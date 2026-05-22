************************************************************
* Appendix Table A.3: Consumption Habit Formation
* Source: verification.md Table A.3 and
* hao_working_folder/oct_25_presentation/5_consumption_originaldata.do
* lines 67-80.
************************************************************

clear all
set more off

global data "`c(pwd)'/data"
local analysis_main "$data/final/analysis_main.dta"

local outdir "$data/output/tables"
local outfile "`outdir'/iv_com_weekly_attend_nop1attendance_originaldata.tex"
local alias "`outdir'/table_a_iii.tex"

capture mkdir "$data/output"
capture mkdir "`outdir'"

use `analysis_main', clear

preserve
	keep if treatment == 0
	collapse (mean) amount_payed_mean=amount_payed amount_allotted_mean=amount_allotted, by(pid)
	foreach var of varlist amount_payed_mean amount_allotted_mean {
		replace `var' = 0 if mi(`var')
		egen median_`var' = median(`var')
		gen higher_`var' = (`var' > median_`var') if !mi(`var')
		drop median_`var'
	}
	keep pid higher_amount_payed_mean higher_amount_allotted_mean amount_payed_mean amount_allotted_mean
	tempfile control_payment_higher_lower
	save `control_payment_higher_lower', replace
restore

merge m:1 pid using `control_payment_higher_lower', keep(1 2 3) nogen
keep if treatment == 0

lab var higher_amount_payed_mean "Higher Incentive Paid"

eststo clear
foreach i of varlist attend_nadj attend_and_before8_nadj {
	eststo: ivregress 2sls `i' attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
		i.stand i.strata i.week_in i.calendar_week ///
		(higher_amount_payed_mean = higher_amount_allotted_mean) if phase == 2

	summarize `i' if e(sample) & higher_amount_allotted_mean == 0
	estadd scalar control_mean = r(mean)
}

esttab using "`outfile'", ///
	replace keep(higher_amount_payed_mean) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
	stats(control_mean N, fmt(3 a0 a0) labels("Control Mean" "N: worker-weeks")) collabels(none) ///
	nonotes nonumbers mtitles("Attend" "By 8" "Work" "Earn" "Earn\$\mid\$Work") nostar booktabs label

copy "`outfile'" "`alias'", replace

eststo clear
