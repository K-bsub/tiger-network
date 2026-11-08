# Project Plan

**Project:** India's Tiger Network
**Author:** Kiran Balasubramanian
**Start:** September 2026
**Pace:** **2–4 hours per week**, alongside full-time work. Weeks are
self-contained and may slip. The plan below is sized to that cadence.

---

## How to read this plan

- Each **week is one small unit** of 2–4 hours. It has a clear entry state, a
  clear exit state, and a single deliverable where possible.
- Weeks are grouped into **stages**, one per analysis track, in priority order.
- The pace is honest: at 2–4 h/week this is a **multi-month project**, roughly
  **5–6 months** of calendar time if weeks rarely slip. That is expected and
  fine.
- A week that needs a design decision **ends by asking the decision**, not by
  guessing. Code follows the decision the next week.

---

## Week 0 — Scaffolding (done)

The repository, R environment, and documentation set already exist (this
scaffold). Week 0 is not new build work — it is **verify and commit** what was
scaffolded, so Week 1 starts from a clean, version-controlled base.

| # | Task | Done when | Est. |
|---|---|---|---|
| 0.1 | Unzip the scaffold into a local folder named `tiger-network` | Folder opens with the tree in the README | 5 min |
| 0.2 | Open `tiger-network.Rproj` in RStudio | Project loads; working directory is the repo root | 5 min |
| 0.3 | Read the three core docs: `proposal.md`, `project-plan.md`, `methodology.md` | You agree with Decisions 1–3 and the scope, or note changes | 20–30 min |
| 0.4 | Confirm the three pending forks are acceptable as *pending* (boundary source, missing-year handling, resistance values) | You are happy to decide these in Weeks 2/4/9, not now | 5 min |
| 0.5 | `git init`; create the GitHub repo `tiger-network` under `K-bsub`; set `main` as default | Empty remote exists and is linked | 10 min |
| 0.6 | First commit of the scaffold (docs + code + config, **no data**) | `git status` shows nothing under `data/raw`, `data/processed`, `data/restricted` staged | 10 min |
| 0.7 | Confirm `.gitignore` excludes data and heavy outputs | `git status --short` lists no `.tif`/`.gpkg`/`.rds` from `data/` or `outputs/rasters` | 5 min |
| 0.8 | Push `main` to GitHub | Remote shows the scaffold; `.gitkeep` files hold the empty folders | 5 min |

**Not in Week 0:** running `renv::init()` (that is Week 1, after `00a` verifies
the toolchain), any data download, and any analysis. Week 0 ends with a
committed, pushed scaffold and no data in version control.

**Exit state:** `tiger-network` repo is live on GitHub with the full scaffold on
`main`, data-free, ready for Week 1.

---

## Stage 0 — Setup and audit (Weeks 1–2)

| Week | Focus | Exit state (deliverable) | Est. |
|---|---|---|---|
| **1** | Environment + data audit | `00a` runs clean; `00b` audit table written; you know exactly what data is present vs missing | 2–3 h |
| **2** | Re-acquire gaps + boundary decision | Missing scripted data re-downloaded; **Decision:** WII TR boundaries vs KBA fallback | 3–4 h |

**Week 1 note:** the audit is the whole point of this stage. It tells us how much
of "all reserves" is already on disk and how much must be rebuilt.

**Week 2 note:** the boundary decision is the biggest feasibility fork. If the
authoritative WII/NTCA all-reserve boundary layer is not publicly downloadable,
we fall back to KBA (with the Corbett-style area caveat) and record why.

### Week 1 — task breakdown *(complete)*

Entry state: scaffold on `main`, `gh-pages` live (placeholder site). No data
re-acquired, no analysis run, `renv` not yet initialised.

| # | Task | Done when | Est. |
|---|---|---|---|
| 1.1 | Run `scripts/00a_setup_environment.R` | Packages install; GDAL/GEOS/PROJ versions print; CRS 7755 resolves; no error | 20–30 min |
| 1.2 | Fix any toolchain problem `00a` surfaces before going further | `00a` runs clean end to end | 0–60 min (varies) |
| 1.3 | Point `data/raw/` subfolders at whatever prior-project data still exists (copy or move it in, matching the layout in `data/README.md`) | Any surviving downloads sit under the right `data/raw/<subfolder>` | 15–30 min |
| 1.4 | Run `scripts/00b_audit_data.R` | `outputs/tables/tbl_00_data_audit.csv` written; console shows PRESENT / MISSING per dataset | 5 min |
| 1.5 | Read the audit output; note which growth-track datasets are MISSING | You know exactly what must be re-downloaded in Week 2 | 10 min |
| 1.6 | `install.packages("renv")`; `renv::init()`; `renv::snapshot()` | `renv.lock` created | 20–30 min |
| 1.7 | Commit `renv.lock` and the audit table (`analysis: add renv lockfile and data audit`) | Committed and pushed to `main` | 5 min |

**Week 1 outcome (as run):** `00a` clean (GDAL 3.12.1 / GEOS 3.14.1 / PROJ
9.7.1; EPSG:7755 resolves). `data/raw/` left **empty** on purpose — the
surviving Phase 1 files are 7-reserve / wrong-edition, so they are not staged.
`00b` therefore reports **all 13 datasets MISSING** (the true baseline).
`renv` initialised and snapshotted (124 packages; R 4.5.2 pinned).

**Note — site already published:** the `gh-pages` bootstrap and first site
publish were completed during Week 0 (ahead of the Stage 4 schedule). The
Quarto CLI method is recorded in `docs/handoff.md`. This does not change the
Stage 4 plan — the site is republished with real content later; only the
plumbing is done early.

**Week 1 pitfalls:**
- Do **not** run `renv::init()` before `00a` passes — the toolchain must be
  verified first, or `renv` pins a broken environment.
- The audit only finds data that is in the right `data/raw/<subfolder>`. If a
  dataset reports MISSING but you think you have it, check placement before
  re-downloading (task 1.3 exists to prevent false MISSING results).

**Exit state:** `00a` clean, audit table written and read, `renv` initialised
and locked. You know the exact data gap to close in Week 2.

### Week 2 — task breakdown

Entry state: `00a` clean; `renv` locked; `data/raw/` empty; `00b` reports all 13
datasets MISSING. Boundary source not yet chosen.

Week 2 has two jobs: **(A)** make the boundary-source Decision, and **(B)** close
the acquirable part of the data gap. The all-reserve NTCA census is **not** a
Week-2 download — it is manual extraction scheduled for Weeks 4–5. Week 2
acquires everything that can be scripted or downloaded now.

| # | Task | Done when | Est. |
|---|---|---|---|
| 2.1 | Check whether the authoritative WII/NTCA all-reserve TR boundary layer is publicly downloadable (WII site, NTCA, any open portal) | You know: available (and how) or not available | 20–40 min |
| 2.2 | **Make the boundary-source Decision** (WII TR vs KBA fallback). Record it as a numbered Decision in `docs/methodology.md` with the reason and the Phase-1 KBA area caveat | Numbered Decision written; source chosen | 15–30 min |
| 2.3 | Acquire the chosen boundary source into `data/raw/boundaries/` (WII) or `data/raw/wdpa/` (KBA) | Boundary file on disk in the right subfolder | 20–40 min |
| 2.4 | Run scripted open-data downloads via `scripts/01_download_open_data.R`: GBIF tiger occ, GBIF target-group background, ESA WorldCover, gHM (Theobald 2024 v3), OSM roads + settlements (Geofabrik India) | Script completes; files land in `gbif/`, `worldcover/`, `ghm/`, `osm/` | 60–90 min (download-bound) |
| 2.5 | Acquire SRTM / terrain — `elevatr` AWS Terrain Tiles for the national extent, or SRTM tiles if preferred | Elevation data in `data/raw/elevation/` | 20–40 min |
| 2.6 | Manual downloads: admin boundaries (Natural Earth states + DataMeet districts) → `administrative/`; ISFR 2021 Chapter 4 → `forest/`; Singh & Sen 2015 PDF → `ntca/` | Each manual file in its subfolder | 30–45 min |
| 2.7 | Re-run `scripts/00b_audit_data.R` | Audit re-run; formerly-MISSING acquired datasets now report PRESENT | 5 min |
| 2.8 | Confirm no `data/restricted/` or raw data is staged for commit (`git status --short`) | Nothing under `data/` staged | 5 min |
| 2.9 | Commit the methodology Decision + updated docs (`docs:` scope, separate from any code commit) | Committed and pushed to `main` | 10 min |

**Not in Week 2:** the all-reserve NTCA census (manual PDF/Excel extraction —
Weeks 4–5), building the boundary layer itself (`scripts/02` — Week 3), and any
covariate processing (Stage 2). Week 2 stops at *raw data on disk* plus the
boundary Decision.

**Week 2 pitfalls:**
- **Licences.** KBA (non-commercial, attribution), WorldCover (CC BY 4.0), gHM
  (CC BY 4.0), OSM (ODbL), DataMeet (CC BY 4.0) all require attribution. Keep
  `docs/data-sources.md` and `data/data_manifest.csv` in sync with anything you
  add.
- **KBA area caveat.** If the Decision picks KBA, carry the Phase-1 note that KBA
  polygon area mismatched legal TR area and inflated Corbett's density. It must
  be documented, not silently used.
- **`00b` re-run reads presence only.** A PRESENT after acquisition confirms a
  file exists, not that it covers all reserves or the national extent. Judge
  coverage yourself.
- **Async GBIF background download.** The target-group background is a queued
  GBIF download, not instant — it may need a wait-and-fetch step. Do not treat a
  pending download as MISSING.

**Exit state:** boundary source chosen and recorded as a numbered Decision; all
scriptable and manually-downloadable datasets on disk; `00b` re-run shows the
reduced gap; the only remaining growth-track gap is the manual NTCA census
(Weeks 4–5).

**Week 2 outcome (as run):** Decision 4 (boundary) + Decision 5 (Mammalia
target group) recorded. `scripts/01` extended from stubs to 8 blocks and run.
**Acquired (12 of 14 manifest rows PRESENT):**
- GBIF tiger occ — 4,606 pts (DOI 10.15468/dl.npxmxx)
- GBIF Mammalia background — 39,057 pts, 2006–2022 (DOI 10.15468/dl.2d523e)
- ESA WorldCover 2021 — 1 km modal class
- gHM 2022 — 1 km (DOI 10.5281/zenodo.14502573)
- OSM roads 885,669 + settlements 199,800 (Geofabrik)
- Terrain elevation/slope/TRI — 1 km (elevatr AWS z7)
- NTCA DSS boundary KML, admin boundaries (36 states + 641 districts),
  ISFR 2021, Singh & Sen 2015 (manual)

The 2 MISSING rows (KBA, WDPA) are the **assessed-and-rejected** boundary
sources from Decision 4 (`required_for=none`) — they stay MISSING by design, not
a gap. **The NTCA census reports were NOT downloaded** — that moves to Week 3
(task 3.1); the `ntca_census` PRESENT in the audit is a stray/7-reserve file,
not the five All-India Tiger Estimation rounds. Task 2.3 wording (WII/KBA
subpaths) left as-is; the actual boundary source is the NTCA DSS KML per
Decision 4. `renv` snapshotted (adds osmextract, elevatr, rnaturalearthhires).

---

## Stage 1 — Growth (Weeks 3–7) · priority 1

This is the largest data-effort stage. Phase 1 extracted reserve-level census
for **7 reserves**. Extending to **all reserves** across five census rounds is
the main new work, and it is manual PDF/Excel extraction.

| Week | Focus | Exit state (deliverable) | Est. |
|---|---|---|---|
| **3** | Boundary layer built | `02` output: reserves layer with unit_id, state, landscape_complex, area_km2 | 3–4 h |
| **4** | Census extraction *(done — full series, not half)* | Full within-reserve census entered (`census_reserve_long.csv`); **Decisions 6 + 7** made | 3–4 h |
| **5** | Census join + area overwrite *(done)* | `03` output: `stats_reserve_census_7755.gpkg` (wide census joined to boundaries; `area_km2` overwritten from notified total per **Decision 8**; density) | 3–4 h |
| **6** | Growth metrics *(done)* | `04` output: `tbl_01_reserve_growth.csv` (change_abs, %, AAGR) + 4 columns appended to the stats layer; **Decision 9** made | 2–3 h |
| **7** | Growth visuals + roll-up | `05` outputs: ranking figure, regional roll-up table, animated choropleth (**3 frames — 2014/2018/2022 — per Decision 6, not 5**) | 3–4 h |

**At the end of Stage 1 the priority-1 track is complete and publishable on its
own.** If the project stops here, it is still a finished, worthwhile piece.

### Week 3 — task breakdown *(complete)*

Entry state (from Week 2): all covariates + admin boundaries on disk; NTCA DSS
boundary KML in `data/raw/ntca/`; ISFR 2021 + Singh & Sen fetched. Boundary
layer not yet built.

| # | Task | Done when | Est. |
|---|---|---|---|
| 3.1 | Download the five NTCA All India Tiger Estimation reports (2006, 2010, 2014, 2018, 2022) — PDF + any Excel — into `data/raw/ntca/` | All five rounds on disk; `00b` `ntca_census` PRESENT reflects the real reports | 20–40 min |
| 3.2 | Write `scripts/02_prepare_boundaries.R`: parse the NTCA DSS KML, separate PA polygons / corridors / unattributed | KML parsed; groups separated | 45–60 min |
| 3.3 | Match KML PA polygons to the 58 reserves via a reserve→constituent-PA crosswalk; resolve gaps and multi-part reserves by hand | All resolvable reserves matched; gaps logged | 45–60 min |
| 3.4 | Attach `unit_id`, `unit_name`, `unit_name_std`, `state`, `landscape_complex` | Every reserve polygon carries the standard identifiers | 30–45 min |
| 3.5 | Set `area_km2` (Decision 4 basis); dissolve multi-part reserves; add `source = "ntca"` | Area populated; geometry dissolved/validated | 20–30 min |
| 3.6 | Write `boundary_reserves_all_7755.gpkg`; update `data-dictionary.md` to match | Layer written; dictionary updated | 15–20 min |
| 3.7 | Commit (`analysis:` for `scripts/02`; `docs:` separate for dictionary/methodology) | Committed and pushed to `main` | 10 min |

**Week 3 outcome (as run):** all tasks done. Key deviations from the plan above,
all recorded in `docs/methodology.md` (Week-3 change log):
- The KML holds **PA polygons, not reserve entities**, so 3.3 became a
  hand-reviewed reserve→constituent-PA **crosswalk**
  (`data/raw/ntca/reserve_pa_crosswalk.csv`), not a direct name match. Match key
  is **name + state** (PA names are not unique). 10 reserves are multi-part and
  are dissolved.
- The GDAL KML driver dropped the attribute fields and split the file into two
  layers, so `scripts/02` parses the KML with **`xml2`** and rebuilds geometry
  from ring coordinates. New dependency: `xml2`.
- **3 gaps** (Amrabad, Pilibhit, Dholpur-Karauli) written as geometry-absent
  rows — the "2 false matches" (Bor, Kamlang) were name-lookup artefacts and are
  correctly matched.
- **`area_km2` is a flagged placeholder** (`area_provisional = TRUE`,
  `area_source = wikipedia_ntca_2022_PLACEHOLDER`) — the census overwrite is a
  Week-4/5 task, since the census table did not exist at build time.
- QA columns `poly_km2` / `poly_census_ratio` added; one outlier
  (Nagarjunsagar-Srisailam, ratio 1.54) documented in Limitations.

**Exit state:** `boundary_reserves_all_7755.gpkg` written (58 reserves: 55
geometry + 3 absent); `boundary_states_7755.gpkg` written; corridors and 156
duplicates set aside for later; the five NTCA census reports on disk ready for
Week 4–5 extraction.

### Week 4 — task breakdown *(complete)*

Entry state (from Week 3): `boundary_reserves_all_7755.gpkg` built, with
`area_km2` holding a **provisional placeholder** (`area_provisional = TRUE`).
The five NTCA All India Tiger Estimation reports (2006, 2010, 2014, 2018, 2022)
are on disk in `data/raw/ntca/`. No census figures extracted yet.

Week 4 starts the all-reserve census time series — the main new data effort of
the project. It is manual PDF/table extraction and is the natural
stop-and-resume task, split across Weeks 4–5.

| # | Task | Done when | Est. |
|---|---|---|---|
| 4.1 | Locate the reserve-level population tables in each of the five NTCA reports; note the page/table and the exact figure type (SECR estimate midpoint per Decision-4 limitations) | You know where each round's per-reserve figures live | 30–45 min |
| 4.2 | **Make the missing-year Decision** (pending, [Week 4] in methodology): how to treat reserves absent from a round (the Kaziranga-2006 problem, at scale — carry-forward, interpolate, leave `NA`, or use the Singh & Sen gap-fill). Record as a numbered Decision **before** entering data | Numbered Decision written in `docs/methodology.md` | 20–30 min |
| 4.3 | Decide the census table shape: long (`unit_id`, `year`, `pop`, `source`) vs wide (`pop_2006`…`pop_2022`). Naming-conventions §5 uses `pop_<year>`; the stats layer schema (`stats_reserve_census_7755.gpkg`) is wide — enter as long, pivot to wide on join | Table shape fixed; entry template created | 15–20 min |
| 4.4 | Extract ~half of the reserves into the census time series (start with the well-documented core reserves) | ~29 reserves entered across the five rounds | 90–120 min |
| 4.5 | Spot-check entered figures against a second source (Wikipedia 2022 column, ISFR, or the report's own summary) for the rows entered | Entered rows cross-checked; discrepancies logged | 20–30 min |
| 4.6 | Save the partial census table to `data/raw/ntca/` (or `data/interim/`); do **not** join to boundaries yet (that is Week 5) | Partial census table on disk, versioned | 10 min |
| 4.7 | Commit (`data:`/`analysis:` for the extraction; `docs:` for the missing-year Decision) | Committed and pushed to `main` | 10 min |

**Week 4 pitfalls:**
- **NTCA figures are estimates, not counts** (SECR; use the midpoint for
  comparability — a known limitation). Do not mix a count and an estimate for
  the same reserve-year.
- **Reserve names differ between the census reports and the boundary layer.**
  Join on `unit_id` via `unit_name_std`, not on raw `unit_name`. The 3
  geometry-absent reserves (Amrabad, Pilibhit, Dholpur-Karauli) still get census
  rows — they have a `unit_id`, just no polygon.
- **New reserves have short histories.** A 2014+ reserve has no 2006/2010
  figure; that is expected, not missing data to fill. The missing-year Decision
  (4.2) must distinguish "not yet a reserve" from "surveyed but not reported".
- **Do not overwrite `area_km2` yet unless the report gives core+buffer totals**
  you trust. If it does, overwriting the placeholder (and setting
  `area_provisional = FALSE`) can start here; otherwise it is a Week-5 join step.

**Decision due this week:** missing-year census handling (numbered Decision).

**Exit state:** ~half the reserves entered into the census time series; the
missing-year Decision recorded; table shape fixed. Week 5 finishes the extraction
and joins the census to the boundary layer (overwriting the placeholder
`area_km2`).

**Week 4 outcome (as run):** all 4.1–4.6 tasks done, and the extraction ran
**ahead of plan — the full series, not half**, because the data was already
located. Recorded in `docs/methodology.md` (Decisions 6 + 7; four Week-4 change
log entries).

- **4.1 — source map.** The per-reserve figures live in a **table only for
  2014/2018/2022** (2014 Table 2.2 pp.22-23; 2018 Table 3.4 pp.42-43; 2022 Table
  I.3.3 pp.28-29). **2006 and 2010 have no per-reserve table** — reserve-anchored
  figures sit in landscape-chapter prose, are partial, and are a different
  spatial unit (reserve + surrounds) and method (double sampling). Map:
  `outputs/tables/tbl_04_census_source_map.csv`.
- **Decision 6 (new)** — census figure type + baseline. The series is
  within-reserve SECR, **2014/2018/2022 only**; 2006/2010 are context, not a
  baseline. This drops the planned five-frame animation to **three frames** (a
  proposal deviation, logged).
- **4.2 → Decision 7 (new)** — missing (reserve, round) cells are `NA`; no
  carry-forward, interpolation, or gap-fill. The gap structure is
  left-censoring (reserves enter when first estimated), **no true internal gaps**.
- **4.3 — table shape.** Long (`census_reserve_long.csv`), pivots to wide on the
  Week-5 join. Documented in `data-dictionary.md`.
- **4.4 — extraction (full).** `census_reserve_long.csv` — **148 within-reserve
  rows across 53 reserves** + 5 never-estimated flag rows. 2022 transcribed from
  a page raster (its PDF text layer is corrupt).
- **4.5 — spot-check passed.** 2022 within-values match the PIB government
  release **17/17**; the 2014 column sums to the report's own total (1586)
  exactly. 2018 sum is +35 vs the report's de-double-counted 1923 — expected, not
  an error. Log: `outputs/tables/tbl_04_spotcheck_log.md`.
- **Prose sweep** (extra pass) — table-missing reserves checked in prose: found
  Orang 2014 (NP survey) and Ratapani 2022 (WLS complex) as **supplementary**
  rows (segregated, excluded from the series), and Mukundara 2014 = a real
  within-reserve **0** (+1 series row). No 2018 additions.
- **2006/2010 secondary table** (user request) —
  `census_reserve_long_2006_2010.csv`: 24 prose-derived figures, confidence-
  graded, context only. **Singh & Sen (2015) supplies no values** (its reserve
  bars are normalised indices sourced from NTCA); no other reference gives a
  comparable reserve-level count set (write-up:
  `docs/tbl_04_secondary_sources_2006_2010.md`).
- **Not done in Week 4 (moves to Week 5, as planned):** the census is **not
  joined to boundaries**, and `area_km2` is **still the provisional
  placeholder**.

### Week 5 — task breakdown

Entry state (from Week 4): `census_reserve_long.csv` holds the full within-reserve
SECR series (148 rows, 53 reserves, 2014/2018/2022) + 5 never-estimated flags,
spot-checked and on disk. `boundary_reserves_all_7755.gpkg` still has
**provisional** `area_km2` (`area_provisional = TRUE`). Decisions 6 + 7 fix the
series and the missing-year rule. The census is **not yet joined** to the
boundary layer.

Week 4 already finished the extraction, so Week 5 is the **join + area
overwrite** week: pivot the census to wide, attach it to the reserves, replace
the placeholder area with the census total area, and compute density. This writes
`stats_reserve_census_7755.gpkg` — the analysis-ready growth input for Week 6.

First check: the census reports give **population**, but Decision 4 wants
**official census total area** (core+buffer) to overwrite the placeholder
`area_km2` and to compute density. Task 5.1 confirms where that area table lives
(NTCA report annex vs. the crosswalk placeholder). If no trustworthy census area
table exists, the placeholder stays and `area_provisional` stays `TRUE` — density
is then deferred, not faked.

| # | Task | Done when | Est. |
|---|---|---|---|
| 5.1 | Locate the **official reserve area** (core+buffer) table in the NTCA reports (or confirm none is usable). Note page/table, as in the 4.1 map | You know the area source per reserve, or have confirmed there is none | 30–45 min |
| 5.2 | Write `scripts/03_prepare_census.R`: read `census_reserve_long.csv`, validate against `CENSUS_YEARS`/`unit_id`, pivot long → wide (`pop_2014`, `pop_2018`, `pop_2022`) per Decision 6 | Script reads long, pivots wide; row count and `unit_id` set verified | 45–60 min |
| 5.3 | Join the wide census to `boundary_reserves_all_7755.gpkg` on `unit_id`; carry `census_status`; confirm all 58 reserves present (53 measured + 5 flagged) | Join clean; no unmatched `unit_id`; the 3 geometry-absent reserves still carry census rows | 20–30 min |
| 5.4 | **Overwrite `area_km2`** from the census area table (5.1); set `area_provisional = FALSE` and `area_source` to the census; leave placeholder + `TRUE` for any reserve with no census area | Every row with a census area updated; `area_provisional` flag correct per row | 20–30 min |
| 5.5 | Compute `density_2022` = `pop_2022` ÷ census `area_km2` × 100 (per 100 km²); `NA` where either input is `NA` | Density populated where inputs exist; `NA` elsewhere, not 0 | 15–20 min |
| 5.6 | Set `baseline_year` per reserve (earliest non-`NA` round) — do **not** compute change/AAGR yet (that is Week 6) | `baseline_year` correct (2014 core; 2018/2022 late entries) | 10–15 min |
| 5.7 | Write `stats_reserve_census_7755.gpkg`; update `data-dictionary.md` to match the as-built fields | Layer written; dictionary matches | 15–20 min |
| 5.8 | Glance at the 6 crosswalk `review` rows (Kamlang, Pench-MP, Pench-MH, Bor, Similipal, Nagarhole) — confirm each census row landed on the right `unit_id` | The name-collision reserves are joined correctly | 15 min |
| 5.9 | Reconcile config drift: `R/00_config.R` still has `BASELINE_YEAR <- 2006L` and `BASELINE_WINDOW <- c(2006,2010)`, which pre-date Decision 6. Update to the 2014 baseline (or add a comment pointing to Decision 6) | Config no longer contradicts Decision 6 | 10–15 min |
| 5.10 | Commit (`analysis:` for `scripts/03` + the stats layer; `docs:` for dictionary/config notes) | Committed and pushed to `main` | 10 min |

**Week 5 pitfalls:**
- **Population area ≠ polygon area.** Decision 4 is strict: `area_km2` and
  `density_2022` use the **official census total area**, never the KML
  `poly_km2`. If 5.1 finds no usable census area, do not silently fall back to the
  polygon — leave the placeholder and defer density.
- **Two Pench, two `unit_id`.** The pivot and join key on `unit_id`, never
  `unit_name`. The 4.4 extraction already split Pench-MP (23) and Pench-MH (33);
  the join must preserve that. Check row 5.8.
- **Never-estimated reserves must survive the join.** The 5 flag rows
  (`census_status = not_estimated_post2022_notification`) have `pop = NA` and no
  year — they should map with `NA` population, not be dropped by an inner join.
  Use a left join from the 58-reserve boundary layer.
- **Supplementary rows stay out.** `census_reserve_long_2006_2010.csv` and the
  Orang/Ratapani supplementary rows are **not** inputs to the wide pivot. Filter
  to `census_status = measured` AND `spatial_unit = within_reserve` before
  pivoting.
- **`area_provisional` is the audit column.** After 5.4, any row still `TRUE`
  is a reserve with no census area — that is a real gap to note, not a bug.

**Decision due this week:** none required. (If 5.1 finds the census area is
unusable and a fallback is needed, that becomes a numbered Decision — but the
default is to defer density, not to decide.)

**Exit state:** `stats_reserve_census_7755.gpkg` written — all 58 reserves,
wide census (`pop_2014/2018/2022`), census-sourced `area_km2` (placeholder
overwritten where a census area exists), `density_2022`, `baseline_year`,
`census_status`. Growth metrics (change/%/AAGR) are **not** computed yet — that is
Week 6. Config drift reconciled.

**Week 5 outcome (as run):** completed. `scripts/03_prepare_census.R` reads the
long census, validates + pivots wide (53 reserves; 45/50/53 by round), left-joins
onto the boundary layer (58 reserves; 53 measured + 5 flagged; 3 geometry-absent
keep their census), overwrites `area_km2` from `tbl_05_area_source_map.csv`, and
computes `density_2022` (52 values; NA for the 5 flagged + Sundarbans) and
`baseline_year` (45 at 2014, 5 at 2018, 3 at 2022). **Decision 8** (area source =
NTCA-notified core+buffer total; ISFR-2021 Ch.4 is cross-check only, not the
area source) was made this week. **The area overwrite changed zero values** — the
Week-3 placeholder already matched the notified totals to the cent, so the
overwrite was provenance-only (flag + source). Config drift reconciled
(task 5.9): `CENSUS_SERIES_YEARS`/`CENSUS_BASELINE_YEAR` added; `BASELINE_YEAR`/
`CURRENT_YEAR` kept at 2006/2022 because `scripts/01` uses `BASELINE_YEAR` as the
GBIF download bound — not the census baseline. QA tables tbl_06–tbl_09 written.
Crosswalk `review` rows (task 5.8) all verified correct.

---

## Week 6 — task breakdown

Entry state: `stats_reserve_census_7755.gpkg` written with `pop_2014/2018/2022`,
`area_km2` (notified), `density_2022`, `baseline_year`, `census_status`. The
growth-metric columns (`change_abs`, `change_pct`, `aagr`) exist in the
data-dictionary schema but are **not yet populated** — Week 6 computes them.

Week 6 extends `scripts/03` (or adds `scripts/04`, see 6.1) to compute per-reserve
growth over each reserve's **own observed span** (baseline → 2022), per Decision 6
(series 2014/2018/2022) and Decision 7 (`NA`, no imputation). No new data.

| # | Task | Done when | Est. |
|---|---|---|---|
| 6.1 | Decide where growth metrics live: extend `scripts/03` (append columns to the same layer) **or** add `scripts/04_growth_metrics.R` reading the stats layer. Recommend `04` — keeps `03` as "assemble the layer", `04` as "derive metrics", and matches the `tbl_01`/`fig` output naming | Location chosen; script header written | 10 min |
| 6.2 | `change_abs` = `pop_2022 − pop_baseline`, where `pop_baseline` is the pop in each reserve's `baseline_year`. `NA` for reserves with only one round (2022-only entries) or `NA` `pop_2022` (Sundarbans, the 5 flagged) | `change_abs` populated; `NA` exactly where < 2 rounds or endpoint missing | 20–30 min |
| 6.3 | `change_pct` = `change_abs / pop_baseline × 100`. Guard `pop_baseline == 0` (Mukundara baseline 2014 = 0): a 0→N change is undefined as a percent — store `NA` and flag, do not divide by zero | `change_pct` populated; `NA` for single-round and zero-baseline reserves; zero-baseline cases flagged | 20–30 min |
| 6.4 | `aagr` = `(pop_2022 / pop_baseline)^(1 / (2022 − baseline_year)) − 1`, as a percent. Same zero-baseline and single-round guards (`NA`, not error/Inf) | `aagr` populated with the same `NA` pattern; no `Inf`/`NaN` | 20–30 min |
| 6.5 | Decide the treatment of **real within-reserve zeros** in the endpoints as a numbered Decision (they break ratio-based metrics): baseline 0 (Mukundara 0→1→1) and 2022 = 0 (Kamlang, Dampa, Kawal, Satkosia, Sahyadri — declines to local extirpation). `change_abs` is always valid; `change_pct`/`aagr` are `NA` where baseline = 0. Record as **Decision 9** | Decision 9 written in `methodology.md`; guards match it | 15–20 min |
| 6.6 | Write `outputs/tables/tbl_01_reserve_growth.csv` — per-reserve `unit_id, unit_name, state, landscape_complex, baseline_year, pop_<baseline>, pop_2022, change_abs, change_pct, aagr, density_2022, census_status`, sorted by a sensible growth metric | `tbl_01_reserve_growth.csv` written | 15–20 min |
| 6.7 | Verify: no `Inf`/`NaN` anywhere; `NA` pattern matches Decision 7/9; national picture sane (most reserves growing; the handful of declines/zeros identified); spot-check 2–3 known reserves (e.g. Corbett, Ranthambore, a zero-2022 case) | Verification block passes; spot-checks match the source figures | 15 min |
| 6.8 | Append `change_abs/change_pct/aagr` to `stats_reserve_census_7755.gpkg` (so the layer and `tbl_01` agree), update `data-dictionary.md` (mark the three columns as built, drop the "Week 6" tag) | Layer updated; dictionary matches as-built | 15 min |
| 6.9 | Commit (`analysis:` for the metrics + layer/table; `docs:` for Decision 9 + dictionary) | Committed and pushed | 10 min |

**Week 6 pitfalls:**
- **Zero baseline breaks ratios.** Mukundara's 2014 = 0 makes `change_pct` and
  `aagr` undefined (÷0). Store `NA` and flag — do not report an infinite growth
  rate. `change_abs` (0→1 = +1) is still valid. This is what Decision 9 fixes.
- **Per-reserve span, not a fixed 2014→2022.** AAGR uses each reserve's own
  `baseline_year` → 2022 gap (8, 4, or 0 years). A reserve with only a 2022 row
  has a zero-length span → no metric (`NA`), not a divide-by-zero.
- **Sundarbans has no 2022 within-figure.** Its `pop_2022` is `NA`, so all three
  metrics are `NA` even though it has 2014/2018 values. Correct per Decision 7.
- **Single-round reserves.** The 2022-only entries (Navegaon-Nagzira, Ramgarh
  Vishdhari, Srivilliputhur-Megamalai, Ranipur) get `NA` growth — one point is
  not a trend.

**Decision due this week:** **Decision 9** — treatment of real within-reserve
zeros in growth metrics (task 6.5).

**Exit state:** `tbl_01_reserve_growth.csv` written and the three growth columns
populated on the stats layer; Decision 9 recorded; dictionary updated. The
priority-1 growth **numbers** are complete — only the Week-7 visuals/roll-up
remain to finish Stage 1.

**Week 6 outcome (as run):** `scripts/04_growth_metrics.R` built (tasks 6.1-6.8).
- **6.1 — script location.** Metrics live in a new `scripts/04_growth_metrics.R`
  (derive), NOT in `scripts/03` (assemble). The pre-existing visuals stub
  `04_growth_analysis.R` was **renumbered to `05_growth_analysis.R`** (Week 7), so
  each filename matches its week's deliverable.
- **Decision 9** made (real within-reserve zeros): `change_abs` always valid;
  `change_pct`/`aagr` = `NA` + `growth_zero_flag = TRUE` where the baseline is 0
  (Mukundara); a real decline to 0 in 2022 is a valid -100 / -100%·yr, not `NA`;
  never `Inf`/`NaN`.
- **Metrics as built:** `change_abs` non-`NA` 49; `change_pct`/`aagr` non-`NA` 48;
  `growth_zero_flag` TRUE 1 (Mukundara). National split: 32 growing, 17 declining,
  0 flat, 9 `change_abs` `NA`. Fastest growth Manas (+23.1%/yr, 11->58); five
  extirpations at -100%/yr (Kamlang, Sahyadri, Dampa, Satkosia, Kawal).
- **New column** `growth_zero_flag` added to `tbl_01` and the stats layer, so a
  ratio-undefined `NA` is distinct from a missing-data `NA`.
- **Deviation from the 6.6 spec:** `tbl_01` carries `pop_baseline` + `baseline_year`
  (a single `pop_<baseline>` column is impossible - reserves have different
  baseline years); sorted by `change_pct` desc, `NA`s last.

### Week 7 — task breakdown *(complete)*

Entry state: `stats_reserve_census_7755.gpkg` carries all growth columns
(`change_abs`, `change_pct`, `aagr`, `growth_zero_flag`); `tbl_01_reserve_growth.csv`
written. `scripts/05_growth_analysis.R` is the renumbered stub (header only).
No new data. This week is the Stage-1 finish: turn the numbers into the
publishable ranking figure, the regional roll-up, and the animated choropleth.

Week 7 fills in `scripts/05_growth_analysis.R`, reading the stats layer only. Per
Decision 6 the animation has **3 frames (2014/2018/2022)**, not 5. Per Decisions
7/9 the visuals must show `NA` reserves (single-round, Sundarbans, the 5 flagged)
and the `growth_zero_flag` reserve as a distinct category, never as 0 or a gap.

**As built:** all of 7.1–7.6 done in `scripts/05_growth_analysis.R` (STEP 1 read;
STEP 2–3 roll-up engine; STEP 4 tbl_02; STEP 5 fig_01; STEP 6 fig_02; STEP 7 the
7.6 verification block). `tbl_02_regional_rollup.csv` (23 rows: 5 landscape + 18
state), `fig_01_growth_ranking.png`, and `fig_02_growth_animation.gif` written.
The 7.6 block passes all 13 checks. Regional totals reconcile across both
groupings and the per-reserve table (pop_2014 1586, pop_2018 1958, pop_2022 2257,
change_abs +651; n_measured 53). Roll-up ratio is population-weighted (sum pops,
then %); regional AAGR uses a pop_baseline-weighted mean span, with change_pct as
the primary regional ratio. Landscape picture: Central India +282 (+59.7%),
Shivalik-Gangetic +239 (+58.9%), Western Ghats +108 (+19.8%), North-East Hills
+22 (+13.2%), Sundarbans NA. 7.7 (this doc pass) and 7.8 (commit) close the week.

| # | Task | Done when | Est. | Status |
|---|---|---|---|---|
| 7.1 | Header/scope of `scripts/05_growth_analysis.R`: reads `stats_reserve_census_7755.gpkg`; writes `fig_01`, `fig_02`, `tbl_02`. Confirm the old "fill in Week 4" stub comment is replaced | Script header matches the deliverable; no stale week reference | 10 min | ✅ Header rewritten; frame count fixed to 3 (was "five census years"); stale `# ... (fill in Week 4)` replaced with `TODO(Week 7)` staging |
| 7.2 | Regional roll-up: aggregate `pop_2014/2018/2022`, `change_abs`, and a coverage count to **landscape_complex** and **state**. Decide the roll-up rule for `NA` pops (sum over non-`NA` only; report n contributing) and for the ratio metrics (roll up absolute pops, then recompute % on the sums — do NOT average per-reserve %). Record the rule inline | Roll-up computed for both units; `NA`-handling rule stated | 40–60 min | ✅ `rollup_by()` for both units; rule recorded inline (STEP 2). Ratio recomputed on summed pops over a single contributor set; regional AAGR over a pop_baseline-weighted mean span |
| 7.3 | Write `outputs/tables/tbl_02_regional_rollup.csv` (landscape_complex + state blocks; pops per round, absolute change, % change on summed pops, reserve count, n measured) | `tbl_02_regional_rollup.csv` written | 20–30 min | ✅ 23 rows. Added `n_measured` (census_status == "measured"); kept per-field coverage counts + `aagr`/`span_region` as extensions |
| 7.4 | `fig_01` ranking figure: reserves ranked by a chosen growth metric (default `change_pct`, `NA`s excluded or shown separately), faceted or coloured by landscape_complex. State the effort/detection caveat in the caption (success criterion) | `fig_01_growth_ranking.png` written; caveat in caption | 45–60 min | ✅ Faceted by landscape (top strips), fill = growth sign, site palette. NAs excluded from bars AND counted per facet ("N not ranked"). Caveat wrapped in caption. Sundarbans facet (0 ranked) dropped from plot, reported in console |
| 7.5 | `fig_02` animated choropleth: reserve polygons coloured by a per-round growth category across **3 frames** (2014/2018/2022). Geometry-absent reserves (Amrabad, Pilibhit, Dholpur-Karauli) and `NA`-pop reserves shown as a distinct "no estimate" class, never as 0 | `fig_02_growth_animation.gif` written; `NA`/absent reserves visibly distinct | 60–90 min | ✅ 3 held frames via `transition_manual` (fixed geometry). NA → grey "No estimate"; real 0 → near-white "0 (real)"; 3 geometry-absent named off-map, never drawn. Renderer fallback to 3 PNGs if gganimate/gifski missing |
| 7.6 | Verify: roll-up sums reconcile to the per-reserve table; frame counts = 3; no reserve rendered as 0 where it is actually `NA`; the `growth_zero_flag` reserve is not shown as a decline | Verification block passes | 20 min | ✅ STEP 7 hard-stopping block; all 13 checks OK |
| 7.7 | Update `data-dictionary.md` (add `tbl_02_regional_rollup.csv` schema) and `README.md`/handoff (Week 7 -> complete, Stage 1 done) | Docs match as-built | 15–20 min | ✅ This pass |
| 7.8 | Commit (`analysis:` for `05` + figures/table; `docs:` for dictionary/handoff, separate) | Committed and pushed | 10 min | ⬜ Kiran to commit |

**Week 7 pitfalls:**
- **`NA` is not 0 on a map.** A reserve with no estimate for a round (single-round,
  Sundarbans 2022, the 5 flagged, the 3 geometry-absent) must render as a distinct
  "no estimate" class, never as a zero-population choropleth cell. This is the most
  likely way the visuals could misrepresent Decision 7.
- **Do not average per-reserve percentages for the roll-up.** Sum absolute pops per
  region, then compute the regional % on those sums. Averaging % over-weights small
  reserves (a 0->1 reserve and a 200->260 reserve are not equal weight).
- **3 frames, not 5.** The animation is 2014/2018/2022 (Decision 6). 2006/2010 have
  no per-reserve series.
- **`growth_zero_flag` reserve.** Mukundara (0->1->1) is real recovery with an
  undefined %; show it in a category that is not "decline" and not "no data".

**Decision due this week:** none required. (The roll-up `NA` rule in 7.2 is an
inline analytical choice; promote it to a numbered Decision only if it proves
contested — it is not, so it stays inline.)

**Exit state:** `fig_01`, `fig_02`, and `tbl_02` written; the Stage-1 growth track
is complete and publishable on its own. Docs updated; Week 7 ticked.

**Week 7 — discovered facts (carry forward):**
- **`gifski` was missing from `renv`; `gganimate` was present.** `fig_02` needs a
  renderer. Installed `gifski` (CRAN ships a Windows binary — no Rust toolchain),
  `renv::snapshot(packages = c("gganimate","gifski"))` (a bare snapshot may miss
  it because the script uses `requireNamespace`, not `library`). Now locked.
- **`transition_states` tweens `geom_sf` geometry** — reserves appeared to move
  between frames. For a fixed-geometry choropleth use **`transition_manual`**
  (discrete held frames, no vertex interpolation). Do the same for any future
  animated map.
- **`summarise()` name collision:** an output column must not reuse an input
  column name that a later expression in the same call still reads (a summed
  `pop_2022` shadowed the original, making `sum(!is.na(pop_2022))` return 1).
  Emit sums under `sum_*` names, rename at the end. Cost one debug cycle.
- **`forcats` is not in `renv`.** Used base `reorder()` for within-facet bar
  ordering instead of `fct_reorder`. Do not add `forcats` just for this.
- **Roll-up ratio is population-weighted, not a mean of per-reserve %.** Regional
  AAGR needs one span; used the pop_baseline-weighted mean span. `change_pct` is
  the primary regional ratio, `aagr` secondary (mixed-span caveat).

---

## Stage 2 — Connectivity (Weeks 8–12) · priority 2

| Week | Focus | Exit state (deliverable) | Est. |
|---|---|---|---|
| **8** | Covariate stack | `scripts/06` output: land cover, terrain, gHM, dist-to-road aligned to one 1 km grid | 3–4 h |
| **9** ✅ | Resistance surface | **Decisions 11–16**; `scripts/07_connectivity.R` STEPs 9.2 + 9.5–9.8 → four resistance surfaces (`baseline`, `noghm`, `road15`, `road50`) + `tbl_11_resistance_qa.csv` | 2–3 h planned; ~4× as run |
| **10** ✅ | Least-cost paths | **Decisions 17–18**; `scripts/07_connectivity.R` STEPs 10.0–10.5 → 106 pairs, paths on four surfaces (`lcp_reserve_network_7755.gpkg`), validation, QA, Decision-18 comparison, NTCA overlap (`tbl_12_*`); `scripts/02` Amrabad split | 3–4 h planned; well over as run |
| **11** ✅ | Reserve network graph | **Decision 19**; `scripts/07_connectivity.R` STEPs 11.1–11.4 with `R/00_functions_network.R` → 47 nodes (56 reserves), 73 edges, 3 sets; node metrics, second run without cross-group links, threshold scan, Decision-19 variant comparison, network QA (`tbl_13_*`); literature check | 3–4 h planned; as-run time not recorded |
| **12** ✅ | Pinch points + visuals | **Decision 20**; `scripts/07_connectivity.R` STEPs 12.1–12.7 with `R/00_functions_pinch.R` → 556 road crossings on 74 of 76 baseline paths, 365 sites, 200 pinch points (tier 1: 3, tier 2: 98, tier 3: 99); Decision-20 variant comparison (gHM multiplier sensitive, road value robust); QA 74 of 74 (`tbl_14_*`); the publishable `tbl_03_reserve_network.csv`, `tbl_03b_pinch_points.csv` and `tbl_03_notes.md`; `fig_03_reserve_network.png`; literature check | 3–4 h planned; the task estimates added up to 5.5–7.7 h; as-run time not recorded |

**Script plan (fixed 2026-09-26):** all of Stage 2 from Week 9 on is **one
script, `scripts/07_connectivity.R`**, with one STEP block per task (STEP 9.x,
10.x, 11.x, 12.x). Each week adds its STEPs to the same file. This replaces the
earlier plan of a separate `07_build_resistance.R`.

### Week 8 — task breakdown *(complete)*

**Week 8 outcome (as run):** all six tasks done in
`scripts/06_build_covariate_stack.R`. Built the 1 km EPSG:7755 template (3093 ×
2864 = 8,858,352 cells; boundary + 5 km collar, extent snapped to whole
`GRID_CELL_M`), aligned the three Week-2 covariates onto it (WorldCover nearest;
gHM + terrain bilinear; `compareGeom` PASS), derived `cov_distroad_1km_7755.tif`
(rasterise→distance over 885,669 roads), and stacked six bands to
`cov_stack_1km_7755.tif` under a common NA mask (**Decision 10**). QA
(`tbl_10_covariate_stack_qa.csv`): all bands 3,010,738 cells / 98.15% of India /
range_ok TRUE; stacked-vs-source spot-check confirms values intact. gHM is the
binding NA layer (56,827 India-grid cells, 1.85%, lost — exact figure from the
2026-09-26 re-run of `tbl_10`); a gHM gap-fill relevance check is deferred to
Week 9 (Decision 10). Deliverable renamed `06_covariates.R` →
`06_build_covariate_stack.R` (naming §3); the old stub is deleted (confirmed
2026-09-26).

Entry state (as of Week-7 close): Stage 1 (growth) is done. On disk from Week 2
(`scripts/01`), all on the 1 km EPSG:7755 grid where raster: WorldCover 2021
(1 km modal), gHM 2022 (1 km), terrain (elevation/slope/TRI, 1 km), OSM roads
(885,669) and settlements (199,800). `boundary_reserves_all_7755.gpkg` and
`boundary_states_7755.gpkg` built (Week 3). No census dependency in Stage 2.

Week 8 builds `scripts/06_build_covariate_stack.R`: assemble one aligned,
analysis-ready covariate raster stack on a single 1 km EPSG:7755 template, so the
Week-9 resistance surface and the Week-13+ SDM read the same grid. This week is
**assembly and alignment only** — no resistance values yet (that is Week 9's
numbered Decision), no modelling.

Naming (naming-conventions §2/§6): stack `cov_stack_1km_7755.tif`; per-layer
interim `cov_<subject>_1km_7755.tif`; QA tables `tbl_10`+ (output counter is
independent of the script prefix).

| # | Task | Done when | Est. |
|---|---|---|---|
| 8.1 | Header/scope of `scripts/06_build_covariate_stack.R`: reads the Week-2 covariate layers + boundaries; writes `cov_stack_1km_7755.tif` + QA. Confirm no stale stub text | Header matches the deliverable; runs `source(00_config, 00_functions_io)` | 10 min |
| 8.2 | Define the **1 km analysis template** (extent = India boundary buffered to a clean grid; res 1000 m; CRS 7755). Record it once so every layer resamples to it. Use `GRID_CELL_M` from config, never a hardcoded 1000 | One `terra::rast` template; extent/res/CRS asserted; written or held for reuse | 30–40 min |
| 8.3 | Align the existing covariates to the template: WorldCover (categorical → **nearest**), gHM and terrain (continuous → **bilinear**). Guard against silent CRS/res mismatch; re-assert against the template after. *(As built: `terra::resample()` onto the template, NOT `read_rast()` — the inputs are already EPSG:7755, and `read_rast()` would reproject onto an auto grid and interpolate twice.)* | 3 covariate layers on the identical grid; `compareGeom` passes | 40–60 min |
| 8.4 | Derive **distance-to-road** from OSM roads on the template grid (`terra::distance` to the road layer, or rasterise + distance). Decide the road-class set for "road" here as an **inline** choice (record it); the *barrier* road-class Decision is Week 9, keep them separate | `cov_distroad_1km_7755.tif` on the grid; class set recorded inline | 40–60 min |
| 8.5 | Stack the aligned layers into `cov_stack_1km_7755.tif` with stable, documented band names (`landcover`, `ghm`, `elev`, `slope`, `tri`, `dist_road_m`). NA-mask consistently (a cell NA in one layer policy — decide and record) | Multi-band GeoTIFF written via `write_processed_rast`; band names set | 30–40 min |
| 8.6 | QA: per-band coverage (% non-NA over India), min/max sanity, and a value spot-check against the Week-2 interim layers. Write `tbl_10_covariate_stack_qa.csv` | QA table written; no all-NA band; ranges plausible | 30 min |
| 8.7 | Update `data-dictionary.md` (add `cov_stack_1km_7755.tif` band schema) and `README.md`/handoff (Week 8 status, entry point for Stage 2) | Docs match as-built | 15–20 min |
| 8.8 | Commit (`analysis:` for `06` + stack/QA; `docs:` separate) | Committed and pushed | 10 min |

**Week 8 pitfalls:**
- **One template, resample everything to it.** Do not resample layers to each
  other pairwise — pick the India-extent 1 km template once and align every layer
  to it, or bands will drift by a cell and `compareGeom` will fail at stack time.
- **Categorical vs continuous resampling.** WorldCover must use **nearest**
  (`terra::resample(method = "near")`); gHM/terrain use **bilinear**. Bilinear on
  a class raster invents fractional land-cover codes.
- **PROJ `proj.db` clash still applies.** Same machine trap as Stage 1 — confirm
  `crs(rast(crs="EPSG:7755"))` prints the India NSF LCC WKT in a fresh session
  before any reprojection (see handoff "Known gotchas").
- **Keep the barrier-road Decision for Week 9.** 8.4's road set is only for a
  distance covariate; the resistance/barrier road-class choice is a numbered
  Decision next week. Do not pre-empt it.
- **Settlement layer is village-dominated (~195k).** It is a Week 8–9 pending
  Decision (trim to city/town, or change KDE radius). If distance-to-settlement
  is wanted as a covariate, raise the trim first — do not stack the raw 199,800.

**Decision due this week:** none numbered required for the covariate stack itself
beyond **Decision 10** (the cross-band common NA mask — made as built). Three
items come due next (Week 9): land-cover **resistance values**, the **barrier road
classes**, and the **Decision-10 gHM gap-fill relevance check**. All three are
surfaced at Week-8 close so Week 9 opens with them ready to decide.

**Exit state:** `cov_stack_1km_7755.tif` written and QA'd — one aligned 1 km grid
that Weeks 9 (resistance) and 13+ (SDM) both read. Docs updated; Week 8 ticked.

---

### Week 9 — task breakdown *(complete)*

**Week 9 outcome (as run, 2026-09-26):** all tasks done. `scripts/07_connectivity.R`
started as the single Stage-2 script (header for Weeks 9–12; STEP 9.2; STEPs
9.5–9.8). **Decision 10 closed** through Decisions 11–13: the pre-fill relevance
check triggered (27 of 169 units) → gHM gap-fill in `scripts/06` STEP 8.4b → the
re-check still triggered on a land-cover edge shift → **Decision 12** (land cover
from the unmasked tile cache) → still triggered on a terrain edge shift →
**Decision 13** (terrain from the raw DEM) → CLEAR. Final stack (`build_tag`
d13f): 3,067,467 complete-case cells of 3,067,565 India-grid cells. A write
defect was found and fixed: the stack file had been `INT1U` on disk; every raster
write is now explicit-type and verified on read-back. **Decisions 14–16** set the
resistance rules (set-B class values × (1 + 4 × gHM), cap 100, Sundarban water
10, road barrier motorway–secondary at 30 by the maximum rule, water exempt from
gHM). Four surfaces written — `baseline`, `noghm`, `road15`, `road50` — all
asserts PASS (`tbl_11_resistance_qa.csv`; first build kept as
`tbl_11_resistance_qa_pred16.csv`). Baseline mean 22.46; 41.4 % of cells ≥ 30
(busy cropland × gHM), so the road barrier adds nothing in busy farmland — the
`noghm` comparison in Week 10 tests this. The week took about four times the
planned 2–3 h because of the Decision-10 chain and the write defect.

Entry state (as of Week-8 close): `cov_stack_1km_7755.tif` written (6 bands:
`landcover`, `ghm`, `elev`, `slope`, `tri`, `dist_road_m`; common NA mask,
3,010,738 complete-case cells) and QA'd (`tbl_10`). `cov_distroad_1km_7755.tif`
held un-common-masked in `data/interim/`. `WORLDCOVER_RESISTANCE` in
`R/00_config.R` holds a literature-informed **starting** set (not yet a Decision).
OSM roads (`osm_roads_major_7755.gpkg`, 885,669 features, tertiary-dominated) on
disk. Reserve geometry available (`boundary_reserves_all_7755.gpkg`). **Plan gap
(found 2026-09-26):** no task extracted the NTCA corridor polygons that Week 3
set aside — task 9.2a below closes it.

Week 9 starts `scripts/07_connectivity.R` (one script for all of Stage 2) and
fills its resistance STEPs: turn the covariate stack into a
movement-**resistance** surface on the same 1 km EPSG:7755 grid, so Week 10's
least-cost paths read it directly. This week is where the two deferred
connectivity Decisions are **made before any resistance raster is written**, and
where the Decision-10 gap-fill question is **resolved**.

Naming (naming-conventions §2/§6): resistance raster
`resist_tiger_baseline_7755.tif`; QA tables `tbl_11`+ (output counter independent
of the script prefix).

**Status (2026-09-26):** 9.1 ✅ · 9.2a ✅ · 9.2 ✅ (via 9.2b–9.2d; **Decision 10
closed**, final stack 3,067,467 complete-case cells) · 9.3 ✅ (**Decision 14**) ·
9.4 ✅ (**Decision 15**) · 9.5–9.8 ✅ (first build → **Decision 16**, water
exempt from gHM → rebuild, all asserts PASS) · 9.9 ✅ · 9.10 ✅.

| # | Task | Done when | Est. |
|---|---|---|---|
| 9.1 | Header/scope of `scripts/07_connectivity.R`: the header covers all of Stage 2 (Weeks 9–12) and lists the STEP blocks; Week 9 fills only the resistance STEPs. Reads `cov_stack_1km_7755.tif` (+ OSM roads for the barrier class); writes `resist_tiger_baseline_7755.tif` + QA; `source(00_config, 00_functions_io)` | Header matches the deliverable; runs the sources | 10 min |
| 9.2a | Add a corridor output to `scripts/02`: write the 59 NTCA corridor polygons to `boundary_corridors_7755.gpkg`; re-run `02` with a guard that stops if the reserve layer would change | Corridor layer written; guard reports the reserve layer identical | 20–30 min |
| 9.2 | **Resolve Decision 10 (gHM gap-fill relevance check).** Rule fixed first as **Decision 11** (units: reserve polygons + NTCA corridors + 10 km reserve rings; any-touch membership; land cells only; material if ≥ 5 % or ≥ 25 land cells dropped; fill = iterative 3 × 3 focal mean, ≤ 5 passes). Then `scripts/07_connectivity.R` STEP 9.2 counts the 56,827 dropped India-grid cells per unit → `tbl_11_ghm_gap_relevance.csv`. If any unit is material, apply the fill and rebuild the stack; if none, close Decision 10 "no fill needed" | Decision 11 recorded before the run; `tbl_11` written; outcome recorded in methodology | 40–60 min |
| 9.2b | Pre-fill check TRIGGERED (27 units). Fill in `scripts/06` STEP 8.4b (`GHM_GAP_FILL <- TRUE`), rebuild the stack, re-run `scripts/07` STEP 9.2 (post-fill). Clear → Decision 10 closes; still triggered → stop and decide again before 9.3 | `tbl_10` has `n_filled`; `tbl_11_ghm_gap_relevance_postfill.csv` written; outcome recorded in methodology | 30–45 min |
| 9.2c | Post-fill check STILL TRIGGERED (1 corridor; cause = 1,778 India cells with no land-cover class, not gHM). **Decision 12:** gHM closed; `scripts/06` builds land cover from the unmasked tile cache, masked on the template (guard: no interior class changed or lost). Re-run `06` + `07` STEP 9.2 (`postfill_d12`). Clear → Decision 10 closes; still triggered → stop and decide again | `tbl_11_ghm_gap_relevance_postfill_d12.csv` written; edge vs interior no-class cells reported; outcome recorded | 30–45 min |
| 9.2d | `postfill_d12` check STILL TRIGGERED (same corridor; cause = terrain `NA` at the 1,771 edge cells). **Decision 13:** `scripts/06` rebuilds terrain from the raw DEM (the `scripts/01` path without its mask), masked on the template; interior guard (5 × 5 core, tolerance 0.01); 7 interior no-class cells accepted. Re-run `06` + `07` STEP 9.2 (`postfill_d13`). Clear → Decision 10 closes; still triggered → stop and decide again | `tbl_11_ghm_gap_relevance_postfill_d13.csv` written; outcome recorded; interior cells listed | 30–45 min |
| 9.3 | **Make the land-cover resistance-value Decision (numbered — Decision 14).** Review `WORLDCOVER_RESISTANCE` against tiger movement literature; confirm or revise the 11 class values (1 = easiest … high = barrier). Record the final set + rationale as a numbered Decision. Do **not** hardcode values in `scripts/07` — read them from `R/00_config.R` | Numbered Decision written; `WORLDCOVER_RESISTANCE` finalised in config | 30–45 min |
| 9.4 | **Make the barrier road-class Decision (numbered — Decision 15).** Decide which OSM road classes act as movement barriers in the resistance surface — keep tertiary or restrict to motorway–secondary. Separate from the 8.4 distance covariate (which kept all classes). Record the class set + barrier weight rationale | Numbered Decision written; barrier class set fixed | 20–30 min |
| 9.5 | Build the Decision-14 surface: reclassify `landcover` via `WORLDCOVER_RESISTANCE` (categorical `classify()`; assert every present class code has a value, no `NA` leak); apply the Sundarban water override (reserve `unit_id` 57 + 10 km ring → class 80 = 10); multiply by `1 + k × gHM`; cap at `RESIST_MAX`. Build the baseline (k = `RESIST_GHM_K`) and each entry of `RESIST_VARIANTS` with its own k | Land-cover × gHM layers on the 1 km grid for the baseline and each variant; all classes mapped; override cell count reported | 40–60 min |
| 9.6 | Add the Decision-15 road barrier: rasterise `ROAD_BARRIER_CLASSES` (`_link` → parent class) onto the grid with `touches = TRUE`; on road cells take `max(surface, road value)` — `ROAD_BARRIER_VALUE` (30) for the baseline and `noghm`, 15 / 50 for `road15` / `road50` | Combined surfaces for the baseline and 3 variants; road-cell count reported | 30–40 min |
| 9.7 | Write `resist_tiger_baseline_7755.tif` and the variants `resist_tiger_noghm_7755.tif`, `resist_tiger_road15_7755.tif`, `resist_tiger_road50_7755.tif` via `write_processed_rast` (`FLT4S`, read-back verified); assert grid match vs the stack (`compareGeom`) and a sane value range (min ≥ 1, finite max, no `NA` inside the complete-case footprint). *(Cells `NA` in the stack stay `NA` — 98 India-grid cells in the final `d13` stack — so "no `NA` inside India" cannot hold under Decision 10.)* | Resistance raster written; asserts pass | 20 min |
| 9.8 | QA: value distribution, per-class contribution, and a spot-check that known barriers (built-up, major roads, water) score high and tree cover scores low. Write `tbl_11_resistance_qa.csv` | QA table written; barrier/low-cost sanity holds | 30 min |
| 9.9 | Update `data-dictionary.md` (`resist_tiger_baseline_7755.tif` schema), `methodology.md` (the new numbered Decisions + Week-9 change log), `README.md`/handoff (Week 9 status, entry point for Week 10) | Docs match as-built | 20 min |
| 9.10 | Commit (`analysis:` for `07` + resistance/QA; `docs:` separate) | Committed and pushed | 10 min |

**Week 9 pitfalls:**
- **Decisions before the raster.** 9.2–9.4 are numbered Decisions and must be
  fixed **before** the resistance surface is written (pre-registration). Do not
  write `resist_*` then back-fill the rationale.
- **Read resistance values from config, never hardcode.** `scripts/07` must read
  `WORLDCOVER_RESISTANCE`; a literal lookup in the script would drift from the
  recorded Decision.
- **Categorical reclass, not interpolation.** Land cover → resistance is a
  `classify()`/lookup on class codes, never a bilinear/continuous op.
- **Assert no unmapped class.** If a WorldCover code present in the stack has no
  resistance value, the reclass leaks `NA` into the surface — assert every present
  code is covered before writing.
- **PROJ `proj.db` clash still applies.** Same machine trap — confirm
  `crs(rast(crs="EPSG:7755"))` prints the India NSF LCC WKT in a fresh session.
- **Keep the barrier road set separate from the 8.4 distance set.** 8.4 kept all
  major classes for a distance covariate; 9.4 is the independent barrier choice.

**Decisions due this week:** the land-cover **resistance values** (9.3) and the
**barrier road classes** (9.4), both numbered; plus the resolution of **Decision
10** (9.2 — gHM gap-fill applied as a new Decision, or closed as not-needed).

**Exit state:** `resist_tiger_baseline_7755.tif` written and QA'd on the 1 km
grid; the two connectivity Decisions recorded; Decision 10 resolved. Ready for
Week 10 least-cost paths. Docs updated; Week 9 ticked.
*(As built: ✅ — plus three variant surfaces and Decisions 11–16.)*

---

### Week 10 — task breakdown *(complete)*

Entry state (as of Week-9 close): four resistance surfaces on the 1 km EPSG:7755
grid in `data/processed/` — `resist_tiger_baseline_7755.tif` and the variants
`noghm` (k = 0), `road15`, `road50` (Decisions 14–16); values 1–100 on the
complete-case footprint, `NA` on every other cell — the 98 India cells that
Decision 10 dropped and every cell outside India. Reserve geometry for 55 of
58 reserves (`boundary_reserves_all_7755.gpkg`; Amrabad, Pilibhit and
Dholpur-Karauli have none). The 59 NTCA corridor polygons
(`boundary_corridors_7755.gpkg`). **Raised, not decided** (methodology →
Decisions pending → "[Week 10] Least-cost-path set-up"): reserve pairs, path
method and tool, geometry-absent reserves, variant comparison metric.
*(2026-10-01: Decision 17 recorded — pairs, method, start and end, Amrabad
split, network groups, NTCA comparison. After task 10.3b, 56 reserves have
geometry. Decision 18 recorded — variant comparison metric. 2026-10-02:
Decision 17 amended (contiguous = shared footprint cell); path engine
written.)*

Week 10 adds the least-cost-path (LCP) STEPs to `scripts/07_connectivity.R`: one
least-cost path for each pair of neighbouring reserves on the baseline surface,
then the same pairs on the three variants, compared by a metric fixed in
advance. Week 11 builds the reserve network graph from these paths; Week 12 finds
road pinch points on them.

Naming (naming-conventions §2/§6): paths `lcp_reserve_network_7755.gpkg` (one
layer per surface); pair list and QA tables `tbl_12_*` (a new group; `tbl_03` stays
reserved for the Week-12 network metrics).

| # | Task | Done when | Est. |
|---|---|---|---|
| 10.1 ✅ | **Set-up Decision (numbered — Decision 17), before any path.** Research, raise the forks, record the choices: (a) which reserve pairs are "neighbouring" (for example k nearest neighbours, a distance limit, or a Delaunay/Gabriel graph of reserve polygons); (b) path method and tool (`leastcostpath` or `gdistance`; 8 or 16 neighbours; cost = resistance × distance with diagonal correction); (c) where a path starts and ends (the polygon edge — nearest boundary cells — or a point); (d) the 3 geometry-absent reserves; (e) whether to compare baseline paths with the NTCA corridor polygons (descriptive only) | Decision 17 recorded in methodology; settings in `R/00_config.R` *(done 2026-10-01)* | 45–60 min |
| 10.2 ✅ | **Comparison-metric Decision (numbered — Decision 18), before any variant path is examined.** How a variant's path differs from the baseline's for the same pair: for example the share of baseline path length within 1 km of the variant path, the change in cost-distance rank across pairs, and the pairs whose route changes corridor. Fix the metric and what counts as a "material" change | Decision 18 recorded; settings in config *(done 2026-10-01: symmetric 5 km buffer overlap < 0.5, or percentile-rank change ≥ 0.25; label "robust" if ≤ 20 % material and ρ ≥ 0.9)* | 20–30 min |
| 10.3 ✅ | Tool check (Decision 17 points 3–5): add `gdistance` and `raster` (validation only) and lock them (`renv::snapshot()`); set the `required` list in `scripts/00a_setup_environment.R` — remove `leastcostpath` (listed from Week 0; doc fix pass 2026-09-27, F1-A). Build the 16-neighbour cell graph (crossed-cells knight rule) on the national baseline surface and smoke-test **one** baseline pair for runtime and peak memory | Packages locked; `00a` updated; one path runs; runtime per pair and peak memory known (the crop fallback applies only if memory fails) *(2026-10-02: engine `R/00_functions_lcp.R` written; checks (a)–(c) pass in a sandbox; a synthetic national-size graph — 3.06 M nodes, 16 neighbours — used 3.2 GB at peak, build 9 s, one search 11 s; `00a` list set from `renv::dependencies()`. Done on the project machine: `renv.lock` updated; STEP 10.0 — 3,067,467 nodes, 24,462,121 cell edges, build 8 s; Kanha → Pench one search 0.3 s, 422.6 resistance-km, 129.9 km; R heap 1.5 GB; no crop needed)* | 30–45 min |
| 10.3b ✅ | **Amrabad split (Decision 17 point 7, D1a).** `scripts/02`: split the Nagarjunsagar-Srisailam polygon at the state boundary per `BOUNDARY_STATE_SPLITS`; Amrabad gets geometry (`geometry_present = TRUE`; new `match_status` value for a split part). Re-run `scripts/02` and every Stage-1 script that reads the reserve geometry; re-render the Stage-1 maps; confirm that census and area values do not change. Correct the Decision-4 limitation text (the Week-3 "coarse envelope" cause) and the boundary-layer entry in `data-dictionary.md` (also: `unit_id` is stored as real; `area_provisional` stays `TRUE` in this layer — the Week-5 overwrite is in the stats layer). The split does not change the resistance surfaces, so a Week-9 re-run is not needed; if one is made (`RUN_RESISTANCE <- TRUE`), STEP 9.2 writes the gap table with the `_split` label (RS1) | 56 reserves with geometry; split areas 2,372.7 / 2,701.2 km²; Stage-1 tables unchanged except geometry fields; maps re-rendered *(done 2026-10-02: re-run 02 → 05; before/after check PASS — only units 1 and 51 changed, in the allowed fields; `fig_02` re-rendered; docs corrected)* | 45–60 min |
| 10.4 ✅ | STEP 10.1 in `scripts/07`: build the reserve pairs per Decision 17 points 1 and 8 → `tbl_12_reserve_pairs.csv` (pair id; from/to `unit_id`, name and `network_group`; `gap_km`; `contiguous`; `cross_group`). `contiguous` = the two reserves share a footprint cell (Decision 17 point 6, amended). Assert that `NETWORK_GROUPS` holds every `unit_id` once | Pair table written; every pair has two reserves with geometry; about 106 pairs expected (geometry check) — a large difference is investigated, not accepted *(done 2026-10-03: 106 pairs; 3 connected sets (34, 13, 9); 9 contiguous; 2 cross-group)* | 30–45 min |
| 10.5 ✅ | STEP 10.2: least-cost paths on the **baseline** for every pair, edge to edge → `lcp_reserve_network_7755.gpkg`, layer `baseline` (pair id, from/to, cost-distance in resistance-km, path length km, ratio path length / gap, `via_unit_ids`, `in_network` per Decision 17 point 2). Read the surface from disk; values from config | Baseline paths written; read back and checked *(done 2026-10-03: 97 paths, 9 contiguous, 0 no path; 21 pairs out of the network under point 2)* | 45–60 min |
| 10.5b ✅ | STEP 10.2b: validation per Decision 17 point 4 → `tbl_12_lcp_validation.csv` — (a) synthetic grid, hand-computed, 8 and 16 neighbours, with a one-cell barrier; (b) `terra::costDist` at 8 neighbours on 3 pairs (both runs with the source cells set to 0); (c) `gdistance` at 16 neighbours, end-cell mode, on the same 3 pairs | All checks pass (relative cost difference ≤ 1e-6) or the result is stated as not comparable with the reason; path overlap reported *(done 2026-10-03: 15 of 15 pass, largest difference 1.5e-15; V-add pair Bandhavgarh–Panna included)* | 45–60 min |
| 10.6 ✅ | STEP 10.3: path QA → `tbl_12_lcp_qa.csv` — every pair has a path or a stated reason (for example blocked by `NA` cells); an empty path only for a contiguous pair; paths lie inside the footprint; no path starts or ends in the wrong reserve; if the crop fallback is used, no path touches the window edge (re-run wider if it does) | QA table written; every pair accounted for *(done 2026-10-03: 106 of 106 pass every check)* | 30 min |
| 10.7 ✅ | STEP 10.4: the same pairs on `noghm`, `road15`, `road50` → layers in the same GeoPackage; apply the Decision-18 metric to every pair that is not contiguous → `tbl_12_lcp_variant_comparison.csv` (one row per pair and variant) and `tbl_12_lcp_variant_summary.csv` (one row per variant, with the label) | Variant paths written; both tables written by the pre-fixed metric; labels applied as fixed *(done 2026-10-03: QA 424 of 424 pass; gHM multiplier robust (0.186 material, ρ 0.985); road value robust (road15 0.113, road50 0.093))* | 40–60 min |
| 10.8 ✅ | STEP 10.5: descriptive overlap of baseline paths with the 59 NTCA corridor polygons (Decision 17 point 9) → `tbl_12_lcp_ntca_overlap.csv` (per pair) and `tbl_12_lcp_ntca_corridors.csv` (per corridor). Not a validation: the NTCA corridors come from a different method (Qureshi et al. 2014) | Overlap table written *(done 2026-10-03: median share 0.064; 31 of 59 corridors crossed)* | 20–30 min |
| 10.9 ✅ | Update `data-dictionary.md` (paths layer, `tbl_12_*`), `methodology.md` (Decision 18 + Week-10 change log), `naming-conventions.md` §6 (`tbl_12` group), `README.md`/handoff (Week 10 status, entry point for Week 11) | Docs match as-built *(done 2026-10-03)* | 20–30 min |
| 10.10 ✅ | Commit (`analysis:` for `07` + paths/QA tables; `docs:` separate) | Committed and pushed *(done 2026-10-03)* | 10 min |

**Week 10 pitfalls:**
- **Decisions before the paths.** Decisions 17 and 18 are fixed before any
  path is examined; Decision 18 before any **variant** path is run. Do not look
  at variant paths and then choose the metric.
- **Resistance vs conductance.** Our engine works in resistance
  (resistance-km). `gdistance` works in conductance (1 / resistance) with a
  geographic correction for step length. In the 10.5b check, convert before
  comparing costs.
- **Re-running `scripts/07` rewrites Week-9 outputs.** Decided (process
  choice RS1, 2026-10-02; raised 2026-09-27): `RUN_RESISTANCE <- FALSE` skips
  the Week-9 STEPs, and a guard checks the four surfaces on disk against
  `tbl_11_resistance_qa.csv`. With split parts in the reserve layer, STEP 9.2
  adds `_split` to its gap-table label, so no Week-9 table is overwritten.
- **`NA` cells are walls.** The 98 `NA` cells inside India (mostly water)
  cannot be crossed. A pair with no path must be reported, not silently dropped.
- **Paths cannot leave India.** The grid has a 5 km collar outside India, but
  the resistance surfaces are `NA` on every cell outside India, the collar
  included. Paths cannot go through Nepal, Bhutan, Bangladesh or Myanmar.
  Transboundary links (Valmiki–Chitwan, Manas–Royal Manas, the Sundarbans) are
  under-represented — record it as a limitation.
- **Cropping can cut off the true path.** If a pair is solved on a cropped
  window for speed, the window must be wide enough; a path that touches the
  crop edge must be re-run wider (task 10.6).
- **Polygon edge vs point.** Decided: edge to edge (Decision 17 point 6). The
  search starts from all cells of the source reserve at once, not from one
  point.
- **Knight steps jump one-cell barriers** unless they cost the cells they
  cross. The 10.5b synthetic test must include a one-cell road line.
- **Busy farmland is already ≥ 30.** In the baseline, 41.4 % of cells are at or
  above the road value, so paths through farmland may not avoid roads. Read the
  `noghm` comparison before interpreting the baseline routes.
- **Memory.** The graph has about 3.07 million nodes (footprint cells) and,
  with 16 neighbours, about 24 million edges. A synthetic graph of that size
  used 3.2 GB at peak in a sandbox (2026-10-02). On Windows, R reports only
  its own heap; read the process peak in Task Manager during STEP 10.0.
- **PROJ `proj.db` clash still applies** — fresh session.

**Decisions due this week:** **17** (LCP set-up) and **18** (variant comparison
metric), both numbered and both before the paths they govern.

**Exit state:** `lcp_reserve_network_7755.gpkg` with one layer per surface;
`tbl_12_reserve_pairs.csv`, `tbl_12_lcp_validation.csv`, `tbl_12_lcp_qa.csv`,
`tbl_12_lcp_variant_comparison.csv`, `tbl_12_lcp_variant_summary.csv`,
`tbl_12_lcp_ntca_overlap.csv` and `tbl_12_lcp_ntca_corridors.csv` written; every pair accounted for; 56 reserves with geometry. Ready for
Week 11 (network graph). Docs updated; Week 10 ticked.

### Week 11 — task breakdown *(complete)*

Entry state (as of Week-10 close, 2026-10-03): `lcp_reserve_network_7755.gpkg`
with layers `baseline`, `noghm`, `road15`, `road50` — 106 pairs each (97 paths,
9 contiguous, 0 with no path). On the baseline, 21 pairs are not in the network
(Decision 17 point 2, `in_network = FALSE`); on the variants 19 / 22 / 19. The
pairs (`tbl_12_reserve_pairs.csv`) form 3 connected sets (34, 13, 9 reserves);
56 reserves are network nodes (Pilibhit and Dholpur-Karauli have no geometry).
`NETWORK_GROUPS` labels each reserve (`northeast`, `western_ghats`, `north`,
`central`). Decision 18 labelled the gHM multiplier and the road value
**robust** for the paths. **Raised, not decided** (methodology → Decisions
pending → "[Week 11] Functional-link rule"): how a pair counts as a link, and
whether the network metrics are repeated on the variants.

Week 11 adds the network STEPs to `scripts/07_connectivity.R`: a link table
from the baseline paths, an `igraph` graph of 47 nodes (the 56 reserves, with
contiguous reserves merged into blocks — Decision 19 point 2), and per-reserve
metrics — betweenness (linchpin reserves) and components (isolated reserves).
Week 12 finds road pinch points on the paths and draws the network figure.

Naming (naming-conventions §2/§6): link and metric tables `tbl_13_*` (a new
group). `tbl_03` stays reserved for the Week-12 publishable network table. The
graph object is not written to disk; it is rebuilt from the paths layer on each
run.

| # | Task | Done when | Est. |
|---|---|---|---|
| 11.1 ✅ | **Functional-link Decision (numbered — Decision 19), before any network metric.** Research, raise the forks, record the choices: (a) which in-network pairs are links — all of them with the cost as the edge weight, or only those below a cost threshold (and from what evidence); (b) the edge weight (cost-distance, resistance-km) and the treatment of the 9 contiguous pairs (cost 0); (c) the metrics — degree, weighted betweenness (linchpins), components (isolated reserves) — and their normalisation across the 3 connected sets; (d) the definition of "isolated"; (e) whether the metrics are repeated on `noghm`, `road15`, `road50`, and if so the comparison metric, fixed now as Decision 18 did for the paths; (f) how the `network_group` labels enter (reporting only, Decision 17 point 8) | Decision 19 recorded in methodology; settings in `R/00_config.R` *(done 2026-10-03: a1 + a4, b1, c1 + k3, d2, e2, f2 — all in-network pairs are links, cost as the weight, no threshold; contiguous reserves merge, 56 reserves → 47 nodes; betweenness normalised by the node's own set; `linchpin` = top 3 in the set, `cut_node` next to it; `isolated` = degree 0, with `pendant` and the cheapest-link cost; a descriptive threshold scan; a second baseline run without cross-group links; variants repeated — "robust" if the sets are the same, ρ ≥ 0.9 and linchpin retention ≥ 2/3)* | 45–60 min |
| 11.2 ✅ | STEP 11.1 in `scripts/07`: the nodes (blocks of contiguous reserves, Decision 19 point 2); the link table from the `baseline` layer (`in_network == TRUE`, each pair with its `link_role` — Decision 19 point 3) → `tbl_13_network_links.csv`; the `igraph` graph (47 nodes from 56 reserves) | Link table written; 47 nodes, 56 reserves; every edge traces to one `pair_id` *(done 2026-10-04: new `R/00_functions_network.R`; 85 in-network pairs — 9 `block`, 0 `within_block`, 73 `edge`, 3 `parallel`; 47 nodes, 73 edges, no node without an edge; 3 sets of 33, 8 and 6 nodes, the same sets as all 106 pairs; 13 bridges; 44 edges in the minimum spanning forest; 10 of 10 construction checks pass)* | 30–45 min |
| 11.3 ✅ | STEP 11.2: per-reserve metrics per Decision 19 points 4–7 → `tbl_13_network_metrics.csv` (`unit_id`, name, `network_group`, node id and name, set id and size, degree, betweenness raw, normalised and rank, `linchpin`, `cut_node`, `isolated`, `pendant`, cheapest-link cost and rank); the second run without cross-group links (point 9; `_nocross` columns, `cross_group_dependent`); the threshold scan (point 8) → `tbl_13_network_threshold_scan.csv` | Metrics table written, one row per network reserve (56); scan table written, one row per baseline edge *(done 2026-10-04: the hand-computed self-test of Decision 19 point 11 runs at the start of this STEP, 17 of 17 cases; 8 linchpin nodes — set 1: Madhav, Guru Ghasidas-Tamor Pingla, Sanjay Dubri; set 2: the Bandipur block, Bhadra, Parambikulam + Anamalai; set 3: Pakke + Nameri, Orang; 12 cut nodes; no isolated node; 6 pendant nodes; second run: 1 cross-group link removed, sets of 29, 8, 6 and 4 nodes, Madhav is `cross_group_dependent`; Sariska has `betweenness_norm` 0.2258, the value from the pair layout; scan: 73 rows, 44 joining edges)* | 30–45 min |
| 11.4 ✅ | STEP 11.3 — **required (Decision 19 point 10)**: the same metrics on the three variant surfaces, compared by the pre-fixed metric (sets the same; Spearman ρ of normalised betweenness; linchpin retention) → `tbl_13_network_variant_comparison.csv`; `stable_linchpin` added to the metrics table | Comparison written by the fixed metric; labels applied as fixed *(done 2026-10-04: `noghm` — sets the same, ρ 0.941, 7 of 8 linchpins retained, robust; `road15` — sets the same, ρ 0.979, 8 of 8, robust; `road50` — sets the same, ρ 0.995, 7 of 8, robust. By the Decision-19 rule: gHM multiplier robust; road value robust. 7 stable linchpins; Sanjay Dubri is not stable — Pench (MH) is a linchpin in its place on `noghm` and `road50`. The metrics table has 7 more columns, 32 in all)* | 30–45 min |
| 11.5 ✅ | STEP 11.4: network QA (Decision 19 point 11) — no self-loops or duplicate edges; edge weights all above zero (none `NA`); each of the 56 network reserves in one node only; 47 nodes; set sizes add up to 47 nodes and 56 reserves; betweenness and the per-set normalisation checked on a small hand-computed graph | QA passes; any failure stops the script *(done 2026-10-04: the construction checks run in STEP 11.1 and, for each variant, in STEP 11.3; the hand-computed self-test runs in STEP 11.2; STEP 11.4 collects them and adds result checks — the flags, the betweenness identity from the shortest paths, the edge weights, the second run, the scan, the tables on disk — and writes `tbl_13_network_qa.csv` (process choice q1); 91 of 91 checks pass)* | 20–30 min |
| 11.6 ✅ | *(Optional, as done for the Week-10 extremes)* Literature check of the top-betweenness and the isolated reserves (descriptive) → `references.md` | Each named reserve has a source or a "no source found" note *(done 2026-10-04: 19 named nodes in a table, 11 new entries; three "no source found" notes — Madhav centrality, Orang–Dampa, a northern link of Nagarjunsagar-Srisailam + Amrabad; two data items kept as limitations, author choice g1 — Guru Ghasidas-Tamor Pingla and Sanjay Dubri are 1.59 km apart in the KML, BRT is 10.1 km from Sathyamangalam)* | 30–45 min |
| 11.7 ✅ | Update `data-dictionary.md` (`tbl_13_*`), `methodology.md` (Decision 19 + Week-11 change log), `naming-conventions.md` §6 (`tbl_13` group), `README.md`/handoff (Week 11 status, entry point for Week 12) | Docs match as-built *(done 2026-10-04: also the Limitations, a new pending item "[Week 12] Pinch-point rule", and `references.md`)* | 20–30 min |
| 11.8 ✅ | Commit (`analysis:` for `07`, config, functions; outputs; `docs:` separate; `docs: update handoff after Week 11` with the plan) | Committed and pushed *(done 2026-10-04)* | 10 min |

**Week 11 pitfalls:**
- **Decision 19 before any metric — and the path costs are already seen.** The
  Week-10 tables show the cost of every pair. A cost threshold chosen now is
  chosen after seeing those costs. Prefer a rule tied to outside evidence, or
  no threshold (cost as the weight), and state in Decision 19 that the cost
  distribution was seen.
- **Zero-cost links.** The 9 contiguous pairs have cost 0. `igraph` 1.6.0
  stops on a zero weight in `betweenness()` ("Weight vector must be positive";
  tested 2026-10-03 — check the project's version), and zero weights also make
  ties. Decision 19 point (b) fixes the treatment — for example, one merged
  node per contiguous pair, or a fixed small weight.
- **Weights are distances in `igraph`.** In `betweenness()` and `distances()`,
  a higher weight means a longer path. Use the cost-distance, not a
  conductance.
- **Three connected sets.** The pair rule gives sets of 34, 13 and 9 reserves.
  Raw betweenness is not comparable between sets of different size; Decision 19
  point (c) fixes the normalisation.
- **P3 removed 21 baseline links.** Use `in_network == TRUE` only. A reserve
  that lies between two others gains betweenness because of P3; say so when
  you name linchpins.
- **Missing nodes and borders.** Pilibhit and Dholpur-Karauli are not nodes
  (G1); Pilibhit lies between Dudhwa and Corbett. Transboundary links are
  absent, so a border reserve can look more isolated than it is (Limitations).
- **Cross-group links.** Sariska–Rajaji is in the network; Sariska–Corbett is
  not (P3). Whether `north` joins `central` depends on Decision 19 point (a).
- **PROJ `proj.db` clash still applies** — fresh session.

**Decision due this week:** **19** (functional links), numbered, before any
network metric. *(Recorded 2026-10-03.)*

**Exit state:** Decision 19 recorded; `tbl_13_network_links.csv`,
`tbl_13_network_metrics.csv`, `tbl_13_network_threshold_scan.csv`,
`tbl_13_network_variant_comparison.csv` and `tbl_13_network_qa.csv` written; network QA passes; linchpin
and isolated reserves named (or "no reserve is isolated by the rule", with the
pendant nodes); docs updated; Week 11 ticked. Ready for Week 12 (pinch points,
`fig_04`, the publishable `tbl_03`).

### Week 12 — task breakdown *(complete)*

Entry state (as of Week-11 close, 2026-10-04): the reserve network of Decision
19 — 47 nodes (56 reserves), 73 edges, 3 sets, 13 bridges
(`tbl_13_network_links.csv`); node metrics with the linchpin, cut-node, pendant
and cheapest-link columns, the second-run and variant flags
(`tbl_13_network_metrics.csv`); network QA 91 of 91. The paths are in
`lcp_reserve_network_7755.gpkg` (four layers, 106 pairs each; on the baseline
85 pairs are in the network, 76 of them with a path and 9 contiguous). The
road input of Decision 15 is `data/raw/osm/osm_roads_major_7755.gpkg`
(885,669 features; the barrier classes are motorway to secondary, with
`_link` merged into the parent class). **No road crossing is computed yet:**
the paths layer and the `tbl_12_*` / `tbl_13_*` tables hold no road field.
**Decision 20 recorded 2026-10-10** (task 12.1), before any road crossing;
the tasks below name its numbered points.

Week 12 adds the pinch-point STEPs to `scripts/07_connectivity.R`: the places
where the least-cost paths cross barrier roads, a rule that names pinch points
among them, the publishable network table and the network figure. Week 12
closes Stage 2 (proposal question 2).

Naming (naming-conventions §2/§6): working tables `tbl_14_*` (a new group, the
next free number); the publishable tables `tbl_03_<slug>.csv` (number reserved
since Week 10) and its companion `tbl_03b_<slug>.csv`; the figure
`fig_03_<slug>.png` (author choice 2026-10-10; the plan first named `fig_04`
— see the pitfalls).

**Size.** The estimates add up to about 5.5–7.7 hours (4.9–6.9 without the
optional task 12.9; task 12.5 is required since Decision 20), above one week
of 2–4 hours. A split point
is marked after task 12.6: crossings, pinch points and QA
first; the publishable table, the figure and the Stage-2 close second.

| # | Task | Done when | Est. |
|---|---|---|---|
| 12.1 ✅ | **Pinch-point Decision (numbered — Decision 20), before any road crossing is computed.** Research, raise the forks, record the choices: (a) the roads; (b) the paths; (c) what one crossing is, and how close crossings are merged; (d) what a pinch point is and how it is ranked, with no traffic data; (e) whether the crossings are repeated on the variant surfaces; (f) what the publishable `tbl_03` and the figure hold, and the position precision of a published crossing (sensitive-data policy §3); (g) a statement of what was seen before the Decision | Decision 20 recorded in methodology; settings in `R/00_config.R` *(done 2026-10-10: a1 + n1, b1 + k1, c1 + r1 + m1, d1 + t1, e2, p1 + q1 + g1 — the barrier-road cells of Decision 15, no road names; crossings for the 76 in-network paths, the rule counts the 73 edges, four links flagged; a crossing = one unbroken run of barrier-road cells in the cell list of a path, reserve cells counted and flagged; crossings at most 5 km apart = one site; `pinch_point` = `on_bridge` or `shared` (2 or more edges), three tiers, no order by road class; variants repeated — "robust" if the site overlap is ≥ 2/3; positions at a 10 km grid cell with state and district; `tbl_03` + `tbl_03b`; `fig_03`; a new rule in the policy §3. No crossing was seen; the network results were)* | 45–60 min |
| 12.2 ✅ | Process choices before code (not numbered): how the road layer is read (each run, or one interim barrier-road layer and a run switch); where the functions go; the `tbl_14_*` slugs. Then STEP 12.1 in `scripts/07`: the barrier roads for the crossing step, by the same class rule as STEP 9.6 and Decision 20 point 1, with a guard against `tbl_11_resistance_qa.csv` (`n_road_cells`) | Road input ready; the cell count agrees with the Week-9 surfaces *(done 2026-10-10: choices A2, B1, C1, L2 — an interim raster with the switch `RUN_ROAD_CELLS`; new `R/00_functions_pinch.R`; five `tbl_14` tables (`road_crossings`, `pinch_points`, `pinch_link_summary`, `pinch_variant_comparison`, `pinch_qa`), baseline rows only; `PINCH_LIT_FLAG_PAIRS` by `unit_id` with a names guard. STEP 12.1 on the project machine: 444,234 barrier-road features → **535,592 cells, the Week-9 count**; by highest class: motorway 9,240, trunk 155,723, primary 168,278, secondary 202,351; guard 6 of 6; `cov_roadbarrier_class_1km_7755.tif` written; 35 s. All four `lit_flag` links are bridges)* | 20–30 min |
| 12.3 ✅ | STEP 12.2: the crossings of the baseline paths per Decision 20 points 2–3 → `tbl_14_road_crossings.csv` (one row per crossing: `pair_id`, the two nodes, `link_role`, `is_bridge`, `lit_flag`, `n_cells`, `road_class_top`, `in_reserve_unit_ids`, position as a 10 km grid cell with state and district). The road layer has no name or reference field (n1). The 1 km cells go to a gitignored layer | Table written; each crossing traces to one `pair_id`; no 1 km position in the table *(done 2026-10-10: 76 paths (73 `edge`, 3 `parallel`); **556 crossings on 74 paths, 765 road cells**; cells per crossing median 1, maximum 7; by highest class motorway 10, trunk 234, primary 171, secondary 141; 122 crossings on the 13 bridge edges, 49 on the four `lit_flag` links; self-test 19 of 19; the cost from each cell list equals the engine cost on every path; the workspace build on the real files gave the same figures. Two paths have no crossing. Sariska–Rajaji has 35 crossings, 7 of them in Delhi. Outputs: `tbl_14_road_crossings.csv`; `lcp_road_crossings_7755.gpkg` (1 km cells, gitignored). District layer: `data/raw/administrative/`)* | 45–60 min |
| 12.4 ✅ | STEP 12.3: the sites (Decision 20 point 4) and the pinch-point rule (point 5) applied to the crossings; → `tbl_14_pinch_points.csv` (one row per site); the summary per link → `tbl_14_pinch_link_summary.csv` (choice C1; the counts per node go to `tbl_03`) | Tables written; flags and tiers applied as fixed *(done 2026-10-10: **365 sites; 200 pinch points — tier 1: 3, tier 2: 98, tier 3: 99**; `on_bridge` 101, `shared` 102; shortest gap between two sites 5.10 km; longest span 22.6 km (Sariska–Rajaji, Delhi); self-test 22 of 22; publish guard 8 of 8; the workspace build on the real files and a second method (`hclust()`) gave the same sites. The label separates little: 54.8 % of the sites are pinch points; tier 1 is three sites (two near Orang, one near Bhadra). `tbl_14_road_crossings.csv` is written again with `site_id`)* | 30–45 min |
| 12.5 ✅ | STEP 12.4 — **required (Decision 20 point 6)**: points 1–5 on `noghm`, `road15` and `road50`, each with its own paths, edges and bridges; compared with the baseline by the pre-fixed metric (site overlap at 5 km; robust if ≥ 2/3) → `tbl_14_pinch_variant_comparison.csv` | Comparison written by the fixed metric; labels applied as fixed *(done 2026-10-10: `noghm` — 496 crossings, 372 sites, 155 pinch points, site overlap **0.520, sensitive**; `road15` — 610, 383, 202, **0.866, robust**; `road50` — 546, 363, 192, **0.820, robust**. By the Decision-20 rule: **gHM multiplier — sensitive; road value — robust.** This is not the result that Decision 20 named as likely. 98 of the 200 baseline pinch points have a variant pinch point near them on all three variants. `tbl_14_pinch_points.csv` is written again with `near_pinch_<variant>` and `n_variants_near`; the variant crossing cells are in the gitignored 1 km file)* | 30–45 min |
| 12.6 ✅ | STEP 12.5: QA — the crossing and pinch-point functions on a hand-made case first (a known path, a known road, a known count); then each crossing lies on a path and on a barrier road; no crossing for a contiguous pair; counts per link add up to the table total → `tbl_14_pinch_qa.csv`; any failure stops the script | QA passes *(done 2026-10-10: **74 of 74 checks** — test cases 3 of 3 (52 hand-made cases), roads 6 of 6, baseline 15 of 15, each variant 12 of 12, all 14 of 14; `tbl_14_pinch_qa.csv` written; eleven planted faults each failed a check in the drafting chat)* | 20–30 min |
| — | **Split point** (if the week is over 4 hours): commit tasks 12.1–12.6; continue with 12.7 in the next session *(2026-10-10: reached after about 2 hours; the author chose to continue with task 12.7 in the same session)* | — | — |
| 12.7 ✅ | STEP 12.6: the publishable tables per Decision 20 point 7 — `tbl_03_<slug>.csv`, one row per reserve (56): the network results from `tbl_13_network_metrics.csv` (node, set, linchpin with its flags, cut node, pendant, cheapest link) and the pinch-point counts on the edges of the node, by tier; `tbl_03b_<slug>.csv`, one row per baseline pinch point. The publish check for the 10 km rule (sensitive-data policy §3) is written here | `tbl_03` and `tbl_03b` written; publish checks pass; no position finer than 10 km *(done 2026-10-10: `tbl_03_reserve_network.csv` — 56 reserves, 47 nodes, 42 nodes with a pinch point on an edge, 7 with a tier-1 pinch point; `tbl_03b_pinch_points.csv` — all 200 pinch points by tier (author choice); `assert_publishable_table()` in `R/00_functions_sensitive.R`; six planted faults each stopped the publish check in the drafting chat)* | 20–30 min |
| 12.8 ✅ | STEP 12.7: the network figure `fig_03_<slug>.png` per Decision 20 point 7 — nodes by flag, the 73 edge paths as modelled lines, bridges marked, pinch points at their 10 km cell by tier. The caption states that the paths are modelled and not observed movement, that the surface is India-only, what a pinch point is here, and the limits of the linchpin labels | Figure written; caption has the caveats; publish checks pass *(done 2026-10-10: `fig_03_reserve_network.png` — 47 nodes with 8 linchpins, 73 edge paths with 13 bridge links, 200 pinch points of all three tiers (author choice: tier 3 small and pale) in 194 cells of 10 km; 10 of 10 figure checks; the pinch points are read from `tbl_03b` only. **Title, subtitle and caption are draft text of the drafting chat; the author keeps the draft for now.** Seven build choices of the drafting chat are listed in the change log; the author keeps all seven, and the link line width of 0.3)* | 45–60 min |
| 12.9 ✅ | *(Optional, as done in Weeks 10 and 11)* Literature check of the named pinch points (documented road and corridor conflicts, mitigation structures) → `references.md` | Each named pinch point has a source or a "no source found" note *(done 2026-10-10: the road layer has no road names, so the check is by group — the 3 tier-1 pinch points, the tier-2 pinch points by bridge link, the 6 districts with 5 or more tier-3 pinch points — and at the level of link and district. Of 21 groups: 10 with a source for a road conflict in the same district or reserve, 5 with a source for the link or context only, 6 with no source. No source confirms a tier-1 pinch point. Two limits of the rule recorded for task 12.10. Sources are news reports; verify before citing)* | 30–45 min |
| 12.10 ✅ | Update `data-dictionary.md` (`tbl_14_*`, `tbl_03`, `tbl_03b`, `fig_03`, the gitignored crossings layer), `methodology.md` (Decision 20, Week-12 change log, Limitations, a Stage-2 summary against proposal question 2), `proposal.md` §8 if a stated choice changed, `naming-conventions.md` §6, `README.md`/handoff (Stage 2 complete; entry point for Week 13) | Docs match as-built *(done 2026-10-10: the note file `tbl_03_notes.md` — written by STEP 12.6, author choice — and its dictionary and naming entries; `methodology.md` status, the "Week 12 complete" entry with the Stage-2 summary against proposal question 2, ten new Limitations; `README.md`; `handoff.md` with the Week-13 entry point. `proposal.md` §8: no new entry — no stated choice changed)* | 30–45 min |
| 12.11 ✅ | Commit (`analysis:` for `07`, config, functions, outputs; `docs:` separate; `docs: update handoff after Week 12` with the plan) | Committed and pushed *(done 2026-10-10, by the author)* | 10 min |

**Week 12 pitfalls:**
- **Decision 20 before any crossing — and the network results are already
  seen.** The linchpins, the bridges and the path routes are known. No road
  crossing is. Fix the roads, the crossing rule and the pinch-point rule
  first, and say in the Decision what was seen.
- **A path is a line through 1 km cell centres.** A line-on-line intersection
  with an OSM road has an error of about 1 km, and a path that runs along a
  road can cross it many times. The engine saw the roads as cells
  (`touches = TRUE`). Define a crossing in the terms of the surface, or give
  the reason for a different rule.
- **Knight steps cross cells between two path vertices.** The cells that a
  16-neighbour step crosses are not all path vertices. Use the crossed-cells
  rule of the engine (`R/00_functions_lcp.R`) to list the cells of a path.
- **The road layer is large and STEP 9.6 does not run** (`RUN_RESISTANCE <-
  FALSE`). The crossing step needs its own road read; plan it (task 12.2).
- **No traffic data.** The Bay Area project had traffic counts; this project
  has the OSM road class only. Do not call a class a traffic volume.
- **Which paths.** 85 baseline pairs are in the network: 9 `block` (no path),
  73 `edge`, 3 `parallel`. The 21 pairs that P3 removed have paths too.
  Decision 20 point (b) fixes the set.
- **Links without literature support give crossings too** (Orang–Dampa,
  Anamalai–Srivilliputhur-Megamalai, Sariska–Rajaji; Limitations). Flag them
  in the tables; do not drop them without a rule.
- **Roads inside a reserve or a block are not counted.** The paths are edge
  to edge, and a contiguous pair has no path. Say so where pinch points are
  named.
- **Road variants.** `road15` and `road50` change the road value. Decision 18
  found the routes robust, but a crossing can move. Decision 20 point (e)
  fixes whether to test it.
- **Rows against nodes.** `tbl_13_network_metrics.csv` has 56 rows and 47
  nodes. Count and draw by `node_id`.
- **Publication.** The sensitive-data policy §3 allows no precise coordinate
  in a figure, table or caption. A crossing is a modelled path on a public
  road, not a tiger location. Decision 20 point 7 fixes the published
  position at a 10 km grid cell with state and district — in `tbl_14_*` too,
  because `outputs/tables/` is committed.
- **Numbers.** `tbl_03` is reserved for the publishable table; `tbl_03b` is
  its companion (naming §6). The figure is `fig_03` (author choice
  2026-10-10). `fig_04` is then the next free figure number, and the Week-16
  row names `fig_05` — confirm that number at Week 16.
- **PROJ `proj.db` clash still applies** — fresh session.

**Decision due this week:** **20** (pinch-point rule), numbered, before any
road crossing is computed. *(Recorded 2026-10-10.)*

**Exit state:** Decision 20 recorded; `tbl_14_road_crossings.csv`,
`tbl_14_pinch_points.csv`, `tbl_14_pinch_link_summary.csv`,
`tbl_14_pinch_variant_comparison.csv` and `tbl_14_pinch_qa.csv` written; `tbl_03_<slug>.csv`, `tbl_03b_<slug>.csv` and
`fig_03_<slug>.png` written and through the publish
checks; docs updated; Week 12 ticked; Stage 2 complete. Ready for Week 13
(Stage 3, habitat suitability).

---

## Stage 3 — Habitat suitability (Weeks 13–16) · priority 3

**Script note (2026-09-26):** the header-only stubs `08_habitat_suitability.R`
and `09_build_site.R` were deleted. Stage 3 starts a new script at the next free
number (`08`) in Week 13; the site-build script (Stage 4) takes the number after
that. Each is named (naming §3, `NN_verb_object.R`) when its stage starts.
*(2026-10-17: by process choice s1 of task 13.2 (2026-10-11), Week 13 is
`scripts/08_prepare_occurrences.R`, one script for Week 13 only. Week 14
starts a new script at the next free number and names it then (naming §3);
Week 14 also says whether Week 15 uses that script. The site-build script
takes a later number.)*

| Week | Focus | Exit state (deliverable) | Est. |
|---|---|---|---|
| **13** ✅ | Occurrence + effort | **Decisions 21–22** first; `scripts/08_prepare_occurrences.R` (new script, named in task 13.2, process choice s1) outputs: cleaned occurrences, target-group background, KDE (task breakdown below) *(done 2026-10-18: Decisions 21 and 22; STEPs 13.1–13.6; 300 clean tiger records, 23,901 clean background records; 11 surfaces; QA 171 of 171; eleven `tbl_15` tables; outcome of Decision 21 point 8: `no_1km_model`. Committed 2026-10-18 (task 13.10))* | 3–4 h planned; the task estimates add up to 4.6–6.3 h (split point after task 13.4). *(Ran on 2026-10-11, 2026-10-17 and 2026-10-18; no time recorded per task)* |
| **14** ✅ | SDM fit | A new script, named in Week 14 (process choice s1 of task 13.2: `scripts/08` holds Week 13 only): `maxnet` fitted with bias correction; model saved. *(2026-10-11: by Decision 21 point 8, the week starts with the outcome of the presence-cell count — no 1 km model, a reduced model, or the planned model — and the Decisions that follow from it.)* *(2026-10-18: the outcome is `no_1km_model`. Task breakdown below: **Decision 23** first picks branch A (no suitability model; Week 14 builds the effort result) or branch B (a model at a coarser grain; Week 14 fits it). The focus "SDM fit" applies to branch B only)* *(2026-10-25: Decision 23 picks **branch B** — a `maxnet` model on the obscured iNaturalist set at the 0.2° grain (a2, b3). Task 14.4 counts the presence and background cells; below the limits of Decision 23 points 4 and 6 there is no model, and the week gives the effort result)* *(2026-10-25: task 14.4 gives `planned_model` — 104 presence cells, 1,486 background cells. A model is fitted; Weeks 15–16 predict and show it at 0.2°)* *(done 2026-10-25: Decisions 23 and 24; `scripts/09_model_suitability.R` STEPs 14.1–14.3; 6 of 9 covariates kept; `lq`, multiplier 1; mean test Boyce 0.668 over 5 spatial folds; both sensitivity runs robust; the model file under `data/processed/`; QA 133 of 133; seven `tbl_16` tables. Commit (task 14.8) by the author before the Week-15 chat)* | 3–4 h *(2026-10-18: the task estimates add up to 4.1–5.7 h for branch A and 4.3–5.9 h for branch B; split point after task 14.3)* *(2026-10-25: branch B, plus about 15–30 min for the new background output and the 0.2° cells; estimate)* |
| **15** ✅ | Predict + validate | **Decision 25** first (the prediction: the model file, the output type and clamping, the cells, the published form and classes, the sensitive-data check of the surface, the caption content), before any prediction file is written; then the prediction of the main model over the 6,969 model cells (`scripts/09`), the gate of Decision 24 point 8 (the mean test Boyce index is 0.668, so the gate allows a map), the reserve check of point 9 (the Spearman ρ of the reserve value and `density_2022`; the reserves with no presence cell, counts only) and the QA (task breakdown below) *(written again 2026-10-25, task 14.7; the earlier dated notes said that the week depends on Decisions 23 and 24, which are now made)* *(2026-10-31: tasks 15.1–15.2 done — Decision 25 with point 9, and the process choices)* *(2026-11-01: task 15.3 done — the prediction and the gate (open); task 15.4 done — r1 "agrees", r2 not published, z1 0; task 15.5 done — QA 84 of 84)* *(done 2026-11-01: Decision 25; `scripts/09` STEPs 15.1–15.3; the prediction of 6,969 model cells; `tbl_17_reserve_suitability.csv`; QA 84 of 84; the docs and the Week-16 breakdown (task 15.6). Commit (task 15.7) by the author)* | 3–4 h planned; the task estimates add up to 3.2–4.7 h (split point after task 15.2) |
| **16** | SDM visuals + Gi* | **Decision 26** (the Gi* settings; pending item "[Week 15–16] Gi* settings") before any Gi* is computed; the Gi* of the effort and of the tiger records in the Phase-1 form (the tiger Gi* is never published or committed); the suitability figure in the form that Decision 25 fixes, with the effort caveat (proposal §7). `fig_04` is the next free figure number (the earlier row named `fig_05`). Task breakdown written in Week 15 *(written again 2026-10-25, task 14.7; the draft puts the Gi* Decision in Week 16, not Week 15)* *(2026-11-01: the task breakdown is written below — Decision 26, the process choices, the Gi*, the two figures, the QA, the docs (the Stage-3 close), the commit; estimates 3.4–4.9 h)* *(2026-10-31, Decision 25 f3: **two** suitability figures — `fig_04` (the five classes by rank) and `fig_05` (the cloglog value, with the legend label "model output (cloglog), relative; not a probability of presence"); the hatch of the cells outside the training range on both; the nine caption items of Decision 25 point 5, drafted and marked as drafts; the check that the figure code reads only the prediction layer and the grid layer, written with the figures. A slug does not hold "tiger")* *(2026-11-07: task 16.1 done — Decision 26: four Gi\* (`effort_inat` with `tiger_obscured`, `effort_all` with `tiger_5km`) on the 0.2° model cells, value 0/1, a 50 km band, the exact p, Benjamini–Hochberg; `fig_06` (the `effort_inat` Gi\*) is a third figure; the tiger Gi\* never published)* *(2026-11-07: task 16.2 done — the process choices; Amendment 1 of Decision 26: the distance between cells on the sphere)* | 2–3 h planned; probably 3–4 h with the Gi* (estimate) *(2026-11-07: about 4.2–6.2 h with Decision 26; estimate)* |

**Pending, not yet scheduled (raised with Decision 14):** after the SDM exists,
an SDM-based resistance surface (1 − suitability) and a circuit-theory run
between reserves, to reproduce the national method and check the Stage-2 paths.
Transform and tool are decided then (see `methodology.md`, Decisions pending).
*(2026-10-18: this item needs a suitability surface. Decision 23 decides
whether one is made, and at which grain.)* *(2026-10-25: Decision 23 — a
surface at 0.2° (about 20 km), if task 14.4 allows a model. A resistance
surface from it would have that grain; decide then whether the item still
applies.)*

### Week 13 — task breakdown *(complete)*

*(Written 2026-10-10, after the Week-12 push.)*

Entry state (as of Week-12 close, 2026-10-10): Stage 2 is complete and
pushed. Stage 3 reads none of its outputs. On disk from Week 2
(`scripts/01`), all gitignored:

- `data/interim/occ_tiger_gbif_raw_7755.gpkg` — 4,606 GBIF tiger records
  inside India (DOI 10.15468/dl.npxmxx). Median coordinate uncertainty about
  30 km. Year span 1840–2026.
- `data/interim/effort_background_tgs_7755.gpkg` — 39,057 GBIF Mammalia
  records inside India, tiger excluded, 2006–2022 (Decision 5; DOI
  10.15468/dl.2d523e).
- `osm_settlements_7755.gpkg` — 199,800 settlement points (city 495, town
  4,102, village 195,203). Folder not verified for this plan; the OSM roads
  are in `data/raw/osm/`. *(2026-10-17: verified in `scripts/01` Block 6:
  `data/raw/osm/osm_settlements_7755.gpkg`.)*
- `data/processed/cov_stack_1km_7755.tif` — 6 bands on the 1 km grid, with the
  common NA mask (Decision 10).

**No cleaned count is known.** What is already seen: the two raw counts, the
median uncertainty, the year span, and the Phase-1 result (about 116 clean
baseline points for 7 reserves).

Week 13 starts Stage 3 with a new script, `scripts/08_<verb_object>.R`
(named in task 13.2; naming §3). It cleans the tiger records and the
target-group background by one rule, counts what each rule step removes, and
builds the effort surface. Week 14 fits the SDM on these outputs.
*(2026-10-17: the script is `scripts/08_prepare_occurrences.R`. The outcome
of Decision 21 point 8 is `no_1km_model`, so Week 14 starts with a Decision
between no model and a model at a coarser grain; an SDM is fitted only if
the second is chosen.)*

Naming (naming-conventions §2/§6): layers `occ_tiger_gbif_clean_7755.gpkg`
(the dictionary has a placeholder entry) and
`effort_background_tgs_clean_7755.gpkg`; density surfaces `kde_<what>_1km_7755.tif`;
working tables `tbl_15_*` (a new group; 15 is the next number after
`tbl_14` — confirm it against a listing of `outputs/tables/`).

**Size.** The estimates add up to about 4.6–6.3 hours (4.3–5.9 without the
optional task 13.8), above one week of 2–4 hours. A split point is marked
after task 13.4: the two cleaned sets and the counts first; the effort
Decision, the density surfaces, QA and the docs second.

| # | Task | Done when | Est. |
|---|---|---|---|
| 13.1 ✅ | **Occurrence-cleaning Decision (numbered — Decision 21), before any cleaned count is seen.** Research, raise the forks, record the choices: (a) the coordinate-uncertainty limit, and what to do with a record that has no uncertainty value; (b) the year window for the tiger records (the background is 2006–2022; the tiger pull is 1840–2026); (c) the record types to remove — captive and zoo records, museum specimens, fossil records, records at a country, state or institution centroid, records with zero or equal coordinates; (d) obscured records (policy tier T1): keep, or remove because the position is not good to 1 km; (e) duplicates and thinning — one record per 1 km cell, per cell and year, or none; (f) records on a cell with no covariate value (the common NA mask) or outside India; (g) whether the background takes the same rule in each point — the target-group method needs the same bias in the two sets; (h) a minimum number of clean presence cells below which the Week-14 plan changes, fixed now; (i) what was seen (the entry state above). Also the tool: base `sf`/`dplyr` rules, or the `CoordinateCleaner` package (a new dependency) | Decision 21 recorded in `methodology.md` with the date, the choices, the judgement values and what was seen; the pending item closed; `OCC_*` settings in `R/00_config.R`. No record is cleaned and no count is made before it *(done 2026-10-11: Decision 21 recorded — forks a3, n1, b1, c1, z2, o2, e1, g3, h2, k2; no `CoordinateCleaner`; no record cleaned and no count made. c1 became c2 by Amendment 1 of the same day, after the names stage of task 13.2 and before any count)* | 45–60 min |
| 13.2 ✅ | Process choices before code (not numbered): the script name; one script for all of Stage 3 with one STEP block per task (as `scripts/07`), or one script per week; a function file (`R/00_functions_occ.R`); the `tbl_15_*` slugs; any new package (`renv::snapshot()`, and the `scripts/00a` list); whether a data file goes to the chat for tests (the records are public GBIF data, but they hold precise tiger positions — decide it, do not default). Then the script header, the guards (inputs present, CRS 7755, PROJ check) and STEP 13.1: read the two raw layers, list the fields, and count the records by each field that Decision 21 uses — **counts of the raw state only** | Header and guards run; the raw field list and the raw counts are in the console; the fields that Decision 21 names are all present, or the Decision is amended with a dated note before any record is removed *(done 2026-10-11: process choices s1, f1, g1, t1, p1, q1, d1; `scripts/08_prepare_occurrences.R` and `R/00_functions_occ.R`; names stage, then Decision 21 Amendment 1 (c2, y1); counts stage — guards pass (tiger 4,606 by `gbifID`, background 39,057), `tbl_15_occ_raw_counts.csv` 165 rows; then Amendment 2 (v1))* | 30–45 min |
| 13.3 ✅ | STEP 13.2: apply Decision 21 to the tiger records, one rule step at a time, in the fixed order → `data/processed/occ_tiger_gbif_clean_7755.gpkg` (gitignored) and the attrition table `tbl_15_occ_cleaning.csv` (one row per rule step and set: records in, removed, out — **no coordinate**) | Clean layer written and read back; the attrition rows add up to the raw count; the minimum of point (h) is compared with the result and the outcome is stated *(done 2026-10-17: zoo block of `scripts/01` (154 features); process choices w1, s1, b1; first run stopped at the dataset check, author choice k1; second run: 300 records kept (1 km set 45 records in 17 cells; 5 km set 300 in 44; obscured set 884 in 104 cells of 0.2°); layers read back; `tbl_15_occ_cleaning`, `_by_dataset`, `_sets`, `_dataset_check` written; **point 8: `no_1km_model`**)* | 30–45 min |
| 13.4 ✅ | STEP 13.3: the same rule on the background → `data/processed/effort_background_tgs_clean_7755.gpkg` (gitignored), rows added to `tbl_15_occ_cleaning.csv`; a tally of the clean background by order and family → `tbl_15_background_taxa.csv` (the evidence for the pending Decision "target-group scope") | Clean background written; attrition adds up; the taxa table written; the target-group scope is decided now or the reason to wait for Week 14 is recorded *(done 2026-10-17: process choices d1, t1, r1; first run stopped at the dataset check on five background datasets, author choice e1; second run: 23,901 background records kept (1 km 20,905 in 4,554 cells; matched 1 km 6,082 in 417 cells); background layer read back; the four `tbl_15` tables with both sets; `tbl_15_background_taxa.csv` (46 rows); target-group scope carried to Week 14, author choice g1)* | 30 min |
| — | **Split point** (if the week is over 4 hours): commit tasks 13.1–13.4; continue with 13.5 in the next session *(2026-10-17: reached; tasks 13.1–13.4 took two sessions, 2026-10-11 and 2026-10-17; commit, then task 13.5 in the next session)* | — | — |
| 13.5 ✅ | **Effort-surface Decision (numbered — Decision 22), before any density surface is seen.** It closes the pending item "Settlement layer for the KDE". Record: (a) which surfaces Week 13 builds — background effort, tiger records, settlements — and what each is for (a description of effort, a bias input for the SDM, a covariate); (b) the settlement classes (all, or city and town only); (c) the kernel and the radius — the config has `KDE_RADIUS_M` 20 km with a 10/20/30 km test, and the pending item says 15 km: one of the two is wrong; (d) the time windows (`BASELINE_WINDOW` 2006–2010 and `CURRENT_WINDOW` 2018–2022 are in the config; the census baseline is 2014); (e) the edge rule at the coast and the border; (f) Getis-Ord Gi* — `methodology.md` §5.5 names it and no week of Stage 3 holds it: Week 13, a later week, or not built; (g) the published form of a tiger-record surface (see the pitfalls); (h) what was seen — the cleaned counts of tasks 13.3–13.4 | Decision 22 recorded before STEP 13.4 runs; the pending item closed; `KDE_*` settings corrected in `R/00_config.R` *(done 2026-10-17: author choices a2, p1, u2, b2, c2, d3, e2, f2, g1 — three surfaces (effort, tiger, city/town), the 5 km sets, one unit per 1 km cell, quartic 20 km with 10/30 km QA surfaces, counts by window and two effort window surfaces (100 units or more), uniform edge correction, Gi* to the Week-14 Decision, no published tiger surface; new `KDE_*` block in the config; the settlement item closed. Point (c): the 15 km and the 20 km were both correct, for two different surfaces)* | 30–45 min |
| 13.6 ✅ | STEP 13.4: the density surfaces per Decision 22 on the 1 km template → `data/processed/kde_<what>_1km_7755.tif` (through `write_processed_rast()`, read back) | Surfaces written; each has the grid of the covariate stack (`compareGeom`); value range and sum reported *(2026-10-17, Decision 22: three surfaces at 20 km, the same three at 10 and 30 km for the QA only, the effort surfaces of 2006–2010 and 2018–2022 if each has 100 units or more, and the counts by window in one `tbl_15` table. Process choices first: the tool, the file names, where the QA surfaces are kept, the table slug, any new package. More surfaces than the plan of 2026-10-10: the estimate is probably low)* *(done 2026-10-18: process choices t1, k2, n1, q2, s1, r1, h1, v1; new `R/00_functions_kde.R`; `scripts/08` STEP 13.4 and the switch `RUN_CLEANING`; run with `RUN_CLEANING = FALSE`: hand-made case 16 of 16, guard passed, 11 surfaces written and read back (both effort window surfaces built: 623 and 3,569 units), `tbl_15_occ_window_counts.csv` and `tbl_15_kde_summary.csv` written; 6.3 min)* | 30–45 min |
| 13.7 ✅ | STEP 13.5: QA — the cleaning functions on a hand-made case first (known records, a known count at each rule step); then: no clean record outside the complete-case footprint; no clean record fails a rule of Decision 21; the thinning rule holds (count per cell); the attrition adds up on disk; the tiger and background sets went through the same steps; each surface has the template grid and no value below zero; the publish checks (`assert_publishable_rast()`, `assert_no_raw_points()`, no coordinate column in a `tbl_15` table) → `tbl_15_occ_qa.csv`; any failure stops the script | QA passes *(2026-10-17, Decision 22 "Consequences": a hand-made case for the kernel and the edge rule first; unit counts; the count of cells with an edge mass below 0.5; the QA-radius numbers; no tiger surface under `outputs/`)* *(done 2026-10-18: process choices c1, h1, x1, t1, s2, p1; `occ_self_test()`, `kde_direct_check()`, the switch `RUN_SURFACES`; run with `RUN_CLEANING = FALSE` and `RUN_SURFACES = FALSE`: 171 of 171 checks pass; `tbl_15_occ_qa.csv` (171 rows) and `tbl_15_kde_radius_compare.csv` (6 rows))* | 20–30 min |
| 13.8 ✅ | *(Optional)* Clean tiger records per reserve (count inside the reserve polygon, by `unit_id`) → `tbl_15_occ_by_reserve.csv`, with `warn_small_n()`; an input to the Week-15 validation and to the effort text | Table written; reserves with no clean record counted; small counts handled by the policy *(2026-10-17, Decision 22 point 9: this table is the only published tiger product of Week 13; a count of 1 or 2 is given as "fewer than 3". Still optional)* *(done 2026-10-18: process choices s1, r1, p1, w1, x1, and o1 after the first run stopped on 13 background records in two overlapping reserve polygons (6 pairs of polygons overlap, 20.7 km²); STEP 13.6; `tbl_15_occ_by_reserve.csv`, 58 rows)* | 20 min |
| 13.9 ✅ | Update `data-dictionary.md` (the two clean layers, the surfaces, `tbl_15_*`), `methodology.md` (Decisions 21–22, Week-13 change log, Limitations), `data-sources.md` (the cleaning note of the GBIF entries), `naming-conventions.md` §6, `README.md`/handoff (Week 13 status; entry point for Week 14) | Docs match as-built *(done 2026-10-18: most docs were updated task by task. This task added 13 Week-13 items to "Limitations" in `methodology.md`, the status lines, a change-log entry, a dated note on the Week-14 model item, the Week-13 close of the handoff and `README.md` (with the Stack row: no `spatstat`), one example name of naming §2 as built, and the Week-14 task breakdown below. `proposal.md` §8 waits for Decision 23. The two checks that need a listing of `outputs/tables/` go to task 13.10)* | 30–45 min |
| 13.10 ✅ | Commit (`analysis:` for `08`, config, functions, outputs; `docs:` separate; `docs: update handoff after Week 13` with the plan) | Committed and pushed; `git status --short` shows no point layer staged *(2026-10-18: also no tiger surface (`kde_tiger_*`) and no file of exact tiger counts staged; `diag_reserve_overlap.R` is not committed. After the push, run `list.files("outputs/tables")` and send the list (file names only): it closes two open checks — naming §6 against the files, and the stale `tbl_05_census_wide_check.csv` (to delete since Week 6))* *(done 2026-10-18: committed, as the author reported. The listing has 53 files and matches naming §6 in both directions; `tbl_05_census_wide_check.csv` is not on disk; `tbl_16` is free)* | 10 min |

**Changes from Decision 21 (2026-10-11).** The task table above is the plan
of 2026-10-10. Decision 21 changes these tasks:

- **13.2 (STEP 13.1):** the raw state comes from the two GBIF zip files
  (`data/raw/gbif/`, `data/raw/gbif_background/`), not only from the interim
  layers. The interim layers do not hold the rule fields; they are the guard
  for the entry state (Decision 21 point 1). The step also reads the header
  line of each file and lists the `issue` flag names with their counts. One
  more process choice: the file name of the obscured set.
- **13.3 (STEP 13.2):** one more input — the OpenStreetMap zoo features, from
  one more read of the cached Geofabrik file (the road and settlement reads
  of Week 2 were slow). One more output — the obscured set. The clean layer
  holds `uncert_set` (`1km`, `5km`). The count `n_cells_1km` is compared
  with 25 and 80, and the outcome of Decision 21 point 8 is stated.
- **13.4 (STEP 13.3):** the background comes from the zip file. Three
  background sets: 1 km, 5 km, and matched 1 km (`ds_match`). The obscured
  rule gives a count only.
- **13.7:** the QA list of Decision 21 ("Consequences") is added to the
  list of the task.
- **13.3, by Amendment 2 (2026-10-11):** a check of the GBIF description of
  each dataset that gives a record to the 1 km or the 5 km set; a hit stops
  the script before the clean layers are written. The word list and the
  record of a decision are process choices of the task.
- **Estimates (not measured):** about 45 to 60 minutes more for tasks 13.2
  to 13.4. The split point after task 13.4 is the probable end of the first
  session.

**Week 13 pitfalls:**
- **Decision 21 before any cleaned count — and some figures are already
  seen.** The raw counts, the 30 km median uncertainty and the Phase-1 result
  are known. Say so in the Decision, and set the limits from the grid, the
  literature and the use (a 1 km SDM), not from the result.
- **A precise tiger record is sensitive (policy tier T2).** The clean point
  layers stay under `data/` (gitignored). A `tbl_15` table holds counts, never
  a coordinate. The console text that goes to a chat holds counts, never a
  coordinate. Check `git status --short` before each commit.
- **A density surface of few points can show a position.** A kernel peak of
  one isolated record is at that record. The ≥ 1 km rule of the policy does
  not prevent this. Decision 22 point (g) fixes the published form; use
  `warn_small_n()`.
- **A missing uncertainty value is not a precise record.** Count the `NA`
  values first; Decision 21 point (a) gives the rule.
- **Obscured records are probably the cause of the 30 km median** (not
  verified). They are tier T1, and they cannot place a record in a 1 km cell.
- **Captive animals and museum specimens.** A zoo record is a true record of
  a tiger and a false record of habitat. Check the record-type fields before
  the rule is written (task 13.2 lists the fields).
- **One rule for the two sets.** If the tiger records are thinned or limited
  by uncertainty and the background is not, the background no longer has the
  bias of the tiger records (Decision 5).
- **The year windows do not match.** The tiger pull has records from 1840;
  the background starts in 2006. `BASELINE_YEAR` and `CURRENT_YEAR` in the
  config are the download bounds, not the census baseline (handoff gotcha).
- **Expect a small clean set.** Phase 1 kept about 116 points. A small set
  limits the SDM; the plan's risk table has "SDM adds little" with the
  response "drop it". Decision 21 point (h) makes that a rule before the
  count is seen.
- **Records on cells with no covariate value.** The stack has `NA` on 98
  cells inside India and on each cell outside it. A record there cannot go
  into the model.
- **"In a reserve" is by the KML polygon.** The polygons are national-park
  and sanctuary outlines (polygon/census ratio median 0.515), so a record in
  a buffer zone is "outside". This affects task 13.8 and the Week-15
  validation. Join by `unit_id`; `unit_name` is not a unique key.
- **A KDE over India needs a plan for the window and the run time.** *(2026-10-17:
  Decision 22 fixes the window — the complete-case cells — and the kernel;
  the tool is a process choice of task 13.6.)* A
  `spatstat` window from the national polygon on a 3093 × 2864 grid is large;
  a raster method on the template can be the better tool. Decide in task
  13.5 and test on a small area first.
- **`scripts/07` is not changed.** Stage 3 is a new script. The stubs of the
  old numbering were deleted in Week 9.
- **Numbers.** `tbl_15` is the next table group. `fig_04` is the next free
  figure number, and the Week-16 row names `fig_05` — confirm at Week 16.
- **PROJ `proj.db` clash still applies** — fresh session.

**Decisions due this week:** **21** (occurrence cleaning), before any cleaned
count; **22** (effort surfaces; closes the pending settlement item), before
any density surface. The pending item "target-group scope" is decided in
task 13.4 or carried to Week 14 with a recorded reason.

**Exit state:** Decisions 21 and 22 recorded; `occ_tiger_gbif_clean_7755.gpkg`
and `effort_background_tgs_clean_7755.gpkg` written (gitignored);
`tbl_15_occ_cleaning.csv`, `tbl_15_background_taxa.csv` and
`tbl_15_occ_qa.csv` written with no coordinate; the density surfaces of
Decision 22 written and through the publish check; the minimum of Decision
21 point (h) compared with the result; docs updated; Week 13 ticked. Ready
for Week 14 (SDM fit). *(2026-10-17: with the outcome `no_1km_model`, ready
for the Week-14 model Decision.)* *(2026-10-18: reached; committed in task
13.10. Decisions 21 and 22 recorded; the three clean point layers
and the 11 surfaces on disk (gitignored); eleven `tbl_15` tables with no
coordinate; QA 171 of 171; the minimum of point (h) compared — 17 cells,
`no_1km_model`; docs updated. Week 13 ran on 2026-10-11, 2026-10-17 and
2026-10-18; no time was recorded per task.)*

### Week 14 — task breakdown *(complete)*

*(Written 2026-10-18 at the Week-13 close (task 13.9), before the Week-13
commit. This is a plan. It makes no Decision: Decisions 23 and 24 are the
author's, in Week 14.)*

Entry state (as of the Week-13 close, 2026-10-18): Week 13 is complete and
committed (task 13.10). On disk from Week 13
(`scripts/08`), all gitignored:

- `data/processed/occ_tiger_gbif_clean_7755.gpkg` — 300 clean tiger
  records with `uncert_set` and `cell_1km`. The 1 km set: 45 records in 17
  cells. The 5 km set: 300 records in 44 cells. Precise positions (tier
  T2).
- `data/processed/occ_tiger_gbif_obscured_7755.gpkg` — 884 iNaturalist
  records in 104 cells of 0.2° (tier T1).
- `data/processed/effort_background_tgs_clean_7755.gpkg` — 23,901 clean
  background records: 1 km background 20,905 records in 4,554 cells; 5 km
  background 23,901 records in 5,512 cells; matched 1 km background 6,082
  records in 417 cells.
- `data/processed/kde_*_1km_7755.tif` — the five 20 km surfaces of Decision
  22: effort, tiger (never published, never committed), settlement, and
  the effort surfaces of 2006–2010 and 2018–2022.
- `data/processed/cov_stack_1km_7755.tif` — 6 bands, common NA mask
  (Decision 10); 3,067,467 complete-case cells.

Committed: the eleven `tbl_15_*` tables (counts, names and statistics
only).

**Seen at the Week-13 close.** Each count of the `tbl_15` tables: the
cleaning steps, the sets, the datasets, the taxa, the counts by window, the
surface summaries, the QA-radius values and the counts per reserve. **Not
computed:** a count of presence cells at a grain coarser than 1 km, a
model, a Gi* value, a ratio. Decision 23 states this list again, and says
whether the author has looked at a surface or a point layer on a map.

**The outcome that Week 14 starts from.** Decision 21 point 8 gave
`no_1km_model` (17 cells, below 25). By point 8, Week 14 starts with a
numbered Decision between (i) no suitability model — Stage 3 gives the
effort result — and (ii) a model at a coarser grain, with the 5 km set and
the obscured set as the inputs that it can use. A 1 km model on the 5 km
set is not an option. The model sets of Decision 21 point 9 (`main`,
`uncert5km`, `matched`) are not run.

**Two branches.** Task 14.1 (Decision 23) picks one. **Branch A** is (i),
**branch B** is (ii). Tasks 14.1, 14.2 and 14.6 to 14.8 are the same in
the two branches; tasks 14.3 to 14.5 are not. After Decision 23, the
parts of the other branch get a dated note "not used".

**Script.** Week 14 starts a new script at the next free number,
`scripts/09_<verb_object>.R` (naming §3), named in task 14.2. `scripts/08`
does not change, unless Decision 23 needs a new output from it (see the
pitfalls: the obscured set has no background).

**Size.** The estimates add up to about 4.1–5.7 hours for branch A and
4.3–5.9 hours for branch B (estimates, not measured), above one week of
2–4 hours. Week 13 kept no time per task. A split point is marked after
task 14.3: the two Decisions and the process choices first (no result);
the STEPs, the QA and the docs second.

| # | Task | Done when | Est. |
|---|---|---|---|
| 14.1 ✅ | **Model Decision (numbered — Decision 23), before any count at a coarser grain is made.** Research, raise the forks, record the choices: (a) (i) no suitability model — Stage 3 gives the effort result (proposal question 4), and question 3 gets no model answer (success criterion "All three tracks completed at a level the data supports") — or (ii) a model at a coarser grain; (b) for (ii): the grain and the input set — the 5 km set on a grid of 5 km or coarser (for example the 10 km publication grid, `PINCH_PUBLISH_GRID_M`), the obscured set on its 0.2° cells, or both as two models; and whether the coarse grid is an aggregate of the 1 km template; (c) for (ii): the minimum number of presence cells at that grain and what happens below it, fixed before the count (on a grid that is an aggregate of the 1 km template, the 5 km set has 44 cells or fewer); (d) for (ii): the background at that grain — the target-group scope (pending item; `tbl_15_background_taxa.csv`), a minimum size of a background set (pending item, point 3), and a background for the obscured set (see the pitfalls); (e) for (ii): a run without the Facebook dataset (273 of the 300 records of the 5 km set) — needed or not; (f) for both: Gi* and the ratio of the tiger and effort surfaces (pending points 6 and 7) — built or not, and in which week; their settings go into a later numbered Decision; (g) what was seen (the entry state above; the facts of the pitfalls below) | Decision 23 recorded in `methodology.md` with the date, the choices, the judgement values and what was seen; the pending model item updated (points 1, 3 and 4–7 closed, or carried with a reason); §5.4 written again; a `proposal.md` §8 entry; config settings if needed. No count at a coarser grain is made before it *(done 2026-10-25: Decision 23 recorded — forks a2, b3, v1, c1, r2, s1, m1, e1, f2: a `maxnet` model on the obscured set at the 0.2° grain; a model cell has complete-case 1 km cells on 50 % or more of it; the limits 25 and 80 of Decision 21 point 8 on the presence cells; a background of the clean iNaturalist mammal records (all Mammalia) of 10 times the presence cells or more; the Facebook dataset as a check (it gives no record to the model); a Gi* of the effort and of the tiger records (the tiger Gi* never published), settings in Week 15 or 16; no ratio. New `SDM_*` block in the config; the target-group item closed; §5.4 written again; a `proposal.md` §8 entry. No count made)* | 45–60 min |
| 14.2 ✅ | Process choices before code (not numbered): the script name `scripts/09_<verb_object>.R`; one script for Week 14 only, or for Weeks 14–15 (as process choice s1 of task 13.2); a function file; the table group (`tbl_16`, the next number; free in the listing of task 13.10) and its slugs; switches that skip finished STEPs (as `RUN_CLEANING`); any new package — `maxnet` is not in `renv.lock` (the lock list of task 13.6), and `sfdep` (Gi*) is to be checked — with `renv::snapshot()` and the `scripts/00a` list; the rule d1 of task 13.2 stays (no data file goes to the chat; the chat tests on made-up records). Then the script header and the guards: inputs present; CRS 7755; the clean layers give the counts of `tbl_15_occ_sets.csv`; `OCC_POINT8_OUTCOME` is `no_1km_model` | Header and guards run on the project machine; no result is printed *(done 2026-10-25: process choices s1, f1, w2, g1, t1, l1, r1 and the order o2, all as the chat recommended; `scripts/08` STEP 13.3 writes `effort_background_inat_cell02_7755.gpkg` (16,806 records: obscured 7,029, uncert 9,777) in one run with `RUN_CLEANING = TRUE` — the Week-13 counts are the same again, QA 172 of 172, and only `tbl_15_occ_qa.csv` changed (one new check); `scripts/09_model_suitability.R` and `R/00_functions_sdm.R` (new): 35 of 35 guards pass; `SDM_GRAIN_OUTCOME` in the config. `maxnet` 0.1.4 is installed; it goes into `renv.lock` with the fit STEP)* | 30–45 min |
| 14.3 ✅ | **Second Decision (numbered — Decision 24), before its result is computed.** **Branch A — the effort result:** (a) Gi* — built or not; the grid (for example the 10 km publication grid); the value of a cell (background cells or records); the neighbours and the distance band (the Phase-1 documents give 50 km and 25 km: a new judgement value); the correction for many tests (a false discovery rate; Caldas de Castro & Singer 2006); (b) the ratio of the tiger and effort surfaces — built or not; the grid; the minimum effort for a cell to get a value; not published at 1 km (Decision 22 point 9); (c) a comparison by reserve from `tbl_15_occ_by_reserve.csv` (for example, the reserves with background records and no tiger record) and its rule; (d) the published form of the effort and settlement surfaces (grid, classes, the effort caveat of proposal §7). **Branch B — the model settings:** (a) the covariates — the collinearity check (slope and TRI), the elevation on water and coastal cells (−434.2 m; pending item), and how each band is summarised to the grain (for example a mean, or the share of each land-cover class); (b) the feature classes and the regularisation of `maxnet` (Decision 21 point 8 gives `lq` at most for 25–79 cells at 1 km; Decision 24 says what applies at the grain); (c) the background points and the bias input — the effort surface (pending point 4), the settlement surface as a bias covariate (pending point 5), or neither; (d) the evaluation — the method (for example spatial blocks), the metric, and what is reported with few presence cells; (e) the sensitivity runs and their comparison rule (pending point 2 was written for the 1 km sets); (f) where the model is saved and what the saved object holds (check it for presence and background values before a commit); the file name against the QA check of task 13.7 (see the pitfalls). For both branches: what was seen | Decision 24 recorded before STEP 14.1 runs; config settings *(2026-10-25, process choice o2: Decision 24 comes after task 14.4 — after the count and before the covariate summaries and the fit. It states the counts of task 14.4 that were seen. With a no-model outcome it is not written: see "Changes from Decision 23")* *(done 2026-10-25: Decision 24 recorded — forks c1, z1, k1, f3, b1 (b2 as a sensitivity run), a1, v1, g2, r3, s3, m1, each as the chat recommended: nine candidate covariates summarised to the 0.2° cells, water cells out of the terrain means and an elevation floor of 0 m, \|r\| > 0.7 with a fixed order, AICc over 12 settings, no bias covariate, 2° blocks in 5 folds (Boyce, test AUC, OR10), the gate (mean test Boyce ≤ 0), the reserve check (census density; reserves with no presence cell), two sensitivity runs, the model file under `data/processed/`. A second `SDM_*` block in the config. The pending items "Model Decisions that Decision 21 names" and "Terrain variables" closed)* | 45–60 min |
| — | **Split point** (if the week is over 4 hours): commit the Decisions and the docs of tasks 14.1–14.3; continue with task 14.4 in the next session *(2026-10-25, o2: the split point moves to after task 14.4 — the count and its stop point. Commit tasks 14.1, 14.2 and 14.4; Decision 24 starts the next session)* | — | — |
| 14.4 ✅ | STEP 14.1. **Branch A:** build what Decision 24 fixes (Gi*, the ratio) on its grid → layers under `data/processed/` (gitignored) and `tbl_16_*` tables (counts and statistics only); if Decision 24 builds neither, this task has no STEP. **Branch B:** build the grain (the coarse template and the summarised covariate stack); assign the presence and background records to it; count the presence cells; compare the count with the minimum of Decision 23 and state the outcome — a stop point, as in task 13.3 | Outputs written and read back. Branch B: the outcome stated and locked in the config (as `OCC_POINT8_OUTCOME`) *(2026-10-25: task 14.4 comes before task 14.3 (o2). Process choices k1 — the grid `sdm_grid_cell02_7755.gpkg` and the 1 km cell-id raster `sdm_cellid_1km_7755.tif` under `data/processed/`, with no presence or background flag, and the switch `RUN_GRID`; h1 — a hand-made case first. No covariate summary in this task: it needs Decision 24)* *(done 2026-10-25: hand-made case 19 of 19; 7,450 cells with complete-case centres, 6,969 model cells; 104 presence cells (none removed by the 50 % rule); 1,486 background cells (minimum 1,040); **outcome `planned_model`**, locked in `SDM_GRAIN_OUTCOME`; `tbl_16_sdm_counts.csv`; STEP 14.1 took 0.1 min. `RUN_GRID <- FALSE` after the run)* | 45–60 min (A) / 30–45 min (B) |
| 14.5 ✅ | STEP 14.2. **Branch A:** the comparison by reserve of Decision 24 → a `tbl_16` table (a tiger count of 1 or 2 is `<3`, Decision 22 point 9; no tiger total). **Branch B:** if the outcome of task 14.4 allows it, fit `maxnet` with the settings of Decision 24; the evaluation; the sensitivity runs → the model file and `tbl_16_*` tables (no position) | Table written. Branch B: the model saved and read back; the evaluation table written *(2026-10-25, Decision 24: the covariate summaries of the model cells (points 1–2), the collinearity check (point 3), the AICc grid of 12 models (point 4), the main model (points 5–6), the 5-fold block cross-validation (point 7), the two sensitivity runs (point 10) and the model file (point 11). Process choices first: the `tbl_16` slugs; whether the covariate table of the model cells is written; the Boyce function (own code or a package); run switches; `maxnet` in `renv.lock` after the first run. The estimate is probably low: 12 + 5 + 2 model fits)* *(done 2026-10-25: process choices q1, t1, y1, h1, w1 and the chat's eight implementation points, all accepted; hand-made case 23 of 23; the collinearity rule kept 6 of the 9 candidates (no slope and no TRI: both have \|r\| > 0.7 with elevation); AICc selected `lq`, multiplier 1 (10 coefficients); over 5 folds: mean test Boyce 0.668, test AUC 0.749, OR10 0.165; both sensitivity runs "robust"; the model file `data/processed/tiger_sdm_maxnet_cell02_20261025.rds`; the covariate table under `data/processed/`; five `tbl_16` tables; STEP 14.2 took 0.2 min; `maxnet` 0.1.4 and `glmnet` 5.0 in `renv.lock`. `RUN_COVARIATES <- FALSE` after the run)* | 20–30 min (A) / 45–60 min (B) |
| 14.6 ✅ | STEP 14.3: QA — a hand-made case first (branch A: Gi* or the ratio on a small known grid; branch B: the aggregation and the presence count on a small known grid); each output on its grid; the small-count rule; the publish checks (no position or cell column in a `tbl_16` table; no file from the tiger records under `outputs/`, except a model file that Decision 24 allows) → `tbl_16_*_qa.csv`; a failure stops the script | QA passes *(2026-10-25, Decision 24 "Consequences": hand-made cases for the covariate summary (with a water cell and a cell with water only), the collinearity rule, AICc, the fold assignment and the Boyce index; the model-file check (no part of the object with the length of the data rows); no position or cell column in a `tbl_16` table; the Facebook check of Decision 23 point 7)* *(2026-10-25, task 14.5: the hand-made cases of this list already run at the start of STEP 14.2 (h1, 23 checks), and STEP 14.2 checks the model object before the save and each `tbl_16` table with `occ_assert_counts_only()`. Task 14.6 decides in its process choices which checks of the outputs on disk it adds. By w1, each run of `scripts/09` fits the models again and writes the five tables again; a run on another date writes one more model file)* *(done 2026-10-25: process choices c1, m1, h1, p1, s1; STEP 14.3 computes the main numbers again by a second path (the covariates by `terra::zonal()`; the cells, AICc and the training AUC again); QA 133 of 133 checks pass → `tbl_16_sdm_qa.csv`; the Facebook check of Decision 23 point 7: 0 records; 0.2 min. New: 12 functions in `R/00_functions_sdm.R`, two check tolerances in `R/00_config.R`)* | 20–30 min |
| 14.7 ✅ | Update `data-dictionary.md`, `methodology.md` (Decisions 23–24, change log, Limitations, §5.4 and §5.5), `proposal.md` §8, `naming-conventions.md` §6, `references.md`, `README.md` (status; the track table if there is no model), handoff (Week-14 status; entry point for Week 15), `project-plan.md` (Weeks 15–16 written again for the branch) | Docs match as-built *(2026-10-25: also the two new pending items — "[Week 15–16] Gi* settings" and "[Week 15] Prediction and publication of the suitability surface" — into the Week-15 and Week-16 rows; the reserve check and the gate of Decision 24 (points 8–9) into Week 15)* *(done 2026-10-25: Limitations (seven Week-14 items), §5.4 and §5.5 written again, the status, the pending items, a change-log entry; `proposal.md` §8, `README.md`, the handoff; the rows of Weeks 15–16 written again and the Week-15 task breakdown below. At the author's request, `methodology.md` and the handoff were made shorter: the change-log entries of Weeks 3–13 moved to `docs/methodology-changelog-archive.md`; the handoff written again for the weeks that follow. `data-dictionary.md`, `naming-conventions.md` §6 and `references.md` were complete from tasks 14.1–14.6)* | 30–45 min |
| 14.8 | Commit (`analysis:` for `09`, config, functions, tables; `docs:` separate; `docs: update handoff after Week 14` with the plan) | Committed and pushed; `git status --short` shows no point layer, no tiger surface and no file of exact tiger counts staged *(2026-10-25: by the author, before the Week-15 chat; nothing of Week 14 was committed before)* | 10 min |

**Changes from Decision 23 (2026-10-25).** The task table above is the plan
of 2026-10-18. Decision 23 picks branch B and changes these tasks:

- **Branch A is not used** in tasks 14.3 to 14.5 (dated 2026-10-25), unless
  task 14.4 gives a no-model outcome (Decision 23 points 4 and 6). Then
  Decision 24 (if recorded) gets a dated note "not used", task 14.5 fits no
  model, and the effort result (the branch-A list of task 14.3) goes into
  the Gi* Decision of Decision 23 point 8 (Week 15 or 16).
- **14.2:** more process choices — where the obscured background is made
  (a new output: `scripts/08` STEP 13.3 again with `RUN_CLEANING = TRUE`,
  which writes the outputs of STEPs 13.1–13.3 again, or a new STEP of
  `scripts/09` that reads the GBIF background file); a guard for
  `datasetKey` in the clean background layer (`scripts/08` STEP 13.3 writes
  it; the obscured tiger layer already has the cell corner,
  `cell02_lon_deg` and `cell02_lat_deg`); how the 0.2° cell polygons are made
  (in EPSG:4326, with densified edges, projected to EPSG:7755); the name of
  the outcome lock (as `OCC_POINT8_OUTCOME`). The guards also check the
  `SDM_*` block.
- **14.3 (Decision 24, branch B):** (a) the covariates are summarised from
  the 1 km cells to the 0.2° model cells; (c) the background is the
  iNaturalist target group of Decision 23 r2, so the fork is only whether
  a bias input is added to it (pending points 4 and 5), and whether
  `maxnet` adds the presences to the background (its default); (d) the
  evaluation needs a check that is not circular (the presences are
  probably mostly in reserves); (e) the sensitivity runs at the 0.2° grain
  (the 1 km model sets are not run).
- **14.4 (STEP 14.1, branch B):** the 0.2° cells; the model cells (Decision
  23 point 3); the presence cells and the background cells; the outcome of
  Decision 23 points 4 and 6 (`SDM_OUTCOME_VALUES`), stated and locked in
  the config. This is the first count at the 0.2° grain after the
  model-cell rule.
- **14.5:** no run without the Facebook dataset: Decision 23 e1 is a check
  in task 14.6.
- **14.6 (QA):** the list of Decision 23 ("Consequences") is added: a
  hand-made case for the cell of a coordinate and for the cover share; the
  iNaturalist key and the uncertainty of each presence record; the
  iNaturalist key of each background record; 0 records of the Facebook
  dataset; no 0.2° cell in a `tbl_16` table.
- **Estimates (not measured):** about 15 to 30 minutes more for tasks 14.2
  and 14.4 (the new background output and the 0.2° cells).
- **The order (process choice o2 of task 14.2, 2026-10-25):** 14.1, 14.2,
  **14.4** (the count; a stop point: the outcome is recorded in Decision 23
  and locked in `SDM_GRAIN_OUTCOME`), then **14.3** (Decision 24), then
  14.5 to 14.8. Reason: the background test (10 times the presence cells)
  can give no model, and the count of the background cells was not known;
  with o2, Decision 24 is not written for nothing. Decision 24 then states
  the two counts that were seen. The counts show no model result, and the
  limits of the feature classes are already fixed (Decision 23 c1).

**Week 14 pitfalls:**
- **Each Decision before its count.** Each `tbl_15` count is seen. The
  count of presence cells at a coarser grain is not; Decision 23 fixes the
  minimum before it. The chat cannot make that count (no data file, rule
  d1); the author does not make it before the Decision.
- **A coarser grain does not correct a position error.** In a simulation
  study, a coarser grain did not make up for the position error (Gábor et
  al. 2022; Decision 21, "Reason and sources"). A record of the 5 km set
  keeps an error of up to 5 km at each grain. The public point of an
  obscured record is about 10 km from its true position on average (two
  random points in one 0.2° cell; Decision 22 point 1).
- **One dataset gives most tiger records.** "Bengal Tiger (Panthera
  tigris) Sighting based on Photographs from Facebook in India" gives 273
  of the 300 records of the 5 km set and 20 of the 45 of the 1 km set. Its
  GBIF entry does not say how a position was given to a photograph. It
  gives no background record, so the matched background has nothing from
  it. *(2026-10-25: not in the model — the obscured set and the background
  of Decision 23 are from iNaturalist only; e1 is a check of this.)*
- **The tiger records and the background have different years.** 268 of
  the 300 records of the tiger 5 km set are from 2018–2022 (26 of its 44
  cells). 5,355 of the 6,082 records of the matched 1 km background are
  from 2006–2017. The 5 km background has 9,504 of its 23,901 records in
  2018–2022.
- **The largest group of the tiger 1 km set is outside the reserve
  polygons.** Its 18 records of 2018–2022 are in one cell, and each reserve
  row of `tbl_15_occ_by_reserve.csv` has fewer. The cause is not known.
  Before a model uses the 5 km set, the author can look at the cell on the
  project machine and give the chat a category only (for example a buffer
  zone, a captive or rescue site, a town) — no position. With the cell
  unit, the cell counts 1 however many records it holds. *(2026-10-25: the
  1 km set and the 5 km set are not model inputs (Decision 23 b3), so this
  check is not needed for the model.)*
- **The obscured set has no background.** Decision 21 point 4 counts the
  obscured background and does not keep it. A model on the obscured set
  needs a background set by the same rule: a new output of `scripts/08`
  STEP 13.3 and a run with `RUN_CLEANING = TRUE` (STEPs 13.1–13.3 then
  write their outputs again). *(2026-10-25: Decision 23 r2 — the obscured
  background plus the iNaturalist records of the 5 km background; where it
  is made is a process choice of task 14.2.)*
- **A 0.2° cell is not on the 1 km grid.** It is a cell of longitude and
  latitude; the template is EPSG:7755. A covariate value for a 0.2° cell
  needs a summary over a polygon, not `terra::aggregate()`. In India a
  0.2° cell is about 22 km north–south and 18–22 km east–west (computed:
  0.2° of longitude is about 22.0 km at 8° N and 17.8 km at 37° N).
  *(2026-10-25: Decision 23 point 3 (model cells) and Decision 24 (the
  summary of each band).)*
- **The target-group scope is open.** The 23,901 background records hold
  rodents (6,361), bats (746) and whales (140), which the methods that
  record tigers do not record. If a model is chosen, Decision 23 fixes the
  scope. A smaller target group needs the effort surface built again with
  the Decision-22 settings (Decision 22 point 1). *(2026-10-25: closed —
  Decision 23 s1, all Mammalia; the effort surfaces are not built again.
  5,377 of the 6,361 rodent records are squirrels, which visitors
  photograph.)*
- **A bias correction can over-correct.** It can over-correct where the
  effort is low (Ranc et al. 2017; Barber et al. 2022). In two simulation
  studies, a filter of the records was the most consistent correction
  (Fourcade et al. 2014; Kramer-Schadt et al. 2013). See Decision 22,
  "Reason and sources".
- **Terrain.** Slope and TRI are probably collinear, and the stack
  elevation reaches −434.2 m (probably sea-floor depth; pending item). Read
  the current values in `tbl_10`.
- **The Gi\* band is a new value.** The Phase-1 documents give 50 km
  (final report) and 25 km (method notes and story-map outline).
  *(2026-10-25: the Gi* Decision of Week 15 or 16 fixes it (Decision 23
  f2). The Phase-1 Gi* used the tiger records.)*
- **The tiger file-name check.** The QA check of task 13.7 "no file with
  'tiger' in its name under `outputs/`" fails on
  `outputs/models/tiger_sdm_*.rds` (naming §6). Change the check or the
  name in task 14.2 or 14.3, not after a failed run.
- **A published total can give a suppressed count.** A table that uses the
  reserve counts of `tbl_15_occ_by_reserve.csv` keeps the `<3` values and
  holds no tiger total.
- **`proposal.md` §8.** The doc fix pass of 2026-10-17 left §8 until the
  model Decision. Each branch needs an entry: §5 of the proposal names a
  `maxnet` SDM with a national prediction.
- **Numbers.** Decision 23 is the next Decision number; `tbl_16` is the
  next table group. `fig_04` is the next free figure number, and the
  Week-16 row names `fig_05` — confirm at Week 16.
- **Sensitive data.** The clean point layers, the tiger surface and each
  layer made from the tiger records stay under `data/` (gitignored). The
  console text that goes to a chat holds counts and names, never a
  coordinate or a cell number.
- **PROJ `proj.db` clash still applies** — fresh session.

**Decisions due this week:** **23** (no model or a model at a coarser
grain; for a model, the grain, the inputs, the minimum, the background and
the target-group scope), before any count at a coarser grain; **24**
(branch A: the effort result; branch B: the model settings), before its
result is computed. The pending items "Model Decisions that Decision 21
names", "Target-group scope" and "Terrain variables in the SDM" are closed
by them or carried with a recorded reason. *(2026-10-25: Decision 23
recorded; "Target-group scope" closed; "Terrain variables in the SDM" and
points (2), (4), (5) of the model item carried to Decision 24, the branch-B
Decision.)*
*(2026-10-25: Decision 24 recorded; the two pending items closed by
Decisions 23 and 24. New pending items: "[Week 15–16] Gi* settings" and
"[Week 15] Prediction and publication of the suitability surface".)*

**Exit state:** Decisions 23 and 24 recorded; `scripts/09_<verb_object>.R`
ran on the project machine; branch A: the outputs of Decision 24 written
(`tbl_16_*`) and through the publish checks; branch B: the presence-cell
outcome at the grain stated, and a model fitted and saved if the outcome
allows it; QA passed; a `proposal.md` §8 entry; docs updated; Weeks 15–16
written again for the branch; Week 14 ticked.
*(2026-10-25: reached — branch B; the outcome `planned_model`; the model
fitted and saved; QA 133 of 133; the docs updated; Weeks 15–16 written
again. The commit (task 14.8) is by the author.)*

### Week 15 — task breakdown

*(Written 2026-10-25 at the Week-14 close (task 14.7). This is a draft
plan. It makes no Decision: Decision 25 is the author's, in task 15.1.)*

Entry state (as of the Week-14 close, 2026-10-25; Week 14 committed by the
author in task 14.8). On disk, all gitignored:

- `data/processed/sdm_grid_cell02_7755.gpkg` — 7,450 cells of 0.2°, 6,969
  model cells (no presence or background flag).
- `data/processed/sdm_cellid_1km_7755.tif` — the 0.2° cell id of each
  complete-case 1 km cell.
- `data/processed/sdm_covariates_cell02.csv` — the covariates of the 6,969
  model cells (no presence or background flag).
- `data/processed/tiger_sdm_maxnet_cell02_20261025.rds` — the main model
  (`lq`, multiplier 1; `ghm_mean`, `lc_forest`, `elev_mean`, `lc_open`,
  `droad_km_mean`, `lc_built`) and its settings.
- The Week-13 layers (the clean and obscured tiger layers, the backgrounds,
  the density surfaces) and the reserve layers
  (`boundary_reserves_all_7755.gpkg`, `stats_reserve_census_7755.gpkg`).

Committed: the seven `tbl_16_*` tables (counts and statistics only).
`scripts/09_model_suitability.R` holds STEPs 14.1–14.3; `RUN_GRID` and
`RUN_COVARIATES` are `FALSE`; the 19 fits run in each run (process choice
w1 of task 14.5).

**Seen at the Week-14 close.** Each value of the `tbl_16` tables: the counts
of the grid, the presences and the background; the covariate statistics
and correlations; the AICc table; the cross-validation metrics by fold;
the sensitivity ρ and overlaps; the QA. **Not computed or not seen:** a
prediction written to a file, a map, a reserve value, the reserve check, a
Gi* value. The predictions of STEP 14.2 were made in memory only. Decision
25 states this list again.

**Size.** The estimates add up to about 3.2–4.7 hours (estimates, not
measured). A split point is marked after task 15.2: the Decision and the
process choices first (no result), the STEPs second.

| # | Task | Done when | Est. |
|---|---|---|---|
| 15.1 ✅ | **Prediction Decision (numbered — Decision 25), before any prediction surface is written or seen.** Research, raise the forks, record the choices: (a) the model file (`tiger_sdm_maxnet_cell02_20261025.rds`; process choice m1 of task 14.6) and the output type of the surface — cloglog (the type of the evaluation, Decision 24 point 7), logistic or raw — and clamping; (b) the cells: the 6,969 model cells only (Decision 23 point 3), and how a cell outside the training range of a covariate is shown (clamping only, or a flag such as MESS); (c) the published form: the classes (for example quantile classes or fixed breaks), the unit (the 0.2° cell), and whether a table of the reserve values by reserve is published; (d) sensitive data: the policy tier of a surface fitted on the obscured records, and a check that the published form does not mark the presence cells (Decision 23 point 9); (e) the caption content that the Decisions fix: the effort caveat (proposal §7), "suitability, not occupancy" (Decision 1), the tie rule of the Boyce index when the metrics are given (Decision 24 point 8: above 0, the metrics are published with the map); (f) the figure number (`fig_04` is free) and whether the two sensitivity runs are shown; (g) what was seen (the list above) | Decision 25 recorded in `methodology.md` with the date, the choices, the judgement values and what was seen; the pending item "[Week 15] Prediction and publication of the suitability surface" closed; config settings if needed *(done 2026-10-31: Decision 25 recorded — a1 (the model file of 2026-10-25, cloglog with clamping), b2 (the cells outside the training range flagged, counted and hatched), c1 with n5 (five equal-count classes by rank; no value in the legend), d1 (no layer before Week 18; tier T1), e1 (nine caption items), f3 (two figures: `fig_04` classes, `fig_05` value with the label "relative; not a probability of presence"; the hatch on both), t1 (a reserve table, no presence column), h1 (a 1 km cell is inside if its centre is; a 1 km cell outside the model cells has no value and is counted). f3 and its two-figure form are not the chat's recommendation. The pending item closed; "[Week 18] Published path layer" is now "[Week 18] Published layers". A new config block. No prediction made)* | 45–60 min |
| 15.2 ✅ | Process choices before code (not numbered): the STEP numbers of `scripts/09` and the table slugs (the `tbl_16` group; process choice t1 of task 14.2: each task names its own tables); a run switch for the fits now that the model is fixed (w2 of task 14.5), or a read of the model file; where the prediction layer goes (`data/processed/`, gitignored, until the published form of Decision 25 is made); the inputs of the reserve check (`boundary_reserves_all_7755.gpkg` for the polygons, `stats_reserve_census_7755.gpkg` for `density_2022`, both keyed on `unit_id`); a hand-made case first (as h1 of tasks 14.4–14.6) *(2026-10-31, from Decision 25 "Consequences": (1) a1 names the model file, so the run either skips the 19 fits (a switch, w2 of task 14.5) or reads the file directly; with either, STEP 14.3 check m1 ("the model file of this run") must change. (2) The reserve table (t1) has reserve names and number columns that are not in the list of check (a): STEP 14.3 scans each `tbl_16_*.csv` (except the QA table) and stops on them, so the table needs another number (`tbl_17` is the next free) or a change of the scan. (3) The publish check of the reserve table (no presence column, no cell id). (4) The name of the prediction layer under `data/processed/`. (5) The column names, the rounding and the tie rule of the rank of the reserve table)* | Choices recorded; no code before them *(done 2026-10-31: w1 (a switch `RUN_FIT`, `FALSE`: STEP 14.2 skipped; check m1 reads `SDM_PRED_MODEL_FILE`), l1 (`data/processed/sdm_prediction_cell02.csv`), n1 (`tbl_17_reserve_suitability.csv`), c1 (STEP 14.3 scans its six tables; STEP 15.3 the Week-15 tables), t1 (`tbl_16_sdm_prediction`, `tbl_16_sdm_reserve_check`, `tbl_16_sdm_pred_qa`; the class value ranges in a table), k1 (the columns of Decision 25 point 7 plus `landscape_complex`; ties "min"), e1 (`sf::st_intersects()` on the centres; QA by `terra::extract()`), p1 (`exact = FALSE`), q1 (own QA table; a second path). Also **Decision 25 point 9** (y1, z1), added before any result: r2 only if each count of the 2 × 2 table is 3 or more; a QA check that stops on a reserve whose presence state the outputs show. Details: `methodology.md`, change log 2026-10-31, task 15.2)* | 15–30 min |
| — | **Split point** (if the week is over 4 hours): commit the Decision and the docs of tasks 15.1–15.2; continue with task 15.3 in the next session *(2026-11-01: not used; the author commits Week 15 in task 15.7)* | — | — |
| 15.3 ✅ | STEP 15.1 — the prediction of the main model over the 6,969 model cells with the settings of Decision 25 → a layer under `data/processed/` (gitignored) and a summary table (statistics only); **the gate of Decision 24 point 8** stated in the table and the console (the mean test Boyce index is 0.668, above 0: the gate allows a suitability map) *(2026-10-31, Decision 25 points 1–4: the layer holds the cell id, the cloglog value, the class and the out-of-range flag of each model cell, and no presence or background field; the summary table holds the class sizes and the counts of the cells outside the training range, all and by covariate)* *(2026-10-31, task 15.2: first `RUN_FIT` (w1) and the change of STEP 14.3 (check m1; the scan of its six tables only, c1), and the header of `scripts/09` with the choices of task 15.2; the layer `sdm_prediction_cell02.csv` (l1); `tbl_16_sdm_prediction.csv` with the class value ranges and the median (t1); a hand-made case first)* | The layer written and read back; the gate stated *(done 2026-11-01: `RUN_FIT` = `FALSE`, STEP 14.2 skipped, QA 133 of 133; STEP 15.1 — the hand-made case 18 of 18; the gate open (mean test Boyce 0.668); 6,969 model cells, cloglog 2.1e−13 to 0.9998, median 0.290; classes of 1,394 (5 to 2) and 1,393 (1); 32 cells outside the training range; the layer `sdm_prediction_cell02.csv` and `tbl_16_sdm_prediction.csv` (36 rows). Not committed: the author commits at the end of the week)* | 30–45 min |
| 15.4 ✅ | STEP 15.2 — **the reserve check of Decision 24 point 9.** r1: the reserve value (the mean of the predictions over the complete-case 1 km cells inside the reserve polygon, each 1 km cell with the value of its 0.2° cell; a cell in two overlapping polygons counts in each) and the Spearman ρ with `density_2022` over the reserves with a polygon and a value — ρ, n and the two-sided p; the reading "agrees" if ρ > 0 and p < 0.05 (`SDM_RESERVE_P`), otherwise "no agreement shown". r2: the reserves with no presence cell and the share of them above the median prediction of the model cells — counts and the share only, **no reserve name linked to a presence or no-presence state** *(2026-10-31, Decision 25: the cells of point 8 (h1) — a 1 km cell is inside if its centre is inside the polygon or on its edge; a 1 km cell whose 0.2° cell is not a model cell has no value and is counted for each reserve; a reserve with no valued cell is not in r1 or r2. Also the published reserve table of point 7 (t1): 58 rows, no presence column)* *(2026-10-31, task 15.2: the cells by e1; p by p1; `tbl_16_sdm_reserve_check.csv`; `tbl_17_reserve_suitability.csv` with the columns of k1; r2 under Decision 25 point 9 (y1); the counts of the two kinds of z1)* | A `tbl_16` table (statistics only); the reading of r1 stated *(2026-10-31: and the reserve table of Decision 25 point 7, with the number of task 15.2)* *(done 2026-11-01: 56 of 58 reserves with a value; r1 ρ = 0.379, n = 51, p = 0.00614 → "agrees"; r2 not published (Decision 25 point 9); z1 0; `tbl_16_sdm_reserve_check.csv` (14 rows), `tbl_17_reserve_suitability.csv` (58 rows). Not committed)* | 30–45 min |
| 15.5 ✅ | STEP 15.3 — QA: a hand-made case first; the prediction again from the model file by a second path; the reserve values again (for example `terra::zonal()` on the cell-id raster); the gate and the r1 reading again from the tables; the publish checks of Decision 25 and those of task 14.6 (no position or cell column, no cell id as a value, no reserve name with a presence state, no tiger file under `outputs/`) → a `tbl_16` QA table; a failure stops the script *(2026-10-31, Decision 25 "Consequences": hand-made cases for the class rule (a tie; n not a multiple of 5), for the flag (a value at a limit is inside) and for the cells of point 8 (a centre on an edge; a 1 km cell in a cell that is not a model cell); the class sizes (1,394 × 4 and 1,393); class 5 against the top set of `sdm_compare()`; no presence or background field in the prediction layer; no presence column in the reserve table)* *(2026-10-31, task 15.2 (q1, c1): `tbl_16_sdm_pred_qa.csv`; the second path by hand from the model file; the reserve values by `terra::extract()`; the scan of the Week-15 tables and `tbl_17`; Decision 25 point 9: hand-made cases for the r2 rule (a count of 0, 2 and 3) and for the two kinds of z1, and the z1 count = 0)* | QA passes *(done 2026-11-01: 84 of 84; the second path agrees; the terra path found no reserve that differs; an information count by the author's choice: 1 reserve (Mukundara Hills) has 19 of its 316 valued 1 km cells outside the training range. Not committed)* | 30–45 min |
| 15.6 ✅ | Update `data-dictionary.md`, `methodology.md` (Decision 25, change log, Limitations, §5.4), `proposal.md` §8 (if a choice differs from the proposal), `naming-conventions.md` §6, `references.md`, `README.md`, the handoff, `project-plan.md` (the Week-16 task breakdown: Decision 26 on the Gi* settings, the Gi* build, the figures) | Docs match as-built *(done 2026-11-01: the author's choice m1 (no note on the cells outside the range of one reserve value); §5.4 written again; eight Week-15 items in "Limitations"; a change-log entry with the record against proposal question 3; a dated note in `proposal.md` §8; `README.md`; the handoff; the Week-16 task breakdown below. `data-dictionary.md`, `naming-conventions.md` §6 and `references.md` were complete from tasks 15.1–15.5)* | 30–45 min |
| 15.7 ✅ | Commit (`analysis:` for `09`, config, functions, tables; `docs:` separate) | Committed and pushed; `git status --short` shows nothing under `data/` staged | 10 min |

**Week 15 pitfalls:**
- **Decision 25 before any prediction file.** The metrics are seen; a
  prediction surface is not. Do not map the model file before the
  Decision.
- **The gate is known.** The mean test Boyce index (0.668) is above 0, so
  the gate of Decision 24 point 8 allows a map. Week 15 states it; it is
  not a new rule. The metrics are published with the map (point 8).
- **The census density is per total notified area** (`density_2022`,
  Decision 8), and the polygon is the core protected-area outline (Decision
  4). r1 is partly linked to the presences (Decision 24, "Limitations").
- **`unit_name` is not unique** (two Pench, two Rajiv Gandhi): key on
  `unit_id`. Pilibhit and Dholpur-Karauli have no polygon; Amrabad has its
  polygon from the state split. 6 pairs of reserve polygons overlap; a
  cell counts in each (as o1 of task 13.8).
- **No reserve name with a presence state (r2).** A table of the reserve
  values by reserve is a Decision-25 question (fork c).
- **One model file, and w1.** Each run of `scripts/09` fits the models
  again and writes the model file with the date of the run; a run on
  another date writes one more file. The Week-15 STEPs read the file that
  Decision 25 names, or task 15.2 adds the switch.
- **Clamping.** `predict.maxnet()` clamps by default; the evaluation used
  cloglog with clamping (Decision 24 point 7).
- **A 0.2° cell is a cell of longitude and latitude.** The grid layer holds
  the cell polygons in EPSG:7755 (edges densified every 0.01°); the reserve
  value uses the 1 km cells of the cell-id raster.
- **The publish checks.** `assert_publishable_rast()` is for a raster of
  1 km or coarser; a layer of 0.2° polygons needs the check that Decision
  25 fixes. The clean point layers and the obscured set stay under `data/`.
- **Numbers.** Decision 25 is the next Decision number (Decision 26 for the
  Gi* settings in Week 16); the Week-15 tables take new slugs in the
  `tbl_16` group; `fig_04` is the next free figure number.
  *(2026-10-31: Decision 25 reserves `fig_04` and `fig_05`. The published
  reserve table cannot go in the `tbl_16` group unless the scan of STEP
  14.3 changes; task 15.2 decides.)*
- **PROJ `proj.db` clash still applies** — fresh session.

**Decisions due this week:** **25** (the prediction and its published
form), before any prediction file. Decision 26 (the Gi* settings) is due in
Week 16 in this draft.

**Exit state:** Decision 25 recorded; the prediction layer written; the gate
stated; the reserve check written; QA passed; docs updated; the Week-16 task
breakdown written; Week 15 ticked.
*(2026-11-01: reached — Decision 25 with point 9; the prediction (the gate
open); the reserve check (r1 "agrees"; r2 not published; z1 0); QA 84 of
84; the docs; the Week-16 breakdown. The commit (task 15.7) is by the
author.)*

### Week 16 — task breakdown

*(Written 2026-11-01 at the Week-15 close (task 15.6). This is a draft
plan. It makes no Decision: Decision 26 is the author's, in task 16.1.)*

Entry state (as of the Week-15 close, 2026-11-01; Week 15 committed by the
author in task 15.7). On disk, all gitignored:

- `data/processed/sdm_prediction_cell02.csv` — the prediction (`id`,
  `value`, `rank`, `class`, `out_of_range`), 6,969 rows; no presence or
  background field.
- `data/processed/sdm_grid_cell02_7755.gpkg` (the 0.2° cells as polygons
  in EPSG:7755) and `sdm_cellid_1km_7755.tif`.
- The Week-13 layers: the clean tiger records (`occ_tiger_gbif_clean_7755.gpkg`;
  the 1 km set and the 5 km set; tier T2), the obscured set (T1), the
  clean background (`effort_background_tgs_clean_7755.gpkg`), the density
  surfaces (`kde_*`; `kde_tiger_*` never published or committed).
- The reserve layer, and the state layer (Natural Earth, in
  `data/processed/`).

Committed: the `tbl_16` tables of Weeks 14–15 and
`tbl_17_reserve_suitability.csv`. `scripts/09_model_suitability.R` holds
STEPs 14.1–15.3; `RUN_FIT` is `FALSE`.

**Seen at the Week-15 close.** The values of the Week-15 tables: the
statistics of the prediction and of its classes, the cells outside the
training range, the value and the rank of each reserve, r1, the QA.
**Not computed or not seen:** a map of the prediction, a figure, a Gi*
value. Decision 26 states this list again.

**Size.** The estimates add up to about 3.4–4.9 hours (estimates, not
measured; the Week-16 row planned 2–3 h, probably 3–4 h with the Gi*). A
split point is marked after task 16.2. *(2026-11-07: Decision 26 adds two
Gi\*, the QA bands and `fig_06`: about 4.2–6.2 hours (an estimate). A second
split point after task 16.3 is possible.)*

| # | Task | Done when | Est. |
|---|---|---|---|
| 16.1 ✅ | **Gi\* Decision (numbered — Decision 26), before any Gi\* is computed** (pending item "[Week 15–16] Gi* settings"; Decision 23 point 8). Research, raise the forks, record the choices: (a) the input set of the tiger Gi* — the 5 km set (300 records in 44 1 km cells; tier T2; 273 records from one dataset), the obscured set (884 records in 104 cells of 0.2°; T1), or both; (b) the input of the effort Gi* (the clean background, or a part of it); (c) the grid and the value of a cell (records, or another count); (d) the neighbours and the distance band (a new value; Phase 1: a fixed band of 50 km, with the peak of its incremental spatial autocorrelation at 25 km); (e) the correction for many tests (Phase 1: a false discovery rate); (f) the published form of the effort Gi* (tier T0: a figure, a table or none) and what the docs can state from the tiger Gi* (never published or committed; for example, whether the Phase-1 cold spot at Ranthambore is found again); (g) the code: `sfdep` (in the `scripts/00a` list, not in `renv.lock`) or own code; (h) what was seen (the list above) | Decision 26 recorded in `methodology.md` with the date, the choices, the judgement values and what was seen; the pending item closed; config settings if needed *(done 2026-11-07: Decision 26 recorded — x1 (no comparison with Phase 1), a3 (both tiger sets), b1 with C1-2 (`effort_inat` with the obscured set; `effort_all`, the background of all datasets, with the 5 km set), c1 (the 6,969 model cells, 0/1), d1 (50 km, the cell included) with k1 (8 neighbours or more for a class) and q2 (QA bands: queen and 75 km), e1 (the exact p), m1 (Benjamini–Hochberg, q = 0.05), f1 (`fig_06` for `effort_inat`; `effort_all` in the table only, the chat's reading), s2 with L1 and S-a (the tiger counts; by landscape complex for the 5 km set only), w1 (all years), g1 (own code); h1 and h2. a3, s2 and C1-2 are not the chat's recommendation. The pending item closed; a config block `GISTAR_*`. No Gi\* computed)* | 45–60 min |
| 16.2 ✅ | Process choices before code (not numbered): the STEP numbers of `scripts/09` (s1 of task 14.2: one script for Weeks 14–16); the table slugs; the figure slugs (no "tiger"; `fig_04` and `fig_05` reserved by Decision 25; `fig_06` is the next free number); the size, the colours (readable with a colour-vision deficiency), the hatch and the frame of the two suitability figures (as `fig_03`, national scale); where the caption drafts go; the check of Decision 25 point 4 (the figure code reads only the prediction layer and the grid layer); hand-made cases first *(2026-11-07, Decision 26 "Consequences": also the cell centre; how a record of the 5 km sets gets its 0.2° cell; the Gi\* layer names (`hot_`); the number and slug of the Gi\* statistics table; the slug, colours and size of `fig_06`; the check of the `fig_06` code (Decision 26 point 7))* | Choices recorded; no code before them *(done 2026-11-07: s1, f1, p1, r2, n1, t1, g1, z1, c1, h1, k1, d1, q1 — each as the chat recommended; and Amendment 1 of Decision 26 (A1): the distance between cells is on the sphere, not in EPSG:7755 (an error of the chat, found in this task). Details: `methodology.md`, change log, task 16.2)* | 15–30 min |
| — | **Split point** (if the week is over 4 hours): commit the Decision and the docs of tasks 16.1–16.2; continue with task 16.3 in the next session | — | — |
| 16.3 ✅ | STEP 16.1 — the Gi* of Decision 26: the effort Gi* and the tiger Gi* (the tiger Gi* stays under `data/`, gitignored); tables of statistics only *(2026-11-07, Decision 26: four Gi\* at 50 km and at the two QA bands; one statistics table with the counts of point 7)* *(2026-11-07, task 16.2: `R/00_functions_gistar.R` (f1); the GBIF coordinates of the 5 km sets from the two zip files (r2); the layers `hot_*_cell02.csv` (n1); `tbl_18_gistar.csv` (t1); the distance on the sphere (Amendment 1))* | The layers written and read back; the tables written *(done 2026-11-07: the hand-made case 26 of 26; the four layers `hot_*_cell02.csv` written and read back; `tbl_18_gistar.csv`, 92 rows; at 50 km `effort_inat` 654 hot, `effort_all` 559 hot, no cold cell; `tiger_obscured` 200 hot (85 also effort hot), `tiger_5km` 52 hot (20). STEP 16.1 took 0.1 min. Details: Decision 26, "Result of STEP 16.1")* | 30–45 min *(2026-11-07: probably 45–60 min; estimate)* |
| 16.4 | STEP 16.2 — the two suitability figures of Decision 25 points 4–6: `fig_04` (the five classes; the legend by rank, no value) and `fig_05` (the value; the legend label `SDM_PUB_VALUE_LABEL`); on both: the hatch of the 32 cells outside the training range, the blank cells that are not model cells, the reserve outlines (the core polygons) and the state boundaries; no presence or background mark; the caption drafts with the nine items of Decision 25 point 5, marked as drafts (the narrative is the author's) *(2026-11-07, Decision 26 f1: also `fig_06`, the `effort_inat` Gi\*, with the nine caption items of Decision 26 point 7)* *(2026-11-07, task 16.2: `R/00_functions_fig.R` (f1); the slugs of g1; the frame of z1; the colours of c1 (the `fig_06` hex values with a colour-vision simulation); the hatch and the key box of h1; the read guard `fig_read()` (k1); the caption drafts as for `fig_03` (d1))* *(2026-11-07, after the run of task 16.3: before the code, the author answers the three readings of task 16.3 and a caption question of `fig_06` (at 50 km no effort cell is cold))* *(2026-11-07: the readings confirmed; the caption choice k-a — caption item 4 of `fig_06` also states that no cell is cold at 50 km and gives the cold count at 75 km)* | Two PNG files under `outputs/figures/`; the caption drafts *(2026-11-07: three PNG files)* | 45–60 min *(2026-11-07: probably 60–90 min; estimate)* |
| 16.5 | STEP 16.3 — QA: hand-made cases; the Gi* again by a second path; the check of Decision 25 point 4; the publish checks (no tiger Gi* file under `outputs/`; no file with "tiger" in its name; the scans of the new tables) → a QA table; a failure stops the script *(2026-11-07: the QA list of Decision 26 "Consequences")* *(2026-11-07, task 16.2: `tbl_18_gistar_qa.csv` (t1); the read record of k1; the permutation check of q1; the cell of r2 against the iNaturalist layer)* | QA passes | 30–45 min |
| 16.6 | Docs, the Stage-3 close: `methodology.md` (Decision 26 and its result, change log, Limitations, §5.4–5.5), `proposal.md` §8, `README.md`, `data-dictionary.md`, `naming-conventions.md` §6, `references.md`, the handoff; Stage 3 against proposal questions 3 and 4 (a record, not site text); the pending item "[After Stage 3] SDM-based resistance" (does it still apply at 0.2°?); the Week-17 plan | Docs match as-built | 30–45 min |
| 16.7 | Commit (`analysis:` for `09`, config, functions, tables, figures; `docs:` separate) | Committed and pushed; `git status --short` shows nothing under `data/` staged | 10 min |

**Week 16 pitfalls:**
- **Decision 26 before any Gi\*.** The Phase-1 settings are known (a band of
  50 km, a false discovery rate), and the tiger records were counted in
  Week 13 (by window, by reserve). No Gi* has been computed.
- **The tiger Gi\* is never published or committed** (Decision 23 point 8;
  `SDM_GISTAR_PUBLISH_TIGER` = `FALSE`). No figure of it goes to
  `outputs/`; the docs state only what Decision 26 allows.
- **The clean tiger sets are tier T2** (precise points). The 5 km set has
  273 of its 300 records from one dataset (Decision 21).
- **`sfdep` is not in `renv.lock`.** `renv` records a package only when a
  script loads it: snapshot after the first run that uses it.
- **The two suitability figures:** the legend of `fig_04` gives no cloglog
  value; the legend label of `fig_05` is fixed; the hatch is on both (32
  cells; by m1 of task 15.6 no other note on the one reserve value that
  uses hatched cells); a blank cell is not a model cell; the reserve
  outlines are the core polygons; no presence or background mark; each
  caption states the effort caveat (proposal §7).
- **A 0.2° cell is a polygon in EPSG:7755** (the grid layer, with edges
  densified every 0.01°). A raster of 0.2° in EPSG:4326 fails
  `assert_publishable_rast()`; Week 16 makes figures only (Decision 25 d1).
- **A slug does not hold "tiger"** (the QA check "no file with 'tiger' in
  its name under `outputs/`").
- **`RUN_FIT` stays `FALSE`.** Each run writes the Week-15 tables again
  (the same values).
- **Numbers.** Decision 26 is the next Decision number; `fig_06` and
  `tbl_18` are the next free numbers.
- *(2026-11-07, Decision 26)* **The tiger Gi\* cannot show a cold spot**
  (Decision 26 point 6, arithmetic from the published counts). A text about
  the tiger Gi\* says so. **`fig_06` is reserved** for the `effort_inat`
  Gi\*; `fig_07` is the next free figure number.
- **PROJ `proj.db` clash still applies** — fresh session.

**Decisions due this week:** **26** (the Gi* settings), before any Gi*.

**Exit state:** Decision 26 recorded; the Gi* written (the tiger Gi* under
`data/` only); `fig_04` and `fig_05` with the caption drafts; QA passed;
docs updated (the Stage-3 close); the Week-17 plan written; Week 16 ticked.

---

## Stage 4 — Story site and close (Weeks 17–20)

| Week | Focus | Exit state (deliverable) | Est. |
|---|---|---|---|
| **17** | Site skeleton | Quarto site structure; one page per track; navigation | 3–4 h |
| **18** | Leaflet maps | Interactive maps wired in (reuse Bay Area Leaflet recipe) *(2026-10-31: first the pending item "[Week 18] Published layers" (`methodology.md`) — whether a path layer and the suitability surface at 0.2° go on an interactive map, and in which form; Decision 25 point 4)* | 3–4 h |
| **19** | Narrative + QC | Author-written narrative; figure alt text; accessibility pass | 3–4 h |
| **20** | Publish + docs close | Site deployed to GitHub Pages; final report; decision log closed | 3–4 h |

---

## Milestone summary

| Milestone | Target week | Meaning |
|---|---|---|
| Scaffold committed to GitHub | 0 | Version-controlled, data-free base to build on |
| Data audited and gaps closed | 2 | Know exactly what must be rebuilt |
| **Growth track complete** | 7 | ✅ Achieved Week 7 — priority-1 deliverable done and publishable (tbl_01, tbl_02, fig_01, fig_02) |
| **Connectivity track complete** | 12 | ✅ Achieved Week 12 — priority-2 deliverable done (`tbl_03`, `tbl_03b`, `fig_03`; working tables `tbl_11`–`tbl_14`). The figure text is a draft; the path layer for the site needs its own rule (Week 18) |
| Suitability track complete | 16 | Priority-3 deliverable done *(2026-10-25: a model is fitted at the 0.2° grain (Week 14); the prediction, the reserve check, the Gi* and the figure in Weeks 15–16)* *(2026-11-01: the prediction and the reserve check are done (Week 15; r1 "agrees"); the Gi* and the two figures in Week 16)* |
| **Site published** | 20 | Full project live |

---

## Risk management (pace-specific)

| Risk | Likelihood | Effect | Response |
|---|---|---|---|
| All-reserve census extraction is slower than 2 weeks | ~~High~~ **Retired** | Stage 1 slips | Did not materialise — the full within-reserve series was extracted in Week 4 (2014/2018/2022 is only 3 tabular rounds, not 5). Week 5 is now the join, not more extraction |
| WII TR boundaries not public | Medium | Weaker boundary layer | KBA fallback, documented (Decision) |
| Weeks slip due to job load | High | Calendar stretches | Expected. Each week is self-contained; no penalty for a gap |
| SDM adds little beyond growth + connectivity | Medium *(2026-10-18: occurred in part — no 1 km model, Decision 21 point 8)* | Wasted effort | Priority 3 by design — drop it if Stage 1–2 already tell the story. *(2026-10-18: Decision 23, task 14.1, decides between no model and a model at a coarser grain)* *(2026-10-25: Decision 23 chose a model at the 0.2° grain (a2, b3); the count of task 14.4 can still give no model)* *(2026-10-25, Week 14: the count gave `planned_model`; the model is fitted, and the value for the gate is above 0. The answer to question 3 is at about 20 km, not at 1 km)* |
| Scope creep to "every possible analysis" | Medium | Never finishes | Three tracks only. New ideas go to a Phase-2 future-work list |

---

## Progress tracking

Status is tracked per week in this table. Update the exit state to ✅ when the
deliverable exists.

| Week | Deliverable | Status |
|---|---|---|
| 0 | Scaffold committed + pushed to GitHub (data-free) | ✅ Complete |
| 1 | Data audit table | ✅ Complete |
| 2 | Boundary decision + gap downloads | ✅ Complete |
| 3 | Reserve boundary layer | ✅ Complete |
| 4 | Census time series extracted (all reserves) | ✅ Complete |
| 5 | Census joined to boundaries + area overwrite | ✅ Complete |
| 6 | Growth metrics table | ✅ Complete |
| 7 | Growth visuals + roll-up | ✅ Complete |
| 8 | Covariate stack (Stage 2 start) | ✅ Complete |
| 9 | Resistance surfaces (Decisions 11–16) | ✅ Complete |
| 10 | Least-cost paths + variant comparison | ✅ Complete |
| 11 | Reserve network graph (Decision 19) | ✅ Complete |
| 12 | Pinch points + network figure (Decision 20) | ✅ Complete |
| 13–16 | Suitability track | In progress — Week 13 complete (Decisions 21–22; outcome `no_1km_model`; committed 2026-10-18). **Week 14 complete (2026-10-25)** — Decision 23, a model at the 0.2° grain on the obscured set; `scripts/09`; the count: `planned_model` (104 presence cells, 1,486 background cells); Decision 24 (the model settings); the fit: `lq`, multiplier 1, mean test Boyce 0.668 over 5 spatial folds; QA 133 of 133; the commit by the author (task 14.8). **Week 15:** tasks 15.1–15.2 done (2026-10-31) — Decision 25 (the prediction and its published form; point 9 added in task 15.2) and the process choices; task 15.3 done (2026-11-01) — the prediction; the gate open; task 15.4 done (2026-11-01) — the reserve check: r1 "agrees"; task 15.5 done (2026-11-01) — QA 84 of 84. **Week 15 complete (2026-11-01)**; the commit (task 15.7) by the author. **Week 15 committed** (`7ae300a`). **Week 16:** task 16.1 done (2026-11-07) — Decision 26 (the Gi* settings). Task 16.2 done (2026-11-07) — the process choices and Amendment 1 of Decision 26. Task 16.3 done (2026-11-07) — STEP 16.1, the four Gi\*. Next: task 16.4 (the figures) |
| 17–20 | Site + close | ⚪ Not started |
