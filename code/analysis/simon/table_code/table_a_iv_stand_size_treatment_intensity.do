************************************************************
* Appendix Table A.4: Stand Size and Treatment Intensity
************************************************************

version 17
clear all
set more off

global data "`c(pwd)'/data"
local stand_size_studysample "$data/stand_strength/data/stand_size_intensity_studysample.dta"

local tables "$data/output/tables"
capture mkdir "$data/output"
capture mkdir "`tables'"

use `stand_size_studysample', clear

tempvar stand_group
egen `stand_group' = group(stand)
drop stand
rename `stand_group' stand

label var num_rid "\shortstack{Workers\\Approached}"
label var num_treatment "\shortstack{Assigned\\Treatment}"
label var final_stand_size_exp "\shortstack{Finalized\\Stand Size}"
label var treat_intensity_exp "\shortstack{Treatment\\Intensity}"

replace final_stand_size_exp = round(final_stand_size_exp, 1)
replace treat_intensity_exp = round(treat_intensity_exp, 0.0001)

order stand num_rid final_stand_size_exp num_treatment treat_intensity_exp
keep stand num_rid final_stand_size_exp num_treatment treat_intensity_exp

texsave _all ///
	using "`tables'/stand_size_tex_compact_studysample.tex", ///
	varlabels replace frag width(.8\columnwidth) ///
	location(H)

copy "`tables'/stand_size_tex_compact_studysample.tex" "`tables'/table_a_iv.tex", replace
