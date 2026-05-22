global data "`c(pwd)'/data"

cap mkdir "$data/output"
cap mkdir "$data/output/figures"

* Requires estimates reg_1-reg_12 produced by the LOSO shock robustness setup.
* The estimation setup is retained in the original source and should be moved
* into data_processing.do before this file is run end-to-end.

matrix coefs = J(50, 4, .)
matrix colnames coefs = threshold coef lb ub
local row = 1
forval current_stand = 1/12 {
	estimates restore reg_`current_stand'
	matrix coefs[`row', 1] = `current_stand'
	matrix coefs[`row', 2] = _b[treat]
	matrix coefs[`row', 3] = e(lb)[1,1]
	matrix coefs[`row', 4] = e(ub)[1,1]
	local row = `row' + 1
}
drop _all
svmat coefs, names(col)
twoway (rcap ub lb threshold, lcolor(gs8) lwidth(medium)) ///
	(scatter coef threshold, mcolor(navy) msize(medium) msymbol(circle)), ///
	xlabel(1 2 3 4 5 6 7 8 9 10 11 12 "None", labsize(small)) ///
	ylabel(, labsize(medium) format(%9.3f)) xtitle("Stand Excluded", size(medium)) ///
	ytitle("Treatment Coefficient", size(medium)) legend(order(2 "Coefficient" 1 "90% CI") size(medium)) ///
	graphregion(color(white)) plotregion(color(white)) yline(0, lcolor(red) lpattern(dash) lwidth(thin))
graph export "$data/output/figures/treatment_effect_by_shock_threshold_col3_treat_loso_originaldata.pdf", replace
graph export "$data/output/figures/figure_a_i_treat.pdf", replace

matrix coefs = J(50, 4, .)
matrix colnames coefs = threshold coef lb ub
local row = 1
forval current_stand = 1/12 {
	estimates restore reg_`current_stand'
	matrix coefs[`row', 1] = `current_stand'
	matrix coefs[`row', 2] = _b[treatXpost_attend_j]
	matrix coefs[`row', 3] = e(lb)[1,2]
	matrix coefs[`row', 4] = e(ub)[1,2]
	local row = `row' + 1
}
drop _all
svmat coefs, names(col)
twoway (rcap ub lb threshold, lcolor(gs8) lwidth(medium)) ///
	(scatter coef threshold, mcolor(navy) msize(medium) msymbol(circle)), ///
	xlabel(1 2 3 4 5 6 7 8 9 10 11 12 "None", labsize(small)) ///
	ylabel(, labsize(medium) format(%9.3f)) xtitle("Stand Excluded", size(medium)) ///
	ytitle("Treatment x Post Shock Coefficient", size(medium)) legend(order(2 "Coefficient" 1 "90% CI") size(medium)) ///
	graphregion(color(white)) plotregion(color(white)) yline(0, lcolor(red) lpattern(dash) lwidth(thin))
graph export "$data/output/figures/treatment_effect_by_shock_threshold_col3_treatpost_loso_originaldata.pdf", replace
graph export "$data/output/figures/figure_a_i_treatpost.pdf", replace
