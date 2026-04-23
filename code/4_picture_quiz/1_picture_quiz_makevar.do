
**************************************************
**************************************************
*	Project: LD Main Study
*	Purpose: Picture Quiz Cleaning and Make Var
*	Author: HW
*	Last modified: May 13 2025 HW
**************************************************
**************************************************

	use "$raw/01-picture-quiz-appended.dta" , clear
	
***************	
**# Keep Vars
***************

	keep submissiondate c1 rid? q?
	rename q? pq_recognized?
	
	replace  submissiondate = dofc(submissiondate)
	format submissiondate %td
	
	forval i = 1/8 {
		clonevar date`i' = submissiondate
		clonevar pq_enumerator_name`i' =  c1
	}
	drop submissiondate c1
	
	
*************	
**# Reshape
*************

	gen survey_index = _n
	reshape long rid pq_recognized date pq_enumerator_name , i(survey_index) j(j)
	
	drop survey_index j
	drop if mi(rid)
	
	
****************
**# RID to PID
****************	
	
	destring rid , replace
	sort rid date
	
	rename rid pid // Here I think its PID instead of RID
	
	
	
***************
**# Save Data
***************

	save "$temp/02_picture_quiz_makevar.dta" , replace
	
	
	
	
***********************************************************************
**# Appendix: Check how many PIDs are in the main sample and the quiz 
***********************************************************************

	preserve
		keep pid
		duplicates drop
		merge 1:1 pid using  "$temp/00_mainstudy_master.dta"  , keep(1 2 3) // 145 out of 225 appeared in at least 1 quize
	restore
	
	
	
	
	
	