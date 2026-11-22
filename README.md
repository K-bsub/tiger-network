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
| **Status** | **Week 18 complete (2026-11-21) — the open items and the skeleton of the story site.** The four open analysis items are closed; no analysis output changed. **Decision 28** fixed the form of the story site: seven pages; interactive maps, and an interactive `fig_01`, where the rule of the published layers allows (Decision 29, Week 19); the PNG files as the record in the repository; captions as page text with the numbers from code; no R code in the pages; a deploy on each push of `site/**`. The skeleton is live, with the PNG stand-ins, the tables of 60 rows or fewer and draft text (`scripts/11_build_site.R`; QA 45 of 45, `tbl_20_site_qa.csv`). Next: **Week 19** — Decision 29 (the published layers), then the interactive `fig_01` and `fig_02` (Stage 4, Weeks 18–22). **Week 17:** an SDM-based check of the connectivity result (Decision 27): the SDM-based paths **"differ"** from the Stage-2 paths (46 of 94 compared pairs material), the variant is **"sensitive"**, and the pair rule of Decision 17 **"differs"** (51 of 106); `fig_07`, `fig_08` and the `tbl_19_sdmres_*` tables; the paths and the current are modelled, not observed movement. **Week 16:** four Gi* on the 0.2° model cells (Decision 26); the tiger Gi* are never published; `fig_04`–`fig_06` (relative suitability at 0.2°, not a probability of presence; the effort Gi*); QA 113 of 113 — Stage 3 (habitat suitability) complete. **Week 15:** the prediction at 0.2° (five classes of equal count); the reserve check r1 "agrees" (Spearman ρ 0.379 with the 2022 census density, n 51, p 0.006); r2 not published; `tbl_17_reserve_suitability.csv`. **Week 14:** a `maxnet` model at the 0.2° grain (about 20 km) on the obscured iNaturalist tiger records (104 presence cells), with the clean iNaturalist mammal records as the background; no 1 km model (Decision 21); a mean test Boyce index of 0.668 over 5 spatial folds. **Earlier:** Stage 1 (Growth) complete in Week 7; Stage 2 (Connectivity) complete in Week 12 — least-cost paths, the reserve network and road pinch points (Decisions 17–20; 200 pinch points, sensitive to the gHM multiplier), each published position as a 10 km grid cell (`tbl_03_reserve_network.csv`, `tbl_03b_pinch_points.csv`, `tbl_03_notes.md`, `fig_03_reserve_network.png`); the paths and crossings are modelled, not observed tiger movement. Week 13: occurrence cleaning (Decision 21) and effort surfaces (Decision 22; the tiger surface is never published; `tbl_15_occ_by_reserve.csv` gives a tiger count of 1 or 2 as `<3`). The results of the closed stages: `docs/methodology.md`, change log, "Weeks 3–13". |
| **Focal species** | *Panthera tigris* (Bengal tiger) |
| **Study area** | India — all tiger reserves with reserve-level census data |
| **Primary unit** | Reserve, rolled up to landscape complex and state |
| **Analysis CRS** | EPSG:7755 — WGS 84 / India NSF LCC (national equal-area/conformal frame) |
| **Stack** | R (sf, terra, xml2, igraph, ggplot2, gganimate + gifski; own least-cost-path engine on `terra` + `igraph`, Decision 17; density surfaces by `terra::focal()`, Decision 22; `maxnet` for the SDM, Decisions 23–24; own code for Gi*, Decision 26; own circuit-theory code on `Matrix` and least-cost paths on `igraph` for the SDM-based check, Decision 27), Quarto 1.10.18 (pinned in `publish.yml`) for the story site, built by `scripts/11_build_site.R` (`xml2` for its QA); Leaflet planned for the interactive maps (the tool is confirmed in Week 19, task 19.2) |
| **Story site** | Live (skeleton, 2026-11-21): https://K-bsub.github.io/tiger-network/ — seven pages with the static stand-ins and the tables; the interactive maps, the chart and the author's text follow in Weeks 19–21 (Decision 28) |

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
│   ├── figures/        Copies of outputs/figures/ (written by scripts/11)
│   ├── tables/         Table include files _*.md (written by scripts/11)
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

# 6. The story site (Decision 28): source the site script (STEP 18.1),
#    render in the Terminal, not in the R console:  quarto render site
#    then source the script again for the QA of the render (STEP 18.2)
source("scripts/11_build_site.R")
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
