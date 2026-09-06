# =============================================================================
# 02_prepare_boundaries.R
# Build the reserve boundary layer and assign each reserve to a landscape
# complex and state. Output is the spatial backbone for all three tracks.
#
# Decision required before coding: authoritative WII/NTCA TR boundaries vs KBA
# fallback (record as a numbered Decision in docs/methodology.md).
#
# Outputs:
#   data/processed/boundary_reserves_all_7755.gpkg   (fields: unit_id, unit_name,
#     unit_name_std, state, landscape_complex, area_km2)
#   data/processed/boundary_states_7755.gpkg
# =============================================================================
suppressPackageStartupMessages({ library(here); library(sf); library(dplyr) })
source(here("R", "00_config.R"))
source(here("R", "00_functions_io.R"))
# ... (fill in Week 2)
