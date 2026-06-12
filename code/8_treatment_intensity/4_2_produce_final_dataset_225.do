************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Create Final Data for Stand Size
* 	Author:				HW 
* 	Created:			2025-May-30 (HW)
* 	Last modified:		2025-May-30 (HW)
************************************************************
************************************************************


***********************
**# 1. Screening Data
***********************

	use "$temp/02_screening_cleaned.dta" , clear
	keep stand rid
	duplicates drop stand rid , force
	drop if inlist(stand,$droplist)

	collapse (count) rid , by(stand)
	lab drop stand_lab
	lab var stand "Stand"
	rename rid num_rid
	lab var num_rid "Num RIDs Surveyed at Screening"
	
	save "$temp/stand_size_sc.dta" , replace


***************************************
**# 2. Number of Treatment Each Stand
***************************************

	use "$temp/00_mainstudy_master.dta"  , clear
	drop if inlist(stand, ${droplist})
	keep if treatment == 1

	keep pid stand
	collapse (count) num_treatment = pid , by(stand)
	cap lab drop p0
	lab var num_treatment "Num Treatment Group at Stand"

	save "$temp/num_treat_by_stand_studysample.dta" , replace




***********************************
**# 3. Merge Estimated Stand Size
***********************************

	merge 1:1 stand using "$temp/estimated_stand_sizes_exp.dta", nogen
	merge 1:1 stand using "$temp/estimated_stand_sizes_lin.dta", nogen
	merge 1:1 stand using "$temp/stand_size_sc.dta", nogen

	drop if mi(raw_stand_size_exp)



****************************
**# 4. Finalize Stand Size
****************************

	gen final_stand_size_exp = max(corrected_stand_size_exp, num_rid)
	gen final_stand_size_lin = max(corrected_stand_size_lin, num_rid)
	gen treat_intensity_exp = num_treatment / final_stand_size_exp
	gen treat_intensity_lin = num_treatment / final_stand_size_lin


	* More or less Intense
	more_or_less treat_intensity_exp , prefix("higher_") ///
		varlab("Higher Stand Treat Intensity") ///
		vallab(0 "Lower Stand Treat Intensity" 1 "Higher Stand Treat Intensity")

	more_or_less final_stand_size_exp , prefix("higher_") ///
		varlab("Higher Stand Size") ///
		vallab(0 "Lower Stand Size" 1 "Higher Stand Size")


	more_or_less treat_intensity_exp , prefix("him_") includemedian ///
		varlab("Higher Stand Treat Intensity (Inc. Median)") ///
		vallab(0 "Lower Stand Treat Intensity" 1 "Higher Stand Treat Intensity")


	more_or_less final_stand_size_exp , prefix("him_") includemedian ///
		varlab("Higher Stand Size (Inc. Median)") ///
		vallab(0 "Lower Stand Size" 1 "Higher Stand Size")


******************
**# 5. Save Data
******************

	lab var stand 							"Stand"
	lab var num_treatment 					"Num Treat Group at Stand"
	lab var raw_stand_size_exp 				"Stand Size, Exp Function, Un-Corrected"
	lab var correction_factor 				"Correction Factor"
	lab var corrected_stand_size_exp 		"Stand Size, Exp Function, Corrected"
	lab var raw_stand_size_lin 				"Stand Size, Linear Function, Un-Corrected"
	lab var corrected_stand_size_lin 		"Stand Size, Linear Function, Corrected"
	lab var num_rid							"Num People Screened at Stand"

	lab var final_stand_size_exp			"Finalized Stand Size, Exp Function"
	lab var final_stand_size_lin			"Finalized Stand Size, Lin Function"

	lab var treat_intensity_exp				"Stand Treatment Intensity, Exp Function"
	lab var treat_intensity_lin				"Stand Treatment Intensity, Lin Function"

	format raw_stand_size_exp-corrected_stand_size_lin final_stand_size_exp final_stand_size_lin %9.2f
	format treat_intensity_exp treat_intensity_lin %9.3f

	order stand num_treatment correction_factor raw_stand_size_exp corrected_stand_size_exp raw_stand_size_lin corrected_stand_size_lin num_rid final_stand_size_exp final_stand_size_lin treat_intensity_exp treat_intensity_lin higher_treat_intensity_exp higher_final_stand_size_exp


	save "$final/stand_size_intensity_studysample.dta" , replace
