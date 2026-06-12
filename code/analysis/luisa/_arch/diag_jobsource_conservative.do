*************************************************
*  diag: CONSERVATIVE job-at-stand build
*  - clean source on non-multiday work days
*  - multiday spells = consecutive run of multiday
*    work days (work==1), non-work days skipped
*  - anchor = clean source on the WORK DAY
*    immediately preceding the spell (1 work-day lookback)
*  Reports: % of total work days left UNLABELED,
*  overall and within the 7-day daily-recall-grid subset
*  Author: Claude (diagnostic / prototype only)
*************************************************

clear all
set more off
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_jobsource_conservative.log", replace text

use "$temp/05_phase1_phase2_makepanel.dta", clear
keep pid date phase attend work multiday_job whenfound howfound howfound_notattend daily_recall_lag recall_source mode
sort pid date
isid pid date

*--- recall-grid indicator: day was filled by the 7-day daily grid (lag 1-7) ---
gen byte grid = !mi(daily_recall_lag)

di "==== work-day universe ===="
count if work==1
gen byte workday = (work==1)
di "==== multiday_job status among work days (note any missing) ===="
tab multiday_job grid if workday==1, missing

*===============================================================*
* 1. CLEAN SOURCE on non-multiday work days  (stand=1 / not=0)
*===============================================================*
local howfound_stand 6,7,8,9,10,11
gen byte clean_stand = .
replace clean_stand = 1 if whenfound==2
replace clean_stand = 0 if inlist(whenfound,1,3)
replace clean_stand = 0 if mi(clean_stand) & !mi(howfound_notattend) & howfound_notattend!=5
replace clean_stand = 1 if mi(clean_stand) & inlist(howfound,`howfound_stand')
replace clean_stand = 0 if mi(clean_stand) & inlist(howfound,1,2,3,4,998)

gen byte has_clean = (work==1 & multiday_job==0 & !mi(clean_stand))
replace clean_stand = . if has_clean==0

*===============================================================*
* 2. MULTIDAY SPELLS (consecutive multiday work days)
*===============================================================*
gen byte multiday_work = (work==1 & multiday_job==1)
gen byte mwflag = multiday_work if work==1
preserve
    keep if work==1
    sort pid date
    by pid: gen byte lag_mw     = mwflag[_n-1]
    by pid: gen byte lag_clean  = .          // will fill below
    by pid: gen long spellstart = (mwflag==1 & (lag_mw!=1 | mi(lag_mw)))
    by pid: gen long spell_id   = sum(spellstart) if mwflag==1
    keep pid date spell_id spellstart
    tempfile spells
    save `spells'
restore
merge 1:1 pid date using `spells', nogen

*===============================================================*
* 3. CONSERVATIVE ANCHOR = clean source of the immediately
*    preceding WORK DAY (1 work-day lookback)
*===============================================================*
preserve
    keep if work==1
    sort pid date
    by pid: gen byte prevwork_clean = clean_stand[_n-1]   // prior work day's clean source
    keep if spellstart==1
    keep pid spell_id prevwork_clean
    tempfile anc
    save `anc'
restore
merge m:1 pid spell_id using `anc', nogen keep(1 3)

gen byte job_at_stand = clean_stand                          // direct on non-multiday clean days
replace job_at_stand = prevwork_clean if multiday_work==1 & !mi(prevwork_clean)

*===============================================================*
* 4. COVERAGE / UNLABELED among ALL work days
*===============================================================*
di "==== OVERALL: labeled vs unlabeled among all work days ===="
gen byte labeled = (work==1 & !mi(job_at_stand))
count if work==1
local totwork = r(N)
count if labeled==1
local lab = r(N)
di "  total work days = `totwork'; labeled = `lab' (" %4.1f 100*`lab'/`totwork' "%); UNLABELED = " `totwork'-`lab' " (" %4.1f 100*(`totwork'-`lab')/`totwork' "%)"

di "==== breakdown of UNLABELED work days by type ===="
gen str20 unlab_reason = ""
replace unlab_reason = "multiday-noorigin" if work==1 & mi(job_at_stand) & multiday_job==1
replace unlab_reason = "nonmulti-nosource" if work==1 & mi(job_at_stand) & multiday_job==0
replace unlab_reason = "multiday_job missing" if work==1 & mi(job_at_stand) & mi(multiday_job)
tab unlab_reason if work==1 & labeled==0, missing

di "==== job_at_stand distribution (all work days) ===="
tab job_at_stand if work==1, missing

*===============================================================*
* 5. SAME but restricted to 7-DAY DAILY RECALL GRID days
*===============================================================*
di "==== GRID-ONLY: labeled vs unlabeled among work days filled by 7-day grid ===="
count if work==1 & grid==1
local gw = r(N)
count if work==1 & grid==1 & labeled==1
local gl = r(N)
di "  grid work days = `gw'; labeled = `gl' (" %4.1f 100*`gl'/`gw' "%); UNLABELED = " `gw'-`gl' " (" %4.1f 100*(`gw'-`gl')/`gw' "%)"
tab unlab_reason if work==1 & grid==1 & labeled==0, missing
di "==== how many NON-grid work days exist (comprehensive recall etc.) ===="
count if work==1 & grid==0
tab multiday_job if work==1 & grid==0, missing

log close
