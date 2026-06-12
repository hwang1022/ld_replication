*************************************************
*Project: Labor Displine
*Title: Employers Activity Renaming
*Author: Lakshmi (LR) / adapated by Simon Taye
*Created On: 13th July 2023
*Last Edited On: June 5, 2026


**Notes by Simon:
* /07. Data/3. Main Study 3.0/02. Cleaning Data/08. Others/01. Code/Employers Survey/employers_activity_mainstudy_renaming.do'
	* The first half of this file currently commented out is the "renaming" of the original data. It corresponds to the do-file mentioned above.
	* It outputs employer_activity_mainstudy_named 
	
* /07. Data/3. Main Study 3.0/02. Cleaning Data/08. Others/01. Code/Employers Survey/employers_activity_cleaning.do'
	* The second half of this file is derived from the do-file above. It takes the "renamed" data and applies corrections.
***************************************************

/************************************************	
*1. Import data + Append v4 data (piloting)
*************************************************
 
  use "$raw/ls_employer_activity_mainstudy_v1.dta", clear
  append using "$raw/ls_employer_activity_pilot_v4.dta"
  
  
	*Intro
	rename p1      recruiter_id
	rename p3      stand
	rename p3_998  stand_others
	rename p4      interviwer
	rename p4_998  interview_others
	rename p6      start_time
	rename ss1     first_name
	rename ss1_1   last_name
	rename p7      intrested_survey

	*Comprehension
	rename b0      comp1_how_many_trained
	rename c0      comp1_how_many_untrained
	rename d0      comp2_how_many_trained
	rename e0      comp2_how_many_untrained
	rename f0      comp3_how_many_trained
	rename g0      comp3_how_many_untrained

	*Comprehension Calculation
	rename b0_cal  calculate_comp1_trained
	rename c0_cal  calculate_comp1_untrained
	rename d0_cal  calculate_comp2_trained
	rename e0_cal  calculate_comp2_untrained
	rename f0_cal  calculate_comp3_trained
	rename g0_cal  calculate_comp3_untrained

	*2 Weeks After
	rename a1      trained_2_weeks
	rename a2      reason_2_weeks
	rename a2_1    reason_2w_tired_sick
	rename a2_2    reason_2w_more_money_native_back
	rename a2_3    reason_2w_habit
	rename a2_4    reason_2w_annoyed
	rename a2_5    reason_2w_going_native
	rename a2_6    reason_2w_earned_money
	rename a2_7    reason_2w_standard_strenght
	rename a2_8    reason_2w_work_directly
	rename a2_9    reason_2w_work_availability
	rename a2_10   reason_2w_friends_infulence
	rename a2_11   reason_2w_strenght_increase
	rename a2_12   reason_2w_strenght_decrease
	rename a2_998  reason_2w_others
	rename a_others reason_2w_others_spec

	*2 Months After
	rename b1      trained_2_months
	rename b2      reason_2_months
	rename b2_1    reason_2m_tired_sick
	rename b2_2    reason_2m_more_money_native_back
	rename b2_3    reason_2m_habit
	rename b2_4    reason_2m_annoyed
	rename b2_5    reason_2m_going_native
	rename b2_6    reason_2m_earned_money
	rename b2_7    reason_2m_standard_strenght
	rename b2_8    reason_2m_work_directly
	rename b2_9    reason_2m_work_availability
	rename b2_10   reason_2m_friends_infulence
	rename b2_11   reason_2m_strenght_increase
	rename b2_12   reason_2m_strenght_decrease
	rename b2_998  reason_2m_others
	rename b_others reason_2m_others_spec

	*4 Months After
	rename c1      trained_4_months
	rename c2      reason_4_months
	rename c2_1    reason_4m_tired_sick
	rename c2_2    reason_4m_more_money_native_back
	rename c2_3    reason_4m_habit
	rename c2_4    reason_4m_annoyed
	rename c2_5    reason_4m_going_native
	rename c2_6    reason_4m_earned_money
	rename c2_7    reason_4m_standard_strenght
	rename c2_8    reason_4m_work_directly
	rename c2_9    reason_4m_work_availability
	rename c2_10   reason_4m_friends_infulence
	rename c2_11   reason_4m_strenght_increase
	rename c2_12   reason_4m_strenght_decrease
	rename c2_998  reason_4m_others
	rename c_others reason_4m_others_spec

	*Phone Number Details
	rename k3      phone_num_avail
	rename k4      phone_num
	rename k5      payment_mode
	rename k5_1    mode_cash
	rename k5_2    mode_g_pay
	rename k5_3    mode_paytm
	rename k5_4    mode_bank
	rename k5_998  mode_others
	rename k5_others mode_specify

	*End
	rename z0       check_completion
	rename z0_1     comprehension
	rename z0_a     reason_incomplete
	rename z0_a_998 reason_incomplete_others
	rename z1       rec_id_check
	rename z2       end_time
	rename p5       date


	************************************************	
	*2.Labelling
	************************************************

	*Intro
	label var recruiter_id      "recruiter id"
	label var stand             "stand"
	label var stand_others      "stand others"
	label var interviwer        "interviwer"
	label var interview_others  "interviwer others"
	label var start_time        "start time"
	label var first_name        "first name"
	label var last_name         "last name"
	label var intrested_survey  "intrested in survey"

	*Comprehension
	label var comp1_how_many_trained     "comp 1 how many trained"
	label var comp1_how_many_untrained   "comp 1 how many untrained"
	label var comp2_how_many_trained     "comp 2 how many trained"
	label var comp2_how_many_untrained   "comp 2 how many untrained"
	label var comp3_how_many_trained     "comp 3 how many trained"
	label var comp3_how_many_untrained   "comp 3 how many untrained"


	label var  calculate_comp1_trained     "calculate comp1 trained"
	label var  calculate_comp1_untrained   "calculate comp1 untrained"
	label var  calculate_comp2_trained     "calculate comp2 trained"
	label var  calculate_comp2_untrained   "calculate comp2 untrained"
	label var  calculate_comp3_trained     "calculate comp3 trained"
	label var  calculate_comp3_untrained   "calculate comp3 untrained"


	*2 Weeks After
	label var trained_2_weeks                       "2 weeks trained"
	label var reason_2_weeks                        "2 weeks reasons"
	label var reason_2w_tired_sick                  "reason 2w tired & sick"
	label var reason_2w_more_money_native_back      "reason 2w more money & back in native"
	label var reason_2w_habit                       "reason 2w habit"
	label var reason_2w_annoyed                     "reason 2w annoyed"
	label var reason_2w_going_native                "reason 2w going native"
	label var reason_2w_earned_money                "reason 2w eanrned more money"
	label var reason_2w_standard_strenght           "reason 2w standard strenght"
	label var reason_2w_work_directly               "reason 2w work directly"
	label var reason_2w_work_availability           "reason 2w work availablity"
	label var reason_2w_friends_infulence           "reason 2w friends influence"
	label var reason_2w_strenght_increase           "reason 2w strenght increase"
	label var reason_2w_strenght_decrease           "reason 2w strenght decrease"
	label var reason_2w_others                      "reason 2w others"
	label var reason_2w_others_spec                 "reason 2w others spec"

	*2 Months After
	label var trained_2_months                      "2 months trained"
	label var reason_2_months                       "2 months reason"
	label var reason_2m_tired_sick                  "reason 2m tired & sick"
	label var reason_2m_more_money_native_back      "reason 2m more money & back in native"
	label var reason_2m_habit                       "reason 2m habit"
	label var reason_2m_annoyed                     "reason 2m annoyed"
	label var reason_2m_going_native                "reason 2m going native"
	label var reason_2m_earned_money                "reason 2m eanrned more money"
	label var reason_2m_standard_strenght           "reason 2m standard strenght"
	label var reason_2m_work_directly               "reason 2m work directly"
	label var reason_2m_work_availability           "reason 2m work availablity"
	label var reason_2m_friends_infulence           "reason 2m friends influence"
	label var reason_2m_strenght_increase           "reason 2m strenght increase"
	label var reason_2m_strenght_decrease           "reason 2m strenght decrease"
	label var reason_2m_others                      "reason 2m others"
	label var reason_2m_others_spec                 "reason 2m others spec"

	*4 Months After
	label var trained_4_months                      "4 months trained"
	label var reason_4_months                       "4 months reason"
	label var reason_4m_tired_sick                  "reason 4m tired & sick"
	label var reason_4m_more_money_native_back      "reason 4m more money & back in native"
	label var reason_4m_habit                       "reason 4m habit"
	label var reason_4m_annoyed                     "reason 4m annoyed"
	label var reason_4m_going_native                "reason 4m going native"
	label var reason_4m_earned_money                "reason 4m eanrned more money"
	label var reason_4m_standard_strenght           "reason 4m standard strenght"
	label var reason_4m_work_directly               "reason 4m work directly"
	label var reason_4m_work_availability           "reason 4m work availablity"
	label var reason_4m_friends_infulence           "reason 4m friends influence"
	label var reason_4m_strenght_increase           "reason 4m strenght increase"
	label var reason_4m_strenght_decrease           "reason 4m strenght decrease"
	label var reason_4m_others                      "reason 4m others"
	label var reason_4m_others_spec                 "reason 4m others spec"
	 

	*Phone Number Details

	label var phone_num_avail    "phone number avail"
	label var phone_num          "phone number"
	label var payment_mode       "paymnet mode"
	label var mode_cash          "mode cash"
	label var mode_g_pay         "mode gpay"
	label var mode_paytm         "mode paytm"
	label var mode_bank          "mode bank"
	label var mode_others        "mode others"
	label var mode_specify       "mode specify"

	*End
	label var check_completion         "survey completed"
	label var comprehension            "comprehension scale"
	label var reason_incomplete        "incomplete reasons"
	label var reason_incomplete_others "reasons incomplete others"
	label var rec_id_check             "recruiter id"
	label var end_time                 "end time"

	label var date                     "date"
	*/

	use "$raw/employer_activity_mainstudy_named.dta"

* Replacing Checklist (as it was created under m1 in pilot_v4)
	*Check List 1
	replace  cl_1_1= 1 if m1_1 ==1
	replace  cl_1_2= 1 if m1_2 ==1
	replace  cl_1_3= 1 if m1_3 ==1

	*Check List 2
	replace  cl_2_1= 1 if m1_4 ==1
	replace  cl_2_2= 1 if m1_5 ==1
	replace  cl_2_3= 1 if m1_6 ==1
	replace  cl_2_4= 1 if m1_7 ==1
	replace  cl_2_5= 1 if m1_8 ==1
	replace  cl_2_6= 1 if m1_9 ==1

	*Check List 3
	replace  cl_3_1= 1 if m1_10 ==1
	replace  cl_3_2= 1 if m1_11 ==1
	replace  cl_3_3= 1 if m1_12 ==1
	replace  cl_3_4= 1 if m1_13 ==1
	replace  cl_3_5= 1 if m1_14 ==1

	*Check List 4
	replace  cl_4_1= 1 if m1_15 ==1
	replace  cl_4_2= 1 if m1_16 ==1
	replace  cl_4_3= 1 if m1_17 ==1

* Combined check list of pilot_v4 
	drop m1_*

* Replacing the dropped out survey with missing variable
	replace trained_2_weeks  = . if trained_2_weeks ==  1 | trained_2_weeks == 999
	replace trained_2_months = . if trained_2_months == 1 | trained_2_months == 999
	replace trained_4_months = . if trained_4_months == 1 | trained_4_months == 999
	replace reason_2w_others_spec ="" if regexm(reason_2w_others_spec, "999|Survey was incomplete|Survey incomplete")
	replace reason_2m_others_spec ="" if regexm(reason_2m_others_spec, "999|Survey was incomplete|Survey incomplete")
	replace reason_4m_others_spec ="" if regexm(reason_4m_others_spec, "999|Survey was incomplete|Survey incomplete")
	* Compreh. cleaning
	replace comp1_how_many_trained   = . if comp1_how_many_trained   == 1
	replace comp1_how_many_untrained = . if comp1_how_many_untrained == 1
	replace comp3_how_many_trained   = . if comp3_how_many_trained   == 1 |comp3_how_many_trained   == 999
	replace comp3_how_many_untrained = . if comp3_how_many_untrained == 1 |comp3_how_many_untrained == 999

	* Cleaning dropout - mentioned in the field

	replace reason_2_weeks = ""  if reason_2_weeks  == "998" & recruiter_id == 68   & key == "uuid:522065ba-8ae2-4c10-b4e2-7075e7acf795"
	replace reason_2_months = "" if reason_2_months == "998" & recruiter_id == 68   & key == "uuid:522065ba-8ae2-4c10-b4e2-7075e7acf795"
	replace reason_4_months = "" if reason_4_months == "998" & recruiter_id == 68   & key == "uuid:522065ba-8ae2-4c10-b4e2-7075e7acf795"
	replace reason_2_weeks  = "" if reason_2_weeks  == "998" & recruiter_id == 9402 & key == "uuid:cb80adde-caac-487a-873f-b4508b254dac"
	replace reason_2_months = "" if reason_2_months == "998" & recruiter_id == 9402 & key == "uuid:cb80adde-caac-487a-873f-b4508b254dac"
	replace reason_4_months = "" if reason_4_months == "998" & recruiter_id == 9402 & key == "uuid:cb80adde-caac-487a-873f-b4508b254dac"
	replace reason_2_weeks  = "" if reason_2_weeks  == "998" & recruiter_id == 9209 & key == "uuid:d3420082-9e16-4b47-a90b-4658f415c16d"
	replace reason_2_months = "" if reason_2_months == "998" & recruiter_id == 9209 & key == "uuid:d3420082-9e16-4b47-a90b-4658f415c16d"
	replace reason_4_months = "" if reason_4_months == "998" & recruiter_id == 9209 & key == "uuid:d3420082-9e16-4b47-a90b-4658f415c16d"
	*Surveyors have marked these options in others by mistake

	replace reason_2m_strenght_increase = 1 if recruiter_id == 66   & key == "uuid:af7656e5-27f7-4835-bfa3-dd290177e069" // surveyor marked it under the other option
	replace reason_4m_work_availability = 1 if recruiter_id == 9701 & key == "uuid:bf4d7bfd-0ec5-454f-be86-b7c96f3a6816" // surveyor marked it under the other option
	replace mode_cash =  1                  if recruiter_id == 62   & key == "uuid:82dff99a-6026-4183-b46c-da7c252be309" // surveyor marked it under the other option
	replace mode_g_pay = 1                  if recruiter_id == 62   & key == "uuid:82dff99a-6026-4183-b46c-da7c252be309" // surveyor marked it under the other option
	replace mode_paytm = 1                  if recruiter_id == 62   & key == "uuid:82dff99a-6026-4183-b46c-da7c252be309" // surveyor marked it under the other option
	replace mode_bank =  1                  if recruiter_id == 62   & key == "uuid:82dff99a-6026-4183-b46c-da7c252be309" // surveyor marked it under the other option

	*Translating Tamil string variables into English
	*2 weeks after reasons specifications
	replace reason_2w_others_spec = "They have been habituated and few might not have come to the stand becase of family situation" ///
		if key == "uuid:9bf49b57-3591-4e89-b078-25828f0b3350"
	replace reason_2w_others_spec = "Cash transfers have habituated them to come regularly" ///                                         
		if key == "uuid:d20e354a-24ab-492f-bf5f-2f50a60c3b18"
	*2 Months after reasons specifications
	replace reason_2m_others_spec = "They might have gone to attend functions and festivals" ///
		if key == "uuid:ec18c28a-f7cf-449a-930d-a7f29f0e0e1a"
	replace reason_2m_others_spec = "Cash transfers have habituated them to come regularly"  ///
		if key == "uuid:d20e354a-24ab-492f-bf5f-2f50a60c3b18"
	*4 Months after reasons specifications
	replace reason_4m_others_spec = "There are no job availablity from mid July-mid Aug"                  /// 
		if key == "uuid:bf4d7bfd-0ec5-454f-be86-b7c96f3a6816"
	replace reason_4m_others_spec = "They take few people to jobs to help them in difficult times"        ///
		if key == "uuid:6e981dbe-40ab-4630-a55a-badd49233046"
	replace reason_4m_others_spec = "If their regular job end, they will agin come to stand to find jobs" ///
		if key == "uuid:af7656e5-27f7-4835-bfa3-dd290177e069"

	*Notes
	replace notes = "As soon as section B started partcipant said he don't know answers for all this & left" if key == "uuid:cb80adde-caac-487a-873f-b4508b254dac"
	replace notes = "Kept repeating that never all the 100 will turn up"                                     if key == "uuid:47a772c6-792c-4f4e-9c94-20aed06d53b4"
	replace notes = "Tought a lot before spaking up"                                                         if key == "uuid:e370ac0a-7bdb-4129-85de-dac90d0555df"
	replace notes = "Was busy in recruitment process and just answers for a sake of it"                      if key == "uuid:62b61903-b44d-434a-aabb-8886e95d7791"
	replace notes = "Was busy in recruitment process"                                                        if key == "uuid:b257a54d-a291-4a64-ac1d-1e6d4b3fc31c"
	replace notes = "Partcipant was time contrained to concetrate and answer"                                if key == "uuid:d3420082-9e16-4b47-a90b-4658f415c16d"
	replace notes = "Was busy in phone"                                                                      if key == "uuid:69e26c01-8d07-4a7e-9525-c980aba3803f"
	replace notes = "He was in hurry to leave the stand"                                                     if key == "uuid:135b4e59-817c-4e76-876e-15e1ddef67e2"
	replace notes = "Was busy in recruitment process"                                                        if key == "uuid:d2d30805-b11c-4701-9b82-526081343e6d"
	replace notes = "Was busy in recruitment process"                                                        if key == "uuid:98c9ab8a-044d-4a6d-8ba5-6ce97e4f282c"

	* Drop unwanted vars
	drop deviceid devicephonenum username device_info caseid

************************************************	
*Save
************************************************
	order recruiter_id date interviwer stand stand_others

	save "$final/ls_employer_activity_mainstudy_named.dta", replace
