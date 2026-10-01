! csm-analysis: post-processing and plotting of constitutive-model results.
! Re-exports the public API; see notes/csm_analysis.pdf for the design.

module csm_analysis
   use mod_fm_kinds,          only: wp
   use mod_fm_quad_plot,      only: quad_plot_t
   use mod_fm_oedometer_plot, only: oedometer_plot_t
   use mod_fm_xy_plot,        only: xy_plot_t
   implicit none
   private
   public :: wp, quad_plot_t, oedometer_plot_t, xy_plot_t
end module csm_analysis
