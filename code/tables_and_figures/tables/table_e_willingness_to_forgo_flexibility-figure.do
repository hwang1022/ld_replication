************************************************************
* Table VI: Willingness to Forgo Flexibility
* Source: replication/code/analysis/archive/paper_analysis_newdata.do
*         Flexibility block around line 880
************************************************************

version 18.0
clear all
set more off

local shocks_table2 "$temp/shocks_dataset_table2.dta"
local flex_wide "$final/05c_phase2act_flextest_combined.dta"

local outdir "$output/tables"
capture mkdir "$output"
capture mkdir "`outdir'"

* table_code/data_processing.do creates the shock variables consumed here.
use "$ld_dir/07. Data/3. Main Study 3.0/ld_replication/data/final/final_data_prioritize_in_person.dta", clear
merge 1:1 pid date using "`flex_wide'", keep(1 3) nogen
egen flex_num_obs = rownonmiss(fixed_choice_q1 fixed_choice_q2)

eststo clear

recode jl_choice1_fixed_vs_stand 2 = 0
replace jl_choice1_fixed_vs_stand = jl_contract_penalty if jl_choice1_fixed_vs_stand == 1

eststo: reg jl_choice1_fixed_vs_stand treatment i.stand i.strata, clu(pid)
sum jl_choice1_fixed_vs_stand if treat == 0 & e(sample)
estadd scalar y_mean = r(mean)
estadd local strata "Yes", replace
estadd local stand "Yes", replace

reshape long fixed_choice_q, i(pid date) j(qid)

eststo: reg fixed_choice_q treat i.flex_version i.strata i.first_day i.second_day, clu(pid)
sum fixed_choice_q if treat == 0 & e(sample)
estadd scalar y_mean = r(mean)
estadd local strata "Yes", replace
estadd local stand "Yes", replace

eststo: reg fixed_choice_q treat i.flex_version i.strata i.first_day i.second_day [w = flex_num_obs], clu(pid)
sum fixed_choice_q if treat == 0 & e(sample)
estadd scalar y_mean = r(mean)
estadd local strata "Yes", replace
estadd local stand "Yes", replace

eststo: reg fixed_choice_q treat treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 i.standid i.strata i.first_day i.second_day, clu(pid)
sum fixed_choice_q if treat == 0 & e(sample)
global control_mean : di %6.3fc r(mean)
global te : di %6.3fc _b[treat]
global te_se : di %6.3fc _se[treat]
test treat = 0
global pval : di %6.3fc r(p)



eststo: reg fixed_choice_q treat treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 i.standid i.strata i.first_day i.second_day [w = flex_num_obs], clu(pid)
sum fixed_choice_q if treat == 0 & e(sample)
global te_shock : di %6.3fc _b[treatXpost_attendloo_b25]
global te_se_shock : di %6.3fc _se[treatXpost_attendloo_b25]
test treatXpost_attendloo_b25 = 0
global pval_shock : di %6.3fc r(p)

clear

set obs 2

gen mean = $te if _n == 1
replace mean = $te_shock if _n == 2

gen ub = mean + 1.96*$se_beta if _n == 1
replace ub = mean + 1.96*$se_beta_shock if _n == 2

gen lb = mean - 1.96*$se_beta if _n == 2
replace lb = mean - 1.96*$se_beta_shock if _n == 2


cap drop lab1
cap drop p_y1
cap drop p_x1
gen lab1 = "{&Delta}{sub:p}  = $beta_lab , p = $pval"
gen p_y1 = 4.55
gen p_x1 = .5 	


cap drop p_y1_s
gen p_y1_s = 4.9


gen treat = 0 if _n == 1
replace treat = 1 if _n == 2

twoway (bar mean treat if treat == 0, lcolor(gs8) fcolor(gs8%60)) ///
(bar mean treat if treat == 1, lcolor(maroon) fcolor(maroon)) ///
(rcap ub lb treat if treat == 1, lcolor(maroon) lw(thin) ) ///
(scatter p_y1 p_x1 , msym(none) mlab(lab1) mlabpos(0) mlabcolor(gs8) mlabsize(large)) ///
(scatteri 4.5 0 4.5 1,  recast(line) lw(medium)  mc(none) lc(black) lp(solid) lw(thin)) ///
(scatteri 4.5 0 4.5 1,  recast(dropline) base(4.48) lw(medium) mc(none) lc(black) lp(solid) lw(thin)), ///
xlabel(0 "Control" 1 "Treatment", notick) ///
legend(off) xtitle("") ytitle("Automaticity (0-5)") 
graph export "${output_dir}/fig_automaticity_te_zoom.png", replace



twoway (bar mean treat if treat == 0, lcolor(gs8) fcolor(gs8%60)) ///
(bar mean treat if treat == 1, lcolor(maroon) fcolor(maroon)) ///
(rcap ub lb treat if treat == 1, lcolor(maroon) lw(thin)) ///
(scatter p_y1_s p_x1 , msym(none) mlab(lab1) mlabpos(0) mlabcolor(gs8) mlabsize(large)) ///
(scatteri 4.6 0 4.6 1,  recast(line) lw(medium)  mc(none) lc(black) lp(solid) lw(thin)) ///
(scatteri 4.6 0 4.6 1,  recast(dropline) base(4.5) lw(medium) mc(none) lc(black) lp(solid) lw(thin)), ///
xlabel(0 "Control" 1 "Treatment", notick) ///
legend(off) xtitle("") ytitle("Automaticity (0-5)") ///
yscale(r(0 5)) ylabel(0(1)5)
graph export "${output_dir}/fig_automaticity_te_scale0-5.png", replace





