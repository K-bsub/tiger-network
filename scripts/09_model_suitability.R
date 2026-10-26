# =============================================================================
# 09_model_suitability.R  [STAGE 3 — HABITAT SUITABILITY, Weeks 14-16]
# The model at a coarser grain of Decision 23 (2026-10-25): a maxnet model on
# the obscured iNaturalist tiger records, on the 0.2 degree cells of the
# iNaturalist obscuring grid, with a background of the clean iNaturalist
# Mammalia records.
#
# Process choices of task 14.2 (2026-10-25):
#   s1  one script for Weeks 14-16 (the count, the fit, the prediction, the
#       validation, Gi*, the figures), one STEP block per task, as scripts/07
#   f1  the functions are in R/00_functions_sdm.R
#   w2  the background of Decision 23 r2 comes from scripts/08 STEP 13.3
#       (effort_background_inat_cell02_7755.gpkg), with the 0.2 degree cells
#       of the GBIF coordinates; this script does not read a GBIF file
#   g1  model cells (task 14.4): the centre of each complete-case 1 km cell
#       is converted to longitude and latitude and gets its 0.2 degree cell
#       by the record rule (occ_cell02()); the share of a cell = the count of
#       its complete-case centres x 1 km2 / the area of the cell polygon in
#       EPSG:7755 (edges densified every 0.01 degrees)
#   t1  tbl_16_sdm_counts.csv (task 14.4) and tbl_16_sdm_qa.csv (task 14.6);
#       each later task names its own tables
#   l1  the outcome lock SDM_GRAIN_OUTCOME (R/00_config.R): NA until task
#       14.4; while NA, the script stops at the end of STEP 14.1
#   r1  no run switch yet; a STEP that writes a layer for later STEPs gets a
#       switch when it is added
#   o2  (the order) the count first (task 14.4), then Decision 24 (task 14.3),
#       then the covariate summaries and the fit (task 14.5)
# Rule d1 of task 13.2 stays: no data file goes to a chat; the chat tests the
# functions on made-up records.
#
# STEPS (each task adds its block; the numbers are those of the Week-14 plan):
#   task 14.2  this header and the guards. No result is printed
#   STEP 14.1 (task 14.4)  the 0.2 degree cells; the model cells (Decision 23
#              point 3); the presence cells and the background cells; the
#              outcome of Decision 23 points 4 and 6 -> tbl_16_sdm_counts.csv;
#              a stop point: the outcome is locked in SDM_GRAIN_OUTCOME.
#              Process choices of task 14.4 (2026-10-25): k1 the grid and the
#              1 km cell-id raster are written to data/processed/ (no
#              presence or background flag in them), with the switch
#              RUN_GRID; h1 a hand-made case (sdm_self_test()) runs first.
#              Ran 2026-10-25: outcome "planned_model" (104 presence cells,
#              1,486 background cells), locked in SDM_GRAIN_OUTCOME
#   Decision 24 (task 14.3), after STEP 14.1 (process choice o2)
#   STEP 14.2 (task 14.5)  the covariate summaries of the model cells; the
#              maxnet fit, the evaluation and the sensitivity runs of Decision
#              24; only with SDM_GRAIN_OUTCOME "reduced_model" or
#              "planned_model". Process choices of task 14.5 (2026-10-25):
#              q1 the covariate table sdm_covariates_cell02.csv under
#              data/processed/ (no presence or background flag), with the
#              switch RUN_COVARIATES; t1 five tbl_16 tables; y1 own code for
#              the Boyce index and the AUC; h1 a hand-made case first
#              (sdm_self_test_142()); w1 no switch for the fits.
#              Ran 2026-10-25: 6 of the 9 candidates kept; lq, regmult 1
#              (10 coefficients); mean test Boyce 0.668 over 5 folds; both
#              sensitivity runs "robust"; RUN_COVARIATES FALSE after the run.
#              By w1, the fits run again in each run of this script; a run
#              on another date writes one more model file
#   STEP 14.3 (task 14.6)  QA -> tbl_16_sdm_qa.csv. Process choices of task
#              14.6 (2026-10-25): c1 a second path for the main numbers (the
#              sdm_qa_* functions; no sdm_* function of STEPs 14.1-14.2); m1
#              the model file of this run; h1 the hand-made cases of STEPs
#              14.1-14.3 as rows of the table (sdm_self_test_143() for the
#              QA functions); p1 the publish checks (a)-(d); s1 no reserve
#              column or name in a tbl_16 table. Reads files only; runs in
#              each run after STEP 14.2; a FALSE stops the script after the
#              table is written (as STEP 13.5 of scripts/08)
#   Weeks 15-16: the prediction, the validation, the Gi* of Decision 23
#              point 8 and the figures (planned in task 14.7)
#
# SENSITIVE DATA (docs/sensitive-data-policy.md; Decision 23 point 9):
#   The obscured set and each layer made from it are tier T1 and stay under
#   data/ (gitignored). This script prints TRUE/FALSE, names and counts only:
#   no coordinate, no 0.2 degree cell corner, no cell index, no cell number.
#   A tbl_16 table holds counts and statistics only.
#
# INPUTS (the guards; all under data/ are gitignored):
#   data/processed/cov_stack_1km_7755.tif                 the 1 km grid and
#                                                         the complete-case
#                                                         cells (scripts/06)
#   data/processed/occ_tiger_gbif_obscured_7755.gpkg      the presences: the
#                                                         obscured set
#                                                         (scripts/08 STEP 13.2)
#   data/processed/effort_background_tgs_clean_7755.gpkg  the clean background
#                                                         (scripts/08 STEP 13.3)
#   data/processed/effort_background_inat_cell02_7755.gpkg
#                                                         the background of
#                                                         Decision 23 r2
#                                                         (scripts/08 STEP 13.3,
#                                                         since 2026-10-25)
#   outputs/tables/tbl_15_occ_sets.csv                    the guard: the layers
#                                                         must give its counts
#   outputs/tables/tbl_10_covariate_stack_qa.csv          the guard: the
#                                                         complete-case count
#
# OUTPUTS (STEP 14.1, task 14.4; process choices k1, t1):
#   data/processed/sdm_grid_cell02_7755.gpkg   one polygon per 0.2 degree cell
#     with one or more complete-case 1 km centres: id, ix, iy, n_cc,
#     area_km2, share, model. Edges densified every 0.01 degrees, in
#     EPSG:7755. No presence or background flag (no tiger position).
#     Gitignored
#   data/processed/sdm_cellid_1km_7755.tif     the 1 km template: the id of
#     the 0.2 degree cell of each complete-case cell (INT4S; NA elsewhere).
#     For the covariate summaries of STEP 14.2. Gitignored
#   outputs/tables/tbl_16_sdm_counts.csv       group, item, value,
#     grain_outcome. The counts of STEP 14.1 and the outcome of Decision 23
#     points 4 and 6. Counts and statistics only: no cell id, no corner
#
# OUTPUTS (STEP 14.2, task 14.5; process choices q1, t1):
#   data/processed/sdm_covariates_cell02.csv   one row per model cell: id,
#     n_cc, the nine candidates of Decision 24, settl_mean, z1_water_excl,
#     z1_elev_floored, water_only. No presence or background flag. Gitignored
#   data/processed/tiger_sdm_maxnet_cell02_<date>.rds   the main model and
#     its settings (Decision 24 point 11). Gitignored
#   outputs/tables/tbl_16_sdm_covariates.csv     covariate, role, kept, min,
#     mean, max, z1_water_1km_cells, z1_floored_1km_cells,
#     z1_water_only_cells
#   outputs/tables/tbl_16_sdm_covariate_cor.csv  var_a, var_b, r, above_limit
#   outputs/tables/tbl_16_sdm_aicc.csv           classes, regmult, status, k,
#     loglik, aicc, delta_aicc, selected
#   outputs/tables/tbl_16_sdm_cv.csv             fold, blocks,
#     test_presence_cells, test_background_cells, train_presence_cells,
#     status, boyce, auc_test, or10, auc_train, auc_diff (rows: the folds,
#     mean, sd, main)
#   outputs/tables/tbl_16_sdm_sensitivity.csv    run, status, presence_cells,
#     background_cells, classes, regmult, rho, top_overlap, label
#   Statistics only: no cell id, no corner, no data row.
#
# INPUTS (STEP 14.3, task 14.6): the layers, the grid, the cell-id raster,
#   the stack and the settlement surface (as above); the covariate table; the
#   model file of this run; the tbl_16 tables; tbl_10;
#   data/processed/boundary_reserves_all_7755.gpkg (unit_name, for check s1);
#   .gitignore (check p1 d).
#
# OUTPUTS (STEP 14.3; process choices t1 of task 14.2, c1, h1, p1):
#   outputs/tables/tbl_16_sdm_qa.csv   group, check, value, pass. One row per
#     check. Written first; then any FALSE in `pass` stops the script.
#
# SETTINGS: the SDM_* values (Decision 23) and the OCC_* values that Decision
#   23 reuses come from R/00_config.R. Do not repeat a value as a literal.
#
# MACHINE TRAP: same PROJ / PostGIS proj.db clash as scripts/06 and 08. Run in
# a FRESH session; the guard below stops if EPSG:7755 does not resolve.
# =============================================================================

# ---- Prerequisites ----------------------------------------------------------
suppressPackageStartupMessages({
  library(here)
  library(terra)
  library(sf)
})

source(here("R", "00_config.R"))             # CRS, DIR_*, OCC_*, SDM_*
source(here("R", "00_functions_io.R"))       # read_vec, write_table
source(here("R", "00_functions_occ.R"))      # occ_id_chr, occ_cell02
source(here("R", "00_functions_sensitive.R"))# publish checks (later STEPs)
source(here("R", "00_functions_sdm.R"))      # sdm_* (task 14.2)

rule <- function(txt) cat("\n", strrep("=", 78), "\n", txt, "\n",
                          strrep("=", 78), "\n", sep = "")

# ---- Run switch (process choice k1, task 14.4, 2026-10-25) --------------------
# TRUE  : STEP 14.1 builds the 0.2 degree grid and the 1 km cell-id raster
#         and writes them (the first run, or after a change of the stack).
# FALSE : STEP 14.1 reads the two files from data/processed/; a guard checks
#         them against the stack.
# Set FALSE after the first run of task 14.4.
# 2026-10-25: FALSE — the run of task 14.4 wrote the two files (7,450 cells).
RUN_GRID <- FALSE

# ---- Run switch (process choice w1, task 14.5, 2026-10-25) ---------------------
# TRUE  : STEP 14.2 builds the covariate table of the model cells and writes
#         it (the first run, or after a change of the stack or the grid).
# FALSE : STEP 14.2 reads it from data/processed/; a guard checks it.
# Set FALSE after the first run of task 14.5.
# 2026-10-25: FALSE — the run of task 14.5 wrote the table (6,969 model
# cells).
RUN_COVARIATES <- FALSE

# ---- Paths ------------------------------------------------------------------
stack_in    <- file.path(DIR_PROCESSED, "cov_stack_1km_7755.tif")
obscured_in <- file.path(DIR_PROCESSED, "occ_tiger_gbif_obscured_7755.gpkg")
bg_clean_in <- file.path(DIR_PROCESSED, "effort_background_tgs_clean_7755.gpkg")
bg_inat_in  <- file.path(DIR_PROCESSED,
                         "effort_background_inat_cell02_7755.gpkg")
sets_tbl_in <- file.path(DIR_TABLES, "tbl_15_occ_sets.csv")
stack_qa_in <- file.path(DIR_TABLES, "tbl_10_covariate_stack_qa.csv")
# STEP 14.1 (k1)
grid_out    <- "sdm_grid_cell02_7755.gpkg"     # in DIR_PROCESSED
cellid_out  <- "sdm_cellid_1km_7755.tif"       # in DIR_PROCESSED
# STEP 14.2 (q1, Decision 24 point 10)
cov_out     <- "sdm_covariates_cell02.csv"     # in DIR_PROCESSED
settl_in    <- file.path(DIR_PROCESSED, "kde_settlement_citytown_1km_7755.tif")
# STEP 14.3 (s1, p1)
reserves_in  <- file.path(DIR_PROCESSED, "boundary_reserves_all_7755.gpkg")
gitignore_in <- here(".gitignore")
# Output table via write_table(nn = 16, slug = "sdm_counts")

# Fields that the later STEPs use. The structure of the scripts/08 layers,
# not choices of the analysis.
FIELDS_OBSCURED <- c("gbifID", "datasetKey", "year", "uncert_m",
                     "cell02_lon_deg", "cell02_lat_deg")
FIELDS_BG_CLEAN <- c("gbifID", "datasetKey", "order", "family", "uncert_set",
                     "cell_1km")
FIELDS_BG_INAT  <- c("gbifID", "datasetKey", "part", "order", "family",
                     "year", "uncert_m", "uncert_set", "cell02_lon_deg",
                     "cell02_lat_deg")

# ---- Guards (fail early; they print no result) ------------------------------
# 0) The run switch.
if (!is.logical(RUN_GRID) || length(RUN_GRID) != 1L || is.na(RUN_GRID)) {
  stop("RUN_GRID must be TRUE or FALSE.", call. = FALSE)
}
if (!is.logical(RUN_COVARIATES) || length(RUN_COVARIATES) != 1L ||
    is.na(RUN_COVARIATES)) {
  stop("RUN_COVARIATES must be TRUE or FALSE.", call. = FALSE)
}
if (RUN_COVARIATES && !file.exists(settl_in)) {
  stop("RUN_COVARIATES = TRUE needs ", settl_in, " (scripts/08 STEP 13.4).",
       call. = FALSE)
}
if (!RUN_COVARIATES && !file.exists(file.path(DIR_PROCESSED, cov_out))) {
  stop("RUN_COVARIATES = FALSE needs ", cov_out, " in ", DIR_PROCESSED,
       " (a run with RUN_COVARIATES <- TRUE writes it).", call. = FALSE)
}
if (!RUN_GRID && !all(file.exists(file.path(DIR_PROCESSED,
                                             c(grid_out, cellid_out))))) {
  stop("RUN_GRID = FALSE needs ", grid_out, " and ", cellid_out, " in ",
       DIR_PROCESSED, " (a run with RUN_GRID <- TRUE writes them).",
       call. = FALSE)
}

# 1) The settings of Decision 23 and the outcome of Decision 21 point 8.
n_cfg <- sdm_check_config()

# 2) The analysis CRS must resolve in this session (PROJ proj.db clash).
crs_wkt <- terra::crs(terra::rast(crs = paste0("EPSG:", CRS_ANALYSIS)))
if (!nzchar(crs_wkt) || !grepl("India", crs_wkt)) {
  stop("EPSG:", CRS_ANALYSIS, " did not resolve to the India NSF LCC frame. ",
       "Restart R so .Rprofile pins PROJ_LIB before terra loads, then re-run.",
       call. = FALSE)
}

# 3) Every input must exist.
inputs <- c(stack_in, obscured_in, bg_clean_in, bg_inat_in, sets_tbl_in,
            stack_qa_in)
missing_inputs <- inputs[!file.exists(inputs)]
if (length(missing_inputs) > 0) {
  stop("Missing required input(s):\n  ",
       paste(missing_inputs, collapse = "\n  "),
       if (bg_inat_in %in% missing_inputs) paste0(
         "\nThe iNaturalist background comes from scripts/08 with ",
         "RUN_CLEANING <- TRUE (task 14.2, process choice w2)."),
       call. = FALSE)
}

# 4) The fields and the CRS of the three layers.
f_obs  <- sdm_read_fields(obscured_in)
f_bg   <- sdm_read_fields(bg_clean_in)
f_inat <- sdm_read_fields(bg_inat_in)
n_lyr <- sdm_run_guards(list(
  "the obscured layer must have the fields of scripts/08 STEP 13.2" =
    all(FIELDS_OBSCURED %in% f_obs$fields),
  "the clean background layer must have the fields of scripts/08 STEP 13.3 (with datasetKey)" =
    all(FIELDS_BG_CLEAN %in% f_bg$fields),
  "the iNaturalist background layer must have the fields of scripts/08 STEP 13.3" =
    all(FIELDS_BG_INAT %in% f_inat$fields),
  "each layer must be in the analysis CRS" =
    identical(c(f_obs$epsg, f_bg$epsg, f_inat$epsg),
              rep(as.integer(CRS_ANALYSIS), 3))
), what = "the layers (fields and CRS)")

# 5) The layers must give the counts of tbl_15_occ_sets.csv (a stale layer or
#    table stops the run). The counts are compared, not printed.
sets_tbl <- utils::read.csv(sets_tbl_in, stringsAsFactors = FALSE)
set_val <- function(set, subset, col) {
  v <- sets_tbl[[col]][sets_tbl$set == set & sets_tbl$subset == subset]
  if (length(v) != 1L) {
    stop("tbl_15_occ_sets.csv has no single row for ", set, " / ", subset,
         ".", call. = FALSE)
  }
  v
}
obs_d  <- sf::st_drop_geometry(sf::st_read(obscured_in, quiet = TRUE))
bg_d   <- sf::st_drop_geometry(sf::st_read(bg_clean_in, quiet = TRUE))
inat_d <- sf::st_drop_geometry(sf::st_read(bg_inat_in, quiet = TRUE))

inat_a <- inat_d$part == "obscured"
inat_b <- inat_d$part == "uncert"
bg_b   <- bg_d$datasetKey == SDM_BG_DATASET_KEY &
  bg_d$uncert_set %in% SDM_BG_UNCERT_SETS

n_cnt <- sdm_run_guards(list(
  "tbl_15_occ_sets.csv: the tiger 1 km row must hold OCC_POINT8_OUTCOME" =
    identical(set_val("tiger", "1km", "point8_outcome"), OCC_POINT8_OUTCOME),
  "the obscured layer must give the records of the tiger obscured row" =
    nrow(obs_d) == set_val("tiger", "obscured", "records"),
  "the obscured layer must give the 0.2 degree cells of the tiger obscured row" =
    sdm_n_cells(obs_d$cell02_lon_deg, obs_d$cell02_lat_deg) ==
      set_val("tiger", "obscured", "n_cells"),
  "each obscured record must be iNaturalist with an uncertainty >= OCC_OBSCURED_MIN_UNCERT_M" =
    all(obs_d$datasetKey == OCC_INAT_DATASET_KEY) &&
    all(obs_d$uncert_m >= OCC_OBSCURED_MIN_UNCERT_M),
  "the clean background layer must give the records and 1 km cells of the background 5km row" =
    nrow(bg_d) == set_val("background", "5km", "records") &&
    length(unique(bg_d$cell_1km)) == set_val("background", "5km", "n_cells"),
  "the iNaturalist background must hold the two parts only, of the iNaturalist dataset" =
    all(inat_a | inat_b) &&
    all(inat_d$datasetKey == SDM_BG_DATASET_KEY) &&
    !anyDuplicated(occ_id_chr(inat_d$gbifID)),
  "the obscured part must give the records and 0.2 degree cells of the background obscured row" =
    sum(inat_a) == set_val("background", "obscured", "records") &&
    sdm_n_cells(inat_d$cell02_lon_deg[inat_a], inat_d$cell02_lat_deg[inat_a]) ==
      set_val("background", "obscured", "n_cells"),
  "the uncert part must be the iNaturalist records of the clean background with uncert_set in SDM_BG_UNCERT_SETS" =
    setequal(occ_id_chr(inat_d$gbifID[inat_b]), occ_id_chr(bg_d$gbifID[bg_b])),
  "each record of the iNaturalist background must have a 0.2 degree cell" =
    !anyNA(inat_d$cell02_lon_deg) && !anyNA(inat_d$cell02_lat_deg)
), what = "the layers against tbl_15_occ_sets.csv")

# 6) The covariate stack: the analysis CRS, and the complete-case count of
#    tbl_10_covariate_stack_qa.csv (the Decision-10 common mask).
stack_r  <- terra::rast(stack_in)
stack_qa <- utils::read.csv(stack_qa_in, stringsAsFactors = FALSE)
n_cc     <- terra::global(terra::noNA(stack_r), "sum", na.rm = TRUE)[1, 1]
n_stk <- sdm_run_guards(list(
  "the stack must be in the analysis CRS" =
    identical(as.character(terra::crs(stack_r, describe = TRUE)$code),
              as.character(CRS_ANALYSIS)),
  "the stack must have one band per row of tbl_10_covariate_stack_qa.csv" =
    terra::nlyr(stack_r) == nrow(stack_qa),
  "tbl_10_covariate_stack_qa.csv must give one complete-case count" =
    length(unique(stack_qa$n_valid)) == 1L,
  "the complete-case cells of the stack must be the count of tbl_10" =
    isTRUE(n_cc == stack_qa$n_valid[1])
), what = "the covariate stack")

n_cc_stack <- n_cc
rm(bg_d, inat_a, inat_b, bg_b, n_cc)

rule(paste0("09_model_suitability.R — guards passed (",
            n_cfg + n_lyr + n_cnt + n_stk, " checks); CRS OK",
            "\nSDM_GRAIN_OUTCOME = ",
            if (is.na(SDM_GRAIN_OUTCOME)) "NA" else SDM_GRAIN_OUTCOME,
            if (is.na(SDM_GRAIN_OUTCOME))
              " -> STEP 14.1 (task 14.4) is the next STEP." else ""))

# =============================================================================
# STEP 14.1 — the 0.2 degree cells, the model cells and the counts (task 14.4)
# =============================================================================
# Decision 23 points 2 to 6; process choices g1, k1, h1, t1, l1.
#   1. the hand-made case (sdm_self_test()); a failed check stops the run
#   2. the grid (RUN_GRID = TRUE: built and written; FALSE: read and checked):
#      the 0.2 degree cell of each complete-case 1 km centre, the cover share
#      of each cell, the model cells (share >= SDM_CELL_MIN_COVER)
#   3. the presence cells: the 0.2 degree cells of the obscured set on model
#      cells (Decision 23 points 2 and 3)
#   4. the background cells: the cells of the two parts of the iNaturalist
#      background on model cells (point 5)
#   5. the outcome of points 4 and 6; the table tbl_16_sdm_counts.csv
#   6. the lock (l1): NA -> the outcome is stated and the script stops here;
#      set -> a run with another outcome stops before any write
# Console text: counts and names only.

rule("STEP 14.1 — the 0.2 degree cells, the model cells and the counts (task 14.4)")
t_step <- Sys.time()

# ---- 1. The hand-made case (h1) -------------------------------------------------
st <- sdm_self_test()
cat("hand-made case:", sum(st$pass), "of", nrow(st), "checks pass.\n")
if (!all(st$pass)) {
  stop("The hand-made case failed:\n  ",
       paste(st$check[!st$pass], collapse = "\n  "), call. = FALSE)
}

# ---- 2. The grid (g1, k1) --------------------------------------------------------
if (RUN_GRID) {
  centres <- sdm_centre_cells(stack_r, SDM_GRAIN_DEG)
  grid_sf <- sdm_build_grid(centres, SDM_GRAIN_DEG,
                            min_cover = SDM_CELL_MIN_COVER)
  cellid_r <- sdm_cellid_rast(stack_r, centres)
  stopifnot(
    "each complete-case 1 km cell must have a 0.2 degree cell" =
      nrow(centres) == n_cc_stack,
    "the centres of the grid must add up to the complete-case cells" =
      sum(grid_sf$n_cc) == n_cc_stack,
    "each grid cell must have an area above 0" = all(grid_sf$area_km2 > 0)
  )
  write_processed_vec(grid_sf, grid_out, dir = DIR_PROCESSED)
  write_processed_rast(cellid_r, cellid_out, dir = DIR_PROCESSED,
                       datatype = "INT4S")
  back <- sf::st_drop_geometry(sf::st_read(file.path(DIR_PROCESSED, grid_out),
                                           quiet = TRUE))
  if (nrow(back) != nrow(grid_sf) || !setequal(back$id, grid_sf$id) ||
      sum(back$model) != sum(grid_sf$model)) {
    stop("Read-back check failed for ", grid_out, ".", call. = FALSE)
  }
  rm(centres, cellid_r, back)
}
grid_sf  <- sf::st_read(file.path(DIR_PROCESSED, grid_out), quiet = TRUE)
grid_d   <- sf::st_drop_geometry(grid_sf)
cellid_r <- terra::rast(file.path(DIR_PROCESSED, cellid_out))
n_cid    <- terra::global(!is.na(cellid_r), "sum", na.rm = TRUE)[1, 1]
id_tab   <- terra::freq(cellid_r)
sdm_run_guards(list(
  "the cell-id raster must have the grid of the stack" =
    isTRUE(terra::compareGeom(cellid_r, stack_r, stopOnError = FALSE)),
  "the cell-id raster must have a value on each complete-case cell only" =
    isTRUE(n_cid == n_cc_stack),
  "the grid must hold each id of the cell-id raster, with its count" =
    setequal(id_tab$value, grid_d$id) &&
    all(id_tab$count == grid_d$n_cc[match(id_tab$value, grid_d$id)]),
  "the model flag must be share >= SDM_CELL_MIN_COVER" =
    identical(as.logical(grid_d$model),
              grid_d$share >= SDM_CELL_MIN_COVER)
), what = "the grid of STEP 14.1")
rm(id_tab)
cat("grid: cells with complete-case centres", nrow(grid_d), "| model cells",
    sum(grid_d$model), "\n")

# ---- 3.-5. Presence cells, background cells, outcome, table ------------------------
pres_idx <- sdm_cell_index(obs_d$cell02_lon_deg, obs_d$cell02_lat_deg)
pres_id  <- sdm_cell_id(pres_idx$ix, pres_idx$iy)
bg_idx   <- sdm_cell_index(inat_d$cell02_lon_deg, inat_d$cell02_lat_deg)
bg_id    <- sdm_cell_id(bg_idx$ix, bg_idx$iy)
cnt <- sdm_count_cells(grid_d, pres_id = pres_id, bg_id = bg_id,
                       bg_part = inat_d$part, n_cc_all = n_cc_stack)
rm(pres_idx, bg_idx, pres_id, bg_id)

cat("\n--- counts (Decision 23 points 3 to 6) ---\n")
show <- cnt$table
show$value <- vapply(show$value, function(v) {
  if (v == round(v)) formatC(v, format = "d", big.mark = ",") else
    sprintf("%.2f", v)
}, character(1))
print(show[, c("group", "item", "value")], row.names = FALSE)

cat("\nDecision 23 point 4: presence cells on model cells =", cnt$n_presence,
    "(limits", SDM_MIN_CELLS, "and", SDM_MIN_CELLS_FULL, ")\n")
cat("Decision 23 point 6: background cells on model cells =",
    cnt$n_background, "(minimum", SDM_BG_MIN_RATIO, "x", cnt$n_presence, "=",
    SDM_BG_MIN_RATIO * cnt$n_presence, ")\n")
cat("outcome:", cnt$outcome, "\n")

# ---- 6. The lock (l1) -------------------------------------------------------------
if (!is.na(SDM_GRAIN_OUTCOME) && !identical(cnt$outcome, SDM_GRAIN_OUTCOME)) {
  stop("The outcome of this run (", cnt$outcome, ") is not the recorded ",
       "outcome SDM_GRAIN_OUTCOME (", SDM_GRAIN_OUTCOME, "). Nothing of the ",
       "table is written. Find the cause; do not change the lock to pass.",
       call. = FALSE)
}
occ_assert_counts_only(cnt$table, cols = names(cnt$table),
                       count_cols = "value", name = "tbl_16_sdm_counts.csv")
write_table(cnt$table, nn = 16, slug = "sdm_counts")

if (is.na(SDM_GRAIN_OUTCOME)) {
  rule(paste0("STEP 14.1 complete (", round(as.numeric(difftime(
    Sys.time(), t_step, units = "mins")), 1), " min) — STOP POINT.\n",
    "Outcome of Decision 23 points 4 and 6: ", cnt$outcome, ".\n",
    "Record it in docs/methodology.md (Decision 23), then set ",
    "SDM_GRAIN_OUTCOME <- \"", cnt$outcome, "\" in R/00_config.R.\n",
    "Nothing after STEP 14.1 runs while the lock is NA."))
} else {
  rule(paste0("STEP 14.1 complete (", round(as.numeric(difftime(
    Sys.time(), t_step, units = "mins")), 1), " min): outcome = the ",
    "recorded outcome (", SDM_GRAIN_OUTCOME, ")."))
}

# =============================================================================
# STEP 14.2 — covariates, collinearity, AICc, main model, cross-validation,
#             sensitivity runs, model file (task 14.5; Decision 24)
# =============================================================================
# Decision 24 points 1-7, 10 and 11; process choices q1, t1, y1, h1, w1. Runs
# only with SDM_GRAIN_OUTCOME "reduced_model" or "planned_model".
#   1. maxnet 0.1.4; the hand-made case (sdm_self_test_142())
#   2. the covariate table of the model cells (RUN_COVARIATES = TRUE: built
#      and written; FALSE: read and checked)
#   3. the collinearity rule -> tbl_16_sdm_covariates.csv,
#      tbl_16_sdm_covariate_cor.csv
#   4. the data rows: the presence and background cells of STEP 14.1
#   5. the AICc grid and the selection -> tbl_16_sdm_aicc.csv
#   6. the main model (the selected fit of the grid); its training AUC
#   7. the block cross-validation -> tbl_16_sdm_cv.csv
#   8. the two sensitivity runs -> tbl_16_sdm_sensitivity.csv
#   9. the model file (data/processed/, gitignored) and its check
# The data rows are not written to any file. Console text and tables: counts
# and statistics only (no cell id, no corner).

if (SDM_GRAIN_OUTCOME %in% c("reduced_model", "planned_model")) {

rule("STEP 14.2 — covariates, AICc, main model, cross-validation, sensitivity runs (task 14.5)")
t_step2 <- Sys.time()

# ---- 1. maxnet and the hand-made case (h1) -------------------------------------
if (!requireNamespace("maxnet", quietly = TRUE) ||
    as.character(utils::packageVersion("maxnet")) != "0.1.4") {
  stop("STEP 14.2 needs maxnet 0.1.4 (renv::install(\"maxnet\")).",
       call. = FALSE)
}
st2 <- sdm_self_test_142()
cat("hand-made case of STEP 14.2:", sum(st2$pass), "of", nrow(st2),
    "checks pass.\n")
if (!all(st2$pass)) {
  stop("The hand-made case of STEP 14.2 failed:\n  ",
       paste(st2$check[!st2$pass], collapse = "\n  "), call. = FALSE)
}

# ---- 2. Covariates of the model cells (q1, w1) ----------------------------------
model_ids <- grid_d$id[grid_d$model]
cov_path  <- file.path(DIR_PROCESSED, cov_out)
if (RUN_COVARIATES) {
  settl_r <- terra::rast(settl_in)
  if (!isTRUE(terra::compareGeom(settl_r, stack_r, stopOnError = FALSE))) {
    stop("The settlement surface does not have the grid of the stack.",
         call. = FALSE)
  }
  cov_new <- sdm_covariates(stack_r, cellid_r, model_ids, settl_r)
  utils::write.csv(cov_new, cov_path, row.names = FALSE)
  back <- utils::read.csv(cov_path)
  if (nrow(back) != nrow(cov_new) || !identical(back$id, cov_new$id) ||
      !isTRUE(all.equal(back[, SDM_COVARIATES], cov_new[, SDM_COVARIATES],
                        tolerance = 1e-12, check.attributes = FALSE))) {
    stop("Read-back check failed for ", cov_out, ".", call. = FALSE)
  }
  message("Wrote ", cov_path, " (", nrow(cov_new), " model cells)")
  rm(settl_r, cov_new, back)
}
cov <- utils::read.csv(cov_path)
sdm_run_guards(list(
  "the covariate table must hold each model cell once" =
    setequal(cov$id, model_ids) && !anyDuplicated(cov$id),
  "the covariate table must hold the nine candidates and settl_mean" =
    all(c(SDM_COVARIATES, "settl_mean") %in% names(cov)),
  "no covariate may be NA or below 0" =
    !anyNA(cov[, c(SDM_COVARIATES, "settl_mean")]) &&
    all(cov[, c(SDM_COVARIATES, "settl_mean")] >= 0),
  "each share must be 1 or below" =
    all(cov[, names(SDM_LC_GROUPS)] <= 1 + 1e-9),
  "the complete-case cells of the table must be the count of STEP 14.1" =
    sum(cov$n_cc) == sum(grid_d$n_cc[grid_d$model])
), what = "the covariate table")
cov <- cov[order(cov$id), ]
rownames(cov) <- NULL

# ---- 3. Collinearity (Decision 24 point 3) --------------------------------------
sel  <- sdm_select_covariates(cov, SDM_COV_PRIORITY, SDM_COR_MAX)
covs <- sel$kept
terrain_cov <- paste0(SDM_TERRAIN_BANDS, "_mean")
cov_tbl <- data.frame(
  covariate = c(SDM_COV_PRIORITY, "settl_mean"),
  role = c(rep("candidate", length(SDM_COV_PRIORITY)), "bias_run"),
  kept = c(SDM_COV_PRIORITY %in% covs, NA),
  stringsAsFactors = FALSE
)
cov_tbl$min  <- vapply(cov_tbl$covariate, function(v) min(cov[[v]]), 1)
cov_tbl$mean <- vapply(cov_tbl$covariate, function(v) mean(cov[[v]]), 1)
cov_tbl$max  <- vapply(cov_tbl$covariate, function(v) max(cov[[v]]), 1)
cov_tbl$z1_water_1km_cells <- ifelse(cov_tbl$covariate %in% terrain_cov,
                                     sum(cov$z1_water_excl), 0)
cov_tbl$z1_floored_1km_cells <- ifelse(cov_tbl$covariate == "elev_mean",
                                       sum(cov$z1_elev_floored), 0)
cov_tbl$z1_water_only_cells <- ifelse(cov_tbl$covariate %in% terrain_cov,
                                      sum(cov$water_only), 0)
rownames(cov_tbl) <- NULL
cat("\n--- covariates (Decision 24 points 1 to 3; over the", nrow(cov),
    "model cells) ---\n")
print(cov_tbl, row.names = FALSE, digits = 4)
cat("\nkept (|r| <=", SDM_COR_MAX, "):", paste(covs, collapse = ", "), "\n")
cat("pairs with |r| >", SDM_COR_MAX, ":\n")
print(sel$cor[sel$cor$above_limit, ], row.names = FALSE, digits = 3)

# ---- 4. The data rows (presence and background cells of STEP 14.1) --------------
pres_all <- sdm_cell_id(sdm_cell_index(obs_d$cell02_lon_deg,
                                       obs_d$cell02_lat_deg)$ix,
                        sdm_cell_index(obs_d$cell02_lon_deg,
                                       obs_d$cell02_lat_deg)$iy)
bg_all <- sdm_cell_id(sdm_cell_index(inat_d$cell02_lon_deg,
                                     inat_d$cell02_lat_deg)$ix,
                      sdm_cell_index(inat_d$cell02_lon_deg,
                                     inat_d$cell02_lat_deg)$iy)
pres_id <- sort(unique(pres_all[pres_all %in% model_ids]))
bg_id   <- sort(unique(bg_all[bg_all %in% model_ids]))
if (length(pres_id) != cnt$n_presence || length(bg_id) != cnt$n_background) {
  stop("The presence or background cells differ from the counts of STEP ",
       "14.1.", call. = FALSE)
}
dat <- rbind(cov[match(pres_id, cov$id), covs, drop = FALSE],
             cov[match(bg_id, cov$id), covs, drop = FALSE])
p <- c(rep(1, length(pres_id)), rep(0, length(bg_id)))
rownames(dat) <- NULL
all_data <- cov[, covs, drop = FALSE]
pres_idx <- match(pres_id, cov$id)

# ---- 5. The AICc grid and the selection (Decision 24 point 4) --------------------
fc_grid <- if (SDM_GRAIN_OUTCOME == "reduced_model") {
  intersect(SDM_FC_GRID, SDM_REDUCED_MAX_CLASSES)   # Decision 23 point 4
} else SDM_FC_GRID
grid_fit <- sdm_aicc_grid(p, dat, all_data, pres_idx, fc_grid,
                          SDM_REGMULT_GRID)
aicc_tbl <- sdm_select_aicc(grid_fit$table, SDM_AICC_DELTA)
sel_row  <- aicc_tbl[aicc_tbl$selected, ]
sel_fc   <- sel_row$classes
sel_rm   <- sel_row$regmult
fit_main <- grid_fit$fits[[paste0(sel_fc, "_", sel_rm)]]
cat("\n--- AICc grid (Decision 24 point 4; n =", length(pres_id),
    "presence cells) ---\n")
print(aicc_tbl, row.names = FALSE, digits = 6)
cat("\nselected:", sel_fc, "with regmult", sel_rm, "|", sel_row$k,
    "coefficients\n")

# ---- 6. The main model -----------------------------------------------------------
pred_main <- sdm_predict(fit_main, all_data, SDM_EVAL_TYPE)
auc_train_main <- sdm_auc(pred_main[pres_idx],
                          pred_main[match(bg_id, cov$id)])

# ---- 7. Block cross-validation (Decision 24 point 7) -----------------------------
cells <- data.frame(id = sort(union(pres_id, bg_id)))
cells$is_pres <- cells$id %in% pres_id
cells$is_bg   <- cells$id %in% bg_id
block_cells <- as.integer(round(SDM_CV_BLOCK_DEG / SDM_GRAIN_DEG))
cv_res <- sdm_cv(cells, cov, covs, sel_fc, sel_rm, SDM_CV_K, block_cells,
                 SDM_EVAL_TYPE)
folds <- cv_res$folds
ok_f  <- folds$status == "fitted"
metric_cols <- c("boyce", "auc_test", "or10", "auc_train", "auc_diff")
summ <- function(fun, label) {
  r <- folds[1, ]
  r[] <- NA
  r$fold <- label
  r$status <- paste0(sum(ok_f), " of ", nrow(folds), " folds")
  for (m in metric_cols) r[[m]] <- fun(folds[[m]][ok_f], na.rm = TRUE)
  r
}
main_row <- folds[1, ]
main_row[] <- NA
main_row$fold <- "main"
main_row$status <- "fitted"
main_row$train_presence_cells <- length(pres_id)
main_row$auc_train <- auc_train_main
cv_tbl <- rbind(folds, summ(mean, "mean"), summ(stats::sd, "sd"), main_row)
rownames(cv_tbl) <- NULL
cat("\n--- block cross-validation (Decision 24 point 7;", SDM_CV_BLOCK_DEG,
    "degree blocks,", SDM_CV_K, "folds,", SDM_EVAL_TYPE, ") ---\n")
print(cv_tbl, row.names = FALSE, digits = 3)

# ---- 8. Sensitivity runs (Decision 24 point 10) ----------------------------------
sens_row <- function(run, status, n_p, n_b, fc = NA_character_,
                     rmv = NA_real_, cmp = NULL) {
  data.frame(run = run, status = status, presence_cells = n_p,
             background_cells = n_b, classes = fc, regmult = rmv,
             rho = if (is.null(cmp)) NA_real_ else cmp$rho,
             top_overlap = if (is.null(cmp)) NA_real_ else cmp$top_overlap,
             label = if (is.null(cmp)) NA_character_ else cmp$label,
             stringsAsFactors = FALSE)
}
sens <- list()
# 8a. bias_settlement (b2): settl_mean as a bias covariate, fixed at its
#     median over the model cells at prediction; point 3 does not apply.
covs_b <- c(covs, "settl_mean")
dat_b <- rbind(cov[match(pres_id, cov$id), covs_b, drop = FALSE],
               cov[match(bg_id, cov$id), covs_b, drop = FALSE])
rownames(dat_b) <- NULL
fit_b <- tryCatch(sdm_fit(p, dat_b, sel_fc, sel_rm), error = function(e) e)
if (inherits(fit_b, "error")) {
  sens[["bias_settlement"]] <- sens_row("bias_settlement", "failed",
                                        length(pres_id), length(bg_id),
                                        sel_fc, sel_rm)
} else {
  all_b <- cov[, covs_b, drop = FALSE]
  all_b$settl_mean <- stats::median(cov$settl_mean)
  pred_b <- sdm_predict(fit_b, all_b, SDM_EVAL_TYPE)
  sens[["bias_settlement"]] <- sens_row(
    "bias_settlement", "run", length(pres_id), length(bg_id), sel_fc, sel_rm,
    sdm_compare(pred_main, pred_b, cov$id))
}
# 8b. window_2018_2022: the records of SDM_SENS_WINDOW only; the limits of
#     Decision 23 points 4 and 6 apply; 25-79 presence cells -> lq at most.
in_w <- function(y) !is.na(y) & y >= SDM_SENS_WINDOW[1] &
  y <= SDM_SENS_WINDOW[2]
pres_w <- sort(unique(pres_all[in_w(obs_d$year) & pres_all %in% model_ids]))
bg_w   <- sort(unique(bg_all[in_w(inat_d$year) & bg_all %in% model_ids]))
out_w  <- sdm_outcome(length(pres_w), length(bg_w))
if (out_w %in% c("no_model_presence", "no_model_background")) {
  sens[["window_2018_2022"]] <- sens_row("window_2018_2022",
                                         paste("not run:", out_w),
                                         length(pres_w), length(bg_w))
} else {
  fc_w <- if (out_w == "reduced_model") SDM_REDUCED_MAX_CLASSES else sel_fc
  dat_w <- rbind(cov[match(pres_w, cov$id), covs, drop = FALSE],
                 cov[match(bg_w, cov$id), covs, drop = FALSE])
  rownames(dat_w) <- NULL
  p_w <- c(rep(1, length(pres_w)), rep(0, length(bg_w)))
  fit_w <- tryCatch(sdm_fit(p_w, dat_w, fc_w, sel_rm), error = function(e) e)
  if (inherits(fit_w, "error")) {
    sens[["window_2018_2022"]] <- sens_row("window_2018_2022", "failed",
                                           length(pres_w), length(bg_w),
                                           fc_w, sel_rm)
  } else {
    pred_w <- sdm_predict(fit_w, all_data, SDM_EVAL_TYPE)
    sens[["window_2018_2022"]] <- sens_row(
      "window_2018_2022", "run", length(pres_w), length(bg_w), fc_w, sel_rm,
      sdm_compare(pred_main, pred_w, cov$id))
  }
}
sens_tbl <- do.call(rbind, sens)
rownames(sens_tbl) <- NULL
cat("\n--- sensitivity runs (Decision 24 point 10; robust if rho >= ",
    SDM_SENS_RHO_MIN, " and top-", SDM_SENS_TOP_SHARE * 100,
    "% overlap >= ", round(SDM_SENS_OVERLAP_MIN, 3), ") ---\n", sep = "")
print(sens_tbl, row.names = FALSE, digits = 3)

# ---- Tables (t1; statistics only) ------------------------------------------------
occ_assert_counts_only(cov_tbl, cols = names(cov_tbl),
                       count_cols = c("min", "mean", "max",
                                      "z1_water_1km_cells",
                                      "z1_floored_1km_cells",
                                      "z1_water_only_cells"),
                       name = "tbl_16_sdm_covariates.csv")
occ_assert_counts_only(sel$cor, cols = names(sel$cor), count_cols = character(0),
                       name = "tbl_16_sdm_covariate_cor.csv")
occ_assert_counts_only(aicc_tbl, cols = names(aicc_tbl),
                       count_cols = character(0),
                       name = "tbl_16_sdm_aicc.csv")
occ_assert_counts_only(cv_tbl, cols = names(cv_tbl), count_cols = character(0),
                       name = "tbl_16_sdm_cv.csv")
occ_assert_counts_only(sens_tbl, cols = names(sens_tbl),
                       count_cols = c("presence_cells", "background_cells"),
                       name = "tbl_16_sdm_sensitivity.csv")
write_table(cov_tbl,  nn = 16, slug = "sdm_covariates")
write_table(sel$cor,  nn = 16, slug = "sdm_covariate_cor")
write_table(aicc_tbl, nn = 16, slug = "sdm_aicc")
write_table(cv_tbl,   nn = 16, slug = "sdm_cv")
write_table(sens_tbl, nn = 16, slug = "sdm_sensitivity")

# ---- 9. The model file (Decision 24 point 11) ------------------------------------
model_obj <- list(
  model = fit_main,
  settings = list(decision = "Decision 24", outcome = SDM_GRAIN_OUTCOME,
                  covariates = covs, classes = sel_fc, regmult = sel_rm,
                  aicc = aicc_tbl, eval_type = SDM_EVAL_TYPE,
                  n_presence_cells = length(pres_id),
                  n_background_cells = length(bg_id)),
  versions = list(maxnet = as.character(utils::packageVersion("maxnet")),
                  glmnet = as.character(utils::packageVersion("glmnet")),
                  R = R.version.string)
)
if (!sdm_object_ok(model_obj, n_min = length(p))) {
  stop("The model object has a part with the length of the data rows ",
       "(Decision 24 point 11). Nothing is saved.", call. = FALSE)
}
model_path <- save_model(model_obj, SDM_MODEL_NAME[["species"]],
                         SDM_MODEL_NAME[["model"]], dir = SDM_MODEL_DIR)
back_obj <- readRDS(model_path)
if (!identical(back_obj$model$betas, fit_main$betas)) {
  stop("Read-back check failed for the model file.", call. = FALSE)
}
rm(back_obj)

rule(paste0(
  "STEP 14.2 complete (", round(as.numeric(difftime(Sys.time(), t_step2,
                                                  units = "mins")), 1),
  " min).\nCovariates kept: ", paste(covs, collapse = ", "), "\n",
  "Selected: ", sel_fc, ", regmult ", sel_rm, " (", sel_row$k,
  " coefficients)\n",
  "Cross-validation: mean test Boyce ", round(mean(folds$boyce[ok_f]), 3),
  " | mean test AUC ", round(mean(folds$auc_test[ok_f]), 3),
  " | mean OR10 ", round(mean(folds$or10[ok_f]), 3), "\n",
  "Gate of Decision 24 point 8 (applied in Week 15): mean test Boyce ",
  if (isTRUE(mean(folds$boyce[ok_f]) > SDM_BOYCE_GATE)) "above" else
    "at or below", " ", SDM_BOYCE_GATE, ".\n",
  "Sensitivity: ", paste(sens_tbl$run, ifelse(is.na(sens_tbl$label),
                                               sens_tbl$status,
                                               sens_tbl$label),
                         sep = " = ", collapse = " | "), "\n",
  "Model file under data/processed/ (gitignored)."))

}  # end if (SDM_GRAIN_OUTCOME is a model outcome), STEP 14.2

# =============================================================================
# STEP 14.3 — QA (task 14.6; Decisions 23 and 24)
# =============================================================================
# Process choices of task 14.6 (2026-10-25): c1 a second path for the main
# numbers (no sdm_* function of STEPs 14.1 and 14.2: the sdm_qa_* functions);
# m1 the model file of this run (the path that save_model() gave), other
# dated model files counted only; h1 the hand-made cases of STEPs 14.1 to
# 14.3 as rows of the table; p1 the publish checks (a) to (d); s1 the
# small-count rule of Decision 22 point 9 is for counts by reserve: no tbl_16
# table may hold a reserve column or a reserve name.
# As STEP 13.5 of scripts/08: the step reads its inputs from disk (not the
# objects of STEP 14.2), runs in each run after STEP 14.2, and writes
# tbl_16_sdm_qa.csv (group, check, value, pass) first; then any FALSE stops
# the script. Groups: "test case", "presence", "background", "grid",
# "covariates", "model", "cv", "sensitivity", "publish".
# Console text: counts, names and statistics only.

if (SDM_GRAIN_OUTCOME %in% c("reduced_model", "planned_model")) {

rule("STEP 14.3 — QA (task 14.6; Decisions 23 and 24)")
t_step3 <- Sys.time()
for (v in c("SDM_QA_REL_TOL", "SDM_QA_DEG_TOL")) {
  if (!exists(v)) {
    stop(v, " is missing from R/00_config.R (task 14.6).", call. = FALSE)
  }
}
for (f in c(reserves_in, gitignore_in)) {
  if (!file.exists(f)) stop("STEP 14.3 needs ", f, ".", call. = FALSE)
}

qa <- list()
add_qa <- function(group, check, value, pass) {
  qa[[length(qa) + 1L]] <<- data.frame(group = group, check = check,
                                       value = as.character(value),
                                       pass = isTRUE(pass),
                                       stringsAsFactors = FALSE)
  invisible(NULL)
}
agree  <- function(d) isTRUE(d <= SDM_QA_REL_TOL)
diff_txt <- function(d) sprintf("largest relative difference %.2e", d)
n_fail_txt <- function(n, of) sprintf("%d of %d records fail", n, of)
same_txt <- function(a, b) paste0(paste(a, collapse = ", "), "; table ",
                                  paste(b, collapse = ", "))

# ---- 1. Hand-made cases (h1) ------------------------------------------------------
tests <- list("STEP 14.1" = sdm_self_test(),
              "STEP 14.2" = sdm_self_test_142(),
              "STEP 14.3" = sdm_self_test_143())
for (s in names(tests)) {
  tt <- tests[[s]]
  for (i in seq_len(nrow(tt))) {
    add_qa("test case", paste0(s, ": ", tt$check[i]),
           if (tt$pass[i]) "pass" else "FAIL", tt$pass[i])
  }
}
cat("hand-made cases:", paste(vapply(names(tests), function(s)
  paste0(s, " ", sum(tests[[s]]$pass), " of ", nrow(tests[[s]])),
  character(1)), collapse = " | "), "\n")

# ---- 2. Inputs (files on disk) ------------------------------------------------------
obs_q  <- sf::st_read(obscured_in, quiet = TRUE)
inat_q <- sf::st_read(bg_inat_in, quiet = TRUE)
od_q   <- sf::st_drop_geometry(obs_q)
id_q   <- sf::st_drop_geometry(inat_q)
grid_q <- sf::st_drop_geometry(sf::st_read(file.path(DIR_PROCESSED, grid_out),
                                           quiet = TRUE))
cid_q  <- terra::rast(file.path(DIR_PROCESSED, cellid_out))
stk_q  <- terra::rast(stack_in)
stl_q  <- terra::rast(settl_in)
cov_q  <- utils::read.csv(cov_path)
cov_q  <- cov_q[order(cov_q$id), ]
rownames(cov_q) <- NULL
tb16 <- function(slug) {
  f <- file.path(DIR_TABLES, paste0("tbl_16_", slug, ".csv"))
  if (!file.exists(f)) stop("Table not found: ", f, call. = FALSE)
  utils::read.csv(f, stringsAsFactors = FALSE)
}
t_cnt <- tb16("sdm_counts")
t_cov <- tb16("sdm_covariates")
t_cor <- tb16("sdm_covariate_cor")
t_aic <- tb16("sdm_aicc")
t_cv  <- tb16("sdm_cv")
t_sen <- tb16("sdm_sensitivity")
cnt_v <- function(group, item) {
  v <- t_cnt$value[t_cnt$group == group & t_cnt$item == item]
  if (length(v) == 1L) v else NA_real_
}
n_cc_q <- utils::read.csv(stack_qa_in)$n_valid[1]
res_q  <- sf::st_drop_geometry(sf::st_read(reserves_in, quiet = TRUE))
if (!"unit_name" %in% names(res_q)) {
  stop("The reserve layer has no field unit_name.", call. = FALSE)
}
grid_key   <- paste(grid_q$ix, grid_q$iy, sep = "_")
model_keys <- grid_key[grid_q$model]
key_id     <- stats::setNames(grid_q$id, grid_key)

# ---- 3. Presences (Decision 23 points 2, 3, 7; "Consequences") -----------------------
n_o   <- nrow(od_q)
k_obs <- sdm_qa_key(od_q$cell02_lon_deg, od_q$cell02_lat_deg)
p_key <- sort(unique(k_obs[k_obs %in% model_keys]))
k <- sum(od_q$datasetKey != OCC_INAT_DATASET_KEY | is.na(od_q$datasetKey))
add_qa("presence", "each record is of the iNaturalist dataset (OCC_INAT_DATASET_KEY)",
       n_fail_txt(k, n_o), k == 0)
k <- sum(is.na(od_q$uncert_m) | od_q$uncert_m < OCC_OBSCURED_MIN_UNCERT_M)
add_qa("presence", "each record has an uncertainty of OCC_OBSCURED_MIN_UNCERT_M or more",
       n_fail_txt(k, n_o), k == 0)
k <- sum(od_q$datasetKey %in% SDM_CHECK_ABSENT_DATASETS)
add_qa("presence", "Decision 23 point 7 (e1): no record of SDM_CHECK_ABSENT_DATASETS",
       sprintf("%d records", k), k == 0)
k <- sdm_qa_corner_fail(obs_q, od_q$cell02_lon_deg, od_q$cell02_lat_deg)
add_qa("presence", "each point is in the 0.2 degree cell of its stored corner",
       n_fail_txt(k, n_o), k == 0)
add_qa("presence", "records = tbl_16_sdm_counts (presence, records)",
       same_txt(n_o, cnt_v("presence", "records")),
       n_o == cnt_v("presence", "records"))
add_qa("presence", "cells and cells on model cells, counted again = tbl_16_sdm_counts",
       same_txt(c(length(unique(k_obs)), length(p_key)),
                c(cnt_v("presence", "cells_all"),
                  cnt_v("presence", "cells_model"))),
       length(unique(k_obs)) == cnt_v("presence", "cells_all") &&
         length(p_key) == cnt_v("presence", "cells_model"))

# ---- 4. Background (Decision 23 points 5 to 7) ------------------------------------------
n_b0  <- nrow(id_q)
k_bg  <- sdm_qa_key(id_q$cell02_lon_deg, id_q$cell02_lat_deg)
b_key <- sort(unique(k_bg[k_bg %in% model_keys]))
k <- sum(id_q$datasetKey != SDM_BG_DATASET_KEY | is.na(id_q$datasetKey))
add_qa("background", "each record is of the iNaturalist dataset (SDM_BG_DATASET_KEY)",
       n_fail_txt(k, n_b0), k == 0)
k <- sum(id_q$datasetKey %in% SDM_CHECK_ABSENT_DATASETS)
add_qa("background", "Decision 23 point 7 (e1): no record of SDM_CHECK_ABSENT_DATASETS",
       sprintf("%d records", k), k == 0)
k <- sdm_qa_corner_fail(inat_q, id_q$cell02_lon_deg, id_q$cell02_lat_deg)
add_qa("background", "each point is in the 0.2 degree cell of its stored corner",
       n_fail_txt(k, n_b0), k == 0)
n_pa <- sum(id_q$part == "obscured")
n_pb <- sum(id_q$part == "uncert")
add_qa("background", "records of the two parts = tbl_16_sdm_counts",
       same_txt(c(n_pa, n_pb), c(cnt_v("background", "obscured_records"),
                                 cnt_v("background", "uncert_records"))),
       n_pa + n_pb == n_b0 && n_pa == cnt_v("background", "obscured_records") &&
         n_pb == cnt_v("background", "uncert_records"))
n_both <- length(intersect(b_key, p_key))
add_qa("background", "cells on model cells and cells with a presence, counted again = tbl_16_sdm_counts",
       same_txt(c(length(b_key), n_both),
                c(cnt_v("background", "cells_model"),
                  cnt_v("background", "cells_model_with_presence"))),
       length(b_key) == cnt_v("background", "cells_model") &&
         n_both == cnt_v("background", "cells_model_with_presence"))
n_p_q <- length(p_key)
n_b_q <- length(b_key)
k <- n_b_q >= SDM_BG_MIN_RATIO * n_p_q && n_p_q >= SDM_MIN_CELLS
add_qa("background", "the counted cells give the recorded outcome (Decision 23 points 4 and 6)",
       sprintf("%d presence cells, %d background cells; outcome %s", n_p_q,
               n_b_q, SDM_GRAIN_OUTCOME),
       k && identical(SDM_GRAIN_OUTCOME,
                      if (n_p_q >= SDM_MIN_CELLS_FULL) "planned_model" else
                        "reduced_model"))

# ---- 5. The grid (Decision 23 point 3) ---------------------------------------------------
add_qa("grid", "the cell-id raster has the grid of the stack",
       "compareGeom", isTRUE(terra::compareGeom(cid_q, stk_q,
                                                stopOnError = FALSE)))
add_qa("grid", "grid cells and model cells = tbl_16_sdm_counts",
       same_txt(c(nrow(grid_q), sum(grid_q$model)),
                c(cnt_v("grid", "cells_with_complete_case_centres"),
                  cnt_v("grid", "model_cells"))),
       nrow(grid_q) == cnt_v("grid", "cells_with_complete_case_centres") &&
         sum(grid_q$model) == cnt_v("grid", "model_cells"))
add_qa("grid", "the centres of the grid = the complete-case cells of tbl_10 and tbl_16",
       same_txt(sum(grid_q$n_cc), c(n_cc_q,
                                    cnt_v("grid", "complete_case_1km_cells"))),
       sum(grid_q$n_cc) == n_cc_q &&
         n_cc_q == cnt_v("grid", "complete_case_1km_cells"))
add_qa("grid", "the model flag is share >= SDM_CELL_MIN_COVER",
       sprintf("%d of %d cells differ",
               sum(as.logical(grid_q$model) != (grid_q$share >=
                                                  SDM_CELL_MIN_COVER)),
               nrow(grid_q)),
       identical(as.logical(grid_q$model), grid_q$share >= SDM_CELL_MIN_COVER))
mids <- sort(grid_q$id[grid_q$model])
add_qa("grid", "the covariate table holds each model cell once, with the n_cc of the grid",
       sprintf("%d rows; %d model cells", nrow(cov_q), length(mids)),
       identical(as.numeric(cov_q$id), as.numeric(mids)) &&
         identical(as.numeric(cov_q$n_cc),
                   as.numeric(grid_q$n_cc[match(mids, grid_q$id)])))

# ---- 6. Covariates (Decision 24 points 1 to 3; the zonal path) ------------------------
zq <- sdm_qa_zonal(stk_q, cid_q, stl_q, mids)
for (v in c("n_cc", SDM_COVARIATES, "settl_mean", "z1_water_excl",
            "z1_elev_floored")) {
  d <- sdm_qa_diff(cov_q[[v]], zq[[v]])
  add_qa("covariates", paste0(v, ": the covariate table = terra::zonal()"),
         diff_txt(d), agree(d))
}
add_qa("covariates", "water_only: the covariate table = terra::zonal()",
       sprintf("%d and %d cells", sum(as.logical(cov_q$water_only)),
               sum(zq$water_only)),
       identical(as.logical(cov_q$water_only), as.logical(zq$water_only)))
rows_t <- match(c(SDM_COV_PRIORITY, "settl_mean"), t_cov$covariate)
d <- if (anyNA(rows_t)) Inf else max(vapply(c(SDM_COV_PRIORITY, "settl_mean"),
  function(v) {
    r <- t_cov[t_cov$covariate == v, ]
    sdm_qa_diff(c(r$min, r$mean, r$max),
                c(min(cov_q[[v]]), mean(cov_q[[v]]), max(cov_q[[v]])))
  }, numeric(1)))
add_qa("covariates", "tbl_16_sdm_covariates: min, mean and max = the covariate table",
       diff_txt(d), agree(d))
terr <- paste0(SDM_TERRAIN_BANDS, "_mean")
z_exp <- data.frame(
  w = ifelse(t_cov$covariate %in% terr, sum(cov_q$z1_water_excl), 0),
  f = ifelse(t_cov$covariate == "elev_mean", sum(cov_q$z1_elev_floored), 0),
  o = ifelse(t_cov$covariate %in% terr, sum(as.logical(cov_q$water_only)), 0))
add_qa("covariates", "tbl_16_sdm_covariates: the z1 counts = the covariate table",
       sprintf("%d water, %d floored, %d water-only", sum(cov_q$z1_water_excl),
               sum(cov_q$z1_elev_floored), sum(as.logical(cov_q$water_only))),
       all(t_cov$z1_water_1km_cells == z_exp$w) &&
         all(t_cov$z1_floored_1km_cells == z_exp$f) &&
         all(t_cov$z1_water_only_cells == z_exp$o))
kept_q <- sdm_qa_kept(cov_q, SDM_COV_PRIORITY, SDM_COR_MAX)
kept_t <- t_cov$covariate[t_cov$role == "candidate" & t_cov$kept %in% TRUE]
add_qa("covariates", "the collinearity rule again: the kept set = tbl_16_sdm_covariates",
       same_txt(length(kept_q), length(kept_t)), identical(kept_q, kept_t))
cm_q <- stats::cor(as.matrix(cov_q[, SDM_COV_PRIORITY]))
r_q <- cm_q[cbind(match(t_cor$var_a, SDM_COV_PRIORITY),
                  match(t_cor$var_b, SDM_COV_PRIORITY))]
d <- sdm_qa_diff(t_cor$r, r_q)
add_qa("covariates", "tbl_16_sdm_covariate_cor: one row per pair; r = cor() of the covariate table",
       paste0(nrow(t_cor), " pairs; ", diff_txt(d)),
       nrow(t_cor) == choose(length(SDM_COV_PRIORITY), 2) && agree(d))
add_qa("covariates", "tbl_16_sdm_covariate_cor: above_limit is |r| > SDM_COR_MAX",
       sprintf("%d pairs above", sum(t_cor$above_limit)),
       identical(as.logical(t_cor$above_limit), abs(t_cor$r) > SDM_COR_MAX))

# ---- 7. The model file (Decision 24 points 4, 6 and 11; m1) ------------------------------
mf_all <- list.files(SDM_MODEL_DIR, pattern = paste0(
  "^", SDM_MODEL_NAME[["species"]], "_", SDM_MODEL_NAME[["model"]],
  "_[0-9]{8}\\.rds$"))
add_qa("model", "the model file of this run is on disk (m1)",
       sprintf("%s; %d other dated model file(s)", basename(model_path),
               length(setdiff(mf_all, basename(model_path)))),
       file.exists(model_path) && basename(model_path) %in% mf_all)
mo <- readRDS(model_path)
add_qa("model", "the object holds model, settings and versions",
       paste(names(mo), collapse = ", "),
       identical(names(mo), c("model", "settings", "versions")))
n_rows_q <- n_p_q + n_b_q
lp <- sdm_qa_largest_part(mo)
add_qa("model", "Decision 24 point 11: no part has the length or the rows of the data rows",
       sprintf("largest part %d; data rows %d", as.integer(lp), n_rows_q),
       lp < n_rows_q)
sel_q <- t_aic[t_aic$selected %in% TRUE, ]
add_qa("model", "settings: the kept covariates, the selected classes and multiplier",
       paste0(length(mo$settings$covariates), " covariates; ",
              mo$settings$classes, ", regmult ", mo$settings$regmult),
       nrow(sel_q) == 1 && identical(mo$settings$covariates, kept_t) &&
         identical(mo$settings$classes, sel_q$classes) &&
         isTRUE(mo$settings$regmult == sel_q$regmult))
add_qa("model", "settings: the presence and background cells counted again",
       same_txt(c(mo$settings$n_presence_cells, mo$settings$n_background_cells),
                c(n_p_q, n_b_q)),
       isTRUE(mo$settings$n_presence_cells == n_p_q) &&
         isTRUE(mo$settings$n_background_cells == n_b_q))
add_qa("model", "versions: maxnet 0.1.4",
       paste0("maxnet ", mo$versions$maxnet, ", glmnet ", mo$versions$glmnet),
       identical(mo$versions$maxnet, "0.1.4"))
fit_q  <- mo$model
covs_q <- mo$settings$covariates
k_q    <- length(fit_q$betas)
pr_q   <- match(unname(key_id[p_key]), cov_q$id)
br_q   <- match(unname(key_id[b_key]), cov_q$id)
raw_q  <- as.numeric(stats::predict(fit_q, cov_q[, covs_q, drop = FALSE],
                                    type = "exponential", clamp = TRUE))
a_q    <- sdm_qa_aicc(raw_q, pr_q, k_q)
add_qa("model", "K of the model file = k of the selected row of tbl_16_sdm_aicc",
       same_txt(k_q, sel_q$k), nrow(sel_q) == 1 && k_q == sel_q$k)
d <- sdm_qa_diff(a_q, sel_q$aicc)
add_qa("model", "AICc again from the model file = the selected row of tbl_16_sdm_aicc",
       diff_txt(d), agree(d))
fc_q <- if (SDM_GRAIN_OUTCOME == "reduced_model") {
  intersect(SDM_FC_GRID, SDM_REDUCED_MAX_CLASSES)
} else SDM_FC_GRID
add_qa("model", "tbl_16_sdm_aicc: one row per model of the grid, each with a status",
       sprintf("%d rows; %d fitted with an AICc", nrow(t_aic),
               sum(t_aic$status == "fitted")),
       nrow(t_aic) == length(fc_q) * length(SDM_REGMULT_GRID) &&
         all(t_aic$status %in% c("fitted", "no_aicc", "failed")) &&
         identical(is.na(t_aic$aicc), t_aic$status != "fitted"))
d <- sdm_qa_diff(t_aic$delta_aicc, t_aic$aicc - min(t_aic$aicc, na.rm = TRUE))
r_sel <- sdm_qa_select(t_aic$aicc, t_aic$k, SDM_AICC_DELTA)
add_qa("model", "tbl_16_sdm_aicc: delta_aicc and the selection rule again",
       paste0("row ", r_sel, " selected again; ", diff_txt(d)),
       agree(d) && identical(which(t_aic$selected %in% TRUE), r_sel))
cl_q  <- as.numeric(stats::predict(fit_q, cov_q[, covs_q, drop = FALSE],
                                   type = SDM_EVAL_TYPE, clamp = TRUE))
auc_q <- sdm_qa_auc(cl_q[pr_q], cl_q[br_q])
main_q <- t_cv[t_cv$fold == "main", ]
d <- if (nrow(main_q) == 1) sdm_qa_diff(auc_q, main_q$auc_train) else Inf
add_qa("model", "training AUC again (Wilcoxon) = the row main of tbl_16_sdm_cv",
       diff_txt(d), agree(d) && isTRUE(main_q$train_presence_cells == n_p_q))
rm(raw_q, cl_q)

# ---- 8. Cross-validation (Decision 24 point 7) ------------------------------------------
fr <- t_cv[t_cv$fold %in% as.character(seq_len(SDM_CV_K)), ]
add_qa("cv", "rows: the folds, mean, sd and main; each fold fitted",
       sprintf("%d folds; %d fitted", nrow(fr), sum(fr$status == "fitted")),
       nrow(fr) == SDM_CV_K && nrow(t_cv) == SDM_CV_K + 3 &&
         all(c("mean", "sd", "main") %in% t_cv$fold) &&
         all(fr$status == "fitted"))
add_qa("cv", "the test cells of the folds add up to the cells counted again",
       same_txt(c(n_p_q, n_b_q), c(sum(fr$test_presence_cells),
                                   sum(fr$test_background_cells))),
       sum(fr$test_presence_cells) == n_p_q &&
         sum(fr$test_background_cells) == n_b_q)
add_qa("cv", "training + test presence cells = all presence cells in each fold",
       sprintf("%d of %d folds", sum(fr$train_presence_cells +
                                       fr$test_presence_cells == n_p_q),
               nrow(fr)),
       all(fr$train_presence_cells + fr$test_presence_cells == n_p_q))
bc <- round(SDM_CV_BLOCK_DEG / SDM_GRAIN_DEG)
dk <- strsplit(union(p_key, b_key), "_", fixed = TRUE)
blk <- unique(vapply(dk, function(z) paste(floor(as.numeric(z[1]) / bc),
                                           floor(as.numeric(z[2]) / bc)),
                     character(1)))
add_qa("cv", "the blocks of the folds = the 2 degree blocks with data, counted again",
       same_txt(length(blk), sum(fr$blocks)), sum(fr$blocks) == length(blk))
met <- c("boyce", "auc_test", "or10", "auc_train", "auc_diff")
d <- max(vapply(met, function(m) max(
  sdm_qa_diff(t_cv[t_cv$fold == "mean", m], mean(fr[[m]])),
  sdm_qa_diff(t_cv[t_cv$fold == "sd", m], stats::sd(fr[[m]]))), numeric(1)))
add_qa("cv", "the rows mean and sd = the mean and SD of the fold rows",
       diff_txt(d), agree(d))
d <- sdm_qa_diff(fr$auc_diff, fr$auc_train - fr$auc_test)
add_qa("cv", "auc_diff = auc_train - auc_test", diff_txt(d), agree(d))
add_qa("cv", "Boyce in [-1, 1]; AUC and OR10 in [0, 1]",
       sprintf("Boyce %.3f to %.3f", min(fr$boyce), max(fr$boyce)),
       all(abs(fr$boyce) <= 1) &&
         all(fr[, c("auc_test", "auc_train", "or10")] >= 0 &
               fr[, c("auc_test", "auc_train", "or10")] <= 1))

# ---- 9. Sensitivity runs (Decision 24 point 10) ------------------------------------------
add_qa("sensitivity", "one row per run of SDM_SENS_RUNS",
       paste(t_sen$run, collapse = ", "), identical(t_sen$run, SDM_SENS_RUNS))
rb <- t_sen[t_sen$run == "bias_settlement", ]
add_qa("sensitivity", "bias_settlement: the cells and the settings of the main model",
       same_txt(c(n_p_q, n_b_q), c(rb$presence_cells, rb$background_cells)),
       nrow(rb) == 1 && rb$status == "run" && rb$presence_cells == n_p_q &&
         rb$background_cells == n_b_q && rb$classes == sel_q$classes &&
         rb$regmult == sel_q$regmult)
in_w <- function(y) !is.na(y) & y >= SDM_SENS_WINDOW[1] &
  y <= SDM_SENS_WINDOW[2]
pw <- unique(k_obs[in_w(od_q$year) & k_obs %in% model_keys])
bw <- unique(k_bg[in_w(id_q$year) & k_bg %in% model_keys])
rw <- t_sen[t_sen$run == "window_2018_2022", ]
w_run <- length(pw) >= SDM_MIN_CELLS &&
  length(bw) >= SDM_BG_MIN_RATIO * length(pw)
w_fc  <- if (length(pw) < SDM_MIN_CELLS_FULL) SDM_REDUCED_MAX_CLASSES else
  sel_q$classes
add_qa("sensitivity", "window_2018_2022: the cells counted again, the limits of Decision 23 and the classes",
       same_txt(c(length(pw), length(bw)), c(rw$presence_cells,
                                             rw$background_cells)),
       nrow(rw) == 1 && rw$presence_cells == length(pw) &&
         rw$background_cells == length(bw) &&
         (if (w_run) rw$status %in% c("run", "failed") &&
            rw$classes == w_fc && rw$regmult == sel_q$regmult else
              startsWith(rw$status, "not run")))
ok_r <- t_sen$status == "run"
lab_q <- ifelse(t_sen$rho >= SDM_SENS_RHO_MIN &
                  t_sen$top_overlap >= SDM_SENS_OVERLAP_MIN, "robust",
                "sensitive")
add_qa("sensitivity", "the label from rho and the top share; rho in [-1, 1], share in [0, 1]",
       paste(paste(t_sen$run, t_sen$label, sep = " = "), collapse = "; "),
       all(t_sen$label[ok_r] == lab_q[ok_r]) &&
         all(abs(t_sen$rho[ok_r]) <= 1) &&
         all(t_sen$top_overlap[ok_r] >= 0 & t_sen$top_overlap[ok_r] <= 1))

# ---- 10. Publish checks (p1, s1) ---------------------------------------------------------
f16 <- setdiff(list.files(DIR_TABLES, pattern = "^tbl_16_.*\\.csv$"),
               "tbl_16_sdm_qa.csv")
need16 <- paste0("tbl_16_", c("sdm_counts", "sdm_covariates",
                              "sdm_covariate_cor", "sdm_aicc", "sdm_cv",
                              "sdm_sensitivity"), ".csv")
add_qa("publish", "the six tbl_16 tables of STEPs 14.1 and 14.2 are on disk",
       sprintf("%d tbl_16 files besides the QA table", length(f16)),
       all(need16 %in% f16))
num_ok16 <- c("value", "min", "mean", "max", "z1_water_1km_cells",
              "z1_floored_1km_cells", "z1_water_only_cells", "r", "regmult",
              "k", "loglik", "aicc", "delta_aicc", "blocks",
              "test_presence_cells", "test_background_cells",
              "train_presence_cells", "boyce", "auc_test", "or10",
              "auc_train", "auc_diff", "presence_cells", "background_cells",
              "rho", "top_overlap")
pos_re16 <- paste0("^(x|y|lon|lat|longitude|latitude|geom|geometry|cell|",
                   "cells|id|ix|iy)$|^cell_|cell02|_cell$|corner")
res_hits <- 0
for (f in f16) {
  x <- utils::read.csv(file.path(DIR_TABLES, f), stringsAsFactors = FALSE)
  bad_pos <- names(x)[grepl(pos_re16, tolower(names(x)))]
  bad_num <- setdiff(names(x)[vapply(x, is.numeric, logical(1))], num_ok16)
  add_qa("publish", paste0(f, ": (a) no position or cell column; numbers are counts or statistics"),
         if (length(c(bad_pos, bad_num)) == 0) paste(ncol(x), "columns") else
           paste("columns:", paste(unique(c(bad_pos, bad_num)),
                                   collapse = ", ")),
         length(bad_pos) == 0 && length(bad_num) == 0)
  h <- sdm_qa_id_hits(x, grid_q$id)
  add_qa("publish", paste0(f, ": (b) no value is a cell id of the grid"),
         sprintf("%d values", h), h == 0)
  res_hits <- res_hits + sdm_qa_reserve_hits(x, res_q$unit_name)
}
out_files <- list.files(here("outputs"), recursive = TRUE)
k <- sum(grepl("tiger", basename(out_files), ignore.case = TRUE))
add_qa("publish", "(c) no file with \"tiger\" in its name under outputs/",
       sprintf("%d of %d files", k, length(out_files)), k == 0)
proc_root <- normalizePath(DIR_PROCESSED, winslash = "/", mustWork = FALSE)
in_proc <- function(f) startsWith(normalizePath(f, winslash = "/",
                                                mustWork = FALSE),
                                  paste0(proc_root, "/"))
add_qa("publish", "(d) the model file and the covariate table are under data/processed/",
       paste(basename(c(model_path, cov_path)), collapse = ", "),
       in_proc(model_path) && in_proc(cov_path))
gi <- trimws(readLines(gitignore_in, warn = FALSE))
add_qa("publish", "(d) .gitignore holds the line data/processed/**",
       sprintf("%d lines read", length(gi)), "data/processed/**" %in% gi)
pres_counts <- c(t_cnt$value[t_cnt$group == "presence"],
                 cnt_v("background", "cells_model_with_presence"),
                 fr$test_presence_cells, fr$train_presence_cells,
                 t_sen$presence_cells)
pres_counts <- pres_counts[!is.na(pres_counts) & pres_counts > 0]
add_qa("publish", "s1: no tbl_16 table holds a reserve column or a reserve name (Decision 22 point 9)",
       sprintf("%d hits; smallest presence count above 0: %s", res_hits,
               if (length(pres_counts)) format(min(pres_counts)) else "none"),
       res_hits == 0)

# ---- 11. Write the QA table, then stop on a failure ----------------------------------------
qa_tbl <- do.call(rbind, qa)
h <- sdm_qa_id_hits(qa_tbl, grid_q$id)
add_qa("publish", "tbl_16_sdm_qa.csv: (b) no value is a cell id of the grid",
       sprintf("%d values", h), h == 0)
qa_tbl <- do.call(rbind, qa)
rownames(qa_tbl) <- NULL
occ_assert_counts_only(qa_tbl, cols = c("group", "check", "value", "pass"),
                       count_cols = character(0), name = "tbl_16_sdm_qa.csv")
write_table(qa_tbl, nn = 16, slug = "sdm_qa")
cat("\n--- QA by group ---\n")
grp <- unique(qa_tbl$group)
print(data.frame(group = grp,
                 checks = vapply(grp, function(g) sum(qa_tbl$group == g),
                                 integer(1)),
                 pass = vapply(grp, function(g)
                   sum(qa_tbl$pass[qa_tbl$group == g]), integer(1))),
      row.names = FALSE)
n_bad <- sum(!qa_tbl$pass)
if (n_bad > 0) {
  cat("\n--- checks that FAIL ---\n")
  print(qa_tbl[!qa_tbl$pass, c("group", "check", "value")], row.names = FALSE)
  stop("QA: ", n_bad, " of ", nrow(qa_tbl), " checks fail. tbl_16_sdm_qa.csv ",
       "is written; find the cause before any commit.", call. = FALSE)
}
rule(paste0("STEP 14.3 complete: QA ", nrow(qa_tbl), " of ", nrow(qa_tbl),
            " checks pass (", round(as.numeric(difftime(Sys.time(), t_step3,
                                                     units = "mins")), 1),
            " min).\nCheck `git status --short` before a commit: nothing ",
            "under data/ may be staged."))

}  # end if (SDM_GRAIN_OUTCOME is a model outcome), STEP 14.3
