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
**# Table 2: Shocks Erode Habit Stock
*****************************************

****
**## 1. Call Data
****

	use "$main_data" , clear
	gen_bl_cov

	gen treat = treatment
  	egen standid = group(stand)

	* create calweek counter for each standXphase
	sort standid phase calendar_week date pid
	by standid phase calendar_week: gen stand_ph_calweek_id1 = 1 if _n==1
	egen temp2 = seq() if stand_ph_calweek_id1 == 1, by(standid phase)
	egen stand_ph_calweek = max(temp2), by(standid phase calendar_week)
	gen treatXstand_ph_calweek = treat*stand_ph_calweek
	drop temp*


	egen temp1 = mean(week_in) if dow==1, by(pid phase)
	egen temp2 = max(temp1), by(pid phase)
	gen week_in_dm = week_in - temp2
	drop temp*
	gen treatXweek_in_dm = treat*week_in_dm

	gen treatXweek_in = treat*week_in
	gen treatXpostweek5 = treat*(week_in>=5)

	**# Pre
	if "$data_version" == "original" {
		reg attend bl_attend standid##phase##treat if phase<2
	}
	else {
		reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment if phase<2	
	}
	predict resid_day_attendph2 if phase==2, residuals

	/*
	From text:
	The baseline specification uses baseline and Phase 1 data and residualizes against treatment assignment,
	stand fixed effects, phase fixed effects, stand × phase, treatment × stand, and workers'
	baseline controls
	*/

****
**## 3. Stand Attendance LOO - LC more efficient code
****

* --- Step 1: aggregate daily residuals to worker-week level ---
preserve
keep if phase == 2 & resid_day_attendph2 != .
collapse (sum) w_sum = resid_day_attendph2 (count) w_n = resid_day_attendph2, ///
    by(standid calendar_week pid)

* --- Step 2: stand-week totals ---
bysort standid calendar_week: egen sw_sum = total(w_sum)
bysort standid calendar_week: egen sw_n   = total(w_n)

* --- Step 3: worker-level LOO mean ---
gen avg_wkattend_loo = (sw_sum - w_sum) / (sw_n - w_n)
* avg_wkattend_loo is now constant within worker x stand x week:
* it is the mean of other workers' daily residuals at that stand-week.

keep standid calendar_week pid avg_wkattend_loo
tempfile loo_worker_week
save `loo_worker_week'
restore

* Merge LOO back into the full daily panel
merge m:1 standid calendar_week pid using `loo_worker_week', ///
    keep(1 3) nogen

	tab week_in phase 
		
	
/****
**## 3. Stand Attendance LOO
****

		* LEAVE ONE OUT MEANS FOR STAND ATTENDANCE
	  	  * dont use daily averages for control group - use residuals for everyone to do this
			* pid's in chronological order
			egen pid2 = group(standid pid)
			* leave one out means
				gen avg_wkattend_loo = . 
				forvalues s=1/11 {
					* di `s'
					quietly summ pid2 if standid==`s'
					forvalues i=`r(min)'/`r(max)' {
						quietly egen temp1 = mean(resid_day_attendph2) if standid==`s' & pid2!=`i' & phase==2, by(standid calendar_week)
						quietly egen temp2 = max(temp1) if phase==2, by(standid calendar_week)
						quietly replace avg_wkattend_loo = temp2 if pid2==`i'
						drop temp*
					}
				}
*/

	* Indicator for Shock
	_pctile  avg_wkattend_loo if avg_wkattend_loo!=. & dow==2, p(25)
	scalar pct_j_attend = r(r1)
	di scalar(pct_j_attend)
	// OG : .01891695 --> confirmed with new LOO computation
	// NEW DATA, correct: -.01045022
	// NEW DATA, new spec (paper): -.01134772
	// NEW DATA, old spec: -.01123573
	gen wkof_attend_j = (avg_wkattend_loo <= pct_j_attend) if avg_wkattend_loo!=.


	* First calendar week of shock (Leave one out, varies by pid)
	gen calwk_of_shock = stand_ph_calweek if wkof_attend_j==1
	bys pid : egen firstofshock_calwk_j = min(calwk_of_shock)
	drop calwk_of_shock

	* LC adds
	gen weekin_of_shock = week_in_p1_p2 if wkof_attend_j==1
	bys pid : egen firstofshock_weekin_j = min(weekin_of_shock)
	drop weekin_of_shock
	
	
	* Weeks since shock
	gen wks_since_shock_j = stand_ph_calweek - firstofshock_calwk_j
	replace wks_since_shock_j = . if firstofshock_calwk_j == .


	* Dummy for first week in which shock happens (contemporaneous shock)
	gen firstwk_attend_j = (wks_since_shock_j == 0)
	gen firstwk_attendloo_b25 = firstwk_attend_j


	* Post variable
	gen post_attend_j = (wks_since_shock_j > 0 & !mi(wks_since_shock_j))
	gen treatXpost_attend_j = treatment*post_attend_j
	gen post_attendloo_b25 = post_attend_j
	gen treatXpost_attendloo_b25 = treatXpost_attend_j
	
	unique pid if post_attendloo_b25 == 1 & phase == 2
		// Number of unique values of pid is  143
		// Number of records is  3882
	unique pid if post_attendloo_b25 == 1 & phase == 3
		// Number of unique values of pid is  184
		// Number of records is  34937

	
	* One week post shock
	gen attend_j_post1 = (wks_since_shock_j==1)
	gen attendloo25_post1 = attend_j_post1
	gen treatXattend_j_post1 = treatment*attend_j_post1
	gen treatXattendloo25_post1 = treatXattend_j_post1
		
	
	* Two+ weeks post shock
	gen attend_j_post2p = (wks_since_shock_j>=2 & !mi(wks_since_shock_j))
	gen attendloo25_post2p = attend_j_post2p
	gen treatXattend_j_post2p = treatment*attend_j_post2p
	gen treatXattendloo25_post2p = treatXattend_j_post2p
	
	

**## Columns 1 and 2: Same Spec as in Shocks Analysis

	eststo clear 
  
	* Column 1
	eststo: reg attend_nadj treat treatXweek_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 , vce(cluster pid)
	/*
	OG --> matches paper version
Linear regression                               Number of obs     =      1,800
                                                F(45, 224)        =       9.78
                                                Prob > F          =     0.0000
                                                R-squared         =     0.1727
                                                Root MSE          =     2.0324

                                                (Std. err. adjusted for 225 clusters in pid)
--------------------------------------------------------------------------------------------
                           |               Robust
               attend_nadj | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
---------------------------+----------------------------------------------------------------
                     treat |   .4666505   .1962011     2.38   0.018     .0800145    .8532865
          treatXweek_in_dm |  -.0711807   .0404321    -1.76   0.080    -.1508565    .0084952

	NEW data --> spec in paper
	Linear regression                               Number of obs     =      1,800
                                                F(43, 224)        =       8.88
                                                Prob > F          =     0.0000
                                                R-squared         =     0.1667
                                                Root MSE          =     2.0371

                                      (Std. err. adjusted for 225 clusters in pid)
----------------------------------------------------------------------------------
                 |               Robust
     attend_nadj | Coefficient  std. err.      t    P>|t|     [95% conf. interval]
-----------------+----------------------------------------------------------------
           treat |   .4505446   .1999685     2.25   0.025     .0564844    .8446048
treatXweek_in_dm |   -.075202   .0401622    -1.87   0.062     -.154346     .003942
	*/
	estadd local weekin  "Yes", replace
	estadd local calweek "Yes", replace
	matrix pval = J(1,2,.)
	matrix colnames pval = treat treatXweek_in_dm
	matrix pval[1,1] = r(table)[4,1]
	matrix pval[1,2] = r(table)[4,2]
	estadd matrix pval 
	local treat_pval = r(table)[4,2]
	save_input , number(`treat_pval') filename("shock_col1_pval_treatXweek_in_dm") format("%9.3f")
	

	
	* Column 2
	eststo: reg attend_nadj treat treatXpostweek5 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 , vce(cluster pid)
	estadd local weekin  "Yes", replace
	estadd local calweek "Yes", replace
	
	matrix pval = J(1,2,.)
	matrix colnames pval = treat treatXpostweek5
	matrix pval[1,1] = r(table)[4,1]
	matrix pval[1,2] = r(table)[4,2]
	estadd matrix pval 
	local treat_pval = r(table)[4,2]
	save_input , number(`treat_pval') filename("shock_col2_pval_treatXpostweek5") format("%9.3f")
  
  

	* Column 3
	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
	
	* Figure out the # of obs --> we remove one week for each person shocked (first week)
	* ever shocked in sample
	cap drop ever_post_ph2
	bys pid: egen ever_post_ph2 = max(post_attendloo_b25)
	unique pid if ever_post_ph2 == 1 & e(sample)==1
	// 	Number of unique values of pid is  184
	// 	Number of records is  1288
// 	di 184*7 + (225-184)*8
	// 1616

	
	wildbootstrap regress attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, cluster( standid)
	
	
// 	boottest {treat} {treatXpost_attendloo_b25} //, seed(123) reps(2048) boottype(wild) nograph 
// 	matrix pval = J(1,2,.)
// 	matrix colnames pval = treat treatXpost_attendloo_b25
// 	matrix pval[1,1] = r(p_1)
// 	matrix pval[1,2] = r(p_2)

	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval 
	
	
	
	
	* Column 4 - time trend 
	reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
// 	boottest {treat} {treatXpost_attendloo_b25} {treatXweek_in_dm}, seed(123) reps(2048) boottype(wild) nograph 
	
	wildbootstrap reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, cluster( standid)
	
	matrix pval = J(1,3,.)
	matrix colnames pval = treat treatXpost_attendloo_b25 treatXweek_in_dm
	matrix pval[1,1] = r(p_1)
	matrix pval[1,2] = r(p_2)
	matrix pval[1,3] = r(p_3)

	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval 

	* Column 5
	reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
	
	wildbootstrap regress  attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, cluster( standid)
	
// 	boottest {treat} {treatXattendloo25_post1} {treatXattendloo25_post2p}, seed(123) reps(2048) boottype(wild) nograph 
	matrix pval = J(1,3,.)
	matrix colnames pval = treat treatXattendloo25_post1 treatXattendloo25_post2p
	matrix pval[1,1] = r(p_1)
	matrix pval[1,2] = r(p_2)
	matrix pval[1,3] = r(p_3)	
	
	
	eststo: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
  		estadd local calweek "Yes", replace
		 estadd local weekin  "Yes", replace
	estadd matrix pval 


	* Column 6
	reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
	boottest {treat} {treatXattendloo25_post1} {treatXattendloo25_post2p} {treatXweek_in_dm}, seed(123) reps(2048) boottype(wild) nograph 
	matrix pval = J(1,4,.)
	matrix colnames pval = treat treatXattendloo25_post1 treatXattendloo25_post2p treatXweek_in_dm
	matrix pval[1,1] = r(p_1)
	matrix pval[1,2] = r(p_2)
	matrix pval[1,3] = r(p_3)	
	matrix pval[1,4] = r(p_4)	

	eststo: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval 

		
	label var treat "Treat"
	label var treatXpostweek5 "Treat $\times$ Second month of phase 2"     
	label var treatXpost_attendloo_b25 "Treat $\times$ Post shock"
	label var post_attendloo_b25 "Post shock"
	label var treatXattendloo25_post1 "Treat $\times$ 1 week post shock"
	label var treatXattendloo25_post2p "Treat $\times$ 2+ weeks post shock"
	label var treatXweek_in_dm "Treat $\times$ Week in phase 2"

	
	  esttab 	using "$tables/shocks_attendloo_b25_bootstrap_jul.tex" , se ///
				keep(	treat treatXweek_in_dm treatXpostweek5 treatXpost_attendloo_b25 treatXattendloo25_post1 ///
						treatXattendloo25_post2p treatXweek_in_dm) ///
				order(	treat treatXpost_attendloo_b25 treatXattendloo25_post1 ///
						treatXattendloo25_post2p treatXpostweek5 treatXweek_in_dm ) ///
				nostar l cells(b(fmt(3)) se(fmt(3) par) pval(fmt(3) par("[" "]") pvalue(pval))) nonotes  ///
				starlevels(* 0.10 ** 0.05 *** .01) ///
				stats(weekin calweek N, fmt(0 0 0) labels("Week in phase FE" "Calendar Week FE" "N: worker-weeks")) ///
				replace collabels(none) frag gaps nomtitles 
				
	
	eststo clear
