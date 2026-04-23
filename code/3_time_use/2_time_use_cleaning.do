**************************************************
**************************************************
*	Project: LD Main Study
*	Purpose: Clean Time Use
* 	
*	Author: HW
*	Last modified: May 12, 2024 HW
**************************************************
**************************************************


**********************
**# Append V1 and V2
**********************


****
**## V1 
****

	use "$temp/lss_time_use_module_v1.dta" , clear
	rename p1 pid
	rename p3 date
	isid pid date
	
	
	keep if z0 == 1
	destring stand , replace
	drop if inlist(stand,${droplist})		
	
	
	keep pid date index_1-work_9
	gen tu_version = 1
	lab var tu_version "Time Use Survey Version"

	save "$temp/lss_time_use_module_v1_cleaned.dta" , replace
	
	
	
	
****
**## V2
****

	use "$raw/lss_time_use_module_v2.dta" , clear
	rename p1 pid
	rename p3 date
	replace date = td(13oct2022) if date == td(13oct2021)
	isid pid date
	
	
	keep if z0 == 1
	replace  stand = regexcapture(0) if regexmatch(stand, "\d+")
	destring stand , replace 
	drop if inlist(stand,${droplist})		
	
	
	keep pid date index_1-work_9
	drop activity_filt*
	drop activity_tot*
	gen tu_version = 2
	lab var tu_version "Time Use Survey Version"

	save "$temp/lss_time_use_module_v2_cleaned.dta" , replace
	
	

	
****	
**## Append
****

	use "$temp/lss_time_use_module_v1_cleaned.dta" , clear
	append using "$temp/lss_time_use_module_v2_cleaned.dta" 
	
	
	drop index* time_activity_?
	

	
	
	
	
**************
**# Cleaning
**************


****
**## Activities
****
	
	forvalues i = 1/14 {
		forvalues j = 1/7 {
			
			* Gen Main Var
			cap gen time_activity_`i'_`j' = "0"
			replace time_activity_`i'_`j' = "" if mi(time_activity_1_`j')
			destring time_activity_`i'_`j' , replace
			
			* Handle Others
			gen act = lower(trim(time_activity_others_`j'))
			replace time_activity_`i'_`j'  = 1 if inlist(act, ///
				"my daughter is tuition center pickup", ///
				"droped mom for", ///
				"droped mom for job") & `i' == 5
			replace time_activity_`i'_`j'  = 1 if act == "bathing" & `i' == 6
			replace time_activity_`i'_`j'  = 1 if act == "using phone" & `i' == 9
			replace time_activity_`i'_`j' = 1 if inlist(act, "going to work", "walking") & `i' == 10
			replace time_activity_`i'_`j' = 1 if act == "summadha irupe" & `i' == 11
			replace time_activity_`i'_`j' = 1 if act == "waiting for job" & `i' == 12
			replace time_activity_`i'_`j' = 1 if inlist(act, ///
				"house cleaning", ///
				"washing the vehicle", ///
				"i do watering and milking of cows", ///
				"gardening", ///
				"dishes wash") & `i' == 13
			replace time_activity_`i'_`j' = 1 if inlist(act, ///
				"drinking tea", ///
				"watching tv", ///
				"tv parpathu", ///
				"tv", ///
				"tea sapiduvadhu", ///
				"tea poduvadhu", ///
				"tea shop", ///
				"watching news") & `i' == 14
			drop act
			
			* Adjusted for other
			cap gen time_activity_adj_`i'_`j' = time_activity_`i'_`j'
			if `i' <= 12 replace time_activity_adj_`i'_`j' = activity_other_`i'_`j' if !mi(activity_other_`i'_`j')
			
			
			* Labels
			local activity_lab ""
			if `i' == 1  local activity_lab "1. Get water"
			if `i' == 2  local activity_lab "2. Cook breakfast"
			if `i' == 3  local activity_lab "3. Eat breakfast"
			if `i' == 4  local activity_lab "4. Help get kids ready for school"
			if `i' == 5  local activity_lab "5. Drop kids at school"
			if `i' == 6  local activity_lab "6. Wash / bathe"
			if `i' == 7  local activity_lab "7. Go to temple / prayers / meditate"
			if `i' == 8  local activity_lab "8. Go to the store / shop"
			if `i' == 9  local activity_lab "9. Call employers / friends to find a job"
			if `i' == 10 local activity_lab "10. Traveling"
			if `i' == 11 local activity_lab "11. Sleep / rest"
			if `i' == 12 local activity_lab "12. Be at the stand / search for work"
			if `i' == 13 local activity_lab "13. Home production (chores, livestock care, etc.)"
			if `i' == 14 local activity_lab "14. Entertainment (drinking tea, watching TV, etc.)"
    
			local time_lab ""
			if `j' == 1  local time_lab "5:30-6:00am"
			if `j' == 2  local time_lab "6:00-6:30am"
			if `j' == 3  local time_lab "6:30-7:00am"
			if `j' == 4  local time_lab "7:00-7:30am"
			if `j' == 5  local time_lab "7:30-8:00am"
			if `j' == 6  local time_lab "8:00-8:30am"
			if `j' == 7  local time_lab "8:30-9:00am"
			
			lab var time_activity_`i'_`j' 		"Activity at `time_lab': `activity_lab'"
			lab var time_activity_adj_`i'_`j' 	"Adj Activity (Incl. Weak) at `time_lab': `activity_lab'"
		}
		
		* Main Total
		egen time_activity_tot_`i' = rowtotal(time_activity_`i'_*) , missing
		egen time_activity_adj_tot_`i' = rowtotal(time_activity_adj_`i'_*) , missing
		
		lab var time_activity_tot_`i' 		"Activity: `activity_lab'"
		lab var time_activity_adj_tot_`i' 	"Adj Activity (Incl. Weak): `activity_lab'"
	}
	
	drop time_label_repeat_* time_activity_99* time_activity_others* activity_other*
	
	
****
**## Changes in Activities
****

	* Asked in version 2, conditional on doing the activity
	foreach i in 1 2 4 5 8 {
		
		gen time_self_less_comp_2mo_`i' = .
		replace time_self_less_comp_2mo_`i' = 1 if time_whodid`i' == 1 & tu_version == 2
		replace time_self_less_comp_2mo_`i' = 0 if inlist(time_whodid`i',2,3,4) & tu_version == 2
		
		gen time_self_more_comp_2mo_`i' = .
		replace time_self_more_comp_2mo_`i' = 0 if time_whodid`i' == 1 & tu_version == 2
		replace time_self_more_comp_2mo_`i' = 1 if inlist(time_whodid`i',2,3,4) & tu_version == 2
		
	}
	
	
	* Asked in version 1
	foreach i in 1 2 4 5 8 {
		forvalues j = 1/7 {
			
			gen time_whodid_self_`i'_`j' = .
			gen time_whodid_other_`i'_`j' = .
			
			replace time_whodid_self_`i'_`j' 	= time_whodid`i'_`j' == 1 if !mi(time_whodid`i'_`j' )
			replace time_whodid_other_`i'_`j' 	= time_whodid`i'_`j' != 1 if !mi(time_whodid`i'_`j' )
			
			replace time_whodid_self_`i'_`j' 	= time_whodid_self_`i'_`j' * (8-`j')
			replace time_whodid_other_`i'_`j' 	= time_whodid_other_`i'_`j' * (8-`j')

		}
		
		egen time_whodid_self_`i' = rowtotal(time_whodid_self_`i'_*) , missing
		egen time_whodid_other_`i' = rowtotal(time_whodid_other_`i'_*) , missing
		
		replace time_self_less_comp_2mo_`i' = time_whodid_self_`i' > time_whodid_other_`i' if !mi(time_whodid_self_`i')
		replace time_self_more_comp_2mo_`i' = time_whodid_self_`i' <= time_whodid_other_`i' if !mi(time_whodid_self_`i')
	}
	
	drop time_whodid*
	
	lab var time_self_less_comp_2mo_1 "I would have been more likely to 1. Get water two months ago"
	lab var time_self_less_comp_2mo_2 "I would have been more likely to 2. Cook breakfast two months ago"
	lab var time_self_less_comp_2mo_4 "I would have been more likely to 4. Help get kids ready for school two months ago"
	lab var time_self_less_comp_2mo_5 "I would have been more likely to 5. Drop kids at school two months ago"
	lab var time_self_less_comp_2mo_8 "I would have been more likely to 8. Go to the store/shop two months ago"
	

	lab var time_self_more_comp_2mo_1 "Oth Fmly Mbr would have been more likely to 1. Get water two months ago"
	lab var time_self_more_comp_2mo_2 "Oth Fmly Mbr would have been more likely to 2. Cook breakfast two months ago"
	lab var time_self_more_comp_2mo_4 "Oth Fmly Mbr would have been more likely to 4. Help get kids ready for school two months ago"
	lab var time_self_more_comp_2mo_5 "Oth Fmly Mbr would have been more likely to 5. Drop kids at school two months ago"
	lab var time_self_more_comp_2mo_8 "Oth Fmly Mbr would have been more likely to 8. Go to the store/shop two months ago"
	
	

****
**## Bed Time
****

	replace bed_time = regexs(0) if regexmatch(bed_time, "\d+:\d+:\d+")
	split bed_time , parse(:)
	destring bed_time1 bed_time2 , replace
	
	replace bed_time1 = bed_time1 + 12 if inlist(bed_time1,1,2)
	replace bed_time1 = bed_time1 + 12
	replace bed_time1 = bed_time1 + bed_time2/60
	
	rename bed_time1 time_bed_hours
	drop bed_time? bed_time

	lab var time_bed_hours "Bed Time (24 hour format, post midnight times are 25, 26)"
	

	
	
****
**## Job Finding Probability
****	
	
	rename work_8 time_jfp_n_days_8am
	rename work_9 time_jfp_n_days_9am
	
	lab var time_jfp_n_days_8am "Time Use Survey n days expected to find work if arrive at 8"
	lab var time_jfp_n_days_9am "Time Use Survey n days expected to find work if arrive at 9"	

	
	
	

****************************
**# Finalize and Save Data
****************************



****
**## Order Variables 
****

	order 	pid date tu_version time_jfp_n_days_8am time_jfp_n_days_9am time_bed_hours ///
			time_activity_*_1 time_activity_*_2 time_activity_*_3 time_activity_*_4 time_activity_*_5 time_activity_*_6 time_activity_*_7 ///
			time_activity_adj_*_1 time_activity_adj_*_2 time_activity_adj_*_3 time_activity_adj_*_4 ///
			time_activity_adj_*_5 time_activity_adj_*_6 time_activity_adj_*_7 ///
			time_activity_tot_* time_activity_adj_tot_*


	forval i = 1/7 {
		order time_activity_13_`i' time_activity_14_`i' , after(time_activity_12_`i')
		order time_activity_adj_13_`i' time_activity_adj_14_`i' , after(time_activity_adj_12_`i')
	}
	
	forval i = 14(-1)1 {
		order time_activity_adj_tot_`i' , after(time_activity_adj_14_7)
	}
	
	forval i = 14(-1)1 {
		order time_activity_tot_`i' , after(time_activity_adj_14_7)
	}	
	
	
	
****
**## Save Data
****

	save "$temp/lss_time_use_cleaned_hw.dta" , replace
