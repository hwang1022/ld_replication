**************************************************
* Project: LD
* Purpose: Make baseline panel data
* Author : Supraja
* Notes: 08-09-2021 (LC) Generation of holiday dummy now depends on global created within make_dates.do
* Last modified: 2025-07-18 (HW)
**************************************************


*******************
**# 1.  Open data
*******************

	use "$temp/03_baseline_completed_cleaned.dta", clear
	isid pid date 
	
	
	drop if check_completion == 0 & mode == 2 // HW: Confirmed 0 dropped
		// this should not drop anything since we already drop at the end of 02_baseline_cleaning.do
		// Important: the line below is wrong because we are dropping participants we saw at the stand and did not take survey, wrongly marking them as not attending
		// This had implications for eligibility. We fixed this on 22-04-2022
	   * keep if check_completion!=0  //keeping only started/completed surveys
	   
****************************	   
**# 2.  Generate variables
****************************	   

	* Survey attempted at stand 
	gen stand_survey = mode==1 //mode of survey is in person or phone
		* note that surveys could be incomplete.. 
	label var stand_survey "Survey taken at the stand (may be incomplete)"

		
	* Fix launchset variable (HW cleaned 2024-10-15)
	assert launchset != .
	bys pid: ereplace launchset = max(launchset)
	
	* Based on discussion with Luisa, treat this dataset as the most accurate
	* HW Oct 15 2024: added stand as well
	preserve 
		use "$raw/launch_prefill_pidwise_2022.dta", clear
		isid pid 
		keep pid launchset batch stand
		rename launchset launchset_new
		tempfile pid_ops
		save `pid_ops'
	restore 

	* FIXME: 17318 17319 in master not merged. All others merged. 
	* HW: 17318 17319 are rid's. They're in screening and are eligible. However somehow not in master_pid_list.dta
	merge m:1 pid using `pid_ops' , keep(1 3 4 5) keepusing(launchset_new) 	update replace nogen 	// 336 obs changed launchset, same as the note
	merge m:1 pid using `pid_ops' , keep(1 3 4 5) keepusing(batch) 		update replace nogen 		// 216 obs , same as the note
	merge m:1 pid using `pid_ops' , keep(1 3 4 5) keepusing(stand) 		update replace nogen 		// 6 obs
	sort pid date

	* HW I drop them for now
	drop if pid == 17318
	drop if pid == 17319

	
	* Interview Start Time (HW added Oct 15 2024. This can be used as a proxy for spot time because interview usually start at around the same time  as arrival)
	* HW: Note that some start times are obvious off, sometimes by several hours
	split bs_sttime , parse(":")
	replace bs_sttime3 = regexcapture(0) if regexmatch(bs_sttime3, "\d+")
	destring bs_sttime1 bs_sttime2 bs_sttime3 , replace

	gen start_time_hours = bs_sttime1 + bs_sttime2/60 + bs_sttime3/3600
	label var start_time_hours "Time at which survey started"
	bys pid: egen bs_avg_start_time = mean(start_time_hours)
	label var bs_avg_start_time "BL average start time"		

	drop bs_sttime1 bs_sttime2 bs_sttime3

	
	
		
		
	/*
	* Impute spot time using start time (HW added Oct 15 2024)
	* HW: I use the regression equation spot_time = a + b1*start_time + b2*start_time^2 + e
	gen start_time_hours_fixed = start_time_hours
	replace start_time_hours_fixed = . if ///
			!mi(spot_time_hours) & abs(spot_time_hours - start_time_hours) >= `=1/3' ///
			// If spot time and start time are off by more than 20 minutee, drop 
	
	reg spot_time_hours c.start_time_hours_fixed##c.start_time_hours_fixed
	predict spot_time_hours_predict
	gen spot_time_hours_impute = spot_time_hours
	replace spot_time_hours_impute = spot_time_hours_predict if mi(spot_time_hours_impute)
	label var spot_time_hours_impute "Time at which participant first spotted (Imputed using interview start time)"
	bys pid: egen bs_avg_spot_time_impute = mean(spot_time_hours_impute)
	label var bs_avg_spot_time_impute "BL average spot time (Imputed using interview start time)"		
	
	drop start_time_hours_fixed spot_time_hours_predict
	*/
	

****************************		
**#  3.  Balance the panel
****************************		

	* Generate a tag for days that we do observe 
	gen bs_obs = 1
	label var bs_obs "BL day where we talk to participant - in person or phone"
	count if bs_obs == 1 // 6,037
		

	* HW: Try make panel of maximun possible date ranges
	* Based on designated baseline start and end date
	* If some pid has surveys before or after start/end date, extend the panel to accomandate
	* The first/last interview of that specific pid
	tempfile bs_notfilled
	save `bs_notfilled' , replace
	
	
	collapse (mean)launchset (min) mindate=date (max) maxdate=date , by(pid)
	isid pid
	gen bs_start_date = .
	gen bs_end_date = .
	
	setDates
	forv i = 1/$numSetsTotal { 
	    replace bs_start_date = ${baselineStartSet`i'} 	if launchset == `i'
	    replace bs_end_date   = ${baselineEndSet`i'} 	if launchset == `i'
	}
	
	gen panel_start_date 	= td(1jan2022)
	replace panel_start_date = panel_start_date - 1
	gen panel_end_date 	= td(31dec2022)
	replace panel_end_date = panel_end_date + 1
	
	gen panel_duration = panel_end_date - panel_start_date + 1
	expand panel_duration
	
	bys pid (panel_start_date) : gen date_order = _n
	gen date = panel_start_date + date_order - 1
	gen bs_designated_survey_period = 1 if date >= bs_start_date & date <= bs_end_date
	keep pid date panel_start_date panel_end_date bs_start_date bs_end_date bs_designated_survey_period
	format %td date panel_start_date panel_end_date bs_start_date bs_end_date
	
	merge 1:1 pid date using `bs_notfilled' , keep(1 2 3) 
	// HW Oct 22:
	// 287 surveys took place outside of designated survey period
	// Among them 150 took place within 7 days after the end of bs
	// and 80 took place within 7 days before the start of bs
	
	// HW Oct 22:
	// Even if we only keep designated survey period and keep(1 3), the total number is 11,569, up a bit from 11,595
	// Using the old code. Indicating that there are some pids
	// whoes first legal survy didn't start on the designated start date
	// Or the last legal survey happended before the end date (legal means happened within the designated period)

	
	* Replace key invariant variables to be non-missing 
	bys pid: ereplace launchset 	= max(launchset)
	bys pid: ereplace batch 		= max(batch)
	bys pid: ereplace stand 		= max(stand)

	* Day of week variable 
	gen dow = dow(date)
	label define dow_lab 0 "Sunday" 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday" , replace
	label value dow dow_lab
	label var dow "Day of week"

	
	* Account for days where surveyors are not in the field (Sundays, holidays). Generate holidays date
	* LC - need to define the holidays global
	* ado file that generates $holiday_list global be found in Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/98. Utilities/01. Programs
	gen holiday = 0
	foreach day in $holiday_list {
	    replace holiday = 1 if date == `day'
	}
	label var holiday  "Holiday"


	
	* HW Feb 2025: Try fix spot time, then merge attendance without being surveyed, then try to fix spot time again
	* Updating the Oct 2024 code following new spot time fixing method
	
	* HW FEB 2025 final note: Two 4 devices have been fixed in cleaning, I find 
	format spot_time %tCHH:MM
	gen spot_time_hours = hh(spot_time) + mm(spot_time)/60 + ss(spot_time)/3600
	label var spot_time_hours "Time at which surveyors first spotted participants"
	count if (spot_time_hours < 5.5 | spot_time_hours > 10.5) & !mi(spot_time_hours)
	assert `r(N)' == 0

	* Count if there are entries with incorrectly recorded spot time and then got corrected in the text. Should be 0 in BL.
	count if mi(spot_time) & !mi(spot_time_text)
	assert `r(N)' == 0
	
	merge 1:1 pid date using "$raw/05_attendance_check.dta", ///
			keepusing(arrival_time_hours seen) nogen keep(1 3)
	replace arrival_time_hours = . if !mi(spot_time_hours)
	
	count if (spot_time_hours < 5.5 | spot_time_hours > 10.5) & !mi(spot_time_hours)
	assert `r(N)' == 0
	replace spot_time_hours = arrival_time_hours if mi(spot_time_hours) & !mi(arrival_time_hours)
	drop arrival_time_hours
	

	* Attendance (in-person dates in cto are days of attendance to the stand)
	gen attend = 0
	label var attend "Attendance at stand (not self-reported)"
	replace attend = 1 if mode == 1 | seen == 1
	replace attend = 0 if mi(attend) & dow!=0 & holiday == 0
	replace attend = . if dow==0 | holiday == 1
	drop seen
	
	
	* Spot Time
	bys pid: egen bs_avg_spot_time = mean(spot_time_hours)
	label var bs_avg_spot_time "BL average spot time"	


*************************************************
**# 4.  Fill up data for relevant days in panel
************************************************* 

****
**## Reconcile Versions
****

	forval i = 1/7 {
		replace bs_work_`i' = bs_main_act_work_`i' if !mi(bs_main_act_work_`i')
		replace bs_earn_`i' = bs_earn_`i' + bs_notpaid_amt_due_`i' if !mi(bs_notpaid_amt_due_`i')
		replace bs_earn_`i' = 0 if bs_work_`i' == 0
		
	}




****
**## Gen blank key variables
****

 	* Numeric variables
	local 	numericVars attend_sr work earn work_type role why_attend whenfound  howfound  ///
			time_found howfound_notattend native try_work why_notattend spend_day time_left_stand ///
			how_found_native why_nottry firsttime_emp notpaid_amt_due  paid_filt main_act_hh_chores ///
			main_act_home_rest main_act_self_employed main_act_work main_act_sick main_act_planned_event ///
			main_act_emergency main_act_travel main_act_family_time main_act_friends_time main_act_998
	foreach var in `numericVars' {
		gen `var' = .
		
		* Value labels
		qui cap elabel list (bs_`var'_1)
		if "`r(name)'" != "" lab val `var' `r(name)'
	}	
	label var attend_sr "Attendance at stand (self-reported)"	
	label var work  "Worked"
	label var earn "Earnings"
	label var work_type "Type of work"
	label var role  "Role"
	label var why_attend "Reason for attending stand"
	label var whenfound  "When was work found?"
	label var howfound   "How was work found?"
	label var time_found "What time was work found?"
	label var howfound_notattend  "How was work found, when not at stand?"
	label var native "Are they in their native?"
	label var try_work "Tried to work"
	label var why_notattend "If tried to find work, why they did not attend stand"
	label var spend_day "How do they spend the rest of the day"
	label var time_left_stand "Time they left the stand"
	label var how_found_native "How did they find work if they are in a different place"
	label var why_nottry "Why did they not try"

	label var main_act_hh_chores        "Main act - stayed home to do household chores"
	label var main_act_home_rest        "Main act - stayed home to rest"
	label var main_act_self_employed    "Main act - work as self-employed / not for pay"
	label var main_act_work             "Main act - work for pay"
	label var main_act_sick             "Main act - sick/injured"
	label var main_act_planned_event    "Main act - attended a planned event"
	label var main_act_emergency        "Main act - emergency"
	label var main_act_travel           "Main act - traveled"
	label var main_act_family_time      "Main act - spent time with children/family"
	label var main_act_friends_time     "Main act - spent time with friends"
	label var main_act_998              "Main act - Other (specify)"

	
	
	* String variables
	* FIXME all these variables are just missing. We never pre-fill them 
	* FIXME HW: they are not all missing. It is expected most of them are missing because they need to choose "other" to enable the "other"'s
	rename rb1_b1_others_* bs_main_act_others_*
	rename d_main_activity_* bs_main_activity_*

	local 	stringVars work_type_others why_attend_others  ///
			howfound_notattend_others why_notattend_others ///
			spend_day_others main_activity main_act_others ///
			howfound_others paid_filt_others whenfound_others how_found_native_others 
			
	foreach var in `stringVars' {
		
		* HW: Variables with all missing are coded by Stata as . instead of as ""
		* The lines below fixes this
		tostring bs_`var'_* , replace
		foreach i of varlist bs_`var'_* {
			replace `i' = "" if `i' == "."
		}
		
		gen `var' = ""
	}	
	label var work_type_others "Type of work- Others"
	label var why_attend_others "Reason for attending the stand- Others"
	label var howfound_notattend_others  "How they found work wothout attendning the stand - Others"
	label var why_notattend_others "If tried, why they did not attend stand - Others"
	label var spend_day_others  "How do they spend the rest of the day - Others" 
	label var main_activity 				"Main activity"
	label var main_act_others  				"Main activity, other"
	label var howfound_others   "How did they find work - Others"
	label var whenfound_others "When did they find work - Others"
	label var how_found_native_others  	"How did they find work if they are in a different place - Others"

	
****
**## Fill Recall
****	

	* Define number of recall days
	* ado file defineRecallDays can be found in 
	* Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/98. Utilities/01. Programs
	qui defineRecallDays, varname(bs_attend_sr)
	
	* Fill up key variables with relevant values	
	forv z = 1/`r(max_days_recall)' {
		foreach var in `numericVars' {
			bys pid (date): replace `var'= bs_`var'_`z'[_n+`z'] if !mi(bs_`var'_`z'[_n+`z'])  & pid == pid[_n+`z'] & bs_`var'_`z'[_n+`z'] != 999 & mi(`var')
		}
		foreach var in `stringVars' {
			bys pid (date): replace `var'= bs_`var'_`z'[_n+`z'] if !mi(bs_`var'_`z'[_n+`z'])  & pid == pid[_n+`z'] & mi(`var')
		}
	}
	
	drop bs_*_1 bs_*_2 bs_*_3 bs_*_4 bs_*_5 bs_*_6 bs_*_7
	
	save "$temp/04_baseline_recall_filled_temp.dta", replace
	

****	
**## Main Activity
****	
	
	/*
	
	* Replace work variable with main activity if main activity == 4 (work)
	* starting from 9-06-2022 when we changed our work elicitation method
	replace work = main_act_work if mi(work) & !mi(main_act_work)
		
	replace main_act_hh_chores      = 1 if spend_day == 2
	replace main_act_home_rest      = 1 if spend_day == 5
	replace main_act_self_employed  = 1 if spend_day == 8
	replace main_act_planned_event  = 1 if spend_day == 4
	replace main_act_emergency      = 1 if spend_day == 6
	replace main_act_travel         = 1 if spend_day == 7
	replace main_act_family_time    = 1 if spend_day == 1
	replace main_act_friends_time   = 1 if spend_day == 3
	replace main_act_998            = 1 if spend_day == 998

	replace main_act_hh_chores      = 0 if spend_day != 2    & !mi(spend_day)
	replace main_act_home_rest      = 0 if spend_day != 5    & !mi(spend_day)
	replace main_act_self_employed  = 0 if spend_day != 8    & !mi(spend_day)
	replace main_act_planned_event  = 0 if spend_day != 4    & !mi(spend_day)
	replace main_act_emergency      = 0 if spend_day != 6    & !mi(spend_day)
	replace main_act_travel         = 0 if spend_day != 7    & !mi(spend_day)
	replace main_act_family_time    = 0 if spend_day != 1    & !mi(spend_day)
	replace main_act_friends_time   = 0 if spend_day != 3    & !mi(spend_day)
	replace main_act_998            = 0 if spend_day != 998  & !mi(spend_day)
	replace main_act_others = spend_day_others if spend_day == 998
	
	* Replace earn variable with amount due if not paid on that day
	* starting only from April XX?
	 replace earn = notpaid_amt_due if earn == 0  // HW: only 5 repalcements
	 

	* Job found at stand indicator 
	gen job_found_at_stand = 1 if whenfound == 2 // found at stand !mi only if attend & work == 1
	replace job_found_at_stand = 1 if whenfound == 1 & inlist(howfound , 6, 7, 8)
	replace job_found_at_stand = 1 if whenfound == 3 & inlist(howfound , 6, 7, 8)
	replace job_found_at_stand = 0 if whenfound == 1 & !inlist(howfound , 6, 7, 8, .)
	replace job_found_at_stand = 0 if whenfound == 3 & !inlist(howfound , 6, 7, 8, .)
	replace job_found_at_stand = 0 if work == 1 & attend == 0 & howfound_notattend !=5 // & !mi(howfound_notattend)
	replace job_found_at_stand = 1 if work == 1 & attend == 0 & howfound_notattend ==5
	label var job_found_at_stand "Job found at stand (using whenfound variable)"

	*/
	
	

	
**********************
**# 5.  Value labels
**********************

	label define why_notattend_lab 1 "Thought no job at stand" 2 "Thought I would get a job through phone calls" 3 "Did not feel like going/travel" 4 "Wanted an easier job"  5 "Did not prefer a construction job" 6 "Issues at stand"

	lab val why_notattend why_notattend_lab

	
************************************
**# 6.	Limit Date (HW added Oct )
************************************

	sort pid date 
	save "$temp/04_baseline_makepanel_no_limit_date.dta", replace

	keep if bs_designated_survey_period == 1
	drop  bs_designated_survey_period


	
******************* 
**# 7.  Save data
*******************	  

	sort pid date 
	save "$temp/04_baseline_makepanel.dta", replace


	
	

