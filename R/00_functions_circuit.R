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
# Decision 27 point 5 (the list is at its block below). Task 17.5 adds the
# comparison of point 7 (STEP 17.3) and task 17.6 the QA of phase 1 (STEP
# 17.4); the lists are at their blocks below.
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

# =============================================================================
# Task 17.5 (2026-11-14): STEP 17.3 — the comparison of Decision 27 point 7
# (process choices TB1, CC1 and FC1, and the reading R4 of task 17.5).
#   circ_check_config_173()  the settings of task 17.5
#   circ_line_share_in()     the share of the length of each line inside a
#                            set of polygons
#   circ_compare_paths()     per pair: a set of paths against a reference
#                            set, by the rule of Decision 18 (CC1); one row
#                            for each pair, a pair that is not compared gets
#                            NA (R4)
#   circ_partial_spearman()  the Pearson partial correlation of the ranks
#   circ_compare_summary()   per surface: the shares, rho, the label and the
#                            descriptive values (TB1)
#   circ_self_test_173()     the hand-made case of STEP 17.3, with the test
#                            of circ_compare_paths() against
#                            lcp_compare_variant() (one yardstick, CC1)
# =============================================================================

SDMRES_NEEDED_173 <- c(
  "SDMRES_TABLE_SLUGS", "SDMRES_FIG_SLUGS", "SDMRES_PUB_FIGS",
  "SDMRES_FIG_N_CLASSES", "SDMRES_TOP_CURRENT_SHARE",
  "SDMRES_COMPARE_LABELS", "SDMRES_FIG07_PALETTE", "SDMRES_FIG07_PATH_COL",
  "SDMRES_FIG07_PATH_LWD", "SDMRES_FIG08_COLOURS", "SDMRES_FIG08_LWD",
  "SDMRES_FIG08_LTY", "SDMRES_FIG08_STAGE2_MIX", "FIG_STAGE3_SIZE_IN",
  "FIG_STAGE3_DPI", "FIG_HATCH_KEY_POS", "FIG_HATCH_LINES_PER_CELL",
  "FIG_FRAME_COLOURS", "DIR_FIGURES", "SDMRES_RANK_SIGNIF"
)

# The settings of task 17.5. Returns a named list of TRUE/FALSE checks (for
# sdm_run_guards()). Stops first if a setting is missing.
circ_check_config_173 <- function() {
  miss <- SDMRES_NEEDED_173[!vapply(SDMRES_NEEDED_173, exists, logical(1))]
  if (length(miss) > 0) {
    stop("Setting(s) missing from R/00_config.R (task 17.5): ",
         paste(miss, collapse = ", "), call. = FALSE)
  }
  is_col <- function(v) {
    is.character(v) && length(v) > 0 && !anyNA(v) &&
      !inherits(try(grDevices::col2rgb(v), silent = TRUE), "try-error")
  }
  pos_num <- function(v, nm) {
    is.numeric(v) && identical(names(v), nm) && !anyNA(v) && all(v > 0)
  }
  pal <- SDMRES_FIG07_PALETTE
  mix <- grDevices::rgb(grDevices::colorRamp(c(
    FIG_FRAME_COLOURS[["paper"]], FIG_FRAME_COLOURS[["ink"]]))(
      SDMRES_FIG08_STAGE2_MIX), maxColorValue = 255)
  list(
    "SDMRES_TABLE_SLUGS must hold compare and compare_summary (TB1 of task 17.5)" =
      all(c("compare", "compare_summary") %in% names(SDMRES_TABLE_SLUGS)) &&
      !anyDuplicated(SDMRES_TABLE_SLUGS),
    "SDMRES_FIG_N_CLASSES x SDMRES_TOP_CURRENT_SHARE must be 1 (FC1: the top class = the top cells of point 7)" =
      isTRUE(abs(SDMRES_FIG_N_CLASSES * SDMRES_TOP_CURRENT_SHARE - 1) < 1e-12),
    "SDMRES_COMPARE_LABELS must hold stage2 and variant, two words each" =
      identical(names(SDMRES_COMPARE_LABELS), c("stage2", "variant")) &&
      all(lengths(SDMRES_COMPARE_LABELS) == 2L),
    "SDMRES_FIG07_PALETTE must be a viridisLite option with 0 <= begin < end <= 1 (PL1)" =
      is.list(pal) && identical(names(pal), c("option", "begin", "end")) &&
      is.character(pal$option) && length(pal$option) == 1L &&
      pal$option %in% c("magma", "inferno", "plasma", "viridis", "cividis",
                        "rocket", "mako", "turbo") &&
      is.numeric(pal$begin) && is.numeric(pal$end) &&
      pal$begin >= 0 && pal$begin < pal$end && pal$end <= 1,
    "SDMRES_FIG07_PATH_COL must be line and casing colours; the casing is the ink (L7a)" =
      identical(names(SDMRES_FIG07_PATH_COL), c("line", "casing")) &&
      is_col(SDMRES_FIG07_PATH_COL) &&
      identical(SDMRES_FIG07_PATH_COL[["casing"]], FIG_FRAME_COLOURS[["ink"]]),
    "SDMRES_FIG07_PATH_LWD must be line < casing, both above 0 (L7a)" =
      pos_num(SDMRES_FIG07_PATH_LWD, c("line", "casing")) &&
      SDMRES_FIG07_PATH_LWD[["line"]] < SDMRES_FIG07_PATH_LWD[["casing"]],
    "SDMRES_FIG08_COLOURS, _LWD and _LTY must name sdm and stage2 (L8a)" =
      identical(names(SDMRES_FIG08_COLOURS), c("sdm", "stage2")) &&
      is_col(SDMRES_FIG08_COLOURS) &&
      pos_num(SDMRES_FIG08_LWD, c("sdm", "stage2")) &&
      identical(names(SDMRES_FIG08_LTY), c("sdm", "stage2")) &&
      all(SDMRES_FIG08_LTY %in% c("solid", "dashed", "dotted", "dotdash",
                                  "longdash", "twodash")) &&
      SDMRES_FIG08_LTY[["sdm"]] != SDMRES_FIG08_LTY[["stage2"]],
    "the Stage-2 grey of fig_08 must be the mix of the paper and the ink (the link colour of fig_03; L8a)" =
      identical(toupper(SDMRES_FIG08_COLOURS[["stage2"]]), toupper(mix)),
    "the figure size, resolution and key must be those of fig_04 to fig_06 (SZ1)" =
      identical(names(FIG_STAGE3_SIZE_IN), c("width", "height")) &&
      all(FIG_STAGE3_SIZE_IN > 0) && FIG_STAGE3_DPI > 0 &&
      identical(names(FIG_HATCH_KEY_POS), c("x", "y")) &&
      all(FIG_HATCH_KEY_POS > 0 & FIG_HATCH_KEY_POS < 1),
    "no table or figure slug may hold the word tiger" =
      !any(grepl("tiger", c(SDMRES_TABLE_SLUGS, SDMRES_FIG_SLUGS),
                 ignore.case = TRUE)),
    "SDMRES_RANK_SIGNIF must be a whole number from 10 to 14 (NT1 of task 17.6)" =
      is.numeric(SDMRES_RANK_SIGNIF) && length(SDMRES_RANK_SIGNIF) == 1L &&
      SDMRES_RANK_SIGNIF == round(SDMRES_RANK_SIGNIF) &&
      SDMRES_RANK_SIGNIF >= 10 && SDMRES_RANK_SIGNIF <= 14
  )
}

# ---- Point 7 (descriptive): the share of a line inside polygons ------------------
# lines : an sfc of LINESTRING; polys : an sfc of POLYGON (the same projected
# CRS). Returns, for each line, the share of its length inside the union of
# the polygons (0-1; a part on an edge counts as inside). NA for an empty
# line or a line of length 0.
circ_line_share_in <- function(lines, polys) {
  if (sf::st_crs(lines) != sf::st_crs(polys)) {      # sf: an equivalent CRS
    stop("circ_line_share_in(): the lines and the polygons must have one CRS.",
         call. = FALSE)
  }
  u <- if (length(polys) == 0) NULL else sf::st_union(polys)
  vapply(seq_along(lines), function(i) {
    g <- lines[i]
    if (sf::st_is_empty(g)) return(NA_real_)
    lt <- as.numeric(sf::st_length(g))
    if (lt == 0) return(NA_real_)
    if (is.null(u)) return(0)
    ins <- suppressWarnings(sf::st_intersection(g, u))
    li <- if (length(ins) == 0) 0 else sum(as.numeric(sf::st_length(ins)))
    min(1, max(0, li / lt))
  }, numeric(1))
}

# ---- Point 7 (CC1): one set of paths against a reference set, per pair -------------
# The rule of Decision 18 as lcp_compare_variant() applies it (route overlap
# = min of the two shares at d_km with lcp_route_share(); material if below
# route_material; the percentile rank of the cost among the compared pairs,
# ties at the average rank; material if the change is rank_material or
# more), with the Stage-2 fields that do not apply here left out.
#   base, var : sf (the same projected CRS) with pair_id, cost_rkm, path_km
#               and a LINESTRING; one row per pair, in one order. base is the
#               reference, var the surface of the row
#   info      : a data frame with pair_id, from_name, to_name, gap_km, in the
#               same order
#   compared  : TRUE for a pair of point 7 (both have a path); FALSE gives NA
#               in the columns of Decision 18 (R4 of task 17.5)
# Returns one row per pair; the column names of tbl_12_lcp_variant_comparison
# .csv where the meaning is the same.
circ_compare_paths <- function(base, var, info, compared, surface, reference,
                               d_km = SDMRES_COMPARE_ROUTE_D_KM,
                               descr_km = SDMRES_COMPARE_ROUTE_D_DESCR_KM,
                               route_material = SDMRES_COMPARE_ROUTE_MATERIAL,
                               rank_material = SDMRES_COMPARE_RANK_MATERIAL,
                               digits = SDMRES_RANK_SIGNIF) {
  n <- nrow(info)
  if (!identical(as.integer(base$pair_id), as.integer(info$pair_id)) ||
      !identical(as.integer(var$pair_id), as.integer(info$pair_id)) ||
      length(compared) != n || anyNA(compared)) {
    stop("circ_compare_paths(): base, var, info and compared must have one ",
         "row per pair, in one order.", call. = FALSE)
  }
  gb <- sf::st_geometry(base)
  gv <- sf::st_geometry(var)
  k <- which(compared)
  bad <- k[sf::st_is_empty(gb[k]) | sf::st_is_empty(gv[k]) |
             !is.finite(base$cost_rkm[k]) | !is.finite(var$cost_rkm[k]) |
             base$cost_rkm[k] <= 0 | var$cost_rkm[k] <= 0]
  if (length(bad) > 0) {
    stop("circ_compare_paths(): a compared pair has no path or no cost ",
         "(pair_id ", paste(info$pair_id[bad], collapse = ", "), ").",
         call. = FALSE)
  }
  share_bv <- share_vb <- rep(NA_real_, n)
  descr <- matrix(NA_real_, n, length(descr_km),
                  dimnames = list(NULL, paste0("route_overlap_", descr_km, "km")))
  for (i in k) {
    share_bv[i] <- lcp_route_share(gb[i], gv[i], d_km)
    share_vb[i] <- lcp_route_share(gv[i], gb[i], d_km)
    for (j in seq_along(descr_km)) {
      descr[i, j] <- min(lcp_route_share(gb[i], gv[i], descr_km[j]),
                         lcp_route_share(gv[i], gb[i], descr_km[j]))
    }
  }
  pr <- function(x) (rank(x, ties.method = "average") - 1) / (length(x) - 1)
  rank_b <- rank_v <- rep(NA_real_, n)
  if (length(k) >= 2L) {
    rank_b[k] <- pr(signif(base$cost_rkm[k], digits))   # NT1 of task 17.6
    rank_v[k] <- pr(signif(var$cost_rkm[k], digits))
  }
  na_if <- function(v) ifelse(compared, v, NA)
  out <- data.frame(
    pair_id = info$pair_id, surface = surface, reference = reference,
    compared = compared, from_name = info$from_name, to_name = info$to_name,
    gap_km = info$gap_km,
    share_base_in_variant = share_bv, share_variant_in_base = share_vb,
    route_overlap = pmin(share_bv, share_vb),
    descr,
    cost_base = na_if(base$cost_rkm), cost_variant = na_if(var$cost_rkm),
    rank_base = rank_b, rank_variant = rank_v,
    stringsAsFactors = FALSE, check.names = FALSE)
  out$rank_change    <- out$rank_variant - out$rank_base
  out$material_route <- out$route_overlap < route_material
  out$material_rank  <- abs(out$rank_change) >= rank_material
  out$material_pair  <- out$material_route | out$material_rank
  out$path_length_ratio <- na_if(var$path_km / base$path_km)
  rownames(out) <- NULL
  out
}

# The Pearson partial correlation of the ranks of x and y given z (ties at
# the average rank): the partial Spearman rho. NA if fewer than 4 values or
# if x or y has a rank correlation of 1 with z.
circ_partial_spearman <- function(x, y, z) {
  ok <- is.finite(x) & is.finite(y) & is.finite(z)
  if (sum(ok) < 4L) return(NA_real_)
  r <- stats::cor(cbind(rank(x[ok]), rank(y[ok]), rank(z[ok])))
  den <- (1 - r[1, 3]^2) * (1 - r[2, 3]^2)
  if (!is.finite(den) || den <= 1e-12) return(NA_real_)
  (r[1, 2] - r[1, 3] * r[2, 3]) / sqrt(den)
}

# ---- Point 7: the summary of one surface (TB1) --------------------------------------------
#   cmp        : the rows of circ_compare_paths() for one surface
#   status     : the status of each row's pair at 0.2 degrees (STEP 17.1)
#   reff, redundancy : of the surface of the rows, for each row
#   cost_stage2: the Stage-2 cost of each row's pair
#   top_share  : the share of each Stage-2 path in the top cells
#   top_cells  : the number of the top cells
#   labels     : the two words of the label (the first = the pass word)
# The label, rho and the shares use the compared pairs (Decision 18 points
# 5-6); the descriptive values use the compared pairs too (R4: one n).
circ_compare_summary <- function(cmp, status, reff, redundancy, cost_stage2,
                                 top_share, top_cells, labels,
                                 max_share = SDMRES_COMPARE_MAX_SHARE,
                                 min_rho = SDMRES_COMPARE_MIN_RHO,
                                 digits = SDMRES_RANK_SIGNIF) {
  n <- nrow(cmp)
  if (length(status) != n || length(reff) != n || length(redundancy) != n ||
      length(cost_stage2) != n || length(top_share) != n ||
      length(labels) != 2L) {
    stop("circ_compare_summary(): one value per row is needed.",
         call. = FALSE)
  }
  k <- cmp$compared
  sg <- function(v) signif(v, digits)        # NT1 of task 17.6: ties first
  rho <- if (sum(k) >= 3L) {
    stats::cor(sg(cmp$cost_base[k]), sg(cmp$cost_variant[k]),
               method = "spearman")
  } else NA_real_
  sh <- mean(cmp$material_pair[k])
  data.frame(
    surface = cmp$surface[1], reference = cmp$reference[1],
    stage2_paths = n, pairs_compared = sum(k),
    contiguous_02_excluded = sum(status == "contiguous_02"),
    no_path_excluded = sum(status == "no_path"),
    share_material_route = mean(cmp$material_route[k]),
    share_material_rank = mean(cmp$material_rank[k]),
    share_material_pair = sh,
    spearman_rho = rho,
    median_route_overlap = stats::median(cmp$route_overlap[k]),
    label = if (isTRUE(sh <= max_share && rho >= min_rho)) labels[1] else
      labels[2],
    rho_reff_stage2_cost = if (sum(k) >= 3L) {
      stats::cor(sg(reff[k]), sg(cost_stage2[k]), method = "spearman")
    } else NA_real_,
    partial_rho_reff_stage2_cost_gap =
      circ_partial_spearman(sg(reff[k]), sg(cost_stage2[k]), cmp$gap_km[k]),
    median_redundancy = stats::median(redundancy[k]),
    median_top_current_share = stats::median(top_share[k]),
    top_current_cells = as.integer(top_cells),
    stringsAsFactors = FALSE)
}

# ---- The hand-made case of STEP 17.3 (h1 of task 17.2) -----------------------------------
# Made-up lines, cells and pairs only. Returns a data frame: check, pass.
circ_self_test_173 <- function() {
  res <- list()
  chk <- function(name, ok) res[[length(res) + 1L]] <<-
    data.frame(check = name, pass = isTRUE(ok), stringsAsFactors = FALSE)
  near <- function(a, b, tol = 1e-9) {
    length(a) == length(b) && all(abs(a - b) <= tol * pmax(1, abs(b)))
  }
  crs <- sf::st_crs(CRS_ANALYSIS)
  ln <- function(m) sf::st_linestring(matrix(m, ncol = 2, byrow = TRUE))
  sq <- function(x0, y0, s) {
    sf::st_polygon(list(rbind(c(x0, y0), c(x0 + s, y0), c(x0 + s, y0 + s),
                              c(x0, y0 + s), c(x0, y0))))
  }
  # 1. The share of a line inside polygons. Two squares of 10 km side by
  #    side (0-20 km); a line of 40 km from x = -10 to 30 km at y = 5 km.
  polys <- sf::st_sfc(sq(0, 0, 1e4), sq(1e4, 0, 1e4), crs = crs)
  lines <- sf::st_sfc(ln(c(-1e4, 5e3, 3e4, 5e3)), ln(c(2e3, 2e3, 8e3, 8e3)),
                      sf::st_linestring(), ln(c(5e4, 0, 6e4, 0)), crs = crs)
  sh <- circ_line_share_in(lines, polys)
  chk("share in polygons: 20 of 40 km = 0.5; inside = 1; empty = NA; outside = 0",
      near(sh[c(1, 2, 4)], c(0.5, 1, 0)) && is.na(sh[3]))
  chk("share in polygons: no polygon gives 0",
      near(circ_line_share_in(lines[1], sf::st_sfc(crs = crs)), 0))
  chk("share in polygons: lines and polygons in two CRS stop the function",
      inherits(try(circ_line_share_in(lines, sf::st_transform(polys, 4326)),
                   silent = TRUE), "try-error"))
  # 2. The top cells (FC1). 12 made-up cells; a tie across the class break
  #    goes to the lower id; the two cells with 0 take the last two ranks
  #    (the lowest class holds 2 cells: ceiling(12 / 5 x j) steps).
  ids <- c(105L, 101L, 109L, 103L, 111L, 102L, 104L, 110L, 106L, 108L,
           107L, 112L)
  val <- c(5, 9, 9, 1, 0, 3, 2, 7, 0, 4, 6, 0.5)
  rc <- sdm_rank_class(val, ids, 5L)
  top <- rc$class == 5L
  chk("top cells: the top class holds ceiling(n / 5) = 3 cells = ceiling(0.2 n)",
      sum(top) == 3L && sum(top) == ceiling(0.2 * length(val)))
  chk("top cells: a tie at the break goes to the lower id (101 and 109 at 9; 110 at 7)",
      setequal(ids[top], c(101L, 109L, 110L)))
  chk("top cells: the cells with 0 take the last ranks (106, then 111) and the lowest class",
      identical(rc$rank[match(c(106L, 111L), ids)], c(11L, 12L)) &&
      all(rc$class[val == 0] == 1L))
  # 3. CC1: circ_compare_paths() against lcp_compare_variant() on made-up
  #    Stage-2 style layers: 6 pairs, pair 6 contiguous (not compared).
  bl <- list(ln(c(0, 0, 1e5, 0)), ln(c(0, 1e4, 0, 9e4)),
             ln(c(0, 0, 5e4, 5e4)), ln(c(2e4, 0, 2e4, 6e4, 5e4, 6e4)),
             ln(c(0, -2e4, 8e4, -2e4)), sf::st_linestring())
  vl <- list(ln(c(0, 1.5e4, 1e5, 1.5e4)), ln(c(5e4, 1e4, 5e4, 9e4)),
             ln(c(0, 0, 5e4, 5.5e4)), ln(c(2e4, 0, 2e4, 6e4, 5e4, 6e4)),
             ln(c(0, -2e4, 4e4, 3e4, 8e4, -2e4)), sf::st_linestring())
  mk <- function(g, cost, surf) {
    gg <- sf::st_sfc(g, crs = crs)
    sf::st_sf(pair_id = 1:6, surface = surf,
              from_name = paste0("A", 1:6), to_name = paste0("B", 1:6),
              gap_km = c(10, 20, 30, 40, 50, 0),
              contiguous = c(rep(FALSE, 5), TRUE),
              path_status = c(rep("path", 5), "contiguous"),
              cost_rkm = cost, path_km = as.numeric(sf::st_length(gg)) / 1000,
              in_network = TRUE, via_unit_ids = "", geometry = gg)
  }
  b6 <- mk(bl, c(100, 400, 300, 200, 500, 0), "baseline")
  v6 <- mk(vl, c(150, 300, 300, 600, 500, 0), "noghm")
  ref <- lcp_compare_variant(b6, v6, 20, c(5, 10, 20, 40), 0.5, 0.25)
  own <- circ_compare_paths(b6, v6, sf::st_drop_geometry(b6), !b6$contiguous,
                            "noghm", "baseline", 20, c(5, 10, 20, 40), 0.5,
                            0.25)
  cols <- c("share_base_in_variant", "share_variant_in_base", "route_overlap",
            "route_overlap_5km", "route_overlap_10km", "route_overlap_20km",
            "route_overlap_40km", "cost_base", "cost_variant", "rank_base",
            "rank_variant", "rank_change", "material_route", "material_rank",
            "material_pair", "path_length_ratio")
  oc <- own[own$compared, ]
  same <- all(vapply(cols, function(cn) {
    a <- oc[[cn]]; b <- ref[[cn]]
    if (is.logical(b)) identical(as.logical(a), b) else near(a, b, 1e-12)
  }, logical(1)))
  chk("CC1: the same values as lcp_compare_variant() (Decision 18) for each compared pair",
      same && identical(oc$pair_id, ref$pair_id))
  chk("CC1: the made-up case has material and other pairs (the test has power)",
      any(ref$material_pair) && !all(ref$material_pair) &&
      any(ref$material_route) && any(ref$material_rank))
  chk("R4: a pair that is not compared has a row, with NA in each column of Decision 18",
      nrow(own) == 6L && !own$compared[6] &&
      all(is.na(unlist(own[6, cols]))))
  vn <- v6
  vn$cost_rkm[c(2, 3)] <- c(300, 300 * (1 + 4e-16))   # equal but for the last bits
  own_n <- circ_compare_paths(b6, vn, sf::st_drop_geometry(b6), !b6$contiguous,
                              "noghm", "baseline", 20, c(5, 10, 20, 40), 0.5,
                              0.25)
  chk("NT1: two costs that differ only in the last bits get the average rank",
      vn$cost_rkm[2] != vn$cost_rkm[3] &&
        near(own_n$rank_variant[2], own_n$rank_variant[3], 0) &&
        near(own_n$rank_variant[2], 0.375, 1e-12))
  chk("CC1: a compared pair with no path stops the function",
      inherits(try(circ_compare_paths(b6, v6, sf::st_drop_geometry(b6),
                                      rep(TRUE, 6), "x", "y"), silent = TRUE),
               "try-error"))
  # 4. The partial Spearman rho: the residual form on made-up values.
  x <- c(3, 1, 4, 1, 5, 9, 2, 6, 5, 3)
  y <- c(2, 7, 1, 8, 2, 8, 1, 8, 2, 8)
  z <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
  rx <- rank(x); ry <- rank(y); rz <- rank(z)
  by_res <- stats::cor(stats::resid(stats::lm(rx ~ rz)),
                       stats::resid(stats::lm(ry ~ rz)))
  chk("partial rho: equal to the correlation of the rank residuals given z",
      near(circ_partial_spearman(x, y, z), by_res, 1e-12))
  chk("partial rho: fewer than 4 values, or x equal to z, gives NA",
      is.na(circ_partial_spearman(1:3, 3:1, 1:3)) &&
      is.na(circ_partial_spearman(z, y, z)))
  # 5. The label (Decision 18 points 5-6 with the words of point 7).
  mk_cmp <- function(mat, cb, cv) {
    data.frame(surface = "s", reference = "r", compared = TRUE,
               gap_km = seq_along(mat), material_route = mat,
               material_rank = FALSE, material_pair = mat,
               route_overlap = ifelse(mat, 0.2, 0.9), cost_base = cb,
               cost_variant = cv)
  }
  one <- function(cmp) {
    n <- nrow(cmp)
    circ_compare_summary(cmp, rep("path", n), seq_len(n), rep(2, n),
                         seq_len(n), rep(0.5, n), 3L, c("agrees", "differs"),
                         0.2, 0.9)$label
  }
  c10 <- 1:10
  chk("label: 1 of 10 material and rho 1 -> agrees",
      one(mk_cmp(c(TRUE, rep(FALSE, 9)), c10, c10)) == "agrees")
  chk("label: 2 of 10 material (= 20 %) -> agrees; 3 of 10 -> differs",
      one(mk_cmp(c(TRUE, TRUE, rep(FALSE, 8)), c10, c10)) == "agrees" &&
      one(mk_cmp(c(TRUE, TRUE, TRUE, rep(FALSE, 7)), c10, c10)) == "differs")
  chk("label: no material pair but rho below 0.9 -> differs",
      one(mk_cmp(rep(FALSE, 10), c10, c(2, 1, 4, 3, 6, 5, 8, 7, 10, 9) *
                   c(1, 1, 1, 1, 1, 1, 1, 1, 1, 0.1))) == "differs")
  do.call(rbind, res)
}

# =============================================================================
# Task 17.6 (2026-11-14): STEP 17.4 — the QA of phase 1 (process choices QS1,
# QE1, QP1, QO1, QT1 and QF of task 17.6). A second path: these functions
# call no circ_* function of STEPs 17.1 to 17.3, no igraph function and not
# lcp_route_share(). STEP 17.4 gives them the files that STEPs 17.1 to 17.3
# wrote.
#   circ_qa_check_config()   the SDMRES_QA_* settings
#   circ_qa_x_r()            the input x and the resistance from the rank
#   circ_qa_dist_km()        the distance between two points on the sphere
#                            (the atan2 form of the haversine)
#   circ_qa_links()          the 8-neighbour links by terra::adjacent()
#   circ_qa_components()     the connected sets by the smallest label (no
#                            igraph)
#   circ_qa_reserve_cells()  the model cells of a reserve by
#                            terra::rasterize() (the cell centres)
#   circ_qa_pcg()            a conjugate-gradient solve with a Jacobi
#                            preconditioner (no CHOLMOD)
#   circ_qa_solve_pair()     the effective resistance, the node currents and
#                            three identities of one pair (QE1)
#   circ_qa_dijkstra()       a least-cost search in base R (QP1)
#   circ_qa_line_cells()     the cells (ix, iy) of a written path line
#   circ_qa_point_share()    the share of a line within d of another line,
#                            by points (QO1)
#   circ_qa_point_share_in() the share of a line inside polygons, by points
#   circ_qa_rank01()         the percentile rank, ties at the average rank
#   circ_qa_partial_rho()    the partial rho from the residuals of the ranks
#   circ_qa_classes()        the classes of equal count by rank
#   circ_qa_self_test()      the hand-made case of STEP 17.4
# =============================================================================

SDMRES_QA_NEEDED <- c("SDMRES_QA_TOL_REL", "SDMRES_QA_PCG_TOL",
                      "SDMRES_QA_PCG_MAXIT", "SDMRES_QA_POINT_STEP_M",
                      "SDMRES_QA_SHARE_TOL")

circ_qa_check_config <- function() {
  miss <- SDMRES_QA_NEEDED[!vapply(SDMRES_QA_NEEDED, exists, logical(1))]
  if (length(miss) > 0) {
    stop("Setting(s) missing from R/00_config.R (task 17.6): ",
         paste(miss, collapse = ", "), call. = FALSE)
  }
  one_num <- function(v) is.numeric(v) && length(v) == 1L && !is.na(v)
  list(
    "SDMRES_QA_TOL_REL must be SDMRES_CHECK_TOL_REL (the limit of Decision 17)" =
      identical(SDMRES_QA_TOL_REL, SDMRES_CHECK_TOL_REL),
    "SDMRES_QA_PCG_TOL must be above 0 and below SDMRES_QA_TOL_REL / 1000" =
      one_num(SDMRES_QA_PCG_TOL) && SDMRES_QA_PCG_TOL > 0 &&
      SDMRES_QA_PCG_TOL < SDMRES_QA_TOL_REL / 1000,
    "SDMRES_QA_PCG_MAXIT must be a whole number of 1,000 or more" =
      one_num(SDMRES_QA_PCG_MAXIT) &&
      SDMRES_QA_PCG_MAXIT == round(SDMRES_QA_PCG_MAXIT) &&
      SDMRES_QA_PCG_MAXIT >= 1000,
    "SDMRES_QA_POINT_STEP_M must be above 0 and 1,000 m or less (QO1)" =
      one_num(SDMRES_QA_POINT_STEP_M) && SDMRES_QA_POINT_STEP_M > 0 &&
      SDMRES_QA_POINT_STEP_M <= 1000,
    "SDMRES_QA_SHARE_TOL must be above 0 and 0.1 or less (QO1)" =
      one_num(SDMRES_QA_SHARE_TOL) && SDMRES_QA_SHARE_TOL > 0 &&
      SDMRES_QA_SHARE_TOL <= 0.1
  )
}

# The input x and the resistance from the rank (Decision 27 points 1-2),
# written again: x = (n - rank) / (n - 1); linear: R = R_MAX - (R_MAX -
# R_MIN) x; negexp: R = R_MAX - (R_MAX - R_MIN) (1 - e^(-c x)) / (1 - e^(-c)).
circ_qa_x_r <- function(rank, n, form, r_min = SDMRES_R_MIN,
                        r_max = SDMRES_R_MAX, c = SDMRES_NEGEXP_C) {
  x <- (n - rank) / (n - 1)
  r <- if (identical(form, "linear")) {
    r_max - (r_max - r_min) * x
  } else if (identical(form, "negexp")) {
    r_max - (r_max - r_min) * (1 - exp(-c * x)) / (1 - exp(-c))
  } else {
    stop("circ_qa_x_r(): unknown form.", call. = FALSE)
  }
  list(x = x, r = r)
}

# The distance (km) between two points on the sphere of radius r_km: the
# atan2 form of the haversine.
circ_qa_dist_km <- function(lon1, lat1, lon2, lat2,
                            r_km = GISTAR_EARTH_RADIUS_KM) {
  k <- pi / 180
  h <- sin((lat2 - lat1) * k / 2)^2 +
    cos(lat1 * k) * cos(lat2 * k) * sin((lon2 - lon1) * k / 2)^2
  2 * r_km * atan2(sqrt(h), sqrt(1 - h))
}

# The 8-neighbour links of the cells (ix, iy) by terra::adjacent() on a plane
# raster of the index frame. Returns a data frame: from, to (the positions
# in the input; from < to), type, d_km (circ_qa_dist_km() between the
# centres).
circ_qa_links <- function(ix, iy, deg = SDM_GRAIN_DEG) {
  n <- length(ix)
  x0 <- min(ix); y1 <- max(iy)
  nx <- max(ix) - x0 + 1L; ny <- y1 - min(iy) + 1L
  r <- terra::rast(nrows = ny, ncols = nx, xmin = 0, xmax = nx, ymin = 0,
                   ymax = ny, crs = "local")
  cell <- (y1 - iy) * nx + (ix - x0) + 1          # row-major from the top left
  pos <- rep(NA_integer_, nx * ny)
  pos[cell] <- seq_len(n)
  adj <- terra::adjacent(r, cell, directions = "queen", pairs = TRUE)
  p1 <- pos[adj[, 1]]; p2 <- pos[adj[, 2]]
  keep <- !is.na(p1) & !is.na(p2)
  a <- pmin(p1[keep], p2[keep]); b <- pmax(p1[keep], p2[keep])
  u <- !duplicated(paste(a, b))
  a <- a[u]; b <- b[u]
  type <- ifelse(ix[a] == ix[b] | iy[a] == iy[b], "rook", "diagonal")
  d <- circ_qa_dist_km((ix[a] + 0.5) * deg, (iy[a] + 0.5) * deg,
                       (ix[b] + 0.5) * deg, (iy[b] + 0.5) * deg)
  o <- order(a, b)
  data.frame(from = a[o], to = b[o], type = type[o], d_km = d[o],
             stringsAsFactors = FALSE)
}

# The connected sets: each node takes the smallest label of its neighbours
# until no label changes (no igraph). Returns the smallest node number of
# the set of each node.
circ_qa_components <- function(n, from, to) {
  lab <- seq_len(n)
  f <- c(from, to); t <- c(to, from)
  repeat {
    cand <- lab[t]
    o <- order(f, cand)
    ff <- f[o]; cc <- cand[o]
    first <- !duplicated(ff)
    new <- lab
    new[ff[first]] <- pmin(lab[ff[first]], cc[first])
    if (identical(new, lab)) break
    lab <- new
  }
  lab
}

# The model cells of one reserve polygon (the centre rule of Decision 25 h1)
# by terra::rasterize() of the polygon on the cell-id raster (a cell counts if
# its centre is inside). Returns list(ids = the sorted 0.2 degree cell ids,
# id_1km = the 0.2 degree cell id of each 1 km cell; NA cells left out).
circ_qa_reserve_cells <- function(geom, cellid_r) {
  v <- terra::vect(sf::st_sf(geometry = geom))
  cr <- terra::crop(cellid_r, terra::ext(v), snap = "out")
  m <- terra::rasterize(v, cr, field = 1, touches = FALSE, background = NA)
  ids <- terra::values(cr, mat = FALSE)[!is.na(terra::values(m, mat = FALSE))]
  ids <- ids[!is.na(ids)]
  list(ids = sort(unique(as.integer(ids))), id_1km = as.integer(ids))
}

# A conjugate-gradient solve of A x = b (A symmetric positive definite, a
# sparse Matrix) with a Jacobi preconditioner. Stops when the residual is
# tol x |b| or less. Returns list(x, it, converged).
circ_qa_pcg <- function(A, b, tol = SDMRES_QA_PCG_TOL,
                        maxit = SDMRES_QA_PCG_MAXIT) {
  dinv <- 1 / Matrix::diag(A)
  x <- numeric(length(b)); r <- b; z <- dinv * r; p <- z
  rz <- sum(r * z); nb <- sqrt(sum(b^2))
  for (it in seq_len(maxit)) {
    Ap <- as.vector(A %*% p)
    al <- rz / sum(p * Ap)
    x <- x + al * p
    r <- r - al * Ap
    if (sqrt(sum(r^2)) <= tol * nb) {
      return(list(x = x, it = it, converged = TRUE))
    }
    z <- dinv * r
    rz2 <- sum(r * z)
    p <- z + (rz2 / rz) * p
    rz <- rz2
  }
  list(x = x, it = maxit, converged = FALSE)
}

# One pair by the second engine (QE1). The nodes of a are joined into one
# node with 1 A in; the nodes of b are the ground; only the connected set of
# a (comp) is used. Returns list(reff, reff_swap (b in, a the ground),
# energy (sum of g dV^2 with 1 A), kirchhoff (the largest net current at a
# node that is not in a or b), out_a (the current out of a), current (the
# node current, 1/2 sum |I|, 0 in a and b), it, converged).
circ_qa_solve_pair <- function(n, from, to, g, a, b, comp) {
  keep <- which(comp == comp[a[1]])
  if (!all(b %in% keep)) stop("circ_qa_solve_pair(): b is not in the set of a.",
                              call. = FALSE)
  one <- function(src, gnd) {
    others <- setdiff(keep, c(src, gnd))
    map <- rep(NA_integer_, n)
    map[src] <- 1L
    map[others] <- seq_along(others) + 1L
    k <- length(others) + 1L
    use <- from %in% keep & to %in% keep
    mf <- map[from[use]]; mt <- map[to[use]]; gu <- g[use]
    both <- !is.na(mf) & !is.na(mt) & mf != mt
    ii <- c(mf[both], mt[both], mf[both], mt[both])
    jj <- c(mt[both], mf[both], mf[both], mt[both])
    xx <- c(-gu[both], -gu[both], gu[both], gu[both])
    to_gnd <- xor(is.na(mf), is.na(mt))         # a link to the ground
    dn <- ifelse(is.na(mf), mt, mf)[to_gnd]
    ii <- c(ii, dn); jj <- c(jj, dn); xx <- c(xx, gu[to_gnd])
    A <- Matrix::sparseMatrix(i = ii, j = jj, x = xx, dims = c(k, k))
    rhs <- numeric(k); rhs[1] <- 1
    s <- circ_qa_pcg(A, rhs)
    v <- numeric(n)
    v[src] <- s$x[1]
    v[others] <- s$x[-1]
    list(v = v, it = s$it, converged = s$converged)
  }
  s1 <- one(a, b)
  s2 <- one(b, a)
  v <- s1$v
  use <- from %in% keep & to %in% keep
  I <- ifelse(use, g * (v[from] - v[to]), 0)   # the current from -> to
  rs <- rowsum(c(I, -I), c(from, to))          # the net current out of a node
  net <- numeric(n)
  net[as.integer(rownames(rs))] <- rs[, 1]
  ab <- c(a, b)
  out_a <- sum(net[a])
  cur <- numeric(n)
  s <- rowsum(c(abs(I), abs(I)), c(from, to), reorder = TRUE)
  cur[as.integer(rownames(s))] <- 0.5 * s[, 1]
  cur[ab] <- 0
  list(reff = v[a[1]], reff_swap = s2$v[b[1]],
       energy = sum(g[use] * (v[from[use]] - v[to[use]])^2),
       kirchhoff = max(abs(net[setdiff(keep, ab)])), out_a = out_a,
       current = cur, it = max(s1$it, s2$it),
       converged = s1$converged && s2$converged)
}

# A least-cost search in base R (QP1): from all nodes of a (cost 0) to the
# first node of b that the search settles. Returns list(cost, nodes (the
# path from a node of a to a node of b)). cost Inf and no nodes if b cannot
# be reached.
circ_qa_dijkstra <- function(n, from, to, w, a, b) {
  f <- c(from, to); t <- c(to, from); ww <- c(w, w)
  o <- order(f); f <- f[o]; t <- t[o]; ww <- ww[o]
  cnt <- tabulate(f, n); start <- cumsum(c(1L, cnt))[seq_len(n)]
  dist <- rep(Inf, n); pred <- rep(NA_integer_, n); done <- rep(FALSE, n)
  dist[a] <- 0
  open <- dist
  isb <- rep(FALSE, n); isb[b] <- TRUE
  repeat {
    u <- which.min(open)
    if (!is.finite(open[u])) return(list(cost = Inf, nodes = integer(0)))
    if (isb[u]) break
    done[u] <- TRUE; open[u] <- Inf
    if (cnt[u] > 0L) {
      idx <- start[u]:(start[u] + cnt[u] - 1L)
      v <- t[idx]; nd <- dist[u] + ww[idx]
      better <- !done[v] & nd < dist[v]
      dist[v[better]] <- nd[better]; open[v[better]] <- nd[better]
      pred[v[better]] <- u
    }
  }
  path <- u
  while (!is.na(pred[path[1]])) path <- c(pred[path[1]], path)
  list(cost = dist[u], nodes = path)
}

# The cells (ix, iy) of a written path line: its vertices from the CRS of
# the line to longitude and latitude. Returns a data frame: ix, iy, ok (each
# vertex is at a cell centre, within 1e-6 of a cell).
circ_qa_line_cells <- function(line, deg = SDM_GRAIN_DEG) {
  xy <- sf::st_coordinates(line)[, 1:2, drop = FALSE]
  ll <- sf::sf_project(from = sf::st_crs(line), to = sf::st_crs(4326),
                       pts = xy)
  fx <- ll[, 1] / deg; fy <- ll[, 2] / deg
  ix <- floor(fx); iy <- floor(fy)
  data.frame(ix = as.integer(ix), iy = as.integer(iy),
             ok = abs(fx - ix - 0.5) < 1e-6 & abs(fy - iy - 0.5) < 1e-6)
}

# The points along a line at a step of step_m: the centres of n equal parts
# (n = the length / step_m, rounded up). An empty line gives no point.
circ_qa_points <- function(line, step_m) {
  len <- as.numeric(sf::st_length(line))
  if (sf::st_is_empty(line) || len == 0) return(NULL)
  n <- max(1L, as.integer(ceiling(len / step_m)))
  sf::st_cast(sf::st_line_sample(line, sample = (seq_len(n) - 0.5) / n),
              "POINT")
}

# The share of the line a within d_km of the line b, by points (QO1).
circ_qa_point_share <- function(a, b, d_km, step_m = SDMRES_QA_POINT_STEP_M) {
  pts <- circ_qa_points(a, step_m)
  if (is.null(pts) || sf::st_is_empty(b)) return(NA_real_)
  mean(lengths(sf::st_is_within_distance(pts, b, dist = d_km * 1000)) > 0)
}

# The share of the line a inside the polygons u (one geometry, a union), by
# points (QO1).
circ_qa_point_share_in <- function(a, u, step_m = SDMRES_QA_POINT_STEP_M) {
  pts <- circ_qa_points(a, step_m)
  if (is.null(pts)) return(NA_real_)
  if (length(u) == 0) return(0)
  mean(lengths(sf::st_intersects(pts, u)) > 0)
}

# The percentile rank (rank - 1) / (n - 1), ties at the average rank.
circ_qa_rank01 <- function(x) (rank(x, ties.method = "average") - 1) /
  (length(x) - 1)

# The partial rho of x and y given z: the Pearson correlation of the
# residuals of the ranks of x and of y on the ranks of z.
circ_qa_partial_rho <- function(x, y, z) {
  rx <- rank(x); ry <- rank(y); rz <- rank(z)
  stats::cor(stats::resid(stats::lm(rx ~ rz)), stats::resid(stats::lm(ry ~ rz)))
}

# The classes of equal count by rank: the cells in the order of the value
# (highest first; a tie to the lower id); position p is in class k - j + 1,
# with j the smallest j such that p <= ceiling(j n / k).
circ_qa_classes <- function(value, id, k) {
  n <- length(value)
  p <- integer(n)
  p[order(-value, id)] <- seq_len(n)
  bounds <- ceiling(seq_len(k) * n / k)
  j <- findInterval(p - 1, bounds) + 1L
  as.integer(k - j + 1L)
}

# ---- The hand-made case of STEP 17.4 ----------------------------------------------------
# Made-up values, cells, circuits, graphs and lines only. Returns a data
# frame: check, pass.
circ_qa_self_test <- function() {
  res <- list()
  chk <- function(name, ok) res[[length(res) + 1L]] <<-
    data.frame(check = name, pass = isTRUE(ok), stringsAsFactors = FALSE)
  near <- function(a, b, tol = 1e-9) {
    length(a) == length(b) && all(abs(a - b) <= tol * pmax(1, abs(b)))
  }
  # 1. The resistance from the rank.
  lin <- circ_qa_x_r(1:5, 5L, "linear", 1, 100, 8)
  chk("x and R: ranks 1 to 5 give x = 1 to 0 and R = 1, 25.75, 50.5, 75.25, 100",
      near(lin$x, c(1, 0.75, 0.5, 0.25, 0)) &&
      near(lin$r, c(1, 25.75, 50.5, 75.25, 100)))
  ne <- circ_qa_x_r(c(10, 9, 6), 11L, "negexp", 1, 100, 8)  # x = 0.1, 0.2, 0.5
  chk("x and R: negexp8 gives about 45.5, 21.0 and 2.8 at x = 0.1, 0.2 and 0.5 (Decision 27 point 2)",
      identical(round(ne$r, 1), c(45.5, 21.0, 2.8)))
  # 2. The distance on the sphere.
  chk("distance: 1 degree of latitude = r x pi / 180; 0 for one point",
      near(circ_qa_dist_km(80, 20, 80, 21, 6371.0088), 6371.0088 * pi / 180) &&
      circ_qa_dist_km(80, 20, 80, 20) == 0)
  # 3. The links: an L of 3 cells and a cell on a diagonal; a cell alone.
  ix <- c(10L, 11L, 10L, 12L, 20L); iy <- c(5L, 5L, 6L, 6L, 5L)
  L <- circ_qa_links(ix, iy, 0.2)
  key <- paste(L$from, L$to, L$type)
  chk("links: 1-2 and 1-3 rook; 2-3 and 2-4 diagonal; the cell alone has no link",
      setequal(key, c("1 2 rook", "1 3 rook", "2 3 diagonal", "2 4 diagonal")))
  chk("links: the length is the distance between the centres",
      near(L$d_km[1], circ_qa_dist_km(2.1, 1.1, 2.3, 1.1)))
  # 4. The connected sets.
  cm <- circ_qa_components(6L, c(1L, 2L, 4L), c(2L, 3L, 5L))
  chk("sets: {1, 2, 3}, {4, 5} and {6} (the smallest node of each set)",
      identical(cm, c(1L, 1L, 1L, 4L, 4L, 6L)))
  # 5. The cells of a reserve: a made-up raster of 10 x 10 cells of 1 km with
  #    ids by column pair; a square that covers the centres of 3 x 2 cells.
  cr <- terra::rast(nrows = 10, ncols = 10, xmin = 0, xmax = 1e4, ymin = 0,
                    ymax = 1e4, crs = "EPSG:7755")
  terra::values(cr) <- rep(c(1L, 1L, 2L, 2L, 3L, 3L, 4L, 4L, NA, 5L), 10)
  sq <- sf::st_sfc(sf::st_polygon(list(rbind(c(1200, 7200), c(4200, 7200),
    c(4200, 9200), c(1200, 9200), c(1200, 7200)))), crs = 7755)
  rq <- circ_qa_reserve_cells(sq, cr)
  chk("reserve cells: the centres of columns 2-4 and rows 1-2 give ids 1 and 2 (6 cells of 1 km)",
      identical(rq$ids, c(1L, 2L)) && length(rq$id_1km) == 6L)
  # 6. The second solver (QE1): series, parallel, bridge.
  sp <- function(n, L, a, b) {
    circ_qa_solve_pair(n, L[, 1], L[, 2], 1 / L[, 3], a, b,
                       circ_qa_components(n, L[, 1], L[, 2]))
  }
  s1 <- sp(3L, rbind(c(1, 2, 3), c(2, 3, 5)), 1L, 3L)
  chk("solver: series R = 8, the middle node 1 A, the ends 0",
      near(s1$reff, 8, 1e-9) && near(s1$current, c(0, 1, 0), 1e-9))
  s2 <- sp(3L, rbind(c(1, 2, 4), c(1, 3, 2), c(3, 2, 2)), 1L, 2L)
  chk("solver: parallel R = 2; the middle node 0.5 A",
      near(s2$reff, 2, 1e-9) && near(s2$current[3], 0.5, 1e-9))
  s3 <- sp(4L, rbind(c(1, 3, 1), c(1, 4, 2), c(3, 2, 2), c(4, 2, 1),
                     c(3, 4, 1)), 1L, 2L)
  chk("solver: unbalanced bridge R = 1.4; the same with the ends swapped; energy = R; 1 A out; no net current at C and D",
      near(s3$reff, 1.4, 1e-9) && near(s3$reff_swap, 1.4, 1e-9) &&
      near(s3$energy, 1.4, 1e-9) && near(s3$out_a, 1, 1e-9) &&
      s3$kirchhoff < 1e-9 && isTRUE(s3$converged))
  s4 <- sp(5L, rbind(c(1, 3, 2), c(2, 3, 2), c(3, 4, 1), c(4, 5, 7)),
           c(1L, 2L), 4L)
  chk("solver: a reserve of two cells (1 || 2 to 3, then 4): R = 1 + 1 = 2; node 5 (a dead end) 0 A",
      near(s4$reff, 2, 1e-9) && near(s4$current[5], 0, 1e-9) &&
      near(s4$current[3], 1, 1e-9))
  # 7. The least-cost search (QP1).
  Lw <- rbind(c(1, 2, 1), c(2, 3, 1), c(1, 3, 5), c(3, 4, 1), c(5, 6, 1))
  d1 <- circ_qa_dijkstra(6L, Lw[, 1], Lw[, 2], Lw[, 3], 1L, 4L)
  chk("search: 1-2-3-4 at cost 3 (not 1-3-4 at 6)",
      d1$cost == 3 && identical(d1$nodes, c(1L, 2L, 3L, 4L)))
  d2 <- circ_qa_dijkstra(6L, Lw[, 1], Lw[, 2], Lw[, 3], c(1L, 3L), 4L)
  chk("search: from two nodes, the path starts at the nearer one (3) at cost 1",
      d2$cost == 1 && identical(d2$nodes, c(3L, 4L)))
  chk("search: no route gives cost Inf",
      is.infinite(circ_qa_dijkstra(6L, Lw[, 1], Lw[, 2], Lw[, 3], 1L, 6L)$cost))
  # 8. The cells of a line through cell centres (EPSG:7755).
  ll <- cbind(c(80.1, 80.3, 80.5), c(20.1, 20.1, 20.3))
  xy <- sf::sf_project(from = sf::st_crs(4326), to = sf::st_crs(7755), pts = ll)
  lc <- circ_qa_line_cells(sf::st_sfc(sf::st_linestring(xy), crs = 7755), 0.2)
  chk("line cells: the vertices give the cells (400, 100), (401, 100), (402, 101)",
      identical(lc$ix, c(400L, 401L, 402L)) && identical(lc$iy, c(100L, 100L, 101L)) &&
      all(lc$ok))
  # 9. The shares by points (QO1): a line of 40 km and one of 40 km that
  #    starts 20 km to the east; within 1 km: 21 of 40 km.
  la <- sf::st_sfc(sf::st_linestring(rbind(c(-1e4, 0), c(3e4, 0))), crs = 7755)
  lb <- sf::st_sfc(sf::st_linestring(rbind(c(1e4, 0), c(5e4, 0))), crs = 7755)
  chk("share by points: 0.525 (21 of 40 km within 1 km), the same as the exact share",
      near(circ_qa_point_share(la, lb, 1, 250), 0.525, 1e-12))
  u <- sf::st_union(sf::st_sfc(sf::st_polygon(list(rbind(c(0, -5e3), c(2e4, -5e3),
    c(2e4, 5e3), c(0, 5e3), c(0, -5e3)))), crs = 7755))
  chk("share in polygons by points: 20 of 40 km = 0.5; an empty line gives NA",
      near(circ_qa_point_share_in(la, u, 250), 0.5, 1e-12) &&
      is.na(circ_qa_point_share_in(sf::st_sfc(sf::st_linestring(), crs = 7755), u)))
  # 10. Ranks, partial rho and classes.
  chk("rank: (rank - 1) / (n - 1) with a tie at the average rank",
      near(circ_qa_rank01(c(10, 20, 20, 40)), c(0, 0.5, 0.5, 1)))
  chk("rank (NT1): 20 and 20 x (1 + 4e-16) are a tie after signif(, 12)",
      near(circ_qa_rank01(signif(c(10, 20, 20 * (1 + 4e-16), 40), 12)),
           c(0, 0.5, 0.5, 1)))
  x <- c(3, 1, 4, 1, 5, 9, 2, 6, 5, 3); y <- c(2, 7, 1, 8, 2, 8, 1, 8, 2, 8)
  z <- 1:10
  r3 <- stats::cor(cbind(rank(x), rank(y), rank(z)))
  pf <- (r3[1, 2] - r3[1, 3] * r3[2, 3]) / sqrt((1 - r3[1, 3]^2) * (1 - r3[2, 3]^2))
  chk("partial rho: the residual form = the formula of the three rank correlations",
      near(circ_qa_partial_rho(x, y, z), pf, 1e-12))
  ids <- c(105L, 101L, 109L, 103L, 111L, 102L, 104L, 110L, 106L, 108L,
           107L, 112L)
  val <- c(5, 9, 9, 1, 0, 3, 2, 7, 0, 4, 6, 0.5)
  cl <- circ_qa_classes(val, ids, 5L)
  chk("classes: sizes 3, 2, 3, 2, 2 (classes 5 to 1); the top class 101, 109, 110",
      identical(as.integer(table(factor(cl, levels = 5:1))), c(3L, 2L, 3L, 2L, 2L)) &&
      setequal(ids[cl == 5L], c(101L, 109L, 110L)))
  do.call(rbind, res)
}

# =============================================================================
# Task 17.6b (2026-11-14): STEP 17.5 — phase 2 (Decision 27 points 6, 8 and
# 9; the author's answer "R5, R6 confirmed; F2a, T2a, Q2a, new QA slug").
#   circ_phase2_pairs()    all pairs of the reserves with a polygon, from the
#                          lower unit_id to the higher one (R5), with the link
#                          to the pairs of Decision 17
#   circ_run_pairs()       the circuit and the least-cost path of each pair,
#                          with the checks of STEP 17.2 (F2a)
#   circ_pair_rule()       point 8: the rank of the effective resistance
#                          (NT1, then the tie rule; R6), the lowest pairs, the
#                          lowest partner of each reserve, the share, the count
#   circ_phase2_summary()  tbl_19_sdmres_phase2_summary.csv (T2a)
#   circ_self_test_175()   the hand-made case of STEP 17.5
#   circ_qa_pair_rule()    point 8 again by a count of the pairs before each
#                          pair (the QA of phase 2, Q2a)
# =============================================================================

# All pairs of the reserves (unit_id, unit_name; one row per reserve with a
# polygon), from the lower unit_id to the higher one (R5), in that order.
# d17: tbl_12_reserve_pairs.csv (pair_id, from_unit_id, to_unit_id). Returns
# a data frame: p2_id, from_unit_id, from_name, to_unit_id, to_name,
# decision17, pair_id_decision17.
circ_phase2_pairs <- function(unit_id, unit_name, d17) {
  if (anyDuplicated(unit_id) || length(unit_id) < 2L) {
    stop("circ_phase2_pairs(): two or more reserves, each once.", call. = FALSE)
  }
  o <- order(unit_id)
  u <- as.integer(unit_id[o])
  nm <- unit_name[o]
  cmb <- utils::combn(length(u), 2L)
  p <- data.frame(p2_id = seq_len(ncol(cmb)),
                  from_unit_id = u[cmb[1, ]], from_name = nm[cmb[1, ]],
                  to_unit_id = u[cmb[2, ]], to_name = nm[cmb[2, ]],
                  stringsAsFactors = FALSE)
  dk <- paste(pmin(d17$from_unit_id, d17$to_unit_id),
              pmax(d17$from_unit_id, d17$to_unit_id))
  m <- match(paste(p$from_unit_id, p$to_unit_id), dk)
  p$decision17 <- !is.na(m)
  p$pair_id_decision17 <- as.integer(d17$pair_id[m])
  p
}

# The circuit (Z1) and the least-cost path of each pair, with the checks of
# STEP 17.2 for each pair (1 A out of the first reserve; (iii) the cost again
# from the cells; the cost not below the effective resistance; the path from
# one reserve to the other). A failure stops with the row id.
#   info   : a data frame, one row per pair (copied to the output); id_col
#            names its id column
#   status : the status of each pair (circ_pair_status())
#   node_a, node_b : lists of the node indices of the two reserves
#   r      : the resistance of each node; ix, iy: the cells of the nodes
#   oor    : the flag of the cells outside the training range (k1)
#   sub    : a logical per pair; the current of these pairs is summed apart
#   progress : 0 = no progress lines; k > 0 = one line after each k solved
#              pairs (the number of pairs and the minutes; no id, no name)
# Returns list(out, geoms (sfc LINESTRING in the analysis CRS), current,
# current_sub, hatched (the hatched nodes on the paths)).
circ_run_pairs <- function(info, id_col, status, node_a, node_b, links, memb,
                           r, ix, iy, oor, surface, phase, sub = NULL,
                           tol = SDMRES_CHECK_TOL_REL, progress = 0L) {
  n <- nrow(info)
  t0 <- Sys.time()
  n_solve <- sum(status == "path")
  n_done <- 0L
  n_nodes <- length(r)
  if (length(status) != n || length(node_a) != n || length(node_b) != n) {
    stop("circ_run_pairs(): one status and one node set per pair.",
         call. = FALSE)
  }
  if (is.null(sub)) sub <- rep(FALSE, n)
  lr <- circ_link_resistance(links, r)
  cur <- numeric(n_nodes)
  cur_sub <- numeric(n_nodes)
  hat <- integer(0)
  geoms <- vector("list", n)
  out <- data.frame(info, surface = surface, phase = phase, status = status,
                    reff = NA_real_, cost_rkm = NA_real_, path_km = NA_real_,
                    n_path_cells = NA_integer_, n_hatched_cells = NA_integer_,
                    redundancy = NA_real_, stringsAsFactors = FALSE)
  for (k in seq_len(n)) {
    if (status[k] %in% c("contiguous_02", "no_path")) {
      z <- if (status[k] == "contiguous_02") 0 else Inf
      out$reff[k] <- z
      out$cost_rkm[k] <- z
      out$path_km[k] <- if (z == 0) 0 else NA_real_
      out$n_path_cells[k] <- 0L
      out$n_hatched_cells[k] <- 0L
      geoms[[k]] <- sf::st_linestring()
      next
    }
    if (status[k] != "path") {
      stop("circ_run_pairs(): ", id_col, " ", info[[id_col]][k],
           " has the status ", status[k], ".", call. = FALSE)
    }
    a <- node_a[[k]]
    b <- node_b[[k]]
    keep <- which(memb == memb[a[1]])
    sol <- circ_solve_pair(n_nodes, links$from, links$to, 1 / lr, a, b, keep)
    p <- circ_lcp_pair(n_nodes, links$from, links$to, lr, a, b)
    pc <- circ_path_cost(ix[p$nodes], iy[p$nodes], r[p$nodes])
    ok <- c(
      "the current out of the first reserve is 1 A" =
        abs(sol$out_a - 1) <= tol,
      "the effective resistance is finite and above 0" =
        is.finite(sol$reff) && sol$reff > 0,
      "the path has 2 cells or more" =
        is.finite(p$cost) && length(p$nodes) >= 2L,
      "the path starts in the first reserve and ends in the second" =
        p$nodes[1] %in% a && p$nodes[length(p$nodes)] %in% b,
      "(iii) the path cost again from the cells" =
        isTRUE(pc$steps_ok) && abs(pc$cost - p$cost) <= tol * max(1, p$cost),
      "the path cost is not below the effective resistance" =
        p$cost >= sol$reff * (1 - tol))
    if (!all(ok)) {
      stop("circ_run_pairs(): ", id_col, " ", info[[id_col]][k], " on ",
           surface, ": ", paste(names(ok)[!ok], collapse = "; "),
           call. = FALSE)
    }
    cur <- cur + sol$current
    if (sub[k]) cur_sub <- cur_sub + sol$current
    hat <- union(hat, p$nodes[oor[p$nodes]])
    ln <- circ_path_line(ix[p$nodes], iy[p$nodes])
    geoms[[k]] <- ln
    out$reff[k] <- sol$reff
    out$cost_rkm[k] <- p$cost
    out$path_km[k] <- as.numeric(sf::st_length(
      sf::st_sfc(ln, crs = CRS_ANALYSIS))) / 1000
    out$n_path_cells[k] <- length(p$nodes)
    out$n_hatched_cells[k] <- sum(oor[p$nodes])
    out$redundancy[k] <- p$cost / sol$reff
    n_done <- n_done + 1L
    if (progress > 0L && (n_done %% progress == 0L || n_done == n_solve)) {
      cat(sprintf("  %s: %s of %s pairs solved (%.1f min)\n", surface,
                  format(n_done, big.mark = ","), format(n_solve, big.mark = ","),
                  as.numeric(difftime(Sys.time(), t0, units = "mins"))))
    }
  }
  list(out = out, geoms = sf::st_sfc(geoms, crs = CRS_ANALYSIS), current = cur,
       current_sub = cur_sub, hatched = hat)
}

# Point 8 on one surface (P2c; R6). The order: the effective resistance
# rounded to `digits` significant digits (NT1; 0 first, Inf last), then the
# lower from_unit_id, then the lower to_unit_id. n_low: the number of the
# pairs of Decision 17. Returns list(rank, in_lowest, lowest_of_from,
# lowest_of_to, share (of the pairs of Decision 17 among the n_low lowest),
# count (the reserves whose lowest partner is not a pair of Decision 17)).
circ_pair_rule <- function(reff, from, to, is_d17, n_low,
                           digits = SDMRES_RANK_SIGNIF) {
  n <- length(reff)
  if (anyNA(reff) || length(from) != n || length(to) != n ||
      length(is_d17) != n || any(from >= to) || n_low < 1L || n_low > n) {
    stop("circ_pair_rule(): one value per pair, from < to, 1 <= n_low <= n.",
         call. = FALSE)
  }
  o <- order(signif(reff, digits), from, to)
  rank <- integer(n)
  rank[o] <- seq_len(n)
  units <- sort(unique(c(from, to)))
  best <- vapply(units, function(u) {
    w <- which(from == u | to == u)
    w[which.min(rank[w])]
  }, integer(1))
  lof <- lot <- logical(n)
  for (j in seq_along(units)) {
    if (from[best[j]] == units[j]) lof[best[j]] <- TRUE else lot[best[j]] <- TRUE
  }
  list(rank = rank, in_lowest = rank <= n_low, lowest_of_from = lof,
       lowest_of_to = lot, share = sum(is_d17 & rank <= n_low) / n_low,
       count = sum(!is_d17[best]))
}

# tbl_19_sdmres_phase2_summary.csv (T2a): group, item, surface, value,
# reading. Counts and statistics only: no cell id, no position, no reserve
# name.
#   runs  : a named list (by surface) of the out tables of circ_run_pairs()
#   rules : a named list (by surface) of circ_pair_rule() results
#   curs, hats : named lists of the total currents and the hatched nodes
circ_phase2_summary <- function(runs, rules, curs, hats, n_res, n_low, n_rev,
                                min_share = SDMRES_PAIRRULE_MIN_SHARE,
                                labels = SDMRES_PAIRRULE_LABELS,
                                label_surface = "main") {
  rows <- list()
  add <- function(group, item, value, surface = "", reading = "") {
    rows[[length(rows) + 1L]] <<- data.frame(
      group = group, item = item, surface = surface, value = value,
      reading = reading, stringsAsFactors = FALSE)
  }
  d1 <- runs[[1]]
  add("pairs", "reserves", n_res, reading = "the reserves with a polygon")
  add("pairs", "phase2_pairs", nrow(d1), reading = "all pairs (from < to; R5)")
  add("pairs", "decision17_pairs", sum(d1$decision17),
      reading = "the pairs of tbl_12_reserve_pairs.csv")
  add("pairs", "decision17_other_direction", n_rev,
      reading = "pairs of Decision 17 whose from_unit_id is the higher id")
  add("pairs", "contiguous_02", sum(d1$status == "contiguous_02"),
      reading = "effective resistance 0 (Decision 27 point 3)")
  add("pairs", "no_path", sum(d1$status == "no_path"), reading = "Inf")
  add("pairs", "solved", sum(d1$status == "path"))
  q3 <- function(v) stats::quantile(v, c(0.25, 0.5, 0.75), names = FALSE)
  for (nm in names(runs)) {
    d <- runs[[nm]]
    ru <- rules[[nm]]
    s <- d$status == "path"
    add("pair_rule", "lowest_pairs", n_low, nm,
        "the number of the pairs of Decision 17")
    add("pair_rule", "decision17_in_lowest", sum(d$decision17 & ru$in_lowest), nm)
    add("pair_rule", "share", ru$share, nm,
        "pairs of Decision 17 among the lowest (Decision 27 point 8)")
    add("pair_rule", "reserves_lowest_partner_not_decision17", ru$count, nm,
        "of the reserves")
    if (identical(nm, label_surface)) {
      lab <- if (ru$share >= min_share) labels[1] else labels[2]
      add("pair_rule", "label_agrees", as.numeric(lab == labels[1]), nm, lab)
    }
    q <- q3(d$reff[s])
    add("reff", "reff_min", min(d$reff[s]), nm, "resistance-km; solved pairs")
    add("reff", "reff_q25", q[1], nm)
    add("reff", "reff_median", q[2], nm)
    add("reff", "reff_q75", q[3], nm)
    add("reff", "reff_max", max(d$reff[s]), nm)
    add("paths", "paths", sum(s), nm)
    add("paths", "path_km_min", min(d$path_km[s]), nm)
    add("paths", "path_km_median", stats::median(d$path_km[s]), nm)
    add("paths", "path_km_max", max(d$path_km[s]), nm)
    add("paths", "redundancy_median", stats::median(d$redundancy[s]), nm,
        "path cost / effective resistance")
    add("paths", "paths_with_hatched", sum(d$n_hatched_cells[s] > 0), nm,
        "k1 (Decision 27 point 1)")
    add("paths", "hatched_cells_on_paths", length(hats[[nm]]), nm, "k1")
    cu <- curs[[nm]]
    add("current", "cells_with_current", sum(cu > 0), nm,
        "the total current of phase 2 (1 A per pair)")
    add("current", "cells_without_current", sum(cu == 0), nm)
    add("current", "current_median", stats::median(cu), nm)
    add("current", "current_max", max(cu), nm)
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

# The hand-made case of STEP 17.5. Returns a data frame: check, pass.
circ_self_test_175 <- function() {
  res <- list()
  chk <- function(name, ok) res[[length(res) + 1L]] <<-
    data.frame(check = name, pass = isTRUE(ok), stringsAsFactors = FALSE)
  near <- function(a, b, tol = 1e-9) {
    length(a) == length(b) && all(abs(a - b) <= tol * pmax(1, abs(b)))
  }
  # 1. The pairs (R5): 4 reserves with ids 7, 3, 9, 5; Decision 17 has (7, 3)
  #    in the other direction and (5, 9).
  d17 <- data.frame(pair_id = c(11L, 12L), from_unit_id = c(7L, 5L),
                    to_unit_id = c(3L, 9L))
  p <- circ_phase2_pairs(c(7L, 3L, 9L, 5L), c("G", "C", "I", "E"), d17)
  chk("pairs: 6 pairs, from < to, in the order (3,5), (3,7), (3,9), (5,7), (5,9), (7,9)",
      nrow(p) == 6L && identical(p$from_unit_id, c(3L, 3L, 3L, 5L, 5L, 7L)) &&
        identical(p$to_unit_id, c(5L, 7L, 9L, 7L, 9L, 9L)) &&
        identical(p$from_name[2], "C") && identical(p$to_name[2], "G"))
  chk("pairs: the link to Decision 17 in either direction (R5)",
      identical(p$decision17, c(FALSE, TRUE, FALSE, FALSE, TRUE, FALSE)) &&
        identical(p$pair_id_decision17[c(2, 5)], c(11L, 12L)))
  # 2. Point 8 (R6): a 0, an exact tie broken by the ids, a near-tie that
  #    NT1 makes a tie.
  reff <- c(10, 0, 10 * (1 + 4e-16), 4, 10, 4)
  ru <- circ_pair_rule(reff, p$from_unit_id, p$to_unit_id, p$decision17, 2L,
                       digits = 12L)
  chk("pair rule: the ranks 4, 1, 5, 2, 6, 3 (0 first; the tie at 4 and the near-tie at 10 by the ids)",
      identical(ru$rank, c(4L, 1L, 5L, 2L, 6L, 3L)))
  ru15 <- circ_pair_rule(reff, p$from_unit_id, p$to_unit_id, p$decision17, 2L,
                         digits = 17L)
  chk("pair rule: with 17 digits the near-tie is not a tie (rank 6 for (3,9))",
      ru15$rank[3] == 6L)
  chk("pair rule: the share of the pairs of Decision 17 among the 2 lowest = 1/2",
      near(ru$share, 0.5) && identical(ru$in_lowest,
                                       c(FALSE, TRUE, FALSE, TRUE, FALSE, FALSE)))
  chk("pair rule: the lowest partner of 3 and 7 is (3,7); of 5 is (5,7); of 9 is (7,9); count = 2",
      ru$count == 2L &&
        identical(ru$lowest_of_from, c(FALSE, TRUE, FALSE, TRUE, FALSE, FALSE)) &&
        identical(ru$lowest_of_to, c(FALSE, TRUE, FALSE, FALSE, FALSE, TRUE)))
  qr <- circ_qa_pair_rule(reff, p$from_unit_id, p$to_unit_id, p$decision17, 2L,
                          digits = 12L)
  chk("pair rule: the QA count gives the same ranks, share and count",
      identical(qr$rank, ru$rank) && near(qr$share, ru$share) &&
        qr$count == ru$count)
  # 3. The run of the pairs on a row of 5 made-up cells: A = {1}, B = {5},
  #    C = {2, 3}, D = {3, 4}. (A, B) in series; (A, C) one link; (C, D)
  #    contiguous at 0.2 degrees.
  ix <- 400L:404L; iy <- rep(100L, 5)
  r <- c(1, 3, 5, 7, 9)
  L <- circ_links(ix, iy, 0.2)
  lr <- circ_link_resistance(L, r)
  memb <- circ_components(5L, L)
  ids <- sdm_cell_id(ix, iy)
  cells <- list(A = ids[1], B = ids[5], C = ids[2:3], D = ids[3:4])
  info <- data.frame(p2_id = 1:3, from = c("A", "A", "C"), to = c("B", "C", "D"),
                     stringsAsFactors = FALSE)
  st <- circ_pair_status(cells[info$from], cells[info$to], ids, memb)
  na <- lapply(cells[info$from], function(v) match(v, ids))
  nb <- lapply(cells[info$to], function(v) match(v, ids))
  rp <- circ_run_pairs(info, "p2_id", st, na, nb, L, memb, r, ix, iy,
                       rep(FALSE, 5), "test", "phase2", sub = c(TRUE, FALSE, FALSE))
  chk("run: (A, B) in series, (A, C) one link, (C, D) contiguous at 0.2 degrees (0)",
      identical(st, c("path", "path", "contiguous_02")) &&
        near(rp$out$reff, c(sum(lr), lr[1], 0)) &&
        near(rp$out$cost_rkm, c(sum(lr), lr[1], 0)))
  chk("run: the total current 0, 1, 1, 1, 0 (only (A, B) has nodes between); the sum of the pairs in sub the same",
      near(rp$current, c(0, 1, 1, 1, 0)) && near(rp$current_sub, c(0, 1, 1, 1, 0)))
  do.call(rbind, res)
}

# Point 8 again for the QA (Q2a): the rank of a pair = 1 + the number of the
# pairs before it (a lower rounded value, or the same value and a lower
# from_unit_id, or the same value and from_unit_id and a lower to_unit_id).
circ_qa_pair_rule <- function(reff, from, to, is_d17, n_low,
                              digits = SDMRES_RANK_SIGNIF) {
  k <- signif(reff, digits)
  n <- length(k)
  rank <- vapply(seq_len(n), function(i) {
    1L + sum(k < k[i] | (k == k[i] & (from < from[i] |
                                        (from == from[i] & to < to[i]))))
  }, integer(1))
  units <- sort(unique(c(from, to)))
  low_d17 <- vapply(units, function(u) {
    w <- which(from == u | to == u)
    is_d17[w[rank[w] == min(rank[w])]]
  }, logical(1))
  list(rank = as.integer(rank), share = sum(is_d17 & rank <= n_low) / n_low,
       count = sum(!low_d17))
}
