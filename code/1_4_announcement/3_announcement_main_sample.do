**************************************************
*	Project: LD 
*	Purpose: Announcement make variables
*	Author: HW 
*	Last modified: 2024-12-03 (YS)
**************************************************

******************************
**# 1. Determine Eligibility
******************************


****
**## List of Participants
****

	* Start from Announcement	
	use pid a_date using "$temp/04_announcement_completed_makevar.dta" , clear // 280 people from non-drop list stands
	
	* Merge Treatment status
	merge 1:1 pid using "$raw/ls_randomization_master.dta" , keep(3) keepusing(strata treatment bs_sum_attend) nogen
	drop if bs_sum_attend >= 7
	drop bs_sum_attend

	* Merge with stand and launchset
	merge 1:1 pid using "$raw/launch_prefill_pidwise_2022.dta" , keepusing(stand batch launchset late_announcement_flag modified_launchset_flag) keep(1 3) nogen


	* Filter Launchset
	keep if inlist(launchset, 1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 15, 16, 17)


	save "$temp/00_mainstudy_master.dta", replace
	
