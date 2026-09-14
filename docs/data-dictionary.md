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

## stats_reserve_census_7755.gpkg  *(Week 5 — built; growth metrics Week 6)*

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
and `baseline_year` computed. **`change_abs`, `change_pct`, `aagr` are NOT in the
Week-5 layer** — they are added in Week 6.

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
| `change_abs` | numeric | **Week 6.** 2022 − baseline; `NA` if only one round |
| `change_pct` | numeric | **Week 6.** Percent change over the observed span; `NA` if only one round |
| `aagr` | numeric | **Week 6.** Average annual growth rate; `NA` if only one round |

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

## occ_tiger_gbif_clean_7755.gpkg  *(Week 13)*

| Field | Type | Meaning |
|---|---|---|
| `gbif_id` | character | GBIF occurrence key |
| `year` | integer | Observation year |
| `coord_uncert_m` | numeric | Coordinate uncertainty, metres |
| `obscured` | logical | Whether the source obscured the coordinate |
| `source` | character | `gbif` |

*(Further layers — resist, lcp, sdm — documented as they are built.)*
