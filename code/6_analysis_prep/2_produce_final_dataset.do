**************************************************
**************************************************
*	Project: LD Main Study
*	Purpose: Construct fulloutcomes 
*	Author: HW, based on Daryl
*	Last modified: Nov 14, 2024
**************************************************
**************************************************

	use "$temp/03_bs_phase123_makevardaily_weekly.dta", clear
	

	
**********************
**# 1. Baseline Data
**********************
		
	gen __4_BASELINE_COV________ = .
	merge m:1 pid using "$temp/05_baseline_cov.dta", keep(1 3) nogen
	
	
************************
**# 2.  Screening Data
************************

	gen __5_SCREENING_DEM________ = .
	merge m:1 pid using "$temp/06_screening_dem_vars_with_pid.dta", keep(1 3) nogen
	
	
****************************
**# 3.  Baseline Demo Data
****************************
	
	gen __6_BASELINE_DEM________ = .
	merge m:1 pid using "$temp/03_bs_demographics_completed_makevar.dta", keep(1 3) 
	gen took_baseline_demo = _merge == 3
	drop _merge
	order took_baseline_demo , after(__6_BASELINE_DEM________)
	
	drop if pid == 1944
	
	
***************************************
**# 4.  Phase 2 Activities and Others
***************************************	

****
**## Flexibility
****
	
	* HW: Outdated as of May 2025. Replaced by the one-line code below
	/*
	preserve
		use pid flex_question flex_ann_date flex_version fixed_choice_q first_day second_day ///
			using "$temp/06c_phase2act_flextest_combined_makevar.dta" , clear
		drop if mi(fixed_choice_q)
		rename flex_ann_date date
		
		reshape wide fixed_choice_q, i(pid) j(flex_question)
		egen flex_num_obs = rownonmiss(fixed_choice_q1 fixed_choice_q2)
		
		tempfile flex
		save `flex' , replace
	restore
	
	gen __7_PII_ACT_FLEX________ = .
	merge 1:1 pid date using `flex', keep(1 3) nogen
	*/

		/*
	merge 1:1 pid date using "$temp/05c_phase2act_flextest_combined.dta" , keep(1 3) nogen
*/
****	
**## Job Finding Probability
****	
	/*
	gen __7_JFP________ = .
	merge 1:1 pid date 	using "$temp/02_jfp_makevar_v2.dta", keep(1 3)  nogen
	*/
	
	
****	
**## Job List
****	
	
	gen __7_JOB_LIST________ = .
	merge 1:1 pid date 	using "$temp/03b_phase2act_joblist_cleaned_completed_v2.dta", ///
						keepusing(jl_*) keep(1 3)  nogen
	
****
**## Picture Quiz
****		
	/*
	gen __7_MULTI_QUIZ________ = .
	merge m:1 pid date using "$temp/02_picture_quiz_makevar.dta", keep(1 3) nogen
	*/

****
**## Shocks
****	
	/*
	gen __7_SHOCKS________ = .
	merge 1:1 pid date using "$temp/03_shock_module_panel_merged_hw.dta", keep(1 3)  nogen
	*/

****
**## Timeuse (HW Checked Jan 23 2025)
****	
	
/*
	gen __8_MULTI_TIMEUSE________ = .
	merge 1:1 pid date using "$temp/lss_time_use_cleaned_hw.dta" , keep(1 3) nogen
	*/
	
	
****
**## Vignettes
****	
	
	
	gen __9_SINGLE_VGNTTE________ = .
	merge 1:1 pid date using "$temp/03a_phase2act_vignettes_makevar_hw.dta", keep(1 3) keepusing(r_reg_morning_act_* r_morning_alarm cog_going_without_thinking) nogen
	
	
		
		
	/*	
****
**## Wives
****	
	
	gen __10_SINGLE_WIVES________ = .
	merge m:1 pid date using "$temp/03-wife-survey-cleaned.dta", keep(1 3) keepusing(wife_*) nogen
	
****
**## Odd Jobs
****	
	
	gen __11_SINGLE_ODD________ = .
	merge m:1 pid date using "$temp/01b_odd_jobs_named.dta", keep(1 3) keepusing(sat_survey-act_unpaid_mins) nogen
	foreach i of varlist sat_survey-act_unpaid_mins {
		rename `i' oj_`i'
	}
	*/
	

*********************
**# Calendar Events
*********************

	preserve
		use "$external/calevents_clean.dta", clear

		* Remove semicolons at beginning and end of calevent_description
		replace calevent_description = regexr(calevent_description, "^[\;]+", "")
		replace calevent_description = regexr(calevent_description, "[\;]+$", "")
		replace calevent_description = subinstr(calevent_description,";","; ",.)
		strclean calevent_description , replace proper

		* Replace calevent_worker_timeoff
		replace calevent_worker_timeoff = . if calevent != 1

		* Shorten variables
		rename calevent_worker_timeoff 	calevent_timeoff
		rename calevent_nationwide 		calevent_nation 
		rename calevent_auspicious 		calevent_ausp


		local calevents "timeoff tn nation ausp hindu christian muslim celebrated_scale"
		foreach x of local calevents{
			rename calevent_`x' cal_`x'
		}

		gen __CALENDAR_EVENTS_2022_____ = .	
		order __CALENDAR_EVENTS_2022_____

		tempfile cal_events
		save `cal_events' , replace

	restore

	merge m:1 date using `cal_events', keep(1 3) nogen



*********************************
**# Final Cleaning and Labeling
*********************************
	
	lab var treatment "Treatment"
	
	
****************************
**# 4.  Save Final Dataset
****************************
	
	merge m:1 pid using "$temp/00_mainstudy_master.dta", keep(3) keepusing(pid) nogen 
	save "$final/final_data_$data_version_new.dta", replace
	