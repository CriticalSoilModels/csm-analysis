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
! Legend: a colour key above the top-left panel instead of a legend (mod_fm_plot_style, Q7).
!
! Usage:
!    type(quad_plot_t) :: fig
!    call fig%add(history%sig, history%eps, label="p0 = 100 kPa")
!    call fig%save("output/quad.png", status)

module mod_fm_quad_plot
   use mod_fm_kinds,            only: wp
   use mod_invariant_histories, only: calc_p_history, calc_q_history, calc_eps_vol_history, &
                                      calc_eps_q_history
   use mod_fm_plot_style,       only: series_colour, add_to_key, plot_scales, check_history, label_panel
   use fortplot,                only: figure_t
   use stdlib_error,            only: state_type, STDLIB_VALUE_ERROR, STDLIB_SUCCESS
   implicit none
   private
   public :: quad_plot_t

   character(len=*), parameter :: WHERE_AT = "quad_plot_t"

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

      if (allocated(self%add_error)) return
      if (.not. allocated(self%series)) allocate(self%series(0))
      call check_history(sig, eps, size(self%series) + 1, self%add_error)
      if (allocated(self%add_error)) return

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
            call add_to_key(key, i, s%label)
            ! q and eps_q are magnitudes: never flipped.
            if (self%use_axial_strain) then
               x_shear = sign*strain_scale*s%eps_a
            else
               x_shear = strain_scale*s%eps_q
            end if
            call fig%subplot_plot(1, 1, x_shear,  s%q,                      color=series_colour(i))
            call fig%subplot_plot(1, 2, sign*s%p, s%q,                      color=series_colour(i))
            call fig%subplot_plot(2, 1, x_shear,  sign*strain_scale*s%eps_v, color=series_colour(i))
            call fig%subplot_plot(2, 2, sign*s%p, sign*strain_scale*s%eps_v, color=series_colour(i))
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

end module mod_fm_quad_plot
