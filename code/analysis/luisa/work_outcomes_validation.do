 ************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Replicate the main paper analysis using HW's new dataset
* 	Author:				HW 
* 	Last modified:		2026-June-06 (HW)
************************************************************
************************************************************


****
**## 0. Call Data
****

	use "/Users/`c(username)'/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/code/analysis/luisa/final_data_prioritize_in_person.dta" , clear

lab var work1_nadj "Work, Mean Impute"
lab var work_nadj  "Work, Rand Impute"

assert (work_source_inperson == . & work == .) | (work_source_inperson != . & work != .) | phase == 0

/* Note! No comprehensive recall in Phase 0!! (baseline)*/

	
/*
Notes on variable definitions:
	- work_orig = daily-grid (≤7-day) recall only, in-person and phone
	- recall_reliable = 1 if that day's ≤7-day value came from an in-person survey, 0 if phone, . if no 7-day grid recall.
	- work1 = mean-imputed work, which equals work_orig on daily-grid days and the comp-recall mean fill otherwise.
	- work_source_inperson = 1/0 for in-person/phone from either the daily grid or the comprehensive recall.
*/

****
**## * 1. Define weekly variables
****

** 1.1 New work definition
	gen  temp1 = work_orig if recall_reliable == 1
	replace temp1 = work1 if work_source_inperson == 1 & mi(temp1)
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen work_wkly3 = max(temp2), by(pid phase week_in)
	drop temp*
** 1.2 Job found at stand -- unconditional on working
	* Note: currently job_at_stand only defined if work = 1
	gen 	job_at_stand1 = job_at_stand if work_orig == 1
	replace job_at_stand1 = 0 if work_orig == 0 & recall_reliable == 1
	
	gen  temp1 = job_at_stand if recall_reliable == 1
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen job_at_stand_wkly = max(temp2), by(pid phase week_in)
	drop temp*	
	
	gen  temp1 = job_at_stand1 if recall_reliable == 1
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen job_at_stand_wkly1 = max(temp2), by(pid phase week_in)
	drop temp*
** 1.3 Labor supply (attend or work)
	gen  temp1 = attend
	replace  temp1 = work1 if work_source_inperson == 1 & temp1 == 0
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen ls3 = max(temp2), by(pid phase week_in)
	drop temp*
** 1.4 Self-employment
	gen temp1 = main_act_self_employed if recall_reliable == 1
	egen temp2 = total(temp1) , by(pid phase week_in) missing
	egen self_emp_wkly = max(temp2), by(pid phase week_in)
	drop temp*

****
**## * 2. Table 1
****

** 2.1 Table 1 - OLS regression
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

	
** 2.2 Table 1 - Poisson regression
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


****
**## * 3. Other work outcomes table
****
	
	
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

// eststo a4_p1: reg self_emp_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
// sum self_emp_wkly if treatment==0 & e(sample)
// estadd scalar y_mean=r(mean)

eststo a2_p2: reg job_at_stand_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum job_at_stand_wkly if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a1_p2: reg job_at_stand_wkly1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum job_at_stand_wkly1 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a3_p2: reg ls3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum ls3 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

// eststo a4_p2: reg self_emp_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
// sum self_emp_wkly if treatment==0 & e(sample)
// estadd scalar y_mean=r(mean)

esttab a1_p1 a2_p1 a3_p1  a1_p2 a2_p2 a3_p2 using  "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/other_employment.tex" , ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes mtitles("Job at stand (uncond.)" "Job at stand (cond.)" "Attend or work" "Job at stand (uncond.)" "Job at stand (cond.)" "Attend or work") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

eststo clear
eststo a1_p1: poisson job_at_stand_wkly1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum job_at_stand_wkly1 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a2_p1: poisson job_at_stand_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum job_at_stand_wkly if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a3_p1: poisson ls3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum ls3 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

// eststo a4_p1: poisson self_emp_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
// sum self_emp_wkly if treatment==0 & e(sample)
// estadd scalar y_mean=r(mean)

eststo a1_p2: poisson job_at_stand_wkly1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum job_at_stand_wkly1 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a2_p2: poisson job_at_stand_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum job_at_stand_wkly if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

eststo a3_p2: poisson ls3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum ls3 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)

// eststo a4_p2: poisson self_emp_wkly treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
// sum self_emp_wkly if treatment==0 & e(sample)
// estadd scalar y_mean=r(mean)

esttab a1_p1 a2_p1 a3_p1  a1_p2 a2_p2 a3_p2 using  "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/other_employment-poisson.tex" , ///, ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes  mtitles("Job at stand (uncond.)" "Job at stand (cond.)" "Attend or work" "Self-employment" "Job at stand (uncond.)" "Job at stand (cond.)" "Attend or work" "Self-employment") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 0  1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))


* Job at stand -  daily regression
	
eststo clear
	
	
eststo a1: reg job_at_stand1 treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1 & recall_reliable == 1, vce(cluster pid)
sum job_at_stand1 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)	

eststo a2: reg job_at_stand treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1 & recall_reliable == 1, vce(cluster pid)
sum job_at_stand if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)
		
eststo a3: reg job_at_stand1 treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2 & recall_reliable == 1, vce(cluster pid)
sum job_at_stand1 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)	

eststo a4: reg job_at_stand treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2 & recall_reliable == 1, vce(cluster pid)
sum job_at_stand1 if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)


esttab a1 a2 a3 a4 using  "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/job_at_stand_daily_regression.tex" , ///, ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
    nonotes  mtitles("Job at stand (uncond.)" "Job at stand (cond.)" "Job at stand (uncond.)" "Job at stand (cond.)") nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

****
**## * 3. Missing analysis
****
cap drop notmi_work
gen  notmi_work = work_source_inperson == 1 //if !mi(work_source_inperson)


eststo clear
eststo a1: reg notmi_work treatment if phase==1, vce(cluster pid)
sum notmi_work if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)	
estadd local c1 "No"
estadd local c2 "No"
estadd local c3 "No"

eststo a2: reg notmi_work treatment i.stand i.strata if phase==1, vce(cluster pid)
sum notmi_work if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)	
estadd local c1 "Yes"
estadd local c2 "No"
estadd local c3 "No"

eststo a3: reg notmi_work treatment  i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum notmi_work if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)	
estadd local c1 "Yes"
estadd local c2 "Yes"
estadd local c3 "No"

eststo a4: reg notmi_work treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum notmi_work if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)
estadd local c1 "Yes"
estadd local c2 "Yes"
estadd local c3 "Yes"

eststo a5: reg notmi_work treatment if phase==2, vce(cluster pid)
sum notmi_work if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)	
estadd local c1 "No"
estadd local c2 "No"
estadd local c3 "No"

eststo a6: reg notmi_work treatment i.stand i.strata if phase==2, vce(cluster pid)
sum notmi_work if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)	
estadd local c1 "Yes"
estadd local c2 "No"
estadd local c3 "No"

eststo a7: reg notmi_work treatment  i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum notmi_work if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)	
estadd local c1 "Yes"
estadd local c2 "Yes"
estadd local c3 "No"

eststo a8: reg notmi_work treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum notmi_work if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)
estadd local c1 "Yes"
estadd local c2 "Yes"
estadd local c3 "Yes"
	
	
	

esttab a1 a2 a3 a4 a5 a6 a7 a8 using  "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/work_missingness.tex" , ///, ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean c1 c2 c3 N, labels("Control mean" "Stand+Strata FEs" "Time (study+cal.) FEs" "Baseline controls" "N: worker-weeks")) collabels(none) ///
    nonotes  nomtitles nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))



cap drop notmi_job_at_stand
gen temp1 = job_at_stand1 if recall_reliable == 1
gen notmi_job_at_stand = !mi(temp1)
drop temp1

eststo clear
eststo a1: reg notmi_job_at_stand treatment if phase==1, vce(cluster pid)
sum notmi_job_at_stand if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)	
estadd local c1 "No"
estadd local c2 "No"
estadd local c3 "No"

eststo a2: reg notmi_job_at_stand treatment i.stand i.strata if phase==1, vce(cluster pid)
sum notmi_job_at_stand if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)	
estadd local c1 "Yes"
estadd local c2 "No"
estadd local c3 "No"

eststo a3: reg notmi_job_at_stand treatment  i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum notmi_job_at_stand if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)	
estadd local c1 "Yes"
estadd local c2 "Yes"
estadd local c3 "No"

eststo a4: reg notmi_job_at_stand treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1, vce(cluster pid)
sum notmi_job_at_stand if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)
estadd local c1 "Yes"
estadd local c2 "Yes"
estadd local c3 "Yes"

eststo a5: reg notmi_job_at_stand treatment if phase==2, vce(cluster pid)
sum notmi_job_at_stand if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)	
estadd local c1 "No"
estadd local c2 "No"
estadd local c3 "No"

eststo a6: reg notmi_job_at_stand treatment i.stand i.strata if phase==2, vce(cluster pid)
sum notmi_job_at_stand if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)	
estadd local c1 "Yes"
estadd local c2 "No"
estadd local c3 "No"

eststo a7: reg notmi_job_at_stand treatment  i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum notmi_job_at_stand if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)	
estadd local c1 "Yes"
estadd local c2 "Yes"
estadd local c3 "No"

eststo a8: reg notmi_job_at_stand treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
sum notmi_job_at_stand if treatment==0 & e(sample)
estadd scalar y_mean=r(mean)
estadd local c1 "Yes"
estadd local c2 "Yes"
estadd local c3 "Yes"
	
	
	

esttab a1 a2 a3 a4 a5 a6 a7 a8 using  "/Users/`c(username)'/Library/CloudStorage/Dropbox/Apps/Overleaf/LD_shocks/tables/job_at_stand_missingness.tex" , ///, ///
    replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    stats(y_mean c1 c2 c3 N, labels("Control mean" "Stand+Strata FEs" "Time (study+cal.) FEs" "Baseline controls" "N: worker-weeks")) collabels(none) ///
    nonotes  nomtitles nostar booktabs label ///
    mgroups("Phase 1" "Phase 2", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

	merge m:1 pid week_in using "${replication_dir}/code/analysis/simon/extra_data/phase1_incentive_survey_vs_record_makevar.dta", gen(incentive_merge)

	keep if phase == 1 & inlist(dow, 1, 2)

	bys pid week_in: egen mean_attend = mean(attend)
	bys pid week_in: egen temp = mean(work) if recall_reliable == 1
	bys pid week_in: egen mean_work = max(temp)
	drop temp
	
	bys pid week_in: egen temp = mean(job_at_stand1) if recall_reliable == 1
	bys pid week_in: egen mean_job_at_stand = max(temp)
	drop temp
	
	
	keep if dow == 1
	
	cap drop allotted_above_*
	su amount_allotted if treatment == 0, d
	gen allotted_above_mean = amount_allotted>r(mean) if !mi(amount_allotted)
	gen allotted_above_median = amount_allotted>r(p50) if !mi(amount_allotted)
	
	
xtset pid week_in
gen amount_allottedL1 = l.amount_allotted
gen amount_paidL1 = l.amount_payed
gen allotted_above_meanL1 = l.allotted_above_mean
gen allotted_above_medianL1 = l.allotted_above_median
	
ivreg2 mean_attend (amount_paidL1 = amount_allottedL1) i.stand i.week_in i.calendar_week if treatment == 0 & dow == 1, first
ivreg2 mean_work (amount_paidL1 = amount_allottedL1) i.stand i.week_in i.calendar_week if treatment == 0 & dow == 1, first
ivreg2 work1 (amount_paidL1 = amount_allottedL1) i.stand i.week_in i.calendar_week i.pid if treatment == 0 & dow == 1, first
	
	
	
	
	xtset pid week_in
	
	xtreg mean_attend allotted_above_meanL1 i.week_in i.calendar_week if treatment == 0, fe
	xtreg mean_work allotted_above_meanL1 i.week_in i.calendar_week if treatment == 0, fe
	
	xtreg mean_attend allotted_above_medianL1 i.week_in i.calendar_week if treatment == 0, fe
	xtreg mean_work allotted_above_medianL1 i.week_in i.calendar_week if treatment == 0, fe
	
	reg attend allotted_above_meanL1 i.week_in i.calendar_week if treatment == 0, vce(cluster pid)
	reg attend allotted_above_medianL1 i.week_in i.calendar_week if treatment == 0, vce(cluster pid)
	
	reg work allotted_above_meanL1 i.week_in i.calendar_week if treatment == 0, vce(cluster pid)
	reg work allotted_above_medianL1 i.week_in i.calendar_week if treatment == 0, vce(cluster pid)
	
	reg work allotted_above_meanL1 bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if treatment == 0 & recall_reliable == 1, vce(cluster pid)
	reg work allotted_above_medianL1 bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if treatment == 0 & recall_reliable == 1, vce(cluster pid)
	
	reg work allotted_above_meanL1 i.week_in i.calendar_week if treatment == 0 & recall_reliable == 1, vce(cluster pid)
	reg work allotted_above_medianL1 i.week_in i.calendar_week if treatment == 0 & recall_reliable == 1, vce(cluster pid)
	
	reg work1 allotted_above_meanL1 i.week_in i.calendar_week if treatment == 0 & work_source_inperson == 1, vce(cluster pid)
	reg work1 allotted_above_medianL1 i.week_in i.calendar_week if treatment == 0 & work_source_inperson == 1, vce(cluster pid)
	
	reg mean_work allotted_above_meanL1 i.week_in i.calendar_week if treatment == 0, vce(cluster pid)
	reg mean_work allotted_above_medianL1 i.week_in i.calendar_week if treatment == 0, vce(cluster pid)
	
	
	
	
	
	
	xtreg mean_attend allotted_above_meanL1 i.week_in i.calendar_week if treatment == 0, fe
	xtreg mean_work allotted_above_meanL1 i.week_in i.calendar_week if treatment == 0, fe
	
	reg mean_attend amount_allottedL1 i.week_in i.calendar_week if treatment == 0, vce(cluster pid)
	reg mean_job_at_stand amount_allottedL1 i.week_in i.calendar_week if treatment == 0, vce(cluster pid)
	
	reg work1 amount_allottedL1 i.week_in i.calendar_week if treatment == 0 & work_source_inperson == 1 , vce(cluster pid)
	reg work1 amount_allottedL1 i.week_in i.calendar_week if treatment == 0 & recall_reliable == 1 , vce(cluster pid)
	
	reg attend_and_before8 amount_allottedL1 i.week_in i.calendar_week if treatment == 0, vce(cluster pid)
	reg attend_and_before8 amount_allottedL1 bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if treatment == 0 & recall_reliable==1, vce(cluster pid)
	
	
	reg job_at_stand amount_allottedL1 i.week_in i.calendar_week if treatment == 0, vce(cluster pid)
	reg job_at_stand amount_allottedL1 bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if treatment == 0, vce(cluster pid)
	
	reg job_at_stand1 amount_allottedL1 i.week_in i.calendar_week if treatment == 0, vce(cluster pid)
	reg job_at_stand1 amount_allottedL1 bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if treatment == 0, vce(cluster pid)
	
	
	reg job_at_stand amount_allottedL1 i.week_in i.calendar_week if treatment == 0 & recall_reliable==1, vce(cluster pid)
	reg job_at_stand amount_allottedL1 bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if treatment == 0 & recall_reliable==1, vce(cluster pid)
	
	reg job_at_stand1 amount_allottedL1 i.week_in i.calendar_week if treatment == 0 & recall_reliable==1, vce(cluster pid)
	reg job_at_stand1 amount_allottedL1 bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if treatment == 0 & recall_reliable==1, vce(cluster pid)
	
	reg mean_job_at_stand amount_allottedL1 i.week_in i.calendar_week if treatment == 0 , vce(cluster pid)
	reg mean_job_at_stand amount_allottedL1 bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if treatment ==0, vce(cluster pid)
	
	
	
	
	reg mean_work amount_allottedL1 i.week_in i.calendar_week if treatment == 0, vce(cluster pid)
	reg mean_work amount_allottedL1  bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if treatment == 0, vce(cluster pid)
	reg work1 amount_allottedL1  bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if treatment == 0 & work_source_inperson==1, vce(cluster pid)
	reg work amount_allottedL1  bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if treatment == 0 & recall_reliable==1, vce(cluster pid)
	reg work amount_allottedL1 bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if treatment == 0 & recall_reliable==1, vce(cluster pid)	
	
	reg job_at_stand amount_allottedL1 bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if treatment == 0 & recall_reliable==1, vce(cluster pid)
	
	
	
	reg mean_work amount_allottedL1  bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if treatment == 0 & work_source_inperson==1, vce(cluster pid)
	
	
	
	reg mean_work amount_allottedL1  bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if treatment == 0 & recall_reliable==1, vce(cluster pid)
	
	
	
	xtreg work l.amount_allotted i.stand i.week_in i.calendar_week if treatment == 0 & recall_reliable == 1
	
	
	