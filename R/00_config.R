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
ROAD_BARRIER_TOUCHES <- TRUE   # rasterise every cell a road touches, so a
                               # diagonal road leaves no corner gap for a
                               # diagonal step (Decision 15 point 4). The
                               # engine has 16 neighbours: a knight step
                               # cannot jump the road line (crossed-cells
                               # rule, Decision 17 point 3).

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

# ---- Connectivity: reserve network (Decision 19, 2026-10-03) ----------------
# Fixed BEFORE any network metric is computed. See docs/methodology.md,
# Decision 19. The Week-11 STEPs of scripts/07_connectivity.R read these.
# The path costs were seen in Week 10; no rule here uses a cost value.
#   link    = every pair with in_network == TRUE on the surface (no threshold)
#   node    = a block of contiguous reserves, or one reserve
#             (56 reserves -> 47 nodes; the same on every surface)
#   edge    = the lowest-cost in-network pair between two nodes
#             (tie: lowest pair_id); weight = cost_rkm, a distance
#   betweenness_norm = raw / ((n - 1)(n - 2) / 2), n = nodes in the node's
#                      own set; NA if n < NET_NORM_MIN_SET_NODES
#   linchpin = rank in the set <= NET_LINCHPIN_TOP_N AND betweenness_norm > 0
#              (ties at the last rank are all linchpins)
#   isolated = degree 0;  pendant = degree 1
NET_LINK_RULE          <- "all_in_network"  # a1: no cost threshold
NET_EDGE_WEIGHT_FIELD  <- "cost_rkm"        # resistance-km; a distance
NET_CONTIGUOUS_RULE    <- "merge_block"     # b1: contiguous reserves = 1 node
NET_PARALLEL_RULE      <- "min_cost"        # one edge per node pair
NET_EXPECTED_RESERVES  <- 56L               # QA: stop if different
NET_EXPECTED_NODES     <- 47L               # QA: stop if different
NET_NORM_RULE          <- "own_set"         # c1
NET_NORM_MIN_SET_NODES <- 3L                # below this, betweenness_norm = NA
NET_LINCHPIN_TOP_N     <- 3L                # judgement value (k3)

# Descriptive threshold scan (a4): baseline only. It chooses no threshold and
# removes no link.
NET_THRESHOLD_SCAN      <- TRUE
NET_THRESHOLD_SCAN_SURF <- "baseline"

# Second run without the cross-group links (f2): baseline only. A linchpin of
# the main graph that is not a linchpin here gets cross_group_dependent = TRUE.
NET_NOCROSS_RERUN       <- TRUE
NET_NOCROSS_SURF        <- "baseline"

# Variant repeat (e2). Each variant is compared with the baseline only.
#   label = "robust" if the sets are the same
#           AND Spearman rho of betweenness_norm >= NET_COMPARE_ROBUST_MIN_RHO
#           AND linchpin retention >= NET_COMPARE_ROBUST_MIN_RETENTION,
#           else "sensitive".
#   The road value is robust only if BOTH road15 and road50 are robust.
#   A linchpin on all four surfaces is a stable linchpin.
NET_COMPARE_VARIANTS             <- names(RESIST_VARIANTS)  # noghm, road15, road50
NET_COMPARE_ROBUST_MIN_RHO       <- 0.9    # judgement value
NET_COMPARE_ROBUST_MIN_RETENTION <- 2 / 3  # judgement value

# ---- Connectivity: road pinch points (Decision 20, 2026-10-10) --------------
# Fixed BEFORE any road crossing is computed. See docs/methodology.md,
# Decision 20. The Week-12 STEPs of scripts/07_connectivity.R read these; do
# not repeat the values as literals in any script.
# The network results were seen in Week 11; no rule here uses a crossing
# count, a cost or a road class.
#   road cell   = a footprint cell that a barrier road touches (the cells of
#                 STEP 9.6); road_class_top = the highest class in the cell
#   cell list   = the path cells in order + the 2 middle cells of each knight
#                 step (crossed-cells rule, Decision 17 point 3)
#   crossing    = one unbroken run of road cells in the cell list of a path
#   site        = crossings joined at <= PINCH_SITE_MERGE_KM (cell centres;
#                 one link or different links)
#   on_bridge   = a bridge edge uses the site
#   shared      = >= PINCH_SHARED_MIN_EDGES edges use the site
#   pinch_point = on_bridge OR shared
#   pinch_tier  = 1 both flags; 2 on_bridge only; 3 shared only

# (1) Roads (a1): the Decision-15 barrier classes and rasterise rule. The
# class order is for road_class_top only (a description, not a rule and not a
# traffic volume). scripts/07 asserts that the order holds every barrier
# class once, and that the cell count equals n_road_cells in
# tbl_11_resistance_qa.csv.
PINCH_ROAD_CLASSES     <- ROAD_BARRIER_CLASSES
PINCH_ROAD_TOUCHES     <- ROAD_BARRIER_TOUCHES
PINCH_ROAD_CLASS_ORDER <- c("motorway", "trunk", "primary", "secondary")
                          # highest first

# (2) Paths (b1): crossings for the in-network pairs with these link roles
# (Decision 19 point 3); the pinch-point rule counts the edges only.
PINCH_PATH_LINK_ROLES <- c("edge", "parallel")
PINCH_RULE_LINK_ROLES <- c("edge")

# Links marked lit_flag = TRUE in every table (k1): no literature support, or
# a described barrier (methodology Limitations, 2026-10-04). No link is
# dropped. unit_id is the key (naming §5); the names are a guard (process
# choice L2, 2026-10-10). scripts/07 asserts that each unit_id has the stated
# name and that each entry is a pair of tbl_12_reserve_pairs.csv.
PINCH_LIT_FLAG_PAIRS <- list(
  list(unit_ids = c(8L, 37L),  names = c("Orang", "Dampa")),
  list(unit_ids = c(46L, 49L), names = c("Anamalai", "Srivilliputhur-Megamalai")),
  list(unit_ids = c(20L, 45L), names = c("Periyar", "Kalakad-Mundanthurai")),
  list(unit_ids = c(41L, 56L), names = c("Sariska", "Rajaji"))
)

# (3) One crossing (c1, r1). The functions build one rule set only; a
# different value needs a new Decision and new code.
PINCH_CROSSING_RULE     <- "cell_run"        # not a line-on-line intersection
PINCH_RESERVE_CELL_RULE <- "count_and_flag"  # reserve cells count; the
                                             # reserves are listed

# (4) Site (m1). 5 km = the Decision-18 route distance (judgement value).
PINCH_SITE_MERGE_KM <- 5

# (5) Pinch point (d1).
PINCH_RULE             <- "bridge_or_shared"
PINCH_SHARED_MIN_EDGES <- 2L                 # judgement value

# (6) Variant repeat (e2). Each variant is compared with the baseline only.
#   near          = two sites with cell centres <= PINCH_COMPARE_D_KM apart
#   site_overlap  = min(share of baseline pinch points with a variant pinch
#                       point near them, share of variant pinch points with a
#                       baseline pinch point near them)
#   label         = "robust" if site_overlap >= the minimum, else "sensitive";
#                   a surface with no pinch point is "sensitive".
#   The road value is robust only if BOTH road15 and road50 are robust.
PINCH_COMPARE_VARIANTS           <- names(RESIST_VARIANTS)  # noghm, road15, road50
PINCH_COMPARE_D_KM               <- 5       # = PINCH_SITE_MERGE_KM by Decision 20
PINCH_COMPARE_D_DESCR_KM         <- c(5, 10)  # descriptive overlap columns
PINCH_COMPARE_ROBUST_MIN_OVERLAP <- 2 / 3   # judgement value (the Decision-19
                                            # retention limit)

# (7) Publication (p1): a crossing or a site is given as a cell of this grid
# (the analysis grid aggregated from its top-left corner), with state and
# district, in every committed table, figure, caption and popup
# (docs/sensitive-data-policy.md §3). It must be a whole multiple of
# GRID_CELL_M. The 1 km cells go only into a gitignored layer.
PINCH_PUBLISH_GRID_M <- 10000L               # judgement value
PINCH_FIG_NUMBER     <- 3L                   # fig_03_<slug>.png (author choice)

# (7, figure g1) The file name, the size, and the place of the linchpin list.
# PINCH_FIG_KEY_POS: the top-left corner of the list, as a share of the extent
# of the state layer (x from the west side, y from the south side). The
# values put the list in the Bay of Bengal, between the mainland and the
# islands.
PINCH_FIG_SLUG       <- "reserve_network"    # fig_03_reserve_network.png
PINCH_FIG_SIZE_IN    <- c(width = 11, height = 10.6)   # inches
PINCH_FIG_DPI        <- 200L                 # as fig_01 and fig_02
PINCH_FIG_KEY_POS    <- c(x = 0.60, y = 0.36)

# ---- Convenience -----------------------------------------------------------
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
