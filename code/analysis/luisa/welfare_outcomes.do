 ************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Replicate the main paper analysis using HW's new dataset
* 	Author:				HW 
* 	Last modified:		2026-Apr-23 (HW)
************************************************************
************************************************************


****
**## 1. Call Data
****

use "/Users/`c(username)'/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/code/analysis/luisa/final_data_prioritize_in_person.dta" , clear

** Beliefs about third person	
gen bs_dem_workdays_late_arr_frac = bs_dem_workdays_late_arriver/7
gen bs_dem_workdays_early_arr_frac = bs_dem_workdays_early_arriver/7
	
twoway (hist bs_dem_workdays_late_arriver if phase == 1 & week_in == 1 & dow == 1,  lcolor(gs12) fcolor(gs12) frac discrete lw(thin)) || ///
(hist bs_dem_workdays_early_arriver if phase == 1 & week_in == 1 & dow == 1, lcolor(red) fcolor(none) frac discrete lw(thin)), ///
legend(order(2 "Worker who arrives by 7:40 am" 1 "Worker who arrives by 9 am")) ///
xlabel(0(1)7) xtitle("Expected number of days of employment (out of 7)")
graph export "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/figures/hist_expected_jfp_baseline_days.tex", replace

twoway (hist bs_dem_workdays_late_arr_frac if phase == 1 & week_in == 1 & dow == 1, width(.2) start(0) lcolor(gs12) fcolor(gs12) frac lw(thin)) || ///
(hist bs_dem_workdays_early_arr_frac if phase == 1 & week_in == 1 & dow == 1, width(.2) start(0) lcolor(red) fcolor(none) frac lw(thin)), ///
legend(order(2 "Worker who arrives by 7:40 am" 1 "Worker who arrives by 9 am")) ///
xlabel(0(.2)1) xtitle("Expected number of days of employment (out of 7)")
graph export "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/figures/hist_expected_jfp_baseline_fraction.png", replace



gen  temp1 = work_orig if recall_reliable == 1
replace temp1 = work1 if work_source_inperson == 1 & mi(temp1)
egen temp2 = total(temp1) , by(pid phase week_in) missing
egen work_wkly3 = max(temp2), by(pid phase week_in) //missing

drop temp*

cap drop jfp_above_mean jfp_above_median
su bs_dem_workdays_early_arr_frac if phase == 1 & week_in == 1 & dow == 1, d
di r(mean)
scalar jfp_early_mean = r(mean)
di r(p50)
scalar jfp_early_median = r(p50)
di scalar(jfp_early_mean)
di scalar(jfp_early_median)

gen jfp_above_mean = bs_dem_workdays_late_arr_frac> scalar(jfp_early_mean)
gen jfp_above_median = bs_dem_workdays_late_arr_frac> scalar(jfp_early_median)
gen treatXjfp_above_mean = treatment*jfp_above_mean if !mi(jfp_above_mean)
gen treatXjfp_above_median = treatment*jfp_above_median if !mi(jfp_above_mean)

la var jfp_above_mean "1(Exp. jfp at 8am $>$ mean)"
la var treatXjfp_above_mean "Treatment $\times$ 1(Exp. jfp $>$ mean)"
la var jfp_above_median "1(Exp. jfp at 8am $>$ median)"
la var treatXjfp_above_median "Treatment $\times$ 1(Exp. jfp $>$ median)"
eststo clear

	eststo a1: reg attend_nadj treatment treatXjfp_above_mean jfp_above_mean attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
		sum attend_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)	
	eststo a2: 
reg attend_and_before8_nadj treatment treatXjfp_above_mean jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
		sum attend_and_before8_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)	
	eststo a3: 
reg attend_nadj treatment treatXjfp_above_mean jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
		sum attend_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)	
		
	eststo a4: 
reg attend_and_before8_nadj treatment treatXjfp_above_mean jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum attend_and_before8_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)	
	eststo a5: 
	reg work_wkly3 treatment treatXjfp_above_mean jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum work_wkly3 if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)

esttab a1 a2 a3 a4 a5 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/tab_bl_jfp_het_above_mean.tex" , ///
    replace keep(treatment treatXjfp_above_mean jfp_above_mean) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes nonumbers mtitles("By 8" "Attend" "By 8" "Attend" "Work") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

eststo clear

	eststo a1: reg attend_nadj treatment treatXjfp_above_median jfp_above_median attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
		sum attend_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)	
	eststo a2: 
reg attend_and_before8_nadj treatment treatXjfp_above_median jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
		sum attend_and_before8_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)	
	eststo a3: 
reg attend_nadj treatment treatXjfp_above_median jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
		sum attend_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)	
		
	eststo a4: 
reg attend_and_before8_nadj treatment treatXjfp_above_median jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum attend_and_before8_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)	
	eststo a5: 
	
	reg work_wkly3 treatment treatXjfp_above_median jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum work_wkly3 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)	
		
esttab a1 a2 a3 a4 a5 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/tab_bl_jfp_het_above_median.tex" , ///
    replace keep(treatment treatXjfp_above_median jfp_above_median) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes nonumbers mtitles("By 8" "Attend" "By 8" "Attend" "Work") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

* Own beliefs
cap drop own_jfp_stand

unique pid if !mi(bs_dem_pred_look_stand)
// Number of unique values of pid is  216
unique pid if !mi(bs_dem_pred_find_stand)
// Number of unique values of pid is  216
* <FIXME> Why missing for 9 observations??

cap drop own_jfp_stand
gen own_jfp_stand = bs_dem_pred_find_stand / bs_dem_pred_look_stand
gen own_jfp = bs_dem_pred_find / bs_dem_pred_look

unique pid if own_jfp_stand> 1 & own_jfp_stand<.

* <FIXME> >1 for 7 pid --> for now leave missing
twoway (hist own_jfp_stand if phase == 1 & week_in == 1 & dow == 1 & own_jfp_stand<=1, width(.1) start(0) lcolor(gs12) fcolor(gs12) frac lw(thin)), ///
xlabel(0(.2)1) xtitle("Expected job finding probability when searching at stand")
graph export "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/figures/hist_expected_own_jfp_stand_baseline_fraction.png", replace

twoway (hist own_jfp if phase == 1 & week_in == 1 & dow == 1 & own_jfp<=1, width(.1) start(0) lcolor(gs12) fcolor(gs12) frac lw(thin)), ///
xlabel(0(.2)1) xtitle("Expected job finding probability when searching")
graph export "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/figures/hist_expected_own_jfp_baseline_fraction.png", replace


twoway (hist own_jfp if phase == 1 & week_in == 1 & dow == 1 & own_jfp<=1, width(.1) start(0) lcolor(gs12) fcolor(gs12) frac lw(thin)) || ///
(hist own_jfp_stand if phase == 1 & week_in == 1 & dow == 1 & own_jfp_stand<=1, width(.1) start(0) lcolor(red) fcolor(none) frac lw(thin))  , ///
xlabel(0(.2)1) xtitle("Expected job finding probability when searching")
graph export "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/figures/hist_expected_own_jfp_combined_baseline_fraction.png", replace



// legend(order(2 "Worker who arrives by 7:40 am" 1 "Worker who arrives by 9 am")) ///




su own_jfp_stand if own_jfp_stand<=1 & phase == 2 & week_in == 1 & dow == 2, d
scalar own_jfp_stand_mean = r(mean)
scalar own_jfp_stand_median = r(p50)
di scalar(own_jfp_stand_mean)
di scalar(own_jfp_stand_median)


cap drop own_jfp_above_median own_jfp_above_mean
gen own_jfp_above_median = own_jfp_stand> scalar(own_jfp_stand_median) if own_jfp_stand<=1
gen own_jfp_above_mean = own_jfp_stand> scalar(own_jfp_stand_mean) if own_jfp_stand<=1

cap drop treatXown_jfp*
gen treatXown_jfp_above_mean = treatment*own_jfp_above_mean 	if !mi(own_jfp_above_mean)
gen treatXown_jfp_above_median = treatment*own_jfp_above_median if !mi(own_jfp_above_median)

la var own_jfp_above_mean "1(Own exp. jfp$>$ mean)"
la var treatXown_jfp_above_mean "Treatment $\times$ 1(Own exp. jfp $>$ mean)"
la var own_jfp_above_median "1(Own exp. jfp$>$ median)"
la var treatXown_jfp_above_median "Treatment $\times$ 1(Own exp. jfp $>$ median)"

eststo clear


	eststo a1: reg attend_nadj treatment treatXown_jfp_above_median own_jfp_above_median attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
	
	eststo a2: 
reg attend_and_before8_nadj treatment treatXown_jfp_above_median own_jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)

	eststo a3: 
reg attend_nadj treatment treatXown_jfp_above_median own_jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	
	eststo a4: 
reg attend_and_before8_nadj treatment treatXown_jfp_above_median own_jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)

	eststo a5: 
reg work_wkly3 treatment treatXown_jfp_above_median own_jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)


esttab a1 a2 a3 a4 a5 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/tab_bl_own_jfp_het_above_median.tex" , ///
    replace keep(treatment treatXown_jfp_above_median own_jfp_above_median) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes nonumbers mtitles("By 8" "Attend" "By 8" "Attend" "Work") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

	eststo clear


	eststo a1: reg attend_nadj treatment treatXown_jfp_above_mean own_jfp_above_mean attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
	
	eststo a2: 
reg attend_and_before8_nadj treatment treatXown_jfp_above_mean own_jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)

	eststo a3: 
reg attend_nadj treatment treatXown_jfp_above_mean own_jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	
	eststo a4: 
reg attend_and_before8_nadj treatment treatXown_jfp_above_mean own_jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)

	eststo a5: 
reg work_wkly3 treatment treatXown_jfp_above_mean own_jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)


esttab a1 a2 a3 a4 a5 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/tab_bl_own_jfp_het_above_mean.tex" , ///
    replace keep(treatment treatXown_jfp_above_mean own_jfp_above_mean) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes nonumbers mtitles("By 8" "Attend" "By 8" "Attend" "Work") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

	
/*
Notes on variable definitions:
	- work_orig = daily-grid (≤7-day) recall only, in-person and phone
	- recall_reliable = 1 if that day's ≤7-day value came from an in-person survey, 0 if phone, . if no 7-day grid recall.
	- work1 = mean-imputed work, which equals work_orig on daily-grid days and the comp-recall mean fill otherwise.
	- work_source_inperson = 1/0 for in-person/phone from either the daily grid or the comprehensive recall.
*/

*****************************************
**# Job found at stand
*****************************************

gen 	job_at_stand1 = job_at_stand if work_orig == 1
replace job_at_stand1 = 0 if work_orig == 0 & recall_reliable == 1


	gen  temp1 = job_at_stand if recall_reliable == 1
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen job_at_stand_wkly = max(temp2), by(pid phase week_in)
	drop temp*

	gen  temp1 = job_at_stand if recall_reliable == 1
	replace temp1 = 0 if recall_reliable == 1 & work_orig == 0
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen job_at_stand_wkly1 = max(temp2), by(pid phase week_in)
	drop temp*

forv p = 1/2{
	eststo ph`p'_spec1: reg job_at_stand_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==`p', vce(cluster pid)
	sum job_at_stand_wkly if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

}

forv p = 1/2{
	eststo ph`p'_spec2: reg job_at_stand_wkly1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==`p', vce(cluster pid)
	sum job_at_stand_wkly1 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

}

	
esttab  ph1_spec2 ph2_spec2 ph1_spec1 ph2_spec1 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/tab_job_at_stand.tex" , ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats( y_mean N, labels("Control mean" "N: worker-weeks")) ///
    nonotes  nostar booktabs label mtitles("Phase 1" "Phase 2" "Phase 1" "Phase 2")  collabels(none) ///
    mgroups( "Job found at stand (uncond.)" "Job found at stand (cond. on work)", pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	
*****************************************
**# Work definitions
*****************************************		

	cap drop work_wkly?
	cap drop work_wkly?_adj
	cap drop temp*
eststo clear
	* Work 1 -- in person data from \leq7 day recall (current definition)

	gen  temp1 = work_orig  if recall_reliable == 1
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen work_wkly1 = max(temp2), by(pid phase week_in)
	
	drop temp*
	
	* Work 2 -- all data from \leq7 day recall (phone + in person)

	gen  temp1 = work_orig //if recall_reliable == 1
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen work_wkly2 = max(temp2), by(pid phase week_in)

	drop temp*

	
	* Work 3 -- all in person data (from \leq7 day recall + comprehensive)

	gen  temp1 = work_orig if recall_reliable == 1
	replace temp1 = work1 if work_source_inperson == 1 & mi(temp1)
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen work_wkly3 = max(temp2), by(pid phase week_in)

	drop temp*
	
	* Work 4 -- all data (from \leq7 day recall + comprehensive, phone + in person)

	gen  temp1 = work1
	replace temp1 = work1 if mi(temp1)
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen work_wkly4 = max(temp2), by(pid phase week_in)

	drop temp*

	eststo clear
	forv p = 1/2 {
		forv i = 1/4 {
		eststo ph`p'_v`i': reg work_wkly`i' treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==`p', vce(cluster pid)
		sum work_wkly`i' if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)
		if inlist("`i'", "1", "2") {
			estadd local recall = "$\leq$7"
		}
		else {
			estadd local recall = "Any lags"
		}
		if inlist("`i'", "1", "3") {
			estadd local source = "In person only"
		}
		else {
			estadd local source = "Incl. phone"
		}
		
		}
	}
	

esttab ph1_v1 ph1_v2 ph1_v3 ph1_v4 ph2_v1 ph2_v2 ph2_v3 ph2_v4 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/work_definition_robustness1.tex" , ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats( recall source y_mean N, labels("Recall lag" "Survey source" "Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes  nostar booktabs label nomtitles ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	
*****************************************
**# Work definitions (prorated)
*****************************************

	
	cap drop work_wkly?
	cap drop work_wkly?_adj
	cap drop temp*
eststo clear
	* Work 1 -- in person data from \leq7 day recall (current definition)

	gen  temp1 = work_orig  if recall_reliable == 1
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	// number of days non miss work per week
	egen temp3 = count(temp1) , by(pid phase week_in)
	egen work_wkly1 = max(temp2), by(pid phase week_in)
	gen work_wkly1_adj = work_wkly1*7/temp3
	
	drop temp*
	
	* Work 2 -- all data from \leq7 day recall (phone + in person)

	gen  temp1 = work_orig //if recall_reliable == 1
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen temp3 = count(temp1) , by(pid phase week_in)
	egen work_wkly2 = max(temp2), by(pid phase week_in)
	gen work_wkly2_adj = work_wkly2*7/temp3

	drop temp*

	
	* Work 3 -- all in person data (from \leq7 day recall + comprehensive)

	gen  temp1 = work_orig if recall_reliable == 1
	replace temp1 = work1 if work_source_inperson == 1 & mi(temp1)
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen temp3 = count(temp1) , by(pid phase week_in)
	egen work_wkly3 = max(temp2), by(pid phase week_in)
	gen work_wkly3_adj = work_wkly3*7/temp3

	drop temp*
	
	* Work 4 -- all data (from \leq7 day recall + comprehensive, phone + in person)

	gen  temp1 = work1
	replace temp1 = work1 if mi(temp1)
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen temp3 = count(temp1) , by(pid phase week_in)
	egen work_wkly4 = max(temp2), by(pid phase week_in)
	gen work_wkly4_adj = work_wkly4*7/temp3

	drop temp*

	eststo clear
	forv p = 1/2 {
		forv i = 1/4 {
		eststo ph`p'_v`i': reg work_wkly`i'_adj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==`p', vce(cluster pid)
		sum work_wkly`i'_adj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)
		if inlist("`i'", "1", "2") {
			estadd local recall = "$\leq$7"
		}
		else {
			estadd local recall = "Any lags"
		}
		if inlist("`i'", "1", "3") {
			estadd local source = "In person only"
		}
		else {
			estadd local source = "Incl. phone"
		}
		
		}
	}
	

esttab ph1_v1 ph1_v2 ph1_v3 ph1_v4 ph2_v1 ph2_v2 ph2_v3 ph2_v4 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/work_definition_robustness2.tex" , ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats( recall source y_mean N, labels("Recall lag" "Survey source" "Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes  nostar booktabs label nomtitles ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	
	
	
	
	
	
*****************************************
**#Non missing days (worker-day level)
*****************************************	

	** How many non missing for each regression?
	cap drop count_nm?
	* Work 1 -- in person data from \leq7 day recall (current definition)
	gen  count_nm1 = recall_reliable == 1 	//if !mi(recall_reliable)
	* Work 2 -- all data from \leq7 day recall (phone + in person)
	gen  count_nm2 = !mi(recall_reliable) 		//if !mi(recall_reliable)
	* Work 3 -- all in person data (from \leq7 day recall + comprehensive)
	gen  count_nm3 = work_source_inperson == 1 //if !mi(work_source_inperson)
	* Work 4 -- all data (from \leq7 day recall + comprehensive, phone + in person)
	gen  count_nm4 = !mi(work_source_inperson)				//if !mi(work_source_inperson)
	
	eststo clear
	forv p = 1/2 {
		forv i = 1/4 {
		eststo ph`p'_v`i': reg count_nm`i' treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==`p', vce(cluster pid)
		sum count_nm`i' if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)
			if inlist("`i'", "1", "2") {
				estadd local recall = "$\leq$7"
			}
			else {
				estadd local recall = "Any lags"
			}
			if inlist("`i'", "1", "3") {
				estadd local source = "In person only"
			}
			else {
				estadd local source = "Incl. phone"
			}
		}
	}
	

esttab ph1_v1 ph1_v2 ph1_v3 ph1_v4 ph2_v1 ph2_v2 ph2_v3 ph2_v4 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/work_def_missingness.tex" , ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats( recall source y_mean N , labels("Recall lag" "Survey source" "Control mean" "N: worker-days")) collabels(none) ///
    nonotes  nostar booktabs label nomtitles ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	
	* Only strata + stand FE
	eststo clear
	forv p = 1/2 {
		forv i = 1/4 {
		eststo ph`p'_v`i': reg count_nm`i' treatment  i.stand i.strata i.week_in i.calendar_week if phase==`p', vce(cluster pid)
		sum count_nm`i' if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)
			if inlist("`i'", "1", "2") {
				estadd local recall = "$\leq$7"
			}
			else {
				estadd local recall = "Any lags"
			}
			if inlist("`i'", "1", "3") {
				estadd local source = "In person only"
			}
			else {
				estadd local source = "Incl. phone"
			}
			
		}
	}
	

esttab ph1_v1 ph1_v2 ph1_v3 ph1_v4 ph2_v1 ph2_v2 ph2_v3 ph2_v4 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/work_def_missingness_nocontrols.tex" , ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats( recall source y_mean N , labels("Recall lag" "Survey source" "Control mean" "N: worker-days")) collabels(none) ///
    nonotes  nostar booktabs label nomtitles ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	

*****************************************
**#Non missing days (worker-phase level)
*****************************************	

	cap drop count_tot_nm?
	* Work 1 -- in person data from \leq7 day recall (current definition)
	egen  count_tot_nm1 = total(recall_reliable == 1), by(phase pid) //if !mi(recall_reliable)
	* Work 2 -- all data from \leq7 day recall (phone + in person)
	egen  count_tot_nm2 = total(!mi(recall_reliable)) , by(phase pid)		//if !mi(recall_reliable)
	* Work 3 -- all in person data (from \leq7 day recall + comprehensive)
	egen  count_tot_nm3 = total(work_source_inperson == 1), by(phase pid) //if !mi(work_source_inperson)
	* Work 4 -- all data (from \leq7 day recall + comprehensive, phone + in person)
	egen  count_tot_nm4 = total(!mi(work_source_inperson)), by(phase pid)				//if !mi(work_source_inperson)
	
	eststo clear
	forv p = 1/2 {
		forv i = 1/4 {
		eststo ph`p'_v`i': reg count_tot_nm`i' treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata if phase==`p' & week_in == 1 & dow == 2, vce(robust)
		sum count_tot_nm`i' if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)
			if inlist("`i'", "1", "2") {
				estadd local recall = "$\leq$7"
			}
			else {
				estadd local recall = "Any lags"
			}
			if inlist("`i'", "1", "3") {
				estadd local source = "In person only"
			}
			else {
				estadd local source = "Incl. phone"
			}
		}
	}
	

esttab ph1_v1 ph1_v2 ph1_v3 ph1_v4 ph2_v1 ph2_v2 ph2_v3 ph2_v4 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/work_def_missingness_tot_days.tex" , ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats( recall source y_mean N , labels("Recall lag" "Survey source" "Control mean" "N: workers")) collabels(none) ///
    nonotes  nostar booktabs label nomtitles ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

	* No controls

	eststo clear
	forv p = 1/2 {
		forv i = 1/4 {
		eststo ph`p'_v`i': reg count_tot_nm`i' treatment i.stand i.strata if phase==`p' & week_in == 1 & dow == 2, vce(robust)
		sum count_tot_nm`i' if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)
			if inlist("`i'", "1", "2") {
				estadd local recall = "$\leq$7"
			}
			else {
				estadd local recall = "Any lags"
			}
			if inlist("`i'", "1", "3") {
				estadd local source = "In person only"
			}
			else {
				estadd local source = "Incl. phone"
			}
			
		}
	}
	

esttab ph1_v1 ph1_v2 ph1_v3 ph1_v4 ph2_v1 ph2_v2 ph2_v3 ph2_v4 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/work_def_missingness_tot_days_nocontrols.tex" , ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats( recall source y_mean N , labels("Recall lag" "Survey source" "Control mean" "N: workers")) collabels(none) ///
    nonotes  nostar booktabs label nomtitles ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	
	
	
	
*****************************************
**# Labor supply alt. (attend or work)
*****************************************	
	
	cap drop ls?
	cap drop temp*
eststo clear
	
	* Ls 1
	gen temp1=attend
	replace temp1=work_orig if recall_reliable == 1 & temp1 == 0
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen ls1 = max(temp2), by(pid phase week_in)
	drop temp*
	
	* Work 2 -- all data from \leq7 day recall (phone + in person)

	gen  temp1 = attend
	replace  temp1 = work_orig if temp1 == 0 & !mi(work_orig)
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen ls2 = max(temp2), by(pid phase week_in)

	drop temp*

	
	* Work 3 -- all in person data (from \leq7 day recall + comprehensive)
	gen  temp1 = attend
	replace  temp1 = work1 if work_source_inperson == 1 & temp1 == 0
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen ls3 = max(temp2), by(pid phase week_in)
	drop temp*
	
	* Work 4 -- all data (from \leq7 day recall + comprehensive, phone + in person)

	gen  temp1 = attend
	replace temp1 = work1 if temp1 == 0 & !mi(work1)
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen ls4 = max(temp2), by(pid phase week_in)

	drop temp*
	
	eststo clear
	forv p = 1/2 {
		forv i = 1/4 {
		eststo ph`p'_v`i': reg ls`i' treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==`p', vce(cluster pid)
		sum ls`i' if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)
		if inlist("`i'", "1", "2") {
			estadd local recall = "$\leq$7"
		}
		else {
			estadd local recall = "Any lags"
		}
		if inlist("`i'", "1", "3") {
			estadd local source = "In person only"
		}
		else {
			estadd local source = "Incl. phone"
		}
		
		
		}
	}
	
esttab ph1_v1 ph1_v2 ph1_v3 ph1_v4 ph2_v1 ph2_v2 ph2_v3 ph2_v4 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/work_definition_ls.tex" , ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats( recall source y_mean N, labels("Recall lag" "Survey source" "Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes  nostar booktabs label nomtitles ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

	* Exclude Sundays
	cap drop ls?_nosun
	cap drop temp*
eststo clear
	
	* Ls 1
	gen temp1=attend
	replace temp1=work_orig if recall_reliable == 1 & temp1 == 0 & dow!=0 & holiday == 0
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen ls1_nosun = max(temp2), by(pid phase week_in)
	drop temp*
	
	* Work 2 -- all data from \leq7 day recall (phone + in person)

	gen  temp1 = attend
	replace  temp1 = work_orig if temp1 == 0 & !mi(work_orig) & dow!=0 & holiday == 0
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen ls2_nosun = max(temp2), by(pid phase week_in)

	drop temp*

	
	* Work 3 -- all in person data (from \leq7 day recall + comprehensive)
	gen  temp1 = attend
	replace  temp1 = work1 if work_source_inperson == 1 & temp1 == 0 & dow!=0  & holiday == 0
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen ls3_nosun = max(temp2), by(pid phase week_in)
	drop temp*
	
	* Work 4 -- all data (from \leq7 day recall + comprehensive, phone + in person)

	gen  temp1 = attend
	replace temp1 = work1 if temp1 == 0 & !mi(work1) & dow!=0  & holiday == 0
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen ls4_nosun = max(temp2), by(pid phase week_in)

	drop temp*
	
	eststo clear
	forv p = 1/2 {
		forv i = 1/4 {
		eststo ph`p'_v`i': reg ls`i'_nosun treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==`p', vce(cluster pid)
		sum ls`i'_nosun if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)
		if inlist("`i'", "1", "2") {
			estadd local recall = "$\leq$7"
		}
		else {
			estadd local recall = "Any lags"
		}
		if inlist("`i'", "1", "3") {
			estadd local source = "In person only"
		}
		else {
			estadd local source = "Incl. phone"
		}
		
		}
	}
	
esttab ph1_v1 ph1_v2 ph1_v3 ph1_v4 ph2_v1 ph2_v2 ph2_v3 ph2_v4 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/work_definition_ls_nosun.tex" , ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats( recall source y_mean N, labels("Recall lag" "Survey source" "Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes  nostar booktabs label nomtitles ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	

	
** TABLE 1
lab var work1_nadj "Work, Mean Impute"
lab var work_nadj  "Work, Rand Impute"

eststo clear
eststo a1: reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum attend_nadj if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo b1: reg attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum attend_and_before8_nadj if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a2: reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum attend_nadj if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo b2: reg attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum attend_and_before8_nadj if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo d2: reg work_wkly3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum work_wkly3 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

esttab b1 a1 b2 a2 d2 using  "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/table1.tex" , ///, ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes nonumbers mtitles("By 8" "Attend" "By 8" "Attend" "Work") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

	
** TABLE 1 -- Poisson
lab var work1_nadj "Work, Mean Impute"
lab var work_nadj  "Work, Rand Impute"

eststo clear
eststo a1: poisson attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum attend_nadj if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo b1: poisson attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum attend_and_before8_nadj if treatment==0 & e(sample)                  
estadd scalar y_mean=r(mean)

eststo a2: poisson attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum attend_nadj if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo b2: poisson attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum attend_and_before8_nadj if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo d2: poisson work_wkly3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum work_wkly3 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

esttab b1 a1 b2 a2 d2 using  "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/table1-poisson.tex" , ///, ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes nonumbers mtitles("By 8" "Attend" "By 8" "Attend" "Work") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))


** Other employment robustness
lab var work1_nadj "Work, Mean Impute"
lab var work_nadj  "Work, Rand Impute"


* Self-employment

gen temp1 = main_act_self_employed if recall_reliable == 1
egen temp2 = total(temp1) , by(pid phase week_in) missing
egen self_emp_wkly = max(temp2), by(pid phase week_in)
drop temp*


eststo clear
eststo a2_p1: reg job_at_stand_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum job_at_stand_wkly if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a1_p1: reg job_at_stand_wkly1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum job_at_stand_wkly1 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a3_p1: reg ls3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum ls3 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a4_p1: reg self_emp_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum self_emp_wkly if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a2_p2: reg job_at_stand_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum job_at_stand_wkly if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a1_p2: reg job_at_stand_wkly1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum job_at_stand_wkly1 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a3_p2: reg ls3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum ls3 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a4_p2: reg self_emp_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum self_emp_wkly if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

esttab a1_p1 a2_p1 a3_p1 a4_p2 a1_p2 a2_p2 a3_p2 a4_p2 using  "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/other_employment.tex" , ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes nonumbers mtitles("Job at stand (uncond.)" "Job at stand (cond.)" "Attend or work" "Self-employment" "Job at stand (uncond.)" "Job at stand (cond.)" "Attend or work" "Self-employment") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 0 0 1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

		
	/*mtitles("$\leq$7 day, in person" "$\leq$7 day, incl. phone" "Any lag, in person" "Any lag, incl. phone" "$\leq$7 day, in person" "$\leq$7 day, incl. phone" "Any lag, in person" "Any lag, incl. phone")*/

eststo clear
eststo a2_p1: poisson job_at_stand_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum job_at_stand_wkly if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a1_p1: poisson job_at_stand_wkly1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum job_at_stand_wkly1 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a3_p1: poisson ls3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum ls3 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

// eststo a4_p1: poisson self_emp_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
// sum self_emp_wkly if treatment==0 & e(sample)
// estadd scalar y_mean=r(mean)

eststo a2_p2: poisson job_at_stand_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum job_at_stand_wkly if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a1_p2: poisson job_at_stand_wkly1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum job_at_stand_wkly1 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a3_p2: poisson ls3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum ls3 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

// eststo a4_p2: poisson self_emp_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
// sum self_emp_wkly if treatment==0 & e(sample)
// estadd scalar y_mean=r(mean)

esttab a1_p1 a2_p1 a3_p1  a1_p2 a2_p2 a3_p2 using  "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/other_employment.tex" , ///, ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes nonumbers mtitles("Job at stand (uncond.)" "Job at stand (cond.)" "Attend or work" "Self-employment" "Job at stand (uncond.)" "Job at stand (cond.)" "Attend or work" "Self-employment") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 0 0 1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

		
	/*mtitles("$\leq$7 day, in person" "$\leq$7 day, incl. phone" "Any lag, in person" "Any lag, incl. phone" "$\leq$7 day, in person" "$\leq$7 day, incl. phone" "Any lag, in person" "Any lag, incl. phone")*/
