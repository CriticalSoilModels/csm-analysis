! fumat: post-processing and plotting of constitutive-model element tests.
! Re-exports the public API; see notes/fumat.pdf for the design.

module fumat
   use mod_fm_kinds,     only: wp
   use mod_fm_quad_plot, only: quad_plot_t
   implicit none
   private
   public :: wp, quad_plot_t
end module fumat
