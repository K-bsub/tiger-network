# =============================================================================
# 03_prepare_census.R  [GROWTH — priority 1]
# Assemble the reserve-level census time series (2006-2022, all reserves) from
# the NTCA extractions, join to the reserve boundary layer, and compute growth
# metrics: absolute change, % growth, AAGR, density (tigers/100 km2).
#
# Watch: not every reserve has data in every round (the Kaziranga-2006 gap, at
# scale). Missing-year handling is a numbered Decision.
#
# Outputs:
#   data/processed/stats_reserve_census_7755.gpkg
#   outputs/tables/tbl_01_reserve_growth.csv
# =============================================================================
suppressPackageStartupMessages({ library(here); library(sf); library(dplyr); library(tidyr) })
source(here("R", "00_config.R")); source(here("R", "00_functions_io.R"))
# ... (fill in Weeks 3-4)
