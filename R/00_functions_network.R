# =============================================================================
# 00_functions_network.R
# Reserve network for Stage 2, Week 11 (Decision 19, docs/methodology.md).
# Sourced by scripts/07_connectivity.R; never run standalone.
#
# Method (Decision 19):
#   - Link: every pair with in_network == TRUE on a surface. No cost threshold.
#   - Node: a block of contiguous reserves (the connected sets of the
#     contiguous pairs), or one reserve. node_id = lowest unit_id in the node.
#     The blocks come from geometry: the same on every surface.
#   - Edge: between two nodes, the in-network pair with the lowest cost
#     (a tie: the lowest pair_id). Each edge traces to one pair_id.
#   - Edge weight: the cost-distance (resistance-km). In igraph a weight is a
#     distance: a higher weight is a longer path. It must be above zero.
#   - link_role of an in-network pair:
#       "block"        contiguous pair (it makes a block; not an edge)
#       "within_block" not contiguous, both reserves in one block (not an edge)
#       "edge"         the lowest-cost pair between two nodes
#       "parallel"     another pair between the same two nodes (not an edge)
#   - Set: a connected component of the graph. set_id 1 = the largest set
#     (a tie: the set with the lowest node_id first).
#   - Node metrics (points 5-7):
#       betweenness_raw   weighted shortest-path betweenness, undirected, end
#                         points not counted, no cutoff (igraph::betweenness)
#       betweenness_norm  raw / ((n - 1)(n - 2) / 2), n = nodes in the node's
#                         own set; NA if n is below the minimum set size
#       betweenness_rank  rank of betweenness_norm in the set (1 = highest;
#                         tied values take the lowest rank number)
#       linchpin          rank <= top n AND betweenness_norm > 0
#       cut_node          articulation point (igraph::articulation_points)
#       isolated          degree 0;  pendant = degree 1
#       cheapest_link_rkm lowest edge weight of the node (NA at degree 0);
#       cheapest_link_rank  over all nodes, 1 = the highest value
#     Ranks use values rounded to 10 decimal places, so that two values that
#     are equal by the rule do not get two ranks from floating-point noise.
#   - Threshold scan (point 8): the edges in cost order (a tie: the lowest
#     pair_id); after each edge, the number of sets and the largest set.
#     joins_sets = the edge joined two sets. It chooses no threshold.
#   - Variant comparison (point 10), each variant against the baseline:
#       sets_same           the nodes divide into the same sets
#       rho                 Spearman correlation of betweenness_norm over the
#                           nodes with a value on both surfaces (tied values
#                           take their average rank)
#       linchpin_retention  baseline linchpins that are linchpins on the
#                           variant / baseline linchpins
#       label               "robust" if sets_same AND rho >= the minimum AND
#                           linchpin_retention >= the minimum; else
#                           "sensitive"
#     Descriptive (no limit): edge counts, edges changed, cut-node set, the
#     linchpins lost and gained.
#
# Functions:
#   net_read_paths()      one layer of the paths file -> plain data frame
#   net_build_nodes()     reserves -> nodes (one row per reserve)
#   net_build_links()     one path layer -> link table (one row per
#                         in-network pair, with node ids and link_role)
#   net_build_graph()     link table -> igraph graph (one vertex per node)
#   net_edge_flags()      per edge: is_bridge, in_mst
#   net_sets()            per node: set_id, set_size
#   net_same_partition()  do two groupings of the same items agree?
#   net_check_graph()     construction checks (Decision 19 point 11) -> table
#   net_node_metrics()    per node: sets, degree, betweenness, linchpin,
#                         cut_node, isolated, pendant, cheapest link
#   net_threshold_scan()  per edge, in cost order: sets after the edge
#   net_selftest_metrics() hand-computed test graph for the two functions
#                         above (Decision 19 point 11)
#   net_compare_variant() one variant against the baseline -> one row
#   net_check_metrics()   result checks on one metrics table -> table
#   net_betweenness_identity()  sum of betweenness against the shortest paths
#                         of the graph, by set (does not call betweenness())
#   net_check_weights()   each edge weight = the cost of its pair in the layer
#
# Base R + igraph; sf only to read a layer. No value is hardcoded: the calling
# script passes the NET_* settings from R/00_config.R.
# =============================================================================

# ---- Read one path layer -----------------------------------------------------
# path  : lcp_reserve_network_7755.gpkg
# layer : "baseline", "noghm", "road15" or "road50"
# Returns the attribute table (no geometry), one row per pair.
net_read_paths <- function(path, layer) {
  if (!file.exists(path)) stop("File not found: ", path, call. = FALSE)
  if (!layer %in% sf::st_layers(path)$name) {
    stop("net_read_paths: layer '", layer, "' is not in ", basename(path),
         ". Run the Week-10 STEPs first.", call. = FALSE)
  }
  x <- sf::st_drop_geometry(sf::st_read(path, layer = layer, quiet = TRUE))
  if (!"surface" %in% names(x) || !all(x$surface == layer)) {
    stop("net_read_paths: the surface field of layer '", layer,
         "' does not agree with the layer name.", call. = FALSE)
  }
  as.data.frame(x)
}

# ---- Nodes -------------------------------------------------------------------
# unit_id, unit_name : the network reserves (geometry present), same length
# pairs              : the pair table (from_unit_id, to_unit_id, contiguous)
# groups             : NETWORK_GROUPS (named list of unit_id vectors)
# Returns one row per reserve: unit_id, unit_name, network_group, node_id,
# node_name, block_size (reserves in the node).
net_build_nodes <- function(unit_id, unit_name, pairs, groups) {
  unit_id <- as.integer(unit_id)
  if (length(unit_id) != length(unit_name) || anyNA(unit_id) ||
      anyDuplicated(unit_id)) {
    stop("net_build_nodes: unit_id must be complete and unique, with one ",
         "name each.", call. = FALSE)
  }
  need <- c("from_unit_id", "to_unit_id", "contiguous")
  if (!all(need %in% names(pairs))) {
    stop("net_build_nodes: the pair table needs ", paste(need, collapse = ", "),
         ".", call. = FALSE)
  }
  ord       <- order(unit_id)
  unit_id   <- unit_id[ord]
  unit_name <- as.character(unit_name)[ord]

  cp <- pairs[as.logical(pairs$contiguous), need[1:2], drop = FALSE]
  if (!all(c(cp$from_unit_id, cp$to_unit_id) %in% unit_id)) {
    stop("net_build_nodes: a contiguous pair has a reserve that is not in ",
         "the network.", call. = FALSE)
  }
  g <- igraph::graph_from_data_frame(
    data.frame(from = as.character(cp$from_unit_id),
               to   = as.character(cp$to_unit_id)),
    directed = FALSE, vertices = data.frame(name = as.character(unit_id)))
  memb <- as.integer(igraph::components(g)$membership)  # in unit_id order

  node_id    <- as.integer(stats::ave(unit_id, memb, FUN = min))
  block_size <- as.integer(stats::ave(unit_id, memb, FUN = length))
  # unit_id is sorted, so the names join in unit_id order.
  node_name  <- stats::ave(unit_name, memb,
                           FUN = function(x) paste(x, collapse = " + "))

  grp_ids <- unlist(groups, use.names = FALSE)
  grp     <- rep(names(groups), lengths(groups))[match(unit_id, grp_ids)]
  if (anyNA(grp)) {
    stop("net_build_nodes: reserve(s) with no network group: ",
         paste(unit_id[is.na(grp)], collapse = ", "), call. = FALSE)
  }

  data.frame(unit_id = unit_id, unit_name = unit_name, network_group = grp,
             node_id = node_id, node_name = node_name,
             block_size = block_size, stringsAsFactors = FALSE)
}

# ---- Links -------------------------------------------------------------------
# paths : one layer of lcp_reserve_network_7755.gpkg as a plain data frame
#         (no geometry), one row per pair
# nodes : from net_build_nodes()
# weight_field        : the cost-distance field (NET_EDGE_WEIGHT_FIELD)
# exclude_cross_group : TRUE drops the pairs with cross_group == TRUE before
#                       the edges are chosen (Decision 19 point 9)
# Returns one row per in-network pair, in pair_id order, with from_node_id,
# to_node_id and link_role.
net_build_links <- function(paths, nodes, weight_field,
                            exclude_cross_group = FALSE) {
  need <- c("pair_id", "surface", "from_unit_id", "from_name", "to_unit_id",
            "to_name", "from_group", "to_group", "cross_group", "contiguous",
            "gap_km", "path_km", "in_network", weight_field)
  if (!all(need %in% names(paths))) {
    stop("net_build_links: field(s) missing from the path layer: ",
         paste(setdiff(need, names(paths)), collapse = ", "), call. = FALSE)
  }
  p <- as.data.frame(paths)[, need, drop = FALSE]
  for (f in c("cross_group", "contiguous", "in_network")) {
    p[[f]] <- as.logical(p[[f]])
  }
  if (anyNA(p$in_network) || anyNA(p$contiguous) || anyNA(p$cross_group) ||
      anyDuplicated(p$pair_id)) {
    stop("net_build_links: in_network, contiguous and cross_group must be ",
         "complete, and pair_id unique.", call. = FALSE)
  }

  p <- p[p$in_network, , drop = FALSE]
  if (isTRUE(exclude_cross_group)) p <- p[!p$cross_group, , drop = FALSE]
  p <- p[order(p$pair_id), , drop = FALSE]

  p$from_node_id <- nodes$node_id[match(p$from_unit_id, nodes$unit_id)]
  p$to_node_id   <- nodes$node_id[match(p$to_unit_id, nodes$unit_id)]
  if (anyNA(p$from_node_id) || anyNA(p$to_node_id)) {
    stop("net_build_links: a pair has a reserve that is not a network ",
         "reserve.", call. = FALSE)
  }

  same <- p$from_node_id == p$to_node_id
  if (any(p$contiguous & !same)) {
    stop("net_build_links: a contiguous pair is not inside one node.",
         call. = FALSE)
  }
  role <- rep(NA_character_, nrow(p))
  role[p$contiguous]         <- "block"
  role[same & !p$contiguous] <- "within_block"

  btw <- which(!same)
  w   <- p[[weight_field]]
  if (length(btw) > 0) {
    if (anyNA(w[btw]) || any(w[btw] <= 0)) {
      stop("net_build_links: a pair between two nodes has a weight that is ",
           "NA, zero or negative (pair_id ",
           paste(p$pair_id[btw][is.na(w[btw]) | w[btw] <= 0], collapse = ", "),
           ").", call. = FALSE)
    }
    key <- paste(pmin(p$from_node_id[btw], p$to_node_id[btw]),
                 pmax(p$from_node_id[btw], p$to_node_id[btw]), sep = "-")
    o     <- order(key, w[btw], p$pair_id[btw])   # lowest cost, then pair_id
    first <- !duplicated(key[o])
    role[btw[o]] <- ifelse(first, "edge", "parallel")
  }
  p$link_role <- role
  rownames(p) <- NULL
  p
}

# ---- Graph -------------------------------------------------------------------
# One vertex per node (name = node_id as text; attributes node_id, node_name,
# n_reserves). One edge per link with link_role "edge" (attributes weight,
# pair_id). Undirected. A node with no edge stays in the graph (degree 0).
net_build_graph <- function(links, nodes, weight_field) {
  v <- unique(nodes[, c("node_id", "node_name", "block_size")])
  v <- v[order(v$node_id), , drop = FALSE]
  if (anyDuplicated(v$node_id)) {
    stop("net_build_graph: a node has two names or two sizes.", call. = FALSE)
  }
  e <- links[links$link_role == "edge", , drop = FALSE]
  igraph::graph_from_data_frame(
    data.frame(from    = as.character(e$from_node_id),
               to      = as.character(e$to_node_id),
               weight  = e[[weight_field]],
               pair_id = e$pair_id),
    directed = FALSE,
    vertices = data.frame(name       = as.character(v$node_id),
                          node_id    = v$node_id,
                          node_name  = v$node_name,
                          n_reserves = v$block_size,
                          stringsAsFactors = FALSE))
}

# ---- Edge flags --------------------------------------------------------------
# is_bridge : without the edge, its set divides (igraph::bridges).
# in_mst    : the edge is in the minimum spanning forest by weight. In the
#             threshold scan (Decision 19 point 8) these are the edges that
#             join two sets. Equal weights would make the forest not unique.
net_edge_flags <- function(g) {
  pid <- igraph::E(g)$pair_id
  if (igraph::ecount(g) == 0) {
    return(data.frame(pair_id = integer(0), is_bridge = logical(0),
                      in_mst = logical(0)))
  }
  br <- as.integer(igraph::bridges(g))
  ms <- igraph::mst(g, weights = igraph::E(g)$weight)
  data.frame(pair_id   = pid,
             is_bridge = seq_along(pid) %in% br,
             in_mst    = pid %in% igraph::E(ms)$pair_id)
}

# ---- Sets --------------------------------------------------------------------
# Returns one row per node: node_id, set_id, set_size (nodes), set_reserves.
# set_id 1 = the largest set by nodes; a tie: the set with the lowest node_id.
net_sets <- function(g) {
  cmp     <- igraph::components(g)
  node_id <- as.integer(igraph::V(g)$node_id)
  memb    <- as.integer(cmp$membership)
  size    <- as.integer(cmp$csize[memb])
  lowest  <- stats::ave(node_id, memb, FUN = min)
  n_res   <- as.integer(stats::ave(as.integer(igraph::V(g)$n_reserves), memb,
                                   FUN = sum))
  key <- unique(data.frame(memb = memb, size = size, lowest = lowest))
  key <- key[order(-key$size, key$lowest), , drop = FALSE]
  out <- data.frame(node_id = node_id, set_id = match(memb, key$memb),
                    set_size = size, set_reserves = n_res)
  out[order(out$node_id), , drop = FALSE]
}

# ---- Partition comparison ----------------------------------------------------
# TRUE if two groupings of the same items (same order) put the same items
# together. The group labels can be different.
net_same_partition <- function(a, b) {
  if (length(a) != length(b)) return(FALSE)
  if (length(a) == 0) return(TRUE)
  tab <- unique(data.frame(a = a, b = b))
  !anyDuplicated(tab$a) && !anyDuplicated(tab$b)
}

# ---- Construction checks (Decision 19 point 11) ------------------------------
# Returns a table: check, value, pass. The calling script stops on any FALSE.
net_check_graph <- function(g, nodes, links, expected_reserves,
                            expected_nodes) {
  e_pid  <- igraph::E(g)$pair_id
  e_w    <- igraph::E(g)$weight
  l_edge <- links$pair_id[links$link_role == "edge"]
  sets   <- net_sets(g)
  set1   <- sets[!duplicated(sets$set_id), , drop = FALSE]
  chk <- function(check, value, pass) {
    data.frame(check = check, value = as.character(value), pass = isTRUE(pass),
               stringsAsFactors = FALSE)
  }
  rbind(
    chk("each reserve in one node only",
        sprintf("%d reserves, %d duplicated, %d with no node", nrow(nodes),
                sum(duplicated(nodes$unit_id)), sum(is.na(nodes$node_id))),
        !anyDuplicated(nodes$unit_id) && !anyNA(nodes$node_id)),
    chk("reserve count as expected", nrow(nodes),
        nrow(nodes) == expected_reserves),
    chk("node count as expected", length(unique(nodes$node_id)),
        length(unique(nodes$node_id)) == expected_nodes),
    chk("graph vertices = nodes", igraph::vcount(g),
        setequal(as.integer(igraph::V(g)$node_id), nodes$node_id) &&
          igraph::vcount(g) == length(unique(nodes$node_id))),
    chk("no loop, no duplicate edge", igraph::ecount(g), igraph::is_simple(g)),
    chk("edge weights above zero, none NA",
        if (length(e_w) > 0) sprintf("min %.3f", min(e_w)) else "no edge",
        !anyNA(e_w) && all(e_w > 0)),
    chk("each edge traces to one pair_id",
        sprintf("%d edges, %d pair_ids", igraph::ecount(g),
                length(unique(e_pid))),
        !anyNA(e_pid) && !anyDuplicated(e_pid) && setequal(e_pid, l_edge) &&
          length(e_pid) == length(l_edge)),
    chk("each in-network pair has a link_role", sum(is.na(links$link_role)),
        !anyNA(links$link_role)),
    chk("set sizes add up to the node count", sum(set1$set_size),
        sum(set1$set_size) == igraph::vcount(g)),
    chk("set reserves add up to the reserve count", sum(set1$set_reserves),
        sum(set1$set_reserves) == nrow(nodes))
  )
}

# ---- Node metrics (Decision 19 points 4-7) -----------------------------------
# g                  : from net_build_graph()
# norm_min_set_nodes : NET_NORM_MIN_SET_NODES (must be >= 3: below 3 the
#                      divisor is zero)
# linchpin_top_n     : NET_LINCHPIN_TOP_N
# Returns one row per node, in node_id order.
net_node_metrics <- function(g, norm_min_set_nodes, linchpin_top_n) {
  if (!is.numeric(norm_min_set_nodes) || norm_min_set_nodes < 3) {
    stop("net_node_metrics: norm_min_set_nodes must be 3 or more.",
         call. = FALSE)
  }
  sets <- net_sets(g)                                    # node_id order
  k    <- match(sets$node_id, as.integer(igraph::V(g)$node_id))
  w    <- igraph::E(g)$weight
  m    <- igraph::ecount(g)
  if (m > 0 && (anyNA(w) || any(w <= 0))) {
    stop("net_node_metrics: an edge weight is NA, zero or negative.",
         call. = FALSE)
  }

  deg <- as.integer(igraph::degree(g))[k]
  btw <- if (m > 0) {
    as.numeric(igraph::betweenness(g, directed = FALSE, weights = w,
                                   normalized = FALSE))
  } else {
    rep(0, igraph::vcount(g))
  }
  btw <- btw[k]

  n    <- sets$set_size
  norm <- ifelse(n >= norm_min_set_nodes, btw / ((n - 1) * (n - 2) / 2),
                 NA_real_)
  rank_desc <- function(x) {
    as.integer(rank(-round(x, 10), ties.method = "min", na.last = "keep"))
  }
  btw_rank <- as.integer(stats::ave(norm, sets$set_id, FUN = rank_desc))
  linchpin <- !is.na(btw_rank) & btw_rank <= linchpin_top_n &
    round(norm, 10) > 0

  cut_idx  <- as.integer(igraph::articulation_points(g))  # vertex indices
  cut_node <- k %in% cut_idx

  cheapest <- rep(NA_real_, igraph::vcount(g))
  if (m > 0) {
    el  <- igraph::ends(g, igraph::E(g), names = FALSE)
    low <- tapply(c(w, w), c(el[, 1], el[, 2]), min)
    cheapest[as.integer(names(low))] <- as.numeric(low)
  }
  cheapest <- cheapest[k]

  data.frame(node_id            = sets$node_id,
             set_id             = sets$set_id,
             set_size           = sets$set_size,
             set_reserves       = sets$set_reserves,
             degree             = deg,
             betweenness_raw    = btw,
             betweenness_norm   = norm,
             betweenness_rank   = btw_rank,
             linchpin           = linchpin,
             cut_node           = cut_node,
             isolated           = deg == 0L,
             pendant            = deg == 1L,
             cheapest_link_rkm  = cheapest,
             cheapest_link_rank = rank_desc(cheapest))
}

# ---- Threshold scan (Decision 19 point 8) ------------------------------------
# Returns one row per edge, in cost order: step, pair_id, threshold_rkm (the
# weight of the edge), n_sets and largest_set_nodes with the edges up to this
# one in the graph, and joins_sets. Descriptive: no threshold is chosen.
net_threshold_scan <- function(g) {
  m <- igraph::ecount(g)
  if (m == 0) {
    return(data.frame(step = integer(0), pair_id = integer(0),
                      threshold_rkm = numeric(0), n_sets = integer(0),
                      largest_set_nodes = integer(0), joins_sets = logical(0)))
  }
  w   <- igraph::E(g)$weight
  pid <- igraph::E(g)$pair_id
  o   <- order(w, pid)
  n_sets  <- integer(m)
  largest <- integer(m)
  for (i in seq_len(m)) {
    cmp <- igraph::components(
      igraph::subgraph.edges(g, o[seq_len(i)], delete.vertices = FALSE))
    n_sets[i]  <- cmp$no
    largest[i] <- max(cmp$csize)
  }
  data.frame(step = seq_len(m), pair_id = pid[o], threshold_rkm = w[o],
             n_sets = n_sets, largest_set_nodes = largest,
             joins_sets = n_sets < c(igraph::vcount(g), n_sets[-m]))
}

# ---- Self-test on a hand-computed graph (Decision 19 point 11) ----------------
# 11 nodes, 4 sets:
#   path      1 - 2 - 3 - 4 - 5     weights 1, 2, 3, 4   (pair_id 1-4)
#   triangle  6 - 7 (1), 7 - 8 (1), 6 - 8 (5)            (pair_id 5-7)
#             the shortest way 6 -> 8 goes through 7 (2 < 5): this tests that
#             a weight is a distance. Without weights, node 7 would get 0.
#   pair      9 - 10 (2)                                 (pair_id 8)
#   single    11
# The test uses minimum set size 3 and top n 3 (its hand values need them); it
# does not read the config. Returns: case, expected, engine, pass.
net_selftest_metrics <- function(tol = 1e-9) {
  e <- data.frame(from = c(1, 2, 3, 4, 6, 7, 6, 9),
                  to   = c(2, 3, 4, 5, 7, 8, 8, 10),
                  weight  = c(1, 2, 3, 4, 1, 1, 5, 2),
                  pair_id = 1:8)
  g <- igraph::graph_from_data_frame(
    data.frame(from = as.character(e$from), to = as.character(e$to),
               weight = e$weight, pair_id = e$pair_id),
    directed = FALSE,
    vertices = data.frame(name = as.character(1:11), node_id = 1:11,
                          node_name = paste0("N", 1:11), n_reserves = 1L,
                          stringsAsFactors = FALSE))
  mt <- net_node_metrics(g, norm_min_set_nodes = 3, linchpin_top_n = 3)
  sc <- net_threshold_scan(g)
  fl <- net_edge_flags(g)
  fl <- fl[order(fl$pair_id), ]

  exp <- list(
    set_id             = c(1, 1, 1, 1, 1, 2, 2, 2, 3, 3, 4),
    degree             = c(1, 2, 2, 2, 1, 2, 2, 2, 1, 1, 0),
    betweenness_raw    = c(0, 3, 4, 3, 0, 0, 1, 0, 0, 0, 0),
    betweenness_norm   = c(0, 1 / 2, 2 / 3, 1 / 2, 0, 0, 1, 0, NA, NA, NA),
    betweenness_rank   = c(4, 2, 1, 2, 4, 2, 1, 2, NA, NA, NA),
    linchpin           = c(FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE, FALSE,
                           FALSE, FALSE, FALSE),
    cut_node           = c(FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE,
                           FALSE, FALSE, FALSE),
    isolated           = c(rep(FALSE, 10), TRUE),
    pendant            = c(TRUE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE,
                           TRUE, TRUE, FALSE),
    cheapest_link_rkm  = c(1, 1, 2, 3, 4, 1, 1, 1, 2, 2, NA),
    cheapest_link_rank = c(6, 6, 3, 2, 1, 6, 6, 6, 3, 3, NA)
  )
  same <- function(a, b) {
    length(a) == length(b) && identical(is.na(a), is.na(b)) &&
      all(abs(as.numeric(a) - as.numeric(b))[!is.na(a)] <= tol)
  }
  show <- function(x) paste(ifelse(is.na(x), "NA", format(round(as.numeric(x), 3))),
                            collapse = " ")
  out <- do.call(rbind, lapply(names(exp), function(f) {
    data.frame(case = f, expected = show(exp[[f]]), engine = show(mt[[f]]),
               pass = same(exp[[f]], mt[[f]]), stringsAsFactors = FALSE)
  }))

  exp_sc <- list(
    scan_pair_id      = c(1, 5, 6, 2, 8, 3, 4, 7),
    scan_n_sets       = c(10, 9, 8, 7, 6, 5, 4, 4),
    scan_largest_set  = c(2, 2, 3, 3, 3, 4, 5, 5),
    scan_joins_sets   = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE),
    edge_is_bridge    = c(TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, TRUE),
    edge_in_mst       = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE)
  )
  got_sc <- list(scan_pair_id = sc$pair_id, scan_n_sets = sc$n_sets,
                 scan_largest_set = sc$largest_set_nodes,
                 scan_joins_sets = sc$joins_sets,
                 edge_is_bridge = fl$is_bridge, edge_in_mst = fl$in_mst)
  out2 <- do.call(rbind, lapply(names(exp_sc), function(f) {
    data.frame(case = f, expected = show(exp_sc[[f]]), engine = show(got_sc[[f]]),
               pass = same(exp_sc[[f]], got_sc[[f]]), stringsAsFactors = FALSE)
  }))
  rbind(out, out2)
}

# ---- Variant comparison (Decision 19 point 10) -------------------------------
# links_base, links_var : from net_build_links() (baseline, variant)
# met_base, met_var     : from net_node_metrics() (same nodes, node_id order)
# node_names            : data frame node_id, node_name (for the name lists)
# min_rho, min_retention: NET_COMPARE_ROBUST_MIN_RHO, _MIN_RETENTION
# tol                   : so that 2 of 3 retained counts as >= 2/3
# Returns one row. n_edges_changed = node pairs that have an edge on one
# surface only, or an edge that traces to a different pair_id.
net_compare_variant <- function(links_base, met_base, links_var, met_var,
                                node_names, min_rho, min_retention,
                                tol = 1e-9) {
  if (!identical(met_base$node_id, met_var$node_id)) {
    stop("net_compare_variant: the two surfaces do not have the same nodes.",
         call. = FALSE)
  }
  edge_key <- function(l) {
    e <- l[l$link_role == "edge", , drop = FALSE]
    stats::setNames(e$pair_id,
                    paste(pmin(e$from_node_id, e$to_node_id),
                          pmax(e$from_node_id, e$to_node_id), sep = "-"))
  }
  eb <- edge_key(links_base)
  ev <- edge_key(links_var)
  both      <- intersect(names(eb), names(ev))
  n_changed <- length(setdiff(names(eb), names(ev))) +
    length(setdiff(names(ev), names(eb))) + sum(eb[both] != ev[both])

  sets_same <- net_same_partition(met_base$set_id, met_var$set_id)

  ok  <- !is.na(met_base$betweenness_norm) & !is.na(met_var$betweenness_norm)
  rho <- if (sum(ok) >= 3 &&
             stats::sd(met_base$betweenness_norm[ok]) > 0 &&
             stats::sd(met_var$betweenness_norm[ok]) > 0) {
    stats::cor(met_base$betweenness_norm[ok], met_var$betweenness_norm[ok],
               method = "spearman")
  } else {
    NA_real_
  }

  lb <- met_base$linchpin
  lv <- met_var$linchpin
  n_base     <- sum(lb)
  n_retained <- sum(lb & lv)
  retention  <- if (n_base > 0) n_retained / n_base else NA_real_

  nm <- node_names$node_name[match(met_base$node_id, node_names$node_id)]
  name_list <- function(i) if (any(i)) paste(nm[i], collapse = "; ") else ""

  robust <- isTRUE(sets_same) && !is.na(rho) && rho >= min_rho &&
    !is.na(retention) && retention >= min_retention - tol

  data.frame(n_edges_baseline     = length(eb),
             n_edges_variant      = length(ev),
             n_edges_changed      = n_changed,
             sets_same            = sets_same,
             n_nodes_compared     = sum(ok),
             rho                  = rho,
             n_linchpins_baseline = n_base,
             n_linchpins_retained = n_retained,
             linchpin_retention   = retention,
             cut_nodes_same       = identical(met_base$cut_node, met_var$cut_node),
             linchpins_lost       = name_list(lb & !lv),
             linchpins_gained     = name_list(lv & !lb),
             label                = if (robust) "robust" else "sensitive",
             stringsAsFactors = FALSE)
}

# ---- Result checks on one metrics table (STEP 11.4) ---------------------------
# met : from net_node_metrics(). The linchpin rule is written here a second
# way (a count of the nodes with a higher value), not copied from the function.
# Returns a table: check, value, pass.
net_check_metrics <- function(met, norm_min_set_nodes, linchpin_top_n) {
  chk <- function(check, value, pass) {
    data.frame(check = check, value = as.character(value), pass = isTRUE(pass),
               stringsAsFactors = FALSE)
  }
  v <- round(met$betweenness_norm, 10)
  n_higher <- vapply(seq_len(nrow(met)), function(i) {
    if (is.na(v[i])) return(NA_integer_)
    sum(v[met$set_id == met$set_id[i]] > v[i], na.rm = TRUE)
  }, integer(1))
  lp_rule <- !is.na(v) & v > 0 & n_higher < linchpin_top_n
  low_deg <- met$degree <= 1L
  top_cl  <- which(met$cheapest_link_rank == 1L)
  rbind(
    chk("betweenness_norm is 0 to 1; NA only in a set below the minimum size",
        sprintf("range %s, %d NA",
                if (all(is.na(v))) "none" else
                  paste(format(range(v, na.rm = TRUE), digits = 4),
                        collapse = " to "), sum(is.na(v))),
        identical(is.na(v), met$set_size < norm_min_set_nodes) &&
          all(v >= 0 & v <= 1 + 1e-9, na.rm = TRUE)),
    chk("linchpin = fewer than top-n nodes of the set are higher, value > 0",
        sprintf("%d linchpins", sum(met$linchpin)),
        identical(met$linchpin, lp_rule)),
    chk("isolated = degree 0 = a set of one node", sum(met$isolated),
        identical(met$isolated, met$degree == 0L) &&
          identical(met$isolated, met$set_size == 1L)),
    chk("pendant = degree 1", sum(met$pendant),
        identical(met$pendant, met$degree == 1L)),
    chk("a cut node has degree 2 or more", sum(met$cut_node),
        all(met$degree[met$cut_node] >= 2L)),
    chk("betweenness_raw is 0 at degree 0 and 1", sum(low_deg),
        all(met$betweenness_raw[low_deg] == 0)),
    chk("cheapest link: NA only at degree 0; rank 1 = the highest value",
        sprintf("%d NA", sum(is.na(met$cheapest_link_rkm))),
        identical(is.na(met$cheapest_link_rkm), met$isolated) &&
          (all(is.na(met$cheapest_link_rkm)) ||
             (length(top_cl) >= 1 &&
                all(met$cheapest_link_rkm[top_cl] ==
                      max(met$cheapest_link_rkm, na.rm = TRUE)))))
  )
}

# ---- Betweenness identity (STEP 11.4) -----------------------------------------
# In a set, the sum of betweenness over the nodes = the sum, over the node
# pairs of the set, of the number of nodes between the two ends on their
# shortest path (the mean, if two shortest paths are equal). This function
# gets the right side from igraph::all_shortest_paths(); it does not call
# betweenness(). Returns one row per set: set_id, sum_betweenness,
# sum_path_nodes, pass.
net_betweenness_identity <- function(g, met, tol = 1e-6) {
  n   <- igraph::vcount(g)
  w   <- if (igraph::ecount(g) > 0) igraph::E(g)$weight else NULL
  k   <- match(as.integer(igraph::V(g)$node_id), met$node_id)
  if (anyNA(k)) {
    stop("net_betweenness_identity: a graph node is not in the metrics.",
         call. = FALSE)
  }
  set <- met$set_id[k]
  between <- numeric(n)
  for (i in seq_len(n)) {
    to <- which(set == set[i] & seq_len(n) > i)
    if (length(to) == 0) next
    r  <- igraph::all_shortest_paths(g, from = i, to = to, weights = w)
    vp <- if (!is.null(r$vpaths)) r$vpaths else r$res   # igraph 2.x / 1.x
    end <- vapply(vp, function(p) as.integer(p)[length(p)], integer(1))
    len <- vapply(vp, function(p) length(p) - 2L, integer(1))
    if (!setequal(unique(end), to)) {
      stop("net_betweenness_identity: a node of the set has no path.",
           call. = FALSE)
    }
    between[i] <- sum(tapply(len, end, mean))
  }
  sum_b <- tapply(met$betweenness_raw[k], set, sum)
  sum_p <- tapply(between, set, sum)
  data.frame(set_id          = as.integer(names(sum_b)),
             sum_betweenness = as.numeric(sum_b),
             sum_path_nodes  = as.numeric(sum_p[names(sum_b)]),
             pass            = abs(as.numeric(sum_b) -
                                     as.numeric(sum_p[names(sum_b)])) <= tol)
}

# ---- Edge weights against the layer (STEP 11.4) --------------------------------
# Each edge weight must be the cost of its pair_id in the path layer.
# Returns a one-row table: check, value, pass.
net_check_weights <- function(g, paths, weight_field) {
  pid <- igraph::E(g)$pair_id
  ref <- paths[[weight_field]][match(pid, paths$pair_id)]
  data.frame(check = "each edge weight = the cost of its pair_id in the layer",
             value = sprintf("%d edges", length(pid)),
             pass  = !anyNA(ref) && identical(as.numeric(igraph::E(g)$weight),
                                              as.numeric(ref)),
             stringsAsFactors = FALSE)
}
