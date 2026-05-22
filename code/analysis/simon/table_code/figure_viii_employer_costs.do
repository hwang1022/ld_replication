global data "`c(pwd)'/data"
local employers_survey "$data/final/ls_employers_survey_combined.dta"

cap mkdir "$data/output"
cap mkdir "$data/output/figures"

use `employers_survey', clear

tostring rec_rpw_work_1, replace
replace rec_rpw_work_1 = rec_worker_type if !mi(rec_rpw_find_time)
replace rec_rpw_find_time_1 = rec_rpw_find_time if !mi(rec_rpw_find_time)
replace rec_rpw_onboard_time_1 = rec_rpw_onboard_time if !mi(rec_rpw_onboard_time)

replace rec_rpw_work_1 = "5. Concrete" if rec_rpw_work_1 == "5"
replace rec_rpw_work_1 = "4. Centering" if rec_rpw_work_1 == "4"
replace rec_rpw_work_1 = "3. Tile Worker" if rec_rpw_work_1 == "3"
replace rec_rpw_work_1 = "10. Painter" if rec_rpw_work_1 == "10"
replace rec_rpw_work_1 = "1. Foundation" if rec_rpw_work_1 == "1"
replace rec_rpw_work_1 = "11. Carpenter" if rec_rpw_work_1 == "11"
replace rec_rpw_work_1 = "2. Wall Builder" if rec_rpw_work_1 == "2"
replace rec_rpw_work_1 = "6. Demolisher" if rec_rpw_work_1 == "6"
replace rec_rpw_work_1 = "7. Loadman" if rec_rpw_work_1 == "7"
replace rec_rpw_work_1 = "9. Welder" if rec_rpw_work_1 == "9"

reshape long rec_rpw_work_ rec_rpw_find_time_ rec_rpw_onboard_time_, i(recruiter_id) j(choice)
gen worker_skill = 1 if rec_rpw_work_ == "1. Foundation" | rec_rpw_work_ == "2. Wall Builder" | rec_rpw_work_ == "4. Centering" | rec_rpw_work_ == "5. Concrete" | rec_rpw_work_ == "6. Demolisher" | rec_rpw_work_ == "7. Loadman" | rec_rpw_work_ == "8. Stone Cutter"
replace worker_skill = 2 if rec_rpw_work_ == "3. Tile Worker" | rec_rpw_work_ == "9. Welder" | rec_rpw_work_ == "10. Painter" | rec_rpw_work_ == "11. Carpenter"

twoway (hist rec_rpw_find_time_ if worker_skill == 1, lcolor(gs12) fcolor(gs12) width(1) fraction start(1) discrete) || ///
	(hist rec_rpw_find_time_ if worker_skill == 2, fcolor(none) lcolor(maroon) width(1) lwidth(medium) fraction start(1) discrete), ///
	xtitle("Duration", size(medium)) ytitle("Fraction of recruiter responses", size(medium)) yla(, labsize(*1.25)) ///
	legend(label(1 "Unskilled") label(2 "Skilled") pos(2) ring(0) region(lcolor(black))) ///
	xlabel(1 "<30 mins" 2 "30-90 mins" 3 ">90 mins" 4 `""Not worth" "replacing""' 5 `""Okay to delay"" work""', angle(0) labsize(medium))
graph export "$data/output/figures/rec_replacement_duration.pdf", replace
graph export "$data/output/figures/figure_viii_a.pdf", replace

gen d1_b_coded = 1 if rec_rpw_onboard_time_ < 30
replace d1_b_coded = 2 if rec_rpw_onboard_time_ >= 30 & rec_rpw_onboard_time_ < 60
replace d1_b_coded = 3 if rec_rpw_onboard_time_ >= 60

twoway (hist d1_b_coded if worker_skill == 1, lcolor(gs12) fcolor(gs12) width(1) fraction start(1) discrete) || ///
	(hist d1_b_coded if worker_skill == 2, fcolor(none) lcolor(maroon) width(1) lwidth(medium) fraction start(1) discrete), ///
	xtitle("Duration") ytitle("Fraction of recruiter responses", size(medium)) yla(, labsize(*1.3)) ///
	legend(label(1 "Unskilled") label(2 "Skilled") pos(2) ring(0) region(lcolor(black))) ///
	xlabel(1 "<30 mins" 2 "30-90 mins" 3 ">90 mins", labsize(medium))
graph export "$data/output/figures/rec_wrkr_training_duration.pdf", replace
graph export "$data/output/figures/figure_viii_b.pdf", replace
