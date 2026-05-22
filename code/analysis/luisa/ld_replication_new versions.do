************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Replicate the main paper analysis using HW's new dataset
* 	Author:				HW 
* 	Last modified:		2026-Apr-23 (HW)
************************************************************
************************************************************

	
*****************************************
**# Table 2: Shocks Erode Habit Stock
*****************************************

****
**## 1. Call Data
****

	use "$main_data" , clear
// 	gen_bl_cov

	gen ls = attend
	replace ls = work1 if work_source_inperson == 1
	
	egen ls_weekly = total(ls), by(pid calendar_week)
	
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


	* PID*day level residulized attendance
// 	reg attend i.standid i.calendar_week i.dow  if phase==0 | (phase==1 & treat==0)
// 	predict resid_day_attendph2 if phase==2 , residuals

	//reg attend bl_attend bl_earn miss_bl_earn i.standid##i.treatment if phase<2	
	//predict resid_day_attendph3 if phase==2, residuals

	//reg attend i.phase if phase<2	
	//predict resid_day_attendph4 if phase==2, residuals

	global version "v0"
	* V0
	reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment if phase<2	
	predict resid_day_attendph2 if phase==2 /*& treat == 0*/, residuals
	/* V1
	cap drop resid_day_attendph2
	reg attend i.standid##i.treatment i.calendar_week phase##treatment i.dow if phase<2	
	predict resid_day_attendph2 if phase==2 & treat == 0, residuals
	* V2
	cap drop resid_day_attendph2
	reg attend i.standid##i.treatment phase##treatment i.dow if phase<2	
	predict resid_day_attendph2 if phase==2 & treat == 0, residuals
	* V3
	cap drop resid_day_attendph2
	reg attend i.standid i.calendar_week phase i.dow if (treat == 0 & phase<2) | phase == 0
	predict resid_day_attendph2 if phase==2 & treat == 0, residuals
	* V4
	cap drop resid_day_attendph2
	reg attend i.standid i.calendar_week i.dow if  phase == 0
	predict resid_day_attendph2 if phase==2 & treat == 0, residuals
	* V5
	cap drop resid_day_attendph2
	reg attend i.standid i.calendar_week i.dow  if phase==0 | (phase==1 & treat==0)
	predict resid_day_attendph2 if phase==2 & treat == 0, residuals
	* V0_2
	cap drop resid_day_attendph2
	reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment if phase<2	
	predict resid_day_attendph2 if phase==2 & treat == 0, residuals
	* V0_3
	cap drop resid_day_attendph2
	reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment i.calendar_week if phase<2	
	predict resid_day_attendph2 if phase==2, residuals
	*/
****
**## 2. Stand Attendance LOO 
****

	* ORIGINAL CODE FOR LOO 
	* dont use daily averages for control group - use residuals for everyone to do this
	* pid's in chronological order
	

	* More Efficient Version of the LOO Code
	* Created by LC on April 19 2026
	* Last edited by HW on April 28 2026
	preserve
		* Step 1: aggregate daily residuals to worker-week level
		keep if phase == 2
		set type double
		collapse (sum) w_sum = resid_day_attendph2 (count) w_n = resid_day_attendph2 (first) standid , ///
			by(calendar_week pid treat)

		bys standid calendar_week: egen count_pid = count(pid) if treat == 0
		* Step 2: stand-week totals
		bysort standid calendar_week: egen sw_sum 	= total(w_sum) //if treat == 0
		bysort standid calendar_week: egen sw_n		= total(w_n) //if treat == 0
		sort pid calendar_week
		
		* Step 3: worker-level LOO mean
		gen double avg_wkattend_loo = (sw_sum - w_sum) / (sw_n - w_n)
		* avg_wkattend_loo is now constant within worker x stand x week:
		* it is the mean of other workers' daily residuals at that stand-week.
		
		bys pid calendar_week: keep if _n == 1
		sum avg_wkattend_loo /*  if treat == 0 & count_pid>3 & !mi(count_pid)*/, d 		
		sum avg_wkattend_loo if treat == 0 /*& count_pid>3 & !mi(count_pid)*/, d 
		scalar pct_j_attend = r(p25)

		ksmirnov avg_wkattend_loo, by(treat)
		local ks_p : di %6.3fc r(p)
		distplot avg_wkattend_loo, over(treat) note("Ksmirnov pval `ks_p'")
		graph export  "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/code/analysis/luisa/shocks/distplot_loo_by_treat_$version.png", replace

				
		keep pid calendar_week avg_wkattend_loo
		gen dow = 2

		tempfile loo_worker_week
		save `loo_worker_week'


	restore

	* Merge LOO back into the full daily panel
	merge m:1 pid calendar_week using `loo_worker_week', keep(1 2 3) nogen

	* Indicator for Shock
	gen wkof_attend_j = (avg_wkattend_loo <= pct_j_attend) if avg_wkattend_loo!=.

	* First calendar week of shock (Leave one out, varies by pid)
	gen calwk_of_shock = stand_ph_calweek if wkof_attend_j==1
	bys pid : egen firstofshock_calwk_j = min(calwk_of_shock)
	drop calwk_of_shock
	
	gen calwk_of_shock = calendar_week if wkof_attend_j==1
	bys pid : egen firstofshock1_calwk_j = min(calwk_of_shock)
	drop calwk_of_shock
	
	reg firstofshock_calwk_j treat i.standid if phase == 2 & dow == 2 & week_in == 2, vce(cluster standid)
	reg firstofshock_calwk_j treat if phase == 2 & dow == 2 & week_in == 2, vce(cluster standid)
	reg firstofshock_calwk_j treat i.launchset i.standid if phase == 2 & dow == 2 & week_in == 2, vce(cluster standid)
	
	twoway (hist firstofshock1_calwk_j if phase == 2 & dow == 2 & week_in == 2 & treat == 0, ///
	lcolor(gs12) fcolor(none) discrete width(1) freq) || ///
	(hist firstofshock1_calwk_j if phase == 2 & dow == 2 & week_in == 2 & treat == 1, ///
	lcolor(red) fcolor(none) discrete width(1) freq), ///
	legend(order(1 "Control" 2 "Treatment"))  xlabel(18(1)48) ///
	xtitle("Calendar week of first shock (Phase 2)")
	graph export  "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/code/analysis/luisa/shocks/hist_firstcalwk_shock_by_treat_$version.png", replace
	
// 	replace firstofshock_calwk_j = firstofshock_calwk_j+1 if firstofshock1_calwk_j == 25
// 	replace firstofshock_calwk_j = firstofshock_calwk_j+2 if firstofshock1_calwk_j == 24
// 	replace firstofshock1_calwk_j = firstofshock1_calwk_j+1 if firstofshock1_calwk_j == 25
// 	replace firstofshock1_calwk_j = firstofshock1_calwk_j+2 if firstofshock1_calwk_j == 24


	* Weeks since shock
	gen wks_since_shock_j = stand_ph_calweek - firstofshock_calwk_j
	replace wks_since_shock_j = . if firstofshock_calwk_j == .

	* Dummy for first week in which shock happens (contemporaneous shock)
	gen firstwk_attend_j = (wks_since_shock_j == 0)
	gen firstwk_attendloo_b25 = firstwk_attend_j
	gen treatXfirstwk_attendloo_b25 = treatment*firstwk_attendloo_b25

	
	* Post variable
	gen post_attend_j = (wks_since_shock_j > 0 & !mi(wks_since_shock_j))
	gen treatXpost_attend_j = treatment*post_attend_j
	gen post_attendloo_b25 = post_attend_j
	gen treatXpost_attendloo_b25 = treatXpost_attend_j
	
	
	reg attend_nadj firstwk_attend_j post_attendloo_b25 i.standid if phase== 2 & dow == 2 & treat == 0
	reghdfe attend_nadj firstwk_attend_j##treat post_attendloo_b25##treat if phase== 2 & dow == 2, absorb(standid)	
	reghdfe attend_nadj firstwk_attend_j##treat  if phase== 2 & dow == 2, absorb(standid calendar_week)
	reghdfe attend_nadj firstwk_attend_j##treat  if phase== 2 & dow == 2, absorb(standid )

	* One week post shock
	gen attend_j_post1 = (wks_since_shock_j==1)
	gen attendloo25_post1 = attend_j_post1
	gen treatXattend_j_post1 = treatment*attend_j_post1
	gen treatXattendloo25_post1 = treatXattend_j_post1
	
	* Two weeks post shock
	gen attend_j_post2 = (wks_since_shock_j==2)
	gen attendloo25_post2 = attend_j_post2
	gen treatXattend_j_post2 = treatment*attend_j_post2
	gen treatXattendloo25_post2 = treatXattend_j_post2
		
	* Two+ weeks post shock
	gen attend_j_post2p = (wks_since_shock_j>=2 & !mi(wks_since_shock_j))
	gen attendloo25_post2p = attend_j_post2p
	gen treatXattend_j_post2p = treatment*attend_j_post2p
	gen treatXattendloo25_post2p = treatXattend_j_post2p
	
	* Three+ weeks post shock
	gen attend_j_post3p = (wks_since_shock_j>=3 & !mi(wks_since_shock_j))
	gen attendloo25_post3p = attend_j_post2p
	gen treatXattend_j_post3p = treatment*attend_j_post3p
	gen treatXattendloo25_post3p = treatXattend_j_post3p
	
	
 reghdfe attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid) absorb(calendar_week standid strata)
 reghdfe attend_and_before8_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid) absorb(calendar_week standid strata) 
 
	reg attend_and_before8_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week  firstwk_attendloo_b25##treat if phase==2, vce(cluster standid)
	
	reg attend_and_before8_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week  standid##launchset firstwk_attendloo_b25##treat if  phase==2, vce(cluster standid)
	
	reg attend_and_before8_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week   if  phase==2 &  firstwk_attendloo_b25==0, vce(cluster standid)
	
	reg ls_weekly treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week  standid##launchset firstwk_attendloo_b25##treat if phase==2, vce(cluster standid)
	
	reg ls_weekly treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week  standid##launchset  if phase==2 & firstwk_attendloo_b25 == 0, vce(cluster standid)

	reg ls_weekly treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week  if phase==2 & firstwk_attendloo_b25 == 0, vce(cluster standid)

	xxx

****
**## 3. Shocks Regression Analysis
****

	local bootstrap_program = "wildbootstrap" // "boottest" or "wildbootstrap"

	* Columns 1 and 2: Same Spec as in Shocks Analysis
	eststo clear 
  
	* Column 1
	eststo: reg attend_nadj treat treatXweek_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 , vce(cluster pid)
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
	cap drop ever_post_attendloo_b25
	bys pid: egen ever_post_attendloo_b25 = max(post_attendloo_b25)
	reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
	
	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, cluster(standid) reps(2048) rseed(123)
		matrix pval = J(1,2,.)
		matrix colnames pval = treat treatXpost_attendloo_b25
		matrix pval[1,1] = r(table)[3,1]
		matrix pval[1,2] = r(table)[3,2]
	}

	if "`bootstrap_program'" == "boottest" {
		boottest {treat} {treatXpost_attendloo_b25} , seed(123) reps(2048) boottype(wild) nograph 
		matrix pval = J(1,2,.)
		matrix colnames pval = treat treatXpost_attendloo_b25
		matrix pval[1,1] = r(p_1)
		matrix pval[1,2] = r(p_2)
	}

	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval 
	
	
	* Column 4 - time trend 
	reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)


	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress attend_nadj treat treatXpost_attendloo_b25 treatXweek_in_dm post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage  week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, cluster( standid) reps(2048) rseed(123)
		matrix pval = J(1,3,.)
		matrix colnames pval = treat treatXpost_attendloo_b25 treatXweek_in_dm
		matrix pval[1,1] = r(table)[3,1]
		matrix pval[1,2] = r(table)[3,2]
		matrix pval[1,3] = r(table)[3,3]
	}

	if "`bootstrap_program'" == "boottest" {
		boottest {treat} {treatXpost_attendloo_b25} {treatXweek_in_dm}, seed(123) reps(2048) boottype(wild) nograph 
		matrix pval = J(1,3,.)
		matrix colnames pval = treat treatXpost_attendloo_b25 treatXweek_in_dm
		matrix pval[1,1] = r(p_1)
		matrix pval[1,2] = r(p_2)
		matrix pval[1,3] = r(p_3)
	}

	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval 

	* Column 5
 	reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week  if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)


	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress  attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, cluster(standid) reps(2048) rseed(123)

		matrix pval = J(1,3,.)
		matrix colnames pval = treat treatXattendloo25_post1 treatXattendloo25_post2p
		matrix pval[1,1] = r(table)[3,1]
		matrix pval[1,2] = r(table)[3,2]
		matrix pval[1,3] = r(table)[3,3]
	}


	if "`bootstrap_program'" == "boottest" {
		boottest {treat} {treatXattendloo25_post1} {treatXattendloo25_post2p}, seed(123) reps(2048) boottype(wild) nograph 
		matrix pval = J(1,3,.)
		matrix colnames pval = treat treatXattendloo25_post1 treatXattendloo25_post2p
		matrix pval[1,1] = r(p_1)
		matrix pval[1,2] = r(p_2)
		matrix pval[1,3] = r(p_3)	
	}
	
	eststo: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
  		estadd local calweek "Yes", replace
		 estadd local weekin  "Yes", replace
	estadd matrix pval 


	* Column 6
	reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)


	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p treatXweek_in_dm attendloo25_post1 attendloo25_post2p week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, cluster(standid) reps(2048) rseed(123)

		matrix pval = J(1,4,.)
		matrix colnames pval = treat treatXattendloo25_post1 treatXattendloo25_post2p treatXweek_in_dm
		matrix pval[1,1] = r(table)[3,1]
		matrix pval[1,2] = r(table)[3,2]
		matrix pval[1,3] = r(table)[3,3]
		matrix pval[1,4] = r(table)[3,4]
	}

	if "`bootstrap_program'" == "boottest" { 
		boottest {treat} {treatXattendloo25_post1} {treatXattendloo25_post2p} {treatXweek_in_dm}, seed(123) reps(2048) boottype(wild) nograph 
		matrix pval = J(1,4,.)
		matrix colnames pval = treat treatXattendloo25_post1 treatXattendloo25_post2p treatXweek_in_dm
		matrix pval[1,1] = r(p_1)
		matrix pval[1,2] = r(p_2)
		matrix pval[1,3] = r(p_3)	
		matrix pval[1,4] = r(p_4)	
	}

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

	
	  esttab 	using "$tables/shocks_attendloo_b25_bootstrap_jul_`bootstrap_program'.tex" , se ///
				keep(	treat treatXweek_in_dm treatXpostweek5 treatXpost_attendloo_b25 treatXattendloo25_post1 ///
						treatXattendloo25_post2p treatXweek_in_dm) ///
				order(	treat treatXpost_attendloo_b25 treatXattendloo25_post1 ///
						treatXattendloo25_post2p treatXpostweek5 treatXweek_in_dm ) ///
				nostar l cells(b(fmt(3)) se(fmt(3) par) pval(fmt(3) par("[" "]") pvalue(pval))) nonotes  ///
				starlevels(* 0.10 ** 0.05 *** .01) ///
				stats(weekin calweek N, fmt(0 0 0) labels("Week in phase FE" "Calendar Week FE" "N: worker-weeks")) ///
				replace collabels(none) frag gaps nomtitles 
				
	eststo clear


**************************
**# Figure 4: Attendance
**************************

	eststo clear 
	
	recode jl_choice1_fixed_vs_stand 2 = 0
	replace jl_choice1_fixed_vs_stand = jl_contract_penalty if jl_choice1_fixed_vs_stand == 1
	
	eststo: reg jl_choice1_fixed_vs_stand treatment i.stand i.strata, clu(pid)
	sum jl_choice1_fixed_vs_stand if treat == 0 & e(sample)
	estadd scalar y_mean=r(mean)
	estadd local strata          "Yes", replace
	estadd local stand           "Yes", replace
	
	

	reshape long fixed_choice_q , i(pid date) j(qid) 

	keep if !mi(date)
	merge 1:m pid date using "$temp/05d_phase2act_flextest_reshaped.dta", keep(1 3) nogen



eststo clear 

	eststo: reg fixed_choice_q treat  i.flex_version i.strata i.first_day i.second_day, clu(pid)
	sum fixed_choice_q if treat == 0 & e(sample)
	estadd scalar y_mean=r(mean)
	estadd local strata          "Yes", replace
	estadd local stand           "Yes", replace
	eststo: reg fixed_choice_q treat  i.flex_version i.strata i.first_day i.second_day [w=flex_num_obs], clu(pid)
	sum fixed_choice_q if treat == 0 & e(sample)
	estadd scalar y_mean=r(mean)
	estadd local strata          "Yes", replace
	estadd local stand           "Yes", replace
	* shock heterogeneity
	eststo: reg fixed_choice_q treat treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 i.standid i.strata i.first_day i.second_day , clu(pid)
	sum fixed_choice_q if treat == 0 & e(sample)
	estadd scalar y_mean=r(mean)
	estadd local strata          "Yes", replace
	estadd local stand           "Yes", replace
	eststo: reg fixed_choice_q treat treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 i.standid i.strata i.first_day i.second_day [w=flex_num_obs], clu(pid)
	sum fixed_choice_q if treat == 0 & e(sample)
	estadd scalar y_mean=r(mean)
	estadd local strata          "Yes", replace
	estadd local stand           "Yes", replace

	esttab using "$tables/flex_fixed_choice_attendloo_b25.tex" , se(3) replace keep(treat treatXpost_attendloo_b25) stats(y_mean N, labels("Control mean" "N: worker-question"))  l nonotes  cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) nostar collabels(none) nonum mtitles( "\shortstack{Contract\\ Job}" "\shortstack{Fixed choice\\ No Weight}" "\shortstack{Fixed choice\\ Weighted}" "\shortstack{Fixed choice\\ Weighted}" "\shortstack{Fixed choice\\ No Weight}") booktabs style(tex)
	
	eststo clear 
