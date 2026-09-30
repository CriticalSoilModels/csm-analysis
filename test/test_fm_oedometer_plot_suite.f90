module mod_test_fm_oedometer_plot_suite
   use mod_fm_kinds,          only: wp
   use mod_fm_oedometer_plot, only: oedometer_plot_t
   use mod_fm_test_files,     only: delete_if_exists, check_written
   use stdlib_error,          only: state_type
   use testdrive,             only: new_unittest, unittest_type, error_type, check
   implicit none
   private
   public :: collect_oedometer_plot_suite

   character(len=*), parameter :: PNG = "build/test_fm_oedometer_plot.png"

contains

   subroutine collect_oedometer_plot_suite(testsuite)
      type(unittest_type), allocatable, intent(out) :: testsuite(:)

      testsuite = [ &
         new_unittest("save without tests is an error",  test_no_tests), &
         new_unittest("sig and eps of different lengths", test_lengths), &
         new_unittest("writes a PNG, all options",        test_writes_png) &
      ]
   end subroutine collect_oedometer_plot_suite

   subroutine oedometer(sig, eps)
      !! A short oedometric compression history, tension positive, K0 = 0.5.
      real(wp), intent(out) :: sig(6, 5), eps(6, 5)
      integer :: i

      sig = 0.0_wp
      eps = 0.0_wp
      do i = 1, 5
         sig(1:3, i) = -100.0_wp*i*[1.0_wp, 0.5_wp, 0.5_wp]
         eps(1, i)   = -0.001_wp*i
      end do
   end subroutine oedometer

   subroutine test_no_tests(error)
      type(error_type), allocatable, intent(out) :: error
      type(oedometer_plot_t) :: fig
      type(state_type) :: status

      call fig%save(PNG, status)
      call check(error, status%error(), more="expected an error")
   end subroutine test_no_tests

   subroutine test_lengths(error)
      type(error_type), allocatable, intent(out) :: error
      type(oedometer_plot_t) :: fig
      type(state_type) :: status
      real(wp) :: sig(6, 5), eps(6, 5)

      call oedometer(sig, eps)
      call fig%add(sig(:, 1:3), eps)
      call fig%save(PNG, status)
      call check(error, status%error(), more="expected an error")
      if (allocated(error)) return
      call check(error, index(status%message, "test 1") > 0, more="message: "//trim(status%message))
   end subroutine test_lengths

   subroutine test_writes_png(error)
      type(error_type), allocatable, intent(out) :: error
      type(oedometer_plot_t) :: fig
      type(state_type) :: status
      real(wp) :: sig(6, 5), eps(6, 5)

      call oedometer(sig, eps)
      fig%compression_positive = .true.
      fig%strain_in_percent    = .false.
      fig%title       = "options"
      fig%stress_unit = "MPa"
      call fig%add(sig, eps, label="one")
      call fig%add(2.0_wp*sig, eps, label="two")
      call delete_if_exists(PNG)
      call fig%save(PNG, status)
      call check_written(PNG, status, error)
   end subroutine test_writes_png

end module mod_test_fm_oedometer_plot_suite
