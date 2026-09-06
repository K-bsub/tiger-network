# Data acquisition

Data is **not** committed to this repository. This file explains where each
dataset goes and how to get it. The authoritative machine-readable inventory is
`data/data_manifest.csv`; the human-readable citations and licences are in
`docs/data-sources.md`.

## Before you download anything: audit

Most of these datasets came from the two earlier tiger projects. Disk space was
reclaimed, so some may be gone. **Run the audit first** and re-download only
what it reports MISSING:

```r
source("scripts/00b_audit_data.R")   # -> outputs/tables/tbl_00_data_audit.csv
```

## Expected folder layout under `data/raw/`

```
data/raw/
├── ntca/            NTCA census reports (2006, 2010, 2014, 2018, 2022) + Singh & Sen 2015
├── boundaries/      Authoritative tiger reserve boundaries (WII/NTCA) — if obtained
├── wdpa/            KBA Global protected areas (fallback boundaries)
├── gbif/            GBIF tiger occurrences + target-group background CSVs
├── worldcover/      ESA WorldCover 2021 tiles
├── elevation/       SRTM / terrain tiles
├── ghm/             Global Human Modification raster
├── osm/             Geofabrik India roads + settlements
├── forest/          ISFR 2021 Chapter 4 forest + corridor tables
└── administrative/  Natural Earth states, DataMeet districts
```

## Scripted downloads

`scripts/01_download_open_data.R` re-acquires these automatically (guarded to
skip what already exists):

- **GBIF tiger occurrences** — `rgbif::occ_download()`
- **GBIF target-group background** (all vertebrates, for SDM bias correction) —
  async GBIF download. **New to this project**; not in the prior tiger work.
- **ESA WorldCover 2021** — public AWS COGs, auth-free
- **Terrain** — `elevatr` (AWS Terrain Tiles) or SRTM tiles
- **gHM** — Theobald 2024 v3 via `/vsicurl` from Zenodo
- **OSM roads / settlements** — Geofabrik India extract

## Manual downloads (cannot be scripted cleanly)

- **NTCA census reports** — PDFs/Excel from https://ntca.gov.in. Reserve-level
  figures for **all reserves** must be extracted from these. Phase 1 did this
  for 7 reserves only; extending to all reserves is the main data effort.
- **ISFR 2021 Chapter 4** — https://fsi.nic.in. Per-reserve forest cover and the
  13 documented corridors. Phase 1 already extracted these to Excel — check the
  audit before re-doing.
- **Authoritative TR boundaries (WII/NTCA)** — availability is the key Week-1
  unknown. If not publicly downloadable, fall back to KBA polygons (Phase 1
  source) and record the choice as a numbered Decision. Note the Phase 1 caveat:
  KBA area mismatched legal TR area and inflated Corbett's density.

## Licences

Honour every licence. Attribution is required for KBA, WorldCover, gHM, OSM
(ODbL), and DataMeet. Full terms in `docs/data-sources.md`.
