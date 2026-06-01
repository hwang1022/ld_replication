clear all
set more off
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_feasibility.log", replace text

use "$temp/05_phase1_phase2_makepanel.dta", clear

di "==== is there a whenfound_v2 anywhere? (check phase2 cleaned) ===="
preserve
use "$temp/03_phase2_completed_cleaned.dta", clear
cap ds *whenfound*
restore

di "==== whenfound by attend status ===="
tab whenfound attend, missing

di "==== whenfound by phase ===="
tab whenfound phase, missing col

di "==== multiday_job by phase ===="
tab multiday_job phase, missing col

*** Build a simple stand/outside from whenfound and from howfound, compare on NON-multiday work days
gen src_when = .
replace src_when = 1 if whenfound==2          // stand
replace src_when = 0 if inlist(whenfound,1,3) // outside

di "==== src_when on non-multiday work days (attend==1) ===="
tab whenfound src_when if multiday_job==0 & work==1 & attend==1, missing

*** How many work days are multiday & need attribution, by phase
di "==== work-day counts needing attribution ===="
gen needs_attr = (multiday_job==1 & work==1)
tab needs_attr phase, col

*** Eyeball multiday runs: show pattern for a handful of pids with many multiday days
sort pid date
by pid: egen nmulti = total(multiday_job==1 & work==1)
gsort -nmulti pid date
di "==== top pids by # multiday workdays ===="
preserve
    bys pid: keep if _n==1
    gsort -nmulti
    list pid nmulti in 1/15, clean
restore

*** Print day-by-day for the single pid with most multiday days
sum nmulti, meanonly
levelsof pid if nmulti==r(max), local(toppid)
local tp : word 1 of `toppid'
di "==== day-by-day for pid `tp' (phase, date, attend, work, multiday, whenfound, howfound) ===="
list date phase attend work multiday_job whenfound howfound howfound_notattend if pid==`tp', clean noobs

log close
