global data "`c(pwd)'/data"
local analysis_main "$data/final/analysis_main.dta"

cap mkdir "$data/output"
cap mkdir "$data/output/figures"

use `analysis_main', clear
duplicates drop pid, force
label define lngterm_work 1 "Least likely" 2 "Not likely" 3 `""Neither likely""or unlikely""' 4 "Likely" 5 "Very likely"
label value bs_dem_lngterm_work lngterm_work
twoway hist bs_dem_lngterm_work, lcolor(gs12) fcolor(gs12) frac xla(1/5, valuelabel) discrete width(0.5) xtitle("")
graph export "$data/output/figures/bs_dem_no_ltjob.pdf", replace
graph export "$data/output/figures/figure_vi_a.pdf", replace

use `analysis_main', clear
duplicates drop pid, force
keep pid bs_dem_no_ltjob_*
drop bs_dem_no_ltjob_reasons bs_dem_no_ltjob_reasons_oth
reshape long bs_dem_no_ltjob_, i(pid) j(reason)
collapse (mean) bs_dem_no_ltjob_, by(reason)
gsort -bs_dem_no_ltjob_
gen reason_by_popular = _n
label define no_ltjob_lab_sorted 1 "Earn more" 2 `""Like current""profession""' 3 `""Prefer" "flexibility" "' 4 `""More free""time""' 5 `""Don't like""having boss""' 6 `""Don't have""qualifications""'
label value reason_by_popular no_ltjob_lab_sorted
graph bar bs_dem_no_ltjob_, over(reason_by_popular, label(labsize(medium))) xsize(8) ytitle("Fraction") bar(1, fcolor(gs12) lcolor(gs12))
graph export "$data/output/figures/bs_dem_no_ltjob_reasons.pdf", replace
graph export "$data/output/figures/figure_vi_b.pdf", replace
