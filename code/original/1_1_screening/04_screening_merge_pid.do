**************************************************
*Project: LD Main Study
*Script : 04_screening_merge_pid
*Purpose: Merge pids into screening data
*Author : Luisa
*Last modified: 2024-03-26 (YS)
**************************************************
	
/*----------------------------------------------------*/
   /* [>   1.  Open data    <] */ 
/*----------------------------------------------------*/

	* create rid-pid data set for merge 
	use "./07. Data/3. Main Study 3.0/04. Operation/01. Screening/02. Output/02. PID Assignment/master_pid_list.dta", clear 
	isid rid
	* every surveyor is given a bunch of IDs to start talking to people 
	drop if inlist(stand, ${droplist}) // defined in master dofile
	keep rid pid 
	save "./07. Data/3. Main Study 3.0/02. Cleaning Data/01. Screening/02. Output/master_pid_list.dta", replace 

	* open screening data set
	use "./07. Data/3. Main Study 3.0/02. Cleaning Data/01. Screening/02. Output/05_screening_dem_vars.dta", clear

/*----------------------------------------------------*/
   /* [>   2.  Merge with PIDs    <] */ 
/*----------------------------------------------------*/

	merge 1:1 rid using "./07. Data/3. Main Study 3.0/02. Cleaning Data/01. Screening/02. Output/master_pid_list.dta"
	* April 2024: LC pretty confident that is fully updated and good to use.

	/*     
   Result                           # of obs.
    -----------------------------------------
    not matched                            12
        from master                         4  (_merge==1)
        from using                          8  (_merge==2)

    matched                             1,059  (_merge==3)
    -----------------------------------------

	*/

	drop if pid == . // _merge==1 
	* FIXME what does _merge==2 correspond to? why do we retain those obs?
		/*
		    pid |      Freq.     Percent        Cum.
	------------+-----------------------------------
	       1327 |          1       12.50       12.50
	       1501 |          1       12.50       25.00 // Assigned to Saidapet, but we abandoned this stand. 
	       1502 |          1       12.50       37.50 // Assigned to Saidapet, but we abandoned this stand. 
	       1503 |          1       12.50       50.00 // Assigned to Saidapet, but we abandoned this stand. 
	       1504 |          1       12.50       62.50 // Assigned to Saidapet, but we abandoned this stand. 
	       1505 |          1       12.50       75.00 // Assigned to Saidapet, but we abandoned this stand. 
	       1506 |          1       12.50       87.50 // Assigned to Saidapet, but we abandoned this stand. 
	       1507 |          1       12.50      100.00 
	------------+-----------------------------------
	      Total |          8      100.00
	*/
	* 2024-04-04: checked if these pids are in our main sample - doesn't seem to be the case, so made decision to drop them. 
	drop if _merge==2
	drop _merge
	gen ss_rid = rid
	label var ss_rid "Screening survey RID"
	label var pid "PID"

/*----------------------------------------------------*/
   /* [>   3.  Save data    <] */ 
/*----------------------------------------------------*/
	order rid ss_rid pid stand 
	save "./07. Data/3. Main Study 3.0/02. Cleaning Data/01. Screening/02. Output/06_screening_dem_vars_with_pid.dta", replace

	
