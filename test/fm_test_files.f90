module mod_fm_test_files
   !! File helpers for the figure tests: every figure's save is checked the same way.
   use stdlib_error, only: state_type
   use testdrive,    only: error_type, check
   implicit none
   private
   public :: delete_if_exists, check_written

contains

   subroutine delete_if_exists(path)
      character(len=*), intent(in) :: path
      logical :: exists
      integer :: unit

      inquire(file=path, exist=exists)
      if (.not. exists) return
      open(newunit=unit, file=path, status="old")
      close(unit, status="delete")
   end subroutine delete_if_exists

   subroutine check_written(path, status, error)
      !! save returned status: it must have succeeded and left a non-empty file, which is
      !! then removed.
      character(len=*), intent(in) :: path
      type(state_type), intent(in) :: status
      type(error_type), allocatable, intent(out) :: error
      logical :: exists
      integer :: file_size

      call check(error, .not. status%error(), more="save failed: "//trim(status%message))
      if (allocated(error)) return
      inquire(file=path, exist=exists, size=file_size)
      call check(error, exists .and. file_size > 0, more="no file written: "//path)
      call delete_if_exists(path)
   end subroutine check_written

end module mod_fm_test_files
