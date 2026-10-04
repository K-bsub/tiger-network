# =============================================================================
# 02_prepare_boundaries.R
# Build the reserve boundary layer from the NTCA DSS PA/TR/corridor KML.
#
# Decision 4 (docs/methodology.md) is settled: the NTCA DSS PA_TR_Corridor_Final
# KML is the single geometry source for reserves and corridors. Reserve area and
# density come from the NTCA census, NOT from the polygon (the polygon is the
# core PA, ~55% below the legal core+buffer total).
#
# WHAT THE KML ACTUALLY HOLDS (verified Week 3):
#   920 Placemarks, all Polygon/MultiGeometry (no LineStrings).
#     - 705 carry a DESIG field  -> the protected-area polygons
#         (Sanctuary 511, National Park 96, Community Reserve 76,
#          Conservation Reserve 22). Names are NP/sanctuary names, NOT
#          "<X> Tiger Reserve". A tiger reserve is built from one or more of
#          these constituent PAs (e.g. Corbett TR = Corbett NP + Sonanadi WLS).
#     -  59 carry a Corridor field (blank <name>, blank DESIG) -> corridors
#          (POLYGONS, not centrelines). Written to their own layer (added
#          2026-09-26, Week-9 task 9.2a) for the Stage-2 connectivity track;
#          they are not reserve inputs.
#     - 156 are unnamed / no attributes. They are SPATIAL DUPLICATES of the
#          named PA polygons (153/156 sit on top of >=1 named PA). They are NOT
#          reserve inputs and NOT corridors. Preserved to a separate diagnostic
#          layer, excluded from the reserve build.
#
# HOW RESERVES ARE BUILT (crosswalk-driven, Decision-4 area basis):
#   data/raw/ntca/reserve_pa_crosswalk.csv maps each of the 58 reserves to its
#   constituent KML PA name(s) (exact KML spelling, ';'-separated for multi-part
#   reserves). We join KML PA polygons to that crosswalk on NAME + STATE (name
#   alone is ambiguous: two "Pench", two "Rajiv Gandhi"), union the parts, and
#   dissolve to ONE polygon per unit_id. Area is taken from the crosswalk
#   placeholder column and flagged provisional (overwritten in Week 5 from the
#   NTCA census).
#
# 3 reserves have NO KML polygon of their own (Amrabad, Pilibhit,
# Dholpur-Karauli). Pilibhit and Dholpur-Karauli are written as geometry-absent
# rows (empty geometry) so the census still has a home (Decision 17, G1).
#
# STATE SPLIT (STEP 4b; Decision 17 point 7, D1a; added 2026-10-02): the KML
# polygon matched to Nagarjunsagar-Srisailam is the undivided reserve, and
# about 2,701 km2 of it lies in Telangana, where Amrabad now is. The parent
# polygon is split at the state boundary (data/raw/administrative/
# boundary_states_ne_7755.gpkg) per BOUNDARY_STATE_SPLITS in R/00_config.R:
# the Andhra Pradesh part stays unit_id 1, the Telangana part becomes Amrabad
# (unit_id 51). Both parts get match_status = BOUNDARY_SPLIT_STATUS
# ("state_split") and the parent's n_parts. Result: 56 reserves with geometry,
# 2 geometry-absent.
#
# Outputs:
#   data/processed/boundary_reserves_all_7755.gpkg
#     fields: unit_id, unit_name, unit_name_std, state, landscape_complex,
#             area_km2, area_provisional, area_source, n_parts, match_status,
#             geometry_present, source, poly_km2, poly_census_ratio
#   data/processed/boundary_states_7755.gpkg
#   data/processed/boundary_corridors_7755.gpkg        (the 59 corridors;
#                                                       added Week 9, task 9.2a)
#   data/interim/boundary_kml_unattributed_7755.gpkg   (the 156 duplicates)
#   outputs/tables/tbl_02_reserve_build_report.csv     (per-reserve build log)
#
# RE-RUN GUARD (added Week 9; changed 2026-10-02, option G-a): if
# boundary_reserves_all_7755.gpkg already exists, STEP 6 compares the new
# reserve layer to it BEFORE writing, and stops with nothing overwritten if:
#   - the layer on disk already has the state split: any attribute or polygon
#     area differs (the Week-9 rule);
#   - the layer on disk does not have the split yet (the first split run):
#     any row OUTSIDE the split reserves differs in attributes or area; or, on
#     the split reserves, any attribute other than geometry_present,
#     match_status, n_parts, poly_km2 and poly_census_ratio differs; or the
#     split parts are not all geometry_present with BOUNDARY_SPLIT_STATUS; or
#     their total area differs from the area on disk (relative 1e-6).
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(sf)
  library(dplyr)
  library(stringr)
  library(tidyr)
  library(readr)
  library(xml2)
})

source(here("R", "00_config.R"))          # CRS_ANALYSIS, DIR_*, LANDSCAPE_COMPLEXES
source(here("R", "00_functions_io.R"))    # read_vec, write_processed_vec

rule <- function(txt) cat("\n", strrep("=", 78), "\n", txt, "\n",
                          strrep("=", 78), "\n", sep = "")

# ---- Paths ------------------------------------------------------------------
kml_path   <- file.path(DIR_RAW, "ntca", "PA_TR_Corridor_Final",
                        "PA_TR_Corridor_Final.kml")
xwalk_path <- file.path(DIR_RAW, "ntca", "reserve_pa_crosswalk.csv")

reserves_out <- file.path(DIR_PROCESSED, "boundary_reserves_all_7755.gpkg")
corridors_out <- file.path(DIR_PROCESSED, "boundary_corridors_7755.gpkg")
states_out   <- file.path(DIR_PROCESSED, "boundary_states_7755.gpkg")
unattr_out   <- file.path(DIR_INTERIM,   "boundary_kml_unattributed_7755.gpkg")
states_src   <- file.path(DIR_RAW, "administrative", "boundary_states_ne_7755.gpkg")
report_nn    <- 2L
report_slug  <- "reserve_build_report"

stopifnot(file.exists(kml_path))
stopifnot(file.exists(xwalk_path))

# The state split (STEP 4b) needs the state layer and its settings.
for (nm in c("BOUNDARY_STATE_SPLITS", "BOUNDARY_SPLIT_STATUS")) {
  if (!exists(nm)) stop(nm, " is missing from R/00_config.R (Decision 17, D1a).",
                        call. = FALSE)
}
if (length(BOUNDARY_STATE_SPLITS) > 0 && !file.exists(states_src)) {
  stop("State layer not found: ", states_src, " — the state split (STEP 4b) ",
       "needs it.", call. = FALSE)
}

# ---- Small helpers ----------------------------------------------------------
# Name standardiser for robust joins. Lower-case, drop the PA-type words and
# punctuation, collapse whitespace. Applied to BOTH the KML <name> and the
# crosswalk kml_pa_names so spelling of type words never breaks a join.
std_name <- function(x) {
  x <- str_to_lower(x)
  x <- str_replace_all(
    x,
    "\\b(national park|wildlife sanctuary|wls|np|sanctuary|conservation reserve|community reserve|tiger reserve|reserve|wl)\\b",
    " "
  )
  x <- str_replace_all(x, "[^a-z0-9 ]", " ")
  x <- str_squish(x)
  x
}

# State standardiser (KML state_name is upper-case, crosswalk is title-case).
std_state <- function(x) str_replace_all(str_to_lower(x %||% ""), "[^a-z]", "")

# State split (STEP 4b; Decision 17 point 7, D1a). Replaces the parent's
# dissolved polygon with one part per state in spec$parts. Each part keeps the
# polygon parts of parent x state; collections are reduced to their polygons.
# Stops if a name, state or unit_id does not resolve, if a part already has its
# own KML polygon, if a part is empty, or if the parts do not cover the parent
# (relative area difference > 1e-3). Returns the new dissolved layer, the new
# n_parts table, the split unit_ids and a per-part report.
apply_state_split <- function(dissolved, n_parts_tbl, spec, states_sf, xwalk) {
  pid <- as.integer(spec$parent_unit_id)
  xp  <- xwalk[xwalk$unit_id == pid, ]
  if (nrow(xp) != 1L || xp$unit_name != spec$parent_name) {
    stop("State split: parent unit_id ", pid, " does not resolve to '",
         spec$parent_name, "' in the crosswalk.", call. = FALSE)
  }
  if (sum(dissolved$unit_id == pid) != 1L) {
    stop("State split: parent '", spec$parent_name, "' has no dissolved ",
         "polygon.", call. = FALSE)
  }
  geom_col <- attr(dissolved, "sf_column")
  parent_g <- st_geometry(dissolved)[dissolved$unit_id == pid]
  parent_a <- as.numeric(st_area(parent_g))
  part_ids <- vapply(spec$parts, function(p) as.integer(p$unit_id), integer(1))
  if (anyDuplicated(part_ids) || !pid %in% part_ids) {
    stop("State split: part unit_ids must be unique and include the parent.",
         call. = FALSE)
  }
  new_ids <- setdiff(part_ids, pid)
  if (any(new_ids %in% dissolved$unit_id)) {
    stop("State split: unit_id ", paste(new_ids[new_ids %in% dissolved$unit_id],
         collapse = ", "), " already has its own KML polygon.", call. = FALSE)
  }
  parts_g <- vector("list", length(spec$parts))
  report  <- vector("list", length(spec$parts))
  for (i in seq_along(spec$parts)) {
    p  <- spec$parts[[i]]
    xr <- xwalk[xwalk$unit_id == p$unit_id, ]
    if (nrow(xr) != 1L || xr$unit_name != p$unit_name ||
        std_state(xr$state) != std_state(p$state)) {
      stop("State split: part unit_id ", p$unit_id, " does not resolve to '",
           p$unit_name, "' (", p$state, ") in the crosswalk.", call. = FALSE)
    }
    sg <- states_sf[states_sf$name == p$state, ]
    if (nrow(sg) == 0L) {
      stop("State split: state '", p$state, "' not in the state layer.",
           call. = FALSE)
    }
    g <- st_make_valid(st_intersection(parent_g, st_union(st_geometry(sg))))
    if (any(as.character(st_geometry_type(g)) == "GEOMETRYCOLLECTION")) {
      g <- st_collection_extract(g, "POLYGON")
    }
    g <- st_cast(st_union(g), "MULTIPOLYGON")
    a <- as.numeric(st_area(g))
    if (length(g) != 1L || !is.finite(a) || a <= 0) {
      stop("State split: part '", p$unit_name, "' is empty.", call. = FALSE)
    }
    parts_g[[i]] <- g
    report[[i]] <- data.frame(unit_id = as.integer(p$unit_id),
                              unit_name = p$unit_name, state = p$state,
                              part_km2 = round(a / 1e6, 1),
                              n_polygons = length(st_cast(g, "POLYGON")))
  }
  report <- do.call(rbind, report)
  rel_gap <- abs(sum(report$part_km2) * 1e6 - parent_a) / parent_a
  if (rel_gap > 1e-3) {
    stop("State split: the parts cover ", round(sum(report$part_km2), 1),
         " km2 of the parent's ", round(parent_a / 1e6, 1), " km2 — the parent ",
         "reaches a state that is not in the split.", call. = FALSE)
  }
  new_rows <- st_sf(unit_id = part_ids, geometry = do.call(c, parts_g))
  st_geometry(new_rows) <- geom_col
  dissolved_out <- rbind(dissolved[dissolved$unit_id != pid, ], new_rows)
  parent_n <- n_parts_tbl$n_parts[n_parts_tbl$unit_id == pid]
  n_parts_out <- rbind(n_parts_tbl,
                       data.frame(unit_id = new_ids,
                                  n_parts = rep(parent_n, length(new_ids))))
  list(dissolved = dissolved_out, n_parts = n_parts_out,
       split_ids = part_ids, report = report, parent_km2 = parent_a / 1e6)
}

# Normalise attributes for the re-run guard: a GeoPackage round trip can return
# logical fields as integer and change column classes.
norm_attrs <- function(x) {
  d <- as.data.frame(st_drop_geometry(x))
  d[] <- lapply(d, function(col) {
    if (is.logical(col)) as.integer(col)
    else if (is.factor(col)) as.character(col)
    else col
  })
  rownames(d) <- NULL
  d
}

# Re-run guard (STEP 6; option G-a, 2026-10-02). Returns a character vector of
# problems (empty = pass) and the mode used. See the header for the rule.
guard_reserve_layer <- function(old_sf, new_sf, split_ids, split_status) {
  old_sf <- old_sf[order(old_sf$unit_id), ]
  new_sf <- new_sf[order(new_sf$unit_id), ]
  old_df <- norm_attrs(old_sf); new_df <- norm_attrs(new_sf)
  old_a  <- as.numeric(st_area(old_sf)); new_a <- as.numeric(st_area(new_sf))
  if (!identical(names(old_df), names(new_df))) {
    return(list(mode = "names", problems = "column names differ"))
  }
  if (!isTRUE(all.equal(old_df$unit_id, new_df$unit_id))) {
    return(list(mode = "rows", problems = "unit_id sets differ"))
  }
  in_split  <- new_df$unit_id %in% split_ids
  old_split <- length(split_ids) > 0 &&
    all(old_df$match_status[in_split] == split_status)
  if (length(split_ids) == 0 || old_split) {
    probs <- c(
      if (!isTRUE(all.equal(old_df, new_df, check.attributes = FALSE)))
        "attributes differ",
      if (!isTRUE(all.equal(old_a, new_a, tolerance = 1e-9)))
        "polygon areas differ")
    return(list(mode = "identical", problems = probs))
  }
  allowed <- c("geometry_present", "match_status", "n_parts", "poly_km2",
               "poly_census_ratio")
  fixed_cols <- setdiff(names(new_df), allowed)
  probs <- c(
    if (!isTRUE(all.equal(old_df[!in_split, ], new_df[!in_split, ],
                          check.attributes = FALSE)))
      "attributes differ outside the split reserves",
    if (!isTRUE(all.equal(old_a[!in_split], new_a[!in_split], tolerance = 1e-9)))
      "polygon areas differ outside the split reserves",
    if (!isTRUE(all.equal(old_df[in_split, fixed_cols], new_df[in_split, fixed_cols],
                          check.attributes = FALSE)))
      "a fixed attribute changed on a split reserve",
    if (!all(new_df$geometry_present[in_split] == 1L))
      "a split part has no geometry",
    if (!all(new_df$match_status[in_split] == split_status))
      paste0("a split part lacks match_status '", split_status, "'"),
    if (abs(sum(new_a[in_split]) - sum(old_a[in_split])) / sum(old_a[in_split]) > 1e-6)
      "the split parts do not add up to the area on disk"
  )
  list(mode = "first split", problems = probs)
}

# ==============================================================================
# STEP 1 — Read the KML via xml2 and split into the three groups
# ==============================================================================
rule("STEP 1 — parse KML (xml2), split PA polygons / corridors / unattributed")

# WHY xml2 AND NOT st_read:
# The GDAL KML driver on this machine (a) discards the SchemaData/SimpleData
# fields (DESIG, state_name, Corridor) that the whole reserve<->PA match needs,
# and (b) splits the file into two layers ('PA_TR_Corridors' = 764, 'corridor'
# = 156) so a plain st_read sees only 764 and no attributes. Parsing the XML
# directly recovers all 920 placemarks and every field, deterministically.
#
# Geometry is rebuilt directly from each placemark's ring coordinates with
# st_polygon / st_multipolygon (outer boundary + inner holes, multi-part where
# present). st_as_sfc() on the KML text does NOT work for this file's
# MultiGeometry/altitudeMode structure — it returns empty geometries — so the
# rings are parsed explicitly. Verified against the file: 963 outer rings (all
# closed), 500 holes, 99 multi-polygon placemarks.

kml_xml <- read_xml(kml_path)
xml_ns_strip(kml_xml)                          # drop namespaces so paths are simple
placemarks <- xml_find_all(kml_xml, ".//Placemark")
cat("placemarks in KML:", length(placemarks), "\n")
stopifnot(length(placemarks) > 0)

# --- Per-placemark: pull name, the SimpleData fields, and a geometry sfc ------
simple_field <- function(pm, field) {
  node <- xml_find_first(pm, sprintf(".//SimpleData[@name='%s']", field))
  if (inherits(node, "xml_missing")) NA_character_ else str_squish(xml_text(node))
}

# Parse one <coordinates> element's text into an n x 2 matrix (lon, lat).
# KML coordinate tokens are 'lon,lat,alt' separated by whitespace; drop alt.
ring_matrix <- function(coords_node) {
  txt <- str_squish(xml_text(coords_node))
  if (txt == "") return(NULL)
  toks <- strsplit(txt, "\\s+")[[1]]
  xy <- lapply(toks, function(tok) {
    v <- as.numeric(strsplit(tok, ",", fixed = TRUE)[[1]])
    if (length(v) >= 2) v[1:2] else NULL
  })
  xy <- xy[!vapply(xy, is.null, logical(1))]
  if (length(xy) < 4) return(NULL)             # a ring needs >= 4 points
  m <- do.call(rbind, xy)
  # Ensure the ring is closed (first == last); st_polygon requires it.
  if (!isTRUE(all.equal(m[1, ], m[nrow(m), ]))) m <- rbind(m, m[1, ])
  m
}

# Build one placemark's geometry directly from its ring coordinates.
# Structure: MultiGeometry -> one or more <Polygon>; each Polygon has one
# outerBoundaryIs/LinearRing/coordinates and zero+ innerBoundaryIs (holes).
# We assemble st_polygon(list(outer, hole1, ...)) per polygon and combine
# multiple polygons into an st_multipolygon. No GDAL text parsing (st_as_sfc on
# KML fails for this file's MultiGeometry/altitudeMode structure).
placemark_geom <- function(pm) {
  poly_nodes <- xml_find_all(pm, ".//Polygon")
  if (length(poly_nodes) == 0) {
    return(st_sfc(st_multipolygon(), crs = CRS_WGS84))
  }
  polys <- list()
  for (poly in poly_nodes) {
    outer <- xml_find_first(poly, "./outerBoundaryIs/LinearRing/coordinates")
    if (inherits(outer, "xml_missing")) next
    om <- ring_matrix(outer)
    if (is.null(om)) next
    rings <- list(om)
    for (inner in xml_find_all(poly, "./innerBoundaryIs/LinearRing/coordinates")) {
      im <- ring_matrix(inner)
      if (!is.null(im)) rings[[length(rings) + 1]] <- im
    }
    polys[[length(polys) + 1]] <- st_polygon(rings)
  }
  if (length(polys) == 0) {
    return(st_sfc(st_multipolygon(), crs = CRS_WGS84))
  }
  # Combine into a single MULTIPOLYGON for this placemark. st_multipolygon takes
  # a list of polygons, each a list of rings (outer + holes). Each element of
  # `polys` is an st_polygon (already a list of ring matrices), so pass them
  # through with unclass() to strip the sfg class but keep the ring lists.
  mp <- st_multipolygon(lapply(polys, unclass))
  st_sfc(mp, crs = CRS_WGS84)
}

n  <- length(placemarks)
nm_v    <- character(n); desig_v <- character(n)
state_v <- character(n); corr_v  <- character(n)
geoms   <- vector("list", n)

for (i in seq_len(n)) {
  pm <- placemarks[[i]]
  ne <- xml_find_first(pm, "./name")
  nm_v[i]    <- if (inherits(ne, "xml_missing")) NA_character_ else str_squish(xml_text(ne))
  desig_v[i] <- simple_field(pm, "DESIG")
  state_v[i] <- simple_field(pm, "state_name")
  corr_v[i]  <- simple_field(pm, "Corridor")
  geoms[[i]] <- placemark_geom(pm)
}

geom_sfc <- do.call(c, geoms)                  # combine into one sfc (WGS84)

kml <- st_sf(
  .name  = nm_v,
  .desig = desig_v,
  .state = state_v,
  .corr  = corr_v,
  geometry = geom_sfc
)

# Drop Z, force 2D polygons, reproject to the analysis CRS, make valid.
kml <- st_zm(kml, drop = TRUE, what = "ZM")
kml <- st_make_valid(st_transform(kml, CRS_ANALYSIS))

kml <- kml |>
  mutate(
    .has_desig = !is.na(.desig) & str_squish(.desig) != "",
    .has_corr  = !is.na(.corr)  & str_squish(.corr)  != ""
  )

# Sanity: field-based split must reproduce the known 705 / 59 / 156 shape.
cat(sprintf("parsed: %d placemarks | DESIG=%d Corridor=%d empty=%d\n",
            nrow(kml), sum(kml$.has_desig), sum(kml$.has_corr),
            sum(!kml$.has_desig & !kml$.has_corr)))

pa_poly    <- kml |> filter(.has_desig)                 # named PA polygons (705)
corridors  <- kml |> filter(!.has_desig & .has_corr)    # corridors (59) — dropped
unattr     <- kml |> filter(!.has_desig & !.has_corr)   # unnamed duplicates (156)

cat(sprintf("  PA polygons (DESIG): %d\n", nrow(pa_poly)))
cat(sprintf("  corridors (Corridor field): %d  [written to boundary_corridors in STEP 6]\n",
            nrow(corridors)))
cat(sprintf("  unattributed / duplicates: %d  [preserved to diagnostic layer]\n",
            nrow(unattr)))

# Preserve the unattributed placemarks (do not silently drop) -----------------
if (nrow(unattr) > 0) {
  if (!dir.exists(DIR_INTERIM)) dir.create(DIR_INTERIM, recursive = TRUE)
  unattr |>
    transmute(kml_row = row_number(),
              note = "unnamed KML placemark; spatial duplicate of a named PA; not a reserve input") |>
    st_write(unattr_out, delete_dsn = TRUE, quiet = TRUE)
  cat("  wrote diagnostic layer:", unattr_out, "\n")
}

# ==============================================================================
# STEP 2 — Read the crosswalk and expand multi-part reserves
# ==============================================================================
rule("STEP 2 — read reserve->PA crosswalk, expand parts")

xwalk <- read_csv(xwalk_path, show_col_types = FALSE)

req_cols <- c("unit_id", "unit_name", "state", "landscape_complex",
              "area_km2_placeholder", "area_source", "kml_pa_names",
              "match_status")
missing_cols <- setdiff(req_cols, names(xwalk))
if (length(missing_cols) > 0) {
  stop("crosswalk is missing columns: ", paste(missing_cols, collapse = ", "),
       call. = FALSE)
}

# Validate landscape_complex against the controlled vocabulary.
bad_lc <- setdiff(unique(xwalk$landscape_complex), LANDSCAPE_COMPLEXES)
if (length(bad_lc) > 0) {
  stop("crosswalk landscape_complex not in LANDSCAPE_COMPLEXES: ",
       paste(bad_lc, collapse = ", "), call. = FALSE)
}

# One row per (reserve, constituent PA). Blank kml_pa_names -> geometry-absent.
parts <- xwalk |>
  mutate(kml_pa_names = ifelse(is.na(kml_pa_names), "", kml_pa_names)) |>
  separate_rows(kml_pa_names, sep = ";") |>
  mutate(
    pa_name_raw = str_squish(kml_pa_names),
    pa_std      = std_name(pa_name_raw),
    state_std   = std_state(state)
  )

n_geom_reserves <- xwalk |> filter(str_squish(replace_na(kml_pa_names, "")) != "") |> nrow()
cat(sprintf("reserves in crosswalk: %d | with >=1 PA name: %d | geometry-absent: %d\n",
            nrow(xwalk), n_geom_reserves, nrow(xwalk) - n_geom_reserves))

# ==============================================================================
# STEP 3 — Attach unit_id to each KML PA polygon via a NON-spatial name+state key
# ==============================================================================
rule("STEP 3 — match PA polygons to reserve parts (name + state)")

# Non-spatial lookup: (pa_std, state_std) -> unit_id, from the crosswalk parts.
# Kept as a plain tibble (no geometry) so the join stays a clean attribute join.
part_key <- parts |>
  filter(pa_name_raw != "") |>
  distinct(unit_id, unit_name, pa_name_raw, pa_std, state_std)

# Guard: a (pa_std, state_std) key should map to ONE reserve. If the same PA key
# points at two reserves, the crosswalk is ambiguous — stop and show it.
dup_key <- part_key |>
  count(pa_std, state_std, name = "n_units") |>
  filter(n_units > 1)
if (nrow(dup_key) > 0) {
  cat("!! crosswalk PA key maps to >1 reserve (ambiguous) — fix the crosswalk:\n")
  part_key |>
    semi_join(dup_key, by = c("pa_std", "state_std")) |>
    arrange(pa_std) |>
    mutate(l = sprintf("   key(%s | %s) -> #%d %s",
                       pa_std, state_std, unit_id, unit_name)) |>
    pull(l) |> cat(sep = "\n")
  stop("ambiguous PA->reserve keys; resolve before building.", call. = FALSE)
}

# Tag every KML PA polygon with its unit_id (attribute join on the pair key).
# sf keeps its geometry through a left_join when the sf object is on the left.
pa_tagged <- pa_poly |>
  mutate(pa_std = std_name(.name), state_std = std_state(.state)) |>
  left_join(part_key |> select(unit_id, pa_std, state_std),
            by = c("pa_std", "state_std"))

# Report crosswalk parts that matched NO KML polygon (spelling / state issues).
matched_keys <- pa_tagged |>
  st_drop_geometry() |>
  filter(!is.na(unit_id)) |>
  distinct(pa_std, state_std)
parts_nomatch <- part_key |>
  anti_join(matched_keys, by = c("pa_std", "state_std"))
if (nrow(parts_nomatch) > 0) {
  cat("!! crosswalk parts with NO KML polygon (name+state) — check spelling/state:\n")
  parts_nomatch |>
    arrange(unit_id) |>
    mutate(l = sprintf("   #%d %s  ->  part '%s'", unit_id, unit_name, pa_name_raw)) |>
    pull(l) |> cat(sep = "\n")
  cat("\n")
} else {
  cat("all non-blank crosswalk parts matched at least one KML polygon.\n")
}

# Report KML polygons that matched no reserve (informational — most of the 705
# PAs are not tiger reserves, so a large number here is expected and fine).
n_pa_unused <- pa_tagged |> st_drop_geometry() |> filter(is.na(unit_id)) |> nrow()
cat(sprintf("KML PA polygons used by a reserve: %d | not used (non-TR PAs): %d\n",
            sum(!is.na(pa_tagged$unit_id)), n_pa_unused))

# ==============================================================================
# STEP 4 — Dissolve tagged polygons to ONE polygon per reserve (canonical sf)
# ==============================================================================
rule("STEP 4 — dissolve constituent PAs to one polygon per reserve")

# n_parts = number of KML polygons feeding each reserve (before the union).
n_parts_tbl <- pa_tagged |>
  st_drop_geometry() |>
  filter(!is.na(unit_id)) |>
  count(unit_id, name = "n_parts")

# Canonical dissolve: group_by(unit_id) |> summarise() unions the geometries.
# This is the standard, stable sf idiom — no list-columns, no group_map.
dissolved_sf <- pa_tagged |>
  filter(!is.na(unit_id)) |>
  st_make_valid() |>
  group_by(unit_id) |>
  summarise(.groups = "drop") |>
  st_make_valid()

cat(sprintf("reserves with dissolved geometry: %d\n", nrow(dissolved_sf)))

# ==============================================================================
# STEP 4b — State split (Decision 17 point 7, D1a; BOUNDARY_STATE_SPLITS)
# ==============================================================================
rule("STEP 4b — split parent polygon(s) at the state boundary (Decision 17, D1a)")

split_ids <- integer(0)
if (length(BOUNDARY_STATE_SPLITS) > 0) {
  states_split_sf <- read_vec(states_src) |> st_make_valid()
  if (!"name" %in% names(states_split_sf)) {
    stop("State layer has no 'name' field: ", states_src, call. = FALSE)
  }
  for (spec in BOUNDARY_STATE_SPLITS) {
    sp <- apply_state_split(dissolved_sf, n_parts_tbl, spec, states_split_sf, xwalk)
    dissolved_sf <- sp$dissolved
    n_parts_tbl  <- sp$n_parts
    split_ids    <- c(split_ids, sp$split_ids)
    cat(sprintf("split '%s' (%.1f km2) at the state boundary:\n",
                spec$parent_name, sp$parent_km2))
    print(sp$report, row.names = FALSE)
  }
  dissolved_sf <- dissolved_sf[order(dissolved_sf$unit_id), ]
  rm(states_split_sf)
}
cat(sprintf("reserves with geometry after the split: %d\n", nrow(dissolved_sf)))

# ==============================================================================
# STEP 5 — Attach attributes, add geometry-absent reserves, finalise
# ==============================================================================
rule("STEP 5 — attach attributes, add geometry-absent reserves")

# Per-reserve attributes (one row per reserve from the crosswalk).
attrs <- xwalk |>
  transmute(
    unit_id,
    unit_name,
    unit_name_std = std_name(unit_name),
    state,
    landscape_complex,
    area_km2 = suppressWarnings(as.numeric(area_km2_placeholder)),
    area_provisional = TRUE,                 # Decision 4: overwrite from census (Week 5)
    area_source,
    match_status,
    source = "ntca"
  )

# Reserves WITH geometry: join attributes + n_parts onto the dissolved sf.
reserves_geom <- dissolved_sf |>
  left_join(attrs,       by = "unit_id") |>
  left_join(n_parts_tbl, by = "unit_id") |>
  mutate(geometry_present = TRUE)

# Reserves WITHOUT geometry (crosswalk has no PA name and no split part): build
# empty-geometry rows so the census still has a home. These are the 2 known
# gaps (Pilibhit, Dholpur-Karauli; Decision 17, G1).
ids_with_geom <- reserves_geom$unit_id
empty_geom <- st_sfc(st_multipolygon(), crs = CRS_ANALYSIS)
reserves_nogeom <- attrs |>
  filter(!unit_id %in% ids_with_geom) |>
  mutate(n_parts = 0L, geometry_present = FALSE)
if (nrow(reserves_nogeom) > 0) {
  reserves_nogeom <- st_sf(
    reserves_nogeom,
    geometry = st_sfc(rep(list(st_multipolygon()), nrow(reserves_nogeom)),
                      crs = CRS_ANALYSIS)
  )
  cat("geometry-absent reserves (no KML polygon):\n")
  reserves_nogeom |> st_drop_geometry() |>
    mutate(l = sprintf("   #%d %s [%s]", unit_id, unit_name, state)) |>
    pull(l) |> cat(sep = "\n")
  cat("\n")
}

# Align geometry column names, then bind the two sets.
st_geometry(reserves_geom)  <- "geometry"
reserves_sf <- if (nrow(reserves_nogeom) > 0) {
  rbind(
    reserves_geom  |> select(names(attrs), n_parts, geometry_present),
    reserves_nogeom |> select(names(attrs), n_parts, geometry_present)
  )
} else {
  reserves_geom |> select(names(attrs), n_parts, geometry_present)
}

reserves_sf <- reserves_sf |>
  arrange(unit_id) |>
  select(unit_id, unit_name, unit_name_std, state, landscape_complex,
         area_km2, area_provisional, area_source, n_parts, match_status,
         geometry_present, source)

# Split parts (STEP 4b) carry BOUNDARY_SPLIT_STATUS, so later steps (scripts/07
# STEP 9.2) can see that the layer has the split.
reserves_sf$match_status[reserves_sf$unit_id %in% split_ids] <- BOUNDARY_SPLIT_STATUS

cat(sprintf("reserves built: %d | with geometry: %d | geometry-absent: %d\n",
            nrow(reserves_sf), sum(reserves_sf$geometry_present),
            sum(!reserves_sf$geometry_present)))

# Guard: exactly the 58 reserves, unit_id unique.
stopifnot(nrow(reserves_sf) == 58L)
stopifnot(!any(duplicated(reserves_sf$unit_id)))

# ---- QA columns: polygon area and polygon/census ratio ----------------------
# poly_km2 is the KML-derived geometry area; area_km2 is the (provisional)
# census total. The ratio makes the Decision-4 gap visible per reserve and flags
# outliers downstream WITHOUT a separate check. Expected: ratio < 1 for most
# (core-PA polygon under-states the legal total). A ratio > ~1.1 means the KML
# polygon over-extends the notified reserve (coarse source geometry) — geometry
# is for mapping/connectivity only, so this does not affect any census-based
# metric, but it is worth seeing.
poly_area_km2 <- round(as.numeric(st_area(reserves_sf)) / 1e6, 1)
reserves_sf <- reserves_sf |>
  mutate(
    poly_km2          = ifelse(geometry_present, poly_area_km2, NA_real_),
    poly_census_ratio = ifelse(geometry_present & is.finite(poly_km2 / area_km2),
                               round(poly_km2 / area_km2, 2), NA_real_)
  )

# Flag polygons that over-extend the census total (informational, not an error).
over_ext <- reserves_sf |>
  st_drop_geometry() |>
  filter(!is.na(poly_census_ratio), poly_census_ratio > 1.1) |>
  arrange(desc(poly_census_ratio))
if (nrow(over_ext) > 0) {
  cat("note — KML polygon over-extends census area (coarse geometry; mapping only):\n")
  over_ext |>
    mutate(l = sprintf("   #%d %s  poly %.0f / census %.0f  (ratio %.2f)",
                       unit_id, unit_name, poly_km2, area_km2, poly_census_ratio)) |>
    pull(l) |> cat(sep = "\n")
  cat("\n")
}

# ==============================================================================
# STEP 6 — Write reserve layer + states layer + build report
# ==============================================================================
rule("STEP 6 — write outputs")

if (!dir.exists(DIR_PROCESSED)) dir.create(DIR_PROCESSED, recursive = TRUE)

# ---- Re-run guard (option G-a): only the split reserves may change ----------
# Compare against the layer on disk BEFORE overwriting it (rule in the header).
# Any problem stops the script with nothing overwritten.
if (file.exists(reserves_out)) {
  old_sf <- st_read(reserves_out, quiet = TRUE)
  g <- guard_reserve_layer(old_sf, reserves_sf, split_ids, BOUNDARY_SPLIT_STATUS)
  if (length(g$problems) > 0) {
    stop("Re-run guard (", g$mode, "): ", paste(g$problems, collapse = "; "),
         ". Nothing was overwritten. Inspect the difference before you replace ",
         reserves_out, ".", call. = FALSE)
  }
  cat("re-run guard (", g$mode, "): pass — ",
      if (g$mode == "first split") {
        paste0("only the split reserves (unit_id ",
               paste(split_ids, collapse = ", "), ") changed, as allowed")
      } else {
        "reserve layer identical to the one on disk (attributes + areas)"
      }, ".\n", sep = "")
}

# Reserve layer.
st_write(reserves_sf, reserves_out, delete_dsn = TRUE, quiet = TRUE)
cat("wrote", reserves_out, "(", nrow(reserves_sf), "reserves )\n")

# Corridor layer (Week 9, task 9.2a). The 59 NTCA corridor POLYGONS separated in
# STEP 1. Field names stay close to the KML: `kml_name` is the placemark
# <name>, `corridor_label` is the SimpleData Corridor field. No name is
# invented; a blank stays NA.
blank_to_na <- function(v) ifelse(is.na(v) | str_squish(v) == "", NA_character_, v)

# Decode XML entities left in the text. Some Corridor values are escaped twice
# in the KML (for example "&amp;apos;"), so xml2 decodes once and leaves
# "&apos;" in the value (as built: "Dibru Saikhowa-D &apos;e",
# "D&apos; Ering-mehao"). This restores the character the KML means; it does
# not change a name. Applied to the corridor fields only — the PA names drive
# the reserve crosswalk and are left untouched (the re-run guard above would
# stop on any change there). &amp; is decoded LAST so "&amp;lt;" is not
# decoded twice.
decode_xml_entities <- function(v) {
  v <- str_replace_all(v, fixed("&apos;"), "'")
  v <- str_replace_all(v, fixed("&quot;"), '"')
  v <- str_replace_all(v, fixed("&lt;"),   "<")
  v <- str_replace_all(v, fixed("&gt;"),   ">")
  v <- str_replace_all(v, fixed("&amp;"),  "&")
  v
}
corridors_sf <- corridors |>
  mutate(
    corridor_id    = row_number(),
    kml_name       = decode_xml_entities(blank_to_na(.name)),
    corridor_label = decode_xml_entities(blank_to_na(.corr)),
    state          = decode_xml_entities(blank_to_na(.state)),
    source         = "ntca"
  ) |>
  select(corridor_id, kml_name, corridor_label, state, source)
left_entities <- grepl("&[A-Za-z#0-9]+;", c(corridors_sf$kml_name,
                                             corridors_sf$corridor_label,
                                             corridors_sf$state))
if (any(left_entities)) {
  warning(sum(left_entities), " corridor field value(s) still hold an XML ",
          "entity after decoding — inspect them.")
}
n_empty_corr <- sum(st_is_empty(corridors_sf))
if (nrow(corridors_sf) != 59L) {
  warning("expected 59 corridor polygons, found ", nrow(corridors_sf),
          " — inspect the KML split in STEP 1.")
}
if (n_empty_corr > 0) {
  warning(n_empty_corr, " corridor polygon(s) have empty geometry.")
}
st_write(corridors_sf, corridors_out, delete_dsn = TRUE, quiet = TRUE)
cat("wrote", corridors_out, "(", nrow(corridors_sf), "corridors;",
    sum(!is.na(corridors_sf$corridor_label)), "with a Corridor label )\n")

# States layer (the other declared 02 output) — from the acquired admin layer
# (states_src, set in Paths).
if (file.exists(states_src)) {
  states_sf <- read_vec(states_src) |> st_make_valid()
  st_write(states_sf, states_out, delete_dsn = TRUE, quiet = TRUE)
  cat("wrote", states_out, "(", nrow(states_sf), "states )\n")
} else {
  warning("states source not found (", states_src,
          ") — boundary_states_7755.gpkg not written.")
}

# Per-reserve build report (for hand-checking the review/gap and outlier rows).
report <- reserves_sf |>
  st_drop_geometry() |>
  transmute(unit_id, unit_name, state, landscape_complex,
            area_km2, area_provisional, poly_km2, poly_census_ratio,
            n_parts, match_status, geometry_present)
write_table(report, report_nn, report_slug)

rule("02 done. Reserve layer, state layer, corridor layer, and build report written.")
