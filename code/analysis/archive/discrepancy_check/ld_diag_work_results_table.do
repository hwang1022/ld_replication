************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Replicate the main paper analysis using HW's new dataset
* 	Author:				HW 
* 	Last modified:		2026-Apr-15 (HW)
************************************************************
************************************************************

**********************
**# Define Variables
**********************

	* Generate baseline covariates for original dataset. New datatsets have these variables already.
	cap program drop gen_bl_cov
	program define gen_bl_cov
		preserve

			cap drop bl_attend bl_earn miss_bl_earn bl_modalwage

			keep if phase == 0

			egen temp = mean(attend), by(pid)
			egen bl_attend = max(temp), by(pid)
			drop temp

			* earnings 
			egen temp = mean(earn) , by(pid)
			egen bl_earn = max(temp), by(pid)
			gen miss_bl_earn = (bl_earn==.)
			replace bl_earn = 0 if miss_bl_earn==1
			drop temp
			
			* Modal Work
			egen temp1 = mode(earn) if earn>0, by(pid)
			egen bl_modalwage = max(temp1), by(pid)
			replace bl_modalwage = 0 if bl_modalwage==.
			drop temp1

			keep pid bl_attend bl_earn miss_bl_earn bl_modalwage
			duplicates drop pid, force

			tempfile bl_cov
			save `bl_cov', replace

		restore

		merge m:1 pid using `bl_cov', update replace keep(1 2 3 4 5) nogen


	end
	
*****************************************
**# Work data
*****************************************
	
use "$final/final_data_prioritize_date", clear
	
	cap drop work1_wkly2
	cap drop temp1
	
	/* Reminder -- work data definitions
			- work_orig: data from 7-day recall only
			- work1: includes work data imputed as means
			- work: includes work data randomly assigned to comprehensive recall days
		Reminder -- work source definitions
			- recall_reliable: recall comes from 7-day recall grid (i.e. no comp recall) conducted in person
			- work_source_inperson: recall comes from either 7-day recall grid or comprehensive, conducted in person
	*/
	
	* 1. Is treatment more likely to have recall reliable work days? 
	reg recall_reliable treatment  if inlist(phase, 1,2), vce(cluster pid)
	reg recall_reliable treatment i.phase i.stand i.calendar_week if inlist(phase, 1,2), vce(cluster pid)
	reg recall_reliable treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.strata i.phase i.stand i.calendar_week if inlist(phase, 1,2), vce(cluster pid)
	
	reg recall_reliable treatment  if phase == 2, vce(cluster pid)
	reg recall_reliable treatment i.stand i.calendar_week if phase == 2, vce(cluster pid)
	reg recall_reliable treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.strata i.stand i.calendar_week if phase == 2, vce(cluster pid)
	
	bys recall_reliable: reg work_orig treatment if phase == 2, vce(cluster pid)
	reg work_orig recall_reliable##treatment  if phase == 2, vce(cluster pid)
	reg work_orig recall_reliable##treatment  i.stand i.calendar_week if phase == 2, vce(cluster pid)
	reg work_orig recall_reliable##treatment  bl_attend bl_earn miss_bl_earn bl_modalwage i.strata i.stand i.calendar_week if phase == 2, vce(cluster pid)
	
	
	
	reg work_source_inperson treatment  if inlist(phase, 1,2), vce(cluster pid)
	reg work_source_inperson treatment i.phase i.stand i.calendar_week if inlist(phase, 1,2), vce(cluster pid)
	reg work_source_inperson treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.strata i.phase i.stand i.calendar_week if inlist(phase, 1,2), vce(cluster pid)
	
	reg work_source_inperson treatment  if phase == 2, vce(cluster pid)
	reg work_source_inperson treatment i.stand i.calendar_week if phase == 2, vce(cluster pid)
	reg work_source_inperson treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.strata i.stand i.calendar_week if phase == 2, vce(cluster pid)

	
	* Do treatment workers have more days of reliable recall??
	
	egen reliable_days = total(recall_reliable) , by(pid phase) missing

	* Use reliable_days 1 ==> includes comprehensive recall days
	egen reliable_days1 = total(work_source_inperson) , by(pid phase) missing
	
	*** Phase 1 
	reg reliable_days treatment if phase == 1 & week_in == 2 & dow == 2
	reg reliable_days treatment i.stand i.strata if phase == 2 & week_in == 2 & dow == 2
	
	reg reliable_days1 treatment if phase == 1 & week_in == 2 & dow == 2
	reg reliable_days1 treatment i.stand i.strata if phase == 2 & week_in == 2 & dow == 2
	*** Phase 2 --> add it somewhere
	reg reliable_days treatment if phase == 2 & week_in == 2 & dow == 2
	reg reliable_days treatment i.stand i.strata if phase == 2 & week_in == 2 & dow == 2
	
	reg reliable_days1 treatment if phase == 2 & week_in == 2 & dow == 2
	reg reliable_days1 treatment i.stand i.strata if phase == 2 & week_in == 2 & dow == 2

	
	* LS = showing up at the stand
	* V1: only use work_orig (in person recall from 7-day grid)
	gen  temp1 = work_orig if recall_reliable == 1
	egen temp2 = total(temp1) , by(pid phase week_in) missing // aggregate at weekly level
	egen work_wkly1 = max(temp2), by(pid phase week_in)
		* Proporated version, leave it for now
		//egen temp3 = count(work1), by(pid phase week_in)
		//gen work1_wkly2_adj = work1_wkly2*7/temp3
	drop temp*


	* V2: use work from 7-day recall grid (in person or on the phone)
	gen  temp1 = work_orig
	egen temp2 = total(temp1) , by(pid phase week_in) missing // aggregate at weekly level
	egen work_wkly2 = max(temp2), by(pid phase week_in)
	drop temp*

	* V3: use also comp_recall, in person only, mean imputation
	
	gen  temp1 = work1 if work_source_inperson == 1
	egen temp2 = total(temp1) , by(pid phase week_in) missing // aggregate at weekly level
	egen work_wkly3 = max(temp2), by(pid phase week_in)
	drop temp*

	* V4:  use also comp_recall, in person only, random imputation
	gen  temp1 = work if work_source_inperson == 1
	egen temp2 = total(temp1) , by(pid phase week_in) missing // aggregate at weekly level
	egen work_wkly4 = max(temp2), by(pid phase week_in)
	drop temp*
	
	
	* LS = showing up at the stand or work outside
	* V1 : only use work_orig (in person recall from 7-day grid)
	gen temp = attend
	replace temp = 1 if work_orig == 1 & attend == 0 & recall_reliable == 1
	egen ls_week1 = total(temp), by(pid phase week_in) missing
	drop temp
	
	* V2 : only use work_orig (in person recall from 7-day grid)
	gen temp = attend
	replace temp = 1 if work_orig == 1 & attend == 0
	egen ls_week2 = total(temp), by(pid phase week_in) missing
	drop temp
	
	* V3 :use also comp_recall, in person only, mean imputation
	gen temp = attend
	replace temp = work1 if work1 > 0 & !mi(work1) & attend == 0 & work_source_inperson == 1
	egen ls_week3 = total(temp), by(pid phase week_in) missing
	drop temp
	
	* V4 :use also comp_recall, in person only, mean imputation
	gen temp = attend
	replace temp = 1 if work == 1 & attend == 0 & work_source_inperson == 1
	egen ls_week4 = total(temp), by(pid phase week_in) missing
	drop temp

	
	eststo clear
	** Phase 1
	eststo ph1_v1: reg work_wkly1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly1 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph1_v2: reg work_wkly2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly2 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph1_v3: reg work_wkly3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly3 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph1_v4: reg work_wkly4 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly4 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	** Phase 2
	eststo ph2_v1: reg work_wkly1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	sum work_wkly1 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph2_v2: reg work_wkly2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	sum work_wkly2 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph2_v3: reg work_wkly3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2 , vce(cluster pid)
	sum work_wkly3 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph2_v4: reg work_wkly4 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	sum work_wkly4 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)
	
	
	
	
	esttab ph1_v1 ph1_v2 ph1_v3 ph1_v4 ph2_v1 ph2_v2 ph2_v3 ph2_v4 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/replication/data/discrepancy_check/out/diag_work_ph1_ph2_prioritize_date.tex",  ///
	replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
	stats( y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
	nonotes nonumbers mtitles("In pers., 7day" "All, 7 day" "In pers., comp" "In pers., comp"  "In pers., 7day" "All, 7 day" "In pers., comp" "In pers., comp" ) nostar booktabs ///
	mgroups("Phase 1" "Phase 2" , pattern(1 0 0 0 1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))


	******* LABOR SUPPLY
	eststo clear
	** Phase 1
	eststo ph1_v1: reg ls_week1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly1 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph1_v2: reg ls_week2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly2 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph1_v3: reg ls_week3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly3 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph1_v4: reg ls_week4 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly4 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	** Phase 2
	eststo ph2_v1: reg ls_week1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	sum work_wkly1 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph2_v2: reg ls_week2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	sum work_wkly2 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph2_v3: reg ls_week3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2 , vce(cluster pid)
	sum work_wkly3 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph2_v4: reg ls_week4 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	sum work_wkly4 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)
	
	
	
	
	esttab ph1_v1 ph1_v2 ph1_v3 ph1_v4 ph2_v1 ph2_v2 ph2_v3 ph2_v4 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/replication/data/discrepancy_check/out/diag_laborsupply_ph1_ph2_prioritize_date.tex",  ///
	replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
	stats( y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
	nonotes nonumbers mtitles("In pers., 7day" "All, 7 day" "In pers., comp" "In pers., comp"  "In pers., 7day" "All, 7 day" "In pers., comp" "In pers., comp" ) nostar booktabs ///
	mgroups("Phase 1" "Phase 2" , pattern(1 0 0 0 1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

	
	
		
	use "$final/final_data_prioritize_in_person.dta", clear
	
	cap drop work1_wkly2
	cap drop temp1
	
	/* Reminder -- work data definitions
			- work_orig: data from 7-day recall only
			- work1: includes work data imputed as means
			- work: includes work data randomly assigned to comprehensive recall days
		Reminder -- work source definitions
			- recall_reliable: recall comes from 7-day recall grid (i.e. no comp recall) conducted in person
			- work_source_inperson: recall comes from either 7-day recall grid or comprehensive, conducted in person
	*/
	
	
	
	* LS = showing up at the stand
	* V1: only use work_orig (in person recall from 7-day grid)
	gen  temp1 = work_orig if recall_reliable == 1
	egen temp2 = total(temp1) , by(pid phase week_in) missing // aggregate at weekly level
	egen work_wkly1 = max(temp2), by(pid phase week_in)
		* Proporated version, leave it for now
		//egen temp3 = count(work1), by(pid phase week_in)
		//gen work1_wkly2_adj = work1_wkly2*7/temp3
	drop temp*


	* V2: use work from 7-day recall grid (in person or on the phone)
	gen  temp1 = work_orig
	egen temp2 = total(temp1) , by(pid phase week_in) missing // aggregate at weekly level
	egen work_wkly2 = max(temp2), by(pid phase week_in)
	drop temp*

	* V3: use also comp_recall, in person only, mean imputation
	
	gen  temp1 = work1 if work_source_inperson == 1
	egen temp2 = total(temp1) , by(pid phase week_in) missing // aggregate at weekly level
	egen work_wkly3 = max(temp2), by(pid phase week_in)
	drop temp*

	* V4:  use also comp_recall, in person only, random imputation
	gen  temp1 = work if work_source_inperson == 1
	egen temp2 = total(temp1) , by(pid phase week_in) missing // aggregate at weekly level
	egen work_wkly4 = max(temp2), by(pid phase week_in)
	drop temp*
	
	
	* LS = showing up at the stand or work outside
	* V1 : only use work_orig (in person recall from 7-day grid)
	gen temp = attend
	replace temp = 1 if work_orig == 1 & attend == 0 & recall_reliable == 1
	egen ls_week1 = total(temp), by(pid phase week_in) missing
	drop temp
	
	* V2 : only use work_orig (in person recall from 7-day grid)
	gen temp = attend
	replace temp = 1 if work_orig == 1 & attend == 0
	egen ls_week2 = total(temp), by(pid phase week_in) missing
	drop temp
	
	* V3 :use also comp_recall, in person only, mean imputation
	gen temp = attend
	replace temp = work1 if work1 > 0 & !mi(work1) & attend == 0 & work_source_inperson == 1
	egen ls_week3 = total(temp), by(pid phase week_in) missing
	drop temp
	
	* V4 :use also comp_recall, in person only, mean imputation
	gen temp = attend
	replace temp = 1 if work == 1 & attend == 0 & work_source_inperson == 1
	egen ls_week4 = total(temp), by(pid phase week_in) missing
	drop temp
	
	******* WORK

	eststo clear
	** Phase 1
	eststo ph1_v1: reg work_wkly1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly1 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph1_v2: reg work_wkly2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly2 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph1_v3: reg work_wkly3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly3 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph1_v4: reg work_wkly4 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly4 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	** Phase 2
	eststo ph2_v1: reg work_wkly1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	sum work_wkly1 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph2_v2: reg work_wkly2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	sum work_wkly2 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph2_v3: reg work_wkly3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2 , vce(cluster pid)
	sum work_wkly3 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph2_v4: reg work_wkly4 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	sum work_wkly4 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)
	
	
	
	
	esttab ph1_v1 ph1_v2 ph1_v3 ph1_v4 ph2_v1 ph2_v2 ph2_v3 ph2_v4 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/replication/data/discrepancy_check/out/diag_work_ph1_ph2_prioritize_in_person.tex",  ///
	replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
	stats( y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
	nonotes nonumbers mtitles("In pers., 7day" "All, 7 day" "In pers., comp" "In pers., comp"  "In pers., 7day" "All, 7 day" "In pers., comp" "In pers., comp" ) nostar booktabs ///
	mgroups("Phase 1" "Phase 2" , pattern(1 0 0 0 1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))

	
	
	******* LABOR SUPPLY
	eststo clear
	** Phase 1
	eststo ph1_v1: reg ls_week1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly1 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph1_v2: reg ls_week2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly2 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph1_v3: reg ls_week3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly3 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph1_v4: reg ls_week4 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum work_wkly4 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	** Phase 2
	eststo ph2_v1: reg ls_week1 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	sum work_wkly1 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph2_v2: reg ls_week2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	sum work_wkly2 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph2_v3: reg ls_week3 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2 , vce(cluster pid)
	sum work_wkly3 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	eststo ph2_v4: reg ls_week4 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	sum work_wkly4 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)
	
	
	
	
	esttab ph1_v1 ph1_v2 ph1_v3 ph1_v4 ph2_v1 ph2_v2 ph2_v3 ph2_v4 using "/Users/`c(username)'/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/replication/data/discrepancy_check/out/diag_laborsupply_ph1_ph2_prioritize_in_person.tex",  ///
	replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
	stats( y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
	nonotes nonumbers mtitles("In pers., 7day" "All, 7 day" "In pers., comp" "In pers., comp"  "In pers., 7day" "All, 7 day" "In pers., comp" "In pers., comp" ) nostar booktabs ///
	mgroups("Phase 1" "Phase 2" , pattern(1 0 0 0 1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
