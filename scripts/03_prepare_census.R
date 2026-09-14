# =============================================================================
# 03_prepare_census.R  [GROWTH - priority 1]
# Assemble the reserve-level census time series and (later) join it to the
# reserve boundary layer with census-sourced area and density.
#
# Decision 6: the growth series is the WITHIN-RESERVE SECR estimate for
#   2014 / 2018 / 2022 only. 2006/2010 have no per-reserve table (context only).
# Decision 7: a missing (reserve, round) cell is NA. No carry-forward, no
#   interpolation, no gap-fill.
# Decision 8: reserve area = NTCA-notified core+buffer total (tbl_05), NOT the
#   KML polygon; overwritten into the boundary layer in a later step.
#
# THIS FILE IS BUILT IN STAGES (project plan, Week 5):
#   [5.2]              read census_reserve_long.csv, validate against the
#                      Decision-6 year set and unit_id, pivot long -> wide
#                      (pop_2014, pop_2018, pop_2022). Verify row count + unit_id.
#   [5.3]              left-join census_wide onto boundary_reserves_all_7755.gpkg
#                      by unit_id; carry census_status; confirm all 58 present
#                      (53 measured + 5 flagged); 3 geometry-absent keep census.
#   [5.4]              overwrite area_km2 from tbl_05_area_source_map.csv
#                      (Decision 8): area_km2 <- area_total_km2, area_source <-
#                      the census source, area_provisional <- FALSE per row that
#                      gets a census area (placeholder + TRUE kept otherwise).
#   [5.5]              density_2022 = pop_2022 / area_km2 * 100 (per 100 km2);
#                      NA where pop_2022 or area_km2 is NA; 0 for a real pop zero.
#   [5.6-5.7 THIS COMMIT] baseline_year = earliest round with a non-NA pop per
#                      reserve; write data/processed/stats_reserve_census_7755.gpkg
#                      (all 58 reserves) and update docs/data-dictionary.md.
#   [Week 6]           change_abs / change_pct / aagr.
#
# Outputs (through this stage):
#   outputs/tables/tbl_06_census_wide_check.csv    (5.2 pivot QA)
#   outputs/tables/tbl_07_census_join_check.csv    (5.3 per-reserve join QA)
#   outputs/tables/tbl_08_area_overwrite_check.csv (5.4 area overwrite QA)
#   outputs/tables/tbl_09_density_check.csv        (5.5 density QA)
#   data/processed/stats_reserve_census_7755.gpkg  (5.7 DELIVERABLE layer)
# Outputs (Week 6):
#   outputs/tables/tbl_01_reserve_growth.csv
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(sf)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
})

source(here("R", "00_config.R"))        # CENSUS_SERIES_YEARS, DIR_*, etc.
source(here("R", "00_functions_io.R"))  # write_table (tbl_NN_slug.csv)

rule <- function(txt) cat("\n", strrep("=", 78), "\n", txt, "\n",
                          strrep("=", 78), "\n", sep = "")

# ---- Decision-6 series years -------------------------------------------------
# The per-reserve SECR series is 2014/2018/2022 ONLY (Decision 6). This now comes
# from R/00_config.R (CENSUS_SERIES_YEARS), reconciled to Decision 6 in task 5.9.
# A defensive guard catches any future config edit that reintroduces the old
# five-round vector, so the drift can never return silently.
SERIES_YEARS <- CENSUS_SERIES_YEARS

if (!setequal(SERIES_YEARS, c(2014L, 2018L, 2022L))) {
  stop("R/00_config.R CENSUS_SERIES_YEARS = {", paste(SERIES_YEARS, collapse = ", "),
       "} does not match the Decision-6 series 2014/2018/2022. Fix the config.",
       call. = FALSE)
}

# ---- Paths ------------------------------------------------------------------
census_long_path <- file.path(DIR_RAW, "ntca", "census_reserve_long.csv")
stopifnot(file.exists(census_long_path))

# QA table numbers (independent of script prefixes; naming-conventions Sec 6).
# 5.2 wide-pivot check is tbl_06 (tbl_05 is the area-source map from task 5.1).
wide_check_nn   <- 6L
wide_check_slug <- "census_wide_check"
join_check_nn   <- 7L
join_check_slug <- "census_join_check"
area_check_nn   <- 8L
area_check_slug <- "area_overwrite_check"
density_check_nn   <- 9L
density_check_slug <- "density_check"

# Area-source map from task 5.1 / Decision 8 (tbl_05). Holds the NTCA-notified
# core/buffer/total per reserve; area_total_km2 overwrites area_km2 in 5.4.
area_map_path <- file.path(DIR_TABLES, "tbl_05_area_source_map.csv")

# Deliverable layer (5.7).
stats_out <- "stats_reserve_census_7755.gpkg"

# ==============================================================================
# STEP 1 - Read the long census table
# ==============================================================================
rule("STEP 1 - read census_reserve_long.csv (skip commented header block)")

# The file carries a block of quoted '#'-prefixed comment lines before the real
# header. read_csv's comment = "#" does not strip quoted '#'; drop them by hand,
# then parse the remainder.
raw_lines <- read_lines(census_long_path)
data_lines <- raw_lines[!str_detect(raw_lines, '^\\s*"?#')]
census_long <- read_csv(paste(data_lines, collapse = "\n"),
                        show_col_types = FALSE, progress = FALSE)

cat("rows read:", nrow(census_long),
    "| distinct unit_id:", dplyr::n_distinct(census_long$unit_id), "\n")

# Required columns for this step.
req_cols <- c("unit_id", "unit_name", "year", "pop",
              "spatial_unit", "census_status")
missing_cols <- setdiff(req_cols, names(census_long))
if (length(missing_cols) > 0) {
  stop("census_reserve_long.csv is missing required column(s): ",
       paste(missing_cols, collapse = ", "), call. = FALSE)
}

# Enforce types (unit_id/year integer, pop numeric). year/pop may be NA on flag
# rows; suppress the coercion warning and let NA flow through.
census_long <- census_long |>
  mutate(
    unit_id = as.integer(unit_id),
    year    = suppressWarnings(as.integer(year)),
    pop     = suppressWarnings(as.numeric(pop))
  )

# ==============================================================================
# STEP 2 - Filter to the pivot input: measured, within-reserve rows only
# ==============================================================================
rule("STEP 2 - filter to census_status == 'measured' AND spatial_unit == 'within_reserve'")

# WHAT IS EXCLUDED HERE (by design, Decisions 6/7):
#   - not_estimated_post2022_notification  : 5 flag rows (pop = NA, no year) ->
#       these reserves map but have no population; they re-enter at the boundary
#       LEFT JOIN in step 5.3, NOT in the pivot.
#   - measured_prose_supplementary         : Orang 2014, Ratapani 2022 (a
#       non-within spatial_unit) -> preserved in the long file, never in the
#       within-reserve series.
#   - any 2006/2010 rows                   : not in this file (kept separately),
#       but the year assert below is the backstop if one ever appears.
census_within <- census_long |>
  filter(census_status == "measured", spatial_unit == "within_reserve")

cat("measured/within rows:", nrow(census_within),
    "| distinct reserves:", dplyr::n_distinct(census_within$unit_id), "\n")
cat("rows per year:\n")
census_within |> count(year) |> arrange(year) |>
  mutate(l = sprintf("   %d: %d", year, n)) |> pull(l) |> cat(sep = "\n")
cat("\n")

# ==============================================================================
# STEP 3 - Validate BEFORE pivoting (fail loud, not silent)
# ==============================================================================
rule("STEP 3 - validate years, unit_id, and (unit_id, year) uniqueness")

# 3a. Every year must be in the Decision-6 series. A 2006/2010 row here would be
#     a data error (they belong in the 2006_2010 context file).
bad_years <- setdiff(unique(census_within$year), SERIES_YEARS)
if (length(bad_years) > 0) {
  stop("Unexpected census year(s) in the within-reserve series: ",
       paste(bad_years, collapse = ", "),
       ". Decision 6 fixes the series to ", paste(SERIES_YEARS, collapse = "/"),
       ".", call. = FALSE)
}
cat("years present:", paste(sort(unique(census_within$year)), collapse = ", "),
    "(expected ", paste(SERIES_YEARS, collapse = "/"), ")\n", sep = "")

# 3b. unit_id must be a non-missing integer on every within-reserve row.
if (any(is.na(census_within$unit_id))) {
  stop(sum(is.na(census_within$unit_id)),
       " within-reserve row(s) have a missing unit_id.", call. = FALSE)
}

# 3c. (unit_id, year) must be unique - a duplicate would silently overwrite on
#     pivot (values_fn would collapse it). Two Pench reserves are DIFFERENT
#     unit_ids (23 MP, 33 MH), so they are NOT duplicates - this is exactly why
#     the key is unit_id, never unit_name.
dups <- census_within |> count(unit_id, year) |> filter(n > 1)
if (nrow(dups) > 0) {
  cat("!! duplicate (unit_id, year) rows:\n")
  dups |> left_join(distinct(census_within, unit_id, unit_name), by = "unit_id") |>
    mutate(l = sprintf("   #%d %s year %d  x%d", unit_id, unit_name, year, n)) |>
    pull(l) |> cat(sep = "\n")
  stop("Duplicate (unit_id, year) pairs; resolve before pivoting.", call. = FALSE)
}
cat("(unit_id, year) uniqueness: OK (no duplicates)\n")

# 3d. Report NA vs zero in pop, so the Decision-7 distinction stays visible.
#     A pop = 0 is a REAL within-reserve zero (e.g. Mukundara 2014, Dampa) and
#     must remain 0; a missing round is simply an absent row (-> NA after pivot).
n_zero <- sum(census_within$pop == 0, na.rm = TRUE)
n_na   <- sum(is.na(census_within$pop))
cat(sprintf("pop in within set: %d rows | real zeros: %d | NA-within: %d\n",
            nrow(census_within), n_zero, n_na))
if (n_na > 0) {
  census_within |> filter(is.na(pop)) |>
    mutate(l = sprintf("   NA-within: #%d %s %d (kept as NA, Decision 7)",
                       unit_id, unit_name, year)) |>
    pull(l) |> cat(sep = "\n")
  cat("\n")
}

# ==============================================================================
# STEP 4 - Pivot long -> wide (pop_2014, pop_2018, pop_2022)
# ==============================================================================
rule("STEP 4 - pivot to wide: one row per unit_id, columns pop_2014/2018/2022")

# names_expand = TRUE forces all three SERIES_YEARS columns to exist even if a
# year had no rows, so the wide schema is fixed regardless of the input. A
# (reserve, round) with no row becomes NA (Decision 7) - which is what pivot
# does by default for absent combinations.
census_wide <- census_within |>
  select(unit_id, unit_name, year, pop) |>
  mutate(year = factor(year, levels = SERIES_YEARS)) |>
  pivot_wider(
    id_cols     = c(unit_id, unit_name),
    names_from  = year,
    names_expand = TRUE,
    names_prefix = "pop_",
    values_from = pop
  ) |>
  arrange(unit_id)

# Guarantee the three columns exist and are in order (defensive).
for (y in SERIES_YEARS) {
  col <- paste0("pop_", y)
  if (!col %in% names(census_wide)) census_wide[[col]] <- NA_real_
}
census_wide <- census_wide |>
  select(unit_id, unit_name, pop_2014, pop_2018, pop_2022)

cat("wide rows (= distinct within-reserve reserves):", nrow(census_wide), "\n")
cat("non-NA per column:\n")
cat(sprintf("   pop_2014: %d | pop_2018: %d | pop_2022: %d\n",
            sum(!is.na(census_wide$pop_2014)),
            sum(!is.na(census_wide$pop_2018)),
            sum(!is.na(census_wide$pop_2022))))

# ==============================================================================
# STEP 5 - Verify row count and unit_id set (task 5.2 done-when)
# ==============================================================================
rule("STEP 5 - verify row count and unit_id set")

# Expected from the Week-4 extraction (handoff / methodology): 53 reserves carry
# a measured within-reserve figure in at least one round.
#
# TWO DIFFERENT COUNTS - do not conflate them:
#   ROW PRESENCE  (a reserve HAS a row that round)      : 45 / 50 / 53
#   NON-NA VALUE  (that row's pop is an actual number)  : 45 / 50 / 52
# They differ only in 2022, because Sundarbans (unit_id 57) has a 2022 within
# ROW but a BLANK within-figure (only the biosphere-level 101+-10 is published),
# stored NA-within (handoff flag; Decision 7). The done-when for 5.2 is about the
# SERIES SHAPE, so verify ROW PRESENCE (45/50/53) and report non-NA alongside.
EXPECTED_RESERVES     <- 53L
EXPECTED_ROWS_BY_YEAR <- c(pop_2014 = 45L, pop_2018 = 50L, pop_2022 = 53L)

got_reserves <- nrow(census_wide)

# Row presence per year = reserves that had a row in census_within that year.
rows_by_year <- vapply(
  SERIES_YEARS,
  function(y) dplyr::n_distinct(census_within$unit_id[census_within$year == y]),
  integer(1)
)
names(rows_by_year) <- paste0("pop_", SERIES_YEARS)

# Non-NA value per year (informational; 2022 is one short of row presence).
nonna_by_year <- c(
  pop_2014 = sum(!is.na(census_wide$pop_2014)),
  pop_2018 = sum(!is.na(census_wide$pop_2018)),
  pop_2022 = sum(!is.na(census_wide$pop_2022))
)

cat(sprintf("reserves in wide table: %d (expected %d)\n",
            got_reserves, EXPECTED_RESERVES))
for (nm in names(EXPECTED_ROWS_BY_YEAR)) {
  flag <- if (rows_by_year[[nm]] == EXPECTED_ROWS_BY_YEAR[[nm]]) "OK" else "MISMATCH"
  cat(sprintf("   %s: row-present %d (expected %d) [%s] | non-NA value %d\n",
              nm, rows_by_year[[nm]], EXPECTED_ROWS_BY_YEAR[[nm]], flag,
              nonna_by_year[[nm]]))
}

# Report any row-present-but-NA-within case explicitly (expected: Sundarbans 2022).
na_within_2022 <- census_within |>
  filter(year == 2022L, is.na(pop)) |>
  distinct(unit_id, unit_name)
if (nrow(na_within_2022) > 0) {
  cat("row-present but NA-within (2022):\n")
  na_within_2022 |>
    mutate(l = sprintf("   #%d %s (within-figure blank; kept NA, Decision 7)",
                       unit_id, unit_name)) |>
    pull(l) |> cat(sep = "\n")
  cat("\n")
}

# unit_id set: unique, non-missing, and within the 1..58 reserve universe.
stopifnot(!any(duplicated(census_wide$unit_id)))
stopifnot(!any(is.na(census_wide$unit_id)))
out_of_range <- census_wide$unit_id[!census_wide$unit_id %in% 1:58]
if (length(out_of_range) > 0) {
  stop("unit_id(s) outside 1:58 in the wide table: ",
       paste(out_of_range, collapse = ", "), call. = FALSE)
}

# Two-Pench guard: both must be present on their own unit_id with distinct series.
if (all(c(23L, 33L) %in% census_wide$unit_id)) {
  cat("\nPench split check (must be two rows, distinct series):\n")
  census_wide |> filter(unit_id %in% c(23L, 33L)) |>
    mutate(l = sprintf("   #%d %-10s  2014=%s 2018=%s 2022=%s",
                       unit_id, unit_name,
                       ifelse(is.na(pop_2014), "NA", pop_2014),
                       ifelse(is.na(pop_2018), "NA", pop_2018),
                       ifelse(is.na(pop_2022), "NA", pop_2022))) |>
    pull(l) |> cat(sep = "\n")
  cat("\n")
}

# Hard stop if the reserve count or the per-year series shape is wrong - the
# pivot is the whole job of 5.2. Checks ROW PRESENCE (45/50/53), not non-NA.
if (got_reserves != EXPECTED_RESERVES) {
  stop("Wide table has ", got_reserves, " reserves; expected ",
       EXPECTED_RESERVES, ". Investigate the filter/extraction before 5.3.",
       call. = FALSE)
}
if (!identical(rows_by_year[names(EXPECTED_ROWS_BY_YEAR)], EXPECTED_ROWS_BY_YEAR)) {
  stop("Per-year row presence ",
       paste(sprintf("%s=%d", names(rows_by_year), rows_by_year), collapse = ", "),
       " does not match the expected 45/50/53. Investigate before 5.3.",
       call. = FALSE)
}

# ---- QA output (not the deliverable layer - that is 5.7) ---------------------
# Write the wide table as a plain CSV so the pivot can be eyeballed before the
# join. The joined GeoPackage (stats_reserve_census_7755.gpkg) is written in 5.7.
write_table(census_wide, wide_check_nn, wide_check_slug)

rule("03 STAGE 5.2 done: long read, validated, pivoted wide (53 reserves; 45/50/53).")
cat("NEXT (5.3): left-join census_wide onto boundary_reserves_all_7755.gpkg.\n")

# ==============================================================================
# STEP 6 (5.3) - Join wide census onto the reserve boundary layer
# ==============================================================================
rule("STEP 6 (5.3) - left-join census onto boundary_reserves_all_7755.gpkg by unit_id")

reserves_path <- file.path(DIR_PROCESSED, "boundary_reserves_all_7755.gpkg")
stopifnot(file.exists(reserves_path))

# read_vec() reprojects to CRS_ANALYSIS (7755). The boundary layer holds all 58
# reserves (55 with geometry + 3 geometry-absent empty rows).
reserves_sf <- read_vec(reserves_path)
cat("boundary reserves read:", nrow(reserves_sf),
    "| with geometry_present==TRUE:",
    sum(reserves_sf$geometry_present, na.rm = TRUE),
    "| absent:", sum(!reserves_sf$geometry_present, na.rm = TRUE), "\n")

# --- 6a. Guard the boundary layer BEFORE joining ------------------------------
stopifnot("unit_id" %in% names(reserves_sf))
if (nrow(reserves_sf) != 58L) {
  stop("Boundary layer has ", nrow(reserves_sf),
       " reserves; expected 58. Check scripts/02 output.", call. = FALSE)
}
if (any(duplicated(reserves_sf$unit_id))) {
  stop("Duplicate unit_id in the boundary layer.", call. = FALSE)
}

# --- 6b. Derive census_status per reserve from the LONG file -------------------
# census_wide has only the 53 measured reserves, so census_status must come from
# the long file (which also carries the 5 never-estimated flag rows). Collapse to
# one status per unit_id: a reserve with any measured/within row is "measured";
# a never-estimated reserve is "not_estimated_post2022_notification". These two
# sets are disjoint and cover all 58 (verified in the data).
status_by_unit <- census_long |>
  mutate(
    is_measured = census_status == "measured" & spatial_unit == "within_reserve",
    is_flagged  = census_status == "not_estimated_post2022_notification"
  ) |>
  group_by(unit_id) |>
  summarise(
    any_measured = any(is_measured, na.rm = TRUE),
    any_flagged  = any(is_flagged,  na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    census_status = case_when(
      any_measured ~ "measured",
      any_flagged  ~ "not_estimated_post2022_notification",
      TRUE         ~ NA_character_          # should not happen; caught below
    )
  ) |>
  select(unit_id, census_status)

# Every reserve that appears in the long file must resolve to a status.
if (any(is.na(status_by_unit$census_status))) {
  bad <- status_by_unit$unit_id[is.na(status_by_unit$census_status)]
  stop("Reserve(s) with unresolved census_status: ",
       paste(bad, collapse = ", "), call. = FALSE)
}

# --- 6c. Cross-check unit_id sets BEFORE the join (fail loud) ------------------
# The join is a LEFT join from the 58-reserve boundary, so census rows that do
# not match a boundary unit_id would be SILENTLY DROPPED. Guard against it: the
# census unit_id set must be a subset of the boundary unit_id set.
b_ids <- sort(reserves_sf$unit_id)
c_ids <- sort(unique(census_wide$unit_id))
census_not_in_boundary <- setdiff(c_ids, b_ids)
if (length(census_not_in_boundary) > 0) {
  cat("!! census unit_id(s) with NO boundary row (would be dropped):\n")
  census_wide |> filter(unit_id %in% census_not_in_boundary) |>
    mutate(l = sprintf("   #%d %s", unit_id, unit_name)) |>
    pull(l) |> cat(sep = "\n")
  stop("Census reserves missing from the boundary layer; fix before joining.",
       call. = FALSE)
}
# Informational: boundary reserves with no measured census (expected: the 5 flags).
boundary_no_census <- setdiff(b_ids, c_ids)
cat("boundary reserves with no measured census row (expected 5 flagged):",
    length(boundary_no_census), "\n")

# --- 6d. The join -------------------------------------------------------------
# LEFT join FROM the boundary layer so all 58 reserves (incl. the 3 geometry-
# absent and the 5 never-estimated) survive. Drop census unit_name first: the
# boundary layer carries the authoritative unit_name, and keeping both would
# create unit_name.x / unit_name.y. Keep only the pop_* columns from the census.
census_pop <- census_wide |> select(unit_id, pop_2014, pop_2018, pop_2022)

stats_sf <- reserves_sf |>
  left_join(census_pop,     by = "unit_id") |>
  left_join(status_by_unit, by = "unit_id")

# --- 6e. Verify the join (task 5.3 done-when) ---------------------------------
rule("STEP 7 (5.3) - verify join: 58 reserves, no unmatched, flags + geometry-absent intact")

# 7a. Still exactly 58 rows, unit_id unique - a left join must not add/lose rows.
stopifnot(nrow(stats_sf) == 58L)
stopifnot(!any(duplicated(stats_sf$unit_id)))
cat("rows after join:", nrow(stats_sf), "(expected 58)\n")

# 7b. census_status present on every reserve; counts match 53 measured / 5 flagged.
n_measured <- sum(stats_sf$census_status == "measured", na.rm = TRUE)
n_flagged  <- sum(stats_sf$census_status == "not_estimated_post2022_notification",
                  na.rm = TRUE)
n_status_na <- sum(is.na(stats_sf$census_status))
cat(sprintf("census_status: measured %d | not_estimated %d | NA %d (expected 53 / 5 / 0)\n",
            n_measured, n_flagged, n_status_na))
if (n_status_na > 0) {
  stop(n_status_na, " reserve(s) have no census_status after the join.",
       call. = FALSE)
}
if (n_measured != 53L || n_flagged != 5L) {
  stop("census_status split is ", n_measured, " / ", n_flagged,
       "; expected 53 / 5.", call. = FALSE)
}

# 7c. Population presence lines up with census_status.
#   - measured reserves: should have >=1 non-NA pop across the three rounds
#     (Sundarbans is the one measured reserve whose 2022 is NA-within, but it has
#      2014/2018 values, so it still has >=1 non-NA).
#   - flagged reserves: should have ALL pop_* == NA.
pop_cols <- c("pop_2014", "pop_2018", "pop_2022")
stats_tbl <- st_drop_geometry(stats_sf)
any_pop <- rowSums(!is.na(stats_tbl[pop_cols])) > 0

meas_no_pop <- stats_tbl$unit_id[stats_tbl$census_status == "measured" & !any_pop]
flag_has_pop <- stats_tbl$unit_id[
  stats_tbl$census_status == "not_estimated_post2022_notification" & any_pop]
if (length(meas_no_pop) > 0) {
  stop("Measured reserve(s) with no population in any round: ",
       paste(meas_no_pop, collapse = ", "), call. = FALSE)
}
if (length(flag_has_pop) > 0) {
  stop("Flagged (never-estimated) reserve(s) unexpectedly carry population: ",
       paste(flag_has_pop, collapse = ", "), call. = FALSE)
}
cat("population presence matches census_status (measured have data; flagged all NA)\n")

# 7d. The 3 geometry-absent reserves must still carry their census row.
#   Amrabad, Pilibhit are measured (have pop); Dholpur-Karauli is flagged (NA pop).
#   All three must be present with a resolved census_status.
absent <- stats_tbl |> filter(!geometry_present)
cat("\ngeometry-absent reserves (must still carry census):", nrow(absent), "\n")
absent |>
  mutate(l = sprintf("   #%d %-18s status=%s  pop_2022=%s",
                     unit_id, unit_name, census_status,
                     ifelse(is.na(pop_2022), "NA", as.character(pop_2022)))) |>
  pull(l) |> cat(sep = "\n")
cat("\n")
if (any(is.na(absent$census_status))) {
  stop("A geometry-absent reserve lost its census_status in the join.",
       call. = FALSE)
}

# 7e. Two-Pench guard survives the join on unit_id.
if (all(c(23L, 33L) %in% stats_tbl$unit_id)) {
  pench <- stats_tbl |> filter(unit_id %in% c(23L, 33L))
  cat("Pench split after join (distinct series on unit_id):\n")
  pench |>
    mutate(l = sprintf("   #%d %-10s 2014=%s 2018=%s 2022=%s",
                       unit_id, unit_name,
                       ifelse(is.na(pop_2014), "NA", pop_2014),
                       ifelse(is.na(pop_2018), "NA", pop_2018),
                       ifelse(is.na(pop_2022), "NA", pop_2022))) |>
    pull(l) |> cat(sep = "\n")
  cat("\n")
}

# ---- QA output: per-reserve join check (attribute table, no geometry) --------
join_check <- stats_tbl |>
  select(unit_id, unit_name, state, geometry_present, census_status,
         pop_2014, pop_2018, pop_2022) |>
  arrange(unit_id)
write_table(join_check, join_check_nn, join_check_slug)

rule("03 STAGE 5.3 done: census joined to boundary (58 reserves; 53 measured + 5 flagged).")
cat("NEXT (5.4): overwrite area_km2 from tbl_05_area_source_map.csv (Decision 8).\n")

# ==============================================================================
# STEP 8 (5.4) - Overwrite area_km2 from the census/notified area (Decision 8)
# ==============================================================================
rule("STEP 8 (5.4) - overwrite area_km2 from tbl_05_area_source_map.csv (Decision 8)")

# Decision 4/8: reserve area is the NTCA-NOTIFIED core+buffer total, never the
# KML polygon. tbl_05 (task 5.1) holds area_total_km2 per unit_id for all 58.
# The overwrite is CONDITIONAL per row (plan 5.4): a reserve gets the census
# area only if tbl_05 supplies one; otherwise it keeps the provisional
# placeholder and area_provisional stays TRUE. With the current tbl_05 (all 58
# populated) every reserve is overwritten, but the conditional keeps the flag
# correct by construction if a future tbl_05 ever omits a reserve.

stopifnot(file.exists(area_map_path))
area_map <- read_csv(area_map_path, comment = "#", show_col_types = FALSE,
                     progress = FALSE)

# Required columns from tbl_05.
req_area_cols <- c("unit_id", "area_total_km2", "area_source")
missing_area  <- setdiff(req_area_cols, names(area_map))
if (length(missing_area) > 0) {
  stop("tbl_05_area_source_map.csv missing column(s): ",
       paste(missing_area, collapse = ", "), call. = FALSE)
}

area_map <- area_map |>
  mutate(
    unit_id            = as.integer(unit_id),
    area_total_km2     = suppressWarnings(as.numeric(area_total_km2)),
    area_source_census = as.character(area_source)   # rename to avoid clash
  ) |>
  select(unit_id, area_total_km2, area_source_census)

# --- 8a. Guard tbl_05 against the joined layer BEFORE overwriting -------------
if (any(duplicated(area_map$unit_id))) {
  stop("Duplicate unit_id in tbl_05_area_source_map.csv.", call. = FALSE)
}
# Every reserve in the layer should have a tbl_05 row (informational if not).
layer_ids <- stats_sf$unit_id
no_area_row <- setdiff(layer_ids, area_map$unit_id)
if (length(no_area_row) > 0) {
  cat("note - reserve(s) with NO tbl_05 area row (keep placeholder, TRUE):\n")
  stats_sf |> st_drop_geometry() |> filter(unit_id %in% no_area_row) |>
    mutate(l = sprintf("   #%d %s", unit_id, unit_name)) |>
    pull(l) |> cat(sep = "\n")
  cat("\n")
}
# tbl_05 rows with no matching reserve (would be silently unused) - warn only.
area_orphans <- setdiff(area_map$unit_id, layer_ids)
if (length(area_orphans) > 0) {
  warning(length(area_orphans), " tbl_05 unit_id(s) match no reserve: ",
          paste(area_orphans, collapse = ", "))
}

# --- 8b. Preserve the provisional values for the QA log, then overwrite -------
# Keep the old (placeholder) area + source so the QA table shows before/after.
stats_sf <- stats_sf |>
  mutate(
    area_km2_provisional_old = area_km2,
    area_source_old          = area_source
  ) |>
  left_join(area_map, by = "unit_id")

# CONDITIONAL overwrite: only where a census area_total_km2 exists (non-NA).
has_census_area <- !is.na(stats_sf$area_total_km2)

stats_sf <- stats_sf |>
  mutate(
    area_km2 = ifelse(has_census_area, area_total_km2, area_km2),
    area_source = ifelse(has_census_area,
                         area_source_census, area_source),
    area_provisional = ifelse(has_census_area, FALSE, area_provisional)
  )

# --- 8c. Recompute the stale QA ratio -----------------------------------------
# poly_census_ratio was computed in scripts/02 as poly_km2 / (provisional area).
# After the overwrite that denominator changed, so the old ratio is stale. Recompute
# against the notified area so the QA column stays meaningful (poly is still the KML
# geometry area; ratio > ~1.1 flags a polygon that over-extends the notified total).
if (all(c("poly_km2", "poly_census_ratio") %in% names(stats_sf))) {
  stats_sf <- stats_sf |>
    mutate(
      poly_census_ratio = ifelse(
        geometry_present & is.finite(poly_km2 / area_km2),
        round(poly_km2 / area_km2, 2),
        NA_real_
      )
    )
}

# Drop the temporary census-area helper column (keep before/after for the QA table).
stats_sf <- stats_sf |> select(-area_total_km2, -area_source_census)

# --- 8d. Verify the overwrite (task 5.4 done-when) ----------------------------
rule("STEP 9 (5.4) - verify area overwrite and area_provisional flag per row")

st <- st_drop_geometry(stats_sf)

n_overwritten <- sum(has_census_area)
n_still_prov  <- sum(st$area_provisional, na.rm = TRUE)
n_prov_na     <- sum(is.na(st$area_provisional))
cat(sprintf("reserves overwritten from census area: %d / 58\n", n_overwritten))
cat(sprintf("area_provisional == FALSE: %d | still TRUE: %d | NA: %d\n",
            sum(!st$area_provisional, na.rm = TRUE), n_still_prov, n_prov_na))

# Flag must be correct per row: FALSE exactly where a census area was applied.
prov_mismatch <- st$unit_id[ has_census_area & st$area_provisional ] |>
  union(st$unit_id[ !has_census_area & !st$area_provisional ])
if (length(prov_mismatch) > 0) {
  stop("area_provisional flag wrong for unit_id(s): ",
       paste(sort(prov_mismatch), collapse = ", "), call. = FALSE)
}
cat("area_provisional flag correct per row (FALSE iff a census area was applied)\n")

# area_source must be the census source wherever it was overwritten.
src_bad <- st$unit_id[ has_census_area & st$area_source != "ntca_notification" ]
if (length(src_bad) > 0) {
  stop("area_source not set to the census source for unit_id(s): ",
       paste(src_bad, collapse = ", "), call. = FALSE)
}
cat("area_source set to 'ntca_notification' on every overwritten row\n")

# No NA area on any overwritten reserve; national total sanity vs NTCA (~84,487).
if (any(is.na(st$area_km2[has_census_area]))) {
  stop("NA area_km2 on a reserve that should have a census area.", call. = FALSE)
}
total_area <- round(sum(st$area_km2, na.rm = TRUE), 1)
cat(sprintf("sum(area_km2) across 58 = %.1f km2 (NTCA stated ~84,487)\n", total_area))
if (abs(total_area - 84487) > 500) {
  warning("Total notified area ", total_area,
          " deviates >500 km2 from the NTCA figure; check tbl_05.")
}

# Spot the before/after on a few reserves so the change is visible.
cat("\nbefore/after (placeholder -> notified), first 5 reserves:\n")
st |> arrange(unit_id) |> slice_head(n = 5) |>
  mutate(l = sprintf("   #%d %-24s %8.1f -> %8.1f  [%s]",
                     unit_id, unit_name,
                     area_km2_provisional_old, area_km2,
                     ifelse(area_provisional, "provisional", "census"))) |>
  pull(l) |> cat(sep = "\n")
cat("\n")

# ---- QA output: area overwrite before/after ----------------------------------
area_check <- st |>
  select(unit_id, unit_name, geometry_present, census_status,
         area_km2_provisional_old, area_km2, area_provisional, area_source,
         poly_km2, poly_census_ratio) |>
  arrange(unit_id)
write_table(area_check, area_check_nn, area_check_slug)

rule("03 STAGE 5.4 done: area_km2 overwritten from notified census area (Decision 8).")

# ==============================================================================
# STEP 10 (5.5) - density_2022 (tigers per 100 km2)
# ==============================================================================
rule("STEP 10 (5.5) - density_2022 = pop_2022 / area_km2 * 100 (per 100 km2)")

# density_2022 uses the 2022 within-reserve population and the NOTIFIED total
# area (Decision 4/8: never the KML polygon area). NA propagates: a reserve with
# no pop_2022 (the 5 flagged + Sundarbans NA-within) or no area gets NA density -
# NOT 0. A REAL within-reserve zero (pop_2022 == 0, e.g. Dampa, Kawal) gives a
# real density of 0. R arithmetic already does both correctly (NA/x = NA,
# 0/x = 0); the ifelse below is only a guard against a 0 or NA area denominator.
#
# NOTE (comparability): this is density per TOTAL notified area. NTCA sometimes
# quotes reserve density against CORE area, which yields a higher number (e.g.
# Corbett). Ours is deliberately per-total-area so it is consistent across all
# reserves under Decision 8; it will not match a core-only report figure.

stats_sf <- stats_sf |>
  mutate(
    density_2022 = ifelse(
      !is.na(pop_2022) & !is.na(area_km2) & area_km2 > 0,
      round(pop_2022 / area_km2 * 100, 2),
      NA_real_
    )
  )

# --- 10a. Verify density (task 5.5 done-when) ---------------------------------
rule("STEP 11 (5.5) - verify density: NA iff pop_2022 or area missing; 0 for real zeros")

st <- st_drop_geometry(stats_sf)

n_pop22   <- sum(!is.na(st$pop_2022))
n_dens    <- sum(!is.na(st$density_2022))
n_dens_na <- sum(is.na(st$density_2022))
cat(sprintf("pop_2022 present: %d | density_2022 non-NA: %d | NA: %d\n",
            n_pop22, n_dens, n_dens_na))

# 11a. density is non-NA EXACTLY where both pop_2022 and area_km2 are present.
expect_dens <- !is.na(st$pop_2022) & !is.na(st$area_km2) & st$area_km2 > 0
mismatch <- st$unit_id[ xor(expect_dens, !is.na(st$density_2022)) ]
if (length(mismatch) > 0) {
  stop("density_2022 NA-pattern wrong for unit_id(s): ",
       paste(sort(mismatch), collapse = ", "),
       " (density must be non-NA iff pop_2022 and area_km2 both present).",
       call. = FALSE)
}
cat("density non-NA exactly where pop_2022 and area_km2 are both present: OK\n")

# 11b. Real within-reserve zeros must give density 0 (not NA).
zero_pop <- st |> filter(pop_2022 == 0)
if (nrow(zero_pop) > 0) {
  bad_zero <- zero_pop$unit_id[is.na(zero_pop$density_2022) | zero_pop$density_2022 != 0]
  if (length(bad_zero) > 0) {
    stop("Reserve(s) with pop_2022 == 0 did not get density 0: ",
         paste(bad_zero, collapse = ", "), call. = FALSE)
  }
  cat(sprintf("real within-reserve zeros -> density 0: %d reserve(s) OK\n",
              nrow(zero_pop)))
}

# 11c. Reserves that SHOULD be NA density (report them explicitly).
na_dens <- st |> filter(is.na(density_2022)) |>
  select(unit_id, unit_name, census_status, pop_2022, area_km2)
cat("\ndensity_2022 == NA (expected: 5 flagged + Sundarbans NA-within):\n")
na_dens |>
  mutate(l = sprintf("   #%d %-22s status=%s pop_2022=%s area=%s",
                     unit_id, unit_name, census_status,
                     ifelse(is.na(pop_2022), "NA", as.character(pop_2022)),
                     ifelse(is.na(area_km2), "NA", as.character(area_km2)))) |>
  pull(l) |> cat(sep = "\n")
cat("\n")

# 11d. Sanity: highest densities should be the known source populations.
cat("top 5 density_2022 (per 100 km2):\n")
st |> filter(!is.na(density_2022)) |> arrange(desc(density_2022)) |>
  slice_head(n = 5) |>
  mutate(l = sprintf("   #%d %-12s pop %s / area %.0f = %.2f",
                     unit_id, unit_name, as.character(pop_2022),
                     area_km2, density_2022)) |>
  pull(l) |> cat(sep = "\n")
cat("\n")

# ---- QA output: density check ------------------------------------------------
density_check <- st |>
  select(unit_id, unit_name, census_status, pop_2022, area_km2, area_source,
         density_2022) |>
  arrange(desc(density_2022))
write_table(density_check, density_check_nn, density_check_slug)

rule("03 STAGE 5.5 done: density_2022 computed (52 values; 6 NA: 5 flagged + Sundarbans).")
cat("NEXT (5.6): baseline_year = earliest round with a non-NA pop per reserve;\n",
    "then 5.7 write stats_reserve_census_7755.gpkg + update data-dictionary.md.\n",
    sep = "")

# `stats_sf` now also carries density_2022. Still NOT written to disk - the
# stats_reserve_census_7755.gpkg deliverable is written in 5.7 after baseline_year,
# at which point the QA-only helper columns are dropped.

# ==============================================================================
# STEP 12 (5.6) - baseline_year (earliest round with a non-NA pop per reserve)
# ==============================================================================
rule("STEP 12 (5.6) - baseline_year = earliest round with a non-NA pop per reserve")

# Decision 6/7: each reserve's baseline is its FIRST observed round - 2014 for
# the core, 2018 or 2022 for late entries. A reserve with no pop in any round
# (the 5 flagged) gets NA. baseline_year is the earliest year whose pop is
# NON-NA (not merely row-present); in this dataset the two coincide (no reserve
# has an NA-pop earliest row), but "earliest non-NA" is the correct rule.
# Change / % / AAGR are NOT computed here - that is Week 6.

st_tmp <- st_drop_geometry(stats_sf)
baseline_year <- vapply(seq_len(nrow(st_tmp)), function(i) {
  for (y in SERIES_YEARS) {
    v <- st_tmp[[paste0("pop_", y)]][i]
    if (!is.na(v)) return(y)
  }
  NA_integer_
}, integer(1))
stats_sf$baseline_year <- baseline_year

# --- 12a. Verify baseline_year -----------------------------------------------
st <- st_drop_geometry(stats_sf)
cat("baseline_year distribution:\n")
bt <- table(st$baseline_year, useNA = "ifany")
bt_names <- names(bt)
for (k in seq_along(bt)) {
  lbl <- bt_names[k]
  if (is.na(lbl) || lbl == "") lbl <- "NA"
  cat(sprintf("   %s: %d\n", lbl, bt[[k]]))
}

# Every measured reserve must have a baseline; every flagged reserve must be NA.
meas_no_base <- st$unit_id[st$census_status == "measured" & is.na(st$baseline_year)]
flag_has_base <- st$unit_id[
  st$census_status == "not_estimated_post2022_notification" & !is.na(st$baseline_year)]
if (length(meas_no_base) > 0) {
  stop("Measured reserve(s) with no baseline_year: ",
       paste(meas_no_base, collapse = ", "), call. = FALSE)
}
if (length(flag_has_base) > 0) {
  stop("Flagged reserve(s) unexpectedly have a baseline_year: ",
       paste(flag_has_base, collapse = ", "), call. = FALSE)
}
cat("baseline_year present for all measured, NA for all flagged: OK\n")

# ==============================================================================
# STEP 13 (5.7) - assemble final schema and write stats_reserve_census_7755.gpkg
# ==============================================================================
rule("STEP 13 (5.7) - write stats_reserve_census_7755.gpkg")

# Drop the QA-only helper columns carried since 5.4. They live in
# tbl_08_area_overwrite_check.csv; they are not part of the deliverable layer.
stats_sf <- stats_sf |> select(-any_of(c("area_km2_provisional_old",
                                         "area_source_old")))

# Final column order. Week-6 growth metrics (change_abs/change_pct/aagr) are NOT
# added yet - they are computed and appended in Week 6, and the data-dictionary
# marks them as such. poly_km2 / poly_census_ratio are kept as documented QA
# diagnostics (recomputed against the notified area in 5.4).
final_cols <- c(
  "unit_id", "unit_name", "unit_name_std", "state", "landscape_complex",
  "area_km2", "area_provisional", "area_source",
  "pop_2014", "pop_2018", "pop_2022",
  "density_2022", "baseline_year", "census_status",
  "n_parts", "match_status", "geometry_present", "source",
  "poly_km2", "poly_census_ratio"
)
present_cols <- intersect(final_cols, names(stats_sf))
missing_final <- setdiff(final_cols, names(stats_sf))
if (length(missing_final) > 0) {
  # Not fatal - report what the boundary layer did not supply, then proceed with
  # what is present (keeps the script robust to minor scripts/02 schema drift).
  warning("expected column(s) not on the layer, omitted from output: ",
          paste(missing_final, collapse = ", "))
}
# Keep the geometry column; select the present analysis columns in order.
stats_sf <- stats_sf |> select(all_of(present_cols))

# Final guards before writing.
stopifnot(nrow(stats_sf) == 58L)
stopifnot(!any(duplicated(stats_sf$unit_id)))
stopifnot(inherits(stats_sf, "sf"))
cat("final layer: ", nrow(stats_sf), " reserves, ",
    length(present_cols), " attribute columns + geometry\n", sep = "")
cat("columns: ", paste(present_cols, collapse = ", "), "\n", sep = "")

# Write via the project IO helper (writes to DIR_PROCESSED, delete_dsn = TRUE).
write_processed_vec(stats_sf, stats_out)

# Confirm the write round-trips: re-read and check row count + key fields.
stats_back <- read_vec(file.path(DIR_PROCESSED, stats_out))
cat("re-read check: ", nrow(stats_back), " reserves | ",
    sum(!is.na(stats_back$density_2022)), " with density | ",
    sum(stats_back$census_status == "measured", na.rm = TRUE), " measured\n",
    sep = "")
stopifnot(nrow(stats_back) == 58L)

rule("03 STAGE 5.7 done: stats_reserve_census_7755.gpkg written (58 reserves).")
cat("Week-5 deliverable complete: wide census + notified area + density_2022 +\n",
    "baseline_year + census_status, all 58 reserves.\n",
    "REMAINING Week-5 housekeeping (not in this script):\n",
    "  - task 5.8: eyeball the 6 crosswalk 'review' rows in tbl_07/tbl_09.\n",
    "  - task 5.9: reconcile R/00_config.R BASELINE_YEAR/CENSUS_YEARS to Decision 6.\n",
    "  - update docs/data-dictionary.md (stats layer as-built; change/AAGR = Week 6).\n",
    "Week 6: change_abs / change_pct / aagr on the 2014->2022 span.\n", sep = "")