************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Replicate the main paper analysis using HW's new dataset
* 	Author:				HW 
* 	Last modified:		2026-Apr-15 (HW)
************************************************************
************************************************************


**********************
**# Define Variables
**********************

	* Generate baseline covariates for original dataset. New datatsets have these variables already.
	cap program drop gen_bl_cov
	program define gen_bl_cov
		preserve

			cap drop bl_attend bl_earn miss_bl_earn bl_modalwage

			keep if phase == 0

			egen temp = mean(attend), by(pid)
			egen bl_attend = max(temp), by(pid)
			drop temp

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

			keep pid bl_attend bl_earn miss_bl_earn bl_modalwage
			duplicates drop pid, force

			tempfile bl_cov
			save `bl_cov', replace

		restore

		merge m:1 pid using `bl_cov', update replace keep(1 2 3 4 5) nogen


	end



***********************************
**# Table 1: Labor Supply Effects
***********************************

	* Note from HW: sample size here is 1572 and not 1575 because 3 PIDs got late announcements in week 2, so week 1 data is missing

	use "$main_data" , clear
	lab var work1_nadj	"Work, Mean Impute"
	lab var work_nadj	"Work, Rand Impute"

	/*
	LC fix holidays issue 
	<FIXME> this should be somewhere else (macros?)
	*/

	/*
	LC fix original code:
	1. add missing when creating temp2 --> if all work reliable missing, it was set to 0 rather than missing2
		(see difference with temp3)
	2. use recall_lag rather than recall_length --> recall length is sparse
		<FIXME> I don't actually know how recall_length is created
		--> it comes from "/02. Cleaning Data/Analysis Prep/01. Code/02_bs_phase1_phase2_makevar_weekly_hw.do"
	*/
	if "$data_version" == "original" {

		egen temp = min(work_recall_mode), by(pid phase week_in)
		gen work_recall_mode_any1 = (temp==1)
		drop temp
	* correcting recall_lag rather than recall_length
		gen temp1 = (recall_lag<=7) /* will=1 if recall < 7 days ago & work not missing */
		egen grid_recall_anyinwk = max(temp1), by(pid phase week_in)
		drop temp*
		* LC correcing temp 2!! and correcting recall_lag rather than recall_length
		gen temp1 = work1 if recall_lag<=7 & work_recall_mode==1
		egen temp2 = total(temp1) if grid_recall_anyinwk==1 & work_recall_mode_any1==1, by(pid phase week_in) missing
		// add temp3 to see the difference with correct version
		egen temp3 = total(temp1) if grid_recall_anyinwk==1 & work_recall_mode_any1==1, by(pid phase week_in)
		egen work1_wkly2 = max(temp2), by(pid phase week_in)
		drop temp*

	}
	
	/*
		Reminder -- work data definitions
			- work_orig: data from 7-day recall only
			- work1: includes work data imputed as means
			- work: includes work data randomly assigned to comprehensive recall days
		Reminder -- work source definitions
			- recall_reliable: recall comes from 7-day recall grid (i.e. no comp recall) conducted in person
			- work_source_inperson: recall comes from either 7-day recall grid or comprehensive, conducted in person
	*/
	
	
	
	if "$data_version" == "new" {
		cap drop work1_wkly2
		cap drop temp1
	* V1: only use work_orig (in person recall from 7-day grid)
// 		gen  temp1 = work_orig if recall_reliable == 1
	* V2: use also comp_recall, in person only, mean imputation
		gen  temp1 = work1 if work_source_inperson == 1
	* V3: use also comp_recall, in person only, random imputation
// 		gen  temp1 = work if work_source_inperson == 1
		
		
		egen temp2 = total(temp1) , by(pid phase week_in) missing // aggregate at weekly level
		egen work1_wkly2 = max(temp2), by(pid phase week_in)
			* Proporated version, leave it for now
			//egen temp3 = count(work1), by(pid phase week_in)
			//gen work1_wkly2_adj = work1_wkly2*7/temp3
		drop temp*

	}
	
	reg work1_wkly2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	reg work1_wkly2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	
	cap drop ls
	gen ls = .
	replace ls = attend
	
	* v1 : any work data
		//replace ls = 1 if work_orig == 1 & attend == 0
	* v2 : replace only if work data is from reliable recall
// 	replace ls = 1 if work_orig == 1 & attend == 0 & recall_reliable == 1
	* v3 : replace comp_recall
	replace ls = 1 if work == 1 & attend == 0 & work_source_inperson == 1
	
	cap drop ls_week
	egen ls_week = total(ls), by(pid phase week_in) missing
	
	reg ls_week treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	
	* Gen baseline covariates for original dataset
	gen_bl_cov
	
	eststo clear 
	eststo a1: reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum attend_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)
  

	eststo b1: reg attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum attend_and_before8_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)
	
  
	eststo a2: reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	unique pid if e(sample)
	sum attend_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)


	eststo b2: reg attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	sum attend_and_before8_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)


	eststo d2: reg work1_wkly2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	unique pid if e(sample)
	unique pid week_in if e(sample)
	
	*** Unique PID's in sample
	preserve
		keep if e(sample)
		contract pid

		rename _freq count_week_in
		
		if "$data_version" == "original" {
				save "${replication_dir}/data/discrepancy_check/out/pid_missing_phase2_original.dta",replace
		}
		else if "$data_version_new" == "prioritize_date" {
			save "${replication_dir}/data/discrepancy_check/out/pid_missing_phase2_new_date.dta",replace
		}
		else {
			save "${replication_dir}/data/discrepancy_check/out/pid_missing_phase2_new_inperson.dta",replace
		}
		unique pid
	restore
	
	*** Unique PID-week_in in sample
	preserve
		keep if e(sample)
		bys pid: gen week_in_count = _N
// 		keep if week_in_count < 7
		keep pid stand week_in week_in_count
		sort stand pid week_in
		if "$data_version" == "original" {
				save "${replication_dir}/data/discrepancy_check/out/pid_missing_work_phase2_original.dta",replace
		}
		else if "$data_version_new" == "prioritize_date" {
			save "${replication_dir}/data/discrepancy_check/out/pid_missing_work_phase2_new_date.dta",replace
		}
		else {
			save "${replication_dir}/data/discrepancy_check/out/pid_missing_work_phase2_new_inperson.dta",replace
		}
		unique pid
	restore
	
	
	sum work1_wkly2 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)
	
	** pid in:
		* - master 	(_merge == 1): new data (in person)
		* - using 	(_merge == 1): original data
		* - both 	(_merge == 3):
	use "${replication_dir}/data/discrepancy_check/out/pid_missing_phase2_new_inperson.dta", clear
	merge 1:1 pid using  "${replication_dir}/data/discrepancy_check/out/pid_missing_phase2_original.dta"

	list pid if _merge == 1, clean noobs
	/*
	The following PID's are in new data, but not in old data
	604   --> 6 weeks
    1511  --> 2 weeks
    6826  --> 2 weeks
    6889  --> 1 weeks
	*/

	
	** pid-week_in in: 
	* - master only	(_merge == 1): new data (in person)
	* - using only	(_merge == 2): original data
	* - both 	(_merge == 3):
	use "${replication_dir}/data/discrepancy_check/out/pid_missing_work_phase2_new_inperson.dta", clear
	merge 1:1 pid week_in using "${replication_dir}/data/discrepancy_check/out/pid_missing_work_phase2_original.dta"

	unique pid if _merge == 1
		// Number of unique values of pid is  15
		// Number of records is  29
	unique pid if _merge == 1 & !inlist(pid, ${miss_pid})
		// Number of unique values of pid is  11
		// Number of records is  18

	unique pid if _merge == 2
		// Number of unique values of pid is  5
		// Number of records is  5
		list pid week_in if _merge == 2, clean noobs
		/*
			pid   week_in  
			 315         3  
			1379         4  
			1645         4  
			1744         3  
			7714         3
		*/
	unique pid if _merge == 3
		// Number of unique values of pid is  201
		// Number of records is  1352

	gen pid_only_in_new = inlist(pid, ${miss_pid})
	
	gen pid_week_only_in_new 	= _merge == 1
	gen pid_week_only_in_old 	= _merge == 2
	gen pid_week_in_both 		= _merge == 3
		
	save "${replication_dir}/data/discrepancy_check/out/pid_week_discrepancy_accounting.dta", replace
	
	
	*** Compare day by day in phase 2
	* Save old dataset with prefill OLD 
			preserve 
				/* <FIXME> what's work1?
					gen work1 = work 
					replace work1 = work_imputed_mean if mi(work) & !mi(work_imputed_mean)
					la var work1 "Work; imputed work as means instead of random assignment"
				*/
				
				use "$final/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta" , clear	
				keep stand pid date week_in phase attend work work1 work_recall_mode ///
				recall_length comp_days comp_worked incomplete_comp_recall ///
				backfill_min_date backfill_max_date work_imputed comp_recall_filt ///
				comprehensive_recall recall_lag attend_nadj holiday
				drop if mi(date)
				
				keep if phase == 2
				local ll pid date
			
				egen temp = min(work_recall_mode), by(pid phase week_in) // = 1 if there's been any in person recall during that week
				gen work_recall_mode_any1 = (temp==1) // indicator for whether any in person recall occurred
				drop temp
			
			
				gen temp1 = (recall_length<=7) /* will=1 if recall <= 7 days ago & work not missing */
				egen grid_recall_anyinwk = max(temp1), by(pid phase week_in)
				drop temp*
				
				gen temp1 = work1 if recall_length<=7 & work_recall_mode==1
				egen temp2 = total(temp1) if grid_recall_anyinwk==1 & work_recall_mode_any1==1, by(pid phase week_in)
				egen work1_wkly2 = max(temp2), by(pid phase week_in)
				drop temp*
			
				* Adding the OLD prefix to variables, except pid date
				foreach v of varlist * {
					if !`: list v in ll' {
						rename `v' old_`v'
					}
				}
				save "${replication_dir}/data/discrepancy_check/out/phase2_old_for_diag.dta", replace
			restore
	
	use "$final/final_data_prioritize_in_person.dta", clear
	keep stand pid date week_in phase attend mode attend work work_orig ///
	recall_reliable recall_source dow attend_nadj holiday
	keep if phase == 2
		* Gen work var
	gen  temp1 = work_orig if recall_reliable == 1
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen work1_wkly2 = max(temp2), by(pid phase week_in)
	drop temp*
	
	merge 1:1 pid date using "${replication_dir}/data/discrepancy_check/out/phase2_old_for_diag.dta"
	
	order stand pid date dow week_in recall_source work1_wkly2 old_work1_wkly2 work work_orig old_work old_work1

	list pid date stand if _merge == 1, clean noobs
	/*
	1520   26nov2022   15. Velachery  
    1554   26nov2022   15. Velachery  
    1561   26nov2022   15. Velachery  
    1562   26nov2022   15. Velachery  
    1580   26nov2022   15. Velachery  
	*/
	drop _merge
	
	* 1. Recall length not binding in OLD definition
	tab old_recall_length, m
	
	
				gen temp1 = old_work1 if old_recall_length<=7 & old_work_recall_mode==1
				egen temp2 = total(temp1) if old_grid_recall_anyinwk==1 & old_work_recall_mode_any1==1, by(pid phase week_in)

	