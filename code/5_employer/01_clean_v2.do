**************************************************
**************************************************
*Project: LD Main Study
*Purpose: Employers Survey v2 Cleaning
*Author: HW Jan 24 2025
*Last modified: HW Jan 30 2025
**************************************************	
**************************************************
	
	use "$raw/ls_employers_survey_v2.dta" , clear
	assert r4 == 1
	
************	
**# Rename
************

	* Drop Intro Vars
	drop deviceid-p0_998 p2-p4  mode-r4
	
	
	* Drop PII
	drop ss1 ss1_1
	
	
	* Drop Useless Vars
	drop b4_others count_works-show_draws_count draw_num* unique_draw* z0-endtime count_check*
	 
	
	
	
**## Proceed Introduction

	rename ss2 		intro_role 
	rename ss3     	intro_workex_mestri

	
	
**## Recruiter's Section — Section A: Recruitment Purpose

	rename a1        	rec_how_find_worker
	rename a1_1      	rec_how_find_stand 
	rename a1_2      	rec_how_find_call
	rename a1_3      	rec_how_find_frnd
	rename a1_4      	rec_how_find_migrant
	rename a1_5      	rec_how_find_contractor
	rename a1_998    	rec_how_find_others
	drop a1_others
	
	
	rename a2        	rec_worker_type // Types of work typically do
	rename a2_1      	rec_foundation
	rename a2_2      	rec_wall_bulider
	rename a2_3      	rec_tile_worker
	rename a2_4      	rec_centring
	rename a2_5      	rec_concrete
	rename a2_6      	rec_demolisher
	rename a2_7      	rec_loadman
	rename a2_8      	rec_stone_cutter
	rename a2_9      	rec_welder
	rename a2_10     	rec_painter
	rename a2_11     	rec_carpenter
	rename a2_12     	rec_electrician
	rename a2_13     	rec_plumber
	rename a2_998    	rec_wrk_type_others
	rename a2_others	rec_wrk_type_others_spec
	
	
	
	rename a3_v2     rec_hiring_freq_days
	rename a5        rec_hire_large_co


	
	
**## Recruiter's Section > consent > Section B: Worker Skills
	
	
	rename b5 			rec_balu_sanjay	
	rename b6 			rec_balu_sanjay_why
	rename b7        	rec_last_30days_laborstand_hire
	
	rename b8_1      rec_day_min_hire_from_stand
	rename b8_2      rec_day_max_hire_from_stand
	rename b9        rec_10day_contract_absent_days


	rename b2_250        rec_sk_bonus_vs_daily_wage
	rename b2_500        rec_sk_bonus_vs_daily_wage_500
	rename b2_max        rec_sk_bonus_vs_daily_wage_max
	
	
	
	rename b10	      rec_same_workers 
	rename b10_others rec_same_workers_others_spec


	rename b11            rec_10_worker_morethan_1day
	rename b12            rec_hire_reg_worker
	rename b12_1          rec_why_not_reg
	
	
	
	rename b12_1_1 			rec_why_not_reg_notregular
	rename b12_1_2 			rec_why_not_reg_stophard
	rename b12_1_3 			rec_why_not_reg_tired
	rename b12_1_4 			rec_why_not_reg_demendhigher
	rename b12_1_998 		rec_why_not_reg_others
	drop b12_1_others


	
**## Recruiter's Section > consent > Section C: Multi-Day

	rename c1        rec_current_how_many_workers
	rename c2        rec_stand_hire_1day
	rename c3        rec_stand_hire_more1day  
	
	
	rename c4    	rec_avg_days_more1day
	rename c5   	rec_reg_worker_offer_multiday
	rename c6   	rec_how_more_multiday_need
	
	rename c7        rec_relay_worker_hiring_change
	rename c7_1      rec_relay_more_training 
	rename c7_2      rec_relay_offer_benefits
	rename c7_3      rec_relay_skill_project
	rename c7_4      rec_relay_expand_business
	rename c7_5      rec_relay_inkind_gifts
	rename c7_6      rec_relay_intrest_free_loans
	rename c7_7      rec_relay_pay_school_fees
	rename c7_8      rec_relay_none
	
	rename c7_998 		rec_relay_others
	rename c7_others 	rec_relay_others_spec
	
	
	rename d4       	rec_hire_buffer_workers
	rename d4_1       	rec_hire_buffer_workers_howmany
	
	
	
**## Recruiter's Section > consent > Section E: Migrant Workers

	rename e1_a        rec_hire_migrant_workers
	rename e1_b        rec_why_migrant_workers
	rename e1_b_1      rec_mig_worker_come_everyday
	rename e1_b_2      rec_mig_worker_ontime
	rename e1_b_3      rec_mig_worker_lower_wages
	rename e1_b_4      rec_mig_worker_work_hard
	rename e1_b_5      rec_mig_worker_follow_rules
	rename e1_b_998    rec_mig_worker_others
	rename e1_b_others rec_mig_workers_others_spec

	

	rename e2       rec_how_find_worker_urgent
	rename e2_1     rec_urgent_hire_outsiders
	rename e2_2     rec_urgent_hire_reliable
	rename e2_3     rec_urgent_hire_more
	rename e2_4     rec_urgent_pay_more
	
	
**## Recruiter's Section > Section D: Costs
	
	
	forval i = 1/2{
	rename selected_choice_`i' rec_rpw_work_`i'
	
	rename d1_a_`i' rec_rpw_find_time_`i'
	rename d1_b_`i' rec_rpw_onboard_time_`i'
	rename d1_c_`i' rec_rpw_addnl_cost_`i'
	
	rename d1_c_1_`i' 		rec_rpw_addnl_cost_delay_`i'
	rename d1_c_2_`i' 		rec_rpw_addnl_cost_getalong_`i'
	rename d1_c_3_`i'		rec_rpw_addnl_cost_overtime_`i'
	rename d1_c_998_`i' 	rec_rpw_addnl_cost_others_`i'
	rename d1_c_others_`i'	rec_rpw_addnl_cost_others_spec_`i'
	
	}
	
	rename d1_s1a 			rec_rpw_find_time
	rename d1_s1b 			rec_rpw_onboard_time
	rename d1_s1c 			rec_rpw_addnl_cost
	
	rename d1_s1c_1 		rec_rpw_addnl_cost_delay
	rename d1_s1c_2 		rec_rpw_addnl_cost_getalong
	rename d1_s1c_3			rec_rpw_addnl_cost_overtime
	rename d1_s1c_998 		rec_rpw_addnl_cost_others
	rename d1_s1c_others	rec_rpw_addnl_cost_others_spec
	
	
	rename b3        	rec_sk_pdtivity
	rename b4        	rec_sk_pdivity_why
	
	
	
**## Employer Survey > Section k: Recruitment Purpose
	

	rename k1        em_how_find_worker
	rename k1_1      em_how_find_stand 
	rename k1_2      em_how_find_call
	rename k1_3      em_how_find_frnd
	rename k1_4      em_how_find_migrant
	rename k1_5      em_how_find_contractor
	rename k1_998    em_how_find_others

	rename k2        em_hire_pattern
	
	rename k2_1        em_hire_pattern_occasion
	rename k2_2        em_hire_pattern_regular
	rename k2_3        em_hire_pattern_veryregular
	rename k2_4        em_hire_pattern_freq_or_largeco

	
	rename k3        	em_last_30days_laborstand_hire
	
	rename k4_1      em_day_min_hire_from_stand
	rename k4_2      em_day_max_hire_from_stand
	rename k5        em_10day_contract_absent_days	
	
	
	rename l3 			em_balu_sanjay	
	rename l3_a 		em_balu_sanjay_why
	
	
	rename l2_250        em_sk_bonus_vs_daily_wage
	rename l2_500        em_sk_bonus_vs_daily_wage_500
	rename l2_max        em_sk_bonus_vs_daily_wage_max	
	
	
	rename k6	      		em_same_workers 
	rename k6_others 		em_same_workers_others_spec


	rename k7            em_10_worker_morethan_1day
	rename k8            em_hire_reg_worker
	rename k8_1          em_why_not_reg
	
	
	rename k8_1_1 			em_why_not_reg_notregular
	rename k8_1_2 			em_why_not_reg_stophard
	rename k8_1_3 			em_why_not_reg_tired
	rename k8_1_4 			em_why_not_reg_demendhigher
	rename k8_1_998 		em_why_not_reg_others
	
	
	
**## Employer Survey > Section C: Multi-Day

	rename n1        em_current_how_many_workers
	rename n2        em_stand_hire_1day
	rename n3        em_stand_hire_more1day  
	
	
	rename n4    	em_avg_days_more1day
	rename n5   	em_reg_worker_offer_multiday
	rename n6   	em_how_more_multiday_need
	
	rename n7        em_relay_worker_hiring_change
	rename n7_1      em_relay_more_training 
	rename n7_2      em_relay_offer_benefits
	rename n7_3      em_relay_skill_project
	rename n7_4      em_relay_expand_business
	rename n7_5      em_relay_inkind_gifts
	rename n7_6      em_relay_intrest_free_loans
	rename n7_7      em_relay_pay_school_fees
	rename n7_8      em_relay_none
	
	rename n7_998 		em_relay_others
	rename n7_others 	em_relay_others_spec
	
	
	rename l6       	em_hire_buffer_workers
	rename l7       	em_hire_buffer_workers_howmany
	
	
	
	
**### Employer Survey > Section M: Migrant Workers
	
	rename m1_a        em_hire_migrant_workers
	rename m1_b        em_why_migrant_workers
	rename m1_b_1      em_mig_worker_come_everyday
	rename m1_b_2      em_mig_worker_ontime
	rename m1_b_3      em_mig_worker_lower_wages
	rename m1_b_4      em_mig_worker_work_hard
	rename m1_b_5      em_mig_worker_follow_rules
	rename m1_b_998    em_mig_worker_others
	rename m1_b_others em_mig_workers_others_spec

	rename m2       	em_how_find_worker_urgent
	rename m2_1     	em_urgent_hire_outsiders
	rename m2_2     	em_urgent_hire_reliable
	rename m2_3     	em_urgent_hire_more
	rename m2_4     	em_urgent_pay_more
	

	
************************************	
**# Combine Employer and Recruiter
************************************
/*
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
					balu_sanjay	balu_sanjay_why sk_bonus_vs_daily_wage sk_bonus_vs_daily_wage_500 sk_bonus_vs_daily_wage_max ///
					same_workers same_workers_others_spec 10_worker_morethan_1day hire_reg_worker why_not_reg ///
					why_not_reg_notregular why_not_reg_stophard why_not_reg_tired why_not_reg_demendhigher why_not_reg_others {
		clonevar 	comb_`i' = rec_`i'
		replace 	comb_`i' = em_`i' if mi(comb_`i')
						
	}
	
	
	foreach i in 	current_how_many_workers stand_hire_1day stand_hire_more1day avg_days_more1day reg_worker_offer_multiday ///
					how_more_multiday_need relay_worker_hiring_change relay_more_training  relay_offer_benefits relay_skill_project ///
					relay_expand_business relay_inkind_gifts relay_intrest_free_loans relay_pay_school_fees relay_none relay_others ///
					relay_others_spec hire_buffer_workers hire_buffer_workers_howmany {
		clonevar 	comb_`i' = rec_`i'
		replace 	comb_`i' = em_`i' if mi(comb_`i')
						
	}	
	

	
	foreach i in 	hire_migrant_workers why_migrant_workers mig_worker_come_everyday mig_worker_ontime mig_worker_lower_wages ///
					mig_worker_work_hard mig_worker_follow_rules mig_worker_others mig_workers_others_spec how_find_worker_urgent ///
					urgent_hire_outsiders urgent_hire_reliable urgent_hire_more urgent_pay_more {
		clonevar 	comb_`i' = rec_`i'
		replace 	comb_`i' = em_`i' if mi(comb_`i')
						
	}	
*/	
	
****************
**# Order Vars
****************

	rename p1 	recruiter_id
	rename p3	date
	rename p5	role
	gen version = 2
	order recruiter_id role version date

	save "$temp/ls_employers_survey_v2_renamed.dta" , replace
