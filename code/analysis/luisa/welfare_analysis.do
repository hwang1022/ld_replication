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
	
	gen actual_bs_attend_scale = bs_sum_attend * 6/8
	cap drop y
	gen y = bs_dem_pred_look_stand
	twoway (scatter bs_dem_pred_look_stand actual_bs_attend_scale if phase == 1 & week_in == 1 & dow == 1, jitter(3)) ///
	(lfit bs_dem_pred_look_stand y if phase == 1 & week_in == 1 & dow == 1), ///
	legend(off) ytitle("Predicted attendance") xtitle("Actual attendance" "Days (out of 6)")
	
	twoway (hist bs_dem_pred_look_stand  if phase == 1 & week_in == 1 & dow == 1,  start(0) width(1) lcolor(gs12) fcolor(gs12%60)) ///
	(hist actual_bs_attend_scale  if phase == 1 & week_in == 1 & dow == 1, start(0) width(1)  lcolor(red) fcolor(none)), ///
	legend(order(1 "Predicted attendance" 2 "Actual attendance") ring(0) pos(11) col(1)) ///
	xtitle("Days (out of 6)")
	
	
	* Merge 
	
	
	merge m:1 pid using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/02. Cleaning Data/06a. Phase 2 Activities/02. Output/03a_phase2act_vignettes_makevar.dta", nogen
	
	
	reg l_life_satisfaction_ladder treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata if phase == 1 & week_in == 1 & dow == 1, vce(robust)
	reg l_life_satisfaction_overall treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata if phase == 1 & week_in == 1 & dow == 1, vce(robust)
	reg l_how_satisfed_with_current_work treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata if phase == 1 & week_in == 1 & dow == 1, vce(robust)
	
	
	distplot l_life_satisfaction_ladder if phase == 1 & week_in == 1 & dow == 1, over(treatment)
	distplot l_life_satisfaction_overall if phase == 1 & week_in == 1 & dow == 1, over(treatment)
	distplot l_how_satisfed_with_current_work if phase == 1 & week_in == 1 & dow == 1, over(treatment)
	
	
	replace e_how_satisfied_work_actual = . if e_how_satisfied_work_actual == 999
	distplot e_how_satisfied_work_actual if phase == 1 & week_in == 1 & dow == 1, over(treatment)
	reg e_how_satisfied_work_actual treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata if phase == 1 & week_in == 1 & dow == 1, vce(robust)
	
	su e_how_satisfied_work_actual if phase == 1 & week_in == 1 & dow == 1, d
	gen above_mean_sat = e_how_satisfied_work_actual>r(mean) if !mi(e_how_satisfied_work_actual)
	gen above_median_sat = e_how_satisfied_work_actual>r(p50) if !mi(e_how_satisfied_work_actual)
	gen not_satisfied = e_how_satisfied_work_actual<r(p25) if !mi(e_how_satisfied_work_actual)
	
	reg e_how_satisfied_work_actual treatment  i.stand i.strata if phase == 1 & week_in == 1 & dow == 1, vce(robust)
	reg above_median_sat treatment  i.stand i.strata if phase == 1 & week_in == 1 & dow == 1, vce(robust)
	reg not_satisfied treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata if phase == 1 & week_in == 1 & dow == 1, vce(robust)

	
	reg e_did_you_refuse treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata if phase == 1 & week_in == 1 & dow == 1, vce(robust)
	reg e_unique_employers_job_obtained treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata if phase == 1 & week_in == 1 & dow == 1, vce(robust)
	reg e_how_many_days_out_of_7 treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata if phase == 1 & week_in == 1 & dow == 1, vce(robust)
	reg cog_rearrange_to_go treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata if phase == 1 & week_in == 1 & dow == 1, vce(robust)
	reg rearrange_to_go_d_l treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata if phase == 1 & week_in == 1 & dow == 1, vce(robust)
	
twoway (hist bs_dem_pred_look_stand if phase == 1 & week_in == 1 & dow == 1,  lcolor(gs12) fcolor(gs12%60) frac discrete lw(thin)), ///
legend(off) ///
xlabel(0(1)7) xtitle("Expected number of days of employment (out of 7)")
graph export "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/figures/hist_expected_jfp_baseline_days.png", replace

qui su bs_dem_workdays_early_arr_frac if phase == 1 & week_in == 1 & dow == 1, d
local mean_early : di %3.2fc r(mean)
local median_early : di %3.2fc r(p50)
qui su bs_dem_workdays_late_arr_frac if phase == 1 & week_in == 1 & dow == 1, d
local mean_late : di %3.2fc r(mean)
local median_late : di %3.2fc r(p50)
twoway (hist bs_dem_workdays_late_arr_frac if phase == 1 & week_in == 1 & dow == 1, width(.2) start(0) lcolor(gs12) fcolor(gs12%60) frac lw(thin)) || ///
(hist bs_dem_workdays_early_arr_frac if phase == 1 & week_in == 1 & dow == 1, width(.2) start(0) lcolor(red) fcolor(none) frac lw(thin)), ///
legend(order(2 "Worker who arrives at 7:40 am" 1 "Worker who arrives at 9 am")) ///
xlabel(0(.2)1.1) xtitle("Expected proportion of days of employment by arrival time") ///
note("Mean (median) early: `mean_early' (`median_early')" "Mean (median) late  : `mean_late' (`median_late')")
graph export "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/figures/hist_expected_jfp_baseline_fraction.png", replace


gen  temp1 = work_orig if recall_reliable == 1
replace temp1 = work1 if work_source_inperson == 1 & mi(temp1)
egen temp2 = total(temp1) , by(pid phase week_in) missing
egen work_wkly3 = max(temp2), by(pid phase week_in) //missing

drop temp*

cap drop jfp_above_mean jfp_above_median
cap drop treatXjfp_*
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
	
eststo a2: reg attend_and_before8_nadj treatment treatXjfp_above_mean jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
		sum attend_and_before8_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)	
	
eststo a3: reg attend_nadj treatment treatXjfp_above_mean jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum attend_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)	
		
eststo a4: reg attend_and_before8_nadj treatment treatXjfp_above_mean jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum attend_and_before8_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)	
	
eststo a5: 	reg work_wkly3 treatment treatXjfp_above_mean jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum work_wkly3 if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)

esttab a2 a1 a3 a4 a5 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/tab_bl_jfp_het_above_mean.tex" , ///
    replace keep(treatment treatXjfp_above_mean jfp_above_mean) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes nonumbers mtitles("By 8" "Attend" "By 8" "Attend" "Work") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

eststo clear

eststo a1: reg attend_nadj treatment treatXjfp_above_median jfp_above_median attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
		sum attend_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)	
	
eststo a2: reg attend_and_before8_nadj treatment treatXjfp_above_median jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
		sum attend_and_before8_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)	
	
	
eststo a3: reg attend_nadj treatment treatXjfp_above_median jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
		sum attend_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)	
		
eststo a4: reg attend_and_before8_nadj treatment treatXjfp_above_median jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum attend_and_before8_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)	
	
eststo a5: reg work_wkly3 treatment treatXjfp_above_median jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum work_wkly3 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)	
		
esttab a2 a1 a3 a4 a5 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/tab_bl_jfp_het_above_median.tex" , ///
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

cap drop own_jfp_stand own_jfp
gen own_jfp_stand = bs_dem_pred_find_stand / bs_dem_pred_look_stand
gen own_jfp = bs_dem_pred_find / bs_dem_pred_look

unique pid if own_jfp_stand> 1 & own_jfp_stand<.


* <FIXME> >1 for 7 pid --> for now leave missing
twoway (hist own_jfp if phase == 1 & week_in == 1 & dow == 1 & own_jfp<=1, width(.1) start(0) lcolor(gs12) fcolor(gs12%60) frac lw(thin)), ///
xlabel(0(.2)1) xtitle("Exp. job finding probability: days of employment out of days of search")
graph export "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/figures/hist_expected_own_jfp_baseline_fraction.png", replace

twoway (hist own_jfp_stand if phase == 1 & week_in == 1 & dow == 1 & own_jfp_stand<=1, width(.1) start(0) lcolor(gs12) fcolor(gs12) frac lw(thin)), ///
xlabel(0(.2)1) xtitle("Exp. job finding probability: days of employment out of days of search at stand")
graph export "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/figures/hist_expected_own_jfp_stand_baseline_fraction.png", replace

qui su own_jfp if phase == 1 & week_in == 1 & dow == 1 & own_jfp <=1, d
local mean_overall : di %3.2fc r(mean)
local median_overall : di %3.2fc r(p50)
qui su own_jfp_stand if phase == 1 & week_in == 1 & dow == 1 & own_jfp_stand <=1, d
local mean_stand: di %3.2fc r(mean)
local median_stand : di %3.2fc r(p50)

twoway (hist own_jfp if phase == 1 & week_in == 1 & dow == 1 & own_jfp<=1, width(.1) start(0) lcolor(gs12) fcolor(gs12%60) frac lw(thin)) || ///
(hist own_jfp_stand if phase == 1 & week_in == 1 & dow == 1 & own_jfp_stand<=1, width(.1) start(0) lcolor(red) fcolor(none) frac lw(thin))  , ///
xlabel(0(.2)1) xtitle("Exp. job finding probability: days of employment out of days of search") ///
legend(order(- "Job finding probability:" 1 "Unconditional" 2 "At stand") ring(0) pos(11) col(1)) ///
note("Mean (median) overall: `mean_overall' (`median_overall')" "Mean (median) stand  : `mean_stand' (`median_stand')")
graph export "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/figures/hist_expected_own_jfp_combined_baseline_fraction.png", replace



// legend(order(2 "Worker who arrives by 7:40 am" 1 "Worker who arrives by 9 am")) ///




su own_jfp_stand if own_jfp_stand<=1 & phase == 2 & week_in == 1 & dow == 2, d
scalar own_jfp_stand_median = r(p50)
scalar own_jfp_stand_mean = r(mean)

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
	sum attend_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)	
		
eststo a2: reg attend_and_before8_nadj treatment treatXown_jfp_above_median own_jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
	sum attend_and_before8_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)	
	
eststo a3: reg attend_nadj treatment treatXown_jfp_above_median own_jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum attend_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)	
	
eststo a4: reg attend_and_before8_nadj treatment treatXown_jfp_above_median own_jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum attend_and_before8_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)	

eststo a5: reg work_wkly3 treatment treatXown_jfp_above_median own_jfp_above_median  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum work_wkly3 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)	

esttab a1 a2 a3 a4 a5 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/tab_bl_own_jfp_het_above_median.tex" , ///
    replace keep(treatment treatXown_jfp_above_median own_jfp_above_median) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes nonumbers mtitles("By 8" "Attend" "By 8" "Attend" "Work") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

eststo clear

eststo a1: reg attend_nadj treatment treatXown_jfp_above_mean own_jfp_above_mean attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
	sum attend_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)	

	eststo a2: reg attend_and_before8_nadj treatment treatXown_jfp_above_mean own_jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
	sum attend_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)	
	
eststo a3: reg attend_nadj treatment treatXown_jfp_above_mean own_jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum attend_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)	

	eststo a4: reg attend_and_before8_nadj treatment treatXown_jfp_above_mean own_jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum attend_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)	

	eststo a5: reg work_wkly3 treatment treatXown_jfp_above_mean own_jfp_above_mean  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum work_wkly3 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)	

esttab a1 a2 a3 a4 a5 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/tab_bl_own_jfp_het_above_mean.tex" , ///
    replace keep(treatment treatXown_jfp_above_mean own_jfp_above_mean) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes nonumbers mtitles("By 8" "Attend" "By 8" "Attend" "Work") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
