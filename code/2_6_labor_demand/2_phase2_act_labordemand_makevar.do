**************************************************
*Project: LD Main Study
*Purpose: Phase 2 activity - flexibility test cleaning
*Author: Luisa
*Last modified: 21-07-2022 (LC)
* Added dates for when the test date fell outside of the 7 weeks of Phase 2
**************************************************

	clear all
	set more off
	program drop _all

************************************************	
*0. Initial setup
************************************************
	
	
	program main
		
		use "$temp/01d_phase2act_labordemand_cleaned_completed_v2.dta", clear
		generating
		labelling
		save "$temp/02d_phase2act_labordemand_makevar_v2.dta", replace
	
	end
	
*****************************************
*Codes Starts
*****************************************

	program generating
	
		drop date
		gen date = date(required_attendance_date, "DMY")
		format date %td
		
		
		merge 1:1 pid date using "./02. Cleaning Data/06. Phase 2/02. Output/04_phase2_makepanel_for_tests_launchset1-3.dta", keepusing(f_treatment attend work howfound arrival_time daycount whenfound)
		keep if _merge == 3
		drop _merge	
		
		gen week_in = floor(daycount/7) + 1
		label var week_in "Weeks into Phase 2"
		gen arrival_time_hours = hh(arrival_time) + mm(arrival_time)/60 + ss(arrival_time)/3600
		label var arrival_time_hours "Arrival time (observed) in fraction of hours"
		// !!! QUICK FIX FOR NOW !!! replace as . if arrival_time <6, and replace with am if it is pm
	// 	replace arrival_time_hours = arrival_time_hours - 12 if arrival_time_hours > 12
		// 	replace arrival_time_hours = . if arrival_time_hours < 6
		
		gen     arrive_before_8 = arrival_time_hours <= 8    if !mi(arrival_time_hours) & !inlist(stand, ${cutoff_0815}, ${cutoff_0745}) //12-07-22 changed to globals (DL)
		replace arrive_before_8 = arrival_time_hours <= 8.25 if !mi(arrival_time_hours) & inlist(stand, ${cutoff_0815})
		replace arrive_before_8 = arrival_time_hours <= 7.75 if !mi(arrival_time_hours) & inlist(stand, ${cutoff_0745})
		replace arrive_before_8 = arrival_time_hours < 8.5 if !mi(arrival_time_hours) & stand>12 //10oct-2022 (NL)
		
		label var arrive_before_8 "=1 if attended the stand and spotted before cut-off time"
		
		gen attend_and_before8 = arrive_before_8 if attend == 1
		replace attend_and_before8 = 0 if attend == 0
		label var attend_and_before8 "=1 if attended and arrived before 8, 0 otherwise"

		merge 1:1 pid date using "./02. Cleaning Data/06. Phase 2/02. Output/05_phase2_makevar.dta", keepusing(bs_avg_wage bs_sum_attend bs_sum_work ss_dem_age)
		drop if _merge == 2
		drop _merge
		// Replace for dates outside of the 7 weeks
		foreach x in bs_avg_wage bs_sum_attend bs_sum_work ss_dem_age {
			bys pid: ereplace `x'= max(`x')
		}
		
		gen attend_on_date = attend_and_before8 == 1
		
		gen work_found_at_stand = work == 1 & whenfound == 2 if !mi(work) & !mi(whenfound)
// 		gen     day1 = 1 if day == "Monday"
// 		replace day1 = 2 if day == "Tuesday"
// 		replace day1 = 3 if day == "Wednesday"
// 		replace day1 = 4 if day == "Thursday"
// 		replace day1 = 5 if day == "Friday"
// 		replace day1 = 6 if day == "Saturday"
		drop  day
// 		rename  day1  day
		gen day = dow(date)
		
		bys pid : gen announced_twice = _N>1
	end


	program labelling
		label var attend_on_date "=1 if attended on required day before cut-off"
		label var treatment "Treatment status"
		
		//label define day_label 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday"
		//label value day day_label
		
		label define howfound_labs 1 "1. Phone- An employer/owner called me/I called the employer" 2 "2. Phone- A recruiter/contractor contacted me/I called the recruiter" 3 "3. Phone- A friend or family member offered me work/I called them" 4 "4. Self Employed- I worked for myself (self-owned business and earned an income)" 5 "5. Multi-day job with the same employer." 6 "6. Stand- recruiter/contractor called/ I called the recruiter/contractor" 7 "7. Stand- A friend or family member offered me job when I was at the stand." 8 "8. Stand- A reccruiter offered me job when I was at the stand." 998 "998. Others, specify ______" 999 "999. Survey was incomplete"
		label values howfound howfound_labs
		
	
	end

main
	
	*Done! 
	
