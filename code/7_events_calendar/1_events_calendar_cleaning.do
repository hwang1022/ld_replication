************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Clean festival calendar dataset
* 	Author:				HW 
* 	Date created:		2026-May-28 (HW)
* 	Last modified:		2026-May-28 (HW)
************************************************************
************************************************************

	/* 
	Notes on this data (see email with Alosias on 3 September 2024 for more details)

	Data source:  https://www.tamildailycalendar.com/tamil_festival_dates.php?Year=2022

	Variable widely_celebrated (1-5 scale): constructed based on the impression of our team (RAs and Field Team). 1 is an extremely low percentage of people who do it and 5 is an extremely high percentage of people who celebrate in TN. 

	Variable participant_timeoff: constructed based on the impression of our team (RAs and Field Team). indicates whether workers are likely to take time off from work to attend such events, keeping in mind the population at the labor stands 

	Context on the Calendar: We follow both the English calendar (12 months) and the Tamil calendar (12 months) in Tamil Nadu. Regarding Hindu festivals, Panchagam (also called the Hindu calendar) is used to determine the festivals' days and some important moments/times and Hindus follow these systems to worship God. While this calendar lists all Hindu festivals, all were not considered equally important. At the very least, people might visit the temple on these days.

	For festivals that span multiple days (e.g. navratri), the start and end dates have been mentioned with different names. Most of these days, people celebrate both start and end dates as important auspicious days.   

	Are there certain observance days (out of all the full moon days, new moon days, Mugurtham days, and Pradosham days) that are particularly important in a year? 
		- Yes, it's already there on the list (Mahalaya Ammavasai (new moon) and Chitra Poornami (full moon) - some temple conducts special pooja or rituals. Pradosham is not celebrated but based on the horoscope, people do some rituals to get rid of problems. I can add Mugurtham days - Hindu people usually do all the events/functions during these days (marriage, ear piercing, naming, starting a project, starting constructions, etc.)
	*/



***************
**# Call Data
***************

	use "$external/holiday_festival_calendar_2022.dta", clear
	isid date


***********************
**# Variable Creation
***********************

	drop date_str day 
	gen calevent = 1
	label var calevent "The date is a festival / holiday / auspicious day with moon cycle"
	egen calevent_description = concat(festivals holidays moon_time), punct(", ")
	replace calevent_description = subinstr(calevent_description, ", , ", "", .)
	replace calevent_description = regexr(calevent_description, "^, ", "")
	replace calevent_description = regexr(calevent_description, ",$", "")
	replace calevent_description = regexr(calevent_description, ", $", "")
	lab var calevent_description "Description of festival / holiday / auspicious day"

	gen calevent_is_festival = !missing(festivals)
	lab var calevent_is_festival "The date is a festival"
	gen calevent_is_holiday = !missing(holidays)
	lab var calevent_is_holiday "The date is a holiday"
	gen calevent_is_mugurtham = !missing(moon_time)
	lab var calevent_is_mugurtham "The date is a Mugurtham day"

	drop festivals holidays moon_time

	rename widely_celebrated calevent_celebrated_scale 
	label var calevent_celebrated_scale "Scale at which this event is celebrated in TN (1-5)"

	rename participant_timeoff calevent_worker_timeoff 
	label var calevent_worker_timeoff "Worker is likely to take time off work to attend"

	rename hindus_fest calevent_hindu 
	rename christians_fest calevent_christian
	rename muslims_fest calevent_muslim 	
	rename mugurtham_days calevent_auspicious
	label var calevent_auspicious"Auspicious (Mugurtham) days"
	rename tn_holidays calevent_tn 
	rename national_wide_hdays	calevent_nationwide 


***************
**# Save Data
***************

	gen __FEASTIVAL_CALENDAR_____ = .


* Save dataset 
	order date __FEASTIVAL_CALENDAR_____ calevent calevent_is_festival calevent_is_holiday calevent_is_mugurtham calevent_description calevent_celebrated_scale calevent_worker_timeoff calevent_tn calevent_nationwide calevent_auspicious calevent_hindu calevent_christian calevent_muslim
	save "$final/calevents_clean.dta", replace  

