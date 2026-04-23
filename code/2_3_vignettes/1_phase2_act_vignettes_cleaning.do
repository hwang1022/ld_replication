**************************************************
*Project: LD Main Study
*Purpose: Phase 2 activity - vignettes Renaming  
*Author: Luisa
*Last modified: 2024-05-06 (YS)
**************************************************

/*----------------------------------------------------*/
   /* [>   1.  Open data    <] */ 
/*----------------------------------------------------*/

	use "$raw/01a_phase2act_vignettes_named.dta", clear
	
/*----------------------------------------------------*/
   /* [>   2.  Clean data    <] */ 
/*----------------------------------------------------*/

	//03-06-2022
	replace cog_pref_rank_flex = 4          if key == "uuid:52100e79-fe8b-44f5-8a9f-cdc9b7799ee3" | key == "uuid:77e2b64c-60e6-4398-8d8f-981189493d29"
	replace cog_pref_rank_ontime_pay = 4    if key == "uuid:79da015c-b905-406a-b6eb-cf3aaaf9ff76"
	replace cog_pref_rank_safety = 3        if key == "uuid:e7e2e7a1-7860-4cde-b51e-e4e0ed2cbcf7"
	//03-07-2022
	drop if key == "uuid:e32c448a-819f-4920-aa0e-1dc47ecbdf3e" // duplicate
	//21-09-2022
	replace cog_pref_rank_flex = 4 if key == "uuid:35085e67-1dbd-41bc-8bbd-26d4647b0b8e"
	//28-09-2022
	replace cog_pref_rank_flex = 4 if key == "uuid:d5735653-5bc3-4bb0-b06e-147590a25b90"
	//10-10-2022
	drop if key == "uuid:9b81bfae-b405-416d-9094-7f4f6e7bb4ef" // duplicate
	gen version = 1 if filename == "ls_p2_vignettes_survey_v1" | filename == "ls_p2_vignettes_survey_v2"
	replace version = 2 if filename == "ls_p2_vignettes_survey_v3"
	
		//this PID did not respond for 1 rank --> assume is a tablet error so replaced the missing one with the rank
	replace cog_pref_rank_safety = 1 if cog_pref_rank_safety == . & key == "uuid:9e87ef0e-0d6c-4040-9510-cd6049f98e0f"
	
	gen i_festival_work_choice = i_beach_carnival_work_choice if version == 1
	replace i_beach_carnival_work_choice = . if version == 1
	gen i_life_philosophy_agreement_v2 = i_life_philosophy_agreement if version == 2
	replace i_life_philosophy_agreement = . if version == 2

/*----------------------------------------------------*/
   /* [>   3.  Save data    <] */ 
/*----------------------------------------------------*/

	saveold "$temp/02a_phase2act_vignettes_cleaned.dta", replace
	
	keep if check_completion == 1

	sort pid date
	order pid date stand cog_* r_* i_*
	saveold "$temp/03a_phase2act_vignettes_cleaned_completed.dta", replace
	
