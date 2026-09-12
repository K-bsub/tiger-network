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

## stats_reserve_census_7755.gpkg  *(Weeks 5–6)*

| Field | Type | Meaning |
|---|---|---|
| `unit_id` | integer | Join key to reserves |
| `pop_2006` … `pop_2022` | numeric | Population estimate per census year |
| `change_abs` | numeric | 2022 − 2006 (or earliest available) |
| `change_pct` | numeric | Percent change |
| `aagr` | numeric | Average annual growth rate |
| `density_2022` | numeric | Tigers per 100 km², 2022 |
| `baseline_year` | integer | Earliest available census year for this reserve |

## occ_tiger_gbif_clean_7755.gpkg  *(Week 13)*

| Field | Type | Meaning |
|---|---|---|
| `gbif_id` | character | GBIF occurrence key |
| `year` | integer | Observation year |
| `coord_uncert_m` | numeric | Coordinate uncertainty, metres |
| `obscured` | logical | Whether the source obscured the coordinate |
| `source` | character | `gbif` |

*(Further layers — resist, lcp, sdm — documented as they are built.)*
