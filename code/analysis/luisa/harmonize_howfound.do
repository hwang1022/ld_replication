*****************************************************************
*  harmonize_howfound.do
*  Harmonize the two howfound codings (v1 rf4_1 / v2 rf4_v2_1)
*  by remapping v2 onto the v1 scheme BEFORE combining.
*
*  v2 (rf4_v2_1)  ->  v1 (rf4_1)
*    1,2 Phone-employer   -> 1
*    3,4 Phone-recruiter  -> 2
*    5,6 Phone-friend     -> 3
*    7   Self-employed    -> 4
*    8,9 Stand-recruiter  -> 6
*    10  Stand-friend     -> 7
*    11  Stand-rec-offered-> 8
*  (v1 code 5 = Multi-day has no v2 equivalent.)
*****************************************************************

forval i = 1/7 {
    * remap v2 codes to the v1 scheme
    recode d_howfound_v2_`i' (1 2=1)(3 4=2)(5 6=3)(7=4)(8 9=6)(10=7)(11=8)

    * combine: use v1; fall back to the remapped v2 where v1 is missing
    replace d_howfound_`i' = d_howfound_v2_`i' if mi(d_howfound_`i')
}
