# Naming Conventions

R-based project. Conventions follow the Bay Area sister project, not the ArcGIS
tiger Phase 1 (no PascalCase feature classes, no `.gdb`).

---

## 1. Species and unit codes

| Code | Meaning |
|---|---|
| `tiger` | *Panthera tigris* — the only focal species here |

Single-species project, so a species token is optional in filenames. Use it
where a layer could otherwise be ambiguous.

---

## 2. Files and directories

- **snake_case throughout.** No spaces, no capitals, no hyphens in data files.
- Hyphens are permitted **only** in documentation filenames (`data-sources.md`).
- Pattern for data layers:

```
<theme>_<subject>_<qualifier>_<crs>.<ext>
```

Examples:

```
boundary_reserves_all_7755.gpkg
boundary_states_7755.gpkg
occ_tiger_gbif_clean_7755.gpkg
effort_background_tgs_7755.gpkg
cov_stack_1km_7755.tif
resist_tiger_baseline_7755.tif
lcp_reserve_network_7755.gpkg
kde_tiger_current_1km_7755.tif
stats_reserve_census_7755.gpkg
sdm_tiger_suitability_1km_7755.tif
```

**Always end data filenames with the EPSG code.** This is the single most useful
habit for avoiding silent CRS mistakes.

**Theme prefixes:**

| Prefix | Contents |
|---|---|
| `boundary_` | Reserve, state, and study-area boundaries |
| `occ_` | Occurrence records |
| `effort_` | Sampling-effort / background layers |
| `cov_` | Environmental and anthropogenic covariates |
| `kde_` | Kernel density surfaces |
| `hot_` | Hot spot (Gi*) results |
| `resist_` | Resistance surfaces |
| `lcp_` | Least-cost paths and corridors |
| `sdm_` | Species distribution / suitability surfaces |
| `stats_` | Tabular summaries joined to geometry |

---

## 3. Scripts

```
NN_verb_object.R
```

Two-digit prefix sets execution order (`00a`, `00b`, `01`, `02`, ...). Function
files in `R/` use the `00_functions_<domain>.R` pattern and are sourced, never
run standalone.

---

## 4. R objects

- **snake_case** for all objects and functions.
- Suffix spatial objects by type so their class is obvious:

| Suffix | Class |
|---|---|
| `_sf` | `sf` vector object |
| `_r` | `terra::SpatRaster` |
| `_v` | `terra::SpatVector` |
| `_ppp` | `spatstat` point pattern |
| `_fit` | fitted model object |
| `_df` / `_tbl` | plain data frame / tibble |

Examples: `reserves_sf`, `landcover_r`, `occ_tiger_ppp`, `tiger_sdm_fit`

- Functions are verbs: `read_vec()`, `build_resistance()`, `fit_sdm()`.

---

## 5. Fields / columns

- **snake_case**, lowercase.
- Units embedded in the name: `area_km2`, `dist_road_m`, `elev_mean_m`.
- Year suffix for temporal fields: `pop_2006`, `pop_2022`.

Standard identifiers used across layers:

| Field | Type | Meaning |
|---|---|---|
| `unit_id` | integer | Stable ID for a reserve (join key) |
| `unit_name` | character | Reserve display name |
| `unit_name_std` | character | Standardised name for joins across sources |
| `state` | character | State name |
| `landscape_complex` | character | One of `LANDSCAPE_COMPLEXES` (see `R/00_config.R`) |
| `pop_<year>` | numeric | Reserve population estimate for a census year |
| `source` | character | `ntca`, `gbif`, `isfr`, `kba`, `wii` |
| `coord_uncert_m` | numeric | Coordinate uncertainty in metres |

---

## 6. Outputs

```
outputs/figures/fig_<nn>_<slug>.png
outputs/tables/tbl_<nn>_<slug>.csv
outputs/models/<species>_<model>_<date>.rds
```

Examples: `fig_01_growth_ranking.png`, `tbl_01_reserve_growth.csv`,
`tiger_sdm_maxnet_20260901.rds`

Execution-order numbers (script prefixes) and output table numbers are
**independent counters**. A script header matches its filename; output table
numbers are their own sequence.

---

## 7. Git

- Branches: `main` (stable), `week-NN-<topic>` for working branches.
- Commit messages: imperative present tense, scope prefix.
  - `data: add GBIF re-download script`
  - `analysis: compute reserve growth metrics`
  - `docs: record boundary-source decision`
- Documentation commits and site commits are always **separate** from analysis
  commits.
