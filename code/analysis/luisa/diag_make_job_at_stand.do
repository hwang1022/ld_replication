*****************************************************************
*  diag_make_job_at_stand.do
*  -------------------------------------------------------------
*  PROTOTYPE for a new outcome: was employment found AT THE STAND
*  (job_at_stand = 1) vs NOT at the stand (= 0)?
*
*  Built on "$temp/05_phase1_phase2_makepanel.dta".
*  The CORE BLOCK below (sections 1-4) is meant to be folded into
*  code/1_5_phase_1_2/5_phase1_2_makevar.do, right AFTER the panel
*  is loaded and BEFORE any row-dropping sample restrictions
*  (the consecutive-day / spell logic needs the full daily panel).
*
*  Design (agreed with LC, 2026-05-29):
*   - Category scheme: STAND (1) vs NOT-STAND (0). "Not-stand"
*     bundles outside/phone, self-employed, and "other".
*   - Source signal: combine whenfound (primary, no version
*     conflict) + howfound_notattend (non-attend days have no
*     stand option -> not-stand) + howfound (rare fallback).
*   - Multiday jobs mask the source. Reconstruct multiday SPELLS
*     as maximal runs of consecutive multiday WORK days, then
*     CONSERVATIVELY attribute each spell the clean source of the
*     work day IMMEDIATELY PRECEDING it (the "job-finding" day).
*   - Restrict attribution to days carrying 7-day daily-grid
*     detail (daily_recall_lag non-missing); comprehensive-recall
*     days have no day-level source and stay missing.
*
*  Coverage (conservative): ~94% of all work days labeled
*  (~96% within the 7-day grid). Remaining unlabeled is mostly
*  multiday jobs whose origin is never observed.
*
*  Author: Claude (prototype / diagnostic only)
*****************************************************************

clear all
set more off
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_make_job_at_stand.log", replace text

use "$temp/05_phase1_phase2_makepanel.dta", clear
sort pid date
isid pid date

*================================================================*
**# CORE BLOCK -- paste into 5_phase1_2_makevar.do
*================================================================*

* 7-day daily-recall-grid indicator (source detail only exists here)
gen byte grid = !mi(daily_recall_lag)

*----------------------------------------------------------------*
* 1. CLEAN SOURCE on NON-multiday work days  (stand=1 / not-stand=0)
*    howfound stand codes: v1 rf4_1 ={6,7,8}; v2 rf4_v2_1 ={8,9,10,11}
*    -> union {6,7,8,9,10,11}. (howfound==5 is ambiguous v1-multiday
*    vs v2-phone-friend, so it is NOT used here.)
*----------------------------------------------------------------*
gen byte clean_stand = .
* primary: whenfound (2 = while at stand; 1/3 = outside). No version conflict.
replace clean_stand = 1 if whenfound==2
replace clean_stand = 0 if inlist(whenfound,1,3)
* non-attend days: howfound_notattend has NO stand option -> not-stand
*   (any non-missing source other than multiday code 5)
replace clean_stand = 0 if mi(clean_stand) & !mi(howfound_notattend) & howfound_notattend!=5
* rare fallback: attend-day channel where whenfound is missing
replace clean_stand = 1 if mi(clean_stand) & inlist(howfound,6,7,8,9,10,11)
replace clean_stand = 0 if mi(clean_stand) & inlist(howfound,1,2,3,4,998)

* "clean source" is only meaningful on NON-multiday WORK days
gen byte has_clean = (work==1 & multiday_job==0 & !mi(clean_stand))
replace clean_stand = . if !has_clean
label var clean_stand "Job found at stand (1/0), directly observed on non-multiday work days"

*----------------------------------------------------------------*
* 2. MULTIDAY SPELLS = maximal run of consecutive multiday WORK days
*    (restrict to work==1, order by date; non-work days are skipped
*    so they do not break a spell; a non-multiday work day starts a
*    new job).
*----------------------------------------------------------------*
gen byte multiday_work = (work==1 & multiday_job==1)
gen byte mwflag = multiday_work if work==1     // defined only on work days
preserve
    keep if work==1
    sort pid date
    by pid: gen byte lag_mw      = mwflag[_n-1]                       // prior work day multiday?
    by pid: gen long spellstart  = (mwflag==1 & (lag_mw!=1 | mi(lag_mw)))
    by pid: gen long spell_id    = sum(spellstart) if mwflag==1
    keep pid date spell_id spellstart
    tempfile spells
    save `spells'
restore
merge 1:1 pid date using `spells', nogen
label var spell_id "Multiday-job spell id (within pid)"

*----------------------------------------------------------------*
* 3. CONSERVATIVE ATTRIBUTION = clean source of the work day
*    IMMEDIATELY PRECEDING the spell (1 work-day lookback).
*----------------------------------------------------------------*
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

*----------------------------------------------------------------*
* 4. FINAL VARIABLE: job_at_stand (1 = found at stand, 0 = not)
*----------------------------------------------------------------*
gen byte job_at_stand = clean_stand                                   // direct on non-multiday days
replace  job_at_stand = prevwork_clean if multiday_work==1 & !mi(prevwork_clean)
* keep to the 7-day grid (comprehensive-recall days have no detail)
replace  job_at_stand = . if grid==0
label define yn_stand 0 "0. Not at stand (outside/phone/self/other)" 1 "1. Found at stand", replace
label values job_at_stand yn_stand
label var   job_at_stand "Employment found at the stand (1) vs not (0); multiday attributed from spell's preceding work day"

* provenance flag, for auditing how each label was assigned
gen byte job_at_stand_method = .
replace  job_at_stand_method = 1 if !mi(job_at_stand) & multiday_work==0          // directly observed
replace  job_at_stand_method = 2 if !mi(job_at_stand) & multiday_work==1          // attributed from prev work day
label define jasm 1 "1. Directly observed (non-multiday)" 2 "2. Attributed from spell's preceding work day", replace
label values job_at_stand_method jasm
label var   job_at_stand_method "How job_at_stand was assigned"

* tidy up helper vars (keep spell_id for auditing; drop the rest)
drop grid clean_stand has_clean multiday_work mwflag spellstart prevwork_clean

*================================================================*
**# END CORE BLOCK
*================================================================*

*----------------------------------------------------------------*
* VALIDATION / COVERAGE (safe to delete when folding in)
*----------------------------------------------------------------*
di "==== job_at_stand among all work days ===="
tab job_at_stand if work==1, missing
di "==== assignment method among labeled work days ===="
tab job_at_stand_method if work==1
di "==== unlabeled work days: how many, and why ===="
count if work==1 & mi(job_at_stand)
gen str24 why = ""
replace why = "multiday-no-origin"   if work==1 & mi(job_at_stand) & multiday_job==1
replace why = "nonmulti-no-source"   if work==1 & mi(job_at_stand) & multiday_job==0
replace why = "multiday_job missing" if work==1 & mi(job_at_stand) & mi(multiday_job)
tab why if work==1 & mi(job_at_stand), missing
di "==== by phase ===="
tab job_at_stand phase if work==1, col missing

* eyeball one heavy multiday worker end-to-end
sort pid date
di "==== day-by-day audit, pid 1769 ===="
list date phase work multiday_job spell_id job_at_stand job_at_stand_method ///
     if pid==1769 & !mi(work), clean noobs

log close
