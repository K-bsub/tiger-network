# =============================================================================
# 04_growth_analysis.R  [GROWTH — priority 1]
# Rank reserves within landscape complex and state; build the animated
# choropleth of growth category across the five census years (gganimate).
#
# Outputs:
#   outputs/figures/fig_01_growth_ranking.png
#   outputs/figures/fig_02_growth_animation.gif
#   outputs/tables/tbl_02_regional_rollup.csv
# =============================================================================
suppressPackageStartupMessages({ library(here); library(sf); library(dplyr); library(ggplot2); library(gganimate) })
source(here("R", "00_config.R")); source(here("R", "00_functions_io.R"))
# ... (fill in Week 4)
