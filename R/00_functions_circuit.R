# =============================================================================
# 00_functions_circuit.R
# The SDM-based resistance and the circuit-theory check of Decision 27
# (2026-11-14). scripts/10_check_sdm_connectivity.R sources this file
# (process choice f1 of task 17.2). The settings are the SDMRES_* values of
# R/00_config.R; no value of the analysis is written here as a literal.
#
# Task 17.3 (2026-11-14): STEP 17.1 — the two surfaces, the graph of the
# model cells and the cells of the reserves (Decision 27 points 1 to 3).
#   circ_check_config()     the SDMRES_* block (Decision 27; task 17.2)
#   circ_rank_to_x()        the input x from the rank (point 1, a2)
#   circ_transform()        x -> resistance, linear or negative exponential
#                           (point 2, b3)
#   circ_surface()          one surface layer: id, x, resistance
#   circ_surface_checks()   the checks of a surface layer
#   circ_links()            the links of the graph: 8 neighbours among the
#                           model cells, with the length on the sphere
#                           (point 3, c1)
#   circ_link_resistance()  d x (R_i + R_j) / 2 for each link (point 3)
#   circ_components()       the connected sets of the graph (igraph)
#   circ_reserve_cells()    the model cells of each reserve (centre rule)
#   circ_pair_status()      contiguous at 0.2 degrees, no path, or path
#   circ_surface_summary()  the table tbl_19_sdmres_surface.csv
#   circ_self_test_171()    the hand-made case of STEP 17.1 (h1 of 17.2)
# Task 17.4 adds the circuit solver, the least-cost paths and the checks of
# Decision 27 point 5.
#
# SENSITIVE DATA: these functions return TRUE/FALSE, counts, statistics and
# the layers (cell ids and values). None of them prints a coordinate, a cell
# corner or a cell id. A surface holds no presence or background field.
# =============================================================================

# ---- The SDMRES_* block (Decision 27; task 17.2) ------------------------------
SDMRES_NEEDED <- c(
  "SDMRES_INPUT", "SDMRES_HATCHED", "SDMRES_R_MIN", "SDMRES_R_MAX",
  "SDMRES_SURFACES", "SDMRES_NEGEXP_C", "SDMRES_GRAIN", "SDMRES_NEIGHBOURS",
  "SDMRES_LINK_RULE", "SDMRES_RESERVE_CELL_RULE", "SDMRES_METHODS",
  "SDMRES_FOCAL_CURRENT", "SDMRES_TOOL", "SDMRES_CHECK_TOL_REL",
  "SDMRES_PHASE1_PAIRS", "SDMRES_PHASE2_PAIRS", "SDMRES_PHASE2_SURFACES",
  "SDMRES_PHASE2_PATHS", "SDMRES_COMPARE_SURFACE",
  "SDMRES_COMPARE_ROUTE_D_KM", "SDMRES_COMPARE_ROUTE_D_DESCR_KM",
  "SDMRES_COMPARE_ROUTE_MATERIAL", "SDMRES_COMPARE_RANK_MATERIAL",
  "SDMRES_COMPARE_MAX_SHARE", "SDMRES_COMPARE_MIN_RHO",
  "SDMRES_COMPARE_LABELS", "SDMRES_TOP_CURRENT_SHARE",
  "SDMRES_PAIRRULE_MIN_SHARE", "SDMRES_PAIRRULE_LABELS",
  "SDMRES_FIG07_PHASE", "SDMRES_PUB_LAYER", "SDMRES_PUB_FIGS",
  "SDMRES_FIG_N_CLASSES", "SDMRES_FIG08_BACKGROUND", "SDMRES_LAYER_SURFACE",
  "SDMRES_LAYER_PATHS", "SDMRES_LAYER_CURRENT", "SDMRES_TABLE_NN",
  "SDMRES_TABLE_SLUGS", "SDMRES_FIG_SLUGS",
  # earlier settings that Decision 27 uses
  "SDM_GRAIN_DEG", "SDM_RESERVE_CELL_RULE", "GISTAR_DIST",
  "GISTAR_EARTH_RADIUS_KM", "LCP_COMPARE_ROUTE_MATERIAL",
  "LCP_COMPARE_RANK_MATERIAL", "LCP_COMPARE_ROBUST_MAX_SHARE",
  "LCP_COMPARE_ROBUST_MIN_RHO", "SDM_SENS_TOP_SHARE",
  "NET_COMPARE_ROBUST_MIN_RETENTION", "SDM_PUB_N_CLASSES",
  "LCP_VALIDATE_TOL_REL", "NET_EXPECTED_RESERVES"
)

# Returns a named list of TRUE/FALSE checks (for sdm_run_guards()). Stops
# first if a setting is missing.
circ_check_config <- function() {
  miss <- SDMRES_NEEDED[!vapply(SDMRES_NEEDED, exists, logical(1))]
  if (length(miss) > 0) {
    stop("Setting(s) missing from R/00_config.R (Decision 27; task 17.2): ",
         paste(miss, collapse = ", "), call. = FALSE)
  }
  one_num <- function(v) is.numeric(v) && length(v) == 1L && !is.na(v)
  slugs <- c(SDMRES_TABLE_SLUGS, SDMRES_FIG_SLUGS)
  list(
    "SDMRES_INPUT must be rank (Decision 27 a2)" =
      identical(SDMRES_INPUT, "rank"),
    "SDMRES_HATCHED must be keep_and_count (Decision 27 k1)" =
      identical(SDMRES_HATCHED, "keep_and_count"),
    "SDMRES_R_MIN and SDMRES_R_MAX must be numbers with 0 < R_MIN < R_MAX (Decision 27 point 2)" =
      one_num(SDMRES_R_MIN) && one_num(SDMRES_R_MAX) && SDMRES_R_MIN > 0 &&
      SDMRES_R_MIN < SDMRES_R_MAX,
    "SDMRES_SURFACES must be main = linear and negexp8 = negexp (Decision 27 b3)" =
      identical(SDMRES_SURFACES, c(main = "linear", negexp8 = "negexp")),
    "SDMRES_NEGEXP_C must be a number above 0 (Decision 27 b2)" =
      one_num(SDMRES_NEGEXP_C) && SDMRES_NEGEXP_C > 0,
    "SDMRES_GRAIN must be cell02_model (Decision 27 c1)" =
      identical(SDMRES_GRAIN, "cell02_model"),
    "SDMRES_NEIGHBOURS must be 8 (Decision 27 c1)" =
      identical(SDMRES_NEIGHBOURS, 8L),
    "SDMRES_LINK_RULE must be dist_x_mean (Decision 27 point 3)" =
      identical(SDMRES_LINK_RULE, "dist_x_mean"),
    "GISTAR_DIST must be sphere (Decision 26 Amendment 1)" =
      identical(GISTAR_DIST, "sphere"),
    "SDMRES_RESERVE_CELL_RULE must be SDM_RESERVE_CELL_RULE, centre (Decision 25 h1)" =
      identical(SDMRES_RESERVE_CELL_RULE, SDM_RESERVE_CELL_RULE) &&
      identical(SDMRES_RESERVE_CELL_RULE, "centre"),
    "SDMRES_METHODS must be circuit and lcp (Decision 27 d3)" =
      identical(SDMRES_METHODS, c("circuit", "lcp")),
    "SDMRES_FOCAL_CURRENT must be zero (Decision 27 Z1)" =
      identical(SDMRES_FOCAL_CURRENT, "zero"),
    "SDMRES_TOOL must be own (Decision 27 t1)" =
      identical(SDMRES_TOOL, "own"),
    "SDMRES_CHECK_TOL_REL must be LCP_VALIDATE_TOL_REL (Decision 27 point 5)" =
      identical(SDMRES_CHECK_TOL_REL, LCP_VALIDATE_TOL_REL),
    "the phases must be decision17 and all_reserves (Decision 27 e1, e3)" =
      identical(SDMRES_PHASE1_PAIRS, "decision17") &&
      identical(SDMRES_PHASE2_PAIRS, "all_reserves"),
    "phase 2 must run on both surfaces, with paths (Decision 27 P1b)" =
      identical(SDMRES_PHASE2_SURFACES, names(SDMRES_SURFACES)) &&
      identical(SDMRES_PHASE2_PATHS, TRUE),
    "the comparison must use the Stage-2 baseline and the Decision-18 limits (Decision 27 f1)" =
      identical(SDMRES_COMPARE_SURFACE, "baseline") &&
      identical(SDMRES_COMPARE_ROUTE_MATERIAL, LCP_COMPARE_ROUTE_MATERIAL) &&
      identical(SDMRES_COMPARE_RANK_MATERIAL, LCP_COMPARE_RANK_MATERIAL) &&
      identical(SDMRES_COMPARE_MAX_SHARE, LCP_COMPARE_ROBUST_MAX_SHARE) &&
      identical(SDMRES_COMPARE_MIN_RHO, LCP_COMPARE_ROBUST_MIN_RHO),
    "SDMRES_COMPARE_ROUTE_D_KM must be a number in SDMRES_COMPARE_ROUTE_D_DESCR_KM" =
      one_num(SDMRES_COMPARE_ROUTE_D_KM) && SDMRES_COMPARE_ROUTE_D_KM > 0 &&
      SDMRES_COMPARE_ROUTE_D_KM %in% SDMRES_COMPARE_ROUTE_D_DESCR_KM,
    "SDMRES_TOP_CURRENT_SHARE must be SDM_SENS_TOP_SHARE (Decision 27 f1)" =
      identical(SDMRES_TOP_CURRENT_SHARE, SDM_SENS_TOP_SHARE),
    "SDMRES_PAIRRULE_MIN_SHARE must be NET_COMPARE_ROBUST_MIN_RETENTION (Decision 27 P2c)" =
      identical(SDMRES_PAIRRULE_MIN_SHARE, NET_COMPARE_ROBUST_MIN_RETENTION),
    "SDMRES_FIG07_PHASE must be phase1 (Decision 27 P3a)" =
      identical(SDMRES_FIG07_PHASE, "phase1"),
    "SDMRES_PUB_LAYER must be FALSE (Decision 27 point 10)" =
      identical(SDMRES_PUB_LAYER, FALSE),
    "SDMRES_FIG08_BACKGROUND must be plain (Decision 27 F2)" =
      identical(SDMRES_FIG08_BACKGROUND, "plain"),
    "SDMRES_PUB_FIGS must be current = 7 and paths = 8 (Decision 27 g3)" =
      identical(SDMRES_PUB_FIGS, c(current = 7L, paths = 8L)),
    "SDMRES_TABLE_NN must be 19 (n1 of task 17.2)" =
      identical(SDMRES_TABLE_NN, 19L),
    "no table or figure slug may hold the word tiger" =
      !any(grepl("tiger", slugs, ignore.case = TRUE))
  )
}

# ---- Point 1 (a2): the input x ---------------------------------------------------
# x = (n - rank) / (n - 1). rank 1 (the highest value) gives x = 1; rank n
# gives x = 0. The ranks must be 1 to n, each once (Decision 25 point 3).
circ_rank_to_x <- function(rank, n = length(rank)) {
  if (n < 2L || length(rank) != n || anyNA(rank) ||
      !setequal(rank, seq_len(n)) || anyDuplicated(rank)) {
    stop("circ_rank_to_x(): the ranks must be 1 to n, each once (n >= 2).",
         call. = FALSE)
  }
  (n - rank) / (n - 1)
}

# ---- Point 2 (b3): x -> resistance ----------------------------------------------
#   linear : R = r_min + (r_max - r_min) * (1 - x)
#   negexp : R = r_max - (r_max - r_min) * (1 - exp(-c x)) / (1 - exp(-c))
# Both give r_min at x = 1 and r_max at x = 0.
circ_transform <- function(x, form, r_min = SDMRES_R_MIN,
                           r_max = SDMRES_R_MAX, c = SDMRES_NEGEXP_C) {
  form <- match.arg(form, c("linear", "negexp"))
  if (!is.numeric(x) || anyNA(x) || any(x < 0 | x > 1)) {
    stop("circ_transform(): x must be in [0, 1], with no NA.", call. = FALSE)
  }
  if (form == "linear") return(r_min + (r_max - r_min) * (1 - x))
  if (!is.numeric(c) || length(c) != 1L || is.na(c) || c <= 0) {
    stop("circ_transform(): c must be one number above 0.", call. = FALSE)
  }
  r_max - (r_max - r_min) * (1 - exp(-c * x)) / (1 - exp(-c))
}

# ---- One surface layer -------------------------------------------------------------
# The fields of resist_sdm_<surface>_cell02.csv (n1 of task 17.2), in this
# order. No presence or background field, and no geometry.
SDMRES_SURFACE_FIELDS <- c("id", "x", "resistance")

#   pred    : the prediction layer of STEP 15.1 (SDM_PRED_FIELDS)
#   surface : a name of SDMRES_SURFACES ("main" or "negexp8")
# Returns a data frame (SDMRES_SURFACE_FIELDS), one row per model cell,
# ordered by id. A cell outside the training range keeps its rank (k1).
circ_surface <- function(pred, surface, forms = SDMRES_SURFACES) {
  if (!surface %in% names(forms)) {
    stop("circ_surface(): unknown surface '", surface, "'.", call. = FALSE)
  }
  if (!all(c("id", "rank") %in% names(pred))) {
    stop("circ_surface(): the prediction layer must hold id and rank.",
         call. = FALSE)
  }
  p <- pred[order(pred$id), c("id", "rank")]
  x <- circ_rank_to_x(p$rank, nrow(p))
  data.frame(id = as.integer(p$id), x = x,
             resistance = circ_transform(x, forms[[surface]]))
}

# The checks of a surface layer (in memory or read back from disk). A named
# list of TRUE/FALSE for sdm_run_guards().
circ_surface_checks <- function(s, model_ids, r_min = SDMRES_R_MIN,
                                r_max = SDMRES_R_MAX) {
  tol <- 1e-9 * r_max
  ok_f <- identical(names(s), SDMRES_SURFACE_FIELDS)
  if (!ok_f) {
    return(list("the surface must have the fields id, x, resistance (in this order; no other field)" = FALSE))
  }
  o <- order(s$x)
  list(
    "the surface must have the fields id, x, resistance (in this order; no other field)" =
      ok_f,
    "the surface must hold each model cell once" =
      nrow(s) == length(model_ids) && setequal(s$id, model_ids) &&
      !anyDuplicated(s$id),
    "no field may be NA" = !anyNA(s),
    "x must be in [0, 1], with x = 1 once and x = 0 once" =
      all(s$x >= 0 & s$x <= 1) && sum(s$x == 1) == 1L && sum(s$x == 0) == 1L,
    "the resistance must be in [SDMRES_R_MIN, SDMRES_R_MAX]" =
      all(s$resistance >= r_min - tol & s$resistance <= r_max + tol),
    "the resistance must be SDMRES_R_MIN at x = 1 and SDMRES_R_MAX at x = 0" =
      abs(s$resistance[s$x == 1] - r_min) <= tol &&
      abs(s$resistance[s$x == 0] - r_max) <= tol,
    "the resistance must not rise with x" =
      all(diff(s$resistance[o]) <= tol)
  )
}

# ---- Point 3 (c1): the graph of the model cells -------------------------------------
# The links between model cells (ix, iy): each cell to each of its 8
# neighbours (rook and diagonal) that is in the set. Each undirected link
# once (the half set of offsets: east, north, north-east, north-west). A
# diagonal link needs no other cell. The length is the distance between the
# two cell centres on the sphere (gistar_centres(), gistar_dist_km();
# Decision 26 p1 and Amendment 1).
# Returns a data frame: from, to (the positions of the two cells in the
# input), type ("rook" or "diagonal"), d_km.
circ_links <- function(ix, iy, deg = SDM_GRAIN_DEG) {
  n <- length(ix)
  if (n == 0L || length(iy) != n || anyNA(ix) || anyNA(iy)) {
    stop("circ_links(): ix and iy must have one value per cell, no NA.",
         call. = FALSE)
  }
  id <- sdm_cell_id(ix, iy)
  if (anyDuplicated(id)) stop("circ_links(): a cell is in the set twice.",
                              call. = FALSE)
  off <- data.frame(dx = c(1L, 0L, 1L, -1L), dy = c(0L, 1L, 1L, 1L),
                    type = c("rook", "rook", "diagonal", "diagonal"))
  parts <- vector("list", nrow(off))
  for (k in seq_len(nrow(off))) {
    jx <- ix + off$dx[k]
    jy <- iy + off$dy[k]
    ok <- jx >= 0L & jy >= 0L
    j <- rep(NA_integer_, n)
    j[ok] <- match(sdm_cell_id(jx[ok], jy[ok]), id)
    i <- which(!is.na(j))
    parts[[k]] <- data.frame(from = i, to = j[i], type = rep(off$type[k],
                                                             length(i)))
  }
  links <- do.call(rbind, parts)
  ctr <- gistar_centres(ix, iy, deg)
  links$d_km <- gistar_dist_km(ctr$lon[links$from], ctr$lat[links$from],
                               ctr$lon[links$to], ctr$lat[links$to])
  rownames(links) <- NULL
  links
}

# The resistance of each link (resistance-km): d x (R_i + R_j) / 2, with r the
# resistance of each cell in the order of the input of circ_links().
circ_link_resistance <- function(links, r) {
  if (anyNA(r) || max(links$from, links$to) > length(r)) {
    stop("circ_link_resistance(): r must hold one value per cell.",
         call. = FALSE)
  }
  links$d_km * (r[links$from] + r[links$to]) / 2
}

# The connected set of each cell (a membership number). A cell with no link
# is a set of its own.
circ_components <- function(n_nodes, links) {
  g <- igraph::make_graph(edges = as.vector(rbind(links$from, links$to)),
                          n = n_nodes, directed = FALSE)
  as.integer(igraph::components(g)$membership)
}

# ---- Point 3: the cells of each reserve ------------------------------------------------
# The model cells that hold the centre of one or more complete-case 1 km
# cells of the reserve polygon (Decision 25 h1; Decision 27 point 3).
#   rc        : the result of sdm_reserve_cells() (res, cell, id)
#   model_ids : the ids of the model cells
#   n_res     : the number of rows of the reserve layer
# Returns list(cells = one sorted vector of model-cell ids per reserve row,
# n_1km_model, n_1km_nonmodel = the 1 km cells of each reserve whose 0.2
# degree cell is or is not a model cell).
circ_reserve_cells <- function(rc, model_ids, n_res) {
  in_m <- rc$id %in% model_ids
  cells <- lapply(seq_len(n_res), function(i) {
    sort(unique(as.integer(rc$id[rc$res == i & in_m])))
  })
  list(cells = cells,
       n_1km_model = tabulate(rc$res[in_m], nbins = n_res),
       n_1km_nonmodel = tabulate(rc$res[!in_m], nbins = n_res))
}

# The status of each pair (Decision 27 point 3), from geometry only:
#   "contiguous_02" the two reserves share a model cell
#   "no_path"       no connected set holds cells of both
#   "path"          otherwise
#   "no_cells"      a reserve has no model cell (a guard stops on it)
#   cells_a, cells_b : lists of model-cell ids, one element per pair
#   model_ids        : the ids of the model cells, in the order of membership
#   membership       : the result of circ_components()
circ_pair_status <- function(cells_a, cells_b, model_ids, membership) {
  if (length(cells_a) != length(cells_b)) {
    stop("circ_pair_status(): cells_a and cells_b differ in length.",
         call. = FALSE)
  }
  vapply(seq_along(cells_a), function(k) {
    a <- cells_a[[k]]
    b <- cells_b[[k]]
    if (length(a) == 0L || length(b) == 0L) return("no_cells")
    if (length(intersect(a, b)) > 0L) return("contiguous_02")
    ma <- membership[match(a, model_ids)]
    mb <- membership[match(b, model_ids)]
    if (anyNA(ma) || anyNA(mb)) return("no_cells")
    if (length(intersect(ma, mb)) == 0L) "no_path" else "path"
  }, character(1))
}

# ---- The table of STEP 17.1 (tbl_19_sdmres_surface.csv) ------------------------------
# group, item, surface, value, reading. Counts and statistics only: no cell
# id, no position, no reserve name.
#   surfaces    : named list of surface layers (circ_surface())
#   oor         : TRUE/FALSE per row of each surface (the same id order)
#   links       : circ_links() of the model cells (in the surface order)
#   membership  : circ_components()
#   model_ids   : the ids of the model cells, in the order of membership
#   rcl         : circ_reserve_cells()
#   has_geom    : TRUE/FALSE per reserve row
#   status      : circ_pair_status() of the phase-1 pairs
#   contig_d17  : the contiguous flag of Decision 17 of each phase-1 pair
circ_surface_summary <- function(surfaces, oor, links, membership, model_ids,
                                 rcl, has_geom, status, contig_d17) {
  rows <- list()
  add <- function(group, item, value, surface = "", reading = "") {
    rows[[length(rows) + 1L]] <<- data.frame(
      group = group, item = item, surface = surface, value = value,
      reading = reading, stringsAsFactors = FALSE)
  }
  s1 <- surfaces[[1]]
  add("input", "model_cells", nrow(s1), reading = "the nodes (Decision 27 c1)")
  add("input", "cells_outside_range", sum(oor),
      reading = "kept with their rank (Decision 27 k1)")
  for (nm in names(surfaces)) {
    r <- surfaces[[nm]]$resistance
    q <- stats::quantile(r, c(0.25, 0.5, 0.75), names = FALSE, type = 7)
    add("surface", "r_min", min(r), nm, "resistance (1 to 100)")
    add("surface", "r_q25", q[1], nm)
    add("surface", "r_median", q[2], nm)
    add("surface", "r_mean", mean(r), nm)
    add("surface", "r_q75", q[3], nm)
    add("surface", "r_max", max(r), nm)
    add("surface", "r_min_outside_range", min(r[oor]), nm,
        "over the cells outside the training range")
    add("surface", "r_max_outside_range", max(r[oor]), nm,
        "over the cells outside the training range")
    lr <- circ_link_resistance(links, r)
    add("surface", "link_r_min", min(lr), nm, "resistance-km")
    add("surface", "link_r_median", stats::median(lr), nm, "resistance-km")
    add("surface", "link_r_max", max(lr), nm, "resistance-km")
  }
  sz <- tabulate(membership)
  add("graph", "nodes", length(membership))
  add("graph", "links_rook", sum(links$type == "rook"))
  add("graph", "links_diagonal", sum(links$type == "diagonal"))
  add("graph", "link_km_min", min(links$d_km), reading = "on the sphere")
  add("graph", "link_km_median", stats::median(links$d_km),
      reading = "on the sphere")
  add("graph", "link_km_max", max(links$d_km), reading = "on the sphere")
  add("graph", "components", length(sz), reading = "connected sets")
  add("graph", "largest_component_cells", max(sz))
  add("graph", "cells_outside_largest_component", sum(sz) - max(sz))
  add("graph", "isolated_cells", sum(sz == 1L), reading = "cells with no link")
  nc <- lengths(rcl$cells)[has_geom]
  comp_n <- vapply(rcl$cells[has_geom], function(v) {
    length(unique(membership[match(v, model_ids)]))
  }, integer(1))
  add("reserves", "reserves_with_polygon", sum(has_geom))
  add("reserves", "reserves_with_model_cell", sum(nc > 0L))
  add("reserves", "model_cells_per_reserve_min", min(nc))
  add("reserves", "model_cells_per_reserve_median", stats::median(nc))
  add("reserves", "model_cells_per_reserve_max", max(nc))
  add("reserves", "reserves_with_one_model_cell", sum(nc == 1L))
  add("reserves", "reserves_in_two_or_more_components", sum(comp_n >= 2L),
      reading = "cells of one reserve in two or more connected sets")
  all_ids <- unlist(rcl$cells[has_geom], use.names = FALSE)
  add("reserves", "model_cells_in_two_or_more_reserves",
      sum(table(all_ids) >= 2L))
  add("reserves", "reserve_1km_cells_in_model_cells",
      sum(rcl$n_1km_model[has_geom]), reading = "a 1 km cell in two polygons counts in each")
  add("reserves", "reserve_1km_cells_not_in_model_cells",
      sum(rcl$n_1km_nonmodel[has_geom]), reading = "no value (Decision 25 h1)")
  add("pairs", "phase1_pairs", length(status),
      reading = "the pairs of Decision 17")
  add("pairs", "contiguous_decision17", sum(contig_d17))
  nc17 <- !contig_d17
  add("pairs", "not_contiguous_decision17", sum(nc17),
      reading = "the candidates of Decision 27 point 7")
  add("pairs", "contiguous_02_of_not_contiguous", sum(status[nc17] == "contiguous_02"),
      reading = "out of point 7 (Decision 27 point 3)")
  add("pairs", "no_path_of_not_contiguous", sum(status[nc17] == "no_path"),
      reading = "out of point 7 (Decision 27 point 3)")
  add("pairs", "to_compare", sum(status[nc17] == "path"),
      reading = "the pairs of Decision 27 point 7")
  add("pairs", "contiguous_02_of_contiguous_decision17",
      sum(status[contig_d17] == "contiguous_02"), reading = "descriptive")
  add("pairs", "no_cells", sum(status == "no_cells"),
      reading = "must be 0 (a guard)")
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

# ---- The hand-made case of STEP 17.1 (h1 of task 17.2) -----------------------------
# Made-up cells and values only. Returns a data frame: check, pass.
circ_self_test_171 <- function() {
  res <- list()
  chk <- function(name, ok) res[[length(res) + 1L]] <<-
    data.frame(check = name, pass = isTRUE(ok), stringsAsFactors = FALSE)
  near <- function(a, b, tol = 1e-9) {
    length(a) == length(b) && all(abs(a - b) <= tol * pmax(1, abs(b)))
  }
  # 1. The input x from the rank (n = 5).
  chk("x from ranks 1..5 is 1, 0.75, 0.5, 0.25, 0",
      near(circ_rank_to_x(c(1, 2, 3, 4, 5)), c(1, 0.75, 0.5, 0.25, 0)))
  chk("x stops on a rank that is not 1..n",
      inherits(try(circ_rank_to_x(c(1, 2, 2)), silent = TRUE), "try-error"))
  # 2. The transforms (values by hand: R = 1 + 99 (1 - x); the negative
  #    exponential with c = 8 at x = 0.5, 0.2 and 0.1).
  chk("linear: R(1) = 1, R(0.5) = 50.5, R(0) = 100",
      near(circ_transform(c(1, 0.5, 0), "linear", 1, 100), c(1, 50.5, 100)))
  ne <- function(x) 100 - 99 * (1 - exp(-8 * x)) / (1 - exp(-8))
  chk("negexp (c = 8): R(1) = 1 and R(0) = 100",
      near(circ_transform(c(1, 0), "negexp", 1, 100, 8), c(1, 100)))
  chk("negexp (c = 8): R(0.5), R(0.2), R(0.1) as the formula; about 2.78, 20.96, 45.47",
      near(circ_transform(c(0.5, 0.2, 0.1), "negexp", 1, 100, 8),
           ne(c(0.5, 0.2, 0.1))) &&
      all(abs(ne(c(0.5, 0.2, 0.1)) - c(2.78, 20.96, 45.47)) < 0.01))
  chk("transform stops on x outside [0, 1]",
      inherits(try(circ_transform(1.2, "linear"), silent = TRUE), "try-error"))
  # 3. A surface from a made-up prediction layer; the cell outside the
  #    training range keeps its rank (k1).
  pred <- data.frame(id = c(50L, 10L, 40L, 20L, 30L),
                     value = c(0.1, 0.9, 0.2, 0.7, 0.5),
                     rank = c(5L, 1L, 4L, 2L, 3L), class = c(1L, 5L, 2L, 4L, 3L),
                     out_of_range = c(FALSE, FALSE, TRUE, FALSE, FALSE))
  s <- circ_surface(pred, "main", c(main = "linear"))
  chk("surface: ordered by id; x and R from the rank",
      identical(s$id, c(10L, 20L, 30L, 40L, 50L)) &&
      near(s$x, c(1, 0.75, 0.5, 0.25, 0)) &&
      near(s$resistance, 1 + 99 * (1 - c(1, 0.75, 0.5, 0.25, 0))))
  chk("surface: the checks pass on a correct layer",
      all(unlist(circ_surface_checks(s, c(10L, 20L, 30L, 40L, 50L), 1, 100))))
  bad <- s
  bad$resistance[2] <- 90       # x = 0.75 now has a higher R than x = 0.5
  chk("surface: the checks fail when R rises with x",
      !all(unlist(circ_surface_checks(bad, s$id, 1, 100))))
  # 4. The links: a block of 4 x 3 cells with its centre-left cell (1, 1)
  #    removed, and one cell far away. By hand: rook 17 - 4 = 13, diagonal
  #    12 - 4 = 8; the far cell has no link.
  ix0 <- 400L
  iy0 <- 100L
  g <- expand.grid(dx = 0:3, dy = 0:2)
  g <- g[!(g$dx == 1 & g$dy == 1), ]
  ix <- c(ix0 + g$dx, ix0 + 9L)
  iy <- c(iy0 + g$dy, iy0)
  L <- circ_links(ix, iy, 0.2)
  chk("links: 13 rook and 8 diagonal; each link once",
      sum(L$type == "rook") == 13L && sum(L$type == "diagonal") == 8L &&
      !anyDuplicated(t(apply(L[, c("from", "to")], 1, sort))))
  far <- length(ix)
  chk("links: the far cell has no link", !any(L$from == far | L$to == far))
  # A second path for the link set: every pair with max(|dx|, |dy|) = 1.
  pr <- which(outer(seq_along(ix), seq_along(ix), "<"), arr.ind = TRUE)
  adj <- pmax(abs(ix[pr[, 1]] - ix[pr[, 2]]), abs(iy[pr[, 1]] - iy[pr[, 2]])) == 1
  chk("links: the same set as all pairs of cells that touch",
      sum(adj) == nrow(L) &&
      setequal(paste(pmin(L$from, L$to), pmax(L$from, L$to)),
               paste(pr[adj, 1], pr[adj, 2])))
  # Lengths by hand: north-south = R x 0.2 degrees in radians (on the sphere);
  # east-west at latitude phi = 2 R asin(cos(phi) sin(0.1 degrees)).
  rad <- pi / 180
  ns <- L$type == "rook" & ix[L$from] == ix[L$to]
  ew <- L$type == "rook" & iy[L$from] == iy[L$to]
  phi <- (iy[L$from[ew]] + 0.5) * 0.2 * rad
  chk("links: north-south length = R x 0.2 degrees",
      near(L$d_km[ns], rep(GISTAR_EARTH_RADIUS_KM * 0.2 * rad, sum(ns))))
  chk("links: east-west length = 2 R asin(cos(lat) sin(0.1 degrees))",
      near(L$d_km[ew], 2 * GISTAR_EARTH_RADIUS_KM *
             asin(cos(phi) * sin(0.1 * rad))))
  chk("links: a diagonal is longer than the rook links of its cells",
      all(L$d_km[L$type == "diagonal"] > max(L$d_km[L$type == "rook"]) * 1.3))
  r <- seq_along(ix)
  lr <- circ_link_resistance(L, r)
  chk("link resistance = d x (R_i + R_j) / 2",
      near(lr, L$d_km * (L$from + L$to) / 2))
  # 5. The connected sets: the block and the far cell.
  m <- circ_components(length(ix), L)
  chk("components: 2 sets (the block, the far cell)",
      length(unique(m)) == 2L && sum(m == m[far]) == 1L)
  # 6. The cells of the reserves and the pair status. The ids are the
  #    sdm_cell_id() of the cells; 999 is not a model cell.
  ids <- sdm_cell_id(ix, iy)
  rc <- data.frame(res = c(1L, 1L, 1L, 2L, 2L, 3L, 4L),
                   cell = 1:7,
                   id = c(ids[1], ids[1], ids[2], ids[2], ids[3], 999L,
                          ids[far]))
  rcl <- circ_reserve_cells(rc, ids, 4L)
  chk("reserve cells: unique model cells; a non-model id is left out and counted",
      identical(rcl$cells[[1]], sort(c(ids[1], ids[2]))) &&
      identical(rcl$cells[[3]], integer(0)) &&
      identical(rcl$n_1km_model, c(3L, 2L, 0L, 1L)) &&
      identical(rcl$n_1km_nonmodel, c(0L, 0L, 1L, 0L)))
  st <- circ_pair_status(rcl$cells[c(1, 1, 1, 2)], rcl$cells[c(2, 4, 3, 4)],
                         ids, m)
  chk("pair status: contiguous_02, no_path, no_cells, no_path",
      identical(st, c("contiguous_02", "no_path", "no_cells", "no_path")))
  rcl2 <- list(cells = list(ids[1], ids[5]))
  chk("pair status: two cells of one set with no shared cell give path",
      identical(circ_pair_status(rcl2$cells[1], rcl2$cells[2], ids, m), "path"))
  do.call(rbind, res)
}

# =============================================================================
# Task 17.4 (2026-11-14): STEP 17.2 — the circuit and the least-cost paths of
# phase 1 (Decision 27 points 4 to 6), after the checks of point 5.
#   circ_solve_pair()       the effective resistance and the node currents of
#                           one pair (the two reserves joined into one node
#                           each; Z1)
#   circ_lcp_pair()         the least-cost path of one pair, edge to edge
#   circ_path_cost()        the cost of a path again from the cell values and
#                           the cell centres (check (iii) of point 5)
#   circ_path_line()        the line of a path through the cell centres, in
#                           the analysis CRS
#   circ_grid_links()       the 8-neighbour links of a small projected grid
#                           (for check (ii))
#   circ_check_gdistance()  check (ii): the effective resistance against
#                           gdistance::commuteDistance() on a small grid
#   circ_self_test_172()    the hand-made circuits and paths (check (i))
# =============================================================================

# ---- Point 4: one pair, circuit theory ---------------------------------------------
# A general graph: n_nodes nodes; links (from, to) with conductance g > 0.
# The nodes of `a` are joined into one node and the nodes of `b` into one
# node (for this pair only); 1 A goes in at a; b is the ground. Only the
# nodes of `keep` are solved (the connected set that holds a and b; NULL =
# all nodes). The Laplacian of the reduced graph, with the row and the column
# of b removed, is solved with Matrix (a sparse Cholesky factor).
# Returns list(reff = the voltage of a; v = the voltage of each node (NA
# outside keep); current = the node current of each node (half the sum of
# the absolute currents of its links; 0 in a and b (Z1) and outside keep);
# out_a = the current out of a, which must be 1).
circ_solve_pair <- function(n_nodes, from, to, g, a, b, keep = NULL) {
  a <- unique(as.integer(a))
  b <- unique(as.integer(b))
  if (length(a) == 0L || length(b) == 0L || length(intersect(a, b)) > 0L) {
    stop("circ_solve_pair(): a and b must be non-empty and disjoint.",
         call. = FALSE)
  }
  if (length(g) != length(from) || length(to) != length(from) ||
      anyNA(g) || any(g <= 0) || any(!is.finite(g))) {
    stop("circ_solve_pair(): each link needs one conductance above 0.",
         call. = FALSE)
  }
  keep <- if (is.null(keep)) seq_len(n_nodes) else sort(unique(as.integer(keep)))
  if (!all(c(a, b) %in% keep)) {
    stop("circ_solve_pair(): a and b must be in keep.", call. = FALSE)
  }
  # New index: a -> 1, b -> 2, the other kept nodes -> 3, 4, ...
  map <- rep(NA_integer_, n_nodes)
  others <- setdiff(keep, c(a, b))
  map[a] <- 1L
  map[b] <- 2L
  map[others] <- seq_along(others) + 2L
  k <- length(others) + 2L
  mf <- map[from]
  mt <- map[to]
  use <- !is.na(mf) & !is.na(mt) & mf != mt
  mf <- mf[use]
  mt <- mt[use]
  gu <- g[use]
  L <- Matrix::sparseMatrix(i = c(mf, mt, mf, mt), j = c(mt, mf, mf, mt),
                            x = c(-gu, -gu, gu, gu), dims = c(k, k))
  Lr <- Matrix::forceSymmetric(L[-2L, -2L, drop = FALSE], uplo = "U")
  rhs <- numeric(k - 1L)
  rhs[1] <- 1
  vr <- as.vector(Matrix::solve(Lr, rhs))
  vn <- c(vr[1], 0, vr[-1])            # the voltage of each new node; b = 0
  I <- gu * (vn[mf] - vn[mt])          # the current of each link (mf -> mt)
  out_a <- sum(I[mf == 1L]) - sum(I[mt == 1L])
  cn <- numeric(k)
  cn <- cn + tabulate(mf, nbins = k) * 0   # keep the length k
  s <- rowsum(c(abs(I), abs(I)), c(mf, mt), reorder = TRUE)
  cn[as.integer(rownames(s))] <- 0.5 * s[, 1]
  cn[1:2] <- 0                          # Z1: the two reserves of the pair
  v <- rep(NA_real_, n_nodes)
  v[keep] <- vn[map[keep]]
  current <- numeric(n_nodes)
  current[keep] <- cn[map[keep]]
  list(reff = vn[1], v = v, current = current, out_a = out_a)
}

# ---- Point 4: one pair, the least-cost path ------------------------------------------
# Dijkstra (igraph) on the links with the weights w (the link resistances),
# from all nodes of a at once (a super node joined to each node of a with
# weight 0) to the nodes of b. The path ends at the node of b with the lowest
# cost; a tie goes to the lowest node index (as lcp_search()). Movement
# inside a costs nothing; the first node of b reached is the entry.
# Returns list(cost, nodes = the path from the exit node of a to the entry
# node of b). cost is Inf and nodes empty when b cannot be reached.
circ_lcp_pair <- function(n_nodes, from, to, w, a, b, tol_rel = 1e-9) {
  a <- sort(unique(as.integer(a)))
  b <- sort(unique(as.integer(b)))
  if (anyNA(w) || any(w < 0) || length(w) != length(from)) {
    stop("circ_lcp_pair(): each link needs one weight of 0 or more.",
         call. = FALSE)
  }
  s <- n_nodes + 1L
  gr <- igraph::make_graph(edges = as.vector(rbind(c(from, rep(s, length(a))),
                                                   c(to, a))),
                           n = n_nodes + 1L, directed = FALSE)
  w2 <- c(w, rep(0, length(a)))
  d <- igraph::distances(gr, v = s, to = b, weights = w2,
                         algorithm = "dijkstra")[1, ]
  if (all(is.infinite(d))) return(list(cost = Inf, nodes = integer(0)))
  best <- b[which(d == min(d))[1]]
  sp <- igraph::shortest_paths(gr, from = s, to = best, weights = w2,
                               output = "both")
  vp <- as.integer(sp$vpath[[1]])
  ep <- as.integer(sp$epath[[1]])
  cost <- sum(w2[ep])
  if (abs(cost - min(d)) > tol_rel * max(1, min(d))) {
    stop("circ_lcp_pair(): the path cost differs from the Dijkstra distance.",
         call. = FALSE)
  }
  list(cost = min(d), nodes = vp[vp != s])
}

# ---- Point 5 (iii): the cost of a path again --------------------------------------------
# From the cells (ix, iy) of the path and their resistance r, by the link rule
# of point 3: for each step, the distance between the two centres on the
# sphere x (R_i + R_j) / 2. A step must go to one of the 8 neighbours. It
# uses no link table. Returns list(cost, steps_ok).
circ_path_cost <- function(ix, iy, r, deg = SDM_GRAIN_DEG) {
  n <- length(ix)
  if (n < 2L) return(list(cost = 0, steps_ok = TRUE))
  dx <- abs(diff(ix))
  dy <- abs(diff(iy))
  steps_ok <- all(pmax(dx, dy) == 1L)
  lon <- (ix + 0.5) * deg
  lat <- (iy + 0.5) * deg
  d <- gistar_dist_km(lon[-n], lat[-n], lon[-1], lat[-1])
  list(cost = sum(d * (r[-n] + r[-1]) / 2), steps_ok = steps_ok)
}

# The line of a path through the cell centres, in the analysis CRS (an sfg).
# Fewer than 2 cells gives an empty LINESTRING.
circ_path_line <- function(ix, iy, deg = SDM_GRAIN_DEG, crs_out = CRS_ANALYSIS) {
  if (length(ix) < 2L) return(sf::st_linestring())
  ll <- cbind((ix + 0.5) * deg, (iy + 0.5) * deg)
  xy <- sf::sf_project(from = sf::st_crs(CRS_WGS84), to = sf::st_crs(crs_out),
                       pts = ll)
  sf::st_linestring(xy)
}

# ---- Point 5 (ii): gdistance on a small projected grid ---------------------------------
# The 8-neighbour links of a grid of nr x nc cells of size res (map units),
# cells numbered row by row from the top left (as raster and terra). The
# link resistance is the distance between the centres x (R_i + R_j) / 2.
circ_grid_links <- function(nr, nc, res, r) {
  cell <- seq_len(nr * nc)
  row <- (cell - 1L) %/% nc + 1L
  col <- (cell - 1L) %% nc + 1L
  off <- data.frame(dr = c(0L, 1L, 1L, 1L), dc = c(1L, 0L, 1L, -1L))
  parts <- lapply(seq_len(nrow(off)), function(k) {
    r2 <- row + off$dr[k]
    c2 <- col + off$dc[k]
    ok <- r2 >= 1L & r2 <= nr & c2 >= 1L & c2 <= nc
    data.frame(from = cell[ok], to = (r2[ok] - 1L) * nc + c2[ok],
               d = res * sqrt(off$dr[k]^2 + off$dc[k]^2))
  })
  L <- do.call(rbind, parts)
  L$resistance <- L$d * (r[L$from] + r[L$to]) / 2
  L
}

# Check (ii) of Decision 27 point 5. A grid of 8 x 9 cells of 1,000 m with
# made-up resistance values (1 to 97); two point nodes. gdistance:
# conductance 1 / mean(R) for 8 directions, divided by the step length
# (geoCorrection type "c"), so the conductance of a link is 1 / (d x mean R),
# the rule of the own code. commuteDistance() gives the effective resistance
# x sum(transitionMatrix(tr)) (the gdistance source); the check multiplies the
# own value by the same sum. Returns a data frame: check, own, reference,
# rel_diff, pass.
circ_check_gdistance <- function(tol_rel = SDMRES_CHECK_TOL_REL) {
  if (!requireNamespace("gdistance", quietly = TRUE) ||
      !requireNamespace("raster", quietly = TRUE)) {
    stop("circ_check_gdistance(): the packages gdistance and raster are ",
         "needed (check (ii) of Decision 27 point 5; scripts/00a).",
         call. = FALSE)
  }
  nr <- 8L
  nc <- 9L
  res <- 1000
  v <- 1 + ((seq_len(nr * nc) * 37L) %% 97L)
  # gdistance grounds the last cell of the grid inside commuteDistance(), so
  # that cell cannot be a point node (an index error in gdistance 1.6.4).
  pairs <- rbind(c(1L, nr * nc - 1L), c(12L, 50L), c(30L, 31L))
  rr <- raster::raster(nrows = nr, ncols = nc, xmn = 0, xmx = nc * res,
                       ymn = 0, ymx = nr * res,
                       crs = "+proj=utm +zone=44 +datum=WGS84 +units=m")
  rr <- raster::setValues(rr, v)
  tr <- gdistance::transition(rr, transitionFunction = function(x) 1 / mean(x),
                              directions = 8, symm = TRUE)
  tr <- gdistance::geoCorrection(tr, type = "c", multpl = FALSE)
  vol <- sum(gdistance::transitionMatrix(tr))
  L <- circ_grid_links(nr, nc, res, v)
  out <- lapply(seq_len(nrow(pairs)), function(k) {
    p <- pairs[k, ]
    own <- circ_solve_pair(nr * nc, L$from, L$to, 1 / L$resistance,
                           a = p[1], b = p[2])$reff
    xy <- raster::xyFromCell(rr, p)
    ref <- as.matrix(gdistance::commuteDistance(tr, xy))[1, 2]
    data.frame(check = sprintf("(ii) gdistance, cells %d and %d of %d", p[1],
                               p[2], nr * nc),
               own = own * vol, reference = ref,
               rel_diff = abs(own * vol - ref) / max(1, abs(ref)))
  })
  out <- do.call(rbind, out)
  out$pass <- out$rel_diff <= tol_rel
  out
}

# ---- Point 5 (i) and (iii): the hand-made case of STEP 17.2 ------------------------------
# Circuits with exact values, the current rule (Z1), the paths and the path
# cost, on made-up graphs only. Returns a data frame: check, pass.
circ_self_test_172 <- function() {
  res <- list()
  chk <- function(name, ok) res[[length(res) + 1L]] <<-
    data.frame(check = name, pass = isTRUE(ok), stringsAsFactors = FALSE)
  near <- function(a, b, tol = 1e-9) {
    length(a) == length(b) && all(abs(a - b) <= tol * pmax(1, abs(b)))
  }
  solve <- function(n, L, a, b, keep = NULL) {
    circ_solve_pair(n, L[, 1], L[, 2], 1 / L[, 3], a, b, keep)
  }
  # 1. Series: 1 -3- 2 -5- 3. R = 8; the middle node carries 1 A.
  s1 <- solve(3L, rbind(c(1, 2, 3), c(2, 3, 5)), 1L, 3L)
  chk("(i) series: R = 3 + 5 = 8", near(s1$reff, 8))
  chk("(i) series: the middle node carries 1 A; the two ends 0 (Z1)",
      near(s1$current, c(0, 1, 0)))
  chk("(i) series: 1 A leaves a", near(s1$out_a, 1))
  # 2. Parallel: 1 -4- 2 and 1 -2- 3 -2- 2. R = 4 || 4 = 2.
  s2 <- solve(3L, rbind(c(1, 2, 4), c(1, 3, 2), c(3, 2, 2)), 1L, 2L)
  chk("(i) parallel: R = 4 || (2 + 2) = 2", near(s2$reff, 2))
  chk("(i) parallel: the middle node carries 0.5 A", near(s2$current[3], 0.5))
  # 3. Unbalanced bridge: A=1, B=2, C=3, D=4; A-C 1, A-D 2, C-B 2, D-B 1,
  #    C-D 1. By hand (nodal equations): V_A = 7/5, V_C = 4/5, V_D = 3/5, so
  #    R = 1.4; the C-D current is 0.2 A; C and D each carry 0.6 A.
  s3 <- solve(4L, rbind(c(1, 3, 1), c(1, 4, 2), c(3, 2, 2), c(4, 2, 1),
                        c(3, 4, 1)), 1L, 2L)
  chk("(i) unbalanced bridge: R = 1.4", near(s3$reff, 1.4))
  chk("(i) unbalanced bridge: V_C = 0.8 and V_D = 0.6",
      near(s3$v[3:4], c(0.8, 0.6)))
  chk("(i) unbalanced bridge: C and D carry 0.6 A each",
      near(s3$current, c(0, 0, 0.6, 0.6)))
  # 4. Balanced bridge (1/2 = 2/4): no current in C-D; R = (1+2) || (2+4) = 2.
  s4 <- solve(4L, rbind(c(1, 3, 1), c(1, 4, 2), c(3, 2, 2), c(4, 2, 4),
                        c(3, 4, 7)), 1L, 2L)
  chk("(i) balanced bridge: R = 3 || 6 = 2; V_C = V_D",
      near(s4$reff, 2) && near(s4$v[3], s4$v[4]))
  # 5. A region joined into one node: a = {1, 2}, each -2- 3, 3 -1- 4 (b).
  #    R = (2 || 2) + 1 = 2. With a = {1} only: R = 2 + 1 = 3.
  L5 <- rbind(c(1, 3, 2), c(2, 3, 2), c(3, 4, 1), c(1, 2, 9))
  chk("(i) region: a joined into one node gives R = 2",
      near(solve(4L, L5, c(1L, 2L), 4L)$reff, 2))
  chk("(i) region: the node 1 alone gives R = 2 || (9 + 2) + 1",
      near(solve(4L, L5, 1L, 4L)$reff, 1 / (1 / 2 + 1 / 11) + 1))
  # 6. Only the connected set is solved: nodes 5-6 are a separate set.
  L6 <- rbind(c(1, 2, 3), c(2, 3, 5), c(5, 6, 1))
  s6 <- solve(6L, L6, 1L, 3L, keep = 1:3)
  chk("(i) a separate set is left out: R = 8; no voltage and no current there",
      near(s6$reff, 8) && all(is.na(s6$v[5:6])) && all(s6$current[5:6] == 0))
  chk("(i) a and b that share a node stop the solve",
      inherits(try(solve(3L, L6[1:2, ], c(1L, 2L), 2L), silent = TRUE),
               "try-error"))
  # 7. Paths: 1 -1- 2 -1- 3; 1 -5- 4 -0.5- 3; 3 -1- 5.
  L7 <- rbind(c(1, 2, 1), c(2, 3, 1), c(1, 4, 5), c(4, 3, 0.5), c(3, 5, 1))
  p1 <- circ_lcp_pair(5L, L7[, 1], L7[, 2], L7[, 3], 1L, c(3L, 5L))
  chk("(iii) path: from 1 to {3, 5}: 1-2-3, cost 2",
      near(p1$cost, 2) && identical(p1$nodes, c(1L, 2L, 3L)))
  p2 <- circ_lcp_pair(5L, L7[, 1], L7[, 2], L7[, 3], c(1L, 4L), 3L)
  chk("(iii) path: from the region {1, 4}: 4-3, cost 0.5 (edge to edge)",
      near(p2$cost, 0.5) && identical(p2$nodes, c(4L, 3L)))
  L8 <- rbind(c(1, 3, 2), c(1, 5, 2))
  p3 <- circ_lcp_pair(5L, L8[, 1], L8[, 2], L8[, 3], 1L, c(5L, 3L))
  chk("(iii) path: a tie goes to the lowest node (3)",
      identical(p3$nodes, c(1L, 3L)))
  chk("(iii) path: no route gives cost Inf",
      is.infinite(circ_lcp_pair(5L, L8[, 1], L8[, 2], L8[, 3], 1L, 4L)$cost))
  chk("(i) the effective resistance is not above the least-cost cost (bridge)",
      s3$reff <= circ_lcp_pair(4L, c(1, 1, 3, 4, 3), c(3, 4, 2, 2, 4),
                               c(1, 2, 2, 1, 1), 1L, 2L)$cost + 1e-12)
  # 8. The path cost again on made-up 0.2 degree cells: (400, 100) east to
  #    (401, 100), then north-east to (402, 101); R = 1, 3, 5. By hand: the
  #    east step d1 x 2 + the diagonal step d2 x 4, with the haversine
  #    distances of the centres.
  rad <- pi / 180
  hav <- function(lo1, la1, lo2, la2) {
    2 * GISTAR_EARTH_RADIUS_KM * asin(sqrt(sin((la2 - la1) * rad / 2)^2 +
      cos(la1 * rad) * cos(la2 * rad) * sin((lo2 - lo1) * rad / 2)^2))
  }
  d1 <- hav(80.1, 20.1, 80.3, 20.1)
  d2 <- hav(80.3, 20.1, 80.5, 20.3)
  pc <- circ_path_cost(c(400L, 401L, 402L), c(100L, 100L, 101L), c(1, 3, 5),
                       deg = 0.2)
  chk("(iii) path cost again: d1 x 2 + d2 x 4", near(pc$cost, d1 * 2 + d2 * 4) &&
      isTRUE(pc$steps_ok))
  chk("(iii) path cost again: a step that is not to a neighbour fails",
      !circ_path_cost(c(400L, 402L), c(100L, 100L), c(1, 1), 0.2)$steps_ok)
  # The same cells through circ_links() and circ_lcp_pair(): one cost.
  ixg <- c(400L, 401L, 402L, 401L)
  iyg <- c(100L, 100L, 101L, 101L)
  rg <- c(1, 3, 5, 50)
  Lg <- circ_links(ixg, iyg, 0.2)
  pg <- circ_lcp_pair(4L, Lg$from, Lg$to, circ_link_resistance(Lg, rg), 1L, 3L)
  pcg <- circ_path_cost(ixg[pg$nodes], iyg[pg$nodes], rg[pg$nodes], 0.2)
  chk("(iii) the Dijkstra cost on circ_links() = the cost again from the cells",
      near(pg$cost, pcg$cost) && identical(pg$nodes, c(1L, 2L, 3L)))
  chk("path line: fewer than 2 cells gives an empty line",
      sf::st_is_empty(circ_path_line(400L, 100L)))
  do.call(rbind, res)
}
