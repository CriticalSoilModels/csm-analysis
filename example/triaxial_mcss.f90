! Drained triaxial compression of MCSS (Mohr-Coulomb with strain softening, from
! critical-soil-models), run with element-driver and plotted with csm-analysis's quad_plot_t.
!
! element-driver is a dev-dependency of csm-analysis (examples only); the library itself does not
! depend on any solver (F1). Three cell pressures, 10% axial strain in 1000 increments, Euler
! substepping. The sample yields at peak strength and softens to residual strength (at 200 kPa
! through a snap-back that strain control cannot follow; element-driver notes I13).
!
! Run with: fpm run --example triaxial_mcss
! Writes:   output/triaxial_mcss.png
! Signs: data are tension positive (F3); the plot shows compression positive.

program triaxial_mcss
   use mod_ed_kinds,          only: wp
   use mod_ed_model,          only: ed_model_t
   use mod_ed_material_point, only: material_point_t
   use mod_ed_prebuilt_steps, only: drained_triaxial_step
   use mod_ed_run,            only: history_t, run
   use mod_ed_csm_model,      only: ed_csm_model
   use mod_mcss_model,        only: mcss_model_t
   use mod_mcss_types,        only: DEFAULT_AS_PARAMS
   use mod_integrate_stress,  only: integrator_params_t
   use stdlib_error,          only: state_type
   use csm_analysis,          only: quad_plot_t
   implicit none

   real(wp), parameter :: DEG_TO_RAD = acos(-1.0_wp)/180.0_wp
   real(wp), parameter :: CELL_PRESSURES(3) = [-50.0_wp, -100.0_wp, -200.0_wp]   ! [kPa]
   real(wp), parameter :: EPS_END = -0.1_wp      ! total axial strain [-]
   integer,  parameter :: N_INC   = 1000

   type(history_t) :: history(3)
   type(quad_plot_t) :: fig
   type(state_type) :: status
   character(len=32) :: label
   integer :: i

   do i = 1, 3
      call run_test(CELL_PRESSURES(i), history(i))
   end do

   fig%title = "Drained triaxial, MCSS (element-driver), three cell pressures; compression positive"
   fig%compression_positive = .true.
   do i = 1, 3
      write(label, '(i0, " kPa")') nint(-CELL_PRESSURES(i))
      call fig%add(history(i)%sig, history(i)%eps, label=trim(label))
   end do
   call fig%save("output/triaxial_mcss.png", status)
   if (status%error()) error stop "plot failed: "//trim(status%message)

contains

   subroutine run_test(cell_pressure, hist)
      real(wp),        intent(in)  :: cell_pressure
      type(history_t), intent(out) :: hist
      class(ed_model_t), allocatable :: model
      type(material_point_t) :: point
      type(state_type) :: status

      allocate(model, source=ed_csm_model(make_mcss(), iparams=integrator_params_t(ftol=1.0e-8_wp)))
      point%sig(1:3) = cell_pressure
      call run(model, point, [drained_triaxial_step(EPS_END, N_INC)], hist, status)
      if (status%error()) error stop "MCSS triaxial run failed: "//trim(status%message)
   end subroutine run_test

   function make_mcss() result(mcss)
      !! MCSS at peak state with zero plastic strain.
      type(mcss_model_t) :: mcss

      mcss%params%G         = 10000.0_wp          ! shear modulus [kPa]
      mcss%params%nu        = 0.3_wp              ! Poisson's ratio [-]
      mcss%params%c_peak    = 10.0_wp             ! cohesion, peak and residual [kPa]
      mcss%params%c_res     = 2.0_wp
      mcss%params%phi_peak  = 30.0_wp*DEG_TO_RAD  ! friction angle, peak and residual
      mcss%params%phi_res   = 20.0_wp*DEG_TO_RAD
      mcss%params%psi_peak  = 10.0_wp*DEG_TO_RAD  ! dilation angle, peak and residual
      mcss%params%psi_res   = 0.0_wp
      mcss%params%factor    = 100.0_wp            ! softening rate
      mcss%params%as_params = DEFAULT_AS_PARAMS   ! Abbo-Sloan rounding

      mcss%state%c        = mcss%params%c_peak
      mcss%state%phi      = mcss%params%phi_peak
      mcss%state%psi      = mcss%params%psi_peak
      mcss%state%eps_p    = 0.0_wp
      mcss%state%eps_p_eq = 0.0_wp

      mcss%yield_tol    = 1.0e-8_wp
      mcss%max_substeps = 0
      mcss%dt_min       = 1.0e-9_wp
   end function make_mcss

end program triaxial_mcss
