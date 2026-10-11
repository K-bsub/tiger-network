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
#   WEEK 10 — least-cost paths between neighbouring reserve pairs
#             (Decisions 17 + 18; engine in R/00_functions_lcp.R)
#     guard     the four resistance surfaces on disk must match
#               tbl_11_resistance_qa.csv (cells, min, max, mean)
#     STEP 10.0 tool check (task 10.3): synthetic self-test + one national
#               baseline pair (runtime, memory); switch RUN_LCP_SMOKE
#     STEP 10.1 reserve pairs (task 10.4; Decision 17 points 1, 6, 8):
#               Euclidean-allocation zones on the footprint, rook adjacency,
#               gap cap -> tbl_12_reserve_pairs.csv
#     STEP 10.2 baseline least-cost paths for every pair (task 10.5;
#               Decision 17 points 2-6) -> lcp_reserve_network_7755.gpkg,
#               layer "baseline"
#     STEP 10.2b validation (task 10.5b; Decision 17 point 4 + V-add):
#               (a) synthetic, (b) terra::costDist, (c) gdistance
#               -> tbl_12_lcp_validation.csv; switch LCP_VALIDATE (config)
#     STEP 10.3 path QA, baseline (task 10.6) -> tbl_12_lcp_qa.csv
#     STEP 10.4 variant paths (noghm, road15, road50), their QA, and the
#               Decision-18 comparison (task 10.7) -> layers in
#               lcp_reserve_network_7755.gpkg; tbl_12_lcp_qa.csv (all four
#               surfaces); tbl_12_lcp_variant_comparison.csv;
#               tbl_12_lcp_variant_summary.csv
#     STEP 10.5 NTCA corridor overlap, baseline (task 10.8; Decision 17
#               point 9; descriptive) -> tbl_12_lcp_ntca_overlap.csv,
#               tbl_12_lcp_ntca_corridors.csv; switch LCP_NTCA_OVERLAP
#   WEEK 11 — reserve network graph (Decision 19; functions in
#             R/00_functions_network.R)
#     STEP 11.1 nodes (blocks of contiguous reserves), link table and igraph
#               graph from the "baseline" layer; construction checks; bridge
#               and spanning-forest flags (task 11.2; Decision 19 points 1-4,
#               8 and 11) -> tbl_13_network_links.csv
#     STEP 11.2 self-test of the metric functions on a hand-computed graph;
#               node metrics (sets, degree, betweenness, linchpin, cut_node,
#               isolated, pendant, cheapest link); second baseline run
#               without cross-group links; threshold scan (task 11.3;
#               Decision 19 points 4-9 and 11) -> tbl_13_network_metrics.csv,
#               tbl_13_network_threshold_scan.csv
#     STEP 11.3 the graph and the metrics on noghm, road15 and road50, each
#               compared with the baseline by the fixed rule (task 11.4;
#               Decision 19 point 10) -> tbl_13_network_variant_comparison.csv;
#               tbl_13_network_metrics.csv written again with the variant
#               columns and stable_linchpin
#     STEP 11.4 network QA: the construction checks of the four surfaces
#               and the self-test, collected; result checks (flags, the
#               betweenness identity, edge weights, second run, scan, tables
#               on disk). Any failure stops the script (task 11.5;
#               Decision 19 point 11) -> tbl_13_network_qa.csv
#   WEEK 12 — road pinch points (Decision 20; functions in
#             R/00_functions_pinch.R)
#     guard     the Decision-20 settings; the lit_flag links resolve to pairs
#     STEP 12.1 barrier-road cells with their class (task 12.2; Decision 20
#               point 1): the Decision-15 classes, one rasterise call per
#               class with the arguments of STEP 9.6; guard against
#               n_road_cells of tbl_11_resistance_qa.csv
#               -> data/interim/cov_roadbarrier_class_1km_7755.tif;
#               switch RUN_ROAD_CELLS
#     STEP 12.2 road crossings of the baseline paths (task 12.3; Decision
#               20 points 2, 3 and 7): self-test on a hand-made case; the cell
#               list of each in-network path (knight-step middle cells
#               included; cost check against the engine); a crossing = one
#               unbroken run of barrier-road cells; position at the 10 km
#               publish grid with state and district
#               -> tbl_14_road_crossings.csv;
#               data/processed/lcp_road_crossings_7755.gpkg (1 km cells,
#               gitignored)
#     STEP 12.3 sites and pinch points, baseline (task 12.4; Decision 20
#               points 4, 5 and 7): self-test on a hand-made case; crossings
#               at most 5 km apart = one site; pinch_point = on_bridge OR
#               shared, three tiers; the summary per link
#               -> tbl_14_pinch_points.csv (one row per site),
#               tbl_14_pinch_link_summary.csv; tbl_14_road_crossings.csv and
#               the 1 km layer written again with site_id
#     STEP 12.4 the same chain on noghm, road15 and road50, each with its
#               own paths, edges and bridges; each compared with the baseline
#               by the fixed rule (task 12.5; Decision 20 point 6)
#               -> tbl_14_pinch_variant_comparison.csv; tbl_14_pinch_points.csv
#               written again with near_pinch_<variant> and n_variants_near;
#               the variant crossing cells in the gitignored 1 km file
#     STEP 12.5 pinch-point QA: the self-tests and the road-cell guard,
#               collected; the QA list of Decision 20 on each of the four
#               surfaces; the comparison; the tables and the 1 km file on
#               disk; no position finer than the publish grid. Any failure
#               stops the script (task 12.6) -> tbl_14_pinch_qa.csv
#     STEP 12.6 publishable tables (task 12.7; Decision 20 point 7):
#               tbl_03_reserve_network.csv (one row per network reserve: the
#               node results and the pinch points on its edges, by tier) and
#               tbl_03b_pinch_points.csv (one row per baseline pinch point);
#               publish check assert_publishable_table()
#               (R/00_functions_sensitive.R); tbl_03_notes.md (what a
#               pinch point is here, the tiers, the limits)
#     STEP 12.7 figure fig_03_reserve_network.png (task 12.8; Decision 20
#               point 7): the nodes by flag, the baseline edge paths with
#               the bridge links marked, the baseline pinch points at their
#               publish-grid cell, by tier. The pinch points are read from
#               tbl_03b only. Title, subtitle and caption are draft text
#               for the author's edit
#
# Tasks 9.3 and 9.4 (resistance values, barrier road classes) are numbered
# Decisions (14 and 15) recorded in docs/methodology.md BEFORE their STEPs are
# written.
# Their values are read from R/00_config.R, never hardcoded here.
#
# RUN SWITCHES (process choice RS1, 2026-10-02; set below "Prerequisites"):
#   RUN_RESISTANCE  TRUE  -> the Week-9 STEPs (9.2, 9.5-9.8) run and rewrite
#                            their outputs (a clean-clone run sets TRUE).
#                   FALSE -> they are skipped; the Week-10+ STEPs read the four
#                            surfaces from disk, after the surface guard.
#   RUN_LCP_SMOKE   TRUE  -> STEP 10.0 runs (task 10.3).
#   RUN_ROAD_CELLS  TRUE  -> STEP 12.1 reads the road layer, builds the
#                            barrier-road class raster and writes it.
#                   FALSE -> STEP 12.1 reads the raster from disk.
#                            The STEP-12.1 guard runs in both cases.
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
#   SPLIT SUFFIX (process choice RS1, 2026-10-02): when the reserve layer has
#     parts with match_status == BOUNDARY_SPLIT_STATUS (the Decision-17 D1a
#     split, scripts/02), the gap table label gets "_split", for example
#     tbl_11_ghm_gap_relevance_postfill_d13f_split.csv. The dropped-cell layer
#     does not depend on the reserves, so its name does not change.
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
# OUTPUTS (STEP 9.2; <state> = prefill | postfill | postfill_d12 |
#          postfill_<build_tag>, from tbl_10; the gap table adds "_split"):
#   data/interim/cov_commonmask_dropped_<state>_1km_7755.tif
#                                     dropped India cells, value = WorldCover
#                                     class (0 = no class), else NA
#   outputs/tables/tbl_11_ghm_gap_relevance_<state>[_split].csv  one row per
#     unit (tbl_11 is shared with the Week-9 resistance QA table under the
#      naming-conventions §6 rule: numbers group, slugs identify.)
# OUTPUTS (STEP 9.7-9.8): data/processed/resist_tiger_<surface>_7755.tif,
#   outputs/tables/tbl_11_resistance_qa.csv
# INPUTS (Week 10): the four resist_tiger_<surface>_7755.tif files,
#   tbl_11_resistance_qa.csv, boundary_reserves_all_7755.gpkg
# OUTPUTS (STEP 10.0): console report only (runtime, memory, one path).
# OUTPUTS (STEP 10.1): outputs/tables/tbl_12_reserve_pairs.csv;
#   data/interim/lcp_pair_zones_1km_7755.tif (allocation zones, QA only)
# OUTPUTS (STEP 10.2): data/processed/lcp_reserve_network_7755.gpkg, layer
#   "baseline" (one LINESTRING per pair; empty for contiguous pairs)
# OUTPUTS (STEP 10.2b): outputs/tables/tbl_12_lcp_validation.csv
# OUTPUTS (STEP 10.3): outputs/tables/tbl_12_lcp_qa.csv (baseline rows; STEP
#   10.4 rewrites it with all four surfaces)
# OUTPUTS (STEP 10.4): layers noghm, road15, road50 in
#   lcp_reserve_network_7755.gpkg; tbl_12_lcp_variant_comparison.csv;
#   tbl_12_lcp_variant_summary.csv
# OUTPUTS (STEP 10.5): outputs/tables/tbl_12_lcp_ntca_overlap.csv (per pair),
#   outputs/tables/tbl_12_lcp_ntca_corridors.csv (per corridor)
# INPUTS (Week 11): data/processed/lcp_reserve_network_7755.gpkg (the layers
#   that STEPs 10.2 and 10.4 write in this run), the pair table and the
#   reserve list of STEP 10.1 (in memory)
# OUTPUTS (STEP 11.1): outputs/tables/tbl_13_network_links.csv (one row per
#   baseline in-network pair). The graph is not written; it is rebuilt from
#   the paths layer on each run.
# OUTPUTS (STEP 11.2): outputs/tables/tbl_13_network_metrics.csv (one row per
#   network reserve; the reserves of one block share the values of their
#   node; STEP 11.3 writes it again with 7 more columns);
#   outputs/tables/tbl_13_network_threshold_scan.csv (one row per baseline
#   edge, in cost order)
# OUTPUTS (STEP 11.3): outputs/tables/tbl_13_network_variant_comparison.csv
#   (one row per variant); tbl_13_network_metrics.csv (written again:
#   betweenness_norm_<variant>, linchpin_<variant>, stable_linchpin)
# OUTPUTS (STEP 11.4): outputs/tables/tbl_13_network_qa.csv (one row per
#   check: surface, check, value, pass)
# OUTPUTS (STEP 12.1): data/interim/cov_roadbarrier_class_1km_7755.tif (INT1U;
#   class rank 1..4 on a barrier-road cell of the footprint, NA elsewhere;
#   the layer name records the class order)
# OUTPUTS (STEP 12.2): outputs/tables/tbl_14_road_crossings.csv (one row per
#   crossing; position at the publish grid only);
#   data/processed/lcp_road_crossings_7755.gpkg, layer "baseline" (one point
#   per crossing cell; 1 km positions — gitignored, never published)
# OUTPUTS (STEP 12.3): outputs/tables/tbl_14_pinch_points.csv (one row per
#   site: flags, tier, counts, links, position at the publish grid);
#   outputs/tables/tbl_14_pinch_link_summary.csv (one row per link);
#   tbl_14_road_crossings.csv and the 1 km layer again, with site_id
# OUTPUTS (STEP 12.4): outputs/tables/tbl_14_pinch_variant_comparison.csv (one
#   row per variant); tbl_14_pinch_points.csv again, with the variant columns;
#   layers "noghm", "road15", "road50" of lcp_road_crossings_7755.gpkg
# OUTPUTS (STEP 12.5): outputs/tables/tbl_14_pinch_qa.csv (one row per check:
#   surface, check, value, pass)
# OUTPUTS (STEP 12.6): outputs/tables/tbl_03_reserve_network.csv (56 rows; no
#   position); outputs/tables/tbl_03b_pinch_points.csv (one row per baseline
#   pinch point; position at the publish grid only);
#   outputs/tables/tbl_03_notes.md (the note file of the two tables)
# OUTPUTS (STEP 12.7): outputs/figures/fig_03_reserve_network.png (a static
#   map at national scale; pinch points at the publish grid only)
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

# ---- Run switches (process choice RS1, 2026-10-02) ---------------------------
RUN_RESISTANCE <- FALSE   # TRUE: re-run the Week-9 STEPs (clean clone)
RUN_LCP_SMOKE  <- FALSE   # TRUE: STEP 10.0 tool check (task 10.3; done
                          # 2026-10-02 — set TRUE to repeat it)
RUN_ROAD_CELLS <- FALSE   # TRUE: STEP 12.1 builds the barrier-road class
                          # raster from the road layer (done 2026-10-10 — set
                          # TRUE on a clean clone, or after a change of the
                          # road layer). FALSE: read it from disk

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
# 1) Decision-11 parameters must come from config (Week-9 STEPs only).
gap_params <- c("GAP_BUFFER_M", "GAP_MIN_PCT", "GAP_MIN_CELLS",
                "GAP_WATER_CLASS", "GAP_FILL_WINDOW", "GAP_FILL_MAX_ITER",
                "GHM_GAP_FILL", "BOUNDARY_SPLIT_STATUS")
if (!is.logical(RUN_RESISTANCE) || !is.logical(RUN_LCP_SMOKE) ||
    !is.logical(RUN_ROAD_CELLS)) {
  stop("RUN_RESISTANCE, RUN_LCP_SMOKE and RUN_ROAD_CELLS must be TRUE or FALSE.",
       call. = FALSE)
}
missing_params <- gap_params[!vapply(gap_params, exists, logical(1))]
if (isTRUE(RUN_RESISTANCE) && length(missing_params) > 0) {
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

# 3) Every input must exist (the Week-9 inputs only when RUN_RESISTANCE).
inputs <- if (isTRUE(RUN_RESISTANCE)) {
  c(stack_in, distroad_in, lc_in, india_in, reserves_in, corridors_in, tbl10_in)
} else {
  reserves_in
}
missing_inputs <- inputs[!file.exists(inputs)]
if (length(missing_inputs) > 0) {
  stop("Missing required input(s):\n  ", paste(missing_inputs, collapse = "\n  "),
       "\nboundary_corridors_7755.gpkg comes from the Week-9 re-run of ",
       "scripts/02 (task 9.2a).", call. = FALSE)
}

rule(paste0("07_connectivity.R — inputs found; CRS OK | RUN_RESISTANCE = ",
            RUN_RESISTANCE, " | RUN_LCP_SMOKE = ", RUN_LCP_SMOKE,
            " | RUN_ROAD_CELLS = ", RUN_ROAD_CELLS))

# =============================================================================
# WEEK 9 — resistance surfaces. Runs only when RUN_RESISTANCE is TRUE.
# The block ends at "end if (RUN_RESISTANCE)" after STEP 9.8. The code inside
# is not indented, so its lines match the Week-9 record.
# =============================================================================
if (isTRUE(RUN_RESISTANCE)) {

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

# Split suffix (process choice RS1): a reserve layer with D1a split parts gets
# its own gap-table label, so the recorded Week-9 tables are not overwritten.
has_split <- "match_status" %in% names(reserves_sf) &&
  any(reserves_sf$match_status == BOUNDARY_SPLIT_STATUS, na.rm = TRUE)
if (has_split) gap_slug <- paste0(gap_slug, "_split")
cat("reserve layer:", if (has_split) {
  paste0("split parts present -> gap table label '", gap_slug, "'")
} else {
  "no split parts"
}, "\n")

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

}  # end if (RUN_RESISTANCE)

# =============================================================================
# WEEK 10 — least-cost paths (Decisions 17 + 18)
# =============================================================================
# Engine: R/00_functions_lcp.R (own 16-neighbour cell graph, crossed-cells
# knight rule, igraph Dijkstra from all cells of the source reserve).
# Every Decision-17/18 value is read from R/00_config.R.
source(here("R", "00_functions_lcp.R"))

# ---- Guard: settings --------------------------------------------------------
lcp_params <- c("LCP_PAIR_ADJACENCY", "LCP_PAIR_MAX_GAP_KM",
                "LCP_THROUGH_RESERVE_RULE", "LCP_NEIGHBOURS", "LCP_KNIGHT_RULE",
                "LCP_VALIDATE", "LCP_VALIDATE_PAIRS", "LCP_VALIDATE_TOL_REL",
                "LCP_VALIDATE_WINDOW_KM", "LCP_CROP",
                "LCP_CROP_FALLBACK_MIN_BUFFER_KM",
                "LCP_CROP_FALLBACK_BUFFER_FRAC", "LCP_RESERVE_TOUCHES",
                "LCP_EXCLUDED_UNIT_IDS", "LCP_EXCLUDED_UNIT_NAMES",
                "NETWORK_GROUPS", "LCP_NTCA_OVERLAP", "LCP_COMPARE_VARIANTS",
                "LCP_COMPARE_ROUTE_D_KM", "LCP_COMPARE_ROUTE_D_DESCR_KM",
                "LCP_COMPARE_ROUTE_MATERIAL", "LCP_COMPARE_RANK_MATERIAL",
                "LCP_COMPARE_ROBUST_MAX_SHARE", "LCP_COMPARE_ROBUST_MIN_RHO",
                "RESIST_VARIANTS")
missing_lcp <- lcp_params[!vapply(lcp_params, exists, logical(1))]
if (length(missing_lcp) > 0) {
  stop("Decision-17/18 setting(s) missing from R/00_config.R: ",
       paste(missing_lcp, collapse = ", "), call. = FALSE)
}
if (!requireNamespace("igraph", quietly = TRUE)) {
  stop("Package igraph is needed for the path engine (scripts/00a).",
       call. = FALSE)
}

# ---- Guard: the four surfaces on disk match the Week-9 QA -------------------
# Cells exact; min, max and mean within 0.001 (tbl_11 rounds to 3 decimals,
# and the files are 32-bit float).
rule("WEEK 10 — surface guard (files vs tbl_11_resistance_qa)")
resqa_in      <- file.path(DIR_TABLES, "tbl_11_resistance_qa.csv")
surface_names <- c("baseline", names(RESIST_VARIANTS))
resist_in     <- stats::setNames(
  file.path(DIR_PROCESSED, paste0("resist_tiger_", surface_names, "_7755.tif")),
  surface_names)
need_w10 <- c(resqa_in, resist_in)
if (any(!file.exists(need_w10))) {
  stop("Missing Week-10 input(s):\n  ",
       paste(need_w10[!file.exists(need_w10)], collapse = "\n  "),
       "\nSet RUN_RESISTANCE <- TRUE to build the surfaces.", call. = FALSE)
}
resqa_disk <- utils::read.csv(resqa_in, stringsAsFactors = FALSE)
r_ref <- NULL
for (nm in surface_names) {
  q <- resqa_disk[resqa_disk$surface == nm, ]
  if (nrow(q) != 1L) {
    stop("tbl_11_resistance_qa.csv has ", nrow(q), " row(s) for surface '",
         nm, "' (expected 1).", call. = FALSE)
  }
  r_nm <- terra::rast(resist_in[[nm]])
  if (is.null(r_ref)) r_ref <- r_nm
  if (!isTRUE(terra::compareGeom(r_nm, r_ref, stopOnError = FALSE, crs = TRUE,
                                 ext = TRUE, rowcol = TRUE, res = TRUE))) {
    stop(nm, ": grid differs from the baseline grid.", call. = FALSE)
  }
  n_nm    <- terra::global(!is.na(r_nm), "sum")[[1]]
  mm      <- as.numeric(terra::minmax(r_nm, compute = TRUE))
  mean_nm <- terra::global(r_nm, "mean", na.rm = TRUE)[[1]]
  bad <- c(
    if (n_nm != q$n_cells) paste0("cells ", n_nm, " vs QA ", q$n_cells),
    if (abs(mm[1] - q$min) > 1e-3) paste0("min ", mm[1], " vs QA ", q$min),
    if (abs(mm[2] - q$max) > 1e-3) paste0("max ", mm[2], " vs QA ", q$max),
    if (abs(mean_nm - q$mean) > 1e-3) paste0("mean ", round(mean_nm, 4),
                                             " vs QA ", q$mean)
  )
  if (length(bad) > 0) {
    stop(nm, ": the file on disk does not match tbl_11_resistance_qa.csv (",
         paste(bad, collapse = "; "), "). Re-run with RUN_RESISTANCE <- TRUE.",
         call. = FALSE)
  }
  cat(sprintf("%-8s OK: %s cells, min %.3f, max %.3f, mean %.3f\n", nm,
              format(n_nm, big.mark = ","), mm[1], mm[2], mean_nm))
}
rm(r_nm, r_ref)

# ---- Shared Week-10 inputs ----------------------------------------------------
# The baseline surface defines the footprint (its non-NA cells are the
# complete-case cells, Decision 10). The reserve layer gives the reserves.
lcp_base <- terra::rast(resist_in[["baseline"]])
reserves_lcp <- read_vec(reserves_in)
reserves_lcp$unit_id <- as.integer(reserves_lcp$unit_id)

# =============================================================================
# STEP 10.0 — tool check (task 10.3): self-test + one national baseline pair
# =============================================================================
# Smoke test only: it writes no file. The pair set is built in STEP 10.1.
# Pair: Kanha (22) - Pench (23), gap about 106 km (near the median gap of the
# 2026-10-01 geometry check). Record the runtime and memory in the handoff.
if (isTRUE(RUN_LCP_SMOKE)) {
  rule("STEP 10.0 — tool check: synthetic self-test, then one national pair")

  st <- lcp_selftest_synthetic()
  print(st[, c("case", "expected", "engine", "pass")], row.names = FALSE)
  if (!all(st$pass)) {
    stop("Synthetic self-test failed — the engine is wrong. Nothing further ",
         "runs.", call. = FALSE)
  }

  SMOKE_IDS   <- c(22L, 23L)
  SMOKE_NAMES <- c("Kanha", "Pench")
  smoke_sf <- reserves_lcp[match(SMOKE_IDS, reserves_lcp$unit_id), ]
  if (anyNA(smoke_sf$unit_id) || !identical(smoke_sf$unit_name, SMOKE_NAMES) ||
      !all(smoke_sf$geometry_present)) {
    stop("Smoke pair does not resolve: unit_id ",
         paste(SMOKE_IDS, collapse = ", "), " gave '",
         paste(smoke_sf$unit_name, collapse = ", "), "' (expected '",
         paste(SMOKE_NAMES, collapse = ", "), "', with geometry).",
         call. = FALSE)
  }

  t0 <- Sys.time()
  smoke_cells <- lcp_reserve_cells(lcp_base, smoke_sf,
                                   touches = LCP_RESERVE_TOUCHES)
  t1 <- Sys.time()
  G <- lcp_build_graph(lcp_base, smoke_cells, neighbours = LCP_NEIGHBOURS,
                       knight_rule = LCP_KNIGHT_RULE)
  t2 <- Sys.time()
  sm <- lcp_search(G, from = 1L, to = 2L)
  t3 <- Sys.time()

  sm_line <- lcp_path_line(sm$cells[[1]], lcp_base)
  sm_len  <- as.numeric(sf::st_length(sf::st_sfc(sm_line, crs = CRS_ANALYSIS))) / 1000
  sm_gap  <- as.numeric(sf::st_distance(smoke_sf[1, ], smoke_sf[2, ])) / 1000
  mem     <- lcp_mem_report()
  secs    <- function(a, b) round(as.numeric(difftime(b, a, units = "secs")), 1)

  cat(sprintf("reserve cells: %s %s, %s %s | contiguous: %s\n",
              SMOKE_NAMES[1], format(length(smoke_cells[[1]]), big.mark = ","),
              SMOKE_NAMES[2], format(length(smoke_cells[[2]]), big.mark = ","),
              lcp_contiguous(smoke_cells[[1]], smoke_cells[[2]])))
  cat(sprintf("graph: %s nodes, %s cell edges, %d neighbours, knight rule %s\n",
              format(G$n_nodes, big.mark = ","),
              format(G$n_cell_edges, big.mark = ","), G$neighbours,
              G$knight_rule))
  cat(sprintf("time (s): reserve cells %s | graph build %s | one search %s\n",
              secs(t0, t1), secs(t1, t2), secs(t2, t3)))
  cat(sprintf(paste0("path %s -> %s: cost %.1f resistance-km | %d cells | ",
                     "length %.1f km | gap %.1f km | length / gap %.2f\n"),
              SMOKE_NAMES[1], SMOKE_NAMES[2], sm$cost, sm$n_cells, sm_len,
              sm_gap, sm_len / sm_gap))
  cat(sprintf("memory: %s MB (%s)\n", format(mem$peak_mb, big.mark = ","),
              mem$source))
  rm(G); invisible(gc())
  rule("STEP 10.0 done — record runtime and memory. Next: task 10.3b, then STEP 10.1.")
}

# =============================================================================
# STEP 10.1 — reserve pairs (task 10.4; Decision 17 points 1, 6 and 8)
# =============================================================================
# 1. Every footprint cell goes to the nearest reserve polygon (straight line);
#    the cells of each reserve take their own reserve first.
# 2. Two reserves are a candidate pair if their zones share >= 1 cell edge.
# 3. A candidate is kept if the polygon gap is <= LCP_PAIR_MAX_GAP_KM.
# 4. contiguous = the two reserves share a footprint cell (amended 2026-10-02);
#    cross_group = the two reserves are in different NETWORK_GROUPS.
# One pair set for all four surfaces: no resistance value is used here.
rule("STEP 10.1 — reserve pairs (Decision 17) -> tbl_12_reserve_pairs.csv")

# QA expectation from the Decision-17 geometry check (2026-10-01): about 106
# pairs with the split. A count outside +/- 10 % stops the script: a large
# difference is investigated, not accepted (task 10.4).
PAIRS_EXPECTED     <- 106L
PAIRS_EXPECTED_TOL <- 0.10

# Guard: NETWORK_GROUPS holds every unit_id of the reserve layer exactly once.
grp_ids <- unlist(NETWORK_GROUPS, use.names = FALSE)
if (anyDuplicated(grp_ids) || !setequal(grp_ids, reserves_lcp$unit_id)) {
  stop("NETWORK_GROUPS must hold every unit_id of the reserve layer exactly ",
       "once. Duplicated: ", paste(grp_ids[duplicated(grp_ids)], collapse = ", "),
       " | missing: ", paste(setdiff(reserves_lcp$unit_id, grp_ids), collapse = ", "),
       " | not in the layer: ", paste(setdiff(grp_ids, reserves_lcp$unit_id),
                                      collapse = ", "), call. = FALSE)
}

# Guard: the geometry-absent reserves are exactly LCP_EXCLUDED_UNIT_IDS (G1),
# and the names match.
absent_ids <- sort(reserves_lcp$unit_id[!as.logical(reserves_lcp$geometry_present)])
if (!identical(absent_ids, sort(LCP_EXCLUDED_UNIT_IDS)) ||
    !identical(reserves_lcp$unit_name[match(LCP_EXCLUDED_UNIT_IDS,
                                            reserves_lcp$unit_id)],
               LCP_EXCLUDED_UNIT_NAMES)) {
  stop("Geometry-absent reserves (", paste(absent_ids, collapse = ", "),
       ") do not match LCP_EXCLUDED_UNIT_IDS / _NAMES (",
       paste(LCP_EXCLUDED_UNIT_IDS, collapse = ", "), "). Run task 10.3b ",
       "(scripts/02 state split) first, or check the config.", call. = FALSE)
}
res_net <- reserves_lcp[!reserves_lcp$unit_id %in% LCP_EXCLUDED_UNIT_IDS, ]
res_net <- res_net[order(res_net$unit_id), ]
cat(sprintf("reserves in the network: %d (excluded, no geometry: %s)\n",
            nrow(res_net), paste(LCP_EXCLUDED_UNIT_NAMES, collapse = ", ")))

# Reserve cells (Decision 17 point 6; touches = TRUE, footprint cells only).
res_cells <- lcp_reserve_cells(lcp_base, res_net, touches = LCP_RESERVE_TOUCHES)
if (any(lengths(res_cells) == 0L)) {
  stop("Reserve(s) with no footprint cell: ",
       paste(res_net$unit_name[lengths(res_cells) == 0L], collapse = ", "),
       call. = FALSE)
}
cat(sprintf("reserve cells: min %d (%s), median %d, max %d (%s)\n",
            min(lengths(res_cells)), res_net$unit_name[which.min(lengths(res_cells))],
            as.integer(stats::median(lengths(res_cells))),
            max(lengths(res_cells)), res_net$unit_name[which.max(lengths(res_cells))]))

t_alloc <- Sys.time()
zones <- lcp_alloc_zones(lcp_base, res_net, res_cells)
cat(sprintf("allocation zones: %s footprint cells allocated in %.0f s\n",
            format(sum(!is.na(zones)), big.mark = ","),
            as.numeric(difftime(Sys.time(), t_alloc, units = "secs"))))
if (sum(!is.na(zones)) != sum(!is.na(terra::values(lcp_base, mat = FALSE)))) {
  stop("Allocation does not cover every footprint cell.", call. = FALSE)
}

adj <- lcp_zone_adjacency(zones, terra::nrow(lcp_base), terra::ncol(lcp_base))
bp  <- lcp_build_pairs(adj, res_net, res_cells, NETWORK_GROUPS,
                       LCP_PAIR_MAX_GAP_KM)
pairs <- bp$pairs
cat(sprintf(paste0("candidate pairs (zones share an edge): %d | dropped by the ",
                   "%s km cap: %d | kept: %d\n"),
            nrow(adj), format(LCP_PAIR_MAX_GAP_KM), nrow(bp$dropped), nrow(pairs)))

# Checks
if (abs(nrow(pairs) - PAIRS_EXPECTED) > PAIRS_EXPECTED_TOL * PAIRS_EXPECTED) {
  stop("Pair count ", nrow(pairs), " is outside ", PAIRS_EXPECTED, " +/- ",
       PAIRS_EXPECTED_TOL * 100, " % (Decision-17 geometry check). Investigate ",
       "before you accept it.", call. = FALSE)
}
if (anyDuplicated(paste(pairs$from_unit_id, pairs$to_unit_id)) ||
    any(pairs$from_unit_id >= pairs$to_unit_id)) {
  stop("Pair table has a duplicate or an unordered pair.", call. = FALSE)
}
if (any(pairs$contiguous & pairs$gap_km > 1.5)) {
  stop("A contiguous pair has a gap above 1.5 km (the cell diagonal is ",
       "1.41 km): check the reserve cells.", call. = FALSE)
}
if (any(!pairs$contiguous & pairs$gap_km == 0)) {
  stop("A gap-0 pair is not contiguous: check the reserve cells.", call. = FALSE)
}

g_pairs <- igraph::graph_from_data_frame(
  pairs[, c("from_unit_id", "to_unit_id")], directed = FALSE,
  vertices = data.frame(name = res_net$unit_id))
cc <- igraph::components(g_pairs)
cat(sprintf("connected sets: %d (sizes %s) | reserves with no pair: %s\n", cc$no,
            paste(sort(cc$csize, decreasing = TRUE), collapse = ", "),
            if (any(cc$csize == 1L)) paste(res_net$unit_name[cc$membership %in%
                                             which(cc$csize == 1L)], collapse = ", ")
            else "none"))
cat(sprintf("gap km: median %.1f, max %.1f | contiguous: %d | cross-group: %d\n",
            stats::median(pairs$gap_km), max(pairs$gap_km), sum(pairs$contiguous),
            sum(pairs$cross_group)))
cat("contiguous pairs (cost 0, empty path):\n")
print(pairs[pairs$contiguous, c("pair_id", "from_name", "to_name", "gap_km")],
      row.names = FALSE)
cat("cross-group pairs (kept; Decision 17 point 8):\n")
print(pairs[pairs$cross_group, c("pair_id", "from_name", "to_name", "from_group",
                                 "to_group", "gap_km")], row.names = FALSE)
cat("pairs per network group (both ends in the group):\n")
print(table(pairs$from_group[!pairs$cross_group]))

# Outputs
zones_r <- terra::setValues(terra::rast(lcp_base), zones)
names(zones_r) <- "unit_id"
zones_out <- file.path(DIR_INTERIM, "lcp_pair_zones_1km_7755.tif")
terra::writeRaster(zones_r, zones_out, overwrite = TRUE, datatype = "INT2U",
                   gdal = c("COMPRESS=DEFLATE"))
zr <- terra::rast(zones_out)
if (terra::global(!is.na(zr), "sum")[[1]] != sum(!is.na(zones))) {
  stop("Zone raster read-back: cell count differs.", call. = FALSE)
}
cat("wrote", zones_out, "(QA only)\n")
write_table(pairs, 12, "reserve_pairs")
rule(sprintf("STEP 10.1 done — %d pairs. Next: STEP 10.2 baseline paths (task 10.5).",
             nrow(pairs)))

# =============================================================================
# STEP 10.2 — baseline least-cost paths (task 10.5; Decision 17 points 2-6)
# =============================================================================
# Graph: 16 neighbours, crossed-cells knight rule (Decision 17 point 3); one
# Dijkstra search per source reserve from all of its cells (edge to edge,
# point 6). Contiguous pairs: cost 0, empty path. Point 2 (P3) then sets
# via_unit_ids and in_network. Fields: data-dictionary.md.
rule("STEP 10.2 — baseline least-cost paths -> lcp_reserve_network_7755.gpkg")
paths_out <- file.path(DIR_PROCESSED, "lcp_reserve_network_7755.gpkg")

t_b <- Sys.time()
G_base <- lcp_build_graph(lcp_base, res_cells, neighbours = LCP_NEIGHBOURS,
                          knight_rule = LCP_KNIGHT_RULE)
t_s <- Sys.time()
paths_base <- lcp_paths_for_pairs(G_base, lcp_base, res_net, res_cells, pairs,
                                  surface = "baseline")
paths_base <- lcp_apply_through_rule(paths_base, pairs, res_net, res_cells)
t_e <- Sys.time()
cat(sprintf(paste0("graph: %s nodes, %s cell edges (%.0f s) | searches: %d ",
                   "source reserves (%.0f s)\n"),
            format(G_base$n_nodes, big.mark = ","),
            format(G_base$n_cell_edges, big.mark = ","),
            as.numeric(difftime(t_s, t_b, units = "secs")),
            length(unique(pairs$from_unit_id[!pairs$contiguous])),
            as.numeric(difftime(t_e, t_s, units = "secs"))))
rm(G_base); invisible(gc())

st_tab <- table(factor(paths_base$path_status,
                       levels = c("path", "contiguous", "no_path")))
cat(sprintf("pairs: %d | path %d | contiguous %d | no path %d\n",
            nrow(paths_base), st_tab[["path"]], st_tab[["contiguous"]],
            st_tab[["no_path"]]))
if (st_tab[["no_path"]] > 0) {
  cat("pairs with NO path (reported, not dropped; Decision 17):\n")
  print(sf::st_drop_geometry(paths_base)[paths_base$path_status == "no_path",
        c("pair_id", "from_name", "to_name", "gap_km")], row.names = FALSE)
}
pb <- sf::st_drop_geometry(paths_base)[paths_base$path_status == "path", ]
cat(sprintf(paste0("paths: cost median %.1f, max %.1f resistance-km | length ",
                   "median %.1f, max %.1f km | length/gap median %.2f, ",
                   "range %.2f-%.2f\n"),
            stats::median(pb$cost_rkm), max(pb$cost_rkm),
            stats::median(pb$path_km), max(pb$path_km),
            stats::median(pb$path_gap_ratio), min(pb$path_gap_ratio),
            max(pb$path_gap_ratio)))
cat(sprintf(paste0("Decision 17 point 2 (P3): paths that cross another ",
                   "reserve %d | not in the network %d\n"),
            sum(paths_base$via_unit_ids != ""), sum(!paths_base$in_network)))
if (any(!paths_base$in_network)) {
  print(sf::st_drop_geometry(paths_base)[!paths_base$in_network,
        c("pair_id", "from_name", "to_name", "via_unit_ids",
          "redundant_via_unit_ids", "path_status")], row.names = FALSE)
}

lcp_write_layer(paths_base, paths_out, "baseline")
rule(sprintf(paste0("STEP 10.2 done — %d baseline paths written. Next: STEP ",
                    "10.2b validation (task 10.5b)."), st_tab[["path"]]))

# =============================================================================
# STEP 10.2b — validation (task 10.5b; Decision 17 point 4; V-add)
# =============================================================================
# (a) synthetic grids with hand-computed costs (8 and 16 neighbours, a
#     one-cell road line and a one-cell NA line);
# (b) terra::costDist, 8 neighbours, edge to edge (source cells set to 0 in
#     both runs), on a window around the pair;
# (c) gdistance, 16 neighbours, end-cell knight rule, point to point between
#     the exit and entry cells of the baseline path, on the same window.
# Pairs: the shortest gap, the gap nearest the median and the longest gap of
# the pairs with a path (contiguous pairs have none — Decision 17 point 4 as
# read under the C1 amendment), plus the highest length/gap ratio (V-add,
# 2026-10-03). Window = bounding box of the path and both reserves +
# LCP_VALIDATE_WINDOW_KM. Pass: relative cost difference <= LCP_VALIDATE_TOL_REL.
# The table is written first; then any failure stops the script.
if (isTRUE(LCP_VALIDATE)) {
  rule("STEP 10.2b — validation: (a) synthetic, (b) terra::costDist, (c) gdistance")

  st <- lcp_selftest_synthetic()
  val_rows <- list(data.frame(
    check = st$check, rule = "synthetic", case = st$case, pair_id = NA_integer_,
    from_name = NA_character_, to_name = NA_character_, gap_km = NA_real_,
    neighbours = st$neighbours, knight_rule = st$knight_rule,
    window_cells = 49L, engine = st$engine, reference = st$reference,
    rel_diff = ifelse(is.infinite(st$engine) & is.infinite(st$reference), 0,
                      abs(st$engine - st$reference) / pmax(1, abs(st$reference))),
    path_overlap = NA_real_, pass = st$pass, note = "", stringsAsFactors = FALSE))
  cat(sprintf("(a) synthetic: %d of %d cases pass\n", sum(st$pass), nrow(st)))

  vp <- lcp_validation_pairs(paths_base, LCP_VALIDATE_PAIRS, add_max_ratio = TRUE)
  for (i in seq_len(nrow(vp))) {
    pid <- vp$pair_id[i]
    pr  <- paths_base[paths_base$pair_id == pid, ]
    ka  <- match(pr$from_unit_id, res_net$unit_id)
    kb  <- match(pr$to_unit_id, res_net$unit_id)
    win <- lcp_validation_window(
      lcp_base, c(sf::st_geometry(pr), sf::st_geometry(res_net)[c(ka, kb)]),
      LCP_VALIDATE_WINDOW_KM)
    to_win <- function(cc) terra::cellFromXY(win, terra::xyFromCell(lcp_base, cc))
    A_w <- to_win(res_cells[[ka]]); B_w <- to_win(res_cells[[kb]])
    if (anyNA(A_w) || anyNA(B_w)) {
      stop("Validation window for pair ", pid, " does not hold every reserve ",
           "cell.", call. = FALSE)
    }
    t_v <- Sys.time()
    rb <- lcp_check_terra(win, A_w, B_w)
    rc <- lcp_check_gdistance(win, to_win(pr$exit_cell), to_win(pr$entry_cell))
    for (rr in list(rb, rc)) {
      val_rows[[length(val_rows) + 1L]] <- data.frame(
        check = rr$check, rule = vp$rule[i], case = NA_character_, pair_id = pid,
        from_name = pr$from_name, to_name = pr$to_name, gap_km = pr$gap_km,
        neighbours = rr$neighbours,
        knight_rule = if (rr$check == "c_gdistance") "end_cells" else NA_character_,
        window_cells = terra::ncell(win), engine = rr$engine,
        reference = rr$reference, rel_diff = rr$rel_diff,
        path_overlap = if ("path_overlap" %in% names(rr)) rr$path_overlap else NA_real_,
        pass = is.finite(rr$rel_diff) && rr$rel_diff <= LCP_VALIDATE_TOL_REL,
        note = rr$note, stringsAsFactors = FALSE)
    }
    cat(sprintf(paste0("pair %d %s - %s [%s]: window %s cells | (b) rel diff %.1e",
                       " | (c) rel diff %.1e, path overlap %.3f | %.0f s\n"),
                pid, pr$from_name, pr$to_name, vp$rule[i],
                format(terra::ncell(win), big.mark = ","), rb$rel_diff,
                rc$rel_diff, rc$path_overlap,
                as.numeric(difftime(Sys.time(), t_v, units = "secs"))))
    if (nzchar(rb$note)) cat("   note (b):", rb$note, "\n")
  }
  val <- do.call(rbind, val_rows)
  write_table(val, 12, "lcp_validation")
  if (!all(val$pass)) {
    stop("Validation FAILED (", sum(!val$pass), " row(s)); see ",
         "tbl_12_lcp_validation.csv. The engine result is not accepted.",
         call. = FALSE)
  }
  rule(sprintf(paste0("STEP 10.2b done — all %d checks pass. Next: STEP 10.3 ",
                      "path QA (task 10.6)."), nrow(val)))
}

# =============================================================================
# STEP 10.3 — path QA, baseline (task 10.6)
# =============================================================================
# One row per pair (lcp_qa_paths()): accounted for (path / contiguous /
# no_path), empty line only for contiguous or no_path, path cells on the
# footprint, start in the source reserve and end in the target reserve, valid
# 16-neighbour steps, cost and length recomputed from the raster equal the
# stored values, in_network consistent with Decision 17 point 2. The crop
# fallback is not used (LCP_CROP = FALSE), so no window-edge check applies.
# The table is written first; then any failed pair stops the script.
rule("STEP 10.3 — path QA (baseline) -> tbl_12_lcp_qa.csv")
if (isTRUE(LCP_CROP)) {
  stop("LCP_CROP is TRUE, but the crop fallback is not built (Decision 17 ",
       "point 5: only if memory fails).", call. = FALSE)
}
qa_base <- lcp_qa_paths(paths_base, lcp_base, res_net, res_cells, pairs)
chk_cols <- c("in_pair_table", "status_ok", "empty_ok", "footprint_ok",
              "start_ok", "end_ok", "steps_ok", "cost_ok", "length_ok",
              "network_ok")
cat(sprintf("pairs accounted for: %d of %d (path %d, contiguous %d, no path %d)\n",
            sum(qa_base$path_status %in% c("path", "contiguous", "no_path")),
            nrow(pairs), sum(qa_base$path_status == "path"),
            sum(qa_base$path_status == "contiguous"),
            sum(qa_base$path_status == "no_path")))
cat("checks failed per column:",
    paste(sprintf("%s %d", chk_cols, colSums(qa_base[, chk_cols] == FALSE,
                                             na.rm = TRUE)), collapse = " | "),
    "\n")
qp <- qa_base[qa_base$path_status == "path", ]
cat("lowest length/gap ratios:\n")
print(utils::head(qp[order(qp$path_gap_ratio), c("pair_id", "from_name", "to_name",
      "gap_km", "path_km", "path_gap_ratio")], 5), row.names = FALSE, digits = 3)
cat("highest length/gap ratios:\n")
print(utils::head(qp[order(-qp$path_gap_ratio), c("pair_id", "from_name", "to_name",
      "gap_km", "path_km", "path_gap_ratio")], 5), row.names = FALSE, digits = 3)
cat("highest costs:\n")
print(utils::head(qp[order(-qp$cost_rkm), c("pair_id", "from_name", "to_name",
      "gap_km", "path_km", "cost_rkm")], 5), row.names = FALSE, digits = 4)
write_table(qa_base, 12, "lcp_qa")
if (!all(qa_base$qa_pass)) {
  print(qa_base[!qa_base$qa_pass, c("pair_id", "from_name", "to_name",
                                    "path_status", chk_cols)], row.names = FALSE)
  stop("Path QA FAILED for ", sum(!qa_base$qa_pass), " pair(s); see ",
       "tbl_12_lcp_qa.csv.", call. = FALSE)
}
rule(sprintf(paste0("STEP 10.3 done — all %d pairs pass QA. Next: STEP 10.4 ",
                    "variant paths (task 10.7)."), nrow(qa_base)))

# =============================================================================
# STEP 10.4 — variant paths, their QA, and the Decision-18 comparison
# =============================================================================
# The same pairs and reserve cells on each variant surface (Decision 17 point
# 1), the same engine settings, the same QA as STEP 10.3. Then Decision 18:
# each variant against the baseline, on every pair that is not contiguous.
# Labels are applied by the rule fixed in Decision 18, before any variant
# path was examined.
rule("STEP 10.4 — variant paths + QA + Decision-18 comparison")
base_na <- is.na(terra::values(lcp_base, mat = FALSE))
paths_var <- list()
qa_all <- list(baseline = qa_base)
for (v in LCP_COMPARE_VARIANTS) {
  r_v <- terra::rast(resist_in[[v]])
  if (!identical(is.na(terra::values(r_v, mat = FALSE)), base_na)) {
    stop("Surface '", v, "' has a different NA footprint from the baseline; ",
         "the reserve cells and pairs would not carry over.", call. = FALSE)
  }
  t_v <- Sys.time()
  G_v <- lcp_build_graph(r_v, res_cells, neighbours = LCP_NEIGHBOURS,
                         knight_rule = LCP_KNIGHT_RULE)
  pv <- lcp_paths_for_pairs(G_v, r_v, res_net, res_cells, pairs, surface = v)
  pv <- lcp_apply_through_rule(pv, pairs, res_net, res_cells)
  rm(G_v); invisible(gc())
  qa_v <- lcp_qa_paths(pv, r_v, res_net, res_cells, pairs)
  cat(sprintf(paste0("%-7s paths %d, contiguous %d, no path %d | not in ",
                     "network %d | QA failures %d | %.0f s\n"),
              v, sum(pv$path_status == "path"),
              sum(pv$path_status == "contiguous"),
              sum(pv$path_status == "no_path"), sum(!pv$in_network),
              sum(!qa_v$qa_pass),
              as.numeric(difftime(Sys.time(), t_v, units = "secs"))))
  lcp_write_layer(pv, paths_out, v)
  paths_var[[v]] <- pv
  qa_all[[v]] <- qa_v
}
qa_all <- do.call(rbind, qa_all)
rownames(qa_all) <- NULL
write_table(qa_all, 12, "lcp_qa")
if (!all(qa_all$qa_pass)) {
  print(qa_all[!qa_all$qa_pass, c("surface", "pair_id", "from_name", "to_name",
                                  "path_status", chk_cols)], row.names = FALSE)
  stop("Path QA FAILED on ", sum(!qa_all$qa_pass), " row(s); see ",
       "tbl_12_lcp_qa.csv.", call. = FALSE)
}

cmp <- lapply(LCP_COMPARE_VARIANTS, function(v) {
  lcp_compare_variant(paths_base, paths_var[[v]],
                      d_km = LCP_COMPARE_ROUTE_D_KM,
                      descr_km = LCP_COMPARE_ROUTE_D_DESCR_KM,
                      route_material = LCP_COMPARE_ROUTE_MATERIAL,
                      rank_material = LCP_COMPARE_RANK_MATERIAL)
})
names(cmp) <- LCP_COMPARE_VARIANTS
cmp_summary <- lcp_compare_summary(cmp, n_contiguous = sum(pairs$contiguous),
                                   max_share = LCP_COMPARE_ROBUST_MAX_SHARE,
                                   min_rho = LCP_COMPARE_ROBUST_MIN_RHO)
cmp_all <- do.call(rbind, cmp)
rownames(cmp_all) <- NULL
write_table(cmp_all, 12, "lcp_variant_comparison")
write_table(cmp_summary, 12, "lcp_variant_summary")

cat(sprintf(paste0("Decision 18: d = %s km; material route < %s; material ",
                   "rank change >= %s; robust if material share <= %s and ",
                   "rho >= %s\n"),
            format(LCP_COMPARE_ROUTE_D_KM), format(LCP_COMPARE_ROUTE_MATERIAL),
            format(LCP_COMPARE_RANK_MATERIAL),
            format(LCP_COMPARE_ROBUST_MAX_SHARE),
            format(LCP_COMPARE_ROBUST_MIN_RHO)))
print(cmp_summary, row.names = FALSE, digits = 3)
for (v in LCP_COMPARE_VARIANTS) {
  m <- cmp[[v]][cmp[[v]]$material_pair, ]
  if (nrow(m) > 0) {
    cat(sprintf("material pairs, %s (%d):\n", v, nrow(m)))
    print(m[order(m$route_overlap), c("pair_id", "from_name", "to_name",
            "route_overlap", "rank_change", "material_route", "material_rank")],
          row.names = FALSE, digits = 3)
  }
}
rule(sprintf(paste0("STEP 10.4 done — labels: gHM multiplier %s; road value %s. ",
                    "Next: STEP 10.5 NTCA overlap (task 10.8)."),
             cmp_summary$choice_label[cmp_summary$variant == "noghm"],
             cmp_summary$choice_label[cmp_summary$variant == "road15"]))

# =============================================================================
# STEP 10.5 — NTCA corridor overlap, baseline (task 10.8; Decision 17 point 9)
# =============================================================================
# Descriptive only, NOT a validation: the NTCA corridors (Qureshi et al. 2014)
# come from a different method. (i) per pair: path length inside any corridor
# polygon and its share; (ii) per corridor: whether at least one baseline path
# crosses it. No buffer (Decision 17 fixes none), so a path that runs 1 km
# beside a corridor counts as outside it.
if (isTRUE(LCP_NTCA_OVERLAP)) {
  rule("STEP 10.5 — NTCA corridor overlap (baseline; descriptive, not a validation)")
  if (!file.exists(corridors_in)) {
    stop("Corridor layer not found: ", corridors_in, call. = FALSE)
  }
  corr_sf <- read_vec(corridors_in)
  if (nrow(corr_sf) != 59L) {
    warning("Expected 59 NTCA corridor polygons, found ", nrow(corr_sf), ".")
  }
  ov <- lcp_ntca_overlap(paths_base, corr_sf)
  op <- ov$per_path[ov$per_path$path_status == "path", ]
  oc <- ov$per_corridor
  cat(sprintf(paste0("paths: %d | share inside corridors: median %.3f, mean %.3f",
                     " | paths with share 0: %d | paths crossing >= 1 ",
                     "corridor: %d\n"),
              nrow(op), stats::median(op$share_in_corridor),
              mean(op$share_in_corridor), sum(op$share_in_corridor == 0),
              sum(op$n_corridors_crossed > 0)))
  cat(sprintf("corridors crossed by >= 1 baseline path: %d of %d\n",
              sum(oc$crossed), nrow(oc)))
  cat("paths with the highest share inside corridors:\n")
  print(utils::head(op[order(-op$share_in_corridor),
        c("pair_id", "from_name", "to_name", "path_km", "km_in_corridor",
          "share_in_corridor", "corridor_ids")], 5), row.names = FALSE, digits = 3)
  if (any(!oc$crossed)) {
    cat("corridors crossed by no baseline path:\n")
    print(oc[!oc$crossed, c("corridor_id", "corridor_label", "state",
                            "area_km2")], row.names = FALSE)
  }
  write_table(ov$per_path, 12, "lcp_ntca_overlap")
  write_table(ov$per_corridor, 12, "lcp_ntca_corridors")
  rule("STEP 10.5 done — NTCA overlap written (descriptive). Week-10 STEPs complete.")
}

# =============================================================================
# WEEK 11 — reserve network graph (Decision 19)
# =============================================================================
# Functions: R/00_functions_network.R. Every Decision-19 value is read from
# R/00_config.R (NET_*). The Week-11 STEPs read the path layers from disk (the
# file that STEPs 10.2 and 10.4 wrote in this run); `pairs` and `res_net` come
# from STEP 10.1.
source(here("R", "00_functions_network.R"))

# ---- Guard: settings --------------------------------------------------------
net_params <- c("NET_LINK_RULE", "NET_EDGE_WEIGHT_FIELD", "NET_CONTIGUOUS_RULE",
                "NET_PARALLEL_RULE", "NET_EXPECTED_RESERVES",
                "NET_EXPECTED_NODES", "NET_NORM_RULE", "NET_NORM_MIN_SET_NODES",
                "NET_LINCHPIN_TOP_N", "NET_THRESHOLD_SCAN",
                "NET_THRESHOLD_SCAN_SURF", "NET_NOCROSS_RERUN",
                "NET_NOCROSS_SURF", "NET_COMPARE_VARIANTS",
                "NET_COMPARE_ROBUST_MIN_RHO",
                "NET_COMPARE_ROBUST_MIN_RETENTION")
missing_net <- net_params[!vapply(net_params, exists, logical(1))]
if (length(missing_net) > 0) {
  stop("Decision-19 setting(s) missing from R/00_config.R: ",
       paste(missing_net, collapse = ", "), call. = FALSE)
}
# The functions build one rule set only (Decision 19 points 1-3). A different
# value in the config needs a new Decision and new code, not a silent run.
if (!identical(NET_LINK_RULE, "all_in_network") ||
    !identical(NET_CONTIGUOUS_RULE, "merge_block") ||
    !identical(NET_PARALLEL_RULE, "min_cost")) {
  stop("R/00_functions_network.R builds only NET_LINK_RULE = 'all_in_network', ",
       "NET_CONTIGUOUS_RULE = 'merge_block', NET_PARALLEL_RULE = 'min_cost' ",
       "(Decision 19). The config has: ", NET_LINK_RULE, ", ",
       NET_CONTIGUOUS_RULE, ", ", NET_PARALLEL_RULE, ".", call. = FALSE)
}

# =============================================================================
# STEP 11.1 — nodes, link table and graph (task 11.2; Decision 19 points 1-4)
# =============================================================================
# 1. Nodes: the contiguous pairs join their reserves into blocks; one block or
#    one reserve = one node. Geometry only: the same on every surface.
# 2. Links: every baseline pair with in_network == TRUE. No cost threshold.
# 3. Edges: between two nodes, the pair with the lowest cost (a tie: the
#    lowest pair_id). The other in-network pairs stay in the table with their
#    link_role (block, within_block, parallel).
# 4. Construction checks (Decision 19 point 11): any failure stops the script.
# 5. Edge flags: is_bridge, in_mst (the spanning forest of the threshold scan,
#    point 8). No node metric is computed here (STEP 11.2).
rule("STEP 11.1 — nodes, links, graph (Decision 19) -> tbl_13_network_links.csv")

NET_BASE_SURFACE <- "baseline"   # the layer name that STEP 10.2 writes

# ---- 11.1a Nodes --------------------------------------------------------------
net_nodes <- net_build_nodes(res_net$unit_id, res_net$unit_name, pairs,
                             NETWORK_GROUPS)
net_blocks <- unique(net_nodes[net_nodes$block_size > 1,
                               c("node_id", "node_name", "block_size")])
cat(sprintf("nodes: %d from %d reserves | blocks with more than one reserve: %d\n",
            length(unique(net_nodes$node_id)), nrow(net_nodes), nrow(net_blocks)))
if (nrow(net_blocks) > 0) print(net_blocks, row.names = FALSE)

# ---- 11.1b Links and graph ----------------------------------------------------
paths_net_base <- net_read_paths(paths_out, NET_BASE_SURFACE)
if (nrow(paths_net_base) != nrow(pairs) ||
    !setequal(paths_net_base$pair_id, pairs$pair_id)) {
  stop("The baseline layer on disk (", nrow(paths_net_base), " pairs) does not ",
       "hold the pairs of STEP 10.1 (", nrow(pairs), ").", call. = FALSE)
}
net_links <- net_build_links(paths_net_base, net_nodes, NET_EDGE_WEIGHT_FIELD)
net_g     <- net_build_graph(net_links, net_nodes, NET_EDGE_WEIGHT_FIELD)

cat(sprintf("pairs: %d | in the network (links): %d | not in the network: %d\n",
            nrow(paths_net_base), nrow(net_links),
            nrow(paths_net_base) - nrow(net_links)))
cat("link roles:\n")
print(table(link_role = factor(net_links$link_role,
                               levels = c("block", "within_block", "edge",
                                          "parallel"))))
cat(sprintf("graph: %d nodes, %d edges | nodes with no edge: %d\n",
            igraph::vcount(net_g), igraph::ecount(net_g),
            sum(igraph::degree(net_g) == 0)))
if (any(net_links$link_role == "parallel")) {
  cat("parallel links (in the network, not the lowest cost between two nodes):\n")
  print(net_links[net_links$link_role == "parallel",
                  c("pair_id", "from_name", "to_name", NET_EDGE_WEIGHT_FIELD)],
        row.names = FALSE, digits = 6)
}

# ---- 11.1c Construction checks (stop on any failure) --------------------------
net_chk <- net_check_graph(net_g, net_nodes, net_links, NET_EXPECTED_RESERVES,
                           NET_EXPECTED_NODES)
for (i in seq_len(nrow(net_chk))) {
  cat(sprintf("  %-4s %s (%s)\n", if (net_chk$pass[i]) "ok" else "FAIL",
              net_chk$check[i], net_chk$value[i]))
}
if (!all(net_chk$pass)) {
  stop("Network construction check(s) failed: ",
       paste(net_chk$check[!net_chk$pass], collapse = "; "), call. = FALSE)
}

# ---- 11.1d Sets (report) -------------------------------------------------------
net_set_tbl <- net_sets(net_g)
net_nodes$set_id <- net_set_tbl$set_id[match(net_nodes$node_id,
                                             net_set_tbl$node_id)]
set_report <- do.call(rbind, lapply(sort(unique(net_nodes$set_id)), function(k) {
  x <- net_nodes[net_nodes$set_id == k, ]
  data.frame(set_id = k, nodes = length(unique(x$node_id)), reserves = nrow(x),
             network_groups = paste(sort(unique(x$network_group)),
                                    collapse = ", "))
}))
cat("sets (connected components of the in-network graph):\n")
print(set_report, row.names = FALSE)

# Report only (Decision 19 point 11): are these the sets that ALL pairs give?
# If not, the through-reserve rule (P3) divided a set.
all_as_links <- paths_net_base
all_as_links$in_network <- TRUE
net_g_all <- net_build_graph(
  net_build_links(all_as_links, net_nodes, NET_EDGE_WEIGHT_FIELD),
  net_nodes, NET_EDGE_WEIGHT_FIELD)
sets_all  <- net_sets(net_g_all)
sets_same <- net_same_partition(net_set_tbl$set_id, sets_all$set_id)
cat(sprintf(paste0("sets of all %d pairs: sizes %s (nodes) | the in-network ",
                   "graph has the same sets: %s\n"),
            nrow(pairs),
            paste(sort(unique(sets_all[, c("set_id", "set_size")])$set_size,
                       decreasing = TRUE), collapse = ", "),
            if (sets_same) "yes" else "NO — P3 divided a set (report it)"))
rm(all_as_links, net_g_all, sets_all)

# ---- 11.1e Edge flags ----------------------------------------------------------
net_flags <- net_edge_flags(net_g)
k_flag <- match(net_links$pair_id, net_flags$pair_id)   # NA for non-edges
net_links$is_bridge <- net_flags$is_bridge[k_flag]
net_links$in_mst    <- net_flags$in_mst[k_flag]
cat(sprintf(paste0("edges: %d | bridges (the set divides without the edge): %d",
                   " | in the minimum spanning forest: %d\n"),
            nrow(net_flags), sum(net_flags$is_bridge), sum(net_flags$in_mst)))
if (anyDuplicated(net_links[[NET_EDGE_WEIGHT_FIELD]][net_links$link_role == "edge"])) {
  cat("NOTE: two edges have the same weight — the spanning forest is not ",
      "unique (in_mst).\n", sep = "")
}
if (any(net_flags$is_bridge)) {
  cat("bridges:\n")
  print(net_links[which(net_links$is_bridge),
                  c("pair_id", "from_name", "to_name", "cross_group",
                    NET_EDGE_WEIGHT_FIELD)], row.names = FALSE, digits = 6)
}

# ---- 11.1f Output ---------------------------------------------------------------
links_out <- net_links[, c("pair_id", "surface", "from_unit_id", "from_name",
                           "to_unit_id", "to_name", "from_group", "to_group",
                           "cross_group", "contiguous", "gap_km",
                           NET_EDGE_WEIGHT_FIELD, "path_km", "from_node_id",
                           "to_node_id", "link_role", "is_bridge", "in_mst")]
write_table(links_out, 13, "network_links")
rule(sprintf(paste0("STEP 11.1 done — %d nodes, %d edges, %d sets. Next: STEP ",
                    "11.2 metrics (task 11.3)."),
             igraph::vcount(net_g), igraph::ecount(net_g),
             nrow(set_report)))

# =============================================================================
# STEP 11.2 — node metrics, second run, threshold scan (task 11.3;
#             Decision 19 points 4-9)
# =============================================================================
# 1. Self-test: the metric and scan functions run on a hand-computed graph
#    first (Decision 19 point 11). A failure stops the script.
# 2. Metrics for each node of the baseline graph (points 4-7). Betweenness is
#    normalised by the node's own set.
# 3. Second run, baseline only (point 9): the same graph without the pairs
#    with cross_group == TRUE. cross_group_dependent = a linchpin of the main
#    graph that is not a linchpin in the second run.
# 4. Threshold scan, baseline only (point 8). Descriptive: no threshold is
#    chosen and no link is removed.
# 5. One row per reserve: the reserves of one block share the node values.
rule(paste0("STEP 11.2 — metrics, second run, threshold scan -> ",
            "tbl_13_network_metrics.csv, tbl_13_network_threshold_scan.csv"))

# ---- Guard: settings that this STEP builds -------------------------------------
if (!identical(NET_NORM_RULE, "own_set")) {
  stop("STEP 11.2 builds only NET_NORM_RULE = 'own_set' (Decision 19 point 5). ",
       "The config has: ", NET_NORM_RULE, ".", call. = FALSE)
}
if (!identical(NET_NOCROSS_SURF, NET_BASE_SURFACE) ||
    !identical(NET_THRESHOLD_SCAN_SURF, NET_BASE_SURFACE)) {
  stop("The second run and the threshold scan are for the '", NET_BASE_SURFACE,
       "' surface only (Decision 19 points 8 and 9). The config has: ",
       NET_NOCROSS_SURF, ", ", NET_THRESHOLD_SCAN_SURF, ".", call. = FALSE)
}

# ---- 11.2a Self-test (hand-computed graph) --------------------------------------
net_st <- net_selftest_metrics()
cat(sprintf("self-test on the hand-computed graph: %d of %d cases pass\n",
            sum(net_st$pass), nrow(net_st)))
if (!all(net_st$pass)) {
  print(net_st[!net_st$pass, ], row.names = FALSE, right = FALSE)
  stop("The metric self-test failed — the functions are wrong. No metric is ",
       "computed.", call. = FALSE)
}

# ---- 11.2b Node metrics, baseline ------------------------------------------------
net_met <- net_node_metrics(net_g, NET_NORM_MIN_SET_NODES, NET_LINCHPIN_TOP_N)
net_node_names <- unique(net_nodes[, c("node_id", "node_name", "network_group")])
net_node_names <- stats::aggregate(
  network_group ~ node_id + node_name, data = net_node_names,
  FUN = function(x) paste(sort(unique(x)), collapse = ", "))
met_show <- merge(net_node_names, net_met, by = "node_id")

cat(sprintf(paste0("nodes: %d | sets: %d | betweenness_norm is NA (set below ",
                   "%d nodes): %d\n"),
            nrow(net_met), length(unique(net_met$set_id)),
            NET_NORM_MIN_SET_NODES, sum(is.na(net_met$betweenness_norm))))
cat(sprintf("linchpins (rank <= %d in the set, value > 0): %d | cut nodes: %d\n",
            NET_LINCHPIN_TOP_N, sum(net_met$linchpin), sum(net_met$cut_node)))
cat("linchpins, by set:\n")
print(met_show[met_show$linchpin,
               c("set_id", "set_size", "node_name", "betweenness_raw",
                 "betweenness_norm", "betweenness_rank", "cut_node", "degree")
               ][order(met_show$set_id[met_show$linchpin],
                       met_show$betweenness_rank[met_show$linchpin]), ],
      row.names = FALSE, digits = 4)
if (any(net_met$cut_node & !net_met$linchpin)) {
  cat("cut nodes that are not linchpins:\n")
  print(met_show[met_show$cut_node & !met_show$linchpin,
                 c("set_id", "node_name", "betweenness_norm",
                   "betweenness_rank", "degree")], row.names = FALSE, digits = 4)
}
if (any(net_met$isolated)) {
  cat("isolated nodes (degree 0):\n")
  print(met_show[met_show$isolated, c("node_id", "node_name")], row.names = FALSE)
} else {
  cat("isolated nodes (degree 0): none — no reserve is isolated by this rule\n")
}
cat(sprintf("pendant nodes (degree 1): %d\n", sum(net_met$pendant)))
if (any(net_met$pendant)) {
  print(met_show[met_show$pendant,
                 c("set_id", "node_name", "cheapest_link_rkm",
                   "cheapest_link_rank")][order(
                     met_show$cheapest_link_rank[met_show$pendant]), ],
        row.names = FALSE, digits = 6)
}
cat("highest cheapest-link cost (the nodes hardest to reach from a neighbour):\n")
print(utils::head(met_show[order(met_show$cheapest_link_rank),
                           c("node_name", "degree", "cheapest_link_rkm",
                             "cheapest_link_rank")], 5),
      row.names = FALSE, digits = 6)

# ---- 11.2c Second run without cross-group links (baseline) ----------------------
nocross_cols <- c("set_id_nocross", "set_size_nocross",
                  "betweenness_norm_nocross", "betweenness_rank_nocross",
                  "linchpin_nocross", "cross_group_dependent")
if (isTRUE(NET_NOCROSS_RERUN)) {
  net_links_nc <- net_build_links(paths_net_base, net_nodes,
                                  NET_EDGE_WEIGHT_FIELD,
                                  exclude_cross_group = TRUE)
  net_g_nc   <- net_build_graph(net_links_nc, net_nodes, NET_EDGE_WEIGHT_FIELD)
  net_met_nc <- net_node_metrics(net_g_nc, NET_NORM_MIN_SET_NODES,
                                 NET_LINCHPIN_TOP_N)
  if (!identical(net_met_nc$node_id, net_met$node_id)) {
    stop("The second run does not have the nodes of the main graph.",
         call. = FALSE)
  }
  net_met$set_id_nocross           <- net_met_nc$set_id
  net_met$set_size_nocross         <- net_met_nc$set_size
  net_met$betweenness_norm_nocross <- net_met_nc$betweenness_norm
  net_met$betweenness_rank_nocross <- net_met_nc$betweenness_rank
  net_met$linchpin_nocross         <- net_met_nc$linchpin
  net_met$cross_group_dependent    <- net_met$linchpin & !net_met_nc$linchpin

  n_cross_links <- sum(paths_net_base$in_network & paths_net_base$cross_group)
  cat(sprintf(paste0("second run: %d cross-group link(s) removed | edges %d -> ",
                     "%d | sets %d -> %d (sizes %s)\n"),
              n_cross_links, igraph::ecount(net_g), igraph::ecount(net_g_nc),
              length(unique(net_met$set_id)), length(unique(net_met_nc$set_id)),
              paste(sort(net_met_nc$set_size[!duplicated(net_met_nc$set_id)],
                         decreasing = TRUE), collapse = ", ")))
  nc_show <- merge(net_node_names,
                   net_met[, c("node_id", "set_id", "betweenness_norm",
                               "betweenness_rank", "linchpin", nocross_cols)],
                   by = "node_id")
  cat("linchpins in the second run, by set:\n")
  print(nc_show[nc_show$linchpin_nocross,
                c("set_id_nocross", "set_size_nocross", "node_name",
                  "betweenness_norm_nocross", "betweenness_rank_nocross")
                ][order(nc_show$set_id_nocross[nc_show$linchpin_nocross],
                        nc_show$betweenness_rank_nocross[nc_show$linchpin_nocross]), ],
        row.names = FALSE, digits = 4)
  if (any(net_met$cross_group_dependent)) {
    cat("cross_group_dependent (linchpin in the main graph, not in the second run):\n")
    print(nc_show[nc_show$cross_group_dependent,
                  c("node_name", "betweenness_norm", "betweenness_rank",
                    "betweenness_norm_nocross", "betweenness_rank_nocross")],
          row.names = FALSE, digits = 4)
  } else {
    cat("cross_group_dependent: none\n")
  }
} else {
  cat("NET_NOCROSS_RERUN is FALSE: the second run is skipped; its columns are NA.\n")
  net_met[nocross_cols] <- NA
}

# ---- 11.2d Threshold scan (baseline; descriptive) --------------------------------
if (isTRUE(NET_THRESHOLD_SCAN)) {
  net_scan <- net_threshold_scan(net_g)
  # The joining edges of the scan are the spanning-forest edges of STEP 11.1.
  if (!setequal(net_scan$pair_id[net_scan$joins_sets],
                net_flags$pair_id[net_flags$in_mst])) {
    stop("Threshold scan: the joining edges are not the spanning-forest edges ",
         "of STEP 11.1 (in_mst).", call. = FALSE)
  }
  k_scan <- match(net_scan$pair_id, net_links$pair_id)
  scan_out <- data.frame(
    step              = net_scan$step,
    pair_id           = net_scan$pair_id,
    from_name         = net_links$from_name[k_scan],
    to_name           = net_links$to_name[k_scan],
    threshold_rkm     = net_scan$threshold_rkm,
    n_sets            = net_scan$n_sets,
    largest_set_nodes = net_scan$largest_set_nodes,
    joins_sets        = net_scan$joins_sets)
  cat(sprintf(paste0("threshold scan: %d edges | joining edges: %d | sets at ",
                     "the end: %d | no threshold chosen\n"),
              nrow(scan_out), sum(scan_out$joins_sets),
              scan_out$n_sets[nrow(scan_out)]))
  cat("the last joining edges (the highest cost at which two sets join):\n")
  print(utils::tail(scan_out[scan_out$joins_sets, ], 5), row.names = FALSE,
        digits = 6)
  write_table(scan_out, 13, "network_threshold_scan")
} else {
  cat("NET_THRESHOLD_SCAN is FALSE: the threshold scan is skipped.\n")
}

# ---- 11.2e Output: one row per reserve --------------------------------------------
k_met <- match(net_nodes$node_id, net_met$node_id)
if (anyNA(k_met)) stop("A reserve has no node metrics.", call. = FALSE)
metrics_out <- cbind(
  net_nodes[, c("unit_id", "unit_name", "network_group", "node_id", "node_name",
                "block_size")],
  net_met[k_met, setdiff(names(net_met), "node_id")])
metrics_out <- metrics_out[order(metrics_out$unit_id), ]
rownames(metrics_out) <- NULL
if (nrow(metrics_out) != NET_EXPECTED_RESERVES ||
    anyDuplicated(metrics_out$unit_id)) {
  stop("Metrics table: ", nrow(metrics_out), " rows, expected one row for ",
       "each of the ", NET_EXPECTED_RESERVES, " network reserves.",
       call. = FALSE)
}
write_table(metrics_out, 13, "network_metrics")
rule(sprintf(paste0("STEP 11.2 done — %d linchpin nodes, %d cut nodes, %d ",
                    "isolated, %d pendant. Next: STEP 11.3 variants (task 11.4)."),
             sum(net_met$linchpin), sum(net_met$cut_node),
             sum(net_met$isolated), sum(net_met$pendant)))

# =============================================================================
# STEP 11.3 — variants and the Decision-19 comparison (task 11.4; point 10)
# =============================================================================
# 1. For noghm, road15 and road50: the links, the graph and the node metrics,
#    by the same rules and the same functions as the baseline. The nodes are
#    the same (blocks come from geometry). Each variant graph gets the
#    construction checks of STEP 11.1; a failure stops the script.
# 2. Each variant is compared with the baseline only. The label rule was
#    fixed in Decision 19 before any metric: "robust" if the sets are the
#    same AND Spearman rho of betweenness_norm >= NET_COMPARE_ROBUST_MIN_RHO
#    AND linchpin retention >= NET_COMPARE_ROBUST_MIN_RETENTION.
# 3. A choice tested by two variants (the road value) is robust only if both
#    are robust.
# 4. stable_linchpin = a linchpin on the baseline and on every variant.
# The second run (point 9) and the threshold scan (point 8) are for the
# baseline only; they are not repeated here.
rule(paste0("STEP 11.3 — variants (", paste(NET_COMPARE_VARIANTS, collapse = ", "),
            ") -> tbl_13_network_variant_comparison.csv"))

if (!all(NET_COMPARE_VARIANTS %in% names(RESIST_VARIANTS)) ||
    NET_BASE_SURFACE %in% NET_COMPARE_VARIANTS ||
    anyDuplicated(NET_COMPARE_VARIANTS) || length(NET_COMPARE_VARIANTS) == 0) {
  stop("NET_COMPARE_VARIANTS must name one or more of RESIST_VARIANTS (",
       paste(names(RESIST_VARIANTS), collapse = ", "), "), each one time.",
       call. = FALSE)
}

# Which choice does a variant test? From RESIST_VARIANTS: the setting that
# differs from the baseline.
net_variant_tests <- vapply(NET_COMPARE_VARIANTS, function(v) {
  d <- c(if (!isTRUE(all.equal(RESIST_VARIANTS[[v]]$ghm_k, RESIST_GHM_K)))
           "gHM multiplier (Decision 14)",
         if (!isTRUE(all.equal(RESIST_VARIANTS[[v]]$road_value,
                               ROAD_BARRIER_VALUE)))
           "road value (Decision 15)")
  if (length(d) != 1L) {
    stop("Variant '", v, "' must differ from the baseline in exactly one ",
         "choice (found ", length(d), ").", call. = FALSE)
  }
  d
}, character(1))

net_var_met   <- list()
net_var_chk   <- list()   # kept for STEP 11.4
net_var_g     <- list()
net_var_paths <- list()
net_cmp_rows  <- list()
for (v in NET_COMPARE_VARIANTS) {
  paths_v <- net_read_paths(paths_out, v)
  if (nrow(paths_v) != nrow(pairs) ||
      !setequal(paths_v$pair_id, pairs$pair_id)) {
    stop("Layer '", v, "' on disk (", nrow(paths_v), " pairs) does not hold ",
         "the pairs of STEP 10.1 (", nrow(pairs), ").", call. = FALSE)
  }
  links_v <- net_build_links(paths_v, net_nodes, NET_EDGE_WEIGHT_FIELD)
  g_v     <- net_build_graph(links_v, net_nodes, NET_EDGE_WEIGHT_FIELD)
  chk_v   <- net_check_graph(g_v, net_nodes, links_v, NET_EXPECTED_RESERVES,
                             NET_EXPECTED_NODES)
  if (!all(chk_v$pass)) {
    stop("Network construction check(s) failed on '", v, "': ",
         paste(chk_v$check[!chk_v$pass], collapse = "; "), call. = FALSE)
  }
  met_v <- net_node_metrics(g_v, NET_NORM_MIN_SET_NODES, NET_LINCHPIN_TOP_N)
  # The baseline metrics without the second-run columns of STEP 11.2c.
  cmp_v <- net_compare_variant(net_links, net_met, links_v, met_v,
                               net_node_names, NET_COMPARE_ROBUST_MIN_RHO,
                               NET_COMPARE_ROBUST_MIN_RETENTION)
  net_var_met[[v]]   <- met_v
  net_var_chk[[v]]   <- chk_v
  net_var_g[[v]]     <- g_v
  net_var_paths[[v]] <- paths_v
  net_cmp_rows[[v]] <- cbind(
    data.frame(variant = v, tests = unname(net_variant_tests[v]),
               stringsAsFactors = FALSE), cmp_v)
  cat(sprintf(paste0("%-7s links %d | edges %d (changed %d) | checks %d of %d ",
                     "| sets same: %s | rho %.3f | linchpins retained %d of %d ",
                     "| %s\n"),
              v, nrow(links_v), igraph::ecount(g_v), cmp_v$n_edges_changed,
              sum(chk_v$pass), nrow(chk_v), cmp_v$sets_same, cmp_v$rho,
              cmp_v$n_linchpins_retained, cmp_v$n_linchpins_baseline,
              cmp_v$label))
  if (nzchar(cmp_v$linchpins_lost)) {
    cat("          linchpins lost:   ", cmp_v$linchpins_lost, "\n", sep = "")
  }
  if (nzchar(cmp_v$linchpins_gained)) {
    cat("          linchpins gained: ", cmp_v$linchpins_gained, "\n", sep = "")
  }
}
net_cmp <- do.call(rbind, net_cmp_rows)
rownames(net_cmp) <- NULL

# ---- Labels by choice (fixed in Decision 19 point 10) ---------------------------
net_choice <- tapply(net_cmp$label == "robust", net_cmp$tests, all)
net_choice_label <- ifelse(net_choice, "robust", "sensitive")
cat(sprintf(paste0("limits: rho >= %s, linchpin retention >= %.3f (judgement ",
                   "values, Decision 19)\n"),
            format(NET_COMPARE_ROBUST_MIN_RHO), NET_COMPARE_ROBUST_MIN_RETENTION))
for (ch in names(net_choice_label)) {
  cat(sprintf("label — %s: %s (variants: %s)\n", ch, net_choice_label[[ch]],
              paste(net_cmp$variant[net_cmp$tests == ch], collapse = ", ")))
}
write_table(net_cmp, 13, "network_variant_comparison")

# ---- Variant columns and stable_linchpin in the metrics table --------------------
stable <- net_met$linchpin
for (v in NET_COMPARE_VARIANTS) {
  if (!identical(net_var_met[[v]]$node_id, net_met$node_id)) {
    stop("Variant '", v, "' does not have the nodes of the baseline.",
         call. = FALSE)
  }
  net_met[[paste0("betweenness_norm_", v)]] <- net_var_met[[v]]$betweenness_norm
  stable <- stable & net_var_met[[v]]$linchpin
}
for (v in NET_COMPARE_VARIANTS) {
  net_met[[paste0("linchpin_", v)]] <- net_var_met[[v]]$linchpin
}
net_met$stable_linchpin <- stable

stab_show <- merge(net_node_names,
                   net_met[, c("node_id", "set_id", "betweenness_rank",
                               "linchpin",
                               paste0("linchpin_", NET_COMPARE_VARIANTS),
                               "stable_linchpin")], by = "node_id")
any_lp <- rowSums(stab_show[, c("linchpin",
                                paste0("linchpin_", NET_COMPARE_VARIANTS))]) > 0
cat(sprintf("stable linchpins (on all %d surfaces): %d of %d baseline linchpins\n",
            length(NET_COMPARE_VARIANTS) + 1L, sum(net_met$stable_linchpin),
            sum(net_met$linchpin)))
cat("nodes that are a linchpin on one surface or more:\n")
print(stab_show[any_lp, c("set_id", "node_name", "linchpin",
                          paste0("linchpin_", NET_COMPARE_VARIANTS),
                          "stable_linchpin")][order(
                            stab_show$set_id[any_lp],
                            stab_show$betweenness_rank[any_lp]), ],
      row.names = FALSE)

metrics_out <- cbind(
  net_nodes[, c("unit_id", "unit_name", "network_group", "node_id", "node_name",
                "block_size")],
  net_met[k_met, setdiff(names(net_met), "node_id")])
metrics_out <- metrics_out[order(metrics_out$unit_id), ]
rownames(metrics_out) <- NULL
if (nrow(metrics_out) != NET_EXPECTED_RESERVES ||
    anyDuplicated(metrics_out$unit_id)) {
  stop("Metrics table: ", nrow(metrics_out), " rows, expected one row for ",
       "each of the ", NET_EXPECTED_RESERVES, " network reserves.",
       call. = FALSE)
}
write_table(metrics_out, 13, "network_metrics")
rule(sprintf("STEP 11.3 done — labels: %s. Next: STEP 11.4 network QA (task 11.5).",
             paste(sprintf("%s %s", sub(" \\(Decision.*$", "",
                                        names(net_choice_label)),
                           net_choice_label), collapse = "; ")))

# =============================================================================
# STEP 11.4 — network QA (task 11.5; Decision 19 point 11)
# =============================================================================
# 1. Collected: the construction checks of the four surfaces (STEPs 11.1 and
#    11.3) and the self-test on the hand-computed graph (STEP 11.2).
# 2. On each surface: result checks on the metrics; the betweenness identity
#    (the sum of betweenness in a set against the shortest paths of the graph,
#    without betweenness()); each edge weight against the layer.
# 3. Baseline: block members share the node values; the second run; the
#    threshold scan; bridges; the variant flags.
# 4. The tables on disk have the rows that this run wrote.
# The table is written first; then any failure stops the script.
rule("STEP 11.4 — network QA -> tbl_13_network_qa.csv")

qa_row <- function(surface, check, value, pass) {
  data.frame(surface = surface, check = check, value = as.character(value),
             pass = isTRUE(pass), stringsAsFactors = FALSE)
}
qa_tag <- function(surface, tbl) {
  data.frame(surface = surface, tbl[, c("check", "value", "pass")],
             stringsAsFactors = FALSE)
}
net_base_cols <- c("node_id", "set_id", "set_size", "set_reserves", "degree",
                   "betweenness_raw", "betweenness_norm", "betweenness_rank",
                   "linchpin", "cut_node", "isolated", "pendant",
                   "cheapest_link_rkm", "cheapest_link_rank")
qa_surfaces <- c(
  stats::setNames(list(list(chk = net_chk, g = net_g, paths = paths_net_base,
                            met = net_met[, net_base_cols])), NET_BASE_SURFACE),
  lapply(stats::setNames(NET_COMPARE_VARIANTS, NET_COMPARE_VARIANTS),
         function(v) list(chk = net_var_chk[[v]], g = net_var_g[[v]],
                          paths = net_var_paths[[v]], met = net_var_met[[v]])))

# ---- 11.4a Self-test (collected) --------------------------------------------------
net_qa <- qa_row("test graph", "hand-computed self-test of the metric and scan functions",
                 sprintf("%d of %d cases", sum(net_st$pass), nrow(net_st)),
                 all(net_st$pass))

# ---- 11.4b Each surface ------------------------------------------------------------
for (sf_name in names(qa_surfaces)) {
  q   <- qa_surfaces[[sf_name]]
  idn <- net_betweenness_identity(q$g, q$met)
  net_qa <- rbind(
    net_qa,
    qa_tag(sf_name, q$chk),
    qa_tag(sf_name, net_check_metrics(q$met, NET_NORM_MIN_SET_NODES,
                                      NET_LINCHPIN_TOP_N)),
    qa_row(sf_name,
           "sum of betweenness = nodes between the ends of the shortest paths, by set",
           paste(sprintf("set %d: %s = %s", idn$set_id,
                         trimws(format(round(idn$sum_betweenness, 6))),
                         trimws(format(round(idn$sum_path_nodes, 6)))),
                 collapse = "; "),
           all(idn$pass)),
    qa_tag(sf_name, net_check_weights(q$g, q$paths, NET_EDGE_WEIGHT_FIELD)))
}

# ---- 11.4c Baseline results ---------------------------------------------------------
n_nodes_net <- length(unique(net_nodes$node_id))
n_sets_net  <- length(unique(net_met$set_id))
node_rows   <- unique(metrics_out[, setdiff(names(metrics_out),
                                            c("unit_id", "unit_name"))])
net_qa <- rbind(
  net_qa,
  qa_row(NET_BASE_SURFACE, "metrics table: one row for each network reserve",
         nrow(metrics_out),
         nrow(metrics_out) == NET_EXPECTED_RESERVES &&
           !anyDuplicated(metrics_out$unit_id)),
  qa_row(NET_BASE_SURFACE, "the reserves of one block have the same node values",
         sprintf("%d different rows, %d nodes", nrow(node_rows), n_nodes_net),
         nrow(node_rows) == n_nodes_net),
  qa_row(NET_BASE_SURFACE, "each bridge is in the minimum spanning forest",
         sprintf("%d bridges", sum(net_flags$is_bridge)),
         all(net_flags$in_mst[net_flags$is_bridge])),
  qa_row(NET_BASE_SURFACE, "spanning-forest edges = nodes - sets",
         sprintf("%d = %d - %d", sum(net_flags$in_mst), n_nodes_net, n_sets_net),
         sum(net_flags$in_mst) == n_nodes_net - n_sets_net))

if (isTRUE(NET_NOCROSS_RERUN)) {
  # Without some links, a set can only divide: each second-run set must be
  # inside one set of the main graph.
  nc_in_main <- tapply(net_met$set_id, net_met$set_id_nocross,
                       function(x) length(unique(x)))
  net_qa <- rbind(
    net_qa,
    qa_row(NET_BASE_SURFACE, "second run: each set is inside one set of the main graph",
           sprintf("%d sets", length(nc_in_main)), all(nc_in_main == 1L)),
    qa_row(NET_BASE_SURFACE, "cross_group_dependent only on a baseline linchpin",
           sum(net_met$cross_group_dependent),
           identical(net_met$cross_group_dependent,
                     net_met$linchpin & !net_met$linchpin_nocross)))
}
if (isTRUE(NET_THRESHOLD_SCAN)) {
  net_qa <- rbind(
    net_qa,
    qa_row(NET_BASE_SURFACE, "scan: one row per edge, cost does not decrease",
           nrow(scan_out),
           nrow(scan_out) == igraph::ecount(net_g) &&
             !is.unsorted(scan_out$threshold_rkm)),
    qa_row(NET_BASE_SURFACE, "scan: joining edges = nodes - sets; the last n_sets = the sets",
           sprintf("%d joining, %d sets at the end", sum(scan_out$joins_sets),
                   scan_out$n_sets[nrow(scan_out)]),
           sum(scan_out$joins_sets) == n_nodes_net - n_sets_net &&
             scan_out$n_sets[nrow(scan_out)] == n_sets_net))
}
lp_all <- Reduce(`&`, c(list(net_met$linchpin),
                        lapply(NET_COMPARE_VARIANTS,
                               function(v) net_var_met[[v]]$linchpin)))
net_qa <- rbind(
  net_qa,
  qa_row("all", "stable_linchpin = a linchpin on the baseline and each variant",
         sum(net_met$stable_linchpin),
         identical(net_met$stable_linchpin, lp_all)),
  qa_row("all", "variant labels are robust or sensitive; one row per variant",
         paste(net_cmp$variant, net_cmp$label, collapse = "; "),
         all(net_cmp$label %in% c("robust", "sensitive")) &&
           identical(net_cmp$variant, NET_COMPARE_VARIANTS)))

# ---- 11.4d Tables on disk -------------------------------------------------------------
qa_disk <- list(network_links = nrow(links_out),
                network_metrics = nrow(metrics_out),
                network_variant_comparison = nrow(net_cmp))
if (isTRUE(NET_THRESHOLD_SCAN)) {
  qa_disk$network_threshold_scan <- nrow(scan_out)
}
for (slug in names(qa_disk)) {
  f <- file.path(DIR_TABLES, sprintf("tbl_13_%s.csv", slug))
  n_disk <- if (file.exists(f)) nrow(utils::read.csv(f)) else NA_integer_
  net_qa <- rbind(net_qa,
                  qa_row("all", sprintf("on disk: %s", basename(f)),
                         sprintf("%s rows, %d expected", n_disk, qa_disk[[slug]]),
                         !is.na(n_disk) && n_disk == qa_disk[[slug]]))
}
rownames(net_qa) <- NULL

# ---- 11.4e Report, write, stop on failure -----------------------------------------------
qa_sum <- stats::aggregate(pass ~ surface, data = net_qa,
                           FUN = function(x) sprintf("%d of %d", sum(x), length(x)))
qa_sum <- qa_sum[match(unique(net_qa$surface), qa_sum$surface), ]
names(qa_sum)[2] <- "checks_passed"
print(qa_sum, row.names = FALSE)
idn_rows <- grepl("^sum of betweenness", net_qa$check)
cat("betweenness identity (sum of betweenness = nodes between the ends of the",
    "shortest paths):\n")
for (i in which(idn_rows)) {
  cat(sprintf("  %-9s %s\n", net_qa$surface[i], net_qa$value[i]))
}
write_table(net_qa, 13, "network_qa")
if (!all(net_qa$pass)) {
  cat("FAILED checks:\n")
  print(net_qa[!net_qa$pass, ], row.names = FALSE, right = FALSE)
  stop("Network QA failed: ", sum(!net_qa$pass), " check(s). See ",
       "tbl_13_network_qa.csv.", call. = FALSE)
}
rule(sprintf(paste0("STEP 11.4 done — network QA: %d of %d checks pass. ",
                    "Week-11 STEPs complete."),
             sum(net_qa$pass), nrow(net_qa)))

# =============================================================================
# WEEK 12 — road pinch points (Decision 20)
# =============================================================================
# Functions: R/00_functions_pinch.R. Every Decision-20 value is read from
# R/00_config.R (PINCH_*). The Week-12 STEPs use `lcp_base`, `resqa_disk`,
# `pairs` and `res_net` from the Week-10 STEPs of this run.
source(here("R", "00_functions_pinch.R"))

# ---- Guard: settings --------------------------------------------------------
pinch_params <- c("PINCH_ROAD_CLASSES", "PINCH_ROAD_TOUCHES",
                  "PINCH_ROAD_CLASS_ORDER", "PINCH_PATH_LINK_ROLES",
                  "PINCH_RULE_LINK_ROLES", "PINCH_LIT_FLAG_PAIRS",
                  "PINCH_CROSSING_RULE", "PINCH_RESERVE_CELL_RULE",
                  "PINCH_SITE_MERGE_KM", "PINCH_RULE", "PINCH_SHARED_MIN_EDGES",
                  "PINCH_COMPARE_VARIANTS", "PINCH_COMPARE_D_KM",
                  "PINCH_COMPARE_D_DESCR_KM", "PINCH_COMPARE_ROBUST_MIN_OVERLAP",
                  "PINCH_PUBLISH_GRID_M", "PINCH_FIG_NUMBER", "PINCH_FIG_SLUG",
                  "PINCH_FIG_SIZE_IN", "PINCH_FIG_DPI", "PINCH_FIG_KEY_POS")
missing_pinch <- pinch_params[!vapply(pinch_params, exists, logical(1))]
if (length(missing_pinch) > 0) {
  stop("Decision-20 setting(s) missing from R/00_config.R: ",
       paste(missing_pinch, collapse = ", "), call. = FALSE)
}
# The functions build one rule set only (Decision 20 points 3 and 5). A
# different value in the config needs a new Decision and new code.
if (!identical(PINCH_CROSSING_RULE, "cell_run") ||
    !identical(PINCH_RESERVE_CELL_RULE, "count_and_flag") ||
    !identical(PINCH_RULE, "bridge_or_shared")) {
  stop("R/00_functions_pinch.R builds only PINCH_CROSSING_RULE = 'cell_run', ",
       "PINCH_RESERVE_CELL_RULE = 'count_and_flag', PINCH_RULE = ",
       "'bridge_or_shared' (Decision 20). The config has: ",
       PINCH_CROSSING_RULE, ", ", PINCH_RESERVE_CELL_RULE, ", ", PINCH_RULE,
       ".", call. = FALSE)
}
# Decision 20 point 1: the road cells are the cells that the engine saw, so
# the classes and the rasterise rule must be the Decision-15 ones. The class
# order must hold each barrier class once.
if (!identical(PINCH_ROAD_CLASSES, ROAD_BARRIER_CLASSES) ||
    !identical(PINCH_ROAD_TOUCHES, ROAD_BARRIER_TOUCHES)) {
  stop("PINCH_ROAD_CLASSES / PINCH_ROAD_TOUCHES are not the Decision-15 ",
       "settings (ROAD_BARRIER_CLASSES / ROAD_BARRIER_TOUCHES).", call. = FALSE)
}
if (anyDuplicated(PINCH_ROAD_CLASS_ORDER) ||
    !setequal(PINCH_ROAD_CLASS_ORDER, PINCH_ROAD_CLASSES)) {
  stop("PINCH_ROAD_CLASS_ORDER must hold each class of PINCH_ROAD_CLASSES ",
       "once.", call. = FALSE)
}
# Decision 20 point 7: the publish grid is the analysis grid aggregated by a
# whole factor, and it is not finer than the publish floor.
if (PINCH_PUBLISH_GRID_M %% GRID_CELL_M != 0 ||
    PINCH_PUBLISH_GRID_M < PUBLISH_FLOOR_M) {
  stop("PINCH_PUBLISH_GRID_M (", PINCH_PUBLISH_GRID_M, ") must be a whole ",
       "multiple of GRID_CELL_M (", GRID_CELL_M, ") and at least ",
       "PUBLISH_FLOOR_M (", PUBLISH_FLOOR_M, ").", call. = FALSE)
}

# ---- Guard: the lit_flag links resolve (Decision 20 point 2, k1) ---------------
# Each entry of PINCH_LIT_FLAG_PAIRS must be a pair of STEP 10.1, with the
# stated names. A stop here means that the config list or the pair table
# changed.
pinch_lit <- pinch_lit_flag_pairs(PINCH_LIT_FLAG_PAIRS, pairs)
cat("links with lit_flag (no literature support, or a described barrier):\n")
print(pinch_lit, row.names = FALSE)

# =============================================================================
# STEP 12.1 — barrier-road cells with their class (task 12.2; Decision 20
#             point 1)
# =============================================================================
# 1. Roads: the Decision-15 barrier classes; a `_link` ramp is in its parent
#    class (the rule of STEP 9.6).
# 2. One rasterise call per class onto the surface grid, with the arguments of
#    STEP 9.6 (field = 1, background = 0, touches). The cells of all classes
#    together are the cells of the one STEP-9.6 call. Each cell keeps the rank
#    of the highest class that touches it (1 = the first class of
#    PINCH_ROAD_CLASS_ORDER). Mask: the footprint (the non-NA cells of the
#    baseline surface).
# 3. Guard, on the raster of this run or on the file from disk: the grid, the
#    class order in the layer name, the values, the footprint, and the cell
#    count against n_road_cells of tbl_11_resistance_qa.csv. Any failure
#    stops the script.
# The road cells come from geometry: the same on all four surfaces. STEP 9.6
# does not run when RUN_RESISTANCE is FALSE, so this STEP has its own road
# read. No crossing is computed here (STEP 12.2).
rule("STEP 12.1 — barrier-road cells (Decision 20 point 1)")
roadcells_file <- "cov_roadbarrier_class_1km_7755.tif"
roadcells_out  <- file.path(DIR_INTERIM, roadcells_file)

if (isTRUE(RUN_ROAD_CELLS)) {
  if (!file.exists(roads_in)) {
    stop("Missing road layer: ", roads_in, call. = FALSE)
  }
  t_r <- Sys.time()
  roads_pinch <- read_vec(roads_in)
  if (!"highway" %in% names(roads_pinch)) {
    stop("Road layer has no 'highway' field: ", roads_in, call. = FALSE)
  }
  n_roads_all <- nrow(roads_pinch)
  roads_pinch$road_class <- sub("_link$", "", roads_pinch$highway)  # ramp -> parent
  roads_pinch <- roads_pinch[roads_pinch$road_class %in% PINCH_ROAD_CLASSES, ]
  if (nrow(roads_pinch) == 0) {
    stop("No road features in PINCH_ROAD_CLASSES.", call. = FALSE)
  }
  pinch_feat <- as.data.frame(table(factor(roads_pinch$road_class,
                                           levels = PINCH_ROAD_CLASS_ORDER)))
  names(pinch_feat) <- c("road_class", "n_features")
  cat(sprintf("road layer: %s features | barrier classes: %s\n",
              format(n_roads_all, big.mark = ","),
              format(nrow(roads_pinch), big.mark = ",")))
  cat("barrier road features (links merged into parent class):\n")
  print(pinch_feat, row.names = FALSE)

  road_class_r <- pinch_road_class_raster(roads_pinch, lcp_base,
                                          class_field = "road_class",
                                          class_order = PINCH_ROAD_CLASS_ORDER,
                                          touches = PINCH_ROAD_TOUCHES)
  cat(sprintf("read + rasterise: %.0f s\n",
              as.numeric(difftime(Sys.time(), t_r, units = "secs"))))
  rm(roads_pinch); invisible(gc())
} else {
  if (!file.exists(roadcells_out)) {
    stop("Missing barrier-road raster: ", roadcells_out,
         "\nSet RUN_ROAD_CELLS <- TRUE to build it.", call. = FALSE)
  }
  road_class_r <- terra::rast(roadcells_out)
  cat("read from disk:", roadcells_out, "\n")
}

# ---- 12.1a Guard (stop on any failure; nothing is written before it) ---------
road_chk <- pinch_check_road_cells(road_class_r, lcp_base,
                                   PINCH_ROAD_CLASS_ORDER,
                                   n_expected = resqa_disk$n_road_cells)
for (i in seq_len(nrow(road_chk))) {
  cat(sprintf("  %-4s %s (%s)\n", if (road_chk$pass[i]) "ok" else "FAIL",
              road_chk$check[i], road_chk$value[i]))
}
if (!all(road_chk$pass)) {
  stop("Barrier-road cell check(s) failed: ",
       paste(road_chk$check[!road_chk$pass], collapse = "; "),
       if (!isTRUE(RUN_ROAD_CELLS)) ". Re-run with RUN_ROAD_CELLS <- TRUE."
       else ". The road cells are not the cells of the Week-9 surfaces.",
       call. = FALSE)
}

# ---- 12.1b Cells per class (report) --------------------------------------------
road_class_n <- pinch_road_cell_counts(road_class_r, PINCH_ROAD_CLASS_ORDER)
road_class_n$pct_of_road_cells <- round(100 * road_class_n$n_cells /
                                          sum(road_class_n$n_cells), 1)
cat("barrier-road cells by road_class_top (the highest class in the cell):\n")
print(road_class_n, row.names = FALSE)
n_foot_12 <- sum(!is.na(terra::values(lcp_base, mat = FALSE)))
cat(sprintf("barrier-road cells in the footprint: %s (%.1f%% of %s cells)\n",
            format(sum(road_class_n$n_cells), big.mark = ","),
            100 * sum(road_class_n$n_cells) / n_foot_12,
            format(n_foot_12, big.mark = ",")))

# ---- 12.1c Output ----------------------------------------------------------------
if (isTRUE(RUN_ROAD_CELLS)) {
  write_processed_rast(road_class_r, roadcells_file, dir = DIR_INTERIM,
                       datatype = "INT1U")
  # The file must give the same result in the guard as the raster in memory.
  road_chk_disk <- pinch_check_road_cells(terra::rast(roadcells_out), lcp_base,
                                          PINCH_ROAD_CLASS_ORDER,
                                          n_expected = resqa_disk$n_road_cells)
  if (!all(road_chk_disk$pass)) {
    stop("The barrier-road raster on disk fails the guard: ",
         paste(road_chk_disk$check[!road_chk_disk$pass], collapse = "; "),
         call. = FALSE)
  }
  cat("the file on disk passes the same guard\n")
}

# For the crossing STEPs: the class rank of each cell of the grid (NA = not a
# barrier-road cell).
road_rank_v <- as.integer(terra::values(road_class_r, mat = FALSE))
rule(sprintf(paste0("STEP 12.1 done — %s barrier-road cells, the count of the ",
                    "Week-9 surfaces. Next: STEP 12.2 crossings (task 12.3)."),
             format(sum(!is.na(road_rank_v)), big.mark = ",")))

# =============================================================================
# STEP 12.2 — road crossings of the baseline paths (task 12.3; Decision 20
#             points 2, 3 and 7)
# =============================================================================
# 1. Links: every baseline in-network pair with a path — link_role in
#    PINCH_PATH_LINK_ROLES (edge, parallel). Their path cells come from
#    `paths_base` (STEP 10.2 of this run; the layer on disk has no cell list).
# 2. Cell list of a path: the path cells in order, with the two middle cells
#    of each knight step (crossed-cells rule, Decision 17 point 3). Check: the
#    step cost from the cell list must be the cost of the path on the layer.
# 3. Crossing: one unbroken run of barrier-road cells in the cell list. Every
#    road cell counts, also a cell in a reserve footprint (the reserves are
#    listed). No cell is excluded.
# 4. Position: the middle cell of the run (for an even run, the cell nearer
#    the start). The table gives only its cell of the PINCH_PUBLISH_GRID_M
#    grid, with the state and the district. The 1 km cells go to a gitignored
#    layer under data/processed.
# No site and no pinch point is made here (STEP 12.3).
rule(paste0("STEP 12.2 — road crossings, baseline (Decision 20) -> ",
            "tbl_14_road_crossings.csv"))
PINCH_BASE_SURFACE <- NET_BASE_SURFACE          # "baseline"
crossings_gpkg <- file.path(DIR_PROCESSED, "lcp_road_crossings_7755.gpkg")
states_in      <- file.path(DIR_PROCESSED, "boundary_states_7755.gpkg")
# The district layer of scripts/01 Block 8 (DataMeet, Census 2011).
districts_in   <- file.path(DIR_RAW, "administrative",
                            "boundary_districts_datameet2011_7755.gpkg")
ADMIN_STATE_FIELD         <- "name"        # Natural Earth admin-1 name
ADMIN_DISTRICT_FIELD      <- "DISTRICT"    # DataMeet 2011 district name
ADMIN_DISTRICT_CODE_FIELD <- "censuscode"  # 2011 census district code (the
                                           # names are not unique)
admin_in <- c(states_in, districts_in)
if (any(!file.exists(admin_in))) {
  stop("Missing admin layer(s) for the crossing positions:\n  ",
       paste(admin_in[!file.exists(admin_in)], collapse = "\n  "),
       call. = FALSE)
}

# ---- 12.2a Self-test (hand-made case; stop on any failure) ----------------------
pinch_st <- pinch_selftest()
cat(sprintf("self-test on the hand-made case: %d of %d cases pass\n",
            sum(pinch_st$pass), nrow(pinch_st)))
if (!all(pinch_st$pass)) {
  print(pinch_st[!pinch_st$pass, ], row.names = FALSE, right = FALSE)
  stop("Pinch-point self-test failed — the crossing functions are wrong. ",
       "Nothing further runs.", call. = FALSE)
}

# ---- 12.2b Crossings ---------------------------------------------------------------
if (!"cells" %in% names(paths_base) ||
    !identical(sort(paths_base$pair_id), sort(pairs$pair_id))) {
  stop("`paths_base` (STEP 10.2) does not hold the path cells of the pairs of ",
       "this run.", call. = FALSE)
}
t_x <- Sys.time()
lcp_vals <- terra::values(lcp_base, mat = FALSE)
cross_base <- pinch_crossings(
  paths = paths_base, links = net_links, link_roles = PINCH_PATH_LINK_ROLES,
  road_rank_v = road_rank_v, class_order = PINCH_ROAD_CLASS_ORDER,
  vals = lcp_vals, nc = terra::ncol(lcp_base),
  res_km = terra::xres(lcp_base) / 1000, reserve_cells = res_cells,
  unit_id = res_net$unit_id, surface = PINCH_BASE_SURFACE)
cx  <- cross_base$crossings
cxc <- cross_base$cells
cxp <- cross_base$paths
if (is.null(cx)) {
  stop("No road crossing on any baseline path — check the road cells and the ",
       "paths.", call. = FALSE)
}
cat(sprintf(paste0("paths with crossings computed: %d (%s) | cell lists: %s ",
                   "cells, %s from knight steps | %.0f s\n"),
            nrow(cxp),
            paste(sprintf("%s %d", names(table(cxp$link_role)),
                          as.integer(table(cxp$link_role))), collapse = ", "),
            format(sum(cxp$n_list_cells), big.mark = ","),
            format(sum(cxp$n_list_cells - cxp$n_vertices), big.mark = ","),
            as.numeric(difftime(Sys.time(), t_x, units = "secs"))))

# ---- 12.2c Checks (stop on any failure) ---------------------------------------------
n_links_x <- sum(net_links$link_role %in% PINCH_PATH_LINK_ROLES)
x_chk <- c(
  "each link in the roles has its crossings computed" =
    nrow(cxp) == n_links_x && setequal(cxp$pair_id,
      net_links$pair_id[net_links$link_role %in% PINCH_PATH_LINK_ROLES]),
  "cost from the cell list = cost of the path (every path)" = all(cxp$cost_ok),
  "each crossing cell is a barrier-road cell" =
    all(!is.na(road_rank_v[cxc$cell])),
  "each crossing cell is a footprint cell" = all(!is.na(lcp_vals[cxc$cell])),
  "crossing cells add up to the road cells on the paths" =
    nrow(cxc) == sum(cx$n_cells) && nrow(cxc) == sum(cxp$n_road_cells),
  "crossings add up per path" =
    nrow(cx) == sum(cxp$n_crossings) && !anyDuplicated(cx$crossing_id),
  "the middle cell is a cell of its crossing" =
    all(mapply(function(m, cc) m %in% cc, cx$mid_cell, cx$cells))
)
for (i in seq_along(x_chk)) {
  cat(sprintf("  %-4s %s\n", if (isTRUE(x_chk[[i]])) "ok" else "FAIL",
              names(x_chk)[i]))
}
if (!all(x_chk)) {
  if (!all(cxp$cost_ok)) {
    print(cxp[!cxp$cost_ok, c("pair_id", "cost_rkm", "cost_from_list")],
          row.names = FALSE, digits = 12)
  }
  stop("Crossing check(s) failed: ", paste(names(x_chk)[!x_chk],
                                           collapse = "; "), call. = FALSE)
}

# ---- 12.2d Link fields and published position -----------------------------------------
k_l <- match(cx$pair_id, net_links$pair_id)
grid_prefix <- sprintf("grid%d", as.integer(PINCH_PUBLISH_GRID_M %/% 1000L))
g_x <- pinch_grid_cell(cx$mid_cell, lcp_base, PINCH_PUBLISH_GRID_M)
names(g_x) <- sub("^grid", grid_prefix, names(g_x))
states_sf    <- read_vec(states_in)
districts_sf <- read_vec(districts_in)
cat("admin layers:", states_in, "|", districts_in, "\n")
a_state <- pinch_admin_lookup(cx$mid_cell, lcp_base, states_sf,
                              ADMIN_STATE_FIELD)
a_dist  <- pinch_admin_lookup(cx$mid_cell, lcp_base, districts_sf,
                              ADMIN_DISTRICT_FIELD)
a_code  <- pinch_admin_lookup(cx$mid_cell, lcp_base, districts_sf,
                              ADMIN_DISTRICT_CODE_FIELD)
cat(sprintf(paste0("state from the nearest polygon (centre in no polygon): %d",
                   " | district from the nearest polygon: %d (of %d crossings)\n"),
            sum(a_state$nearest), sum(a_dist$nearest), nrow(cx)))

cx$from_unit_id <- net_links$from_unit_id[k_l]
cx$from_name    <- net_links$from_name[k_l]
cx$to_unit_id   <- net_links$to_unit_id[k_l]
cx$to_name      <- net_links$to_name[k_l]
cx$from_node_id <- net_links$from_node_id[k_l]
cx$to_node_id   <- net_links$to_node_id[k_l]
cx$link_role    <- net_links$link_role[k_l]
cx$is_bridge    <- net_links$is_bridge[k_l]      # NA for a parallel link
cx$lit_flag     <- cx$pair_id %in% pinch_lit$pair_id
cx <- cbind(cx, g_x)
cx$state         <- a_state$value
cx$district      <- a_dist$value
cx$district_code <- a_code$value
cross_base$crossings <- cx                       # for STEP 12.3 (with `cells`)

# ---- 12.2e Report -------------------------------------------------------------------
cat(sprintf(paste0("crossings: %s on %d paths | road cells on the paths: %s ",
                   "(%.1f%% of the %s list cells)\n"),
            format(nrow(cx), big.mark = ","), sum(cxp$n_crossings > 0),
            format(nrow(cxc), big.mark = ","),
            100 * nrow(cxc) / sum(cxp$n_list_cells),
            format(sum(cxp$n_list_cells), big.mark = ",")))
cat(sprintf(paste0("cells per crossing: median %g, mean %.2f, max %d | ",
                   "crossings of 1 cell: %d | of 5 cells or more: %d\n"),
            stats::median(cx$n_cells), mean(cx$n_cells), max(cx$n_cells),
            sum(cx$n_cells == 1L), sum(cx$n_cells >= 5L)))
cat("crossings by link_role:\n")
print(table(link_role = cx$link_role))
cat("crossings by road_class_top (the highest class in the run):\n")
print(table(road_class_top = factor(cx$road_class_top,
                                    levels = PINCH_ROAD_CLASS_ORDER)))
cat(sprintf(paste0("crossings with a cell in a reserve footprint: %d | with ",
                   "a middle cell of a knight step: %d | on a bridge edge: %d",
                   " | on a link with lit_flag: %d\n"),
            sum(cx$in_reserve_unit_ids != ""),
            length(unique(cxc$crossing_id[!cxc$is_vertex])),
            sum(cx$is_bridge %in% TRUE), sum(cx$lit_flag)))
per_link <- merge(
  net_links[net_links$link_role %in% PINCH_PATH_LINK_ROLES,
            c("pair_id", "from_name", "to_name", "link_role", "is_bridge",
              "path_km")],
  cxp[, c("pair_id", "n_crossings", "n_road_cells")], by = "pair_id")
per_link$lit_flag <- per_link$pair_id %in% pinch_lit$pair_id
per_link$crossings_per_100km <- round(100 * per_link$n_crossings /
                                        per_link$path_km, 1)
cat(sprintf(paste0("crossings per path: median %g, range %d-%d | per 100 km ",
                   "of path: median %.1f\n"),
            stats::median(per_link$n_crossings), min(per_link$n_crossings),
            max(per_link$n_crossings),
            stats::median(per_link$crossings_per_100km)))
if (any(per_link$n_crossings == 0L)) {
  cat("paths with no road crossing:\n")
  print(per_link[per_link$n_crossings == 0L,
                 c("pair_id", "from_name", "to_name", "link_role", "path_km")],
        row.names = FALSE, digits = 4)
}
cat("the bridge edges (Decision 19) and their crossings:\n")
print(per_link[per_link$is_bridge %in% TRUE,
               c("pair_id", "from_name", "to_name", "path_km", "n_crossings",
                 "n_road_cells", "crossings_per_100km", "lit_flag")],
      row.names = FALSE, digits = 4)
cat("the longest runs (a path that goes along a road):\n")
print(utils::head(cx[order(-cx$n_cells),
                     c("crossing_id", "from_name", "to_name", "n_cells",
                       "road_class_top", "state", "district")], 5),
      row.names = FALSE)

# ---- 12.2f Outputs --------------------------------------------------------------------
# (i) The 1 km cells: one point per crossing cell. Gitignored (data/processed);
# never a published layer (sensitive-data policy §3; Decision 20 point 7).
k_c <- match(cxc$crossing_id, cx$crossing_id)
cxc$is_mid <- cxc$cell == cx$mid_cell[k_c] &
  cxc$seq == (cx$n_cells[k_c] - 1L) %/% 2L + 1L
cxc_sf <- sf::st_as_sf(
  cbind(cxc, as.data.frame(terra::xyFromCell(lcp_base, cxc$cell))),
  coords = c("x", "y"), crs = sf::st_crs(res_net))
pinch_write_layer(cxc_sf, crossings_gpkg, PINCH_BASE_SURFACE)

# (ii) The table: one row per crossing; the position at the publish grid only.
x_cols <- c("crossing_id", "pair_id", "surface", "from_unit_id", "from_name",
            "to_unit_id", "to_name", "from_node_id", "to_node_id", "link_role",
            "is_bridge", "lit_flag", "run_no", "n_cells", "road_class_top",
            "in_reserve_unit_ids", names(g_x), "state", "district",
            "district_code")
crossings_out <- cx[order(cx$pair_id, cx$run_no), x_cols]
rownames(crossings_out) <- NULL
# Guard (Decision 20 point 7): no position finer than the publish grid in a
# committed table. The columns are the list above.
x_pub <- pinch_check_publish_table(crossings_out, lcp_base,
                                   PINCH_PUBLISH_GRID_M, grid_prefix)
if (!identical(names(crossings_out), x_cols) || !all(x_pub$pass)) {
  print(x_pub[!x_pub$pass, ], row.names = FALSE, right = FALSE)
  stop("tbl_14_road_crossings: a column or a position is finer than the ",
       "publish grid (", PINCH_PUBLISH_GRID_M, " m). The table is not written.",
       call. = FALSE)
}
write_table(crossings_out, 14, "road_crossings")
rule(sprintf(paste0("STEP 12.2 done — %s crossings on %d baseline paths. ",
                    "Next: STEP 12.3 sites and pinch points (task 12.4)."),
             format(nrow(crossings_out), big.mark = ","), nrow(cxp)))

# =============================================================================
# STEP 12.3 — sites and pinch points, baseline (task 12.4; Decision 20
#             points 4, 5 and 7)
# =============================================================================
# 1. Site: two crossings are joined if a cell centre of one is at most
#    PINCH_SITE_MERGE_KM from a cell centre of the other (one link or
#    different links). A site is a connected set of joined crossings. All
#    crossings of STEP 12.2 enter (edge and parallel links).
# 2. Pinch point: on_bridge = a bridge edge (Decision 19) uses the site;
#    shared = PINCH_SHARED_MIN_EDGES or more edges use it; pinch_point =
#    on_bridge OR shared; pinch_tier 1 = both, 2 = on_bridge only, 3 = shared
#    only. Only `edge` links count. The road class, the cost and the number
#    of crossings are columns; they are not in the rule and give no order.
# 3. Position: the mean of the distinct cell centres of the site. The tables
#    give only its cell of the publish grid, with state and district.
# "Pinch point" here is NOT the pinch point of circuit-theory mapping (a
# narrow part of a corridor with high current flow): a least-cost path has no
# width (Decision 20 point 5).
rule(paste0("STEP 12.3 — sites and pinch points, baseline (Decision 20) -> ",
            "tbl_14_pinch_points.csv, tbl_14_pinch_link_summary.csv"))

# ---- 12.3a Self-test (hand-made case; stop on any failure) ----------------------
pinch_st2 <- pinch_selftest_sites()
cat(sprintf("self-test of the sites and the rule: %d of %d cases pass\n",
            sum(pinch_st2$pass), nrow(pinch_st2)))
if (!all(pinch_st2$pass)) {
  print(pinch_st2[!pinch_st2$pass, ], row.names = FALSE, right = FALSE)
  stop("Site self-test failed — the site or rule functions are wrong. ",
       "Nothing further runs.", call. = FALSE)
}

# ---- 12.3b Sites and the rule -------------------------------------------------------
nc_12  <- terra::ncol(lcp_base)
res_12 <- terra::xres(lcp_base) / 1000
cx$site_id <- pinch_build_sites(cx, nc_12, res_12, PINCH_SITE_MERGE_KM)
sites_base <- pinch_site_table(cx, lcp_base, PINCH_ROAD_CLASS_ORDER,
                               PINCH_RULE_LINK_ROLES, PINCH_SHARED_MIN_EDGES,
                               PINCH_BASE_SURFACE)
site_gap_km <- pinch_min_site_gap_km(cx, cx$site_id, nc_12, res_12)

# Position at the publish grid, state and district (of the mean point).
g_s <- pinch_grid_cell_xy(sites_base$mean_x, sites_base$mean_y, lcp_base,
                          PINCH_PUBLISH_GRID_M)
names(g_s) <- sub("^grid", grid_prefix, names(g_s))
s_xy    <- cbind(sites_base$mean_x, sites_base$mean_y)
s_state <- pinch_admin_lookup_xy(s_xy, states_sf, ADMIN_STATE_FIELD)
s_dist  <- pinch_admin_lookup_xy(s_xy, districts_sf, ADMIN_DISTRICT_FIELD)
s_code  <- pinch_admin_lookup_xy(s_xy, districts_sf, ADMIN_DISTRICT_CODE_FIELD)
sites_base <- cbind(sites_base, g_s)
sites_base$state         <- s_state$value
sites_base$district      <- s_dist$value
sites_base$district_code <- s_code$value
link_sum <- pinch_link_summary(cx, sites_base, cxp)
cross_base$crossings <- cx                 # now with site_id (for STEP 12.4)

# ---- 12.3c Checks (stop on any failure) ---------------------------------------------
rule_2 <- sites_base$n_bridges >= 1L | sites_base$n_edges >= PINCH_SHARED_MIN_EDGES
tier_2 <- ifelse(!rule_2, NA_integer_,
                 3L - 2L * (sites_base$n_bridges >= 1L &
                              sites_base$n_edges >= PINCH_SHARED_MIN_EDGES) -
                   1L * (sites_base$n_bridges >= 1L &
                           sites_base$n_edges < PINCH_SHARED_MIN_EDGES))
s_chk <- c(
  "each crossing is in one site" =
    !anyNA(cx$site_id) && sum(sites_base$n_crossings) == nrow(cx),
  "site ids are 1 to n, in the order of the lowest cell" =
    identical(sites_base$site_id, seq_len(nrow(sites_base))) &&
    !is.unsorted(tapply(vapply(cx$cells, min, numeric(1)), cx$site_id, min)),
  "two sites are more than the merge distance apart" =
    site_gap_km > PINCH_SITE_MERGE_KM,
  "pinch_point = on_bridge OR shared (rule written a second way)" =
    identical(sites_base$pinch_point, rule_2) &&
    identical(sites_base$pinch_tier, tier_2),
  "a bridge edge counts as an edge; edges are links" =
    all(sites_base$n_bridges <= sites_base$n_edges) &&
    all(sites_base$n_edges <= sites_base$n_links),
  "site cells add up to the distinct crossing cells" =
    sum(sites_base$n_cells) ==
    nrow(unique(data.frame(s = rep(cx$site_id, lengths(cx$cells)),
                           c = unlist(cx$cells)))),
  "each link has a site for each of its crossings" =
    all(link_sum$n_sites <= link_sum$n_crossings) &&
    all((link_sum$n_sites > 0) == (link_sum$n_crossings > 0)) &&
    all(link_sum$n_pinch_points == link_sum$n_pinch_tier1 +
          link_sum$n_pinch_tier2 + link_sum$n_pinch_tier3),
  "each site on a bridge edge is a pinch point" =
    all(sites_base$pinch_point[sites_base$site_id %in%
                                 cx$site_id[cx$is_bridge %in% TRUE]])
)
for (i in seq_along(s_chk)) {
  cat(sprintf("  %-4s %s\n", if (isTRUE(s_chk[[i]])) "ok" else "FAIL",
              names(s_chk)[i]))
}
if (!all(s_chk)) {
  stop("Site check(s) failed: ", paste(names(s_chk)[!s_chk], collapse = "; "),
       call. = FALSE)
}

# ---- 12.3d Report -------------------------------------------------------------------
pp <- sites_base[sites_base$pinch_point, ]
cat(sprintf(paste0("sites: %d from %d crossings (merge distance %g km) | ",
                   "crossings per site: median %g, max %d | sites of one ",
                   "crossing: %d | shortest gap between two sites: %.2f km\n"),
            nrow(sites_base), nrow(cx), PINCH_SITE_MERGE_KM,
            stats::median(sites_base$n_crossings), max(sites_base$n_crossings),
            sum(sites_base$n_crossings == 1L), site_gap_km))
cat(sprintf(paste0("span_km: median %.1f, max %.1f | sites with a span above ",
                   "%g km (a chain): %d\n"),
            stats::median(sites_base$span_km), max(sites_base$span_km),
            2 * PINCH_SITE_MERGE_KM,
            sum(sites_base$span_km > 2 * PINCH_SITE_MERGE_KM)))
cat(sprintf(paste0("pinch points: %d of %d sites (%.1f%%) | on_bridge %d | ",
                   "shared %d | tier 1 (both) %d, tier 2 (on_bridge only) %d, ",
                   "tier 3 (shared only) %d\n"),
            nrow(pp), nrow(sites_base), 100 * nrow(pp) / nrow(sites_base),
            sum(sites_base$on_bridge), sum(sites_base$shared),
            sum(pp$pinch_tier == 1L), sum(pp$pinch_tier == 2L),
            sum(pp$pinch_tier == 3L)))
cat(sprintf(paste0("pinch points with lit_flag (each edge has the flag): %d ",
                   "| with lit_flag_any: %d | with a cell in a reserve ",
                   "footprint: %d | sites with parallel links only: %d\n"),
            sum(pp$lit_flag), sum(pp$lit_flag_any),
            sum(pp$in_reserve_unit_ids != ""), sum(sites_base$n_edges == 0L)))
cat("pinch points by pinch_tier and road_class_top (a description, not a rule):\n")
print(table(pinch_tier = pp$pinch_tier,
            road_class_top = factor(pp$road_class_top,
                                    levels = PINCH_ROAD_CLASS_ORDER)))
show_s <- c("site_id", "pinch_tier", "n_edges", "n_bridges", "n_crossings",
            "span_km", "road_class_top", "lit_flag", "state", "district",
            "links")
if (any(pp$pinch_tier == 1L)) {
  cat("tier-1 pinch points (on a bridge edge AND shared):\n")
  print(pp[pp$pinch_tier == 1L, show_s], row.names = FALSE, digits = 3,
        right = FALSE)
}
cat("the sites with the most edges:\n")
print(utils::head(sites_base[order(-sites_base$n_edges, sites_base$site_id),
                             show_s], 8), row.names = FALSE, digits = 3,
      right = FALSE)
cat("the sites with the longest span:\n")
print(utils::head(sites_base[order(-sites_base$span_km), show_s], 5),
      row.names = FALSE, digits = 3, right = FALSE)
br <- merge(per_link[per_link$is_bridge %in% TRUE,
                     c("pair_id", "from_name", "to_name", "lit_flag")],
            link_sum[, c("pair_id", "n_crossings", "n_sites", "n_pinch_points",
                         "n_pinch_tier1", "n_pinch_tier2")], by = "pair_id")
cat("the bridge edges: crossings, sites and pinch points:\n")
print(br, row.names = FALSE)
cat("pinch points by state:\n")
print(sort(table(pp$state), decreasing = TRUE))

# ---- 12.3e Outputs --------------------------------------------------------------------
# (i) Sites: one row per site (pinch points and other sites), position at the
# publish grid only. Sorted by tier, then site_id (Decision 20 point 5).
s_cols <- c("site_id", "surface", "pinch_point", "pinch_tier", "on_bridge",
            "shared", "n_crossings", "n_links", "n_edges", "n_bridges",
            "n_cells", "span_km", "road_class_top", "in_reserve_unit_ids",
            "lit_flag", "lit_flag_any", "pair_ids", "edge_pair_ids",
            "bridge_pair_ids", "links", names(g_s), "state", "district",
            "district_code")
sites_out <- sites_base[order(is.na(sites_base$pinch_tier),
                              sites_base$pinch_tier, sites_base$site_id),
                        s_cols]
sites_out$span_km <- round(sites_out$span_km, 3)
rownames(sites_out) <- NULL

# (ii) Links: one row per link with crossings computed.
k_ls <- match(link_sum$pair_id, net_links$pair_id)
links_sum_out <- cbind(
  net_links[k_ls, c("pair_id", "surface", "from_unit_id", "from_name",
                    "to_unit_id", "to_name", "from_node_id", "to_node_id",
                    "link_role", "is_bridge")],
  lit_flag = link_sum$pair_id %in% pinch_lit$pair_id,
  net_links[k_ls, c(NET_EDGE_WEIGHT_FIELD, "path_km")],
  link_sum[, setdiff(names(link_sum), "pair_id")])
rownames(links_sum_out) <- NULL

# (iii) The crossing table again, with site_id (as STEP 11.3 does for the
# metrics table).
x_cols2 <- append(x_cols, "site_id", after = match("crossing_id", x_cols))
crossings_out <- cx[order(cx$pair_id, cx$run_no), x_cols2]
rownames(crossings_out) <- NULL

# Guard (Decision 20 point 7): no position finer than the publish grid in a
# committed table. Any failure stops the script before a table is written.
pub_chk <- rbind(
  cbind(table = "tbl_14_pinch_points",
        pinch_check_publish_table(sites_out, lcp_base, PINCH_PUBLISH_GRID_M,
                                  grid_prefix)),
  cbind(table = "tbl_14_road_crossings",
        pinch_check_publish_table(crossings_out, lcp_base,
                                  PINCH_PUBLISH_GRID_M, grid_prefix)))
if (!all(pub_chk$pass) || any(c(names(g_s), "state", "district") %in%
                              names(links_sum_out))) {
  print(pub_chk[!pub_chk$pass, ], row.names = FALSE, right = FALSE)
  stop("A Week-12 table holds a position finer than the publish grid (",
       PINCH_PUBLISH_GRID_M, " m). No table is written.", call. = FALSE)
}
cat(sprintf("publish guard: %d of %d checks pass (no position finer than %g km)\n",
            sum(pub_chk$pass), nrow(pub_chk), PINCH_PUBLISH_GRID_M / 1000))
write_table(sites_out, 14, "pinch_points")
write_table(links_sum_out, 14, "pinch_link_summary")
write_table(crossings_out, 14, "road_crossings")

# (iv) The 1 km layer again, with site_id (gitignored; never published).
cxc_sf$site_id <- cx$site_id[match(cxc_sf$crossing_id, cx$crossing_id)]
pinch_write_layer(cxc_sf, crossings_gpkg, PINCH_BASE_SURFACE)
rule(sprintf(paste0("STEP 12.3 done — %d sites, %d pinch points (tier 1: %d, ",
                    "tier 2: %d, tier 3: %d). Next: STEP 12.4 variants ",
                    "(task 12.5)."),
             nrow(sites_base), nrow(pp), sum(pp$pinch_tier == 1L),
             sum(pp$pinch_tier == 2L), sum(pp$pinch_tier == 3L)))

# =============================================================================
# STEP 12.4 — variants and the Decision-20 comparison (task 12.5; point 6)
# =============================================================================
# 1. For noghm, road15 and road50: the crossings, the sites and the pinch
#    points, by the rules and the functions of the baseline
#    (pinch_run_surface()). Each variant has its own paths (STEP 10.4), its
#    own links, edges and bridges (the Decision-19 graph of STEP 11.3). The
#    barrier-road cells are the same on every surface.
# 2. Each variant is compared with the baseline only. The label rule was
#    fixed in Decision 20 before any crossing: "robust" if site_overlap >=
#    PINCH_COMPARE_ROBUST_MIN_OVERLAP, where site_overlap = min(share of the
#    baseline pinch points with a variant pinch point within
#    PINCH_COMPARE_D_KM, share of the variant pinch points with a baseline
#    pinch point within that distance).
# 3. A choice tested by two variants (the road value) is robust only if both
#    are robust.
# 4. Each baseline site gets near_pinch_<variant> (a variant pinch point is
#    within the distance) and n_variants_near. No new label is made.
# outputs/tables gets the comparison table only (process choice,
# 2026-10-10); the variant crossing cells go to the gitignored 1 km file.
rule(paste0("STEP 12.4 — variants (", paste(PINCH_COMPARE_VARIANTS,
                                             collapse = ", "),
            ") -> tbl_14_pinch_variant_comparison.csv"))
if (!identical(sort(PINCH_COMPARE_VARIANTS), sort(NET_COMPARE_VARIANTS)) ||
    !all(PINCH_COMPARE_VARIANTS %in% names(paths_var)) ||
    !all(PINCH_COMPARE_VARIANTS %in% names(net_var_g))) {
  stop("PINCH_COMPARE_VARIANTS must be the variants of STEPs 10.4 and 11.3 (",
       paste(NET_COMPARE_VARIANTS, collapse = ", "), ").", call. = FALSE)
}

# ---- 12.4a Self-test of the comparison (stop on any failure) ---------------------
pinch_st3 <- pinch_selftest_compare()
cat(sprintf("self-test of the comparison: %d of %d cases pass\n",
            sum(pinch_st3$pass), nrow(pinch_st3)))
if (!all(pinch_st3$pass)) {
  print(pinch_st3[!pinch_st3$pass, ], row.names = FALSE, right = FALSE)
  stop("Comparison self-test failed. Nothing further runs.", call. = FALSE)
}

# ---- 12.4b The chain function on the baseline = STEPs 12.2 and 12.3 --------------
run_surface <- function(paths, links, edge_flags, r, surface) {
  pinch_run_surface(
    paths = paths, links = links, edge_flags = edge_flags,
    lit_pair_ids = pinch_lit$pair_id, link_roles = PINCH_PATH_LINK_ROLES,
    rule_link_roles = PINCH_RULE_LINK_ROLES, road_rank_v = road_rank_v,
    class_order = PINCH_ROAD_CLASS_ORDER, r = r, reserve_cells = res_cells,
    unit_id = res_net$unit_id, merge_km = PINCH_SITE_MERGE_KM,
    shared_min_edges = PINCH_SHARED_MIN_EDGES, surface = surface)
}
pinch_base <- run_surface(paths_base, net_links, net_flags, lcp_base,
                          PINCH_BASE_SURFACE)
same_cols <- c("site_id", "n_crossings", "n_links", "n_edges", "n_bridges",
               "n_cells", "span_km", "pinch_point", "pinch_tier", "lit_flag",
               "links")
if (!identical(pinch_base$crossings$crossing_id, cx$crossing_id) ||
    !identical(pinch_base$crossings$site_id, cx$site_id) ||
    !isTRUE(all.equal(pinch_base$sites[, same_cols], sites_base[, same_cols],
                      check.attributes = FALSE))) {
  stop("pinch_run_surface() on the baseline does not give the crossings and ",
       "sites of STEPs 12.2 and 12.3.", call. = FALSE)
}
cat(sprintf(paste0("the chain function on the baseline gives the result of ",
                   "STEPs 12.2-12.3: %d crossings, %d sites, %d pinch points\n"),
            nrow(pinch_base$crossings), nrow(pinch_base$sites),
            sum(pinch_base$sites$pinch_point)))

# ---- 12.4c Each variant -------------------------------------------------------------
pinch_var     <- list()
pinch_cmp     <- list()
pinch_var_chk <- list()                       # kept for the QA STEP
pinch_links   <- stats::setNames(list(net_links), PINCH_BASE_SURFACE)
pinch_flags   <- stats::setNames(list(net_flags), PINCH_BASE_SURFACE)
for (v in PINCH_COMPARE_VARIANTS) {
  t_v <- Sys.time()
  r_v <- terra::rast(resist_in[[v]])
  links_v <- net_build_links(net_var_paths[[v]], net_nodes,
                             NET_EDGE_WEIGHT_FIELD)
  flags_v <- net_edge_flags(net_var_g[[v]])
  if (!setequal(flags_v$pair_id,
                links_v$pair_id[links_v$link_role == "edge"]) ||
      !identical(sort(paths_var[[v]]$pair_id), sort(pairs$pair_id)) ||
      !"cells" %in% names(paths_var[[v]])) {
    stop("Variant '", v, "': the graph of STEP 11.3 and the paths of STEP ",
         "10.4 do not agree with its link table.", call. = FALSE)
  }
  pv <- run_surface(paths_var[[v]], links_v, flags_v, r_v, v)
  v_chk <- c(
    "cost from the cell list = cost of the path (every path)" =
      all(pv$paths$cost_ok),
    "each crossing cell is a barrier-road cell" =
      all(!is.na(road_rank_v[pv$cells$cell])),
    "crossings and cells add up per path" =
      nrow(pv$crossings) == sum(pv$paths$n_crossings) &&
      nrow(pv$cells) == sum(pv$paths$n_road_cells),
    "each crossing is in one site" =
      !anyNA(pv$crossings$site_id) &&
      sum(pv$sites$n_crossings) == nrow(pv$crossings),
    "two sites are more than the merge distance apart" =
      pv$site_gap_km > PINCH_SITE_MERGE_KM,
    "each site on a bridge edge is a pinch point" =
      all(pv$sites$pinch_point[pv$sites$site_id %in%
            pv$crossings$site_id[pv$crossings$is_bridge %in% TRUE]])
  )
  pinch_var_chk[[v]] <- v_chk
  if (!all(v_chk)) {
    stop("Variant '", v, "' — check(s) failed: ",
         paste(names(v_chk)[!v_chk], collapse = "; "), call. = FALSE)
  }
  cmp_v <- pinch_compare_variant(pinch_base, pv, nc_12, res_12,
                                 PINCH_COMPARE_D_KM, PINCH_COMPARE_D_DESCR_KM,
                                 PINCH_COMPARE_ROBUST_MIN_OVERLAP)
  pinch_var[[v]] <- pv
  pinch_cmp[[v]] <- cmp_v
  pinch_links[[v]] <- links_v
  pinch_flags[[v]] <- flags_v
  cat(sprintf(paste0("%-7s paths %d (bridges %d) | crossings %d | sites %d | ",
                     "pinch points %d (tier 1: %d, 2: %d, 3: %d) | checks %d ",
                     "of %d | share_base %.3f, share_variant %.3f, ",
                     "site_overlap %.3f | %s | %.0f s\n"),
              v, nrow(pv$paths), sum(flags_v$is_bridge), nrow(pv$crossings),
              nrow(pv$sites), cmp_v$row$n_pinch_points,
              cmp_v$row$n_pinch_tier1, cmp_v$row$n_pinch_tier2,
              cmp_v$row$n_pinch_tier3, sum(v_chk), length(v_chk),
              cmp_v$row$share_base, cmp_v$row$share_variant,
              cmp_v$row$site_overlap, cmp_v$row$label,
              as.numeric(difftime(Sys.time(), t_v, units = "secs"))))
  # The 1 km cells of the variant: gitignored; never published.
  v_sf <- sf::st_as_sf(
    cbind(pv$cells, as.data.frame(terra::xyFromCell(lcp_base, pv$cells$cell))),
    coords = c("x", "y"), crs = sf::st_crs(res_net))
  pinch_write_layer(v_sf, crossings_gpkg, v)
  rm(r_v, v_sf)
}

# ---- 12.4d Comparison table and labels (fixed in Decision 20 point 6) ------------
pinch_cmp_tbl <- do.call(rbind, lapply(PINCH_COMPARE_VARIANTS, function(v) {
  cbind(data.frame(variant = v, tests = unname(net_variant_tests[v]),
                   n_paths = nrow(pinch_var[[v]]$paths),
                   n_bridge_edges = sum(net_edge_flags(net_var_g[[v]])$is_bridge),
                   stringsAsFactors = FALSE),
        pinch_cmp[[v]]$row)
}))
pinch_choice_label <- tapply(pinch_cmp_tbl$label, pinch_cmp_tbl$tests,
                             function(z) if (all(z == "robust")) "robust"
                             else "sensitive")
pinch_cmp_tbl$choice_label <- as.vector(pinch_choice_label[pinch_cmp_tbl$tests])
rownames(pinch_cmp_tbl) <- NULL
cat(sprintf(paste0("baseline: %d crossings, %d sites, %d pinch points (tier ",
                   "1: %d, 2: %d, 3: %d)\n"),
            nrow(cx), nrow(sites_base), sum(sites_base$pinch_point),
            sum(sites_base$pinch_tier %in% 1L),
            sum(sites_base$pinch_tier %in% 2L),
            sum(sites_base$pinch_tier %in% 3L)))
print(pinch_cmp_tbl[, c("variant", "n_crossings", "n_sites", "n_pinch_points",
                        "share_base", "share_variant", "site_overlap",
                        paste0("site_overlap_", PINCH_COMPARE_D_DESCR_KM, "km"),
                        "all_sites_overlap", "n_base_tier12_not_near",
                        "label")], row.names = FALSE, digits = 3)
cat(sprintf("limit: site_overlap >= %.3f at %g km (judgement values, Decision 20)\n",
            PINCH_COMPARE_ROBUST_MIN_OVERLAP, PINCH_COMPARE_D_KM))
for (ch in names(pinch_choice_label)) {
  cat(sprintf("label — %s: %s (variants: %s)\n", ch, pinch_choice_label[[ch]],
              paste(pinch_cmp_tbl$variant[pinch_cmp_tbl$tests == ch],
                    collapse = ", ")))
}
for (v in PINCH_COMPARE_VARIANTS) {
  z <- pinch_cmp_tbl$base_tier12_not_near_by_link[pinch_cmp_tbl$variant == v]
  cat(sprintf("%-7s baseline tier-1 and tier-2 pinch points with no variant pinch point near, by link: %s\n",
              v, if (nzchar(z)) z else "none"))
}
write_table(pinch_cmp_tbl, 14, "pinch_variant_comparison")

# ---- 12.4e The variant result of each baseline site ---------------------------------
near_cols <- paste0("near_pinch_", PINCH_COMPARE_VARIANTS)
for (v in PINCH_COMPARE_VARIANTS) {
  sites_base[[paste0("near_pinch_", v)]] <- pinch_cmp[[v]]$near_base
}
sites_base$n_variants_near <- as.integer(rowSums(sites_base[, near_cols,
                                                             drop = FALSE]))
ppb <- sites_base[sites_base$pinch_point, ]
cat(sprintf(paste0("baseline pinch points near a variant pinch point on all ",
                   "%d variants: %d of %d | on none: %d\n"),
            length(near_cols), sum(ppb$n_variants_near == length(near_cols)),
            nrow(ppb), sum(ppb$n_variants_near == 0L)))
cat("baseline pinch points by pinch_tier and n_variants_near:\n")
print(table(pinch_tier = ppb$pinch_tier, n_variants_near = ppb$n_variants_near))
cat("tier-1 pinch points and their variant result:\n")
print(ppb[ppb$pinch_tier == 1L, c("site_id", "links", near_cols,
                                  "n_variants_near")], row.names = FALSE,
      right = FALSE)
s_cols2 <- c(s_cols, near_cols, "n_variants_near")
sites_out <- sites_base[order(is.na(sites_base$pinch_tier),
                              sites_base$pinch_tier, sites_base$site_id),
                        s_cols2]
sites_out$span_km <- round(sites_out$span_km, 3)
rownames(sites_out) <- NULL
pub_chk2 <- pinch_check_publish_table(sites_out, lcp_base, PINCH_PUBLISH_GRID_M,
                                      grid_prefix)
if (!all(pub_chk2$pass)) {
  stop("tbl_14_pinch_points: a position is finer than the publish grid. ",
       "The table is not written.", call. = FALSE)
}
write_table(sites_out, 14, "pinch_points")
rule(sprintf("STEP 12.4 done — labels: %s. Next: STEP 12.5 QA (task 12.6).",
             paste(sprintf("%s %s", sub(" \\(Decision.*$", "",
                                        names(pinch_choice_label)),
                           pinch_choice_label), collapse = "; ")))

# =============================================================================
# STEP 12.5 — pinch-point QA (task 12.6; Decision 20, "Consequences")
# =============================================================================
# The checks of the earlier Week-12 STEPs, collected, and the QA list of
# Decision 20 on each surface: the functions on the hand-made cases; each
# crossing cell is in the cell list of its path and is a barrier-road cell;
# each barrier-road cell of a cell list is in one crossing only; no crossing
# for a contiguous pair or a pair that is not in the network; each crossing
# is in one site only; two sites are more than the merge distance apart; the
# counts add up; the rule written a second way; no committed table holds a
# position finer than the publish grid. The table is written first; then any
# failure stops the script.
rule("STEP 12.5 — pinch-point QA -> tbl_14_pinch_qa.csv")
pqa_row <- function(surface, check, value, pass) {
  data.frame(surface = surface, check = check, value = as.character(value),
             pass = isTRUE(pass), stringsAsFactors = FALSE)
}
pqa_tbl <- function(surface, x) {
  data.frame(surface = surface, check = x$check, value = x$value,
             pass = x$pass, stringsAsFactors = FALSE)
}

# ---- 12.5a Self-tests and road cells (collected) ---------------------------------
pinch_qa <- rbind(
  pqa_row("test case", "crossings: hand-made path, road and counts (STEP 12.2)",
          sprintf("%d of %d cases", sum(pinch_st$pass), nrow(pinch_st)),
          all(pinch_st$pass)),
  pqa_row("test case", "sites and rule: hand-made case (STEP 12.3)",
          sprintf("%d of %d cases", sum(pinch_st2$pass), nrow(pinch_st2)),
          all(pinch_st2$pass)),
  pqa_row("test case", "variant comparison: hand-made case (STEP 12.4)",
          sprintf("%d of %d cases", sum(pinch_st3$pass), nrow(pinch_st3)),
          all(pinch_st3$pass)),
  pqa_tbl("roads", road_chk))

# ---- 12.5b Each surface ----------------------------------------------------------------
pinch_all <- c(stats::setNames(list(pinch_base), PINCH_BASE_SURFACE), pinch_var)
for (sname in names(pinch_all)) {
  is_b <- sname == PINCH_BASE_SURFACE
  pinch_qa <- rbind(pinch_qa, pqa_tbl(sname, pinch_check_surface(
    ps = pinch_all[[sname]],
    paths = if (is_b) paths_base else paths_var[[sname]],
    links = pinch_links[[sname]], flags = pinch_flags[[sname]], pairs = pairs,
    road_rank_v = road_rank_v, nc = nc_12, res_km = res_12,
    link_roles = PINCH_PATH_LINK_ROLES,
    rule_link_roles = PINCH_RULE_LINK_ROLES, merge_km = PINCH_SITE_MERGE_KM,
    shared_min_edges = PINCH_SHARED_MIN_EDGES,
    lit_pair_ids = pinch_lit$pair_id)))
}

# ---- 12.5c Baseline results and the comparison ------------------------------------------
cmp_lab <- ifelse(!is.na(pinch_cmp_tbl$site_overlap) &
                    pinch_cmp_tbl$site_overlap >=
                    PINCH_COMPARE_ROBUST_MIN_OVERLAP - 1e-9, "robust",
                  "sensitive")
cmp_choice <- vapply(pinch_cmp_tbl$tests, function(ch) {
  if (all(cmp_lab[pinch_cmp_tbl$tests == ch] == "robust")) "robust"
  else "sensitive"
}, character(1))
shares <- unlist(pinch_cmp_tbl[, c("share_base", "share_variant",
                                   "site_overlap", "all_sites_overlap")])
pinch_qa <- rbind(
  pinch_qa,
  pqa_row(PINCH_BASE_SURFACE,
          "the chain function gives the crossings and sites of STEPs 12.2-12.3",
          sprintf("%d crossings, %d sites", nrow(cx), nrow(sites_base)),
          identical(pinch_base$crossings$crossing_id, cx$crossing_id) &&
            identical(pinch_base$crossings$site_id, cx$site_id) &&
            identical(pinch_base$sites$pinch_tier, sites_base$pinch_tier)),
  pqa_row(PINCH_BASE_SURFACE, "site ids are 1 to n, in the order of the lowest cell",
          nrow(sites_base),
          identical(sites_base$site_id, seq_len(nrow(sites_base))) &&
            !is.unsorted(tapply(vapply(cx$cells, min, numeric(1)), cx$site_id,
                                min))),
  pqa_row(PINCH_BASE_SURFACE, "each lit_flag link of the config is an in-network link",
          paste(pinch_lit$pair_id, collapse = ", "),
          all(pinch_lit$pair_id %in% net_links$pair_id)),
  pqa_row("all", "comparison: one row per variant; each variant differs in one choice",
          paste(pinch_cmp_tbl$variant, collapse = ", "),
          identical(pinch_cmp_tbl$variant, PINCH_COMPARE_VARIANTS) &&
            !anyNA(pinch_cmp_tbl$tests)),
  pqa_row("all", "comparison: shares are 0 to 1; site_overlap = the lower share",
          paste(sprintf("%.3f", pinch_cmp_tbl$site_overlap), collapse = ", "),
          all(shares >= 0 & shares <= 1, na.rm = TRUE) &&
            isTRUE(all.equal(pinch_cmp_tbl$site_overlap,
                             pmin(pinch_cmp_tbl$share_base,
                                  pinch_cmp_tbl$share_variant)))),
  pqa_row("all", "comparison: labels by the fixed rule (written a second way)",
          paste(sprintf("%s %s", pinch_cmp_tbl$variant, pinch_cmp_tbl$label),
                collapse = "; "),
          identical(cmp_lab, pinch_cmp_tbl$label) &&
            identical(unname(cmp_choice), pinch_cmp_tbl$choice_label)),
  pqa_row("all", "n_variants_near = the number of variants with a pinch point near",
          sprintf("%d sites", nrow(sites_base)),
          identical(sites_base$n_variants_near,
                    as.integer(rowSums(sites_base[, near_cols, drop = FALSE]))) &&
            all(vapply(PINCH_COMPARE_VARIANTS, function(v) {
              identical(sites_base[[paste0("near_pinch_", v)]],
                        pinch_cmp[[v]]$near_base)
            }, logical(1)))))

# ---- 12.5d Tables and layers on disk -----------------------------------------------------
# Each committed tbl_14 table: the row count, and no position finer than the
# publish grid. (tbl_14_pinch_qa.csv itself holds no position.)
pqa_disk <- list(
  road_crossings = list(n = nrow(crossings_out), grid = TRUE),
  pinch_points = list(n = nrow(sites_out), grid = TRUE),
  pinch_link_summary = list(n = nrow(links_sum_out), grid = FALSE),
  pinch_variant_comparison = list(n = nrow(pinch_cmp_tbl), grid = FALSE))
banned_cols <- c("cell", "cells", "mid_cell", "mean_cell", "exit_cell",
                 "entry_cell", "x", "y", "mean_x", "mean_y", "lon", "lat",
                 "longitude", "latitude", "geom", "geometry")
for (slug in names(pqa_disk)) {
  f <- file.path(DIR_TABLES, sprintf("tbl_14_%s.csv", slug))
  d <- if (file.exists(f)) utils::read.csv(f, stringsAsFactors = FALSE) else NULL
  pinch_qa <- rbind(pinch_qa, pqa_row(
    "all", sprintf("on disk: %s", basename(f)),
    sprintf("%s rows, %d expected", if (is.null(d)) NA else nrow(d),
            pqa_disk[[slug]]$n),
    !is.null(d) && nrow(d) == pqa_disk[[slug]]$n))
  pub_ok <- !is.null(d) && if (pqa_disk[[slug]]$grid) {
    all(pinch_check_publish_table(d, lcp_base, PINCH_PUBLISH_GRID_M,
                                  grid_prefix)$pass)
  } else {
    !any(names(d) %in% banned_cols) && !any(grepl("^grid", names(d)))
  }
  pinch_qa <- rbind(pinch_qa, pqa_row(
    "all", sprintf("no position finer than the publish grid: %s", basename(f)),
    if (pqa_disk[[slug]]$grid) sprintf("positions at %g km", PINCH_PUBLISH_GRID_M / 1000)
    else "no position column", pub_ok))
}
lay <- if (file.exists(crossings_gpkg)) sf::st_layers(crossings_gpkg) else NULL
lay_n <- vapply(names(pinch_all), function(s) nrow(pinch_all[[s]]$cells),
                integer(1))
pinch_qa <- rbind(
  pinch_qa,
  pqa_row("all", "1 km file: one layer per surface, one point per crossing cell",
          if (is.null(lay)) "file absent" else
            paste(sprintf("%s %s", lay$name, lay$features), collapse = "; "),
          !is.null(lay) && setequal(lay$name, names(pinch_all)) &&
            identical(as.integer(lay$features[match(names(pinch_all), lay$name)]),
                      unname(lay_n))),
  pqa_row("all", "1 km file is under data/ (gitignored), not under outputs/",
          sub(here::here(), "", crossings_gpkg, fixed = TRUE),
          startsWith(normalizePath(crossings_gpkg, winslash = "/", mustWork = FALSE),
                     normalizePath(here::here("data"), winslash = "/",
                                   mustWork = FALSE))))
rownames(pinch_qa) <- NULL

# ---- 12.5e Report, write, stop on failure --------------------------------------------------
pqa_sum <- stats::aggregate(pass ~ surface, data = pinch_qa,
                            FUN = function(x) sprintf("%d of %d", sum(x), length(x)))
pqa_sum <- pqa_sum[match(unique(pinch_qa$surface), pqa_sum$surface), ]
names(pqa_sum)[2] <- "checks_passed"
print(pqa_sum, row.names = FALSE)
write_table(pinch_qa, 14, "pinch_qa")
if (!all(pinch_qa$pass)) {
  cat("FAILED checks:\n")
  print(pinch_qa[!pinch_qa$pass, ], row.names = FALSE, right = FALSE)
  stop("Pinch-point QA failed: ", sum(!pinch_qa$pass), " check(s). See ",
       "tbl_14_pinch_qa.csv.", call. = FALSE)
}
rule(sprintf(paste0("STEP 12.5 done — pinch-point QA: %d of %d checks pass. ",
                    "Next: STEP 12.6 publishable tables (task 12.7)."),
             sum(pinch_qa$pass), nrow(pinch_qa)))

# =============================================================================
# STEP 12.6 — publishable tables (task 12.7; Decision 20 point 7)
# =============================================================================
# tbl_03_reserve_network.csv — one row per network reserve (56). The network
#   results of the reserve's node (STEPs 11.2-11.3: set, degree, betweenness,
#   linchpin with cross_group_dependent and stable_linchpin, cut node,
#   pendant, cheapest link) and the pinch points on the edges of the node, by
#   tier. The values are per node: the reserves of one block share them. No
#   position.
# tbl_03b_pinch_points.csv — one row per baseline pinch point (all tiers;
#   author choice 2026-10-10), sorted by tier, then site_id: the two flags,
#   the edges and bridge edges, the links by name, the highest road class,
#   the reserves, lit_flag, state, district, the cell of the publish grid,
#   and the variant result of the site.
# "Pinch point" here is NOT the pinch point of circuit-theory mapping
# (Decision 20 point 5). A path and a crossing are modelled, not observed.
# Publish check: assert_publishable_table() (R/00_functions_sensitive.R;
# sensitive-data policy §3) before each write.
# tbl_03_notes.md — the note file of the two tables (Decision 20 point 5:
#   each table says what a pinch point is here; author choice 2026-10-10).
rule(paste0("STEP 12.6 — publishable tables (Decision 20 point 7) -> ",
            "tbl_03_reserve_network.csv, tbl_03b_pinch_points.csv"))
source(here("R", "00_functions_sensitive.R"))

# ---- 12.6a tbl_03: one row per network reserve -----------------------------------
node_sum <- pinch_node_summary(cx, sites_base, net_links, net_nodes$node_id,
                               PINCH_RULE_LINK_ROLES)
met_cols <- c("unit_id", "unit_name", "network_group", "node_id", "node_name",
              "block_size", "set_id", "set_size", "degree", "betweenness_norm",
              "betweenness_rank", "linchpin", "cross_group_dependent",
              "stable_linchpin", "cut_node", "pendant", "isolated",
              "cheapest_link_rkm", "cheapest_link_rank")
if (!all(met_cols %in% names(metrics_out))) {
  stop("The metrics table of STEP 11.3 has no column(s): ",
       paste(setdiff(met_cols, names(metrics_out)), collapse = ", "),
       call. = FALSE)
}
tbl03 <- metrics_out[, met_cols]
tbl03$state <- res_net$state[match(tbl03$unit_id, res_net$unit_id)]
tbl03 <- tbl03[, append(met_cols, "state", after = 2L)]
tbl03$betweenness_norm  <- round(tbl03$betweenness_norm, 4)
tbl03$cheapest_link_rkm <- round(tbl03$cheapest_link_rkm, 1)
k_ns <- match(tbl03$node_id, node_sum$node_id)
tbl03 <- cbind(tbl03, node_sum[k_ns, c("n_bridge_edges", "n_crossings",
                                       "n_sites", "n_pinch_points",
                                       "n_pinch_tier1", "n_pinch_tier2",
                                       "n_pinch_tier3")])
tbl03 <- tbl03[order(tbl03$unit_id), ]
rownames(tbl03) <- NULL

# ---- 12.6b tbl_03b: one row per baseline pinch point --------------------------------
b_cols <- c("site_id", "pinch_tier", "on_bridge", "shared", "n_edges",
            "n_bridges", "links", "road_class_top", "in_reserve_unit_ids",
            "lit_flag", "lit_flag_any", "state", "district", "district_code",
            names(g_s), near_cols, "n_variants_near")
tbl03b <- sites_base[sites_base$pinch_point, b_cols]
tbl03b <- tbl03b[order(tbl03b$pinch_tier, tbl03b$site_id), ]
rownames(tbl03b) <- NULL

# ---- 12.6c Checks (stop on any failure; nothing is written before them) ----------
per_node <- unique(tbl03[, setdiff(names(tbl03), c("unit_id", "unit_name",
                                                   "state", "network_group"))])
edge_sites <- unique(cx$site_id[cx$link_role %in% PINCH_RULE_LINK_ROLES])
t_chk <- c(
  "tbl_03: one row for each network reserve" =
    nrow(tbl03) == NET_EXPECTED_RESERVES && !anyDuplicated(tbl03$unit_id) &&
    setequal(tbl03$unit_id, res_net$unit_id) && !anyNA(tbl03$state),
  "tbl_03: the reserves of one node have the same values" =
    nrow(per_node) == NET_EXPECTED_NODES,
  "tbl_03: the network columns are those of tbl_13_network_metrics" =
    isTRUE(all.equal(tbl03$degree, metrics_out$degree[order(metrics_out$unit_id)])) &&
    identical(tbl03$linchpin, metrics_out$linchpin[order(metrics_out$unit_id)]),
  "tbl_03: node degree = its number of edges in the link table" =
    all(node_sum$n_edges[k_ns] == tbl03$degree),
  "tbl_03: pinch points per node = the sum of the three tiers" =
    all(tbl03$n_pinch_points == tbl03$n_pinch_tier1 + tbl03$n_pinch_tier2 +
          tbl03$n_pinch_tier3) && all(tbl03$n_pinch_points <= tbl03$n_sites),
  "tbl_03: each site on an edge counts for 2 nodes or more" =
    sum(node_sum$n_sites) >= 2L * length(edge_sites),
  "tbl_03: bridge edges per node add up to 2 x the bridges" =
    sum(node_sum$n_bridge_edges) == 2L * sum(net_flags$is_bridge),
  "tbl_03b: one row for each baseline pinch point, by tier then site_id" =
    nrow(tbl03b) == sum(sites_base$pinch_point) &&
    !anyDuplicated(tbl03b$site_id) && !anyNA(tbl03b$pinch_tier) &&
    identical(order(tbl03b$pinch_tier, tbl03b$site_id), seq_len(nrow(tbl03b))),
  "tbl_03b: the rows are the pinch points of tbl_14_pinch_points" =
    isTRUE(all.equal(tbl03b, sites_out[sites_out$pinch_point %in% TRUE,
                                       b_cols], check.attributes = FALSE))
)
for (i in seq_along(t_chk)) {
  cat(sprintf("  %-4s %s\n", if (isTRUE(t_chk[[i]])) "ok" else "FAIL",
              names(t_chk)[i]))
}
if (!all(t_chk)) {
  stop("Publishable-table check(s) failed: ",
       paste(names(t_chk)[!t_chk], collapse = "; "), call. = FALSE)
}

# ---- 12.6d Publish checks (sensitive-data policy §3) and output -------------------
assert_publishable_table(tbl03, prefix = NULL, name = "tbl_03_reserve_network")
assert_publishable_table(tbl03b, prefix = grid_prefix, r = lcp_base,
                         grid_m = PINCH_PUBLISH_GRID_M,
                         name = "tbl_03b_pinch_points")
cat("publish checks pass: tbl_03 has no position; tbl_03b has positions at the",
    PINCH_PUBLISH_GRID_M / 1000, "km grid only\n")

n03 <- unique(tbl03[, c("node_id", "node_name", "set_id", "linchpin",
                        "cross_group_dependent", "stable_linchpin", "cut_node",
                        "pendant", "degree", "n_bridge_edges", "n_pinch_points",
                        "n_pinch_tier1", "n_pinch_tier2", "n_pinch_tier3")])
cat(sprintf(paste0("tbl_03: %d reserves, %d nodes | nodes with a pinch point ",
                   "on an edge: %d | with a tier-1 pinch point: %d\n"),
            nrow(tbl03), nrow(n03), sum(n03$n_pinch_points > 0),
            sum(n03$n_pinch_tier1 > 0)))
cat("the linchpin nodes, with their flags and the pinch points on their edges:\n")
print(n03[n03$linchpin, c("set_id", "node_name", "cross_group_dependent",
                          "stable_linchpin", "cut_node", "degree",
                          "n_bridge_edges", "n_pinch_points", "n_pinch_tier1",
                          "n_pinch_tier2", "n_pinch_tier3")][
            order(n03$set_id[n03$linchpin]), ], row.names = FALSE, right = FALSE)
cat("the nodes with the most pinch points on their edges:\n")
print(utils::head(n03[order(-n03$n_pinch_points, n03$node_id),
                      c("node_name", "linchpin", "pendant", "degree",
                        "n_bridge_edges", "n_pinch_points", "n_pinch_tier1",
                        "n_pinch_tier2", "n_pinch_tier3")], 8),
      row.names = FALSE, right = FALSE)
cat(sprintf("tbl_03b: %d pinch points | tier 1: %d, tier 2: %d, tier 3: %d\n",
            nrow(tbl03b), sum(tbl03b$pinch_tier == 1L),
            sum(tbl03b$pinch_tier == 2L), sum(tbl03b$pinch_tier == 3L)))
write_table(tbl03, 3, "reserve_network")
utils::write.csv(tbl03b, file.path(DIR_TABLES, "tbl_03b_pinch_points.csv"),
                 row.names = FALSE)
message("Wrote ", file.path(DIR_TABLES, "tbl_03b_pinch_points.csv"), " (",
        nrow(tbl03b), " rows)")
for (f in c("tbl_03_reserve_network.csv", "tbl_03b_pinch_points.csv")) {
  n_disk <- nrow(utils::read.csv(file.path(DIR_TABLES, f)))
  if (n_disk != if (f == "tbl_03_reserve_network.csv") nrow(tbl03) else nrow(tbl03b)) {
    stop(f, ": the file on disk has ", n_disk, " rows.", call. = FALSE)
  }
}
# ---- 12.6e Note file (Decision 20 point 5; author choice 2026-10-10) -----------------
# What a pinch point is here, the tiers and the limits, next to the two
# tables. Every value is a config value or a count of this run. No position.
note_path  <- file.path(DIR_TABLES, "tbl_03_notes.md")
note_lines <- pinch_table_note(
  n_reserves = nrow(tbl03), n_nodes = nrow(n03),
  tiers = as.integer(table(factor(tbl03b$pinch_tier, levels = 1:3))),
  road_classes = PINCH_ROAD_CLASS_ORDER, merge_km = PINCH_SITE_MERGE_KM,
  shared_min = PINCH_SHARED_MIN_EDGES, grid_m = PINCH_PUBLISH_GRID_M,
  compare_d_km = PINCH_COMPARE_D_KM,
  n_variants = length(PINCH_COMPARE_VARIANTS),
  choice_labels = stats::setNames(
    as.vector(pinch_choice_label),
    sub(" \\(Decision.*$", "", names(pinch_choice_label))),
  linchpin_top_n = NET_LINCHPIN_TOP_N)
if (any(grepl("[^ -~]", note_lines))) {
  stop("The note file must be ASCII text; a line has another character.",
       call. = FALSE)
}
writeLines(note_lines, note_path)
if (!identical(readLines(note_path), note_lines)) {
  stop("tbl_03_notes.md: the file on disk is not the text that was written.",
       call. = FALSE)
}
message("Wrote ", note_path, " (", length(note_lines), " lines)")
rule(sprintf(paste0("STEP 12.6 done — tbl_03 (%d reserves), tbl_03b (%d pinch ",
                    "points) and tbl_03_notes.md written. Next: STEP 12.7 ",
                    "figure (task 12.8)."),
             nrow(tbl03), nrow(tbl03b)))

# =============================================================================
# STEP 12.7 — figure fig_03 (task 12.8; Decision 20 point 7, g1)
# =============================================================================
# A map at national scale:
#   - the nodes by flag: linchpin with its two flags (`stable_linchpin`,
#     `cross_group_dependent`), cut node (a ring), pendant, other;
#   - the baseline edge paths as modelled lines, with the bridge links marked;
#   - the baseline pinch points at the centre of their publish-grid cell, by
#     tier. Author choice 2026-10-10: all three tiers; tier 3 small and pale.
# Positions (sensitive-data policy §3): the pinch points are read from
# `tbl03b` (the publishable table) only. The path lines are drawn in this
# static figure at national scale only. A node is drawn at the centroid of
# its reserve polygons (public boundaries).
# Colours: the site symbology of scripts/05 (same hex values). Each class has
# a shape or a size of its own, so that no class is told by colour only.
# Title, subtitle and caption: DRAFT text for the author's edit. Every number
# in them is read from the objects of this run.
rule(sprintf("STEP 12.7 — figure fig_%02d (Decision 20 point 7)",
             PINCH_FIG_NUMBER))
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("STEP 12.7 needs the package ggplot2 (scripts/05 uses it; it is in ",
       "renv.lock). Run renv::restore().", call. = FALSE)
}
suppressPackageStartupMessages(library(ggplot2))

# ---- 12.7a Self-test of the figure tables ----------------------------------------
fig_test <- pinch_selftest_figure()
if (!all(fig_test)) {
  stop("pinch_selftest_figure() failed: ",
       paste(names(fig_test)[!fig_test], collapse = "; "), call. = FALSE)
}
cat(sprintf("figure-table self-test: %d of %d cases pass\n", sum(fig_test),
            length(fig_test)))

# ---- 12.7b The tables that the figure draws ---------------------------------------
# Nodes: one row per node, from the publishable reserve table.
fig_nodes <- unique(tbl03[, c("node_id", "node_name", "set_id", "set_size",
                              "betweenness_rank", "linchpin",
                              "stable_linchpin", "cross_group_dependent",
                              "cut_node", "pendant", "isolated", "degree")])
fig_nodes <- merge(fig_nodes, pinch_node_points(res_net, net_nodes),
                   by = "node_id")
fig_nodes <- fig_nodes[order(fig_nodes$node_id), ]
# Pinch points: the publishable table only (it passed the publish check in
# STEP 12.6; the check runs again here on the table that is drawn).
assert_publishable_table(tbl03b, prefix = grid_prefix, r = lcp_base,
                         grid_m = PINCH_PUBLISH_GRID_M,
                         name = "the pinch points of the figure")
fig_marks <- pinch_figure_marks(fig_nodes, tbl03b, grid_prefix)
fig_cls   <- pinch_figure_classes(1L + length(PINCH_COMPARE_VARIANTS),
                                  PINCH_SHARED_MIN_EDGES)
fig_cls   <- fig_cls[fig_cls$cls %in% fig_marks$cls, ]
fig_marks$cls <- factor(fig_marks$cls, levels = fig_cls$cls)
fig_marks <- fig_marks[order(fig_cls$draw[as.integer(fig_marks$cls)]), ]
# Edge paths: the line and the pair number only (no cell list).
fig_edge_ids <- net_links$pair_id[net_links$link_role %in% PINCH_RULE_LINK_ROLES]
fig_paths <- paths_base[match(fig_edge_ids, paths_base$pair_id), "pair_id"]
fig_paths$bridge <- net_flags$is_bridge[match(fig_paths$pair_id,
                                              net_flags$pair_id)]
fig_link_levels <- c("Link", "Bridge link: without it,\nits set divides")
fig_paths$kind <- factor(fig_link_levels[1L + fig_paths$bridge],
                         levels = fig_link_levels)
# Linchpin list: a number in each linchpin mark, and the names by set.
fig_lp <- fig_nodes[fig_nodes$linchpin, ]
fig_lp <- fig_lp[order(fig_lp$set_id, fig_lp$betweenness_rank, fig_lp$node_id), ]
fig_lp$num <- seq_len(nrow(fig_lp))
fig_key <- paste(c("Linchpin nodes", unlist(lapply(
  split(fig_lp, fig_lp$set_id), function(z) {
    c(sprintf("Set of %d nodes", z$set_size[1]),
      vapply(seq_len(nrow(z)), function(i) {
        paste(strwrap(z$node_name[i], width = 30,
                      initial = sprintf("%d  ", z$num[i]), exdent = 5),
              collapse = "\n")
      }, character(1)))
  }))), collapse = "\n")

# ---- 12.7c Checks (stop on any failure; the file is not written before them) -----
fig_bb <- sf::st_bbox(states_sf)
in_bb  <- function(x, y) {
  all(x >= fig_bb[["xmin"]] & x <= fig_bb[["xmax"]] &
        y >= fig_bb[["ymin"]] & y <= fig_bb[["ymax"]])
}
pm <- fig_marks[fig_marks$kind == "pinch", ]
k_pm <- match(pm$id, tbl03b$site_id)
fig_chk <- c(
  "nodes: one mark for each node of the network" =
    sum(fig_marks$kind == "node") == NET_EXPECTED_NODES &&
    setequal(fig_marks$id[fig_marks$kind == "node"], net_nodes$node_id),
  "nodes: the linchpin marks are the linchpin nodes of tbl_03" =
    setequal(fig_marks$id[grepl("^lp_", fig_marks$cls)],
             tbl03$node_id[tbl03$linchpin]) &&
    nrow(fig_lp) == length(unique(tbl03$node_id[tbl03$linchpin])),
  "nodes: one ring for each cut node; one pendant mark for each pendant node" =
    setequal(fig_marks$id[fig_marks$kind == "cut"],
             tbl03$node_id[tbl03$cut_node]) &&
    setequal(fig_marks$id[fig_marks$cls %in% "pend"],
             tbl03$node_id[tbl03$pendant & !tbl03$linchpin]),
  "nodes: each position is inside the extent of the state layer" =
    in_bb(fig_nodes$x, fig_nodes$y),
  "paths: one line for each baseline edge; each line is a path" =
    nrow(fig_paths) == sum(net_links$link_role %in% PINCH_RULE_LINK_ROLES) &&
    !anyNA(fig_paths$pair_id) && !anyDuplicated(fig_paths$pair_id) &&
    all(paths_base$path_status[match(fig_paths$pair_id, paths_base$pair_id)] ==
          "path") &&
    !any(sf::st_is_empty(fig_paths)),
  "paths: the bridge lines are the bridge edges" =
    !anyNA(fig_paths$bridge) &&
    sum(fig_paths$bridge) == sum(net_flags$is_bridge) &&
    setequal(fig_paths$pair_id[fig_paths$bridge],
             net_flags$pair_id[net_flags$is_bridge]),
  "paths: the figure table holds the line and the pair number only" =
    identical(setdiff(names(fig_paths), attr(fig_paths, "sf_column")),
              c("pair_id", "bridge", "kind")),
  "pinch points: one mark for each row of tbl_03b, with its tier" =
    nrow(pm) == nrow(tbl03b) && !anyNA(k_pm) &&
    identical(as.character(pm$cls), paste0("t", tbl03b$pinch_tier[k_pm])),
  "pinch points: each mark is at the centre of its publish-grid cell" =
    isTRUE(all.equal(pm$x, tbl03b[[paste0(grid_prefix, "_x_km")]][k_pm] * 1000)) &&
    isTRUE(all.equal(pm$y, tbl03b[[paste0(grid_prefix, "_y_km")]][k_pm] * 1000)) &&
    in_bb(pm$x, pm$y),
  "legend: each mark has a class of the legend" = !anyNA(fig_marks$cls)
)
for (i in seq_along(fig_chk)) {
  cat(sprintf("  %-4s %s\n", if (isTRUE(fig_chk[[i]])) "ok" else "FAIL",
              names(fig_chk)[i]))
}
if (!all(fig_chk)) {
  stop("Figure check(s) failed: ",
       paste(names(fig_chk)[!fig_chk], collapse = "; "),
       ". The figure is not written.", call. = FALSE)
}

# ---- 12.7d Colours and mark specifications -----------------------------------------
# The first six values are the site symbology (the same hex values as in
# scripts/05_growth_analysis.R). The other colours are mixes of them.
PAL_GROW    <- "#225522"
PAL_DECLINE <- "#e34a33"
INK         <- "#1e1e1e"
PAPER       <- "#f7f4ee"
STATE_FILL  <- "#e9e4d8"
STATE_LINE  <- "#d4cfc4"
fig_mix <- function(a, b, w) {
  grDevices::rgb(grDevices::colorRamp(c(a, b))(w), maxColorValue = 255)
}
FIG_RESERVE_FILL <- fig_mix(PAPER, PAL_GROW, 0.35)     # reserve polygons
FIG_LINK_COL     <- fig_mix(PAPER, INK, 0.55)          # links; other nodes
FIG_TIER3_FILL   <- fig_mix(PAPER, PAL_DECLINE, 0.35)  # tier 3: pale
FIG_TIER3_LINE   <- fig_mix(PAPER, PAL_DECLINE, 0.75)
# shape: 21 circle, 23 diamond, 24 triangle (each with a fill and an outline).
# Nodes are circles or diamonds; pinch points are triangles.
fig_spec <- data.frame(
  cls    = c("lp_s", "lp_sx", "lp_n", "lp_nx", "oth", "pend", "cut",
             "t1", "t2", "t3"),
  shape  = c(21, 23, 21, 23, 21, 21, 21, 24, 24, 24),
  fill   = c(PAL_GROW, PAL_GROW, PAPER, PAPER, FIG_LINK_COL, PAPER, NA,
             PAL_DECLINE, PAL_DECLINE, FIG_TIER3_FILL),
  colour = c(INK, INK, PAL_GROW, PAL_GROW, INK, INK, INK,
             INK, PAL_DECLINE, FIG_TIER3_LINE),
  size   = c(4.6, 4.6, 4.6, 4.6, 1.9, 1.9, 6.6, 3.0, 1.6, 0.9),
  stroke = c(0.4, 0.4, 1.1, 1.1, 0.3, 0.5, 0.7, 0.6, 0.2, 0.25),
  stringsAsFactors = FALSE)
fig_spec <- fig_spec[match(fig_cls$cls, fig_spec$cls), ]
fig_val  <- function(col) stats::setNames(fig_spec[[col]], fig_spec$cls)
fig_num_col <- ifelse(fig_lp$stable_linchpin, PAPER, INK)   # number in the mark
FIG_LINK_LWD <- stats::setNames(c(0.3, 0.9), fig_link_levels)
fig_marks_name <- "Nodes and road pinch points"

# ---- 12.7e Title, subtitle and caption (DRAFT text for the author's edit) ------------
fig_tiers  <- table(factor(tbl03b$pinch_tier, levels = 1:3))
fig_t1_states <- table(tbl03b$state[tbl03b$pinch_tier == 1L])
fig_absent <- reserves_lcp$unit_name[!as.logical(reserves_lcp$geometry_present)]
fig_title  <- "Tiger reserve network: modelled links, linchpin nodes and road pinch points"
fig_sub <- sprintf(
  paste0("%d nodes (%d reserves) and %d modelled links, of which %d are bridge ",
         "links.\n%d road pinch points (tier 1: %d, tier 2: %d, tier 3: %d). ",
         "Baseline resistance surface."),
  nrow(fig_nodes), nrow(tbl03), nrow(fig_paths), sum(fig_paths$bridge),
  nrow(tbl03b), fig_tiers[["1"]], fig_tiers[["2"]], fig_tiers[["3"]])
fig_cap_parts <- c(
  sprintf(paste0("Lines: the %d least-cost paths between the nodes on the ",
                 "baseline resistance surface (Decisions 17 to 19). The paths ",
                 "are modelled. They are not observed tiger movement. The ",
                 "surface is India-only: a path cannot go through a neighbour ",
                 "country."), nrow(fig_paths)),
  sprintf(paste0("Pinch point (Decision 20): a place where a barrier road ",
                 "(OpenStreetMap %s) meets a modelled path that is a bridge ",
                 "link, or that %d or more links share. It is not the pinch ",
                 "point of circuit-theory mapping. Each pinch point is drawn ",
                 "at the centre of its %g km grid cell. The %d pinch points ",
                 "are in %d cells; marks in the same cell or in adjacent ",
                 "cells overlap."),
          paste(PINCH_ROAD_CLASS_ORDER, collapse = ", "),
          PINCH_SHARED_MIN_EDGES, PINCH_PUBLISH_GRID_M / 1000, nrow(tbl03b),
          length(unique(tbl03b[[paste0(grid_prefix, "_id")]]))),
  if (fig_tiers[["1"]] > 0) {
    sprintf("The %d tier-1 pinch points are in: %s.", fig_tiers[["1"]],
            paste(sprintf("%s (%d)", names(fig_t1_states), fig_t1_states),
                  collapse = ", "))
  },
  sprintf(paste0("Linchpin: a node with a betweenness rank from 1 to %d in ",
                 "its set of joined nodes. The number %d is a judgement ",
                 "value: in a small set, %d nodes are a large share of the ",
                 "set."), NET_LINCHPIN_TOP_N, NET_LINCHPIN_TOP_N,
          NET_LINCHPIN_TOP_N),
  sprintf("Variant result for the pinch points (Decision 20): %s.",
          paste(sprintf("%s %s", sub(" \\(Decision.*$", "",
                                     names(pinch_choice_label)),
                        pinch_choice_label), collapse = "; ")),
  if (length(fig_absent) > 0) {
    sprintf("Not in the network (no boundary polygon): %s.",
            paste(fig_absent, collapse = ", "))
  },
  paste0("Sources: roads \u00a9 OpenStreetMap contributors (ODbL); state ",
         "lines Natural Earth (approximate); reserve boundaries NTCA."))
fig_cap <- paste(strwrap(paste(fig_cap_parts, collapse = " "), width = 185),
                 collapse = "\n")

# ---- 12.7f The map ----------------------------------------------------------------------
theme_map <- theme_void(base_size = 11) +
  theme(
    plot.background  = element_rect(fill = PAPER, colour = NA),
    panel.background = element_rect(fill = PAPER, colour = NA),
    plot.title       = element_text(face = "bold", colour = INK, size = 15),
    plot.subtitle    = element_text(colour = INK, size = 11),
    plot.caption     = element_text(colour = INK, size = 7.5, hjust = 0,
                                    lineheight = 1.15),
    plot.caption.position = "plot",
    plot.title.position   = "plot",
    legend.title     = element_text(colour = INK, size = 9),
    legend.text      = element_text(colour = INK, size = 8, lineheight = 0.95),
    legend.key.height = grid::unit(27, "pt"),
    legend.position  = "right",
    plot.margin      = margin(10, 10, 10, 10))
fig_w <- fig_bb[["xmax"]] - fig_bb[["xmin"]]
fig_h <- fig_bb[["ymax"]] - fig_bb[["ymin"]]
p03 <- ggplot() +
  geom_sf(data = states_sf, fill = STATE_FILL, colour = STATE_LINE,
          linewidth = 0.2) +
  geom_sf(data = res_net, fill = FIG_RESERVE_FILL, colour = NA) +
  geom_sf(data = fig_paths[!fig_paths$bridge, ], aes(linewidth = kind),
          colour = FIG_LINK_COL, key_glyph = "path") +
  geom_sf(data = fig_paths[fig_paths$bridge, ], aes(linewidth = kind),
          colour = INK, key_glyph = "path") +
  geom_point(data = fig_marks,
             aes(x = x, y = y, shape = cls, fill = cls, colour = cls,
                 size = cls, stroke = cls)) +
  geom_text(data = fig_lp, aes(x = x, y = y, label = num), colour = fig_num_col,
            size = 2.7, fontface = "bold") +
  annotate("text", x = fig_bb[["xmin"]] + PINCH_FIG_KEY_POS[["x"]] * fig_w,
           y = fig_bb[["ymin"]] + PINCH_FIG_KEY_POS[["y"]] * fig_h,
           label = fig_key, hjust = 0, vjust = 1, size = 2.7, colour = INK,
           lineheight = 1.1) +
  scale_linewidth_manual(
    values = FIG_LINK_LWD, drop = FALSE,
    name = "Modelled least-cost path",
    guide = guide_legend(order = 1, override.aes = list(
      colour = c(FIG_LINK_COL, INK)))) +
  scale_shape_manual(values = fig_val("shape"), labels = fig_cls$label,
                     name = fig_marks_name, guide = guide_legend(order = 2)) +
  scale_fill_manual(values = fig_val("fill"), labels = fig_cls$label,
                    name = fig_marks_name, na.value = NA,
                    guide = guide_legend(order = 2)) +
  scale_colour_manual(values = fig_val("colour"), labels = fig_cls$label,
                      name = fig_marks_name, guide = guide_legend(order = 2)) +
  scale_size_manual(values = fig_val("size"), labels = fig_cls$label,
                    name = fig_marks_name, guide = guide_legend(order = 2)) +
  scale_discrete_manual("stroke", values = fig_val("stroke"),
                        labels = fig_cls$label, name = fig_marks_name,
                        guide = guide_legend(order = 2)) +
  coord_sf(crs = sf::st_crs(states_sf), datum = NA) +
  labs(title = fig_title, subtitle = fig_sub, caption = fig_cap) +
  theme_map

# ---- 12.7g Output ------------------------------------------------------------------
if (!dir.exists(DIR_FIGURES)) dir.create(DIR_FIGURES, recursive = TRUE)
fig03_path <- file.path(DIR_FIGURES, sprintf("fig_%02d_%s.png", PINCH_FIG_NUMBER,
                                             PINCH_FIG_SLUG))
ggsave(fig03_path, plot = p03, width = PINCH_FIG_SIZE_IN[["width"]],
       height = PINCH_FIG_SIZE_IN[["height"]], dpi = PINCH_FIG_DPI, bg = PAPER)
if (!file.exists(fig03_path) || file.size(fig03_path) == 0) {
  stop("The figure file was not written: ", fig03_path, call. = FALSE)
}
message("Wrote ", fig03_path)
cat(sprintf(paste0("fig_%02d: %d nodes (%d linchpin, %d cut-node rings, %d ",
                   "pendant) | %d edge paths (%d bridge links) | %d pinch ",
                   "points (tier 1: %d, tier 2: %d, tier 3: %d) in %d cells ",
                   "of %g km\n"),
            PINCH_FIG_NUMBER, nrow(fig_nodes), nrow(fig_lp),
            sum(fig_marks$kind == "cut"), sum(fig_marks$cls %in% "pend"),
            nrow(fig_paths), sum(fig_paths$bridge), nrow(tbl03b),
            fig_tiers[["1"]], fig_tiers[["2"]], fig_tiers[["3"]],
            length(unique(tbl03b[[paste0(grid_prefix, "_id")]])),
            PINCH_PUBLISH_GRID_M / 1000))
cat("the classes in the legend:\n")
print(data.frame(class = gsub("\n", " ", fig_cls$label),
                 marks = as.vector(table(fig_marks$cls))),
      row.names = FALSE, right = FALSE)
cat("the linchpin numbers:\n")
print(fig_lp[, c("num", "node_name", "set_id", "set_size", "betweenness_rank",
                 "stable_linchpin", "cross_group_dependent", "cut_node")],
      row.names = FALSE, right = FALSE)
cat("title, subtitle and caption are DRAFT text for the author's edit:\n")
cat(fig_title, "\n", fig_sub, "\n", fig_cap, "\n", sep = "")
rule(sprintf(paste0("STEP 12.7 done — fig_%02d_%s.png written. Stage 2 code is ",
                    "complete. Next: docs close (task 12.10)."),
             PINCH_FIG_NUMBER, PINCH_FIG_SLUG))
