*****************************************************************
*  diag_howfound_harmonize.do
*  -------------------------------------------------------------
*  PROTOTYPE FIX for the v1/v2 howfound coding collision.
*
*  PROBLEM (verified, diag_codes_reliable.do):
*   The combined `howfound` is filled from v1 (rf4_1) when present,
*   else from v2 (rf4_v2_1) -- but 3_combine line 179 pours RAW v2
*   codes into the v1-coded variable with NO remap. The two schemes
*   number answers differently, so combined codes 5/6/7 are
*   ambiguous and 6/7 even cross the stand vs not-stand line:
*     code5: v1 Multi-day      | v2 Phone-friend
*     code6: v1 Stand-recruiter| v2 Phone-called-friend
*     code7: v1 Stand-friend   | v2 Self-employed
*   v2 has NO multi-day code at all (multiday only via explicit Q).
*
*  FIX (3 parts):
*   (1) howfound_version flag (1=v1 rf4_1, 2=v2 rf4_v2_1).
*   (2) REMAP v2 onto the v1 scheme BEFORE combining (crosswalk
*       below). This keeps existing v1 semantics & the stand union
*       {6,7,8} intact, so downstream code is unchanged, but every
*       combined code now means exactly one thing.
*   (3) GATE the multiday fallback to v1 rows: multiday from
*       howfound==5 ONLY where version==1 (v2 code 5 = phone-friend).
*
*  CROSSWALK  v2 (rf4_v2_1)  ->  v1/target (rf4_1)
*     v2 1,2  Phone-employer (called me / I called)   -> 1
*     v2 3,4  Phone-recruiter (contacted / I called)  -> 2
*     v2 5,6  Phone-friend (offered / I called)        -> 3
*     v2 7    Self-employed                            -> 4
*     v2 8,9  Stand-recruiter (called / I called)      -> 6
*     v2 10   Stand-friend offered at stand            -> 7
*     v2 11   Stand-recruiter offered at stand         -> 8
*     v2 998 Other -> 998 ;  v2 999 Incomplete -> 999
*   (v1 code 5 = Multi-day has no v2 source: stays v1-only.)
*   (howfound_notattend has NO v2 variant -> needs no remap.)
*
*  This file is a PROTOTYPE: it builds & validates the harmonized
*  variable on the raw phase-2 file, then prints the exact drop-in
*  block for code/1_5_phase_1_2/3_combine_phase1_2.do.
*  Author: Claude (diagnostic only; pipeline edit is yours to paste)
*****************************************************************
clear all
set more off
set linesize 160
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_howfound_harmonize.log", replace text

*================================================================*
* A reusable program: harmonize one v2 howfound var to v1 scheme
*================================================================*
capture program drop hf_v2_to_v1
program define hf_v2_to_v1
    * args: 1=source v2 var, 2=new harmonized var name
    args src out
    recode `src' (1 2 = 1)(3 4 = 2)(5 6 = 3)(7 = 4)(8 9 = 6)(10 = 7)(11 = 8) ///
                 (998 = 998)(999 = 999), gen(`out')
end

*================================================================*
* Build harmonized combine on raw phase-2 (has v1 AND v2 per slot)
*================================================================*
use "$temp/03_phase2_completed_cleaned.dta", clear

local n_v2src   0     // # slot-rows sourced from v2
local n_naive_amb 0   // v2-sourced rows whose RAW v2 code is 5/6/7 (ambiguous in naive)
local n_standflip 0   // v2-sourced rows where naive=stand but harmonized=not-stand (or vice versa)
local n_code5_md  0   // v2-sourced rows with raw code 5 (naive would read as multiday)

forval i = 1/7 {
    cap confirm variable f_howfound_`i'
    if _rc continue
    cap confirm variable f_howfound_v2_`i'
    if _rc continue

    * (1) provenance flag
    gen byte hf_version_`i' = .
    replace  hf_version_`i' = 1 if !mi(f_howfound_`i')
    replace  hf_version_`i' = 2 if mi(f_howfound_`i') & !mi(f_howfound_v2_`i')

    * (2a) NAIVE combine (current line 179): raw v2 poured in
    gen hf_naive_`i' = f_howfound_`i'
    replace hf_naive_`i' = f_howfound_v2_`i' if mi(hf_naive_`i')

    * (2b) HARMONIZED combine: remap v2 -> v1 scheme first
    hf_v2_to_v1 f_howfound_v2_`i' hf_v2map_`i'
    gen hf_harm_`i' = f_howfound_`i'
    replace hf_harm_`i' = hf_v2map_`i' if mi(hf_harm_`i')

    * ---- validation tallies (only on v2-sourced rows) ----
    qui count if hf_version_`i'==2
    local n_v2src = `n_v2src' + r(N)
    qui count if hf_version_`i'==2 & inlist(hf_naive_`i',5,6,7)
    local n_naive_amb = `n_naive_amb' + r(N)
    qui count if hf_version_`i'==2 & hf_naive_`i'==5
    local n_code5_md = `n_code5_md' + r(N)
    * stand status under each: stand = codes {6,7,8,9,10,11}
    gen byte st_naive_`i' = inlist(hf_naive_`i',6,7,8,9,10,11) if !mi(hf_naive_`i')
    gen byte st_harm_`i'  = inlist(hf_harm_`i', 6,7,8,9,10,11) if !mi(hf_harm_`i')
    qui count if hf_version_`i'==2 & st_naive_`i'!=st_harm_`i' & !mi(st_naive_`i') & !mi(st_harm_`i')
    local n_standflip = `n_standflip' + r(N)
}

di ""
di "==================================================================="
di " VALIDATION: naive (current) vs harmonized combine, v2-sourced rows"
di "==================================================================="
di "  v2-sourced slot-rows total ........................ `n_v2src'"
di "  ... whose RAW v2 code is 5/6/7 (ambiguous naive) .. `n_naive_amb'"
di "  ... raw code 5 -> naive MISREADS as multi-day ..... `n_code5_md'"
di "  ... STAND-status FLIPS once harmonized ............ `n_standflip'"
di "  (stand-status flips are the dangerous ones: v2 phone/self-emp"
di "   miscoded as a stand channel under the naive combine.)"

di ""
di "==== Example slot 1: naive vs harmonized among v2-sourced rows ===="
label define HFL 1 "1 Phone-employer" 2 "2 Phone-recruiter" 3 "3 Phone-friend" ///
                 4 "4 Self-emp" 5 "5 Multi-day" 6 "6 Stand-recruiter" ///
                 7 "7 Stand-friend" 8 "8 Stand-rec-offered" 998 "998 Other" 999 "999 Incompl", replace
label values hf_naive_1 hf_harm_1 HFL
di " rows where v2 was used (hf_version_1==2):"
tab hf_naive_1 hf_harm_1 if hf_version_1==2, missing

di ""
di "==== (3) GATED multiday rule check (slot 1) ===="
di "  v2 rows with raw code 5 = phone-friend; naive multiday rule"
di "  (howfound==5) would FLAG them. Gated rule (version==1) won't."
gen byte md_naive_1 = (hf_naive_1==5) if !mi(hf_naive_1)
gen byte md_gated_1 = (hf_harm_1==5 & hf_version_1==1) if !mi(hf_harm_1)
di "  multiday flagged by NAIVE howfound==5 (slot1):"
count if md_naive_1==1
di "  multiday flagged by GATED rule (slot1):"
count if md_gated_1==1
di "  of the naive-flagged, how many are v2 phone-friend (should be removed):"
count if md_naive_1==1 & hf_version_1==2

di ""
di "==== Harmonized howfound distribution (slot 1, all rows) ===="
tab hf_harm_1, missing

*================================================================*
* DROP-IN BLOCK for 3_combine_phase1_2.do  (printed for the user)
*================================================================*
di ""
di "================= DROP-IN FOR 3_combine_phase1_2.do ================="
di "* --- REPLACE the current line 179 block (howfound combine) with: ---"
di "* provenance + harmonized combine (v2 remapped to v1 scheme)"
di "apply7 gen byte d_howfound_version_ = ."
di "apply7 replace  d_howfound_version_ = 1 if !mi(d_howfound_)"
di "apply7 replace  d_howfound_version_ = 2 if mi(d_howfound_) & !mi(d_howfound_v2_)"
di "apply7 recode d_howfound_v2_ (1 2=1)(3 4=2)(5 6=3)(7=4)(8 9=6)(10=7)(11=8)(998=998)(999=999)"
di "apply7 replace d_howfound_ = d_howfound_v2_ if mi(d_howfound_)"
di "drop d_howfound_v2_*"
di "*"
di "* --- THEN change the multiday-from-channel line (was line 259) to GATE on v1: ---"
di "apply7 replace d_multiday_job_ = (d_howfound_ == 5) if mi(d_multiday_job_) & !mi(d_howfound_) & d_howfound_version_==1"
di "*   (d_howfound_notattend_ has no v2 variant, so its ==5 rule is unchanged.)"
di "===================================================================="

log close
