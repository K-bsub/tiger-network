# Handoff — India's Tiger Network

**What this is:** the single rolling context document for this project. One chat
per week. At the **start** of a week's chat, paste or attach this file so the
assistant has full context. At the **end**, update the "Current state" and "Log"
sections and commit. This file is the memory between chats — keep it truthful.

**How to update:** edit "Current state" to match reality, add a dated entry to
the "Log", tick the week off in `project-plan.md`, then commit both together
(`docs: update handoff after Week N`).

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
- **Fixed Decisions (see `docs/methodology.md`):** D1 suitability not occupancy;
  D2 reserve unit rolled up; D3 CRS 7755.

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
  generalised to ≥1 km; gate publish exports through the assert functions.

---

## Current state  ·  updated after **Week 2** (boundary Decision + all data acquired)

- **Done:** Toolchain verified — `00a` runs clean (GDAL 3.12.1 / GEOS 3.14.1 /
  PROJ 9.7.1; EPSG:7755 resolves to "WGS 84 / India NSF LCC"). `renv`
  initialised and snapshotted (124 packages linked; R 4.5.2 pinned in
  `renv.lock`). Data audit run — `00b` reports **all 13 datasets MISSING**;
  `outputs/tables/tbl_00_data_audit.csv` written. Week 1 marked complete in
  `project-plan.md`; Week 2 task breakdown (2.1–2.9) added.
- **On disk:** scaffold + `renv` library. **`data/raw/` deliberately left
  empty.** Surviving Phase 1 files (NTCA census, ISFR forest, corridors) cover
  **7 reserves only** / wrong edition (ISFR 2017, not 2021), so they are not
  usable for an all-reserve analysis and were not staged. `data/raw/` empty is
  the correct state — the audit therefore reports the true gap.
- **Active week:** **Week 2 complete.** Boundary Decision made (Decision 4);
  Decision 5 (Mammalia target group) recorded; **all data acquired** (12/14
  manifest PRESENT — the 2 MISSING are the rejected KBA/WDPA sources). `00b`
  re-run confirms. **Next: Week 3** — (a) download the five NTCA census reports
  (task 3.1 — not done in Week 2); (b) build the reserve boundary layer
  (`scripts/02`): parse the NTCA DSS KML to reserve polygons, resolve the 3
  unmatched + 2 false-matched reserves by hand, attach unit_id / state /
  landscape_complex, and set area from the NTCA census (not the polygon, per
  Decision 4).

### Data acquired so far (tasks 2.4 + 2.5, via `scripts/01`)

All on the 1 km EPSG:7755 grid where raster; `00b` shows PRESENT for each.
- **GBIF tiger occ** — 4,606 pts in India (DOI 10.15468/dl.npxmxx). Median coord
  uncertainty ~30 km — heavy cleaning drop expected in Week 13.
- **GBIF Mammalia background** — 39,057 pts, 2006–2022 (DOI 10.15468/dl.2d523e).
- **WorldCover 2021** — 1 km modal class (all 11 classes present).
- **gHM 2022** — 1 km, mean 0.377 (windowed read; leaves only a source stamp in
  raw, so its manifest glob points at `*stamp*.txt`).
- **OSM** — roads 885,669 (major, tertiary-dominated); settlements 199,800
  (**village-dominated ~195k** — likely needs trimming for the KDE, see pending
  Decisions).
- **Terrain** — elevation/slope/TRI, 1 km (elevatr AWS z7; slope/TRI derived on
  native DEM). Coverage verified full-India.
- **Admin boundaries** — Natural Earth states (36) + DataMeet Census-2011
  districts (641), scripted (Block 8). Districts are pre-redistricting vintage.
- **Manual (fetched by hand):** ISFR 2021 Ch.4, Singh & Sen 2015. **NOT
  fetched:** the five NTCA census reports (2006–2022) — moved to Week 3 (task
  3.1). The `ntca_census` PRESENT in `00b` is a stray/7-reserve file, not the
  All-India Tiger Estimation rounds.

**Manifest note:** windowed/streamed pulls (GBIF zips, gHM stamp) and the
osmextract/elevatr outputs needed manifest glob/subpath fixes to audit PRESENT —
the default globs assumed conventional download-to-disk files. All reconciled.

### Boundary Decision (made Week 2 — Decision 4)

- **Chosen:** NTCA DSS `PA_TR_Corridor_Final` KML as the single geometry source
  for reserves + corridors. Reserve **area/density come from the NTCA census
  total, not the KML polygon** (the polygon is the core PA, ~55% below legal
  total).
- **Why the alternatives lost:** WII authoritative layer not publicly
  downloadable; **WDPA holds zero Indian national PAs** (Ramsar/WHS only —
  verified from the country profile); KBA covers fewer reserves (51 vs 55), has
  the same core-PA area limit, and no corridors.
- **Provenance:** already documented in the Phase-2 project's `data-sources.md`
  (NTCA DSS, July 2022, GoI licence). Raw at
  `data/raw/ntca/PA_TR_Corridor_Final/`.
- **Carried gaps (fix in Week 3):** 3 reserves not name-matched (Amrabad,
  Pilibhit, Dholpur-Karauli); 2 false matches (Bor→Great Himalayan NP,
  Kamlang→Namdapha-Kamlang).

### Open pending Decisions (decide in the week noted)

Full text in `methodology.md` → "Decisions pending".
- **[Week 4]** Missing-year census handling (the Kaziranga-2006 problem, at scale).
- **[Week 8–9]** Settlement layer for the KDE — village-dominated (~195k);
  trim to city/town (4,597) or change radius?
- **[Week 9]** Land-cover resistance values (starting set in `R/00_config.R`).
- **[Week 9]** Road classes for the barrier surface — keep tertiary or restrict
  to motorway–secondary?
- **[Week 13–14]** Target-group scope — all Mammalia vs large-bodied guild.
- **[Week 14]** Terrain variables in the SDM — collinearity check (slope vs TRI).

### Known gotchas (do not relearn)

- **First GitHub Pages publish:** the Action deploys to `gh-pages` but cannot
  create it. Bootstrap the branch once from the **Terminal tab** (not R
  console): `quarto publish gh-pages site`. Do **not** use
  `quarto::quarto_publish_site(server="gh-pages")` — that R wrapper targets
  Posit Connect and misreads `gh-pages` as a hostname.
- **`rlang` lock:** if a package update says "cannot remove prior installation"
  or "namespace already loaded, >= X required", restart R and run
  `install.packages()` as the **first** action, before anything auto-loads it.
- **`gh-pages` branch shows source as "deleted":** correct. That branch holds
  only rendered HTML; source stays on `main`.
- **`00b` reads `data/data_manifest.csv`** as the expected inventory (not
  `data-sources.md`).
- **The audit checks file *presence*, not *coverage*.** A `PRESENT` result means
  "a matching file exists in the folder", nothing more. When real data is staged
  in Week 2+, do not read a `PRESENT` on `ntca_census` as "the census is done" —
  the all-reserve census is manual extraction (Weeks 4–5) and the audit cannot
  see whether a file holds 7 reserves or all of them.
- **`00b` glob is recursive and case-insensitive.** A stray matching file in a
  nested subfolder still counts as `PRESENT`. Keep `data/raw/<subfolder>/` clean
  so a leftover file does not create a false `PRESENT`.
- **PROJ / PostGIS `proj.db` clash (this machine).** PostgreSQL 16 / PostGIS 3.6
  puts an old `proj.db` on PATH
  (`C:\Program Files\PostgreSQL\16\share\contrib\postgis-3.6\proj\proj.db`,
  LAYOUT.VERSION.MINOR = 2 — an ancient PROJ). GDAL/terra load that instead of
  their own, so **every reprojection to EPSG:7755 fails** with `empty srs` /
  `[project] cannot get output boundaries for the target crs`. This is NOT a code
  bug — the CRS engine is reading a corrupt database. Fix: pin `PROJ_LIB` to
  terra's bundled `proj.db` in the project `.Rprofile`, set **before** terra
  loads (after `renv/activate.R`). Verify in a fresh session with
  `crs(rast(crs="EPSG:7755"))` — it must print the "India NSF LCC" WKT. The env
  var must be set in a clean session; setting it after terra is already loaded
  does not take (PROJ caches the path at first use).

---

## Weekly log (newest first)

### Week 2 (part) — Admin boundaries + Week-2 close · 2026-09-07
- Entry state: covariates + boundary KML acquired; admin + manual downloads
  pending.
- Did: added `scripts/01` Block 8 — Natural Earth states (36) + DataMeet
  Census-2011 districts (641), scripted, reprojected to 7755. Fetched the manual
  PDFs by hand (ISFR 2021 Ch.4, Singh & Sen 2015). **Did NOT download the NTCA
  census reports** — deferred to Week 3 (task 3.1). Re-ran `00b`: **12/14
  PRESENT** (the 2 MISSING are the rejected KBA/WDPA sources — by design). Fixed
  admin/terrain/settlement manifest globs. `renv::snapshot()` (adds osmextract,
  elevatr, rnaturalearthhires). Confirmed no data staged for commit.
- Decisions made: none new (Decisions 4 + 5 already logged; 4 new pending
  Decisions added to methodology this week).
- Outputs: admin boundary layers; updated `data-sources.md`, `references.md`,
  `methodology.md`, `data_manifest.csv`, `project-plan.md` (Week 2 ✅), this
  handoff.
- Gotchas found: `ne_states()` needs `rnaturalearthhires` (not on CRAN — install
  from `https://ropensci.r-universe.dev`). Streamed/windowed pulls and
  osmextract/elevatr outputs needed manifest glob fixes to audit PRESENT (the
  default globs assume download-to-disk files).
- Carried forward / next week: **Week 3** — download the five NTCA census
  reports (task 3.1); build the reserve boundary layer from the KML
  (`scripts/02`); resolve the 3 unmatched + 2 false-matched reserves.

### Week 2 (part) — Scripted data downloads · 2026-09-07
- Entry state: boundary Decision made; `data/raw/` otherwise empty.
- Did: wrote and ran `scripts/01` blocks 1–7 — India boundary (Natural Earth),
  GBIF tiger occ + Mammalia background, WorldCover (1 km modal), gHM 2022 (1 km),
  OSM roads + settlements (Geofabrik via osmextract), terrain (elevatr AWS z7,
  elevation/slope/TRI). All covariates on the 1 km EPSG:7755 grid. Verified
  terrain covers full India. Fixed several manifest glob/subpath mismatches so
  `00b` audits the streamed/windowed pulls correctly (6 PRESENT).
- Decisions made: none numbered this entry (Decision 5 — Mammalia target group —
  was logged with the GBIF work). Several forks surfaced for end-of-week
  pending Decisions: road classes, settlement filtering, terrain variable
  selection.
- Outputs: interim covariate layers (`cov_landcover_..._1km_7755.tif`,
  `cov_ghm2022_1km_7755.tif`, `cov_terrain_1km_7755.tif`), raw GBIF/OSM/terrain,
  updated docs + manifest.
- Gotchas found: **PROJ/PostGIS `proj.db` clash** (see Known gotchas — cost most
  of this session; fixed via `.Rprofile` PROJ_LIB pin). WorldCover 10 m national
  reproject fails / is far too slow — reproject each tile to a 1 km template
  instead. osmextract needs `max_file_size` raised for the 1.5 GB India pbf, and
  an interrupted convert leaves a locked `.gpkg` (delete it + restart R).
- Carried forward / next week: manual downloads (2.6); then re-audit, commit,
  and write the end-of-week pending Decisions.

### Week 2 (part) — Boundary-source Decision · 2026-09-07
- Entry state: `00a` clean; `renv` locked; `data/raw/` empty; `00b` all 13
  MISSING; boundary source not chosen.
- Did: ran task 2.1 (boundary feasibility). Verified three candidate sources
  against the 58 official reserves. **WII** authoritative layer not publicly
  downloadable. **WDPA** holds zero Indian national PAs (India country profile:
  "national designations only = 0"; the extract is Ramsar/WHS only, 63 polygons)
  — rejected. **KBA** 51/58, core-PA area only, no corridors. **NTCA DSS KML**
  55/58 + corridors, core-PA area only. Chose the KML (Option C): geometry from
  KML, area/density from the NTCA census. Recovered KML provenance from the
  Phase-2 project docs (no re-download needed).
- Decisions made: **Decision 4 — Reserve boundary source and area basis**
  (methodology.md).
- Outputs: `scripts/00c_verify_wdpa_boundaries.R`,
  `outputs/tables/tbl_00_kba_tr_match.csv`. Updated `methodology.md`,
  `data-sources.md`, `data/data_manifest.csv`, `README.md`, this handoff.
- Gotchas found: WDPA India national layer does not exist publicly — do not
  re-attempt. KBA and the NTCA KML both store the **core PA polygon, not the
  legal TR extent** — never derive reserve area from either geometry.
- Carried forward / next week: finish Week-2 downloads (tasks 2.4–2.9); in
  Week 3 fix the 3 unmatched + 2 false-matched reserves when building the
  boundary layer.

### Week 1 — Setup + data audit · 2026-09-06
- Entry state: scaffold on `main`; `gh-pages` live (placeholder site); no data
  re-acquired; `renv` not initialised; no analysis.
- Did: ran `00a` (toolchain clean — GDAL 3.12.1 / GEOS 3.14.1 / PROJ 9.7.1;
  EPSG:7755 resolves). Reviewed prior-project disk contents; decided the
  surviving Phase 1 files (7-reserve census, ISFR 2017, 7-reserve corridors) are
  not usable for an all-reserve analysis, so left `data/raw/` empty. Ran `00b`
  audit (all 13 MISSING — the honest baseline). Ran `renv::init()` + `snapshot()`
  (124 packages; R 4.5.2 pinned).
- Decisions made: (none numbered; note the working call to reject Phase 1 data
  as insufficient — logged here, not a methodology Decision)
- Outputs: `outputs/tables/tbl_00_data_audit.csv`, `renv.lock`
- Gotchas found: audit checks presence not coverage; `00b` glob is recursive +
  case-insensitive (see "Known gotchas").
- Carried forward / next week: Week 2 closes the data gap the audit found and
  makes the **boundary-source Decision** (WII TR vs KBA fallback).

### Week 0 — Scaffolding · 2026-09-06
- Built the full repo scaffold in R (config, IO + sensitive functions, 11
  numbered script stubs, 8 docs, Quarto site, GitHub Action).
- Fixed Decisions 1–3.
- Committed and pushed `main`; bootstrapped `gh-pages`; site live with
  placeholder pages.
- **Carried forward:** three pending Decisions (Weeks 2/4/9); data audit is the
  Week 1 job.

---

## Template — copy this block for each new week

```
### Week N — <topic> · <date>
- Entry state: <what existed at the start>
- Did: <what was completed>
- Decisions made: <numbered Decisions added to methodology.md, if any>
- Outputs: <files produced>
- Gotchas found: <anything worth not relearning>
- Carried forward / next week: <what Week N+1 starts from>
```
