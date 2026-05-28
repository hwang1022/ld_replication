************************************************************
* Table 4: Automaticity - Change in Psychological Default
************************************************************

version 17
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
local shocks_table2 "$data_temp/shocks_dataset_table2.dta"

local outdir "$output/tables"
capture mkdir "$output"
capture mkdir "`outdir'"

use "`shocks_table2'", clear

capture confirm variable treat
if _rc {
	gen treat = treatment
}

capture confirm variable standid
if _rc {
	egen standid = group(stand)
}

capture confirm variable treatXfirstwk_attendloo_b25
if _rc {
	gen treatXfirstwk_attendloo_b25 = treat * firstwk_attendloo_b25
}

eststo clear

eststo: reg cog_going_without_thinking treat i.standid i.strata if phase == 2, clu(pid)
sum cog_going_without_thinking if treat == 0 & e(sample)
estadd scalar y_mean = r(mean)

eststo: reg cog_going_without_thinking treat treatXpost_attendloo_b25 post_attendloo_b25 ///
	treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 i.standid i.strata ///
	if phase == 2, clu(pid)
sum cog_going_without_thinking if treat == 0 & e(sample)
estadd scalar y_mean = r(mean)

label var treat "Treat"
label var treatXpost_attendloo_b25 "Treat $\times$ Post shock"

esttab using "`outdir'/vig_cog_going_wo_think_attendloo_b25.tex", se(3) replace ///
	keep(treat treatXpost_attendloo_b25) ///
	stats(y_mean N, labels("Control mean" "N: worker")) ///
	nonotes cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
	nostar nomtitles style(tex) booktabs nolz label collabels(none)

copy "`outdir'/vig_cog_going_wo_think_attendloo_b25.tex" "`outdir'/table_d.tex", replace

eststo clear
