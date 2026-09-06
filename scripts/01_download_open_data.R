# =============================================================================
# 01_download_open_data.R
# Re-acquire ONLY the datasets the audit (00b) reported MISSING.
# Do not blindly re-download everything. Each block is guarded: it skips if the
# target already exists. Fill in blocks as the audit dictates.
# See data/README.md for manual-download steps (NTCA PDFs, ISFR, WII boundaries).
# =============================================================================

suppressPackageStartupMessages({ library(here); library(dplyr); library(readr) })
source(here("R", "00_config.R"))

audit_path <- file.path(DIR_TABLES, "tbl_00_data_audit.csv")
if (!file.exists(audit_path))
  stop("Run scripts/00b_audit_data.R first — no audit table found.", call. = FALSE)
audit <- read_csv(audit_path, show_col_types = FALSE)
missing_ids <- audit |> filter(grepl("MISSING", status)) |> pull(dataset_id)
message("Datasets to re-acquire: ", paste(missing_ids, collapse = ", "))

# ---- GBIF Panthera tigris occurrences (scripted) ---------------------------
# if ("gbif_occ" %in% missing_ids) { ... rgbif::occ_download(...) ... }

# ---- GBIF target-group background effort (scripted, async) -----------------
# if ("gbif_effort" %in% missing_ids) { ... }

# ---- ESA WorldCover tiles (scripted from public AWS COGs) -------------------
# if ("worldcover" %in% missing_ids) { ... }

# ---- SRTM / elevatr terrain (scripted) -------------------------------------
# if ("srtm" %in% missing_ids) { ... elevatr::get_elev_raster(...) ... }

# ---- gHM (Theobald 2024, /vsicurl from Zenodo) -----------------------------
# ---- OSM roads/settlements (Geofabrik India extract) -----------------------

# NOTE: NTCA census, ISFR forest, WII/TR boundaries are MANUAL downloads.
#       See data/README.md — they cannot be scripted cleanly.
message("Scripted downloads complete. Handle manual sources per data/README.md.")
