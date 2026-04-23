**************************************************
**************************************************
*Project: LD Main Study
*Purpose: Employers Survey v1 Cleaning
*Author: HW Jan 24 2025
*Last modified: HW Jan 24 2025
**************************************************	
**************************************************
	
	use "$raw/ls_employers_survey_v1.dta" , clear
	assert r4 == 1
	
************	
**# Rename
************

	* Drop Intro Vars
	drop deviceid-p0_998 p2-p4  mode-r4
	
	
	* Drop PII
	drop ss1 ss1_1
	
	
	* Drop Useless Vars
	drop cal_rank b4_others count_works-show_draws_count draw_num* unique_draw* z0-endtime
	 
	
	
	
**## Proceed Introduction

	rename ss2 intro_role 
	
	
	
**## Recruiter's Section — Section A: Recruitment Purpose

	rename a1        	rec_how_find_worker
	rename a1_1      	rec_how_find_stand 
	rename a1_2      	rec_how_find_call
	rename a1_3      	rec_how_find_frnd
	rename a1_4      	rec_how_find_migrant
	rename a1_5      	rec_how_find_contractor
	rename a1_998    	rec_how_find_others
	// rename a1_others    rec_how_find_others_spec
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
	
	
	
	rename a3        rec_hiring_freq
	rename a4        rec_hiring_nos
	rename a5        rec_hire_large_co


	
	
**## Recruiter's Section — Section B: Worker Skills > Ranking
	
	rename b1_label		rec_rk
	rename b1a 			rec_rk_safety_reg
	rename b1b 			rec_rk_effort
	rename b1c 			rec_rk_not_steal
	rename b1d 			rec_rk_come_regular
	rename b1e 			rec_rk_getting_along_others
	
	rename b2        	rec_sk_bonus_vs_daily_wage
	rename b2_1        	rec_sk_bonus_vs_daily_wage_why
	rename b3        	rec_sk_pdtivity
	rename b4        	rec_sk_pdivity_why
	
	rename b5 			rec_balu_sanjay	
	rename b6 			rec_balu_sanjay_why
	
	
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
	
	
	
	
	rename d2         rec_reg_worker_adv
	rename d2_1       rec_reg_worker_adv_knows_site
	rename d2_2       rec_reg_worker_adv_knows_exp
	rename d2_3       rec_reg_worker_adv_knows_team
	rename d2_4       rec_reg_worker_adv_less_traning
	rename d2_5       rec_reg_worker_adv_hire_better
	rename d2_6       rec_reg_worker_adv_none
	rename d2_998     rec_reg_worker_adv_others
	rename d2_others  rec_reg_worker_adv_others_spec

	rename d3       rec_reg_work_cons
	rename d3_1     rec_reg_work_cons_tired
	rename d3_2     rec_reg_work_cons_highwage
	rename d3_3     rec_reg_work_cons_not_reliable
	rename d3_4     rec_reg_work_cons_stop_hardwork
	rename d3_5     rec_reg_work_cons_disrupt
	rename d3_6     rec_reg_work_cons_none_2
	rename d3_998   rec_reg_work_cons_others
	rename d3_others rec_reg_work_cons_others_spec

	rename d4       rec_hire_buffer_workers
		
	
	
	
**## Recruiter's Section > Section E: Migrant Workers
	
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

	
	
	
**## Employer Survey > Section l: Costs
	
	
	rename l2        	em_sk_bonus_vs_daily_wage
	rename l2_1        	em_sk_bonus_vs_daily_wage_why

	rename l3 			em_balu_sanjay	
	rename l3_a 		em_balu_sanjay_why
	
	
	rename l4         em_reg_worker_adv
	rename l4_1       em_reg_worker_adv_knows_site
	rename l4_2       em_reg_worker_adv_knows_exp
	rename l4_3       em_reg_worker_adv_knows_team
	rename l4_4       em_reg_worker_adv_less_traning
	rename l4_5       em_reg_worker_adv_hire_better
	rename l4_6       em_reg_worker_adv_none
	rename l4_998     em_reg_worker_adv_others
	rename l4_others  em_reg_worker_adv_others_spec		
	
	
	
	rename l5       	em_reg_work_cons
	rename l5_1     	em_reg_work_cons_tired
	rename l5_2     	em_reg_work_cons_highwage
	rename l5_3     	em_reg_work_cons_not_reliable
	rename l5_4     	em_reg_work_cons_stop_hardwork
	rename l5_5     	em_reg_work_cons_disrupt
	rename l5_6     	em_reg_work_cons_none_2
	rename l5_998   	em_reg_work_cons_others
	rename l5_others 	em_reg_work_cons_others_spec	
	
	rename l6       	em_hire_buffer_workers
	
	
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
	

**************
**# Cleaning
**************

	replace rec_plumber = 1 				if strpos(rec_wrk_type_others_spec, "Plumbing")
	replace rec_wrk_type_others = 1 		if strpos(rec_wrk_type_others_spec, "Plumbing")
	replace rec_wrk_type_others_spec = "" 	if strpos(rec_wrk_type_others_spec, "Plumbing")	
	
	
	
	
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
	

	
	
	clonevar comb_sk_bonus_vs_daily_wage       			= rec_sk_bonus_vs_daily_wage
	clonevar comb_sk_bonus_vs_daily_wage_why        	= rec_sk_bonus_vs_daily_wage_why
	clonevar comb_balu_sanjay 							= rec_balu_sanjay	
	clonevar comb_balu_sanjay_why 						= rec_balu_sanjay_why
	
	replace comb_sk_bonus_vs_daily_wage       			= em_sk_bonus_vs_daily_wage			if mi(comb_sk_bonus_vs_daily_wage)
	replace comb_sk_bonus_vs_daily_wage_why        		= em_sk_bonus_vs_daily_wage_why		if mi(comb_sk_bonus_vs_daily_wage_why)
	replace comb_balu_sanjay 							= em_balu_sanjay					if mi(comb_balu_sanjay)
	replace comb_balu_sanjay_why 						= em_balu_sanjay_why				if mi(comb_balu_sanjay_why)
	
	
	
	foreach i in 	reg_worker_adv reg_worker_adv_knows_site reg_worker_adv_knows_exp reg_worker_adv_knows_team  reg_worker_adv_less_traning ///
					reg_worker_adv_hire_better reg_worker_adv_none reg_worker_adv_others reg_worker_adv_others_spec	{
		clonevar 	comb_`i' = rec_`i'
		replace 	comb_`i' = em_`i' if mi(comb_`i')
						
	}
	
	
	foreach i in 	reg_work_cons reg_work_cons_tired reg_work_cons_highwage reg_work_cons_not_reliable reg_work_cons_stop_hardwork	///
					reg_work_cons_disrupt reg_work_cons_none_2 reg_work_cons_others reg_work_cons_others_spec hire_buffer_workers {
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
	gen version = 1
	order recruiter_id role version date

	
	save "$temp/ls_employers_survey_v1_renamed.dta" , replace
