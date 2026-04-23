************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Replicate the main paper analysis using HW's new dataset
* 	Author:				HW 
* 	Last modified:		2025-May-24 (HW)
************************************************************
************************************************************


*************************
**# 0. Data Preparation
*************************

	use "$datadir/Analysis Prep/02. Output/03_bs_phase123_makevar_daily_weekly_full.dta" , clear
	keep pid bl_attend bl_hiattend bl_hiattend2 bl_earn miss_bl_earn bl_modalwage ss_* bs_sum* bs_share*
	duplicates drop pid, force

	
	drop bl_hiattend bl_hiattend2
 
	replace  bs_sum_nottry = 0 if mi(bs_sum_nottry) // Make it unconditional

	* Birthplace
	tab ss_dem_birthplace , gen(ss_dem_birthplace_)
	drop ss_dem_birthplace
	drop ss_dem_district
	
	* Years in Chenni
	replace ss_dem_years_chennai = ss_dem_age if mi(ss_dem_years_chennai)
	drop ss_dem_months_chennai
	
	* Where stay
	tab ss_dem_stay , gen(ss_dem_stay_)
	drop ss_dem_stay
	drop ss_dem_stay_others

	* Own House
	tab ss_dem_ownhouse , gen(ss_dem_ownhouse_)
	drop ss_dem_ownhouse
	drop ss_dem_ownhouse_others
	
	* House Tyep
	tab ss_dem_housetype , gen(ss_dem_housetype_)
	drop ss_dem_housetype
	drop ss_dem_housetype_others
	
	* Highest Edu
	tab ss_dem_highest_edu , gen(ss_dem_highest_edu_)
	drop ss_dem_highest_edu
	drop ss_dem_highest_edu_others
	
	* Class
	replace ss_dem_class = 0 if mi(ss_dem_class)
	

	drop ss_dem_commute_cost ss_dem_cost_bike ss_dem_read_tamil ss_dem_calculation

	
	
	* Rename (c means covariate)
	rename * c_*
	rename c_pid pid
	
	save "$temp/cov_candidates.dta" , replace


	
	
*****************************
**# 1. Analysis Replication
*****************************


****
**## Figure 1: Probability of finding a job by arrival time
****

	use "$datadir/03. Baseline/02. Output/05_baseline_makevar.dta" , clear

	qui binscatter work arrival_time_hours_30 if arrival_time_hours <=10, xlabel(6(0.5)10 6.5 "6.30" 7.5 "7.30" 8.5 "8.30" 9.5 "9.30") ylabel(, nogrid) xtitle("Arrival Time") ytitle("Mean Work") line(connect) lc(maroon) mc(blue)
	
	graph export "$figures/comm_bs_attend_work_30.pdf", replace 
	
	
	
	
****
**## Figure 2: Job preferences at baseline
****	

	* 2 (a)
	use "$datadir/Analysis Prep/02. Output/03_bs_phase123_makevar_daily_weekly_full.dta" , clear
	keep if phase==0
	duplicates drop pid , force
	label define lngterm_work 1 "Least likely" 2 "Not likely" 3 `""Neither likely""or unlikely""' 4 "Likely" 5 "Very likely"  
	label value bs_dem_lngterm_work lngterm_work 

	
	qui twoway hist bs_dem_lngterm_work , lcolor(gs12) fcolor(gs12) frac xla(1/5, valuelabel) discrete width(0.5) xtitle("") 
	graph export "$figures/bs_dem_no_ltjob.pdf",replace	
	
	
	
	
	* 2 (b)
	use "$datadir/Analysis Prep/02. Output/03_bs_phase123_makevar_daily_weekly_full.dta" , clear
	duplicates drop pid , force
	
	keep pid bs_dem_no_ltjob_* 
	drop bs_dem_no_ltjob_reasons bs_dem_no_ltjob_reasons_oth

	reshape long bs_dem_no_ltjob_, i(pid) j(reason)
	collapse (mean) bs_dem_no_ltjob_, by(reason)
	
	gsort -bs_dem_no_ltjob_
	gen reason_by_popular = _n
	label define no_ltjob_lab_sorted 1 "Earn more" 2 `""Like current""profession""' 3 `""Prefer" "flexibility" "' 4 `""More free""time""' 5 `""Don't like""having boss""'  6 `""Don't have""qualifications""'  
	label value reason_by_popular no_ltjob_lab_sorted

	qui graph bar bs_dem_no_ltjob_, over(reason_by_popular, label(labsize(medium))) xsize(8) ytitle("Fraction") 
	graph export "$figures/bs_dem_no_ltjob_reasons.pdf",replace

	
	
****	
**## Figure 3: Treatment effect on attendance and arrival time in Phase 1
****

	use "$datadir/Analysis Prep/02. Output/03_bs_phase123_makevar_daily_weekly_full.dta" , clear
	
	forvalues i = 1/2 {
		ksmirnov attend_nadj if phase == `i', by(treatment)
		local pval: display %4.3f `r(p)'
		distplot attend_nadj if phase == `i', lcolor(gs12 maroon) over(treatment) ylabel(, nogrid) legend(order(1 "Control" 2 "Treatment") pos(6) row(1) region(lstyle(none))) note("K-Smirnov test p-value: `pval'") graphregion(color(white)) xtitle("Days of attendance in a week (Phase `i')")
		graph export "$figures/comm_dist_attend_nadj_p`i'.pdf", replace 
	}
	
	gen arrival_time_hours_std_daily = arrival_time_hours
  	replace arrival_time_hours_std_daily = arrival_time_hours - 0.25 if inlist(stand, ${cutoff_0815}) 
  	replace arrival_time_hours_std_daily = arrival_time_hours + 0.25 if inlist(stand, ${cutoff_0745})
  	replace arrival_time_hours_std_daily = 10 if arrival_time_hours_std_daily >= 10 & arrival_time_hours_std_daily != .

	twoway (hist arrival_time_hours_std_daily if treatment == 0 & inrange(arrival_time_hours_std_daily, 5.5, 12)  & phase == 1, lcolor(gs12) fcolor(gs12) fraction start(5.5)  width(0.25) ) || (hist arrival_time_hours_std_daily if treatment == 1 & inrange(arrival_time_hours_std_daily, 5.5, 12)  & phase == 1 , fcolor(none) lcolor(maroon) lwidth(medium) fraction   start(5.5)  width(0.25) ),legend(on row(1) label(1 "Control") label(2 "Treatment") pos(6) ring(1) ) xlabel(6(1)10) xmtick(6.5(1)10) note("*Treatment cut-off times are standardised to 8am") graphregion(color(white)) xtitle("Arrival time (observed) in fraction of hours (Phase 1)")
	 graph export "$figures/hist_arrival_time_by_treatment_p1_daily.pdf", replace

	twoway (hist arrival_time_hours_std_daily if treatment == 0 & inrange(arrival_time_hours_std_daily, 5.5, 12)  & phase == 2, lcolor(gs12) fcolor(gs12) fraction start(5.5)  width(0.25) ) || (hist arrival_time_hours_std_daily if treatment == 1 & inrange(arrival_time_hours_std_daily, 5.5, 12)  & phase == 2 , fcolor(none) lcolor(maroon) lwidth(medium) fraction   start(5.5)  width(0.25) ),legend(on row(1) label(1 "Control") label(2 "Treatment") pos(6) ring(1) ) xlabel(6(1)10) xmtick(6.5(1)10) note("*Treatment cut-off times are standardised to 8am") graphregion(color(white)) xtitle("Arrival time (observed) in fraction of hours (Phase 2)")
	 graph export "$figures/hist_arrival_time_by_treatment_p2_daily.pdf", replace
	
	
	

****	
**## Figure 5: Attendance
****
	use "$datadir/Analysis Prep/02. Output/03_bs_phase123_makevar_daily_weekly_full.dta" , clear
	gen week_modified0 = week_in
	replace week_modified0 = week_modified0 + 7 if phase == 3 | phase == 2
	replace week_modified0 = week_modified0 + 8 if phase == 3
	replace week_modified0 = 16 + floor((week_modified0 - 16) / 3) * 3 + 1 if week_modified0 > 15

	reg attend_adj i.stand i.calendar_week, vce(clu pid)
	predict attend_adj_resid1 if e(sample), resid
	

	
	binscatter attend_adj_resid1 week_modified0, by(treatment) colors(navy maroon) msymbols(O X) ///
	    xline(7.5, lpattern(dash) lcolor(black)) xline(15.5, lpattern("..--..--") lcolor(black)) ///
	    xline(0.5, lpattern(dash_dot) lcolor(black)) line(connect) legend(label(1 "Control") ///
	    label(2 "Treatment") size(small) row(1) symysize(0.75)  symxsize(5) region(lstyle(none)) ///
	    position(bottom)) ytitle("Weekly Mean Attend", size(small)) xtitle("Weeks in Phase", size(small)) ///
	    yscale(range(-1 1.5))  ///
	    xlabel(0(1)38  8 "1" 9 "2" 10 "3" 11 "4" 12 "5" 13 "6" 14 "7" 15 "8" 16 " " 17 "13" 18 " " 19 " " 20 "16" 21 " " 22 " " 23 "19" 24 " " 25 " " 26 "22" 27 " " 28 " " 29 "25" 30 " " 31 " " 32 "28" 33 " " 34 " " 35 "31" 36 " " 37 " " 38 "34" , ///
	    labsize(small) nogrid noticks) text(1.5 4 "{bf:Phase 1}", size(small)) text(1.5 11.5 "{bf:Phase 2}", size(small))  ///
	    text(1.5 20 "{bf:Phase 3}", size(small)) text(1.5 0 "{bf:BL}", size(small)) discrete

	    graph export "$figures/attend_adj_bs_p1_p2_p3_stand_calweek_v2.pdf", replace

		
		
		
****	
**## Figure 5: Attendance (With CI)
****

	use "$datadir/Analysis Prep/02. Output/03_bs_phase123_makevar_daily_weekly_full.dta" , clear
	gen week_modified0 = week_in
	replace week_modified0 = week_modified0 + 7 if phase == 3 | phase == 2
	replace week_modified0 = week_modified0 + 8 if phase == 3
	replace week_modified0 = 16 + floor((week_modified0 - 16) / 3) * 3 + 1 if week_modified0 > 15

	reg attend_adj i.stand i.calendar_week, vce(clu pid)
	predict attend_adj_resid1 if e(sample), resid
	

	tempfile attendance_temp_save
	save `attendance_temp_save' , replace
	statsby, by(week_modified0 treatment) : ci means attend_adj_resid1 , level(90)
	drop N se level 
	drop if week_modified0 > 38
	
	twoway  (connected mean week_modified0 if treatment == 1, lc(maroon) mcolor(maroon)) (rcap lb ub week_modified0 if treatment == 1, lc(maroon)) ///
			(connected mean week_modified0 if treatment == 0, lc(navy) mcolor(navy)) (rcap lb ub week_modified0 if treatment == 0, lc(navy)) , ///
			xline(7.5, lpattern(dash) lcolor(black)) ///
			xline(15.5, lpattern("..--..--") lcolor(black)) ///
			xline(0.5, lpattern(dash_dot) lcolor(black))  ///
			legend(order(1 "Treatment" 3 "Control") size(small) row(1) symysize(0.75)  symxsize(5) region(lstyle(none)) ///
			position(bottom)) ytitle("Weekly Mean Attend", size(small)) xtitle("Weeks in Phase", size(small)) ///
			yscale(range(-1 1.5))  ///
			xlabel(0(1)38  8 "1" 9 "2" 10 "3" 11 "4" 12 "5" 13 "6" 14 "7" 15 "8" 16 " " 17 "13" 18 " " 19 " " 20 "16" 21 " " 22 " " 23 "19" 24 " " 25 " " 26 "22" 27 " " 28 " " 29 "25" 30 " " 31 " " 32 "28" 33 " " 34 " " 35 "31" 36 " " 37 " " 38 "34" , ///
			labsize(small) nogrid noticks) text(1.5 4 "{bf:Phase 1}", size(small)) text(1.5 11.5 "{bf:Phase 2}", size(small))  ///
			text(1.5 20 "{bf:Phase 3}", size(small)) text(1.5 0 "{bf:BL}", size(small))
			
	
			
	    graph export "$figures/attend_adj_bs_p1_p2_p3_stand_calweek_v2_ci.pdf", replace
		
		

			
****		
**## Figure 6: Treatment effect on morning routines during Phase 2
****
		
		
**### Panel A

	use "$datadir/Analysis Prep/02. Output/03_bs_phase123_makevar_daily_weekly_full.dta" , clear
	keep if !mi(r_reg_morning_act_water)
	
	
	reshape long r_reg_morning_act_, i(pid) j(activities) string
	collapse (mean) r_reg_morning_act_, by(activities treatment)	
	
		gen bord = 1 if activities == "water"
		replace bord = 2 if activities == "cook_breakf"
		replace bord = 3 if activities == "eat_breakf"
		replace bord = 4 if activities == "help_kids"
		replace bord = 5 if activities == "drop_kids"
		replace bord = 6 if activities == "wash"
		replace bord = 7 if activities == "pray"
		replace bord = 8 if activities == "shopping"
		replace bord = 9 if activities == "998"


	twoway (bar r_reg_morning_act_ bord if treatment == 0,  lcolor(gs12) fcolor(gs12)) || ///
      (bar r_reg_morning_act_ bord if treatment == 1, fcolor(none) lcolor(maroon)), ///
      xlabel(1 `" "Get" "water" "' 2 `" "Cook" "breakfast" "' 3 `" "Eat" "breakfast" "' 4 `" "Help get" "kids ready" "' 5 `" "Drop kids" "at school" "' 6 "Wash/bathe" 7 `" "Temples/" "prayers" "' 8 `" "Go to the" "store/shop" "' 9 "Others", noticks labsize(small)) ///
      xtitle("") ytitle("Percent of respondents selecting each option") legend(order(1 "Control" 2 "Treatment") pos(6) row(1))
	graph export "$figures/bar_morning_activities_low_att.pdf", replace
	
	
**### Panel B
	
	use "$datadir/Analysis Prep/02. Output/03_bs_phase123_makevar_daily_weekly_full.dta" , clear
	keep if !mi(r_morning_alarm)
	
	graph bar (mean)r_morning_alarm, over(treatment) asyvars ///
	bar(1, fcolor(gs12) lcolor(gs12)) ///
	bar(2, fcolor(none) lcolor(maroon)) ///
	ytitle("Share of respondents") ///
	yscale(range(0 0.5)) ///
	legend(order(1 "Control" 2 "Treatment") row(1) position(bottom))

    graph export "$figures/bars_use_alarm.pdf", replace
		
		
		
		
****
**## Days Show Up Figure in Slides
****

	use "$datadir/03. Baseline/02. Output/05_baseline_makevar.dta", clear // HW's version
	
	use "~/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/02. Cleaning Data/03. Baseline/02. Output/05_baseline_makevar.dta" , clear // Original version

	* weekly attendance
	gen bs_sum_attend_weekly = (bs_sum_attend/11)*6
	duplicates drop pid , force 

	tab bs_sum_attend_weekly

	* 885 PIDs in this baseline sample.
	qui twoway hist bs_sum_attend_weekly , fraction start(0) xlabel(0(1)6) xmtick(0(1)6) graphregion(color(white)) xtitle("Days attended stand per week (baseline)") bin(12) lcolor(gs8) fcolor(gs12)
	graph export "$figures/hist_bs_sum_attend_weekly.pdf", replace
		

****
**# Table 2: Labor Supply Effects
****



	* Note: sample size here is 1572 and not 1575 because 3 PIDs got late announcements in week 2, so week 1 data is missing

	use "$datadir/Analysis Prep/02. Output/03_bs_phase123_makevar_daily_weekly_full.dta", clear
	lab var work1_nadj	"Work, Mean Impute"
	lab var work_nadj	"Work, Rand Impute"



	gen  temp1 = work_orig if recall_reliable == 1
  	egen temp2 = total(temp1) , by(pid phase week_in) missing
  	egen work1_wkly2 = max(temp2), by(pid phase week_in)
  	drop temp*
	
	
**### Actual Regression
	
	
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


	 
	* 2024-05-02 new version for slides, changing order 
	esttab b1 a1 b2 a2 d2 using "$tables/com_weekly_attend_b8_attend_work1_frag2_rephw.tex",  ///
	replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
	stats( y_mean N, labels("Control mean" "N: worker-weeks")) collabels(none) ///
	nonotes nonumbers mtitles("By 8" "Attend" "By 8" "Attend" "Work") nostar booktabs ///
	mgroups("Phase 1" "Phase 2" , pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
  
  
  

	
**### Robustness

	merge m:1 pid using "$temp/cov_candidates.dta" , keep(1 2 3) nogen

	
	
	foreach ourcome of varlist attend_nadj attend_and_before8_nadj {

		dsregress `ourcome' treatment if phase==1 , controls(c_*) vce(cluster pid)
		local controls_treat = e(controls_sel)
		di "`controls_treat'"
		eststo clear 
		eststo: reg `ourcome' treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
		eststo: reg `ourcome' treatment i.stand i.strata if phase==1  , vce(cluster pid)
		eststo: reg `ourcome' treatment attend_week  i.stand i.strata i.week_in i.calendar_week if phase==1  , vce(cluster pid)
		eststo: reg `ourcome' treatment attend_week  i.stand i.strata i.week_in i.calendar_week `controls_treat' if phase==1  , vce(cluster pid)
		eststo: reg `ourcome' treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week `controls_treat' if phase==1  , vce(cluster pid)


		esttab using "$tables/com_weekly_p1_`ourcome'_rephw.tex",  ///
		replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
		stats(N, labels("N: worker-weeks")) collabels(none) ///
		nonotes nonumbers mtitles("Paper" "Strata" "Stata+Survey FE" "Stata+Survey+PDL" "Paper + PDL") nostar booktabs 
		eststo clear 
	}
	
	
	
	
	foreach ourcome of varlist attend_nadj attend_and_before8_nadj work1_wkly2 {

		dsregress `ourcome' treatment if phase==2 , controls(c_*) vce(cluster pid)
		local controls_treat = e(controls_sel)
		di "`controls_treat'"
		
		eststo clear 
		eststo: reg `ourcome' treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
		eststo: reg `ourcome' treatment i.stand i.strata if phase==2  , vce(cluster pid)
		eststo: reg `ourcome' treatment attend_week  i.stand i.strata i.week_in i.calendar_week if phase==2  , vce(cluster pid)
		eststo: reg `ourcome' treatment attend_week  i.stand i.strata i.week_in i.calendar_week `controls_treat' if phase==2  , vce(cluster pid)
		eststo: reg `ourcome' treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week `controls_treat' if phase==2  , vce(cluster pid)


		esttab using "$tables/com_weekly_p2_`ourcome'_rephw.tex",  ///
		replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
		stats(N, labels("N: worker-weeks")) collabels(none) ///
		nonotes nonumbers mtitles("Paper" "Strata" "Stata+Survey FE" "Stata+Survey+PDL" "Paper + PDL") nostar booktabs 
		eststo clear 
	}
	
	
	
***************************************
**# Table 3: Shocks Erode Habit Stock
***************************************
	
	
	use "$datadir/Analysis Prep/02. Output/03_bs_phase123_makevar_daily_weekly_full.dta" , clear
	egen standid = group(stand)
	gen treat = treatment
	
	local use_original = 0
	if `use_original' == 1{
	use "$original_main" , clear
	gen treat = treatment
	egen standid = group(stand)
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
	}
	  
	  
	gen treatXweek_in = treatment*week_in
	gen treatXpostweek5 = treatment*(week_in>=5)
	
	
	reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment if phase<2	
	predict resid_day_attendph2 if phase==2, residuals
	
	
	sort standid phase calendar_week date pid
	by standid phase calendar_week: gen stand_ph_calweek_id1 = 1 if _n==1
	egen temp2 = seq() if stand_ph_calweek_id1 == 1, by(standid phase)
	egen stand_ph_calweek = max(temp2), by(standid phase calendar_week)
	gen treatXstand_ph_calweek = treatment*stand_ph_calweek
	drop temp*
	
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

	
	  esttab 	using "$tables/shocks_attendloo_b25.tex" , se ///
				keep(	treat treatXweek_in_dm treatXpostweek5 treatXpost_attendloo_b25 treatXattendloo25_post1 ///
						treatXattendloo25_post2p treatXweek_in_dm) ///
				order(	treat treatXpost_attendloo_b25 treatXattendloo25_post1 ///
						treatXattendloo25_post2p treatXpostweek5 treatXweek_in_dm ) ///
				nostar l cells(b(fmt(a3)) se(fmt(3) par) pval(fmt(3) par("[" "]") pvalue(pval))) nonotes  ///
				starlevels(* 0.10 ** 0.05 *** .01) ///
				stats(weekin calweek N, labels("Week in phase FE" "Calendar Week FE" "N: worker-weeks")) ///
				replace collabels(none) frag gaps nomtitles 
				
				
	  esttab 	using "$tables/shocks_attendloo_b25_p.tex" , se ///
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

	reshape long fixed_choice_q , i(pid date) j(qid) 

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

	esttab using "$tables/flex_fixed_choice_attendloo_b25.tex" , se(3) replace keep(treat treatXpost_attendloo_b25) stats(y_mean N, labels("Control mean" "N: worker-question"))  l nonotes  cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) nostar collabels(none) nonum mtitles("\shortstack{Fixed choice\\ No Weight}" "\shortstack{Fixed choice\\ Weighted}" "\shortstack{Fixed choice\\ Weighted}" "\shortstack{Fixed choice\\ No Weight}") booktabs style(tex)
	
	eststo clear 
	
	
	
******************	
**# Robust Check
******************

	use "$datadir/Analysis Prep/02. Output/03_bs_phase123_makevar_daily_weekly_full.dta" , clear 
	
	eststo clear 


	forval i = 1/32 {
		eststo c`i': reg attend_adj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==3 & week_in <= `i' , vce(cluster pid)
		sum attend_adj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)
	}
	
	
	use "$dir/original_main_data.dta" , clear
	eststo c1o: reg attend_nadj treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.stand i.strata i.week_in i.calendar_week if phase==3  , vce(cluster pid)
	sum attend_nadj if treatment==0 & e(sample)
	estadd scalar y_mean=r(mean)

	use "$datadir/Analysis Prep/02. Output/03_bs_phase123_makevar_daily_weekly_full.dta"
	lab var work1_nadj	"Work, Mean Impute"
	lab var work_nadj	"Work, Rand Impute"
 
	esttab c32 c8 c12 c16 c1o using "$tables/com_weekly_attend_phase3.tex",  replace keep(treatment) cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) stats( y_mean N, labels("Control mean" "N: worker-weeks")) nonotes  nonumbers nostar style(tex) booktabs mtitles("Attend (All Weeks)" "Attend ($\le$8 WK)" "Attend ($\le$12 WK)" "Attend ($\le$16 WK)" "Attend (Original Data, nadj)") 
	
	estimates drop c1o
	
	coefplot * , keep(treatment) yline(0) legend(off) vertical xtitle("Threshold 1-32 weeks (32 weeks in total)") xlabel("") ylabel(#40)  ytitle("Treatment Coefficient and 95% CI")
	gr export "$figures/p3_threshold.pdf" , replace
	eststo clear 
	
	
	
	
	forval i = 4/32 {
		eststo c`i': reg attend_adj treatment attend_week bl_attend bl_earn miss_bl_earn i.stand i.strata i.week_in i.calendar_week if phase==3 & week_in <= `i' & week_in > 3 , vce(cluster pid)
		sum attend_adj if treatment==0 & e(sample)
		estadd scalar y_mean=r(mean)
	}
		
	
	coefplot * , keep(treatment) yline(0) legend(off) vertical xtitle("Threshold 4-32 weeks, first 3 weeks dropped") xlabel("") ylabel(#20)  ytitle("Treatment Coefficient and 95% CI")
	gr export "$figures/p3_threshold_drop3.pdf" , replace
	
	
	eststo clear 
	
	
**# Employer Survey

	use "$datadir/08. Others/02. Output/Employers Survey/ls_employers_survey_combined.dta" , clear
	

	graph bar, over(comb_10day_contract_absent_days, label(labsize(medium))) b1title(Number of days,size(medium)) yla(,labsize(*1.3)) ytitle("Percent",size(medium)) 
	graph export "$figures/workers_days_off_10.pdf",replace
	
	
	
	
	
**# Treatment Effect on Reliable Recall

	use "$datadir/Analysis Prep/02. Output/03_bs_phase123_makevar_daily_weekly_full.dta" , clear



	
	
	ttest recall_reliable , by(treatment)



recall_reliable  recall_source


	
***************
**# Multi-Day
***************

	use "$temp/baseline_multiday_final.dta" , clear
	foreach i of varlist num_spells_uncond-mean_type_7_uncond {
		rename `i' b_`i'
	}
	merge 1:m pid using "$temp/p1p2_multiday_final.dta" , keep(1 2 3) nogen
	merge m:1 pid using "$datadir/Analysis Prep/02. Output/00_mainstudy_master.dta"  , keepusing(strata stand launchset) keep(3) nogen
	lab var treatment "Treatment"

	eststo clear
	foreach i of varlist  any_spells num_spells_uncond num_days_uncond num_days_cond mean_type_3_uncond sum_type_3 {
		eststo : reg `i' treatment b_`i' i.strata i.stand i.launchset if phase == 1 , r
		sum `i' if treatment == 0 & e(sample)
		local c_mean = trim("`: display %9.3f `r(mean)''")
		local c_sd = trim("`: display %9.3f `r(sd)''")
		loc treat = _b[treatment]
		loc teffect = 100*(`treat'/`r(mean)')
		local t_effect = trim("`: display %9.3f `teffect''")
		local c_mean = subinstr(`"`c_mean'"',"0.",".",.)
		local c_sd = subinstr(`"`c_sd'"',"0.",".",.)
		local t_effect = subinstr(`"`t_effect'"',"0.",".",.)
		estadd local	c_mean 		`c_mean'
		estadd local	c_sd 		`c_sd'
		estadd local 	t_effect 	`t_effect'
	}

	esttab using "$tables/multiday_treatment_effects_phase1.tex", ///
		replace keep(treatment) ///
		cells(b(fmt(a3)) se(fmt(3) par)) ///
		stats(c_mean c_sd t_effect N, ///
			labels("Control mean" "Control SD" "Treatment effect (\%)" "Observations") ///
			fmt(%9.3f %9.3f %9.3f %9.0fc)) ///
		mtitles("Any MDS Spells" "Number MDS" "Num MDS Days (uncond.)" "Num MDS Days (cond.)" "Prop. Impossible MDS (uncond.)" "Num Impossible MDS") ///
		nonotes nonumbers booktabs  ///
		collabels(none) style(tex)

	eststo clear


	eststo clear
	foreach i of varlist  any_spells num_spells_uncond num_days_uncond  num_days_uncond num_days_cond mean_type_3_uncond sum_type_3 {
		eststo : reg `i' treatment b_`i' i.strata i.stand i.launchset if phase == 2 , r
		sum `i' if treatment == 0 & e(sample)
		local c_mean = trim("`: display %9.3f `r(mean)''")
		local c_sd = trim("`: display %9.3f `r(sd)''")
		loc treat = _b[treatment]
		loc teffect = 100*(`treat'/`r(mean)')
		local t_effect = trim("`: display %9.3f `teffect''")
		local c_mean = subinstr(`"`c_mean'"',"0.",".",.)
		local c_sd = subinstr(`"`c_sd'"',"0.",".",.)
		local t_effect = subinstr(`"`t_effect'"',"0.",".",.)
		estadd local	c_mean 		`c_mean'
		estadd local	c_sd 		`c_sd'
		estadd local 	t_effect 	`t_effect'
	}


	esttab using "$tables/multiday_treatment_effects_phase2.tex", ///
		replace keep(treatment) ///
		cells(b(fmt(a3)) se(fmt(3) par)) ///
		stats(c_mean c_sd t_effect N, ///
			labels("Control mean" "Control SD" "Treatment effect (\%)" "Observations") ///
			fmt(%9.3f %9.3f %9.3f %9.0fc)) ///
		mtitles("Any MDS Spells" "Number MDS" "Num MDS Days (uncond.)" "Num MDS Days (cond.)" "Prop. Impossible MDS (uncond.)" "Num Impossible MDS") ///
		nonotes nonumbers booktabs  ///
		collabels(none) style(tex)

	eststo clear