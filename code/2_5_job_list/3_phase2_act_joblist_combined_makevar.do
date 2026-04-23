**************************************************
* Project: LD
* Purpose: Make Variables for job list test analysis
	// survey instrument: ls_p2_contract_activity
* Created: 
* Last modified: 2024-08-20 (YS)
	* Previous: HW Jul 29 2024
**************************************************

/*----------------------------------------------------*/
   /* [>   1.  Combine data    <] */ 
/*----------------------------------------------------*/

	* merge v1
	* v1 data is problematic - 3 PIDs with 2 obs
		* quick fix: keep first obs for each of these cases 
	use "$temp/03b_phase2act_joblist_cleaned_completed", clear
	sort pid date 
	bys pid: gen sno = _n
	keep if sno==1
	drop sno 

	keep pid date joblist_accept_22500 joblist_accept_22500 notes_22500 joblist_accept_22500 notes_22500 joblist_accept_20000 joblist_accept_22500 notes_22500 joblist_accept_20000 notes_20000 joblist_accept_22500 notes_22500 joblist_accept_20000 notes_20000 joblist_accept_17500 joblist_accept_22500 notes_22500 joblist_accept_20000 notes_20000 joblist_accept_17500 notes_17500 joblist_accept_22500 notes_22500 joblist_accept_20000 notes_20000 joblist_accept_17500 notes_17500 joblist_accept_15000 joblist_accept_22500 notes_22500 joblist_accept_20000 notes_20000 joblist_accept_17500 notes_17500 joblist_accept_15000 notes_15000 q2_1 q2_1_998 a0 a0_reason a1 a2 new_elicitation

	* now merge with final set of PIDs in main study 
	merge 1:1 pid using "$temp/00_mainstudy_master.dta", gen(_merge_v1)
	* _merge_v1==1: 47 PIDs in v1 but not in master data - could have been dropped from main study
	* _merge_v1==2: 33 PIDs in master but not in v1 data  
	drop if _merge_v1==1

	* merge v2
	merge 1:1 pid using "$temp/03b_phase2act_joblist_cleaned_completed_v2", gen(_merge_v2) 
	* _merge_v2==1: 116 PIDs in master but not in v2 data  

/*----------------------------------------------------*/
   /* [>   2.  Clean data   <] */ 
/*----------------------------------------------------*/

	gen version = 1 if _merge_v1 == 3 & new_elicitation == 0
		replace version = 2 if _merge_v1 == 3 & new_elicitation == 1
		replace version = 3 if _merge_v2==3
	la def jd_version 1 "Offered various salaries" 2 "Offered only Rs 20,000" 3 "Offered job with penalty"
	la val version jd_version

	* FIXME - YS does not understand this. Need to go back to the variables definitions in CTO.
	replace jl_choice1_fixed = jl_choice1_fixed_vs_stand == 1 if _merge_v2==3
	replace jl_choice1_stand = jl_choice1_fixed_vs_stand == 2 if _merge_v2==3

	* FIXME - YS does not understand this. Need to go back to the variables definitions in CTO.
	//replace . with 0 for those in version 3 that said they did not want fixed jobs
	replace jl_contract_penalty = 0 if version==3 & jl_contract_penalty==.

	* FIXME - YS does not understand this. Need to go back to the variables definitions in CTO.
	gen ltjob = .
		replace ltjob = 1 if joblist_accept_20000==1 | jl_contract_penalty ==1
		replace ltjob = 0 if joblist_accept_20000==0 | jl_contract_penalty ==0

	gen miss_jl_contract_penalty = (jl_contract_penalty==.)

/*----------------------------------------------------*/
   /* [>   3.  Label variables    <] */ 
/*----------------------------------------------------*/

	la var ltjob "Long-term Job"
	la var jl_choice1_fixed "Contract Job"
	la var jl_choice1_stand "Stand Job"
	la var joblist_accept_20000 "Accept 20,000Rs Job"
	la var jl_contract_penalty "Contract Job w Penalty"
	la var miss_jl_contract_penalty "Missing - Contract Job w Penalty"

/*----------------------------------------------------*/
   /* [>   4.  Save data    <] */ 
/*----------------------------------------------------*/

	save "$temp/04b_phase2act_joblist_combined_makevar.dta", replace
