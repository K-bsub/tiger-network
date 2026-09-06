# =============================================================================
# 09_build_site.R  [DELIVERABLE]
# Render the Quarto story site. Renders locally and freezes computed output in
# site/_freeze/ (committed) so the GitHub Action needs only Quarto, not the R
# spatial stack. Quarto is not on the Windows PATH — call via quarto::.
# =============================================================================
suppressPackageStartupMessages({ library(here); library(quarto) })
quarto::quarto_render(here("site"), as_job = FALSE)
