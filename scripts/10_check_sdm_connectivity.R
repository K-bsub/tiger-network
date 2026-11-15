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
#   STEP 17.3 (task 17.5)  the comparison of point 7; fig_07 and fig_08
#   STEP 17.4 (task 17.6)  the QA of phase 1
#   STEP 17.5 (task 17.6b) phase 2 (points 6 and 8) and its QA; only with
#              RUN_PHASE2 = TRUE
#
# SENSITIVE DATA (docs/sensitive-data-policy.md; Decision 27 point 10):
#   The surfaces, the currents and the paths stay under data/processed/
#   (gitignored). The suitability comes from a model on records that the
#   source obscured (tier T1). This script prints TRUE/FALSE, names, counts
#   and statistics only: no coordinate, no cell corner, no cell id. A tbl_19
#   table holds no position and no cell id.
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

# Fields that this script uses. The structure of the earlier layers and
# tables, not choices of the analysis.
FIELDS_GRID  <- c("id", "ix", "iy", "n_cc", "area_km2", "share", "model")
FIELDS_PAIRS <- c("pair_id", "from_unit_id", "to_unit_id", "contiguous")
FIELDS_T17   <- c("unit_id", "n_1km_cells_used", "n_1km_cells_no_value")

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
