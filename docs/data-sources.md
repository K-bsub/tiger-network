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
  legal core-plus-buffer tiger-reserve extent** (median area ~55% below the
  legal total). Covers 55 of 58 reserves by name; 3 not found (Amrabad,
  Pilibhit, Dholpur-Karauli) and 2 false matches (Bor, Kamlang) are fixed by
  hand in Week 3. Corridor centrelines are largely unnamed in the source; names
  assigned in the connectivity track. Infrastructure-clearance dataset, not
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

### India administrative boundaries
- **Role:** State/district context and roll-up.
- **Source:** Natural Earth (public domain); DataMeet India districts (CC BY 4.0).

---

## Occurrences and effort

### GBIF — Panthera tigris in India
- **Role:** Occurrence data for SDM and the effort thread.
- **Source:** https://www.gbif.org (`rgbif`). Phase 1 pulled ~4,500 records.
- **Licence:** CC BY / CC0 per record.
- **Note:** Re-pull recommended for the national extent.

### GBIF — target-group background (all vertebrates)
- **Role:** Sampling-effort layer; bias correction for the SDM. **New to this
  project.**
- **Source:** https://www.gbif.org async download (no 10k cap).
- **Licence:** CC BY / CC0 per record.

---

## Covariates

### ESA WorldCover 2021 v200
- **Role:** Land cover for resistance surface and SDM.
- **Source:** https://esa-worldcover.org (public AWS COGs).
- **Resolution:** 10 m. **Licence:** CC BY 4.0.
- **Known issue (from Bay Area):** under-maps chaparral/shrub; check relevance
  for Indian dry-forest classes at model fit.

### SRTM / terrain
- **Role:** Elevation, slope, TRI for SDM.
- **Source:** USGS Earth Explorer / NASA (30 m); or `elevatr` AWS Terrain Tiles.
- **Licence:** Public domain.
- **Note:** Phase 1 had 19 tiles for 11–31°N, 73–94°E. National extent may need
  more.

### Global Human Modification (gHM)
- **Role:** Human-pressure covariate for connectivity and SDM.
- **Source:** Theobald et al. 2024 v3, Zenodo (`/vsicurl`), preferred over
  Kennedy 2019 (per Bay Area Decision 15).
- **Licence:** CC BY 4.0.

### OpenStreetMap — roads and settlements (India)
- **Role:** Road barriers for connectivity; human-footprint context.
- **Source:** Geofabrik India extract (https://download.geofabrik.de/asia/india.html).
- **Licence:** ODbL — attribution required.

### ISFR 2021 Chapter 4 — forest and corridors
- **Role:** Per-reserve forest cover (VDF/MDF/OF) and 13 documented corridors.
- **Source:** Forest Survey of India (https://fsi.nic.in). **Manual.**
- **Licence:** Government of India.
- **Note:** Already extracted to Excel in Phase 1 — check the audit first.
