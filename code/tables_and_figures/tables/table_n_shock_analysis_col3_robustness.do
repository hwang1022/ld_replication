*****************************************
** Appendix Table A.7: Shock Analysis -- Robustness (column 3)
*****************************************

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
local verified_tex "`outdir'/shocks_analysis_col_3_robustness_originaldata.tex"
local roman_alias "`outdir'/table_n.tex"
capture mkdir "$output"
capture mkdir "`outdir'"

capture program drop min_attend_week
program define min_attend_week
    capture confirm variable attend_week
    if !_rc {
        tempvar min_attend_week
        bysort pid calendar_week: egen `min_attend_week' = min(attend_week)
        replace attend_week = `min_attend_week'
    }
end

capture program drop run_col_3
program define run_col_3
    reg attend_nadj treat treatXpost_attend_j post_attend_j attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attend_j==0, vce(cluster standid)
    boottest {treat} {treatXpost_attend_j}, seed(123) reps(2048) boottype(wild) nograph
    matrix pval = J(1,2,.)
    matrix colnames pval = treat treatXpost_attend_j
    matrix pval[1,1] = r(p_1)
    matrix pval[1,2] = r(p_2)

    eststo: reg attend_nadj treat treatXpost_attend_j post_attend_j attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if firstwk_attend_j!=1, vce(cluster pid)
    estadd local calweek "Yes", replace
    estadd local weekin  "Yes", replace
    estadd matrix pval
end

eststo clear

* Main Specification
use "`shocks_original_25'", clear
keep if phase==2
keep if dow == 2
run_col_3

* Lasso Residual
use "`shocks_altspec'", clear
min_attend_week
keep if phase==2
keep if dow == 2
run_col_3

* 20th Percentile Threshold
use "`shocks_original_20'", clear
min_attend_week
keep if phase==2
keep if dow == 2
run_col_3

* 30th Percentile Threshold
use "`shocks_original_30'", clear
min_attend_week
keep if phase==2
keep if dow == 2
run_col_3

* Residual Baseline Only
use "`shocks_baseline_25'", clear
min_attend_week
keep if phase==2
keep if dow == 2
run_col_3

* 4-Day Rolling Average
use "`shocks_rolling_4'", clear
min_attend_week
keep if phase==2
keep if dow == 2
run_col_3

* 7-Day Rolling Average
use "`shocks_rolling_7'", clear
min_attend_week
keep if phase==2
keep if dow == 2
run_col_3

label var treat "Treat"
label var treatXpost_attend_j "Treat $\times$ Post shock"

esttab using "`verified_tex'", se ///
    keep(treat treatXpost_attend_j) ///
    order(treat treatXpost_attend_j) ///
    posthead("\midrule") prefoot("\hlinmidrulee") ///
    nostar l cells(b(fmt(a3)) se(fmt(3) par) pval(fmt(3) par("[" "]") pvalue(pval))) nonotes ///
    starlevels(* 0.10 ** 0.05 *** .01) ///
    stats(weekin calweek N, labels("Week in phase FE" "Calendar Week FE" "N: worker-weeks")) ///
    replace collabels(none) gaps ///
    mtitles("\shortstack{Main\\Spec}" "\shortstack{Lasso\\Residual}" "\shortstack{$20^{\text{th}}$ \\ Percentile \\ Threshold}" "\shortstack{$30^{\text{th}}$ \\ Percentile \\ Threshold}" "\shortstack{Residual\\Baseline\\Only}" "\shortstack{4-Day\\ Rolling\\ Average}" "\shortstack{7-Day\\ Rolling\\ Average}") ///
    style(tex) booktabs

copy "`verified_tex'" "`roman_alias'", replace

eststo clear
