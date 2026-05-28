************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Replicate the main paper analysis using HW's new dataset
* 	Author:				HW 
* 	Last modified:		2026-May-22 (HW)
************************************************************
************************************************************

**************************************************
**# Define Basleine Covariates for Original Data
**************************************************

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

************************************************************
**# Figure 1: Probability of finding a job by arrival time
************************************************************

	* HW confirmed this works for both original and new data (Apr 17, 2026)

	use "$main_data" , clear
	cap gen arrival_time_hours_30 = .
	forvalues i =  6/10 {
	  replace arrival_time_hours_30 = `i' if arrival_time_hours < `i'.5 & arrival_time_hours_30 == . & phase == 0
	  replace arrival_time_hours_30 = `i'.5 if arrival_time_hours < `i'+1  & arrival_time_hours_30 == . & phase == 0
	}
	binscatter work arrival_time_hours_30 if arrival_time_hours <=10 & phase == 0, xlabel(6(0.5)10 6.5 "6.30" 7.5 "7.30" 8.5 "8.30" 9.5 "9.30") ylabel(, nogrid) xtitle("Arrival Time") ytitle("Mean Work") line(connect) lc(maroon) mc(navy) yscale(range(0.4 0.8))
	graph export "$figures/comm_bs_attend_work_30.pdf", replace
	
*********************************************************************
**# Figures 2-3: Attendance and arrival time in Phase 1 and Phase 2
*********************************************************************

	* HW confirmed this works for both original and new data (May 22, 2026)

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

	* HW confirmed this works for both original and new data (May 22, 2026)

	use "$main_data" , clear


****
**## Original Version
****

if "$data_version" == "original" {
	gen week_modified0 = week_in_bs_p1_p2_p3
	replace week_modified0 = 16 + floor((week_in_bs_p1_p2_p3 - 16) / 3) * 3 + 1 if week_in_bs_p1_p2_p3 > 15

 
  	reg attend_adj i.stand i.calendar_week, vce(clu pid)
	predict attend_adj_resid1 if e(sample), resid

  // Present attendance over time by treatment group for each week
  	binscatter attend_adj_resid1 week_modified0, by(treatment) colors(navy maroon) msymbols(O X) ///
	xline(7.5, lpattern(dash) lcolor(black)) xline(15.5, lpattern("..--..--") lcolor(black)) ///
	xline(0.5, lpattern(dash_dot) lcolor(black)) line(connect) legend(label(1 "Control") ///
	label(2 "Treatment") size(small) row(1) symysize(0.75)  symxsize(5) region(lstyle(none)) ///
	position(bottom)) ytitle("Weekly Mean Attend", size(small)) xtitle("Weeks in Phase", size(small)) ///
	yscale(range(-1 1.5)) ylabel(none) ///
	xlabel(0(1)27  8 "1" 9 "2" 10 "3" 11 "4" 12 "5" 13 "6" 14 "7" 15 "8" 16 " " 17 "13" 18 " " 19 " " 20 "16" 21 " " 22 " " 23 "19" 24 " " 25 " " 26 "22" 27 " ", ///
	labsize(small) nogrid noticks) text(1.5 4 "{bf:Phase 1}", size(small)) text(1.5 11.5 "{bf:Phase 2}", size(small))  ///
	text(1.5 20 "{bf:Phase 3}", size(small)) text(1.5 0 "{bf:BL}", size(small))

	graph export "$figures/attend_adj_bs_p1_p2_p3_stand_calweek_v2.pdf", replace

}



if "$data_version" == "new" {
****
**## New Version
****

	* Every 2 weeks (except 3 weeks once in phase 1 b/c 7 in total) in P1 and P2, every month in P3
	gen bins1 = . 
	replace bins1 = 0 if week_in == 0 | phase == 0
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

	* Gen baseline covariates for original dataset
	gen_bl_cov

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

}





*******************************************************************
**# Figure 5: Treatment effect on morning routines during Phase 2
*******************************************************************

	* HW confirmed this works for both original and new data (May 22, 2026)
	* Actually this is independent of the main dataset


****
**## (a) Activities done in the morning between 5.30am to 9am
****

	use "$temp/03a_phase2act_vignettes_makevar_hw.dta", clear
	keep r_reg_morning_act_* pid

	merge 1:1 pid using "$temp/00_mainstudy_master.dta"  , keep(3) nogen keepusing(treatment)

	reshape long r_reg_morning_act_, i(pid) j(activities) string

	tempfile morning_act_data
	save `morning_act_data' , replace
	statsby, by(activities treatment) : ci means r_reg_morning_act_


	gen bord = 1 if activities == "water"
		replace bord = 2 if activities == "cook_breakf"
		replace bord = 3 if activities == "eat_breakf"
		replace bord = 4 if activities == "help_kids"
		replace bord = 5 if activities == "drop_kids"
		replace bord = 6 if activities == "wash"
		replace bord = 7 if activities == "pray"
		replace bord = 8 if activities == "shopping"
		replace bord = 9 if activities == "oth"


	twoway ///
		(bar mean bord if treatment == 0, lcolor(gs12) fcolor(gs12)) || ///
		(bar mean bord if treatment == 1, fcolor(none) lcolor(maroon)) || ///
		(rcap lb ub bord if treatment == 0, lc(gs8)) || ///
		(rcap lb ub bord if treatment == 1, lc(maroon)) , ///
		xlabel(1 `" "Get" "water" "' 2 `" "Cook" "breakfast" "' 3 `" "Eat" "breakfast" "' 4 `" "Help get" "kids ready" "' 5 `" "Drop kids" "at school" "' 6 "Wash/bathe" 7 `" "Temples/" "prayers" "' 8 `" "Go to the" "store/shop" "' 9 "Others", noticks labsize(small)) ///
		xtitle("") ytitle("Percent of respondents selecting each option") legend(order(1 "Control" 2 "Treatment") pos(6) row(1))


	graph export "$figures/bar_morning_activities_low_att.pdf", replace
	

****
**## (b) Usage of an alarm to wake up in the morning
****

	use "$temp/03a_phase2act_vignettes_makevar_hw.dta", clear
	keep r_morning_alarm pid
	merge 1:1 pid using "$temp/00_mainstudy_master.dta"  , keep(3) nogen keepusing(treatment)

	statsby, by(treatment) clear: ci mean r_morning_alarm

	twoway ///
		(bar mean treatment if treatment == 0 , fcolor(gs12) lcolor(gs12) ) || ///
		(bar mean treatment if treatment == 1 , fcolor(none) lcolor(maroon)) || ///
		(rcap lb ub treatment if treatment == 0, lc(gs8)) || ///
		(rcap lb ub treatment if treatment == 1, lc(maroon)) , ///
		xlabel("") xsc(range(-.75 1.75)) ///
		ytitle("Share of respondents") ylabel(0(0.1)0.5) ///
		legend(order(1 "Control" 2 "Treatment") pos(6) row(1)) ///
		xtitle("")


	graph export "$figures/bars_use_alarm_low_att.pdf", replace



*******************************************
**# Figure 6: Job preferences at baseline
*******************************************


****
**## (a) Likelihood of accepting a long-term, formal job if offered one
****

	use "$main_data" , clear
	drop if mi(bs_dem_lngterm_work)
	keep pid bs_dem_lngterm_work
	duplicates drop pid, force

	label define lngterm_work 1 "Least likely" 2 "Not likely" 3 `""Neither likely""or unlikely""' 4 "Likely" 5 "Very likely"  
	label value bs_dem_lngterm_work lngterm_work 

	qui twoway hist bs_dem_lngterm_work, lcolor(gs12) fcolor(gs12) frac xla(1/5, valuelabel) discrete width(0.5) xtitle("") 

	graph export "$figures/bs_dem_no_ltjob.pdf", replace



****
**## (b) Characteristics of casual jobs found at the stands most appreciated by participants
****

	use "$main_data" , clear
	drop if mi(bs_dem_no_ltjob_reasons)
	keep pid bs_dem_no_ltjob_reasons
	duplicates drop pid, force

	forval i = 1/6 {
		gen bs_dem_no_ltjob_reasons_`i' = strpos(bs_dem_no_ltjob_reasons, string(`i')) > 0
	}
	reshape long bs_dem_no_ltjob_reasons_ , i(pid) j(reason)

	lab define reason 1 `""Prefer" "flexibility" "' 2 "Earn more" 3 `""Like current""profession""' 4 `""More free""time""' 5 `""Don't like""having boss""' 6 `""Don't have""qualifications""' , replace
	lab val reason reason

	collapse bs_dem_no_ltjob_reasons_ , by(reason)

	graph bar bs_dem_no_ltjob_reasons_, over(reason, sort(1) descending label(labsize(medium))) bar(1, color(gs12)) xsize(8) ytitle("Fraction")

	gr export "$figures/bs_dem_no_ltjob_reasons.pdf", replace 




********************************************
**# Figure 7: Predicted Worker Absenteeism
********************************************

	if "$data_version" == "original" {

		use "$ld_dir/07. Data/3. Main Study 3.0/02. Cleaning Data/08. Others/02. Output/Employers Survey/02_employer_survey_cleaned.dta", clear
		keep if p5 == 1

		replace b9 = k5 if p5 == 2

		graph bar, over(b9, label(labsize(medium))) b1title(Number of days,size(medium)) yla(,labsize(*1.3)) ytitle("Percent",size(medium)) bar(1, color(gs12))

		graph export "$figures/workers_days_off_10.pdf",replace

	}

	if "$data_version" == "new" {
		
		use "$final/ls_employers_survey_combined.dta", clear
		graph bar, over(rec_10day_contract_absent_days, label(labsize(medium))) b1title(Number of days,size(medium)) yla(,labsize(*1.3)) ytitle("Percent",size(medium)) bar(1, color(gs12))

		graph export "$figures/workers_days_off_10.pdf",replace

	}


*******************************************
**# Figure 8: Costs incurred by employers
*******************************************



  	use "$ld_dir/07. Data/3. Main Study 3.0/02. Cleaning Data/08. Others/02. Output/Employers Survey/02_employer_survey_cleaned.dta", clear


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

	graph bar response_, over(choice, label( labsize(medium))) xsize(8) ytitle("Fraction of recruiter responses") bar(1, color(gs12))
	graph export "$figures/emp_resp_c7_n7.pdf",replace
	restore 

**## Histogram - Replacement duration 
	* these questions were only asked to recruiters 

	keep if p5==1 // only recruiters
	
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

**## Histogram - Training - time taken to onboard a new worker

	* How much time do you typically spend helping a new worker understand what needs to be done and how to do it?
	gen d1_b_coded= 1 if d1_b_<30
	replace d1_b_coded= 2 if d1_b_>=30 & d1_b_<60
	replace d1_b_coded= 3 if d1_b_>=60 

	qui twoway (hist d1_b_coded  if worker_skill==1, lcolor(gs12) fcolor(gs12) width(1) fraction start(1) width(1) discrete) || ///
      (hist d1_b_coded if worker_skill==2, fcolor(none) lcolor(maroon) width(1) lwidth(medium) fraction  start(1) width(1) discrete), ///
      xtitle("Duration") ytitle("Fraction of recruiter responses",size(medium)) yla(,labsize(*1.3)) legend( label(1 "Unskilled") label(2 "Skilled") ///
        pos(2) ring(0) region(lcolor(black)) )xlabel(1 "<30 mins" 2 "30-90 mins" 3 ">90 mins", labsize(medium))









	use "$final/ls_employers_survey_combined.dta", clear
	keep recruiter_id comb_relay_worker_hiring_change

	forval i = 1/7 {
		gen response_`i' = strpos(comb_relay_worker_hiring_change, "`i'") > 0
	}
	

	reshape long response_, i(recruiter_id) j(choice)
	collapse (mean) response_, by(choice)

	label define empresp_lab 1 `""Provide" "training" "' 2 "Insurance" 3 `""Change biz""type""' 4 `""Expand""business""' 5 "In-kind gifts"  6 "Loans"  7 "School fees"
	label value choice empresp_lab 

	graph bar response_, over(choice, label( labsize(medium))) xsize(8) ytitle("Fraction of recruiter responses") bar(1, color(gs12))
	graph export "$figures/emp_resp_c7_n7.pdf",replace























***********************************
**# Table 1: Labor Supply Effects
***********************************

	* Note: sample size here is 1572 and not 1575 because 3 PIDs got late announcements in week 2, so week 1 data is missing

	use "$main_data" , clear
	lab var work1_nadj	"Work, Mean Impute"
	lab var work_nadj	"Work, Rand Impute"

	if "$data_version" == "original" {

		egen temp = min(work_recall_mode), by(pid phase week_in)
		gen work_recall_mode_any1 = (temp==1)
		drop temp
	
		gen temp1 = (recall_length<=7) /* will=1 if recall < 7 days ago & work not missing */
		egen grid_recall_anyinwk = max(temp1), by(pid phase week_in)
		drop temp*
		
		gen temp1 = work1 if recall_length<=7 & work_recall_mode==1
		egen temp2 = total(temp1) if grid_recall_anyinwk==1 & work_recall_mode_any1==1, by(pid phase week_in)
		egen work1_wkly2 = max(temp2), by(pid phase week_in)
		drop temp*

	}

	if "$data_version" == "new" {

		gen  temp1 = work_orig if recall_reliable == 1
		egen temp2 = total(temp1) , by(pid phase week_in) missing
		egen work1_wkly2 = max(temp2), by(pid phase week_in)
		drop temp*

	}


	* Gen baseline covariates for original dataset
	gen_bl_cov
	
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
	if "$data_version" == "original" {
		reg attend bl_attend standid##phase##treat if phase<2
	}
	else {
		reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment if phase<2	
	}
	predict resid_day_attendph2 if phase==2, residuals

	reg attend bl_attend bl_earn miss_bl_earn i.standid##i.treatment if phase<2	
	predict resid_day_attendph3 if phase==2, residuals



	reg attend i.phase if phase<2	
	predict resid_day_attendph4 if phase==2, residuals



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
		gen double avg_wkattend_loo = (sw_mean - w_mean) / (sw_n - w_n)
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
	eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
	
	wildbootstrap regress attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, cluster( standid)
	
	// {treat} {treatXpost_attendloo_b25}
	
	boottest {treat} {treatXpost_attendloo_b25} //, seed(123) reps(2048) boottype(wild) nograph 
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
// 	boottest {treat} {treatXpost_attendloo_b25} {treatXweek_in_dm}, seed(123) reps(2048) boottype(wild) nograph 
	
	wildbootstrap regress attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, cluster( standid)
	
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
// 	reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
//	
	wildbootstrap regress  attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p  week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, cluster( standid)
	
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
				nostar l cells(b(fmt(3)) se(fmt(3) par) pval(fmt(3) par("[" "]") pvalue(pval))) nonotes  ///
				starlevels(* 0.10 ** 0.05 *** .01) ///
				stats(weekin calweek N, fmt(0 0 0) labels("Week in phase FE" "Calendar Week FE" "N: worker-weeks")) ///
				replace collabels(none) frag gaps nomtitles 
				
	
	eststo clear


	


	use "$ld_dir/07. Data/3. Main Study 3.0/02. Cleaning Data/08. Others/02. Output/Time Use/03-time-use-makepanel.dta", clear 
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



	eststo: reg tu_jfp_8am treatment i.stand i.strata i.date if phase==2 , cl(pid)
	estadd local bl_jfp "No", replace
	estadd local surveydate "Yes", replace
	sum tu_jfp_8am if e(sample) & treatment==0
	estadd scalar y_mean=r(mean)



	label var tu_jfp_8am "Days"
	label var treatment "Treatment"
	esttab using "$tables/tu_jfp_8am_short.tex" , se keep(treatment) nostar l cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) nonotes starlevels(* 0.10 ** 0.05 *** .01) stats(surveydate y_mean N, labels("Survey date FE" "Control mean" "N: worker-survey")) replace collabels(none) frag gaps






***********************************************
**# Table 6: Willingness to Forgo Flexibility
***********************************************

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


***********************************************
**# Table 4: Automaticity: Change in Psychological Default
***********************************************

**## Automaticity: Change in psychological default
 	use "$ld_dir/07. Data/3. Main Study 3.0/02. Cleaning Data/06a. Phase 2 Activities/02. Output/03a_phase2act_vignettes_makevar.dta", clear
  isid pid //data is at the pid level 
  ta phase if miss_vignette!=1, m // we had a few surveys done outside of phase 2
  merge 1:1 pid date phase using "$ld_dir/07. Data/3. Main Study 3.0/02. Cleaning Data/Analysis Prep/02. Output/temp_shocks.dta"
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




