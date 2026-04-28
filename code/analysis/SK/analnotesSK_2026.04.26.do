



* Look at work combining phase 1 and phase 2
reg work1_wkly2 treatXph1 treatXph2 i.phase attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand##phase i.strata##phase i.week_in i.calendar_week if phase==1 | phase==2  , vce(cluster pid)
* Works fine for the other main variables too:
reg attend_nadj treatXph1 treatXph2 i.phase attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand##phase i.strata##phase i.week_in i.calendar_week if phase==1 | phase==2  , vce(cluster pid)



*** Shocks analysis
*****************************************
**# Table 2: Shocks Erode Habit Stock
*****************************************

****
**## 1. Call Data
****

	use "$main_data" , clear
	* gen_bl_cov

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
	*if "$data_version" == "original" {
	*	reg attend bl_attend standid##phase##treat if phase<2
	*}
	*else {
		
		* preferred
		reg attend i.standid i.phase i.calendar_week if phase==0 | (phase==1 & treat==0)	
		
		* other variants of preferred 
		
		
		* other options
		* reg attend i.standid if phase==0 	
		* reg attend bl_attend bl_earn miss_bl_earn i.standid if phase==1 & treat==0	
	*}
	*** THIS IS NEW - WE WANT TO PREDICT RESIDUALS FOR CONTROL GROUP ONLY IN PHASE 2
	predict resid_day_attendph2temp if phase==2 & treat==0, residuals
	*egen resid_day_attendph2 = max(resid_day_attendph2temp) if phase==2, by(stand calendar_week)
	*drop resid_day_attendph2temp

	*reg attend bl_attend bl_earn miss_bl_earn i.standid##i.treatment if phase<2	
	*predict resid_day_attendph3 if phase==2, residuals



	*reg attend i.phase if phase<2	
	*predict resid_day_attendph4 if phase==2, residuals



****
**## 2. Stand Attendance LOO 
****

	* More Efficient Version of the LOO Code
	* Created by LC on April 19 2026
	* Last edited by HW on April 23 2026
	preserve
		
		* Step 1: aggregate daily residuals to worker-week level
		keep if phase == 2
		collapse (mean) w_mean = resid_day_attendph2 (count) w_n = resid_day_attendph2 (first) standid , ///
			by(calendar_week pid)

		* Step 2: stand-week totals
		bysort standid calendar_week: egen sw_mean 	= total(w_mean)
		bysort standid calendar_week: egen sw_n		= total(w_n)

		* Step 3: worker-level LOO mean
		gen double avg_wkattend_loo = (sw_mean - w_mean) / (sw_n - 1)
		* avg_wkattend_loo is now constant within worker x stand x week:
		* it is the mean of other workers' daily residuals at that stand-week.

		keep pid calendar_week avg_wkattend_loo
		gen dow = 2

		tempfile loo_worker_week
		save `loo_worker_week'

		sum avg_wkattend_loo , d 
		scalar pct_j_attend = r(p25)

	restore

	* Merge LOO back into the full daily panel
	merge m:1 pid calendar_week dow using `loo_worker_week', keep(1 2 3) nogen

	* Indicator for Shock
	gen wkof_attend_j = (avg_wkattend_loo <= pct_j_attend) if avg_wkattend_loo!=.

	* First calendar week of shock (Leave one out, varies by pid)
	gen calwk_of_shock = stand_ph_calweek if wkof_attend_j==1
	bys pid : egen firstofshock_calwk_j = min(calwk_of_shock)
	drop calwk_of_shock

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
		
	* Two+ weeks post shock
	gen attend_j_post2p = (wks_since_shock_j>=2 & !mi(wks_since_shock_j))
	gen attendloo25_post2p = attend_j_post2p
	gen treatXattend_j_post2p = treatment*attend_j_post2p
	gen treatXattendloo25_post2p = treatXattend_j_post2p
	
	

****
**## 3. Shocks Regression Analysis
****
reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)

reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
