# =============================================================================
# 00b_audit_data.R
# Data audit. Checks which expected datasets are still on disk.
#
# WHY THIS EXISTS
# Most datasets came from the two earlier tiger projects, but disk space was
# reclaimed and some downloads may have been deleted. This script reads the
# expected inventory (data/data_manifest.csv), searches for each dataset under
# data/raw/, and reports PRESENT / MISSING / EMPTY so you re-download only what
# is actually gone — not everything.
#
# It writes outputs/tables/tbl_00_data_audit.csv and prints a summary. It never
# downloads or deletes anything.
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tidyr)
})

source(here("R", "00_config.R"))

manifest_path <- here("data", "data_manifest.csv")
if (!file.exists(manifest_path)) {
  stop("Manifest not found: ", manifest_path, call. = FALSE)
}
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)

# ---- Helper: find files matching any of a ;-separated glob list -------------
find_matches <- function(dir, glob_string) {
  if (!dir.exists(dir)) return(character(0))
  globs <- str_split(glob_string, ";", simplify = FALSE)[[1]] |> str_trim()
  hits <- character(0)
  for (g in globs) {
    hits <- c(
      hits,
      list.files(dir, pattern = utils::glob2rx(g),
                 recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
    )
  }
  unique(hits)
}

human_size <- function(bytes) {
  if (length(bytes) == 0 || is.na(bytes)) return("0 B")
  units <- c("B", "KB", "MB", "GB", "TB")
  i <- if (bytes <= 0) 1 else floor(log(bytes, 1024)) + 1
  i <- max(1, min(i, length(units)))
  sprintf("%.1f %s", bytes / 1024^(i - 1), units[i])
}

# ---- Run the audit ---------------------------------------------------------
audit <- manifest |>
  rowwise() |>
  mutate(
    search_dir = file.path(DIR_RAW, expected_subpath),
    dir_exists = dir.exists(search_dir),
    matches    = list(find_matches(search_dir, glob)),
    n_files    = length(matches),
    bytes      = if (n_files > 0) sum(file.size(matches), na.rm = TRUE) else 0,
    status = dplyr::case_when(
      !dir_exists            ~ "MISSING (no dir)",
      n_files == 0           ~ "MISSING (empty)",
      TRUE                   ~ "PRESENT"
    ),
    size_h = human_size(bytes)
  ) |>
  ungroup()

# ---- Console summary --------------------------------------------------------
cat("\n==================== DATA AUDIT ====================\n")
cat("Searched under:", DIR_RAW, "\n")
cat("Manifest:", manifest_path, "\n\n")

audit |>
  mutate(line = sprintf("  [%-16s] %-45s %s",
                        status, str_trunc(dataset_name, 45), size_h)) |>
  pull(line) |>
  cat(sep = "\n")

present <- sum(audit$status == "PRESENT")
missing <- sum(str_starts(audit$status, "MISSING"))

cat("\n\n----------------------------------------------------\n")
cat(sprintf("PRESENT: %d    MISSING: %d    TOTAL: %d\n",
            present, missing, nrow(audit)))

# What is missing that blocks the top-priority track (growth)?
growth_missing <- audit |>
  filter(str_starts(status, "MISSING"),
         str_detect(required_for, "growth"))
if (nrow(growth_missing) > 0) {
  cat("\n!! Missing datasets needed for the GROWTH track (priority 1):\n")
  growth_missing |>
    mutate(l = sprintf("   - %s  ->  %s", dataset_name, source_url)) |>
    pull(l) |> cat(sep = "\n")
  cat("\n")
}

# ---- Write the audit table --------------------------------------------------
out <- audit |>
  select(dataset_id, dataset_name, category, required_for,
         status, n_files, size_h, search_dir, source_url, license, notes)

out_path <- file.path(DIR_TABLES, "tbl_00_data_audit.csv")
if (!dir.exists(DIR_TABLES)) dir.create(DIR_TABLES, recursive = TRUE)
readr::write_csv(out, out_path)
cat("\nWrote", out_path, "\n")
cat("Re-download only the MISSING rows (see data/README.md).\n")
