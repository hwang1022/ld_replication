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

cap mkdir "$output"
cap mkdir "$output/figures"

local shocks_table2 "$data_temp/shocks_dataset_table2.dta"

use "`shocks_table2'", clear

capture confirm variable standid
if _rc {
	egen standid = group(stand)
}

capture confirm variable treat
if _rc {
	gen treat = treatment
}

eststo clear
forval current_stand = 1/12 {
	capture noisily reg attend_nadj treat treatXpost_attend_j post_attend_j attend_week ///
		bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week ///
		if phase==2 & firstwk_attend_j==0 & standid!=`current_stand', vce(cluster standid)
	if _rc continue

	capture noisily boottest {treat} {treatXpost_attend_j}, seed(123) reps(2048) boottype(wild) nograph level(90)
	local used_boottest = (_rc == 0)

	matrix pval = J(1,2,.)
	matrix colnames pval = treat treatXpost_attend_j

	matrix lb = J(1,2,.)
	matrix colnames lb = treat treatXpost_attend_j
	matrix ub = J(1,2,.)
	matrix colnames ub = treat treatXpost_attend_j

	if `used_boottest' {
		matrix pval[1,1] = r(p_1)
		matrix pval[1,2] = r(p_2)
		forv i = 1/2 {
			local ci_clean_`i' = r(CIstr_`i')
			if regexmatch("`ci_clean_`i''", "\[([^,]+),") {
				local temp1_`i' = regexcapture(1)
				local temp1_`i' = subinstr("`temp1_`i''", "−", "-", .)
			}
			if regexmatch("`ci_clean_`i''", ",\s*([^\]]+)\]") {
				local temp2_`i' = regexcapture(1)
				local temp2_`i' = subinstr("`temp2_`i''", "−", "-", .)
			}
			matrix lb[1,`i'] = real("`temp1_`i''")
			matrix ub[1,`i'] = real("`temp2_`i''")
		}
	}
	else {
		matrix pval[1,1] = r(table)[4,1]
		matrix pval[1,2] = r(table)[4,2]
		scalar zcrit = invnormal(0.95)
		matrix lb[1,1] = _b[treat] - zcrit * _se[treat]
		matrix ub[1,1] = _b[treat] + zcrit * _se[treat]
		matrix lb[1,2] = _b[treatXpost_attend_j] - zcrit * _se[treatXpost_attend_j]
		matrix ub[1,2] = _b[treatXpost_attend_j] + zcrit * _se[treatXpost_attend_j]
	}

	eststo reg_`current_stand' : reg attend_nadj treat treatXpost_attend_j post_attend_j attend_week ///
		bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week ///
		if phase==2 & firstwk_attend_j==0 & standid!=`current_stand'
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval
	estadd matrix lb
	estadd matrix ub
}

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
graph export "$output/figures/treatment_effect_by_shock_threshold_col3_treat_loso_originaldata.pdf", replace
graph export "$output/figures/figure_j_treat.pdf", replace

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
graph export "$output/figures/treatment_effect_by_shock_threshold_col3_treatpost_loso_originaldata.pdf", replace
graph export "$output/figures/figure_j_treatpost.pdf", replace
