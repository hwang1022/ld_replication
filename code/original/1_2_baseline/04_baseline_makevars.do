/***------------------------------------------------
Project:			Labor Discipline
Purpose:			Baseline - Make Aggregate variables
Author:				Luisa 
Last modified:		2024-06-24 (PB)
--------------------------------------------------------***/

/*----------------------------------------------------------
	1. Open Data
------------------------------------------------------------*/
 
   cd "/Users/${user}/Dropbox/Labor Discipline" 

   use "./07. Data/3. Main Study 3.0/02. Cleaning Data/03. Baseline/02. Output/04_baseline_makepanel.dta", clear
   isid pid date

/*----------------------------------------------------------
	2. Generate baseline variables
------------------------------------------------------------*/
	
	* Unique PID
	bys pid (date): gen uniqpid = 1 if _n == 1
	
	* Calendar week
	gen calendar_week = week(date)
		replace calendar_week = calendar_week - 1 if dow(date) == 6
		replace calendar_week = calendar_week - 1 if dow(date) == 0
	gen week_in = 1 // all of baseline is coded as week_in = 1

	* Arrival time
	merge 1:1 pid date using "./07. Data/3. Main Study 3.0/02. Cleaning Data/09. Monitoring/02. Output/06. Attendance Tracker/05_attendance_check.dta", keepusing(arrival_time arrival_time_hours)
  
	/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                        28,678
        from master                     6,967  (_merge==1)
        from using                     21,711  (_merge==2)

    Matched                             4,628  (_merge==3)
    -----------------------------------------

	*/
	* FIXME why is so much of the master data unmatched? attend = 0?
	* tab attend if _merge==1, m  
	*  tab attend if _merge==3, m // 2% of obs have attend ==0?
   
	keep if _merge != 2
	
	// Set up arrival times in 15-minute intervals
	gen arrival_time_hours_15 = .
	forvalues i =  6/10 {
	  replace arrival_time_hours_15 = `i' if arrival_time_hours < `i'.25 & arrival_time_hours_15 == .
	  replace arrival_time_hours_15 = `i'.25 if arrival_time_hours < `i'.5 & arrival_time_hours_15 == .
	  replace arrival_time_hours_15 = `i'.5 if arrival_time_hours < `i'.75 & arrival_time_hours_15 == .
	  replace arrival_time_hours_15 = `i'.75 if arrival_time_hours < `i'+1 & arrival_time_hours_15 == .
	}
	
	* Set up arrival time in 30-minute intervals
	gen arrival_time_hours_30 = . 
	forvalues i =  6/10 {
	  replace arrival_time_hours_30 = `i' if arrival_time_hours < `i'.5 & arrival_time_hours_30 == .
	  replace arrival_time_hours_30 = `i'.5 if arrival_time_hours < `i'+1  & arrival_time_hours_30 == .
	}
	
	* Set up arrival time in hourly intervals
	gen arrival_time_hours_60 = round(arrival_time_hours)

	* Label all the arrival time interval variables
	la var arrival_time_hours_15 "Arrival Time (15min)"
	la var arrival_time_hours_30 "Arrival Time (30min)"
	la var arrival_time_hours_60 "Arrival Time (1hr)"
	la var arrival_time_hours "Arrival Time"
	drop _merge

	* BL total (observed) stand attendance 
	assert attend==. if dow==0 | holiday==1
	
	* For non-zero, non-holiday observations, capture the total days attended in baseline
	bys pid (daycount): egen bs_sum_attend = total(attend) if dow!=0 & holiday==0
		bys pid (daycount): ereplace bs_sum_attend = max(bs_sum_attend)
	
	* Total value of attendance shouldn't be 13
	assert bs_sum_attend < 13
	label var bs_sum_attend "Total days attended in baseline" 

	/* Old code: 
	bys pid (daycount): egen bs_count_attend = count(attend!= .) if dow!=0 & holiday==0
	bys pid (daycount): ereplace bs_count_attend = max(bs_count_attend)
	bys pid (daycount): gen bs_sum_attend_adj = bs_sum_attend/bs_count_attend * 11
		  
	bys pid (daycount): egen bs_sum_attend_after_day4 = total(attend) if dow!=0 & holiday==0 & daycount > 4 
	bys pid (daycount): ereplace bs_sum_attend_after_day4 = max(bs_sum_attend_after_day4)	*/
	
	* BL total days worked 
	bys pid (daycount): egen bs_sum_work = total(work) if dow!=0 & holiday == 0
		bys pid (daycount): ereplace bs_sum_work = max(bs_sum_work)
		label var bs_sum_work "BL total days worked"
	
	* BL average wage 
	* earn is mostly . on days where work==0, 9 obs have positive values
	bys pid (daycount): egen bs_avg_wage = mean(earn) if dow!=0 & holiday==0
		bys pid (daycount): ereplace bs_avg_wage = max(bs_avg_wage)
		label var bs_avg_wage "BL average wage earned"

	* BL total wage
	bys pid (daycount): egen bs_sum_wage = total(earn) if dow!=0 & holiday == 0
		bys pid (daycount): ereplace bs_sum_wage = max(bs_sum_wage)
		label var bs_sum_wage "BL total wages earned"

	* BL job found at stand 
	bys pid: egen bs_sum_job_found_at_stand = total(job_found_at_stand) if dow!=0 & holiday == 0
		bys pid: ereplace bs_sum_job_found_at_stand = max(bs_sum_job_found_at_stand)
		label var bs_sum_job_found_at_stand "BL total days job found at stand (using whenfound variable)"
   
	* BL days drunk
	bys pid (daycount): egen bs_sum_alcohol = total(too_drunk) if dow!=0 & holiday == 0
		bys pid (daycount): ereplace bs_sum_alcohol = max(bs_sum_alcohol)
		label var bs_sum_alcohol "BL total days too drunk to answer"

	* BL days not interested in survey
	bys pid: egen bs_sum_notinterest = count(bs_interest) if bs_interest==0 & attend ==1 & mode==1 
		bys pid: replace bs_sum_notinterest = 0 if bs_sum_notinterest==.
	bys pid: egen max_noninterest = max(bs_sum_notinterest)
		drop bs_sum_notinterest
		rename max_noninterest bs_sum_noninterest
		label var bs_sum_noninterest  "BL total days not interested to answer"

	* BL total days worked AND did not attend stand
	gen work_not_attend = work == 1 & attend == 0 if !mi(work) & !mi(attend)
	bys pid: egen bs_sum_work_not_attend = total(work_not_attend) if dow != 0 & holiday == 0
		label var bs_sum_work_not_attend "BL total days worked AND did not attend stand"
	drop work_not_attend

	* BL total days worker did not try to find work
	bys pid: egen bs_sum_nottry = total(try_work == 0) if !mi(try_work) & dow != 0 & holiday == 0
		label var bs_sum_nottry "BL total days did not try to find work"

	* BL total work days missing
	bys pid: egen bs_sum_work_missing = total(work==.) if dow!=0 & holiday == 0
	bys pid: ereplace bs_sum_work_missing = max(bs_sum_work_missing)
		label var bs_sum_work_missing "BL total days with missing work data"   

	* BL total work days non-missing
	bys pid: egen bs_sum_work_notmissing = total(work==.) if dow!=0 & holiday == 0
	bys pid: ereplace bs_sum_work_notmissing = max(bs_sum_work_notmissing) if dow!=0 & holiday == 0
		replace bs_sum_work_notmissing = 11 - bs_sum_work_notmissing
		label var bs_sum_work_notmissing "BL total days with non-missing work data"   

	gen bs_share_work_notmissing = bs_sum_work / bs_sum_work_notmissing
		label var bs_share_work_notmissing "BL share of days worked"

	* BL number of days per work type 
	preserve
		gen num_days_per_worktype = 1
		keep if work == 1
		collapse (count) num_days_per_worktype, by(pid work_type)
		bys pid: gen diff_worktype_num = _N
		bys pid: keep if _n == 1
		keep pid diff_worktype_num
		label var diff_worktype_num "BL number of different professions"
		tempfile worktype
		save `worktype'
	restore
	
	display "`worktype'"

	capture drop _merge
	merge m:1 pid using `worktype'
	
	/*   Result                           # of obs.
    -----------------------------------------
    not matched                           877
        from master                       877  (_merge==1)	
        from using                          0  (_merge==2)

    matched                            10,718  (_merge==3)
    -----------------------------------------	
	Note: There are observations in the master file that don't have values for number of days per worktype 
	*/
		drop _merge

		
/*----------------------------------------------------------
	3. Merge with eligibility data
------------------------------------------------------------*/

   preserve 
	   use "./07. Data/3. Main Study 3.0/04. Operation/03. Baseline/02. Output/01. Eligibility/baseline_eligible_master.dta", clear 
	   keep pid bs_sum_attend bs_sum_wage bs_sum_work stand 
	   rename bs_* bs_*_eligibility  
	   rename stand elig_stand 
	   label var bs_sum_attend_eligibility "BL attendance (used to determine eligibility)"
	   label var bs_sum_wage_eligibility "BL wage (used to determine eligibility)"
	   label var bs_sum_work_eligibility "BL work (used to determine eligibility)"
	   tempfile elig_bs_criteria
	   save `elig_bs_criteria' 
   restore 

   merge m:1 pid using `elig_bs_criteria'
   
    /* Result                           # of obs.
    -----------------------------------------
    not matched                         7,571
        from master                     7,334  (_merge==1)
        from using                        237  (_merge==2)

    matched                             4,261  (_merge==3)
    ----------------------------------------- 
	Note: 
	1) merge == 1 corresponds to ineligible baselines
	2) merge == 2 corresponds to stands that were in the eligibility data
	but were dropped in the baseline.
	*/
	
	* Drop dropped stands
	   tab elig_stand if _merge==2 			// corresponds to dropped stands 
	   drop if _merge ==2 					// in eligibility data but not in baseline data... why? dropped stands
   
   * Note that bs_sum_attend_eligibility is missing for a big chunk (_merge==1): these are ineligible baselines
   drop elig_stand 
   bys pid: ereplace bs_sum_attend_eligibility 	= max(bs_sum_attend_eligibility)
   bys pid: ereplace bs_sum_wage_eligibility 	= max(bs_sum_wage_eligibility)


/*----------------------------------------------------------
	5. Save data
------------------------------------------------------------*/

	sort pid date interviewer 
	order pid date daycount dow holiday stand launchset batch bs_start_date bs_end_date interviewer mode stand_survey attend bs_sum_attend work work_type work_type_others role bs_sum_work earn bs_avg_wage earn bs_sum_wage why_attend why_attend_others whenfound howfound time_found howfound_notattend howfound_notattend_others native try_work why_notattend why_notattend_others spend_day spend_day_others time_left_stand how_found_native why_nottry

	saveold "./07. Data/3. Main Study 3.0/02. Cleaning Data/03. Baseline/02. Output/05_baseline_makevar.dta", replace