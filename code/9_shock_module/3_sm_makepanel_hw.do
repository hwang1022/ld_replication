**************************************************
*	Project: LD Main Study
*	Purpose: Shock Module Make Panel
*	Author: HW 
*	Last modified: Oct-4-2024 (HW)
**************************************************


***************
**# Load Data
***************

	use "$temp/02_shock_module_cleaned_hw.dta" , clear
	
	
****************	
**# Glossaries
****************

	* Covered Period
		* This is the time window covered by one survey
		* By default it is 14 days. However in some cases if the start of a recall event 
		* happended a bit earlier than 14 days before, or that a event will end after 
		* the date of interview. In this case we extend the Covered Period
		
		* Any date outside of the covered period is unknown
		* We cannot tell if there were an events
		
		

	
***********************
**# MakePanel Options
***********************
	
	* Min number of consequetive unknown days for them to be treated as unknown
	* Intuition is that if there's only 1 or 2 days betwwen the covered periods of two surveys,
	* people will usually report if anything happened within this gap.
	
	global min_conseq_unknown_day = 4 // 56 days affected
	assert $min_conseq_unknown_day >= 1 // Need to be at least 1
	
	

	
******************************************
**# Identify Maximun Possible Date Range
******************************************

	
	preserve
		egen max_date = rowmax(date invited_startdate1 invited_enddate1 invited_startdate2 invited_enddate2 happened_startdate1 happened_enddate1)
		egen min_date = rowmin(date invited_startdate1 invited_enddate1 invited_startdate2 invited_enddate2 happened_startdate1 happened_enddate1)
		
		qui sum max_date 
		global maxdate = `r(max)'
		
		qui sum min_date 
		global mindate = `r(min)'
	
	restore
	
	
*****************************
**# Focus on Invited Events
*****************************


****
**## Make Panel
****

	keep 	pid date invited_name1 invited_days1 invited_startdate1 invited_enddate1 invited_location1 invited_attend1 invited_back_date1 invited_pressure1 ///
			invited_name2 invited_days2 invited_startdate2 invited_enddate2 invited_location2 invited_attend2 invited_back_date2 invited_pressure2
	sort pid date
			
			
	* Gen helpful variable to later restrict sample to periods coevered by the survey
	* I.e. 14 days before the survey. Extend a few days if start and end dates falls out of the period
	gen survey_covered_date_start = date - 14
	format survey_covered_date_start %td
	replace survey_covered_date_start = invited_startdate1 if invited_startdate1 < survey_covered_date_start
	replace survey_covered_date_start = invited_startdate2 if invited_startdate2 < survey_covered_date_start
	
	
	gen survey_covered_date_end = date
	format survey_covered_date_end %td
	replace survey_covered_date_end = invited_enddate1 if invited_enddate1 > survey_covered_date_end & !mi(invited_enddate1)
	replace survey_covered_date_end = invited_back_date1 if invited_back_date1 > survey_covered_date_end & !mi(invited_back_date1)
	replace survey_covered_date_end = invited_enddate2 if invited_enddate2 > survey_covered_date_end & !mi(invited_enddate2)
	replace survey_covered_date_end = invited_back_date2 if invited_back_date2 > survey_covered_date_end & !mi(invited_back_date2)
	
	gen survey_dates_covered = survey_covered_date_end - survey_covered_date_start + 1
	bys pid (date): gen survey_order = _n
	

	
	
	* Reshape
	tempvar pid_date
	egen `pid_date' = group(pid date)
	reshape long invited_name invited_days invited_startdate invited_enddate invited_location invited_attend invited_back_date invited_pressure, i(`pid_date') j(invited_number)
	
	* Drop harmless empty entries
	drop if invited_number == 2 & mi(invited_name)
	
	
	
	drop invited_number
	bys pid (invited_startdate) : gen invited_number = _n if !mi(invited_name)
	order invited_number , after(pid)
	

	
	* Make Panel
	// keep  pid survey_covered_date_start invited_number invited_name invited_days invited_startdate invited_enddate invited_location invited_attend invited_back_date invited_pressure
	drop date
	gen date = invited_startdate
	format date %td
	replace date = survey_covered_date_start if mi(date)
	
	
	* Make sure the panel cover the maximun possible date range
	count
	set obs `=`r(N)'+2'
	
	replace pid = 0 in `=`r(N)'+1'
	replace pid = 0 in `=`r(N)'+2'
	
	replace date = $mindate in `=`r(N)'+1'
	replace date = $maxdate in `=`r(N)'+2'
	
	
	* Fill Panel Dates
	tsset pid date
	tsfill, full
	drop if pid == 0
	bys pid (date) : gen day_order = _n
	order date day_order, after(pid)
	
	
	* Survey Covered Period (Very Inefficient Implementation..) 
	assert mi(survey_covered_date_start) if  mi(survey_covered_date_end)
	levelsof pid
	gen known = .

	foreach i in `r(levels)' {
		
		tempfile everyone
		save `everyone' , replace
		keep if pid == `i'
		
		
		preserve
			keep survey_covered_date_start
			drop if mi(survey_covered_date_start)
			count
			xpose, clear
			rename v* start*
			tempfile startdates
			save `startdates' , replace
		restore
		
		preserve
			keep survey_covered_date_end
			drop if mi(survey_covered_date_end)
			count
			local num_covers = `r(N)'
			xpose, clear
			rename v* end*
			tempfile enddates
			save `enddates' , replace
		restore
		
		
		merge 1:1 _n using `startdates', keep(1 2 3) nogen
		merge 1:1 _n using `enddates' , keep(1 2 3) nogen
		replace known = 0
		
		
		forval j = 1/`=`num_covers'-1' {
			
			sum start`=`j' + 1'
			local next_start_date = `r(mean)'
			
			sum end`j'
			local prev_end_date = `r(mean)'
			
			if `next_start_date' - `prev_end_date' - 1 < $min_conseq_unknown_day {
				replace start`=`j' + 1' = end`j'
			}
		}
		
		forval j = 1/`num_covers' {
			sum start`j'
			local start_date = `r(mean)'
			
			sum end`j'
			local end_date = `r(mean)'
			
			replace known = 1 if date >= `start_date' & date <= `end_date'
			
		}
		
		drop start* end*
		tempfile pid_level
		save `pid_level' , replace
		
		use `everyone' , clear
		merge 1:1 pid day_order using `pid_level' , keep(1 2 3 4 5) update nogen
		
	}
	lab define known_lab 1 "Survey Covered Period" 0 "Not Covered, Unknown" , replace
	lab val known known_lab

	
	* Fill Panel
	bys pid (date) : replace invited_number = invited_number[_n-1] if mi(invited_number)
	replace invited_number = 0 if mi(invited_number)
	
	foreach i of varlist 	invited_name invited_days invited_startdate invited_enddate ///
							invited_location invited_attend invited_back_date invited_pressure {
		bys pid invited_number (date) : replace `i' = `i'[_n-1] if mi(`i') & !mi(invited_number)
	}

	
	
****	
**## Gen Duration
****

	* Gen status
	bys pid invited_number (date) : gen invited_happening = date >= invited_startdate & date <= invited_enddate
	bys pid invited_number (date) : replace invited_happening = . if mi(invited_startdate)
	
	bys pid invited_number (date) : gen at_invited = date >= invited_startdate & date <= invited_back_date & !mi(invited_back_date)
	bys pid invited_number (date) : replace at_invited = . if mi(invited_startdate)

	gen status = 0
	replace status = 1 if invited_happening == 1 & at_invited == 1
	replace status = 2 if invited_happening == 0 & at_invited == 1
	replace status = 3 if invited_happening == 1 & at_invited == 0 & !mi(invited_back_date)
	replace status = 4 if invited_happening == 1 & at_invited == 0 & mi(invited_back_date)
	replace status = -99 if known == 0
	lab define invitedlab -99 "Not Covered in Survey" 0 "No Event" 1 "Event Happening, At Event" 2 "Event Ended, Remain At Event" 3 "Event Happening, Come Back Early" 4 "Event Happening, No Attend"
	lab val status invitedlab
	
	
	
	* Gen helpful vars
	
		* Invitation Info
		rename invited_number invited_order
		replace invited_order = . if status == 0
		
		rename invited_name invited_type
		replace invited_type = . if status == 0
		
		rename invited_days invited_duration
		replace invited_duration = . if status == 0
		
		gen invited_started = date == invited_startdate
		replace invited_started = . if invited_started != 1
		
		gen invited_ended = date == invited_enddate
		replace invited_ended = . if invited_ended != 1
	
	
		* DiD Indicator
		gen post = invited_order
		bys pid (date) : replace post = post[_n-1] if mi(post) 
		replace post = 0 if mi(post)
		
		lab define postlab 	0 "Pre 1st Known Event" 1 "Post 1st Known Event Start" 2 "Post 2nd Known Event Start" ///
							3 "Post 3rd Known Event Start" 4 "Post 4th Known Event Start" 5 "Post 5th Known Event Start"
		lab val post postlab
		
	
	* Replace variables with dates that are beyond covered period with missing
	foreach i of varlist invited_order-at_invited {
		if "`known'" != "known" replace `i' = . if status == -99
	}
	 
	
	
	
********************	
**## Final Touches
********************	

	keep pid date day_order known invited_order invited_type invited_duration status post
	order pid date day_order known invited_order invited_type invited_duration status post
	
	rename status invited_status
	rename post invited_post
	
	lab var pid 				"PID"
	lab var date 				"Date"
	lab var day_order 			"Number of Days in Maximum Possible Time Range"
	lab var known 				"Day Falls in Survey Covered Period"
	lab var invited_order 		"The nth Invited Event the Respondent Invited to"
	lab var invited_type 		"Invited Event Type"
	lab var invited_duration 	"Invited Event Duration, Regradless of Whether Attend"
	lab var invited_status 		"Status"
	lab var invited_post		"DiD Indicator"
	
	
	save "$temp/03_shock_module_panel_invited_hw.dta" , replace
	
	
	
************************************************************************************
**# Focus on Happened Events (Code is almost identical to that for Invited Events)
************************************************************************************


	use "$temp/02_shock_module_cleaned_hw.dta" , clear

	
****
**## Make Panel
****

	keep 	pid date happened_name1 happened_days1 happened_startdate1 happened_enddate1 happened_location1 happened_attend1 happened_back_date1 happened_pressure1
	sort pid date
			
			
	* Gen helpful variable to later restrict sample to periods coevered by the survey
	* I.e. 14 days before the survey. Extend a few days if start and end dates falls out of the period
	gen survey_covered_date_start = date - 14
	format survey_covered_date_start %td
	replace survey_covered_date_start = happened_startdate1 if happened_startdate1 < survey_covered_date_start
	
	
	
	gen survey_covered_date_end = date
	format survey_covered_date_end %td
	replace survey_covered_date_end = happened_enddate1 if happened_enddate1 > survey_covered_date_end & !mi(happened_enddate1)
	replace survey_covered_date_end = happened_back_date1 if happened_back_date1 > survey_covered_date_end & !mi(happened_back_date1)
	
	
	* Reshape
	rename *1 *
	
	gen survey_dates_covered = survey_covered_date_end - survey_covered_date_start + 1
	bys pid (date): gen survey_order = _n
	

	bys pid (happened_startdate) : gen happened_number = _n if !mi(happened_name)
	order happened_number , after(pid)
	

	
	* Make Panel
	drop date
	gen date = happened_startdate
	format date %td
	replace date = survey_covered_date_start if mi(date)
	

	* Make sure the panel cover the maximun possible date range
	count
	set obs `=`r(N)'+2'
	
	replace pid = 0 in `=`r(N)'+1'
	replace pid = 0 in `=`r(N)'+2'
	
	replace date = $mindate in `=`r(N)'+1'
	replace date = $maxdate in `=`r(N)'+2'
	
	
	
	* Fill Panel Dates
	tsset pid date
	tsfill, full
	drop if pid == 0
	bys pid (date) : gen day_order = _n
	order date day_order, after(pid)
	
	
	* Survey Covered Period (Very Inefficient Implementation..) 
	assert mi(survey_covered_date_start) if  mi(survey_covered_date_end)
	levelsof pid
	gen known = .

	foreach i in `r(levels)' {
		
		tempfile everyone
		save `everyone' , replace
		keep if pid == `i'
		
		
		preserve
			keep survey_covered_date_start
			drop if mi(survey_covered_date_start)
			count
			xpose, clear
			rename v* start*
			tempfile startdates
			save `startdates' , replace
		restore
		
		preserve
			keep survey_covered_date_end
			drop if mi(survey_covered_date_end)
			count
			local num_covers = `r(N)'
			xpose, clear
			rename v* end*
			tempfile enddates
			save `enddates' , replace
		restore
		
		
		merge 1:1 _n using `startdates', keep(1 2 3) nogen
		merge 1:1 _n using `enddates' , keep(1 2 3) nogen
		replace known = 0
		
		
		forval j = 1/`=`num_covers'-1' {
			
			sum start`=`j' + 1'
			local next_start_date = `r(mean)'
			
			sum end`j'
			local prev_end_date = `r(mean)'
			
			if `next_start_date' - `prev_end_date' - 1 < $min_conseq_unknown_day {
				replace start`=`j' + 1' = end`j'
			}
		}
		
		forval j = 1/`num_covers' {
			sum start`j'
			local start_date = `r(mean)'
			
			sum end`j'
			local end_date = `r(mean)'
			
			replace known = 1 if date >= `start_date' & date <= `end_date'
			
		}
		
		drop start* end*
		tempfile pid_level
		save `pid_level' , replace
		
		use `everyone' , clear
		merge 1:1 pid day_order using `pid_level' , keep(1 2 3 4 5) update nogen
		
	}
	lab define known_lab 1 "Survey Covered Period" 0 "Not Covered, Unknown" , replace
	lab val known known_lab

	
	* Fill Panel
	bys pid (date) : replace happened_number = happened_number[_n-1] if mi(happened_number)
	replace happened_number = 0 if mi(happened_number)
	
	foreach i of varlist 	happened_name happened_days happened_startdate happened_enddate ///
							happened_location happened_attend happened_back_date happened_pressure {
		bys pid happened_number (date) : replace `i' = `i'[_n-1] if mi(`i') & !mi(happened_number)
	}

	
	
****	
**## Gen Duration
****

	* Gen status
	bys pid happened_number (date) : gen happened_happening = date >= happened_startdate & date <= happened_enddate
	bys pid happened_number (date) : replace happened_happening = . if mi(happened_startdate)
	
	bys pid happened_number (date) : gen at_happened = date >= happened_startdate & date <= happened_back_date & !mi(happened_back_date)
	bys pid happened_number (date) : replace at_happened = . if mi(happened_startdate)

	gen status = 0
	replace status = 1 if happened_happening == 1 & at_happened == 1
	replace status = 2 if happened_happening == 0 & at_happened == 1
	replace status = 3 if happened_happening == 1 & at_happened == 0 & !mi(happened_back_date)
	replace status = 4 if happened_happening == 1 & at_happened == 0 & mi(happened_back_date)
	replace status = -99 if known == 0
	lab define happenedlab -99 "Not Covered in Survey" 0 "No Event" 1 "Event Happening, At Event" 2 "Event Ended, Remain At Event" 3 "Event Happening, Come Back Early" 4 "Event Happening, No Attend"
	lab val status happenedlab
	
	
	
	* Gen helpful vars
	
		* Invitation Info
		rename happened_number happened_order
		replace happened_order = . if status == 0
		
		rename happened_name happened_type
		replace happened_type = . if status == 0
		
		rename happened_days happened_duration
		replace happened_duration = . if status == 0
		
		gen happened_started = date == happened_startdate
		replace happened_started = . if happened_started != 1
		
		gen happened_ended = date == happened_enddate
		replace happened_ended = . if happened_ended != 1
	
	
		* DiD Indicator
		gen post = happened_order
		bys pid (date) : replace post = post[_n-1] if mi(post) 
		replace post = 0 if mi(post)
		
		lab define postlab 	0 "Pre 1st Known Event" 1 "Post 1st Known Event Start" 2 "Post 2nd Known Event Start" ///
							3 "Post 3rd Known Event Start" 4 "Post 4th Known Event Start" 5 "Post 5th Known Event Start"
		lab val post postlab
		
	
	* Replace variables with dates that are beyond covered period with missing
	foreach i of varlist happened_order-at_happened {
		if "`known'" != "known" replace `i' = . if status == -99
	}
	 
	
	
	
*****
**## Final Touches
*****

	keep pid date day_order known happened_order happened_type happened_duration status post
	order pid date day_order known happened_order happened_type happened_duration status post
	
	rename status happened_status
	rename post happened_post
	
	lab var pid 				"PID"
	lab var date 				"Date"
	lab var day_order 			"Number of Days in Maximum Possible Time Range"
	lab var known 				"Day Falls in Survey Covered Period"
	lab var happened_order 		"The nth Happened Event the Respondent Happened to"
	lab var happened_type 		"Happened Event Type"
	lab var happened_duration 	"Happened Event Duration, Regradless of Whether Attend"
	lab var happened_status 	"Happened Event Status"
	lab var happened_post		"Happened Event DiD Indicator"
	
	
	save "$temp/03_shock_module_panel_happened_hw.dta" , replace
	
	
	
	
	
	
	
**************************
**# Both Kinds of Events
**************************

	use "$temp/02_shock_module_cleaned_merged_hw.dta" , clear

****
**## Make Panel
****

	keep 	pid date event_name1-event_pressure3
	sort 	pid date
			
			
	* Gen helpful variable to later restrict sample to periods coevered by the survey
	* I.e. 14 days before the survey. Extend a few days if start and end dates falls out of the period
	gen survey_covered_date_start = date - 14
	format survey_covered_date_start %td
	replace survey_covered_date_start = event_startdate1 if event_startdate1 < survey_covered_date_start
	replace survey_covered_date_start = event_startdate2 if event_startdate2 < survey_covered_date_start
	replace survey_covered_date_start = event_startdate3 if event_startdate3 < survey_covered_date_start
	
	gen survey_covered_date_end = date
	format survey_covered_date_end %td
	replace survey_covered_date_end = event_enddate1 if event_enddate1 > survey_covered_date_end & !mi(event_enddate1)
	replace survey_covered_date_end = event_back_date1 if event_back_date1 > survey_covered_date_end & !mi(event_back_date1)
	replace survey_covered_date_end = event_enddate2 if event_enddate2 > survey_covered_date_end & !mi(event_enddate2)
	replace survey_covered_date_end = event_back_date2 if event_back_date2 > survey_covered_date_end & !mi(event_back_date2)
	replace survey_covered_date_end = event_enddate3 if event_enddate3 > survey_covered_date_end & !mi(event_enddate3)
	replace survey_covered_date_end = event_back_date3 if event_back_date3 > survey_covered_date_end & !mi(event_back_date3)
	gen survey_dates_covered = survey_covered_date_end - survey_covered_date_start + 1
	bys pid (date): gen survey_order = _n
	

	* Reshape
	tempvar pid_date
	egen `pid_date' = group(pid date)
	reshape long event_name event_days event_expand_days event_startdate event_enddate event_done_date event_location event_attend event_back_date event_pressure, i(`pid_date') j(event_number)
	
	
	* Drop harmless empty entries
	drop if inlist(event_number,2,3) & mi(event_name)

	
	* Event Number
	drop event_number
	bys pid (event_startdate) : gen event_number = _n if !mi(event_name)
	order event_number , after(pid)
	
	
****	
**## Make Panel
****	

	qui sum survey_covered_date_start
	global mindate = `r(min)'
	
	qui sum survey_covered_date_end
	global maxdate = `r(max)'
	
	forval i = 22856/22977 {
		gen d_`i'_ = 0
	}
	
	
	save "$temp/temp_shock_module.dta" , replace
	
	
	

**### Survey Covered Period
	
	preserve
	
		forval i = 22856/22977 { // The maximum possible date range.
			replace d_`i'_ = 1 if `i' >= survey_covered_date_start & `i' <= survey_covered_date_end & survey_covered_date_start != . & survey_covered_date_end != .
		}
		
		collapse (max)d_*, by(pid)
		
		gen index = 1
		

		reshape wide d_*, i(index) j(pid)
		drop index
		

		xpose, clear varname
		rename v1 survey_covered_period
	 
		
		generate date_str = regexcapture(0) if regexmatch(_varname, "[0-9]{5}")
		gen date = real(date_str)

		generate pid_str = regexcapture(0) if regexmatch(_varname, "[0-9]{4}$")
		gen pid = real(pid_str)
		
		
		bysort pid (date) : gen k = _n if survey_covered_period == 0
		forval i = 1/1000 {
			bysort pid (date) : replace k = k[_n+1] if k != . & k[_n+1] !=.
		}
		
		egen not_covered_period_id = group(pid k)
		
		gen count = 1
		egen n_cons_days = count(count), by (not_covered_period_id)
		replace survey_covered_period = 1 if survey_covered_period == 0 & n_cons_days < $min_conseq_unknown_day
		
		
		keep 	pid date survey_covered_period
		order 	pid date survey_covered_period
		
		tempfile survey_covered_period
		save `survey_covered_period' , replace
	
	restore
	
	
**### Event happening

	cap program drop gen_panel
	program define gen_panel
	
		args restrction
		
		forval i = 22856/22977 {
			replace d_`i'_ = 1 if `i' >= event_startdate & `i' <= event_done_date & !mi(event_startdate) & !mi(event_done_date) `restrction'
		}
		collapse (max)d_*, by(pid)
		gen index = 1
		reshape wide d_*, i(index) j(pid)
		drop index
		xpose, clear varname
		rename v1 event_happening
		generate date_str = regexcapture(0) if regexmatch(_varname, "[0-9]{5}")
		gen date = real(date_str)
		generate pid_str = regexcapture(0) if regexmatch(_varname, "[0-9]{4}$")
		gen pid = real(pid_str)
		bysort pid (date) : gen first_event = _n if event_happening == 1
		by pid : egen first_event_date = min(first_event)
		bysort pid (date) : gen post_first_event = 1 if _n >= first_event_date
		replace post_first_event = 0 if mi(post_first_event)
		keep 	pid date event_happening post_first_event
		order 	pid date event_happening post_first_event
	
	
	end


	* No restriction
	use "$temp/temp_shock_module.dta" , clear
	gen_panel ""
	tempfile event_happening
	save `event_happening' , replace

	
	
	
	* n days or more
	forval j = 2/10 {
		use "$temp/temp_shock_module.dta" , clear
		gen_panel "& event_expand_days >= `j'"
		rename event_happening event_happening_`j'd
		rename post_first_event post_first_event_`j'd
		tempfile event_happening_`j'd
		save `event_happening_`j'd' , replace
	}
	
	
	
	* Pressure level 1 or more
	forval j = 1/5 {
		use "$temp/temp_shock_module.dta" , clear
		gen_panel "& event_pressure >= `j'"
		rename event_happening event_happening_`j'p
		rename post_first_event post_first_event_`j'p
		tempfile event_happening_`j'p
		save `event_happening_`j'p' , replace
	}
		
	
	
**### Finish Making Panel
	
	use `survey_covered_period' , clear
	merge 1:1 pid date using `event_happening' , keep(1 2 3) nogen
	forval j = 2/10 {
		merge 1:1 pid date using `event_happening_`j'd' , keep(1 2 3) nogen
	}
	forval j = 1/5 {
		merge 1:1 pid date using `event_happening_`j'p' , keep(1 2 3) nogen
	}
	
	
	format date %td
	
	
	lab var pid 				"PID"
	lab var date 				"Date"
	lab var survey_covered_period 				"Day Falls in Survey Covered Period"

	
	
	save  "$temp/03_shock_module_panel_merged_hw.dta" , replace // Here merged means invite and happen are considered to have the same level of exogenity
	
	
	
	
************************	
**# Save Final Dataset
************************
	
	use "$temp/03_shock_module_panel_invited_hw.dta" , clear
	gen __INVITED__________ = .
	order __INVITED__________ , before(invited_order)
	
	
	gen __Happened__________ = .
	merge 1:1 	pid date using "$temp/03_shock_module_panel_happened_hw.dta" , ///
				keepusing(happened_order happened_type happened_duration happened_status happened_post) ///
				nogen
				
	save  "$final/03_shock_module_panel_hw.dta" , replace // Here invite and happen listed alongside eachother, seen as different kinds of events
