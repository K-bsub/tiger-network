# =============================================================================
# 10_check_sdm_connectivity.R  [STAGE 3+ — SDM-BASED RESISTANCE, Week 17]
# The SDM-based resistance and the circuit-theory check of Decision 27
# (2026-11-14): a resistance surface from the rank of the suitability of
# Decision 25 (a linear main surface, `main`, and a negative-exponential
# variant, `negexp8`) on the graph of the 0.2 degree model cells; circuit
# theory and least-cost paths between the reserves; a comparison with the
# Stage-2 least-cost paths (phase 1, the 106 pairs of Decision 17) and a
# check of the pair rule of Decision 17 (phase 2, all 1,540 pairs).
#
# Process choices of task 17.2 (2026-11-14):
#   s1  this script, one STEP block per task (as scripts/07 and 09)
#   f1  the functions are in R/00_functions_circuit.R. It reuses
#       sdm_reserve_cells() and the guard helpers of R/00_functions_sdm.R,
#       gistar_centres() and gistar_dist_km() of R/00_functions_gistar.R,
#       and (STEP 17.3) the overlap code of Decision 18 in
#       R/00_functions_lcp.R
#   n1  the names: the SDMRES_LAYER_*, SDMRES_TABLE_* and SDMRES_FIG_*
#       values of R/00_config.R
#   w1  one run switch, RUN_PHASE2 (below)
#   p1  no new package: Matrix and igraph (renv.lock); gdistance and raster
#       for check (ii) of Decision 27 point 5
#   h1  the hand-made case of each STEP runs first; a failure stops the
#       script
#
# Process choices of task 17.5 (2026-11-14; STEP 17.3): TB1 two tables, one
#   row per surface and Stage-2 path and one row per surface (the slug
#   compare_summary); CC1 the comparison in circ_compare_paths(), tested
#   against lcp_compare_variant(); FC1 the classes of fig_07 by
#   sdm_rank_class() over all model cells (the top class = the top cells of
#   point 7); PL1 inferno; L7a cyan on an ink casing; L8a purple solid and
#   grey dashed; FR1 the frame in R/00_functions_fig.R
#   (fig_frame_paths()); SZ1 the size and the key of fig_04 to fig_06. The
#   readings R3 (fig_08 draws the main paths of the compared pairs and all
#   Stage-2 paths) and R4 (a row for each Stage-2 path; the summary uses the
#   compared pairs)
#
# STEPS (each task adds its block):
#   STEP 17.1 (task 17.3)  the two surfaces of Decision 27 points 1-2, from
#              the rank of the prediction of STEP 15.1 (scripts/09); the graph
#              of the model cells and the cells of the reserves (point 3);
#              the status of the phase-1 pairs from geometry (contiguous at
#              0.2 degrees, no path) -> the layers resist_sdm_<surface>_
#              cell02.csv and tbl_19_sdmres_surface.csv; h1 a hand-made case
#              first (circ_self_test_171())
#   STEP 17.2 (task 17.4)  phase 1 on both surfaces: for each pair of
#              Decision 17 that is not contiguous at 0.2 degrees, the
#              effective resistance and the node currents (Z1) and the
#              least-cost path (points 4-6), after the checks of point 5:
#              (i) hand-made circuits and paths (circ_self_test_172()),
#              (ii) gdistance::commuteDistance() on a small grid
#              (circ_check_gdistance()), (iii) each path cost again from the
#              cells -> lcp_sdm_network_7755.gpkg (layers <surface>_phase1),
#              circ_current_<surface>_phase1_cell02.csv and
#              tbl_19_sdmres_pairs.csv
#   STEP 17.3 (task 17.5)  the comparison of point 7 (main against the
#              Stage-2 baseline paths, negexp8 against main; the
#              descriptive values) and the figures fig_07 and fig_08, after
#              the hand-made cases (circ_self_test_173(), fig_self_test(),
#              fig_self_test_paths()) -> tbl_19_sdmres_compare.csv,
#              tbl_19_sdmres_compare_summary.csv, fig_07_sdm_current.png,
#              fig_08_sdm_paths.png
#   STEP 17.4 (task 17.6)  the QA of phase 1
#   STEP 17.5 (task 17.6b) phase 2 (points 6 and 8) and its QA; only with
#              RUN_PHASE2 = TRUE
#
# SENSITIVE DATA (docs/sensitive-data-policy.md; Decision 27 point 10):
#   The surfaces, the currents and the paths stay under data/processed/
#   (gitignored). The suitability comes from a model on records that the
#   source obscured (tier T1). This script prints TRUE/FALSE, names, counts
#   and statistics only: no coordinate, no cell corner, no cell id. A tbl_19
#   table holds no position and no cell id. fig_07 and fig_08 are static
#   figures at national scale (Decision 27 point 10; Decision 20 point 7):
#   the 0.2 degree cells, the path lines, the reserve outlines, the state
#   lines and the hatch; no point and no presence or background mark.
#
# INPUTS (STEP 17.1; all under data/ are gitignored):
#   data/processed/sdm_grid_cell02_7755.gpkg   the 0.2 degree grid (scripts/09
#                                              STEP 14.1): id, ix, iy, model
#   data/processed/sdm_cellid_1km_7755.tif     the 0.2 degree cell of each
#                                              complete-case 1 km cell
#   data/processed/sdm_prediction_cell02.csv   the prediction (scripts/09
#                                              STEP 15.1): id, value, rank,
#                                              class, out_of_range
#   data/processed/boundary_reserves_all_7755.gpkg   the reserves
#   outputs/tables/tbl_12_reserve_pairs.csv          the pairs of Decision 17
#   outputs/tables/tbl_16_sdm_prediction.csv         a guard: the model cells
#                                                    and the cells outside
#                                                    the training range
#   outputs/tables/tbl_17_reserve_suitability.csv    a guard: the 1 km cells
#                                                    of each reserve
#
# INPUTS (STEP 17.2): the objects of STEP 17.1 in memory (the surfaces, the
#   graph, the cells of the reserves, the status of the pairs).
#
# INPUTS (STEP 17.3): the objects of STEPs 17.1 and 17.2 in memory (the
#   paths, the total currents, the status of the pairs), and:
#   data/processed/lcp_reserve_network_7755.gpkg   the Stage-2 paths
#     (scripts/07 STEP 10.2), layer baseline; only the fields FIELDS_S2 are
#     kept
#   data/processed/sdm_grid_cell02_7755.gpkg   the polygons of the model
#     cells (the top cells of point 7; fig_07)
#   data/processed/boundary_states_7755.gpkg   the state lines (the frame)
#   data/raw/gbif/gbif_tiger_download_doi.txt and
#     data/raw/gbif_background/background_download_doi.txt   the DOIs of
#     the captions (as scripts/09 STEP 16.2)
#
# OUTPUTS (STEP 17.2, task 17.4; n1 of task 17.2), all from phase 1:
#   data/processed/lcp_sdm_network_7755.gpkg   one layer per surface
#     (main_phase1, negexp8_phase1), one LINESTRING per pair of Decision 17
#     through the 0.2 degree cell centres in EPSG:7755 (empty for a pair
#     that is contiguous at 0.2 degrees): pair_id, surface, phase, the unit
#     ids and names, status, reff, cost_rkm, path_km, n_path_cells,
#     n_hatched_cells, redundancy. Read back and checked. Gitignored
#   data/processed/circ_current_main_phase1_cell02.csv and
#     circ_current_negexp8_phase1_cell02.csv   one row per model cell: id,
#     current (the total current of the phase-1 pairs, 1 A each; Z1). No
#     geometry. Read back and checked. Gitignored
#   outputs/tables/tbl_19_sdmres_pairs.csv   one row per pair and surface:
#     pair_id, surface, the unit ids and names, contiguous_decision17,
#     status, reff, cost_rkm, path_km, n_path_cells, n_hatched_cells,
#     redundancy. No position and no cell id
#
# OUTPUTS (STEP 17.3, task 17.5; TB1):
#   outputs/tables/tbl_19_sdmres_compare.csv   one row per surface and
#     Stage-2 path: pair_id, surface, reference, compared, the reserve
#     names, gap_km, the columns of Decision 18 (NA for a pair that is not
#     compared), top_current_share. No position and no cell id
#   outputs/tables/tbl_19_sdmres_compare_summary.csv   one row per surface:
#     the counts, the shares, rho, the label, and the descriptive rho,
#     partial rho, redundancy and top-current share
#   outputs/figures/fig_07_sdm_current.png and fig_08_sdm_paths.png
#     (11 x 10.6 inches at 200 dpi; the pixel size is checked)
#
# OUTPUTS (STEP 17.1, task 17.3; n1 of task 17.2):
#   data/processed/resist_sdm_main_cell02.csv and
#     data/processed/resist_sdm_negexp8_cell02.csv   one row per model cell:
#     id, x, resistance. No geometry, no presence or background field.
#     Written, then read back and checked. Gitignored
#   outputs/tables/tbl_19_sdmres_surface.csv   group, item, surface, value,
#     reading: the input, the statistics of each surface, the graph, the
#     cells of the reserves, the status of the phase-1 pairs. Counts and
#     statistics only: no cell id, no position, no reserve name
#
# SETTINGS: the SDMRES_* values (Decision 27; task 17.2) and the earlier
#   values that Decision 27 reuses come from R/00_config.R. Do not repeat a
#   value as a literal.
#
# MACHINE TRAP: the PROJ / PostGIS proj.db clash (handoff). Run in a FRESH
# session; the guard below stops if EPSG:7755 does not resolve.
# =============================================================================

# ---- Prerequisites ----------------------------------------------------------
suppressPackageStartupMessages({
  library(here)
  library(terra)
  library(sf)
})

source(here("R", "00_config.R"))             # CRS, DIR_*, SDM_*, SDMRES_*
source(here("R", "00_functions_io.R"))       # write_table
source(here("R", "00_functions_sensitive.R"))# assert_publishable_table
source(here("R", "00_functions_sdm.R"))      # sdm_reserve_cells, guards
source(here("R", "00_functions_gistar.R"))   # gistar_centres, gistar_dist_km
source(here("R", "00_functions_lcp.R"))      # lcp_write_layer (task 17.4)
source(here("R", "00_functions_circuit.R"))  # circ_* (task 17.3)
source(here("R", "00_functions_fig.R"))      # fig_* (task 17.5, STEP 17.3)

options(width = 120)
rule <- function(txt) cat("\n", strrep("=", 78), "\n", txt, "\n",
                          strrep("=", 78), "\n", sep = "")

# ---- Run switch (w1 of task 17.2, 2026-11-14) ----------------------------------
# TRUE  : STEP 17.5 runs phase 2 (all pairs of the reserves; Decision 27
#         points 6 and 8). Set TRUE only after the QA of phase 1 passes.
# FALSE : phase 2 does not run.
RUN_PHASE2 <- FALSE

# ---- Paths --------------------------------------------------------------------
grid_in     <- file.path(DIR_PROCESSED, "sdm_grid_cell02_7755.gpkg")
cellid_in   <- file.path(DIR_PROCESSED, "sdm_cellid_1km_7755.tif")
pred_in     <- file.path(DIR_PROCESSED, "sdm_prediction_cell02.csv")
reserves_in <- file.path(DIR_PROCESSED, "boundary_reserves_all_7755.gpkg")
pairs_in    <- file.path(DIR_TABLES, "tbl_12_reserve_pairs.csv")
predtbl_in  <- file.path(DIR_TABLES, "tbl_16_sdm_prediction.csv")
tbl17_in    <- file.path(DIR_TABLES, "tbl_17_reserve_suitability.csv")
# STEP 17.3 (task 17.5): the Stage-2 paths, the frame and the DOI files of
# the captions (as scripts/09 STEP 16.2)
s2_in        <- file.path(DIR_PROCESSED, "lcp_reserve_network_7755.gpkg")
states_in    <- file.path(DIR_PROCESSED, "boundary_states_7755.gpkg")
tiger_doi_in <- file.path(DIR_RAW, "gbif", "gbif_tiger_download_doi.txt")
bg_doi_in    <- file.path(DIR_RAW, "gbif_background",
                          "background_download_doi.txt")

# Fields that this script uses. The structure of the earlier layers and
# tables, not choices of the analysis.
FIELDS_GRID  <- c("id", "ix", "iy", "n_cc", "area_km2", "share", "model")
FIELDS_PAIRS <- c("pair_id", "from_unit_id", "to_unit_id", "contiguous")
FIELDS_T17   <- c("unit_id", "n_1km_cells_used", "n_1km_cells_no_value")
FIELDS_S2    <- c("pair_id", "from_unit_id", "to_unit_id", "contiguous",
                  "gap_km", "path_status", "cost_rkm", "path_km")

# ---- Guards (fail early; they print no result) ------------------------------
# 0) The run switch.
if (!is.logical(RUN_PHASE2) || length(RUN_PHASE2) != 1L || is.na(RUN_PHASE2)) {
  stop("RUN_PHASE2 must be TRUE or FALSE.", call. = FALSE)
}
if (RUN_PHASE2) {
  stop("STEP 17.5 (phase 2) is not in this script yet (task 17.6b). Keep ",
       "RUN_PHASE2 <- FALSE.", call. = FALSE)
}

# 1) The settings of Decision 27 and task 17.2.
n_cfg <- sdm_run_guards(circ_check_config(),
                        what = "the SDMRES_* block of R/00_config.R")

# 2) The analysis CRS must resolve in this session (PROJ proj.db clash).
crs_wkt <- terra::crs(terra::rast(crs = paste0("EPSG:", CRS_ANALYSIS)))
if (!nzchar(crs_wkt) || !grepl("India", crs_wkt)) {
  stop("EPSG:", CRS_ANALYSIS, " did not resolve to the India NSF LCC frame. ",
       "Restart R so .Rprofile pins PROJ_LIB before terra loads, then re-run.",
       call. = FALSE)
}

# 3) Every input must exist.
inputs <- c(grid_in, cellid_in, pred_in, reserves_in, pairs_in, predtbl_in,
            tbl17_in)
missing_inputs <- inputs[!file.exists(inputs)]
if (length(missing_inputs) > 0) {
  stop("Missing required input(s):\n  ",
       paste(missing_inputs, collapse = "\n  "),
       "\nThe grid, the cell-id raster and the prediction come from ",
       "scripts/09 (STEPs 14.1 and 15.1).", call. = FALSE)
}

# 4) The grid and the prediction (scripts/09 STEPs 14.1 and 15.1).
f_grid <- sdm_read_fields(grid_in)
grid_d <- sf::st_drop_geometry(sf::st_read(grid_in, quiet = TRUE))
pred_d <- utils::read.csv(pred_in)
predtbl <- utils::read.csv(predtbl_in, stringsAsFactors = FALSE)
tval <- function(group, item) {
  v <- predtbl$value[predtbl$group == group & predtbl$item == item]
  if (length(v) != 1L) {
    stop("tbl_16_sdm_prediction.csv has no single row ", group, " / ", item,
         ".", call. = FALSE)
  }
  v
}
model_ids <- sort(as.integer(grid_d$id[grid_d$model]))
n_inp <- sdm_run_guards(list(
  "the grid must have the fields of scripts/09 STEP 14.1, in the analysis CRS" =
    all(FIELDS_GRID %in% f_grid$fields) &&
    identical(f_grid$epsg, as.integer(CRS_ANALYSIS)),
  "each grid id must be once, and model must be TRUE or FALSE" =
    !anyDuplicated(grid_d$id) && is.logical(grid_d$model) &&
    !anyNA(grid_d$model)
), what = "the grid (scripts/09 STEP 14.1)")
n_inp <- n_inp + sdm_run_guards(sdm_pred_layer_checks(pred_d, model_ids),
                                what = "the prediction layer (scripts/09 STEP 15.1)")
n_inp <- n_inp + sdm_run_guards(list(
  "the model cells must be the count of tbl_16_sdm_prediction.csv" =
    isTRUE(length(model_ids) == tval("cells", "model_cells")),
  "the cells outside the training range must be the count of tbl_16_sdm_prediction.csv" =
    isTRUE(sum(pred_d$out_of_range) == tval("range", "cells_outside"))
), what = "the prediction against tbl_16_sdm_prediction.csv")

# 5) The reserves and the 1 km cell-id raster.
res_sf <- sf::st_read(reserves_in, quiet = TRUE)
res_d  <- sf::st_drop_geometry(res_sf)
has_geom <- !sf::st_is_empty(res_sf)
cellid_r <- terra::rast(cellid_in)
t17 <- utils::read.csv(tbl17_in, stringsAsFactors = FALSE)
n_inp <- n_inp + sdm_run_guards(list(
  "the reserve layer must have unit_id, unit_name and geometry_present" =
    all(c("unit_id", "unit_name", "geometry_present") %in% names(res_d)),
  "the reserve layer must be in the analysis CRS" =
    identical(as.integer(sf::st_crs(res_sf)$epsg), as.integer(CRS_ANALYSIS)),
  "each unit_id must be a whole number, once" =
    !anyNA(res_d$unit_id) && all(res_d$unit_id == round(res_d$unit_id)) &&
    !anyDuplicated(res_d$unit_id),
  "geometry_present must agree with the geometry" =
    identical(as.logical(res_d$geometry_present), has_geom),
  "the reserves with a polygon must be NET_EXPECTED_RESERVES" =
    sum(has_geom) == NET_EXPECTED_RESERVES,
  "the cell-id raster must be in the analysis CRS" =
    identical(as.character(terra::crs(cellid_r, describe = TRUE)$code),
              as.character(CRS_ANALYSIS)),
  "tbl_17_reserve_suitability.csv must hold each reserve once, with the cell counts" =
    all(FIELDS_T17 %in% names(t17)) && !anyDuplicated(t17$unit_id) &&
    setequal(as.integer(t17$unit_id), as.integer(res_d$unit_id))
), what = "the reserves")

# 6) The pairs of Decision 17 (tbl_12_reserve_pairs.csv).
pairs_d <- utils::read.csv(pairs_in, stringsAsFactors = FALSE)
geom_ids <- as.integer(res_d$unit_id[has_geom])
n_inp <- n_inp + sdm_run_guards(list(
  "tbl_12_reserve_pairs.csv must have pair_id, from_unit_id, to_unit_id and contiguous" =
    all(FIELDS_PAIRS %in% names(pairs_d)),
  "each pair_id must be once, and each pair of reserves once" =
    !anyDuplicated(pairs_d$pair_id) &&
    !anyDuplicated(paste(pmin(pairs_d$from_unit_id, pairs_d$to_unit_id),
                         pmax(pairs_d$from_unit_id, pairs_d$to_unit_id))),
  "the two reserves of a pair must differ, and each must have a polygon" =
    all(pairs_d$from_unit_id != pairs_d$to_unit_id) &&
    all(c(pairs_d$from_unit_id, pairs_d$to_unit_id) %in% geom_ids),
  "contiguous must be TRUE or FALSE" =
    is.logical(pairs_d$contiguous) && !anyNA(pairs_d$contiguous)
), what = "the pairs of Decision 17")

rule(paste0("10_check_sdm_connectivity.R — guards passed (", n_cfg + n_inp,
            " checks); CRS OK | RUN_PHASE2 = ", RUN_PHASE2))
cat("model cells:", format(length(model_ids), big.mark = ","),
    "| reserves with a polygon:", sum(has_geom),
    "| pairs of Decision 17:", nrow(pairs_d), "\n")

# =============================================================================
# STEP 17.1 — the surfaces, the graph and the cells of the reserves (task
#             17.3; Decision 27 points 1 to 3)
# =============================================================================
# h1 a hand-made case first.
#   1. the hand-made case (circ_self_test_171())
#   2. the two surfaces from the rank (a2, b3; the hatched cells kept, k1);
#      written, read back and checked
#   3. the graph of the model cells: 8 neighbours, the link length on the
#      sphere (c1); the connected sets
#   4. the model cells of each reserve (the centre rule of Decision 25 h1);
#      a guard against the 1 km counts of tbl_17_reserve_suitability.csv
#   5. the status of the phase-1 pairs from geometry: contiguous at 0.2
#      degrees, no path, or path (point 3)
#   6. tbl_19_sdmres_surface.csv
# Console text: counts and statistics only.

rule("STEP 17.1 — the surfaces, the graph and the cells of the reserves (task 17.3)")
t_step171 <- Sys.time()

# ---- 1. The hand-made case (h1) ---------------------------------------------------
st171 <- circ_self_test_171()
cat("hand-made case of STEP 17.1:", sum(st171$pass), "of", nrow(st171),
    "checks pass.\n")
if (!all(st171$pass)) {
  stop("The hand-made case of STEP 17.1 failed:\n  ",
       paste(st171$check[!st171$pass], collapse = "\n  "), call. = FALSE)
}

# ---- 2. The two surfaces (Decision 27 points 1 and 2) ------------------------------
pred_d <- pred_d[order(pred_d$id), ]
surf <- lapply(names(SDMRES_SURFACES), function(nm) circ_surface(pred_d, nm))
names(surf) <- names(SDMRES_SURFACES)
for (nm in names(surf)) {
  sdm_run_guards(circ_surface_checks(surf[[nm]], model_ids),
                 what = paste0("the surface ", nm, " (in memory)"))
  f_out <- file.path(DIR_PROCESSED, sprintf(SDMRES_LAYER_SURFACE, nm))
  utils::write.csv(surf[[nm]], f_out, row.names = FALSE)
  back <- utils::read.csv(f_out)
  sdm_run_guards(c(
    circ_surface_checks(back, model_ids),
    list("the file must hold the values in memory" =
           identical(as.integer(back$id), surf[[nm]]$id) &&
           isTRUE(all.equal(back$x, surf[[nm]]$x, tolerance = 1e-12)) &&
           isTRUE(all.equal(back$resistance, surf[[nm]]$resistance,
                            tolerance = 1e-12)))
  ), what = paste0("the file ", basename(f_out), " (read back)"))
  cat("wrote", basename(f_out), "-", format(nrow(back), big.mark = ","),
      "rows; read back and checked\n")
}
# The flag of Decision 25 b2, in the id order of the surfaces (k1: counted,
# not removed).
oor <- pred_d$out_of_range
if (!identical(as.integer(pred_d$id), surf[[1]]$id)) {
  stop("The prediction and the surfaces are not in one id order.",
       call. = FALSE)
}

# ---- 3. The graph of the model cells (Decision 27 point 3, c1) ----------------------
grid_m <- grid_d[grid_d$model, c("id", "ix", "iy")]
grid_m <- grid_m[order(grid_m$id), ]
if (!identical(as.integer(grid_m$id), model_ids) ||
    !identical(sdm_cell_id(grid_m$ix, grid_m$iy), model_ids)) {
  stop("The grid ids do not agree with ix and iy (sdm_cell_id()).",
       call. = FALSE)
}
links <- circ_links(as.integer(grid_m$ix), as.integer(grid_m$iy))
memb  <- circ_components(nrow(grid_m), links)
cat("graph:", format(length(model_ids), big.mark = ","), "nodes |",
    format(nrow(links), big.mark = ","), "links |",
    length(unique(memb)), "connected sets\n")

# ---- 4. The model cells of each reserve (the centre rule) --------------------------
rc  <- sdm_reserve_cells(res_sf, cellid_r)
rcl <- circ_reserve_cells(rc, model_ids, nrow(res_sf))
t17m <- t17[match(as.integer(res_d$unit_id), as.integer(t17$unit_id)), ]
sdm_run_guards(list(
  "each reserve with a polygon must have one or more model cells (STEP 15.2)" =
    all(lengths(rcl$cells)[has_geom] > 0L),
  "a reserve with no polygon must have no cell" =
    all(lengths(rcl$cells)[!has_geom] == 0L),
  "the 1 km cells in model cells must be n_1km_cells_used of tbl_17, by reserve" =
    identical(as.integer(rcl$n_1km_model[has_geom]),
              as.integer(t17m$n_1km_cells_used[has_geom])),
  "the 1 km cells in other cells must be n_1km_cells_no_value of tbl_17, by reserve" =
    identical(as.integer(rcl$n_1km_nonmodel[has_geom]),
              as.integer(t17m$n_1km_cells_no_value[has_geom]))
), what = "the cells of the reserves (against tbl_17_reserve_suitability.csv)")
cat("cells of the reserves: the 1 km counts agree with",
    "tbl_17_reserve_suitability.csv for each of the", sum(has_geom),
    "reserves\n")

# ---- 5. The status of the phase-1 pairs (geometry only) ----------------------------
ia <- match(pairs_d$from_unit_id, res_d$unit_id)
ib <- match(pairs_d$to_unit_id, res_d$unit_id)
status <- circ_pair_status(rcl$cells[ia], rcl$cells[ib], model_ids, memb)
if (any(status == "no_cells")) {
  stop("A pair has a reserve with no model cell.", call. = FALSE)
}

# ---- 6. tbl_19_sdmres_surface.csv ---------------------------------------------------
tbl171 <- circ_surface_summary(surf, oor, links, memb, model_ids, rcl,
                               has_geom, status, pairs_d$contiguous)
assert_publishable_table(tbl171, prefix = NULL,
                         name = "tbl_19_sdmres_surface.csv")
write_table(tbl171, SDMRES_TABLE_NN, SDMRES_TABLE_SLUGS[["surface"]])

show171 <- tbl171
show171$value <- vapply(tbl171$value, function(v) {
  if (abs(v - round(v)) < 1e-9 && abs(v) < 1e9) {
    format(round(v), big.mark = ",", scientific = FALSE)
  } else {
    format(signif(v, 6), scientific = FALSE)
  }
}, character(1))
print(show171, row.names = FALSE, right = FALSE)

cat(sprintf("\nSTEP 17.1 time: %.1f min\n",
            as.numeric(difftime(Sys.time(), t_step171, units = "mins"))))
rule("STEP 17.1 done.")

# =============================================================================
# STEP 17.2 — phase 1: the circuit and the least-cost paths (task 17.4;
#             Decision 27 points 4 to 6), after the checks of point 5
# =============================================================================
# h1 the checks of point 5 first.
#   1. check (i) and the paths of (iii) on hand-made graphs
#      (circ_self_test_172()); check (ii): gdistance on a small grid
#      (circ_check_gdistance())
#   2. for each surface and each phase-1 pair with the status "path": the
#      effective resistance and the node currents on the connected set of
#      the pair (Z1); the least-cost path, edge to edge; for each path,
#      check (iii) (the cost again from the cells), the current out of the
#      first reserve (1 A), and the path cost not below the effective
#      resistance. A pair contiguous at 0.2 degrees gets 0 and no path; a
#      pair with no path gets Inf (none in STEP 17.1)
#   3. the paths (one layer per surface) and the total currents, written and
#      read back
#   4. tbl_19_sdmres_pairs.csv
# Console text: counts and statistics only.

rule("STEP 17.2 — phase 1: the circuit and the least-cost paths (task 17.4)")
t_step172 <- Sys.time()

# ---- 1. The checks of Decision 27 point 5 -------------------------------------------
if (!requireNamespace("Matrix", quietly = TRUE)) {
  stop("STEP 17.2 needs the package Matrix (p1 of task 17.2; scripts/00a).",
       call. = FALSE)
}
st172 <- circ_self_test_172()
cat("checks (i) and (iii), hand-made case of STEP 17.2:", sum(st172$pass),
    "of", nrow(st172), "pass.\n")
if (!all(st172$pass)) {
  stop("The hand-made case of STEP 17.2 failed:\n  ",
       paste(st172$check[!st172$pass], collapse = "\n  "), call. = FALSE)
}
gd172 <- circ_check_gdistance()
cat("check (ii), gdistance::commuteDistance() on a small grid:",
    sum(gd172$pass), "of", nrow(gd172), "pass; largest relative difference",
    format(signif(max(gd172$rel_diff), 3)), "\n")
if (!all(gd172$pass)) {
  stop("Check (ii) failed (gdistance):\n  ",
       paste(gd172$check[!gd172$pass], collapse = "\n  "), call. = FALSE)
}

# ---- 2. The circuit and the paths of phase 1 ------------------------------------------
PHASE1  <- "phase1"
n_nodes <- length(model_ids)
node_a  <- lapply(ia, function(i) match(rcl$cells[[i]], model_ids))
node_b  <- lapply(ib, function(i) match(rcl$cells[[i]], model_ids))
paths172 <- list()
cur172   <- list()
hat172   <- list()   # the hatched cells on the paths (k1: counted)
for (nm in names(surf)) {
  r  <- surf[[nm]]$resistance
  lr <- circ_link_resistance(links, r)
  cur <- numeric(n_nodes)
  hat <- integer(0)
  geoms <- vector("list", nrow(pairs_d))
  out <- data.frame(
    pair_id = pairs_d$pair_id, surface = nm, phase = PHASE1,
    from_unit_id = as.integer(pairs_d$from_unit_id),
    from_name = pairs_d$from_name,
    to_unit_id = as.integer(pairs_d$to_unit_id), to_name = pairs_d$to_name,
    contiguous_decision17 = pairs_d$contiguous, status = status,
    reff = NA_real_, cost_rkm = NA_real_, path_km = NA_real_,
    n_path_cells = NA_integer_, n_hatched_cells = NA_integer_,
    redundancy = NA_real_, stringsAsFactors = FALSE)
  for (k in seq_len(nrow(pairs_d))) {
    if (status[k] %in% c("contiguous_02", "no_path")) {
      z <- if (status[k] == "contiguous_02") 0 else Inf
      out$reff[k] <- z
      out$cost_rkm[k] <- z
      out$path_km[k] <- if (z == 0) 0 else NA_real_
      out$n_path_cells[k] <- 0L
      out$n_hatched_cells[k] <- 0L
      geoms[[k]] <- sf::st_linestring()
      next
    }
    a <- node_a[[k]]
    b <- node_b[[k]]
    keep <- which(memb == memb[a[1]])
    sol <- circ_solve_pair(n_nodes, links$from, links$to, 1 / lr, a, b, keep)
    p   <- circ_lcp_pair(n_nodes, links$from, links$to, lr, a, b)
    pc  <- circ_path_cost(grid_m$ix[p$nodes], grid_m$iy[p$nodes], r[p$nodes])
    ok <- c(
      "the current out of the first reserve is 1 A" =
        abs(sol$out_a - 1) <= SDMRES_CHECK_TOL_REL,
      "the effective resistance is finite and above 0" =
        is.finite(sol$reff) && sol$reff > 0,
      "the path has 2 cells or more" =
        is.finite(p$cost) && length(p$nodes) >= 2L,
      "the path starts in the first reserve and ends in the second" =
        p$nodes[1] %in% a && p$nodes[length(p$nodes)] %in% b,
      "(iii) the path cost again from the cells" =
        isTRUE(pc$steps_ok) &&
        abs(pc$cost - p$cost) <= SDMRES_CHECK_TOL_REL * max(1, p$cost),
      "the path cost is not below the effective resistance" =
        p$cost >= sol$reff * (1 - SDMRES_CHECK_TOL_REL))
    if (!all(ok)) {
      stop("STEP 17.2, pair_id ", pairs_d$pair_id[k], " on ", nm, ": ",
           paste(names(ok)[!ok], collapse = "; "), call. = FALSE)
    }
    cur <- cur + sol$current
    hat <- union(hat, p$nodes[oor[p$nodes]])
    ln <- circ_path_line(grid_m$ix[p$nodes], grid_m$iy[p$nodes])
    geoms[[k]] <- ln
    out$reff[k] <- sol$reff
    out$cost_rkm[k] <- p$cost
    out$path_km[k] <- as.numeric(sf::st_length(
      sf::st_sfc(ln, crs = CRS_ANALYSIS))) / 1000
    out$n_path_cells[k] <- length(p$nodes)
    out$n_hatched_cells[k] <- sum(oor[p$nodes])
    out$redundancy[k] <- p$cost / sol$reff
  }
  paths172[[nm]] <- sf::st_sf(out, geometry = sf::st_sfc(geoms,
                                                         crs = CRS_ANALYSIS))
  cur172[[nm]] <- cur
  hat172[[nm]] <- hat
  solved <- out$status == "path"
  cat(sprintf(paste0("%s: %d pairs solved; each passed the checks (current ",
                     "out = 1 A; (iii) the cost again; cost not below the ",
                     "effective resistance)\n"), nm, sum(solved)))
}

# ---- 3. The paths and the total currents, written and read back ----------------------
paths_out <- file.path(DIR_PROCESSED, SDMRES_LAYER_PATHS)
for (nm in names(paths172)) {
  lcp_write_layer(paths172[[nm]], paths_out, paste0(nm, "_", PHASE1))
  f_cur <- file.path(DIR_PROCESSED, sprintf(SDMRES_LAYER_CURRENT, nm, PHASE1))
  cur_d <- data.frame(id = model_ids, current = cur172[[nm]])
  utils::write.csv(cur_d, f_cur, row.names = FALSE)
  back <- utils::read.csv(f_cur)
  sdm_run_guards(list(
    "the current layer must have the fields id and current" =
      identical(names(back), c("id", "current")),
    "the current layer must hold each model cell once, in id order" =
      identical(as.integer(back$id), model_ids),
    "each current must be 0 or more" =
      !anyNA(back$current) && all(back$current >= 0),
    "the file must hold the values in memory" =
      isTRUE(all.equal(back$current, cur_d$current, tolerance = 1e-12))
  ), what = paste0("the file ", basename(f_cur), " (read back)"))
  cat("wrote", basename(f_cur), "-", format(nrow(back), big.mark = ","),
      "rows; read back and checked\n")
}

# ---- 4. tbl_19_sdmres_pairs.csv -----------------------------------------------------
tbl172 <- do.call(rbind, lapply(paths172, sf::st_drop_geometry))
tbl172 <- tbl172[, setdiff(names(tbl172), "phase")]
rownames(tbl172) <- NULL
assert_publishable_table(tbl172, prefix = NULL,
                         name = "tbl_19_sdmres_pairs.csv")
write_table(tbl172, SDMRES_TABLE_NN, SDMRES_TABLE_SLUGS[["pairs"]])

# ---- The console: counts and statistics -----------------------------------------------
q3 <- function(v) {
  q <- stats::quantile(v, c(0, 0.5, 1), names = FALSE)
  paste0(format(signif(q[2], 4), big.mark = ","), " (",
         format(signif(q[1], 4), big.mark = ","), " to ",
         format(signif(q[3], 4), big.mark = ","), ")")
}
sum172 <- do.call(rbind, lapply(names(paths172), function(nm) {
  d <- sf::st_drop_geometry(paths172[[nm]])
  s <- d$status == "path"
  data.frame(
    surface = nm,
    pairs_solved = sum(s),
    contiguous_02 = sum(d$status == "contiguous_02"),
    reff_median_min_max = q3(d$reff[s]),
    cost_median_min_max = q3(d$cost_rkm[s]),
    redundancy_median_min_max = q3(d$redundancy[s]),
    path_km_median_min_max = q3(d$path_km[s]),
    paths_with_hatched = sum(d$n_hatched_cells[s] > 0),
    hatched_cells_on_paths = length(hat172[[nm]]),
    cells_with_current = sum(cur172[[nm]] > 0),
    current_max = signif(max(cur172[[nm]]), 4),
    stringsAsFactors = FALSE)
}))
print(t(sum172), quote = FALSE)

cat(sprintf("\nSTEP 17.2 time: %.1f min\n",
            as.numeric(difftime(Sys.time(), t_step172, units = "mins"))))
rule("STEP 17.2 done. Next: STEP 17.3 (task 17.5): the comparison of point 7 and the figures.")

# =============================================================================
# STEP 17.3 — the comparison of point 7 and the figures fig_07 and fig_08
#             (task 17.5; Decision 27 points 7, 9 and 10)
# =============================================================================
# Process choices of task 17.5 (2026-11-14): TB1, CC1, FC1, PL1, L7a, L8a,
# FR1 and SZ1; the readings R3 and R4. h1 the hand-made cases first.
#   1. the settings of task 17.5; the hand-made cases (circ_self_test_173(),
#      fig_self_test(), fig_self_test_paths())
#   2. the Stage-2 baseline paths (lcp_reserve_network_7755.gpkg, layer
#      baseline): the fields of the comparison only, with guards against
#      tbl_12_reserve_pairs.csv
#   3. the top cells of the phase-1 total current of each surface (FC1: the
#      top class of sdm_rank_class(), a tie to the lower cell id), as the
#      polygons of the grid layer in EPSG:7755
#   4. the comparison of point 7 (CC1, R4): one row for each surface and
#      Stage-2 path; main against the Stage-2 baseline, negexp8 against
#      main; the share of each Stage-2 path in the top cells of the surface
#   5. tbl_19_sdmres_compare.csv and tbl_19_sdmres_compare_summary.csv (TB1)
#   6. fig_07 (PL1, L7a, FC1) and fig_08 (L8a, R3) in the frame of FR1 with
#      the settings of SZ1; the read guard of k1 (task 16.2); the draft
#      captions; the checks before a file is written
# Console text: counts, statistics, the labels and the draft captions. No
# pair row is printed.

rule("STEP 17.3 — the comparison of point 7 and the figures fig_07 and fig_08 (task 17.5)")
t_step173 <- Sys.time()

# ---- 1. The settings and the hand-made cases (h1) ------------------------------------
for (pk in c("ggplot2", "viridisLite")) {
  if (!requireNamespace(pk, quietly = TRUE)) {
    stop("STEP 17.3 needs the package ", pk, " (in renv.lock). Run ",
         "renv::restore().", call. = FALSE)
  }
}
suppressPackageStartupMessages(library(ggplot2))
n173 <- sdm_run_guards(circ_check_config_173(),
                       what = "the settings of task 17.5 (R/00_config.R)")
cat("settings of task 17.5:", n173, "checks pass.\n")
tests173 <- list(
  "the comparison of point 7 (circ_self_test_173())" = circ_self_test_173,
  "the figure helpers of STEP 16.2 (fig_self_test())" = fig_self_test,
  "the frame of fig_07 and fig_08 (fig_self_test_paths())" = fig_self_test_paths)
for (nm in names(tests173)) {
  r <- tests173[[nm]]()
  cat("hand-made case,", nm, ":", sum(r$pass), "of", nrow(r), "checks pass.\n")
  if (!all(r$pass)) {
    stop("The hand-made case failed (", nm, "):\n  ",
         paste(r$check[!r$pass], collapse = "\n  "), call. = FALSE)
  }
}
miss173 <- c(s2_in, states_in, tiger_doi_in, bg_doi_in)
miss173 <- miss173[!file.exists(miss173)]
if (length(miss173) > 0) {
  stop("STEP 17.3 needs:\n  ", paste(miss173, collapse = "\n  "),
       call. = FALSE)
}
K173 <- SDMRES_FIG_N_CLASSES
n_model <- length(model_ids)

# ---- 2. The Stage-2 baseline paths (Decisions 14 to 17) -------------------------------
# The layer holds the 1 km cells of the exit and the entry of each path; only
# the fields of FIELDS_S2 are kept, and nothing of the layer is printed.
s2_all <- sf::st_read(s2_in, layer = SDMRES_COMPARE_SURFACE, quiet = TRUE)
s2_m <- match(pairs_d$pair_id, s2_all$pair_id)
s2_is_path <- s2_all$path_status == "path"
sdm_run_guards(list(
  "the Stage-2 layer must have the fields of the comparison, in the analysis CRS" =
    all(FIELDS_S2 %in% names(s2_all)) &&
    identical(as.integer(sf::st_crs(s2_all)$epsg), as.integer(CRS_ANALYSIS)),
  "the Stage-2 layer must hold each pair of tbl_12_reserve_pairs.csv once" =
    nrow(s2_all) == nrow(pairs_d) && !anyNA(s2_m) &&
    !anyDuplicated(s2_all$pair_id),
  "the unit ids and contiguous must agree with tbl_12_reserve_pairs.csv" =
    identical(as.integer(s2_all$from_unit_id[s2_m]),
              as.integer(pairs_d$from_unit_id)) &&
    identical(as.integer(s2_all$to_unit_id[s2_m]),
              as.integer(pairs_d$to_unit_id)) &&
    identical(as.logical(s2_all$contiguous[s2_m]),
              as.logical(pairs_d$contiguous)),
  "gap_km must agree with tbl_12_reserve_pairs.csv" =
    isTRUE(all.equal(as.numeric(s2_all$gap_km[s2_m]),
                     as.numeric(pairs_d$gap_km), tolerance = 1e-9)),
  "path_status must be contiguous for a contiguous pair, and path or no_path for the others" =
    all(ifelse(s2_all$contiguous, s2_all$path_status == "contiguous",
               s2_all$path_status %in% c("path", "no_path"))),
  "each Stage-2 path must have a line, a cost above 0 and a length above 0" =
    !any(sf::st_is_empty(s2_all)[s2_is_path]) &&
    all(is.finite(s2_all$cost_rkm[s2_is_path]) &
          s2_all$cost_rkm[s2_is_path] > 0 & s2_all$path_km[s2_is_path] > 0)
), what = "the Stage-2 baseline paths (lcp_reserve_network_7755.gpkg)")
s2 <- s2_all[s2_m, FIELDS_S2]
rm(s2_all, s2_m, s2_is_path)

# ---- 3. The top cells of the current (FC1) ---------------------------------------------
rd173 <- fig_reader(list(cells = grid_in, frame = states_in,
                         caption = c(tiger_doi_in, bg_doi_in)))
grid_sf <- rd173$read(grid_in, "cells")
grid_sf <- grid_sf[as.logical(grid_sf$model), "id"]
grid_sf <- grid_sf[order(grid_sf$id), ]
if (!identical(as.integer(grid_sf$id), model_ids)) {
  stop("The grid polygons and the model cells are not the same cells.",
       call. = FALSE)
}
cells_g <- sf::st_geometry(grid_sf)
top173 <- lapply(names(surf), function(nm) {
  sdm_rank_class(cur172[[nm]], model_ids, K173)
})
names(top173) <- names(surf)
n_top <- ceiling(SDMRES_TOP_CURRENT_SHARE * n_model)
sdm_run_guards(stats::setNames(lapply(names(surf), function(nm) {
  is_top <- top173[[nm]]$class == K173
  sum(is_top) == n_top &&
    setequal(model_ids[is_top],
             model_ids[order(-cur172[[nm]], model_ids)[seq_len(n_top)]])
}), paste0("the top class of ", names(surf), " must be the top ",
           SDMRES_TOP_CURRENT_SHARE * 100, " % of the cells by current ",
           "(a tie to the lower id; FC1)")),
  what = "the top cells of the current")

# ---- 4. The comparison of point 7 (CC1, R4) --------------------------------------------
# One row for each Stage-2 path. A pair is compared if it has a path at 0.2
# degrees too (not contiguous at 0.2 degrees; not "no path").
s2_rows <- which(s2$path_status == "path")
base_s2 <- s2[s2_rows, ]
info173 <- data.frame(pair_id = pairs_d$pair_id, from_name = pairs_d$from_name,
                      to_name = pairs_d$to_name, gap_km = pairs_d$gap_km,
                      stringsAsFactors = FALSE)[s2_rows, ]
st_s2  <- status[s2_rows]
cmp_ok <- st_s2 == "path"
sdm_s2 <- lapply(paths172, function(x) x[s2_rows, ])
sdm_run_guards(list(
  "the paths of STEP 17.2 must be in the order of the Stage-2 rows" =
    all(vapply(sdm_s2, function(x) {
      identical(as.integer(x$pair_id), as.integer(info173$pair_id))
    }, logical(1))),
  "a compared pair must have a path on each surface" =
    all(vapply(sdm_s2, function(x) all(x$status[cmp_ok] == "path"),
               logical(1))),
  "each Stage-2 path must be compared, contiguous at 0.2 degrees or no path" =
    all(st_s2 %in% c("path", "contiguous_02", "no_path"))
), what = "the pairs of point 7")
cmp173 <- list(
  main = circ_compare_paths(base_s2, sdm_s2$main, info173, cmp_ok,
                            "main", "stage2_baseline"),
  negexp8 = circ_compare_paths(sdm_s2$main, sdm_s2$negexp8, info173, cmp_ok,
                               "negexp8", "main"))
top_share <- lapply(names(surf), function(nm) {
  circ_line_share_in(sf::st_geometry(base_s2),
                     cells_g[top173[[nm]]$class == K173])
})
names(top_share) <- names(surf)
for (nm in names(cmp173)) cmp173[[nm]]$top_current_share <- top_share[[nm]]
sum173 <- rbind(
  circ_compare_summary(cmp173$main, st_s2, sdm_s2$main$reff,
                       sdm_s2$main$redundancy, base_s2$cost_rkm,
                       top_share$main, n_top, SDMRES_COMPARE_LABELS$stage2),
  circ_compare_summary(cmp173$negexp8, st_s2, sdm_s2$negexp8$reff,
                       sdm_s2$negexp8$redundancy, base_s2$cost_rkm,
                       top_share$negexp8, n_top,
                       SDMRES_COMPARE_LABELS$variant))
sdm_run_guards(list(
  "Stage-2 paths = compared + contiguous at 0.2 degrees + no path, on each surface" =
    all(sum173$stage2_paths == sum173$pairs_compared +
          sum173$contiguous_02_excluded + sum173$no_path_excluded),
  "each label must be one of its two words" =
    sum173$label[1] %in% SDMRES_COMPARE_LABELS$stage2 &&
    sum173$label[2] %in% SDMRES_COMPARE_LABELS$variant,
  "each share of a Stage-2 path in the top cells must be 0 to 1" =
    all(vapply(top_share, function(v) all(v >= 0 & v <= 1), logical(1)))
), what = "the comparison of point 7")

# ---- 5. The tables (TB1) ------------------------------------------------------------------
tbl173 <- do.call(rbind, cmp173)
rownames(tbl173) <- NULL
assert_publishable_table(tbl173, prefix = NULL,
                         name = "tbl_19_sdmres_compare.csv")
write_table(tbl173, SDMRES_TABLE_NN, SDMRES_TABLE_SLUGS[["compare"]])
assert_publishable_table(sum173, prefix = NULL,
                         name = "tbl_19_sdmres_compare_summary.csv")
write_table(sum173, SDMRES_TABLE_NN, SDMRES_TABLE_SLUGS[["compare_summary"]])
show173 <- sum173
for (cn in names(show173)) {
  if (is.numeric(show173[[cn]])) {
    show173[[cn]] <- format(signif(show173[[cn]], 4), big.mark = ",",
                            scientific = FALSE)
  }
}
print(t(show173), quote = FALSE)

# ---- 6. The figures (Decision 27 points 9 and 10) ---------------------------------------
fig_ink   <- FIG_FRAME_COLOURS[["ink"]]
fig_paper <- FIG_FRAME_COLOURS[["paper"]]
states173 <- rd173$read(states_in, "frame")
fig_st  <- sf::st_sf(geometry = sf::st_geometry(states173)[
  !sf::st_is_empty(states173)])
fig_res <- sf::st_sf(geometry = sf::st_geometry(res_sf)[has_geom])
fig_bb  <- sf::st_bbox(fig_st)
fig_side <- sqrt(stats::median(as.numeric(sf::st_area(cells_g))))
fig_step <- 2 * fig_side / FIG_HATCH_LINES_PER_CELL
fig_hatch <- sf::st_sf(geometry = fig_hatch_lines(cells_g[oor], fig_step))
fig_key_x <- fig_bb[["xmin"]] + FIG_HATCH_KEY_POS[["x"]] *
  (fig_bb[["xmax"]] - fig_bb[["xmin"]])
fig_key_y <- fig_bb[["ymin"]] + FIG_HATCH_KEY_POS[["y"]] *
  (fig_bb[["ymax"]] - fig_bb[["ymin"]])
fig_kb <- fig_key_box(fig_key_x, fig_key_y, 3 * fig_side, fig_step,
                      sf::st_crs(fig_st))
fig_noor <- sum(oor)
fig_key_label <- paste0("Outside the training range of\none or more ",
                        "covariates (", fig_noor, " cells)")
# fig_07: the classes of the main current (FC1) and the Stage-2 paths (L7a).
cls07 <- top173$main$class
fig_c07 <- sf::st_sf(class = factor(as.character(cls07),
                                    levels = as.character(K173:1)),
                     geometry = cells_g)
pal07 <- stats::setNames(viridisLite::viridis(
  K173, option = SDMRES_FIG07_PALETTE$option,
  begin = SDMRES_FIG07_PALETTE$begin, end = SDMRES_FIG07_PALETTE$end),
  as.character(1:K173))
lab_s2  <- "Stage-2 least-cost path\n(baseline surface, 1 km)"
lab_sdm <- "Least-cost path on the\nsuitability-based surface (main)"
s2_lines07 <- sf::st_sf(kind = factor(rep("stage2", nrow(base_s2))),
                        geometry = sf::st_geometry(base_s2))
lay07 <- list(
  ggplot2::geom_sf(data = s2_lines07, ggplot2::aes(linetype = kind),
                   colour = SDMRES_FIG07_PATH_COL[["casing"]],
                   linewidth = SDMRES_FIG07_PATH_LWD[["casing"]],
                   key_glyph = "path"),
  ggplot2::geom_sf(data = s2_lines07, ggplot2::aes(linetype = kind),
                   colour = SDMRES_FIG07_PATH_COL[["line"]],
                   linewidth = SDMRES_FIG07_PATH_LWD[["line"]],
                   key_glyph = "path"))
sc07 <- list(
  ggplot2::scale_fill_manual(values = pal07, breaks = as.character(K173:1),
                             labels = fig_class_labels(K173), drop = FALSE,
                             name = "Total current, phase 1\n(class by rank)",
                             guide = ggplot2::guide_legend(order = 1)),
  ggplot2::scale_colour_manual(values = pal07, guide = "none"),
  ggplot2::scale_linetype_manual(values = c(stage2 = "solid"),
                                 labels = c(stage2 = lab_s2),
                                 name = "Modelled route",
                                 guide = ggplot2::guide_legend(order = 2)))
# fig_08: the main paths of the compared pairs and the Stage-2 paths (L8a,
# R3). The main lines first, the Stage-2 lines on top.
lev08 <- c("sdm", "stage2")
lab08 <- c(sdm = lab_sdm, stage2 = lab_s2)
sdm_lines08 <- sf::st_sf(kind = factor(rep("sdm", sum(cmp_ok)), levels = lev08),
                         geometry = sf::st_geometry(sdm_s2$main)[cmp_ok])
s2_lines08 <- sf::st_sf(kind = factor(rep("stage2", nrow(base_s2)),
                                      levels = lev08),
                        geometry = sf::st_geometry(base_s2))
aes08 <- ggplot2::aes(colour = kind, linetype = kind, linewidth = kind)
lay08 <- list(
  ggplot2::geom_sf(data = sdm_lines08, mapping = aes08, key_glyph = "path"),
  ggplot2::geom_sf(data = s2_lines08, mapping = aes08, key_glyph = "path"))
sc08 <- list(
  ggplot2::scale_colour_manual(values = SDMRES_FIG08_COLOURS, breaks = lev08,
                               labels = lab08, drop = FALSE,
                               name = "Modelled least-cost path"),
  ggplot2::scale_linetype_manual(values = SDMRES_FIG08_LTY, breaks = lev08,
                                 labels = lab08, drop = FALSE,
                                 name = "Modelled least-cost path"),
  ggplot2::scale_linewidth_manual(values = SDMRES_FIG08_LWD, breaks = lev08,
                                  labels = lab08, drop = FALSE,
                                  name = "Modelled least-cost path"))

# The draft captions (the narrative is the author's; Decision 27 point 10).
fig_doi <- function(txt) {
  d <- sub("^DOI:\\s*", "", grep("^DOI:", txt, value = TRUE))
  if (length(d) != 1L || !nzchar(d)) {
    stop("A GBIF DOI file must hold one line \"DOI: ...\".", call. = FALSE)
  }
  d
}
fig_doi_t <- fig_doi(rd173$read(tiger_doi_in, "caption"))
fig_doi_b <- fig_doi(rd173$read(bg_doi_in, "caption"))
fig_deg <- "\u00b0"; fig_dash <- "\u2013"
fig_area <- range(fig_quad_area_km2(grid_m$iy * SDM_GRAIN_DEG,
                                    (grid_m$iy + 1) * SDM_GRAIN_DEG,
                                    SDM_GRAIN_DEG))
fig_area_txt <- paste0(fig_fmt_int(fig_area[1]), fig_dash,
                       fig_fmt_int(fig_area[2]), " km\u00b2")
n_solved <- sum(status == "path")
n_s2  <- nrow(base_s2)
n_cmp <- sum(cmp_ok)
n_c02 <- sum(st_s2 == "contiguous_02")
n_np  <- sum(st_s2 == "no_path")
n_zero <- sum(cur172$main == 0)
lab_main <- sum173$label[sum173$surface == "main"]
lab_neg  <- sum173$label[sum173$surface == "negexp8"]
n_mat <- sum(cmp173$main$material_pair, na.rm = TRUE)
fig_txt <- list(
  modelled = paste0("The lines and the current are modelled. They are not ",
                    "observed tiger movement."),
  surface = paste0(
    "Resistance (Decision 27): R = ", SDMRES_R_MIN, " + ",
    SDMRES_R_MAX - SDMRES_R_MIN, " \u00d7 (1 \u2212 x), with x the rank of ",
    "the relative suitability of the model cell, from 0 (lowest) to 1 ",
    "(highest). The suitability comes from a maxnet model of presence and ",
    "background records. It is relative; it is not occupancy and not the ",
    "occupancy probability (\u03a8) of the national method. The rank gives ",
    "equal steps of rank, not of suitability."),
  grain = paste0(
    "Graph: the ", fig_fmt_int(n_model), " model cells of 0.2", fig_deg,
    " (cells of about 20 km; ", fig_area_txt, "), each joined to its 8 ",
    "neighbours. A route narrower than a cell does not show. A blank cell ",
    "is not a model cell. India only: no route goes through a neighbour ",
    "country."),
  effort = paste0(
    "Most presence records are in the reserves, so a low resistance in a ",
    "reserve partly shows where people record tigers (proposal \u00a77)."),
  label = paste0(
    "Comparison with the Stage-2 paths (Decision 27 point 7, the rule of ",
    "Decision 18): \"", lab_main, "\" (", n_mat, " of ", n_cmp,
    " compared pairs differ in route or in cost rank; Spearman rho ",
    fig_fmt(sum173$spearman_rho[sum173$surface == "main"]), " of the path ",
    "costs). The variant surface (negative exponential, c = ",
    SDMRES_NEGEXP_C, ") against the main surface: \"", lab_neg, "\"."),
  excluded = paste0(
    if (n_c02 == 1) "1 pair with a Stage-2 path has" else
      paste(n_c02, "pairs with a Stage-2 path have"),
    " no path here: the two reserves share a 0.2", fig_deg, " cell.",
    if (n_np > 0) paste0(" ", n_np, if (n_np == 1) " pair has" else
      " pairs have", " no route through model cells.") else ""),
  hatch = paste0(
    "Hatch: the ", fig_noor, " cells outside the training range of one or ",
    "more covariates; their values are clamped and kept."),
  outlines = paste0(
    "Reserve outlines: the core protected-area polygons of the NTCA ",
    "(Decision 4), not the notified total area. State lines: Natural Earth ",
    "(approximate)."),
  sources = paste0(
    "Sources: GBIF occurrence downloads ", fig_doi_t, " (tiger) and ",
    fig_doi_b, " (mammals), iNaturalist research-grade observations; ESA ",
    "WorldCover 2021; Global Human Modification 2022; terrain AWS Terrain ",
    "Tiles; OpenStreetMap data \u00a9 OpenStreetMap contributors (ODbL)."))
fig_title07 <- paste0("Modelled current between the tiger reserves on a ",
                      "suitability-based surface")
fig_sub07 <- paste0(
  "Circuit theory, phase 1: ", n_solved, " pairs on ",
  fig_fmt_int(n_model), " cells of 0.2", fig_deg, ", in five classes of ",
  "equal size by rank.\nLines: ", n_s2, " Stage-2 least-cost paths. Hatch: ",
  fig_noor, " cells outside the training range.")
fig_cap07 <- fig_wrap(list(
  paste0("Colour: the total current of circuit theory on the main surface: ",
         "1 A between the two reserves of each of the ", n_solved,
         " phase-1 pairs (Decision 17) that are not contiguous at 0.2",
         fig_deg, ", summed over the pairs. The cells of the two reserves of ",
         "a pair carry no current for that pair. A reserve with more pairs ",
         "sends more current. Five classes of equal size by rank; each class ",
         "holds 20\u00a0% of the model cells; the legend gives no value. ",
         n_zero, " cells carry no current (lowest class)."),
  paste0("Lines: the ", n_s2, " Stage-2 least-cost paths on the baseline ",
         "resistance surface of 1 km (Decisions 14 to 17)."),
  fig_txt$modelled, fig_txt$surface, fig_txt$grain, fig_txt$effort,
  fig_txt$label, fig_txt$hatch, fig_txt$outlines, fig_txt$sources))
fig_title08 <- paste0("Least-cost paths between the tiger reserves: ",
                      "suitability-based surface and Stage-2 surface")
fig_sub08 <- paste0(
  n_cmp, " paths on the main suitability-based surface (0.2", fig_deg,
  ") and ", n_s2, " Stage-2 paths (1 km). Comparison: \"", lab_main,
  "\".\nHatch: ", fig_noor, " cells outside the training range.")
fig_cap08 <- fig_wrap(list(
  paste0("Purple: the ", n_cmp, " least-cost paths on the main ",
         "suitability-based surface, through the centres of the 0.2", fig_deg,
         " cells. Grey dashes: the ", n_s2, " Stage-2 least-cost paths on the ",
         "baseline resistance surface of 1 km (Decisions 14 to 17). Where the ",
         "two share a route, the grey dashes are on the purple line."),
  fig_txt$excluded, fig_txt$modelled, fig_txt$surface, fig_txt$grain,
  fig_txt$effort, fig_txt$label, fig_txt$hatch, fig_txt$outlines,
  fig_txt$sources))

# The checks (stop before a file is written).
want_sz <- vapply(seq_len(K173), function(j) {
  ceiling(j * n_model / K173) - ceiling((j - 1) * n_model / K173)
}, numeric(1))
fig_texts <- c(fig_title07, fig_sub07, fig_cap07, fig_title08, fig_sub08,
               fig_cap08)
fig_chk173 <- list(
  "fig_07: one class for each model cell; the class sizes are ceiling(j n / k) - ceiling((j - 1) n / k) (classes 5 to 1)" =
    nrow(fig_c07) == n_model && !anyNA(fig_c07$class) &&
    identical(as.numeric(table(factor(cls07, levels = K173:1))), want_sz),
  "fig_07: the top class is the set of the top cells of point 7 (FC1)" =
    setequal(model_ids[cls07 == K173],
             model_ids[order(-cur172$main, model_ids)[seq_len(n_top)]]),
  "fig_07: the cells with no current are in the lowest class" =
    all(cls07[cur172$main == 0] == 1L),
  "fig_07 and fig_08: the Stage-2 lines are the paths of the baseline layer, none empty" =
    nrow(s2_lines07) == sum(s2$path_status == "path") &&
    !any(sf::st_is_empty(s2_lines07)) && nrow(s2_lines08) == nrow(s2_lines07),
  "fig_08: the main lines are the paths of the compared pairs, none empty (R3)" =
    nrow(sdm_lines08) == n_cmp && !any(sf::st_is_empty(sdm_lines08)),
  "the hatched cells are the cells outside the training range of tbl_16_sdm_prediction.csv" =
    fig_noor == tval("range", "cells_outside"),
  "each hatched cell holds one or more hatch lines" =
    fig_noor == 0 ||
    all(lengths(sf::st_intersects(cells_g[oor], fig_hatch)) > 0),
  "no field of a drawn or read table holds a presence, record or tiger word" =
    fig_fields_ok(fig_c07) && fig_fields_ok(s2_lines08) &&
    fig_fields_ok(sdm_lines08) && fig_fields_ok(grid_sf) &&
    fig_fields_ok(s2) && fig_fields_ok(data.frame(id = 1, current = 1)),
  "the reserve outlines and the state lines are geometry only" =
    identical(names(fig_res), "geometry") && identical(names(fig_st), "geometry"),
  "the read log: each read is on the list of its use (k1 of task 16.2)" =
    all(rd173$log()$fig %in% c("cells", "frame", "caption")),
  "the key box is inside the frame" =
    fig_key_x + 3 * fig_side < fig_bb[["xmax"]] &&
    fig_key_y + 3 * fig_side < fig_bb[["ymax"]],
  "the captions hold the label of point 7" =
    grepl(lab_main, fig_cap07, fixed = TRUE) &&
    grepl(lab_main, fig_cap08, fixed = TRUE),
  "no title or caption holds a coordinate (a number with a degree sign and N, S, E or W)" =
    !any(grepl("[0-9]\\s*\u00b0\\s*[NSEW]", fig_texts))
)
for (i in seq_along(fig_chk173)) {
  cat(sprintf("  %-4s %s\n", if (isTRUE(fig_chk173[[i]])) "ok" else "FAIL",
              names(fig_chk173)[i]))
}
if (!all(vapply(fig_chk173, isTRUE, logical(1)))) {
  stop("Figure check(s) failed. No figure is written.", call. = FALSE)
}

fig_p07 <- fig_frame_paths(
  fig_st, fig_res, fig_bb, FIG_FRAME_COLOURS, fig_title07, fig_sub07,
  fig_cap07, cells = fig_c07,
  cell_aes = ggplot2::aes(fill = class, colour = class), hatch = fig_hatch,
  key = fig_kb, key_label = fig_key_label, path_layers = lay07, scales = sc07)
fig_p08 <- fig_frame_paths(
  fig_st, fig_res, fig_bb, FIG_FRAME_COLOURS, fig_title08, fig_sub08,
  fig_cap08, hatch = fig_hatch, key = fig_kb, key_label = fig_key_label,
  path_layers = lay08, scales = sc08)
fig_path_of <- function(what) {
  file.path(DIR_FIGURES, sprintf("fig_%02d_%s.png", SDMRES_PUB_FIGS[[what]],
                                 SDMRES_FIG_SLUGS[[what]]))
}
fig_save_png(fig_p07, fig_path_of("current"), FIG_STAGE3_SIZE_IN,
             FIG_STAGE3_DPI, fig_paper)
fig_save_png(fig_p08, fig_path_of("paths"), FIG_STAGE3_SIZE_IN,
             FIG_STAGE3_DPI, fig_paper)

cat("\nThe reads of STEP 17.3 (k1 of task 16.2):\n")
print(rd173$log(), row.names = FALSE)
cat("\nDRAFT captions (the narrative is the author's):\n")
for (fg in list(c("fig_07", fig_title07, fig_sub07, fig_cap07),
                c("fig_08", fig_title08, fig_sub08, fig_cap08))) {
  cat("\n---", fg[1], "(DRAFT) ---\nTitle:", fg[2], "\nSubtitle:", fg[3],
      "\nCaption:\n", fg[4], "\n", sep = "")
}

cat(sprintf("\nSTEP 17.3 time: %.1f min\n",
            as.numeric(difftime(Sys.time(), t_step173, units = "mins"))))
rule("STEP 17.3 done. Next: STEP 17.4 (task 17.6): the QA of phase 1.")
