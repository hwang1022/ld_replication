**c*********************************************************
* Project: Labor Discipline
* Purpose: Build shock datasets for the modular table/figure files.
*
* Reading guide:
*   1. Set paths and analysis constants.
*   2. Build the main worker-day/worker-week analysis dataset.
*   3. Build Phase 2 shock datasets for Table 2 and robustness checks.
*   4. Build the Phase 1 shock dataset used in the appendix.
************************************************************

clear all
set more off
set seed 42

************************************************************
** 1. Paths and analysis constants
************************************************************

local final_data_w_shocks "$final/final_data_w_shocks.dta"

local shocks_prediction_original "$temp/shocks_dataset_prediction_originaldata.dta"
local shocks_prediction_altspec "$temp/shocks_dataset_prediction_originaldata_altspec.dta"
local shocks_prediction_baseline "$temp/shocks_dataset_prediction_originaldata_baseline.dta"
local shocks_prediction_predicted "$temp/shocks_dataset_prediction_originaldata_predicted.dta"
local shocks_prediction_phase1 "$temp/shocks_dataset_prediction_phase1.dta"
local shocks_table2 "$temp/shocks_dataset_table2.dta"
local shocks_original_25 "$temp/shocks_dataset_originaldata_25.dta"
local shocks_ready_original "$temp/shocks_dataset_ready_originaldata.dta"

************************************************************
** 2. Main analysis dataset
**
** This dataset is the common input for Figures 1-4 and
** Tables 1-2. The helper below exists only to attach baseline
** attendance and earnings controls at the worker level before
** downstream datasets are built.
************************************************************

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
		* Internal tempfile used below to merge worker-level baseline controls
		* back onto the full analysis panel.
		save "`bl_cov'", replace
	restore
	merge m:1 pid using "`bl_cov'", update replace keep(1 2 3 4 5) nogen
end

use "$main_data", clear
gen_bl_cov

cap drop work1_wkly2
gen temp1 = work_orig if recall_reliable == 1
egen temp2 = total(temp1), by(pid phase week_in) missing
egen work1_wkly2 = max(temp2), by(pid phase week_in)
drop temp*

* Used by:
*   figure_a_job_finding_probability_by_arrival_time.do
*   figure_b_phase1_attendance_arrival_time.do
*   figure_c_phase2_attendance_arrival_time.do
*   figure_d_attendance_over_time.do
*   figure_e_morning_routines.do
*   figure_f_baseline_job_preferences.do
*   table_a_labor_supply_effects.do
*   table_h_weekly_incentive_amount_phase1.do
*   table_j_consumption_habit_formation.do
*   table_l_general_equilibrium_effects.do
* Also reused within this file to build all shock datasets below.
save "`final_data_w_shocks'", replace

************************************************************
** 3. Phase 2 shock datasets
**
** These datasets measure low-attendance shocks using
** leave-one-worker-out stand attendance. The programs below
** keep the repeated mechanics in one documented place.
************************************************************

cap program drop add_phase_week_vars
program define add_phase_week_vars
	/*
	Create phase-week identifiers and treatment interactions used by
	the Phase 2 shock specifications.
	*/
	capture drop stand_ph_calweek_id1 stand_ph_calweek week_in_dm ///
		treatXweek_in_dm treatXweek_in treatXpostweek5
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
end

cap program drop gen_loo_attendance_loop
program define gen_loo_attendance_loop
	/*
	For each worker, calculate the average residual attendance of
	other workers at the same stand-week. This reproduces the legacy
	loop used by the replication code and is kept as a program because
	the same leave-one-out construction is reused across several shock
	dataset variants.
	*/
	syntax, Phase(integer)
	capture drop pid2 avg_wkattend_loo tag_stand_pid2_calweek lag1avg_wkattend_loo templag
	egen pid2 = group(standid pid)
	gen avg_wkattend_loo = .
	forvalues s = 1/11 {
		quietly summ pid2 if standid == `s'
		forvalues i = `r(min)'/`r(max)' {
			quietly egen temp1 = mean(resid_day_attendph2) if standid == `s' & pid2 != `i' & phase == `phase', by(standid calendar_week)
			quietly egen temp2 = max(temp1) if phase == `phase', by(standid calendar_week)
			quietly replace avg_wkattend_loo = temp2 if pid2 == `i'
			drop temp*
		}
	}
	gen treatXavg_wkattend_loo = treat * avg_wkattend_loo
	sort standid pid2 calendar_week date
	by standid pid2 calendar_week: gen tag_stand_pid2_calweek = 1 if _n == 1
	sort tag_stand_pid2_calweek standid pid2 calendar_week date
	by tag_stand_pid2_calweek standid pid2: gen templag = avg_wkattend_loo[_n - 1] if tag_stand_pid2_calweek == 1 & phase <= `phase'
	egen lag1avg_wkattend_loo = max(templag), by(pid2 calendar_week)
end

cap program drop add_shock_timing
program define add_shock_timing
	/*
	Turn leave-one-out attendance into first-shock, post-shock, and
	one-week/two-plus-week post-shock indicators. The alias25 option
	creates the historical variable names consumed by Table 2.
	*/
	syntax, Threshold(real) [Strict Alias25]

	_pctile avg_wkattend_loo if avg_wkattend_loo != . & dow == 2, p(`threshold')
	scalar pct_j_attend = r(r1)
	if "`strict'" != "" {
		gen wkof_attend_j = (avg_wkattend_loo < pct_j_attend) if avg_wkattend_loo != .
	}
	else {
		gen wkof_attend_j = (avg_wkattend_loo <= pct_j_attend) if avg_wkattend_loo != .
	}

	gen calwk_of_shock = stand_ph_calweek if wkof_attend_j == 1
	bys pid: egen firstofshock_calwk_j = min(calwk_of_shock)
	drop calwk_of_shock

	gen wks_since_shock_j = stand_ph_calweek - firstofshock_calwk_j
	replace wks_since_shock_j = . if firstofshock_calwk_j == .

	gen firstwk_attend_j = (wks_since_shock_j == 0)

	gen post_attend_j = (wks_since_shock_j > 0 & !mi(wks_since_shock_j))
	gen treatXpost_attend_j = treatment * post_attend_j

	gen attend_j_post1 = (wks_since_shock_j == 1)
	gen treatXattend_j_post1 = treatment * attend_j_post1

	gen attend_j_post2p = (wks_since_shock_j >= 2 & !mi(wks_since_shock_j))
	gen treatXattend_j_post2p = treatment * attend_j_post2p

	gen shock_threshold = `threshold'
	label var shock_threshold "Shock Threshold"

	if "`alias25'" != "" {
		gen firstwk_attendloo_b25 = firstwk_attend_j
		gen treatXfirstwk_attendloo_b25 = treatment * firstwk_attendloo_b25
		gen post_attendloo_b25 = post_attend_j
		gen treatXpost_attendloo_b25 = treatXpost_attend_j
		gen attendloo25_post1 = attend_j_post1
		gen treatXattendloo25_post1 = treatXattend_j_post1
		gen attendloo25_post2p = attend_j_post2p
		gen treatXattendloo25_post2p = treatXattend_j_post2p
	}
end

** 3.1 Main Phase 2 shock dataset used by Table 2.
use "`final_data_w_shocks'", clear
egen standid = group(stand)
gen treat = treatment
add_phase_week_vars

reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment if phase < 2
predict resid_day_attendph2 if phase == 2, residuals
gen_loo_attendance_loop, phase(2)

* Internal input reused below to create the 20th, 25th, and 30th
* percentile Phase 2 shock datasets.
save "`shocks_prediction_original'", replace

foreach shock_threshold in 20 25 30 {
	use "`shocks_prediction_original'", clear
	if `shock_threshold' == 25 {
		add_shock_timing, threshold(`shock_threshold') alias25
		* Used by:
		*   table_b_shocks_erode_habit_stock.do
		*   table_d_automaticity_psychological_default.do
		*   table_e_willingness_to_forgo_flexibility.do
		*   figure_j_disruption_effect_robustness.do
		save "`shocks_table2'", replace
		* Used by:
		*   table_n_shock_analysis_col3_robustness.do
		*   table_o_shock_analysis_col4_robustness.do
		save "`shocks_original_25'", replace
		* Compatibility output for older appendix code; no current
		* modular do-file reads this dataset directly.
		save "`shocks_ready_original'", replace
	}
	else {
		add_shock_timing, threshold(`shock_threshold')
	}
	* For shock_threshold == 20 or 30, used by:
	*   table_n_shock_analysis_col3_robustness.do
	*   table_o_shock_analysis_col4_robustness.do
	* For shock_threshold == 25, this overwrites the same file saved
	* above for the same Table N/O consumers.
	save "$temp/shocks_dataset_originaldata_`shock_threshold'.dta", replace
}

** 3.2 Alternative control selection for Appendix shock robustness.
use "`final_data_w_shocks'", clear
egen standid = group(stand)
gen treat = treatment
add_phase_week_vars

local dem_candidates ""
foreach candidate in ss_dem_age ss_dem_age_guess ss_dem_birthplace_* ss_dem_ownhouse_1 ///
	ss_dem_ownhouse_2 ss_dem_ownhouse_3 ss_dem_housetype_1 ss_dem_housetype_2 ///
	ss_dem_housetype_3 ss_dem_housetype_4 ss_dem_housetype_5 ss_dem_highest_edu_1 ///
	ss_dem_highest_edu_2 ss_dem_highest_edu_3 ss_dem_highest_edu_4 ss_dem_highest_edu_5 ///
	ss_dem_educ_numeracy ss_dem_educ_literacy ss_dem_educ_noschool ss_dem_commute_bus ///
	ss_dem_commute_auto ss_dem_commute_train ss_dem_commute_moto ss_dem_commute_bike ///
	ss_dem_commute_foot ss_dem_commute_time {
	capture ds `candidate', has(type numeric)
	if !_rc {
		local dem_candidates "`dem_candidates' `r(varlist)'"
	}
}

dsregress attend treatment if phase < 2, ///
	controls((bl_attend bl_earn miss_bl_earn bl_modalwage ib0.standid i.phase ///
	i.standid#i.phase i.standid#treatment week_in c.week_in#c.week_in) `dem_candidates') ///
	vce(cluster pid)
local controls_treat = e(controls_sel)
reg attend treatment `controls_treat' if phase < 2
predict resid_day_attendph2 if phase == 2, residuals
gen_loo_attendance_loop, phase(2)

* Internal input used immediately below to create the alternative-control
* robustness shock dataset.
save "`shocks_prediction_altspec'", replace
use "`shocks_prediction_altspec'", clear
add_shock_timing, threshold(25)
* Used by:
*   table_n_shock_analysis_col3_robustness.do
*   table_o_shock_analysis_col4_robustness.do
save "$temp/shocks_dataset_originaldata_25_altspec.dta", replace

** 3.3 Baseline-only residual specification for Appendix shock robustness.
use "`final_data_w_shocks'", clear
egen standid = group(stand)
gen treat = treatment
add_phase_week_vars

reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment if phase == 0
predict resid_day_attendph2 if phase == 2, residuals
gen_loo_attendance_loop, phase(2)

* Internal input used immediately below to create the baseline-only
* robustness shock dataset.
save "`shocks_prediction_baseline'", replace
use "`shocks_prediction_baseline'", clear
add_shock_timing, threshold(25)
* Used by:
*   table_n_shock_analysis_col3_robustness.do
*   table_o_shock_analysis_col4_robustness.do
save "$temp/shocks_dataset_originaldata_25_baseline.dta", replace

** 3.4 Rolling-residual shock robustness datasets.
use "`final_data_w_shocks'", clear
egen standid = group(stand)
gen treat = treatment
add_phase_week_vars

reg attend bl_attend standid##phase##treat if phase < 2
predict resid_day_attendph2 if phase == 2, residuals
* Internal input reused below to create the 4-day and 7-day rolling
* residual shock datasets.
save "`shocks_prediction_predicted'", replace

foreach rolling_num in 4 7 {
	use "`shocks_prediction_predicted'", clear
	keep if phase == 2
	sort pid date

	preserve
		keep if dow != 0 & holiday == 0
		bys pid (date): gen day_in_p2 = _n
		xtset pid day_in_p2
		tssmooth ma resid_day_attendph2_rolling = resid_day_attendph2, window(`=`rolling_num' - 1' 1 0)
		keep pid date resid_day_attendph2_rolling
		tempfile rolling_avg
		* Internal tempfile merged back onto the Phase 2 panel below.
		save "`rolling_avg'", replace
	restore
	merge 1:1 pid date using "`rolling_avg'", keep(1 2 3)
	assert _merge == 3 | _merge == 1
	drop _merge
	rename resid_day_attendph2 resid_day_attendph2_noroll
	rename resid_day_attendph2_rolling resid_day_attendph2

	gen_loo_attendance_loop, phase(2)
	* Internal input for the rolling-residual shock dataset saved next;
	* no current modular do-file reads this prediction file directly.
	save "$temp/shocks_dataset_prediction_originaldata_rolling_`rolling_num'.dta", replace

	add_shock_timing, threshold(25)
	* Used by:
	*   table_n_shock_analysis_col3_robustness.do
	*   table_o_shock_analysis_col4_robustness.do
	save "$temp/shocks_dataset_originaldata_rolling_`rolling_num'.dta", replace
}

************************************************************
** 4. Phase 1 shock dataset for Appendix Table A.6
**
** Phase 1 needs a simpler leave-one-worker-out calculation because
** the appendix specification keeps only Tuesday worker-weeks before
** assigning the shock timing.
************************************************************

use "`final_data_w_shocks'", clear
egen standid = group(stand)
gen treat = treatment
gen treatXpostweek5 = treatment * (week_in >= 5)

sort standid phase calendar_week date pid
bys standid phase (date pid): egen start_calendar_week = min(calendar_week)
bys standid phase (date pid): gen stand_ph_calweek = calendar_week - start_calendar_week + 1
gen treatXstand_ph_calweek = treatment * stand_ph_calweek

reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment if phase == 0
predict resid_day_attendph2 if phase == 1, residuals
keep if phase == 1

bys standid calendar_week: egen sum_all = total(resid_day_attendph2)
bys standid calendar_week: egen cnt_all = count(resid_day_attendph2)
bys pid calendar_week: egen sum_pid = total(resid_day_attendph2)
bys pid calendar_week: egen cnt_pid = count(resid_day_attendph2)

gen avg_wkattend_loo = (sum_all - sum_pid) / (cnt_all - cnt_pid)
replace avg_wkattend_loo = . if cnt_all - cnt_pid <= 0 | cnt_all - cnt_pid == .
drop sum_all cnt_all sum_pid cnt_pid

keep if dow == 2

egen temp1 = mean(week_in) if dow == 2, by(pid phase)
egen temp2 = max(temp1), by(pid phase)
gen week_in_dm = week_in - temp2
drop temp*
gen treatXweek_in_dm = treatment * week_in_dm

* Internal input used immediately below to create the Phase 1 shock
* dataset consumed by Table M.
save "`shocks_prediction_phase1'", replace
add_shock_timing, threshold(25) strict
* Used by:
*   table_m_disruptions_phase1.do
save "$temp/shocks_dataset_25_phase1.dta", replace
