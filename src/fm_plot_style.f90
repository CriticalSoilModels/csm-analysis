! Shared pieces of the fumat figures: the colour cycle, the colour key, and the scaling of
! plotted values (sign flip for compression_positive, strains in %).
!
! Colour key: fortplot's figure legend is broken for subplots (entries drawn on top of each
! other in the lower-left corner, location ignored; fumat notes Q7). Until it is fixed, each
! series gets a fixed colour from the matplotlib tab10 cycle, and the figures write a key such
! as "blue: 50 kPa   orange: 100 kPa" as the title of their first panel.

module mod_fm_plot_style
   use mod_fm_kinds, only: wp
   use fortplot,     only: figure_t
   implicit none
   private
   public :: series_colour, add_to_key, plot_scales, check_history, label_panel

   character(len=*), parameter :: COLOUR_NAMES(10) = [character(len=6) :: "blue", "orange", "green", &
      "red", "purple", "brown", "pink", "grey", "olive", "cyan"]
   real(wp), parameter :: COLOURS(3, 10) = reshape([ &
      31.0_wp, 119.0_wp, 180.0_wp,   255.0_wp, 127.0_wp,  14.0_wp,    44.0_wp, 160.0_wp,  44.0_wp, &
     214.0_wp,  39.0_wp,  40.0_wp,   148.0_wp, 103.0_wp, 189.0_wp,   140.0_wp,  86.0_wp,  75.0_wp, &
     227.0_wp, 119.0_wp, 194.0_wp,   127.0_wp, 127.0_wp, 127.0_wp,   188.0_wp, 189.0_wp,  34.0_wp, &
      23.0_wp, 190.0_wp, 207.0_wp], [3, 10]) / 255.0_wp

contains

   pure function series_colour(i) result(colour)
      !! RGB colour of series i (1-based); the cycle repeats after 10.
      integer, intent(in) :: i
      real(wp) :: colour(3)

      colour = COLOURS(:, modulo(i - 1, size(COLOURS, 2)) + 1)
   end function series_colour

   pure subroutine add_to_key(key, i, label)
      !! Appends "colour: label" for series i to the colour key; empty labels are skipped.
      character(len=:), allocatable, intent(inout) :: key
      integer,          intent(in) :: i
      character(len=*), intent(in) :: label

      if (len(label) == 0) return
      if (.not. allocated(key)) key = ""
      if (len(key) > 0) key = key//"   "
      key = key//trim(COLOUR_NAMES(modulo(i - 1, size(COLOUR_NAMES)) + 1))//": "//label
   end subroutine add_to_key

   pure subroutine plot_scales(compression_positive, strain_in_percent, sign, strain_scale, strain_unit)
      !! Factors applied to plotted values: sign = -1 flips signed quantities to compression
      !! positive (F3); strain_scale = 100 plots strains in %.
      logical,  intent(in)  :: compression_positive, strain_in_percent
      real(wp), intent(out) :: sign, strain_scale
      character(len=:), allocatable, intent(out) :: strain_unit

      sign = 1.0_wp
      if (compression_positive) sign = -1.0_wp
      strain_scale = 1.0_wp
      strain_unit  = "[-]"
      if (strain_in_percent) then
         strain_scale = 100.0_wp
         strain_unit  = "[%]"
      end if
   end subroutine plot_scales

   pure subroutine check_history(sig, eps, i, error)
      !! Shape check for test i: sig and eps are (6, n) with the same n. error is left
      !! unallocated when they are fine.
      real(wp), intent(in) :: sig(:,:), eps(:,:)
      integer,  intent(in) :: i
      character(len=:), allocatable, intent(out) :: error
      character(len=16) :: number

      write(number, '(i0)') i
      if (size(sig, 1) /= 6 .or. size(eps, 1) /= 6) then
         error = "test "//trim(number)//": sig and eps must have 6 rows"
      else if (size(sig, 2) /= size(eps, 2)) then
         error = "test "//trim(number)//": sig and eps have different numbers of states"
      end if
   end subroutine check_history

   subroutine label_panel(fig, row, col, xlabel, ylabel)
      type(figure_t),   intent(inout) :: fig
      integer,          intent(in)    :: row, col
      character(len=*), intent(in)    :: xlabel, ylabel

      call fig%subplot_set_xlabel(row, col, xlabel)
      call fig%subplot_set_ylabel(row, col, ylabel)
   end subroutine label_panel

end module mod_fm_plot_style
