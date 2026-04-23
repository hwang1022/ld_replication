    use  "$ld_dir/07. Data/3. Main Study 3.0/02. Cleaning Data/06a. Phase 2 Activities/02. Output/06c_phase2act_flextest_combined_makevar.dta", clear
	assert phase==2 //always done in phase 2
  	isid pid flex_question, missok //data is at the pid-question level 
  		* missing values as some did not do survey (miss_flextest)
	rename flex_ann_date date //rename date variable for merge
	merge m:1 pid date using "$ld_dir/07. Data/3. Main Study 3.0/02. Cleaning Data/Analysis Prep/02. Output/temp_shocks.dta"
	assert miss_flextest==1 if _merge==1
	drop if _merge==2 
	drop _merge 
	
	* weights
	egen temp1 = seq(), by(pid)
	egen num_obs = max(temp1), by(pid)
	drop temp1
	
	label var treatXpost_attendloo_b25 "Treatment x Post shock"
	eststo clear 
	eststo: reg fixed_choice_q f_treatment  i.flex_version i.strata i.first_day i.second_day [w=num_obs], clu(pid)
	sum fixed_choice_q if f_treatment == 0 & e(sample)
	estadd scalar y_mean=r(mean)
	estadd local strata          "Yes", replace
	estadd local stand           "Yes", replace
	* shock heterogeneity
	eststo: reg fixed_choice_q f_treatment treatXpost_attendloo_b25 post_attendloo_b25 treatXfirstwk_attendloo_b25 firstwk_attendloo_b25 i.standid i.strata i.first_day i.second_day [w=num_obs], clu(pid)
	sum fixed_choice_q if f_treatment == 0 & e(sample)
	estadd scalar y_mean=r(mean)
	estadd local strata          "Yes", replace
	estadd local stand           "Yes", replace

	esttab using "${output_overleaf}/tables/flex_fixed_choice_attendloo_b25.tex" , se(3) replace keep(f_treatment treatXpost_attendloo_b25) stats(y_mean N, labels("Control mean" "N: worker-question"))  l nonotes frag cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) nostar collabels(none) nonum nomti