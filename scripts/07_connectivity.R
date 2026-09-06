# =============================================================================
# 07_connectivity.R  [CONNECTIVITY — priority 2]
# Build the resistance surface (WORLDCOVER_RESISTANCE + roads as barriers).
# Least-cost paths between neighbouring reserve pairs (leastcostpath). Assemble
# the reserve network as an igraph; compute betweenness (linchpin reserves),
# components (isolated reserves), and identify road pinch points.
#
# Decision required: resistance values are a numbered Decision before running.
#
# Outputs:
#   data/processed/resist_tiger_baseline_7755.tif   (>= PUBLISH_FLOOR_M to publish)
#   data/processed/lcp_reserve_network_7755.gpkg
#   outputs/tables/tbl_03_network_metrics.csv
#   outputs/figures/fig_04_connectivity_network.png
# =============================================================================
suppressPackageStartupMessages({ library(here); library(sf); library(terra); library(leastcostpath); library(igraph) })
source(here("R", "00_config.R")); source(here("R", "00_functions_io.R")); source(here("R", "00_functions_sensitive.R"))
# ... (fill in Weeks 7-8)
