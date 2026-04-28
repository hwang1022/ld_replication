/*
Shocks New Spec: no LOO, control-only residuals

- Residual regression estimated on baseline + phase-1 controls
- Residuals predicted for phase-2 controls only
- Stand-week shock measure uses simple stand-week averages (not leave-one-out)
*/

**********************
**# Setup
**********************

global db_dir "~/Dropbox"
global ld_dir                 "$db_dir/Labor Discipline"
global replication_dir        "$ld_dir/07. Data/3. Main Study 3.0/replication"

// WARNING: This corresponds to Simon's local setup. Comment out / delete line below when running elsewhere.
global replication_dir "/Users/st2246/Work/labor/new_asks/replication"

global code                   "$replication_dir/code"
global raw                    "$replication_dir/data/raw"
global temp                   "$replication_dir/data/temp"
global final                  "$replication_dir/data/final"
global external               "$replication_dir/data/external"

global output "$replication_dir/output/prioritize_date"
global tables "$output/tables"

cap mkdir "$output"
cap mkdir "$tables"


**********************
**# Define Variables
**********************

* Generate baseline covariates inline for standalone use.
cap program drop gen_bl_cov
program define gen_bl_cov
    preserve

        cap drop bl_attend bl_earn miss_bl_earn bl_modalwage

        keep if phase == 0

        egen temp = mean(attend), by(pid)
        egen bl_attend = max(temp), by(pid)
        drop temp

        * earnings
        egen temp = mean(earn), by(pid)
        egen bl_earn = max(temp), by(pid)
        gen miss_bl_earn = (bl_earn==.)
        replace bl_earn = 0 if miss_bl_earn==1
        drop temp

        * Modal Work
        egen temp1 = mode(earn) if earn>0, by(pid)
        egen bl_modalwage = max(temp1), by(pid)
        replace bl_modalwage = 0 if bl_modalwage==.
        drop temp1

        keep pid bl_attend bl_earn miss_bl_earn bl_modalwage
        duplicates drop pid, force

        tempfile bl_cov
        save `bl_cov', replace

    restore

    merge m:1 pid using `bl_cov', update replace keep(1 2 3 4 5) nogen

end


*****************************************
**# Shock data creation
*****************************************

// WARNING: switch to "use "$main_data" , clear"; below is for Simon's local setup.
use "$temp/03_bs_phase123_makevar_daily_weekly_full.dta", clear
gen_bl_cov

gen treat = treatment
egen standid = group(stand)

* create calweek counter for each standXphase
sort standid phase calendar_week date pid
by standid phase calendar_week: gen stand_ph_calweek_id1 = 1 if _n==1
egen temp2 = seq() if stand_ph_calweek_id1 == 1, by(standid phase)
egen stand_ph_calweek = max(temp2), by(standid phase calendar_week)
gen treatXstand_ph_calweek = treat*stand_ph_calweek
drop temp*

egen temp1 = mean(week_in) if dow==1, by(pid phase)
egen temp2 = max(temp1), by(pid phase)
gen week_in_dm = week_in - temp2
drop temp*
gen treatXweek_in_dm = treat*week_in_dm

gen treatXweek_in = treat*week_in
gen treatXpostweek5 = treat*(week_in>=5)

* New residual regression: baseline + phase-1 controls only
reg attend i.standid i.phase i.calendar_week  if phase==0 | (phase==1 & treat==0)
predict resid_day_attendph2temp if phase==2 & treat==0, residuals


* Mean of control-group phase-2 residuals per stand-week
egen avg_wkattend_ctrl = mean(resid_day_attendph2temp) if phase==2, by(standid calendar_week)
* Broadcast to all workers in same stand-week
egen avg_wkattend = max(avg_wkattend_ctrl), by(standid calendar_week)


* Indicator for Shock
* calculate percentile on control residuals to avoid weighting by number of treated people in a stand
_pctile avg_wkattend_ctrl if dow==2, p(25)
scalar pct_j_attend = r(r1)
gen wkof_attend_j = (avg_wkattend < pct_j_attend) if avg_wkattend!=.


//// Time since shock variable
* First calendar week of shock
gen calwk_of_shock = stand_ph_calweek if wkof_attend_j==1
bys pid : egen firstofshock_calwk_j = min(calwk_of_shock)
drop calwk_of_shock

* Weeks since shock
gen wks_since_shock_j = stand_ph_calweek - firstofshock_calwk_j
* Dummy for first week in which shock happens (contemporaneous shock)
gen firstwk_attendloo_b25 = wks_since_shock_j == 0

////// Post shock variables and interaction
* Post shock variable and interaction
gen post_attendloo_b25 = (wks_since_shock_j > 0) & (!mi(wks_since_shock_j))
gen treatXpost_attendloo_b25 = treatment * post_attendloo_b25 

* One week post shock and interaction
gen attendloo25_post1 = wks_since_shock_j == 1
gen treatXattendloo25_post1 = treatment * attendloo25_post1 

* Two+ weeks post shock and interaction
gen attendloo25_post2p = (wks_since_shock_j>=2) & (!mi(wks_since_shock_j))
gen treatXattendloo25_post2p = treatment*attendloo25_post2p 

// NOTE: saving this data so I can separte table code and regression code
save "$temp/shock_new_spec.dta", replace
