*****************************************************************
*  diag_reliable_cut.do
*  How do multiday_job and job_at_stand look if we use ONLY
*  recall_reliable==1 (in-person) data?
*  Two builds:
*   (I)  FULL-panel build (current), then DESCRIBE on reliable==1
*   (II) STRICT: keep only reliable==1 rows, rebuild from scratch
*****************************************************************
clear all
set more off
set linesize 160
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_reliable_cut.log", replace text

*--- program: build job_at_stand CORE BLOCK on whatever is in memory ---
capture program drop buildjas
program define buildjas
    gen byte grid = !mi(daily_recall_lag)
    gen byte clean_stand = .
    replace clean_stand = 1 if whenfound==2
    replace clean_stand = 0 if inlist(whenfound,1,3)
    replace clean_stand = 0 if mi(clean_stand) & !mi(howfound_notattend) & howfound_notattend!=5
    replace clean_stand = 1 if mi(clean_stand) & inlist(howfound,6,7,8,9,10,11)
    replace clean_stand = 0 if mi(clean_stand) & inlist(howfound,1,2,3,4,998)
    gen byte has_clean = (work==1 & multiday_job==0 & !mi(clean_stand))
    replace clean_stand = . if !has_clean
    gen byte multiday_work = (work==1 & multiday_job==1)
    gen byte mwflag = multiday_work if work==1
    preserve
        keep if work==1
        sort pid date
        by pid: gen byte lag_mw = mwflag[_n-1]
        by pid: gen long spellstart = (mwflag==1 & (lag_mw!=1 | mi(lag_mw)))
        by pid: gen long spell_id = sum(spellstart) if mwflag==1
        by pid: gen byte prevwork_clean = clean_stand[_n-1]
        keep pid date spell_id spellstart prevwork_clean
        tempfile sp
        save `sp'
    restore
    merge 1:1 pid date using `sp', nogen
    preserve
        keep if spellstart==1
        keep pid spell_id prevwork_clean
        rename prevwork_clean anchor_clean
        tempfile an
        save `an'
    restore
    merge m:1 pid spell_id using `an', nogen keep(1 3)
    gen byte job_at_stand = clean_stand
    replace  job_at_stand = anchor_clean if multiday_work==1 & !mi(anchor_clean)
    replace  job_at_stand = . if grid==0
end

*================================================================*
* 0. recall_reliable landscape
*================================================================*
use "$temp/05_phase1_phase2_makepanel.dta", clear
sort pid date
gen byte grid0 = !mi(daily_recall_lag)
di "==== recall_reliable distribution (all 24,381 rows) ===="
tab recall_reliable, missing
di "==== recall_reliable x grid (daily-grid day?) ===="
tab recall_reliable grid0, missing
di "==== recall_reliable among WORK days ===="
tab recall_reliable if work==1, missing
di "==== recall_reliable x phase (work days) ===="
tab recall_reliable phase if work==1, missing

*================================================================*
* (I) FULL build, then describe on reliable==1
*================================================================*
use "$temp/05_phase1_phase2_makepanel.dta", clear
sort pid date
buildjas
di "==== (I) multiday_job rate among WORK days: FULL vs reliable==1 ===="
di "  FULL:"
tab multiday_job if work==1, missing
di "  reliable==1 only:"
tab multiday_job if work==1 & recall_reliable==1, missing
di "==== (I) job_at_stand among WORK days: FULL ===="
tab job_at_stand if work==1, missing
di "==== (I) job_at_stand among WORK days: reliable==1 subset ===="
tab job_at_stand if work==1 & recall_reliable==1, missing
di "==== (I) job_at_stand among WORK days: reliable==0 (phone) subset ===="
tab job_at_stand if work==1 & recall_reliable==0, missing

*================================================================*
* (II) STRICT: keep only reliable==1 rows, rebuild from scratch
*================================================================*
use "$temp/05_phase1_phase2_makepanel.dta", clear
keep if recall_reliable==1
sort pid date
di "==== (II) STRICT subset size ===="
count
di "  work days in subset:"
count if work==1
buildjas
di "==== (II) STRICT: multiday_job rate among work days ===="
tab multiday_job if work==1, missing
di "==== (II) STRICT: job_at_stand among work days ===="
tab job_at_stand if work==1, missing
di "==== (II) STRICT: spells rebuilt from reliable-only (length dist) ===="
preserve
    keep if spellstart==1
    count
    bys pid (spell_id): gen x=1
restore
di "==== (II) STRICT: how fragmented? mean calendar gap between consecutive kept work days ===="
preserve
    keep if work==1
    sort pid date
    by pid: gen long cg = date - date[_n-1]
    tab cg if cg<=10
restore

log close
