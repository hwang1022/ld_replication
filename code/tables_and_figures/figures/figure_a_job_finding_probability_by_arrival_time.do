if "$data" == "" {
	global data "`c(pwd)'/data"
}
if "$data_final" == "" {
	global data_final "${data}/final"
}
if "$data_temp" == "" {
	global data_temp "${data}/temp"
}
if "$output" == "" {
	global output "${data}/output"
}
local analysis_main "$data_final/analysis_main.dta"

cap mkdir "$output"
cap mkdir "$output/figures"

use "`analysis_main'", clear
cap gen arrival_time_hours_30 = .
forvalues i = 6/10 {
	replace arrival_time_hours_30 = `i' if arrival_time_hours < `i'.5 & arrival_time_hours_30 == . & phase == 0
	replace arrival_time_hours_30 = `i'.5 if arrival_time_hours < `i' + 1 & arrival_time_hours_30 == . & phase == 0
}

binscatter work arrival_time_hours_30 if arrival_time_hours <= 10 & phase == 0, ///
	xlabel(6(0.5)10 6.5 "6.30" 7.5 "7.30" 8.5 "8.30" 9.5 "9.30") ///
	ylabel(, nogrid) xtitle("Arrival Time") ytitle("Mean Work") ///
	line(connect) lc(maroon) mc(navy) yscale(range(0.4 0.8))

graph export "$output/figures/comm_bs_attend_work_30.pdf", replace
graph export "$output/figures/figure_a.pdf", replace
