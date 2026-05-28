************************************************************
* Table I: Labor Supply Effects
* Source: verification.md Table 1 entry and
* replication/code/analysis/ld_replication.do Table 1 block.
************************************************************

clear all
set more off

if "$data" == "" {
	global data "`c(pwd)'/data"
}
if "$data_final" == "" {
	global data_final "${data}/final"
}
if "$data_temp" == "" {
	global data_temp "${data}/temp"
}
if "$output" == "" {
	global output "${data}/output"
}
local analysis_main "$data_final/analysis_main.dta"

local outdir "$output/tables"
capture mkdir "$output"
capture mkdir "`outdir'"

* table_code/data_processing.do creates analysis_main.dta with baseline
* covariates and work1_wkly2. This file keeps only the table estimation block.
use "`analysis_main'", clear

lab var work1_nadj "Work, Mean Impute"
lab var work_nadj  "Work, Rand Impute"

eststo clear
eststo a1: reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum attend_nadj if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo b1: reg attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum attend_and_before8_nadj if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a2: reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum attend_nadj if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo b2: reg attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum attend_and_before8_nadj if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo d2: reg work1_wkly2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum work1_wkly2 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

esttab b1 a1 b2 a2 d2 using "`outdir'/com_weekly_attend_b8_attend_work1_frag2_rephw.tex", ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes nonumbers mtitles("By 8" "Attend" "By 8" "Attend" "Work") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

esttab b1 a1 b2 a2 d2 using "`outdir'/table_a.tex", ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes nonumbers mtitles("By 8" "Attend" "By 8" "Attend" "Work") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
