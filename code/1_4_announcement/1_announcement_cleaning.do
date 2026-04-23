**************************************************
**************************************************
* Project: LD 
* Purpose: Clean announcement data
* Author: Supraja
* Note: 02-04-2022 (LC)
* - The cleaning program was commented out so it was not called by the master
* - Added generation of batch variable, and flags for late announcement and whether they were moved to the next launchset
* - For people pushed to the next launchset: modify the launchset variable
* Last last modified: 2024-03-28 (YS)
* Last modified: HW Nov 21 2024
**************************************************
**************************************************

			
***************
**# Call Data
***************			
			
	use "$raw/01_announcement_named.dta", clear
	
	format date %td
	rename treatment_status treatment 
	
	* Drop monthly participants (i.e. those screened out after baseline)
	keep if !mi(treatment) 
	
	
****************	
**# Clean Data
****************

	drop if inlist(stand, ${droplist})

	* Correcting for wrongly entered date
	
	replace date=td(16mar2022) if key=="uuid:7ae6d0b4-69f0-4813-9a06-eae158f32121" & pid==405
	
	//04-04-2022
	replace check_completion=1 if pid==2129 & date==td(30mar2022) & key=="uuid:4ea9953d-dce8-4bbc-a86a-897cb7adea17"
	
	//ANYONE ANNOUNCED AFTER 05/04 IN THE FIRST 5 STANDS WOULD HAVE BEEN ANNOUNCED AS MONTHLY -NL
	
	//25-04-2022 - changing two 'other' stands to 6 
	replace stand = 6 if (pid ==672 & date==td(25apr2022) & key =="uuid:334ba607-7c1f-4d04-9dc5-f6b41fce32e0")| (pid ==673 & date == td(25apr2022) & key == "uuid:7edcb399-4bfb-4ae0-987e-f82a794dc165")
	
	//25-05-22 replacing stand for announcement today
	replace stand = 10 if date == td(25may2022)
	
	//25-05-22 replacing stand for announcement today
	replace stand = 10 if date == td(26may2022)
	
	//31-05-22 replacing stand for announcement 
	replace stand = 10 if date == td(31may2022)
	
	//31-05-22 replacing stand for announcement 
	replace stand = 10 if date == td(01jun2022)
	
	//31-05-22 replacing stand for announcement of many stand 10 PIDS
	replace stand = 10 if pid == 1050 | pid == 1049 | pid == 3029 | pid == 3007 | pid ==3041 | pid == 3059 | pid == 3021 | pid == 3066
	
	//06-06-22, replacing stand for announcement -NL
	replace stand=10 if stand==998 & key=="uuid:be033894-025b-45fa-9efc-657e2c0a28c6"
	replace stand=10 if stand==998 & key=="uuid:6dbc61b3-44b4-4d5d-afe5-508b0b825fb2"
	replace stand=10 if stand==998 & key=="uuid:2c58d48c-7c7a-4eb1-b630-6d9703133d72"
	replace stand=10 if stand==998 & key=="uuid:9e46253b-2b47-41b5-9f65-1a36e13ff568"
	replace stand=10 if stand==998 & key=="uuid:d83acf75-007c-4fc0-b573-0d82e98fa52d"

	//replacing stand for announcement 
	replace stand = 10 if key == "uuid:2a887a1c-f9f7-4914-87ce-8ba60fddd218"
	
	//29-06, correcting for missing stand value
	replace stand=12 if pid==1219
	replace stand=12 if pid==1244
	replace stand=12 if pid==1272
	replace stand=12 if pid==1276
	replace stand=12 if pid==1283
	replace stand=12 if pid==1297
	replace stand=13 if pid==1302
	replace stand=13 if pid==1351
	replace stand=13 if pid==1366
	replace stand=13 if pid==1367
	replace stand=13 if pid==1379
	replace stand=12 if pid==4300
	replace stand=12 if pid==4307
	replace stand=12 if pid==4309

	//13-07
	replace launchset = 13 if key == "uuid:5d8124f1-030d-4ee3-9e66-2c855791dd9f" // PID - 6848, was assigned PID late
	replace stand_cutoff = "8" if stand == 16 & date == td(13jul2022) // issue in prefills, it wasn't showing up
	
	//29-07, since some participants did the comprehension questions later, the duplicate observations need to be merged, NL
	duplicates tag pid, gen(dup)
	bys pid: egen min_date= min(date) if dup>=1
	format min_date %td
	bys pid (date): gen count=_n if dup>=1
	keep if count==. | count==1
	replace date=min_date if dup>=1
	drop min_date dup count
		
	//15-09 (NL)
	replace launchset=13 if pid==1705
	
	//once announcement is done, check if the treatment status matches the randomization in the master randomization dta. 

	// batch number
	preserve
		use "$raw/master_pid_list.dta", clear
		keep pid date
		rename date s_date
		label var s_date "Screening date"
		tempfile screening
		save `screening'
	restore

	merge n:1 pid using `screening'
	keep if _merge == 3
	drop _merge
		
	bys stand: egen min_date = min(s_date)
	format min_date %td

	gen batch = . 
		
	qui levelsof stand, local(stands)
	
	foreach s in `stands' {
		replace batch = 1 if stand == `s' & inrange(s_date, min_date, min_date+2)
		replace batch = 2 if stand == `s' & inrange(s_date, min_date + 7, min_date+9)  //s_date == min_date + 7
		replace batch = 3 if stand == `s' & inrange(s_date, min_date + 14, min_date+16)  //s_date == min_date + 14
	}
	drop min_date
		
	//29-07, correcting for missing batch values
	replace batch =2 if key=="uuid:89e53d26-86ea-43e9-8657-8263364e2240"
	replace batch =2 if key=="uuid:615c7dfc-88f7-4ce1-b557-662c66c0f9e5"
	replace batch =2 if key=="uuid:d16beb51-7cba-45b2-bcdf-9faae2b790b5"
	replace batch =1 if key=="uuid:087795a8-58f2-4c7f-8b85-470677746ff3"
	
	//13-08, dropping ineligible participant
	drop if key=="uuid:2191b848-b8dd-4bd3-97f1-7acc7a56170d"
	
	//assert !mi(batch) // if batch is missing, it means that either there was a fourth batch, or that screening happened on days subsequent to the third
	
	//08-09, changing launchset based on the new timeline
	replace launchset = 17 if launchset==13 & stand==14
	replace launchset = 17 if launchset==13 & stand==15
	replace launchset = 18 if launchset==14 & stand==14
	replace launchset = 19 if launchset==14 & stand==19
	replace launchset = 20 if launchset==15 & stand==19

	drop if inlist(stand, ${droplist}) // defined in master.do

/*----------------------------------------------------*/
   /* [>   3.  Save data    <] */ 
/*----------------------------------------------------*/
	
	sort date interviewer pid
	drop anote* a1_* cnote* bnote* dnote* c1_* c2_* c5_* 
	//added 2024-03-28
	drop deviceid subscriberid devicephonenum username duration caseid key stand_others interviewer_others stand_cutoff in_hold total_eligible final_eligible s2* randvar1 p12_b note1_a note_d sec_a_11a1_*  a_1note*  c7_* notes note2 
	rename date a_date 	//added 2024-03-28

	rename interviewer a_interviewer 
	label var a_interviewer "Announcement surveyor"

	rename launchset a_launchset
	label var a_launchset "Launchset (announcement data)"

	rename batch a_batch
	label var a_batch "Batch (announcement data)"

	label var a_date "Announcement date"
	order stand pid a_launchset a_batch a_date a_interviewer treatment
	isid pid 
	saveold "$temp/02_announcement_cleaned.dta", replace

	// keep completed surveys 
	keep if check_completion==1
		* drops 4 surveys 
	save "$temp/03_announcement_completed_cleaned.dta", replace
	
