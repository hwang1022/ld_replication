*****************************************************************
*  diag_audit_multiday.do  -- FULL AUDIT of multiday_job
*  PART A: phase-2 raw  -> provenance (explicit Q vs fallback) & conflicts
*  PART B: phase-1 raw  -> confirm 100% channel-derived (no explicit Q)
*  PART C: 05 makepanel -> final-variable consistency, cond/diff,
*                          missingness, spell plausibility, by phase
*****************************************************************
clear all
set more off
set linesize 160
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_audit_multiday.log", replace text

*================================================================*
* PART A. PHASE-2 RAW: provenance & conflicts (per recall slot)
*================================================================*
use "$temp/03_phase2_completed_cleaned.dta", clear

local exp_yes 0
local exp_no  0
local conflict_no_chan5 0      // explicit=No but v1 channel=multiday(5)
local fallback_md 0            // explicit missing -> md set by howfound(v1)==5
local v2_contam 0              // explicit missing & v1 missing & v2==5 (phone-friend misflag)
forval i = 1/7 {
    cap confirm variable f_multiday_job_`i'
    if _rc continue
    qui count if f_multiday_job_`i'==1
    local exp_yes = `exp_yes' + r(N)
    qui count if f_multiday_job_`i'==0
    local exp_no  = `exp_no'  + r(N)
    qui count if f_multiday_job_`i'==0 & f_howfound_`i'==5     // worker: not multiday, channel(v1): multiday
    local conflict_no_chan5 = `conflict_no_chan5' + r(N)
    qui count if mi(f_multiday_job_`i') & f_howfound_`i'==5    // fallback contributes a multiday
    local fallback_md = `fallback_md' + r(N)
    qui count if mi(f_multiday_job_`i') & mi(f_howfound_`i') & f_howfound_v2_`i'==5  // misflag risk
    local v2_contam = `v2_contam' + r(N)
}
di "==== PHASE 2 provenance (summed over 7 recall slots) ===="
di "  explicit multiday Q = YES ............... `exp_yes'"
di "  explicit multiday Q = NO ................ `exp_no'"
di "  CONFLICT: explicit=No but howfound(v1)=5  `conflict_no_chan5'"
di "  multiday set by FALLBACK (explicit mi & howfound v1==5) ... `fallback_md'"
di "  v2 phone-friend misflag risk (should be 0) ............... `v2_contam'"

*================================================================*
* PART B. PHASE-1 RAW: no explicit Q -> all channel-derived
*================================================================*
use "$temp/03_phase1_completed_cleaned.dta", clear
cap confirm variable d_multiday_job_1
di "==== PHASE 1: explicit multiday var exists? rc=" _rc " (111 = does NOT exist) ===="
local p1_chan5 0
local p1_chan5_na 0
forval i = 1/7 {
    cap confirm variable d_howfound_`i'
    if _rc continue
    qui count if d_howfound_`i'==5
    local p1_chan5 = `p1_chan5' + r(N)
    cap confirm variable d_howfound_notattend_`i'
    if !_rc {
        qui count if d_howfound_notattend_`i'==5
        local p1_chan5_na = `p1_chan5_na' + r(N)
    }
}
di "==== PHASE 1 multiday is 100% channel-derived ===="
di "  howfound==5 (attend) ....... `p1_chan5'"
di "  howfound_notattend==5 ...... `p1_chan5_na'"

*================================================================*
* PART C. FINAL DAILY PANEL (05): consistency & plausibility
*================================================================*
use "$temp/05_phase1_phase2_makepanel.dta", clear
sort pid date
gen byte grid = !mi(daily_recall_lag)

di "==== C1. multiday_job rate by phase (work days) ===="
tab multiday_job phase if work==1, col missing

di "==== C2. multiday_job x whenfound (1=before/outside, 2=at stand, 3=after) ===="
tab whenfound multiday_job, missing

di "==== C3. multiday_job x howfound (channel) ===="
tab howfound multiday_job, missing
di "==== C4. multiday_job x howfound_notattend ===="
tab howfound_notattend multiday_job, missing

di "==== C5. PLAUSIBILITY: multiday==1 but day's channel is a NON-multiday code ===="
di "   (legit if it's the first/anchor day; flagged for inspection)"
gen byte chan_nonmulti = .
replace chan_nonmulti = 1 if multiday_job==1 & ( inlist(howfound,1,2,3,4,6,7,8,9,10,11) | inlist(howfound_notattend,1,2,3,4) )
count if multiday_job==1
count if chan_nonmulti==1
di "==== of those, how many are self-employed channel (code 4)? ===="
count if multiday_job==1 & (howfound==4 | howfound_notattend==4)

di "==== C6. multiday_job vs multiday_job_cond (the work==0 -> 0 rule) ===="
tab multiday_job multiday_job_cond, missing
di "   rows flagged multiday_cond==1 but multiday_job==0 (i.e., not working):"
count if multiday_job_cond==1 & multiday_job==0

di "==== C7. MISSINGNESS of multiday_job on work days, by grid ===="
tab grid if work==1 & mi(multiday_job), missing
count if work==1 & mi(multiday_job)

di "==== C8. SPELL plausibility: length distribution & single-day multiday spells ===="
gen byte mwflag = (work==1 & multiday_job==1) if work==1
preserve
    keep if work==1
    sort pid date
    by pid: gen byte lag_mw = mwflag[_n-1]
    by pid: gen long spellstart = (mwflag==1 & (lag_mw!=1 | mi(lag_mw)))
    by pid: gen long spell_id   = sum(spellstart) if mwflag==1
    keep if mwflag==1
    bys pid spell_id: gen long len = _N
    by pid spell_id: keep if _n==1
    di "  number of spells:"
    count
    di "  single-day spells (len==1):"
    count if len==1
    tab len if len<=10
    sum len, detail
restore

log close
