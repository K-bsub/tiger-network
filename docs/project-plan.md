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
| **10** | Least-cost paths | `scripts/07_connectivity.R` LCP STEPs: LCPs between neighbouring reserve pairs; **plus the Decision-14/15 sensitivity comparison** (baseline vs `noghm`, `road15`, `road50`; metric fixed before any variant's paths are examined) | 3–4 h |
| **11** | Reserve network graph | `scripts/07_connectivity.R` graph STEPs: `igraph` metrics — betweenness (linchpins), components (isolated reserves) | 3–4 h |
| **12** | Pinch points + visuals | `scripts/07_connectivity.R` pinch-point STEPs: road-crossing pinch points; `fig_04` network figure; `tbl_03` metrics | 3–4 h |

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

### Week 10 — task breakdown

Entry state (as of Week-9 close): four resistance surfaces on the 1 km EPSG:7755
grid in `data/processed/` — `resist_tiger_baseline_7755.tif` and the variants
`noghm` (k = 0), `road15`, `road50` (Decisions 14–16); values 1–100, `NA` only
on the 98 cells outside the complete-case footprint. Reserve geometry for 55 of
58 reserves (`boundary_reserves_all_7755.gpkg`; Amrabad, Pilibhit and
Dholpur-Karauli have none). The 59 NTCA corridor polygons
(`boundary_corridors_7755.gpkg`). **Raised, not decided** (methodology →
Decisions pending → "[Week 10] Least-cost-path set-up"): reserve pairs, path
method and tool, geometry-absent reserves, variant comparison metric.

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
| 10.1 | **Set-up Decision (numbered — Decision 17), before any path.** Research, raise the forks, record the choices: (a) which reserve pairs are "neighbouring" (for example k nearest neighbours, a distance limit, or a Delaunay/Gabriel graph of reserve polygons); (b) path method and tool (`leastcostpath` or `gdistance`; 8 or 16 neighbours; cost = resistance × distance with diagonal correction); (c) where a path starts and ends (the polygon edge — nearest boundary cells — or a point); (d) the 3 geometry-absent reserves; (e) whether to compare baseline paths with the NTCA corridor polygons (descriptive only) | Decision 17 recorded in methodology; settings in `R/00_config.R` | 45–60 min |
| 10.2 | **Comparison-metric Decision (numbered — Decision 18), before any variant path is examined.** How a variant's path differs from the baseline's for the same pair: for example the share of baseline path length within 1 km of the variant path, the change in cost-distance rank across pairs, and the pairs whose route changes corridor. Fix the metric and what counts as a "material" change | Decision 18 recorded; settings in config | 20–30 min |
| 10.3 | Tool check: install and lock the chosen package (`renv::snapshot()`); smoke-test **one** baseline pair for runtime and memory on the national grid (and on a cropped window, if Decision 17 allows cropping) | Package locked; one path runs; runtime per pair known | 20–30 min |
| 10.4 | STEP 10.1 in `scripts/07`: build the reserve pairs per Decision 17 → `tbl_12_reserve_pairs.csv` (pair id, from/to `unit_id` and name, straight-line gap between polygons in km) | Pair table written; every pair has two reserves with geometry | 20–30 min |
| 10.5 | STEP 10.2: least-cost paths on the **baseline** for every pair → `lcp_reserve_network_7755.gpkg`, layer `baseline` (pair id, from/to, cost-distance, path length km, ratio path length / straight gap). Read the surface from disk; values from config | Baseline paths written; read back and checked | 45–60 min |
| 10.6 | STEP 10.3: path QA → `tbl_12_lcp_qa.csv` — every pair has a path or a stated reason (for example blocked by `NA` cells or the grid edge); paths lie inside the footprint; no path starts or ends in the wrong reserve; if cropping is used, no path touches the crop edge (re-run wider if it does) | QA table written; every pair accounted for | 30 min |
| 10.7 | STEP 10.4: the same pairs on `noghm`, `road15`, `road50` → layers in the same GeoPackage; apply the Decision-18 metric → `tbl_12_lcp_variant_comparison.csv` | Variant paths written; comparison table written by the pre-fixed metric | 40–60 min |
| 10.8 | *(If Decision 17 includes it)* Descriptive overlap of baseline paths with the 59 NTCA corridor polygons → `tbl_12_lcp_ntca_overlap.csv`. Not a validation: the NTCA corridors come from a different method (Qureshi et al. 2014) | Overlap table written, or task marked not applicable | 20–30 min |
| 10.9 | Update `data-dictionary.md` (paths layer, `tbl_12_*`), `methodology.md` (Decisions 17–18 + Week-10 change log), `README.md`/handoff (Week 10 status, entry point for Week 11) | Docs match as-built | 20 min |
| 10.10 | Commit (`analysis:` for `07` + paths/QA tables; `docs:` separate) | Committed and pushed | 10 min |

**Week 10 pitfalls:**
- **Decisions before the paths.** Decisions 17 and 18 are fixed before any
  path is examined; Decision 18 before any **variant** path is run. Do not look
  at variant paths and then choose the metric.
- **Resistance vs conductance.** `gdistance` works in conductance (1 /
  resistance) and needs a geographic correction for diagonal steps;
  `leastcostpath` takes resistance and handles it internally. Check the units
  of the cost-distance before comparing pairs.
- **`NA` cells are walls.** The 98 `NA` cells (mostly water) cannot be crossed.
  A pair with no path must be reported, not silently dropped.
- **The grid ends 5 km outside India.** Paths cannot go through Nepal,
  Bhutan, Bangladesh or Myanmar. Transboundary links (Valmiki–Chitwan,
  Manas–Royal Manas, the Sundarbans) are under-represented — record it as a
  limitation.
- **Cropping can cut off the true path.** If a pair is solved on a cropped
  window for speed, the window must be wide enough; a path that touches the
  crop edge must be re-run wider (task 10.6).
- **Polygon edge vs point.** Starting from a centroid adds cost inside the
  reserve and favours large reserves; starting from the polygon edge measures
  the gap between reserves. Decision 17 fixes it.
- **Busy farmland is already ≥ 30.** In the baseline, 41.4 % of cells are at or
  above the road value, so paths through farmland may not avoid roads. Read the
  `noghm` comparison before interpreting the baseline routes.
- **Memory.** A transition matrix for 8.9 million cells with 16 neighbours is
  large. The task-10.3 smoke test shows whether the national grid fits.
- **PROJ `proj.db` clash still applies** — fresh session.

**Decisions due this week:** **17** (LCP set-up) and **18** (variant comparison
metric), both numbered and both before the paths they govern.

**Exit state:** `lcp_reserve_network_7755.gpkg` with one layer per surface;
`tbl_12_reserve_pairs.csv`, `tbl_12_lcp_qa.csv`,
`tbl_12_lcp_variant_comparison.csv` written; every pair accounted for. Ready for
Week 11 (network graph). Docs updated; Week 10 ticked.

---

## Stage 3 — Habitat suitability (Weeks 13–16) · priority 3

**Script note (2026-09-26):** the header-only stubs `08_habitat_suitability.R`
and `09_build_site.R` were deleted. Stage 3 starts a new script at the next free
number (`08`) in Week 13; the site-build script (Stage 4) takes the number after
that. Each is named (naming §3, `NN_verb_object.R`) when its stage starts.

| Week | Focus | Exit state (deliverable) | Est. |
|---|---|---|---|
| **13** | Occurrence + effort | `scripts/08_<verb_object>.R` (new script, named at Week 13) outputs: cleaned occurrences, target-group background, KDE | 3–4 h |
| **14** | SDM fit | `scripts/08`: `maxnet` fitted with bias correction; model saved | 3–4 h |
| **15** | Predict + validate | National suitability surface; validation against reserves; publish-floor gate | 3–4 h |
| **16** | SDM visuals | `fig_05` suitability map with effort caveat | 2–3 h |

**Pending, not yet scheduled (raised with Decision 14):** after the SDM exists,
an SDM-based resistance surface (1 − suitability) and a circuit-theory run
between reserves, to reproduce the national method and check the Stage-2 paths.
Transform and tool are decided then (see `methodology.md`, Decisions pending).

---

## Stage 4 — Story site and close (Weeks 17–20)

| Week | Focus | Exit state (deliverable) | Est. |
|---|---|---|---|
| **17** | Site skeleton | Quarto site structure; one page per track; navigation | 3–4 h |
| **18** | Leaflet maps | Interactive maps wired in (reuse Bay Area Leaflet recipe) | 3–4 h |
| **19** | Narrative + QC | Author-written narrative; figure alt text; accessibility pass | 3–4 h |
| **20** | Publish + docs close | Site deployed to GitHub Pages; final report; decision log closed | 3–4 h |

---

## Milestone summary

| Milestone | Target week | Meaning |
|---|---|---|
| Scaffold committed to GitHub | 0 | Version-controlled, data-free base to build on |
| Data audited and gaps closed | 2 | Know exactly what must be rebuilt |
| **Growth track complete** | 7 | ✅ Achieved Week 7 — priority-1 deliverable done and publishable (tbl_01, tbl_02, fig_01, fig_02) |
| Connectivity track complete | 12 | Priority-2 deliverable done |
| Suitability track complete | 16 | Priority-3 deliverable done |
| **Site published** | 20 | Full project live |

---

## Risk management (pace-specific)

| Risk | Likelihood | Effect | Response |
|---|---|---|---|
| All-reserve census extraction is slower than 2 weeks | ~~High~~ **Retired** | Stage 1 slips | Did not materialise — the full within-reserve series was extracted in Week 4 (2014/2018/2022 is only 3 tabular rounds, not 5). Week 5 is now the join, not more extraction |
| WII TR boundaries not public | Medium | Weaker boundary layer | KBA fallback, documented (Decision) |
| Weeks slip due to job load | High | Calendar stretches | Expected. Each week is self-contained; no penalty for a gap |
| SDM adds little beyond growth + connectivity | Medium | Wasted effort | Priority 3 by design — drop it if Stage 1–2 already tell the story |
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
| 10 | Least-cost paths + variant comparison | ⚪ Not started |
| 11–12 | Network graph + pinch points | ⚪ Not started |
| 13–16 | Suitability track | ⚪ Not started |
| 17–20 | Site + close | ⚪ Not started |
