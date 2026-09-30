! Basic fortplot usage: a line plot saved at two resolutions.
! Run with: fpm run --example fortplot_basics

program fortplot_basics
   use fortplot, only: figure_t
   use stdlib_math, only: linspace
   use stdlib_kinds, only: dp

   implicit none

   type(figure_t) :: fig
   integer, parameter :: n = 5*10**2
   real(dp), dimension(n) :: x, yf
   integer :: i

! Generate test data
   x = linspace(0.0_dp, 10.0_dp, n)
   yf = sin(x)**2

   print *, size(yf)
   call fig%initialize(dpi = 300.0_dp)
   call fig%set_title("Function Plot")
   call fig%set_xlabel("x")
   call fig%set_ylabel("y")
   call fig%plot(x, yf)
   print *, fig%get_width()
   call fig%savefig("output/fortplot_basics_300dpi.png")
   

   call fig%set_dpi(dpi = 100.0_dp)
   call fig%savefig("output/fortplot_basics_100dpi.png")
end program fortplot_basics
