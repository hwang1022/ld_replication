# README — Building `job_at_stand` (found-at-stand vs. not), incl. the multiday-job dummy

**Author:** Claude · **Date:** 2026-05-29
**Prototype code:** `code/analysis/luisa/diag_make_job_at_stand.do`
**Input:** `$temp/05_phase1_phase2_makepanel.dta` (worker × day, phases 1 & 2)
**Destination (eventually):** the CORE BLOCK is meant to be pasted into `code/1_5_phase_1_2/5_phase1_2_makevar.do`.

This document walks through **every decision**, in the order I made them, so you can audit or change any link in the chain.

---

## 0. The goal

Create a worker-day dummy: **was the day's employment found _at the stand_ (`job_at_stand = 1`) or _not_ (`= 0`)?**

The hard part is **multiday jobs**: on most days of a multiday job the worker just answers "multi-day job, same employer," which hides whether the job _originally_ came from the stand or from outside. So a big part of the job is reconstructing multiday spells and recovering the original source.

---

## 1. Finding the raw ingredients

The source information lives in three survey variables (all present in the makepanel file):

| Variable | Asked of | Value label (key codes) |
|---|---|---|
| `whenfound` (`rd3`) | days with a stand recall | **1** = already had job before coming to stand (→ outside) · **2** = while at the stand (→ **STAND**) · **3** = after leaving stand without finding work (→ outside) |
| `howfound` (`rd4`) | attend days | the _channel_ (phone / self-employed / multi-day / stand-recruiter / …) |
| `howfound_notattend` (`rd6`) | non-attend days | phone / self-employed / multi-day — **no stand option exists** |

plus `multiday_job` (0/1), `work` (worked that day), and `daily_recall_lag` (which day of the 7-day recall grid filled this row).

**Decision 1 — Use `whenfound` as the primary signal.** `whenfound` _directly_ answers "stand vs. outside," whereas `howfound` only gives the channel. As section 2 explains, `howfound` is also contaminated by a coding problem, so I lean on `whenfound`.

---

## 2. Two complications I discovered (and how they shaped the design)

### 2a. `howfound` secretly mixes **two different coding schemes**
The combined `howfound` is filled from the original question (`rf4_1`) when available, otherwise from a revised question (`rf4_v2_1`). **The two questionnaires number the answers differently:**

| Code | Original `rf4_1` | Revised `rf4_v2_1` |
|---|---|---|
| 5 | **Multi-day job** | Phone – friend/family (→ outside) |
| 6 | Stand – recruiter | Phone – called friend (→ outside) |
| 7 | Stand – friend/family | Self-employed |
| 8 | Stand – recruiter offered | Stand – recruiter |
| 9, 10, 11 | _(don't exist)_ | Stand – various |

So **codes 5/6/7 are ambiguous** in the combined variable, and "multi-day" (code 5 in the original) collides with "phone-friend" (code 5 in the revised). 

**Decision 2 — Don't classify off the ambiguous `howfound` codes.** Because `whenfound` is co-present on essentially every attend-day record (8,419 of 8,420), and `howfound_notattend` has _no stand option at all_, I almost never need `howfound`. I only fall back to it for the ~1 stray day where `whenfound` is missing, and there I use the **union** of stand codes `{6,7,8,9,10,11}`. The ambiguous "multi-day vs phone-friend" code 5 is deliberately left unused for classification.

### 2b. There is **no** multiday duration / sequence / start variable
I searched the raw cleaned files — nothing records how long a multiday job lasts or when it began. (This matches your warning.)

**Decision 3 — Reconstruct multiday spells from the daily panel** (section 4), since we can't read them off a variable.

---

## 3. The four design choices (your calls, 2026-05-29)

I asked, you answered:

| # | Question | Your decision |
|---|---|---|
| A | Primary classifier for normal days | **Combine** `whenfound` + `howfound_notattend` (+ `howfound` fallback) |
| B | Final categories | **Stand vs. NOT-stand** (1/0). "Not-stand" bundles outside, phone, self-employed, and "other". |
| C | Multiday spell definition | **Consecutive run** of multiday work days (revisit alternatives later) |
| D | Which day's source to propagate | **Nearest prior clean source**, started **conservative** = the work day immediately before the spell |

These map one-to-one onto the four code steps below.

---

## 4. Step-by-step coding logic

The do-file's **CORE BLOCK** has four numbered sections matching this.

### Step 1 — `clean_stand`: the directly-observed source on **non-multiday** work days
Build a 1/0 (stand / not-stand) only where the source is unambiguous:
1. `whenfound == 2` → **1 (stand)**; `whenfound` ∈ {1,3} → **0 (not-stand)**.
2. else if `howfound_notattend` is non-missing and ≠ 5 (multi-day) → **0** (non-attend days can't be "at stand").
3. else (rare) use `howfound`: stand codes {6,7,8,9,10,11} → **1**; {1,2,3,4,998} → **0**.

Then keep `clean_stand` only on **work days that are not flagged multiday** — that is what "clean" means: a day whose source we trust at face value.
*Result: 7,540 of 7,567 non-multiday work days get a clean value (75% stand).*

### Step 2 — Reconstruct multiday **spells**
- A "multiday work day" = `work==1 & multiday_job==1`.
- Order each worker's **work days** by date and mark a **new spell** whenever a multiday work day follows a day that was _not_ a multiday work day.
- Non-work days (Sundays, holidays, days off) are simply skipped, so they **don't split** a job that continues across them. A genuine non-multiday work day in between **does** start a new spell (it's a different job).
- `spell_id` numbers the spells within each worker.
*Result: 973 spells; median length 2 days, mean 3.4, max 25.*

### Step 3 — Conservative **attribution**
For each spell, look at the **work day immediately before it** and take that day's `clean_stand`. That preceding day is the "job-finding" day — it captures the case where _the worker only learns at the end of day 1 that the job is multiday_, so day 1 still carries a real stand/outside answer.
- "Conservative" = a **1 work-day lookback** only. We do **not** reach further back (which would risk borrowing the source from a different, earlier job). Widening this is the first knob to turn later.

### Step 4 — Assemble `job_at_stand`
- Non-multiday day → its own `clean_stand`.
- Multiday day → the attributed value from its spell's preceding work day (if any).
- Restrict to the **7-day daily recall grid** (`daily_recall_lag` non-missing); comprehensive-recall days carry no day-level source and stay missing.
- Also output `job_at_stand_method` (1 = directly observed, 2 = attributed) and keep `spell_id`, both for auditing.

---

## 5. What you get (coverage)

Among all 11,118 work days:

| | Days | % |
|---|---|---|
| Found at stand (1) | 7,205 | 64.8% |
| Not at stand (0) | 3,251 | 29.2% |
| **Unlabeled (.)** | **662** | **6.0%** |

- ≈ **94% labeled** overall; **≈ 96% within the 7-day grid**.
- 72% of labels are directly observed, 28% come from multiday attribution.
- The unlabeled 6% breaks down as: 56% multiday jobs whose origin is never observed (irreducible under the conservative rule), 40% comprehensive-recall days (no day detail), 4% non-multiday days with no recorded source.

---

## 6. Known limitations / things to revisit
1. **Conservative lookback (1 work day)** leaves 371 multiday days unlabeled because their spell starts with no clean preceding day. Widening the lookback recovers more (up to ~96% at unlimited) at some accuracy cost — not yet validated (flip-rate check pending).
2. **Spell definition** is "consecutive multiday work days." Alternatives (allow short gaps; treat any contiguous work run as one spell) are open per your note.
3. **`howfound` ambiguity** is sidestepped, not solved; if you ever want to classify directly off `howfound`, you must first recover v1-vs-v2 provenance.
4. **"Not-stand" is a bundle** (outside + phone + self-employed + other). If you later want self-employed separated, switch the scheme in Step 1.

---

## 7. How to fold this into the pipeline
Paste **Sections 1–4 (the CORE BLOCK)** from `diag_make_job_at_stand.do` into `5_phase1_2_makevar.do`, **right after the panel is loaded and before any row-dropping restrictions** (the consecutive-day logic needs the full daily panel). The validation block at the bottom of the prototype can be deleted. (I can only write inside `code/analysis/luisa/`, so the actual paste into the pipeline file is yours to make.)
