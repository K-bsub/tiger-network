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
#       (2026-11-07, r2 of task 16.2: STEP 16.1 reads the GBIF
#       coordinates of the two download zip files)
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
#   Decision 25 (task 15.1, 2026-10-31): the prediction and its published
#              form (point 9 added in task 15.2)
#   Process choices of task 15.2 (2026-10-31): w1 the switch RUN_FIT
#              (FALSE: STEP 14.2 is skipped; the later STEPs read the model
#              file of the record, SDM_PRED_MODEL_FILE); l1 the layer
#              sdm_prediction_cell02.csv; n1 the reserve table tbl_17; c1
#              STEP 14.3 scans its six tables only, STEP 15.3 the Week-15
#              tables; t1 the Week-15 tables; k1, e1, p1, q1 (STEPs 15.2 and
#              15.3)
#   STEP 15.1 (task 15.3)  the prediction of the main model (the model file
#              of the record; cloglog with clamping) over the model cells;
#              the cells outside the training range; the rank and the class;
#              the gate of Decision 24 point 8 -> the layer
#              sdm_prediction_cell02.csv and tbl_16_sdm_prediction.csv; h1 a
#              hand-made case first (sdm_self_test_151()).
#              Ran 2026-11-01: the gate open (mean test Boyce 0.668); 6,969
#              model cells; classes of 1,394 (5 to 2) and 1,393 (1) cells; 32
#              cells outside the training range; QA of STEP 14.3 133 of 133
#              with RUN_FIT = FALSE
#   STEP 15.2 (task 15.4)  the reserve check of Decision 24 point 9 with
#              Decision 25 points 7 to 9: the 1 km cells of each reserve by
#              the centre rule (e1); the reserve values; r1 (p1); r2 under
#              the rule of point 9 (y1); the counts of the two kinds of z1
#              -> tbl_16_sdm_reserve_check.csv and
#              tbl_17_reserve_suitability.csv (n1, k1); h1 a hand-made case
#              first (sdm_self_test_152()).
#              Ran 2026-11-01: 56 of 58 reserves with a value; r1 rho 0.379,
#              n 51, p 0.00614 -> "agrees"; r2 not published; z1 0
#   STEP 15.3 (task 15.5)  QA of Decision 25 -> tbl_16_sdm_pred_qa.csv (q1,
#              c1 of task 15.2): the hand-made cases of STEPs 15.1-15.3; a
#              second path (the sdm_qa_* functions of task 15.5; no sdm_*
#              function of STEPs 15.1-15.2); the publish scans of the Week-15
#              tables; an information count of the hatched valued 1 km cells
#              of the reserves (author's choice, task 15.5). Written first;
#              then a FALSE stops the script
#   Decision 26 (task 16.1, 2026-11-07): the Gi* settings; Amendment 1 (task
#              16.2): the distance between cells on the sphere
#   Process choices of task 16.2 (2026-11-07): s1 STEPs 16.1-16.3 after STEP
#              15.3, no new run switch; f1 R/00_functions_gistar.R and
#              R/00_functions_fig.R; p1 the cell centre in longitude and
#              latitude; r2 the GBIF coordinates of the 5 km sets from the two
#              zip files; n1 the four layers hot_*_cell02.csv; t1
#              tbl_18_gistar.csv and tbl_18_gistar_qa.csv; g1, z1, c1, h1, k1,
#              d1 (the figures, STEP 16.2); q1 (the QA, STEP 16.3)
#   STEP 16.1 (task 16.3)  the four Gi* of Decision 26 (effort_inat with
#              tiger_obscured; effort_all with tiger_5km) on the model cells,
#              value 0/1, at GISTAR_BAND_KM and at the two QA bands; the exact
#              p, Benjamini-Hochberg and the classes; the four layers and
#              tbl_18_gistar.csv; h1 a hand-made case first
#              (gistar_self_test()). The tiger Gi* are never published or
#              committed
#   STEP 16.2 (task 16.4)  the figures fig_04 (the five classes) and fig_05
#              (the model output) of Decision 25 points 4 to 6, only with a
#              model outcome; fig_06 (the effort_inat Gi*) of Decision 26
#              point 7. The read guard of k1 (fig_reader()); the hatch and
#              the key box of h1; the caption drafts of d1 (each number from
#              a table or a layer; printed under "DRAFT"); h1 a hand-made
#              case first (fig_self_test())
#   Week 16, to come: STEP 16.3 (QA)
#
# SENSITIVE DATA (docs/sensitive-data-policy.md; Decision 23 point 9):
#   The obscured set and each layer made from it are tier T1 and stay under
#   data/ (gitignored). This script prints TRUE/FALSE, names and counts only:
#   no coordinate, no 0.2 degree cell corner, no cell index, no cell number.
#   A tbl_16 table holds counts and statistics only.
#   (2026-11-07: STEP 16.1 also reads the clean tiger layer (tier T2) and
#   the GBIF coordinates of the two zip files. No coordinate is printed or
#   written to a table; tbl_18_gistar.csv holds counts and statistics only.)
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
#   model file of the record (SDM_PRED_MODEL_FILE; until task 15.3: the model
#   file of this run); the six tbl_16 tables of STEPs 14.1-14.2; tbl_10;
#   data/processed/boundary_reserves_all_7755.gpkg (unit_name, for check s1);
#   .gitignore (check p1 d).
#
# OUTPUTS (STEP 14.3; process choices t1 of task 14.2, c1, h1, p1):
#   outputs/tables/tbl_16_sdm_qa.csv   group, check, value, pass. One row per
#     check. Written first; then any FALSE in `pass` stops the script.
#
# INPUTS (STEP 15.1, task 15.3): the model file of the record; the covariate
#   table; the grid; the obscured layer and the iNaturalist background (for
#   a guard only: no presence or background cell is outside the training
#   range); outputs/tables/tbl_16_sdm_cv.csv (the row mean: the gate).
#
# OUTPUTS (STEP 15.1, task 15.3; process choices l1, t1 of task 15.2):
#   data/processed/sdm_prediction_cell02.csv   one row per model cell: id,
#     value (cloglog, with clamping), rank (1 = the highest value), class
#     (1-5; 5 = the highest), out_of_range. No geometry, no presence or
#     background field. Gitignored
#   outputs/tables/tbl_16_sdm_prediction.csv   group, item, value, reading:
#     the gate; the minimum, median and maximum of the value; each class with
#     its size and value range; the cells outside the training range, all and
#     by covariate. Statistics only: no cell id, no corner
#
# INPUTS (STEP 15.2, task 15.4): the reserve layer (boundary_reserves_all;
#   unit_id, unit_name, state, landscape_complex, geometry_present); the
#   census layer stats_reserve_census_7755.gpkg (density_2022, by unit_id);
#   the prediction layer of STEP 15.1; the cell-id raster; the obscured layer
#   (the presence cells, for r2 only).
#
# OUTPUTS (STEP 15.2, task 15.4; process choices n1, t1, k1 of task 15.2):
#   outputs/tables/tbl_16_sdm_reserve_check.csv   group, item, value,
#     reading: the reserve counts; r1 (rho, n, p, the reading); r2 (its
#     counts and share only if each count of the 2 x 2 table is 3 or more,
#     Decision 25 point 9); the counts of the two kinds of z1. Statistics
#     only: no reserve name, no reserve column, no cell id
#   outputs/tables/tbl_17_reserve_suitability.csv  publishable; one row per
#     reserve (58), by unit_id: unit_id, unit_name, state, landscape_complex,
#     cloglog_mean, cloglog_rank, density_2022, n_1km_cells_used,
#     n_1km_cells_no_value. No presence column
#
# INPUTS (STEP 15.3, task 15.5): the model file of the record, the covariate
#   table, the grid, the cell-id raster, the obscured layer and the
#   iNaturalist background, the reserve and census layers, the prediction
#   layer, tbl_16_sdm_cv.csv and the three Week-15 tables; .gitignore.
#
# OUTPUTS (STEP 15.3; process choices q1, c1 of task 15.2):
#   outputs/tables/tbl_16_sdm_pred_qa.csv   group, check, value, pass. One
#     row per check. Written first; then any FALSE in `pass` stops the
#     script. Counts and statistics only: no reserve name, no cell id
#
# INPUTS (STEP 16.1, task 16.3): the grid and the cell-id raster (STEP 14.1);
#   the obscured layer and the iNaturalist background (read by the guards);
#   data/processed/occ_tiger_gbif_clean_7755.gpkg (tier T2) and the clean
#   background layer; the two GBIF download zip files (their key files in
#   data/raw/gbif/ and data/raw/gbif_background/; r2); the reserve layer
#   (rule L1); tbl_15_occ_sets.csv (the guards); .gitignore.
#
# OUTPUTS (STEP 16.1, task 16.3; process choices n1, t1 of task 16.2):
#   data/processed/hot_effort_inat_cell02.csv, hot_tiger_obscured_cell02.csv,
#     hot_effort_all_cell02.csv and hot_tiger_5km_cell02.csv (gitignored; the
#     two tiger layers are never committed): one row per model cell: id,
#     value, n_nb, n_win, k, gistar, p_hot, p_cold, p_two, p_adj, class. No
#     geometry
#   outputs/tables/tbl_18_gistar.csv   publishable; gistar, band, group, item,
#     value, reading: the settings; the neighbours by band; for the effort
#     Gi*, the inputs and the classes; for the tiger Gi*, only the counts of
#     Decision 26 point 7 (s1; for tiger_5km also by landscape complex, s2).
#     No cell id, no position, no reserve name
#
# INPUTS (STEP 16.2, task 16.4; k1 of task 16.2): the figures read only the
#   files of their list. fig_04 and fig_05: the prediction layer (STEP 15.1),
#   the grid layer (STEP 14.1), the reserve layer and
#   data/processed/boundary_states_7755.gpkg. fig_06: the layer
#   hot_effort_inat_cell02.csv (STEP 16.1), the grid, the reserves and the
#   states. The captions: tbl_16_sdm_counts, tbl_16_sdm_cv,
#   tbl_16_sdm_sensitivity, tbl_16_sdm_prediction, tbl_16_sdm_reserve_check,
#   tbl_18_gistar and the two GBIF DOI files (gbif_tiger_download_doi.txt,
#   background_download_doi.txt). Of the reserve and state layers, only the
#   geometry is drawn.
#
# OUTPUTS (STEP 16.2, task 16.4; g1, z1 of task 16.2):
#   outputs/figures/fig_04_suitability_classes.png,
#   fig_05_suitability_value.png and fig_06_effort_gistar.png (11 x 10.6
#   inches, 200 dpi; the size is read back from each file). The titles, the
#   subtitles and the captions are DRAFT text for the author's edit (d1).
#   No point, no presence mark, no background mark
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
source(here("R", "00_functions_gistar.R"))   # gistar_* (task 16.3)
source(here("R", "00_functions_fig.R"))      # fig_* (task 16.4)

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

# ---- Run switch (process choice w1, task 15.2, 2026-10-31) ---------------------
# TRUE  : STEP 14.2 runs as in Week 14 (the 19 fits, the five STEP-14.2
#         tables, a model file with the date of the run), and STEP 14.3 also
#         checks that the fit of this run has the coefficients of the model
#         file of the record.
# FALSE : STEP 14.2 is skipped: no fit, and no STEP-14.2 table or model file
#         is written. STEP 14.3 and the Week-15 STEPs read the model file of
#         the record, SDM_PRED_MODEL_FILE (Decision 25 a1).
# 2026-10-31: FALSE — the model of the record is fixed by Decision 25.
RUN_FIT <- FALSE

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
cov_path    <- file.path(DIR_PROCESSED, cov_out)
settl_in    <- file.path(DIR_PROCESSED, "kde_settlement_citytown_1km_7755.tif")
# The model file of the record (Decision 25 a1; w1 of task 15.2). STEP 14.3
# and the Week-15 STEPs read it. With RUN_FIT = TRUE, STEP 14.2 writes one more
# dated file (run_model_path).
rec_model_path <- file.path(SDM_MODEL_DIR, SDM_PRED_MODEL_FILE)
run_model_path <- NA_character_
# STEP 14.3 (s1, p1)
reserves_in  <- file.path(DIR_PROCESSED, "boundary_reserves_all_7755.gpkg")
gitignore_in <- here(".gitignore")
# STEP 15.1 (l1, t1 of task 15.2)
pred_out  <- "sdm_prediction_cell02.csv"       # in DIR_PROCESSED
pred_path <- file.path(DIR_PROCESSED, pred_out)
cv_tbl_in <- file.path(DIR_TABLES, "tbl_16_sdm_cv.csv")
# STEP 15.2 (n1, k1 of task 15.2)
stats_in  <- file.path(DIR_PROCESSED, "stats_reserve_census_7755.gpkg")
# STEP 16.1 (r2, n1, t1 of task 16.2)
tiger_clean_in <- file.path(DIR_PROCESSED, "occ_tiger_gbif_clean_7755.gpkg")
tiger_key_in   <- file.path(DIR_RAW, "gbif", "gbif_tiger_download_key.txt")
bg_key_in      <- file.path(DIR_RAW, "gbif_background",
                            "background_download_key.txt")
# STEP 16.2 (k1 of task 16.2): the frame and the DOI files of the captions
states_in    <- file.path(DIR_PROCESSED, "boundary_states_7755.gpkg")
tiger_doi_in <- file.path(DIR_RAW, "gbif", "gbif_tiger_download_doi.txt")
bg_doi_in    <- file.path(DIR_RAW, "gbif_background",
                          "background_download_doi.txt")
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
if (!is.logical(RUN_FIT) || length(RUN_FIT) != 1L || is.na(RUN_FIT)) {
  stop("RUN_FIT must be TRUE or FALSE.", call. = FALSE)
}
if (RUN_COVARIATES && !RUN_FIT) {
  stop("RUN_COVARIATES = TRUE needs RUN_FIT = TRUE (the covariate table is ",
       "built in STEP 14.2).", call. = FALSE)
}
if (!file.exists(rec_model_path)) {
  stop("The model file of the record is not on disk: ", rec_model_path,
       " (SDM_PRED_MODEL_FILE, Decision 25 a1).", call. = FALSE)
}
if (RUN_FIT && identical(
  normalizePath(file.path(SDM_MODEL_DIR, sprintf(
    "%s_%s_%s.rds", SDM_MODEL_NAME[["species"]], SDM_MODEL_NAME[["model"]],
    format(Sys.Date(), "%Y%m%d"))), winslash = "/", mustWork = FALSE),
  normalizePath(rec_model_path, winslash = "/", mustWork = FALSE))) {
  stop("RUN_FIT = TRUE today would write over the model file of the record (",
       SDM_PRED_MODEL_FILE, "). Run on another day or keep RUN_FIT = FALSE.",
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
# Process choice w1 of task 15.2: runs only with RUN_FIT = TRUE.

if (SDM_GRAIN_OUTCOME %in% c("reduced_model", "planned_model") && !RUN_FIT) {
  rule(paste0("STEP 14.2 skipped (RUN_FIT = FALSE; w1 of task 15.2): no fit; ",
              "the later STEPs read the model file of the record,
",
              SDM_PRED_MODEL_FILE, "."))
}

if (SDM_GRAIN_OUTCOME %in% c("reduced_model", "planned_model") && RUN_FIT) {

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
run_model_path <- save_model(model_obj, SDM_MODEL_NAME[["species"]],
                             SDM_MODEL_NAME[["model"]], dir = SDM_MODEL_DIR)
back_obj <- readRDS(run_model_path)
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

}  # end if (SDM_GRAIN_OUTCOME is a model outcome and RUN_FIT), STEP 14.2

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
# Process choices of task 15.2 (2026-10-31): w1 check m1 reads the model file
# of the record (SDM_PRED_MODEL_FILE); with RUN_FIT = TRUE, one more check:
# the fit of this run has the coefficients of that file. c1 the publish
# checks scan the six tables of STEPs 14.1-14.2 only; STEP 15.3 scans the
# Week-15 tables.
# As STEP 13.5 of scripts/08: the step reads its inputs from disk (not the
# objects of STEP 14.2), runs in each run after STEP 14.2 (also when RUN_FIT
# = FALSE skips STEP 14.2), and writes tbl_16_sdm_qa.csv (group, check,
# value, pass) first; then any FALSE stops the script. Groups: "test case",
# "presence", "background", "grid", "covariates", "model", "cv",
# "sensitivity", "publish".
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
add_qa("model", "the model file of the record (SDM_PRED_MODEL_FILE) is on disk (m1; w1 of task 15.2)",
       sprintf("%s; %d other dated model file(s)", SDM_PRED_MODEL_FILE,
               length(setdiff(mf_all, SDM_PRED_MODEL_FILE))),
       file.exists(rec_model_path) && SDM_PRED_MODEL_FILE %in% mf_all)
mo <- readRDS(rec_model_path)
if (RUN_FIT) {
  mr <- readRDS(run_model_path)
  b_same <- identical(names(mr$model$betas), names(mo$model$betas))
  d <- if (b_same) sdm_qa_diff(as.numeric(mr$model$betas),
                               as.numeric(mo$model$betas)) else Inf
  add_qa("model", "RUN_FIT = TRUE: the fit of this run has the coefficients of the model file of the record (w1 of task 15.2)",
         paste0(basename(run_model_path), "; ", diff_txt(d)),
         b_same && agree(d))
  rm(mr)
}
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
# c1 of task 15.2: the six tables of STEPs 14.1-14.2 only. STEP 15.3 scans
# the Week-15 tables in the same run, after STEPs 15.1-15.2 write them.
need16 <- paste0("tbl_16_", c("sdm_counts", "sdm_covariates",
                              "sdm_covariate_cor", "sdm_aicc", "sdm_cv",
                              "sdm_sensitivity"), ".csv")
f16 <- need16[file.exists(file.path(DIR_TABLES, need16))]
add_qa("publish", "the six tbl_16 tables of STEPs 14.1 and 14.2 are on disk",
       sprintf("%d of %d tables", length(f16), length(need16)),
       length(f16) == length(need16))
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
mp_q <- c(rec_model_path, if (RUN_FIT) run_model_path)
add_qa("publish", "(d) the model file(s) and the covariate table are under data/processed/",
       paste(basename(c(mp_q, cov_path)), collapse = ", "),
       all(vapply(c(mp_q, cov_path), in_proc, logical(1))))
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

# =============================================================================
# STEP 15.1 — the prediction, the classes, the flag and the gate (task 15.3;
#             Decision 25 points 1 to 4; Decision 24 point 8)
# =============================================================================
# Process choices of task 15.2 (2026-10-31): w1 the model file of the
# record; l1 the layer; t1 the table; h1 a hand-made case first. Runs only
# with SDM_GRAIN_OUTCOME "reduced_model" or "planned_model", after STEP 14.3.
#   1. maxnet 0.1.4; the settings of Decision 25; the hand-made case
#      (sdm_self_test_151())
#   2. the gate (Decision 24 point 8) from the row mean of tbl_16_sdm_cv.csv.
#      Closed: the gate rows are written to tbl_16_sdm_prediction.csv and the
#      script stops (no layer)
#   3. the model file of the record and the covariate table of the model
#      cells
#   4. the prediction: cloglog with clamping (Decision 25 a1)
#   5. the cells outside the training range (point 2); a guard: no presence
#      or background cell is outside it
#   6. the rank and the class (point 3)
#   7. the layer data/processed/sdm_prediction_cell02.csv (gitignored), read
#      back and checked
#   8. tbl_16_sdm_prediction.csv (statistics only)
# Console text: counts and statistics only (no cell id, no corner).

if (SDM_GRAIN_OUTCOME %in% c("reduced_model", "planned_model")) {

rule("STEP 15.1 — the prediction, the classes, the flag and the gate (task 15.3)")
t_step151 <- Sys.time()

# ---- 1. maxnet, the settings of Decision 25, the hand-made case (h1) ----------
if (!requireNamespace("maxnet", quietly = TRUE) ||
    as.character(utils::packageVersion("maxnet")) != "0.1.4") {
  stop("STEP 15.1 needs maxnet 0.1.4 (renv::restore()).", call. = FALSE)
}
need25 <- c("SDM_PRED_MODEL_FILE", "SDM_PRED_TYPE", "SDM_PRED_CLAMP",
            "SDM_PRED_FLAG_RANGE", "SDM_PUB_N_CLASSES", "SDM_PUB_CLASS_RULE",
            "SDM_PUB_LAYER")
miss25 <- need25[!vapply(need25, exists, logical(1))]
if (length(miss25) > 0) {
  stop("Setting(s) missing from R/00_config.R (Decision 25): ",
       paste(miss25, collapse = ", "), call. = FALSE)
}
sdm_run_guards(list(
  "SDM_PRED_TYPE must be SDM_EVAL_TYPE, cloglog (Decision 25 a1)" =
    identical(SDM_PRED_TYPE, SDM_EVAL_TYPE) &&
    identical(SDM_PRED_TYPE, "cloglog"),
  "SDM_PRED_CLAMP must be TRUE (Decision 25 a1)" =
    identical(SDM_PRED_CLAMP, TRUE),
  "SDM_PRED_FLAG_RANGE must be TRUE (Decision 25 b2)" =
    identical(SDM_PRED_FLAG_RANGE, TRUE),
  "SDM_PUB_N_CLASSES must be 5 and SDM_PUB_CLASS_RULE rank_equal_count (Decision 25 c1, n5)" =
    identical(SDM_PUB_N_CLASSES, 5L) &&
    identical(SDM_PUB_CLASS_RULE, "rank_equal_count"),
  "SDM_PUB_N_CLASSES x SDM_SENS_TOP_SHARE must be 1 (class 5 = the top set of the sensitivity rule)" =
    isTRUE(all.equal(SDM_PUB_N_CLASSES * SDM_SENS_TOP_SHARE, 1)),
  "SDM_PUB_LAYER must be FALSE (Decision 25 d1)" =
    identical(SDM_PUB_LAYER, FALSE)
), what = "the Decision-25 settings")
st151 <- sdm_self_test_151()
cat("hand-made case of STEP 15.1:", sum(st151$pass), "of", nrow(st151),
    "checks pass.\n")
if (!all(st151$pass)) {
  stop("The hand-made case of STEP 15.1 failed:\n  ",
       paste(st151$check[!st151$pass], collapse = "\n  "), call. = FALSE)
}

# ---- 2. The gate (Decision 24 point 8) -------------------------------------------
if (!file.exists(cv_tbl_in)) {
  stop("STEP 15.1 needs ", cv_tbl_in, ".", call. = FALSE)
}
cv_t <- utils::read.csv(cv_tbl_in, stringsAsFactors = FALSE)
mean_boyce <- cv_t$boyce[cv_t$fold == "mean"]
if (length(mean_boyce) != 1L) {
  stop("tbl_16_sdm_cv.csv must have one row mean.", call. = FALSE)
}
gate_open <- sdm_gate_open(mean_boyce, SDM_BOYCE_GATE)
cat("gate (Decision 24 point 8): mean test Boyce index", round(mean_boyce, 3),
    if (gate_open) "is above" else "is at or below", SDM_BOYCE_GATE,
    if (gate_open) "-> a suitability map is allowed.\n" else
      "-> no suitability map.\n")
if (!gate_open) {
  g_tbl <- sdm_pred_summary(mean_boyce, gate = SDM_BOYCE_GATE)
  occ_assert_counts_only(g_tbl, cols = c("group", "item", "value", "reading"),
                         count_cols = character(0),
                         name = "tbl_16_sdm_prediction.csv")
  write_table(g_tbl, nn = 16, slug = "sdm_prediction")
  stop("The gate of Decision 24 point 8 is closed: the model is not published ",
       "as a suitability map, and no prediction layer is written. Stage 3 ",
       "gives the effort result.", call. = FALSE)
}

# ---- 3. The model file of the record and the covariate table ---------------------
mo_p   <- readRDS(rec_model_path)
fit_p  <- mo_p$model
covs_p <- mo_p$settings$covariates
cov_p  <- utils::read.csv(cov_path)
cov_p  <- cov_p[order(cov_p$id), ]
rownames(cov_p) <- NULL
model_ids_p <- sort(grid_d$id[grid_d$model])
sdm_run_guards(list(
  "the model file must hold model, settings and versions" =
    identical(names(mo_p), c("model", "settings", "versions")),
  "the model must be a maxnet fit of maxnet 0.1.4" =
    inherits(fit_p, "maxnet") && identical(mo_p$versions$maxnet, "0.1.4"),
  "the model must have varmin and varmax for each kept covariate (and no other)" =
    length(covs_p) > 0 && setequal(names(fit_p$varmin), covs_p) &&
    setequal(names(fit_p$varmax), covs_p),
  "the covariate table must hold each model cell of the grid once" =
    identical(as.numeric(cov_p$id), as.numeric(model_ids_p)),
  "the covariate table must hold the kept covariates, with no NA" =
    all(covs_p %in% names(cov_p)) && !anyNA(cov_p[, covs_p, drop = FALSE])
), what = "the model file of the record and the covariate table")
cat("model file:", SDM_PRED_MODEL_FILE, "|", length(covs_p), "covariates:",
    paste(covs_p, collapse = ", "), "|", mo_p$settings$classes, "regmult",
    mo_p$settings$regmult, "\n")

# ---- 4. The prediction (Decision 25 a1) -------------------------------------------
nd_p  <- cov_p[, covs_p, drop = FALSE]
val_p <- sdm_pred_values(fit_p, nd_p, SDM_PRED_TYPE, SDM_PRED_CLAMP)

# ---- 5. The cells outside the training range (Decision 25 b2) ---------------------
oor_p <- sdm_out_of_range(nd_p, fit_p$varmin, fit_p$varmax)
# The presence and background cells, for the guard only (as STEP 14.1; STEP
# 14.2 can be skipped, w1). They are not written to any file.
pi_p <- sdm_cell_index(obs_d$cell02_lon_deg, obs_d$cell02_lat_deg)
bi_p <- sdm_cell_index(inat_d$cell02_lon_deg, inat_d$cell02_lat_deg)
is_p <- cov_p$id %in% sdm_cell_id(pi_p$ix, pi_p$iy)
is_b <- cov_p$id %in% sdm_cell_id(bi_p$ix, bi_p$iy)
sdm_run_guards(list(
  "one value per model cell, with no NA" =
    length(val_p) == nrow(cov_p) && !anyNA(val_p),
  "the presence and background cells on model cells must be the counts of STEP 14.1" =
    sum(is_p) == cnt$n_presence && sum(is_b) == cnt$n_background,
  "no presence or background cell may be outside the training range (Decision 25 point 2)" =
    !any(oor_p$flag[is_p | is_b])
), what = "the prediction")
rm(pi_p, bi_p, is_p, is_b)

# ---- 6. The rank and the class (Decision 25 c1, n5) --------------------------------
rc_p <- sdm_rank_class(val_p, cov_p$id, SDM_PUB_N_CLASSES)
layer_p <- data.frame(id = cov_p$id, value = val_p, rank = rc_p$rank,
                      class = rc_p$class, out_of_range = oor_p$flag)
sdm_run_guards(sdm_pred_layer_checks(layer_p, model_ids_p),
               what = "the prediction layer (in memory)")

# ---- 7. The layer (l1): write, read back, check ------------------------------------
utils::write.csv(layer_p, pred_path, row.names = FALSE)
back_p <- utils::read.csv(pred_path)
sdm_run_guards(c(sdm_pred_layer_checks(back_p, model_ids_p), list(
  "the file on disk must hold the ids, ranks, classes and flags in memory" =
    identical(as.numeric(back_p$id), as.numeric(layer_p$id)) &&
    identical(as.integer(back_p$rank), layer_p$rank) &&
    identical(as.integer(back_p$class), layer_p$class) &&
    identical(as.logical(back_p$out_of_range), layer_p$out_of_range),
  "the file on disk must hold the values in memory" =
    isTRUE(all.equal(back_p$value, layer_p$value, tolerance = 1e-12))
)), what = "the prediction layer (read back)")
message("Wrote ", pred_path, " (", nrow(layer_p), " model cells)")
rm(back_p)

# ---- 8. The table (t1; statistics only) --------------------------------------------
pred_tbl <- sdm_pred_summary(mean_boyce, layer_p, oor_p, SDM_BOYCE_GATE,
                             SDM_PUB_N_CLASSES)
occ_assert_counts_only(pred_tbl, cols = c("group", "item", "value", "reading"),
                       count_cols = character(0),
                       name = "tbl_16_sdm_prediction.csv")
assert_publishable_table(pred_tbl, prefix = NULL,
                         name = "tbl_16_sdm_prediction.csv")
write_table(pred_tbl, nn = 16, slug = "sdm_prediction")
cat("\n--- tbl_16_sdm_prediction.csv (Decision 25 points 2 and 3; Decision 24 point 8) ---\n")
show_p <- pred_tbl
show_p$value <- ifelse(is.na(pred_tbl$value), "",
  ifelse(pred_tbl$value == round(pred_tbl$value) & abs(pred_tbl$value) >= 1,
         trimws(formatC(pred_tbl$value, format = "d", big.mark = ",")),
         trimws(formatC(pred_tbl$value, digits = 4, format = "g"))))
old_w <- options(width = 120)
print(show_p, row.names = FALSE, right = FALSE)
options(old_w)
rm(show_p)

rule(paste0(
  "STEP 15.1 complete (", round(as.numeric(difftime(Sys.time(), t_step151,
                                                  units = "mins")), 1),
  " min).\nGate: open (mean test Boyce ", round(mean_boyce, 3), " > ",
  SDM_BOYCE_GATE, ").\n",
  "Prediction: ", nrow(layer_p), " model cells, cloglog with clamping, from ",
  SDM_PRED_MODEL_FILE, ".\n",
  "Classes 5 to 1: ", paste(vapply(rev(seq_len(SDM_PUB_N_CLASSES)),
                                   function(j) sum(layer_p$class == j),
                                   integer(1)), collapse = ", "),
  " cells | outside the training range: ", sum(layer_p$out_of_range),
  " cells.\nLayer under data/processed/ (gitignored). Check `git status ",
  "--short` before a commit: nothing under data/ may be staged."))

}  # end if (SDM_GRAIN_OUTCOME is a model outcome), STEP 15.1

# =============================================================================
# STEP 15.2 — the reserve check and the reserve table (task 15.4; Decision 24
#             point 9; Decision 25 points 7 to 9)
# =============================================================================
# Process choices of task 15.2 (2026-10-31): n1, t1, k1, e1, p1; h1 a
# hand-made case first. Runs only with SDM_GRAIN_OUTCOME "reduced_model" or
# "planned_model", after STEP 15.1 (a closed gate stops the script in STEP
# 15.1).
#   1. the settings; the hand-made case (sdm_self_test_152())
#   2. the inputs: the reserve layer, density_2022, the prediction layer of
#      STEP 15.1 (from disk)
#   3. the complete-case 1 km cells inside each reserve polygon (centre rule;
#      a cell in two polygons counts in each)
#   4. the presence cells (for r2 only); the reserve values and counts
#   5. r1 (Spearman rho, n, p; the reading)
#   6. r2 under the rule of Decision 25 point 9 (y1)
#   7. the counts of the two kinds of z1 (Decision 25 point 9). STEP 15.3
#      (task 15.5) checks that the total is 0; above 0, the console gives the
#      names, marked "not for the docs"
#   8. tbl_16_sdm_reserve_check.csv and tbl_17_reserve_suitability.csv
# Console text: counts, names and statistics. No reserve name is printed with
# a presence state; the r2 counts are printed only if they are published.

if (SDM_GRAIN_OUTCOME %in% c("reduced_model", "planned_model")) {

rule("STEP 15.2 — the reserve check and the reserve table (task 15.4)")
t_step152 <- Sys.time()

# ---- 1. The settings and the hand-made case (h1) ---------------------------------
need152 <- c("SDM_RESERVE_CHECK", "SDM_RESERVE_P", "SDM_RESERVE_CELL_RULE",
             "SDM_RESERVE_NONMODEL", "SDM_PUB_RESERVE_TABLE",
             "SDM_PUB_R2_MIN_N", "SDM_PUB_RANK_TIES", "SDM_RESERVE_P_EXACT")
miss152 <- need152[!vapply(need152, exists, logical(1))]
if (length(miss152) > 0) {
  stop("Setting(s) missing from R/00_config.R (Decisions 24 and 25): ",
       paste(miss152, collapse = ", "), call. = FALSE)
}
sdm_run_guards(list(
  "SDM_RESERVE_CELL_RULE must be centre (Decision 25 h1)" =
    identical(SDM_RESERVE_CELL_RULE, "centre"),
  "SDM_RESERVE_NONMODEL must be exclude_and_count (Decision 25 h1)" =
    identical(SDM_RESERVE_NONMODEL, "exclude_and_count"),
  "SDM_PUB_RESERVE_TABLE must be TRUE (Decision 25 t1)" =
    identical(SDM_PUB_RESERVE_TABLE, TRUE),
  "SDM_PUB_R2_MIN_N must be KDE_SMALL_N, 3 (Decision 25 point 9, y1)" =
    identical(SDM_PUB_R2_MIN_N, KDE_SMALL_N) &&
    isTRUE(SDM_PUB_R2_MIN_N == 3),
  "SDM_PUB_RANK_TIES must be min (k1 of task 15.2)" =
    identical(SDM_PUB_RANK_TIES, "min"),
  "SDM_RESERVE_P_EXACT must be FALSE (p1 of task 15.2)" =
    identical(SDM_RESERVE_P_EXACT, FALSE),
  "SDM_RESERVE_P must be a number in (0, 1)" =
    is.numeric(SDM_RESERVE_P) && length(SDM_RESERVE_P) == 1 &&
    SDM_RESERVE_P > 0 && SDM_RESERVE_P < 1
), what = "the settings of the reserve check")
st152 <- sdm_self_test_152()
cat("hand-made case of STEP 15.2:", sum(st152$pass), "of", nrow(st152),
    "checks pass.\n")
if (!all(st152$pass)) {
  stop("The hand-made case of STEP 15.2 failed:\n  ",
       paste(st152$check[!st152$pass], collapse = "\n  "), call. = FALSE)
}

# ---- 2. The inputs -----------------------------------------------------------------
for (f in c(reserves_in, stats_in, pred_path)) {
  if (!file.exists(f)) stop("STEP 15.2 needs ", f, ".", call. = FALSE)
}
res_sf <- sf::st_read(reserves_in, quiet = TRUE)
res_d  <- sf::st_drop_geometry(res_sf)
st_d   <- sf::st_drop_geometry(sf::st_read(stats_in, quiet = TRUE))
pred_d <- utils::read.csv(pred_path)
has_geom <- !sf::st_is_empty(res_sf)
sdm_run_guards(list(
  "the reserve layer must have unit_id, unit_name, state, landscape_complex and geometry_present" =
    all(c("unit_id", "unit_name", "state", "landscape_complex",
          "geometry_present") %in% names(res_d)),
  "the reserve layer must be in the analysis CRS" =
    identical(as.integer(sf::st_crs(res_sf)$epsg), as.integer(CRS_ANALYSIS)),
  "each unit_id of the reserve layer must be a whole number, once" =
    !anyNA(res_d$unit_id) && all(res_d$unit_id == round(res_d$unit_id)) &&
    !anyDuplicated(res_d$unit_id),
  "geometry_present must agree with the geometry" =
    identical(as.logical(res_d$geometry_present), has_geom),
  "the census layer must hold unit_id and density_2022, each reserve once" =
    all(c("unit_id", "density_2022") %in% names(st_d)) &&
    !anyDuplicated(st_d$unit_id) &&
    setequal(as.integer(st_d$unit_id), as.integer(res_d$unit_id)),
  "density_2022 must be 0 or more, or NA" =
    all(is.na(st_d$density_2022) | st_d$density_2022 >= 0)
), what = "the reserve and census layers")
sdm_run_guards(sdm_pred_layer_checks(pred_d, sort(grid_d$id[grid_d$model])),
               what = "the prediction layer of STEP 15.1 (from disk)")
dens <- st_d$density_2022[match(as.integer(res_d$unit_id),
                                as.integer(st_d$unit_id))]
cat("reserves:", nrow(res_d), "| with a polygon:", sum(has_geom),
    "| with density_2022:", sum(!is.na(dens)), "\n")

# ---- 3. The 1 km cells of each reserve (e1; Decision 25 point 8) ----------------
rc <- sdm_reserve_cells(res_sf, cellid_r)

# ---- 4. Presence cells (r2 only) and the reserve values ---------------------------
pi_r <- sdm_cell_index(obs_d$cell02_lon_deg, obs_d$cell02_lat_deg)
pres_ids_r <- intersect(sdm_cell_id(pi_r$ix, pi_r$iy), pred_d$id)
rv <- sdm_reserve_values(rc, pred_d, nrow(res_d), has_geom, pres_ids_r)
sdm_run_guards(list(
  "the presence cells on model cells must be the count of STEP 14.1" =
    length(pres_ids_r) == cnt$n_presence,
  "each reserve with a polygon must have its counts; a reserve with no polygon none" =
    all(!is.na(rv$n_used[has_geom])) && all(is.na(rv$n_used[!has_geom])),
  "the 1 km cells of the reserves must be complete-case cells of the grid" =
    all(rc$id %in% grid_d$id)
), what = "the reserve values")
rm(pi_r)

# ---- 5. r1 (Decision 24 point 9; p1) ---------------------------------------------
r1 <- sdm_reserve_r1(rv$value, dens, SDM_RESERVE_P, SDM_RESERVE_P_EXACT)

# ---- 6. r2 under Decision 25 point 9 (y1) ------------------------------------------
med_p <- stats::median(pred_d$value)
r2 <- sdm_reserve_r2(rv$value, rv$has_presence, med_p, SDM_PUB_R2_MIN_N)

# ---- 7. The two kinds of z1 (Decision 25 point 9) --------------------------------
z1 <- sdm_reserve_z1(has_geom, rv$n_used, rv$all_hatched)

# ---- 8. The tables (n1, t1, k1) ----------------------------------------------------
tbl17 <- sdm_reserve_table(res_d, rv, dens, SDM_PUB_RANK_TIES)
sdm_run_guards(sdm_reserve_table_checks(tbl17, nrow(res_d)),
               what = "tbl_17_reserve_suitability.csv")
assert_publishable_table(tbl17, prefix = NULL,
                         name = "tbl_17_reserve_suitability.csv")
chk <- sdm_reserve_check_summary(nrow(res_d), has_geom, rv, dens, r1, r2, z1,
                                 SDM_PUB_R2_MIN_N)
occ_assert_counts_only(chk, cols = c("group", "item", "value", "reading"),
                       count_cols = character(0),
                       name = "tbl_16_sdm_reserve_check.csv")
assert_publishable_table(chk, prefix = NULL,
                         name = "tbl_16_sdm_reserve_check.csv")
norm_n <- function(x) tolower(gsub("[[:space:]]+", " ", trimws(x)))
sdm_run_guards(list(
  "tbl_16_sdm_reserve_check.csv must hold no reserve name and no reserve column (check s1 of task 14.6)" =
    !any(grepl("^(unit_id|unit_name|reserve.*)$", tolower(names(chk)))) &&
    !any(norm_n(c(chk$item, chk$reading)) %in% norm_n(res_d$unit_name)),
  "r2: no count in the table unless r2 is published (Decision 25 point 9)" =
    r2$publish || sum(chk$group == "r2") == 1L
), what = "tbl_16_sdm_reserve_check.csv")
write_table(chk,   nn = 16, slug = "sdm_reserve_check")
write_table(tbl17, nn = 17, slug = "reserve_suitability")

# ---- Console (counts, names and statistics) ---------------------------------------
fmt_v <- function(v) ifelse(is.na(v), "",
  ifelse(v == round(v) & abs(v) >= 1,
         trimws(formatC(v, format = "d", big.mark = ",")),
         trimws(formatC(v, digits = 4, format = "g"))))
cat("\n--- tbl_16_sdm_reserve_check.csv (Decision 24 point 9; Decision 25 points 8 and 9) ---\n")
show_c <- chk
show_c$value <- fmt_v(chk$value)
old_w <- options(width = 120)
print(show_c, row.names = FALSE, right = FALSE)
cat("\n--- tbl_17_reserve_suitability.csv (Decision 25 point 7; by unit_id;",
    "state and landscape_complex are in the file) ---\n")
show_t <- tbl17[, c("unit_id", "unit_name", "cloglog_mean", "cloglog_rank",
                    "density_2022", "n_1km_cells_used",
                    "n_1km_cells_no_value")]
show_t$cloglog_mean <- ifelse(is.na(tbl17$cloglog_mean), "NA",
  trimws(formatC(tbl17$cloglog_mean, digits = 4, format = "g")))
show_t$density_2022 <- ifelse(is.na(tbl17$density_2022), "NA",
  trimws(formatC(tbl17$density_2022, digits = 4, format = "g")))
print(show_t, row.names = FALSE, right = FALSE)
options(old_w)
rm(show_c, show_t)

cat("\nr1:", sprintf("rho = %.3f, n = %d, p = %.3g -> %s", r1$rho, r1$n, r1$p,
                     r1$reading), "\n")
if (r2$publish) {
  cat("r2: published -", r2$n_above, "of", r2$n_none,
      "reserves with no presence cell are above the median of the model cells",
      sprintf("(share %.3f)", r2$share), "\n")
} else {
  cat(paste0("r2: not published (a count of the 2 x 2 table is below ",
             SDM_PUB_R2_MIN_N, "; Decision 25 point 9).\n"))
}
cat("z1 (Decision 25 point 9): kind (a)", z1$kind_a, "| kind (b)", z1$kind_b,
    "| total", z1$total, "(STEP 15.3 checks that the total is 0)\n")
if (z1$total > 0) {
  cat("\n*** NOT FOR THE DOCS (Decision 25 point 9) ***\n")
  if (z1$kind_a > 0) {
    cat("kind (a), all valued 1 km cells outside the training range:",
        paste(res_d$unit_name[z1$rows_a], collapse = "; "), "\n")
  }
  if (z1$kind_b > 0) {
    cat("kind (b), a polygon and no 1 km cell with a value:",
        paste(res_d$unit_name[z1$rows_b], collapse = "; "), "\n")
  }
  cat("STEP 15.3 (task 15.5) will fail on this check. The author decides",
      "before the figures and before the commit of tbl_17.\n")
  cat("*** END ***\n")
}

rule(paste0(
  "STEP 15.2 complete (", round(as.numeric(difftime(Sys.time(), t_step152,
                                                  units = "mins")), 1),
  " min).\nReserves with a value: ", sum(!is.na(rv$value)), " of ",
  nrow(res_d), " | r1: ", r1$reading, " | r2: ",
  if (r2$publish) "published" else "not published", " | z1 total: ",
  z1$total, ".\nCheck `git status --short` before a commit: nothing under ",
  "data/ may be staged."))

}  # end if (SDM_GRAIN_OUTCOME is a model outcome), STEP 15.2

# =============================================================================
# STEP 15.3 — QA of Decision 25 (task 15.5)
# =============================================================================
# Process choices of task 15.2 (2026-10-31): q1 its own table, a hand-made
# case first, a second path that calls no sdm_* function of STEPs 15.1-15.2
# (the sdm_qa_* functions of task 15.5); c1 the publish scans of the Week-15
# tables in this run. Author's choice of task 15.5 (2026-11-01): an
# information count of the valued 1 km cells of the reserves that are outside
# the training range (a row with pass TRUE; not a check).
# As STEP 14.3: the step reads its inputs from disk and writes
# tbl_16_sdm_pred_qa.csv (group, check, value, pass) first; then any FALSE
# stops the script. Groups: "test case", "prediction", "classes",
# "reserves", "r1", "r2", "z1", "info", "publish".
# Console: counts, names and statistics. A reserve name is printed only for
# the information count (a share of cells, not a presence state) and, if the
# z1 check fails, in a block marked "not for the docs". No r2 count is
# printed or written when r2 is not published.

if (SDM_GRAIN_OUTCOME %in% c("reduced_model", "planned_model")) {

rule("STEP 15.3 — QA of Decision 25 (task 15.5)")
t_step153 <- Sys.time()
q5 <- list()
add_q5 <- function(group, check, value, pass) {
  q5[[length(q5) + 1L]] <<- data.frame(group = group, check = check,
                                       value = as.character(value),
                                       pass = isTRUE(pass),
                                       stringsAsFactors = FALSE)
  invisible(NULL)
}
agree5 <- function(d) isTRUE(d <= SDM_QA_REL_TOL)
dtxt5  <- function(d) sprintf("largest relative difference %.2e", d)

# ---- 1. Hand-made cases (h1) ------------------------------------------------------
tests5 <- list("STEP 15.1" = sdm_self_test_151(),
               "STEP 15.2" = sdm_self_test_152(),
               "STEP 15.3" = sdm_self_test_153())
for (s5 in names(tests5)) {
  tt <- tests5[[s5]]
  for (i in seq_len(nrow(tt))) {
    add_q5("test case", paste0(s5, ": ", tt$check[i]),
           if (tt$pass[i]) "pass" else "FAIL", tt$pass[i])
  }
}
cat("hand-made cases:", paste(vapply(names(tests5), function(s5)
  paste0(s5, " ", sum(tests5[[s5]]$pass), " of ", nrow(tests5[[s5]])),
  character(1)), collapse = " | "), "\n")

# ---- 2. Inputs (files on disk) -------------------------------------------------------
tp_in  <- file.path(DIR_TABLES, "tbl_16_sdm_prediction.csv")
tc_in  <- file.path(DIR_TABLES, "tbl_16_sdm_reserve_check.csv")
t17_in <- file.path(DIR_TABLES, "tbl_17_reserve_suitability.csv")
for (f in c(rec_model_path, cov_path, file.path(DIR_PROCESSED, grid_out),
            file.path(DIR_PROCESSED, cellid_out), obscured_in, bg_inat_in,
            reserves_in, stats_in, pred_path, cv_tbl_in, tp_in, tc_in, t17_in,
            gitignore_in)) {
  if (!file.exists(f)) stop("STEP 15.3 needs ", f, ".", call. = FALSE)
}
mo5   <- readRDS(rec_model_path)
fit5  <- mo5$model
covs5 <- names(fit5$varmin)
cov5  <- utils::read.csv(cov_path)
cov5  <- cov5[order(cov5$id), ]
grid5 <- sf::st_drop_geometry(sf::st_read(file.path(DIR_PROCESSED, grid_out),
                                          quiet = TRUE))
cid5  <- terra::rast(file.path(DIR_PROCESSED, cellid_out))
od5   <- sf::st_drop_geometry(sf::st_read(obscured_in, quiet = TRUE))
ib5   <- sf::st_drop_geometry(sf::st_read(bg_inat_in, quiet = TRUE))
res5  <- sf::st_read(reserves_in, quiet = TRUE)
rd5   <- sf::st_drop_geometry(res5)
geom5 <- !sf::st_is_empty(res5)
st5   <- sf::st_drop_geometry(sf::st_read(stats_in, quiet = TRUE))
pl5   <- utils::read.csv(pred_path)
cv5   <- utils::read.csv(cv_tbl_in, stringsAsFactors = FALSE)
tp5   <- utils::read.csv(tp_in, stringsAsFactors = FALSE)
tc5   <- utils::read.csv(tc_in, stringsAsFactors = FALSE)
t17   <- utils::read.csv(t17_in, stringsAsFactors = FALSE)
mid5  <- sort(grid5$id[grid5$model])
key5  <- stats::setNames(grid5$id, paste(grid5$ix, grid5$iy, sep = "_"))
pres5 <- unique(unname(key5[sdm_qa_key(od5$cell02_lon_deg,
                                       od5$cell02_lat_deg)]))
pres5 <- pres5[!is.na(pres5) & pres5 %in% mid5]
bg5   <- unique(unname(key5[sdm_qa_key(ib5$cell02_lon_deg,
                                       ib5$cell02_lat_deg)]))
bg5   <- bg5[!is.na(bg5) & bg5 %in% mid5]
tpv <- function(item) {
  v <- tp5$value[tp5$item == item]
  if (length(v) == 1L) v else NA_real_
}
tcv <- function(group, item) {
  v <- tc5$value[tc5$group == group & tc5$item == item]
  if (length(v) == 1L) v else NA_real_
}

# ---- 3. The prediction (Decision 25 points 1, 2 and 4) ------------------------------
add_q5("prediction", "the layer has the fields id, value, rank, class, out_of_range only (no presence or background field)",
       paste(names(pl5), collapse = ", "),
       identical(names(pl5), c("id", "value", "rank", "class",
                               "out_of_range")))
add_q5("prediction", "the layer and the covariate table hold each model cell of the grid once",
       sprintf("%d and %d rows; %d model cells", nrow(pl5), nrow(cov5),
               length(mid5)),
       identical(as.numeric(sort(pl5$id)), as.numeric(mid5)) &&
         !anyDuplicated(pl5$id) &&
         identical(as.numeric(cov5$id), as.numeric(mid5)))
pl5 <- pl5[order(pl5$id), ]
add_q5("prediction", "the model file is the record (SDM_PRED_MODEL_FILE), of maxnet 0.1.4 (Decision 25 a1)",
       paste0(basename(rec_model_path), "; maxnet ", mo5$versions$maxnet),
       identical(basename(rec_model_path), SDM_PRED_MODEL_FILE) &&
         identical(mo5$versions$maxnet, "0.1.4"))
hv5 <- sdm_qa_cloglog(fit5, cov5[, covs5, drop = FALSE])
d <- sdm_qa_diff(pl5$value, hv5)
add_q5("prediction", "the values again by hand from the model file (clamping; link + alpha; cloglog) = the layer",
       dtxt5(d), agree5(d))
oo5 <- sdm_qa_oor(cov5[, covs5, drop = FALSE], fit5$varmin, fit5$varmax)
add_q5("prediction", "the flag again (sweep()) = out_of_range of the layer",
       sprintf("%d cells outside", sum(oo5$flag)),
       identical(oo5$flag, as.logical(pl5$out_of_range)))
pb5 <- pl5$id %in% c(pres5, bg5)
add_q5("prediction", "no presence or background cell is outside the training range (Decision 25 point 2)",
       sprintf("%d presence or background cells; %d outside", sum(pb5),
               sum(oo5$flag & pb5)),
       sum(pb5) > 0 && !any(oo5$flag & pb5))
oor_tab <- c(tpv("cells_outside"),
             vapply(paste0(covs5, "_below_min"), tpv, numeric(1)),
             vapply(paste0(covs5, "_above_max"), tpv, numeric(1)))
oor_q5 <- c(sum(oo5$flag), oo5$below[covs5], oo5$above[covs5])
add_q5("prediction", "tbl_16_sdm_prediction: the cells outside, all and by covariate = the flag again",
       sprintf("%d cells outside; table %s", sum(oo5$flag),
               format(tpv("cells_outside"))),
       identical(as.numeric(oor_q5), as.numeric(oor_tab)))
d <- sdm_qa_diff(c(tpv("min"), tpv("median"), tpv("max")),
                 c(min(hv5), stats::median(hv5), max(hv5)))
add_q5("prediction", "tbl_16_sdm_prediction: min, median and max = the values again",
       dtxt5(d), agree5(d))
mb5 <- cv5$boyce[cv5$fold == "mean"]
gt5 <- tp5$reading[tp5$group == "gate" & tp5$item == "result"]
add_q5("prediction", "the gate again: the row mean of tbl_16_sdm_cv is above SDM_BOYCE_GATE, and tbl_16_sdm_prediction says so (Decision 24 point 8)",
       sprintf("mean test Boyce %.3f; gate %s", mb5, format(SDM_BOYCE_GATE)),
       length(mb5) == 1L && isTRUE(mb5 > SDM_BOYCE_GATE) &&
         agree5(sdm_qa_diff(tpv("mean_test_boyce"), mb5)) &&
         isTRUE(tpv("gate_value") == SDM_BOYCE_GATE) && length(gt5) == 1L &&
         startsWith(gt5, "above the gate"))

# ---- 4. The classes (Decision 25 point 3) ---------------------------------------
K5 <- as.integer(SDM_PUB_N_CLASSES)
n5 <- nrow(pl5)
rc5 <- sdm_qa_rank_class(pl5$value, pl5$id, K5)
add_q5("classes", "the ranks and the classes again (other code) = the layer",
       sprintf("%d cells", n5),
       identical(rc5$rank, as.integer(pl5$rank)) &&
         identical(rc5$class, as.integer(pl5$class)))
sz_exp <- diff(c(0, ceiling(seq_len(K5) * n5 / K5)))   # classes K to 1
sz_obs <- vapply(rev(seq_len(K5)), function(j) sum(pl5$class == j), integer(1))
add_q5("classes", "the class sizes = ceiling(j n / k) - ceiling((j - 1) n / k) (classes 5 to 1)",
       paste(sz_obs, collapse = ", "),
       identical(as.numeric(sz_obs), as.numeric(sz_exp)))
top5 <- pl5$id[order(-pl5$value, pl5$id)][seq_len(
  ceiling(SDM_SENS_TOP_SHARE * n5))]
add_q5("classes", "class 5 = the top SDM_SENS_TOP_SHARE set of the sensitivity rule (the order of sdm_compare())",
       sprintf("%d cells", length(top5)),
       setequal(pl5$id[pl5$class == K5], top5))
cls_tab <- unlist(lapply(rev(seq_len(K5)), function(j) c(
  tpv(sprintf("class_%d_cells", j)), tpv(sprintf("class_%d_value_min", j)),
  tpv(sprintf("class_%d_value_max", j)))))
cls_q5 <- unlist(lapply(rev(seq_len(K5)), function(j) {
  v <- hv5[rc5$class == j]
  c(length(v), min(v), max(v))
}))
d <- sdm_qa_diff(cls_tab, cls_q5)
add_q5("classes", "tbl_16_sdm_prediction: the class sizes and value ranges = the values and classes again",
       dtxt5(d), agree5(d))
nt5 <- sum(stats::ave(as.integer(pl5$class), match(pl5$value, unique(pl5$value)),
                      FUN = function(z) length(unique(z))) > 1L)
add_q5("classes", "tbl_16_sdm_prediction: the cells in a tie across a class break, counted again",
       sprintf("%d cells; table %s", nt5,
               format(tpv("cells_tied_across_breaks"))),
       isTRUE(nt5 == tpv("cells_tied_across_breaks")))

# ---- 5. The reserves (Decision 24 point 9; Decision 25 points 7 and 8) ----------
qc5 <- sdm_qa_reserve_cells(res5, cid5)
qv5 <- sdm_qa_reserve_values(qc5, pl5, geom5, pres5)
m17 <- match(as.integer(rd5$unit_id), t17$unit_id)
f17 <- c("unit_id", "unit_name", "state", "landscape_complex", "cloglog_mean",
         "cloglog_rank", "density_2022", "n_1km_cells_used",
         "n_1km_cells_no_value")
add_q5("reserves", "tbl_17: the fields of k1 (no presence column); one row per reserve by unit_id; names, state and landscape from the reserve layer",
       sprintf("%d rows; %d reserves", nrow(t17), nrow(rd5)),
       identical(names(t17), f17) && nrow(t17) == nrow(rd5) &&
         !anyNA(m17) && !is.unsorted(t17$unit_id) &&
         identical(as.character(t17$unit_name[m17]),
                   as.character(rd5$unit_name)) &&
         identical(as.character(t17$state[m17]), as.character(rd5$state)) &&
         identical(as.character(t17$landscape_complex[m17]),
                   as.character(rd5$landscape_complex)))
nu5 <- sum(qv5$n_used[geom5] != t17$n_1km_cells_used[m17][geom5], na.rm = TRUE)
nn5 <- sum(qv5$n_no_value[geom5] != t17$n_1km_cells_no_value[m17][geom5],
           na.rm = TRUE)
add_q5("reserves", "the 1 km cells again by terra::extract(): the cells used and with no value = tbl_17 (reserves that differ)",
       sprintf("%d and %d of %d reserves differ", nu5, nn5, sum(geom5)),
       nu5 == 0L && nn5 == 0L &&
         !anyNA(t17$n_1km_cells_used[m17][geom5]) &&
         all(is.na(t17$n_1km_cells_used[m17][!geom5])))
d <- sdm_qa_diff(t17$cloglog_mean[m17], qv5$value)
add_q5("reserves", "the reserve values again = tbl_17 cloglog_mean",
       dtxt5(d), agree5(d))
rk5 <- as.integer(rank(-qv5$value, na.last = "keep", ties.method = "min"))
add_q5("reserves", "the ranks again (a tie gets the lowest rank) = tbl_17 cloglog_rank",
       sprintf("%d reserves with a rank", sum(!is.na(rk5))),
       identical(rk5, as.integer(t17$cloglog_rank[m17])))
dn5 <- st5$density_2022[match(as.integer(rd5$unit_id), as.integer(st5$unit_id))]
d <- sdm_qa_diff(t17$density_2022[m17], dn5)
add_q5("reserves", "density_2022 again from the census layer = tbl_17",
       dtxt5(d), agree5(d))
rcn_q5 <- c(nrow(rd5), sum(geom5), sum(!is.na(qv5$value)),
            sum(!is.na(qv5$value) & !is.na(dn5)),
            sum(qv5$n_used, na.rm = TRUE), sum(qv5$n_no_value, na.rm = TRUE))
rcn_tab <- c(tcv("reserves", "all"), tcv("reserves", "with_polygon"),
             tcv("reserves", "with_value"),
             tcv("reserves", "with_value_and_density"),
             tcv("cells", "cells_1km_used"), tcv("cells", "cells_1km_no_value"))
add_q5("reserves", "tbl_16_sdm_reserve_check: the reserve and cell counts again",
       paste(rcn_q5, collapse = ", "),
       identical(as.numeric(rcn_q5), as.numeric(rcn_tab)))

# ---- 6. r1 (Decision 24 point 9; p1) -----------------------------------------------
sp5 <- sdm_qa_spearman(qv5$value, dn5)
rt5 <- tc5$reading[tc5$group == "r1" & tc5$item == "result"]
re5 <- if (isTRUE(sp5[["rho"]] > 0 && sp5[["p"]] < SDM_RESERVE_P)) "agrees" else
  "no agreement shown"
d <- sdm_qa_diff(c(tcv("r1", "rho"), tcv("r1", "n"), tcv("r1", "p_value")),
                 as.numeric(sp5))
add_q5("r1", "rho, n and p again (ranks; t approximation) = tbl_16_sdm_reserve_check",
       dtxt5(d), agree5(d))
add_q5("r1", "the reading again (rho > 0 and p < SDM_RESERVE_P)",
       sprintf("%s; table: %s", re5, paste(rt5, collapse = " ")),
       length(rt5) == 1L && identical(re5, rt5))

# ---- 7. r2 under Decision 25 point 9 (y1) -------------------------------------------
cn5  <- sdm_qa_r2_counts(qv5$value, qv5$has_presence, stats::median(pl5$value))
pub5 <- all(cn5 >= SDM_PUB_R2_MIN_N)
r2r5 <- tc5[tc5$group == "r2", ]
tpub <- nrow(r2r5) > 1L
add_q5("r2", "the rule of Decision 25 point 9 again: r2 is published only if each count of the 2 x 2 table is SDM_PUB_R2_MIN_N or more; the table follows it",
       sprintf("the rule: %s; the table: %s",
               if (pub5) "published" else "not published",
               if (tpub) "published" else "not published"),
       identical(pub5, tpub) &&
         ((tpub && nrow(r2r5) == 4L) ||
            (!tpub && nrow(r2r5) == 1L &&
               startsWith(r2r5$reading[1], "r2 not published"))))
if (pub5 && tpub) {
  r2q <- c(cn5[["above_none"]] + cn5[["not_above_none"]], cn5[["above_none"]])
  r2q <- c(r2q, r2q[2] / r2q[1])
  d <- sdm_qa_diff(c(tcv("r2", "reserves_no_presence_cell"),
                     tcv("r2", "of_these_above_median"), tcv("r2", "share")),
                   r2q)
  add_q5("r2", "published r2: the counts and the share again", dtxt5(d),
         agree5(d))
}

# ---- 8. z1 (Decision 25 point 9) ----------------------------------------------------
za5 <- which(geom5 & qv5$n_used > 0 & qv5$n_hatched == qv5$n_used)
zb5 <- which(geom5 & qv5$n_used == 0)
add_q5("z1", "the two kinds counted again = tbl_16_sdm_reserve_check",
       sprintf("kind (a) %d, kind (b) %d", length(za5), length(zb5)),
       isTRUE(length(za5) == tcv("z1", "kind_a")) &&
         isTRUE(length(zb5) == tcv("z1", "kind_b")) &&
         isTRUE(length(za5) + length(zb5) == tcv("z1", "total")))
add_q5("z1", "Decision 25 point 9: no reserve whose presence state the outputs show (the total must be 0)",
       sprintf("%d reserves", length(za5) + length(zb5)),
       length(za5) + length(zb5) == 0L)

# ---- 9. Information (author's choice, task 15.5; not a check) ---------------------
hr5 <- which(!is.na(qv5$n_hatched) & qv5$n_hatched > 0)
add_q5("info", "information (task 15.5): the reserves with one or more valued 1 km cells outside the training range, and those 1 km cells summed over the reserves",
       sprintf("%d reserves; %d 1 km cells", length(hr5),
               sum(qv5$n_hatched, na.rm = TRUE)),
       TRUE)

# ---- 10. Publish checks (c1) ------------------------------------------------------
pos_re5 <- paste0("^(x|y|lon|lat|longitude|latitude|geom|geometry|cell|",
                  "cells|id|ix|iy)$|^cell_|cell02|_cell$|corner")
scan5 <- list(
  "tbl_16_sdm_prediction.csv" = list(x = tp5, num = "value", s1 = TRUE),
  "tbl_16_sdm_reserve_check.csv" = list(x = tc5, num = "value", s1 = TRUE),
  "tbl_17_reserve_suitability.csv" = list(
    x = t17, num = c("unit_id", "cloglog_mean", "cloglog_rank",
                     "density_2022", "n_1km_cells_used",
                     "n_1km_cells_no_value"), s1 = FALSE))
for (f in names(scan5)) {
  x <- scan5[[f]]$x
  bad_pos <- names(x)[grepl(pos_re5, tolower(names(x)))]
  bad_num <- setdiff(names(x)[vapply(x, is.numeric, logical(1))],
                     scan5[[f]]$num)
  add_q5("publish", paste0(f, ": (a) no position or cell column; numbers are counts or statistics"),
         if (length(c(bad_pos, bad_num)) == 0) paste(ncol(x), "columns") else
           paste("columns:", paste(unique(c(bad_pos, bad_num)),
                                   collapse = ", ")),
         length(bad_pos) == 0 && length(bad_num) == 0)
  h <- sdm_qa_id_hits(x, grid5$id)
  add_q5("publish", paste0(f, ": (b) no value is a cell id of the grid"),
         sprintf("%d values", h), h == 0)
  if (scan5[[f]]$s1) {
    rh <- sdm_qa_reserve_hits(x, rd5$unit_name)
    add_q5("publish", paste0(f, ": s1 no reserve column and no reserve name (a tbl_16 table)"),
           sprintf("%d hits", rh), rh == 0)
  }
}
add_q5("publish", "tbl_17_reserve_suitability.csv: no presence, record or tiger word in a field name (Decision 25 point 9)",
       paste(ncol(t17), "columns"),
       !any(grepl("presence|pres_|record|tiger|occ|background",
                  tolower(names(t17)))))
ap5 <- tryCatch({
  assert_publishable_table(t17, prefix = NULL,
                           name = "tbl_17_reserve_suitability.csv")
  TRUE
}, error = function(e) FALSE)
add_q5("publish", "tbl_17_reserve_suitability.csv: assert_publishable_table() passes",
       if (ap5) "pass" else "refused", ap5)
out5 <- list.files(here("outputs"), recursive = TRUE)
k <- sum(grepl("tiger", basename(out5), ignore.case = TRUE))
add_q5("publish", "(c) no file with \"tiger\" in its name under outputs/",
       sprintf("%d of %d files", k, length(out5)), k == 0)
pr5 <- normalizePath(DIR_PROCESSED, winslash = "/", mustWork = FALSE)
gi5 <- trimws(readLines(gitignore_in, warn = FALSE))
add_q5("publish", "(d) the prediction layer is under data/processed/, and .gitignore holds data/processed/**",
       basename(pred_path),
       startsWith(normalizePath(pred_path, winslash = "/", mustWork = FALSE),
                  paste0(pr5, "/")) && "data/processed/**" %in% gi5)

# ---- 11. Write the QA table, then stop on a failure ------------------------------
qa5_tbl <- do.call(rbind, q5)
h  <- sdm_qa_id_hits(qa5_tbl, grid5$id)
rh <- sdm_qa_reserve_hits(qa5_tbl, rd5$unit_name)
add_q5("publish", "tbl_16_sdm_pred_qa.csv: (b) no value is a cell id; s1 no reserve name",
       sprintf("%d and %d", h, rh), h == 0 && rh == 0)
qa5_tbl <- do.call(rbind, q5)
rownames(qa5_tbl) <- NULL
occ_assert_counts_only(qa5_tbl, cols = c("group", "check", "value", "pass"),
                       count_cols = character(0),
                       name = "tbl_16_sdm_pred_qa.csv")
write_table(qa5_tbl, nn = 16, slug = "sdm_pred_qa")
cat("\n--- QA by group ---\n")
grp5 <- unique(qa5_tbl$group)
print(data.frame(group = grp5,
                 checks = vapply(grp5, function(g) sum(qa5_tbl$group == g),
                                 integer(1)),
                 pass = vapply(grp5, function(g)
                   sum(qa5_tbl$pass[qa5_tbl$group == g]), integer(1))),
      row.names = FALSE)
cat("\ninformation (task 15.5): reserves with one or more valued 1 km cells",
    "outside the training range:", length(hr5), "| such 1 km cells in total:",
    sum(qv5$n_hatched, na.rm = TRUE), "\n")
if (length(hr5) > 0) {
  cat("By reserve (a share of the cells of the value; not a presence state):\n")
  hshow <- data.frame(unit_id = as.integer(rd5$unit_id[hr5]),
                      unit_name = rd5$unit_name[hr5],
                      cells_outside = qv5$n_hatched[hr5],
                      cells_used = qv5$n_used[hr5])
  print(hshow[order(hshow$unit_id), ], row.names = FALSE, right = FALSE)
}
if (length(za5) + length(zb5) > 0) {
  cat("\n*** NOT FOR THE DOCS (Decision 25 point 9) ***\n")
  if (length(za5) > 0) {
    cat("kind (a):", paste(rd5$unit_name[za5], collapse = "; "), "\n")
  }
  if (length(zb5) > 0) {
    cat("kind (b):", paste(rd5$unit_name[zb5], collapse = "; "), "\n")
  }
  cat("The author decides before the figures and before the commit of tbl_17.\n")
  cat("*** END ***\n")
}
n_bad5 <- sum(!qa5_tbl$pass)
if (n_bad5 > 0) {
  cat("\n--- checks that FAIL ---\n")
  bad5 <- qa5_tbl[!qa5_tbl$pass, ]
  cat(paste0(bad5$group, " | ", bad5$check, " | ", bad5$value,
             collapse = "\n"), "\n")
  stop("QA of Decision 25: ", n_bad5, " of ", nrow(qa5_tbl), " checks fail. ",
       "tbl_16_sdm_pred_qa.csv is written; find the cause before any commit.",
       call. = FALSE)
}
rule(paste0("STEP 15.3 complete: QA ", nrow(qa5_tbl), " of ", nrow(qa5_tbl),
            " checks pass (", round(as.numeric(difftime(Sys.time(), t_step153,
                                                     units = "mins")), 1),
            " min).\nCheck `git status --short` before a commit: nothing ",
            "under data/ may be staged."))

}  # end if (SDM_GRAIN_OUTCOME is a model outcome), STEP 15.3

# =============================================================================
# STEP 16.1 — the four Gi* of Decision 26 (task 16.3)
# =============================================================================
# Decision 26 with Amendment 1; process choices s1, f1, p1, r2, n1, t1 of task
# 16.2; h1 a hand-made case first. Runs in each run, after STEP 15.3 (the Gi*
# do not use the model).
#   1. the settings; the hand-made case (gistar_self_test())
#   2. the model cells; the neighbours at GISTAR_BAND_KM and at the two QA
#      bands (the great-circle distance between the cell centres of p1,
#      Amendment 1; "queen" by the cell index)
#   3. the inputs (Decision 26 point 2): effort_inat and tiger_obscured from
#      the layers that the guards read; effort_all and tiger_5km from the
#      clean layers, each record in the 0.2 degree cell of its GBIF
#      coordinates (r2: the two download zip files)
#   4. the Gi* of each input at each band; the classes (e1, m1, k1)
#   5. the four layers at GISTAR_BAND_KM (n1): written, read back, checked
#   6. the counts of Decision 26 point 7 (s1; s2 with rule L1 for tiger_5km;
#      S-a) and the table tbl_18_gistar.csv (t1)
# Console text: counts and statistics only. For the tiger Gi*, only the
# counts of Decision 26 point 7: no input count, no position, no name.

rule("STEP 16.1 — the four Gi* of Decision 26 (task 16.3)")
t_step161 <- Sys.time()

# ---- 1. The settings and the hand-made case (h1) ---------------------------------
need161 <- c("GISTAR_RUNS", "GISTAR_UNCERT_SETS", "GISTAR_CELLS", "GISTAR_VALUE",
             "GISTAR_BAND_KM", "GISTAR_SELF", "GISTAR_MIN_NEIGHBOURS",
             "GISTAR_QA_BANDS", "GISTAR_TEST", "GISTAR_P_ADJUST",
             "GISTAR_FDR_Q", "GISTAR_CLASSES", "GISTAR_TIGER_STATEMENT",
             "GISTAR_LANDSCAPE_RULE", "GISTAR_YEARS", "GISTAR_CODE",
             "GISTAR_DIST", "GISTAR_EARTH_RADIUS_KM", "GISTAR_CENTRE",
             "GISTAR_LAYER_FILES", "GISTAR_TABLE_NN", "GISTAR_TABLE_SLUG",
             "GISTAR_QA_TABLE_SLUG", "SDM_GISTAR_PUBLISH_TIGER",
             "LANDSCAPE_COMPLEXES")
miss161 <- need161[!vapply(need161, exists, logical(1))]
if (length(miss161) > 0) {
  stop("Setting(s) missing from R/00_config.R (Decision 26; task 16.2): ",
       paste(miss161, collapse = ", "), call. = FALSE)
}
sdm_run_guards(gistar_check_config(), what = "the settings of Decision 26")
st161 <- gistar_self_test()
cat("hand-made case of STEP 16.1:", sum(st161$pass), "of", nrow(st161),
    "checks pass.\n")
if (!all(st161$pass)) {
  stop("The hand-made case of STEP 16.1 failed:\n  ",
       paste(st161$check[!st161$pass], collapse = "\n  "), call. = FALSE)
}

# ---- 2. The model cells and the neighbours (Decision 26 points 3 to 5) -----------
gs_cells <- grid_d[grid_d$model, c("id", "ix", "iy")]
gs_cells <- gs_cells[order(gs_cells$id), ]
rownames(gs_cells) <- NULL
gs_n <- nrow(gs_cells)
gs_main <- paste0("band", GISTAR_BAND_KM, "_km")
gs_bands <- c(gs_main, names(GISTAR_QA_BANDS))
gs_nb <- list()
gs_nb[[gs_main]] <- gistar_neighbours(gs_cells$ix, gs_cells$iy, "band",
                                      GISTAR_BAND_KM)
for (b in names(GISTAR_QA_BANDS)) {
  gs_nb[[b]] <- if (identical(GISTAR_QA_BANDS[[b]], "queen")) {
    gistar_neighbours(gs_cells$ix, gs_cells$iy, "queen")
  } else {
    gistar_neighbours(gs_cells$ix, gs_cells$iy, "band", GISTAR_QA_BANDS[[b]])
  }
}
cat("model cells:", gs_n, "\n")
cat("neighbours of a cell (the cell itself not counted), by band:\n")
for (b in gs_bands) {
  v <- gs_nb[[b]]$n_nb
  cat(sprintf("  %-10s min %d, median %g, max %d; cells with fewer than %d: %d\n",
              b, min(v), stats::median(v), max(v), GISTAR_MIN_NEIGHBOURS,
              sum(v < GISTAR_MIN_NEIGHBOURS)))
}

# ---- 3. The inputs (Decision 26 point 2; r2 of task 16.2) ------------------------
for (f in c(tiger_clean_in, bg_clean_in, tiger_key_in, bg_key_in)) {
  if (!file.exists(f)) stop("STEP 16.1 needs ", f, ".", call. = FALSE)
}
gs_tc <- sf::st_drop_geometry(sf::st_read(tiger_clean_in, quiet = TRUE))
gs_bc <- sf::st_drop_geometry(sf::st_read(bg_clean_in, quiet = TRUE))
gs_tc <- gs_tc[gs_tc$uncert_set %in% GISTAR_UNCERT_SETS, ]
gs_bc <- gs_bc[gs_bc$uncert_set %in% GISTAR_UNCERT_SETS, ]
gs_zf <- c("gbifID", "decimalLatitude", "decimalLongitude")
gs_zt <- occ_read_fields(occ_zip_path(tiger_key_in), gs_zf)
gs_zb <- occ_read_fields(occ_zip_path(bg_key_in), gs_zf)
gs_t5 <- gistar_record_cells(gs_tc$gbifID, gs_zt)
gs_ea <- gistar_record_cells(gs_bc$gbifID, gs_zb)
rm(gs_zt, gs_zb)

gs_ei_idx <- sdm_cell_index(inat_d$cell02_lon_deg, inat_d$cell02_lat_deg)
gs_to_idx <- sdm_cell_index(obs_d$cell02_lon_deg, obs_d$cell02_lat_deg)
gs_ids <- list(
  effort_inat    = sdm_cell_id(gs_ei_idx$ix, gs_ei_idx$iy),
  tiger_obscured = sdm_cell_id(gs_to_idx$ix, gs_to_idx$iy),
  effort_all     = gs_ea$id,
  tiger_5km      = gs_t5$id
)
rm(gs_ei_idx, gs_to_idx)
gs_count <- function(ids) {
  u <- unique(ids)
  c(records = length(ids), records_not_model = sum(!ids %in% gs_cells$id),
    cells_model = sum(u %in% gs_cells$id),
    cells_not_model = sum(!u %in% gs_cells$id))
}
gs_cnt <- lapply(gs_ids, gs_count)
# The iNaturalist records of effort_all: their cell must be the cell of the
# iNaturalist layer (part "uncert"; r2 gives the same input to occ_cell02()).
gs_inat_rows <- which(gs_bc$datasetKey == SDM_BG_DATASET_KEY)
gs_m <- match(occ_id_chr(gs_bc$gbifID[gs_inat_rows]), occ_id_chr(inat_d$gbifID))
gs_eff_ids <- occ_id_chr(c(inat_d$gbifID, gs_bc$gbifID))
gs_tig_ids <- occ_id_chr(c(obs_d$gbifID, gs_tc$gbifID))
gs_yr_ok <- function(y) !anyNA(y) && all(y >= GISTAR_YEARS[1] &
                                           y <= GISTAR_YEARS[2])
sdm_run_guards(list(
  "the clean tiger layer must give the records of the tiger 5km row of tbl_15_occ_sets.csv" =
    nrow(gs_tc) == set_val("tiger", "5km", "records"),
  "the clean background layer must give the records of the background 5km row" =
    nrow(gs_bc) == set_val("background", "5km", "records"),
  "each record of the two clean layers must have its GBIF coordinates, once (r2)" =
    gs_t5$n_missing == 0 && gs_t5$n_repeat == 0 &&
    gs_ea$n_missing == 0 && gs_ea$n_repeat == 0,
  "an iNaturalist record of effort_all must have the cell of the iNaturalist layer (r2)" =
    length(gs_inat_rows) > 0 && !anyNA(gs_m) &&
    all(inat_d$part[gs_m] == "uncert") &&
    identical(gs_ea$id[gs_inat_rows], gs_ids$effort_inat[gs_m]),
  "no record of an effort input may be a tiger record (gbifID)" =
    length(intersect(gs_eff_ids, gs_tig_ids)) == 0,
  "each record must be of GISTAR_YEARS (w1)" =
    gs_yr_ok(obs_d$year) && gs_yr_ok(inat_d$year) && gs_yr_ok(gs_tc$year) &&
    gs_yr_ok(gs_bc$year),
  "effort_inat must have the background cells of STEP 14.1 (before maxnet adds a presence cell)" =
    gs_cnt$effort_inat[["cells_model"]] == cnt$n_background,
  "tiger_obscured must have the presence cells of STEP 14.1" =
    gs_cnt$tiger_obscured[["cells_model"]] == cnt$n_presence,
  "tiger_5km must have 1 or more model cells, and no more than its 1 km cells" =
    gs_cnt$tiger_5km[["cells_model"]] >= 1 &&
    gs_cnt$tiger_5km[["cells_model"]] <= set_val("tiger", "5km", "n_cells"),
  "effort_all must have 1 or more model cells and fewer than all model cells" =
    gs_cnt$effort_all[["cells_model"]] >= 1 &&
    gs_cnt$effort_all[["cells_model"]] < gs_n
), what = "the inputs of the Gi*")
rm(gs_m, gs_eff_ids, gs_tig_ids)
cat("inputs of the effort Gi* (records; records not on a model cell; model",
    "cells with a record):\n")
for (g in GISTAR_RUNS$gistar[!GISTAR_RUNS$tiger]) {
  cat(sprintf("  %-12s %s records; %s not on a model cell; %s model cells\n",
              g, format(gs_cnt[[g]][["records"]], big.mark = ","),
              format(gs_cnt[[g]][["records_not_model"]], big.mark = ","),
              format(gs_cnt[[g]][["cells_model"]], big.mark = ",")))
}

# ---- 4. The Gi* (Decision 26 point 6; e1, m1, k1) --------------------------------
gs_x <- lapply(gs_ids, function(ids) as.integer(gs_cells$id %in% ids))
gs_res <- list()
for (g in GISTAR_RUNS$gistar) {
  gs_res[[g]] <- lapply(gs_nb, function(nb) gistar_run(gs_x[[g]], nb))
}

# ---- 5. The four layers at the main band (n1) ------------------------------------
gs_pr <- normalizePath(DIR_PROCESSED, winslash = "/", mustWork = FALSE)
gs_gi <- trimws(readLines(gitignore_in, warn = FALSE))
if (!"data/processed/**" %in% gs_gi) {
  stop(".gitignore must hold data/processed/** before a Gi* layer is written.",
       call. = FALSE)
}
for (g in GISTAR_RUNS$gistar) {
  lay <- data.frame(id = gs_cells$id, gs_res[[g]][[gs_main]],
                    stringsAsFactors = FALSE)
  sdm_run_guards(gistar_layer_checks(lay, gs_cells$id),
                 what = paste0("the Gi* layer of ", g, " (in memory)"))
  out <- file.path(DIR_PROCESSED, GISTAR_LAYER_FILES[[g]])
  if (!startsWith(normalizePath(out, winslash = "/", mustWork = FALSE),
                  paste0(gs_pr, "/"))) {
    stop("A Gi* layer must be under data/processed/.", call. = FALSE)
  }
  utils::write.csv(lay, out, row.names = FALSE)
  back <- utils::read.csv(out, stringsAsFactors = FALSE)
  sdm_run_guards(c(gistar_layer_checks(back, gs_cells$id), list(
    "the layer on disk must hold the classes, K and p_two of the run" =
      identical(back$class, lay$class) &&
      identical(as.integer(back$k), lay$k) &&
      isTRUE(all.equal(back$p_two, lay$p_two, tolerance = 1e-12))
  )), what = paste0("the Gi* layer ", basename(out), " (read back)"))
}
rm(lay, back, out)
cat("layers written and read back:", length(GISTAR_LAYER_FILES), "\n")

# ---- 6. The counts of Decision 26 point 7 and tbl_18_gistar.csv (t1) -------------
gs_row <- function(gistar, band, group, item, value, reading = "") {
  data.frame(gistar = gistar, band = band, group = group, item = item,
             value = as.numeric(value), reading = reading,
             stringsAsFactors = FALSE)
}
gs_cls <- function(g, b) gs_res[[g]][[b]]$class
gs_rows <- list(
  gs_row("all", "-", "settings", "model_cells", gs_n,
         "the 0.2 degree model cells (Decision 23 point 3)"),
  gs_row("all", "-", "settings", "band_km", GISTAR_BAND_KM,
         "great-circle distance between cell centres (Decision 26 Amendment 1)"),
  gs_row("all", "-", "settings", "min_neighbours", GISTAR_MIN_NEIGHBOURS,
         "a cell with fewer neighbours has no class (k1)"),
  gs_row("all", "-", "settings", "fdr_q", GISTAR_FDR_Q,
         "Benjamini-Hochberg, for each Gi* and band (m1)"))
for (b in gs_bands) {
  v <- gs_nb[[b]]$n_nb
  gs_rows <- c(gs_rows, list(
    gs_row("all", b, "neighbours", "min", min(v), "the cell itself not counted"),
    gs_row("all", b, "neighbours", "median", stats::median(v)),
    gs_row("all", b, "neighbours", "max", max(v)),
    gs_row("all", b, "neighbours", "cells_below_min",
           sum(v < GISTAR_MIN_NEIGHBOURS), "class few_neighbours")))
}
gs_qa <- setdiff(gs_bands, gs_main)
for (i in seq_len(nrow(GISTAR_RUNS))) {
  g <- GISTAR_RUNS$gistar[i]
  tig <- GISTAR_RUNS$tiger[i]
  if (!tig) {
    for (it in c("records", "records_not_model", "cells_model",
                 "cells_not_model")) {
      gs_rows <- c(gs_rows, list(gs_row(g, "-", "input", it,
                                        gs_cnt[[g]][[it]])))
    }
  }
  # The classes at each band. A tiger Gi*: hot, cold and few_neighbours only
  # (Decision 26 point 7, s1).
  its <- if (tig) c("hot", "cold", "few_neighbours") else GISTAR_CLASSES
  for (b in gs_bands) {
    for (it in its) {
      gs_rows <- c(gs_rows, list(gs_row(g, b, "class", it,
                                        sum(gs_cls(g, b) == it))))
    }
  }
  # The QA bands (Decision 26 point 5): the share of the hot (cold) cells at
  # the main band that keep the class at the QA band; NA if there is none.
  for (b in gs_qa) {
    for (cl in c("hot", "cold")) {
      gs_rows <- c(gs_rows, list(gs_row(
        g, b, "qa_band", paste0(cl, "_same_class_share"),
        gistar_same_share(gs_cls(g, gs_main), gs_cls(g, b), cl),
        paste0("of the ", cl, " cells at ", gs_main))))
    }
  }
  # A tiger Gi* against the effort Gi* of its observer group (s1).
  if (tig) {
    e <- GISTAR_RUNS$compare[i]
    hot_t <- gs_cls(g, gs_main) == "hot"
    both <- sum(hot_t & gs_cls(e, gs_main) == "hot")
    gs_rows <- c(gs_rows, list(
      gs_row(g, gs_main, "compare", "hot_also_effort_hot", both,
             paste0("hot cells that are hot in ", e)),
      gs_row(g, gs_main, "compare", "hot_also_effort_hot_share",
             if (sum(hot_t) > 0) both / sum(hot_t) else NA_real_,
             paste0("of the hot cells; NA if there is none"))))
  }
}
# Rule L1 for tiger_5km only (s2; S-a): the hot cells by landscape complex.
gs_res_sf <- sf::st_read(reserves_in, quiet = TRUE)
gs_rc <- sdm_reserve_cells(gs_res_sf, cellid_r)
gs_res_d <- sf::st_drop_geometry(gs_res_sf)
gs_l1 <- names(GISTAR_TIGER_STATEMENT)[GISTAR_TIGER_STATEMENT == "s2"]
for (g in gs_l1) {
  lcc <- gistar_landscape_counts(
    hot_ids = gs_cells$id[gs_cls(g, gs_main) == "hot"],
    rc_id = gs_rc$id, rc_lc = gs_res_d$landscape_complex[gs_rc$res],
    levels = LANDSCAPE_COMPLEXES)
  for (r in seq_len(nrow(lcc))) {
    gs_rows <- c(gs_rows, list(gs_row(
      g, gs_main, "landscape", lcc$landscape[r], lcc$hot_cells[r],
      "hot cells by rule L1; a cell can count in two complexes")))
  }
}
gs_tbl <- do.call(rbind, gs_rows)
rownames(gs_tbl) <- NULL

# The checks of the table before it is written (Decision 26 point 7; t1).
gs_tig_rows <- gs_tbl$gistar %in% GISTAR_RUNS$gistar[GISTAR_RUNS$tiger]
gs_ok_tig <- (gs_tbl$group == "class" &
                gs_tbl$item %in% c("hot", "cold", "few_neighbours")) |
  (gs_tbl$group == "qa_band" &
     gs_tbl$item %in% c("hot_same_class_share", "cold_same_class_share")) |
  (gs_tbl$group == "compare" &
     gs_tbl$item %in% c("hot_also_effort_hot", "hot_also_effort_hot_share")) |
  (gs_tbl$group == "landscape" & gs_tbl$gistar %in% gs_l1)
gs_lc_words <- c(LANDSCAPE_COMPLEXES, "outside_reserve_polygons")
gs_lc_rows <- gs_tbl$group == "landscape"
gs_lc_text <- vapply(seq_len(nrow(gs_tbl)), function(r) {
  any(vapply(LANDSCAPE_COMPLEXES, function(w) {
    grepl(w, tolower(paste(gs_tbl$item[r], gs_tbl$reading[r])), fixed = TRUE)
  }, logical(1)))
}, logical(1))
sdm_run_guards(list(
  "a tiger row may hold only the counts of Decision 26 point 7" =
    all(gs_ok_tig[gs_tig_rows]),
  "a landscape row only for the Gi* of s2, with a level name" =
    all(gs_tbl$gistar[gs_lc_rows] %in% gs_l1) &&
    all(gs_tbl$item[gs_lc_rows] %in% gs_lc_words),
  "no landscape name outside the landscape rows (t1)" =
    !any(gs_lc_text & !gs_lc_rows),
  "no value of the table may be a cell id of the grid" =
    sdm_qa_id_hits(gs_tbl, grid_d$id) == 0,
  "no reserve name or reserve column outside the landscape rows" =
    sdm_qa_reserve_hits(gs_tbl[!gs_lc_rows, ], gs_res_d$unit_name) == 0
), what = "tbl_18_gistar.csv before the write")
occ_assert_counts_only(gs_tbl, cols = c("gistar", "band", "group", "item",
                                        "value", "reading"),
                       count_cols = character(0), name = "tbl_18_gistar.csv")
write_table(gs_tbl, nn = GISTAR_TABLE_NN, slug = GISTAR_TABLE_SLUG)

cat("\n--- tbl_18_gistar.csv (publishable; counts and statistics only) ---\n")
gs_show <- gs_tbl[gs_tbl$group != "settings", c("gistar", "band", "group",
                                                 "item", "value")]
gs_show$value <- vapply(gs_show$value, function(v) {
  if (is.na(v)) "NA" else if (v == round(v)) {
    formatC(v, format = "d", big.mark = ",")
  } else sprintf("%.3f", v)
}, character(1))
op161 <- options(width = 120)
print(gs_show, row.names = FALSE, right = FALSE)
options(op161)
rm(gs_tc, gs_bc, gs_x, gs_show, gs_rc, gs_res_sf, op161)
rule(paste0("STEP 16.1 complete (", round(as.numeric(difftime(
  Sys.time(), t_step161, units = "mins")), 1), " min): four Gi* layers ",
  "under data/processed/ (gitignored) and tbl_18_gistar.csv.\nNext: STEP ",
  "16.2, the figures (task 16.4). Check `git status --short` before a ",
  "commit: nothing under data/ may be staged."))

# =============================================================================
# STEP 16.2 — the figures fig_04, fig_05 and fig_06 (task 16.4)
# =============================================================================
# Decision 25 points 4 to 6; Decision 26 point 7 (with k-a); process choices
# g1, z1, c1, h1, k1, d1 of task 16.2; h1 a hand-made case first. fig_04 and
# fig_05 only with a model outcome (the gate of Decision 24 point 8 is open:
# STEP 15.1 stops the script if it is closed).
#   1. the settings; the packages; the hand-made case (fig_self_test())
#   2. the read guard (k1): the files of each figure, and the tables and the
#      DOI files of the captions; each read is recorded
#   3. the drawing tables: the model cells with the prediction layer (fig_04,
#      fig_05) and with the effort_inat Gi* layer (fig_06); the hatch (h1)
#   4. the caption drafts (d1): each number from a table or a layer
#   5. the checks (a failure stops the step before a file is written)
#   6. the three PNG files; their size read back from the file
# Console text: counts, statistics and the title, subtitle and caption drafts
# (marked DRAFT). No position.

rule("STEP 16.2 — the figures fig_04, fig_05 and fig_06 (task 16.4)")
t_step162 <- Sys.time()

# ---- 1. The settings, the packages and the hand-made case (h1) -----------------
need162 <- c("SDM_PUB_FIG_CLASS", "SDM_PUB_FIG_VALUE", "SDM_PUB_VALUE_LABEL",
             "SDM_PUB_HATCH", "SDM_PUB_N_CLASSES", "GISTAR_PUB_FIG",
             "GISTAR_PUB_FIG_GISTAR", "SDM_PUB_FIG_CLASS_SLUG",
             "SDM_PUB_FIG_VALUE_SLUG", "GISTAR_PUB_FIG_SLUG",
             "FIG_STAGE3_SIZE_IN", "FIG_STAGE3_DPI", "FIG_STAGE3_PALETTE",
             "FIG_HATCH_LINES_PER_CELL", "FIG_HATCH_KEY_POS",
             "FIG_GISTAR_COLOURS", "FIG_FRAME_COLOURS")
miss162 <- need162[!vapply(need162, exists, logical(1))]
if (length(miss162) > 0) {
  stop("Setting(s) missing from R/00_config.R (Decisions 25 and 26; tasks ",
       "16.2 and 16.4): ", paste(miss162, collapse = ", "), call. = FALSE)
}
for (pk in c("ggplot2", "viridisLite")) {
  if (!requireNamespace(pk, quietly = TRUE)) {
    stop("STEP 16.2 needs the package ", pk, " (in renv.lock). Run ",
         "renv::restore().", call. = FALSE)
  }
}
suppressPackageStartupMessages(library(ggplot2))
fig_slugs <- c(SDM_PUB_FIG_CLASS_SLUG, SDM_PUB_FIG_VALUE_SLUG,
               GISTAR_PUB_FIG_SLUG)
sdm_run_guards(list(
  "the figure numbers must be 4, 5 and 6 (Decision 25 f3; Decision 26 f1)" =
    SDM_PUB_FIG_CLASS == 4 && SDM_PUB_FIG_VALUE == 5 && GISTAR_PUB_FIG == 6,
  "no figure slug may hold the word tiger (g1)" =
    !any(grepl("tiger", fig_slugs, ignore.case = TRUE)),
  "fig_06 must draw the effort_inat Gi* (Decision 26 f1)" =
    identical(GISTAR_PUB_FIG_GISTAR, "effort_inat") &&
    !grepl("tiger", GISTAR_LAYER_FILES[[GISTAR_PUB_FIG_GISTAR]]),
  "the hatch must be on (Decision 25 b2)" = isTRUE(SDM_PUB_HATCH),
  "FIG_GISTAR_COLOURS must name the four classes" =
    identical(names(FIG_GISTAR_COLOURS), GISTAR_CLASSES),
  "FIG_FRAME_COLOURS must name ink, paper, state_fill and state_line" =
    identical(names(FIG_FRAME_COLOURS),
              c("ink", "paper", "state_fill", "state_line")),
  "FIG_HATCH_LINES_PER_CELL must be a whole number of 1 or more" =
    is.numeric(FIG_HATCH_LINES_PER_CELL) &&
    FIG_HATCH_LINES_PER_CELL >= 1 &&
    FIG_HATCH_LINES_PER_CELL == round(FIG_HATCH_LINES_PER_CELL)
), what = "the settings of the figures")
st162 <- fig_self_test()
cat("hand-made case of STEP 16.2:", sum(st162$pass), "of", nrow(st162),
    "checks pass.\n")
if (!all(st162$pass)) {
  stop("The hand-made case of STEP 16.2 failed:\n  ",
       paste(st162$check[!st162$pass], collapse = "\n  "), call. = FALSE)
}
fig_do_sdm <- SDM_GRAIN_OUTCOME %in% c("reduced_model", "planned_model")
fig_ink   <- FIG_FRAME_COLOURS[["ink"]]
fig_paper <- FIG_FRAME_COLOURS[["paper"]]

# ---- 2. The read guard (k1 of task 16.2) ----------------------------------------
# One list for each figure and one for the captions. A read of a file that is
# not on the list stops the step; each read is recorded and printed.
fig_grid_in <- file.path(DIR_PROCESSED, grid_out)
fig_hot_in  <- file.path(DIR_PROCESSED,
                         GISTAR_LAYER_FILES[[GISTAR_PUB_FIG_GISTAR]])
fig_tab <- function(slug) file.path(DIR_TABLES, paste0(slug, ".csv"))
fig_lists <- list(
  fig_04_05 = c(pred_path, fig_grid_in, reserves_in, states_in),
  fig_06    = c(fig_hot_in, fig_grid_in, reserves_in, states_in),
  caption   = c(fig_tab("tbl_16_sdm_counts"), fig_tab("tbl_16_sdm_cv"),
                fig_tab("tbl_16_sdm_sensitivity"),
                fig_tab("tbl_16_sdm_prediction"),
                fig_tab("tbl_16_sdm_reserve_check"),
                fig_tab(sprintf("tbl_%02d_%s", GISTAR_TABLE_NN,
                                GISTAR_TABLE_SLUG)),
                tiger_doi_in, bg_doi_in))
fig_need <- unique(unlist(if (fig_do_sdm) fig_lists else
  list(fig_lists$fig_06, fig_tab("tbl_16_sdm_counts"),
       fig_tab(sprintf("tbl_%02d_%s", GISTAR_TABLE_NN, GISTAR_TABLE_SLUG)),
       bg_doi_in)))
fig_miss <- fig_need[!file.exists(fig_need)]
if (length(fig_miss) > 0) {
  stop("STEP 16.2 needs:\n  ", paste(fig_miss, collapse = "\n  "),
       call. = FALSE)
}
fig_rd <- fig_reader(fig_lists)

# The tables and the DOI files of the captions (statistics and text only).
# The tables of the model and the tiger DOI only with a model outcome.
fig_t_counts <- fig_rd$read(fig_tab("tbl_16_sdm_counts"), "caption")
fig_t_gs     <- fig_rd$read(fig_tab(sprintf("tbl_%02d_%s", GISTAR_TABLE_NN,
                                            GISTAR_TABLE_SLUG)), "caption")
fig_doi <- function(txt) {
  d <- sub("^DOI:\\s*", "", grep("^DOI:", txt, value = TRUE))
  if (length(d) != 1L || !nzchar(d)) {
    stop("A GBIF DOI file must hold one line \"DOI: ...\".", call. = FALSE)
  }
  d
}
fig_doi_b <- fig_doi(fig_rd$read(bg_doi_in, "caption"))
if (fig_do_sdm) {
  fig_t_cv   <- fig_rd$read(fig_tab("tbl_16_sdm_cv"), "caption")
  fig_t_sens <- fig_rd$read(fig_tab("tbl_16_sdm_sensitivity"), "caption")
  fig_t_pred <- fig_rd$read(fig_tab("tbl_16_sdm_prediction"), "caption")
  fig_t_rchk <- fig_rd$read(fig_tab("tbl_16_sdm_reserve_check"), "caption")
  fig_doi_t  <- fig_doi(fig_rd$read(tiger_doi_in, "caption"))
}
fig_val <- function(t, group, item, col = "value") {
  v <- t[[col]][t$group == group & t$item == item]
  if (length(v) != 1L) {
    stop("A caption value is not in its table: ", group, " / ", item,
         call. = FALSE)
  }
  v
}
fig_gs <- function(gistar, band, group, item) {
  v <- fig_t_gs$value[fig_t_gs$gistar == gistar & fig_t_gs$band == band &
                        fig_t_gs$group == group & fig_t_gs$item == item]
  if (length(v) != 1L) {
    stop("A value is not in tbl_18_gistar.csv: ", gistar, " / ", band, " / ",
         group, " / ", item, call. = FALSE)
  }
  v
}

# ---- 3. The drawing tables and the hatch (h1) -------------------------------------
fig_cells_of <- function(grid) {
  g <- grid[as.logical(grid$model), "id"]
  g[order(g$id), ]
}
fig_area_range <- function(ids) {         # km2 on the WGS 84 ellipsoid
  iy <- ids %/% SDM_ID_BASE
  a <- fig_quad_area_km2(iy * SDM_GRAIN_DEG, (iy + 1) * SDM_GRAIN_DEG,
                         SDM_GRAIN_DEG)
  range(a)
}
fig_geom_only <- function(x) {
  g <- sf::st_geometry(x)
  sf::st_sf(geometry = g[!sf::st_is_empty(g)])
}
# fig_06: the effort_inat Gi* (always).
fig_g6     <- fig_cells_of(fig_rd$read(fig_grid_in, "fig_06"))
fig_hot    <- fig_rd$read(fig_hot_in, "fig_06")
fig_res6   <- fig_geom_only(fig_rd$read(reserves_in, "fig_06"))
fig_st6    <- fig_rd$read(states_in, "fig_06")
fig_m6     <- match(fig_g6$id, fig_hot$id)
fig_c6 <- sf::st_sf(class = factor(fig_hot$class[fig_m6],
                                   levels = GISTAR_CLASSES),
                    geometry = sf::st_geometry(fig_g6))
fig_states_g <- fig_geom_only(fig_st6)
fig_bb <- sf::st_bbox(fig_st6)
fig_area <- fig_area_range(fig_g6$id)
fig_side <- sqrt(stats::median(as.numeric(sf::st_area(fig_g6))))
fig_step <- 2 * fig_side / FIG_HATCH_LINES_PER_CELL
# fig_04 and fig_05: the prediction (model outcome only).
if (fig_do_sdm) {
  fig_g45  <- fig_cells_of(fig_rd$read(fig_grid_in, "fig_04_05"))
  fig_pred <- fig_rd$read(pred_path, "fig_04_05")
  fig_res45 <- fig_geom_only(fig_rd$read(reserves_in, "fig_04_05"))
  fig_st45 <- fig_rd$read(states_in, "fig_04_05")
  fig_m45  <- match(fig_g45$id, fig_pred$id)
  fig_c45 <- sf::st_sf(
    class = factor(as.character(fig_pred$class[fig_m45]),
                   levels = as.character(SDM_PUB_N_CLASSES:1)),
    value = fig_pred$value[fig_m45],
    out_of_range = as.logical(fig_pred$out_of_range[fig_m45]),
    geometry = sf::st_geometry(fig_g45))
  fig_hatch <- fig_hatch_lines(sf::st_geometry(fig_c45)[fig_c45$out_of_range],
                               fig_step)
  fig_hatch_sf <- sf::st_sf(geometry = fig_hatch)
  fig_w <- fig_bb[["xmax"]] - fig_bb[["xmin"]]
  fig_h <- fig_bb[["ymax"]] - fig_bb[["ymin"]]
  fig_key_x <- fig_bb[["xmin"]] + FIG_HATCH_KEY_POS[["x"]] * fig_w
  fig_key_y <- fig_bb[["ymin"]] + FIG_HATCH_KEY_POS[["y"]] * fig_h
  fig_kb <- fig_key_box(fig_key_x, fig_key_y, 3 * fig_side, fig_step,
                        sf::st_crs(fig_st45))
}

# ---- 4. The caption drafts (d1) -----------------------------------------------------
fig_deg <- "\u00b0"; fig_km2 <- "km\u00b2"; fig_dash <- "\u2013"
fig_area_txt <- paste0(fig_fmt_int(fig_area[1]), fig_dash,
                       fig_fmt_int(fig_area[2]), " ", fig_km2)
fig_n_model <- nrow(fig_g6)
fig_outlines <- paste0(
  "Reserve outlines: the core protected-area polygons of the NTCA (Decision ",
  "4), not the notified total area. State lines: Natural Earth ",
  "(approximate).")
if (fig_do_sdm) {
  fig_n_pres <- fig_val(fig_t_counts, "presence", "cells_model")
  fig_n_bg   <- fig_val(fig_t_counts, "background", "cells_model")
  fig_boyce  <- fig_t_cv$boyce[fig_t_cv$fold == "mean"]
  fig_auc    <- fig_t_cv$auc_test[fig_t_cv$fold == "mean"]
  fig_ov     <- fig_t_sens$top_overlap
  fig_noor   <- sum(fig_c45$out_of_range)
  fig_rho    <- fig_val(fig_t_rchk, "r1", "rho")
  fig_rn     <- fig_val(fig_t_rchk, "r1", "n")
  fig_rp     <- fig_val(fig_t_rchk, "r1", "p_value")
  fig_rread  <- fig_val(fig_t_rchk, "r1", "result", "reading")
  fig_cap45 <- function(how_to_read) fig_wrap(list(
    paste0("Relative habitat suitability for tigers from a maxnet model at ",
           "the 0.2", fig_deg, " grain (cells of about 20 km; ", fig_area_txt,
           "), on ", fig_fmt_int(fig_n_model), " model cells. It is not ",
           "occupancy (Decision 1) and not a probability of presence."),
    paste0("Presences: the iNaturalist tiger records, obscured by the source ",
           "to their 0.2", fig_deg, " cell, in ", fig_fmt_int(fig_n_pres),
           " cells. Background: the iNaturalist mammal records, in ",
           fig_fmt_int(fig_n_bg), " cells. The records show where people ",
           "photograph and upload animals; the background corrects this ",
           "effort bias in part, not fully (proposal \u00a77)."),
    how_to_read,
    paste0("Sensitivity runs: ", fig_fmt(fig_ov[1]), " and ",
           fig_fmt(fig_ov[2]), " of the top-20 % cells of the main model are ",
           "also in the top 20 % of the two runs."),
    paste0("Evaluation: a mean test Boyce index of ", fig_fmt(fig_boyce),
           " over ", SDM_CV_K, " folds of ", SDM_CV_BLOCK_DEG, fig_deg,
           " spatial blocks (repeated P/E values kept; not the ",
           "ecospat.boyce() default) and a mean test AUC of ",
           fig_fmt(fig_auc), "."),
    paste0("Hatch: the ", fig_noor, " cells outside the training range of ",
           "one or more covariates; their values are clamped. A blank cell ",
           "is not a model cell (less than ",
           round(100 * SDM_CELL_MIN_COVER), " % complete-case cover: a value ",
           "of each covariate)."),
    fig_outlines,
    paste0("Reserve check: \"", fig_rread, "\" by the rule of the project ",
           "(Spearman rho ", fig_fmt(fig_rho), " between the reserve value ",
           "and the 2022 census density; n = ", fig_fmt_int(fig_rn),
           " reserves; p = ", fig_fmt(fig_rp), ")."),
    paste0("Sources: GBIF occurrence downloads ", fig_doi_t, " (tiger) and ",
           fig_doi_b, " (mammals), iNaturalist research-grade observations; ",
           "ESA WorldCover 2021; Global Human Modification 2022; terrain ",
           "AWS Terrain Tiles; OpenStreetMap data \u00a9 OpenStreetMap ",
           "contributors (ODbL).")))
  fig_title45 <- "Modelled relative habitat suitability for tigers in India"
  fig_sub04 <- paste0("Five classes of equal size by rank of the model ",
                      "output, on ", fig_fmt_int(fig_n_model), " cells of 0.2",
                      fig_deg, ". Hatch: ", fig_noor, " cells outside the ",
                      "training range.")
  fig_sub05 <- paste0("The model output (cloglog) on ",
                      fig_fmt_int(fig_n_model), " cells of 0.2", fig_deg,
                      ": relative, not a probability of presence. Hatch: ",
                      fig_noor, " cells outside the training range.")
  fig_cap04 <- fig_cap45(paste0(
    "Classes: five classes of equal size by the rank of the model output; ",
    "each class holds 20 % of the model cells. The legend gives no model ",
    "value."))
  fig_cap05 <- fig_cap45(paste0(
    "Colour: the ", SDM_PUB_VALUE_LABEL, "."))
}
fig_n6 <- vapply(GISTAR_CLASSES, function(k) sum(fig_c6$class == k),
                 numeric(1))
fig_m_eff <- fig_gs(GISTAR_PUB_FIG_GISTAR, "-", "input", "cells_model")
fig_nb_in <- fig_gs("all", paste0("band", GISTAR_BAND_KM, "_km"),
                    "neighbours", "max")
fig_qa_names <- setdiff(unique(fig_t_gs$band[fig_t_gs$group == "qa_band"]),
                        "-")
fig_share <- vapply(fig_qa_names, function(b) {
  fig_gs(GISTAR_PUB_FIG_GISTAR, b, "qa_band", "hot_same_class_share")
}, numeric(1))
# k-a (2026-11-07): the cold count at the QA band(s) of a distance (75 km).
fig_qa_km <- paste0("band", unlist(GISTAR_QA_BANDS[vapply(
  GISTAR_QA_BANDS, is.numeric, logical(1))]), "_km")
fig_cold_qa <- vapply(fig_qa_km, function(b) {
  fig_gs(GISTAR_PUB_FIG_GISTAR, b, "class", "cold")
}, numeric(1))
fig_band_txt <- function(b) {
  if (identical(b, "queen")) "the queen neighbours" else
    paste0("a band of ", sub("^band([0-9.]+)_km$", "\\1", b), " km")
}
fig_cold_note <- if (fig_n6[["cold"]] == 0) {
  paste0(" No cell is cold at ", GISTAR_BAND_KM, " km; with ",
         paste(vapply(fig_qa_km, function(b) {
           paste0(fig_band_txt(b), " (QA), ", fig_fmt_int(fig_cold_qa[[b]]),
                  " cells are cold")
         }, character(1)), collapse = "; with "), ".")
} else ""
fig_cap06 <- fig_wrap(list(
  paste0("The Getis", fig_dash, "Ord Gi* of the iNaturalist mammal records ",
         "(tiger excluded) at the 0.2", fig_deg, " grain (cells of ",
         fig_area_txt, "), ", GISTAR_YEARS[1], fig_dash, GISTAR_YEARS[2],
         ". It shows clusters of cells with records. It does not show search ",
         "effort or animals."),
  paste0("Input: the ", fig_fmt_int(fig_m_eff), " model cells with one or ",
         "more records, of ", fig_fmt_int(fig_n_model), " model cells; the ",
         "source obscured part of the records to their 0.2", fig_deg,
         " cell. The presence cells of the model are not in the input; the ",
         "figure uses no tiger record."),
  paste0("Neighbours: the cells within ", GISTAR_BAND_KM, " km (great-circle ",
         "distance between cell centres; ", fig_nb_in, " neighbours for an ",
         "inner cell), the cell itself included. A cell with fewer than ",
         GISTAR_MIN_NEIGHBOURS, " neighbours has no class (",
         fig_fmt_int(fig_n6[["few_neighbours"]]), " cells)."),
  paste0("Test: the exact p-value under random relabelling of the cells, ",
         "with a false discovery rate (Benjamini", fig_dash, "Hochberg) of ",
         GISTAR_FDR_Q, ": ", fig_fmt_int(fig_n6[["hot"]]), " hot cells, ",
         fig_fmt_int(fig_n6[["cold"]]), " cold cells, ",
         fig_fmt_int(fig_n6[["not_significant"]]),
         " cells not significant.", fig_cold_note),
  "A blank cell is not a model cell.",
  paste0("QA bands: the share of the hot cells that stay hot is ",
         paste(vapply(fig_qa_names, function(b) {
           paste0(round(100 * fig_share[[b]]), " % with ", fig_band_txt(b))
         }, character(1)), collapse = " and "), "."),
  paste0("The records show where people record mammals on iNaturalist. A ",
         "place with no record can still have been visited, and a cluster ",
         "mixes effort with where mammals are (proposal \u00a77)."),
  fig_outlines,
  paste0("Source: GBIF occurrence download ", fig_doi_b, " (mammals), ",
         "iNaturalist research-grade observations.")))
fig_title06 <- paste0("Clusters of iNaturalist mammal records (Getis",
                      fig_dash, "Ord Gi*, ", GISTAR_BAND_KM, " km)")
fig_sub06 <- paste0(fig_fmt_int(fig_n6[["hot"]]), " hot cells and ",
                    fig_fmt_int(fig_n6[["cold"]]), " cold cells of ",
                    fig_fmt_int(fig_n_model), " model cells of 0.2", fig_deg,
                    ". Tiger records are not used.")

# ---- 5. The checks (stop before a file is written) --------------------------------
fig_cls_tbl <- function(k) fig_val(fig_t_pred, "class",
                                   paste0("class_", k, "_cells"))
fig_chk <- list(
  "fig_06: one row for each model cell, each with a class" =
    nrow(fig_c6) == fig_val(fig_t_counts, "grid", "model_cells") &&
    !anyNA(fig_m6) && !anyNA(fig_c6$class),
  "fig_06: the class counts are the counts of tbl_18_gistar.csv (main band)" =
    all(vapply(GISTAR_CLASSES, function(k) {
      fig_n6[[k]] == fig_gs(GISTAR_PUB_FIG_GISTAR,
                            paste0("band", GISTAR_BAND_KM, "_km"), "class", k)
    }, logical(1))),
  "fig_06: no field of the drawn table holds a presence, record or tiger word" =
    fig_fields_ok(fig_c6) && fig_fields_ok(fig_hot),
  "the reserve outlines and the state lines are geometry only" =
    identical(names(fig_res6), "geometry") &&
    identical(names(fig_states_g), "geometry"),
  "the read log: each figure read only the files of its list (k1)" =
    all(fig_rd$log()$fig %in% names(fig_lists))
)
if (fig_do_sdm) {
  fig_chk <- c(fig_chk, list(
    "fig_04/05: one row for each model cell, each with a class and a value" =
      nrow(fig_c45) == nrow(fig_g6) && !anyNA(fig_m45) &&
      !anyNA(fig_c45$class) && !anyNA(fig_c45$value),
    "fig_04/05: the class sizes are those of tbl_16_sdm_prediction.csv" =
      all(vapply(SDM_PUB_N_CLASSES:1, function(k) {
        sum(fig_c45$class == as.character(k)) == fig_cls_tbl(k)
      }, logical(1))),
    "fig_04/05: the hatched cells are the cells outside the training range of tbl_16_sdm_prediction.csv" =
      fig_noor == fig_val(fig_t_pred, "range", "cells_outside"),
    "fig_04/05: each hatched cell holds one or more hatch lines" =
      fig_noor == 0 ||
      all(lengths(sf::st_intersects(
        sf::st_geometry(fig_c45)[fig_c45$out_of_range], fig_hatch)) > 0),
    "fig_04/05: no field of the drawn table holds a presence, record or tiger word" =
      fig_fields_ok(fig_c45) && fig_fields_ok(fig_pred),
    "fig_04/05: the gate is open (Decision 24 point 8)" =
      fig_val(fig_t_pred, "gate", "mean_test_boyce") > SDM_BOYCE_GATE,
    "fig_04/05: the key box is inside the frame" =
      fig_key_x + 3 * fig_side < fig_bb[["xmax"]] &&
      fig_key_y + 3 * fig_side < fig_bb[["ymax"]]
  ))
}
for (i in seq_along(fig_chk)) {
  cat(sprintf("  %-4s %s\n", if (isTRUE(fig_chk[[i]])) "ok" else "FAIL",
              names(fig_chk)[i]))
}
if (!all(vapply(fig_chk, isTRUE, logical(1)))) {
  stop("Figure check(s) failed. No figure is written.", call. = FALSE)
}

# ---- 6. The three figures (z1, c1, h1) ----------------------------------------------
fig_frame <- function(cells, fill_scale, colour_scale, aes_fill, res, st,
                      title, subtitle, caption, hatch = NULL, key = NULL,
                      key_label = NULL) {
  p <- ggplot() +
    geom_sf(data = st, fill = FIG_FRAME_COLOURS[["state_fill"]],
            colour = NA) +
    geom_sf(data = cells, mapping = aes_fill, linewidth = 0.05) +
    geom_sf(data = st, fill = NA, colour = FIG_FRAME_COLOURS[["state_line"]],
            linewidth = 0.25) +
    geom_sf(data = res, fill = NA, colour = "white", linewidth = 0.7) +
    geom_sf(data = res, fill = NA, colour = fig_ink, linewidth = 0.3)
  if (!is.null(hatch) && nrow(hatch) > 0) {
    p <- p + geom_sf(data = hatch, colour = "white", linewidth = 0.6) +
      geom_sf(data = hatch, colour = fig_ink, linewidth = 0.25)
  }
  if (!is.null(key)) {
    p <- p +
      geom_sf(data = sf::st_sf(geometry = key$square), fill = fig_paper,
              colour = fig_ink, linewidth = 0.3) +
      geom_sf(data = sf::st_sf(geometry = key$hatch), colour = fig_ink,
              linewidth = 0.25) +
      annotate("text", x = fig_key_x + 3.6 * fig_side,
               y = fig_key_y + 1.5 * fig_side, label = key_label, hjust = 0,
               vjust = 0.5, size = 2.8, colour = fig_ink, lineheight = 1.05)
  }
  p + fill_scale + colour_scale +
    coord_sf(crs = sf::st_crs(st), datum = NA,
             xlim = c(fig_bb[["xmin"]], fig_bb[["xmax"]]),
             ylim = c(fig_bb[["ymin"]], fig_bb[["ymax"]])) +
    labs(title = title, subtitle = subtitle, caption = caption) +
    fig_theme(fig_ink, fig_paper)
}
fig_save <- function(p, nn, slug) {
  if (!dir.exists(DIR_FIGURES)) dir.create(DIR_FIGURES, recursive = TRUE)
  path <- file.path(DIR_FIGURES, sprintf("fig_%02d_%s.png", nn, slug))
  ggsave(path, plot = p, width = FIG_STAGE3_SIZE_IN[["width"]],
         height = FIG_STAGE3_SIZE_IN[["height"]], dpi = FIG_STAGE3_DPI,
         bg = fig_paper)
  want <- round(FIG_STAGE3_SIZE_IN * FIG_STAGE3_DPI)
  got <- fig_png_size(path)
  if (!all(got == want)) {
    stop("The figure ", basename(path), " has ", got[1], " x ", got[2],
         " pixels, not ", want[1], " x ", want[2], ".", call. = FALSE)
  }
  message("Wrote ", path, " (", got[1], " x ", got[2], " pixels)")
  invisible(path)
}
fig_written <- character(0)
if (fig_do_sdm) {
  fig_pal5 <- stats::setNames(viridisLite::viridis(SDM_PUB_N_CLASSES,
                                                   option = FIG_STAGE3_PALETTE),
                              as.character(1:SDM_PUB_N_CLASSES))
  fig_key_label <- paste0("Outside the training range of\none or more ",
                          "covariates (", fig_noor, " cells)")
  fig_p04 <- fig_frame(
    fig_c45,
    scale_fill_manual(values = fig_pal5,
                      breaks = as.character(SDM_PUB_N_CLASSES:1),
                      labels = fig_class_labels(SDM_PUB_N_CLASSES),
                      drop = FALSE,
                      name = "Relative suitability\n(class by rank)"),
    scale_colour_manual(values = fig_pal5, guide = "none"),
    aes(fill = class, colour = class), fig_res45,
    fig_geom_only(fig_st45), fig_title45, fig_sub04, fig_cap04,
    hatch = fig_hatch_sf, key = fig_kb, key_label = fig_key_label)
  fig_p05 <- fig_frame(
    fig_c45,
    scale_fill_viridis_c(option = FIG_STAGE3_PALETTE, limits = c(0, 1),
                         breaks = seq(0, 1, 0.25),
                         name = paste(strwrap(SDM_PUB_VALUE_LABEL, 24),
                                      collapse = "\n")),
    scale_colour_viridis_c(option = FIG_STAGE3_PALETTE, limits = c(0, 1),
                           guide = "none"),
    aes(fill = value, colour = value), fig_res45,
    fig_geom_only(fig_st45), fig_title45, fig_sub05, fig_cap05,
    hatch = fig_hatch_sf, key = fig_kb, key_label = fig_key_label)
  fig_written <- c(fig_written,
                   fig_save(fig_p04, SDM_PUB_FIG_CLASS, SDM_PUB_FIG_CLASS_SLUG),
                   fig_save(fig_p05, SDM_PUB_FIG_VALUE, SDM_PUB_FIG_VALUE_SLUG))
}
fig_lab6 <- c(hot = "Hot", cold = "Cold", not_significant = "Not significant",
              few_neighbours = paste0("Fewer than ", GISTAR_MIN_NEIGHBOURS,
                                      " neighbours"))
fig_lab6 <- paste0(fig_lab6[GISTAR_CLASSES], " (",
                   vapply(fig_n6, fig_fmt_int, character(1)), ")")
fig_p06 <- fig_frame(
  fig_c6,
  scale_fill_manual(values = FIG_GISTAR_COLOURS, breaks = GISTAR_CLASSES,
                    labels = fig_lab6, drop = FALSE,
                    name = paste0("Gi* class (", GISTAR_BAND_KM, " km;\n",
                                  "cells of 0.2", fig_deg, ")")),
  scale_colour_manual(values = FIG_GISTAR_COLOURS, guide = "none"),
  aes(fill = class, colour = class), fig_res6, fig_states_g, fig_title06,
  fig_sub06, fig_cap06)
fig_written <- c(fig_written,
                 fig_save(fig_p06, GISTAR_PUB_FIG, GISTAR_PUB_FIG_SLUG))

cat("\nfiles read by the figure code (k1):\n")
print(fig_rd$log(), row.names = FALSE, right = FALSE)
if (fig_do_sdm) {
  cat(sprintf("\nfig_%02d and fig_%02d: %s model cells; classes 5 to 1: %s;",
              SDM_PUB_FIG_CLASS, SDM_PUB_FIG_VALUE, fig_fmt_int(nrow(fig_c45)),
              paste(vapply(SDM_PUB_N_CLASSES:1, function(k) {
                fig_fmt_int(sum(fig_c45$class == as.character(k)))
              }, character(1)), collapse = ", ")),
      "hatched cells:", fig_noor, "| hatch lines:", length(fig_hatch), "\n")
}
cat(sprintf("fig_%02d: hot %s, cold %s, not significant %s, fewer than %d neighbours %s\n",
            GISTAR_PUB_FIG, fig_fmt_int(fig_n6[["hot"]]),
            fig_fmt_int(fig_n6[["cold"]]),
            fig_fmt_int(fig_n6[["not_significant"]]), GISTAR_MIN_NEIGHBOURS,
            fig_fmt_int(fig_n6[["few_neighbours"]])))
cat("\n*** DRAFT text for the author's edit (title, subtitle, caption) ***\n")
if (fig_do_sdm) {
  cat("\n[fig_04]\n", fig_title45, "\n", fig_sub04, "\n", fig_cap04, "\n",
      sep = "")
  cat("\n[fig_05]\n", fig_title45, "\n", fig_sub05, "\n", fig_cap05, "\n",
      sep = "")
}
cat("\n[fig_06]\n", fig_title06, "\n", fig_sub06, "\n", fig_cap06, "\n",
    sep = "")
cat("*** END OF DRAFT ***\n")
rule(paste0("STEP 16.2 complete (", round(as.numeric(difftime(
  Sys.time(), t_step162, units = "mins")), 1), " min): ",
  length(fig_written), " figures in outputs/figures/.\nNext: STEP 16.3, the QA ",
  "(task 16.5). Check `git status --short` before a commit: nothing under ",
  "data/ may be staged."))
