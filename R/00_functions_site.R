# =============================================================================
# 00_functions_site.R
# The site functions of Decision 28 (2026-11-21) for Stage 4, Week 18.
# scripts/11_build_site.R sources this file (process choice f1 of task 18.4).
# The settings are the SITE_* values of R/00_config.R; no value of the
# analysis is written here as a literal.
#
# Task 18.5 (2026-11-21): STEP 18.1 — the copies, the table files and the
# publish check before each write (Decision 28 points 1, 2, 6 and 8;
# process choices n1, l1, w2, d1, t1, h1 of task 18.4).
#   site_check_config()     the SITE_* block: a named list of TRUE/FALSE
#   site_path()             a path in site/ from its parts
#   site_read_table()       a committed CSV file, each field as text
#   site_fmt_values()       the numbers of a table on a page (d1)
#   site_md_escape()        the text of a cell for a pipe table
#   site_md_table()         a pipe table (the lines), in a responsive div
#   site_table_block()      the lines of an include file: the table and the
#                           link to the full CSV file
#   site_links_block()      the lines of the link list of a page
#   site_links_all()        the lines of the list of all committed tables
#   site_shift_headings()   each Markdown heading down by n levels
#   site_check_suppressed() the check of Decision 22 point 9 on a page table
#   site_scan_files()       the files in site/ that the check refuses
#   site_page_refs()        the figures and the include files that a page
#                           holds
#   site_write_if_changed() write lines only if the file differs
#   site_copy_if_changed()  copy a file only if the copy differs (MD5)
#   site_self_test()        the hand-made case of STEP 18.1 (h1)
#
# SENSITIVE DATA (docs/sensitive-data-policy.md; Decision 28 point 8): the
# functions read committed outputs only (outputs/figures, outputs/tables).
# No function reads a file under data/. A table on a page passes
# assert_publishable_table() (R/00_functions_sensitive.R) before it is
# written. The functions print nothing; the script prints names and counts.
# =============================================================================

# ---- The SITE_* block --------------------------------------------------------
site_check_config <- function() {
  pages <- names(SITE_PAGES)
  tp <- vapply(SITE_TABLES_PAGE, function(x) x$page, character(1))
  list(
    "SITE_PAGES: named, unique keys and files, each file a .qmd" =
      !is.null(pages) && !anyDuplicated(pages) &&
      !anyDuplicated(SITE_PAGES) && all(grepl("\\.qmd$", SITE_PAGES)),
    "SITE_FIGURES: unique files; each page a key of SITE_PAGES; kind chart or map" =
      !anyDuplicated(SITE_FIGURES$file) &&
      all(SITE_FIGURES$page %in% pages) &&
      all(SITE_FIGURES$kind %in% c("chart", "map")),
    "SITE_FIGURES: no file name holds 'tiger'" =
      !any(grepl("tiger", SITE_FIGURES$file, ignore.case = TRUE)),
    "SITE_TABLES_PAGE: named; each page a key; each has columns" =
      !is.null(names(SITE_TABLES_PAGE)) && all(tp %in% pages) &&
      all(vapply(SITE_TABLES_PAGE, function(x) length(x$columns) > 0,
                 logical(1))),
    "SITE_TABLES_LINK: unique names; each page a key; not also on a page" =
      !anyDuplicated(SITE_TABLES_LINK$name) &&
      all(SITE_TABLES_LINK$page %in% pages) &&
      !any(SITE_TABLES_LINK$name %in% names(SITE_TABLES_PAGE)),
    "SITE_NOTES: each page a key" = all(SITE_NOTES$page %in% pages),
    "SITE_SUPPRESSED_TABLES: each is a table on a page" =
      all(SITE_SUPPRESSED_TABLES %in% names(SITE_TABLES_PAGE)),
    "SITE_TABLE_MAX_ROWS and SITE_SIGNIF: whole numbers above 0" =
      SITE_TABLE_MAX_ROWS >= 1 && SITE_SIGNIF >= 1 &&
      SITE_TABLE_MAX_ROWS == round(SITE_TABLE_MAX_ROWS) &&
      SITE_SIGNIF == round(SITE_SIGNIF),
    "SITE_REPO_URL: an https URL with no trailing slash" =
      grepl("^https://", SITE_REPO_URL) && !grepl("/$", SITE_REPO_URL),
    "SITE_ALLOW_WIDGETS is FALSE in Week 18 (Decision 28 R9)" =
      identical(SITE_ALLOW_WIDGETS, FALSE),
    "SITE_BANNED_EXT holds csv, gpkg, tif and rds" =
      all(c("csv", "gpkg", "tif", "rds") %in% SITE_BANNED_EXT)
  )
}

# A path in site/ from its parts (site_dir: DIR_SITE, or a test folder).
site_path <- function(site_dir, ...) file.path(site_dir, ...)

# ---- Read and format ------------------------------------------------------------
# A committed CSV file with each field as text: "NA" is NA; an empty field
# stays ""; "<3" stays "<3". The column names are kept as they are.
site_read_table <- function(path) {
  if (!file.exists(path)) {
    stop("site_read_table(): file not found: ", path, call. = FALSE)
  }
  utils::read.csv(path, colClasses = "character", na.strings = "NA",
                  check.names = FALSE, stringsAsFactors = FALSE,
                  encoding = "UTF-8")
}

# The numbers of a table on a page (d1 of task 18.4). x: a character vector.
# A value that is a number: a whole number stays a whole number; another
# number gets `signif` significant digits, with no exponent. NA -> "NA". A
# value that is not a number (text, TRUE, FALSE, "<3", "") stays as it is.
site_fmt_values <- function(x, signif = SITE_SIGNIF) {
  out <- ifelse(is.na(x), "NA", x)
  num <- suppressWarnings(as.numeric(x))
  is_num <- !is.na(x) & !is.na(num) & is.finite(num) &
    !toupper(trimws(x)) %in% c("TRUE", "FALSE")
  for (i in which(is_num)) {
    v <- num[i]
    out[i] <- if (v == round(v)) {
      format(round(v), scientific = FALSE, trim = TRUE)
    } else {
      format(signif(v, signif), scientific = FALSE, trim = TRUE,
             drop0trailing = TRUE)
    }
  }
  out
}

# The text of a cell for a pipe table: no line break, "|" escaped.
site_md_escape <- function(x) {
  x <- gsub("[\r\n]+", " ", x)
  gsub("|", "\\|", x, fixed = TRUE)
}

# A pipe table from a data frame of text (already formatted). A column is
# right-aligned if each value that is not "NA" or "" is a number. The table
# is in a div of the class table-responsive (a wide table scrolls on a
# narrow screen). Returns the lines.
site_md_table <- function(df) {
  nm <- names(df)
  right <- vapply(df, function(v) {
    w <- v[!v %in% c("NA", "")]
    length(w) > 0 && all(!is.na(suppressWarnings(as.numeric(w))))
  }, logical(1))
  head <- paste0("| ", paste(site_md_escape(nm), collapse = " | "), " |")
  sep <- paste0("|", paste(ifelse(right, "---:", ":---"), collapse = "|"), "|")
  rows <- vapply(seq_len(nrow(df)), function(i) {
    paste0("| ", paste(site_md_escape(unlist(df[i, ], use.names = FALSE)),
                       collapse = " | "), " |")
  }, character(1))
  c("::: {.table-responsive}", "", head, sep, rows, "", ":::")
}

# The lines of the include file of a table on a page: the table, then the
# line with the counts and the link to the full CSV file.
site_table_block <- function(df_shown, name, n_cols_all, repo_url) {
  url <- paste0(repo_url, "/outputs/tables/", name, ".csv")
  c(site_md_table(df_shown), "",
    paste0("Rows: ", nrow(df_shown), ". Columns shown: ", ncol(df_shown),
           " of ", n_cols_all, ". Full table: [`", name, ".csv`](", url, ")."),
    "")
}

# The lines of the link list of a page: one item per table, with its rows.
# links: a data frame with name and rows.
site_links_block <- function(links, repo_url) {
  c(vapply(seq_len(nrow(links)), function(i) {
    paste0("- [`", links$name[i], ".csv`](", repo_url, "/outputs/tables/",
           links$name[i], ".csv) \u2014 ", format(links$rows[i], big.mark = ","),
           " rows")
  }, character(1)), "")
}

# The lines of the list of all committed tables: files, a character vector
# of file names in outputs/tables/ (sorted here in byte order, so that the
# file is the same in each locale).
site_links_all <- function(files, repo_url) {
  files <- sort(files, method = "radix")   # byte order in each locale
  c(paste0("Files: ", length(files), "."), "",
    paste0("- [`", files, "`](", repo_url, "/outputs/tables/", files, ")"),
    "")
}

# Each Markdown heading ("#" to "######" at the start of a line, then a
# space) goes down by n levels, to at most 6.
site_shift_headings <- function(lines, n = SITE_NOTES_HEADING_SHIFT) {
  hit <- grepl("^#{1,6} ", lines)
  for (i in which(hit)) {
    k <- attr(regexpr("^#+", lines[i]), "match.length")
    lines[i] <- paste0(strrep("#", min(6L, k + n)), substring(lines[i], k + 1))
  }
  lines
}

# ---- The checks ------------------------------------------------------------------
# Decision 22 point 9 on a table on a page. csv: the table as read (text);
# shown: the formatted table of the page (the same rows, the shown columns).
# Returns a named list of TRUE/FALSE.
site_check_suppressed <- function(csv, shown, mark = SITE_SUPPRESSED_MARK,
                                  cols_pattern = SITE_SUPPRESSED_COLS) {
  cols <- names(shown)
  in_csv <- vapply(cols, function(cn) sum(csv[[cn]] %in% mark), numeric(1))
  in_page <- vapply(cols, function(cn) sum(shown[[cn]] %in% mark),
                    numeric(1))
  kept <- all(vapply(cols, function(cn) {
    identical(which(csv[[cn]] %in% mark), which(shown[[cn]] %in% mark))
  }, logical(1)))
  sup_cols <- grep(cols_pattern, cols, value = TRUE)
  no_small <- all(vapply(sup_cols, function(cn) {
    !any(shown[[cn]] %in% c("1", "2"))
  }, logical(1)))
  list(
    "the same rows as the CSV file (no total row)" =
      nrow(shown) == nrow(csv),
    "each mark of the CSV file stays in its row" =
      kept && sum(in_csv) == sum(in_page),
    "no shown count column holds 1 or 2" = no_small
  )
}

# The files in site_dir that the check refuses (Decision 28 point 8): a
# banned file type, or (with no widgets allowed) a widget file. The render
# folders are not read. Returns the paths relative to site_dir.
site_scan_files <- function(site_dir, banned = SITE_BANNED_EXT,
                            allow_widgets = SITE_ALLOW_WIDGETS,
                            widget_ext = SITE_WIDGET_EXT,
                            skip = SITE_SKIP_DIRS) {
  f <- list.files(site_dir, recursive = TRUE, all.files = TRUE,
                  include.dirs = FALSE)
  top <- sub("/.*$", "", f)
  f <- f[!top %in% skip & !grepl("(^|/)(_site|\\.quarto|site_libs)/", f)]
  ext <- tolower(tools::file_ext(f))
  bad <- ext %in% banned
  if (!allow_widgets) bad <- bad | ext %in% widget_ext
  f[bad]
}

# The figures and the include files that a page holds. Returns a list:
# figures (file names in SITE_FIG_DIR) and includes (file names in
# SITE_TABLE_DIR).
site_page_refs <- function(page_path, fig_dir = SITE_FIG_DIR,
                           table_dir = SITE_TABLE_DIR) {
  txt <- readLines(page_path, warn = FALSE, encoding = "UTF-8")
  txt <- txt[!grepl("^\\s*<!--", txt)]
  fig_re <- paste0("\\]\\(", fig_dir, "/([^)\\s]+)\\)")
  figs <- unlist(regmatches(txt, gregexpr(fig_re, txt, perl = TRUE)))
  figs <- sub(paste0("^\\]\\(", fig_dir, "/"), "", sub("\\)$", "", figs))
  inc_re <- paste0("\\{\\{< include ", table_dir, "/([^ ]+) >\\}\\}")
  incs <- unlist(regmatches(txt, gregexpr(inc_re, txt, perl = TRUE)))
  incs <- sub(paste0("^\\{\\{< include ", table_dir, "/"), "",
              sub(" >\\}\\}$", "", incs))
  list(figures = figs, includes = incs)
}

# ---- Write and copy ---------------------------------------------------------------
# Write lines (UTF-8, LF) to path only if the file does not exist or its
# content differs. Returns "written" or "same". A file that is the same
# keeps its time stamp (STEP 18.2 compares the time stamps).
site_write_if_changed <- function(lines, path) {
  # The comparison is on the bytes (UTF-8): a text with a non-ASCII
  # character and the same text read from the file have different encoding
  # marks in R, so identical() on the two strings is FALSE.
  new <- charToRaw(enc2utf8(paste0(paste(lines, collapse = "\n"), "\n")))
  if (file.exists(path)) {
    old <- readBin(path, "raw", n = file.info(path)$size)
    if (identical(old, new)) return("same")
  }
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeBin(new, path)
  "written"
}

# Copy src to dst only if dst does not exist or its MD5 differs; then check
# the MD5 of the copy. Returns "copied" or "same".
site_copy_if_changed <- function(src, dst) {
  if (!file.exists(src)) {
    stop("site_copy_if_changed(): file not found: ", src, call. = FALSE)
  }
  md5 <- function(p) unname(tools::md5sum(p))
  if (file.exists(dst) && identical(md5(src), md5(dst))) return("same")
  dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
  ok <- file.copy(src, dst, overwrite = TRUE)
  if (!ok || !identical(md5(src), md5(dst))) {
    stop("site_copy_if_changed(): the copy of ", basename(src),
         " differs from its source.", call. = FALSE)
  }
  "copied"
}

# ---- The hand-made case of STEP 18.1 (h1 of task 18.4) ----------------------------
# Made-up values and files only, in a temporary folder. Returns a data
# frame: check, pass.
site_self_test <- function() {
  tmp <- tempfile("sitetest_"); dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))
  # d1: the numbers.
  v_in  <- c("3", "0.123456", "1234.567", NA, "<3", "TRUE", "-100",
             "1e-05", "", "text | with bar", "59.70", "-0.0004567")
  v_out <- site_fmt_values(v_in, 3L)
  v_exp <- c("3", "0.123", "1230", "NA", "<3", "TRUE", "-100", "0.00001",
             "", "text | with bar", "59.7", "-0.000457")
  # A made-up table and its expected lines.
  df <- data.frame(name = c("A", "B|C"), n = c("2", "10"),
                   share = c("0.5", "NA"), stringsAsFactors = FALSE)
  md <- site_md_table(df)
  md_exp <- c("::: {.table-responsive}", "",
              "| name | n | share |", "|:---|---:|---:|",
              "| A | 2 | 0.5 |", "| B\\|C | 10 | NA |", "", ":::")
  blk <- site_table_block(df, "tbl_99_test", 5L, "https://example.org/r")
  # The publish check of a table (assert_publishable_table()).
  refused <- function(x) {
    tryCatch({ assert_publishable_table(x, name = "test"); FALSE },
             error = function(e) TRUE)
  }
  ok_tab  <- data.frame(unit_name = "A", value = 1)
  bad_xy  <- data.frame(unit_name = "A", x = 1)
  bad_grd <- data.frame(unit_name = "A", grid10_x_km = 1)
  # Decision 22 point 9.
  csv <- data.frame(unit_name = c("A", "B", "C"),
                    tiger_1km_records = c("0", "<3", "5"),
                    other = c("1", "2", "3"), stringsAsFactors = FALSE)
  good <- csv
  lost <- csv; lost$tiger_1km_records[2] <- "2"
  total <- rbind(csv, data.frame(unit_name = "Total",
                                 tiger_1km_records = "7", other = "6"))
  s_good  <- site_check_suppressed(csv, good, "<3", "^tiger_")
  s_lost  <- site_check_suppressed(csv, lost, "<3", "^tiger_")
  s_total <- site_check_suppressed(csv, total, "<3", "^tiger_")
  # The scan of a site folder.
  sd <- file.path(tmp, "site"); dir.create(file.path(sd, "figures"),
                                           recursive = TRUE)
  dir.create(file.path(sd, "_site")); dir.create(file.path(sd, ".quarto"))
  writeLines("x", file.path(sd, "page.qmd"))
  writeLines("x", file.path(sd, "figures", "fig_99.png"))
  writeLines("x", file.path(sd, "_site", "page.html"))
  writeLines("x", file.path(sd, ".quarto", "cache.json"))
  scan_clean <- site_scan_files(sd, c("csv", "gpkg"), FALSE, c("html", "json"),
                                c("_site", ".quarto"))
  writeLines("x", file.path(sd, "figures", "layer.gpkg"))
  writeLines("x", file.path(sd, "map.html"))
  scan_bad <- site_scan_files(sd, c("csv", "gpkg"), FALSE, c("html", "json"),
                              c("_site", ".quarto"))
  # Write and copy only if changed; the time stamp of an unchanged file.
  f1 <- file.path(tmp, "a.md")
  w1 <- site_write_if_changed(c("x", "y \u2014 \u00e9"), f1)
  t1 <- file.info(f1)$mtime
  Sys.sleep(1.1)
  w2 <- site_write_if_changed(c("x", "y \u2014 \u00e9"), f1)
  t2 <- file.info(f1)$mtime
  w3 <- site_write_if_changed(c("x", "z"), f1)
  src <- file.path(tmp, "src.bin"); dst <- file.path(tmp, "out", "src.bin")
  writeBin(as.raw(0:255), src)
  c1 <- site_copy_if_changed(src, dst)
  c2 <- site_copy_if_changed(src, dst)
  # Headings and page references.
  hs <- site_shift_headings(c("# A", "## B", "text #1", "###### F"), 2L)
  pg <- file.path(tmp, "p.qmd")
  writeLines(c("<!-- ![x](figures/old.png) -->",
               "![label](figures/fig_01_a.png){fig-alt=\"t\"}", "",
               "{{< include tables/_tbl_01_a.md >}}", ""), pg)
  refs <- site_page_refs(pg, "figures", "tables")
  links <- site_links_block(data.frame(name = "tbl_99_b", rows = 3080),
                            "https://example.org/r")
  la <- site_links_all(c("b.csv", "a.md"), "https://example.org/r")
  chk <- list(
    "d1: whole numbers stay; others get 3 significant digits; text, NA, <3, TRUE stay" =
      identical(v_out, v_exp),
    "table: the expected pipe table, right-aligned numbers, '|' escaped" =
      identical(md, md_exp),
    "table block: the table, then rows, columns and the link" =
      identical(blk[length(blk) - 1],
                "Rows: 2. Columns shown: 3 of 5. Full table: [`tbl_99_test.csv`](https://example.org/r/outputs/tables/tbl_99_test.csv)."),
    "publish check: a plain table passes; an x column and a grid column are refused" =
      !refused(ok_tab) && refused(bad_xy) && refused(bad_grd),
    "Decision 22 point 9: a table with its marks passes" =
      all(unlist(s_good)),
    "Decision 22 point 9: a mark replaced by 2 is found" =
      !isTRUE(s_lost[[2]]) && !isTRUE(s_lost[[3]]),
    "Decision 22 point 9: a total row is found" = !isTRUE(s_total[[1]]),
    "scan: a clean folder gives no file; the render folders are not read" =
      length(scan_clean) == 0,
    "scan: a layer file and a widget file are found" =
      setequal(scan_bad, c("figures/layer.gpkg", "map.html")),
    "write: written, then the same (a non-ASCII text; time stamp kept), then written" =
      identical(c(w1, w2, w3), c("written", "same", "written")) &&
      identical(t1, t2),
    "copy: copied, then the same; the copy has the MD5 of its source" =
      identical(c(c1, c2), c("copied", "same")) &&
      identical(unname(tools::md5sum(src)), unname(tools::md5sum(dst))),
    "headings: down by 2 levels, at most 6; other lines stay" =
      identical(hs, c("### A", "#### B", "text #1", "###### F")),
    "page references: the figure and the include; a comment is not read" =
      identical(refs$figures, "fig_01_a.png") &&
      identical(refs$includes, "_tbl_01_a.md"),
    "link lists: the rows with a thousands mark; the files sorted" =
      identical(links[1], "- [`tbl_99_b.csv`](https://example.org/r/outputs/tables/tbl_99_b.csv) \u2014 3,080 rows") &&
      identical(la[3], "- [`a.md`](https://example.org/r/outputs/tables/a.md)")
  )
  data.frame(check = names(chk),
             pass = vapply(chk, function(v) isTRUE(v), logical(1)),
             stringsAsFactors = FALSE, row.names = NULL)
}

# =============================================================================
# Task 18.6 (2026-11-21): STEP 18.2 — the QA of the rendered site (Decision
# 28 point 8; process choices q1, x1, c1 and v1 of task 18.6). A SECOND PATH:
# the site_qa_* functions do not call the site_* functions of STEP 18.1; they
# read the rendered HTML with xml2 (x1) and the CSV files with read.csv().
#   site_qa_files()      the files of a folder (relative paths); the render
#                        folders left out
#   site_qa_fresh()      the render is newer than each file of site/
#   site_qa_page()       one rendered page: the images (with alt text and
#                        caption), the tables, the links, the text, the HTML
#   site_qa_csv()        a committed CSV file, each field as text
#   site_qa_self_test()  the hand-made case of STEP 18.2 (made-up files)
# =============================================================================

# The files of dir as paths relative to dir, with the top folders of skip
# left out.
site_qa_files <- function(dir, skip = c(SITE_OUT_DIR, ".quarto")) {
  f <- list.files(dir, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  f[!sub("/.*$", "", f) %in% skip]
}

# TRUE if <site_dir>/<out>/index.html is newer than each file of site_dir
# (the render folders left out). Returns list(fresh, reason).
site_qa_fresh <- function(site_dir, out = SITE_OUT_DIR) {
  idx <- file.path(site_dir, out, "index.html")
  if (!file.exists(idx)) {
    return(list(fresh = FALSE, reason = "no rendered site (no index.html)"))
  }
  f <- site_qa_files(site_dir, c(out, ".quarto"))
  mt <- file.mtime(file.path(site_dir, f))
  t_idx <- file.mtime(idx)
  late <- f[mt > t_idx]
  if (length(late) > 0) {
    return(list(fresh = FALSE, reason = paste0(
      length(late), " file(s) of site/ are newer than the render, for ",
      "example ", late[which.max(mt[mt > t_idx])])))
  }
  list(fresh = TRUE, reason = "")
}

# One rendered page (x1: xml2). Returns a list:
#   img    data frame: src, alt, caption (the figcaption of its figure)
#   tables list of list(header = text, cells = a character matrix)
#   links  the href of each link
#   text   the text of the body
#   html   the HTML as one text
site_qa_page <- function(path) {
  html <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"),
                collapse = "\n")
  doc <- xml2::read_html(path, encoding = "UTF-8")   # Quarto writes UTF-8
  imgs <- xml2::xml_find_all(doc, "//img")
  cap <- vapply(imgs, function(im) {
    fc <- xml2::xml_find_first(im, "ancestor::figure[1]//figcaption")
    if (inherits(fc, "xml_missing")) NA_character_ else
      trimws(xml2::xml_text(fc))
  }, character(1))
  img <- data.frame(src = xml2::xml_attr(imgs, "src"),
                    alt = xml2::xml_attr(imgs, "alt"),
                    caption = cap, stringsAsFactors = FALSE)
  tabs <- lapply(xml2::xml_find_all(doc, "//table"), function(tb) {
    hd <- trimws(xml2::xml_text(xml2::xml_find_all(tb, ".//thead//th")))
    rows <- xml2::xml_find_all(tb, ".//tbody/tr")
    cells <- do.call(rbind, lapply(rows, function(r) {
      trimws(xml2::xml_text(xml2::xml_find_all(r, "./td")))
    }))
    if (is.null(cells)) cells <- matrix(character(0), 0, length(hd))
    list(header = hd, cells = cells)
  })
  links <- xml2::xml_attr(xml2::xml_find_all(doc, "//a[@href]"), "href")
  body <- xml2::xml_find_first(doc, "//body")
  list(img = img, tables = tabs, links = links,
       text = if (inherits(body, "xml_missing")) "" else xml2::xml_text(body),
       html = html)
}

# A committed CSV file with each field as text ("NA" -> NA).
site_qa_csv <- function(path) {
  utils::read.csv(path, colClasses = "character", na.strings = "NA",
                  check.names = FALSE, stringsAsFactors = FALSE,
                  encoding = "UTF-8")
}

# The hand-made case of STEP 18.2. Made-up files only. Returns a data frame:
# check, pass.
site_qa_self_test <- function() {
  tmp <- tempfile("siteqa_"); dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE))
  sd <- file.path(tmp, "site"); out <- file.path(sd, "_site")
  dir.create(file.path(out, "figures"), recursive = TRUE)
  dir.create(file.path(sd, ".quarto"))
  writeLines("p", file.path(sd, "page.qmd"))
  writeLines("c", file.path(sd, ".quarto", "cache.json"))
  Sys.sleep(1.1)
  page <- c("<html><head><meta charset=\"utf-8\"></head><body><main>",
            "<figure class=\"figure\"><p><img src=\"figures/f.png\" alt=\"A map.\"></p>",
            "<figcaption>Static stand-in.</figcaption></figure>",
            "<p><img src=\"figures/g.png\" alt=\"\"></p>",
            "<table><thead><tr><th>unit_name</th><th>tiger_n</th></tr></thead>",
            "<tbody><tr><td>A</td><td>0</td></tr><tr><td>B</td><td>&lt;3</td></tr></tbody></table>",
            "<p><a href=\"https://example.org/r/outputs/tables/t.csv\">t</a> at 21.1234\u00b0 N</p>",
            "</main></body></html>")
  writeLines(page, file.path(out, "index.html"), useBytes = TRUE)
  writeLines("<html><body><iframe src=\"m.html\"></iframe></body></html>",
             file.path(out, "map.html"))
  pg <- site_qa_page(file.path(out, "index.html"))
  pw <- site_qa_page(file.path(out, "map.html"))
  fr1 <- site_qa_fresh(sd, "_site")
  Sys.sleep(1.1)
  writeLines("p2", file.path(sd, "page.qmd"))
  fr2 <- site_qa_fresh(sd, "_site")
  tb <- pg$tables[[1]]
  yml <- c("      - name: Set up Quarto", "        uses: quarto-dev/quarto-actions/setup@v2",
           "        with:", "          version: 1.10.18")
  ver_ok  <- any(grepl("^\\s*version:\\s*\"?1\\.10\\.18\"?\\s*$", yml))
  ver_bad <- any(grepl("^\\s*version:\\s*\"?1\\.10\\.18\"?\\s*$",
                       sub("1.10.18", "1.10.19", yml, fixed = TRUE)))
  chk <- list(
    "files: the render folders are not listed" =
      identical(site_qa_files(sd, c("_site", ".quarto")), "page.qmd"),
    "fresh: TRUE after the render; FALSE when a site file is newer" =
      isTRUE(fr1$fresh) && !isTRUE(fr2$fresh) && grepl("page.qmd", fr2$reason),
    "page: two images; the alt text and the caption of the first; none for the second" =
      nrow(pg$img) == 2 && identical(pg$img$alt[1], "A map.") &&
      identical(pg$img$caption[1], "Static stand-in.") &&
      identical(pg$img$alt[2], "") && is.na(pg$img$caption[2]),
    "page: the table header, its 2 rows and the mark <3 in row 2" =
      identical(tb$header, c("unit_name", "tiger_n")) && nrow(tb$cells) == 2 &&
      identical(which(tb$cells[, 2] == "<3"), 2L),
    "page: the link to the repository" =
      identical(pg$links, "https://example.org/r/outputs/tables/t.csv"),
    "positions: the degree text is found; 0.2 degrees, 0.123 NA and 0.456 are not" =
      grepl(SITE_QA_DEGREE_RE, pg$text, perl = TRUE) &&
      !grepl(SITE_QA_DEGREE_RE,
             "cells of 0.2\u00b0, a value of 0.123 NA and 0.456 in a table",
             perl = TRUE),
    "positions: grid10_x_km, lon and x are position columns; unit_name is not" =
      all(grepl(SITE_QA_POSITION_COLS, c("grid10_x_km", "lon", "x"),
                perl = TRUE)) &&
      !grepl(SITE_QA_POSITION_COLS, "unit_name", perl = TRUE),
    "widgets: a frame is found; the plain page has none" =
      grepl("<iframe|htmlwidget", pw$html, ignore.case = TRUE) &&
      !grepl("<iframe|htmlwidget", pg$html, ignore.case = TRUE),
    "version: the pinned line is found; another version is not" =
      ver_ok && !ver_bad
  )
  data.frame(check = names(chk),
             pass = vapply(chk, function(v) isTRUE(v), logical(1)),
             stringsAsFactors = FALSE, row.names = NULL)
}
