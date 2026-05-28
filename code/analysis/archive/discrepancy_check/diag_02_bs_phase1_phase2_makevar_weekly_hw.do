**************************************************
**************************************************
*	Project: LD Main Study
*	Purpose: Construct Outcome Dataset for Analysis
*	Original Author: Daryl, Taken over by HW
*	Original Dofile Last modified: Yogita (01-31-2024)
*	Last Modified: HW Oct 31 2024
**************************************************
**************************************************

/*-------------------------------------------------------------*/
   /* [>   1.  Open data  <] */ 
/*-------------------------------------------------------------*/

 	use "$datadir/Analysis Prep/02. Output/03_bs_phase123_makevar.dta", clear
	isid pid date
	
	
	

/*-------------------------------------------------------------*/
   /* [>   2.  Collapse variables into weekly values  <] */ 
/*-------------------------------------------------------------*/

	//Treat a standard week as 6 days 
	local dow 6

	/* [> Attend <] */ 
		preserve
		drop if attend == . 
			* corresponds to dow==0, holiday==1 and 6 obs for late announcements 
		gen attend_week = attend  
		collapse (sum) attend (count) attend_week (mean) arrival_time_hours , by(pid phase week_in)
		gen attend_adj = attend/attend_week*`dow'
		tempfile attend
		save `attend'
		restore 

	/* [> Attend b co <] */ 
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
		gen work1_week = work
		collapse (sum) work1 (count) work1_week, by(pid treatment phase week_in)
		gen work1_adj = work1/work1_week*`dow'
		tempfile work1
		save `work1'
		restore

	/* [> Job Found at stand <] */ 
		assert job_found_at_stand == . if job_not_found_at_stand == . & inlist(phase, 1,2)
		assert job_not_found_at_stand == . if job_found_at_stand == . & inlist(phase, 1,2)
		preserve
		drop if job_found_at_stand == . 
		gen job_found_at_stand_week = job_found_at_stand
		gen job_not_found_at_stand_week = job_not_found_at_stand
		collapse (sum) job_found_at_stand job_not_found_at_stand (count) job_found_at_stand_week job_not_found_at_stand_week , by(pid treatment phase week_in)
		gen job_found_at_stand_adj = job_found_at_stand/job_found_at_stand_week*`dow'
		gen job_not_found_at_stand_adj = job_not_found_at_stand/job_not_found_at_stand_week*`dow'	
		tempfile jfs
		save `jfs'
		restore 

	/* [> Found at stand 2 <] */ 
		assert found_at_stand2 == . if found_not_at_stand2 == . & inlist(phase, 1,2)
		assert found_not_at_stand2 == . if found_at_stand2 == . & inlist(phase, 1,2)
		preserve
		drop if found_at_stand2 == . 
		gen found_at_stand2_week = found_at_stand2
		gen found_not_at_stand2_week = found_not_at_stand2
		collapse (sum) found_at_stand2 found_not_at_stand2 (count) found_at_stand2_week found_not_at_stand2_week , by(pid treatment phase week_in)
		gen found_at_stand2_adj = found_at_stand2/found_at_stand2_week*`dow'
		gen found_not_at_stand2_adj = found_not_at_stand2/found_not_at_stand2_week*`dow'	
		tempfile fas2
		save `fas2'
		restore 

	/* [> Found at stand 2 imputed <] */ 
		assert found_at_stand2_imp == . if found_not_at_stand2_imp == . & inlist(phase, 1,2)
		assert found_not_at_stand2_imp == . if found_at_stand2_imp == . & inlist(phase, 1,2)
		preserve
		drop if found_at_stand2_imp  == . 
		gen found_at_stand2_imp_week = found_at_stand2_imp
		gen found_not_at_stand2_imp_week = found_not_at_stand2_imp
		collapse (sum) found_at_stand2_imp  found_not_at_stand2_imp (count) found_at_stand2_imp_week found_not_at_stand2_imp_week , by(pid treatment phase week_in)
		gen found_at_stand2_imp_adj = found_at_stand2_imp/found_at_stand2_imp_week*`dow'	
		gen found_not_at_stand2_imp_adj = found_not_at_stand2_imp/found_not_at_stand2_imp_week*`dow'
		tempfile fas2_imp
		save `fas2_imp'
		restore 

		preserve
		drop if found_at_stand2_imp  == . 
		drop if phase == 2 & week_in == 7 & inlist(dow, 6)
		gen found_at_stand2_imp_week = found_at_stand2_imp
		gen found_not_at_stand2_imp_week = found_not_at_stand2_imp
		collapse (sum) found_at_stand2_imp  found_not_at_stand2_imp (count) found_at_stand2_imp_week found_not_at_stand2_imp_week , by(pid treatment phase week_in)
		gen found_at_stand2_imp_p2w7_adj = found_at_stand2_imp/found_at_stand2_imp_week*`dow'	
		gen found_not_at_stand2_imp_p2w7_adj = found_not_at_stand2_imp/found_not_at_stand2_imp_week*`dow'
		keep pid treatment week_in phase found_at_stand2_imp_p2w7_adj found_not_at_stand2_imp_p2w7_adj
		tempfile fas2_imp2
		save `fas2_imp2'
		restore 


	/* [> Additional info <] */ 
		preserve
		collapse (lastnm) strata stand calendar_week launchset bs_sum_attend bs_sum_work week_in_p1_p2 week_in_bs_p1_p2, by(pid treatment phase week_in)
		tempfile temp
		save `temp'
		restore 

		use `temp', clear 
		merge 1:1 pid week_in phase treatment using `attend'
		drop _merge 
		merge 1:1 pid week_in phase treatment using `attendb8'
		drop _merge 
		merge 1:1 pid week_in phase treatment using `work'
		drop _merge 
		merge 1:1 pid week_in phase treatment using `work1'
		drop _merge 
		merge 1:1 pid week_in phase treatment using `jfs'
		drop _merge 
		merge 1:1 pid week_in phase treatment using `fas2'
		drop _merge 
		merge 1:1 pid week_in phase treatment using `fas2_imp'
		drop _merge 
		merge 1:1 pid week_in phase treatment using `fas2_imp2'
		drop _merge 

		sort pid phase week_in
		assert earn == . if work == . 
		/* assert earn == 0 if work == 0 */

		//generate variables 
		gen arrival_time_hours_std = arrival_time_hours
			replace arrival_time_hours_std = arrival_time_hours - 0.25 if inlist(stand, ${cutoff_0815}) 
			replace arrival_time_hours_std = arrival_time_hours + 0.25 if inlist(stand, ${cutoff_0745})
			replace arrival_time_hours_std = 10 if arrival_time_hours_std >= 10 & arrival_time_hours_std != .  
		label var arrival_time_hours_std "Arrival time (observed) in fraction of hours, all stands"

		// label variables 
		la var work_adj "Work (weekly, adjusted)"
		la var work_week "Number of days where work is recorded (weekly)"
		la var work1_adj "Work (weekly, adjusted)"
		la var work1_week "Number of days where work is recorded (weekly)"
		la var earn_adj "Wage earned (weekly, adjusted)"
		la var earn_week "Number of days where earn is recorded (weekly)"
		la var attend_adj "Attend (weekly, adjusted)"
		la var attend_week "Number of days where attend is recorded (weekly)"
		la var attend_and_before8_adj  "Attend by 8am (weekly, adjusted)"	
		la var attend_and_before8_week "Number of days where attend by 8 is recorded (weekly)"
		la var job_found_at_stand_adj "Worked (Stand) (weekly, adjusted)"
		la var job_found_at_stand_week "Number of days where work (stand) is recorded (weekly)"
		la var job_not_found_at_stand_adj "Worked (Other Sources) (weekly, adjusted)"
		la var job_not_found_at_stand_week "Number of days where work (other sources) is recorded (weekly)"

	/* [> Checks <] */ 
		//DL- 271222 to write an assertion that the right number of observations per pid
	/* 	snapshot save 
		local snapshot_num r(snapshot)
		// snapshot used instead of preserve and restore, so that preserve and restore can be used for other purposes
		contract pid stand launchset phase, freq(phase_freq)

		//for baseline
		cap assert _freq == 1 if phase == 0
		if _rc == 9 {
			list pid if _freq != 1 & phase == 0
		}

		// To check the numbers match the launchsets

		//for phase 1
		*to check if within launchset is consistent
		preserve
		contract launchset phase_freq if phase == 1, freq(pid_freq)
		bys launchset: gen count = _n
		assert count == 1
		restore 
	 	assert phase_freq == 7 if inlist(launchset,1,2,3,4,5,13,14,15,16)
		assert phase_freq == 11 if inlist(launchset,10,11,12,17)
		
	 	//for phase 2
	 	*to check if within launchset is consistent
		preserve
		contract launchset phase_freq if phase == 2, freq(pid_freq)
		bys launchset: gen count = _n
		assert count == 1
		restore 

		snapshot restore `snapshot_num' */
		
		
		e4gergergerg

/*-------------------------------------------------------------*/
   /* [>   3.  Merge in follow up data (Phase 3)   <] */ 
/*-------------------------------------------------------------*/
	
	* Added 2024.04.29

	preserve

	use "$datadir/07. Phase 3/02. Output/02_phase3_cleaned.dta", clear 
	isid pid date 
	
	* FIXME YS: why do we make this restriction? We lose 11% of obs that take place in weeks 1-3, and 2% of obs from weeks 27-32
		* the obs from weeks 27-32 are probably when we went back to very early stands to do the wives survey. 
	keep if inrange(weeks_after_p2, 4, 15)
	* keep if inrange(weeks_after_p2, 1, 15)

	keep phase pid stand attend attend_and_before8 weeks_after_p2 calendar_week launchset
	gen attend_week = attend  
	collapse (mean) calendar_week attend attend_and_before8 phase (count) attend_week, by(pid stand weeks_after_p2)
		* Note: because there are several batches within each stand, for every stand-date, the PIDs might belong to different weeks_after_p2.

	* YS 2024.02.09 FIXME THIS ISN'T ENTIRELY CORRECT. WE HAVE MULT OBS PER WEEK IN SOME WEEKS.
	  *gen attend_adj =  attend*6
	  *gen attend_and_before8_adj = attend_and_before8*6
	  gen attend_adj = attend/attend_week*6
	  gen attend_and_before8_adj = attend_and_before8/attend_week*6

  	gen week_in = weeks_after_p2 - 3
  
	tempfile temp 
	save `temp'
	restore 

	/*
	* OLDER 
	preserve
	use "$datadir/08. Others/02. Output/followups/followups_panel_cleaned.dta" , clear
	* YS: code that created this dataset is here - 07. Data/3. Main Study 3.0/02. Cleaning Data/08. Others/01. Code/04_ld_p2_followup_visits_code_renaming.do
		* the relevant code (lines 42 to 168) is commented out entirely, no idea why.
		* I cannot trace the raw input file (07. Data/3. Main Study 3.0/01. Raw Data/03. DTA Files/lss_phase2_followup_survey_v1.dta) - why? data encryption? emailed Alosias and Luisa on 2024-04-11.
	gen phase = 3
	drop deviceid subscriberid simid devicephonenum username duration caseid stand1_6 dem_sum_attend dem_sum_work p0_998 p2_998 name z0_a_998 formdef_version key submissiondate followup_visit_day zero_att p2_end_date end_dow month min_visit_date cutoff starttime endtime launchset interviewer
	rename treatment_status treatment
	isid pid date 

	// do we have a balanced panel? mostly yes.
	bys stand: tab pid 
		* stand 16 seems problematic, some PIDs have fewer entries 
	bys stand: tab date
		* stand 16 10nov and 11nov only have 23 entries (all other dates have 33 entries)

	order phase stand date pid

	* br if a1==1 & attend==0
		* 3 obs where attend = 0 even though participant came to stand (based on a1)

	gen calendar_week = week(date)
	replace calendar_week = calendar_week - 1 if dow(date) == 6
	replace calendar_week = calendar_week - 1 if dow(date) == 0
	label var calendar_week "Week in the year"
	
	* check data 
	*count if phase==3 & stand==1 & calendar_week==30 // 34
	*count if phase==3 & stand==1 & calendar_week==31 // 34
	*count if phase==3 & stand==1 & calendar_week==34 // 34

	* FIXME YS: why do we make this restriction? We lose 14% of obs that take place in weeks 1-3
	keep if inrange(weeks_after_p2, 4, 15)

	bys stand: tab visit_count
	* Note: in some stands, we went back very often. 27 times in stand 16, 17 times in stands 13 and 17.

	keep phase pid stand attend attend_and_before8 weeks_after_p2 calendar_week
	gen attend_week = attend  
	collapse (mean) attend attend_and_before8 calendar_week phase (count) attend_week, by(pid stand weeks_after_p2)
		* Note: because there are several batches within each stand, for every stand-date, the PIDs might belong to different weeks_after_p2.

	* YS 2024.02.09 FIXME THIS ISN'T ENTIRELY CORRECT. WE HAVE MULT OBS PER WEEK IN SOME WEEKS.
	  *gen attend_adj =  attend*6
	  *gen attend_and_before8_adj = attend_and_before8*6
	  gen attend_adj = attend/attend_week*6
	  gen attend_and_before8_adj = attend_and_before8/attend_week*6

  	gen week_in = weeks_after_p2 - 3
  
	tempfile temp 
	save `temp'
	restore 
	*/
	
	append using `temp'

* Harmonize week in variable 
	gen week_in_p1_p2_p3 = week_in_p1_p2
	replace week_in_p1_p2_p3 = week_in +15 if phase == 3

	gen week_in_bs_p1_p2_p3 = week_in_bs_p1_p2
	replace week_in_bs_p1_p2_p3 = week_in +15 if phase == 3 

* Replace time-invariant variables 
	foreach i in treatment stand strata bs_sum_attend launchset {
		bys pid: ereplace `i' = max(`i')
	}

/*-------------------------------------------------------------*/
   /* [>   4.  Merge in payment data (Phase 1)   <] */ 
/*-------------------------------------------------------------*/

	merge 1:1 pid week_in phase using "$datadir/05a. Phase 1 Incentive/02. Output/05_phase1_comprehension_makevar_short.dta"
 	count if phase==1 & _merge==1 
 		* 67 pid-week pairs have missing payments data 
 		* FIXME these are problematic - we should not have any missing data in phase 1.
 	drop _merge 

/*----------------------------------------------------*/
   /* [>   5.  Save data   <] */ 
/*----------------------------------------------------*/

	save "$datadir/Analysis Prep/02. Output/04_bs_phase1_phase2_makevar_weekly.dta", replace

/*----------------------------------------------------*/
   /* [>   6.  Combine weekly and daily data  <] */ 
/*----------------------------------------------------*/

	/* [> Weekly Data <] */ 
		use "$datadir/Analysis Prep/02. Output/04_bs_phase1_phase2_makevar_weekly.dta",clear
		isid pid phase week_in

		* Non-adjusted variables 
		rename attend                     attend_nadj
		label var attend_nadj 				 "Attendance (weekly, not adjusted)"	
		rename attend_and_before8         attend_and_before8_nadj
		label var attend_and_before8_nadj "Attend by 8am (weekly, not adjusted)"
		rename work                       work_nadj
		label var work_nadj               "Work (weekly, not adjusted)"
		rename work1                      work1_nadj
		label var work1_nadj               "Work (weekly, not adjusted)"
		rename earn                       earn_nadj
		label var earn_nadj               "Wage earned (weekly, not adjusted)"
		rename job_found_at_stand         job_found_at_stand_nadj
		label var job_found_at_stand_nadj  "Job found at stand (weekly, not adjusted)"
		rename job_not_found_at_stand     job_not_found_at_stand_nadj
		label var job_not_found_at_stand_nadj  "Job not found at stand (weekly, not adjusted)"
		rename found_at_stand2            found_at_stand2_nadj
		label var found_at_stand2_nadj    "Job found at stand (weekly, not adjusted)"
		rename found_not_at_stand2        found_not_at_stand2_nadj
		label var found_not_at_stand2_nadj  "Job not found at stand (weekly, not adjusted)"
		rename found_at_stand2_imp        found_at_stand2_imp_nadj
		label var found_at_stand2_imp_nadj     "Job found at stand (weekly, not adjusted)"
		rename found_not_at_stand2_imp    found_not_at_stand2_imp_nadj
		label var found_not_at_stand2_imp_nadj "Job not found at stand (weekly, not adjusted)"

		gen work_stand_nstand_adj = found_at_stand2_adj + found_not_at_stand2_adj
		label var found_at_stand2_adj "Work Found At Stand (weekly, adjusted)"
		label var found_not_at_stand2_adj "Work Found Outside Stand (weekly, adjusted)"
		label var work_stand_nstand_adj "Work Found At Stand/Outside Stand (weekly, adjusted)"
		gen work_stand_nstand_imp_adj = found_at_stand2_imp_adj + found_not_at_stand2_imp_adj
		gen work_stand_nstand_imp_p2w7_adj = found_at_stand2_imp_p2w7_adj + found_not_at_stand2_imp_p2w7_adj

		replace earn_nadj=. if earn_nadj!=. & earn_adj==.

		tempfile temp 
		save `temp'

	/* [> Daily Data <] */ 
	 	use "${datadir}/Analysis Prep/02. Output/03_bs_phase1_phase2_makevar.dta", clear
		replace earn=0 if work==0 & earn==.

	 	//merge both data sets
	 	merge m:1 pid week_in phase using `temp', gen(weekly_data) keepusing(attend* attend_and_before8* work* found_at_stand2* job_found_at_stand* job_not_found_at_stand* found_not_at_stand* earn* arrival_time_hours_std week_in_p1_p2_p3 week_in_bs_p1_p2_p3 total_payment)

	 	merge m:1 pid week_in phase using `temp', gen(calweek) keepusing(calendar_week) update
	 	drop calweek

	 	sort pid phase week_in
	 	foreach var in attend_nadj attend_week attend_adj attend_and_before8_nadj attend_and_before8_week attend_and_before8_adj work_nadj work1_nadj earn_nadj work_week work1_week earn_week work_adj work1_adj earn_adj job_found_at_stand_nadj job_not_found_at_stand_nadj job_found_at_stand_week job_not_found_at_stand_week job_found_at_stand_adj job_not_found_at_stand_adj found_at_stand2_nadj found_not_at_stand2_nadj found_at_stand2_week found_not_at_stand2_week found_at_stand2_adj found_not_at_stand2_adj found_at_stand2_imp_adj found_not_at_stand2_imp_adj found_at_stand2_imp_p2w7_adj found_not_at_stand2_imp_p2w7_adj {
	 		 	bys pid phase week_in (date): replace `var' = . if _n != 2 & phase != 3
	 	}

		foreach i in treatment stand strata bs_sum_attend {
			bys pid (phase week_in): ereplace `i' = max(`i')
		}

	 	la var treatment "Treatment"

/*----------------------------------------------------*/
   /* [>   7.  Data Creation For Analysis  <] */ 
/*----------------------------------------------------*/

// Attrition Variables
	 * Phase 2 Informal Dropouts - daycount is held at 48 to standardize that by end of week 7, we identify the informal dropouts
		bys pid (date): gen inf_dropout_3_p2 = 1  if daycount == 48 & last_attended >= 21 & last_spoke >= 21
			replace inf_dropout_3_p2 = 0 if inf_dropout_3_p2 == .
		bys pid (date): ereplace inf_dropout_3_p2 = max(inf_dropout_3_p2)

		gen missing_work = work == . if inlist(phase, 1, 2)
		gen missing_fs2 = found_at_stand2 == . if inlist(phase, 1, 2)

		la var inf_dropout_3_p2      "Phase 2 Informal Dropouts"
		la var p1_inf_dropout_3      "Phase 1 Informal Dropouts"
		la var inf_dropout_3_overall "Overall Informal Dropouts"
		la var missing_work          "=1 if Missing Work"
		la var missing_fs2           "=1 if Missing Found at Stand"

/* [> Shocks <] */
	* Code was written by MC + HS

	* merge in announcement data
		preserve
			use "${datadir}/04. Announcement/02. Output/04_announcement_completed_makevar.dta", clear
			keep pid late_announcement_flag a_belief_attend_change a_belief_arrival_time_change treatment
			rename late_announcement_flag late_announcement_flag2
			tempfile announcement
			save `announcement' 
		restore
		cap drop _merge
		merge m:1 pid using `announcement', assert(using mat)
		keep if _merge==3
		cap drop _merge

		* YS 02/08/2024
			* corr late_announcement_flag late_announcement_flag2
				* we already have this variable in data - is the above code redundant? 

	*1) Organize data for analysis of shock
		*Create same variable than "last_attended" (which counts the number of days since the worker last attended the stand), but excluding sundays and holidays
		*not_attend_spell=1 when observation is part of a non-attendance spell (defined in previous code by excluding sundays and holidays)

		tempfile temp 
		save `temp'
		drop if dow == 0 | holiday == 1 /* exclude sundays and holidays */
		drop if date == .

		bys pid (date): gen days2 = _n
		tsset pid days2
		tsspell not_attend_spell, cond(not_attend_spell == 1) /* separate observations by spell of non-attendance */
		rename _seq day_nb_in_non_attend_spell
		replace day_nb_in_non_attend_spell = . if day_nb_in_non_attend_spell == 0 /* replace by missing in attendance spells */

		*In the following, the goal is to add the information contained in the variable "why_nottry" (asked if the respondent said they didn't look for work this day) to the variables "reason_absence_planned_event"  and "reason_absence_emergency" constructed in previous code. Then, following the same procedure as in previous code, we impute the reason to the whole non-attending spell if no work is mentioned during this spell.
		*why_nottry=5 if "Other obligations (planned events)"
		*why_nottry=7 if "Emergency"
		*reason_absence_native=1 if "travel" or "I had to return to my native"
		*reason_absence_planned_event=1 if "Planned events (marriage, functions)" or "I had to attend a function"
		*reason_absence_emergency=1 if "Emergency (fire, flood, accident, someone got sick or other unexpected events)" or "Emergencies (medical, family, etc)."

		gen reason_absence_planned_event2 = reason_absence_planned_event
		replace reason_absence_planned_event2 = 1 if why_nottry == 5 & reason_absence_work == 0 & not_attend_spell == 1
		bys pid _spell: ereplace reason_absence_planned_event2 = max(reason_absence_planned_event2) if not_attend_spell == 1

		gen reason_absence_emergency2 = reason_absence_emergency
		replace reason_absence_emergency2 = 1 if why_nottry == 7 & reason_absence_work == 0 & not_attend_spell == 1 
		bys pid _spell: ereplace reason_absence_emergency2 = max(reason_absence_emergency2) if not_attend_spell == 1

		merge 1:1 pid date phase week_in using `temp'
		drop _merge _spell _end
		sort pid date

		order day_nb_in_non_attend_spell, after(not_attend_spell)
		order reason_absence_planned_event2, after(reason_absence_planned_event)
		order reason_absence_emergency2, after(reason_absence_emergency)

	*2) Create dummy for stand-week level shocks
			* Identify stand-week shock as bottom 10% of the attendance distribution for the control group
		
		* Phase 1
		preserve
			keep if treatment == 0 & phase == 1
			bys stand calendar_week: egen mean_attend=mean(attend_adj)
			duplicates drop stand calendar_week, force
			order calendar_week mean_attend, after(stand) 
			_pctile mean_attend, percentiles(10)
			scalar decile1=r(r1)
			gen decile1=decile1
			gen bottom_10=mean_attend<=decile1 if mean_attend!=.
			keep stand calendar_week bottom_10
			tempfile temp_p1 
			save `temp_p1', replace
		restore

		merge m:1 stand calendar_week using `temp_p1'
		drop _merge

		gen week_after=calendar_week+1 if bottom_10 == 1
		bys stand: egen first_week_after=min(week_after) 
		gen after_shock_p1=1 if calendar_week>=first_week_after & calendar_week!=.
		replace after_shock_p1=0 if after_shock_p1 == . & calendar_week!=.
		drop bottom_10 week_after first_week_after
		label var after_shock_p1 "After shock at stand"

		*Phase 2
		preserve
			keep if treatment == 0 & phase == 2
			bys stand calendar_week: egen mean_attend=mean(attend_adj)
			duplicates drop stand calendar_week, force
			order calendar_week mean_attend, after(stand) 
			_pctile mean_attend, percentiles(10)
			scalar decile1=r(r1)
			gen decile1=decile1
			gen bottom_10=mean_attend<=decile1 if mean_attend!=.
			keep stand calendar_week bottom_10
			tempfile temp_p2 
			save `temp_p2', replace
		restore

		merge m:1 stand calendar_week using `temp_p2'

		gen week_after=calendar_week+1 if bottom_10 == 1
		bys stand: egen first_week_after=min(week_after) 
		gen after_shock_p2=1 if calendar_week>=first_week_after & calendar_week!=.
		replace after_shock_p2=0 if after_shock_p2==. & calendar_week!=.
		drop bottom_10 week_after first_week_after
		label var after_shock_p2 "After shock at stand"

		** Combine with shock module **
			*Stats desc
			preserve
			keep if phase==1
			bys pid: egen event=max(event_any)
			bys pid: egen invite=max(invite_any)
			bys pid: egen event_invite=max(event_invite_any)
			duplicates drop pid, force
			sum event /* 31% of people experienced an event in phase 1 */
			sum invite /* 32% of people experienced an invite in phase 1 */
			sum event_invite /* 41% of people experienced an event or invite in phase 1 */
			restore

			preserve
			keep if phase==2
			bys pid: egen event=max(event_any)
			bys pid: egen invite=max(invite_any)
			bys pid: egen event_invite=max(event_invite_any)
			duplicates drop pid, force
			sum event /* 10% of people experienced an event in phase 2 */
			sum invite /* 8% of people experienced an invite in phase 2 */
			sum event_invite /* 15% of people experienced an event or invite in phase 2 */
			restore

			egen event_invite_duration = rowmax(event_duration_days invite_duration_days) 
			order event_any invite_any event_invite_any event_duration_days invite_duration_days event_invite_duration, after(not_attend_spell)

	*Define absence as being absent for more than 3 days because of planned event, emergency or travel to village, or as being invited to an event/invite that lasts more than 3 days

		forvalues i = 1/2 {
			*Events only
			gen absence1_event_p`i'=(((reason_absence_native==1 | reason_absence_planned_event2==1 | reason_absence_emergency2==1) & (day_nb_in_non_attend_spell>=3 & not_attend_spell==1)) | (event_any==1 & event_duration_days>=3)) & (phase==`i')
			bys pid (date) : gen first_day_absence=_n if absence1_event_p`i'==1
			bys pid : ereplace first_day_absence=min(first_day_absence)
			bys pid (date) : gen after_absence1_event_p`i'=1 if _n>first_day_absence
			replace after_absence1_event_p`i'=0 if after_absence1_event_p`i'==.
			drop first_day_absence
			label var after_absence1_event_p`i' "After absence"
			
			*Invites only
			gen absence1_invite_p`i'=(((reason_absence_native==1 | reason_absence_planned_event2==1 | reason_absence_emergency2==1) & (day_nb_in_non_attend_spell>=3 & not_attend_spell==1)) | (invite_any==1 & invite_duration_days>=3)) & (phase==`i')
			bys pid (date) : gen first_day_absence=_n if absence1_invite_p`i'==1
			bys pid : ereplace first_day_absence=min(first_day_absence)
			bys pid (date) : gen after_absence1_invite_p`i'=1 if _n>first_day_absence
			replace after_absence1_invite_p`i'=0 if after_absence1_invite_p`i'==.
			drop first_day_absence
			label var after_absence1_invite_p`i' "After absence"
			
			*Events + invites
			gen absence1_event_invite_p`i'=(((reason_absence_native==1 | reason_absence_planned_event2==1 | reason_absence_emergency2==1) & (day_nb_in_non_attend_spell>=3 & not_attend_spell==1)) | (event_invite_any==1 & event_invite_duration>=3)) & (phase==`i') 
			bys pid (date) : gen first_day_absence=_n if absence1_event_invite_p`i'==1
			bys pid : ereplace first_day_absence=min(first_day_absence)
			bys pid (date) : gen after_absence1_event_invite_p`i'=1 if _n>first_day_absence
			replace after_absence1_event_invite_p`i'=0 if after_absence1_event_invite_p`i'==.
			drop first_day_absence
			label var after_absence1_event_invite_p`i' "After absence"
			
			*Events + stand shock
			gen after_event_combined_p`i'=(after_absence1_event_p`i'==1) | (after_shock_p`i'==1)
			label var after_event_combined_p`i' "After absence or stand shock"
			
			*Invites + stand shock
			gen after_invite_combined_p`i'=(after_absence1_invite_p`i'==1) | (after_shock_p`i'==1)
			label var after_invite_combined_p`i' "After absence or stand shock"
			
			*Events + invites + stand shock
			gen after_event_invite_combined_p`i'=(after_absence1_event_invite_p`i'==1) | (after_shock_p`i'==1)
			label var after_event_invite_combined_p`i' "After absence or stand shock"
		}

		order absence1_event_invite_p1 absence1_event_invite_p2, after(event_invite_duration)

		*% of people who experienced at least one of these shocks
			forvalues i=1/2 {
				preserve
				keep if phase == `i'
				bys pid: ereplace absence1_event_p`i'              = max(absence1_event_p`i')
				bys pid: ereplace absence1_invite_p`i'             = max(absence1_invite_p`i')
				bys pid: ereplace absence1_event_invite_p`i'       = max(absence1_event_invite_p`i')
				bys pid: ereplace after_event_combined_p`i'        = max(after_event_combined_p`i')
				bys pid: ereplace after_invite_combined_p`i'       = max(after_invite_combined_p`i')
				bys pid: ereplace after_event_invite_combined_p`i' = max(after_event_invite_combined_p`i')
				duplicates drop pid, force
				sum absence1_event_p`i' /* 47% in phase 1 and 44% in phase 2 */
				sum absence1_invite_p`i' /* 50% in phase 1 and 42% in phase 2 */
				sum absence1_event_invite_p`i' /* 52% in phase 1 and 45% in phase 2 */
				sum after_event_combined_p`i' /* 59% in phase 1 and 51% in phase 2 */
				sum after_invite_combined_p`i' /* 61% in phase 1 and 49% in phase 2 */
				sum after_event_invite_combined_p`i' /* 62% in phase 1 and 52% in phase 2 */
				restore
			}

		** Add controls **
		bys pid: egen p2_announced_late2 = max(p2_announced_late)
		gen p2_announced_late_miss = p2_announced_late2 == .
		replace p2_announced_late2 = 0 if p2_announced_late2 == .

		* FIXME 2024-04-11 commenting out as avg_spot_time is missing 
		/*
		gen avg_spot_time_orig = avg_spot_time
		drop avg_spot_time
		egen avg_spot_time = mean(avg_spot_time), by(pid) 
		gen avg_spot_time_miss = avg_spot_time == .
		replace avg_spot_time = 0 if avg_spot_time_miss == 1 
		*/

/* [> Time Use Survey <] */ 
	/*
	+----------------------+--------------------------------------------------------------------------------+
	| Variable             | Label                                                                          |
	+----------------------+--------------------------------------------------------------------------------+
	| activity_tot_time_1  | Total time in the morning (5.30am-9am) to Get water                            |
	+----------------------+--------------------------------------------------------------------------------+
	| activity_tot_time_2  | Total time in the morning (5.30am-9am) to Cook breakfast                       |
	+----------------------+--------------------------------------------------------------------------------+
	| activity_tot_time_3  | Total time in the morning (5.30am-9am) to Eat breakfast                        |
	+----------------------+--------------------------------------------------------------------------------+
	| activity_tot_time_4  | Total time in the morning (5.30am-9am) to Help get kids ready for school       |
	+----------------------+--------------------------------------------------------------------------------+
	| activity_tot_time_5  | Total time in the morning (5.30am-9am) to Drop kids at school                  |
	+----------------------+--------------------------------------------------------------------------------+
	| activity_tot_time_6  | Total time in the morning (5.30am-9am) to Wash/bathe                           |
	+----------------------+--------------------------------------------------------------------------------+
	| activity_tot_time_7  | Total time in the morning (5.30am-9am) to Go to temple/prayers/meditate        |
	+----------------------+--------------------------------------------------------------------------------+
	| activity_tot_time_8  | Total time in the morning (5.30am-9am) to Go to the store/shop                 |
	+----------------------+--------------------------------------------------------------------------------+
	| activity_tot_time_9  | Total time in the morning (5.30am-9am) to Call employers/friends to find a job |
	+----------------------+--------------------------------------------------------------------------------+
	| activity_tot_time_10 | Total time in the morning (5.30am-9am) to Travel                               |
	+----------------------+--------------------------------------------------------------------------------+
	| activity_tot_time_11 | Total time in the morning (5.30am-9am) to Sleep                                |
	+----------------------+--------------------------------------------------------------------------------+
	| activity_tot_time_12 | Total time in the morning (5.30am-9am) to Be at the stand/ Search for work     |
	+----------------------+--------------------------------------------------------------------------------+
	| bedtime              | Bedtime                                                                        |
	+----------------------+--------------------------------------------------------------------------------+
	| time_whodid1         | Who more likely to Get water                                                   |
	+----------------------+--------------------------------------------------------------------------------+
	| time_whodid2         | Who more likely to Cook breakfast                                              |
	+----------------------+--------------------------------------------------------------------------------+
	| time_whodid4         | Who more likely to Help get kids ready for school                              |
	+----------------------+--------------------------------------------------------------------------------+
	| time_whodid5         | Who more likely to Drop kids at school                                         |
	+----------------------+--------------------------------------------------------------------------------+
	| time_whodid8         | Who more likely to Go to the store/shop                                        |
	+----------------------+--------------------------------------------------------------------------------+
	| jfp_8am              | Days of work will find next week if come to the stand everyday at 8am          |
	+----------------------+--------------------------------------------------------------------------------+
	| jfp_9am              | Days of work will find next week if come to the stand everyday at 9am          |
	+----------------------+--------------------------------------------------------------------------------+
	*/

	/* [> Generating binaries <] */ 
	gen tu_water_myself     = tu_time_whodid1 == 1 if inlist(tu_time_whodid1, 1,2,3)
	gen tu_cook_myself      = tu_time_whodid2 == 1 if inlist(tu_time_whodid2, 1,2,3)
	gen tu_help_kids_myself = tu_time_whodid4 == 1 if inlist(tu_time_whodid4, 1,2,3)
	gen tu_drop_kids_myself = tu_time_whodid5 == 1 if inlist(tu_time_whodid5, 1,2,3)
	gen tu_store_myself     = tu_time_whodid8 == 1 if inlist(tu_time_whodid8, 1,2,3)

	egen tu_hh_chores_myself = anymatch(tu_water_myself tu_cook_myself), values(1)
		replace tu_hh_chores_myself = . if tu_water_myself == . & tu_cook_myself == . 
	egen tu_prep_kids_myself = anymatch(tu_help_kids_myself tu_drop_kids_myself), values(1)
		replace tu_prep_kids_myself = . if tu_help_kids_myself == . & tu_drop_kids_myself == . 

	*combining the time use together
		foreach i of varlist tu_activity_tot_time_* {
			replace `i' = `i'*60
		}
	egen tu_activity_tot_time_hh_chores = rowtotal(tu_activity_tot_time_1 tu_activity_tot_time_2 tu_activity_tot_time_3), missing
	egen tu_activity_tot_time_kids      = rowtotal(tu_activity_tot_time_4 tu_activity_tot_time_5), missing
	egen tu_activity_tot_time_errands   = rowtotal(tu_activity_tot_time_6 tu_activity_tot_time_7 tu_activity_tot_time_8 tu_activity_tot_time_10), missing
	egen tu_activity_tot_time_work      = rowtotal(tu_activity_tot_time_9 tu_activity_tot_time_12), missing

		foreach i of varlist tu_time_activity_*_adj {
			replace `i' = `i'*30
		}
	egen tu_time_activity_hh_chores_adj = rowtotal(tu_time_activity_1_adj tu_time_activity_2_adj tu_time_activity_3_adj tu_time_activity_14_adj), missing
	egen tu_time_activity_kids_adj      = rowtotal(tu_time_activity_4_adj tu_time_activity_5_adj), missing
	egen tu_time_activity_errands_adj   = rowtotal(tu_time_activity_6_adj tu_time_activity_7_adj tu_time_activity_8_adj tu_time_activity_10_adj tu_time_activity_15_adj), missing
	egen tu_time_activity_work_adj      = rowtotal(tu_time_activity_9_adj tu_time_activity_12_adj), missing
	egen tu_time_activity_rest_adj      = rowtotal(tu_time_activity_11_adj tu_time_activity_13_adj), missing


	//recombining 
	egen tu_time_activity_for_others_adj = rowtotal(tu_time_activity_1_adj tu_time_activity_2_adj tu_time_activity_4_adj tu_time_activity_5_adj tu_time_activity_14_adj), missing
	egen tu_time_activity_for_self_adj = rowtotal(tu_time_activity_3_adj tu_time_activity_6_adj tu_time_activity_7_adj tu_time_activity_8_adj tu_time_activity_10_adj tu_time_activity_15_adj), missing


	//get the phase and calendar week 
		*replace phase = 3 if time_use_survey == 1 & phase == . 
		*replace calendar_week = week(date) if phase == 3 & time_use_survey == 1
		*replace calendar_week = calendar_week - 1 if dow(date) == 6 & phase == 3 & time_use_survey == 1
		*replace calendar_week = calendar_week - 1 if dow(date) == 0 & phase == 3 & time_use_survey == 1

/* [> Phase 1 Incentive data <] */ 
	merge m:1 pid stand using "${dir}/06. Monitoring/05a. Phase 1 Incentive/03. Stand Quality/02. Output/p1_incentive_surveyor_data_pid_.dta", gen(incentive)

	drop if incentive == 2

/* [> Generate new comp recall variables <] */ 
	* br pid phase date dow attend work mode recall_days comp_days if phase !=0 & phase !=3
	bys pid (date): gen recall_length = 1 if recall_days[_n+1]==1 & recall_days!=.
	bys pid (date): gen temp1 = 1 if recall_days[_n+1] > 1 & recall_days[_n+1]!=. & comp_days==.
	bys pid (date): gen temp2 = 2 if recall_days[_n+2] > 1 & temp1[_n+1]==1 & comp_days==. 
	bys pid (date): gen temp3 = 3 if recall_days[_n+3] > 2 & temp1[_n+2]==1 & temp2[_n+1]==2 & comp_days==. 
	bys pid (date): gen temp4 = 4 if recall_days[_n+4] > 3 & temp1[_n+3]==1 & temp2[_n+2]==2 & temp3[_n+1]==3 & comp_days==. 
	bys pid (date): gen temp5 = 5 if recall_days[_n+5] > 4 & temp1[_n+4]==1 & temp2[_n+3]==2 & temp3[_n+2]==3 & temp4[_n+1]==4 & comp_days==. 
	bys pid (date): gen temp6 = 6 if recall_days[_n+6] > 5 & temp1[_n+5]==1 & temp2[_n+4]==2 & temp3[_n+3]==3 & temp4[_n+2]==4 & temp5[_n+1]==5 & comp_days==. 
	bys pid (date): gen temp7 = 7 if recall_days[_n+7] > 6 & temp1[_n+6]==1 & temp2[_n+5]==2 & temp3[_n+4]==3 & temp4[_n+3]==4 & temp5[_n+2]==5 & temp6[_n+1]==6 & comp_days==. 

	replace recall_length = temp1 if temp1!=.
	replace recall_length = temp2 if temp2!=.
	replace recall_length = temp3 if temp3!=.
	replace recall_length = temp4 if temp4!=.
	replace recall_length = temp5 if temp5!=.
	replace recall_length = temp6 if temp6!=.
	replace recall_length = temp7 if temp7!=.
	label var recall_length "Number of days of recall"

	gen recall_7 = (mode!=. & recall_length <=7 & recall_length!=.)
	label var recall_7 "Recalled in 7-day grid"
	gen recall_comp = (comp_days==1)
	label var recall_comp "Recalled in comprehensive recall"

	* FIXME this is problematic
	* br pid phase date dow attend mode recall_days comp_days recall_length recall_7 recall_comp if phase !=0 & phase !=3 & recall_7==0 & recall_comp==0 

/* [> Label variables <] */ 
	label var launchset "Start of phase 1 (grouped across stands)"
	label var batch "Batch (within a stand)"
	label var strata "Strata (same across stands)"
	label var phase "Phase of experiment"
	label var holiday "Holiday, no fieldwork"
	label var attend "Attend (daily)"
	label var attend_and_before8 "Attend by 8am (daily)"
	label var work "Work (daily) - imputed work randomly assigned"
	label var work_type "Work activity (daily)"
	label var earn "Wage earned (daily)"
	label var howfound_overall "How work was found"

	label var recall_days "Number of recall days"
	label var backfill_min_date "End date for comprehensive recall imputation"
	label var backfill_max_date "Start date for comprehensive recall imputation"
	label var comp_days "Imputation done using comprehensive recall data"

	label var daycount "Days since the beginning of this phase"

/* [> Clean up variables <] */ 
	drop late_announcement_flag
	rename late_announcement_flag2 late_announcement_flag
	label var late_announcement_flag "Late announcement at start of Phase 1"
	label var p2_announced_late2 "Late announcement at end of Phase 1"
	label var work1 "Work (daily) - imputed work as means instead of random assignment"

	bys pid: ereplace dropout = max(dropout)
	label var dropout "Refused to participate further"

	foreach x of varlist bs_sum* bs_avg_wage {
		bys pid: ereplace `x' = max(`x')
	}

	bys pid (date): gen daycountinstudy = _n	
	label var daycountinstudy "Days since beginning of experiment"
		replace daycountinstudy=. if phase==3

	* Dropping irrelevant variables 
	drop arrival_time_hours_15 arrival_time_hours_60 temp* _merge

/* [> Fix launchset <] */
	bys pid: egen temp = max(launchset)
	drop launchset

	* check that this fixes the issue - compare to spreadsheet 
	preserve
	use "./07. Data/3. Main Study 3.0/04. Operation/launch_prefill_pidwise_2022.dta", clear
		keep pid launchset 
		rename launchset ls1
		tempfile launchset 
		save `launchset', replace
	restore
	
	merge m:1 pid using `launchset'
	keep if _merge==3
	corr temp ls1 
		* 1
	drop ls1 
	rename temp launchset 

/* [> Fix batch <] */
	bys stand launchset: gen temp = _n==1
	bys stand: replace temp = sum(temp)
	rename batch batch_orig
	label var batch_orig "Batch (within stand) - original"
	rename temp batch 
	label var batch "Batch (within stand)"

/* [> Add notes <] */ 
	gen datanotes = ""
	replace datanotes = "Attend recoded as . due to late announcement" if date <= a_date & modified_launchset_flag == 0 & late_announcement_flag == 1 & phase==1 

/* [> Save final dataset <] */ 
	order stand pid treatment strata launchset batch phase week_in week_in_bs_p1_p2_p3 calendar_week date dow daycountinstudy holiday attend attend_adj attend_nadj attend_and_before8 attend_and_before8_adj attend_and_before8_nadj work1 work work_adj work_nadj work1_adj work1_nadj multiday_job_inc found_at_stand2 found_at_stand2_adj found_at_stand2_nadj found_not_at_stand2 found_not_at_stand2_adj found_not_at_stand2_nadj missing_work_data missing_work_data_comp comp_days work_type earn earn_adj earn_nadj howfound_overall after_event_invite_combined_p1 mode work_recall_mode dropout inf_dropout_3_p2 late_announcement_flag p2_announced_late2 bs_sum_attend bs_sum_work bs_sum_wage bs_dem_stand_yrs
	sort stand pid date 
 	save "$datadir/Analysis Prep/02. Output/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta", replace

