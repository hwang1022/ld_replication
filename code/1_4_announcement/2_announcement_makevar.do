**************************************************
*Project: LD 
*Purpose: Announcement make variables
*Author: Supraja
*Last modified: 2024-03-28 (YS)
**************************************************

/*----------------------------------------------------*/
   /* [>   1.  Open data    <] */ 
/*----------------------------------------------------*/
		
	use "$temp/03_announcement_completed_cleaned.dta", clear

/*----------------------------------------------------*/
   /* [>   2.  Generate variables    <] */ 
/*----------------------------------------------------*/

* Comprehension score

	// Treatment participants 
		forv i = 1/6 {
			* recoding variables to be binary
			gen treat_q`i'_correct = a_treat_comp`i' == 1 if !mi(a_treat_comp`i')
		}
		
		egen treat_comp_score = rowtotal(treat_q1_correct - treat_q6_correct)
		replace treat_comp_score = . if treatment == 0 //control coded as missing
		label var treat_comp_score "Comprehension Score (treatment)"
		
		*generate number missing 26-07-22 realized only questions 1,2,3 (coded as q1, q2, q6) were asked prior to July 2022 survey CTO fix
		*will no longer need next few lines once questions fixed bc will always be out of 3
		egen treat_comp_missing = rowmiss(treat_q1_correct - treat_q6_correct)
			label var treat_comp_missing "# of Treatment Questions Missing"
		replace treat_comp_missing=. if treatment== 0 //control coded as missing
		egen treat_comp_asked = rownonmiss(treat_q1_correct - treat_q6_correct), strok
			label var treat_comp_asked "# of Treatment Questions Asked"
		replace treat_comp_asked=. if treatment== 0 //control coded as missing

		gen treat_comp_pctscore = treat_comp_score / treat_comp_asked
			label var treat_comp_pctscore "% of comprehensive questions correct (treatment)"
		replace treat_comp_pctscore = . if treatment == 0 //control coded as missing

	// Control participants 
		forv i = 1/5 {
			gen control_q`i'_correct = a_control_comp`i'  == 1 if !mi(a_control_comp`i')
		}

		egen control_comp_score = rowtotal(control_q1_correct - control_q5_correct)
		replace control_comp_score = . if treatment == 1 //treatment coded as missing
		label var control_comp_score "Comprehension Score (control)"
				
		*generate number missing 26-07-22 realized only questions 1,2,3 were asked prior to July 2022 survey CTO fix
		egen control_comp_missing = rowmiss(control_q1_correct -control_q5_correct)
		label var control_comp_missing "# of Control Questions Missing"
		replace control_comp_missing=. if treatment== 1 //treatment coded as missing
		egen control_comp_asked = rownonmiss(control_q1_correct -control_q5_correct), strok
		label var control_comp_asked "# of Control Questions Asked"
		replace control_comp_asked=. if treatment== 1 //treatment coded as missing

		gen control_comp_pctscore = control_comp_score / control_comp_asked
			label var control_comp_pctscore "% of comprehensive questions correct (control)"
		replace control_comp_pctscore = . if treatment == 1 //treatment coded as missing

	// All participants 
		gen a_comp_pctscore = treat_comp_pctscore
		replace a_comp_pctscore = control_comp_pctscore if mi(a_comp_pctscore) & treatment==0
		label var a_comp_pctscore "% of comprehensive questions correct"
		
		* All questions correct
		gen treat_comp_allcorrect = 1 if treat_comp_pctscore == 1
		gen control_comp_allcorrect = 1 if control_comp_pctscore == 1
		
		gen a_comp_allcorrect = 0 if !missing(treat_comp_pctscore) | !missing(control_comp_pctscore)
		replace a_comp_allcorrect = 1 if treat_comp_pctscore == 1 | control_comp_pctscore == 1
		label var a_comp_allcorrect "100% Comprehension"

* Beliefs
	gen a_belief_share_days_before8  = a_belief_arrival_time/a_belief_attend
    label var a_belief_share_days_before8  "% days of exp. attend before 8am out of exp att days in 3 weeks into Phase 1"

    gen a_belief_attend_more = a_belief_attend_change == 3 if !mi(a_belief_attend_change)
    gen a_belief_attend_noless = a_belief_attend_change != 1 if !mi(a_belief_attend_change)
	label var a_belief_attend_more "Dummy= 1 if expect to attend more in Phase 2 wrt Phase 1"
    label var a_belief_attend_noless "Dummy= 1 if expect to attend more or the same in Phase 2 wrt Phase 1"

	gen a_belief_arrival_time_more = a_belief_arrival_time_change == 3 if !mi(a_belief_arrival_time_change)
	gen a_belief_arrival_time_noless = a_belief_arrival_time_change != 1 if !mi(a_belief_arrival_time_change)
	label var a_belief_arrival_time_more "Dummy= 1 if expect to attend before 8 am more often in Phase 2 than in Phase 1"
	label var a_belief_arrival_time_noless "Dummy= 1 if expect to attend before 8 am more or as often in Phase 2 wrt Phase 1"

	* saveold "$datadir/04. Announcement/02. Output/03a_announcement_completed_temp.dta", replace

/*----------------------------------------------------*/
   /* [>   3.  Fix launchset    <] */ 
/*----------------------------------------------------*/

	* Based on discussion with Luisa, treat this dataset as the most accurate
	preserve 
	use "$raw/launch_prefill_pidwise_2022.dta", clear
	isid pid 
	keep pid launchset batch late_announcement_flag modified_launchset_flag
	rename launchset launchset_op 
	rename batch batch_op 
	tempfile pid_ops
	save `pid_ops'
	restore 

	merge 1:1 pid using `pid_ops'
	assert _merge!=1
	drop if _merge==2 // from using data
	drop _merge 
	* the launchset variable is inconsistent in some cases 
	corr a_launchset launchset_op
	count if a_launchset!=launchset_op
		* 27 obs 
	* the batch variable is inconsistent in some cases 
	corr a_batch batch_op
	count if a_batch!=batch_op
		* 21 obs 

	replace a_launchset = launchset_op if a_launchset!=launchset_op & launchset_op!=.
	replace a_batch = batch_op if a_batch!=batch_op & batch_op!=.
	drop launchset_op batch_op 

	/* OLDER code, commented out 2024-04-22.
	merge 1:1 pid using "./07. Data/3. Main Study 3.0/04. Operation/launch_prefill_pidwise_2022.dta", keepusing(launchset batch late_announcement_flag modified_launchset_flag)
	assert _merge != 1 // all PIDs in Phase 1 should be in the prefill list
	keep if _merge == 3
	drop _merge

	replace a_launchset = launchset if modified_launchset_flag == 1 // LC 23-07 because a_launchset was still the old launchset

	* FIXME where did this come from? Should this apply to a_launchset? This code seems redundant as we drop launchset soon after.
	replace launchset = 17 if launchset==13 & stand==14
	replace launchset = 17 if launchset==13 & stand==15
	replace launchset = 18 if launchset==14 & stand==14
	replace launchset = 19 if launchset==14 & stand==19
	replace launchset = 20 if launchset==15 & stand==19
	replace launchset= 13 if pid==1705
	replace launchset = 15 if pid == 1818

	drop launchset batch original_launchset 
	*/

/*----------------------------------------------------*/
   /* [>   4.  Save data    <] */ 
/*----------------------------------------------------*/
	
	//added 2024-03-28
	rename treat* a_treat*
	rename a_treatment treatment
	rename control* a_control*

	drop a_sttime incentive phase2_el_week name_check go_ahead check_completion check_pid_check check_reason_incomplete_others check_reason_incomplete submissiondate a_treat_comp* a_control_comp* a_treat_questions a_control_questions q* formdef_version starttime endtime note_c
	order stand pid a_launchset a_batch a_date a_interviewer late_announcement_flag modified_launchset_flag treatment a_comp_pctscore a_comp_allcorrect a_belief*
	isid pid 
	save "$temp/04_announcement_completed_makevar.dta", replace
	
	
**# 5. Keep those Peroceeded

	keep pid
	save "$temp/05_announcement_list.dta", replace
	
	
	
