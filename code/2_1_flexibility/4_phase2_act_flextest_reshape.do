**************************************************
* Project: LD Main Study
* Purpose: Phase 2 activity - flexibility test cleaning
* Author: HW
* Last modified: 2026-04-14 (HW)
**************************************************

use "$temp/05c_phase2act_flextest_combined.dta", clear

egen flex_num_obs = rownonmiss(fixed_choice_q1 fixed_choice_q2)
reshape long fixed_choice_q, i(pid date) j(question_num)

keep if !missing(fixed_choice_q)

save "$temp/05d_phase2act_flextest_reshaped.dta", replace


