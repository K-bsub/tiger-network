# Data acquisition

Data is **not** committed to this repository. This file tells where each
dataset goes and how to get it. The machine-readable inventory is
`data/data_manifest.csv`. The citations and licences are in
`docs/data-sources.md`.

## Before you download anything: audit

Some datasets can be absent on a new machine. **Run the audit first** and
download again only what it reports MISSING:

```r
source("scripts/00b_audit_data.R")   # -> outputs/tables/tbl_00_data_audit.csv
```

The audit checks that a file is present. It does not check what the file
holds. Its file search is recursive, so keep each `data/raw/<subfolder>/`
free of other files.

## Folder layout under `data/raw/`

```
data/raw/
├── ntca/             NTCA census reports (2006–2022), Singh & Sen 2015, the
│                     census entry files (census_reserve_long*.csv), the
│                     reserve-to-PA crosswalk, and PA_TR_Corridor_Final/
│                     (the NTCA DSS KML; Decision 4)
├── wdpa/             WDPA India download (rejected in Decision 4; a record)
├── gbif/             GBIF tiger records: download zip, key and DOI;
│                     dataset_meta/ (the GBIF registry cache of scripts/08)
├── gbif_background/  GBIF Mammalia background (Decision 5): zip, key, DOI
├── worldcover/       ESA WorldCover 2021; tiles_1km/ (the 1 km tile cache)
├── terrain/          Elevation DEM (elevatr, AWS Terrain Tiles, zoom 7)
├── ghm/              Global Human Modification 2022 (a source stamp only)
├── osm/              OpenStreetMap roads, settlements and zoos;
│                     geofabrik_cache/ (the Geofabrik India files)
├── forest/           ISFR 2017 and 2021 report PDFs
└── administrative/   Natural Earth states; DataMeet 2011 districts
```

Keep `data/raw/worldcover/tiles_1km/` and
`data/raw/terrain/dem_india_aws_z7_4326.tif`: `scripts/06` needs them.

## Scripted downloads

`scripts/01_download_open_data.R` downloads these. Each block does not
download a file that is already on disk.

- **India national boundary** — Natural Earth (the clip frame).
- **GBIF tiger records** — `rgbif::occ_download()` (DOI 10.15468/dl.npxmxx).
- **GBIF target-group background** — Mammalia only, tiger excluded
  (Decision 5); an async GBIF download (DOI 10.15468/dl.2d523e).
- **ESA WorldCover 2021** — public AWS COGs, no login; a windowed read to a
  1 km tile cache.
- **gHM 2022** — Theobald v3 through `/vsicurl` from Zenodo. The read is
  windowed, so no raw file stays on disk (only a source stamp).
- **OpenStreetMap roads, settlements and zoos** — the Geofabrik India extract
  (`osmextract`).
- **Terrain** — `elevatr` (AWS Terrain Tiles). Slope and TRI come from the
  raw DEM.
- **Administrative boundaries** — Natural Earth states; DataMeet Census-2011
  districts.

The two GBIF blocks need `GBIF_USER`, `GBIF_PWD` and `GBIF_EMAIL` in your
user `.Renviron` (never in the repository).

## Manual downloads

- **NTCA census reports** — the PDFs of the five rounds from
  https://ntca.gov.in. The reserve figures were extracted in Week 4 into
  `data/raw/ntca/census_reserve_long.csv`. Reserve tables exist for 2014,
  2018 and 2022 only (Decision 6).
- **NTCA DSS PA/TR/corridor KML** — the boundary source (Decision 4). It
  gives the geometry only; the reserve area is the notified total (Decision
  8). Direct ZIP:
  https://ntca.gov.in/wp-content/uploads/2022/07/PA_TR_Corridor_Final.zip,
  to `data/raw/ntca/PA_TR_Corridor_Final/`.
- **Singh & Sen 2015** — the paper PDF. Assessed; not a numeric source
  (`docs/data-sources.md`).
- **ISFR 2017 and 2021** — the report PDFs from https://fsi.nic.in. ISFR 2021
  Chapter 4 is a cross-check of the reserve area only (Decision 8).
- **WDPA India** — https://www.protectedplanet.net/country/IND. Rejected as a
  boundary source (Decision 4); kept so that the rejection is on record.

## Licences

Obey each licence. Attribution is necessary for the NTCA data, GBIF (cite
the download DOIs), WorldCover, gHM, OpenStreetMap (ODbL) and DataMeet. The
full terms are in `docs/data-sources.md`.
