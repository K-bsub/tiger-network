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
#          (POLYGONS, not centrelines). DROPPED here (Stage 2 re-extracts them).
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
# 3 reserves have NO KML geometry (Amrabad, Pilibhit, Dholpur-Karauli). They are
# written as geometry-absent rows (empty geometry) so the census still has a
# home; resolve by hand later if a geometry is wanted.
#
# Outputs:
#   data/processed/boundary_reserves_all_7755.gpkg
#     fields: unit_id, unit_name, unit_name_std, state, landscape_complex,
#             area_km2, area_provisional, area_source, n_parts, match_status,
#             geometry_present, source
#   data/processed/boundary_states_7755.gpkg
#   data/interim/boundary_kml_unattributed_7755.gpkg   (the 156 duplicates)
#   outputs/tables/tbl_02_reserve_build_report.csv     (per-reserve build log)
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
states_out   <- file.path(DIR_PROCESSED, "boundary_states_7755.gpkg")
unattr_out   <- file.path(DIR_INTERIM,   "boundary_kml_unattributed_7755.gpkg")
report_nn    <- 2L
report_slug  <- "reserve_build_report"

stopifnot(file.exists(kml_path))
stopifnot(file.exists(xwalk_path))

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
cat(sprintf("  corridors (Corridor field): %d  [DROPPED - Stage 2 re-extracts]\n",
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

# Reserves WITHOUT geometry (crosswalk has no PA name): build empty-geometry rows
# so the census still has a home. These are the 3 known gaps.
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

# Reserve layer.
if (!dir.exists(DIR_PROCESSED)) dir.create(DIR_PROCESSED, recursive = TRUE)
st_write(reserves_sf, reserves_out, delete_dsn = TRUE, quiet = TRUE)
cat("wrote", reserves_out, "(", nrow(reserves_sf), "reserves )\n")

# States layer (the other declared 02 output) — from the acquired admin layer.
states_src <- file.path(DIR_RAW, "administrative", "boundary_states_ne_7755.gpkg")
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

rule("02 done. NEXT: hand-check tbl_02 review/gap rows; overwrite area_km2 from census in Week 5.")
