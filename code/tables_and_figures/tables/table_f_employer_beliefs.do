**************************************************
* Table 7: Employer beliefs
**************************************************

version 17
clear all
set more off

local employer_activity_cleaned  "$final/ls_employer_activity_mainstudy_named.dta"

local outdir "$output/tables"
capture mkdir "$output"
capture mkdir "`outdir'"
local table_tex "`outdir'/table_f_employer_beliefs.tex"
local alias_tex "`outdir'/table_f.tex"

/*----------------------------------------------------*/
   /* [>  9.  Employers' belief survey   <] */
/*----------------------------------------------------*/

use "`employer_activity_cleaned'", clear

summarize trained_2_weeks, detail
local med_2wk: display %9.0fc r(p50)
local med_2wk = strtrim("`med_2wk'")
local diff_2wk: display %9.1fc (r(p50) - 46)*100/46
local diff_2wk = strtrim("`diff_2wk'")

summarize trained_2_months, detail
local med_2mth: display %9.0fc r(p50)
local med_2mth = strtrim("`med_2mth'")
local diff_2mth: display %9.1fc (r(p50) - 45)*100/45
local diff_2mth = strtrim("`diff_2mth'")

summarize trained_4_months, detail
local med_4mth: display %9.0fc r(p50)
local med_4mth = strtrim("`med_4mth'")
local diff_4mth: display %9.1fc (r(p50) - 30)*100/30
local diff_4mth = strtrim("`diff_4mth'")

file open table_out using "`table_tex'", write replace text
file write table_out "\begin{table}[htbp!]" _n
file write table_out "\caption{Employer beliefs}" _n
file write table_out "\label{tab:emp-beliefs}" _n
file write table_out "\centering" _n
file write table_out "\renewcommand{\arraystretch}{1.5} %" _n
file write table_out "\begin{threeparttable}" _n
file write table_out "\begin{tabular}{|c|c|c|c|c|}" _n
file write table_out "\hline" _n
file write table_out "Time Point & Control & Treatment & Treatment & \% Change \\" _n
file write table_out " &  &  & (median) & \\" _n
file write table_out " (1) & (2) & (3) & (4) & (5)  \\" _n
file write table_out "\hline" _n
file write table_out "2 Weeks & 46 & 55 & `med_2wk' & `diff_2wk'\% \\" _n
file write table_out "\hline" _n
file write table_out "2 Months & 45 & 50 & `med_2mth' & `diff_2mth'\% \\" _n
file write table_out "\hline" _n
file write table_out "4 Months & 30 & 33 & `med_4mth' & `diff_4mth'\% \\" _n
file write table_out "\hline" _n
file write table_out "\end{tabular}" _n
file write table_out "\begin{tablenotes}" _n
file write table_out "\textit{Notes:} This table presents results from an incentivized survey with employers where we elicit beliefs regarding the impact of our intervention. Column 1 indicates several time points after the end of Phase 1. Columns 2 and 3 indicate counts of control and treatment participants (out of 100) respectively attending the stand at the different time points, based on the experimental data. Column 4 summarizes employers' median responses to the number of treated workers attending the stand each day at the time points indicated in Column 1, while Column 5 presents the corresponding percentage change in expected attendance between treatment and control participants." _n
file write table_out "\end{tablenotes}" _n
file write table_out "\end{threeparttable}" _n
file write table_out "\end{table}" _n
file close table_out

copy "`table_tex'" "`alias_tex'", replace
