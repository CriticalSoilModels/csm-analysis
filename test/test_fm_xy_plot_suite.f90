module mod_test_fm_xy_plot_suite
   use mod_fm_kinds,      only: wp
   use mod_fm_xy_plot,    only: xy_plot_t
   use mod_fm_test_files, only: delete_if_exists, check_written
   use stdlib_error,      only: state_type
   use testdrive,         only: new_unittest, unittest_type, error_type, check
   implicit none
   private
   public :: collect_xy_plot_suite

   character(len=*), parameter :: PNG = "build/test_fm_xy_plot.png"

contains

   subroutine collect_xy_plot_suite(testsuite)
      type(unittest_type), allocatable, intent(out) :: testsuite(:)

      testsuite = [ &
         new_unittest("save without curves is an error", test_no_curves), &
         new_unittest("x and y of different lengths",    test_lengths), &
         new_unittest("writes a PNG with a legend",      test_writes_png) &
      ]
   end subroutine collect_xy_plot_suite

   subroutine test_no_curves(error)
      type(error_type), allocatable, intent(out) :: error
      type(xy_plot_t) :: fig
      type(state_type) :: status

      call fig%save(PNG, status)
      call check(error, status%error(), more="expected an error")
   end subroutine test_no_curves

   subroutine test_lengths(error)
      type(error_type), allocatable, intent(out) :: error
      type(xy_plot_t) :: fig
      type(state_type) :: status

      call fig%add([1.0_wp, 2.0_wp], [1.0_wp, 2.0_wp])
      call fig%add([1.0_wp, 2.0_wp, 3.0_wp], [1.0_wp, 2.0_wp])
      call fig%save(PNG, status)
      call check(error, status%error(), more="expected an error")
      if (allocated(error)) return
      call check(error, index(status%message, "curve 2") > 0, more="message: "//trim(status%message))
   end subroutine test_lengths

   subroutine test_writes_png(error)
      type(error_type), allocatable, intent(out) :: error
      type(xy_plot_t) :: fig
      type(state_type) :: status

      fig%title  = "title"
      fig%xlabel = "x"
      fig%ylabel = "y"
      call fig%add([0.0_wp, 1.0_wp, 2.0_wp], [0.0_wp, 1.0_wp, 4.0_wp], label="squares")
      call fig%add([0.0_wp, 1.0_wp, 2.0_wp], [0.0_wp, 1.0_wp, 2.0_wp])   ! no label
      call delete_if_exists(PNG)
      call fig%save(PNG, status)
      call check_written(PNG, status, error)
   end subroutine test_writes_png

end module mod_test_fm_xy_plot_suite
