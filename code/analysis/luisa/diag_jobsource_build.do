*************************************************
*  diag: BUILD job-at-stand source variable
*  - clean source on non-multiday work days
*    (combine whenfound + howfound_notattend + howfound)
*  - multiday spells = consecutive run of multiday
*    work days (work==1), non-work days skipped
*  - anchor = nearest prior clean source within
*    a backward window W (test several W)
*  Output: stand vs NOT-stand (1/0)
*  Author: Claude (diagnostic / prototype only)
*************************************************

clear all
set more off
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_jobsource_build.log", replace text

use "$temp/05_phase1_phase2_makepanel.dta", clear
keep pid date phase attend work multiday_job multiday_job_cond whenfound howfound howfound_notattend
sort pid date
isid pid date

*===============================================================*
* 1. CLEAN SOURCE on non-multiday work days
*    stand (1) vs not-stand (0). Missing if no source info.
*===============================================================*
* stand codes in howfound: v1 stand={6,7,8}; v2 stand={8,9,10,11}; union:
local howfound_stand 6 7 8 9 10 11

gen byte clean_stand = .
* primary: whenfound (attend-survey days), no version conflict
replace clean_stand = 1 if whenfound==2
replace clean_stand = 0 if inlist(whenfound,1,3)
* secondary: non-attend days -> howfound_notattend has NO stand option
*   any non-missing, non-multiday(5), counts as NOT-stand (0)
replace clean_stand = 0 if mi(clean_stand) & !mi(howfound_notattend) & howfound_notattend!=5
* tertiary: howfound channel where whenfound missing (rare)
replace clean_stand = 1 if mi(clean_stand) & inlist(howfound, `=subinstr("`howfound_stand'"," ",",",.)')
replace clean_stand = 0 if mi(clean_stand) & inlist(howfound,1,2,3,4,998)
* NOTE: howfound==5 left missing here (ambiguous: v1 multiday vs v2 phone-friend)

* "clean source" only meaningful on non-multiday WORK days
gen byte has_clean = (work==1 & multiday_job==0 & !mi(clean_stand))
replace clean_stand = . if has_clean==0   // restrict clean_stand to clean-source days

di "==== distribution of clean_stand on clean-source non-multiday work days ===="
tab clean_stand if has_clean==1, missing

di "==== how many non-multiday work days LACK a clean source ===="
count if work==1 & multiday_job==0
count if work==1 & multiday_job==0 & has_clean==0

*===============================================================*
* 2. MULTIDAY SPELLS = maximal consecutive run of multiday
*    work days within pid (restrict to work==1, order by date,
*    non-work days are skipped -> don't break a spell)
*===============================================================*
gen byte multiday_work = (work==1 & multiday_job==1)

* sequence among work days only
gen long wseq = .
bys pid (date): replace wseq = sum(work==1)        // running count of work days
* spell id: new spell when current work day is multiday but previous WORK day was not multiday
gen byte prev_multi = .
bys pid (date): gen long wsofar = sum(work==1)
* build previous-work-day multiday flag
gen byte mwflag = multiday_work if work==1
sort pid date
by pid: gen long _wn = sum(work==1)
* lag of mwflag over work days
tempvar lagmw
gen byte `lagmw' = .
bys pid (date): replace `lagmw' = mwflag[_n-1] if work==1  // NOTE: previous CALENDAR row; fix below

* Proper: collapse to work days to get true previous-work-day flag
preserve
    keep if work==1
    sort pid date
    by pid: gen byte lag_mw = mwflag[_n-1]
    by pid: gen long spellstart = (mwflag==1 & (lag_mw!=1 | mi(lag_mw)))
    by pid: gen long spell_id = sum(spellstart) if mwflag==1
    keep pid date spell_id spellstart lag_mw
    tempfile spells
    save `spells'
restore
merge 1:1 pid date using `spells', nogen

di "==== number of multiday spells & their lengths ===="
preserve
    keep if multiday_work==1
    bys pid spell_id: gen long len = _N
    by pid spell_id: keep if _n==1
    sum len, detail
    tab len if len<=15
restore

*===============================================================*
* 3. ANCHOR: nearest prior clean source within window W
*    (search backward in CALENDAR days from spell start)
*===============================================================*
* date of spell start per spell
gen double spellstart_date = date if spellstart==1
bys pid spell_id (date): egen double sstart = min(spellstart_date) if !mi(spell_id)

foreach W in 1 3 7 14 9999 {
    di "================ WINDOW W=`W' calendar days ================"
    * for each multiday-work day, we want anchor at spell level:
    * find nearest prior clean-source day before sstart within W days
    gen byte anchor_stand_`W' = .

    * candidate clean days: has_clean==1
    * We'll loop over spells via a join trick:
    preserve
        keep if has_clean==1
        keep pid date clean_stand
        rename date cdate
        rename clean_stand csrc
        tempfile clean
        save `clean'
    restore

    * spell-start rows
    preserve
        keep if spellstart==1
        keep pid spell_id sstart
        joinby pid using `clean'
        keep if cdate < sstart & (sstart - cdate) <= `W'
        * nearest prior: max cdate per spell
        bys pid spell_id (cdate): keep if _n==_N
        keep pid spell_id csrc
        rename csrc anchor_val_`W'
        tempfile anc
        save `anc'
    restore
    merge m:1 pid spell_id using `anc', nogen keep(1 3)
    replace anchor_stand_`W' = anchor_val_`W' if multiday_work==1 & !mi(spell_id)
    cap drop anchor_val_`W'

    qui count if multiday_work==1
    local denom = r(N)
    qui count if multiday_work==1 & !mi(anchor_stand_`W')
    local num = r(N)
    di "  multiday work days = `denom'; attributed = `num' (" %4.1f 100*`num'/`denom' "%)"
    tab anchor_stand_`W' if multiday_work==1, missing
}

log close
