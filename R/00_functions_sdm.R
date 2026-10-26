# =============================================================================
# 00_functions_sdm.R
# Functions for the Stage-3 model at a coarser grain (Decision 23,
# 2026-10-25). scripts/09_model_suitability.R sources this file (process
# choice f1 of task 14.2). The settings are the SDM_* values of
# R/00_config.R; no value of the analysis is written here as a literal.
#
# Task 14.2 (2026-10-25): the guard functions of the script header.
#   sdm_check_config()   the SDM_* block of Decision 23 and the outcome lock
#   sdm_cell_index()     integer column and row of a 0.2 degree cell corner
#   sdm_n_cells()        number of different 0.2 degree cells
#   sdm_read_fields()    the field names and the CRS of a vector layer
#   sdm_run_guards()     a named list of TRUE/FALSE checks -> stop on FALSE
# Task 14.4 (2026-10-25): STEP 14.1 — the 0.2 degree cells, the model cells
# and the counts (process choices g1, k1, h1).
#   sdm_cell_id()        one integer per 0.2 degree cell (from ix, iy)
#   sdm_centre_cells()   the 0.2 degree cell of each complete-case 1 km cell
#   sdm_cell_polygons()  the polygons of 0.2 degree cells, densified, in the
#                        analysis CRS
#   sdm_build_grid()     the grid: complete-case centres, area and cover
#                        share of each cell, the model-cell flag
#   sdm_cellid_rast()    the 0.2 degree cell id of each complete-case 1 km
#                        cell, on the 1 km template
#   sdm_outcome()        the outcome of Decision 23 points 4 and 6
#   sdm_count_cells()    the counts of STEP 14.1 (tbl_16_sdm_counts.csv)
#   sdm_self_test()      the hand-made case (process choice h1)
# Task 14.5 (2026-10-25): STEP 14.2 — Decision 24 (process choices q1, t1,
# y1, h1, w1).
#   sdm_covariates()        the covariates of the model cells (points 1-2)
#   sdm_select_covariates() the collinearity rule (point 3)
#   sdm_aicc_value(), sdm_fit(), sdm_predict(), sdm_aicc_grid(),
#   sdm_select_aicc()       the AICc grid and the selection (point 4)
#   sdm_auc(), sdm_boyce(), sdm_or10(), sdm_block_id(), sdm_fold_blocks(),
#   sdm_cv()                the block cross-validation (point 7)
#   sdm_compare()           the comparison of a sensitivity run (point 10)
#   sdm_object_ok()         the check of the model file (point 11)
#   sdm_self_test_142()     the hand-made case of STEP 14.2 (h1)
# Task 14.6 (2026-10-25): STEP 14.3 — the QA (process choices c1, m1, h1, p1,
# s1). A second path: these functions do not call the sdm_* functions of
# STEPs 14.1 and 14.2.
#   sdm_qa_corner_fail()    points not in the cell of their stored corner
#   sdm_qa_key()            a text key of a 0.2 degree cell from its corner
#   sdm_qa_zonal()          the covariates again, by terra::zonal()
#   sdm_qa_diff()           the largest relative difference of two vectors
#   sdm_qa_kept()           the collinearity rule again
#   sdm_qa_aicc(), sdm_qa_select()  AICc and the selection again
#   sdm_qa_auc()            AUC from the Wilcoxon statistic
#   sdm_qa_largest_part()   the largest part of an object (point 11)
#   sdm_qa_id_hits()        values of a table that are a cell id
#   sdm_qa_reserve_hits()   reserve names or reserve columns in a table
#   sdm_self_test_143()     the hand-made case of STEP 14.3 (h1)
#
# SENSITIVE DATA: these functions return TRUE/FALSE, names and counts, and
# the grid (cell ids, shares, polygons). The grid holds no presence or
# background flag. None of them prints a coordinate, a cell corner or a cell
# id.
# =============================================================================

# ---- The SDM_* block of Decision 23 ------------------------------------------
# Stops with the name of each failed check. The values are compared with the
# Decision-21 settings that Decision 23 reuses (points 2, 4 and 5).
sdm_check_config <- function() {
  need <- c("SDM_MODEL", "SDM_PRESENCE_SET", "SDM_GRAIN_DEG", "SDM_GRAIN_CRS",
            "SDM_CELL_MIN_COVER", "SDM_MIN_CELLS", "SDM_MIN_CELLS_FULL",
            "SDM_REDUCED_MAX_CLASSES", "SDM_BG_DATASET_KEY",
            "SDM_BG_OBSCURED", "SDM_BG_UNCERT_SETS", "SDM_BG_SCOPE",
            "SDM_BG_MIN_RATIO", "SDM_OUTCOME_VALUES", "SDM_GRAIN_OUTCOME",
            "SDM_CHECK_ABSENT_DATASETS", "SDM_GISTAR_SETS",
            "SDM_GISTAR_PUBLISH_TIGER", "SDM_RATIO",
            "OCC_OBSCURED_CELL_DEG", "OCC_MIN_CELLS_MODEL",
            "OCC_MIN_CELLS_FULL", "OCC_REDUCED_MAX_CLASSES",
            "OCC_INAT_DATASET_KEY", "OCC_POINT8_OUTCOME", "CRS_WGS84")
  miss <- need[!vapply(need, exists, logical(1))]
  if (length(miss) > 0) {
    stop("Setting(s) missing from R/00_config.R: ",
         paste(miss, collapse = ", "), call. = FALSE)
  }
  checks <- list(
    "OCC_POINT8_OUTCOME must be no_1km_model (Decision 21 point 8)" =
      identical(OCC_POINT8_OUTCOME, "no_1km_model"),
    "SDM_MODEL must be coarse_grain (Decision 23 a2)" =
      identical(SDM_MODEL, "coarse_grain"),
    "SDM_PRESENCE_SET must be obscured (Decision 23 b3)" =
      identical(SDM_PRESENCE_SET, "obscured"),
    "SDM_GRAIN_DEG must be OCC_OBSCURED_CELL_DEG = 0.2 (Decision 23 b3)" =
      isTRUE(all.equal(SDM_GRAIN_DEG, OCC_OBSCURED_CELL_DEG)) &&
      isTRUE(all.equal(SDM_GRAIN_DEG, 0.2)),
    "SDM_GRAIN_CRS must be CRS_WGS84 (Decision 23 b3)" =
      identical(as.integer(SDM_GRAIN_CRS), as.integer(CRS_WGS84)),
    "SDM_CELL_MIN_COVER must be above 0 and 1 or below (Decision 23 v1)" =
      is.numeric(SDM_CELL_MIN_COVER) && length(SDM_CELL_MIN_COVER) == 1 &&
      SDM_CELL_MIN_COVER > 0 && SDM_CELL_MIN_COVER <= 1,
    "SDM_MIN_CELLS, SDM_MIN_CELLS_FULL and SDM_REDUCED_MAX_CLASSES must be the Decision-21 values (Decision 23 c1)" =
      identical(SDM_MIN_CELLS, OCC_MIN_CELLS_MODEL) &&
      identical(SDM_MIN_CELLS_FULL, OCC_MIN_CELLS_FULL) &&
      identical(SDM_REDUCED_MAX_CLASSES, OCC_REDUCED_MAX_CLASSES),
    "SDM_BG_DATASET_KEY must be OCC_INAT_DATASET_KEY (Decision 23 r2)" =
      identical(SDM_BG_DATASET_KEY, OCC_INAT_DATASET_KEY),
    "SDM_BG_OBSCURED must be TRUE (Decision 23 r2)" =
      identical(SDM_BG_OBSCURED, TRUE),
    "SDM_BG_UNCERT_SETS must be uncert_set values of Decision 21 (Decision 23 r2)" =
      length(SDM_BG_UNCERT_SETS) > 0 &&
      all(SDM_BG_UNCERT_SETS %in% c("1km", "5km")),
    "SDM_BG_SCOPE must be Mammalia (Decision 23 s1)" =
      identical(SDM_BG_SCOPE, "Mammalia"),
    "SDM_BG_MIN_RATIO must be 1 or more (Decision 23 m1)" =
      is.numeric(SDM_BG_MIN_RATIO) && length(SDM_BG_MIN_RATIO) == 1 &&
      SDM_BG_MIN_RATIO >= 1,
    "SDM_OUTCOME_VALUES must be the four outcomes of Decision 23" =
      identical(SDM_OUTCOME_VALUES,
                c("no_model_presence", "no_model_background",
                  "reduced_model", "planned_model")),
    "SDM_GRAIN_OUTCOME must be NA or one of SDM_OUTCOME_VALUES (process choice l1)" =
      length(SDM_GRAIN_OUTCOME) == 1 &&
      (is.na(SDM_GRAIN_OUTCOME) || SDM_GRAIN_OUTCOME %in% SDM_OUTCOME_VALUES),
    "SDM_CHECK_ABSENT_DATASETS must hold one or more dataset keys (Decision 23 e1)" =
      is.character(SDM_CHECK_ABSENT_DATASETS) &&
      length(SDM_CHECK_ABSENT_DATASETS) > 0 &&
      !anyNA(SDM_CHECK_ABSENT_DATASETS),
    "SDM_GISTAR_SETS must be effort and tiger (Decision 23 f2)" =
      identical(SDM_GISTAR_SETS, c("effort", "tiger")),
    "SDM_GISTAR_PUBLISH_TIGER must be FALSE (Decision 23 f2)" =
      identical(SDM_GISTAR_PUBLISH_TIGER, FALSE),
    "SDM_RATIO must be FALSE (Decision 23 f2)" = identical(SDM_RATIO, FALSE)
  )
  sdm_run_guards(checks, what = "the SDM_* block of R/00_config.R")
}

# ---- 0.2 degree cells ----------------------------------------------------------
# The corner columns (cell02_lon_deg, cell02_lat_deg) come from occ_cell02():
# floor(round(x / deg, 9)) * deg. The integer index is round(corner / deg),
# so two corners of one cell always give one index, whatever the last bits of
# the double.
sdm_cell_index <- function(cell_lon_deg, cell_lat_deg, deg = SDM_GRAIN_DEG) {
  if (length(cell_lon_deg) != length(cell_lat_deg)) {
    stop("sdm_cell_index(): the two corner columns differ in length.",
         call. = FALSE)
  }
  ix <- round(cell_lon_deg / deg)
  iy <- round(cell_lat_deg / deg)
  # A corner must be on the grid: its index times deg gives the corner back.
  off <- pmax(abs(ix * deg - cell_lon_deg), abs(iy * deg - cell_lat_deg))
  if (any(off > 1e-6, na.rm = TRUE)) {
    stop("sdm_cell_index(): a corner is not a multiple of ", deg, " degrees.",
         call. = FALSE)
  }
  data.frame(ix = as.integer(ix), iy = as.integer(iy))
}

# Number of different 0.2 degree cells of a set of corners.
sdm_n_cells <- function(cell_lon_deg, cell_lat_deg, deg = SDM_GRAIN_DEG) {
  idx <- sdm_cell_index(cell_lon_deg, cell_lat_deg, deg)
  if (anyNA(idx$ix) || anyNA(idx$iy)) {
    stop("sdm_n_cells(): a record has no 0.2 degree cell.", call. = FALSE)
  }
  nrow(unique(idx))
}

# One integer per cell: iy * 100000 + ix. The cells of India have ix from
# about 340 to 490 and iy from about 30 to 190 (0.2 degree steps), so the id
# is unique and below 2^31. The id is a position at 0.2 degrees: it goes into
# the gitignored grid files only, never into a table.
SDM_ID_BASE <- 100000L
sdm_cell_id <- function(ix, iy) {
  if (anyNA(ix) || anyNA(iy) || any(ix < 0L) || any(iy < 0L) ||
      any(ix >= SDM_ID_BASE) || any(iy * SDM_ID_BASE + ix > .Machine$integer.max)) {
    stop("sdm_cell_id(): an index is NA or outside the id range.",
         call. = FALSE)
  }
  as.integer(iy) * SDM_ID_BASE + as.integer(ix)
}

# ---- STEP 14.1: the grid (process choice g1) -----------------------------------
# The 0.2 degree cell of the centre of each complete-case 1 km cell. The
# centre is converted from the analysis CRS to longitude and latitude, and
# gets its cell by the record rule (occ_cell02(): a centre on an edge goes to
# the cell north or east of it).
#   stack_r : the covariate stack (the Decision-10 common mask)
# Returns a data frame: cell_1km (cell number of the template), ix, iy, id.
sdm_centre_cells <- function(stack_r, deg = SDM_GRAIN_DEG) {
  ok <- terra::values(terra::noNA(stack_r), mat = FALSE)
  cc <- which(ok == 1)
  if (length(cc) == 0) stop("sdm_centre_cells(): no complete-case cell.",
                            call. = FALSE)
  xy <- terra::xyFromCell(stack_r, cc)
  ll <- sf::sf_project(from = sf::st_crs(terra::crs(stack_r)),
                       to = sf::st_crs(CRS_WGS84), pts = xy)
  if (anyNA(ll)) stop("sdm_centre_cells(): a centre did not convert.",
                      call. = FALSE)
  corner <- occ_cell02(ll[, 1], ll[, 2], deg)
  idx <- sdm_cell_index(corner$cell02_lon_deg, corner$cell02_lat_deg, deg)
  data.frame(cell_1km = cc, ix = idx$ix, iy = idx$iy,
             id = sdm_cell_id(idx$ix, idx$iy))
}

# The polygons of cells (ix, iy) in longitude and latitude, each edge cut into
# segments of densify_deg, then converted to the analysis CRS. Returns an sfc.
sdm_cell_polygons <- function(ix, iy, deg = SDM_GRAIN_DEG, densify_deg = 0.01,
                              crs_out = CRS_ANALYSIS) {
  n_seg <- max(1L, as.integer(round(deg / densify_deg)))
  s <- seq(0, 1, length.out = n_seg + 1L)
  polys <- lapply(seq_along(ix), function(i) {
    x0 <- ix[i] * deg; y0 <- iy[i] * deg; x1 <- x0 + deg; y1 <- y0 + deg
    ring <- rbind(
      cbind(x0 + s * deg, y0),                      # south edge, west to east
      cbind(x1, y0 + s[-1] * deg),                  # east edge, south to north
      cbind(x1 - s[-1] * deg, y1),                  # north edge, east to west
      cbind(x0, y1 - s[-c(1, n_seg + 1L)] * deg)    # west edge, north to south
    )
    # Close the ring with the first point itself (x1 - deg is not always x0
    # in floating point).
    sf::st_polygon(list(rbind(ring, ring[1, ])))
  })
  g <- sf::st_sfc(polys, crs = CRS_WGS84)
  sf::st_transform(g, crs_out)
}

# The grid of 0.2 degree cells that hold one or more complete-case centres.
#   centres  : the output of sdm_centre_cells()
#   cell_km2 : the area of one 1 km cell, in km2 of the analysis CRS
# The share of a cell = (its complete-case centres x cell_km2) / (the area
# of its polygon in the analysis CRS). model = share >= min_cover (Decision 23
# point 3). Returns an sf: id, ix, iy, n_cc, area_km2, share, model.
sdm_build_grid <- function(centres, deg = SDM_GRAIN_DEG,
                           min_cover = SDM_CELL_MIN_COVER,
                           cell_km2 = (GRID_CELL_M / 1000)^2,
                           densify_deg = 0.01, crs_out = CRS_ANALYSIS) {
  ids <- sort(unique(centres$id))
  u <- data.frame(id = ids, ix = as.integer(ids %% SDM_ID_BASE),
                  iy = as.integer(ids %/% SDM_ID_BASE))
  n_cc <- tabulate(match(centres$id, u$id), nbins = nrow(u))
  g <- sdm_cell_polygons(u$ix, u$iy, deg, densify_deg, crs_out)
  area_km2 <- as.numeric(sf::st_area(g)) / 1e6
  share <- n_cc * cell_km2 / area_km2
  sf::st_sf(id = u$id, ix = u$ix, iy = u$iy, n_cc = as.integer(n_cc),
            area_km2 = area_km2, share = share, model = share >= min_cover,
            geometry = g)
}

# The 0.2 degree cell id of each complete-case 1 km cell, on the template of
# the stack (NA elsewhere). For the covariate summaries of STEP 14.2.
sdm_cellid_rast <- function(stack_r, centres) {
  r <- terra::rast(stack_r[[1]])
  terra::values(r) <- NA_integer_
  r[centres$cell_1km] <- centres$id
  names(r) <- "cell02_id"
  r
}

# ---- STEP 14.1: the outcome of Decision 23 points 4 and 6 ----------------------
# Point 4 first (presence cells), then point 6 (background cells).
sdm_outcome <- function(n_presence, n_background,
                        min_cells = SDM_MIN_CELLS,
                        min_full = SDM_MIN_CELLS_FULL,
                        bg_ratio = SDM_BG_MIN_RATIO) {
  if (n_presence < min_cells) return("no_model_presence")
  if (n_background < bg_ratio * n_presence) return("no_model_background")
  if (n_presence < min_full) return("reduced_model")
  "planned_model"
}

# ---- STEP 14.1: the counts --------------------------------------------------------
#   grid_d   : the grid without geometry (id, model, n_cc)
#   pres_id  : the cell id of each presence record (the obscured set)
#   bg_id    : the cell id of each background record
#   bg_part  : the part of each background record ("obscured" or "uncert")
#   n_cc_all : the number of complete-case 1 km cells of the stack
# Returns list(table = the long table for tbl_16_sdm_counts.csv,
#              n_presence, n_background, outcome).
sdm_count_cells <- function(grid_d, pres_id, bg_id, bg_part, n_cc_all) {
  model_id <- grid_d$id[grid_d$model]
  pres_cells  <- unique(pres_id)
  pres_model  <- pres_cells[pres_cells %in% model_id]
  bg_model_a  <- unique(bg_id[bg_part == "obscured" & bg_id %in% model_id])
  bg_model_b  <- unique(bg_id[bg_part == "uncert" & bg_id %in% model_id])
  bg_model    <- union(bg_model_a, bg_model_b)
  n_pres <- length(pres_model)
  n_bg   <- length(bg_model)
  outcome <- sdm_outcome(n_pres, n_bg)
  row <- function(group, item, value) {
    data.frame(group = group, item = item, value = as.numeric(value),
               stringsAsFactors = FALSE)
  }
  tbl <- rbind(
    row("grid", "complete_case_1km_cells", n_cc_all),
    row("grid", "cells_with_complete_case_centres", nrow(grid_d)),
    row("grid", "model_cells", length(model_id)),
    row("grid", "complete_case_1km_cells_in_model_cells",
        sum(grid_d$n_cc[grid_d$model])),
    row("presence", "records", length(pres_id)),
    row("presence", "cells_all", length(pres_cells)),
    row("presence", "cells_not_model", length(pres_cells) - n_pres),
    row("presence", "records_not_model", sum(!pres_id %in% model_id)),
    row("presence", "cells_model", n_pres),
    row("background", "obscured_records", sum(bg_part == "obscured")),
    row("background", "obscured_cells_all",
        length(unique(bg_id[bg_part == "obscured"]))),
    row("background", "obscured_cells_model", length(bg_model_a)),
    row("background", "uncert_records", sum(bg_part == "uncert")),
    row("background", "uncert_cells_all",
        length(unique(bg_id[bg_part == "uncert"]))),
    row("background", "uncert_cells_model", length(bg_model_b)),
    row("background", "cells_model", n_bg),
    row("background", "cells_model_with_presence",
        sum(bg_model %in% pres_model)),
    row("test", "min_presence_cells", SDM_MIN_CELLS),
    row("test", "full_presence_cells", SDM_MIN_CELLS_FULL),
    row("test", "min_background_cells", SDM_BG_MIN_RATIO * n_pres),
    row("test", "background_to_presence_ratio",
        if (n_pres > 0) n_bg / n_pres else 0)
  )
  tbl$grain_outcome <- ifelse(tbl$group == "test", outcome, "")
  list(table = tbl, n_presence = n_pres, n_background = n_bg,
       outcome = outcome)
}

# ---- STEP 14.1: the hand-made case (process choice h1) ---------------------------
# Made-up values only. Returns a data frame (check, pass); the caller stops on
# a FALSE. Five groups:
#   1. the cell of a coordinate, also on an edge (the record rule)
#   2. the id: unique, and the same for the corners of one cell
#   3. the polygon area in the analysis CRS against the area on the ellipsoid
#   4. the cover share on a made-up 1 km grid: about 1 inside, about 0.5 for
#      a cell with complete-case cells on its east half only, 0 outside
#   5. the counts and the outcome on made-up records
sdm_self_test <- function() {
  chk <- list()
  add <- function(name, ok) chk[[name]] <<- isTRUE(ok)
  deg <- 0.2
  # 1. cells of coordinates (76.8 and 11.4 are on edges)
  c1 <- occ_cell02(c(76.8, 76.81, 76.99999999, 77.0), c(11.4, 11.39, 11.5, 11.6),
                   deg)
  i1 <- sdm_cell_index(c1$cell02_lon_deg, c1$cell02_lat_deg, deg)
  add("1a a coordinate on an edge goes to the cell north and east of it",
      i1$ix[1] == 384L && i1$iy[1] == 57L)
  add("1b a coordinate just south of an edge goes to the cell south of it",
      i1$iy[2] == 56L)
  add("1c a coordinate just west of an edge goes to the cell west of it",
      i1$ix[3] == 384L)
  add("1d 77.0 / 11.6 is the corner of cell (385, 58)",
      i1$ix[4] == 385L && i1$iy[4] == 58L)
  # 2. the id
  id <- sdm_cell_id(i1$ix, i1$iy)
  add("2a the id is the same for two points of one cell",
      id[1] == sdm_cell_id(384L, 57L))
  add("2b two different cells have two different ids",
      length(unique(sdm_cell_id(c(384L, 385L, 384L), c(57L, 57L, 58L)))) == 3)
  # 3. polygon area against the ellipsoid (lwgeom or s2), at 8 and 30 N
  g  <- sdm_cell_polygons(c(385L, 385L), c(40L, 150L), deg)
  a_proj <- as.numeric(sf::st_area(g)) / 1e6
  g_ll <- sf::st_transform(g, CRS_WGS84)
  a_ell <- as.numeric(sf::st_area(g_ll)) / 1e6
  add("3a the area in the analysis CRS is within 5 % of the area on the ellipsoid",
      all(abs(a_proj / a_ell - 1) < 0.05))
  add("3b a cell at 8 N is larger than a cell at 30 N", a_ell[1] > a_ell[2])
  # 4. cover share on a made-up 1 km grid around cell (385, 57)
  ctr <- sf::st_transform(sf::st_sfc(sf::st_point(c(77.1, 11.5)),
                                     crs = CRS_WGS84), CRS_ANALYSIS)
  xy0 <- round(sf::st_coordinates(ctr)[1, ] / 1000) * 1000
  tmpl <- terra::rast(xmin = xy0[1] - 60000, xmax = xy0[1] + 60000,
                      ymin = xy0[2] - 60000, ymax = xy0[2] + 60000,
                      resolution = GRID_CELL_M,
                      crs = paste0("EPSG:", CRS_ANALYSIS))
  all_xy <- terra::xyFromCell(tmpl, seq_len(terra::ncell(tmpl)))
  all_ll <- sf::sf_project(from = sf::st_crs(terra::crs(tmpl)),
                           to = sf::st_crs(CRS_WGS84), pts = all_xy)
  # complete-case: all cells, except the west half of cell (384, 57)
  # (76.8-77.0 E, 11.4-11.6 N), which has complete-case cells east of 76.9 E
  # only.
  in_w <- all_ll[, 1] >= 76.8 & all_ll[, 1] < 76.9 &
    all_ll[, 2] >= 11.4 & all_ll[, 2] < 11.6
  v <- rep(1, terra::ncell(tmpl)); v[in_w] <- NA
  s1 <- tmpl; terra::values(s1) <- v
  s2 <- tmpl; terra::values(s2) <- v * 2
  stk <- c(s1, s2)
  cen <- sdm_centre_cells(stk, deg)
  grd <- sf::st_drop_geometry(sdm_build_grid(cen, deg, min_cover = 0.5))
  sh_in   <- grd$share[grd$id == sdm_cell_id(385L, 57L)]
  sh_half <- grd$share[grd$id == sdm_cell_id(384L, 57L)]
  add("4a a cell with all centres complete-case has a share of about 1",
      length(sh_in) == 1 && abs(sh_in - 1) < 0.03)
  add("4b a cell with complete-case cells on its east half has a share of about 0.5",
      length(sh_half) == 1 && abs(sh_half - 0.5) < 0.03)
  add("4c the centres of the grid add up to the complete-case cells",
      sum(grd$n_cc) == sum(!is.na(v)))
  # 5. counts and outcome on made-up records
  gd <- data.frame(id = c(1L, 2L, 3L, 4L), model = c(TRUE, TRUE, FALSE, TRUE),
                   n_cc = c(400L, 410L, 100L, 420L))
  cnt <- sdm_count_cells(gd, pres_id = c(1L, 1L, 3L, 2L),
                         bg_id = c(1L, 2L, 3L, 4L, 4L),
                         bg_part = c("obscured", "uncert", "uncert",
                                     "uncert", "obscured"),
                         n_cc_all = 1330)
  tv <- stats::setNames(cnt$table$value,
                        paste(cnt$table$group, cnt$table$item))
  add("5a presence cells on model cells: 2 (a record in a non-model cell is out)",
      cnt$n_presence == 2 && tv[["presence cells_not_model"]] == 1 &&
        tv[["presence records_not_model"]] == 1)
  add("5b background cells on model cells: 3 (the two parts together)",
      cnt$n_background == 3 && tv[["background obscured_cells_model"]] == 2 &&
        tv[["background uncert_cells_model"]] == 2)
  add("5c background cells that are also presence cells: 2",
      tv[["background cells_model_with_presence"]] == 2)
  add("5d outcome below 25 presence cells: no_model_presence",
      sdm_outcome(24, 10000, 25, 80, 10) == "no_model_presence")
  add("5e outcome with a background below 10 x: no_model_background",
      sdm_outcome(30, 299, 25, 80, 10) == "no_model_background")
  add("5f outcome at 30 presence cells and 300 background cells: reduced_model",
      sdm_outcome(30, 300, 25, 80, 10) == "reduced_model")
  add("5g outcome at 79 and 790: reduced_model; at 80 and 800: planned_model",
      sdm_outcome(79, 790, 25, 80, 10) == "reduced_model" &&
        sdm_outcome(80, 800, 25, 80, 10) == "planned_model")
  add("5h the count table has no position or cell column",
      tryCatch({
        occ_assert_counts_only(cnt$table, cols = names(cnt$table),
                               count_cols = "value", name = "test")
        TRUE
      }, error = function(e) FALSE))
  data.frame(check = names(chk), pass = unlist(chk), row.names = NULL,
             stringsAsFactors = FALSE)
}

# =============================================================================
# Task 14.5 — STEP 14.2: covariates, collinearity, AICc, fit, cross-validation,
# sensitivity runs, model file (Decision 24; process choices q1, t1, y1, h1,
# w1)
# =============================================================================

# ---- Covariates (Decision 24 points 1 and 2) -----------------------------------
# One row per model cell: the summaries of Decision 24 point 1 over the
# complete-case 1 km cells of the cell, with the water rule of point 2.
#   stack_r   : the covariate stack (bands named as in STACK_BANDS)
#   cellid_r  : sdm_cellid_1km_7755.tif (the 0.2 degree cell id of each
#               complete-case 1 km cell)
#   model_ids : the ids of the model cells
#   settl_r   : the city/town surface of Decision 22 (or NULL)
# Returns a data frame, one row per model cell, ordered by id: id, n_cc, the
# nine candidates, settl_mean (if settl_r), z1_water_excl (water 1 km cells
# not used in the terrain means), z1_elev_floored (1 km cells used in the
# elevation mean with a value raised to elev_min), water_only (TRUE if the
# terrain means use water cells only).
sdm_covariates <- function(stack_r, cellid_r, model_ids, settl_r = NULL,
                           lc_groups = SDM_LC_GROUPS,
                           water_class = SDM_WATER_CLASS,
                           elev_min = SDM_ELEV_MIN_M) {
  id_all <- terra::values(cellid_r, mat = FALSE)
  cc <- which(!is.na(id_all) & id_all %in% model_ids)
  id <- as.integer(id_all[cc])
  rm(id_all)
  ids <- sort(unique(id))
  if (!setequal(ids, model_ids)) {
    stop("sdm_covariates(): a model cell has no complete-case 1 km cell.",
         call. = FALSE)
  }
  gsum <- function(x) {
    r <- rowsum(x, id, reorder = TRUE)
    if (!identical(as.integer(rownames(r)), ids)) {
      stop("sdm_covariates(): the groups are out of order.", call. = FALSE)
    }
    r[, 1]
  }
  band <- function(r, name) {
    v <- terra::values(r[[name]], mat = FALSE)[cc]
    if (anyNA(v)) {
      stop("sdm_covariates(): ", name, " is NA on a complete-case cell.",
           call. = FALSE)
    }
    v
  }
  need <- c("landcover", "ghm", SDM_TERRAIN_BANDS, "dist_road_m")
  if (!all(need %in% names(stack_r))) {
    stop("sdm_covariates(): the stack must have the bands ",
         paste(need, collapse = ", "), ".", call. = FALSE)
  }
  lc    <- band(stack_r, "landcover")
  water <- lc == water_class
  n_cc   <- gsum(rep(1, length(id)))
  n_land <- gsum(as.numeric(!water))
  water_only <- n_land == 0
  # A 1 km cell is used in the terrain means if it is not water, or if its
  # model cell has water cells only (Decision 24 point 2).
  use <- !water | water_only[match(id, ids)]
  n_use <- gsum(as.numeric(use))
  tmean <- function(v) gsum(ifelse(use, v, 0)) / n_use
  elev <- band(stack_r, "elev")
  floored <- use & elev < elev_min
  out <- data.frame(id = ids, n_cc = as.integer(n_cc))
  out$ghm_mean      <- gsum(band(stack_r, "ghm")) / n_cc
  out$elev_mean     <- tmean(pmax(elev, elev_min))
  out$slope_mean    <- tmean(band(stack_r, "slope"))
  out$tri_mean      <- tmean(band(stack_r, "tri"))
  out$droad_km_mean <- gsum(band(stack_r, "dist_road_m") / 1000) / n_cc
  for (g in names(lc_groups)) {
    out[[g]] <- gsum(as.numeric(lc %in% lc_groups[[g]])) / n_cc
  }
  if (!is.null(settl_r)) {
    out$settl_mean <- gsum(band(settl_r, 1)) / n_cc
  }
  out$z1_water_excl   <- as.integer(gsum(as.numeric(water & !use)))
  out$z1_elev_floored <- as.integer(gsum(as.numeric(floored)))
  out$water_only      <- as.logical(water_only)
  rownames(out) <- NULL
  out
}

# ---- Collinearity (Decision 24 point 3) -----------------------------------------
# Pearson r between the candidates on all rows of `cov`; the candidates in
# the order of `priority`; a candidate is kept if its |r| with each kept
# candidate is r_max or less. Returns list(kept, cor = one row per pair).
sdm_select_covariates <- function(cov, priority = SDM_COV_PRIORITY,
                                  r_max = SDM_COR_MAX) {
  if (!all(priority %in% names(cov))) {
    stop("sdm_select_covariates(): a candidate is not in the table.",
         call. = FALSE)
  }
  x <- as.matrix(cov[, priority, drop = FALSE])
  if (anyNA(x) || any(apply(x, 2, stats::sd) == 0)) {
    stop("sdm_select_covariates(): a candidate is NA or constant.",
         call. = FALSE)
  }
  r <- stats::cor(x, method = "pearson")
  kept <- character(0)
  for (v in priority) {
    if (length(kept) == 0 || all(abs(r[v, kept]) <= r_max)) kept <- c(kept, v)
  }
  pairs <- t(utils::combn(priority, 2))
  tbl <- data.frame(var_a = pairs[, 1], var_b = pairs[, 2], r = r[pairs],
                    stringsAsFactors = FALSE)
  tbl$above_limit <- abs(tbl$r) > r_max
  list(kept = kept, cor = tbl)
}

# ---- AICc (Decision 24 point 4) --------------------------------------------------
# raw: the raw (exponential) output over all model cells; pres_idx: the
# positions of the presence cells in `raw`; k: the non-zero coefficients.
# The raw output is scaled to a sum of 1. No AICc if k >= n - 1.
sdm_aicc_value <- function(raw, pres_idx, k) {
  n <- length(pres_idx)
  if (k >= n - 1) return(c(loglik = NA_real_, aicc = NA_real_))
  sc <- raw / sum(raw)
  ll <- sum(log(sc[pres_idx]))
  c(loglik = ll, aicc = 2 * k - 2 * ll + 2 * k * (k + 1) / (n - k - 1))
}

# One maxnet fit with the feature classes and the multiplier.
sdm_fit <- function(p, data, classes, regmult,
                    add_samples = SDM_ADD_SAMPLES) {
  maxnet::maxnet(p, data,
                 f = maxnet::maxnet.formula(p, data, classes = classes),
                 regmult = regmult, addsamplestobackground = add_samples)
}

# Predictions of a fit (a numeric vector).
sdm_predict <- function(fit, newdata, type) {
  as.numeric(stats::predict(fit, newdata, type = type, clamp = TRUE))
}

# The grid of point 4. all_data: the covariates of all model cells (the rows
# of the AICc likelihood); pres_idx: the presence cells in all_data.
# Returns list(table, fits); a failed fit is a row with status "failed".
sdm_aicc_grid <- function(p, data, all_data, pres_idx,
                          fc_grid = SDM_FC_GRID,
                          rm_grid = SDM_REGMULT_GRID) {
  rows <- list()
  fits <- list()
  for (fc in fc_grid) for (rmv in rm_grid) {
    key <- paste0(fc, "_", rmv)
    fit <- tryCatch(sdm_fit(p, data, fc, rmv), error = function(e) e)
    if (inherits(fit, "error")) {
      rows[[key]] <- data.frame(classes = fc, regmult = rmv,
                                status = "failed", k = NA_integer_,
                                loglik = NA_real_, aicc = NA_real_)
      next
    }
    raw <- sdm_predict(fit, all_data, "exponential")
    k <- length(fit$betas)
    a <- sdm_aicc_value(raw, pres_idx, k)
    rows[[key]] <- data.frame(classes = fc, regmult = rmv,
                              status = if (is.na(a[["aicc"]])) "no_aicc" else
                                "fitted",
                              k = as.integer(k), loglik = a[["loglik"]],
                              aicc = a[["aicc"]])
    fits[[key]] <- fit
  }
  tbl <- do.call(rbind, rows)
  rownames(tbl) <- NULL
  list(table = tbl, fits = fits)
}

# The selection of point 4: within delta of the lowest AICc (strictly
# below), the fewest coefficients, then the lower AICc, then the grid order.
sdm_select_aicc <- function(tbl, delta = SDM_AICC_DELTA) {
  ok <- !is.na(tbl$aicc)
  if (!any(ok)) {
    stop("No model of the AICc grid has an AICc (Decision 24 point 4): the ",
         "author decides.", call. = FALSE)
  }
  tbl$delta_aicc <- ifelse(ok, tbl$aicc - min(tbl$aicc[ok]), NA_real_)
  cand <- which(ok & tbl$delta_aicc < delta)
  o <- cand[order(tbl$k[cand], tbl$aicc[cand], cand)]
  tbl$selected <- FALSE
  tbl$selected[o[1]] <- TRUE
  tbl
}

# ---- Evaluation (Decision 24 point 7) ---------------------------------------------
# AUC from ranks (the Mann-Whitney form): the share of (presence, background)
# pairs where the presence value is higher; a tie counts 1/2.
sdm_auc <- function(pres, bg) {
  np <- length(pres)
  nb <- length(bg)
  if (np == 0 || nb == 0) return(NA_real_)
  r <- rank(c(pres, bg))
  (sum(r[seq_len(np)]) - np * (np + 1) / 2) / (np * nb)
}

# The continuous Boyce index (Hirzel et al. 2006). obs: the predictions at
# the test presence cells; all: the predictions at all model cells. A window
# of width window x the range of `all`, at res centres from the lower end +
# half a window to the upper end - half a window; P/E = the share of obs in
# the window / the share of all in the window; windows with no cell of all
# are dropped; the index is the Spearman correlation of P/E and the centre.
# NA if fewer than 2 windows or P/E is constant.
sdm_boyce <- function(obs, all, window = SDM_BOYCE_WINDOW,
                      res = SDM_BOYCE_RES) {
  rng <- range(all)
  w <- diff(rng) * window
  if (!is.finite(w) || w <= 0 || length(obs) == 0) return(NA_real_)
  ctr <- seq(rng[1] + w / 2, rng[2] - w / 2, length.out = res)
  pe <- vapply(ctr, function(cc) {
    lo <- cc - w / 2
    hi <- cc + w / 2
    e <- mean(all >= lo & all <= hi)
    if (e == 0) return(NA_real_)
    mean(obs >= lo & obs <= hi) / e
  }, numeric(1))
  ok <- !is.na(pe)
  if (sum(ok) < 2 || stats::sd(pe[ok]) == 0) return(NA_real_)
  stats::cor(pe[ok], ctr[ok], method = "spearman")
}

# OR10: the share of the test presence values below the q quantile (R type
# 7) of the training presence values.
sdm_or10 <- function(train_pres, test_pres, q = SDM_OR_QUANTILE) {
  if (length(test_pres) == 0) return(NA_real_)
  thr <- stats::quantile(train_pres, q, type = 7, names = FALSE)
  mean(test_pres < thr)
}

# The block of a 0.2 degree cell: (ix %/% block_cells, iy %/% block_cells),
# as one integer id.
sdm_block_id <- function(ix, iy, block_cells) {
  sdm_cell_id(ix %/% block_cells, iy %/% block_cells)
}

# The folds of point 7. One row per data cell (block, is_pres, is_bg). The
# blocks are sorted by presence cells (most first), background cells (most
# first), block id; then given to the folds 1..k, k..1, 1..k, ...
# Returns a data frame: block, fold, n_presence, n_background.
sdm_fold_blocks <- function(block, is_pres, is_bg, k = SDM_CV_K) {
  b  <- sort(unique(block))
  fb <- factor(block, levels = b)
  np <- as.integer(tapply(is_pres, fb, sum))
  nb <- as.integer(tapply(is_bg, fb, sum))
  o  <- order(-np, -nb, b)
  pos <- seq_along(o)
  r <- (pos - 1L) %% (2L * k)
  fold <- ifelse(r < k, r + 1L, 2L * k - r)
  data.frame(block = b[o], fold = as.integer(fold), n_presence = np[o],
             n_background = nb[o])
}

# The cross-validation of point 7.
#   cells   : one row per data cell: id, is_pres, is_bg
#   cov     : the covariate table of all model cells (id + covariates)
#   covs    : the covariates of the model
# Returns list(folds = one row per fold, blocks = the fold of each block).
sdm_cv <- function(cells, cov, covs, classes, regmult, k = SDM_CV_K,
                   block_cells, type = SDM_EVAL_TYPE) {
  ix <- cells$id %% SDM_ID_BASE
  iy <- cells$id %/% SDM_ID_BASE
  cells$block <- sdm_block_id(ix, iy, block_cells)
  fb <- sdm_fold_blocks(cells$block, cells$is_pres, cells$is_bg, k)
  cells$fold <- fb$fold[match(cells$block, fb$block)]
  all_data <- cov[, covs, drop = FALSE]
  rows <- lapply(seq_len(k), function(f) {
    tr <- cells[cells$fold != f, ]
    te <- cells[cells$fold == f, ]
    tr_p <- tr$id[tr$is_pres]
    tr_b <- tr$id[tr$is_bg]
    te_p <- te$id[te$is_pres]
    te_b <- te$id[te$is_bg]
    base <- data.frame(fold = as.character(f),
                       blocks = sum(fb$fold == f),
                       test_presence_cells = length(te_p),
                       test_background_cells = length(te_b),
                       train_presence_cells = length(tr_p),
                       status = "fitted", boyce = NA_real_,
                       auc_test = NA_real_, or10 = NA_real_,
                       auc_train = NA_real_, auc_diff = NA_real_,
                       stringsAsFactors = FALSE)
    if (length(te_p) == 0 || length(tr_p) == 0) {
      base$status <- "no_presence"
      return(base)
    }
    dat <- rbind(cov[match(tr_p, cov$id), covs, drop = FALSE],
                 cov[match(tr_b, cov$id), covs, drop = FALSE])
    p <- c(rep(1, length(tr_p)), rep(0, length(tr_b)))
    fit <- tryCatch(sdm_fit(p, dat, classes, regmult), error = function(e) e)
    if (inherits(fit, "error")) {
      base$status <- "failed"
      return(base)
    }
    pr <- sdm_predict(fit, all_data, type)
    v <- function(ids) pr[match(ids, cov$id)]
    base$boyce     <- sdm_boyce(v(te_p), pr)
    base$auc_test  <- sdm_auc(v(te_p), v(te_b))
    base$or10      <- sdm_or10(v(tr_p), v(te_p))
    base$auc_train <- sdm_auc(v(tr_p), v(tr_b))
    base$auc_diff  <- base$auc_train - base$auc_test
    base
  })
  list(folds = do.call(rbind, rows), blocks = fb)
}

# ---- Sensitivity comparison (Decision 24 point 10) --------------------------------
# Spearman rho of two predictions over the same cells, and the share of the
# top cells of `main` (ceiling(top_share x n), ordered by value, a tie to the
# lower id) that are also in the top cells of `run`.
sdm_compare <- function(main, run, ids, top_share = SDM_SENS_TOP_SHARE,
                        rho_min = SDM_SENS_RHO_MIN,
                        overlap_min = SDM_SENS_OVERLAP_MIN) {
  rho <- stats::cor(main, run, method = "spearman")
  n_top <- ceiling(top_share * length(ids))
  top <- function(x) ids[order(-x, ids)][seq_len(n_top)]
  ov <- length(intersect(top(main), top(run))) / n_top
  list(rho = rho, top_overlap = ov,
       label = if (isTRUE(rho >= rho_min) && ov >= overlap_min) "robust" else
         "sensitive")
}

# ---- Model file (Decision 24 point 11) ---------------------------------------------
# FALSE if a part of obj (at any depth) is a vector, matrix or data frame
# with n_min or more elements (vector) or rows (matrix, data frame): such a
# part could hold the data rows. n_min = the number of data rows.
sdm_object_ok <- function(obj, n_min) {
  bad <- FALSE
  walk <- function(x) {
    if (is.data.frame(x) || !is.null(dim(x))) {
      if (NROW(x) >= n_min) bad <<- TRUE
      return(invisible(NULL))
    }
    if (is.list(x)) {
      for (el in x) walk(el)
      return(invisible(NULL))
    }
    if (is.atomic(x) && length(x) >= n_min) bad <<- TRUE
    invisible(NULL)
  }
  walk(obj)
  !bad
}

# ---- STEP 14.2: the hand-made case (process choice h1) ------------------------------
# Made-up values only (and the example data of the maxnet package for one
# fit). Returns a data frame (check, pass); the caller stops on a FALSE.
sdm_self_test_142 <- function() {
  chk <- list()
  add <- function(name, ok) chk[[name]] <<- isTRUE(ok)
  # 1. covariates: 6 cells of 1 km; model cells 1 (cells 1-3) and 2 (cells
  #    4-5, water only); cell 6 is not complete-case.
  tmpl <- terra::rast(nrows = 2, ncols = 3, xmin = 0, xmax = 3000, ymin = 0,
                      ymax = 2000, crs = paste0("EPSG:", CRS_ANALYSIS))
  mk <- function(v) { r <- tmpl; terra::values(r) <- v; r }
  stk <- c(mk(c(10, 80, 40, 80, 80, NA)), mk(c(0.2, 0.4, 0.6, 0.1, 0.3, NA)),
           mk(c(100, -50, 200, -20, 30, NA)), mk(c(2, 9, 4, 1, 3, NA)),
           mk(c(10, 90, 30, 5, 15, NA)),
           mk(c(1000, 2000, 3000, 500, 1500, NA)))
  names(stk) <- c("landcover", "ghm", "elev", "slope", "tri", "dist_road_m")
  cid <- mk(c(1L, 1L, 1L, 2L, 2L, NA))
  stl <- mk(c(0.1, 0.2, 0.3, 0.4, 0.5, NA))
  cv <- sdm_covariates(stk, cid, c(1L, 2L), stl)
  c1 <- cv[cv$id == 1, ]
  c2 <- cv[cv$id == 2, ]
  near <- function(a, b) isTRUE(all.equal(as.numeric(a), b, tolerance = 1e-9))
  add("1a terrain means without water cells (elev 150, slope 3, TRI 20)",
      near(c1$elev_mean, 150) && near(c1$slope_mean, 3) &&
        near(c1$tri_mean, 20))
  add("1b gHM, road (km) and settlement means over all complete-case cells",
      near(c1$ghm_mean, 0.4) && near(c1$droad_km_mean, 2) &&
        near(c1$settl_mean, 0.2))
  add("1c shares over all complete-case cells (forest 1/3, crop 1/3, open 0, built 0)",
      near(c1$lc_forest, 1 / 3) && near(c1$lc_crop, 1 / 3) &&
        near(c1$lc_open, 0) && near(c1$lc_built, 0))
  add("1d water-only cell: water cells used, elevation floor 0 (elev 15)",
      isTRUE(c2$water_only) && near(c2$elev_mean, 15) &&
        near(c2$slope_mean, 2) && near(c2$tri_mean, 10))
  add("1e z1 counts: 1 water cell out (cell 1); 1 elevation floored (cell 2)",
      c1$z1_water_excl == 1L && c2$z1_water_excl == 0L &&
        c1$z1_elev_floored == 0L && c2$z1_elev_floored == 1L)
  add("1f the cell that is not complete-case is not used (n_cc 3 and 2)",
      c1$n_cc == 3L && c2$n_cc == 2L)
  # 2. collinearity
  x1 <- 1:20
  tst <- data.frame(x2 = x1 + rep(c(0.1, -0.1), 10), x1 = x1,
                    x3 = rep(c(1, 5), 10))
  sel <- sdm_select_covariates(tst, priority = c("x2", "x1", "x3"),
                               r_max = 0.7)
  add("2a a candidate with |r| > 0.7 to a kept one is removed (x1)",
      identical(sel$kept, c("x2", "x3")))
  add("2b the correlation table has one row per pair (3)",
      nrow(sel$cor) == 3 && sum(sel$cor$above_limit) == 1)
  # 3. AICc
  raw <- c(1, 1, 2, 4)
  a <- sdm_aicc_value(raw, c(4, 4, 3, 1, 2), 1)
  ll <- 2 * log(0.5) + log(0.25) + 2 * log(0.125)
  add("3a AICc = 2K - 2LL + 2K(K+1)/(n-K-1) on scaled raw values",
      near(a[["loglik"]], ll) && near(a[["aicc"]], 2 - 2 * ll + 4 / 3))
  add("3b no AICc if K >= n - 1",
      is.na(sdm_aicc_value(raw, c(4, 4, 3, 1, 2), 4)[["aicc"]]))
  tb <- data.frame(classes = c("lqph", "lqh", "lq", "lqph"),
                   regmult = c(1, 2, 3, 4), k = c(30L, 12L, 5L, 50L),
                   aicc = c(100, 101.5, 103, NA))
  ts <- sdm_select_aicc(tb, delta = 2)
  add("3c selection: within 2, the fewest coefficients (row 2)",
      which(ts$selected) == 2L && is.na(ts$delta_aicc[4]))
  # 4. folds
  blk <- rep(1:12, times = c(10:1, 1, 1))
  isp <- c(rep(TRUE, 55), FALSE, FALSE)
  isb <- !isp
  fb <- sdm_fold_blocks(blk, isp, isb, k = 5)
  add("4a serpentine folds 1 2 3 4 5 5 4 3 2 1 1 2",
      identical(fb$fold, c(1L, 2L, 3L, 4L, 5L, 5L, 4L, 3L, 2L, 1L, 1L, 2L)) &&
        identical(fb$block, 1:12))
  add("4b the block of a cell: 2 degree blocks from the cell index",
      sdm_block_id(385L, 57L, 10L) == sdm_block_id(389L, 59L, 10L) &&
        sdm_block_id(390L, 57L, 10L) != sdm_block_id(389L, 57L, 10L))
  # 5. Boyce, AUC, OR10
  all <- seq(0, 1, length.out = 1001)
  add("5a Boyce: presence density that rises with the value gives about 1",
      sdm_boyce(rep(all, times = round(all * 20)), all) > 0.99)
  add("5b Boyce: presence density that falls with the value gives about -1",
      sdm_boyce(rep(all, times = round((1 - all) * 20)), all) < -0.99)
  # Ties of P/E are kept (no removal of repeated values): presences in the
  # top 15 % only give many windows with P/E = 0, and the index is 0.65,
  # not 1.
  add("5f Boyce: presences in the top 15 % only give 0.65 (ties kept)",
      abs(sdm_boyce(seq(0.85, 1, length.out = 30), all) - 0.654) < 0.01)
  add("5c Boyce: presences spread as all cells give no index (P/E constant)",
      is.na(sdm_boyce(all, all)))
  add("5d AUC: 1, 0 and 0.5 (a tie)",
      sdm_auc(c(3, 4), c(1, 2)) == 1 && sdm_auc(c(1, 2), c(3, 4)) == 0 &&
        sdm_auc(1, 1) == 0.5)
  add("5e OR10: training 1..10 (10th percentile 1.9), test 1, 2, 3 -> 1/3",
      near(sdm_or10(1:10, c(1, 2, 3)), 1 / 3))
  # 6. comparison
  cm1 <- sdm_compare(1:100, 1:100, 1:100, 0.2, 0.9, 2 / 3)
  cm2 <- sdm_compare(1:100, 100:1, 1:100, 0.2, 0.9, 2 / 3)
  add("6a the same prediction: rho 1, overlap 1, robust",
      near(cm1$rho, 1) && near(cm1$top_overlap, 1) && cm1$label == "robust")
  add("6b the reverse prediction: rho -1, overlap 0, sensitive",
      near(cm2$rho, -1) && near(cm2$top_overlap, 0) &&
        cm2$label == "sensitive")
  # 7. model object check
  obj <- list(a = 1:5, b = list(c = matrix(0, 5, 2)))
  add("7a an object with a part of the data length fails the check",
      !sdm_object_ok(obj, 5) && sdm_object_ok(obj, 10))
  # 8. one maxnet fit on the example data of the package (not project data)
  ex <- new.env()
  utils::data("bradypus", package = "maxnet", envir = ex)
  bp <- ex$bradypus
  pp <- bp$presence
  dd <- bp[, c("cld6190_ann", "h_dem", "pre6190_ann")]
  g <- tryCatch(sdm_aicc_grid(pp, dd, dd, which(pp == 1), "lq", 1),
                error = function(e) NULL)
  add("8a maxnet fits and gets an AICc on the package example data",
      !is.null(g) && g$table$status == "fitted" && is.finite(g$table$aicc))
  data.frame(check = names(chk), pass = unlist(chk), row.names = NULL,
             stringsAsFactors = FALSE)
}

# =============================================================================
# Task 14.6 — STEP 14.3: the QA (process choices c1, m1, h1, p1, s1). A
# second path for the main numbers: these functions do not call the sdm_*
# functions of STEPs 14.1 and 14.2. The tolerances are SDM_QA_REL_TOL and
# SDM_QA_DEG_TOL (R/00_config.R).
# =============================================================================

# The records whose point (any CRS) is not in the 0.2 degree cell of its
# stored south-west corner. The point goes to EPSG:4326 (CRS_WGS84); the cell
# is widened by tol degrees on each side (the round trip of the projection).
# Returns the number of such records (a record with no point counts).
sdm_qa_corner_fail <- function(x, corner_lon, corner_lat, deg = SDM_GRAIN_DEG,
                               tol = SDM_QA_DEG_TOL) {
  g  <- sf::st_transform(sf::st_geometry(x), CRS_WGS84)
  xy <- sf::st_coordinates(g)
  if (nrow(xy) != length(corner_lon)) {
    stop("sdm_qa_corner_fail(): one point per record is needed.",
         call. = FALSE)
  }
  bad <- is.na(xy[, 1]) | is.na(xy[, 2]) | is.na(corner_lon) |
    is.na(corner_lat) |
    xy[, 1] < corner_lon - tol | xy[, 1] > corner_lon + deg + tol |
    xy[, 2] < corner_lat - tol | xy[, 2] > corner_lat + deg + tol
  sum(bad)
}

# A text key "ix_iy" of a 0.2 degree cell from its south-west corner
# (the corner is a whole multiple of deg; round() takes away the float error).
sdm_qa_key <- function(corner_lon, corner_lat, deg = SDM_GRAIN_DEG) {
  paste(round(corner_lon / deg), round(corner_lat / deg), sep = "_")
}

# The covariates of the cells `ids` by terra::zonal() on the cell-id raster
# (Decision 24 points 1 and 2; implementation point 1). Same columns as
# sdm_covariates(), computed with sums of masked layers.
sdm_qa_zonal <- function(stack_r, cellid_r, settl_r, ids,
                         lc_groups = SDM_LC_GROUPS,
                         water_class = SDM_WATER_CLASS,
                         elev_min = SDM_ELEV_MIN_M,
                         terrain = SDM_TERRAIN_BANDS) {
  zsum <- function(x) {
    z <- terra::zonal(x, cellid_r, fun = "sum", na.rm = TRUE)
    as.numeric(z[[2]][match(ids, z[[1]])])
  }
  lc    <- stack_r[["landcover"]]
  one   <- terra::ifel(is.na(cellid_r), NA, 1)
  water <- terra::ifel(lc == water_class, 1, 0)
  land  <- 1 - water
  n_cc    <- zsum(one)
  n_water <- zsum(water)
  w_only  <- n_water == n_cc
  out <- data.frame(id = ids, n_cc = n_cc)
  out$ghm_mean      <- zsum(stack_r[["ghm"]]) / n_cc
  out$droad_km_mean <- zsum(stack_r[["dist_road_m"]]) / 1000 / n_cc
  for (g in names(lc_groups)) {
    out[[g]] <- zsum(terra::ifel(lc %in% lc_groups[[g]], 1, 0)) / n_cc
  }
  elev    <- stack_r[["elev"]]
  low     <- terra::ifel(elev < elev_min, 1, 0)
  elev_f  <- terra::ifel(elev < elev_min, elev_min, elev)
  for (b in terrain) {
    x <- if (b == "elev") elev_f else stack_r[[b]]
    m_land <- zsum(x * land) / (n_cc - n_water)
    m_all  <- zsum(x) / n_cc
    out[[paste0(b, "_mean")]] <- ifelse(w_only, m_all, m_land)
  }
  out$settl_mean      <- zsum(settl_r) / n_cc
  out$z1_water_excl   <- ifelse(w_only, 0, n_water)
  out$z1_elev_floored <- ifelse(w_only, zsum(low), zsum(low * land))
  out$water_only      <- w_only
  out
}

# The largest difference of a and b, relative to max(1, |b|). Inf if the
# lengths differ or a value is NA in one of them only.
sdm_qa_diff <- function(a, b) {
  a <- as.numeric(a)
  b <- as.numeric(b)
  if (length(a) != length(b)) return(Inf)
  if (any(is.na(a) != is.na(b))) return(Inf)
  ok <- !is.na(a)
  if (!any(ok)) return(0)
  max(abs(a[ok] - b[ok]) / pmax(1, abs(b[ok])))
}

# The collinearity rule again (Decision 24 point 3): the candidates kept, from
# the correlation matrix of the table.
sdm_qa_kept <- function(x, priority = SDM_COV_PRIORITY, r_max = SDM_COR_MAX) {
  cm <- abs(stats::cor(as.matrix(x[, priority, drop = FALSE])))
  keep <- logical(length(priority))
  names(keep) <- priority
  for (i in seq_along(priority)) {
    prior <- priority[keep]
    keep[i] <- length(prior) == 0 || max(cm[priority[i], prior]) <= r_max
  }
  priority[keep]
}

# AICc again (Decision 24 point 4): raw = the raw output over all model
# cells, pres_rows = the rows of the presence cells, k = the coefficients.
sdm_qa_aicc <- function(raw, pres_rows, k) {
  n <- length(pres_rows)
  if (k + 1 >= n) return(NA_real_)
  ll <- sum(log(raw[pres_rows])) - n * log(sum(raw))
  -2 * ll + 2 * k + (2 * k * (k + 1)) / (n - k - 1)
}

# The AICc selection again (point 4): within delta (strictly below), the
# fewest coefficients, then the lower AICc, then the first row. Returns the
# row number.
sdm_qa_select <- function(aicc, k, delta = SDM_AICC_DELTA) {
  d <- aicc - min(aicc, na.rm = TRUE)
  rows <- which(!is.na(d) & d < delta)
  rows <- rows[k[rows] == min(k[rows])]
  rows <- rows[aicc[rows] == min(aicc[rows])]
  rows[1]
}

# AUC from the Wilcoxon rank-sum statistic (a tie counts 1/2).
sdm_qa_auc <- function(pres, bg) {
  w <- suppressWarnings(stats::wilcox.test(pres, bg, exact = FALSE))$statistic
  as.numeric(w) / (length(pres) * length(bg))
}

# The largest part of an object at any depth: the length of a vector, the
# rows of a matrix, a data frame or an S4 matrix. (A second walker for the
# check of Decision 24 point 11.)
sdm_qa_largest_part <- function(obj) {
  if (is.data.frame(obj)) {
    return(max(nrow(obj), vapply(obj, sdm_qa_largest_part, numeric(1))))
  }
  if (is.list(obj)) {
    return(max(length(obj), vapply(obj, sdm_qa_largest_part, numeric(1))))
  }
  d <- dim(obj)
  if (!is.null(d)) return(as.numeric(d[1]))
  if (is.environment(obj) || is.function(obj) || is.language(obj)) return(0)
  as.numeric(length(obj))
}

# The number of values of a table that are a cell id of the grid: whole
# numbers in a number column, and runs of digits in a text column (commas
# between digits are taken out first).
sdm_qa_id_hits <- function(tbl, ids) {
  hits <- 0
  for (col in names(tbl)) {
    v <- tbl[[col]]
    if (is.numeric(v)) {
      w <- v[!is.na(v) & v == round(v)]
      hits <- hits + sum(w %in% ids)
    } else if (is.character(v) || is.factor(v)) {
      txt <- gsub("(?<=[0-9]),(?=[0-9])", "", as.character(v), perl = TRUE)
      nums <- unlist(regmatches(txt, gregexpr("[0-9]+", txt)))
      hits <- hits + sum(suppressWarnings(as.numeric(nums)) %in% ids)
    }
  }
  hits
}

# The number of reserve names (or reserve columns) in a table: a text value
# that is a reserve name (case and spaces not counted), or a column named
# unit_id, unit_name or reserve*.
sdm_qa_reserve_hits <- function(tbl, reserve_names) {
  norm <- function(x) tolower(gsub("[[:space:]]+", " ", trimws(x)))
  rn <- norm(reserve_names[!is.na(reserve_names) & nzchar(reserve_names)])
  hits <- sum(grepl("^(unit_id|unit_name|reserve.*)$", tolower(names(tbl))))
  for (col in names(tbl)) {
    v <- tbl[[col]]
    if (is.character(v) || is.factor(v)) {
      hits <- hits + sum(norm(as.character(v)) %in% rn)
    }
  }
  hits
}

# ---- STEP 14.3: the hand-made case of the QA functions (process choice h1) ---------
sdm_self_test_143 <- function() {
  chk <- list()
  add <- function(name, ok) chk[[name]] <<- isTRUE(ok)
  near <- function(a, b) isTRUE(all.equal(as.numeric(a), b, tolerance = 1e-9))
  # 1. The zonal path on the grid of sdm_self_test_142() (model cell 1: cells
  #    1-3, one water cell; model cell 2: cells 4-5, water only).
  tmpl <- terra::rast(nrows = 2, ncols = 3, xmin = 0, xmax = 3000, ymin = 0,
                      ymax = 2000, crs = paste0("EPSG:", CRS_ANALYSIS))
  mk <- function(v) { r <- tmpl; terra::values(r) <- v; r }
  stk <- c(mk(c(10, 80, 40, 80, 80, NA)), mk(c(0.2, 0.4, 0.6, 0.1, 0.3, NA)),
           mk(c(100, -50, 200, -20, 30, NA)), mk(c(2, 9, 4, 1, 3, NA)),
           mk(c(10, 90, 30, 5, 15, NA)),
           mk(c(1000, 2000, 3000, 500, 1500, NA)))
  names(stk) <- c("landcover", "ghm", "elev", "slope", "tri", "dist_road_m")
  cid <- mk(c(1L, 1L, 1L, 2L, 2L, NA))
  stl <- mk(c(0.1, 0.2, 0.3, 0.4, 0.5, NA))
  z <- sdm_qa_zonal(stk, cid, stl, c(1L, 2L))
  z1 <- z[z$id == 1, ]
  z2 <- z[z$id == 2, ]
  add("1a zonal: terrain means without water (elev 150, slope 3, TRI 20)",
      near(z1$elev_mean, 150) && near(z1$slope_mean, 3) &&
        near(z1$tri_mean, 20))
  add("1b zonal: gHM 0.4, road 2 km, settlement 0.2, n_cc 3 and 2",
      near(z1$ghm_mean, 0.4) && near(z1$droad_km_mean, 2) &&
        near(z1$settl_mean, 0.2) && z1$n_cc == 3 && z2$n_cc == 2)
  add("1c zonal: shares forest 1/3, crop 1/3, open 0, built 0",
      near(z1$lc_forest, 1 / 3) && near(z1$lc_crop, 1 / 3) &&
        near(z1$lc_open, 0) && near(z1$lc_built, 0))
  add("1d zonal: water-only cell (elev 15, slope 2, TRI 10)",
      isTRUE(z2$water_only) && near(z2$elev_mean, 15) &&
        near(z2$slope_mean, 2) && near(z2$tri_mean, 10))
  add("1e zonal: z1 counts (1 water cell out; 1 elevation floored)",
      z1$z1_water_excl == 1 && z2$z1_water_excl == 0 &&
        z1$z1_elev_floored == 0 && z2$z1_elev_floored == 1)
  # 2. Corner check and key (a point on an edge, a point just inside)
  pts <- sf::st_sfc(sf::st_point(c(77.0, 11.6)),
                    sf::st_point(c(77.0 - 1e-9, 11.7)),
                    sf::st_point(c(77.1, 11.9)), crs = CRS_WGS84)
  pts <- sf::st_transform(pts, CRS_ANALYSIS)
  add("2a corner check: 3 points in their cells (an edge point within tol)",
      sdm_qa_corner_fail(pts, c(77.0, 77.0, 77.0), c(11.6, 11.6, 11.8)) == 0)
  add("2b corner check: a wrong corner (0.2 degrees off) is found",
      sdm_qa_corner_fail(pts, c(77.0, 77.0, 77.2), c(11.6, 11.6, 11.8)) == 1)
  add("2c key: 77.0 / 11.6 is 385_58",
      identical(sdm_qa_key(77.0, 11.6), "385_58"))
  # 3. Collinearity, AICc, selection, AUC
  x1 <- 1:20
  tst <- data.frame(x2 = x1 + rep(c(0.1, -0.1), 10), x1 = x1,
                    x3 = rep(c(1, 5), 10))
  add("3a kept: x2 and x3 (x1 has |r| > 0.7 with x2)",
      identical(sdm_qa_kept(tst, c("x2", "x1", "x3"), 0.7), c("x2", "x3")))
  # raw 1, 1, 2, 4 (sum 8); presences rows 3, 4, 4, 4 -> LL = log(2/8) +
  # 3 log(4/8); k = 1, n = 4: AICc = -2 LL + 2 + 4 / 2
  add("3b AICc of a hand case: -2(log 0.25 + 3 log 0.5) + 2 + 2",
      near(sdm_qa_aicc(c(1, 1, 2, 4), c(3, 4, 4, 4), 1),
           -2 * (log(0.25) + 3 * log(0.5)) + 4) &&
        is.na(sdm_qa_aicc(c(1, 1, 2, 4), c(3, 4), 1)))
  add("3c selection: within 2, the fewest coefficients (row 2)",
      sdm_qa_select(c(100, 100.2, 103, 101.5), c(10, 5, 3, 5)) == 2)
  add("3d AUC (Wilcoxon): 1, 0 and 0.5",
      near(sdm_qa_auc(c(3, 4), c(1, 2)), 1) &&
        near(sdm_qa_auc(c(1, 2), c(3, 4)), 0) && near(sdm_qa_auc(1, 1), 0.5))
  # 4. The walker of the model object
  n <- 50
  ok_obj  <- list(a = 1:10, b = list(c = matrix(0, 5, 3), d = "x"))
  bad_vec <- list(a = 1:10, b = list(c = rep(0, n)))
  bad_mat <- list(m = matrix(0, n, 2))
  bad_df  <- list(s = list(t = data.frame(v = seq_len(n))))
  add("4a walker: a small object passes; a vector, matrix or data frame of n fails",
      sdm_qa_largest_part(ok_obj) < n && sdm_qa_largest_part(bad_vec) >= n &&
        sdm_qa_largest_part(bad_mat) >= n && sdm_qa_largest_part(bad_df) >= n)
  # 5. The value scans
  ids <- c(3800385L, 4200390L)
  add("5a id scan: a number column and a text column with an id are found",
      sdm_qa_id_hits(data.frame(a = c(1, 3800385), b = "x"), ids) == 1 &&
        sdm_qa_id_hits(data.frame(b = "cell 4,200,390"), ids) == 1 &&
        sdm_qa_id_hits(data.frame(a = c(104, 1486), b = "6969 of 6969"),
                       ids) == 0)
  add("5b reserve scan: a name in a text column and a unit_name column are found",
      sdm_qa_reserve_hits(data.frame(a = c(" kanha", "x")), c("Kanha")) == 1 &&
        sdm_qa_reserve_hits(data.frame(unit_name = "x"), c("Kanha")) == 1 &&
        sdm_qa_reserve_hits(data.frame(a = "fold 1"), c("Kanha")) == 0)
  data.frame(check = names(chk), pass = unlist(chk), row.names = NULL,
             stringsAsFactors = FALSE)
}

# ---- Layers --------------------------------------------------------------------
# The field names and the EPSG code of a vector layer, from its first row
# only (no geometry is returned, so nothing of a position is kept).
sdm_read_fields <- function(path) {
  if (!file.exists(path)) stop("File not found: ", path, call. = FALSE)
  lyr <- sf::st_layers(path)$name
  if (length(lyr) != 1L) {
    stop("sdm_read_fields(): ", basename(path), " must hold one layer.",
         call. = FALSE)
  }
  x <- sf::st_read(path, query = sprintf('SELECT * FROM "%s" LIMIT 1', lyr),
                   quiet = TRUE)
  list(fields = setdiff(names(x), attr(x, "sf_column")),
       epsg   = sf::st_crs(x)$epsg)
}

# ---- Guards --------------------------------------------------------------------
# `checks` is a named list of TRUE/FALSE. A FALSE, an NA or a value that is
# not one TRUE/FALSE stops with the names of the failed checks. On success it
# returns the number of checks (invisibly). It prints nothing.
sdm_run_guards <- function(checks, what) {
  ok <- vapply(checks, function(v) isTRUE(v), logical(1))
  if (!all(ok)) {
    stop("Guard(s) failed for ", what, ":\n  ",
         paste(names(checks)[!ok], collapse = "\n  "), call. = FALSE)
  }
  invisible(length(checks))
}
