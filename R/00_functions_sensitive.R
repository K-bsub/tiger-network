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

# Stop if a table that will be committed or published holds a position that
# is finer than the publish grid for modelled paths and road crossings
# (docs/sensitive-data-policy.md §3; Decision 20 point 7). Call it before
# each write of a publishable table that has, or can have, a position.
#   x      : the table (a data frame; an sf object is refused)
#   prefix : NULL if the table must hold NO position. Otherwise the prefix of
#            the grid columns (for example "grid10"): <prefix>_id,
#            <prefix>_x_km, <prefix>_y_km must be in the table, and each
#            position must be a centre of the coarse grid.
#   r      : the analysis grid (a SpatRaster); needed with a prefix
#   grid_m : the cell size of the coarse grid in metres (PINCH_PUBLISH_GRID_M);
#            it must not be finer than min_grid_m
#   name   : the table name, for the message
# The coarse grid is the analysis grid aggregated from its top-left corner.
assert_publishable_table <- function(x, prefix = NULL, r = NULL, grid_m = NULL,
                                     min_grid_m = PINCH_PUBLISH_GRID_M,
                                     name = "table") {
  refuse <- function(...) {
    stop("Refusing to publish ", name, ": ", ..., " (sensitive-data-policy.md ",
         "§3: a modelled path or crossing is published at the ",
         min_grid_m / 1000, " km grid).", call. = FALSE)
  }
  if (inherits(x, "sf")) refuse("it has a geometry column")
  banned <- c("cell", "cells", "mid_cell", "mean_cell", "exit_cell",
              "entry_cell", "x", "y", "mean_x", "mean_y", "lon", "lat",
              "longitude", "latitude", "geom", "geometry")
  bad <- intersect(tolower(names(x)), banned)
  if (length(bad) > 0) {
    refuse("column(s) with a 1 km cell or a point coordinate: ",
           paste(bad, collapse = ", "))
  }
  if (is.null(prefix)) {
    pos <- grep("^grid[0-9]*_(id|x_km|y_km)$", names(x), value = TRUE)
    if (length(pos) > 0) {
      refuse("position column(s) in a table that must have none: ",
             paste(pos, collapse = ", "))
    }
    return(invisible(x))
  }
  gc <- paste0(prefix, c("_id", "_x_km", "_y_km"))
  if (!all(gc %in% names(x))) {
    refuse("the grid column(s) ", paste(setdiff(gc, names(x)), collapse = ", "),
           " are not in the table")
  }
  if (is.null(r) || is.null(grid_m)) {
    refuse("the grid check needs the analysis grid and the grid size")
  }
  if (grid_m < min_grid_m || abs(grid_m / terra::xres(r) -
                                 round(grid_m / terra::xres(r))) > 1e-9) {
    refuse("the grid of ", grid_m, " m is finer than ", min_grid_m,
           " m, or it is not a whole multiple of the cell size")
  }
  cx <- (x[[gc[2]]] * 1000 - terra::xmin(r)) / grid_m - 0.5
  cy <- (terra::ymax(r) - x[[gc[3]]] * 1000) / grid_m - 0.5
  nc <- as.integer(ceiling(terra::ncol(r) / round(grid_m / terra::xres(r))))
  if (anyNA(cx) || anyNA(cy) || any(abs(cx - round(cx)) > 1e-6) ||
      any(abs(cy - round(cy)) > 1e-6)) {
    refuse("a position is not a centre of the ", grid_m / 1000, " km grid")
  }
  if (any(x[[gc[1]]] != round(cy) * nc + round(cx) + 1)) {
    refuse(gc[1], " is not the grid cell at ", gc[2], ", ", gc[3])
  }
  invisible(x)
}
