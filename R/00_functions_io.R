# =============================================================================
# 00_functions_io.R
# Input / output helpers. Sourced, never run standalone.
# Every read reprojects to the analysis CRS; every write is deterministic.
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

# Write a processed raster as GeoTIFF with sensible compression.
write_processed_rast <- function(x, filename, dir = DIR_PROCESSED) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  out <- file.path(dir, filename)
  terra::writeRaster(
    x, out, overwrite = TRUE,
    gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "TILED=YES")
  )
  message("Wrote ", out)
  invisible(out)
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
