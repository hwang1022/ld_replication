*********************************************************
*********************************************************
*														*
*	Master Do-File: LD									*
*	Date Created: Oct 7 2024 by HW						*
*	Last Modified: Apr 17 2026 by HW					*
*														*
*	This master do-file defines globals and programs 	*
*	and cleans individual survey rounds					*
* 	and creates final dataset							*
* 	and conducts analysis								*
*														*
*********************************************************
*********************************************************
	
**********************
**# Initialize Stata
**********************

	cap ssc install ietoolkit, replace
	cap ssc install grstyle, replace
 	ieboilstart, version(18.0)
 	* ieboilstart, version(15.1)
	`r(version)'
	
	set seed 42
	
	cap ssc install grstyle, replace
 	set scheme s2color
 	graph set window fontface "Times New Roman" 
 	grstyle init
 	grstyle color background white
 	grstyle linepattern major_grid dash

	
*******************
**# Define Macros
*******************

****
**## Run dofiles
****
	
	* Indicator directory defined 
	global 	MasterRunning = 1
	
	* Whether run everything, or just define directories
		* Install Packages: Install packages written by Hao Wang used in the analysis
		* Run Cleaning: cleaning of the surveys
		* Run Analysis: Generate tables and figures in the paper and slides
	local 	install_packages 			= 0
	local 	run_cleaning 				= 0
	local 	run_analysis 				= 0

	**# The version of Data to use
	global data_version "new" // "original" or "new"
	global data_version_new "prioritize_in_person" // "prioritize_date" or "prioritize_in_person". If you chose "original", this option is ignored.

	* If prioritize in-person recall over recalls made on phone but on a closer date.
	if "$data_version_new" == "prioritize_in_person" global prioritize_in_person = 1
	if "$data_version_new" == "prioritize_date" global prioritize_in_person = 0

	* The cleaning code for original data, written by Yogita's RA, is not automated
	if `run_cleaning' == 1 & "$data_version" == "original" {
		di as error "Cannot run cleaning with original data version. Cleaning is only available for new data versions."
		exit
	}



	
****
**## Directories
****

	* If your Dropbox is in you home directory
	global db_dir "~/Dropbox"

	* If you use Windows or you Dropbox not in the default location
	if 	"`c(username)'" == "hschof"							global db_dir "C:/Users/hschof/Dropbox"

	global ld_dir 				"$db_dir/Labor Discipline"
	global replication_dir 		"$ld_dir/07. Data/3. Main Study 3.0/ld_replication"
	global code 				"$replication_dir/code"
	global raw 					"$replication_dir/data/raw"
	global temp 				"$replication_dir/data/temp"
	global final 				"$replication_dir/data/final"
	global external 			"$replication_dir/data/external"

	* The Original Dataset, last edited in July 2024
	global original_main 				"$final/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta"  
	
	* The New Dataset 
	global new_main_prioritize_date 		"$final/final_data_prioritize_date.dta"
	global new_main_prioritize_in_person 	"$final/final_data_prioritize_in_person.dta"


	* determine which set of dofiles to run
	if "$data_version" == "original" {
		global main_data "$original_main"
		global output "$replication_dir/output/original"
	}
	else if "$data_version_new" == "prioritize_date" {
		global main_data "$new_main_prioritize_date"
		global output "$replication_dir/output/prioritize_date"
	}
	else if "$data_version_new" == "prioritize_in_person" {
		global main_data "$new_main_prioritize_in_person"
		global output "$replication_dir/output/prioritize_in_person"
	}

	global tables 	"$output/tables"
	global figures 	"$output/figures"
	global stats 	"$output/stats"

	di "Main data: $main_data"

****				   
**## List Stands Chracteristics
****			   
				   
	* Dropped stands
	global droplist "4, 7, 8, 9, 10, 11, 12, 14, 19"

	* Different cutoff times
	global cutoff_0815 "2, 6, 15, 17, 19, 20"
	global cutoff_0745 "12"

	* Union PIDs
	global union_pid "1409, 1414, 1416, 1448"

	* Formal Dropouts
	global dropout_pid "2107, 555, 547, 646, 689, 641, 1405, 1903, 1928, 2020, 1744, 1333"	 
	
****
**## Define Programs
****	
	
	do "$code/1.macro.do"
	

****
**## Install Packages
****	

	* <FIXME>
	* LC 4/18/26 added package boottest
	* LC 4/21/26 added package elabel
	* Also: it references HW's github
	if `install_packages' == 1 {
		local packagelist baltab strclean more_or_less
		foreach package in `packagelist' {
			cap net uninstall `package'
			net install `package', from(https://raw.githubusercontent.com/haowang5/stata/main/) replace
		}

		ssc install boottest, replace 
		ssc install elabel, replace 
	}
	
// 	local github https://raw.githubusercontent.com
// 	net install staggered, from(`github'/mcaceresb/stata-staggered/main) replace
*******************	
**# Data Creation
*******************
if `run_cleaning' == 1 {
	
****
**## 1.  Screening
****

	* Last Edited by HW Nov 8 2024
	
	* Input: 	01_screening_named.dta
	* Output: 	
		* 06_screening_dem_vars_with_pid.dta	(Demographics vars only, will be merged into main data)
		* 07_screening_makevar_with_pid.dta		(All vars)
	
	
	* Clean raw data, save completed surveys
	* Manual corrections made by field team
	* HW assumes everything is correct
	include "$code/1_1_screening/1_screening_cleaning.do"

	* Clean up variables - gen ss_* variables
	include "$code/1_1_screening/2_screening_makevar.do"

	* Merge in pid
	include "$code/1_1_screening/3_screening_merge_pid.do"

	
****
**## 2.  Baseline
****	

	* Last Edited by HW Dec 10 2024

	* Input dataset: 	01_baseline_named.dta
	* Output dataset: 	
		* 05_baseline_makevar.dta 	(Baseline Panel Data)
		* 05_baseline_cov.dta 		(PID level baseline data, used as covs in regression)
	
	* Note: keep only surveys conducted at stand AND phone surveys that're completed


	* Clean raw data, manually fixes errors
	* Manual corrections made by field team
	* HW assumes everything is correct (Except fixing spot time associated with two deviceids in Feb 2025)
	include "$code/1_2_baseline/1_baseline_cleaning.do"


	* Make panel
	include "$code/1_2_baseline/2_baseline_makepanel.do"
	* Updated the launchset based on the dta file Luisa shared. Data will change as panel construction relies on launchset variable.
	* FIXME check with Luisa: when using launch_prefill_pidwise_2022.dta to update the launchset variable, there are a few PIDs that are not present in launch_prefill_pidwise_2022.dta.


	* Make aggregate variables
	include "$code/1_2_baseline/3_baseline_makevars.do"


	
	
	
****
**## 3a.  Demographics (HW checked on Nov 8)
****
	
	* Input: 	01_bs_demographics_p1_named.dta and 02_bs_demographics_p2_named.dta
	* Output: 	03_bs_demographics_completed_makevar.dta

	* Clean raw data
	* Manual corrections made by field team
	include "$code/1_3_demographics/1_baseline_demographics_cleaning.do"
	* Several PIDs with more than one entry - YS/LC decided to keep only the first entry for each duplicate PID

	* Make variables
	include "$code/1_3_demographics/2_baseline_demographics_makevar.do"



****	
**## 4. Announcement
****

	* Input: 	01_announcement_named.dta
	* Output: 	04_announcement_completed_makevar.dta (Comprehensive dataset containing all questions)
	*			05_announcement_list.dta (list of participants from non-drop list stands)

	* Restrict sample to those not in droplist and manual cleaning 
	include "$code/1_4_announcement/1_announcement_cleaning.do"

	* Clean responses and produce output dataset
	include "$code/1_4_announcement/2_announcement_makevar.do"

	* Create a list of main study sample
	include "$code/1_4_announcement/3_announcement_main_sample.do"
	

	
	
****
**##  4.  Phase 1 and 2
****		

	* Input: 	01_phase1_named.dta 
	*			01_phase2_named.dta
	
	* Output: 	06_phase1_phase2_makevar.dta

	/* [> Cleaning <] */ 
	* HW assumes all the manual corrections are correct
	include "$code/1_5_phase_1_2/1_phase1_cleaning.do"
	include "$code/1_5_phase_1_2/2_phase2_cleaning.do"

	/* [> Combine Phase 1 and 2 <] */
	include "$code/1_5_phase_1_2/3_combine_phase1_2.do"

	/* [> Make Panel <] */
	include "$code/1_5_phase_1_2/4_phase1_2_make_panel.do"

	/* [> Make Vars <] */
	include "$code/1_5_phase_1_2/5_phase1_2_makevar.do"
	

	
****	
**##  4.  Phase 3
****

	* Clean and Make Panel for Phase 3
	include "$code/1_6_phase_3/1_phase3_cleaning.do"
	
	
****	
**##  5.  Phase 2 Activities
****

**### Flex test

	* Last Edited by HW in May 2025

	* Survey Tools Name: lss_p2_flexibility_act
	* There are two versions of the questionnaire, Stands 1-6 and Stands 13-20, hence two do files per step below.

	/* [> Clean raw data, save completed surveys <] */ 
		* manual corrections made by field team
	include "$code/2_1_flexibility/1_phase2_act_flextest_cleaning_v1.do"
	include "$code/2_1_flexibility/2_phase2_act_flextest_cleaning_v2.do"

	/* [> Make variables, drop variables not needed in analysis <] */
	include "$code/2_1_flexibility/3_phase2_act_flextest_makevar.do"

	
	
**### Job Finding Probability (JFP)
	
	* Last Edited by HW in May 2025 (Only cleaned expectation, not recall)
	* Survey Tools Name: lss_jfp_recall_survey
	
	* Clean raw data, save completed surveys
	include "$code/2_2_job_finding_probability/1_recall_cleaning.do"

	* Make variables
	include "$code/2_2_job_finding_probability/2_recall_makevar.do"
	
	
	
	
**### Vignettes survey 

	* Last Edited by HW in Feb 2025

	/* [> Clean raw data, save completed surveys <] */ 
	include "$code/2_3_vignettes/1_phase2_act_vignettes_cleaning.do"

	/* [> Make variables <] */
	include "$code/2_3_vignettes/2_phase2act_vignettes_makevar.do"
	
	
	
**### Networks
	* <FIXME> LC 4/21 returns an error --> need to install elabel
	* Last Edited by HW in May 2025
	
	include "$code/2_4_networks/1_networks_cleaning.do"
	
	
	
	
**### Job list test

	
	* Survey Tools Name: ls_p2_contract_activity

	/* [> Clean raw data, save completed surveys <] */
		* manual corrections made by field team
	* FIXME PENDING HAO TO CLEAN UP
	include "$code/2_5_job_list/1_phase2_act_joblist_cleaning_v1.do"
	include "$code/2_5_job_list/2_phase2_act_joblist_cleaning_v2.do"

	/* [> Make variables, drop variables not needed in analysis <] */
	* FIXME PENDING HAO SEEMS TO BE IN THE MIDDLE OF CLEAN UP
	* FIXME YS made some changes on 08-20-2024 - still need to understand the variables from the earlier versions of this test.
	include "$code/2_5_job_list/3_phase2_act_joblist_combined_makevar.do"

	/*
	include "$code/2_6_labor_demand/1_phase2_act_labordemand_cleaning.do"
	include "$code/2_6_labor_demand/2_phase2_act_labordemand_makevar.do"
	*/
	
	



	
****	
**## 6.  Other surveys
****

**## Phase 1 Incentive Payment

include "$code/2_7_incentive/1_clean_incentive_spreadsheet.do"



**### Time Use

	/*

	* Last Edited by HW in May 2025
	
	* Output: $final/lss_time_use_cleaned_hw.dta

	* Create Stata datasets from raw data
	include "$code/3_time_use/1_time_use_renaming.do"

	* Clean Data, Make Variables
	include "$code/3_time_use/2_time_use_cleaning.do"
	include "$code/3_time_use/3_time_use_makevar.do"

*/
	
	
**### Shocks Module
	
	* Last Edited by HW in Oct 2024
	
	* Manual corrections based on LC's code
	* Cleaning of varaibles
	// Shocks module not included in replication package
	

**### Wives survey
	// Wives survey not included in replication package

	
	
**### Picture Quiz
	
	* Last Edited by HW in May 2025
	
	include "$code/4_picture_quiz/1_picture_quiz_makevar.do"
	

**### Odd jobs module
	
	* FIXME PENDING TO ADD
	
	


******************************************
**# 9. Analysis Prep: Make Final Dataset
******************************************
	
	* Make Daily Weekly Dataset
	include "$code/6_analysis_prep/1_merge_main_surveys.do"

	* Make Final Dataset
	include "$code/6_analysis_prep/2_produce_final_dataset.do"
	


*************************
**# 10. Employer Survey
*************************

	* Last Edited by HW May 8 2025

	* Input: 
		* ls_employers_survey_v1.dta
		* ls_employers_survey_v2.dta
		* ls_employers_survey_v3.dta
		* ls_employers_survey_avadi_v1.dta
		* ls_employers_survey_avadi_v2.dta
	* Output: ls_employers_survey_combined.dta
	
	include "$code/5_employer/01_clean_avadi_v1.do"
	include "$code/5_employer/01_clean_avadi_v2.do"
	include "$code/5_employer/01_clean_v1.do"
	include "$code/5_employer/01_clean_v2.do"
	include "$code/5_employer/01_clean_v3.do"
	include "$code/5_employer/02_append_data.do"





	use "$main_data", clear
}


**************
**# Analysis
**************

if `run_analysis' == 1 {
	
	include "$code/analysis/ld_replication.do"
	
}

