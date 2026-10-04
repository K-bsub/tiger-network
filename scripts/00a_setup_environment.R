# =============================================================================
# 00a_setup_environment.R
# Verify the spatial toolchain and install project packages.
# Run this FIRST, before renv::init(), so any GDAL/GEOS/PROJ problem surfaces
# before the reproducible environment is layered on top.
# =============================================================================

# ---- 1. Required packages --------------------------------------------------
# Checked against renv::dependencies(c("R", "scripts")) on 2026-10-02.
required <- c(
  # Core spatial
  "sf", "terra", "here",
  # Connectivity. The path engine is our own (R/00_functions_lcp.R, terra +
  # igraph; Decision 17). gdistance + raster are for validation check (c) only.
  "igraph", "gdistance", "raster",
  # Data handling
  "dplyr", "tidyr", "readr", "stringr", "tibble", "xml2",
  # Acquisition (scripts/01)
  "rgbif", "elevatr", "osmextract", "rnaturalearth",
  # Figures (Stage 1 animation)
  "ggplot2", "gganimate", "gifski",
  # Planned, not used yet — listed so a fresh setup has them
  "spatstat.explore", "spatstat.geom", "sfdep",   # KDE / Gi* (Weeks 13+)
  "maxnet", "predicts",                            # SDM (Weeks 14+)
  "leaflet", "htmlwidgets"                         # story site
)

installed <- rownames(installed.packages())
missing   <- setdiff(required, installed)

if (length(missing) > 0) {
  message("Installing missing packages: ", paste(missing, collapse = ", "))
  install.packages(missing)
} else {
  message("All required packages already installed.")
}

# rnaturalearthhires is not on CRAN. rnaturalearth needs it for
# scale = "large" and for ne_states() (scripts/01). renv::dependencies() does
# not find it, because no script calls it by name.
if (!requireNamespace("rnaturalearthhires", quietly = TRUE)) {
  message("Installing rnaturalearthhires from the rOpenSci R-universe.")
  install.packages("rnaturalearthhires",
                   repos = c("https://ropensci.r-universe.dev",
                             getOption("repos")))
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
