! Oedometer plot of element tests, side by side:
!
!   vertical stress sig_v vs axial strain eps_a  |  horizontal stress sig_h vs sig_v
!
! Tests are added one at a time as stress and strain histories, sig(6, n) and eps(6, n),
! from any solver (F2). Axis 1 is vertical: sig_v = sig(1, :), eps_a = eps(1, :), and
! sig_h = (sig(2, :) + sig(3, :))/2. Under oedometric (K0) conditions eps_a = eps_v and the
! slope of the right panel is K0 (1D unloading-reloading shows as a change of slope).
!
! Signs: data are tension positive (F3), and by default the plots show them as they are, so
! compression is negative. Every plotted quantity is signed, so compression_positive = .true.
! flips all of them to the geotechnical convention; only the drawn values change.
!
! Legend: a colour key above the left panel instead of a legend (mod_fm_plot_style, Q7).
!
! Usage:
!    type(oedometer_plot_t) :: fig
!    call fig%add(history%sig, history%eps, label="dense")
!    call fig%save("output/oedometer.png", status)

module mod_fm_oedometer_plot
   use mod_fm_kinds,      only: wp
   use mod_fm_plot_style, only: series_colour, add_to_key, plot_scales, check_history, label_panel
   use fortplot,          only: figure_t
   use stdlib_error,      only: state_type, STDLIB_VALUE_ERROR, STDLIB_SUCCESS
   implicit none
   private
   public :: oedometer_plot_t

   character(len=*), parameter :: WHERE_AT = "oedometer_plot_t"

   type :: oedometer_series_t
      character(len=:), allocatable :: label
      real(wp), allocatable :: eps_a(:), sig_v(:), sig_h(:)
   end type oedometer_series_t

   type :: oedometer_plot_t
      !! Options, set before save:
      logical :: compression_positive = .false.        !! Plot compression positive (F3)
      logical :: strain_in_percent    = .true.         !! Plot strains in % instead of [-]
      character(len=:), allocatable :: title           !! Figure title (none if unset)
      character(len=:), allocatable :: stress_unit     !! Stress unit in the labels (default kPa)
      integer :: width  = 1000                         !! Figure size in pixels
      integer :: height = 480
      type(oedometer_series_t), allocatable, private :: series(:)
      character(len=:), allocatable, private :: add_error   !! First error from add, reported by save
   contains
      procedure :: add  => oedometer_plot_add
      procedure :: save => oedometer_plot_save
   end type oedometer_plot_t

contains

   subroutine oedometer_plot_add(self, sig, eps, label)
      !! Adds one test. Shape errors are kept and reported by save, so add has no status.
      class(oedometer_plot_t), intent(inout) :: self
      real(wp),                intent(in)    :: sig(:,:)   !! (6, n) stress history
      real(wp),                intent(in)    :: eps(:,:)   !! (6, n) strain history
      character(len=*),        intent(in), optional :: label
      type(oedometer_series_t) :: s

      if (allocated(self%add_error)) return
      if (.not. allocated(self%series)) allocate(self%series(0))
      call check_history(sig, eps, size(self%series) + 1, self%add_error)
      if (allocated(self%add_error)) return

      s%label = ""
      if (present(label)) s%label = label
      s%eps_a = eps(1, :)
      s%sig_v = sig(1, :)
      s%sig_h = 0.5_wp*(sig(2, :) + sig(3, :))
      self%series = [self%series, s]
   end subroutine oedometer_plot_add

   subroutine oedometer_plot_save(self, filename, status)
      !! Draws the two panels and writes the figure (format from the file extension).
      class(oedometer_plot_t), intent(in)  :: self
      character(len=*),        intent(in)  :: filename
      type(state_type),        intent(out) :: status
      type(figure_t) :: fig
      real(wp) :: sign, strain_scale
      character(len=:), allocatable :: unit, strain_unit, key
      integer :: i

      if (allocated(self%add_error)) then
         status = state_type(WHERE_AT, STDLIB_VALUE_ERROR, self%add_error)
         return
      end if
      if (.not. allocated(self%series)) then
         status = state_type(WHERE_AT, STDLIB_VALUE_ERROR, "no tests added")
         return
      end if
      if (size(self%series) == 0) then
         status = state_type(WHERE_AT, STDLIB_VALUE_ERROR, "no tests added")
         return
      end if

      call plot_scales(self%compression_positive, self%strain_in_percent, sign, strain_scale, strain_unit)
      unit = "kPa"
      if (allocated(self%stress_unit)) unit = self%stress_unit

      call fig%initialize(width=self%width, height=self%height)
      call fig%subplots(1, 2)
      key = ""
      do i = 1, size(self%series)
         associate (s => self%series(i))
            call add_to_key(key, i, s%label)
            call fig%subplot_plot(1, 1, sign*strain_scale*s%eps_a, sign*s%sig_v, color=series_colour(i))
            call fig%subplot_plot(1, 2, sign*s%sig_v, sign*s%sig_h,             color=series_colour(i))
         end associate
      end do

      call label_panel(fig, 1, 1, "axial strain $\epsilon_a$ "//strain_unit, &
                       "vertical stress $\sigma_v$ ["//unit//"]")
      call label_panel(fig, 1, 2, "vertical stress $\sigma_v$ ["//unit//"]", &
                       "horizontal stress $\sigma_h$ ["//unit//"]")
      ! fortplot's suptitle is a single line, so the key goes above the first panel.
      if (allocated(self%title)) call fig%suptitle(self%title)
      if (len(key) > 0) call fig%subplot_set_title(1, 1, key)

      call fig%savefig(filename)
      status = state_type(STDLIB_SUCCESS)
   end subroutine oedometer_plot_save

end module mod_fm_oedometer_plot
