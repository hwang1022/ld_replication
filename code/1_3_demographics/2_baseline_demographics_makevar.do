************************************************
************************************************
*	Project: LD Main Study
*	Script : 03_baseline_demographics_makevar
*	Purpose: Processing demographic survey variables for analysis
*	Author : Luisa
*	Last last modified: 2024-03-27 (YS)
*	Last modified: 2024-11-08 (HW)
************************************************
************************************************


*******************
**# 1.  Open data
*******************

	use "$temp/03_bs_demographics_completed_cleaned.dta", clear



****************************
**# 2.  Generate variables
****************************

* Fix launchset variable (added 2024-04-22)
	* Based on discussion with Luisa, treat this dataset as the most accurate
	preserve 
	use "$raw/launch_prefill_pidwise_2022.dta", clear
	isid pid 
	keep pid launchset batch 
	rename launchset launchset_op 
	rename batch batch_op 
	tempfile pid_ops
	save `pid_ops'
	restore 

	merge m:1 pid using `pid_ops'
	assert _merge !=1
	drop if _merge==2 // from using data
	drop _merge 
	* the launchset variable is inconsistent in some cases 
	corr launchset launchset_op
	count if launchset!=launchset_op
		* 37 obs 
	* the batch variable is consistent
	// corr batch batch_op					HW commented out on Jul 23 because there is no batch variable
	// count if batch!=batch_op				HW commented out on Jul 23 because there is no batch variable
		* 0 obs 

	replace launchset = launchset_op if launchset!=launchset_op & launchset_op!=.
	drop launchset_op batch_op 



****
**## Dem survey part 1
****
	    
	// Commute accompanied by anyone? 
		split(bs_dem_stand_accomp_who)
		local pvars = r(nvars)
		local withwhom "alone friend spouse child parent other"
		foreach var in `withwhom' {
			gen bs_dem_commute_w_`var' = 0 if !mi(bs_dem_stand_accomp_who)
			label var bs_dem_commute_w_`var' "Commute with - `var'" 
		}
		
		forv i = 1/`pvars' {
			destring bs_dem_stand_accomp_who`i', replace
			* Generate dummies
			replace bs_dem_commute_w_alone   = 1 if bs_dem_stand_accomp_who`i' == 1 
			replace bs_dem_commute_w_friend  = 1 if bs_dem_stand_accomp_who`i' == 2 | bs_dem_stand_accomp_who`i' == 3
			replace bs_dem_commute_w_spouse  = 1 if bs_dem_stand_accomp_who`i' == 4 
			replace bs_dem_commute_w_child   = 1 if bs_dem_stand_accomp_who`i' == 5 
			replace bs_dem_commute_w_parent  = 1 if bs_dem_stand_accomp_who`i' == 6 
			replace bs_dem_commute_w_other   = 1 if bs_dem_stand_accomp_who`i' == 998 
			drop bs_dem_stand_accomp_who`i'
		}
		
	// Stand jobs
		split(bs_dem_stand_job)
		local qvars = r(nvars)
		local job foundation centering ///
				  concrete demolish loading ///
				  welder painting carpenter tile_work wall_build stone_cut ///
				  agri fisheries electrician plumber scavenger ///
				  maid cargo loadman rikshaw_pull porter tailor /// 
				  textile factory technician auto ///
				  car cleaning scaffolding gardening 

		foreach var in `job' {
			gen bs_dem_job_`var' = 0 if !mi(bs_dem_stand_job)
			label var bs_dem_job_`var' "Stand jobs - `var'" 
		}				  

		forval i = 1/`qvars' {
			destring bs_dem_stand_job`i', replace
			* Generate dummies
			replace bs_dem_job_foundation  = 1 if bs_dem_stand_job`i' == 1 
			replace bs_dem_job_centering   = 1 if bs_dem_stand_job`i' == 2 
			replace bs_dem_job_concrete    = 1 if bs_dem_stand_job`i' == 3 
			replace bs_dem_job_demolish    = 1 if bs_dem_stand_job`i' == 4 
			replace bs_dem_job_loading	   = 1 if bs_dem_stand_job`i' == 5 
			replace bs_dem_job_welder      = 1 if bs_dem_stand_job`i' == 6 
			replace bs_dem_job_painting    = 1 if bs_dem_stand_job`i' == 7 
			replace bs_dem_job_carpenter   = 1 if bs_dem_stand_job`i' == 8 
			replace bs_dem_job_tile_work   = 1 if bs_dem_stand_job`i' == 9 
			replace bs_dem_job_wall_build  = 1 if bs_dem_stand_job`i' == 10 
			replace bs_dem_job_stone_cut   = 1 if bs_dem_stand_job`i' == 11
			replace bs_dem_job_agri        = 1 if bs_dem_stand_job`i' == 12 
			replace bs_dem_job_fisheries   = 1 if bs_dem_stand_job`i' == 13 
			replace bs_dem_job_electrician = 1 if bs_dem_stand_job`i' == 14 
			replace bs_dem_job_plumber     = 1 if bs_dem_stand_job`i' == 15 
			replace bs_dem_job_scavenger   = 1 if bs_dem_stand_job`i' == 16 
			replace bs_dem_job_maid        = 1 if bs_dem_stand_job`i' == 17 
			replace bs_dem_job_cargo       = 1 if bs_dem_stand_job`i' == 18 
			replace bs_dem_job_loadman     = 1 if bs_dem_stand_job`i' == 19 
			replace bs_dem_job_rikshaw_pull= 1 if bs_dem_stand_job`i' == 20 
			replace bs_dem_job_porter      = 1 if bs_dem_stand_job`i' == 21 
			replace bs_dem_job_tailor      = 1 if bs_dem_stand_job`i' == 22 
			replace bs_dem_job_textile     = 1 if bs_dem_stand_job`i' == 23 
			replace bs_dem_job_factory     = 1 if bs_dem_stand_job`i' == 24 
			replace bs_dem_job_technician  = 1 if bs_dem_stand_job`i' == 25 
			replace bs_dem_job_auto        = 1 if bs_dem_stand_job`i' == 26 
			replace bs_dem_job_car         = 1 if bs_dem_stand_job`i' == 27 
			replace bs_dem_job_cleaning    = 1 if bs_dem_stand_job`i' == 28 
			replace bs_dem_job_scaffolding = 1 if bs_dem_stand_job`i' == 29
			replace bs_dem_job_gardening   = 1 if bs_dem_stand_job`i' == 30 
			drop bs_dem_stand_job`i'
		}

	// Reasons for not preferring long-term jobs
		gen bs_dem_informaljob = bs_dem_no_ltjob_reasons if bs_dem_lngterm_work < 4
		replace bs_dem_informaljob = bs_dem_yes_ltjob_neg_reasons if bs_dem_lngterm_work > 3 & !mi(bs_dem_lngterm_work)
		
		split(bs_dem_informaljob)
		local qvars = r(nvars)
		local reasons flex daily_earn prof_pref free_time noboss noqual other
		foreach var in `reasons' {
			gen bs_dem_informaljob_`var' = 0 if !mi(bs_dem_informaljob)
		}				  

		forval i = 1/`qvars' {
			destring bs_dem_informaljob`i', replace
			* Generate dummies
			replace bs_dem_informaljob_flex       = 1 if bs_dem_informaljob`i' == 1 
			replace bs_dem_informaljob_daily_earn = 1 if bs_dem_informaljob`i' == 2 
			replace bs_dem_informaljob_prof_pref  = 1 if bs_dem_informaljob`i' == 3 
			replace bs_dem_informaljob_free_time  = 1 if bs_dem_informaljob`i' == 4 
			replace bs_dem_informaljob_noboss     = 1 if bs_dem_informaljob`i' == 5 
			replace bs_dem_informaljob_noqual     = 1 if bs_dem_informaljob`i' == 6
			replace bs_dem_informaljob_other      = 1 if bs_dem_informaljob`i' == 998 
			drop bs_dem_informaljob`i'
		}
		
	// Obligations
		gen bs_dem_no_morning_obligation = 1 - bs_dem_obligation if !mi(bs_dem_obligation)
		replace bs_dem_no_morning_obligation = 1 if dsh_3 == 6 // this is redundant for some obs as it was already asked under bs_dem_obligation
		replace bs_dem_no_morning_obligation = 0 if !mi(dsh_3) & dsh_3 != 6
		replace bs_dem_no_morning_obligation = 1 if dsh_3_mod_6 == 1 // this should also be redundant
		replace bs_dem_no_morning_obligation = 0 if !mi(bs_dem_obligation_mod) & dsh_3_mod_6 == 0
		
	// Possible to adjust
		gen bs_dem_possible_to_adjust = 1 if dsh_3_mod_2 == 4
		replace bs_dem_possible_to_adjust = 1 if dsh_3_mod_2 == 5
		replace bs_dem_possible_to_adjust = 0 if !mi(dsh_3_mod_2) & bs_dem_possible_to_adjust == .
		label var bs_dem_possible_to_adjust "Possible or easy for respondent to adjust"

		label var dsh_3_mod_1 "Dropping kids off at school"
		label var dsh_3_mod_2 "Fetching water"
		label var dsh_3_mod_3 "Preparing food"
		label var dsh_3_mod_4 "Prayers/rituals"
		label var dsh_3_mod_5 "Any other"
		
	

****
**## Dem survey part 2
****

	// Management during rainy days	
		split(bs_dem_rain_manage)
		local rvars = r(nvars)
		local manage native outside_stand loans savings lower_wages

		foreach var in `manage' {
			gen bs_dem_manage_`var' = 0 if !mi(bs_dem_rain_manage)
			label var bs_dem_manage_`var' "Manage - `var'" 
		}	
		
		forv i = 1/`rvars' {
			destring bs_dem_rain_manage`i', replace
			* Generate dummies
			replace bs_dem_manage_native         = 1 if bs_dem_rain_manage`i' == 1 
			replace bs_dem_manage_outside_stand  = 1 if bs_dem_rain_manage`i' == 2
			replace bs_dem_manage_loans          = 1 if bs_dem_rain_manage`i' == 3
			replace bs_dem_manage_savings        = 1 if bs_dem_rain_manage`i' == 4
			replace bs_dem_manage_lower_wages    = 1 if bs_dem_rain_manage`i' == 5
			drop bs_dem_rain_manage`i'
			
		}
		
	// Who lives with the participant?
		split(bs_dem_live_with)
		local svars= r(nvars)
		local live family relatives friends
		foreach var in `live' {
			gen bs_dem_live_`var' = 0 if !mi(bs_dem_live_with)
			label var bs_dem_live_`var' "Stay with - `var'" 
		}	
		forval i = 1/`svars' {
			destring bs_dem_live_with`i', replace
			* Generate dummies
			replace bs_dem_live_family    = 1 if bs_dem_live_with`i' == 1 
			replace bs_dem_live_relatives = 1 if bs_dem_live_with`i' == 2
			replace bs_dem_live_friends   = 1 if bs_dem_live_with`i' == 3
			drop bs_dem_live_with`i'
		}
		
	// Others who earn
		split(bs_dem_others_earn)
		local tvars= r(nvars)
		local otherearn nobody spouse children sibling parents
		
		foreach var in `otherearn' {
			gen bs_dem_otherearn_`var' = 0 if !mi(bs_dem_others_earn)
			label var bs_dem_otherearn_`var' "Others earn - `var'" 
		}	

		forv i = 1/`tvars' {
			destring bs_dem_others_earn`i', replace
			}
			
		forv i = 1/`tvars' {
			* Generate dummies
			replace bs_dem_otherearn_nobody    = 1 if bs_dem_others_earn`i' == 1
			replace bs_dem_otherearn_spouse    = 1 if bs_dem_others_earn`i' == 2
			replace bs_dem_otherearn_children  = 1 if bs_dem_others_earn`i' == 3
			replace bs_dem_otherearn_sibling   = 1 if bs_dem_others_earn`i' == 4
			replace bs_dem_otherearn_parents   = 1 if bs_dem_others_earn`i' == 5
			drop bs_dem_others_earn`i'
		}
		 
	// Have a family
		 gen bs_dem_has_family = 0
		 replace bs_dem_has_family = 1 if bs_dem_marital_st == 2
		 replace bs_dem_has_family = 1 if inlist(bs_dem_marital_st, 3, 4) & bs_dem_children == 1
		label var bs_dem_has_family "Has a spouse or children"

	replace bs_dem_no_children = 0 if bs_dem_no_children == .
	capture rename dem_sum_job_found_at_stand dem_sum_job_at_stand



	
********************************
**# 3. 	Gen Analysis Variables
********************************

	forval i = 1/6 {
		
		gen bs_dem_no_ltjob_`i' = .
		replace bs_dem_no_ltjob_`i'= 0 if !mi(bs_dem_no_ltjob_reasons) | !mi(bs_dem_lngterm_network)
		replace bs_dem_no_ltjob_`i'= 1 if strpos(bs_dem_no_ltjob_reasons, "`i'")
		replace bs_dem_no_ltjob_`i'= 1 if bs_dem_lngterm_network == `i'
		
	}
	
	

*******************
**# 4.  Save data
*******************


	* HW Nov 2024: Currently only keep bs_dem_*
	keep pid bs_dem_*
	
	isid pid 
	save "$temp/03_bs_demographics_completed_makevar.dta", replace
