*************************************************
*************************************************
*	Project: LD Main Study
*	Purpose: Phase 1 and phase 2 combine
*	Author: HW
*	Last modified: 2024-11-12 (HW)
*************************************************
*************************************************

	* Define a program that conveniently replaces all 7 of the same variable
	cap program drop apply7 
	program define apply7 
	
		forval i = 1/7 {
			
			local current_command `"`0'"'
			local current_command = subinstr(`"`current_command'"', "_ ", "_`i' ", .) 
			local current_command = subinstr(`"`current_command'"', "_)", "_`i')", .) 
			local current_command = regexreplace(`"`current_command'"', "_$", "_`i'") 
			`current_command'
		}
	end
	
	
**********************************
**# 1. Append 2 cleaned datasets
**********************************

****
**## Merge Phases
****

	use "$temp/03_phase1_completed_cleaned.dta", clear
	isid pid date
	
	local tostring_vars d_how_found_native_others_2 d_howfound_others_3 d_why_notattend_others_3 ///
						d_why_notattend_others_4 d_comp_reason_998
	foreach i of varlist `tostring_vars' {
		tostring `i' , replace
		replace `i' = "" if `i' == "."
	}	
	gen phase_source = 1

	
	preserve
	
		use "$temp/03_phase2_completed_cleaned.dta" , clear
		rename f_* d_*
		
		local tostring_vars stand_others reason_not_proceed_others check_reason_inc_sp_others ///
							d_whenfound_others_1 d_how_found_native_others_1 d_how_found_native_others_4 ///
							d_why_attend_others_5 d_spend_day_others_6 d_spend_day_others_7 ///
							d_part_leave_reason_others
		foreach i of varlist `tostring_vars' {
			tostring `i' , replace
			replace `i' = "" if `i' == "."
		}
		
		gen phase_source = 2
		
		tempfile phase2merge
		save `phase2merge' , replace
	
	restore
	

	append using  `phase2merge'


****
**## Drop Obs
****

	// Identify if there are phone surveys marked as completed but are totally empty
	drop if mi(d_work_1) & mi(d_main_activity_1) & mode == 2
	
		
****	
**## Restrict Sample
****

	merge m:1 pid using "$temp/00_mainstudy_master.dta" , keep(3) nogen keepusing(pid)
	sort pid date
	


****	
**## FEB 2025 fix spot time
****
	

	replace arrival_time_string = "" if mode != 1
	replace arrival_time_text = "" if mode != 1
	
	
	replace arrival_time_text = subinstr(arrival_time_text, ":", " ", .)
	replace arrival_time_text = subinstr(arrival_time_text, ".", " ", .)
	replace arrival_time_text = subinstr(arrival_time_text, ",", " ", .)
	replace arrival_time_text = subinstr(arrival_time_text, ";", " ", .)
	
	strclean arrival_time_text , replace keepc("\d\s")
	split arrival_time_text , gen(spot_time_text)
	destring  spot_time_text1 spot_time_text2 , replace
	replace spot_time_text1 = . if spot_time_text1 < 5 | spot_time_text1 > 10
	replace spot_time_text2 = . if spot_time_text2 >= 60 | spot_time_text2 < 0
	
	
	gen spot_time_sr = spot_time_text1 + spot_time_text2/60
	
	
	gen spot_time = clock(arrival_time_string, "hms")
	format %tcHH:MM:SS spot_time
	gen spot_time_tr = hh(spot_time) + mm(spot_time)/60 + ss(spot_time)/3600
	
	replace spot_time_tr = spot_time_sr if spot_time_tr > 10.5 | spot_time_tr < 5.5
	
	
	drop arrival_time_string arrival_time_text arrival_time spot_time_text1 spot_time_text2 spot_time_text3 spot_time_sr spot_time
	rename spot_time_tr arrival_time
	
	
	* As of Feb 11 there are 6 times I don't know how to fix
	/*
	replace spot_time_sr = tc(01jan1960 6:28:28) if deviceid == "5e3afbdf2f09153a" & arrival_time_string == "6:28:28 PM"
	replace spot_time_sr = tc(01jan1960 6:33:30) if deviceid == "5e3afbdf2f09153a" & arrival_time_string == "6:33:30 PM"
	replace spot_time_sr = tc(01jan1960 6:35:46) if deviceid == "869432027503718" & arrival_time_string == "6:35:46 PM"
	replace spot_time_sr = tc(01jan1960 6:27:18) if deviceid == "692bb00b81f91b92" & arrival_time_string == "6:27:18 PM"
	replace spot_time_sr = tc(01jan1960 7:03:50) if deviceid == "8fb9a480e1856583" & arrival_time_string == "7:03:50 PM"
	replace spot_time_sr = tc(01jan1960 8:51:13) if deviceid == "3df6903d9ab8bc62" & arrival_time_string == "8:51:13 PM"
	*/
	

************************
**# 2. Manipulate Vars
************************

****
**## Drop Vars
****


	* Drop Cover
	order deviceid mode arrival_time phase_source
	drop 	interviewer-today recall_days_cp-recall_days_mpc launchset-index_1 index_* ///
	
	* Drop Comp
	drop 	rf_5 rf_6 rf_7 d_comp_reason_absence-d_comp_completion ///
			d_comp_reason_absence_v2 d_comp_where_v2 d_comp_reason_others d14* d17* f17* 
	
	* Drop Fitbit Stuff
	drop rf14_* rf15_* rf16_* rf17_*
	
	* Drop Tail
	drop count_complete-filename
	
	* Drop payment related vars but empty
	drop rf1_a_paid_* rf1_a_due_*
	
	
****
**## Rename Vars
****	
	
	* Replace specify other "f12. Why did you not try to work?"
	rename rd12_998_* d_why_nottry_oth_* 
	apply7 replace d_why_nottry_oth_ =  rf12_998_ if mi(d_why_nottry_oth_)
	drop rf12_998_*

	
	* Main activity is other
	apply7 rename d_main_act_others_ 	d_main_act_other_spec_
	apply7 rename d_main_act_998_ 		d_main_act_other_
	
	* Is there a particular reason why you didn't come to the stand 1 days ago to search for a job?
	apply7 replace d_why_attend_ =  d_why_notattend_v2_ if mi(d_why_attend_)
	drop d_why_notattend_v2_*
	
	* How did you find this job?
	apply7 replace d_howfound_ =  d_howfound_v2_ if mi(d_howfound_)
	drop d_howfound_v2_*
	
	* Main Act: Friends
	forval i=1/7 {
		replace d_main_act_friends_time_`i' = d_main_act_friends_time`i'  if mi(d_main_act_friends_time_`i')
		drop d_main_act_friends_time`i'
	}
	
	 
****
**## Reconcile How Spend and Main Activity
****

	apply7 replace d_work_ = . if d_work_ == 999
		
	apply7 replace d_main_act_work_ = d_work_ if mi(d_main_activity_ ) & !mi(d_work_)
	apply7 replace d_main_act_work_ = 0 if d_howfound_ == 4 | d_howfound_notattend_ == 4 // Here d_main_act_work_? means work for pay
	

	apply7 replace d_main_act_hh_chores_		= 	d_spend_day_ == 2 if mi(d_main_activity_ ) &  !mi(d_spend_day_ )	// checked
	apply7 replace d_main_act_home_rest_		= 	d_spend_day_ == 5 if mi(d_main_activity_ ) &  !mi(d_spend_day_ )	// checked
	apply7 replace d_main_act_self_employed_	= 	(d_howfound_ == 4 | d_howfound_notattend_ == 4) if ///
													mi(d_main_activity_ ) &  ///
													(!mi(d_howfound_ ) | !mi(d_howfound_notattend_ ))	// checked
	apply7 replace d_main_act_self_employed_	= 0 if d_work_ == 0
	apply7 replace d_main_act_sick_				= 	d_why_nottry_ == 4 if mi(d_main_activity_ ) &  !mi(d_why_nottry_ )	// checked	
	apply7 replace d_main_act_planned_event_	= 	d_spend_day_ == 4 if mi(d_main_activity_ ) 	&  !mi(d_spend_day_ )	// checked
	apply7 replace d_main_act_emergency_		= 	d_spend_day_ == 6 if mi(d_main_activity_ ) 	&  !mi(d_spend_day_ )	// checked
	apply7 replace d_main_act_travel_			= 	d_spend_day_ == 7 if mi(d_main_activity_ ) 	&  !mi(d_spend_day_ )	// checked
	apply7 replace d_main_act_family_time_		= 	d_spend_day_ == 1 if mi(d_main_activity_ ) 	&  !mi(d_spend_day_ )	// checked
	apply7 replace d_main_act_friends_time_		= 	d_spend_day_ == 3 if mi(d_main_activity_ ) 	&  !mi(d_spend_day_ )	// checked
	apply7 replace d_main_act_other_			= 	(d_spend_day_ == 998 | d_why_nottry_ == 998) if ///
													mi(d_main_activity_ ) &  ///
													(!mi(d_spend_day_ ) | !mi(d_why_nottry_ ))	// checked
	
	
	apply7 replace d_work_ = d_main_act_work_	// Here d_work_? means work for pay
	
	* Replace other activities = 0 if work (either for pay or self employee)
	apply7 replace d_main_act_hh_chores_		= 	0 if (d_main_act_work_ == 1 | d_main_act_self_employed_ == 1) & mi(d_main_act_hh_chores_)
	apply7 replace d_main_act_home_rest_		= 	0 if (d_main_act_work_ == 1 | d_main_act_self_employed_ == 1) & mi(d_main_act_home_rest_)
	apply7 replace d_main_act_sick_				= 	0 if (d_main_act_work_ == 1 | d_main_act_self_employed_ == 1) & mi(d_main_act_sick_)
	apply7 replace d_main_act_planned_event_	= 	0 if (d_main_act_work_ == 1 | d_main_act_self_employed_ == 1) & mi(d_main_act_planned_event_)
	apply7 replace d_main_act_emergency_		= 	0 if (d_main_act_work_ == 1 | d_main_act_self_employed_ == 1) & mi(d_main_act_emergency_)
	apply7 replace d_main_act_travel_			= 	0 if (d_main_act_work_ == 1 | d_main_act_self_employed_ == 1) & mi(d_main_act_travel_)
	apply7 replace d_main_act_family_time_		= 	0 if (d_main_act_work_ == 1 | d_main_act_self_employed_ == 1) & mi(d_main_act_family_time_)
	apply7 replace d_main_act_friends_time_		= 	0 if (d_main_act_work_ == 1 | d_main_act_self_employed_ == 1) & mi(d_main_act_friends_time_)
	apply7 replace d_main_act_other_			= 	0 if (d_main_act_work_ == 1 | d_main_act_self_employed_ == 1) & mi(d_main_act_other_)
	
	
	* Fill others with 0 if one of them is 1
	foreach i in "d_main_act_hh_chores_" "d_main_act_home_rest_" "d_main_act_self_employed_" "d_main_act_work_" "d_main_act_sick_" "d_main_act_planned_event_" "d_main_act_emergency_" "d_main_act_travel_" "d_main_act_family_time_" "d_main_act_friends_time_" "d_main_act_other_" {
		foreach j in "d_main_act_hh_chores_" "d_main_act_home_rest_" "d_main_act_self_employed_" "d_main_act_work_" "d_main_act_sick_" "d_main_act_planned_event_" "d_main_act_emergency_" "d_main_act_travel_" "d_main_act_family_time_" "d_main_act_friends_time_" "d_main_act_other_" {
			
			forval k = 1/7 {
				replace `j'`k' = 0 if `i'`k' == 1 & mi(`j'`k')
			}
		}
	} 
	
	* If the person didn't work and don't have any other main activity, it must be that they looked for a job but failed. 
	* There is no option for looking for job as main activity so I replace everything with 0
	foreach i in "d_main_act_hh_chores_" "d_main_act_home_rest_" "d_main_act_sick_" "d_main_act_planned_event_" "d_main_act_emergency_" "d_main_act_travel_" "d_main_act_family_time_" "d_main_act_friends_time_" "d_main_act_other_" {
		forval k = 1/7 {
			replace `i'`k' = 0 if d_main_act_self_employed_`k' == 0 & d_main_act_work_`k' == 0 & mi(`i'`k')
		}
	}
	
	
	* If comprehensive recall shows 0 days worked then replace 7 days of recall with 0
	apply7 replace  d_work_ = 0 if d_comp_worked == 0
	apply7 replace  d_earn_ = . if d_comp_worked == 0
	
	 
****
**## Multi-day Job
****	

	apply7 replace d_multiday_job_ = d_multidayjob_notattend_ 	if mi(d_multiday_job_)
	apply7 replace d_multiday_job_ = d_howfound_ == 5 			if mi(d_multiday_job_) & !mi(d_howfound_ )
	apply7 replace d_multiday_job_ = d_howfound_notattend_ == 5 if mi(d_multiday_job_) & !mi(d_howfound_notattend_ )
	
	apply7 gen d_multiday_job_cond_ = d_multiday_job_
	apply7 replace d_multiday_job_ = 0 if d_work_ == 0
	
	apply7 drop d_multidayjob_notattend_
	
****	
**## Earning
****

	apply7 replace d_earn_ = d_earn_ + d_paid_filt_ if !mi(d_paid_filt_ )
	apply7 replace d_earn_ = . if d_earn_ == pid 	// 4 instances where earning is equal to pid????
	apply7 replace d_earn_ = . if d_earn_ == 999

*****************************	
**# 3. Comprehensive Recall
*****************************

	* Clean Recent date
	gen recent_date_dt = date(recent_date, "YMD")
	format recent_date_dt %td
	drop recent_date
	rename recent_date_dt recent_date
	
	count if !mi(d_comp_worked) & !mi(recent_date) & recent_date >= date // There is no case where recent day is in the future for obs with comp recall  
	
	
	* Generate used_recall_days, which is the actual number of days recalled in Comp Recall section
	gen used_recall_days = .
	replace used_recall_days = date - recent_date if !mi(d_comp_worked) & !mi(recent_date)
	replace used_recall_days = recall_days if !mi(d_comp_worked) & mi(recent_date) // replace used_recall_days with recall_days if recent_date is empty. This happens mostly on the first day of phase 2
	
	* Validate the recent_date, generate a used_recent_date that is most likely to be accurate
	gen used_recent_date = .
	replace used_recent_date = date - used_recall_days if !mi(used_recall_days)
	
	assert !mi(used_recall_days) & !mi(used_recent_date) if !mi(d_comp_worked)
	
	
******************	
**# Save Dataset
******************	

	save "$temp/04_phase1_phase2_cleaned.dta", replace
	
