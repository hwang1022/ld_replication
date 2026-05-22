## Sensitivity analyses for the sharp-null-of-full-mediation test (Kwon-Roth)
##   1) Vary M and Y binary thresholds at consistent days/week rates
##   2) Multi-valued M (tertiles, and 3 fixed-cut bins) x binary Y

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
  library(TestMechs)
})

DATA <- "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/final/final_data_prioritize_date.dta"

raw <- read_dta(DATA)

worker <- raw %>%
  filter(dow == 2, phase %in% c(1, 2)) %>%
  group_by(pid, phase) %>%
  summarise(t = sum(attend_nadj, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(id_cols = pid, names_from = phase, values_from = t, names_prefix = "M_phase") %>%
  rename(M_total = M_phase1, Y_total = M_phase2) %>%
  left_join(raw %>% distinct(pid, treatment, strata, stand), by = "pid") %>%
  mutate(D = as.integer(treatment)) %>%
  as.data.frame()

cat(sprintf("N workers: %d  (%d treated, %d control)\n\n",
            nrow(worker), sum(worker$D==1), sum(worker$D==0)))

run_pack <- function(df) {
  out <- list()
  out$cs   <- tryCatch(test_sharp_null(df=df, d="D", m="M", y="Y", method="CS"),
                       error = function(e) list(error=conditionMessage(e)))
  out$arp  <- tryCatch(test_sharp_null(df=df, d="D", m="M", y="Y", method="ARP"),
                       error = function(e) list(error=conditionMessage(e)))
  out$toru <- tryCatch(test_sharp_null(df=df, d="D", m="M", y="Y", method="toru", B=500),
                       error = function(e) list(error=conditionMessage(e)))
  out$lb_at <- tryCatch(lb_frac_affected(df=df, d="D", m="M", y="Y", at_group=1),
                       error = function(e) NA_real_)
  out$lb_nt <- tryCatch(lb_frac_affected(df=df, d="D", m="M", y="Y", at_group=0),
                       error = function(e) NA_real_)
  out
}

fmt_row <- function(label, df, res) {
  ate_M <- mean(df$M[df$D==1]) - mean(df$M[df$D==0])
  ate_Y <- mean(df$Y[df$D==1]) - mean(df$Y[df$D==0])
  cs_p  <- res$cs$pval %||% NA_real_
  arp_r <- if (!is.null(res$arp$reject)) as.logical(res$arp$reject) else NA
  arp_e <- res$arp$eta %||% NA_real_
  toru_r <- if (!is.null(res$toru$reject)) as.logical(res$toru$reject) else NA
  cat(sprintf("%-40s | ATE_M=%+.2f  ATE_Y=%+.2f | CS p=%-6s | ARP rej=%-5s eta=%+6.2f | toru rej=%-5s | LB(AT)=%.3f LB(NT)=%.3f\n",
              label, ate_M, ate_Y,
              format(cs_p, digits=3),
              as.character(arp_r), arp_e,
              as.character(toru_r),
              res$lb_at, res$lb_nt))
}
`%||%` <- function(a, b) if (!is.null(a)) a else b

############################################################################
## Part 1: threshold sensitivity (binary M, binary Y at consistent rates) ##
############################################################################
cat("=========================================================================\n")
cat("PART 1: BINARY M, BINARY Y — vary threshold (days/week)\n")
cat("=========================================================================\n")
cat("M cutoff = rate * 7 weeks;  Y cutoff = rate * 8 weeks (Phase 2 has 8 wks)\n\n")
cat(sprintf("%-40s | %-22s | %-12s | %-26s | %-13s | %s\n",
            "spec", "ATEs", "CS test", "ARP test", "toru", "lower bounds"))
cat(strrep("-", 160), "\n", sep="")

for (rate in c(2, 3, 4, 5)) {
  df <- worker
  df$M <- as.integer(df$M_total >= rate * 7)
  df$Y <- as.integer(df$Y_total >= rate * 8)
  pM1 <- mean(df$M)
  pY1 <- mean(df$Y)
  label <- sprintf(">=%dd/wk  (M>=%d, Y>=%d)  P(M=1)=%.2f P(Y=1)=%.2f",
                   rate, rate*7, rate*8, pM1, pY1)
  res <- run_pack(df)
  fmt_row(label, df, res)
}

############################################################################
## Part 2: vary only Y threshold; hold M at 4 days/week                    ##
############################################################################
cat("\n=========================================================================\n")
cat("PART 2: HOLD M at >=4d/wk; vary only Y threshold\n")
cat("=========================================================================\n\n")
df_base <- worker
df_base$M <- as.integer(df_base$M_total >= 28)

for (rate in c(2, 3, 4, 5)) {
  df <- df_base
  df$Y <- as.integer(df$Y_total >= rate * 8)
  label <- sprintf("M>=4d/wk; Y>=%dd/wk  (Y>=%d)  P(Y=1)=%.2f",
                   rate, rate*8, mean(df$Y))
  res <- run_pack(df)
  fmt_row(label, df, res)
}

############################################################################
## Part 3: multi-valued M (3 levels), binary Y at >=4d/wk                  ##
############################################################################
cat("\n=========================================================================\n")
cat("PART 3: MULTI-VALUED M (3 levels), BINARY Y at >=4d/wk\n")
cat("=========================================================================\n\n")

run_mv <- function(label, df) {
  cells <- table(df$Y, df$M, df$D)
  cat(sprintf("\n--- %s ---\n", label))
  cat("M distribution by D:\n")
  print(table(M = df$M, D = df$D))
  cat(sprintf("min cell count: %d (across %d cells)\n",
              min(cells), length(cells)))
  cat(sprintf("ATE on Y (binary): %+.3f\n",
              mean(df$Y[df$D==1]) - mean(df$Y[df$D==0])))

  cs <- tryCatch(test_sharp_null(df=df, d="D", m="M", y="Y", method="CS"),
                 error = function(e) list(error=conditionMessage(e)))
  arp <- tryCatch(test_sharp_null(df=df, d="D", m="M", y="Y", method="ARP"),
                  error = function(e) list(error=conditionMessage(e)))
  lb <- tryCatch(lb_frac_affected(df=df, d="D", m="M", y="Y", at_group=NULL),
                 error = function(e) NA_real_)

  if (!is.null(cs$error)) cat("  CS error: ", cs$error, "\n")
  else cat(sprintf("  CS p-value:        %s   reject@5%%: %s\n",
                   format(cs$pval, digits=4),
                   as.character(cs$reject)))
  if (!is.null(arp$error)) cat("  ARP error: ", arp$error, "\n")
  else cat(sprintf("  ARP reject@5%%:    %s   eta=%+.3f\n",
                   as.character(as.logical(arp$reject)),
                   arp$eta %||% NA_real_))
  cat(sprintf("  LB(pooled fraction affected): %s\n", format(lb, digits=4)))
}

# Spec A: data-driven tertiles of phase 1 attendance
df <- worker
df$M <- as.integer(cut(df$M_total,
                       breaks = quantile(df$M_total, c(0, 1/3, 2/3, 1)),
                       include.lowest = TRUE, labels = FALSE)) - 1L
df$Y <- as.integer(df$Y_total >= 32)
run_mv("Tertiles of M (0=low, 1=mid, 2=high)", df)

# Spec B: fixed-cut bins at days/week
#   0 = "minimal" (<2/wk, M<14)
#   1 = "moderate" (2-4/wk, 14<=M<28)
#   2 = "regular" (>=4/wk, M>=28)
df <- worker
df$M <- with(df, ifelse(M_total < 14, 0L,
                ifelse(M_total < 28, 1L, 2L)))
df$Y <- as.integer(df$Y_total >= 32)
run_mv("Fixed cuts: <2 / 2-4 / >=4 days/week", df)

# Spec C: fixed cuts, with the SECOND cut at strict regularity (>=5/wk)
df <- worker
df$M <- with(df, ifelse(M_total < 14, 0L,
                ifelse(M_total < 35, 1L, 2L)))
df$Y <- as.integer(df$Y_total >= 32)
run_mv("Fixed cuts: <2 / 2-5 / >=5 days/week", df)

cat("\nDone.\n")
