# =============================================================================
# 00_functions_sensitive.R
# Guards that enforce docs/sensitive-data-policy.md before any publish step.
# Ported from the Bay Area project's assert_publishable() pattern.
# Tigers are lower-risk than pumas, but precise GBIF points still exist, so a
# lightweight guard is kept. Sourced, never run standalone.
# =============================================================================

# Stop if a raster is finer than the publish floor. Call before exporting any
# continuous surface (SDM suitability, KDE, resistance) for the site.
assert_publishable_rast <- function(r, floor_m = PUBLISH_FLOOR_M) {
  res_m <- min(terra::res(r))
  if (res_m < floor_m) {
    stop(
      sprintf(
        "Refusing to publish: raster cell size %.0f m is finer than the %.0f m publish floor.\n  Aggregate first, e.g. terra::aggregate(r, fact = ceiling(%.0f / %.0f)).",
        res_m, floor_m, floor_m, res_m
      ),
      call. = FALSE
    )
  }
  invisible(r)
}

# Stop if a vector layer that will be published still carries precise points.
# Published occurrence products must be aggregated to reserve or grid level,
# never raw points. Pass expect = "polygon" for unit-level summaries.
assert_no_raw_points <- function(x, expect = c("polygon", "aggregated")) {
  expect <- match.arg(expect)
  geom <- unique(as.character(sf::st_geometry_type(x)))
  if (any(geom %in% c("POINT", "MULTIPOINT"))) {
    stop(
      "Refusing to publish raw point geometry. Published occurrence outputs ",
      "must be aggregated to reserve or grid cell (see sensitive-data-policy.md).",
      call. = FALSE
    )
  }
  invisible(x)
}

# Warn on small-n aggregation units that could reverse-narrow a location.
# A reserve or cell with very few underlying records is a disclosure risk.
warn_small_n <- function(x, count_field, min_n = 3L) {
  if (!count_field %in% names(x)) {
    warning("Field '", count_field, "' not found; small-n check skipped.")
    return(invisible(x))
  }
  small <- x[[count_field]] < min_n
  if (any(small, na.rm = TRUE)) {
    warning(sum(small, na.rm = TRUE), " unit(s) have n < ", min_n,
            " — suppress or coarsen before publishing.")
  }
  invisible(x)
}
