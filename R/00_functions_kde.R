# =============================================================================
# 00_functions_kde.R
# Density surfaces for Stage 3, Week 13 (Decision 22, docs/methodology.md).
# Sourced by scripts/08_prepare_occurrences.R; never run standalone.
#
# Task 13.6 (STEP 13.4; added 2026-10-17; process choices t1, k2, n1, q2, s1,
# r1, h1, v1). One method for each surface (Decision 22 points 3, 5 and 7):
#   1. units  : a raster with 1 on each complete-case 1 km cell that holds one
#               or more inputs, and 0 on all other cells (the cell is the
#               unit; the number of inputs in a cell is not a weight).
#   2. kernel : quartic, K(d) = (1 - (d / R)^2)^2 for d < R, 0 from R; R is
#               the SUPPORT radius (not a standard deviation). The weight of a
#               cell is K at the distance between the cell centres; the
#               weights are scaled to a sum of 1 over the full disc.
#   3. sum    : terra::focal() with the weight matrix and fillvalue = 0. The
#               default fillvalue (NA) makes each cell within R of the grid
#               edge NA; the grid has a 5 km margin only (tested 2026-10-17).
#   4. edge   : uniform correction. M = the kernel mass of the disc of a cell
#               that falls on window cells (focal of the 0/1 window). The
#               value = sum / M / cell area (km2): units per km2. NA outside
#               the window (the complete-case cells of the covariate stack).
#
# Functions:
#   kde_weights()       the scaled quartic weight matrix for a radius
#   kde_window()        the 0/1 window raster of the complete-case cells
#   kde_units_rast()    the 0/1 units raster from a vector of cell numbers
#   kde_edge_mass()     M for a radius (NA outside the window)
#   kde_surface()       one surface: kernel sum / M / cell area
#   kde_summary()       sum, min, max, area above 0, cells with M below a flag
#   kde_compare()       Spearman rank correlation of two surfaces (QA radii)
#   kde_check_windows() the time windows: in order, no gap, no overlap
#   kde_window_counts() records and units of one set in each time window
#   kde_self_test()     the hand-made case of process choice h1
#   --- task 13.7 ---
#   kde_direct_check()  a written surface against a direct calculation at
#                       sample cells (kernel sum and edge mass from the
#                       distances, with no convolution)
#
# Base R and terra. No value is hardcoded: the calling script passes the
# KDE_* settings from R/00_config.R. No function prints or returns a position.
# =============================================================================

# ---- Kernel ----------------------------------------------------------------
# radius_m : the support radius R in metres (KDE_RADIUS_M or a QA radius)
# cell_m   : the cell size in metres (GRID_CELL_M); the grid cells are square
# Returns a (2k + 1) x (2k + 1) matrix, k = floor(R / cell_m), sum 1.
kde_weights <- function(radius_m, cell_m) {
  if (!is.numeric(radius_m) || length(radius_m) != 1L || is.na(radius_m) ||
      !is.numeric(cell_m) || length(cell_m) != 1L || is.na(cell_m) ||
      cell_m <= 0 || radius_m < 2 * cell_m) {
    stop("kde_weights(): the radius must be a number of 2 cells or more.",
         call. = FALSE)
  }
  k   <- floor(radius_m / cell_m)
  off <- (-k:k) * cell_m
  d   <- sqrt(outer(off^2, off^2, "+"))
  w   <- ifelse(d < radius_m, (1 - (d / radius_m)^2)^2, 0)
  w / sum(w)
}

# ---- Window ----------------------------------------------------------------
# stack : the covariate stack (all bands). A complete-case cell has a value in
#         each band (Decision 10; the cells of Decision 21 step 9).
# Returns list(win01 = 0/1 raster on the full grid, n = number of window
# cells).
kde_window <- function(stack) {
  cc    <- !is.na(sum(stack))
  win01 <- terra::ifel(cc, 1, 0)
  names(win01) <- "window"
  list(win01 = win01, n = as.integer(terra::global(win01, "sum")[[1]]))
}

# ---- Units -----------------------------------------------------------------
# template : a raster with the grid of the stack
# cells    : cell numbers of the inputs (duplicates are allowed; a cell counts
#            1 however many inputs it holds - KDE_UNIT = "cell")
# win_v    : the values of the window raster (0/1, one per cell), to check
#            that each unit is a window cell
kde_units_rast <- function(template, cells, win_v) {
  cells <- unique(as.integer(cells))
  if (anyNA(cells) || any(cells < 1L) ||
      any(cells > terra::ncell(template))) {
    stop("kde_units_rast(): a cell number is NA or outside the grid.",
         call. = FALSE)
  }
  if (length(win_v) != terra::ncell(template) || any(win_v[cells] != 1)) {
    stop("kde_units_rast(): a unit is not on a complete-case cell.",
         call. = FALSE)
  }
  v <- numeric(terra::ncell(template))
  v[cells] <- 1
  u <- terra::rast(template, nlyrs = 1)
  u <- terra::setValues(u, v)
  names(u) <- "units"
  u
}

# ---- Edge mass -------------------------------------------------------------
# M for each window cell: the sum of the weights of the cells of its disc that
# are window cells. Cells outside the grid count as 0 (fillvalue = 0). NA
# outside the window. M is in (0, 1].
kde_edge_mass <- function(win01, w) {
  m <- terra::focal(win01, w = w, fun = "sum", na.rm = FALSE, fillvalue = 0)
  m <- terra::mask(m, win01, maskvalues = 0)
  names(m) <- "edge_mass"
  m
}

# ---- One surface -----------------------------------------------------------
# units_r : the 0/1 units raster (kde_units_rast())
# mass_r  : the edge mass for the same weights (kde_edge_mass())
# cell_m  : the cell size in metres
# Value: units per km2 after the edge correction; NA outside the window.
kde_surface <- function(units_r, w, mass_r, cell_m, name = "density") {
  s <- terra::focal(units_r, w = w, fun = "sum", na.rm = FALSE,
                    fillvalue = 0)
  v <- s / mass_r / (cell_m / 1000)^2
  names(v) <- name
  v
}

# ---- Summary ---------------------------------------------------------------
# Statistics of one surface for tbl_15_kde_summary.csv. No position.
#   integral        : the sum of value x cell area over the window (about the
#                     number of units; not exact, because of the edge
#                     correction)
#   area_above0_km2 : the area of the cells with a value above 0
#   cells_mass_low  : window cells with M below flag_mass (one value per
#                     radius; the same for each surface of that radius)
kde_summary <- function(r, mass_r, flag_mass, cell_m) {
  a  <- (cell_m / 1000)^2
  mn <- terra::global(r, "min", na.rm = TRUE)[[1]]
  mx <- terra::global(r, "max", na.rm = TRUE)[[1]]
  sm <- terra::global(r, "sum", na.rm = TRUE)[[1]]
  ab <- terra::global(r > 0, "sum", na.rm = TRUE)[[1]]
  lo <- terra::global(mass_r < flag_mass, "sum", na.rm = TRUE)[[1]]
  data.frame(value_min = mn, value_max = mx, integral = sm * a,
             area_above0_km2 = ab * a, cells_mass_low = lo,
             stringsAsFactors = FALSE)
}

# ---- Radius comparison (Decision 22 point 5, QA) ---------------------------
# The Spearman rank correlation of two surfaces on the cells where one or both
# are above 0. Descriptive only: no rule uses it (Decision 22 c2).
kde_compare <- function(r_main, r_test) {
  v <- terra::values(c(r_main, r_test), mat = TRUE)
  keep <- stats::complete.cases(v) & (v[, 1] > 0 | v[, 2] > 0)
  rho <- if (sum(keep) > 2) {
    suppressWarnings(stats::cor(v[keep, 1], v[keep, 2], method = "spearman"))
  } else NA_real_
  data.frame(spearman = rho, cells_compared = sum(keep))
}

# ---- Time windows (Decision 22 point 6) -------------------------------------
# windows : named list of c(first, last) years (KDE_WINDOWS)
# Stops if the windows are not in order, leave a gap, overlap, or do not
# cover year_min to year_max.
kde_check_windows <- function(windows, year_min, year_max) {
  if (!is.list(windows) || length(windows) == 0 || is.null(names(windows)) ||
      any(!nzchar(names(windows)))) {
    stop("KDE_WINDOWS must be a named list.", call. = FALSE)
  }
  lo <- vapply(windows, function(x) as.integer(x[1]), integer(1))
  hi <- vapply(windows, function(x) as.integer(x[2]), integer(1))
  if (any(vapply(windows, length, integer(1)) != 2L) || anyNA(lo) ||
      anyNA(hi) || any(hi < lo)) {
    stop("Each window of KDE_WINDOWS must be c(first year, last year).",
         call. = FALSE)
  }
  if (lo[1] != year_min || hi[length(hi)] != year_max ||
      (length(lo) > 1 && any(lo[-1] != hi[-length(hi)] + 1L))) {
    stop("KDE_WINDOWS must cover ", year_min, "-", year_max, " in order, ",
         "with no gap and no overlap.", call. = FALSE)
  }
  invisible(TRUE)
}

# Records and units of one set in each window, and for all years.
#   year      : the year of each record
#   unit      : the unit of each record (a 1 km cell number, or a key of the
#               0.2 degree cell for the obscured set); used for the count only
#   set       : "tiger" or "background"; subset: the name of the set as in
#               tbl_15_occ_sets.csv ("1km", "5km", "obscured", "matched_1km")
#   unit_type : "cell_1km" or "cell_0.2deg" (text for the table)
kde_window_counts <- function(year, unit, set, subset, windows, unit_type) {
  stopifnot(length(year) == length(unit))
  one <- function(nm, lo, hi, k) {
    data.frame(set = set, subset = subset, window = nm,
               year_min = as.integer(lo),
               year_max = as.integer(hi), records = sum(k),
               units = length(unique(unit[k])), unit_type = unit_type,
               stringsAsFactors = FALSE)
  }
  rows <- lapply(names(windows), function(nm) {
    lo <- windows[[nm]][1]; hi <- windows[[nm]][2]
    one(nm, lo, hi, !is.na(year) & year >= lo & year <= hi)
  })
  lo_all <- windows[[1]][1]
  hi_all <- windows[[length(windows)]][2]
  rows[[length(rows) + 1]] <- one("all", lo_all, hi_all,
                                  !is.na(year) & year >= lo_all &
                                    year <= hi_all)
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

# ---- Hand-made case (process choice h1) -------------------------------------
# A made-up grid of 41 x 41 cells of cell_m, radius 5 cells. The expected
# values are computed by hand (loops), not by the functions under test.
# Returns one row per check: check, expected, got, pass. The caller stops if
# a check fails.
kde_self_test <- function(cell_m = 1000) {
  n  <- 41L
  R  <- 5 * cell_m
  k  <- 5L
  c0 <- 21L                                   # the centre row and column
  g  <- terra::rast(nrows = n, ncols = n, xmin = 0, xmax = n * cell_m,
                    ymin = 0, ymax = n * cell_m, crs = "local")
  w  <- kde_weights(R, cell_m)

  # Hand values: the unscaled quartic weights by a loop.
  raw <- matrix(0, 2 * k + 1, 2 * k + 1)
  for (i in -k:k) for (j in -k:k) {
    d <- sqrt(i^2 + j^2) * cell_m
    if (d < R) raw[i + k + 1, j + k + 1] <- (1 - (d / R)^2)^2
  }
  wc_hand      <- 1 / sum(raw)               # the scaled centre weight
  n_disc_hand  <- sum(raw > 0)                # cells of one disc
  quad_hand    <- sum(raw[(k + 1):(2 * k + 1), (k + 1):(2 * k + 1)]) /
    sum(raw)                                  # corner cell: a quarter disc
  half_hand    <- sum(raw[, 1:(k + 1)]) / sum(raw)  # straight edge: a half
  cell_rc <- function(r, c) terra::cellFromRowCol(g, r, c)
  val     <- function(x, r, c) terra::values(x, mat = FALSE)[cell_rc(r, c)]
  a_km2   <- (cell_m / 1000)^2

  # Case A: full window, one unit at the centre.
  winA  <- terra::setValues(terra::rast(g), 1)
  wvA   <- terra::values(winA, mat = FALSE)
  uA    <- kde_units_rast(g, cell_rc(c0, c0), wvA)
  mA    <- kde_edge_mass(winA, w)
  sA    <- kde_surface(uA, w, mA, cell_m)
  # Case B: full window, one unit at the corner cell (row 1, column 1).
  uB    <- kde_units_rast(g, cell_rc(1, 1), wvA)
  sB    <- kde_surface(uB, w, mA, cell_m)
  # Case C: window = columns 1 to c0 (a straight edge); a unit at (c0, c0).
  winC  <- terra::setValues(terra::rast(g),
                            rep(as.numeric(seq_len(n) <= c0), times = n))
  wvC   <- terra::values(winC, mat = FALSE)
  uC    <- kde_units_rast(g, cell_rc(c0, c0), wvC)
  mC    <- kde_edge_mass(winC, w)
  sC    <- kde_surface(uC, w, mC, cell_m)
  # Case D: three inputs in one cell count as one unit.
  uD    <- kde_units_rast(g, rep(cell_rc(c0, c0), 3), wvA)
  # Case E: a unit outside the window is refused.
  e_ok  <- tryCatch({ kde_units_rast(g, cell_rc(c0, c0 + 1L), wvC); FALSE },
                    error = function(e) TRUE)

  tol <- 1e-9
  chk <- list(
    list("weights sum to 1", 1, sum(w)),
    list("weight is 0 at the radius (5 cells)", 0, w[k + 1, 1]),
    list("weights are symmetric (max difference)", 0,
         max(abs(w - t(w)), abs(w - w[nrow(w):1, ]))),
    list("cells of one disc", n_disc_hand, sum(w > 0)),
    list("A: value at the unit cell = centre weight / km2",
         wc_hand / a_km2, val(sA, c0, c0)),
    list("A: edge mass at an inner cell", 1, val(mA, c0, c0)),
    list("A: value 0 at 6 cells from the unit (exact)", 0,
         val(sA, c0, c0 + k + 1L)),
    list("A: cells above 0 = cells of one disc", n_disc_hand,
         sum(terra::values(sA, mat = FALSE) > 0, na.rm = TRUE)),
    list("A: integral = 1 unit", 1,
         sum(terra::values(sA, mat = FALSE), na.rm = TRUE) * a_km2),
    list("B: edge mass at the grid corner (quarter disc)", quad_hand,
         val(mA, 1, 1)),
    list("B: value at the grid corner = centre weight / mass / km2",
         wc_hand / quad_hand / a_km2, val(sB, 1, 1)),
    list("C: edge mass on a straight window edge (its column and the left)",
         half_hand,
         val(mC, c0, c0)),
    list("C: value on the edge = centre weight / mass / km2",
         wc_hand / half_hand / a_km2, val(sC, c0, c0)),
    list("C: NA outside the window (1 = NA)", 1,
         as.numeric(is.na(val(sC, c0, c0 + 1L)))),
    list("D: three inputs in one cell = 1 unit", 1,
         sum(terra::values(uD, mat = FALSE))),
    list("E: a unit outside the window is refused (1 = refused)", 1,
         as.numeric(e_ok))
  )
  out <- data.frame(
    check    = vapply(chk, `[[`, character(1), 1),
    expected = vapply(chk, function(x) as.numeric(x[[2]]), numeric(1)),
    got      = vapply(chk, function(x) as.numeric(x[[3]]), numeric(1)),
    stringsAsFactors = FALSE
  )
  out$pass <- !is.na(out$got) &
    abs(out$got - out$expected) <= tol * pmax(1, abs(out$expected))
  out
}

# ---- Direct calculation at sample cells (task 13.7, STEP 13.5) --------------
# For each sample cell: the kernel sum of the units and the edge mass are
# computed from the distances between cell centres (no focal(), no weight
# matrix), then value = sum / mass / cell area. The result is compared with
# the written surface r.
#   unit_cells   : cell numbers of the units of the surface
#   win_v        : the values of the window raster (0/1, one per cell)
#   sample_cells : the cells to check (window cells)
# Returns one row: cells, max_rel_diff (relative to the direct value; a cell
# where both are 0 counts as 0). No position is returned.
kde_direct_check <- function(r, unit_cells, win_v, radius_m, cell_m,
                             sample_cells) {
  K   <- function(d) ifelse(d < radius_m, (1 - (d / radius_m)^2)^2, 0)
  k   <- floor(radius_m / cell_m)
  off <- (-k:k) * cell_m
  Z   <- sum(K(sqrt(outer(off^2, off^2, "+"))))
  nr  <- terra::nrow(r)
  nc  <- terra::ncol(r)
  uxy <- terra::xyFromCell(r, unit_cells)
  got <- terra::values(r, mat = FALSE)[sample_cells]
  direct <- vapply(sample_cells, function(cl) {
    rc  <- terra::rowColFromCell(r, cl)
    xy  <- terra::xyFromCell(r, cl)
    s   <- sum(K(sqrt((uxy[, 1] - xy[1, 1])^2 + (uxy[, 2] - xy[1, 2])^2))) / Z
    blk <- terra::cellFromRowColCombine(
      r, max(1, rc[1, 1] - k):min(nr, rc[1, 1] + k),
      max(1, rc[1, 2] - k):min(nc, rc[1, 2] + k))
    bxy <- terra::xyFromCell(r, blk)
    m   <- sum(K(sqrt((bxy[, 1] - xy[1, 1])^2 + (bxy[, 2] - xy[1, 2])^2)) *
                 win_v[blk]) / Z
    s / m / (cell_m / 1000)^2
  }, numeric(1))
  rel <- ifelse(direct == 0 & got == 0, 0,
                abs(got - direct) / pmax(abs(direct), 1e-12))
  data.frame(cells = length(sample_cells), max_rel_diff = max(rel))
}
