global data "`c(pwd)'/data"
local employers_survey "$data/final/ls_employers_survey_combined.dta"

cap mkdir "$data/output"
cap mkdir "$data/output/figures"

use `employers_survey', clear
graph bar, over(comb_10day_contract_absent_days, label(labsize(medium))) ///
	b1title(Number of days, size(medium)) yla(, labsize(*1.3)) ///
	ytitle("Percent", size(medium)) bar(1, fcolor(gs12) lcolor(gs12))
graph export "$data/output/figures/workers_days_off_10.pdf", replace
graph export "$data/output/figures/figure_vii.pdf", replace
