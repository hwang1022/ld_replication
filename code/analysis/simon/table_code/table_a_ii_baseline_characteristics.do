************************************************************
* Appendix Table A.2: Baseline Characteristics
* Source: verification.md Table A.2 and
* hao_working_folder/nov_paper/nov_paper_analysis.do lines 392-453.
************************************************************

clear all
set more off

global data "`c(pwd)'/data"
local phase1_phase2_combined "$data/final/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta"

local outdir "$data/output/tables"

capture mkdir "$data/output"
capture mkdir "`outdir'"

use `phase1_phase2_combined', clear
duplicates drop pid, force

local balance_vars ss_dem_age bs_dem_has_family bs_sum_attend bs_sum_work bs_sum_wage ss_dem_educ_noschool ss_dem_educ_literacy bs_dem_stand_yrs bs_dem_job_yrs bs_avg_wage
foreach var in `balance_vars' {
    ttest `var' if phase == 0 & uniqpid == 1, by(treatment)
    local `var'_mean_c : di %6.2fc r(mu_1)
    local `var'_sd_c   : di %6.2fc r(sd_1)
    local `var'_sd_c  "(``var'_sd_c')"
    local `var'_sd_c : subinstr local `var'_sd_c " " "", all
    local `var'_mean_t : di %6.2fc r(mu_2)
    local `var'_sd_t   : di %6.2fc r(sd_2)
    local `var'_sd_t  "(``var'_sd_t')"
    local `var'_sd_t : subinstr local `var'_sd_t " " "", all
    local `var'_p      : di %6.2fc r(p)

    reg `var' treatment i.stand i.strata if phase == 0 & uniqpid == 1, r
    local t = _b[treatment] / _se[treatment]
    local `var'_reg_p : di %6.2fc 2 * ttail(e(df_r), abs(`t'))
}

count if treatment == 1 & phase == 0 & uniqpid == 1
local n_t = r(N)
count if treatment == 0 & phase == 0 & uniqpid == 1
local n_c = r(N)

texdoc init "`outdir'/baseline_treatment_control_balance3col.tex", replace force
tex \begin{tabular}{lccc}
tex \toprule
tex          &  (1) & (2) & (3)  \\
tex          & Control & Treatment & Regression  \\
tex & Mean    & Mean      & P-value \\
tex \midrule
tex \hspace{0.1cm} Age                 & `ss_dem_age_mean_c'           & `ss_dem_age_mean_t'                  & `ss_dem_age_reg_p' \\
tex                                    & `ss_dem_age_sd_c'             & `ss_dem_age_sd_t'            &                   \\
tex \hspace{0.1cm} No schooling   & `ss_dem_educ_noschool_mean_c' & `ss_dem_educ_noschool_mean_t' & `ss_dem_educ_noschool_reg_p' \\
tex                               & `ss_dem_educ_noschool_sd_c'   & `ss_dem_educ_noschool_sd_t'    &                   \\
tex \hspace{0.1cm} Has spouse/children & `bs_dem_has_family_mean_c'    & `bs_dem_has_family_mean_t'   &  `bs_dem_has_family_reg_p' \\
tex                                    & `bs_dem_has_family_sd_c'      & `bs_dem_has_family_sd_t'     &                   \\
tex \hspace{0.1cm} Years at stand                & `bs_dem_stand_yrs_mean_c'   & `bs_dem_stand_yrs_mean_t' & `bs_dem_stand_yrs_reg_p' \\
tex                                             & `bs_dem_stand_yrs_sd_c'     & `bs_dem_stand_yrs_sd_t'     &                 \\
tex \hspace{0.1cm} Years in current profession   & `bs_dem_job_yrs_mean_c'     & `bs_dem_job_yrs_mean_t'   & `bs_dem_job_yrs_reg_p' \\
tex                                             & `bs_dem_job_yrs_sd_c'       & `bs_dem_job_yrs_sd_t'       &                 \\
tex \hspace{0.1cm} Days attended stand         & `bs_sum_attend_mean_c'        & `bs_sum_attend_mean_t'    & `bs_sum_attend_reg_p' \\
tex                                                 & `bs_sum_attend_sd_c'          & `bs_sum_attend_sd_t'          &                          \\
tex \hspace{0.1cm} Days worked & `bs_sum_work_mean_c' & `bs_sum_work_mean_t' & `bs_sum_work_reg_p' \\
tex                                                 & `bs_sum_work_sd_c'   & `bs_sum_work_sd_t'   &                          \\
tex \hspace{0.1cm} Average daily wage (in rupees)         & `bs_avg_wage_mean_c'          & `bs_avg_wage_mean_t'   & `bs_avg_wage_reg_p' \\
tex                                                 & `bs_avg_wage_sd_c'            & `bs_avg_wage_sd_t'            &                          \\
tex \hspace{0.1cm} Total earnings (in rupees)         & `bs_sum_wage_mean_c'          & `bs_sum_wage_mean_t'   & `bs_sum_wage_reg_p' \\
tex                                                 & `bs_sum_wage_sd_c'            & `bs_sum_wage_sd_t'            &                          \\
tex \hline
tex Observations       & `n_c' & `n_t' & \\
tex \bottomrule
tex \end{tabular}
texdoc close

copy "`outdir'/baseline_treatment_control_balance3col.tex" "`outdir'/table_a_ii.tex", replace
