*************************************************
*************************************************
* Project: LD
* Purpose: Make Variables for Analysis
* Last last modified: 2024-05-06 (YS)
* Last modified: 2025-Jan-23 (HW)
*************************************************
*************************************************

	cap program drop convert_zero_one 
	program define convert_zero_one 

	syntax varlist [,flip]
	
	local varname : word 1 of "`varlist'"
	
	replace `varname' = . if `varname' == 999
	qui sum `varname'
	assert `r(min)' >= 1 & `r(max)' <= 5
	
	if "`flip'" != "" recode `varname' (5=1) (4=2) (1=5) (2=4)

	replace `varname' = (`varname' - 1)/ 4
	
	lab val `varname' 
	format  `varname' %9.0g	

	end


*******************
**# 1.  Open data
*******************


	use "$temp/03a_phase2act_vignettes_cleaned_completed.dta", clear


***********************
**# 2.  Vars Creation
***********************	
	

****	
**## Cognitive/ Preference
****	

	
	* C1. I prefer casual daily work to formal employment that gives work each day because of the flexibility to come whichever days I want.
	convert_zero_one cog_pref_daily_for_flex , flip
	
	
	
	* C2. Going to the stand is something I do without thinking
	convert_zero_one cog_going_without_thinking , flip
	

	
	* C3. I need to rearrange my morning activities on the days that I have to go to the stand.
	convert_zero_one cog_rearrange_to_go, flip
	
	
	* C4. When do you usually decide when you go to the stand when you have not secured a job already?
		* only asked in filename v3 of survey
	rename c4 cog_decision_gostand 


	
	
	
	
	

	
	* Please rank the qualities of a job that are most important to you from this list. Please rank the following options from most important to least important:
	foreach var in pref_rank_safety pref_rank_flex pref_rank_heavywork pref_rank_ontime_pay {
		replace cog_`var' = . if cog_`var' == 999
		gen `var' = 5 - cog_`var' if cog_`var' != . 
	}
	la var cog_pref_rank_safety     "Safety"
	la var cog_pref_rank_flex       "Flexibility"
	la var cog_pref_rank_heavywork  "Not Phy Taxing"
	la var cog_pref_rank_ontime_pay "On Time Pay"
	
	rename cog_pref_rank_safety 		cog_pref_score_safety
	rename cog_pref_rank_flex 			cog_pref_score_flex
	rename cog_pref_rank_heavywork 		cog_pref_score_heavywork
	rename cog_pref_rank_ontime_pay 	cog_pref_score_ontime_pay


	order pid date cog_pref_daily_for_flex cog_pref_score* cog_going_without_thinking cog_rearrange_to_go cog_decision_gostand  
	
	

****	
**## Routine
****	
	
	* R1: Absence acceptable
	convert_zero_one r_acceptable_tired_not_go
	
	
	* R2: 
	rename r_reg_morning_act_998 r_reg_morning_act_oth
	drop r_reg_morning_act_998_others
	replace r_reg_morning_act_oth = 0 if mi(r_reg_morning_act_oth) & !mi(r_regular_morning_act)

	* R3: Do you use an alarm to wake up in the morning?
	* r_morning_alarm
	
	order r_* , after(cog_decision_gostand)
	
	
****	
**## Identity
****

	* I1: Sanjay wants to get to the labor stand by 8 am each day so he has a good chance of getting a job. But he is often later than he wants to be, only arriving around 8:30 or 9 am.
	gen i_excusable_if_late_arrival = i_commitment_if_late_arrival
	convert_zero_one i_excusable_if_late_arrival
	
	
	* I2: Which of these statements do you agree with most strongly
	gen i_life_philosophy_agree_work = i_life_philosophy_agreement
	replace i_life_philosophy_agree_work = i_life_philosophy_agreement_v2 	if mi(i_life_philosophy_agree_work)
	replace i_life_philosophy_agree_work = i2_1 							if mi(i_life_philosophy_agree_work)
	replace i_life_philosophy_agree_work = . if i_life_philosophy_agree_work == 999
	replace i_life_philosophy_agree_work = i_life_philosophy_agree_work - 1
	
	
	* I3: A worker was planning to go to the labor stand tomorrow to meet up with an employer who had hired him. However, he just heard from his friend about a fair/carnival at the beach tomorrow and his kids want him to take them to the fair. The carnival happens only once a year it is the last day. What should he do?
	gen i_beach_carnival_choose_work = i_beach_carnival_work_choice
	convert_zero_one i_beach_carnival_choose_work , flip
	

	* I4. I am going to describe to you two characters. Listen to both and then respond. The first one is a good / reliable worker that shows up to work when they promise and earns money for their family. The second one is Someone who is there / available for the community/ neighbors / temple/church/religious institution and very helpful to everyone in general.
		gen i_tale_of_two_characters_d = i_tale_of_two_characters == 1 if i_tale_of_two_characters != .
		la var i_tale_of_two_characters_d "Worker identity"


	*I5. You have already worked for 6 days in a week. But your employer asks you to come again on Sunday when your family and friends are also at home. Would you prefer to report for work on a Sunday or spend time with your family?
		* i_whether_work_on_7thday
		* we dropped this question in later version 
		
	order i_excusable_if_late_arrival i_life_philosophy_agree_work i_beach_carnival_choose_work i_tale_of_two_characters i_tale_of_two_characters_d i_whether_work_on_7thday , after(r_morning_alarm)
		
		
		
****		
**## life satisfaction
****		

	
	* FIXME did we decide to drop these questions in later version?
	* HW: we added the question in later version
	order l_life_satisfaction_overall  l_life_satisfaction_ladder l_how_satisfed_with_current_work , after(i_whether_work_on_7thday)
	
	
	
	
****	
**## Expectation
****	

	rename work_last_week e_work_last_week
	order e_how_many_days_out_of_7 e_work_last_week e_how_many_days_expec_work  e_how_satisfied_work_actual , after(l_how_satisfed_with_current_work)

	
****	
**## Networks
****	
	
/* [>   Networks   <] */

	* E1. In the past 7 days, did you refuse any job offers?	
		* e_did_you_refuse

	* E1_1. If yes, how many days did you refuse a job offer?
		* e_how_many_days_refused

	* E2. What was the reason for refusal?
		* e_reason_for_refusal

	* E3. In the past 7 days, how many different (unique) employers did you work for?
		* _unique_employers_job_worked

	* E4. In the past 7 days, how many different (unique) people did you get jobs from?
		* e_unique_employers_job_obtained

	* E5. In the past 7 days, how many different (unique) people did you offer jobs to?
		* e_unique_employers_job_given
		
	rename e2_1 	e_reason_refusal_lowwage
	rename e2_2 	e_reason_refusal_notdesirable
	rename e2_3 	e_reason_refusal_betteroffer
	rename e2_4 	e_reason_refusal_toofar
	rename e2_5 	e_reason_refusal_havemultiday
	rename e2_6 	e_reason_refusal_needrest
	rename e2_7 	e_reason_refusal_emergency
	rename e2_8		e_reason_refusal_health

	order e_did_you_refuse e_how_many_days_refused e_reason_refusal* e_unique_employers_job_obtained  e_unique_employers_job_given , after(e_how_satisfied_work_actual)
	
	
**************	
**# Save Data
**************

	keep pid-e_unique_employers_job_given

	save "$temp/03a_phase2act_vignettes_makevar_hw.dta", replace


