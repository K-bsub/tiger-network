# =============================================================================
# 00_functions_io.R
# Input / output helpers. Sourced, never run standalone.
# Every read reprojects to the analysis CRS; every write is deterministic.
# Every raster write is read back and verified (write_processed_rast).
# =============================================================================

# Read a vector layer and reproject to the analysis CRS.
read_vec <- function(path, crs = CRS_ANALYSIS) {
  if (!file.exists(path)) stop("File not found: ", path, call. = FALSE)
  v <- sf::st_read(path, quiet = TRUE)
  if (is.na(sf::st_crs(v))) {
    warning("No CRS on ", basename(path), " — assuming EPSG:", CRS_WGS84)
    sf::st_crs(v) <- CRS_WGS84
  }
  sf::st_transform(v, crs)
}

# Read a raster and reproject to the analysis CRS (nearest for categorical).
read_rast <- function(path, crs = CRS_ANALYSIS, categorical = FALSE) {
  if (!file.exists(path)) stop("File not found: ", path, call. = FALSE)
  r <- terra::rast(path)
  method <- if (categorical) "near" else "bilinear"
  terra::project(r, paste0("EPSG:", crs), method = method)
}

# Write a processed vector layer as GeoPackage. Overwrites deterministically.
write_processed_vec <- function(x, filename, dir = DIR_PROCESSED) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  out <- file.path(dir, filename)
  sf::st_write(x, out, delete_dsn = TRUE, quiet = TRUE)
  message("Wrote ", out, " (", nrow(x), " features)")
  invisible(out)
}

# Write a processed raster as GeoTIFF, then VERIFY the file on disk.
#
# Week 9 fix (2026-09-26): the 6-band covariate stack was written as INT1U.
# A GeoTIFF holds ONE data type for all bands, and terra::writeRaster() chose an
# unsigned 8-bit type (the land-cover band is integer), so gHM and distance-to-
# road were written as 0 and elevation/TRI were cut to 0-254. The in-memory QA
# (tbl_10) did not see it, because it ran before the write. Two changes:
#   1. datatype is now explicit. Default "FLT4S" (32-bit float): it holds every
#      covariate in this project exactly enough, and integer class codes stay
#      exact. Pass an integer type only for a layer that is integer by design.
#      The compression predictor follows the type (3 for float, 2 for integer).
#   2. verify = TRUE reads the file back and compares, band by band, the NA
#      count (must be equal) and the mean (must agree within rel_tol, scaled by
#      max(1, |mean|)). Any difference stops the script: a written file must
#      hold the values that were computed.
write_processed_rast <- function(x, filename, dir = DIR_PROCESSED,
                                 datatype = "FLT4S", verify = TRUE,
                                 rel_tol = 1e-4) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  out <- file.path(dir, filename)
  is_float  <- grepl("^FLT", datatype)
  predictor <- if (is_float) "PREDICTOR=3" else "PREDICTOR=2"
  terra::writeRaster(
    x, out, overwrite = TRUE, datatype = datatype,
    gdal = c("COMPRESS=DEFLATE", predictor, "TILED=YES")
  )
  if (isTRUE(verify)) verify_written_rast(x, out, rel_tol = rel_tol)
  message("Wrote ", out, " (", datatype,
          if (isTRUE(verify)) ", read-back verified" else "", ")")
  invisible(out)
}

# Read a written raster back and compare it with the in-memory raster.
# Stops on a layer-count difference, an NA-count difference, or a mean that
# differs by more than rel_tol * max(1, |mean|). Used by write_processed_rast().
verify_written_rast <- function(x, path, rel_tol = 1e-4) {
  y <- terra::rast(path)
  if (terra::nlyr(y) != terra::nlyr(x)) {
    stop("Read-back check failed for ", basename(path), ": ", terra::nlyr(x),
         " layer(s) in memory, ", terra::nlyr(y), " on disk.", call. = FALSE)
  }
  m_x <- terra::global(x, "mean", na.rm = TRUE)[[1]]
  m_y <- terra::global(y, "mean", na.rm = TRUE)[[1]]
  n_x <- terra::global(is.na(x), "sum")[[1]]
  n_y <- terra::global(is.na(y), "sum")[[1]]
  bad_mean <- is.na(m_x) != is.na(m_y) |
    (!is.na(m_x) & !is.na(m_y) & abs(m_y - m_x) > rel_tol * pmax(1, abs(m_x)))
  bad_na <- n_x != n_y
  bad <- which(bad_mean | bad_na)
  if (length(bad) > 0) {
    detail <- paste0(names(x)[bad], " (mean ", signif(m_x[bad], 6), " -> ",
                     signif(m_y[bad], 6), "; NA ", n_x[bad], " -> ", n_y[bad], ")",
                     collapse = "; ")
    stop("Read-back check failed for ", basename(path), ": ", detail,
         ". The file does not hold the computed values (check the datatype).",
         call. = FALSE)
  }
  invisible(TRUE)
}

# Write an output table with a numbered slug (tbl_NN_slug.csv).
write_table <- function(x, nn, slug, dir = DIR_TABLES) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  out <- file.path(dir, sprintf("tbl_%02d_%s.csv", as.integer(nn), slug))
  utils::write.csv(x, out, row.names = FALSE)
  message("Wrote ", out, " (", nrow(x), " rows)")
  invisible(out)
}

# Save a fitted model with a dated filename (<species>_<model>_<date>.rds).
save_model <- function(obj, species, model, dir = DIR_MODELS) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  out <- file.path(dir, sprintf("%s_%s_%s.rds", species, model,
                                format(Sys.Date(), "%Y%m%d")))
  saveRDS(obj, out)
  message("Wrote ", out)
  invisible(out)
}
