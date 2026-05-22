************************************************************
* Table VI: Willingness to Forgo Flexibility
* Source: replication/code/analysis/archive/paper_analysis_newdata.do
*         Flexibility block around line 880
************************************************************

version 18.0
clear all
set more off

global data "`c(pwd)'/data"
local shocks_table2 "$data/temp/shocks_dataset_table2.dta"

local outdir "$data/output/tables"
capture mkdir "$data/output"
capture mkdir "`outdir'"

* table_code/data_processing.do creates the shock variables consumed here.
use `shocks_table2', clear

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
estadd scalar y_mean = r(mean)
estadd local strata "Yes", replace
estadd local stand "Yes", replace

eststo: reg fixed_choice_q treat treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 i.standid i.strata i.first_day i.second_day [w = flex_num_obs], clu(pid)
sum fixed_choice_q if treat == 0 & e(sample)
estadd scalar y_mean = r(mean)
estadd local strata "Yes", replace
estadd local stand "Yes", replace

esttab using "`outdir'/flex_fixed_choice_attendloo_b25.tex", se(3) replace keep(treat treatXpost_attendloo_b25) ///
	stats(y_mean N, labels("Control mean" "N: worker-question")) l nonotes ///
	cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) nostar collabels(none) nonum ///
	mtitles("\shortstack{Contract\\ Job}" "\shortstack{Fixed choice\\ No Weight}" ///
		"\shortstack{Fixed choice\\ Weighted}" "\shortstack{Fixed choice\\ Weighted}" ///
		"\shortstack{Fixed choice\\ No Weight}") booktabs style(tex)

copy "`outdir'/flex_fixed_choice_attendloo_b25.tex" "`outdir'/table_vi.tex", replace

eststo clear
