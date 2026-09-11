source("renv/activate.R")
# =============================================================================
# Add this block to the PROJECT .Rprofile (repo root: tiger-network/.Rprofile).
# It runs at every session start, BEFORE terra/sf load, so PROJ uses terra's
# own proj.db instead of the stale PostGIS one on this machine's PATH.
#
# WHY: PostgreSQL 16 / PostGIS 3.6 puts an old proj.db on PATH
#   (C:\Program Files\PostgreSQL\16\share\contrib\postgis-3.6\proj\proj.db,
#    DATABASE.LAYOUT.VERSION.MINOR = 2, i.e. an ancient PROJ). GDAL/terra load
#   that instead of their own, so EVERY reprojection to EPSG:7755 fails with
#   "empty srs" / "cannot get output boundaries". Pointing PROJ_LIB at terra's
#   bundled database fixes it. Must be set before terra is loaded.
#
# renv note: this .Rprofile line must sit AFTER renv's own
#   source("renv/activate.R") line, so the library paths are set first.
# =============================================================================
 
local({
  # terra's bundled proj.db (preferred); fall back to sf's if terra's is absent.
  proj_terra <- system.file("proj", package = "terra")
  proj_sf    <- system.file("proj", package = "sf")
  proj_dir   <- if (file.exists(file.path(proj_terra, "proj.db"))) {
    proj_terra
  } else if (file.exists(file.path(proj_sf, "proj.db"))) {
    proj_sf
  } else {
    NULL
  }
  if (!is.null(proj_dir)) {
    Sys.setenv(PROJ_LIB = proj_dir)
    # GDAL's own data dir, for the same shadowing reason.
    gdal_dir <- system.file("gdal", package = "terra")
    if (nzchar(gdal_dir)) Sys.setenv(GDAL_DATA = gdal_dir)
    message("[.Rprofile] PROJ_LIB pinned to: ", proj_dir)
  } else {
    warning("[.Rprofile] could not locate a bundled proj.db; ",
            "EPSG:7755 reprojection may fail (PostGIS PROJ clash).")
  }
})
