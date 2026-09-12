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
| **4** | Census extraction — part 1 | ~half of reserves entered into the census time series; **Decision:** missing-year handling | 3–4 h |
| **5** | Census extraction — part 2 | All available reserves entered; census joined to boundaries | 3–4 h |
| **6** | Growth metrics | `03` output: `tbl_01_reserve_growth.csv` (change, %, AAGR, density) | 2–3 h |
| **7** | Growth visuals + roll-up | `04` outputs: ranking figure, regional roll-up table, animated choropleth | 3–4 h |

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

### Week 4 — task breakdown

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

---

## Stage 2 — Connectivity (Weeks 8–12) · priority 2

| Week | Focus | Exit state (deliverable) | Est. |
|---|---|---|---|
| **8** | Covariate stack | `06` output: land cover, terrain, gHM, dist-to-road aligned to a 1 km grid | 3–4 h |
| **9** | Resistance surface | **Decision:** resistance values (numbered); `07` resistance raster | 2–3 h |
| **10** | Least-cost paths | LCPs between neighbouring reserve pairs | 3–4 h |
| **11** | Reserve network graph | `igraph` metrics: betweenness (linchpins), components (isolated reserves) | 3–4 h |
| **12** | Pinch points + visuals | Road-crossing pinch points; `fig_04` network figure; `tbl_03` metrics | 3–4 h |

---

## Stage 3 — Habitat suitability (Weeks 13–16) · priority 3

| Week | Focus | Exit state (deliverable) | Est. |
|---|---|---|---|
| **13** | Occurrence + effort | `05` outputs: cleaned occurrences, target-group background, KDE | 3–4 h |
| **14** | SDM fit | `08`: `maxnet` fitted with bias correction; model saved | 3–4 h |
| **15** | Predict + validate | National suitability surface; validation against reserves; publish-floor gate | 3–4 h |
| **16** | SDM visuals | `fig_05` suitability map with effort caveat | 2–3 h |

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
| **Growth track complete** | 7 | Priority-1 deliverable done and publishable |
| Connectivity track complete | 12 | Priority-2 deliverable done |
| Suitability track complete | 16 | Priority-3 deliverable done |
| **Site published** | 20 | Full project live |

---

## Risk management (pace-specific)

| Risk | Likelihood | Effect | Response |
|---|---|---|---|
| All-reserve census extraction is slower than 2 weeks | High | Stage 1 slips | Extraction is the natural stop-and-resume task; split across more weeks freely |
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
| 4–5 | Census time series (all reserves) | ⚪ Not started |
| 6 | Growth metrics table | ⚪ Not started |
| 7 | Growth visuals + roll-up | ⚪ Not started |
| 8–12 | Connectivity track | ⚪ Not started |
| 13–16 | Suitability track | ⚪ Not started |
| 17–20 | Site + close | ⚪ Not started |
