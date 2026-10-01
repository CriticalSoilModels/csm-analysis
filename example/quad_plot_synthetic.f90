! Quad plot of three synthetic drained triaxial compression tests.
!
! The histories are made up (hyperbolic q vs axial strain, contraction then dilation) and
! written as tension-positive sig(6, n) and eps(6, n), the form any solver hands over. The
! same data are plotted twice: as stored (compression negative) and compression positive.
!
! Run with: fpm run --example quad_plot_synthetic
! Writes:   output/quad_plot_synthetic.png, output/quad_plot_synthetic_compression_positive.png

program quad_plot_synthetic
   use csm_analysis,        only: wp, quad_plot_t
   use stdlib_error, only: state_type
   use stdlib_math,  only: linspace
   implicit none

   real(wp), parameter :: CELL_PRESSURES(3) = [50.0_wp, 100.0_wp, 200.0_wp]   ! [kPa], compression
   integer,  parameter :: N = 200
   type(quad_plot_t) :: fig, fig_cp
   type(state_type) :: status
   real(wp) :: sig(6, N), eps(6, N)
   character(len=32) :: label
   integer :: i

   do i = 1, size(CELL_PRESSURES)
      call drained_triaxial(CELL_PRESSURES(i), sig, eps)
      write(label, '("p0 = ", i0, " kPa")') nint(CELL_PRESSURES(i))
      call fig%add(sig, eps, label=trim(label))
      call fig_cp%add(sig, eps, label=trim(label))
   end do

   fig%title = "Synthetic drained triaxial compression (as stored: compression negative)"
   call fig%save("output/quad_plot_synthetic.png", status)
   if (status%error()) error stop trim(status%message)

   fig_cp%title = "Synthetic drained triaxial compression (compression positive)"
   fig_cp%compression_positive = .true.
   call fig_cp%save("output/quad_plot_synthetic_compression_positive.png", status)
   if (status%error()) error stop trim(status%message)

contains

   subroutine drained_triaxial(p0, sig, eps)
      !! Cell pressure p0 (compression > 0) held constant; axial strain to 10 % compression.
      real(wp), intent(in)  :: p0
      real(wp), intent(out) :: sig(:,:), eps(:,:)
      real(wp) :: eps_a(size(sig, 2)), q(size(sig, 2)), eps_v(size(sig, 2))
      real(wp), parameter :: M = 1.2_wp, A = 0.01_wp   ! strength ratio q_f/p_f, hyperbola strain
      real(wp) :: e0

      ! Compression-positive magnitudes first, then stored tension positive.
      eps_a = linspace(0.0_wp, 0.10_wp, size(eps_a))
      ! Drained path dp = dq/3 with q -> q_f at p_f = p0 + q_f/3: q_f = M p0 / (1 - M/3)
      q     = M*p0/(1.0_wp - M/3.0_wp) * eps_a/(A + eps_a)
      ! Contraction, then dilation after eps_a = e0; denser response at low cell pressure.
      e0    = 0.02_wp*p0/50.0_wp
      eps_v = 0.5_wp*eps_a*(e0 - eps_a)/(e0 + eps_a)

      sig = 0.0_wp
      sig(1, :) = -(p0 + q)          ! axial
      sig(2, :) = -p0                ! radial (cell pressure)
      sig(3, :) = -p0
      eps = 0.0_wp
      eps(1, :) = -eps_a
      eps(2, :) = -(eps_v - eps_a)/2.0_wp
      eps(3, :) = eps(2, :)
   end subroutine drained_triaxial

end program quad_plot_synthetic
