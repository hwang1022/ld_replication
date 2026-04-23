**************************************************
* Project: LD
* Purpose: Make baseline panel data
* Author : Supraja
* Notes: 08-09-2021 (LC) Generation of holiday dummy now depends on global created within make_dates.do
* Last modified: 2024-03-25 (YS)
**************************************************
	
/*----------------------------------------------------*/
   /* [>   1.  Open data    <] */ 
/*----------------------------------------------------*/

	cd "/Users/${user}/Dropbox/Labor Discipline"
	use "./07. Data/3. Main Study 3.0/02. Cleaning Data/03. Baseline/02. Output/03_baseline_completed_cleaned.dta", clear
	isid pid date 
	
	drop if check_completion == 0 & mode == 2
		// this should not drop anything since we already drop at the end of 02_baseline_cleaning.do
	   //Important: the line below is wrong because we are dropping participants we saw at the stand and did not take survey, wrongly marking them as not attending
	   //This had implications for eligibility. We fixed this on 22-04-2022
	   * keep if check_completion!=0  //keeping only started/completed surveys

/*----------------------------------------------------*/
   /* [>   2.  Generate variables    <] */ 
/*----------------------------------------------------*/

	* Survey attempted at stand 
		gen stand_survey=1 if mode==1 //mode of survey is in person or phone
			* note that surveys could be incomplete.. 
		label var stand_survey "Survey taken at the stand (may be incomplete)"

	* Latest day of interview
		bysort pid (date): egen max_date = max(date)
		format max_date %td
		label var max_date "BL latest date of interview"

	* Attendance (in-person dates in cto are days of attendance to the stand)
		gen attend = (mode==1)
		label var attend "Attendance at stand (not self-reported)"

	* Fix launchset variable (2024-04-22)
		bys pid: ereplace launchset = max(launchset)

		* Based on discussion with Luisa, treat this dataset as the most accurate
		preserve 
		use "~/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/04. Operation/launch_prefill_pidwise_2022.dta", clear 
		isid pid 
		keep pid launchset batch 
		rename launchset launchset_op 
		rename batch batch_op 
		tempfile pid_ops
		save `pid_ops'
		restore 

		merge m:1 pid using `pid_ops'
		* FIXME check with Luisa: why do we have 2 PIDs where _merge==1?
		drop if _merge==2 // from using data
		drop _merge 
		* the launchset variable is inconsistent in some cases 
		corr launchset launchset_op
		count if launchset!=launchset_op
			* 336 obs 
		* the batch variable is inconsistent in some cases 
		corr batch batch_op
		count if batch!=batch_op
			* 216 obs 

		replace launchset = launchset_op if launchset!=launchset_op & launchset_op!=.
		replace batch = batch_op if batch!=batch_op & batch_op!=.
		drop launchset_op batch_op 

		//For launchset == 1 only, we need to create the first day of baseline
		/*
		preserve
			keep if launchset == 1 
			bys pid: keep if _n == 1
			replace date = ${baselineStartSet1}
			replace attended = 0
			tempfile date1
			save `date1'
		restore	
		append using `date1'
		*/
		
	* Spot time
	   // ES - 12-07-2022 - edited out this code to prevent spot_time from being dropped
	   *formatting time
	   *ren spot_time spot_time_str
	   *tostring spot_time, gen(spot_time_str)
	   *gen double spot_time_new = clock(spot_time_str, "hms")
	   *format spot_time  %tcHH:MM:SS
	   *drop spot_time_str

	   format spot_time %tCHH:MM
	   foreach v in spot_time { //time_found 
		   gen `v'_hours = hh(`v') + mm(`v')/60 + ss(`v')/3600
	   }
	   label var spot_time_hours "Time at which surveyors first spotted participants"

		bys pid: egen bs_avg_spot_time = mean(spot_time_hours)
		label var bs_avg_spot_time "BL average spot time"

		// LC 12/4/2022 correction (temp): arrival time if post 6 pm should be am  
		//    replace time_found_hours = time_found_hours - 12 if time_found_hours >= 18 & !mi(time_found_hours)
		//    replace time_found_hours = . if time_found_hours > 12 & time_found_hours<18
		//    replace spot_time_hours  = spot_time_hours - 12 if spot_time_hours >= 18 & spot_time_hours <= 23
		//    replace time_found_hours = . if spot_time_hours > 11 & time_found_hours<18
		//    label var time_found_hours "Time the job found (cond on having found it at stand) in fractions of hours"

	* Main reason for absence (comprehensive)
		/*
		split bs_comp_reason_absence
		local nvars = r(nvars)
		local reasons family hh_chores friends function emergencies long_term_emp native
			
		foreach var in `reasons' {
			gen bs_comp_`var' = 0 if !mi(bs_comp_reason_absence)
		}
			
		forv i = 1/`nvars' {
			destring bs_comp_reason_absence`i', replace
			* Generate dummies
			replace bs_comp_family = 1        if bs_comp_reason_absence`i' == 1  //if !mi(ss_profession_const`i')
			replace bs_comp_hh_chores = 1     if bs_comp_reason_absence`i' == 2  //if !mi(ss_profession_const`i')
			replace bs_comp_friends  = 1      if bs_comp_reason_absence`i' == 3  //if !mi(ss_profession_const`i')
			replace bs_comp_function  = 1     if bs_comp_reason_absence`i' == 4  //if !mi(ss_profession_const`i')
			replace bs_comp_emergencies = 1   if bs_comp_reason_absence`i' == 5  //if !mi(ss_profession_const`i')
			replace bs_comp_long_term_emp = 1 if bs_comp_reason_absence`i' == 6  //if !mi(ss_profession_const`i')
			replace bs_comp_native    = 1     if bs_comp_reason_absence`i' == 7  //if !mi(ss_profession_const`i')
			drop bs_comp_reason_absence`i'
		}
		*/

/*----------------------------------------------------*/
   /* [>   3.  Balance the panel    <] */ 
/*----------------------------------------------------*/
	* Right now our data set is not balanced, we only have obs for days when we meet the participants.

	* Generate a tag for days that we do observe 
	gen bs_obs = 1
	label var bs_obs "BL day where we talk to participant - in person or phone"
	count if bs_obs == 1
		* 6,035
		

	* Pre-fill all dates 
	xtset pid date
	tsfill, full
	isid pid date 
	count if bs_obs == 1
	* 6,035
	
	
	
	

	* Replace key invariant variables to be non-missing 
	bys pid: ereplace launchset = max(launchset)
	bys pid: ereplace batch = max(batch)
	bys pid: ereplace stand = max(stand)
	bys pid: ereplace max_date = max(max_date)

	* Define baseline start and end dates using launchset 
	gen bs_start_date = .
	gen bs_end_date = .
	
	forv i = 1/$numSetsTotal { 
	    // LC - added global with number of stand sets we launched in
	    // this is defined in master_dates.do
	    replace bs_start_date = ${baselineStartSet`i'} if launchset == `i'
	    replace bs_end_date   = ${baselineEndSet`i'} if launchset == `i'
	}

	format bs_start_date %td 
	format bs_end_date %td 
	label var bs_start_date "BL start date"
	label var bs_end_date "BL end date"

	* Only keep relevant dates for each PID
	drop if date < bs_start_date
	drop if date > bs_end_date
	

	* Check that the balanced panel has been constructed correctly 
	bys pid (date): gen daycount = _n
	label var daycount "Day in phase (resets every phase)"
	tab daycount, m 
	assert stand==6 if daycount > 13 // this occured because of 2 days of holidays at the end of baseline in stand 6 (04/14-15, wed and thurs) so baseline had to be extended and we did announcements throughout the following week 

	* Day of week variable 
	gen dow = dow(date)
	label define dow_lab 0 "Sunday" 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday"
	label value dow dow_lab
	label var dow "Day of week"

	* Need to account for days where surveyors are not in the field (Sundays, holidays). Generate holidays date
		// LC - need to define the holidays global
		* ado file that generates $holiday_list global be found in Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/98. Utilities/01. Programs
	gen holiday = 0
	foreach day in $holiday_list {
	    replace holiday = 1 if date == `day'
	}
	label var holiday  "Holiday"

	* Impute attendance as 0 on days where stand is running and we don't see the participant 
	replace attend = 0 if attend == . & dow!=0 & holiday == 0
 
/*----------------------------------------------------*/
   /* [>   4.  Fill up data for relevant days in panel   <] */ 
/*----------------------------------------------------*/

* Gen blank key variables
 	// numeric variables
	local numericVars attend_sr work earn work_type role why_attend whenfound  howfound  time_found howfound_notattend native try_work why_notattend spend_day time_left_stand how_found_native why_nottry firsttime_emp notpaid_amt_due  paid_filt main_act_hh_chores main_act_home_rest main_act_self_employed main_act_work main_act_sick main_act_planned_event main_act_emergency main_act_travel main_act_family_time main_act_friends_time main_act_998 
	foreach var in `numericVars' {
		gen `var' = .
	}	

	label var attend_sr "Attendance at stand (self-reported)"	
	label var work  "Worked"
	label var earn "Earnings"
	label var work_type "Type of work"
	label var role  "Role"
	label var why_attend "Reason for attending stand"
	label var whenfound  "When was work found?"
	label var howfound   "How was work found?"
	label var time_found "What time was work found?"
	label var howfound_notattend  "How was work found, when not at stand?"
	label var native "Are they in their native?"
	label var try_work "Tried to work"
	label var why_notattend "If tried to find work, why they did not attend stand"
	label var spend_day "How do they spend the rest of the day"
	label var time_left_stand "Time they left the stand"
	label var how_found_native "How did they find work if they are in a different place"
	label var why_nottry "Why did they not try"

	label var main_act_hh_chores        "Main act - stayed home to do household chores"
	label var main_act_home_rest        "Main act - stayed home to rest"
	label var main_act_self_employed    "Main act - work as self-employed / not for pay"
	label var main_act_work             "Main act - work for pay"
	label var main_act_sick             "Main act - sick/injured"
	label var main_act_planned_event    "Main act - attended a planned event"
	label var main_act_emergency        "Main act - emergency"
	label var main_act_travel           "Main act - traveled"
	label var main_act_family_time      "Main act - spent time with children/family"
	label var main_act_friends_time     "Main act - spent time with friends"
	label var main_act_998              "Main act - Other (specify)"

	// string variables
	* FIXME all these variables are just missing. We never pre-fill them 
	local stringVars work_type_others why_attend_others whenfound_others howfound_others howfound_notattend_others why_notattend_others spend_day_others how_found_native_others paid_filt_others main_activity main_act_others
	foreach var in `stringVars' {
		gen `var' = ""
	}	

	label var work_type_others "Type of work- Others"
	label var why_attend_others "Reason for attending the stand- Others"
	label var whenfound_others "When did they find work - Others"
	label var howfound_others   "How did they find work - Others"
	label var howfound_notattend_others  "How they found work wothout attendning the stand - Others"
	label var why_notattend_others "If tried, why they did not attend stand - Others"
	label var spend_day_others  "How do they spend the rest of the day - Others" 
	label var how_found_native_others  "How did they find work if they are in a different place - Others"
	label var main_activity "Main activity"
	label var main_act_others  "Main activity, other"

* Define number of recall days
	defineRecallDays, varname(bs_attend_sr)
		* ado file defineRecallDays can be found in Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/98. Utilities/01. Programs
	local recall_days = r(max_days_recall)
	
	// LC - don't want to substitute the attended variable (observed) with self-reported one
	// 	forv z = 1/`recall_days' {
	// 	    bys pid (daycount): replace attended    = bs_attend_sr_`z'[_n+`z']     if !mi(bs_attend_`z'[_n+`z'] ) & pid == pid[_n+`z'] & ///
	// 		                  ( dow == 0 | holiday == 1) // we want to replace attendance with self-reported data only when we are not in the field.
	// 	}

* Fill up key variables with relevant values	
	// numeric variables
	forv z = 1/`recall_days' {
		foreach var in `numericVars' {
			disp("****")
			bys pid (daycount): replace `var'= bs_`var'_`z'[_n+`z'] if !mi(bs_`var'_`z'[_n+`z'])  & pid == pid[_n+`z'] & bs_`var'_`z'[_n+`z'] != 999 & mi(`var')
		}
	}
	
* Replace work variable with main activity if main activity == 4 (work)
	* starting from 9-06-2022 when we changed our work elicitation method
	replace work = main_act_work if mi(work) & !mi(main_act_work)
		
	replace main_act_hh_chores      = 1 if spend_day == 2
	replace main_act_home_rest      = 1 if spend_day == 5
	replace main_act_self_employed  = 1 if spend_day == 8
	replace main_act_planned_event  = 1 if spend_day == 4
	replace main_act_emergency      = 1 if spend_day == 6
	replace main_act_travel         = 1 if spend_day == 7
	replace main_act_family_time    = 1 if spend_day == 1
	replace main_act_friends_time   = 1 if spend_day == 3
	replace main_act_998            = 1 if spend_day == 998

	replace main_act_hh_chores      = 0 if spend_day != 2    & !mi(spend_day)
	replace main_act_home_rest      = 0 if spend_day != 5    & !mi(spend_day)
	replace main_act_self_employed  = 0 if spend_day != 8    & !mi(spend_day)
	replace main_act_planned_event  = 0 if spend_day != 4    & !mi(spend_day)
	replace main_act_emergency      = 0 if spend_day != 6    & !mi(spend_day)
	replace main_act_travel         = 0 if spend_day != 7    & !mi(spend_day)
	replace main_act_family_time    = 0 if spend_day != 1    & !mi(spend_day)
	replace main_act_friends_time   = 0 if spend_day != 3    & !mi(spend_day)
	replace main_act_998            = 0 if spend_day != 998  & !mi(spend_day)
	replace main_act_others = spend_day_others if spend_day == 998
	
* Replace earn variable with amount due if not paid on that day
	* starting only from April XX?
	 replace earn = notpaid_amt_due if earn == 0  

* Job found at stand indicator 
	gen job_found_at_stand = 1 if whenfound == 2 // found at stand !mi only if attend & work == 1
		replace job_found_at_stand = 1 if whenfound == 1 & inlist(howfound , 6, 7, 8)
		replace job_found_at_stand = 1 if whenfound == 3 & inlist(howfound , 6, 7, 8)
		replace job_found_at_stand = 0 if whenfound == 1 & !inlist(howfound , 6, 7, 8) & !mi(howfound)
		replace job_found_at_stand = 0 if whenfound == 3 & !inlist(howfound , 6, 7, 8) & !mi(howfound)
		replace job_found_at_stand = 0 if work == 1 & attend == 0 & howfound_notattend !=5 // & !mi(howfound_notattend)
		replace job_found_at_stand = 1 if work == 1 & attend == 0 & howfound_notattend ==5
	label var job_found_at_stand "Job found at stand (using whenfound variable)"

* Multi-day job (2024-05-01 added using code from 01_phase1_makevar.do)
   gen multiday_job = 1 if work == 1 & howfound == 5
      replace multiday_job = 1 if work == 1 & howfound_notattend == 5
      replace multiday_job = 0 if work == 1 & multiday_job == .
   label var multiday_job "Multi-day job (cond on working)"

   sort    pid date
   tsset   pid date 
   
   
   tsspell multiday_job 
   
   
   
   

   //Multiday Jobs is just an indicator if howfound/howfound_not attend == "multiday job", so need to edit to fit the structure
   gen multiday_job_inc = multiday_job
   //edit to fit the discussed format
   bys pid (date): replace multiday_job_inc = 1  if multiday_job == 0 & multiday_job[_n+1] == 1 & (howfound != .|howfound_notattend != .)
   label var multiday_job_inc "multiday job (corrected to include first day)" 
   //now edit the spells
   replace _spell = _spell[_n+1] if multiday_job == 0 & multiday_job_inc == 1 

   /* [> Creation of the dummies <] */ 
   //multiday first
   bys pid _spell (date): gen multiday_first = 1 if _n == 1               & multiday_job_inc == 1
   replace multiday_first = 0                    if multiday_job_inc == 1 & multiday_first != 1
   label var multiday_first "First day of multiday job"

   //multiday last
   bys pid _spell (date): gen multiday_last = 1 if _n == _N & multiday_job_inc == 1
   replace   multiday_last = 0 if multiday_job_inc == 1     & multiday_last != 1
   label var multiday_last "Last day of multiday job"

   /* [> Get the number of days in a multiday job <] */ 
   bys pid _spell (date): egen multiday_num = count(_spell) if multiday_job_inc == 1
   label var multiday_num "Duration of multiday job (days)"
   
   /* [> How the multiday job was found  <] */ 
   gen     howfound_multiday = howfound           if multiday_first == 1
   replace howfound_multiday = howfound_notattend if multiday_first == 1 & howfound_multiday == .
   bys pid _spell (date): ereplace howfound_multiday = max(howfound_multiday) if multiday_num != . 
   
   label val howfound_multiday howfound_lab
   label var howfound_multiday "How multiday job was found"
   tab howfound_multiday multiday_first, m

    /* [> When the multiday job was found  <] */     
    gen     whenfound_multiday = whenfound           if multiday_first == 1
    bys pid _spell (date): ereplace whenfound_multiday = max(whenfound_multiday) if multiday_num != . 
   
    label val whenfound_multiday whenfound_lab
    label var whenfound_multiday "When multiday job was found"
    tab whenfound_multiday multiday_first, m
   
   drop _spell _seq _end

* How job was found (2024-05-01 added using code from 01_phase1_makevar.do)
   egen howfound_overall = rowfirst(howfound howfound_notattend)
   replace howfound_overall = howfound_multiday if howfound_multiday != .
   label val howfound_overall howfound_lab
   label var howfound_overall "How the job was found overall" 
   	
/*----------------------------------------------------*/
   /* [>   5.  Variable labels   <] */ 
/*----------------------------------------------------*/

	label define work_type_lab 1  "Agricultural Worker" 2  "Fisheries" 3  "Foundation" 4  "Wall Builder" 5  "Tile Worker" 6  "Centering" 7  "Concrete" 8  "Demolisher" 9  "Loadman (in Construction)" 10 "Stone Cutter" 11 "Welder" 12 "Painter" 13 "Carpenter" 14 "Electrician" 15 "Plumber" 16 "Manual Scavenger/ Sewage work" 17 "Householed worker/ maid" 18 "Cargo Puller" 19 "Loadman" 20 "Rikshaw Puller" 21 "Porter (railway station)" 22 "Tailor" 23 "Garment/ Textile Worker" 24 "Industry and Factory Worker" 25 "Machinery Technician" 26 "Auto Driver" 27 "Cardriver" 28 "Cleaning (office spaces, roads, any other corporation related)" 29 "Scuffolding" 30 "Gardening" 31 "Vendor/shop work" 32 "Catering"

	label define role_lab 1 "Helper" 2 "Mason" 3 "Mesthri" 4 "Does not apply"						   
	label define why_attend_lab 1 "To look for a job for the same day" 2 "To meet my friends and hang out" 3 "To pick up people for a job" 4 "To get picked up by the employer" 5 "To network/secure a job for the next days" 6"To get survey money"
							
	label define whenfound_lab 1 "Already had a job before coming" 2 "At the stand" ///
	                    3 "After I left the stand" 998 "Other"

	label define howfound_lab 1 "Phone-Employer" 2 "Phone-Recruiter/contractor" 3 "Phone-friend/family" 4 "Self Employed" 5 "Multi-day job" 6 "Stand-recruiter/contractor called" 7 "Stand-friend/family"  8 "Stand-recruiter/contractor in-person"
					  
	label define howfound_notattend_lab	1 "Phone-Employer" 2 "Phone-Recruiter/contractor" 3 "Phone-friend/family" 4 "Self Employed" 5 "Multi-day job"
									
	/*4 "4. Phone - I called a recruiter/ contractor" LC - this iption seems repeated*/

	label define why_notattend_lab 1 "Thought no job at stand" 2 "Thought I would get a job through phone calls" 3 "Did not feel like going/travel" 4 "Wanted an easier job"  5 "Did not prefer a construction job" 6 "Issues at stand"

	label define spend_day_lab 1 "Spent time with my children or family" 2 "Stayed home for doing household chores" 3 "Spent time with my friends" 4 "Attended a function" 5 "Took rest" 6 "Atend to someone sick"  7 "Traveling" 8 "Work not for pay"		   

	label define how_found_native_lab 1 "1. I called some recruiters" 2 "2. I called/asked a friend or family member for work" 3 "3. I went directly to a construction/work site" 4 "4. I went to a different stand"

	label define why_nottry_lab 1 "No job at the stand" 2 "bDid not feel like working" 3 "Had physical pain" 4 "Sick/injured"  5 "Other obligations" 6 "Hungover" 7 "Emergency"	   
	* label all variables						
	local lvar work_type role why_attend whenfound howfound howfound_notattend why_notattend spend_day how_found_native why_nottry
	foreach var in `lvar' {
		label val `var' `var'_lab
	} 	

/*----------------------------------------------------*/
   /* [>   6.  Save data    <] */ 
/*----------------------------------------------------*/

	sort date interviewer pid
	
	// drop variables that not required for analysis 
	drop p0_998 gps_latitude gps_longitude gps_altitude gps_accuracy interviewer_others alternate response1 response1_a call_pick_up name_confirmation participant_available available time_available call_phonenum1 call_phonenum2 response4 call_pick_up1 call_status name_confirmation1 mask_1 mask_2 phonesurvey_consent phonenum1 convenient_time1 bs_firstday bs_daily_monthly  today recent_date recall_days_cp recall_days_mp recall_days drunk survey_proceed reason_not_proceed reason_not_proceed_others bs_sttime recall_count index_* bs_work_* *bs_earn_* bs_role_* bs_attend_* bs_why_attend_*  bs_whenfound_*  bs_howfound_* bs_native_* bs_try_work_*  bs_spend_day_*  bs_section_complete_* bs_why_notattend_1 bs_why_notattend_others_1 bs_how_found_native_1 bs_how_found_native_others_1 bs_why_nottry_1 bs_why_notattend_2 bs_why_notattend_others_2 bs_how_found_native_2 bs_how_found_native_others_2 bs_why_nottry_2 bs_why_notattend_3 bs_why_notattend_others_3 bs_how_found_native_3 bs_how_found_native_others_3 bs_why_nottry_3 bs_why_notattend_4 bs_why_notattend_others_4 bs_how_found_native_4 bs_how_found_native_others_4 bs_why_nottry_4 bs_why_notattend_5 bs_why_notattend_others_5 bs_how_found_native_5 bs_how_found_native_others_5 bs_why_nottry_5 bs_why_notattend_6 bs_why_notattend_others_6 bs_how_found_native_6 bs_how_found_native_others_6 bs_why_nottry_6 bs_why_notattend_7 bs_why_notattend_others_7 bs_how_found_native_7 bs_how_found_native_others_7 bs_why_nottry_7 count_complete complete partial_completeness paid check_completion check_reason_inc_onspot check_reason_inc_onspot_others check_reason_inc_ph check_reason_inc_ph_others check_bs_some_recalls check_pid_check phonenum_given phonenumber check_recalldays reason_mismatch_recalldays bs_time_found_* formdef_version date_available filename name_check repeat bs_time_left_stand_* recall_days_st recall_days_mpc  

	//newly added 2024-03-27
	drop spot_time_text recall_days_ind cov* key submissiondate bs_main_act_* bs_paid_filt_* bs_firsttime_emp* bs_notpaid_amt_due* b17_v2_* d_main_activity_* rb1_b1_others_* v309 v288 b17_* b14 v311
	
	order stand pid date launchset bs_start_date bs_end_date interviewer dow mode max_date bs_start_date daycount holiday attend stand_survey too_drunk go_ahead bs_interest work earn work_type work_type_others role attend why_attend why_attend_others whenfound whenfound_others howfound howfound_others time_found howfound_notattend howfound_notattend_others native try_work why_notattend why_notattend_others spend_day spend_day_others time_left_stand how_found_native how_found_native_others why_nottry 

	save "./07. Data/3. Main Study 3.0/02. Cleaning Data/03. Baseline/02. Output/04_baseline_makepanel.dta", replace

