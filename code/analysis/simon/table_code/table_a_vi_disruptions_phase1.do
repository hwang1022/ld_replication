*****************************************
** Appendix Table A.6: Disruptions During Phase 1
*****************************************

clear all
set more off

global data "`c(pwd)'/data"

local outdir "$data/output/tables"
local shock_threshold = 25
local shocks_25_phase1 "$data/temp/shocks_dataset_`shock_threshold'_phase1.dta"
local verified_tex "`outdir'/shocks_attend_j25_bootstrap_phase1.tex"
local appendix_alias "`outdir'/table_a_vi.tex"
capture mkdir "$data/output"
capture mkdir "`outdir'"

use `shocks_25_phase1', clear

eststo clear

* Column 1
eststo: reg attend_nadj treat treatXweek_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==1, vce(cluster pid)
estadd local weekin  "Yes", replace
estadd local calweek "Yes", replace
matrix pval = J(1,2,.)
matrix colnames pval = treat treatXweek_in_dm
matrix pval[1,1] = r(table)[4,1]
matrix pval[1,2] = r(table)[4,2]
estadd matrix pval

* Column 2
eststo: reg attend_nadj treat treatXpostweek5 attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==1, vce(cluster pid)
estadd local weekin  "Yes", replace
estadd local calweek "Yes", replace
matrix pval = J(1,2,.)
matrix colnames pval = treat treatXpostweek5
matrix pval[1,1] = r(table)[4,1]
matrix pval[1,2] = r(table)[4,2]
estadd matrix pval

* Column 3
reg attend_nadj treat treatXpost_attend_j post_attend_j attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==1 & firstwk_attend_j!=1, vce(cluster standid)
boottest {treat} {treatXpost_attend_j}, seed(123) reps(2048) boottype(wild) nograph
matrix pval = J(1,2,.)
matrix colnames pval = treat treatXpost_attend_j
matrix pval[1,1] = r(p_1)
matrix pval[1,2] = r(p_2)

eststo: reg attend_nadj treat treatXpost_attend_j post_attend_j attend_week bl_attend bl_earn miss_bl_earn bl_modalwage week_in_dm i.standid i.strata i.calendar_week if phase==1 & firstwk_attend_j!=1, vce(cluster pid)
estadd local calweek "Yes", replace
estadd local weekin  "Yes", replace
estadd matrix pval

* Column 4 - time trend
reg attend_nadj treat treatXpost_attend_j post_attend_j attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==1 & firstwk_attend_j!=1, vce(cluster standid)
boottest {treat} {treatXpost_attend_j} {treatXweek_in_dm}, seed(123) reps(2048) boottype(wild) nograph
matrix pval = J(1,3,.)
matrix colnames pval = treat treatXpost_attend_j treatXweek_in_dm
matrix pval[1,1] = r(p_1)
matrix pval[1,2] = r(p_2)
matrix pval[1,3] = r(p_3)

eststo: reg attend_nadj treat treatXpost_attend_j post_attend_j attend_week bl_attend bl_earn miss_bl_earn bl_modalwage treatXweek_in_dm week_in_dm i.standid i.strata i.calendar_week if phase==1 & firstwk_attend_j!=1, vce(cluster pid)
estadd local calweek "Yes", replace
estadd local weekin  "Yes", replace
estadd matrix pval

* Column 5
reg attend_nadj treat treatXattend_j_post1 treatXattend_j_post2p attend_j_post1 attend_j_post2p week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==1 & firstwk_attend_j!=1, vce(cluster standid)
boottest {treat} {treatXattend_j_post1} {treatXattend_j_post2p}, seed(123) reps(2048) boottype(wild) nograph
matrix pval = J(1,3,.)
matrix colnames pval = treat treatXattend_j_post1 treatXattend_j_post2p
matrix pval[1,1] = r(p_1)
matrix pval[1,2] = r(p_2)
matrix pval[1,3] = r(p_3)

eststo: reg attend_nadj treat treatXattend_j_post1 treatXattend_j_post2p attend_j_post1 attend_j_post2p week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==1 & firstwk_attend_j!=1, vce(cluster pid)
estadd local calweek "Yes", replace
estadd local weekin  "Yes", replace
estadd matrix pval

* Column 6
reg attend_nadj treat treatXattend_j_post1 treatXattend_j_post2p attend_j_post1 attend_j_post2p treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==1 & firstwk_attend_j!=1, vce(cluster standid)
boottest {treat} {treatXattend_j_post1} {treatXattend_j_post2p} {treatXweek_in_dm}, seed(123) reps(2048) boottype(wild) nograph
matrix pval = J(1,4,.)
matrix colnames pval = treat treatXattend_j_post1 treatXattend_j_post2p treatXweek_in_dm
matrix pval[1,1] = r(p_1)
matrix pval[1,2] = r(p_2)
matrix pval[1,3] = r(p_3)
matrix pval[1,4] = r(p_4)

eststo: reg attend_nadj treat treatXattend_j_post1 treatXattend_j_post2p attend_j_post1 attend_j_post2p treatXweek_in_dm week_in_dm attend_week bl_attend bl_earn miss_bl_earn bl_modalwage i.standid i.strata i.calendar_week if phase==1 & firstwk_attend_j!=1, vce(cluster pid)
estadd local calweek "Yes", replace
estadd local weekin  "Yes", replace
estadd matrix pval

label var treat "Treat"
label var treatXpostweek5 "Treat $\times$ Second month of phase 1"
label var treatXpost_attend_j "Treat $\times$ Post shock"
label var post_attend_j "Post shock"
label var treatXattend_j_post1 "Treat $\times$ 1 week post shock"
label var treatXattend_j_post2p "Treat $\times$ 2+ weeks post shock"
label var treatXweek_in_dm "Treat $\times$ Week in phase 1"

esttab using "`verified_tex'", se ///
    keep(treat treatXweek_in_dm treatXpostweek5 treatXpost_attend_j treatXattend_j_post1 ///
         treatXattend_j_post2p treatXweek_in_dm) ///
    order(treat treatXpost_attend_j treatXattend_j_post1 ///
          treatXattend_j_post2p treatXpostweek5 treatXweek_in_dm) ///
    nostar l cells(b(fmt(a3)) se(fmt(3) par) pval(fmt(3) par("[" "]") pvalue(pval))) nonotes ///
    starlevels(* 0.10 ** 0.05 *** .01) ///
    stats(weekin calweek N, labels("Week in phase FE" "Calendar Week FE" "N: worker-weeks")) ///
    replace collabels(none) frag gaps nomtitles

copy "`verified_tex'" "`appendix_alias'", replace

eststo clear
