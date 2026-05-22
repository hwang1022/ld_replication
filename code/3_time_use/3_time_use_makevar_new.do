**************************************************
**************************************************
*	Project: LD Main Study
*	Purpose: Make Time Use Variables
* 	
*	Author: HW
*	Last modified: Apr 28, 2026 HW
**************************************************
**************************************************

	use "$temp/lss_time_use_cleaned_hw.dta", clear
	isid pid date

	egen num_activities_530_600 = rowtotal(time_activity_adj_1_1 time_activity_adj_2_1 time_activity_adj_3_1 time_activity_adj_4_1 time_activity_adj_5_1 time_activity_adj_6_1 time_activity_adj_7_1 time_activity_adj_8_1 time_activity_adj_9_1 time_activity_adj_10_1 time_activity_adj_11_1 time_activity_adj_12_1 time_activity_adj_13_1 time_activity_adj_14_1)

	egen num_activities_600_630 = rowtotal(time_activity_adj_1_2 time_activity_adj_2_2 time_activity_adj_3_2 time_activity_adj_4_2 time_activity_adj_5_2 time_activity_adj_6_2 time_activity_adj_7_2 time_activity_adj_8_2 time_activity_adj_9_2 time_activity_adj_10_2 time_activity_adj_11_2 time_activity_adj_12_2 time_activity_adj_13_2 time_activity_adj_14_2)

	egen num_activities_630_700 = rowtotal(time_activity_adj_1_3 time_activity_adj_2_3 time_activity_adj_3_3 time_activity_adj_4_3 time_activity_adj_5_3 time_activity_adj_6_3 time_activity_adj_7_3 time_activity_adj_8_3 time_activity_adj_9_3 time_activity_adj_10_3 time_activity_adj_11_3 time_activity_adj_12_3 time_activity_adj_13_3 time_activity_adj_14_3)

	egen num_activities_700_730 = rowtotal(time_activity_adj_1_4 time_activity_adj_2_4 time_activity_adj_3_4 time_activity_adj_4_4 time_activity_adj_5_4 time_activity_adj_6_4 time_activity_adj_7_4 time_activity_adj_8_4 time_activity_adj_9_4 time_activity_adj_10_4 time_activity_adj_11_4 time_activity_adj_12_4 time_activity_adj_13_4 time_activity_adj_14_4)

	egen num_activities_730_800 = rowtotal(time_activity_adj_1_5 time_activity_adj_2_5 time_activity_adj_3_5 time_activity_adj_4_5 time_activity_adj_5_5 time_activity_adj_6_5 time_activity_adj_7_5 time_activity_adj_8_5 time_activity_adj_9_5 time_activity_adj_10_5 time_activity_adj_11_5 time_activity_adj_12_5 time_activity_adj_13_5 time_activity_adj_14_5)

	egen num_activities_800_830 = rowtotal(time_activity_adj_1_6 time_activity_adj_2_6 time_activity_adj_3_6 time_activity_adj_4_6 time_activity_adj_5_6 time_activity_adj_6_6 time_activity_adj_7_6 time_activity_adj_8_6 time_activity_adj_9_6 time_activity_adj_10_6 time_activity_adj_11_6 time_activity_adj_12_6 time_activity_adj_13_6 time_activity_adj_14_6)

	egen num_activities_830_900 = rowtotal(time_activity_adj_1_7 time_activity_adj_2_7 time_activity_adj_3_7 time_activity_adj_4_7 time_activity_adj_5_7 time_activity_adj_6_7 time_activity_adj_7_7 time_activity_adj_8_7 time_activity_adj_9_7 time_activity_adj_10_7 time_activity_adj_11_7 time_activity_adj_12_7 time_activity_adj_13_7 time_activity_adj_14_7)

	gen last_sleep_time_slot = 0
	forval i = 1/6 {
		local k = `i' + 1
		replace last_sleep_time_slot = `i' if time_activity_11_`i' == 1 & time_activity_11_`k' == 0
	}
	replace last_sleep_time_slot = 7 if time_activity_11_7 == 1

	lab def last_sleep_time_slot 0 "Before 5:30" 1 "5:30-6:00" 2 "6:00-6:30" 3 "6:30-7:00" 4 "7:00-7:30" 5 "7:30-8:00" 6 "8:00-8:30" 7 "8:30-9:00" , replace
	lab val last_sleep_time_slot last_sleep_time_slot

	keep pid date last_sleep_time_slot time_bed_hours
	sort pid date
	
	save "$temp/lss_time_use_sleep.dta" , replace







	use "$temp/00_mainstudy_master.dta", clear
	merge 1:m pid using "$temp/lss_time_use_sleep.dta", keep(3) nogen
	bys pid (date) : gen times_surveyed = _N



	gr bar (meanci) time_bed_hours [w= times_surveyed], over(treatment) ytitle("Bed Time") ylabel(0(1)25)

	tab last_sleep_time_slot , gen(last_sleep_time_slot_)
	lab var last_sleep_time_slot_1 "Before 5:30"
	lab var last_sleep_time_slot_2 "5:30-6:00"
	lab var last_sleep_time_slot_3 "6:00-6:30"
	lab var last_sleep_time_slot_4 "6:30-7:00"
	lab var last_sleep_time_slot_5 "7:00-7:30"
	lab var last_sleep_time_slot_6 "7:30-8:00"
	lab var last_sleep_time_slot_7 "8:00-8:30"
	gr bar (meanci) last_sleep_time_slot_* [w= times_surveyed], over(treatment) ytitle("Last Sleep Time Slot")  legend(order(1 "Before 5:30" 2 "5:30-6:00" 3 "6:00-6:30" 4 "6:30-7:00" 5 "7:00-7:30" 6 "7:30-8:00" 7 "8:00-8:30"))

