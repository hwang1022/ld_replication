clear all
set more off

// Using OLD data fuild for this since new one is missing the phase variable 
local time_use_makepanel "$temp/03-time-use-makepanel.dta"

local outdir "$output/tables"
capture mkdir "$output"
capture mkdir "`outdir'"

use "`time_use_makepanel'", clear

eststo clear

eststo: reg tu_jfp_8am treatment i.stand i.strata if phase == 2, cl(pid)
estadd local surveydate "No", replace
sum tu_jfp_8am if e(sample) & treatment == 0
estadd scalar y_mean = r(mean)

eststo: reg tu_jfp_8am treatment i.stand i.strata i.date if phase == 2, cl(pid)
estadd local surveydate "Yes", replace
sum tu_jfp_8am if e(sample) & treatment == 0
estadd scalar y_mean = r(mean)

label var tu_jfp_8am "Days"
label var treatment "Treatment"

esttab using "`outdir'/tu_jfp_8am_short.tex", ///
    se keep(treatment) nostar l ///
    cells(b(fmt(a3)) se(fmt(3) par) p(fmt(3) par([ ]))) ///
    nonotes starlevels(* 0.10 ** 0.05 *** .01) ///
    stats(surveydate y_mean N, ///
        labels("Survey date FE" "Control mean" "N: worker-survey")) ///
    replace collabels(none) frag gaps

copy "`outdir'/tu_jfp_8am_short.tex" "`outdir'/table_c.tex", replace
