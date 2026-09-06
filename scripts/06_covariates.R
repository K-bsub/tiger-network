# =============================================================================
# 06_covariates.R  [CONNECTIVITY + SDM input]
# Assemble the covariate stack at GRID_CELL_M: WorldCover-derived land cover,
# terrain (elevation/slope/TRI), gHM, distance-to-road. Align to a common grid.
#
# Outputs:
#   data/processed/cov_stack_1km_7755.tif  (multi-band)
# =============================================================================
suppressPackageStartupMessages({ library(here); library(terra); library(sf) })
source(here("R", "00_config.R")); source(here("R", "00_functions_io.R"))
# ... (fill in Week 6)
