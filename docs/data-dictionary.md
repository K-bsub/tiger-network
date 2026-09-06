# Data Dictionary

Every field in every processed layer. Filled in as layers are built. Field
naming rules are in `docs/naming-conventions.md`.

---

## boundary_reserves_all_7755.gpkg  *(Week 3)*

| Field | Type | Meaning |
|---|---|---|
| `unit_id` | integer | Stable reserve ID (primary join key) |
| `unit_name` | character | Reserve display name |
| `unit_name_std` | character | Standardised name for cross-source joins |
| `state` | character | State name |
| `landscape_complex` | character | One of `LANDSCAPE_COMPLEXES` |
| `area_km2` | numeric | Reserve area, km² |
| `source` | character | Boundary source: `wii` or `kba` |

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
