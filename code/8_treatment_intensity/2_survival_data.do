************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Create data used for survival estimation
* 	Author:				HW 
* 	Created:			2025-May-27 (HW)
* 	Last modified:			2026-June-8 (ST)
************************************************************
************************************************************

	// Name of old data
	//local baseline_panel "$datadir/03. Baseline/02. Output/04_baseline_makepanel_no_limit_date.dta"
	local baseline_panel "$temp/04_baseline_makepanel_no_limit_date.dta"

***********************
**# Survival Function
***********************

	use "`baseline_panel'" , clear
	drop if inlist(stand,$droplist)


	
****
**## Time Left Hours
****

	* Convert time_left_stand from tc format to decimal hours
	gen time_left_hours = hh(time_left_stand) + mm(time_left_stand)/60 + ss(time_left_stand)/3600
	replace time_left_hours = . if time_left_hours < 5 | time_left_hours > 17

	count if !mi(time_left_hours)
	count if !mi(spot_time_hours)
	count if !mi(time_left_hours) & !mi(spot_time_hours)


****
**## Time find job
****

	* Convert time_found from tc format to decimal hours
	gen time_found_hours = hh(time_found) + mm(time_found)/60 + ss(time_found)/3600
	replace time_found_hours = . if time_found_hours < 5 | time_found_hours > 17

	count if !mi(time_found_hours)
	count if !mi(spot_time_hours)
	count if !mi(time_found_hours) & !mi(spot_time_hours)




****
**## Time Stay at Stand
****	

	keep if (!mi(time_found_hours)|!mi(time_left_hours)) & !mi(spot_time_hours)

	gen time_leave_hours = time_found_hours
	replace time_leave_hours = time_left_hours if mi(time_leave_hours)

	gen time_at_stand = time_leave_hours - spot_time_hours
	lab var time_at_stand "Time Spent at Stand"

	gen found_job = 0
	replace found_job = 1 if !mi(time_found_hours)
	lab def found_job 0 "No Job" 1 "Found Job" , replace
	lab val found_job found_job


	winsor2 time_at_stand , suffix("_t") cuts(1 99)

	save "$temp/survival_function_data.dta" , replace










