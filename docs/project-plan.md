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
| 2 | Boundary decision + gap downloads | ⚪ Not started |
| 3 | Reserve boundary layer | ⚪ Not started |
| 4–5 | Census time series (all reserves) | ⚪ Not started |
| 6 | Growth metrics table | ⚪ Not started |
| 7 | Growth visuals + roll-up | ⚪ Not started |
| 8–12 | Connectivity track | ⚪ Not started |
| 13–16 | Suitability track | ⚪ Not started |
| 17–20 | Site + close | ⚪ Not started |
