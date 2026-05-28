************************************************************
* Appendix Table A.8: Shock Analysis - Robustness (column 4)
* Source: verification.md Table A.8 and
* hao_working_folder/oct_25_presentation/3_shocks_spec_table_originaldata.do
* lines 1449-1602.
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
local shocks_original_25 "$data_temp/shocks_dataset_originaldata_25.dta"
local shocks_altspec "$data_temp/shocks_dataset_originaldata_25_altspec.dta"
local shocks_original_20 "$data_temp/shocks_dataset_originaldata_20.dta"
local shocks_original_30 "$data_temp/shocks_dataset_originaldata_30.dta"
local shocks_baseline_25 "$data_temp/shocks_dataset_originaldata_25_baseline.dta"
local shocks_rolling_4 "$data_temp/shocks_dataset_originaldata_rolling_4.dta"
local shocks_rolling_7 "$data_temp/shocks_dataset_originaldata_rolling_7.dta"

local outdir "$output/tables"
local outfile "`outdir'/shocks_analysis_col_4_robustness_originaldata.tex"
local alias "`outdir'/table_o.tex"

capture mkdir "$output"
capture mkdir "`outdir'"

cap program drop normalize_attend_week
program define normalize_attend_week
	tempvar attend_week_min
	bysort pid calendar_week: egen `attend_week_min' = min(attend_week)
	replace attend_week = `attend_week_min'
end

cap program drop run_col_4
program define run_col_4
	reg attend_nadj treat treatXpost_attend_j post_attend_j attend_week bl_attend bl_earn ///
		miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata ///
		i.calendar_week if phase == 2 & firstwk_attend_j == 0, vce(cluster standid)
	boottest {treat} {treatXpost_attend_j} {treatXweek_in_dm}, ///
		seed(123) reps(2048) boottype(wild) nograph

	matrix pval = J(1,3,.)
	matrix colnames pval = treat treatXpost_attend_j treatXweek_in_dm
	matrix pval[1,1] = r(p_1)
	matrix pval[1,2] = r(p_2)
	matrix pval[1,3] = r(p_3)

	eststo: reg attend_nadj treat treatXpost_attend_j post_attend_j attend_week bl_attend ///
		bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid ///
		i.strata i.calendar_week if phase == 2 & firstwk_attend_j == 0, vce(cluster pid)
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval
end

eststo clear

* Main Specification
use "`shocks_original_25'", clear
normalize_attend_week
keep if phase == 2
keep if dow == 2
run_col_4

* Alternative Prediction Spec
use "`shocks_altspec'", clear
normalize_attend_week
keep if phase == 2
keep if dow == 2
run_col_4

* P20
use "`shocks_original_20'", clear
normalize_attend_week
keep if phase == 2
keep if dow == 2
run_col_4

* P30
use "`shocks_original_30'", clear
normalize_attend_week
keep if phase == 2
keep if dow == 2
run_col_4

* Baseline
use "`shocks_baseline_25'", clear
normalize_attend_week
keep if phase == 2
keep if dow == 2
run_col_4

* 4-Day Rolling Average
use "`shocks_rolling_4'", clear
normalize_attend_week
keep if phase == 2
keep if dow == 2
run_col_4

* 7-Day Rolling Average
use "`shocks_rolling_7'", clear
normalize_attend_week
keep if phase == 2
keep if dow == 2
run_col_4

label var treat "Treat"
label var treatXpost_attend_j "Treat $\times$ Post shock"
label var treatXweek_in_dm "Treat $\times$ Week in phase 2"

esttab using "`outfile'", se ///
	keep(treat treatXpost_attend_j treatXweek_in_dm) ///
	order(treat treatXpost_attend_j treatXweek_in_dm) ///
	nostar l cells(b(fmt(a3)) se(fmt(3) par) pval(fmt(3) par("[" "]") pvalue(pval))) ///
	nonotes starlevels(* 0.10 ** 0.05 *** .01) ///
	stats(weekin calweek N, labels("Week in phase FE" "Calendar Week FE" "N: worker-weeks")) ///
	    replace collabels(none) gaps ///
	mtitles("\shortstack{Main\\Spec}" "\shortstack{Lasso\\Residual}" ///
		"\shortstack{$20^{\text{th}}$ \\ Percentile \\ Threshold}" ///
		"\shortstack{$30^{\text{th}}$ \\ Percentile \\ Threshold}" ///
		"\shortstack{Residual\\Baseline\\Only}" "\shortstack{4-Day\\ Rolling\\ Average}" ///
		"\shortstack{7-Day\\ Rolling\\ Average}") style(tex) booktabs

copy "`outfile'" "`alias'", replace

eststo clear
