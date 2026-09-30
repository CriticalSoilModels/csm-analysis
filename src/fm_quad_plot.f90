! Quad plot of element tests on a 2x2 grid:
!
!   q     vs eps_q  |  q     vs p
!   eps_v vs eps_q  |  eps_v vs p
!
! Tests are added one at a time as stress and strain histories, sig(6, n) and eps(6, n),
! from any solver (F2); nothing is kept but the plotted quantities. All four quantities are
! invariants from csm-tensors (F10), so the plot does not depend on the axes of the test:
!   p = tr(sig)/3,  q = sqrt(3 J2) >= 0,  eps_v = tr(eps),  eps_q = sqrt(2/3 e:e) >= 0.
! q deps_q equals the deviatoric work s:de when the strain increment is coaxial with s, as in
! any triaxial test. In a triaxial test q = |s_a - s_r| and eps_q = 2/3 |e_a - e_r|.
!
! eps_q equals the axial strain only without volume change (triaxial compression, with
! eps_a and eps_v taken compression positive: eps_a = eps_q + eps_v/3). Lab data are usually
! plotted against axial strain, so use_axial_strain = .true. switches the left column to
! eps_a = eps(1, :), with axis 1 axial.
!
! Signs: data are tension positive (F3), and by default the plots show them as they are, so
! p and eps_v are negative in compression. q and eps_q are magnitudes, >= 0 either way. Set
! compression_positive = .true. to plot p, eps_v, and eps_a in the geotechnical convention;
! only the drawn values change.
!
! Legend: fortplot's figure legend is broken for subplots (entries drawn on top of each
! other in the lower-left corner, location ignored; fumat notes Q7). Until it is fixed, each
! test gets a fixed colour from the matplotlib tab10 cycle and the colour key is written
! above the top-left panel, e.g. "blue: p0 = 50 kPa   orange: p0 = 100 kPa".
!
! Usage:
!    type(quad_plot_t) :: fig
!    call fig%add(history%sig, history%eps, label="p0 = 100 kPa")
!    call fig%save("output/quad.png", status)

module mod_fm_quad_plot
   use mod_fm_kinds,            only: wp
   use mod_invariant_histories, only: calc_p_history, calc_q_history, calc_eps_vol_history, &
                                      calc_eps_q_history
   use fortplot,                only: figure_t
   use stdlib_error,            only: state_type, STDLIB_VALUE_ERROR, STDLIB_SUCCESS
   implicit none
   private
   public :: quad_plot_t

   character(len=*), parameter :: WHERE_AT = "quad_plot_t"

   ! matplotlib tab10 colour cycle, with names for the colour key.
   character(len=*), parameter :: COLOUR_NAMES(10) = [character(len=6) :: "blue", "orange", "green", &
      "red", "purple", "brown", "pink", "grey", "olive", "cyan"]
   real(wp), parameter :: COLOURS(3, 10) = reshape([ &
      31.0_wp, 119.0_wp, 180.0_wp,   255.0_wp, 127.0_wp,  14.0_wp,    44.0_wp, 160.0_wp,  44.0_wp, &
     214.0_wp,  39.0_wp,  40.0_wp,   148.0_wp, 103.0_wp, 189.0_wp,   140.0_wp,  86.0_wp,  75.0_wp, &
     227.0_wp, 119.0_wp, 194.0_wp,   127.0_wp, 127.0_wp, 127.0_wp,   188.0_wp, 189.0_wp,  34.0_wp, &
      23.0_wp, 190.0_wp, 207.0_wp], [3, 10]) / 255.0_wp

   type :: quad_series_t
      character(len=:), allocatable :: label
      real(wp), allocatable :: eps_a(:), eps_q(:), eps_v(:), p(:), q(:)
   end type quad_series_t

   type :: quad_plot_t
      !! Options, set before save:
      logical :: compression_positive = .false.        !! Plot compression positive (F3)
      logical :: strain_in_percent    = .true.         !! Plot strains in % instead of [-]
      logical :: use_axial_strain     = .false.        !! Left column vs eps_a instead of eps_q
      character(len=:), allocatable :: title           !! Figure title (none if unset)
      character(len=:), allocatable :: stress_unit     !! Stress unit in the labels (default kPa)
      integer :: width  = 1000                         !! Figure size in pixels
      integer :: height = 850
      type(quad_series_t), allocatable, private :: series(:)
      character(len=:), allocatable, private :: add_error   !! First error from add, reported by save
   contains
      procedure :: add  => quad_plot_add
      procedure :: save => quad_plot_save
   end type quad_plot_t

contains

   subroutine quad_plot_add(self, sig, eps, label)
      !! Adds one test. Shape errors are kept and reported by save, so add has no status.
      class(quad_plot_t), intent(inout) :: self
      real(wp),           intent(in)    :: sig(:,:)   !! (6, n) stress history
      real(wp),           intent(in)    :: eps(:,:)   !! (6, n) strain history
      character(len=*),   intent(in), optional :: label
      type(quad_series_t) :: s
      character(len=16) :: number

      if (allocated(self%add_error)) return
      if (.not. allocated(self%series)) allocate(self%series(0))
      write(number, '(i0)') size(self%series) + 1
      if (size(sig, 1) /= 6 .or. size(eps, 1) /= 6) then
         self%add_error = "test "//trim(number)//": sig and eps must have 6 rows"
         return
      end if
      if (size(sig, 2) /= size(eps, 2)) then
         self%add_error = "test "//trim(number)//": sig and eps have different numbers of states"
         return
      end if

      s%label = ""
      if (present(label)) s%label = label
      s%eps_a = eps(1, :)
      s%eps_q = calc_eps_q_history(eps)
      s%eps_v = calc_eps_vol_history(eps)
      s%p     = calc_p_history(sig)
      s%q     = calc_q_history(sig)
      self%series = [self%series, s]
   end subroutine quad_plot_add

   subroutine quad_plot_save(self, filename, status)
      !! Draws the four panels and writes the figure (format from the file extension).
      class(quad_plot_t), intent(in)  :: self
      character(len=*),   intent(in)  :: filename
      type(state_type),   intent(out) :: status
      type(figure_t) :: fig
      real(wp) :: sign, strain_scale
      real(wp), allocatable :: x_shear(:)
      character(len=:), allocatable :: unit, strain_unit, shear_label, eps_v_label, p_label, q_label, key
      real(wp) :: colour(3)
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

      sign = 1.0_wp
      if (self%compression_positive) sign = -1.0_wp
      strain_scale = 1.0_wp
      strain_unit  = "[-]"
      if (self%strain_in_percent) then
         strain_scale = 100.0_wp
         strain_unit  = "[%]"
      end if
      unit = "kPa"
      if (allocated(self%stress_unit)) unit = self%stress_unit

      if (self%use_axial_strain) then
         shear_label = "axial strain $\epsilon_a$ "//strain_unit
      else
         shear_label = "deviatoric strain $\epsilon_q$ "//strain_unit
      end if
      eps_v_label = "volumetric strain $\epsilon_v$ "//strain_unit
      p_label     = "mean stress p ["//unit//"]"
      q_label     = "deviator stress q ["//unit//"]"

      call fig%initialize(width=self%width, height=self%height)
      call fig%subplots(2, 2)
      key = ""
      do i = 1, size(self%series)
         associate (s => self%series(i))
            colour = COLOURS(:, modulo(i - 1, size(COLOURS, 2)) + 1)
            if (len(s%label) > 0) then
               if (len(key) > 0) key = key//"   "
               key = key//trim(COLOUR_NAMES(modulo(i - 1, size(COLOURS, 2)) + 1))//": "//s%label
            end if
            ! q and eps_q are magnitudes: never flipped.
            if (self%use_axial_strain) then
               x_shear = sign*strain_scale*s%eps_a
            else
               x_shear = strain_scale*s%eps_q
            end if
            call fig%subplot_plot(1, 1, x_shear,  s%q,                      color=colour)
            call fig%subplot_plot(1, 2, sign*s%p, s%q,                      color=colour)
            call fig%subplot_plot(2, 1, x_shear,  sign*strain_scale*s%eps_v, color=colour)
            call fig%subplot_plot(2, 2, sign*s%p, sign*strain_scale*s%eps_v, color=colour)
         end associate
      end do

      call label_panel(fig, 1, 1, shear_label, q_label)
      call label_panel(fig, 1, 2, p_label,     q_label)
      call label_panel(fig, 2, 1, shear_label, eps_v_label)
      call label_panel(fig, 2, 2, p_label,     eps_v_label)
      ! fortplot's suptitle is a single line, so the key goes above the first panel.
      if (allocated(self%title)) call fig%suptitle(self%title)
      if (len(key) > 0) call fig%subplot_set_title(1, 1, key)

      call fig%savefig(filename)
      status = state_type(STDLIB_SUCCESS)
   end subroutine quad_plot_save

   subroutine label_panel(fig, row, col, xlabel, ylabel)
      type(figure_t),   intent(inout) :: fig
      integer,          intent(in)    :: row, col
      character(len=*), intent(in)    :: xlabel, ylabel

      call fig%subplot_set_xlabel(row, col, xlabel)
      call fig%subplot_set_ylabel(row, col, ylabel)
   end subroutine label_panel

end module mod_fm_quad_plot
