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
| **Status** | **Week 13 complete — Stage 3 (habitat suitability) has started (2026-10-11 to 2026-10-18).** `scripts/08_prepare_occurrences.R` (functions in `R/00_functions_occ.R` and `R/00_functions_kde.R`) cleans the GBIF tiger records and the Mammalia background by **Decision 21**, fixed before any cleaned count (record type, year 2006–2022, coordinate flags, uncertainty, centroids, zoos, the covariate footprint; one rule for the two sets). Result: 300 tiger records kept; the 1 km set has 45 records in 17 cells, so the outcome of Decision 21 point 8 is **no 1 km suitability model**. Clean background: 23,901 records. **Decision 22**, fixed before any density surface: effort, tiger-record and city/town surfaces with a quartic kernel of 20 km radius; the tiger surface is never published. QA: 171 of 171 checks pass. The published tiger product is the count of clean records per reserve (`tbl_15_occ_by_reserve.csv`; a count of 1 or 2 is given as `<3`). Count tables `tbl_15_*` (no position). Next: **Week 14** — **Decision 23**: a suitability model at a coarser grain, or no model (Stage 3 then gives the effort result). **Prior: Week 12 — Stage 2 (Connectivity) complete:** least-cost paths (Decisions 17–18), the reserve network (Decision 19) and road pinch points (Decision 20; a pinch point is a position in the network, not the pinch point of circuit-theory mapping; 200 pinch points, sensitive to the gHM multiplier). Outputs for publication, with each position as a 10 km grid cell: `tbl_03_reserve_network.csv`, `tbl_03b_pinch_points.csv`, `tbl_03_notes.md`, `fig_03_reserve_network.png`. The paths and crossings are modelled; they are not observed tiger movement. Stage-2 summary against proposal question 2: `docs/methodology.md`, change log, "Week 12 complete". |
| **Focal species** | *Panthera tigris* (Bengal tiger) |
| **Study area** | India — all tiger reserves with reserve-level census data |
| **Primary unit** | Reserve, rolled up to landscape complex and state |
| **Analysis CRS** | EPSG:7755 — WGS 84 / India NSF LCC (national equal-area/conformal frame) |
| **Stack** | R (sf, terra, xml2, igraph, ggplot2, gganimate + gifski; own least-cost-path engine on `terra` + `igraph`, Decision 17; density surfaces by `terra::focal()`, Decision 22; `sfdep` for Gi* and `maxnet` for an SDM only if the Week-14 Decisions use them), Quarto, Leaflet |
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
| 1 | **Growth** | Per-reserve census metrics 2014/2018/2022 (Decision 6), 3-frame animated choropleth | Phase 1, scaled 7 → all |
| 2 | **Connectivity** | Least-cost paths + reserve-network graph + road pinch points | Phase 2 plan, ported ArcGIS → R |
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
