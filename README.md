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
| **Status** | **Week 8 complete — Stage 2 (Connectivity) input assembly done.** `scripts/06_build_covariate_stack.R` assembled the aligned 1 km EPSG:7755 covariate stack `data/processed/cov_stack_1km_7755.tif` (6 bands: `landcover`, `ghm`, `elev`, `slope`, `tri`, `dist_road_m`) from the Week-2 layers, plus the interim distance-to-road covariate `cov_distroad_1km_7755.tif` and QA table `outputs/tables/tbl_10_covariate_stack_qa.csv`. One 1 km template built from the national boundary (5 km collar, extent snapped to whole `GRID_CELL_M`; 3093 × 2864 = 8,858,352 cells); every covariate resampled onto it — WorldCover **nearest** (categorical), gHM/terrain **bilinear** (continuous); distance-to-road by rasterise-then-`terra::distance` over the 885,669 major-road lines (all classes incl. tertiary — an inline covariate choice, not the Week-9 barrier Decision). Cross-band **common NA mask** (**Decision 10**): a cell is kept only where all six bands are non-`NA` → **3,010,738 complete-case cells (98.15% of India)**; gHM is the binding NA layer (windowed-COG edge), so the mask drops ~56,840 cells (~1.8%) — a gHM coastal/edge gap-fill is **deferred to Week 9** pending a per-reserve relevance check. QA spot-check confirms alignment did not corrupt values (gHM 0.377/0.377, landcover modal 40 n_class 11, elev 577/571, slope 2.54/2.50, tri 23.4/23.1, dist_road 2019/2045). Assembly and alignment only — resistance values and barrier road classes are Week 9. Prior: Week 7 — Stage 1 (Growth) done (`tbl_02`, `fig_01`, `fig_02`; 13/13 checks). Next: Week 9 — Stage 2 resistance surface: the land-cover resistance-value Decision and the barrier road-class Decision, plus the Decision-10 gHM gap-fill relevance check. |
| **Focal species** | *Panthera tigris* (Bengal tiger) |
| **Study area** | India — all tiger reserves with reserve-level census data |
| **Primary unit** | Reserve, rolled up to landscape complex and state |
| **Analysis CRS** | EPSG:7755 — WGS 84 / India NSF LCC (national equal-area/conformal frame) |
| **Stack** | R (sf, terra, xml2, spatstat, sfdep, leastcostpath, igraph, maxnet, ggplot2, gganimate + gifski), Quarto, Leaflet |
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
