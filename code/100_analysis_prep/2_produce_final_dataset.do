**************************************************
**************************************************
*	Project: LD Main Study
*	Purpose: Construct fulloutcomes 
*	Author: HW, based on Daryl
*	Last modified: Nov 14, 2024
**************************************************
**************************************************

	use "$temp/03_bs_phase123_makevardaily_weekly_${data_version}.dta", clear
	

	
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

	* Old code, Not used as of May 28 2026
	/*
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
	*/

	merge m:1 date using "$final/calevents_clean.dta", keep(1 3) nogen


*************
**# Weather
*************

	if "$weather_data" == "raw"{
		merge m:1 stand date using "$final/weather_shock_final_day_stand.dta", keep(1 3) nogen keepusing(__RAW_WEATHER_____ mean_at mean_at_rec max_at max_at_rec accu_prec accu_prec_rec max_wc max_wc_rec __RAIN_CODE_____ wc_1 wc_2 wc_3 wc_4 wc_5 wc_6 wc_7 wc_rec_1 wc_rec_2 wc_rec_3 wc_rec_4 wc_rec_5 wc_rec_6 wc_rec_7 wc_geq_1 wc_geq_2 wc_geq_3 wc_geq_4 wc_geq_5 wc_geq_6 wc_geq_1_rec wc_geq_2_rec wc_geq_3_rec wc_geq_4_rec wc_geq_5_rec wc_geq_6_rec)
	}
	
	if "$weather_data" == "percentile"{
		merge m:1 stand date using "$final/weather_shock_final_day_stand.dta", keep(1 3) nogen keepusing(__RAW_WEATHER_____-wc_geq_6_rec)
	}
	
	if "$weather_data" == "all"{
		merge m:1 stand date using "$final/weather_shock_final_day_stand.dta", keep(1 3) nogen
	}


	* Options:
		* "none" or "": Do not merge weather data to the final dataset
		* "raw": Merge raw weather data at stand-date-level. This includes mean apparent temperature, mean apparent temperature during recruitment hours, max apparent temperature, max apparent temperature during recruitment hours, cumulative precipitation, precipitation during recruitment hours, and maximum weather code (the worst weather during the period) and weather code during recruitment hours.
		* "percentile": Merge weather data at stand-date-level, but in addition to the raw weather data, include indicators for whether each weather variable falls in the top 85, 90, 95, 99% of values across all stand-date combinations of the calendar year.
		* "all": Merge weather data at stand-date-level, but in addition to the raw weather data and percentile indicators, include rolling averages and lags of weather variables.
	

*********************************
**# Final Cleaning and Labeling
*********************************
	
	lab var treatment "Treatment"


	* Labels for Where and How Found Job 
	lab var whenfound "When Found (Cond. SR Attend)"
	lab var howfound "How Found (Cond. SR Attend)"
	lab var howfound_notattend "How Found (Cond. SR Not Attend)"

	lab def whenfound 1 "I already had a job before coming to the stand" 2 "While at the stand (friend gave me a job, met recruiter, recruiter phone called me, etc.)" 3 "After I left the stand without finding a job" , replace
	lab val whenfound whenfound

	/*
	lab def howfound 1 "Phone- An employer/owner called me/I called the employer" 2 "Phone- A recruiter/contractor contacted me/I called the recruiter" 3 "Phone- A friend or family member offered me work/I called them" 4 "Self Employed- I worked for myself (self-owned business and earned an income)" 5 "Multi-day job with the same employer" 6 "Stand- recruiter/contractor called/ I called the recruiter/contractor" 7 "Stand- A friend or family member offered me job when I was at the stand" 8 "Stand- A recruiter offered me job when I was at the stand" , replace
	lab val howfound howfound

	lab def howfound_notattend 1 "Phone- An employer/owner called me/I called the employer" 2 "Phone- A recruiter/contractor contacted me/I called the recruiter" 3 "Phone- A friend or family member offered me work/I called them" 4 "Self Employed- I worked for myself (self-owned business and earned an income)" 5 "Multi-day job with the same employer" , replace
	lab val howfound_notattend howfound_notattend
	*/
	drop howfound howfound_notattend 
	

****************************
**# 4.  Save Final Dataset
****************************
	
	merge m:1 pid using "$temp/00_mainstudy_master.dta", keep(3) keepusing(pid) nogen 
	save "$main_data", replace
