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
graph bar, over(comb_10day_contract_absent_days, label(labsize(medium))) ///
	b1title(Number of days, size(medium)) yla(, labsize(*1.3)) ///
	ytitle("Percent", size(medium)) bar(1, fcolor(gs12) lcolor(gs12))
graph export "$output/figures/workers_days_off_10.pdf", replace
graph export "$output/figures/figure_g.pdf", replace
