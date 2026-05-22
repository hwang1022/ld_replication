************************************************************
* Table 8: Employer Willingness to Pay for Workers with Habit Stock
* Source: main_analysis_2024_11_14.do, Employers' job offer survey block
*
* Note: verification.md flags a title/header mismatch. The paper table title is
* "Employer Willingness to Pay for Workers with Habit Stock", while the source
* code section header is "Employers' job offer survey".
************************************************************

version 17
clear all
set more off

global data "`c(pwd)'/data"
local employer_job_offer_cleaned "$data/02. Cleaning Data/08. Others/02. Output/Employers Survey/employer_job_offer_cleaned.dta"

local outdir "$data/output/tables"
capture mkdir "$data/output"
capture mkdir "`outdir'"

local table_tex "`outdir'/table_viii_employer_job_offer_survey.tex"
local alias_tex "`outdir'/table_viii.tex"

/*----------------------------------------------------*/
   /* [>  10.  Employers' job offer survey   <] */
/*----------------------------------------------------*/

use `employer_job_offer_cleaned', clear

isid pid
local emp_joboffer_sample_N: display %9.0fc _N
local emp_joboffer_sample_N = strtrim("`emp_joboffer_sample_N'")

* Equal subsidy of Rs. 300.
recode Subsidy_1 (2 = 0)
summarize Subsidy_1
local Subsidy_1_mean: display %9.1fc r(mean) * 100
local Subsidy_1_mean = strtrim("`Subsidy_1_mean'")

recode Subsidy_2 (2 = 0) (. = 0)
summarize Subsidy_2
local Subsidy_2_mean: display %9.1fc r(mean) * 100
local Subsidy_2_mean = strtrim("`Subsidy_2_mean'")

recode Subsidy_3 (2 = 0) (. = 0)
summarize Subsidy_3
local Subsidy_3_mean: display %9.1fc r(mean) * 100
local Subsidy_3_mean = strtrim("`Subsidy_3_mean'")

recode Subsidy_4 (2 = 0) (. = 0)
summarize Subsidy_4
local Subsidy_4_mean: display %9.1fc r(mean) * 100
local Subsidy_4_mean = strtrim("`Subsidy_4_mean'")

recode Subsidy_5 (2 = 0) (. = 0)
summarize Subsidy_5
local Subsidy_5_mean: display %9.1fc r(mean) * 100
local Subsidy_5_mean = strtrim("`Subsidy_5_mean'")

file open table_out using "`table_tex'", write replace text
file write table_out "\begin{table}[htbp!]" _n
file write table_out "\caption{Employer Willingness to Pay for Workers with Habit Stock}" _n
file write table_out "\label{tab:emp-wtp}" _n
file write table_out "\centering" _n
file write table_out "\begin{threeparttable}" _n
file write table_out "\begin{tabular}{|c|c|c|c|c|c|}" _n
file write table_out "\hline" _n
file write table_out "Subsidy: untrained (INR) & 300 & 300 & 300 & 300 & 300 \\" _n
file write table_out "\hline" _n
file write table_out "Subsidy: trained (INR) & 300 & 250-275 & 200-250 & 150-225 & 100-200 \\" _n
file write table_out "\hline" _n
file write table_out "\% choose trained & `Subsidy_1_mean' & `Subsidy_2_mean' & `Subsidy_3_mean' & `Subsidy_4_mean' & `Subsidy_5_mean' \\" _n
file write table_out "\hline" _n
file write table_out "\end{tabular}" _n
file write table_out "\begin{tablenotes}" _n
file write table_out "\textit{Notes:} This table presents results from an incentivized survey with employers where we elicit willingness to pay for trained workers with habit stock." _n
file write table_out "\end{tablenotes}" _n
file write table_out "\end{threeparttable}" _n
file write table_out "\end{table}" _n
file close table_out

copy "`table_tex'" "`alias_tex'", replace
