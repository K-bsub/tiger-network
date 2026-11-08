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

# KDE settings: see "Stage 3: effort surfaces (Decision 22)" below.

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

# ---- Stage 3: occurrence cleaning (Decision 21, 2026-10-11) -----------------
# Fixed BEFORE any record is cleaned and before any cleaned count is made. See
# docs/methodology.md, Decision 21, for the sources, the reasons and what was
# seen. The Stage-3 script (scripts/08) reads these; do not repeat the values
# as literals in any script.
#   source  = the two GBIF SIMPLE_CSV files of Week 2, read again (the interim
#             layers do not hold the rule fields); the interim layers are the
#             guard for the entry state
#   steps   = OCC_STEP_ORDER, one order for the tiger records and for the
#             background; a record is counted at the first step that removes it
#   sets    = uncert_set "1km" (<= OCC_UNCERT_MAIN_M) and "5km" (above it and
#             <= OCC_UNCERT_WIDE_M); the 1 km set is the main set, the 5 km
#             set (both values) is for one sensitivity run
#   cell    = one presence per 1 km complete-case cell; no distance thinning

# (2) Rule steps, in order. Each name is a row of the attrition table.
OCC_STEP_ORDER <- c("status", "basis", "year", "coord_flags", "uncert_na",
                    "uncert", "centroid", "zoo", "footprint")

# Steps 1-2 (c2): a record stays only with these values. A missing value is
# removed. Amendment 1 (2026-10-11, after the names stage of STEP 13.1 and
# before any count): c2 replaces c1, which kept only the first two record
# types. OBSERVATION and OCCURRENCE are not in the two files.
OCC_STATUS_KEEP <- c("PRESENT")
OCC_BASIS_KEEP  <- c("HUMAN_OBSERVATION", "MACHINE_OBSERVATION",
                     "OBSERVATION", "OCCURRENCE", "MATERIAL_SAMPLE")

# Step 3 (b1): the year window is the window of the background download. A
# record with no year is removed.
OCC_YEAR_MIN <- BASELINE_YEAR   # 2006
OCC_YEAR_MAX <- CURRENT_YEAR    # 2022

# Step 4: GBIF `issue` flags. A record with a flag of OCC_ISSUE_REMOVE is
# removed (the coordinate is wrong, or GBIF changed it on an assumption). The
# flags of OCC_ISSUE_REPORT are counted and remove no record. Judgement lists.
OCC_ISSUE_REMOVE <- c(
  "ZERO_COORDINATE", "COORDINATE_OUT_OF_RANGE", "COORDINATE_INVALID",
  "COUNTRY_COORDINATE_MISMATCH", "PRESUMED_SWAPPED_COORDINATE",
  "PRESUMED_NEGATED_LATITUDE", "PRESUMED_NEGATED_LONGITUDE",
  "COORDINATE_REPROJECTION_FAILED", "COORDINATE_REPROJECTION_SUSPICIOUS",
  "COORDINATE_UNCERTAINTY_METERS_INVALID"
)
OCC_ISSUE_REPORT <- c(
  "GEODETIC_DATUM_ASSUMED_WGS84", "GEODETIC_DATUM_INVALID",
  "COORDINATE_ROUNDED", "COORDINATE_REPROJECTED",
  "COORDINATE_PRECISION_INVALID"
)

# Steps 5-6 (n1, a3): coordinateUncertaintyInMeters.
OCC_UNCERT_NA_RULE <- "remove"       # no value, or a value <= 0: removed
OCC_UNCERT_MAIN_M  <- GRID_CELL_M    # 1,000 m: the main set ("1km")
OCC_UNCERT_WIDE_M  <- as.integer(LCP_COMPARE_ROUTE_D_KM * 1000)
                                     # 5,000 m: the Decision-18 distance
                                     # (judgement value); the second set

# (4) Obscured set (o2): a record that step 6 removes, from the iNaturalist
# dataset, with an uncertainty of at least OCC_OBSCURED_MIN_UNCERT_M. It gets
# the 0.2 degree cell of its public coordinates. It is never a 1 km presence.
OCC_INAT_DATASET_KEY      <- "50c9509d-22c7-4a22-a47d-8c48425ef4a7"
                             # "iNaturalist Research-grade Observations"
                             # (GBIF registry, read 2026-10-11)
OCC_OBSCURED_MIN_UNCERT_M <- 25000L  # judgement value: below the smallest
                                     # diagonal of a 0.2 degree cell in India
                                     # (about 28.4 km at 37 N)
OCC_OBSCURED_CELL_DEG     <- 0.2     # the iNaturalist obscuring grid

# Step 7 (z2): geometric centroid of India, of each state and of each
# district; a record within the distance is removed.
OCC_CENTROID_LEVELS <- c("india", "state", "district")
OCC_CENTROID_DIST_M <- GRID_CELL_M   # judgement value

# Step 8 (z2): OpenStreetMap zoo features (points and areas) from the cached
# Geofabrik India file; a record within the distance is removed.
OCC_ZOO_OSM_KEY   <- "tourism"
OCC_ZOO_OSM_VALUE <- "zoo"
OCC_ZOO_DIST_M    <- GRID_CELL_M     # judgement value

# (5) Presence cells (e1). The functions build one rule only; a different
# value needs a new Decision and new code.
OCC_THIN_RULE <- "one_per_cell"

# (7) Background (g3): the same steps and values. ds_match = the dataset of
# the record holds at least this number of records of the tiger 1 km set.
OCC_BG_SAME_RULE       <- TRUE
OCC_BG_MATCH_MIN_TIGER <- 1L         # judgement value

# (8) Minimum number of tiger presence cells in the 1 km set (h2, k2):
#   below OCC_MIN_CELLS_MODEL          no 1 km suitability model; Week 14
#                                      starts with a Decision (no model, or a
#                                      model at a coarser grain)
#   OCC_MIN_CELLS_MODEL to FULL - 1    a reduced model: feature classes at
#                                      most OCC_REDUCED_MAX_CLASSES
#   OCC_MIN_CELLS_FULL or more         the planned model
# The outcome is stated in task 13.3 and does not change after that.
OCC_MIN_CELLS_MODEL     <- 25L   # van Proosdij et al. 2016 (judgement value)
OCC_MIN_CELLS_FULL      <- 80L   # the maxnet default adds product features
                                 # from 80 presences (judgement value)
OCC_REDUCED_MAX_CLASSES <- "lq"  # linear + quadratic (judgement value)

# Decision-21 point-8 OUTCOME (process choice r1, 2026-10-17). The STEP-13.2
# run of 2026-10-17 gave n_cells_1km = 17 -> "no_1km_model". scripts/08 stops
# if a run gives another outcome. Set by the recorded outcome in
# docs/methodology.md (Decision 21, "Outcome of point 8") — do not change it
# to test alternatives. Values: "no_1km_model", "reduced_model",
# "planned_model".
OCC_POINT8_OUTCOME <- "no_1km_model"

# Amendment 2 (2026-10-11, after the raw counts; process choice w1): the
# dataset check. For each dataset with a record in the 1 km or the 5 km set,
# the GBIF registry text (title, description, purpose, additional
# information, sampling description) is searched for these word parts (case
# is ignored). A hit stops the script before the clean layers are written,
# unless the dataset key is in OCC_DATASET_CLEARED. Judgement list.
OCC_DATASET_FLAG_WORDS <- c("degrad", "generali", "obscur", "fuzz", "withh",
                            "blur", "randomi", "coarse", "rounded",
                            "sensitiv", "approximat", "not precise")
# Datasets that the author read and cleared: names = datasetKey, value = the
# date, the decision and the reason (text). A dataset is added only by the
# author, after the script stops on it.
OCC_DATASET_CLEARED <- list(
  # Mammal occurrence in rainforest fragments of the Valparai Plateau and
  # Anamalai Tiger Reserve, Western Ghats, India (2005-06)
  "3732112e-848c-4fcc-b62d-e5acb9d12099" = paste(
    "2026-10-17: keep (k1). The word 'approximat' is in the method sentence:",
    "the position is the midpoint of a line transect, or comes from the name",
    "of a place, and each record has a coordinate uncertainty in metres.",
    "Step 6 uses that value. Cleared after the sets and the point-8 outcome",
    "of the first STEP-13.2 run were seen."),
  # The five background datasets below (choice e1, 2026-10-17) stopped the
  # first STEP-13.3 run. They were cleared after the background sets and the
  # taxa of that run were seen.
  # Mammal occurrence records from bird surveys and leopard study in the
  # Anamalai Hills, Western Ghats, India (1999-2020)
  "b045f965-8a06-4b9c-a1b1-a9b5a1628b52" = paste(
    "2026-10-17: keep (e1). 'degrad' is about degraded forest fragments (the",
    "habitat); 'approximat' is about the number of point counts, and about",
    "positions from a place name, which have a coordinate uncertainty in",
    "metres. The position is the start point of a line transect."),
  # Mammal occurrence along line transects for hornbill survey in the
  # Western Ghats, India (2005-06)
  "7528e073-dea9-4172-a1cb-27c684f2a4b5" = paste(
    "2026-10-17: keep (e1). The position is the approximate start point or",
    "midpoint of a line transect from GPS records; the coordinate",
    "uncertainty is based on the transect length and the position error."),
  # Fruiting trees and their bird and mammalian visitors and seed predators
  # in the Anamalai Hills, India
  "cf973c89-6819-4fc5-be56-c23f0119ff69" = paste(
    "2026-10-17: keep (e1). 'approximat' is about the annual rainfall. The",
    "entry has no sentence about the positions."),
  # India Roadkill Monitoring Project
  "f334ae5e-0991-44bb-b64b-d602f4c8c289" = paste(
    "2026-10-17: keep (e1). 'sensitiv' is about ecologically sensitive",
    "landscapes. Note: the publisher changed an uncertainty of 0 m to 30 m",
    "or 100 m, so such a record passes steps 5 and 6 with a value that the",
    "publisher assigned."),
  # Mammal occurrence along bird survey transects in the Dampa Tiger Reserve
  # landscape, Mizoram, northeast India (2014)
  "f896ef0c-7fad-44eb-bf56-b5dbe821fb5c" = paste(
    "2026-10-17: keep (e1). The position is the approximate midpoint of a",
    "line transect, with a coordinate uncertainty in metres (the sentence of",
    "the k1 dataset).")
)

# (9) Model sets for Week 14. Each sensitivity set changes ONE choice against
# `main`. `uncert` = the uncert_set values of the tiger cells and of the
# background; `bg_matched` = only the background records with ds_match TRUE.
OCC_MODEL_SETS <- list(
  main      = list(uncert = c("1km"),        bg_matched = FALSE),
  uncert5km = list(uncert = c("1km", "5km"), bg_matched = FALSE),
  matched   = list(uncert = c("1km"),        bg_matched = TRUE)
)

# ---- Stage 3: effort surfaces (Decision 22, 2026-10-17) ---------------------
# Fixed BEFORE any density surface is built and before any count by time
# window is made. See docs/methodology.md, Decision 22, for the sources, the
# reasons and what was seen. Fork codes: a2, p1, u2, b2, c2, d3, e2, f2, g1.
# scripts/08 STEP 13.4 (task 13.6) reads these; do not repeat the values as
# literals in any script.
#   surfaces = effort (clean Mammalia background), tiger (clean tiger
#              records), settlement (OSM city + town); all years 2006-2022
#   unit     = a complete-case 1 km cell with one or more inputs counts 1
#   value    = units per km2 after the edge correction; NA outside the
#              complete-case cells of cov_stack_1km_7755.tif
#   the tiger surface is never published or committed (g1)

# (1)-(2) Surfaces and records (a2, p1). The uncert_set values of the clean
# tiger and background layers that go into a surface (the 5 km sets). The
# matched background (ds_match) is not used. The obscured set is in no
# surface.
KDE_SURFACES     <- c("effort", "tiger", "settlement")
KDE_UNCERT_SETS  <- c("1km", "5km")

# (3) Unit (u2): "cell" = one count per complete-case 1 km cell with one or
# more records (or settlement points); the number in a cell is not a weight.
KDE_UNIT <- "cell"

# (4) Settlement classes (b2): OSM `place` values that are used. Villages are
# not used (OSM holds about 30 % of the Census-2011 villages).
KDE_SETTLEMENT_CLASSES <- c("city", "town")

# (5) Kernel and radius (c2). KDE_RADIUS_M is the SUPPORT radius: the quartic
# kernel K(d) = (1 - (d / R)^2)^2 is 0 at d >= R. On the grid, the weight of
# a cell is K at the distance between cell centres; the weights are scaled to
# a sum of 1 over the full disc. A tool that takes a standard deviation
# (spatstat `sigma`) must get KDE_SIGMA_M = R / sqrt(8), not R (checked in
# spatstat.explore 3.2.5: quartic, sigma 1 -> support radius 2.83).
KDE_KERNEL     <- "quartic"
KDE_RADIUS_M   <- 20000L                    # Phase-1 value (judgement)
KDE_SIGMA_M    <- KDE_RADIUS_M / sqrt(8)    # 7,071 m; derived, do not edit
KDE_RADII_QA_M <- c(10000L, 30000L)         # QA comparison only (c2); not an
                                            # input to any later step

# (6) Time windows (d3). The surfaces of point 1 use all years. The counts by
# window cover each clean set. Effort window surfaces (KDE_RADIUS_M only) for
# KDE_WINDOW_SURFACES, each built only if the window has KDE_WINDOW_MIN_UNITS
# units or more; otherwise the count only.
KDE_WINDOWS <- list(
  baseline = BASELINE_WINDOW,                                   # 2006-2010
  middle   = c(BASELINE_WINDOW[2] + 1L, CURRENT_WINDOW[1] - 1L), # 2011-2017
  current  = CURRENT_WINDOW                                     # 2018-2022
)
KDE_WINDOW_SURFACES  <- c("baseline", "current")   # effort surface only
KDE_WINDOW_MIN_UNITS <- 100L                       # judgement value

# (7) Edge rule (e2): "uniform" = the value of a cell is divided by the kernel
# mass of its disc that falls on window cells (the complete-case cells).
# Cells with a mass below KDE_EDGE_FLAG_MASS keep their value and are counted.
KDE_EDGE           <- "uniform"
KDE_EDGE_FLAG_MASS <- 0.5                          # judgement value

# (8) Gi* (f2): not built in Week 13; the Week-14 model Decision decides it.
# (2026-10-25: Decision 23 f2 decides it — see SDM_GISTAR_* below.)

# (9) Publication (g1). The tiger surface and its QA surfaces stay under
# data/ (gitignored). The published tiger product is the count by reserve
# (task 13.8); a count below KDE_SMALL_N is not published.
KDE_PUBLISH_TIGER <- FALSE
KDE_SMALL_N       <- 3L                            # warn_small_n() default

# ---- Stage 3: model at a coarser grain (Decision 23, 2026-10-25) ------------
# Fixed BEFORE any count of presence or background cells at a coarser grain
# and before any model. See docs/methodology.md, Decision 23, for the sources,
# the reasons and what was seen. Fork codes: a2, b3, v1, c1, r2, s1, m1, e1,
# f2. The Week-14 script (scripts/09, named in task 14.2) reads these; do not
# repeat the values as literals in any script.
#   model      = a maxnet model at a coarser grain (a2); there is no 1 km
#                model (OCC_POINT8_OUTCOME)
#   grain      = the cells of the iNaturalist obscuring grid: 0.2 x 0.2
#                degrees, edges at multiples of 0.2 degrees, in EPSG:4326
#                (b3); not an aggregate of the 1 km template
#   presences  = the obscured set (Decision 21 point 4); one per model cell
#   background = the clean iNaturalist Mammalia records (r2, s1): the
#                obscured background and the iNaturalist records of the 5 km
#                background; one per model cell
#   minimum    = the limits of Decision 21 point 8 for the presence cells
#                (c1), and SDM_BG_MIN_RATIO x the presence cells for the
#                background (m1); below either limit there is no model, and
#                Stage 3 gives the effort result

# (1)-(2) Model, input set and grain (a2, b3). The cell of a record is its
# EPSG:4326 coordinates rounded down to a multiple of SDM_GRAIN_DEG (the rule
# of Decision 21 point 4). The value 0.2 comes from the iNaturalist code
# (uncertainty_cell_center_latlon); it is not a judgement value.
SDM_MODEL        <- "coarse_grain"
SDM_PRESENCE_SET <- "obscured"
SDM_GRAIN_DEG    <- OCC_OBSCURED_CELL_DEG   # 0.2
SDM_GRAIN_CRS    <- CRS_WGS84               # the cells are in longitude and
                                            # latitude

# (3) Model cells (v1). A 0.2 degree cell is a model cell if the complete-case
# 1 km cells of cov_stack_1km_7755.tif that have their centre inside the cell
# polygon cover this share of the polygon area or more (both areas in
# EPSG:7755 units). Only a model cell can be a presence, background or
# prediction cell.
SDM_CELL_MIN_COVER <- 0.5                   # judgement value

# (4) Minimum number of presence cells (c1): the limits of Decision 21 point
# 8, applied to the presence cells after point 3. No new value.
#   below SDM_MIN_CELLS                no model; Stage 3 gives the effort
#                                      result; no other grain is tried
#   SDM_MIN_CELLS to FULL - 1          a reduced model: feature classes at
#                                      most SDM_REDUCED_MAX_CLASSES
#   SDM_MIN_CELLS_FULL or more         the planned model (Decision 24)
SDM_MIN_CELLS           <- OCC_MIN_CELLS_MODEL      # 25
SDM_MIN_CELLS_FULL      <- OCC_MIN_CELLS_FULL       # 80
SDM_REDUCED_MAX_CLASSES <- OCC_REDUCED_MAX_CLASSES  # "lq"

# (5) Background (r2, s1). Only records of the iNaturalist dataset; all
# Mammalia except the tiger (Decision 5). The target group does not change,
# so the Decision-22 effort surfaces are not built again. Two parts:
#   obscured = the background records that pass steps 1-5 of Decision 21 and
#              the obscured rule of its point 4 (counted in Week 13, not
#              kept on disk: a new output, task 14.2)
#   uncert   = the records of the clean background with these uncert_set
#              values (the 5 km background), each in the cell of its own
#              coordinates
SDM_BG_DATASET_KEY <- OCC_INAT_DATASET_KEY
SDM_BG_OBSCURED    <- TRUE
SDM_BG_UNCERT_SETS <- c("1km", "5km")
SDM_BG_SCOPE       <- "Mammalia"            # s1: no taxon is removed

# (6) Minimum size of the background (m1): the background cells (after point
# 3, before maxnet adds a presence cell to the background) must be at least
# SDM_BG_MIN_RATIO x the presence cells. Below it: no model, as in point 4.
SDM_BG_MIN_RATIO <- 10L                     # judgement value

# Outcome of points 4 and 6 (point 4 is tested first). Task 14.4 states the
# outcome and locks it in this file, as OCC_POINT8_OUTCOME. It does not
# change after that.
SDM_OUTCOME_VALUES <- c("no_model_presence", "no_model_background",
                        "reduced_model", "planned_model")

# The outcome lock (process choice l1 of task 14.2, 2026-10-25). NA until the
# count of task 14.4 (scripts/09 STEP 14.1). While it is NA, scripts/09 stops
# at the end of STEP 14.1. After it is set, scripts/09 stops if a run gives
# another outcome, and the fit STEPs run only with "reduced_model" or
# "planned_model". Set it only to the outcome recorded in docs/methodology.md
# (Decision 23, "Outcome of points 4 and 6"); do not change it to test
# alternatives.
# 2026-10-25 (task 14.4): the STEP-14.1 run gave 104 presence cells and
# 1,486 background cells on model cells (minimum 1,040) -> "planned_model".
SDM_GRAIN_OUTCOME <- "planned_model"

# (7) The Facebook dataset (e1). With b3 this dataset gives no record to the
# model. The QA counts its records in the presence set and in the background;
# each count must be 0. "Bengal Tiger (Panthera tigris) Sighting based on
# Photographs from Facebook in India".
SDM_CHECK_ABSENT_DATASETS <- c("ff8a7785-27c8-4162-907e-658e28a09ba1")

# (8) Gi* and the ratio (f2). A Gi* of the effort and a Gi* of the tiger
# records (the Phase-1 form) are built. Their settings are a numbered
# Decision in Week 15 or 16, before any Gi* is computed. The tiger Gi* is
# never published and never committed. No ratio of the tiger and effort
# surfaces (if task 14.4 gives no model, the Gi* Decision decides the ratio).
# (2026-11-07: Decision 26 fixes the Gi* settings: the GISTAR_* block below.
# x1: no Phase-1 form and no comparison with Phase 1.)
SDM_GISTAR_SETS          <- c("effort", "tiger")
SDM_GISTAR_PUBLISH_TIGER <- FALSE
SDM_RATIO                <- FALSE

# ---- Stage 3: model settings (Decision 24, 2026-10-25) ----------------------
# Fixed after the count of task 14.4 and BEFORE any covariate summary at 0.2
# degrees, any correlation, any model and any prediction. See
# docs/methodology.md, Decision 24, for the sources, the reasons and what was
# seen. Fork codes: c1, z1, k1, f3, b1 (b2 as a sensitivity run), a1, v1,
# g2, r3, s3, m1. scripts/09 STEP 14.2 (task 14.5) and STEP 14.3 (task 14.6)
# read these; the gate and the reserve check are applied in Week 15. Do not
# repeat the values as literals in any script.

# (1) Covariates (c1): the nine candidates. Each is a summary over the
# complete-case 1 km cells of a model cell (sdm_cellid_1km_7755.tif):
#   ghm_mean, elev_mean, slope_mean, tri_mean  the mean of the band (point 2
#                                              for the three terrain bands)
#   droad_km_mean                              the mean of dist_road_m / 1000
#   lc_*                                       the share of the cells of the
#                                              land-cover classes below
SDM_COVARIATES <- c("ghm_mean", "elev_mean", "slope_mean", "tri_mean",
                    "droad_km_mean", "lc_forest", "lc_open", "lc_crop",
                    "lc_built")
SDM_LC_GROUPS <- list(
  lc_forest = c(10L, 95L),        # tree cover, mangroves
  lc_open   = c(20L, 30L, 90L),   # shrubland, grassland, herbaceous wetland
  lc_crop   = c(40L),             # cropland
  lc_built  = c(50L)              # built-up
)                                 # 60, 70, 80, 100: the rest (no covariate)

# (2) Water and negative elevation (z1): the terrain means do not use the
# cells of this class; on the cells that they use, an elevation below
# SDM_ELEV_MIN_M becomes SDM_ELEV_MIN_M. A model cell with water cells only
# gets the means of its water cells, with the same elevation floor.
SDM_TERRAIN_BANDS <- c("elev", "slope", "tri")
SDM_WATER_CLASS   <- 80L          # WorldCover: permanent water bodies
SDM_ELEV_MIN_M    <- 0            # judgement value (lowest land about -2 m)

# (3) Collinearity (k1): Pearson r on all model cells; the candidates in this
# order; a candidate is kept if its |r| with each kept candidate is
# SDM_COR_MAX or less.
SDM_COR_MAX      <- 0.7           # Dormann et al. 2013 (judgement value)
SDM_COV_PRIORITY <- c("ghm_mean", "lc_forest", "elev_mean", "slope_mean",
                      "tri_mean", "lc_crop", "lc_open", "droad_km_mean",
                      "lc_built")

# (4) Feature classes and regularisation (f3): the grid, the AICc rule
# (Warren & Seifert 2011; raw output scaled to a sum of 1 over the model
# cells; K = non-zero coefficients; no AICc if K >= n - 1), and the choice:
# within SDM_AICC_DELTA of the lowest AICc, the fewest coefficients, then the
# lower AICc.
SDM_FC_GRID      <- c("lq", "lqh", "lqph")
SDM_REGMULT_GRID <- c(1, 2, 3, 4)
SDM_AICC_DELTA   <- 2             # judgement value

# (5)-(6) Bias input (b1) and the background (a1).
SDM_BIAS_MAIN   <- "none"         # b1: the target-group background only
SDM_ADD_SAMPLES <- TRUE           # a1: maxnet addsamplestobackground

# (7) Evaluation (v1): 2 x 2 degree blocks (edges at multiples of 2 degrees),
# 5 folds by the serpentine order of Decision 24 point 7; cloglog output with
# clamping; the continuous Boyce index (window 1/10 of the prediction range,
# 100 points), the test AUC, OR10, AUCdiff.
SDM_CV_BLOCK_DEG <- 2             # judgement value
SDM_CV_K         <- 5L            # judgement value
SDM_EVAL_TYPE    <- "cloglog"
SDM_BOYCE_WINDOW <- 0.1           # Hirzel et al. 2006
SDM_BOYCE_RES    <- 100L
SDM_OR_QUANTILE  <- 0.10          # OR10

# (8) The gate (g2), applied in Week 15: a mean test Boyce index of
# SDM_BOYCE_GATE or below -> not published as a suitability map.
SDM_BOYCE_GATE <- 0

# (9) The reserve check (r3), run in Week 15: r1 the Spearman rho of the
# reserve value and density_2022 ("agrees" if rho > 0 and p < SDM_RESERVE_P);
# r2 the reserves with no presence cell (counts and a share only; no reserve
# name with a presence state).
# (2026-10-31: Decision 25 point 8 reads which 1 km cells are used —
# SDM_RESERVE_CELL_RULE and SDM_RESERVE_NONMODEL below.)
SDM_RESERVE_CHECK <- c("census_density", "no_presence_reserves")
SDM_RESERVE_P     <- 0.05         # judgement value

# (10) Sensitivity runs (s3) and the comparison rule ("robust" if rho >=
# SDM_SENS_RHO_MIN and the overlap of the top SDM_SENS_TOP_SHARE cells >=
# SDM_SENS_OVERLAP_MIN; otherwise "sensitive").
SDM_SENS_RUNS        <- c("bias_settlement", "window_2018_2022")
SDM_SENS_BIAS_FIX    <- "median"  # the bias covariate at prediction
SDM_SENS_WINDOW      <- CURRENT_WINDOW               # 2018-2022
SDM_SENS_RHO_MIN     <- 0.9       # the value of Decisions 18 to 20
SDM_SENS_TOP_SHARE   <- 0.2       # judgement value
SDM_SENS_OVERLAP_MIN <- 2 / 3     # the value of Decisions 18 to 20

# (11) Model file (m1): save_model(..., species = SDM_MODEL_NAME[["species"]],
# model = SDM_MODEL_NAME[["model"]], dir = SDM_MODEL_DIR) ->
# data/processed/tiger_sdm_maxnet_cell02_<date>.rds (gitignored).
SDM_MODEL_DIR  <- DIR_PROCESSED
SDM_MODEL_NAME <- c(species = "tiger", model = "sdm_maxnet_cell02")

# ---- Stage 3: QA of the model (task 14.6, 2026-10-25) -----------------------
# scripts/09 STEP 14.3 computes the main numbers again by a second path
# (process choice c1). Two values agree if |a - b| <= SDM_QA_REL_TOL x
# max(1, |b|). A point agrees with its 0.2 degree cell if it is in the cell
# widened by SDM_QA_DEG_TOL degrees on each side (the round trip of the
# projection EPSG:7755 -> EPSG:4326). Check tolerances, not analysis values.
SDM_QA_REL_TOL <- 1e-9
SDM_QA_DEG_TOL <- 1e-7

# ---- Stage 3: prediction and publication (Decision 25, 2026-10-31) ----------
# Fixed BEFORE any prediction is written to a file or seen. See
# docs/methodology.md, Decision 25, for the sources, the reasons and what was
# seen. Fork codes: a1, b2, c1 (n5), d1, e1, f3 (two figures), t1, h1;
# point 9 (task 15.2): y1, z1. scripts/09 (Week 15) and the Week-16 figure code read these; do not repeat
# the values as literals in any script.
#   cells  = the 6,969 model cells only (Decision 23 point 3)
#   value  = cloglog with clamping, from the model file named below
#   flag   = out of range: one or more covariates below varmin or above
#            varmax of the model object (a value at a limit is inside)
#   class  = K - floor(K x (r - 1) / n); r = the rank of the value (1 = the
#            highest; a tie to the lower cell id); n = the model cells
#   output = two static figures, a reserve table and tables of statistics;
#            no layer before the Week-18 rule (pending "Published layers")

# (1) Model file, output type and clamping (a1). The file of the record, not
# a model that a run fits again (each run of scripts/09 writes one more dated
# file: process choice w1 of task 14.5). The file is in SDM_MODEL_DIR.
SDM_PRED_MODEL_FILE <- "tiger_sdm_maxnet_cell02_20261025.rds"
SDM_PRED_TYPE       <- SDM_EVAL_TYPE      # "cloglog"
SDM_PRED_CLAMP      <- TRUE               # the predict.maxnet() default

# (2) Cells outside the training range (b2). Each model cell gets the flag;
# the counts are reported (all cells; for each covariate, below varmin and
# above varmax). No limit on the counts. The reserve check uses the clamped
# values of all cells.
SDM_PRED_FLAG_RANGE <- TRUE

# (3) Classes (c1, n5): equal-count classes by rank. Class K holds the
# highest values; with n = 6,969: 1,394 cells in each of classes 5 to 2,
# 1,393 in class 1. Class K = the top-SDM_SENS_TOP_SHARE set of
# sdm_compare(). The legend gives the classes by rank and no value.
SDM_PUB_N_CLASSES  <- 5L                  # judgement value (range 3 to 7)
SDM_PUB_CLASS_RULE <- "rank_equal_count"  # the one rule that the code builds

# (4) Published form (d1). No layer in Week 15: the prediction layer (cell
# id, value, class, flag; no presence or background field) stays under
# data/processed/ (gitignored). Tier T1 (sensitive-data policy section 2).
SDM_PUB_LAYER <- FALSE

# (5) Caption (e1): the nine items of Decision 25 point 5; drafted in Week
# 16 and marked as a draft. No setting.

# (6) Figures (f3: two figures), at national scale, with the reserve
# outlines and the state boundaries; no presence or background mark. The
# slugs are set in Week 16 (a slug does not hold "tiger").
SDM_PUB_FIG_CLASS   <- 4L                 # fig_04_<slug>.png: the classes
SDM_PUB_FIG_VALUE   <- 5L                 # fig_05_<slug>.png: the value
SDM_PUB_VALUE_LABEL <- paste("model output (cloglog), relative;",
                             "not a probability of presence")
SDM_PUB_HATCH       <- TRUE               # the flag of (2), on both figures

# (7) Reserve table (t1): one row for each reserve of
# boundary_reserves_all_7755.gpkg (58 rows; key unit_id): unit_id,
# unit_name, state, the reserve value and its rank, density_2022, the 1 km
# cells used, the 1 km cells with no value. No presence column. Number,
# slug, column names, rounding and the tie rule of the rank: task 15.2.
# (2026-10-31, task 15.2: tbl_17_reserve_suitability.csv (n1); the columns
# of k1 with landscape_complex; full precision; SDM_PUB_RANK_TIES below.)
SDM_PUB_RESERVE_TABLE <- TRUE

# (8) Cells of the reserve check (h1; a reading of Decision 24 point 9). A
# complete-case 1 km cell is inside a polygon if its centre is inside it or
# on its edge. A 1 km cell whose 0.2 degree cell is not a model cell has no
# value: it is left out of the mean and counted for each reserve. A reserve
# with no cell that has a value gets no value and is not in r1 or r2.
SDM_RESERVE_CELL_RULE <- "centre"
SDM_RESERVE_NONMODEL  <- "exclude_and_count"

# (9) The presence state of a reserve in the published outputs (y1, z1;
# added 2026-10-31 in task 15.2, before any result).
#   r2  (y1): over the reserves with a value, the 2 x 2 count (value above the
#             median of the model cells or not x with or without a presence
#             cell). r2 is published only if each of the four counts is
#             SDM_PUB_R2_MIN_N or more; 0 is also below the limit. Otherwise
#             the table, the console and the docs say "r2 not published" and
#             give no count.
#   z1      : the reserves with a polygon whose 1 km cells with a value are
#             all outside the training range, or that have no 1 km cell
#             with a value. The QA count must be 0; otherwise the script
#             stops and the author decides. No setting.
SDM_PUB_R2_MIN_N <- KDE_SMALL_N           # 3, the value of Decision 22 point 9

# Process choices of task 15.2 (2026-10-31) that set a value:
#   k1  the rank of the reserve value in the reserve table: a tie gets the
#       lowest rank number (base::rank(-x, ties.method = SDM_PUB_RANK_TIES))
#   p1  the p-value of r1: stats::cor.test(method = "spearman", exact =
#       SDM_RESERVE_P_EXACT) in each case, with or without ties
SDM_PUB_RANK_TIES   <- "min"
SDM_RESERVE_P_EXACT <- FALSE

# ---- Stage 3: Gi* (Decision 26, 2026-11-07) ----------------------------------
# Fixed BEFORE any Gi* is computed and before any neighbour list is made. See
# docs/methodology.md, Decision 26, for the sources, the reasons and what was
# seen. Fork codes: x1, a3, b1 (C1-2), c1, d1 (k1, q2), e1, m1, f1, s2 (L1,
# S-a), w1, g1. scripts/09 (Week 16) reads these; do not repeat the values as
# literals in any script.
#   aim    = each tiger Gi* against the effort Gi* of its observer group; no
#            comparison with Phase 1 (x1)
#   cells  = the 6,969 model cells (Decision 23 point 3); the value of a cell
#            is 1 if it holds one or more records of the input, else 0 (c1)
#   window = the cell and its neighbours within GISTAR_BAND_KM (distance
#            between cell centres on the sphere, GISTAR_DIST, Amendment 1;
#            binary weights; the cell itself included)
#   p      = exact under random relabelling: K_i ~ hypergeometric(n cells,
#            M cells with 1, n_i cells in the window); two-sided p =
#            min(1, 2 x min(P(K >= K_i), P(K <= K_i))) (e1)
#   class  = hot / cold: BH-adjusted p <= GISTAR_FDR_Q and K_i above / below
#            its expectation; not_significant; few_neighbours (k1) (m1)
#   the tiger Gi* are never published or committed (SDM_GISTAR_PUBLISH_TIGER)

# (1)-(2) The four Gi* (x1, a3, b1, C1-2): the input of each and the Gi* it
# is compared with.
#   effort_inat    the background cells of Decision 23 point 5 (iNaturalist,
#                  parts a and b) BEFORE maxnet adds a presence cell: no
#                  presence cell in an effort input
#   tiger_obscured the obscured set (Decision 21 point 4)
#   effort_all     the clean background of all datasets, uncert_set in
#                  GISTAR_UNCERT_SETS (the input of the Decision-22 effort
#                  surface)
#   tiger_5km      the clean tiger records, uncert_set in GISTAR_UNCERT_SETS
# A record of effort_all or tiger_5km goes into the 0.2 degree cell of its
# own coordinates (the rule of Decision 21 point 4); a record in a cell that
# is not a model cell is not used and is counted.
GISTAR_RUNS <- data.frame(
  gistar  = c("effort_inat", "tiger_obscured", "effort_all", "tiger_5km"),
  compare = c("tiger_obscured", "effort_inat", "tiger_5km", "effort_all"),
  tiger   = c(FALSE, TRUE, FALSE, TRUE),
  stringsAsFactors = FALSE
)
GISTAR_UNCERT_SETS <- KDE_UNCERT_SETS     # c("1km", "5km"): the 5 km sets

# (3) Cells and value (c1).
GISTAR_CELLS <- "model"                   # the model cells of Decision 23
GISTAR_VALUE <- "binary"                  # 1 = one or more records

# (4) Neighbours and band (d1, k1). The distance is on the sphere (GISTAR_DIST,
# Amendment 1); an inner cell has 20 neighbours at 6-37 degrees N; the script
# counts them. A cell with fewer than
# GISTAR_MIN_NEIGHBOURS neighbours (the cell itself not counted) gets the
# class "few_neighbours"; its value stays in the windows of the other cells.
GISTAR_BAND_KM        <- 50               # judgement value
GISTAR_SELF           <- TRUE             # Gi* (star): w_ii = 1
GISTAR_MIN_NEIGHBOURS <- 8L               # Esri guidance (judgement value)

# (5) QA bands (q2): descriptive only; no rule uses them. "queen" = the 8
# cells around a cell by the cell index (ix, iy) that are model cells. k1
# and m1 apply to each QA band separately.
GISTAR_QA_BANDS <- list(queen = "queen", band75_km = 75)   # judgement values

# (6) Test and correction (e1, m1), for each Gi* and each band separately.
GISTAR_TEST     <- "exact_relabel"        # stats::phyper; no random number
GISTAR_P_ADJUST <- "BH"                   # stats::p.adjust(method = )
GISTAR_FDR_Q    <- 0.05                   # judgement value
GISTAR_CLASSES  <- c("hot", "cold", "not_significant", "few_neighbours")

# (7) Publication (f1, s2 with L1 and S-a). fig_06 = the effort_inat Gi*
# (tier T1: the source obscured part of its input). effort_all: in the
# statistics table only (the chat's reading of C1-2). The tiger Gi*: counts
# only (s1); for tiger_5km also the hot cells by landscape complex (s2) by
# rule L1: a hot cell counts for a complex if one or more of its
# complete-case 1 km cells has its centre in a reserve polygon of that
# complex (Decision 25 point 8); otherwise "outside the reserve polygons".
GISTAR_PUB_FIG         <- 6L              # fig_06_<slug>.png
GISTAR_PUB_FIG_GISTAR  <- "effort_inat"
GISTAR_PUB_TABLE_ONLY  <- "effort_all"
GISTAR_TIGER_STATEMENT <- c(tiger_obscured = "s1", tiger_5km = "s2")
GISTAR_LANDSCAPE_RULE  <- "centre_any"    # L1

# (8)-(9) Time window (w1) and code (g1).
GISTAR_YEARS <- c(BASELINE_YEAR, CURRENT_YEAR)   # 2006-2022: all years
GISTAR_CODE  <- "own"                     # base R and sf; no new package

# Process choices of task 16.2 (2026-11-07) that set a value, and Amendment 1
# of Decision 26 (A1):
#   A1  the distance between two cells: the great-circle distance (haversine)
#       on a sphere of radius GISTAR_EARTH_RADIUS_KM between the cell
#       centres in longitude and latitude; for the main band, the 75 km QA
#       band and both QA paths (was: in the analysis CRS)
#   p1  the centre of a cell: ((ix + 0.5) x SDM_GRAIN_DEG, (iy + 0.5) x
#       SDM_GRAIN_DEG) in longitude and latitude
#   n1  the four Gi* layers in DIR_PROCESSED (gitignored; no geometry)
#   t1  tbl_18_gistar.csv (publishable) and tbl_18_gistar_qa.csv
#   g1  the figure slugs (no "tiger")
#   z1  the size and the resolution of fig_03
#   c1  the palette of fig_04 and fig_05 (a viridisLite option); the fig_06
#       colours are set in task 16.4
#   h1  the hatch lines in each cell, and the position of the key box (a
#       share of the extent of the state layer: x from the west side, y
#       from the south side). Start values; tuned in task 16.4
#   q1  the permutation check of the exact p (QA only)
GISTAR_DIST            <- "sphere"        # A1
GISTAR_EARTH_RADIUS_KM <- 6371.0088       # (2a + b) / 3 of WGS 84
GISTAR_CENTRE          <- "lonlat_index"  # p1
GISTAR_LAYER_FILES <- c(
  effort_inat    = "hot_effort_inat_cell02.csv",
  tiger_obscured = "hot_tiger_obscured_cell02.csv",
  effort_all     = "hot_effort_all_cell02.csv",
  tiger_5km      = "hot_tiger_5km_cell02.csv"
)
GISTAR_TABLE_NN      <- 18L
GISTAR_TABLE_SLUG    <- "gistar"          # tbl_18_gistar.csv
GISTAR_QA_TABLE_SLUG <- "gistar_qa"       # tbl_18_gistar_qa.csv
SDM_PUB_FIG_CLASS_SLUG <- "suitability_classes"   # fig_04
SDM_PUB_FIG_VALUE_SLUG <- "suitability_value"     # fig_05
GISTAR_PUB_FIG_SLUG    <- "effort_gistar"         # fig_06
FIG_STAGE3_SIZE_IN <- PINCH_FIG_SIZE_IN   # 11 x 10.6 inches, as fig_03
FIG_STAGE3_DPI     <- PINCH_FIG_DPI       # 200, as fig_03
FIG_STAGE3_PALETTE <- "viridis"           # viridisLite option
FIG_HATCH_LINES_PER_CELL <- 3L            # start value (task 16.4)
FIG_HATCH_KEY_POS  <- c(x = 0.60, y = 0.36)   # start value (task 16.4)
GISTAR_QA_PERM_N     <- 9999L             # total relabellings
GISTAR_QA_PERM_CELLS <- 20L               # sample cells for each Gi*
GISTAR_QA_PERM_LEVEL <- 0.999             # the binomial interval
GISTAR_QA_SEED       <- 20261107L         # a fixed seed (QA only)

# ---- Convenience -----------------------------------------------------------
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
