/*
	Generate shock tables using pre-made data. Follows old table closely.
	Most of the logic is contained in code that produces the tables
*/

**********************
**# Setup
**********************

* INFO: Intended to run after 0.master.do (defines estout dependencies).
* For standalone use, set these globals manually.

global db_dir "~/Dropbox"
global ld_dir                 "$db_dir/Labor Discipline"
global replication_dir        "$ld_dir/07. Data/3. Main Study 3.0/replication"

// WARNING: This corresponds to Simon's local setup. Comment out / delete line below when running elsewhere.
global replication_dir "/Users/st2246/Work/labor/new_asks/replication"
global shock_temp "/Users/st2246/Work/labor/new_asks/replication/code/analysis/simon/shock_data"

global code                   "$replication_dir/code"
global raw                    "$replication_dir/data/raw"
global temp                   "$replication_dir/data/temp"
global final                  "$replication_dir/data/final"
global external               "$replication_dir/data/external"

* Hao working folder data path (requested in PLAN.md)
global datadir "/Users/st2246/Work/labor/3. Main Study 3.0/hao_working_folder/02. Cleaning Data"
global main_data "$datadir/Analysis Prep/02. Output/03_bs_phase123_makevar_daily_weekly_full.dta"

global output "$replication_dir/output/prioritize_date"
global tables "$output/tables"

**********************
**# Code for generating table using premade shock data
**********************


**## Columns 1 and 2: Same Spec as in Shocks Analysis

use "$temp/shock_new_spec.dta", clear
//use "$temp/shocks_dataset_ready_originaldata.dta", clear

// Use the wildbootstrap command? If 1 then use; also modify table file name to make it clear
// I recommend 0 since differences are small and wildbootstrap makes code take 10x longer. Switch to 1 after spec is finalized.
local wildbootstrap 0

eststo clear

* Column 1
eststo: reg attend_nadj treat treatXweek_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2, vce(cluster pid)
estadd local weekin  "Yes", replace
estadd local calweek "Yes", replace
matrix pval = J(1,2,.)
matrix colnames pval = treat treatXweek_in_dm
matrix pval[1,1] = r(table)[4,1]
matrix pval[1,2] = r(table)[4,2]
estadd matrix pval


* Column 2
eststo: reg attend_nadj treat treatXpostweek5 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2, vce(cluster pid)
estadd local weekin  "Yes", replace
estadd local calweek "Yes", replace

matrix pval = J(1,2,.)
matrix colnames pval = treat treatXpostweek5
matrix pval[1,1] = r(table)[4,1]
matrix pval[1,2] = r(table)[4,2]
estadd matrix pval


* Column 3
if `wildbootstrap' == 1 {
	wildbootstrap regress attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, cluster(standid)
}
else {
reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn  bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
}

boottest {treat} {treatXpost_attendloo_b25}
matrix pval = J(1,2,.)
matrix colnames pval = treat treatXpost_attendloo_b25
matrix pval[1,1] = r(p_1)
matrix pval[1,2] = r(p_2)

eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
estadd local calweek "Yes", replace
estadd local weekin  "Yes", replace
estadd matrix pval


* Column 4 - time trend
if `wildbootstrap' == 1 {
	wildbootstrap regress attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, cluster(standid)
}
else {
	reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
}

boottest {treat} {treatXpost_attendloo_b25} {treatXweek_in_dm}
matrix pval = J(1,3,.)
matrix colnames pval = treat treatXpost_attendloo_b25 treatXweek_in_dm
matrix pval[1,1] = r(p_1)
matrix pval[1,2] = r(p_2)
matrix pval[1,3] = r(p_3)

eststo: reg attend_nadj treat treatXpost_attendloo_b25 post_attendloo_b25 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
estadd local calweek "Yes", replace
estadd local weekin  "Yes", replace
estadd matrix pval

* Column 5

if `wildbootstrap' == 1 {
	wildbootstrap regress attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, cluster(standid)
}
else {
	reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
}

boottest {treat} {treatXattendloo25_post1} {treatXattendloo25_post2p}
matrix pval = J(1,3,.)
matrix colnames pval = treat treatXattendloo25_post1 treatXattendloo25_post2p
matrix pval[1,1] = r(p_1)
matrix pval[1,2] = r(p_2)
matrix pval[1,3] = r(p_3)


eststo: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
estadd local calweek "Yes", replace
estadd local weekin  "Yes", replace
estadd matrix pval


* Column 6

if `wildbootstrap' == 1 {
	wildbootstrap regress attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, cluster(standid)
} 
else  {
	reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster standid)
}
boottest {treat} {treatXattendloo25_post1} {treatXattendloo25_post2p} {treatXweek_in_dm}
matrix pval = J(1,4,.)
matrix colnames pval = treat treatXattendloo25_post1 treatXattendloo25_post2p treatXweek_in_dm
matrix pval[1,1] = r(p_1)
matrix pval[1,2] = r(p_2)
matrix pval[1,3] = r(p_3)
matrix pval[1,4] = r(p_4)

eststo: reg attend_nadj treat treatXattendloo25_post1 treatXattendloo25_post2p attendloo25_post1 attendloo25_post2p treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==2 & firstwk_attendloo_b25==0, vce(cluster pid)
estadd local calweek "Yes", replace
estadd local weekin  "Yes", replace
estadd matrix pval


label var treat "Treat"
label var treatXpostweek5 "Treat $\times$ Second month of phase 2"
label var treatXpost_attendloo_b25 "Treat $\times$ Post shock"
label var post_attendloo_b25 "Post shock"
label var treatXattendloo25_post1 "Treat $\times$ 1 week post shock"
label var treatXattendloo25_post2p "Treat $\times$ 2+ weeks post shock"
label var treatXweek_in_dm "Treat $\times$ Week in phase 2"



if `wildbootstrap' == 1 {
	local filename "$tables/shocks_attendb25_newspec_wild.tex"
}
else {
	local filename "$tables/shocks_attendb25_newspec_nowild.tex"
}


esttab using "`filename'", se ///
    keep( treat treatXweek_in_dm treatXpostweek5 treatXpost_attendloo_b25 treatXattendloo25_post1 ///
          treatXattendloo25_post2p treatXweek_in_dm) ///
    order( treat treatXpost_attendloo_b25 treatXattendloo25_post1 ///
           treatXattendloo25_post2p treatXpostweek5 treatXweek_in_dm ) ///
    nostar l cells(b(fmt(a3)) se(fmt(3) par) pval(fmt(3) par("[" "]") pvalue(pval))) nonotes ///
    starlevels(* 0.10 ** 0.05 *** .01) ///
    stats(weekin calweek N, labels("Week in phase FE" "Calendar Week FE" "N: worker-weeks")) ///
    replace collabels(none) gaps nomtitles

eststo clear
