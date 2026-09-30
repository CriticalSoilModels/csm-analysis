! Working precision kinds for fumat.
!
! wp is the working precision of csm-tensors (mod_csm_kinds), so fumat, element-driver, and
! critical-soil-models always agree. Change it there, not here.

module mod_fm_kinds
   use mod_csm_kinds, only: csm_wp => wp
   implicit none
   private

   integer, parameter, public :: wp = csm_wp    !! Working precision (currently double)

end module mod_fm_kinds
