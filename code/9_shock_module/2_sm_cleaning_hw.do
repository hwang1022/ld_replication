**************************************************
*	Project: LD Main Study
*	Purpose: Shock Module Cleaning
*	Author: HW 
* 	Adapted from 2_sm_cleaning.do by Luisa
*	Last modified: Sep-9-2024 (HW)
**************************************************

*****************************
**# Define Cleaning Options
*****************************


	* Whether remove events that are "Less than one day" in duration.
	* If so, delete the event and ajust number of events accordingly
	* Note that if one selected "Less than one day", then they will not be asked about further event information
	* Which means events "Less than one day" only has one variable— event type (e.g. Wedding / Funeral)
	* The duration of event was only asked in version 2
	* Notes that only q1 will be affected
	global drop_count_less_one_day = 1


	* Whether remove events that the respondent didn't attend
	* Keep the variable and differentite in analysis
	global drop_no_attend = 0

	
	* Whether to drop respondents who didn't answer q15 and q16
	* The two questions are simple and straightforward, if someone didn't answer them, they likely didn't answer other questions
	* I use answering q15 and q16 as proxy for survey take up because the prevalence of 998 and 999 in event roster makes it impossible
	* to tell whether one attrited or had no event
	global drop_no_answer = 1
	
	
	
	* After cleaning, there are 2 interviews each with two invites. However both invites have no info at all (even in the raw dataset)
	* I current drop the two observations (The respondents corresponding to the interviews both have multiple interviews)
	* By dropping them their status will be considered as missing for the covered period of the survey
	global drop_no_info = 1
	
	
	
********************	
**# Define Program
********************

	cap program drop clean_invite_name
	program define clean_invite_name
	
	syntax varlist [,]
	
	foreach i of varlist `varlist' {
		replace `i' = regexs(0) if(regexm(`i', "\d+"))
		destring `i' , replace
	}

	end
	
	
***************
**# Load Data
***************

	use "$temp/01_shock_module_named_hw.dta" , clear
	
	
	
*********************
**# Restrict Sample
*********************
	
	if $drop_no_answer == 1 drop if !inlist(native_return_request,0,1)
	
	
	
*****************
**# Corrections
*****************


	* Luisa's code
	// 14-nov-2022
	replace invited_enddate1 = td(20aug2022) if key == "uuid:47e1ba94-3c4f-45d7-a420-2b02edbe2bae"
	// 25-nov-22
	//wrong year
	replace happened_enddate1 = td(20aug2022) if key == "uuid:d024a64a-52e7-4bdf-9b0c-07adc72de5e6"
	//invited _start_date > invited_end_date
	replace invited_enddate1   = td(24aug2022) if key == "uuid:90cf2343-90cf-4c73-a3b7-91e4ca828b56"
	replace invited_back_date1 = td(24aug2022) if key == "uuid:90cf2343-90cf-4c73-a3b7-91e4ca828b56"
	replace invited_enddate1   = td(01sep2022) if key == "uuid:47f01cfa-5360-4d01-b1e1-890af8564982"
	replace invited_startdate1 = td(24nov2022) if key == "uuid:c0ac45fc-b53c-422a-96ad-06d675589d0d"
	replace invited_enddate1   = td(26nov2022) if key == "uuid:c0ac45fc-b53c-422a-96ad-06d675589d0d"
	* Luisa's code end
	
	
	replace invited_others = "" if strpos(invited_others, "0")
	replace invited_others = "" if strpos(invited_others, "999")
	replace invited_others = "" if strpos(invited_others, "None")
	replace invited_others = "" if strpos(invited_others, "Nothing")
	replace invited_others = "" if invited_others == "Na"
	replace invited_others = "" if invited_others == "No"
	replace invited_others = "" if invited_others == "O"
	
	
	
	replace happened_others = "" if strpos(happened_others, "0")
	replace happened_others = "" if strpos(happened_others, "999")
	replace happened_others = "" if strpos(happened_others, "None")
	replace happened_others = "" if strpos(happened_others, "Nothing")
	replace happened_others = "" if strpos(happened_others, "nothing")
	replace happened_others = "" if strpos(happened_others, "No problem")
	replace happened_others = "" if strpos(happened_others, "Nil")
	replace happened_others = "" if strpos(happened_others, "N0ne")
	replace happened_others = "" if happened_others == "Na"
	replace happened_others = "" if happened_others == "No"
	replace happened_others = "" if happened_others == "O"
	replace happened_others = "" if happened_others == "no"
	
	
	
	* Fix one incorrect happened_startdate
	replace happened_startdate1 = 22861 if happened_startdate1 == 22770 // May 5 to Aug 5
	
	
	* Fix one incorrect invited_back_date
	replace invited_back_date1 = 22879 if invited_back_date1 == 22514 // Aug 2021 to Aug 2022
	
	
**********************	
**# Resitrict Sample
**********************
	
	global droplist 4, 7, 8, 9, 10, 11, 12, 14, 19 	// From mater
	destring stand , replace
	drop if inlist(stand, ${droplist})
	drop stand
	
	

	isid pid date
	sort pid date
	
	

******************
**# Clean Events
******************
	
	// Handle Others
	// Here I assume and have checked Baby birthday means brithday of baby who has been born a while ago, i.e. not childbirth
	gen invited_other = 0
	order invited_other , after(invited_childschool)
	
	tab invited_others
	assert `r(r)' == 5 // There are 5 legit others
	replace invited_other = 1 if strpos(invited_others, "Baby brithday") // Checked, happened_birth == 0
	replace invited_other = 1 if strpos(invited_others, "Bank loan")
	replace invited_other = 1 if strpos(invited_others, "Birthday function")
	replace invited_other = 1 if strpos(invited_others, "Valakappu")
	replace invited_other = 1 if strpos(invited_others, "Baby brithday") // Checked, happened_birth == 0
	
	count if strpos(invited_others, "Farming wor")	// Checked farming work also counted in the happened section. Remove this entry later. This person has no other events in case you wonder, very safe to remove. Entry will be automatically removed.
	drop invited_others

	* Drop events for "No event" (vast majority of 998, 999)
	egen event_num = rowtotal(invited_wedding invited_funeral invited_festival invited_pilgrimage invited_childschool invited_other)
	gen  event_any = event_num >= 1 & !mi(event_num)
	order event_num event_any, after(invited_other)
	
	* Clean event name
	replace invited_name1 = "" if event_any == 0
	replace invited_name2 = "" if event_any == 0
	clean_invite_name invited_name1 invited_name2
	lab define eventname 1 "1. Wedding" 2 "2. Funeral" 3 "3. Festival" 4 "4. Pilgrimage" 5 "5. Children's school meeting" 998 "Other (Verified)" , replace
	lab val invited_name1 eventname
	lab val invited_name2 eventname
	

	foreach i of varlist 	invited_if_one_day1 invited_days1 invited_startdate1 invited_enddate1 ///
							invited_location1 invited_attend1 invited_back_date1 invited_pressure1 {
		replace `i' = . if mi(invited_name1)
							}
										
	foreach i of varlist 	invited_if_one_day2 invited_days2 invited_startdate2 invited_enddate2 ///
							invited_location2 invited_attend2 invited_back_date2 invited_pressure2 {
		replace `i' = . if mi(invited_name2)
	}
	
	
	* If event start date is the same as interview date, drop
	gen temp_date_wrong_1 = invited_startdate1 == date
	gen temp_date_wrong_2 = invited_startdate2 == date
	foreach i of varlist invited_name1 invited_if_one_day1 invited_days1 invited_startdate1 invited_enddate1 invited_location1 invited_attend1 invited_back_date1 invited_pressure1 {
		replace `i' = . if temp_date_wrong_1 == 1
	}	
	foreach i of varlist invited_name2 invited_if_one_day2 invited_days2 invited_startdate2 invited_enddate2 invited_location2 invited_attend2 invited_back_date2 invited_pressure2 {
		replace `i' = . if temp_date_wrong_2 == 1
	}
	drop temp_date_wrong_*
	

	* Drop useless vars
	drop invited_998 invited_999
	
	
	* Drop Events that are less than 1 day
	if $drop_count_less_one_day == 1 {
		
		* Clear entries
		forval i = 1/2 {
			replace invited_name`i' = . if invited_if_one_day`i' == 1
			foreach j of varlist 	invited_if_one_day`i' invited_days`i' invited_startdate`i' invited_enddate`i' invited_location`i' invited_attend`i' invited_back_date`i' invited_pressure`i' {
				replace `j' = . if mi(invited_name`i')
			}	
		}
		drop invited_if_one_day1 invited_if_one_day2
	}
	
	
	
	* Drop Events that are not attended
	if $drop_no_attend == 1 {
		
		* Clear entries
		forval i = 1/2 {
			replace invited_name`i' = . if invited_attend`i' != 1
			foreach j of varlist 	invited_if_one_day`i' invited_days`i' invited_startdate`i' invited_enddate`i' invited_location`i' invited_attend`i' invited_back_date`i' invited_pressure`i' {
				replace `j' = . if mi(invited_name`i')
			}	
		}
	}
	
	* Remove events with event name only bu no anything else
	if $drop_no_info == 1 replace invited_name1 = . if !mi(invited_name1) & mi(invited_days1)
	if $drop_no_info == 1 replace invited_name2 = . if !mi(invited_name2) & mi(invited_days2)
	
	* Update summaries
	foreach i of varlist invited_wedding invited_funeral invited_festival invited_pilgrimage invited_childschool invited_other event_num event_any {
		replace `i' = 0
	}
	replace invited_wedding = invited_wedding + 1 if invited_name1 == 1
	replace invited_funeral = invited_funeral + 1 if invited_name1 == 2
	replace invited_festival = invited_festival + 1 if invited_name1 == 3
	replace invited_pilgrimage = invited_pilgrimage + 1 if invited_name1 == 4
	replace invited_childschool = invited_childschool + 1 if invited_name1 == 5
	replace invited_other = invited_other + 1 if invited_name1 == 6
	replace invited_wedding = invited_wedding + 1 if invited_name2 == 1
	replace invited_funeral = invited_funeral + 1 if invited_name2 == 2
	replace invited_festival = invited_festival + 1 if invited_name2 == 3
	replace invited_pilgrimage = invited_pilgrimage + 1 if invited_name2 == 4
	replace invited_childschool = invited_childschool + 1 if invited_name2 == 5
	replace invited_other = invited_other + 1 if invited_name2 == 6
	replace event_num = invited_wedding + invited_funeral + invited_festival + invited_pilgrimage + invited_childschool + invited_other
	replace event_any = 1 if event_num >= 1 & !mi(event_num)	
	
	

	* Based on different cleaning options (e.g. drop_no_attend), it is possible that all entries event 2 gets dropped.
	* In this case remove invited_*2 alltogether
	qui tab invited_name2
	if `r(r)' == 0 drop invited*2
	
	
	* Correct q_2 to match Q3_1 and Q3_2 // In case you wonder there is no 0 days in invited_days1 or invited_days2
	replace invited_days1 = invited_enddate1 - invited_startdate1 + 1
	replace invited_days2 = invited_enddate2 - invited_startdate2 + 1
	lab var invited_days1 "Duration of Invited Event"
	lab var invited_days2 "Duration of Invited Event"

	
	* Drop invited_back_date if no attend
	replace invited_back_date1 = . if invited_attend1 == 0
	replace invited_back_date2 = . if invited_attend2 == 0
	
	* Replace back date with event end date if attend but not specify return date
	replace invited_back_date1 = invited_enddate1 if mi(invited_back_date1) & invited_attend1 == 1
	replace invited_back_date2 = invited_enddate1 if mi(invited_back_date1) & invited_attend1 == 1
	
	
	* Gen expanded event duarion where the end data is either event end date or come back date, whichever later.

	egen actualinvitedendddate1 = rowmax(invited_enddate1 invited_back_date1)
	egen actualinvitedendddate2 = rowmax(invited_enddate2 invited_back_date2)
	order actualinvitedendddate1 , after(invited_back_date1)
	order actualinvitedendddate2 , after(invited_back_date2)
	
	gen invited_expand_days1 = actualinvitedendddate1 - invited_startdate1 + 1
	gen invited_expand_days2 = actualinvitedendddate2 - invited_startdate2 + 1
	
	order invited_expand_days1 , after(invited_days1)
	order invited_expand_days2 , after(invited_days2)
	
	lab var invited_days1 "Duration of Invited Event, including days at event place after event end"
	lab var invited_days2 "Duration of Invited Event, including days at event place after event end"
	
	
*******************
**# Clean Happens
*******************

	// Handle Others. I checked there is only 1 other and it's legit
	gen happened_other = 0
	order happened_other , after(happened_property)
	
	tab happened_others
	assert `r(r)' == 1 // There is 1 legit others
	replace happened_other = 1 if strpos(happened_others, "Went to hometown for his daughter")
	drop happened_others
	

	* Drop happens for "No happen" (vast majority of 998, 999)
	egen happen_num = rowtotal(happened_sick happened_famsick happened_birth happened_death happened_emergency happened_agwork happened_property happened_other)
	gen  happen_any = happen_num >= 1 & !mi(happen_num)
	order happen_num happen_any, after(happened_other)
	
	* Clean happen name
	replace happened_name1 = "" if happen_any == 0
	replace happened_name2 = "" if happen_any == 0
	clean_invite_name happened_name1 happened_name2
	replace happened_name1 = . if happened_name1 == 0
	replace happened_name1 = . if happened_name2 == 0
	lab define happenname 1 "1.Falling sick/injury" 2 "2. Member of the family falling sick/getting injured and requiring assistance" 3 "3. Childbirth in the family" 4 "4. Death in the family" 5 "5. Fire/floods at home" 6 "6. Agricultural work at your native" 998 "Other (Verified)" , replace
	lab val happened_name1 happenname
	lab val happened_name2 happenname
	

	foreach i of varlist 	happened_if_one_day1 happened_days1 happened_startdate1 happened_enddate1 ///
							happened_location1 happened_attend1 happened_back_date1 happened_pressure1 {
		replace `i' = . if mi(happened_name1)
							}
										
	foreach i of varlist 	happened_if_one_day2 happened_days2 happened_startdate2 happened_enddate2 ///
							happened_location2 happened_attend2 happened_back_date2 happened_pressure2 {
		replace `i' = . if mi(happened_name2)
	}
	
	* If happen start date is the same as interview date, drop
	gen temp_date_wrong_1 = happened_startdate1 == date
	gen temp_date_wrong_2 = happened_startdate2 == date
	foreach i of varlist happened_name1 happened_if_one_day1 happened_days1 happened_startdate1 happened_enddate1 happened_location1 happened_attend1 happened_back_date1 happened_pressure1 {
		replace `i' = . if temp_date_wrong_1 == 1
	}	
	foreach i of varlist happened_name2 happened_if_one_day2 happened_days2 happened_startdate2 happened_enddate2 happened_location2 happened_attend2 happened_back_date2 happened_pressure2 {
		replace `i' = . if temp_date_wrong_2 == 1
	}
	drop temp_date_wrong_*
	
	* Drop useless vars
	drop happened_998 happened_999
	


	
	* Drop Events that are less than 1 day
	if $drop_count_less_one_day == 1 {
		
		* Clear entries
		forval i = 1/2 {
			replace happened_name`i' = . if happened_if_one_day`i' == 1
			foreach j of varlist 	happened_if_one_day`i' happened_days`i' happened_startdate`i' happened_enddate`i' happened_location`i' happened_attend`i' happened_back_date`i' happened_pressure`i' {
				replace `j' = . if mi(happened_name`i')
			}	
		}
		drop happened_if_one_day1 happened_if_one_day2
	}
	
	
	
	* Drop Events that are not attended
	if $drop_no_attend == 1 {
		
		* Clear entries
		forval i = 1/2 {
			replace happened_name`i' = . if happened_attend`i' != 1
			foreach j of varlist 	happened_if_one_day`i' happened_days`i' happened_startdate`i' happened_enddate`i' happened_location`i' happened_attend`i' happened_back_date`i' happened_pressure`i' {
				replace `j' = . if mi(happened_name`i')
			}	
		}
	}
	
	
	* Remove events with event name only bu no anything else
	if $drop_no_info == 1 replace happened_name1 = . if !mi(happened_name1) & mi(happened_days1)
	if $drop_no_info == 1 replace happened_name2 = . if !mi(happened_name2) & mi(happened_days2)
	
	* Update summaries
	foreach i of varlist happened_sick happened_famsick happened_birth happened_death happened_emergency happened_agwork happened_property happened_other happen_num happen_any {
		replace `i' = 0
	}
	replace happened_sick = happened_sick + 1 if happened_name1 == 1
	replace happened_famsick = happened_famsick + 1 if happened_name1 == 2
	replace happened_birth = happened_birth + 1 if happened_name1 == 3
	replace happened_death = happened_death + 1 if happened_name1 == 4
	replace happened_emergency = happened_emergency + 1 if happened_name1 == 5
	replace happened_agwork = happened_agwork + 1 if happened_name1 == 6
	replace happened_property = happened_property + 1 if happened_name1 == 7
	replace happened_other= happened_other + 1 if happened_name1 == 998
	replace happened_sick = happened_sick + 1 if happened_name2 == 1
	replace happened_famsick = happened_famsick + 1 if happened_name2 == 2
	replace happened_birth = happened_birth + 1 if happened_name2 == 3
	replace happened_death = happened_death + 1 if happened_name2 == 4
	replace happened_emergency = happened_emergency + 1 if happened_name2 == 5
	replace happened_agwork = happened_agwork + 1 if happened_name2 == 6
	replace happened_property = happened_property + 1 if happened_name2 == 7
	replace happened_other= happened_other + 1 if happened_name2 == 998	
	
	replace happen_num = happened_sick + happened_famsick + happened_birth + happened_death + happened_emergency + happened_agwork + happened_property + happened_other
	replace happen_any = 1 if happen_num >= 1 & !mi(happen_num)	
	
	
	* Fix 1 legit happen but with 999 as attend. I replace it with not attended
	replace happened_attend1 = 0 if key == "uuid:1ec35b68-fbef-4e75-a6bf-842313151e95"
	
	
	* Based on current different cleaning options, all entries happen 2 have been dropped.
	* In this case remove happened_*2 alltogether
	qui tab happened_name2
	local num_nonmiss = `r(r)'
	if `num_nonmiss' == 0 drop happened*2
	assert `num_nonmiss' == 0
	
	
	* Correct q_2 to match Q3_1 and Q3_2 // In case you wonder there is no 0 days in happened_days1
	replace happened_days1 = happened_enddate1 - happened_startdate1 + 1
	lab var happened_days1 "Duration of Happened Event"
	
	* Drop happened_back_date if no attend
	replace happened_back_date1 = . if happened_attend1 == 0
	
	* Replace back date with event end date if attend but not specify return date
	replace happened_back_date1 = happened_enddate1 if mi(happened_back_date1) & happened_attend1 == 1
	
	
	* Gen expanded event duarion where the end data is either event end date or come back date, whichever later.
	egen actualhappenedendddate1 = rowmax(happened_enddate1 happened_back_date1)
	order actualhappenedendddate1 , after(happened_back_date1)
	gen happened_expand_days1 = actualhappenedendddate1 - happened_startdate1 + 1
	order happened_expand_days1  , after(happened_days1)
	lab var happened_expand_days1 "Duration of Happened Event, including days at event place after event end"
	
	
	
	
	
*******************
**# Quick Summary
*******************
		
	* Number of Observations
	count
	
	
	* Number of Invited Events
	tab event_num 
	tab event_any
	
	* Types of Invited Events
	tab1 invited_name*
	
	* Location of Invited Events
	tab1 invited_days1

	
******************
**# Save Dataset
******************	
	cap drop __0*
	save "$temp/02_shock_module_cleaned_hw.dta" , replace
	
	
	
	
	
	
	
	
	
	
	
*************************************************************************
**# Both Invited and Happened (simplified content, added on Oct 3 2024)
*************************************************************************

	use "$temp/02_shock_module_cleaned_hw.dta" , clear

	
	* Drop Unecessary Vars
	drop 	invited_wedding invited_funeral invited_festival invited_pilgrimage invited_childschool invited_other event_num event_any ///
			__HAPPEN__________ happened_sick happened_famsick happened_birth happened_death happened_emergency happened_agwork ///
			happened_property happened_other happen_num happen_any
	
			
	* Rename Vars
	rename invited_name1 				event_name1
	rename invited_days1 				event_days1
	rename invited_expand_days1 		event_expand_days1
	rename invited_startdate1 			event_startdate1
	rename invited_enddate1 			event_enddate1
	rename invited_location1 			event_location1
	rename invited_attend1 				event_attend1
	rename invited_back_date1 			event_back_date1
	rename invited_pressure1 			event_pressure1
	rename invited_name2 				event_name2
	rename invited_days2 				event_days2
	rename invited_expand_days2 		event_expand_days2
	rename invited_startdate2 			event_startdate2
	rename invited_enddate2 			event_enddate2
	rename invited_location2 			event_location2
	rename invited_attend2 				event_attend2
	rename invited_back_date2 			event_back_date2
	rename invited_pressure2 			event_pressure2
	rename happened_name1 				event_name3
	rename happened_days1 				event_days3
	rename happened_expand_days1 		event_expand_days3
	rename happened_startdate1 			event_startdate3
	rename happened_enddate1 			event_enddate3
	rename happened_location1 			event_location3
	rename happened_attend1 			event_attend3
	rename happened_back_date1 			event_back_date3
	rename happened_pressure1			event_pressure3
	rename actualinvitedendddate1 		event_done_date1
	rename actualinvitedendddate2 		event_done_date2
	rename actualhappenedendddate1		event_done_date3
	
	
	
	* Reconcile event name
	replace event_name1 = 6 if event_name1 == 998
	replace event_name2 = 6 if event_name2 == 998
	replace event_name3 = event_name3 + 6
	replace event_name3 = 14 if event_name3 == 1004
	
	lab define event_name 	1 "Invite 1. Wedding" 2 "Invite 2. Funeral" 3 "Invite 3. Festival" 4 "Invite 4. Pilgrimage" ///
							5 "Invite 5. Children's school meeting" 6 "Invite 6. Other Verified" ///
							7 "Happen 1. Sick/Injury" 8 "Happen 2. Family Sick/Injury" 9 "Happen 3. Childbirth in Family" ///
							10 "Happen 4. Death in Family" 11 "Happen 5. Fire/Floods at Home" 12 "Happen 6. Agricultural Work" ///
							13 "Happen 7. Selling/Buying Property" 14 "Happen 8. Other Verified" , replace
	lab val event_name1 event_name
	lab val event_name2 event_name
	lab val event_name3 event_name
	
	
	* Order Events. If event 1 is missing but event 3 presents, move event 3 up. Same if event 2 is missing but event 3 presents
	gen event_1_miss = mi(event_name1) & !mi(event_name3)
	gen event_2_miss = mi(event_name2) & !mi(event_name3)
	
	replace event_name1				= event_name3			if event_1_miss == 1
	replace event_days1				= event_days3			if event_1_miss == 1
	replace event_expand_days1		= event_expand_days3	if event_1_miss == 1
	replace event_startdate1		= event_startdate3		if event_1_miss == 1
	replace event_enddate1			= event_enddate3		if event_1_miss == 1
	replace event_location1			= event_location3		if event_1_miss == 1
	replace event_attend1			= event_attend3			if event_1_miss == 1
	replace event_back_date1		= event_back_date3		if event_1_miss == 1
	replace event_pressure1			= event_pressure3		if event_1_miss == 1
	replace event_done_date1		= event_done_date3		if event_1_miss == 1
	
	replace event_name3			= . if event_1_miss == 1
	replace event_days3			= . if event_1_miss == 1
	replace event_expand_days3	= . if event_1_miss == 1
	replace event_startdate3	= . if event_1_miss == 1
	replace event_enddate3		= . if event_1_miss == 1
	replace event_location3		= . if event_1_miss == 1
	replace event_attend3		= . if event_1_miss == 1
	replace event_back_date3	= . if event_1_miss == 1
	replace event_pressure3		= . if event_1_miss == 1
	replace event_done_date3	= . if event_1_miss == 1

	replace event_name2				= event_name3			if event_2_miss == 1
	replace event_days2				= event_days3			if event_2_miss == 1
	replace event_expand_days2		= event_expand_days3	if event_2_miss == 1
	replace event_startdate2		= event_startdate3		if event_2_miss == 1
	replace event_enddate2			= event_enddate3		if event_2_miss == 1
	replace event_location2			= event_location3		if event_2_miss == 1
	replace event_attend2			= event_attend3			if event_2_miss == 1
	replace event_back_date2		= event_back_date3		if event_2_miss == 1
	replace event_pressure2			= event_pressure3		if event_2_miss == 1
	replace event_done_date2		= event_done_date3		if event_1_miss == 1
	
	replace event_name3			= . if event_2_miss == 1
	replace event_days3			= . if event_2_miss == 1
	replace event_expand_days3	= . if event_2_miss == 1
	replace event_startdate3	= . if event_2_miss == 1
	replace event_enddate3		= . if event_2_miss == 1
	replace event_location3		= . if event_2_miss == 1
	replace event_attend3		= . if event_2_miss == 1
	replace event_back_date3	= . if event_2_miss == 1
	replace event_pressure3		= . if event_2_miss == 1
	replace event_done_date3	= . if event_2_miss == 1
	
	drop event_1_miss
	drop event_2_miss

	save "$temp/02_shock_module_cleaned_merged_hw.dta" , replace
