*****************************************************************
*  diag_defB_coverage.do
*  Coverage cost of Definition B (non-work day splits spell),
*  under three attribution rules:
*   A   : current (skip non-work; anchor = prior work day clean)
*   B1  : split on non-work; RE-ANCHOR each segment on its own
*         immediately-preceding work day (post-gap segs lose anchor)
*   B2  : split for COUNTING, but PROPAGATE the original job's
*         source across non-work gaps (same job -> same source)
*****************************************************************
clear all
set more off
set linesize 160
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_defB_coverage.log", replace text

use "$temp/05_phase1_phase2_makepanel.dta", clear
sort pid date
gen byte grid = !mi(daily_recall_lag)

* clean_stand (same as build)
gen byte clean_stand = .
replace clean_stand = 1 if whenfound==2
replace clean_stand = 0 if inlist(whenfound,1,3)
replace clean_stand = 0 if mi(clean_stand) & !mi(howfound_notattend) & howfound_notattend!=5
replace clean_stand = 1 if mi(clean_stand) & inlist(howfound,6,7,8,9,10,11)
replace clean_stand = 0 if mi(clean_stand) & inlist(howfound,1,2,3,4,998)
gen byte has_clean = (work==1 & multiday_job==0 & !mi(clean_stand))
replace clean_stand = . if !has_clean

gen byte multiday_work = (work==1 & multiday_job==1)

* ---- A blocks (skip non-work) over WORK days ----
gen byte mwflag = multiday_work if work==1
preserve
    keep if work==1
    sort pid date
    by pid: gen byte lag_mw     = mwflag[_n-1]
    by pid: gen long Astart     = (mwflag==1 & (lag_mw!=1 | mi(lag_mw)))
    by pid: gen long Ablock     = sum(Astart) if mwflag==1
    by pid: gen byte prevwork_clean = clean_stand[_n-1]
    keep pid date Ablock Astart prevwork_clean
    tempfile A
    save `A'
restore
merge 1:1 pid date using `A', nogen

* anchor for each A block (propagated source = B2 and current A)
preserve
    keep if Astart==1
    keep pid Ablock prevwork_clean
    rename prevwork_clean Aanchor
    tempfile aa
    save `aa'
restore
merge m:1 pid Ablock using `aa', nogen keep(1 3)

* ---- B segments (split on non-work) over full calendar ----
sort pid date
by pid: gen byte lagB    = multiday_work[_n-1]
by pid: gen long Bstart  = (multiday_work==1 & (lagB!=1 | mi(lagB)))
by pid: gen long Bseg    = sum(Bstart) if multiday_work==1

* B1 anchor: each B segment's immediately-preceding WORK day clean source
preserve
    keep if work==1
    sort pid date
    by pid: gen byte prevwork_clean2 = clean_stand[_n-1]
    keep pid date prevwork_clean2
    tempfile pw
    save `pw'
restore
merge 1:1 pid date using `pw', nogen
preserve
    keep if Bstart==1
    keep pid Bseg prevwork_clean2
    rename prevwork_clean2 Banchor
    tempfile bb
    save `bb'
restore
merge m:1 pid Bseg using `bb', nogen keep(1 3)

* ---- Build the three job_at_stand variants ----
* A (current)
gen byte jas_A = clean_stand
replace  jas_A = Aanchor if multiday_work==1 & !mi(Aanchor)
replace  jas_A = . if grid==0
* B1 (re-anchor each segment)
gen byte jas_B1 = clean_stand
replace  jas_B1 = Banchor if multiday_work==1 & !mi(Banchor)
replace  jas_B1 = . if grid==0
* B2 (split for counting, propagate original A-block source)
gen byte jas_B2 = clean_stand
replace  jas_B2 = Aanchor if multiday_work==1 & !mi(Aanchor)
replace  jas_B2 = . if grid==0

di "==== COVERAGE among all WORK days (n=11,118) ===="
foreach v in jas_A jas_B1 jas_B2 {
    qui count if work==1 & !mi(`v')
    local lab = r(N)
    qui count if work==1
    local tot = r(N)
    di "  `v': labeled = `lab' / `tot'  (" %5.1f 100*`lab'/`tot' "%)"
}
di "==== COVERAGE among MULTIDAY work days only (n=3,287) ===="
foreach v in jas_A jas_B1 jas_B2 {
    qui count if multiday_work==1 & !mi(`v')
    local lab = r(N)
    qui count if multiday_work==1
    local tot = r(N)
    di "  `v': labeled = `lab' / `tot'  (" %5.1f 100*`lab'/`tot' "%)"
}
di "==== Multiday days LEFT UNLABELED specifically by re-anchoring (in A, lost in B1) ===="
count if multiday_work==1 & !mi(jas_A) & mi(jas_B1)
di "==== Do A and B1/B2 ever DISAGREE on the label (flip rate)? ===="
count if multiday_work==1 & !mi(jas_A) & !mi(jas_B1) & jas_A!=jas_B1
count if multiday_work==1 & !mi(jas_A) & !mi(jas_B2) & jas_A!=jas_B2

log close
