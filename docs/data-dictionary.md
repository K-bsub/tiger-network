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

**Coverage (as built 2026-10-02):** 56 of 58 reserves have geometry: 55 from
their own KML polygons, and Amrabad from the state split (Decision 17, D1a —
`scripts/02` STEP 4b splits the Nagarjunsagar-Srisailam polygon at the Andhra
Pradesh–Telangana boundary: 2,372.7 km² stays `unit_id` 1, 2,701.2 km² in 2
polygons becomes Amrabad, `unit_id` 51). 2 reserves have no polygon (Pilibhit,
Dholpur-Karauli) and are written as geometry-absent rows
(`geometry_present = FALSE`) so the census still joins. *(Weeks 3–9: 55 with
geometry, 3 absent.)*

**Build note (why this is not a simple 55/58 name match):** the KML holds 705
national-park / sanctuary polygons, not tiger-reserve entities. A tiger reserve
is built from one or more constituent PAs (for example Corbett = Corbett NP +
Sonanadi WLS). The match is on standardised **name + state** together, because
name alone is not unique (two "Pench", two "Rajiv Gandhi"). See the change log
in `docs/methodology.md`.

| Field | Type | Meaning |
|---|---|---|
| `unit_id` | integer | Stable reserve ID (primary join key). Stored as **real** in the GeoPackage (R reads it as double); compare it as a number or convert with `as.integer()` |
| `unit_name` | character | Reserve display name |
| `unit_name_std` | character | Standardised name (lower-case, PA-type words and punctuation removed) for cross-source joins |
| `state` | character | State name |
| `landscape_complex` | character | One of `LANDSCAPE_COMPLEXES` |
| `area_km2` | numeric | Reserve area (core+buffer), km². **Provisional in Week 3** — see `area_provisional`. **Not** derived from the polygon geometry (Decision 4) |
| `area_provisional` | logical | `TRUE` in this layer for all 58: it keeps the Week-3 placeholder. The Week-5 overwrite from the NTCA census is written to `stats_reserve_census_7755.gpkg` (`scripts/03`), where it is `FALSE`. The values are equal (Week 5 changed none) |
| `area_source` | character | Provenance of `area_km2`. This layer: `wikipedia_ntca_2022_PLACEHOLDER`. The stats layer: `ntca_notification` |
| `n_parts` | integer | Number of KML PA polygons dissolved into this reserve (0 for geometry-absent reserves). A state-split part keeps its parent's count |
| `match_status` | character | Crosswalk match class: `matched`, `multi` (2+ constituent PAs), `review` (hand-check), `gap` (no KML geometry), or `state_split` (a part of a KML polygon split at a state boundary — Decision 17, D1a; `BOUNDARY_SPLIT_STATUS`; units 1 and 51) |
| `geometry_present` | logical | `TRUE` if the reserve has geometry; `FALSE` for the 2 gaps (3 before 2026-10-02) |
| `source` | character | Boundary geometry source: `ntca` (KML) |
| `poly_km2` | numeric | QA only. Area of the KML polygon geometry, km². `NA` for geometry-absent reserves |
| `poly_census_ratio` | numeric | QA only. `poly_km2 / area_km2`. Expected below 1 (the core-PA polygon under-states the legal total). A value above ~1.1 flags a coarse/over-extended source polygon — geometry is for mapping only, so no census metric is affected. `NA` for geometry-absent reserves |

**QA columns (`poly_km2`, `poly_census_ratio`) are diagnostics, not analysis
inputs.** They make the Decision-4 area gap visible per reserve. As built
(2026-10-02, 56 reserves), the polygon/census ratio has a median of 0.515; the
highest is Amrabad (1.03). *(Corrected 2026-10-02: earlier text said "median
near 0.58"; the data give 0.51 for the 55 reserves before the split.)* Before
the split, Nagarjunsagar-Srisailam had ratio 1.54 because its KML polygon held
the undivided reserve, Amrabad included (Decision 17). See
`docs/methodology.md` (change log + limitations).

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
| `n_parts` | integer | KML PA polygons dissolved into this reserve (from the boundary layer; 0 for geometry-absent; a state-split part keeps its parent's count) |
| `match_status` | character | Crosswalk match class (from the boundary layer; includes `state_split` for units 1 and 51) |
| `geometry_present` | logical | `TRUE` if the reserve has geometry; `FALSE` for the 2 gaps (3 before 2026-10-02) |
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
  **"0 (real)"** class on the ramp (Decision 9); the geometry-absent reserves
  (Pilibhit, Dholpur-Karauli; Amrabad too before the 2026-10-02 split) are
  named off-map and never drawn.

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
| `dist_road_m` | continuous | Distance to nearest major road, metres, after the common mask. `d13f` build: min 0, max 279,692.7 m ≈ 279.7 km, mean 2,044.3 m (read the current values in `tbl_10`) | `cov_distroad_1km_7755.tif` (this script) | derived on grid |

**Not applied here:** the land-cover resistance values (`WORLDCOVER_RESISTANCE`,
Decision 14) and the barrier road classes (Decision 15). `scripts/07` applies them
to build `resist_tiger_<surface>_7755.tif`. The stack holds covariate values only.

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
279,693 m (~279.7 km), mean 2,045 m. The stack band has the 98 India cells
of the Decision-10 common mask removed (`d13f` build, `tbl_10`): max 279,692.7 m
(the same as this layer after rounding), mean 2,044.3 m. *(Week-8 stack band:
max 278.9 km, mean 2,019 m, because the mask then removed the 56,827 India
cells where gHM was `NA`.)*

| Band | Type | Units | Meaning |
|---|---|---|---|
| `dist_road_m` | continuous | metres | Distance from the cell centre to the nearest major-road cell (0 on a road cell) |

## tbl_10_covariate_stack_qa.csv  *(Week 8 — built; 6 columns added 2026-09-26)*

Written by `scripts/06_build_covariate_stack.R` (STEP 8.6,
`write_table(nn = 10, ...)`) — per-band QA for the stack (task 8.6). One row per
band. Six columns were added on 2026-09-26: `n_valid_before` and
`n_dropped_by_mask` (fix pass, so the Decision-10 coverage cost is a saved
figure), `n_filled` (Decision 11), `lc_source` (Decision 12), `terrain_source`
(Decision 13) and `build_tag`. The denominator of `pct_of_india` is the full
India footprint on the grid (3,067,565 cells); the numerator is the after-mask
count, so `pct_of_india` is equal on every row. Week 8: 98.15. `d13f` build:
100 — 3,067,467 of 3,067,565 cells (99.997 %), rounded to 2 decimals.

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
| `n_valid` | integer | Non-`NA` cells in the stacked band **after** the common mask. Equal across bands (hard stop). Week 8: 3,010,738; `d13f` build: 3,067,467 |
| `pct_of_india` | numeric | `n_valid` as % of India-grid cells, rounded to 2 decimals. Week 8: 98.15; `d13f` build: 100 (98 India cells dropped) |
| `min`, `max` | numeric | Band min / max (categorical band: class-code range) |
| `range_ok` | logical | `TRUE` if `[min,max]` sits inside the band's physical sanity range; a `FALSE` warns, does not stop |
| `stack_stat` | character | Summary of the **stacked** band — `mean=…` for continuous, `modal=…; n_class=…` for `landcover` |
| `source_stat` | character | Same summary for the **source** layer (before the common mask), for the alignment spot-check. Close agreement confirms values were not corrupted. Small gaps come from the cells the common mask removes (56,827 in Week 8; 98 in the `d13f` build) and, for gHM, from the Decision-11 fill (the gHM source is the unfilled layer) |

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
| `checked` | logical | `FALSE` for the geometry-absent reserves (listed, not counted): 3 in the Week-9 tables, 2 in a `_split` table |
| `note` | character | Unit-level caveat (geometry absent; over-extended polygon, for example Nagarjunsagar-Srisailam in the Week-9 tables) |

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

## tbl_12_reserve_pairs.csv  *(Week 10 — built, task 10.4)*

Written by `scripts/07_connectivity.R` STEP 10.1 (Decision 17 points 1, 6 and
8). One row per reserve pair. The same pairs are used on all four surfaces:
no resistance value enters this table. 56 reserves (Pilibhit and
Dholpur-Karauli have no geometry, Decision 17 G1).

**How the pairs are made.** Every footprint cell (the non-NA cells of the
baseline surface) is allocated to the nearest reserve polygon by straight-line
distance: the polygon edges are densified to 250 m and used as generator
points, so the distance is exact to within 125 m. The cells of each reserve
(`touches = TRUE`) take their own reserve first; a cell shared by two reserves
goes to the lower `unit_id`. Two reserves are a candidate pair if their zones
share at least one cell edge; a candidate is kept if the polygon gap is at most
315 km (`LCP_PAIR_MAX_GAP_KM`).

**As built (2026-10-03):** 132 candidates, 26 above the cap, **106 pairs**; 3
connected sets (34, 13 and 9 reserves); no reserve without a pair; gap median
106.8 km, maximum 310.8 km; 9 contiguous; 2 cross-group.

| Field | Type | Meaning |
|---|---|---|
| `pair_id` | integer | 1 to n, in order of `from_unit_id`, then `to_unit_id` |
| `from_unit_id`, `to_unit_id` | integer | The two reserves; `from_unit_id` < `to_unit_id` |
| `from_name`, `to_name` | character | Reserve names |
| `from_group`, `to_group` | character | `network_group` of each reserve (`NETWORK_GROUPS`: `northeast`, `western_ghats`, `north`, `central`) |
| `gap_km` | numeric | Straight-line gap between the two reserve polygons, km (2 decimals); at most 315 |
| `contiguous` | logical | `TRUE` if the two reserves share a footprint cell (Decision 17 point 6, amended 2026-10-02). Such a pair gets cost 0 and an empty path, and Decision 18 excludes it |
| `cross_group` | logical | `TRUE` if the two network groups differ. The pair is kept (Decision 17 point 8) |
| `zone_shared_edges` | integer | QA: number of cell edges the two allocation zones share (at least 1) |

## lcp_reserve_network_7755.gpkg  *(Week 10 — layer `baseline` built, task 10.5; layers `noghm`, `road15`, `road50` built, task 10.7)*

Written by `scripts/07_connectivity.R` STEP 10.2 (Decision 17 points 2–6). One
layer per surface (`baseline`; the variant layers `noghm`, `road15`, `road50`
follow in STEP 10.4), each with one LINESTRING per pair of
`tbl_12_reserve_pairs.csv`. The line runs through the cell centres, from the
exit cell of the source reserve to the entry cell of the target reserve. A
contiguous pair has an empty line. Each layer is read back and compared after
it is written.

**As built, `baseline` (2026-10-03):** 106 pairs — 97 paths, 9 contiguous, 0
with no path. Cost median 577.3, maximum 5,814.2 resistance-km. Path length
median 163.3 km, maximum 619.4 km. Length/gap median 1.34, range 0.63–4.18. 26
paths cross another reserve; 21 pairs are not in the network (point 2).

**As built, variant layers (2026-10-03, STEP 10.4):** same pairs and fields;
each layer 97 paths, 9 contiguous, 0 with no path. Pairs not in the network:
`noghm` 19, `road15` 22, `road50` 19.

| Field | Type | Meaning |
|---|---|---|
| `pair_id` | integer | Join key to `tbl_12_reserve_pairs.csv` |
| `surface` | character | `baseline`, `noghm`, `road15` or `road50` (= the layer name) |
| `from_unit_id`, `to_unit_id` | integer | The two reserves; the search runs from `from_unit_id` |
| `from_name`, `to_name` | character | Reserve names |
| `from_group`, `to_group`, `cross_group` | character / logical | Network groups and the cross-group flag (from the pair table) |
| `contiguous`, `gap_km` | logical / numeric | From the pair table |
| `path_status` | character | `path`; `contiguous` (cost 0, empty line, no search); or `no_path` (no route through non-NA cells — kept, not dropped) |
| `cost_rkm` | numeric | Least cost-distance, resistance-km (Decision 17 point 3). 0 for contiguous; NA for `no_path` |
| `path_km` | numeric | Length of the line, km. 0 for contiguous |
| `path_gap_ratio` | numeric | `path_km` / `gap_km`, for `path` rows. It can be below 1 for a very short gap: the line joins cell centres, and an edge cell can extend past the polygon |
| `n_cells` | integer | Cells on the path, including the exit and entry cells |
| `exit_cell`, `entry_cell` | integer | Cell numbers (1 km EPSG:7755 grid) where the path leaves the source and reaches the target |
| `via_unit_ids` | character | Other reserves whose cells the path crosses, `;`-separated (cells shared with an end reserve do not count). Empty if none |
| `redundant_via_unit_ids` | character | The via reserves C for which A–C and C–B are both pairs (Decision 17 point 2) |
| `in_network` | logical | `FALSE` if `redundant_via_unit_ids` is not empty, or if `path_status` is `no_path`; else `TRUE`. Week 11 uses only `TRUE` rows |

## tbl_12_lcp_validation.csv  *(Week 10 — built, task 10.5b)*

Written by `scripts/07_connectivity.R` STEP 10.2b (Decision 17 point 4, plus
V-add). One row per check. The table is written before the pass test; any
failed row then stops the script.

- (a) `a_synthetic`: 7 small grids with hand-computed costs.
- (b) `b_terra_costDist`: the engine at 8 neighbours against
  `terra::costDist()` (`maxiter = 1000`), edge to edge, with the source cells
  set to 0 in both runs, on a window around the pair.
- (c) `c_gdistance`: the engine at 16 neighbours in end-cell mode against
  `gdistance`, point to point between the exit and entry cells of the baseline
  path, on the same window.

Pairs for (b) and (c), from the pairs with a path: the shortest gap, the gap
nearest the median, the longest gap, and the highest `path_gap_ratio` (V-add).
Window = bounding box of the path and both reserves + 100 km.

**As built (2026-10-03):** 15 rows, all pass. Pairs 31 Guru Ghasidas-Tamor
Pingla – Sanjay Dubri (shortest gap), 28 Achanakmar – Bandhavgarh (median), 3
Namdapha – Pakke (longest), 59 Bandhavgarh – Panna (highest ratio). Largest
relative difference 1.5e-15; path overlap 1.000 on every pair.

| Field | Type | Meaning |
|---|---|---|
| `check` | character | `a_synthetic`, `b_terra_costDist` or `c_gdistance` |
| `rule` | character | Why the pair was picked: `min_nonzero_gap`, `median_gap`, `max_gap`, `max_path_gap_ratio` (joined with `+` if one pair meets two); `synthetic` for (a) |
| `case` | character | Name of the synthetic case (check a only) |
| `pair_id`, `from_name`, `to_name`, `gap_km` | integer / character / numeric | The pair (checks b and c) |
| `neighbours` | integer | 8 or 16 |
| `knight_rule` | character | `crossed_cells` or `end_cells` (16-neighbour rows) |
| `window_cells` | integer | Cells in the window (49 for the synthetic grids) |
| `engine`, `reference` | numeric | Cost from our engine and from the reference (hand value, `terra` or `gdistance`), resistance-km |
| `rel_diff` | numeric | abs(engine − reference) / max(1, reference) |
| `path_overlap` | numeric | Check (c): share of the engine's path cells that the `gdistance` path also uses. Reported, not tested: tied routes can differ |
| `pass` | logical | Synthetic: hand value matched; (b), (c): `rel_diff` ≤ 1e-6 (`LCP_VALIDATE_TOL_REL`) |
| `note` | character | Any warning from `terra::costDist()` (for example no convergence); empty if none |

## tbl_12_lcp_qa.csv  *(Week 10 — built, tasks 10.6–10.7; all four surfaces)*

Written by `scripts/07_connectivity.R` STEP 10.3 (`baseline` rows) and
rewritten by STEP 10.4 with all four surfaces (`lcp_qa_paths()`). One row
per pair and surface: 4 × 106 = 424 rows. The checks recompute cost and length from the raster
values, step by step, without the graph. Each check is `TRUE`/`FALSE`, or `NA`
where it does not apply (for example the start check on a contiguous pair).
The table is written first; then any failed pair stops the script. The crop
fallback is not used (`LCP_CROP = FALSE`), so there is no window-edge check.

**As built (2026-10-03):** 424 of 424 rows pass; on every surface 106 of
106 pairs are accounted for (97 paths, 9 contiguous, 0 with no path).

| Field | Type | Meaning |
|---|---|---|
| `pair_id`, `surface`, `from_name`, `to_name` | integer / character | The pair and the surface |
| `path_status`, `gap_km`, `cost_rkm`, `path_km`, `path_gap_ratio`, `in_network` | — | Copied from the paths layer (information) |
| `in_pair_table` | logical | The pair and its two reserves match `tbl_12_reserve_pairs.csv` |
| `status_ok` | logical | `path_status` is `path`, `contiguous` or `no_path`, and `contiguous` agrees with the pair table |
| `empty_ok` | logical | The line is empty if and only if the pair is contiguous or has no path |
| `footprint_ok` | logical | Every path cell is non-NA on the surface |
| `start_ok`, `end_ok` | logical | The first path cell is a cell of the source reserve and equals `exit_cell`; the last is a cell of the target reserve and equals `entry_cell` |
| `steps_ok` | logical | Every step is a valid 16-neighbour step |
| `cost_ok` | logical | The cost recomputed from the raster (Decision 17 point 3, crossed-cells rule) equals `cost_rkm` (relative 1e-9); 0 for a contiguous pair |
| `length_ok` | logical | The length recomputed from the steps equals `path_km`, and the line has one vertex per path cell |
| `network_ok` | logical | `in_network` agrees with `redundant_via_unit_ids` and `path_status` (Decision 17 point 2) |
| `qa_pass` | logical | No check is `FALSE` |

## tbl_12_lcp_variant_comparison.csv  *(Week 10 — built, task 10.7)*

Written by `scripts/07_connectivity.R` STEP 10.4 (Decision 18). One row per
compared pair and variant: the 97 pairs that are not contiguous × 3 variants =
291 rows. Each variant is compared with the baseline only.

| Field | Type | Meaning |
|---|---|---|
| `pair_id`, `variant`, `from_name`, `to_name`, `gap_km` | — | The pair and the variant (`noghm`, `road15`, `road50`) |
| `share_base_in_variant` | numeric | Share of the baseline path length within 5 km of the variant path |
| `share_variant_in_base` | numeric | Share of the variant path length within 5 km of the baseline path |
| `route_overlap` | numeric | The smaller of the two shares (Decision 18 point 2) |
| `route_overlap_1km`, `_2km`, `_5km`, `_10km` | numeric | The same symmetric overlap at 1, 2, 5 and 10 km (descriptive, point 7) |
| `cost_base`, `cost_variant` | numeric | Cost-distance, resistance-km |
| `rank_base`, `rank_variant` | numeric | Percentile rank of the cost among the compared pairs, (rank − 1)/(n − 1), ties = average rank |
| `rank_change` | numeric | `rank_variant` − `rank_base` |
| `material_route` | logical | `route_overlap` < 0.5 (point 3) |
| `material_rank` | logical | abs(`rank_change`) ≥ 0.25 (point 4) |
| `material_pair` | logical | `material_route` or `material_rank` (point 5) |
| `path_length_ratio` | numeric | Variant path length / baseline path length (descriptive) |
| `in_network_base`, `in_network_variant`, `in_network_changed` | logical | Network membership under point 2 on each surface, and whether it changed (descriptive) |
| `via_base`, `via_variant`, `via_changed` | character / logical | Reserves the path crosses on each surface, and whether they changed (descriptive) |

## tbl_12_lcp_variant_summary.csv  *(Week 10 — built, task 10.7)*

Written by `scripts/07_connectivity.R` STEP 10.4 (Decision 18 points 5–6).
One row per variant.

**As built (2026-10-03):** `noghm` 0.186 material, ρ 0.985 — robust;
`road15` 0.113, ρ 0.995 — robust; `road50` 0.093, ρ 0.997 — robust. Choice
labels: gHM multiplier robust; road value robust.

| Field | Type | Meaning |
|---|---|---|
| `variant` | character | `noghm`, `road15` or `road50` |
| `tests` | character | The choice the variant tests: gHM multiplier (Decision 14) or road value (Decision 15) |
| `pairs_compared`, `contiguous_excluded` | integer | 97 and 9 as built |
| `share_material_route`, `share_material_rank`, `share_material_pair` | numeric | Shares of the compared pairs |
| `spearman_rho` | numeric | Spearman rank correlation of baseline and variant costs |
| `median_route_overlap` | numeric | Median of `route_overlap` (descriptive) |
| `in_network_changed`, `via_changed` | integer | Pairs whose network membership / crossed reserves changed (descriptive) |
| `label` | character | `robust` if `share_material_pair` ≤ 0.20 and `spearman_rho` ≥ 0.9, else `sensitive` (fixed in Decision 18) |
| `choice_label` | character | The label of the tested choice. For the road value: `robust` only if both `road15` and `road50` are robust |

## tbl_12_lcp_ntca_overlap.csv  *(Week 10 — built, task 10.8)*

Written by `scripts/07_connectivity.R` STEP 10.5 (Decision 17 point 9;
`lcp_ntca_overlap()`). One row per pair (106), **baseline paths only**.
Descriptive, **not a validation**: the NTCA corridors (Qureshi et al. 2014)
come from a different method. **No buffer** (Decision 17 fixes none): a path
that runs 1 km beside a corridor counts as outside it. Overlapping corridors
count once (the union of the polygons).

**As built (2026-10-03):** 97 paths; share inside corridors median 0.064, mean
0.128; 42 paths with share 0; 55 paths cross at least one corridor.

| Field | Type | Meaning |
|---|---|---|
| `pair_id`, `from_name`, `to_name` | — | The pair |
| `path_status`, `path_km` | character / numeric | From the `baseline` layer |
| `km_in_corridor` | numeric | Path length inside any corridor polygon, km. NA for contiguous pairs |
| `share_in_corridor` | numeric | `km_in_corridor` / `path_km`. NA for contiguous pairs |
| `n_corridors_crossed` | integer | Corridor polygons the path intersects |
| `corridor_ids` | character | Their `corridor_id`s, `;`-separated |

## tbl_12_lcp_ntca_corridors.csv  *(Week 10 — built, task 10.8)*

Written by STEP 10.5 with the table above. One row per NTCA corridor polygon
(59). Same caveats (descriptive; no buffer; baseline paths only).

**As built (2026-10-03):** 31 of 59 corridors crossed by at least one baseline
path.

| Field | Type | Meaning |
|---|---|---|
| `corridor_id`, `corridor_label`, `state` | — | From `boundary_corridors_7755.gpkg` (labels as written in the KML) |
| `area_km2` | numeric | Polygon area, km² |
| `crossed` | logical | At least one baseline path intersects the polygon |
| `n_paths` | integer | Baseline paths that intersect it |
| `pair_ids` | character | Their `pair_id`s, `;`-separated |

## lcp_pair_zones_1km_7755.tif  *(data/interim; Week 10, task 10.4 — QA only)*

The allocation zones of STEP 10.1 on the 1 km EPSG:7755 grid. Value =
`unit_id` of the nearest reserve; `NA` off the footprint. `INT2U`. Not an
analysis output; kept to check the pairs by eye.

## occ_tiger_gbif_clean_7755.gpkg  *(Week 13)*

| Field | Type | Meaning |
|---|---|---|
| `gbif_id` | character | GBIF occurrence key |
| `year` | integer | Observation year |
| `coord_uncert_m` | numeric | Coordinate uncertainty, metres |
| `obscured` | logical | Whether the source obscured the coordinate |
| `source` | character | `gbif` |

*(Further layers — lcp, sdm — documented as they are built.)*
