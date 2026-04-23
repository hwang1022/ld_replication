**************************************************
* Project: LD Main Study
* Purpose: Phase 2 activity - flexibility test cleaning
* Author: HW
* Last modified: 2025-05-08 (HW)
**************************************************




********
**# V2
********

	use "$temp/03c_phase2act_flextest_cleaned_completed_v2.dta", clear
	
	gen 	fixed_choice_q1 = 1     if  contract_choice_q1 == 1
	replace fixed_choice_q1 = 0     if  contract_choice_q1 == 2
	
	gen     fixed_choice_q2 = 1     if  contract_choice_q2 == 1
	replace fixed_choice_q2 = 0     if  contract_choice_q2 == 2
	

	foreach x in first second {
		gen     `x'_day1 = 1 if `x'_day == "Monday"
		replace `x'_day1 = 2 if `x'_day == "Tuesday"
		replace `x'_day1 = 3 if `x'_day == "Wednesday"
		replace `x'_day1 = 4 if `x'_day == "Thursday"
		replace `x'_day1 = 5 if `x'_day == "Friday"
		replace `x'_day1 = 6 if `x'_day == "Saturday"
		drop  `x'_day
		rename  `x'_day1  `x'_day
	}
		
	

	label define day_label 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday" , replace
	label value first_day day_label
	label value second_day day_label
	
	label var fixed_choice_q1    "=1 if fixed days was the choice in Q1"
	label var fixed_choice_q2     "=1 if fixed days was the choice in Q2"
	
	label var first_day "Flex test - first day of week"
	label var second_day "Flex test - second day of week"
	
	
	gen flex_version = 2
	
	keep pid date fixed_choice_q1 fixed_choice_q2 first_day second_day flex_version

	save "$temp/04c_phase2act_flextest_makevar_tmp_v2.dta", replace





********
**# V1
********

	use "$temp/03c_phase2act_flextest_cleaned_completed.dta", clear
	
	gen 	fixed_choice_q1 = 1     if  contract_choice == 1
	replace fixed_choice_q1 = 0     if  contract_choice == 2
	
	foreach x in first second {
		gen     `x'_day1 = 1 if `x'_day == "Monday"
		replace `x'_day1 = 2 if `x'_day == "Tuesday"
		replace `x'_day1 = 3 if `x'_day == "Wednesday"
		replace `x'_day1 = 4 if `x'_day == "Thursday"
		replace `x'_day1 = 5 if `x'_day == "Friday"
		replace `x'_day1 = 6 if `x'_day == "Saturday"
		drop  `x'_day
		rename  `x'_day1  `x'_day
	}
		
	
	label define day_label 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday" , replace
	label value first_day day_label
	label value second_day day_label
	
	label var fixed_choice_q1    "=1 if fixed days was the choice in Q1"
	
	label var first_day "Flex test - first day of week"
	label var second_day "Flex test - second day of week"
	
	gen flex_version = 1
	
	keep pid date fixed_choice_q1 first_day second_day flex_version


	save "$temp/04c_phase2act_flextest_makevar_tmp_v1.dta", replace
	
	
	
*************	
**# Combine
*************

	use "$temp/04c_phase2act_flextest_makevar_tmp_v2.dta", clear
	append using "$temp/04c_phase2act_flextest_makevar_tmp_v1.dta"

	save "$temp/05c_phase2act_flextest_combined.dta" , replace
	
	




