# Handoff — India's Tiger Network

**What this is:** the rolling context document for this project. One chat
per week. At the **start** of a week's chat, attach this file with the other
docs so the assistant has the context. At the **end**, update "Current
state" and the weekly log, tick the week in `project-plan.md`, and commit
(`docs: update handoff after Week N`). This file is the memory between
chats — keep it true.

*(2026-10-25: written again, shorter, at the Week-14 close, at the author's
request. It holds what later weeks need. The history of Weeks 0–13 is in
git, in `docs/methodology.md` and in `docs/methodology-changelog-archive.md`.)*

---

## Fixed context (rarely changes)

- **Repo:** https://github.com/K-bsub/tiger-network  ·  local:
  `C:/Users/kiran/OneDrive/Documents/GitHub/tiger-network`
- **Site:** https://K-bsub.github.io/tiger-network/
- **Environment:** R 4.5.2, RStudio on Windows; `renv` for reproducibility.
  Quarto is **not** on the Windows PATH — render from R with
  `quarto::quarto_render("site", as_job = FALSE)`.
- **Analysis CRS:** EPSG:7755 (WGS 84 / India NSF LCC).
- **Scope (locked):** three tracks in priority order — (1) Growth, (2)
  Connectivity, (3) Habitat suitability (SDM, **not** occupancy) — plus the
  cross-cutting effort/observer-bias thread. Reserve-level, rolled up to
  landscape complex and state.
- **Fixed Decisions** (full text in `docs/methodology.md`; "post-result" =
  recorded after a result was seen, and the Decision says so):

  | D | Rule (short form) |
  |---|---|
  | 1 | Habitat suitability (SDM), not occupancy |
  | 2 | Unit = the reserve, rolled up to landscape complex and state |
  | 3 | CRS EPSG:7755 |
  | 4 | NTCA DSS KML for the geometry only; area and density from the NTCA census |
  | 5 | Target-group background = Mammalia (tiger excluded) |
  | 6 | Census series = within-reserve SECR 2014/2018/2022 only; 2006/2010 are context, not a baseline |
  | 7 | A missing (reserve, round) cell is `NA`; no imputation |
  | 8 | Reserve area = the NTCA-notified core + buffer total (ISFR 2021 Ch. 4 is a cross-check only) |
  | 9 | Real zeros: `change_abs` always valid; a ratio is `NA` with a flag only when the baseline is 0; a real 2022 zero is −100 % |
  | 10 | Covariate stack: a common NA mask (any band `NA` → all bands `NA`) |
  | 11–13 | gHM gap fill by a relevance rule; gHM closed; land cover from the unmasked tile cache; terrain from the raw DEM; 7 tile-corner no-class cells accepted (12 and 13 post-result) |
  | 14 | Resistance: set-B class values × (1 + 4 × gHM), cap 100; Sundarban water 10 (50 elsewhere); variant `noghm` |
  | 15 | Road barrier: motorway to secondary, value 30, maximum rule, `touches = TRUE`; variants `road15`, `road50` |
  | 16 | Water exempt from the gHM multiplier (post-result) |
  | 17 | Least-cost paths: pairs by allocation adjacency + gap ≤ 315 km; through-reserve rule P3; 16 neighbours with the crossed-cells knight rule; own engine, validated; edge to edge; contiguous = a shared footprint cell; Amrabad from the state split; Pilibhit and Dholpur-Karauli out (no polygon) |
  | 18 | Variant comparison: "material" if the 5 km route overlap < 0.5 or the rank change ≥ 0.25; "robust" if ≤ 20 % material and ρ ≥ 0.9 (the road value only if both road variants are) |
  | 19 | Network: each in-network pair is a link (cost = weight, no threshold); contiguous reserves merge (56 reserves → 47 nodes); betweenness normalised in the node's own set; `linchpin` = top 3 in the set with a value > 0; `isolated` = degree 0, `pendant` = degree 1; "robust" if the sets are the same, ρ ≥ 0.9 and linchpin retention ≥ 2/3 |
  | 20 | Road pinch points: crossings of the in-network paths with the D15 barrier cells; crossings ≤ 5 km apart = one site; a pinch point is a site on a bridge edge or a site that ≥ 2 edges use (tiers 1–3); "robust" if the site overlap ≥ 2/3; published as a 10 km grid cell + state + district; a network label, not the pinch point of circuit-theory mapping |
  | 21 | Occurrence cleaning: one rule of nine steps for the tiger and the background; the 1 km set (main) and the 5 km set; the obscured set (iNaturalist, uncertainty ≥ 25 km, with its 0.2° cell; never a 1 km presence); one presence per cell; the limits 25 and 80 cells (point 8); a dataset check by a word list; outcome `no_1km_model` (locked) |
  | 22 | Effort surfaces: effort, tiger records and city/town settlement; the 5 km sets; one unit per 1 km cell; quartic kernel of 20 km radius (σ 7,071 m), QA surfaces at 10 and 30 km; three time windows; the tiger surface is never published or committed; the published tiger product is the count by reserve (1 or 2 → `<3`) |
  | 23 | A `maxnet` model at the 0.2° grain on the obscured set; model cell = complete-case cover ≥ 50 %; the limits 25 and 80 presence cells; background = the clean iNaturalist Mammalia records (two parts), ≥ 10 × the presence cells; the Facebook dataset is a check (0 records); Gi* of the effort and of the tiger records (tiger Gi* never published); no ratio. Outcome `planned_model` (locked) |
  | 24 | Model settings: nine candidates summarised over the 1 km cells of a cell; no water cells in the terrain means, elevation floor 0 m; \|r\| > 0.7 removes the later candidate of a fixed order; AICc over `lq`/`lqh`/`lqph` × regmult 1–4 (fewest coefficients within ΔAICc 2); no bias covariate; presences added to the background; 2° blocks in 5 folds (Boyce, test AUC, OR10, AUCdiff; cloglog); gate: mean test Boyce ≤ 0 → no suitability map; reserve check (Week 15); two sensitivity runs; the model file under `data/processed/` |

## Ways of working (apply every chat)

- ASD-STE100 Simplified Technical English in all writing.
- No flattery; realistic assessment; surface discrepancies, never silently
  default.
- Decisions before code: raise open forks; Kiran makes the call.
- Deliver **full files**, not snippets. Present only changed files per turn.
- Work at the **file level** (Kiran applies edits and re-uploads corrected
  files; those are the source of truth).
- Pre-registration discipline: fix analytical rules as numbered Decisions
  before looking at results.
- Sensitive-data policy: no precise points published; continuous surfaces
  generalised to ≥ 1 km; gate publish exports through the assert functions.
  A modelled path or road crossing is given as a 10 km grid cell in every
  committed table, figure and caption (`assert_publishable_table()`); 1 km
  cells stay in gitignored layers.
- **Rule d1:** no data file with positions goes to a chat. Console text sent
  to a chat holds counts, names and statistics only. The chat tests its code
  on made-up records.
- The run on the project machine is the record. Kiran runs the script and
  sends the console text; the docs for a task are written only after that
  run confirms the result.
- The narrative is the author's. A chat does not write story text; a title
  or a caption from a chat is a draft and is marked as one.
- Before each deliverable, check the new text against the AI-word list.
- Take each figure from code or data, never from prose.
- Doc commits are separate from analysis commits (`analysis:` / `docs:`).

---

## Current state  ·  **Week 14 complete** · 2026-10-25

### Where the project is

- **Stage 1 (Growth):** complete in Week 7. **Stage 2 (Connectivity):**
  complete in Week 12. **Stage 3 (Habitat suitability):** Week 13 complete
  and committed (2026-10-18); **Week 14 complete (2026-10-25)**. Nothing of
  Week 14 was committed during the week; the author commits it (task 14.8)
  before the Week-15 chat.
- **Week 14 in short** (full record: Decisions 23 and 24 and the change log
  in `methodology.md`):
  - **Decision 23** (task 14.1): the model at the 0.2° grain. **The count**
    (task 14.4): 6,969 model cells, 104 presence cells, 1,486 background
    cells → `planned_model`, locked in `SDM_GRAIN_OUTCOME`.
  - **Decision 24** (task 14.3): the model settings, before any covariate
    summary.
  - **The fit** (task 14.5): 6 of 9 covariates kept (`ghm_mean`,
    `lc_forest`, `elev_mean`, `lc_open`, `droad_km_mean`, `lc_built`; slope
    and TRI out by their \|r\| with elevation, crop by its \|r\| with gHM);
    AICc → `lq`, regmult 1 (10 coefficients; no other model within 2);
    cross-validation over 5 folds of 2° blocks — mean test Boyce **0.668**
    (SD 0.177), test AUC 0.749, OR10 0.165, AUCdiff 0.060; training AUC of
    the main model 0.806; sensitivity runs `bias_settlement` (ρ 0.988) and
    `window_2018_2022` (71 presence cells, ρ 0.991), both robust.
  - **The QA** (task 14.6): 133 of 133 checks, with a second path for the
    main numbers; 0 records of the Facebook dataset.
  - **Process choices:** task 14.2 — s1, f1, w2, g1, t1, l1, r1 and the
    order o2; task 14.4 — k1, h1; task 14.5 — q1, t1, y1, h1, w1 and eight
    implementation points; task 14.6 — c1, m1, h1, p1, s1. All as the chat
    recommended.
  - **Docs close** (task 14.7): Limitations, §5.4–5.5, the Week-15 plan;
    `methodology.md` made shorter (the change log of Weeks 3–13 moved to
    `docs/methodology-changelog-archive.md`); this file written again.
- **`scripts/09_model_suitability.R`:** STEPs 14.1–14.3. `RUN_GRID <- FALSE`,
  `RUN_COVARIATES <- FALSE`. The 19 fits run in each run (process choice
  w1). In the run of task 14.6, STEPs 14.1, 14.2 and 14.3 took 0.0, 0.1
  and 0.2 minutes.
- **`renv.lock`:** `maxnet` 0.1.4 and `glmnet` 5.0 (with `foreach`,
  `iterators`, `RcppEigen`, `shape`, `survival`) since task 14.5. `sfdep`
  is in the `scripts/00a` list only (not in the lock until a script loads
  it).

### Week-15 entry point

- **Next: task 15.1 — Decision 25** (the prediction and its published form),
  before any prediction file is written or seen. The forks are in
  `project-plan.md` → "Week 15 — task breakdown" (a draft: the model file
  and the output type, the cells, the published form and classes, the
  sensitive-data check of the surface, the caption content, the figure
  number, what was seen).
- **Then:** task 15.2 (process choices), 15.3 (the prediction and the gate),
  15.4 (the reserve check), 15.5 (QA), 15.6 (docs; the Week-16 breakdown),
  15.7 (commit). Split point after task 15.2.
- **The gate is known:** the mean test Boyce index is 0.668, above 0, so the
  gate of Decision 24 point 8 allows a map; Week 15 states it.
- **Read before Week 15:** Decision 23 point 9 (publication), Decision 24
  points 7–9 and "Result of the run", the Week-15 pitfalls of the plan,
  `docs/sensitive-data-policy.md`, the Stage-3 items of "Limitations".
- **Files for the Week-15 chat:** the docs; `R/00_config.R`,
  `R/00_functions_sdm.R`, `R/00_functions_io.R`, `R/00_functions_occ.R`,
  `R/00_functions_sensitive.R`; `scripts/09_model_suitability.R`; the
  `tbl_16_*` tables if a value is needed (committed; statistics only). No
  data file (rule d1).

### Results by stage (a record for the write-up of Weeks 17–20)

- **Stage 1 — Growth (Weeks 3–7).** Within-reserve totals 1,586 (2014),
  1,958 (2018), 2,257 (2022); change +651; 53 reserves with census data.
  By landscape: Central India +282 (+59.7 %), Shivalik-Gangetic +239
  (+58.9 %), Western Ghats +108 (+19.8 %), North-East Hills +22 (+13.2 %),
  Sundarbans `NA`. Outputs: `tbl_01_reserve_growth.csv`,
  `tbl_02_regional_rollup.csv`, `fig_01_growth_ranking.png`,
  `fig_02_growth_animation.gif` (3 frames).
- **Stage 2 — Connectivity (Weeks 8–12).** 106 pairs: 97 paths and 9
  contiguous pairs; 85 in the network; path cost median 577.3
  resistance-km. 47 nodes from 56 reserves, 73 edges, 3 sets (33, 8 and 6
  nodes), 13 bridges. 8 linchpins: Madhav, Guru Ghasidas-Tamor Pingla,
  Sanjay Dubri; the Bandipur block, Bhadra, Parambikulam + Anamalai; Pakke
  + Nameri, Orang (Madhav is `cross_group_dependent`; Sanjay Dubri is not a
  linchpin on all four surfaces). No isolated node; 6 pendant nodes
  (Valmiki, Sundarbans, Dampa, Sahyadri, Kalakad-Mundanthurai, BRT). 556
  road crossings on 74 of 76 paths; 365 sites; 200 pinch points (tier 1:
  3, tier 2: 98, tier 3: 99). Variant labels: paths robust / robust;
  network robust / robust; pinch points **sensitive** (gHM multiplier, site
  overlap 0.520) / robust (road value). The paths cross 31 of the 59 NTCA
  corridors (share of path length inside, median 0.064). Outputs for
  publication (positions at a 10 km cell): `tbl_03_reserve_network.csv`,
  `tbl_03b_pinch_points.csv`, `tbl_03_notes.md`,
  `fig_03_reserve_network.png`. Full summary against proposal question 2:
  `methodology.md`, change log, "Weeks 3–13".
- **Stage 3 — so far (Weeks 13–14).** GBIF tiger records 4,606 → 300
  clean (1 km set: 45 records in 17 cells → no 1 km model; 5 km set: 300
  records in 44 cells; one Facebook dataset gives 273 of the 300);
  obscured set 884 records in 104 cells of 0.2°; clean background 23,901
  records. The model of Week 14 (above). The published tiger product so
  far: `tbl_15_occ_by_reserve.csv` (a count of 1 or 2 is `<3`).

### Files that later weeks read

Field details: `docs/data-dictionary.md`. All under `data/` are gitignored.

| File | What | Rule |
|---|---|---|
| `data/processed/boundary_reserves_all_7755.gpkg` | 58 reserves (56 with a polygon; 6 polygon pairs overlap) | Key `unit_id` |
| `data/processed/stats_reserve_census_7755.gpkg` | Census series, notified area, `density_2022` | Density per total notified area (D8) |
| `data/processed/cov_stack_1km_7755.tif` | 6 bands, 3,067,467 complete-case cells | Common NA mask (D10) |
| `data/processed/resist_tiger_<surface>_7755.tif`, `lcp_reserve_network_7755.gpkg` | Stage-2 surfaces and paths (4 variants) | Path layer on the site: pending [Week 18] |
| `data/processed/lcp_road_crossings_7755.gpkg` | Crossings at 1 km | Never published |
| `data/processed/occ_tiger_gbif_clean_7755.gpkg` | 300 clean tiger records | Tier T2; never published |
| `data/processed/occ_tiger_gbif_obscured_7755.gpkg` | 884 obscured records | Tier T1 |
| `data/processed/effort_background_tgs_clean_7755.gpkg`, `effort_background_inat_cell02_7755.gpkg` | Clean background; the model background | — |
| `data/processed/kde_*_1km_7755.tif` | Effort, tiger, settlement surfaces (20 km) | `kde_tiger_*` never published or committed |
| `data/processed/sdm_grid_cell02_7755.gpkg`, `sdm_cellid_1km_7755.tif` | 0.2° cells (7,450; 6,969 model cells); cell id of each 1 km cell | No presence flag |
| `data/processed/sdm_covariates_cell02.csv` | Covariates of the 6,969 model cells | Holds cell ids: no table row from it |
| `data/processed/tiger_sdm_maxnet_cell02_20261025.rds` | The main model and its settings | Under `data/` (D24 m1) |
| `outputs/tables/tbl_00`–`tbl_16_*`, `outputs/figures/fig_01`–`fig_03` | Committed tables and figures | Counts and statistics; positions at 10 km only |

### Open items (carried)

- `scripts/03` line 101: wrap the literal text in `I()` for `readr` ≥ 2.2
  (no output change; not done).
- The NTCA overlap has no buffer (Decision 17). Transboundary links are
  absent (India-only surface).
- `fig_03`: the title, subtitle and caption, and the wording of
  `tbl_03_notes.md`, are chat drafts — the author's edit is open. The thin
  link lines are faint at width 0.3 (kept by author choice).
- `sensitive-data-policy.md`: the sentence "Bobcat-style finer
  publication…" was not reviewed against the rule for modelled paths and
  crossings.
- **Reserve polygons overlap:** 6 pairs, 20.7 km² (Bandipur–Sathyamangalam
  10.9 km², Parambikulam–Anamalai 5.5, Periyar–Srivilliputhur-Megamalai
  3.0, Manas–Buxa 0.85, Pakke–Nameri 0.34, Bandipur–Mudumalai 0.09).
  `scripts/02` is not changed; a fix would need the runs of Weeks 10–12
  again. Decide when the reserve layer is next touched.
- The 18 records of the tiger 1 km set from 2018–2022 are in one cell
  outside all reserve polygons; the cause is not known (not a model input).
- The AI-word list is an image-only PDF; the checks use the list of the
  source web page (humanizeai.io) as a search pattern. A text file in the
  repo would make the check exact.

### References still to verify (before they are cited on the site)

Entries marked in `references.md`. Sarkar et al. 2016, Jhala et al. 2021,
Habib et al. 2020, Hussain et al. 2022, WHCWG 2010, McRae & Kavanagh 2011,
Jan et al. 1999, Savary et al. 2022, Sharma et al. 2009 and 2011,
Johnsingh et al. 2004, the transboundary TAL report, Sarkar et al. 2021,
the 2026 bioRxiv preprint. Week 11: Brandes 2001, Brooks 2003, Carroll et
al. 2012, Freeman 1977 (volume and pages); Jhala et al. 2015 (report
number); Johnsingh et al. 2009 (authors, proceedings); Singh et al. 2015
(authors, article number); the two Qureshi et al. 2014 chapters (read in
fragments); which Pench unit Dutta et al. 2016 mean. Week 12: Carter et
al. 2020, Cushman et al. 2013, McRae 2012, Pariwakam et al. 2018, WHCWG
2013 (abstracts or extracts); Saxena & Habib 2022 (through a news report);
the 21 news and grey sources of "Week-12 pinch points" (two summary only,
one exam-preparation page, some with no day or title). Week 13: Phillips et
al. 2009 and van Proosdij et al. 2016 (abstracts); three iNaturalist forum
posts (not the official help page; the geoprivacy state of the tiger taxon
not checked); the GBIF technical pages (one through a summary); Barber et
al. 2022 (repository page and abstract). Week 14: Botella et al. 2020 and
Guisan et al. 2007 (repository records and abstracts; no DOI recorded); the
iNaturalist help page (through a summary); the iNaturalist source file
(current branch only); one more forum thread (users, not staff); the
`maxnet` source files (master branch, not the tag of 0.1.4);
Radosavljevic & Anderson 2014 and Warren & Seifert 2011 (not read; as the
ENMeval help pages give them); Dormann et al. 2013, Roberts et al. 2017 (no
DOI on the record) and Hirzel et al. 2006 (through a summary); Valavi et
al. 2019 (package manual); the `ecospat.boyce` help page (version 3.4,
through a summary).

### Open pending Decisions (decide in the week noted)

Full text in `methodology.md` → "Decisions pending".
- **[Week 15] Prediction and publication of the suitability surface** →
  **Decision 25**, task 15.1: the model file and the output type with
  clamping, the cells, the classes and the published form, the
  sensitive-data check, the caption, the figure. The gate and the reserve
  check are fixed already (Decision 24 points 8–9).
- **[Week 15–16] Gi\* settings** (raised with Decision 23 point 8; Week 16 in
  the plan draft, Decision 26): the input set of the tiger Gi* (5 km set,
  obscured set or both), the grid, the value of a cell, the neighbours and
  the band (a new value; Phase 1: 50 km and 25 km), the correction for many
  tests, and what the docs can state from the tiger Gi* (never published).
- **[Week 18] Published path layer** (raised with Decision 20): no layer,
  simplified lines, or a zoom limit, before a path layer goes on the site.
- **[After Stage 3] SDM-based resistance + circuit-theory check.** The
  surface will be at 0.2° (about 20 km); decide then whether the item still
  applies.

_Resolved (in `methodology.md`): Decisions 7 to 24 closed the earlier
items (missing years, area source, zeros, the NA policy, the gHM fill,
resistance values, barrier roads, water and gHM, the path set-up, the
comparison metric, the link rule, the pinch-point rule, the cleaning rule,
the settlement layer, the target-group scope, the model Decisions, the
uses of the effort surfaces, the terrain variables)._

### Data on disk (raw; via `scripts/01`)

All on the 1 km EPSG:7755 grid where raster.
- **GBIF tiger occurrences** — 4,606 points (DOI 10.15468/dl.npxmxx).
  **GBIF Mammalia background** — 39,057 points, 2006–2022 (DOI
  10.15468/dl.2d523e). `scripts/08` reads the two zip files again.
- **WorldCover 2021** (1 km modal class, 11 classes; built from the 88
  unmasked tiles), **gHM 2022** (mean 0.377), **terrain** (elevation, slope,
  TRI from the raw elevatr AWS z7 DEM).
- **OSM** (`data/raw/osm/`): roads 885,669 (major); settlements 199,800
  (mostly villages; Decision 22 uses the 4,597 city and town points); zoos
  154 (63 points, 91 areas).
- **Admin boundaries:** Natural Earth states (36) in `data/processed/`;
  DataMeet Census-2011 districts (641) in `data/raw/administrative/`.
- **NTCA:** `data/raw/ntca/PA_TR_Corridor_Final/` (KML); the census reports
  2006–2022 (parsed in Week 4), ISFR 2021 Ch. 4, Singh & Sen 2015.

---

## Known gotchas (do not relearn)

*(Kept at the Week-14 close: the items that apply to later work. The items
of closed one-time work are in git history.)*

**Environment and tools**
- **PROJ / PostGIS `proj.db` clash (this machine).** PostgreSQL 16 / PostGIS
  3.6 puts an old `proj.db` on PATH, so every reprojection to EPSG:7755
  fails (`empty srs`). Fix: `PROJ_LIB` is pinned to terra's bundled
  `proj.db` in the project `.Rprofile`, set before terra loads. Run each
  script in a **fresh session**; check `crs(rast(crs="EPSG:7755"))` prints
  "India NSF LCC".
- **renv records only the packages that a script loads** (`library()`,
  `require()`, `pkg::`). A package in the `scripts/00a` list only (now
  `sfdep`) is not in `renv.lock`; snapshot after the first script that
  calls it. A package called through `requireNamespace()` (for example
  `gifski`) may need `renv::snapshot(packages = ...)`.
- **`rlang` lock:** if an update says "cannot remove prior installation" or
  "namespace already loaded", restart R and run `install.packages()` first.
- **Quarto / GitHub Pages:** bootstrap `gh-pages` once from the Terminal tab
  (`quarto publish gh-pages site`); do not use
  `quarto::quarto_publish_site(server = "gh-pages")` (it targets Posit
  Connect). The `gh-pages` branch shows the source as "deleted": correct.
- **On Windows, R reports only its own heap.** Read Task Manager for the
  process peak.
- **`terra`:** `ext()` returns an S4 `SpatExtent` (use `as.vector()` before
  subsetting); `is.na()`, `mean`, `sum` on a SpatRaster are base generics —
  do not prefix them with `terra::`; `terra::nearest()` is a brute-force
  search (use `sf::st_nearest_feature()` in chunks); `terra::focal()` gives
  `NA` near the grid edge unless `fillvalue = 0`.
- **`tapply()` gives a one-dimension array**, not a vector; `identical()`
  then fails. Use `as.vector()`.
- **`dplyr::summarise` reads its own new columns.** Do not reuse an input
  column name as an output name that a later expression still reads.
- **`gganimate`:** use `transition_manual()` for a fixed-geometry map
  (`transition_states()` tweens the polygons). `gifski` is a separate
  install.
- **`ggplot2`:** one legend for marks of two kinds needs one class factor;
  `ggrepel` is not in `renv`. `facet_wrap()` has no `space = "free_y"`
  (bar thickness varies between facets in `fig_01`; a cosmetic item for the
  story-map pass).
- **A wide table wraps at the console width.** Print it at
  `options(width = 120)`; the console text is the record.
- **Non-ASCII and invisible characters.** Write a character that a result
  depends on as an escape (`\u00a9`, `\ufeff`).

**Data and keys**
- **`data_inventory_v2.xlsx` is not a file of this project.** It is the
  Phase-1 inventory (February 2026). A chat does not read it or use it. The
  inventory of this project is `data/data_manifest.csv`.
- **`unit_name` is not a unique key** (two Pench: `unit_id` 23 MP and 33 MH;
  two Rajiv Gandhi). Join on `unit_id`, or name + state.
- **`density_2022` is per total notified area**, not core only (Decision
  8); the polygon is the core protected-area outline (Decision 4). Never
  derive area or density from `poly_km2`. `area_km2` is the notified total
  in the stats layer only.
- **`BASELINE_YEAR` is the GBIF download bound (2006), not the census
  baseline** (`CENSUS_BASELINE_YEAR`, 2014). Keep them separate.
- **`census_reserve_long.csv` has a quoted `#` comment block** before the
  header; `read_csv(comment = "#")` does not strip it.
- **Census values are "within the reserve"**, not "utilising"; a `-` or `0`
  in a census table is a real zero (Decision 9).
- **Reserve polygons can overlap** (6 pairs). A count or a value by reserve
  says what it does with a point or a cell in two polygons (task 13.8: it
  counts in each, o1; Decision 24 point 9 the same).
- **State and district come from two layers** and can disagree at a border
  (Natural Earth states; DataMeet 2011 districts). The district layer is in
  `data/raw/administrative/`, the state layer in `data/processed/`.
- **"5km" has two meanings in the `tbl_15` tables:** as a value of
  `uncert_set` it is above 1 km and ≤ 5 km only; "the 5 km set" is all
  kept records.
- **Keep the raw inputs:** `data/raw/worldcover/tiles_1km/` and
  `data/raw/terrain/dem_india_aws_z7_4326.tif` are required by `scripts/06`.
- **The GBIF registry cache needs the network on the first run**
  (`data/raw/gbif/dataset_meta/`). A new dataset with a word of the check
  list stops `scripts/08` until it is cleared (`OCC_DATASET_CLEARED`); a hit
  is a reason to read the description, not a finding.
- **The audit (`00b`) checks file presence, not coverage**, and its glob is
  recursive: keep `data/raw/<subfolder>/` clean.

**Publish and sensitive data**
- **No position finer than 10 km for a modelled path or crossing** in a
  committed table or figure (`assert_publishable_table()`).
- **A published total can give a suppressed count.** Do not publish a total
  next to a table with `<3` values.
- **"Pinch point" is a network label** (Decision 20): not each crossing, not
  a measure of traffic, not circuit theory. A road inside a node has no
  crossing; a documented crossing place can be a crossing that is not a
  pinch point. The road layer has no road name.
- **A geometry rule can make a link that the literature does not know**
  (for example Orang–Dampa, 305 km). Check a named link against
  `references.md` before it goes into the story. The metrics table is per
  reserve, the values per node: count by `node_id`.
- **The Boyce index of this project is not the `ecospat.boyce()`
  default.** Implementation point 3 of Decision 24 keeps repeated P/E
  values; `ecospat.boyce()` removes successive repeats by default. A text
  that gives a Boyce value says so.

**Code patterns**
- **QA the file on disk, not only the object in memory.** Use
  `write_processed_rast()` (explicit `datatype`, read-back); its default
  read-back tolerance cannot see a file of zeros when the mean is about
  1e-5 — pass a smaller `rel_tol` for such a layer.
- **`write_processed_vec()` deletes the whole GeoPackage.** For a file with
  one layer per surface, write one layer (`lcp_write_layer()`).
- **Mask on the final template**, never on an intermediate grid (a one-cell
  edge shift otherwise).
- **An imputed value must not feed a rule meant for observed values**
  (Decision 16).
- **A point exactly on a grid line or cell edge needs a rule** (east/south
  for the 10 km grid; north/east for the 0.2° cell). A polygon ring built
  from a corner plus 0.2° steps does not close in floating point; close it
  with its first point.
- **A QA check for a table that the same run writes later enters the QA
  table one run late.** Say so in the run instructions.
- **Each run of `scripts/09` fits the models again** (w1). It writes the
  STEP-14.2 tables, `tbl_16_sdm_qa.csv` and a model file with the date of
  the run; a run on another date gives one more
  `tiger_sdm_maxnet_cell02_<date>.rds`. The run of task 14.6 gave the same
  values as the run of task 14.5. Add a switch (w2) if the fits become slow
  or the model file must not change.
- **The radius of a quartic kernel is not its sigma** (support radius =
  √8 × `sigma`; Decision 22).

**Process (chat)**
- **A list of expected `git status` lines starts from the last commit.** Ask
  which tasks are committed (or for `git log -1`) before writing one.
- **The chat's tests use other versions** (R 4.3.3, `glmnet` 4.1.8 in the
  chat; R 4.5.2, `glmnet` 5.0 on the project machine). The project-machine
  run is the record. A chat cannot rebuild every input; it tests on
  made-up records.
- **A forecast in a Decision can be wrong** (Decision 20: "robust" was
  named as likely; the result was "sensitive"; Decision 24 point 1 expected
  slope or TRI to stay). Record the result; do not change the Decision text.
- **An inference is not a check.** When a fix targets one band or table,
  check the others for the same cause.
- **One letter code can name two process choices.** Write the task with the
  code ("s1 of task 13.2").
- **Table numbers are not unique keys.** Refer to a table by its full file
  name.
- **A web page read through a fetch can give a summary only.** Mark such an
  entry in `references.md`.

---

## Weekly log (newest first)

*(Weeks 0–13: git history, and the change log of `methodology.md` with its
archive.)*

### Week 14 — Stage 3: Decisions 23–24, the model and the QA · 2026-10-18 to 2026-10-25
- Entry state: Week 13 complete and committed; outcome `no_1km_model`.
- Did: task 14.1 Decision 23; task 14.2 the process choices, the
  iNaturalist background (`scripts/08` STEP 13.3 again) and the header and
  35 guards of `scripts/09`; task 14.4 the count (STEP 14.1) —
  `planned_model`; task 14.3 Decision 24; task 14.5 the fit (STEP 14.2);
  task 14.6 the QA (STEP 14.3); task 14.7 the docs close, the Week-15 plan
  and the cleanup of `methodology.md` and this file.
- Decisions made: **Decision 23** (a2, b3, v1, c1, r2, s1, m1, e1, f2;
  f2 is not the chat's recommendation) and **Decision 24** (c1, z1, k1, f3,
  b1 with b2 as a sensitivity run, a1, v1, g2, r3, s3, m1). The process
  choices are listed under "Current state".
- Outputs: `scripts/09_model_suitability.R`, `R/00_functions_sdm.R` (new);
  two `SDM_*` blocks and two QA tolerances in `R/00_config.R`; seven
  `tbl_16_*` tables; the grid, the cell-id raster, the covariate table and
  the model file under `data/processed/`; `renv.lock` (`maxnet`, `glmnet`).
- Gotchas found: see "Known gotchas" (the polygon ring, the QA one run
  late, renv and `scripts/00a`, the `git status` list, the Boyce tie rule,
  the fits in each run, the package versions).
- Errors of the chat: the Decision-24 fork text said "eight covariates"
  (nine candidates); a quote of Roberts et al. 2017 was a summary (fixed
  before delivery); the run instructions of task 14.2 said that no table
  would change (`tbl_15_occ_qa.csv` changed); the expected `git status`
  list of task 14.5 assumed a commit; process choice t1 said that the
  correlation table shows the kept candidates; the estimates of task 14.6
  (checks and time) and its function count. Each is recorded in the change
  log.
- Carried forward / next session: the author commits Week 14 (task 14.8);
  then Week 15, task 15.1 — Decision 25.

## Template — copy this block for each new week

### Week N — <topic> · <date>
- Entry state:
- Did:
- Decisions made:
- Outputs:
- Gotchas found:
- Errors of the chat:
- Carried forward / next session:
