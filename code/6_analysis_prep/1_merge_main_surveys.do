**************************************************
**************************************************
*	Project: LD Main Study
*	Purpose: Construct daily outcomes 
*	Author: HW, based on Daryl
*	Last modified: Dec 1, 2024 HW
**************************************************
**************************************************

/*
- 2024-10-31: HW made significant change to the code
- 2024-10-15: HW reorganized code, keeping as much original code as pissible
- 2024-10-10: HW fixed data loss when appending phase 2 due to the use of "append [...] , force"
- 2024-06-25: PB addressed a FIXME on merging in BL attendance check data. Code moved to baseline makevar.
- 2024-05-25: PB addressed a FIXME on replacing values for arriving/attending before 8am cutoff.
- 2024-04-10: LC imputed as no event/invitation happening only for the days covered by the shock module
- 2024-04-06: LC merged all participants who took the sm survey (including those who not report any shock/invite 
*/



******************************
**# 0. Determine Eligibility
******************************


****
**## List of Participants
****

	use "$temp/00_mainstudy_master.dta"  , clear
	
	
	
********************************
**# 1.  Combine BL, P1 & 2, P3
********************************


****
**## Baseline
****

	// use pid date mode attend attend_sr work earn work_type multiday_job arrival_time_hours phase ///
	// 	using"$final/05_baseline_makevar.dta" , clear
		
	use pid date mode attend attend_sr work earn work_type arrival_time_hours phase ///
		using"$temp/05_baseline_makevar.dta" , clear
	
	* Restrict Sample
	merge m:1 pid using "$temp/00_mainstudy_master.dta" , keep(3) keepusing(pid stand launchset batch strata treatment late_announcement_flag) nogen
	
	
	* Section Headings
	gen __0_COVER________ = .
	gen __1_DATE_VARIABLES________ = .
	gen __2_DAILY_ATTENDACE________ = .
	order 	__0_COVER________ pid stand launchset batch strata treatment late_announcement_flag ///
			__1_DATE_VARIABLES________ date phase  ///
			__2_DAILY_ATTENDACE________ 
	
	tempfile bl
	save `bl' , replace	


	
****
**## Phase 1 and 2
****

					
	use "$temp/05_phase1_phase2_makevar_daily.dta", clear
	sort pid date
	
	* Restrict Sample
	merge m:1 pid using "$temp/00_mainstudy_master.dta" , keep(3) keepusing(pid stand launchset batch strata treatment late_announcement_flag) nogen replace update
	
	* Section Headings
	gen __0_COVER________ = .
	gen __1_DATE_VARIABLES________ = .
	gen __2_DAILY_ATTENDACE________ = .
	order 	__0_COVER________ pid stand launchset batch strata treatment late_announcement_flag ///
			__1_DATE_VARIABLES________ date phase  ///
			__2_DAILY_ATTENDACE________ 
	
	tempfile p12
	save `p12' , replace
	
	
****
**## Phase 3
****
	
	use "$temp/02_phase3_cleaned.dta", clear
	
	* Restrict Sample
	merge m:1 pid using "$temp/00_mainstudy_master.dta" , keep(3) keepusing(pid stand launchset batch strata treatment late_announcement_flag) nogen replace update
	
	
	* Section Headings
	gen __0_COVER________ = .
	gen __1_DATE_VARIABLES________ = .
	gen __2_DAILY_ATTENDACE________ = .
	order 	__0_COVER________ pid stand launchset batch strata treatment late_announcement_flag ///
			__1_DATE_VARIABLES________ date phase  ///
			__2_DAILY_ATTENDACE________ 
	
	tempfile p3
	save `p3' , replace
	
	
****	
**## Combine Phases
****

	use `bl' , clear
	append using `p12'
	append using `p3'
	
	* There are some days on which both phase 2 and phase 3 took place
	* In this case I only keep phase 2 because the dates are in phase 2 period
	* Only 121, 137, 202, 303, 529, 542 are affected
	sort pid date phase
	duplicates drop pid date, force 

	


************	
**# Checks
************

	
****	
**## Clean and fix variables
****	

	
	* Mode
	replace mode = 1 if attend == 1 & phase == 3
	replace mode = 3 if mi(mode) & !mi(work)
	lab def mode 3 "3. Recall (In person or Phone)" , modify
	lab val mode mode

	* Holiday
	do "$code/1.macro.do"
	setDates
	gen holiday = 0
	local holiday_inlist ""
	foreach j in $holiday_list {
		local holiday_inlist "`holiday_inlist', `j'"
	}
	replace holiday = 1 if inlist(date`holiday_inlist')
	
	* Gen Day
	cap drop daycount
	cap drop dow
	bysort  pid phase (date) : gen daycount = _n
	gen dow = dow(date)
	
	* HW Feb 2025: this is not true. Only attendance were removed
	/*
	foreach i of varlist mode-main_act_other {
		cap replace `i' = .  if dow == 0
		cap replace `i' = "" if dow == 0
		cap replace `i' = .  if holiday == 1
		cap replace `i' = "" if holiday == 1
	}
	*/
	
	foreach i of varlist attend {
		cap replace `i' = .  if dow == 0
		cap replace `i' = "" if dow == 0
		cap replace `i' = .  if holiday == 1
		cap replace `i' = "" if holiday == 1
	}
	
	

	* Week in study
	cap drop week_in
    gen week_in = floor(daycount/7)	+ 1
	replace week_in = week_in - 1 if dow == 0
	la var week_in "Weeks into each phase"
	replace week_in = 0 if phase == 0
	
	drop if phase == 1 & !mi(week_in) & week_in > 7
	
	* Calendar week
	cap drop calendar_week
	gen calendar_week = week(date)
	replace calendar_week = calendar_week - 1 if dow(date) == 6 & date < 23010
	replace calendar_week = calendar_week - 1 if dow(date) == 0
	replace calendar_week = calendar_week + 52 if date >= 23011
	label var calendar_week "Calendar week"
	


	* Arrive before cut-off-time (conditional on attended)
	cap drop arrive_before_8
	gen arrive_before_8 = arrival_time_hours <= 8 if ///
		!mi(arrival_time_hours) & !inlist(stand, ${cutoff_0815}, ${cutoff_0745})
	replace arrive_before_8 = arrival_time_hours <= 8.25 if ///
		!mi(arrival_time_hours) & inlist(stand, ${cutoff_0815})
	replace arrive_before_8 = arrival_time_hours <= 7.75 if ///
		!mi(arrival_time_hours) & inlist(stand, ${cutoff_0745})
	la var arrive_before_8 "Arrive by cut-off-time (conditional on attend)"
	
	* Attend and arrive before cut-off time (0 if not attended, or arrived after)
	cap drop attend_and_before8
	gen attend_and_before8 = arrive_before_8 if attend == 1
	replace attend_and_before8 = 0 if attend == 0
	la var attend_and_before8 "Arrive by cut-off-time (unconditional on attend)"


	* Harmonize week_in across phase 1 and 2  
	gen week_in_p1_p2 = week_in if phase == 1 | phase == 2
	replace week_in_p1_p2 = week_in + 7 if phase == 2
	replace week_in_p1_p2 = 7 if week_in > 7 & phase == 1
	
	lab def weekp1p2 	1 "P1 Wk1" 2 "P1 Wk2" 3 "P1 Wk3"  4 "P1 Wk4"  5 "P1 Wk5"  6 "P1 Wk6"  7 "P1 Wk7&7+" ///
						8 "P2 Wk1" 9 "P2 Wk2" 10 "P2 Wk3" 11 "P2 Wk4" 12 "P2 Wk5" 13 "P2 Wk6" 14 "P2 Wk7" 15 "P2 Wk8" , replace 
						
	lab val week_in_p1_p2 weekp1p2
	lab var week_in_p1_p2 "Weeks into experiment, Phase 1 + 2"

	
	
**************************
**# Reorganize variables
**************************

	order holiday daycount dow week_in calendar_week week_in_p1_p2 , after(phase)
	 

	
	
***************
**# Save Data
***************	

	save "$temp/03_bs_phase123_makevar.dta", replace
	
	

******************	
**# Weekly Value
******************



	* Identify people who missed a whole week due to late announcement. Drop the first week for them.
	preserve
		keep if late_announce_no_data_flag == 1
		drop if dow == 0
		collapse (count)phase  , by(pid week_in)
		keep if phase == 6
		keep pid week_in
		gen phase = 1
		tempfile late_announce_no_data
		save `late_announce_no_data' , replace
	restore
	
	

	* Treat a standard week as 6 days 
	local dow 6

	/* [> Attend <] */ 
	preserve
		gen attend_week = attend  
		collapse (sum)attend (count) attend_week , by(pid phase week_in)
		replace attend = . if attend_week == 0
		gen attend_adj = attend/attend_week*`dow'
		tempfile attend
		save `attend'
	restore 

	/* [> Attend before cutoff <] */ 
	preserve
		drop if attend_and_before8 == . 
		gen attend_and_before8_week = attend_and_before8  
		collapse (sum) attend_and_before8 (count) attend_and_before8_week , by(pid phase week_in)
		gen attend_and_before8_adj = attend_and_before8/attend_and_before8_week*`dow'
		tempfile attendb8
		save `attendb8'
	restore 

	/* [> Work <] */ 
	preserve
		drop if work == . 
		replace earn=0 if work==0 & earn==.
		gen work_week = work
		gen earn_week = earn
		collapse (sum) work earn (count) work_week earn_week, by(pid phase week_in)
		gen work_adj = work/work_week*`dow'
		gen earn_adj = earn/earn_week*`dow'
		tempfile work
		save `work'
	restore

	/* [> Work 1 <] */ 
	preserve
		drop if work1 == . 
		gen work1_week = work1
		collapse (sum) work1 (count) work1_week, by(pid phase week_in)
		gen work1_adj = work1/work1_week*`dow'
		tempfile work1
		save `work1'
	restore

	/* [> Work orig <] */ 
	preserve
		drop if work_orig == . 
		gen work_orig_week = work_orig
		collapse (sum) work_orig (count) work_orig_week, by(pid phase week_in)
		gen work_orig_adj = work_orig/work_orig_week*`dow'
		tempfile work_orig
		save `work_orig'
	restore
	

	/* [> Additional info <] */ 
	preserve
		duplicates drop pid phase week_in , force
		keep pid phase week_in
		tempfile temp
		save `temp'
	restore 

	
	use `temp', clear 
	merge 1:1 pid week_in phase using `attend'
	drop _merge 
	merge 1:1 pid week_in phase using `attendb8'
	drop _merge 
	merge 1:1 pid week_in phase using `work'
	drop _merge 
	merge 1:1 pid week_in phase using `work1'
	drop _merge 
	merge 1:1 pid week_in phase using `work_orig'
	drop _merge 

	sort pid phase week_in
	

	assert earn == . if work == . 
	
	rename attend 				attend_nadj
	rename attend_and_before8 	attend_and_before8_nadj
	rename work 				work_nadj
	rename earn 				earn_nadj
	rename work1 				work1_nadj
	rename work_orig 			work_orig_nadj
	

	gen dow = 2

	merge 1:1 pid phase week_in using `late_announce_no_data' , keep(1 2 3)
	drop if _merge == 3
	drop _merge
	
	
	tempfile temp 
	save `temp'
	
	* Daily Data
	use  "$temp/03_bs_phase123_makevar.dta", clear
	replace earn=0 if work==0 & earn==.
	
	gen __3_WEEKLY_ATTENDACE________ = .
	merge m:1 pid week_in phase dow using `temp' , nogen
	sort pid date
	
	
	
**********************
**# 3.  Save Dataset
**********************

	save "$temp/03_bs_phase123_makevardaily_weekly.dta", replace
	