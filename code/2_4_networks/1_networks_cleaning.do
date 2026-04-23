**************************************************
*Project: LD Main Study
*Purpose: Networks 
*Author: HW
*Last modified: 30-08-2024 (HW)
**************************************************


************************			
**# 1. Load Named Data	
************************

	use "$raw/01_networks_named.dta" , clear
			
			
			
***************
**# 2. Checks
***************

	assert mi(p12_c) 	// Assert the dataset does not contain surveys stopped because of Covid or Drunk
	assert z0 == 1 		// Assert all surveys are completed
	
***********************************
**# 3. Rename and Check Variables
***********************************
	
	tab e_did_you_refuse 				, m
	tab e_how_many_days_refused			, m
	tab e2 								, m
	tab e2_998 							, m
	tab e_unique_employers_job_worked 	, m
	tab e_unique_employers_job_obtained , m
	tab e_unique_employers_job_given 	, m
	
	
	keep 	pid date e_did_you_refuse e_how_many_days_refused e2 e2_998 e_unique_employers_job_worked ///
			e_unique_employers_job_obtained e_unique_employers_job_given
	
	rename date 							ntwks_date
	rename e_did_you_refuse 				ntwks_refuse_any_7dys
	rename e_how_many_days_refused 			ntwks_refuse_num
	rename e2 								ntwks_refuse_resaon
	rename e2_998 							ntwks_refuse_resaon_spec
	rename e_unique_employers_job_worked	ntwks_unq_emplyrs_job_worked
	rename e_unique_employers_job_obtained	ntwks_unq_emplyrs_job_obtained
	rename e_unique_employers_job_given		ntwks_unq_emplyrs_job_given
	

*********************
**# Clean Variables
*********************

	cap program drop otherspec 
	program define otherspec 

		syntax varlist(min=2 max=2) , SPECify(string) CATegory(integer) [NEWCATegory(string)]
		
		local catvar : word 1 of `varlist'
		local othvar : word 2 of `varlist'
		
		tempvar hasstr
		gen `hasstr' = strpos(`othvar', `"`specify'"') > 0
		sum `hasstr'
		
		replace `catvar' 	= `category' 	if `hasstr' == 1
		replace `othvar'  	= "" 			if `hasstr' == 1
		
		if `"`newcategory'"' != "" {
			qui elabel list (`catvar')
			label define `r(name)' `category' `"`newcategory'"' , modify
		}
		
	end
	
	
	otherspec ntwks_refuse_resaon ntwks_refuse_resaon_spec, spec("Already") cat(3)
	otherspec ntwks_refuse_resaon ntwks_refuse_resaon_spec, spec("family function") cat(10) newcat("Family Responsibility")
	otherspec ntwks_refuse_resaon ntwks_refuse_resaon_spec, spec("Health issue") cat(8) newcat("Health Issue")
	otherspec ntwks_refuse_resaon ntwks_refuse_resaon_spec, spec("Not feeling well") cat(8) 
	otherspec ntwks_refuse_resaon ntwks_refuse_resaon_spec, spec("Rest") cat(8)
	otherspec ntwks_refuse_resaon ntwks_refuse_resaon_spec, spec("Regular work in one site") cat(5) newcat("Had a multiday job")
	otherspec ntwks_refuse_resaon ntwks_refuse_resaon_spec, spec("Suddenly other program") cat(3)
	assert mi(ntwks_refuse_resaon_spec)
	


	
	assert ntwks_unq_emplyrs_job_worked >= 0
	assert ntwks_unq_emplyrs_job_obtained >= 0
	assert ntwks_unq_emplyrs_job_given >= 0
	
	
	
	
***************	
**# Save Data
***************

	save "$temp/01_networks_cleaned.dta", replace
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

	