**************************************************
**************************************************
*Project: LD Main Study
*Purpose: Employers Survey v1 Cleaning
*Author: HW Jan 30 2025
*Last modified: HW Jan 30 2025
**************************************************	
**************************************************
	
	
*****************	
**# Create Data
*****************

	use "$temp/ls_employers_survey_v1_renamed.dta" , clear
	append using "$temp/ls_employers_survey_v2_renamed.dta"
	append using "$temp/ls_employers_survey_v3_renamed.dta"
	
	
	gsort recruiter_id -date
	duplicates drop recruiter_id , force

	
	merge 1:1 recruiter_id using "$temp/ls_employers_survey_avadi_v1_renamed.dta" , keep(1 3 4 5) update replace nogen
	merge 1:1 recruiter_id using "$temp/ls_employers_survey_avadi_v2_renamed.dta" , keep(1 3 4 5) update replace nogen
	
	
	
	
	
********************
**# Combine Rec Em
********************

	clonevar comb_how_find_worker 			= rec_how_find_worker
	clonevar comb_how_find_stand 			= rec_how_find_stand
	clonevar comb_how_find_call 			= rec_how_find_call
	clonevar comb_how_find_frnd 			= rec_how_find_frnd
	clonevar comb_how_find_migrant 			= rec_how_find_migrant
	clonevar comb_how_find_contractor 		= rec_how_find_contractor
	clonevar comb_how_find_others 			= rec_how_find_others
	
	
	replace comb_how_find_worker 			= em_how_find_worker			if mi(comb_how_find_worker)
	replace comb_how_find_stand 			= em_how_find_stand				if mi(comb_how_find_stand)
	replace comb_how_find_call 				= em_how_find_call				if mi(comb_how_find_call)
	replace comb_how_find_frnd 				= em_how_find_frnd				if mi(comb_how_find_frnd)
	replace comb_how_find_migrant 			= em_how_find_migrant			if mi(comb_how_find_migrant)
	replace comb_how_find_contractor 		= em_how_find_contractor		if mi(comb_how_find_contractor)
	replace comb_how_find_others 			= em_how_find_others			if mi(comb_how_find_others)
	

	
	foreach i in 	last_30days_laborstand_hire	day_min_hire_from_stand day_max_hire_from_stand 10day_contract_absent_days	///
					sk_bonus_vs_daily_wage sk_bonus_vs_daily_wage_500 sk_bonus_vs_daily_wage_max ///
					same_workers same_workers_others_spec 10_worker_morethan_1day hire_reg_worker why_not_reg ///
					why_not_reg_notregular why_not_reg_stophard why_not_reg_tired why_not_reg_demendhigher why_not_reg_others {
		clonevar 	comb_`i' = rec_`i'
		replace 	comb_`i' = em_`i' if mi(comb_`i')
						
	}
	

	
	foreach i in 	current_how_many_workers stand_hire_1day stand_hire_more1day avg_days_more1day reg_worker_offer_multiday ///
					how_more_multiday_need relay_worker_hiring_change relay_more_training  relay_offer_benefits relay_skill_project ///
					relay_expand_business relay_inkind_gifts relay_intrest_free_loans relay_pay_school_fees relay_none relay_others ///
					relay_others_spec hire_buffer_workers hire_buffer_workers_howmany reg_work_inc_pdivity_earn {
		clonevar 	comb_`i' = rec_`i'
		replace 	comb_`i' = em_`i' if mi(comb_`i')
						
	}	
	

	
	foreach i in 	hire_migrant_workers why_migrant_workers mig_worker_come_everyday mig_worker_ontime mig_worker_lower_wages ///
					mig_worker_work_hard mig_worker_follow_rules mig_worker_others mig_workers_others_spec how_find_worker_urgent ///
					urgent_hire_outsiders urgent_hire_reliable urgent_hire_more urgent_pay_more {
		clonevar 	comb_`i' = rec_`i'
		replace 	comb_`i' = em_`i' if mi(comb_`i')
						
	}
	
	
	save "$final/ls_employers_survey_combined.dta" , replace
