# =============================================================================
# 00a_setup_environment.R
# Verify the spatial toolchain and install project packages.
# Run this FIRST, before renv::init(), so any GDAL/GEOS/PROJ problem surfaces
# before the reproducible environment is layered on top.
# =============================================================================

# ---- 1. Required packages --------------------------------------------------
required <- c(
  # Core spatial
  "sf", "terra", "here",
  # Point pattern / spatial statistics
  "spatstat.explore", "spatstat.geom", "sfdep",
  # Connectivity
  "leastcostpath", "igraph",
  # Habitat suitability (SDM)
  "maxnet", "predicts",
  # Data handling
  "dplyr", "tidyr", "readr", "stringr", "readxl", "exactextractr",
  # Acquisition
  "rgbif", "elevatr", "osmdata",
  # Visualisation / site
  "ggplot2", "leaflet", "htmlwidgets", "gganimate"
)

installed <- rownames(installed.packages())
missing   <- setdiff(required, installed)

if (length(missing) > 0) {
  message("Installing missing packages: ", paste(missing, collapse = ", "))
  install.packages(missing)
} else {
  message("All required packages already installed.")
}

# ---- 2. Verify the spatial toolchain ---------------------------------------
# A silent GDAL/GEOS/PROJ mismatch is the most common source of hard-to-debug
# spatial errors on Windows. Print versions so any mismatch is visible now.
suppressPackageStartupMessages({
  library(sf)
  library(terra)
})

message("\n--- Spatial toolchain versions ---")
print(sf::sf_extSoftVersion())
message("terra / GDAL: ", terra::gdal(lib = "gdal"))
message("terra / GEOS: ", terra::gdal(lib = "geos"))
message("terra / PROJ: ", terra::gdal(lib = "proj"))

# ---- 3. Verify the analysis CRS is resolvable ------------------------------
source(here::here("R", "00_config.R"))
crs_test <- sf::st_crs(CRS_ANALYSIS)
if (is.na(crs_test)) {
  stop("Analysis CRS EPSG:", CRS_ANALYSIS,
       " could not be resolved — check the PROJ database.", call. = FALSE)
}
message("\nAnalysis CRS EPSG:", CRS_ANALYSIS, " resolved OK:")
message("  ", crs_test$Name)

message("\nSetup checks complete. Next: run scripts/00b_audit_data.R")
