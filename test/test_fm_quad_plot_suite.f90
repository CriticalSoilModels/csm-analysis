module mod_test_fm_quad_plot_suite
   use mod_fm_kinds,     only: wp
   use mod_fm_quad_plot, only: quad_plot_t
   use stdlib_error,     only: state_type
   use testdrive,        only: new_unittest, unittest_type, error_type, check
   implicit none
   private
   public :: collect_quad_plot_suite

   character(len=*), parameter :: PNG = "build/test_fm_quad_plot.png"

contains

   subroutine collect_quad_plot_suite(testsuite)
      type(unittest_type), allocatable, intent(out) :: testsuite(:)

      testsuite = [ &
         new_unittest("save without tests is an error",  test_no_tests), &
         new_unittest("sig without 6 rows is an error",   test_rows), &
         new_unittest("sig and eps of different lengths", test_lengths), &
         new_unittest("writes a PNG",                     test_writes_png), &
         new_unittest("writes a PNG, all options",        test_options) &
      ]
   end subroutine collect_quad_plot_suite

   subroutine triaxial(sig, eps)
      !! A short drained triaxial compression history, tension positive.
      real(wp), intent(out) :: sig(6, 5), eps(6, 5)
      integer :: i

      sig = 0.0_wp
      eps = 0.0_wp
      do i = 1, 5
         sig(1:3, i) = [-100.0_wp - 50.0_wp*(i - 1), -100.0_wp, -100.0_wp]
         eps(1:3, i) = [-0.002_wp*(i - 1), 0.0005_wp*(i - 1), 0.0005_wp*(i - 1)]
      end do
   end subroutine triaxial

   subroutine test_no_tests(error)
      type(error_type), allocatable, intent(out) :: error
      type(quad_plot_t) :: fig
      type(state_type) :: status

      call fig%save(PNG, status)
      call check(error, status%error(), more="expected an error")
   end subroutine test_no_tests

   subroutine test_rows(error)
      type(error_type), allocatable, intent(out) :: error
      type(quad_plot_t) :: fig
      type(state_type) :: status
      real(wp) :: sig(6, 5), eps(6, 5)

      call triaxial(sig, eps)
      call fig%add(sig(1:5, :), eps)
      call fig%save(PNG, status)
      call check(error, status%error(), more="expected an error")
      if (allocated(error)) return
      call check(error, index(status%message, "6 rows") > 0, more="message: "//trim(status%message))
   end subroutine test_rows

   subroutine test_lengths(error)
      type(error_type), allocatable, intent(out) :: error
      type(quad_plot_t) :: fig
      type(state_type) :: status
      real(wp) :: sig(6, 5), eps(6, 5)

      call triaxial(sig, eps)
      call fig%add(sig, eps)                      ! fine
      call fig%add(sig(:, 1:4), eps, label="bad") ! the second test is wrong
      call fig%save(PNG, status)
      call check(error, status%error(), more="expected an error")
      if (allocated(error)) return
      call check(error, index(status%message, "test 2") > 0, more="message: "//trim(status%message))
   end subroutine test_lengths

   subroutine test_writes_png(error)
      type(error_type), allocatable, intent(out) :: error
      type(quad_plot_t) :: fig
      real(wp) :: sig(6, 5), eps(6, 5)

      call triaxial(sig, eps)
      call fig%add(sig, eps, label="one")
      call fig%add(2.0_wp*sig, 2.0_wp*eps, label="two")
      call check_png(fig, error)
   end subroutine test_writes_png

   subroutine test_options(error)
      type(error_type), allocatable, intent(out) :: error
      type(quad_plot_t) :: fig
      real(wp) :: sig(6, 5), eps(6, 5)

      call triaxial(sig, eps)
      fig%compression_positive = .true.
      fig%strain_in_percent    = .false.
      fig%use_axial_strain     = .true.
      fig%title       = "options"
      fig%stress_unit = "MPa"
      call fig%add(sig, eps)
      call check_png(fig, error)
   end subroutine test_options

   subroutine check_png(fig, error)
      !! Saves to PNG and checks that a non-empty file appeared; removes it afterwards.
      type(quad_plot_t), intent(in) :: fig
      type(error_type), allocatable, intent(out) :: error
      type(state_type) :: status
      logical :: exists
      integer :: file_size, unit

      inquire(file=PNG, exist=exists)
      if (exists) call delete(PNG)
      call fig%save(PNG, status)
      call check(error, .not. status%error(), more="save failed: "//trim(status%message))
      if (allocated(error)) return
      inquire(file=PNG, exist=exists, size=file_size)
      call check(error, exists .and. file_size > 0, more="no PNG written")
      if (exists) call delete(PNG)
   end subroutine check_png

   subroutine delete(path)
      character(len=*), intent(in) :: path
      integer :: unit

      open(newunit=unit, file=path, status="old")
      close(unit, status="delete")
   end subroutine delete

end module mod_test_fm_quad_plot_suite
