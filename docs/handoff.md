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
  D2 reserve unit rolled up; D3 CRS 7755; D4 NTCA KML geometry, census area;
  D5 Mammalia target group; **D6 census series = within-reserve SECR 2014/2018/2022
  only (2006/2010 are context, not a baseline)**; **D7 missing (reserve, round)
  cells = `NA`, no imputation**; **D8 reserve area = NTCA-notified core+buffer
  total (ISFR-2021 Ch.4 is cross-check only, not the area source)**.

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

## Current state  ·  updated after **Week 7** (growth visuals + roll-up — Stage 1 done)

- **Done this week:** `scripts/05_growth_analysis.R` (tasks 7.1-7.6) built the
  regional roll-up and the two growth figures, all reading
  `stats_reserve_census_7755.gpkg` only (no new data, no new Decision). Wrote
  **`outputs/tables/tbl_02_regional_rollup.csv`** (23 rows),
  **`outputs/figures/fig_01_growth_ranking.png`**, and
  **`outputs/figures/fig_02_growth_animation.gif`**. The 7.6 verification block
  (STEP 7) passes all 13 checks. **Stage 1 (Growth) is complete and publishable.**
  Docs updated: `data-dictionary.md` (tbl_02 schema + fig_01/fig_02 notes),
  `project-plan.md` (Week 7 ✅ + Week 8 breakdown), `README.md`, this handoff.
- **Script structure of `scripts/05`:** STEP 1 read+guard; STEP 2 the roll-up
  rule (recorded inline); STEP 3 `rollup_by()` engine; STEP 4 write tbl_02;
  STEP 5 fig_01; STEP 6 fig_02 (with a renderer fallback); STEP 7 the 7.6
  verification block. It reads the stats layer only and writes nothing back to it.
- **Roll-up rule (the analytical choice this week):** absolute fields
  (`pop_2014/2018/2022`, `change_abs`) are summed over **non-`NA` reserves only**,
  with a **coverage count per field** (`n_pop_2014`, `n_pop_2018`, `n_pop_2022`,
  `n_change_abs`) plus `n_reserves` and `n_measured`. Ratio fields (`change_pct`,
  `aagr`) are **recomputed on the summed pops**, never averaged from per-reserve %.
  Numerator and denominator use the SAME contributor set (valid two-round span,
  not `growth_zero_flag`). Regional `aagr` is annualised over a
  `pop_baseline`-weighted mean span (`span_region`); `change_pct` is primary. Left
  inline (not a numbered Decision) — uncontested.
- **tbl_02 as built:** 5 landscape complexes + 18 states. Landscape picture:
  Central India +282 (+59.7%, aagr +6.1%/yr), Shivalik-Gangetic +239 (+58.9%,
  +6.3%/yr), Western Ghats +108 (+19.8%, +2.3%/yr), North-East Hills +22 (+13.2%,
  +1.7%/yr), Sundarbans NA (its one reserve is `pop_2022` `NA`).
- **fig_01:** reserves ranked by `change_pct` (default; `RANK_METRIC` switches to
  `change_abs`/`aagr`), faceted by landscape (top strips, alternating region
  wash), fill = growth sign. 48 ranked, 10 not-ranked (NA ratio) shown separately
  as a per-facet "(N not ranked)" count. Sundarbans facet (0 ranked) dropped from
  the plot, reported in console. Effort caveat wrapped in the caption.
- **fig_02:** 3-frame choropleth (2014/2018/2022, Decision 6) via
  `transition_manual` (fixed geometry — polygons do not move). Per-round tiger
  count binned with fixed breaks. Three classes kept distinct: `NA` pop → grey
  **"No estimate"**; real within-reserve 0 → near-white **"0 (real)"** (Decision
  9); 3 geometry-absent reserves (Amrabad, Pilibhit, Dholpur-Karauli) named
  off-map, **never drawn as 0**. Per-frame class counts: No-estimate 11/7/5,
  "0 (real)" 1/3/5 across the rounds.
- **7.6 verification (all OK):** roll-up reconciles across both groupings and the
  per-reserve `na.rm` sum (pop_2014 1586, pop_2018 1958, pop_2022 2257, change_abs
  +651; n_measured 53); frames = 3 = {2014,2018,2022}; every `NA`-pop cell is
  "No estimate" (never a number) and every "0 (real)" cell is a measured 0; the
  `growth_zero_flag` reserve (Mukundara) is absent from the ranked bars, shown as
  not-ranked, and its `change_abs` is +1 (not a decline).
- **Next: Week 8** — **Stage 2 (Connectivity) starts.** Build
  `scripts/06_build_covariate_stack.R`: one aligned 1 km EPSG:7755 covariate stack
  (`cov_stack_1km_7755.tif`) from the Week-2 layers (WorldCover, gHM, terrain,
  distance-to-road). Assembly/alignment only — the resistance-value and
  barrier-road-class Decisions are Week 9. See `project-plan.md` → Week 8
  breakdown. No census dependency in Stage 2.

### Output files this week (under `outputs/`)

- `outputs/tables/tbl_02_regional_rollup.csv` — the Week-7 roll-up table (23 rows).
- `outputs/figures/fig_01_growth_ranking.png` — the ranking figure.
- `outputs/figures/fig_02_growth_animation.gif` — the 3-frame choropleth.
- No change to `data/processed/` this week — `scripts/05` reads the stats layer,
  writes nothing back to it. (The three `fig_02_frame_*.png` files are a
  fallback-only output when gganimate/gifski are missing; they were removed after
  the GIF rendered — do not commit them.)
- New dependency locked in `renv.lock`: **`gifski`** (the `fig_02` GIF renderer).

### Data on disk (from Week 2, via `scripts/01` — unchanged)

All on the 1 km EPSG:7755 grid where raster.
- **GBIF tiger occ** — 4,606 pts (DOI 10.15468/dl.npxmxx). Median coord
  uncertainty ~30 km — heavy cleaning drop expected in Week 13.
- **GBIF Mammalia background** — 39,057 pts, 2006–2022 (DOI 10.15468/dl.2d523e).
- **WorldCover 2021** — 1 km modal class (all 11 classes present).
- **gHM 2022** — 1 km, mean 0.377.
- **OSM** — roads 885,669 (major, tertiary-dominated); settlements 199,800
  (**village-dominated ~195k** — likely needs trimming for the KDE).
- **Terrain** — elevation/slope/TRI, 1 km (elevatr AWS z7). Full-India coverage.
- **Admin boundaries** — Natural Earth states (36) + DataMeet Census-2011
  districts (641). Districts are pre-redistricting vintage.
- **Manual PDFs:** ISFR 2021 Ch.4 (parsed for the Week-5 area cross-check),
  Singh & Sen 2015, and the five NTCA census reports (2006–2022, parsed Week 4).

### Boundary Decision (Decision 4 — settled Week 2, as-built Week 3)

- **Chosen:** NTCA DSS `PA_TR_Corridor_Final` KML as the single geometry source.
  Reserve **area/density come from the NTCA notified total, not the KML polygon**
  (the polygon under-states the legal total; as-built poly/census ratio ~0.58).
- **As-built refinements (Week 3):** the "2 false matches" (Bor, Kamlang) were
  name-lookup artefacts — both have correct in-state polygons and are matched.
  Real gaps are the 3 geometry-absent reserves (Amrabad, Pilibhit,
  Dholpur-Karauli). Corridors are **named polygons**, not unnamed centrelines.
- **Raw:** `data/raw/ntca/PA_TR_Corridor_Final/`.

### Open pending Decisions (decide in the week noted)

Full text in `methodology.md` → "Decisions pending".
- **[Week 8–9]** Settlement layer for the KDE — village-dominated (~195k);
  trim to city/town (4,597) or change radius?
- **[Week 9]** Land-cover resistance values (starting set in `R/00_config.R`).
- **[Week 9]** Road classes for the barrier surface — keep tertiary or restrict
  to motorway–secondary?
- **[Week 13–14]** Target-group scope — all Mammalia vs large-bodied guild.
- **[Week 14]** Terrain variables in the SDM — collinearity check (slope vs TRI).

_Resolved: [Week 4] missing-year handling → Decision 7; [Week 5] area source →
Decision 8; [Week 6] zero-baseline handling → Decision 9._
_Week 7 added no numbered Decision (the roll-up `NA` rule is an inline choice,
uncontested). **Two pending Decisions come due at Week 9** — land-cover resistance
values and barrier road classes; surface both at Week-8 close._

### Known gotchas (do not relearn)

- **NTCA KML — the GDAL driver mangles it; parse with `xml2`.** The KML
  `PA_TR_Corridor_Final.kml` (a) has its attribute fields (`DESIG`, `state_name`,
  `Corridor`) inside `SchemaData/SimpleData`, which the GDAL/LIBKML driver
  **drops** (an `st_read` shows only `Name`/`Description`/`geometry`), and (b) is
  split by the driver into **two layers** (`PA_TR_Corridors` = 764, `corridor` =
  156), so a plain `st_read` sees 764 features and no fields. `scripts/02`
  therefore parses the KML with **`xml2`** and rebuilds geometry from ring
  coordinates. Do not switch it back to `st_read`. Also: `st_as_sfc()` on a KML
  geometry snippet **returns empty geometries** for this file's
  MultiGeometry/altitudeMode structure — that path was tried and abandoned. New
  dependency: `xml2` (run `renv::snapshot()` if not already locked).
- **KML layer named `corridor` is NOT the corridors.** The GDAL `corridor` layer
  (156 features) holds the **unnamed duplicate** placemarks. The real corridors
  (59) sit inside the `PA_TR_Corridors` layer, tagged by the `Corridor` field.
- **`unit_name` is not a unique key.** Two `Pench` (MP + MH) and two
  `Rajiv Gandhi` (Karnataka + AP) exist in the KML. Any KML→reserve match must
  use **name + state**, never name alone. `scripts/02` does; keep it that way.
- **`area_km2` is the notified total from Week 5 on (`area_provisional = FALSE`).**
  Resolved: `scripts/03` overwrote it from `tbl_05_area_source_map.csv`
  (Decision 8). The overwrite changed zero values — the Week-3 placeholder already
  matched. Never derive area/density from `poly_km2` (the KML polygon).
- **`BASELINE_YEAR` in `R/00_config.R` is the GBIF download bound, NOT the census
  baseline.** It doubles as `scripts/01`'s YR_MIN (2006). Decision 6's census
  baseline is `CENSUS_BASELINE_YEAR` (2014). Do NOT set `BASELINE_YEAR` to 2014 —
  it would silently narrow the GBIF occurrence pull. The two were separated in
  task 5.9; keep them separate.
- **`census_reserve_long.csv` has a quoted `#` comment block before the header.**
  `read_csv(comment = "#")` does NOT strip quoted `#` lines — drop them by hand
  first (`raw[!str_detect(raw, '^\\s*"?#')]`), as `scripts/03` does. Same trap in
  pandas.
- **`density_2022` is per TOTAL notified area, not core-only.** It will not match
  an NTCA density figure that used core area (Corbett especially). Deliberate,
  per Decision 8 — consistent across all reserves.
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
- **2022 census table (Table I.3.3) — the PDF text layer is CORRUPT.**
  `pdftotext` on pages 28-29 returns column-scrambled garbage (reserve names and
  numbers do not line up). The 2022 values were transcribed from a **150-DPI page
  raster** (`pdftoppm`), read visually. Do not trust a text-extraction of that
  table; re-raster if you need to re-check a value. 2014 (Table 2.2) and 2018
  (Table 3.4) text layers are clean.
- **"Within" vs "utilising" — take WITHIN.** 2018 Table 3.4 and 2022 Table I.3.3
  each give two population columns per reserve: "tigers utilising the reserve"
  (larger, double-counts tigers shared between abutting reserves) and "tigers
  within the reserve". The series uses **within**. The 2018 report says so
  explicitly. Getting this wrong inflates every 2018/2022 figure.
- **2006/2010 have NO per-reserve table.** Do not go looking for one — it does
  not exist. Those rounds report at state × landscape-complex scale (Table ES.1);
  reserve numbers are only in landscape-chapter prose, partial, and a different
  spatial unit. This is why Decision 6 starts the series at 2014.
- **Singh & Sen (2015) is not a numeric source.** Its per-reserve bars (Figs
  9-16) are **normalised indices** (0-120 axis, captioned "Source: NTCA"), not
  counts — Corbett's ~100 bar vs its real 215 proves it. Useful for trend
  direction only. Do not read values off it.
- **Two Pench = two `unit_id` (23 MP, 33 MH).** Both print as "Pench" in every
  census table; disambiguate by the state column. The extraction did; the Week-5
  join must key on `unit_id`, never `unit_name`.
- **`-` or `0` in a census table is a real within-reserve zero**, not missing —
  enter `0` (Dampa, Kamlang, Kawal, Satkosia, Sahyadri, Palamau-2018,
  Buxa-2018). Missing = the row is simply absent (reserve not estimated that
  round).
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
- **`gganimate` `transition_states` tweens `geom_sf` geometry.** On a fixed-
  geometry choropleth the reserves appeared to morph/drift between frames because
  gganimate interpolated the polygon vertices. Use **`transition_manual(year)`**
  for any fixed-geometry animated map — it holds each state as a discrete frame,
  no vertex tween. `ease_aes` makes the wrong version worse; drop it. Label var
  becomes `{current_frame}` (not `{closest_state}`).
- **`gifski` is a separate install from `gganimate`.** `gganimate` was in `renv`;
  `gifski` (the default GIF renderer) was not, so `fig_02` fell back to 3 static
  PNGs. Fix: `renv::install("gifski")` (CRAN Windows binary — no Rust toolchain),
  then `renv::snapshot(packages = c("gganimate","gifski"))`. A bare
  `renv::snapshot()` may miss `gifski` because `scripts/05` calls it via
  `requireNamespace`, not `library` — name it explicitly in the snapshot.
- **`dplyr::summarise` name collision.** Expressions evaluate IN ORDER within one
  `summarise()`. An output column must NOT reuse an input column name that a later
  expression still reads: `pop_2022 = sum(pop_2022, ...)` then
  `n_pop_2022 = sum(!is.na(pop_2022))` counts the 1-length summary (=> n=1), not
  the group. `scripts/05` emits sums under `sum_*` names and renames only at the
  end. Watch for this in every roll-up.
- **`forcats` is not in `renv`.** `scripts/05` uses base `reorder()` for
  within-facet bar ordering, not `fct_reorder`. Do not add `forcats` just for one
  reorder. (`row_key` is unique per reserve, so base `reorder()` orders correctly
  inside a free-`y` facet.)
- **Roll-up: never average per-reserve percentages.** Sum the absolute pops per
  region, then compute the regional % on those sums (population-weighted).
  Averaging % over-weights small reserves. For a regional AAGR (spans differ,
  8 yr vs 4 yr), annualise over a `pop_baseline`-weighted mean span; report
  `change_pct` as primary.
- **`facet_wrap` has no `space="free_y"`.** Bar thickness therefore varies between
  facets in fig_01 (a 20-bar facet has thinner bars than a 7-bar facet). Cosmetic;
  `facet_grid(rows, space="free_y")` would equalise but loses the clean top strips.
  Left as-is for Week 7 (see the fig_01 cosmetic backlog for the story-map pass).

---

## Weekly log (newest first)

### Week 7 — Growth visuals + regional roll-up · 2026-09-20
- Entry state: `stats_reserve_census_7755.gpkg` carried all growth columns;
  `tbl_01_reserve_growth.csv` written (Week 6); `scripts/05_growth_analysis.R` was
  the renumbered header-only stub.
- Did (tasks 7.1-7.6, all in `scripts/05_growth_analysis.R`):
  - **7.1** rewrote the header/scope — fixed the frame count (the stub said "five
    census years"; Decision 6 fixes it to 3) and replaced the stale
    `# ... (fill in Week 4)` with `TODO(Week 7)` staging.
  - **7.2** `rollup_by()` for landscape complex and state; roll-up rule recorded
    inline (STEP 2): sum non-NA with a per-field coverage count; ratio recomputed
    on the summed pops, single contributor set; regional AAGR over a
    pop_baseline-weighted mean span.
  - **7.3** wrote `tbl_02_regional_rollup.csv` (23 rows); added `n_measured`.
  - **7.4** `fig_01` ranking, faceted by landscape, NAs shown separately, effort
    caveat wrapped in caption.
  - **7.5** `fig_02` 3-frame choropleth (`transition_manual`, fixed geometry);
    NA → grey "No estimate", real 0 → "0 (real)", 3 geometry-absent named off-map.
  - **7.6** STEP 7 hard-stopping verification block — all 13 checks OK.
- Decisions made: none (the roll-up NA rule is an inline choice, uncontested).
- Outputs: `scripts/05_growth_analysis.R` (filled), `tbl_02_regional_rollup.csv`,
  `fig_01_growth_ranking.png`, `fig_02_growth_animation.gif`; updated
  `data-dictionary.md`, `project-plan.md`, `README.md`, this handoff; `renv.lock`
  gains `gifski`.
- Gotchas found (now in "Known gotchas"): `transition_states` tweens `geom_sf`
  geometry → use `transition_manual`; `gifski` is a separate install from
  `gganimate`; `summarise` name-collision (summed col shadows the input a later
  expr reads); `forcats` not in `renv` → base `reorder()`; never average
  per-reserve % in a roll-up; `facet_wrap` has no `space="free_y"`.
- Data notes (not bugs): Sundarbans has a `pop_2022` `NA`, so it is grey in fig_02
  2022, absent from the fig_01 bars, and NA in the tbl_02 ratio — correct. Amrabad
  ranks in fig_01 (tabular) but is one of the 3 geometry-absent reserves, so it is
  named off-map in fig_02 (cannot be a polygon).
- Carried forward / next week: **Week 8** — Stage 2 (Connectivity) starts. Build
  `scripts/06_build_covariate_stack.R` → `cov_stack_1km_7755.tif` (WorldCover,
  gHM, terrain, distance-to-road on one 1 km EPSG:7755 template). Assembly only;
  the resistance-value + barrier-road-class Decisions are Week 9. Watch the
  categorical-vs-continuous resample rule and the PROJ `proj.db` clash.

### Week 6 — Growth metrics derived · 2026-09-19
- Entry state: `stats_reserve_census_7755.gpkg` built (Week 5) with
  `pop_2014/2018/2022`, notified `area_km2`, `density_2022`, `baseline_year`,
  `census_status`; growth columns not yet computed; Decision 9 pending.
- Did (tasks 6.1-6.8):
  - **6.1** - metrics go in a NEW `scripts/04_growth_metrics.R` (derive);
    renumbered the visuals stub `04_growth_analysis.R` -> `05_growth_analysis.R`.
  - **6.5 / Decision 9** - real within-reserve zeros: `change_abs` always valid;
    zero baseline -> `change_pct`/`aagr` `NA` + `growth_zero_flag`; real 2022 zero
    -> valid -100; never `Inf`/`NaN`.
  - **6.2** `change_abs` (non-`NA` 49); **6.3** `change_pct` + `growth_zero_flag`
    (non-`NA` 48; flag TRUE 1); **6.4** `aagr` over each reserve's own span
    (non-`NA` 48). **6.6** wrote `tbl_01_reserve_growth.csv` (58 reserves,
    sorted by `change_pct` desc). **6.7** whole-set verify (no `Inf`/`NaN`; NA
    pattern per Decisions 7/9; national split 32 growing / 17 declining).
    **6.8** appended the four columns to the stats layer + re-read round-trip.
- Decisions made: **Decision 9** (real within-reserve zeros in growth metrics).
- Outputs: `scripts/04_growth_metrics.R`, `scripts/05_growth_analysis.R` (renamed),
  `tbl_01_reserve_growth.csv`, updated `stats_reserve_census_7755.gpkg`;
  updated `methodology.md`, `data-dictionary.md`, `project-plan.md`, `README.md`,
  this handoff.
- Gotchas found: (1) the 6.2 done-when wording ("2022-only or NA pop_2022") is
  incomplete - a 2022-only reserve computes `change_abs = 0` unless you guard on
  SPAN, not just endpoints; guard on `baseline_year < 2022`. (2) Only **3**
  single-round reserves, not 4 - Navegaon-Nagzira has a 2014/2018 figure; trust
  the data-driven NA set, not the old planning list. (3) `growth_zero_flag` marks
  ONLY the zero-baseline case (ratio-undefined `NA`); a real 2022-zero decline is
  a valid -100, unflagged - do not blur the two.
- Carried forward / next week: **Week 7** - fill in `scripts/05_growth_analysis.R`
  (reads the stats layer): `fig_01` ranking, `fig_02` animated choropleth
  (3 frames, Decision 6), `tbl_02_regional_rollup.csv`. `NA`/geometry-absent
  reserves must render as a distinct "no estimate" class, never 0. Roll-up: sum
  absolute pops per region then recompute %, do NOT average per-reserve %.


### Week 5 — Census join, area overwrite, density, stats layer · 2026-09-13
- Entry state: `census_reserve_long.csv` extracted (Week 4); boundary layer with
  provisional `area_km2`; no stats layer.
- Did (tasks 5.1–5.9):
  - **5.1 + Decision 8** — located the reserve area source. Neither census report
    tabulates area; ISFR-2021 Ch.4 carries a WII digitized-boundary GIS area, not
    the notified total. Chose the NTCA-notified core+buffer total (consolidated
    notifications), ISFR as cross-check only. Built `tbl_05_area_source_map.csv`
    (58) + `tbl_05b_isfr_area_crosscheck.csv` (52). Notified total 84,507 vs NTCA
    stated 84,487.
  - **5.2** — `scripts/03` reads long, validates, pivots wide (53 reserves;
    45/50/53). **5.3** — left-join onto boundaries (58; 53 measured + 5 flagged;
    3 geometry-absent keep census). **5.4** — area overwrite (zero value change).
    **5.5** — density_2022 (52 values). **5.6** — baseline_year (45/5/3). **5.7** —
    wrote `stats_reserve_census_7755.gpkg` (58 reserves, 20 cols + geometry).
  - **5.8** — verified the 6 crosswalk `review` rows (all correct). **5.9** —
    reconciled config to Decision 6 (added `CENSUS_SERIES_YEARS`/
    `CENSUS_BASELINE_YEAR`; kept `BASELINE_YEAR` as the GBIF bound).
- Decisions made: **Decision 8** (reserve area source).
- Outputs: `scripts/03_prepare_census.R`, `stats_reserve_census_7755.gpkg`,
  `tbl_05`, `tbl_05b`, `tbl_06`–`tbl_09`; updated `methodology.md`,
  `data-dictionary.md`, `project-plan.md`, `README.md`, `R/00_config.R`, this handoff.
- Gotchas found (now in "Known gotchas"): `BASELINE_YEAR` double-duty (census vs
  GBIF bound); quoted-`#` comment block in the census CSV breaks `comment="#"`;
  ISFR area is a WII polygon area not the notified total; density is per-total-area
  not core-only; `table(useNA="ifany")` NA bin breaks name-indexed printing (fixed
  by index iteration). Process note: one mis-placed str_replace scrambled step
  order mid-build; caught in the coherence check and rebuilt — re-read the file
  before large edits.
- Carried forward / next week: **Week 6** — growth metrics (change/%/AAGR) →
  `tbl_01_reserve_growth.csv` + append to the stats layer. **Decision 9**
  (zero-baseline handling) first. Delete the stale `tbl_05_census_wide_check.csv`.

### Week 4 — Census time series extracted (full) · 2026-09-12
- Entry state: boundary layer built with **provisional** `area_km2`; the five NTCA
  reports on disk, not parsed; missing-year Decision pending.
- Did:
  - **4.1** — located the per-reserve figures in all five reports. Found the
    tabular figures exist **only for 2014/2018/2022** (Table 2.2 / 3.4 / I.3.3);
    2006/2010 have no per-reserve table. Wrote `tbl_04_census_source_map.csv`.
  - **Decision 6** — census figure type + baseline: within-reserve SECR,
    2014/2018/2022 only; 2006/2010 are context, not a baseline. Corrected the
    methodology limitation that wrongly called all rounds SECR.
  - **4.2 → Decision 7** — missing (reserve, round) = `NA`; no imputation.
    Grounded in the observed gap structure (left-censoring, no internal gaps).
  - **4.3** — long table shape fixed; `census_reserve_long.csv` template;
    data-dictionary updated (long + wide schema; dropped `pop_2006/2010`).
  - **4.4** — extracted the **full** series (planned as half):
    `census_reserve_long.csv`, 148 within-reserve rows / 53 reserves + 5 flags.
    2022 transcribed from a page raster.
  - **4.5** — spot-check passed: 2022 vs PIB release **17/17**; 2014 sum = report
    total (1586) exactly; 2018 sum +35 vs report's de-double-counted 1923
    (expected). Wrote `tbl_04_spotcheck_log.md`.
  - **Prose sweep** (extra) — table-missing reserves checked in prose. Added
    Orang 2014 + Ratapani 2022 as **supplementary** (segregated), Mukundara 2014
    = real within-reserve 0. No 2018 additions.
  - **2006/2010 secondary table** (user request) —
    `census_reserve_long_2006_2010.csv` (24 prose figures, confidence-graded,
    context only). Confirmed Singh & Sen supplies no values; no other reference
    gives a comparable reserve-level count set
    (`tbl_04_secondary_sources_2006_2010.md`). Added 3 references.
- Decisions made: **Decision 6** (census figure type + baseline), **Decision 7**
  (missing-year handling = `NA`).
- Outputs: `census_reserve_long.csv`, `census_reserve_long_2006_2010.csv`,
  `tbl_04_census_source_map.csv`, `tbl_04_spotcheck_log.md`,
  `tbl_04_secondary_sources_2006_2010.md`; updated `methodology.md`,
  `data-dictionary.md`, `references.md`, `project-plan.md` (Week 4 ✅ + Week 5
  tasks), this handoff.
- Gotchas found (all now in "Known gotchas"): 2022 Table I.3.3 PDF text layer is
  corrupt → read from a page raster; take the **within** column not "utilising";
  2006/2010 have no per-reserve table; Singh & Sen bars are normalised indices,
  not counts; two Pench = two `unit_id`; `-`/`0` is a real zero.
- Carried forward / next week: **Week 5** — pivot long → wide, join census to the
  boundary layer, **overwrite `area_km2`** from the census area (find that table
  first — task 5.1), compute `density_2022`, write
  `stats_reserve_census_7755.gpkg`. Also reconcile `R/00_config.R` `BASELINE_YEAR`
  drift (still 2006, pre-Decision-6). Glance at the 6 crosswalk `review` rows.

### Week 3 — Reserve boundary layer built · 2026-09-11
- Entry state: all covariates + admin boundaries + NTCA DSS KML on disk; boundary
  layer not built; the five NTCA census reports not yet downloaded.
- Did:
  - **Task 3.1** — downloaded the five NTCA All India Tiger Estimation reports
    (2006, 2010, 2014, 2018, 2022) into `data/raw/ntca/` (PDF; no Excel).
  - **Tasks 3.2–3.6** — wrote and ran `scripts/02_prepare_boundaries.R`. Built
    `boundary_reserves_all_7755.gpkg` (58 reserves: 55 geometry + 3 absent) and
    `boundary_states_7755.gpkg` (36). Built the hand-reviewed
    `reserve_pa_crosswalk.csv` (58 reserves → constituent KML PA names + a
    provisional area placeholder). Added QA columns (`poly_km2`,
    `poly_census_ratio`) and a build report (`tbl_02_reserve_build_report.csv`).
    Preserved the 156 unnamed KML duplicates to
    `data/interim/boundary_kml_unattributed_7755.gpkg`.
  - Updated docs: `data-dictionary.md` (new reserve schema), `methodology.md`
    (Week-3 change log + Nagarjunsagar limitation), `data-sources.md`,
    `proposal.md` (§8), `README.md`, `project-plan.md` (Week 3 ✅ + Week 4 tasks).
- Decisions made: none numbered (Decision 4 unchanged; the Week-3 change log
  records the as-built refinements to it).
- Outputs: `scripts/02`, `boundary_reserves_all_7755.gpkg`,
  `boundary_states_7755.gpkg`, `boundary_kml_unattributed_7755.gpkg`,
  `reserve_pa_crosswalk.csv`, `tbl_02_reserve_build_report.csv`, updated docs.
- Gotchas found (all now in "Known gotchas"): GDAL KML driver drops the
  SchemaData fields and splits the file into two layers → parse with `xml2`;
  `st_as_sfc()` on KML snippets returns empty geometry; the KML `corridor` layer
  is actually the 156 duplicates; `unit_name` is not unique (two Pench, two Rajiv
  Gandhi) → match on name + state. New dependency: `xml2`.
- Data QA: polygon/census ratio median ~0.58 (expected — polygons under-state the
  legal total). One outlier — Nagarjunsagar-Srisailam ratio 1.54 (coarse source
  geometry; not an Amrabad overlap; area is census-sourced so no metric affected)
  — documented in `methodology.md` Limitations.
- Carried forward / next week: **Week 4** — extract the all-reserve census time
  series from the five NTCA reports (manual). Make the **missing-year Decision**
  first (numbered). 6 crosswalk `review` rows to glance at when joining the
  census. `area_km2` overwrite from census happens in Week 5.

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
