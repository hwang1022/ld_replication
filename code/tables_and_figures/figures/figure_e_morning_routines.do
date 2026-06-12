local final_data_w_shocks "$final/final_data_w_shocks.dta"

cap mkdir "$output"
cap mkdir "$output/figures"

use "`final_data_w_shocks'", clear
keep if !mi(r_reg_morning_act_water)
reshape long r_reg_morning_act_, i(pid) j(activities) string
statsby, by(activities treatment) clear: ci means r_reg_morning_act_, level(90)
drop N se level

gen bord = 1 if activities == "water"
replace bord = 2 if activities == "cook_breakf"
replace bord = 3 if activities == "eat_breakf"
replace bord = 4 if activities == "help_kids"
replace bord = 5 if activities == "drop_kids"
replace bord = 6 if activities == "wash"
replace bord = 7 if activities == "pray"
replace bord = 8 if activities == "shopping"
replace bord = 9 if activities == "oth"

twoway (bar mean bord if treatment == 0, lcolor(gs12) fcolor(gs12)) || ///
	(bar mean bord if treatment == 1, fcolor(none) lcolor(maroon)),  /// ||
	xlabel(1 `" "Get" "water" "' 2 `" "Cook" "breakfast" "' 3 `" "Eat" "breakfast" "' 4 `" "Help get" "kids ready" "' 5 `" "Drop kids" "at school" "' 6 "Wash/bathe" 7 `" "Temples/" "prayers" "' 8 `" "Go to the" "store/shop" "' 9 "Others", noticks labsize(small)) ///
	xtitle("") ytitle("Percent of respondents selecting each option") legend(order(1 "Control" 2 "Treatment") pos(6) row(1))
graph export "$output/figures/bar_morning_activities_low_att.pdf", replace
graph export "$output/figures/figure_e_a.pdf", replace

use "`final_data_w_shocks'", clear
keep if !mi(r_morning_alarm)
graph bar (meanci) r_morning_alarm, over(treatment) asyvars ///
	bar(1, fcolor(gs12) lcolor(gs12)) bar(2, fcolor(none) lcolor(maroon)) ///
	ytitle("Share of respondents") yscale(range(0 0.5)) ///
	legend(order(1 "Control" 2 "Treatment") row(1) position(bottom))
graph export "$output/figures/bars_use_alarm.pdf", replace
graph export "$output/figures/figure_e_b.pdf", replace
