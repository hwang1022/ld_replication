************************************************************
* Appendix Table A.2: Baseline Characteristics
* Source: verification.md Table A.2 and
* hao_working_folder/nov_paper/nov_paper_analysis.do lines 392-453.
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

use "`analysis_main'", clear

bysort pid date: gen uniqpid = _n == 1
keep if uniqpid == 1

local balance_vars ss_dem_age ss_dem_educ_noschool bs_dem_has_family bs_dem_stand_yrs bs_dem_job_yrs bs_sum_attend bs_sum_work bs_avg_wage bs_sum_wage
local nvars : word count `balance_vars'

tempname control_b control_v treatment_b treatment_v pvalue_b pvalue_v
matrix `control_b' = J(1, `nvars', .)
matrix `control_v' = J(`nvars', `nvars', 0)
matrix `treatment_b' = J(1, `nvars', .)
matrix `treatment_v' = J(`nvars', `nvars', 0)
matrix `pvalue_b' = J(1, `nvars', .)
matrix `pvalue_v' = J(`nvars', `nvars', 0)
matrix colnames `control_b' = `balance_vars'
matrix rownames `control_v' = `balance_vars'
matrix colnames `control_v' = `balance_vars'
matrix colnames `treatment_b' = `balance_vars'
matrix rownames `treatment_v' = `balance_vars'
matrix colnames `treatment_v' = `balance_vars'
matrix colnames `pvalue_b' = `balance_vars'
matrix rownames `pvalue_v' = `balance_vars'
matrix colnames `pvalue_v' = `balance_vars'

local i = 0
foreach var in `balance_vars' {
    local ++i
    ttest `var' if phase == 0 & uniqpid == 1, by(treatment)
    matrix `control_b'[1, `i'] = r(mu_1)
    matrix `control_v'[`i', `i'] = r(sd_1)^2
    matrix `treatment_b'[1, `i'] = r(mu_2)
    matrix `treatment_v'[`i', `i'] = r(sd_2)^2

    reg `var' treatment i.stand i.strata if phase == 0 & uniqpid == 1, r
    local t = _b[treatment] / _se[treatment]
    matrix `pvalue_b'[1, `i'] = 2 * ttail(e(df_r), abs(`t'))
}

count if treatment == 1 & phase == 0 & uniqpid == 1
local n_t = r(N)
count if treatment == 0 & phase == 0 & uniqpid == 1
local n_c = r(N)

local verified_tex "`outdir'/baseline_treatment_control_balance3col.tex"
local roman_alias "`outdir'/table_i.tex"

eststo clear
ereturn post `control_b' `control_v', obs(`n_c')
eststo control
ereturn post `treatment_b' `treatment_v', obs(`n_t')
eststo treatment
ereturn post `pvalue_b' `pvalue_v'
eststo pvalue

esttab control treatment pvalue using "`verified_tex'", ///
    b(2) se(2) ///
    keep(`balance_vars') ///
    coeflabels(ss_dem_age "\hspace{0.1cm} Age" ///
        ss_dem_educ_noschool "\hspace{0.1cm} No schooling" ///
        bs_dem_has_family "\hspace{0.1cm} Has spouse/children" ///
        bs_dem_stand_yrs "\hspace{0.1cm} Years at stand" ///
        bs_dem_job_yrs "\hspace{0.1cm} Years in current profession" ///
        bs_sum_attend "\hspace{0.1cm} Days attended stand" ///
        bs_sum_work "\hspace{0.1cm} Days worked" ///
        bs_avg_wage "\hspace{0.1cm} Average daily wage (in rupees)" ///
        bs_sum_wage "\hspace{0.1cm} Total earnings (in rupees)") ///
    prehead("\begin{tabular}{lccc}" "\toprule" ///
        "         &  (1) & (2) & (3)  \\" ///
        "         & Control & Treatment & Regression  \\" ///
        "         & Mean    & Mean      & P-value \\") ///
    postfoot("\midrule" "Observations       & `n_c' & `n_t' & \\" ///
        "\bottomrule" "\end{tabular}") ///
    nostar nogaps fragment collabels(none) nomtitles nonumbers noobs label ///
    substitute("\hline" "\midrule" "(0.00)" "" "(.)" "") replace

copy "`verified_tex'" "`roman_alias'", replace

eststo clear
