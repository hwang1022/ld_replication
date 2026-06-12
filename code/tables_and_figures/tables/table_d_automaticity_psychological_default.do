************************************************************
* Table 4: Automaticity - Change in Psychological Default
************************************************************

version 17
clear all
set more off

local shocks_table2 "$temp/shocks_dataset_table2.dta"

local outdir "$output/tables"
capture mkdir "$output"
capture mkdir "`outdir'"

use "`shocks_table2'", clear

// Note: as part of the cleaning, the cog_going_without_thinking scale was compressed to be in 0-1 from 1-4
// generate a variable in case the unscaled version is preferred
gen cog_going_without_thinking_u = (cog_going_without_thinking * 4) + 1
local cog_variable cog_going_without_thinking_u 

eststo clear

eststo: reg `cog_variable' treat i.standid i.strata if phase == 2, clu(pid)
sum `cog_variable' if treat == 0 & e(sample)
estadd scalar y_mean = r(mean)

eststo: reg `cog_variable' treat treatXpost_attendloo_b25 post_attendloo_b25 ///
	treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 i.standid i.strata ///
	if phase == 2, clu(pid)
sum `cog_variable' if treat == 0 & e(sample)
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
