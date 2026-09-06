# =============================================================================
# 05_occurrence_and_effort.R  [EFFORT thread + SDM input]
# Clean GBIF occurrences; build the target-group background (all vertebrates)
# as the sampling-effort layer. KDE + Gi* on occurrences to reproduce and
# generalise the Phase 1 observer-bias finding (Ranthambore cold spot) nationally.
#
# Outputs:
#   data/processed/occ_tiger_gbif_clean_7755.gpkg
#   data/processed/effort_background_tgs_7755.gpkg
#   outputs/rasters/kde_tiger_current_1km_7755.tif
#   outputs/figures/fig_03_effort_vs_detection.png
# =============================================================================
suppressPackageStartupMessages({ library(here); library(sf); library(terra); library(spatstat.explore); library(sfdep) })
source(here("R", "00_config.R")); source(here("R", "00_functions_io.R")); source(here("R", "00_functions_sensitive.R"))
# ... (fill in Week 5)
