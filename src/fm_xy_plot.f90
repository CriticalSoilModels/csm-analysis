! General x-y overlay: any quantities against each other on one set of axes, for what the
! standard figures do not cover (Lode angle, state variables, a single stress component, ...).
!
! The caller computes x and y (e.g. with csm-tensors' mod_invariant_histories), so signs and
! units are whatever the caller passes; nothing is flipped or scaled here.
!
! Usage:
!    type(xy_plot_t) :: fig
!    fig%xlabel = "time t [s]"
!    fig%ylabel = "Lode angle [rad]"
!    call fig%add(history%t_total, calc_lode_history(history%sig), label="dense")
!    call fig%save("output/lode.png", status)

module mod_fm_xy_plot
   use mod_fm_kinds,      only: wp
   use mod_fm_plot_style, only: series_colour
   use fortplot,          only: figure_t
   use stdlib_error,      only: state_type, STDLIB_VALUE_ERROR, STDLIB_SUCCESS
   implicit none
   private
   public :: xy_plot_t

   character(len=*), parameter :: WHERE_AT = "xy_plot_t"

   type :: xy_series_t
      character(len=:), allocatable :: label
      real(wp), allocatable :: x(:), y(:)
   end type xy_series_t

   type :: xy_plot_t
      !! Options, set before save:
      character(len=:), allocatable :: title, xlabel, ylabel
      integer :: width  = 800                          !! Figure size in pixels
      integer :: height = 600
      type(xy_series_t), allocatable, private :: series(:)
      character(len=:), allocatable, private :: add_error   !! First error from add, reported by save
   contains
      procedure :: add  => xy_plot_add
      procedure :: save => xy_plot_save
   end type xy_plot_t

contains

   subroutine xy_plot_add(self, x, y, label)
      !! Adds one curve. A length mismatch is kept and reported by save, so add has no status.
      class(xy_plot_t), intent(inout) :: self
      real(wp),         intent(in)    :: x(:), y(:)
      character(len=*), intent(in), optional :: label
      type(xy_series_t) :: s
      character(len=16) :: number

      if (allocated(self%add_error)) return
      if (.not. allocated(self%series)) allocate(self%series(0))
      if (size(x) /= size(y)) then
         write(number, '(i0)') size(self%series) + 1
         self%add_error = "curve "//trim(number)//": x and y have different lengths"
         return
      end if

      s%label = ""
      if (present(label)) s%label = label
      s%x = x
      s%y = y
      self%series = [self%series, s]
   end subroutine xy_plot_add

   subroutine xy_plot_save(self, filename, status)
      !! Draws the curves and writes the figure (format from the file extension). On a single
      !! set of axes fortplot's legend works, so labelled curves get a real legend.
      class(xy_plot_t), intent(in)  :: self
      character(len=*), intent(in)  :: filename
      type(state_type), intent(out) :: status
      type(figure_t) :: fig
      integer :: i
      logical :: any_label

      if (allocated(self%add_error)) then
         status = state_type(WHERE_AT, STDLIB_VALUE_ERROR, self%add_error)
         return
      end if
      if (.not. allocated(self%series)) then
         status = state_type(WHERE_AT, STDLIB_VALUE_ERROR, "no curves added")
         return
      end if
      if (size(self%series) == 0) then
         status = state_type(WHERE_AT, STDLIB_VALUE_ERROR, "no curves added")
         return
      end if

      call fig%initialize(width=self%width, height=self%height)
      any_label = .false.
      do i = 1, size(self%series)
         associate (s => self%series(i))
            if (len(s%label) > 0) then
               any_label = .true.
               call fig%add_plot(s%x, s%y, label=s%label, color=series_colour(i))
            else
               call fig%add_plot(s%x, s%y, color=series_colour(i))
            end if
         end associate
      end do
      if (allocated(self%xlabel)) call fig%set_xlabel(self%xlabel)
      if (allocated(self%ylabel)) call fig%set_ylabel(self%ylabel)
      if (allocated(self%title))  call fig%set_title(self%title)
      if (any_label) call fig%legend()

      call fig%savefig(filename)
      status = state_type(STDLIB_SUCCESS)
   end subroutine xy_plot_save

end module mod_fm_xy_plot
