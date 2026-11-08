# =============================================================================
# 00_functions_gistar.R
# The Getis-Ord Gi* of Decision 26 (2026-11-07; with Amendment 1) for Stage 3,
# Week 16. scripts/09_model_suitability.R sources this file (process choice
# f1 of task 16.2). The settings are the GISTAR_* values of R/00_config.R; no
# value of the analysis is written here as a literal.
#
# The rule in short (Decision 26 points 3 to 6; Amendment 1):
#   cells  : the 0.2 degree model cells; the value of a cell is 1 if it holds
#            one or more records of the input, else 0
#   window : the cell itself and its neighbours. A neighbour is a cell with a
#            great-circle distance (haversine, sphere of radius
#            GISTAR_EARTH_RADIUS_KM) of GISTAR_BAND_KM or less between the
#            cell centres ((ix + 0.5) x deg, (iy + 0.5) x deg). "queen" (a QA
#            band) = the 8 cells around a cell, by the cell index
#   K_i    : the number of cells with the value 1 in the window of cell i
#   G*_i   : (K_i - xbar n_i) / (S sqrt((n n_i - n_i^2) / (n - 1))); n = the
#            model cells, n_i = the cells in the window, xbar and S the mean
#            and the standard deviation (divisor n) of the values
#   p      : exact under random relabelling: K ~ hypergeometric(n cells, M
#            cells with 1, n_i cells drawn); p_hot = P(K >= K_i), p_cold =
#            P(K <= K_i), p_two = min(1, 2 x min(p_hot, p_cold))
#   class  : few_neighbours if the cell has fewer than GISTAR_MIN_NEIGHBOURS
#            neighbours (its value stays in the windows of the other cells);
#            otherwise the Benjamini-Hochberg adjusted p_two over the cells
#            with a class: hot (<= q and K_i above xbar n_i), cold (<= q and
#            K_i below it), not_significant
#
# Task 16.3 (2026-11-07): STEP 16.1.
#   gistar_check_config()    the GISTAR_* settings (a named list of checks)
#   gistar_dist_km()         the great-circle distance (haversine)
#   gistar_centres()         the centre of each cell in longitude and latitude
#   gistar_window()          the index window that holds each neighbour
#   gistar_neighbours()      the neighbour pairs at a band, or "queen"
#   gistar_stat()            n_i, K_i, G*_i and the exact p of each cell
#   gistar_classify()        the adjusted p and the class of each cell
#   gistar_run()             gistar_stat() and gistar_classify() together
#   gistar_record_cells()    the 0.2 degree cell of each record from its GBIF
#                            coordinates (process choice r2 of task 16.2)
#   gistar_landscape_counts() the hot cells by landscape complex (rule L1)
#   gistar_same_share()      the share of the cells of a class that keep it
#   gistar_layer_checks()    the checks of a Gi* layer (process choice n1)
#   gistar_self_test()       the hand-made case of STEP 16.1 (h1)
#
# Uses base R and stats; gistar_record_cells() also uses occ_id_chr(),
# occ_num() and occ_cell02() (R/00_functions_occ.R) and sdm_cell_index() and
# sdm_cell_id() (R/00_functions_sdm.R).
#
# SENSITIVE DATA: these functions return TRUE/FALSE, counts, statistics and
# cell ids. None of them prints a coordinate, a cell corner or a cell id. A
# layer with a cell id goes to data/processed/ only (gitignored).
# =============================================================================

# The fields of a Gi* layer, in this order (process choice n1 of task 16.2).
GISTAR_LAYER_FIELDS <- c("id", "value", "n_nb", "n_win", "k", "gistar",
                         "p_hot", "p_cold", "p_two", "p_adj", "class")

# ---- The settings of Decision 26 ------------------------------------------------
# Returns a named list of TRUE/FALSE (for sdm_run_guards()).
gistar_check_config <- function() {
  is_num1 <- function(x) is.numeric(x) && length(x) == 1L && !is.na(x)
  runs_ok <- is.data.frame(GISTAR_RUNS) &&
    identical(GISTAR_RUNS$gistar, c("effort_inat", "tiger_obscured",
                                    "effort_all", "tiger_5km")) &&
    identical(GISTAR_RUNS$compare, c("tiger_obscured", "effort_inat",
                                     "tiger_5km", "effort_all")) &&
    identical(GISTAR_RUNS$tiger, c(FALSE, TRUE, FALSE, TRUE))
  list(
    "GISTAR_RUNS must hold the four Gi* of Decision 26 point 2, with their pairs" =
      runs_ok,
    "GISTAR_UNCERT_SETS must be the 5 km sets (KDE_UNCERT_SETS)" =
      identical(GISTAR_UNCERT_SETS, KDE_UNCERT_SETS),
    "GISTAR_CELLS must be model and GISTAR_VALUE binary (c1)" =
      identical(GISTAR_CELLS, "model") && identical(GISTAR_VALUE, "binary"),
    "GISTAR_BAND_KM must be one number above 0 (d1)" =
      is_num1(GISTAR_BAND_KM) && GISTAR_BAND_KM > 0,
    "GISTAR_SELF must be TRUE (Gi*, the cell in its own window)" =
      identical(GISTAR_SELF, TRUE),
    "GISTAR_MIN_NEIGHBOURS must be a whole number of 1 or more (k1)" =
      is_num1(GISTAR_MIN_NEIGHBOURS) &&
      GISTAR_MIN_NEIGHBOURS == round(GISTAR_MIN_NEIGHBOURS) &&
      GISTAR_MIN_NEIGHBOURS >= 1,
    "GISTAR_QA_BANDS must be queen and one band in km (q2)" =
      is.list(GISTAR_QA_BANDS) &&
      identical(names(GISTAR_QA_BANDS), c("queen", "band75_km")) &&
      identical(GISTAR_QA_BANDS$queen, "queen") &&
      is_num1(GISTAR_QA_BANDS$band75_km) &&
      GISTAR_QA_BANDS$band75_km > GISTAR_BAND_KM,
    "GISTAR_TEST must be exact_relabel and GISTAR_P_ADJUST BH (e1, m1)" =
      identical(GISTAR_TEST, "exact_relabel") &&
      identical(GISTAR_P_ADJUST, "BH"),
    "GISTAR_FDR_Q must be a number in (0, 1) (m1)" =
      is_num1(GISTAR_FDR_Q) && GISTAR_FDR_Q > 0 && GISTAR_FDR_Q < 1,
    "GISTAR_CLASSES must be hot, cold, not_significant, few_neighbours" =
      identical(GISTAR_CLASSES, c("hot", "cold", "not_significant",
                                  "few_neighbours")),
    "GISTAR_TIGER_STATEMENT must be s1 (obscured) and s2 (5 km) (S-a)" =
      identical(GISTAR_TIGER_STATEMENT,
                c(tiger_obscured = "s1", tiger_5km = "s2")),
    "GISTAR_LANDSCAPE_RULE must be centre_any (L1)" =
      identical(GISTAR_LANDSCAPE_RULE, "centre_any"),
    "GISTAR_YEARS must be BASELINE_YEAR to CURRENT_YEAR (w1)" =
      identical(as.integer(GISTAR_YEARS),
                as.integer(c(BASELINE_YEAR, CURRENT_YEAR))),
    "GISTAR_CODE must be own (g1)" = identical(GISTAR_CODE, "own"),
    "GISTAR_DIST must be sphere (Amendment 1)" =
      identical(GISTAR_DIST, "sphere"),
    "GISTAR_EARTH_RADIUS_KM must be (2a + b) / 3 of WGS 84" =
      is_num1(GISTAR_EARTH_RADIUS_KM) &&
      abs(GISTAR_EARTH_RADIUS_KM - (2 * 6378.137 + 6356.752314245) / 3) < 1e-3,
    "GISTAR_CENTRE must be lonlat_index (p1)" =
      identical(GISTAR_CENTRE, "lonlat_index"),
    "GISTAR_LAYER_FILES must name one CSV for each Gi* (n1)" =
      identical(names(GISTAR_LAYER_FILES), GISTAR_RUNS$gistar) &&
      all(grepl("^hot_[a-z0-9_]+_cell02\\.csv$", GISTAR_LAYER_FILES)),
    "the table number and slugs must be 18, gistar and gistar_qa (t1)" =
      identical(as.integer(GISTAR_TABLE_NN), 18L) &&
      identical(GISTAR_TABLE_SLUG, "gistar") &&
      identical(GISTAR_QA_TABLE_SLUG, "gistar_qa"),
    "SDM_GISTAR_PUBLISH_TIGER must be FALSE (Decision 23 point 8)" =
      identical(SDM_GISTAR_PUBLISH_TIGER, FALSE)
  )
}

# ---- Distance and centres (Amendment 1; process choice p1) ------------------------
# The great-circle distance in km (the haversine formula) on a sphere of
# radius r_km. Longitude and latitude in degrees; the vectors are recycled.
gistar_dist_km <- function(lon1, lat1, lon2, lat2,
                           r_km = GISTAR_EARTH_RADIUS_KM) {
  rad <- pi / 180
  p1 <- lat1 * rad
  p2 <- lat2 * rad
  a <- sin((p2 - p1) / 2)^2 +
    cos(p1) * cos(p2) * sin((lon2 - lon1) * rad / 2)^2
  2 * r_km * asin(pmin(1, sqrt(a)))
}

# The centre of each cell (ix, iy) in longitude and latitude (p1).
gistar_centres <- function(ix, iy, deg = SDM_GRAIN_DEG) {
  data.frame(lon = (ix + 0.5) * deg, lat = (iy + 0.5) * deg)
}

# The index window that holds each neighbour within band_km, for cells at
# the latitudes `lat` (the cell centres). Returns c(ox, oy): each neighbour
# has |dx| <= ox and |dy| <= oy (dx, dy: the index differences).
#   oy : with |dy| >= oy + 1 the distance is (oy + 1) x the north-south step
#        or more (an arc of a meridian is the shortest path between two
#        latitudes), which is above band_km
#   ox : the smallest value such that the pair (ox + 1, dy) is beyond the
#        band for each |dy| <= oy and each latitude; the distance increases
#        with |dx| at fixed latitudes, so each pair with |dx| > ox is beyond
#        the band too
gistar_window <- function(lat, band_km, deg = SDM_GRAIN_DEG,
                          r_km = GISTAR_EARTH_RADIUS_KM, max_off = 20L) {
  if (!is.numeric(band_km) || length(band_km) != 1L || is.na(band_km) ||
      band_km <= 0) {
    stop("gistar_window(): band_km must be one number above 0.", call. = FALSE)
  }
  step_ns <- r_km * deg * pi / 180
  oy <- as.integer(floor(band_km / step_ns))
  lat_u <- sort(unique(lat))
  for (ox in 0:max_off) {
    far <- vapply(-oy:oy, function(dy) {
      all(gistar_dist_km(0, lat_u, (ox + 1) * deg, lat_u + dy * deg,
                         r_km) > band_km)
    }, logical(1))
    if (all(far)) return(c(ox = as.integer(ox), oy = oy))
  }
  stop("gistar_window(): no window of ", max_off, " cells or fewer holds ",
       "the band of ", band_km, " km.", call. = FALSE)
}

# ---- Neighbours (Decision 26 points 4 and 5) -----------------------------------------
# ix, iy  : the integer index of each cell (one row per cell; no repeat)
# rule    : "band" (a neighbour within band_km, Amendment 1) or "queen" (the
#           8 cells around a cell, by the index)
# Returns a list: from, to (the rows of the pairs; each pair in both
# directions; the cell itself is not a pair), d_km (NA for queen), n_nb (the
# neighbours of each cell), window (ox, oy).
gistar_neighbours <- function(ix, iy, rule = c("band", "queen"),
                              band_km = NULL, deg = SDM_GRAIN_DEG,
                              r_km = GISTAR_EARTH_RADIUS_KM) {
  rule <- match.arg(rule)
  n <- length(ix)
  if (n == 0L || length(iy) != n || anyNA(ix) || anyNA(iy) ||
      any(ix != round(ix)) || any(iy != round(iy))) {
    stop("gistar_neighbours(): ix and iy must be whole numbers of one length.",
         call. = FALSE)
  }
  ctr <- gistar_centres(ix, iy, deg)
  win <- if (rule == "queen") c(ox = 1L, oy = 1L) else
    gistar_window(ctr$lat, band_km, deg, r_km)
  # A key for each cell, with room for the offsets on each side.
  kx <- ix - min(ix) + win[["ox"]]
  ky <- iy - min(iy) + win[["oy"]]
  base <- max(kx) + win[["ox"]] + 1
  key <- ky * base + kx
  if (anyDuplicated(key)) {
    stop("gistar_neighbours(): a cell index is there two times.", call. = FALSE)
  }
  offs <- expand.grid(dx = -win[["ox"]]:win[["ox"]],
                      dy = -win[["oy"]]:win[["oy"]])
  offs <- offs[!(offs$dx == 0 & offs$dy == 0), ]
  from <- list(); to <- list(); dk <- list()
  for (r in seq_len(nrow(offs))) {
    j <- match((ky + offs$dy[r]) * base + (kx + offs$dx[r]), key)
    i <- which(!is.na(j))
    if (length(i) == 0) next
    j <- j[i]
    d <- if (rule == "band") {
      gistar_dist_km(ctr$lon[i], ctr$lat[i], ctr$lon[j], ctr$lat[j], r_km)
    } else rep(NA_real_, length(i))
    keep <- if (rule == "band") d <= band_km else rep(TRUE, length(i))
    from[[length(from) + 1L]] <- i[keep]
    to[[length(to) + 1L]]     <- j[keep]
    dk[[length(dk) + 1L]]     <- d[keep]
  }
  from <- as.integer(unlist(from)); to <- as.integer(unlist(to))
  list(from = from, to = to, d_km = unlist(dk),
       n_nb = tabulate(from, nbins = n), window = win, rule = rule,
       band_km = if (rule == "band") band_km else NA_real_)
}

# ---- The statistic and the exact p (Decision 26 point 6) ------------------------------
# x  : the value of each cell, 0 or 1 (the order of the cells of nb)
# nb : the result of gistar_neighbours()
# Returns a data frame, one row per cell: value, n_nb, n_win, k, gistar,
# p_hot, p_cold, p_two.
gistar_stat <- function(x, nb) {
  n <- length(x)
  if (n != length(nb$n_nb)) {
    stop("gistar_stat(): x and the neighbours differ in length.",
         call. = FALSE)
  }
  if (anyNA(x) || !all(x %in% c(0, 1))) {
    stop("gistar_stat(): each value must be 0 or 1 (Decision 26 c1).",
         call. = FALSE)
  }
  m <- sum(x)
  if (m == 0 || m == n) {
    stop("gistar_stat(): all values are equal (", m, " of ", n,
         " cells are 1); Gi* has no variance.", call. = FALSE)
  }
  n_win <- nb$n_nb + 1L
  if (any(n_win >= n)) {
    stop("gistar_stat(): a window holds all cells.", call. = FALSE)
  }
  k <- as.integer(x + tabulate(nb$from[x[nb$to] == 1], nbins = n))
  xbar <- m / n
  s <- sqrt(mean(x^2) - xbar^2)
  g <- (k - xbar * n_win) / (s * sqrt((n * n_win - n_win^2) / (n - 1)))
  p_hot  <- stats::phyper(k - 1, m, n - m, n_win, lower.tail = FALSE)
  p_cold <- stats::phyper(k, m, n - m, n_win)
  data.frame(value = as.integer(x), n_nb = as.integer(nb$n_nb),
             n_win = as.integer(n_win), k = k, gistar = g, p_hot = p_hot,
             p_cold = p_cold, p_two = pmin(1, 2 * pmin(p_hot, p_cold)))
}

# The adjusted p and the class (Decision 26 point 6; k1 of point 4).
#   st     : the result of gistar_stat()
#   min_nb : GISTAR_MIN_NEIGHBOURS; q : GISTAR_FDR_Q; method : GISTAR_P_ADJUST
# Returns st with p_adj (NA for few_neighbours) and class.
gistar_classify <- function(st, min_nb = GISTAR_MIN_NEIGHBOURS,
                            q = GISTAR_FDR_Q, method = GISTAR_P_ADJUST) {
  classed <- st$n_nb >= min_nb
  p_adj <- rep(NA_real_, nrow(st))
  if (any(classed)) {
    p_adj[classed] <- stats::p.adjust(st$p_two[classed], method = method)
  }
  e <- mean(st$value) * st$n_win
  cls <- rep("few_neighbours", nrow(st))
  cls[classed] <- "not_significant"
  sig <- classed & p_adj <= q
  cls[sig & st$k > e] <- "hot"
  cls[sig & st$k < e] <- "cold"
  st$p_adj <- p_adj
  st$class <- cls
  st
}

gistar_run <- function(x, nb, min_nb = GISTAR_MIN_NEIGHBOURS,
                       q = GISTAR_FDR_Q, method = GISTAR_P_ADJUST) {
  gistar_classify(gistar_stat(x, nb), min_nb, q, method)
}

# ---- The 0.2 degree cell of a record (process choice r2 of task 16.2) --------------
# gbif_id : the gbifID of each record of a clean layer
# z       : the fields gbifID, decimalLatitude, decimalLongitude of the GBIF
#           download (occ_read_fields(); all text)
# Returns list(id = the 0.2 degree cell id of each record (NA if not found),
# n_missing = records with no row or no coordinates in z, n_repeat = records
# whose gbifID is in z two or more times). The cell is occ_cell02() of the
# GBIF coordinates: the rule of Decision 21 point 4 and of background part (b).
gistar_record_cells <- function(gbif_id, z, deg = SDM_GRAIN_DEG) {
  zid <- occ_id_chr(z$gbifID)
  rid <- occ_id_chr(gbif_id)
  zi  <- match(rid, zid)
  n_repeat <- sum(rid %in% zid[duplicated(zid)])
  lon <- occ_num(z$decimalLongitude[zi], "decimalLongitude")
  lat <- occ_num(z$decimalLatitude[zi], "decimalLatitude")
  ok  <- !is.na(zi) & !is.na(lon) & !is.na(lat)
  id  <- rep(NA_integer_, length(rid))
  if (any(ok)) {
    corner <- occ_cell02(lon[ok], lat[ok], deg)
    idx <- sdm_cell_index(corner$cell02_lon_deg, corner$cell02_lat_deg, deg)
    id[ok] <- sdm_cell_id(idx$ix, idx$iy)
  }
  list(id = id, n_missing = sum(!ok), n_repeat = n_repeat)
}

# ---- Rule L1 (Decision 26 point 7) ----------------------------------------------------
# hot_ids : the cell ids of the hot cells
# rc_id   : the 0.2 degree cell id of each row of sdm_reserve_cells() (a
#           complete-case 1 km cell whose centre is in a reserve polygon)
# rc_lc   : the landscape complex of the reserve of each such row
# levels  : the landscape complexes (LANDSCAPE_COMPLEXES)
# Returns a data frame: landscape (the levels, then
# "outside_reserve_polygons"), hot_cells. A cell with reserves of two
# complexes counts in each.
gistar_landscape_counts <- function(hot_ids, rc_id, rc_lc, levels) {
  if (length(rc_id) != length(rc_lc)) {
    stop("gistar_landscape_counts(): rc_id and rc_lc differ in length.",
         call. = FALSE)
  }
  if (!all(rc_lc %in% levels)) {
    stop("gistar_landscape_counts(): a landscape complex is not one of ",
         "the levels.", call. = FALSE)
  }
  n_lc <- vapply(levels, function(l) {
    sum(unique(hot_ids) %in% unique(rc_id[rc_lc == l]))
  }, numeric(1))
  data.frame(landscape = c(levels, "outside_reserve_polygons"),
             hot_cells = as.integer(c(n_lc,
                                      sum(!unique(hot_ids) %in% rc_id))),
             stringsAsFactors = FALSE)
}

# The share of the cells of class `cls` in `main` that have the same class
# in `qa` (QA bands, Decision 26 point 5). NA if `main` has no such cell.
gistar_same_share <- function(main, qa, cls) {
  n <- sum(main == cls)
  if (n == 0) return(NA_real_)
  sum(main == cls & qa == cls) / n
}

# ---- The checks of a Gi* layer (process choice n1 of task 16.2) ------------------------
# layer : a Gi* layer (a data frame; from memory or read back from disk)
# ids   : the model cell ids, sorted
# Returns a named list of TRUE/FALSE.
gistar_layer_checks <- function(layer, ids, classes = GISTAR_CLASSES,
                                min_nb = GISTAR_MIN_NEIGHBOURS) {
  ok_cols <- identical(names(layer), GISTAR_LAYER_FIELDS)
  pr <- function(v) is.numeric(v) && !anyNA(v) && all(v >= 0 & v <= 1)
  few <- if (ok_cols) layer$class == "few_neighbours" else FALSE
  list(
    "the layer must have the fields of n1, in their order" = ok_cols,
    "the layer must have one row for each model cell, in the order of the id" =
      ok_cols && identical(as.numeric(layer$id), as.numeric(ids)),
    "value must be 0 or 1" =
      ok_cols && !anyNA(layer$value) && all(layer$value %in% c(0, 1)),
    "n_win must be n_nb + 1" =
      ok_cols && !anyNA(layer$n_win) && all(layer$n_win == layer$n_nb + 1),
    "k must be from value to n_win" =
      ok_cols && !anyNA(layer$k) && all(layer$k >= layer$value) &&
      all(layer$k <= layer$n_win),
    "p_hot, p_cold and p_two must be in [0, 1]" =
      ok_cols && pr(layer$p_hot) && pr(layer$p_cold) && pr(layer$p_two),
    "p_adj must be NA for few_neighbours only, and in [0, 1] elsewhere" =
      ok_cols && all(is.na(layer$p_adj) == few) &&
      all(layer$p_adj[!few] >= 0 & layer$p_adj[!few] <= 1),
    "each class must be one of GISTAR_CLASSES" =
      ok_cols && all(layer$class %in% classes),
    "few_neighbours must be the cells with fewer than GISTAR_MIN_NEIGHBOURS neighbours" =
      ok_cols && identical(few, layer$n_nb < min_nb),
    "no field name may hold a presence, background, record, tiger or occurrence word" =
      !any(grepl("presence|pres_|background|record|tiger|occ",
                 tolower(names(layer))))
  )
}

# ---- The hand-made case of STEP 16.1 (h1) ---------------------------------------------
# A made-up lattice of 15 x 15 cells of 0.2 degrees (ix 400-414, iy 100-114;
# about 20-23 degrees N). The expected values are computed here by direct
# loops (all pairs; sums of dhyper terms; the BH steps by hand), not by the
# functions under test. Returns a data frame: check, pass. The caller stops
# on a FALSE.
gistar_self_test <- function(deg = 0.2, r_km = 6371.0088, band_km = 50,
                             min_nb = 8L, q = 0.05) {
  tol <- 1e-12
  near <- function(a, b) isTRUE(all(abs(a - b) <= tol * pmax(1, abs(b))))
  g <- expand.grid(ix = 400:414, iy = 100:114)
  n <- nrow(g)
  rc <- function(ix, iy) which(g$ix == ix & g$iy == iy)
  lon <- (g$ix + 0.5) * deg
  lat <- (g$iy + 0.5) * deg
  hav <- function(i, j) {               # by hand, for the expected values
    p1 <- lat[i] * pi / 180; p2 <- lat[j] * pi / 180
    dl <- (lon[j] - lon[i]) * pi / 180
    a <- sin((p2 - p1) / 2)^2 + cos(p1) * cos(p2) * sin(dl / 2)^2
    2 * r_km * asin(sqrt(a))
  }
  # Expected neighbour counts: all pairs by a double loop.
  nb_hand <- integer(n)
  for (i in seq_len(n)) for (j in seq_len(n)) {
    if (i != j && hav(i, j) <= band_km) nb_hand[i] <- nb_hand[i] + 1L
  }
  nb  <- gistar_neighbours(g$ix, g$iy, "band", band_km, deg, r_km)
  nbq <- gistar_neighbours(g$ix, g$iy, "queen", NULL, deg, r_km)
  # Values: 1 on the 7 east columns (ix >= 408), 0 elsewhere.
  x <- as.integer(g$ix >= 408)
  st <- gistar_run(x, nb, min_nb, q, "BH")
  m <- sum(x)
  # Cell A (inner, west): window all 0. Cell B (inner, east): window all 1.
  # Cell C: on the border of the two halves. Corner: (400, 100).
  a <- rc(402, 107); b <- rc(412, 107); cc <- rc(408, 107)
  corner <- rc(400, 100); edge <- rc(407, 100)
  # K of cell C by hand.
  win_c <- c(cc, which(vapply(seq_len(n), function(j) {
    j != cc && hav(cc, j) <= band_km
  }, logical(1))))
  k_c <- sum(x[win_c]); nw_c <- length(win_c)
  xbar <- m / n; s <- sqrt(xbar * (1 - xbar))
  g_c <- (k_c - xbar * nw_c) / (s * sqrt((n * nw_c - nw_c^2) / (n - 1)))
  ph_c <- sum(stats::dhyper(k_c:min(nw_c, m), m, n - m, nw_c))
  pc_c <- sum(stats::dhyper(0:k_c, m, n - m, nw_c))
  # BH by hand over the cells with a class.
  cl <- which(nb_hand >= min_nb)
  p2 <- st$p_two[cl]
  o <- order(p2, decreasing = TRUE)
  bh <- numeric(length(p2))
  bh[o] <- pmin(1, cummin(length(p2) / (length(p2):1) * p2[o]))
  # k1: a 1 at the corner counts in the window of its neighbour (401, 101).
  x2 <- x; x2[corner] <- 1L
  st2 <- gistar_stat(x2, nb)
  # Rule L1 on made-up reserve cells.
  lc <- gistar_landscape_counts(hot_ids = c(11, 12, 13, 14),
                                rc_id = c(11, 11, 12, 12, 99),
                                rc_lc = c("a", "a", "a", "b", "b"),
                                levels = c("a", "b", "c"))
  # The window and the stops.
  w <- gistar_window(lat, band_km, deg, r_km)
  stop_zero <- tryCatch({ gistar_stat(rep(0L, n), nb); FALSE },
                        error = function(e) TRUE)
  stop_bin  <- tryCatch({ gistar_stat(x * 2L, nb); FALSE },
                        error = function(e) TRUE)
  stop_win  <- tryCatch({ gistar_window(lat, 500, deg, r_km, max_off = 3L)
                          FALSE }, error = function(e) TRUE)
  layer <- data.frame(id = seq_len(n), st)
  bad_layer <- layer; names(bad_layer)[2] <- "presence"
  # r2: the cell of a record from its GBIF coordinates. 77.2 is on a cell
  # edge: the record goes to the cell east of it (ix 386). gbifID 3 is in
  # the made-up file two times; gbifID 4 is not in it.
  z <- data.frame(gbifID = c("1", "2", "3", "3"),
                  decimalLatitude  = c("20.0", "20.15", "8.7", "8.7"),
                  decimalLongitude = c("77.2", "77.39", "77.0", "77.0"),
                  stringsAsFactors = FALSE)
  rec <- gistar_record_cells(c("1", "2", "3", "4"), z, deg)
  rec_ok <- identical(rec$id[1:3], as.integer(c(100L * 100000L + 386L,
                                                100L * 100000L + 386L,
                                                43L * 100000L + 385L))) &&
    is.na(rec$id[4]) && rec$n_missing == 1L && rec$n_repeat == 1L
  chk <- list(
    "distance: 1 degree of latitude = r x pi / 180" =
      near(gistar_dist_km(78, 20, 78, 21, r_km), r_km * pi / 180),
    "distance: 0 for one point, and the same in both directions" =
      gistar_dist_km(78, 20, 78, 20, r_km) == 0 &&
      near(gistar_dist_km(78, 20, 79, 21, r_km),
           gistar_dist_km(79, 21, 78, 20, r_km)),
    "window at 50 km on this lattice: ox = 2, oy = 2" =
      identical(unname(w), c(2L, 2L)),
    "band: the neighbour count of each cell = the count of all pairs by hand" =
      identical(nb$n_nb, nb_hand),
    "band: an inner cell has 20 neighbours at 50 km" = nb$n_nb[a] == 20L,
    "band: the corner cell has 7 neighbours; an edge cell 12" =
      nb$n_nb[corner] == 7L && nb$n_nb[edge] == 12L,
    "band: each pair is there in both directions" =
      identical(sort(paste(nb$from, nb$to)), sort(paste(nb$to, nb$from))),
    "queen: an inner cell 8, the corner 3, an edge cell 5" =
      nbq$n_nb[a] == 8L && nbq$n_nb[corner] == 3L && nbq$n_nb[edge] == 5L,
    "K of the border cell = the sum of its window by hand" =
      st$k[cc] == k_c && st$n_win[cc] == nw_c,
    "G* of the border cell = the formula by hand" = near(st$gistar[cc], g_c),
    "p_hot and p_cold of the border cell = the sums of dhyper by hand" =
      near(st$p_hot[cc], ph_c) && near(st$p_cold[cc], pc_c),
    "p_hot + p_cold - P(K = k) = 1 at each cell" =
      near(st$p_hot + st$p_cold -
             stats::dhyper(st$k, m, n - m, st$n_win), rep(1, n)),
    "p_two = min(1, 2 x min(p_hot, p_cold))" =
      near(st$p_two, pmin(1, 2 * pmin(st$p_hot, st$p_cold))),
    "BH: p_adj of the cells with a class = the steps by hand" =
      near(st$p_adj[cl], bh),
    "class: the inner east cell (window all 1) is hot" = st$class[b] == "hot",
    "class: the inner west cell (window all 0) is cold" = st$class[a] == "cold",
    "k1: the corner cell is few_neighbours, with no p_adj" =
      st$class[corner] == "few_neighbours" && is.na(st$p_adj[corner]),
    "k1: the value of the corner cell counts in the window of its neighbour" =
      st2$k[rc(401, 101)] == st$k[rc(401, 101)] + 1L,
    "a run with all values 0 stops (no variance)" = stop_zero,
    "a value that is not 0 or 1 stops" = stop_bin,
    "a band larger than the window limit stops" = stop_win,
    "L1: hot cells by complex (a cell in two complexes counts in each)" =
      identical(lc$hot_cells, c(2L, 1L, 0L, 2L)) &&
      identical(lc$landscape, c("a", "b", "c", "outside_reserve_polygons")),
    "the same-class share: 1 of 2 hot cells keeps its class" =
      gistar_same_share(c("hot", "hot", "cold"), c("hot", "not_significant",
                                                    "cold"), "hot") == 0.5 &&
      is.na(gistar_same_share(c("cold"), c("cold"), "hot")),
    "layer checks: a correct layer passes" =
      all(unlist(gistar_layer_checks(layer, seq_len(n),
                                     min_nb = min_nb))),
    "layer checks: a layer with a presence field fails" =
      !all(unlist(gistar_layer_checks(bad_layer, seq_len(n),
                                      min_nb = min_nb))),
    "r2: the cell of a record from its GBIF coordinates (an edge goes east or north); a missing and a repeated gbifID are counted" =
      rec_ok
  )
  data.frame(check = names(chk),
             pass = vapply(chk, function(v) isTRUE(v), logical(1)),
             stringsAsFactors = FALSE, row.names = NULL)
}
