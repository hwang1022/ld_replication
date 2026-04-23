************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Baseline - Make Aggregate variables
* 	Author:				Luisa 
* 	Last modified:		2024-Oct-10 (HW)
************************************************************


******************
**# 1. Open Data
******************

   use "$temp/04_baseline_makepanel.dta", clear
   isid pid date
   sort pid date

  
   
************************************
**# 2. Generate baseline variables
************************************

	cap drop _merge
	
	* Calendar week
	gen calendar_week = week(date)
	replace calendar_week = calendar_week - 1 if dow(date) == 6	// In stata Saturday is considered the start of week
	replace calendar_week = calendar_week - 1 if dow(date) == 0 // In stata Sunday is considered the secodn day of week, following Saturday
	gen week_in = 1 // all of baseline is coded as week_in = 1


	gen arrival_time_hours = spot_time_hours
	// Set up arrival times in 15-minute intervals
	gen arrival_time_hours_15 = .
	forvalues i =  6/10 {
	  replace arrival_time_hours_15 = `i' if arrival_time_hours < `i'.25 & arrival_time_hours_15 == .
	  replace arrival_time_hours_15 = `i'.25 if arrival_time_hours < `i'.5 & arrival_time_hours_15 == .
	  replace arrival_time_hours_15 = `i'.5 if arrival_time_hours < `i'.75 & arrival_time_hours_15 == .
	  replace arrival_time_hours_15 = `i'.75 if arrival_time_hours < `i'+1 & arrival_time_hours_15 == .
	}
	
	// Set up arrival time in 30-minute intervals
	gen arrival_time_hours_30 = . 
	forvalues i =  6/10 {
	  replace arrival_time_hours_30 = `i' if arrival_time_hours < `i'.5 & arrival_time_hours_30 == .
	  replace arrival_time_hours_30 = `i'.5 if arrival_time_hours < `i'+1  & arrival_time_hours_30 == .
	}
	
	// Set up arrival time in hourly intervals
	gen arrival_time_hours_60 = round(arrival_time_hours)

	// Label all the arrival time interval variables
	la var arrival_time_hours_15 "Arrival Time (15min)"
	la var arrival_time_hours_30 "Arrival Time (30min)"
	la var arrival_time_hours_60 "Arrival Time (1hr)"
	la var arrival_time_hours "Arrival Time"
	cap drop _merge
	
	gen arrival_time_hours_imputed = arrival_time_hours
	replace arrival_time_hours_imputed = start_time_hours if mi(arrival_time_hours_imputed)
	replace arrival_time_hours_imputed = . if arrival_time_hours_imputed < 5.5
	replace arrival_time_hours_imputed = .  if arrival_time_hours_imputed > 10.5
	
	
	* Arrive before cut-off-time (conditional on attended)
	gen arrive_before_8 = arrival_time_hours <= 8 if ///
		!mi(arrival_time_hours) & !inlist(stand, ${cutoff_0815}, ${cutoff_0745})
	replace arrive_before_8 = arrival_time_hours <= 8.25 if ///
		!mi(arrival_time_hours) & inlist(stand, ${cutoff_0815})
	replace arrive_before_8 = arrival_time_hours <= 7.75 if ///
		!mi(arrival_time_hours) & inlist(stand, ${cutoff_0745})
	la var arrive_before_8 "Arrive by cut-off-time (conditional on attend)"
	
	* Attend and arrive before cut-off time (0 if not attended, or arrived after)
	gen attend_and_before8 = arrive_before_8 if attend == 1
	replace attend_and_before8 = 0 if attend == 0
	la var attend_and_before8 "Arrive by cut-off-time (unconditional on attend)"
	
	
	
	* Arrive before cut-off-time (conditional on attended)
	gen arrive_before_8_imputed = arrival_time_hours_imputed <= 8 if ///
		!mi(arrival_time_hours_imputed) & !inlist(stand, ${cutoff_0815}, ${cutoff_0745})
	replace arrive_before_8_imputed = arrival_time_hours_imputed <= 8.25 if ///
		!mi(arrival_time_hours_imputed) & inlist(stand, ${cutoff_0815})
	replace arrive_before_8_imputed = arrival_time_hours_imputed <= 7.75 if ///
		!mi(arrival_time_hours_imputed) & inlist(stand, ${cutoff_0745})
	la var arrive_before_8_imputed "Arrive by cut-off-time (conditional on attend)"
	
	* Attend and arrive before cut-off time (0 if not attended, or arrived after)
	gen attend_and_before8_imputed = arrive_before_8_imputed if attend == 1
	replace attend_and_before8_imputed = 0 if attend == 0
	la var attend_and_before8_imputed "Arrive by cut-off-time (unconditional on attend)"
		


	* BL total (observed) stand attendance 
	assert attend==. if dow==0 | holiday==1
	
	bys pid (date) : gen daycount = _n
	// For non-zero, non-holiday observations, capture the total days attended in baseline
	bys pid (daycount): egen bs_sum_attend = total(attend) if dow!=0 & holiday==0
	bys pid (daycount): ereplace bs_sum_attend = max(bs_sum_attend)
	
	// Total value of attendance shouldn't be 13
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

	/*
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
	*/
	
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


	
	
	
	
	
********************************
**# Save Cov (Use as controls)
********************************

	egen temp = mean(attend), by(pid)
	egen bl_attend = max(temp), by(pid)
	drop temp
	gen bl_hiattend = (bl_attend>=0.45) if bl_attend!=. //median 0.4545455
	gen bl_hiattend2 = (bl_attend>0.5) if bl_attend!=.

	* earnings 
	egen temp = mean(earn) , by(pid)
	egen bl_earn = max(temp), by(pid)
	gen miss_bl_earn = (bl_earn==.)
	replace bl_earn = 0 if miss_bl_earn==1
	drop temp
	
	* Modal Work
	egen temp1 = mode(earn) if earn>0, by(pid)
	egen bl_modalwage = max(temp1), by(pid)
	replace bl_modalwage = 0 if bl_modalwage==.
	drop temp1



	preserve 
		keep pid bs_sum_attend-bl_modalwage
		duplicates drop pid , force
		
		save "$temp/05_baseline_cov.dta" , replace
	restore
	
	
	
	
*********************	
**# Save Panel Data
*********************

	preserve 

	sort pid date  

	// keep pid date dow holiday calendar_week week_in stand launchset mode arrival_time_hours attend attend_sr work earn work_type multiday_job multiday_job_inc multiday_first multiday_last multiday_num howfound_multiday whenfound_multiday
	
	
	// keep pid date dow holiday calendar_week week_in stand launchset mode arrival_time_hours attend attend_sr work earn work_type 
	
	gen phase = 0
	save "$temp/05_baseline_makevar.dta", replace
	
	restore


	
	
