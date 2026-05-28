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
local employers_survey "$data_final/ls_employers_survey_combined.dta"

cap mkdir "$output"
cap mkdir "$output/figures"

use "`employers_survey'", clear

gen response_1 = comb_relay_more_training
gen response_2 = comb_relay_offer_benefits
gen response_3 = comb_relay_skill_project
gen response_4 = comb_relay_expand_business
gen response_5 = comb_relay_inkind_gifts
replace response_5 = 1 if role == 2 & (em_relay_others_spec == "Give to Ration rice and house rent." | em_relay_others_spec == "Ration rice/house rent provided")
replace response_5 = 1 if role == 1 & rec_relay_others_spec != ""
gen response_6 = comb_relay_intrest_free_loans
gen response_7 = comb_relay_pay_school_fees

keep recruiter_id response*
drop if response_1 == .
reshape long response_, i(recruiter_id) j(choice)
collapse (mean) response_, by(choice)

label define empresp_lab 1 `""Provide" "training" "' 2 "Insurance" 3 `""Change biz""type""' 4 `""Expand""business""' 5 "In-kind gifts" 6 "Loans" 7 "School fees"
label value choice empresp_lab

graph bar response_, over(choice, label(labsize(medium))) xsize(8) ytitle("Fraction of recruiter responses") bar(1, fcolor(gs12) lcolor(gs12))
graph export "$output/figures/emp_resp_c7_n7.pdf", replace
graph export "$output/figures/figure_i.pdf", replace
