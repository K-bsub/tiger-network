# =============================================================================
# 00_functions_occ.R
# Occurrence records for Stage 3, Week 13 (Decision 21, docs/methodology.md).
# Sourced by scripts/08_prepare_occurrences.R; never run standalone.
#
# Task 13.2 (STEP 13.1): the read of the two GBIF SIMPLE_CSV files, the names
# report, the entry state and the raw counts.
# Task 13.3 (STEP 13.2; added 2026-10-11): the nine rule steps of Decision 21,
# the uncertainty sets, the obscured set, the presence cells, the outcome of
# point 8, the attrition tables and the dataset check of Amendment 2.
# Task 13.4 (STEP 13.3; added 2026-10-17): the taxa table of the background.
# The background uses the functions of task 13.3 (one rule for the two sets).
# Task 13.7 (STEP 13.5; added 2026-10-18): the hand-made case of the rule
# functions (process choice h1).
# Task 13.8 (STEP 13.6; added 2026-10-18): the reserve of each record and the
# suppression of small counts (Decision 22 point 9).
#
# Sensitive data (docs/sensitive-data-policy.md): a tiger record holds a
# precise position. No function here prints a coordinate. The tables hold
# counts and names only (occ_assert_counts_only()).
#
# Functions:
#   occ_zip_path()        key file -> path of the download zip
#   occ_zip_csv_name()    name of the one data file in the zip
#   occ_read_header()     field names of the data file (the first line)
#   occ_check_fields()    stop if a field of the rule is not in the header
#   occ_read_fields()     read the named fields, all as text
#   occ_parses_num()      TRUE if every value that is not empty is a number
#   occ_num()             text -> number; stop on a value that is not a number
#   occ_distinct()        distinct values of a field, "(none)" for no value
#   occ_split_flags()     the `issue` field -> one vector of flag names per
#                         record
#   occ_flag_names()      distinct flag names of a field
#   occ_flag_group()      flag names -> "remove", "report" or "other"
#   occ_names_report()    names stage: distinct values and checks, no count
#   occ_id_chr()          a record identifier as text (for a set comparison)
#   occ_entry_state()     step 0 of Decision 21: the scripts/01 filter
#   occ_uncert_levels()   the class labels of occ_uncert_bin()
#   occ_uncert_bin()      uncertainty -> class by the Decision-21 limits
#   occ_year_bin()        year -> class by the Decision-21 window
#   occ_raw_counts()      raw counts of the entry state, long table
#   occ_assert_counts_only()  stop if a table is not a plain count table
#   --- task 13.3 ---
#   occ_centroids()       centroids of India, the states and the districts
#   occ_near()            TRUE for a point within a distance of a feature
#   occ_stack_cells()     1 km cell of each point; complete-case or not
#   occ_step_fails()      one column per rule step: does the record fail it?
#   occ_first_fail()      the first step that a record fails (NA = kept)
#   occ_uncert_set()      "1km" or "5km" for a kept record
#   occ_cell02()          south-west corner of the 0.2 degree cell
#   occ_attrition()       records in, removed, out, by step
#   occ_by_dataset()      the same by dataset, long table
#   occ_point8_outcome()  Decision 21 point 8: the outcome for a cell count
#   occ_dataset_meta()    GBIF registry entry of a dataset (cached as JSON)
#   occ_dataset_text()    title and description text of a registry entry
#   occ_dataset_check()   Amendment 2: words about degraded positions
#   --- task 13.4 ---
#   occ_taxa_table()      clean background by order and family
#   --- task 13.7 ---
#   occ_self_test()       the hand-made case of the rule functions (h1)
#   --- task 13.8 ---
#   occ_reserve_index()   the reserve polygon(s) that hold each record
#   occ_reserve_overlaps() pairs of reserve polygons that overlap (km2)
#   occ_suppress_small()  a count of 1 to min_n - 1 -> "<min_n" (text)
#
# Base R, sf, terra, readr, dplyr (all_of() in occ_read_fields()) and
# jsonlite. No value is hardcoded: the calling script passes the OCC_*
# settings from R/00_config.R.
# =============================================================================

# ---- The download zip --------------------------------------------------------
# key_file : text file with the GBIF download key on line 1 (scripts/01)
# Returns the path of <key>.zip in the folder of the key file.
occ_zip_path <- function(key_file) {
  if (!file.exists(key_file)) {
    stop("Key file not found: ", key_file, ". Run scripts/01 (GBIF blocks).",
         call. = FALSE)
  }
  key <- trimws(readLines(key_file, n = 1, warn = FALSE))
  if (length(key) != 1L || !nzchar(key)) {
    stop("occ_zip_path(): no download key in ", key_file, ".", call. = FALSE)
  }
  zip <- file.path(dirname(key_file), paste0(key, ".zip"))
  if (!file.exists(zip)) {
    stop("Download zip not found: ", zip, ". Run scripts/01 (GBIF blocks).",
         call. = FALSE)
  }
  zip
}

# Name of the data file in a SIMPLE_CSV zip. The zip must hold one .csv file.
occ_zip_csv_name <- function(zip) {
  nm  <- utils::unzip(zip, list = TRUE)$Name
  csv <- nm[grepl("\\.csv$", nm, ignore.case = TRUE)]
  if (length(csv) != 1L) {
    stop("occ_zip_csv_name(): ", basename(zip), " holds ", length(csv),
         " .csv files; a SIMPLE_CSV download holds one.", call. = FALSE)
  }
  csv
}

# ---- Header and fields -------------------------------------------------------
# The first line of the data file, divided at the tab characters.
occ_read_header <- function(zip) {
  con <- unz(zip, occ_zip_csv_name(zip))
  on.exit(close(con))
  line <- readLines(con, n = 1, warn = FALSE, encoding = "UTF-8")
  if (length(line) != 1L || !nzchar(line)) {
    stop("occ_read_header(): no header line in ", basename(zip), ".",
         call. = FALSE)
  }
  # Remove a byte-order mark (U+FEFF) at the start of the line. The mark is
  # written as an escape: an editor cannot remove it without a visible change.
  line <- sub("^\ufeff", "", line)
  strsplit(line, "\t", fixed = TRUE)[[1]]
}

# Stop if a field that Decision 21 uses is not in the header. The message
# gives the action: a dated amendment of Decision 21 before any record is
# removed (Decision 21 point 1).
occ_check_fields <- function(header, need, set) {
  miss <- setdiff(need, header)
  if (length(miss) > 0) {
    stop("The ", set, " file does not have the field(s): ",
         paste(miss, collapse = ", "), ". Decision 21 needs a dated ",
         "amendment before any record is removed.", call. = FALSE)
  }
  invisible(TRUE)
}

# Read the named fields of the data file. Every field is text; an empty field
# is NA. The file has no quote characters with a meaning (quote = "", as
# scripts/01 Block 3).
occ_read_fields <- function(zip, fields) {
  csv <- occ_zip_csv_name(zip)
  out <- readr::read_tsv(
    unz(zip, csv),
    col_select     = dplyr::all_of(fields),
    col_types      = readr::cols(.default = readr::col_character()),
    quote          = "",
    na             = "",
    progress       = FALSE,
    show_col_types = FALSE,
    lazy           = FALSE
  )
  prob <- readr::problems(out)
  out  <- as.data.frame(out, stringsAsFactors = FALSE)
  if (nrow(prob) > 0) {
    stop("occ_read_fields(): ", nrow(prob), " read problem(s) in ",
         basename(zip), " (first: row ", prob$row[1], ", ", prob$actual[1],
         ").", call. = FALSE)
  }
  out[, fields, drop = FALSE]
}

# ---- Small helpers -----------------------------------------------------------
# TRUE if every value that is not NA is a number.
occ_parses_num <- function(x) {
  v <- suppressWarnings(as.numeric(x))
  !any(!is.na(x) & is.na(v))
}

# Text -> number. A value that is not empty and not a number stops the script.
occ_num <- function(x, field) {
  v   <- suppressWarnings(as.numeric(x))
  bad <- !is.na(x) & is.na(v)
  if (any(bad)) {
    stop("occ_num(): ", sum(bad), " value(s) of `", field,
         "` are not numbers.", call. = FALSE)
  }
  v
}

# Distinct values of a field, sorted; "(none)" stands for no value.
occ_distinct <- function(x) {
  v <- sort(unique(x[!is.na(x)]))
  if (anyNA(x)) c(v, "(none)") else v
}

# The `issue` field holds flag names divided by ";". Returns a list with one
# character vector per record (length 0 if the record has no flag).
occ_split_flags <- function(issue) {
  out <- strsplit(ifelse(is.na(issue), "", issue), ";", fixed = TRUE)
  lapply(out, function(f) {
    f <- trimws(f)
    f[nzchar(f)]
  })
}

# Distinct flag names of an `issue` field, sorted.
occ_flag_names <- function(issue) {
  sort(unique(unlist(occ_split_flags(issue), use.names = FALSE)))
}

# "remove" (OCC_ISSUE_REMOVE), "report" (OCC_ISSUE_REPORT) or "other".
occ_flag_group <- function(flags, remove, report) {
  ifelse(flags %in% remove, "remove", ifelse(flags %in% report, "report",
                                             "other"))
}

# ---- Names stage (STEP 13.1, stage "names") ------------------------------------
# Prints the distinct values of the rule fields of one file. It prints NO
# count of records. Returns a table of checks: set, check, result, detail.
# result is "ok" or "REVIEW". A "REVIEW" line is a possible amendment of
# Decision 21; the author decides.
#   dat           : from occ_read_fields() (the whole file)
#   set           : "tiger" or "background"
#   status_vocab  : the values that GBIF gives for occurrenceStatus
#   basis_vocab   : the values that GBIF gives for basisOfRecord
#   status_keep, basis_keep, issue_remove, issue_report, inat_key : OCC_* settings
#   flag_review_pattern : a flag with no rule and a name that matches this
#                         pattern is a "REVIEW" line
occ_names_report <- function(dat, set, status_vocab, basis_vocab, status_keep,
                             basis_keep, issue_remove, issue_report, inat_key,
                             flag_review_pattern) {
  chk <- list()
  add <- function(check, ok, detail = "") {
    chk[[length(chk) + 1L]] <<- data.frame(
      set = set, check = check, result = if (isTRUE(ok)) "ok" else "REVIEW",
      detail = detail, stringsAsFactors = FALSE)
  }
  show <- function(label, v) {
    cat(sprintf("  %-44s %s\n", label,
                if (length(v) == 0) "(none)" else paste(v, collapse = ", ")))
  }
  cat("\n--- ", set, ": distinct values (names only, no count) ---\n", sep = "")

  st <- occ_distinct(dat$occurrenceStatus)
  show("occurrenceStatus:", st)
  unk <- setdiff(st, c(status_vocab, "(none)"))
  add("occurrenceStatus values are in the GBIF vocabulary", length(unk) == 0,
      paste(unk, collapse = ", "))
  add("each OCC_STATUS_KEEP value is in the file", all(status_keep %in% st),
      paste(setdiff(status_keep, st), collapse = ", "))

  bs <- occ_distinct(dat$basisOfRecord)
  show("basisOfRecord:", bs)
  unk <- setdiff(bs, c(basis_vocab, "(none)"))
  add("basisOfRecord values are in the GBIF vocabulary", length(unk) == 0,
      paste(unk, collapse = ", "))
  add("one or more OCC_BASIS_KEEP values are in the file",
      any(basis_keep %in% bs), "")

  fl  <- occ_flag_names(dat$issue)
  grp <- occ_flag_group(fl, issue_remove, issue_report)
  show("issue flags, rule 'remove':", fl[grp == "remove"])
  show("issue flags, rule 'report':", fl[grp == "report"])
  show("issue flags, no rule:", fl[grp == "other"])
  show("'remove' flags not in file:", setdiff(issue_remove, fl))
  show("'report' flags not in file:", setdiff(issue_report, fl))
  bad_form <- fl[!grepl("^[A-Z][A-Z0-9_]*$", fl)]
  add("flag names have the form NAME_IN_CAPITALS", length(bad_form) == 0,
      paste(bad_form, collapse = ", "))
  rev <- fl[grp == "other" & grepl(flag_review_pattern, fl)]
  add("no flag about a coordinate is without a rule", length(rev) == 0,
      paste(rev, collapse = ", "))

  cat(sprintf("  %-44s %s\n", "year: all values numbers:",
              occ_parses_num(dat$year)))
  add("year values are numbers", occ_parses_num(dat$year))
  for (f in c("decimalLatitude", "decimalLongitude",
              "coordinateUncertaintyInMeters")) {
    ok <- occ_parses_num(dat[[f]])
    cat(sprintf("  %-44s %s\n", paste0(f, ": numbers:"), ok))
    add(paste0(f, " values are numbers"), ok)
  }

  uuid <- "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
  key_ok <- !anyNA(dat$datasetKey) && all(grepl(uuid, dat$datasetKey))
  add("each record has a datasetKey in the UUID form", key_ok)
  has_inat <- inat_key %in% dat$datasetKey
  cat(sprintf("  %-44s %s\n", "iNaturalist dataset in file:", has_inat))
  add("the iNaturalist dataset key is in the file", has_inat,
      if (has_inat) "" else "the obscured set will be empty")

  id_ok <- !anyNA(dat$gbifID) && !anyDuplicated(dat$gbifID)
  add("gbifID is complete and unique", id_ok)

  do.call(rbind, chk)
}

# ---- Entry state (Decision 21 point 1, step 0) -------------------------------
# A record identifier as text, so that two sources can be compared as sets.
# Works for text, 64-bit integer and double (a gbifID is below 2^53).
occ_id_chr <- function(x) {
  if (inherits(x, "integer64")) return(as.character(x))
  if (is.numeric(x)) return(ifelse(is.na(x), NA_character_, sprintf("%.0f", x)))
  trimws(as.character(x))
}

# The scripts/01 filter, repeated:
#   - a record with two coordinates;
#   - background only (year_min and year_max given): a year in the window;
#   - background only (exclude_species_key given): speciesKey is not that key
#     (a record with no speciesKey stays, as in scripts/01);
#   - inside the India polygon (the same sf subset as scripts/01).
# dat   : from occ_read_fields()
# india : the India polygon, sf, in the analysis CRS
# Returns a list: sf (points in the analysis CRS, with the fields of dat and
# the numeric fields lat, lon, year_num, uncert_m) and counts (a named
# integer vector). No coordinate is printed.
occ_entry_state <- function(dat, india, crs_in, year_min = NULL,
                            year_max = NULL, exclude_species_key = NULL) {
  dat$lat      <- occ_num(dat$decimalLatitude, "decimalLatitude")
  dat$lon      <- occ_num(dat$decimalLongitude, "decimalLongitude")
  dat$year_num <- occ_num(dat$year, "year")
  dat$uncert_m <- occ_num(dat$coordinateUncertaintyInMeters,
                          "coordinateUncertaintyInMeters")
  counts <- c(file_rows = nrow(dat))

  d <- dat[!is.na(dat$lat) & !is.na(dat$lon), , drop = FALSE]
  counts["with_coordinates"] <- nrow(d)

  if (!is.null(year_min) || !is.null(year_max) ||
      !is.null(exclude_species_key)) {
    if (is.null(year_min) || is.null(year_max) ||
        is.null(exclude_species_key)) {
      stop("occ_entry_state(): give year_min, year_max and ",
           "exclude_species_key together (the background filter).",
           call. = FALSE)
    }
    if (!"speciesKey" %in% names(d)) {
      stop("occ_entry_state(): the background filter needs `speciesKey`.",
           call. = FALSE)
    }
    keep <- !is.na(d$year_num) & d$year_num >= year_min &
      d$year_num <= year_max &
      (is.na(d$speciesKey) | d$speciesKey != as.character(exclude_species_key))
    d <- d[keep, , drop = FALSE]
    counts["after_year_and_taxon_filter"] <- nrow(d)
  }

  pts <- sf::st_as_sf(d, coords = c("lon", "lat"), crs = crs_in,
                      remove = FALSE)
  pts <- sf::st_transform(pts, sf::st_crs(india))
  pts <- pts[india, ]
  counts["entry_state"] <- nrow(pts)
  list(sf = pts, counts = counts)
}

# ---- Classes by the Decision-21 limits ---------------------------------------
# Uncertainty class. The classes do not overlap:
#   "(none)"            no value
#   "<=0"               zero or below
#   ">0 to <main>"      above 0, up to and including the main limit
#   "><main> to <wide>" above the main limit, up to and including the wide limit
#   "><wide> to <<obs>" above the wide limit, below the obscured minimum
#   ">=<obs>"           the obscured minimum or above
occ_uncert_levels <- function(main, wide, obscured) {
  c("(none)", "<=0", sprintf(">0 to %d", main),
    sprintf(">%d to %d", main, wide), sprintf(">%d to <%d", wide, obscured),
    sprintf(">=%d", obscured))
}
occ_uncert_bin <- function(u, main, wide, obscured) {
  if (!(main < wide && wide < obscured)) {
    stop("occ_uncert_bin(): the limits must be in the order main < wide < ",
         "obscured.", call. = FALSE)
  }
  lev <- occ_uncert_levels(main, wide, obscured)
  out <- rep(lev[1], length(u))
  ok  <- !is.na(u)
  out[ok & u <= 0]                       <- lev[2]
  out[ok & u > 0 & u <= main]            <- lev[3]
  out[ok & u > main & u <= wide]         <- lev[4]
  out[ok & u > wide & u < obscured]      <- lev[5]
  out[ok & u >= obscured]                <- lev[6]
  factor(out, levels = lev)
}

# Year class: "(none)", "<min", "min-max", ">max".
occ_year_bin <- function(y, year_min, year_max) {
  lev <- c("(none)", sprintf("<%d", year_min),
           sprintf("%d-%d", year_min, year_max), sprintf(">%d", year_max))
  out <- rep(lev[1], length(y))
  ok  <- !is.na(y)
  out[ok & y < year_min]                  <- lev[2]
  out[ok & y >= year_min & y <= year_max] <- lev[3]
  out[ok & y > year_max]                  <- lev[4]
  factor(out, levels = lev)
}

# ---- Raw counts of the entry state (STEP 13.1, stage "counts") -----------------
# x      : the sf of occ_entry_state() (or its attribute table)
# counts : the counts of occ_entry_state()
# Returns a long table: set, field, value, n. One row per value of each field
# that Decision 21 uses. For a field with one value per record the rows add up
# to the number of records in the entry state (checked here). The flag rows
# count the records with that flag, so they do not add up.
# The table holds no coordinate and no cell.
occ_raw_counts <- function(x, counts, set, year_min, year_max, issue_remove,
                           issue_report, uncert_main, uncert_wide,
                           uncert_obscured, inat_key) {
  d <- if (inherits(x, "sf")) sf::st_drop_geometry(x) else x
  n <- nrow(d)
  rows <- function(field, value, nn) {
    data.frame(set = set, field = field, value = as.character(value),
               n = as.integer(nn), stringsAsFactors = FALSE)
  }
  tab <- function(field, v, by_n = TRUE) {
    v <- if (is.factor(v)) v else ifelse(is.na(v), "(none)", as.character(v))
    t <- table(v, useNA = "no")
    if (by_n && !is.factor(v)) t <- t[order(-as.integer(t), names(t))]
    rows(field, names(t), as.integer(t))
  }

  out <- list(rows("records", names(counts), counts))
  out[[2]] <- tab("occurrenceStatus", d$occurrenceStatus)
  out[[3]] <- tab("basisOfRecord", d$basisOfRecord)
  out[[4]] <- tab("year", occ_year_bin(d$year_num, year_min, year_max))

  fl  <- occ_split_flags(d$issue)
  all <- unlist(fl, use.names = FALSE)
  ft  <- table(all)
  grp <- occ_flag_group(names(ft), issue_remove, issue_report)
  o   <- order(match(grp, c("remove", "report", "other")), -as.integer(ft),
               names(ft))
  ft  <- ft[o]
  grp <- grp[o]
  out[[5]] <- if (length(ft) > 0) {
    rows(paste0("issue_flag_", grp), names(ft), as.integer(ft))
  } else {
    rows(character(0), character(0), integer(0))
  }
  has_remove <- vapply(fl, function(f) any(f %in% issue_remove), logical(1))
  out[[6]] <- rows("issue_summary",
                   c("no_flag", "one_or_more_remove_flags"),
                   c(sum(lengths(fl) == 0L), sum(has_remove)))

  out[[7]] <- rows("coord_test", c("zero_zero", "lat_equals_lon"),
                   c(sum(d$lat == 0 & d$lon == 0), sum(d$lat == d$lon)))

  ub <- occ_uncert_bin(d$uncert_m, uncert_main, uncert_wide, uncert_obscured)
  out[[8]] <- tab("uncertainty_m", ub)

  is_inat <- !is.na(d$datasetKey) & d$datasetKey == inat_key
  out[[9]]  <- tab("dataset_group",
                   factor(ifelse(is_inat, "iNaturalist", "other"),
                          levels = c("iNaturalist", "other")))
  out[[10]] <- tab("inat_uncertainty_m", ub[is_inat])
  out[[11]] <- tab("datasetKey", d$datasetKey)

  res <- do.call(rbind, out)
  rownames(res) <- NULL

  # Each one-value field must add up to the entry state.
  for (f in c("occurrenceStatus", "basisOfRecord", "year", "uncertainty_m",
              "dataset_group", "datasetKey")) {
    s <- sum(res$n[res$field == f])
    if (s != n) {
      stop("occ_raw_counts(): field '", f, "' adds up to ", s, ", not to the ",
           n, " records of the entry state (", set, ").", call. = FALSE)
    }
  }
  if (sum(res$n[res$field == "inat_uncertainty_m"]) != sum(is_inat)) {
    stop("occ_raw_counts(): the iNaturalist rows do not add up (", set, ").",
         call. = FALSE)
  }
  res
}

# ---- Publish check for a count table -------------------------------------------
# outputs/tables/ is committed. A tbl_15 table holds counts and names only
# (Decision 21 point 10). Stop if x has a geometry, or columns that are not
# `cols` (in that order), or a column name that holds a position or a cell,
# or a number that is negative or NA (in the columns of `count_cols`).
occ_assert_counts_only <- function(x, cols = c("set", "field", "value", "n"),
                                   count_cols = "n", name = "table") {
  if (inherits(x, "sf")) {
    stop("Refusing to write ", name, ": it has a geometry column.",
         call. = FALSE)
  }
  if (!identical(names(x), cols)) {
    stop("Refusing to write ", name, ": its columns must be ",
         paste(cols, collapse = ", "), ".", call. = FALSE)
  }
  pos <- grepl(paste0("^(x|y|lon|lat|longitude|latitude|geom|geometry|cell|",
                      "cells)$|^cell_|cell02|_cell$"), tolower(names(x)))
  if (any(pos)) {
    stop("Refusing to write ", name, ": column(s) with a position or a cell: ",
         paste(names(x)[pos], collapse = ", "), ".", call. = FALSE)
  }
  for (f in count_cols) {
    v <- x[[f]]
    if (!is.numeric(v) || anyNA(v) || any(v < 0)) {
      stop("Refusing to write ", name, ": `", f, "` has a value that is NA, ",
           "negative or not a number.", call. = FALSE)
    }
  }
  invisible(x)
}

# =============================================================================
# Task 13.3 — STEP 13.2: Decision 21 on a set of records
# =============================================================================

# ---- Reference features for steps 7 and 8 -----------------------------------
# Centroids (Decision 21 step 7): the geometric centroid of each polygon of
# each layer, in the CRS of the layers (sf::st_centroid() on the geometry, so
# that no attribute warning is given).
#   layers : a named list of sf polygon layers (names: the level)
# Returns an sf of points with the field `level`.
occ_centroids <- function(layers) {
  out <- lapply(names(layers), function(lv) {
    g <- sf::st_geometry(layers[[lv]])
    g <- g[!sf::st_is_empty(g)]
    cen <- suppressWarnings(sf::st_centroid(g))
    sf::st_sf(data.frame(level = rep(lv, length(cen)),
                         stringsAsFactors = FALSE), geometry = cen)
  })
  do.call(rbind, out)
}

# TRUE for each feature of x that is within `dist` (map units) of one or more
# features of y. A distance equal to `dist` counts as within.
occ_near <- function(x, y, dist) {
  if (nrow(x) == 0) return(logical(0))
  if (nrow(y) == 0) return(rep(FALSE, nrow(x)))
  lengths(sf::st_is_within_distance(x, y, dist = dist)) > 0
}

# The 1 km cell of each point on the covariate stack, and whether it is a
# complete-case cell (a value in each band; Decision 10). A point outside the
# raster has cell NA and is not complete.
occ_stack_cells <- function(x, stack) {
  xy   <- sf::st_coordinates(x)[, 1:2, drop = FALSE]
  cell <- terra::cellFromXY(stack, xy)
  ok   <- !is.na(cell)
  complete <- rep(FALSE, nrow(xy))
  if (any(ok)) {
    v <- as.matrix(terra::extract(stack, cell[ok]))
    complete[ok] <- rowSums(is.na(v)) == 0
  }
  list(cell = as.integer(cell), complete = complete)
}

# ---- Rule steps (Decision 21 point 2) ------------------------------------------
# One logical column per step: TRUE = the record fails the step. Each column
# is computed on ALL records, independent of the order, so that a QA check can
# show that no kept record fails any step. The order is applied by
# occ_first_fail().
#   d          : attribute table of the entry state (occ_entry_state()), with
#                lat, lon, year_num, uncert_m
#   near_centroid, near_zoo, complete : logical vectors, one per record
occ_step_fails <- function(d, status_keep, basis_keep, year_min, year_max,
                           issue_remove, uncert_wide, near_centroid, near_zoo,
                           complete) {
  n  <- nrow(d)
  stopifnot(length(near_centroid) == n, length(near_zoo) == n,
            length(complete) == n)
  fl <- occ_split_flags(d$issue)
  has_remove <- vapply(fl, function(f) any(f %in% issue_remove), logical(1))
  u  <- d$uncert_m
  data.frame(
    status      = !(d$occurrenceStatus %in% status_keep),
    basis       = !(d$basisOfRecord %in% basis_keep),
    year        = is.na(d$year_num) | d$year_num < year_min |
                  d$year_num > year_max,
    coord_flags = has_remove | (d$lat == 0 & d$lon == 0) | (d$lat == d$lon),
    uncert_na   = is.na(u) | u <= 0,
    uncert      = !is.na(u) & u > uncert_wide,
    centroid    = near_centroid,
    zoo         = near_zoo,
    footprint   = !complete
  )
}

# The first step in `order` that each record fails; NA if it fails none.
occ_first_fail <- function(fails, order) {
  if (!identical(names(fails), order)) {
    stop("occ_first_fail(): the step columns must be in the order ",
         paste(order, collapse = ", "), ".", call. = FALSE)
  }
  m   <- as.matrix(fails)
  hit <- rowSums(m) > 0
  out <- rep(NA_character_, nrow(m))
  out[hit] <- order[max.col(m[hit, , drop = FALSE], ties.method = "first")]
  out
}

# "1km" (<= main) or "5km" (above main, <= wide) for a kept record.
occ_uncert_set <- function(u, main, wide) {
  if (anyNA(u) || any(u <= 0) || any(u > wide)) {
    stop("occ_uncert_set(): a kept record has no uncertainty or one above ",
         "the wide limit.", call. = FALSE)
  }
  ifelse(u <= main, "1km", "5km")
}

# South-west corner (degrees) of the cell of a `deg` grid that holds each
# point. The rounding to 9 decimals stops a value such as 77.2 / 0.2 from
# falling into the cell below.
occ_cell02 <- function(lon, lat, deg) {
  data.frame(cell02_lon_deg = floor(round(lon / deg, 9)) * deg,
             cell02_lat_deg = floor(round(lat / deg, 9)) * deg)
}

# ---- Attrition (tbl_15_occ_cleaning.csv) --------------------------------------
# One row per step, in order, after a row for the entry state: records in,
# removed, records out. The rows add up (checked).
occ_attrition <- function(removed_at, order, set) {
  n   <- length(removed_at)
  rem <- vapply(order, function(s) sum(removed_at %in% s), integer(1))
  out_n <- n - cumsum(rem)
  in_n  <- c(n, utils::head(out_n, -1))
  res <- data.frame(set = set, step_order = c(0L, seq_along(order)),
                    step = c("entry_state", order),
                    records_in = c(n, in_n), removed = c(0L, rem),
                    records_out = c(n, out_n), stringsAsFactors = FALSE)
  rownames(res) <- NULL
  if (res$records_out[nrow(res)] != sum(is.na(removed_at))) {
    stop("occ_attrition(): the steps do not add up (", set, ").",
         call. = FALSE)
  }
  res
}

# The same by dataset: set, datasetKey, item, n. Items: entry_state; removed at
# each step ("removed_<step>"); kept_1km, kept_5km; obscured. Each dataset has
# each item (n can be 0). For each dataset, entry_state = the removed items +
# kept_1km + kept_5km (checked); obscured is a part of removed_uncert.
occ_by_dataset <- function(datasetKey, removed_at, uncert_set, obscured, order,
                           set) {
  keys  <- sort(unique(datasetKey))
  items <- c("entry_state", paste0("removed_", order), "kept_1km", "kept_5km",
             "obscured")
  rows <- lapply(keys, function(k) {
    i <- datasetKey == k
    n <- c(sum(i),
           vapply(order, function(s) sum(i & removed_at %in% s), integer(1)),
           sum(i & is.na(removed_at) & uncert_set %in% "1km"),
           sum(i & is.na(removed_at) & uncert_set %in% "5km"),
           sum(i & obscured))
    if (n[1] != sum(n[2:(length(order) + 3)])) {
      stop("occ_by_dataset(): dataset ", k, " does not add up (", set, ").",
           call. = FALSE)
    }
    data.frame(set = set, datasetKey = k, item = items, n = as.integer(n),
               stringsAsFactors = FALSE)
  })
  res <- do.call(rbind, rows)
  rownames(res) <- NULL
  res
}

# ---- Decision 21 point 8 -------------------------------------------------------
occ_point8_outcome <- function(n_cells, min_model, min_full) {
  if (!(min_model < min_full)) {
    stop("occ_point8_outcome(): the limits must be min_model < min_full.",
         call. = FALSE)
  }
  if (n_cells < min_model) "no_1km_model"
  else if (n_cells < min_full) "reduced_model"
  else "planned_model"
}

# ---- Dataset check (Decision 21, Amendment 2) ----------------------------------
# The GBIF registry entry of each dataset, as a list. The first run reads it
# from the GBIF API and keeps the JSON text in cache_dir/<key>.json; a later
# run reads the file and needs no network. A failed read stops the script.
occ_dataset_meta <- function(keys, cache_dir,
                             api = "https://api.gbif.org/v1/dataset/") {
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  out <- lapply(keys, function(k) {
    f <- file.path(cache_dir, paste0(k, ".json"))
    if (!file.exists(f)) {
      ok <- tryCatch({
        utils::download.file(paste0(api, k), f, quiet = TRUE, mode = "wb",
                             method = "libcurl")
        TRUE
      }, error = function(e) FALSE, warning = function(w) FALSE)
      if (!ok || !file.exists(f) || file.size(f) == 0) {
        unlink(f)
        stop("occ_dataset_meta(): the GBIF registry entry of dataset ", k,
             " could not be read (", api, k, "). The first run needs the ",
             "network.", call. = FALSE)
      }
    }
    m <- jsonlite::fromJSON(f, simplifyVector = FALSE)
    if (!identical(m$key, k)) {
      stop("occ_dataset_meta(): ", basename(f), " is not the entry of ", k,
           ".", call. = FALSE)
    }
    m
  })
  stats::setNames(out, keys)
}

# Title and the text fields of a registry entry, in one string, with the HTML
# tags removed.
occ_dataset_text <- function(m) {
  parts <- c(m$title, m$description, m$purpose, m$additionalInfo,
             unlist(m$samplingDescription, use.names = FALSE))
  txt <- paste(as.character(unlist(parts, use.names = FALSE)), collapse = " ")
  txt <- gsub("<[^>]+>", " ", txt)
  gsub("[[:space:]]+", " ", txt)
}

# One row per dataset: the words of `words` (case is ignored; a word is a
# fixed part of a word, for example "generali") that are in the text, and
# whether the dataset is in `cleared` (names = dataset keys). `hit` = one or
# more words; `stop` = hit and not cleared.
occ_dataset_check <- function(meta, words, cleared, n_1km, n_5km, set) {
  keys <- names(meta)
  if (length(keys) == 0) {
    return(data.frame(set = character(0), datasetKey = character(0),
                      title = character(0), n_1km = integer(0),
                      n_5km = integer(0), words_found = character(0),
                      hit = logical(0), cleared = logical(0),
                      stop = logical(0), stringsAsFactors = FALSE))
  }
  rows <- lapply(keys, function(k) {
    txt <- tolower(occ_dataset_text(meta[[k]]))
    w   <- words[vapply(tolower(words), function(x) grepl(x, txt, fixed = TRUE),
                        logical(1))]
    data.frame(set = set, datasetKey = k,
               title = as.character(meta[[k]]$title %||% ""),
               n_1km = if (k %in% names(n_1km)) as.integer(n_1km[[k]]) else 0L,
               n_5km = if (k %in% names(n_5km)) as.integer(n_5km[[k]]) else 0L,
               words_found = paste(w, collapse = "; "),
               hit = length(w) > 0,
               cleared = k %in% names(cleared),
               stringsAsFactors = FALSE)
  })
  res <- do.call(rbind, rows)
  res$stop <- res$hit & !res$cleared
  rownames(res) <- NULL
  res
}

# =============================================================================
# Task 13.4 — STEP 13.3: the background
# =============================================================================

# Clean background by taxon (tbl_15_background_taxa.csv): one row per order
# and family. A missing order or family is "(none)". records_5km counts all
# kept records (uncert_set "1km" or "5km"), as the 5 km set does; records_1km
# the "1km" records; records_matched_1km the "1km" records with ds_match TRUE.
# Sorted by records_5km (highest first), then order and family.
occ_taxa_table <- function(order, family, uncert_set, ds_match, set) {
  n <- length(uncert_set)
  stopifnot(length(order) == n, length(family) == n, length(ds_match) == n)
  nm <- function(x) ifelse(is.na(x) | !nzchar(trimws(x)), "(none)", x)
  key <- paste(nm(order), nm(family), sep = "\t")
  r1  <- tapply(uncert_set == "1km", key, sum)
  r5  <- tapply(rep(1L, n), key, sum)
  m1  <- tapply(uncert_set == "1km" & ds_match, key, sum)
  of  <- do.call(rbind, strsplit(names(r5), "\t", fixed = TRUE))
  res <- data.frame(set = set, order = of[, 1], family = of[, 2],
                    records_1km = as.integer(r1[names(r5)]),
                    records_5km = as.integer(r5),
                    records_matched_1km = as.integer(m1[names(r5)]),
                    stringsAsFactors = FALSE)
  res <- res[order(-res$records_5km, res$order, res$family), , drop = FALSE]
  rownames(res) <- NULL
  if (sum(res$records_5km) != n ||
      sum(res$records_1km) != sum(uncert_set == "1km") ||
      sum(res$records_matched_1km) != sum(uncert_set == "1km" & ds_match)) {
    stop("occ_taxa_table(): the rows do not add up (", set, ").",
         call. = FALSE)
  }
  res
}

# =============================================================================
# Task 13.7 - STEP 13.5: the hand-made case of the rule functions
# =============================================================================
# Process choice h1 (2026-10-18). Twenty made-up records, each made to fail a
# known step of Decision 21 (or none), go through occ_step_fails(),
# occ_first_fail() and occ_attrition() with the settings of the config. The
# expected first failed step of each record and the counts are written by
# hand below, not computed by the functions under test. Also:
# occ_uncert_set() at the limits, occ_cell02() on a cell edge,
# occ_point8_outcome() at the limits and occ_near() at the distance limit
# minus 1 m, at the limit and plus 1 m, from a made-up point and a made-up
# area. The records are not real; no
# position of a real record is used.
# Returns one row per check: check, expected, got, pass. The caller stops if a
# check fails.
occ_self_test <- function(status_keep, basis_keep, year_min, year_max,
                          issue_remove, issue_report, uncert_main,
                          uncert_wide, order, min_model, min_full, cell_deg,
                          near_m) {
  stopifnot(!"ABSENT" %in% status_keep,
            !"PRESERVED_SPECIMEN" %in% basis_keep,
            length(issue_remove) > 0, length(issue_report) > 0,
            identical(order, c("status", "basis", "year", "coord_flags",
                               "uncert_na", "uncert", "centroid", "zoo",
                               "footprint")))
  ok_st <- status_keep[1]
  ok_bs <- basis_keep[1]
  ok_yr <- year_min
  ok_u  <- uncert_main
  # One row per record: the fields of the rule, the three spatial results,
  # and the hand-written expected first failed step ("" = kept).
  rec <- data.frame(
    occurrenceStatus = c(ok_st, "ABSENT", NA, ok_st, ok_st, ok_st, ok_st,
                         ok_st, ok_st, ok_st, ok_st, ok_st, ok_st, ok_st,
                         ok_st, ok_st, ok_st, ok_st, ok_st, ok_st),
    basisOfRecord = c(ok_bs, ok_bs, ok_bs, "PRESERVED_SPECIMEN", ok_bs, ok_bs,
                      ok_bs, ok_bs, ok_bs, ok_bs, ok_bs, ok_bs, ok_bs, ok_bs,
                      "PRESERVED_SPECIMEN", ok_bs, ok_bs, ok_bs, ok_bs, ok_bs),
    year_num = c(ok_yr, ok_yr, ok_yr, ok_yr, year_min - 1, NA, ok_yr, ok_yr,
                 ok_yr, ok_yr, ok_yr, ok_yr, ok_yr, ok_yr, year_max + 1,
                 ok_yr, year_max, ok_yr, ok_yr, ok_yr),
    issue = c(NA, NA, NA, NA, NA, NA,
              paste(issue_report[1], issue_remove[1], sep = ";"),
              NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,
              issue_report[1]),
    lat = c(20, 20, 20, 20, 20, 20, 20, 21, 20, 20, 20, 20, 20, 20, 20, 20,
            20, 20, 20, 20),
    lon = c(78, 78, 78, 78, 78, 78, 78, 21, 78, 78, 78, 78, 78, 78, 78, 78,
            78, 78, 78, 78),
    uncert_m = c(ok_u, ok_u, ok_u, ok_u, ok_u, ok_u, ok_u, ok_u, NA, 0,
                 uncert_wide + 1, ok_u, ok_u, ok_u, ok_u, uncert_wide + 1,
                 uncert_main, uncert_main + 1, uncert_wide, ok_u),
    stringsAsFactors = FALSE
  )
  near_centroid <- c(rep(FALSE, 11), TRUE, rep(FALSE, 8))
  near_zoo      <- c(rep(FALSE, 12), TRUE, FALSE, TRUE, rep(FALSE, 5))
  complete      <- c(rep(TRUE, 13), FALSE, TRUE, FALSE, rep(TRUE, 4))
  expect_first  <- c("", "status", "status", "basis", "year", "year",
                     "coord_flags", "coord_flags", "uncert_na", "uncert_na",
                     "uncert", "centroid", "zoo", "footprint", "basis",
                     "uncert", "", "", "", "")
  # Hand counts of the attrition, in the order of the steps.
  expect_removed <- c(status = 2, basis = 2, year = 2, coord_flags = 2,
                      uncert_na = 2, uncert = 2, centroid = 1, zoo = 1,
                      footprint = 1)

  fails <- occ_step_fails(rec, status_keep = status_keep,
                          basis_keep = basis_keep, year_min = year_min,
                          year_max = year_max, issue_remove = issue_remove,
                          uncert_wide = uncert_wide,
                          near_centroid = near_centroid, near_zoo = near_zoo,
                          complete = complete)[, order]
  first <- occ_first_fail(fails, order)
  got_first <- ifelse(is.na(first), "", first)
  att   <- occ_attrition(first, order, set = "test case")
  kept  <- is.na(first)
  us    <- occ_uncert_set(rec$uncert_m[kept], uncert_main, uncert_wide)

  # occ_cell02(): a point on a cell edge goes to the cell east / north of it.
  e_lon <- 386 * cell_deg   # a multiple of the cell size (77.2 at 0.2)
  c02 <- occ_cell02(lon = c(e_lon, e_lon - 1e-7), lat = c(20, 20),
                    deg = cell_deg)

  # occ_near(): one made-up point and one made-up square of 100 m.
  crs <- sf::st_crs(7755)
  x0 <- 3000000; y0 <- 1500000
  tgt_pt <- sf::st_sf(id = 1, geometry = sf::st_sfc(sf::st_point(c(x0, y0)),
                                                    crs = crs))
  sq <- sf::st_polygon(list(rbind(c(x0, y0), c(x0 + 100, y0),
                                  c(x0 + 100, y0 + 100), c(x0, y0 + 100),
                                  c(x0, y0))))
  tgt_sq <- sf::st_sf(id = 1, geometry = sf::st_sfc(sq, crs = crs))
  probe <- function(dx, dy) sf::st_sf(id = seq_along(dx), geometry =
    sf::st_sfc(lapply(dx, function(d) sf::st_point(c(x0 - d, y0 + dy))),
               crs = crs))
  # The probes are due west of the point, and level with the middle of the
  # west edge of the square, so each distance is exactly d.
  dd    <- near_m + c(-1, 0, 1)
  n_pt  <- occ_near(probe(dd, 0), tgt_pt, near_m)
  n_sq  <- occ_near(probe(dd, 50), tgt_sq, near_m)

  chk <- list(
    list("records with the hand-written first failed step (of 20)", 20,
         sum(got_first == expect_first)),
    list("steps with the hand-written number removed (of 9)", 9,
         sum(att$removed[match(names(expect_removed), att$step)] ==
               expect_removed)),
    list("records kept", 5, sum(kept)),
    list("attrition: entry 20, last records_out = kept", 1,
         as.numeric(att$records_in[1] == 20 &&
                      att$records_out[nrow(att)] == sum(kept))),
    list("a report flag alone removes no record (1 = kept)", 1,
         as.numeric(kept[20])),
    list("uncertainty sets of the 5 kept records match (5 of 5)", 5,
         sum(us == c("1km", "1km", "5km", "5km", "1km"))),
    list("cell02: a point on a cell edge -> the cell east of the edge", 1,
         as.numeric(abs(c02$cell02_lon_deg[1] - e_lon) < 1e-9)),
    list("cell02: a point just west of the edge -> the cell west of it", 1,
         as.numeric(abs(c02$cell02_lon_deg[2] - (e_lon - cell_deg)) < 1e-9)),
    list("point 8 outcome at min_model - 1, min_model, min_full - 1, min_full",
         4, sum(c(occ_point8_outcome(min_model - 1, min_model, min_full),
                  occ_point8_outcome(min_model, min_model, min_full),
                  occ_point8_outcome(min_full - 1, min_model, min_full),
                  occ_point8_outcome(min_full, min_model, min_full)) ==
                  c("no_1km_model", "reduced_model", "reduced_model",
                    "planned_model"))),
    list("occ_near, point: limit - 1 m and limit near, limit + 1 m not", 3,
         sum(n_pt == c(TRUE, TRUE, FALSE))),
    list("occ_near, area: limit - 1 m and limit near, limit + 1 m not", 3,
         sum(n_sq == c(TRUE, TRUE, FALSE)))
  )
  data.frame(
    check    = vapply(chk, `[[`, character(1), 1),
    expected = vapply(chk, function(x) as.numeric(x[[2]]), numeric(1)),
    got      = vapply(chk, function(x) as.numeric(x[[3]]), numeric(1)),
    pass     = vapply(chk, function(x) isTRUE(all.equal(as.numeric(x[[2]]),
                                                         as.numeric(x[[3]]))),
                      logical(1)),
    stringsAsFactors = FALSE
  )
}

# =============================================================================
# Task 13.8 - STEP 13.6: clean records per reserve
# =============================================================================
# The reserve polygon(s) that hold each record (process choice r1: the record
# position; a point on the edge of a polygon counts as inside). Process
# choice o1 (2026-10-18): a record in two or more polygons (an overlap of
# reserve polygons) counts in each of them.
#   x        : sf points (a clean layer), in the CRS of `reserves`
#   reserves : sf polygons with geometry (one row per reserve)
# Returns list(hits = for each point the rows of `reserves` that hold it
# (integer(0) if none); long = data.frame(rec, res), one row per point and
# reserve; n_multi = the number of points in two or more polygons).
occ_reserve_index <- function(x, reserves) {
  hit <- lapply(sf::st_intersects(x, reserves), as.integer)
  n   <- lengths(hit)
  list(hits = hit,
       long = data.frame(rec = rep(seq_along(hit), n),
                         res = unlist(hit, use.names = FALSE)),
       n_multi = sum(n > 1L))
}

# Pairs of reserve polygons whose areas overlap (an area above 0; a pair that
# only touches is left out). Returns data.frame(a, b, overlap_km2) with the
# rows a < b of `reserves`.
occ_reserve_overlaps <- function(reserves) {
  g   <- sf::st_geometry(reserves)
  hit <- sf::st_intersects(g)
  out <- list()
  for (i in seq_along(hit)) {
    for (j in hit[[i]][hit[[i]] > i]) {
      ix <- suppressWarnings(sf::st_intersection(g[i], g[j]))
      a  <- if (length(ix) == 0) 0 else as.numeric(sum(sf::st_area(ix))) / 1e6
      if (a > 0) out[[length(out) + 1L]] <- data.frame(a = i, b = j,
                                                        overlap_km2 = a)
    }
  }
  if (length(out) == 0) {
    return(data.frame(a = integer(0), b = integer(0),
                      overlap_km2 = numeric(0)))
  }
  do.call(rbind, out)
}

# Decision 22 point 9: a count from 1 to min_n - 1 is written as the text
# "<min_n" (for min_n = 3: "<3"). 0, min_n or more, and NA stay as they are
# (as text). Returns a character vector.
occ_suppress_small <- function(v, min_n) {
  out <- ifelse(is.na(v), NA_character_, as.character(v))
  out[!is.na(v) & v >= 1 & v < min_n] <- paste0("<", min_n)
  out
}
