/****
Project:          Labor Discipline  

Purpose:          Analysis of LD Data - All results in slides/paper

Filepath:         Labor Discipline/07. Data/3. Main Study 3.0/05. Analysis/01. Code

Inputs:            07. Data/3. Main Study 3.0/02. Cleaning Data/Analysis Prep/02. Output/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta

Last modified:    2024-11-14 (YS) update tables in draft and slides
 
****/

/*----------------------------------------------------*/
   /* [>   0.  Set directory    <] */ 
/*----------------------------------------------------*/

	clear all
	set more off

	// Specifying user-dependent globals (Dropbox and Overleaf)
	if "`c(username)'" == "yogita"{
		global user yogita
		cd "/Users/${user}/Dropbox/Labor Discipline"
		do "07. Data/3. Main Study 3.0/master.do"
	}
	 else if "`c(username)'" == "luisacefala"{
	 	global user luisacefala
		cd "/Users/${user}/Dropbox/Labor Discipline"
		do "07. Data/3. Main Study 3.0/master.do"
	}
	 else if "`c(username)'" == "hschof"{
		cd "C:\Users\hschof\Dropbox\Labor Discipline"
		do "07. Data\3. Main Study 3.0\master.do"
	}
	else if "`c(username)'" == "supreet"{
		global user supreet
		cd "/Users/${user}/Dropbox/Labor Discipline"
		do "07. Data/3. Main Study 3.0/master.do"
	}
	else if "`c(username)'" == "prayog"{
		global user prayog
		cd "/Users/${user}/NUS Dropbox/Prayog Bhattarai/Labor Discipline"
		do "07. Data/3. Main Study 3.0/master.do"
	}
	else if "`c(username)'" == "danhuang"{ // Hao Wang added Jul 16 2024
		global user danhuang
		cd "/Users/danhuang/Library/CloudStorage/Dropbox/Labor\ Discipline"
		do "07. Data/3. Main Study 3.0/master.do"
	}

	* SK: I cant get the below command to work. I added the below file to my ado folder. I also tried installing "ssc install blindschemes". Commenting out for now.
	set scheme plotplain_custom //set plot scheme
		*need to have this saved in Applications/Stata/ado folder
		* scheme file "scheme-plotplain_custom.scheme" is saved in the same folder as this code (Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/05. Analysis/01. Code)

/*----------------------------------------------------*/
   /* [>   1.  Open data    <] */ 
/*----------------------------------------------------*/

	use "07. Data/3. Main Study 3.0/02. Cleaning Data/Analysis Prep/02. Output/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta", clear
	* data is at the person-day level 
	* 13 days in Phase 0 (BL), 48 days in Phase 1 (7 weeks; final week is Mon-Saturday) and 55 days in 2 respectively (8 weeks; final week is Mon-Saturday)
	isid pid phase week_in date, missok
	assert phase!=.
	assert week_in!=.
		* date is missing for phase 3  
		* week in resets for each phase (i.e. goes from 1-7 for phase 1, 1-8 for phase 2)

	** Checks on data 
	* tab phase, m 
	/*
    Phase of |
   experiment |      Freq.     Percent        Cum.
  ------------+-----------------------------------
            0 |      2,949       10.64       10.64
            1 |     10,800       38.97       49.62
            2 |     12,370       44.64       94.25
            3 |      1,592        5.75      100.00
  ------------+-----------------------------------
        Total |     27,711      100.00
	*/

	* tab attend if phase <3 & holiday !=1 & dow !=0, m 
	assert late_announcement_flag==1 if phase <3 & holiday !=1 & dow !=0 & attend==.
	/*
	     Attend |
		(daily) |      Freq.     Percent        Cum.
	------------+-----------------------------------
			  0 |     10,406       48.23       48.23
			  1 |     11,135       51.60       99.83
			  . |         37        0.17      100.00
	------------+-----------------------------------
		  Total |     21,578      100.00

	* 37 missing obs. Correspond to late announcement participants. Attendance is coded as . on the day they receive the late announcement and on the days prior 
	*/

	assert mode==3 if (dow==0 | holiday==1) & phase==1
	/*  
	Issues with data 
	tab mode if (dow==0 | holiday==1) & phase==2
		* FIXME 72 obs marked as in person/phone.. how can this be?
	*/

	* merge in events calendar (holidays, festivals etc.)
	drop _merge 
	merge m:1 date using "./07. Data/3. Main Study 3.0/02. Cleaning Data/08. Others/02. Output/Events calendar/calevents_clean.dta"
	* tab date if _merge==2 // these are dates outside the study dates, so not relevant 
	drop if _merge==2
	assert phase==3 if _merge==1  //phase 3 
	drop _merge 
	
/*----------------------------------------------------*/
   /* [>   2.  Generate new variables (SK)    <] */ 
/*----------------------------------------------------*/
	* FIXME move to dm file once we know which variables are relevant to keep.
	
	gen treat = treatment
	
  *** IDENTIFIERS
  	egen standid = group(stand)

  	* 1 obs per pid week_in phase
	  sort pid phase week_in date
      by pid phase week_in: gen pid_phase_week = 1 if [_n==1]
	* 1 obs per pid calendar_week phase
      sort pid phase calendar_week date
	  by pid phase calendar_week: gen pid_phase_calweek = 1 if [_n==1]
    * 1 obs per pid 
      by pid: gen pid_1 = 1 if [_n==1]
    * 1 obs per date per stand
      sort standid date pid
      by standid date: gen tag_stand_date = 1 if [_n==1]
    * 1 obs per stand-phase-week
      sort standid phase week_in date pid
      by standid phase week_in: gen tag_stand_phase_week = 1 if [_n==1]
    * 1 obs per stand-calendar week
      sort standid calendar_week date pid
      by standid calendar_week: gen tag_stand_calweek = 1 if [_n==1]
	
	* create calweek counter for each standXphase
		sort standid phase calendar_week date pid
		by standid phase calendar_week: gen stand_ph_calweek_id1 = 1 if _n==1
		egen temp2 = seq() if stand_ph_calweek_id1 == 1, by(standid phase)
		egen stand_ph_calweek = max(temp2), by(standid phase calendar_week)
		gen treatXstand_ph_calweek = treat*stand_ph_calweek
		drop temp*
		* de-meaned
			egen temp1 = mean(stand_ph_calweek) if dow==1, by(pid phase)
			egen temp2 = max(temp1), by(pid phase)
			gen stand_ph_calweek_dm = stand_ph_calweek - temp2
				drop temp*
			gen treatXstand_ph_calweek_dm = treat*stand_ph_calweek_dm 
	
	* week_in variables
		* de-meaned week_in
			egen temp1 = mean(week_in) if dow==1, by(pid phase)
			egen temp2 = max(temp1), by(pid phase)
			gen week_in_dm = week_in - temp2
				drop temp*
			gen treatXweek_in_dm = treat*week_in_dm
		* week-in variable that spans phase 2 and 3
			egen temp1 = max(week_in) if phase==2, by(pid)
			egen temp2 = max(temp1), by(pid)
			gen week_in23 = week_in if phase<=2
				replace week_in23 = week_in + temp2 if phase==3
				drop temp*
			gen treatXweek_in23 = treat*week_in23
		* de-meaned phase 2-3 week_in
			egen temp1 = mean(week_in23) if dow==1 & phase>=2, by(pid)
			egen temp2 = max(temp1), by(pid)
			gen week_in23_dm = week_in_dm if phase<2
				replace week_in23_dm = week_in23 - temp2
				drop temp*
			gen treatXweek_in23_dm = treat*week_in23_dm
		* interactions etc
			gen post23week5 = (week_in23>=5) if week_in23!=.
			gen treatXpost23week5 = treat*(week_in23>=5)

  ***  FIXED EFFECTS
  	egen stand_strata_FE = group(stand strata) 
  	egen stand_weekin_FE = group(stand week_in) 

  *** WEEKLY VARS
  	egen holiday_week = max(holiday), by(pid phase week_in)

  *** ATTEND VARIABLE
    gen attend_wk = attend_nadj if phase<=2
    replace attend_wk = attend_adj if phase==3

  *** TREATMENT DUMMIES
  	*gen treat = treatment
  	gen treatXphase0 = treat*(phase==0)
  	gen treatXphase1 = treat*(phase==1)
  	gen treatXphase2 = treat*(phase==2)
  	gen treatXphase3 = treat*(phase==3)

  	gen treatXweek_in = treat*week_in
    gen treatXpostweek4 = treat*(week_in>=4)
    gen treatXpostweek5 = treat*(week_in>=5)
    gen treatXpostweek6 = treat*(week_in>=6)

		gen treatXcalendar_week = treat*calendar_week

    /* treatXcalweek
    egen temp = seq() if tag_stand_calweek==1, by(standid phase)
      *FIXME YS i don't fully understand this.
    egen calweek_seq = max(temp), by(standid calendar_week)
    drop temp
    gen treatXcalweekseq = treat*calweek_seq
		*/

  	* Other interactions with phase
  	forvalues i=1/3 {
  		foreach v of varlist bs_avg_wage bs_sum_work bs_sum_attend bs_sum_wage {
  			gen `v'Xphase`i' = `v'*(phase==`i')
  		}
  	}

    *** Figure out most recent 7 days from end of baseline
      capture drop temp*
      egen temp = max(date) if phase==0, by(pid)
      gen ph0_days_from_end = temp-date+1
      egen temp2 = sum(attend) if ph0_days_from_end<=7, by(pid)
      egen temp3 = sum(attend) if ph0_days_from_end>7 & ph0_days_from_end<=14, by(pid)
      *replace week_in=1 if ph0_days_from_end<=7
      replace week_in=0 if ph0_days_from_end>7 & ph0_days_from_end<=14
      drop temp*

      egen temp = max(daycount) if phase==0, by(pid)
      egen baseline_length = max(temp), by(pid)
      drop temp

  ***************** OUTCOMES *******************
  	* fill in attend for phase 3
  	*replace attend_nadj = attend_adj if phase==3
  	*replace attend_week = 6 if phase==3

  	** Restrictions on work_recall_mode
  		* was any of the week's observations from in person surveys
  		egen temp = min(work_recall_mode), by(pid phase week_in)
  		gen work_recall_mode_any1 = (temp==1)
  		drop temp
  		* was any of the week's observations from phone surveys
  		gen temp2 = (work_recall_mode==2)
  		egen temp = max(temp2), by(pid phase week_in)
  		gen work_recall_mode_any2 = (temp==1)
  		drop temp*
  		* was any of the week's observations missing
  		gen temp3 = (work_recall_mode==3)
  		egen temp = max(temp3), by(pid phase week_in)
  		gen work_recall_mode_any3 = (temp==1)
  		drop temp*

  	** Restrictions on recall_length
  		* was any of the week's observations from grid recall (length<7)
  		gen temp1 = (recall_length<=7) /* will=1 if recall < 7 days ago & work not missing */
  		egen grid_recall_anyinwk = max(temp1), by(pid phase week_in)
  		drop temp*
  		* were any of the week's observations from long recall (length>7)
  		gen temp1 = (recall_length==.) /* will=1 if recall > 7 days ago or work missing */
  		egen long_recall_anyinwk = max(temp1), by(pid phase week_in)
  		drop temp*

  	* work found at stand - recode missings as zero
  		gen work1_fromstand = found_at_stand2
  		replace work1_fromstand = 0 if found_at_stand2==.

  	* New weekly variables
  		* 1) no restrictions
  			egen work1_wkly1 = total(work1), by(pid phase week_in)
  			egen work1_fromstand_wkly1 = total(work1_fromstand), by(pid phase week_in)
  		* 2) reliable data - in person & <=7 days (grid recall, not imputed)
  			* overall work
  			gen temp1 = work1 if recall_length<=7 & work_recall_mode==1
  			egen temp2 = total(temp1) if grid_recall_anyinwk==1 & work_recall_mode_any1==1, by(pid phase week_in)
  			egen work1_wkly2 = max(temp2), by(pid phase week_in)
  			drop temp*
  			* work at stand
  			gen temp1 = work1_fromstand if recall_length<=7 & work_recall_mode==1
  			egen temp2 = total(temp1) if grid_recall_anyinwk==1 & work_recall_mode_any1==1, by(pid phase week_in)
  			egen work1_fromstand_wkly2 = max(temp2), by(pid phase week_in)
  			drop temp*

  ***************** BL VARIABLES *******************

      * bl work - smaller categories
      gen bl_modaloccup = 0
      replace bl_modaloccup = 4 if  modal_workbaseline==4 
      replace bl_modaloccup = 7 if  modal_workbaseline==7 

      * reconstruct modal baseline wage
      egen temp1 = mode(earn) if phase==0 & earn>0, by(pid)
      egen bl_modalwage = max(temp1), by(pid)
      replace bl_modalwage = 0 if bl_modalwage==.
      drop temp1

      * baseline covariates
      * attend
      egen temp = mean(attend) if phase==0, by(pid)
      egen bl_attend = max(temp), by(pid)
      drop temp
      gen bl_hiattend = (bl_attend>=0.45) if bl_attend!=. //median 0.4545455
      gen bl_hiattend2 = (bl_attend>0.5) if bl_attend!=.
      * interactions with treat
      gen treatXbl_attend = treat*bl_attend
      gen treatXbl_hiattend = treat*bl_hiattend
      gen treatXbl_hiattend2 = treat*bl_hiattend2

      * earnings 
      egen temp = mean(earn) if phase==0, by(pid)
      egen bl_earn = max(temp), by(pid)
      gen miss_bl_earn = (bl_earn==.)
      replace bl_earn = 0 if miss_bl_earn==1
      drop temp

    ***************** PHASE 3 *******************
      * how many days since last survey
      * infer from attend_adj variable
      * tab attend_nadj if phase==3
      gen attend_nadj_temp = attend_nadj
      replace attend_nadj_temp = 1 if attend_nadj>0 & attend_nadj<1

    * id seq() for pid's within each stand
      egen temp = seq() if pid_1==1, by(stand)
      egen id_standpid = max(temp), by(pid)
      drop temp
      egen max_standpid = max(id_standpid), by(stand)

    * id seq() for dates within each stand in each phase
      egen temp = seq() if tag_stand_date==1, by(stand phase)
      egen id_standphaseday = max(temp), by(stand phase)
      drop temp*
      egen max_standphaseday = max(id_standphaseday), by(stand phase)

  ***************** SHOCKS - STAND ATTENDANCE *******************
	/* CHOICES
		- initial reg for residuals
		- when computing percentiles - lag values or contemporaneous values; 1 obs per week or all data
	
	*/
	
	
	* DAILY ATTENDANCE RESIDUALS - predict residuals taking out BL attend and stand + phase FE
		* FOR CONTROL GROUP ONLY SPECS
			** Initial control group default:
			* capture reg attend bl_attend i.standid i.phase if treat==0 
			* predict resid_day_attendph2 if phase==2, residuals
			
		* FOR LOO SPECS
			* capture reg attend bl_attend bl_earn miss_bl_earn standid##phase standid##treat if phase<2		
			* capture reg attend bl_attend bl_earn miss_bl_earn standid##phase##treat if phase<2
			* capture reg attend bl_attend bl_earn miss_bl_earn standid##treat if phase<2 /* terrible unless you interact with phase */
			* capture reg attend bl_attend bl_earn miss_bl_earn i.standid i.phase i.treat if phase<2 /* terrible unless you interact with phase */
			* capture reg attend bl_attend bl_earn miss_bl_earn i.standid treat##phase if phase<2
			
			/*
			* manually code standid*phase interactions - verifies default (will predict based on phase = 0)
			forvalues i=1/11 {
				gen ph1Xstandid`i' = (phase==1)*(standid==`i')
			}
			reg attend bl_attend i.standid i.phase ph1Xstandid* standid##treat if phase<2
			*/
			
			/*
			* prior:
			capture reg attend bl_attend bl_earn miss_bl_earn standid##phase standid##treat if phase<2	
			capture reg attend bl_attend bl_earn miss_bl_earn standid##phase##treat if phase<2	
			**** capture reg attend bl_attend standid##phase##treat if phase<2
			
			* no 
			* capture reg attend standid##phase##treat if phase<2
			* capture reg attend bl_attend i.bl_modaloccup bl_modalwage standid##phase##treat if phase<2
			
			* Not bad: baseline data only (still leave one out)
				capture reg attend bl_attend i.standid treat if phase==0
			* a bit worse but qualitatively similar (can also remove treat)
				capture reg attend i.standid treat if phase==0
			* just individual FE in phase 0 - treat dummy noisy, but interaction fine (similar if do phase<2 & interaction phase with pid)
				capture reg attend i.pid if phase==0
			*/
			
			* final
			capture reg attend bl_attend standid##phase##treat if phase<2
			predict resid_day_attendph2 if phase==2, residuals

		
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
			* interaction for first stage
				gen treatXavg_wkattend_loo = treat*avg_wkattend_loo
			* get lagged weekly value for each PID
				* tag for 1 obs per stand-pid-calendar_week
				  sort standid pid2 calendar_week date
				  by standid pid2 calendar_week: gen tag_stand_pid2_calweek = 1 if [_n==1]
				* create lagged weekly stand attendance for each PID
				  sort tag_stand_pid2_calweek standid pid2 calendar_week date
				  by tag_stand_pid2_calweek standid pid2: gen templag = avg_wkattend_loo[_n-1] if tag_stand_pid2_calweek==1 & phase<=2
				  egen lag1avg_wkattend_loo = max(templag), by(pid2 calendar_week)
	
	
	/*
	* WEEKLY ATTENDANCE CONTROL GROUP MEAN - simple control group average
	  
	  /* this code is taking daily averages for control group, and then converting to weekly (could do in one step)
	  * daily average for stand - only makes sense if using only control group avg
			egen temp = mean(resid_day_attendph2) if treat==0, by(standid date)
			egen avgr_day_attendph2 = max(temp), by(standid date)
			drop temp
	  * weekly attendance for control group
		  egen temp = mean(avgr_day_attendph2) if treat==0, by(standid calendar_week)
		  egen avgr_attendph2_cwk = max(temp), by(standid calendar_week) 
	  */
	  
	  * weekly attendance for control group - mean of week-wise residuals
		  egen temp = mean(resid_day_attendph2) if treat==0, by(standid calendar_week)
		  egen avg_wkattend_ctrl = max(temp), by(standid calendar_week) 
	  
      * lagged week value
			gen lag_calweek = calendar_week-1
			* sort so that we have 1 obs per stand_calweek to get lags 
			sort tag_stand_calweek standid calendar_week date pid
			forvalues w=1/4 {
			  * create lags for one obs per stand-week
			  by tag_stand_calweek standid: gen temp`w' = avg_wkattend_ctrl[_n-`w'] if tag_stand_calweek==1 & phase<=2
			  * fill out remaining obs
			  egen lag`w'avg_wkattend_ctrl = max(temp`w'), by(standid calendar_week)
			}
			drop temp*
			* br tag_stand_calweek standid calendar_week date pid avgr_attendph2_cwk lag*avgr_attendph2_cwk
	*/
			
	  
	  
    ***** USING THIS VAR
    * Average of calendar week is below threshold (using version that removes phase FE)

    * Generate 10th, 20th, 25th, and 50th percentiles
    *_pctile  lag1avgr_attendph2_cwk if phase==2 & lag1avgr_attendph2_cwk!=., p(10, 20, 25, 30, 50)
     * weekly attend
		
		/*
		* control group averages
		  _pctile  lag1avg_wkattend_ctrl if phase==2 & lag1avg_wkattend_ctrl!=., p(5, 10, 15, 20, 25, 30, 50)
		  * one obs per stand-week-phase
		  * _pctile  lag1avg_wkattend_ctrl if phase==2 & lag1avg_wkattend_ctrl!=. & tag_stand_phase_week==1, p(5, 10, 15, 20, 25, 30, 50)
		  return list 
			scalar pct5_attendctrl = r(r1)
			scalar pct10_attendctrl = r(r2)
			scalar pct15_attendctrl = r(r3)
			scalar pct20_attendctrl = r(r4)
			scalar pct25_attendctrl = r(r5)
			scalar pct30_attendctrl = r(r6)
			scalar pct50_attendctrl = r(r7)
		*/
		
		* leave one out means
		* FIXME YS should we only use one obs per pid-cal week? so we further condition on dow==1
		* original
		* _pctile  avg_wkattend_loo if phase==2 & avg_wkattend_loo!=., p(5, 10, 15, 20, 25, 30, 50)
		
		* one obs per pid-calweek
		_pctile  avg_wkattend_loo if phase==2 & avg_wkattend_loo!=. & dow==1, p(5, 10, 15, 20, 25, 30, 50)
		*_pctile  lag1avg_wkattend_loo if phase==2 & avg_wkattend_loo!=. & dow==1, p(5, 10, 15, 20, 25, 30, 50)		
		
		return list 
			scalar pct5_attendloo = r(r1)
			scalar pct10_attendloo = r(r2)
			scalar pct15_attendloo = r(r3)
			scalar pct20_attendloo = r(r4)
			scalar pct25_attendloo = r(r5)
			scalar pct30_attendloo = r(r6)
			scalar pct50_attendloo = r(r7)
		
		/*
		foreach p in 5 10 15 20 25 {
			  *di pct`p'_attendctrl
			  
			  * week of shock
			  gen wkof_attendctrl_b`p' = (avg_wkattend_ctrl < pct`p'_attendctrl) if phase==2 & avg_wkattend_ctrl!=.
			  gen treatXwkof_attendctrl_b`p' = treat*wkof_attendctrl_b`p'
			  
			  * week after shock
			  gen avgr_attendctrl_b`p' = (lag1avg_wkattend_ctrl < pct`p'_attendctrl) if phase==2 & lag1avg_wkattend_ctrl!=.
			  * mark all future obs in phase 2 as 1 after one of these events
				  sort standid pid date
				  gen post_attendctrl_b`p' = .
				  replace post_attendctrl_b`p' = 1 if avgr_attendctrl_b`p'==1 & phase==2
				  by standid pid: replace post_attendctrl_b`p' = post_attendctrl_b`p'[_n-1] if phase==2 & post_attendctrl_b`p'[_n-1]!=.
				* replace phase 2 missings as 0
				  replace post_attendctrl_b`p' = 0 if post_attendctrl_b`p'==. & phase==2
				* fill out variable for phase 3
				  egen temp = max(post_attendctrl_b`p') if phase>=2, by(pid)
				  replace post_attendctrl_b`p' = temp if phase==3
				  drop temp
				* interactions
				  gen treatXpost_attendctrl_b`p' = treat*post_attendctrl_b`p'
		}
		*/
		
		* leave one out means
			  * foreach p in 5 10 15 20 25 30 {
			  foreach p in 20 25 {
			   
				  * dummy for below `p' percentile in that week
					gen wkof_attendloo_b`p' = (avg_wkattend_loo < pct`p'_attendloo) if phase==2 & avg_wkattend_loo!=.
					gen treatXwkof_attendloo_b`p' = treat*wkof_attendloo_b`p'
				  
				  * first calendar week of shock - loo - varies by pid
					gen temp = stand_ph_calweek if wkof_attendloo_b`p'==1 & phase==2
					egen firstpostshockl_calwk`p' = min(temp) if phase==2, by(pid)
					drop temp*
					egen firstpostshockl_calwk`p'all = max(firstpostshockl_calwk`p'), by(pid)
					gen treatXfirstpostshockl_calwk`p'all = treat*firstpostshockl_calwk`p'all		
				  
				  * weeks since shock
					gen wks_since_shock`p' = stand_ph_calweek - firstpostshockl_calwk`p' if phase==2
				  
				  * dummy for first week in which shock happens (contemporaneous shock)
					gen firstwk_attendloo_b`p' = (wks_since_shock`p' == 0)
					gen treatXfirstwk_attendloo_b`p' = treat*firstwk_attendloo_b`p'
				  
				  * post variable
					gen post_attendloo_b`p' = (wks_since_shock`p' > 0 & wks_since_shock`p'<.)
					
					* fill out variable for phase 3
					egen temp = max(post_attendloo_b`p') if phase>=2, by(pid)
					replace post_attendloo_b`p' = temp if phase==3
					drop temp
					* interactions
					gen treatXpost_attendloo_b`p' = treat*post_attendloo_b`p'
					
					/*
					* Initial code
					  * week after shock
					  gen avgr_attendloo_b`p' = (lag1avg_wkattend_loo < pct`p'_attendloo) if phase==2 & lag1avg_wkattend_loo!=.
					  * mark all future obs in phase 2 as 1 after one of these events
					  sort standid pid date
					  gen post_attendloo_b`p' = .
					  replace post_attendloo_b`p' = 1 if avgr_attendloo_b`p'==1 & phase==2
					  by standid pid: replace post_attendloo_b`p' = post_attendloo_b`p'[_n-1] if phase==2 & post_attendloo_b`p'[_n-1]!=.
					  * replace phase 2 missings as 0
					  replace post_attendloo_b`p' = 0 if post_attendloo_b`p'==. & phase==2
					  * fill out variable for phase 3
					  egen temp = max(post_attendloo_b`p') if phase>=2, by(pid)
					  replace post_attendloo_b`p' = temp if phase==3
					  drop temp
					  * interactions
					  gen treatXpost_attendloo_b`p' = treat*post_attendloo_b`p'
					 */
			  }  
			 
	* figure out first calendar_week of shock for all stands in phase 2
			
			/*
			* first calendar week for shocks - ctrl
			foreach p in 5 10 15 20 25 {
				gen temp = stand_ph_calweek if post_attendctrl_b`p'==1 & phase==2
				egen firstpostshockc_calwk`p' = min(temp) if phase==2, by(pid)
				* instead of pid, could have this vary by stand_id
				drop temp*
				egen firstpostshockc_calwk`p'all = max(firstpostshockc_calwk`p'), by(pid)
				gen treatXfirstpostshockc_calwk`p'all = treat*firstpostshockc_calwk`p'all
			}
			*/
						
			* heterogeneous effects versions - binary for whether stand had a shock before a given week
			* foreach p in 10 15 20 25 30 {
			foreach p in 20 25 {
				forvalues w=1/11 {
					gen temp = (firstpostshockl_calwk`p'<=`w') if phase==2				
					egen hadshockloo`p'_pre`w' = max(temp), by(pid)
					gen treatXhadshockloo`p'_pre`w' = treat*hadshockloo`p'_pre`w'
					drop temp
				}
			}

		* Event study dummies
			*foreach p in 10 15 20 25 30 {
			foreach p in 20 25 {
				* post variables
				gen attendloo`p'_post1 = (wks_since_shock`p'==1)
				gen attendloo`p'_post2 = (wks_since_shock`p'==2)
				gen attendloo`p'_post2p = (wks_since_shock`p'>=2 & wks_since_shock`p'<.)
				gen attendloo`p'_post3 = (wks_since_shock`p'==3)
				gen attendloo`p'_post3p = (wks_since_shock`p'>=3 & wks_since_shock`p'<.)
				gen attendloo`p'_post4 = (wks_since_shock`p'==4)
				gen attendloo`p'_post34 = (wks_since_shock`p'==3 | wks_since_shock`p'==4)
				gen attendloo`p'_post5 = (wks_since_shock`p'==5)
				gen attendloo`p'_post5p = (wks_since_shock`p'==5) + (wks_since_shock`p'==6) + (wks_since_shock`p'==7) + (wks_since_shock`p'==8) + (wks_since_shock`p'==9)
				gen attendloo`p'_post6p = (wks_since_shock`p'>=6 & wks_since_shock`p'<.)
		
				* pre variables
				gen attendloo`p'_pre1 = (wks_since_shock`p'==-1)
				gen attendloo`p'_pre2 = (wks_since_shock`p'==-2)
				gen attendloo`p'_pre3 = (wks_since_shock`p'==-3)
				gen attendloo`p'_pre23 = (wks_since_shock`p'==-2 | wks_since_shock`p'==-3)
				gen attendloo`p'_pre4 = (wks_since_shock`p'==-4)
				gen attendloo`p'_pre4p = (wks_since_shock`p'<=-4) 
				gen attendloo`p'_pre5p = (wks_since_shock`p'==-5) + (wks_since_shock`p'==-6) + (wks_since_shock`p'==-7) + (wks_since_shock`p'==-8) + (wks_since_shock`p'==-9)
				gen attendloo`p'_pre34 = (wks_since_shock`p'==-3 | wks_since_shock`p'==-4) 

				* interactions
					forvalues w=1/5 {
						gen treatXattendloo`p'_post`w' = treat*attendloo`p'_post`w'
					}
					gen treatXattendloo`p'_post2p = treat*attendloo`p'_post2p
					gen treatXattendloo`p'_post3p = treat*attendloo`p'_post3p
					gen treatXattendloo`p'_post34 = treat*attendloo`p'_post34
					gen treatXattendloo`p'_post5p = treat*attendloo`p'_post5p
					gen treatXattendloo`p'_post6p = treat*attendloo`p'_post6p
					
					forvalues w=1/4 {
						gen treatXattendloo`p'_pre`w' = treat*attendloo`p'_pre`w'
					}
					gen treatXattendloo`p'_pre5p = treat*attendloo`p'_pre5p
					gen treatXattendloo`p'_pre4p = treat*attendloo`p'_pre4p
					gen treatXattendloo`p'_pre23 = treat*attendloo`p'_pre23
					gen treatXattendloo`p'_pre34 = treat*attendloo`p'_pre34
				
				* check
				* gen temp1 = attendloo25_post1 + attendloo25_post2 + attendloo25_post3 + attendloo25_post4 + attendloo25_post5p
			}
			
			/*
			foreach p in 10 15 20 25 30 {
				gen attendloo`p'_post3p = (wks_since_shock`p'>=3 & wks_since_shock`p'<.)
				gen treatXattendloo`p'_post3p = treat*attendloo`p'_post3p
			}
			*/
			
/*----------------------------------------------------*/
   /* [>   3.  SK new code (shocks table)    <] */ 
/*----------------------------------------------------*/

* 4 column table in slides with bootstrap p-vals in []
	eststo clear 
		matrix pval = (.,.,.,.,.,.) //for the 6 coefficients that we intend to report 
		matrix colnames pval = treat treatXpost_attendloo_b25 post_attendloo_b25_temp treatXattendloo25_post1 treatXattendloo25_post2p treatXweek_in_dm
		matrix list pval

	* Column 1 - phase 2 (2 months) ATE:
		* bootstrapped p-values
		reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
		boottest {treat}, seed(123) reps(2048) boottype(wild) nograph
		matrix pval[1,1] = r(p)
		boottest {treatXpost_attendloo_b25}, seed(123) reps(2048) boottype(wild) nograph
		matrix pval[1,2] = r(p)

		eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
		estadd local calweek "Yes", replace
		estadd matrix pval 

	* Column 2 - time trend 
		* bootstrapped p-values
		reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
		boottest {treat} {treatXpost_attendloo_b25} {treatXweek_in_dm}, seed(123) reps(2048) boottype(wild) nograph 
			matrix pval[1,1] = r(p_1)	
			matrix pval[1,2] = r(p_2)
			matrix pval[1,6] = r(p_3)

		eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
		estadd local calweek "Yes", replace
		estadd matrix pval 

		/*
		* Column 3 
		cap drop post_attendloo_b25_temp
		gen post_attendloo_b25_temp = post_attendloo_b25
		label var post_attendloo_b25_temp "Post shock"
		* bootstrapped p-values
		reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25_temp treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
		boottest {treat} {treatXpost_attendloo_b25} {post_attendloo_b25_temp}, seed(123) reps(2048) boottype(wild) nograph 	
			matrix pval[1,1] = r(p_1) 
			matrix pval[1,2] = r(p_2)
			matrix pval[1,3] = r(p_3)
			matrix pval[1,6] = .

		eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25_temp treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
 		estadd local calweek "Yes", replace
		estadd matrix pval 
		*/

	* Column 3 
		* bootstrapped p-values
		reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
		boottest {treat} {treatXattendloo25_post1} {treatXattendloo25_post2p}, seed(123) reps(2048) boottype(wild) nograph
			matrix pval[1,1] = r(p_1)
			matrix pval[1,2] = .
			matrix pval[1,3] = .
			matrix pval[1,4] = r(p_2)
			matrix pval[1,5] = r(p_3)
			matrix pval[1,6] = .

		eststo: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
  		estadd local calweek "Yes", replace
		estadd matrix pval 

	* Column 4
		* bootstrapped p-values
		reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
		boottest {treat} {treatXattendloo25_post1} {treatXattendloo25_post2p} {treatXweek_in_dm}, seed(123) reps(2048) boottype(wild) nograph 	
			matrix pval[1,1] = r(p_1)
			matrix pval[1,4] = r(p_2)
			matrix pval[1,5] = r(p_3)
			matrix pval[1,6] = r(p_4)

		eststo: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
		estadd local calweek "Yes", replace
		estadd matrix pval

	label var treat "Treat"
	label var treatXpost_attendloo_b25 "Treat x Post shock"
	*label var post_attendloo_b25_temp "Post shock"
	label var treatXattendloo25_post1 "Treat x 1 week post shock"
	label var treatXattendloo25_post2p "Treat x 2+ weeks post shock"
	label var treatXweek_in_dm "Treat x Week number"

	esttab using "${output_overleaf}/tables/shocks_attendloo_b25_bootp.tex", se keep(treat treatXpost_attendloo_b25 treatXattendloo25_post1 treatXattendloo25_post2p treatXweek_in_dm) order(treat treatXpost_attendloo_b25 treatXattendloo25_post1 treatXattendloo25_post2p treatXweek_in_dm) nomti l nonotes nostar replace cells(b(fmt(3)) se(fmt(3) par) pval(fmt(3) par("[" "]") pvalue(pval))) stats(calweek N, labels("Calendar Week FE" "N: worker-weeks") fmt(%9.0fc %9.0fc)) frag collabels(none) gap 	
			* post_attendloo_b25_temp

	* Replace the (.) with blanks 
		* Define the file path
		local inputfile "${output_overleaf}/tables/shocks_attendloo_b25_bootp.tex"

		* Initialize an empty string to store file content
		local content = ""

		* Open the input file for reading
		file open infile using "`inputfile'", read text
		* Read each line from the input file
		file read infile line
		while r(eof) == 0 {
		    * Append the line to the content
		    local content = `"`content'"' + " " + `"`line'"'
		    file read infile line
		}
		* Close the file after reading
		file close infile

		* Display the original content for debugging
		display "Original Content:"
		display "`content'"

		* Perform the replacements in the content
		local content = subinstr("`content'", "[.]&", "&", .)
		local content = subinstr("`content'", "[.]\\", "\\", .)

		* Display the modified content for debugging
		display "Modified Content:"
		display "`content'"

		* Open the file again for writing
		file open infile using "`inputfile'", write text replace
		* Write the modified content back to the file
		file write infile "`content'"
		* Close the file after writing
		file close infile

	/* 	Original code
	* Col 1 - Phase 2 (2 months) ATE:
	eststo m1: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
	estadd local calweek "Yes", replace
	* bootstrapped p-values
	reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
	boottest {treat} {treatXpost_attendloo_b25}, seed(123) reps(2048) boottype(wild) nograph 	
	* FIXME Prayog how do we incorporate the wild bootstrap p-values?

	* Col 2 - time trend
	eststo m2: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
	estadd local calweek "Yes", replace
	* bootstrapped p-values
	reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
	boottest {treat} {treatXpost_attendloo_b25}, seed(123) reps(2048) boottype(wild) nograph 	
	* FIXME Prayog how do we incorporate the wild bootstrap p-values?

	* Col 3 - remove time trend, show coeff on post 
	gen post_attendloo_b25_temp = post_attendloo_b25
	eststo m3: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25_temp  treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata if phase==2 , vce(cluster standid)
  estadd local calweek "No", replace
	* bootstrapped p-values
	reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25_temp treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata if phase==2, vce(cluster pid)
	boottest {treat} {treatXpost_attendloo_b25} {post_attendloo_b25_temp}, seed(123) reps(2048) boottype(wild) nograph 	
	* FIXME Prayog how do we incorporate the wild bootstrap p-values?

	* Col 4 - immediate effects (post event study dummies)
	eststo m4: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
  estadd local calweek "Yes", replace
	* bootstrapped p-values
	reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
	boottest {treat} {treatXattendloo25_post1} {treatXattendloo25_post2p}, seed(123) reps(2048) boottype(wild) nograph
	* FIXME Prayog how do we incorporate the wild bootstrap p-values?

	* Col 5 - immediate effects (post event study dummies) + time trend
	eststo m5: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
  estadd local calweek "Yes", replace
	* bootstrapped p-values
	reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
	estadd local calweek "Yes", replace
	boottest {treat} {treatXattendloo25_post1} {treatXattendloo25_post2p} {treatXweek_in_dm}, seed(123) reps(2048) boottype(wild) nograph 	

	* FIXME Prayog how do we incorporate the wild bootstrap p-values?

	label var treat "Treat"
	label var treatXpost_attendloo_b25 "Treat x Post shock"
	label var post_attendloo_b25_temp "Post shock"
	label var treatXattendloo25_post1 "Treat x 1 week post shock"
	label var treatXattendloo25_post2p "Treat x 2+ weeks post shock"
	label var treatXweek_in_dm "Treat x Week number"

	esttab using "${output_overleaf}/tables/shocks_attendloo_b25.tex", se keep(treat treatXpost_attendloo_b25 post_attendloo_b25_temp treatXattendloo25_post1 treatXattendloo25_post2p treatXweek_in_dm) order(treat treatXpost_attendloo_b25 post_attendloo_b25_temp treatXattendloo25_post1 treatXattendloo25_post2p treatXweek_in_dm) nomti l nonotes nostar replace cells(b(fmt(a3)) se(fmt(3) par) "bootpval(fmt(3) par([ ]))") stats(calweek N, labels("Calendar Week FE" "N: worker-weeks")) frag collabels(none) gap
 */	

* 7 column table for draft - 2 additional columns (first two) det of effects over time
	* FIXME: some inconsistencies in FEs/controls across columns - we should converge on a consistent set.
	* FIXME this has not been updated to reflect SK's latest changes on 11.15.2024
	eststo clear
  eststo: reg attend_nadj treat treatXweek_in bl_attend bl_earn miss_bl_earn i.standid i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
  estadd local calweek "Yes", replace

  eststo: reg attend_nadj treat treatXpostweek5 bl_attend bl_earn miss_bl_earn i.standid i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
  estadd local calweek "Yes", replace

	* Col 3 - Phase 2 (2 months) ATE:
	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 bl_attend bl_earn miss_bl_earn attend_week i.standid i.strata i.calendar_week if phase==2 , vce(cluster pid)
  estadd local calweek "Yes", replace

	* Col 4 - time trend 
		* FIXME for now, I changed week_in_dm to week_in here to be consistent with cols 1 and 2
	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 bl_attend bl_earn miss_bl_earn treatXweek_in week_in i.standid i.strata i.calendar_week if phase==2 , vce(cluster pid)
  estadd local calweek "Yes", replace

	* Col 5 
	gen post_attendloo_b25_temp = post_attendloo_b25
	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25_temp  treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 bl_attend bl_earn miss_bl_earn i.standid i.strata if phase==2 , vce(cluster pid)
  estadd local calweek "No", replace

	* Col 6 - immediate effects (post event study dummies)
	eststo: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn i.standid i.strata i.calendar_week if phase==2 , vce(cluster pid)
  estadd local calweek "Yes", replace

	* Col 7 - immediate effects (post event study dummies) + time trend
			* FIXME for now, I changed week_in_dm to week_in here to be consistent with cols 1 and 2
	eststo: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 treatXweek_in week_in attend_week bl_attend bl_earn miss_bl_earn i.standid i.strata i.calendar_week if phase==2 , vce(cluster pid)
	estadd local calweek "Yes", replace

	label var treat "Treatment"
	label var treatXpost_attendloo_b25 "Treatment x Post shock"
  label var treatXweek_in "Treatment x Week number in phase 2"
  label var treatXpostweek5 "Treatment x Second month of phase 2"     
	label var treatXattendloo25_post1 "Treatment x 1 week post shock"
	label var treatXattendloo25_post2p "Treatment x 2+ weeks post shock"
	label var treatXweek_in_dm "Treatment x Week number"
	label var post_attendloo_b25_temp "Post shock"

	esttab using "${output_overleaf}/tables/shocks_attendloo_b25_full.tex", se keep(treat treatXweek_in treatXpostweek5 treatXpost_attendloo_b25 treatXattendloo25_post1 treatXattendloo25_post2p post_attendloo_b25_temp) order(treat treatXpost_attendloo_b25 post_attendloo_b25_temp treatXweek_in treatXpostweek5 treatXattendloo25_post1 treatXattendloo25_post2p) nomti l nonotes nostar replace cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) stats(calweek N, labels("Calendar Week FE" "N: worker-weeks")) frag collabels(none) gap
	capture drop post_attendloo_b25_temp


	***** EVENT STUDY REGRESSION CODE *****
	*foreach p in 25 {
	*	reg attend_nadj treatXattendloo`p'_pre4p  treatXattendloo`p'_pre1 treat treatXfirstwk_attendloo_b`p' treatXattendloo`p'_post1 treatXattendloo`p'_post2 treatXattendloo`p'_post34 treatXattendloo`p'_post5p attendloo`p'_pre4p attendloo`p'_pre1 firstwk_attendloo_b`p' attendloo`p'_post1 attendloo`p'_post2 attendloo`p'_post34 attendloo`p'_post5p bl_attend bl_earn miss_bl_earn i.strata i.standid i.calendar_week if phase>=2 , vce(cluster pid)
	*}

	* Save dataset
		* save "07. Data/3. Main Study 3.0/02. Cleaning Data/Analysis Prep/02. Output/05_bs_phase1_phase2_makevar_combined_daily_weekly_shocks.dta", replace

/*----------------------------------------------------*/
   /* [>   4.  Figures    <] */ 
/*----------------------------------------------------*/

**## Histogram: BL knowledge of JFP
* Q from BL demog survey part 1 B5
	* Assume Guru and Venkatesh are two people who come to the stand to look for work, Venkatesh and Guru both come to the stand everyday for a week (7 consecutive days). Venkatesh comes at 7:40am, and Guru comes at 9am. Based on your experience at the stand, how many days of work do you think Venkatesh and Guru will get respectively?

	gen bs_dem_workdays_early_share = bs_dem_workdays_early_arriver/6 
	gen bs_dem_workdays_late_share = bs_dem_workdays_late_arriver/6

	sum bs_dem_workdays_early_share if uniqpid==1 & phase==0, d
	local coef: display %9.0fc `r(mean)'*100
	save_input `coef' "bs_dem_workdays_early_share"

	sum bs_dem_workdays_late_share  if uniqpid==1 & phase==0, d
	local coef: display %9.0fc `r(mean)'*100
	save_input `coef' "bs_dem_workdays_late_share"

	twoway 	(histogram bs_dem_workdays_early_arriver, discrete gap(20) fcolor(gs12) lcolor(gs12)) (histogram bs_dem_workdays_late_arriver, discrete gap(20) fcolor(none) lcolor(maroon)), legend(order(1 "Arrives at 7:40am" 2 "Arrives at 9am" )) ytitle("Fraction") xtitle("Number of days would find job in a week") xlabel(0(1)6)
	gr export "${output_overleaf}/figures/bs_dem_workdays_early_vs_late.pdf", replace

**## Stat: Size of treatment incentives 
	sum bs_sum_wage if phase==0 & uniqpid==1
 	local coef: display %9.0fc (50/(r(mean)/10))*100
 	save_input `coef' "incentive_dailyearn"

**## Histogram: BL labor supply (days showed up to stand per week) and employment (days worked per week)
	
	preserve
	use "07. Data/3. Main Study 3.0/02. Cleaning Data/03. Baseline/02. Output/05_baseline_makevar.dta", clear
	* twoway hist bs_sum_attend if uniqpid==1 & phase==0, fraction start(0) width(0.25) xlabel(0(1)7) xmtick(0(1)7) graphregion(color(white)) xtitle("Total days attended stand (baseline)")
	* graph export "${output_overleaf}/figures/hist_bs_sum_attend.png", replace

	** weekly attendance
	gen bs_sum_attend_weekly = (bs_sum_attend/11)*6
	capture drop uniqpid 
	bys pid: gen uniqpid = _n==1
	count if uniqpid==1
	local coef: display %9.0fc `r(N)'
	save_input `coef' "bs_all_N"

	* 885 PIDs in this baseline sample.
	qui twoway hist bs_sum_attend_weekly if uniqpid==1, fraction start(0) xlabel(0(1)6) xmtick(0(1)6) graphregion(color(white)) xtitle("Days attended stand per week (baseline)") bin(12)
	graph export "${output_overleaf}/figures/hist_bs_sum_attend_weekly.png", replace
	sum bs_sum_attend_weekly if uniqpid==1, d 
	local coef: display %9.1fc `r(mean)'
	save_input `coef' "bs_sum_attend_weekly_mean"

	gen temp = 1 if bs_sum_attend_weekly<4 & uniqpid==1
	replace temp = 0 if temp==. & uniqpid==1
	sum temp if uniqpid==1, d 
	local coef: display %9.0fc `r(mean)'*100
	save_input `coef' "bs_sum_attend_weekly_below4"
	drop temp 

	gen temp = 1 if bs_sum_attend_weekly<5 & uniqpid==1
	replace temp = 0 if temp==. & uniqpid==1
	sum temp if uniqpid==1, d 
	local coef: display %9.0fc `r(mean)'*100
	save_input `coef' "bs_sum_attend_weekly_below5"
	drop temp 

	drop bs_sum_attend_weekly 

	** weekly work
	gen bs_sum_work_weekly = (bs_sum_work/10)*6

	qui twoway hist bs_sum_work_weekly if uniqpid==1, fraction start(0) xlabel(0(1)6) xmtick(0(1)6) graphregion(color(white)) xtitle("Days worked per week (baseline)") bin(12)
	graph export "${output_overleaf}/figures/hist_bs_sum_work_weekly.png", replace
	sum bs_sum_work_weekly if uniqpid==1, d 
	local coef: display %9.1fc `r(mean)'
	save_input `coef' "bs_sum_work_weekly_mean"
	drop bs_sum_work_weekly
	restore

**## Histogram: desire to switch to long-term stable work
	label define lngterm_work 1 "Least likely" 2 "Not likely" 3 `""Neither likely""or unlikely""' 4 "Likely" 5 "Very likely"  
	*label define lngterm_work 1 `""Least""likely""' 2 `""Not""likely""' 3 "Neutral" 4 "Likely" 5 `""Very""likely""'  
	/*
	1. least likely
	2. not likely
	3. neither likely nor  unlikely
	4. likely
	5. very likely
	999. Survey was incomplete
	*/

	label value bs_dem_lngterm_work lngterm_work 

	qui twoway hist bs_dem_lngterm_work if uniqpid==1 & phase==0, lcolor(gs12) fcolor(gs12) frac xla(1/5, valuelabel) discrete width(0.5) xtitle("") 
	graph export "$output_overleaf/figures/bs_dem_no_ltjob.png",replace

  gen temp = . 
  replace temp = 1 if uniqpid==1 & phase==0 & (bs_dem_lngterm_work ==4 | bs_dem_lngterm_work==5)
  replace temp = 0 if uniqpid==1 & phase==0 & (bs_dem_lngterm_work ==1 | bs_dem_lngterm_work==2 | bs_dem_lngterm_work==3)
  sum temp if uniqpid==1 & phase==0
  local coef: display %9.0fc `r(mean)'*100
  save_input `coef' "bs_dem_lngterm_work_likely"
  drop temp 

**## Histogram: reason for not wanting stable job

	preserve  
  gen longtermjob = (bs_dem_lngterm_work==4 | bs_dem_lngterm_work==5 & bs_dem_lngterm_work!=.)
  replace longtermjob=. if bs_dem_lngterm_work==.

  gen temp1 = substr(bs_dem_no_ltjob_reasons, 1, 1)
  gen temp2 = substr(bs_dem_no_ltjob_reasons, 3, 1)
  gen temp3 = substr(bs_dem_no_ltjob_reasons, 5, 1)
  gen temp4 = substr(bs_dem_no_ltjob_reasons, 7, 1)
  gen temp5 = substr(bs_dem_no_ltjob_reasons, 9, 1)
  destring temp*, replace

  * earn more
  gen bs_dem_no_ltjob_1 = 0
    replace bs_dem_no_ltjob_1 = 1 if temp1==2 | temp2==2 | temp3==2 | temp4 ==2 | temp5 ==2
    replace bs_dem_no_ltjob_1 = . if bs_dem_no_ltjob_reasons=="" & bs_dem_lngterm_network==.
    replace bs_dem_no_ltjob_1 = 1 if bs_dem_lngterm_network==2

  * like current
  gen bs_dem_no_ltjob_2 = 0
    replace bs_dem_no_ltjob_2 = 1 if temp1==3 | temp2==3 | temp3==3 | temp4 ==3 | temp5 ==3
    replace bs_dem_no_ltjob_2 = . if bs_dem_no_ltjob_reasons=="" & bs_dem_lngterm_network==.  
    replace bs_dem_no_ltjob_2 = 1 if bs_dem_lngterm_network==3 

  * prefer flex 
  gen bs_dem_no_ltjob_3 = 0
    replace bs_dem_no_ltjob_3 = 1 if temp1==1 | temp2== 1 | temp3==1 | temp4 == 1 | temp5 ==1
    replace bs_dem_no_ltjob_3 = . if bs_dem_no_ltjob_reasons=="" & bs_dem_lngterm_network==.
    replace bs_dem_no_ltjob_3 = 1 if bs_dem_lngterm_network==1

  * free time
  gen bs_dem_no_ltjob_4 = 0
    replace bs_dem_no_ltjob_4 = 1 if temp1==4 | temp2==4 | temp3==4 | temp4 ==4 | temp5 ==4
    replace bs_dem_no_ltjob_4 = . if bs_dem_no_ltjob_reasons=="" & bs_dem_lngterm_network==.  
    replace bs_dem_no_ltjob_4 = 1 if bs_dem_lngterm_network==4   

  * no boss
  gen bs_dem_no_ltjob_5 = 0
    replace bs_dem_no_ltjob_5 = 1 if temp1==5 | temp2==5 | temp3==5 | temp4 ==5 | temp5 ==5
    replace bs_dem_no_ltjob_5 = . if bs_dem_no_ltjob_reasons=="" & bs_dem_lngterm_network==. 

  * no qual
  gen bs_dem_no_ltjob_6 = 0
    replace bs_dem_no_ltjob_6 = 1 if temp1==6 | temp2==6 | temp3==6 | temp4 ==6 | temp5 ==6
    replace bs_dem_no_ltjob_6 = . if bs_dem_no_ltjob_reasons=="" & bs_dem_lngterm_network==. 
    replace bs_dem_no_ltjob_6 = 1 if bs_dem_lngterm_network==6 

  * how many prefer flex and free time?
  sum bs_dem_no_ltjob_3 
  local bs_dem_no_ltjob_3: display %9.0fc `r(mean)'*100
  save_input `bs_dem_no_ltjob_3' "bs_dem_no_ltjob_3"

  sum bs_dem_no_ltjob_4 
  local bs_dem_no_ltjob_4: display %9.0fc `r(mean)'*100
  save_input `bs_dem_no_ltjob_4' "bs_dem_no_ltjob_4"

  egen temp = rowmax(bs_dem_no_ltjob_3  bs_dem_no_ltjob_4)
  sum temp 
  local bs_dem_noltjob_flex: display %9.0fc `r(mean)'*100
  save_input `bs_dem_noltjob_flex' "bs_dem_noltjob_flex"
  drop temp  

  keep if uniqpid==1 & phase==0
  keep pid bs_dem_no_ltjob_* 
  drop bs_dem_no_ltjob_reasons bs_dem_no_ltjob_reasons_oth

  reshape long bs_dem_no_ltjob_, i(pid) j(reason)
  collapse (mean) bs_dem_no_ltjob_, by(reason)

  /*
  1. I prefer the flexibility of this job/I don't like having a fixed schedule
  2. I earn more per day with this job
  3. I like this profession better
  4. I have more free time with this job
  5. I don't like having a boss
  6. I don't think I have the qualifications for a regular job, hence I don't search.
  */

  label define no_ltjob_lab 1 "Earn more" 2 `""Like current""profession""' 3 `""Prefer" "flexibility" "' 4 `""More free""time""' 5 `""Don't like""having boss""'  6 `""Don't have""qualifications""'  
  label value reason no_ltjob_lab 

  qui graph bar bs_dem_no_ltjob_, over(reason, label( labsize(medium))) xsize(8) ytitle("Fraction")
  graph export "$output_overleaf/figures/bs_dem_no_ltjob_reasons.png",replace
  restore 

  verify_package binscatter

**## Scatterplot: probability of finding a job by arrival time
  * Note: arrival_time_hours_30 only defined in baseline data (created in 04_baseline_makevars.do)
  	* FIXME why is arrival_time_hours_30 missing for 17.73% of baseline obs where attend=1?
	qui binscatter work arrival_time_hours_30 if arrival_time_hours <=10, xlabel(6(0.5)10 6.5 "6.30" 7.5 "7.30" 8.5 "8.30" 9.5 "9.30") ylabel(, nogrid) xtitle("Arrival Time") ytitle("Mean Work") line(connect) lc(maroon) mc(blue)
	graph export "${output_overleaf}/figures/comm_bs_attend_work_30.png", replace 
  sum work if arrival_time_hours_30<=8 & arrival_time_hours_30!=. & arrival_time_hours <=10
  local coef: display %9.0fc `r(mean)'*100
  save_input `coef' "arrival_time_bef8"

  sum work if arrival_time_hours_30>9 & arrival_time_hours_30!=. & arrival_time_hours <=10
  local coef: display %9.0fc `r(mean)'*100
  save_input `coef' "arrival_time_aft9"

**## Figure: Attendance at stand (any time)
  verify_package distplot
	forvalues i = 1/2 {
		ksmirnov attend_nadj if phase == `i', by(treatment)
		local pval: display %4.3f `r(p)'
		distplot attend_nadj if phase == `i', lcolor(gs12 maroon) over(treatment) ylabel(, nogrid) legend(order(1 "Control" 2 "Treatment") pos(6) row(1) region(lstyle(none))) note("K-Smirnov test p-value: `pval'") graphregion(color(white)) xtitle("Days of attendance in a week (Phase `i')")
		graph export "${output_overleaf}/figures/comm_dist_attend_nadj_p`i'.png", replace 
	}

**## Figure: Work (phase 2)
  ksmirnov work1_wkly2 if phase == 2, by(treatment)
  local pval: display %4.3f `r(p)'
  save_input `pval' "dist_work_pval"

**## Histogram: Arrival time P1 & P2
	gen arrival_time_hours_std_daily = arrival_time_hours
  	replace arrival_time_hours_std_daily = arrival_time_hours - 0.25 if inlist(stand, ${cutoff_0815}) 
  	replace arrival_time_hours_std_daily = arrival_time_hours + 0.25 if inlist(stand, ${cutoff_0745})
  	replace arrival_time_hours_std_daily = 10 if arrival_time_hours_std_daily >= 10 & arrival_time_hours_std_daily != .

	twoway (hist arrival_time_hours_std_daily if treatment == 0 & inrange(arrival_time_hours_std_daily, 5.5, 12)  & phase == 1, lcolor(gs12) fcolor(gs12) fraction start(5.5)  width(0.25) ) || (hist arrival_time_hours_std_daily if treatment == 1 & inrange(arrival_time_hours_std_daily, 5.5, 12)  & phase == 1 , fcolor(none) lcolor(maroon) lwidth(medium) fraction   start(5.5)  width(0.25) ),legend(on row(1) label(1 "Control") label(2 "Treatment") pos(6) ring(1) ) xlabel(6(1)10) xmtick(6.5(1)10) note("*Treatment cut-off times are standardised to 8am") graphregion(color(white)) xtitle("Arrival time (observed) in fraction of hours (Phase 1)")
	 graph export "${output_overleaf}/figures/hist_arrival_time_by_treatment_p1_daily.png", replace

	twoway (hist arrival_time_hours_std_daily if treatment == 0 & inrange(arrival_time_hours_std_daily, 5.5, 12)  & phase == 2, lcolor(gs12) fcolor(gs12) fraction start(5.5)  width(0.25) ) || (hist arrival_time_hours_std_daily if treatment == 1 & inrange(arrival_time_hours_std_daily, 5.5, 12)  & phase == 2 , fcolor(none) lcolor(maroon) lwidth(medium) fraction   start(5.5)  width(0.25) ),legend(on row(1) label(1 "Control") label(2 "Treatment") pos(6) ring(1) ) xlabel(6(1)10) xmtick(6.5(1)10) note("*Treatment cut-off times are standardised to 8am") graphregion(color(white)) xtitle("Arrival time (observed) in fraction of hours (Phase 2)")
	 graph export "${output_overleaf}/figures/hist_arrival_time_by_treatment_p2_daily.png", replace

**## Scatterplot: Persistence in labor supply effects 

**## Scatterplot: Persistence in labor supply effects 

* attend_adj, stand + cal week FE 
	gen week_modified0 = week_in_bs_p1_p2_p3
	replace week_modified0 = 16 + floor((week_in_bs_p1_p2_p3 - 16) / 3) * 3 + 1 if week_in_bs_p1_p2_p3 > 15

	reg attend_adj i.stand i.calendar_week, vce(clu pid)
	predict attend_adj_resid1 if e(sample), resid
	binscatter attend_adj_resid1 week_modified0, by(treatment) colors(navy maroon) msymbols(O X) ///
	    xline(7.5, lpattern(dash) lcolor(black)) xline(15.5, lpattern("..--..--") lcolor(black)) ///
	    xline(0.5, lpattern(dash_dot) lcolor(black)) line(connect) legend(label(1 "Control") ///
	    label(2 "Treatment") size(small) row(1) symysize(0.75)  symxsize(5) region(lstyle(none)) ///
	    position(bottom)) ytitle("Weekly Mean Attend", size(small)) xtitle("Weeks in Phase", size(small)) ///
	    yscale(range(-1 1.5)) ylabel(none) ///
	    xlabel(0(1)27  8 "1" 9 "2" 10 "3" 11 "4" 12 "5" 13 "6" 14 "7" 15 "8" 16 " " 17 "13" 18 " " 19 " " 20 "16" 21 " " 22 " " 23 "19" 24 " " 25 " " 26 "22" 27 " ", ///
	    labsize(small) nogrid noticks) text(1.5 4 "{bf:Phase 1}", size(small)) text(1.5 11.5 "{bf:Phase 2}", size(small))  ///
	    text(1.5 20 "{bf:Phase 3}", size(small)) text(1.5 0 "{bf:BL}", size(small))
	    graph export "${output_overleaf}/figures/attend_adj_bs_p1_p2_p3_stand_calweek_v2.png", replace
	drop attend_adj_resid1

	/* 
	* attend_adj, stand + cal week FE 
  reg attend_adj i.stand i.calendar_week, vce(clu pid)
    predict attend_adj_resid1 if e(sample), resid
  qui binscatter attend_adj_resid1 week_in_bs_p1_p2_p3, by(treatment) nquantiles(27) colors(navy maroon) msymbols(O X) xline(7.5, lpattern(dash) lcolor(black)) xline(15.5, lpattern("..--..--") lcolor(black)) xline(0.5, lpattern(dash_dot) lcolor(black))   line(connect) legend(label(1 "Control") label(2 "Treatment") size(small) row(1) symysize(0.75)  symxsize(5) region(lstyle(none)) position(bottom)) ytitle("Weekly Mean Attend", size(small)) xtitle("Weeks in Phase", size(small)) yscale(range(-1 1.5)) ylabel(none) xlabel(0(1)27  8 "1" 9 "2" 10 "3" 11 "4" 12 "5" 13 "6" 14 "7" 15 "8" 16 "12" 17 "13" 18 "14" 19 "15" 20 "16" 21 "17" 22 "18" 23 "19" 24 "20" 25 "21" 26 "22" 27 "23", labsize(small)) text(1.5 4 "{bf:Phase 1}", size(small)) text(1.5 11.5 "{bf:Phase 2}", size(small))  text(1.5 20 "{bf:Follow Up}", size(small)) text(1.5 0 "{bf:BL}", size(small))
    graph export "${output_overleaf}/figures/attend_adj_bs_p1_p2_p3_stand_calweek_v2.png", replace
  drop attend_adj_resid1 
  */

* attendance before cutoff
  reg attend_and_before8_adj i.stand i.calendar_week, vce(clu pid)
    predict attend_and_before8_adj_resid1 if e(sample), resid
  qui binscatter attend_and_before8_adj_resid1 week_in_bs_p1_p2_p3, by(treatment) nquantiles(27) colors(navy maroon) msymbols(O X) xline(7.5, lpattern(dash) lcolor(black)) xline(15.5, lpattern("..--..--") lcolor(black)) xline(0.5, lpattern(dash_dot) lcolor(black)) line(connect) legend(label(1 "Control") label(2 "Treatment") size(small) row(1) symysize(0.75)  symxsize(5) region(lstyle(none)) position(bottom)) ytitle("Weekly Mean Attend by 8", size(small)) xtitle("Weeks in Phase", size(small)) yscale(range(-1 1.5)) ylabel(none) xlabel(0(1)27 8 "1" 9 "2" 10 "3" 11 "4" 12 "5" 13 "6" 14 "7" 15 "8" 16 "12" 17 "13" 18 "14" 19 "15" 20 "16" 21 "17" 22 "18" 23 "19" 24 "20" 25 "21" 26 "22" 27 "23", labsize(small)) text(1.5 4 "{bf:Phase 1}", size(small)) text(1.5 11.5 "{bf:Phase 2}", size(small)) text(1.5 20 "{bf:Follow Up}", size(small)) text(1.5 0 "{bf:BL}", size(small))
    graph export "${output_overleaf}/figures/attend_b8_adj_bs_p1_p2_p3_stand_calweek.png", replace

  // PB: Collapse phase 3 into 3-week bins
  gen week_modified0 = week_in_bs_p1_p2_p3
    replace week_modified0 = 16 + floor((week_in_bs_p1_p2_p3 - 16) / 3) * 3 + 1 if week_in_bs_p1_p2_p3 > 15
  
  // Residualize attendance
  reg attend_adj i.stand i.calendar_week, vce(clu pid)
    predict attend_adj_resid1 if e(sample), resid

  // Present attendance over time by treatment group for each week
  qui binscatter attend_adj_resid1 week_modified0, by(treatment) colors(navy maroon) msymbols(O X) ///
    xline(7.5, lpattern(dash) lcolor(black)) xline(15.5, lpattern("..--..--") lcolor(black)) ///
    xline(0.5, lpattern(dash_dot) lcolor(black)) line(connect) legend(label(1 "Control") ///
    label(2 "Treatment") size(small) row(1) symysize(0.75)  symxsize(5) region(lstyle(none)) ///
    position(bottom)) ytitle("Weekly Mean Attend", size(small)) xtitle("Weeks in Phase", size(small)) ///
    yscale(range(-1 1.5)) ylabel(none) ///
    xlabel(0(1)27  8 "1" 9 "2" 10 "3" 11 "4" 12 "5" 13 "6" 14 "7" 15 "8" 16 " " 17 "13" 18 " " 19 " " 20 "16" 21 " " 22 " " 23 "19" 24 " " 25 " " 26 "22" 27 " ", ///
    labsize(small) nogrid noticks) text(1.5 4 "{bf:Phase 1}", size(small)) text(1.5 11.5 "{bf:Phase 2}", size(small))  ///
    text(1.5 20 "{bf:Phase 3}", size(small)) text(1.5 0 "{bf:BL}", size(small))
  graph export "${output_overleaf}/figures/attend_adj_bs_p1_p2_p3_stand_calweek_v2.png", replace
  drop attend_adj_resid1

/*
**## Barchart - Time Use OLD
	gen phase_tu_graph = 1 if phase == 1
	 replace phase_tu_graph = 2 if inlist(phase, 2,3)

	preserve 
		collapse (mean) tu_time_activity_for_others_adj tu_time_activity_for_self_adj tu_time_activity_work_adj if inlist(phase, 1,2,3) , by(treatment phase_tu_graph)
		rename tu_time_activity_for_others_adj tu_1
		rename tu_time_activity_for_self_adj tu_2
		rename tu_time_activity_work_adj tu_3
		reshape long tu_ , i(treatment phase_tu_graph) 
		rename tu_ tu
		gen cat = _j
		replace cat = cat-0.25 if treatment == 0
		replace cat = cat+0.25 if treatment == 1

		qui twoway (bar tu cat if phase == 2 & cat == 0.75,color("27 158 119") lcolor(black) barwidth(0.33)) ///
		(bar tu cat if phase == 2 & cat == 1.25,color("27 158 119") lcolor(black) barwidth(0.33)) ///
		(bar tu cat if phase == 2 & cat == 1.75,color("217 95 2") lcolor(black) barwidth(0.33)) ///
		(bar tu cat if phase == 2 & cat == 2.25,color("217 95 2") lcolor(black) barwidth(0.33)) ///
		(bar tu cat if phase == 2 & cat == 2.75,color("117 112 179") lcolor(black) barwidth(0.33)) ///
		(bar tu cat if phase == 2 & cat == 3.25,color("117 112 179") lcolor(black) barwidth(0.33)), /// 
		xlabel(0.75 "C" 1.25 "T" 1.75 "C" 2.25 "T" 2.75 "C" 3.25 "T") graphregion(color(white)) /// 
		legend(order( 1 "Others" 3 "Self" 5 "Work") cols(3) position(bottom)) xtitle("Phase 2 + 3") ytitle("Time Use (Minutes)") name(phase2,replace) aspect(1.5) xsize(5)
		graph export "${output_overleaf}/figures/morning_time_use.png", replace
	restore
*/

**## Barchart - Time Use Activity Breakdown
	preserve
	use "./07. Data/3. Main Study 3.0/02. Cleaning Data/06a. Phase 2 Activities/02. Output/03a_phase2act_vignettes_makevar.dta", clear
	keep r_reg_morning_act_* f_treatment pid

	* tab r_reg_morning_act_998_others 
		* not much info here, so dropping this
	drop r_reg_morning_act_998_others
	reshape long r_reg_morning_act_, i(pid) j(activities) string
	collapse (mean) r_reg_morning_act_, by(activities f_treatment)	
	
	gen bord = 1 if activities == "water"
		replace bord = 2 if activities == "cook_breakf"
		replace bord = 3 if activities == "eat_breakf"
		replace bord = 4 if activities == "help_kids"
		replace bord = 5 if activities == "drop_kids"
		replace bord = 6 if activities == "wash"
		replace bord = 7 if activities == "pray"
		replace bord = 8 if activities == "shopping"
		replace bord = 9 if activities == "998"

  // PB: Changed bin color/opacity.
	twoway (bar r_reg_morning_act_ bord if f_treatment == 0,  lcolor(gs12) fcolor(gs12)) || ///
      (bar r_reg_morning_act_ bord if f_treatment == 1, fcolor(none) lcolor(maroon)), ///
      xlabel(1 `" "Get" "water" "' 2 `" "Cook" "breakfast" "' 3 `" "Eat" "breakfast" "' 4 `" "Help get" "kids ready" "' 5 `" "Drop kids" "at school" "' 6 "Wash/bathe" 7 `" "Temples/" "prayers" "' 8 `" "Go to the" "store/shop" "' 9 "Others", noticks) ///
      xtitle("") ytitle("Percent of respondents selecting each option") legend(order(1 "Control" 2 "Treatment") pos(6) row(1))
	graph export "${output_overleaf}/figures/bar_morning_activities_low_att.png", replace
	restore

**## Barchart - Share of respondents that use a morning alarm
  preserve
      use "./07. Data/3. Main Study 3.0/02. Cleaning Data/06a. Phase 2 Activities/02. Output/03a_phase2act_vignettes_makevar.dta", clear

      tab r_morning_alarm if f_treatment == 1

      /* Output:
          [Yes/no] Using an |
        alarm to wake up in |       Treatment
                the morning |   Control  Treatment |     Total
      ----------------------+----------------------+----------
                         No |        71         76 |       147 
                        Yes |        32         22 |        54 
      ----------------------+----------------------+----------
                      Total |       103         98 |       201 

      */

      /*
      twoway (hist r_morning_alarm_yes if f_treatment == 0, lcolor(gs12) fcolor(gs12) width(1)  fraction discrete ) ///
            || (hist r_morning_alarm_yes if f_treatment == 1, fcolor(none) lcolor(maroon) width(1) lwidth(medium) fraction discrete), ///
            legend(order(1 "Control" 2 "Treatment") pos(6) row(1) region(lstyle(none))) xtitle("") ylabel(, nogrid) ///
            xlabel( 0.2 "No" 1.2 "Yes", nogrid notick) graphregion(color(white))
      */

      * Step 1: Calculate means, minimum, and maximum
      g alarm_control = (r_morning_alarm==1 & f_treatment == 0) if f_treatment==0
      g alarm_treatment = (r_morning_alarm == 1 & f_treatment == 1) if f_treatment == 1

      local variables alarm_control alarm_treatment
      foreach var of local variables {
          sum `var'
          scalar `var'_mean = r(mean)
          scalar `var'_min = r(min)
          scalar `var'_max = r(max)
      }

      matrix results = (alarm_control_mean, alarm_control_min, alarm_control_max \ alarm_treatment_mean, alarm_treatment_min, alarm_treatment_max)
      matrix rownames results = Control Treatment
      matrix colnames results = Mean Min Max

      svmat double results, names(col)

      keep Mean Min Max
      save "/Users/prayog/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/02. Cleaning Data/06a. Phase 2 Activities/02. Output/temp_vignettes_morningalarm_results_matrix.dta", replace

      use "/Users/prayog/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/02. Cleaning Data/06a. Phase 2 Activities/02. Output/temp_vignettes_morningalarm_results_matrix.dta", clear
      drop if Mean ==.

      gen treated = ""
      replace treated = "Treatment" if Mean < 0.3
      replace treated = "Control" if Mean > 0.3

      graph bar (mean) Mean, over(treated) asyvars ///
         bar(1, fcolor(gs12) lcolor(gs12)) ///
         bar(2, fcolor(none) lcolor(maroon)) ///
         ytitle("Share of respondents") ///
         yscale(range(0 0.5)) ///
         legend(order(1 "Control" 2 "Treatment") row(1) position(bottom))

      graph export "$output_overleaf/figures/bars_use_alarm.png", replace
  restore

**## Histogram: Shocks to labor supply
	preserve 
	gen temp=week_in if stand_ph_calweek==firstpostshockl_calwk25 & phase==2
  bys pid: egen week_attendloo25 = max(temp)
  keep if phase ==2
  keep stand pid week_attendloo25
  duplicates drop
  isid pid
  tab week_attendloo25, m //16% have no shock 
  hist week_attendloo25, frac xtitle("Week in Phase 2") lcolor(gs12) fcolor(gs12) discrete xlabel(1(1)8) ytitle("Frequency of when shock occurs")
  graph export "${output_overleaf}/figures/hist_week_attendloo25.png", replace

	//include no shocks
  replace week_attendloo25 = 10 if week_attendloo25==.
  hist week_attendloo25, frac xtitle("Week in Phase 2") lcolor(gs12) fcolor(gs12) discrete xlabel(1(1)8 10) ytitle("Frequency") xlabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 10 "No shock")
  graph export "${output_overleaf}/figures/hist_week_attendloo25_incl0.png", replace
  restore 

  // Sample size stat 
  count if phase==1 & uniqpid==1
  local samplesize: display %9.0fc `r(N)'
  save_input `samplesize' "samplesize"


  verify_package unique

  // Number of stands
  unique standid 
  local num_stands: display %9.0fc `r(unique)'
  save_input `num_stands' "num_stands"

  // Experience of the average worker (bs_dem_stand_yrs)
  sum bs_dem_stand_yrs if phase == 0 & uniqpid == 1
  local coef: display %9.0fc `r(mean)'
  save_input `coef' "years_in_stand" 

  // A worker's mean attendance 
  sum attend_adj if attend_adj !=. & phase == 0
  local coef: display %9.1fc `r(mean)'
  save_input `coef' "phase0_mean_attendance"

  // Employment rate
  sum work_adj if work_adj !=. & phase == 0
  local coef: display %9.0fc `r(mean)'
  save_input `coef' "phase0_days_worked_weekly"

**## Barchart - Commuting method and duration
	* Method  
	lab var ss_dem_commute_bus 		"Bus"
	lab var ss_dem_commute_auto 	"Auto/Rickshaw"
	lab var ss_dem_commute_train	"Train"
	lab var ss_dem_commute_moto 	"Motorbike"
	lab var ss_dem_commute_bike 	"Bicycle"
	lab var ss_dem_commute_foot		"On Foot"

	statplot ss_dem_commute_foot ss_dem_commute_moto ss_dem_commute_bus ss_dem_commute_bike ss_dem_commute_auto ss_dem_commute_train if uniqpid==1, blabel(bar, format(%8.2f)) ytitle("Share")
	gr export "$figures/dist_commuting_methods.pdf" , replace

	* Duration
	preserve 
	keep if phase==0

	* convert hours to minutes 
	replace ss_dem_commute_time = ss_dem_commute_time * 60

	gen commute_method = .
	replace commute_method = 1 if ss_dem_commute_foot == 1
	replace commute_method = 2 if ss_dem_commute_moto == 1
	replace commute_method = 3 if ss_dem_commute_bus == 1
	replace commute_method = 4 if ss_dem_commute_bike == 1
	replace commute_method = 5 if ss_dem_commute_auto == 1
	replace commute_method = 6 if ss_dem_commute_train == 1
	lab def commute_method 1 "On Foot" 2 "Motorbike" 3 "Bus" 4 "Bicycle" 5 "Auto/Rickshaw" 6 "Train", replace
	lab val commute_method commute_method

	keep pid commute_method ss_dem_commute_time
	duplicates drop 
	collapse ss_dem_commute_time, by(commute_method) 
	twoway bar ss_dem_commute_time  commute_method, barw(0.6) xtitle("Commute Method") xlabel(1 "On Foot" 2 "Motorbike" 3 "Bus" 4 "Bicycle" 5 "Auto/Rickshaw" 6 "Train") ytitle("Minutes") ylab(0(10)80)
	gr export "$figures/dist_commuting_duration.pdf" , replace
	restore 

/*----------------------------------------------------*/
   /* [>   5.  Regression tables    <] */ 
/*----------------------------------------------------*/
	  
**## Table: "Labor supply effects"
	* even though data is at person-day level, these outcomes are defined at the weekly level (only 1 non-missing value per week)
	* in phase 1, total obs: 225 people x 7 weeks = 1575 
  * in phase 2, total obs: 225 people x 8 weeks = 1800 
	* # obs for worked is lower because we have some missing work data (this is balanced across T and C)

	eststo clear 
	eststo a1: reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum attend_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)
    * note: sample size here is 1572 and not 1575 because 3 PIDs got late announcements in week 2, so week 1 data is missing
    * tab late_announcement_flag  if phase==1 & attend_nadj==. & dow==2, m

  local coef: display %9.3fc _b[treatment]
  save_input `coef' "attend_nadj_p1_b"

	* Saving treatment effects in % terms 
	local coef: display %9.0fc (_b[treatment]/`r(mean)')*100
	save_input `coef' "attend_nadj_p1_percent"

	local coef: display %9.1fc (_b[treatment]/`r(mean)')*100
	save_input `coef' "attend_nadj_p1_percent_1dp"

	eststo b1: reg attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum attend_and_before8_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)

  local coef: display %9.3fc _b[treatment]
  save_input `coef' "attend_and_before8_p1_b"

  * Saving treatment effects in % terms 
  local coef: display %9.0fc (_b[treatment]/`r(mean)')*100
  save_input `coef' "attend_and_before8_p1_percent"
  
	eststo a2: reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
  // PB: store the p-value
  matrix list r(table)
  local coef: display %9.3fc r(table)[4, "treatment"]
  save_input `coef' "attend_nadj_p2_pvalue"
	
  sum attend_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)

  local coef: display %9.3fc _b[treatment]
  save_input `coef' "attend_nadj_p2_b"

	* Saving treatment effects in % terms 
	local coef: display %9.0fc (_b[treatment]/`r(mean)')*100
	save_input `coef' "attend_nadj_p2_percent"

	local coef: display %9.1fc (_b[treatment]/`r(mean)')*100
	save_input `coef' "attend_nadj_p2_percent_1dp"

	eststo b2: reg attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	matrix list r(table)
  local coef: display %9.3fc r(table)[4, "treatment"]
  save_input `coef' "attend_and_before8_p2_pvalue"

  sum attend_and_before8_nadj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)

  local coef: display %9.3fc _b[treatment]
  save_input `coef' "attend_and_before8_p2_b"

  * Saving treatment effects in % terms 
  local coef: display %9.0fc (_b[treatment]/`r(mean)')*100
  save_input `coef' "attend_and_before8_p2_percent"

  local coef: display %9.1fc (_b[treatment]/`r(mean)')*100
  save_input `coef' "attend_and_before8_p2_percent_1dp"

	eststo c2: reg work1_fromstand_wkly2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	sum work1_fromstand_wkly2 if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)

	eststo d2: reg work1_wkly2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	matrix list r(table)
  local coef: display %9.3fc r(table)[4, "treatment"]
  save_input `coef' "work1_wkly2_p2_pvalue"

  sum work1_wkly2 if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)
	
  local coef: display %9.3fc _b[treatment]
  save_input `coef' "work1_wkly2_p2_b"

	* Saving treatment effects in % terms 
	local coef: display %9.0fc (_b[treatment]/`r(mean)')*100
	save_input `coef' "work1_wkly2_p2_percent"

	local coef: display %9.1fc (_b[treatment]/`r(mean)')*100
	save_input `coef' "work1_wkly2_p2_percent_1dp"

	* esttab a1 b1 a2 b2 using "${output_overleaf}/tables/com_weekly_attend_attend_b8_frag2.tex", replace keep(treatment) nostar cells(b( fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) stats( y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) l nonotes frag nonumbers nomtitles 
	* starlevels(* 0.10 ** 0.05 *** .01)

	esttab a1 b1 a2 b2 d2 using "${output_overleaf}/tables/com_weekly_attend_attend_b8_work1_frag2.tex",  replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) stats( y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) l nonotes frag nonumbers nomtitles nostar
  * 2024-05-02 removing c2 from Col 5

  * 2024-05-02 new version for slides, changing order 
  esttab b1 a1 b2 a2 d2 using "${output_overleaf}/tables/com_weekly_attend_b8_attend_work1_frag2.tex",  replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) stats( y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) l nonotes frag nonumbers nomtitles nostar

	* phase 3 attendance effects
	reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn i.strata  i.stand i.week_in  i.calendar_week if phase == 3, vce(cluster pid)
	matrix list r(table)
	local coef3_p: display %9.2fc r(table)[4,1]
	sum attend_nadj if treatment==0 & e(sample)
	local coef3 : display %9.1fc (_b[treatment]/`r(mean)')*100
	local coef3_nodm : display %9.0fc (_b[treatment]/`r(mean)')*100
	save_input `coef3' "diff_attend3"
	save_input `coef3_nodm' "diff_attend3_nodm"
	save_input `coef3_p' "diff_attend3_p"

**## Stat: effect on daily wage
	reg earn treatment bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
	matrix list r(table)
	local earn_p: display %9.3fc r(table)[4,1]
	save_input `earn_p' "earn_p"

**## Table: "Deterioration of effects over time?"

  eststo clear
  eststo: reg attend_nadj treat treatXweek_in bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
  estadd local phase "2", replace
  estadd local stand   "Yes", replace
  estadd local strata  "Yes", replace
  estadd local weekin  "Yes", replace
  estadd local calweek "Yes", replace

  eststo: reg attend_nadj treat treatXpostweek5 bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.week_in i.calendar_week if phase==2, vce(cluster pid)
  estadd local phase "2", replace
  estadd local stand   "Yes", replace
  estadd local strata  "Yes", replace
  estadd local weekin  "Yes", replace
  estadd local calweek "Yes", replace

  label var treat "Treatment"
  label var treatXweek_in "Treatment x Week in phase 2"
  label var treatXpostweek5 "Treatment x Second month of phase 2"     
  label var attend_nadj "Attend"

  esttab using "${output_overleaf}/tables/TE_overtime.tex" , se order(treat treatXweek_in treatXpostweek5) keep(treat treatXweek_in treatXpostweek5) nostar l cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) nonotes  starlevels(* 0.10 ** 0.05 *** .01) stats(weekin calweek N, labels("Week in phase FE" "Calendar Week FE" "N: worker-weeks")) replace collabels(none) frag gaps

**## Table: Attrition - formal and informal dropouts 
	eststo clear 
	eststo: reg dropout treatment i.stand i.strata if uniqpid == 1 & phase == 2, r 
			sum dropout if treatment==0 & e(sample)
				estadd scalar y_mean=r(mean)
	* reg p1_inf_dropout_3 treatment i.stand i.strata if uniqpid == 1 & phase == 2, r 
			* sum p1_inf_dropout_3 if treatment==0 & e(sample)
				* estadd scalar y_mean=r(mean)
	* reg inf_dropout_3_overall treatment i.stand i.strata if uniqpid == 1 & phase == 2, r 
			* sum inf_dropout_3_overall if treatment==0 & e(sample)
				* estadd scalar y_mean=r(mean)
	eststo: reg inf_dropout_3_p2 treatment i.stand i.strata if uniqpid == 1 & phase == 2, r 
			sum inf_dropout_3_p2 if treatment==0 & e(sample)
				estadd scalar y_mean=r(mean)

	esttab using "${output_overleaf}/tables/balance_dropouts.tex", replace keep(treatment) frag ///
     cells(b(star fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) stats( y_mean N, labels("Control mean" "N")) /// 
     collabels(none) l nonotes starlevels(* 0.10 ** 0.05 *** .01) nonumbers mtitles("Formal Dropouts"  "Informal Dropout (P2)")
  
**## Table: Demographic characteristics  

	* save as locals 
	local balance_vars ss_dem_age bs_dem_has_family bs_sum_attend bs_sum_work bs_sum_wage ss_dem_educ_noschool ss_dem_educ_literacy bs_dem_stand_yrs bs_dem_job_yrs bs_avg_wage
		foreach var in `balance_vars' {
			ttest `var' if phase == 0 & uniqpid == 1, by(treatment)
			local `var'_mean_c : di %6.2fc r(mu_1)
			local `var'_sd_c   : di %6.2fc r(sd_1)
			local `var'_sd_c  "(``var'_sd_c')"
			local `var'_mean_t : di %6.2fc r(mu_2)
			local `var'_sd_t   : di %6.2fc r(sd_2)
			local `var'_sd_t  "(``var'_sd_t')"
			local `var'_p      : di %6.1fc r(p)

			reg `var' treatment i.stand i.strata  if phase == 0 & uniqpid == 1, r
			local t = _b[treatment]/_se[treatment]
			local `var'_reg_p: di %6.3fc 2 * ttail(e(df_r),abs(`t'))
		}
		count if treatment == 1  & phase == 0 & uniqpid == 1
		local n_t = r(N)
		count if treatment == 0  & phase == 0 & uniqpid == 1
		local n_c = r(N)

		matrix mean_control = (`ss_dem_age_mean_c' , `ss_dem_educ_noschool_mean_c' , `bs_dem_has_family_mean_c' , `bs_dem_stand_yrs_mean_c' , `bs_dem_job_yrs_mean_c' , `bs_sum_attend_mean_c' , `bs_sum_work_mean_c' , `bs_avg_wage_mean_c' , `bs_sum_wage_mean_c')
		matrix colnames mean_control = "Age" "No schooling" "Has spouse/children" "Years at stand" "Years in current profession" "Days attended stand" "Days worked" "Average daily wage (in rupees)" "Total earnings (in rupees)"
		
		matrix sd_control = (`ss_dem_age_sd_c' , `ss_dem_educ_noschool_sd_c' , `bs_dem_has_family_sd_c' , `bs_dem_stand_yrs_sd_c' , `bs_dem_job_yrs_sd_c' , `bs_sum_attend_sd_c' , `bs_sum_work_sd_c' , `bs_avg_wage_sd_c' , `bs_sum_wage_sd_c')
		matrix colnames sd_control = "Age" "No schooling" "Has spouse/children" "Years at stand" "Years in current profession" "Days attended stand" "Days worked" "Average daily wage (in rupees)" "Total earnings (in rupees)"

		matrix mean_treat = (`ss_dem_age_mean_t' , `ss_dem_educ_noschool_mean_t' , `bs_dem_has_family_mean_t' , `bs_dem_stand_yrs_mean_t' , `bs_dem_job_yrs_mean_t' , `bs_sum_attend_mean_t' , `bs_sum_work_mean_t' , `bs_avg_wage_mean_t' , `bs_sum_wage_mean_t')
		matrix colnames mean_treat = "Age" "No schooling" "Has spouse/children" "Years at stand" "Years in current profession" "Days attended stand" "Days worked" "Average daily wage (in rupees)" "Total earnings (in rupees)"
		
		matrix sd_treat = (`ss_dem_age_sd_t' , `ss_dem_educ_noschool_sd_t' , `bs_dem_has_family_sd_t' , `bs_dem_stand_yrs_sd_t' , `bs_dem_job_yrs_sd_t' , `bs_sum_attend_sd_t' , `bs_sum_work_sd_t' , `bs_avg_wage_sd_t' , `bs_sum_wage_sd_t')
		matrix colnames sd_treat = "Age" "No schooling" "Has spouse/children" "Years at stand" "Years in current profession" "Days attended stand" "Days worked" "Average daily wage (in rupees)" "Total earnings (in rupees)"

		matrix reg_p = (`ss_dem_age_reg_p' , `ss_dem_educ_noschool_reg_p' , `bs_dem_has_family_reg_p' , `bs_dem_stand_yrs_reg_p' , `bs_dem_job_yrs_reg_p' , `bs_sum_attend_reg_p' , `bs_sum_work_reg_p' , `bs_avg_wage_reg_p' , `bs_sum_wage_reg_p')
		matrix colnames reg_p = "Age" "No schooling" "Has spouse/children" "Years at stand" "Years in current profession" "Days attended stand" "Days worked" "Average daily wage (in rupees)" "Total earnings (in rupees)"

		eststo clear
		estadd matrix mean_control
		estadd matrix mean_treat
		estadd matrix sd_control
		estadd matrix sd_treat 
		estadd matrix reg_p

		esttab using "${output_overleaf}/tables/bl_balance_3col_condensed_code.tex", frag gaps noobs cells("mean_control(fmt(3)) mean_treat(fmt(3)) reg_p(par([ ]) fmt(3))" "sd_control(par fmt(3)) sd_treat(par fmt(3))") ///
			l nonum collabels(none)  ///
			replace nocons nomti 
		

	* make 3 col table
	texdoc init "${output_overleaf}/tables/baseline_treatment_control_balance3col.tex", replace force

	tex \begin{tabular}{lccc}
	tex \toprule
	tex          &  (1) & (2) & (3)  \\
	tex          & Control & Treatment & Regression  \\
	tex & Mean    & Mean      & P-value \\
	tex \midrule
	tex \hspace{0.1cm} Age                 & `ss_dem_age_mean_c'           & `ss_dem_age_mean_t'                  & `ss_dem_age_reg_p' \\
	tex                                    & `ss_dem_age_sd_c'             & `ss_dem_age_sd_t'            &                   \\
	tex \hspace{0.1cm} No schooling   & `ss_dem_educ_noschool_mean_c' & `ss_dem_educ_noschool_mean_t' & `ss_dem_educ_noschool_reg_p' \\
	tex                               & `ss_dem_educ_noschool_sd_c'   & `ss_dem_educ_noschool_sd_t'    &                   \\
	tex \hspace{0.1cm} Has spouse/children & `bs_dem_has_family_mean_c'    & `bs_dem_has_family_mean_t'   &  `bs_dem_has_family_reg_p' \\
	tex                                    & `bs_dem_has_family_sd_c'      & `bs_dem_has_family_sd_t'     &                   \\
	tex \hspace{0.1cm} Years at stand                & `bs_dem_stand_yrs_mean_c'   & `bs_dem_stand_yrs_mean_t' & `bs_dem_stand_yrs_reg_p' \\
	tex                                             & `bs_dem_stand_yrs_sd_c'     & `bs_dem_stand_yrs_sd_t'     &                 \\
	tex \hspace{0.1cm} Years in current profession   & `bs_dem_job_yrs_mean_c'     & `bs_dem_job_yrs_mean_t'   & `bs_dem_job_yrs_reg_p' \\
	tex                                             & `bs_dem_job_yrs_sd_c'       & `bs_dem_job_yrs_sd_t'       &                 \\
	tex \hspace{0.1cm} Days attended stand         & `bs_sum_attend_mean_c'        & `bs_sum_attend_mean_t'    & `bs_sum_attend_reg_p' \\
	tex                                                 & `bs_sum_attend_sd_c'          & `bs_sum_attend_sd_t'          &                          \\
	tex \hspace{0.1cm} Days worked & `bs_sum_work_mean_c' & `bs_sum_work_mean_t' & `bs_sum_work_reg_p' \\
	tex                                                 & `bs_sum_work_sd_c'   & `bs_sum_work_sd_t'   &                          \\
	tex \hspace{0.1cm} Average daily wage (in rupees)         & `bs_avg_wage_mean_c'          & `bs_avg_wage_mean_t'   & `bs_avg_wage_reg_p' \\
	tex                                                 & `bs_avg_wage_sd_c'            & `bs_avg_wage_sd_t'            &                          \\
	tex \hspace{0.1cm} Total earnings (in rupees)         & `bs_sum_wage_mean_c'          & `bs_sum_wage_mean_t'   & `bs_sum_wage_reg_p' \\
	tex                                                 & `bs_sum_wage_sd_c'            & `bs_sum_wage_sd_t'            &                          \\
	tex \hline
	tex N: workers       & `n_c' & `n_t' & \\
	tex \bottomrule 
	tex \end{tabular}
	texdoc close

**## Stats for paper 
  sum ss_dem_age if phase == 0 & uniqpid == 1
  local coef: display %9.0fc `r(mean)'
  save_input `coef' "ss_dem_age"

  sum bs_sum_attend if phase == 0 & uniqpid == 1
  local coef: display %9.1fc `r(mean)'
  save_input `coef' "bs_sum_attend"

  sum bs_sum_attend if phase == 0 & uniqpid == 1
	local coef: display %9.0fc `r(mean)'
	save_input `coef' "bs_sum_attend_round"

  sum bs_sum_work if phase == 0 & uniqpid == 1
  local coef: display %9.1fc `r(mean)'
  save_input `coef' "bs_sum_work"

  gen temp = (bs_sum_attend/11)*6
  sum temp if phase == 0 & uniqpid == 1
  local coef: display %9.1fc `r(mean)'
  save_input `coef' "bs_sum_attend_weekly"
  drop temp 

  gen temp = (bs_sum_work/10)*6
  sum temp if phase == 0 & uniqpid == 1
  local coef: display %9.1fc `r(mean)'
  save_input `coef' "bs_sum_work_weekly"
  drop temp 

  sum ss_dem_educ_noschool if phase == 0 & uniqpid == 1
  local coef: display %9.0fc `r(mean)'*100
  save_input `coef' "ss_dem_educ_noschool"  

  sum bs_dem_stand_yrs if phase == 0 & uniqpid == 1
  local coef: display %9.0fc `r(mean)'
  save_input `coef' "bs_dem_stand_yrs"  

  sum bs_avg_wage if phase == 0 & uniqpid == 1
  local coef: display %9.0fc `r(mean)'
  save_input `coef' "bs_avg_wage"

**## Table: Work data well balanced - Missing work data
	eststo clear 
	eststo: reg missing_work treatment i.stand i.strata i.week_in_p1_p2 i.calendar_week i.phase, vce(clu pid)
			sum missing_work if treatment==0 & e(sample)
				estadd scalar y_mean=r(mean)
	esttab using "$output_overleaf/tables/balance_missing_work2.tex",  replace keep(treatment)  cells(b(star fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) stats( y_mean N, labels("Control mean" "N")) collabels(none) l nonotes starlevels(* 0.10 ** 0.05 *** .01) nonumbers mtitles("Missing Work Data") frag
	*addnotes("Standard errors are clustered at the PID level in parenthesis." "P-values in brackets" "Stand, Strata, Week In Phase, Calendar Week \& Phase FE used " )

**## Table: Time use OLD
	eststo clear 
	eststo: reg tu_time_activity_for_others_adj treatment  i.calendar_week i.strata i.stand  if inlist(phase, 2,3), vce(cluster pid)
			sum tu_time_activity_for_others_adj if treatment==0 & e(sample)
					estadd scalar y_mean=r(mean)
			estadd local strata  "Yes", replace
			estadd local stand   "Yes", replace
			estadd local weekin  "No", replace
			estadd local calweek "Yes", replace
			estadd local phase   "2+3", replace

	eststo: reg tu_time_activity_for_self_adj treatment  i.calendar_week i.strata i.stand  if inlist(phase, 2,3), vce(cluster pid)
			sum tu_time_activity_for_self_adj if treatment==0 & e(sample)
					estadd scalar y_mean=r(mean)
			estadd local strata  "Yes", replace
			estadd local stand   "Yes", replace
			estadd local weekin  "No", replace
			estadd local calweek "Yes", replace
			estadd local phase   "2+3", replace

	eststo: reg tu_time_activity_work_adj treatment  i.calendar_week i.strata i.stand  if inlist(phase, 2,3), vce(cluster pid)
			sum tu_time_activity_work_adj if treatment==0 & e(sample)
					estadd scalar y_mean=r(mean)
			estadd local strata  "Yes", replace
			estadd local stand   "Yes", replace
			estadd local weekin  "No", replace
			estadd local calweek "Yes", replace
			estadd local phase   "2+3", replace

	eststo: reg tu_time_activity_11_adj treatment  i.calendar_week i.strata i.stand  if inlist(phase, 2,3), vce(cluster pid)
			sum tu_time_activity_11_adj if treatment==0 & e(sample)
					estadd scalar y_mean=r(mean)
			estadd local strata  "Yes", replace
			estadd local stand   "Yes", replace
			estadd local weekin  "No", replace
			estadd local calweek "Yes", replace
			estadd local phase   "2+3", replace

	eststo: reg tu_time_activity_13_adj treatment  i.calendar_week i.strata i.stand  if inlist(phase, 2,3), vce(cluster pid)
			sum tu_time_activity_13_adj if treatment==0 & e(sample)
					estadd scalar y_mean=r(mean)
			estadd local strata  "Yes", replace
			estadd local stand   "Yes", replace
			estadd local weekin  "No", replace
			estadd local calweek "Yes", replace
			estadd local phase   "2+3", replace
 
	esttab using "${output_overleaf}/tables/com_timeuse_tottime_p2_p3_others_self.tex", replace keep(treatment)  cells(b(star fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) stats(y_mean N, labels("Control mean" "N")) collabels(none) l nonotes  starlevels(* 0.10 ** 0.05 *** .01) frag mtitles("Others" "Self" "Find Work" "Sleep" "Missing")
	* addnotes("Standard errors are clustered at the PID level in parenthesis." "P-values in brackets" "Time is measured in minutes")

**## Table: Fraction of workers treated in each stand (upper bound)
	
	* Start with screening data to compute denominator (count of those approached)
	use "${datadir}/01. Screening/02. Output/03_screening_completed_cleaned.dta", clear 
		collapse (count) rid, by(stand)
		tempfile approached 
		save `approached'
	* Repeat step above to get total count of those approached, across all stands 
	use "${datadir}/01. Screening/02. Output/03_screening_completed_cleaned.dta", clear 
		collapse (count) rid
		append using `approached'
	replace stand = 100 if stand == .
		tempfile approached 
		save `approached'	

	* Use phase 1 data to compute numerator (count of those enrolled)
	use "${datadir}/Analysis Prep/02. Output/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta", clear
	contract pid 
	keep pid 
	merge 1:1 pid using "${datadir}/04. Announcement/02. Output/03_announcement_completed_cleaned.dta"
	keep if _merge == 3

	bys pid: keep if _n == 1
	collapse (count) pid if treatment == 1, by(stand)
			tempfile treatment 
			save `treatment'
	* Repeat step above to get total count of those enrolled, across all stands 
	use "${datadir}/Analysis Prep/02. Output/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta", clear
	contract pid 
	keep pid 
	merge 1:1 pid using "${datadir}/04. Announcement/02. Output/03_announcement_completed_cleaned.dta"
	keep if _merge == 3
	collapse (count) pid if treatment == 1
		append using `treatment'
	replace stand = 100 if stand == .

	* Merge approached data with enrolment data 
	merge 1:1 stand using `approached'
	assert _merge==3
	drop _merge 

	* Gen share treated at stand = count of those enrolled / count of those approached
	gen perc = pid/rid

	preserve 
	drop rid pid 
	drop if stand==100
	save  "./07. Data/3. Main Study 3.0/02. Cleaning Data/Analysis Prep/02. Output/stand_frac_treated.dta", replace 
	restore 

	* FIXME re-write this code so that it can run in stata version 16 as well. use stand_temp variable below so that the stand ID runs from 1-11.
	* Generate new stand variable that ranges from 1-11 
	egen stand_temp = group(stand)
	replace stand_temp = 100 if stand_temp==12

	la var rid "Workers Approached"
	la var pid "Enrolled in Treatment"
	la var perc "Share"
	la var stand_temp "Stand"
		foreach i in 1 2 3 4 5 6 7 8 9 10 11 100 {
			  sum rid if stand_temp == `i'
			  local rid_mean`i': di %9.0fc `r(mean)'
			  sum pid if stand_temp == `i'
			  local pid_mean`i': di %9.0fc `r(mean)'
			  sum perc if stand_temp == `i'
			  local perc_mean`i': di %9.3fc `r(mean)'
		}
		
		* modify table 
		verify_package texdoc
 		texdoc init "${output_overleaf}/tables/fraction_workers_treated_by_stand.tex", replace force
		tex \begin{tabular}{cccc}
		tex \toprule
		tex \addlinespace
		tex Stand    & Workers Approached & Enrolled in Treatment & Share \\
		tex \addlinespace \hline \addlinespace
		tex 1        & `rid_mean1'           & `pid_mean1'          & `perc_mean1' \\
		tex 2 			 & `rid_mean2'           & `pid_mean2'          & `perc_mean2' \\
		tex 3 			 & `rid_mean3'           & `pid_mean3'          & `perc_mean3' \\
		tex 4 			 & `rid_mean4'           & `pid_mean4'          & `perc_mean4' \\
		tex 5 			 & `rid_mean5'           & `pid_mean5'          & `perc_mean5' \\
		tex 6 			 & `rid_mean6'           & `pid_mean6'          & `perc_mean6' \\
		tex 7 			 & `rid_mean7'           & `pid_mean7'          & `perc_mean7' \\
		tex 8 			 & `rid_mean8'           & `pid_mean8'          & `perc_mean8' \\
		tex 9 			 & `rid_mean9'           & `pid_mean9'          & `perc_mean9' \\
		tex 10 			 & `rid_mean10'          & `pid_mean10'         & `perc_mean10' \\
		tex 11 			 & `rid_mean11'          & `pid_mean11'         & `perc_mean11' \\
		tex \addlinespace \hline \addlinespace
		tex Total    & `rid_mean100'         & `pid_mean100'        & `perc_mean100' \\
		tex \bottomrule
		tex \end{tabular}
		texdoc close

		drop stand_temp
	/*
	la val stand 
	if `c(version)' >= 17 {
		table stand, stat(mean rid pid perc)
		collect style cell var[perc], nformat(%9.3f)
		collect layout (stand[1 2 3 4 5 6 7 8 9 10 11 100]) (result#var)	
		collect label levels var rid "Workers Approached" pid "Enrolled in Treatment" perc "Share", modify
		collect label levels stand 100 "Total"
		collect style cell, halign(center)
		collect style tex, nobegintable
		collect export "${output_overleaf}/tables/fraction_workers_treated_by_stand.tex", replace tableonly 
	}
	*/
  sum perc, d  
  local coef: display %9.1fc `r(max)'*100
  save_input `coef' "max_perc_approached"

  local coef: display %9.1fc `r(mean)'*100
  save_input `coef' "mean_perc_approached"

**## Table: Perceived job finding probability 
	use "./07. Data/3. Main Study 3.0/02. Cleaning Data/08. Others/02. Output/Time Use/03-time-use-makepanel.dta", clear 
		* we have 182 obs that are missing phase info (data collected outside of experiment timeline)
			* true for all obs in stands 1-6

	* compute baseline value for each worker
		* FIXME this isn't actually a baseline value, its phase 1. I'm going to leave out these controls for now. 
	gen temp = tu_jfp_8am if phase==1
	egen bl_seq_pid_jfp_8am = max(temp), by(pid)
	gen miss_bl_seq_pid_jfp_8am = (bl_seq_pid_jfp_8am==.)
		replace bl_seq_pid_jfp_8am = 0 if bl_seq_pid_jfp_8am==.
	drop temp

	* figure out first observation per worker
	sort pid phase  
	egen seq_pid_jfp_8am = seq() if tu_jfp_8am!=., by(pid phase)
	* Number of obs per person in phase 2
	egen numobs_jfp_8am = max(seq_pid_jfp_8am), by(pid phase)

	* Survey completion: We have 100 PIDs out of 123 in phase 2, stand 13 onwards 

	eststo clear 
	eststo: reg tu_jfp_8am treatment i.stand i.strata if phase==2 , cl(pid)
  matrix list r(table)
  local coef: display %9.3fc r(table)[4, "treatment"]
  save_input `coef' "TE_tu_jfp_8am_pvalue"
	estadd local bl_jfp "No", replace
	estadd local surveydate "No", replace
	sum tu_jfp_8am if e(sample) & treatment==0
			estadd scalar y_mean=r(mean)
  local coef: display %9.1fc (_b[treatment]/`r(mean)')*100
  save_input `coef' "TE_tu_jfp_8am_perc"

  /*
	eststo: reg tu_jfp_8am treatment bl_seq_pid_jfp_8am miss_bl_seq_pid_jfp_8am i.stand i.strata if phase==2 , cl(pid)
	 * tab miss_bl_seq_pid_jfp_8am if e(sample) - have BL data for 65% of phase 2 data
	* label this next one as: survey date FE
	estadd local bl_jfp "Yes", replace
	estadd local surveydate "No", replace
	sum tu_jfp_8am if e(sample) & treatment==0
	estadd scalar y_mean=r(mean)
	*/

	eststo: reg tu_jfp_8am treatment i.stand i.strata i.date if phase==2 , cl(pid)
	estadd local bl_jfp "No", replace
	estadd local surveydate "Yes", replace
	sum tu_jfp_8am if e(sample) & treatment==0
	estadd scalar y_mean=r(mean)

	/*
	* First observation per PID 
	eststo: reg tu_jfp_8am treatment i.stand i.strata if phase==2 & seq_pid_jfp_8am==1, cl(pid)
	estadd local bl_jfp "No", replace
	estadd local surveydate "No", replace
	sum tu_jfp_8am if e(sample) & treatment==0
	estadd scalar y_mean=r(mean)

  
	eststo: reg tu_jfp_8am treatment i.stand i.strata bl_seq_pid_jfp_8am miss_bl_seq_pid_jfp_8am  if phase==2 & seq_pid_jfp_8am==1, cl(pid)
	estadd local bl_jfp "Yes", replace
	estadd local surveydate "No", replace
	sum tu_jfp_8am if e(sample) & treatment==0
	estadd scalar y_mean=r(mean)
	

	eststo: reg tu_jfp_8am treatment i.stand i.strata i.date if phase==2 & seq_pid_jfp_8am==1, cl(pid)
	estadd local bl_jfp "No", replace
	estadd local surveydate "Yes", replace
	sum tu_jfp_8am if e(sample) & treatment==0
	estadd scalar y_mean=r(mean)
	*/

	label var tu_jfp_8am "Days"
	label var treatment "Treatment"
	esttab using "${output_overleaf}/tables/tu_jfp_8am_short.tex" , se keep(treatment) nostar l cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) nonotes starlevels(* 0.10 ** 0.05 *** .01) stats(surveydate y_mean N, labels("Survey date FE" "Control mean" "N: worker-survey")) replace collabels(none) frag gaps

	*esttab using "${output_overleaf}/tables/tu_jfp_8am.tex" , se keep(treatment) nostar l cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) nonotes starlevels(* 0.10 ** 0.05 *** .01) stats(y_mean bl_jfp surveydate N, labels("Control mean" "Control for BL response" "Survey date FE" "N: worker-survey")) replace collabels(none) frag gaps

	* Balance in responses by T status
	bys pid: ereplace miss_tu = max(miss_tu)
	bys pid: ereplace stand = max(stand)
	bys pid: ereplace treatment = max(treatment)
	bys pid: gen uniqpid = _n==1
	reg miss_tu treatment i.stand if uniqpid==1 & stand > 12
		* coef .0257396 (pval 0.617)
		* control mean .0833333

**## Stat for paper
	use "./07. Data/3. Main Study 3.0/02. Cleaning Data/01. Screening/02. Output/06_screening_dem_vars_with_pid.dta", clear 
	merge 1:1 pid using "./07. Data/3. Main Study 3.0/02. Cleaning Data/Analysis Prep/02. Output/06_pids_in_mainstudy.dta"
	keep if _merge==3
	gen temp = 1-ss_dem_morestand
	sum temp, d
	local coef: display %9.1fc `r(mean)'*100
  save_input `coef' "ss_dem_onestand"

/*----------------------------------------------------*/
   /* [>   6.  Phase 2 Tests    <] */ 
/*----------------------------------------------------*/

**## Automaticity: Change in psychological default
 	use "./07. Data/3. Main Study 3.0/02. Cleaning Data/06a. Phase 2 Activities/02. Output/03a_phase2act_vignettes_makevar.dta", clear
  isid pid //data is at the pid level 
  ta phase if miss_vignette!=1, m // we had a few surveys done outside of phase 2
  merge 1:1 pid date phase using "./07. Data/3. Main Study 3.0/02. Cleaning Data/Analysis Prep/02. Output/temp_shocks.dta"
  assert phase!=2 if _merge==1
  drop if _merge==2
  drop _merge 

  * reverse scale 
  gen cog_going_without_thinking_v2 = cog_going_without_thinking
  recode cog_going_without_thinking_v2 (1=5) (2=4) (4=2) (5=1)
 
  * Going to the labor stand without thinking
  label var treatment "Treatment"
 	label var treatXpost_attendloo_b25 "Treatment x Post shock"
  eststo clear 
  eststo: reg cog_going_without_thinking_v2 treatment i.standid i.strata , clu(pid)
	sum cog_going_without_thinking_v2 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)
  eststo: reg cog_going_without_thinking_v2 treatment treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 i.standid i.strata, clu(pid)
	sum cog_going_without_thinking_v2 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)
  esttab using "${output_overleaf}/tables/vig_cog_going_wo_think_attendloo_b25.tex" , se(3) replace keep(treatment treatXpost_attendloo_b25) stats(y_mean N, labels("Control mean" "N: worker"))  l nonotes frag cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) nostar collabels(none) nonum nomti

**## Change in preference for flexibility?
* FIXME weights

	use  "./07. Data/3. Main Study 3.0/02. Cleaning Data/06a. Phase 2 Activities/02. Output/06c_phase2act_flextest_combined_makevar.dta", clear
	assert phase==2 //always done in phase 2
  	isid pid flex_question, missok //data is at the pid-question level 
  		* missing values as some did not do survey (miss_flextest)
	rename flex_ann_date date //rename date variable for merge
	merge m:1 pid date using "./07. Data/3. Main Study 3.0/02. Cleaning Data/Analysis Prep/02. Output/temp_shocks.dta"
	assert miss_flextest==1 if _merge==1
	drop if _merge==2 
	drop _merge 
	
	* weights
	egen temp1 = seq(), by(pid)
	egen num_obs = max(temp1), by(pid)
	drop temp1
	
	label var treatXpost_attendloo_b25 "Treatment x Post shock"
	eststo clear 
	eststo: reg fixed_choice_q f_treatment  i.flex_version i.strata i.first_day i.second_day [w=num_obs], clu(pid)
	sum fixed_choice_q if f_treatment == 0 & e(sample)
	estadd scalar y_mean=r(mean)
	estadd local strata          "Yes", replace
	estadd local stand           "Yes", replace
	* shock heterogeneity
	eststo: reg fixed_choice_q f_treatment treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 i.standid i.strata i.first_day i.second_day [w=num_obs], clu(pid)
	sum fixed_choice_q if f_treatment == 0 & e(sample)
	estadd scalar y_mean=r(mean)
	estadd local strata          "Yes", replace
	estadd local stand           "Yes", replace

	esttab using "${output_overleaf}/tables/flex_fixed_choice_attendloo_b25.tex" , se(3) replace keep(f_treatment treatXpost_attendloo_b25) stats(y_mean N, labels("Control mean" "N: worker-question"))  l nonotes frag cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) nostar collabels(none) nonum nomti

/* OLDER 
**## Table: Preference for flexibility OLD

  use "./07. Data/3. Main Study 3.0/02. Cleaning Data/06a. Phase 2 Activities/02. Output/03a_phase2act_vignettes_makevar.dta", clear
  isid pid 

  * Col 1: Prefer daily work (vignettes survey)
  * reminder: a very small number of obs were done in phase 1 and phase 3
	eststo clear 
	eststo: reg pref_daily_for_flex_d_l f_treatment i.week_in i.calendar_week i.phase i.stand i.strata, clu(pid)
	sum pref_daily_for_flex_d_l if f_treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)
	estadd local strata          "Yes", replace
	estadd local stand           "Yes", replace
	estadd local attend_fe         "-", replace

	local coef_pre : display %9.1fc (_b[f_treatment]/`r(mean)')*100*(-1)
	save_input `coef_pre' "coef_pre"

  * Col 2 and 3: Choose and meet target of inflexible contract
	use  "${dir}/02. Cleaning Data/06a. Phase 2 Activities/02. Output/06c_phase2act_flextest_combined_makevar.dta", clear
  isid pid flex_question, missok 
  
	eststo: reg fixed_choice_q f_treatment i.stand i.strata i.first_day i.second_day, clu(pid)
	sum fixed_choice_q if f_treatment == 0 & e(sample)
		estadd scalar y_mean=r(mean)
	estadd local strata          "Yes", replace
	estadd local stand           "Yes", replace
	estadd local attend_fe          "Yes", replace

  local coef_fix : display %9.1fc _b[f_treatment]*100
  save_input `coef_fix' "coef_fix"

	local coef_fix_percent: display %9.1fc (_b[f_treatment]/`r(mean)')*100
	save_input `coef_fix_percent' "coef_fix_percent"
	
	drop if q_choice != flex_question & q_choice != .
	
	eststo: reg met_target f_treatment i.stand  i.first_day i.second_day i.strata if fixed_choice_q == 1, clu(pid)
		sum met_target if f_treatment == 0 & e(sample)
		estadd scalar y_mean=r(mean)
		estadd local strata          "Yes", replace
		estadd local stand           "Yes", replace
		estadd local attend_fe       "Yes", replace

	local coef_met : display %9.0fc (_b[f_treatment]/`r(mean)')*100
	save_input `coef_met' "coef_met"
	
  * Column 4: Job list
	use "${dir}/02. Cleaning Data/06a. Phase 2 Activities/02. Output/04b_phase2act_joblist_combined_makevar.dta", clear
	gen f_treatment = treatment 

	eststo: reg jl_contract_penalty f_treatment i.stand i.strata, clu(pid)
		sum jl_contract_penalty if f_treatment == 0 & e(sample)
		estadd scalar y_mean=r(mean)
		estadd local strata          "Yes", replace
		estadd local stand           "Yes", replace
		estadd local attend_fe         "-", replace

		local coef_pen : display %9.1fc (_b[f_treatment]/`r(mean)')*100
		save_input `coef_pen' "coef_pen"
	
	esttab using "${output_overleaf}/tables/com_activities.tex" , se(3) replace keep(f_treatment) mtitles("Prefer daily work" "Fixed Choice" "Met Target" "Contract Job w Penalty") stats(y_mean N, labels("Control mean" "N"))  l nonotes frag nonum cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) nostar collabels(none)

	* nostars
	esttab using "${output_overleaf}/tables/com_activities_nostar.tex" , replace keep(f_treatment) nostar cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) stats(y_mean N, labels("Control mean" "N"))  collabels(none) l nonotes frag nonumbers nomtitles 
		* mtitles("Fixed Choice" "Met Target" "Contract Job w Penalty" "Prefer daily work")

  * Generate manually: com_activities1.tex com_activities2.tex com_activities3.tex com_activities4.tex

**## Table: Mechanism - Persistence through identity channel (vignettes survey) OLD

	use "${dir}/02. Cleaning Data/06a. Phase 2 Activities/02. Output/03a_phase2act_vignettes_makevar.dta", clear

	eststo clear
	eststo: reg i_tale_of_two_characters_d f_treatment i.stand i.strata i.week_in i.calendar_week i.phase, robust
	sum i_tale_of_two_characters_d if f_treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)
	
	local coef_wrkr: display %9.0fc (_b[f_treatment]/`r(mean)')*100
	save_input `coef_wrkr' "coef_wrkr"
	
  // PB: Added options frag and gaps 
	esttab using "${output_overleaf}/tables/com_identity_channel2.tex", se(3) ///
    frag keep(f_treatment) replace stats( y_mean N, labels( "Control mean"  "N")) ///
    l nonotes collabels(none) addnotes("Robust standard errors" ) nonumber nostar cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ])))
	
  /*
	reg i_commitment_if_late_arrival_d_l f_treatment i.phase i.stand i.strata i.week_in i.calendar_week, robust
	sum  i_commitment_if_late_arrival_d_l if f_treatment==0 & e(sample)
	local coef_commit : display %9.0fc (_b[f_treatment]*-1/`r(mean)')*100
	save_input `coef_commit' "coef_commit"
  */

**## Barchart: Mechanism - Persistence through automaticity of behavior (vignettes survey) OLD
	twoway (hist cog_going_without_thinking if f_treatment == 0, lcolor(gs12) fcolor(gs12) fraction start(1) discrete ) || (hist cog_going_without_thinking if f_treatment == 1, fcolor(none) lcolor(maroon) width(1) lwidth(medium) fraction  start(1) discrete) , ///
	legend(order(1 "Control" 2 "Treatment") pos(6) row(1) region(lstyle(none))) xtitle("") ylabel(, nogrid) xlabel( 1 `" "Strongly" "agree""' 2 "Agree" 3 "Neutral" 4 "Disagree" 5 `" "Strongly" "disagree" "', notick) graphregion(color(white))
	graph export "${output_overleaf}/figures/hist_go_without_thinking_low_att.png", replace
	
	gen cog_going_wo_think_agree = .
		replace cog_going_wo_think_agree = 1 if (cog_going_without_thinking ==1 | cog_going_without_thinking ==2) & cog_going_without_thinking !=.
		replace cog_going_wo_think_agree = 0 if (cog_going_without_thinking ==3 | cog_going_without_thinking ==4 | cog_going_without_thinking ==5) & cog_going_without_thinking !=.

	eststo clear
	eststo: reg cog_going_wo_think_agree f_treatment i.stand i.strata i.vig_interviewer, robust
	sum cog_going_wo_think_agree if f_treatment==0 & e(sample)
	local coef_think : display %9.0fc (_b[f_treatment]/`r(mean)')*100
	save_input `coef_think' "coef_think"
*/

/*----------------------------------------------------*/
   /* [>   7.  Stats for slides/draft    <] */ 
/*----------------------------------------------------*/

**## Beliefs about / intentions to work in the coming week 

	* open announcement data
	use "./07. Data/3. Main Study 3.0/02. Cleaning Data/04. Announcement/02. Output/04_announcement_completed_makevar.dta", clear
	* keep beliefs variables 
	keep pid stand a_belief_attend a_belief_attend_change a_belief_arrival_time a_belief_arrival_time_change a_belief_attend_more a_belief_attend_noless a_belief_arrival_time_more a_belief_arrival_time_noless

	* merge into our main dataset
	merge 1:m pid using "07. Data/3. Main Study 3.0/02. Cleaning Data/Analysis Prep/02. Output/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta", gen(_merge2)
	drop if _merge2==1 //pids not in main study 
	drop _merge*

  sum bs_dem_pred_look if uniqpid==1 & phase==0
	local coef: display %9.1fc `r(mean)'
	save_input `coef' "bs_dem_pred_look"
  sum bs_dem_pred_look_stand if uniqpid==1 & phase==0
	local coef: display %9.1fc `r(mean)'
	save_input `coef' "bs_dem_pred_look_stand"

**## Mechanisms: I need to rearrange my morning activities on the days that I have to go to the stand
  use "./07. Data/3. Main Study 3.0/02. Cleaning Data/06a. Phase 2 Activities/02. Output/03a_phase2act_vignettes_makevar.dta", clear
  isid pid //data is at the pid level 
  ta phase if miss_vignette!=1, m // we had a few surveys done outside of phase 2
  merge 1:1 pid date phase using "./07. Data/3. Main Study 3.0/02. Cleaning Data/Analysis Prep/02. Output/temp_shocks.dta"
  assert phase!=2 if _merge==1
  drop if _merge==2
  drop _merge 

  * reverse scale   
  gen cog_rearrange_to_go_v2 = cog_rearrange_to_go
  recode cog_rearrange_to_go_v2 (1=5) (2=4) (4=2) (5=1)

  reg cog_rearrange_to_go_v2 treatment i.standid i.strata , clu(pid)
	local coeff: display %9.3fc _b[treatment]
  save_input `coeff' "coeff_cog_rearrange_to_go_v2"
 	local t = _b[treatment]/_se[treatment]
	local coeff: display %9.2fc 2*ttail(e(df_r),abs(`t'))
  save_input `coeff' "pval_cog_rearrange_to_go_v2"
  sum cog_rearrange_to_go_v2 if e(sample), d 
  local coeff: display %9.2fc r(mean)
  save_input `coeff' "mean_cog_rearrange_to_go_v2"

**## End of phase 1 announcement comprehension 

	use "./07. Data/3. Main Study 3.0/02. Cleaning Data/08. Others/02. Output/Phase 2 Announcement/02-phase2-announcement-cleaned.dta", clear
 	assert p2_ann_check_completion == 1

 	** Mean comprehension (out of 3)
 	* treatment
	sum p2_ann_tot_correct if treatment == 1 
		local p2_ann_treat_comprend_mean: display %9.1fc (`r(mean)'/3)*100
		save_input `p2_ann_treat_comprend_mean' "p2_ann_treat_comprend_mean"
	* control
	sum p2_ann_tot_correct if treatment == 0
		local p2_ann_cont_comprend_mean: di %9.1fc (`r(mean)'/3)*100
		save_input `p2_ann_cont_comprend_mean' "p2_ann_cont_comprend_mean"
	* overall 
	sum p2_ann_tot_correct
		local p2_ann_overall_comprend_mean: di %9.1fc (`r(mean)'/3)*100
		save_input `p2_ann_overall_comprend_mean' "p2_ann_overall_comprend_mean"

	** Treatment effect on comprehension
	gen corr_perc = p2_ann_tot_correct/3
	la var corr_perc "Percentage answered correctly (out of 3 questions)"

	reg corr_perc treatment i.stand
	scalar treateff_stand = _b[treatment]
	local p2_ann_treateff_coef: di %9.3fc treateff_stand
	save_input `p2_ann_treateff_coef' "p2_ann_treateff_coef"
	scalar p_value = 2*ttail(e(df_r), abs(_b[treatment]/_se[treatment]))
	local p2_ann_treateff_pval: di %9.2fc p_value
	save_input `p2_ann_treateff_pval' "p2_ann_treateff_pval"

	 	texdoc init "${output_overleaf}/tables/p2_ann_completion_balance.tex", replace force

		tex \begin{tabular}{cccc}
		tex \toprule \addlinespace
		tex  & Overall & Control & Treatment & Regression Coef \\
		tex & & & p-value \\
		tex \midrule
		tex Comprehension 			 & `p2_ann_overall_comprend_mean'           & `p2_ann_cont_comprend_mean'          & `p2_ann_treat_comprend_mean' & `p2_ann_treateff_coef' \\
		tex & & & [`p2_ann_treateff_pval'] \\
		tex \bottomrule
		tex \end{tabular}
		texdoc close

/*----------------------------------------------------*/
   /* [>   8.  Employers Survey    <] */ 
/*----------------------------------------------------*/

**## Statistics

	* Open data 
  	use "./07. Data/3. Main Study 3.0/02. Cleaning Data/08. Others/02. Output/Employers Survey/02_employer_survey_cleaned.dta", clear

  	local samplesize: display %9.0fc _N
  	save_input `samplesize' "recruit_sample_N"

	   * tab p5, m
		* 115 recruiters, 56 employers

	* how frequently do you come to the stand in a week?
		* only asked to recruiters (p5==1)
		* a3_v2 only asked to a subset of recruiters - first version was a3
  	sum a3_v2
  	local coef: display %9.0fc `r(mean)'
  	save_input `coef' "freq_stand"

	* how many workers do you hire when you come to the stand?

	 tab a4 if p5==1, m
	 	* only asked to recruiters (p5==1)
	 	* FIXME why is this missing for 58 obs? I think we removed this question after the first round of data collection (where we asked a3). CHECK.

	* "How much time does it typically take to find a worker to replace someone who was supposed to come to work but didn't?" 
	 * For each job type questions 
  	tostring selected_choice_1 , replace
  	replace selected_choice_1=a2 if count_works=="1"
  	replace d1_a_1= d1_s1a if count_works =="1"
  	replace d1_b_1= d1_s1b if count_works =="1"
  	replace d1_c_1= d1_s1c if count_works =="1"
  	replace d1_c_others_1 = d1_s1c_others  if count_works =="1"
  	drop d1_c_1_1 d1_c_1_2 d1_c_2_1 d1_c_3_1 d1_c_998_1 d1_c_2_2 d1_c_3_2 d1_c_998_2  //d1_c_1_3 d1_c_1_998

**## Histogram - what would you do differently?
	gen response_1 = c7_1 if p5==1
	replace response_1 = n7_1 if p5==2

	gen response_2 = c7_2 if p5==1
	replace response_2 = n7_2 if p5==2

	gen response_3 = c7_3 if p5==1
	replace response_3 = n7_3 if p5==2

	gen response_4 = c7_4 if p5==1
	replace response_4 = n7_4 if p5==2

	gen response_5 = c7_5 if p5==1
	replace response_5 = n7_5 if p5==2
	replace response_5 = 1 if p5==2 & (n7_others=="Give to Ration rice and house rent." |n7_others=="Ration rice/house rent provided")
	replace response_5 = 1 if p5==1 & c7_others!=""
	* all correspond to in kind gift giving

	gen response_6 = c7_6 if p5==1
	replace response_6 = n7_6 if p5==2

	gen response_7 = c7_7 if p5==1
	replace response_7 = n7_7 if p5==2

	preserve 
	keep rid response* 
	drop if response_1==.
	reshape long response_, i(rid) j(choice)
	collapse (mean) response_, by(choice)

	label define empresp_lab 1 `""Provide" "training" "' 2 "Insurance" 3 `""Change biz""type""' 4 `""Expand""business""' 5 "In-kind gifts"  6 "Loans"  7 "School fees"
	label value choice empresp_lab 

	graph bar response_, over(choice, label( labsize(medium))) xsize(8) ytitle("Fraction of recruiter responses")
	graph export "$output_overleaf/figures/emp_resp_c7_n7.png",replace
	restore 

**## Histogram - Replacement duration 
	* these questions were only asked to recruiters 

	keep if p5==1 // only recruiters
	preserve
	keep rid d1* selected_choice_1  selected_choice_2
	drop d1_s* 
	replace selected_choice_1 ="5. Concrete" if selected_choice_1 =="5"
	replace selected_choice_1 ="4. Centering" if selected_choice_1 =="4"
	replace selected_choice_1 ="3. Tile Worker" if selected_choice_1 =="3"
	replace selected_choice_1 ="10. Painter" if selected_choice_1 =="10"		
	replace selected_choice_1 ="1. Foundation" if selected_choice_1 =="1"
	replace selected_choice_1 ="11. Carpenter" if selected_choice_1 =="11"
	replace selected_choice_1 ="2. Wall Builder" if selected_choice_1 =="2"
	replace selected_choice_1 ="4. Centering" if selected_choice_1 =="4"		
	replace selected_choice_1 ="6. Demolisher" if selected_choice_1 =="6"
	replace selected_choice_1 ="7. Loadman" if selected_choice_1 =="7"
	replace selected_choice_1 ="9. Welder" if selected_choice_1 =="9"

	reshape long selected_choice_ d1_a_ d1_b_ d1_c_ d1_c_others_ , i(rid) j(choice)

	split d1_c_ ,p("")
	forval i=1/3{
		gen d1_c_1_`i'= 1 if d1_c_1=="`i'" | d1_c_2=="`i'" | d1_c_3 =="`i'"
	}
				
	replace d1_c_1_1 = 0 if d1_c_1_1 ==.
	replace d1_c_1_2 = 0 if d1_c_1_2 ==.
	replace d1_c_1_3 = 0 if d1_c_1_3 ==.

	drop d1_c_1 d1_c_2 d1_c_3

	gen worker_skill =1 if selected_choice_=="1. Foundation" | selected_choice_=="2. Wall Builder" | selected_choice_=="4. Centering" |selected_choice_=="5. Concrete" | selected_choice_=="6. Demolisher" |selected_choice_=="7. Loadman"| selected_choice_=="8. Stone Cutter"

	replace worker_skill = 2 if selected_choice_=="3. Tile Worker" | selected_choice_=="9. Welder" | selected_choice_=="10. Painter" | selected_choice_=="11. Carpenter" 

  // PB: changed bin color and opacity to make the graph more visually appealing. Changed red bins to maroon. 
  qui twoway (hist d1_a_ if worker_skill==1, lcolor(gs12) fcolor(gs12) width(1) fraction start(1) discrete) || ///
         (hist d1_a_ if worker_skill==2, fcolor(none) lcolor(maroon) width(1) lwidth(medium) fraction start(1) discrete), ///
          xtitle("Duration", size(medium))      ///
          ytitle("Fraction of recruiter responses", size(medium))       ///
          yla(, labsize(*1.25))         ///
          legend(label(1 "Unskilled") label(2 "Skilled") pos(2) ring(0) region(lcolor(black)))        ///
          xlabel(1 "<30 mins" 2 "30-90 mins" 3 ">90 mins" 4 `""Not worth" "replacing""' 5 `""Okay to delay"" work""', angle(0) labsize(medium)) 
  graph export "$output_overleaf/figures/rec_replacement_duration.png",replace

**## Histogram - Training - time taken to onboard a new worker

	* How much time do you typically spend helping a new worker understand what needs to be done and how to do it?
	gen d1_b_coded= 1 if d1_b_<30
	replace d1_b_coded= 2 if d1_b_>=30 & d1_b_<60
	replace d1_b_coded= 3 if d1_b_>=60 

	qui twoway (hist d1_b_coded  if worker_skill==1, lcolor(gs12) fcolor(gs12) width(1) fraction start(1) width(1) discrete) || ///
      (hist d1_b_coded if worker_skill==2, fcolor(none) lcolor(maroon) width(1) lwidth(medium) fraction  start(1) width(1) discrete), ///
      xtitle("Duration") ytitle("Fraction of recruiter responses",size(medium)) yla(,labsize(*1.3)) legend( label(1 "Unskilled") label(2 "Skilled") ///
        pos(2) ring(0) region(lcolor(black)) )xlabel(1 "<30 mins" 2 "30-90 mins" 3 ">90 mins", labsize(medium))
	graph export "$output_overleaf/figures/rec_wrkr_training_duration.png",replace
	restore

**## Histogram -  Lower Productivity - Guru vs Venkat

	*Imagine there  are two workers described above. Guru usually comes all five days and Venkatesh typically comes on 3 or 4 of the days. On a given day when both come to work, who do you think would get more done on that day?

	qui graph bar, over(b3,label(labsize(medium))) yla(,labsize(*1.3)) ytitle("Percent",size(medium))
	graph export "$output_overleaf/figures/rec_guru_venkat.png",replace

**## Histogram -  Lower Productivity - Worker reliable (REVIEW) !!!!!
	use "$datadir/08. Others/02. Output/Employers Survey/02_employer_survey_cleaned.dta", clear

	replace b13 = k10 if p5 == 2 // the two variables names are saved differently for recruiters and employers survey
	*It would improve my productivity / ability to earn an income a lot if workers were more reliable in coming to work on the days they say they will.

	qui graph bar, over(b13)

	graph export "$output_overleaf/figures/pdtivity_agree.png",replace

**## Histogram - WTP for more reliable labor
	replace b2_max = l2_max if p5 == 2
	*Imagine there is a job that takes a worker 6 days to complete. If you hire someone who definitely shows up on all 6 days what is the max amount you would be willing to pay as bonus (Rs)?

	qui graph bar, over(b2_max, label(labsize(medium))) b1title(,size(medium)) yla(,labsize(*1.3)) ytitle("Percent",size(medium)) 

	graph export "$output_overleaf/figures/wtp_bonus_max.png",replace

**## Histogram: Employers expect productivity losses from work breaks
	use "$datadir/08. Others/02. Output/Employers Survey/02_employer_survey_cleaned.dta", clear
	keep if p5 == 1
		/*Balu and Sanjay have been doing work at the labor stand for 5 years, and come to the labor stand about 5 days per week. They are both average workers... 
	    
	    In January, Sanjay has to go back to his village for some personal family matters and so is not able to come to the labor stand for two months. He returns in March to Chennai to come back to the labor stand. Balu does not go back to his native and works at the labor stand as usual through this time. Which of the 2 workers would you prefer to hire in March?
		*/
	label define bal_lab 1 "Sanjay" 2 "Balu" 3 "Indifferent"
	label value b5 bal_lab
	qui graph bar, over (b5) 
	qui graph bar, over(b5, label(labsize(medium))) ytitle("Percent", size(medium)) yla(, labsize(*1.3)) 
	graph export "$output_overleaf/figures/rec_balu_sanjay.png", replace

**## Histogram - Multi day work
	use "$datadir/08. Others/02. Output/Employers Survey/02_employer_survey_cleaned.dta", clear
	replace b11 = k9 if p5 == 2
	*Imagine you were hiring ten people at the stand. Of these ten people, how many would typically work for you for more than one day at a time?" (N = 103)

	qui graph bar, over(b11, label(labsize(medium))) b1title(,size(medium)) yla(,labsize(*1.3)) ytitle("Percent",size(medium)) 

	graph export "$output_overleaf/figures/multi_day_work.png",replace

**## Histogram - Avg days
	preserve
	replace c4 = n4 if p5 == 2
	*For those workers you hired at the labor stand, and worked for more than 1 day, what is the average number of days they will work?
	keep if date>td(30mar2023)

	qui graph bar, over(c4, label(labsize(medium))) b1title(Number of Days, size(medium)) ytitle("Percent",size(medium)) yla(,labsize(*1.25))

	graph export "$output_overleaf/figures/avg_days_stand_contract.png",replace
	restore

**## Histogram - Employers anticipate irregular workers
	*Suppose you hired one worker for a 10 day contract (so that the worker said he would come on all days when he took the job). Out of these 10 workdays, on how many days do you think the worker would be absent from work?

	replace b9 = k5 if p5 == 2

	graph bar, over(b9, label(labsize(medium))) b1title(Number of days,size(medium)) yla(,labsize(*1.3)) ytitle("Percent",size(medium)) 
	graph export "$output_overleaf/figures/workers_days_off_10.png",replace

	sum b9, d 
	local b9_mean: display %9.1fc (`r(mean)'/10)*100
	local b9_median: display %9.1fc (`r(p50)'/10)*100
	save_input `b9_mean' "b9_mean"
	save_input `b9_median' "b9_median"

**## Histogram - Extra workers buffer
	replace d4_1 = l7 if p5 == 2
	*For every 10 workers you need, how many extra would you hire as a buffer against absences?

	qui graph bar, over(d4_1, label(labsize(medium))) b1title(Number of Workers, size(medium)) ytitle("Percent",size(medium)) yla(,labsize(*1.25))
	graph export "$output_overleaf/figures/buffer_workers_nos.png",replace

	sum d4_1, d 
	local d4_1_mean: display %9.1fc (`r(mean)'/10)*100
	local d4_1_median: display %9.1fc (`r(p50)'/10)*100
	save_input `d4_1_mean' "d4_1_mean"
	save_input `d4_1_median' "d4_1_median"

**## Histogram - Reason for preferring migrant workers

	* If you hire migrant workers, why do you choose to hire them?
	foreach i in 1 2 3 4 5 998 {
	    replace e1_b_`i' = m1_b_`i' if p5 == 2
	}

	preserve
	keep rid e1_b*
	drop e1_b_others e1_b
	reshape long e1_b_, i(rid) j(choice) 
	collapse (mean) e1_b_, by(choice)

		label define migrant_lab 1 `""Work everyday/" "more often" "' 2 `""Will arrive" "on time""' 3 `""Willing to work for""lower wage""' 4 "Work harder" 5 `""Better at ""following rules""' 998 "Others"
		label value choice migrant_lab 

	qui graph bar e1_b_, over(choice, label( labsize(medium))) ytitle("Fraction of recruiters responding yes") xsize(8)
	graph export "$output_overleaf/figures/migrant_worker_reason.png",replace

	* work everyday/more often
	sum e1_b_ if choice==1
	local e1_b_1: display %9.0fc `r(mean)'*100
	save_input `e1_b_1' "e1_b_1"

	* arrive on time
	sum e1_b_ if choice==2
	local e1_b_2: display %9.0fc `r(mean)'*100
	save_input `e1_b_2' "e1_b_2"

	* willing to work for lower wage
	sum e1_b_ if choice==3
	local e1_b_3: display %9.0fc `r(mean)'*100
	save_input `e1_b_3' "e1_b_3"

	restore

**## Histogram - Advantages of regular workers
	preserve
	drop d2 d2_others
	keep rid d2*
	* What are the (dis)advantages of hiring the same worker repeatedly,if any?
	reshape long d2_, i(rid) j(choice) 
	collapse (mean) d2, by(choice)

	label define adv_lab 1 "Worksite is familiar" 2 "Knows expectation" 3 "Works well with others" 4 "Less training" 5 "Low risk - finding at stand" 6 "None" 998"Others"
	label value choice d2 adv_lab 

	qui graph bar d2, over(choice, label(labsize(medium) angle(25))) xsize(7) ytitle("Fraction of recruiters responding yes", size(medium)) yla(,labsize(*1.3))
	graph export "$output_overleaf/figures/rec_advantages.png",replace
	restore

**## Histogram - Disadvantages of regular workers
	preserve
	drop d3 d3_others
	keep rid d3*
	* What are the (dis)advantages of hiring the same worker repeatedly,if any?
	reshape long d3_, i(rid) j(choice) 
	collapse (mean) d3, by(choice)

	label define disadv_lab 1 "Will be tired" 2 "Demand higher wage" 3 "Not reliable" 4 "Stop working hard" 5 "Disrupt work" 6 "None" 998 "Others"
	label value choice d3 disadv_lab 

	qui graph bar d3, over(choice, label(labsize(medium) angle(25))) xsize(6) ytitle("Fraction of recruiters responding yes", size(medium)) yla(,labsize(*1.3))
	graph export "$output_overleaf/figures/rec_disadvantages.png",replace
	restore

/*----------------------------------------------------*/
   /* [>  9.  Employers' belief survey   <] */ 
/*----------------------------------------------------*/

	use "/Users/${user}/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/02. Cleaning Data/08. Others/02. Output/Employers Survey/employer_activity_mainstudy_cleaned.dta", clear
		*FIXME Why is recruiter id for two people is the same? 9102 repeated. 

	summarize trained_2_weeks, detail
  local samplesize: display %9.0fc `r(N)'
  save_input `samplesize' "employer_activity_sample_N"

	local median_2wk: di %9.0fc r(p50)
	display `median_2wk'

	local diff_2wk: di %9.1fc (r(p50) - 46)*100/46
	display `diff_2wk'

	save_input `median_2wk' "med_2wk" 
	save_input `diff_2wk' "diff_2wk"
		
	summarize trained_2_months, detail
	local median_2mth: di %9.0fc r(p50)
	display `median_2mth'

	local diff_2mth: di %9.1fc (r(p50) - 45)*100/45
	display `diff_2mth'

	save_input `median_2mth' "med_2mth" 
	save_input `diff_2mth' "diff_2mth"


	summarize trained_4_month, detail
	local median_4mth: di %9.0fc r(p50)
	display `median_4mth'

	local diff_4mth: di %9.1fc (r(p50) - 30)*100/30
	display `diff_4mth'

	save_input `median_4mth' "med_4mth" 
	save_input `diff_4mth' "diff_4mth"

/*----------------------------------------------------*/
   /* [>  10.  Employers' job offer survey   <] */ 
/*----------------------------------------------------*/

	use "./07. Data/3. Main Study 3.0/02. Cleaning Data/08. Others/02. Output/Employers Survey/employer_job_offer_cleaned.dta", clear 
  isid pid
  local samplesize: display %9.0fc _N
  save_input `samplesize' "emp_joboffer_sample_N"

	* equal subsidy of Rs. 300

	recode Subsidy_1 (2=0)
	tab Subsidy_1, m 
	sum Subsidy_1
	local Subsidy_1_mean: display %9.1fc `r(mean)'*100
	save_input `Subsidy_1_mean' "Subsidy_1_mean"

	recode Subsidy_2 (2=0)(.=0)
	tab Subsidy_2, m 
	sum Subsidy_2
	local Subsidy_2_mean: display %9.1fc `r(mean)'*100
	save_input `Subsidy_2_mean' "Subsidy_2_mean"

	recode Subsidy_3 (2=0)(.=0)
	tab Subsidy_3, m 
	sum Subsidy_3
	local Subsidy_3_mean: display %9.1fc `r(mean)'*100
	save_input `Subsidy_3_mean' "Subsidy_3_mean"

	recode Subsidy_4 (2=0) (.=0)
	tab Subsidy_4, m 
	sum Subsidy_4
	local Subsidy_4_mean: display %9.1fc `r(mean)'*100
	save_input `Subsidy_4_mean' "Subsidy_4_mean"

	recode Subsidy_5 (2=0) (.=0)
	tab Subsidy_5, m 
	sum Subsidy_5
	local Subsidy_5_mean: display %9.1fc `r(mean)'*100
	save_input `Subsidy_5_mean' "Subsidy_5_mean"

	sum Subsidy_5
	local wtp_trained: di %9.0fc `r(mean)' * 100
	save_input `wtp_trained' "emp_job_offer_wtp_11_22pc"

	* Note: 1 in 10 chance of lottery winner
	tab ball_color, m
		* total of 3 vouchers given 
		* From Alosias email Nov 29, 2023: 2 vouchers expired, not claimed by the employer within 3 days time period, and 1 claimed but study participant didn't show up on that day.

/*----------------------------------------------------*/
   /* [>  11. bedtime results   <] */ 
/*----------------------------------------------------*/

	use "./07. Data/3. Main Study 3.0/02. Cleaning Data/08. Others/02. Output/Time Use/03-time-use-makepanel.dta", clear

	g tu_bedtime_minutes = (tu_bedtime - tc(00:00)) / 60000
	la var tu_bedtime_minutes "Bedtime in minutes"

	tab phase, m 
		* all early stands will have phase=., as time use survey was done much later.

	eststo clear
	eststo: reg tu_bedtime_minutes treatment i.stand i.strata
	scalar bedtime_effect = _b[treatment]
	local coef: di %9.2fc bedtime_effect
	save_input `coef' "bedtime_treatment_coefficient"

	scalar t_treat = _b[treatment] / _se[treatment]
	scalar bedtime_pval = 2 * (ttail(e(df_r), abs(scalar(t_treat))))
	local pval: di %9.3fc bedtime_pval
	save_input `pval' "bedtime_treatment_pval"
		estadd local stand_fe = "Yes"
		estadd local strata_fe = "Yes"
		estadd local phase_fe = "No"		

	eststo: reg tu_bedtime_minutes treatment i.stand i.strata i.phase
		estadd local stand_fe = "Yes"
		estadd local strata_fe = "Yes"
		estadd local phase_fe = "Yes"

	label var treatment "Treatment"
	esttab using "$output_overleaf/tables/timeuse-bedtime-minutes.tex" , se order(treatment) keep(treatment) nostar l cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) nonotes  starlevels(* 0.10 ** 0.05 *** .01) stats(phase_fe N, labels("Phase FE" "N"))  replace collabels(none) frag gaps nonum nomti

/*----------------------------------------------------*/
   /* [>   12.  picture quiz   <] */ 
/*----------------------------------------------------*/
 
	use "./07. Data/3. Main Study 3.0/02. Cleaning Data/08. Others/02. Output/Picture Quiz/02-picture-quiz-cleaned.dta", clear 

	* FIXME figure out the right attempt number variable, control for that.

	/* 	
	eststo: reg q treatment i.stand i.surveyor_id
	sum q if treatment == 0
	local mean_depvar = r(mean)
	estadd scalar control_mean = `mean_depvar'
	estadd local stand_fe 				"Yes"
	estadd local surveyor_fe 			"Yes"
	* estadd local attempt_fe 			"No"
	estadd local phase_fe 				"No"

		eststo r2: reg q treatment i.stand i.surveyor_id i.total_attempts
		estadd local stand_fe 				"Yes"
		estadd local surveyor_fe 			"Yes"
		estadd local attempt_fe 			"Yes"
		estadd local phase_fe 				"No"
		estadd scalar control_mean = `mean_depvar'
		estadd scalar obs = 					e(N) 
	*/

	eststo clear 
	eststo m1: reg q treatment i.stand i.phase
	estadd local stand_fe 				"Yes"
	estadd local surveyor_fe 			"No"
	estadd local phase_fe 				"Yes"
	sum q if treatment == 0 & e(sample)
	local mean_depvar = r(mean)
	estadd scalar control_mean = 	`mean_depvar'
	estadd scalar obs = 					e(N) 

	eststo m2: reg q treatment i.stand i.surveyor_id i.phase
	estadd local stand_fe 				"Yes"
	estadd local surveyor_fe 			"Yes"
	estadd local phase_fe 				"Yes"
	sum q if treatment == 0 & e(sample)
	local mean_depvar = r(mean)
	estadd scalar control_mean = 	`mean_depvar'
	estadd scalar obs = 					e(N) 
	
	label var treatment "Treatment"

	esttab m1 m2 using "$output_overleaf/tables/picture-quiz-responses-to-questions.tex" , se order(treatment) keep(treatment) nostar l cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) nonotes  starlevels(* 0.10 ** 0.05 *** .01) stats(stand_fe phase_fe surveyor_fe control_mean obs, labels("Stand FE" "Phase FE" "Staff FE" "Control mean" "N: staff-question"))  replace collabels(none) frag gaps nonum nomti
		* attempt_fe "Quiz number FE"

	sum q if e(sample)

