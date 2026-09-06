# =============================================================================
# 00_config.R
# Central project configuration. Sourced by every script and function file.
# Set values here once; never hardcode a CRS, path, or year list elsewhere.
# =============================================================================

# ---- Coordinate reference system -------------------------------------------
# Analysis CRS for all of India. EPSG:7755 = WGS 84 / India NSF LCC, a national
# Lambert Conformal Conic frame appropriate for a country-wide extent. The
# tiger Phase 1 used UTM 43N (EPSG:32643), which is fine for Central India but
# distorts at the national scale (Kaziranga to the Western Ghats spans several
# UTM zones). Raw data is ingested in EPSG:4326 and reprojected on load.
CRS_ANALYSIS <- 7755L
CRS_WGS84    <- 4326L

# ---- Census years ----------------------------------------------------------
# NTCA All India Tiger Estimation rounds. The full time series, not just the
# 2006/2022 endpoints used in Phase 1.
CENSUS_YEARS   <- c(2006L, 2010L, 2014L, 2018L, 2022L)
BASELINE_YEAR  <- 2006L
CURRENT_YEAR   <- 2022L

# ---- Occurrence temporal windows (for KDE / effort comparisons) ------------
BASELINE_WINDOW <- c(2006L, 2010L)
CURRENT_WINDOW  <- c(2018L, 2022L)

# ---- Landscape complexes (roll-up units for the narrative) -----------------
# NTCA / WII tiger landscape complexes. Reserves are assigned to one of these
# in scripts/02; this vector is the controlled vocabulary for that field.
LANDSCAPE_COMPLEXES <- c(
  "shivalik_gangetic",      # Terai Arc: Corbett, Dudhwa, Valmiki, Pilibhit ...
  "central_india_eastern",  # Kanha, Pench, Bandhavgarh, Tadoba, Similipal ...
  "western_ghats",          # Bandipur, Nagarahole, Periyar, Anamalai ...
  "northeast_hills",        # Kaziranga, Manas, Namdapha ...
  "sundarbans"              # Sundarbans (distinct: mangrove, no land corridor)
)

# ---- Paths -----------------------------------------------------------------
# All paths are project-relative via here::here(). Do NOT use here() inside
# site/ .qmd files (they need page-relative paths) — this is for scripts only.
DIR_RAW        <- here::here("data", "raw")
DIR_INTERIM    <- here::here("data", "interim")
DIR_PROCESSED  <- here::here("data", "processed")
DIR_RESTRICTED <- here::here("data", "restricted")
DIR_FIGURES    <- here::here("outputs", "figures")
DIR_TABLES     <- here::here("outputs", "tables")
DIR_MODELS     <- here::here("outputs", "models")
DIR_RASTERS    <- here::here("outputs", "rasters")

# ---- Analysis parameters ---------------------------------------------------
# Grid cell size (metres) for raster covariates and the SDM prediction surface.
GRID_CELL_M <- 1000L

# Publish floor: continuous surfaces are generalised to at least this cell size
# before publication (see docs/sensitive-data-policy.md §3).
PUBLISH_FLOOR_M <- 1000L

# KDE search radius (metres) — starting value; test 10/20/30 km as in Phase 1.
KDE_RADIUS_M <- 20000L

# ---- Connectivity: land-cover resistance lookup ----------------------------
# ESA WorldCover 2021 class -> movement resistance (1 = easiest, high = barrier).
# Values are literature-informed starting points and MUST be recorded as a
# numbered Decision before the resistance surface is built. Do not treat as final.
WORLDCOVER_RESISTANCE <- c(
  "10" =   1,   # Tree cover
  "20" =   3,   # Shrubland
  "30" =   5,   # Grassland
  "40" =   7,   # Cropland
  "50" =  50,   # Built-up
  "60" =  10,   # Bare / sparse vegetation
  "70" = 100,   # Snow and ice
  "80" = 100,   # Permanent water bodies
  "90" =  15,   # Herbaceous wetland
  "95" =  10,   # Mangroves
  "100" =  8    # Moss and lichen
)

# ---- Convenience -----------------------------------------------------------
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
