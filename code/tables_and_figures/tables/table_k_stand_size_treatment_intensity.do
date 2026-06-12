************************************************************
* Appendix Table A.4: Stand Size and Treatment Intensity
************************************************************

version 17
clear all
set more off

local stand_size_studysample "$final/stand_size_intensity_studysample.dta"

local tables "$output/tables"
local verified_tex "`tables'/stand_size_tex_compact_studysample.tex"
local roman_alias "`tables'/table_k.tex"
capture mkdir "$output"
capture mkdir "`tables'"

use "`stand_size_studysample'", clear

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

mkmat num_rid final_stand_size_exp num_treatment treat_intensity_exp, matrix(table_k)
levelsof stand, local(stands)
matrix rownames table_k = `stands'
matrix colnames table_k = Workers_Approached Estimated_Stand_Size Assigned_Treatment Treatment_Intensity

esttab matrix(table_k, fmt(0 1 0 2)) using "`verified_tex'", replace ///
	booktabs nomtitles nonumbers noobs label ///
	collabels("Workers Approached" "Estimated Stand Size" "Assigned Treatment" "Treatment Intensity") ///
	fragment

copy "`verified_tex'" "`roman_alias'", replace
