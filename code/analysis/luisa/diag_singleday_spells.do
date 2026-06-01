*****************************************************************
*  diag_singleday_spells.do
*  (1) How much does job_at_stand ATTRIBUTION lean on single-day
*      multiday spells, and do their anchors have a clean source?
*  (2) ALT spell def B: non-work day (Sunday/holiday/off) SPLITS
*      a spell. Compare #spells & single-day share vs current A.
*  (3) Is COMPREHENSIVE recall (grid==0 / multiday_job missing on
*      neighbors) the main driver of single-day spells?
*****************************************************************
clear all
set more off
set linesize 160
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_singleday_spells.log", replace text

use "$temp/05_phase1_phase2_makepanel.dta", clear
sort pid date
isid pid date
gen byte grid = !mi(daily_recall_lag)

*---- clean_stand (copy of CORE BLOCK step 1) ----
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

*================================================================*
* DEFINITION A (CURRENT): spells over WORK days (skip non-work)
*   + anchor = clean source of immediately preceding WORK day
*================================================================*
preserve
    keep if work==1
    sort pid date
    by pid: gen byte lag_mw     = mwflag[_n-1]
    by pid: gen byte lead_mw    = mwflag[_n+1]
    by pid: gen long spellstart = (mwflag==1 & (lag_mw!=1 | mi(lag_mw)))
    by pid: gen long spell_id   = sum(spellstart) if mwflag==1
    bys pid spell_id (date): gen long lenA = _N if !mi(spell_id)
    * anchor: prior WORK day's clean source
    sort pid date
    by pid: gen byte prevwork_clean = clean_stand[_n-1]
    * neighbor provenance for single-day diagnosis
    by pid: gen byte prevwork_grid = grid[_n-1]
    by pid: gen      prevwork_mdj  = multiday_job[_n-1]
    by pid: gen byte nextwork_grid = grid[_n+1]
    by pid: gen      nextwork_mdj  = multiday_job[_n+1]
    by pid: gen long calgap_prev   = date - date[_n-1]
    by pid: gen long calgap_next   = date[_n+1] - date
    keep pid date spell_id spellstart lenA prevwork_clean ///
         prevwork_grid prevwork_mdj nextwork_grid nextwork_mdj calgap_prev calgap_next
    tempfile A
    save `A'
restore
merge 1:1 pid date using `A', nogen

*---- rebuild job_at_stand exactly as packaged (anchor at spell level) ----
preserve
    keep if spellstart==1
    keep pid spell_id prevwork_clean
    rename prevwork_clean anchor_clean
    tempfile anc
    save `anc'
restore
merge m:1 pid spell_id using `anc', nogen keep(1 3)
gen byte job_at_stand = clean_stand
replace  job_at_stand = anchor_clean if multiday_work==1 & !mi(anchor_clean)
replace  job_at_stand = . if grid==0
gen byte method = .
replace method = 1 if !mi(job_at_stand) & multiday_work==0
replace method = 2 if !mi(job_at_stand) & multiday_work==1

*================================================================*
* (1) ATTRIBUTION dependence on single-day spells
*================================================================*
di "==== (1a) Attributed (method==2) multiday days by spell length ===="
gen byte len1 = (lenA==1) if !mi(lenA)
tab len1 if method==2, missing
di "  attributed days total:"
count if method==2
di "  attributed days from SINGLE-day spells:"
count if method==2 & lenA==1

di "==== (1b) SPELL-LEVEL: does the spell's anchor have a clean source? ===="
preserve
    keep if spellstart==1            // one row per spell
    gen byte anchored = !mi(anchor_clean)
    gen byte single   = (lenA==1)
    di "  total spells:"
    count
    di "  single-day spells:"
    count if single==1
    di "  --- attribution feasibility (anchor clean present) by spell length ---"
    tab single anchored, row missing
    di "  among SINGLE-day spells: anchored vs not"
    tab anchored if single==1, missing
    di "  among MULTI-day spells: anchored vs not"
    tab anchored if single==0, missing
restore

*================================================================*
* (3) Is COMPREHENSIVE recall the driver of single-day spells?
*     Look at the WORK-day neighbors that bound each single-day spell.
*================================================================*
di "==== (3) SINGLE-day spell days: what bounds them? ===="
gen byte singleA = (multiday_work==1 & lenA==1)
count if singleA==1
di "  prior WORK day separated by a NON-WORK gap (calgap_prev>1):"
count if singleA==1 & calgap_prev>1 & !mi(calgap_prev)
di "  next  WORK day separated by a NON-WORK gap (calgap_next>1):"
count if singleA==1 & calgap_next>1 & !mi(calgap_next)
di "  prior WORK day is COMPREHENSIVE (grid==0):"
count if singleA==1 & prevwork_grid==0
di "  prior WORK day has multiday_job MISSING (unknown -> broke run):"
count if singleA==1 & mi(prevwork_mdj) & !mi(prevwork_grid)
di "  next  WORK day has multiday_job MISSING:"
count if singleA==1 & mi(nextwork_mdj) & !mi(nextwork_grid)
di "  single-day spell is itself a COMPREHENSIVE day (grid==0):"
count if singleA==1 & grid==0
di "  single-day spell is on the GRID:"
count if singleA==1 & grid==1
di "==== (3b) phase split of single-day spells ===="
tab phase if singleA==1, missing

*================================================================*
* (2) DEFINITION B: non-work day SPLITS the spell (calendar runs)
*================================================================*
sort pid date
by pid: gen byte lagB        = multiday_work[_n-1]
by pid: gen long spellstartB = (multiday_work==1 & (lagB!=1 | mi(lagB)))
by pid: gen long spell_idB   = sum(spellstartB) if multiday_work==1
bys pid spell_idB (date): gen long lenB = _N if !mi(spell_idB)

di "==== (2) SPELL COUNTS: A (skip non-work) vs B (split on non-work) ===="
preserve
    keep if spellstartB==1
    di "  Definition B: number of spells:"
    count
    di "  Definition B: single-day spells:"
    count if lenB==1
    di "  Definition B: length distribution (<=10):"
    tab lenB if lenB<=10
    sum lenB, detail
restore
di "  (Definition A had 973 spells, 406 single-day, per audit C8)"

di "==== (2b) How many A-spells get SPLIT by a non-work day? ===="
preserve
    keep if multiday_work==1
    * count distinct B-spells within each A-spell
    bys pid spell_id spell_idB: gen byte firstBinA = (_n==1)
    bys pid spell_id: egen long nB = total(firstBinA)
    bys pid spell_id (date): keep if _n==1
    di "  A-spells split into >1 B-spell (i.e., span a non-work day):"
    count if nB>1
    di "  total A-spells:"
    count
    tab nB if nB<=8
restore

log close
