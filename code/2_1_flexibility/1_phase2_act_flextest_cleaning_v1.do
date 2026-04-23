**************************************************
*Project: LD Main Study
*Purpose: Phase 2 activity - flexibility test cleaning
*Author: Luisa
*Last modified: 12-06-2022 (LC)
*HW modified directories in late 2024
**************************************************

	cap program drop main
	program main
		use "$raw/01c_phase2act_flextest_named.dta", clear
		cleaning
		saveold "$temp/03c_phase2act_flextest_cleaned.dta", replace
		finalizing
		sort pid date
		order pid date stand contract_choice* first_day second_day
		save "$temp/03c_phase2act_flextest_cleaned_completed.dta", replace
	end
	
*****************************************
*Codes Starts
*****************************************

	cap program drop cleaning
	program cleaning
		// Duplicate observations
		drop if key == "uuid:55f2d7f8-f064-4754-baf5-bc556b701f50" // 268 - duplicates observation
		drop if key == "uuid:9659ae9a-a371-444c-bea8-5ea7ef66d34c" // 333 - duplicates observation
		drop if key == "uuid:af4d8c15-6c13-46af-a662-3a8585963936" // 311 - duplicates observation
		drop if key == "uuid:3f07a753-c3ca-4f86-aff4-f672e323ed6c" // 328
		drop if key == "uuid:368f95ce-3bce-4056-90e2-dcc33e43cdaf" // 350
		drop if key == "uuid:f47cffea-d885-4448-9e32-22ec2d67f07a" // 354
		// TEMP DROP! for some reasons he doesn't have prefills
		drop if key == "uuid:0a0f5171-aabc-4ab2-b38b-623b16fad16a"
		disp("No corrections so far")
		
	end
	
	cap program drop finalizing
	program finalizing
		gen new_elicitation = !mi(comp_question_1)
		keep if check_completion == 1
	
		isid pid date
	end

	
main

	
