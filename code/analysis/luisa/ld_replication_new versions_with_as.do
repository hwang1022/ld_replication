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
	global save_overleaf 0
	global overleaf_dir "$db_dir/Apps/Overleaf/LD_shocks"
	
	* Run 0.master.do to set globals
	* main dataset is "./07. Data/3. Main Study 3.0/ld_replication/data/final/final_data_prioritize_in_person.dta"
	use "$main_data" , clear

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
	
	* Save version for plots
	global version "V0"
// 	* V2
// 	cap drop resid_day_attendph2
// 	reg attend i.standid##i.treatment phase##treatment i.dow if phase<2	
// 	predict resid_day_attendph2 if phase==2 & treat == 0, residuals
// 	* V4
// 	cap drop resid_day_attendph2
// 	reg attend i.standid i.calendar_week i.dow if  phase == 0
// 	predict resid_day_attendph2 if phase==2 & treat == 0, residuals
// 	/* V1 */
// 	cap drop resid_day_attendph2	
// 	reg attend i.standid##i.treatment i.calendar_week phase##treatment i.dow if phase<2	
// 	predict resid_day_attendph2 if phase==2 & treat == 0, residuals
// 	* V3
// 	cap drop resid_day_attendph2
// 	reg attend i.standid i.calendar_week phase i.dow if (treat == 0 & phase<2) | phase == 0
// 	predict resid_day_attendph2 if phase==2 & treat == 0, residuals
// 	* V1_2
// 	cap drop resid_day_attendph2
// 	reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment if phase<2	
// 	predict resid_day_attendph2 if phase==2 & treat == 0, residuals
//
// 	* V0_2
// 	cap drop resid_day_attendph2
// 	reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment i.dow if phase<2	
// 	predict resid_day_attendph2 if phase==2, residuals
//	
// 	* V0_3
// 	cap drop resid_day_attendph2
// 	reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment i.launchset##i.standid if phase<2	
// 	predict resid_day_attendph2 if phase==2, residuals
//	
	* V5
	cap drop resid_day_attendph2
	reg attend i.standid i.calendar_week i.dow  if phase==0 | (phase==1 & treat==0)
	predict resid_day_attendph2 if phase==2 & treat == 0, residuals

	* V0
	cap drop resid_day_attendph2
	reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment i.dow i.launchset if phase<2	
	predict resid_day_attendph2 if phase==2, residuals
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
		sum avg_wkattend_loo, d // if treat == 0
		scalar pct_j_attend = r(p25)
		
		di scalar(pct_j_attend)
		//sum avg_wkattend_loo /*if treat == 0 & count_pid>3 & !mi(count_pid)*/, d 

		ksmirnov avg_wkattend_loo, by(treat)
		local ks_p : di %6.3fc r(p)
		
		distplot avg_wkattend_loo, over(treat) note("Ksmirnov pval `ks_p'") lcolor(gs12 red)
		if "$save_overleaf" == "1" {
			graph export  "$overleaf_dir/figures/distplot_loo_by_treat_$version.png", replace
		}
				
		keep pid calendar_week avg_wkattend_loo
		gen dow = 2

		tempfile loo_worker_week
		save `loo_worker_week'


	restore
****
**## 2. Merge LOO back into the full daily panel and build variables
****	
	merge m:1 pid calendar_week using `loo_worker_week', keep(1 2 3) nogen

	* Indicator for Shock
	gen wkof_attend_j = (avg_wkattend_loo <= pct_j_attend) if avg_wkattend_loo!=.

	* First stand-phase calendar week of shock
	gen calwk_of_shock = stand_ph_calweek if wkof_attend_j==1
	bys pid : egen firstofshock_calwk_j = min(calwk_of_shock)
	drop calwk_of_shock
	* First calendar weeek
	gen calwk_of_shock = calendar_week if wkof_attend_j==1
	bys pid : egen firstofshock1_calwk_j = min(calwk_of_shock)
	drop calwk_of_shock

	* First week-in-study of shock
	gen temp = week_in if wkof_attend_j==1
	bys pid : egen firstofshock_weekin_j = min(temp)
	drop temp
	
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


****
**## 3. Diagnostics
****		

****
**## 3.1 Diagnostics: First-stage
****		
	
	* Only week of shock
	// no controls
	reg attend_nadj treat treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 if phase==2 , vce(cluster pid)
	// strata + stand controls
	reg attend_nadj treat treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 i.standid i.strata  if phase==2 , vce(cluster pid)
	// strata + cal week + week in study FEs
	reg attend_nadj treat treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 i.standid i.strata i.calendar_week i.week_in if phase==2 , vce(cluster pid)
	
	* Week of shock + post shock
	// no controls
	reg attend_nadj treat treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 post_attendloo_b25 treatXpost_attendloo_b25 if phase==2 , vce(cluster pid)
	// strata + stand controls
	reg attend_nadj treat treatXfirstwk_attendloo_b25 firstwk_attendloo_b25  post_attendloo_b25 treatXpost_attendloo_b25  i.standid i.strata  if phase==2 , vce(cluster pid)
	// strata + cal week + week in study FEs
	reg attend_nadj treat treatXfirstwk_attendloo_b25 firstwk_attendloo_b25  post_attendloo_b25 treatXpost_attendloo_b25  i.standid i.strata i.calendar_week i.week_in if phase==2 , vce(cluster pid)

	* To do: add bl controls + run with bootstrapped SE

****
**## 3.2 Diagnostics: Timing of the shock
****	
	* Timing of first shock (calendar week)
	reg firstofshock_calwk_j treat i.standid if phase == 2 & dow == 2 & week_in == 2, vce(cluster standid)
	reg firstofshock_calwk_j treat if phase == 2 & dow == 2 & week_in == 2, vce(cluster standid)
	reg firstofshock_calwk_j treat i.launchset i.standid if phase == 2 & dow == 2 & week_in == 2, vce(cluster standid)
	

	count if firstofshock1_calwk_j !=. & phase == 2 & dow == 2 & week_in == 2 & treat == 0
	local w_shocked_c = r(N)
	count if firstofshock1_calwk_j !=. & phase == 2 & dow == 2 & week_in == 2 & treat == 1
	local w_shocked_t = r(N)
	
	
	twoway (hist firstofshock1_calwk_j if phase == 2 & dow == 2 & week_in == 2 & treat == 0, ///
	lcolor(gs12) fcolor(gs12%60) discrete width(1)  lw(thin) freq) || ///
	(hist firstofshock1_calwk_j if phase == 2 & dow == 2 & week_in == 2 & treat == 1, ///
	lcolor(red) fcolor(none) discrete width(1)  lw(thin) freq), ///
	legend(order(1 "Control" 2 "Treatment"))  xlabel(18(1)48) ///
	xtitle("Calendar week of first shock (Phase 2)") ///
	note("Control workers ever shocked: `w_shocked_c'" "Treated workers ever shocked: `w_shocked_t'")
	if "$save_overleaf" == "1" {
			graph export  "$overleaf_dir/figures/hist_firstcalwk_shock_by_treat_$version.png", replace
	}
	
	reg firstofshock_weekin_j treat i.standid if phase == 2 & dow == 2 & week_in == 2, vce(cluster standid)
	reg firstofshock_weekin_j treat if phase == 2 & dow == 2 & week_in == 2, vce(cluster standid)
	reg firstofshock_weekin_j treat i.launchset##i.standid if phase == 2 & dow == 2 & week_in == 2, vce(cluster standid)
	
	count if firstofshock_weekin_j !=. & phase == 2 & dow == 2 & week_in == 2 & treat == 0
	local w_shocked_c = r(N)
	count if firstofshock_weekin_j !=. & phase == 2 & dow == 2 & week_in == 2 & treat == 1
	local w_shocked_t = r(N)
	
	twoway (hist firstofshock_weekin_j if phase == 2 & dow == 2 & week_in == 2 & treat == 0, ///
	lcolor(gs12) fcolor(gs12%60) discrete width(1) lw(thin) freq) || ///
	(hist firstofshock_weekin_j if phase == 2 & dow == 2 & week_in == 2 & treat == 1, ///
	lcolor(red) fcolor(none) discrete width(1)  lw(thin) freq), ///
	legend(order(1 "Control" 2 "Treatment"))  xlabel(1(1)8) ///
	xtitle("Week in study of first shock (Phase 2)") ///
	note("Control workers ever shocked: `w_shocked_c'" "Treated workers ever shocked: `w_shocked_t'")
	if "$save_overleaf" == "1" {
		graph export  "$overleaf_dir/figures/hist_firstweekin_shock_by_treat_$version.png", replace
	}

****
**## 3.4 Current Table 2 code
****
	* LC : boottest is faster (?) but doesn't work for me
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

	if "$save_overleaf" == "1" {
		esttab 	using $overleaf_dir/tables/shocks_attendloo_b25_bootstrap_jul_$version.tex" , se ///
				keep(	treat treatXweek_in_dm treatXpostweek5 treatXpost_attendloo_b25 treatXattendloo25_post1 ///
						treatXattendloo25_post2p treatXweek_in_dm) ///
				order(	treat treatXpost_attendloo_b25 treatXattendloo25_post1 ///
						treatXattendloo25_post2p treatXpostweek5 treatXweek_in_dm ) ///
				nostar l cells(b(fmt(3)) se(fmt(3) par) pval(fmt(3) par("[" "]") pvalue(pval))) nonotes  ///
				starlevels(* 0.10 ** 0.05 *** .01) ///
				stats(weekin calweek N, fmt(0 0 0) labels("Week in phase FE" "Calendar Week FE" "N: worker-weeks")) ///
				replace collabels(none) frag gaps nomtitles 
	}

		
	eststo clear
	
******* Variant: add week of shock
	
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
	reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 if phase==2, vce(cluster standid)
	
	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 if phase==2, cluster(standid) reps(2048) rseed(123)
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

	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 if phase==2, vce(cluster pid)
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval 
	
	
	* Column 4 - time trend 
	reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)


	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress attend_nadj treat treatXpost_attendloo_b25 treatXweek_in_dm post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage  week_in_dm i.standid i.strata i.calendar_week treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 if phase==2, cluster( standid) reps(2048) rseed(123)
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

	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 if phase==2, vce(cluster pid)
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval 

	* Column 5
 	reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 if phase==2, vce(cluster standid)


	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress  attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 if phase==2, cluster(standid) reps(2048) rseed(123)

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
	
	eststo: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 if phase==2, vce(cluster pid)
  		estadd local calweek "Yes", replace
		 estadd local weekin  "Yes", replace
	estadd matrix pval 


	* Column 6
	reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 if phase==2 , vce(cluster standid)


	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p treatXweek_in_dm attendloo25_post1 attendloo25_post2p week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 if phase==2, cluster(standid) reps(2048) rseed(123)

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

	eststo: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 if phase==2, vce(cluster pid)
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
	if "$save_overleaf" == "1" {
		esttab 	using $overleaf_dir/tables/shocks_attendloo_b25_bootstrap_w_firstweek_$version.tex" , se ///
				keep(	treat treatXweek_in_dm treatXpostweek5 treatXpost_attendloo_b25 treatXattendloo25_post1 ///
						treatXattendloo25_post2p treatXweek_in_dm) ///
				order(	treat treatXpost_attendloo_b25 treatXattendloo25_post1 ///
						treatXattendloo25_post2p treatXpostweek5 treatXweek_in_dm ) ///
				nostar l cells(b(fmt(3)) se(fmt(3) par) pval(fmt(3) par("[" "]") pvalue(pval))) nonotes  ///
				starlevels(* 0.10 ** 0.05 *** .01) ///
				stats(weekin calweek N, fmt(0 0 0) labels("Week in phase FE" "Calendar Week FE" "N: worker-weeks")) ///
				replace collabels(none) frag gaps nomtitles 
	}					
	
	
	
******* Variant: add launchset FE
local bootstrap_program = "wildbootstrap" // "boottest" or "wildbootstrap"

* Column 1
	eststo: reg attend_nadj treat treatXweek_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week i.launchset if phase==2 , vce(cluster pid)
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
	eststo: reg attend_nadj treat treatXpostweek5 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week i.launchset if phase==2 , vce(cluster pid)
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
	reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week i.launchset  if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
	
	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week i.launchset if phase==2 & firstwk_attendloo_b25==0, cluster(standid) reps(2048) rseed(123)
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

	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week i.launchset if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval 
	
	
	* Column 4 - time trend 
	reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week i.launchset if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)


	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress attend_nadj treat treatXpost_attendloo_b25 treatXweek_in_dm post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage  week_in_dm i.standid i.strata i.calendar_week i.launchset if phase==2 & firstwk_attendloo_b25==0, cluster( standid) reps(2048) rseed(123)
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

	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week i.launchset if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval 

	* Column 5
 	reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week i.launchset  if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)


	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress  attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week i.launchset if phase==2 & firstwk_attendloo_b25==0, cluster(standid) reps(2048) rseed(123)

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
	
	eststo: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week i.launchset if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
  		estadd local calweek "Yes", replace
		 estadd local weekin  "Yes", replace
	estadd matrix pval 


	* Column 6
	reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week i.launchset if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)


	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p treatXweek_in_dm attendloo25_post1 attendloo25_post2p week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week i.launchset if phase==2 & firstwk_attendloo_b25==0, cluster(standid) reps(2048) rseed(123)

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

	eststo: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week i.launchset if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval 

	if "$save_overleaf" == "1" {
		esttab 	using $overleaf_dir/tables/shocks_attendloo_b25_bootstrap_w_launchset_$version.tex" , se ///
		keep(	treat treatXweek_in_dm treatXpostweek5 treatXpost_attendloo_b25 treatXattendloo25_post1 ///
				treatXattendloo25_post2p treatXweek_in_dm) ///
		order(	treat treatXpost_attendloo_b25 treatXattendloo25_post1 ///
				treatXattendloo25_post2p treatXpostweek5 treatXweek_in_dm ) ///
		nostar l cells(b(fmt(3)) se(fmt(3) par) pval(fmt(3) par("[" "]") pvalue(pval))) nonotes  ///
		starlevels(* 0.10 ** 0.05 *** .01) ///
		stats(weekin calweek N, fmt(0 0 0) labels("Week in phase FE" "Calendar Week FE" "N: worker-weeks")) ///
		replace collabels(none) frag gaps nomtitles 
	}			
				
******* Variant: add launchsetXstandid FE
local bootstrap_program = "wildbootstrap" // "boottest" or "wildbootstrap"
eststo clear
* Column 1
	eststo: reg attend_nadj treat treatXweek_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week i.launchset##i.standid if phase==2 , vce(cluster pid)
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
	eststo: reg attend_nadj treat treatXpostweek5 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week i.launchset##i.standid if phase==2 , vce(cluster pid)
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
	reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week i.launchset##i.standid  if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
	
	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week i.launchset##i.standid if phase==2 & firstwk_attendloo_b25==0, cluster(standid) reps(2048) rseed(123)
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

	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week i.launchset##i.standid if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval 
	
	
	* Column 4 - time trend 
	reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week i.launchset##i.standid if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)


	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress attend_nadj treat treatXpost_attendloo_b25 treatXweek_in_dm post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage  week_in_dm i.standid i.strata i.calendar_week i.launchset##i.standid if phase==2 & firstwk_attendloo_b25==0, cluster( standid) reps(2048) rseed(123)
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

	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week i.launchset##i.standid if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval 

	* Column 5
 	reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week i.launchset##i.standid  if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)


	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress  attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week i.launchset##i.standid if phase==2 & firstwk_attendloo_b25==0, cluster(standid) reps(2048) rseed(123)

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
	
	eststo: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week i.launchset##i.standid if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
  		estadd local calweek "Yes", replace
		 estadd local weekin  "Yes", replace
	estadd matrix pval 


	* Column 6
	reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week i.launchset##i.standid if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)


	if "`bootstrap_program'" == "wildbootstrap" {
		wildbootstrap regress attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p treatXweek_in_dm attendloo25_post1 attendloo25_post2p week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week i.launchset##i.standid if phase==2 & firstwk_attendloo_b25==0, cluster(standid) reps(2048) rseed(123)

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

	eststo: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week i.launchset##i.standid if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval 


	if "$save_overleaf" == "1" {
		esttab 	using $overleaf_dir/tables/shocks_attendloo_b25_bootstrap_w_launchsetXstandid_$version.tex" , se ///
		keep(	treat treatXweek_in_dm treatXpostweek5 treatXpost_attendloo_b25 treatXattendloo25_post1 ///
				treatXattendloo25_post2p treatXweek_in_dm) ///
		order(	treat treatXpost_attendloo_b25 treatXattendloo25_post1 ///
				treatXattendloo25_post2p treatXpostweek5 treatXweek_in_dm ) ///
		nostar l cells(b(fmt(3)) se(fmt(3) par) pval(fmt(3) par("[" "]") pvalue(pval))) nonotes  ///
		starlevels(* 0.10 ** 0.05 *** .01) ///
		stats(weekin calweek N, fmt(0 0 0) labels("Week in phase FE" "Calendar Week FE" "N: worker-weeks")) ///
		replace collabels(none) frag gaps nomtitles 
	}	
					
	eststo clear
/*-------------------------------------------------------------------------------------------*	
						END : CURRENT TABLE 2 CODE
*-------------------------------------------------------------------------------------------*/


**** Roth and Sant'Anna

keep if inlist(phase, 1, 2)

keep if attend_nadj != .

* unique observation - phase
bys pid phase (date): gen unique_obs_ph = _n == 1
* unique observation (phase 2 only)
gen unique_obs = 0
replace unique_obs = unique_obs_ph if phase == 2

gen temp = week_in if wkof_attend_j==1 & phase==2
egen first_shock_weekin = min(temp), by(pid)	
la var first_shock_weekin "First week in study of shock"


egen id_num = group(pid)
sort id_num week_in_p1_p2
xtset id_num week_in_p1_p2

* Gen cohort - defined by treatment timing
cap drop cohort
gen cohort = 7+first_shock_weekin
// gen cohort = first_shock_weekin

replace cohort = 0 if cohort == . | cohort >= 16

cap drop never_treat
gen never_treat = (cohort == 0)

staggered attend_nadj if treat ==0 & week_in_p1_p2>1, i(id_num) t(week_in_p1_p2) g(cohort) estimand(simple eventstudy) eventTime(-3/3) num_fisher(500) use_last_treated_only
/*
-------------+----------------------------------------------------------------
simple       |
      cohort |  -.0237438   .2743382    -0.09   0.931    -.5614369    .5139492
-------------+----------------------------------------------------------------
eventstudy   |
   cohort -4 |   .0693547   .1903235     0.36   0.716    -.3036725    .4423819
          -3 |  -.2584101   .2244746    -1.15   0.250    -.6983722    .1815519
          -2 |   .1828252   .1651634     1.11   0.268    -.1408891    .5065395
          -1 |          0  (omitted)
           0 |  -.4050804   .1507908    -2.69   0.007     -.700625   -.1095358
           1 |   -.053456   .2162024    -0.25   0.805     -.477205     .370293
           2 |  -.1440803   .2982763    -0.48   0.629    -.7286911    .4405305
           3 |   .3075317   .3613117     0.85   0.395    -.4006261     1.01569
           4 |  -.2518944   .3887473    -0.65   0.517    -1.013825    .5100363
------------------------------------------------------------------------------
*/

staggered attend_nadj if treat ==1 & week_in_p1_p2>1, i(id_num) t(week_in_p1_p2) g(cohort) estimand(simple eventstudy) eventTime(-3/3) num_fisher(500) use_last_treated_only
/* simple       |
      cohort |  -.4110745   .2753279    -1.49   0.135    -.9507072    .1285582
-------------+----------------------------------------------------------------
eventstudy   |
   cohort -4 |   .1616986   .2227064     0.73   0.468    -.2747979    .5981952
          -3 |  -.4391243   .1864337    -2.36   0.019    -.8045277   -.0737209
          -2 |  -.1713848          .        .       .            .           .
          -1 |          0  (omitted)
           0 |  -.7320168    .039504   -18.53   0.000    -.8094432   -.6545904
           1 |  -.4291176   .1882129    -2.28   0.023     -.798008   -.0602271
           2 |  -.0321014   .3499005    -0.09   0.927    -.7178937    .6536909
           3 |    .112688   .3880147     0.29   0.771    -.6478068    .8731828
           4 |  -.9040908   .3848854    -2.35   0.019    -1.658452   -.1497293
------------------------------------------------------------------------------
*/

 
staggered attend_nadj if treat ==0 & week_in_p1_p2>1, i(id_num) t(week_in_p1_p2) g(cohort) estimand(simple eventstudy) eventTime(-4/4) num_fisher(500) 
/*-------------+----------------------------------------------------------------
simple       |
      cohort |  -.0033782   .2444399    -0.01   0.989    -.4824717    .4757153
-------------+----------------------------------------------------------------
eventstudy   |
   cohort -4 |   .1678641    .175997     0.95   0.340    -.1770837     .512812
          -3 |   -.302183   .1972308    -1.53   0.125    -.6887484    .0843823
          -2 |   .0995129   .1649469     0.60   0.546     -.223777    .4228029
          -1 |  -4.44e-16          .        .       .            .           .
           0 |  -.3643225   .1837094    -1.98   0.047    -.7243863   -.0042588
           1 |  -.0381271   .1968885    -0.19   0.846    -.4240215    .3477672
           2 |  -.0043447    .251822    -0.02   0.986    -.4979068    .4892174
           3 |   .1598255   .3343559     0.48   0.633    -.4954999     .815151
           4 |  -.2453725    .329007    -0.75   0.456    -.8902144    .3994694
------------------------------------------------------------------------------
*/
staggered attend_nadj if treat ==1 & week_in_p1_p2>1, i(id_num) t(week_in_p1_p2) g(cohort) estimand(simple eventstudy) eventTime(-4/4) num_fisher(500) 
/*simple       |
      cohort |  -.3348841   .2395665    -1.40   0.162    -.8044258    .1346575
-------------+----------------------------------------------------------------
eventstudy   |
   cohort -4 |   .0987442   .1931734     0.51   0.609    -.2798687    .4773572
          -3 |  -.5897319   .1857913    -3.17   0.002    -.9538762   -.2255875
          -2 |   -.199651   .0449893    -4.44   0.000    -.2878284   -.1114736
          -1 |          0  (omitted)
           0 |  -.7204084   .1140021    -6.32   0.000    -.9438485   -.4969684
           1 |  -.3971264   .1543557    -2.57   0.010    -.6996581   -.0945947
           2 |   .0671362   .2492574     0.27   0.788    -.4213994    .5556718
           3 |   .1209777   .3107725     0.39   0.697    -.4881251    .7300806
           4 |  -.5765069   .3111036    -1.85   0.064    -1.186259    .0332451
------------------------------------------------------------------------------
*/


**** Abraham and Sun

//
/* SA cohort variables: eventstudyinteract requires cohort() to be MISSING
   (not zero) for the never-treated comparison group. */
gen sa_cohort = cohort
replace sa_cohort = . if cohort == 0


/*----------------------------------------------
   4. Create relative-time dummies

   eventstudyinteract requires a set of binary
   indicator variables, one per event-time period.
   The reference period (k=-1) is EXCLUDED from
   the variable list passed to the command.

   Dummies must be 0 for never-treated units.
----------------------------------------------*/

// gen rel_time = week_in_p1_p2 - cohort if cohort > 0
gen rel_time = week_in_p1_p2 - cohort if cohort > 0
tab rel_time



qui su rel_time
local relmin = abs(r(min))
local relmax = abs(r(max))
	// leads
	cap drop F_*
	forval x = 2/`relmin' {  // drop the first lead
		gen F_`x' = rel_time == -`x'
	}
	//lags
	cap drop L_*
	forval x = 0/`relmax' {
		gen L_`x' = rel_time ==  `x'
	}

	
sum cohort
gen last_cohort = cohort==r(max) // dummy for the latest- or never-treated cohort
tab rel_time if dow == 2
bys treat: tabstat rel_time if dow == 2, by(sa_cohort) stats(min max N)

tab rel_time if dow == 2	
	*** Indicator for never treated + last cohort treated
	cap drop never_treat_pool sa_cohort_pool
	gen never_treat_pool = never_treat
	replace never_treat_pool = 1 if cohort == 15
	
	gen sa_cohort_pool = sa_cohort
	replace sa_cohort_pool = . if never_treat_pool == 1

	*** Comparison: never_treated
	***** Control
	eventstudyinteract attend_nadj L_* F_* if treat == 0, ///
	 vce(cluster pid) absorb(pid week_in) cohort(sa_cohort) control_cohort(never_treat)

	event_plot e(b_iw)#e(V_iw), ///
	default_look graph_opt(xtitle("Periods since the event") ytitle("Average effect") xlabel(-7(1)6) ///
	title("Control -- not-treated (phase 1 and 2)")) stub_lag(L_#) stub_lead(F_#) trimlag(6) trimlead(6)

	** Exclude always treated
	eventstudyinteract attend_nadj L_* F_* if treat == 0 & sa_cohort !=1, ///
	vce(cluster pid) absorb(pid week_in) cohort(sa_cohort) control_cohort(never_treat)

	event_plot e(b_iw)#e(V_iw), ///
	default_look graph_opt(xtitle("Periods since the event") ytitle("Average effect") xlabel(-4(1)3) ///
	title("Control -- not-treated (phase 1 and 2)")) stub_lag(L_#) stub_lead(F_#) trimlag(3) trimlead(4) 
	
		* Not yet treated
eventstudyinteract attend_nadj L_* F_* if treat == 0 & ((rel_time<0 & cohort == 15) | cohort<15) & never_treat == 0, ///
 vce(cluster pid) absorb(pid week_in) cohort(sa_cohort_pool) control_cohort(last_cohort)

event_plot e(b_iw)#e(V_iw), ///
default_look graph_opt(xtitle("Periods since the event") ytitle("Average effect") xlabel(-7(1)6) ///
title("Control -- not-yet-treated (phase 1 and 2)")) stub_lag(L_#) stub_lead(F_#) trimlag(6) trimlead(6)

	
	***** Treatment
	eventstudyinteract attend_nadj L_* F_* if treat == 1, ///
	 vce(cluster pid) absorb(pid week_in) cohort(sa_cohort) control_cohort(never_treat)

	event_plot e(b_iw)#e(V_iw), ///
	default_look graph_opt(xtitle("Periods since the event") ytitle("Average effect") xlabel(-7(1)6) ///
	title("Treatment -- not-treated (phase 1 and 2)")) stub_lag(L_#) stub_lead(F_#) trimlag(6) trimlead(6)

	** Exclude always treated
	eventstudyinteract attend_nadj L_* F_* if treat == 1 & sa_cohort !=1, ///
	vce(cluster pid) absorb(pid week_in) cohort(sa_cohort) control_cohort(never_treat)

	event_plot e(b_iw)#e(V_iw), ///
	default_look graph_opt(xtitle("Periods since the event") ytitle("Average effect") xlabel(-4(1)4) ///
	title("Treatment -- not-treated (phase 1 and 2)")) stub_lag(L_#) stub_lead(F_#) trimlag(3) trimlead(4) 

		* Not yet treated
eventstudyinteract attend_nadj L_* F_* if treat == 1 & ((rel_time<0 & cohort == 15) | cohort<15) & never_treat == 0, ///
 vce(cluster pid) absorb(pid week_in) cohort(sa_cohort_pool) control_cohort(last_cohort)

event_plot e(b_iw)#e(V_iw), ///
default_look graph_opt(xtitle("Periods since the event") ytitle("Average effect") xlabel(-7(1)6) ///
title("Treatment -- not-yet-treated (phase 1 and 2)")) stub_lag(L_#) stub_lead(F_#) trimlag(6) trimlead(6)



xxxxx
