# =============================================================================
# 12_build_maps.R  [STAGE 4 — THE STORY SITE, Weeks 19-20]
# The interactive figures of Decision 29 (2026-11-26): for each figure of
# SITE_MAPS, a self-contained HTML file site/widgets/<the stem of its PNG
# file>.html (nm1 of task 19.2), shown in a frame of its page (Decision 28
# R8; fr1). The PNG files stay the record in the repository (Decision 28 P1).
# This script writes no page and no file outside site/widgets/ (and, from
# task 19.4, its QA table).
#
# Decision 29: A1; B1; P4 with P4a; N1; S3 with Sf1; G2; C2; Q2; H3; T2; Z2;
#   D1; K1; the readings R11 and R13.
# Process choices of task 19.2 (2026-11-26): mt1, ch1, bm1, zm1, sc1, nm1,
#   lv1, fg1, fr1, hv1, rd1, ht1, sz1, vy1, ck1, rv1, ts1.
#
# STEPS:
#   STEP 19.1 (task 19.3)  the hand-made case (map_self_test()); the guards;
#              fig_01: the chart (ggiraph, ch1) from
#              tbl_01_reserve_growth.csv; fig_02: the map (leaflet, mt1 and
#              fg1) from the reserve layer and the state layer (tier T0), one
#              layer for each census round; for the map, the check K1 (i) of
#              Decision 29 point 13 on the widget object; the save of each
#              file (self-contained; the size limit of sz1; a write only if
#              the bytes change)
#   STEP 19.2 (task 19.4)  the QA of the saved files by a second path: K1
#              (ii) on the JSON of each file (the map_qa_* functions; the
#              hand-made case map_qa_self_test() first): for each file one
#              widget, self-contained, the size; for fig_02 each point
#              against the vertices of the two layers, the calls (no other
#              layer), the bounds, the zoom, the features of each layer,
#              the rounds, the hover texts and the colours against the
#              source (fs2); for fig_01 the bars and the hover texts
#              against tbl_01 and no geometry; no decimal degree in a text
#              -> outputs/tables/tbl_21_map_qa.csv (with the MD5 of each
#              file, for check l of STEP 18.2), then a stop if a check
#              fails
#
# RUN (sc1 of task 19.2): in a NEW R session with tiger-network.Rproj open
# (the .Rprofile pins PROJ_LIB; a fresh session avoids the PROJ clash):
#   source("scripts/11_build_site.R")   # STEP 18.1: the site files
#   source("scripts/12_build_maps.R")   # this script
# then in the RStudio Terminal, from the root of the repository:
#   quarto render site
# then source scripts/11_build_site.R again (STEP 18.2, the QA of the
# render; its check l reads tbl_21_map_qa.csv of STEP 19.2). The first run
# that writes tbl_21: see the NOTE of STEP 19.2 (one more render). A file is written only if its bytes change, so a
# second run changes no time stamp.
# A PUSH TO main THAT CHANGES site/** DEPLOYS THE SITE (Decision 28 d1).
# Commit site/ only after the QA of task 19.4 passes.
#
# SENSITIVE DATA (docs/sensitive-data-policy.md; Decision 29): fig_01 and
# fig_02 are tier T0. The script reads the three tables of SITE_VARS_TABLES
# (tbl_01, tbl_02, tbl_07) and the two layers of MAP_FIG02_LAYERS under
# data/processed/; it reads no tiger
# record, no model layer and no Gi* layer. The console shows names, counts
# and TRUE/FALSE only.
#
# INPUTS:  outputs/tables/tbl_01_reserve_growth.csv; tbl_02_regional_rollup.csv
#          and tbl_07_census_join_check.csv (the values of the captions, to
#          check that the chart and the map agree with them; mb1);
#          data/processed/stats_reserve_census_7755.gpkg and
#          boundary_states_7755.gpkg; scripts/05_growth_analysis.R (its
#          constants, parsed by map_read_constants(), not run).
# OUTPUTS: site/widgets/fig_01_growth_ranking.html and
#          site/widgets/fig_02_growth_animation.html (committed with the
#          site, after the QA of task 19.4).
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(sf)
  library(ggplot2)    # theme_tiger of scripts/05 calls ggplot2 by name
  library(ggiraph)
  library(leaflet)
  library(htmlwidgets)
})

source(here("R", "00_config.R"))
source(here("R", "00_functions_io.R"))         # read_vec()
source(here("R", "00_functions_sensitive.R"))  # assert_publishable_table()
source(here("R", "00_functions_site.R"))       # site_read_table(), site_fmt_values()
source(here("R", "00_functions_map.R"))

options(width = 120)
rule <- function(txt) cat("\n", strrep("=", 78), "\n", txt, "\n",
                          strrep("=", 78), "\n", sep = "")

# A named list of TRUE/FALSE: print the count; stop with the names that fail.
run_guards <- function(chk, label) {
  pass <- vapply(chk, isTRUE, logical(1))
  cat(label, ": ", sum(pass), " of ", length(pass), " pass\n", sep = "")
  if (!all(pass)) {
    stop(label, " failed:\n  - ",
         paste(names(chk)[!pass], collapse = "\n  - "), call. = FALSE)
  }
  invisible(TRUE)
}
fmt_n <- function(x) format(x, big.mark = ",", scientific = FALSE)

# ==============================================================================
# STEP 19.1 — the chart of fig_01 and the map of fig_02 (task 19.3)
# ==============================================================================
rule("STEP 19.1 — the chart of fig_01 and the map of fig_02 (task 19.3)")

# ---- The hand-made case first ------------------------------------------------------
st <- map_self_test()
print(st, right = FALSE, row.names = FALSE)
if (!all(st$pass)) {
  stop("The hand-made case of STEP 19.1 failed; no file was written.",
       call. = FALSE)
}

# ---- The guards --------------------------------------------------------------------
run_guards(map_check_config(), "MAP_* settings")
f01_name <- "fig_01_growth_ranking"
f02_name <- "fig_02_growth_animation"
src_t01 <- file.path(DIR_TABLES, paste0(MAP_FIG01_TABLE, ".csv"))
src_cap <- file.path(DIR_TABLES, paste0(SITE_VARS_TABLES, ".csv"))
names(src_cap) <- names(SITE_VARS_TABLES)
src_lay <- file.path(DIR_PROCESSED, MAP_FIG02_LAYERS)
names(src_lay) <- names(MAP_FIG02_LAYERS)
norm <- function(p) tolower(normalizePath(p, winslash = "/", mustWork = FALSE))
run_guards(list(
  "pandoc is available to rmarkdown (mt1)" = rmarkdown::pandoc_available(),
  "tbl_01_reserve_growth.csv is in outputs/tables/" = file.exists(src_t01),
  "the tables of the captions are in outputs/tables/; tbl_01 is the same file (mb1)" =
    all(file.exists(src_cap)) &&
    identical(MAP_FIG01_TABLE, SITE_VARS_TABLES[["t01"]]),
  "the two layers of fig_02 are in data/processed/" =
    all(file.exists(src_lay)),
  "scripts/05_growth_analysis.R exists (its constants)" =
    file.exists(MAP_GROWTH_SCRIPT),
  "SITE_MAPS holds the two files of this STEP" =
    all(paste0(c(f01_name, f02_name), ".html") %in% SITE_MAPS$file),
  "the output folder is site/widgets/" =
    identical(norm(MAP_OUT_DIR), norm(file.path(DIR_SITE, SITE_WIDGET_DIR)))
), "STEP 19.1 guards")
cat("versions: pandoc ", format(rmarkdown::pandoc_version()),
    " | leaflet ", format(utils::packageVersion("leaflet")),
    " | ggiraph ", format(utils::packageVersion("ggiraph")),
    " | gdtools ", format(utils::packageVersion("gdtools")),
    " | htmlwidgets ", format(utils::packageVersion("htmlwidgets")), "\n",
    sep = "")

k <- map_read_constants(MAP_GROWTH_SCRIPT, MAP_GROWTH_NAMES)
cat("constants read from scripts/05 (parsed, not run):", length(k), "of",
    length(MAP_GROWTH_NAMES), "\n")
run_guards(list(
  "RANK_METRIC of scripts/05 is SITE_VARS_METRIC (the numbers of the captions)" =
    identical(k$RANK_METRIC, SITE_VARS_METRIC)
), "constants")

# ---- fig_01: the chart (ch1) -----------------------------------------------------------
cat("\n--- fig_01: the chart ---\n")
t01 <- site_read_table(src_t01)
need <- unique(c("unit_id", "unit_name", "landscape_complex",
                 k$RANK_METRIC, MAP_FIG01_HOVER))
miss <- setdiff(need, names(t01))
if (length(miss) > 0) {
  stop("tbl_01_reserve_growth.csv has no column(s): ",
       paste(miss, collapse = ", "), call. = FALSE)
}
assert_publishable_table(t01, name = MAP_FIG01_TABLE)
# The values of the captions, as STEP 18.1 of scripts/11 writes them to
# site/_variables.yml (mb1): the chart and the map must agree with them.
vars_cap <- site_vars_growth(t01, site_read_table(src_cap[["t02"]]),
                             site_read_table(src_cap[["t07"]]))
d1 <- map_fig01_data(t01, k)
ch <- map_fig01_chart(d1, k, f01_name)
tip_fields <- setdiff(MAP_FIG01_HOVER, "unit_name")
run_guards(list(
  "one bar for each reserve with a value of RANK_METRIC" =
    d1$n_ranked == sum(!is.na(t01[[k$RANK_METRIC]])),
  "the bars and the reserves not ranked are the rows of tbl_01" =
    d1$n_ranked + d1$n_not_ranked == nrow(t01),
  "a hover text for each bar, with each field of MAP_FIG01_HOVER" =
    length(d1$ranked$tip) == d1$n_ranked &&
    all(vapply(tip_fields, function(f) {
      all(grepl(paste0("<br>", f, ": "), d1$ranked$tip, fixed = TRUE))
    }, logical(1))),
  "no decimal degree in a hover text" = all(map_text_ok(d1$ranked$tip)),
  "the counts and the reserves with no panel are those of the caption (mb1)" =
    identical(vars_cap[["fig01.n_ranked"]], fmt_n(d1$n_ranked)) &&
    identical(vars_cap[["fig01.n_not_ranked"]], fmt_n(d1$n_not_ranked)) &&
    identical(vars_cap[["fig01.no_panel"]],
              if (length(d1$no_panel) == 0) "none" else
                paste(d1$no_panel, collapse = ", ")),
  "the widget is a girafe chart with the fixed id of its file" =
    inherits(ch$widget, "girafe") &&
    identical(ch$widget$elementId, f01_name)
), "fig_01 checks")
f01 <- file.path(MAP_OUT_DIR, paste0(f01_name, ".html"))
s01 <- map_save_widget(ch$widget, f01, MAP_FIG01_TITLE, background = k$PAPER)
cat("bars:", d1$n_ranked, "| not ranked:", d1$n_not_ranked, "| panels:",
    d1$n_facets, "| SVG", MAP_FIG01_WIDTH_IN, "x", round(ch$height_in, 2),
    "in\n")
cat("panels:", paste(d1$facets, collapse = " | "), "\n")
cat("not ranked, no panel:", if (length(d1$no_panel) == 0) "none" else
      paste(d1$no_panel, collapse = ", "), "\n")
cat(basename(f01), ":", s01$status, ",", fmt_n(s01$bytes), "bytes\n")

# ---- fig_02: the map (mt1, fg1) ----------------------------------------------------------
cat("\n--- fig_02: the map ---\n")
res_all <- read_vec(src_lay[["reserves"]])
states  <- read_vec(src_lay[["states"]])
need2 <- c("unit_id", "unit_name", "state", "geometry_present",
           paste0("pop_", MAP_FIG02_ROUNDS))
miss2 <- setdiff(need2, names(res_all))
if (length(miss2) > 0) {
  stop(basename(src_lay[["reserves"]]), " has no field(s): ",
       paste(miss2, collapse = ", "), call. = FALSE)
}
has <- as.logical(res_all$geometry_present) & !sf::st_is_empty(res_all)
absent <- sort(res_all$unit_name[!has])
res <- sf::st_transform(res_all[has, c("unit_id", "unit_name", "state",
                                       paste0("pop_", MAP_FIG02_ROUNDS))],
                        CRS_WGS84)
sf::st_geometry(res) <- map_round_sfc(sf::st_geometry(res))
st4 <- map_round_sfc(sf::st_geometry(sf::st_transform(states, CRS_WGS84)))
assert_no_raw_points(res)
mp <- map_fig02_map(res, st4, k, f02_name)
cat("reserves read:", nrow(res_all), "| with a polygon:", nrow(res),
    "| not drawn (no polygon):", paste(absent, collapse = ", "), "\n")
run_guards(list(
  "the reserves with no polygon are fig02.not_drawn of the caption (tbl_07; mb1)" =
    identical(vars_cap[["fig02.not_drawn"]],
              if (length(absent) == 0) "none" else
                paste(sort(absent, method = "radix"), collapse = ", ")) &&
    identical(vars_cap[["fig02.n_not_drawn"]], fmt_n(length(absent))),
  "the map holds no text box: no addControl call (mb1)" =
    !any(vapply(mp$widget$x$calls, function(cl) identical(cl$method, "addControl"),
                logical(1))),
  "the legend heading holds the title; the attribution line holds the sources (T2)" =
    any(grepl(MAP_FIG02_TITLE, mp$texts, fixed = TRUE)) &&
    MAP_FIG02_SOURCES %in% mp$texts
), "fig_02 page text (mb1)")
cat("vertices (rounded, unique): reserves", fmt_n(length(map_sfc_keys(res))),
    "| states", fmt_n(length(map_sfc_keys(st4))), "\n")
run_guards(map_check_leaflet(mp$widget, mp$keys, mp$bounds, mp$methods,
                             mp$texts),
           "fig_02 K1 (i) (Decision 29 point 13)")
calls <- mp$widget$x$calls
polys <- Filter(function(cl) identical(cl$method, "addPolygons"), calls)
hook <- mp$widget$jsHooks$render[[1]]$data
lc <- Filter(function(cl) identical(cl$method, "addLayersControl"), calls)
class_ok <- vapply(MAP_FIG02_ROUNDS, function(yr) {
  pop <- suppressWarnings(as.numeric(res[[paste0("pop_", yr)]]))
  cls <- as.character(map_bin_pop(pop, k$POP_BREAKS, k$POP_LABELS))
  all(cls[is.na(pop)] == "No estimate") &&
    all(cls[!is.na(pop) & pop == 0] == k$POP_LABELS[1]) &&
    !any(cls[!is.na(pop)] == "No estimate")
}, logical(1))
run_guards(list(
  "two layers: the state lines, then the reserve outlines once, with the unit_id of each (fs2)" =
    length(polys) == 2L && is.null(polys[[1]]$args[[2]]) &&
    identical(as.character(unlist(polys[[2]]$args[[2]])),
              as.character(res$unit_id)),
  "a colour and a hover text for each reserve in each round (fs2)" =
    setequal(names(hook$fill), as.character(MAP_FIG02_ROUNDS)) &&
    setequal(names(hook$tip), as.character(MAP_FIG02_ROUNDS)) &&
    all(lengths(hook$fill) == nrow(res)) && all(lengths(hook$tip) == nrow(res)),
  "the layer shows the colours and the labels of the round MAP_FIG02_FIRST (fs2)" =
    identical(unlist(polys[[2]]$args[[4]]$fillColor),
              unlist(hook$fill[[as.character(MAP_FIG02_FIRST)]])) &&
    identical(as.character(unlist(polys[[2]]$args[[5]])),
              unlist(hook$tip[[as.character(MAP_FIG02_FIRST)]])),
  "the radio buttons list the round MAP_FIG02_FIRST first" =
    length(lc) == 1L &&
    identical(as.character(lc[[1]]$args[[1]][1]), as.character(MAP_FIG02_FIRST)),
  "each round: NA is 'No estimate', a real 0 is the first class" =
    all(class_ok),
  "each round: the classes count each reserve with a polygon once" =
    all(vapply(mp$classes, sum, numeric(1)) == nrow(res))
), "fig_02 checks")
cls_tab <- do.call(rbind, lapply(mp$classes, function(t) as.integer(t)))
colnames(cls_tab) <- names(mp$classes[[1]])
cat("reserves by class and round (counts):\n")
print(cls_tab[as.character(MAP_FIG02_ROUNDS), , drop = FALSE])
f02 <- file.path(MAP_OUT_DIR, paste0(f02_name, ".html"))
s02 <- map_save_widget(mp$widget, f02, MAP_FIG02_TITLE)
cat(basename(f02), ":", s02$status, ",", fmt_n(s02$bytes), "bytes",
    "| the maximum zoom:", MAP_MAX_ZOOM[[f02_name]], "\n")

# ---- Summary of STEP 19.1 ----------------------------------------------------------------
n_written <- sum(c(s01$status, s02$status) == "written")
cat("\nfiles written in this run:", n_written, "of 2 (a file that is the",
    "same is not written)\n")
rule("STEP 19.1 done.")

# ==============================================================================
rule("STEP 19.2 — the QA of the saved files, by a second path (K1 (ii); task 19.4)")
# Each saved file is read again (map_qa_read(): the JSON of the widget in
# the file), and the source layers and tbl_01 are read again. No object of
# STEP 19.1 is used but the constants of scripts/05 (the colours and the
# breaks of the source). The QA table holds counts, names, TRUE/FALSE and
# the MD5 of each file; no coordinate.
mqst <- map_qa_self_test()
print(mqst, right = FALSE, row.names = FALSE)
if (!all(mqst$pass)) {
  stop("The hand-made case of STEP 19.2 failed; no QA table was written.",
       call. = FALSE)
}
qa <- data.frame(file = "test case", group = "test case",
                 check = c(paste("STEP 19.1:", map_self_test()$check),
                           paste("STEP 19.2:", mqst$check)),
                 value = "pass", stringsAsFactors = FALSE)
qa$pass <- c(map_self_test()$pass, mqst$pass)
qa$value[!qa$pass] <- "fail"
add_file <- function(q, file) {
  rbind(qa, data.frame(file = file, q[, c("group", "check", "value", "pass")],
                       stringsAsFactors = FALSE))
}
# fig_01: the chart (no geometry; the bars and the hover texts against
# tbl_01).
t01_qa <- site_read_table(src_t01)
qa <- add_file(map_qa_chart(map_qa_read(f01), f01_name, t01_qa,
                            SITE_VARS_METRIC), basename(f01))
# fig_02: the map (each point against the vertices of the two layers; the
# layers, the rounds, the hover texts and the colours against the source).
res_qa <- read_vec(src_lay[["reserves"]])
states_qa <- read_vec(src_lay[["states"]])
has_qa <- as.logical(res_qa$geometry_present) & !sf::st_is_empty(res_qa)
allowed_qa <- unique(c(map_qa_keys(res_qa[has_qa, ]), map_qa_keys(states_qa)))
rd02 <- map_qa_read(f02)
qa <- add_file(rbind(map_qa_leaflet(rd02, f02_name, allowed_qa,
                                    MAP_QA_METHODS[[f02_name]]),
                     map_qa_fig02(rd02, res_qa, states_qa, k)),
               basename(f02))
qa_file <- file.path(DIR_TABLES, sprintf("tbl_%02d_%s.csv", MAP_QA_TABLE_NN,
                                         MAP_QA_TABLE_SLUG))
qa_new <- !file.exists(qa_file)
write_table(qa, MAP_QA_TABLE_NN, MAP_QA_TABLE_SLUG)
for (fl in unique(qa$file[qa$group != "test case"])) {
  q <- qa[qa$file == fl, ]
  cat("\n", fl, "\n", sep = "")
  cat(sprintf("  %-5s  %-11s  %s [%s]\n", ifelse(q$pass, "TRUE", "FALSE"),
              q$group, q$check, q$value), sep = "")
}
cat("\nQA of STEP 19.2: ", sum(qa$pass), " of ", nrow(qa), " pass (",
    sum(qa$group == "test case"), " of them hand-made checks)\n", sep = "")
if (qa_new) {
  cat("NOTE: ", basename(qa_file), " is a new table. The list of all tables ",
      "of the Data page does not hold it yet: after the render, source ",
      "scripts/11 (STEP 18.1 writes the list again), render again, and ",
      "source scripts/11 once more for STEP 18.2.\n", sep = "")
}
if (!all(qa$pass)) {
  stop("STEP 19.2: ", sum(!qa$pass), " check(s) fail (see ", basename(qa_file),
       "). Do not commit site/.", call. = FALSE)
}
rule(paste("STEP 19.2 done: the QA of the map files passes. Next: quarto render",
           "site (Terminal); then source scripts/11_build_site.R (STEP 18.2)."))
