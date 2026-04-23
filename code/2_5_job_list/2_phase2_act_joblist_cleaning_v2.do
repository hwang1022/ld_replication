**************************************************
*Project: LD Main Study
*Purpose: Phase 2 activity - vignettes Renaming  
*Author: Luisa
*Last modified: 03-06-2022 (LC)
**************************************************

	clear all
	set more off
	program drop _all

************************************************	
*0. Initial setup
************************************************
	
		
	*Specify general Dropbox LD folder:
	
	if "$master" == "running" { // everything is already specified in master do file
		}
	
	else {
							
		* Choosing from: 
		if "`c(username)'" == "Alosias" {
				global data "D:/Dropbox/Labor Discipline"
			} 
		if "`c(username)'" == "luisacefala" {
				global data "/Users/luisacefala/Dropbox/Labor Discipline"
			} 
		if "`c(username)'" == "Vasanthi" {
				global data "C:/Users/Vasanthi/Dropbox/Labor Discipline"
			} 
		if "`c(username)'" == "Niveditha LN" {
				global data"C:/Users/Niveditha LN/Dropbox/Labor Discipline"
			}
		if "`c(username)'" == "Lenovo" {
				global data"C:/Users/Lenovo/Dropbox/Labor Discipline"
			}
	}
			
	*Specify specific subfolder:
	global dir "$data/07. Data/3. Main Study 3.0/"
	
	program main
		use "$raw/01b_phase2act_joblist_named_v2.dta", clear
		cleaning
		saveold "$temp/02b_phase2act_joblist_cleaned_v2.dta", replace
		drop_incomplete
		sort pid date
		order pid date stand 
		saveold "$temp/03b_phase2act_joblist_cleaned_completed_v2.dta", replace
	end
	
*****************************************
*Codes Starts
*****************************************

	program cleaning
		
		gen jl_choice1_fixed=1 if jl_choice1_fixed_vs_stand ==1
		gen jl_choice1_stand=1 if jl_choice1_fixed_vs_stand ==2
		replace jl_choice1_stand=0 if  jl_choice1_stand==.
		replace jl_choice1_fixed=0 if  jl_choice1_fixed==.
		
		
		
		//dropping duplicate entry (NL)
		drop if key== "uuid:0f2cd4e8-ab29-4d0f-9d81-2507568a9432"
		drop if key== "uuid:81072703-2af6-40a7-8dae-ecbf25644db9"
		drop if key=="uuid:329db8d2-d1e7-49eb-bd41-0a1ad483a5f6"
		
		isid pid 
		
	end
	
	program drop_incomplete
		
		
		keep if check_completion == 1
	
	end
	
	
main
	
	*Done! 
	
