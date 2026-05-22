**************************************************
**************************************************
*	Project: LD Main Study
*	Purpose: Construct Time use survey Vars 
*	Author: HW, based on DL and PB
*	Last modified: Jan 22, 2024
**************************************************
**************************************************
 
 
 
 
/*----------------------------------------------------*/
   /* [>   1.  Load cleaned data   <] */ 
/*----------------------------------------------------*/

	use "$temp/lss_time_use_cleaned_hw.dta", clear
	isid pid date


/*----------------------------------------------------*/
   /* [>   3.  Label variables   <] */ 
/*----------------------------------------------------*/

	la var time_activity_tot_1  "Total time in the morning (5.30am-9am) to Get water"
	la var time_activity_tot_2  "Total time in the morning (5.30am-9am) to Cook breakfast"
	la var time_activity_tot_3  "Total time in the morning (5.30am-9am) to Eat breakfast"
	la var time_activity_tot_4  "Total time in the morning (5.30am-9am) to Help get kids ready for school"
	la var time_activity_tot_5  "Total time in the morning (5.30am-9am) to Drop kids at school"
	la var time_activity_tot_6  "Total time in the morning (5.30am-9am) to Wash/bathe"
	la var time_activity_tot_7  "Total time in the morning (5.30am-9am) to Go to temple/prayers/meditate"
	la var time_activity_tot_8  "Total time in the morning (5.30am-9am) to Go to the store/shop"
	la var time_activity_tot_9  "Total time in the morning (5.30am-9am) to Call employers/friends to find a job"
	la var time_activity_tot_10 "Total time in the morning (5.30am-9am) to Travel"
	la var time_activity_tot_11 "Total time in the morning (5.30am-9am) to Sleep"
	la var time_activity_tot_12 "Total time in the morning (5.30am-9am) to Be at the stand/ Search for work "

	la var time_activity_1_adj "Total time in the morning (5.30am-9am) to Get water adjusted"
	la var time_activity_2_adj "Total time in the morning (5.30am-9am) to Cook breakfast adjusted"
	la var time_activity_3_adj "Total time in the morning (5.30am-9am) to Eat breakfast adjusted"
	la var time_activity_4_adj "Total time in the morning (5.30am-9am) to Help get kids ready for school adjusted"
	la var time_activity_5_adj "Total time in the morning (5.30am-9am) to Drop kids at school adjusted"
	la var time_activity_6_adj "Total time in the morning (5.30am-9am) to Wash/bathe adjusted"
	la var time_activity_7_adj "Total time in the morning (5.30am-9am) to Go to temple/prayers/meditate adjusted"
	la var time_activity_8_adj "Total time in the morning (5.30am-9am) to Go to the store/shop adjusted"
	la var time_activity_9_adj "Total time in the morning (5.30am-9am) to Call employers/friends to find a job adjusted"
	la var time_activity_10_adj "Total time in the morning (5.30am-9am) to Travel adjusted"
	la var time_activity_11_adj "Total time in the morning (5.30am-9am) to Sleep adjusted"
	la var time_activity_12_adj "Total time in the morning (5.30am-9am) to Be at the stand/ Search for work  adjusted"
	
	// la var time_activity_998_adj "Total time in the morning (5.30am-9am) to Others adjusted"
	la var time_activity_13_adj "Total time in the morning (5.30am-9am) to Nothing adjusted"
	la var time_activity_14_adj "Total time in the morning (5.30am-9am) to HH chores adjusted"
	la var time_activity_15_adj "Total time in the morning (5.30am-9am) to Watching adjusted"
	la var bedtime              "Bedtime"
	la var time_whodid1         "Who more likely to Get water"
	la var time_whodid2         "Who more likely to Cook breakfast"
	la var time_whodid4         "Who more likely to Help get kids ready for school"
	la var time_whodid5         "Who more likely to Drop kids at school"
	la var time_whodid8         "Who more likely to Go to the store/shop"
	la var jfp_8am              "Days of work will find next week if come to the stand everyday at 8am"
	la var jfp_9am              "Days of work will find next week if come to the stand everyday at 9am"

	
	
	
	rename * tu_*
	

	rename tu_pid pid 
	rename tu_date date 
	rename tu_tu_version tu_version 
	label var tu_version "Time use survey version"

	
/*----------------------------------------------------*/
   /* [>   4.  Save data   <] */ 
/*----------------------------------------------------*/

	save "$temp/03-time-use-makevar.dta", replace
