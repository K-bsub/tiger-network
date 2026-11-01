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
| **Status** | **Week 15 complete (2026-11-01) — Stage 3 (habitat suitability) has a prediction and a reserve check.** **Decision 25** fixed the prediction and its published form before any prediction file: cloglog with clamping from the model file of Week 14; five classes of equal count by rank (relative suitability, not a probability of presence); the cells outside the training range flagged (32 of 6,969); no published layer before the Week-18 rule; two static figures in Week 16 (`fig_04` the classes, `fig_05` the value); a reserve table. As run (`scripts/09_model_suitability.R` STEPs 15.1–15.3): the gate is open (mean test Boyce index 0.668); the reserve check r1 "agrees" (Spearman ρ 0.379 of the reserve value and the 2022 census density, n 51, p 0.006); r2 is not published (Decision 25 point 9); `tbl_17_reserve_suitability.csv` (58 reserves); QA 84 of 84. The prediction stays under `data/` (gitignored). Next: **Week 16** — Decision 26 (the Gi* settings), the Gi* of the effort and of the tiger records (the tiger Gi* is never published), and the two suitability figures. **Week 14:** a `maxnet` model at the 0.2° grain of the iNaturalist obscuring grid (about 20 km), on the obscured iNaturalist tiger records (104 presence cells), with the clean iNaturalist mammal records as the background (1,486 cells); no 1 km model (Decision 21: 17 cells); Decisions 23–24; six covariates; `lq` with multiplier 1 by AICc; a mean test Boyce index of 0.668 over 5 folds of 2° spatial blocks; both sensitivity runs robust. **Earlier:** Stage 1 (Growth) complete in Week 7; Stage 2 (Connectivity) complete in Week 12 — least-cost paths, the reserve network and road pinch points (Decisions 17–20; 200 pinch points, sensitive to the gHM multiplier), each published position as a 10 km grid cell (`tbl_03_reserve_network.csv`, `tbl_03b_pinch_points.csv`, `tbl_03_notes.md`, `fig_03_reserve_network.png`); the paths and crossings are modelled, not observed tiger movement. Week 13: occurrence cleaning (Decision 21) and effort surfaces (Decision 22; the tiger surface is never published; `tbl_15_occ_by_reserve.csv` gives a tiger count of 1 or 2 as `<3`). The results of the closed stages: `docs/methodology.md`, change log, "Weeks 3–13". |
| **Focal species** | *Panthera tigris* (Bengal tiger) |
| **Study area** | India — all tiger reserves with reserve-level census data |
| **Primary unit** | Reserve, rolled up to landscape complex and state |
| **Analysis CRS** | EPSG:7755 — WGS 84 / India NSF LCC (national equal-area/conformal frame) |
| **Stack** | R (sf, terra, xml2, igraph, ggplot2, gganimate + gifski; own least-cost-path engine on `terra` + `igraph`, Decision 17; density surfaces by `terra::focal()`, Decision 22; `maxnet` for the SDM, Decisions 23–24; `sfdep` for Gi* if Decision 26 uses it), Quarto, Leaflet |
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
| `docs/methodology-changelog-archive.md` | The change-log entries of Weeks 3–13, moved from `methodology.md` on 2026-10-25 (a record; not updated) |
| `docs/data-sources.md` | Expected inventory, citations, access steps, licences |
| `docs/data-dictionary.md` | Every field in every processed layer |
| `docs/naming-conventions.md` | File, layer, object and field naming rules |
| `docs/sensitive-data-policy.md` | Read before handling any precise occurrence data |
| `docs/references.md` | Bibliography |
