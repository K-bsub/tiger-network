# =============================================================================
# 08_habitat_suitability.R  [SDM — priority 3]
# Habitat suitability (NOT occupancy). maxnet on cleaned occurrences + covariate
# stack, with target-group background for sampling-bias correction. Predict a
# national suitability surface; validate against reserve locations.
#
# Framing is fixed as a Decision: this is suitability, no detection-history claim.
#
# Outputs:
#   outputs/models/tiger_sdm_maxnet_<date>.rds
#   outputs/rasters/sdm_tiger_suitability_1km_7755.tif  (gate through assert_publishable_rast)
#   outputs/figures/fig_05_suitability.png
# =============================================================================
suppressPackageStartupMessages({ library(here); library(terra); library(sf); library(maxnet); library(predicts) })
source(here("R", "00_config.R")); source(here("R", "00_functions_io.R")); source(here("R", "00_functions_sensitive.R"))
# ... (fill in Weeks 9-10)
