# =============================================================================
# 00_functions_pinch.R
# Road pinch points for Stage 2, Week 12 (Decision 20, docs/methodology.md).
# Sourced by scripts/07_connectivity.R; never run standalone.
#
# Method (Decision 20):
#   - Road cell: a footprint cell that a barrier road touches. The barrier
#     roads are the Decision-15 classes (a `_link` ramp is in its parent
#     class), rasterised with touches = TRUE and masked to the footprint. This
#     is the rule of scripts/07 STEP 9.6, so the cells are the cells that the
#     path engine saw. The cells come from geometry: the same on every surface.
#   - road_class_top: the highest class that touches the cell. The raster
#     holds its rank in the class order (1 = the highest class). The class is
#     a description. It is not a traffic volume and it is in no rule.
#   - Links with lit_flag: a config list of reserve pairs (unit_id + names).
#     No link is dropped.
#   - Cell list of a path: the path cells in order, and, for each knight
#     step, the two middle cells that the step crosses (the crossed-cells rule
#     of the engine, Decision 17 point 3).
#   - Crossing: one unbroken run of barrier-road cells in the cell list of a
#     path. Every road cell counts, also a cell in a reserve footprint; the
#     reserves are listed. Position: the middle cell of the run (for an even
#     run, the cell nearer the start).
#   - Published position (point 7): the cell of the coarse grid
#     (PINCH_PUBLISH_GRID_M) that holds the middle cell, with state and
#     district. The 1 km cells go only into a gitignored layer.
#   - Site (point 4): crossings at most PINCH_SITE_MERGE_KM apart (cell
#     centres; one link or different links) are joined; a site is a connected
#     set of joined crossings. Site position: the mean of its distinct cell
#     centres.
#   - Pinch point (point 5): on_bridge = a bridge edge uses the site; shared
#     = PINCH_SHARED_MIN_EDGES or more edges use it; pinch_point = on_bridge
#     OR shared; pinch_tier 1 = both, 2 = on_bridge only, 3 = shared only.
#     Only `edge` links count. The road class is not in the rule. This is not
#     the pinch point of circuit-theory mapping: a least-cost path has no
#     width.
#   - Variants (point 6): the same chain on noghm, road15 and road50, each
#     with its own paths, edges and bridges. site_overlap = min(share of the
#     baseline pinch points with a variant pinch point within
#     PINCH_COMPARE_D_KM, share of the variant pinch points with a baseline
#     pinch point within it); "robust" if site_overlap >=
#     PINCH_COMPARE_ROBUST_MIN_OVERLAP.
#
# Functions (task 12.8):
#   pinch_node_points()       node_id -> x, y: the centroid of its reserves
#   pinch_figure_classes()    the mark classes of fig_03: label, draw order
#   pinch_figure_marks()      one row per mark (node, cut-node ring, pinch
#                             point); pinch points from a publishable table
#   pinch_selftest_figure()   hand-made case for the two figure tables
#
# Functions (task 12.7):
#   pinch_node_summary()      one row per node: edges, crossings, sites and
#                             pinch points on its edges, by tier
#   pinch_table_note()        the lines of the note file of tbl_03 and
#                             tbl_03b (added 2026-10-10, author choice)
#
# Functions (task 12.6):
#   pinch_check_surface()     the QA list of Decision 20 for one surface
#
# Functions (task 12.5):
#   pinch_run_surface()       crossings, sites and rule for one surface
#   pinch_sites_near()        which sites of A have a site of B within d km
#   pinch_compare_variant()   one variant against the baseline -> one row
#   pinch_selftest_compare()  hand-made case for the comparison
#
# Functions (task 12.4):
#   pinch_build_sites()       crossings -> site_id (joined at <= merge_km)
#   pinch_min_site_gap_km()   shortest distance between two sites (a check)
#   pinch_apply_rule()        n_edges, n_bridges -> the two flags and the tier
#   pinch_site_table()        one row per site, with the rule applied
#   pinch_link_summary()      one row per link: crossings, sites, pinch points
#   pinch_check_publish_table() guard: no position finer than the publish grid
#   pinch_selftest_sites()    hand-made case for the functions above
#   pinch_admin_lookup_xy()   point -> state or district name
#
# Functions (task 12.3):
#   pinch_path_cell_list()    path cells -> cell list (with the middle cells
#                             of the knight steps)
#   pinch_cell_list_cost()    Decision-17 cost from a cell list (a check on
#                             the function above, against the engine)
#   pinch_runs()              unbroken runs of TRUE
#   pinch_crossings()         the crossings of the paths of one surface
#   pinch_grid_cell()         cell -> cell of the coarse publish grid
#   pinch_grid_cell_xy()      point -> cell of the coarse publish grid
#   pinch_admin_lookup()      cell -> state or district name
#   pinch_write_layer()       write one layer of the crossings file, read back
#   pinch_selftest()          hand-made case for the functions above
#
# Functions (task 12.2):
#   pinch_road_layer_name()   the layer name that records the class order
#   pinch_road_class_raster() barrier roads -> class-rank raster on the grid
#   pinch_road_cell_counts()  road cells per class
#   pinch_check_road_cells()  guard: grid, class order, values, footprint,
#                             cell count against the Week-9 QA -> table
#   pinch_lit_flag_pairs()    config list -> pair_ids, with the names guard
#
# Base R + terra + sf. No value is hardcoded: the calling script passes the
# PINCH_* settings from R/00_config.R.
# =============================================================================

# ---- Layer name ---------------------------------------------------------------
# The class order is written into the layer name of the raster, so a file on
# disk shows the order it was built with. Example:
#   rank_motorway_trunk_primary_secondary  (1 = motorway ... 4 = secondary)
pinch_road_layer_name <- function(class_order) {
  paste0("rank_", paste(class_order, collapse = "_"))
}

# ---- Barrier roads -> class-rank raster ---------------------------------------
# roads       : sf lines with the class in `class_field`. The caller has
#               already put each `_link` ramp into its parent class and kept
#               only the barrier classes.
# tmpl        : 1-layer SpatRaster on the surface grid; its non-NA cells are
#               the footprint (the baseline resistance surface).
# class_order : class names, highest first (PINCH_ROAD_CLASS_ORDER).
# touches     : PINCH_ROAD_TOUCHES (= ROAD_BARRIER_TOUCHES).
# One rasterise call per class, with the arguments of STEP 9.6 (field = 1,
# background = 0, touches). A cell that a road touches is touched in the
# call of that road's class, so the cells of all classes together are the
# cells of the one STEP-9.6 call on all barrier roads. The classes are
# written from the lowest to the highest, so the highest class stays.
# Returns a SpatRaster: 1..length(class_order) on a road cell of the
# footprint, NA on every other cell.
pinch_road_class_raster <- function(roads, tmpl, class_field, class_order,
                                    touches) {
  stopifnot(inherits(tmpl, "SpatRaster"), terra::nlyr(tmpl) == 1L)
  if (!class_field %in% names(roads)) {
    stop("pinch_road_class_raster: the road layer has no field '",
         class_field, "'.", call. = FALSE)
  }
  if (anyDuplicated(class_order) || length(class_order) == 0L) {
    stop("pinch_road_class_raster: class_order must hold each class once.",
         call. = FALSE)
  }
  cls <- as.character(roads[[class_field]])
  if (!all(cls %in% class_order)) {
    stop("pinch_road_class_raster: road class(es) not in class_order: ",
         paste(sort(unique(cls[!cls %in% class_order])), collapse = ", "),
         call. = FALSE)
  }
  if (sf::st_crs(roads) != sf::st_crs(terra::crs(tmpl))) {
    stop("pinch_road_class_raster: the roads and the grid do not have the ",
         "same CRS.", call. = FALSE)
  }
  rank_r <- terra::rast(tmpl)                         # same grid, no values
  rank_r <- terra::init(rank_r, NA_integer_)
  for (k in rev(seq_along(class_order))) {
    rk <- roads[cls == class_order[k], ]
    if (nrow(rk) == 0L) next                          # no road of this class
    hit <- terra::rasterize(terra::vect(rk), tmpl, field = 1, background = 0,
                            touches = touches)
    rank_r <- terra::ifel(hit == 1, k, rank_r)
  }
  rank_r <- terra::mask(rank_r, tmpl)                 # footprint only
  names(rank_r) <- pinch_road_layer_name(class_order)
  rank_r
}

# ---- Road cells per class -----------------------------------------------------
# Returns one row per class of class_order: road_class, class_rank, n_cells
# (0 if the class has no cell).
pinch_road_cell_counts <- function(road_r, class_order) {
  v   <- terra::values(road_r, mat = FALSE)
  tab <- table(factor(v, levels = seq_along(class_order)))
  data.frame(road_class = class_order, class_rank = seq_along(class_order),
             n_cells = as.integer(tab), stringsAsFactors = FALSE)
}

# ---- Guard: the road cells against the grid and the Week-9 QA ------------------
# road_r      : the class-rank raster (just built, or read from disk)
# tmpl        : the baseline resistance surface (grid and footprint)
# class_order : PINCH_ROAD_CLASS_ORDER
# n_expected  : n_road_cells of each surface in tbl_11_resistance_qa.csv
#               (one value per surface; they must all be the same)
# Returns a table: check, value, pass. The calling script stops on any FALSE.
pinch_check_road_cells <- function(road_r, tmpl, class_order, n_expected) {
  chk <- function(check, value, pass) {
    data.frame(check = check, value = as.character(value), pass = isTRUE(pass),
               stringsAsFactors = FALSE)
  }
  same_grid <- terra::nlyr(road_r) == 1L &&
    isTRUE(terra::compareGeom(road_r, tmpl, stopOnError = FALSE, crs = TRUE,
                              ext = TRUE, rowcol = TRUE, res = TRUE))
  out <- chk("the road raster is on the surface grid",
             paste(dim(road_r)[1:2], collapse = " x "), same_grid)
  out <- rbind(out, chk("the layer name records the class order of the config",
                        names(road_r)[1],
                        identical(names(road_r)[1],
                                  pinch_road_layer_name(class_order))))
  if (!same_grid) return(out)        # the cell checks need the same grid

  v    <- terra::values(road_r, mat = FALSE)
  foot <- !is.na(terra::values(tmpl, mat = FALSE))
  road <- !is.na(v)
  n_road <- sum(road)
  n_exp  <- unique(as.numeric(n_expected))
  rbind(
    out,
    chk("values are whole class ranks, 1 to the number of classes",
        if (n_road > 0) paste(range(v[road]), collapse = " to ") else "no cell",
        n_road > 0 && all(v[road] == round(v[road])) &&
          all(v[road] >= 1 & v[road] <= length(class_order))),
    chk("no road cell outside the footprint", sum(road & !foot),
        !any(road & !foot)),
    chk("the Week-9 QA gives one road-cell count for all surfaces",
        paste(format(n_exp, big.mark = ","), collapse = "; "),
        length(n_exp) == 1L && !is.na(n_exp)),
    chk("road cells = n_road_cells of tbl_11_resistance_qa.csv",
        sprintf("%s here, %s in the Week-9 QA", format(n_road, big.mark = ","),
                paste(format(n_exp, big.mark = ","), collapse = "; ")),
        length(n_exp) == 1L && !is.na(n_exp) && n_road == n_exp)
  )
}

# ---- Links with lit_flag (Decision 20 point 2, k1) -----------------------------
# flag_list : PINCH_LIT_FLAG_PAIRS — a list; each entry has unit_ids (2) and
#             names (2), in the same order
# pairs     : the pair table (pair_id, from/to unit_id and name)
# Stops if a unit_id does not have the stated name, or if an entry is not a
# pair of the table. Returns one row per entry: pair_id, the two unit_ids and
# names as in the pair table.
pinch_lit_flag_pairs <- function(flag_list, pairs) {
  need <- c("pair_id", "from_unit_id", "from_name", "to_unit_id", "to_name")
  if (!all(need %in% names(pairs))) {
    stop("pinch_lit_flag_pairs: the pair table needs ",
         paste(need, collapse = ", "), ".", call. = FALSE)
  }
  name_of <- function(id) {
    k <- match(id, c(pairs$from_unit_id, pairs$to_unit_id))
    c(pairs$from_name, pairs$to_name)[k]
  }
  rows <- lapply(seq_along(flag_list), function(i) {
    e <- flag_list[[i]]
    if (!is.list(e) || length(e$unit_ids) != 2L || length(e$names) != 2L ||
        anyNA(e$unit_ids) || e$unit_ids[1] == e$unit_ids[2]) {
      stop("pinch_lit_flag_pairs: entry ", i, " must have two different ",
           "unit_ids and two names.", call. = FALSE)
    }
    got <- name_of(e$unit_ids)
    if (anyNA(got) || !identical(as.character(got), as.character(e$names))) {
      stop("pinch_lit_flag_pairs: entry ", i, " — unit_id ",
           paste(e$unit_ids, collapse = ", "), " gives '",
           paste(got, collapse = "', '"), "', not '",
           paste(e$names, collapse = "', '"), "'.", call. = FALSE)
    }
    k <- which(pairs$from_unit_id == min(e$unit_ids) &
                 pairs$to_unit_id == max(e$unit_ids))
    if (length(k) != 1L) {
      stop("pinch_lit_flag_pairs: entry ", i, " (", paste(e$names, collapse =
           " - "), ") is not a pair of the pair table.", call. = FALSE)
    }
    pairs[k, need]
  })
  out <- do.call(rbind, rows)
  if (anyDuplicated(out$pair_id)) {
    stop("pinch_lit_flag_pairs: a pair is in the list two times.",
         call. = FALSE)
  }
  rownames(out) <- NULL
  out
}

# ---- Cell list of a path (Decision 20 point 3) ---------------------------------
# cells : the path cells in order (the line vertices; cell numbers of the grid)
# nc    : number of columns of the grid
# The cell list = the path cells in order, and, for each knight step, the two
# middle cells that the step crosses, put between its two end cells in the
# order in which the straight line meets them. This is the crossed-cells rule
# of the engine (Decision 17 point 3; the same cells as lcp_build_graph() and
# lcp_path_cost() in R/00_functions_lcp.R). Orthogonal and diagonal steps add
# no cell.
#   knight step of 2 columns (dr = +-1, dc = +-2): (row, col + s), then
#                                                  (row + dr, col + s)
#   knight step of 2 rows    (dr = +-2, dc = +-1): (row + s, col), then
#                                                  (row + s, col + dc)
#   s = the sign of the 2-cell direction; (row, col) = the start cell.
# Stops on a step that is not one of the 16 neighbour steps.
# Returns a data frame in list order: cell, is_vertex, vertex_no (NA for a
# middle cell), step (the step that the cell starts or is in; the last
# vertex has the number of the last step).
pinch_path_cell_list <- function(cells, nc) {
  cells <- as.integer(cells)
  n <- length(cells)
  if (n == 0L || anyNA(cells)) {
    stop("pinch_path_cell_list: the path has no cells, or an NA cell.",
         call. = FALSE)
  }
  if (n == 1L) {
    return(data.frame(cell = cells, is_vertex = TRUE, vertex_no = 1L,
                      step = 1L))
  }
  rw <- (cells - 1L) %/% nc + 1L
  cl <- (cells - 1L) %%  nc + 1L
  i  <- seq_len(n - 1L)
  dr <- rw[i + 1L] - rw[i]
  dc <- cl[i + 1L] - cl[i]
  adr <- abs(dr); adc <- abs(dc)
  kn  <- (adr == 1L & adc == 2L) | (adr == 2L & adc == 1L)
  ok  <- kn | (adr + adc == 1L) | (adr == 1L & adc == 1L)
  if (!all(ok)) {
    stop("pinch_path_cell_list: step ", which(!ok)[1], " (cell ",
         cells[which(!ok)[1]], " to ", cells[which(!ok)[1] + 1L],
         ") is not one of the 16 neighbour steps.", call. = FALSE)
  }
  r0 <- rw[i]; c0 <- cl[i]
  two_col <- kn & adc == 2L
  m1 <- ifelse(two_col, (r0 - 1L) * nc + (c0 + sign(dc)),
                        (r0 + sign(dr) - 1L) * nc + c0)
  m2 <- ifelse(two_col, (r0 + dr - 1L) * nc + (c0 + sign(dc)),
                        (r0 + sign(dr) - 1L) * nc + (c0 + dc))
  n_extra <- ifelse(kn, 2L, 0L)
  pos_v   <- c(1L, 1L + cumsum(1L + n_extra))      # list position of each vertex
  n_out   <- n + sum(n_extra)
  out   <- integer(n_out)
  is_v  <- logical(n_out)
  v_no  <- rep(NA_integer_, n_out)
  step  <- integer(n_out)
  out[pos_v]  <- cells
  is_v[pos_v] <- TRUE
  v_no[pos_v] <- seq_len(n)
  step[pos_v] <- c(i, n - 1L)
  k <- which(kn)
  if (length(k) > 0L) {
    out[pos_v[k] + 1L]  <- as.integer(m1[k])
    out[pos_v[k] + 2L]  <- as.integer(m2[k])
    step[pos_v[k] + 1L] <- k
    step[pos_v[k] + 2L] <- k
  }
  data.frame(cell = out, is_vertex = is_v, vertex_no = v_no, step = step)
}

# ---- Cost of a path from its cell list ------------------------------------------
# A check on pinch_path_cell_list(): the Decision-17 step cost, computed from
# the cell list (step length x the mean value of the cells of the step: 2
# cells for an orthogonal or diagonal step, 4 for a knight step). It must be
# the cost that the engine gave the path. A wrong middle cell changes it.
# cell_list : from pinch_path_cell_list()
# vals      : the values of the resistance surface, by cell number
# nc, res_km: columns of the grid; cell size in km
pinch_cell_list_cost <- function(cell_list, vals, nc, res_km) {
  vi <- which(cell_list$is_vertex)
  if (length(vi) < 2L) return(0)
  vc <- cell_list$cell[vi]
  rw <- (vc - 1L) %/% nc + 1L
  cl <- (vc - 1L) %%  nc + 1L
  len <- sqrt(diff(rw)^2 + diff(cl)^2) * res_km
  x   <- vals[cell_list$cell]
  cs  <- cumsum(x)
  a <- vi[-length(vi)]; b <- vi[-1L]
  sum(len * (cs[b] - cs[a] + x[a]) / (b - a + 1L))
}

# ---- Runs of TRUE ----------------------------------------------------------------
# x: logical vector (no NA). Returns one row per unbroken run of TRUE: start,
# end (positions in x).
pinch_runs <- function(x) {
  if (anyNA(x)) stop("pinch_runs: NA in the input.", call. = FALSE)
  r <- rle(as.logical(x))
  e <- cumsum(r$lengths)
  s <- e - r$lengths + 1L
  data.frame(start = s[r$values], end = e[r$values])
}

# ---- Crossings of the paths of one surface (Decision 20 points 2-3) ------------
# paths         : one row per pair, with pair_id, path_status, cost_rkm and
#                 the list column `cells` (the output of lcp_paths_for_pairs()
#                 for the surface; an sf object or a data frame)
# links         : the link table of the surface (net_build_links()), with
#                 pair_id and link_role
# link_roles    : PINCH_PATH_LINK_ROLES — the links that get crossings
# road_rank_v   : class rank by cell number (NA = not a barrier-road cell)
# class_order   : PINCH_ROAD_CLASS_ORDER
# vals          : the values of the surface, by cell number (cost check)
# nc, res_km    : columns of the grid; cell size in km
# reserve_cells : list of footprint-cell vectors, one per reserve
# unit_id       : the unit_id of each element of reserve_cells
# surface       : the surface name (a column of the output)
# A crossing = one unbroken run of barrier-road cells in the cell list of a
# path. Every road cell counts, also a cell in a reserve footprint
# (in_reserve_unit_ids lists the reserves). Position of a crossing: the
# middle cell of the run (for an even run, the cell nearer the start).
# Returns a list:
#   crossings  one row per crossing: crossing_id (<pair_id>-<run number>),
#              pair_id, surface, run_no, n_cells, class_rank_top,
#              road_class_top, mid_cell, in_reserve_unit_ids, and the list
#              column `cells`
#   cells      one row per crossing cell: crossing_id, pair_id, surface, seq,
#              cell, class_rank, road_class, is_vertex, reserve_unit_ids
#   paths      one row per path: pair_id, link_role, n_vertices,
#              n_knight_steps, n_list_cells, n_road_cells, n_crossings,
#              cost_rkm, cost_from_list, cost_ok
pinch_crossings <- function(paths, links, link_roles, road_rank_v, class_order,
                            vals, nc, res_km, reserve_cells, unit_id, surface,
                            cost_tol_rel = 1e-9) {
  if (!all(c("pair_id", "path_status", "cost_rkm", "cells") %in% names(paths))) {
    stop("pinch_crossings: the paths need pair_id, path_status, cost_rkm and ",
         "the list column `cells`.", call. = FALSE)
  }
  if (length(reserve_cells) != length(unit_id)) {
    stop("pinch_crossings: reserve_cells and unit_id do not have the same ",
         "length.", call. = FALSE)
  }
  sel <- links[links$link_role %in% link_roles, c("pair_id", "link_role")]
  sel <- sel[order(sel$pair_id), , drop = FALSE]
  k   <- match(sel$pair_id, paths$pair_id)
  if (anyNA(k) || any(paths$path_status[k] != "path")) {
    stop("pinch_crossings: a link has no path on surface '", surface,
         "' (pair_id ",
         paste(sel$pair_id[is.na(k) | paths$path_status[k] != "path"],
               collapse = ", "), ").", call. = FALSE)
  }
  own_cell <- unlist(reserve_cells, use.names = FALSE)
  own_uid  <- rep(as.integer(unit_id), lengths(reserve_cells))

  cr <- list(); ce <- list(); pa <- list()
  for (j in seq_len(nrow(sel))) {
    pid <- sel$pair_id[j]
    cl  <- pinch_path_cell_list(paths$cells[[k[j]]], nc)
    cost_list <- pinch_cell_list_cost(cl, vals, nc, res_km)
    cost_path <- paths$cost_rkm[k[j]]
    rank_j <- road_rank_v[cl$cell]
    runs   <- pinch_runs(!is.na(rank_j))
    pa[[j]] <- data.frame(
      pair_id = pid, link_role = sel$link_role[j],
      n_vertices = sum(cl$is_vertex),
      n_knight_steps = (nrow(cl) - sum(cl$is_vertex)) / 2L,
      n_list_cells = nrow(cl), n_road_cells = sum(!is.na(rank_j)),
      n_crossings = nrow(runs), cost_rkm = cost_path,
      cost_from_list = cost_list,
      cost_ok = abs(cost_list - cost_path) <= cost_tol_rel * max(1, cost_path),
      stringsAsFactors = FALSE)
    if (nrow(runs) == 0L) next
    in_own <- own_cell %in% cl$cell              # reserve cells on this path
    oc <- own_cell[in_own]; ou <- own_uid[in_own]
    res_of <- function(cc) {
      vapply(cc, function(x) paste(sort(unique(ou[oc == x])), collapse = ";"),
             character(1))
    }
    ids <- sprintf("%d-%d", pid, seq_len(nrow(runs)))
    idx <- lapply(seq_len(nrow(runs)),
                  function(q) seq.int(runs$start[q], runs$end[q]))
    n_c <- lengths(idx)
    mid <- runs$start + (n_c - 1L) %/% 2L
    top <- vapply(idx, function(q) min(rank_j[q]), numeric(1))
    cr[[j]] <- data.frame(
      crossing_id = ids, pair_id = pid, surface = surface,
      run_no = seq_len(nrow(runs)), n_cells = n_c,
      class_rank_top = as.integer(top),
      road_class_top = class_order[as.integer(top)],
      mid_cell = cl$cell[mid],
      in_reserve_unit_ids = vapply(idx, function(q) {
        paste(sort(unique(ou[oc %in% cl$cell[q]])), collapse = ";")
      }, character(1)),
      stringsAsFactors = FALSE)
    cr[[j]]$cells <- lapply(idx, function(q) cl$cell[q])
    all_q <- unlist(idx, use.names = FALSE)
    ce[[j]] <- data.frame(
      crossing_id = rep(ids, n_c), pair_id = pid, surface = surface,
      seq = sequence(n_c), cell = cl$cell[all_q],
      class_rank = as.integer(rank_j[all_q]),
      road_class = class_order[as.integer(rank_j[all_q])],
      is_vertex = cl$is_vertex[all_q],
      reserve_unit_ids = unname(res_of(cl$cell[all_q])),
      stringsAsFactors = FALSE)
  }
  bind <- function(x) {
    x <- x[!vapply(x, is.null, logical(1))]
    if (length(x) == 0L) return(NULL)
    out <- do.call(rbind, x); rownames(out) <- NULL; out
  }
  list(crossings = bind(cr), cells = bind(ce), paths = bind(pa))
}

# ---- Published position: the cell of the coarse grid (Decision 20 point 7) -----
# cells  : cell numbers of the analysis grid r
# grid_m : PINCH_PUBLISH_GRID_M — a whole multiple of the cell size of r
# The coarse grid is the analysis grid aggregated from its top-left corner
# (the grid of terra::aggregate(r, fact)). Returns a data frame: grid_id (the
# cell number of the coarse grid), grid_x_km, grid_y_km (the centre of the
# coarse cell, in the CRS of r, in km).
pinch_grid_cell <- function(cells, r, grid_m) {
  fact <- grid_m / terra::xres(r)
  if (abs(fact - round(fact)) > 1e-9 || fact < 1 ||
      abs(terra::xres(r) - terra::yres(r)) > 1e-6 * terra::xres(r)) {
    stop("pinch_grid_cell: grid_m must be a whole multiple of the (square) ",
         "cell size.", call. = FALSE)
  }
  xy <- terra::xyFromCell(r, cells)
  pinch_grid_cell_xy(xy[, 1], xy[, 2], r, grid_m)
}

# The same for points (x, y in the CRS of r): the cell of the coarse grid
# that holds the point. A point exactly on a line of the coarse grid goes to
# the cell to the east or to the south of the line.
pinch_grid_cell_xy <- function(x, y, r, grid_m) {
  fact <- grid_m / terra::xres(r)
  if (abs(fact - round(fact)) > 1e-9 || fact < 1) {
    stop("pinch_grid_cell_xy: grid_m must be a whole multiple of the cell ",
         "size.", call. = FALSE)
  }
  nc10 <- as.integer(ceiling(terra::ncol(r) / round(fact)))
  nr10 <- as.integer(ceiling(terra::nrow(r) / round(fact)))
  cl10 <- floor((x - terra::xmin(r)) / grid_m)
  rw10 <- floor((terra::ymax(r) - y) / grid_m)
  if (anyNA(cl10) || anyNA(rw10) || any(cl10 < 0 | cl10 >= nc10) ||
      any(rw10 < 0 | rw10 >= nr10)) {
    stop("pinch_grid_cell_xy: a point is outside the grid.", call. = FALSE)
  }
  data.frame(grid_id   = as.integer(rw10 * nc10 + cl10 + 1L),
             grid_x_km = (terra::xmin(r) + (cl10 + 0.5) * grid_m) / 1000,
             grid_y_km = (terra::ymax(r) - (rw10 + 0.5) * grid_m) / 1000)
}

# ---- State or district of a cell ---------------------------------------------------
# cells : cell numbers of r;  polys : sf polygons in the CRS of r;
# field : the name field of polys.
# The polygon that holds the cell centre (the first, if the centre is on a
# border). A centre in no polygon (a coast or border cell: the layers do not
# have the same outline) takes the nearest polygon; `nearest` marks it.
# Returns a data frame in the order of `cells`: value, nearest.
pinch_admin_lookup <- function(cells, r, polys, field) {
  if (!field %in% names(polys)) {
    stop("pinch_admin_lookup: the layer has no field '", field, "'.",
         call. = FALSE)
  }
  if (sf::st_crs(polys) != sf::st_crs(terra::crs(r))) {
    stop("pinch_admin_lookup: the layer and the grid do not have the same ",
         "CRS.", call. = FALSE)
  }
  u   <- unique(cells)
  out <- pinch_admin_lookup_xy(terra::xyFromCell(r, u), polys, field)
  out <- out[match(cells, u), , drop = FALSE]
  rownames(out) <- NULL
  out
}

# The same for points. xy: a 2-column matrix (x, y) in the CRS of polys (the
# caller makes sure of the CRS). Returns: value, nearest, in the order of xy.
pinch_admin_lookup_xy <- function(xy, polys, field) {
  if (!field %in% names(polys)) {
    stop("pinch_admin_lookup_xy: the layer has no field '", field, "'.",
         call. = FALSE)
  }
  pts <- sf::st_as_sf(data.frame(x = xy[, 1], y = xy[, 2]),
                      coords = c("x", "y"), crs = sf::st_crs(polys))
  hit <- sf::st_intersects(pts, polys)
  idx <- vapply(hit, function(h) if (length(h) > 0L) h[1] else NA_integer_,
                integer(1))
  far <- is.na(idx)
  if (any(far)) idx[far] <- sf::st_nearest_feature(pts[far, ], polys)
  data.frame(value = as.character(polys[[field]])[idx], nearest = far,
             stringsAsFactors = FALSE)
}

# ---- Write one layer of the crossings file, then read it back -------------------
# x: sf. Replaces only `layer` in the GeoPackage at `path`. Read-back: the
# same rows and the same attributes (logical fields compared as integer).
# Any difference stops the script. This file holds 1 km positions: it stays
# under data/ (gitignored) and is not a published layer.
pinch_write_layer <- function(x, path, layer) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  sf::st_write(x, path, layer = layer, delete_layer = TRUE, quiet = TRUE)
  y <- sf::st_read(path, layer = layer, quiet = TRUE)
  norm <- function(d) {
    d <- as.data.frame(sf::st_drop_geometry(d))
    d[] <- lapply(d, function(v) if (is.logical(v)) as.integer(v) else v)
    rownames(d) <- NULL
    d
  }
  same <- nrow(y) == nrow(x) &&
    isTRUE(all.equal(norm(x), norm(y)[, names(norm(x)), drop = FALSE],
                     check.attributes = FALSE))
  if (!same) {
    stop("pinch_write_layer(): read-back of layer '", layer, "' in ", path,
         " differs from the data that were written.", call. = FALSE)
  }
  message("Wrote layer '", layer, "' to ", path, " (", nrow(x),
          " features; read back and checked)")
  invisible(path)
}

# ---- Self-test on a hand-made case (Decision 20, QA) -----------------------------
# A 7 x 7 grid (cell = (row - 1) x 7 + col). One path with each step type:
#   vertices 22 (4,1) -> 23 (4,2)  orthogonal
#            23 (4,2) -> 18 (3,4)  knight, 2 columns: middle cells 24, 17
#            18 (3,4) -> 26 (4,5)  diagonal
#            26 (4,5) -> 41 (6,6)  knight, 2 rows: middle cells 33, 34
#            41 (6,6) -> 42 (6,7)  orthogonal
#   cell list: 22 23 24 17 18 26 33 34 41 42
# Roads (class rank): column 3 = rank 2 (cells 3 10 17 24 31 38 45); cell 26
# = rank 4; cell 33 = rank 1; cell 42 = rank 3.
#   crossing 1: cells 24 17 — both are middle cells of the first knight step,
#               so a rule that looks only at the path vertices finds nothing
#               here. Highest class rank 2. Middle cell 24.
#   crossing 2: cells 26 33 — highest class rank 1. Middle cell 26.
#   crossing 3: cell 42 (the last cell). Rank 3.
# Values 1 on each cell, 30 on a road cell: cost by hand =
#   1 x (1+1)/2 + sqrt(5) x (1+30+30+1)/4 + sqrt(2) x (1+30)/2
#   + sqrt(5) x (30+30+1+1)/4 + 1 x (1+30)/2
# Reserve: cells 24 and 25 = unit 7; cell 42 = units 8 and 9.
# The path in the other direction must give the same cells in the other order.
# Coarse grid: a grid of 20 rows x 30 columns of 1 km cells, 10 km grid (2
# rows x 3 columns) — cell 1 (row 1, col 1) -> 1; cell 20 (row 1, col 20)
# -> 2; cell 271 (row 10, col 1) -> 1; cell 301 (row 11, col 1) -> 4; cell
# 600 (row 20, col 30) -> 6.
# Returns: case, expected, engine, pass.
pinch_selftest <- function(tol = 1e-9) {
  nc <- 7L
  v  <- c(22L, 23L, 18L, 26L, 41L, 42L)
  cl <- pinch_path_cell_list(v, nc)
  cl_rev <- pinch_path_cell_list(rev(v), nc)
  rank <- rep(NA_integer_, 49L)
  rank[c(3L, 10L, 17L, 24L, 31L, 38L, 45L)] <- 2L
  rank[26L] <- 4L; rank[33L] <- 1L; rank[42L] <- 3L
  vals <- ifelse(is.na(rank), 1, 30)
  paths <- data.frame(pair_id = 5L, path_status = "path", cost_rkm = NA_real_,
                      stringsAsFactors = FALSE)
  paths$cells <- list(v)
  cost_hand <- 1 * (1 + 1) / 2 + sqrt(5) * (1 + 30 + 30 + 1) / 4 +
    sqrt(2) * (1 + 30) / 2 + sqrt(5) * (30 + 30 + 1 + 1) / 4 + 1 * (1 + 30) / 2
  paths$cost_rkm <- cost_hand
  links <- data.frame(pair_id = 5L, link_role = "edge",
                      stringsAsFactors = FALSE)
  x <- pinch_crossings(paths, links, "edge", rank,
                       c("c1", "c2", "c3", "c4"), vals, nc, 1,
                       reserve_cells = list(c(24L, 25L), 42L, 42L),
                       unit_id = c(7L, 8L, 9L), surface = "test")
  bad_step <- tryCatch({ pinch_path_cell_list(c(22L, 25L), nc); FALSE },
                       error = function(e) TRUE)
  g <- pinch_grid_cell(c(1L, 20L, 271L, 301L, 600L),
                       terra::rast(nrows = 20, ncols = 30, xmin = 0,
                                   xmax = 30000, ymin = 0, ymax = 20000,
                                   crs = "EPSG:7755"), 10000)
  show <- function(z) paste(z, collapse = " ")
  chk <- function(case, expected, engine) {
    data.frame(case = case, expected = show(expected), engine = show(engine),
               pass = identical(show(expected), show(engine)),
               stringsAsFactors = FALSE)
  }
  rbind(
    chk("cell list", c(22, 23, 24, 17, 18, 26, 33, 34, 41, 42), cl$cell),
    chk("cell list: vertices", c(TRUE, TRUE, FALSE, FALSE, TRUE, TRUE, FALSE,
                                 FALSE, TRUE, TRUE), cl$is_vertex),
    chk("cell list, other direction", rev(c(22, 23, 24, 17, 18, 26, 33, 34,
                                            41, 42)), cl_rev$cell),
    chk("a step that is not a neighbour step stops", TRUE, bad_step),
    chk("cost from the cell list = cost by hand", TRUE,
        abs(pinch_cell_list_cost(cl, vals, nc, 1) - cost_hand) <= tol),
    chk("number of crossings", 3, nrow(x$crossings)),
    chk("crossing ids", c("5-1", "5-2", "5-3"), x$crossings$crossing_id),
    chk("cells per crossing", c(2, 2, 1), x$crossings$n_cells),
    chk("crossing cells", c(24, 17, 26, 33, 42), x$cells$cell),
    chk("highest class rank", c(2, 1, 3), x$crossings$class_rank_top),
    chk("highest class name", c("c2", "c1", "c3"), x$crossings$road_class_top),
    chk("middle cell", c(24, 26, 42), x$crossings$mid_cell),
    chk("reserves per crossing", c("7", "", "8;9"),
        x$crossings$in_reserve_unit_ids),
    chk("crossing cells that are path vertices",
        c(FALSE, FALSE, TRUE, FALSE, TRUE), x$cells$is_vertex),
    chk("road cells on the path", 5, x$paths$n_road_cells),
    chk("cost check of the path", TRUE, x$paths$cost_ok),
    chk("coarse grid cell", c(1, 2, 1, 4, 6), g$grid_id),
    chk("coarse grid centre x (km)", c(5, 15, 5, 5, 25), g$grid_x_km),
    chk("coarse grid centre y (km)", c(15, 15, 15, 5, 5), g$grid_y_km)
  )
}

# ---- Sites (Decision 20 point 4) ---------------------------------------------------
# crossings : one row per crossing, with the list column `cells`
# nc, res_km: columns of the grid; cell size in km
# merge_km  : PINCH_SITE_MERGE_KM
# Two crossings are joined if the shortest distance between a cell centre of
# one and a cell centre of the other is <= merge_km. They can be on one link
# or on different links. A site is a connected set of joined crossings, so a
# line of crossings can make one long site (span_km shows it). The distance
# is computed from the row and column numbers (whole cells), so a distance of
# exactly merge_km joins.
# Returns site_id for each crossing: 1 to n, in the order of the lowest cell
# number of each site.
pinch_build_sites <- function(crossings, nc, res_km, merge_km, chunk = 2000L) {
  n <- nrow(crossings)
  if (n == 0L) return(integer(0))
  cr_i <- rep(seq_len(n), lengths(crossings$cells))
  cell <- unlist(crossings$cells, use.names = FALSE)
  if (length(cell) == 0L || anyNA(cell) || any(lengths(crossings$cells) == 0L)) {
    stop("pinch_build_sites: a crossing has no cell.", call. = FALSE)
  }
  rw <- (cell - 1L) %/% nc
  cl <- (cell - 1L) %%  nc
  thr2 <- (merge_km / res_km)^2 + 1e-9
  N  <- length(cell)
  ea <- list(); eb <- list()
  for (s in seq.int(1L, N, by = chunk)) {
    ii <- s:min(N, s + chunk - 1L)
    d2 <- outer(rw[ii], rw, "-")^2 + outer(cl[ii], cl, "-")^2
    w  <- which(d2 <= thr2, arr.ind = TRUE)
    a  <- cr_i[ii[w[, 1]]]; b <- cr_i[w[, 2]]
    k  <- a < b
    ea[[length(ea) + 1L]] <- a[k]; eb[[length(eb) + 1L]] <- b[k]
  }
  e <- unique(cbind(unlist(ea), unlist(eb)))
  g <- igraph::make_graph(edges = as.integer(t(e)), n = n, directed = FALSE)
  memb <- as.integer(igraph::components(g)$membership)
  low  <- tapply(cell, memb[cr_i], min)          # lowest cell of each set
  match(memb, as.integer(names(low)[order(low)]))
}

# Shortest distance (km) between two cells of DIFFERENT sites. A check on
# pinch_build_sites(): it must be above merge_km. Inf if there is one site.
pinch_min_site_gap_km <- function(crossings, site_id, nc, res_km,
                                  chunk = 2000L) {
  sid  <- rep(site_id, lengths(crossings$cells))
  cell <- unlist(crossings$cells, use.names = FALSE)
  u    <- !duplicated(cbind(sid, cell))
  sid  <- sid[u]; cell <- cell[u]
  rw <- (cell - 1L) %/% nc; cl <- (cell - 1L) %% nc
  best <- Inf
  for (s in seq.int(1L, length(cell), by = chunk)) {
    ii <- s:min(length(cell), s + chunk - 1L)
    d2 <- outer(rw[ii], rw, "-")^2 + outer(cl[ii], cl, "-")^2
    d2[outer(sid[ii], sid, "==")] <- Inf
    best <- min(best, d2)
  }
  sqrt(best) * res_km
}

# ---- The pinch-point rule (Decision 20 point 5) -------------------------------------
# n_edges, n_bridges : per site
# shared_min_edges   : PINCH_SHARED_MIN_EDGES
# on_bridge = a bridge edge uses the site; shared = shared_min_edges or more
# edges use it; pinch_point = on_bridge OR shared; pinch_tier 1 = both flags,
# 2 = on_bridge only, 3 = shared only, NA = not a pinch point. The road
# class, the cost and the number of crossings are not in the rule.
pinch_apply_rule <- function(n_edges, n_bridges, shared_min_edges) {
  on_bridge <- n_bridges >= 1L
  shared    <- n_edges >= shared_min_edges
  data.frame(on_bridge = on_bridge, shared = shared,
             pinch_point = on_bridge | shared,
             pinch_tier = ifelse(on_bridge & shared, 1L,
                          ifelse(on_bridge, 2L, ifelse(shared, 3L, NA_integer_))))
}

# ---- Site table (Decision 20 points 4-5) ----------------------------------------------
# crossings : one row per crossing, with site_id, pair_id, link_role,
#             is_bridge, lit_flag, class_rank_top, in_reserve_unit_ids,
#             from_name, to_name and the list column `cells`
# r         : the analysis grid
# rule_link_roles : PINCH_RULE_LINK_ROLES — the links that the rule counts
# Returns one row per site, in site_id order. n_links = different pair_ids;
# n_edges = different pair_ids with a link role of the rule; n_bridges = of
# those, with is_bridge TRUE. lit_flag = the site has an edge and each of its
# edges has the flag; lit_flag_any = one or more of its edges has it. span_km
# = the longest distance between two of its cell centres. mean_x, mean_y =
# the mean of its distinct cell centres (the site position; NOT for a
# published table — see pinch_grid_cell()).
pinch_site_table <- function(crossings, r, class_order, rule_link_roles,
                             shared_min_edges, surface) {
  need <- c("site_id", "pair_id", "link_role", "is_bridge", "lit_flag",
            "class_rank_top", "in_reserve_unit_ids", "from_name", "to_name",
            "cells")
  if (!all(need %in% names(crossings))) {
    stop("pinch_site_table: field(s) missing from the crossings: ",
         paste(setdiff(need, names(crossings)), collapse = ", "), call. = FALSE)
  }
  join <- function(x) paste(x, collapse = ";")
  rows <- lapply(sort(unique(crossings$site_id)), function(s) {
    x  <- crossings[crossings$site_id == s, , drop = FALSE]
    cc <- unique(unlist(x$cells, use.names = FALSE))
    xy <- terra::xyFromCell(r, cc)
    is_e <- x$link_role %in% rule_link_roles
    pid   <- sort(unique(x$pair_id))
    e_pid <- sort(unique(x$pair_id[is_e]))
    b_pid <- sort(unique(x$pair_id[is_e & x$is_bridge %in% TRUE]))
    lit_e <- sort(unique(x$pair_id[is_e & x$lit_flag %in% TRUE]))
    uid <- unlist(strsplit(x$in_reserve_unit_ids, ";", fixed = TRUE))
    uid <- sort(unique(as.integer(uid[nzchar(uid)])))
    nm  <- unique(data.frame(p = x$pair_id, n = paste(x$from_name, "-",
                                                      x$to_name)))
    nm  <- nm[order(nm$p), ]
    data.frame(
      site_id = s, surface = surface,
      n_crossings = nrow(x), n_links = length(pid), n_edges = length(e_pid),
      n_bridges = length(b_pid), n_cells = length(cc),
      span_km = if (length(cc) > 1L) max(stats::dist(xy)) / 1000 else 0,
      class_rank_top = min(x$class_rank_top),
      road_class_top = class_order[min(x$class_rank_top)],
      in_reserve_unit_ids = join(uid),
      lit_flag = length(e_pid) > 0L && length(lit_e) == length(e_pid),
      lit_flag_any = length(lit_e) > 0L,
      pair_ids = join(pid), edge_pair_ids = join(e_pid),
      bridge_pair_ids = join(b_pid), links = paste(nm$n, collapse = "; "),
      mean_x = mean(xy[, 1]), mean_y = mean(xy[, 2]),
      stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  out <- cbind(out, pinch_apply_rule(out$n_edges, out$n_bridges,
                                     shared_min_edges))
  rownames(out) <- NULL
  out
}

# ---- Summary per link ---------------------------------------------------------------------
# crossings : one row per crossing with pair_id and site_id
# sites     : from pinch_site_table() (site_id, pinch_point, pinch_tier)
# path_tbl  : the `paths` table of pinch_crossings() (one row per link)
# Returns one row per link of path_tbl: the crossings, the road cells, the
# sites that the path of the link uses, and how many of them are pinch
# points, by tier. A site counts for each link that uses it.
pinch_link_summary <- function(crossings, sites, path_tbl) {
  k   <- match(crossings$site_id, sites$site_id)
  u   <- unique(data.frame(pair_id = crossings$pair_id,
                           site_id = crossings$site_id,
                           tier = sites$pinch_tier[k]))
  cnt <- function(sel) {
    as.integer(table(factor(u$pair_id[sel], levels = path_tbl$pair_id)))
  }
  data.frame(pair_id = path_tbl$pair_id,
             n_crossings = path_tbl$n_crossings,
             n_road_cells = path_tbl$n_road_cells,
             n_sites = cnt(rep(TRUE, nrow(u))),
             n_pinch_points = cnt(!is.na(u$tier)),
             n_pinch_tier1 = cnt(u$tier %in% 1L),
             n_pinch_tier2 = cnt(u$tier %in% 2L),
             n_pinch_tier3 = cnt(u$tier %in% 3L))
}

# ---- Guard: no position finer than the publish grid in a table ---------------------------
# x      : a table that is committed (outputs/tables)
# r      : the analysis grid;  grid_m : PINCH_PUBLISH_GRID_M
# prefix : the prefix of the grid columns (for example "grid10")
# The table must not hold a 1 km cell number or a coordinate that is not a
# centre of the coarse grid, and <prefix>_id must be the cell of the coarse
# grid at <prefix>_x_km, <prefix>_y_km (Decision 20 point 7;
# sensitive-data policy §3). Returns a table: check, value, pass.
pinch_check_publish_table <- function(x, r, grid_m, prefix) {
  chk <- function(check, value, pass) {
    data.frame(check = check, value = as.character(value), pass = isTRUE(pass),
               stringsAsFactors = FALSE)
  }
  banned <- c("cell", "cells", "mid_cell", "mean_cell", "exit_cell",
              "entry_cell", "x", "y", "mean_x", "mean_y", "lon", "lat",
              "longitude", "latitude", "geom", "geometry")
  gc <- paste0(prefix, c("_id", "_x_km", "_y_km"))
  out <- chk("no column with a 1 km cell or a point coordinate",
             paste(intersect(names(x), banned), collapse = ", "),
             !any(names(x) %in% banned))
  out <- rbind(out, chk("the publish-grid columns are in the table",
                        paste(intersect(names(x), gc), collapse = ", "),
                        all(gc %in% names(x))))
  if (!all(gc %in% names(x))) return(out)
  fact <- as.integer(round(grid_m / terra::xres(r)))
  nc10 <- as.integer(ceiling(terra::ncol(r) / fact))
  cx10 <- (x[[gc[2]]] * 1000 - terra::xmin(r)) / grid_m - 0.5
  cy10 <- (terra::ymax(r) - x[[gc[3]]] * 1000) / grid_m - 0.5
  on_grid <- !anyNA(cx10) && !anyNA(cy10) &&
    all(abs(cx10 - round(cx10)) < 1e-6) && all(abs(cy10 - round(cy10)) < 1e-6)
  rbind(out,
        chk("each position is a centre of the publish grid",
            sprintf("%d rows, grid %g m", nrow(x), grid_m), on_grid),
        chk("the grid id is the cell of the publish grid at that centre",
            length(unique(x[[gc[1]]])),
            on_grid && all(x[[gc[1]]] == round(cy10) * nc10 + round(cx10) + 1)))
}

# ---- Self-test of the sites and the rule (Decision 20, QA) -----------------------------
# A grid of 100 x 100 cells of 1 km (cell = (row - 1) x 100 + col), merge
# distance 5 km, shared = 2 edges. Crossings (one cell each):
#   A pair 1 edge, bridge, lit (10,10)   B pair 2 edge (10,15)     A-B 5 km: joined
#   C pair 3 edge (10,21)                D pair 3 edge (13,25)     B-C 6 km: not joined;
#                                                                   C-D 5 km (3, 4): joined
#   E pair 4 parallel (40,40)            F pair 5 edge (40,42)     joined; 1 edge only
#   G pair 6 edge (60,60)                H pair 7 edge (61,61)     joined; 2 edges
#   I pair 8 edge, bridge, lit (80,80)                             alone
#   J pair 9 edge (90,10)   K pair 9 edge (90,14)   L pair 10 edge (90,18)
#                                        J-K 4, K-L 4, J-L 8 km: one site by the chain
# Sites by lowest cell: 1 {A,B} both flags, tier 1; 2 {C,D} one edge, no pinch
# point; 3 {E,F} one edge (a parallel link does not count), no pinch point;
# 4 {G,H} shared, tier 3; 5 {I} on a bridge, tier 2; 6 {J,K,L} shared, tier 3,
# span 8 km. Mean positions (x, y in km; y = 100 - row + 0.5) and the cell of
# the 10 km grid (10 columns; id = row10 x 10 + col10 + 1):
#   site 1 (12, 90.5) -> 2      site 2 (22.5, 89) -> 13    site 3 (40.5, 60.5) -> 35
#   site 4 (60, 40): on a grid line in x and in y -> the cell to the east and
#   south, 67           site 5 (79.5, 20.5) -> 78     site 6 (13.5, 10.5) -> 82
# Shortest gap between two sites: B-C, 6 km.
# Returns: case, expected, engine, pass.
pinch_selftest_sites <- function() {
  r  <- terra::rast(nrows = 100, ncols = 100, xmin = 0, xmax = 1e5, ymin = 0,
                    ymax = 1e5, crs = "EPSG:7755")
  cl <- function(row, col) as.integer((row - 1L) * 100L + col)
  x <- data.frame(
    crossing_id = LETTERS[1:12],
    pair_id   = c(1L, 2L, 3L, 3L, 4L, 5L, 6L, 7L, 8L, 9L, 9L, 10L),
    link_role = c("edge", "edge", "edge", "edge", "parallel", "edge", "edge",
                  "edge", "edge", "edge", "edge", "edge"),
    is_bridge = c(TRUE, FALSE, FALSE, FALSE, NA, FALSE, FALSE, FALSE, TRUE,
                  FALSE, FALSE, FALSE),
    lit_flag  = c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE,
                  FALSE, FALSE, FALSE),
    class_rank_top = c(3L, 2L, 4L, 4L, 1L, 4L, 2L, 3L, 4L, 3L, 3L, 1L),
    in_reserve_unit_ids = c("7", "", "", "", "", "", "", "", "8;9", "", "", ""),
    from_name = paste0("F", c(1, 2, 3, 3, 4, 5, 6, 7, 8, 9, 9, 10)),
    to_name   = paste0("T", c(1, 2, 3, 3, 4, 5, 6, 7, 8, 9, 9, 10)),
    stringsAsFactors = FALSE)
  x$cells <- as.list(c(cl(10, 10), cl(10, 15), cl(10, 21), cl(13, 25),
                       cl(40, 40), cl(40, 42), cl(60, 60), cl(61, 61),
                       cl(80, 80), cl(90, 10), cl(90, 14), cl(90, 18)))
  o <- c(7L, 12L, 3L, 1L, 9L, 5L, 11L, 2L, 8L, 4L, 10L, 6L)   # mixed order in
  x <- x[o, ]
  x$site_id <- pinch_build_sites(x, 100L, 1, 5)
  s <- pinch_site_table(x, r, c("c1", "c2", "c3", "c4"), "edge", 2L, "test")
  g <- pinch_grid_cell_xy(s$mean_x, s$mean_y, r, 1e4)
  path_tbl <- data.frame(pair_id = 1:10, n_crossings = c(1, 1, 2, 1, 1, 1, 1,
                                                          1, 2, 1),
                         n_road_cells = c(1, 1, 2, 1, 1, 1, 1, 1, 2, 1))
  ls <- pinch_link_summary(x, s, path_tbl)
  show <- function(z) paste(ifelse(is.na(z), "NA", as.character(z)),
                            collapse = " ")
  chk <- function(case, expected, engine) {
    data.frame(case = case, expected = show(expected), engine = show(engine),
               pass = identical(show(expected), show(engine)),
               stringsAsFactors = FALSE)
  }
  rbind(
    chk("site of each crossing (A to L)",
        c(1, 1, 2, 2, 3, 3, 4, 4, 5, 6, 6, 6), x$site_id[order(o)]),
    chk("number of sites", 6, nrow(s)),
    chk("crossings per site", c(2, 2, 2, 2, 1, 3), s$n_crossings),
    chk("links per site", c(2, 1, 2, 2, 1, 2), s$n_links),
    chk("edges per site (a parallel link does not count)",
        c(2, 1, 1, 2, 1, 2), s$n_edges),
    chk("bridge edges per site", c(1, 0, 0, 0, 1, 0), s$n_bridges),
    chk("on_bridge", c(TRUE, FALSE, FALSE, FALSE, TRUE, FALSE), s$on_bridge),
    chk("shared", c(TRUE, FALSE, FALSE, TRUE, FALSE, TRUE), s$shared),
    chk("pinch_point", c(TRUE, FALSE, FALSE, TRUE, TRUE, TRUE), s$pinch_point),
    chk("pinch_tier", c(1, NA, NA, 3, 2, 3), s$pinch_tier),
    chk("span_km (site 6 is a chain of 8 km)", c(5, 5, 2, 1.414, 0, 8),
        round(s$span_km, 3)),
    chk("highest class per site", c("c2", "c4", "c1", "c2", "c4", "c1"),
        s$road_class_top),
    chk("lit_flag (each edge of the site has the flag)",
        c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE), s$lit_flag),
    chk("lit_flag_any", c(TRUE, FALSE, FALSE, FALSE, TRUE, FALSE),
        s$lit_flag_any),
    chk("reserves per site", c("7", "", "", "", "8;9", ""),
        s$in_reserve_unit_ids),
    chk("edge pair_ids per site", c("1;2", "3", "5", "6;7", "8", "9;10"),
        s$edge_pair_ids),
    chk("mean position of site 1 (km)", c(12, 90.5),
        c(s$mean_x[1], s$mean_y[1]) / 1000),
    chk("publish-grid cell of the sites", c(2, 13, 35, 67, 78, 82), g$grid_id),
    chk("shortest gap between two sites (km)", 6,
        pinch_min_site_gap_km(x, x$site_id, 100L, 1)),
    chk("link summary: sites per link (pairs 1 to 10)",
        c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1), ls$n_sites),
    chk("link summary: pinch points per link",
        c(1, 1, 0, 0, 0, 1, 1, 1, 1, 1), ls$n_pinch_points),
    chk("link summary: tier-3 pinch points per link",
        c(0, 0, 0, 0, 0, 1, 1, 0, 1, 1), ls$n_pinch_tier3)
  )
}

# ---- One surface: crossings, sites, rule (Decision 20 points 2-5) -----------------
# The whole chain for one surface, with the functions above. STEP 12.4 uses it
# for each variant; on the baseline it must give the result of STEPs 12.2 and
# 12.3 (the script checks this).
# paths        : the paths of the surface, with the list column `cells`
# links        : the link table of the surface (net_build_links())
# edge_flags   : net_edge_flags() of the graph of the surface (pair_id,
#                is_bridge)
# lit_pair_ids : the pair_ids with lit_flag
# r            : the resistance surface (grid; values for the cost check)
# Returns a list: crossings (with the link fields, site_id and `cells`),
# cells, paths, sites, link_summary, site_gap_km.
pinch_run_surface <- function(paths, links, edge_flags, lit_pair_ids,
                              link_roles, rule_link_roles, road_rank_v,
                              class_order, r, reserve_cells, unit_id, merge_km,
                              shared_min_edges, surface) {
  nc     <- terra::ncol(r)
  res_km <- terra::xres(r) / 1000
  x <- pinch_crossings(paths = paths, links = links, link_roles = link_roles,
                       road_rank_v = road_rank_v, class_order = class_order,
                       vals = terra::values(r, mat = FALSE), nc = nc,
                       res_km = res_km, reserve_cells = reserve_cells,
                       unit_id = unit_id, surface = surface)
  if (is.null(x$crossings)) {
    stop("pinch_run_surface: no road crossing on surface '", surface, "'.",
         call. = FALSE)
  }
  cx <- x$crossings
  k  <- match(cx$pair_id, links$pair_id)
  for (f in c("from_unit_id", "from_name", "to_unit_id", "to_name",
              "from_node_id", "to_node_id", "link_role")) {
    cx[[f]] <- links[[f]][k]
  }
  cx$is_bridge <- edge_flags$is_bridge[match(cx$pair_id, edge_flags$pair_id)]
  cx$lit_flag  <- cx$pair_id %in% lit_pair_ids
  cx$site_id   <- pinch_build_sites(cx, nc, res_km, merge_km)
  sites <- pinch_site_table(cx, r, class_order, rule_link_roles,
                            shared_min_edges, surface)
  x$cells$site_id <- cx$site_id[match(x$cells$crossing_id, cx$crossing_id)]
  list(crossings = cx, cells = x$cells, paths = x$paths, sites = sites,
       link_summary = pinch_link_summary(cx, sites, x$paths),
       site_gap_km = pinch_min_site_gap_km(cx, cx$site_id, nc, res_km))
}

# ---- Which sites of A are near a site of B? (Decision 20 point 6) -----------------
# a_cross, b_cross : crossings with site_id and the list column `cells`
# a_ids, b_ids     : the site_ids of A to test, and the site_ids of B that
#                    count
# Two sites are near if the shortest distance between a cell centre of one
# and a cell centre of the other is <= d_km (whole cells, as in
# pinch_build_sites()). Returns a logical vector in the order of a_ids.
pinch_sites_near <- function(a_cross, a_ids, b_cross, b_ids, nc, res_km, d_km,
                             chunk = 2000L) {
  if (length(a_ids) == 0L) return(logical(0))
  long <- function(x, ids) {
    s <- rep(x$site_id, lengths(x$cells))
    cc <- unlist(x$cells, use.names = FALSE)
    u <- s %in% ids & !duplicated(cbind(s, cc))
    data.frame(site = s[u], cell = cc[u])
  }
  a <- long(a_cross, a_ids)
  b <- unique(long(b_cross, b_ids)$cell)
  if (length(b) == 0L) return(rep(FALSE, length(a_ids)))
  ar <- (a$cell - 1L) %/% nc; ac <- (a$cell - 1L) %% nc
  br <- (b - 1L) %/% nc;      bc <- (b - 1L) %% nc
  thr2 <- (d_km / res_km)^2 + 1e-9
  hit  <- logical(nrow(a))
  for (s in seq.int(1L, nrow(a), by = chunk)) {
    ii <- s:min(nrow(a), s + chunk - 1L)
    d2 <- outer(ar[ii], br, "-")^2 + outer(ac[ii], bc, "-")^2
    hit[ii] <- apply(d2, 1L, min) <= thr2
  }
  near <- tapply(hit, a$site, any)
  out <- as.logical(near[as.character(a_ids)])
  out[is.na(out)] <- FALSE
  out
}

# ---- One variant against the baseline (Decision 20 point 6) -----------------------
# base, var : lists with `crossings` (site_id, cells) and `sites` (site_id,
#             pinch_point, pinch_tier, links) — the output of
#             pinch_run_surface()
# d_km      : PINCH_COMPARE_D_KM;  d_descr_km : PINCH_COMPARE_D_DESCR_KM
# min_overlap : PINCH_COMPARE_ROBUST_MIN_OVERLAP;  tol : so that 2 of 3
#             counts as >= 2/3
#   share_base    = baseline pinch points with a variant pinch point near them
#                   / baseline pinch points
#   share_variant = variant pinch points with a baseline pinch point near
#                   them / variant pinch points
#   site_overlap  = min(share_base, share_variant)
#   label         = "robust" if site_overlap >= min_overlap, else "sensitive";
#                   a surface with no pinch point gives NA and "sensitive".
# Descriptive (no limit): the same overlap at each distance of d_descr_km;
# the same overlap for all sites; the baseline tier-1 and tier-2 pinch points
# with no variant pinch point near them, by link (entries divided by " | ",
# because the link list of one site uses "; ").
# Returns a list: row (one-row data frame) and near_base (for each baseline
# site, in the order of base$sites: a variant pinch point is near).
pinch_compare_variant <- function(base, var, nc, res_km, d_km, d_descr_km,
                                  min_overlap, tol = 1e-9) {
  bs <- base$sites; vs <- var$sites
  b_pp <- bs$site_id[bs$pinch_point]
  v_pp <- vs$site_id[vs$pinch_point]
  ov <- function(a, a_ids, b, b_ids, d) {
    if (length(a_ids) == 0L || length(b_ids) == 0L) return(NA_real_)
    mean(pinch_sites_near(a, a_ids, b, b_ids, nc, res_km, d))
  }
  both <- function(a_ids, b_ids, d) {
    c(ov(base$crossings, a_ids, var$crossings, b_ids, d),
      ov(var$crossings, b_ids, base$crossings, a_ids, d))
  }
  main <- both(b_pp, v_pp, d_km)
  site_overlap <- if (anyNA(main)) NA_real_ else min(main)
  descr <- vapply(d_descr_km, function(d) {
    z <- both(b_pp, v_pp, d)
    if (anyNA(z)) NA_real_ else min(z)
  }, numeric(1))
  names(descr) <- paste0("site_overlap_", d_descr_km, "km")
  alls <- both(bs$site_id, vs$site_id, d_km)
  near_base <- pinch_sites_near(base$crossings, bs$site_id, var$crossings,
                                v_pp, nc, res_km, d_km)
  lost <- bs$pinch_tier %in% c(1L, 2L) & !near_base
  by_link <- if (any(lost)) {
    tb <- sort(table(bs$links[lost]), decreasing = TRUE)
    paste(sprintf("%s (%d)", names(tb), as.integer(tb)), collapse = " | ")
  } else ""
  robust <- !is.na(site_overlap) && site_overlap >= min_overlap - tol
  row <- data.frame(
    n_crossings = nrow(var$crossings), n_sites = nrow(vs),
    n_pinch_points = length(v_pp),
    n_pinch_tier1 = sum(vs$pinch_tier %in% 1L),
    n_pinch_tier2 = sum(vs$pinch_tier %in% 2L),
    n_pinch_tier3 = sum(vs$pinch_tier %in% 3L),
    n_pinch_points_baseline = length(b_pp),
    share_base = main[1], share_variant = main[2],
    site_overlap = site_overlap,
    as.data.frame(as.list(descr)),
    all_sites_share_base = alls[1], all_sites_share_variant = alls[2],
    all_sites_overlap = if (anyNA(alls)) NA_real_ else min(alls),
    n_base_tier12_not_near = sum(lost),
    base_tier12_not_near_by_link = by_link,
    label = if (robust) "robust" else "sensitive",
    stringsAsFactors = FALSE)
  list(row = row, near_base = near_base)
}

# ---- Self-test of the comparison (Decision 20, QA) ----------------------------------
# A grid of 100 x 100 cells of 1 km; each site has one cell (row, col).
# Baseline: pinch points P1 (10,10) tier 2, P2 (10,30) tier 1, P3 (50,50)
#           tier 3; site N1 (80,80), not a pinch point.
# Variant : pinch points Q1 (10,13), Q2 (14,33), Q3 (50,56), Q4 (90,90);
#           site M1 (80,81), not a pinch point.
# Distances: P1-Q1 3 km; P2-Q2 5 km (4, 3 — exactly the limit: near);
#            P3-Q3 6 km; N1-M1 1 km; Q4 is far from each baseline site.
# At 5 km : share_base 2/3 (P1, P2), share_variant 2/4 (Q1, Q2) -> overlap 0.5
#           -> "sensitive". Baseline tier 1-2 with no variant pinch point
#           near: 0 (P3 is tier 3).
# At 10 km: share_base 3/3, share_variant 3/4 -> 0.75.
# All sites at 5 km: baseline 3/4 (P1, P2, N1), variant 3/5 (Q1, Q2, M1)
#           -> 0.6.
# Case 2  : the variant has only Q1 and Q2 as pinch points -> share_base
#           2/3, share_variant 2/2 -> overlap 2/3 -> "robust" (the limit
#           counts).
# Case 3  : the variant has no pinch point -> overlap NA -> "sensitive".
# Returns: case, expected, engine, pass.
pinch_selftest_compare <- function() {
  cl <- function(row, col) as.integer((row - 1L) * 100L + col)
  mk <- function(cells, pinch, tier) {
    n <- length(cells)
    cr <- data.frame(site_id = seq_len(n))
    cr$cells <- as.list(cells)
    list(crossings = cr,
         sites = data.frame(site_id = seq_len(n), pinch_point = pinch,
                            pinch_tier = tier, links = paste0("L", seq_len(n)),
                            stringsAsFactors = FALSE))
  }
  base <- mk(c(cl(10, 10), cl(10, 30), cl(50, 50), cl(80, 80)),
             c(TRUE, TRUE, TRUE, FALSE), c(2L, 1L, 3L, NA))
  v_cells <- c(cl(10, 13), cl(14, 33), cl(50, 56), cl(90, 90), cl(80, 81))
  var1 <- mk(v_cells, c(TRUE, TRUE, TRUE, TRUE, FALSE), c(3L, 3L, 3L, 3L, NA))
  var2 <- mk(v_cells, c(TRUE, TRUE, FALSE, FALSE, FALSE), c(3L, 3L, NA, NA, NA))
  var3 <- mk(v_cells, rep(FALSE, 5), rep(NA_integer_, 5))
  run <- function(v) pinch_compare_variant(base, v, 100L, 1, 5, c(5, 10), 2 / 3)
  a <- run(var1); b <- run(var2); c3 <- run(var3)
  show <- function(z) paste(ifelse(is.na(z), "NA", as.character(z)),
                            collapse = " ")
  chk <- function(case, expected, engine) {
    data.frame(case = case, expected = show(expected), engine = show(engine),
               pass = identical(show(expected), show(engine)),
               stringsAsFactors = FALSE)
  }
  r4 <- function(z) round(z, 4)
  rbind(
    chk("share_base, share_variant, site_overlap (5 km)", c(0.6667, 0.5, 0.5),
        r4(c(a$row$share_base, a$row$share_variant, a$row$site_overlap))),
    chk("label below the limit", "sensitive", a$row$label),
    chk("site_overlap at 5 and 10 km", c(0.5, 0.75),
        c(a$row$site_overlap_5km, a$row$site_overlap_10km)),
    chk("all sites: share_base, share_variant, overlap", c(0.75, 0.6, 0.6),
        c(a$row$all_sites_share_base, a$row$all_sites_share_variant,
          a$row$all_sites_overlap)),
    chk("baseline sites with a variant pinch point near (P1, P2, P3, N1)",
        c(TRUE, TRUE, FALSE, FALSE), a$near_base),
    chk("baseline tier 1-2 pinch points with none near", 0,
        a$row$n_base_tier12_not_near),
    chk("variant counts: sites, pinch points", c(5, 4),
        c(a$row$n_sites, a$row$n_pinch_points)),
    chk("case 2: overlap exactly 2/3 is robust", c(0.6667, "robust"),
        c(r4(b$row$site_overlap), b$row$label)),
    chk("case 2: tier 1-2 with none near (P1, P2 are near)", c(0, ""),
        c(b$row$n_base_tier12_not_near, b$row$base_tier12_not_near_by_link)),
    chk("case 3: no variant pinch point", c(NA, "sensitive"),
        c(c3$row$site_overlap, c3$row$label)),
    chk("case 3: baseline tier 1-2 with none near, by link",
        c(2, "L1 (1) | L2 (1)"),
        c(c3$row$n_base_tier12_not_near, c3$row$base_tier12_not_near_by_link))
  )
}

# ---- QA of one surface (Decision 20, "Consequences": the QA list) -----------------
# ps    : the output of pinch_run_surface() for the surface
# paths : the paths of the surface, with the list column `cells`
# links : the link table of the surface (pair_id, link_role)
# flags : net_edge_flags() of the graph of the surface (pair_id, is_bridge)
# pairs : the pair table (pair_id, contiguous)
# The checks do not use the stored counts of pinch_crossings(): the cell list
# of each path is made again here, and the rule is written a second way.
# Returns a table: check, value, pass.
pinch_check_surface <- function(ps, paths, links, flags, pairs, road_rank_v, nc,
                                res_km, link_roles, rule_link_roles, merge_km,
                                shared_min_edges, lit_pair_ids) {
  chk <- function(check, value, pass) {
    data.frame(check = check, value = as.character(value), pass = isTRUE(pass),
               stringsAsFactors = FALSE)
  }
  cx <- ps$crossings; ce <- ps$cells; st <- ps$sites
  want <- sort(links$pair_id[links$link_role %in% link_roles])
  # the cell list of each path, made again
  in_list <- TRUE; road_once <- TRUE; n_road <- 0L
  for (pid in want) {
    cl <- pinch_path_cell_list(paths$cells[[match(pid, paths$pair_id)]], nc)
    is_road <- !is.na(road_rank_v[cl$cell])
    mine <- ce[ce$pair_id == pid, , drop = FALSE]
    n_road <- n_road + sum(is_road)
    in_list <- in_list && all(mine$cell %in% cl$cell) &&
      all(!is.na(road_rank_v[mine$cell]))
    # the road cells of the list, in order = the crossing cells, in order
    road_once <- road_once && identical(as.integer(cl$cell[is_road]),
                                        as.integer(mine$cell)) &&
      !anyDuplicated(paste(mine$crossing_id, mine$seq))
  }
  e_pid <- links$pair_id[links$link_role %in% rule_link_roles]
  b_pid <- flags$pair_id[flags$is_bridge %in% TRUE]
  # the rule, a second way: from the crossings, not from the site table
  ne <- vapply(st$site_id, function(s) {
    length(unique(cx$pair_id[cx$site_id == s & cx$pair_id %in% e_pid]))
  }, integer(1))
  nb <- vapply(st$site_id, function(s) {
    length(unique(cx$pair_id[cx$site_id == s & cx$pair_id %in% b_pid]))
  }, integer(1))
  tier2 <- ifelse(nb >= 1L & ne >= shared_min_edges, 1L,
           ifelse(nb >= 1L, 2L, ifelse(ne >= shared_min_edges, 3L, NA_integer_)))
  sc <- unique(data.frame(s = rep(cx$site_id, lengths(cx$cells)),
                          c = unlist(cx$cells, use.names = FALSE)))
  rbind(
    chk("each link in the roles has its crossings computed",
        sprintf("%d paths", length(want)),
        identical(sort(ps$paths$pair_id), want)),
    chk("cost from the cell list = cost of the path (every path)",
        sprintf("%d of %d", sum(ps$paths$cost_ok), nrow(ps$paths)),
        all(ps$paths$cost_ok)),
    chk("each crossing cell is in the cell list of its path and is a barrier-road cell",
        sprintf("%d cells", nrow(ce)), in_list),
    chk("each barrier-road cell of a cell list is in one crossing only",
        sprintf("%d road cells in the lists, %d crossing cells", n_road,
                nrow(ce)), road_once && n_road == nrow(ce)),
    chk("no crossing for a contiguous pair or a pair that is not in the network",
        sprintf("%d crossings on %d links", nrow(cx),
                length(unique(cx$pair_id))),
        all(cx$pair_id %in% want) &&
          !any(cx$pair_id %in% pairs$pair_id[as.logical(pairs$contiguous)])),
    chk("each crossing is in one site only",
        sprintf("%d crossings, %d sites", nrow(cx), nrow(st)),
        !anyNA(cx$site_id) && !anyDuplicated(cx$crossing_id) &&
          all(cx$site_id %in% st$site_id) &&
          sum(st$n_crossings) == nrow(cx)),
    chk("two sites are more than the merge distance apart",
        sprintf("shortest gap %.2f km, merge distance %g km", ps$site_gap_km,
                merge_km), ps$site_gap_km > merge_km),
    chk("the counts per link and per site add up to the totals",
        sprintf("%d crossings, %d site cells", sum(ps$link_summary$n_crossings),
                sum(st$n_cells)),
        sum(ps$link_summary$n_crossings) == nrow(cx) &&
          sum(ps$link_summary$n_road_cells) == nrow(ce) &&
          sum(st$n_cells) == nrow(sc) &&
          all(ps$link_summary$n_pinch_points ==
                ps$link_summary$n_pinch_tier1 + ps$link_summary$n_pinch_tier2 +
                ps$link_summary$n_pinch_tier3)),
    chk("n_edges and n_bridges from the crossings = the site table",
        sprintf("%d sites", nrow(st)),
        identical(as.integer(ne), as.integer(st$n_edges)) &&
          identical(as.integer(nb), as.integer(st$n_bridges))),
    chk("pinch_point = on_bridge OR shared; tiers (rule written a second way)",
        sprintf("%d pinch points: tier 1 %d, tier 2 %d, tier 3 %d",
                sum(st$pinch_point), sum(st$pinch_tier %in% 1L),
                sum(st$pinch_tier %in% 2L), sum(st$pinch_tier %in% 3L)),
        identical(as.integer(tier2), as.integer(st$pinch_tier)) &&
          identical(!is.na(tier2), as.logical(st$pinch_point))),
    chk("each site on a bridge edge is a pinch point",
        sprintf("%d bridge edges, %d sites on them", length(b_pid),
                sum(nb >= 1L)), all(st$pinch_point[nb >= 1L])),
    chk("lit_flag marks the crossings of the links of the config list",
        sprintf("%d crossings", sum(cx$lit_flag)),
        identical(as.logical(cx$lit_flag), cx$pair_id %in% lit_pair_ids))
  )
}

# ---- Summary per node (for the publishable reserve table) ---------------------------
# crossings : one row per crossing with pair_id and site_id
# sites     : the site table (site_id, pinch_tier)
# links     : the link table with pair_id, link_role, from_node_id,
#             to_node_id and is_bridge
# node_ids  : the nodes of the network
# rule_link_roles : PINCH_RULE_LINK_ROLES (the edges)
# For each node: its edges, its bridge edges, the crossings on its edges, and
# the sites that its edges use — all of them, and the pinch points by tier. A
# site that two edges of the node use counts one time for the node; a site
# on an edge counts for the two nodes of the edge.
pinch_node_summary <- function(crossings, sites, links, node_ids,
                               rule_link_roles) {
  e <- links[links$link_role %in% rule_link_roles, , drop = FALSE]
  tier_of <- sites$pinch_tier[match(crossings$site_id, sites$site_id)]
  rows <- lapply(sort(unique(node_ids)), function(n) {
    pid <- e$pair_id[e$from_node_id == n | e$to_node_id == n]
    k   <- crossings$pair_id %in% pid
    s   <- unique(data.frame(site = crossings$site_id[k], tier = tier_of[k]))
    data.frame(node_id = n, n_edges = length(pid),
               n_bridge_edges = sum(e$is_bridge[e$pair_id %in% pid] %in% TRUE),
               n_crossings = sum(k), n_sites = nrow(s),
               n_pinch_points = sum(!is.na(s$tier)),
               n_pinch_tier1 = sum(s$tier %in% 1L),
               n_pinch_tier2 = sum(s$tier %in% 2L),
               n_pinch_tier3 = sum(s$tier %in% 3L))
  })
  do.call(rbind, rows)
}

# ---- Note file for the publishable tables -----------------------------------------
# Decision 20 point 5: each table says what a pinch point is here. A CSV file
# has no place for a note, so STEP 12.6 writes a note file next to the two
# publishable tables (author choice 2026-10-10). Every value in the text is
# an argument: a config value or a count of the run. The note holds no
# position. The text is ASCII only.
#   n_reserves, n_nodes : rows and nodes of tbl_03
#   tiers               : pinch points of tbl_03b in tier 1, 2, 3
#   road_classes        : PINCH_ROAD_CLASS_ORDER
#   merge_km, shared_min, grid_m, compare_d_km, linchpin_top_n : config values
#   n_variants          : number of variant surfaces
#   choice_labels       : named character vector, for example
#                         c("gHM multiplier" = "sensitive")
# Returns the lines of the file.
pinch_table_note <- function(n_reserves, n_nodes, tiers, road_classes,
                             merge_km, shared_min, grid_m, compare_d_km,
                             n_variants, choice_labels, linchpin_top_n) {
  stopifnot(length(tiers) == 3L, length(choice_labels) >= 1L,
            !is.null(names(choice_labels)))
  c("# Notes for tbl_03_reserve_network.csv and tbl_03b_pinch_points.csv",
    "",
    paste0("Written by scripts/07_connectivity.R STEP 12.6. The script writes ",
           "this file again on each run: do not edit it by hand. The field ",
           "list is in docs/data-dictionary.md. The rules are in ",
           "docs/methodology.md, Decisions 19 and 20."),
    "",
    "## What a \"pinch point\" is in these tables",
    "",
    sprintf(paste0("- A place where a barrier road meets a modelled least-cost ",
                   "path between two tiger reserves, at a site that a bridge ",
                   "link uses or that %d or more links share."), shared_min),
    paste0("- It is NOT the pinch point of circuit-theory mapping (a narrow ",
           "part of a corridor with high current flow). A least-cost path has ",
           "no width."),
    sprintf(paste0("- Barrier road: an OpenStreetMap road of class %s. The ",
                   "road class is a description. It is not a traffic volume ",
                   "and it is not in the rule."),
            paste(road_classes, collapse = ", ")),
    sprintf(paste0("- Site: road crossings at most %g km apart are one site. ",
                   "One row of tbl_03b is one site."), merge_km),
    paste0("- Bridge link: a link of the reserve network without which its ",
           "set of joined nodes divides."),
    "",
    "## Tiers",
    "",
    "- Tier 1: the site is on a bridge link and it is shared.",
    "- Tier 2: the site is on a bridge link only.",
    sprintf("- Tier 3: %d or more links share the site; no bridge link uses it.",
            shared_min),
    "- The sites in one tier have no order between them.",
    "",
    "## Limits",
    "",
    paste0("- The paths and the road crossings are modelled. They are not ",
           "observed tiger movement, and they are not records of tigers on ",
           "roads."),
    paste0("- The resistance surface is India-only: a path cannot go through ",
           "a neighbour country."),
    sprintf(paste0("- Position: each pinch point is given as a %g km grid ",
                   "cell with its state and district, and not more precisely ",
                   "(docs/sensitive-data-policy.md, section 3). The districts ",
                   "are those of the 2011 census."), grid_m / 1000),
    sprintf(paste0("- Variant result for the pinch points (Decision 20 point ",
                   "6): %s. In tbl_03b, n_variants_near is the number of ",
                   "variant surfaces (0 to %d) that have a pinch point within ",
                   "%g km of the site."),
            paste(sprintf("%s %s", names(choice_labels), choice_labels),
                  collapse = "; "), n_variants, compare_d_km),
    sprintf(paste0("- Linchpin (tbl_03): a node with a betweenness rank from ",
                   "1 to %d in its set of joined nodes. The number %d is a ",
                   "judgement value: read the label with set_size."),
            linchpin_top_n, linchpin_top_n),
    paste0("- Node counts (tbl_03): the values are per node, and the reserves ",
           "of one node share them. A site on a link counts for the two nodes ",
           "of the link, so the node counts do not add up to the number of ",
           "pinch points. The count gives no order of nodes."),
    "",
    "## Counts of this run",
    "",
    sprintf("- tbl_03: %d reserves in %d nodes.", n_reserves, n_nodes),
    sprintf("- tbl_03b: %d pinch points (tier 1: %d, tier 2: %d, tier 3: %d).",
            sum(tiers), tiers[1], tiers[2], tiers[3]))
}

# =============================================================================
# Figure fig_03 (task 12.8; Decision 20 point 7, g1)
# =============================================================================
# The figure code is in scripts/07_connectivity.R (STEP 12.7). The functions
# here make the tables that the figure draws, so that the counts on the map
# can be checked before the file is written.

# ---- Node positions for the figure ---------------------------------------------
# res_sf   : the reserve polygons of the network (unit_id), in the analysis CRS
# node_tbl : unit_id and node_id (STEP 11.1)
# The position of a node is the centroid of the union of its reserve
# polygons. The reserve boundaries are public (NTCA); the position is not a
# species record and not a modelled path or crossing. For a node of two or
# more reserves, or a reserve of two or more parts, the centroid can be
# outside the polygons.
# Returns node_id, x, y (metres, analysis CRS), sorted by node_id.
pinch_node_points <- function(res_sf, node_tbl) {
  k <- match(res_sf$unit_id, node_tbl$unit_id)
  if (anyNA(k)) {
    stop("pinch_node_points(): reserve(s) with no node: unit_id ",
         paste(res_sf$unit_id[is.na(k)], collapse = ", "), call. = FALSE)
  }
  nid <- node_tbl$node_id[k]
  ids <- sort(unique(nid))
  xy <- t(vapply(ids, function(n) {
    g <- sf::st_union(sf::st_geometry(res_sf)[nid == n])
    as.numeric(sf::st_coordinates(sf::st_centroid(g))[1, 1:2])
  }, numeric(2)))
  data.frame(node_id = ids, x = xy[, 1], y = xy[, 2])
}

# ---- The mark classes of the figure --------------------------------------------
# One row per class of mark, in legend order. `draw` is the draw order (1 =
# first = below the others). The tier-1 pinch points are drawn last: they are
# few, and some are at a linchpin node at national scale.
#   n_surfaces : the number of surfaces of `stable_linchpin` (baseline +
#                variants; Decision 19 point 10)
#   shared_min : PINCH_SHARED_MIN_EDGES
# Linchpin classes: `stable_linchpin` (a linchpin on all surfaces) and
# `cross_group_dependent` (a linchpin only when the cross-group links are in
# the graph) give four classes. Only the classes that have a mark go into the
# legend.
pinch_figure_classes <- function(n_surfaces, shared_min) {
  data.frame(
    cls = c("lp_s", "lp_sx", "lp_n", "lp_nx", "oth", "pend", "cut",
            "t1", "t2", "t3"),
    label = c(
      "Linchpin node (number: see the list)",
      "Linchpin node, only with the\ncross-group links in the graph",
      sprintf("Linchpin node, not on all\n%d surfaces", n_surfaces),
      sprintf(paste0("Linchpin node, not on all %d surfaces;\nonly with the ",
                     "cross-group links"), n_surfaces),
      "Other node",
      "Pendant node (one link)",
      "Cut node (ring): without it,\nits set divides",
      "Pinch point, tier 1: on a bridge\nlink and shared",
      "Pinch point, tier 2: on a bridge link",
      sprintf("Pinch point, tier 3: shared by\n%d or more links", shared_min)),
    draw = c(9L, 8L, 7L, 6L, 3L, 4L, 5L, 10L, 2L, 1L),
    stringsAsFactors = FALSE)
}

# ---- The marks of the figure ---------------------------------------------------
# nodes  : one row per node: node_id, x, y, linchpin, stable_linchpin,
#          cross_group_dependent, cut_node, pendant, isolated
# sites  : a PUBLISHABLE pinch-point table (tbl_03b): site_id, pinch_tier and
#          the position at the publish grid, <prefix>_x_km and <prefix>_y_km.
#          No other position column is read, so a 1 km position cannot get
#          into the figure (sensitive-data policy §3). An sf object is
#          refused.
# prefix : the prefix of the grid columns ("grid10")
# Returns one row per mark: kind ("node", "cut", "pinch"), id, cls, x, y. A cut
# node has two rows: its node mark and the ring.
pinch_figure_marks <- function(nodes, sites, prefix) {
  need_n <- c("node_id", "x", "y", "linchpin", "stable_linchpin",
              "cross_group_dependent", "cut_node", "pendant", "isolated")
  if (!all(need_n %in% names(nodes))) {
    stop("pinch_figure_marks(): the node table has no column(s): ",
         paste(setdiff(need_n, names(nodes)), collapse = ", "), call. = FALSE)
  }
  if (anyDuplicated(nodes$node_id) || anyNA(nodes[, need_n])) {
    stop("pinch_figure_marks(): the node table has a duplicate node or an NA.",
         call. = FALSE)
  }
  if (any(nodes$isolated)) {
    stop("pinch_figure_marks(): the figure has no mark for an isolated node ",
         "(degree 0): ", paste(nodes$node_id[nodes$isolated], collapse = ", "),
         ". Add a class before the figure is made.", call. = FALSE)
  }
  gx <- paste0(prefix, c("_x_km", "_y_km"))
  if (inherits(sites, "sf") ||
      !all(c("site_id", "pinch_tier", gx) %in% names(sites))) {
    stop("pinch_figure_marks(): the site table must be a publishable table ",
         "(no geometry) with site_id, pinch_tier, ", gx[1], " and ", gx[2],
         ".", call. = FALSE)
  }
  if (anyNA(sites[, c("pinch_tier", gx)]) || !all(sites$pinch_tier %in% 1:3)) {
    stop("pinch_figure_marks(): each row of the site table must be a pinch ",
         "point (pinch_tier 1, 2 or 3) with a position.", call. = FALSE)
  }
  n_cls <- ifelse(nodes$linchpin,
                  paste0("lp_", ifelse(nodes$stable_linchpin, "s", "n"),
                         ifelse(nodes$cross_group_dependent, "x", "")),
                  ifelse(nodes$pendant, "pend", "oth"))
  cut <- nodes[nodes$cut_node, , drop = FALSE]
  rbind(
    data.frame(kind = "node", id = nodes$node_id, cls = n_cls, x = nodes$x,
               y = nodes$y, stringsAsFactors = FALSE),
    data.frame(kind = rep("cut", nrow(cut)), id = cut$node_id,
               cls = rep("cut", nrow(cut)), x = cut$x, y = cut$y,
               stringsAsFactors = FALSE),
    data.frame(kind = "pinch", id = sites$site_id,
               cls = paste0("t", sites$pinch_tier), x = sites[[gx[1]]] * 1000,
               y = sites[[gx[2]]] * 1000, stringsAsFactors = FALSE))
}

# ---- Self-test of the figure tables ----------------------------------------------
# A hand-made case: 6 nodes (one of each linchpin class, one cut node that is
# also a linchpin, one pendant, one other) and 4 pinch points. Returns a
# named logical vector; STEP 12.7 stops if a case fails.
pinch_selftest_figure <- function() {
  nodes <- data.frame(
    node_id = 1:6, x = (1:6) * 1000, y = (6:1) * 1000,
    linchpin              = c(TRUE,  TRUE,  TRUE,  TRUE,  FALSE, FALSE),
    stable_linchpin       = c(TRUE,  TRUE,  FALSE, FALSE, FALSE, FALSE),
    cross_group_dependent = c(FALSE, TRUE,  FALSE, TRUE,  FALSE, FALSE),
    cut_node              = c(TRUE,  FALSE, FALSE, FALSE, FALSE, TRUE),
    pendant               = c(FALSE, FALSE, FALSE, FALSE, TRUE,  FALSE),
    isolated              = FALSE)
  sites <- data.frame(site_id = c(7L, 3L, 9L, 4L), pinch_tier = c(1L, 2L, 3L, 3L),
                      grid10_x_km = c(5, 15, 25, 35),
                      grid10_y_km = c(95, 85, 75, 65), mean_x = 1:4)
  m <- pinch_figure_marks(nodes, sites, "grid10")
  cl <- pinch_figure_classes(4L, 2L)
  stops <- function(expr) inherits(try(expr, silent = TRUE), "try-error")
  iso <- nodes; iso$isolated[5] <- TRUE
  not_pp <- sites; not_pp$pinch_tier[2] <- NA
  c("marks: 6 nodes + 2 rings + 4 pinch points" =
      identical(as.vector(table(factor(m$kind, c("node", "cut", "pinch")))),
                c(6L, 2L, 4L)),
    "marks: node classes from the flags" =
      identical(m$cls[m$kind == "node"],
                c("lp_s", "lp_sx", "lp_n", "lp_nx", "pend", "oth")),
    "marks: the rings are at the cut nodes" =
      identical(m$id[m$kind == "cut"], c(1L, 6L)) &&
      identical(m$x[m$kind == "cut"], c(1000, 6000)),
    "marks: pinch-point class from the tier, position from the grid columns" =
      identical(m$cls[m$kind == "pinch"], c("t1", "t2", "t3", "t3")) &&
      identical(m$x[m$kind == "pinch"], c(5000, 15000, 25000, 35000)) &&
      identical(m$y[m$kind == "pinch"], c(95000, 85000, 75000, 65000)),
    "classes: each mark class has one row and one draw position" =
      all(m$cls %in% cl$cls) && !anyDuplicated(cl$cls) &&
      setequal(cl$draw, seq_len(nrow(cl))),
    "stop: an isolated node" = stops(pinch_figure_marks(iso, sites, "grid10")),
    "stop: a site that is not a pinch point" =
      stops(pinch_figure_marks(nodes, not_pp, "grid10")),
    "stop: a site table with no grid position" =
      stops(pinch_figure_marks(nodes, sites[, c("site_id", "pinch_tier",
                                                "mean_x")], "grid10")))
}
