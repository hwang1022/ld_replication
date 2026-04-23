************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Replicate the main paper analysis using HW's new dataset
* 	Author:				HW 
* 	Last modified:		2026-Apr-15 (HW)
************************************************************
************************************************************

************************************************************
**# Figure 1: Probability of finding a job by arrival time
************************************************************

	use "$main_data" , clear
	gen arrival_time_hours_30 = . 
	forvalues i =  6/10 {
	  replace arrival_time_hours_30 = `i' if arrival_time_hours < `i'.5 & arrival_time_hours_30 == . & phase == 0
	  replace arrival_time_hours_30 = `i'.5 if arrival_time_hours < `i'+1  & arrival_time_hours_30 == . & phase == 0
	}
	binscatter work arrival_time_hours_30 if arrival_time_hours <=10 & phase == 0, xlabel(6(0.5)10 6.5 "6.30" 7.5 "7.30" 8.5 "8.30" 9.5 "9.30") ylabel(, nogrid) xtitle("Arrival Time") ytitle("Mean Work") line(connect) lc(maroon) mc(navy) yscale(range(0.4 0.8))
	graph export "$figures/comm_bs_attend_work_30.pdf", replace
	
*********************************************************************
**# Figures 2-3: Attendance and arrival time in Phase 1 and Phase 2
*********************************************************************

	use "$main_data" , clear

	gen arrival_time_hours_std_daily = arrival_time_hours
	replace arrival_time_hours_std_daily = arrival_time_hours - 0.25 if inlist(stand, ${cutoff_0815}) 
	replace arrival_time_hours_std_daily = arrival_time_hours + 0.25 if inlist(stand, ${cutoff_0745})
	replace arrival_time_hours_std_daily = 10 if arrival_time_hours_std_daily >= 10 & arrival_time_hours_std_daily != .

	forval phase = 1/2 {
	
		ksmirnov attend_nadj if phase == `phase', by(treatment)
		local pval: display %4.3f `r(p)'
		distplot attend_nadj if phase == `phase', lcolor(gs12 maroon) over(treatment) ylabel(, nogrid) legend(order(1 "Control" 2 "Treatment") pos(6) row(1) region(lstyle(none))) note("K-Smirnov test p-value: `pval'") graphregion(color(white)) xtitle("Days of attendance in a week (Phase `phase')")
		graph export "$figures/comm_dist_attend_nadj_p`phase'.pdf", replace


		twoway (hist arrival_time_hours_std_daily if treatment == 0 & inrange(arrival_time_hours_std_daily, 5.5, 12)  & phase == `phase', lcolor(gs12) fcolor(gs12) fraction start(5.5)  width(0.25) ) || (hist arrival_time_hours_std_daily if treatment == 1 & inrange(arrival_time_hours_std_daily, 5.5, 12)  & phase == `phase' , fcolor(none) lcolor(maroon) lwidth(medium) fraction   start(5.5)  width(0.25) ),legend(on row(1) label(1 "Control") label(2 "Treatment") pos(6) ring(1) ) xlabel(6(1)10) xmtick(6.5(1)10) note("*Treatment cut-off times are standardised to 8am") graphregion(color(white)) xtitle("Arrival time (observed) in fraction of hours (Phase `phase')")
		graph export "$figures/hist_arrival_time_by_treatment_p`phase'_daily.pdf", replace
	}


**************************
**# Figure 4: Attendance
**************************

	use "$main_data" , clear
	* Every 2 weeks (except 3 weeks once in phase 1 b/c 7 in total) in P1 and P2, every month in P3
	gen bins1 = . 
	replace bins1 = 0 if week_in == 0
	replace bins1 = 1.5 if (week_in == 1 | week_in == 2) & phase ==1
	replace bins1 = 4 if (week_in == 3 | week_in == 4 | week_in == 5) & phase ==1
	replace bins1 = 6.5 if (week_in == 6 | week_in == 7) & phase ==1
	replace bins1 = 8.5 if (week_in == 1 | week_in == 2) & phase ==2
	replace bins1 = 10.5 if (week_in == 3 | week_in == 4) & phase ==2
	replace bins1 = 12.5 if (week_in == 5 | week_in == 6) & phase ==2
	replace bins1 = 14.5 if (week_in == 7 | week_in == 8) & phase ==2
	replace bins1 = 17.5 if (week_in == 1 | week_in == 2 |week_in == 3 | week_in == 4) & phase ==3
	replace bins1 = 21.5 if (week_in == 5 | week_in == 6 |week_in == 7 | week_in == 8) & phase ==3
	replace bins1 = 25.5 if (week_in == 9 | week_in == 10 |week_in == 11 | week_in == 12) & phase ==3
	replace bins1 = 29.5 if (week_in == 13 | week_in == 14 |week_in == 15 | week_in == 16) & phase ==3
	replace bins1 = 33.5 if (week_in == 17 | week_in == 18 |week_in == 19 | week_in == 20) & phase ==3
	replace bins1 = 37.5 if (week_in == 21 | week_in == 22 |week_in == 23 | week_in == 24) & phase ==3
	replace bins1 = 41.5 if (week_in == 25 | week_in == 26 |week_in == 27 | week_in == 28) & phase ==3


	reg attend_adj bl_attend bl_earn miss_bl_earn bl_modalwage i.strata i.stand i.calendar_week, vce(clu pid)
	estimates store clustered
	predict attend_adj_resid2 if e(sample), resid

	keep if bins1 != . & bins1 <40
		
	* Heather's version without CI
	binscatter attend_adj_resid2 bins1 , by(treatment) discrete colors(navy maroon) msymbols(O X) ///
	xline(7.5, lpattern(dash) lcolor(black)) xline(15.5, lpattern("..--..--") lcolor(black)) ///
	xline(0.5, lpattern(dash_dot) lcolor(black)) line(connect) legend(label(1 "Control") ///
	label(2 "Treatment") size(small) row(1) symysize(0.75)  symxsize(5) region(lstyle(none)) ///
	position(bottom)) ytitle("Weekly Mean Attend", size(small)) xtitle("Weeks in Phase", size(small)) ///
	yscale(range(-1 1.5))  xlab(0(5)40) ///
	text(1.5 4 "{bf:Phase 1}", size(small)) text(1.5 11.5 "{bf:Phase 2}", size(small))  ///
	text(1.5 20 "{bf:Phase 3}", size(small)) text(1.5 0 "{bf:BL}", size(small))

	graph export "$figures/attend_adj_bs_p1_p2_p3_stand_calweek_v2_noci.pdf", replace


	* Heather's version with CI
	tempfile attendance_temp_save
	save `attendance_temp_save' , replace
	statsby, by(bins1 treatment) : ci means attend_adj_resid2 , level(90)
	drop N se level 
	
	twoway  (connected mean bins1 if treatment == 1, lc(maroon) mcolor(maroon)) (rcap lb ub bins1 if treatment == 1, lc(maroon)) ///
			(connected mean bins1 if treatment == 0, lc(navy) mcolor(navy)) (rcap lb ub bins1 if treatment == 0, lc(navy)) , ///
			xline(7.5, lpattern(dash) lcolor(black)) xline(15.5, lpattern("..--..--") lcolor(black)) ///
			xline(0.5, lpattern(dash_dot) lcolor(black)) legend(label(1 "Control") ///
			label(2 "Treatment") size(small) row(1) symysize(0.75)  symxsize(5) region(lstyle(none)) ///
			position(bottom)) ytitle("Weekly Mean Attend", size(small)) xtitle("Weeks in Phase", size(small)) ///
			yscale(range(-1 1.5))  xlab(0(5)40) ///
			text(1.5 4 "{bf:Phase 1}", size(small)) text(1.5 11.5 "{bf:Phase 2}", size(small))  ///
			text(1.5 20 "{bf:Phase 3}", size(small)) text(1.5 0 "{bf:BL}", size(small))

			graph export "$figures/attend_adj_bs_p1_p2_p3_stand_calweek_v2.pdf", replace


	
*******************************************************************
**# Figure 5: Treatment effect on morning routines during Phase 2
*******************************************************************

****
**## Panel A
****

	use "$main_data" , clear
	keep if !mi(r_reg_morning_act_water)

	reshape long r_reg_morning_act_, i(pid) j(activities) string
	tempfile temp_save
	save `temp_save' , replace
	statsby, by(activities treatment) : ci means r_reg_morning_act_, level(90)
	drop N se level

	gen bord = 1 if activities == "water"
	replace bord = 2 if activities == "cook_breakf"
	replace bord = 3 if activities == "eat_breakf"
	replace bord = 4 if activities == "help_kids"
	replace bord = 5 if activities == "drop_kids"
	replace bord = 6 if activities == "wash"
	replace bord = 7 if activities == "pray"
	replace bord = 8 if activities == "shopping"
	replace bord = 9 if activities == "998"

	twoway (bar mean bord if treatment == 0,  lcolor(gs12) fcolor(gs12)) || ///
      (bar mean bord if treatment == 1, fcolor(none) lcolor(maroon)) || ///
      (rcap lb ub bord if treatment == 0, lc(gs8)) || ///
      (rcap lb ub bord if treatment == 1, lc(maroon)), ///
      xlabel(1 `" "Get" "water" "' 2 `" "Cook" "breakfast" "' 3 `" "Eat" "breakfast" "' 4 `" "Help get" "kids ready" "' 5 `" "Drop kids" "at school" "' 6 "Wash/bathe" 7 `" "Temples/" "prayers" "' 8 `" "Go to the" "store/shop" "' 9 "Others", noticks labsize(small)) ///
      xtitle("") ytitle("Percent of respondents selecting each option") legend(order(1 "Control" 2 "Treatment") pos(6) row(1))
	graph export "$figures/bar_morning_activities_low_att.pdf", replace
	

****
**## Panel B
****

	use "$main_data" , clear
	keep if !mi(r_morning_alarm)
	
	graph bar (meanci) r_morning_alarm, over(treatment) asyvars ///
	bar(1, fcolor(gs12) lcolor(gs12)) ///
	bar(2, fcolor(none) lcolor(maroon)) ///
	ytitle("Share of respondents") ///
	yscale(range(0 0.5)) ///
	legend(order(1 "Control" 2 "Treatment") row(1) position(bottom))

    graph export "$figures/bars_use_alarm.pdf", replace



********************************************
**## Figure 6: Job preferences at baseline
********************************************

	* (a) Likelihood of accepting a long-term, formal job if offered one
	use "$main_data" , clear
	duplicates drop pid , force
	
	label define lngterm_work 1 "Least likely" 2 "Not likely" 3 `""Neither likely""or unlikely""' 4 "Likely" 5 "Very likely"  
	label value bs_dem_lngterm_work lngterm_work 

	qui twoway hist bs_dem_lngterm_work , lcolor(gs12) fcolor(gs12) frac xla(1/5, valuelabel) discrete width(0.5) xtitle("") 
	graph export "$figures/bs_dem_no_ltjob.pdf",replace	



	* (b) Characteristics of casual jobs found at the stands most appreciated by participants
	use "$main_data" , clear
	duplicates drop pid , force
	
	keep pid bs_dem_no_ltjob_* 
	drop bs_dem_no_ltjob_reasons bs_dem_no_ltjob_reasons_oth

	reshape long bs_dem_no_ltjob_, i(pid) j(reason)
	collapse (mean) bs_dem_no_ltjob_, by(reason)
	
	gsort -bs_dem_no_ltjob_
	gen reason_by_popular = _n
	label define no_ltjob_lab_sorted ///
		1 "Earn more" 2 `""Like current""profession""' 3 `""Prefer" "flexibility" "' ///
		4 `""More free""time""' 5 `""Don't like""having boss""'  6 `""Don't have""qualifications""'  
	label value reason_by_popular no_ltjob_lab_sorted

	gr bar bs_dem_no_ltjob_, over(reason_by_popular, label(labsize(medium))) xsize(8) ytitle("Fraction")  bar(1, fcolor(gs12) lcolor(gs12))
	graph export "$figures/bs_dem_no_ltjob_reasons.pdf",replace


*********************************************
**## Figure 7: Predicted Worker Absenteeism
*********************************************

	use "$final/ls_employers_survey_combined.dta" , clear
	
	graph bar, over(comb_10day_contract_absent_days, label(labsize(medium))) b1title(Number of days,size(medium)) yla(,labsize(*1.3)) ytitle("Percent",size(medium)) bar(1, fcolor(gs12) lcolor(gs12))
	graph export "$figures/workers_days_off_10.pdf",replace



	
********************************************
**## Figure 8: Costs incurred by employers
********************************************

	* Open data
  	use "$final/ls_employers_survey_combined.dta", clear

	* "How much time does it typically take to find a worker to replace someone who was supposed to come to work but didn't?"
	 * For each job type questions
	 * Note: count_works was dropped in cleaning; !mi(rec_rpw_find_time) proxies count_works=="1"
	 * because the single-work cost variables are only populated when there is one work type.
  	tostring rec_rpw_work_1 , replace
  	replace rec_rpw_work_1=rec_worker_type if !mi(rec_rpw_find_time)
  	replace rec_rpw_find_time_1= rec_rpw_find_time if !mi(rec_rpw_find_time)
  	replace rec_rpw_onboard_time_1= rec_rpw_onboard_time if !mi(rec_rpw_onboard_time)
  	replace rec_rpw_addnl_cost_1= rec_rpw_addnl_cost if !mi(rec_rpw_addnl_cost)
  	replace rec_rpw_addnl_cost_others_spec_1 = rec_rpw_addnl_cost_others_spec  if !mi(rec_rpw_addnl_cost)

	replace rec_rpw_work_1 ="5. Concrete" if rec_rpw_work_1 =="5"
	replace rec_rpw_work_1 ="4. Centering" if rec_rpw_work_1 =="4"
	replace rec_rpw_work_1 ="3. Tile Worker" if rec_rpw_work_1 =="3"
	replace rec_rpw_work_1 ="10. Painter" if rec_rpw_work_1 =="10"
	replace rec_rpw_work_1 ="1. Foundation" if rec_rpw_work_1 =="1"
	replace rec_rpw_work_1 ="11. Carpenter" if rec_rpw_work_1 =="11"
	replace rec_rpw_work_1 ="2. Wall Builder" if rec_rpw_work_1 =="2"
	replace rec_rpw_work_1 ="4. Centering" if rec_rpw_work_1 =="4"
	replace rec_rpw_work_1 ="6. Demolisher" if rec_rpw_work_1 =="6"
	replace rec_rpw_work_1 ="7. Loadman" if rec_rpw_work_1 =="7"
	replace rec_rpw_work_1 ="9. Welder" if rec_rpw_work_1 =="9"


	reshape long rec_rpw_work_ rec_rpw_find_time_ rec_rpw_onboard_time_ , i(recruiter_id) j(choice)

	gen worker_skill =1 if rec_rpw_work_=="1. Foundation" | rec_rpw_work_=="2. Wall Builder" | rec_rpw_work_=="4. Centering" |rec_rpw_work_=="5. Concrete" | rec_rpw_work_=="6. Demolisher" |rec_rpw_work_=="7. Loadman"| rec_rpw_work_=="8. Stone Cutter"

	replace worker_skill = 2 if rec_rpw_work_=="3. Tile Worker" | rec_rpw_work_=="9. Welder" | rec_rpw_work_=="10. Painter" | rec_rpw_work_=="11. Carpenter"


  // PB: changed bin color and opacity to make the graph more visually appealing. Changed red bins to maroon.
  qui twoway (hist rec_rpw_find_time_ if worker_skill==1, lcolor(gs12) fcolor(gs12) width(1) fraction start(1) discrete) || ///
         (hist rec_rpw_find_time_ if worker_skill==2, fcolor(none) lcolor(maroon) width(1) lwidth(medium) fraction start(1) discrete), ///
          xtitle("Duration", size(medium))      ///
          ytitle("Fraction of recruiter responses", size(medium))       ///
          yla(, labsize(*1.25))         ///
          legend(label(1 "Unskilled") label(2 "Skilled") pos(2) ring(0) region(lcolor(black)))        ///
          xlabel(1 "<30 mins" 2 "30-90 mins" 3 ">90 mins" 4 `""Not worth" "replacing""' 5 `""Okay to delay"" work""', angle(0) labsize(medium))
  graph export "$figures/rec_replacement_duration.pdf",replace

**## Histogram - Training - time taken to onboard a new worker

	* How much time do you typically spend helping a new worker understand what needs to be done and how to do it?
	gen d1_b_coded= 1 if rec_rpw_onboard_time_<30
	replace d1_b_coded= 2 if rec_rpw_onboard_time_>=30 & rec_rpw_onboard_time_<60
	replace d1_b_coded= 3 if rec_rpw_onboard_time_>=60

	qui twoway (hist d1_b_coded  if worker_skill==1, lcolor(gs12) fcolor(gs12) width(1) fraction start(1) width(1) discrete) || ///
      (hist d1_b_coded if worker_skill==2, fcolor(none) lcolor(maroon) width(1) lwidth(medium) fraction  start(1) width(1) discrete), ///
      xtitle("Duration") ytitle("Fraction of recruiter responses",size(medium)) yla(,labsize(*1.3)) legend( label(1 "Unskilled") label(2 "Skilled") ///
        pos(2) ring(0) region(lcolor(black)) )xlabel(1 "<30 mins" 2 "30-90 mins" 3 ">90 mins", labsize(medium))
	graph export "$figures/rec_wrkr_training_duration.pdf",replace
	


*****************************************************************
**# Figure 9: Potential implications for labor market structure
*****************************************************************

	use "$final/ls_employers_survey_combined.dta", clear

	* The comb_relay_* variables already combine recruiter (c7_*) and employer (n7_*)
	* responses, prioritizing recruiter data and filling with employer data if missing.
	gen response_1 = comb_relay_more_training
	gen response_2 = comb_relay_offer_benefits
	gen response_3 = comb_relay_skill_project
	gen response_4 = comb_relay_expand_business
	gen response_5 = comb_relay_inkind_gifts
	replace response_5 = 1 if role==2 & (em_relay_others_spec=="Give to Ration rice and house rent." |em_relay_others_spec=="Ration rice/house rent provided")
	replace response_5 = 1 if role==1 & rec_relay_others_spec!=""
	* all correspond to in kind gift giving
	gen response_6 = comb_relay_intrest_free_loans
	gen response_7 = comb_relay_pay_school_fees


	keep recruiter_id response*
	drop if response_1==.
	reshape long response_, i(recruiter_id) j(choice)
	collapse (mean) response_, by(choice)

	label define empresp_lab 1 `""Provide" "training" "' 2 "Insurance" 3 `""Change biz""type""' 4 `""Expand""business""' 5 "In-kind gifts"  6 "Loans"  7 "School fees"
	label value choice empresp_lab

	graph bar response_, over(choice, label( labsize(medium))) xsize(8) ytitle("Fraction of recruiter responses") bar(1, fcolor(gs12) lcolor(gs12))
	graph export "$figures/emp_resp_c7_n7.pdf",replace


***********************************
**# Table 1: Labor Supply Effects
***********************************


	* Note: sample size here is 1572 and not 1575 because 3 PIDs got late announcements in week 2, so week 1 data is missing

	use "$main_data" , clear
	lab var work1_nadj	"Work, Mean Impute"
	lab var work_nadj	"Work, Rand Impute"

	gen  temp1 = work_orig if recall_reliable == 1
  	egen temp2 = total(temp1) , by(pid phase week_in) missing
  	egen work1_wkly2 = max(temp2), by(pid phase week_in)
  	drop temp*
	
	
	eststo clear 
	eststo a1: reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum attend_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)
  

	eststo b1: reg attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
	sum attend_and_before8_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)
	
  
	eststo a2: reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	sum attend_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)


	eststo b2: reg attend_and_before8_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
	sum attend_and_before8_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)


	eststo d2: reg work1_wkly2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)

	sum work1_wkly2 if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)


	esttab b1 a1 b2 a2 d2 using "$tables/com_weekly_attend_b8_attend_work1_frag2_rephw.tex",  ///
	replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
	stats( y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
	nonotes nonumbers mtitles("By 8" "Attend" "By 8" "Attend" "Work") nostar booktabs ///
	mgroups("Phase 1" "Phase 2" , pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))




*****************************************
**# Table 2: Shocks Erode Habit Stock
*****************************************

****
**## 1. Call Data
****

	use "$main_data" , clear
	egen standid = group(stand)
	gen treat = treatment
	
	gen treatXweek_in = treatment*week_in
	gen treatXpostweek5 = treatment*(week_in>=5)

****
**## 2. Prediction
****

	reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment if phase<2	
	predict resid_day_attendph2 if phase==2, residuals
	
	
	sort standid phase calendar_week date pid
	by standid phase calendar_week: gen stand_ph_calweek_id1 = 1 if _n==1
	egen temp2 = seq() if stand_ph_calweek_id1 == 1, by(standid phase)
	egen stand_ph_calweek = max(temp2), by(standid phase calendar_week)
	gen treatXstand_ph_calweek = treatment*stand_ph_calweek
	drop temp*
	

****
**## 3. Gen Attendance
****

	* pid's in chronological order
	egen pid2 = group(standid pid)
	sort pid2 date
	
	* leave one out means
	gen avg_wkattend_loo = . 
	forvalues s=1/11 {
		quietly summ pid2 if standid==`s'
		forvalues i=`r(min)'/`r(max)' {
			quietly egen temp1 = mean(resid_day_attendph2) if standid==`s' & pid2!=`i' & phase==2, by(standid calendar_week)
			quietly egen temp2 = max(temp1) if phase==2, by(standid calendar_week)
			quietly replace avg_wkattend_loo = temp2 if pid2==`i'
			drop temp*
		}
	}
			

****
**## 4. Gen Shock Indicators and Auxiliary Vriables
****

	* interaction for first stage
	gen treatXavg_wkattend_loo = treatment*avg_wkattend_loo
	_pctile  avg_wkattend_loo if phase==2 & avg_wkattend_loo!=. & dow==1, p(5, 10, 15, 20, 25, 30, 50)
	scalar pct25_attendloo = r(r5)
 
	gen wkof_attendloo_b25 = (avg_wkattend_loo < pct25_attendloo) if phase==2 & avg_wkattend_loo!=.
	gen treatXwkof_attendloo_b25 = treatment*wkof_attendloo_b25


	* first calendar week of shock - loo - varies by pid
	gen temp = stand_ph_calweek if wkof_attendloo_b25==1 & phase==2
	egen firstpostshockl_calwk25 = min(temp) if phase==2, by(pid)
	drop temp*
	egen firstpostshockl_calwk25all = max(firstpostshockl_calwk25), by(pid)
	gen treatXfirstpostshockl_calwk25all = treatment*firstpostshockl_calwk25all		

	* weeks since shock
	gen wks_since_shock25 = stand_ph_calweek - firstpostshockl_calwk25 if phase==2

	* dummy for first week in which shock happens (contemporaneous shock)
	gen firstwk_attendloo_b25 = (wks_since_shock25 == 0)
	gen treatXfirstwk_attendloo_b25 = treatment*firstwk_attendloo_b25

	* post variable
	gen post_attendloo_b25 = (wks_since_shock25 > 0 & wks_since_shock25<.)

	* fill out variable for phase 3
	egen temp = max(post_attendloo_b25) if phase>=2, by(pid)
	replace post_attendloo_b25 = temp if phase==3
	drop temp
	* interactions
	gen treatXpost_attendloo_b25 = treatment*post_attendloo_b25
	

	gen attendloo25_post1 = (wks_since_shock25==1)
	gen treatXattendloo25_post1 = treatment*attendloo25_post1
			
	
	gen attendloo25_post2p = (wks_since_shock25>=2 & wks_since_shock25<.)
	gen treatXattendloo25_post2p = treatment*attendloo25_post2p
	
	
	egen temp1 = mean(week_in) if dow==1, by(pid phase)
	egen temp2 = max(temp1), by(pid phase)
	gen week_in_dm = week_in - temp2
	drop temp*
	gen treatXweek_in_dm = treat*week_in_dm



****
**## 5. Regressions
****

	eststo clear 
  
	* Column 1
	eststo: reg attend_nadj treat treatXweek_in_dm  attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 , vce(cluster pid)
	estadd local weekin  "Yes", replace
	estadd local calweek "Yes", replace
	matrix pval = J(1,2,.)
	matrix colnames pval = treat treatXweek_in_dm
	matrix pval[1,1] = r(table)[4,1]
	matrix pval[1,2] = r(table)[4,2]
	estadd matrix pval 
	

	
	* Column 2
	eststo: reg attend_nadj treat treatXpostweek5 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 , vce(cluster pid)
	estadd local weekin  "Yes", replace
	estadd local calweek "Yes", replace
	
	matrix pval = J(1,2,.)
	matrix colnames pval = treat treatXpostweek5
	matrix pval[1,1] = r(table)[4,1]
	matrix pval[1,2] = r(table)[4,2]
	estadd matrix pval 
  
  

	* Column 3
	reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
	boottest {treat} {treatXpost_attendloo_b25}, seed(123) reps(2048) boottype(wild) nograph 
	matrix pval = J(1,2,.)
	matrix colnames pval = treat treatXpost_attendloo_b25
	matrix pval[1,1] = r(p_1)
	matrix pval[1,2] = r(p_2)

	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
	estadd local calweek "Yes", replace
	estadd local weekin  "Yes", replace
	estadd matrix pval 
	
	
	* Column 4 - time trend 
	reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
	boottest {treat} {treatXpost_attendloo_b25} {treatXweek_in_dm}, seed(123) reps(2048) boottype(wild) nograph 
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
	boottest {treat} {treatXattendloo25_post1} {treatXattendloo25_post2p}, seed(123) reps(2048) boottype(wild) nograph 
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
				nostar l cells(b(fmt(a3)) se(fmt(3) par) pval(fmt(3) par("[" "]") pvalue(pval))) nonotes  ///
				starlevels(* 0.10 ** 0.05 *** .01) ///
				stats(weekin calweek N, labels("Week in phase FE" "Calendar Week FE" "N: worker-weeks")) ///
				replace collabels(none) frag gaps nomtitles 
				
				
	  esttab 	using "$tables/shocks_attendloo_b25_regularp_jul.tex" , se ///
				keep(	treat treatXweek_in_dm treatXpostweek5 treatXpost_attendloo_b25 treatXattendloo25_post1 ///
						treatXattendloo25_post2p treatXweek_in_dm) ///
				order(	treat treatXpost_attendloo_b25 treatXattendloo25_post1 ///
						treatXattendloo25_post2p treatXpostweek5 treatXweek_in_dm ) ///
				nostar l cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par("[" "]"))) nonotes  ///
				starlevels(* 0.10 ** 0.05 *** .01) ///
				stats(weekin calweek N, labels("Week in phase FE" "Calendar Week FE" "N: worker-weeks")) ///
				replace collabels(none) frag gaps nomtitles 
	
	
	eststo clear


******************
**# Automaticity
******************

	eststo clear 
	eststo: reg cog_going_without_thinking treat i.standid i.strata if phase == 2, clu(pid)
	sum cog_going_without_thinking if treat==0 & e(sample)
	estadd scalar y_mean=r(mean)
	eststo: reg cog_going_without_thinking treat treatXpost_attendloo_b25 post_attendloo_b25 ///
				treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 i.standid i.strata if phase == 2, clu(pid)
	sum cog_going_without_thinking if treat==0 & e(sample)
	estadd scalar y_mean=r(mean)
	esttab using "$tables/vig_cog_going_wo_think_attendloo_b25.tex" , se(3) replace keep(treat treatXpost_attendloo_b25) stats(y_mean N, labels("Control mean" "N: worker")) nonotes cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) nostar nomtitles style(tex) booktabs nolz label  collabels(none)
	eststo clear 
	
	
	
  
*****************
**# Flexibility
*****************
  /*
	eststo clear 
	
	recode jl_choice1_fixed_vs_stand 2 = 0
	replace jl_choice1_fixed_vs_stand = jl_contract_penalty if jl_choice1_fixed_vs_stand == 1
	
	eststo: reg jl_choice1_fixed_vs_stand treatment i.stand i.strata, clu(pid)
	sum jl_choice1_fixed_vs_stand if treat == 0 & e(sample)
	estadd scalar y_mean=r(mean)
	estadd local strata          "Yes", replace
	estadd local stand           "Yes", replace
	
	

	reshape long fixed_choice_q , i(pid date) j(qid) 

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
	*/