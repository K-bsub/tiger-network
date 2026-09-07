# India's Tiger Network

**Growth, connectivity and habitat suitability across India's tiger reserves**

A reproducible, open-source spatial analysis built entirely in R.
Scales up and ports to R the two earlier wild cat projects:
[tiger-conservation-india](https://github.com/K-bsub/tiger-conservation-india)
(Phase 1 growth, ArcGIS) and its planned Phase 2 connectivity study.
Sibling in method to
[bay-area-wildcats](https://github.com/K-bsub/bay-area-wildcats).

| | |
|---|---|
| **Author** | Kiran Balasubramanian |
| **Status** | **Week 1 complete — environment verified and locked; data audit run.** `00a` toolchain check passes (GDAL 3.12.1 / GEOS 3.14.1 / PROJ 9.7.1; EPSG:7755 resolves). `renv` initialised and snapshotted (124 packages, R 4.5.2 pinned). `00b` audit run: all 13 expected datasets report MISSING — `data/raw/` is deliberately empty (surviving Phase 1 files cover 7 reserves only, so they are not used). Week 2 boundary-source Decision made (Decision 4): NTCA DSS PA/TR/corridor KML is the geometry source; reserve area/density come from the NTCA census, not the polygon. WDPA rejected (India shares no national PAs); KBA assessed but not selected. Remaining Week-2 work: the scripted/manual data downloads. |
| **Focal species** | *Panthera tigris* (Bengal tiger) |
| **Study area** | India — all tiger reserves with reserve-level census data |
| **Primary unit** | Reserve, rolled up to landscape complex and state |
| **Analysis CRS** | EPSG:7755 — WGS 84 / India NSF LCC (national equal-area/conformal frame) |
| **Stack** | R (sf, terra, spatstat, sfdep, leastcostpath, igraph, maxnet), Quarto, Leaflet |
| **Story site** | Planned — Quarto site on GitHub Pages, one page per analysis track |

---

## What this project is (and is not)

This is a **port and scale-up**, not a new subject. Three earlier pieces of
work feed into it:

- **Phase 1 (complete, ArcGIS):** tiger population growth 2006–2022 for
  **7 featured reserves**. Growth, KDE, and Gi* hot spots.
- **Phase 2 (proposed, never run, ArcGIS):** corridor connectivity and threat
  mapping for the **same 7 reserves**.
- **Bay Area wild cats (complete, R):** the connectivity + occupancy R
  toolchain, docs discipline, and sensitive-data policy reused here.

This project runs **three analyses in R for all reserves**, not seven:

| Priority | Track | Method | Prior basis |
|---|---|---|---|
| 1 | **Growth** | Per-reserve census metrics 2006–2022, animated choropleth | Phase 1, scaled 7 → all |
| 2 | **Connectivity** | Least-cost paths + reserve-network graph | Phase 2 plan, ported ArcGIS → R |
| 3 | **Habitat suitability** | SDM (`maxnet`), sampling-bias corrected | New; the honest form of "occupancy" |
| — | **Effort / observer bias** | Woven through all three as a caveat | Signature thread from both prior projects |

### Why "habitat suitability", not "occupancy"

Occupancy models need a **detection history** — repeat visits to defined sites
with detection / non-detection. Opportunistic GBIF tiger records cannot supply
one: Phase 1 kept only ~116 clean baseline points and found strong observer
bias (the Ranthambore cold-spot result). This project therefore models
**habitat suitability (SDM)** from occurrence data, which is defensible with
those data, and does **not** claim occupancy. This is fixed as a Decision
before any modelling — see `docs/methodology.md`.

---

## Repository structure

```
tiger-network/
├── docs/               Project documentation (proposal, plan, methodology, data)
├── R/                  Reusable functions and project configuration
├── scripts/            Numbered analysis pipeline (run in order)
├── data/
│   ├── raw/            Downloaded, unmodified source data      [gitignored]
│   ├── interim/        Intermediate processing artefacts       [gitignored]
│   ├── processed/      Analysis-ready layers (.gpkg / .tif)    [gitignored]
│   └── restricted/     Sensitive data, if any                  [NEVER committed]
├── outputs/            Figures, tables, rasters, fitted models
├── site/               Quarto story site (published to GitHub Pages)
│   └── media/images/   Site imagery (in-project so it deploys)
└── media/              Imagery attribution records
```

Data is **not** stored in this repository. Every dataset is publicly
downloadable — see `data/README.md` for acquisition steps and
`docs/data-sources.md` for citations and licences.

---

## Getting started

```r
# 1. Open tiger-network.Rproj in RStudio

# 2. Install and verify the spatial toolchain (GDAL/GEOS/PROJ) first
source("scripts/00a_setup_environment.R")

# 3. AUDIT what is still on disk from prior projects (space was reclaimed;
#    some downloads may be gone). This reads data/data_manifest.csv as the
#    expected inventory and reports present / missing.
source("scripts/00b_audit_data.R")     # writes outputs/tables/tbl_00_data_audit.csv

# 4. First time only — initialise the reproducible environment
install.packages("renv")
renv::init()          # then renv::snapshot(); commit renv.lock

# 5. Re-acquire only what the audit reports missing (see data/README.md),
#    then run the pipeline in order
source("scripts/01_download_open_data.R")
source("scripts/02_prepare_boundaries.R")
# ... etc.
```

---

## Documentation

| Document | Purpose |
|---|---|
| `docs/proposal.md` | Scope, questions, deliverables |
| `docs/project-plan.md` | Week-by-week plan at a 2–4 h/week pace |
| `docs/methodology.md` | Processing log, numbered Decisions, limitations |
| `docs/data-sources.md` | Expected inventory, citations, access steps, licences |
| `docs/data-dictionary.md` | Every field in every processed layer |
| `docs/naming-conventions.md` | File, layer, object and field naming rules |
| `docs/sensitive-data-policy.md` | Read before handling any precise occurrence data |
| `docs/references.md` | Bibliography |
