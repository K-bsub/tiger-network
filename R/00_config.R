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

# ---- Boundaries: state split (Decision 17, point 7 — D1a; 2026-10-01) --------
# The NTCA KML polygon matched to Nagarjunsagar-Srisailam is the undivided
# reserve: about 2,701 km2 of it lies in Telangana, where Amrabad now is.
# scripts/02 splits the parent polygon at the state boundary
# (boundary_states_7755.gpkg, field `name`) and gives each part to the
# reserve named here. unit_id is the join key (naming §5); scripts/02 asserts
# that each unit_id resolves to the named reserve and state.
BOUNDARY_STATE_SPLITS <- list(
  list(
    parent_unit_id = 1L,
    parent_name    = "Nagarjunsagar-Srisailam",
    parts = list(
      list(unit_id = 1L,  unit_name = "Nagarjunsagar-Srisailam",
           state = "Andhra Pradesh"),
      list(unit_id = 51L, unit_name = "Amrabad",
           state = "Telangana")
    )
  )
)
# match_status that scripts/02 writes on each split part. scripts/07 STEP 9.2
# reads it: a reserve layer with split parts adds "_split" to the gap-table
# label, so the Week-9 tables are not overwritten (process choice RS1,
# 2026-10-02).
BOUNDARY_SPLIT_STATUS <- "state_split"

# ---- Connectivity: least-cost paths (Decision 17, 2026-10-01) ---------------
# Fixed BEFORE any path is built. See docs/methodology.md, Decision 17, for the
# sources and reasons. scripts/07_connectivity.R (Week-10 STEPs) reads these;
# do not repeat the values as literals in any script.

# (1) Reserve pairs: every complete-case footprint cell is allocated to the
# nearest reserve polygon (straight line); two reserves are a candidate pair
# if their zones share >= 1 cell edge; a candidate is kept if the polygon gap
# is <= LCP_PAIR_MAX_GAP_KM. One pair set for every surface.
LCP_PAIR_ADJACENCY   <- "rook"  # zones share at least one cell edge
LCP_PAIR_MAX_GAP_KM  <- 315     # longest recorded straight-line tiger
                                # dispersal in India (Hussain et al. 2022)

# (2) A path that crosses a third reserve C: A-B leaves the network only if
# A-C and C-B are both pairs; otherwise it stays and C is recorded.
LCP_THROUGH_RESERVE_RULE <- "drop_if_redundant"

# (3) Graph: footprint cells are nodes; NA cells are not.
# Step cost = step length (km) x length-weighted mean resistance of the cells
# that the straight line between the two cell centres crosses:
#   orthogonal (1 km), diagonal (sqrt 2 km): the 2 end cells, 1/2 each
#   knight (sqrt 5 km): the 4 crossed cells, 1/4 each; not allowed if any NA
# Cost-distance unit: resistance-km.
LCP_NEIGHBOURS  <- 16L
LCP_KNIGHT_RULE <- "crossed_cells"  # "end_cells" is used ONLY by the
                                    # gdistance validation check (point 4c)

# (4) Validation (scripts/07 STEP 10.2b -> tbl_12_lcp_validation.csv).
# Pairs from the baseline pair set: shortest non-zero gap, gap nearest the
# median, longest gap (ties: lowest pair id). A cost difference above the
# tolerance is a hard stop; path overlap is reported, not a stop.
LCP_VALIDATE           <- TRUE
LCP_VALIDATE_PAIRS     <- c("min_nonzero_gap", "median_gap", "max_gap")
LCP_VALIDATE_TOL_REL   <- 1e-6
LCP_VALIDATE_WINDOW_KM <- 100   # gdistance window: path bounding box + this

# (5) No crop: one national graph. The fallback applies ONLY if the task-10.3
# smoke test shows the national graph does not fit in memory:
# window = pair bounding box + max(MIN_BUFFER_KM, BUFFER_FRAC x gap); a path
# that touches the window edge is re-run on a wider window.
LCP_CROP                        <- FALSE
LCP_CROP_FALLBACK_MIN_BUFFER_KM <- 100
LCP_CROP_FALLBACK_BUFFER_FRAC   <- 0.5

# (6) Start and end: edge to edge. Reserve cells = footprint cells the polygon
# touches. Travel inside the source and target reserves costs nothing; other
# reserves cost their resistance. Contiguous pairs (amended 2026-10-02: the
# two reserves share >= 1 footprint cell; every gap-0 pair is one) get cost 0
# and an empty path.
LCP_RESERVE_TOUCHES <- TRUE

# (7) Reserves with no geometry stay out of the network (G1). Guard names must
# match unit_id.
LCP_EXCLUDED_UNIT_IDS   <- c(44L, 53L)
LCP_EXCLUDED_UNIT_NAMES <- c("Dholpur-Karauli", "Pilibhit")

# (8) Network groups: labels on geography (W2, H1). They remove no pair; a
# pair across two groups is marked cross_group = TRUE. Separate from
# landscape_complex (which does not change). Every unit_id 1-58 must appear
# exactly once; scripts/07 asserts it. Pilibhit (53) and Dholpur-Karauli (44)
# are listed but have no geometry.
NETWORK_GROUPS <- list(
  northeast     = c(2L, 3L, 4L, 5L, 6L, 7L, 8L, 37L, 58L),
  # Namdapha, Pakke, Kamlang, Manas, Nameri, Kaziranga, Orang, Dampa, Buxa
  western_ghats = c(15L, 16L, 17L, 18L, 19L, 20L, 21L, 34L,
                    45L, 46L, 47L, 48L, 49L),
  # Bandipur, Bhadra, Kali, Nagarhole, BRT, Periyar, Parambikulam, Sahyadri,
  # Kalakad-Mundanthurai, Anamalai, Mudumalai, Sathyamangalam,
  # Srivilliputhur-Megamalai
  north         = c(9L, 52L, 53L, 55L, 56L),
  # Valmiki, Dudhwa, Pilibhit, Corbett, Rajaji (the Terai)
  central       = c(1L, 10L, 11L, 12L, 13L, 14L, 22L, 23L, 24L, 25L, 26L,
                    27L, 28L, 29L, 30L, 31L, 32L, 33L, 35L, 36L, 38L, 39L,
                    40L, 41L, 42L, 43L, 44L, 50L, 51L, 54L, 57L)
  # Central India and Eastern Ghats, the Rajasthan reserves (40-44), Ranipur
  # (54) and the Sundarbans (57)
)

# (9) NTCA corridor comparison (descriptive, baseline paths only):
# per path, share of length inside any corridor polygon; per corridor,
# whether >= 1 baseline path crosses it. Not a validation.
LCP_NTCA_OVERLAP <- TRUE

# ---- Connectivity: variant comparison (Decision 18, 2026-10-01) ------------
# Fixed BEFORE any variant path is run. See docs/methodology.md, Decision 18.
# scripts/07_connectivity.R STEP 10.4 reads these. Each variant is compared
# with the baseline only, on every pair that is not contiguous (Decision 17
# point 6, amended 2026-10-02).
#   route overlap = min(share of baseline length within d of the variant path,
#                       share of variant length within d of the baseline path)
#   rank          = (rank - 1) / (n - 1) of cost-distance, ties = average rank
#   material pair = route overlap < ROUTE_MATERIAL  OR  |rank change| >= RANK_MATERIAL
#   label         = "robust" if share of material pairs <= ROBUST_MAX_SHARE
#                   AND Spearman rho >= ROBUST_MIN_RHO, else "sensitive".
#   The road value is robust only if BOTH road15 and road50 are robust.
LCP_COMPARE_VARIANTS          <- names(RESIST_VARIANTS)  # noghm, road15, road50
LCP_COMPARE_ROUTE_D_KM        <- 5     # ~ one resident female home-range radius
LCP_COMPARE_ROUTE_D_DESCR_KM  <- c(1, 2, 5, 10)  # descriptive overlap columns
LCP_COMPARE_ROUTE_MATERIAL    <- 0.5   # route overlap below this = material
LCP_COMPARE_RANK_MATERIAL     <- 0.25  # |percentile-rank change| >= this
LCP_COMPARE_ROBUST_MAX_SHARE  <- 0.20  # judgement value
LCP_COMPARE_ROBUST_MIN_RHO    <- 0.9   # judgement value

# ---- Convenience -----------------------------------------------------------
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
