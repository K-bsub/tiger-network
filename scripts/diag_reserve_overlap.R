# =============================================================================
# diag_reserve_overlap.R  (one-time check for task 13.8; do NOT commit)
# Why did STEP 13.6 find background records in two reserve polygons?
# Reads the reserve layer and the clean background and tiger layers. Writes
# nothing. Prints names, unit_ids, counts and areas only: no coordinate, no
# cell number. Run from the project root in a fresh R session.
# =============================================================================
suppressPackageStartupMessages({
  library(here)
  library(sf)
})
source(here("R", "00_config.R"))
source(here("R", "00_functions_io.R"))

res <- read_vec(file.path(DIR_PROCESSED, "boundary_reserves_all_7755.gpkg"))
res$unit_id <- as.integer(round(res$unit_id))
res <- res[as.logical(res$geometry_present) &
             !sf::st_is_empty(sf::st_geometry(res)), ]
cat("reserves with a polygon:", nrow(res), "\n")
cat("polygons that are not valid (sf::st_is_valid):",
    sum(!sf::st_is_valid(res)), "\n")

# ---- 1. Pairs of reserve polygons that touch or overlap ------------------------
hit <- sf::st_intersects(res)
pairs <- do.call(rbind, lapply(seq_along(hit), function(i) {
  j <- hit[[i]][hit[[i]] > i]
  if (length(j) == 0) return(NULL)
  data.frame(a = i, b = j)
}))
if (is.null(pairs) || nrow(pairs) == 0) {
  cat("no pair of reserve polygons touches or overlaps\n")
} else {
  ov <- vapply(seq_len(nrow(pairs)), function(k) {
    g <- suppressWarnings(sf::st_intersection(
      sf::st_geometry(res)[pairs$a[k]], sf::st_geometry(res)[pairs$b[k]]))
    if (length(g) == 0) 0 else as.numeric(sum(sf::st_area(g))) / 1e6
  }, numeric(1))
  tab <- data.frame(
    unit_id_a  = res$unit_id[pairs$a], name_a = res$unit_name[pairs$a],
    match_a    = res$match_status[pairs$a],
    unit_id_b  = res$unit_id[pairs$b], name_b = res$unit_name[pairs$b],
    match_b    = res$match_status[pairs$b],
    overlap_km2 = round(ov, 3), stringsAsFactors = FALSE)
  cat("\n--- pairs of polygons that touch (overlap_km2 = 0) or overlap ---\n")
  print(tab[order(-tab$overlap_km2), ], row.names = FALSE)
}

# ---- 2. Records in two or more polygons, by pair (counts only) -------------------
for (f in c("effort_background_tgs_clean_7755.gpkg",
            "occ_tiger_gbif_clean_7755.gpkg")) {
  x  <- sf::st_read(file.path(DIR_PROCESSED, f), quiet = TRUE)
  h  <- sf::st_intersects(x, res)
  mi <- which(lengths(h) > 1)
  cat("\n---", f, ":", length(mi), "record(s) in two or more polygons ---\n")
  if (length(mi) == 0) next
  # inside the interior of 2+ polygons (a true overlap), or on an edge?
  w  <- lengths(sf::st_within(x[mi, ], res))
  key <- vapply(h[mi], function(k) paste(sort(res$unit_name[k]),
                                         collapse = " + "), character(1))
  print(as.data.frame(table(reserves = key,
                            inside_interiors = ifelse(w >= 2, "2 or more",
                                                      "0 or 1 (an edge)")),
                      stringsAsFactors = FALSE)[, c("reserves",
                                                    "inside_interiors",
                                                    "Freq")],
        row.names = FALSE)
  cat("datasets of these records:\n")
  print(as.data.frame(table(datasetKey = x$datasetKey[mi])), row.names = FALSE)
}
cat("\nDone. Nothing was written.\n")
