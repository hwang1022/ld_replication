************************************************************
* Tables and figures runner
************************************************************

clear all
set more off

if "$MasterRunning" != "" {
	// Path to this file's location
	global analysis_code "$code/tables_and_figures"
}
else {
	// For running locally without full repo; set below to where the code is located
	global analysis_code "/Users/st2246/Work/labor/new_asks/table_code"
	// Defines globals needed by table / figure code below if this is not running through main
	global data "$analysis_code/data"
	global final "$data/final"
	global temp "$data/temp"
	global external "$data/external"

	// NOTE: change this to '1' use the "in-person" data
	global prioritize_in_person = 0

	global main_data "$final/final_data_prioritize_date.dta"
	if $prioritize_in_person == 1 {
		global main_data "$final/final_data_prioritize_in_person.dta"
	}

	global output "$analysis_code/output/prioritize_date"
	if $prioritize_in_person == 1 {
		global output "$analysis_code/output/prioritize_in_person"
	}

	global tables "$output/tables"
	global figures "$output/figures"
	global stats "$output/stats"
}

capture mkdir "$output"
capture mkdir "$tables"
capture mkdir "$figures"
capture mkdir "$stats"

do "$analysis_code/shock_data_processing.do"

do "$analysis_code/figures/figure_a_job_finding_probability_by_arrival_time.do"
do "$analysis_code/figures/figure_b_phase1_attendance_arrival_time.do"
do "$analysis_code/figures/figure_c_phase2_attendance_arrival_time.do"
do "$analysis_code/figures/figure_d_attendance_over_time.do"
do "$analysis_code/figures/figure_e_morning_routines.do"
do "$analysis_code/figures/figure_f_baseline_job_preferences.do"
do "$analysis_code/figures/figure_g_predicted_worker_absenteeism.do"
do "$analysis_code/figures/figure_h_employer_costs.do"
do "$analysis_code/figures/figure_i_labor_market_structure.do"
do "$analysis_code/figures/figure_j_disruption_effect_robustness.do"

do "$analysis_code/tables/table_a_labor_supply_effects.do"
do "$analysis_code/tables/table_b_shocks_erode_habit_stock.do"
do "$analysis_code/tables/table_c_perceived_job_finding_probability.do"
do "$analysis_code/tables/table_d_automaticity_psychological_default.do"
do "$analysis_code/tables/table_e_willingness_to_forgo_flexibility.do"
do "$analysis_code/tables/table_f_employer_beliefs.do"
do "$analysis_code/tables/table_g_employer_job_offer_survey.do"
do "$analysis_code/tables/table_h_weekly_incentive_amount_phase1.do"
do "$analysis_code/tables/table_i_baseline_characteristics.do"
do "$analysis_code/tables/table_j_consumption_habit_formation.do"
do "$analysis_code/tables/table_k_stand_size_treatment_intensity.do"
do "$analysis_code/tables/table_l_general_equilibrium_effects.do"
do "$analysis_code/tables/table_m_disruptions_phase1.do"
do "$analysis_code/tables/table_n_shock_analysis_col3_robustness.do"
do "$analysis_code/tables/table_o_shock_analysis_col4_robustness.do"
