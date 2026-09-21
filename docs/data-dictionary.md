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
where **all six bands** are non-`NA`. As built: **3,010,738 complete-case cells,
98.15% of the India grid** (gHM is the binding NA layer; the mask drops ~56,840
cells, ~1.8% — a gHM coastal/edge gap-fill is deferred to Week 9, Decision 10).

**Grid:** EPSG:7755, 1 km, 3093 × 2864 = 8,858,352 template cells (extent snapped
to whole `GRID_CELL_M`; 5 km collar). Band order is fixed (`STACK_BANDS`) so later
scripts index by name, never by position.

| Band | Type | Units / domain | Source (Week-2 layer) | Resample |
|---|---|---|---|---|
| `landcover` | categorical | ESA WorldCover 2021 class code (10–100; 11 classes present, modal 40 = cropland) | `cov_landcover_worldcover2021_1km_7755.tif` | nearest |
| `ghm` | continuous | Global Human Modification 2022, 0–1 (India mean 0.377) | `cov_ghm2022_1km_7755.tif` | bilinear |
| `elev` | continuous | Elevation, metres (India: coastal lows to Himalaya) | `cov_terrain_1km_7755.tif` (band `elevation`) | bilinear |
| `slope` | continuous | Slope, degrees (1 km-aggregated) | `cov_terrain_1km_7755.tif` (band `slope`) | bilinear |
| `tri` | continuous | Terrain Ruggedness Index (1 km-aggregated) | `cov_terrain_1km_7755.tif` (band `tri`) | bilinear |
| `dist_road_m` | continuous | Distance to nearest major road, metres (min 0, max ~278.9 km, mean ~2.0 km) | `cov_distroad_1km_7755.tif` (this script) | derived on grid |

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
footprint) so a Week-9 gap-fill can re-stack without re-deriving it.

| Band | Type | Units | Meaning |
|---|---|---|---|
| `dist_road_m` | continuous | metres | Distance from the cell centre to the nearest major-road cell (0 on a road cell) |

## tbl_10_covariate_stack_qa.csv  *(Week 8 — built)*

Written by `scripts/05`/`06`'s `write_table(nn = 10, ...)` — per-band QA for the
stack (task 8.6). One row per band. Coverage is against the full India footprint
(before the common mask), so the common-mask trim shows as bands below 100%.

| Field | Type | Meaning |
|---|---|---|
| `band` | character | Band name (one of `STACK_BANDS`) |
| `n_valid` | integer | Non-`NA` cells in the stacked band (equal across bands after the common mask: 3,010,738) |
| `pct_of_india` | numeric | `n_valid` as % of India-grid cells (98.15% as built) |
| `min`, `max` | numeric | Band min / max (categorical band: class-code range) |
| `range_ok` | logical | `TRUE` if `[min,max]` sits inside the band's physical sanity range; a `FALSE` warns, does not stop |
| `stack_stat` | character | Summary of the **stacked** band — `mean=…` for continuous, `modal=…; n_class=…` for `landcover` |
| `source_stat` | character | Same summary for the **source** Week-2 layer (pre-common-mask), for the alignment spot-check. Close agreement confirms values were not corrupted; small gaps are the ~1.8% common-mask trim |

## occ_tiger_gbif_clean_7755.gpkg  *(Week 13)*

| Field | Type | Meaning |
|---|---|---|
| `gbif_id` | character | GBIF occurrence key |
| `year` | integer | Observation year |
| `coord_uncert_m` | numeric | Coordinate uncertainty, metres |
| `obscured` | logical | Whether the source obscured the coordinate |
| `source` | character | `gbif` |

*(Further layers — resist, lcp, sdm — documented as they are built.)*
