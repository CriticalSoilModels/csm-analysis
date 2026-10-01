! Oedometer plot and x-y overlay of two synthetic oedometer tests with an unload-reload loop.
!
! The histories are made up (loading with K0 = 0.5 or 0.4, unloading and reloading with a stiffer
! response and K0 rising on unloading) and written as tension-positive sig(6, n) and
! eps(6, n), the form any solver hands over.
!
! Run with: fpm run --example oedometer_plot_synthetic
! Writes:   output/oedometer_plot_synthetic.png, output/oedometer_k0_synthetic.png

program oedometer_plot_synthetic
   use csm_analysis,        only: wp, oedometer_plot_t, xy_plot_t
   use stdlib_error, only: state_type
   use stdlib_math,  only: linspace
   implicit none

   integer, parameter :: N = 60                  ! states per stage (load, unload, reload)
   type(oedometer_plot_t) :: fig
   type(xy_plot_t) :: k0_fig
   type(state_type) :: status
   real(wp) :: sig(6, 3*N), eps(6, 3*N)

   fig%title = "Synthetic oedometer tests; compression positive"
   fig%compression_positive = .true.
   k0_fig%title  = "Synthetic oedometer tests: $K_0 = \sigma_h / \sigma_v$"
   k0_fig%xlabel = "vertical stress $\sigma_v$ [kPa] (compression positive)"
   k0_fig%ylabel = "$K_0$ [-]"

   call oedometer(20000.0_wp, 0.5_wp, sig, eps)
   call fig%add(sig, eps, label="soft")
   call k0_fig%add(-sig(1, :), sig(2, :)/sig(1, :), label="soft")
   call oedometer(40000.0_wp, 0.4_wp, sig, eps)
   call fig%add(sig, eps, label="stiff")
   call k0_fig%add(-sig(1, :), sig(2, :)/sig(1, :), label="stiff")

   call fig%save("output/oedometer_plot_synthetic.png", status)
   if (status%error()) error stop trim(status%message)
   call k0_fig%save("output/oedometer_k0_synthetic.png", status)
   if (status%error()) error stop trim(status%message)

contains

   subroutine oedometer(m_load, k0_nc, sig, eps)
      !! Constrained modulus m_load on loading from 10 to 400 kPa, 5 m_load on unloading to
      !! 100 kPa and reloading. Compression positive magnitudes, stored tension positive.
      real(wp), intent(in)  :: m_load, k0_nc   ! constrained modulus on loading, K0 on loading
      real(wp), intent(out) :: sig(:,:), eps(:,:)
      real(wp) :: sig_v(size(sig, 2)), sig_h(size(sig, 2)), eps_a(size(sig, 2))

      sig_v(1:N)         = linspace(10.0_wp, 400.0_wp, N)
      sig_v(N+1:2*N)     = linspace(400.0_wp, 100.0_wp, N)
      sig_v(2*N+1:3*N)   = linspace(100.0_wp, 400.0_wp, N)
      eps_a(1:N)         = (sig_v(1:N) - 10.0_wp)/m_load
      eps_a(N+1:3*N)     = eps_a(N) + (sig_v(N+1:3*N) - 400.0_wp)/(5.0_wp*m_load)
      sig_h(1:N)         = k0_nc*sig_v(1:N)
      ! Unloading: sig_h drops more slowly than sig_v (K0 rises); reloading retraces it.
      sig_h(N+1:3*N)     = k0_nc*400.0_wp + 0.25_wp*(sig_v(N+1:3*N) - 400.0_wp)

      sig = 0.0_wp
      eps = 0.0_wp
      sig(1, :) = -sig_v
      sig(2, :) = -sig_h
      sig(3, :) = -sig_h
      eps(1, :) = -eps_a
   end subroutine oedometer

end program oedometer_plot_synthetic
