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
# The per-reserve growth series is the within-reserve SECR estimate for
# 2014 / 2018 / 2022 ONLY (Decision 6, docs/methodology.md). 2006 and 2010 have
# no comparable per-reserve table and are context only. Use these two constants
# for anything census/growth-related.
CENSUS_SERIES_YEARS  <- c(2014L, 2018L, 2022L)  # Decision 6
CENSUS_BASELINE_YEAR <- 2014L                    # series baseline (per-reserve
                                                 # earliest in practice; 2014 core)

# CENSUS_YEARS kept as an alias for the Decision-6 series (was the five-round
# vector c(2006,2010,2014,2018,2022) before Decision 6 - that predated the
# Week-4 finding that only 2014/2018/2022 are tabulated per reserve).
CENSUS_YEARS   <- CENSUS_SERIES_YEARS

# GBIF OCCURRENCE-DOWNLOAD year bounds (NOT the census baseline). These set the
# year window for the GBIF pull in scripts/01 (YR_MIN / YR_MAX). The occurrence /
# effort thread legitimately spans 2006-2022 (GBIF data range), independent of
# Decision 6, which governs only the census tables. Do NOT set these to the
# census series - narrowing them would silently change the occurrence pull.
BASELINE_YEAR  <- 2006L   # GBIF download lower bound (scripts/01 YR_MIN)
CURRENT_YEAR   <- 2022L   # GBIF download upper bound (scripts/01 YR_MAX)

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

# ---- Decision 11: gHM gap-fill relevance rule (Week 9, task 9.2) ------------
# Fixed BEFORE the check is run (pre-registration). See docs/methodology.md,
# Decision 11, for the sources and reasons. scripts/07_connectivity.R STEP 9.2
# reads these; do not repeat the values as literals in any script.
GAP_BUFFER_M      <- 10000L  # reserve approach-zone ring width, metres
                             # (MoEF 2011 ESZ default; ~1 female home-range
                             #  diameter in Indian telemetry studies)
GAP_MIN_PCT       <- 5       # a unit is "materially affected" if >= this % of
                             # its land cells are dropped ...
GAP_MIN_CELLS     <- 25L     # ... OR >= this many dropped land cells
                             # (25 km2 at 1 km; below a resident female range)
GAP_WATER_CLASS   <- 80L     # WorldCover permanent water: reported, not counted
GAP_FILL_WINDOW   <- 3L      # focal window (cells) for the gHM fill
GAP_FILL_MAX_ITER <- 5L      # max fill passes: fill reaches <= 5 km from real
                             # gHM data. The fill runs ONLY if STEP 9.2 triggers.

# Decision-11 OUTCOME switch. The pre-fill check (2026-09-26) TRIGGERED
# (27 units materially affected), so the fill applies. scripts/06 STEP 8.4b
# fills gHM when this is TRUE and records the count in tbl_10 (n_filled).
# Set by the recorded outcome in docs/methodology.md — do not change it to
# test alternatives.
GHM_GAP_FILL      <- TRUE

# ---- Connectivity: resistance surface (Decision 14, 2026-09-26) -------------
# Fixed BEFORE any resistance surface is built. See docs/methodology.md,
# Decision 14, for the sources and reasons. scripts/07_connectivity.R STEP 9.5
# reads these; do not repeat the values as literals in any script.
#
# Order of operations (Decision 14, point 5):
#   class value -> Sundarban water override -> gHM multiplier (not on the
#   Decision-16 exempt classes) -> cap -> road barrier (Decision 15, task 9.6)
#   resistance = min(RESIST_MAX, value * (1 + RESIST_GHM_K * gHM))   # land
#   resistance = value                                               # water

# ESA WorldCover 2021 class -> movement resistance (1 = easiest ... 100 = max).
WORLDCOVER_RESISTANCE <- c(
  "10"  =   1,   # Tree cover            (Week-0 start: 1)
  "20"  =   3,   # Shrubland             (3)
  "30"  =   3,   # Grassland             (5)   judgement
  "40"  =  10,   # Cropland              (7)   judgement; evidence mixed
  "50"  = 100,   # Built-up              (50)
  "60"  =  10,   # Bare / sparse veg.    (10)  judgement
  "70"  = 100,   # Snow and ice          (100)
  "80"  =  50,   # Permanent water       (100) 10 inside the Sundarban region
  "90"  =   3,   # Herbaceous wetland    (15)  judgement; absent from reserves
  "95"  =   1,   # Mangroves             (10)
  "100" =  50    # Moss and lichen       (8)   judgement; absent from reserves
)

RESIST_MAX   <- 100   # cap applied after the gHM multiplier
RESIST_GHM_K <- 4     # gHM multiplier: x1 at gHM 0 ... x5 at gHM 1 (judgement)

# Decision 16 (2026-09-26, post-result): classes EXEMPT from the gHM multiplier.
# gHM has no data over water; the Decision-11 fill imputed water cells from
# their land neighbours only to keep them in the stack. Water resistance comes
# from land cover (50; 10 in the Sundarban region), not from imputed gHM.
RESIST_GHM_EXEMPT_CLASSES <- c(80L)   # permanent water

# Sundarban water region: water cells inside the Sundarbans reserve polygon plus
# a ring of RESIST_WATER_REGION_BUFFER_M take RESIST_WATER_REGION_VALUE instead
# of the class-80 value. unit_id is the stable reserve key (naming §5); STEP 9.5
# asserts that it resolves to the named reserve.
RESIST_WATER_CLASS            <- 80L
RESIST_WATER_REGION_UNIT_IDS  <- c(57L)          # Sundarbans
RESIST_WATER_REGION_NAMES     <- c("Sundarbans") # guard: must match unit_id
RESIST_WATER_REGION_BUFFER_M  <- GAP_BUFFER_M    # 10 km (Decision 11 value)
RESIST_WATER_REGION_VALUE     <- 10

# ---- Connectivity: road barrier (Decision 15, 2026-09-26) -----------------
# Fixed BEFORE any resistance surface is built. See docs/methodology.md,
# Decision 15. scripts/07_connectivity.R STEP 9.6 reads these.
#   road cell resistance = max(Decision-14 surface, ROAD_BARRIER_VALUE)
# `_link` ramps take their parent class (e.g. trunk_link -> trunk). Tertiary is
# NOT a barrier class; its effect is left to gHM ("minor roads").
ROAD_BARRIER_CLASSES <- c("motorway", "trunk", "primary", "secondary")
ROAD_BARRIER_VALUE   <- 30     # one value for every barrier class (judgement)
ROAD_BARRIER_TOUCHES <- TRUE   # rasterise every cell a road touches (no
                               # diagonal leaks for an 8-neighbour path)

# ---- Connectivity: sensitivity variants (Decisions 14 + 15) ------------------
# Each variant changes ONE choice against the baseline (k = RESIST_GHM_K, road
# value = ROAD_BARRIER_VALUE), so the Week-10 comparison can trace a difference
# to that choice. Written beside the baseline as resist_tiger_<name>_7755.tif.
#   noghm  — Decision 14: no gHM multiplier (k = 0), road value 30
#   road15 — Decision 15: weaker road barrier (15), k = 4
#   road50 — Decision 15: stronger road barrier (50), k = 4
RESIST_VARIANTS <- list(
  noghm  = list(ghm_k = 0,            road_value = ROAD_BARRIER_VALUE),
  road15 = list(ghm_k = RESIST_GHM_K, road_value = 15),
  road50 = list(ghm_k = RESIST_GHM_K, road_value = 50)
)

# ---- Convenience -----------------------------------------------------------
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
