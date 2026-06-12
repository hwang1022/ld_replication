**************************************************
*	Project: LD Main Study
*	Purpose: Shock Module Renaming
*	Author: HW 
* 	Adapted from 1_sm_naming.do by Luisa
*	Last modified: Sep-10-2024 (HW)
**************************************************


***********************	
**# Load Raw Datasets
***********************

	* HW cannot locate the raw dataset in the Dropbox folder so downloaded from Server
	
***************
**# Version 1
***************


	use "$raw/lss_shock_module_v1.dta" , clear
	drop if z0 == 999 // Drop 1 legit incomplete
	
	
	
***#
**## Rename Variables
****	

	* Cover
	gen __COVER__________ = .
	drop stand
	rename p0            	stand
	rename p1            	pid
	rename p3            	date
	rename z0            	check_completion
	rename z0_a 			incomplete_why
	rename z0_a_998			incomplete_why_oth
	rename z1				comfirm_pid
	gen version = 1
	order 	__COVER__________ pid  stand date check_completion incomplete_why incomplete_why_oth key comfirm_pid version
		
		
	* Event
	gen __EVENTS__________ = .
	rename q1_1      invited_wedding
	rename q1_2      invited_funeral
	rename q1_3      invited_festival
	rename q1_4      invited_pilgrimage
	rename q1_5      invited_childschool
	rename q1_998    invited_998
	rename q1_999    invited_999
	rename q1_others invited_others
	order 	__EVENTS__________ invited_wedding invited_funeral invited_festival ///
			invited_pilgrimage invited_childschool invited_998 invited_999 invited_others , after(version)
			

	qui tab event_num
	assert `r(r)' == 2

	forv i = 1/`r(r)' {
		rename event_name_`i' invited_name`i'
		rename q2_`i'      invited_days`i'
		rename q3_1_`i'    invited_startdate`i'
		rename q3_2_`i'    invited_enddate`i'
		rename q4_`i'      invited_location`i'
		rename q5_`i'      invited_attend`i'
		rename q6_`i'      invited_back_date`i'
		rename q7_`i'      invited_pressure`i'
	}
	order 	invited_name1 invited_days1 invited_startdate1 invited_enddate1 invited_location1 invited_attend1 ///
			invited_back_date1 invited_pressure1 invited_name2 invited_days2 invited_startdate2 invited_enddate2 ///
			invited_location2 invited_attend2 invited_back_date2 invited_pressure2 , after(invited_others)
	
	
	
	* Happen
	gen __HAPPEN__________ = .
	drop q8
	rename q8_1      happened_sick
	rename q8_2      happened_famsick
	rename q8_3      happened_birth
	rename q8_4      happened_death 
	rename q8_5      happened_emergency
	rename q8_6      happened_agwork
	rename q8_7      happened_property
	rename q8_998    happened_998
	rename q8_999    happened_999
	rename q8_others happened_others
	

	qui tab happen_num
	assert `r(r)' == 2
	forv i = 1/`r(r)' {
		rename happen_name_`i' happened_name`i'
		rename q9_`i'      happened_days`i'
		rename q10_1_`i'   happened_startdate`i'
		rename q10_2_`i'   happened_enddate`i'
		rename q11_`i'     happened_location`i'
		rename q12_`i'     happened_attend`i'
		rename q13_`i'     happened_back_date`i'
		rename q14_`i'     happened_pressure`i'
	}
	
	
	order 	__HAPPEN__________ happened_sick happened_famsick happened_birth happened_death happened_emergency ///
			happened_agwork happened_property happened_998 happened_999 happened_others happened_name1 happened_days1 happened_startdate1 ///
			happened_enddate1 happened_location1 happened_attend1 happened_back_date1 happened_pressure1  ///
			happened_name2 happened_days2 happened_startdate2 happened_enddate2 happened_location2 happened_attend2 ///
			happened_back_date2 happened_pressure2 , after(invited_pressure2)
		
	
	
	* Sanity Check
	gen __CHECKS__________ = .
	rename q15      native_return_request
	rename q16      native_emergency
	rename q17      other_issues
	rename q17_1    other_issues_reason
	rename q17_2    other_issues_reason_others
	
	order __CHECKS__________ native_return_request native_emergency other_issues other_issues_reason other_issues_reason_others , after(happened_pressure2) 
	
	
	* Drop all remaining variables
	keep __COVER__________-other_issues_reason_others
	
	
	* Save Dataset
	save "$temp/lss_shock_module_v1_renamed.dta" , replace
	
	

	
	
	
***************
**# Version 2
***************

	use "$raw/lss_shock_module_v2.dta" , clear
	drop if z0 == 999 // Drop 1 legit incomplete
	
	
***#
**## Rename Variables
****	

	* Cover
	gen __COVER__________ = .
	rename stand		 	stand_prefill
	rename p0            	stand
	rename p0_998		 	stand_others
	rename p1            	pid
	rename p1_1			 	batch
	rename p2            	interviewer
	rename p2_998        	interviewer_others
	rename p3            	date
	rename z0            	check_completion
	rename z0_a 			incomplete_why
	rename z0_a_998			incomplete_why_oth
	rename z1				comfirm_pid
	gen version = 2
	order 	__COVER__________ pid launchset treatment stand_prefill stand stand_others batch interviewer ///
			interviewer_others date check_completion incomplete_why incomplete_why_oth comfirm_pid key recall_days version
		
		
	* Event
	gen __EVENTS__________ = .
	rename q1_1      invited_wedding
	rename q1_2      invited_funeral
	rename q1_3      invited_festival
	rename q1_4      invited_pilgrimage
	rename q1_5      invited_childschool
	rename q1_998    invited_998
	rename q1_999    invited_999
	rename q1_others invited_others
	order 	__EVENTS__________ invited_wedding invited_funeral invited_festival ///
			invited_pilgrimage invited_childschool invited_998 invited_999 invited_others , after(version)
			

	qui tab event_num
	assert `r(r)' == 2

	forv i = 1/`r(r)' {
		rename event_name_`i' invited_name`i'
		rename q18_`i'     invited_if_one_day`i'
		rename q2_`i'      invited_days`i'
		rename q3_1_`i'    invited_startdate`i'
		rename q3_2_`i'    invited_enddate`i'
		rename q4_`i'      invited_location`i'
		rename q5_`i'      invited_attend`i'
		rename q6_`i'      invited_back_date`i'
		rename q7_`i'      invited_pressure`i'
	}
	order 	invited_name1 invited_if_one_day1 invited_days1 invited_startdate1 invited_enddate1 invited_location1 invited_attend1 ///
			invited_back_date1 invited_pressure1 invited_name2 invited_if_one_day2 invited_days2 invited_startdate2 invited_enddate2 ///
			invited_location2 invited_attend2 invited_back_date2 invited_pressure2 , after(invited_others)
	
	
	
	* Happen
	gen __HAPPEN__________ = .
	drop q8
	rename q8_1      happened_sick
	rename q8_2      happened_famsick
	rename q8_3      happened_birth
	rename q8_4      happened_death 
	rename q8_5      happened_emergency
	rename q8_6      happened_agwork
	rename q8_7      happened_property
	rename q8_998    happened_998
	rename q8_999    happened_999
	rename q8_others happened_others
	

	qui tab happen_num
	assert `r(r)' == 2
	forv i = 1/`r(r)' {
		rename happen_name_`i' happened_name`i'
		rename q19_`i'     happened_if_one_day`i'
		rename q9_`i'      happened_days`i'
		rename q10_1_`i'   happened_startdate`i'
		rename q10_2_`i'   happened_enddate`i'
		rename q11_`i'     happened_location`i'
		rename q12_`i'     happened_attend`i'
		rename q13_`i'     happened_back_date`i'
		rename q14_`i'     happened_pressure`i'
	}
	
	
	order 	__HAPPEN__________ happened_sick happened_famsick happened_birth happened_death happened_emergency ///
			happened_agwork happened_property happened_998 happened_999 happened_others happened_name1 happened_if_one_day1 ///
			happened_days1 happened_startdate1 happened_enddate1 happened_location1 happened_attend1 happened_back_date1 ///
			happened_pressure1 happened_name2 happened_if_one_day2 happened_days2 happened_startdate2 happened_enddate2 ///
			happened_location2 happened_attend2 happened_back_date2 happened_pressure2 , after(invited_pressure2)
		
	
	
	* Sanity Check
	gen __CHECKS__________ = .
	rename q15      native_return_request
	rename q16      native_emergency
	rename q17      other_issues
	rename q17_1    other_issues_reason
	rename q17_2    other_issues_reason_others
	
	order __CHECKS__________ native_return_request native_emergency other_issues other_issues_reason other_issues_reason_others , after(happened_pressure2) 
	
	
	
	* Drop all remaining variables
	keep __COVER__________-other_issues_reason_others
	
	
	
	* Save Dataset
	save "$temp/lss_shock_module_v2_renamed.dta" , replace
	
	
	
	
***************
**# Save Data
***************	
	
	use "$temp/lss_shock_module_v2_renamed.dta" , clear
	append using "$temp/lss_shock_module_v1_renamed.dta"
	
	
	save "$temp/01_shock_module_named_hw.dta" , replace
	
	
