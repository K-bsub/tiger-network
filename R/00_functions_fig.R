# =============================================================================
# 00_functions_fig.R
# Helpers for the three Stage-3 figures of Week 16 (Decision 25 points 4 to 6;
# Decision 26 point 7; process choices f1, z1, c1, h1, k1, d1 of task 16.2):
# fig_04 (the five suitability classes), fig_05 (the model output) and fig_06
# (the Gi* of the iNaturalist mammal records). scripts/09_model_suitability.R
# STEP 16.2 sources this file. The settings are in R/00_config.R; no value of
# the analysis is written here as a literal.
#
# Task 16.4 (2026-11-07): STEP 16.2.
#   fig_reader()       the read guard of k1: a reader that refuses a file that
#                      is not on the list of a figure, and records each read
#   fig_fields_ok()    TRUE if no field name holds a presence, background,
#                      record, tiger or occurrence word (k1)
#   fig_hatch_lines()  diagonal lines (45 degrees) cut to polygons (h1)
#   fig_key_box()      the square of the key box and its hatch (h1)
#   fig_class_labels() the legend labels of the five classes (Decision 25
#                      point 3: by rank, no value)
#   fig_fmt_int(), fig_fmt()  numbers for a caption
#   fig_wrap()         the caption text in lines of a set width
#   fig_quad_area_km2() the area of a 0.2 degree cell on the WGS 84 ellipsoid
#   fig_png_size()     the width and the height of a PNG file (its header)
#   fig_theme()        the theme of fig_03 (z1)
#   fig_self_test()    the hand-made case of STEP 16.2 (h1)
#
# SENSITIVE DATA: the figures draw the model cells (the grid layer with the
# prediction layer or the effort_inat Gi* layer), the reserve outlines and the
# state lines only. No point, no presence mark, no background mark (Decision 25
# point 6; Decision 26 point 7).
# =============================================================================

# ---- The read guard (k1 of task 16.2) ------------------------------------------------
# lists : a named list; for each name (a figure, or "caption"), the paths that
#         it may read
# Returns a list of two functions:
#   read(path, fig) : stops if path is not on lists[[fig]]; otherwise reads it
#                     (.gpkg: sf::st_read(); .csv: utils::read.csv(); .txt:
#                     readLines()) and records the read
#   log()           : a data frame (fig, file) of the reads, in order
fig_reader <- function(lists) {
  norm <- function(p) normalizePath(p, winslash = "/", mustWork = FALSE)
  allowed <- lapply(lists, norm)
  reads <- data.frame(fig = character(0), file = character(0),
                      stringsAsFactors = FALSE)
  read <- function(path, fig) {
    if (!fig %in% names(allowed)) {
      stop("fig_reader(): no list for ", fig, ".", call. = FALSE)
    }
    if (!norm(path) %in% allowed[[fig]]) {
      stop("fig_reader(): ", basename(path), " is not on the list of ", fig,
           " (process choice k1 of task 16.2).", call. = FALSE)
    }
    if (!file.exists(path)) {
      stop("fig_reader(): file not found: ", path, call. = FALSE)
    }
    ext <- tolower(tools::file_ext(path))
    out <- switch(ext,
      gpkg = sf::st_read(path, quiet = TRUE),
      csv  = utils::read.csv(path, stringsAsFactors = FALSE),
      txt  = readLines(path, warn = FALSE),
      stop("fig_reader(): no read rule for .", ext, call. = FALSE))
    reads <<- rbind(reads, data.frame(fig = fig, file = basename(path),
                                      stringsAsFactors = FALSE))
    out
  }
  list(read = read, log = function() reads)
}

# TRUE if no field name of x holds a presence, background, record, tiger or
# occurrence word (the check of Decision 25 point 4 and Decision 26 point 7).
fig_fields_ok <- function(x) {
  !any(grepl("presence|pres_|background|record|tiger|occ",
             tolower(names(x))))
}

# ---- The hatch (h1 of task 16.2) ------------------------------------------------------
# Lines at 45 degrees, y = x + c with c = k x step (k a whole number), cut to
# the polygons. The c values are fixed on the plane, so the lines of two
# cells side by side meet.
#   polys : an sfc of polygons (a projected CRS)
#   step  : the step of c, in the units of the CRS
# Returns an sfc of LINESTRING (empty if polys is empty).
fig_hatch_lines <- function(polys, step) {
  if (!is.numeric(step) || length(step) != 1L || is.na(step) || step <= 0) {
    stop("fig_hatch_lines(): step must be one number above 0.", call. = FALSE)
  }
  crs <- sf::st_crs(polys)
  if (length(polys) == 0) return(sf::st_sfc(crs = crs))
  bb <- sf::st_bbox(polys)
  x0 <- bb[["xmin"]] - step; x1 <- bb[["xmax"]] + step
  ks <- seq(floor((bb[["ymin"]] - x1) / step), ceiling((bb[["ymax"]] - x0) / step))
  lines <- lapply(ks * step, function(c) {
    sf::st_linestring(rbind(c(x0, x0 + c), c(x1, x1 + c)))
  })
  cut <- suppressWarnings(sf::st_intersection(sf::st_sfc(lines, crs = crs),
                                              sf::st_union(polys)))
  cut <- cut[!sf::st_is_empty(cut)]
  if (length(cut) == 0) return(sf::st_sfc(crs = crs))
  suppressWarnings(sf::st_cast(sf::st_collection_extract(cut, "LINESTRING"),
                               "LINESTRING"))
}

# The key box: a square of side `side` with its lower-left corner at (x, y),
# and its hatch. Returns list(square = sfc POLYGON, hatch = sfc LINESTRING).
fig_key_box <- function(x, y, side, step, crs) {
  sq <- sf::st_sfc(sf::st_polygon(list(rbind(
    c(x, y), c(x + side, y), c(x + side, y + side), c(x, y + side), c(x, y)))),
    crs = crs)
  list(square = sq, hatch = fig_hatch_lines(sq, step))
}

# ---- Legend labels and numbers ------------------------------------------------------
# The five classes by rank (Decision 25 point 3): class 5 first. No value.
fig_class_labels <- function(k = SDM_PUB_N_CLASSES) {
  if (!identical(as.integer(k), 5L)) {
    stop("fig_class_labels(): the labels are written for 5 classes.",
         call. = FALSE)
  }
  stats::setNames(c("Highest 20 % of model cells", "Second 20 %",
                    "Middle 20 %", "Fourth 20 %",
                    "Lowest 20 % of model cells"), as.character(5:1))
}

fig_fmt_int <- function(x) formatC(round(x), format = "d", big.mark = ",")
fig_fmt <- function(x, digits = 3) formatC(x, format = "f", digits = digits)

# The parts of a caption as one text, in lines of `width` characters.
fig_wrap <- function(parts, width = 185) {
  parts <- parts[!vapply(parts, is.null, logical(1))]
  paste(strwrap(paste(unlist(parts), collapse = " "), width = width),
        collapse = "\n")
}

# The area (km2) of a cell of latitude lat1-lat2 and width dlon (degrees) on
# the WGS 84 ellipsoid (the authalic formula). For caption item 1 of Decision
# 25 point 5: the analysis CRS (conformal) does not keep areas.
fig_quad_area_km2 <- function(lat1, lat2, dlon) {
  a <- 6378.137; f <- 1 / 298.257223563
  b <- a * (1 - f); e <- sqrt(1 - (b / a)^2)
  q <- function(phi) {
    s <- sin(phi * pi / 180)
    s / (1 - e^2 * s^2) + log((1 + e * s) / (1 - e * s)) / (2 * e)
  }
  (b^2 * dlon * pi / 180 / 2) * (q(lat2) - q(lat1))
}

# The width and the height (pixels) of a PNG file, from its IHDR header.
fig_png_size <- function(path) {
  con <- file(path, "rb"); on.exit(close(con))
  b <- readBin(con, "raw", n = 24)
  if (length(b) < 24 || !identical(b[1:8], as.raw(c(0x89, 0x50, 0x4e, 0x47,
                                                    0x0d, 0x0a, 0x1a, 0x0a)))) {
    stop("fig_png_size(): ", basename(path), " is not a PNG file.",
         call. = FALSE)
  }
  int4 <- function(r) sum(as.integer(r) * 256^(3:0))
  c(width = int4(b[17:20]), height = int4(b[21:24]))
}

# ---- The theme of fig_03 (z1) ------------------------------------------------------------
fig_theme <- function(ink, paper) {
  ggplot2::theme_void(base_size = 11) +
    ggplot2::theme(
      plot.background  = ggplot2::element_rect(fill = paper, colour = NA),
      panel.background = ggplot2::element_rect(fill = paper, colour = NA),
      plot.title       = ggplot2::element_text(face = "bold", colour = ink,
                                               size = 15),
      plot.subtitle    = ggplot2::element_text(colour = ink, size = 11),
      plot.caption     = ggplot2::element_text(colour = ink, size = 7.5,
                                               hjust = 0, lineheight = 1.15),
      plot.caption.position = "plot",
      plot.title.position   = "plot",
      legend.title     = ggplot2::element_text(colour = ink, size = 9),
      legend.text      = ggplot2::element_text(colour = ink, size = 8,
                                               lineheight = 0.95),
      legend.position  = "right",
      plot.margin      = ggplot2::margin(10, 10, 10, 10))
}

# ---- The hand-made case of STEP 16.2 (h1) ---------------------------------------------
# Made-up files and polygons only. Returns a data frame: check, pass.
fig_self_test <- function() {
  tmp <- tempfile("figtest_"); dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))
  f_csv <- file.path(tmp, "a.csv"); f_txt <- file.path(tmp, "b.txt")
  f_no  <- file.path(tmp, "c.csv")
  utils::write.csv(data.frame(id = 1:3, class = c(1L, 2L, 5L)), f_csv,
                   row.names = FALSE)
  writeLines("DOI: 10.0000/x", f_txt)
  utils::write.csv(data.frame(x = 1), f_no, row.names = FALSE)
  rdr <- fig_reader(list(fig_a = c(f_csv), caption = c(f_txt)))
  a <- rdr$read(f_csv, "fig_a"); b <- rdr$read(f_txt, "caption")
  refused <- tryCatch({ rdr$read(f_no, "fig_a"); FALSE },
                      error = function(e) TRUE)
  refused2 <- tryCatch({ rdr$read(f_csv, "caption"); FALSE },
                       error = function(e) TRUE)
  lg <- rdr$log()
  # A made-up square of 10 km in a projected CRS; a step of 2/3 of the side
  # gives 2 or 3 lines in it.
  crs <- sf::st_crs(7755)
  sq <- sf::st_sfc(sf::st_polygon(list(rbind(c(0, 0), c(1e4, 0), c(1e4, 1e4),
                                              c(0, 1e4), c(0, 0)))), crs = crs)
  h <- fig_hatch_lines(sq, 2e4 / 3)
  xy <- lapply(h, function(l) sf::st_coordinates(l)[, 1:2])
  slope1 <- all(vapply(xy, function(m) {
    abs((m[2, 2] - m[1, 2]) - (m[2, 1] - m[1, 1])) < 1e-6
  }, logical(1)))
  inside <- all(lengths(sf::st_covered_by(h, sf::st_buffer(sq, 1e-6))) == 1)
  # Two squares side by side: the lines of one meet the lines of the other.
  sq2 <- sf::st_sfc(sf::st_polygon(list(rbind(c(1e4, 0), c(2e4, 0),
                                               c(2e4, 1e4), c(1e4, 1e4),
                                               c(1e4, 0)))), crs = crs)
  h1 <- fig_hatch_lines(sq, 2e4 / 3); h2 <- fig_hatch_lines(sq2, 2e4 / 3)
  e1 <- do.call(rbind, lapply(h1, function(l) sf::st_coordinates(l)[, 1:2]))
  e2 <- do.call(rbind, lapply(h2, function(l) sf::st_coordinates(l)[, 1:2]))
  # The meeting points inside the common edge (not at its two corners: a
  # line through a corner touches the other square at one point only).
  on_edge <- function(e) {
    y <- as.numeric(e[abs(e[, 1] - 1e4) < 1e-6, 2])
    sort(round(y[y > 1e-6 & y < 1e4 - 1e-6], 3))
  }
  y_at_edge1 <- on_edge(e1)
  y_at_edge2 <- on_edge(e2)
  kb <- fig_key_box(100, 200, 3e4, 2e4 / 3, crs)
  lab <- fig_class_labels(5L)
  # A made-up PNG header (signature and IHDR) of 123 x 45 pixels.
  tf <- tempfile(fileext = ".png")
  writeBin(as.raw(c(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
                    0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52,
                    0, 0, 0, 123, 0, 0, 0, 45)), tf)
  ps <- fig_png_size(tf); unlink(tf)
  chk <- list(
    "reader: a file on the list is read" =
      identical(a$class, c(1L, 2L, 5L)) && identical(b, "DOI: 10.0000/x"),
    "reader: a file that is not on the list of the figure is refused" =
      refused && refused2,
    "reader: the log holds each read (figure and file), in order" =
      identical(lg$fig, c("fig_a", "caption")) &&
      identical(lg$file, c("a.csv", "b.txt")),
    "fields: a presence, record or tiger word is found; plain fields pass" =
      !fig_fields_ok(data.frame(presence = 1)) &&
      !fig_fields_ok(data.frame(n_records = 1)) &&
      !fig_fields_ok(data.frame(tiger_class = 1)) &&
      fig_fields_ok(data.frame(id = 1, class = 1, value = 1,
                               out_of_range = TRUE)),
    "hatch: 2 or 3 lines in a square of 10 km with a step of 2/3 of its side" =
      length(h) %in% 2:3,
    "hatch: each line is at 45 degrees and inside the square" =
      slope1 && inside,
    "hatch: the lines of two squares side by side meet at the common edge" =
      length(y_at_edge1) > 0 && identical(y_at_edge1, y_at_edge2),
    "hatch: no polygon gives no line" =
      length(fig_hatch_lines(sf::st_sfc(crs = crs), 1)) == 0,
    "key box: a square of the given side, with its hatch inside" =
      abs(as.numeric(sf::st_area(kb$square)) - 9e8) < 1e-3 &&
      length(kb$hatch) > 0 &&
      all(lengths(sf::st_covered_by(kb$hatch,
                                    sf::st_buffer(kb$square, 1e-6))) == 1),
    "labels: five classes, class 5 first, no value in a label" =
      identical(names(lab), c("5", "4", "3", "2", "1")) &&
      !any(grepl("[0-9]\\.[0-9]", lab)),
    "numbers: 6969 -> 6,969; 0.66826 -> 0.668" =
      fig_fmt_int(6969) == "6,969" && fig_fmt(0.66826, 3) == "0.668",
    "caption: no line is longer than the width" =
      all(nchar(strsplit(fig_wrap(list(strrep("word ", 100), NULL), 40),
                         "\n")[[1]]) <= 40),
    "PNG size: read from the header (123 x 45)" =
      identical(unname(ps), c(123, 45)),
    "area: the whole WGS 84 ellipsoid is 510,065,621.7 km2" =
      abs(fig_quad_area_km2(-90, 90, 360) - 510065621.7) < 0.1,
    "area: a 0.2 degree cell is 487.6 km2 at 8.0-8.2 N and 395.6 km2 at 36.8-37.0 N" =
      abs(fig_quad_area_km2(8, 8.2, 0.2) - 487.58) < 0.01 &&
      abs(fig_quad_area_km2(36.8, 37, 0.2) - 395.64) < 0.01
  )
  data.frame(check = names(chk),
             pass = vapply(chk, function(v) isTRUE(v), logical(1)),
             stringsAsFactors = FALSE, row.names = NULL)
}

# =============================================================================
# Task 17.5 (2026-11-14): the frame of fig_07 and fig_08 (process choice FR1
# of task 17.5; Decision 27 point 10). scripts/10_check_sdm_connectivity.R
# STEP 17.3 uses these; scripts/09 does not (its run stays the record).
#   fig_frame_paths()     the frame of fig_04 to fig_06 (fig_frame() of
#                         scripts/09 STEP 16.2: the same layers, widths and
#                         order), with each input as an argument, the cells
#                         optional (fig_08 has none), and path layers on top
#   fig_save_png()        ggsave() with the pixel check of fig_save() of
#                         scripts/09
#   fig_mix()             the mix of two colours (as scripts/07 STEP 12.7)
#   fig_self_test_paths() the hand-made case of these three
# SENSITIVE DATA: the frame draws the state lines, the reserve outlines, the
# hatch, the model cells (optional) and the path layers that the caller gives.
# It draws no point and no presence or background mark.
# =============================================================================

# The frame. st: the states (geometry only); res: the reserve outlines
# (geometry only); bb: the bounding box of the frame; cols: FIG_FRAME_COLOURS
# (ink, paper, state_fill, state_line). cells: an sf of cells, drawn with
# cell_aes (for example aes(fill = class, colour = class)) and linewidth
# 0.05. hatch: an sf of hatch lines. key: fig_key_box(); key_label: its text.
# path_layers: a list of ggplot2 layers, drawn after the hatch and before the
# key. scales: a list of ggplot2 scales.
fig_frame_paths <- function(st, res, bb, cols, title, subtitle, caption,
                            cells = NULL, cell_aes = NULL, hatch = NULL,
                            key = NULL, key_label = NULL, path_layers = list(),
                            scales = list()) {
  ink <- cols[["ink"]]
  paper <- cols[["paper"]]
  p <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = st, fill = cols[["state_fill"]], colour = NA)
  if (!is.null(cells)) {
    p <- p + ggplot2::geom_sf(data = cells, mapping = cell_aes,
                              linewidth = 0.05)
  }
  p <- p +
    ggplot2::geom_sf(data = st, fill = NA, colour = cols[["state_line"]],
                     linewidth = 0.25) +
    ggplot2::geom_sf(data = res, fill = NA, colour = "white", linewidth = 0.7) +
    ggplot2::geom_sf(data = res, fill = NA, colour = ink, linewidth = 0.3)
  if (!is.null(hatch) && nrow(hatch) > 0) {
    p <- p + ggplot2::geom_sf(data = hatch, colour = "white", linewidth = 0.6) +
      ggplot2::geom_sf(data = hatch, colour = ink, linewidth = 0.25)
  }
  for (ly in path_layers) p <- p + ly
  if (!is.null(key)) {
    sb <- sf::st_bbox(key$square)
    side <- sb[["xmax"]] - sb[["xmin"]]
    p <- p +
      ggplot2::geom_sf(data = sf::st_sf(geometry = key$square), fill = paper,
                       colour = ink, linewidth = 0.3) +
      ggplot2::geom_sf(data = sf::st_sf(geometry = key$hatch), colour = ink,
                       linewidth = 0.25) +
      ggplot2::annotate("text", x = sb[["xmin"]] + 1.2 * side,
                        y = sb[["ymin"]] + 0.5 * side, label = key_label,
                        hjust = 0, vjust = 0.5, size = 2.8, colour = ink,
                        lineheight = 1.05)
  }
  for (s in scales) p <- p + s
  p + ggplot2::coord_sf(crs = sf::st_crs(st), datum = NA,
                        xlim = c(bb[["xmin"]], bb[["xmax"]]),
                        ylim = c(bb[["ymin"]], bb[["ymax"]])) +
    ggplot2::labs(title = title, subtitle = subtitle, caption = caption) +
    fig_theme(ink, paper)
}

# Write p as a PNG of size_in (width, height; inches) at dpi, then check its
# pixel size from the header. Stops if the size differs. Returns the path.
fig_save_png <- function(p, path, size_in, dpi, bg) {
  dir <- dirname(path)
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  ggplot2::ggsave(path, plot = p, width = size_in[["width"]],
                  height = size_in[["height"]], dpi = dpi, bg = bg)
  want <- round(size_in * dpi)
  got <- fig_png_size(path)
  if (!all(got == want)) {
    stop("The figure ", basename(path), " has ", got[1], " x ", got[2],
         " pixels, not ", want[1], " x ", want[2], ".", call. = FALSE)
  }
  message("Wrote ", path, " (", got[1], " x ", got[2], " pixels)")
  invisible(path)
}

# The mix of the colours a and b at w (0 = a, 1 = b), as scripts/07.
fig_mix <- function(a, b, w) {
  grDevices::rgb(grDevices::colorRamp(c(a, b))(w), maxColorValue = 255)
}

# The hand-made case of the frame (made-up squares and lines only). Returns
# a data frame: check, pass.
fig_self_test_paths <- function() {
  crs <- sf::st_crs(7755)
  sq <- function(x0, y0, s) {
    sf::st_polygon(list(rbind(c(x0, y0), c(x0 + s, y0), c(x0 + s, y0 + s),
                              c(x0, y0 + s), c(x0, y0))))
  }
  st <- sf::st_sf(geometry = sf::st_sfc(sq(0, 0, 1e5), sq(1e5, 0, 1e5),
                                        crs = crs))
  res <- sf::st_sf(geometry = sf::st_sfc(sq(2e4, 2e4, 1e4), crs = crs))
  cells <- sf::st_sf(class = factor(c("1", "2"), levels = c("2", "1")),
                     geometry = sf::st_sfc(sq(4e4, 4e4, 2e4),
                                           sq(6e4, 4e4, 2e4), crs = crs))
  hatch <- sf::st_sf(geometry = fig_hatch_lines(sf::st_geometry(cells)[1],
                                                5e3))
  key <- fig_key_box(1.2e5, 1e4, 1.5e4, 5e3, crs)
  paths <- sf::st_sf(kind = factor("a"), geometry = sf::st_sfc(
    sf::st_linestring(rbind(c(1e4, 5e4), c(1.9e5, 5e4))), crs = crs))
  cols <- c(ink = "#1e1e1e", paper = "#f7f4ee", state_fill = "#e9e4d8",
            state_line = "#ffffff")
  bb <- sf::st_bbox(st)
  lay <- ggplot2::geom_sf(data = paths, ggplot2::aes(linetype = kind),
                          colour = "#00B4D8", linewidth = 0.45,
                          key_glyph = "path")
  p1 <- fig_frame_paths(st, res, bb, cols, "t", "s", "c", cells = cells,
                        cell_aes = ggplot2::aes(fill = class, colour = class),
                        hatch = hatch, key = key, key_label = "k",
                        path_layers = list(lay),
                        scales = list(ggplot2::scale_fill_manual(
                          values = c("1" = "#000000", "2" = "#ffffff"))))
  p2 <- fig_frame_paths(st, res, bb, cols, "t", "s", "c",
                        path_layers = list(lay))
  geoms <- function(p) vapply(p$layers, function(l) class(l$geom)[1],
                              character(1))
  b1 <- tryCatch({ ggplot2::ggplot_build(p1); TRUE }, error = function(e) FALSE)
  b2 <- tryCatch({ ggplot2::ggplot_build(p2); TRUE }, error = function(e) FALSE)
  # The order in p1 (11 layers): state fill, cells, state lines, outlines
  # (2), hatch (2), the path layer, the key (square, hatch, text). From
  # ggplot2 4.0 the layers have names, so the positions are compared with
  # unname().
  is_path <- vapply(p1$layers, function(l) {
    is.data.frame(l$data) && "kind" %in% names(l$data)
  }, logical(1))
  tf <- tempfile(fileext = ".png")
  suppressMessages(fig_save_png(p2, tf, c(width = 2, height = 1.5), 100,
                                cols[["paper"]]))
  sz <- fig_png_size(tf)
  unlink(tf)
  chk <- list(
    "frame: the plot with cells, hatch, key and a path layer builds" = b1,
    "frame: the plot with no cells (fig_08) builds" = b2,
    "frame: 11 layers with cells, hatch and key; 5 with none of them" =
      length(p1$layers) == 11L && length(p2$layers) == 5L,
    "frame: the path layer is after the outlines and the hatch, before the key" =
      identical(unname(which(is_path)), 8L) &&
      unname(geoms(p1)[9]) == "GeomSf" && unname(geoms(p1)[11]) == "GeomText",
    "save: a PNG of 2 x 1.5 inches at 100 dpi has 200 x 150 pixels" =
      identical(unname(sz), c(200, 150)),
    "mix: the paper and the ink at 0.55 is the link colour of fig_03" =
      identical(toupper(fig_mix("#f7f4ee", "#1e1e1e", 0.55)), "#7F7E7B")
  )
  data.frame(check = names(chk),
             pass = vapply(chk, function(v) isTRUE(v), logical(1)),
             stringsAsFactors = FALSE, row.names = NULL)
}
