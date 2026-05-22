# Figures and Tables Mapping Verification

## Summary

| Status | Count |
|--------|-------|
| CORRECT | 23 |
| CLOSE | 6 |
| INCORRECT | 1 |
| NEEDS REVIEW | 1 |
| ORPHAN | 1 |

---

## Replication Package (`ld_replication.do`)

### Figures

| Number | Title | Line | Expected Output | Actual Output | Verdict |
|--------|-------|------|-----------------|---------------|---------|
| Figure 1 | Probability of finding a job by arrival time | 54-66 | `comm_bs_attend_work_30` | `comm_bs_attend_work_30.pdf` | **CORRECT** — header matches, stem matches |
| Figure 2a | Treatment effect on attendance and arrival time in Phase 1 — Weekly attendance | 79-84 | `comm_dist_attend_nadj_p1` | `comm_dist_attend_nadj_p1.pdf` | **CORRECT** — loop phase=1 matches |
| Figure 2b | Treatment effect on attendance and arrival time in Phase 1 — Arrival time | 79,87-88 | `hist_arrival_time_by_treatment_p1_daily` | `hist_arrival_time_by_treatment_p1_daily.pdf` | **CORRECT** |
| Figure 3a | Treatment effect in Phase 2 — Weekly attendance | 79-84 | `comm_dist_attend_nadj_p2` | `comm_dist_attend_nadj_p2.pdf` | **CORRECT** — loop phase=2 matches |
| Figure 3b | Treatment effect in Phase 2 — Arrival time | 79,87-88 | `hist_arrival_time_by_treatment_p2_daily` | `hist_arrival_time_by_treatment_p2_daily.pdf` | **CORRECT** |
| Figure 4 | Attendance (treatment effects over time) | 93-155 | `habit_over_time_ci` | `attend_adj_bs_p1_p2_p3_stand_calweek_v2.pdf` (CI version at line 155) | **INCORRECT** — completely different filename. Header says "Figure 4: Attendance" but the actual output stem bears no resemblance to `habit_over_time_ci`. Two exports exist: line 136 produces `_noci.pdf` and line 155 produces the CI version. The expected filename was not found anywhere in the file. |

### Tables

| Number | Title | Line | Expected Output | Actual Output | Verdict |
|--------|-------|------|-----------------|---------------|---------|
| Table 1 | Labor Supply Effects | 161, 227 | `com_weekly_attend_b8_attend_work1_frag2` | `com_weekly_attend_b8_attend_work1_frag2_rephw.tex` | **CLOSE** — header/title match, stem matches, but code appends `_rephw` suffix not in tracking doc |
| Table 2 | Shocks Erode Habit Stock | 237-238, 463-471 | `shocks_attendloo_b25_feb_3` | `shocks_attendloo_b25_bootstrap_jul.tex` | **CLOSE** — header/title match, stem `shocks_attendloo_b25` matches, but code appends `_bootstrap_jul` not `_feb_3` |

---

## Figures in Old Code (`ld_replication_newdata.do`)

Location: `replication/code/analysis/archive/ld_replication_newdata.do`

| Number | Title | Line | Expected Output | Actual Output | Verdict |
|--------|-------|------|-----------------|---------------|---------|
| Figure 5a | Treatment effect on morning routines — Activities done in the morning | 143 | `bar_morning_activities_low_att` | `bar_morning_activities_low_att.pdf` | **CORRECT** — header at line 111: "Figure 5", Panel A at line 115 |
| Figure 5b | Treatment effect on morning routines — Usage of an alarm | 160 | `bars_use_alarm` | `bars_use_alarm.pdf` | **CORRECT** — Panel B at line 147 |
| Figure 6a | Job preferences at baseline — Likelihood of accepting a long-term, formal job | 176 | `bs_dem_no_ltjob` | `bs_dem_no_ltjob.pdf` | **CORRECT** — header at line 165: "Figure 6: Job preferences at baseline", comment says "(a) Likelihood of accepting..." |
| Figure 6b | Job preferences at baseline — Characteristics of casual jobs most appreciated | 198 | `bs_dem_no_ltjob_reasons` | `bs_dem_no_ltjob_reasons.pdf` | **CORRECT** — comment at line 180: "(b) Characteristics of casual jobs found at the stands most appreciated by participants" |
| Figure 7 | Predicted Worker Absenteeism | 208 | `workers_days_off_10` | `workers_days_off_10.pdf` | **CORRECT** — header at line 202 matches title exactly |
| Figure 8a | Costs incurred by employers — Time taken to find a replacement worker | 259 | `rec_replacement_duration` | `rec_replacement_duration.pdf` | **CORRECT** — header at line 214: "Figure 8: Costs incurred by employers", comment confirms replacement time |
| Figure 8b | Costs incurred by employers — Time taken to onboard a new worker | 272 | `rec_wrkr_training_duration` | `rec_wrkr_training_duration.pdf` | **CORRECT** — sub-header at line 262: "Training - time taken to onboard" |
| Figure 9 | Potential implications for labor market structure | 307 | `emp_resp_c7_n7` | `emp_resp_c7_n7.pdf` (at line 305) | **CORRECT** — filename matches, title at line 277 matches, but actual `graph export` is on line 305 not 307 (2-line offset) |

---

## Figure A.1 (`3_shocks_loso_originaldata.do`)

Location: `hao_working_folder/oct_25_presentation/3_shocks_loso_originaldata.do`

| Number | Title | Line | Expected Output | Actual Output | Verdict |
|--------|-------|------|-----------------|---------------|---------|
| Figure A.1 (Treat) | Disruptions Effect Robustness — Coefficient for Treat | 443 | `treatment_effect_by_shock_threshold_col3_treat_loso_originaldata` | exact match (`.pdf`) | **CORRECT** — section header "Column 3 - Treat", extracts `_b[treat]` |
| Figure A.1 (Treat x Post) | Disruptions Effect Robustness — Coefficient for Treat x Post | 479 | `treatment_effect_by_shock_threshold_col3_treatpost_loso_originaldata` | exact match (`.pdf`) | **CORRECT** — section header "Column 3 - Treat*Post", extracts `_b[treatXpost_attend_j]` |

---

## Tables in Old Code — Main Analysis (`main_analysis_2024_11_14.do`)

Location: `hao_working_folder/paper/update_paper_feb_3/main_analysis_2024_11_14.do`

| Number | Title | Line | Expected Output | Actual Output | Verdict |
|--------|-------|------|-----------------|---------------|---------|
| Table 3 | Perceived job finding probability | 1878 | `tu_jfp_8am_short` | `tu_jfp_8am_short.tex` | **CORRECT** — section header at line 1804: "Table: Perceived job finding probability" matches |
| Table 7 | Employer beliefs | 2467-2489 | inline: `med_2wk`, `med_2mth`, `med_4mth`, `diff_2wk`, `diff_2mth`, `diff_4mth` | all 6 stat names match exactly | **CORRECT** — section header "Employers' belief survey" closely matches |
| Table 8 | Employer Willingness to Pay for Workers with Habit Stock | 2505-2530 | inline: `Subsidy_1_mean` through `Subsidy_5_mean` | all 5 stat names match exactly | **NEEDS REVIEW** — stat names correct but code section header is "Employers' job offer survey", NOT "Employer Willingness to Pay for Workers with Habit Stock". The phrase "Habit Stock" never appears in the do-file. |

---

## Tables in Old Code — Paper Analysis (`paper_analysis_newdata.do`)

Location: `replication/code/analysis/archive/paper_analysis_newdata.do`

| Number | Title | Line | Expected Output | Actual Output | Verdict |
|--------|-------|------|-----------------|---------------|---------|
| Table 4 | Automaticity: Change in Psychological Default | 833 | `vig_cog_going_wo_think_attendloo_b25` | `vig_cog_going_wo_think_attendloo_b25.tex` | **CORRECT** — section header "Automaticity", DV is `cog_going_without_thinking` (psychological default) |
| Table 6 | Willingness to Forgo Flexibility | 880 | `flex_fixed_choice_attendloo_b25` | `flex_fixed_choice_attendloo_b25.tex` | **CORRECT** — section header "Flexibility", DVs are `jl_choice1_fixed_vs_stand` and `fixed_choice_q` |

Note: Neither Table 4 nor Table 6 has an explicit table-number comment in the code. Only Tables 2 and 3 are explicitly labeled in this file. The numbering is assigned externally by the paper / tracking document.

---

## Table 5 — Orphan

Location: `hao_working_folder/paper/habit_formation_project/tables/motivational_evidence2.tex`

| Number | Title | Expected Output | Verdict |
|--------|-------|-----------------|---------|
| Table 5 | Evidence for Persistence in Other Datasets | `motivational_evidence2` | **ORPHAN** — no producing code found |

**Investigation results:**

- The `.tex` file exists and is a hand-written LaTeX table (not auto-generated by `esttab`/`estout`).
- Content: regression estimates from two external papers — Kaur et al. 2015 (columns 1-2) and Carranza et al. 2022 (columns 3-4). Key regressors: "Lagged highest target imposed" and "Lagged log piece rate."
- A sibling file `motivational_evidence.tex` exists with columns swapped (Carranza first, Kaur second).
- No `.do` file (or any code file) anywhere in the repository references `motivational_evidence2`.
- The table is used only in presentation slide decks (13 `.tex` files), not in `paper_main.tex`.
- The title "Evidence for Persistence in Other Datasets" is accurate given the content.

---

## Appendix Tables

### Table A.1 (`FAQ_analysis.do`)

Location: `hao_working_folder/FAQ_analysis.do`

| Number | Title | Line | Expected Output | Actual Output | Verdict |
|--------|-------|------|-----------------|---------------|---------|
| Table A.1 | Weekly Incentive Amount in Phase 1 (Nominal Rs.) | 703 | `balance_test_incentive_record_only` | `balance_test_incentive_record_only.tex` | **CLOSE** |

**Details:** Output filename matches. But the code section header is "Balance Check" (line 685), and the table is a `baltab` balance test (Control vs. Treatment, pairwise t-test) for the single variable `amount_allotted` (labeled "Payment allocated"). The tracking doc's title "Weekly Incentive Amount in Phase 1 (Nominal Rs.)" does not appear in the code and oversimplifies what is actually a balance test table. No "Table A.1" label exists in the code. The generated .tex file shows: Control mean = 163.967, Treatment mean = 159.671, p = 0.460.

### Table A.2 (`nov_paper_analysis.do`)

Location: `hao_working_folder/nov_paper/nov_paper_analysis.do`

| Number | Title | Line | Expected Output | Actual Output | Verdict |
|--------|-------|------|-----------------|---------------|---------|
| Table A.2 | Baseline Characteristics | 422 | `baseline_treatment_control_balance3col` | `baseline_treatment_control_balance3col.tex` | **CLOSE** |

**Details:** Output filename and line number are exact matches. The code section header at line 392 says "Baseline Balance" — not "Baseline Characteristics." The content is a 3-column table (control mean, treatment mean, regression p-value) for baseline demographics. The table is also written to `$ol_tables/` at line 453. No "Table A.2" label appears in the code.

### Table A.3 (`5_consumption_originaldata.do`)

Location: `hao_working_folder/oct_25_presentation/5_consumption_originaldata.do`

| Number | Title | Line | Expected Output | Actual Output | Verdict |
|--------|-------|------|-----------------|---------------|---------|
| Table A.3 | Habit formation in Consumption? | 77 | `iv_com_weekly_attend_nop1attendance_originaldata` | exact match (`.tex`) | **CORRECT** |

**Details:** Exact filename match. File labeled "5. Consumption" / "Consumption Effect, IV." The specification is labeled "Not Controlling for Phase 1 attendance" (`nop1attendance`), consistent with the filename. Uses `ivregress 2sls` with `higher_amount_payed_mean` instrumented by `higher_amount_allotted_mean`.

### Table A.4 (`4_2_produce_final_dataset_225.do`)

Location: `hao_working_folder/stand_strength/4_2_produce_final_dataset_225.do`

| Number | Title | Line | Expected Output | Actual Output | Verdict |
|--------|-------|------|-----------------|---------------|---------|
| Table A.4 | Stand Size and Treatment Intensity | 138 | `stand_size_tex_compact_studysample` | `stand_size_tex_compact_studysample.tex` | **CORRECT** |

**Details:** Uses `texsave` to write a compact LaTeX table with variables `stand`, `num_rid`, `final_stand_size_exp`, `num_treatment`, `treat_intensity_exp` (lines 135-136). Content consistent with the claimed title.

### Table A.5 (`6_ge_effect_originaldata.do`)

Location: `hao_working_folder/oct_25_presentation/6_ge_effect_originaldata.do`

| Number | Title | Line | Expected Output | Actual Output | Verdict |
|--------|-------|------|-----------------|---------------|---------|
| Table A.5 | General Equilibrium Effects | 153 | `com_weekly_attend_b8_attend_work1_frag2_faq_higher_treat_intensity_exp_originaldata_short` | `com_weekly_attend_b8_attend_work1_frag2_faq_higher_treat_intensity_exp_originaldata.tex` | **CLOSE** |

**Details:** The core filename matches exactly. The tracking doc appends `_short` which does not appear anywhere in the code. The output is produced within a `foreach het in ...` loop (line 70) iterating over four heterogeneity variables. Line 153 writes Panel C (p-values from suest tests) appended to Panels A and B (lines 103-119).

### Table A.6 (`1_phase_1_shocks.do`)

Location: `hao_working_folder/oct_25_presentation/1_phase_1_shocks.do`

| Number | Title | Line | Expected Output | Actual Output | Verdict |
|--------|-------|------|-----------------|---------------|---------|
| Table A.6 | Disruptions During Phase 1 | 926 | `shocks_attend_j25_bootstrap_phase1_no_cols56` | `shocks_attend_j25_bootstrap_phase1.tex` | **CLOSE** |

**Details:** `shock_threshold` is set to 25 at line 829. The core filename `shocks_attend_j25_bootstrap_phase1` matches exactly. The `_no_cols56` suffix does not appear anywhere in the do-file (confirmed by grep). The tracking doc already noted this discrepancy. A second companion table `_regularp_phase1.tex` is also produced at line 937.

### Table A.7 (`3_shocks_spec_table_originaldata.do`)

Location: `hao_working_folder/oct_25_presentation/3_shocks_spec_table_originaldata.do`

| Number | Title | Line | Expected Output | Actual Output | Verdict |
|--------|-------|------|-----------------|---------------|---------|
| Table A.7 | Shock Analysis — Robustness (column 3) | 1529 | `shocks_analysis_col_3_robustness_originaldata` | `shocks_analysis_col_3_robustness_originaldata.tex` | **CORRECT** |

**Details:** Section header at line 1468: "5.1. Robustness Check for Column 3." Seven robustness variants: Main Spec, Lasso Residual, P20, P30, Baseline Only, 4-Day Rolling, 7-Day Rolling. No explicit "Table A.7" label — numbering is external.

### Table A.8 (`3_shocks_spec_table_originaldata.do`)

Location: `hao_working_folder/oct_25_presentation/3_shocks_spec_table_originaldata.do`

| Number | Title | Line | Expected Output | Actual Output | Verdict |
|--------|-------|------|-----------------|---------------|---------|
| Table A.8 | Shock Analysis — Robustness (column 4) | 1602 | `shocks_analysis_col_4_robustness_originaldata` | `shocks_analysis_col_4_robustness_originaldata.tex` | **CORRECT** |

**Details:** Section header at line 1540: "5.2. Robustness Check for Column 4." Same robustness variants as A.7, using column 4 specification (includes `treatXweek_in_dm`). No explicit "Table A.8" label.

---

## Issues Requiring Action

1. **Figure 4**: Expected `habit_over_time_ci` but actual output is `attend_adj_bs_p1_p2_p3_stand_calweek_v2`. This mapping is wrong — fix or find the correct figure.

2. **Table 2**: Expected `shocks_attendloo_b25_feb_3` but code writes `shocks_attendloo_b25_bootstrap_jul`. The `_feb_3` suffix was likely a specific version that was renamed.

3. **Table 5**: No producing code exists — the `.tex` file was manually created from external paper results. Mark as "manually created" in the tracking document.

4. **Tables A.5, A.6**: Tracking doc suffixes (`_short`, `_no_cols56`) don't exist in code. Either update tracking doc to match actual output or explain what these suffixes refer to.

5. **Table 8**: Title in tracking doc doesn't match code section header. Verify with authors whether "Employer Willingness to Pay for Workers with Habit Stock" is the intended paper title for the "Employers' job offer survey" section.

6. **Figure 9**: Line number should be 305, not 307.
