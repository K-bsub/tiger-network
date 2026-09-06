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

### Tiger reserve boundaries (authoritative — WII/NTCA)
- **Role:** The all-reserve boundary layer — backbone of every track.
- **Source:** Wildlife Institute of India / NTCA (https://wii.gov.in).
- **Status:** Availability is the key Week-1 unknown. May need a data request.
- **Contingency:** KBA fallback (below).

### KBA Global — Key Biodiversity Areas (fallback boundaries)
- **Role:** Phase 1 boundary source; fallback if WII layer is unavailable.
- **Source:** BirdLife International / KBA Partnership
  (https://www.keybiodiversityareas.org).
- **Licence:** Non-commercial, attribution required.
- **Known issue:** KBA polygon area mismatched legal TR area in Phase 1 and
  inflated Corbett's density. Document if used.

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
