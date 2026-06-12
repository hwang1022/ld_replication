************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Stand Size Estimate
* 	Author:				HW 
* 	Created:			2025-May-30 (HW)
* 	Last modified:		2025-May-30 (HW)
************************************************************
************************************************************

	local baseline_panel "$temp/04_baseline_makepanel_no_limit_date.dta"

*************************************
**# 1. Estimating Survival Function
*************************************

	use "$temp/survival_function_data.dta" , clear
	gen arrived_by_8 = spot_time_hours <= 8
	gen event = 1

	* Create empty dataset to store results
	preserve
		clear
		set obs 0
		gen stand = .
		gen arrived_by_8 = .
		gen found_job = .
		gen streg_coeff = .
		
		* Save empty results dataset
		tempfile results
		save `results'
	restore

	* Get all levels of stand
	qui levelsof stand
	local stand_levels `r(levels)'
	
	* Counter for progress tracking
	local counter = 0
	local total_combinations : word count `stand_levels'
	local total_combinations = `total_combinations' * 2 * 2
	
	di "Running streg for `total_combinations' combinations..."
	
	* Loop through all combinations
	foreach s in `stand_levels' {
		forval a = 0/1 {
			forval j = 0/1 {
				local counter = `counter' + 1
				di "Processing combination `counter'/`total_combinations': stand=`s', arrived_by_8=`a', found_job=`j'"
				
				preserve
					* Filter data for current combination (fixed bug: use loop variables)
					keep if stand == `s' & arrived_by_8 == `a' & found_job == `j' & time_at_stand_t > 0
					
					* Set up survival data and run streg
					gsort -time_at_stand_t
					gen pct = (_n-1)/_N

					keep time_at_stand_t pct
					count if !mi(time_at_stand_t)
					set obs `= r(N) + 1'
					replace time_at_stand_t = 0 in `= r(N) + 1'
					replace pct = 1 in `= r(N) + 1'

					generate F = 1 - pct
					regress F time_at_stand_t, noconstant 
					
					* Store coefficient
					local coeff = r(table)[1,1]
					
					* Store as global macro with specified naming convention
					global lambda_s`s'_e`a'_f`j' = `coeff'
				restore
				
				* Append result to results dataset
				preserve
					use `results', clear
					local new_obs = _N + 1
					set obs `new_obs'
					replace stand = `s' in `new_obs'
					replace arrived_by_8 = `a' in `new_obs'
					replace found_job = `j' in `new_obs'
					replace streg_coeff = `coeff' in `new_obs'
					save `results', replace
				restore
			}
		}
	}

	use `results', clear
	save "$temp/streg_results_dataset.dta", replace




*************************************
**# 2. Prepare Data for Calculation
*************************************

	use "$temp/stand_strength.dta" , clear
	collapse (mean)time_6_00-time10_00 , by(stand)

	* Rename time variables to p_1, p_2, etc. based on order
	rename time_6_00 p_0
	rename time_6_30 p_1
	rename time_7_00 p_2
	rename time_7_30 p_3
	rename time_7_45 p_4
	rename time_8_00 p_5
	rename time_8_15 p_6
	rename time_8_30 p_7
	rename time_8_45 p_8
	rename time_9_00 p_9
	rename time_9_30 p_10
	rename time10_00 p_11
	
	* Create hour variables corresponding to each time period
	gen t_0 = 6
	gen t_1 = 6.5
	gen t_2 = 7
	gen t_3 = 7.5
	gen t_4 = 7.75
	gen t_5 = 8
	gen t_6 = 8.25
	gen t_7 = 8.5
	gen t_8 = 8.75
	gen t_9 = 9
	gen t_10 = 9.5
	gen t_11 = 10

	forval i = 0/11 {
		order t_`i' , after(p_`i')
	}

	save "$temp/calculate_stand_size.dta" , replace


*************************
**# 3. Job Finding Rate
*************************

	* Load job finding rates by stand and arrival time
	use "$temp/survival_function_data.dta" , clear
	gen arrived_by_8 = spot_time_hours <= 8
	
	* Calculate job finding rates (π) by stand and arrival group
	preserve
		collapse (mean) found_job , by(stand arrived_by_8)
		gen pi_value = found_job
		drop found_job
		
		* Store as global macros
		qui levelsof stand
		foreach s in `r(levels)' {
			qui sum pi_value if stand == `s' & arrived_by_8 == 1
			global pi_s`s'_early = r(mean)
			
			qui sum pi_value if stand == `s' & arrived_by_8 == 0
			global pi_s`s'_late = r(mean)
		}
	restore
	

*****************************
**# 4. Calculate Stand Size
*****************************

	* Now implement the stand size calculation algorithm
	use "$temp/calculate_stand_size.dta" , clear
	
	* Create variables to store results
	gen raw_stand_size = .
	
	* Create variables to store N_i (new arrivals at each time period)
	forval i = 0/11 {
		gen n_`i' = .
	}
	
	* Loop through each stand
	qui levelsof stand
	local stand_levels `r(levels)'
	
	foreach s in `stand_levels' {
		di "Calculating stand size for stand `s'"
		
		preserve
			keep if stand == `s'
			
			* Initialize arrays for N_i (new arrivals) and P_i (observed people)
			forval i = 0/11 {
				local P_`i' = p_`i'[1]
				local t_`i' = t_`i'[1]
			}
			
			* N_0 = P_0 by assumption
			local N_0 = `P_0'
			
			* Calculate N_i for i = 1 to 11 using the iterative formula
			forval i = 1/11 {
				local survivors_sum = 0
				
				* Sum survivors from all previous arrival cohorts
				forval j = 0/`=`i'-1' {
					local time_diff = `t_`i'' - `t_`j''
					
					* Determine if arrival time j is early (≤8) or late (>8)
					if `t_`j'' <= 8 {
						local group = "early"
					}
					else {
						local group = "late"
					}
					
					* Calculate survival probability using composite survival function
					* S_g(t) = π_g × S_found,g(t) + (1-π_g) × S_not,g(t)
					* where S_f,g(t) = exp(-λ_f,g × t)
					
					local pi = ${pi_s`s'_`group'}
					local lambda_found = ${lambda_s`s'_e`=(`t_`j'' <= 8)'_f1}
					local lambda_not = ${lambda_s`s'_e`=(`t_`j'' <= 8)'_f0}
					
					local survival_found = max(1-`lambda_found' * `time_diff',0)
					local survival_not = max(1-`lambda_not' * `time_diff',0)
					local survival_composite = `pi' * `survival_found' + (1 - `pi') * `survival_not'
					
					local survivors_from_j = `N_`j'' * `survival_composite'
					local survivors_sum = `survivors_sum' + `survivors_from_j'
				}
				
				* N_i = P_i - survivors_sum
				local N_`i' = `P_`i'' - `survivors_sum'
				
				* Ensure N_i is non-negative
				if `N_`i'' < 0 {
					local N_`i' = 0
				}
			}
			
			* Calculate raw stand size = sum of all N_i
			local raw_size = 0
			forval i = 0/11 {
				local raw_size = `raw_size' + `N_`i''
			}
			
			* Store the results in local macros to persist outside preserve-restore
			local raw_size_s`s' = `raw_size'
			forval i = 0/11 {
				local N_`i'_s`s' = `N_`i''
			}
			
		restore
	}
	
	* Apply the calculated results to the dataset
	foreach s in `stand_levels' {
		replace raw_stand_size = `raw_size_s`s'' if stand == `s'
		forval i = 0/11 {
			replace n_`i' = `N_`i'_s`s'' if stand == `s'
		}
	}
	
	save "$temp/estimated_stand_sizes_precorrect.dta", replace



***************************
**# 5. Correct Stand Size
***************************

	preserve
		use "`baseline_panel'" , clear
		drop if inlist(stand,$droplist)
		drop if dow == 0 | holiday == 1
		assert !mi(attend)

		keep pid stand attend

		collapse (mean)attend (first)stand 	, by(pid)
		collapse (mean)attend 				, by(stand)

		gen correction_factor = 1 / attend

		keep stand correction_factor

		tempfile corrections
		save `corrections'
	restore

	* Merge correction factors and apply them
	merge 1:1 stand using `corrections', nogen keep(match)
	
	* Calculate corrected stand size
	gen corrected_stand_size = raw_stand_size * correction_factor
	


******************
**# 6. Save Data
******************

	* Rename
	rename raw_stand_size 			raw_stand_size_lin
	rename corrected_stand_size 	corrected_stand_size_lin

	* Save results
	keep stand correction_factor raw_stand_size_lin corrected_stand_size_lin
	save "$temp/estimated_stand_sizes_lin.dta", replace
