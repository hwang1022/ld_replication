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
cap mkdir "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/09. Presentations/2026.06.15 WorldBank ABCDE/figures"
global output_dir "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/09. Presentations/2026.06.15 WorldBank ABCDE/figures"
use "`shocks_table2'", clear

// Note: as part of the cleaning, the cog_going_without_thinking scale was compressed to be in 0-1 from 1-4
// generate a variable in case the unscaled version is preferred
gen cog_going_without_thinking_u = (cog_going_without_thinking * 4) + 1
local cog_variable cog_going_without_thinking_u 

eststo clear

eststo: reg `cog_variable' treat i.standid i.strata if phase == 2, clu(pid)
sum `cog_variable' if treat == 0 & e(sample)
estadd scalar y_mean = r(mean)
global control_mean = r(mean)

global beta = _b[treat]
global beta_lab :  di %6.3fc $beta
global se_beta = _se[treat]
global te = $control_mean + $beta
qui test _b[treat] = 0
global pval: di %6.3fc r(p)

clear
set obs 2
gen mean = $control_mean if _n == 1
replace mean = $te if _n == 2

gen ub = mean + 1.96*$se_beta if _n == 2
gen lb = mean - 1.96*$se_beta if _n == 2
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
