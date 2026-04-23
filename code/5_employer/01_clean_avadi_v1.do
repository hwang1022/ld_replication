**************************************************
**************************************************
*Project: LD Main Study
*Purpose: Employers Survey Avadi V1 Cleaning
*Author: HW Jan 30 2025
*Last modified: HW Jan 30 2025
**************************************************	
**************************************************
	
	* This additional survey converts to V2
	
	use "$raw/ls_employers_survey_avadi_v1.dta" , clear
	drop if r4 == 0
	assert r4 == 1
	
************	
**# Rename
************

	* Drop Intro Vars
	drop deviceid-p0_998 p2-p4  mode-r4
	
	
	* Drop PII
	drop ss1 ss1_1
	
	
	* Drop Useless Vars
	drop z0-endtime count_check*
	 
	
	
	
**## Proceed Introduction

	rename ss2 		intro_role 
	rename ss3     	intro_workex_mestri

	
	
**## Recruiter's Section — Section A: Recruitment Purpose

	rename a3_v2     rec_hiring_freq_days

	

	
	
**## Recruiter's Section > consent > Section B: Worker Skills




	rename b2_250        rec_sk_bonus_vs_daily_wage
	rename b2_500        rec_sk_bonus_vs_daily_wage_500
	rename b2_max        rec_sk_bonus_vs_daily_wage_max
	
	rename b5 			rec_balu_sanjay	
	rename b6 			rec_balu_sanjay_why
	rename b7        	rec_last_30days_laborstand_hire
	
	rename b8_1      rec_day_min_hire_from_stand
	rename b8_2      rec_day_max_hire_from_stand
	rename b9        rec_10day_contract_absent_days
	
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
	

	
****************
**# Order Vars
****************

	rename p1 	recruiter_id
	rename p3	date
	rename p5	role
	gen version = 2
	order recruiter_id role version date

	save "$temp/ls_employers_survey_avadi_v1_renamed.dta" , replace
