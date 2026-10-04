# =============================================================================
# 00_functions_lcp.R
# Least-cost-path engine for Stage 2 (Decision 17, docs/methodology.md).
# Sourced by scripts/07_connectivity.R; never run standalone.
#
# Method (Decision 17, points 3, 4 and 6):
#   - Nodes are the non-NA cells of a resistance surface. NA cells are not nodes.
#   - 4, 8 or 16 neighbours. 16 = 4 orthogonal + 4 diagonal + 8 knight steps.
#   - Step cost = step length (km) x length-weighted mean resistance of the
#     cells that the straight line between the two cell centres crosses:
#       orthogonal / diagonal : the 2 end cells, 1/2 each
#       knight, "crossed_cells": the 4 crossed cells, 1/4 each; the step is
#                                not allowed if any of the 4 cells is NA
#       knight, "end_cells"    : the 2 end cells, 1/2 each, no middle check
#                                (the gdistance rule; validation only)
#   - Edge to edge: each reserve has a "super node" joined to all of its cells.
#     In a search, only the source reserve's joins have weight 0; every other
#     reserve's joins have weight Inf (never used). So movement inside the
#     source costs nothing, and the first target cell reached is the entry.
#   - Cost-distance unit: resistance-km.
#
# Functions:
#   lcp_neighbourhood()      half-neighbourhood offsets (each edge once)
#   lcp_reserve_cells()      footprint cells of each reserve polygon
#   lcp_build_graph()        igraph graph + weights + super nodes
#   lcp_search()             one source reserve -> its target reserves
#   lcp_path_line()          cells -> sf LINESTRING (empty if < 2 cells)
#   lcp_contiguous()         do two reserves share a footprint cell?
#   lcp_mem_report()         peak memory (Linux) or R heap only (Windows)
#   lcp_alloc_zones()        Euclidean allocation of footprint cells to the
#                            nearest reserve polygon (Decision 17 point 1)
#   lcp_zone_adjacency()     reserve pairs whose zones share a cell edge
#   lcp_build_pairs()        candidate pairs -> pair table (gap cap, contiguous,
#                            network groups)
#   lcp_paths_for_pairs()    paths for every pair on one surface (sf lines)
#   lcp_apply_through_rule() Decision 17 point 2 (P3): via_unit_ids, in_network
#   lcp_write_layer()        write one surface layer to the paths GeoPackage,
#                            then read it back and compare
#   lcp_path_cost()          cost of a cell path, recomputed from the raster
#   lcp_qa_paths()           path QA for one surface (task 10.6)
#   lcp_route_share()        share of one line within d km of another
#   lcp_compare_variant()    Decision 18, per pair: one variant vs baseline
#   lcp_compare_summary()    Decision 18, per variant: shares, rho, labels
#   lcp_ntca_overlap()       Decision 17 point 9: paths vs NTCA corridors
#   lcp_selftest_synthetic() hand-computed grids (validation check a)
#   lcp_check_terra()        cost vs terra::costDist, 8 neighbours (check b)
#   lcp_check_gdistance()    cost vs gdistance, 16 neighbours,
#                            end-cell mode, point to point (check c)
#   lcp_validation_window()  crop r to the extent of some geometries + buffer
#   lcp_validation_pairs()   the pairs for checks (b) and (c)
# =============================================================================

# ---- Neighbourhood ----------------------------------------------------------
# Half set of offsets (dr = row step, dc = column step), so every undirected
# edge is made once. len = step length in cells.
lcp_neighbourhood <- function(neighbours = LCP_NEIGHBOURS) {
  if (!neighbours %in% c(4L, 8L, 16L)) {
    stop("lcp_neighbourhood(): neighbours must be 4, 8 or 16, not ",
         neighbours, call. = FALSE)
  }
  nb <- data.frame(dr = c(0L, 1L), dc = c(1L, 0L), type = "orth")
  if (neighbours >= 8L) {
    nb <- rbind(nb, data.frame(dr = c(1L, 1L), dc = c(-1L, 1L), type = "diag"))
  }
  if (neighbours == 16L) {
    nb <- rbind(nb, data.frame(dr = c(1L, 1L, 2L, 2L),
                               dc = c(-2L, 2L, -1L, 1L), type = "knight"))
  }
  nb$len <- sqrt(nb$dr^2 + nb$dc^2)
  nb
}

# ---- Reserve cells ----------------------------------------------------------
# Returns a list (one element per row of `reserves`) of cell numbers of `r`
# that the polygon touches (touches = TRUE) or covers (FALSE) AND that are
# non-NA on `r`. Rows with empty geometry give integer(0).
# GEOMETRYCOLLECTION features (st_make_valid in scripts/02 can make them) keep
# their polygon parts only, as in scripts/07 STEP 9.2b; terra::vect() cannot
# take them.
lcp_reserve_cells <- function(r, reserves, touches = LCP_RESERVE_TOUCHES) {
  stopifnot(inherits(r, "SpatRaster"), terra::nlyr(r) == 1L)
  g    <- sf::st_geometry(reserves)
  vals <- terra::values(r, mat = FALSE)
  out  <- vector("list", length(g))
  for (k in seq_along(g)) {
    gk <- g[k]
    if (sf::st_is_empty(gk)) {
      out[[k]] <- integer(0)
      next
    }
    if (as.character(sf::st_geometry_type(gk)) == "GEOMETRYCOLLECTION") {
      gk <- sf::st_union(sf::st_collection_extract(gk, "POLYGON"))
    }
    gk <- sf::st_cast(gk, "MULTIPOLYGON")
    cc <- terra::cells(r, terra::vect(gk), touches = touches)[, "cell"]
    cc <- as.integer(sort(unique(cc)))
    out[[k]] <- cc[!is.na(vals[cc])]
  }
  out
}

# ---- Graph build ------------------------------------------------------------
# r             : 1-layer SpatRaster of resistance (NA = not a node)
# reserve_cells : list of cell-number vectors (from lcp_reserve_cells())
# Returns a list:
#   g             igraph graph (undirected; no weight attribute)
#   w             edge weights (cell edges, then super-node joins = Inf)
#   n_cell_edges  number of cell-to-cell edges
#   super_node    super-node vertex id per reserve
#   super_edges   list of edge indices of each reserve's joins
#   reserve_nodes list of vertex ids of each reserve's cells
#   cell_of_node  cell number of each cell vertex
#   node_of_cell  vertex id of each cell (NA if not a node)
#   res_km, neighbours, knight_rule, n_nodes
lcp_build_graph <- function(r, reserve_cells,
                            neighbours  = LCP_NEIGHBOURS,
                            knight_rule = LCP_KNIGHT_RULE) {
  stopifnot(inherits(r, "SpatRaster"), terra::nlyr(r) == 1L)
  knight_rule <- match.arg(knight_rule, c("crossed_cells", "end_cells"))
  if (terra::is.lonlat(r)) {
    stop("lcp_build_graph(): r must be in a projected CRS (metres).",
         call. = FALSE)
  }
  rx <- terra::xres(r); ry <- terra::yres(r)
  if (abs(rx - ry) > 1e-6 * rx) {
    stop("lcp_build_graph(): cells must be square (xres ", rx, ", yres ", ry,
         ").", call. = FALSE)
  }
  res_km <- rx / 1000
  nr <- terra::nrow(r); nc <- terra::ncol(r)

  vals  <- terra::values(r, mat = FALSE)
  cells <- which(!is.na(vals))
  if (length(cells) == 0L) stop("lcp_build_graph(): r has no non-NA cells.",
                                call. = FALSE)
  if (any(vals[cells] < 0)) {
    stop("lcp_build_graph(): negative resistance values.", call. = FALSE)
  }
  n_nodes <- length(cells)
  node_of_cell <- rep(NA_integer_, terra::ncell(r))
  node_of_cell[cells] <- seq_len(n_nodes)
  rows <- (cells - 1L) %/% nc + 1L
  cols <- (cells - 1L) %%  nc + 1L

  nb <- lcp_neighbourhood(neighbours)
  from_l <- vector("list", nrow(nb)); to_l <- from_l; w_l <- from_l
  for (k in seq_len(nrow(nb))) {
    dr <- nb$dr[k]; dc <- nb$dc[k]
    tr <- rows + dr; tc <- cols + dc
    ok <- tr >= 1L & tr <= nr & tc >= 1L & tc <= nc
    i_cell <- cells[ok]
    j_cell <- (tr[ok] - 1L) * nc + tc[ok]
    keep   <- !is.na(vals[j_cell])
    i_cell <- i_cell[keep]; j_cell <- j_cell[keep]
    len_km <- nb$len[k] * res_km
    if (nb$type[k] == "knight" && knight_rule == "crossed_cells") {
      ir <- (i_cell - 1L) %/% nc + 1L; ic <- (i_cell - 1L) %% nc + 1L
      if (abs(dc) == 2L) {          # 1 row x 2 columns
        sc <- sign(dc)
        m1 <- (ir - 1L) * nc + (ic + sc)
        m2 <- (ir + dr - 1L) * nc + (ic + sc)
      } else {                      # 2 rows x 1 column
        sr <- sign(dr)
        m1 <- (ir + sr - 1L) * nc + ic
        m2 <- (ir + sr - 1L) * nc + (ic + dc)
      }
      ok2 <- !is.na(vals[m1]) & !is.na(vals[m2])
      i_cell <- i_cell[ok2]; j_cell <- j_cell[ok2]
      m1 <- m1[ok2]; m2 <- m2[ok2]
      w <- len_km * (vals[i_cell] + vals[m1] + vals[m2] + vals[j_cell]) / 4
    } else {
      w <- len_km * (vals[i_cell] + vals[j_cell]) / 2
    }
    from_l[[k]] <- node_of_cell[i_cell]
    to_l[[k]]   <- node_of_cell[j_cell]
    w_l[[k]]    <- w
  }
  from <- unlist(from_l, use.names = FALSE); rm(from_l)
  to   <- unlist(to_l,   use.names = FALSE); rm(to_l)
  w    <- unlist(w_l,    use.names = FALSE); rm(w_l)
  n_cell_edges <- length(w)

  # Super nodes: one per reserve, joined to each of its cells (weight Inf
  # until a search makes that reserve the source).
  n_res <- length(reserve_cells)
  super_node    <- n_nodes + seq_len(n_res)
  reserve_nodes <- lapply(reserve_cells, function(cc) {
    nn <- node_of_cell[cc]
    sort(unique(nn[!is.na(nn)]))
  })
  n_join <- lengths(reserve_nodes)
  join_from <- rep(super_node, n_join)
  join_to   <- unlist(reserve_nodes, use.names = FALSE)
  join_end  <- n_cell_edges + cumsum(n_join)
  super_edges <- lapply(seq_len(n_res), function(k) {
    if (n_join[k] == 0L) integer(0) else
      seq.int(join_end[k] - n_join[k] + 1L, join_end[k])
  })

  # Interleaved edge vector (from1, to1, from2, to2, ...) built in place, so
  # no 2 x E matrix copy is made (lower peak memory).
  n_e <- n_cell_edges + length(join_to)
  ev  <- integer(2 * n_e)
  ev[seq.int(1L, by = 2L, length.out = n_e)] <- c(from, join_from)
  rm(from)
  ev[seq.int(2L, by = 2L, length.out = n_e)] <- c(to, join_to)
  rm(to)
  g <- igraph::make_graph(edges = ev, n = n_nodes + n_res, directed = FALSE)
  rm(ev)
  list(
    g             = g,
    w             = c(w, rep(Inf, length(join_to))),
    n_cell_edges  = n_cell_edges,
    super_node    = super_node,
    super_edges   = super_edges,
    reserve_nodes = reserve_nodes,
    cell_of_node  = cells,
    node_of_cell  = node_of_cell,
    res_km        = res_km,
    neighbours    = neighbours,
    knight_rule   = knight_rule,
    n_nodes       = n_nodes
  )
}

# ---- Search -----------------------------------------------------------------
# One Dijkstra search from source reserve `from` (index into reserve_cells) to
# every target reserve in `to`. Returns a data.frame, one row per target:
#   from, to, cost (resistance-km; Inf = no path), exit_cell, entry_cell,
#   n_cells (cells on the path), and a list-column `cells` (path cells, from
#   the exit cell of the source to the entry cell of the target).
# Ties: the target cell with the lowest vertex id wins (deterministic).
lcp_search <- function(G, from, to, tol_rel = 1e-9) {
  stopifnot(length(from) == 1L, !(from %in% to))
  if (length(G$super_edges[[from]]) == 0L) {
    stop("lcp_search(): source reserve ", from, " has no footprint cells.",
         call. = FALSE)
  }
  w <- G$w
  w[G$super_edges[[from]]] <- 0
  src <- G$super_node[from]

  tgt_nodes <- sort(unique(unlist(G$reserve_nodes[to], use.names = FALSE)))
  d_all <- if (length(tgt_nodes) == 0L) numeric(0) else
    igraph::distances(G$g, v = src, to = tgt_nodes, weights = w,
                      mode = "all", algorithm = "dijkstra")[1, ]

  out <- data.frame(from = from, to = to, cost = Inf,
                    exit_cell = NA_integer_, entry_cell = NA_integer_,
                    n_cells = 0L)
  out$cells <- vector("list", length(to))
  best <- rep(NA_integer_, length(to))
  for (i in seq_along(to)) {
    nk <- G$reserve_nodes[[to[i]]]
    if (length(nk) == 0L) next
    dk <- d_all[match(nk, tgt_nodes)]
    if (all(is.infinite(dk))) next
    out$cost[i] <- min(dk)
    best[i] <- nk[which(dk == min(dk))[1]]
  }
  has <- !is.na(best)
  if (any(has)) {
    sp <- igraph::shortest_paths(G$g, from = src, to = best[has], weights = w,
                                 mode = "all", output = "both")
    idx <- which(has)
    for (j in seq_along(idx)) {
      i  <- idx[j]
      vp <- as.integer(sp$vpath[[j]])
      ep <- as.integer(sp$epath[[j]])
      path_cost <- sum(w[ep])
      if (abs(path_cost - out$cost[i]) > tol_rel * max(1, out$cost[i])) {
        stop("lcp_search(): path cost ", path_cost, " differs from the ",
             "Dijkstra distance ", out$cost[i], " (from ", from, " to ",
             to[i], ").", call. = FALSE)
      }
      vp <- vp[vp <= G$n_nodes]            # drop the super node
      cc <- G$cell_of_node[vp]
      out$cells[[i]]   <- cc
      out$n_cells[i]   <- length(cc)
      out$exit_cell[i] <- cc[1]
      out$entry_cell[i] <- cc[length(cc)]
    }
  }
  out
}

# ---- Path geometry ----------------------------------------------------------
# Cell centres -> LINESTRING in the CRS of r. Fewer than 2 cells (a gap-0 /
# shared-cell pair) gives an empty LINESTRING.
lcp_path_line <- function(cells, r) {
  if (length(cells) < 2L) return(sf::st_linestring())
  sf::st_linestring(terra::xyFromCell(r, cells))
}

# ---- Contiguous pairs ---------------------------------------------------------
# Decision 17 point 6 (amended 2026-10-02): a pair is contiguous if the two
# reserves share at least one footprint cell (touches = TRUE). Every gap-0
# pair is contiguous; a pair less than about 1.4 km apart can be too. Such a
# pair gets cost 0 and an empty path.
lcp_contiguous <- function(cells_a, cells_b) {
  length(intersect(cells_a, cells_b)) > 0L
}

# ---- Memory report ------------------------------------------------------------
# Linux: the process peak (VmHWM, MB), which includes igraph's C memory.
# Windows / macOS: only the R heap peak from gc(); igraph's C memory is not
# in it, so read the process peak in Task Manager / Activity Monitor.
lcp_mem_report <- function() {
  st <- "/proc/self/status"
  if (file.exists(st)) {
    hwm <- grep("^VmHWM", readLines(st), value = TRUE)
    kb  <- as.numeric(gsub("[^0-9]", "", hwm))
    return(list(peak_mb = round(kb / 1024), source = "process peak (VmHWM)"))
  }
  g <- gc()
  list(peak_mb = round(sum(g[, ncol(g)])),
       source = "R heap peak only (gc); read the process peak in Task Manager")
}

# ---- Reserve pairs (Decision 17 points 1, 6 and 8) --------------------------
# Euclidean allocation: every non-NA cell of r goes to the nearest reserve
# polygon by straight-line distance. The polygon edges are densified to
# densify_m and used as generator points, so the distance is exact to within
# densify_m / 2 (125 m at the default; cells are 1 km). The cells of each
# reserve (lcp_reserve_cells(), touches = TRUE) take their own reserve first;
# a cell shared by two reserves goes to the lower unit_id. The nearest-point
# search (sf / GEOS tree) runs in chunks to keep memory low.
# Returns an integer vector over all cells of r: unit_id, or NA off the
# footprint.
lcp_alloc_zones <- function(r, reserves, reserve_cells, densify_m = 250,
                            chunk = 250000L) {
  stopifnot(nrow(reserves) == length(reserve_cells), "unit_id" %in% names(reserves))
  uid <- as.integer(reserves$unit_id)
  g <- sf::st_geometry(reserves)
  for (k in which(as.character(sf::st_geometry_type(g)) == "GEOMETRYCOLLECTION")) {
    g[k] <- sf::st_union(sf::st_collection_extract(g[k], "POLYGON"))
  }
  b <- sf::st_segmentize(sf::st_cast(sf::st_boundary(sf::st_cast(g, "MULTIPOLYGON")),
                                     "MULTILINESTRING"), densify_m)
  # Generator points per reserve from its own coordinates. (st_cast() of the
  # whole set to POINT did not keep the ids aligned in sf 1.0-15 — found in
  # testing, 2026-10-03.)
  gen_xy <- do.call(rbind, lapply(seq_along(b), function(k) {
    xy <- sf::st_coordinates(b[k])[, c("X", "Y"), drop = FALSE]
    data.frame(x = xy[, 1], y = xy[, 2], uid = uid[k])
  }))
  gen <- sf::st_as_sf(gen_xy, coords = c("x", "y"), crs = sf::st_crs(reserves))
  # Guard: each reserve's generators lie on its own polygon edge.
  for (k in seq_along(uid)) {
    gk <- gen[gen$uid == uid[k], ]
    if (nrow(gk) == 0L) stop("lcp_alloc_zones(): no generator points for unit_id ",
                             uid[k], ".", call. = FALSE)
    d <- max(as.numeric(sf::st_distance(gk[c(1L, nrow(gk)), ], b[k])))
    if (d > 1) stop("lcp_alloc_zones(): generator points of unit_id ", uid[k],
                    " are off its polygon edge (", round(d), " m).", call. = FALSE)
  }

  vals  <- terra::values(r, mat = FALSE)
  cells <- which(!is.na(vals))
  lab   <- integer(length(cells))
  idx   <- split(seq_along(cells), ceiling(seq_along(cells) / chunk))
  for (ii in idx) {
    q <- sf::st_as_sf(as.data.frame(terra::xyFromCell(r, cells[ii])),
                      coords = c("x", "y"), crs = sf::st_crs(reserves))
    lab[ii] <- gen$uid[sf::st_nearest_feature(q, gen)]
    rm(q)
  }
  alloc <- rep(NA_integer_, terra::ncell(r))
  alloc[cells] <- lab
  # Reserve cells take their own reserve; lower unit_id wins on shared cells.
  for (k in order(uid, decreasing = TRUE)) alloc[reserve_cells[[k]]] <- uid[k]
  alloc
}

# Pairs of zones that share at least one cell edge (rook). Returns a
# data.frame: unit_id_a < unit_id_b, shared_edges (number of cell edges).
lcp_zone_adjacency <- function(alloc, nr, nc) {
  L <- matrix(alloc, nrow = nr, ncol = nc, byrow = TRUE)
  h1 <- L[, -nc, drop = FALSE]; h2 <- L[, -1, drop = FALSE]
  v1 <- L[-nr, , drop = FALSE]; v2 <- L[-1, , drop = FALSE]
  a <- c(h1, v1); b <- c(h2, v2)
  keep <- !is.na(a) & !is.na(b) & a != b
  a <- a[keep]; b <- b[keep]
  lo <- pmin(a, b); hi <- pmax(a, b)
  tab <- as.data.frame(table(paste(lo, hi)), stringsAsFactors = FALSE)
  ab  <- do.call(rbind, strsplit(tab$Var1, " ", fixed = TRUE))
  out <- data.frame(unit_id_a = as.integer(ab[, 1]), unit_id_b = as.integer(ab[, 2]),
                    shared_edges = as.integer(tab$Freq))
  out[order(out$unit_id_a, out$unit_id_b), ]
}

# Candidate pairs -> pair table. reserves: sf with unit_id, unit_name, in the
# same order as reserve_cells. groups: named list (NETWORK_GROUPS). A pair is
# kept if the straight-line gap between the two polygons is <= max_gap_km.
# Columns: pair_id, from/to unit_id, name and network_group, gap_km,
# contiguous (shared footprint cell), cross_group, zone_shared_edges.
lcp_build_pairs <- function(adjacency, reserves, reserve_cells, groups,
                            max_gap_km) {
  uid <- as.integer(reserves$unit_id)
  grp_of <- stats::setNames(rep(names(groups), lengths(groups)),
                            unlist(groups, use.names = FALSE))
  ia <- match(adjacency$unit_id_a, uid); ib <- match(adjacency$unit_id_b, uid)
  if (anyNA(ia) || anyNA(ib)) stop("lcp_build_pairs(): a zone id is not a reserve.",
                                   call. = FALSE)
  gap_m <- vapply(seq_along(ia), function(i) {
    as.numeric(sf::st_distance(sf::st_geometry(reserves)[ia[i]],
                               sf::st_geometry(reserves)[ib[i]]))
  }, numeric(1))
  pairs <- data.frame(
    from_unit_id  = uid[ia],
    from_name     = reserves$unit_name[ia],
    from_group    = unname(grp_of[as.character(uid[ia])]),
    to_unit_id    = uid[ib],
    to_name       = reserves$unit_name[ib],
    to_group      = unname(grp_of[as.character(uid[ib])]),
    gap_km        = round(gap_m / 1000, 2),
    contiguous    = vapply(seq_along(ia), function(i)
                      lcp_contiguous(reserve_cells[[ia[i]]], reserve_cells[[ib[i]]]),
                      logical(1)),
    zone_shared_edges = adjacency$shared_edges,
    stringsAsFactors = FALSE
  )
  pairs$cross_group <- pairs$from_group != pairs$to_group
  dropped <- pairs[pairs$gap_km > max_gap_km, ]
  pairs <- pairs[pairs$gap_km <= max_gap_km, ]
  pairs <- pairs[order(pairs$from_unit_id, pairs$to_unit_id), ]
  pairs$pair_id <- seq_len(nrow(pairs))
  pairs <- pairs[, c("pair_id", "from_unit_id", "from_name", "from_group",
                     "to_unit_id", "to_name", "to_group", "gap_km", "contiguous",
                     "cross_group", "zone_shared_edges")]
  rownames(pairs) <- NULL
  list(pairs = pairs, dropped = dropped)
}

# ---- Paths for every pair on one surface (Decision 17 points 3, 6) ----------
# G: graph from lcp_build_graph() on surface r, built with reserve_cells in the
# order of `reserves`. pairs: tbl_12 pair table. One search per source reserve
# (the from_unit_id of its non-contiguous pairs) to all of its targets.
# Contiguous pairs get cost 0 and an empty path, with no search. A pair with no
# path (all routes blocked by NA cells) is kept with path_status "no_path".
# Returns an sf of LINESTRINGs (CRS of r), one row per pair, with a list column
# `cells` (path cells; dropped by lcp_write_layer()).
lcp_paths_for_pairs <- function(G, r, reserves, reserve_cells, pairs, surface) {
  uid <- as.integer(reserves$unit_id)
  k_of <- function(id) {
    k <- match(id, uid)
    if (anyNA(k)) stop("lcp_paths_for_pairs(): unit_id not in reserves: ",
                       paste(id[is.na(k)], collapse = ", "), call. = FALSE)
    k
  }
  n <- nrow(pairs)
  out <- data.frame(
    pair_id = pairs$pair_id, surface = surface,
    from_unit_id = pairs$from_unit_id, from_name = pairs$from_name,
    to_unit_id = pairs$to_unit_id, to_name = pairs$to_name,
    from_group = pairs$from_group, to_group = pairs$to_group,
    cross_group = pairs$cross_group, contiguous = pairs$contiguous,
    gap_km = pairs$gap_km,
    path_status = ifelse(pairs$contiguous, "contiguous", NA_character_),
    cost_rkm = ifelse(pairs$contiguous, 0, NA_real_),
    path_km = ifelse(pairs$contiguous, 0, NA_real_),
    path_gap_ratio = NA_real_, n_cells = 0L,
    exit_cell = NA_integer_, entry_cell = NA_integer_,
    stringsAsFactors = FALSE)
  cells <- vector("list", n)
  geoms <- rep(list(sf::st_linestring()), n)

  todo <- which(!pairs$contiguous)
  for (src in unique(pairs$from_unit_id[todo])) {
    ii <- todo[pairs$from_unit_id[todo] == src]
    s  <- lcp_search(G, from = k_of(src), to = k_of(pairs$to_unit_id[ii]))
    for (j in seq_along(ii)) {
      i <- ii[j]
      if (!is.finite(s$cost[j])) { out$path_status[i] <- "no_path"; next }
      cc <- s$cells[[j]]
      ln <- lcp_path_line(cc, r)
      out$path_status[i] <- "path"
      out$cost_rkm[i]    <- s$cost[j]
      out$n_cells[i]     <- length(cc)
      out$exit_cell[i]   <- s$exit_cell[j]
      out$entry_cell[i]  <- s$entry_cell[j]
      out$path_km[i]     <- as.numeric(sf::st_length(
                              sf::st_sfc(ln, crs = sf::st_crs(reserves)))) / 1000
      cells[[i]] <- cc
      geoms[[i]] <- ln
    }
  }
  ok <- out$path_status == "path"
  out$path_gap_ratio[ok] <- out$path_km[ok] / out$gap_km[ok]
  out$cells <- cells
  sf::st_sf(out, geometry = sf::st_sfc(geoms, crs = sf::st_crs(reserves)))
}

# ---- Decision 17 point 2 (P3): a path that crosses a third reserve ----------
# via_unit_ids: reserves (other than the pair's own two) whose cells the path
# crosses; cells shared with either end reserve do not count.
# redundant_via_unit_ids: the via reserves C for which A-C and C-B are both
# pairs. in_network = FALSE if any such C exists; also FALSE for "no_path"
# (no route, so no link). Contiguous pairs: in_network = TRUE.
lcp_apply_through_rule <- function(paths, pairs, reserves, reserve_cells) {
  uid   <- as.integer(reserves$unit_id)
  owner <- data.frame(cell = unlist(reserve_cells, use.names = FALSE),
                      uid  = rep(uid, lengths(reserve_cells)))
  key   <- function(a, b) paste(pmin(a, b), pmax(a, b))
  pkeys <- key(pairs$from_unit_id, pairs$to_unit_id)
  via <- red <- character(nrow(paths))
  inn <- rep(TRUE, nrow(paths))
  for (i in seq_len(nrow(paths))) {
    if (paths$path_status[i] == "no_path") { inn[i] <- FALSE; next }
    cc <- paths$cells[[i]]
    if (length(cc) == 0L) next
    a <- paths$from_unit_id[i]; b <- paths$to_unit_id[i]
    ends <- union(reserve_cells[[match(a, uid)]], reserve_cells[[match(b, uid)]])
    hit  <- owner[owner$cell %in% setdiff(cc, ends) & !owner$uid %in% c(a, b), ]
    v <- sort(unique(hit$uid))
    if (length(v) == 0L) next
    rv <- v[key(a, v) %in% pkeys & key(v, b) %in% pkeys]
    via[i] <- paste(v, collapse = ";")
    red[i] <- paste(rv, collapse = ";")
    inn[i] <- length(rv) == 0L
  }
  paths$via_unit_ids <- via
  paths$redundant_via_unit_ids <- red
  paths$in_network <- inn
  paths
}

# ---- Write one surface layer, then read it back and compare ------------------
# Replaces only `layer` in the GeoPackage at `path` (other surfaces stay).
# List columns are dropped. Read-back: same rows, same attributes (logical
# fields compared as integer), same path lengths (relative 1e-9) and the same
# empty geometries. Any difference stops the script.
lcp_write_layer <- function(x, path, layer) {
  x <- x[, !vapply(sf::st_drop_geometry(x), is.list, logical(1))]
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  sf::st_write(x, path, layer = layer, delete_layer = TRUE, quiet = TRUE)
  y <- sf::st_read(path, layer = layer, quiet = TRUE)
  norm <- function(d) {
    d <- as.data.frame(sf::st_drop_geometry(d))
    d[] <- lapply(d, function(v) if (is.logical(v)) as.integer(v) else v)
    rownames(d) <- NULL
    d
  }
  probs <- c(
    if (nrow(y) != nrow(x)) "row count differs",
    if (nrow(y) == nrow(x) &&
        !isTRUE(all.equal(norm(x), norm(y)[, names(norm(x))],
                          check.attributes = FALSE))) "attributes differ",
    if (nrow(y) == nrow(x) &&
        !isTRUE(all.equal(as.numeric(sf::st_length(x)),
                          as.numeric(sf::st_length(y)), tolerance = 1e-9)))
      "path lengths differ",
    if (nrow(y) == nrow(x) && !identical(sf::st_is_empty(x), sf::st_is_empty(y)))
      "empty geometries differ")
  if (length(probs) > 0) {
    stop("lcp_write_layer(): read-back of layer '", layer, "' in ", path, ": ",
         paste(probs, collapse = "; "), ".", call. = FALSE)
  }
  message("Wrote layer '", layer, "' to ", path, " (", nrow(x),
          " features; read back and checked)")
  invisible(path)
}

# ---- Cost of a cell path, recomputed from the raster ---------------------------
# Independent of the graph: walks the cells and applies the Decision-17 step
# rule to the raster values. Returns list(cost, length_km, steps_ok).
lcp_path_cost <- function(cells, r, knight_rule = LCP_KNIGHT_RULE) {
  if (length(cells) < 2L) return(list(cost = 0, length_km = 0, steps_ok = TRUE))
  nc <- terra::ncol(r); res_km <- terra::xres(r) / 1000
  vals <- terra::values(r, mat = FALSE)
  rw <- (cells - 1L) %/% nc + 1L; cl <- (cells - 1L) %% nc + 1L
  i <- seq_len(length(cells) - 1L)
  dr <- rw[i + 1L] - rw[i]; dc <- cl[i + 1L] - cl[i]
  adr <- abs(dr); adc <- abs(dc)
  ok <- (adr + adc > 0) & adr <= 2L & adc <= 2L & !(adr == 2L & adc != 1L) &
        !(adc == 2L & adr != 1L)
  len <- sqrt(dr^2 + dc^2) * res_km
  v1 <- vals[cells[i]]; v2 <- vals[cells[i + 1L]]
  cost <- len * (v1 + v2) / 2
  kn <- which(ok & ((adr == 1L & adc == 2L) | (adr == 2L & adc == 1L)))
  if (knight_rule == "crossed_cells" && length(kn) > 0L) {
    r0 <- rw[i][kn]; c0 <- cl[i][kn]; dk <- dr[kn]; ck <- dc[kn]
    two_col <- abs(ck) == 2L
    m1 <- ifelse(two_col, (r0 - 1L) * nc + (c0 + sign(ck)),
                          (r0 + sign(dk) - 1L) * nc + c0)
    m2 <- ifelse(two_col, (r0 + dk - 1L) * nc + (c0 + sign(ck)),
                          (r0 + sign(dk) - 1L) * nc + (c0 + ck))
    cost[kn] <- len[kn] * (v1[kn] + vals[m1] + vals[m2] + v2[kn]) / 4
  }
  list(cost = sum(cost), length_km = sum(len), steps_ok = all(ok))
}

# ---- Path QA for one surface (task 10.6) ----------------------------------------
# paths: output of lcp_paths_for_pairs() + lcp_apply_through_rule() (with the
# list column `cells`). Returns one row per pair; each check is TRUE/FALSE, NA
# where it does not apply; qa_pass = no FALSE. path_gap_ratio is information.
lcp_qa_paths <- function(paths, r, reserves, reserve_cells, pairs,
                         tol_rel = 1e-9) {
  uid  <- as.integer(reserves$unit_id)
  vals <- terra::values(r, mat = FALSE)
  d <- sf::st_drop_geometry(paths)
  empty <- sf::st_is_empty(paths)
  n <- nrow(d)
  pi <- match(d$pair_id, pairs$pair_id)
  q <- data.frame(pair_id = d$pair_id, surface = d$surface,
                  from_name = d$from_name, to_name = d$to_name,
                  path_status = d$path_status, gap_km = d$gap_km,
                  cost_rkm = d$cost_rkm, path_km = d$path_km,
                  path_gap_ratio = d$path_gap_ratio, in_network = d$in_network,
                  stringsAsFactors = FALSE)
  q$in_pair_table <- !is.na(pi) &
    d$from_unit_id == pairs$from_unit_id[pi] & d$to_unit_id == pairs$to_unit_id[pi]
  q$status_ok <- d$path_status %in% c("path", "contiguous", "no_path") &
    ((d$path_status == "contiguous") == pairs$contiguous[pi])
  q$empty_ok  <- empty == (d$path_status %in% c("contiguous", "no_path"))
  q$footprint_ok <- q$start_ok <- q$end_ok <- q$steps_ok <- NA
  q$cost_ok <- q$length_ok <- NA
  for (k in seq_len(n)) {
    if (d$path_status[k] == "contiguous") {
      q$cost_ok[k]   <- isTRUE(d$cost_rkm[k] == 0)
      q$length_ok[k] <- isTRUE(d$path_km[k] == 0)
      next
    }
    if (d$path_status[k] != "path") next
    cc <- paths$cells[[k]]
    a <- reserve_cells[[match(d$from_unit_id[k], uid)]]
    b <- reserve_cells[[match(d$to_unit_id[k], uid)]]
    q$footprint_ok[k] <- all(!is.na(vals[cc]))
    q$start_ok[k] <- cc[1] %in% a && d$exit_cell[k] == cc[1]
    q$end_ok[k]   <- cc[length(cc)] %in% b && d$entry_cell[k] == cc[length(cc)]
    pc <- lcp_path_cost(cc, r)
    q$steps_ok[k]  <- pc$steps_ok
    q$cost_ok[k]   <- abs(pc$cost - d$cost_rkm[k]) <= tol_rel * max(1, d$cost_rkm[k])
    ln_xy <- sf::st_coordinates(sf::st_geometry(paths)[k])
    q$length_ok[k] <- abs(pc$length_km - d$path_km[k]) <= tol_rel * max(1, d$path_km[k]) &&
                      nrow(ln_xy) == length(cc)
  }
  q$network_ok <- d$in_network ==
    (d$path_status != "no_path" & d$redundant_via_unit_ids == "")
  chk <- c("in_pair_table", "status_ok", "empty_ok", "footprint_ok", "start_ok",
           "end_ok", "steps_ok", "cost_ok", "length_ok", "network_ok")
  q$qa_pass <- apply(q[, chk], 1, function(x) !any(x %in% FALSE))
  q
}

# ---- Decision 18: route overlap ---------------------------------------------------
# Share of the length of line a that lies within d_km of line b (0-1). NA if
# either line is empty.
lcp_route_share <- function(a, b, d_km) {
  if (sf::st_is_empty(a) || sf::st_is_empty(b)) return(NA_real_)
  la <- as.numeric(sf::st_length(a))
  if (la == 0) return(NA_real_)
  inside <- suppressWarnings(sf::st_intersection(a, sf::st_buffer(b, d_km * 1000)))
  li <- if (length(inside) == 0) 0 else sum(as.numeric(sf::st_length(inside)))
  min(1, max(0, li / la))
}

# ---- Decision 18, per pair: one variant against the baseline ---------------------
# Compared pairs: not contiguous (point 1). Route overlap = min(share A, share
# B) at d_km (point 2); material if < route_material (point 3). Percentile
# rank of cost among the compared pairs, ties = average rank; material if
# |change| >= rank_material (point 4). Descriptive: overlap at descr_km, path
# length ratio, in_network change, via change (point 7).
lcp_compare_variant <- function(base, var, d_km, descr_km, route_material,
                                rank_material) {
  stopifnot(identical(base$pair_id, var$pair_id))
  keep <- !base$contiguous
  b <- base[keep, ]; v <- var[keep, ]
  if (any(b$path_status != "path") || any(v$path_status != "path")) {
    stop("lcp_compare_variant(): a compared pair has no path on '",
         v$surface[1], "' or the baseline; Decision 18 does not cover it.",
         call. = FALSE)
  }
  gb <- sf::st_geometry(b); gv <- sf::st_geometry(v)
  n  <- nrow(b)
  share_bv <- share_vb <- numeric(n)
  descr <- matrix(NA_real_, n, length(descr_km),
                  dimnames = list(NULL, paste0("route_overlap_", descr_km, "km")))
  for (i in seq_len(n)) {
    share_bv[i] <- lcp_route_share(gb[i], gv[i], d_km)
    share_vb[i] <- lcp_route_share(gv[i], gb[i], d_km)
    for (j in seq_along(descr_km)) {
      descr[i, j] <- min(lcp_route_share(gb[i], gv[i], descr_km[j]),
                         lcp_route_share(gv[i], gb[i], descr_km[j]))
    }
  }
  pr <- function(x) (rank(x, ties.method = "average") - 1) / (length(x) - 1)
  out <- data.frame(
    pair_id = b$pair_id, variant = v$surface[1],
    from_name = b$from_name, to_name = b$to_name, gap_km = b$gap_km,
    share_base_in_variant = share_bv, share_variant_in_base = share_vb,
    route_overlap = pmin(share_bv, share_vb),
    descr,
    cost_base = b$cost_rkm, cost_variant = v$cost_rkm,
    rank_base = pr(b$cost_rkm), rank_variant = pr(v$cost_rkm),
    stringsAsFactors = FALSE, check.names = FALSE)
  out$rank_change    <- out$rank_variant - out$rank_base
  out$material_route <- out$route_overlap < route_material
  out$material_rank  <- abs(out$rank_change) >= rank_material
  out$material_pair  <- out$material_route | out$material_rank
  out$path_length_ratio  <- v$path_km / b$path_km
  out$in_network_base    <- b$in_network
  out$in_network_variant <- v$in_network
  out$in_network_changed <- b$in_network != v$in_network
  out$via_base    <- b$via_unit_ids
  out$via_variant <- v$via_unit_ids
  out$via_changed <- b$via_unit_ids != v$via_unit_ids
  out
}

# ---- Decision 18, per variant: summary and labels (points 5-6) -------------------
# label: "robust" if share of material pairs <= max_share AND Spearman rho >=
# min_rho, else "sensitive". The road value (road15 + road50) is "robust" only
# if both are robust.
lcp_compare_summary <- function(cmp_list, n_contiguous, max_share, min_rho) {
  rows <- lapply(cmp_list, function(x) {
    rho <- stats::cor(x$cost_base, x$cost_variant, method = "spearman")
    sh  <- mean(x$material_pair)
    data.frame(
      variant = x$variant[1],
      tests = switch(x$variant[1], noghm = "gHM multiplier (Decision 14)",
                     road15 = , road50 = "road value (Decision 15)",
                     "unknown"),
      pairs_compared = nrow(x), contiguous_excluded = n_contiguous,
      share_material_route = mean(x$material_route),
      share_material_rank  = mean(x$material_rank),
      share_material_pair  = sh,
      spearman_rho = rho,
      median_route_overlap = stats::median(x$route_overlap),
      in_network_changed = sum(x$in_network_changed),
      via_changed = sum(x$via_changed),
      label = if (sh <= max_share && rho >= min_rho) "robust" else "sensitive",
      stringsAsFactors = FALSE)
  })
  s <- do.call(rbind, rows)
  road <- s$variant %in% c("road15", "road50")
  s$choice_label <- s$label
  if (all(c("road15", "road50") %in% s$variant)) {
    s$choice_label[road] <- if (all(s$label[road] == "robust")) "robust" else "sensitive"
  }
  rownames(s) <- NULL
  s
}

# ---- Decision 17 point 9: baseline paths vs the NTCA corridor polygons ------------
# Descriptive only — not a validation (the corridors come from a different
# method). (i) per path: length inside any corridor polygon and its share of
# the path length; (ii) per corridor: whether at least one path crosses it.
# A path "crosses" a corridor if the line intersects the polygon. No buffer is
# used (Decision 17 fixes none). Returns list(per_path, per_corridor).
lcp_ntca_overlap <- function(paths, corridors) {
  cg <- sf::st_make_valid(sf::st_geometry(corridors))
  for (k in which(as.character(sf::st_geometry_type(cg)) == "GEOMETRYCOLLECTION")) {
    cg[k] <- sf::st_union(sf::st_collection_extract(cg[k], "POLYGON"))
  }
  cu <- sf::st_union(cg)
  d  <- sf::st_drop_geometry(paths)
  g  <- sf::st_geometry(paths)
  is_path <- d$path_status == "path"
  km_in <- share <- rep(NA_real_, nrow(d))
  n_cross <- rep(NA_integer_, nrow(d)); ids <- rep("", nrow(d))
  hits <- sf::st_intersects(g, cg)
  for (i in which(is_path)) {
    inside <- suppressWarnings(sf::st_intersection(g[i], cu))
    li <- if (length(inside) == 0) 0 else sum(as.numeric(sf::st_length(inside)))
    km_in[i] <- li / 1000
    share[i] <- min(1, li / as.numeric(sf::st_length(g[i])))
    h <- corridors$corridor_id[hits[[i]]]
    n_cross[i] <- length(h)
    ids[i] <- paste(sort(h), collapse = ";")
  }
  per_path <- data.frame(
    pair_id = d$pair_id, from_name = d$from_name, to_name = d$to_name,
    path_status = d$path_status, path_km = d$path_km,
    km_in_corridor = km_in, share_in_corridor = share,
    n_corridors_crossed = n_cross, corridor_ids = ids,
    stringsAsFactors = FALSE)
  crossed_by <- lapply(seq_len(nrow(corridors)), function(k) {
    sort(d$pair_id[is_path & vapply(hits, function(h) k %in% h, logical(1))])
  })
  per_corridor <- data.frame(
    corridor_id = corridors$corridor_id,
    corridor_label = corridors$corridor_label,
    state = corridors$state,
    area_km2 = round(as.numeric(sf::st_area(cg)) / 1e6, 1),
    crossed = lengths(crossed_by) > 0L,
    n_paths = lengths(crossed_by),
    pair_ids = vapply(crossed_by, paste, character(1), collapse = ";"),
    stringsAsFactors = FALSE)
  list(per_path = per_path, per_corridor = per_corridor)
}

# ---- Validation check (a): synthetic grids, hand-computed -------------------
# 7 x 7 grid of 1 km cells. A = row 2, B = row 6 (whole rows). Returns one row
# per case: expected (by hand) and engine cost; pass = |diff| <= tol.
lcp_selftest_synthetic <- function(tol = 1e-9) {
  mk <- function(vals) {
    terra::rast(nrows = 7, ncols = 7, xmin = 0, xmax = 7000,
                ymin = 0, ymax = 7000, crs = "EPSG:7755", vals = vals)
  }
  row_cells <- function(rw) (rw - 1L) * 7L + 1:7
  run <- function(r, A, B, nbh, rule) {
    G <- lcp_build_graph(r, list(A, B), neighbours = nbh, knight_rule = rule)
    lcp_search(G, from = 1L, to = 2L)$cost
  }
  road <- rep(1, 49); road[row_cells(4L)] <- 30   # one-cell road line
  nar  <- rep(1, 49); nar[row_cells(4L)]  <- NA   # one-cell NA line
  flat <- rep(1, 49)
  A <- row_cells(2L); B <- row_cells(6L)
  s5 <- sqrt(5); s2 <- sqrt(2)
  cases <- list(
    # name, raster, A, B, neighbours, knight rule, expected
    list("road line, 8 nb",             road, A, B,  8L, "crossed_cells", 33),
    list("road line, 16 nb, crossed",   road, A, B, 16L, "crossed_cells", 33),
    list("road line, 16 nb, end cells", road, A, B, 16L, "end_cells",     2 + s5),
    list("NA line, 16 nb, crossed",     nar,  A, B, 16L, "crossed_cells", Inf),
    list("NA line, 16 nb, end cells",   nar,  A, B, 16L, "end_cells",     2 + s5),
    list("flat, cell to cell, 8 nb",    flat, 1L, 19L,  8L, "crossed_cells", 2 * s2 + 2),
    list("flat, cell to cell, 16 nb",   flat, 1L, 19L, 16L, "crossed_cells", 2 * s5)
  )
  # Expected values (by hand): road line — the path must cross row 4; two
  # half-steps into and out of a 30 cell cost 15.5 + 15.5, plus 1 + 1 for rows
  # 2->3 and 5->6 = 33. A crossed-cells knight over row 4 costs sqrt(5) x 15.5
  # = 34.66, so it is not used. With end cells only, a knight from row 3 to
  # row 5 jumps the line: 1 + sqrt(5) + 1. Flat, cell 1 (row 1, col 1) to
  # cell 19 (row 3, col 5): 2 diagonals + 2 straight steps (8 nb) or 2 knight
  # steps (16 nb).
  res <- do.call(rbind, lapply(cases, function(cs) {
    got <- run(mk(cs[[2]]), cs[[3]], cs[[4]], cs[[5]], cs[[6]])
    data.frame(check = "a_synthetic", case = cs[[1]], neighbours = cs[[5]],
               knight_rule = cs[[6]], expected = cs[[7]], engine = got,
               reference = cs[[7]],
               pass = (is.infinite(cs[[7]]) && is.infinite(got)) ||
                      (is.finite(got) && abs(got - cs[[7]]) <= tol))
  }))
  res
}

# ---- Validation check (b): terra::costDist, 8 neighbours --------------------
# Both runs use a copy of r with the source cells set to 0: terra marks its
# targets by value, and a target cell's own value enters terra's first step.
# The source is free in the engine anyway, so only the first half-step can
# differ. terra combines two cells as mean x step length (checked on a small
# grid, 2026-10-02); costs are in map units (m), so /1000 gives km.
lcp_check_terra <- function(r, A_cells, B_cells, maxiter = 1000L) {
  r0 <- r
  r0[A_cells] <- 0
  # terra::costDist() iterates; its default (50) did not converge on a long
  # window in testing (2026-10-03). Any warning is captured and reported.
  warn <- NULL
  d <- withCallingHandlers(
    terra::costDist(r0, target = 0, maxiter = maxiter),
    warning = function(w) {
      warn <<- c(warn, conditionMessage(w)); invokeRestart("muffleWarning")
    })
  ref <- min(terra::values(d, mat = FALSE)[B_cells], na.rm = TRUE) / 1000
  G  <- lcp_build_graph(r0, list(A_cells, B_cells), neighbours = 8L)
  eng <- lcp_search(G, from = 1L, to = 2L)$cost
  data.frame(check = "b_terra_costDist", neighbours = 8L,
             engine = eng, reference = ref,
             rel_diff = abs(eng - ref) / max(1, ref),
             note = if (is.null(warn)) "" else
               paste0("terra (maxiter ", maxiter, "): ",
                      paste(unique(warn), collapse = "; ")))
}

# ---- Validation check (c): gdistance, 16 neighbours, end-cell mode ----------
# Point to point between one source cell and one target cell (for example the
# exit and entry cells of an engine path), on a window r_win that contains
# the path. gdistance: conductance = 1 / mean(two cells), geoCorrection
# type "c" divides by the step length (m), so costDistance = sum of
# mean x length (m); /1000 gives resistance-km.
lcp_check_gdistance <- function(r_win, from_cell, to_cell) {
  if (!requireNamespace("gdistance", quietly = TRUE) ||
      !requireNamespace("raster", quietly = TRUE)) {
    stop("lcp_check_gdistance(): packages gdistance and raster are needed ",
         "(validation only; see scripts/00a).", call. = FALSE)
  }
  rr <- raster::raster(r_win)
  tr <- gdistance::transition(rr, transitionFunction = function(x) 1 / mean(x),
                              directions = 16, symm = TRUE)
  tr <- gdistance::geoCorrection(tr, type = "c", multpl = FALSE)
  xy_from <- terra::xyFromCell(r_win, from_cell)
  xy_to   <- terra::xyFromCell(r_win, to_cell)
  ref <- as.numeric(gdistance::costDistance(tr, xy_from, xy_to)) / 1000
  G   <- lcp_build_graph(r_win, list(from_cell, to_cell), neighbours = 16L,
                         knight_rule = "end_cells")
  s   <- lcp_search(G, from = 1L, to = 2L)
  eng <- s$cost
  # Path overlap: share of the engine's path cells that the gdistance path also
  # uses. Reported, not a stop — tied paths can differ.
  overlap <- NA_real_
  sp_line <- tryCatch(gdistance::shortestPath(tr, xy_from, xy_to,
                                              output = "SpatialLines"),
                      error = function(e) NULL)
  if (!is.null(sp_line) && length(s$cells[[1]]) > 0L) {
    xy_g <- sp_line@lines[[1]]@Lines[[1]]@coords
    cells_g <- unique(terra::cellFromXY(r_win, xy_g))
    overlap <- length(intersect(s$cells[[1]], cells_g)) / length(s$cells[[1]])
  }
  data.frame(check = "c_gdistance", neighbours = 16L,
             engine = eng, reference = ref,
             rel_diff = abs(eng - ref) / max(1, ref),
             path_overlap = overlap, note = "")
}

# ---- Validation helpers -------------------------------------------------------
# Crop r to the bounding box of `geoms` (sfc) grown by buffer_km on each side,
# snapped outward to whole cells.
lcp_validation_window <- function(r, geoms, buffer_km) {
  bb <- sf::st_bbox(geoms)
  e  <- terra::ext(bb[["xmin"]] - buffer_km * 1000, bb[["xmax"]] + buffer_km * 1000,
                   bb[["ymin"]] - buffer_km * 1000, bb[["ymax"]] + buffer_km * 1000)
  terra::crop(r, terra::intersect(e, terra::ext(r)), snap = "out")
}

# Pairs for checks (b) and (c) (Decision 17 point 4), from the baseline paths
# with path_status "path" (contiguous pairs have no path to check):
#   min_nonzero_gap, median_gap, max_gap (ties: lowest pair_id), and, with
#   add_max_ratio = TRUE, the highest path_gap_ratio (V-add, 2026-10-03; an
#   extra check — it does not replace the fixed three). A pair picked twice is
#   checked once, with both reasons.
lcp_validation_pairs <- function(paths, rules, add_max_ratio = TRUE) {
  d <- sf::st_drop_geometry(paths)
  d <- d[d$path_status == "path", ]
  d <- d[order(d$pair_id), ]
  pick <- function(rule) {
    switch(rule,
      min_nonzero_gap = d$pair_id[which.min(d$gap_km)],
      median_gap      = d$pair_id[which.min(abs(d$gap_km - stats::median(d$gap_km)))],
      max_gap         = d$pair_id[which.max(d$gap_km)],
      max_path_gap_ratio = d$pair_id[which.max(d$path_gap_ratio)],
      stop("lcp_validation_pairs(): unknown rule '", rule, "'.", call. = FALSE))
  }
  all_rules <- c(rules, if (add_max_ratio) "max_path_gap_ratio")
  ids <- vapply(all_rules, pick, integer(1))
  out <- stats::aggregate(rule ~ pair_id,
                          data = data.frame(pair_id = ids, rule = all_rules),
                          FUN = function(x) paste(x, collapse = "+"))
  out[order(match(out$pair_id, ids)), ]
}
