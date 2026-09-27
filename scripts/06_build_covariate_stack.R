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
# WEEK 9 ADDITION — STEP 8.4b, the Decision-11 gHM gap-fill.
#   The Week-9 relevance check (scripts/07 STEP 9.2, pre-fill) TRIGGERED, so
#   the fill fixed in Decision 11 applies. STEP 8.4b fills NA gHM cells with an
#   iterative focal mean BEFORE stacking, only where the other five bands have
#   values. It runs when GHM_GAP_FILL is TRUE in R/00_config.R and records the
#   filled-cell count in tbl_10 (n_filled). This script stays the ONLY writer
#   of cov_stack_1km_7755.tif.
#
# WEEK 9 ADDITION — Decision 12, land cover from the UNMASKED tile cache.
#   scripts/01 masked WorldCover to India on ITS OWN grid. Resampling that
#   masked layer onto the snapped template shifted the class edge by about one
#   cell: 1,791 cells outside India kept a class and 1,778 India cells had none.
#   STEP 8.3 now merges the 88 unmasked 1 km tiles that scripts/01 cached,
#   resamples them (nearest) onto the template, and masks to India ON THE
#   TEMPLATE — the same India mask as dist_road_m. A guard stops the script if
#   any India cell that had a class before changes or loses it. The aligned,
#   India-masked land cover is also written to data/interim for scripts/07.
#
# WEEK 9 ADDITION — Decision 13, terrain from the UNMASKED raw DEM.
#   The scripts/01 terrain layer has the same one-cell edge shift (it was masked
#   on the scripts/01 grid). STEP 8.3 now repeats the scripts/01 terrain path
#   from the cached raw DEM — slope and TRI on the native DEM, bilinear
#   projection onto the scripts/01 grid — WITHOUT the India mask, then resamples
#   onto the template and masks to India ON THE TEMPLATE. Interior guard: cells
#   whose 5 x 5 neighbourhood lies wholly inside India must match the Week-8
#   values within TERR_GUARD_TOL, or the build stops. Edge changes are reported.
#   gHM is now the ONLY band still masked on the scripts/01 grid (no local copy
#   of the gHM source exists); the Decision-11 fill covers its edge cells.
#
# WEEK 9 FIX — the stack file was written as INT1U (2026-09-26).
#   A GeoTIFF holds one data type for all bands; writeRaster() chose unsigned
#   8-bit, so on disk gHM and dist_road_m were 0 and elev/TRI were cut to 0-254.
#   tbl_10 was computed in memory before the write and did not see it. The stack
#   is now written as FLT4S, the aligned land cover as INT2U, and every write is
#   read back and verified (R/00_functions_io.R, write_processed_rast()).
#
# BUILD_TAG labels this build in tbl_10; scripts/07 names its STEP-9.2 outputs
#   "postfill_<BUILD_TAG>". Change it only when a new source Decision changes
#   what the stack is built from.
#
# INPUTS (as written by scripts/01, Week 2 — all 1 km EPSG:7755 where raster):
#   data/raw/worldcover/tiles_1km/N??E???_1km_7755.tif       88 UNMASKED 1 km
#                                                            WorldCover tiles
#                                                            (CATEGORICAL; the
#                                                            land-cover source
#                                                            from Decision 12)
#   data/interim/cov_landcover_worldcover2021_1km_7755.tif   the scripts/01 masked
#                                                            WorldCover layer —
#                                                            now read ONLY for
#                                                            the Decision-12 guard
#   data/interim/cov_ghm2022_1km_7755.tif                    gHM 2022, 0-1
#                                                            (CONTINUOUS)
#   data/raw/terrain/dem_india_aws_z7_4326.tif               raw DEM, UNMASKED
#                                                            (India + 5 km; the
#                                                            terrain source from
#                                                            Decision 13)
#   data/interim/cov_terrain_1km_7755.tif                    the scripts/01 masked
#                                                            3-band terrain —
#                                                            now read ONLY for
#                                                            the Decision-13 guard
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
#   data/interim/cov_landcover_worldcover2021_aligned_1km_7755.tif
#                                           land cover on the template, masked to
#                                           India, BEFORE the common mask
#                                           (Decision 12; read by scripts/07)
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
#     NEAREST (terra::resample(method = "near"), STEP 8.3 — read_rast() is NOT
#     used here; see the STEP 8.3 note). gHM and terrain are continuous ->
#     BILINEAR. Bilinear on a class raster invents fractional
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
wc_tile_dir <- file.path(DIR_RAW,       "worldcover", "tiles_1km")
ghm_in      <- file.path(DIR_INTERIM,   "cov_ghm2022_1km_7755.tif")
terr_in     <- file.path(DIR_INTERIM,   "cov_terrain_1km_7755.tif")
dem_in      <- file.path(DIR_RAW,       "terrain", "dem_india_aws_z7_4326.tif")
roads_in    <- file.path(DIR_RAW,       "osm", "osm_roads_major_7755.gpkg")
india_in    <- file.path(DIR_INTERIM,   "boundary_india_national_7755.gpkg")
reserves_in <- file.path(DIR_PROCESSED, "boundary_reserves_all_7755.gpkg")
states_in   <- file.path(DIR_PROCESSED, "boundary_states_7755.gpkg")

# Outputs
distroad_out <- file.path(DIR_INTERIM,   "cov_distroad_1km_7755.tif")
lc_aligned_out <- file.path(DIR_INTERIM,
                            "cov_landcover_worldcover2021_aligned_1km_7755.tif")
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

# Decision 13: the terrain rebuild repeats scripts/01 Block 7, which built its
# grid from the India boundary + a 5000 m buffer. COLLAR_M must equal that value
# or the rebuilt terrain will not reproduce the Week-8 interior values.
stopifnot("COLLAR_M must equal the 5000 m buffer scripts/01 used" = COLLAR_M == 5000)

# Decision 13 interior guard tolerance (same units as each terrain band). The
# Week-8 interim terrain was stored as 32-bit float; recomputed values are
# 64-bit, so exact equality is not expected. 0.01 is far above float32 rounding
# (~0.0005 m at 8,000 m) and far below any real change.
TERR_GUARD_TOL <- 0.01

# Label for this build (see the header note). "d13f" = Decisions 12 + 13 + the
# FLT4S write fix. scripts/07 labels its re-check "postfill_d13f".
BUILD_TAG <- "d13f"   # d13 + the FLT4S write fix (2026-09-26)

# ---- Config + CRS guards (fail early, before any heavy read) ----------------
# 1) Grid cell comes from config, not a literal.
stopifnot(is.numeric(GRID_CELL_M), GRID_CELL_M > 0)

# 1b) Decision-11 fill switch and parameters come from config.
fill_params <- c("GHM_GAP_FILL", "GAP_FILL_WINDOW", "GAP_FILL_MAX_ITER")
missing_fill <- fill_params[!vapply(fill_params, exists, logical(1))]
if (length(missing_fill) > 0) {
  stop("Decision-11 setting(s) missing from R/00_config.R: ",
       paste(missing_fill, collapse = ", "), call. = FALSE)
}
stopifnot(
  "GHM_GAP_FILL must be TRUE or FALSE" = isTRUE(GHM_GAP_FILL) || isFALSE(GHM_GAP_FILL),
  "GAP_FILL_WINDOW must be an odd integer >= 3" =
    GAP_FILL_WINDOW >= 3 && GAP_FILL_WINDOW %% 2 == 1,
  "GAP_FILL_MAX_ITER must be >= 1" = GAP_FILL_MAX_ITER >= 1
)

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
inputs <- c(lc_in, wc_tile_dir, ghm_in, terr_in, dem_in, roads_in, india_in,
            reserves_in,
            states_in)
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

# `src` is a file path or an in-memory SpatRaster (the merged tile cache).
align_to_tmpl <- function(src, method, template = tmpl) {
  r <- if (inherits(src, "SpatRaster")) src else terra::rast(src)
  src_label <- if (inherits(src, "SpatRaster")) "in-memory raster" else basename(src)
  in_code <- terra::crs(r, describe = TRUE)$code
  if (identical(as.character(in_code), as.character(CRS_ANALYSIS))) {
    out <- terra::resample(r, template, method = method)   # same CRS -> resample
  } else {
    warning(src_label, " is EPSG:", in_code, ", not the analysis CRS ",
            CRS_ANALYSIS, " — projecting onto the template instead of resampling.")
    out <- terra::project(r, template, method = method)    # CRS + grid in one
  }
  names(out) <- names(r)                                    # keep source names
  out
}

# India mask ON THE TEMPLATE (cell-centre rule, the same terra::mask() rule that
# STEP 8.4 uses for dist_road_m). 1 inside India, NA outside.
india_tmpl <- terra::mask(terra::init(tmpl, 1), terra::vect(india_sf))

# ---- WorldCover 2021 — CATEGORICAL -> nearest (Decision 12) ------------------
# Merge the unmasked 1 km tiles that scripts/01 Block 4 cached, in the SAME order
# scripts/01 used (longitude, then latitude — as.vector(outer(lat, lon))), so
# the "first value wins" rule of terra::merge() gives the same value in any
# overlapping edge cell. Then resample (nearest) onto the template and mask to
# India on the template.
wc_tiles <- list.files(wc_tile_dir, pattern = "^N[0-9]{2}E[0-9]{3}_1km_7755\\.tif$",
                       full.names = TRUE)
if (length(wc_tiles) == 0) {
  stop("No WorldCover 1 km tiles in ", wc_tile_dir,
       " — re-run scripts/01 Block 4 to rebuild the tile cache.", call. = FALSE)
}
tile_id  <- sub("_1km_7755\\.tif$", "", basename(wc_tiles))
tile_lat <- as.integer(substr(tile_id, 2, 3))
tile_lon <- as.integer(substr(tile_id, 5, 7))
wc_tiles <- wc_tiles[order(tile_lon, tile_lat)]
cat("WorldCover tile cache:", length(wc_tiles), "tiles\n")

wc_pieces <- lapply(wc_tiles, terra::rast)
wc_merged <- if (length(wc_pieces) > 1) {
  terra::merge(terra::sprc(wc_pieces))
} else wc_pieces[[1]]
lc_1km <- align_to_tmpl(wc_merged, method = "near")
lc_1km <- terra::mask(lc_1km, india_tmpl)
names(lc_1km) <- "worldcover_2021"
# Drop the colour table inherited from the WorldCover tiles. A multi-band FLT4S
# GeoTIFF cannot store it; writeRaster() warned and dropped it anyway (values
# unaffected). Removing it here keeps the run free of warnings that could hide
# a real one.
terra::coltab(lc_1km) <- NULL

# ---- Decision-12 guard: interior classes unchanged, no class lost ------------
# The scripts/01 masked layer, aligned the Week-8 way. Inside India, every cell
# that had a class there must have the SAME class here. Cells that gain a class
# (the ~1-cell edge offset) are the expected change and are reported.
lc_old <- terra::mask(align_to_tmpl(lc_in, method = "near"), india_tmpl)
n_diff <- terra::global(lc_old != lc_1km, "sum", na.rm = TRUE)[[1]]
n_lost <- terra::global(!is.na(lc_old) & is.na(lc_1km), "sum", na.rm = TRUE)[[1]]
if (!isTRUE(n_diff == 0) || !isTRUE(n_lost == 0)) {
  stop("Decision-12 guard: the tile-cache land cover differs from the ",
       "scripts/01 layer inside India (", n_diff, " cells with another class, ",
       n_lost, " cells that lost a class). Nothing is written. Inspect the tile ",
       "cache and the merge order.", call. = FALSE)
}
n_india_tmpl <- terra::global(india_tmpl, "sum", na.rm = TRUE)[[1]]
n_lc_old  <- terra::global(!is.na(lc_old), "sum", na.rm = TRUE)[[1]]
n_lc_new  <- terra::global(!is.na(lc_1km), "sum", na.rm = TRUE)[[1]]
cat("Decision-12 guard PASS: no interior class changed or lost.\n")
cat("India cells with a land-cover class: before", format(n_lc_old, big.mark = ","),
    "-> now", format(n_lc_new, big.mark = ","), "of",
    format(n_india_tmpl, big.mark = ","), "| still without a class:",
    format(n_india_tmpl - n_lc_new, big.mark = ","), "\n")
rm(wc_pieces, wc_merged, lc_old)

# Aligned, India-masked land cover BEFORE the common mask (read by scripts/07).
write_processed_rast(lc_1km, basename(lc_aligned_out), dir = dirname(lc_aligned_out),
                     datatype = "INT2U")   # class codes 10-100; integer by design
cat("\n")

# ---- gHM 2022 — CONTINUOUS -> bilinear -------------------------------------
ghm_1km <- align_to_tmpl(ghm_in, method = "bilinear")

# ---- Terrain (elevation / slope / tri) — CONTINUOUS -> bilinear (Decision 13)
# Repeat scripts/01 Block 7 exactly, minus its India mask:
#   1. slope (degrees) and TRI on the NATIVE DEM (deriving after a coarsen would
#      understate ruggedness — same reason as scripts/01);
#   2. project all three onto the scripts/01 grid (India + COLLAR_M, 1 km),
#      bilinear — the same first interpolation scripts/01 did;
#   3. resample onto the template (bilinear) — the same second interpolation the
#      Week-8 build did;
#   4. mask to India ON THE TEMPLATE (india_tmpl, as for land cover).
# Steps 1-3 match the Week-8 path, so interior values must match (guard below).
dem_ll <- terra::rast(dem_in)
names(dem_ll) <- "elevation"
slope_ll <- terra::terrain(dem_ll, v = "slope", unit = "degrees")
tri_ll   <- terra::terrain(dem_ll, v = "TRI")
tmpl01 <- terra::rast(terra::vect(sf::st_buffer(india_sf, COLLAR_M)),
                      resolution = GRID_CELL_M)
terr01 <- c(terra::project(dem_ll,   tmpl01, method = "bilinear"),
            terra::project(slope_ll, tmpl01, method = "bilinear"),
            terra::project(tri_ll,   tmpl01, method = "bilinear"))
names(terr01) <- c("elevation", "slope", "tri")
terr_1km <- terra::mask(align_to_tmpl(terr01, method = "bilinear"), india_tmpl)
names(terr_1km) <- c("elevation", "slope", "tri")

# ---- Decision-13 guard: interior terrain unchanged ---------------------------
# "Core" cells: the 5 x 5 neighbourhood on the template lies wholly inside India
# (focal sum of the India mask = 25). Both builds draw on source cells that are
# all inside India there, so values must agree within TERR_GUARD_TOL. Nearer the
# edge the old build could lose or change a value (its source was masked on the
# scripts/01 grid); those cells are the expected change and are only reported.
terr_old <- terra::mask(align_to_tmpl(terr_in, method = "bilinear"), india_tmpl)
names(terr_old) <- c("elevation", "slope", "tri")
core_sum <- terra::focal(india_tmpl, w = 5, fun = "sum", na.rm = FALSE)
core_r   <- terra::ifel(core_sum == 25, 1, NA)
india_edge_r <- terra::ifel(is.na(core_r) & !is.na(india_tmpl), 1, NA)

terr_guard <- lapply(c("elevation", "slope", "tri"), function(b) {
  d_abs   <- abs(terr_1km[[b]] - terr_old[[b]])
  d_core  <- terra::mask(d_abs, core_r)
  max_core <- terra::global(d_core, "max", na.rm = TRUE)[[1]]
  lost_core <- terra::global(terra::mask(!is.na(terr_old[[b]]) & is.na(terr_1km[[b]]),
                                         core_r), "sum", na.rm = TRUE)[[1]]
  gained_edge <- terra::global(terra::mask(is.na(terr_old[[b]]) & !is.na(terr_1km[[b]]),
                                           india_edge_r), "sum", na.rm = TRUE)[[1]]
  changed_edge <- terra::global(terra::mask(d_abs > TERR_GUARD_TOL, india_edge_r),
                                "sum", na.rm = TRUE)[[1]]
  data.frame(band = b, max_abs_diff_core = max_core, lost_core = lost_core,
             gained_edge = gained_edge, changed_edge = changed_edge)
})
terr_guard <- do.call(rbind, terr_guard)
print(terr_guard, row.names = FALSE)
if (any(is.na(terr_guard$max_abs_diff_core)) ||
    any(terr_guard$max_abs_diff_core > TERR_GUARD_TOL) ||
    any(terr_guard$lost_core > 0)) {
  stop("Decision-13 guard: the rebuilt terrain differs from the Week-8 terrain ",
       "in interior (core) cells beyond ", TERR_GUARD_TOL, ", or lost core ",
       "values. Nothing is written. Inspect the scripts/01 path reproduction.",
       call. = FALSE)
}
n_terr_old <- terra::global(!is.na(terr_old[["elevation"]]), "sum", na.rm = TRUE)[[1]]
n_terr_new <- terra::global(!is.na(terr_1km[["elevation"]]), "sum", na.rm = TRUE)[[1]]
cat("Decision-13 guard PASS: interior terrain unchanged (max core difference",
    format(max(terr_guard$max_abs_diff_core), digits = 3), ").\n")
cat("India cells with terrain: before", format(n_terr_old, big.mark = ","),
    "-> now", format(n_terr_new, big.mark = ","), "of",
    format(n_india_tmpl, big.mark = ","), "\n\n")
rm(dem_ll, slope_ll, tri_ll, terr01, terr_old, core_sum)

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
write_processed_rast(dist_road, basename(distroad_out), dir = dirname(distroad_out),
                     datatype = "FLT4S")

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
# STEP 8.4b — Decision-11 gHM gap-fill (Week 9; runs when GHM_GAP_FILL is TRUE)
# =============================================================================
# Method (fixed in Decision 11 BEFORE the relevance check was run):
#   - fill a NA gHM cell with the mean of the valid gHM cells in its
#     GAP_FILL_WINDOW x GAP_FILL_WINDOW neighbourhood; NA cells only
#     (terra::focal na.policy = "only", na.rm = TRUE);
#   - repeat up to GAP_FILL_MAX_ITER passes, so no filled cell is more than
#     GAP_FILL_MAX_ITER cells (km) from real gHM data;
#   - fill ONLY cells where the other five bands have values ("eligible"). A
#     value computed for an ineligible cell is set back to NA in the same pass,
#     so the fill never spreads through ineligible cells (outside India, or
#     where another band is NA);
#   - cells still NA after the last pass stay NA (the common mask in 8.5 then
#     removes them).
#   Water cells (WorldCover 80) are filled too when they are eligible — Decision
#   11 fills by eligibility, not by class. Resistance for water comes from land
#   cover (task 9.3), not from gHM.
# ghm_prefill keeps the unfilled layer for the QA spot-check (STEP 8.6).

rule("STEP 8.4b — Decision-11 gHM gap-fill")

ghm_prefill <- ghm_1km
n_filled    <- 0

if (isTRUE(GHM_GAP_FILL)) {
  eligible <- !is.na(lc_1km) & !is.na(terr_1km[["elevation"]]) &
    !is.na(terr_1km[["slope"]]) & !is.na(terr_1km[["tri"]]) & !is.na(dist_road)
  w_fill <- matrix(1, nrow = GAP_FILL_WINDOW, ncol = GAP_FILL_WINDOW)

  ghm_work <- ghm_1km
  for (k in seq_len(GAP_FILL_MAX_ITER)) {
    ghm_next <- terra::focal(ghm_work, w = w_fill, fun = "mean",
                             na.policy = "only", na.rm = TRUE)
    # Keep new values only in eligible cells.
    ghm_next <- terra::ifel(is.na(ghm_work) & !eligible, NA, ghm_next)
    n_new <- terra::global(is.na(ghm_work) & !is.na(ghm_next), "sum",
                           na.rm = TRUE)[[1]]
    ghm_work <- ghm_next
    cat(sprintf("  pass %d: %s cells filled\n", k, format(n_new, big.mark = ",")))
    if (n_new == 0) break
  }

  # Guards: real gHM values unchanged; filled values inside the 0-1 domain.
  n_changed <- terra::global(ghm_work != ghm_prefill, "sum", na.rm = TRUE)[[1]]
  if (!isTRUE(n_changed == 0)) {
    stop("gap-fill changed ", n_changed, " cells that already had gHM values.",
         call. = FALSE)
  }
  fmm <- terra::minmax(ghm_work)
  if (fmm[1] < 0 || fmm[2] > 1) {
    stop("gap-filled gHM falls outside 0-1 (", round(fmm[1], 3), " to ",
         round(fmm[2], 3), ").", call. = FALSE)
  }

  n_filled <- terra::global(is.na(ghm_prefill) & !is.na(ghm_work), "sum",
                            na.rm = TRUE)[[1]]
  n_still  <- terra::global(eligible & is.na(ghm_work), "sum",
                            na.rm = TRUE)[[1]]
  names(ghm_work) <- names(ghm_1km)
  ghm_1km <- ghm_work
  cat("gHM cells filled:", format(n_filled, big.mark = ","),
      "| eligible cells still NA after", GAP_FILL_MAX_ITER, "passes:",
      format(n_still, big.mark = ","), "\n")
} else {
  cat("GHM_GAP_FILL is FALSE — no fill (pre-Decision-11 behaviour).\n")
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
#   bands already share the India mask (8.3/8.4), but they do NOT share one
#   valid footprint: gHM (windowed 300 m COG read, scripts/01 Block 5) has a
#   smaller valid extent along the coast/border and at small interior gaps. gHM
#   is therefore the BINDING NA layer, and the common mask trims every band to
#   its footprint: 56,827 India-grid cells (1.85%) were lost in the Week-8
#   build, BEFORE the Decision-11 fill (STEP 8.4b); after the fill the loss is
#   smaller and gHM may no longer be the binding layer. The exact
#   per-band counts go to tbl_10 (n_valid_before, n_dropped_by_mask; STEP 8.6).
#   The India-footprint loss is the dist_road_m row's n_dropped_by_mask, because
#   dist_road_m is masked to India exactly (STEP 8.4).
#   Recorded as Decision 10; the gHM gap-fill question is Week 9.

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
# FLT4S for ALL six bands (one GeoTIFF = one data type). Land-cover class codes
# stay exact in 32-bit float. write_processed_rast() reads the file back and
# stops if any band's mean or NA count differs from the in-memory stack.
write_processed_rast(cov_stack, basename(stack_out), dir = dirname(stack_out),
                     datatype = "FLT4S")
cat("\nwrote", terra::nlyr(cov_stack), "-band stack:",
    paste(names(cov_stack), collapse = ", "), "\n")

# =============================================================================
# STEP 8.6 — QA -> tbl_10_covariate_stack_qa.csv
# =============================================================================
# Per-band QA for the assembled stack:
#   - fill: n_filled = gHM cells filled by the Decision-11 fill (STEP 8.4b);
#     0 for every other band, and 0 for gHM when GHM_GAP_FILL is FALSE.
#     n_valid_before for gHM is AFTER the fill (the fill runs before stacking).
#     scripts/07 reads n_filled to label its outputs pre-fill / post-fill.
#   - lc_source: where this build's land cover came from — "tile_cache" since
#     Decision 12 (the same value on every row).
#   - terrain_source: where this build's terrain came from — "raw_dem" since
#     Decision 13 (same value on every row).
#   - build_tag: BUILD_TAG (same value on every row). scripts/07 names its
#     STEP-9.2 outputs "postfill_<build_tag>", so a re-check after a source
#     change never overwrites the earlier result.
#   - coverage: valid (non-NA) cells BEFORE the common mask (n_valid_before,
#     from STEP 8.5), the cells the mask removed (n_dropped_by_mask), and the
#     valid cells AFTER the mask (n_valid) with its % of the India-clipped area.
#     These columns are the saved record of the Decision-10 coverage cost — the
#     figures in docs are read from here, not from the console.
#     NOTE (corrected 2026-09-26): landcover (Decision 12), terrain (Decision
#     13) and dist_road_m are masked to India ON THIS TEMPLATE, so their
#     n_valid_before is at most the India-grid count. gHM is the only band still
#     taken from a scripts/01 layer masked on the scripts/01 grid; the resample
#     shifts its edge by about one cell, so it can hold cells outside India
#     (removed by the common mask) and miss cells inside (covered by the
#     Decision-11 fill where eligible). Before Decisions 12/13 the same shift
#     gave landcover 1,791 cells outside India and 1,778 India cells without a
#     class (net +13), and terrain a net +20.
#   - range:    min / max (sanity vs the known physical range of each covariate)
#   - spot-check (gHM source = the UNFILLED layer, so after a fill the gHM
#     stack mean can differ slightly from the source mean by design):
#     the stacked band's mean vs the SOURCE Week-2 interim layer's
#     mean over the SAME complete-case cells. Alignment (8.3/8.4) resamples but
#     must not corrupt values, so a stacked mean should sit very close to the
#     source mean. WorldCover is categorical -> compare modal class + class count
#     instead of a mean.
#
# Coverage note carried into the table: gHM is the binding NA layer. It has a
# slightly smaller valid footprint than WorldCover/terrain (windowed 300 m COG
# read, coastal/edge + small interior gaps), so the common mask (8.5) trims every
# band to gHM's extent — 56,827 India-grid cells, 1.85%, as built. This
# is the recorded cost of the complete-case policy, not an error.

rule("STEP 8.6 — covariate stack QA -> tbl_10")

# India-clipped denominator: cells inside the national polygon on this grid.
# The denominator is the full India footprint, independent of any band. The
# numerator (n_valid) is the AFTER-mask count, which is equal for every band, so
# pct_of_india is the same on every row (98.15% as built in Week 8). The gap to
# 100% is the Decision-10 trim plus any cell no band covers; the per-band detail
# is in n_valid_before / n_dropped_by_mask.
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
  ghm         = ghm_prefill,     # unfilled source (spot-check vs the stack)
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
    # difference from the 1.85% trim, not a large one).
    m_stack  <- terra::global(band,     "mean", na.rm = TRUE)[[1]]
    m_source <- terra::global(src[[b]], "mean", na.rm = TRUE)[[1]]
    stat_stack  <- sprintf("mean=%.3f", m_stack)
    stat_source <- sprintf("mean=%.3f", m_source)
  }

  data.frame(
    band          = b,
    n_filled          = if (b == "ghm") as.numeric(n_filled) else 0,
    lc_source         = "tile_cache",   # Decision 12: land cover for this build
    terrain_source    = "raw_dem",      # Decision 13: terrain for this build
    build_tag         = BUILD_TAG,      # run label read by scripts/07
    n_valid_before    = as.numeric(n_valid_before[[b]]),
    n_dropped_by_mask = as.numeric(n_valid_before[[b]]) - n_valid,
    n_valid           = n_valid,
    pct_of_india      = round(100 * n_valid / india_cells, 2),
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
if (length(unique(qa$n_valid)) != 1L) {
  stop("QA: after-mask n_valid differs between bands — the common mask did not ",
       "apply to every band.", call. = FALSE)
}
if (any(qa$n_dropped_by_mask < 0)) {
  stop("QA: a band has more valid cells after the common mask than before.",
       call. = FALSE)
}
if (any(qa$n_valid == 0)) {
  stop("QA: an all-NA band exists — ", paste(qa$band[qa$n_valid == 0],
       collapse = ", "), call. = FALSE)
}
if (any(!qa$range_ok)) {
  warning("QA: band(s) outside the sane physical range: ",
          paste(qa$band[!qa$range_ok], collapse = ", "),
          " — inspect before using the stack.")
}

cat("India-grid cells (denominator for pct_of_india):",
    format(india_cells, big.mark = ","), "\n")
binding <- qa$band[which.min(qa$n_valid_before)]
cat("binding NA layer (fewest valid cells before the mask):", binding, "\n")
print(qa, row.names = FALSE)
write_table(qa, nn = 10, slug = "covariate_stack_qa")

rule("Week 8 build complete: cov_stack_1km_7755.tif + tbl_10 written. Stack is Stage-2 ready.")
