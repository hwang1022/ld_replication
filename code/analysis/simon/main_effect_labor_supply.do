
/*

Goal of this do-file:
- Estimate the main treatment effect on labor supply instead of attendance
- Approach
  - Find current main table that does treatment effect on attendance (see 0.master.do)
  - Generate labor supply variable (starter: )
      gen temp = attend
      replace temp = work1 if work1 > 0 & !mi(work1) & attend == 0 & work_source_inperson == 1
      egen ls_week3 = total(temp), by(pid phase week_in) missing
  - Replicate main table but using new variables

Main table found in: code/analysis/ld_replication.do, section "**# Table 1: Labor Supply Effects"
  - Outputs: $tables/com_weekly_attend_b8_attend_work1_frag2_rephw.tex
  - Spec: OLS of attend_nadj on treatment, with controls
    attend_week + bl_attend + bl_earn + miss_bl_earn + bl_modalwage +
    i.stand + i.strata + i.week_in + i.calendar_week FEs, SEs clustered by pid
  - Columns: Phase 1 (Attend), Phase 2 (Attend, Work)

*/

**********************
**# Setup
**********************

* INFO: This file is intended to run after 0.master.do, which defines $main_data,
* $tables, and the gen_bl_cov program. For standalone use, set these globals manually.

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


global main_data "$new_main_prioritize_date"
global output "$replication_dir/output/prioritize_date"
global tables "$output/tables"


**********************
**# Load Data
**********************

use "$main_data", clear

**********************
**# Generate Labor Supply Variable
**********************

* Daily labor supply: stand attendance, OR work1 days when not at stand (in-person source only)
* This captures total labor supply including informal/alternative employment on non-attendance days
gen temp = attend
replace temp = work1 if attend == 0 & !mi(work1) &  work_source_inperson == 1

egen ls_week = total(temp), by(pid phase week_in) missing
drop temp

lab var ls_week "Labor Supply (Days)"

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
**# Table: Main Treatment Effect on Labor Supply
**********************

* Mirrors Table 1 structure from ld_replication.do
* Substitutes: attend_nadj -> ls_week_nadj

eststo clear

* Phase 1: Labor Supply
eststo a1: reg ls_week treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
    i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum ls_week if treatment==0 & e(sample)
estadd scalar y_mean = r(mean)

* Phase 2: Labor Supply
eststo a2: reg ls_week treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
    i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum ls_week if treatment==0 & e(sample)
estadd scalar y_mean = r(mean)

esttab a1 a2 ///
    using "$tables/ls_main_effect.tex", ///
    replace keep(treatment) ///
    cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) ///
    collabels(none) nonotes nonumbers ///
    mtitles("Phase 1" "Phase 2") ///
    nostar booktabs label
