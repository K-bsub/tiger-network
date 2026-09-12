# Data Sources

Human-readable citations, access steps, and licences. The machine-readable
inventory that `scripts/00b_audit_data.R` checks against is
`data/data_manifest.csv`. Keep the two in sync: if you add a dataset, add a row
to the manifest and a section here.

Most datasets come from the two earlier tiger projects. **Run the audit
(`00b`) before re-downloading** — space was reclaimed and some files may be gone.

---

## Population

### NTCA All India Tiger Estimation (2006, 2010, 2014, 2018, 2022)
- **Role:** Primary population data (growth track).
- **Source:** National Tiger Conservation Authority & Wildlife Institute of India.
- **Access:** https://ntca.gov.in — PDF reports + Excel. **Manual.**
- **Licence:** Government of India.
- **Note:** Phase 1 extracted reserve-level figures for 7 reserves only.
  Extending to all reserves is the main new data effort.

### Singh & Sen (2015) — Karnataka 2006–2010 gap-fill
- **Role:** Fills the Bandipur/Nagarahole 2006–2010 gap.
- **Source:** *Am Research Thoughts*, Vol. 1, pp. 1796–1812.
- **Licence:** Research paper. Supplementary, not primary.

---

## Boundaries

Boundary source is fixed by **Decision 4** (see `docs/methodology.md`). The
NTCA DSS KML is the single geometry source for reserves and corridors; reserve
**area and density come from the NTCA census table, not from the polygon
geometry**. The Week-2 assessment of the alternatives is recorded below so the
rejections are not re-litigated.

### NTCA DSS — PA / TR / Corridor KML (PRIMARY, chosen)
- **Role:** Single geometry source — reserve boundaries (mapping, connectivity)
  and tiger corridors (connectivity track). **Not** used for reserve area.
- **Source:** National Tiger Conservation Authority, Decision Support System
  (https://ntca.gov.in/dss/).
- **Full citation:** National Tiger Conservation Authority (2022).
  *PA_TR_Corridor_Final* [KML Dataset]. Decision Support System, NTCA, Ministry
  of Environment, Forests and Climate Change, Government of India, New Delhi.
  July 2022.
- **Direct download:**
  https://ntca.gov.in/wp-content/uploads/2022/07/PA_TR_Corridor_Final.zip
  (direct ZIP, no login).
- **Raw file:** `data/raw/ntca/PA_TR_Corridor_Final/PA_TR_Corridor_Final.kml`
- **CRS (raw):** EPSG:4326. **Licence:** Government of India; attribution
  required; research/education use.
- **Currency:** July 2022.
- **Basis and limits:** geometry is the **core protected-area polygon, not the
  legal core-plus-buffer tiger-reserve extent** (as-built polygon/census ratio
  median near 0.58; most polygons under-state the legal area). The KML holds
  national-park / sanctuary polygons, so each reserve is built from its
  constituent PA(s) via `data/raw/ntca/reserve_pa_crosswalk.csv` and dissolved
  (see the Week-3 change log in `docs/methodology.md`). Covers 55 of 58 reserves;
  3 have no KML polygon (Amrabad, Pilibhit, Dholpur-Karauli — each a 2014+
  reserve, absent from the July-2022 KML) and are kept as geometry-absent rows.
  Corridors are separate named polygons (`Corridor` field, some blank); the
  connectivity track re-extracts them. Infrastructure-clearance dataset, not
  peer-reviewed spatial data — authoritative for approximate extents only.

### KBA Global — Key Biodiversity Areas (assessed, NOT selected)
- **Role:** Phase 1 boundary source; assessed in Week 2 as an alternative.
- **Source:** BirdLife International / KBA Partnership
  (https://www.keybiodiversityareas.org). **Licence:** Non-commercial,
  attribution required.
- **Why not selected:** covers 51 of 58 reserves (fewer than the KML), has the
  **same core-PA area limitation** as the KML (it stores the core NP/sanctuary
  polygon, not the legal TR extent), and carries **no corridor geometry**. The
  KML gives better coverage and corridors from one source, so KBA adds nothing.
- **Phase-1 note (superseded framing):** Phase 1 saw KBA *inflate* Corbett
  (buffer-inclusive polygon). At national scale the dominant error is the
  opposite — *under*-statement from core-only polygons. Either way, KBA is not a
  legal-TR-extent layer. Kept for reference only.

### WDPA (Protected Planet) — India (REJECTED, unusable)
- **Role:** Considered as an open, standards-based boundary source.
- **Why rejected:** India shares **zero national protected areas** with the
  public WDPA. The India country profile states "Number of national
  designations only = 0" for both WDPA and WD-OECM. The India extract holds only
  international designations (Ramsar sites, World Heritage Sites, one Biosphere
  Reserve — 63 polygons), no national parks, sanctuaries, or tiger reserves.
  WDPA cannot supply reserve boundaries for India. Recorded so this is not
  re-checked.

### Reserve→PA crosswalk (project-built reference)
- **Role:** Maps each of the 58 tiger reserves to its constituent KML PA
  polygon name(s) (exact KML spelling, `;`-separated for multi-part reserves).
  Drives the reserve build in `scripts/02`. Also carries a **provisional**
  `area_km2_placeholder` (source: published NTCA/Wikipedia core+buffer totals),
  overwritten from the NTCA census in Week 5.
- **File:** `data/raw/ntca/reserve_pa_crosswalk.csv` (hand-reviewed;
  gitignored with the rest of `data/raw`).
- **Built:** Week 3, from the KML PA names + the NTCA 58-reserve reference list.
- **Role:** State/district context and roll-up (Decision 2 units).
- **States:** Natural Earth admin-1 via `rnaturalearth::ne_states` (public
  domain). 36 states/UTs. Output `boundary_states_ne_7755.gpkg`.
- **Districts:** DataMeet Census-2011 shapefile
  (`datameet/maps` → `Districts/Census_2011/2011_Dist`), pulled file-by-file from
  raw.githubusercontent.com, CC BY 4.0. 641 districts. Output
  `boundary_districts_datameet2011_7755.gpkg`.
- **Vintage caveat:** DataMeet districts are **Census 2011** — India has split
  many districts since, so newer districts are absent. Fine for context /
  roll-up; note before any district-level attribute join.

---

## Occurrences and effort

### GBIF — Panthera tigris in India
- **Role:** Occurrence data for SDM and the effort thread.
- **Source:** https://www.gbif.org (`rgbif` `occ_download`).
- **DOI:** https://doi.org/10.15468/dl.npxmxx (accessed 2026-09-07).
- **Citation:** GBIF.org (2026-09-07) GBIF Occurrence Download
  https://doi.org/10.15468/dl.npxmxx
- **Licence:** CC BY / CC0 per record.
- **Method:** national bbox predicate, then clipped to the India boundary on
  import (see `scripts/01`). 4,606 records inside India (93% of the bbox pull).
- **Note (quality, for Week 13):** median coordinate uncertainty ~30 km; a large
  fraction will be dropped at the 1 km grid. Year span 1840–2026 (windowed at
  cleaning). Raw clipped points in
  `data/interim/occ_tiger_gbif_raw_7755.gpkg`.

### GBIF — target-group background (Mammalia only)
- **Role:** Sampling-effort layer; target-group bias correction for the SDM.
  **New to this project.**
- **Source:** https://www.gbif.org async `occ_download` (no 10k cap).
- **DOI:** https://doi.org/10.15468/dl.2d523e (accessed 2026-09-07).
- **Citation:** GBIF.org (2026-09-07) GBIF Occurrence Download
  https://doi.org/10.15468/dl.2d523e
- **Licence:** CC BY / CC0 per record.
- **Scope:** all Mammalia (class), tiger excluded, 2006–2022, national bbox →
  clipped to India. 39,057 points inside India (75% of pull). **Mammalia only,
  not all vertebrates** — see Decision 5 (birds/fish do not share the tiger's
  sampling bias). Raw clipped points in
  `data/interim/effort_background_tgs_7755.gpkg`.

---

## Covariates

### ESA WorldCover 2021 v200
- **Role:** Land cover for resistance surface and SDM.
- **Source:** https://esa-worldcover.org (public AWS COGs, EPSG:4326).
- **DOI:** https://doi.org/10.5281/zenodo.7254221. **Resolution:** 10 m.
  **Licence:** CC BY 4.0.
- **Acquisition (as built, `scripts/01`):** 3°×3° tiles windowed-read via
  `/vsicurl` (lower-left-corner naming, e.g. N21E078), each reprojected to 1 km
  EPSG:7755 by **modal (majority) class** (categorical layer), then merged and
  clipped to India. 88 tiles overlap the AOI. Output:
  `data/interim/cov_landcover_worldcover2021_1km_7755.tif`; per-tile 1 km cache
  in `data/raw/worldcover/tiles_1km/` (resumable).
- **Class codes present:** 10,20,30,40,50,60,70,80,90,95,100 (all 11 expected).
- **Known issue (from Bay Area):** under-maps chaparral/shrub; check relevance
  for Indian dry-forest classes at model fit. Per-class fractional cover, if
  needed, is a Week-8 zonal step over reserves/corridors (as in Phase 2), not a
  re-pull.

### Terrain — elevation, slope, TRI (AWS Terrain Tiles)
- **Role:** Elevation, slope, and TRI covariates for the SDM (and connectivity).
- **Source:** AWS Open Data Terrain Tiles via `elevatr::get_elev_raster`
  (Mapzen/Tilezen synthesis DEM). https://registry.opendata.aws/terrain-tiles/
- **Licence:** Public domain / open (see AWS Terrain Tiles attribution).
- **Acquisition (as built, `scripts/01`):** DEM pulled at **zoom 7** (~1 km at
  India latitudes — matched to the covariate grid, no 30 m national over-pull),
  clipped to India. **Slope (degrees) and TRI derived on the native DEM** with
  `terra::terrain()` before resampling (deriving after coarsening would
  understate ruggedness), then all three reprojected to the 1 km EPSG:7755
  template (bilinear). Raw DEM cached as
  `data/raw/terrain/dem_india_aws_z7_4326.tif`; 3-band output
  `data/interim/cov_terrain_1km_7755.tif`.
- **Coverage check:** DEM covers the full India bbox; interior fully filled
  (3,067,585 cells inside India). Ranges: elevation −413 to 7,914 m (Himalaya to
  coastal/salt-flat lows), slope 0–45° (1 km-aggregated), TRI 0–635.
- **Superseded plan:** Phase 1 used SRTM 30 m tiles (EarthExplorer). Replaced
  here by elevatr AWS tiles at 1 km — no national 30 m pull needed for a 1 km
  covariate.

### Global Human Modification (gHM)
- **Role:** Human-pressure covariate for connectivity and SDM.
- **Source:** Theobald et al. 2024/2025 v3, Zenodo record 14502573, 2022 static
  snapshot, all-threats-combined (AA), 300 m COG, EPSG:4326.
- **DOI:** https://doi.org/10.5281/zenodo.14502573 (data);
  https://doi.org/10.1038/s41597-025-04892-2 (paper). **Licence:** CC BY 4.0.
- **File:** `HMv20240801_2022s_AA_300.tif` (AA = all threats; other codes on the
  record: BU/HI/FR/TI/AG/EX/NS/PO).
- **Acquisition (as built, `scripts/01`):** windowed `/vsicurl` read → clip →
  reproject to 1 km EPSG:7755 (bilinear, continuous 0–1). Output:
  `data/interim/cov_ghm2022_1km_7755.tif`; source stamp in
  `data/raw/ghm/ghm_source_stamp.txt`.
- **Check:** India min/max 0 / 0.993, mean 0.377 (values correctly within 0–1).
- **Chosen over** Kennedy 2019 (per Bay Area Decision 15).

### OpenStreetMap — roads and settlements (India)
- **Role:** Road barriers for connectivity; settlement/human-footprint context.
- **Source:** Geofabrik India `.osm.pbf` via `osmextract::oe_get`
  (https://download.geofabrik.de/asia/india.html). **Licence:** ODbL —
  attribution required (© OpenStreetMap contributors).
- **Acquisition (as built, `scripts/01`):** Geofabrik India extract (~1.5 GB
  pbf, cached in `data/raw/osm/geofabrik_cache/`), filtered server-side via GDAL
  SQL, clipped to India, reprojected to EPSG:7755.
  - **Roads** (`highway`): motorway, trunk, primary, secondary, tertiary (+
    `_link` ramps). **885,669 features** — tertiary-dominated (432,689).
    Residential/track excluded. Output `osm_roads_major_7755.gpkg`.
  - **Settlements** (`place`): city (495), town (4,102), village (195,203) —
    **199,800 points total**. Output `osm_settlements_7755.gpkg`.
- **Flag for Week 8–9 (KDE / resistance build):** the settlement layer is
  **village-dominated** (~195k of 199,800). A 15 km KDE over that many points
  will near-saturate across India and may not discriminate. Consider trimming to
  city/town (4,597 points) or a smaller radius when the density surface is built.
  Similarly, tertiary roads dominate the road layer; dropping tertiary is a
  one-line filter if the barrier surface is too dense. Both are pending Decisions
  (see `docs/methodology.md`).

### ISFR 2021 Chapter 4 — forest and corridors
- **Role:** Per-reserve forest cover (VDF/MDF/OF) and documented corridors.
- **Source:** Forest Survey of India (https://fsi.nic.in). **Manual.**
- **Licence:** Government of India.
- **Acquired:** ISFR 2021 report fetched to `data/raw/forest/` (manual). This is
  the 2021 edition — the Phase-1 survivor was ISFR 2017 (wrong edition), so a
  fresh 2021 pull was needed. Per-reserve forest tables are extracted from the
  PDF in a later step (Stage 1/2), not at download.
