# Data Dictionary

Every field in every processed layer. Filled in as layers are built. Field
naming rules are in `docs/naming-conventions.md`.

---

## boundary_reserves_all_7755.gpkg  *(Week 3 — built)*

Built by `scripts/02_prepare_boundaries.R` from the NTCA DSS KML (Decision 4).
Each reserve is built from its constituent protected-area polygon(s) named in
`data/raw/ntca/reserve_pa_crosswalk.csv`, then dissolved to one geometry per
`unit_id`. Geometry is the core-PA polygon and is used for **mapping and
connectivity only**. Area comes from the census, not the polygon.

**Coverage:** 55 of 58 reserves have KML geometry. 3 reserves have no KML
polygon (Amrabad, Pilibhit, Dholpur-Karauli) and are written as
geometry-absent rows (`geometry_present = FALSE`) so the census still joins.

**Build note (why this is not a simple 55/58 name match):** the KML holds 705
national-park / sanctuary polygons, not tiger-reserve entities. A tiger reserve
is built from one or more constituent PAs (for example Corbett = Corbett NP +
Sonanadi WLS). The match is on standardised **name + state** together, because
name alone is not unique (two "Pench", two "Rajiv Gandhi"). See the change log
in `docs/methodology.md`.

| Field | Type | Meaning |
|---|---|---|
| `unit_id` | integer | Stable reserve ID (primary join key) |
| `unit_name` | character | Reserve display name |
| `unit_name_std` | character | Standardised name (lower-case, PA-type words and punctuation removed) for cross-source joins |
| `state` | character | State name |
| `landscape_complex` | character | One of `LANDSCAPE_COMPLEXES` |
| `area_km2` | numeric | Reserve area (core+buffer), km². **Provisional in Week 3** — see `area_provisional`. **Not** derived from the polygon geometry (Decision 4) |
| `area_provisional` | logical | `TRUE` while `area_km2` holds the placeholder value. Set to `FALSE` when the field is overwritten from the NTCA census in Week 5 |
| `area_source` | character | Provenance of `area_km2`. Week 3 value: `wikipedia_ntca_2022_PLACEHOLDER`. Week 5 value: the NTCA census |
| `n_parts` | integer | Number of KML PA polygons dissolved into this reserve (0 for geometry-absent reserves) |
| `match_status` | character | Crosswalk match class: `matched`, `multi` (2+ constituent PAs), `review` (hand-check), or `gap` (no KML geometry) |
| `geometry_present` | logical | `TRUE` if the reserve has KML geometry; `FALSE` for the 3 gaps |
| `source` | character | Boundary geometry source: `ntca` (KML) |
| `poly_km2` | numeric | QA only. Area of the KML polygon geometry, km². `NA` for geometry-absent reserves |
| `poly_census_ratio` | numeric | QA only. `poly_km2 / area_km2`. Expected below 1 (the core-PA polygon under-states the legal total). A value above ~1.1 flags a coarse/over-extended source polygon — geometry is for mapping only, so no census metric is affected. `NA` for geometry-absent reserves |

**QA columns (`poly_km2`, `poly_census_ratio`) are diagnostics, not analysis
inputs.** They make the Decision-4 area gap visible per reserve. As built, the
polygon/census ratio has a median near 0.58; one reserve
(Nagarjunsagar-Srisailam, ratio 1.54) over-extends because the KML stores a
coarse envelope of a fragmented hill sanctuary. See `docs/methodology.md`
(change log + limitations).

## Diagnostic layer — boundary_kml_unattributed_7755.gpkg  *(Week 3, interim)*

The 156 unnamed KML placemarks (no `DESIG`, no `Corridor` field). They are
spatial duplicates of the named PA polygons and are **not** reserve inputs. Kept
for inspection so nothing is silently dropped.

| Field | Type | Meaning |
|---|---|---|
| `kml_row` | integer | Row index within the unattributed set |
| `note` | character | Fixed note: duplicate of a named PA; not a reserve input |

## boundary_states_7755.gpkg  *(Week 3 — built)*

India state polygons (Natural Earth admin-1), reprojected to EPSG:7755. 36
features. Fields are the Natural Earth admin-1 attributes as supplied.

## boundary_corridors_7755.gpkg  *(Week 9 — built, task 9.2a)*

The 59 NTCA corridor **polygons** from the DSS KML (Decision 4), written by
`scripts/02_prepare_boundaries.R` STEP 6. They are the KML placemarks with a
`Corridor` field and no `DESIG` field. Set aside in Week 3; written from Week 9
for the connectivity track (Decision 11 relevance check; Week-10 least-cost
paths). They are corridor polygons, not centrelines, and not reserve inputs.

| Field | Type | Meaning |
|---|---|---|
| `corridor_id` | integer | Row number in KML order (stable while the KML is unchanged) |
| `kml_name` | character | Placemark `<name>`; `NA` where blank (the Week-3 KML inspection found the corridor placemarks have a blank name) |
| `corridor_label` | character | KML SimpleData `Corridor` field as written; `NA` where blank. No name is invented |
| `state` | character | KML SimpleData `state_name`; `NA` where blank |
| `source` | character | `ntca` |

## census_reserve_long.csv  *(Week 4 — entry format; raw)*

The census figures are **entered in long format**, one row per (reserve, census
round), then pivoted to the wide `stats_reserve_census_7755.gpkg` on join in
Week 5 (Decision 6 fixes the series to 2014/2018/2022; Decision 7 fixes missing
handling). Long entry keeps provenance per figure and makes `NA` handling
explicit. Stored under `data/raw/ntca/`. Field naming: `pop` is unsuffixed here
because the year is its own column; the `pop_<year>` suffix rule
(naming-conventions §5) applies to the wide layer after the pivot.

| Field | Type | Meaning |
|---|---|---|
| `unit_id` | integer | Join key to reserves (authoritative) |
| `unit_name` | character | Reserve display name (convenience only) |
| `year` | integer | Census round: 2014, 2018, or 2022 |
| `pop` | numeric | Within-reserve SECR estimate midpoint (the entered value) |
| `pop_low` | numeric | Lower SE limit — 2014 only (Table 2.2 gives limits); blank otherwise |
| `pop_high` | numeric | Upper SE limit — 2014 only; blank otherwise |
| `se` | numeric | Standard error as printed — 2018/2022 (they give SE, not limits); blank for scat-DNA minimums |
| `figure_type` | character | `within_reserve_SECR_midpoint` (2014) or `within_reserve_SECR_point` (2018/2022) |
| `spatial_unit` | character | `within_reserve` — never the "utilising" column (Decision 6) |
| `source` | character | `ntca` (controlled vocab, naming-conventions §5) |
| `source_table` | character | `Table 2.2`, `Table 3.4`, or `Table I.3.3` |
| `source_page` | character | Physical PDF page(s) of the source table |
| `entered_by` | character | Initials of whoever keyed the row |
| `entered_date` | character | ISO date the row was keyed |
| `census_status` | character | `measured` or `not_estimated_post2022_notification` |
| `notes` | character | scat-DNA (`*`), MaxEnt (`#`), spelling, or QA notes |

**Entry conventions:** 2014 → `pop` = `Tiger Population`, `pop_low`/`pop_high` =
Lower/Upper SE Limit. 2018 → `pop` = "Tigers within the Tiger Reserve" Number,
`se` = its SE. 2022 → `pop` = "Tiger Number Within Tiger Reserves" value, `se` =
its SE. A `-` or `0` in the report is a real within-reserve zero — enter `0` and
note it, do not leave blank. Reserves absent from a round have **no row** for
that round (Decision 7); never-estimated reserves get one flag row with
`pop = NA`.

## stats_reserve_census_7755.gpkg  *(Week 5 — built; growth metrics Week 6 — built)*

Built by `scripts/03_prepare_census.R`. The wide census (pivoted from
`census_reserve_long.csv`) LEFT-joined onto `boundary_reserves_all_7755.gpkg`
by `unit_id`, so it carries **all 58 reserves** and **inherits every reserve
boundary field** plus the census columns. Per Decision 6 the series is
**2014/2018/2022 only** (no `pop_2006`/`pop_2010`). Per Decision 7, missing
(reserve, round) cells are `NA` — no carry-forward or interpolation. Per
Decision 8, `area_km2` is the **NTCA-notified core+buffer total** (from
`outputs/tables/tbl_05_area_source_map.csv`), never the KML polygon.

**As built (Week 5):** `area_km2` overwritten from the notified total for all 58
(`area_provisional = FALSE`, `area_source = ntca_notification`); `density_2022`
and `baseline_year` computed.

**As built (Week 6):** `scripts/04_growth_metrics.R` appended `change_abs`,
`change_pct`, `aagr`, and `growth_zero_flag` (Decision 9). Growth is over each
reserve's own `baseline_year` → 2022 span (Decision 7). Non-`NA` counts: 49
`change_abs`; 48 `change_pct`/`aagr` (the extra `NA` is Mukundara Hills, zero
baseline, `growth_zero_flag = TRUE`). Real 2022 zeros (Kamlang, Sahyadri, Dampa,
Satkosia, Kawal) carry a valid −100% / −100 %·yr⁻¹, not `NA`. No `Inf`/`NaN`.

| Field | Type | Meaning |
|---|---|---|
| `unit_id` | integer | Stable reserve ID (primary join key) |
| `unit_name` | character | Reserve display name |
| `unit_name_std` | character | Standardised name (from the boundary layer) |
| `state` | character | State name |
| `landscape_complex` | character | One of `LANDSCAPE_COMPLEXES` |
| `area_km2` | numeric | Reserve area (core+buffer), km². **Notified total (Decision 8)**, not the polygon |
| `area_provisional` | logical | `FALSE` once `area_km2` is the notified total (all 58 in Week 5) |
| `area_source` | character | `ntca_notification` (Decision 8). Placeholder tag only if a reserve ever lacks a notified area |
| `pop_2014`, `pop_2018`, `pop_2022` | numeric | Within-reserve SECR estimate per round; `NA` where the reserve has no figure that round (incl. Sundarbans 2022, within-blank) |
| `density_2022` | numeric | Tigers per 100 km², 2022 = `pop_2022 / area_km2 * 100`. `NA` where `pop_2022` or area is `NA`; `0` for a real within-reserve zero. **Per total notified area** (not core-only, so it will not match a core-based NTCA density) |
| `baseline_year` | integer | Earliest round with a non-`NA` `pop` (2014 for 45 reserves; 2018 for 5; 2022 for 3). `NA` for the 5 never-estimated reserves |
| `census_status` | character | `measured` (53) or `not_estimated_post2022_notification` (5 mapped-but-not-measured) |
| `n_parts` | integer | KML PA polygons dissolved into this reserve (from the boundary layer; 0 for geometry-absent) |
| `match_status` | character | Crosswalk match class (from the boundary layer) |
| `geometry_present` | logical | `TRUE` if the reserve has KML geometry; `FALSE` for the 3 gaps |
| `source` | character | Boundary geometry source: `ntca` (KML) |
| `poly_km2` | numeric | QA only. KML polygon area, km². `NA` for geometry-absent reserves |
| `poly_census_ratio` | numeric | QA only. `poly_km2 / area_km2`, **recomputed in 5.4 against the notified area**. `NA` for geometry-absent reserves |
| `change_abs` | numeric | `pop_2022 − pop_baseline` over the reserve's own span. `NA` if only one round (2022-only) or an endpoint is `NA` (Sundarbans, the 5 flagged). A real endpoint `0` keeps a valid value |
| `change_pct` | numeric | `change_abs / pop_baseline × 100`. `NA` where `change_abs` is `NA` **or** the baseline is `0` (Decision 9, flagged below). A real decline to 0 in 2022 is `−100`, not `NA` |
| `aagr` | numeric | Average annual growth rate over the reserve's own span, `(pop_2022 / pop_baseline)^(1 / (2022 − baseline_year)) − 1`, as a percent. Same `NA` set as `change_pct`; a real decline to 0 in 2022 is `−100` %·yr⁻¹. Spans differ (8 yr from a 2014 baseline, 4 yr from 2018), so `aagr` is comparable across reserves where `change_pct` is not |
| `growth_zero_flag` | logical | **Decision 9.** `TRUE` iff the reserve has a real two-round span and `pop_baseline == 0`, i.e. the case where `change_pct`/`aagr` are `NA` because the ratio is undefined (Mukundara Hills only, as built). `FALSE` otherwise — including single-round/missing-endpoint `NA`s and real 2022-zero declines. Lets a reader tell a ratio-undefined `NA` from a missing-data `NA` |

**QA tables written by `scripts/03` (Week 5):** `tbl_06_census_wide_check.csv`
(pivot), `tbl_07_census_join_check.csv` (join), `tbl_08_area_overwrite_check.csv`
(area before/after), `tbl_09_density_check.csv` (density).

## census_reserve_long_2006_2010.csv  *(Week 4 — SECONDARY / context only)*

2006 and 2010 reserve-anchored figures from the NTCA reports' **prose** (those
rounds have no per-reserve table). A **different spatial unit** (reserve +
surrounds / block / landscape) and **different method** (double sampling), so
these are **not** joined into `stats_reserve_census_7755.gpkg` and **not** part
of the growth series (Decision 6). Kept for the 7-reserve Phase-1 comparison and
narrative context. Stored under `data/raw/ntca/`.

| Field | Type | Meaning |
|---|---|---|
| `unit_id` | integer | Join key to reserves |
| `unit_name` | character | Reserve display name |
| `year` | integer | 2006 or 2010 |
| `pop` | numeric | Reserve-anchored population midpoint (blank where the reserve is named but no figure is isolable) |
| `pop_low`, `pop_high` | numeric | Stated range where given |
| `spatial_unit` | character | `reserve_and_surrounds`, `block_or_complex`, `landscape`, or `reserve_prose` — what the figure actually covers |
| `source` | character | `ntca` |
| `source_page` | character | Physical PDF page(s) |
| `attribution_confidence` | character | `high` (named reserve, clear figure), `medium` (reserve-anchored block), `low` (multi-reserve landscape total) |
| `entered_by`, `entered_date` | character | Provenance of the entry |
| `notes` | character | Attribution reasoning / caveats |

## tbl_02_regional_rollup.csv  *(Week 7 — built)*

Written by `scripts/05_growth_analysis.R` (STEP 4). The per-reserve growth layer
rolled up to **two units** — landscape complex and state — stacked into one long
table with a `unit_level` column. 23 rows as built: 5 landscape complexes + 18
states. Roll-up rule (recorded inline in `scripts/05` STEP 2): absolute fields
are summed over non-`NA` reserves only, with a **coverage count per field**; the
ratio fields are **recomputed on the summed pops**, never averaged from
per-reserve percentages. The contributor set for the ratio is the reserves with a
valid two-round span that are not `growth_zero_flag` (same set in numerator and
denominator). Regional `aagr` is annualised over a `pop_baseline`-weighted mean
span; `change_pct` is the primary regional ratio.

Reconciliation (7.6, verified): the landscape total, the state total, and the
per-reserve `na.rm` sum agree for every pop round and for `change_abs`
(pop_2014 1586, pop_2018 1958, pop_2022 2257, change_abs +651; n_measured 53).

| Field | Type | Meaning |
|---|---|---|
| `unit_level` | character | `landscape_complex` or `state` — which roll-up this row belongs to |
| `region` | character | The landscape complex (one of `LANDSCAPE_COMPLEXES`) or state name |
| `n_reserves` | integer | All reserves assigned to the region (the denominator) |
| `n_measured` | integer | Reserves with `census_status == "measured"` (have census data at all; the 5 mapped-but-not-measured are excluded) |
| `pop_2014`, `pop_2018`, `pop_2022` | numeric | Sum of within-reserve `pop_<year>` over reserves with a non-`NA` figure that round. `NA` if no reserve in the region has a figure that round |
| `n_pop_2014`, `n_pop_2018`, `n_pop_2022` | integer | Coverage count per round: reserves contributing to each `pop_<year>` sum |
| `change_abs` | numeric | Sum of per-reserve `change_abs` over reserves with a valid span. Grouping-invariant: the landscape total, state total, and per-reserve total all equal +651 |
| `n_change_abs` | integer | Reserves contributing to `change_abs` (valid two-round span) |
| `change_pct` | numeric | Regional % change **on the summed pops**: `(Σpop_2022 − Σpop_baseline) / Σpop_baseline × 100` over the ratio contributor set. `NA` where the region has no contributor. Never an average of per-reserve % |
| `aagr` | numeric | Regional average annual growth: `(Σpop_2022 / Σpop_baseline)^(1 / span_region) − 1`, as a percent. Secondary to `change_pct` (carries the mixed-span caveat) |
| `span_region` | numeric | `pop_baseline`-weighted mean span (years) over the ratio contributors — the single span the regional `aagr` is annualised over. `NA` where no contributor |
| `n_ratio` | integer | Reserves in the ratio recompute (valid two-round span, not `growth_zero_flag`). Ordering per region: `n_reserves ≥ n_measured ≥ n_pop_2022 ≥ n_ratio` |

## Output figures — fig_01, fig_02  *(Week 7 — built)*

Not data layers; recorded here so the growth-track outputs are documented in one
place. Both from `scripts/05_growth_analysis.R`; both carry the effort/detection
caveat in the caption (proposal success criterion).

- **`outputs/figures/fig_01_growth_ranking.png`** — reserves ranked by
  `change_pct` (default; `RANK_METRIC` switches to `change_abs`/`aagr`), faceted
  by landscape complex, bars filled by growth sign (site palette). Reserves with
  a `NA` ratio (single-round, missing endpoint, or `growth_zero_flag`) are
  excluded from the bars **and** counted in each facet strip ("N not ranked").
  The Sundarbans facet (0 ranked reserves) is dropped from the plot and reported
  in the console.
- **`outputs/figures/fig_02_growth_animation.gif`** — 3-frame choropleth
  (2014/2018/2022, Decision 6). Each reserve is filled by that round's within-
  reserve tiger count, binned with fixed breaks (`POP_BREAKS`) so a colour means
  the same count in every frame. `transition_manual` holds each round as a
  discrete frame (fixed geometry). Three classes stay distinct: a `NA`-pop cell
  is grey **"No estimate"** (never 0); a real within-reserve 0 is a near-white
  **"0 (real)"** class on the ramp (Decision 9); the 3 geometry-absent reserves
  (Amrabad, Pilibhit, Dholpur-Karauli) are named off-map and never drawn.

## cov_stack_1km_7755.tif  *(Week 8 — built)*

Built by `scripts/06_build_covariate_stack.R` (Stage 2 input). One aligned,
analysis-ready **multi-band** raster on a single 1 km EPSG:7755 template, so the
Week-9 resistance surface and the Week-13+ SDM read the identical grid. All bands
resampled onto one template (task 8.2/8.3): WorldCover **nearest** (categorical),
gHM / terrain **bilinear** (continuous); distance-to-road derived on the grid
(task 8.4). Cross-band **common NA mask** (Decision 10): a cell is present only
where **all six bands** are non-`NA`. Week-8 build: 3,010,738 complete-case
cells (98.15% of the 3,067,565-cell India grid). **Week-9 changes:** the gHM
gap-fill (Decision 11, `scripts/06` STEP 8.4b) and the source fixes for land
cover (unmasked tile cache, Decision 12) and terrain (unmasked raw DEM,
Decision 13), both masked on the template, raised this to **3,067,467** of
3,067,565 India-grid cells (98 dropped: 91 water cells beyond the gHM fill and
7 no-class cells at WorldCover tile corners). Decision 10 closed 2026-09-26.
The current figures are always in
`tbl_10_covariate_stack_qa.csv` — read them there, not here.

**Storage (fixed 2026-09-26):** the file is written as 32-bit float (`FLT4S`)
for all six bands, and read back and verified after every write. Builds before
`build_tag` `d13f` were written as `INT1U` and are **not usable** from disk
(gHM and distance-to-road 0; elevation and TRI cut to 0–254).

**Grid:** EPSG:7755, 1 km, 3093 × 2864 = 8,858,352 template cells (extent snapped
to whole `GRID_CELL_M`; 5 km collar). Band order is fixed (`STACK_BANDS`) so later
scripts index by name, never by position.

| Band | Type | Units / domain | Source (Week-2 layer) | Resample |
|---|---|---|---|---|
| `landcover` | categorical | ESA WorldCover 2021 class code (10–100; 11 classes present, modal 40 = cropland) | Since Decision 12: the 88 unmasked 1 km tiles in `data/raw/worldcover/tiles_1km/`, merged, then masked to India on the template (Week 8: `cov_landcover_worldcover2021_1km_7755.tif`) | nearest |
| `ghm` | continuous | Global Human Modification 2022, 0–1 (India mean 0.377) | `cov_ghm2022_1km_7755.tif` | bilinear |
| `elev` | continuous | Elevation, metres. Water cells probably carry sea-floor depths from the source tiles (minimum −434.2 m in the `d13` build — read the current value in `tbl_10`; treatment is a Week-14 decision) | Since Decision 13: raw DEM `data/raw/terrain/dem_india_aws_z7_4326.tif`, via the `scripts/01` path without its mask, then masked on the template (Week 8: `cov_terrain_1km_7755.tif`, band `elevation`) | bilinear |
| `slope` | continuous | Slope, degrees (derived on the native DEM, then 1 km) | As `elev` (band `slope`) | bilinear |
| `tri` | continuous | Terrain Ruggedness Index (derived on the native DEM, then 1 km) | As `elev` (band `tri`) | bilinear |
| `dist_road_m` | continuous | Distance to nearest major road, metres, after the common mask (min 0, max 278,926.5 m ≈ 278.9 km, mean 2,019 m) | `cov_distroad_1km_7755.tif` (this script) | derived on grid |

**Not applied here:** `WORLDCOVER_RESISTANCE` (a starting set, not a Decision) and
any barrier road-class choice — both are Week-9 numbered Decisions. The stack is
covariate values only.

## cov_distroad_1km_7755.tif  *(Week 8 — built, interim)*

Written by `scripts/06_build_covariate_stack.R` (task 8.4). Distance-to-road
covariate; feeds the stack's `dist_road_m` band. Single band on the 1 km EPSG:7755
template. **Inline road-class basis** (covariate only, not a Decision): all five
major OSM classes + `_link` ramps (motorway, trunk, primary, secondary, tertiary),
885,669 features — tertiary **kept** (the barrier-class question is Week 9).
Derived by rasterise-then-`terra::distance` (`touches = TRUE`), computed on the
full template then masked to India. Kept **un-common-masked** (its own gHM-free
footprint) so a Week-9 gap-fill can re-stack without re-deriving it. As built
(2026-09-26 re-run): 3,067,565 valid cells (= the India grid), min 0, max
279,693 m (~279.7 km), mean 2,045 m. The stack band is smaller (max 278.9 km,
mean 2,019 m) because the common mask removes the cells where gHM is `NA`.

| Band | Type | Units | Meaning |
|---|---|---|---|
| `dist_road_m` | continuous | metres | Distance from the cell centre to the nearest major-road cell (0 on a road cell) |

## tbl_10_covariate_stack_qa.csv  *(Week 8 — built; 2 columns added 2026-09-26)*

Written by `scripts/06_build_covariate_stack.R` (STEP 8.6,
`write_table(nn = 10, ...)`) — per-band QA for the stack (task 8.6). One row per
band. `n_valid_before` and `n_dropped_by_mask` were added in the 2026-09-26 fix
pass so the Decision-10 coverage cost is a saved figure; they appear after
`scripts/06` is re-run. The denominator of `pct_of_india` is the full India
footprint on the grid; the numerator is the after-mask count, so
`pct_of_india` is equal on every row (98.15% as built; India grid = 3,067,565
cells).

**Edge offset (data note; corrected 2026-09-26).** `dist_road_m`, `landcover`
(since Decision 12) and terrain (since Decision 13) are masked to India on the
template, so their `n_valid_before` is at most the India-grid count (3,067,565).
gHM is the only band still taken from a `scripts/01` layer masked on the
`scripts/01` grid; the resample onto the snapped template shifts its edge by
about one cell, so it can hold cells outside India and miss cells inside it at
the same time, and its difference from the India count is only a **net**
figure. Before Decisions 12/13, landcover had 1,791 cells outside India and no
class in 1,778 India cells (net +13 — an earlier note called this a "+13
halo", which was wrong); terrain was net +20 and lacked values at the same
edge cells. The India-footprint loss is always the `dist_road_m`
row's `n_dropped_by_mask`.

| Field | Type | Meaning |
|---|---|---|
| `band` | character | Band name (one of `STACK_BANDS`) |
| `lc_source` | character | Land-cover source of this build: `tile_cache` since Decision 12 (same value on every row). Absent in earlier builds |
| `terrain_source` | character | Terrain source of this build: `raw_dem` since Decision 13 (same value on every row). Absent in earlier builds |
| `build_tag` | character | Label of this build (`BUILD_TAG` in `scripts/06`; `d13` after Decision 13, `d13f` after the FLT4S write fix; same value on every row). `scripts/07` names its STEP-9.2 outputs `postfill_<build_tag>`. Absent in earlier builds |
| `n_filled` | numeric | gHM cells filled by the Decision-11 fill (`scripts/06` STEP 8.4b); `0` for every other band, and `0` for gHM when `GHM_GAP_FILL` is `FALSE`. Added Week 9. `scripts/07` uses it to label its outputs pre-fill / post-fill |
| `n_valid_before` | numeric | Non-`NA` cells in the band **before** the common mask (Decision 10). For gHM this is **after** the Decision-11 fill, when it ran. The band with the lowest value is the binding NA layer (gHM in the Week-8 build) |
| `n_dropped_by_mask` | numeric | `n_valid_before − n_valid`: cells the common mask removed from this band. Never negative (hard stop) |
| `n_valid` | integer | Non-`NA` cells in the stacked band **after** the common mask. Equal across bands (hard stop): 3,010,738 as built |
| `pct_of_india` | numeric | `n_valid` as % of India-grid cells (98.15% as built) |
| `min`, `max` | numeric | Band min / max (categorical band: class-code range) |
| `range_ok` | logical | `TRUE` if `[min,max]` sits inside the band's physical sanity range; a `FALSE` warns, does not stop |
| `stack_stat` | character | Summary of the **stacked** band — `mean=…` for continuous, `modal=…; n_class=…` for `landcover` |
| `source_stat` | character | Same summary for the **source** Week-2 layer (pre-common-mask), for the alignment spot-check. Close agreement confirms values were not corrupted; small gaps are the 1.85% common-mask trim |

## cov_landcover_worldcover2021_aligned_1km_7755.tif  *(Week 9 — built, interim)*

Written by `scripts/06_build_covariate_stack.R` STEP 8.3 (Decision 12). WorldCover
2021 land cover on the stack template, masked to India on the template, **before**
the common mask. Built from the 88 unmasked 1 km tiles in
`data/raw/worldcover/tiles_1km/`. Read by `scripts/07` STEP 9.2 to classify
dropped cells. Equal to the stack's `landcover` band wherever the stack has a
value.

| Band | Type | Meaning |
|---|---|---|
| `worldcover_2021` | categorical | WorldCover 2021 class code; `NA` outside India or where no tile has a class |

## cov_commonmask_dropped_<state>_1km_7755.tif  *(Week 9 — built, interim)*

Written by `scripts/07_connectivity.R` STEP 9.2a. `<state>` is `prefill`,
`postfill`, `postfill_d12`, or `postfill_<build_tag>` (for example
`postfill_d13`), set from `tbl_10` `n_filled`, `lc_source` and `build_tag`, so
every version is kept. The
India-grid cells that the Decision-10 common mask removed from the stack
(56,827 pre-fill; 1,869 post-fill and `postfill_d12`; 98 in `postfill_d13`), on
the stack grid. Kept for the Decision-11 check and for Week 10, where these cells are
`NA` in any stack-derived surface.

| Band | Type | Meaning |
|---|---|---|
| `dropped_lc_class` | categorical | WorldCover 2021 class of a dropped India cell (before the mask); `0` = India cell with no WorldCover class; `NA` = not dropped, or outside India |

## tbl_11_ghm_gap_relevance_<state>.csv  *(Week 9 — built, task 9.2)*

Written by `scripts/07_connectivity.R` STEP 9.2c. `<state>` is `prefill`,
`postfill`, `postfill_d12`, or `postfill_<build_tag>` (from `tbl_10`). Each
earlier table is the evidence for the decision that followed it and is never
overwritten (pre-fill → Decision-11 fill; post-fill → Decision 12;
postfill_d12 → Decision 13). One row per footprint unit under
the **Decision-11** rule. Shares the number `tbl_11` with the Week-9
resistance QA table (naming §6: numbers group, slugs identify). Sorted:
material units first, then by dropped land cells.

| Field | Type | Meaning |
|---|---|---|
| `unit_type` | character | `reserve` (KML polygon), `buffer` (the `GAP_BUFFER_M` ring outside a reserve polygon), or `corridor` (NTCA corridor polygon) |
| `unit_id` | integer | Reserve `unit_id` for `reserve`/`buffer`; `corridor_id` for `corridor` |
| `unit_name` | character | Reserve name; buffer = reserve name + ring width; corridor = `corridor_label`, or `corridor_<id> (no label)` |
| `state` | character | State (from the source layer) |
| `landscape_complex` | character | Reserve landscape complex; `NA` for corridors |
| `n_india_cells` | integer | India-grid cells the unit touches |
| `n_land` | integer | Of those, cells with WorldCover ≠ `GAP_WATER_CLASS` (80); no-class cells count as land |
| `n_water` | integer | Cells with WorldCover = 80 (permanent water) |
| `n_dropped_land` | integer | Land cells removed by the common mask (the counted quantity) |
| `n_dropped_water` | integer | Water cells removed by the common mask (reported, not counted) |
| `pct_dropped_land` | numeric | `n_dropped_land / n_land × 100`; `NA` if `n_land` is 0 |
| `material` | logical | Decision 11: `pct_dropped_land ≥ GAP_MIN_PCT` (5) **or** `n_dropped_land ≥ GAP_MIN_CELLS` (25). `NA` for unchecked rows |
| `checked` | logical | `FALSE` for the 3 geometry-absent reserves (listed, not counted) |
| `note` | character | Unit-level caveat (geometry absent; over-extended polygon, for example Nagarjunsagar-Srisailam) |

## resist_tiger_<surface>_7755.tif  *(Week 9 — built, tasks 9.5–9.7)*

Written by `scripts/07_connectivity.R` STEP 9.7 (`FLT4S`, read-back verified).
Four files, one per surface: `baseline`, `noghm`, `road15`, `road50`
(`RESIST_VARIANTS`). On the stack grid; a value on every complete-case cell
(Decision 10) and `NA` elsewhere. Continuous 1 km surface: the sensitive-data
publish floor (≥ 1 km) is met.

| Band | Type | Meaning |
|---|---|---|
| `resistance` | continuous | Movement resistance, 1 (easiest) to `RESIST_MAX` (100). Built as: WorldCover class value (Decision 14) → Sundarban water override (class 80 → 10 inside the Sundarbans reserve + 10 km ring) → × (1 + k × gHM), **except water** (Decision 16) → cap at 100 → on barrier-road cells, max(value, road value) (Decision 15) |

| Surface | k (gHM) | Road value | Changes against the baseline |
|---|---|---|---|
| `baseline` | 4 | 30 | — |
| `noghm` | 0 | 30 | no gHM multiplier (Decision 14) |
| `road15` | 4 | 15 | weaker road barrier (Decision 15) |
| `road50` | 4 | 50 | stronger road barrier (Decision 15) |

## tbl_11_resistance_qa.csv  *(Week 9 — built, task 9.8)*

Written by `scripts/07_connectivity.R` STEP 9.8. One row per resistance surface.
Shares `tbl_11` with the gap-relevance tables (naming §6).

| Field | Type | Meaning |
|---|---|---|
| `surface` | character | `baseline`, `noghm`, `road15`, `road50` |
| `file` | character | Output raster file name |
| `ghm_k` | numeric | gHM multiplier k used |
| `road_value` | numeric | Barrier-road value used |
| `n_cells` | numeric | Complete-case footprint cells (the surface must cover all) |
| `n_na_in_footprint` | numeric | Footprint cells with no value — must be 0 (hard stop) |
| `n_outside_footprint` | numeric | Values outside the footprint — must be 0 (hard stop) |
| `min`, `max`, `mean` | numeric | Surface statistics; min ≥ 1 and max ≤ 100 (hard stops) |
| `pct_at_max` | numeric | % of footprint cells at `RESIST_MAX` |
| `pct_ge_road_value` | numeric | % of footprint cells at or above this surface's road value |
| `n_road_cells` | numeric | Barrier-road cells in the footprint (`touches = TRUE`) |
| `n_road_raised` | numeric | Road cells whose value the maximum rule raised to the road value |
| `n_water_override` | numeric | Water cells set by the Sundarban water override |
| `n_ghm_exempt` | numeric | Footprint cells exempt from the gHM multiplier (water; Decision 16). Absent in the first build |

The first build (before Decision 16) is kept as `tbl_11_resistance_qa_pred16.csv`
(same fields, without `n_ghm_exempt`): the evidence for Decision 16.

## occ_tiger_gbif_clean_7755.gpkg  *(Week 13)*

| Field | Type | Meaning |
|---|---|---|
| `gbif_id` | character | GBIF occurrence key |
| `year` | integer | Observation year |
| `coord_uncert_m` | numeric | Coordinate uncertainty, metres |
| `obscured` | logical | Whether the source obscured the coordinate |
| `source` | character | `gbif` |

*(Further layers — resist, lcp, sdm — documented as they are built.)*
