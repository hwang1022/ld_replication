set scheme stsj 
clear all

sjlog using tip158a, replace
sysuse auto
summarize mpg
scatter mpg weight || function 21.2973, ra(weight) ytitle(Miles per gallon) ytitle(Weight (pounds)) legend(off)
sjlog close, replace

sjlog using tip158b, replace
summarize weight
scatter mpg weight || function 21.2973 , ra(weight) ///
ytitle(Miles per gallon) xtitle(Weight (pounds)) legend(off) ///
|| scatteri 12 3019 41 3019, recast(line) lp(dash) ///
note(added lines show {it:y} and {it:x} means)
sjlog close, replace
