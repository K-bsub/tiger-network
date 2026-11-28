# =============================================================================
# 00_functions_map.R
# The map and chart functions of Decision 29 (2026-11-26) for Stage 4, Week
# 19. scripts/12_build_maps.R sources this file (sc1 of task 19.2). The
# settings are the MAP_* and SITE_* values of R/00_config.R; no value of the
# analysis is written here as a literal.
#
# Task 19.3 (2026-11-26): STEP 19.1 — the interactive fig_01 (a ggiraph
# chart, ch1) and fig_02 (a leaflet map, mt1 and fg1), each a self-contained
# HTML file in site/widgets/ (nm1), with the check K1 (i) of Decision 29
# point 13 on the widget object before the save.
#   map_check_config()    the MAP_* block and SITE_MAPS: a named list of
#                         TRUE/FALSE
#   map_read_constants()  the values of the top-level literal assignments
#                         of a script (the colours of scripts/05)
#   map_round_sfc()       each coordinate of an sfc to `digits` decimals
#   map_keys()            the text key "lng,lat" of each point
#   map_sfc_keys()        the keys of the vertices of an sfc
#   map_widget_points()   each lng/lat pair in the calls of a leaflet widget
#   map_bounds()          the bounds of a map: wider if narrow, rounded
#                         outward
#   map_fit_js()          the JavaScript of the fit (the tools record); the
#                         fit keeps the controls off the bounds (mp1)
#   map_hover_html()      the hover text of each row (hv1)
#   map_text_ok()         TRUE for a text with no decimal degree (as check h)
#   map_check_leaflet()   K1 (i) on a leaflet widget
#   map_save_widget()     save a widget to a temporary file, check its size,
#                         and write it only if its bytes change
#   map_fig01_data()      the bars, the facets and the stripes of fig_01
#   map_fig01_chart()     the girafe widget of fig_01
#   map_bin_pop()         the classes of fig_02 (as scripts/05 STEP 6)
#   map_rounds_js()       the JavaScript of the rounds of fig_02 (fs2)
#   map_fig02_map()       the leaflet widget of fig_02 (no text box: mb1;
#                         the outlines once: fs2)
#   map_self_test()       the hand-made case of STEP 19.1 (made-up values)
#
# Task 19.4 (2026-11-26): STEP 19.2 — K1 (ii), the second path, on the
# saved files (the JSON in the file; the source layers and tables read
# again):
#   map_qa_read()         one saved file: the HTML, the size, the MD5, the
#                         JSON of the widget
#   map_qa_points()       the lng/lat pairs of the parsed JSON
#   map_qa_strings()      each text of the parsed JSON
#   map_qa_external()     the references to another place in the HTML
#   map_qa_keys()         the allowed points of a layer (rounded keys)
#   map_qa_unescape(), map_qa_tip_fields()   a hover text as fields
#   map_qa_leaflet()      the checks of each map file
#   map_qa_fig02()        the checks of the map file of fig_02 (fs2)
#   map_qa_chart()        the checks of the chart file of fig_01
#   map_qa_self_test()    the hand-made case of STEP 19.2 (made-up files)
#
# SENSITIVE DATA (docs/sensitive-data-policy.md; Decision 29): fig_01 and
# fig_02 are tier T0 (the census and the reserve outlines). No function
# reads a tiger record, a model layer or a Gi* layer. The functions print
# nothing; the script prints names and counts.
# =============================================================================

# ---- The MAP_* block -------------------------------------------------------------
map_check_config <- function() {
  maps <- SITE_MAPS
  stems <- sub("\\.html$", "", maps$file)
  fig_stems <- tools::file_path_sans_ext(maps$figure)
  list(
    "SITE_MAPS: unique files, each figure on SITE_FIGURES, kind chart or map" =
      !anyDuplicated(maps$file) && all(maps$figure %in% SITE_FIGURES$file) &&
      all(maps$kind %in% c("chart", "map")),
    "SITE_MAPS: each file is the stem of its PNG file + .html (nm1)" =
      all(grepl("\\.html$", maps$file)) && identical(stems, fig_stems),
    "SITE_MAPS: the kind of each file is the kind of its figure" =
      identical(maps$kind,
                SITE_FIGURES$kind[match(maps$figure, SITE_FIGURES$file)]),
    "MAP_DIGITS: a whole number from 4 to 7" =
      MAP_DIGITS == round(MAP_DIGITS) && MAP_DIGITS >= 4 && MAP_DIGITS <= 7,
    "MAP_MAX_BYTES and MAP_CHECK_TOL_DEG above 0" =
      MAP_MAX_BYTES > 0 && MAP_CHECK_TOL_DEG > 0,
    "MAP_MAX_ZOOM: a value for each map of SITE_MAPS, each above MAP_MIN_ZOOM" =
      all(stems[maps$kind == "map"] %in% names(MAP_MAX_ZOOM)) &&
      all(MAP_MAX_ZOOM > MAP_MIN_ZOOM),
    "MAP_BASEMAP is an Esri provider (bm1)" = grepl("^Esri\\.", MAP_BASEMAP),
    "MAP_FIG01_HOVER: the columns of the page table of tbl_01 (hv1)" =
      identical(MAP_FIG01_HOVER,
                SITE_TABLES_PAGE[[MAP_FIG01_TABLE]]$columns),
    "MAP_FIG02_FIRST is one of MAP_FIG02_ROUNDS" =
      MAP_FIG02_FIRST %in% MAP_FIG02_ROUNDS,
    "MAP_FIG02_SOURCES: one line of text; MAP_FIG02_LEGEND_WIDTH_PX above 0" =
      is.character(MAP_FIG02_SOURCES) && length(MAP_FIG02_SOURCES) == 1L &&
      nzchar(MAP_FIG02_SOURCES) && MAP_FIG02_LEGEND_WIDTH_PX > 0
  )
}

# ---- Constants of another script ---------------------------------------------------
# The values of the top-level assignments `name <- value` of a script, for
# the names given, evaluated in the order of the file in one environment
# (so that a value can use an earlier one). The script is parsed, not run.
# Each name must be assigned exactly once at the top level. Returns a named
# list.
map_read_constants <- function(path, names, parent = globalenv()) {
  if (!file.exists(path)) {
    stop("map_read_constants(): file not found: ", path, call. = FALSE)
  }
  ex <- parse(path, keep.source = FALSE)
  env <- new.env(parent = parent)
  found <- character(0)
  for (e in ex) {
    if (is.call(e) && length(e) == 3L &&
        (identical(e[[1]], as.name("<-")) || identical(e[[1]], as.name("="))) &&
        is.name(e[[2]])) {
      nm <- as.character(e[[2]])
      if (nm %in% names) {
        if (nm %in% found) {
          stop("map_read_constants(): ", nm, " is assigned more than once ",
               "at the top level of ", basename(path), ".", call. = FALSE)
        }
        assign(nm, eval(e[[3]], env), envir = env)
        found <- c(found, nm)
      }
    }
  }
  miss <- setdiff(names, found)
  if (length(miss) > 0) {
    stop("map_read_constants(): not assigned at the top level of ",
         basename(path), ": ", paste(miss, collapse = ", "), call. = FALSE)
  }
  mget(names, envir = env)
}

# ---- Coordinates ------------------------------------------------------------------
# Each coordinate of an sfc (longitude and latitude) to `digits` decimals.
# The geometry type and the CRS do not change.
map_round_sfc <- function(g, digits = MAP_DIGITS) {
  crs <- sf::st_crs(g)
  out <- lapply(g, function(x) {
    cl <- class(x)
    y <- unclass(x)
    y <- if (is.list(y)) {
      rapply(y, function(m) round(m, digits), how = "replace")
    } else {
      round(y, digits)
    }
    class(y) <- cl
    y
  })
  sf::st_sfc(out, crs = crs)
}

# The text key "lng,lat" of each point, with `digits` decimals.
map_keys <- function(lng, lat, digits = MAP_DIGITS) {
  sprintf("%.*f,%.*f", digits, lng, digits, lat)
}

# The keys of the vertices of an sfc (or an sf).
map_sfc_keys <- function(g, digits = MAP_DIGITS) {
  co <- sf::st_coordinates(g)
  unique(map_keys(co[, "X"], co[, "Y"], digits))
}

# Each lng/lat pair in the arguments of the calls of a leaflet widget: a
# list with the numeric elements `lng` and `lat`, at any depth (the form of
# the polygons and lines of leaflet). Returns a matrix: lng, lat.
map_widget_points <- function(w) {
  acc <- list()
  walk <- function(o) {
    if (is.list(o)) {
      if (all(c("lng", "lat") %in% names(o)) && is.numeric(o$lng) &&
          is.numeric(o$lat)) {
        acc[[length(acc) + 1L]] <<- cbind(lng = as.numeric(o$lng),
                                          lat = as.numeric(o$lat))
      } else {
        for (e in o) walk(e)
      }
    }
  }
  for (cl in w$x$calls) walk(cl$args)
  if (length(acc) == 0) return(cbind(lng = numeric(0), lat = numeric(0)))
  do.call(rbind, acc)
}

# The bounds of the map: the bounding box of the sfc objects (lng/lat), made
# wider to min_span if narrower, then rounded outward to `digits` decimals.
# Returns c(lng1, lat1, lng2, lat2).
map_bounds <- function(gs, min_span = MAP_MIN_SPAN_DEG, digits = MAP_DIGITS) {
  bb <- do.call(rbind, lapply(gs, function(g) as.numeric(sf::st_bbox(g))))
  b <- c(min(bb[, 1]), min(bb[, 2]), max(bb[, 3]), max(bb[, 4]))
  for (k in 1:2) {
    span <- b[k + 2] - b[k]
    if (span < min_span) {
      mid <- (b[k] + b[k + 2]) / 2
      b[k] <- mid - min_span / 2
      b[k + 2] <- mid + min_span / 2
    }
  }
  # Outward rounding; the 1e-6 keeps a value that is already on the grid
  # of `digits` (79.975 is stored as 79.97499999...) on that grid.
  f <- 10^digits
  c(floor(b[1:2] * f + 1e-6) / f, ceiling(b[3:4] * f - 1e-6) / f)
}

# The JavaScript of htmlwidgets::onRender() for the fit (the Leaflet recipe
# of the tools record): wait for the real size of the frame, then fit the
# bounds so that no control covers them in the first view (mp1, task 19.3,
# 2026-11-26). Each control is in a corner of the map, so a band at the left
# and the right (h), or a band at the top and the bottom (v), keeps the
# bounds free of the controls; the fit uses the bands that give the larger
# scale before the zoom limits (a wide frame: h; a narrow frame: v), so the
# choice also holds when both fits stop at the minimum zoom. The attribution
# line is in the bottom band of both. The choice is written to the
# attribute data-fit of the map element (for the tests). data = list(b =
# c(lng1, lat1, lng2, lat2), pad = pixels).
map_fit_js <- function() {
  paste(
    "function(el, x, data) {",
    "  var map = this, tries = 0, b = data.b, pad = data.pad;",
    "  var box = L.latLngBounds([[b[1], b[0]], [b[3], b[2]]]);",
    "  function bands() {",
    "    var c = el.getBoundingClientRect(), s = {l: 0, r: 0, t: 0, b: 0, a: 0};",
    "    var ctl = el.querySelectorAll('.leaflet-control');",
    "    for (var i = 0; i < ctl.length; i++) {",
    "      var r = ctl[i].getBoundingClientRect(), p = ctl[i].parentNode.classList;",
    "      if (r.width === 0 || r.height === 0) continue;",
    "      if (ctl[i].classList.contains('leaflet-control-attribution')) {",
    "        s.a = Math.max(s.a, c.bottom - r.top);",
    "        continue;",
    "      }",
    "      if (p.contains('leaflet-left'))   s.l = Math.max(s.l, r.right - c.left);",
    "      if (p.contains('leaflet-right'))  s.r = Math.max(s.r, c.right - r.left);",
    "      if (p.contains('leaflet-top'))    s.t = Math.max(s.t, r.bottom - c.top);",
    "      if (p.contains('leaflet-bottom')) s.b = Math.max(s.b, c.bottom - r.top);",
    "    }",
    "    s.b = Math.max(s.b, s.a);",
    "    return s;",
    "  }",
    "  function fit() {",
    "    if ((el.clientHeight > 0 && el.clientWidth > 0) || tries > 120) {",
    "      map.invalidateSize();",
    "      var s = bands();",
    "      var h = {paddingTopLeft: [s.l + pad, pad],",
    "               paddingBottomRight: [s.r + pad, s.a + pad]};",
    "      var v = {paddingTopLeft: [pad, s.t + pad],",
    "               paddingBottomRight: [pad, s.b + pad]};",
    "      var z0 = map.getZoom();",
    "      var p1 = map.project(box.getNorthWest(), z0);",
    "      var p2 = map.project(box.getSouthEast(), z0);",
    "      var bw = Math.max(Math.abs(p2.x - p1.x), 1);",
    "      var bh = Math.max(Math.abs(p2.y - p1.y), 1);",
    "      var W = el.clientWidth, H = el.clientHeight;",
    "      var sh = Math.min((W - s.l - s.r - 2 * pad) / bw, (H - s.a - 2 * pad) / bh);",
    "      var sv = Math.min((W - 2 * pad) / bw, (H - s.t - s.b - 2 * pad) / bh);",
    "      el.setAttribute('data-fit', sh >= sv ? 'h' : 'v');",
    "      map.fitBounds(box, sh >= sv ? h : v);",
    "    } else {",
    "      tries = tries + 1;",
    "      window.requestAnimationFrame(fit);",
    "    }",
    "  }",
    "  window.requestAnimationFrame(fit);",
    "}", sep = "\n")
}

# ---- Hover text --------------------------------------------------------------------
# One HTML text for each row of df (all columns text): the value of
# `title_col` in bold, then one line "field: value" for each of `fields`.
# Each value is escaped. The fields must be columns of df.
map_hover_html <- function(df, title_col, fields) {
  miss <- setdiff(c(title_col, fields), names(df))
  if (length(miss) > 0) {
    stop("map_hover_html(): column(s) not in the data: ",
         paste(miss, collapse = ", "), call. = FALSE)
  }
  esc <- function(x) htmltools::htmlEscape(ifelse(is.na(x), "NA", x))
  vapply(seq_len(nrow(df)), function(i) {
    lines <- paste0(fields, ": ", esc(unlist(df[i, fields],
                                              use.names = FALSE)))
    paste0("<b>", esc(df[[title_col]][i]), "</b><br>",
           paste(lines, collapse = "<br>"))
  }, character(1))
}

# TRUE for each text with no decimal degree (the pattern of check h of
# STEP 18.2, SITE_QA_DEGREE_RE).
map_text_ok <- function(x) !grepl(SITE_QA_DEGREE_RE, x, perl = TRUE)

# ---- K1 (i): the check of a leaflet widget before the save ---------------------------
#   w        : the leaflet widget
#   allowed  : the keys (map_keys()) of the points that may be in the map
#   bounds   : c(lng1, lat1, lng2, lat2) of map_bounds()
#   methods  : the leaflet calls that this map may hold
#   texts    : each hover text and each text of a control
# Returns a named list of TRUE/FALSE.
map_check_leaflet <- function(w, allowed, bounds, methods, texts,
                              digits = MAP_DIGITS, tol = MAP_CHECK_TOL_DEG) {
  calls <- vapply(w$x$calls, function(cl) cl$method, character(1))
  pts <- map_widget_points(w)
  keys <- map_keys(pts[, "lng"], pts[, "lat"], digits)
  f <- 10^digits
  fb <- w$x$fitBounds
  hooks <- w$jsHooks$render
  hook_b <- if (length(hooks) == 1L) unlist(hooks[[1]]$data$b) else NULL
  lim <- w$x$limits
  list(
    "calls: each call of the map is on its list" =
      length(calls) > 0 && all(calls %in% methods),
    "coordinates: each point is a point of an allowed kind (Decision 29 point 13)" =
      nrow(pts) > 0 && all(keys %in% allowed),
    "coordinates: no point has more decimals than MAP_DIGITS (rd1)" =
      all(abs(pts * f - round(pts * f)) <= tol * f),
    "bounds: fitBounds holds the bounds of the map, as the last view" =
      !is.null(fb) &&
      isTRUE(all.equal(unlist(fb[1:4]), bounds[c(2, 1, 4, 3)], tolerance = 0)),
    "bounds: the fit of onRender holds the same bounds" =
      !is.null(hook_b) && isTRUE(all.equal(hook_b, bounds, tolerance = 0)),
    "limits: the data limits are the range of the points" =
      !is.null(lim) &&
      isTRUE(all.equal(range(lim$lng), range(pts[, "lng"]))) &&
      isTRUE(all.equal(range(lim$lat), range(pts[, "lat"]))),
    "texts: no decimal degree in a hover text or a control" =
      length(texts) > 0 && all(map_text_ok(texts))
  )
}

# ---- Save -------------------------------------------------------------------------
# Save a widget as one self-contained HTML file (mt1): first to a temporary
# folder, then a check of the size (sz1), then a write to `path` only if the
# bytes differ (a file that is the same keeps its time stamp). Returns
# list(status = "written" or "same", bytes).
map_save_widget <- function(w, path, title, background = "white",
                            max_bytes = MAP_MAX_BYTES) {
  if (!rmarkdown::pandoc_available()) {
    stop("map_save_widget(): pandoc is not available; saveWidget() needs it ",
         "for a self-contained file (mt1).", call. = FALSE)
  }
  tmp <- tempfile("mapsave_"); dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))
  f <- file.path(tmp, basename(path))
  htmlwidgets::saveWidget(w, f, selfcontained = TRUE,
                          libdir = file.path(tmp, "lib"),
                          background = background, title = title)
  bytes <- file.size(f)
  if (bytes > max_bytes) {
    stop("map_save_widget(): ", basename(path), " has ", bytes, " bytes, ",
         "more than MAP_MAX_BYTES (", max_bytes, "). No file was written. ",
         "Decision 29 point 2: the author decides.", call. = FALSE)
  }
  new <- readBin(f, "raw", n = bytes)
  if (file.exists(path)) {
    old <- readBin(path, "raw", n = file.size(path))
    if (identical(old, new)) return(list(status = "same", bytes = bytes))
  }
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeBin(new, path)
  list(status = "written", bytes = bytes)
}

# ---- fig_01: the chart (ch1) -------------------------------------------------------------
# The bars of fig_01 as in scripts/05 STEP 5, from tbl_01 read as text (all
# columns), with the metric RANK_METRIC (change_pct).
#   t01    : tbl_01_reserve_growth.csv as text (site_read_table())
#   k      : the constants of scripts/05 (map_read_constants())
#   fields : the hover fields (MAP_FIG01_HOVER)
# Returns a list: ranked (the bars), stripes, x_lim, n_ranked, n_not_ranked,
# n_facets, facets (the labels), no_panel (the names of the reserves with no
# value in a complex with no bar: the chart has no panel for them; byte
# order).
map_fig01_data <- function(t01, k, fields = MAP_FIG01_HOVER,
                           complexes = LANDSCAPE_COMPLEXES) {
  metric <- suppressWarnings(as.numeric(t01[[k$RANK_METRIC]]))
  bad <- !is.na(t01[[k$RANK_METRIC]]) & is.na(metric)
  if (any(bad)) {
    stop("map_fig01_data(): ", k$RANK_METRIC, " holds text that is not a ",
         "number.", call. = FALSE)
  }
  ok <- !is.na(metric)
  ranked <- t01[ok, , drop = FALSE]
  ranked$metric <- metric[ok]
  not_ranked <- t01[!ok, , drop = FALSE]
  ranked$growth_sign <- factor(
    ifelse(ranked$metric > 0, "Growing",
           ifelse(ranked$metric < 0, "Declining", "No change")),
    levels = c("Growing", "No change", "Declining"))
  lc_present <- complexes[complexes %in% ranked$landscape_complex]
  n_na <- as.integer(table(factor(not_ranked$landscape_complex,
                                  levels = lc_present)))
  pretty <- unname(k$lc_pretty[lc_present])
  lab <- ifelse(n_na > 0, sprintf("%s  (%d not ranked)", pretty, n_na), pretty)
  facet_map <- stats::setNames(lab, lc_present)
  ranked$facet <- factor(facet_map[ranked$landscape_complex],
                         levels = facet_map[lc_present])
  key <- paste(ranked$landscape_complex, ranked$unit_name, sep = "___")
  if (anyDuplicated(key)) {
    stop("map_fig01_data(): two bars share the key landscape + name: ",
         paste(unique(key[duplicated(key)]), collapse = ", "), call. = FALSE)
  }
  ranked$row_key <- stats::reorder(key, ranked$metric)
  shown <- as.data.frame(lapply(ranked[, fields, drop = FALSE],
                                site_fmt_values),
                         check.names = FALSE, stringsAsFactors = FALSE)
  ranked$tip <- map_hover_html(shown, "unit_name",
                               setdiff(fields, "unit_name"))
  ranked$bar_id <- as.character(ranked$unit_id)
  stripes <- data.frame(
    facet = factor(facet_map[lc_present], levels = facet_map[lc_present]),
    fill_band = ifelse(seq_along(lc_present) %% 2 == 1, k$PAPER_ALT, k$PAPER),
    stringsAsFactors = FALSE)
  x_min <- min(0, ranked$metric); x_max <- max(0, ranked$metric)
  x_pad <- (x_max - x_min) * 0.04
  list(ranked = ranked, stripes = stripes,
       x_lim = c(x_min - x_pad, x_max + x_pad),
       n_ranked = nrow(ranked), n_not_ranked = nrow(not_ranked),
       n_facets = length(lc_present), facets = unname(facet_map),
       no_panel = sort(not_ranked$unit_name[
         !not_ranked$landscape_complex %in% lc_present], method = "radix"))
}

# The girafe widget of fig_01 (ch1): the ggplot of scripts/05 STEP 5 with
# interactive bars.
#   font_file : MAP_FIG01_FONT_FILE. FALSE: no font file in the file; the
#               text uses the sans font of the reader's browser (the SVG
#               names the sans font of the machine that runs the script).
#               TRUE: Liberation Sans goes into the file (gdtools; about 2 MB
#               more), so that the text has the same size in each browser.
#               ggiraph 0.9.7 or later sends the Liberation fonts by default
#               (its argument `font_set`); with FALSE the script gives it an
#               empty font set. ggiraph 0.9.6 has no `font_set`.
map_fig01_chart <- function(d, k, element_id, font_file = MAP_FIG01_FONT_FILE) {
  if (font_file) gdtools::register_liberationsans()
  p <- ggplot2::ggplot(d$ranked, ggplot2::aes(x = metric, y = row_key)) +
    ggplot2::geom_rect(data = d$stripes, inherit.aes = FALSE,
                       ggplot2::aes(xmin = -Inf, xmax = Inf, ymin = -Inf,
                                    ymax = Inf, fill = I(fill_band))) +
    ggiraph::geom_col_interactive(
      ggplot2::aes(fill = growth_sign, tooltip = tip, data_id = bar_id),
      width = 0.72) +
    ggplot2::geom_vline(xintercept = 0, colour = k$INK, linewidth = 0.4) +
    ggplot2::facet_wrap(ggplot2::vars(facet), ncol = 1, scales = "free_y",
                        strip.position = "top") +
    ggplot2::scale_fill_manual(values = k$sign_pal, drop = FALSE,
                               name = NULL) +
    ggplot2::scale_y_discrete(labels = k$y_labeller) +
    ggplot2::scale_x_continuous(limits = d$x_lim) +
    ggplot2::labs(title = MAP_FIG01_TITLE,
                  subtitle = sprintf(MAP_FIG01_SUBTITLE, k$metric_title),
                  x = k$metric_label, y = NULL,
                  caption = paste(strwrap(paste0("Caveat: ", k$EFFORT_CAVEAT),
                                          width = 120), collapse = "\n")) +
    k$theme_tiger
  if (font_file) {
    p <- p + ggplot2::theme(text = ggplot2::element_text(
      family = "Liberation Sans"))
  }
  h <- MAP_FIG01_HEIGHT_IN
  height <- max(h[["min"]], h[["base"]] + d$n_ranked * h[["per_bar"]] +
                  d$n_facets * h[["per_facet"]])
  args <- list(
    ggobj = p, width_svg = MAP_FIG01_WIDTH_IN, height_svg = height,
    # The SVG id must differ from the id of the widget (its container):
    # with one id for both, the script of ggiraph finds the container and
    # stops (task 19.3, the chat's test: "reading 'baseVal'").
    canvas_id = paste0("svg_", element_id),
    options = list(
      ggiraph::opts_tooltip(css = paste0(
        "background:#ffffff;color:", k$INK, ";padding:6px 8px;",
        "border:1px solid ", k$GRID, ";font-size:12px;",
        "font-family:Arial,'Liberation Sans',sans-serif;")),
      ggiraph::opts_hover(css = paste0("stroke:", k$INK, ";stroke-width:1;")),
      # No toolbar (no PNG button, no zoom, no fullscreen). `hidden` is given
      # by name: in the development version of ggiraph (0.9.8) the value
      # that saveaspng = FALSE sets is lost when the options merge.
      ggiraph::opts_toolbar(saveaspng = FALSE,
                            hidden = c("selection", "zoom", "misc")),
      ggiraph::opts_sizing(rescale = TRUE)))
  has_font_set <- "font_set" %in% names(formals(ggiraph::girafe))
  if (font_file) {
    if (has_font_set) {
      args$font_set <- gdtools::font_set(sans = gdtools::font_liberation("sans"))
    } else {
      args$dependencies <- list(gdtools::liberationsansHtmlDependency())
    }
  } else if (has_font_set) {
    args$font_set <- gdtools::font_set()
  }
  w <- do.call(ggiraph::girafe, args)
  w$elementId <- element_id
  # No page padding in the saved file (htmlwidgets puts 40 px by default),
  # so that the SVG fills the frame of its page (fr1).
  w$sizingPolicy$padding <- 0
  w$sizingPolicy$browser$padding <- 0
  list(widget = w, height_in = height, plot = p)
}

# ---- fig_02: the map (fg1) --------------------------------------------------------------
# The class of each value as in scripts/05 STEP 6: NA -> "No estimate"; a
# real 0 -> the first class ("0 (real)"); else the class of the fixed
# breaks. Returns a factor with the levels of the labels and "No estimate".
map_bin_pop <- function(x, breaks, labels) {
  lab <- as.character(cut(x, breaks = breaks, labels = labels, right = FALSE,
                          include.lowest = TRUE))
  lab[is.na(x)] <- "No estimate"
  factor(lab, levels = c(labels, "No estimate"))
}

# The JavaScript of htmlwidgets::onRender() for the rounds of fig_02 (fs2,
# task 19.4, 2026-11-26): the reserve outlines are in the file once, each
# with its id; the radio buttons (empty base groups, one for each round)
# change the fill colour, the hover label and the popup of each outline.
# The weight of an outline on hover (the highlight) is set here too, so
# that a mouse-out keeps the colour of the round. data: ids (the layer ids
# of the outlines), fill and tip (for each round, one value for each id, in
# the order of ids), first (the round shown first), w and hw (the weights).
map_rounds_js <- function() {
  paste(
    "function(el, x, data) {",
    "  var map = this, ids = data.ids;",
    "  function shape(id) { return map.layerManager.getLayer('shape', id); }",
    "  function show(yr) {",
    "    var f = data.fill[yr], t = data.tip[yr];",
    "    if (!f || !t) return;",
    "    for (var i = 0; i < ids.length; i++) {",
    "      var s = shape(ids[i]);",
    "      if (!s) continue;",
    "      s.setStyle({fillColor: f[i]});",
    "      if (s.getTooltip()) s.setTooltipContent(t[i]);",
    "      if (s.getPopup()) s.setPopupContent(t[i]);",
    "    }",
    "    el.setAttribute('data-round', yr);",
    "  }",
    "  for (var i = 0; i < ids.length; i++) {",
    "    var s = shape(ids[i]);",
    "    if (!s) continue;",
    "    s.on('mouseover', function() { this.setStyle({weight: data.hw}); this.bringToFront(); });",
    "    s.on('mouseout', function() { this.setStyle({weight: data.w}); });",
    "  }",
    "  map.on('baselayerchange', function(e) { show(e.name); });",
    "  show(data.first);",
    "}", sep = "\n")
}

# The leaflet widget of fig_02: the reserve outlines, the state lines, the
# radio buttons of the rounds (the round of `first` shows first) and the
# legend with the title of the map (a draft) as its heading. The data
# sources and the basemap are in the attribution line (T2 of Decision 29
# point 10). mb1 (task 19.3): no text box in the map; the caveat and the
# names of the reserves with no polygon are page text (the caption). fs2
# (task 19.4): the outlines are in the file once (layer id = unit_id); the
# colours and the hover texts of each round are data of the onRender hook
# (map_rounds_js()), with the fit (map_fit_js()) in the same one hook.
#   res     : the reserves with a polygon, in lng/lat, rounded (sf), with
#             unit_id, unit_name, state and pop_<year>
#   states  : the state polygons, in lng/lat, rounded (sfc or sf)
#   k       : the constants of scripts/05
# Returns a list: widget, bounds, texts, keys (the allowed points), classes
# (a table of the classes by round), methods.
map_fig02_map <- function(res, states, k, element_id,
                          rounds = MAP_FIG02_ROUNDS, first = MAP_FIG02_FIRST,
                          max_zoom = MAP_MAX_ZOOM[[element_id]]) {
  ramp <- c(k$POP_RAMP, "No estimate" = k$NO_ESTIMATE_COL)
  bounds <- map_bounds(list(sf::st_geometry(res), sf::st_geometry(states)))
  order_rounds <- c(first, setdiff(rev(rounds), first))
  ids <- as.character(res$unit_id)
  if (anyNA(ids) || anyDuplicated(ids)) {
    stop("map_fig02_map(): each reserve needs a unique unit_id.", call. = FALSE)
  }
  texts <- MAP_FIG02_SOURCES
  classes <- list(); fill <- list(); tips <- list()
  for (yr in order_rounds) {
    y <- as.character(yr)
    pop <- suppressWarnings(as.numeric(res[[paste0("pop_", yr)]]))
    cls <- map_bin_pop(pop, k$POP_BREAKS, k$POP_LABELS)
    classes[[y]] <- table(cls)
    hv <- data.frame(unit_name = res$unit_name, state = res$state,
                     round = y,
                     estimate = ifelse(is.na(pop), "No estimate",
                                       site_fmt_values(as.character(pop))),
                     class = as.character(cls), stringsAsFactors = FALSE)
    hv <- hv[, MAP_FIG02_HOVER]
    tips[[y]] <- map_hover_html(hv, "unit_name",
                                setdiff(MAP_FIG02_HOVER, "unit_name"))
    fill[[y]] <- unname(ramp[as.character(cls)])
    texts <- c(texts, tips[[y]])
  }
  f1 <- as.character(first)
  legend_title <- paste0(
    "<div style='max-width:", MAP_FIG02_LEGEND_WIDTH_PX,
    "px;white-space:normal;line-height:1.25;'>",
    htmltools::htmlEscape(MAP_FIG02_TITLE),
    "<br><span style='font-weight:normal;'>Tigers within reserve</span></div>")
  texts <- c(texts, legend_title)
  hook_js <- paste0("function(el, x, data) {\n  (", map_fit_js(),
                    ").call(this, el, x, data);\n  (", map_rounds_js(),
                    ").call(this, el, x, data);\n}")
  m <- leaflet::leaflet(
    options = leaflet::leafletOptions(minZoom = MAP_MIN_ZOOM,
                                      maxZoom = max_zoom,
                                      zoomSnap = MAP_ZOOM_SNAP,
                                      zoomDelta = MAP_ZOOM_DELTA),
    elementId = element_id) |>
    leaflet::addProviderTiles(MAP_BASEMAP) |>
    leaflet::addPolygons(data = sf::st_geometry(states), fill = FALSE,
                         color = k$STATE_LINE, weight = 0.8, opacity = 1,
                         options = leaflet::pathOptions(
                           attribution = MAP_FIG02_SOURCES)) |>
    leaflet::addPolygons(
      data = sf::st_geometry(res), layerId = ids,
      fillColor = fill[[f1]], fillOpacity = 0.9,
      color = k$INK, weight = MAP_FIG02_WEIGHT[["line"]], opacity = 1,
      label = lapply(tips[[f1]], htmltools::HTML), popup = tips[[f1]],
      labelOptions = leaflet::labelOptions(textsize = "12px",
                                           direction = "auto")) |>
    leaflet::addLayersControl(
      baseGroups = as.character(order_rounds),
      options = leaflet::layersControlOptions(collapsed = FALSE),
      position = "topright") |>
    leaflet::addLegend(position = "bottomright", colors = unname(ramp),
                       labels = names(ramp), opacity = 1,
                       title = legend_title) |>
    leaflet::fitBounds(bounds[1], bounds[2], bounds[3], bounds[4]) |>
    htmlwidgets::onRender(hook_js, data = list(
      b = bounds, pad = MAP_FIT_PAD_PX, ids = as.list(ids), first = f1,
      fill = lapply(fill, as.list), tip = lapply(tips, as.list),
      w = MAP_FIG02_WEIGHT[["line"]], hw = MAP_FIG02_WEIGHT[["hover"]]))
  keys <- unique(c(map_sfc_keys(res), map_sfc_keys(states)))
  list(widget = m, bounds = bounds, texts = texts, keys = keys,
       classes = classes, fill = fill, tips = tips, ids = ids,
       methods = c("addProviderTiles", "addPolygons", "addLayersControl",
                   "addLegend"))
}

# ---- The second path: the QA of the saved files (K1 (ii); task 19.4) -------------
# STEP 19.2 reads each saved file, not the widget object: the JSON of the
# widget in the file, the HTML around it, and the source layers and tables
# again. Each function returns TRUE/FALSE checks with a value (counts and
# names only; no coordinate goes to the console or to the QA table).

# One saved file: list(html, bytes, md5, ids (the data-for of each widget),
# json (the parsed JSON of each widget)).
map_qa_read <- function(path) {
  bytes <- file.size(path)
  html <- readChar(path, bytes, useBytes = TRUE)
  Encoding(html) <- "UTF-8"
  re <- '(?s)<script type="application/json" data-for="([^"]*)">(.*?)</script>'
  m <- regmatches(html, gregexpr(re, html, perl = TRUE))[[1]]
  ids <- sub(re, "\\1", m, perl = TRUE)
  json <- lapply(sub(re, "\\2", m, perl = TRUE), function(b) {
    jsonlite::fromJSON(b, simplifyVector = TRUE, simplifyDataFrame = FALSE,
                       simplifyMatrix = FALSE)
  })
  list(html = html, bytes = bytes, md5 = unname(tools::md5sum(path)),
       ids = ids, json = json)
}

# The lng/lat pairs of each object with the names lng and lat in a parsed
# JSON list. An object with lng and lat of different lengths, or not
# numbers, is counted in `bad`. Returns list(pts (a matrix lng, lat), bad).
map_qa_points <- function(o) {
  acc <- list(); bad <- 0L
  walk <- function(o) {
    if (!is.list(o)) return(invisible())
    nm <- names(o)
    if (!is.null(nm) && any(c("lng", "lat") %in% nm)) {
      if (all(c("lng", "lat") %in% nm) && is.numeric(o[["lng"]]) &&
          is.numeric(o[["lat"]]) && length(o[["lng"]]) == length(o[["lat"]])) {
        acc[[length(acc) + 1L]] <<- cbind(lng = o[["lng"]], lat = o[["lat"]])
      } else {
        bad <<- bad + 1L
      }
      return(invisible())
    }
    for (e in o) walk(e)
  }
  walk(o)
  pts <- if (length(acc) == 0) {
    matrix(numeric(0), 0, 2, dimnames = list(NULL, c("lng", "lat")))
  } else do.call(rbind, acc)
  list(pts = pts, bad = bad)
}

# Each text of a parsed JSON list (the names not included).
map_qa_strings <- function(o) {
  unname(unlist(rapply(list(o), function(x) x, classes = "character",
                       how = "unlist")))
}

# The references of an HTML text to another place: a script, a style
# sheet or an image with a src or href that is not a data: URI, and each
# frame. The text inside a script is not read (the libraries hold tags as
# text, for example the credits of other basemaps).
map_qa_external <- function(html) {
  html <- gsub("(?s)(<script\\b[^>]*>).*?</script>", "\\1</script>", html,
               perl = TRUE)
  tags <- regmatches(html, gregexpr("<(script|link|iframe|img)\\b[^>]*>",
                                    html, perl = TRUE, ignore.case = TRUE))[[1]]
  ref <- grepl("\\b(src|href)\\s*=\\s*[\"']?(?!data:)[^\"'\\s>]+", tags,
               perl = TRUE, ignore.case = TRUE)
  is_frame <- grepl("^<iframe", tags, ignore.case = TRUE)
  substr(tags[ref | is_frame], 1, 60)
}

# The text keys "lng,lat" of the vertices of a layer (sf or sfc), in
# lng/lat and rounded to `digits` decimals: the allowed points of the file.
map_qa_keys <- function(g, digits = MAP_DIGITS) {
  xy <- sf::st_coordinates(sf::st_transform(sf::st_geometry(g), CRS_WGS84))
  xy <- round(xy[, c("X", "Y"), drop = FALSE], digits)
  unique(sprintf("%.*f,%.*f", digits, xy[, 1], digits, xy[, 2]))
}

# HTML entities back to text (one level).
map_qa_unescape <- function(x) {
  x <- gsub("&lt;", "<", x, fixed = TRUE)
  x <- gsub("&gt;", ">", x, fixed = TRUE)
  x <- gsub("&quot;", "\"", x, fixed = TRUE)
  x <- gsub("&#39;", "'", x, fixed = TRUE)
  gsub("&amp;", "&", x, fixed = TRUE)
}

# A hover text "<b>name</b><br>field: value<br>..." as a named character
# vector (".name" and the fields), the values unescaped.
map_qa_tip_fields <- function(tip) {
  parts <- strsplit(tip, "<br>", fixed = TRUE)[[1]]
  nm <- map_qa_unescape(sub("^<b>(.*)</b>$", "\\1", parts[1]))
  kv <- parts[-1]
  key <- sub(": .*$", "", kv)
  val <- map_qa_unescape(sub("^[^:]*: ", "", kv))
  c(.name = nm, stats::setNames(val, key))
}

# The checks of one saved leaflet map file that hold for each map.
#   rd      : map_qa_read() of the file
#   stem    : the name of the file without .html (the widget id)
#   allowed : the allowed points (map_qa_keys() of the source layers)
#   methods : the calls that the file may hold (MAP_QA_METHODS)
# Returns a data frame: group, check, value, pass.
map_qa_leaflet <- function(rd, stem, allowed, methods,
                           max_zoom = MAP_MAX_ZOOM[[stem]],
                           max_bytes = MAP_MAX_BYTES, digits = MAP_DIGITS,
                           tol = MAP_CHECK_TOL_DEG) {
  out <- list()
  add <- function(group, check, value, pass) {
    out[[length(out) + 1L]] <<- data.frame(
      group = group, check = check, value = as.character(value),
      pass = isTRUE(pass), stringsAsFactors = FALSE)
  }
  one <- length(rd$ids) == 1L && identical(rd$ids, stem)
  add("file", "one widget in the file, with the id of the file",
      paste(length(rd$ids), "widget(s)"), one)
  ext <- map_qa_external(rd$html)
  add("file", "self-contained: no script, style sheet, image or frame from another place",
      paste(length(ext), "reference(s)"), length(ext) == 0)
  add("file", "the size is at most MAP_MAX_BYTES (sz1)",
      paste(format(rd$bytes, big.mark = ","), "bytes"), rd$bytes <= max_bytes)
  add("file", "the MD5 of the file (read by check l of STEP 18.2)", rd$md5, TRUE)
  if (!one) return(do.call(rbind, out))
  j <- rd$json[[1]]
  calls <- vapply(j$x$calls, function(cl) as.character(cl$method), character(1))
  add("layers", "each call of the file is on MAP_QA_METHODS (no other layer)",
      paste(unique(calls), collapse = ", "),
      length(calls) > 0 && all(calls %in% methods))
  tiles <- Filter(function(cl) identical(cl$method, "addProviderTiles"), j$x$calls)
  add("layers", "one basemap, MAP_BASEMAP (bm1)",
      paste(vapply(tiles, function(cl) as.character(cl$args[[1]]), ""),
            collapse = ", "),
      length(tiles) == 1L && identical(as.character(tiles[[1]]$args[[1]]),
                                       MAP_BASEMAP))
  # The points: each part of the file but the data limits (checked below).
  wp <- map_qa_points(list(j[setdiff(names(j), "x")],
                           j$x[setdiff(names(j$x), "limits")]))
  pts <- wp$pts
  keys <- sprintf("%.*f,%.*f", digits, pts[, 1], digits, pts[, 2])
  n_bad <- sum(!keys %in% allowed)
  add("coordinates",
      "each point is a point of an allowed kind (Decision 29 point 13, K1 (ii))",
      paste0(format(nrow(pts), big.mark = ","), " points; ", n_bad,
             " not allowed; ", wp$bad, " objects that are not pairs"),
      nrow(pts) > 0 && n_bad == 0 && wp$bad == 0)
  f <- 10^digits
  n_dig <- sum(abs(pts * f - round(pts * f)) > tol * f)
  add("coordinates", "no point has more decimals than MAP_DIGITS (rd1)",
      paste(n_dig, "points"), n_dig == 0)
  fb <- suppressWarnings(as.numeric(unlist(j$x$fitBounds[1:4])))
  hooks <- j$jsHooks$render
  hb <- if (length(hooks) == 1L) suppressWarnings(as.numeric(unlist(hooks[[1]]$data$b))) else NULL
  box_ok <- length(fb) == 4 && !anyNA(fb) && length(hb) == 4 &&
    isTRUE(all.equal(hb, fb[c(2, 1, 4, 3)], tolerance = 0)) && nrow(pts) > 0
  if (box_ok) {
    r_lng <- range(pts[, 1]); r_lat <- range(pts[, 2])
    slack <- function(r, lo, hi) {
      (hi - lo) <= max(diff(r), MAP_MIN_SPAN_DEG) + 2 * 10^-digits + tol
    }
    box_ok <- hb[1] <= r_lng[1] + tol && hb[3] >= r_lng[2] - tol &&
      hb[2] <= r_lat[1] + tol && hb[4] >= r_lat[2] - tol &&
      slack(r_lng, hb[1], hb[3]) && slack(r_lat, hb[2], hb[4]) &&
      all(abs(hb * f - round(hb * f)) <= tol * f)
  }
  add("bounds",
      "fitBounds and the fit of onRender hold one box: it holds each point and is no wider than needed",
      if (box_ok) "the same box" else "not the same, or too wide", box_ok)
  lim <- j$x$limits
  lim_ok <- !is.null(lim) && nrow(pts) > 0 &&
    isTRUE(all.equal(range(as.numeric(lim$lng)), range(pts[, 1]))) &&
    isTRUE(all.equal(range(as.numeric(lim$lat)), range(pts[, 2])))
  add("bounds", "the data limits of the file are the range of the points",
      if (lim_ok) "the range" else "not the range", lim_ok)
  zo <- j$x$options
  add("zoom", "the minimum and the maximum zoom are MAP_MIN_ZOOM and MAP_MAX_ZOOM (Z2, zm1)",
      paste0(zo$minZoom %||% "none", " and ", zo$maxZoom %||% "none"),
      identical(as.numeric(zo$minZoom), as.numeric(MAP_MIN_ZOOM)) &&
        identical(as.numeric(zo$maxZoom), as.numeric(max_zoom)))
  txt <- map_qa_strings(j)
  n_deg <- sum(grepl(SITE_QA_DEGREE_RE, txt, perl = TRUE))
  add("texts", "no text of the file holds a decimal degree (as check h)",
      paste(n_deg, "of", length(txt), "texts"), n_deg == 0)
  do.call(rbind, out)
}

# The checks of the saved file of fig_02 that are its own (fs2, fg1, hv1).
#   rd     : map_qa_read() of the file
#   res    : the reserve layer as read (all reserves; unit_id, unit_name,
#            state, geometry_present, pop_<year>)
#   states : the state layer as read
#   k      : the constants of scripts/05
# Returns a data frame: group, check, value, pass.
map_qa_fig02 <- function(rd, res, states, k, rounds = MAP_FIG02_ROUNDS,
                         first = MAP_FIG02_FIRST, fields = MAP_FIG02_HOVER) {
  out <- list()
  add <- function(group, check, value, pass) {
    out[[length(out) + 1L]] <<- data.frame(
      group = group, check = check, value = as.character(value),
      pass = isTRUE(pass), stringsAsFactors = FALSE)
  }
  j <- rd$json[[1]]
  polys <- Filter(function(cl) identical(cl$method, "addPolygons"), j$x$calls)
  has <- as.logical(res$geometry_present) & !sf::st_is_empty(res)
  src <- res[has, ]
  n_feat <- function(cl) length(cl$args[[1]])
  st_call <- Filter(function(cl) isFALSE(cl$args[[4]]$fill), polys)
  add("layers", "the state lines: one layer, no fill, one feature for each feature of the state layer",
      paste(length(st_call), "layer(s);",
            if (length(st_call) == 1) n_feat(st_call[[1]]) else "-", "of",
            nrow(states), "features"),
      length(st_call) == 1L && n_feat(st_call[[1]]) == nrow(states))
  rs_call <- Filter(function(cl) !is.null(cl$args[[2]]), polys)
  rs_ids <- if (length(rs_call) == 1) as.character(unlist(rs_call[[1]]$args[[2]])) else character(0)
  add("layers", "the reserve outlines: one layer, once (fs2), one feature with its unit_id for each reserve with a polygon",
      paste(length(rs_call), "layer(s);", length(rs_ids), "of", nrow(src),
            "reserves"),
      length(polys) == 2L && length(rs_call) == 1L &&
        n_feat(rs_call[[1]]) == nrow(src) &&
        identical(rs_ids, as.character(src$unit_id)))
  lc <- Filter(function(cl) identical(cl$method, "addLayersControl"), j$x$calls)
  base <- if (length(lc) == 1) as.character(unlist(lc[[1]]$args[[1]])) else character(0)
  add("rounds", "the radio buttons: one for each round of MAP_FIG02_ROUNDS, MAP_FIG02_FIRST first (fg1)",
      paste(base, collapse = ", "),
      setequal(base, as.character(rounds)) && length(base) == length(rounds) &&
        identical(base[1], as.character(first)))
  hd <- if (length(j$jsHooks$render) == 1) j$jsHooks$render[[1]]$data else list()
  ramp <- c(k$POP_RAMP, "No estimate" = k$NO_ESTIMATE_COL)
  n_tip <- 0L; bad_tip <- 0L; bad_col <- 0L; bad_cls <- 0L
  for (yr in as.character(rounds)) {
    fl <- as.character(unlist(hd$fill[[yr]])); tp <- as.character(unlist(hd$tip[[yr]]))
    pop <- suppressWarnings(as.numeric(src[[paste0("pop_", yr)]]))
    if (length(fl) != nrow(src) || length(tp) != nrow(src)) {
      bad_tip <- bad_tip + nrow(src); next
    }
    for (i in seq_len(nrow(src))) {
      n_tip <- n_tip + 1L
      v <- map_qa_tip_fields(tp[i])
      est <- if (is.na(pop[i])) "No estimate" else NA_character_
      e_ok <- !is.na(v["estimate"]) &&
        (if (is.na(pop[i])) identical(unname(v["estimate"]), "No estimate") else
          isTRUE(suppressWarnings(as.numeric(gsub(",", "", v["estimate"]))) == pop[i]))
      ok <- identical(unname(v[".name"]), src$unit_name[i]) &&
        identical(unname(v["state"]), src$state[i]) &&
        identical(unname(v["round"]), yr) && e_ok &&
        identical(names(v)[-1], setdiff(fields, "unit_name"))
      if (!ok) bad_tip <- bad_tip + 1L
      cls_want <- if (is.na(pop[i])) "No estimate" else
        k$POP_LABELS[findInterval(pop[i], k$POP_BREAKS, rightmost.closed = TRUE)]
      if (!identical(unname(v["class"]), cls_want)) bad_cls <- bad_cls + 1L
      if (!identical(fl[i], unname(ramp[cls_want]))) bad_col <- bad_col + 1L
    }
  }
  add("rounds", "the hover texts: for each reserve and round, the name, the state, the round and the estimate of the layer (hv1, fs2)",
      paste(n_tip, "texts;", bad_tip, "not as the layer"),
      n_tip == nrow(src) * length(rounds) && bad_tip == 0)
  add("rounds", "the classes: each class of a hover text is the class of the estimate (the breaks of scripts/05)",
      paste(bad_cls, "not the class"), n_tip > 0 && bad_cls == 0)
  add("rounds", "the colours: each colour is the colour of the class in the legend of scripts/05",
      paste(bad_col, "not the colour"), n_tip > 0 && bad_col == 0)
  f1 <- as.character(first)
  arg_chr <- function(i) {
    if (length(rs_call) == 1) as.character(unlist(rs_call[[1]]$args[[i]])) else character(0)
  }
  fc1 <- if (length(rs_call) == 1) as.character(unlist(rs_call[[1]]$args[[4]]$fillColor)) else character(0)
  tip1 <- as.character(unlist(hd$tip[[f1]]))
  add("rounds", "the first view: the colours, the popups and the labels of the layer are those of MAP_FIG02_FIRST",
      f1, length(tip1) > 0 &&
        identical(fc1, as.character(unlist(hd$fill[[f1]]))) &&
        identical(arg_chr(5), tip1) && identical(arg_chr(7), tip1))
  lg <- Filter(function(cl) identical(cl$method, "addLegend"), j$x$calls)
  lg_ok <- length(lg) == 1L &&
    identical(as.character(unlist(lg[[1]]$args[[1]]$colors)), unname(ramp)) &&
    identical(as.character(unlist(lg[[1]]$args[[1]]$labels)), names(ramp))
  add("layers", "the legend: the classes and the colours of scripts/05, with No estimate",
      paste(length(ramp), "classes"), lg_ok)
  do.call(rbind, out)
}

# The checks of the saved file of the chart fig_01 (ch1): one interactive
# bar for each reserve with a value, the hover text of each bar against
# tbl_01, no geometry.
#   rd     : map_qa_read() of the file
#   stem   : the name of the file without .html
#   t01    : tbl_01 as text; metric: the metric of the bars
# Returns a data frame: group, check, value, pass.
map_qa_chart <- function(rd, stem, t01, metric, fields = MAP_FIG01_HOVER,
                         max_bytes = MAP_MAX_BYTES) {
  out <- list()
  add <- function(group, check, value, pass) {
    out[[length(out) + 1L]] <<- data.frame(
      group = group, check = check, value = as.character(value),
      pass = isTRUE(pass), stringsAsFactors = FALSE)
  }
  one <- length(rd$ids) == 1L && identical(rd$ids, stem)
  add("file", "one widget in the file, with the id of the file",
      paste(length(rd$ids), "widget(s)"), one)
  ext <- map_qa_external(rd$html)
  add("file", "self-contained: no script, style sheet, image or frame from another place",
      paste(length(ext), "reference(s)"), length(ext) == 0)
  add("file", "the size is at most MAP_MAX_BYTES (sz1)",
      paste(format(rd$bytes, big.mark = ","), "bytes"), rd$bytes <= max_bytes)
  add("file", "the MD5 of the file (read by check l of STEP 18.2)", rd$md5, TRUE)
  if (!one) return(do.call(rbind, out))
  j <- rd$json[[1]]
  svg <- as.character(j$x$html %||% "")
  el <- regmatches(svg, gregexpr("<[a-z]+\\b[^>]*\\bdata-id='[^']*'[^>]*>", svg,
                                 perl = TRUE))[[1]]
  ids <- sub("^.*\\bdata-id='([^']*)'.*$", "\\1", el, perl = TRUE)
  tips <- ifelse(grepl("\\btitle='", el, perl = TRUE),
                 sub("^.*\\btitle='([^']*)'.*$", "\\1", el, perl = TRUE), NA)
  has_v <- !is.na(suppressWarnings(as.numeric(t01[[metric]])))
  want <- as.character(t01$unit_id[has_v])
  add("bars", "one interactive bar for each reserve of tbl_01 with a value, with its unit_id",
      paste(length(ids), "bars;", sum(has_v), "reserves with a value"),
      length(ids) == sum(has_v) && setequal(ids, want) && !anyDuplicated(ids))
  bad <- 0L
  for (i in seq_along(ids)) {
    r <- match(ids[i], as.character(t01$unit_id))
    # ggiraph writes the hover text escaped twice in the SVG of the file.
    v <- if (is.na(tips[i])) c(.name = NA) else
      map_qa_tip_fields(map_qa_unescape(map_qa_unescape(tips[i])))
    ok <- !is.na(r) && identical(unname(v[".name"]), t01$unit_name[r]) &&
      identical(names(v)[-1], setdiff(fields, "unit_name"))
    if (!ok) bad <- bad + 1L
  }
  add("bars", "each bar has a hover text with the name of its reserve and the fields of MAP_FIG01_HOVER (hv1)",
      paste(bad, "of", length(ids), "not as tbl_01"), length(ids) > 0 && bad == 0)
  wp <- map_qa_points(j)
  add("coordinates", "no geometry in the file: no lng/lat object (Decision 29 point 14)",
      paste(nrow(wp$pts) + wp$bad, "objects"), nrow(wp$pts) == 0 && wp$bad == 0)
  txt <- c(map_qa_strings(j), map_qa_unescape(map_qa_unescape(tips[!is.na(tips)])))
  n_deg <- sum(grepl(SITE_QA_DEGREE_RE, txt, perl = TRUE))
  add("texts", "no text of the file holds a decimal degree (as check h)",
      paste(n_deg, "texts"), n_deg == 0)
  do.call(rbind, out)
}

# The hand-made case of STEP 19.2. Made-up values and files in a temporary
# folder only. Returns a data frame: check, pass.
map_qa_self_test <- function() {
  tmp <- tempfile("mapqa_"); dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))
  sq <- sf::st_sfc(sf::st_polygon(list(rbind(
    c(77.12346, 20.98765), c(77.3, 20.98765), c(77.3, 21.2),
    c(77.12346, 21.2), c(77.12346, 20.98765)))), crs = CRS_WGS84)
  allowed <- map_qa_keys(sq, 5L)
  bx <- c(77.12346, 20.98765, 77.3, 21.2)
  w <- leaflet::leaflet(elementId = "t_map",
                        options = leaflet::leafletOptions(minZoom = 4, maxZoom = 9)) |>
    leaflet::addProviderTiles(MAP_BASEMAP) |>
    leaflet::addPolygons(data = sq, label = "A: 1") |>
    leaflet::fitBounds(bx[1], bx[2], bx[3], bx[4]) |>
    htmlwidgets::onRender("function(el, x, data) {}",
                          data = list(b = bx, pad = 8L))
  f <- file.path(tmp, "t_map.html")
  map_save_widget(w, f, "t")
  meth <- c("addProviderTiles", "addPolygons")
  run <- function(path, ...) {
    q <- map_qa_leaflet(map_qa_read(path), "t_map", allowed, meth, max_zoom = 9, ...)
    stats::setNames(q$pass, paste(q$group, q$check))
  }
  ok <- run(f)
  html <- readChar(f, file.size(f), useBytes = TRUE)
  plant <- function(from, to, name) {
    p <- file.path(tmp, name)
    writeChar(sub(from, to, html, fixed = TRUE), p, eos = NULL, useBytes = TRUE)
    p
  }
  g <- function(r, pat) r[grepl(pat, names(r), fixed = TRUE)]
  r_pt  <- run(plant("77.3,77.3", "77.3,77.31", "p1.html"))
  r_dig <- run(plant("77.3,77.3", "77.3,77.300001", "p2.html"))
  r_deg <- run(plant('"A: 1"', '"A at 21.1234\u00b0 N"', "p3.html"))
  r_ext <- run(plant("</head>", "<script src=\"https://example.org/a.js\"></script></head>", "p4.html"))
  r_cal <- run(plant('"method":"addPolygons"', '"method":"addMarkers"', "p5.html"))
  r_big <- run(f, max_bytes = 10)
  # A chart file by hand: one bar, its hover text escaped twice as ggiraph
  # writes it.
  t01 <- data.frame(unit_id = c("1", "2"), unit_name = c("A", "B"),
                    v = c("5", NA), stringsAsFactors = FALSE)
  tip <- "&amp;lt;b&amp;gt;A&amp;lt;/b&amp;gt;&amp;lt;br&amp;gt;v: 5"
  chart <- function(extra = "", name) {
    p <- file.path(tmp, name)
    js <- jsonlite::toJSON(list(x = list(html = paste0(
      "<svg><rect id='e1' title='", tip, "' data-id='1'/></svg>"))),
      auto_unbox = TRUE)
    js <- sub("}}$", paste0(extra, "}}"), js)
    writeLines(c("<html><head></head><body>",
                 paste0('<script type="application/json" data-for="t_chart">', js,
                        "</script>"), "</body></html>"), p)
    p
  }
  q_ok <- map_qa_chart(map_qa_read(chart("", "c1.html")), "t_chart", t01, "v",
                       fields = c("unit_name", "v"))
  q_geo <- map_qa_chart(map_qa_read(chart(',"g":{"lng":[77],"lat":[21]}', "c2.html")),
                        "t_chart", t01, "v", fields = c("unit_name", "v"))
  tf <- map_qa_tip_fields("<b>A &amp; B</b><br>state: X<br>class: &gt;200")
  chk <- list(
    "read and check: a made-up map file passes each check" =
      length(ok) >= 10 && all(ok),
    "a point that is not a vertex of the layers is found" =
      !all(g(r_pt, "point of an allowed kind")),
    "a coordinate with more decimals than MAP_DIGITS is found" =
      !all(g(r_dig, "more decimals")),
    "a decimal degree in a text is found" =
      !all(g(r_deg, "decimal degree")),
    "a script from another place is found" =
      !all(g(r_ext, "self-contained")),
    "a call that is not on the list is found" =
      !all(g(r_cal, "MAP_QA_METHODS")),
    "a file over the size limit is found" =
      !all(g(r_big, "MAP_MAX_BYTES")),
    "chart: one bar with its id and its hover text passes; a lng/lat object is found" =
      all(q_ok$pass) && !all(q_geo$pass[q_geo$group == "coordinates"]),
    "hover text: the name and the fields, unescaped" =
      identical(unname(tf), c("A & B", "X", ">200")) &&
      identical(names(tf), c(".name", "state", "class"))
  )
  data.frame(check = names(chk),
             pass = vapply(chk, function(v) isTRUE(v), logical(1)),
             stringsAsFactors = FALSE, row.names = NULL)
}

# ---- The hand-made case of STEP 19.1 ----------------------------------------------------
# Made-up values and layers only, in a temporary folder; no file of the
# project is read or written. Returns a data frame: check, pass.
map_self_test <- function() {
  tmp <- tempfile("maptest_"); dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))
  # map_read_constants(): order, reuse, a missing name, a name twice.
  src <- file.path(tmp, "s.R")
  writeLines(c("A <- 2", "f <- function() stop('not run')",
               "B <- c(x = A * 3)", "if (FALSE) C <- 9", "D <- paste('a', 'b')"),
             src)
  k <- map_read_constants(src, c("A", "B", "D"))
  miss <- tryCatch({ map_read_constants(src, c("A", "C")); FALSE },
                   error = function(e) TRUE)
  writeLines(c("A <- 1", "A <- 2"), src)
  twice <- tryCatch({ map_read_constants(src, "A"); FALSE },
                    error = function(e) TRUE)
  # Rounding and keys.
  sq <- sf::st_sfc(sf::st_polygon(list(rbind(
    c(77.1234567, 20.9876543), c(77.3, 20.9876543), c(77.3, 21.2),
    c(77.1234567, 21.2), c(77.1234567, 20.9876543)))), crs = 4326)
  ln <- sf::st_sfc(sf::st_linestring(rbind(c(78.000004, 22.5), c(79.25, 23))),
                   crs = 4326)
  sq5 <- map_round_sfc(sq, 5L); ln5 <- map_round_sfc(ln, 5L)
  co <- sf::st_coordinates(sq5)
  keys <- c(map_sfc_keys(sq5, 5L), map_sfc_keys(ln5, 5L))
  # Bounds: a narrow box gets wider; outward rounding.
  pt <- sf::st_sfc(sf::st_point(c(80, 25)), crs = 4326)
  bn <- map_bounds(list(pt), min_span = 0.05, digits = 5L)
  pt2 <- sf::st_sfc(sf::st_multipoint(rbind(c(77.123451, 20.1),
                                           c(79.000001, 22))), crs = 4326)
  bn2 <- map_bounds(list(pt2), min_span = 0.05, digits = 5L)
  # Hover text: escape, NA, the fields.
  hv <- map_hover_html(data.frame(n = c("A<b>", "B"), v = c("1", NA),
                                  stringsAsFactors = FALSE), "n", "v")
  no_col <- tryCatch({ map_hover_html(data.frame(n = "A"), "n", "v"); FALSE },
                     error = function(e) TRUE)
  # Classes of fig_02.
  cls <- map_bin_pop(c(NA, 0, 1, 20, 21, 250), c(0, 1, 21, 51, 101, 201, Inf),
                     c("0 (real)", "1-20", "21-50", "51-100", "101-200", ">200"))
  # A leaflet widget and the check K1 (i).
  w <- leaflet::leaflet(elementId = "t") |>
    leaflet::addPolygons(data = sq5, label = "A") |>
    leaflet::addPolylines(data = ln5) |>
    leaflet::fitBounds(77, 20, 80, 24) |>
    htmlwidgets::onRender("function(el, x, data) {}",
                          data = list(b = c(77, 20, 80, 24), pad = 8L))
  pts <- map_widget_points(w)
  ok <- map_check_leaflet(w, keys, c(77, 20, 80, 24),
                          c("addPolygons", "addPolylines"), c("A", "B"),
                          digits = 5L)
  bad_key <- map_check_leaflet(w, keys[-1], c(77, 20, 80, 24),
                               c("addPolygons", "addPolylines"), "A",
                               digits = 5L)
  bad_call <- map_check_leaflet(w, keys, c(77, 20, 80, 24), "addPolygons",
                                "A", digits = 5L)
  bad_text <- map_check_leaflet(w, keys, c(77, 20, 80, 24),
                                c("addPolygons", "addPolylines"),
                                "at 21.1234° N", digits = 5L)
  w6 <- leaflet::leaflet(elementId = "t6") |>
    leaflet::addPolylines(data = ln) |>
    leaflet::fitBounds(77, 20, 80, 24) |>
    htmlwidgets::onRender("function(el, x, data) {}",
                          data = list(b = c(77, 20, 80, 24), pad = 8L))
  bad_dig <- map_check_leaflet(w6, map_sfc_keys(ln, 5L), c(77, 20, 80, 24),
                               "addPolylines", "A", digits = 5L)
  # The save: written, then the same bytes (the same time stamp), then the
  # size limit.
  f <- file.path(tmp, "w.html")
  s1 <- map_save_widget(w, f, "t")
  t1 <- file.info(f)$mtime
  Sys.sleep(1.1)
  s2 <- map_save_widget(w, f, "t")
  t2 <- file.info(f)$mtime
  too_big <- tryCatch({ map_save_widget(w, file.path(tmp, "x.html"), "t",
                                        max_bytes = 10); FALSE },
                      error = function(e) TRUE)
  html <- paste(readLines(f, warn = FALSE), collapse = "\n")
  chk <- list(
    "constants: the values in the order of the file; a value uses an earlier one" =
      identical(k$A, 2) && identical(k$B, c(x = 6)) && identical(k$D, "a b"),
    "constants: a missing name and a name assigned twice stop" =
      miss && twice,
    "rounding: 5 decimals; the type and the CRS stay" =
      isTRUE(all.equal(co[1, 1:2], c(X = 77.12346, Y = 20.98765))) &&
      inherits(sq5[[1]], "POLYGON") && sf::st_crs(sq5) == sf::st_crs(4326),
    "keys: the vertices of the polygon and the line, each once" =
      setequal(keys, c("77.12346,20.98765", "77.30000,20.98765",
                       "77.30000,21.20000", "77.12346,21.20000",
                       "78.00000,22.50000", "79.25000,23.00000")),
    "bounds: a narrow box gets the minimum span; rounded outward" =
      isTRUE(all.equal(bn, c(79.975, 24.975, 80.025, 25.025),
                       tolerance = 1e-12)) &&
      isTRUE(all.equal(bn2, c(77.12345, 20.1, 79.00001, 22),
                       tolerance = 1e-12)),
    "hover: the title in bold, a field line, NA, the escape" =
      identical(hv[1], "<b>A&lt;b&gt;</b><br>v: 1") &&
      identical(hv[2], "<b>B</b><br>v: NA") && no_col,
    "classes: NA, a real 0, the breaks" =
      identical(as.character(cls), c("No estimate", "0 (real)", "1-20", "1-20",
                                     "21-50", ">200")),
    "widget points: the 5 polygon and 2 line vertices" =
      nrow(pts) == 7L,
    "K1 (i): a widget of allowed points, calls and texts passes" =
      all(vapply(ok, isTRUE, logical(1))),
    "K1 (i): a point that is not allowed is found" =
      !isTRUE(bad_key[[2]]),
    "K1 (i): a call that is not on the list is found" =
      !isTRUE(bad_call[[1]]),
    "K1 (i): a decimal degree in a text is found" =
      !isTRUE(bad_text[[7]]),
    "K1 (i): a coordinate with more decimals than MAP_DIGITS is found" =
      !isTRUE(bad_dig[[3]]),
    "save: written, then the same (time stamp kept); a file over the limit stops" =
      identical(c(s1$status, s2$status), c("written", "same")) &&
      identical(t1, t2) && too_big,
    "save: one self-contained file, no script from another place" =
      !dir.exists(file.path(tmp, "lib")) &&
      !grepl("<script[^>]+src=\"(?!data:)", html, perl = TRUE)
  )
  data.frame(check = names(chk),
             pass = vapply(chk, function(v) isTRUE(v), logical(1)),
             stringsAsFactors = FALSE, row.names = NULL)
}
