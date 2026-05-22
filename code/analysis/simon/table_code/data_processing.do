************************************************************
* Project: Labor Discipline
* Purpose: Shared data processing for modular table_code files
************************************************************

clear all
set more off
set seed 42

global data "`c(pwd)'/data"
local main_data_prioritize_date "$data/final/final_data_prioritize_date.dta"
local analysis_main "$data/final/analysis_main.dta"
local shocks_prediction_original "$data/temp/shocks_dataset_prediction_originaldata.dta"
local shocks_table2 "$data/temp/shocks_dataset_table2.dta"
local shocks_original_25 "$data/temp/shocks_dataset_originaldata_25.dta"
local shocks_ready_original "$data/temp/shocks_dataset_ready_originaldata.dta"
global code "`c(pwd)'/replication/code"
global raw "$data/raw"
global temp "$data/temp"
global final "$data/final"
global external "$data/external"
global output "$data/output"
global tables "$output/tables"
global figures "$output/figures"
global stats "$output/stats"

global data_version "new"
global data_version_new "prioritize_date"
global prioritize_in_person = 0

global original_main "$final/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta"
global new_main_prioritize_date "$final/final_data_prioritize_date.dta"
global new_main_prioritize_in_person "$final/final_data_prioritize_in_person.dta"
global main_data "$new_main_prioritize_date"

global droplist "4, 7, 8, 9, 10, 11, 12, 14, 19"
global cutoff_0815 "2, 6, 15, 17, 19, 20"
global cutoff_0745 "12"
global union_pid "1409, 1414, 1416, 1448"
global dropout_pid "2107, 555, 547, 646, 689, 641, 1405, 1903, 1928, 2020, 1744, 1333"

cap mkdir "$data"
cap mkdir "$temp"
cap mkdir "$final"
cap mkdir "$output"
cap mkdir "$tables"
cap mkdir "$figures"
cap mkdir "$stats"

cap program drop save_input
program define save_input
	syntax [anything], number(str) filename(str) [format(str)]
	if "`format'" != "" local number_formatted = string(`number', "`format'")
	else local number_formatted "`number'"
	file open newfile using "$stats/`filename'.tex", write replace
	file write newfile "`number_formatted'%"
	file close newfile
end

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
		gen miss_bl_earn = (bl_earn == .)
		replace bl_earn = 0 if miss_bl_earn == 1
		drop temp
		egen temp1 = mode(earn) if earn > 0, by(pid)
		egen bl_modalwage = max(temp1), by(pid)
		replace bl_modalwage = 0 if bl_modalwage == .
		drop temp1
		keep pid bl_attend bl_earn miss_bl_earn bl_modalwage
		duplicates drop pid, force
		tempfile bl_cov
		save `bl_cov', replace
	restore
	merge m:1 pid using `bl_cov', update replace keep(1 2 3 4 5) nogen
end

************************************************************
** Main analysis dataset used by Figures 1-4 and Tables 1-2
************************************************************

use `main_data_prioritize_date', clear
gen_bl_cov

cap drop work1_wkly2
gen temp1 = work_orig if recall_reliable == 1
egen temp2 = total(temp1), by(pid phase week_in) missing
egen work1_wkly2 = max(temp2), by(pid phase week_in)
drop temp*

save `analysis_main', replace

************************************************************
** Phase 2 shock indicators for Table 2 and related tables
************************************************************

use `analysis_main', clear
egen standid = group(stand)
gen treat = treatment

sort standid phase calendar_week date pid
by standid phase calendar_week: gen stand_ph_calweek_id1 = 1 if _n == 1
egen temp2 = seq() if stand_ph_calweek_id1 == 1, by(standid phase)
egen stand_ph_calweek = max(temp2), by(standid phase calendar_week)
drop temp*

egen temp1 = mean(week_in) if dow == 1, by(pid phase)
egen temp2 = max(temp1), by(pid phase)
gen week_in_dm = week_in - temp2
drop temp*

gen treatXweek_in_dm = treat * week_in_dm
gen treatXweek_in = treat * week_in
gen treatXpostweek5 = treat * (week_in >= 5)

reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment if phase < 2
predict resid_day_attendph2 if phase == 2, residuals

egen pid2 = group(standid pid)
gen avg_wkattend_loo = .
forvalues s = 1/11 {
	quietly summ pid2 if standid == `s'
	forvalues i = `r(min)'/`r(max)' {
		quietly egen temp1 = mean(resid_day_attendph2) if standid == `s' & pid2 != `i' & phase == 2, by(standid calendar_week)
		quietly egen temp2 = max(temp1) if phase == 2, by(standid calendar_week)
		quietly replace avg_wkattend_loo = temp2 if pid2 == `i'
		drop temp*
	}
}

_pctile avg_wkattend_loo if avg_wkattend_loo != . & dow == 2, p(25)
scalar pct_j_attend = r(r1)
gen wkof_attend_j = (avg_wkattend_loo <= pct_j_attend) if avg_wkattend_loo != .

gen calwk_of_shock = stand_ph_calweek if wkof_attend_j == 1
bys pid: egen firstofshock_calwk_j = min(calwk_of_shock)
drop calwk_of_shock

gen wks_since_shock_j = stand_ph_calweek - firstofshock_calwk_j
replace wks_since_shock_j = . if firstofshock_calwk_j == .

gen firstwk_attend_j = (wks_since_shock_j == 0)
gen firstwk_attendloo_b25 = firstwk_attend_j
gen treatXfirstwk_attendloo_b25 = treatment * firstwk_attendloo_b25

gen post_attend_j = (wks_since_shock_j > 0 & !mi(wks_since_shock_j))
gen treatXpost_attend_j = treatment * post_attend_j
gen post_attendloo_b25 = post_attend_j
gen treatXpost_attendloo_b25 = treatXpost_attend_j

gen attend_j_post1 = (wks_since_shock_j == 1)
gen attendloo25_post1 = attend_j_post1
gen treatXattend_j_post1 = treatment * attend_j_post1
gen treatXattendloo25_post1 = treatXattend_j_post1

gen attend_j_post2p = (wks_since_shock_j >= 2 & !mi(wks_since_shock_j))
gen attendloo25_post2p = attend_j_post2p
gen treatXattend_j_post2p = treatment * attend_j_post2p
gen treatXattendloo25_post2p = treatXattend_j_post2p

save `shocks_prediction_original', replace
save `shocks_table2', replace

************************************************************
** Compatibility aliases expected by older appendix code
************************************************************

capture confirm file `shocks_original_25'
if _rc {
	save `shocks_original_25', replace
}

capture confirm file `shocks_ready_original'
if _rc {
	save `shocks_ready_original', replace
}
