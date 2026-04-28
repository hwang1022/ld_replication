/*
This table estimates the short-term labor supply response to income payouts among control group workers.

* **Sample:** Restricted strictly to control group participants (`treatment == 0`) during Phase 1.
* **Dependent Variable:** Total weekly days worked. This is aggregated at the person-week level using only high-quality, in-person recall data (`work_source_inperson == 1`).
* **Specification:** A panel regression predicting weekly work days based on the previous week's received payout (`l.payout`). The model incorporates fixed effects, with standard errors clustered at the individual worker level (`pid`).

Main table structure modeled after Table 1 in code/analysis/ld_replication.do ("Table 1: Labor Supply
Effects"). Earnings variable is `earn` (daily), summed to weekly totals and lagged one week.
*/

**********************
**# Setup
**********************

* INFO: Intended to run after 0.master.do (defines $main_data, $tables).
* For standalone use, set these globals manually.

global db_dir "~/Dropbox"
global ld_dir 				"$db_dir/Labor Discipline"
global replication_dir 		"$ld_dir/07. Data/3. Main Study 3.0/replication"

// WARNING: This corresponds to Simon's local setup. Comment out / delete line below when running
global replication_dir "/Users/st2246/Work/labor/new_asks/replication"
// WARNING: This corresponds to Simon's local setup. Please point to correct data or remove merging logic 
// if incentive payment data is incorporated into the main data
global incentives_data      "/Users/st2246/Work/labor/new_asks/replication/code/analysis/simon/extra_data/phase1_incentive_survey_vs_record_makevar.dta"
global incentives_data      "${replication_dir}/replication/code/analysis/simon/extra_data/phase1_incentive_survey_vs_record_makevar.dta"

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

**********************
**# Load Data
**********************

use "$main_data", clear

**********************
**# Restrict Sample
**********************

keep if treatment == 0 & phase == 1


***********************
**# TEMPORARY -> Remove once incentive data is merged in
***********************

// merge m:1 pid week_in using "$incentives_data", gen(incentive_merge)
merge m:1 pid week_in using "${replication_dir}/code/analysis/simon/extra_data/phase1_incentive_survey_vs_record_makevar.dta", gen(incentive_merge)
  // Drop people in incentive data but not in main data (likely treated people we filtered out)
  drop if incentive_merge == 2
  drop incentive_merge 

**********************
**# Collapse to Person-Week Panel
**********************

gen work_reliable = work1
replace work_reliable = . if work_source_inperson != 1

collapse (firstnm) work1_nadj attend_nadj amount_payed amount_allotted (sum) work_reliable , by(pid stand calendar_week strata week_in)

**********************
**# Panel Setup
**********************

* INFO: week_in is the within-phase week counter (1, 2, ...). xtset requires
*       a numeric, gap-free time variable within each panel unit.
xtset pid week_in

//local controls attend_week bl_attend bl_earn miss_bl_earn bl_modalwage
local controls i.stand i.strata i.week_in i.calendar_week
// INFO: Missing baseline controls
cap drop amount_payed_L1
bys pid (week_in): gen amount_payed_L1 = amount_payed[_n-1]
cap drop amount_allotted_L1
bys pid (week_in): gen amount_allotted_L1 = amount_allotted[_n-1]

ivreg2 work_reliable (amount_payed_L1 = amount_allotted_L1) i.stand i.calendar_week, cluster(pid) first
ivreg2 work_reliable (amount_payed_L1 = amount_allotted_L1) i.stand i.calendar_week if week_in == 2, cluster(pid) first

xtreg work_reliable amount_allotted_L1 i.calendar_week , fe
xtivreg work_reliable (amount_payed_L1 = amount_allotted_L1) i.calendar_week , fe
xtivreg work_reliable (amount_payed_L1 = amount_allotted_L1) , fe first

cap drop allotted_above_median
qui su amount_allotted_L1, d
di r(p50)
gen allotted_above_median = amount_allotted_L1>r(p50) if !mi(amount_allotted_L1)
gen allotted_above_mean = amount_allotted_L1>r(mean) if !mi(amount_allotted_L1)
qui su amount_payed_L1, d
di r(p50)
gen paid_above_median = amount_payed_L1>r(p50) if !mi(amount_payed_L1)

xtivreg work_reliable (paid_above_median = allotted_above_median) i.calendar_week , fe first
xtreg work_reliable allotted_above_median i.calendar_week , fe
xtreg work_reliable allotted_above_mean i.calendar_week , fe

reg work_reliable allotted_above_median i.calendar_week i.stand, cluster(pid)

reg work_reliable allotted_above_mean i.calendar_week i.stand, cluster(pid)
ivreg2 work_reliable (paid_above_median = allotted_above_median) i.calendar_week i.stand, cluster(pid) first

**********************
**# Regression: Labor Supply Response to Lagged Payout
**********************

eststo clear

local outcomes attend_nadj work1_nadj work_reliable
local i 1
* INFO: FEs: pid (absorbed by xtreg,fe) + calendar_week to absorb common time shocks.
*       stand and strata are absorbed by pid FE (time-invariant), so omitted.

foreach outcome in `outcomes' {
    eststo m`i': reg `outcome' l.amount_payed `controls',  ///
        vce(cluster pid)
    sum `outcome' if e(sample)
    estadd scalar y_mean = r(mean)
    sum amount_payed if e(sample)
    estadd scalar amount_payed = r(mean)

    local i = `i' + 1
}




**********************
**# Export
**********************

esttab m1 m2 m3 ///
    using "$tables/earnings_impact_phase1_control.tex", ///
    replace keep(L.amount_payed) ///
    cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean amount_payed N, ///
        labels("Depedent Variable Mean" "Mean Weekly Payment" "N: worker-weeks")) ///
    collabels(none) nonotes nonumbers ///
    mtitles("Attend" "Days Worked" "Days Worked (in-person survey)") ///
    nostar booktabs label
