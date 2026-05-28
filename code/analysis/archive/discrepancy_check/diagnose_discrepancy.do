/******************************************************************************
Diagnose discrepancy in the Phase-2 work1_wkly2 regression between two datasets

  ORIG : 05_bs_phase1_phase2_makevar_combined_daily_weekly.dta
  MOD  : final_data_prioritize_in_person.dta

Mirrors the unified recipe in replication/code/analysis/ld_replication.do:
  - gen_bl_cov (lines 14-51) regenerates bl_attend, bl_earn, miss_bl_earn,
    bl_modalwage from phase==0 rows of each dataset.
  - work1_wkly2 per dataset (lines 170-194).

Outputs overwritten under ./out/ with _stata.csv suffix.
******************************************************************************/

	version 18.0
	clear all
	set more off

	local base   "/Users/lc2295/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0"
	local orig   "`base'/replication/data/final/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta"
	local mod    "`base'/replication/data/final/final_data_prioritize_in_person.dta"
	local out    "`base'/replication/data/temp/discrepancy_check/out"
	cap mkdir "`out'"

	* gen_bl_cov program, lifted from ld_replication.do lines 14-51
	cap program drop gen_bl_cov
	program define gen_bl_cov
		preserve
			cap drop bl_attend bl_earn miss_bl_earn bl_modalwage
			keep if phase == 0

			egen temp = mean(attend), by(pid)
			egen bl_attend = max(temp), by(pid)
			drop temp

			egen temp = mean(earn), by(pid)
			egen bl_earn = max(temp), by(pid)
			gen miss_bl_earn = (bl_earn==.)
			replace bl_earn = 0 if miss_bl_earn==1
			drop temp

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

	tempfile mod_wk orig_wk

*-----------------------------------------------------------------------------*
* MOD: build bl_*, then work1_wkly2 (canonical + via work1), then collapse
*-----------------------------------------------------------------------------*
	use pid date phase week_in dow holiday stand strata treatment calendar_week ///
	    attend_week attend_nadj attend earn work1 work1_week work_orig            ///
	    recall_reliable                                                           ///
	    using "`mod'", clear
	gen_bl_cov

	keep if phase == 2 | phase == 0
	* We needed phase 0 only to build bl_*; now drop non-p2 rows for regression
	keep if phase == 2

	* canonical (matches ld_replication.do:188-192)
	gen  temp1 = work_orig if recall_reliable == 1
	egen temp2 = total(temp1), by(pid phase week_in) missing
	egen work1_wkly2 = max(temp2), by(pid phase week_in)
	drop temp*

	* secondary: naive sum(work1) for cross-check
	egen temp2 = total(work1), by(pid phase week_in) missing
	egen work1_wkly2_via_work1 = max(temp2), by(pid phase week_in)
	drop temp*

	* e(sample) approximation
	gen in_sample = !mi(work1_wkly2) & !mi(treatment) & !mi(attend_week) &       ///
	                !mi(bl_attend) & !mi(bl_earn) & !mi(miss_bl_earn) &          ///
	                !mi(bl_modalwage) & !mi(stand) & !mi(strata) &               ///
	                !mi(week_in) & !mi(calendar_week)

	collapse (firstnm) work1_wkly2 work1_wkly2_via_work1 work1_week              ///
	         (max) in_sample_week=in_sample                                      ///
	         (count) n_days=date                                                 ///
	         (sum) n_days_in_sample=in_sample, by(pid week_in)

	foreach v of varlist work1_wkly2 work1_wkly2_via_work1 work1_week            ///
	                     in_sample_week n_days n_days_in_sample {
		rename `v' `v'_mod
	}
	save `mod_wk'

*-----------------------------------------------------------------------------*
* ORIG: build bl_*, then work1_wkly2 per the original branch, then collapse
*-----------------------------------------------------------------------------*
	use pid date phase week_in dow holiday stand strata treatment calendar_week ///
	    attend_week attend_nadj attend earn work1 work1_week recall_length        ///
	    work_recall_mode                                                          ///
	    using "`orig'", clear
	gen_bl_cov

	keep if phase == 2

	* canonical (matches ld_replication.do:172-183)
	egen temp = min(work_recall_mode), by(pid phase week_in)
	gen work_recall_mode_any1 = (temp==1)
	drop temp

	gen temp1 = (recall_length<=7)
	egen grid_recall_anyinwk = max(temp1), by(pid phase week_in)
	drop temp*

	gen temp1 = work1 if recall_length<=7 & work_recall_mode==1
	egen temp2 = total(temp1) if grid_recall_anyinwk==1 & work_recall_mode_any1==1, ///
		by(pid phase week_in)
	egen work1_wkly2 = max(temp2), by(pid phase week_in)
	drop temp*

	* secondary: naive sum(work1)
	egen temp2 = total(work1), by(pid phase week_in) missing
	egen work1_wkly2_via_work1 = max(temp2), by(pid phase week_in)
	drop temp*

	gen in_sample = !mi(work1_wkly2) & !mi(treatment) & !mi(attend_week) &       ///
	                !mi(bl_attend) & !mi(bl_earn) & !mi(miss_bl_earn) &          ///
	                !mi(bl_modalwage) & !mi(stand) & !mi(strata) &               ///
	                !mi(week_in) & !mi(calendar_week)

	collapse (firstnm) work1_wkly2 work1_wkly2_via_work1 work1_week              ///
	         (max) in_sample_week=in_sample                                      ///
	         (count) n_days=date                                                 ///
	         (sum) n_days_in_sample=in_sample, by(pid week_in)

	foreach v of varlist work1_wkly2 work1_wkly2_via_work1 work1_week            ///
	                     in_sample_week n_days n_days_in_sample {
		rename `v' `v'_orig
	}
	save `orig_wk'

*-----------------------------------------------------------------------------*
* Merge and flag discrepancies
*-----------------------------------------------------------------------------*
	use `mod_wk', clear
	merge 1:1 pid week_in using `orig_wk', keep(1 2 3)
	gen only_in_mod  = _merge == 1
	gen only_in_orig = _merge == 2
	drop _merge

	gen diff_outcome = (work1_wkly2_mod != work1_wkly2_orig) &                    ///
	                   !(mi(work1_wkly2_mod) & mi(work1_wkly2_orig))
	gen diff_outcome_via_work1 =                                                  ///
	    (work1_wkly2_via_work1_mod != work1_wkly2_via_work1_orig) &               ///
	    !(mi(work1_wkly2_via_work1_mod) & mi(work1_wkly2_via_work1_orig))
	gen diff_sample = in_sample_week_mod != in_sample_week_orig

	gen diff_value = cond(mi(work1_wkly2_mod), 0, work1_wkly2_mod) -              ///
	                 cond(mi(work1_wkly2_orig), 0, work1_wkly2_orig)

*-----------------------------------------------------------------------------*
* Outputs
*-----------------------------------------------------------------------------*
	preserve
		keep if diff_outcome | diff_sample | only_in_mod | only_in_orig
		order pid week_in diff_outcome diff_outcome_via_work1 diff_sample          ///
		      only_in_mod only_in_orig work1_wkly2_mod work1_wkly2_orig            ///
		      diff_value work1_wkly2_via_work1_mod work1_wkly2_via_work1_orig      ///
		      work1_week_mod work1_week_orig in_sample_week_mod in_sample_week_orig ///
		      n_days_mod n_days_orig n_days_in_sample_mod n_days_in_sample_orig
		gsort -diff_sample -diff_outcome -diff_value
		export delimited using "`out'/pidweek_discrepancies_stata.csv", replace
	restore

	count
	local n_total = r(N)
	count if diff_outcome
	local n_outcome = r(N)
	count if diff_outcome_via_work1
	local n_outcome_via = r(N)
	count if diff_sample
	local n_sample = r(N)
	count if only_in_mod
	local n_only_mod = r(N)
	count if only_in_orig
	local n_only_orig = r(N)
	count if in_sample_week_mod == 1
	local n_insample_mod = r(N)
	count if in_sample_week_orig == 1
	local n_insample_orig = r(N)

	clear
	set obs 8
	gen metric = ""
	gen value  = .
	replace metric = "total pid-week_in cells"                 in 1
	replace value  = `n_total'                                 in 1
	replace metric = "only in MOD"                             in 2
	replace value  = `n_only_mod'                              in 2
	replace metric = "only in ORIG"                            in 3
	replace value  = `n_only_orig'                             in 3
	replace metric = "diff_outcome (canonical)"                in 4
	replace value  = `n_outcome'                               in 4
	replace metric = "diff_outcome (naive sum(work1))"         in 5
	replace value  = `n_outcome_via'                           in 5
	replace metric = "diff_sample (e(sample) membership)"      in 6
	replace value  = `n_sample'                                in 6
	replace metric = "MOD  worker-weeks in e(sample)"          in 7
	replace value  = `n_insample_mod'                          in 7
	replace metric = "ORIG worker-weeks in e(sample)"          in 8
	replace value  = `n_insample_orig'                         in 8

	export delimited using "`out'/sample_diff_summary_stata.csv", replace

	di as result "Done. Outputs in `out'"
