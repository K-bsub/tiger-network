# =============================================================================
# One-off check for task 10.3b (Decision 17, D1a state split). Not committed.
# PART A: run BEFORE the re-run (backs up the current outputs).
# PART B: run AFTER scripts/02 -> 03 -> 04 -> 05 (compares new vs backup).
# Expected: only unit_id 1 (Nagarjunsagar-Srisailam) and 51 (Amrabad) change,
# and only in geometry_present, match_status, n_parts, poly_km2,
# poly_census_ratio (and their polygon areas). Census, area, density and growth
# values must not change.
# =============================================================================
library(here)
library(sf)

bk <- here("data", "interim", "pre_split_backup_20261002")   # gitignored
tbls_same  <- c("tbl_01_reserve_growth.csv", "tbl_02_regional_rollup.csv",
                "tbl_06_census_wide_check.csv", "tbl_09_density_check.csv")
tbls_split <- c("tbl_02_reserve_build_report.csv", "tbl_07_census_join_check.csv",
                "tbl_08_area_overwrite_check.csv")
layers     <- c("boundary_reserves_all_7755.gpkg", "stats_reserve_census_7755.gpkg")
figs       <- c("fig_01_growth_ranking.png", "fig_02_growth_animation.gif")
SPLIT_IDS  <- c(1L, 51L)
ALLOWED    <- c("geometry_present", "match_status", "n_parts", "poly_km2",
                "poly_census_ratio")

src_path <- function(f) {
  if (grepl("^tbl_", f)) return(here("outputs", "tables", f))
  if (grepl("^fig_", f)) return(here("outputs", "figures", f))
  here("data", "processed", f)
}

# ---- PART A — backup ---------------------------------------------------------
backup_outputs <- function() {
  files <- vapply(c(layers, tbls_same, tbls_split, figs), src_path, character(1))
  miss <- files[!file.exists(files)]
  if (length(miss) > 0) stop("Missing: ", paste(miss, collapse = ", "), call. = FALSE)
  dir.create(bk, recursive = TRUE, showWarnings = FALSE)
  ok <- file.copy(files, bk, overwrite = TRUE)
  stopifnot(all(ok))
  cat("backed up", length(files), "files to", bk, "\n")
}

# ---- PART B — compare --------------------------------------------------------
same_val <- function(a, b) {
  if (is.numeric(a) && is.numeric(b)) {
    (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= 1e-9 * pmax(1, abs(a)))
  } else {
    a <- as.character(a); b <- as.character(b)
    (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
  }
}
# Returns a data.frame of differences: unit_id (NA if no key), column.
diff_frames <- function(old, new) {
  if (!identical(sort(names(old)), sort(names(new)))) {
    return(data.frame(unit_id = NA_integer_, column = "<column set differs>"))
  }
  if ("unit_id" %in% names(old)) {
    if (!setequal(old$unit_id, new$unit_id) || anyDuplicated(old$unit_id)) {
      return(data.frame(unit_id = NA_integer_, column = "<unit_id set differs>"))
    }
    new <- new[match(old$unit_id, new$unit_id), names(old)]
    key <- as.integer(old$unit_id)
  } else {
    if (nrow(old) != nrow(new)) {
      return(data.frame(unit_id = NA_integer_, column = "<row count differs>"))
    }
    new <- new[, names(old)]
    key <- rep(NA_integer_, nrow(old))
  }
  out <- list()
  for (cl in names(old)) {
    bad <- !same_val(old[[cl]], new[[cl]])
    if (any(bad)) out[[cl]] <- data.frame(unit_id = key[bad], column = cl)
  }
  if (length(out) == 0) data.frame(unit_id = integer(0), column = character(0))
  else do.call(rbind, out)
}
report <- function(name, d, allow_split) {
  if (nrow(d) == 0) { cat(sprintf("  %-38s identical\n", name)); return(TRUE) }
  ok <- allow_split && all(d$unit_id %in% SPLIT_IDS) && all(d$column %in% ALLOWED)
  cat(sprintf("  %-38s %s: %s\n", name, if (ok) "changed as expected" else "UNEXPECTED CHANGE",
              paste(unique(paste0(d$column, "[", d$unit_id, "]")), collapse = ", ")))
  ok
}

compare_outputs <- function() {
  res <- c()
  cat("tables that must be identical:\n")
  for (f in tbls_same) {
    d <- diff_frames(read.csv(file.path(bk, f)), read.csv(src_path(f)))
    res[f] <- report(f, d, allow_split = FALSE)
  }
  cat("tables where only unit_id 1 and 51 may change:\n")
  for (f in tbls_split) {
    d <- diff_frames(read.csv(file.path(bk, f)), read.csv(src_path(f)))
    res[f] <- report(f, d, allow_split = TRUE)
  }
  cat("layers (attributes, then polygon area):\n")
  for (f in layers) {
    o <- st_read(file.path(bk, f), quiet = TRUE); n <- st_read(src_path(f), quiet = TRUE)
    d <- diff_frames(st_drop_geometry(o), st_drop_geometry(n))
    res[paste(f, "attrs")] <- report(paste(f, "attrs"), d, allow_split = TRUE)
    n <- n[match(o$unit_id, n$unit_id), ]
    da <- abs(as.numeric(st_area(o)) - as.numeric(st_area(n))) > 1
    ok <- all(o$unit_id[da] %in% SPLIT_IDS)
    cat(sprintf("  %-38s %s\n", paste(f, "areas"),
                if (!any(da)) "identical" else if (ok)
                  paste0("changed as expected: unit_id ", paste(o$unit_id[da], collapse = ", "))
                else paste0("UNEXPECTED CHANGE: unit_id ", paste(o$unit_id[da], collapse = ", "))))
    res[paste(f, "areas")] <- ok
  }
  cat("figures (file content):\n")
  for (f in figs) {
    same <- unname(tools::md5sum(file.path(bk, f)) == tools::md5sum(src_path(f)))
    cat(sprintf("  %-38s %s\n", f, if (same) "identical" else
      if (f == "fig_02_growth_animation.gif") "changed (expected: Amrabad now drawn)"
      else "changed — check by eye (expected: no visible change)"))
  }
  cat("\nRESULT:", if (all(res)) "PASS — only the expected changes." else
      "FAIL — see UNEXPECTED CHANGE above.", "\n")
  invisible(all(res))
}

# Run PART A now; after the re-run, run PART B:
# backup_outputs()
# compare_outputs()
