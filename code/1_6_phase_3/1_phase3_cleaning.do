**************************************************
**************************************************
* Project: LD 
* Purpose: Phase 3 Cleaning  
* Author: HW took over on 2024-10-28
* Last modified: 2024-Dec-3 (HW)
**************************************************
**************************************************


******************************************************************
**# 0. What's the Difference between Original Data and HW's data
******************************************************************

	* "01_phase2_followup_survey_v1" (original dataset used to create phase 3; n = 1,902)
	* "01_phase2_followup_survey_v1" (HW uses to create phase 3; n = 2,306)
	/*
	use "$datadir/07. Phase 3/02. Output/01_phase2_followup_survey_v1.dta" , clear
	duplicates drop p1 p3 , force
	
	preserve
		use p1 p3 using "$datadir/07. Phase 3/02. Output/lss_phase2_followup_survey_v1.dta" , clear
	
		duplicates drop p1 p3 , force
		tempfile new_p3
		save `new_p3' , replace
	restore
	
	merge 1:1 p1 p3 using `new_p3',  keep(1 2 3)  
	rename p1  	pid
	rename p3 	date
	
	// HW confirms the old phase 3 dataset is a perfect subset of the new phase 3 dataset.
	
	twoway 	(histogram date if _merge==3, width(7) color(navy) frequency) ///
			(histogram date if _merge==2, width(7) color(maroon) frequency) , ///
			legend(order(1 "In both datasets" 2 "In HW's dataset only" ))
	gr export "$figures/p3_surveys_dist.pdf" , replace
	*/

*******************
**# 1.  Call data
*******************

	use "$raw/lss_phase2_followup_survey_v1.dta", clear
	// use "$datadir/07. Phase 3/02. Output/01_phase2_followup_survey_v1.dta" , clear
	rename p1 pid
	drop p0 // stand
	cap drop launchset
	merge m:1 pid using "$temp/00_mainstudy_master.dta" , keep(3) keepusing(pid stand launchset) nogen
	assert a1 == 1 // HW Oct 28: This dataset only contains surveys in which respondent is spotted.
	
	
********************	
**# 2.  Clean data 
********************
	
****	
**## Drop Useless Vars and Rename Vars
****	

	drop deviceid subscriberid simid devicephonenum username duration caseid p0_998

	rename p2 interviewer
	rename p3 date
	
	
	* HW Oct 28 2024: I assume the 10 lines of code below is correct
	// LC 27-04-2024 These are fake entries, probably to test
	drop if inlist(key, "uuid:a0af8292-440e-4c92-8ca6-48645a5254bf" , "uuid:ea8be893-4744-4f5c-867c-6088ee4b9e34")  
	// interviewer =="47. Bayas" //2 obs dropped  
	drop if key == "uuid:d5c8d9fc-1508-4b5f-85a5-e1274f965de1" //  interviewer =="48. Mohammad", 1 obs dropped
	rename a1 attend 
	replace attend=0 if a2=="He went through the stand side but didn't stayed in stand."
	drop a2 

	gen p3_followup_visit_day = 1
	label var p3_followup_visit_day "P3 follow up survey done on this date"
	
	order pid date interviewer stand
	sort pid date
	
	
****	
**## Arrival Time
****

	rename a1_2 arrival_time
	
	gen arrival_time_cleaned = regexcapture(0) if regexmatch(arrival_time, "[\d]{1,2}[\:\;\.\s]+[\d]{1,2}")
	
	replace arrival_time_cleaned = "8:51" if strpos(a1_1, "11:21:44 PM")
	replace arrival_time_cleaned = "8:00" if strpos(a1_1, "10:30:20 PM")
	replace arrival_time_cleaned = "8:00" if strpos(a1_1, "10:30:39 PM")
	replace arrival_time_cleaned = "7:40" if strpos(a1_1, "10:10:21 PM")
	replace arrival_time_cleaned = "8:40" if strpos(a1_1, "11:10:03 PM")
	replace arrival_time_cleaned = "7:05" if strpos(a1_1, "9:35:33 PM")
	replace arrival_time_cleaned = "7:50" if strpos(a1_1, "10:20:30 PM")
	replace arrival_time_cleaned = "7:00" if strpos(a1_1, "9:30:30 PM")
	replace arrival_time_cleaned = "8:31" if strpos(a1_1, "11:01:26 PM")
	replace arrival_time_cleaned = "8:40" if strpos(a1_1, "11:10:29 PM")
	replace arrival_time_cleaned = "8:01" if strpos(a1_1, "10:31:52 PM")
	replace arrival_time_cleaned = "7:52" if strpos(a1_1, "10:22:51 PM")
	replace arrival_time_cleaned = "6:01" if strpos(a1_1, "8:31:39 PM")
	
	replace arrival_time_cleaned = subinstr(arrival_time_cleaned , ":" , " ", .)
	replace arrival_time_cleaned = subinstr(arrival_time_cleaned , ";" , " ", .)
	replace arrival_time_cleaned = subinstr(arrival_time_cleaned , "." , " ", .)
	
	split arrival_time_cleaned , gen(arrival_time_)
	
	gen arrival_time_hours = real(arrival_time_1) +  real(arrival_time_2)/60
	
	assert (arrival_time_hours <= 10.5 & arrival_time_hours >= 5.5) & !mi(arrival_time_hours)
	
	
	
****
**## Drop Obs
****

	* Drop duplicates - why do we have these in the first place? if the PID is seen twice, they might have 2 entries?
	* 20 duplicates dropped
	bys pid date (arrival_time_hours) : keep if _n == 1
	duplicates list pid date 
	isid pid date 



		
***************************
**# 3.  Balance the panel
***************************

****	
**## Identify Dates by Stands
****

	levelsof stand
	local stand_levels `r(levels)'
	local all_dates_dup ""
	foreach i in `stand_levels' {
		
		local stand_`i'_dates ""
		levelsof date if stand == `i'
		local all_dates_dup "`all_dates_dup' `r(levels)'"
		foreach j in `r(levels)' {
			local stand_`i'_dates "`stand_`i'_dates', `j'"
		}
	}
	local stand_20_dates "`stand_20_dates', 22965" // One instance of all missing
		
		
****		
**## Make Panel that includes dates not spotted
****		


	keep pid date stand attend arrival_time_hours
	rename arrival_time_hours arrival_time_hours_p3
	tempfile pre_survey_dates_only
	save `pre_survey_dates_only' , replace
 
		
	foreach i in `stand_levels' {
		preserve 
			keep if stand == `i'
			
			tempfile allspot
			save `allspot' , replace
			
			* Create a huge empty panel
			use "$temp/00_mainstudy_master.dta" , clear
			keep if stand == `i'
			keep pid
			duplicates drop pid , force
			gen start_date = 22646 // Jan 1 2022
			expand 730 // 2 years, huge enough to cover all dates
			bysort pid: gen date = start_date + _n - 1

			* Restrict dates to dates in which spotted at least one person
			* (including one instance where none spotted)
			keep if inlist(date`stand_`i'_dates')

			* Merge spotted pid*dates back
			merge 1:1 pid date using  `allspot' , nogen keep(1 3)
			merge 1:1 pid date using  "$raw/05_attendance_check.dta", nogen keep(1 3) keepusing(seen arrival_time_hours)
			
			* Fill panel with absence
			replace attend = 0 if mi(attend)
			replace stand = `i' if mi(stand)
			
			
			tempfile bal_panel_`i'
			save `bal_panel_`i'' , replace 
		
		restore
	}
	
	
	drop _all
	foreach i in `stand_levels' {
		append using `bal_panel_`i'' 
	}

	tempfile survey_dates_only
	save `survey_dates_only' , replace
	
	
	/*
	collapse (mean)attend , by(pid)
	sort attend
	tab attend // 46 out of 225 never showed up on any phase 3 dates
	*/
	
	
****************************
**# 3.  Fill Natural Dates
****************************

	* I keep a panel of 224 days after the conclusion of phase 2 for each pid
	* HW: previously it's 221 days, but I added 3 more days so it's dividable by 7
	use pid launchset using "$temp/00_mainstudy_master.dta" , clear
	duplicates drop pid , force
	
	gen p2_end_date = .
	forv i = 1/$numSetsTotal {
		replace p2_end_date = ${phase2EndSet`i'} if launchset == `i'
	}
	
	
	expand 224
	bys pid : gen date = p2_end_date + _n
	keep pid date p2_end_date
	
	
	* Merge survey dates back
	merge 1:1 pid date using `survey_dates_only' , keep(1 3)
	

	
	* Fix attendance of those seen but not recorded (11 PID*Dates, 6 in stand 13 and 5 in stand 16)
	replace attend = 1 if seen == 1 
	

	
	replace arrival_time_hours_p3 = arrival_time_hours if seen == 1 
	
	replace arrival_time_hours = . if !mi(arrival_time_hours_p3)
	replace arrival_time_hours_p3 = arrival_time_hours_p3 if mi(arrival_time_hours_p3) & !mi(arrival_time_hours)
	
	drop arrival_time_hours seen
	rename arrival_time_hours_p3 arrival_time_hours
	
	assert arrival_time_hours >= 5.5 & arrival_time_hours <= 10.5 if !mi(arrival_time_hours)
	
	
*******************
**# 4. 	Save Data
*******************

	keep pid date attend arrival_time_hours
	gen phase = 3
	isid pid date 
	format %td date
	save "$temp/02_phase3_cleaned.dta", replace
	

	

/*
**************************************************
**# 5. Distribution of survey dates by launchset
**************************************************

	* In the dofile note I saw one potential reason for removing late phase 3 surveys is to remove days for wives survey that took place a long time after the end of normal phase 3. Here I also plot the survey dates of each survey that each stand was subject to. If there are outliers on far the right, we may consider removing them.
	
	foreach i in `stand_levels' {
	preserve 

		* Create a huge empty panel
		use "$temp/00_mainstudy_master.dta" , clear
		keep if stand == `i'
		keep pid
		duplicates drop pid , force
		gen start_date = 22646 // Jan 1 2022
		expand 730 // 2 years, huge enough to cover all dates
		bysort pid: gen date = start_date + _n - 1
		
		* Restrict dates to dates in which spotted at least one person 
		* (including one instance where none spotted)
		keep if inlist(date`stand_`i'_dates')
		duplicates drop date, force
		
		egen min_date = min(date)
		
		replace date = date - min_date
		gen week = date / 7
		
		format %td date
		hist week , frequency  width(1) xtitle("Week Since First Phase 3 Survey") title("Stand `i' Phase 3 Survey Dates")
		gr export "$figures/stand_`i'_dates.pdf" , replace

	restore
	}
	
	
*******************************************
**# 6. Number of data collections by date
*******************************************

	* Adding this section to help restrict date
	* Dec 17 2024
	
	clear
	set obs 1
	
	local i = 1
	foreach d in `all_dates_dup' {
		if `i' == 1 {
			gen date = `d' in 1
		}
		else {
			set obs `i'
			replace date = `d' in `i'
		}
		local i = `i' + 1
		
	}
	
	format %td date
	hist date , fraction
	gr export "$figures/p3_dates.pdf" , replace
	
	
	