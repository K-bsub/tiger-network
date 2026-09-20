# =============================================================================
# 04_growth_metrics.R  [GROWTH - priority 1]
# Derive per-reserve growth metrics from the Week-5 stats layer and write the
# priority-1 growth table. This script DERIVES metrics; it does not assemble the
# layer (that is scripts/03) and does not draw visuals or roll up to region
# (that is scripts/05, Week 7).
#
# Pipeline position:
#   scripts/03  assemble  -> stats_reserve_census_7755.gpkg (pop_*, area, density,
#                            baseline_year, census_status)   [Week 5, done]
#   scripts/04  derive    -> change_abs / change_pct / aagr + tbl_01   [THIS FILE]
#   scripts/05  visualise -> fig_01 ranking, fig_02 animation, tbl_02 roll-up [Week 7]
#
# Governing Decisions (docs/methodology.md):
#   Decision 6  series is within-reserve SECR 2014/2018/2022 only.
#   Decision 7  missing (reserve, round) = NA; no carry-forward/interpolation.
#               Growth is over each reserve's OWN baseline_year -> 2022 span.
#   Decision 9  real within-reserve zeros:
#               - change_abs always valid (a subtraction is defined at 0).
#               - zero baseline (pop_baseline == 0, e.g. Mukundara 0->1->1):
#                   change_pct/aagr = NA, growth_zero_flag = TRUE (ratio undefined).
#               - zero 2022 endpoint (pop_2022 == 0, pop_baseline > 0, real decline
#                   e.g. Kamlang/Sahyadri/Dampa/Satkosia/Kawal): change_pct = -100
#                   and aagr = -100%/yr, computed and reported as-is, NOT flagged.
#               - never Inf/NaN.
#
# Metric definitions (per reserve; pop_baseline = pop in that reserve's
# baseline_year, from the Week-5 layer):
#   change_abs = pop_2022 - pop_baseline
#   change_pct = change_abs / pop_baseline * 100
#   aagr       = (pop_2022 / pop_baseline)^(1 / (2022 - baseline_year)) - 1  (as %)
# NA (not error/Inf) where: only one round (2022-only), pop_2022 is NA
#   (Sundarbans + the 5 flagged), or - for the ratio metrics only - the baseline
#   pop is 0 (Decision 9).
#
# BUILT IN STAGES (project plan, Week 6):
#   [6.1] location chosen + header/structure.                        [done]
#   [6.2] change_abs (NA where < 2 rounds or endpoint missing).       [done]
#   [6.5 + Decision 9] real-within-reserve-zero rule.                 [done]
#   [6.3] change_pct + growth_zero_flag (NA where baseline 0).        [done]
#   [6.4] aagr (same zero-baseline + single-round guards; no Inf/NaN). [done]
#   [6.6] write outputs/tables/tbl_01_reserve_growth.csv.            [done]
#   [6.7] verify: no Inf/NaN; NA pattern matches Decisions 7/9; spot-checks. [done]
#   [6.8] append change_abs/change_pct/aagr/growth_zero_flag to
#         stats_reserve_census_7755.gpkg; update docs/data-dictionary.md. [done]
#
# Inputs:
#   data/processed/stats_reserve_census_7755.gpkg   (scripts/03, Week 5)
# Outputs:
#   outputs/tables/tbl_01_reserve_growth.csv        (6.6)
#   data/processed/stats_reserve_census_7755.gpkg   (6.8, four columns appended)
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(sf)
  library(dplyr)
})

source(here("R", "00_config.R"))        # CENSUS_SERIES_YEARS, DIR_*, CURRENT_YEAR
source(here("R", "00_functions_io.R"))  # read_vec, write_processed_vec, write_table

rule <- function(txt) cat("\n", strrep("=", 78), "\n", txt, "\n",
                          strrep("=", 78), "\n", sep = "")

# ---- Series / span constants ------------------------------------------------
# The growth endpoint is 2022 (series end, Decision 6). Read it from config so a
# future series edit does not leave a hardcoded year behind.
SERIES_YEARS <- CENSUS_SERIES_YEARS
END_YEAR     <- max(SERIES_YEARS)

if (!setequal(SERIES_YEARS, c(2014L, 2018L, 2022L))) {
  stop("R/00_config.R CENSUS_SERIES_YEARS = {", paste(SERIES_YEARS, collapse = ", "),
       "} does not match the Decision-6 series 2014/2018/2022. Fix the config.",
       call. = FALSE)
}

# ---- Paths ------------------------------------------------------------------
stats_path <- file.path(DIR_PROCESSED, "stats_reserve_census_7755.gpkg")
stopifnot(file.exists(stats_path))

growth_tbl_nn   <- 1L                    # tbl_01 (output counter is independent
growth_tbl_slug <- "reserve_growth"      # of the script prefix; naming-conv Sec 6)

# ==============================================================================
# STEP 1 - Read the Week-5 stats layer and guard its schema
# ==============================================================================
rule("STEP 1 - read stats_reserve_census_7755.gpkg (Week-5 deliverable)")

# read_vec() reprojects to CRS_ANALYSIS (7755). The layer holds all 58 reserves
# with pop_2014/2018/2022, baseline_year, and census_status already set.
stats_sf <- read_vec(stats_path)

cat("reserves read:", nrow(stats_sf), "\n")

# Guard the inputs this script depends on BEFORE deriving anything.
if (nrow(stats_sf) != 58L) {
  stop("stats layer has ", nrow(stats_sf), " reserves; expected 58. ",
       "Check scripts/03 output.", call. = FALSE)
}
if (any(duplicated(stats_sf$unit_id))) {
  stop("Duplicate unit_id in the stats layer.", call. = FALSE)
}
pop_cols <- paste0("pop_", SERIES_YEARS)          # pop_2014, pop_2018, pop_2022
req_cols <- c("unit_id", "unit_name", "baseline_year", "census_status", pop_cols)
missing_req <- setdiff(req_cols, names(stats_sf))
if (length(missing_req) > 0) {
  stop("stats layer missing required column(s): ",
       paste(missing_req, collapse = ", "), call. = FALSE)
}
# This script CREATES the growth columns; they must not already exist. A re-run
# on an already-appended layer must start from a clean scripts/03 rebuild, so the
# 6.8 write cannot double-append or diverge from tbl_01.
already <- intersect(c("change_abs", "change_pct", "aagr", "growth_zero_flag"),
                     names(stats_sf))
if (length(already) > 0) {
  stop("Growth column(s) already on the layer: ", paste(already, collapse = ", "),
       ". Re-run scripts/03 to rebuild the Week-5 layer before deriving metrics.",
       call. = FALSE)
}

# ==============================================================================
# STEP 2 (6.5) - Decision 9: real within-reserve zeros
# ==============================================================================
rule("STEP 2 (6.5) - Decision 9 guards: zero baseline -> NA change_pct/aagr")

# Decision 9 (docs/methodology.md) governs the ratio metrics below. It does NOT
# affect change_abs (a subtraction is always valid). It fixes:
#   - baseline pop == 0 (Mukundara Hills, unit_id 42: 0 -> 1 -> 1):
#       change_abs valid (+1); change_pct and aagr = NA + growth_zero_flag TRUE.
#   - pop_2022 == 0 real declines (Kamlang, Sahyadri, Dampa, Satkosia, Kawal):
#       change_pct = -100 and aagr = -100%/yr, computed as-is, NOT flagged.
# STEP 3 (change_abs) is unaffected; STEPs 4-5 implement the ratio guards.

# ==============================================================================
# STEP 3 (6.2) - change_abs = pop_2022 - pop_baseline
# ==============================================================================
rule("STEP 3 (6.2) - change_abs = pop_2022 - pop_baseline")

# pop_baseline = the pop in each reserve's OWN baseline_year (Decision 7: the
# earliest round with a figure - 2014 for the core, 2018/2022 for late entries).
# It is read by selecting the pop_<baseline_year> column per row, NOT assumed to
# be pop_2014.
#
# NA rule (satisfies the 6.2 done-when: "NA exactly where < 2 rounds or endpoint
# missing"). change_abs is non-NA ONLY where a reserve has a real 2-point span:
#   (a) baseline_year is present AND strictly before END_YEAR (>= 2 rounds), AND
#   (b) both pop_baseline and pop_2022 are non-NA.
# Why the span guard (a) is needed and not just (b): a 2022-only reserve has
# baseline_year == 2022, so pop_baseline == pop_2022 and the subtraction would be
# a fabricated 0 ("no change") instead of NA. Guarding on span makes it NA.
#
# This yields NA for exactly:
#   - the 5 flagged reserves        (baseline_year NA)
#   - Sundarbans (unit_id 57)       (pop_2022 NA)
#   - the single-round 2022-only reserves (span 0)
# and a VALID (non-NA) value for the real zeros, which are not missing data:
#   - Mukundara (42): 2014=0 -> 2022=1  => change_abs = +1
#   - 2022-zero declines (e.g. Kamlang): baseline -> 0 => change_abs negative

st <- st_drop_geometry(stats_sf)

# pop_baseline per reserve: pick pop_<baseline_year>, NA where baseline_year is NA.
pop_baseline <- vapply(seq_len(nrow(st)), function(i) {
  by <- st$baseline_year[i]
  if (is.na(by)) return(NA_real_)
  col <- paste0("pop_", by)
  if (!col %in% names(st)) return(NA_real_)   # baseline outside the series (guarded above)
  as.numeric(st[[col]][i])
}, numeric(1))

has_span <- !is.na(st$baseline_year) & st$baseline_year < END_YEAR
valid_ab <- has_span & !is.na(pop_baseline) & !is.na(st$pop_2022)

change_abs <- ifelse(valid_ab, st$pop_2022 - pop_baseline, NA_real_)

# Attach to both the sf object (for 6.8) and a working table (for QA / tbl_01).
stats_sf$change_abs <- change_abs
st$pop_baseline     <- pop_baseline   # carried into tbl_01 (6.6) and QA prints
st$change_abs       <- change_abs

# --- 3a. Verify change_abs NA-pattern (task 6.2 done-when) --------------------
rule("STEP 3a (6.2) - verify change_abs: NA exactly where < 2 rounds or endpoint missing")

n_valid <- sum(!is.na(st$change_abs))
n_na    <- sum(is.na(st$change_abs))
cat(sprintf("change_abs: non-NA %d | NA %d (of 58)\n", n_valid, n_na))

# Expected NA set, derived independently of the computed column, then compared.
exp_na <- is.na(st$baseline_year) |            # 5 flagged
          (st$baseline_year >= END_YEAR) |     # 2022-only single-round
          is.na(pop_baseline) |                # (defensive; covered by baseline NA)
          is.na(st$pop_2022)                   # Sundarbans within-blank
got_na <- is.na(st$change_abs)
if (!identical(exp_na, got_na)) {
  disagree <- st$unit_id[exp_na != got_na]
  stop("change_abs NA-pattern does not match the < 2 rounds / endpoint-missing ",
       "rule for unit_id(s): ", paste(sort(disagree), collapse = ", "), call. = FALSE)
}
cat("change_abs NA-pattern matches the done-when rule: OK\n")

# Break the NA set down so it is auditable (expect: 5 flagged + Sundarbans + 2022-only).
na_flagged  <- sum(is.na(st$change_abs) & st$census_status == "not_estimated_post2022_notification")
na_sundar   <- sum(is.na(st$change_abs) & st$census_status == "measured" & is.na(st$pop_2022))
na_oneround <- sum(is.na(st$change_abs) & st$census_status == "measured" &
                   !is.na(st$pop_2022) & st$baseline_year >= END_YEAR)
cat(sprintf("NA breakdown: flagged %d | Sundarbans-type (2022 NA) %d | 2022-only %d | total %d\n",
            na_flagged, na_sundar, na_oneround, na_flagged + na_sundar + na_oneround))

# --- 3b. Real within-reserve zeros must stay VALID (not NA) -------------------
# Decision 7/9: a 0 is a real figure, not missing. A reserve whose baseline or
# 2022 pop is a real 0 (and which has a 2-round span) must have a non-NA change_abs.
zero_endpoint <- has_span &
                 ((!is.na(pop_baseline) & pop_baseline == 0) |
                  (!is.na(st$pop_2022)  & st$pop_2022  == 0))
if (any(zero_endpoint)) {
  bad_zero <- st$unit_id[zero_endpoint & is.na(st$change_abs)]
  if (length(bad_zero) > 0) {
    stop("Real within-reserve zero(s) wrongly gave NA change_abs for unit_id(s): ",
         paste(sort(bad_zero), collapse = ", "),
         " (a 0 is a real figure, not missing - Decision 7/9).", call. = FALSE)
  }
  cat(sprintf("real within-reserve zeros kept a valid change_abs: %d reserve(s) OK\n",
              sum(zero_endpoint)))
}

# --- 3c. Spot the extremes so the sign/scale is eyeballable ------------------
cat("\ntop 5 change_abs (largest increase):\n")
st |> filter(!is.na(change_abs)) |> arrange(desc(change_abs)) |> slice_head(n = 5) |>
  mutate(l = sprintf("   #%d %-22s %d(base %s) -> %s  = %+d",
                     unit_id, unit_name, baseline_year,
                     ifelse(is.na(pop_baseline), "NA", as.character(pop_baseline)),
                     ifelse(is.na(pop_2022), "NA", as.character(pop_2022)),
                     as.integer(change_abs))) |>
  pull(l) |> cat(sep = "\n")
cat("\nbottom 5 change_abs (largest decline):\n")
st |> filter(!is.na(change_abs)) |> arrange(change_abs) |> slice_head(n = 5) |>
  mutate(l = sprintf("   #%d %-22s %d(base %s) -> %s  = %+d",
                     unit_id, unit_name, baseline_year,
                     ifelse(is.na(pop_baseline), "NA", as.character(pop_baseline)),
                     ifelse(is.na(pop_2022), "NA", as.character(pop_2022)),
                     as.integer(change_abs))) |>
  pull(l) |> cat(sep = "\n")
cat("\n")

rule("04 STAGE 6.2 done: change_abs populated; NA exactly where < 2 rounds or endpoint missing.")

# ==============================================================================
# STEP 4 (6.3) - change_pct + growth_zero_flag
# ==============================================================================
rule("STEP 4 (6.3) - change_pct = change_abs / pop_baseline * 100 (Decision 9)")

# growth_zero_flag (Decision 9): TRUE iff a reserve has a real 2-round span AND
# its baseline pop is 0 - the case where the RATIO metrics (change_pct, aagr) are
# undefined and stored NA. It is a clean logical for all 58 rows:
#   - TRUE  : span present AND pop_baseline == 0   (currently Mukundara only)
#   - FALSE : everything else, INCLUDING span-less reserves (their NA is
#             span-driven, not zero-driven) and real 2022-zero declines (their
#             ratio metrics are a real -100, not NA).
# This is what separates a ratio-undefined NA from a missing-data NA downstream.
growth_zero_flag <- has_span & !is.na(pop_baseline) & pop_baseline == 0

# change_pct: defined wherever change_abs is defined AND the baseline is not 0.
#   - baseline 0 (flagged)      -> NA (ratio undefined; Decision 9)
#   - real 2022 zero, base > 0  -> -100 (a real total decline; computed, kept)
#   - otherwise                 -> change_abs / pop_baseline * 100
# Guarding on !growth_zero_flag (rather than pop_baseline != 0) also protects the
# span-less rows, where pop_baseline may be non-NA but change_abs is already NA.
change_pct <- ifelse(
  !is.na(change_abs) & !growth_zero_flag,
  round(change_abs / pop_baseline * 100, 1),
  NA_real_
)

stats_sf$change_pct       <- change_pct
stats_sf$growth_zero_flag <- growth_zero_flag
st$change_pct       <- change_pct
st$growth_zero_flag <- growth_zero_flag

# --- 4a. Verify change_pct NA-pattern and the flag (task 6.3 done-when) -------
rule("STEP 4a (6.3) - verify change_pct: NA for single-round + zero-baseline; flag correct")

n_pct_valid <- sum(!is.na(st$change_pct))
n_pct_na    <- sum(is.na(st$change_pct))
n_flag      <- sum(st$growth_zero_flag)
cat(sprintf("change_pct: non-NA %d | NA %d (of 58) | growth_zero_flag TRUE: %d\n",
            n_pct_valid, n_pct_na, n_flag))

# Expected change_pct NA = (change_abs NA) UNION (zero-baseline flagged), built
# independently and compared.
exp_pct_na <- is.na(st$change_abs) | st$growth_zero_flag
got_pct_na <- is.na(st$change_pct)
if (!identical(exp_pct_na, got_pct_na)) {
  disagree <- st$unit_id[exp_pct_na != got_pct_na]
  stop("change_pct NA-pattern wrong for unit_id(s): ",
       paste(sort(disagree), collapse = ", "),
       " (expected NA iff change_abs is NA or baseline is 0).", call. = FALSE)
}
cat("change_pct NA-pattern matches Decision 7 + Decision 9: OK\n")

# The flag must never be NA and must be TRUE only on a real span with baseline 0.
if (any(is.na(st$growth_zero_flag))) {
  stop("growth_zero_flag has NA value(s); it must be a clean TRUE/FALSE for all 58.",
       call. = FALSE)
}
flag_bad <- st$unit_id[st$growth_zero_flag &
                       !(has_span & !is.na(pop_baseline) & pop_baseline == 0)]
if (length(flag_bad) > 0) {
  stop("growth_zero_flag TRUE on reserve(s) without a real zero-baseline span: ",
       paste(sort(flag_bad), collapse = ", "), call. = FALSE)
}
# Report the flagged reserves explicitly (expect: Mukundara only).
if (n_flag > 0) {
  cat("growth_zero_flag TRUE (baseline 0; change_pct/aagr = NA):\n")
  st |> filter(growth_zero_flag) |>
    mutate(l = sprintf("   #%d %-22s baseline_year=%d pop_base=0 -> pop_2022=%s (change_abs=%+d)",
                       unit_id, unit_name, baseline_year,
                       ifelse(is.na(pop_2022), "NA", as.character(pop_2022)),
                       as.integer(change_abs))) |>
    pull(l) |> cat(sep = "\n")
  cat("\n")
}

# --- 4b. Real 2022-zero declines must be -100 (valid), NOT NA, NOT flagged ----
# Decision 9: pop_2022 == 0 with pop_baseline > 0 is a real total decline.
decline_zero <- has_span & !is.na(pop_baseline) & pop_baseline > 0 &
                !is.na(st$pop_2022) & st$pop_2022 == 0
if (any(decline_zero)) {
  bad_decl <- st$unit_id[decline_zero & (is.na(st$change_pct) |
                                         round(st$change_pct, 1) != -100 |
                                         st$growth_zero_flag)]
  if (length(bad_decl) > 0) {
    stop("Real 2022-zero decline(s) not handled per Decision 9 for unit_id(s): ",
         paste(sort(bad_decl), collapse = ", "),
         " (expected change_pct = -100, not flagged).", call. = FALSE)
  }
  cat(sprintf("real 2022-zero declines -> change_pct = -100 (valid, unflagged): %d OK\n",
              sum(decline_zero)))
  st |> filter(decline_zero) |>
    mutate(l = sprintf("   #%d %-22s %d(base %s) -> 0  change_pct=%.0f",
                       unit_id, unit_name, baseline_year,
                       as.character(pop_baseline), change_pct)) |>
    pull(l) |> cat(sep = "\n")
  cat("\n")
}

# --- 4c. No Inf/NaN in change_pct (Decision 9 hard requirement) ---------------
if (any(is.infinite(st$change_pct) | is.nan(st$change_pct), na.rm = TRUE)) {
  bad_if <- st$unit_id[is.infinite(st$change_pct) | is.nan(st$change_pct)]
  stop("change_pct contains Inf/NaN for unit_id(s): ",
       paste(sort(bad_if), collapse = ", "), " (Decision 9 forbids it).",
       call. = FALSE)
}
cat("change_pct contains no Inf/NaN: OK\n")

# --- 4d. Spot the extremes ---------------------------------------------------
cat("\ntop 5 change_pct (largest % growth):\n")
st |> filter(!is.na(change_pct)) |> arrange(desc(change_pct)) |> slice_head(n = 5) |>
  mutate(l = sprintf("   #%d %-22s %d(base %s) -> %s  = %+.1f%%",
                     unit_id, unit_name, baseline_year,
                     as.character(pop_baseline),
                     ifelse(is.na(pop_2022), "NA", as.character(pop_2022)),
                     change_pct)) |>
  pull(l) |> cat(sep = "\n")
cat("\nbottom 5 change_pct (largest % decline):\n")
st |> filter(!is.na(change_pct)) |> arrange(change_pct) |> slice_head(n = 5) |>
  mutate(l = sprintf("   #%d %-22s %d(base %s) -> %s  = %+.1f%%",
                     unit_id, unit_name, baseline_year,
                     as.character(pop_baseline),
                     ifelse(is.na(pop_2022), "NA", as.character(pop_2022)),
                     change_pct)) |>
  pull(l) |> cat(sep = "\n")
cat("\n")

rule("04 STAGE 6.3 done: change_pct populated; growth_zero_flag set; no Inf/NaN.")

# ==============================================================================
# STEP 5 (6.4) - aagr = (pop_2022 / pop_baseline)^(1 / span) - 1, as a percent
# ==============================================================================
rule("STEP 5 (6.4) - aagr over each reserve's own baseline_year -> 2022 span (Decision 9)")

# span = END_YEAR - baseline_year, each reserve's OWN observed gap:
#   2014 baseline -> 8 years; 2018 baseline -> 4 years. Single-round (2022-only)
#   reserves have span 0, but they are already NA in change_abs and are excluded
#   by the same !is.na(change_abs) guard below, so 1/span is never evaluated for
#   them (no divide-by-zero in the exponent).
#
# NA / value rule (Decision 9), identical NA set to change_pct:
#   - change_abs NA (single-round, missing endpoint) -> aagr NA
#   - zero baseline (growth_zero_flag)               -> aagr NA (ratio undefined)
#   - real 2022 zero, base > 0: (0/base)^(1/span) - 1 = 0 - 1 = -1 -> -100%/yr,
#       a real annualised decline; computed and kept, NOT flagged.
#   - otherwise: (pop_2022 / pop_baseline)^(1/span) - 1, x100 for percent.
# Guarding on !growth_zero_flag means the ONLY zero-denominator path (baseline 0)
# never executes; the zero-NUMERATOR path (pop_2022 == 0) is well defined.

span <- END_YEAR - st$baseline_year          # NA where baseline_year is NA

aagr_computable <- !is.na(change_abs) & !st$growth_zero_flag
# Extra defensive guard: never evaluate the exponent with a non-positive span.
# In practice aagr_computable already excludes span 0 (those are change_abs NA),
# but assert it so a future baseline_year quirk cannot slip a 1/0 through.
if (any(aagr_computable & (is.na(span) | span <= 0))) {
  bad_span <- st$unit_id[aagr_computable & (is.na(span) | span <= 0)]
  stop("aagr would use a non-positive/NA span for unit_id(s): ",
       paste(sort(bad_span), collapse = ", "),
       " (single-round reserves must be NA before this point).", call. = FALSE)
}

aagr <- ifelse(
  aagr_computable,
  round(((st$pop_2022 / pop_baseline)^(1 / span) - 1) * 100, 1),
  NA_real_
)

stats_sf$aagr <- aagr
st$aagr       <- aagr

# --- 5a. Verify aagr NA-pattern (same set as change_pct) ----------------------
rule("STEP 5a (6.4) - verify aagr: same NA set as change_pct; no Inf/NaN")

n_aagr_valid <- sum(!is.na(st$aagr))
n_aagr_na    <- sum(is.na(st$aagr))
cat(sprintf("aagr: non-NA %d | NA %d (of 58)\n", n_aagr_valid, n_aagr_na))

# aagr and change_pct must share the exact NA pattern (both are ratio metrics with
# the identical guards). Compare positionally.
if (!identical(is.na(st$aagr), is.na(st$change_pct))) {
  disagree <- st$unit_id[is.na(st$aagr) != is.na(st$change_pct)]
  stop("aagr NA-pattern differs from change_pct for unit_id(s): ",
       paste(sort(disagree), collapse = ", "),
       " (the two ratio metrics must share the same NA set).", call. = FALSE)
}
cat("aagr NA-pattern identical to change_pct: OK\n")

# --- 5b. Real 2022-zero declines must be -100%/yr (valid), NOT NA -------------
if (any(decline_zero)) {
  bad_decl <- st$unit_id[decline_zero & (is.na(st$aagr) |
                                         round(st$aagr, 1) != -100 |
                                         st$growth_zero_flag)]
  if (length(bad_decl) > 0) {
    stop("Real 2022-zero decline(s) gave wrong aagr for unit_id(s): ",
         paste(sort(bad_decl), collapse = ", "),
         " (expected -100%/yr, not flagged).", call. = FALSE)
  }
  cat(sprintf("real 2022-zero declines -> aagr = -100%%/yr (valid, unflagged): %d OK\n",
              sum(decline_zero)))
}

# --- 5c. No Inf/NaN in aagr (Decision 9 hard requirement) ---------------------
if (any(is.infinite(st$aagr) | is.nan(st$aagr), na.rm = TRUE)) {
  bad_if <- st$unit_id[is.infinite(st$aagr) | is.nan(st$aagr)]
  stop("aagr contains Inf/NaN for unit_id(s): ",
       paste(sort(bad_if), collapse = ", "), " (Decision 9 forbids it).",
       call. = FALSE)
}
cat("aagr contains no Inf/NaN: OK\n")

# --- 5d. Sign coherence: aagr and change_pct must agree in sign ---------------
# Over a fixed endpoint, an annualised rate and a total percent change always
# share sign (growth is growth; decline is decline). A mismatch would signal a
# span or exponent bug. Zero-change reserves (change_pct == 0) are exempt.
sign_bad <- st$unit_id[!is.na(st$aagr) & !is.na(st$change_pct) &
                       st$change_pct != 0 &
                       sign(st$aagr) != sign(st$change_pct)]
if (length(sign_bad) > 0) {
  stop("aagr and change_pct disagree in sign for unit_id(s): ",
       paste(sort(sign_bad), collapse = ", "),
       " (an annualised rate must share the total change's sign).", call. = FALSE)
}
cat("aagr sign agrees with change_pct on every non-zero reserve: OK\n")

# --- 5e. Spot the extremes ---------------------------------------------------
cat("\ntop 5 aagr (fastest annual growth):\n")
st |> filter(!is.na(aagr)) |> arrange(desc(aagr)) |> slice_head(n = 5) |>
  mutate(l = sprintf("   #%d %-22s %d(base %s)->%s over %dy = %+.1f%%/yr",
                     unit_id, unit_name, baseline_year,
                     as.character(pop_baseline),
                     ifelse(is.na(pop_2022), "NA", as.character(pop_2022)),
                     END_YEAR - baseline_year, aagr)) |>
  pull(l) |> cat(sep = "\n")
cat("\nbottom 5 aagr (fastest annual decline):\n")
st |> filter(!is.na(aagr)) |> arrange(aagr) |> slice_head(n = 5) |>
  mutate(l = sprintf("   #%d %-22s %d(base %s)->%s over %dy = %+.1f%%/yr",
                     unit_id, unit_name, baseline_year,
                     as.character(pop_baseline),
                     ifelse(is.na(pop_2022), "NA", as.character(pop_2022)),
                     END_YEAR - baseline_year, aagr)) |>
  pull(l) |> cat(sep = "\n")
cat("\n")

rule("04 STAGE 6.4 done: aagr populated; same NA set as change_pct; no Inf/NaN.")

# ==============================================================================
# STEP 6 (6.6) - write outputs/tables/tbl_01_reserve_growth.csv
# ==============================================================================
rule("STEP 6 (6.6) - write tbl_01_reserve_growth.csv")

# Per-reserve growth table for all 58 reserves. Column set follows the 6.6 spec,
# with two as-built refinements:
#   - pop_baseline (single value column) + baseline_year carry the plan's
#     "pop_<baseline>" unambiguously; a single pop_<baseline> column is impossible
#     because reserves have different baseline years. pop_2022 is the endpoint.
#   - growth_zero_flag (Decision 9) is included so a reader can tell a
#     ratio-undefined NA (baseline 0) from a missing-data NA.
# Sorted by change_pct descending (the headline "which reserves carried the
# recovery" metric, proposal Q1), NAs last. All 58 rows are kept (measured +
# flagged) so the table is the complete reserve set, not just the growing ones.

req_tbl_cols <- c("unit_id", "unit_name", "state", "landscape_complex",
                  "baseline_year", "pop_baseline", "pop_2022",
                  "change_abs", "change_pct", "aagr", "growth_zero_flag",
                  "density_2022", "census_status")
missing_tbl <- setdiff(req_tbl_cols, names(st))
if (length(missing_tbl) > 0) {
  stop("tbl_01 cannot be built - missing column(s) on the working table: ",
       paste(missing_tbl, collapse = ", "), call. = FALSE)
}

growth_tbl <- st |>
  select(all_of(req_tbl_cols)) |>
  arrange(dplyr::desc(!is.na(change_pct)),   # non-NA change_pct first
          dplyr::desc(change_pct),           # then by growth, high -> low
          unit_id)                           # stable tiebreak

# --- 6a. Guard the table before writing --------------------------------------
stopifnot(nrow(growth_tbl) == 58L)
stopifnot(!any(duplicated(growth_tbl$unit_id)))
# No Inf/NaN in any numeric metric column (belt-and-braces before the file lands).
for (col in c("change_abs", "change_pct", "aagr", "density_2022")) {
  v <- growth_tbl[[col]]
  if (any(is.infinite(v) | is.nan(v), na.rm = TRUE)) {
    stop("tbl_01 column '", col, "' contains Inf/NaN.", call. = FALSE)
  }
}
cat(sprintf("tbl_01: %d rows, %d columns\n", nrow(growth_tbl), ncol(growth_tbl)))
cat("columns: ", paste(names(growth_tbl), collapse = ", "), "\n", sep = "")

# Show the head and tail so the sort + content are visible in the log.
cat("\ntop 5 rows (by change_pct):\n")
growth_tbl |> slice_head(n = 5) |>
  mutate(l = sprintf("   #%d %-22s %s  chg=%s pct=%s aagr=%s",
                     unit_id, unit_name, state,
                     ifelse(is.na(change_abs), "NA", sprintf("%+d", as.integer(change_abs))),
                     ifelse(is.na(change_pct), "NA", sprintf("%+.1f%%", change_pct)),
                     ifelse(is.na(aagr), "NA", sprintf("%+.1f%%/yr", aagr)))) |>
  pull(l) |> cat(sep = "\n")
cat("\nlast 5 rows (NA-change_pct reserves, sorted to the bottom):\n")
growth_tbl |> slice_tail(n = 5) |>
  mutate(l = sprintf("   #%d %-22s %s  status=%s flag=%s",
                     unit_id, unit_name, state, census_status,
                     growth_zero_flag)) |>
  pull(l) |> cat(sep = "\n")
cat("\n")

# --- 6b. Write the table via the project IO helper ---------------------------
write_table(growth_tbl, growth_tbl_nn, growth_tbl_slug)

rule("04 STAGE 6.6 done: tbl_01_reserve_growth.csv written (58 reserves).")

# ==============================================================================
# STEP 7 (6.7) - Verify the derived metrics as a whole
# ==============================================================================
rule("STEP 7 (6.7) - verify: no Inf/NaN; NA pattern matches Decisions 7/9; sanity; spot-checks")

# This step re-checks the FULL set together (the per-metric steps checked each in
# isolation) and hard-stops before the layer is written in 6.8. Nothing here
# recomputes a metric; it only asserts properties of the finished columns.

vst <- st_drop_geometry(stats_sf)   # the object that will be written in 6.8

# --- 7a. No Inf/NaN anywhere in the three growth metrics ---------------------
inf_hits <- character(0)
for (col in c("change_abs", "change_pct", "aagr")) {
  v <- vst[[col]]
  if (any(is.infinite(v) | is.nan(v), na.rm = TRUE)) {
    inf_hits <- c(inf_hits, sprintf("%s: %s", col,
                  paste(vst$unit_id[is.infinite(v) | is.nan(v)], collapse = ",")))
  }
}
if (length(inf_hits) > 0) {
  stop("Inf/NaN present (Decision 9 forbids it): ",
       paste(inf_hits, collapse = " | "), call. = FALSE)
}
cat("no Inf/NaN in change_abs/change_pct/aagr: OK\n")

# --- 7b. NA pattern matches Decisions 7 + 9 ----------------------------------
# change_abs NA  <=> single-round OR endpoint missing.
# change_pct NA  <=> change_abs NA OR zero baseline (growth_zero_flag).
# aagr NA        <=> change_pct NA (identical set).
exp_abs_na <- is.na(vst$baseline_year) | (vst$baseline_year >= END_YEAR) |
              is.na(pop_baseline) | is.na(vst$pop_2022)
if (!identical(exp_abs_na, is.na(vst$change_abs))) {
  stop("6.7: change_abs NA-pattern drifted from Decision 7.", call. = FALSE)
}
exp_ratio_na <- is.na(vst$change_abs) | vst$growth_zero_flag
if (!identical(exp_ratio_na, is.na(vst$change_pct))) {
  stop("6.7: change_pct NA-pattern drifted from Decision 7/9.", call. = FALSE)
}
if (!identical(is.na(vst$aagr), is.na(vst$change_pct))) {
  stop("6.7: aagr NA-pattern differs from change_pct.", call. = FALSE)
}
cat(sprintf("NA pattern OK - change_abs NA %d | change_pct/aagr NA %d | flag %d\n",
            sum(is.na(vst$change_abs)), sum(is.na(vst$change_pct)),
            sum(vst$growth_zero_flag)))

# --- 7c. National sanity: the recovery should dominate -----------------------
grow  <- sum(vst$change_abs > 0, na.rm = TRUE)
decl  <- sum(vst$change_abs < 0, na.rm = TRUE)
flat  <- sum(vst$change_abs == 0, na.rm = TRUE)
cat(sprintf("change_abs sign split: growing %d | declining %d | flat %d | NA %d\n",
            grow, decl, flat, sum(is.na(vst$change_abs))))
if (grow <= decl) {
  warning("6.7 sanity: growing reserves (", grow, ") do not outnumber declining (",
          decl, "). Check the metrics before publishing.")
}
# Sum of change_abs across reserves with a valid span (a coarse national signal;
# NOT the country total, which spans a different denominator - Decision 2).
cat(sprintf("sum(change_abs) over %d valid-span reserves = %+d tigers\n",
            sum(!is.na(vst$change_abs)),
            as.integer(sum(vst$change_abs, na.rm = TRUE))))

# --- 7d. Spot-check named reserves against the source figures ----------------
# Corbett (large, growing), Ranthambore (mid, growing), a zero-2022 decline, and
# Mukundara (zero baseline -> flagged NA). Values echoed, not asserted, so the
# reviewer eyeballs them against the census tables.
spot_ids <- c(Corbett = 55L, Ranthambore = 20L, Kamlang = 4L, `Mukundara Hills` = 42L)
cat("\nspot-checks (eyeball against the NTCA tables):\n")
for (nm in names(spot_ids)) {
  r <- vst[vst$unit_id == spot_ids[[nm]], , drop = FALSE]
  if (nrow(r) == 1L) {
    cat(sprintf("   #%d %-16s base %s(%s) -> 2022 %s | chg %s | pct %s | aagr %s | flag %s\n",
                r$unit_id, r$unit_name,
                ifelse(is.na(r$baseline_year), "NA", as.character(r$baseline_year)),
                ifelse(is.na(pop_baseline[vst$unit_id == spot_ids[[nm]]]), "NA",
                       as.character(pop_baseline[vst$unit_id == spot_ids[[nm]]])),
                ifelse(is.na(r$pop_2022), "NA", as.character(r$pop_2022)),
                ifelse(is.na(r$change_abs), "NA", sprintf("%+d", as.integer(r$change_abs))),
                ifelse(is.na(r$change_pct), "NA", sprintf("%+.1f%%", r$change_pct)),
                ifelse(is.na(r$aagr), "NA", sprintf("%+.1f%%/yr", r$aagr)),
                r$growth_zero_flag))
  } else {
    cat(sprintf("   (spot-check id %d for '%s' not found - check the unit_id map)\n",
                spot_ids[[nm]], nm))
  }
}
cat("\n")

rule("04 STAGE 6.7 done: metrics verified (no Inf/NaN; NA pattern per Decisions 7/9; sane).")

# ==============================================================================
# STEP 8 (6.8) - Append the four growth columns to the stats layer
# ==============================================================================
rule("STEP 8 (6.8) - append change_abs/change_pct/aagr/growth_zero_flag to the stats layer")

# stats_sf already carries the four derived columns (attached in Steps 3-5). Write
# the WHOLE layer back so it and tbl_01 agree. pop_baseline is a tbl_01 convenience
# (derivable from baseline_year + pop_*), NOT added to the layer - the layer keeps
# the per-year pop_* columns and baseline_year, from which pop_baseline is a lookup.
# The Step-1 guard guarantees the four columns were absent on read, so this is a
# clean append, never a double-add.

# Final column order: the Week-5 schema, then the four growth columns appended in
# metric order with growth_zero_flag beside the ratio metrics it governs.
week5_cols <- c(
  "unit_id", "unit_name", "unit_name_std", "state", "landscape_complex",
  "area_km2", "area_provisional", "area_source",
  "pop_2014", "pop_2018", "pop_2022",
  "density_2022", "baseline_year", "census_status",
  "n_parts", "match_status", "geometry_present", "source",
  "poly_km2", "poly_census_ratio"
)
growth_cols <- c("change_abs", "change_pct", "aagr", "growth_zero_flag")

# Keep only Week-5 columns that are actually present (robust to minor scripts/02
# schema drift), then the four growth columns, then geometry (sf keeps it last).
present_week5 <- intersect(week5_cols, names(stats_sf))
missing_week5 <- setdiff(week5_cols, names(stats_sf))
if (length(missing_week5) > 0) {
  warning("Week-5 column(s) not on the layer, omitted from output: ",
          paste(missing_week5, collapse = ", "))
}
stopifnot(all(growth_cols %in% names(stats_sf)))

stats_out_sf <- stats_sf |> select(all_of(c(present_week5, growth_cols)))

# Final guards before writing.
stopifnot(nrow(stats_out_sf) == 58L)
stopifnot(!any(duplicated(stats_out_sf$unit_id)))
stopifnot(inherits(stats_out_sf, "sf"))
cat(sprintf("final layer: %d reserves, %d attribute columns + geometry\n",
            nrow(stats_out_sf), length(present_week5) + length(growth_cols)))
cat("growth columns appended: ", paste(growth_cols, collapse = ", "), "\n", sep = "")

# Overwrite the Week-5 deliverable in place (write_processed_vec uses delete_dsn).
write_processed_vec(stats_out_sf, basename(stats_path))

# Confirm the write round-trips and the four columns survived with the right NA count.
stats_back <- read_vec(stats_path)
cat(sprintf("re-read check: %d reserves | change_abs non-NA %d | aagr non-NA %d | flag TRUE %d\n",
            nrow(stats_back),
            sum(!is.na(stats_back$change_abs)),
            sum(!is.na(stats_back$aagr)),
            sum(stats_back$growth_zero_flag, na.rm = TRUE)))
stopifnot(nrow(stats_back) == 58L)
stopifnot(all(growth_cols %in% names(stats_back)))

rule("04 STAGE 6.8 done: four growth columns appended to stats_reserve_census_7755.gpkg.")

rule("04 done: per-reserve growth metrics derived; tbl_01 + layer updated.")
cat("REMAINING Week-6 housekeeping (not in this script):\n",
    "  - docs/data-dictionary.md: mark change_abs/change_pct/aagr as built,\n",
    "    add growth_zero_flag, drop the 'Week 6' section tag (done in the doc edit).\n",
    "  - handoff.md + project-plan.md Week 6 -> complete.\n",
    "NEXT: Week 7 (scripts/05) - growth ranking figure, animated choropleth,\n",
    "regional roll-up (tbl_02).\n", sep = "")
