**************************************************
**************************************************
*	Project: LD Main Study
*	Purpose: Convert Time Use from 
* 	SurveyCTO Export to Dta
* 	
*	Author: HW
*	Last modified: May 12, 2024 HW
**************************************************
**************************************************


****************
**# Convert V1
****************

	* import_lss_time_use_module_v1.do
*
* 	Imports and aggregates "lss_time_use_module_v1" (ID: lss_time_use_module_v1) data.
*
*	Inputs:  "$datadir/08. Others/02. Output/Time Use/lss_time_use_module_v1_WIDE.csv"
*	Outputs: "$datadir/08. Others/02. Output/Time Use/lss_time_use_module_v1.dta"
*
*	Output by SurveyCTO January 23, 2025 4:19 PM.

* initialize Stata
clear all
set more off
set mem 100m

* initialize workflow-specific parameters
*	Set overwrite_old_data to 1 if you use the review and correction
*	workflow and allow un-approving of submissions. If you do this,
*	incoming data will overwrite old data, so you won't want to make
*	changes to data in your local .dta file (such changes can be
*	overwritten with each new import).
local overwrite_old_data 0

* initialize form-specific parameters
local csvfile "$raw/lss_time_use_module_v1_WIDE.csv"
local dtafile "$temp/lss_time_use_module_v1.dta"
local corrfile "$raw/lss_time_use_module_v1_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid subscriberid simid devicephonenum username duration caseid text_audit p0 p0_998 p2 p2_998 stand name launchset treatment slots activity_repeat_count index_* time_label_repeat_*"
local text_fields2 "time_activity_* time_activity_others_* z0_a_998 notes instanceid"
local date_fields1 "p3"
local datetime_fields1 "submissiondate starttime endtime"

disp
disp "Starting import of: `csvfile'"
disp

* import data from primary .csv file
insheet using "`csvfile'", names clear

* drop extra table-list columns
cap drop reserved_name_for_field_*
cap drop generated_table_list_lab*

* continue only if there's at least one row of data to import
if _N>0 {
	* drop note fields (since they don't contain any real data)
	forvalues i = 1/100 {
		if "`note_fields`i''" ~= "" {
			drop `note_fields`i''
		}
	}
	
	* format date and date/time fields
	forvalues i = 1/100 {
		if "`datetime_fields`i''" ~= "" {
			foreach dtvarlist in `datetime_fields`i'' {
				cap unab dtvarlist : `dtvarlist'
				if _rc==0 {
					foreach dtvar in `dtvarlist' {
						tempvar tempdtvar
						rename `dtvar' `tempdtvar'
						gen double `dtvar'=.
						cap replace `dtvar'=clock(`tempdtvar',"MDYhms",2025)
						* automatically try without seconds, just in case
						cap replace `dtvar'=clock(`tempdtvar',"MDYhm",2025) if `dtvar'==. & `tempdtvar'~=""
						format %tc `dtvar'
						drop `tempdtvar'
					}
				}
			}
		}
		if "`date_fields`i''" ~= "" {
			foreach dtvarlist in `date_fields`i'' {
				cap unab dtvarlist : `dtvarlist'
				if _rc==0 {
					foreach dtvar in `dtvarlist' {
						tempvar tempdtvar
						rename `dtvar' `tempdtvar'
						gen double `dtvar'=.
						cap replace `dtvar'=date(`tempdtvar',"MDY",2025)
						format %td `dtvar'
						drop `tempdtvar'
					}
				}
			}
		}
	}

	* ensure that text fields are always imported as strings (with "" for missing values)
	* (note that we treat "calculate" fields as text; you can destring later if you wish)
	tempvar ismissingvar
	quietly: gen `ismissingvar'=.
	forvalues i = 1/100 {
		if "`text_fields`i''" ~= "" {
			foreach svarlist in `text_fields`i'' {
				cap unab svarlist : `svarlist'
				if _rc==0 {
					foreach stringvar in `svarlist' {
						quietly: replace `ismissingvar'=.
						quietly: cap replace `ismissingvar'=1 if `stringvar'==.
						cap tostring `stringvar', format(%100.0g) replace
						cap replace `stringvar'="" if `ismissingvar'==1
					}
				}
			}
		}
	}
	quietly: drop `ismissingvar'


	* consolidate unique ID into "key" variable
	replace key=instanceid if key==""
	drop instanceid


	* label variables
	label variable key "Unique submission ID"
	cap label variable submissiondate "Date/time submitted"
	cap label variable formdef_version "Form version used on device"
	cap label variable review_status "Review status"
	cap label variable review_comments "Comments made during review"
	cap label variable review_corrections "Corrections made during review"


	label variable p0 "P0. Which stand are you taking the survey at?"
	note p0: "P0. Which stand are you taking the survey at?"

	label variable p0_998 "P0_998. Others, specify:"
	note p0_998: "P0_998. Others, specify:"

	label variable p0_alatitude "P0_A. Geographic location of the stand. (latitude)"
	note p0_alatitude: "P0_A. Geographic location of the stand. (latitude)"

	label variable p0_alongitude "P0_A. Geographic location of the stand. (longitude)"
	note p0_alongitude: "P0_A. Geographic location of the stand. (longitude)"

	label variable p0_aaltitude "P0_A. Geographic location of the stand. (altitude)"
	note p0_aaltitude: "P0_A. Geographic location of the stand. (altitude)"

	label variable p0_aaccuracy "P0_A. Geographic location of the stand. (accuracy)"
	note p0_aaccuracy: "P0_A. Geographic location of the stand. (accuracy)"

	label variable p1 "P1. PID:"
	note p1: "P1. PID:"

	label variable p1_1 "P1_1. Which batch does the PID belong to?"
	note p1_1: "P1_1. Which batch does the PID belong to?"
	label define p1_1 1 "1" 2 "2" 3 "3"
	label values p1_1 p1_1

	label variable p2 "P2. Interviewer's name:"
	note p2: "P2. Interviewer's name:"

	label variable p2_998 "P2_998. Other:"
	note p2_998: "P2_998. Other:"

	label variable p3 "P3. Date:"
	note p3: "P3. Date:"

	label variable p4 "P4. Is your name \${name}?"
	note p4: "P4. Is your name \${name}?"
	label define p4 1 "Yes" 0 "No" 999 "999. Survey was incomplete"
	label values p4 p4

	label variable bed_time "What time do you typically go to bed every night?"
	note bed_time: "What time do you typically go to bed every night?"

	label variable work_8 "1. Keeping in mind how many days you worked last week, how many days of work do "
	note work_8: "1. Keeping in mind how many days you worked last week, how many days of work do you think you will find next week if you come to the stand everyday at 8am?"

	label variable work_9 "2. Keeping in mind how many days you worked last week, how many days of work do "
	note work_9: "2. Keeping in mind how many days you worked last week, how many days of work do you think you will find next week if you come to the stand everyday at 9am?"

	label variable z0 "Z0. Has the survey been completed?"
	note z0: "Z0. Has the survey been completed?"
	label define z0 1 "Yes" 0 "No" 999 "999. Survey was incomplete"
	label values z0 z0

	label variable z0_1 "Z0_1. Please rate the participant's comprehension on a scale of 1-5"
	note z0_1: "Z0_1. Please rate the participant's comprehension on a scale of 1-5"
	label define z0_1 1 "1" 2 "2" 3 "3" 4 "4" 5 "5"
	label values z0_1 z0_1

	label variable z0_a "Z0_A. If not, what is the reason it has been left incomplete?"
	note z0_a: "Z0_A. If not, what is the reason it has been left incomplete?"
	label define z0_a 1 "1. Had to leave immediately/Did not have time" 2 "2. Was not interested" 3 "3. Felt uncomfortable with questions" 4 "4. Friends did not allow him to take the survey completely" 5 "5. Participant was drunk" 998 "998. Others"
	label values z0_a z0_a

	label variable z0_a_998 "Z0_A_998. Others, specify_______________"
	note z0_a_998: "Z0_A_998. Others, specify_______________"

	label variable z1 "DO NOT READ: Re-enter PID: ____"
	note z1: "DO NOT READ: Re-enter PID: ____"

	label variable z2 "Interview End Time: ____"
	note z2: "Interview End Time: ____"

	label variable notes "Notes_____________________"
	note notes: "Notes_____________________"



	capture {
		foreach rgvar of varlist time_activity_* {
			label variable `rgvar' "Which activities do you do between \${time_label_repeat}?"
			note `rgvar': "Which activities do you do between \${time_label_repeat}?"
		}
	}

	capture {
		foreach rgvar of varlist time_activity_others_* {
			label variable `rgvar' "Others, specify:"
			note `rgvar': "Others, specify:"
		}
	}

	capture {
		foreach rgvar of varlist time_whodid1_* {
			label variable `rgvar' "Who would have been more likely to do this activity, '1. Get water' two months a"
			note `rgvar': "Who would have been more likely to do this activity, '1. Get water' two months ago?"
			label define `rgvar' 1 "1. Myself" 2 "2. Wife" 3 "3. Someone else in the family"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist time_whodid2_* {
			label variable `rgvar' "Who would have been more likely to do this activity, '2. Cook breakfast' two mon"
			note `rgvar': "Who would have been more likely to do this activity, '2. Cook breakfast' two months ago?"
			label define `rgvar' 1 "1. Myself" 2 "2. Wife" 3 "3. Someone else in the family"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist time_whodid4_* {
			label variable `rgvar' "Who would have been more likely to do this activity, '4. Help get kids ready for"
			note `rgvar': "Who would have been more likely to do this activity, '4. Help get kids ready for school' two months ago?"
			label define `rgvar' 1 "1. Myself" 2 "2. Wife" 3 "3. Someone else in the family"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist time_whodid5_* {
			label variable `rgvar' "Who would have been more likely to do this activity, '5. Drop kids at school' tw"
			note `rgvar': "Who would have been more likely to do this activity, '5. Drop kids at school' two months ago?"
			label define `rgvar' 1 "1. Myself" 2 "2. Wife" 3 "3. Someone else in the family"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist time_whodid8_* {
			label variable `rgvar' "Who would have been more likely to do this activity, '8. Go to the store/shop' t"
			note `rgvar': "Who would have been more likely to do this activity, '8. Go to the store/shop' two months ago?"
			label define `rgvar' 1 "1. Myself" 2 "2. Wife" 3 "3. Someone else in the family"
			label values `rgvar' `rgvar'
		}
	}




	* append old, previously-imported data (if any)
	cap confirm file "`dtafile'"
	if _rc == 0 {
		* mark all new data before merging with old data
		gen new_data_row=1
		
		* pull in old data
		append using "`dtafile'"
		
		* drop duplicates in favor of old, previously-imported data if overwrite_old_data is 0
		* (alternatively drop in favor of new data if overwrite_old_data is 1)
		sort key
		by key: gen num_for_key = _N
		drop if num_for_key > 1 & ((`overwrite_old_data' == 0 & new_data_row == 1) | (`overwrite_old_data' == 1 & new_data_row ~= 1))
		drop num_for_key

		* drop new-data flag
		drop new_data_row
	}
	
	* save data to Stata format
	save "`dtafile'", replace

	* show codebook and notes
	codebook
	notes list
}

disp
disp "Finished import of: `csvfile'"
disp



****************
**# Convert V2
****************



* OPTIONAL: LOCALLY-APPLIED STATA CORRECTIONS
*
* Rather than using SurveyCTO's review and correction workflow, the code below can apply a list of corrections
* listed in a local .csv file. Feel free to use, ignore, or delete this code.
*
*   Corrections file path and filename:  $datadir/08. Others/02. Output/Time Use/lss_time_use_module_v1_corrections.csv
*
*   Corrections file columns (in order): key, fieldname, value, notes

capture confirm file "`corrfile'"
if _rc==0 {
	disp
	disp "Starting application of corrections in: `corrfile'"
	disp

	* save primary data in memory
	preserve

	* load corrections
	insheet using "`corrfile'", names clear
	
	if _N>0 {
		* number all rows (with +1 offset so that it matches row numbers in Excel)
		gen rownum=_n+1
		
		* drop notes field (for information only)
		drop notes
		
		* make sure that all values are in string format to start
		gen origvalue=value
		tostring value, format(%100.0g) replace
		cap replace value="" if origvalue==.
		drop origvalue
		replace value=trim(value)
		
		* correct field names to match Stata field names (lowercase, drop -'s and .'s)
		replace fieldname=lower(subinstr(subinstr(fieldname,"-","",.),".","",.))
		
		* format date and date/time fields (taking account of possible wildcards for repeat groups)
		forvalues i = 1/100 {
			if "`datetime_fields`i''" ~= "" {
				foreach dtvar in `datetime_fields`i'' {
					* skip fields that aren't yet in the data
					cap unab dtvarignore : `dtvar'
					if _rc==0 {
						gen origvalue=value
						replace value=string(clock(value,"MDYhms",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
						* allow for cases where seconds haven't been specified
						replace value=string(clock(origvalue,"MDYhm",2025),"%25.0g") if strmatch(fieldname,"`dtvar'") & value=="." & origvalue~="."
						drop origvalue
					}
				}
			}
			if "`date_fields`i''" ~= "" {
				foreach dtvar in `date_fields`i'' {
					* skip fields that aren't yet in the data
					cap unab dtvarignore : `dtvar'
					if _rc==0 {
						replace value=string(clock(value,"MDY",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
					}
				}
			}
		}

		* write out a temp file with the commands necessary to apply each correction
		tempfile tempdo
		file open dofile using "`tempdo'", write replace
		local N = _N
		forvalues i = 1/`N' {
			local fieldnameval=fieldname[`i']
			local valueval=value[`i']
			local keyval=key[`i']
			local rownumval=rownum[`i']
			file write dofile `"cap replace `fieldnameval'="`valueval'" if key=="`keyval'""' _n
			file write dofile `"if _rc ~= 0 {"' _n
			if "`valueval'" == "" {
				file write dofile _tab `"cap replace `fieldnameval'=. if key=="`keyval'""' _n
			}
			else {
				file write dofile _tab `"cap replace `fieldnameval'=`valueval' if key=="`keyval'""' _n
			}
			file write dofile _tab `"if _rc ~= 0 {"' _n
			file write dofile _tab _tab `"disp"' _n
			file write dofile _tab _tab `"disp "CAN'T APPLY CORRECTION IN ROW #`rownumval'""' _n
			file write dofile _tab _tab `"disp"' _n
			file write dofile _tab `"}"' _n
			file write dofile `"}"' _n
		}
		file close dofile
	
		* restore primary data
		restore
		
		* execute the .do file to actually apply all corrections
		do "`tempdo'"

		* re-save data
		save "`dtafile'", replace
	}
	else {
		* restore primary data		
		restore
	}

	disp
	disp "Finished applying corrections in: `corrfile'"
	disp
}












