*************************************************
*************************************************
*	Project: LD Main Study
*	Purpose: Phase 1 and phase 2 combined
*	Author: HW
*	Last modified: 2025-05-09 (HW)
*************************************************
*************************************************


*************************
**# 1. Make Empty Panel
*************************
*************************
	
	* Identify maximum duration for the main sample
	use pid  using "$temp/00_mainstudy_master.dta" , clear
	gen start_date 	= td(21mar2022) - 14
	gen end_date 	= td(27nov2022) + 14
	gen duration 	= end_date - start_date + 1
	
	
	expand duration
	bys pid : gen date =  start_date + _n - 1
	format date %td	
	
	keep pid date
	
	
*******************
**# 2. Fill Panel
*******************

****
**## Merge Information Back
****

	* Merge Combined 
	merge 1:1 pid date using "$temp/04_phase1_phase2_cleaned.dta" , keep(1 3) nogen

	
	* Merge Attendance (Whether spotted and time)
	drop deviceid
	rename arrival_time arrival_time_tr
	merge 1:1 pid date using  "$raw/05_attendance_check.dta", ///
		keep(1 3) keepusing(deviceid seen arrival_time_hours) nogen
		

	* Update Attendance
	gen attend_spot = mode == 1
	order attend_spot , after(mode)
	replace attend_spot = 1 if seen == 1
	
	
	* Fill spot time (53 fixed)
	replace arrival_time_hours = . if !mi(arrival_time_tr)
	replace arrival_time_hours = arrival_time_hours - 9.5 if (arrival_time_hours < 5.5 | arrival_time_hours > 10.5) & !mi(arrival_time_hours) & deviceid == "162ff21c55c743bc" 
	replace arrival_time_hours = arrival_time_hours - 9.5 if (arrival_time_hours < 5.5 | arrival_time_hours > 10.5) & !mi(arrival_time_hours) & deviceid == "71dee13f6c50c1c0" 
	replace arrival_time_hours = arrival_time_hours - 9.5 if (arrival_time_hours < 5.5 | arrival_time_hours > 10.5) & !mi(arrival_time_hours) & deviceid == "b3dacea548618e3c"  
	

	replace arrival_time_hours = . if (arrival_time_hours < 5.5 | arrival_time_hours > 10.5) & !mi(arrival_time_hours) // 32 dropped because not sure how to fix
	
	* Final hours
	replace arrival_time_hours = arrival_time_tr if mi(arrival_time_hours) & !mi(arrival_time_tr)
	drop arrival_time_tr	
	
	
****
**## Fill recall
****	
	
	drop d_main_activity_* d_section_complete_*


	
	* Gen Recall Type (i.e. if it is in person grid recall)
	forval i = 1/7 {
		gen d_recall_reliable_`i' = .
		replace d_recall_reliable_`i' = 1 if mode == 1 & (!mi(d_work_`i') | !mi(d_main_act_work_`i'))
		replace d_recall_reliable_`i' = 0 if mode == 2 & (!mi(d_work_`i') | !mi(d_main_act_work_`i'))
		
		gen d_recall_source_`i' = .
		replace d_recall_source_`i' = mode if (!mi(d_work_`i') | !mi(d_main_act_work_`i'))
	}
	
	
	* In person dominates On Phone
	
	
	* Some string variables have become byte (.) because they are empty for all observations
	
	foreach i of varlist 	d_whenfound_others_2 d_whenfound_others_3 d_whenfound_others_4 ///
							d_whenfound_others_5 d_whenfound_others_6 d_whenfound_others_7 ///
							d_howfound_others_2 d_howfound_others_3 d_howfound_others_4 ///
							d_howfound_others_5 d_howfound_others_6 d_howfound_others_7 ///
							d_why_notattend_others_2 d_why_notattend_others_3 d_why_notattend_others_4 ///
							d_why_notattend_others_5 d_why_notattend_others_6 d_why_notattend_others_7 ///
							d_how_found_native_others_3 d_how_found_native_others_4 ///
							d_how_found_native_others_5 d_how_found_native_others_6 ///
							d_how_found_native_others_7 d_why_attend_others_6 d_why_attend_others_7 {
								tostring `i' , replace
								replace `i' = "" if `i' == "."
							}
	* <FIXME> LC 4/18/2026: for code logic, it's extremely important that recall_source is last
	local numericVars   work earn paid_filt notpaid_amt_due work_type role attend why_attend ///
						whenfound howfound howfound_notattend firsttime_emp native ///
						try_work why_notattend why_nottry how_found_native main_act_hh_chores main_act_home_rest ///
						main_act_self_employed main_act_work main_act_sick main_act_planned_event ///
						main_act_emergency main_act_travel main_act_family_time main_act_friends_time ///
						main_act_other multiday_job multiday_job_cond recall_reliable recall_source
	
	
	local stringVars	time_found why_attend_others whenfound_others howfound_others time_left_stand howfound_notattend_others ///
						why_notattend_others why_nottry_oth how_found_native_others main_act_other_spec
	
	
	
	
	* Gen day level variables
	foreach i in `numericVars' {
		gen `i' = .
	}
	foreach i in `stringVars' {
		gen `i' = ""
	}
	
	* Define locals 
	forval i = 1/7{
		local dvars_`i' 
		foreach w in `stringVars' {
			local dvars_`i' `dvars_`i'' d_`w'_`i'
		}
		
		foreach w in `numericVars' {
			local dvars_`i' `dvars_`i'' d_`w'_`i'
		}
	}
	
	* Change 999s to missing 
	forvalues z = 1/7 {
		foreach var in `numericVars' {
			replace d_`var'_`z' = . if d_`var'_`z' == 999
		}
		
		foreach var in `stringVars' {
			replace d_`var'_`z' = "" if d_`var'_`z' == "999"
		}
	}
	* <FIXME> LC: track which daily-grid survey (1-7 days ahead) filled this day
	gen daily_recall_lag = .
	lab var daily_recall_lag "Lag (1-7) from daily-grid survey that filled this day (first-fill-wins, updated by in-person upgrade)"
	
	* Indicators for non-missing  
 	forvalues i = 1/7 {
		egen d_`i'_nmissing = rownonmiss(`dvars_`i'') , strok
 	}
	egen nmissing = rownonmiss(`numericVars' `stringVars'), strok


	* Fill up key variables with relevant values	
	forvalues z = 1/7 {
		* <FIXME> LC: record the z for rows that will be filled in this iteration.
		* Must be written BEFORE the numericVars loop so `recall_source == 2` still
		* reflects the pre-upgrade state.
		if $prioritize_in_person == 1 {
			bys pid (date): replace daily_recall_lag = `z' if ///
			    d_`z'_nmissing[_n+`z'] != 0 & ///
			    (nmissing == 0 | (recall_source == 2 & mode[_n+`z'] == 1)) & ///
			    pid == pid[_n+`z']
		}
		else {
			bys pid (date): replace daily_recall_lag = `z' if ///
			    d_`z'_nmissing[_n+`z'] != 0 & nmissing == 0 & pid == pid[_n+`z']
		}
		foreach var in `numericVars' {
			if $prioritize_in_person == 1 {
				bys pid (date): replace `var'= d_`var'_`z'[_n+`z'] if ///
				d_`z'_nmissing[_n+`z'] != 0 & (nmissing == 0 | (recall_source == 2 & mode[_n+`z'] == 1)) & pid == pid[_n+`z'] & (d_`var'_`z'[_n+`z'] != 999 & d_`var'_`z'[_n+`z'] != .)
			}
			else {
				bys pid (date): replace `var'= d_`var'_`z'[_n+`z'] if ///
				d_`z'_nmissing[_n+`z'] != 0 & nmissing == 0 & pid == pid[_n+`z'] & d_`var'_`z'[_n+`z'] != 999
			}
		}
		
		foreach var in `stringVars' {
			if $prioritize_in_person == 1 {
				bys pid (date): replace `var'= d_`var'_`z'[_n+`z']  if ///
				d_`z'_nmissing[_n+`z'] != 0 & (nmissing == 0 | (recall_source == 2 & mode[_n+`z'] == 1)) & pid == pid[_n+`z'] & (d_`var'_`z'[_n+`z'] != "999" & d_`var'_`z'[_n+`z'] != "")
			}
			else {
				bys pid (date): replace `var'= d_`var'_`z'[_n+`z']  if ///
				d_`z'_nmissing[_n+`z'] != 0 & nmissing == 0 & pid == pid[_n+`z'] & d_`var'_`z'[_n+`z'] != "999"
			}
		}

		ereplace nmissing = rownonmiss(`numericVars' `stringVars'), strok 			
	}

* <FIXME> LC this can be deleted --> just checking some code logics and why the work variable changes
* Current version seems correct		
// 0. original
//
//     Variable |        Obs        Mean    Std. dev.       Min        Max
// -------------+---------------------------------------------------------
//         work |     20,780    .5306064    .4990744          0          1
//
// 1. recall_source is filled before work
//
//     Variable |        Obs        Mean    Std. dev.       Min        Max
// -------------+---------------------------------------------------------
//         work |     20,780    .5320982    .4989807          0          1
// 2. do not restrict on recall_source, only on mode[_n+`z'] == 1
//
//     Variable |        Obs        Mean    Std. dev.       Min        Max
// -------------+---------------------------------------------------------
//         work |     20,784    .5196305    .4996265          0          1
//
// 3. su work
//
//     Variable |        Obs        Mean    Std. dev.       Min        Max
// -------------+---------------------------------------------------------
//         work |     20,780    .5320982    .4989807          0          1



	rename d_comp* comp* 
	drop d_*

	
	* Rename attend
	rename attend 		attend_sr
	rename attend_spot 	attend
	
	* Replace Mode
	/* <FIXME> LC this is a bit confusing 
	--> this variable doesn't refere to whether the recall was done in person or on the phone.
	1. means that *on that day* there was an in person recall survey
	2. means that *on that day* there was a phone recall survey
	3. means that *on that day* there was no recall survey, but outcome vars were inputed using
		a later date survey.
	
	Perhaps we should distinguish between"
	- Survey mode (if any survey conducted on that date)
	- Survey source of the data that were imputed
	*/
	replace mode = 3 if mode == . & nmissing > 0 & !mi(nmissing)
	label define mode 3 "3. Recall (done in person or on the phone)", modify
	drop nmissing
	

	// save "$temp/04_phase1_phase2_panel_main.dta", replace
	
	
*****************************	
**# 3. Comprehensive Recall
*****************************

	* Identify Holidays and Sundays for Later
	gen holiday_or_sunday = 0
	gen dow = dow(date)
	replace holiday_or_sunday = 1 if dow == 0
	foreach i in $holiday_list {
		di "`i'"
		replace holiday_or_sunday = 1 if date == `i'
	}

	
	* Identify Recall Periods
	format %td used_recent_date
// 	br pid date work comp_worked used_recent_date used_recall_days
	
	gen index = _n
	gen recall_id = index if !mi(used_recall_days)
	gen comp_num_work_days = .
	
	// <FIXME> LC adds to match old code --> mode of comprehensive recall
	gen comp_recall_mode = .
	lab var comp_recall_mode "Mode of the comprehensive recall that filled this day (1=in-person, 2=phone)"
	
	* <FIXME> LC: track per-day distance from the comprehensive-recall survey row
	gen comp_recall_lag = .
	lab var comp_recall_lag "Lag in days from comprehensive-recall survey that covered this day"

	
	levelsof recall_id
	foreach i in `r(levels)' {
		sum index if recall_id == `i'
		local local_recall_days = used_recall_days[`r(mean)']
		local local_comp_worked = comp_worked[`r(mean)']
	    local local_comp_mode   = mode[`r(mean)']        // <FIXME> new LC pull the survey row's mode

		di "`local_comp_worked'"
		forval j = 1/`local_recall_days' {
			replace comp_num_work_days = `local_comp_worked' 	if index == `= `r(mean)' - `j'' & mi(recall_id)
			replace comp_recall_mode   = `local_comp_mode'   if index == `= `r(mean)' - `j'' & mi(recall_id)   // <FIXME> new LC
			replace comp_recall_lag    = `j'                 if index == `= `r(mean)' - `j'' & mi(recall_id)   // <FIXME> new LC
			replace recall_id = `i' 							if index == `= `r(mean)' - `j'' & mi(recall_id)
		}
		replace recall_id = . if recall_id == index & index == `r(mean)'
	}
	
	// LC adds
// 	replace comp_recall_mode = mode if !mi(used_recall_days) & mi(comp_recall_mode)

	
	* Recall Periods Duration
	bys recall_id : gen 	recall_period_duration = _N if !mi(recall_id)
	bys recall_id : egen 	num_days_identified = count(work) if !mi(recall_id)
	
	gen day_available_refill_inc_h = mi(work)
	replace day_available_refill_inc_h = . if mi(recall_id) 
	gen day_available_refill_exc_h = mi(work) & holiday_or_sunday == 0 
	replace day_available_refill_exc_h = . if mi(recall_id) 
	
	bys recall_id : egen num_days_available_inc_h = total(day_available_refill_inc_h) if !mi(recall_id)
	bys recall_id : egen num_days_available_exc_h = total(day_available_refill_exc_h) if !mi(recall_id)
	
	
	* Identify days worked, days worked that are already identified, days to be refilled
	bys recall_id : egen identified_work_days = total(work) if !mi(recall_id)
	bys recall_id : gen num_days_worked_to_refill = comp_num_work_days - identified_work_days if !mi(recall_id)
	replace num_days_worked_to_refill = 0 if num_days_worked_to_refill <= 0 // There are some smaller than 0
	sort pid date
	


**## Random Refill, Including Holidays

	preserve
		gen work_random_impute_inc_h = work
		
		* Case 1 of 2: No need to refill
		replace work_random_impute_inc_h = 0 if day_available_refill_inc_h == 1 & num_days_worked_to_refill == 0
		replace recall_id = . 					if num_days_worked_to_refill == 0
		replace day_available_refill_inc_h = . 	if num_days_worked_to_refill == 0
		replace num_days_worked_to_refill = . 	if num_days_worked_to_refill == 0
		
		
		* Case 2 of 2: Random refill
		bys recall_id 				: gen random_num = runiform() if day_available_refill_inc_h == 1 					& !mi(recall_id)
		bys recall_id (random_num) 	: gen work_random_impute = _n <= num_days_worked_to_refill 							if !mi(recall_id)
		bys recall_id (random_num) 	: replace work_random_impute = . if day_available_refill_inc_h != 1					& !mi(recall_id)
		replace work_random_impute_inc_h = work_random_impute if mi(work_random_impute_inc_h) & !mi(work_random_impute)	& !mi(recall_id)
	
		sort pid date
	
		keep pid date work_random_impute_inc_h
		tempfile work_random_impute_inc_h
		save `work_random_impute_inc_h'
	restore
	merge 1:1 pid date using `work_random_impute_inc_h' , nogen


**## Mean Refill, Including Holidays
	set seed 842

	preserve
		gen work_mean_impute_inc_h = work
		
		* Case 1 of 2: No need to refill
		replace work_mean_impute_inc_h = 0 if day_available_refill_inc_h == 1 & num_days_worked_to_refill == 0
		replace recall_id = . 					if num_days_worked_to_refill == 0
		replace num_days_worked_to_refill = . 	if num_days_worked_to_refill == 0
		replace day_available_refill_inc_h = . 	if num_days_worked_to_refill == 0
		
		
		* Case 1 of 2: No need to refill
		bys recall_id : gen mean_work = num_days_worked_to_refill / num_days_available_inc_h if day_available_refill_inc_h == 1 & !mi(recall_id)
		replace mean_work = 1 if mean_work > 1 & !mi(mean_work) & !mi(recall_id)
		replace work_mean_impute_inc_h = mean_work if mi(work_mean_impute_inc_h) & !mi(mean_work)	& !mi(recall_id)
		
		sort pid date
		
		keep pid date work_mean_impute_inc_h
		tempfile work_mean_impute_inc_h
		save `work_mean_impute_inc_h'
	restore
	merge 1:1 pid date using `work_mean_impute_inc_h' , nogen
	
	
**## Random Refill, Excluding Holidays
	set seed 749

	preserve
		gen work_random_impute_exc_h = work
		
		* Case 1 of 2: No need to refill
		replace work_random_impute_exc_h = 0 if day_available_refill_exc_h == 1 & num_days_worked_to_refill == 0
		replace recall_id = . 					if num_days_worked_to_refill == 0
		replace day_available_refill_exc_h = . 	if num_days_worked_to_refill == 0
		replace num_days_worked_to_refill = . 	if num_days_worked_to_refill == 0
		
		
		* Case 2 of 2: Random refill
		bys recall_id 				: gen random_num = runiform() if day_available_refill_exc_h == 1 					& !mi(recall_id)
		bys recall_id (random_num) 	: gen work_random_impute = _n <= num_days_worked_to_refill 							if !mi(recall_id)
		bys recall_id (random_num) 	: replace work_random_impute = . if day_available_refill_exc_h != 1					& !mi(recall_id)
		replace work_random_impute_exc_h = work_random_impute if mi(work_random_impute_exc_h) & !mi(work_random_impute)	& !mi(recall_id)
	
		sort pid date
	
		keep pid date work_random_impute_exc_h
		tempfile work_random_impute_exc_h
		save `work_random_impute_exc_h'
	restore
	merge 1:1 pid date using `work_random_impute_exc_h' , nogen


**## Mean Refill, Excluding Holidays

	preserve
		gen work_mean_impute_exc_h = work
		
		* Case 1 of 2: No need to refill
		replace work_mean_impute_exc_h = 0 if day_available_refill_exc_h == 1 & num_days_worked_to_refill == 0
		replace recall_id = . 					if num_days_worked_to_refill == 0
		replace num_days_worked_to_refill = . 	if num_days_worked_to_refill == 0
		replace day_available_refill_exc_h = . 	if num_days_worked_to_refill == 0
		
		
		* Case 1 of 2: No need to refill
		bys recall_id : gen mean_work = num_days_worked_to_refill / num_days_available_exc_h if day_available_refill_exc_h == 1 & !mi(recall_id)
		replace mean_work = 1 if mean_work > 1 & !mi(mean_work) & !mi(recall_id)
		replace work_mean_impute_exc_h = mean_work if mi(work_mean_impute_exc_h) & !mi(mean_work)	& !mi(recall_id)
		
		sort pid date
		
		keep pid date work_mean_impute_exc_h
		tempfile work_mean_impute_exc_h
		save `work_mean_impute_exc_h'
	restore
	merge 1:1 pid date using `work_mean_impute_exc_h' , nogen
	
	
	
	
****	
**## Final Vars
****



	gen work_orig = work 
	lab var work_orig "Work, no imputation"

	replace work = work_random_impute_exc_h
	lab var work "Work, random imputation"

	gen work1 = work_mean_impute_exc_h
	la var work1 "Work; imputed work as means instead of random assignment"
	
	//rename to_be_comp_refilled_backup comprehensive_recall
	//label var comprehensive_recall "=1 if work/wage data comes from comprehensive recall"
	
	
	// LC adds to match old
	gen work_source_inperson = .
	replace work_source_inperson = 1 if recall_reliable == 1
	replace work_source_inperson = 0 if recall_reliable == 0
	
	lab var work_source_inperson "Work value comes from an in-person recall (daily or comprehensive)"
	* Days where work was filled only by the comprehensive recall (work_orig missing,
	* work non-missing): use comp_recall_mode
	replace work_source_inperson = 1 if mi(work_source_inperson) & mi(work_orig) & !mi(work) & comp_recall_mode == 1
	replace work_source_inperson = 0 if mi(work_source_inperson) & mi(work_orig) & !mi(work) & comp_recall_mode == 2
	
	// <FIXME> LC delete afte
//	* Coverage
//	tab work_source_inperson phase, m
//	
//	* Source mix within comp-only fills
//	count if mi(work_orig) & !mi(work)
//	tab comp_recall_mode if mi(work_orig) & !mi(work), m
//	
//	* Sanity: no missing source when work is imputed from comp recall
//	count if mi(work_orig) & !mi(work) & mi(work_source_inperson)
			
	* <FIXME> LC: unified lag — prefer daily-grid (1-7), fall back to comp-recall (1-N)
	gen recall_lag_any = daily_recall_lag
	replace recall_lag_any = comp_recall_lag if mi(recall_lag_any) & !mi(comp_recall_lag)
	lab var recall_lag_any "Days between this day and the survey that filled its work value (daily grid: 1-7; comp recall: 1-N)"
	
	* <FIXME> LC adds labels
	la var recall_source "1 if recall data come from in person survey, 2 if from phone survey. For recalls from 7-day grid only."
	la var recall_reliable "1 if recall data come from in person survey, 2 if from phone survey, . if no recall or only comp recall available"

************************
**# 4. Restrict Sample
************************

	
	merge m:1 pid using "$raw/launch_prefill_pidwise_2022.dta", ///
		keep(1 3) keepusing(launchset stand) nogen
	
	gen p1_start_date = .
	gen p1_end_date = .
	gen p2_start_date = .
	gen p2_end_date = .
	forv i = 1/$numSetsTotal {
		replace p1_start_date = ${phase1StartSet`i'} if launchset == `i'
		replace p1_end_date = ${phase1EndSet`i'} if launchset == `i'
		replace p2_start_date = ${phase2StartSet`i'} if launchset == `i'
		replace p2_end_date = ${phase2EndSet`i'} if launchset == `i'
	}

	keep if (date >= p1_start_date & date <= p1_end_date) | (date >= p2_start_date & date <= p2_end_date)
	gen phase = .
	replace phase = 1 if date >= p1_start_date & date <= p1_end_date
	replace phase = 2 if date >= p2_start_date & date <= p2_end_date
	
	order phase , after(date)
	drop launchset *_date phase_source
	

	
************************
**# 5. Restrict Sample
************************	
	save "$temp/05_phase1_phase2_makepanel_unrestricted.dta", replace

	

	* <FIXME> LC adds work_source_inperson comp_recall_mode daily_recall_lag comp_recall_lag recall_lag_any
	keep pid stand date phase mode recall_reliable recall_source attend seen arrival_time_hours work earn work1 work_orig work_type role attend_sr main_act_hh_chores main_act_home_rest main_act_self_employed main_act_work main_act_sick main_act_planned_event main_act_emergency main_act_travel main_act_family_time main_act_friends_time main_act_other multiday_job multiday_job_cond work_source_inperson comp_recall_mode daily_recall_lag comp_recall_lag recall_lag_any
	
	// keep pid stand date holiday_or_sunday phase mode attend seen arrival_time_hours work work_mean_impute_* work_random_impute_* work_type role attend_sr main_act_hh_chores main_act_home_rest main_act_self_employed main_act_work main_act_sick main_act_planned_event main_act_emergency main_act_travel main_act_family_time main_act_friends_time main_act_other multiday_job multiday_job_cond	

	
	
	
*********************
**# 6. Save Dataset
*********************	

	save "$temp/05_phase1_phase2_makepanel.dta", replace
	
// * Daily lag should only be set where a daily fill happened
// tab daily_recall_lag, m
// count if !mi(daily_recall_lag) & mi(recall_reliable)    // should be 0
//
// * Comp lag only set on comp-window days
// tab comp_recall_lag, m
// count if !mi(comp_recall_lag) & mi(comp_recall_mode)    // should be 0
//
// * Combined coverage
// tab recall_lag_any, m
// count if !mi(work_orig) & mi(recall_lag_any)            // rows with daily fill but missing lag — should be 0
// count if !mi(work) & mi(work_orig) & mi(recall_lag_any) & !mi(comp_recall_mode)  // comp-filled rows missing lag — should be 0
