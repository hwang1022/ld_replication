************************************************************
* Appendix Table A.5: General Equilibrium Effects
* Source: verification.md Table A.5 entry and
* hao_working_folder/oct_25_presentation/6_ge_effect_originaldata.do.
************************************************************

clear all
set more off

global data "`c(pwd)'/data"
local analysis_main "$data/final/analysis_main.dta"
local stand_size_intensity "$data/stand_strength/data/stand_size_intensity.dta"
local stand_size_studysample "$data/stand_strength/data/stand_size_intensity_studysample.dta"

local outdir "$data/output/tables"
local outfile "`outdir'/com_weekly_attend_b8_attend_work1_frag2_faq_higher_treat_intensity_exp_originaldata.tex"
local alias "`outdir'/table_a_v.tex"
local het higher_treat_intensity_exp

capture mkdir "$data"
capture mkdir "$data/output"
capture mkdir "`outdir'"

use `analysis_main', clear
gen treat = treatment

merge m:1 stand using `stand_size_intensity', ///
	keep(1 2 3) nogen keepusing(higher_treat_intensity_exp him_treat_intensity_exp)
rename higher_treat_intensity_exp higher_treat_intensity_exp_ass
rename him_treat_intensity_exp him_treat_intensity_exp_ass

merge m:1 stand using `stand_size_studysample', ///
	keep(1 2 3) nogen keepusing(higher_treat_intensity_exp him_treat_intensity_exp)

local median_note_higher ""
local median_note_lower "Median or "

eststo clear
foreach i in 0 1 {
	eststo clear
	preserve
	keep if `het' == `i'

	foreach j of varlist attend_nadj attend_and_before8_nadj {
		eststo: reg `j' treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
			ib1.stand i.strata i.week_in i.calendar_week if phase == 1, vce(cluster pid)
		sum `j' if treatment == 0 & e(sample)
		estadd scalar y_mean = r(mean)
		estadd scalar t_effect = 100 * e(b)[1,1] / r(mean)
	}

	foreach j of varlist attend_nadj attend_and_before8_nadj work1_wkly2 {
		eststo: reg `j' treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
			ib1.stand i.strata i.week_in i.calendar_week if phase == 2, vce(cluster pid)
		sum `j' if treatment == 0 & e(sample)
		estadd scalar y_mean = r(mean)
		estadd scalar t_effect = 100 * e(b)[1,1] / r(mean)
	}

	if `i' == 0 {
		esttab using "`outfile'", ///
			replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
			stats(y_mean t_effect N, fmt(a3 a0 a0) labels("Control mean" "Treatment Effect (\%)" "N: worker-weeks")) ///
			collabels(none) nonotes mtitles("By 8" "Attend" "By 8" "Attend" "Work") ///
			nostar booktabs style(tex) label ///
			mgroups("Phase 1" "Phase 2", pattern(1 0 1 0 0) prefix("\multicolumn{@span}{c}{") suffix("}") span erepeat(\cmidrule(lr){@span})) ///
			prehead("\begin{tabular}{l*{5}{c}}" "\toprule") ///
			posthead("\midrule" "\multicolumn{6}{c}{\textbf{Panel A --- `median_note_lower'Lower Intensity than Median Stand}} \\" "\midrule") ///
			postfoot("\bottomrule")
	}
	else {
		esttab using "`outfile'", ///
			append keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
			stats(y_mean t_effect N, fmt(a3 a0 a0) labels("Control mean" "Treatment Effect (\%)" "N: worker-weeks")) ///
			collabels(none) nonotes nomtitle nostar booktabs style(tex) label ///
			prehead("\multicolumn{6}{c}{\textbf{Panel B --- `median_note_higher'Higher Intensity than Median Stand}} \\" "\midrule") ///
			posthead("") postfoot("\bottomrule")
	}
	eststo clear
	restore
}

eststo clear
eststo a10: reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
	ib1.stand i.strata i.week_in i.calendar_week if phase == 1 & `het' == 0
eststo a11: reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
	ib1.stand i.strata i.week_in i.calendar_week if phase == 1 & `het' == 1

eststo b10: reg attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
	ib1.stand i.strata i.week_in i.calendar_week if phase == 1 & `het' == 0
eststo b11: reg attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
	ib1.stand i.strata i.week_in i.calendar_week if phase == 1 & `het' == 1

eststo a20: reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
	ib1.stand i.strata i.week_in i.calendar_week if phase == 2 & `het' == 0
eststo a21: reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
	ib1.stand i.strata i.week_in i.calendar_week if phase == 2 & `het' == 1

eststo b20: reg attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
	ib1.stand i.strata i.week_in i.calendar_week if phase == 2 & `het' == 0
eststo b21: reg attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
	ib1.stand i.strata i.week_in i.calendar_week if phase == 2 & `het' == 1

eststo d20: reg work1_wkly2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
	ib1.stand i.strata i.week_in i.calendar_week if phase == 2 & `het' == 0
eststo d21: reg work1_wkly2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
	ib1.stand i.strata i.week_in i.calendar_week if phase == 2 & `het' == 1

foreach i in b1 a1 b2 a2 d2 {
	suest `i'0 `i'1, vce(cluster pid)
	test [`i'0_mean]treatment = [`i'1_mean]treatment
	estadd scalar chi2 = r(chi2) : `i'0
	estadd scalar p = r(p) : `i'0
}

esttab b10 a10 b20 a20 d20 using "`outfile'", ///
	append drop(*) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
	stats(p, fmt(a3 a3) labels("P-value")) collabels(none) ///
	nonotes nomtitle nostar booktabs style(tex) label ///
	prehead("\multicolumn{6}{c}{\textbf{Panel C --- Difference in Treatment Effect in Panel A and B}} \\" "\midrule") ///
	posthead("") prefoot("") postfoot("\bottomrule" "\end{tabular}")

copy "`outfile'" "`alias'", replace

eststo clear
