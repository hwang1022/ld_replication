*************************************************
*************************************************
*	Project: LD Main Study
*	Purpose: Phase 1 and phase 2 combined
*	Make variables and Weekly Value
*	Author: HW
*	Last modified: 2024-11-13 (HW)
*************************************************
*************************************************

	
	use "$temp/05_phase1_phase2_makepanel.dta", clear
	merge m:1 pid using "$temp/00_mainstudy_master.dta" , keep(1 2 3) keepusing(a_date late_announcement_flag modified_launchset_flag) nogen
	
	
	
	
*********************
**# Restrict Sample
*********************

	* Remove the Sunday at the end of the phase 1 and 2 so that the number of observations equal to Original Main dataset
	bys pid phase (date) : drop if _n == _N
	tab pid , sort

	* Restrict Phase 1 time phrame to 48 days, followign the original dataset (Following the original dataset, though I think it's okay to keep them)
	bys pid phase (date) : drop if _n > 48 & phase == 1
	
	
	
*******************************************************
**# Handle Late announcement but not change launchset
*******************************************************

	* For people with late announcement in the latest stand-batch, we need to replace as missing the days before annoucement
	replace attend = . if date <= a_date & modified_launchset_flag == 0 & late_announcement_flag == 1
	gen late_announce_no_data_flag = 0
	replace late_announce_no_data_flag = 1 if date <= a_date & modified_launchset_flag == 0 & late_announcement_flag == 1
	
	
	
*********************	
**# Basic Variables
*********************

	* Gen Day
	bysort  pid phase (date) : gen daycount = _n
	gen dow = dow(date)
	
	
	* HW Feb 2025: This is not true!
	/*
	foreach i of varlist mode-main_act_other {
		cap replace `i' = .  if dow == 0
		cap replace `i' = "" if dow == 0
	}
	*/
	foreach i of varlist attend {
		cap replace `i' = .  if dow == 0
		cap replace `i' = "" if dow == 0
	}
	
	* Week in study
    gen week_in = floor(daycount/7)	+ 1
	replace week_in = week_in - 1 if dow == 0
	la var week_in "Weeks into each phase"
	tab week_in // some stands extended past week 7
	
	
	* Handle Weekend and Holiday
	makeHolidays
	
	local inlist_holiday ""
	foreach i in `r(holiday_list)' {
		local inlist_holiday "`inlist_holiday', `i'"
	}
	
	gen is_holiday = 0
	replace is_holiday = 1 if inlist(date`inlist_holiday')
	replace attend = . if is_holiday == 1
	replace attend = . if dow == 0
	
	// replace work		= . if is_holiday == 1
	// replace work1		= . if is_holiday == 1
	// replace work_orig	= . if is_holiday == 1	
	
	

	* Arrive before cut-off-time (if attended)
	gen arrive_before_8 = arrival_time_hours <= 8 if ///
		!mi(arrival_time_hours) & !inlist(stand, ${cutoff_0815}, ${cutoff_0745})
	replace arrive_before_8 = arrival_time_hours <= 8.25 if ///
		!mi(arrival_time_hours) & inlist(stand, ${cutoff_0815})
	replace arrive_before_8 = arrival_time_hours <= 7.75 if ///
		!mi(arrival_time_hours) & inlist(stand, ${cutoff_0745})
	la var arrive_before_8 "Attended the stand and spotted before cut-off"
	
	* Attend and arrive before cut-off time (0 if not attended, or arrived after)
	gen attend_and_before8 = arrive_before_8 if attend == 1
	replace attend_and_before8 = 0 if attend == 0
	replace attend_and_before8 = . if mi(attend)
	la var attend_and_before8 "Attend by 8am (daily)"
	
	* Calendar week
	gen calendar_week = week(date)
	replace calendar_week = calendar_week - 1 if dow(date) == 6
	replace calendar_week = calendar_week - 1 if dow(date) == 0
	label var calendar_week "Calendar week"
	
	

* CREATE job found at stand

*----------------------------------------------------------------*
* 1. CLEAN SOURCE on NON-multiday work days  (stand=1 / not-stand=0)
*    howfound stand codes: v1 rf4_1 ={6,7,8}; v2 rf4_v2_1 ={8,9,10,11}
*    -> union {6,7,8,9,10,11}. (howfound==5 is ambiguous v1-multiday
*    vs v2-phone-friend, so it is NOT used here.)
*----------------------------------------------------------------*
* 7-day daily-recall-grid indicator (source detail only exists here)
gen grid = !mi(daily_recall_lag)
gen clean_stand = .
* primary: whenfound (2 = while at stand; 1/3 = outside). No version conflict.
replace clean_stand = 1 if whenfound==2
replace clean_stand = 0 if inlist(whenfound,1,3)
* non-attend days: howfound_notattend has NO stand option -> not-stand
*   (any non-missing source other than multiday code 5)
replace clean_stand = 0 if mi(clean_stand) & !mi(howfound_notattend) & howfound_notattend!=5
* rare fallback: attend-day channel where whenfound is missing
replace clean_stand = 1 if mi(clean_stand) & inlist(howfound,6,7,8,9,10,11)
replace clean_stand = 0 if mi(clean_stand) & inlist(howfound,1,2,3,4,998)

* "clean source" is only meaningful on NON-multiday WORK days
gen has_clean = (work==1 & multiday_job==0 & !mi(clean_stand))
replace clean_stand = . if !has_clean
label var clean_stand "Job found at stand (1/0), directly observed on non-multiday work days"

*----------------------------------------------------------------*
* 2. MULTIDAY SPELLS = maximal run of consecutive multiday WORK days
*    (restrict to work==1, order by date; non-work days are skipped
*    so they do not break a spell; a non-multiday work day starts a
*    new job).
*----------------------------------------------------------------*
gen byte multiday_work = (work==1 & multiday_job==1)
gen byte mwflag = multiday_work if work==1     // defined only on work days
preserve
    keep if work==1
    sort pid date
    by pid: gen lag_mw      = mwflag[_n-1]                       // prior work day multiday?
    by pid: gen spellstart  = (mwflag==1 & (lag_mw!=1 | mi(lag_mw)))
    by pid: gen spell_id    = sum(spellstart) if mwflag==1
    keep pid date spell_id spellstart
    tempfile spells
    save `spells'
restore
merge 1:1 pid date using `spells', nogen
label var spell_id "Multiday-job spell id (within pid)"

*----------------------------------------------------------------*
* 3. CONSERVATIVE ATTRIBUTION = clean source of the work day
*    IMMEDIATELY PRECEDING the spell (1 work-day lookback).
*----------------------------------------------------------------*
preserve
    keep if work==1
    sort pid date
    by pid: gen byte prevwork_clean = clean_stand[_n-1]   // prior work day's clean source
    keep if spellstart==1
    keep pid spell_id prevwork_clean
    tempfile anc
    save `anc'
restore
merge m:1 pid spell_id using `anc', nogen keep(1 3)

*----------------------------------------------------------------*
* 4. FINAL VARIABLE: job_at_stand (1 = found at stand, 0 = not)
*----------------------------------------------------------------*
gen job_at_stand = clean_stand                                   // direct on non-multiday days
replace  job_at_stand = prevwork_clean if multiday_work==1 & !mi(prevwork_clean)
* keep to the 7-day grid (comprehensive-recall days have no detail)
replace  job_at_stand = . if grid==0
label define yn_stand 0 "0. Not at stand (outside/phone/self/other)" 1 "1. Found at stand", replace
label values job_at_stand yn_stand
label var   job_at_stand "Employment found at the stand (1) vs not (0); multiday attributed from spell's preceding work day"

* provenance flag, for auditing how each label was assigned
gen byte job_at_stand_method = .
replace  job_at_stand_method = 1 if !mi(job_at_stand) & multiday_work==0          // directly observed
replace  job_at_stand_method = 2 if !mi(job_at_stand) & multiday_work==1          // attributed from prev work day
label define jasm 1 "1. Directly observed (non-multiday)" 2 "2. Attributed from spell's preceding work day", replace
label values job_at_stand_method jasm
label var   job_at_stand_method "How job_at_stand was assigned"

* tidy up helper vars (keep spell_id for auditing; drop the rest)
drop grid clean_stand has_clean multiday_work mwflag spellstart prevwork_clean

************************	
**# Save Before Weekly
************************


	save "$temp/05_phase1_phase2_makevar_daily.dta", replace
	
	

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
		collapse (sum) attend (count) attend_week , by(pid phase week_in)
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
	
	rename attend attend_nadj
	
	rename attend_and_before8 attend_and_before8_nadj
	rename work work_nadj
	rename earn earn_nadj
	rename work1 work1_nadj
	rename work_orig work_orig_nadj
	
	gen dow = 2

	
	merge 1:1 pid phase week_in using `late_announce_no_data' , keep(1 2 3)
	drop if _merge == 3
	drop _merge
	
	save "$temp/05_phase1_phase2_makevar_weekly.dta", replace
	
**************************	
**# Create Final Dataset
**************************

	use "$temp/05_phase1_phase2_makevar_daily.dta", clear

	merge 1:1 pid phase week_in dow using "$temp/05_phase1_phase2_makevar_weekly.dta" , keep(1 2 3)
	
	
	
	save "$temp/05_phase1_phase2_makevar_daily_weekly.dta", replace
	

	
	/*
	
*****************************************
**# Data Quality Check (HW added Dec 3)
*****************************************

	use "$temp/05_phase1_phase2_makevar_weekly.dta" , clear

	keep if phase == 1
	collapse (count)phase , by(pid)
	merge 1:1 pid using 	"$temp/00_mainstudy_master.dta"
	// keep if !mi(attend_nadj)
	
	*/
