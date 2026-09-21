# =============================================================================
# 06_build_covariate_stack.R  [STAGE 2 — CONNECTIVITY, input assembly]
# Assemble ONE aligned, analysis-ready covariate raster stack on a single 1 km
# EPSG:7755 template, so the Week-9 resistance surface and the Week-13+ SDM read
# the identical grid.
#
# WEEK 8 SCOPE — ASSEMBLY AND ALIGNMENT ONLY.
#   This script resamples the existing Week-2 covariate layers onto one shared
#   template, derives distance-to-road, stacks the bands, and QA-checks the
#   result. It does NOT assign resistance values and does NOT choose barrier road
#   classes — both are Week-9 numbered Decisions. Do not pre-empt them here.
#     - WORLDCOVER_RESISTANCE (R/00_config.R) is a literature-informed STARTING
#       set, not a Decision. It is not applied in this script.
#     - The road-class set used for the distance-to-road COVARIATE (task 8.4) is
#       an inline choice recorded at that step; it is separate from the Week-9
#       barrier road-class Decision.
#
# INPUTS (as written by scripts/01, Week 2 — all 1 km EPSG:7755 where raster):
#   data/interim/cov_landcover_worldcover2021_1km_7755.tif   WorldCover 2021 modal
#                                                            class (CATEGORICAL)
#   data/interim/cov_ghm2022_1km_7755.tif                    gHM 2022, 0-1
#                                                            (CONTINUOUS)
#   data/interim/cov_terrain_1km_7755.tif                    3-band elevation /
#                                                            slope / tri (CONT.)
#   data/raw/osm/osm_roads_major_7755.gpkg                   OSM major roads
#                                                            (lines) for 8.4
#   data/processed/boundary_reserves_all_7755.gpkg           reserves (context /
#                                                            later QA)
#   data/processed/boundary_states_7755.gpkg                 states (context)
#   data/interim/boundary_india_national_7755.gpkg           national clip frame
#                                                            (template extent)
#   NOTE: the Week-2 covariate rasters were written to data/interim/ by
#   scripts/01 (its `bound_dir`), NOT data/processed/. This script reads them
#   from interim and writes the ASSEMBLED stack to data/processed/.
#
# OUTPUTS:
#   data/processed/cov_stack_1km_7755.tif   multi-band stack, bands (task 8.5):
#                                             landcover, ghm, elev, slope, tri,
#                                             dist_road_m
#   data/interim/cov_distroad_1km_7755.tif  distance-to-road covariate (task 8.4)
#   outputs/tables/tbl_10_covariate_stack_qa.csv   per-band QA (task 8.6)
#     (Output table numbers are their own sequence, independent of the script
#      prefix — naming-conventions §6. tbl_10 is the next free number.)
#
# METHOD NOTES (why alignment is done ONE way here):
#   - ONE TEMPLATE, RESAMPLE EVERYTHING TO IT. The India-extent 1 km EPSG:7755
#     template is defined ONCE (task 8.2) and every layer is aligned to it. Do
#     not resample layers to each other pairwise — that drifts bands by a cell
#     and fails compareGeom() at stack time.
#   - CATEGORICAL vs CONTINUOUS resampling. WorldCover is a CLASS raster ->
#     NEAREST (read_rast(..., categorical = TRUE)). gHM and terrain are
#     continuous -> BILINEAR. Bilinear on a class raster invents fractional
#     land-cover codes; nearest on a continuous layer needlessly steps it.
#   - GRID_CELL_M from config, never a hardcoded 1000 (task 8.2).
#   - Settlements are NOT stacked here. The OSM settlement layer is
#     village-dominated (~195k of 199,800); a distance/density-to-settlement
#     covariate needs the trim Decision (Week 8-9 pending) FIRST. Only roads feed
#     task 8.4 this week.
#
# MACHINE TRAP (must clear before any reprojection):
#   PROJ / PostGIS proj.db clash on this build machine makes every reprojection
#   to EPSG:7755 fail with `empty srs` / `cannot get output boundaries`. The
#   .Rprofile pins PROJ_LIB to terra's bundled proj.db BEFORE terra loads. In a
#   FRESH session, confirm the CRS engine is healthy before running the rest:
#     crs(rast(crs = "EPSG:7755"))   # must print the "India NSF LCC" WKT
#   Setting PROJ_LIB after terra is already loaded does NOT take (PROJ caches the
#   path at first use). See docs/handoff.md "Known gotchas".
#
# Run in order after scripts/01-05. Reads config + IO helpers; sources nothing
# else. Writes the stack + QA only; does not modify any Week-2 layer or the
# Stage-1 stats layer.
# =============================================================================

# ---- Prerequisites ----------------------------------------------------------
suppressPackageStartupMessages({
  library(here)
  library(terra)     # raster assembly / alignment / distance
  library(sf)        # boundaries + road lines
  library(dplyr)     # QA table assembly
})

source(here("R", "00_config.R"))        # CRS_ANALYSIS, GRID_CELL_M, DIR_*
source(here("R", "00_functions_io.R"))  # read_vec, read_rast, write_processed_rast, write_table

rule <- function(txt) cat("\n", strrep("=", 78), "\n", txt, "\n",
                          strrep("=", 78), "\n", sep = "")

# ---- Paths ------------------------------------------------------------------
# Inputs (Week-2 covariate rasters live in data/interim; boundaries in processed)
lc_in       <- file.path(DIR_INTERIM,   "cov_landcover_worldcover2021_1km_7755.tif")
ghm_in      <- file.path(DIR_INTERIM,   "cov_ghm2022_1km_7755.tif")
terr_in     <- file.path(DIR_INTERIM,   "cov_terrain_1km_7755.tif")
roads_in    <- file.path(DIR_RAW,       "osm", "osm_roads_major_7755.gpkg")
india_in    <- file.path(DIR_INTERIM,   "boundary_india_national_7755.gpkg")
reserves_in <- file.path(DIR_PROCESSED, "boundary_reserves_all_7755.gpkg")
states_in   <- file.path(DIR_PROCESSED, "boundary_states_7755.gpkg")

# Outputs
distroad_out <- file.path(DIR_INTERIM,   "cov_distroad_1km_7755.tif")
stack_out    <- file.path(DIR_PROCESSED, "cov_stack_1km_7755.tif")
# QA table via write_table(nn = 10, slug = "covariate_stack_qa")

# Documented band order for the stack (task 8.5). Fixed here so every later
# script indexes bands by a stable name, never by position.
STACK_BANDS <- c("landcover", "ghm", "elev", "slope", "tri", "dist_road_m")

# Template collar: metres added around the India boundary before snapping the
# grid, so edge cells and a coastal/border distance-to-road (task 8.4) are not
# clipped at the national outline. Matches the 5 km collar scripts/01 used for
# its Week-2 layers (it hardcoded 5000 inline four times). Named here rather
# than repeated as a literal; migrate to R/00_config.R if a second Stage-2
# script needs the same collar.
COLLAR_M <- 5000

# ---- Config + CRS guards (fail early, before any heavy read) ----------------
# 1) Grid cell comes from config, not a literal.
stopifnot(is.numeric(GRID_CELL_M), GRID_CELL_M > 0)

# 2) The analysis CRS must actually resolve in this session. If the PROJ proj.db
#    clash is active this line prints an empty/again-wrong WKT; stop here rather
#    than fail deep inside a reprojection.
crs_wkt <- terra::crs(terra::rast(crs = paste0("EPSG:", CRS_ANALYSIS)))
if (!nzchar(crs_wkt) || !grepl("India", crs_wkt)) {
  stop("EPSG:", CRS_ANALYSIS, " did not resolve to the India NSF LCC frame. ",
       "The PROJ proj.db clash is likely active — restart R so .Rprofile pins ",
       "PROJ_LIB before terra loads, then re-run. See docs/handoff.md.",
       call. = FALSE)
}

# 3) Every declared input must exist before we start.
inputs <- c(lc_in, ghm_in, terr_in, roads_in, india_in, reserves_in, states_in)
missing_inputs <- inputs[!file.exists(inputs)]
if (length(missing_inputs) > 0) {
  stop("Missing required input(s):\n  ", paste(missing_inputs, collapse = "\n  "),
       "\nRun scripts/01 (covariates + OSM) and scripts/02 (boundaries) first.",
       call. = FALSE)
}

rule("06_build_covariate_stack.R — inputs found; CRS OK. Ready for Week-8 build.")

# =============================================================================
# STEP 8.2 — define the ONE 1 km EPSG:7755 analysis template
# =============================================================================
# The single grid every covariate is resampled onto (task 8.3+). Built ONCE from
# the national boundary and held in memory as `tmpl` for reuse. An empty terra
# template (no values) is enough for resample()/project()/distance() targets.
#
# Construction (why it is snapped to a clean origin):
#   1. Read the national boundary in EPSG:7755 (read_vec reprojects if needed).
#   2. Buffer by COLLAR_M so edge/border cells are not clipped.
#   3. SNAP the extent OUT to whole multiples of GRID_CELL_M — floor xmin/ymin,
#      ceil xmax/ymax. This gives round-number cell edges and makes the template
#      reproducible from the boundary ALONE, independent of whatever bbox origin
#      scripts/01 happened to pick for its Week-2 layers. Every layer is
#      resampled onto this grid in 8.3 regardless, so a fractional-cell offset
#      from the Week-2 origin is corrected there, not carried.
#   4. Build an empty 1 km raster on that snapped extent at CRS_ANALYSIS.
#
# NOTE (alignment): because the origin is snapped here, the Week-2 interim layers
# are NOT guaranteed cell-for-cell coincident with `tmpl`. That is expected —
# 8.3 resample()s each onto `tmpl`. compareGeom() in 8.3 is asserted AFTER the
# resample (against the template), not before it.

rule("STEP 8.2 — build the 1 km EPSG:7755 analysis template")

india_sf <- read_vec(india_in)                       # national frame, EPSG:7755
stopifnot(sf::st_crs(india_sf)$epsg == CRS_ANALYSIS)

india_buf <- sf::st_buffer(india_sf, COLLAR_M)
bb        <- sf::st_bbox(india_buf)

# Snap the extent OUT to whole multiples of GRID_CELL_M (clean grid edges).
snap_lo <- function(v) floor(v / GRID_CELL_M) * GRID_CELL_M
snap_hi <- function(v) ceiling(v / GRID_CELL_M) * GRID_CELL_M
tmpl_ext <- terra::ext(
  snap_lo(bb[["xmin"]]), snap_hi(bb[["xmax"]]),
  snap_lo(bb[["ymin"]]), snap_hi(bb[["ymax"]])
)

# Empty 1 km template on the snapped extent, in the analysis CRS.
tmpl <- terra::rast(
  extent     = tmpl_ext,
  resolution = GRID_CELL_M,
  crs        = paste0("EPSG:", CRS_ANALYSIS)
)

# ---- Assert extent / res / CRS once (fail loud if any is wrong) --------------
# terra::ext() returns an S4 SpatExtent, which is NOT subsettable with ["xmin"].
# Coerce to a named numeric vector first (names: xmin, xmax, ymin, ymax).
res_m   <- terra::res(tmpl)
code    <- terra::crs(tmpl, describe = TRUE)$code
ext_vec <- as.vector(terra::ext(tmpl))               # named numeric, length 4
ext_ok  <- all(ext_vec %% GRID_CELL_M == 0)
stopifnot(
  "template resolution must be GRID_CELL_M in both directions" =
    isTRUE(all.equal(res_m, c(GRID_CELL_M, GRID_CELL_M))),
  "template CRS must be the analysis CRS" =
    identical(as.character(code), as.character(CRS_ANALYSIS)),
  "template extent must snap to whole GRID_CELL_M" = ext_ok
)

cat("template dims (r x c):", paste(dim(tmpl)[1:2], collapse = " x "),
    "=", format(terra::ncell(tmpl), big.mark = ","), "cells\n")
cat("resolution (m):", paste(res_m, collapse = " x "),
    "| EPSG:", code, "| collar:", COLLAR_M, "m\n")
cat("extent (m) [xmin xmax ymin ymax]:",
    paste(round(ext_vec[c("xmin", "xmax", "ymin", "ymax")]), collapse = " / "),
    "\n")
cat("(all extent values are multiples of", GRID_CELL_M, ")\n")

# `tmpl` is now the canonical grid. Every layer in 8.3+ resamples ONTO it.
# It is held in memory for reuse; not written to disk (an empty template needs
# no persistence — 8.3-8.5 consume it directly, and the stack it produces is the
# on-disk record of the grid).

# =============================================================================
# STEP 8.3 — align existing covariates to the template
# =============================================================================
# Put all three Week-2 covariate layers onto the identical grid `tmpl` (8.2).
#
# Why NOT read_rast() here:
#   read_rast() reprojects to the CRS on an AUTO-computed grid, not onto `tmpl`.
#   These inputs are ALREADY EPSG:7755 at 1 km (scripts/01), so the operation we
#   need is a RESAMPLE onto the template (match origin + extent), not a
#   reprojection. Reprojecting an already-7755 layer would interpolate it onto
#   some other grid, and we would still have to resample onto `tmpl` after —
#   two interpolations, and a categorical layer stepped twice. So this step
#   loads with terra::rast() and aligns with ONE interpolation each.
#
# align_to_tmpl(): resample when the input is already in the analysis CRS (the
#   expected case); fall back to project-onto-template if an input is somehow
#   NOT 7755 (CRS + grid in one interpolation). Either way the OUTPUT grid is
#   `tmpl`. Method: "near" for categorical (WorldCover), "bilinear" for
#   continuous (gHM, terrain) — bilinear on a class raster invents fractional
#   codes; nearest on a continuous layer needlessly steps it.

rule("STEP 8.3 — align covariates to the template (WorldCover near; gHM/terrain bilinear)")

align_to_tmpl <- function(path, method, template = tmpl) {
  r <- terra::rast(path)
  in_code <- terra::crs(r, describe = TRUE)$code
  if (identical(as.character(in_code), as.character(CRS_ANALYSIS))) {
    out <- terra::resample(r, template, method = method)   # same CRS -> resample
  } else {
    warning(basename(path), " is EPSG:", in_code, ", not the analysis CRS ",
            CRS_ANALYSIS, " — projecting onto the template instead of resampling.")
    out <- terra::project(r, template, method = method)    # CRS + grid in one
  }
  names(out) <- names(r)                                    # keep source names
  out
}

# ---- WorldCover 2021 — CATEGORICAL -> nearest -------------------------------
lc_1km <- align_to_tmpl(lc_in, method = "near")

# ---- gHM 2022 — CONTINUOUS -> bilinear -------------------------------------
ghm_1km <- align_to_tmpl(ghm_in, method = "bilinear")

# ---- Terrain (elevation / slope / tri) — CONTINUOUS -> bilinear ------------
# Multi-band; resample() applies the one method to every band, which is correct
# here (all three terrain bands are continuous).
terr_1km <- align_to_tmpl(terr_in, method = "bilinear")

# ---- Re-assert each result against the template (silent-mismatch guard) ------
# compareGeom() stops on any extent / resolution / CRS / row-col mismatch, so a
# drifted layer fails HERE, not silently at stack time (8.5).
for (nm in c("lc_1km", "ghm_1km", "terr_1km")) {
  r <- get(nm)
  ok <- terra::compareGeom(r, tmpl, stopOnError = FALSE,
                           crs = TRUE, ext = TRUE, rowcol = TRUE, res = TRUE)
  if (!isTRUE(ok)) {
    stop(nm, " does not match the template grid after alignment — ",
         "inspect the source layer's CRS/extent.", call. = FALSE)
  }
}

cat("aligned to template (", format(terra::ncell(tmpl), big.mark = ","),
    " cells each):\n", sep = "")
cat("  WorldCover : band", paste(names(lc_1km), collapse = "/"),
    "| method near (categorical)\n")
cat("  gHM        : band", paste(names(ghm_1km), collapse = "/"),
    "| method bilinear\n")
cat("  terrain    : bands", paste(names(terr_1km), collapse = "/"),
    "| method bilinear\n")
cat("compareGeom vs template: PASS for all three\n")

# =============================================================================
# STEP 8.4 — derive distance-to-road on the template grid
# =============================================================================
# Build cov_distroad_1km_7755.tif: metres from each cell to the nearest major
# road. This is the CONTINUOUS distance COVARIATE for the SDM / connectivity
# context. It is NOT the resistance/barrier surface — the barrier road-class
# choice is a Week-9 numbered Decision and is not made here.
#
# INLINE road-class choice (covariate only, recorded per task 8.4):
#   Use ALL FIVE major highway classes already in osm_roads_major_7755.gpkg —
#   motorway, trunk, primary, secondary, tertiary (+ their _link ramps).
#   Rationale: scripts/01 already filtered OSM to these major classes
#   (residential/track/path excluded), so the layer is the right footprint for a
#   general "distance to a road of consequence" covariate. Tertiary is KEPT here
#   on purpose — whether tertiary counts as a movement BARRIER is the separate
#   Week-9 Decision; trimming it now would pre-empt that. If a future revision
#   wants distance-to-(secondary+), filter `highway` here, but do it as its own
#   recorded change, not as part of Week 9.
#
# METHOD — rasterize then distance (fast idiom):
#   terra::distance() can measure cell -> line-vector distance directly, but over
#   ~886k lines x ~8.86M cells that is very slow. Instead: rasterize the roads
#   onto `tmpl` (cells a road touches = 1, else NA), then terra::distance() on
#   that raster returns, for every NA cell, the distance to the nearest non-NA
#   cell — i.e. distance to the nearest road cell. At 1 km this is the same
#   covariate far more cheaply. touches = TRUE so a thin line between two cell
#   centres still marks a cell.
#
# Distance is computed on the FULL template (collar included) so border/coastal
# cells get a true nearest-road distance, then masked to India for the covariate.

rule("STEP 8.4 — distance-to-road covariate (rasterize -> distance)")

ROAD_CLASSES <- c("motorway", "trunk", "primary", "secondary", "tertiary",
                  "motorway_link", "trunk_link", "primary_link",
                  "secondary_link", "tertiary_link")   # inline set (see note)

roads_sf <- read_vec(roads_in)                          # lines, EPSG:7755
stopifnot(sf::st_crs(roads_sf)$epsg == CRS_ANALYSIS)

# Keep only the inline class set (defensive: the layer is already major-only,
# but this makes the covariate's class basis explicit and self-documenting).
roads_sf <- roads_sf[roads_sf$highway %in% ROAD_CLASSES, ]
cat("road features used:", format(nrow(roads_sf), big.mark = ","),
    "across", length(unique(roads_sf$highway)), "classes\n")

# Rasterize onto the template (road-touched cell = 1, else NA), then distance.
roads_v  <- terra::vect(roads_sf)
road_ras <- terra::rasterize(roads_v, tmpl, field = 1, touches = TRUE)
dist_full <- terra::distance(road_ras)                  # metres to nearest road cell
names(dist_full) <- "dist_road_m"

# Mask to India (covariate footprint matches the other layers).
dist_road <- terra::mask(dist_full, terra::vect(india_sf))

# Assert grid match, then write the interim covariate.
if (!isTRUE(terra::compareGeom(dist_road, tmpl, stopOnError = FALSE,
                               crs = TRUE, ext = TRUE, rowcol = TRUE, res = TRUE))) {
  stop("dist_road does not match the template grid.", call. = FALSE)
}
write_processed_rast(dist_road, basename(distroad_out), dir = dirname(distroad_out))

# Report -----------------------------------------------------------------------
dmm <- terra::minmax(dist_road)
cat("distance-to-road (m), inside India: min", round(dmm[1]),
    "| max", round(dmm[2]), "\n")
cat("mean (m):", round(terra::global(dist_road, "mean", na.rm = TRUE)[[1]]), "\n")
# Sanity: min should be 0 (cells on a road); max is the remotest cell from any
# major road (large but finite). An all-NA or 0-max result means the rasterize
# missed the lines — flag.
if (is.na(dmm[2]) || dmm[2] <= 0) {
  warning("distance-to-road max is 0 or NA — the road rasterize likely failed.")
}

# =============================================================================
# STEP 8.5 — stack the aligned layers -> cov_stack_1km_7755.tif
# =============================================================================
# Combine the six aligned single-purpose layers into one multi-band GeoTIFF with
# the stable band order STACK_BANDS. Every later Stage-2/3 script indexes bands
# by name from this order.
#
# Band order (from the aligned layers built above):
#   landcover  <- lc_1km    (worldcover_2021, categorical)
#   ghm        <- ghm_1km   (ghm_2022,        0-1)
#   elev       <- terr_1km$elevation
#   slope      <- terr_1km$slope
#   tri        <- terr_1km$tri
#   dist_road_m<- dist_road (metres)
#
# CROSS-BAND NA-MASK POLICY (recorded choice):
#   COMMON MASK — a cell is kept only where ALL SIX bands are non-NA; if any band
#   is NA in a cell, the whole cell is set NA across every band. This yields a
#   complete-case design matrix: every retained cell has a full covariate vector,
#   which is what the Week-9 resistance surface and the Week-13+ maxnet SDM need
#   (neither should see a partial row). The alternative — leaving per-band NAs —
#   would maximise per-band coverage but push ragged-NA handling downstream. The
#   bands already share the India mask (8.3/8.4); the common mask only trims the
#   few edge/coast cells where bilinear vs nearest disagree by a cell.

rule("STEP 8.5 — assemble cov_stack_1km_7755.tif (six bands, common NA mask)")

# Assemble in the documented order, then rename to STACK_BANDS.
cov_stack <- c(
  lc_1km,                 # worldcover_2021
  ghm_1km,                # ghm_2022
  terr_1km[["elevation"]],
  terr_1km[["slope"]],
  terr_1km[["tri"]],
  dist_road               # dist_road_m
)
names(cov_stack) <- STACK_BANDS
stopifnot(
  "stack must have one band per STACK_BANDS entry" =
    terra::nlyr(cov_stack) == length(STACK_BANDS),
  "band names must equal STACK_BANDS in order" =
    identical(names(cov_stack), STACK_BANDS)
)

# ---- Common NA mask: any band NA -> all bands NA ----------------------------
# Per-band valid-cell counts BEFORE the common mask (for the report / QA).
n_valid_before <- terra::global(!is.na(cov_stack), "sum", na.rm = TRUE)[[1]]
names(n_valid_before) <- STACK_BANDS

# A cell is complete iff every band is non-NA. sum(is.na(...)) across layers == 0.
# is.na() is the base generic; terra provides the SpatRaster method, so call it
# unqualified (terra::is.na is not an exported symbol).
na_count  <- sum(is.na(cov_stack))              # per-cell count of NA bands
keep_mask <- na_count == 0                      # 1 where complete, else 0
cov_stack <- terra::mask(cov_stack, keep_mask, maskvalues = c(0, NA))

# Valid-cell count AFTER (identical across bands now, by construction).
n_valid_after <- terra::global(!is.na(cov_stack[[1]]), "sum", na.rm = TRUE)[[1]]

cat("common NA mask applied. Complete-case cells:",
    format(n_valid_after, big.mark = ","),
    "of", format(terra::ncell(cov_stack), big.mark = ","), "template cells\n")
cat("cells dropped per band by the common mask (was -> now", n_valid_after, "):\n")
for (b in STACK_BANDS) {
  cat(sprintf("  %-12s valid before %s  (dropped %s)\n",
              b, format(n_valid_before[[b]], big.mark = ","),
              format(n_valid_before[[b]] - n_valid_after, big.mark = ",")))
}

# ---- Final grid assertion + write -------------------------------------------
if (!isTRUE(terra::compareGeom(cov_stack, tmpl, stopOnError = FALSE,
                               crs = TRUE, ext = TRUE, rowcol = TRUE, res = TRUE))) {
  stop("cov_stack does not match the template grid before write.", call. = FALSE)
}
write_processed_rast(cov_stack, basename(stack_out), dir = dirname(stack_out))
cat("\nwrote", terra::nlyr(cov_stack), "-band stack:",
    paste(names(cov_stack), collapse = ", "), "\n")

# =============================================================================
# STEP 8.6 — QA -> tbl_10_covariate_stack_qa.csv
# =============================================================================
# Per-band QA for the assembled stack:
#   - coverage: valid (non-NA) cells and % of the India-clipped area
#   - range:    min / max (sanity vs the known physical range of each covariate)
#   - spot-check: the stacked band's mean vs the SOURCE Week-2 interim layer's
#     mean over the SAME complete-case cells. Alignment (8.3/8.4) resamples but
#     must not corrupt values, so a stacked mean should sit very close to the
#     source mean. WorldCover is categorical -> compare modal class + class count
#     instead of a mean.
#
# Coverage note carried into the table: gHM is the binding NA layer. It has a
# slightly smaller valid footprint than WorldCover/terrain (windowed 300 m COG
# read, coastal/edge + small interior gaps), so the common mask (8.5) trims every
# band to gHM's extent — ~56.8k cells, ~1.8% of the otherwise-covered area. This
# is the recorded cost of the complete-case policy, not an error.

rule("STEP 8.6 — covariate stack QA -> tbl_10")

# India-clipped denominator: cells inside the national polygon on this grid.
# (Full India footprint, BEFORE the common mask — so pct_of_india shows each
# band's coverage against the whole country, and the common-mask trim is visible
# as gHM/others sitting below 100%.)
india_ones  <- terra::mask(terra::init(tmpl, 1), terra::vect(india_sf))
india_cells <- terra::global(!is.na(india_ones), "sum", na.rm = TRUE)[[1]]

# Physical sanity ranges per band (min_ok, max_ok) — used only to flag, not clip.
sane <- list(
  landcover   = c(10, 100),      # WorldCover class codes
  ghm         = c(0, 1),         # 0-1 index
  elev        = c(-500, 9000),   # metres (India: coastal lows to Himalaya)
  slope       = c(0, 90),        # degrees
  tri         = c(0, 2000),      # ruggedness index (1 km-aggregated)
  dist_road_m = c(0, 1e6)        # metres
)

# Source interim layers for the spot-check (same objects, pre-common-mask).
src <- list(
  landcover   = lc_1km,
  ghm         = ghm_1km,
  elev        = terr_1km[["elevation"]],
  slope       = terr_1km[["slope"]],
  tri         = terr_1km[["tri"]],
  dist_road_m = dist_road
)

qa_rows <- lapply(STACK_BANDS, function(b) {
  band <- cov_stack[[b]]
  n_valid <- terra::global(!is.na(band), "sum", na.rm = TRUE)[[1]]
  mm      <- terra::minmax(band)
  rng_ok  <- !is.na(mm[1]) && !is.na(mm[2]) &&
             mm[1] >= sane[[b]][1] && mm[2] <= sane[[b]][2]

  if (b == "landcover") {
    # categorical: modal class over the stack + number of classes present
    freq   <- terra::freq(band)
    modal  <- freq$value[which.max(freq$count)]
    stat_stack  <- sprintf("modal=%s; n_class=%d", modal, nrow(freq))
    stat_source <- {
      fs <- terra::freq(src[[b]])
      sprintf("modal=%s; n_class=%d", fs$value[which.max(fs$count)], nrow(fs))
    }
  } else {
    # continuous: mean over the stack band vs mean over the source layer,
    # each on its own valid cells (source is pre-common-mask, so expect a small
    # difference from the ~1.8% trim, not a large one).
    m_stack  <- terra::global(band,     "mean", na.rm = TRUE)[[1]]
    m_source <- terra::global(src[[b]], "mean", na.rm = TRUE)[[1]]
    stat_stack  <- sprintf("mean=%.3f", m_stack)
    stat_source <- sprintf("mean=%.3f", m_source)
  }

  data.frame(
    band          = b,
    n_valid       = n_valid,
    pct_of_india  = round(100 * n_valid / india_cells, 2),
    min           = round(mm[1], 3),
    max           = round(mm[2], 3),
    range_ok      = rng_ok,
    stack_stat    = stat_stack,
    source_stat   = stat_source,
    stringsAsFactors = FALSE
  )
})
qa <- do.call(rbind, qa_rows)

# ---- Hard-stop guards on the QA result --------------------------------------
if (any(qa$n_valid == 0)) {
  stop("QA: an all-NA band exists — ", paste(qa$band[qa$n_valid == 0],
       collapse = ", "), call. = FALSE)
}
if (any(!qa$range_ok)) {
  warning("QA: band(s) outside the sane physical range: ",
          paste(qa$band[!qa$range_ok], collapse = ", "),
          " — inspect before using the stack.")
}

print(qa, row.names = FALSE)
write_table(qa, nn = 10, slug = "covariate_stack_qa")

rule("Week 8 build complete: cov_stack_1km_7755.tif + tbl_10 written. Stack is Stage-2 ready.")
