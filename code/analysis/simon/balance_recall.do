/*
This table evaluates employment data attrition and recall quality balance between the treatment and control groups across study phases. Because self-reported labor supply relies on surveys with varying degrees of reliability, the table categorizes observation days to check for differential attrition:

* **Column 1: Attendance Days (Benchmark):** Directly observed stand attendance. This serves as a mechanically balanced, non-attrited baseline for comparison.
* **Column 2: Reliable Work Days (`work_source_inperson == 1`):** High-quality data collected via in-person surveys (combining both 7-day detailed grids and comprehensive recalls).
* **Column 3: Unreliable Work Days (`work_source_inperson == 0`):** Lower-quality data collected via phone surveys.
* **Column 4: Missing Days:** Unrecorded days where data is entirely absent, either because the participant formally dropped out of the study or could not be reached for a follow-up survey.

See data/discrepancy_check/diag_daily_recall_lag_check.do as a starting point.

Main table modeled after Table 1 in code/analysis/ld_replication.do ("Table 1: Labor Supply Effects"),
which outputs $tables/com_weekly_attend_b8_attend_work1_frag2_rephw.tex. That table regresses
attend_nadj on treatment with stand/strata/week_in/calendar_week FEs and baseline covariates,
clustered SEs by pid. This file replicates that structure substituting the four day-category
outcomes, run separately for Phase 1 and Phase 2.
*/

**********************
**# Setup
**********************

* INFO: Intended to run after 0.master.do (defines $main_data, $tables, gen_bl_cov).
* For standalone use, set these globals manually.

global db_dir "~/Dropbox"
global ld_dir 				"$db_dir/Labor Discipline"
global replication_dir 		"$ld_dir/07. Data/3. Main Study 3.0/replication"

// WARNING: This corresponds to Simon's local setup. Comment out / delete line below when running
global replication_dir "/Users/st2246/Work/labor/new_asks/replication"

global code 				"$replication_dir/code"
global raw 					"$replication_dir/data/raw"
global temp 				"$replication_dir/data/temp"
global final 				"$replication_dir/data/final"
global external 			"$replication_dir/data/external"

* The Original Dataset, last edited in July 2024
global original_main 				"$final/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta"  

* The New Dataset 
global new_main_prioritize_date 		"$final/final_data_prioritize_date.dta"
global new_main_prioritize_in_person 	"$final/final_data_prioritize_in_person.dta"


global main_data            "$new_main_prioritize_date"


global output "$replication_dir/output/prioritize_date"
global tables "$output/tables"

global dropout_pid "2107, 555, 547, 646, 689, 641, 1405, 1903, 1928, 2020, 1744, 1333"	 


**********************
**# Load Data
**********************

use "$main_data", clear



**********************
**# Generate Outcome Variables (daily -> weekly)
**********************

* INFO: attend is a daily 0/1 indicator of stand attendance (directly observed).
* INFO: work_source_inperson is a daily 0/1 flag; 1 = in-person survey, 0 = phone survey.
*       Assumed present in $main_data; derived in the new-data pipeline from recall_reliable / mode.
* INFO: A day is "missing" if neither attend==1 nor a work observation exists (i.e., no survey
*       reached the worker). Operationalized as: attend==0 & mi(work_source_inperson).


* Daily category indicators
gen     d_attend          = !missing(attend)
gen     d_reliable        = (work_source_inperson == 1) // source of work is reliable in-person survey
gen     d_unreliable      = (work_source_inperson == 0)
gen     d_either          = !missing(work_source_inperson) // either reliable or unreliable work data (i.e., any survey reached the worker)

// Figure days after "dropout"
preserve
    keep if phase <= 2 
    // Tag days where we have work date -> indicating we met you or have recall data
    gen date_data = date if !missing(work1)
    // Find the last such day for all people
    egen last_day = max(date_data), by(pid)
    // Tag all days AFTER your 'dropout day' (i.e. days after the last time we saw you)
    gen after_last_day = date > last_day
    // Tag as dropout_day for people who dropped (right now, only those in the list)
    gen dropout_day = after_last_day & missing(work1) & inlist(pid, $dropout_pid)

    keep pid date phase dropout_day after_last_day
    tempfile dropout_info
    save `dropout_info', replace
restore

// Merge in dropout days
merge 1:1 pid date using `dropout_info', nogen

gen d_formal_dropout = dropout_day
// Tag days where we have no work data and it's after your last day of work
gen d_missing_dropout = after_last_day & missing(work1)


* Weekly sums within pid-phase-week_in
foreach v in attend reliable unreliable either formal_dropout missing_dropout {
    egen wk_`v' = total(d_`v'), by(pid phase week_in) missing
}


lab var wk_attend           "Attendance Days"
lab var wk_reliable         "Reliable Work Days (in-person)"
lab var wk_unreliable       "Unreliable Work Days (phone)"
lab var wk_either           "Work Days (either source)"
lab var wk_formal_dropout   "Missing data due to formal dropout"
lab var wk_missing_dropout  "Missing data due to non-response"

**********************
**# Baseline Covariates
**********************

* Lifted from code/analysis/ld_replication.do lines 14-51
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

gen_bl_cov

**********************
**# Balance Table
**********************

local outcomes wk_attend wk_reliable wk_unreliable wk_either wk_missing_dropout
local controls attend_week bl_attend bl_earn miss_bl_earn bl_modalwage

eststo clear

foreach phase in 1 2 {
    foreach v of local outcomes {
        eststo `v'_p`phase': reg `v' treatment `controls' ///
            i.stand i.strata i.week_in i.calendar_week ///
            if phase == `phase', vce(cluster pid)
        sum `v' if treatment == 0 & e(sample)
        estadd scalar y_mean = r(mean)
    }
}

**********************
**# Export
**********************

* Phase 1
foreach phase in 1 2 {
    esttab wk_attend_p`phase' wk_reliable_p`phase' wk_unreliable_p`phase' wk_either_p`phase' wk_missing_dropout_p`phase'  ///
    using "$tables/balance_recall_phase`phase'.tex", ///
    replace keep(treatment) ///
    cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) ///
    collabels(none) nonotes nonumbers ///
    mtitles("Attendance Data" "Reliable Work Data" "Unreliable data" "Any work data" "Non-response") ///
    nostar booktabs label


}
