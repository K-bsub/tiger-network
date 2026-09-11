# =============================================================================
# 01_download_open_data.R
# Download scripted open datasets into data/raw/ and report counts / CRS / fields.
# data/raw/** is gitignored — nothing downloaded here is committed.
#
# This file covers the scripted open-data pulls (Week 2, task 2.4):
#   BLOCK 1  India national boundary (Natural Earth) — the clip frame
#   BLOCK 2  GBIF tiger occurrences (Panthera tigris, national bbox)
#   BLOCK 3  GBIF Mammalia target-group BACKGROUND (async; tiger excluded)
#   BLOCK 4  ESA WorldCover 2021 land cover (windowed COG read)
#   BLOCK 5  Global Human Modification 2022 (windowed COG read)
#   BLOCK 6  OSM roads (major) + settlements (India, Geofabrik via osmextract)
#   BLOCK 7  Terrain: elevation + slope + TRI (elevatr AWS tiles -> 1 km)
#   BLOCK 8  Admin boundaries: states (Natural Earth) + districts (DataMeet)
# Task 2.4 scripted pulls (1-6), task 2.5 terrain (7), task 2.6 admin (8, the
# scriptable part; ISFR + Singh & Sen remain manual browser downloads).
#
# terra is required for the raster blocks (4-5,7); osmextract for block 6;
# elevatr for block 7.
#
# CREDENTIALS: the two GBIF blocks call occ_download(), which needs
#   GBIF_USER / GBIF_PWD / GBIF_EMAIL in your USER .Renviron (never in the repo).
#   rgbif reads them automatically. Same account used for the Bay Area pulls.
#
# METHOD NOTES (why this differs from the Bay Area 01):
#   - Footprint is the national BBOX, then records are CLIPPED to the India
#     boundary on import (Decision this turn). Simpler than a GBIF WKT polygon
#     and avoids the winding / single-polygon / island problems.
#   - Background target group is MAMMALIA ONLY (not all vertebrates). Birds and
#     fish do not share the tiger's sampling bias, so they would model birder /
#     aquatic effort, not mammal-observer effort. See docs/methodology.md.
#   - This project is SDM, not occupancy, so the background is saved as clean
#     POINTS for KDE / target-group use in Week 13 — there is no unit x year
#     detection-history machinery here.
# =============================================================================

# Prerequisites ----------------------------------------------------------------
suppressPackageStartupMessages({
  library(here)
  library(sf)
  library(terra)           # raster blocks (WorldCover, gHM)
  library(dplyr)
  library(readr)
  library(rgbif)
  library(rnaturalearth)   # India national boundary (public domain)
  library(osmextract)      # block 6 — Geofabrik OSM extract
  library(elevatr)         # block 7 — AWS terrain tiles
})

source(here::here("R", "00_config.R"))        # CRS_ANALYSIS, CRS_WGS84, DIR_*
source(here::here("R", "00_functions_io.R"))  # read_vec, write_processed_vec

rule <- function(txt) cat("\n", strrep("=", 78), "\n", txt, "\n",
                          strrep("=", 78), "\n", sep = "")

# ==============================================================================
# BLOCK 1 — India national boundary (Natural Earth 1:10m) — the clip frame
# ==============================================================================
# Public-domain admin-0 boundary. Used to (a) derive the national bbox for the
# GBIF predicates and (b) clip pulled records to India on import. Saved to
# interim so later blocks and later scripts reuse the same frame.

rule("BLOCK 1 — India national boundary (Natural Earth)")

bound_dir  <- here::here("data", "interim")
dir.create(bound_dir, recursive = TRUE, showWarnings = FALSE)
india_out  <- file.path(bound_dir, "boundary_india_national_7755.gpkg")

if (!file.exists(india_out)) {
  india_ne <- rnaturalearth::ne_countries(
    country = "India", scale = "large", returnclass = "sf"
  )
  # Keep a single dissolved polygon; store in the analysis CRS.
  india_7755 <- india_ne |>
    st_make_valid() |>
    summarise(country = "India", .groups = "drop") |>
    st_transform(CRS_ANALYSIS)
  st_write(india_7755, india_out, delete_dsn = TRUE, quiet = TRUE)
}

india_7755 <- read_vec(india_out)                 # in CRS_ANALYSIS
india_ll   <- st_transform(india_7755, CRS_WGS84)  # GBIF works in lat/lon
bb         <- st_bbox(india_ll)

cat("India boundary loaded | CRS EPSG:", st_crs(india_7755)$epsg, "\n")
cat("national bbox (WGS84): xmin", round(bb[["xmin"]], 2),
    "ymin", round(bb[["ymin"]], 2),
    "xmax", round(bb[["xmax"]], 2),
    "ymax", round(bb[["ymax"]], 2), "\n")
cat("NOTE: bbox spans neighbouring countries + ocean; records are clipped to\n",
    "the India polygon on import (both blocks below).\n", sep = "")

# ==============================================================================
# BLOCK 2 — GBIF occurrences: Panthera tigris (national bbox -> clip to India)
# ==============================================================================
# Citable download via occ_download() -> produces a DOI (occ_search does not).
# Minimal server-side filtering on purpose: species + bbox + usable coords only.
# basisOfRecord / uncertainty / year are inspected and filtered later (Week 13).

rule("BLOCK 2 — GBIF tiger occurrences (submit / fetch / import)")

gbif_dir <- here::here("data", "raw", "gbif")
dir.create(gbif_dir, recursive = TRUE, showWarnings = FALSE)
key_file <- file.path(gbif_dir, "gbif_tiger_download_key.txt")
doi_file <- file.path(gbif_dir, "gbif_tiger_download_doi.txt")
occ_out  <- file.path(bound_dir, "occ_tiger_gbif_raw_7755.gpkg")

# Taxon key (resolve from name; do not hard-code the integer) ------------------
tiger_key <- name_backbone("Panthera tigris")$usageKey
stopifnot(!is.null(tiger_key))
cat("taxonKey — Panthera tigris:", tiger_key, "\n")

# Submit once; record key + DOI ------------------------------------------------
if (!file.exists(key_file)) {
  dl_key <- occ_download(
    pred("taxonKey", tiger_key),
    pred("hasCoordinate", TRUE),
    pred("hasGeospatialIssue", FALSE),
    pred_gte("decimalLatitude",  bb[["ymin"]]),
    pred_lte("decimalLatitude",  bb[["ymax"]]),
    pred_gte("decimalLongitude", bb[["xmin"]]),
    pred_lte("decimalLongitude", bb[["xmax"]]),
    format = "SIMPLE_CSV"
  )
  occ_download_wait(dl_key)                        # polls until GBIF is ready
  meta <- occ_download_meta(dl_key)
  writeLines(as.character(dl_key), key_file)
  writeLines(c(
    paste("DOI:", meta$doi),
    paste("Key:", meta$key),
    paste("Accessed:", Sys.Date()),
    paste0("Citation: GBIF.org (", Sys.Date(),
           ") GBIF Occurrence Download https://doi.org/", meta$doi)
  ), doi_file)
}

# Fetch (reuses the zip on re-run) + import ------------------------------------
dl_key <- readLines(key_file)[1]
if (!file.exists(file.path(gbif_dir, paste0(dl_key, ".zip")))) {
  occ_download_get(dl_key, path = gbif_dir, overwrite = TRUE)
}
tiger_raw <- occ_download_import(key = dl_key, path = gbif_dir)

cat("\nDOI recorded in", doi_file, "\n")
cat(readLines(doi_file), sep = "\n"); cat("\n")
cat("raw records pulled (bbox):", nrow(tiger_raw), "\n")

# Clip to the India polygon (bbox pulls neighbouring countries + ocean) --------
tiger_sf <- tiger_raw |>
  filter(!is.na(decimalLatitude), !is.na(decimalLongitude)) |>
  st_as_sf(coords = c("decimalLongitude", "decimalLatitude"),
           crs = CRS_WGS84, remove = FALSE) |>
  st_transform(CRS_ANALYSIS)

tiger_in <- tiger_sf[india_7755, ]                 # spatial filter: inside India
cat("records inside India polygon:", nrow(tiger_in),
    sprintf(" (%.0f%% of bbox pull)\n", 100 * nrow(tiger_in) / nrow(tiger_sf)))

# Save the clipped RAW points (cleaning is Week 13; keep everything for now) ----
keep_cols <- intersect(
  c("gbifID", "decimalLatitude", "decimalLongitude", "year", "basisOfRecord",
    "coordinateUncertaintyInMeters", "institutionCode", "datasetKey"),
  names(tiger_in)
)
tiger_in |>
  select(all_of(keep_cols)) |>
  write_processed_vec("occ_tiger_gbif_raw_7755.gpkg", dir = bound_dir)

# Pre-filtering report ---------------------------------------------------------
cat("\n--- basisOfRecord mix ---\n")
tiger_in |> st_drop_geometry() |> count(basisOfRecord, sort = TRUE) |> print()

cat("\n--- coordinateUncertaintyInMeters ---\n")
tiger_in |> st_drop_geometry() |>
  summarise(
    n            = n(),
    n_uncert_na  = sum(is.na(coordinateUncertaintyInMeters)),
    med_uncert_m = median(coordinateUncertaintyInMeters, na.rm = TRUE),
    p90_uncert_m = quantile(coordinateUncertaintyInMeters, 0.90, na.rm = TRUE)
  ) |> print()

cat("\n--- year range ---\n")
tiger_in |> st_drop_geometry() |>
  summarise(min_yr = min(year, na.rm = TRUE),
            max_yr = max(year, na.rm = TRUE)) |> print()

# ==============================================================================
# BLOCK 3 — GBIF Mammalia target-group BACKGROUND (async; tiger excluded)
# ==============================================================================
# Sampling-effort proxy for the SDM (Week 13/14). Target group = ALL Mammalia
# (shared observer bias with tigers), 2006-2022, national bbox -> clip to India,
# tiger excluded. Saved as clean POINTS with class/year for KDE + target-group
# background. NOT a unit x year detection history (this project is SDM).
#
# TWO-PART async:
#   PART A submits the download (records the key), then continues to Part B.
#   PART B waits for READY, imports leanly (5 cols), clips, writes.
# On re-run, Part A sees the key file and skips straight to Part B.

rule("BLOCK 3 — GBIF Mammalia background (submit / wait / lean import)")

# Parameters -------------------------------------------------------------------
YR_MIN <- BASELINE_YEAR   # 2006  (matches the census span)
YR_MAX <- CURRENT_YEAR    # 2022

bg_dir   <- here::here("data", "raw", "gbif_background")
dir.create(bg_dir, recursive = TRUE, showWarnings = FALSE)
bg_key   <- file.path(bg_dir, "background_download_key.txt")
bg_doi   <- file.path(bg_dir, "background_download_doi.txt")
bg_out   <- file.path(bound_dir, "effort_background_tgs_7755.gpkg")

# Mammalia class key + tiger species key (resolve, don't hard-code) ------------
mammal_key <- name_backbone("Mammalia")$usageKey
tiger_spk  <- name_backbone("Panthera tigris")$speciesKey %||%
              name_backbone("Panthera tigris")$usageKey
cat("classKey — Mammalia:", mammal_key, "| speciesKey — tiger:", tiger_spk, "\n")

# ---- PART A: submit ----------------------------------------------------------
if (!file.exists(bg_key)) {
  dl <- occ_download(
    pred("taxonKey", mammal_key),                 # all Mammalia
    pred("hasCoordinate", TRUE),
    pred("hasGeospatialIssue", FALSE),
    pred_gte("year", YR_MIN),
    pred_lte("year", YR_MAX),
    pred_gte("decimalLatitude",  bb[["ymin"]]),
    pred_lte("decimalLatitude",  bb[["ymax"]]),
    pred_gte("decimalLongitude", bb[["xmin"]]),
    pred_lte("decimalLongitude", bb[["xmax"]]),
    pred_not(pred("speciesKey", tiger_spk)),      # exclude the focal species
    format = "SIMPLE_CSV"
  )
  writeLines(as.character(dl), bg_key)
  cat("submitted. key:", as.character(dl), "\n")
  cat(">>> large async download; Part B will wait for it to finish.\n")
} else {
  cat("background key already exists:", readLines(bg_key)[1], "\n")
  cat("delete", bg_key, "to re-submit.\n")
}

# ---- PART B: wait, lean import, clip, write ----------------------------------
bg_dl <- readLines(bg_key)[1]
occ_download_wait(bg_dl)                           # returns at once if ready
if (!file.exists(file.path(bg_dir, paste0(bg_dl, ".zip")))) {
  occ_download_get(bg_dl, path = bg_dir, overwrite = TRUE)
}

# record DOI
bg_meta <- tryCatch(occ_download_meta(bg_dl), error = function(e) NULL)
if (!is.null(bg_meta)) {
  writeLines(c(
    paste("DOI:", bg_meta$doi),
    paste("Key:", bg_meta$key),
    paste("Accessed:", Sys.Date()),
    paste0("Citation: GBIF.org (", Sys.Date(),
           ") GBIF Occurrence Download https://doi.org/", bg_meta$doi)
  ), bg_doi)
  cat("DOI (log in data-sources.md):", bg_meta$doi, "\n")
}

# Lean import: 4 columns only, straight from the zip (this file is large) ------
zip_path <- file.path(bg_dir, paste0(bg_dl, ".zip"))
stopifnot(file.exists(zip_path))
csv_name <- utils::unzip(zip_path, list = TRUE)$Name[1]   # single SIMPLE_CSV
cat("reading", csv_name, "from zip (4 columns only)...\n")

con <- unz(zip_path, csv_name)
bg_raw <- read_tsv(
  con,
  col_select = c(decimalLatitude, decimalLongitude, year, speciesKey),
  col_types  = cols(
    decimalLatitude  = col_double(),
    decimalLongitude = col_double(),
    year             = col_integer(),
    speciesKey       = col_character(),
    .default         = col_skip()
  ),
  quote = "", progress = TRUE
)
cat("rows read:", nrow(bg_raw), "\n")

bg <- bg_raw |>
  filter(!is.na(decimalLatitude), !is.na(decimalLongitude),
         !is.na(year), year >= YR_MIN, year <= YR_MAX,
         # belt-and-suspenders: predicate already drops tiger
         is.na(speciesKey) | speciesKey != as.character(tiger_spk)) |>
  transmute(latitude = decimalLatitude, longitude = decimalLongitude, yr = year)
rm(bg_raw); gc()
cat("after year / tiger filter:", nrow(bg), "\n")

# To sf, reproject, clip to India ----------------------------------------------
bg_sf <- st_as_sf(bg, coords = c("longitude", "latitude"),
                  crs = CRS_WGS84, remove = FALSE) |>
  st_transform(CRS_ANALYSIS)
bg_in <- bg_sf[india_7755, ]
cat("background records inside India polygon:", nrow(bg_in),
    sprintf(" (%.0f%% of pulled)\n", 100 * nrow(bg_in) / nrow(bg_sf)))

# Save clean background points -------------------------------------------------
bg_in |>
  select(yr) |>
  write_processed_vec("effort_background_tgs_7755.gpkg", dir = bound_dir)

# Report -----------------------------------------------------------------------
cat("\n--- Mammalia background effort points ---\n")
cat("total points (India, 2006-2022):", nrow(bg_in), "\n")
cat("records per year:\n")
bg_in |> st_drop_geometry() |> count(yr) |> arrange(yr) |> print(n = Inf)

rule("GBIF blocks done. Log both DOIs in docs/data-sources.md.")

# ==============================================================================
# BLOCK 4 — ESA WorldCover 2021 v200 land cover (windowed COG read -> 1 km modal)
# ==============================================================================
# 10 m, 11 classes, CC-BY 4.0. Public AWS COGs (no auth), 3x3-degree tiles in
# EPSG:4326, named by the tile's LOWER-LEFT corner: <2-digit lat><3-digit lon>
# e.g. N06E072. Only land tiles exist; ocean tiles are absent and skipped.
#
# WHY THIS IS NOT KEPT AT 10 m:
# The analysis grid is 1 km (GRID_CELL_M). A national 10 m raster is ~10,000x
# the cells the project needs; merging + reprojecting it in one shot is very slow
# AND makes terra::project() fail to infer output boundaries for EPSG:7755
# (a bounded LCC frame). Both problems are solved by reprojecting each tile onto
# an EXPLICIT 1 km EPSG:7755 template, with MODAL (majority) class — the correct
# resampling for a categorical layer. The 1 km modal layer is the analysis input;
# any finer/fractional-cover treatment is a deliberate Week-8 step, not here.

rule("BLOCK 4 — ESA WorldCover 2021 (windowed read -> 1 km modal class)")

wc_dir <- here::here("data", "raw", "worldcover")
dir.create(wc_dir, recursive = TRUE, showWarnings = FALSE)
wc_out <- file.path(bound_dir, "cov_landcover_worldcover2021_1km_7755.tif")

if (!file.exists(wc_out)) {
  # --- 1 km analysis-grid template in EPSG:7755 over India (+5 km collar) -----
  # An explicit template gives project() a defined output grid (fixes the
  # "cannot get output boundaries" error) and sets the target resolution.
  india_buf   <- st_buffer(india_7755, 5000)
  india_buf_v <- terra::vect(india_buf)
  tmpl <- terra::rast(india_buf_v, resolution = GRID_CELL_M)
  cat("1 km template:", paste(dim(tmpl)[1:2], collapse = " x "), "cells\n")

  aoi_ll <- st_transform(india_buf, CRS_WGS84)
  aoi_v  <- terra::vect(aoi_ll)

  # --- 3-degree tile grid over the India bbox (lower-left corners) ------------
  lat_ll <- seq(floor(bb[["ymin"]] / 3) * 3, floor(bb[["ymax"]] / 3) * 3, by = 3)
  lon_ll <- seq(floor(bb[["xmin"]] / 3) * 3, floor(bb[["xmax"]] / 3) * 3, by = 3)
  tiles  <- as.vector(outer(
    lat_ll, lon_ll,
    function(la, lo) sprintf("N%02dE%03d", la, lo)   # India is all N / E
  ))
  cat("candidate WorldCover tiles:", length(tiles),
      "(ocean tiles will be skipped)\n")

  url_fmt <- paste0("/vsicurl/https://esa-worldcover.s3.eu-central-1.amazonaws.com/",
                    "v200/2021/map/ESA_WorldCover_10m_2021_v200_%s_Map.tif")

  # --- Per-tile: window-read 10 m -> reproject to the 1 km template (modal) ---
  # Reprojecting each tile straight onto the shared 1 km template means every
  # piece is already aligned; they are then combined by modal class. This keeps
  # memory low (one 10 m tile at a time, never a national 10 m mosaic) and is
  # fast. project(method="mode") does the 10 m -> 1 km majority aggregation.
  wc_dir_tiles <- file.path(wc_dir, "tiles_1km")
  dir.create(wc_dir_tiles, showWarnings = FALSE)

  # A tile-sized 1 km target: reproject each tile to EPSG:7755 at 1 km resolution
  # (output is tile-sized, NOT national), then snap it onto the shared grid so
  # all tiles align. project(method="mode") does the 10 m -> 1 km majority.
  crs_7755 <- paste0("EPSG:", CRS_ANALYSIS)
  pieces <- list()
  for (t in tiles) {
    tile_out <- file.path(wc_dir_tiles, paste0(t, "_1km_7755.tif"))
    if (file.exists(tile_out)) {                       # resumable
      pieces[[t]] <- terra::rast(tile_out); next
    }
    r <- tryCatch(terra::rast(sprintf(url_fmt, t)), error = function(e) NULL)
    if (is.null(r)) next                               # ocean tile: skip
    # window-read this tile's overlap with the AOI (10 m, EPSG:4326)
    r_ll <- tryCatch(terra::crop(r, aoi_v), error = function(e) NULL)
    if (is.null(r_ll) || terra::ncell(r_ll) == 0) next
    # reproject to 1 km EPSG:7755 — tile-sized output (crs+res form)
    r_1km <- tryCatch(
      terra::project(r_ll, crs_7755, res = GRID_CELL_M, method = "mode"),
      error = function(e) NULL
    )
    if (is.null(r_1km) || terra::ncell(r_1km) == 0) next
    # snap onto the shared national grid so every tile aligns for merge.
    # Some edge/island tiles reproject to a footprint outside the buffered
    # India template -> crop returns no overlap; skip those (like ocean tiles).
    tgt <- tryCatch(terra::crop(tmpl, r_1km, snap = "out"),
                    error = function(e) NULL)
    if (is.null(tgt) || terra::ncell(tgt) == 0) {
      cat("  tile", t, "-> outside template, skipped\n"); next
    }
    r_1km <- terra::resample(r_1km, tgt, method = "near")
    terra::writeRaster(r_1km, tile_out, overwrite = TRUE,
                       gdal = c("COMPRESS=DEFLATE", "TILED=YES"))
    pieces[[t]] <- r_1km
    cat("  tile", t, "->", paste(dim(r_1km)[1:2], collapse = "x"), "1km cells\n")
  }
  cat("tiles that exist and overlap the AOI:", length(pieces), "\n")
  stopifnot(length(pieces) >= 1)

  # --- Combine grid-aligned 1 km tiles, mask to India, write -----------------
  # Tiles are a non-overlapping 3-degree grid, so at 1 km there is essentially no
  # overlap to resolve: merge (first value wins in any edge cell) is correct and
  # needs no modal function. sprc() + merge is the memory-safe combine.
  wc_1km <- if (length(pieces) > 1) {
    terra::merge(terra::sprc(unname(pieces)))
  } else pieces[[1]]
  wc_1km <- terra::extend(wc_1km, tmpl)               # to full template extent
  wc_1km <- terra::mask(wc_1km, terra::vect(india_7755))
  names(wc_1km) <- "worldcover_2021"
  terra::writeRaster(wc_1km, wc_out, overwrite = TRUE,
                     gdal = c("COMPRESS=DEFLATE", "TILED=YES"))
}

# Basic check ------------------------------------------------------------------
wc <- terra::rast(wc_out)
cat("\n--- ESA WorldCover 2021, 1 km modal (clipped to India) ---\n")
cat("EPSG:", terra::crs(wc, describe = TRUE)$code,
    "| resolution (m):", paste(round(terra::res(wc)), collapse = " x "), "\n")
cat("dimensions (r x c):", paste(dim(wc)[1:2], collapse = " x "), "\n")
# Class codes present should be a subset of the WORLDCOVER_RESISTANCE keys
# (10,20,30,40,50,60,70,80,90,95,100). Anything else means a bad read.
codes <- terra::unique(wc)[[1]]
cat("class codes present:", paste(sort(codes), collapse = ", "), "\n")
expected <- as.integer(names(WORLDCOVER_RESISTANCE))
unexpected <- setdiff(codes, c(expected, NA))
if (length(unexpected) > 0) {
  warning("WorldCover has unexpected class codes: ",
          paste(unexpected, collapse = ", "), " — inspect the read.")
}

# ==============================================================================
# BLOCK 5 — Global Human Modification 2022 (windowed COG read -> clip)
# ==============================================================================
# Human-pressure covariate (connectivity + SDM). Theobald et al. 2024/2025 v3,
# 2022 STATIC snapshot, all-threats-combined (AA), 300 m COG, EPSG:4326, CC-BY 4.0.
# Zenodo record 14502573; the file we want is the _s_AA_300 layer.
#   value range 0 (unmodified) to 1 (fully modified).
# Try a windowed /vsicurl read first; only if Zenodo refuses range requests do
# we fall back to a full download (guarded, LOUD about the size).
#
# NOTE: the exact Zenodo file name is confirmed on first run — the script lists
# candidate names and picks the _s_AA_300 COG. If Zenodo changes the file name,
# set GHM_FILE explicitly.

rule("BLOCK 5 — Global Human Modification 2022 (windowed COG read)")

ghm_dir <- here::here("data", "raw", "ghm")
dir.create(ghm_dir, recursive = TRUE, showWarnings = FALSE)
ghm_out   <- file.path(bound_dir, "cov_ghm2022_1km_7755.tif")
ghm_stamp <- file.path(ghm_dir, "ghm_source_stamp.txt")

# Zenodo direct-file base for record 14502573. The 2022 static all-threats layer.
# File name confirmed from the Zenodo API (record 14502573): the 2022 static (s)
# all-threats (AA) 300 m COG is HMv20240801_2022s_AA_300.tif. Other threat codes
# on the same record: BU/HI/FR/TI/AG/EX/NS/PO — AA is the combined index we want.
GHM_FILE <- "HMv20240801_2022s_AA_300.tif"
ghm_base <- paste0("https://zenodo.org/records/14502573/files/", GHM_FILE)
ghm_vsi_primary <- paste0("/vsicurl/", ghm_base)
ghm_vsi_dl      <- paste0("/vsicurl/", ghm_base, "?download=1")

if (!file.exists(ghm_out)) {
  # AOI window in WGS84 (gHM is EPSG:4326).
  aoi_ll <- india_7755 |> st_buffer(5000) |> st_transform(CRS_WGS84)
  aoi_v  <- terra::vect(aoi_ll)
  ext_ll <- terra::ext(aoi_v)

  # Windowed COG read: open remote raster, crop to AOI, only then fetch bytes.
  read_window <- function(vsi) {
    r <- tryCatch(terra::rast(vsi), error = function(e) NULL)
    if (is.null(r)) return(NULL)
    tryCatch(terra::crop(r, ext_ll), error = function(e) NULL)
  }
  ghm_ll <- read_window(ghm_vsi_primary)
  if (is.null(ghm_ll)) ghm_ll <- read_window(ghm_vsi_dl)

  # Guarded fallback: only if BOTH windowed reads failed (Zenodo refused range
  # requests). Download the full COG once, then crop locally. Fail LOUD.
  if (is.null(ghm_ll)) {
    warning("gHM windowed /vsicurl read failed (Zenodo may not honour range ",
            "requests). Falling back to a FULL download of ", GHM_FILE,
            " — large and slow. Interrupt now if the URL/file name is wrong.")
    ghm_local <- file.path(ghm_dir, GHM_FILE)
    if (!file.exists(ghm_local)) {
      options(timeout = 7200)                      # 2 h for a large global COG
      download.file(ghm_base, ghm_local, mode = "wb", method = "libcurl")
    }
    r <- terra::rast(ghm_local)
    ghm_ll <- terra::crop(r, ext_ll)
  }

  ghm_ll <- terra::mask(ghm_ll, aoi_v)

  # Reproject to analysis CRS on an EXPLICIT 1 km EPSG:7755 template — BILINEAR
  # (continuous 0-1 metric). The explicit template avoids the same
  # "cannot get output boundaries" failure the LCC frame causes for auto-extent,
  # and puts gHM straight onto the 1 km analysis grid.
  india_buf <- st_buffer(india_7755, 5000)
  tmpl <- terra::rast(terra::vect(india_buf), resolution = GRID_CELL_M)
  ghm_7755 <- terra::project(ghm_ll, tmpl, method = "bilinear")
  ghm_7755 <- terra::mask(ghm_7755, terra::vect(india_7755))
  names(ghm_7755) <- "ghm_2022"
  terra::writeRaster(ghm_7755, ghm_out, overwrite = TRUE,
                     gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "TILED=YES"))

  # Reproducibility stamp (Zenodo IS DOI-pinned — record it).
  writeLines(c(
    "Source: Global Human Modification v3, 2022 static snapshot (all threats, AA)",
    "Citation: Theobald, D.M., Oakleaf, J.R., Moncrieff, G., Voigt, M.,",
    "  Kiesecker, J., Kennedy, C.M. (2025). Global extent and change in human",
    "  modification of terrestrial ecosystems from 1990 to 2022. Sci Data 12, 606.",
    "Data DOI: 10.5281/zenodo.14502573",
    paste("File:", GHM_FILE, "(300 m COG, EPSG:4326, CC-BY 4.0)"),
    paste("Accessed:", Sys.Date())
  ), ghm_stamp)
}

# Basic check ------------------------------------------------------------------
ghm <- terra::rast(ghm_out)
cat("\n--- Global Human Modification v3 (2022, AA) ---\n")
cat("EPSG:", terra::crs(ghm, describe = TRUE)$code,
    "| resolution (m):", paste(round(terra::res(ghm)), collapse = " x "), "\n")
ghm_rng <- terra::minmax(ghm)
cat("gHM min/max:", round(ghm_rng[1], 3), "/", round(ghm_rng[2], 3),
    "(expected within 0-1)\n")
# gHM is 0 (unmodified) to 1 (fully modified). Values outside [0,1] mean a bad
# read / wrong band / fill leaking in — flag rather than trust.
if (ghm_rng[1] < -0.001 || ghm_rng[2] > 1.001) {
  warning("gHM values fall outside [0,1] — inspect the source read (fill / band).")
}
cat("mean gHM (India):",
    round(terra::global(ghm, "mean", na.rm = TRUE)[[1]], 3), "\n")

rule("WorldCover + gHM done.")

# ==============================================================================
# BLOCK 6 — OSM roads (major) + settlements (India, Geofabrik via osmextract)
# ==============================================================================
# Source: Geofabrik India .osm.pbf via osmextract::oe_get (downloads once,
# converts to GPKG, reads as sf). ODbL — attribution required.
#
# Purpose (connectivity track): road-density and settlement-density surfaces
# (line/point KDE at 1 km), NOT a routable network. So we keep only the classes
# those density surfaces used in Phase 2:
#   ROADS (lines, `highway` field): motorway, trunk, primary, secondary,
#     tertiary (+ their _link ramps). Residential/track/path excluded — they
#     bloat the layer and are not the barrier classes of interest.
#   SETTLEMENTS (points, `place` field): city, town, village. hamlet /
#     isolated_dwelling excluded — too granular for a 15 km KDE at 1 km.
#
# The India .osm.pbf is large (~1.5 GB). We filter SERVER-SIDE with a GDAL SQL
# `query=` so only the wanted classes are read into R, and clip to India with
# `boundary=`. Outputs are GeoPackage in data/raw/osm/, in EPSG:7755.

rule("BLOCK 6 — OSM roads + settlements (Geofabrik India)")

osm_dir <- here::here("data", "raw", "osm")
dir.create(osm_dir, recursive = TRUE, showWarnings = FALSE)
roads_out <- file.path(osm_dir, "osm_roads_major_7755.gpkg")
setts_out <- file.path(osm_dir, "osm_settlements_7755.gpkg")

# Keep osmextract's large download + converted gpkg inside data/raw/osm so it is
# gitignored with the rest of raw data (not in the default temp cache).
osm_cache <- file.path(osm_dir, "geofabrik_cache")
dir.create(osm_cache, showWarnings = FALSE)

india_v <- terra::vect(india_7755)                     # for later use / checks

# ---- Roads (major classes) ---------------------------------------------------
if (!file.exists(roads_out)) {
  cat("fetching + filtering OSM roads (major classes)...\n")
  # GGDAL SQL runs against the pbf 'lines' layer. highway classes of interest:
  road_q <- paste(
    "SELECT osm_id, highway, geometry FROM 'lines' WHERE highway IN",
    "('motorway','trunk','primary','secondary','tertiary',",
    "'motorway_link','trunk_link','primary_link','secondary_link','tertiary_link')"
  )
  roads <- oe_get(
    "India",
    layer                 = "lines",
    query                 = road_q,
    download_directory    = osm_cache,
    max_file_size         = 2e9,         # India pbf is ~1.5 GB; default cap is 500 MB
    boundary              = st_transform(india_7755, CRS_WGS84),
    boundary_type         = "clipsrc",   # actually clip geometry to India
    quiet                 = FALSE
  )
  roads <- st_transform(roads, CRS_ANALYSIS)
  st_write(roads, roads_out, delete_dsn = TRUE, quiet = TRUE)
}
roads <- read_vec(roads_out)
cat("\n--- OSM roads (major, clipped to India) ---\n")
cat("features:", nrow(roads), "| EPSG:", st_crs(roads)$epsg, "\n")
cat("class mix (highway):\n")
print(as.data.frame(table(roads$highway)), row.names = FALSE)

# ---- Settlements (city / town / village) -------------------------------------
if (!file.exists(setts_out)) {
  cat("\nfetching + filtering OSM settlements (city/town/village)...\n")
  place_q <- paste(
    "SELECT osm_id, place, name, geometry FROM 'points' WHERE place IN",
    "('city','town','village')"
  )
  setts <- oe_get(
    "India",
    layer              = "points",
    query              = place_q,
    download_directory = osm_cache,
    max_file_size      = 2e9,            # India pbf is ~1.5 GB; default cap is 500 MB
    force_vectortranslate = TRUE,        # re-translate; do not reuse the roads gpkg
    boundary           = st_transform(india_7755, CRS_WGS84),
    boundary_type      = "spat",         # bbox filter is enough for points
    quiet              = FALSE
  )
  setts <- st_transform(setts, CRS_ANALYSIS)
  # spat is a bbox filter; do a precise clip to the India polygon
  setts <- setts[india_7755, ]
  st_write(setts, setts_out, delete_dsn = TRUE, quiet = TRUE)
}
setts <- read_vec(setts_out)
cat("\n--- OSM settlements (clipped to India) ---\n")
cat("features:", nrow(setts), "| EPSG:", st_crs(setts)$epsg, "\n")
cat("class mix (place):\n")
print(as.data.frame(table(setts$place)), row.names = FALSE)

rule("OSM done. Log ODbL attribution in docs.")

# ==============================================================================
# BLOCK 7 — Terrain: elevation + slope + TRI (elevatr AWS tiles -> 1 km) [2.5]
# ==============================================================================
# Elevation from AWS Open Data Terrain Tiles via elevatr::get_elev_raster.
# Zoom sets resolution (z + latitude). The covariate grid is 1 km, so there is
# no reason to pull 30 m nationally and downsample: z = 7 is ~1 km at India's
# latitudes — close to target, a light national pull. From the DEM we derive
# slope (degrees) and TRI (terrain ruggedness index) with terra::terrain(),
# then resample all three onto the shared 1 km EPSG:7755 template so the whole
# covariate stack (WorldCover, gHM, terrain) is grid-aligned.
#
# get_elev_raster returns a raster in the CRS of `prj`; we request WGS84 then
# reproject to 7755 (bilinear, continuous). override_size_check = TRUE because a
# national AOI trips elevatr's built-in size guard.

rule("BLOCK 7 — Terrain: elevation + slope + TRI (elevatr AWS)")

terr_dir <- here::here("data", "raw", "terrain")
dir.create(terr_dir, recursive = TRUE, showWarnings = FALSE)
elev_raw_out <- file.path(terr_dir, "dem_india_aws_z7_4326.tif")   # cached raw DEM
terr_out     <- file.path(bound_dir, "cov_terrain_1km_7755.tif")   # 3-band output

TERRAIN_ZOOM <- 7L   # ~1 km ground resolution at India latitudes

# 1 km EPSG:7755 template (same construction as WorldCover / gHM) --------------
india_buf   <- st_buffer(india_7755, 5000)
india_buf_v <- terra::vect(india_buf)
tmpl <- terra::rast(india_buf_v, resolution = GRID_CELL_M)

# ---- Elevation (cached raw DEM in WGS84) -------------------------------------
if (!file.exists(elev_raw_out)) {
  cat("fetching AWS terrain tiles (z = ", TERRAIN_ZOOM, ")...\n", sep = "")
  aoi_ll <- st_transform(india_buf, CRS_WGS84)
  dem_ll <- elevatr::get_elev_raster(
    locations          = aoi_ll,
    z                  = TERRAIN_ZOOM,
    prj                = paste0("EPSG:", CRS_WGS84),
    src                = "aws",
    clip               = "locations",
    override_size_check = TRUE,
    verbose            = FALSE
  )
  dem_ll <- terra::rast(dem_ll)                       # v0.99 returns RasterLayer
  names(dem_ll) <- "elevation"
  terra::writeRaster(dem_ll, elev_raw_out, overwrite = TRUE,
                     gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "TILED=YES"))
}
dem_ll <- terra::rast(elev_raw_out)

# ---- Derive slope + TRI on the native DEM (before resampling) ----------------
# Compute terrain derivatives at native resolution, then aggregate — deriving
# them after a coarsen would understate ruggedness. terra::terrain gives slope
# in degrees; TRI is the mean abs elevation difference to the 8 neighbours.
slope_ll <- terra::terrain(dem_ll, v = "slope", unit = "degrees")
tri_ll   <- terra::terrain(dem_ll, v = "TRI")
names(slope_ll) <- "slope"
names(tri_ll)   <- "tri"

# ---- Reproject all three onto the shared 1 km 7755 template (bilinear) -------
to_1km <- function(r) {
  rp <- terra::project(r, tmpl, method = "bilinear")
  terra::mask(rp, terra::vect(india_7755))
}
elev_1km  <- to_1km(dem_ll)
slope_1km <- to_1km(slope_ll)
tri_1km   <- to_1km(tri_ll)

terr_stack <- c(elev_1km, slope_1km, tri_1km)
names(terr_stack) <- c("elevation", "slope", "tri")
terra::writeRaster(terr_stack, terr_out, overwrite = TRUE,
                   gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "TILED=YES"))

# Basic check ------------------------------------------------------------------
terr <- terra::rast(terr_out)
cat("\n--- Terrain (elevation / slope / TRI, 1 km, clipped to India) ---\n")
cat("bands:", paste(names(terr), collapse = ", "), "\n")
cat("EPSG:", terra::crs(terr, describe = TRUE)$code,
    "| resolution (m):", paste(round(terra::res(terr)), collapse = " x "), "\n")
mm <- terra::minmax(terr)
for (b in names(terr)) {
  cat(sprintf("  %-9s min %8.2f  max %8.2f\n", b, mm[1, b], mm[2, b]))
}
# elevation should span roughly -tens to ~8500 m (Himalaya); flag if absurd.
if (mm[2, "elevation"] > 9000 || mm[1, "elevation"] < -500) {
  warning("elevation range looks wrong — inspect the DEM read (fill / units).")
}

rule("Terrain done. Task 2.4 (GBIF/WorldCover/gHM/OSM) + task 2.5 (terrain) scripted pulls complete.")

# ==============================================================================
# BLOCK 8 — Admin boundaries: states (Natural Earth) + districts (DataMeet) [2.6]
# ==============================================================================
# The scriptable part of task 2.6. ISFR 2021 Ch.4 and Singh & Sen 2015 remain
# manual browser downloads (PDF/portal) — not here.
#
# STATES: Natural Earth admin-1 via rnaturalearth::ne_states (public domain).
# DISTRICTS: DataMeet Census-2011 district shapefile, pulled file-by-file from
#   raw.githubusercontent.com (a shapefile is 4 sibling files: shp/shx/dbf/prj).
#   CC BY 4.0 — attribution: "India district boundaries by DataMeet (CC BY 4.0)".
#   VINTAGE CAVEAT: these are Census-2011 districts. India has split many
#   districts since; newer districts will not be present. Fine for context /
#   roll-up; note it before any district-level attribute join.
# Both reprojected to EPSG:7755, saved to data/raw/administrative/.

rule("BLOCK 8 — Admin boundaries: states (NE) + districts (DataMeet)")

adm_dir <- here::here("data", "raw", "administrative")
dir.create(adm_dir, recursive = TRUE, showWarnings = FALSE)
states_out <- file.path(adm_dir, "boundary_states_ne_7755.gpkg")
distr_out  <- file.path(adm_dir, "boundary_districts_datameet2011_7755.gpkg")

# ---- States (Natural Earth admin-1) -----------------------------------------
if (!file.exists(states_out)) {
  cat("fetching Natural Earth India states (admin-1)...\n")
  states <- rnaturalearth::ne_states(country = "India", returnclass = "sf") |>
    st_make_valid() |>
    st_transform(CRS_ANALYSIS)
  st_write(states, states_out, delete_dsn = TRUE, quiet = TRUE)
}
states <- read_vec(states_out)
cat("\n--- India states (Natural Earth) ---\n")
cat("features:", nrow(states), "| EPSG:", st_crs(states)$epsg, "\n")

# ---- Districts (DataMeet Census 2011) ---------------------------------------
# Pull the 4 shapefile components into a temp dir, then read + reproject.
if (!file.exists(distr_out)) {
  cat("fetching DataMeet Census-2011 district shapefile (4 files)...\n")
  dm_base <- paste0("https://raw.githubusercontent.com/datameet/maps/master/",
                    "Districts/Census_2011/2011_Dist")
  dm_tmp  <- file.path(adm_dir, "datameet_2011_dist")
  dir.create(dm_tmp, showWarnings = FALSE)
  ok <- TRUE
  for (ext in c(".shp", ".shx", ".dbf", ".prj")) {
    dest <- file.path(dm_tmp, paste0("2011_Dist", ext))
    if (!file.exists(dest)) {
      res <- tryCatch(
        utils::download.file(paste0(dm_base, ext), dest, mode = "wb",
                             method = "libcurl", quiet = TRUE),
        error = function(e) 1L
      )
      if (!identical(res, 0L) || !file.exists(dest)) ok <- FALSE
    }
  }
  if (!ok) {
    warning("DataMeet district download failed for one or more components. ",
            "Check the repo path (Districts/Census_2011/2011_Dist.*) or fetch ",
            "manually. Skipping districts.")
  } else {
    districts <- st_read(file.path(dm_tmp, "2011_Dist.shp"), quiet = TRUE) |>
      st_make_valid() |>
      st_transform(CRS_ANALYSIS)
    st_write(districts, distr_out, delete_dsn = TRUE, quiet = TRUE)
  }
}
if (file.exists(distr_out)) {
  districts <- read_vec(distr_out)
  cat("\n--- India districts (DataMeet, Census 2011) ---\n")
  cat("features:", nrow(districts), "| EPSG:", st_crs(districts)$epsg, "\n")
  cat("(Census-2011 vintage — pre-redistricting; see docs/data-sources.md)\n")
} else {
  cat("\n--- India districts: NOT acquired (download failed) — fetch manually ---\n")
}

rule("Admin boundaries done. Remaining task 2.6 (manual): ISFR 2021 Ch.4 -> forest/, Singh & Sen 2015 -> ntca/. Then re-audit (2.7) + commit (2.9).")
