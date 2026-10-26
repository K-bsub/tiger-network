# =============================================================================
# 08_prepare_occurrences.R  [STAGE 3 — HABITAT SUITABILITY, Week 13]
# Occurrence records and effort for Stage 3 (process choice s1, 2026-10-11:
# one script for Week 13; the model script gets its name in Week 14, after
# the outcome of Decision 21 point 8). Each task adds its own STEP block:
#
#   STEP 13.1 (task 13.2)  the raw state of the two GBIF files, in two stages
#                          (process choice g1):
#                 "names"  header fields and the distinct values of the rule
#                          fields. NO count of records. The author confirms
#                          that Decision 21 needs no amendment.
#                 "counts" the entry state (Decision 21 point 1, step 0), its
#                          guards, and the raw counts by each rule field
#                          -> tbl_15_occ_raw_counts.csv
#   STEP 13.2 (task 13.3)  Decision 21 on the tiger records: the nine rule
#                          steps, the 1 km and 5 km sets, the obscured set,
#                          the presence cells, the outcome of point 8, the
#                          dataset check of Amendment 2 -> the clean layer,
#                          the obscured layer, four tbl_15 tables. Runs with
#                          RAW_STAGE = "counts" (it needs the entry state)
#   STEP 13.3 (task 13.4)  Decision 21 on the background: the same steps,
#                          the 1 km, 5 km and matched 1 km sets, the obscured
#                          count, the dataset check (choice d1) -> the clean
#                          background layer; the four tbl_15 tables again with
#                          both sets (choice t1); tbl_15_background_taxa.csv.
#                          Since 2026-10-25 (task 14.2, process choice w2):
#                          also the iNaturalist background of Decision 23 r2
#                          (the obscured background and the iNaturalist
#                          records of the 5 km background, with their 0.2
#                          degree cells) for scripts/09
#   STEP 13.4 (task 13.6)  the density surfaces of Decision 22: the hand-made
#                          case first (process choice h1); the effort, tiger
#                          and settlement surfaces at KDE_RADIUS_M and at the
#                          QA radii; the effort window surfaces; the counts by
#                          window; the summary table. Reads the clean layers
#                          FROM DISK. Runs with RAW_STAGE = "counts"
#   STEP 13.5 (task 13.7)  QA of Decisions 21 and 22: the hand-made cases of
#                          the rule and density functions; the rules of
#                          Decision 21 checked again on the kept records
#                          (process choice c1); the tables on disk; the
#                          surfaces; the publish checks -> tbl_15_occ_qa.csv
#                          (written first; a FALSE then stops the script) and
#                          tbl_15_kde_radius_compare.csv. Reads files only.
#                          Runs with RAW_STAGE = "counts"
#   STEP 13.6 (task 13.8)  clean records per reserve: the tiger 1 km and 5 km
#                          sets and the background 5 km set, records and 1 km
#                          cells inside each reserve polygon; a tiger count
#                          of 1 or 2 is written "<3" (Decision 22 point 9)
#                          -> tbl_15_occ_by_reserve.csv. Runs with RAW_STAGE
#                          = "counts"
#
# STEP 13.1 removes no record and writes no layer. Its counts are counts of
# the RAW state. STEP 13.2 is the first step that removes records.
#
# WHY THE ZIP FILES AND NOT THE INTERIM LAYERS (Decision 21 point 1):
#   scripts/01 wrote eight fields to the interim tiger layer (no
#   occurrenceStatus, no issue) and only `yr` to the interim background
#   layer. The rule needs the fields of the download. This script reads the
#   two SIMPLE_CSV files again. The interim layers are the guard: the entry
#   state must be the same records (tiger: the gbifID set; background: the
#   number of records).
#
# SENSITIVE DATA (docs/sensitive-data-policy.md; Decision 21 point 10):
#   A tiger record holds a precise position (tier T2). This script prints
#   counts and names only. It prints no coordinate and no cell. The table
#   that it writes holds counts and names only; outputs/tables/ is committed.
#
# INPUTS (STEP 13.1; all gitignored, from scripts/01, Week 2):
#   data/raw/gbif/gbif_tiger_download_key.txt            key of the tiger
#                                                        download
#   data/raw/gbif/<key>.zip                              SIMPLE_CSV, tiger
#                                                        (DOI 10.15468/dl.npxmxx)
#   data/raw/gbif_background/background_download_key.txt key of the Mammalia
#                                                        download
#   data/raw/gbif_background/<key>.zip                   SIMPLE_CSV, Mammalia
#                                                        (DOI 10.15468/dl.2d523e)
#   data/interim/boundary_india_national_7755.gpkg       the India polygon
#   data/interim/occ_tiger_gbif_raw_7755.gpkg            guard (stage "counts")
#   data/interim/effort_background_tgs_7755.gpkg         guard (stage "counts")
# INPUTS (STEP 13.2; checked when RAW_STAGE = "counts"):
#   data/processed/cov_stack_1km_7755.tif                the 1 km grid and the
#                                                        complete-case cells
#   data/processed/boundary_states_7755.gpkg             states (step 7)
#   data/raw/administrative/boundary_districts_datameet2011_7755.gpkg
#                                                        districts (step 7)
#   data/raw/osm/osm_zoos_7755.gpkg                      zoos (step 8;
#                                                        scripts/01 Block 6)
#   data/raw/gbif/dataset_meta/<datasetKey>.json         GBIF registry entries
#                                                        (Amendment 2); made
#                                                        on the first run (the
#                                                        network is needed
#                                                        then), read after
#
# OUTPUTS (STEP 13.2, tiger records; Decision 21):
#   data/processed/occ_tiger_gbif_clean_7755.gpkg      one row per kept record:
#     gbifID, datasetKey, basisOfRecord, year, uncert_m, uncert_set (1km or
#     5km), cell_1km (cell number of the covariate stack). Precise positions
#     (policy tier T2): gitignored, never published
#   data/processed/occ_tiger_gbif_obscured_7755.gpkg   the obscured set (point
#     4): gbifID, datasetKey, year, uncert_m, cell02_lon_deg, cell02_lat_deg
#     (south-west corner of the 0.2 degree cell). Tier T1; gitignored
#   outputs/tables/tbl_15_occ_cleaning.csv             set, step_order, step,
#     records_in, removed, records_out
#   outputs/tables/tbl_15_occ_cleaning_by_dataset.csv  set, datasetKey, item, n
#   outputs/tables/tbl_15_occ_sets.csv                 set, subset, records,
#     n_cells, point8_outcome (process choice s1)
#   outputs/tables/tbl_15_occ_dataset_check.csv        set, datasetKey, title,
#     n_1km, n_5km, words_found, hit, cleared, stop (Amendment 2)
#   Nothing of STEP 13.2 is written if the dataset check stops the script,
#   or if the outcome of point 8 is not OCC_POINT8_OUTCOME (choice r1).
#
# OUTPUTS (STEP 13.3, background; Decision 21 point 7):
#   data/processed/effort_background_tgs_clean_7755.gpkg  one row per kept
#     record: gbifID, datasetKey, basisOfRecord, year, order, family,
#     uncert_m, uncert_set, ds_match, cell_1km. Gitignored
#   data/processed/effort_background_inat_cell02_7755.gpkg  (since 2026-10-25;
#     Decision 23 r2, process choice w2 of task 14.2) the background of the
#     Week-14 model: one row per record of the iNaturalist dataset in one of
#     two parts. part = "obscured": removed at step 6 and in the obscured set
#     by the rule of Decision 21 point 4 (the obscured background, which
#     Week 13 only counted); part = "uncert": kept, with uncert_set in
#     SDM_BG_UNCERT_SETS. Fields: gbifID, datasetKey, part, order, family,
#     year, uncert_m, uncert_set (NA for "obscured"), cell02_lon_deg,
#     cell02_lat_deg (south-west corner of the 0.2 degree cell of the GBIF
#     coordinates). Gitignored. scripts/09 reads it
#   the four tbl_15 tables of STEP 13.2, written again with set = "tiger" and
#     set = "background" rows
#   outputs/tables/tbl_15_background_taxa.csv  set, order, family,
#     records_1km, records_5km, records_matched_1km
#   Nothing of STEP 13.3 is written if its dataset check stops the script.
#
# OUTPUTS (STEP 13.1, stage "counts"):
#   outputs/tables/tbl_15_occ_raw_counts.csv   long table: set, field, value,
#     n. One row per value of each field that Decision 21 uses, for the entry
#     state of the tiger records and of the background. Counts and names
#     only. (Table numbers are their own sequence — naming-conventions §6.
#     tbl_15 was free on 2026-10-11.)
#
# INPUTS (STEP 13.4, task 13.6; all gitignored except the table):
#   data/processed/cov_stack_1km_7755.tif                the grid and the
#                                                        window (complete-case
#                                                        cells)
#   data/processed/occ_tiger_gbif_clean_7755.gpkg        clean tiger records
#   data/processed/occ_tiger_gbif_obscured_7755.gpkg     obscured set (counts by
#                                                        window only)
#   data/processed/effort_background_tgs_clean_7755.gpkg clean background
#   data/raw/osm/osm_settlements_7755.gpkg               city and town points
#                                                        (scripts/01 Block 6)
#   outputs/tables/tbl_15_occ_sets.csv                   the guard: the layers
#                                                        on disk must give its
#                                                        counts
#
# OUTPUTS (STEP 13.4; Decision 22; process choices n1, q2, s1, v1):
#   data/processed/kde_effort_2006_2022_1km_7755.tif      effort, KDE_RADIUS_M
#   data/processed/kde_tiger_2006_2022_1km_7755.tif       tiger, KDE_RADIUS_M.
#     NEVER published, NEVER committed (Decision 22 point 9)
#   data/processed/kde_settlement_citytown_1km_7755.tif   settlement
#   data/processed/kde_effort_2006_2010_1km_7755.tif and
#   data/processed/kde_effort_2018_2022_1km_7755.tif      the effort window
#     surfaces, each only if its window has KDE_WINDOW_MIN_UNITS units or more
#   data/interim/kde_<surface>_<years>_r<R>km_1km_7755.tif  the same three
#     surfaces at each radius of KDE_RADII_QA_M (QA only; not an input to any
#     later step)
#   data/interim/kde_edgemass_r<R>km_1km_7755.tif         the edge mass M of
#     each radius
#   outputs/tables/tbl_15_occ_window_counts.csv  set, subset, window,
#     year_min, year_max, records, units, unit_type
#   outputs/tables/tbl_15_kde_summary.csv  surface, role, year_min, year_max,
#     radius_km, units, built, value_min, value_max, integral,
#     area_above0_km2, cells_mass_low, file
#   The years and the settlement part of a name come from the config
#   (OCC_YEAR_MIN, OCC_YEAR_MAX, KDE_WINDOWS, KDE_SETTLEMENT_CLASSES). Values:
#   units per km2, NA outside the complete-case cells, 32-bit float, read back
#   with a tolerance of KDE_READBACK_REL_TOL.
#
# INPUTS (STEP 13.5, task 13.7): the GBIF zips (occurrenceStatus, issue and
#   the public position of the obscured records, by gbifID); the India,
#   state, district and zoo layers (steps 7 and 8); the stack; the three
#   clean layers; the settlement layer; the tbl_15 tables of STEPs 13.1 to
#   13.4; the surfaces and edge masses of STEP 13.4.
#
# OUTPUTS (STEP 13.5; process choices t1, s2):
#   outputs/tables/tbl_15_kde_radius_compare.csv  surface, radius_km,
#     spearman, cells_compared (Decision 22 point 5; descriptive, no rule)
#   outputs/tables/tbl_15_occ_qa.csv  group, check, value, pass. One row per
#     check. Written first; then any FALSE in `pass` stops the script.
#
# INPUTS (STEP 13.6, task 13.8): data/processed/boundary_reserves_all_7755.gpkg
#   (58 reserves; 2 with no polygon) and the three clean layers.
#
# OUTPUTS (STEP 13.6; process choices s1, r1, p1, w1, x1):
#   outputs/tables/tbl_15_occ_by_reserve.csv  one row per reserve (58),
#     ordered by unit_id: unit_id, unit_name, state, landscape_complex,
#     geometry_present, tiger_1km_records, tiger_1km_cells,
#     tiger_5km_records, tiger_5km_cells, background_5km_records,
#     background_5km_cells. A record is in a reserve if its position is in
#     the polygon (an edge counts); a record in two overlapping polygons
#     counts in each (process choice o1). In a tiger column, a count from 1 to
#     KDE_SMALL_N - 1 is the text "<3"; NA for a reserve with no polygon.
#     No position. The exact tiger counts are not written to any file.
#
# SETTINGS: the OCC_* values (Decision 21) and the KDE_* values (Decision 22)
#   come from R/00_config.R; since 2026-10-25 also four SDM_* values
#   (Decision 23) for the iNaturalist background of STEP 13.3. The field
#   lists and the two GBIF vocabularies below are the structure of the GBIF
#   file, not choices of the analysis.
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
  library(readr)
})

source(here("R", "00_config.R"))         # CRS, DIR_*, OCC_* (Decision 21)
source(here("R", "00_functions_io.R"))   # read_vec, write_table
source(here("R", "00_functions_occ.R"))  # occ_* (task 13.2)
source(here("R", "00_functions_kde.R"))  # kde_* (task 13.6, Decision 22)

rule <- function(txt) cat("\n", strrep("=", 78), "\n", txt, "\n",
                          strrep("=", 78), "\n", sep = "")

# ---- Run switch (process choice g1, 2026-10-11) -------------------------------
# "names"  : STEP 13.1 prints field names and distinct values. No count.
# "counts" : STEP 13.1 also builds the entry state and the raw counts.
# First run: "names". Set "counts" only after the names are read and Decision
# 21 has no open amendment. After task 13.2 the value stays "counts" (STEP
# 13.2 runs only then).
RAW_STAGE <- "counts"

# ---- Run switch (process choice r1, task 13.6, 2026-10-17) --------------------
# TRUE  : STEPs 13.1 to 13.3 run (they read the GBIF zips and write the clean
#         layers and the tbl_15 tables again), then STEP 13.4.
# FALSE : STEPs 13.1 to 13.3 are skipped. STEP 13.4 reads the clean layers
#         from data/processed/; a guard compares them with
#         tbl_15_occ_sets.csv. No GBIF zip and no network are needed.
# STEP 13.4 always reads the clean layers from disk (both values).
# 2026-10-25 (task 14.2, process choice w2): TRUE for ONE run, to write the
# iNaturalist background of Decision 23 (STEP 13.3). The run writes the
# Week-13 layers and tbl_15 tables again; after it, `git status --short` must
# show no change under outputs/tables/. Set FALSE again after that run.
RUN_CLEANING <- FALSE

# ---- Run switch (process choice x1, task 13.7, 2026-10-18) --------------------
# TRUE  : STEP 13.4 builds the surfaces again (about 6 minutes on the project
#         machine).
# FALSE : STEP 13.4 is skipped. STEP 13.5 reads the surfaces from disk.
RUN_SURFACES <- FALSE

# ---- Paths ------------------------------------------------------------------
tiger_key_in <- file.path(DIR_RAW, "gbif", "gbif_tiger_download_key.txt")
bg_key_in    <- file.path(DIR_RAW, "gbif_background",
                          "background_download_key.txt")
india_in     <- file.path(DIR_INTERIM, "boundary_india_national_7755.gpkg")
tiger_raw_in <- file.path(DIR_INTERIM, "occ_tiger_gbif_raw_7755.gpkg")
bg_raw_in    <- file.path(DIR_INTERIM, "effort_background_tgs_7755.gpkg")
# Output table via write_table(nn = 15, slug = "occ_raw_counts")

# STEP 13.2
stack_in     <- file.path(DIR_PROCESSED, "cov_stack_1km_7755.tif")
states_in    <- file.path(DIR_PROCESSED, "boundary_states_7755.gpkg")
districts_in <- file.path(DIR_RAW, "administrative",
                          "boundary_districts_datameet2011_7755.gpkg")
zoos_in      <- file.path(DIR_RAW, "osm", "osm_zoos_7755.gpkg")
meta_dir     <- file.path(DIR_RAW, "gbif", "dataset_meta")
clean_out    <- "occ_tiger_gbif_clean_7755.gpkg"      # in DIR_PROCESSED
obscured_out <- "occ_tiger_gbif_obscured_7755.gpkg"   # in DIR_PROCESSED
# STEP 13.3
bg_clean_out <- "effort_background_tgs_clean_7755.gpkg"  # in DIR_PROCESSED
bg_inat_out  <- "effort_background_inat_cell02_7755.gpkg" # in DIR_PROCESSED;
                                                          # Decision 23 r2
# STEP 13.4 (the raster names are made in STEP 13.4 from the config)
setts_in     <- file.path(DIR_RAW, "osm", "osm_settlements_7755.gpkg")
sets_tbl_in  <- file.path(DIR_TABLES, "tbl_15_occ_sets.csv")
# STEP 13.6
reserves_in  <- file.path(DIR_PROCESSED, "boundary_reserves_all_7755.gpkg")
# Read-back tolerance of the surfaces (process choice v1). The default of
# write_processed_rast() (1e-4 x max(1, |mean|)) cannot see a file of zeros
# when the mean is about 1e-5 (the tiger surface).
KDE_READBACK_REL_TOL <- 1e-8

# ---- Structure of the GBIF SIMPLE_CSV file -------------------------------------
# Fields that Decision 21 uses (point 1). `speciesKey` is read for the tiger
# file too: its one value is the key that the background filter excludes
# (scripts/01 got that key from the GBIF name service; this script does not
# use the network).
FIELDS_RULE  <- c("gbifID", "datasetKey", "occurrenceStatus", "basisOfRecord",
                  "year", "decimalLatitude", "decimalLongitude",
                  "coordinateUncertaintyInMeters", "issue")
FIELDS_TIGER <- c(FIELDS_RULE, "speciesKey")
FIELDS_BG    <- c(FIELDS_RULE, "speciesKey", "order", "family")

# GBIF vocabularies (read 2026-10-11; a value outside them is a "REVIEW" line
# of the names stage, not a stop).
GBIF_STATUS_VOCAB <- c("PRESENT", "ABSENT")
GBIF_BASIS_VOCAB  <- c("PRESERVED_SPECIMEN", "FOSSIL_SPECIMEN",
                       "LIVING_SPECIMEN", "OBSERVATION", "HUMAN_OBSERVATION",
                       "MACHINE_OBSERVATION", "MATERIAL_SAMPLE",
                       "MATERIAL_CITATION", "OCCURRENCE", "LITERATURE")
# A flag with no rule in Decision 21 and a name that matches this pattern is a
# "REVIEW" line of the names stage.
FLAG_REVIEW_PATTERN <- "COORD|GEODETIC|PRESUMED|COUNTRY|FOOTPRINT"

# ---- Guards (fail early) ----------------------------------------------------
# 1) The run switch.
if (!is.character(RAW_STAGE) || length(RAW_STAGE) != 1L ||
    !RAW_STAGE %in% c("names", "counts")) {
  stop("RAW_STAGE must be \"names\" or \"counts\".", call. = FALSE)
}
if (!is.logical(RUN_CLEANING) || length(RUN_CLEANING) != 1L ||
    is.na(RUN_CLEANING)) {
  stop("RUN_CLEANING must be TRUE or FALSE.", call. = FALSE)
}
if (!is.logical(RUN_SURFACES) || length(RUN_SURFACES) != 1L ||
    is.na(RUN_SURFACES)) {
  stop("RUN_SURFACES must be TRUE or FALSE.", call. = FALSE)
}
if (!RUN_CLEANING && RAW_STAGE != "counts") {
  stop("RUN_CLEANING = FALSE skips STEPs 13.1 to 13.3, and STEPs 13.4 and ",
       "13.5 need RAW_STAGE = \"counts\".", call. = FALSE)
}

# 2) The Decision-21 settings of STEP 13.1 must come from config.
occ_params <- c("OCC_STATUS_KEEP", "OCC_BASIS_KEEP", "OCC_YEAR_MIN",
                "OCC_YEAR_MAX", "OCC_ISSUE_REMOVE", "OCC_ISSUE_REPORT",
                "OCC_UNCERT_MAIN_M", "OCC_UNCERT_WIDE_M",
                "OCC_OBSCURED_MIN_UNCERT_M", "OCC_INAT_DATASET_KEY",
                # STEP 13.2
                "OCC_STEP_ORDER", "OCC_OBSCURED_CELL_DEG",
                "OCC_CENTROID_LEVELS", "OCC_CENTROID_DIST_M",
                "OCC_ZOO_DIST_M", "OCC_THIN_RULE", "OCC_MIN_CELLS_MODEL",
                "OCC_MIN_CELLS_FULL", "OCC_DATASET_FLAG_WORDS",
                "OCC_DATASET_CLEARED", "OCC_POINT8_OUTCOME",
                # STEP 13.3
                "OCC_BG_SAME_RULE", "OCC_BG_MATCH_MIN_TIGER")
missing_params <- occ_params[!vapply(occ_params, exists, logical(1))]
if (length(missing_params) > 0) {
  stop("Decision-21 setting(s) missing from R/00_config.R: ",
       paste(missing_params, collapse = ", "), call. = FALSE)
}
stopifnot(
  "OCC_STATUS_KEEP must be in the GBIF vocabulary" =
    all(OCC_STATUS_KEEP %in% GBIF_STATUS_VOCAB),
  "OCC_BASIS_KEEP must be in the GBIF vocabulary" =
    all(OCC_BASIS_KEEP %in% GBIF_BASIS_VOCAB),
  "a flag cannot be in OCC_ISSUE_REMOVE and in OCC_ISSUE_REPORT" =
    length(intersect(OCC_ISSUE_REMOVE, OCC_ISSUE_REPORT)) == 0,
  "OCC_YEAR_MIN must not be above OCC_YEAR_MAX" = OCC_YEAR_MIN <= OCC_YEAR_MAX,
  "the uncertainty limits must be in the order main < wide < obscured" =
    OCC_UNCERT_MAIN_M < OCC_UNCERT_WIDE_M &&
    OCC_UNCERT_WIDE_M < OCC_OBSCURED_MIN_UNCERT_M,
  # STEP 13.2: the functions build one rule set only (Decision 21).
  "OCC_STEP_ORDER must be the nine steps of Decision 21, in order" =
    identical(OCC_STEP_ORDER, c("status", "basis", "year", "coord_flags",
                                "uncert_na", "uncert", "centroid", "zoo",
                                "footprint")),
  "OCC_CENTROID_LEVELS must be india, state, district" =
    identical(OCC_CENTROID_LEVELS, c("india", "state", "district")),
  "OCC_THIN_RULE must be one_per_cell" = identical(OCC_THIN_RULE,
                                                   "one_per_cell"),
  "OCC_DATASET_CLEARED must be a list (names = dataset keys)" =
    is.list(OCC_DATASET_CLEARED) &&
    (length(OCC_DATASET_CLEARED) == 0 ||
       !is.null(names(OCC_DATASET_CLEARED))),
  "OCC_POINT8_OUTCOME must be one of the three outcomes of Decision 21" =
    length(OCC_POINT8_OUTCOME) == 1 &&
    OCC_POINT8_OUTCOME %in% c("no_1km_model", "reduced_model",
                              "planned_model"),
  "OCC_BG_MATCH_MIN_TIGER must be 1 or more" = OCC_BG_MATCH_MIN_TIGER >= 1
)

# 2b) The Decision-22 settings of STEP 13.4 must come from config.
kde_params <- c("KDE_SURFACES", "KDE_UNCERT_SETS", "KDE_UNIT",
                "KDE_SETTLEMENT_CLASSES", "KDE_KERNEL", "KDE_RADIUS_M",
                "KDE_SIGMA_M", "KDE_RADII_QA_M", "KDE_WINDOWS",
                "KDE_WINDOW_SURFACES", "KDE_WINDOW_MIN_UNITS", "KDE_EDGE",
                "KDE_EDGE_FLAG_MASS", "KDE_PUBLISH_TIGER", "KDE_SMALL_N")
missing_kde <- kde_params[!vapply(kde_params, exists, logical(1))]
if (length(missing_kde) > 0) {
  stop("Decision-22 setting(s) missing from R/00_config.R: ",
       paste(missing_kde, collapse = ", "), call. = FALSE)
}
stopifnot(
  "KDE_SURFACES must be effort, tiger, settlement (Decision 22 a2)" =
    identical(KDE_SURFACES, c("effort", "tiger", "settlement")),
  "KDE_UNCERT_SETS must hold uncert_set values of Decision 21 (p1)" =
    length(KDE_UNCERT_SETS) > 0 && all(KDE_UNCERT_SETS %in% c("1km", "5km")),
  "KDE_UNIT must be cell (Decision 22 u2)" = identical(KDE_UNIT, "cell"),
  "KDE_SETTLEMENT_CLASSES must be OSM place values (b2)" =
    length(KDE_SETTLEMENT_CLASSES) > 0 &&
    all(KDE_SETTLEMENT_CLASSES %in% c("city", "town", "village")),
  "KDE_KERNEL must be quartic (Decision 22 c2)" =
    identical(KDE_KERNEL, "quartic"),
  "KDE_SIGMA_M must be KDE_RADIUS_M / sqrt(8)" =
    isTRUE(all.equal(KDE_SIGMA_M, KDE_RADIUS_M / sqrt(8))),
  "the QA radii must differ from KDE_RADIUS_M and from each other" =
    !any(KDE_RADII_QA_M == KDE_RADIUS_M) && !anyDuplicated(KDE_RADII_QA_M),
  "each radius must be 2 cells or more" =
    all(c(KDE_RADIUS_M, KDE_RADII_QA_M) >= 2 * GRID_CELL_M),
  "\"all\" is not a window name (it is the row for all years)" =
    !"all" %in% names(KDE_WINDOWS),
  "KDE_WINDOW_SURFACES must name windows of KDE_WINDOWS" =
    all(KDE_WINDOW_SURFACES %in% names(KDE_WINDOWS)),
  "KDE_WINDOW_MIN_UNITS must be 1 or more" = KDE_WINDOW_MIN_UNITS >= 1,
  "KDE_EDGE must be uniform (Decision 22 e2)" = identical(KDE_EDGE, "uniform"),
  "KDE_EDGE_FLAG_MASS must be above 0 and below 1" =
    KDE_EDGE_FLAG_MASS > 0 && KDE_EDGE_FLAG_MASS < 1,
  "KDE_PUBLISH_TIGER must be FALSE (Decision 22 g1)" =
    identical(KDE_PUBLISH_TIGER, FALSE)
)
kde_check_windows(KDE_WINDOWS, OCC_YEAR_MIN, OCC_YEAR_MAX)

# 2c) The Decision-23 settings that STEP 13.3 uses for the iNaturalist
#     background (task 14.2, process choice w2) must come from config.
sdm_params <- c("SDM_BG_DATASET_KEY", "SDM_BG_OBSCURED", "SDM_BG_UNCERT_SETS",
                "SDM_GRAIN_DEG")
missing_sdm <- sdm_params[!vapply(sdm_params, exists, logical(1))]
if (length(missing_sdm) > 0) {
  stop("Decision-23 setting(s) missing from R/00_config.R: ",
       paste(missing_sdm, collapse = ", "), call. = FALSE)
}
stopifnot(
  "SDM_BG_DATASET_KEY must be OCC_INAT_DATASET_KEY (Decision 23 r2)" =
    identical(SDM_BG_DATASET_KEY, OCC_INAT_DATASET_KEY),
  "SDM_BG_OBSCURED must be TRUE (Decision 23 r2)" =
    identical(SDM_BG_OBSCURED, TRUE),
  "SDM_BG_UNCERT_SETS must hold uncert_set values of Decision 21" =
    length(SDM_BG_UNCERT_SETS) > 0 &&
    all(SDM_BG_UNCERT_SETS %in% c("1km", "5km")),
  "SDM_GRAIN_DEG must be OCC_OBSCURED_CELL_DEG (Decision 23 b3)" =
    isTRUE(all.equal(SDM_GRAIN_DEG, OCC_OBSCURED_CELL_DEG))
)
# The tiger surface must not be written under outputs/ (Decision 22 point 9).
out_root <- normalizePath(here("outputs"), winslash = "/", mustWork = FALSE)
for (d in c(DIR_PROCESSED, DIR_INTERIM)) {
  if (startsWith(normalizePath(d, winslash = "/", mustWork = FALSE),
                 out_root)) {
    stop("A density surface would be written under outputs/: ", d,
         call. = FALSE)
  }
}

# 3) The analysis CRS must resolve in this session (PROJ proj.db clash).
crs_wkt <- terra::crs(terra::rast(crs = paste0("EPSG:", CRS_ANALYSIS)))
if (!nzchar(crs_wkt) || !grepl("India", crs_wkt)) {
  stop("EPSG:", CRS_ANALYSIS, " did not resolve to the India NSF LCC frame. ",
       "Restart R so .Rprofile pins PROJ_LIB before terra loads, then re-run.",
       call. = FALSE)
}

# 4) Every input of this stage must exist. The interim layers are needed for
#    the guards of stage "counts" only.
#    With RUN_CLEANING = FALSE, STEPs 13.4 and 13.5 need the clean layers and
#    the set table of an earlier run; STEP 13.5 also needs the GBIF files and
#    the reference layers of steps 7 and 8.
inputs <- if (RUN_CLEANING) {
  c(tiger_key_in, bg_key_in, india_in,
    if (RAW_STAGE == "counts") c(tiger_raw_in, bg_raw_in, stack_in,
                                 states_in, districts_in, zoos_in, setts_in,
                                 reserves_in))
} else {
  c(stack_in, file.path(DIR_PROCESSED, c(clean_out, obscured_out,
                                         bg_clean_out)),
    setts_in, sets_tbl_in, tiger_key_in, bg_key_in, india_in, states_in,
    districts_in, zoos_in, reserves_in)
}
missing_inputs <- inputs[!file.exists(inputs)]
if (length(missing_inputs) > 0) {
  stop("Missing required input(s):\n  ", paste(missing_inputs, collapse = "\n  "),
       if (RUN_CLEANING) paste0(
         "\nRun scripts/01 (Blocks 1-3; Block 6), scripts/02 and scripts/06 ",
         "first.") else paste0(
         "\nThe clean layers and tbl_15_occ_sets.csv come from a run with ",
         "RUN_CLEANING <- TRUE; the settlement layer from scripts/01 Block ",
         "6; the stack from scripts/06."), call. = FALSE)
}
tiger_zip <- occ_zip_path(tiger_key_in)   # stops if the zip is not there
bg_zip    <- occ_zip_path(bg_key_in)       # (STEPs 13.1 and 13.5 read them)

rule(paste0("08_prepare_occurrences.R — inputs found; CRS OK | RAW_STAGE = ",
            RAW_STAGE, " | RUN_CLEANING = ", RUN_CLEANING,
            " | RUN_SURFACES = ", RUN_SURFACES))

# =============================================================================
# STEP 13.1 — the raw state of the two GBIF files (task 13.2)
# =============================================================================
# Stage "names" reads each file once and prints names only:
#   - the header fields, and whether each field of Decision 21 is there
#     (a missing field stops the script: Decision 21 needs an amendment);
#   - the distinct values of occurrenceStatus and basisOfRecord;
#   - the flag names in `issue`, by their rule in Decision 21 (remove, report,
#     no rule);
#   - whether year, the coordinates and the uncertainty are numbers;
#   - whether the iNaturalist dataset key is in the file.
# It covers the WHOLE file (the bounding-box download), so each value of the
# entry state is in the lists. It prints no count of records.
# A "REVIEW" line is a possible amendment of Decision 21. The author decides.
# STEPs 13.1 to 13.3 run only with RUN_CLEANING = TRUE (process choice r1).

if (RUN_CLEANING) {

rule("STEP 13.1 — raw state of the GBIF files, stage \"names\" (no count)")

sets <- list(
  tiger      = list(zip = tiger_zip, fields = FIELDS_TIGER),
  background = list(zip = bg_zip,    fields = FIELDS_BG)
)

raw_dat    <- list()
name_check <- list()
for (s in names(sets)) {
  hdr <- occ_read_header(sets[[s]]$zip)
  cat("\n--- ", s, ": ", length(hdr), " header fields ---\n", sep = "")
  cat(strwrap(paste(hdr, collapse = ", "), width = 78, prefix = "  "),
      sep = "\n")
  occ_check_fields(hdr, sets[[s]]$fields, s)
  cat("  fields of Decision 21: all ", length(sets[[s]]$fields),
      " are in the header\n", sep = "")

  raw_dat[[s]] <- occ_read_fields(sets[[s]]$zip, sets[[s]]$fields)
  name_check[[s]] <- occ_names_report(
    raw_dat[[s]], set = s,
    status_vocab = GBIF_STATUS_VOCAB, basis_vocab = GBIF_BASIS_VOCAB,
    status_keep = OCC_STATUS_KEEP, basis_keep = OCC_BASIS_KEEP,
    issue_remove = OCC_ISSUE_REMOVE, issue_report = OCC_ISSUE_REPORT,
    inat_key = OCC_INAT_DATASET_KEY,
    flag_review_pattern = FLAG_REVIEW_PATTERN)
}
name_check <- do.call(rbind, name_check)
rownames(name_check) <- NULL

# The tiger speciesKey: one value in the tiger file.
tiger_spk <- unique(raw_dat$tiger$speciesKey[!is.na(raw_dat$tiger$speciesKey)])
name_check <- rbind(name_check, data.frame(
  set = "tiger", check = "the tiger file has one speciesKey",
  result = if (length(tiger_spk) == 1L) "ok" else "REVIEW",
  detail = if (length(tiger_spk) == 1L) "" else
    paste(length(tiger_spk), "values"), stringsAsFactors = FALSE))

cat("\n--- checks of the names stage ---\n")
for (i in seq_len(nrow(name_check))) {
  cat(sprintf("  [%-6s] %-10s %s%s\n", name_check$result[i], name_check$set[i],
              name_check$check[i],
              if (nzchar(name_check$detail[i]))
                paste0("  ->  ", name_check$detail[i]) else ""))
}
n_review <- sum(name_check$result == "REVIEW")
cat("\nlines with REVIEW:", n_review, "\n")

if (RAW_STAGE == "names") {
  rule(paste0("Stage \"names\" complete. No count was printed and no record ",
              "was removed.\n",
              if (n_review > 0) "Read the REVIEW lines first. " else "",
              "If Decision 21 needs no amendment, set RAW_STAGE <- \"counts\" ",
              "and run again."))
}

# -----------------------------------------------------------------------------
# Stage "counts": entry state, guards, raw counts. Runs only when RAW_STAGE is
# "counts". The block ends at "end if (RAW_STAGE == counts)".
# -----------------------------------------------------------------------------
if (RAW_STAGE == "counts") {

rule("STEP 13.1 — raw state of the GBIF files, stage \"counts\"")

if (length(tiger_spk) != 1L) {
  stop("The tiger file has ", length(tiger_spk), " speciesKey values; the ",
       "background filter needs one.", call. = FALSE)
}

india_sf <- read_vec(india_in)
stopifnot(sf::st_crs(india_sf)$epsg == CRS_ANALYSIS)

# ---- Entry state (Decision 21 point 1, step 0) -------------------------------
# Tiger: two coordinates, inside India. Background: also the year window of the
# download (BASELINE_YEAR to CURRENT_YEAR, as scripts/01) and not the tiger.
entry <- list(
  tiger = occ_entry_state(raw_dat$tiger, india_sf, crs_in = CRS_WGS84),
  background = occ_entry_state(raw_dat$background, india_sf,
                               crs_in = CRS_WGS84,
                               year_min = BASELINE_YEAR,
                               year_max = CURRENT_YEAR,
                               exclude_species_key = tiger_spk)
)
for (s in names(entry)) {
  cat("\n", s, ":\n", sep = "")
  for (k in names(entry[[s]]$counts)) {
    cat(sprintf("  %-28s %s\n", k,
                format(entry[[s]]$counts[[k]], big.mark = ",")))
  }
}

# ---- Guards: the entry state is the Week-2 state ------------------------------
# Tiger: the gbifID set must be the set of the interim layer.
tiger_interim <- sf::st_drop_geometry(sf::st_read(tiger_raw_in, quiet = TRUE))
if (!"gbifID" %in% names(tiger_interim)) {
  stop("The interim tiger layer has no gbifID field: ", tiger_raw_in,
       call. = FALSE)
}
id_new <- occ_id_chr(entry$tiger$sf$gbifID)
id_old <- occ_id_chr(tiger_interim$gbifID)
if (anyNA(id_new) || anyNA(id_old) || anyDuplicated(id_new) ||
    anyDuplicated(id_old)) {
  stop("Guard: a gbifID is missing or is there two times (entry state or ",
       "interim layer).", call. = FALSE)
}
only_new <- length(setdiff(id_new, id_old))
only_old <- length(setdiff(id_old, id_new))
cat(sprintf(paste0("\nguard, tiger: entry state %s records | interim layer %s",
                   " | only in the entry state %d | only in the interim ",
                   "layer %d\n"),
            format(length(id_new), big.mark = ","),
            format(length(id_old), big.mark = ","), only_new, only_old))
if (only_new > 0 || only_old > 0) {
  stop("Guard: the tiger entry state is not the record set of the interim ",
       "layer. Nothing is written. Find the cause before any record is ",
       "cleaned (Decision 21 point 1).", call. = FALSE)
}

# Background: the number of records must be the number in the interim layer
# (that layer has no identifier).
bg_layers <- sf::st_layers(bg_raw_in)
if (length(bg_layers$name) != 1L) {
  stop("The interim background file must hold one layer: ", bg_raw_in,
       call. = FALSE)
}
n_bg_old <- as.integer(bg_layers$features[1])
n_bg_new <- nrow(entry$background$sf)
cat(sprintf("guard, background: entry state %s records | interim layer %s\n",
            format(n_bg_new, big.mark = ","),
            format(n_bg_old, big.mark = ",")))
if (is.na(n_bg_old) || n_bg_new != n_bg_old) {
  stop("Guard: the background entry state does not have the number of ",
       "records of the interim layer. Nothing is written. Find the cause ",
       "before any record is cleaned (Decision 21 point 1).", call. = FALSE)
}
cat("guards PASS: the entry state is the Week-2 state.\n")

# ---- Raw counts by each rule field --------------------------------------------
raw_counts <- do.call(rbind, lapply(names(entry), function(s) {
  occ_raw_counts(entry[[s]]$sf, entry[[s]]$counts, set = s,
                 year_min = OCC_YEAR_MIN, year_max = OCC_YEAR_MAX,
                 issue_remove = OCC_ISSUE_REMOVE,
                 issue_report = OCC_ISSUE_REPORT,
                 uncert_main = OCC_UNCERT_MAIN_M,
                 uncert_wide = OCC_UNCERT_WIDE_M,
                 uncert_obscured = OCC_OBSCURED_MIN_UNCERT_M,
                 inat_key = OCC_INAT_DATASET_KEY)
}))
rownames(raw_counts) <- NULL

# Console: every field in full, but the dataset list as its first 10 rows.
DATASET_ROWS_SHOWN <- 10L
for (s in names(entry)) {
  cat("\n--- ", s, ": raw counts of the entry state ---\n", sep = "")
  x <- raw_counts[raw_counts$set == s, ]
  for (f in unique(x$field)) {
    xf <- x[x$field == f, c("value", "n")]
    cat("\n", f, if (f == "datasetKey")
      sprintf(" (%d datasets; the first %d by count)", nrow(xf),
              min(DATASET_ROWS_SHOWN, nrow(xf))), ":\n", sep = "")
    if (f == "datasetKey") xf <- utils::head(xf, DATASET_ROWS_SHOWN)
    print(xf, row.names = FALSE, right = FALSE)
  }
}

occ_assert_counts_only(raw_counts, name = "tbl_15_occ_raw_counts.csv")
write_table(raw_counts, nn = 15, slug = "occ_raw_counts")

rule(paste0("STEP 13.1 complete: tbl_15_occ_raw_counts.csv written. These are ",
            "counts of the RAW state; no record was removed."))

}  # end if (RAW_STAGE == counts)

}  # end if (RUN_CLEANING), STEP 13.1

# =============================================================================
# STEP 13.2 — Decision 21 on the tiger records (task 13.3)
# =============================================================================
# The nine rule steps (Decision 21 point 2) on the tiger entry state. Each
# step is computed on all records; a record is counted at the FIRST step that
# it fails (OCC_STEP_ORDER). A kept record gets uncert_set "1km" or "5km"
# (point 3) and its 1 km cell (point 5). The obscured set is the iNaturalist
# records that step 6 removes with an uncertainty of OCC_OBSCURED_MIN_UNCERT_M
# or more (point 4). The outcome of point 8 is stated from n_cells_1km.
# Then the dataset check of Amendment 2. If it stops, NOTHING is written.
# The console text holds counts, dataset keys and titles only.

if (RUN_CLEANING && RAW_STAGE == "counts") {

rule("STEP 13.2 — Decision 21 on the tiger records (task 13.3)")

# ---- Reference layers ---------------------------------------------------------
stack_r <- terra::rast(stack_in)
stopifnot(
  "the covariate stack must be in the analysis CRS" =
    identical(as.character(terra::crs(stack_r, describe = TRUE)$code),
              as.character(CRS_ANALYSIS)),
  "the covariate stack must have cells of GRID_CELL_M" =
    isTRUE(all.equal(terra::res(stack_r), c(GRID_CELL_M, GRID_CELL_M)))
)
states_sf    <- read_vec(states_in)
districts_sf <- read_vec(districts_in)
zoos_sf      <- read_vec(zoos_in)
if (nrow(zoos_sf) == 0) {
  stop("The zoo layer has no feature: ", zoos_in, ". A failed read is not ",
       "'no zoo' (Decision 21 step 8).", call. = FALSE)
}
n_zoo_invalid <- sum(!sf::st_is_valid(zoos_sf))
if (n_zoo_invalid > 0) zoos_sf <- sf::st_make_valid(zoos_sf)  # in memory only
cat("zoo features:", nrow(zoos_sf), "(points", sum(zoos_sf$feature == "point"),
    "| areas", sum(zoos_sf$feature == "area"), ") | not valid, made valid in",
    "memory:", n_zoo_invalid, "\n")

cent_sf <- occ_centroids(list(india = india_sf, state = states_sf,
                              district = districts_sf))
cat("centroids:", paste(names(table(cent_sf$level)), table(cent_sf$level),
                        sep = " ", collapse = " | "), "\n")

# ---- The nine steps -----------------------------------------------------------
tg   <- entry$tiger$sf
tg_d <- sf::st_drop_geometry(tg)
tg_cells <- occ_stack_cells(tg, stack_r)

tg_fails <- occ_step_fails(
  tg_d,
  status_keep   = OCC_STATUS_KEEP,
  basis_keep    = OCC_BASIS_KEEP,
  year_min      = OCC_YEAR_MIN,
  year_max      = OCC_YEAR_MAX,
  issue_remove  = OCC_ISSUE_REMOVE,
  uncert_wide   = OCC_UNCERT_WIDE_M,
  near_centroid = occ_near(tg, cent_sf, OCC_CENTROID_DIST_M),
  near_zoo      = occ_near(tg, zoos_sf, OCC_ZOO_DIST_M),
  complete      = tg_cells$complete
)[, OCC_STEP_ORDER]
tg_removed <- occ_first_fail(tg_fails, OCC_STEP_ORDER)
tg_kept    <- is.na(tg_removed)

tg_uset <- rep(NA_character_, nrow(tg_d))
tg_uset[tg_kept] <- occ_uncert_set(tg_d$uncert_m[tg_kept], OCC_UNCERT_MAIN_M,
                                   OCC_UNCERT_WIDE_M)

# Obscured set (point 4), and the iNaturalist records of step 6 below the
# obscured minimum (they are in no set; the Decision asks for the count).
is_inat     <- tg_d$datasetKey == OCC_INAT_DATASET_KEY
tg_obscured <- tg_removed %in% "uncert" & is_inat &
  tg_d$uncert_m >= OCC_OBSCURED_MIN_UNCERT_M
n_inat_gap  <- sum(tg_removed %in% "uncert" & is_inat &
                     tg_d$uncert_m < OCC_OBSCURED_MIN_UNCERT_M)

# ---- Attrition and sets -------------------------------------------------------
tg_attr <- occ_attrition(tg_removed, OCC_STEP_ORDER, set = "tiger")
tg_byds <- occ_by_dataset(tg_d$datasetKey, tg_removed, tg_uset, tg_obscured,
                          OCC_STEP_ORDER, set = "tiger")

cat("\n--- tiger: attrition (each record counted at the first step that it",
    "fails) ---\n")
show_attr <- tg_attr
show_attr$fail_in_any_order <- c(NA, colSums(tg_fails))
old_width <- options(width = 120)   # one table, with no wrap
print(show_attr, row.names = FALSE)
options(old_width)
cat("(fail_in_any_order: records that fail the step, with no order; for",
    "information only)\n")

n_rec_1km   <- sum(tg_kept & tg_uset %in% "1km")
n_rec_5km   <- sum(tg_kept)
n_cells_1km <- length(unique(tg_cells$cell[tg_kept & tg_uset %in% "1km"]))
n_cells_5km <- length(unique(tg_cells$cell[tg_kept]))
obs_cell    <- occ_cell02(tg_d$lon[tg_obscured], tg_d$lat[tg_obscured],
                          OCC_OBSCURED_CELL_DEG)
n_cells_obs <- nrow(unique(obs_cell))
outcome     <- occ_point8_outcome(n_cells_1km, OCC_MIN_CELLS_MODEL,
                                  OCC_MIN_CELLS_FULL)

sets_tbl <- data.frame(
  set            = "tiger",
  subset         = c("1km", "5km", "obscured"),
  records        = c(n_rec_1km, n_rec_5km, sum(tg_obscured)),
  n_cells        = c(n_cells_1km, n_cells_5km, n_cells_obs),
  point8_outcome = c(outcome, "", ""),
  stringsAsFactors = FALSE
)
cat("\n--- tiger: sets (n_cells: 1 km cells; for the obscured set, 0.2 degree",
    "cells) ---\n")
print(sets_tbl, row.names = FALSE)
cat("iNaturalist records removed at step 6 with an uncertainty below",
    OCC_OBSCURED_MIN_UNCERT_M, "m (in no set):", n_inat_gap, "\n")
cat(sprintf(paste0("\nDecision 21 point 8: n_cells_1km = %d -> %s (limits %d ",
                   "and %d). The outcome does not change after this run.\n"),
            n_cells_1km, outcome, OCC_MIN_CELLS_MODEL, OCC_MIN_CELLS_FULL))
# Process choice r1 (2026-10-17): the recorded outcome is locked in config.
if (!identical(outcome, OCC_POINT8_OUTCOME)) {
  stop("The outcome of Decision 21 point 8 is '", outcome, "', but the ",
       "recorded outcome (OCC_POINT8_OUTCOME) is '", OCC_POINT8_OUTCOME,
       "'. Nothing of STEP 13.2 is written. An input or a rule changed: find ",
       "the cause. The outcome does not change after task 13.3.",
       call. = FALSE)
}
cat("outcome = the recorded outcome (OCC_POINT8_OUTCOME).\n")

# ---- Dataset check (Decision 21, Amendment 2) ---------------------------------
ds_keys <- sort(unique(tg_d$datasetKey[tg_kept]))
n_ds_1km <- table(tg_d$datasetKey[tg_kept & tg_uset %in% "1km"])
n_ds_5km <- table(tg_d$datasetKey[tg_kept & tg_uset %in% "5km"])
ds_meta  <- occ_dataset_meta(ds_keys, meta_dir)
ds_check <- occ_dataset_check(ds_meta, OCC_DATASET_FLAG_WORDS,
                              OCC_DATASET_CLEARED, n_ds_1km, n_ds_5km,
                              set = "tiger")
cat("\n--- tiger: dataset check (Amendment 2; datasets with a kept record) ---\n")
for (i in seq_len(nrow(ds_check))) {
  cat(sprintf("  %s  1km %3d  5km %3d  %s\n    %s\n    words: %s\n",
              ds_check$datasetKey[i], ds_check$n_1km[i], ds_check$n_5km[i],
              if (ds_check$stop[i]) "STOP" else if (ds_check$hit[i])
                "hit, cleared" else "ok",
              ds_check$title[i],
              if (nzchar(ds_check$words_found[i])) ds_check$words_found[i]
              else "(none)"))
}
if (any(ds_check$stop)) {
  stop("Dataset check (Decision 21, Amendment 2): ", sum(ds_check$stop),
       " dataset(s) with a kept record have words about degraded, ",
       "generalised or obscured positions: ",
       paste(ds_check$datasetKey[ds_check$stop], collapse = ", "),
       ". Nothing of STEP 13.2 is written. Read the description(s) (the ",
       "cached text is in ", meta_dir, "). Then add each key to ",
       "OCC_DATASET_CLEARED with the date and your reason, or amend Decision ",
       "21.", call. = FALSE)
}
cat("dataset check: no stop (", sum(ds_check$hit), " hit(s), all cleared).\n",
    sep = "")

# ---- Checks before the write --------------------------------------------------
fm <- as.matrix(tg_fails)
stopifnot(
  "a kept record fails a step" = !any(fm[tg_kept, , drop = FALSE]),
  "zero or equal coordinates must count zero (step 4)" =
    sum((tg_d$lat == 0 & tg_d$lon == 0) | tg_d$lat == tg_d$lon) == 0,
  "each obscured record must be iNaturalist with an uncertainty >= the minimum" =
    all(is_inat[tg_obscured]) &&
    all(tg_d$uncert_m[tg_obscured] >= OCC_OBSCURED_MIN_UNCERT_M),
  "each kept record must have a 1 km cell" = !anyNA(tg_cells$cell[tg_kept]),
  "the attrition must end at the kept records" =
    tg_attr$records_out[nrow(tg_attr)] == n_rec_5km,
  "the by-dataset rows must add up to the attrition" =
    all(vapply(OCC_STEP_ORDER, function(s)
      sum(tg_byds$n[tg_byds$item == paste0("removed_", s)]) ==
        tg_attr$removed[tg_attr$step == s], logical(1)))
)

# ---- Write: the two layers (gitignored), then the four tables -----------------
clean_sf <- tg[tg_kept, ]
clean_sf <- sf::st_sf(
  gbifID        = clean_sf$gbifID,
  datasetKey    = clean_sf$datasetKey,
  basisOfRecord = clean_sf$basisOfRecord,
  year          = as.integer(clean_sf$year_num),
  uncert_m      = clean_sf$uncert_m,
  uncert_set    = tg_uset[tg_kept],
  cell_1km      = tg_cells$cell[tg_kept],
  geometry      = sf::st_geometry(clean_sf)
)
obs_sf <- tg[tg_obscured, ]
obs_sf <- sf::st_sf(
  gbifID         = obs_sf$gbifID,
  datasetKey     = obs_sf$datasetKey,
  year           = as.integer(obs_sf$year_num),
  uncert_m       = obs_sf$uncert_m,
  cell02_lon_deg = obs_cell$cell02_lon_deg,
  cell02_lat_deg = obs_cell$cell02_lat_deg,
  geometry       = sf::st_geometry(obs_sf)
)
for (w in list(list(x = clean_sf, f = clean_out),
               list(x = obs_sf,   f = obscured_out))) {
  write_processed_vec(w$x, w$f, dir = DIR_PROCESSED)
  back <- sf::st_drop_geometry(sf::st_read(file.path(DIR_PROCESSED, w$f),
                                           quiet = TRUE))
  if (nrow(back) != nrow(w$x) ||
      !setequal(occ_id_chr(back$gbifID), occ_id_chr(w$x$gbifID))) {
    stop("Read-back check failed for ", w$f, ".", call. = FALSE)
  }
}
cat("layers read back: the same records.\n")

ds_tbl <- ds_check[, c("set", "datasetKey", "title", "n_1km", "n_5km",
                       "words_found", "hit", "cleared", "stop")]
occ_assert_counts_only(tg_attr, cols = names(tg_attr),
                       count_cols = c("records_in", "removed", "records_out"),
                       name = "tbl_15_occ_cleaning.csv")
occ_assert_counts_only(tg_byds, name = "tbl_15_occ_cleaning_by_dataset.csv",
                       cols = c("set", "datasetKey", "item", "n"))
occ_assert_counts_only(sets_tbl, cols = names(sets_tbl),
                       count_cols = c("records", "n_cells"),
                       name = "tbl_15_occ_sets.csv")
occ_assert_counts_only(ds_tbl, cols = names(ds_tbl),
                       count_cols = c("n_1km", "n_5km"),
                       name = "tbl_15_occ_dataset_check.csv")
write_table(tg_attr,  nn = 15, slug = "occ_cleaning")
write_table(tg_byds,  nn = 15, slug = "occ_cleaning_by_dataset")
write_table(sets_tbl, nn = 15, slug = "occ_sets")
write_table(ds_tbl,   nn = 15, slug = "occ_dataset_check")

rule(paste0("STEP 13.2 complete: the tiger records are cleaned (Decision 21). ",
            "Point 8: ", outcome, ".\nThe two layers hold precise positions: ",
            "check `git status --short` before a commit."))

}  # end if (RUN_CLEANING && RAW_STAGE == counts), STEP 13.2

# =============================================================================
# STEP 13.3 — Decision 21 on the background (task 13.4)
# =============================================================================
# The same nine steps, values and order as STEP 13.2 (Decision 21 point 7),
# with the same reference features. A kept record gets uncert_set and its 1 km
# cell (points 3 and 5) and ds_match: its dataset holds OCC_BG_MATCH_MIN_TIGER
# or more records of the tiger 1 km set. The obscured rule gives a count only
# (point 4). The dataset check of Amendment 2 runs on the background datasets
# too (process choice d1), with the same word list and cleared list. If it
# stops, NOTHING of STEP 13.3 is written; the STEP-13.2 outputs stay.
# Then the four tbl_15 tables are written again with the tiger rows and the
# background rows (process choice t1), and the taxa table is written.

if (RUN_CLEANING && RAW_STAGE == "counts") {

rule("STEP 13.3 — Decision 21 on the background (task 13.4)")

if (!isTRUE(OCC_BG_SAME_RULE)) {
  stop("OCC_BG_SAME_RULE must be TRUE (Decision 21 point 7).", call. = FALSE)
}

# ---- The nine steps (the same call as STEP 13.2) ------------------------------
bg   <- entry$background$sf
bg_d <- sf::st_drop_geometry(bg)
bg_cells <- occ_stack_cells(bg, stack_r)

bg_fails <- occ_step_fails(
  bg_d,
  status_keep   = OCC_STATUS_KEEP,
  basis_keep    = OCC_BASIS_KEEP,
  year_min      = OCC_YEAR_MIN,
  year_max      = OCC_YEAR_MAX,
  issue_remove  = OCC_ISSUE_REMOVE,
  uncert_wide   = OCC_UNCERT_WIDE_M,
  near_centroid = occ_near(bg, cent_sf, OCC_CENTROID_DIST_M),
  near_zoo      = occ_near(bg, zoos_sf, OCC_ZOO_DIST_M),
  complete      = bg_cells$complete
)[, OCC_STEP_ORDER]
bg_removed <- occ_first_fail(bg_fails, OCC_STEP_ORDER)
bg_kept    <- is.na(bg_removed)

bg_uset <- rep(NA_character_, nrow(bg_d))
bg_uset[bg_kept] <- occ_uncert_set(bg_d$uncert_m[bg_kept], OCC_UNCERT_MAIN_M,
                                   OCC_UNCERT_WIDE_M)

# ds_match (point 7): the datasets of the tiger 1 km set.
tg_1km_by_ds <- table(tg_d$datasetKey[tg_kept & tg_uset %in% "1km"])
match_keys   <- names(tg_1km_by_ds)[tg_1km_by_ds >= OCC_BG_MATCH_MIN_TIGER]
bg_match     <- bg_d$datasetKey %in% match_keys

# Obscured rule, for the count only (point 4).
bg_is_inat  <- bg_d$datasetKey == OCC_INAT_DATASET_KEY
bg_obscured <- bg_removed %in% "uncert" & bg_is_inat &
  bg_d$uncert_m >= OCC_OBSCURED_MIN_UNCERT_M

# ---- Attrition and sets -------------------------------------------------------
bg_attr <- occ_attrition(bg_removed, OCC_STEP_ORDER, set = "background")
bg_byds <- occ_by_dataset(bg_d$datasetKey, bg_removed, bg_uset, bg_obscured,
                          OCC_STEP_ORDER, set = "background")

cat("\n--- background: attrition (each record counted at the first step that",
    "it fails) ---\n")
show_attr <- bg_attr
show_attr$fail_in_any_order <- c(NA, colSums(bg_fails))
old_width <- options(width = 120)
print(show_attr, row.names = FALSE)
options(old_width)

k1  <- bg_kept & bg_uset %in% "1km"
km1 <- k1 & bg_match
bg_obs_cell <- occ_cell02(bg_d$lon[bg_obscured], bg_d$lat[bg_obscured],
                          OCC_OBSCURED_CELL_DEG)
bg_sets <- data.frame(
  set     = "background",
  subset  = c("1km", "5km", "matched_1km", "obscured"),
  records = c(sum(k1), sum(bg_kept), sum(km1), sum(bg_obscured)),
  n_cells = c(length(unique(bg_cells$cell[k1])),
              length(unique(bg_cells$cell[bg_kept])),
              length(unique(bg_cells$cell[km1])),
              nrow(unique(bg_obs_cell))),
  point8_outcome = "",
  stringsAsFactors = FALSE
)
cat("\n--- background: sets (n_cells: 1 km cells; for the obscured count,",
    "0.2 degree cells) ---\n")
print(bg_sets, row.names = FALSE)

cat("\nmatched datasets (with", OCC_BG_MATCH_MIN_TIGER, "or more records of",
    "the tiger 1 km set):\n")
for (k in match_keys) {
  cat(sprintf("  %s  tiger 1km %3d | background 1km %6d | background kept %6d\n",
              k, as.integer(tg_1km_by_ds[[k]]), sum(k1 & bg_d$datasetKey == k),
              sum(bg_kept & bg_d$datasetKey == k)))
}

# ---- Taxa (evidence for the pending item "target-group scope") ---------------
taxa_tbl <- occ_taxa_table(bg_d$order[bg_kept], bg_d$family[bg_kept],
                           bg_uset[bg_kept], bg_match[bg_kept],
                           set = "background")
cat("\n--- background: kept records by order (all families together) ---\n")
by_order <- stats::aggregate(
  cbind(records_1km, records_5km, records_matched_1km) ~ order,
  data = taxa_tbl, FUN = sum)
by_order <- by_order[order(-by_order$records_5km, by_order$order), ]
print(by_order, row.names = FALSE)
cat("(", nrow(taxa_tbl), " order and family rows in tbl_15_background_taxa.csv)\n",
    sep = "")

# ---- Dataset check on the background datasets (Amendment 2; d1) --------------
bg_ds_keys <- sort(unique(bg_d$datasetKey[bg_kept]))
bg_ds_meta <- occ_dataset_meta(bg_ds_keys, meta_dir)
bg_check   <- occ_dataset_check(bg_ds_meta, OCC_DATASET_FLAG_WORDS,
                                OCC_DATASET_CLEARED,
                                table(bg_d$datasetKey[k1]),
                                table(bg_d$datasetKey[bg_kept &
                                                        bg_uset %in% "5km"]),
                                set = "background")
cat("\n--- background: dataset check (Amendment 2; datasets with a kept",
    "record) ---\n")
for (i in seq_len(nrow(bg_check))) {
  cat(sprintf("  %s  1km %6d  5km %5d  %s\n", bg_check$datasetKey[i],
              bg_check$n_1km[i], bg_check$n_5km[i],
              if (bg_check$stop[i]) "STOP" else if (bg_check$hit[i])
                "hit, cleared" else "ok"))
  if (bg_check$hit[i]) {
    cat("    ", bg_check$title[i], "\n    words: ", bg_check$words_found[i],
        "\n", sep = "")
  }
}
if (any(bg_check$stop)) {
  stop("Dataset check (Decision 21, Amendment 2), background: ",
       sum(bg_check$stop), " dataset(s) with a kept record have words about ",
       "degraded, generalised or obscured positions: ",
       paste(bg_check$datasetKey[bg_check$stop], collapse = ", "),
       ". Nothing of STEP 13.3 is written (the STEP-13.2 outputs stay). Read ",
       "the description(s) (the cached text is in ", meta_dir, "). Then add ",
       "each key to OCC_DATASET_CLEARED with the date and your reason, or ",
       "amend Decision 21.", call. = FALSE)
}
cat("dataset check: no stop (", sum(bg_check$hit), " hit(s), all cleared).\n",
    sep = "")

# ---- Checks before the write --------------------------------------------------
bm <- as.matrix(bg_fails)
stopifnot(
  "a kept background record fails a step" = !any(bm[bg_kept, , drop = FALSE]),
  "the two sets must go through the same steps in the same order" =
    identical(names(bg_fails), names(tg_fails)),
  "zero or equal coordinates must count zero (step 4)" =
    sum((bg_d$lat == 0 & bg_d$lon == 0) | bg_d$lat == bg_d$lon) == 0,
  "step 3 must remove no background record (Decision 21 QA)" =
    sum(bg_fails$year) == 0,
  "each obscured background record must be iNaturalist with an uncertainty >= the minimum" =
    all(bg_is_inat[bg_obscured]) &&
    all(bg_d$uncert_m[bg_obscured] >= OCC_OBSCURED_MIN_UNCERT_M),
  "each kept background record must have a 1 km cell" =
    !anyNA(bg_cells$cell[bg_kept]),
  "the attrition must end at the kept records" =
    bg_attr$records_out[nrow(bg_attr)] == sum(bg_kept),
  "the by-dataset rows must add up to the attrition" =
    all(vapply(OCC_STEP_ORDER, function(s)
      sum(bg_byds$n[bg_byds$item == paste0("removed_", s)]) ==
        bg_attr$removed[bg_attr$step == s], logical(1))),
  "ds_match must be TRUE only for a matched dataset" =
    all(bg_d$datasetKey[bg_match] %in% match_keys)
)

# ---- Write: the clean background layer (gitignored), then the tables ---------
bg_sf <- bg[bg_kept, ]
bg_sf <- sf::st_sf(
  gbifID        = bg_sf$gbifID,
  datasetKey    = bg_sf$datasetKey,
  basisOfRecord = bg_sf$basisOfRecord,
  year          = as.integer(bg_sf$year_num),
  order         = bg_sf$order,
  family        = bg_sf$family,
  uncert_m      = bg_sf$uncert_m,
  uncert_set    = bg_uset[bg_kept],
  ds_match      = bg_match[bg_kept],
  cell_1km      = bg_cells$cell[bg_kept],
  geometry      = sf::st_geometry(bg_sf)
)
write_processed_vec(bg_sf, bg_clean_out, dir = DIR_PROCESSED)
back <- sf::st_drop_geometry(sf::st_read(file.path(DIR_PROCESSED, bg_clean_out),
                                         quiet = TRUE))
if (nrow(back) != nrow(bg_sf) ||
    !setequal(occ_id_chr(back$gbifID), occ_id_chr(bg_sf$gbifID))) {
  stop("Read-back check failed for ", bg_clean_out, ".", call. = FALSE)
}
cat("background layer read back: the same records.\n")

# ---- Write: the iNaturalist background of Decision 23 (gitignored) -----------
# Decision 23 r2 (2026-10-25), process choice w2 of task 14.2. Two parts, each
# with the 0.2 degree cell of the GBIF coordinates (occ_cell02(), the rule of
# Decision 21 point 4; a coordinate on an edge goes to the cell north or east
# of it):
#   "obscured" = the obscured background: removed at step 6, iNaturalist,
#                uncertainty >= OCC_OBSCURED_MIN_UNCERT_M (bg_obscured)
#   "uncert"   = the iNaturalist records of the clean background with
#                uncert_set in SDM_BG_UNCERT_SETS (the 5 km background)
# A record cannot be in the two parts: a part-"uncert" record passed step 6.
# This block prints record counts only, not a count of 0.2 degree cells
# (scripts/09 STEP 14.1 counts the cells after the model-cell rule).
inat_a  <- bg_obscured
inat_b  <- bg_kept & bg_is_inat & bg_uset %in% SDM_BG_UNCERT_SETS
inat_ab <- inat_a | inat_b
inat_cell <- occ_cell02(bg_d$lon[inat_ab], bg_d$lat[inat_ab],
                        OCC_OBSCURED_CELL_DEG)
stopifnot(
  "the two parts of the iNaturalist background must not share a record" =
    !any(inat_a & inat_b),
  "each record of the two parts must be of the iNaturalist dataset" =
    all(bg_d$datasetKey[inat_ab] == SDM_BG_DATASET_KEY),
  "the obscured part must be the obscured row of the background sets" =
    sum(inat_a) == bg_sets$records[bg_sets$subset == "obscured"] &&
    nrow(unique(inat_cell[inat_a[inat_ab], , drop = FALSE])) ==
      bg_sets$n_cells[bg_sets$subset == "obscured"],
  "each record of the two parts must have a 0.2 degree cell" =
    !anyNA(inat_cell$cell02_lon_deg) && !anyNA(inat_cell$cell02_lat_deg)
)
bg_inat <- bg[inat_ab, ]
bg_inat <- sf::st_sf(
  gbifID         = bg_inat$gbifID,
  datasetKey     = bg_inat$datasetKey,
  part           = ifelse(inat_a[inat_ab], "obscured", "uncert"),
  order          = bg_inat$order,
  family         = bg_inat$family,
  year           = as.integer(bg_inat$year_num),
  uncert_m       = bg_inat$uncert_m,
  uncert_set     = bg_uset[inat_ab],
  cell02_lon_deg = inat_cell$cell02_lon_deg,
  cell02_lat_deg = inat_cell$cell02_lat_deg,
  geometry       = sf::st_geometry(bg_inat)
)
write_processed_vec(bg_inat, bg_inat_out, dir = DIR_PROCESSED)
back <- sf::st_drop_geometry(sf::st_read(file.path(DIR_PROCESSED, bg_inat_out),
                                         quiet = TRUE))
if (nrow(back) != nrow(bg_inat) ||
    !setequal(occ_id_chr(back$gbifID), occ_id_chr(bg_inat$gbifID)) ||
    sum(back$part == "obscured") != sum(inat_a) ||
    sum(back$part == "uncert") != sum(inat_b)) {
  stop("Read-back check failed for ", bg_inat_out, ".", call. = FALSE)
}
cat("iNaturalist background layer (Decision 23 r2) read back: the same",
    "records.\n  records: obscured", sum(inat_a), "| uncert", sum(inat_b),
    "\n")

all_attr <- rbind(tg_attr, bg_attr)
all_byds <- rbind(tg_byds, bg_byds)
all_sets <- rbind(sets_tbl, bg_sets)
all_ds   <- rbind(ds_tbl, bg_check[, names(ds_tbl)])
occ_assert_counts_only(all_attr, cols = names(all_attr),
                       count_cols = c("records_in", "removed", "records_out"),
                       name = "tbl_15_occ_cleaning.csv")
occ_assert_counts_only(all_byds, cols = c("set", "datasetKey", "item", "n"),
                       name = "tbl_15_occ_cleaning_by_dataset.csv")
occ_assert_counts_only(all_sets, cols = names(all_sets),
                       count_cols = c("records", "n_cells"),
                       name = "tbl_15_occ_sets.csv")
occ_assert_counts_only(all_ds, cols = names(all_ds),
                       count_cols = c("n_1km", "n_5km"),
                       name = "tbl_15_occ_dataset_check.csv")
occ_assert_counts_only(taxa_tbl, cols = names(taxa_tbl),
                       count_cols = c("records_1km", "records_5km",
                                      "records_matched_1km"),
                       name = "tbl_15_background_taxa.csv")
write_table(all_attr, nn = 15, slug = "occ_cleaning")
write_table(all_byds, nn = 15, slug = "occ_cleaning_by_dataset")
write_table(all_sets, nn = 15, slug = "occ_sets")
write_table(all_ds,   nn = 15, slug = "occ_dataset_check")
write_table(taxa_tbl, nn = 15, slug = "background_taxa")

rule(paste0("STEP 13.3 complete: the background is cleaned by the same rule ",
            "(Decision 21 point 7).\nThe four tbl_15 tables now hold the ",
            "tiger rows and the background rows.\nThe iNaturalist ",
            "background of Decision 23 is written for scripts/09."))

}  # end if (RUN_CLEANING && RAW_STAGE == counts), STEP 13.3

# =============================================================================
# STEP 13.4 — density surfaces (task 13.6; Decision 22)
# =============================================================================
# Decision 22 (2026-10-17). Process choices of task 13.6 (2026-10-17): t1 the
# convolution is terra::focal() with fillvalue 0; k2 the functions are in
# R/00_functions_kde.R; n1 one file per surface; q2 the QA surfaces and the
# edge masses go to data/interim/; s1 two tables; r1 RUN_CLEANING; h1 the
# hand-made case first; v1 the read-back tolerance KDE_READBACK_REL_TOL.
#   1. the hand-made case (kde_self_test()); a failed check stops the run
#   2. the window: the complete-case cells of the covariate stack
#   3. the clean layers from disk, with three guards: the CRS; cell_1km is
#      the cell of the position on this stack; the counts are the counts of
#      tbl_15_occ_sets.csv (a stale layer or table stops the run)
#   4. the counts by window of the six clean sets (Decision 22 point 6)
#   5. the units of the three surfaces (Decision 22 points 2 to 4)
#   6. for each radius (KDE_RADIUS_M first, then KDE_RADII_QA_M): the edge
#      mass, then the three surfaces; at KDE_RADIUS_M also the effort window
#      surfaces that have KDE_WINDOW_MIN_UNITS units or more
#   7. the two tables (written last, after all surfaces)
# The console text holds counts and statistics only: no coordinate, no cell
# number, no position of a maximum. The tiger surface goes under data/ only
# (gitignored; Decision 22 point 9). STEP 13.4 runs only with RUN_SURFACES =
# TRUE (process choice x1).

if (RUN_SURFACES && RAW_STAGE == "counts") {

rule("STEP 13.4 — density surfaces (task 13.6; Decision 22)")
t_step <- proc.time()[["elapsed"]]

# ---- 1. Hand-made case (process choice h1) -----------------------------------
kde_check <- kde_self_test(GRID_CELL_M)
cat("\n--- hand-made case (made-up grid of 41 x 41 cells, radius 5 cells) ---\n")
for (i in seq_len(nrow(kde_check))) {
  cat(sprintf("  [%s] %s\n", if (kde_check$pass[i]) "PASS" else "FAIL",
              kde_check$check[i]))
}
if (!all(kde_check$pass)) {
  stop("The hand-made case failed (process choice h1). No surface is built.",
       call. = FALSE)
}
cat("hand-made case: ", sum(kde_check$pass), " of ", nrow(kde_check),
    " checks pass.\n", sep = "")

# ---- 2. Grid and window --------------------------------------------------------
stack_k <- terra::rast(stack_in)
stopifnot(
  "the covariate stack must be in the analysis CRS" =
    identical(as.character(terra::crs(stack_k, describe = TRUE)$code),
              as.character(CRS_ANALYSIS)),
  "the covariate stack must have square cells of GRID_CELL_M" =
    isTRUE(all.equal(terra::res(stack_k), c(GRID_CELL_M, GRID_CELL_M)))
)
win    <- kde_window(stack_k)
win_v  <- terra::values(win$win01, mat = FALSE)
grid_r <- terra::rast(stack_k, nlyrs = 1)   # the grid only, no values
rm(stack_k)
cat("\nwindow: ", win$n, " complete-case cells of ", terra::ncell(grid_r),
    " grid cells\n", sep = "")

# ---- 3. The clean layers (from disk) and their guards ---------------------------
read_clean <- function(f, need) {
  x <- sf::st_read(file.path(DIR_PROCESSED, f), quiet = TRUE)
  if (sf::st_crs(x) != sf::st_crs(CRS_ANALYSIS)) {
    stop(f, " is not in EPSG:", CRS_ANALYSIS, ".", call. = FALSE)
  }
  miss <- setdiff(need, names(x))
  if (length(miss) > 0) {
    stop(f, " does not have the field(s): ", paste(miss, collapse = ", "),
         ".", call. = FALSE)
  }
  x
}
tg_k <- read_clean(clean_out, c("year", "uncert_set", "cell_1km"))
bg_k <- read_clean(bg_clean_out, c("year", "uncert_set", "ds_match",
                                   "cell_1km"))
ob_k <- read_clean(obscured_out, c("year", "cell02_lon_deg",
                                   "cell02_lat_deg"))
# cell_1km must be the cell of the position on this stack (a stack that was
# built again after Week 13 has other cell numbers).
for (x in list(list(d = tg_k, f = clean_out), list(d = bg_k, f = bg_clean_out))) {
  cc <- terra::cellFromXY(grid_r,
                          sf::st_coordinates(x$d)[, 1:2, drop = FALSE])
  if (anyNA(x$d$cell_1km) ||
      !identical(as.integer(cc), as.integer(x$d$cell_1km))) {
    stop("cell_1km of ", x$f, " is not the cell of the position on the ",
         "current covariate stack. Run with RUN_CLEANING <- TRUE.",
         call. = FALSE)
  }
}
tg_a <- sf::st_drop_geometry(tg_k)
bg_a <- sf::st_drop_geometry(bg_k)
ob_a <- sf::st_drop_geometry(ob_k)
rm(tg_k, bg_k, ob_k, x, cc)
bg_a$ds_match <- as.logical(bg_a$ds_match)
# The key of the 0.2 degree cell, with all digits (as unique() in STEP 13.2).
ob_a$cell02   <- paste(sprintf("%.17g", ob_a$cell02_lon_deg),
                       sprintf("%.17g", ob_a$cell02_lat_deg))
if (anyNA(bg_a$ds_match) ||
    any(win_v[c(tg_a$cell_1km, bg_a$cell_1km)] != 1)) {
  stop("A clean record has no ds_match value, or is not on a complete-case ",
       "cell (Decision 21 step 9). Run with RUN_CLEANING <- TRUE.",
       call. = FALSE)
}

k_tg1 <- tg_a$uncert_set == "1km"
k_bg1 <- bg_a$uncert_set == "1km"
k_bgm <- k_bg1 & bg_a$ds_match
layer_sets <- data.frame(
  set     = c(rep("tiger", 3), rep("background", 3)),
  subset  = c("1km", "5km", "obscured", "1km", "5km", "matched_1km"),
  records = c(sum(k_tg1), nrow(tg_a), nrow(ob_a),
              sum(k_bg1), nrow(bg_a), sum(k_bgm)),
  n_cells = c(length(unique(tg_a$cell_1km[k_tg1])),
              length(unique(tg_a$cell_1km)),
              length(unique(ob_a$cell02)),
              length(unique(bg_a$cell_1km[k_bg1])),
              length(unique(bg_a$cell_1km)),
              length(unique(bg_a$cell_1km[k_bgm]))),
  stringsAsFactors = FALSE
)
sets_in <- utils::read.csv(sets_tbl_in, stringsAsFactors = FALSE)
cmp <- merge(layer_sets,
             sets_in[, c("set", "subset", "records", "n_cells")],
             by = c("set", "subset"), all.x = TRUE, sort = FALSE,
             suffixes = c("_layer", "_table"))
cat("\n--- guard: the clean layers on disk against tbl_15_occ_sets.csv ---\n")
print(cmp, row.names = FALSE)
if (anyNA(cmp$records_table) || any(cmp$records_layer != cmp$records_table) ||
    any(cmp$n_cells_layer != cmp$n_cells_table)) {
  stop("The clean layers on disk do not give the counts of ",
       "tbl_15_occ_sets.csv (a stale layer or a stale table). Run with ",
       "RUN_CLEANING <- TRUE.", call. = FALSE)
}
p8 <- sets_in$point8_outcome[sets_in$set == "tiger" & sets_in$subset == "1km"]
if (!identical(as.character(p8), OCC_POINT8_OUTCOME)) {
  stop("tbl_15_occ_sets.csv does not hold the outcome OCC_POINT8_OUTCOME (",
       OCC_POINT8_OUTCOME, ").", call. = FALSE)
}
cat("guard: the layers give the counts of the table; point 8 = ",
    OCC_POINT8_OUTCOME, ".\n", sep = "")

# ---- 4. Counts by window (Decision 22 point 6) -----------------------------------
wc <- rbind(
  kde_window_counts(tg_a$year[k_tg1], tg_a$cell_1km[k_tg1], "tiger", "1km",
                    KDE_WINDOWS, "cell_1km"),
  kde_window_counts(tg_a$year, tg_a$cell_1km, "tiger", "5km",
                    KDE_WINDOWS, "cell_1km"),
  kde_window_counts(ob_a$year, ob_a$cell02, "tiger", "obscured",
                    KDE_WINDOWS, "cell_0.2deg"),
  kde_window_counts(bg_a$year[k_bg1], bg_a$cell_1km[k_bg1], "background",
                    "1km", KDE_WINDOWS, "cell_1km"),
  kde_window_counts(bg_a$year, bg_a$cell_1km, "background", "5km",
                    KDE_WINDOWS, "cell_1km"),
  kde_window_counts(bg_a$year[k_bgm], bg_a$cell_1km[k_bgm], "background",
                    "matched_1km", KDE_WINDOWS, "cell_1km")
)
# Each record must be in exactly one window: the window records add up to
# the "all" row, and the "all" row is the set.
for (i in seq_len(nrow(layer_sets))) {
  r_i  <- wc[wc$set == layer_sets$set[i] & wc$subset == layer_sets$subset[i], ]
  in_w <- sum(r_i$records[r_i$window != "all"])
  if (in_w != r_i$records[r_i$window == "all"] ||
      r_i$records[r_i$window == "all"] != layer_sets$records[i]) {
    stop("The window counts of ", layer_sets$set[i], " ",
         layer_sets$subset[i], " do not add up (a record outside ",
         "KDE_WINDOWS).", call. = FALSE)
  }
}
cat("\n--- counts by window (units: 1 km cells; 0.2 degree cells for the",
    "obscured set) ---\n")
print(wc, row.names = FALSE)

# ---- 5. Units of the three surfaces (Decision 22 points 2 to 4) ------------------
in_kde_set <- function(d) d$uncert_set %in% KDE_UNCERT_SETS
setts_sf <- read_vec(setts_in)
if (!"place" %in% names(setts_sf)) {
  stop("The settlement layer has no `place` field: ", setts_in, call. = FALSE)
}
setts_sf <- setts_sf[setts_sf$place %in% KDE_SETTLEMENT_CLASSES, ]
if (nrow(setts_sf) == 0) {
  stop("No settlement point of the classes ",
       paste(KDE_SETTLEMENT_CLASSES, collapse = ", "), ".", call. = FALSE)
}
set_place <- setts_sf$place
set_cell  <- terra::cellFromXY(grid_r,
                               sf::st_coordinates(setts_sf)[, 1:2,
                                                            drop = FALSE])
rm(setts_sf)
set_in_grid <- !is.na(set_cell)
set_on_win  <- set_in_grid
set_on_win[set_in_grid] <- win_v[set_cell[set_in_grid]] == 1
cat("\n--- settlement points (Decision 22 points 3 and 4) ---\n")
print(as.data.frame(table(place = set_place), stringsAsFactors = FALSE),
      row.names = FALSE)
cat("points outside the grid: ", sum(!set_in_grid),
    " | on a cell that is not complete-case (not used): ",
    sum(set_in_grid & !set_on_win), "\n", sep = "")

units_list <- list(
  effort     = unique(bg_a$cell_1km[in_kde_set(bg_a)]),
  tiger      = unique(tg_a$cell_1km[in_kde_set(tg_a)]),
  settlement = unique(set_cell[set_on_win])
)
stopifnot("the unit list must follow KDE_SURFACES" =
            identical(names(units_list), KDE_SURFACES))
inputs_n <- c(effort = sum(in_kde_set(bg_a)), tiger = sum(in_kde_set(tg_a)),
              settlement = sum(set_on_win))
win_units <- lapply(KDE_WINDOW_SURFACES, function(nm) {
  yr <- KDE_WINDOWS[[nm]]
  k  <- in_kde_set(bg_a) & bg_a$year >= yr[1] & bg_a$year <= yr[2]
  unique(bg_a$cell_1km[k])
})
names(win_units) <- KDE_WINDOW_SURFACES
cat("\n--- units (complete-case 1 km cells with one or more inputs) ---\n")
print(data.frame(surface = names(units_list), inputs = inputs_n,
                 units = lengths(units_list)), row.names = FALSE)
cat("effort window surfaces (minimum ", KDE_WINDOW_MIN_UNITS, " units):\n",
    sep = "")
for (nm in names(win_units)) {
  cat(sprintf("  %-10s %d-%d: %d units -> %s\n", nm, KDE_WINDOWS[[nm]][1],
              KDE_WINDOWS[[nm]][2], length(win_units[[nm]]),
              if (length(win_units[[nm]]) >= KDE_WINDOW_MIN_UNITS) "built"
              else "NOT built (count only)"))
}

# ---- 6. Surfaces -------------------------------------------------------------------
cell_tag <- paste0(GRID_CELL_M / 1000, "km")
yrs_tag  <- function(lo, hi) paste(lo, hi, sep = "_")
kde_name <- function(tag, radius_m = NULL) {
  rr <- if (is.null(radius_m)) "" else sprintf("_r%gkm", radius_m / 1000)
  sprintf("kde_%s%s_%s_%d.tif", tag, rr, cell_tag, CRS_ANALYSIS)
}
surf_tag <- c(
  effort     = paste0("effort_", yrs_tag(OCC_YEAR_MIN, OCC_YEAR_MAX)),
  tiger      = paste0("tiger_", yrs_tag(OCC_YEAR_MIN, OCC_YEAR_MAX)),
  settlement = paste0("settlement_", paste(KDE_SETTLEMENT_CLASSES,
                                           collapse = ""))
)
surf_years <- list(effort = c(OCC_YEAR_MIN, OCC_YEAR_MAX),
                   tiger = c(OCC_YEAR_MIN, OCC_YEAR_MAX),
                   settlement = c(NA_integer_, NA_integer_))

summ  <- list()
radii <- c(KDE_RADIUS_M, KDE_RADII_QA_M)
cat("\n--- surfaces (values: units per km2; no position is printed) ---\n")
for (R in radii) {
  main <- R == KDE_RADIUS_M
  w    <- kde_weights(R, GRID_CELL_M)
  t0   <- proc.time()[["elapsed"]]
  mass <- kde_edge_mass(win$win01, w)
  write_processed_rast(mass, kde_name("edgemass", R), dir = DIR_INTERIM,
                       rel_tol = KDE_READBACK_REL_TOL)
  cat(sprintf("radius %g km: kernel %d x %d cells; edge mass %.0f s\n",
              R / 1000, nrow(w), ncol(w), proc.time()[["elapsed"]] - t0))

  jobs <- lapply(KDE_SURFACES, function(s) list(
    surface = s, role = if (main) "main" else "qa", units = units_list[[s]],
    years = surf_years[[s]],
    file = if (main) kde_name(surf_tag[[s]]) else kde_name(surf_tag[[s]], R),
    dir = if (main) DIR_PROCESSED else DIR_INTERIM))
  if (main) {
    for (nm in names(win_units)) {
      yr <- KDE_WINDOWS[[nm]]
      jobs[[length(jobs) + 1]] <- list(
        surface = "effort", role = "window", units = win_units[[nm]],
        years = yr, file = kde_name(paste0("effort_", yrs_tag(yr[1], yr[2]))),
        dir = DIR_PROCESSED)
    }
  }

  for (j in jobs) {
    built <- j$role != "window" || length(j$units) >= KDE_WINDOW_MIN_UNITS
    row <- data.frame(surface = j$surface, role = j$role,
                      year_min = as.integer(j$years[1]),
                      year_max = as.integer(j$years[2]),
                      radius_km = R / 1000, units = length(j$units),
                      built = built, value_min = NA_real_,
                      value_max = NA_real_, integral = NA_real_,
                      area_above0_km2 = NA_real_, cells_mass_low = NA_real_,
                      file = if (built) j$file else "",
                      stringsAsFactors = FALSE)
    if (built) {
      if (length(j$units) == 0) {
        stop("The ", j$surface, " surface has no unit.", call. = FALSE)
      }
      t1 <- proc.time()[["elapsed"]]
      u  <- kde_units_rast(grid_r, j$units, win_v)
      r  <- kde_surface(u, w, mass, GRID_CELL_M, name = j$surface)
      st <- kde_summary(r, mass, KDE_EDGE_FLAG_MASS, GRID_CELL_M)
      if (is.na(st$value_min) || st$value_min < 0 ||
          st$area_above0_km2 <= 0) {
        stop("The ", j$surface, " surface (", j$role, ", ", R / 1000,
             " km) has a value below 0, or no value above 0.", call. = FALSE)
      }
      write_processed_rast(r, j$file, dir = j$dir,
                           rel_tol = KDE_READBACK_REL_TOL)
      row[, names(st)] <- st
      cat(sprintf(paste0("  %-10s %-6s %s: %5d units | max %.4g | integral ",
                         "%.1f | area above 0 %.0f km2 | %.0f s\n"),
                  j$surface, j$role,
                  if (is.na(j$years[1])) "no years " else
                    paste0(j$years[1], "-", j$years[2]),
                  length(j$units), st$value_max, st$integral,
                  st$area_above0_km2, proc.time()[["elapsed"]] - t1))
      rm(u, r)
    } else {
      cat(sprintf("  %-10s %-6s %d-%d: %d units, below the minimum -> no surface\n",
                  j$surface, j$role, j$years[1], j$years[2],
                  length(j$units)))
      # A file of an earlier run must not stay as if it were this run's.
      old <- file.path(j$dir, j$file)
      if (file.exists(old)) {
        file.remove(old)
        cat("    the file of an earlier run was removed:", j$file, "\n")
      }
    }
    summ[[length(summ) + 1]] <- row
  }
  low <- terra::global(mass < KDE_EDGE_FLAG_MASS, "sum", na.rm = TRUE)[[1]]
  cat(sprintf("  window cells with an edge mass below %g at %g km: %.0f\n",
              KDE_EDGE_FLAG_MASS, R / 1000, low))
  rm(mass)
  invisible(gc())
}
summ_tbl <- do.call(rbind, summ)
rownames(summ_tbl) <- NULL

# ---- 7. Tables (no position) ---------------------------------------------------------
occ_assert_counts_only(wc, cols = names(wc),
                       count_cols = c("year_min", "year_max", "records",
                                      "units"),
                       name = "tbl_15_occ_window_counts.csv")
occ_assert_counts_only(summ_tbl, cols = names(summ_tbl),
                       count_cols = c("radius_km", "units"),
                       name = "tbl_15_kde_summary.csv")
write_table(wc,       nn = 15, slug = "occ_window_counts")
write_table(summ_tbl, nn = 15, slug = "kde_summary")

cat("\n--- summary (tbl_15_kde_summary.csv) ---\n")
print(summ_tbl[, c("surface", "role", "year_min", "year_max", "radius_km",
                   "units", "built", "value_max", "integral",
                   "area_above0_km2", "cells_mass_low")], row.names = FALSE)

rule(paste0("STEP 13.4 complete: ", sum(summ_tbl$built), " surfaces written ",
            "(Decision 22) in ",
            round((proc.time()[["elapsed"]] - t_step) / 60, 1), " min.\n",
            "The tiger surfaces are under data/ (gitignored): check ",
            "`git status --short` before a commit."))

}  # end if (RUN_SURFACES && RAW_STAGE == counts), STEP 13.4

# =============================================================================
# STEP 13.5 — QA (task 13.7; Decisions 21 and 22)
# =============================================================================
# Process choices of task 13.7 (2026-10-18): c1 the rules of Decision 21 are
# checked again on the kept records with the code of this step (not with
# occ_step_fails()); h1 the hand-made case of the rule functions first; x1
# the switch RUN_SURFACES; t1 tbl_15_occ_qa.csv (group, check, value, pass),
# written first, then any FALSE stops the script; s2 the radius comparison
# in its own table; p1 the publish checks.
# Groups: "test case", "tiger", "background", "obscured", "tables",
# "surfaces", "publish". The step reads files only (the GBIF zips for
# occurrenceStatus, issue and the public position of the obscured records).
# The console text and the two tables hold counts, names and statistics only.

if (RAW_STAGE == "counts") {

rule("STEP 13.5 — QA (task 13.7; Decisions 21 and 22)")
t_qa <- proc.time()[["elapsed"]]

qa <- list()
add_qa <- function(group, check, value, pass) {
  qa[[length(qa) + 1L]] <<- data.frame(group = group, check = check,
                                       value = as.character(value),
                                       pass = isTRUE(pass),
                                       stringsAsFactors = FALSE)
  invisible(NULL)
}
n_fail_txt <- function(n, of) sprintf("%d of %d records fail", n, of)

# ---- 1. Hand-made cases (process choice h1; Decision 22 h1) ---------------------
oc <- occ_self_test(
  status_keep = OCC_STATUS_KEEP, basis_keep = OCC_BASIS_KEEP,
  year_min = OCC_YEAR_MIN, year_max = OCC_YEAR_MAX,
  issue_remove = OCC_ISSUE_REMOVE, issue_report = OCC_ISSUE_REPORT,
  uncert_main = OCC_UNCERT_MAIN_M, uncert_wide = OCC_UNCERT_WIDE_M,
  order = OCC_STEP_ORDER, min_model = OCC_MIN_CELLS_MODEL,
  min_full = OCC_MIN_CELLS_FULL, cell_deg = OCC_OBSCURED_CELL_DEG,
  near_m = OCC_CENTROID_DIST_M)
for (i in seq_len(nrow(oc))) {
  add_qa("test case", paste("rules:", oc$check[i]),
         sprintf("expected %g, got %g", oc$expected[i], oc$got[i]),
         oc$pass[i])
}
kc <- kde_self_test(GRID_CELL_M)
for (i in seq_len(nrow(kc))) {
  add_qa("test case", paste("density:", kc$check[i]),
         sprintf("expected %.6g, got %.6g", kc$expected[i], kc$got[i]),
         kc$pass[i])
}
cat("hand-made cases: rules ", sum(oc$pass), " of ", nrow(oc),
    ", density ", sum(kc$pass), " of ", nrow(kc), " checks pass.\n", sep = "")

# ---- 2. Inputs (files on disk) ------------------------------------------------------
stack_q <- terra::rast(stack_in)
grid_q  <- terra::rast(stack_q, nlyrs = 1)
win_q   <- kde_window(stack_q)
win_qv  <- terra::values(win_q$win01, mat = FALSE)
rm(stack_q)
tg_q <- sf::st_read(file.path(DIR_PROCESSED, clean_out), quiet = TRUE)
bg_q <- sf::st_read(file.path(DIR_PROCESSED, bg_clean_out), quiet = TRUE)
ob_q <- sf::st_read(file.path(DIR_PROCESSED, obscured_out), quiet = TRUE)
for (x in list(tg_q, bg_q, ob_q)) {
  if (sf::st_crs(x) != sf::st_crs(CRS_ANALYSIS)) {
    stop("A clean layer is not in EPSG:", CRS_ANALYSIS, ".", call. = FALSE)
  }
}
zoos_q <- read_vec(zoos_in)
if (any(!sf::st_is_valid(zoos_q))) zoos_q <- sf::st_make_valid(zoos_q)
# Centroids for step 7, computed here (not with occ_centroids()).
cent_q <- do.call(c, lapply(list(read_vec(india_in), read_vec(states_in),
                                 read_vec(districts_in)), function(l) {
  g <- sf::st_geometry(l)
  suppressWarnings(sf::st_centroid(g[!sf::st_is_empty(g)]))
}))
z_t <- occ_read_fields(tiger_zip, c("gbifID", "occurrenceStatus",
                                    "basisOfRecord", "issue",
                                    "decimalLatitude", "decimalLongitude"))
z_b <- occ_read_fields(bg_zip, c("gbifID", "occurrenceStatus", "issue",
                                 "decimalLatitude", "decimalLongitude"))
tb <- function(slug) {
  f <- file.path(DIR_TABLES, paste0("tbl_15_", slug, ".csv"))
  if (!file.exists(f)) stop("Table not found: ", f, call. = FALSE)
  utils::read.csv(f, stringsAsFactors = FALSE)
}
t_raw  <- tb("occ_raw_counts")
t_att  <- tb("occ_cleaning")
t_byds <- tb("occ_cleaning_by_dataset")
t_sets <- tb("occ_sets")
t_dsch <- tb("occ_dataset_check")
t_win  <- tb("occ_window_counts")
t_kde  <- tb("kde_summary")
set_row <- function(set, subset, col) {
  v <- t_sets[[col]][t_sets$set == set & t_sets$subset == subset]
  if (length(v) == 1L) v else NA   # NA: the row is not in the table
}

# ---- 3. The rules of Decision 21, checked again on the kept records (c1) ------
# Each check counts the kept records that break a step; 0 passes.
qa_rules <- function(x, z, set) {
  d   <- sf::st_drop_geometry(x)
  n   <- nrow(d)
  id  <- occ_id_chr(d$gbifID)
  zi  <- match(id, occ_id_chr(z$gbifID))
  add_qa(set, "each kept record is in the GBIF file (by gbifID)",
         sprintf("%d of %d records found", sum(!is.na(zi)), n), !anyNA(zi))
  add_qa(set, "no gbifID is in the layer two times",
         sprintf("%d repeated", sum(duplicated(id))), !anyDuplicated(id))
  st <- z$occurrenceStatus[zi]
  k  <- sum(!(st %in% OCC_STATUS_KEEP))
  add_qa(set, "step 1: occurrenceStatus in OCC_STATUS_KEEP", n_fail_txt(k, n),
         k == 0)
  k  <- sum(!(d$basisOfRecord %in% OCC_BASIS_KEEP))
  add_qa(set, "step 2: basisOfRecord in OCC_BASIS_KEEP", n_fail_txt(k, n),
         k == 0)
  k  <- sum(is.na(d$year) | d$year < OCC_YEAR_MIN | d$year > OCC_YEAR_MAX)
  add_qa(set, "step 3: year in OCC_YEAR_MIN to OCC_YEAR_MAX",
         n_fail_txt(k, n), k == 0)
  fl <- strsplit(ifelse(is.na(z$issue[zi]), "", z$issue[zi]), ";",
                 fixed = TRUE)
  k  <- sum(vapply(fl, function(f) any(trimws(f) %in% OCC_ISSUE_REMOVE),
                   logical(1)))
  add_qa(set, "step 4: no flag of OCC_ISSUE_REMOVE (GBIF file)",
         n_fail_txt(k, n), k == 0)
  la <- suppressWarnings(as.numeric(z$decimalLatitude[zi]))
  lo <- suppressWarnings(as.numeric(z$decimalLongitude[zi]))
  k  <- sum(is.na(la) | is.na(lo) | (la == 0 & lo == 0) | la == lo)
  add_qa(set, "step 4: coordinates not missing, not 0/0, not equal",
         n_fail_txt(k, n), k == 0)
  u  <- d$uncert_m
  k  <- sum(is.na(u) | u <= 0)
  add_qa(set, "step 5: an uncertainty value above 0", n_fail_txt(k, n), k == 0)
  k  <- sum(!is.na(u) & u > OCC_UNCERT_WIDE_M)
  add_qa(set, "step 6: uncertainty <= OCC_UNCERT_WIDE_M", n_fail_txt(k, n),
         k == 0)
  dc <- as.numeric(sf::st_distance(
    x, cent_q[sf::st_nearest_feature(x, cent_q)], by_element = TRUE))
  k  <- sum(dc <= OCC_CENTROID_DIST_M)
  add_qa(set, "step 7: more than OCC_CENTROID_DIST_M from each centroid",
         n_fail_txt(k, n), k == 0)
  dz <- as.numeric(sf::st_distance(
    x, zoos_q[sf::st_nearest_feature(x, zoos_q), ], by_element = TRUE))
  k  <- sum(dz <= OCC_ZOO_DIST_M)
  add_qa(set, "step 8: more than OCC_ZOO_DIST_M from each zoo",
         n_fail_txt(k, n), k == 0)
  cc <- terra::cellFromXY(grid_q, sf::st_coordinates(x)[, 1:2, drop = FALSE])
  k  <- sum(is.na(cc) | win_qv[cc] != 1)
  add_qa(set, "step 9: the cell of the position is a complete-case cell",
         n_fail_txt(k, n), k == 0)
  k  <- sum(is.na(cc) | cc != d$cell_1km)
  add_qa(set, "cell_1km is the cell of the position", n_fail_txt(k, n),
         k == 0)
  k  <- sum(d$uncert_set != ifelse(u <= OCC_UNCERT_MAIN_M, "1km", "5km"))
  add_qa(set, "uncert_set agrees with the uncertainty (1km <= main limit)",
         n_fail_txt(k, n), k == 0)
  for (ss in c("1km", "5km")) {
    sel <- if (ss == "1km") d$uncert_set == "1km" else rep(TRUE, n)
    add_qa(set, paste0("one presence per cell (", OCC_THIN_RULE,
                       "): cells of the ", ss, " set = tbl_15_occ_sets"),
           sprintf("%d records, %d cells; table %d cells", sum(sel),
                   length(unique(d$cell_1km[sel])),
                   set_row(set, ss, "n_cells")),
           identical(OCC_THIN_RULE, "one_per_cell") &&
             length(unique(d$cell_1km[sel])) == set_row(set, ss, "n_cells") &&
             sum(sel) == set_row(set, ss, "records"))
  }
  invisible(d)
}
tg_qd <- qa_rules(tg_q, z_t, "tiger")
bg_qd <- qa_rules(bg_q, z_b, "background")
# ds_match (Decision 21 point 7): TRUE exactly for the datasets with
# OCC_BG_MATCH_MIN_TIGER or more records of the tiger 1 km set.
t1_n   <- table(tg_qd$datasetKey[tg_qd$uncert_set == "1km"])
m_keys <- names(t1_n)[t1_n >= OCC_BG_MATCH_MIN_TIGER]
k <- sum(as.logical(bg_qd$ds_match) != (bg_qd$datasetKey %in% m_keys))
add_qa("background", "ds_match = the dataset has a record of the tiger 1 km set",
       n_fail_txt(k, nrow(bg_qd)), k == 0)
k <- sum(bg_qd$uncert_set == "1km" & as.logical(bg_qd$ds_match))
add_qa("background", "matched 1 km set = tbl_15_occ_sets",
       sprintf("%d records; table %d", k,
               set_row("background", "matched_1km", "records")),
       k == set_row("background", "matched_1km", "records"))

# ---- 4. The obscured set (Decision 21 point 4) ------------------------------------
od <- sf::st_drop_geometry(ob_q)
oi <- match(occ_id_chr(od$gbifID), occ_id_chr(z_t$gbifID))
n_o <- nrow(od)
add_qa("obscured", "each record is in the GBIF file (by gbifID)",
       sprintf("%d of %d records found", sum(!is.na(oi)), n_o), !anyNA(oi))
k <- sum(od$datasetKey != OCC_INAT_DATASET_KEY)
add_qa("obscured", "each record has the iNaturalist dataset key",
       n_fail_txt(k, n_o), k == 0)
k <- sum(is.na(od$uncert_m) | od$uncert_m < OCC_OBSCURED_MIN_UNCERT_M)
add_qa("obscured", "each uncertainty >= OCC_OBSCURED_MIN_UNCERT_M",
       n_fail_txt(k, n_o), k == 0)
k <- sum(!(z_t$occurrenceStatus[oi] %in% OCC_STATUS_KEEP) |
           !(z_t$basisOfRecord[oi] %in% OCC_BASIS_KEEP) |
           is.na(od$year) | od$year < OCC_YEAR_MIN | od$year > OCC_YEAR_MAX)
add_qa("obscured", "steps 1 to 3 hold (status, record type, year)",
       n_fail_txt(k, n_o), k == 0)
ofl <- strsplit(ifelse(is.na(z_t$issue[oi]), "", z_t$issue[oi]), ";",
                fixed = TRUE)
k <- sum(vapply(ofl, function(f) any(trimws(f) %in% OCC_ISSUE_REMOVE),
                logical(1)))
add_qa("obscured", "step 4 holds (no flag of OCC_ISSUE_REMOVE)",
       n_fail_txt(k, n_o), k == 0)
ola <- suppressWarnings(as.numeric(z_t$decimalLatitude[oi]))
olo <- suppressWarnings(as.numeric(z_t$decimalLongitude[oi]))
eps <- 1e-9
k <- sum(is.na(ola) | is.na(olo) |
           olo < od$cell02_lon_deg - eps |
           olo >= od$cell02_lon_deg + OCC_OBSCURED_CELL_DEG - eps |
           ola < od$cell02_lat_deg - eps |
           ola >= od$cell02_lat_deg + OCC_OBSCURED_CELL_DEG - eps)
add_qa("obscured", "the public position is inside its 0.2 degree cell",
       n_fail_txt(k, n_o), k == 0)
k <- length(intersect(occ_id_chr(od$gbifID), occ_id_chr(tg_qd$gbifID)))
add_qa("obscured", "no obscured record is in the clean tiger layer",
       sprintf("%d records in both", k), k == 0)
add_qa("obscured", "records = tbl_15_occ_sets",
       sprintf("%d; table %d", n_o, set_row("tiger", "obscured", "records")),
       n_o == set_row("tiger", "obscured", "records"))
rm(z_t, z_b)

# ---- 5. The tables on disk ----------------------------------------------------------
att_set <- list()
for (set in c("tiger", "background")) {
  a <- t_att[t_att$set == set, ]
  a <- a[order(a$step_order), ]
  att_set[[set]] <- a
  ok_names <- identical(a$step, c("entry_state", OCC_STEP_ORDER))
  ok_flow  <- nrow(a) > 1 &&
    all(a$records_out == a$records_in - a$removed) &&
    all(a$records_in[-1] == a$records_out[-nrow(a)])
  n_layer  <- if (set == "tiger") nrow(tg_qd) else nrow(bg_qd)
  n_entry  <- t_raw$n[t_raw$set == set & t_raw$field == "records" &
                        t_raw$value == "entry_state"]
  add_qa("tables", paste0("attrition (", set, "): the steps of Decision 21 ",
                          "in order"),
         paste(nrow(a) - 1L, "steps"), ok_names)
  add_qa("tables", paste0("attrition (", set, "): out = in - removed; each ",
                          "step starts at the last out"),
         sprintf("%d rows", nrow(a)), ok_flow)
  add_qa("tables", paste0("attrition (", set, "): entry = raw entry state; ",
                          "last out = records of the layer"),
         sprintf("entry %d (raw %s); last out %d (layer %d)", a$records_in[1],
                 paste(n_entry, collapse = "/"), a$records_out[nrow(a)],
                 n_layer),
         length(n_entry) == 1 && a$records_in[1] == n_entry &&
           a$records_out[nrow(a)] == n_layer)
  bd <- t_byds[t_byds$set == set, ]
  ok_bd <- all(vapply(OCC_STEP_ORDER, function(s)
    sum(bd$n[bd$item == paste0("removed_", s)]) == a$removed[a$step == s],
    logical(1))) &&
    sum(bd$n[bd$item %in% c("kept_1km", "kept_5km")]) == n_layer &&
    sum(bd$n[bd$item == "entry_state"]) == a$records_in[1]
  add_qa("tables", paste0("by dataset (", set, "): the rows add up to the ",
                          "attrition"),
         sprintf("%d datasets", length(unique(bd$datasetKey))), ok_bd)
  ct <- t_raw$n[t_raw$set == set & t_raw$field == "coord_test"]
  add_qa("tables", paste0("raw counts (", set, "): the two coordinate tests ",
                          "of step 4 count 0"),
         sprintf("%s", paste(ct, collapse = ", ")),
         length(ct) == 2 && all(ct == 0))
}
add_qa("tables", "the tiger and the background went through the same steps",
       paste(nrow(att_set$tiger) - 1L, "steps each"),
       identical(att_set$tiger$step, att_set$background$step))
k <- att_set$background$removed[att_set$background$step == "year"]
add_qa("tables", "step 3 removes no background record",
       sprintf("%d removed", k), length(k) == 1 && k == 0)
k <- sum(as.logical(t_dsch$stop))
add_qa("tables", "dataset check (Amendment 2): no stop",
       sprintf("%d of %d rows with a stop", k, nrow(t_dsch)), k == 0)
p8  <- set_row("tiger", "1km", "point8_outcome")
nc1 <- set_row("tiger", "1km", "n_cells")
p8b <- if (nc1 < OCC_MIN_CELLS_MODEL) "no_1km_model" else
  if (nc1 < OCC_MIN_CELLS_FULL) "reduced_model" else "planned_model"
add_qa("tables", "point 8: the table, the config and a new comparison agree",
       sprintf("%d cells -> %s; table %s; config %s", nc1, p8b, p8,
               OCC_POINT8_OUTCOME),
       identical(p8, OCC_POINT8_OUTCOME) && identical(p8b, OCC_POINT8_OUTCOME))
ws <- unique(t_win[, c("set", "subset")])
for (i in seq_len(nrow(ws))) {
  w <- t_win[t_win$set == ws$set[i] & t_win$subset == ws$subset[i], ]
  add_qa("tables", paste0("window counts (", ws$set[i], " ", ws$subset[i],
                          "): windows add up to all, all = tbl_15_occ_sets"),
         sprintf("%d records", w$records[w$window == "all"]),
         sum(w$records[w$window != "all"]) == w$records[w$window == "all"] &&
           w$records[w$window == "all"] ==
           set_row(ws$set[i], ws$subset[i], "records"))
}
add_qa("tables", "window counts: the six sets of Decision 22 point 6",
       sprintf("%d sets", nrow(ws)), nrow(ws) == 6L)
n_kde_exp <- length(KDE_SURFACES) * (1 + length(KDE_RADII_QA_M)) +
  length(KDE_WINDOW_SURFACES)
add_qa("tables", "tbl_15_kde_summary.csv has one row per surface and radius",
       sprintf("%d rows; expected %d", nrow(t_kde), n_kde_exp),
       nrow(t_kde) == n_kde_exp)

# ---- 6. The surfaces and the edge masses (Decision 22) ------------------------------
kde_dir <- function(role) if (role == "qa") DIR_INTERIM else DIR_PROCESSED
# The expected units of each surface, counted here from the layers.
in_kde <- function(d) d$uncert_set %in% KDE_UNCERT_SETS
setts_q <- read_vec(setts_in)
setts_q <- setts_q[setts_q$place %in% KDE_SETTLEMENT_CLASSES, ]
sc_q    <- terra::cellFromXY(grid_q, sf::st_coordinates(setts_q)[, 1:2,
                                                               drop = FALSE])
sc_q    <- sc_q[!is.na(sc_q)]
units_q <- list(effort = unique(bg_qd$cell_1km[in_kde(bg_qd)]),
                tiger = unique(tg_qd$cell_1km[in_kde(tg_qd)]),
                settlement = unique(sc_q[win_qv[sc_q] == 1]))
rm(setts_q, sc_q)
win_units_q <- function(lo, hi) {
  unique(bg_qd$cell_1km[in_kde(bg_qd) & bg_qd$year >= lo & bg_qd$year <= hi])
}
for (i in seq_len(nrow(t_kde))) {
  rw  <- t_kde[i, ]
  lab <- sprintf("%s %s %g km%s", rw$surface, rw$role, rw$radius_km,
                 if (rw$role == "window") paste0(" ", rw$year_min, "-",
                                                 rw$year_max) else "")
  if (!isTRUE(as.logical(rw$built))) {
    # A window surface below the minimum: no file of that window may exist.
    f_old <- file.path(DIR_PROCESSED, sprintf(
      "kde_effort_%d_%d_%gkm_%d.tif", rw$year_min, rw$year_max,
      GRID_CELL_M / 1000, CRS_ANALYSIS))
    add_qa("surfaces", paste0(lab, ": not built, below the minimum; no file"),
           sprintf("%d units; minimum %d", rw$units, KDE_WINDOW_MIN_UNITS),
           rw$role == "window" && rw$units < KDE_WINDOW_MIN_UNITS &&
             !file.exists(f_old))
    next
  }
  f <- file.path(kde_dir(rw$role), rw$file)
  if (!file.exists(f)) {
    add_qa("surfaces", paste0(lab, ": the file exists"), rw$file, FALSE)
    next
  }
  r  <- terra::rast(f)
  v  <- terra::values(r, mat = FALSE)
  exp_units <- if (rw$role == "window") {
    length(win_units_q(rw$year_min, rw$year_max))
  } else length(units_q[[rw$surface]])
  add_qa("surfaces", paste0(lab, ": the grid of the covariate stack"),
         sprintf("%d x %d cells", terra::ncol(r), terra::nrow(r)),
         isTRUE(terra::compareGeom(r, grid_q, stopOnError = FALSE)))
  add_qa("surfaces", paste0(lab, ": no value below 0"),
         sprintf("min %.3g", min(v, na.rm = TRUE)),
         min(v, na.rm = TRUE) >= 0)
  k <- sum(is.na(v) != (win_qv != 1))
  add_qa("surfaces", paste0(lab, ": NA exactly on the cells that are not ",
                            "complete-case"),
         sprintf("%d cells differ", k), k == 0)
  add_qa("surfaces", paste0(lab, ": units = the cells of its input"),
         sprintf("%d units; counted again %d", rw$units, exp_units),
         rw$units == exp_units)
  integ <- sum(v, na.rm = TRUE) * (GRID_CELL_M / 1000)^2
  add_qa("surfaces", paste0(lab, ": the file gives the integral of the ",
                            "summary"),
         sprintf("%.4f; summary %.4f", integ, rw$integral),
         abs(integ - rw$integral) <= 1e-6 * max(1, abs(rw$integral)))
  rm(r, v)
}
for (R in c(KDE_RADIUS_M, KDE_RADII_QA_M)) {
  f <- file.path(DIR_INTERIM, sprintf("kde_edgemass_r%gkm_%skm_%d.tif",
                                      R / 1000, GRID_CELL_M / 1000,
                                      CRS_ANALYSIS))
  lab <- sprintf("edge mass %g km", R / 1000)
  if (!file.exists(f)) {
    add_qa("surfaces", paste0(lab, ": the file exists"), basename(f), FALSE)
    next
  }
  m <- terra::values(terra::rast(f), mat = FALSE)
  low <- sum(m < KDE_EDGE_FLAG_MASS, na.rm = TRUE)
  low_tbl <- unique(t_kde$cells_mass_low[t_kde$radius_km == R / 1000 &
                                           as.logical(t_kde$built)])
  add_qa("surfaces", paste0(lab, ": above 0 and at most 1 on the window, NA ",
                            "elsewhere"),
         sprintf("min %.4g, max %.6g", min(m, na.rm = TRUE),
                 max(m, na.rm = TRUE)),
         min(m, na.rm = TRUE) > 0 && max(m, na.rm = TRUE) <= 1 + 1e-6 &&
           sum(is.na(m) != (win_qv != 1)) == 0)
  add_qa("surfaces", paste0(lab, ": cells below KDE_EDGE_FLAG_MASS = the ",
                            "summary"),
         sprintf("%d; summary %s", low, paste(low_tbl, collapse = "/")),
         length(low_tbl) == 1 && low == low_tbl)
  if (R == KDE_RADIUS_M) mass20_low <- which(!is.na(m) & m < KDE_EDGE_FLAG_MASS)
  rm(m)
}
# Direct calculation at sample cells (no focal()) for the three surfaces at
# KDE_RADIUS_M: 15 random window cells, 15 window cells with an edge mass
# below KDE_EDGE_FLAG_MASS and 15 cells with a value above 0. No position is
# printed.
set.seed(20261018L)
win_cells <- which(win_qv == 1)
for (s in KDE_SURFACES) {
  rw <- t_kde[t_kde$surface == s & t_kde$role == "main", ]
  f  <- file.path(DIR_PROCESSED, rw$file)
  if (nrow(rw) != 1 || !file.exists(f)) next
  r  <- terra::rast(f)
  pos <- which(terra::values(r, mat = FALSE) > 0)
  smp <- unique(c(sample(win_cells, 15),
                  if (exists("mass20_low") && length(mass20_low) > 0)
                    mass20_low[sample.int(length(mass20_low),
                                          min(15, length(mass20_low)))],
                  pos[sample.int(length(pos), min(15, length(pos)))]))
  dc <- kde_direct_check(r, units_q[[s]], win_qv, KDE_RADIUS_M, GRID_CELL_M,
                         smp)
  add_qa("surfaces", paste0(s, " main ", KDE_RADIUS_M / 1000, " km: a direct ",
                            "calculation at sample cells agrees (1e-5)"),
         sprintf("%d cells, max relative difference %.2g", dc$cells,
                 dc$max_rel_diff),
         dc$max_rel_diff <= 1e-5)
  rm(r, pos)
}

# The radius comparison (Decision 22 point 5; s2): descriptive, no rule.
rc <- list()
for (s in KDE_SURFACES) {
  fm <- t_kde$file[t_kde$surface == s & t_kde$role == "main"]
  for (R in KDE_RADII_QA_M) {
    fq <- t_kde$file[t_kde$surface == s & t_kde$role == "qa" &
                       t_kde$radius_km == R / 1000]
    cmp_r <- if (length(fm) == 1 && length(fq) == 1 &&
                 file.exists(file.path(DIR_PROCESSED, fm)) &&
                 file.exists(file.path(DIR_INTERIM, fq))) {
      kde_compare(terra::rast(file.path(DIR_PROCESSED, fm)),
                  terra::rast(file.path(DIR_INTERIM, fq)))
    } else data.frame(spearman = NA_real_, cells_compared = 0L)
    rc[[length(rc) + 1L]] <- data.frame(
      surface = s, radius_km = R / 1000, spearman = cmp_r$spearman,
      cells_compared = as.integer(cmp_r$cells_compared),
      stringsAsFactors = FALSE)
  }
}
rc_tbl <- do.call(rbind, rc)
add_qa("surfaces", "radius comparison: a Spearman value for each surface and QA radius",
       sprintf("%d of %d computed", sum(!is.na(rc_tbl$spearman)), nrow(rc_tbl)),
       !anyNA(rc_tbl$spearman))
cat("\n--- radius comparison (Decision 22 point 5; descriptive, no rule) ---\n")
print(rc_tbl, row.names = FALSE)

# ---- 7. Publish checks (p1) --------------------------------------------------------------
source(here("R", "00_functions_sensitive.R"))   # assert_publishable_rast()
for (i in which(as.logical(t_kde$built) & t_kde$surface != "tiger" &
                t_kde$role != "qa")) {
  f  <- file.path(DIR_PROCESSED, t_kde$file[i])
  ok <- file.exists(f) && is.null(tryCatch({
    assert_publishable_rast(terra::rast(f)); NULL
  }, error = function(e) conditionMessage(e)))
  add_qa("publish", paste0("assert_publishable_rast(): ", t_kde$surface[i],
                           " ", t_kde$role[i],
                           if (t_kde$role[i] == "window")
                             paste0(" ", t_kde$year_min[i], "-",
                                    t_kde$year_max[i]) else ""),
         sprintf("cell %g m; floor %g m", GRID_CELL_M, PUBLISH_FLOOR_M), ok)
}
out_files <- list.files(here("outputs"), recursive = TRUE)
k <- sum(grepl("tiger", basename(out_files), ignore.case = TRUE))
add_qa("publish", "no file with \"tiger\" in its name under outputs/",
       sprintf("%d of %d files", k, length(out_files)), k == 0)
tg_files <- t_kde$file[t_kde$surface == "tiger" & as.logical(t_kde$built)]
tg_paths <- file.path(vapply(t_kde$role[t_kde$surface == "tiger" &
                                          as.logical(t_kde$built)],
                             kde_dir, character(1)), tg_files)
out_root_q <- normalizePath(here("outputs"), winslash = "/", mustWork = FALSE)
k <- sum(!file.exists(tg_paths) |
           startsWith(normalizePath(tg_paths, winslash = "/",
                                    mustWork = FALSE), out_root_q))
add_qa("publish", "each tiger surface is under data/ (gitignored), not outputs/",
       sprintf("%d files; %d wrong", length(tg_paths), k),
       length(tg_paths) > 0 && k == 0)
# The tbl_15 tables: no position or cell column, and each number column is a
# count or a statistic of a known name (a value test gives false hits: an
# integral such as 44.08 looks like a degree).
num_ok <- c("step_order", "records_in", "removed", "records_out", "n",
            "records", "n_cells", "n_1km", "n_5km", "records_1km",
            "records_5km", "records_matched_1km", "year_min", "year_max",
            "units", "radius_km", "value_min", "value_max", "integral",
            "area_above0_km2", "cells_mass_low", "spearman", "cells_compared",
            # tbl_15_occ_by_reserve.csv (task 13.8, STEP 13.6)
            "unit_id", "tiger_1km_records", "tiger_1km_cells",
            "tiger_5km_records", "tiger_5km_cells", "background_5km_records",
            "background_5km_cells")
pos_re <- paste0("^(x|y|lon|lat|longitude|latitude|geom|geometry|cell|",
                 "cells)$|^cell_|cell02|_cell$")
occ_assert_counts_only(rc_tbl, cols = names(rc_tbl),
                       count_cols = c("radius_km", "cells_compared"),
                       name = "tbl_15_kde_radius_compare.csv")
write_table(rc_tbl, nn = 15, slug = "kde_radius_compare")
# (tbl_15_occ_qa.csv itself is left out: it is written below, and a copy of
# an earlier run would change the number of checks.)
for (f in setdiff(list.files(DIR_TABLES, pattern = "^tbl_15_.*\\.csv$"),
                  "tbl_15_occ_qa.csv")) {
  x <- utils::read.csv(file.path(DIR_TABLES, f), stringsAsFactors = FALSE)
  bad_pos <- names(x)[grepl(pos_re, tolower(names(x)))]
  num     <- names(x)[vapply(x, is.numeric, logical(1))]
  bad_num <- setdiff(num, num_ok)
  add_qa("publish", paste0(f, ": no position or cell column; numbers are ",
                           "counts or statistics"),
         if (length(c(bad_pos, bad_num)) == 0) paste(ncol(x), "columns") else
           paste("columns:", paste(unique(c(bad_pos, bad_num)),
                                   collapse = ", ")),
         length(bad_pos) == 0 && length(bad_num) == 0)
}

# ---- 8. Write the QA table, then stop on a failure (t1) -----------------------------
qa_tbl <- do.call(rbind, qa)
rownames(qa_tbl) <- NULL
occ_assert_counts_only(qa_tbl, cols = c("group", "check", "value", "pass"),
                       count_cols = character(0),
                       name = "tbl_15_occ_qa.csv")
write_table(qa_tbl, nn = 15, slug = "occ_qa")
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
  stop("QA: ", n_bad, " of ", nrow(qa_tbl), " checks fail. tbl_15_occ_qa.csv ",
       "is written; find the cause before any commit.", call. = FALSE)
}
rule(paste0("STEP 13.5 complete: QA ", nrow(qa_tbl), " of ", nrow(qa_tbl),
            " checks pass (", round((proc.time()[["elapsed"]] - t_qa) / 60, 1),
            " min).\nCheck `git status --short` before a commit: no ",
            "kde_tiger_* file and no clean layer may be staged."))

}  # end if (RAW_STAGE == counts), STEP 13.5

# =============================================================================
# STEP 13.6 — clean records per reserve (task 13.8; Decision 22 point 9)
# =============================================================================
# Process choices of task 13.8 (2026-10-18): s1 six counts (tiger 1 km set,
# tiger 5 km set, background 5 km set; records and 1 km cells); r1 a record
# is in a reserve if its position is in the polygon (an edge counts); p1 one
# table, a tiger count of 1 or 2 written "<3", no file of the exact tiger
# counts; w1 58 rows, the totals in the console only; x1 a STEP of its own
# with its own checks (a failure stops the script); o1 (2026-10-18, after the
# first run stopped on 13 background records in two polygons) a record in two
# or more overlapping reserve polygons counts in each of them.
# "In a reserve" is the KML core polygon (plan pitfall): a record in a buffer
# zone is outside. A record of the 5 km set can be up to 5 km from its true
# position. The obscured set is not used (its position is random in a cell of
# 0.2 degree). The console text holds the published counts only.

if (RAW_STAGE == "counts") {

rule("STEP 13.6 — clean records per reserve (task 13.8; Decision 22 point 9)")

res_all <- read_vec(reserves_in)
res_all$unit_id <- as.integer(round(res_all$unit_id))
stopifnot(
  "the reserve layer needs unit_id, unit_name, state, landscape_complex, geometry_present" =
    all(c("unit_id", "unit_name", "state", "landscape_complex",
          "geometry_present") %in% names(res_all)),
  "unit_id must be unique and not NA" =
    !anyNA(res_all$unit_id) && !anyDuplicated(res_all$unit_id)
)
res_all <- res_all[order(res_all$unit_id), ]
has_poly <- as.logical(res_all$geometry_present) &
  !sf::st_is_empty(sf::st_geometry(res_all))
res_poly <- res_all[has_poly, ]
cat("reserves: ", nrow(res_all), " (with a polygon: ", sum(has_poly),
    "; no polygon: ", sum(!has_poly), ")\n", sep = "")

tg_r <- sf::st_read(file.path(DIR_PROCESSED, clean_out), quiet = TRUE)
bg_r <- sf::st_read(file.path(DIR_PROCESSED, bg_clean_out), quiet = TRUE)
if (sf::st_crs(tg_r) != sf::st_crs(res_poly) ||
    sf::st_crs(bg_r) != sf::st_crs(res_poly)) {
  stop("The clean layers and the reserve layer are not in one CRS.",
       call. = FALSE)
}
in_tg <- occ_reserve_index(tg_r, res_poly)
in_bg <- occ_reserve_index(bg_r, res_poly)
tg_rd <- sf::st_drop_geometry(tg_r)
bg_rd <- sf::st_drop_geometry(bg_r)
rm(tg_r, bg_r)

# Overlaps of reserve polygons (process choice o1): the pairs, and the records
# of each set in both polygons of a pair. Names and counts only.
ovl <- occ_reserve_overlaps(res_poly)
both_n <- function(hits, keep, a, b) {
  sum(keep & vapply(hits, function(h) a %in% h && b %in% h, logical(1)))
}
k_t1 <- tg_rd$uncert_set == "1km"
cat("\n--- reserve polygons that overlap (o1: a record in both counts in each) ---\n")
if (nrow(ovl) == 0) {
  cat("none\n")
} else {
  old_width <- options(width = 160)   # one table, with no wrap
  print(data.frame(
    unit_id_a = res_poly$unit_id[ovl$a], name_a = res_poly$unit_name[ovl$a],
    unit_id_b = res_poly$unit_id[ovl$b], name_b = res_poly$unit_name[ovl$b],
    overlap_km2 = round(ovl$overlap_km2, 3),
    tiger_5km_records_in_both = vapply(seq_len(nrow(ovl)), function(k)
      both_n(in_tg$hits, rep(TRUE, nrow(tg_rd)), ovl$a[k], ovl$b[k]),
      integer(1)),
    background_5km_records_in_both = vapply(seq_len(nrow(ovl)), function(k)
      both_n(in_bg$hits, rep(TRUE, nrow(bg_rd)), ovl$a[k], ovl$b[k]),
      integer(1))), row.names = FALSE)
  options(old_width)
}

# Exact counts per reserve with a polygon (in memory only; p1). A record
# counts in each reserve that holds it (o1).
count_by_res <- function(d, keep, long) {
  L  <- long[keep[long$rec], , drop = FALSE]
  rr <- seq_len(nrow(res_poly))
  data.frame(
    records = vapply(rr, function(i) sum(L$res == i), integer(1)),
    cells   = vapply(rr, function(i)
      length(unique(d$cell_1km[L$rec[L$res == i]])), integer(1)))
}
set_keep <- list(tiger_1km = k_t1, tiger_5km = rep(TRUE, nrow(tg_rd)),
                 background_5km = rep(TRUE, nrow(bg_rd)))
set_idx  <- list(tiger_1km = in_tg, tiger_5km = in_tg, background_5km = in_bg)
cnt <- lapply(names(set_keep), function(nm)
  count_by_res(if (nm == "background_5km") bg_rd else tg_rd, set_keep[[nm]],
               set_idx[[nm]]$long))
names(cnt) <- names(set_keep)

# Check: inside + outside = the set; the reserve rows add up to the records
# inside plus the extra counts of the records in two or more polygons.
cat("\n--- totals (console only; process choice w1) ---\n")
for (nm in names(cnt)) {
  k     <- set_keep[[nm]]
  nh    <- lengths(set_idx[[nm]]$hits)
  ins   <- sum(k & nh > 0)
  outs  <- sum(k & nh == 0)
  multi <- sum(k & nh > 1)
  extra <- sum((nh - 1L)[k & nh > 1])
  if (ins + outs != sum(k) || sum(cnt[[nm]]$records) != ins + extra) {
    stop("STEP 13.6: the counts of ", nm, " do not add up.", call. = FALSE)
  }
  cat(sprintf(paste0("  %-15s %5d records: %5d inside a reserve polygon (%d ",
                     "reserves), %5d outside; %d in two or more polygons\n"),
              nm, sum(k), ins, sum(cnt[[nm]]$records > 0), outs, multi))
}

# warn_small_n() on the exact tiger counts above 0 (a count of 0 shows no
# position), then the suppression of Decision 22 point 9.
for (nm in c("tiger_1km", "tiger_5km")) {
  for (cl in c("records", "cells")) {
    x <- cnt[[nm]][cnt[[nm]][[cl]] > 0, , drop = FALSE]
    if (nrow(x) > 0) warn_small_n(x, cl, min_n = KDE_SMALL_N)
  }
}

# The published table: 58 rows; NA for a reserve with no polygon.
full_col <- function(v) { out <- rep(NA_integer_, nrow(res_all))
  out[has_poly] <- v; out }
occ_res <- data.frame(
  unit_id           = res_all$unit_id,
  unit_name         = res_all$unit_name,
  state             = res_all$state,
  landscape_complex = res_all$landscape_complex,
  geometry_present  = has_poly,
  tiger_1km_records = occ_suppress_small(full_col(cnt$tiger_1km$records),
                                         KDE_SMALL_N),
  tiger_1km_cells   = occ_suppress_small(full_col(cnt$tiger_1km$cells),
                                         KDE_SMALL_N),
  tiger_5km_records = occ_suppress_small(full_col(cnt$tiger_5km$records),
                                         KDE_SMALL_N),
  tiger_5km_cells   = occ_suppress_small(full_col(cnt$tiger_5km$cells),
                                         KDE_SMALL_N),
  background_5km_records = full_col(cnt$background_5km$records),
  background_5km_cells   = full_col(cnt$background_5km$cells),
  stringsAsFactors = FALSE
)
tiger_cols <- c("tiger_1km_records", "tiger_1km_cells", "tiger_5km_records",
                "tiger_5km_cells")
small_left <- vapply(tiger_cols, function(cl) {
  v <- suppressWarnings(as.numeric(occ_res[[cl]]))
  sum(!is.na(v) & v >= 1 & v < KDE_SMALL_N)
}, numeric(1))
n_supp <- vapply(tiger_cols, function(cl)
  sum(occ_res[[cl]] %in% paste0("<", KDE_SMALL_N)), numeric(1))
stopifnot(
  "a tiger column still holds a count from 1 to KDE_SMALL_N - 1" =
    all(small_left == 0),
  "a reserve with no polygon must have NA counts" =
    all(is.na(occ_res$tiger_5km_records[!has_poly])) &&
    all(is.na(occ_res$background_5km_records[!has_poly])),
  "a reserve with a polygon must have counts" =
    !anyNA(occ_res$tiger_5km_records[has_poly]) &&
    !anyNA(occ_res$background_5km_records[has_poly])
)
source(here("R", "00_functions_sensitive.R"))   # assert_publishable_table()
assert_publishable_table(occ_res, prefix = NULL,
                         name = "tbl_15_occ_by_reserve.csv")
# (the count columns have NA for a reserve with no polygon, so only unit_id
# goes to the number check of occ_assert_counts_only(); the names are checked
# for all columns)
occ_assert_counts_only(occ_res, cols = names(occ_res), count_cols = "unit_id",
                       name = "tbl_15_occ_by_reserve.csv")
write_table(occ_res, nn = 15, slug = "occ_by_reserve")

cat("\n--- suppressed tiger counts (written \"<", KDE_SMALL_N, "\") ---\n",
    sep = "")
print(data.frame(column = tiger_cols, suppressed = n_supp), row.names = FALSE)
# A total that is published elsewhere, minus the shown counts, gives the
# suppressed count when a column has only one of them.
one_supp <- tiger_cols[n_supp == 1]
if (length(one_supp) > 0) {
  cat("NOTE: one suppressed count in ", paste(one_supp, collapse = ", "),
      ". A published total of that column (inside all reserves) would give ",
      "its value. Do not publish that total.\n", sep = "")
}
cat("\n--- tbl_15_occ_by_reserve.csv: reserves with a tiger record (5 km set) ---\n")
shown <- occ_res[!is.na(occ_res$tiger_5km_records) &
                   occ_res$tiger_5km_records != "0",
                 c("unit_id", "unit_name", tiger_cols)]
print(shown, row.names = FALSE)

rule(paste0("STEP 13.6 complete: tbl_15_occ_by_reserve.csv written (",
            nrow(occ_res), " reserves). Tiger counts of 1 or 2 are \"<",
            KDE_SMALL_N, "\" (Decision 22 point 9)."))

}  # end if (RAW_STAGE == counts), STEP 13.6
