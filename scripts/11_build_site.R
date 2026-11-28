# =============================================================================
# 11_build_site.R  [STAGE 4 — THE STORY SITE, Week 18]
# The site files of Decision 28 (2026-11-21): the copies of the committed
# figures in site/figures/, the tables of the pages as Markdown include files
# in site/tables/, the link lists, and the publish check of Decision 28
# point 8 before each write. The pages (site/*.qmd) hold no R code (Decision
# 28 c1); this script writes no page and no file outside site/.
#
# Decision 28: a3 with t1 and m1; b3 with P1, S1 and n2; c1; d1; e1; f2; the
#   readings R7-R10. In Week 18 each figure is its PNG file as a stand-in
#   (S1); the interactive maps and chart of Week 19 replace them where the
#   rule of the pending item "Published layers" allows (R7).
#
# Process choices of task 18.4 (2026-11-21):
#   s1  this script: STEP 18.1 (task 18.5) and STEP 18.2 (task 18.6)
#   f1  the functions are in R/00_functions_site.R
#   n1  site/figures/<the same file name>; site/tables/_<name>.md
#   p1  the page of the check is site/check.qmd (in SITE_PAGES)
#   l1  the lists are the SITE_* values of R/00_config.R
#   w2  the columns shown on a page: SITE_TABLES_PAGE
#   d1  the numbers of a table on a page: site_fmt_values()
#   t1  the list of links to all committed tables: site/tables/_links_tables.md
#   m1  the marked places and the labels are in the pages
#   r1  the render: `quarto render site` in the RStudio Terminal
#   h1  the hand-made case runs first; a failure stops the script
#
# STEPS:
#   STEP 18.1 (task 18.5)  the hand-made case (site_self_test()); the guards
#              (the inputs, the pages and their references, the navbar);
#              the tables on a page (the columns of w2, the numbers of d1,
#              assert_publishable_table(), Decision 22 point 9) ->
#              site/tables/_<name>.md; the link lists ->
#              site/tables/_links_<page>.md; the notes ->
#              site/tables/_tbl_03_notes.md; the list of all committed
#              tables -> site/tables/_links_tables.md; the figures ->
#              site/figures/<file>; a scan of site/ (no banned file, no
#              widget, no file that is not on the lists)
#   (2026-11-26, task 19.3; Decision 29, ck1 and vy1 of task 19.2: STEP
#              18.1 also checks the frames of the maps of SITE_MAPS and the
#              PNG link of each of their figures, writes site/_variables.yml
#              (the numbers of the captions, and the names of mb1: the
#              reserves with no panel in fig_01 and with no polygon in
#              fig_02) from the committed tables, and
#              allows the files of SITE_MAPS in site/widgets/, which
#              scripts/12_build_maps.R writes.)
#   STEP 18.2 (task 18.6)  the QA of the rendered site/_site/, by a second
#              path (the site_qa_* functions; x1: xml2): it runs only if
#              site/_site/index.html is newer than each file of site/;
#              the hand-made case (site_qa_self_test()) first; the checks
#              a-j of c1 and check k of v1 (the pinned Quarto version) ->
#              outputs/tables/tbl_20_site_qa.csv (q1), then a stop if a
#              check fails
#   (2026-11-26, task 19.4; ck1 of task 19.2: the maps of SITE_MAPS. Check
#              b: each map is a frame on the page of its figure, once, with
#              the link to its figure file after it, and its file in
#              _site/widgets/ has the MD5 of the file in site/widgets/;
#              check c: each frame has a title and a description
#              (aria-describedby); checks a, f and g: the map files are
#              allowed; check i: no widget in a page itself and no frame
#              that is not on SITE_MAPS; a new check l: tbl_21_map_qa.csv
#              of STEP 19.2 passes and holds the MD5 of each map file.)
#
# RUN (r1 of task 18.4): in a NEW R session with tiger-network.Rproj open:
#   source("scripts/11_build_site.R")
# then in the RStudio Terminal, from the root of the repository:
#   quarto render site
# then source the script again: STEP 18.1 changes no file, and STEP 18.2 runs
# on the render. A file is written only if its content changes, so a second
# run changes no time stamp. The first time, tbl_20_site_qa.csv is a new
# table, so the list of all tables (the Data page) changes: source, render
# and source once more (the script says so).
# A PUSH TO main THAT CHANGES site/** DEPLOYS THE SITE (Decision 28 d1).
# Commit site/ only after the QA of task 18.6 passes.
#
# SENSITIVE DATA (docs/sensitive-data-policy.md; Decision 28 point 8): the
# script reads committed outputs only (outputs/figures/, outputs/tables/)
# and the pages; it reads no file under data/. A table on a page passes
# assert_publishable_table() before it is written. The console shows names,
# counts and TRUE/FALSE only.
#
# INPUTS:  outputs/figures/<SITE_FIGURES$file>; outputs/tables/<name>.csv of
#          SITE_TABLES_PAGE and SITE_TABLES_LINK; outputs/tables/
#          tbl_03_notes.md; the file names in outputs/tables/;
#          site/_quarto.yml and the pages of SITE_PAGES.
# OUTPUTS: site/figures/* and site/tables/_*.md (committed with the site);
#          outputs/tables/tbl_20_site_qa.csv (STEP 18.2).
# =============================================================================

suppressPackageStartupMessages({
  library(here)
})

source(here("R", "00_config.R"))
source(here("R", "00_functions_io.R"))         # write_table()
source(here("R", "00_functions_sensitive.R"))  # assert_publishable_table()
source(here("R", "00_functions_site.R"))

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

# The include file of a table, a link list or a note in site/tables/.
inc_name <- function(x) {
  if (length(x) == 0) return(character(0))  # paste0() makes "_.md" of nothing
  paste0(SITE_INCLUDE_PREFIX, x, ".md")
}

# ==============================================================================
# STEP 18.1 — the site files of Decision 28 (task 18.5)
# ==============================================================================
rule("STEP 18.1 — the site files of Decision 28 (task 18.5)")

# ---- h1: the hand-made case first ---------------------------------------------
st <- site_self_test()
print(st, right = FALSE, row.names = FALSE)
if (!all(st$pass)) {
  stop("The hand-made case of STEP 18.1 failed; no file was written.",
       call. = FALSE)
}

# ---- The guards --------------------------------------------------------------------
run_guards(site_check_config(), "SITE_* settings")

fig_src  <- file.path(DIR_FIGURES, SITE_FIGURES$file)
tab_src  <- file.path(DIR_TABLES, paste0(names(SITE_TABLES_PAGE), ".csv"))
lnk_src  <- file.path(DIR_TABLES, paste0(SITE_TABLES_LINK$name, ".csv"))
note_src <- file.path(DIR_TABLES, paste0(SITE_NOTES$name, ".md"))
all_src  <- c(fig_src, tab_src, lnk_src, note_src)
norm <- function(p) tolower(normalizePath(p, winslash = "/", mustWork = FALSE))
dir_fig_out <- file.path(DIR_SITE, SITE_FIG_DIR)
dir_tab_out <- file.path(DIR_SITE, SITE_TABLE_DIR)
page_paths  <- file.path(DIR_SITE, SITE_PAGES)
names(page_paths) <- names(SITE_PAGES)
yml_path <- file.path(DIR_SITE, "_quarto.yml")
yml <- if (file.exists(yml_path)) readLines(yml_path, warn = FALSE) else ""

# The references that each page must hold (Decision 28 point 1): its figures,
# and the include files of its tables, notes and link lists.
link_pages <- unique(SITE_TABLES_LINK$page)
want_refs <- lapply(names(SITE_PAGES), function(k) {
  incs <- c(inc_name(names(SITE_TABLES_PAGE)[vapply(
              SITE_TABLES_PAGE, function(x) x$page, character(1)) == k]),
            inc_name(SITE_NOTES$name[SITE_NOTES$page == k]),
            if (k %in% link_pages) inc_name(sprintf(SITE_LINKS_PAGE_FILE, k)),
            if (k == SITE_LINKS_ALL_PAGE) inc_name(SITE_LINKS_ALL_FILE))
  figs <- SITE_FIGURES$file[SITE_FIGURES$page == k]
  list(figures = figs,
       images = figs[!figs %in% SITE_MAPS$figure],     # S1: the stand-ins
       frames = SITE_MAPS$file[SITE_MAPS$figure %in% figs],   # fr1
       includes = as.character(incs))
})
names(want_refs) <- names(SITE_PAGES)
have_refs <- lapply(names(SITE_PAGES), function(k) {
  if (file.exists(page_paths[[k]])) site_page_refs(page_paths[[k]]) else NULL
})
names(have_refs) <- names(SITE_PAGES)
refs_ok <- function(part) {
  all(vapply(names(SITE_PAGES), function(k) {
    !is.null(have_refs[[k]]) &&
      !anyDuplicated(have_refs[[k]][[part]]) &&
      setequal(have_refs[[k]][[part]], want_refs[[k]][[part]])
  }, logical(1)))
}

run_guards(list(
  "each figure of SITE_FIGURES is in outputs/figures/" =
    all(file.exists(fig_src)),
  "each table of SITE_TABLES_PAGE and SITE_TABLES_LINK is in outputs/tables/" =
    all(file.exists(c(tab_src, lnk_src))),
  "each note file of SITE_NOTES is in outputs/tables/" =
    all(file.exists(note_src)),
  "each source is under outputs/ (no file under data/)" =
    all(startsWith(norm(all_src), paste0(norm(here("outputs")), "/"))) &&
    !any(startsWith(norm(all_src), paste0(norm(here("data")), "/"))),
  "site/_quarto.yml exists and its navbar holds each page of SITE_PAGES" =
    file.exists(yml_path) &&
    all(vapply(SITE_PAGES, function(p) {
      any(grepl(paste0("href: ", p), yml, fixed = TRUE))
    }, logical(1))),
  "each page of SITE_PAGES exists" = all(file.exists(page_paths)),
  "each page holds its figures, once each, and no other figure" =
    refs_ok("figures"),
  "each page holds its include files, once each, and no other include" =
    refs_ok("includes"),
  "each page shows each figure that is not on SITE_MAPS as an image (S1)" =
    refs_ok("images"),
  "each page holds the frame of each map of its figures, once, and no other frame (fr1)" =
    refs_ok("frames")
), "STEP 18.1 guards")

# ---- The tables on a page (Decision 28 point 2; w2, d1; point 8) --------------
cat("\n--- the tables on a page ---\n")
tab_log <- list()
for (nm in names(SITE_TABLES_PAGE)) {
  spec <- SITE_TABLES_PAGE[[nm]]
  csv  <- site_read_table(file.path(DIR_TABLES, paste0(nm, ".csv")))
  miss <- setdiff(spec$columns, names(csv))
  if (length(miss) > 0) {
    stop(nm, ": the column(s) ", paste(miss, collapse = ", "),
         " of SITE_TABLES_PAGE are not in the CSV file.", call. = FALSE)
  }
  if (nrow(csv) > SITE_TABLE_MAX_ROWS) {
    stop(nm, " has ", nrow(csv), " rows, more than SITE_TABLE_MAX_ROWS (",
         SITE_TABLE_MAX_ROWS, "): give it as a link (Decision 28 t1).",
         call. = FALSE)
  }
  raw <- csv[, spec$columns, drop = FALSE]
  # Point 8: the full table and the shown columns hold no position.
  assert_publishable_table(csv, name = nm)
  assert_publishable_table(raw, name = paste(nm, "(shown columns)"))
  shown <- as.data.frame(lapply(raw, site_fmt_values), check.names = FALSE,
                         stringsAsFactors = FALSE)
  n_mark <- NA_integer_
  if (nm %in% SITE_SUPPRESSED_TABLES) {
    run_guards(site_check_suppressed(raw, shown),
               paste0("Decision 22 point 9 (", nm, ")"))
    n_mark <- sum(vapply(shown, function(v) sum(v %in% SITE_SUPPRESSED_MARK),
                         numeric(1)))
  }
  out <- file.path(dir_tab_out, inc_name(nm))
  status <- site_write_if_changed(
    site_table_block(shown, nm, ncol(csv), SITE_REPO_URL), out)
  tab_log[[nm]] <- data.frame(table = nm, page = spec$page,
                              rows = nrow(csv), cols_shown = ncol(shown),
                              cols_all = ncol(csv), marks_kept = n_mark,
                              file = basename(out), status = status,
                              stringsAsFactors = FALSE)
}
print(do.call(rbind, tab_log), row.names = FALSE)

# ---- The link lists (t1) -----------------------------------------------------------
cat("\n--- the tables as links ---\n")
lnk <- SITE_TABLES_LINK
lnk$rows <- vapply(lnk$name, function(nm) {
  nrow(site_read_table(file.path(DIR_TABLES, paste0(nm, ".csv"))))
}, integer(1), USE.NAMES = FALSE)
if (any(lnk$rows <= SITE_TABLE_MAX_ROWS)) {
  stop("A link table has SITE_TABLE_MAX_ROWS rows or fewer (Decision 28 t1): ",
       paste(lnk$name[lnk$rows <= SITE_TABLE_MAX_ROWS], collapse = ", "),
       call. = FALSE)
}
lnk$status <- NA_character_
for (pg in unique(lnk$page)) {
  k <- lnk$page == pg
  out <- file.path(dir_tab_out, inc_name(sprintf(SITE_LINKS_PAGE_FILE, pg)))
  lnk$status[k] <- site_write_if_changed(site_links_block(lnk[k, ],
                                                          SITE_REPO_URL), out)
  lnk$file[k] <- basename(out)
}
print(lnk, row.names = FALSE)

# ---- The notes (Decision 28 point 1) -------------------------------------------------
cat("\n--- the notes ---\n")
for (i in seq_len(nrow(SITE_NOTES))) {
  nm  <- SITE_NOTES$name[i]
  src <- file.path(DIR_TABLES, paste0(nm, ".md"))
  lines <- site_shift_headings(readLines(src, warn = FALSE, encoding = "UTF-8"))
  out <- file.path(dir_tab_out, inc_name(nm))
  cat(nm, "->", basename(out), ":", length(lines), "lines,",
      site_write_if_changed(lines, out), "\n")
}

# ---- The list of all committed tables (t1; the Data page) ---------------------------
cat("\n--- the list of all committed tables ---\n")
all_tabs <- list.files(DIR_TABLES, all.files = FALSE, no.. = TRUE)
all_tabs <- all_tabs[!dir.exists(file.path(DIR_TABLES, all_tabs))]
out <- file.path(dir_tab_out, inc_name(SITE_LINKS_ALL_FILE))
cat("files in outputs/tables/ (no dot files):", length(all_tabs), "->",
    basename(out), ":", site_write_if_changed(site_links_all(all_tabs,
                                                            SITE_REPO_URL),
                                              out), "\n")

# ---- The numbers of the captions (vy1 of task 19.2; Decision 28 point 5) ----------------
cat("\n--- the numbers of the captions ---\n")
vars <- site_vars_growth(
  site_read_table(file.path(DIR_TABLES, paste0(SITE_VARS_TABLES[["t01"]], ".csv"))),
  site_read_table(file.path(DIR_TABLES, paste0(SITE_VARS_TABLES[["t02"]], ".csv"))),
  site_read_table(file.path(DIR_TABLES, paste0(SITE_VARS_TABLES[["t07"]], ".csv"))))
var_keys_used <- unique(unlist(lapply(have_refs, function(r) r$vars)))
run_guards(list(
  "each {{< var >}} key of each page is a key of the file" =
    all(var_keys_used %in% names(vars)),
  "no value holds a decimal degree" =
    !any(grepl(SITE_QA_DEGREE_RE, vars, perl = TRUE))
), "vy1 guards")
vfile <- file.path(DIR_SITE, SITE_VARIABLES_FILE)
v_status <- site_write_if_changed(site_variables_lines(vars), vfile)
cat(length(vars), "keys ->", basename(vfile), ":", v_status,
    "| keys that the pages use:", length(var_keys_used), "\n")

# ---- The figures (P1, S1) -------------------------------------------------------------
cat("\n--- the figures ---\n")
fig_log <- data.frame(file = SITE_FIGURES$file, page = SITE_FIGURES$page,
                      kind = SITE_FIGURES$kind,
                      bytes = file.size(fig_src), status = NA_character_,
                      stringsAsFactors = FALSE)
for (i in seq_len(nrow(fig_log))) {
  fig_log$status[i] <- site_copy_if_changed(
    fig_src[i], file.path(dir_fig_out, SITE_FIGURES$file[i]))
}
print(fig_log, row.names = FALSE)

# ---- The scan of site/ (Decision 28 point 8; R9) -------------------------------------
cat("\n--- the scan of site/ ---\n")
banned <- site_scan_files(DIR_SITE)
want_tab_files <- c(vapply(names(SITE_TABLES_PAGE), inc_name, character(1)),
                    inc_name(SITE_NOTES$name),
                    inc_name(sprintf(SITE_LINKS_PAGE_FILE, link_pages)),
                    inc_name(SITE_LINKS_ALL_FILE))
have_fig_files <- list.files(dir_fig_out, all.files = TRUE, no.. = TRUE)
have_tab_files <- list.files(dir_tab_out, all.files = TRUE, no.. = TRUE)
dir_wid_out <- file.path(DIR_SITE, SITE_WIDGET_DIR)
have_wid_files <- if (dir.exists(dir_wid_out)) {
  list.files(dir_wid_out, all.files = TRUE, no.. = TRUE)
} else character(0)
extra_fig <- setdiff(have_fig_files, SITE_FIGURES$file)
extra_tab <- setdiff(have_tab_files, want_tab_files)
extra_wid <- setdiff(have_wid_files, SITE_MAPS$file)
if (length(extra_fig) + length(extra_tab) + length(extra_wid) > 0) {
  cat("files that are not on the lists (remove them by hand):",
      paste(file.path(c(rep(SITE_FIG_DIR, length(extra_fig)),
                        rep(SITE_TABLE_DIR, length(extra_tab)),
                        rep(SITE_WIDGET_DIR, length(extra_wid))),
                      c(extra_fig, extra_tab, extra_wid)), collapse = ", "),
      "\n")
}
cat("site/", SITE_WIDGET_DIR, "/: ", length(have_wid_files), " of ",
    nrow(SITE_MAPS), " files of SITE_MAPS (scripts/12_build_maps.R writes ",
    "them)\n", sep = "")
run_guards(list(
  "no banned file type and no widget file in site/ (the render folders not read)" =
    length(banned) == 0,
  "site/figures/ holds the files of SITE_FIGURES and no other file" =
    setequal(have_fig_files, SITE_FIGURES$file),
  "site/tables/ holds the expected include files and no other file" =
    setequal(have_tab_files, want_tab_files),
  "site/widgets/ holds no file that is not on SITE_MAPS" =
    length(extra_wid) == 0,
  "each copy in site/figures/ has the MD5 of its source" =
    identical(unname(tools::md5sum(fig_src)),
              unname(tools::md5sum(file.path(dir_fig_out,
                                             SITE_FIGURES$file))))
), "STEP 18.1 scan")
if (length(banned) > 0) cat("refused:", paste(banned, collapse = ", "), "\n")

n_written <- sum(c(vapply(tab_log, function(x) x$status, character(1)),
                   lnk$status[!duplicated(lnk$page)],
                   v_status, fig_log$status) %in% c("written", "copied"))
cat("\nfiles written or copied in this run (tables, link lists, the",
    "variables, figures):", n_written, "\n")
rule("STEP 18.1 done.")

# ==============================================================================
# STEP 18.2 — the QA of the rendered site (task 18.6)
# ==============================================================================
rule("STEP 18.2 — the QA of the rendered site (task 18.6)")

out_dir <- file.path(DIR_SITE, SITE_OUT_DIR)
fr <- site_qa_fresh(DIR_SITE)
if (!fr$fresh) {
  cat("STEP 18.2 is not run: ", fr$reason, ".\n",
      "Render first (`quarto render site` in the RStudio Terminal), then ",
      "source this script again.\n", sep = "")
} else {
  # ---- The hand-made case first -------------------------------------------------
  qst <- site_qa_self_test()
  print(qst, right = FALSE, row.names = FALSE)
  if (!all(qst$pass)) {
    stop("The hand-made case of STEP 18.2 failed; no QA table was written.",
         call. = FALSE)
  }
  qa <- data.frame(group = character(0), check = character(0),
                   value = character(0), pass = logical(0),
                   stringsAsFactors = FALSE)
  add <- function(group, check, value, pass) {
    qa <<- rbind(qa, data.frame(group = group, check = check,
                                value = as.character(value),
                                pass = isTRUE(pass),
                                stringsAsFactors = FALSE))
  }
  for (i in seq_len(nrow(st))) {
    add("test case", paste("STEP 18.1:", st$check[i]),
        if (st$pass[i]) "pass" else "fail", st$pass[i])
  }
  for (i in seq_len(nrow(qst))) {
    add("test case", paste("STEP 18.2:", qst$check[i]),
        if (qst$pass[i]) "pass" else "fail", qst$pass[i])
  }
  md5_same <- function(a, b) {
    ok <- file.exists(a) & file.exists(b)
    ok[ok] <- unname(tools::md5sum(a[ok])) == unname(tools::md5sum(b[ok]))
    ok
  }

  # ---- The rendered pages (x1) -------------------------------------------------------
  html_files <- sub("\\.qmd$", ".html", SITE_PAGES)
  pages <- lapply(file.path(out_dir, html_files), function(p) {
    if (file.exists(p)) site_qa_page(p) else NULL
  })
  names(pages) <- names(SITE_PAGES)
  out_files <- site_qa_files(out_dir, character(0))
  in_lib <- startsWith(out_files, paste0(SITE_QA_LIB_DIR, "/"))

  # a. the pages (the map files of SITE_MAPS in widgets/ are not pages)
  map_paths <- file.path(SITE_WIDGET_DIR, SITE_MAPS$file)
  html_out <- out_files[grepl("\\.html?$", out_files) & !in_lib &
                          !out_files %in% map_paths]
  add("a pages", "each page of SITE_PAGES has its HTML file in _site/",
      paste(sum(html_files %in% out_files), "of", length(html_files)),
      all(html_files %in% out_files))
  add("a pages", "_site/ holds no other HTML page (site_libs/ not counted)",
      paste(length(setdiff(html_out, html_files)), "other"),
      length(setdiff(html_out, html_files)) == 0)

  # b. the images and the figures
  img_all <- do.call(rbind, lapply(names(pages), function(k) {
    p <- pages[[k]]
    if (is.null(p) || nrow(p$img) == 0) return(NULL)
    data.frame(page = k, p$img, stringsAsFactors = FALSE)
  }))
  if (is.null(img_all)) {
    img_all <- data.frame(page = character(0), src = character(0),
                          alt = character(0), caption = character(0))
  }
  img_found <- file.exists(file.path(out_dir, img_all$src))
  add("b images", "each image of each page is a file in _site/",
      paste(sum(img_found), "of", nrow(img_all)),
      nrow(img_all) > 0 && all(img_found))
  img_figs <- SITE_FIGURES[!SITE_FIGURES$file %in% SITE_MAPS$figure, ]
  pages_figs <- vapply(names(SITE_PAGES), function(k) {
    setequal(basename(img_all$src[img_all$page == k]),
             img_figs$file[img_figs$page == k]) &&
      !anyDuplicated(img_all$src[img_all$page == k])
  }, logical(1))
  add("b images",
      "each page shows its figures of SITE_FIGURES that are not on SITE_MAPS as images, once each, and no other image",
      paste(sum(pages_figs), "of", length(pages_figs), "pages"),
      all(pages_figs))
  f_src  <- file.path(DIR_FIGURES, SITE_FIGURES$file)
  f_out  <- file.path(out_dir, SITE_FIG_DIR, SITE_FIGURES$file)
  f_site <- file.path(DIR_SITE, SITE_FIG_DIR, SITE_FIGURES$file)
  add("b images",
      "each figure in _site/figures/ has the MD5 of its source in outputs/figures/",
      paste(sum(md5_same(f_out, f_src)), "of", length(f_src)),
      all(md5_same(f_out, f_src)))
  add("b images", "each copy in site/figures/ has the MD5 of its source",
      paste(sum(md5_same(f_site, f_src)), "of", length(f_src)),
      all(md5_same(f_site, f_src)))
  # b. the frames of the maps (ck1, task 19.4)
  fr_all <- do.call(rbind, lapply(names(pages), function(k) {
    p <- pages[[k]]
    if (is.null(p) || nrow(p$frames) == 0) return(NULL)
    data.frame(page = k, p$frames, stringsAsFactors = FALSE)
  }))
  if (is.null(fr_all)) {
    fr_all <- data.frame(page = character(0), src = character(0),
                         title = character(0), desc = character(0),
                         static = character(0))
  }
  map_page <- SITE_FIGURES$page[match(SITE_MAPS$figure, SITE_FIGURES$file)]
  fr_place <- vapply(seq_len(nrow(SITE_MAPS)), function(i) {
    sum(fr_all$src == map_paths[i] & fr_all$page == map_page[i]) == 1L &&
      sum(fr_all$src == map_paths[i]) == 1L
  }, logical(1))
  add("b frames",
      "each map of SITE_MAPS is a frame on the page of its figure, once",
      paste(sum(fr_place), "of", nrow(SITE_MAPS)), all(fr_place))
  fr_png <- vapply(seq_len(nrow(SITE_MAPS)), function(i) {
    s <- fr_all$static[fr_all$src == map_paths[i]]
    length(s) == 1L && identical(s, file.path(SITE_FIG_DIR, SITE_MAPS$figure[i])) &&
      file.exists(file.path(out_dir, s))
  }, logical(1))
  add("b frames",
      "each frame has a link to the file of its figure in figures/, after it",
      paste(sum(fr_png), "of", nrow(SITE_MAPS)), all(fr_png))
  m_out <- file.path(out_dir, map_paths)
  m_site <- file.path(DIR_SITE, map_paths)
  add("b frames",
      "each map file in _site/widgets/ has the MD5 of its file in site/widgets/",
      paste(sum(md5_same(m_out, m_site)), "of", length(m_out)),
      all(md5_same(m_out, m_site)))

  # c. the alt text and the caption
  alt_ok <- !is.na(img_all$alt) & nchar(trimws(img_all$alt)) > 0
  cap_ok <- !is.na(img_all$caption) & nchar(img_all$caption) > 0
  add("c alt text", "each image has an alt text",
      paste(sum(alt_ok), "of", nrow(img_all)), all(alt_ok))
  add("c alt text", "each image has a caption (the stand-in label)",
      paste(sum(cap_ok), "of", nrow(img_all)), all(cap_ok))
  fr_tc <- !is.na(fr_all$title) & nchar(trimws(fr_all$title)) > 0 &
    !is.na(fr_all$desc) & nchar(fr_all$desc) > 0
  add("c alt text",
      "each frame has a title and a description (the element of its aria-describedby)",
      paste(sum(fr_tc), "of", nrow(fr_all)), nrow(fr_all) > 0 && all(fr_tc))

  # d. the tables on a page, against their CSV files
  for (nm in names(SITE_TABLES_PAGE)) {
    spec <- SITE_TABLES_PAGE[[nm]]
    csv <- site_qa_csv(file.path(DIR_TABLES, paste0(nm, ".csv")))
    pg <- pages[[spec$page]]
    hit <- if (is.null(pg)) list() else
      Filter(function(tb) identical(tb$header, spec$columns), pg$tables)
    one <- length(hit) == 1
    cells <- if (one) hit[[1]]$cells else NULL
    rows_ok <- one && nrow(cells) == nrow(csv)
    first <- csv[[spec$columns[1]]]
    first_ok <- rows_ok &&
      identical(unname(cells[, 1]), ifelse(is.na(first), "NA", first))
    marks_ok <- rows_ok
    n_marks <- 0L
    if (rows_ok) {
      for (j in seq_along(spec$columns)) {
        a <- which(csv[[spec$columns[j]]] %in% SITE_SUPPRESSED_MARK)
        b <- which(cells[, j] == SITE_SUPPRESSED_MARK)
        n_marks <- n_marks + length(a)
        marks_ok <- marks_ok && identical(a, b)
      }
    }
    add("d tables",
        paste0(nm, ": one table on its page with the shown columns, the ",
               "rows of the CSV file, the first column in the CSV order, ",
               "each mark ", SITE_SUPPRESSED_MARK, " in its row"),
        if (one) paste0(nrow(cells), " rows, ", ncol(cells), " columns, ",
                        n_marks, " marks") else "no single table",
        one && rows_ok && first_ok && marks_ok)
  }

  # e. the links to the repository
  links <- unique(unlist(lapply(pages, function(p) p$links)))
  repo <- links[startsWith(links, paste0(SITE_REPO_URL, "/"))]
  rel <- substring(repo, nchar(SITE_REPO_URL) + 2)
  rel_ok <- file.exists(here(rel))
  add("e links", "each link to the repository names a file of the repository",
      paste0(sum(rel_ok), " of ", length(rel),
             if (any(!rel_ok)) paste0("; not found: ",
                                      paste(utils::head(rel[!rel_ok], 3),
                                            collapse = ", ")) else ""),
      length(rel) > 0 && all(rel_ok))

  # f. the files of _site/
  allowed <- c(html_files, file.path(SITE_FIG_DIR, SITE_FIGURES$file),
               map_paths, SITE_QA_QUARTO_FILES)
  extra <- out_files[!out_files %in% allowed & !in_lib]
  add("f _site",
      "_site/ holds only the pages, the listed figures, the map files of SITE_MAPS, site_libs/ and the files of Quarto",
      if (length(extra) == 0) "0 other files" else
        paste0(length(extra), " other: ", paste(utils::head(extra, 5),
                                                collapse = "; ")),
      length(extra) == 0)

  # g. site/ (a second path to the scan of STEP 18.1)
  s_files <- site_qa_files(DIR_SITE)
  s_ext <- tolower(tools::file_ext(s_files))
  s_bad <- s_files[s_ext %in% SITE_BANNED_EXT |
                     (s_ext %in% SITE_WIDGET_EXT & !s_files %in% map_paths)]
  add("g site/",
      "site/ holds no banned file type and no widget file that is not on SITE_MAPS (the render folders not read)",
      if (length(s_bad) == 0) paste(length(s_files), "files read") else
        paste(s_bad, collapse = "; "),
      length(s_bad) == 0)

  # h. no position
  pos_cols <- unlist(lapply(pages, function(p) {
    unlist(lapply(p$tables, function(tb) {
      grep(SITE_QA_POSITION_COLS, tb$header, value = TRUE, perl = TRUE)
    }))
  }))
  add("h positions", "no table on a page has a column of a position",
      paste(length(pos_cols), "columns"), length(pos_cols) == 0)
  deg <- names(pages)[vapply(pages, function(p) {
    !is.null(p) && grepl(SITE_QA_DEGREE_RE, p$text, perl = TRUE)
  }, logical(1))]
  add("h positions",
      "no page text holds a decimal degree with 3 or more decimals",
      if (length(deg) == 0) "0 pages" else paste(deg, collapse = ", "),
      length(deg) == 0)

  # i. the widgets (Decision 28 R9; Decision 29; ck1): no widget in a page
  # itself; each frame of each page is a map of SITE_MAPS
  wid <- names(pages)[vapply(pages, function(p) {
    !is.null(p) && p$widgets > 0
  }, logical(1))]
  add("i widgets", "no page holds a widget in the page itself (each map is a frame)",
      if (length(wid) == 0) "0 pages" else paste(wid, collapse = ", "),
      length(wid) == 0)
  fr_other <- unique(fr_all$src[!fr_all$src %in% map_paths])
  add("i widgets", "no page holds a frame that is not a map of SITE_MAPS",
      if (length(fr_other) == 0) "0 frames" else
        paste(utils::head(fr_other, 3), collapse = ", "),
      length(fr_other) == 0)

  # j. the list of all committed tables (the Data page)
  dl <- pages[[SITE_LINKS_ALL_PAGE]]$links
  listed <- basename(dl[startsWith(dl, paste0(SITE_REPO_URL,
                                              "/outputs/tables/"))])
  on_disk <- list.files(DIR_TABLES, all.files = FALSE, no.. = TRUE)
  on_disk <- on_disk[!dir.exists(file.path(DIR_TABLES, on_disk))]
  add("j tables list",
      "the Data page names each file of outputs/tables/ once",
      paste(length(unique(listed)), "listed;", length(on_disk), "on disk"),
      !anyDuplicated(listed) && setequal(listed, on_disk))

  # k. the Quarto version of the Action (v1)
  yml_a <- if (file.exists(SITE_PUBLISH_YML)) {
    readLines(SITE_PUBLISH_YML, warn = FALSE)
  } else character(0)
  pin_re <- paste0("^\\s*version:\\s*\"?",
                   gsub(".", "\\.", SITE_QUARTO_VERSION, fixed = TRUE),
                   "\"?\\s*$")
  add("k version",
      paste0("publish.yml pins the Quarto version of the QA render (v1)"),
      SITE_QUARTO_VERSION, any(grepl(pin_re, yml_a)))

  # l. the QA of the map files (STEP 19.2 of scripts/12; ck1, task 19.4)
  mq_file <- file.path(DIR_TABLES, sprintf("tbl_%02d_%s.csv", MAP_QA_TABLE_NN,
                                           MAP_QA_TABLE_SLUG))
  mq <- if (file.exists(mq_file)) site_qa_csv(mq_file) else NULL
  mq_pass <- !is.null(mq) && nrow(mq) > 0 && all(mq$pass == "TRUE")
  md5_row <- function(f) {
    if (is.null(mq)) return(NA_character_)
    v <- mq$value[mq$file == f & mq$group == "file" &
                    startsWith(mq$check, "the MD5 of the file")]
    if (length(v) == 1L) v else NA_character_
  }
  mq_md5 <- vapply(SITE_MAPS$file, md5_row, character(1))
  md5_now <- ifelse(file.exists(m_out), unname(tools::md5sum(m_out)), NA)
  mq_same <- !is.na(mq_md5) & !is.na(md5_now) & mq_md5 == md5_now
  add("l map QA",
      paste0(basename(mq_file), " passes, and it holds the MD5 of each map ",
             "file in _site/widgets/ (the QA is of these files)"),
      if (is.null(mq)) "no table" else
        paste0(sum(mq$pass == "TRUE"), " of ", nrow(mq), " pass; MD5 ",
               sum(mq_same), " of ", nrow(SITE_MAPS)),
      mq_pass && all(mq_same))

  # ---- The QA table (q1), then a stop if a check fails -------------------------------
  qa_file <- file.path(DIR_TABLES, sprintf("tbl_%02d_%s.csv", SITE_QA_TABLE_NN,
                                           SITE_QA_TABLE_SLUG))
  qa_new <- !file.exists(qa_file)
  write_table(qa, SITE_QA_TABLE_NN, SITE_QA_TABLE_SLUG)
  cat("\n")
  print(qa[qa$group != "test case", ], row.names = FALSE, right = FALSE)
  cat("\nQA of STEP 18.2: ", sum(qa$pass), " of ", nrow(qa), " pass (",
      sum(qa$group == "test case"), " of them hand-made checks)\n", sep = "")
  if (qa_new) {
    cat("NOTE: ", basename(qa_file), " is a new table. The list of all ",
        "tables of the Data page does not hold it yet. Source this script ",
        "again (STEP 18.1 writes the list again), render, and source it ",
        "once more.\n", sep = "")
  }
  if (!all(qa$pass)) {
    stop("STEP 18.2: ", sum(!qa$pass), " check(s) fail (see ",
         basename(qa_file), "). Do not commit site/.", call. = FALSE)
  }
  rule("STEP 18.2 done: the QA passes.")
}
