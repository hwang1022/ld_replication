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
	}
			
	*Specify specific subfolder:
	global dir "$data/07. Data/3. Main Study 3.0/"
	
	program main
		use "$raw/01b_phase2act_joblist_named.dta", clear
		cleaning
		saveold "$temp/02b_phase2act_joblist_cleaned.dta", replace
		drop_incomplete
		sort pid date
		order pid date stand 
		saveold "$temp/03b_phase2act_joblist_cleaned_completed.dta", replace
	end
	
*****************************************
*Codes Starts
*****************************************

	program cleaning
		// LC, 3-6-22
		replace joblist_accept_20000 = 0 if key == "uuid:ee67d3d4-10f4-4d91-b5a2-be9aad7bf787" // 545
		drop if key == "uuid:12b1f437-5aff-4b18-b895-80330069bb88"        // 523, unable to identify switch point
		
				
		//NL, 28-06-2022, merging for treatment status
		*dropping duplicate observation, one is a new elicitation and other is old. Dropping the new one
		drop if key=="uuid:ae781974-9373-434a-9fe9-d29f949de6fc"
		
		merge m:1 pid using "$raw/ls_randomization_master.dta" , keepusing(treatment)
		keep if _merge==3
			
		
		//NL, 28-06-2022, generating a variable for the new elicitation	
		gen new_elicitation=1 if date>td(26june2022)
		replace new_elicitation=0 if new_elicitation==.
		
		//NL, 01-07-2022, replacing for the missing entries
		replace joblist_accept_20000 = 0 if key=="uuid:fb3f345b-b953-4969-ac68-e32bda02504e"
		replace joblist_accept_20000 = 0 if key=="uuid:491f3f34-662a-4d8e-9d9a-2ca9d5d04a11"
		replace joblist_accept_20000 = 0 if key=="uuid:20590886-d99e-4757-94cd-81b705ea2435"
		replace joblist_accept_20000 = 0 if key=="uuid:6d09be4d-d124-49ef-b161-fbb558216b5e"
		replace joblist_accept_20000 = 0 if key=="uuid:75832ccf-9b71-40ec-b684-0e1f5e03a619"

		
		//NL, 02-08-2022, replace stand values
		local pid 121 126 141 159 163 169 170 180 2108 2110 2112 2129 2136 2144 2149
		foreach pid in `pid'{
		replace stand=1 if pid==`pid'
		}
		replace stand=3 if pid==315
		
	end
	
	program drop_incomplete
		keep if check_completion == 1
	
	end

	
main
	
	*Done! 
	
