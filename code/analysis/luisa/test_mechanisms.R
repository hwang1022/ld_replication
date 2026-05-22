## Testing the sharp null of full mediation (Kwon & Roth 2026)
##   D = treatment (individual-level, randomized within stand x strata)
##   M = Phase 1 total attendance >= 28 days (>= 4 days/week avg over 7 weeks)
##   Y = Phase 2 total attendance >= 32 days (>= 4 days/week avg over 8 weeks)
## Sample: 225 workers; D, M, Y all binary.

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(TestMechs)
})

set.seed(20260508)

DATA <- "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/final/final_data_prioritize_date.dta"
OUT  <- "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/code/analysis/luisa"

raw <- read_dta(DATA)

## --- Build worker-level (PID) data --------------------------------------
weekly <- raw %>%
  filter(dow == 2, phase %in% c(1, 2)) %>%
  select(pid, phase, attend_nadj, treatment, strata, stand)

worker <- weekly %>%
  group_by(pid, phase) %>%
  summarise(attend_total = sum(attend_nadj, na.rm = TRUE),
            n_weeks = sum(!is.na(attend_nadj)),
            .groups = "drop") %>%
  pivot_wider(id_cols = pid,
              names_from  = phase,
              values_from = c(attend_total, n_weeks)) %>%
  rename(M_total = attend_total_1, Y_total = attend_total_2,
         n_p1 = n_weeks_1, n_p2 = n_weeks_2) %>%
  left_join(weekly %>% distinct(pid, treatment, strata, stand), by = "pid")

cat("N workers:", nrow(worker), "  treated:", sum(worker$treatment == 1),
    "  control:", sum(worker$treatment == 0), "\n\n")

## --- Define binary M and Y at fixed, economically-meaningful cutoffs ----
##   "Worked >= 4 days/week on average" in each phase
M_CUT <- 28   # 4 * 7 weeks
Y_CUT <- 32   # 4 * 8 weeks

worker <- worker %>%
  mutate(D = as.integer(treatment),
         M = as.integer(M_total >= M_CUT),
         Y = as.integer(Y_total >= Y_CUT))

cat("--- Marginal distributions ---\n")
cat(sprintf("P(M=1) = %.3f   P(M=1|D=1) = %.3f   P(M=1|D=0) = %.3f\n",
            mean(worker$M),
            mean(worker$M[worker$D == 1]),
            mean(worker$M[worker$D == 0])))
cat(sprintf("P(Y=1) = %.3f   P(Y=1|D=1) = %.3f   P(Y=1|D=0) = %.3f\n",
            mean(worker$Y),
            mean(worker$Y[worker$D == 1]),
            mean(worker$Y[worker$D == 0])))

cat("\n--- 2x2x2 cell counts (Y x M x D) ---\n")
print(xtabs(~ Y + M + D, data = worker))

## --- Implied compliance shares under monotonicity (binary M) ------------
p1 <- mean(worker$M[worker$D == 1])
p0 <- mean(worker$M[worker$D == 0])
N  <- nrow(worker)
cat("\n--- Compliance breakdown under monotonicity (M(1) >= M(0)) ---\n")
cat(sprintf("  Always-takers (M=1 in both): %.1f%%  (%d workers)\n", p0*100, round(p0*N)))
cat(sprintf("  Never-takers  (M=0 in both): %.1f%%  (%d workers)\n", (1-p1)*100, round((1-p1)*N)))
cat(sprintf("  Compliers     (M: 0 -> 1):   %.1f%%  (%d workers)\n", (p1-p0)*100, round((p1-p0)*N)))

## --- Treatment effects on M and Y ---------------------------------------
ate_M <- mean(worker$M[worker$D==1]) - mean(worker$M[worker$D==0])
ate_Y <- mean(worker$Y[worker$D==1]) - mean(worker$Y[worker$D==0])
cat(sprintf("\nATE on M (binary): %+.3f\nATE on Y (binary): %+.3f\n", ate_M, ate_Y))

## --- Visual: testable implications --------------------------------------
##   Under sharp null + monotonicity:
##     P(Y=y, M=0 | D=0) >= P(Y=y, M=0 | D=1) for all y
pdens <- partial_density_plot(
  df = as.data.frame(worker),
  d  = "D", m  = "M", y  = "Y",
  num_Ybins = NULL,
  density_0_label = "Control: P(Y, M=0 | D=0)",
  density_1_label = "Treated: P(Y, M=0 | D=1)"
)
ggsave(file.path(OUT, "tm_partial_density.png"), pdens, width = 6, height = 4, dpi = 150)
cat("Saved partial-density plot.\n")

## --- Tests of the sharp null --------------------------------------------
run_test <- function(label, ...) {
  cat(sprintf("\n>>> %s\n", label))
  res <- tryCatch(test_sharp_null(...), error = function(e) e)
  if (inherits(res, "error")) { cat("  ERROR:", conditionMessage(res), "\n"); return(invisible(NULL)) }
  # Different methods return different fields:
  pv  <- res$pval
  rej <- res$reject
  eta <- res$eta
  if (!is.null(pv))  cat(sprintf("  p-value: %s\n", format(pv, digits = 4)))
  if (!is.null(rej)) cat(sprintf("  reject (alpha=0.05): %s\n", as.logical(rej)))
  if (!is.null(eta)) cat(sprintf("  test statistic eta: %.3f (negative => no violation)\n", eta))
  invisible(res)
}

df <- as.data.frame(worker)

# Headline test: CS (Cox-Shi 2022), no covariates
res_cs <- run_test("CS test, no controls",
                   df = df, d = "D", m = "M", y = "Y", method = "CS")

# CS with strata fixed effects (randomization was stratified)
res_cs_strata <- run_test("CS test, strata FEs",
                          df = df, d = "D", m = "M", y = "Y", method = "CS",
                          reg_formula = "~ D + factor(strata)")

# Kitagawa (toru) — classic IV-validity test for binary M
res_k <- run_test("Kitagawa (toru) test",
                  df = df, d = "D", m = "M", y = "Y", method = "toru", B = 500)

# ARP — better with small/clustered samples
res_arp <- run_test("ARP test",
                    df = df, d = "D", m = "M", y = "Y", method = "ARP")

## --- Lower bounds on fraction affected ----------------------------------
cat("\n--- Lower bounds on fraction of always-takers / never-takers affected ---\n")
lb_at <- lb_frac_affected(df = df, d = "D", m = "M", y = "Y", at_group = 1)
lb_nt <- lb_frac_affected(df = df, d = "D", m = "M", y = "Y", at_group = 0)
lb_pool <- lb_frac_affected(df = df, d = "D", m = "M", y = "Y", at_group = NULL)
cat(sprintf("  Always-takers (M=1 always): nu_1 >= %s\n", format(lb_at,   digits = 4)))
cat(sprintf("  Never-takers  (M=0 always): nu_0 >= %s\n", format(lb_nt,   digits = 4)))
cat(sprintf("  Pooled:                     nu   >= %s\n", format(lb_pool, digits = 4)))

## --- Robustness: allow defiers ------------------------------------------
cat("\n--- Robustness: lower bound on nu_0 (never-takers) under defier shares ---\n")
for (d_share in c(0, 0.05, 0.10, 0.15)) {
  lb <- lb_frac_affected(df = df, d = "D", m = "M", y = "Y", at_group = 0,
                         max_defiers_share = d_share)
  cat(sprintf("  max_defiers_share = %.2f  ->  lb = %s\n", d_share, format(lb, digits = 4)))
}

cat("\nDone.\n")
