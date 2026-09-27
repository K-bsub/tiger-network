# =============================================================================
# 07_connectivity.R  [STAGE 2 — CONNECTIVITY, Weeks 9-12]
# One script for the whole connectivity track (fix-pass Decision C, 2026-09-26).
# Each week adds its own STEP blocks to this file:
#
#   WEEK 9  — resistance surface
#     STEP 9.2  Decision-10 gHM gap-fill relevance check (rule: Decision 11)
#     STEP 9.5  land cover x gHM (Decision 14): class values, Sundarban
#               water override, gHM multiplier (water exempt, Decision 16), cap
#     STEP 9.6  road barrier (Decision 15): maximum rule
#     STEP 9.7  asserts + write resist_tiger_<surface>_7755.tif (baseline,
#               noghm, road15, road50)
#     STEP 9.8  resistance QA -> tbl_11_resistance_qa.csv
#   WEEK 10 — least-cost paths between neighbouring reserve pairs  TODO(Week 10)
#   WEEK 11 — reserve network graph (igraph)                       TODO(Week 11)
#   WEEK 12 — road pinch points + fig_04 / tbl_03                  TODO(Week 12)
#
# Tasks 9.3 and 9.4 (resistance values, barrier road classes) are numbered
# Decisions (14 and 15) recorded in docs/methodology.md BEFORE their STEPs are
# written.
# Their values are read from R/00_config.R, never hardcoded here.
#
# -----------------------------------------------------------------------------
# STEP 9.2 — WHAT IT DOES
#   Decision 10 applied a common NA mask to the covariate stack. In the Week-8
#   build gHM was the binding layer and 56,827 India-grid cells (1.85%) were
#   NA in every band; after Decisions 11-13 the final (d13f) stack drops 98.
#   This step checks whether those cells matter where connectivity happens,
#   using the rule fixed in Decision 11 BEFORE the check was run:
#     - units:      55 reserve polygons (geometry present), the 59 NTCA
#                   corridor polygons, and a GAP_BUFFER_M ring outside each
#                   reserve polygon (the approach zone paths must cross)
#     - membership: any cell the polygon touches (terra::extract touches = TRUE)
#     - counted:    India-grid LAND cells (WorldCover != GAP_WATER_CLASS);
#                   water cells are reported, not counted. An India cell with no
#                   WorldCover class counts as land (conservative).
#     - material:   >= GAP_MIN_PCT % of the unit's land cells dropped, OR
#                   >= GAP_MIN_CELLS dropped land cells
#     - outcome:    ANY material unit -> the Decision-11 gHM fill applies and
#                   the stack is rebuilt; NONE -> Decision 10 closes with
#                   "no fill needed"
#   STEP 9.2 only measures and reports. It does NOT fill or rebuild anything;
#   the fill lives in scripts/06 STEP 8.4b (switch GHM_GAP_FILL).
#
#   RUN LABEL (Decision 11/12/13 outcome record), read from tbl_10:
#     n_filled = 0 for gHM                          -> "prefill"
#     n_filled > 0 and a build_tag column           -> "postfill_<build_tag>"
#                                                      (from Decision 13 on)
#     n_filled > 0, lc_source == "tile_cache" only  -> "postfill_d12" (legacy)
#     n_filled > 0, neither column                  -> "postfill"     (legacy)
#     Output names carry the label, so no earlier result is overwritten by a
#     later re-check.
#     - prefill run TRIGGERED  -> apply the fill (done 2026-09-26).
#     - postfill run clear     -> Decision 10 closes: the common mask on the
#                                 filled stack is final.
#     - postfill run TRIGGERED -> STOP. Decision 11 (H3): decide again before
#                                 STEP 9.3. No further automatic fill.
#                                 (Happened 2026-09-26 -> Decision 12.)
#     - postfill_d12 run       -> STILL TRIGGERED (terrain edge shift) ->
#                                 Decision 13.
#     - postfill_<tag> runs    -> same rule: clear closes Decision 10;
#                                 triggered -> STOP and decide again.
#
# INPUTS:
#   data/processed/cov_stack_1km_7755.tif              (scripts/06)
#   data/interim/cov_distroad_1km_7755.tif             (scripts/06; its valid
#                                                       footprint = India grid)
#   data/interim/cov_landcover_worldcover2021_aligned_1km_7755.tif
#                                                      (scripts/06, Decision 12:
#                                                       land cover on the stack
#                                                       grid, India-masked,
#                                                       before the common mask)
#   data/interim/boundary_india_national_7755.gpkg     (scripts/01; for the
#                                                       no-class distance report)
#   data/processed/boundary_reserves_all_7755.gpkg     (scripts/02)
#   data/processed/boundary_corridors_7755.gpkg        (scripts/02, task 9.2a)
#   outputs/tables/tbl_10_covariate_stack_qa.csv       (scripts/06; cross-check)
#
# OUTPUTS (STEP 9.2; <state> = prefill | postfill, from tbl_10 n_filled):
#   (<state> = prefill | postfill | postfill_d12 | postfill_<build_tag>)
#   data/interim/cov_commonmask_dropped_<state>_1km_7755.tif
#                                     dropped India cells, value = WorldCover
#                                     class (0 = no class), else NA
#   outputs/tables/tbl_11_ghm_gap_relevance_<state>.csv   one row per unit
#     (tbl_11 is shared with the Week-9 resistance QA table under the
#      naming-conventions §6 rule: numbers group, slugs identify.)
#
# MACHINE TRAP: same PROJ / PostGIS proj.db clash as scripts/06. Run in a FRESH
# session; the guard below stops if EPSG:7755 does not resolve.
# =============================================================================

# ---- Prerequisites ----------------------------------------------------------
suppressPackageStartupMessages({
  library(here)
  library(terra)
  library(sf)
  library(dplyr)
})

source(here("R", "00_config.R"))        # CRS, DIR_*, Decision-11 GAP_* values
source(here("R", "00_functions_io.R"))  # read_vec, write_processed_rast, write_table

rule <- function(txt) cat("\n", strrep("=", 78), "\n", txt, "\n",
                          strrep("=", 78), "\n", sep = "")

# ---- Paths ------------------------------------------------------------------
stack_in     <- file.path(DIR_PROCESSED, "cov_stack_1km_7755.tif")
distroad_in  <- file.path(DIR_INTERIM,   "cov_distroad_1km_7755.tif")
lc_in        <- file.path(DIR_INTERIM,
                          "cov_landcover_worldcover2021_aligned_1km_7755.tif")
india_in     <- file.path(DIR_INTERIM,   "boundary_india_national_7755.gpkg")
reserves_in  <- file.path(DIR_PROCESSED, "boundary_reserves_all_7755.gpkg")
corridors_in <- file.path(DIR_PROCESSED, "boundary_corridors_7755.gpkg")
roads_in     <- file.path(DIR_RAW, "osm", "osm_roads_major_7755.gpkg")   # STEP 9.6
tbl10_in     <- file.path(DIR_TABLES,    "tbl_10_covariate_stack_qa.csv")

# Output names carry the fill state; they are set in STEP 9.2a once tbl_10 is
# read (dropped_out, gap_slug).

# ---- Guards (fail early) ----------------------------------------------------
# 1) Decision-11 parameters must come from config.
gap_params <- c("GAP_BUFFER_M", "GAP_MIN_PCT", "GAP_MIN_CELLS",
                "GAP_WATER_CLASS", "GAP_FILL_WINDOW", "GAP_FILL_MAX_ITER",
                "GHM_GAP_FILL")
missing_params <- gap_params[!vapply(gap_params, exists, logical(1))]
if (length(missing_params) > 0) {
  stop("Decision-11 parameter(s) missing from R/00_config.R: ",
       paste(missing_params, collapse = ", "), call. = FALSE)
}

# 2) The analysis CRS must resolve in this session (PROJ proj.db clash).
crs_wkt <- terra::crs(terra::rast(crs = paste0("EPSG:", CRS_ANALYSIS)))
if (!nzchar(crs_wkt) || !grepl("India", crs_wkt)) {
  stop("EPSG:", CRS_ANALYSIS, " did not resolve to the India NSF LCC frame. ",
       "Restart R so .Rprofile pins PROJ_LIB before terra loads, then re-run.",
       call. = FALSE)
}

# 3) Every input must exist.
inputs <- c(stack_in, distroad_in, lc_in, india_in, reserves_in, corridors_in,
            tbl10_in)
missing_inputs <- inputs[!file.exists(inputs)]
if (length(missing_inputs) > 0) {
  stop("Missing required input(s):\n  ", paste(missing_inputs, collapse = "\n  "),
       "\nboundary_corridors_7755.gpkg comes from the Week-9 re-run of ",
       "scripts/02 (task 9.2a).", call. = FALSE)
}

rule("07_connectivity.R — inputs found; CRS OK; Decision-11 parameters loaded")
cat(sprintf(paste0("Decision 11: buffer %d m | material if >= %s%% or >= %d ",
                   "dropped land cells | water class %d not counted\n"),
            GAP_BUFFER_M, format(GAP_MIN_PCT), GAP_MIN_CELLS, GAP_WATER_CLASS))

# =============================================================================
# STEP 9.2a — the dropped-cell layer
# =============================================================================
# India grid  = valid cells of cov_distroad (masked to the India polygon exactly
#               in scripts/06 STEP 8.4; 3,067,565 cells as built).
# Dropped     = India-grid cells where the stack is NA (the Decision-10 mask).
# Land class  = WorldCover class BEFORE the common mask, as scripts/06 wrote it
#               (Decision 12: already on the stack grid and masked to India).

rule("STEP 9.2a — dropped-cell layer (India cells removed by the common mask)")

cov_stack <- terra::rast(stack_in)
stopifnot("stack must carry a 'landcover' band" = "landcover" %in% names(cov_stack))
dist_road <- terra::rast(distroad_in)
if (!isTRUE(terra::compareGeom(dist_road, cov_stack, stopOnError = FALSE,
                               crs = TRUE, ext = TRUE, rowcol = TRUE, res = TRUE))) {
  stop("cov_distroad does not match the stack grid.", call. = FALSE)
}

india_r <- !is.na(dist_road)                        # TRUE inside India, else FALSE

# Land cover before the common mask, as scripts/06 wrote it (Decision 12).
lc_full <- terra::rast(lc_in)
if (!isTRUE(terra::compareGeom(lc_full, cov_stack, stopOnError = FALSE,
                               crs = TRUE, ext = TRUE, rowcol = TRUE, res = TRUE))) {
  stop("aligned land cover does not match the stack grid — re-run scripts/06.",
       call. = FALSE)
}
names(lc_full) <- "lc"

# Consistency check: where the stack has a value, this land cover must equal the
# stack's landcover band exactly. A mismatch means the two files come from
# different scripts/06 runs, and every count below would be wrong.
n_mismatch <- terra::global(lc_full != cov_stack[["landcover"]], "sum",
                            na.rm = TRUE)[[1]]
if (!isTRUE(n_mismatch == 0)) {
  stop("Aligned land cover differs from the stack landcover band in ",
       n_mismatch, " cells — re-run scripts/06 so both come from one run.",
       call. = FALSE)
}

# India cells only; an India cell with no WorldCover class gets code 0.
lc_full <- terra::mask(lc_full, india_r, maskvalues = FALSE)
lc_full <- terra::ifel(india_r & is.na(lc_full), 0L, lc_full)

dropped_r <- india_r & is.na(cov_stack[["landcover"]])   # TRUE = removed India cell
names(dropped_r) <- "dropped"

n_india   <- terra::global(india_r,   "sum", na.rm = TRUE)[[1]]
n_dropped <- terra::global(dropped_r, "sum", na.rm = TRUE)[[1]]

# Cross-check against the saved Week-8 QA (pull figures from data, not prose).
tbl10 <- utils::read.csv(tbl10_in, stringsAsFactors = FALSE)
if (!all(c("n_dropped_by_mask", "n_filled") %in% names(tbl10))) {
  stop("tbl_10 lacks n_dropped_by_mask and/or n_filled — re-run scripts/06 ",
       "(the Week-9 version with STEP 8.4b) first.", call. = FALSE)
}

# Fill state from the saved QA, not from the config switch: the label must
# describe the stack on disk.
ghm_filled <- tbl10$n_filled[tbl10$band == "ghm"]
has_tag    <- "build_tag" %in% names(tbl10) &&
  length(unique(tbl10$build_tag)) == 1L && !is.na(tbl10$build_tag[1]) &&
  nzchar(tbl10$build_tag[1])
lc_fixed   <- "lc_source" %in% names(tbl10) && any(tbl10$lc_source == "tile_cache")
fill_state <- if (!isTRUE(ghm_filled > 0)) {
  "prefill"
} else if (has_tag) {
  paste0("postfill_", tbl10$build_tag[1])
} else if (lc_fixed) {
  "postfill_d12"
} else {
  "postfill"
}
dropped_out <- file.path(DIR_INTERIM,
                         paste0("cov_commonmask_dropped_", fill_state,
                                "_1km_7755.tif"))
gap_slug <- paste0("ghm_gap_relevance_", fill_state)
cat("stack state:", toupper(fill_state), "| gHM cells filled (tbl_10):",
    format(ghm_filled, big.mark = ","), "\n")
if (isTRUE(GHM_GAP_FILL) && fill_state == "prefill") {
  warning("GHM_GAP_FILL is TRUE but tbl_10 shows no filled cells — the stack ",
          "on disk was built without the fill. Re-run scripts/06.")
}
tbl10_drop <- tbl10$n_dropped_by_mask[tbl10$band == "dist_road_m"]
if (!isTRUE(n_dropped == tbl10_drop)) {
  stop("Dropped India cells here (", n_dropped, ") differ from tbl_10 ",
       "dist_road_m n_dropped_by_mask (", tbl10_drop, ").", call. = FALSE)
}
cat("India-grid cells:", format(n_india, big.mark = ","),
    "| dropped by the common mask:", format(n_dropped, big.mark = ","),
    sprintf("(%.2f%%) — matches tbl_10\n", 100 * n_dropped / n_india))

# Dropped-cell layer: WorldCover class where dropped, NA elsewhere.
dropped_class <- terra::ifel(dropped_r, lc_full, NA)
names(dropped_class) <- "dropped_lc_class"
write_processed_rast(dropped_class, basename(dropped_out), dir = dirname(dropped_out),
                     datatype = "INT2U")   # class codes 0-100; integer by design
cat("\n")

# National class breakdown of the dropped cells (land vs water vs no class).
dc_freq <- terra::freq(dropped_class)
dc_freq <- dc_freq[order(-dc_freq$count), c("value", "count")]
names(dc_freq) <- c("worldcover_class", "n_dropped_cells")
cat("dropped India cells by WorldCover class (0 = no class):\n")
print(dc_freq, row.names = FALSE)
n_drop_water <- sum(dc_freq$n_dropped_cells[dc_freq$worldcover_class == GAP_WATER_CLASS])
cat(sprintf("  water (class %d): %s | land (all other classes): %s\n",
            GAP_WATER_CLASS, format(n_drop_water, big.mark = ","),
            format(n_dropped - n_drop_water, big.mark = ",")))

# No-class report (Decision 12). Distance from each dropped no-class cell
# (class 0) to the India boundary. Edge-offset cells sit within about one cell
# of the boundary; cells farther in are interior gaps that Decision 12 does not
# address. The 1.5-cell cut-off is a reporting aid, not a rule.
nc_pts <- terra::as.points(terra::classify(dropped_class, cbind(0, 1), others = NA))
if (nrow(nc_pts) > 0) {
  india_lines <- terra::as.lines(terra::vect(india_in))
  nc_dist <- as.vector(terra::distance(nc_pts, india_lines))
  n_interior <- sum(nc_dist > 1.5 * GRID_CELL_M)
  cat("\ndropped no-class cells:", format(length(nc_dist), big.mark = ","),
      "| distance to the India boundary (m):\n")
  print(summary(nc_dist))
  cat("  within 1.5 cells of the boundary:",
      format(length(nc_dist) - n_interior, big.mark = ","),
      "| farther in (interior gaps):", format(n_interior, big.mark = ","), "\n")
  # Decision 13 (O1): the interior no-class cells are accepted and listed.
  # Print their cell centres (EPSG:7755, metres) so the record is exact.
  if (n_interior > 0 && n_interior <= 50) {
    int_xy <- terra::crds(nc_pts)[nc_dist > 1.5 * GRID_CELL_M, , drop = FALSE]
    int_tbl <- data.frame(x_7755 = int_xy[, 1], y_7755 = int_xy[, 2],
                          dist_boundary_m = round(nc_dist[nc_dist > 1.5 * GRID_CELL_M]))
    cat("  interior no-class cells (cell centres, EPSG:7755):\n")
    print(int_tbl[order(int_tbl$dist_boundary_m), ], row.names = FALSE)
  }
} else {
  cat("\ndropped no-class cells: 0\n")
}

# =============================================================================
# STEP 9.2b — footprint units: reserves, corridors, reserve buffer rings
# =============================================================================
rule("STEP 9.2b — footprint units (reserves, corridors, buffer rings)")

reserves_sf <- read_vec(reserves_in)
res_geo     <- reserves_sf[reserves_sf$geometry_present, ]
res_absent  <- reserves_sf[!reserves_sf$geometry_present, ]

# One column set for every unit type, so the three sets bind cleanly.
as_units <- function(x, unit_type, unit_id, unit_name, state,
                     landscape_complex, poly_census_ratio) {
  st_sf(
    unit_type         = unit_type,
    unit_id           = as.integer(unit_id),
    unit_name         = as.character(unit_name),
    state             = as.character(state),
    landscape_complex = as.character(landscape_complex),
    poly_census_ratio = as.numeric(poly_census_ratio),
    geometry          = st_geometry(x)
  )
}

# Reserves (core-PA polygons — Decision 4 limitation applies).
res_units <- as_units(res_geo, "reserve", res_geo$unit_id, res_geo$unit_name,
                      res_geo$state, res_geo$landscape_complex,
                      res_geo$poly_census_ratio)

# Buffer rings: the GAP_BUFFER_M zone OUTSIDE each reserve polygon.
res_g <- st_geometry(res_geo)
ring_g <- do.call(c, lapply(seq_along(res_g), function(i) {
  st_difference(st_buffer(res_g[i], GAP_BUFFER_M), res_g[i])
}))
buf_units <- as_units(st_sf(geometry = ring_g), "buffer", res_geo$unit_id,
                      paste0(res_geo$unit_name, " (", GAP_BUFFER_M / 1000,
                             " km ring)"),
                      res_geo$state, res_geo$landscape_complex,
                      res_geo$poly_census_ratio)

# NTCA corridor polygons (from scripts/02, task 9.2a). A corridor with no label
# keeps an explicit placeholder name with its id, not an invented name.
corr_sf <- read_vec(corridors_in)
corr_name <- ifelse(is.na(corr_sf$corridor_label),
                    paste0("corridor_", corr_sf$corridor_id, " (no label)"),
                    corr_sf$corridor_label)
corr_units <- as_units(corr_sf, "corridor", corr_sf$corridor_id, corr_name,
                       corr_sf$state, NA_character_, NA_real_)

units_sf <- rbind(res_units, buf_units, corr_units)

# terra::vect() cannot take GEOMETRYCOLLECTION features (st_make_valid in
# scripts/02 can produce them). Keep the polygon parts of any such feature, then
# cast every unit to MULTIPOLYGON so the set has one geometry type.
polys_only <- function(g) {
  gt <- as.character(st_geometry_type(g))
  for (i in which(gt == "GEOMETRYCOLLECTION")) {
    g[i] <- st_union(st_collection_extract(g[i], "POLYGON"))
  }
  st_cast(g, "MULTIPOLYGON")
}
st_geometry(units_sf) <- polys_only(st_geometry(units_sf))
units_sf$unit_key <- seq_len(nrow(units_sf))
cat("units:", nrow(res_units), "reserves |", nrow(buf_units), "buffer rings |",
    nrow(corr_units), "corridors | total", nrow(units_sf), "\n")
if (nrow(res_absent) > 0) {
  cat("NOT checkable (no KML geometry):",
      paste(res_absent$unit_name, collapse = ", "), "\n")
}

# =============================================================================
# STEP 9.2c — count cells per unit and apply the Decision-11 rule
# =============================================================================
rule("STEP 9.2c — per-unit counts and the Decision-11 materiality rule")

# touches = TRUE: every cell a polygon touches (Decision 11, membership rule).
cls_r <- c(lc_full, dropped_r)
ex <- terra::extract(cls_r, terra::vect(units_sf), touches = TRUE, ID = TRUE)

# Keep India cells only (lc is NA outside the India grid).
counts <- ex |>
  filter(!is.na(lc)) |>
  mutate(is_water = lc == GAP_WATER_CLASS,
         is_drop  = as.logical(dropped)) |>
  group_by(ID) |>
  summarise(
    n_india_cells   = n(),
    n_land          = sum(!is_water),
    n_water         = sum(is_water),
    n_dropped_land  = sum(is_drop & !is_water),
    n_dropped_water = sum(is_drop & is_water),
    .groups = "drop"
  )

gap_tbl <- units_sf |>
  st_drop_geometry() |>
  left_join(counts, by = c("unit_key" = "ID")) |>
  mutate(
    across(c(n_india_cells, n_land, n_water, n_dropped_land, n_dropped_water),
           ~ ifelse(is.na(.x), 0L, .x)),
    pct_dropped_land = ifelse(n_land > 0,
                              round(100 * n_dropped_land / n_land, 2), NA_real_),
    material = (!is.na(pct_dropped_land) & pct_dropped_land >= GAP_MIN_PCT) |
               (n_dropped_land >= GAP_MIN_CELLS),
    checked  = TRUE,
    note     = case_when(
      n_india_cells == 0 ~ "no India-grid cells in this unit",
      !is.na(poly_census_ratio) & poly_census_ratio > 1.1 ~
        "reserve polygon over-extends the notified area (Decision 4 limitation)",
      TRUE ~ NA_character_
    )
  )

# Geometry-absent reserves: listed, never counted.
if (nrow(res_absent) > 0) {
  absent_tbl <- res_absent |>
    st_drop_geometry() |>
    transmute(unit_type = "reserve", unit_id = as.integer(unit_id),
              unit_name, state, landscape_complex,
              poly_census_ratio = NA_real_, unit_key = NA_integer_,
              n_india_cells = NA_integer_, n_land = NA_integer_,
              n_water = NA_integer_, n_dropped_land = NA_integer_,
              n_dropped_water = NA_integer_, pct_dropped_land = NA_real_,
              material = NA, checked = FALSE,
              note = "geometry absent in the NTCA KML — cannot be checked")
  gap_tbl <- bind_rows(gap_tbl, absent_tbl)
}

gap_tbl <- gap_tbl |>
  arrange(desc(material), desc(n_dropped_land), unit_type, unit_id) |>
  select(unit_type, unit_id, unit_name, state, landscape_complex,
         n_india_cells, n_land, n_water, n_dropped_land, n_dropped_water,
         pct_dropped_land, material, checked, note)

write_table(gap_tbl, nn = 11, slug = gap_slug)

# ---- Console summary ---------------------------------------------------------
by_type <- gap_tbl |>
  filter(checked) |>
  group_by(unit_type) |>
  summarise(units = n(), with_drop = sum(n_dropped_land > 0),
            n_material = sum(material), dropped_land = sum(n_dropped_land),
            dropped_water = sum(n_dropped_water), .groups = "drop")
cat("\nper unit type (units / units with any dropped land cell / material /",
    "dropped land cells / dropped water cells):\n")
print(as.data.frame(by_type), row.names = FALSE)

fails <- gap_tbl |> filter(material %in% TRUE)
if (nrow(fails) > 0) {
  cat("\nMATERIALLY AFFECTED units (Decision 11):\n")
  print(as.data.frame(fails |>
          select(unit_type, unit_id, unit_name, n_land, n_dropped_land,
                 n_dropped_water, pct_dropped_land)), row.names = FALSE)
}

near <- gap_tbl |>
  filter(checked, !material, n_dropped_land > 0) |>
  arrange(desc(pct_dropped_land)) |>
  head(10)
if (nrow(near) > 0) {
  cat("\nlargest NON-material losses (top 10, for context):\n")
  print(as.data.frame(near |>
          select(unit_type, unit_name, n_land, n_dropped_land,
                 pct_dropped_land)), row.names = FALSE)
}

triggered <- any(gap_tbl$material, na.rm = TRUE)
outcome <- if (fill_state == "prefill") {
  if (triggered) {
    paste0("DECISION 11 (PRE-FILL): TRIGGERED — ", nrow(fails),
           " unit(s) materially affected. Set GHM_GAP_FILL <- TRUE, re-run ",
           "scripts/06, then re-run this script for the post-fill check.")
  } else {
    paste0("DECISION 11 (PRE-FILL): NOT TRIGGERED — no unit materially ",
           "affected. Decision 10 closes with 'no fill needed'.")
  }
} else {
  if (triggered) {
    paste0("DECISION 11 (", toupper(fill_state), "): STILL TRIGGERED — ", nrow(fails),
           " unit(s) materially affected after the bounded fill. STOP: per ",
           "Decision 11 (H3), decide again before STEP 9.3. Do not add passes.")
  } else {
    paste0("DECISION 11 (", toupper(fill_state), "): CLEAR — no unit materially affected. ",
           "Decision 10 closes: the common mask on the filled stack is final.")
  }
}
rule(paste(outcome, "Record the outcome in methodology.md before STEP 9.3."))

# =============================================================================
# STEP 9.5-9.8 — resistance surfaces (Decisions 14 + 15)
# =============================================================================
# Rules are fixed in docs/methodology.md (Decision 14: class values, Sundarban
# water region, gHM multiplier, cap; Decision 15: barrier roads, value, maximum
# rule, touches). Every value is read from R/00_config.R.
#
# Order of operations (Decision 14 point 5; Decision 15 point 3):
#   class value -> Sundarban water override -> x (1 + k * gHM), except on the
#   Decision-16 exempt classes (water) -> cap at RESIST_MAX -> on barrier-road
#   cells: max(surface, road value)
#
# Surfaces built: "baseline" (k = RESIST_GHM_K, road = ROAD_BARRIER_VALUE) and
# every entry of RESIST_VARIANTS (noghm, road15, road50). Each variant changes
# ONE choice against the baseline.
#
# Footprint: the complete-case cells of the stack (Decision 10; 3,067,467 in the
# d13f build). Every surface must have a value on every footprint cell and no
# value outside it.

# Resistance steps run only on a stack where Decision 10 is closed.
if (isTRUE(triggered)) {
  stop("STEP 9.2 is TRIGGERED on this stack — Decision 10 is not closed. ",
       "Resistance surfaces are not built. Decide again before STEP 9.5.",
       call. = FALSE)
}

# ---- Guards: Decision-14/15 settings must come from config ------------------
resist_params <- c("WORLDCOVER_RESISTANCE", "RESIST_MAX", "RESIST_GHM_K",
                   "RESIST_WATER_CLASS", "RESIST_WATER_REGION_UNIT_IDS",
                   "RESIST_WATER_REGION_NAMES", "RESIST_WATER_REGION_BUFFER_M",
                   "RESIST_WATER_REGION_VALUE", "ROAD_BARRIER_CLASSES",
                   "ROAD_BARRIER_VALUE", "ROAD_BARRIER_TOUCHES", "RESIST_VARIANTS",
                   "RESIST_GHM_EXEMPT_CLASSES")
missing_resist <- resist_params[!vapply(resist_params, exists, logical(1))]
if (length(missing_resist) > 0) {
  stop("Decision-14/15 setting(s) missing from R/00_config.R: ",
       paste(missing_resist, collapse = ", "), call. = FALSE)
}
if (!file.exists(roads_in)) {
  stop("Missing road layer: ", roads_in, call. = FALSE)
}

# All surfaces to build: baseline first, then the variants.
surfaces <- c(list(baseline = list(ghm_k = RESIST_GHM_K,
                                   road_value = ROAD_BARRIER_VALUE)),
              RESIST_VARIANTS)
stopifnot(
  "surface names must be unique" = !anyDuplicated(names(surfaces)),
  "every road value must be within 1..RESIST_MAX" =
    all(vapply(surfaces, function(v) v$road_value >= 1 &&
                 v$road_value <= RESIST_MAX, logical(1))),
  "every gHM k must be >= 0" =
    all(vapply(surfaces, function(v) v$ghm_k >= 0, logical(1)))
)

lc_r     <- cov_stack[["landcover"]]
ghm_r    <- cov_stack[["ghm"]]
tmpl_r   <- lc_r                                  # the stack grid
foot_r   <- !is.na(lc_r)                          # complete-case footprint
n_foot   <- terra::global(foot_r, "sum", na.rm = TRUE)[[1]]

# =============================================================================
# STEP 9.5 — land cover x gHM (Decision 14)
# =============================================================================
rule("STEP 9.5 — land-cover resistance, Sundarban water override, gHM multiplier")

# ---- 9.5a Class values: every class present must have a value ---------------
lc_present <- sort(terra::unique(lc_r)[[1]])
lc_known   <- as.numeric(names(WORLDCOVER_RESISTANCE))
lc_unmapped <- setdiff(lc_present, lc_known)
if (length(lc_unmapped) > 0) {
  stop("Land-cover class(es) in the stack with no resistance value: ",
       paste(lc_unmapped, collapse = ", "), call. = FALSE)
}
rcl <- cbind(lc_known, as.numeric(WORLDCOVER_RESISTANCE))
base_r <- terra::classify(lc_r, rcl, others = NA)
names(base_r) <- "resist_class"
n_leak <- terra::global(foot_r & is.na(base_r), "sum", na.rm = TRUE)[[1]]
if (!isTRUE(n_leak == 0)) {
  stop("Class lookup left ", n_leak, " footprint cells without a value.",
       call. = FALSE)
}
class_tab <- as.data.frame(terra::freq(lc_r))[, c("value", "count")]
names(class_tab) <- c("worldcover_class", "n_cells")
class_tab$resist_value <- as.numeric(
  WORLDCOVER_RESISTANCE[as.character(class_tab$worldcover_class)])
cat("classes present:", length(lc_present), "| all mapped\n")

# ---- 9.5b Sundarban water region (Decision 14 point 3) -----------------------
# Region = the named reserve polygon(s) + RESIST_WATER_REGION_BUFFER_M ring.
# Cell membership follows the Decision-11 rule (every cell the region touches),
# because the ring is the Decision-11 buffer; Decision 14 does not state a
# separate rule.
region_sf <- reserves_sf[reserves_sf$unit_id %in% RESIST_WATER_REGION_UNIT_IDS, ]
if (nrow(region_sf) != length(RESIST_WATER_REGION_UNIT_IDS) ||
    !all(region_sf$geometry_present) ||
    !setequal(region_sf$unit_name, RESIST_WATER_REGION_NAMES)) {
  stop("Water-region reserve(s) do not resolve: unit_id ",
       paste(RESIST_WATER_REGION_UNIT_IDS, collapse = ", "), " gave '",
       paste(region_sf$unit_name, collapse = ", "), "' (expected '",
       paste(RESIST_WATER_REGION_NAMES, collapse = ", "),
       "', with geometry).", call. = FALSE)
}
region_g <- st_union(st_buffer(st_geometry(region_sf), RESIST_WATER_REGION_BUFFER_M))
region_r <- terra::rasterize(terra::vect(st_sf(geometry = region_g)), tmpl_r,
                             field = 1, background = 0, touches = TRUE)
water_override <- (region_r == 1) & (lc_r == RESIST_WATER_CLASS)
n_override <- terra::global(water_override, "sum", na.rm = TRUE)[[1]]
base_r <- terra::ifel(water_override, RESIST_WATER_REGION_VALUE, base_r)
cat("Sundarban water region: ", format(n_override, big.mark = ","),
    " water cells set to ", RESIST_WATER_REGION_VALUE, " (class-", RESIST_WATER_CLASS,
    " value elsewhere: ", WORLDCOVER_RESISTANCE[[as.character(RESIST_WATER_CLASS)]],
    ")\n", sep = "")
if (n_override == 0) {
  warning("The Sundarban water override changed no cell — check the region.")
}

# ---- 9.5c gHM multiplier + cap, one surface per distinct k -------------------
# Decision 16: the multiplier is NOT applied to RESIST_GHM_EXEMPT_CLASSES
# (water). gHM over water is imputed (Decision-11 fill), so water keeps its
# land-cover value (50, or 10 in the Sundarban region).
exempt_r <- lc_r %in% RESIST_GHM_EXEMPT_CLASSES
n_exempt <- terra::global(exempt_r, "sum", na.rm = TRUE)[[1]]
cat("cells exempt from the gHM multiplier (Decision 16, classes ",
    paste(RESIST_GHM_EXEMPT_CLASSES, collapse = ", "), "): ",
    format(n_exempt, big.mark = ","), "\n", sep = "")

lcghm_by_k <- list()
for (k in unique(sapply(surfaces, function(v) as.numeric(v$ghm_k)))) {
  mult_k <- terra::ifel(exempt_r, 1, 1 + k * ghm_r)
  s_k    <- base_r * mult_k
  n_capped <- terra::global(s_k > RESIST_MAX, "sum", na.rm = TRUE)[[1]]
  s_k    <- terra::clamp(s_k, upper = RESIST_MAX, values = TRUE)
  lcghm_by_k[[as.character(k)]] <- s_k
  cat(sprintf("k = %s: land cover x gHM built; %s cells capped at %s\n",
              format(k), format(n_capped, big.mark = ","), RESIST_MAX))
}

# =============================================================================
# STEP 9.6 — road barrier (Decision 15)
# =============================================================================
rule("STEP 9.6 — road barrier (maximum rule)")

roads_sf <- read_vec(roads_in)
if (!"highway" %in% names(roads_sf)) {
  stop("Road layer has no 'highway' field: ", roads_in, call. = FALSE)
}
roads_sf$road_class <- sub("_link$", "", roads_sf$highway)   # ramp -> parent
barrier_sf <- roads_sf[roads_sf$road_class %in% ROAD_BARRIER_CLASSES, ]
if (nrow(barrier_sf) == 0) {
  stop("No road features in ROAD_BARRIER_CLASSES.", call. = FALSE)
}
road_counts <- as.data.frame(table(barrier_sf$road_class))
names(road_counts) <- c("road_class", "n_features")
cat("barrier road features (links merged into parent class):\n")
print(road_counts, row.names = FALSE)

road_r <- terra::rasterize(terra::vect(barrier_sf), tmpl_r, field = 1,
                           background = 0, touches = ROAD_BARRIER_TOUCHES)
road_r <- terra::mask(road_r, lc_r)                  # footprint only
n_road <- terra::global(road_r == 1, "sum", na.rm = TRUE)[[1]]
cat(sprintf("barrier-road cells in the footprint: %s (%.1f%%)\n",
            format(n_road, big.mark = ","), 100 * n_road / n_foot))
rm(roads_sf)

# Combine: on a road cell, max(surface, road value); elsewhere the surface.
resist_list <- list()
n_raised    <- list()
for (nm in names(surfaces)) {
  v   <- surfaces[[nm]]
  s_k <- lcghm_by_k[[as.character(as.numeric(v$ghm_k))]]
  raise <- (road_r == 1) & (s_k < v$road_value)
  n_raised[[nm]] <- terra::global(raise, "sum", na.rm = TRUE)[[1]]
  r_nm <- terra::ifel(raise, v$road_value, s_k)
  names(r_nm) <- "resistance"
  resist_list[[nm]] <- r_nm
  cat(sprintf("%-8s k = %s, road = %s: %s road cells raised to the road value\n",
              nm, format(v$ghm_k), format(v$road_value),
              format(n_raised[[nm]], big.mark = ",")))
}

# =============================================================================
# STEP 9.7 — asserts, then write resist_tiger_<name>_7755.tif
# =============================================================================
rule("STEP 9.7 — asserts and write")

qa_rows <- list()
for (nm in names(resist_list)) {
  r_nm <- resist_list[[nm]]
  if (!isTRUE(terra::compareGeom(r_nm, cov_stack, stopOnError = FALSE,
                                 crs = TRUE, ext = TRUE, rowcol = TRUE,
                                 res = TRUE))) {
    stop(nm, ": grid does not match the stack.", call. = FALSE)
  }
  n_na_foot  <- terra::global(foot_r & is.na(r_nm), "sum", na.rm = TRUE)[[1]]
  n_outside  <- terra::global(!foot_r & !is.na(r_nm), "sum", na.rm = TRUE)[[1]]
  mm         <- as.numeric(terra::minmax(r_nm, compute = TRUE))
  mean_r     <- terra::global(r_nm, "mean", na.rm = TRUE)[[1]]
  n_at_max   <- terra::global(r_nm >= RESIST_MAX, "sum", na.rm = TRUE)[[1]]
  n_ge_road  <- terra::global(r_nm >= surfaces[[nm]]$road_value, "sum",
                              na.rm = TRUE)[[1]]
  problems <- c(
    if (n_na_foot > 0) paste(n_na_foot, "NA cells inside the footprint"),
    if (n_outside > 0) paste(n_outside, "values outside the footprint"),
    if (!is.finite(mm[1]) || mm[1] < 1) paste("minimum", mm[1], "< 1"),
    if (!is.finite(mm[2]) || mm[2] > RESIST_MAX)
      paste("maximum", mm[2], ">", RESIST_MAX)
  )
  if (length(problems) > 0) {
    stop(nm, " failed its asserts: ", paste(problems, collapse = "; "),
         ". Nothing further is written.", call. = FALSE)
  }
  out_nm <- paste0("resist_tiger_", nm, "_7755.tif")
  write_processed_rast(r_nm, out_nm, dir = DIR_PROCESSED, datatype = "FLT4S")
  qa_rows[[nm]] <- data.frame(
    surface = nm, file = out_nm,
    ghm_k = surfaces[[nm]]$ghm_k, road_value = surfaces[[nm]]$road_value,
    n_cells = n_foot, n_na_in_footprint = n_na_foot,
    n_outside_footprint = n_outside,
    min = round(mm[1], 3), max = round(mm[2], 3), mean = round(mean_r, 3),
    pct_at_max = round(100 * n_at_max / n_foot, 2),
    pct_ge_road_value = round(100 * n_ge_road / n_foot, 2),
    n_road_cells = n_road, n_road_raised = n_raised[[nm]],
    n_water_override = n_override, n_ghm_exempt = n_exempt,
    stringsAsFactors = FALSE
  )
}

# =============================================================================
# STEP 9.8 — resistance QA -> tbl_11_resistance_qa.csv
# =============================================================================
rule("STEP 9.8 — resistance QA -> tbl_11_resistance_qa")

res_qa <- do.call(rbind, qa_rows)
rownames(res_qa) <- NULL
write_table(res_qa, nn = 11, slug = "resistance_qa")
print(res_qa[, c("surface", "ghm_k", "road_value", "min", "max", "mean",
                 "pct_at_max", "pct_ge_road_value", "n_road_raised")],
      row.names = FALSE)

# Per-class view of the BASELINE: the class value, and the mean final
# resistance on that class (after gHM, cap and roads) — a check that the
# surface behaves as Decision 14 describes.
zonal_base <- terra::zonal(resist_list[["baseline"]], lc_r, fun = "mean",
                           na.rm = TRUE)
names(zonal_base) <- c("worldcover_class", "mean_resistance_baseline")
class_view <- merge(class_tab, zonal_base, by = "worldcover_class", all.x = TRUE)
class_view$mean_resistance_baseline <- round(class_view$mean_resistance_baseline, 2)
cat("\nbaseline by land-cover class (value -> mean final resistance):\n")
print(class_view, row.names = FALSE)

rule(paste0("Week-9 resistance surfaces written: ",
            paste(names(resist_list), collapse = ", "),
            ". Next: Week 10 least-cost paths."))
