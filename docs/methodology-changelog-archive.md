# Methodology — change-log archive, Weeks 3–13

**Project:** India's Tiger Network
**Author:** Kiran Balasubramanian

The change-log entries of `docs/methodology.md` from 2026-09-11 (Week 3) to
2026-10-18 (Week 13). They were moved here word for word on 2026-10-25
(task 14.7, at the request of the author), to make `methodology.md`
shorter. No text of an entry is changed. The Decisions, the pending items
and the Limitations stay in `methodology.md`.

A reference in another document to "the change log" of Weeks 3–13 (for
example "the Week-3 change log", or "change log, 'Week 12 complete'")
points to an entry of this file. This file is a record. It is not updated.

The entries are newest first, as in `methodology.md`.

---

## Change log, Weeks 3–13 (2026-09-11 to 2026-10-18)

### 2026-10-18 — Week 13 complete: task 13.9 (docs close) and the Week-14 plan (no code)

- **Docs only.** No rule, value, script, data layer or table changed; no
  run. Most Week-13 docs were updated task by task (tasks 13.1–13.8).
- **"Limitations":** 13 Week-13 items at the end of the section — the
  clean tiger set and its sources; the uncertainty rule; the obscured set;
  the observers and the years of the two sets; what the rule cannot find;
  the largest group of the tiger 1 km set; the effort surface; the
  tiger-record surface; the kernel choices; the settlement layer; "in a
  reserve"; the overlapping polygons; the suppressed counts. Decisions 21
  and 22 keep their own lists.
- **Found when the items were written (from the committed tables; no new
  count):** the 18 records of the tiger 1 km set from 2018–2022 are in one
  cell (`tbl_15_occ_window_counts.csv`), and no reserve row of
  `tbl_15_occ_by_reserve.csv` has 18 or more records of that set, so the
  cell is outside all reserve polygons. The cause is not known. Added to
  the facts of the Week-14 model item ("Decisions pending").
- **Week 13 against proposal questions 3 and 4 (a record, not text for
  the site):**
  - Question 3 (suitability): no 1 km model (Decision 21 point 8; 17
    cells). Decision 23 (Week 14) decides between no model and a model at
    a coarser grain.
  - Question 4 (effort): the effort, tiger-record and settlement surfaces
    exist (Decision 22), and the counts per reserve are in
    `tbl_15_occ_by_reserve.csv` with no comparison rule. Gi*, a ratio of
    the tiger and effort surfaces and a comparison rule are not built;
    Week 14 decides them (Decisions 23 and 24).
- **`project-plan.md`:** task 13.9 done; a note on task 13.10 (a listing of
  `outputs/tables/` for two open checks); the Week-13 exit state; the
  **Week-14 task breakdown** — Decision 23 first, then branch A (no model:
  Decision 24 on the effort result) or branch B (a model at a coarser
  grain: Decision 24 on the model settings); dated notes on the Stage-3
  rows of Weeks 13–16, the pending SDM-resistance item, the risk "SDM adds
  little" and the progress table. The breakdown is a plan; it makes no
  Decision.
- **Other docs:** `README.md` (status; the Stack row named `spatstat`,
  which Week 13 did not use — the density surfaces use `terra::focal()`);
  `naming-conventions.md` §2 (the example `kde_tiger_current_1km_7755.tif`
  is replaced by the as-built name `kde_effort_2006_2022_1km_7755.tif`);
  the handoff (Week-13 close; Week-14 entry point).
- **Not done:** `proposal.md` §8 (after Decision 23, as the doc fix pass of
  2026-10-17 set); the check of naming §6 against
  `list.files("outputs/tables")` and of the stale
  `tbl_05_census_wide_check.csv` — they need the project machine (task
  13.10). *(2026-10-18, after the Week-13 commit: both checks closed. The
  listing of `outputs/tables/` has 53 files, and it matches naming §6 in
  both directions; `tbl_05_census_wide_check.csv` is not on disk. No file
  changed; naming §6 has a dated note.)*

### 2026-10-18 — Week 13, task 13.8 complete: STEP 13.6 (clean records per reserve)

- **Process choices (author, 2026-10-18):** s1 — six counts per reserve:
  the tiger 1 km set and 5 km set and the background 5 km set, records
  and 1 km cells (the two background columns are not in the plan text:
  the effort in each reserve, for the effort text); r1 — a record is in a
  reserve if its position is in the polygon (an edge counts); p1 — one
  table, `tbl_15_occ_by_reserve.csv`, with a tiger count of 1 or 2 written
  `<3` (Decision 22 point 9) and no file of the exact tiger counts; w1 —
  58 rows by `unit_id`, `NA` for the 2 reserves with no polygon, the
  totals in the console only; x1 — STEP 13.6 with its own checks.
- **First run stopped (2026-10-18):** 13 background records (no tiger
  record) were in two reserve polygons, and the guard of the chat ("one
  reserve per record") stopped the run; nothing was written. A one-time
  check (names, areas and counts only) found that **6 pairs of reserve
  polygons overlap**, 20.7 km² in total: Bandipur–Sathyamangalam 10.921
  km², Parambikulam–Anamalai 5.530, Periyar–Srivilliputhur-Megamalai
  3.007, Manas–Buxa 0.851, Pakke–Nameri 0.335, Bandipur–Mudumalai 0.091.
  All 13 records are in the Parambikulam–Anamalai overlap, from one
  dataset. Nagarjunsagar-Srisailam–Amrabad (the state split) and
  Bandipur–Nagarhole only touch. The probable cause is that the KML
  outlines of neighbouring protected areas overlap at their shared edge
  (not verified). The reserve layer (`scripts/02`) is not changed in Week
  13: the paths, the network and the pinch points of Weeks 10–12 used it.
- **Process choice o1 (author, 2026-10-18, after the facts above):** a
  record in two or more overlapping polygons counts in each of them (r1 as
  written). The check became: the reserve rows add up to the records
  inside plus the extra counts of those records. The rejected options:
  o2 (one reserve by a fixed rule; arbitrary) and o3 (correct the reserve
  layer first; it would need the runs of Weeks 10–12 again).
- **New code:** `occ_reserve_index()` and `occ_reserve_overlaps()` and
  `occ_suppress_small()` in `R/00_functions_occ.R`; STEP 13.6 in
  `scripts/08`; the 7 number columns of the new table added to the list of
  allowed number columns of STEP 13.5 (so that the QA can check the table
  from the next run on: 172 checks then). No new package.
- **Tests in the chat (made-up data):** the counts per reserve agreed with
  a separate count, polygon by polygon; a reserve that overlaps its
  neighbour gave the overlap table and the expected double counts; two
  reserves with the same polygon stopped the first version as expected.
- **Run on the project machine (2026-10-18), second run:** 58 reserves (56
  with a polygon). Reserves with one or more records: tiger 1 km set 6,
  tiger 5 km set 10, background 5 km set 45. Background: 5,857 of the
  23,901 records are inside a reserve polygon (13 of them in two). Tiger
  counts of 1 or 2 written `<3`: 3 and 5 (1 km set: records and cells), 4
  and 6 (5 km set). No tiger column has only one suppressed count.
- **Not written in the docs (Decision 22 point 9):** the number of tiger
  records inside all reserve polygons. With the shown counts of the
  table, such a total gives the sum of the suppressed counts of a column.
  It is in the console text of the run only.
- **Output:** `outputs/tables/tbl_15_occ_by_reserve.csv` (58 rows).

### 2026-10-18 — Week 13, task 13.7 complete: STEP 13.5 (QA of Decisions 21 and 22)

- **Process choices (author, 2026-10-18):** c1 — STEP 13.5 checks the rules
  of Decision 21 again on the kept records with code of its own (not
  `occ_step_fails()`): the fields of the clean layers, `occurrenceStatus`
  and `issue` from the GBIF zips (by `gbifID`), the centroids and the zoos
  by `st_nearest_feature()` and `st_distance()`, and the tables on disk;
  h1 — a hand-made case of the rule functions, `occ_self_test()`, first;
  x1 — a switch `RUN_SURFACES` (`FALSE`: STEP 13.4 is skipped); t1 —
  `tbl_15_occ_qa.csv` in the Week-12 layout (group, check, value, pass),
  written first, then any `FALSE` stops the script; s2 — the Spearman
  values in their own table, `tbl_15_kde_radius_compare.csv`; p1 — the
  publish checks (`assert_publishable_rast()` on the effort and settlement
  surfaces; no file with "tiger" in its name under `outputs/`; each tiger
  surface under `data/`; no position or cell column in a `tbl_15` table).
- **Changes against the choices, stated at delivery:** (1) an addition: a
  direct calculation (kernel sum and edge mass from the distances, with no
  convolution) at 45 sample cells of each 20 km surface,
  `kde_direct_check()`; (2) the p1 check "no value that looks like a
  coordinate" is a list of allowed names of number columns, because a test
  on the values gives false hits (an integral such as 44.08 looks like a
  degree). `assert_no_raw_points()` has no object in Week 13 (no published
  vector layer); it applies from task 13.8 or the Stage-3 figures.
- **New code:** `occ_self_test()` in `R/00_functions_occ.R` (20 made-up
  records; 11 checks); `kde_direct_check()` in `R/00_functions_kde.R`;
  `scripts/08`: the switch `RUN_SURFACES` and STEP 13.5. No new package.
- **Tests in the chat (made-up data):** the hand-made case found three
  faults put into the rule functions on purpose (the last failed step
  instead of the first; `<` for `<=` at the 1 km limit; `>=` at the 5 km
  limit). On a made-up project, 170 of 170 checks passed; four faults put
  into its data (a record near a zoo, a `lon` column in a table, a tiger
  file under `outputs/`, a value below 0) were each found, the table was
  written and the run stopped.
- **Run on the project machine (2026-10-18), `RUN_CLEANING = FALSE`,
  `RUN_SURFACES = FALSE`:** 171 of 171 checks pass — test case 27, tiger
  16, background 18, obscured 8, tables 22, surfaces 65, publish 15; 0.3
  minutes. The Spearman values: see Decision 22, "QA radii".
- **Outputs:** `outputs/tables/tbl_15_occ_qa.csv` (171 rows) and
  `tbl_15_kde_radius_compare.csv` (6 rows).
- **Found for later:** the publish check "no file with 'tiger' in its name
  under `outputs/`" will fail when a model is saved under the name of
  naming §6 (`outputs/models/tiger_sdm_*.rds`). If Week 14 saves a model,
  the check changes then.

### 2026-10-18 — Week 13, task 13.6 complete: STEP 13.4 (density surfaces)

- **Process choices (author, 2026-10-17):** t1 — the convolution is
  `terra::focal()` with a quartic weight matrix and `fillvalue = 0` (no new
  package; exact zeros); k2 — a new function file `R/00_functions_kde.R`;
  n1 — one file per surface; q2 — the QA surfaces and the edge masses go to
  `data/interim/`; s1 — two tables, `tbl_15_occ_window_counts.csv` and
  `tbl_15_kde_summary.csv`; r1 — a switch `RUN_CLEANING` (`FALSE`: STEP
  13.4 only, with a guard against stale layers); h1 — a hand-made case at
  the start of STEP 13.4; v1 — the surfaces are read back with a tolerance
  of 1e-8.
- **Found while the code was written:**
  - `terra::focal()` gives `NA` to each cell within the radius of the grid
    edge when `fillvalue` is `NA` (the default). The grid has a 5 km margin
    around India, so border cells would have had no value. Tested on a small
    grid; the code uses `fillvalue = 0`, and the hand-made case checks a
    unit at a grid corner.
  - The read-back check of `write_processed_rast()` (1e-4 × max(1, |mean|))
    cannot see a file of zeros when the mean is about 1e-5. The surfaces use
    1e-8 (v1); the function does not change.
  - `spatstat` is not in `renv.lock`; it is not used.
- **New code:** `R/00_functions_kde.R` (10 functions: the weights, the
  window, the units raster, the edge mass, one surface, the summary, the
  radius comparison, the window check, the window counts, the hand-made
  case). `scripts/08`: the switch `RUN_CLEANING`, the guards of the
  `KDE_*` settings, the guard that no surface goes under `outputs/`, and
  STEP 13.4. STEPs 13.1–13.3 run only with `RUN_CLEANING = TRUE`; their
  code did not change. No new package.
- **Tests in the chat (made-up data, 300 × 260 cells):** the full STEP
  13.4; a direct calculation (kernel sum and edge mass from the distances)
  at 80 cells of each surface, near the grid edge and the coast too, agreed
  to 6e-8 (32-bit float); the guards stopped on a stale set table, a wrong
  `cell_1km`, an edited `KDE_SIGMA_M`, a missing input and a wrong switch
  value. STEPs 13.1–13.3 could not run in the chat (no GBIF file).
- **Run on the project machine (2026-10-18), `RUN_CLEANING = FALSE`:**
  16 of 16 checks of the hand-made case; guard passed; 11 surfaces written
  and read back; the two tables written; 6.3 minutes. Results: see
  Decision 22, "Outcome of STEP 13.4".
- **Outputs:** `data/processed/kde_effort_2006_2022_1km_7755.tif`,
  `kde_tiger_2006_2022_1km_7755.tif`, `kde_settlement_citytown_1km_7755.tif`,
  `kde_effort_2006_2010_1km_7755.tif`, `kde_effort_2018_2022_1km_7755.tif`;
  in `data/interim/` the six QA surfaces and three edge masses; all
  gitignored. `outputs/tables/tbl_15_occ_window_counts.csv` (24 rows) and
  `tbl_15_kde_summary.csv` (11 rows).

### 2026-10-17 — Week 13, task 13.5: Decision 22 recorded (no surface, no count)

- **Decision 22** (effort surfaces) recorded before any density surface is
  built and before any count by time window is made. The chat raised nine
  forks with one recommended option each; the author chose a2, p1, u2, b2,
  c2, d3, e2, f2, g1 (c2 and d3 are not the chat's recommendations).
- **Found during the research (facts for the Decision):**
  - The 15 km and the 20 km of the pending settlement item are both
    correct, for two different surfaces: 20 km is the Phase-1 tiger-record
    radius, 15 km the Phase-2 settlement radius. The plan text (task 13.5,
    point (c)) said that one of the two was wrong.
  - The quartic kernel of `spatstat` takes a standard deviation, not a
    radius: support radius = √8 × `sigma` (checked in
    `spatstat.explore` 3.2.5). `KDE_SIGMA_M` holds the derived value.
  - OpenStreetMap holds about 30 % of the Census-2011 villages and about
    58 % of the Census-2011 towns (rough comparison).
  - The Phase-1 documents give two Gi* bands (50 km and 25 km).
- **`R/00_config.R`:** a new block "Stage 3: effort surfaces (Decision
  22)" with the `KDE_*` settings. `KDE_RADIUS_M` (20,000) moves into the
  block. No other value changes.
- **Pending items:** "[Week 8–9 → Week 13] Settlement layer for the KDE"
  closed by Decision 22. The Week-14 model item gets points (4) to (7): the
  uses of the effort and settlement surfaces, Gi*, and any ratio surface.
- **Text corrected after the Decision:** `scripts/01` (Block 6 comments),
  `data/data_manifest.csv` (row `osm_settlements`) and `data-sources.md`
  (OpenStreetMap entry) said that Decision 22 was not yet recorded.
- **Not done in this task:** no surface, no count by window, no code in
  `scripts/08`.

### 2026-10-17 — Doc fix pass (Week 13, before task 13.5)

A check of the Week-13 files found stale or missing text. No rule, value,
data layer, table or script logic changed; no re-run. Historical
change-log entries are left as written; this entry records the
corrections.

- **`R/00_functions_occ.R`.** `occ_read_header()` held a literal
  byte-order mark in a regular expression (an invisible character). It is
  now the escape `\ufeff`; the result is the same. The header list of
  packages now names `dplyr` (`all_of()` in `occ_read_fields()`).
- **`scripts/00a_setup_environment.R`.** `jsonlite` added to the package
  list. `R/00_functions_occ.R` calls `jsonlite::fromJSON()` for the cached
  GBIF registry entries (task 13.3, process choice w1). `jsonlite` was
  already in `renv.lock` (`renv::status()`: consistent), so the lock does
  not change. The 2026-10-11 entry ("no new package") is correct for the
  lock only.
- **`scripts/01`, comments only.** The method notes and Block 3 said that
  the background is saved as "clean POINTS" (Block 3: "with class/year").
  The saved points hold `yr` only and are not cleaned; `scripts/08` reads
  the zip again and applies Decision 21. Block 6: the title now names the
  zoos; the purpose text now gives the use as built (roads: the
  `dist_road_m` covariate and the road barrier of Decision 15; settlements:
  an input to the effort surfaces, not to the resistance surfaces; zoos:
  Decision 21 step 8); the radius comment no longer says that Decision 22
  has fixed the radius; "GGDAL" corrected to "GDAL".
- **`data/data_manifest.csv`, row `osm_settlements`.** `required_for` was
  `connectivity`; the resistance surfaces do not use this layer. Now
  `effort` (a value that the manifest already uses). The note now points to
  Decision 22 (task 13.5) and not to "Week 8-9".
- **§5.4.** A dated note gives the outcome `no_1km_model` and the Week-14
  Decision.
- **Pending item "Target-group scope".** The label now shows that the item
  was carried to Week 14 (author choice g1).
- **`naming-conventions.md` §6.** Rows added for `tbl_01` and `tbl_06` to
  `tbl_10`, from `data-dictionary.md` and the handoff. Not yet checked
  against a listing of `outputs/tables/`.
- **`references.md`.** Barber et al. (2022) added (Decision 5 cited it).
  Gábor et al. (2022): volume, issue, pages and the article DOI added.
  Zizka et al. (2019): volume, issue and pages added; the title starts
  "Standardized". Both from university repository records.
- **`project-plan.md`.** The Stage-3 table named `scripts/08_<verb_object>.R`
  for Week 13 and `scripts/08` for Week 14. By process choice s1 of task
  13.2, Week 13 is `scripts/08_prepare_occurrences.R` and Week 14 names a
  new script. The settlement folder in the Week-13 entry state is now
  verified (`data/raw/osm/`). Dated notes on the outcome `no_1km_model`.
- **`data-sources.md`, OpenStreetMap entry.** The role line and the
  settlement flag (the "15 km" radius) now point to Decision 22 and to the
  config value (20 km, a starting value).

### 2026-10-17 — Week 13, task 13.4 complete: STEP 13.3 (background), dataset check, target-group scope; split point

- **Process choices of task 13.4 (author, 2026-10-17):** d1 — the dataset
  check runs on the background datasets too, with the same word list and
  cleared list; t1 — STEP 13.3 writes the four `tbl_15` tables again with
  the tiger rows and the background rows; r1 — the outcome of point 8 is
  locked in the config (`OCC_POINT8_OUTCOME`). The defaults of the clean
  background layer and of the taxa table were accepted.
- **New code:** `scripts/08_prepare_occurrences.R` STEP 13.3 and the lock in
  STEP 13.2; `R/00_functions_occ.R` `occ_taxa_table()`. The background uses
  the functions of STEP 13.2 (one rule for the two sets). `R/00_config.R`:
  `OCC_POINT8_OUTCOME` (28 `OCC_*` settings) and five more entries in
  `OCC_DATASET_CLEARED` (six in all).
- **Tests before the run (made-up records):** a background-only dataset with
  list words stopped STEP 13.3 (the background layer not written; the tiger
  outputs kept); after it was cleared, the background attrition, the kept
  set, `ds_match`, `uncert_set`, the cells, the four sets, the obscured
  count and the taxa table equal a separate computation; a wrong recorded
  outcome stopped STEP 13.2 before any write; no coordinate in the console
  or a table.
- **First run of STEP 13.3 on the project machine (2026-10-17):** the
  dataset check stopped on five datasets; the author chose e1 (Decision 21,
  "Outcome of the dataset check on the background").
- **Second run on the project machine (2026-10-17), the record:**
  - STEP 13.2 printed the same figures as on 2026-10-17 before, and
    "outcome = the recorded outcome".
  - **Background attrition** (each record at its first failed step):

    | Step | Removed | Records out |
    |---|---|---|
    | 0 entry state | — | 39,057 |
    | 1 `status` | 0 | 39,057 |
    | 2 `basis` | 378 | 38,679 |
    | 3 `year` | 0 | 38,679 |
    | 4 `coord_flags` | 0 | 38,679 |
    | 5 `uncert_na` | 5,636 | 33,043 |
    | 6 `uncert` | 8,568 | 24,475 |
    | 7 `centroid` | 57 | 24,418 |
    | 8 `zoo` | 517 | 23,901 |
    | 9 `footprint` | 0 | 23,901 |

    With no order, 98 records fail step 7 and 703 fail step 8. Step 3
    removed no record, as Decision 21 expects.
  - **Background sets:** 1 km 20,905 records in 4,554 cells; 5 km 23,901 in
    5,512; matched 1 km 6,082 in 417; the obscured count 7,029 records in
    825 cells of 0.2°.
  - **Matched datasets** (one or more records of the tiger 1 km set): the
    Valparai and Anamalai datasets of 2005–06 (background 1 km 1,431) and
    2015–18 (3,398), NABU|naturgucker (501), Global Roadkill Data (752), and
    the Facebook photographs (no background record: the dataset holds tiger
    records only).
  - **Taxa:** 46 order and family rows; by order in the pending item
    "Target-group scope".
  - **Datasets with a kept background record:** 24; six hits, all cleared.
  - **Written:** `data/processed/effort_background_tgs_clean_7755.gpkg`
    (23,901 records, read back, gitignored); `tbl_15_occ_cleaning.csv` (20
    rows), `tbl_15_occ_cleaning_by_dataset.csv` (819),
    `tbl_15_occ_sets.csv` (7), `tbl_15_occ_dataset_check.csv` (30),
    `tbl_15_background_taxa.csv` (46).
- **Target-group scope:** author choice g1 — carried to the Week-14 model
  Decision (pending item, dated note).
- **Correction (an error of the chat, 2026-10-17):** the task-13.3 record
  and the chat said that the Facebook dataset gives 253 of the 300 records
  of the 5 km set (84 %). In `tbl_15_occ_dataset_check.csv`, `n_5km` counts
  the records above 1 km only; the dataset gives 20 + 253 = **273 of 300
  (91 %)**. Corrected in the pending Week-14 item and in `references.md`.
- **Docs of the split point:** `data-dictionary.md` (the placeholder entry
  of the clean tiger layer replaced: four layers, the registry cache and the
  six `tbl_15` tables), `naming-conventions.md` §6 (the `tbl_15` row),
  `data-sources.md` (the cleaning notes of the two GBIF entries),
  `README.md` (status), `project-plan.md` (tasks 13.4 and the split point),
  `handoff.md` (the state for the next session).
- **Next:** task 13.5 — Decision 22 (effort surfaces), before any density
  surface is seen.

### 2026-10-17 — Week 13, task 13.3 complete: zoo read, STEP 13.2 (tiger records), dataset check, outcome of point 8

- **Zoo read (`scripts/01` Block 6, new zoo block; process choice q1).** Run
  on the project machine on 2026-10-11 (Block 1, the setup of Block 6 and
  the zoo block only; Block 7 was not run again). OpenStreetMap features
  with `tourism` = zoo, from the cached Geofabrik file (no new download),
  within 1 km of India: **154 features (63 points, 91 areas)** →
  `data/raw/osm/osm_zoos_7755.gpkg`. The GDAL read of the area layer gave 7
  warnings "Non closed ring detected"; the STEP-13.2 run found no invalid
  feature. The block was tested before on a made-up OSM file with
  `osmextract` 0.6.0 (the locked version). New row `osm_zoos` in
  `data/data_manifest.csv`; zoo entry in `docs/data-sources.md`.
- **`scripts/01`, two comments corrected (text only; found in Week 13):**
  `BASELINE_YEAR` is the GBIF download bound, not the census span; the
  settlement comment no longer names a "15 km KDE".
- **Process choices of task 13.3 (author, 2026-10-11):** w1 — the script
  reads the GBIF registry entry of each dataset one time and keeps the JSON
  text in `data/raw/gbif/dataset_meta/`; s1 — the set sizes go to
  `tbl_15_occ_sets.csv`; b1 — STEP 13.2 (tiger) before STEP 13.3
  (background).
- **New code:** `scripts/08_prepare_occurrences.R` STEP 13.2 and 13
  functions in `R/00_functions_occ.R` (the reference features, the nine
  steps, the first failed step, the sets, the 0.2° cell, the attrition, the
  table by dataset, the outcome of point 8, the dataset check).
  `occ_assert_counts_only()` now also stops on a column name with a
  position or a cell. `R/00_config.R`: `OCC_DATASET_FLAG_WORDS` (12 word
  parts) and `OCC_DATASET_CLEARED` (27 `OCC_*` settings). The run switch
  `RAW_STAGE` is `counts`.
- **Tests before the run (made-up records, R 4.3.3 in the chat):** each
  known case at its step (a record 300 m from a district centroid; 500 m
  from a zoo point; inside a zoo area; on a cell with no covariate value;
  1,500 m from a zoo, kept; a material sample, kept; two records in one
  cell); the attrition, the kept set, the sets, the cells and the obscured
  set equal to a separate computation; a dataset with a list word stops the
  script and nothing is written; a missing registry entry with no network
  stops the script; no coordinate in the console or a table.
- **First run on the project machine (2026-10-17):** the dataset check
  stopped on one dataset; nothing of STEP 13.2 was written. The author chose
  k1 (Decision 21, "Outcome of the dataset check"). The attrition table of
  the console wrapped at the console width; the second run prints it at a
  width of 120 (no change to a rule).
- **Second run on the project machine (2026-10-17), the record:**

  | Step | Removed | Records out |
  |---|---|---|
  | 0 entry state | — | 4,606 |
  | 1 `status` | 0 | 4,606 |
  | 2 `basis` | 38 | 4,568 |
  | 3 `year` | 1,043 | 3,525 |
  | 4 `coord_flags` | 0 | 3,525 |
  | 5 `uncert_na` | 313 | 3,212 |
  | 6 `uncert` | 2,912 | 300 |
  | 7 `centroid` | 0 | 300 |
  | 8 `zoo` | 0 | 300 |
  | 9 `footprint` | 0 | 300 |

  - With no order, 13 records fail step 7 and 2 fail step 8; earlier steps
    removed all of them.
  - **Sets (`tbl_15_occ_sets.csv`):** 1 km set 45 records in **17 cells**;
    5 km set 300 records in 44 cells; obscured set 884 records in 104 cells
    of 0.2°. No iNaturalist record was removed at step 6 with an
    uncertainty below 25,000 m.
  - **Point 8: `no_1km_model`** (Decision 21, "Outcome of point 8").
  - **Datasets with a kept record (`tbl_15_occ_dataset_check.csv`):** six.
    1 km set: the Facebook photographs 20, NABU|naturgucker 13, Valparai
    and Anamalai 2015–18 6, Valparai and Anamalai 2005–06 5 (cleared, k1),
    Global Roadkill Data 1. The 5 km set adds 253 of the Facebook
    photographs and 2 of Valparai and Anamalai 2020–23.
  - **Written:** `data/processed/occ_tiger_gbif_clean_7755.gpkg` (300
    records) and `data/processed/occ_tiger_gbif_obscured_7755.gpkg` (884),
    both read back (the same records), both gitignored;
    `tbl_15_occ_cleaning.csv` (10 rows),
    `tbl_15_occ_cleaning_by_dataset.csv` (325 rows),
    `tbl_15_occ_sets.csv` (3 rows), `tbl_15_occ_dataset_check.csv` (6 rows).
- **Not done yet:** STEP 13.3 (the background, task 13.4). The docs of task
  13.9 (`data-dictionary.md`, `naming-conventions.md` §6, the GBIF entries
  of `data-sources.md`, the README and the handoff).

### 2026-10-11 — Week 13, task 13.2 complete: script, names stage, counts stage; Decision 21 Amendments 1 and 2

- **Process choices (author, 2026-10-11):** s1 — one script for Week 13,
  `scripts/08_prepare_occurrences.R`; f1 — `R/00_functions_occ.R`; g1 —
  STEP 13.1 in two stages with the switch `RAW_STAGE` (`names`, then
  `counts`); t1 — the raw counts also go to `tbl_15_occ_raw_counts.csv`; p1
  — the obscured set is `occ_tiger_gbif_obscured_7755.gpkg`; q1 — the zoo
  read is a new block of `scripts/01` (task 13.3); d1 — no data file goes
  to the chat. Reader: `readr`, as `scripts/01` Block 3; no new package.
- **New code:** `scripts/08_prepare_occurrences.R` (header, guards, STEP
  13.1) and `R/00_functions_occ.R` (the read of the two GBIF files, the
  names report, the entry state, the raw counts). The background filter
  takes the tiger `speciesKey` from the tiger file, so the script does not
  use the network (`scripts/01` used the GBIF name service).
- **`tbl_15` is free:** the listing of `outputs/tables/` on 2026-10-11 has
  no `tbl_15_*` file.
- **Names stage run on the project machine (2026-10-11):** all fields of
  Decision 21 are in the two files; 25 of 27 checks `ok`; two `REVIEW`
  lines. No count was printed. The facts and the three answers (no
  amendment for the review flags; y1 for the date flags; c2 for the record
  types) are in Decision 21, "Amendment 1". Amendment 2 (v1, a dataset
  check) came after the counts stage.
- **`R/00_config.R`:** `OCC_BASIS_KEEP` has five values (Amendment 1). The
  number of `OCC_*` settings is 25, as before.
- **Counts stage run on the project machine (2026-10-11).**
  `tbl_15_occ_raw_counts.csv` written (165 rows). No record removed.
  - **Guards PASS.** Tiger: the entry state is the record set of the
    interim layer (4,606 by `gbifID`; 0 only in one of the two). The
    `readr` read of this script and the `rgbif` read of Week 2 give the same
    records. Background: 39,057 records, the count of the interim layer.
  - **Files:** tiger 4,952 rows, all with coordinates; background 51,732
    rows, all with coordinates and all in the year and taxon filter (the
    download predicate had applied it).
  - **Raw counts of the entry state** (before any rule step; limits on the
    clean sets, not clean counts):

    | Item | Tiger (4,606) | Background (39,057) |
    |---|---|---|
    | Uncertainty ≤ 1,000 m | 69 | 21,424 |
    | Above 1,000 m and ≤ 5,000 m | 262 | 3,061 |
    | Above 5,000 m and below 25,000 m | 1,139 | 1,538 |
    | 25,000 m or more | 2,749 | 7,030 |
    | No uncertainty value | 387 | 6,004 |
    | Year 2006–2022 / below / above / none | 3,528 / 118 / 926 / 34 | 39,057 / 0 / 0 / 0 |
    | Record types: human obs. / machine obs. / specimen / material sample / material citation | 4,258 / 305 / 35 / 5 / 3 | 37,541 / 672 / 198 / 466 / 180 |
    | iNaturalist records | 1,842, all 25,000 m or more | 21,083 (7,635 ≤ 1,000 m) |
    | Records with a "remove" flag; zero or equal coordinates | 0; 0 | 0; 0 |
    | Datasets | 25 | 38 |

  - **Decision 21 point 8:** the 1 km set has 69 records or fewer, so
    `n_cells_1km` is 69 or fewer. The outcome is a reduced model or no 1 km
    model; the planned model (80 or more) cannot occur. Task 13.3 states
    the formal outcome.
  - **Point 4:** each iNaturalist tiger record has an uncertainty of 25,000
    m or more; none is between 5,000 m and 25,000 m.
  - **Point 7:** the tiger 1 km set has no iNaturalist record, so the
    matched background will have none. iNaturalist gives 7,635 of the
    21,424 background records with an uncertainty of 1,000 m or less.
  - **Amendment 1 (c2), in numbers:** it keeps 5 tiger and 466 background
    material samples more than c1 at step 2 (raw state).
- **Looked up by the chat (2026-10-11; public GBIF registry and API; counts
  and descriptions only):**
  - `ff8a7785-27c8-4162-907e-658e28a09ba1` (2,306 tiger records): "Bengal
    Tiger (Panthera tigris) Sighting based on Photographs from Facebook in
    India" (Nature Mates-Nature Club; CC0).
  - `e61455a4-352d-4c55-83ea-dbca254e3b29` (305): "Camera trap database of
    Tiger from Rajaji National Park, Uttarakhand" (Wildlife Institute of
    India contacts; CC BY-NC). The description says that the positions were
    degraded for security. The GBIF API (index of 2026-10-11, not the
    download of 2026-09-07) gives 305 records, all `MACHINE_OBSERVATION`,
    none with an uncertainty value.
  - `c6b86c40-ff71-4e5e-902c-111f400d0d56` (63): "India Biodiversity Portal
    publication grade dataset" (CC BY).
  - The fact about the camera-trap dataset led to Amendment 2 (v1).
- **Correction to the entry below ("the chat ... had no R installation"):**
  later on 2026-10-11 the chat had R 4.3.3 (sf 1.0-15, readr 2.1.5).
  `00_config.R` ran there with `source()` and no error. The task-13.2 code
  was tested there on made-up records: the output table against a separate
  tally, and seven cases that must stop the script. The versions are not
  the locked versions of this project.
- **Found and not changed:** the as-built table of `naming-conventions.md`
  §6 has no row for `tbl_01` and for `tbl_06` to `tbl_10`; the files are in
  `outputs/tables/`. A docs item for task 13.9.

### 2026-10-11 — Week 13, task 13.1: Decision 21 recorded (no code, no count)

- **Decision 21** (occurrence cleaning) is recorded. The forks were raised
  on 2026-10-11 and the author chose a3, n1, b1, c1, z2, o2, e1, g3, h2 and
  k2. No record is cleaned and no cleaned count is made. `scripts/08` does
  not exist yet.
- **`R/00_config.R`:** 25 `OCC_*` settings, after the `PINCH_*` block. The
  chat that wrote the block had no R installation. It parsed the file with
  an R grammar (tree-sitter) and got no error; it did not run the file. The
  first `source()` on the project machine is the check.
- **What the files showed (the reason for point 1 of the Decision):**
  - `scripts/01` Block 2 writes eight fields to the interim tiger layer.
    `occurrenceStatus` and `issue` are not among them.
  - `scripts/01` Block 3 writes only `yr` to the interim background layer.
    The uncertainty, the record type, the dataset and the taxon of a
    background record are in the zip file only.
  - Stage 3 therefore reads the two zip files again. The interim layers are
    the guard for the entry state.
  - A test for zero or equal coordinates can remove no record inside India.
    It stays as a check that must count zero.
  - `scripts/01` Block 2 printed the record-type mix, the number of records
    with no uncertainty and the 90th percentile of the uncertainty in Week
    2. The documents hold only the median. Decision 21 states this under
    "What was seen".
- **Checked on 2026-10-11:** the field list of the GBIF simple format (it
  has `issue`, `occurrenceStatus`, `datasetKey`, `order`, `family`; it has
  no `informationWithheld`); the GBIF flag names; the key of the
  iNaturalist dataset in the GBIF registry; the default feature classes in
  the `maxnet` source (`lqh` below 80 presences, `lqph` from 80).
- **Pending list:** the item "[Week 13] Occurrence-cleaning rule" is
  closed. New item "[Week 14] Model Decisions that Decision 21 names". A
  dated note on the item "Target-group scope".
- **`docs/project-plan.md`:** task 13.1 ticked; a note "Changes from
  Decision 21" for tasks 13.2 to 13.4 and 13.7; a dated note on the Week-14
  row; the progress row.
- **`docs/references.md`:** new section "Occurrence cleaning (Decision
  21)".
- **Found and not changed (text only):**
  - `scripts/01` Block 3 says that `BASELINE_YEAR` "matches the census
    span". The config says that it is the GBIF download bound and not the
    census baseline.
  - `scripts/01` Block 6 names a "15 km KDE"; `KDE_RADIUS_M` is 20 km
    (Decision 22 fixes the radius).
  - Decision 5 cites Barber et al. 2022; `references.md` has no entry for
    it.

### 2026-10-10 — Week 12 committed and pushed; Week-13 plan added (no code)

- **Week 12 is committed and pushed** (task 12.11, by the author).
- **`docs/project-plan.md`:** task 12.11 ticked; new section "Week 13 — task
  breakdown" (tasks 13.1–13.10; estimates 4.6–6.3 hours; a split point after
  task 13.4).
- **Pending item added:** "[Week 13] Occurrence-cleaning rule" (Decision 21,
  before any cleaned count). A dated note on the settlement item: the config
  radius is 20 km and the item said 15 km.
- **Three points that the plan raises, not decided:** (1) a minimum number
  of clean presence cells, fixed before the count is seen, below which the
  Week-14 plan changes; (2) Getis-Ord Gi* is named in §5.5 and is in no week
  of Stage 3; (3) a density surface of few tiger records can show a record
  position, which the ≥ 1 km rule of the policy does not prevent.
- **`handoff.md`:** the Week-13 entry point now names the tasks.

### 2026-10-10 — Week 12 complete: task 12.10 (note file, Limitations, Stage-2 summary, docs close)

- **Note file for the publishable tables (author choice 2026-10-10).**
  Decision 20 point 5 says that each table says what a pinch point is here;
  a CSV file has no place for a note. `R/00_functions_pinch.R`:
  `pinch_table_note()`. `scripts/07_connectivity.R` STEP 12.6 (part 12.6e)
  writes `outputs/tables/tbl_03_notes.md`: what a pinch point is here, the
  tiers, the limits, and the counts of the run. Each value in the text is a
  config value or a count of the run; the text is ASCII; the file holds no
  position. The file name and the wording are from the drafting chat; the
  author asked for no change. **Run on the project machine (2026-10-10):**
  the file was written (32 lines); STEPs 12.6 and 12.7 gave the same checks
  and the same figures as before.
- **Week-12 code, in one list.** `R/00_functions_pinch.R` (new; 33
  functions). `R/00_functions_sensitive.R`: `assert_publishable_table()`.
  `R/00_config.R`: 21 `PINCH_*` settings. `scripts/07_connectivity.R`: STEPs
  12.1–12.7 after the Week-11 STEPs, and a third run switch,
  `RUN_ROAD_CELLS` (`FALSE`: STEP 12.1 reads the barrier-road raster from
  disk). STEP 12.7 loads `ggplot2`. No new package. The code of Weeks 9 to
  11 is not changed.
- **Stage 2 against proposal question 2 (a summary of the record; it is not
  narrative text).** The question has four parts:

  | Part of question 2 | What was built | Result on the baseline surface | Read it with |
  |---|---|---|---|
  | "Where are the likely movement corridors between reserves?" | Least-cost paths between neighbour reserves, edge to edge, on a resistance surface of land cover × human pressure, with roads as barriers (Decisions 14–18) | 106 pairs: 97 paths and 9 contiguous pairs; 85 pairs are in the network. Cost median 577.3 resistance-km | A path is a modelled line with no width, not a corridor and not observed movement. Some routes differ from documented corridors (Limitations, "Least-cost routes…"). The share of path length inside the NTCA corridor polygons has a median of 0.064; the paths cross 31 of the 59 corridors. No path leaves India |
  | "Which reserves are connectivity linchpins?" | A graph of the in-network pairs; betweenness inside each connected set; `linchpin` = rank 1 to 3 in the set (Decision 19) | 47 nodes from 56 reserves; 73 edges; 3 sets (33, 8 and 6 nodes). 8 linchpin nodes: Madhav, Guru Ghasidas-Tamor Pingla, Sanjay Dubri; the Bandipur block, Bhadra, Parambikulam + Anamalai; Pakke + Nameri, Orang. 12 cut nodes; 13 bridges | 7 of the 8 are linchpins on all four surfaces. Madhav is a linchpin only with the cross-group link Sariska–Rajaji in the graph. The number 3 is a judgement value; in a set of 6 or 8 nodes it is a large share |
  | "…and which are isolated?" | `isolated` = degree 0; graded columns `pendant` and `cheapest_link_rkm` (Decision 19) | No node is isolated by the rule. 6 pendant nodes: Valmiki, Sundarbans, Dampa, Sahyadri, Kalakad-Mundanthurai, Biligiri Ranganatha Temple | The network has no cost threshold: each pair inside 315 km that passes the through-reserve rule is a link. Some links have no support in the literature. Two reserves are not in the network (no boundary polygon) |
  | "Where do corridors cross major roads?" | Crossings of the in-network paths with barrier roads (OpenStreetMap motorway to secondary); crossings at most 5 km apart are one site; a pinch point is a site on a bridge edge or a site that two or more edges use (Decision 20) | 556 crossings on 74 of 76 paths; 365 sites; 200 pinch points — tier 1: 3, tier 2: 98, tier 3: 99. Published at a 10 km grid cell with state and district (`tbl_03b`, `fig_03`) | The answer is for modelled lines, not for corridors. "Pinch point" is a position in the network; it is not a measure of the effect of a road, and it is not the pinch point of circuit-theory mapping. No traffic data. The label separates little (Limitations) |

- **The Stage-2 variant labels, together** (each by a rule fixed before its
  result):

  | Result | gHM multiplier (`noghm`) | Road value (`road15`, `road50`) |
  |---|---|---|
  | Path routes and cost ranks (Decision 18) | robust | robust |
  | Network sets, betweenness, linchpins (Decision 19) | robust | robust |
  | Pinch points (Decision 20) | **sensitive** (site overlap 0.520; limit 2/3) | robust (0.866 and 0.820) |

  The routes and the node ranks stay when the human-pressure multiplier is
  removed; the places where the paths meet barrier roads do not. A write-up
  that names a pinch point must give the third row.
- **What Stage 2 does not give.** A corridor width or a current-flow map
  (circuit theory; pending, after Stage 3). A resistance surface from the
  SDM (pending, after Stage 3). Links across the national border. Traffic
  volume or road-kill risk. A test against telemetry or genetic data (not
  public); the three literature checks are descriptive.
- **`proposal.md` §8: no new entry.** §8 records where the as-built work
  differs from a choice that the proposal states. For Week 12 the proposal
  states "road pinch points" (§5) and question 2 asks where corridors cross
  major roads; both are built. What a crossing and a pinch point are is an
  elaboration that the proposal left open, and it is Decision 20.
- **Limitations: ten items added** (below, from "A pinch point is a
  position in the network…" to "`fig_03` at national scale").
- **Open items, carried forward.** The title, the subtitle and the caption
  of `fig_03` are draft text. The sources of the Week-12 literature check
  are news reports and must be verified before they are cited. The entries
  of `references.md`, "Road pinch points (Decision 20)", were read from
  abstracts only. `fig_04` is the next free figure number; the Week-16 plan
  row names `fig_05`. Pending Decision: "[Week 18] Published path layer".
- **Docs:** `data-dictionary.md` (`tbl_03_notes.md`),
  `naming-conventions.md` §6, `project-plan.md` (task 12.10 ticked; Week 12
  and the Stage-2 milestone marked), `README.md`, `handoff.md`; the
  Limitations below.

### 2026-10-10 — Week 12 (in progress): task 12.9 (literature check of the pinch points)

- **Author choice 2026-10-10:** task 12.9 (optional) is done. It changes no
  value, no rule and no label. Sources: `references.md`, "Week-12 pinch
  points — literature check".
- **Scope, fixed before the search.** (A) the 3 tier-1 pinch points; (B) the
  tier-2 pinch points by bridge link (13 links); (C) the districts with 5 or
  more tier-3 pinch points (6 districts); (D) the other direction: named
  road conflicts on tiger corridors, compared with the table.
- **Level of the match.** The road layer has no road name (Decision 20,
  n1). A match is the same link or reserve, and the same district when the
  source names one. No pinch point is matched to a named road. No 1 km
  position was used in a search.
- **Result (descriptive), 21 groups in A to C.**
  - A source for a road conflict in the same district or reserve: 10
    groups. Examples: Valmiki–Dudhwa (the Indo-Nepal Border Road goes
    through all six districts of the 11 pinch points; a proposal in 2019);
    Orang–Dampa at Kaziranga (NH-715; Golaghat and Karbi Anglong);
    Biligiri Ranganatha Temple–Sathyamangalam (the night traffic ban on the
    highway in Sathyamangalam, Erode); Corbett–Rajaji (the
    Laldhang–Chillarkhal road, stopped by the Supreme Court in 2019);
    Periyar–Kalakad-Mundanthurai (road and railway in the Shencottah gap).
  - A source for the link only, or context only: 5 groups.
  - No source found or read: 6 groups (Similipal–Sundarbans,
    Bhadra–Nagarhole, Anamalai–Mudumalai, Anamalai–Srivilliputhur-Megamalai,
    Guntur, Krishna).
  - Tier 1: Sonitpur has a district-level source from 2010 that does not
    name tigers; Chikmagalur has a district-level source (NH-169) that names
    another species. **No source confirms a tier-1 pinch point as a known
    tiger crossing place.**
  - Sariska–Rajaji has 21 of the 98 tier-2 pinch points. The sources are
    for roads at the two ends of the link only. The pinch points in
    Haryana, Delhi and western Uttar Pradesh have no source: they follow
    from a bridge link with `lit_flag`.
- **Two limits of the rule, from part D (for the Limitations section, task
  12.10).**
  1. *A road inside a node is not in the result.* NH 766 through Bandipur
     (a night traffic ban, in force for about ten years in 2019) has no
     crossing in the tables: Bandipur, Nagarhole, Mudumalai and Sathyamangalam are one
     node, and no path is modelled inside a node. The same applies to the
     Nagzira–Navegaon part of NH 6, inside the reserve unit
     Nawegaon-Nagzira.
  2. *A documented crossing place can be a crossing that is not a pinch
     point.* NH-44 in the Maharashtra part of Pench has nine monitored
     crossing structures that tigers use (Saxena & Habib 2022). In Nagpur
     district the paths have road crossings on three links
     (`tbl_14_road_crossings.csv`), and none is a pinch point, because one
     edge uses each and no edge there is a bridge. The pinch-point label
     gives the position of a site in the network; it does not say where
     roads affect tigers most.
- **Quality of the sources (stated plainly).** Almost all are news reports,
  read as web pages or extracts on 2026-10-10. One peer-reviewed paper is
  cited through a news report. Two pages gave a summary only. One source is
  an exam-preparation page. Each search was short (one or two queries for
  each group): "no source found" means that these queries found none.
- **Docs:** `references.md` (new section, 22 entries), `project-plan.md`
  (task 12.9 ticked).

### 2026-10-10 — Week 12 (in progress): task 12.8 (STEP 12.7 figure `fig_03`)

- **Author choice (2026-10-10, before the code).** The figure shows the
  pinch points of all three tiers; tier 3 is small and pale.
- **Code.** `R/00_functions_pinch.R`: `pinch_node_points()`,
  `pinch_figure_classes()`, `pinch_figure_marks()`,
  `pinch_selftest_figure()`. `R/00_config.R`: `PINCH_FIG_SLUG`,
  `PINCH_FIG_SIZE_IN`, `PINCH_FIG_DPI`, `PINCH_FIG_KEY_POS`.
  `scripts/07_connectivity.R`: STEP 12.7 after STEP 12.6; it loads
  `ggplot2`. The checks run first; the file is not written if one fails.
- **What the figure shows** (Decision 20 point 7). A map at national scale,
  11 × 10.6 in at 200 dpi.
  - Nodes by flag: a linchpin on all four surfaces (filled circle); a
    linchpin only with the cross-group links in the graph (filled diamond);
    a linchpin that is not a linchpin on all four surfaces (open circle);
    other node; pendant node; a ring for each cut node. Each linchpin has a
    number; the list by set gives the names.
  - The 73 baseline edge paths as modelled lines; the 13 bridge links are
    thick and dark.
  - The 200 baseline pinch points as triangles at the centre of their 10 km
    cell: tier 1 large with an outline, tier 2 medium, tier 3 small and
    pale.
- **Positions (sensitive-data policy §3).** The pinch points are read from
  `tbl03b`, the publishable table, and from no other object; the publish
  check runs again on it in STEP 12.7. The figure table of the paths holds
  the line and the pair number only. The lines are in this static figure
  only. A node is drawn at the centroid of its reserve polygons (public
  boundaries).
- **Choices made in the drafting chat, with no author decision before the
  code. Author decision 2026-10-10, with the project-machine figure and the
  list at hand: all seven stay.**
  1. Slug `reserve_network`, the slug of `tbl_03`.
  2. Size 11 × 10.6 in (`fig_02` is 9 × 9.6 in); the legend needs the width.
  3. A number in each linchpin mark and a list of the names by set.
  4. The reserve polygons are drawn (pale green). Decision 20 does not list
     them.
  5. The `lit_flag` links are not marked.
  6. The tier-1 pinch points are drawn last, on top of the nodes.
  7. The draft caption adds three items to those of Decision 20: the
     variant result, the states of the tier-1 pinch points, the data
     sources.
- **Result on the project machine (2026-10-10).** Self-test 8 of 8; 10 of 10
  figure checks. 47 nodes (8 linchpin, 12 cut-node rings, 6 pendant); 73
  edge paths (13 bridge links); 200 pinch points (tier 1: 3, tier 2: 98,
  tier 3: 99) in 194 cells of 10 km. Legend classes: linchpin on all four
  surfaces 6; linchpin only with the cross-group links 1 (Madhav); linchpin
  not on all four surfaces 1 (Sanjay Dubri); other node 33; pendant node 6.
  Linchpin numbers: set of 33 nodes — 1 Madhav, 2 Guru Ghasidas-Tamor
  Pingla, 3 Sanjay Dubri; set of 8 — 4 Bandipur + Nagarhole + Mudumalai +
  Sathyamangalam, 5 Bhadra, 6 Parambikulam + Anamalai; set of 6 — 7 Pakke +
  Nameri, 8 Orang. The file is 2200 × 2120 pixels. The same figures as in
  the drafting chat.
- **Limits of the figure (stated plainly).**
  - The 3 tier-1 pinch points show as 2 marks: the two sites in Assam are
    in adjacent 10 km cells. The caption gives the count by state. The 200
    pinch points are in 194 cells.
  - The tier-1 mark in Assam is on top of linchpins 7 and 8 and hides a
    part of the mark of linchpin 8. The number stays readable.
  - Tier 3 has low contrast against the map (fill 1.4 to 1, outline 2.3 to
    1). This is the author choice "small and pale"; `tbl_03b` is the full
    list.
  - Colours: the green and the red of the site symbology pass a
    colour-vision separation check as a pair. The green `#225522` does not
    pass two style checks of the same tool (it is dark and has low chroma).
    It was kept because it is the site colour. Each class has a shape or a
    size of its own.
  - The thin grey lines of the links that are not bridges are faint on the
    project-machine file. Author decision 2026-10-10: the line width stays
    0.3.
  - The title, the subtitle and the caption are draft text of the drafting
    chat. Author decision 2026-10-10: the draft stays for now. All numbers
    in them are read from the objects of the run.
- **Test before delivery** (with the real files; `ggplot2` 3.4.4 in the
  drafting chat). The same figures. The mark counts made a second way, from
  the CSV tables on disk, are the same. All 200 triangles of the plot object
  are at a 10 km cell centre; none is at the 1 km site position. Six
  planted faults each stopped the code (a position off the grid; the 1 km
  site table; an `sf` site table; an isolated node; sites that are not
  pinch points; a reserve with no node). The 14 CSV tables did not change,
  byte for byte.
- **Docs:** `data-dictionary.md` (`fig_03`), `project-plan.md` (task 12.8
  ticked). Not yet: `README.md`, `handoff.md`, the Limitations section
  (task 12.10).

### 2026-10-10 — Week 12 (in progress): task 12.7 (STEP 12.6 publishable tables)

- **Author choices (2026-10-10, before the code).** `tbl_03b` holds all
  baseline pinch points, sorted by tier (not tiers 1 and 2 only). Slugs:
  `reserve_network` and `pinch_points`.
- **Code.** `R/00_functions_sensitive.R`: `assert_publishable_table()` — the
  publish check of sensitive-data policy §3. It stops for: an `sf` object; a
  column with a 1 km cell or a point coordinate; a position that is not a
  centre of the publish grid; a grid id that is not the cell at that
  position; a grid finer than 10 km; a grid column in a table that must hold
  no position. `R/00_functions_pinch.R`: `pinch_node_summary()`.
  `scripts/07_connectivity.R`: STEP 12.6 after STEP 12.5. The checks run
  first; no table is written if one fails.
- **`tbl_03_reserve_network.csv`** — one row per network reserve (56). The
  values are per node (47): the reserves of one block share them. The
  network columns are those of `tbl_13_network_metrics.csv`. The pinch-point
  columns count the sites on the edges of the node. No position.
- **`tbl_03b_pinch_points.csv`** — one row per baseline pinch point, sorted
  by tier, then `site_id`. The rows are the pinch points of
  `tbl_14_pinch_points.csv`. Position: the 10 km cell, state and district.
- **Columns added to the list of Decision 20 point 7 (no column of the list
  is absent).** `tbl_03`: `state`, `n_bridge_edges`, `n_crossings`,
  `n_sites`. `tbl_03b`: `site_id` (the key to the `tbl_14` tables),
  `district_code`, `lit_flag_any`.
- **How the node counts are made.** A site on an edge counts for the two
  nodes of the edge. A site that two edges of one node use counts one time
  for that node. The node counts thus do not add up to the number of pinch
  points, and a block of reserves repeats its node values on each row.
- **Result on the project machine (2026-10-10).** 9 of 9 table checks; the
  two publish checks pass. `tbl_03`: 56 reserves, 47 nodes; 42 nodes have a
  pinch point on an edge; 7 have a tier-1 pinch point. `tbl_03b`: 200 rows
  (tier 1: 3, tier 2: 98, tier 3: 99).
  - Linchpin nodes, pinch points on their edges: Madhav 24 (all tier 3);
    Bhadra 18 (tier 1: 1, tier 2: 17); Bandipur + Nagarhole + Mudumalai +
    Sathyamangalam 15 (1, 14); Orang 12 (tier 1: 2, tier 2: 9, tier 3: 1);
    Parambikulam + Anamalai 8 (all tier 2); Pakke + Nameri 3 (tier 1: 2,
    tier 3: 1); Guru Ghasidas-Tamor Pingla 1 and Sanjay Dubri 1 (tier 3).
  - Highest counts: Ratapani 29, Indravati 26, Madhav 24, Kawal 24, Panna
    23 (tier 3 only, each); Sariska 23 (tier 2: 21, tier 3: 2); Rajaji 22
    (all tier 2); Nagarjunsagar-Srisailam + Amrabad 21 (tier 3 only).
  - The count of a node is not an order of nodes: Decision 20 gives no
    order in a tier, and a node with more edges or longer edges can have
    more road crossings.
- **Test before delivery** (with the real files). The same figures. The node
  counts made a second way, from the two `tbl_14` tables on disk, equal
  `tbl_03`. Six planted faults each stopped the publish check: a point
  coordinate column; a position 1 km off the grid; a wrong grid id; a 5 km
  grid; a position column in `tbl_03`; an `sf` object.
- **Open, for the author.** Decision 20 point 5 says that each table header
  says what a pinch point is here. A CSV file has no place for a note. The
  statement is in the `data-dictionary.md` entries of the two tables. A
  note file next to the tables is possible; it is not made.
- **Docs:** `data-dictionary.md` (`tbl_03_reserve_network.csv`,
  `tbl_03b_pinch_points.csv`), `naming-conventions.md` §6,
  `project-plan.md` (task 12.7 ticked). Not yet: `README.md`, `handoff.md`.

### 2026-10-10 — Week 12 (in progress): task 12.6 (STEP 12.5 pinch-point QA)

- **Code.** `R/00_functions_pinch.R`: `pinch_check_surface()` — the QA list
  of Decision 20 for one surface. `scripts/07_connectivity.R`: STEP 12.5
  after STEP 12.4; STEP 12.4 now keeps the link table and the bridge flags
  of each surface for it. The table is written first; then any failure
  stops the script.
- **What STEP 12.5 checks.** (1) The three hand-made self-tests of STEPs
  12.2–12.4, collected (19, 22 and 11 cases). (2) The road-cell guard of
  STEP 12.1 (6 checks). (3) On each of the four surfaces, 12 checks: each
  link in the roles has its crossings; the cost from the cell list is the
  cost of the path; each crossing cell is in the cell list of its path and
  is a barrier-road cell; each barrier-road cell of a cell list is in one
  crossing only; no crossing for a contiguous pair or a pair that is not in
  the network; each crossing is in one site only; two sites are more than
  the merge distance apart; the counts add up; `n_edges` and `n_bridges`
  from the crossings equal the site table; the rule written a second way;
  each site on a bridge edge is a pinch point; `lit_flag` agrees with the
  config list. The cell lists are made again in the check; the stored
  counts are not used. (4) Baseline: the chain function gives the result
  of STEPs 12.2–12.3; the site ids; the `lit_flag` links are in-network
  links. (5) The comparison: one row per variant; the shares; the labels
  by the fixed rule, written a second way; `n_variants_near`. (6) On disk:
  the row count of each `tbl_14` table; no position finer than the publish
  grid in each; the 1 km file has one layer per surface with one point per
  crossing cell, and it is under `data/`.
- **Result on the project machine (2026-10-10): 74 of 74** — test cases 3
  of 3, roads 6 of 6, baseline 15 of 15, `noghm`, `road15` and `road50` 12
  of 12 each, all 14 of 14. Output `tbl_14_pinch_qa.csv` (74 rows).
- **Test before delivery** (with the real files). The same 74 of 74. Eleven
  planted faults in a copy of the baseline result (a removed crossing cell,
  a cell that is not a road cell, a crossing with no site, a changed tier,
  a changed `n_edges`, two sites inside the merge distance, a crossing on a
  contiguous pair, a failed cost check, a wrong `lit_flag`, a changed link
  count, a changed bridge flag) each failed one or more checks. A 1 km
  column put into a table on disk stopped the script after the QA table
  was written with the failure.
- **Defect found by the QA, corrected before delivery.** The first run in
  the drafting chat gave 73 of 74: the `choice_label` column of the
  comparison table was a one-dimension array, not a plain vector, so the
  second-way label check was not identical. The values and the CSV were
  right. STEP 12.4 now makes a plain vector; the CSV on disk is the same
  file, byte for byte.
- **Docs:** `data-dictionary.md` (`tbl_14_pinch_qa.csv`),
  `naming-conventions.md` §6, `project-plan.md` (task 12.6 ticked; the
  split point was reached and the author chose to continue). Not yet:
  `README.md`, `handoff.md`.

### 2026-10-10 — Week 12 (in progress): task 12.5 (STEP 12.4 variants and the Decision-20 comparison)

- **Process choices (put to the author before the code):**
  `outputs/tables` gets only `tbl_14_pinch_variant_comparison.csv`; the
  variant crossing cells go to the gitignored 1 km file, one layer per
  variant; `tbl_14_pinch_points.csv` is written again with
  `near_pinch_<variant>` and `n_variants_near`. No "stable" label is made:
  Decision 20 has none.
- **Code.** `R/00_functions_pinch.R`: `pinch_run_surface()` (the chain of
  STEPs 12.2–12.3 as one function), `pinch_sites_near()`,
  `pinch_compare_variant()`, `pinch_selftest_compare()`.
  `scripts/07_connectivity.R`: STEP 12.4. Each variant uses its own paths
  (STEP 10.4), its own link table and its own bridges (the Decision-19 graph
  of STEP 11.3). The STEP first checks that the chain function gives the
  baseline result of STEPs 12.2–12.3 again.
- **Result on the project machine (2026-10-10).** Rule fixed in Decision 20
  point 6, before any crossing.

  | Surface (tests) | Paths (bridges) | Crossings | Sites | Pinch points (tier 1 / 2 / 3) | Share of baseline | Share of variant | Site overlap | At 10 km | All sites | Label |
  |---|---|---|---|---|---|---|---|---|---|---|
  | `baseline` | 76 (13) | 556 | 365 | 200 (3 / 98 / 99) | — | — | — | — | — | — |
  | `noghm` (gHM multiplier) | 78 (11) | 496 | 372 | 155 (2 / 72 / 81) | 0.520 | 0.671 | **0.520** | 0.625 | 0.667 | **sensitive** |
  | `road15` (road value) | 75 (13) | 610 | 383 | 202 (3 / 98 / 101) | 0.895 | 0.866 | **0.866** | 0.886 | 0.851 | robust |
  | `road50` (road value) | 78 (11) | 546 | 363 | 192 (4 / 72 / 116) | 0.820 | 0.859 | **0.820** | 0.880 | 0.860 | robust |

  By the rule (limit 2/3 at 5 km): **gHM multiplier — sensitive; road value
  — robust** (both road variants). Checks 6 of 6 on each variant, with the
  cost check on the real variant surfaces.
- **This is not the result that Decision 20 named as likely.** Its "What
  was seen" text says that a robust label is the more likely result, because
  the routes (Decision 18) and the network (Decision 19) were robust on all
  three variants. The pinch points are more sensitive than the routes and
  the node ranks. The Decision text is a dated record and is not changed.
- **Where the `noghm` difference is.** 49 baseline tier-1 and tier-2 pinch
  points have no `noghm` pinch point within 5 km: Sariska–Rajaji 17,
  Bhadra–Kali 8, Similipal–Sundarbans 7, Bhadra–Nagarhole 4, Dudhwa–Corbett
  3, Orang–Dampa 3, Valmiki–Dudhwa 2, and one each on five more entries.
  Sariska–Rajaji and Bhadra–Kali had a material route change on `noghm` in
  Week 10 (route overlap 0.261 and 0.225), and `noghm` has 11 bridges, not
  13. On `road50` the count is 23 (Sariska–Rajaji 15); on `road15` it is 3.
- **Per baseline pinch point.** 98 of the 200 have a variant pinch point
  near them on all three variants; 3 have one on none. By tier and
  `n_variants_near` (0 / 1 / 2 / 3): tier 1 — 0, 0, 1, 2; tier 2 — 0, 26, 22,
  50; tier 3 — 3, 19, 31, 46. The two tier-1 sites near Orang are near a
  pinch point on all three variants; the Bhadra site is not on `noghm`.
- **Stage-2 labels together.** Paths (Decision 18): gHM multiplier robust,
  road value robust. Network (Decision 19): robust, robust. Pinch points
  (Decision 20): **sensitive**, robust. The write-up must give all three.
- **Test before delivery** (R 4.3.3, `terra` 1.7-65, `sf` 1.0-15, with the
  real paths of the four layers and the real road raster). **Each printed
  figure is the same as on the project machine.** For each variant, a second
  route (dense points along each path line; `hclust()` for the sites; plain
  coordinate distances for the near flags) gave the same crossings, sites,
  `share_base` and near flags. Limit of that test: the `noghm` and `road15`
  surfaces were not available to the drafting chat, so their cost check ran
  there on a stand-in; the `road50` surface was rebuilt exactly from the
  baseline and the road cells (mean 25.450, as in `tbl_11`). The run on the
  project machine did the cost check on the three real surfaces.
- **Detail fixed at the build:** in `base_tier12_not_near_by_link` the
  entries are divided by " | ", because the link list of one site uses "; ".
- **Docs:** `data-dictionary.md` (the comparison table; the variant columns
  and layers), `naming-conventions.md` §6, `project-plan.md` (task 12.5
  ticked). Not yet: the Limitations (with the Week-12 docs close),
  `README.md`, `handoff.md`.

### 2026-10-10 — Week 12 (in progress): task 12.4 (STEP 12.3 sites and pinch points, baseline)

- **Details fixed at the build** (not in Decision 20; each put to the author
  before the code): `site_id` = 1 to n in the order of the lowest 1 km cell
  number of each site; the published position of a site = the 10 km cell
  that holds the mean of its distinct cell centres, with the state and
  district of that point; `tbl_14_road_crossings.csv` and the 1 km layer are
  written again with `site_id`. **Found in the build, not put to the
  author:** a mean position exactly on a line of the 10 km grid goes to the
  cell to the east or to the south (`pinch_grid_cell_xy()`); a site of two
  diagonal cells has this case.
- **Code.** `R/00_functions_pinch.R`: `pinch_build_sites()`,
  `pinch_min_site_gap_km()`, `pinch_apply_rule()`, `pinch_site_table()`,
  `pinch_link_summary()`, `pinch_check_publish_table()`,
  `pinch_grid_cell_xy()`, `pinch_admin_lookup_xy()`,
  `pinch_selftest_sites()`. `scripts/07_connectivity.R`: STEP 12.3; STEP
  12.2 now uses the same publish guard (no result changed).
- **Checks in the STEP (each stops the script).** A self-test on a hand-made
  case (22 cases: a join at exactly 5 km, no join at 6 km, a chain of 8 km,
  a parallel link that does not count as an edge, each tier, a position on
  a grid line). Each crossing is in one site; two sites are more than 5 km
  apart; the rule written a second way gives the same flags and tiers; the
  counts add up; each site on a bridge edge is a pinch point; no table holds
  a position finer than the publish grid (8 of 8).
- **Result on the project machine (2026-10-10).** **365 sites** from 556
  crossings; crossings per site median 1, maximum 8; 234 sites of one
  crossing; shortest gap between two sites 5.10 km; span median 0, maximum
  22.6 km; 4 sites with a span above 10 km. **200 pinch points (54.8 % of
  the sites):** `on_bridge` 101, `shared` 102; **tier 1 (both) 3, tier 2
  (`on_bridge` only) 98, tier 3 (`shared` only) 99.** 33 pinch points have
  `lit_flag` (each edge of the site has the flag), 35 `lit_flag_any`; 7 have
  a cell in a reserve footprint; 3 sites have parallel links only. Outputs:
  `tbl_14_pinch_points.csv` (365 rows, one per site),
  `tbl_14_pinch_link_summary.csv` (76 rows), `tbl_14_road_crossings.csv`
  and the 1 km layer again with `site_id`.
- **The three tier-1 pinch points.** Sites 54 and 56 (Assam, Sonitpur
  district): each used by Manas–Orang, Nameri–Orang and the bridge
  Orang–Dampa (a `lit_flag` link). Site 346 (Karnataka, Chikmagalur
  district): on two bridges, Bhadra–Kali and Bhadra–Nagarhole.
- **Assessment of the result (no rule changed).** The label separates
  little: more than half of the sites are pinch points. Decision 20 set no
  upper limit, and each crossing on a bridge edge is `on_bridge`: the 13
  bridge edges give 101 pinch points, and Sariska–Rajaji alone gives 21. Of
  the 261 sites that only non-bridge edges use, 99 are `shared`. 58 of the
  76 links have a pinch point; 17 edges have none. The tiers are the only
  order that Decision 20 gives; tier 1 is a list of three. How the write-up,
  `tbl_03b` and `fig_03` use the tiers is an author choice (tasks
  12.7–12.8).
- **Sites with a long span.** Site 24 (Sariska–Rajaji, Delhi): 7 crossings,
  span 22.6 km — the chain that Decision 20 names as a limitation.
- **Test before delivery** (R 4.3.3, `terra` 1.7-65, `sf` 1.0-15, with the
  real files). The Week-12 block ran as delivered; **each printed figure is
  the same as on the project machine.** A second method (single-linkage
  clustering of the crossing cells with `hclust()`, cut at 5 km) gave the
  same 365 sites. The flags and tiers, computed again from
  `tbl_14_road_crossings.csv` on disk, equal the site table.
- **Corrections in the build.** Two hand values of the site self-test were
  wrong at first (the 10 km cell of sites 2 and 4). For site 2 the code was
  right. Site 4 was the grid-line case; the rule for it is now explicit and
  the self-test holds it.
- **Docs:** `data-dictionary.md` (the three `tbl_14` tables of STEPs
  12.2–12.3 and the 1 km layer), `naming-conventions.md` §6 (`tbl_14` row),
  `project-plan.md` (task 12.4 ticked). Not yet: `README.md`, `handoff.md`.

### 2026-10-10 — Week 12 (in progress): task 12.3 (STEP 12.2 road crossings of the baseline paths)

- **These are the first road-crossing results.** Decision 20 was recorded
  before them (task 12.1).
- **Details fixed at the build** (not in Decision 20; put to the author
  before the code, answer "ok"): (1) the path cells come from the `cells`
  column that STEP 10.2 holds in memory (the layer on disk has no cell
  list); (2) the position of a crossing is the middle cell of its run (for
  an even run, the cell nearer the start); (3) the publish-grid columns are
  `grid10_id`, `grid10_x_km`, `grid10_y_km` (the centre of the 10 km cell,
  EPSG:7755); (4) state and district are those of the middle cell; (5) the
  1 km cells go to `data/processed/lcp_road_crossings_7755.gpkg` (one layer
  per surface, one point per crossing cell; gitignored); (6) `crossing_id` =
  `<pair_id>-<run number along the path>`. Added without a question, and
  reported: the column `district_code` (2011 census code; 10 district names
  are not unique).
- **Code.** `R/00_functions_pinch.R`: `pinch_path_cell_list()`,
  `pinch_cell_list_cost()`, `pinch_runs()`, `pinch_crossings()`,
  `pinch_grid_cell()`, `pinch_admin_lookup()`, `pinch_write_layer()`,
  `pinch_selftest()`. `scripts/07_connectivity.R`: STEP 12.2 after STEP
  12.1. State layer: `data/processed/boundary_states_7755.gpkg` (field
  `name`). District layer:
  `data/raw/administrative/boundary_districts_datameet2011_7755.gpkg`
  (fields `DISTRICT`, `censuscode`).
- **Checks in the STEP (each stops the script).** The self-test on a
  hand-made case (19 cases; one crossing lies only on the middle cells of a
  knight step). **The cost from each cell list must be the cost that the
  engine gave the path** (`cost_rkm`, relative 1e-9): this ties the third
  copy of the knight-step rule to the validated engine, on every path of
  every run. Each crossing cell is a barrier-road cell and a footprint cell;
  the counts add up; no column or position of the table is finer than the
  publish grid.
- **Result on the project machine (2026-10-10).** 76 paths (73 `edge`, 3
  `parallel`); cell lists 15,948 cells, 5,684 of them middle cells of knight
  steps. **556 crossings on 74 paths; 765 road cells on the paths** (4.8 %
  of the list cells, against 17.5 % of the footprint). Cells per crossing:
  median 1, mean 1.38, maximum 7; 380 crossings of one cell. By link role:
  `edge` 545, `parallel` 11. By `road_class_top`: motorway 10, trunk 234,
  primary 171, secondary 141. Crossings per path: median 6, range 0–35;
  median 3.5 per 100 km of path. 122 crossings on the 13 bridge edges; 49
  on the four links with `lit_flag`; 13 with a cell in a reserve footprint;
  166 with a middle cell of a knight step. One state came from the nearest
  polygon; no district did. Outputs: `tbl_14_road_crossings.csv` (556 rows)
  and the layer `baseline` of `lcp_road_crossings_7755.gpkg` (765 points).
- **Notes on the result (no rule changed).**
  - *Sariska–Rajaji goes through Delhi.* This bridge (the only
    north–central link, with `lit_flag`) has the most crossings, 35 (68 road
    cells; 8.9 per 100 km). Seven of them are in Delhi, with the two longest
    runs of the table (7 cells each; New Delhi and Central). The path is a
    true least-cost path on the baseline surface; the result shows how weak
    this geometry-rule link is.
  - *Two paths have no crossing:* Guru Ghasidas-Tamor Pingla – Sanjay Dubri
    (1.00 km) and Pench – Pench (MH) (11.36 km).
  - *State and district come from two layers* (Natural Earth states; DataMeet
    2011 districts) and can disagree at a border: one crossing has the state
    Haryana and a Delhi district.
- **Test before delivery** (R 4.3.3, `terra` 1.7-65, `sf` 1.0-15, with the
  real surface, reserve layer, paths file, road raster and admin layers).
  The Week-12 block ran as delivered; **each printed figure is the same as
  on the project machine.** A second route (dense points along each path
  line, never on a cell edge) gave the same cell lists and the same runs for
  76 of 76 paths. The 10 km cell ids equal those of
  `terra::aggregate(fact = 10)`. Six planted faults each stopped the script.
- **Error in the first delivery, corrected.** The first STEP 12.2 looked for
  the district layer in four folders and not in `data/raw/administrative`;
  the run on the project machine stopped before any output. The script now
  has the one path.
- **Docs:** `project-plan.md` (task 12.3 ticked). Not yet:
  `data-dictionary.md` and `naming-conventions.md` §6 for the `tbl_14`
  tables and the crossings layer (with task 12.4); `README.md`,
  `handoff.md`.

### 2026-10-10 — Week 12 (in progress): task 12.2 (process choices; STEP 12.1 barrier-road cells)

- **Process choices (not numbered; each put to the author before the code):**
  **A2** — the barrier-road cells are written one time to an interim raster,
  and a run switch `RUN_ROAD_CELLS` then reads it from disk; **B1** — the
  Week-12 functions go into a new file, `R/00_functions_pinch.R` (the engine
  file is not changed); **C1** — five `tbl_14` tables, baseline rows only:
  `road_crossings`, `pinch_points` (all sites, with the flags),
  `pinch_link_summary`, `pinch_variant_comparison`, `pinch_qa`; the counts
  per node go to `tbl_03`; **L2** — `PINCH_LIT_FLAG_PAIRS` holds `unit_id`
  pairs with a names guard (naming §5). L2 replaces the names-only list of
  the task-12.1 entry below: the `unit_id` of Sariska (41) is in
  `tbl_12_reserve_pairs.csv`.
- **Code.** New `R/00_functions_pinch.R` (`pinch_road_class_raster()`,
  `pinch_road_cell_counts()`, `pinch_check_road_cells()`,
  `pinch_lit_flag_pairs()`, `pinch_road_layer_name()`).
  `scripts/07_connectivity.R`: header (it now names `fig_03`), the switch
  `RUN_ROAD_CELLS`, a Week-12 settings guard, the `lit_flag` guard, and STEP
  12.1 after STEP 11.4. The code of Weeks 9 to 11 is not changed.
  `R/00_config.R`: `PINCH_LIT_FLAG_PAIRS` (L2).
- **STEP 12.1 — method.** The Decision-15 classes, each `_link` ramp in its
  parent class; one rasterise call per class with the arguments of STEP 9.6
  (`field = 1`, `background = 0`, `touches = TRUE`); each cell keeps the rank
  of its highest class (1 = motorway … 4 = secondary); mask = the footprint.
  The guard stops the script if: the grid is not the surface grid; the layer
  name does not record the class order of the config; a value is not a class
  rank; a road cell is outside the footprint; the Week-9 QA gives more than
  one count; or the cell count is not `n_road_cells` of
  `tbl_11_resistance_qa.csv`. The guard runs on the raster of the run and
  again on the file from disk.
- **Result on the project machine (2026-10-10).** Road layer 885,669
  features; barrier classes 444,234 (motorway 23,474; trunk 164,589; primary
  112,711; secondary 143,460). **535,592 barrier-road cells — the
  `n_road_cells` value of all four Week-9 surfaces**; 17.5 % of the
  3,067,467 footprint cells. By `road_class_top`: motorway 9,240 (1.7 %),
  trunk 155,723 (29.1 %), primary 168,278 (31.4 %), secondary 202,351
  (37.8 %). Read and rasterise 35 s. Guard 6 of 6, on the run and on the
  file. Output `data/interim/cov_roadbarrier_class_1km_7755.tif` (`INT1U`,
  read-back verified). `RUN_ROAD_CELLS` is now `FALSE`.
- **Test before delivery** (R 4.3.3, `terra` 1.7-65, `sf` 1.0-15; a synthetic
  grid and road set — the real road layer was not available to the drafting
  chat): the Week-12 block ran as delivered with the switch `TRUE` and
  `FALSE`; the cell set was identical to the cells of the one STEP-9.6 call;
  the class ranks were identical to a second calculation
  (`terra::cells()` per line); seven planted faults each stopped the script.
- **Details fixed at the build** (not in Decision 20): the file name
  `cov_roadbarrier_class_1km_7755.tif`; the class order is written into the
  layer name of the raster (`rank_motorway_trunk_primary_secondary`), so
  that a file built with a different order fails the guard.
- **Seen after Decision 20, from the Week-11 tables (no crossing):** all four
  `lit_flag` links are bridges (pairs 15, 46, 96 and 101; 4 of the 13
  bridges). `on_bridge` will therefore mark the sites on each of these links.
  Decision 20 gives this as a limitation; no rule changed.
- **Files checked for the crossing STEP** (2026-10-10): the baseline surface
  (3,067,467 cells, mean 22.463), the reserve layer (58 rows, 56 with
  geometry) and the paths file (4 layers of 106 pairs; baseline 97 paths, 85
  in the network; the costs equal `tbl_13_network_links.csv`). For 97 of 97
  baseline paths, the line vertices give back the path cells (count, exit
  cell, entry cell).
- **Docs:** `data-dictionary.md` (the new raster), `project-plan.md` (task
  12.2 ticked; the fifth table). Not yet: `naming-conventions.md` §6 (with
  the first `tbl_14` table), `README.md`, `handoff.md`.

### 2026-10-10 — Week 12, task 12.1: Decision 20 recorded (no code, no crossing)

- **Decision 20** fixes the road pinch-point rules before any road crossing
  is computed: the roads are the barrier-road cells of Decision 15; every
  in-network path gets its crossings and the rule counts the edges; a
  crossing is one unbroken run of barrier-road cells in the cell list of a
  path (knight-step middle cells included); reserve cells count and are
  flagged; crossings at most 5 km apart are one site; `pinch_point` =
  `on_bridge` or `shared` (two or more edges), in three tiers, with no order
  by road class; the same on the three variants, "robust" if the site
  overlap is at least 2/3; published positions at a 10 km grid cell with
  state and district; two publishable tables (`tbl_03`, `tbl_03b`) and the
  figure `fig_03`.
- **Fork codes** (raised and chosen 2026-10-10): a1, n1, b1, k1, c1, r1, m1,
  d1, t1, e2, p1, q1, g1; figure number `fig_03`; a policy rule. The author
  gave a1, n1, b1, c1, d1, e2, p1, q1, g1, `fig_03` and the policy rule in
  one answer; k1, r1, m1 and t1 had no code in that answer and were asked
  again before the Decision was written.
- **`R/00_config.R`:** new `PINCH_*` settings. No script reads them yet.
  `PINCH_LIT_FLAG_PAIRS` holds reserve names, not `unit_id`: the `unit_id`
  of Sariska was not in the files of the drafting chat. The script must
  check that each name resolves to one network reserve.
- **`docs/sensitive-data-policy.md`:** one new rule in §3 (modelled paths
  and road crossings). No other text of the policy changed.
- **Pending item closed:** "[Week 12] Pinch-point rule". **Pending item
  added:** "[Week 18] Published path layer".
- **`docs/project-plan.md`:** task 12.1 ticked; task 12.5 (variants) is now
  required; `fig_04` → `fig_03` in the Week-12 text; a second publishable
  table `tbl_03b`; the size estimate without the optional task is now
  4.9–6.9 hours.
- **`docs/references.md`:** new section "Road pinch points (Decision 20)" —
  five new entries, all read from abstracts and web pages only.
- **Not changed, to change when the file is next edited:** the header of
  `scripts/07_connectivity.R` still names `fig_04` (task 12.2);
  `handoff.md` still names `fig_04` and the pending Decision (end of the
  week). The Week-11 exit state in the plan keeps `fig_04` as a dated
  record.
- **Seen before this Decision:** the network results, the Decision-15 road
  cell counts and the Decision-18 route result. No road crossing. The author
  did not look at the paths on a map that shows roads. The Decision states
  this.

### 2026-10-04 — Week 11 complete: tasks 11.2–11.7 (network graph, metrics, variants, QA, literature check, docs)

- **Code.** New `R/00_functions_network.R` (nodes, links, graph, edge flags,
  sets, metrics, threshold scan, self-test, variant comparison, checks).
  `scripts/07_connectivity.R`: STEPs 11.1–11.4 after the Week-10 STEPs; the
  code of Weeks 9 and 10 is not changed. The Week-11 STEPs read the path
  layers from `lcp_reserve_network_7755.gpkg`; `pairs` and the reserve list
  come from STEP 10.1. No new run switch: the Week-10 STEPs run each time.
- **Run and verification.** Each STEP ran on the project machine after a
  Week-10 run. Each `tbl_13_*` table is identical to a separate build of the
  same STEPs on the same paths file (R 4.3.3, `igraph` 1.6.0). An independent
  check with Python (`networkx`, `scipy`) gave the same edges, bridges,
  spanning forest, betweenness, normalisation, cut nodes, linchpins, ρ and
  retention (largest difference 5e-16).
- **STEP 11.1 — nodes, links, graph (`tbl_13_network_links.csv`).** 56
  reserves → 47 nodes (7 blocks). 85 in-network pairs: 9 `block`, 0
  `within_block` (Nagarhole–Mudumalai and Mudumalai–Sathyamangalam are not in
  the network, P3), 73 `edge`, 3 `parallel` (Pakke–Manas, Nameri–Kaziranga,
  Anamalai–Sathyamangalam). No node without an edge. 3 sets: 33 nodes (34
  reserves; `central` + `north`), 8 (13; `western_ghats`), 6 (9;
  `northeast`) — the same sets that all 106 pairs give, so P3 divided no set.
  13 bridges; 44 edges in the minimum spanning forest. 10 of 10 construction
  checks.
- **STEP 11.2 — metrics, second run, scan (`tbl_13_network_metrics.csv`,
  `tbl_13_network_threshold_scan.csv`).** The self-test on the hand-computed
  graph runs first (17 of 17 cases).
  - **Linchpins (8 nodes):** set 1 — Madhav (0.357), Guru Ghasidas-Tamor
    Pingla (0.292), Sanjay Dubri (0.252); set 2 — Bandipur + Nagarhole +
    Mudumalai + Sathyamangalam (0.714), Bhadra (0.476), Parambikulam +
    Anamalai (0.476, tied at rank 2); set 3 — Pakke + Nameri (0.600), Orang
    (0.400). In set 3 only two nodes have a value above 0.
  - **Cut nodes: 12.** Seven are not linchpins: Kali, Periyar +
    Srivilliputhur-Megamalai, Similipal, Sariska, Dudhwa, Corbett, Rajaji.
  - **Isolated: none** — no reserve is isolated by the rule. **Pendant: 6** —
    Valmiki, Sundarbans, Dampa, Sahyadri, Kalakad-Mundanthurai, Biligiri
    Ranganatha Temple. Highest cheapest-link cost: Valmiki 4,186; Sundarbans
    2,691; Nagarjunsagar-Srisailam + Amrabad 2,074; Sariska 1,900; Dampa
    1,311 resistance-km.
  - **Sariska: `betweenness_norm` 0.2258 = 112 / 496,** exactly the value that
    Decision 19 gave from the pair layout. Sariska is on no other shortest
    path; rank 4, not a linchpin.
  - **Second run (point 9):** 1 cross-group link removed (Sariska–Rajaji); 72
    edges; 4 sets (29, 8, 6, 4 nodes). **Madhav is `cross_group_dependent`**:
    rank 1 (0.357) in the main graph, rank 5 (0.214) without the link; Kanha
    becomes a linchpin (rank 2, 0.251). In the `north` set of 4 nodes, Dudhwa
    and Corbett are both rank 1 (0.667).
  - **Scan:** 73 rows, 44 joining edges. The last joins: Ranthambore–Sariska
    1,900; Nagarjunsagar-Srisailam–Indravati 2,074; Similipal–Sundarbans
    2,691; Valmiki–Dudhwa 4,186; Sariska–Rajaji 5,637 resistance-km. No
    threshold chosen.
- **STEP 11.3 — variants (`tbl_13_network_variant_comparison.csv`).** Rule
  fixed in Decision 19 point 10.

  | Variant (tests) | Links | Edges (changed) | Sets same | ρ | Linchpins retained | Cut nodes same | Label |
  |---|---|---|---|---|---|---|---|
  | `noghm` (gHM multiplier) | 87 | 75 (5) | yes | 0.941 | 7 of 8 (0.875) | no | robust |
  | `road15` (road value) | 84 | 72 (2) | yes | 0.979 | 8 of 8 | yes | robust |
  | `road50` (road value) | 87 | 75 (5) | yes | 0.995 | 7 of 8 (0.875) | no | robust |

  By the rule: **gHM multiplier — robust; road value — robust** (both road
  variants). **7 stable linchpins.** Sanjay Dubri is not stable: on `noghm`
  and `road50`, Pench (MH) is a linchpin in its place. The metrics table was
  written again with 7 more columns (32 in all).
- **STEP 11.4 — network QA (`tbl_13_network_qa.csv`).** 91 of 91 checks: the
  self-test; on each surface the 10 construction checks, 7 result checks, the
  betweenness identity and the edge weights; baseline checks of the blocks,
  bridges, second run and scan; the tables on disk. The identity (the sum of
  betweenness in a set = the nodes between the ends of the shortest paths,
  from `igraph::all_shortest_paths()`, not from `betweenness()`) holds on
  each surface (baseline set 1: 1862 = 1862).
- **As built against the Decision-19 "Consequences" text** (the Decision text
  is a dated record and is not changed):
  - The hand-computed self-test runs at the start of STEP 11.2, so that it
    is before any metric (point 11). STEP 11.4 collects it.
  - A fifth table, `tbl_13_network_qa.csv` (process choice **q1**).
  - The graph is rebuilt from the paths layer on each run; it is not written.
- **Details fixed at the build** (not in Decision 19; each was put to the
  author before the code): the second-run columns are the sets, the
  normalised betweenness, its rank, the linchpin flag and
  `cross_group_dependent` only; the scan has one row per edge and no row for
  the empty graph; `cheapest_link_rank` ties take the lowest rank number;
  the metrics table carries `betweenness_norm_<variant>` and
  `linchpin_<variant>`; `n_edges_changed` counts node pairs with an edge on
  one surface only or an edge from a different `pair_id`; the 2/3 limit has
  a tolerance of 1e-9; ranks use values rounded to 10 decimal places; a
  variant with no ρ or no baseline linchpin is "sensitive". The comparison
  table has no `choice_label` column (the Week-10 summary table has one);
  the labels by choice go to the console.
- **Judgement values.** 3, 0.9 and 2/3 were recorded on 2026-10-03 as
  proposed; the author went on to the code with no change.
- **Literature check (task 11.6; `references.md`, "Week-11 network").**
  Descriptive; from abstracts, web pages and extracts. Agrees: Guru
  Ghasidas-Tamor Pingla between Bandhavgarh and Palamau; Kanha and Pench with
  the highest centrality in Dutta et al. (2016); the Bandipur block as the
  largest population, with the Bhadra–Kali connection at risk; Sundarbans,
  Dampa and Sahyadri weakly connected. Does not agree or no source: Madhav
  (no source for a high centrality); Anamalai–Periyar (described as not
  connected along Kerala); Orang–Dampa (no source; a 305 km gap);
  Periyar–Kalakad-Mundanthurai (the Shencottah gap is a barrier; the cost is
  low); Nagarjunsagar-Srisailam + Amrabad (no source for a northern link).
- **Two data items, author choice g1.** Sources call Guru Ghasidas-Tamor
  Pingla and Sanjay Dubri contiguous; the pair table has a 1.59 km gap, so
  they are two nodes (both baseline linchpins). Sources name BRT in the
  Bandipur block; it is 10.1 km from Sathyamangalam, so it is a separate,
  pendant node. **g1: Decision 17 stays as it is; both are recorded as
  limitations.** A merge rule now would be post-result.
- **Process choices (not numbered):** q1 (QA table); g1 (above); the new
  function file `R/00_functions_network.R`.
- **Pending item added:** "[Week 12] Pinch-point rule".
- **Docs:** `data-dictionary.md` (five `tbl_13_*` entries),
  `naming-conventions.md` §6 (`tbl_13` row), `references.md` (two new
  sections), `README.md`, `project-plan.md`, `handoff.md`; Limitations below.

### 2026-10-03 — Week 11, task 11.1: Decision 19 recorded (no code, no metric)

- **Decision 19** fixes the reserve network rules before any network metric:
  all in-network pairs are links with the cost as the weight (no threshold);
  contiguous reserves merge into blocks (56 reserves → 47 nodes); betweenness
  normalised by the node's own set; `linchpin` = top 3 in the set, with
  `cut_node` next to it; `isolated` = degree 0, with `pendant` and the
  cheapest-link cost as graded columns; a threshold scan (descriptive); a
  second baseline run without cross-group links; the metrics repeated on the
  three variants with a fixed comparison (sets the same, ρ ≥ 0.9, linchpin
  retention ≥ 2/3).
- **`R/00_config.R`:** new `NET_*` settings. No script reads them yet.
- **Pending item closed:** "[Week 11] Functional-link rule".
- **`docs/project-plan.md`:** task 11.1 ticked; Week-11 text changed from "56
  nodes" to "47 nodes from 56 reserves"; a fourth table,
  `tbl_13_network_threshold_scan.csv`, added.
- **`docs/references.md`:** new section "Reserve network (Decision 19)".
- The path costs were seen before this Decision (Week 10). The Decision
  states this and uses no cost value in any rule.

### 2026-10-03 — Text fix before Week 11 (two stale statements)

Found when the Week-11 chat read the files. No rule, value, data layer or
script logic changed; no re-run.

- **§5.3 Connectivity.** It still named the tool as "`leastcostpath` or
  `gdistance`", fixed in Decision 17 (the wording of process choice F1-A,
  2026-09-27, from before Decision 17). As built, the engine is our own
  16-neighbour cell graph (`R/00_functions_lcp.R`, `terra` + `igraph`), and
  `gdistance` is for validation only. §5.3 now says so.
- **`R/00_config.R`, `ROAD_BARRIER_TOUCHES` comment.** It gave the reason only
  for an 8-neighbour path (the wording of Decision 15 point 4, from before
  Decision 17). The comment now also names the 16-neighbour engine: knight
  steps are stopped by the crossed-cells rule (Decision 17 point 3). The value
  (`TRUE`) does not change. The text of Decision 15 (point 4 and the
  "Rejected" line) is a dated record and is not changed.

### 2026-10-03 — Week 10 complete: tasks 10.4–10.9 (pairs, baseline paths, validation, QA, variants, NTCA overlap, docs)

- **`R/00_functions_lcp.R`:** new `lcp_alloc_zones()`, `lcp_zone_adjacency()`
  and `lcp_build_pairs()`. Allocation (Decision 17 point 1): each footprint
  cell goes to the nearest reserve polygon edge, densified to 250 m (exact to
  within 125 m), with `sf::st_nearest_feature()` in chunks of 250,000 cells.
  The cells of each reserve take their own reserve; a shared cell goes to the
  lower `unit_id`.
- **`scripts/07` STEP 10.1** → `tbl_12_reserve_pairs.csv` and
  `data/interim/lcp_pair_zones_1km_7755.tif` (QA only). Guards: every
  `unit_id` once in `NETWORK_GROUPS`; the geometry-absent reserves are exactly
  `LCP_EXCLUDED_UNIT_IDS`; no reserve without footprint cells; the allocation
  covers the footprint; the pair count within 106 ± 10 %; no duplicate pair;
  `contiguous` agrees with `gap_km`. The Week-10 inputs are now read once;
  `RUN_LCP_SMOKE` is now `FALSE`.
- **Result on the project machine:** 132 candidate pairs, 26 above the 315 km
  cap, **106 kept** — the count of the Decision-17 geometry check. 3 connected
  sets (34, 13 and 9 reserves); no reserve without a pair. Gap median
  106.8 km, maximum 310.8 km. 9 contiguous pairs: the 8 gap-0 pairs and
  Namdapha–Kamlang (0.3 km). 2 cross-group pairs: Sariska–Corbett (292.7 km)
  and Sariska–Rajaji (290.8 km). Pairs inside one group: central 65,
  western_ghats 23, northeast 13, north 3. Reserve cells: minimum 45
  (Veerangana Durgavati), median 740, maximum 3,054 (Manas). Allocation 24 s.
- **Found in testing (fixed before delivery):** `terra::nearest()` is a
  brute-force search (about 5 hours for the footprint), so the code uses
  `sf::st_nearest_feature()`. In `sf` 1.0-15, `st_cast()` of the whole
  boundary set to POINT gave the points the wrong reserve ids (the first test
  gave 36 pairs and 22 isolated reserves; the check against the expected 106
  found it). The points are now built per reserve from its own coordinates,
  and a guard checks that each reserve's points lie on its own edge.
- **Task 10.5 — baseline paths.** New `lcp_paths_for_pairs()`,
  `lcp_apply_through_rule()` and `lcp_write_layer()`; `scripts/07` STEP 10.2 →
  `lcp_reserve_network_7755.gpkg`, layer `baseline` (read back and checked).
  Code rule not stated in Decision 17: a pair with no path gets
  `in_network = FALSE` (no route, so no link). No such pair occurred.
- **Result on the project machine:** graph built in 6 s; 44 source searches
  in 27 s. 97 paths, 9 contiguous, 0 with no path. Cost median 577.3, maximum
  5,814.2 resistance-km. Length median 163.3 km, maximum 619.4 km. Length/gap
  median 1.34, range 0.63–4.18 (the console does not name the pairs at the
  extremes; a ratio below 1 is possible for a very short gap, because the line
  joins cell centres). 26 paths cross another reserve; **21 pairs are not in
  the network** under point 2, for example Sariska–Corbett (crosses Rajaji,
  with Sariska–Rajaji and Rajaji–Corbett both pairs) and Indravati–Amrabad
  (crosses Nagarjunsagar-Srisailam). Some paths cross several reserves, for
  example Bandhavgarh–Panna (gap 119 km; crosses Guru Ghasidas-Tamor Pingla,
  Sanjay Dubri and Ranipur) and Kaziranga–Orang (gap 70 km; crosses Pakke and
  Nameri). Task 10.6 QA names the pairs at the extremes.
- **Task 10.5b — validation (Decision 17 point 4).** `scripts/07` STEP 10.2b
  → `tbl_12_lcp_validation.csv`. Two process points: (1) the three fixed pairs
  are taken from the pairs with a path — under C1 the pair with the shortest
  non-zero gap (Namdapha–Kamlang, 0.3 km) is contiguous and has no path to
  check; (2) **V-add** (author choice, 2026-10-03): the pair with the highest
  `path_gap_ratio` is checked as well. It is an extra check; the fixed three
  stay. Found in testing: at its default of 50 iterations,
  `terra::costDist()` did not converge on a long window; the check now uses
  `maxiter = 1000` and records any warning.
- **Result on the project machine:** (a) 7 of 7; (b) and (c) pass on pair 31
  Guru Ghasidas-Tamor Pingla – Sanjay Dubri (shortest gap), 28 Achanakmar –
  Bandhavgarh (median), 3 Namdapha – Pakke (longest) and 59 Bandhavgarh – Panna
  (highest ratio, 4.18). Largest relative difference 1.5e-15; path overlap
  1.000 on every pair; no terra warning. The Bandhavgarh – Panna detour
  (through Guru Ghasidas-Tamor Pingla, Sanjay Dubri and Ranipur) is therefore
  a true least-cost path on the baseline surface, not an engine fault.
- **Task 10.6 — path QA.** New `lcp_path_cost()` (cost and length recomputed
  from the raster, without the graph) and `lcp_qa_paths()`; `scripts/07`
  STEP 10.3 → `tbl_12_lcp_qa.csv`. In testing, the QA failed each planted
  fault (a changed cost, removed path cells, a start in the wrong reserve).
- **Result on the project machine:** 106 of 106 pairs accounted for; every
  check passes on every pair. Lowest length/gap ratio: Guru Ghasidas-Tamor
  Pingla – Sanjay Dubri, 0.629 (path 1.00 km, gap 1.59 km — the line joins
  cell centres); the next lowest is 1.003. Highest ratios: Bandhavgarh – Panna
  4.18 (gap 119.0 km, path 496.9 km), Tadoba-Andhari – Pench (MH) 3.58,
  Bandhavgarh – Ranipur 3.00, Nameri – Kaziranga 2.75, Sanjay Dubri – Ranipur
  2.41. Highest costs: Sariska – Corbett 5,814 and Sariska – Rajaji 5,637
  resistance-km (the two cross-group pairs), then Valmiki – Dudhwa 4,186.
- **Literature check of the extremes (author request, 2026-10-03; sources in
  `references.md`, "Week-10 path extremes").** A check of each extreme against
  published evidence. It changes no value and no Decision.
  - *Agrees:* the highest costs. Sariska–Corbett and Sariska–Rajaji: mtDNA
    shows the western (Sariska, Ranthambore) and the northern (Terai)
    populations as genetically distinct (Sharma et al. 2009, 2011).
    Valmiki–Dudhwa: the Indian Terai is fragmented into nine habitat blocks
    (Johnsingh et al. 2004); Valmiki connects with Chitwan, and Pilibhit with
    Shuklaphanta, through Nepal — a route that the India-only surface cannot
    show (Limitations, "Paths stay inside India").
  - *Partly agrees:* Tadoba-Andhari – Pench (MH) (ratio 3.58) — tigers from
    Tadoba move north-east to Umred-Karhandla, Nagzira and Navegaon, and
    Nagzira–Pench is a high-flow link (news reports only; the route of the path
    was not inspected). The Panna–Ranipur part of the Bandhavgarh routes
    agrees with a documented dispersal corridor (Sarkar et al. 2021).
  - *Does not agree:* Bandhavgarh–Panna (ratio 4.18) — NTCA records a direct
    Panna–Bandhavgarh corridor with a ~30 km gap along the Ken and Midhassan
    that needs restoration; the path goes round it. Nameri–Kaziranga (2.75) and
    Kaziranga–Orang (via Pakke and Nameri) — NTCA records connectivity through
    the Brahmaputra river islands, and genetic work groups Kaziranga with
    Nameri (preprint); the paths avoid the river, which follows from the water
    value (Decision 14). Validation (task 10.5b) shows these are true
    least-cost paths on the baseline surface; the disagreement is with the
    surface's values, not with the engine. *Author choice (L1):* recorded as a
    limitation (Limitations, "Least-cost routes can differ from documented
    corridors"); no Decision changes.
- **Task 10.7 — variant paths and Decision 18.** New `lcp_route_share()`,
  `lcp_compare_variant()` and `lcp_compare_summary()`; `scripts/07` STEP 10.4
  → layers `noghm`, `road15`, `road50` in `lcp_reserve_network_7755.gpkg`;
  `tbl_12_lcp_qa.csv` now holds all four surfaces (424 rows, author choice);
  `tbl_12_lcp_variant_comparison.csv` (291 rows) and
  `tbl_12_lcp_variant_summary.csv`. Each variant must have the baseline's NA
  footprint (guard).
- **Result on the project machine:** each variant 97 paths, 9 contiguous, 0
  with no path; QA 0 failures on all 424 rows. Pairs not in the network:
  baseline 21, `noghm` 19, `road15` 22, `road50` 19. Decision 18, 97 compared
  pairs per variant (9 contiguous excluded):

  | Variant (tests) | Material route | Material rank | Material pair | ρ | Median route overlap | `in_network` changed | Label |
  |---|---|---|---|---|---|---|---|
  | `noghm` (gHM multiplier) | 18 (0.186) | 0 | 0.186 | 0.985 | 0.844 | 4 | robust |
  | `road15` (road value) | 11 (0.113) | 0 | 0.113 | 0.995 | 1.000 | 1 | robust |
  | `road50` (road value) | 9 (0.093) | 0 | 0.093 | 0.997 | 1.000 | 4 | robust |

  By the rule fixed in Decision 18: **gHM multiplier — robust; road value —
  robust** (both road variants robust). `noghm` is 1 pair inside the limit: the
  20 % limit allows 19 of 97 material pairs, and 18 are material. No pair has a
  material rank change in any variant; every material pair is a route change.
  Among the material route changes are pairs from the literature check:
  Bandhavgarh – Panna (route overlap 0 under `noghm` and `road50`) and
  Nameri – Kaziranga (0.375 under `road15` and `road50`).
- **Task 10.8 — NTCA corridor overlap (Decision 17 point 9; descriptive, not
  a validation).** New `lcp_ntca_overlap()`; `scripts/07` STEP 10.5. The two
  measures have different units, so they go in two tables (implementation
  choice): `tbl_12_lcp_ntca_overlap.csv` (per pair) and
  `tbl_12_lcp_ntca_corridors.csv` (per corridor). No buffer is used, as
  Decision 17 fixes none.
- **Result on the project machine:** 97 baseline paths — share inside
  corridors median 0.064, mean 0.128; 42 paths with share 0; 55 cross at
  least one corridor. 31 of 59 corridors are crossed by at least one path.
  Of the 28 corridors that no path crosses, many have a label that names a
  place outside the reserve network (for example `dhudwa_nepal1`,
  `kat_khata_corri`, `buxa-jaldapara`, `Dibru Saikhowa-`,
  `kaziranga-karbianlong2`, `kaziranga-itanagar`, `cauveri-bannerghata`,
  `kuderemukh_bhadra`, `NSTR-Tirupati`). `kaziranga-orang` and
  `kaziranga-nameri2` are not crossed (see the L1 limitation);
  `manas-manas-buxa` is not crossed because Manas–Buxa is a contiguous pair
  with no path. Highest shares: Anamalai – Srivilliputhur-Megamalai 0.728,
  Periyar – Anamalai 0.709 (both through corridors 43 and 47).
- **Task 10.9 — end-of-week docs.** `naming-conventions.md` §6: `tbl_12` row
  (7 tables, checked against a listing of `outputs/tables/`). `README.md` and
  this Status: Week 10. `handoff.md`: current state, Week-10 log, new gotchas,
  Week-11 entry point; two stale current-state lines corrected (the "~0.58"
  median, now 0.515; the `area_provisional = FALSE` gotcha, which holds only
  in the stats layer). `project-plan.md`: Week 10 ticked.

### 2026-10-02 — Week 10 (in progress): tasks 10.1–10.3b

- **Decisions 17 and 18** recorded on 2026-10-01 (the first record gave
  2026-09-27 by mistake; corrected). Decision 17 amended 2026-10-02, before any
  path: a contiguous pair shares a footprint cell (C1); how check (b) runs; the
  gap-0 count after the split is 8, not 7. Decision 18 point 1 follows C1.
- **Task 10.3 — path engine and tool check.**
  - `R/00_functions_lcp.R` (new): own 16-neighbour cell graph with the
    crossed-cells knight rule, searched with `igraph` Dijkstra from all cells
    of the source reserve; validation checks (a)–(c); `lcp_contiguous()`,
    `lcp_mem_report()`. Checks (a)–(c) passed in a sandbox (terra 1.7-65,
    igraph 1.6.0, gdistance 1.6.5): 7 of 7 hand-computed cases;
    `terra::costDist` and `gdistance` agree to a relative 1.2e-15.
  - `scripts/00a`: package list set from `renv::dependencies()` — added
    `gdistance`, `raster` (validation), `gifski`, `osmextract`,
    `rnaturalearth`, `tibble`, `xml2`; `rnaturalearthhires` from the rOpenSci
    R-universe (not on CRAN); removed `leastcostpath`, `osmdata`, `readxl`,
    `exactextractr` (no script uses them). `renv.lock` updated.
  - `scripts/07`: run switches (process choice RS1): `RUN_RESISTANCE <- FALSE`
    skips the Week-9 STEPs; a guard checks the four surfaces on disk against
    `tbl_11_resistance_qa.csv`; STEP 9.2 adds `_split` to its gap-table label
    when the reserve layer has split parts. New STEP 10.0 (tool check).
  - **STEP 10.0 on the project machine:** surface guard OK for all 4 surfaces
    (3,067,467 cells each); self-test 7 of 7; graph 3,067,467 nodes and
    24,462,121 cell edges, built in 8 s; Kanha → Pench in one search of 0.3 s:
    422.6 resistance-km, 90 cells, 129.9 km, gap 106.2 km (length/gap 1.22).
    R heap 1.5 GB; the process peak was not measured (3.2 GB in a sandbox test
    of the same graph size). No crop is needed.
- **Task 10.3b — Amrabad split (Decision 17, D1a).** `scripts/02`: new STEP 4b
  (state split per `BOUNDARY_STATE_SPLITS`) and the re-run guard G-a (only the
  split reserves may change, in `geometry_present`, `match_status`, `n_parts`,
  `poly_km2`, `poly_census_ratio`; the parts must add up to the area on disk).
  Re-run 02 → 03 → 04 → 05:
  - 02: Nagarjunsagar-Srisailam 2,372.7 km², Amrabad 2,701.2 km² (2 polygons);
    56 reserves with geometry, 2 absent; guard "first split" passed.
  - A before/after check reported PASS: `tbl_01`, `tbl_02_regional_rollup`,
    `tbl_06`, `tbl_09` and `fig_01` identical; `tbl_02_reserve_build_report`,
    `tbl_07`, `tbl_08` and both layers changed only on units 1 and 51, in the
    allowed fields; `fig_02` re-rendered (Amrabad drawn). Census, area,
    density and growth values did not change.
  - `scripts/03` and `05`: comments only (they named Amrabad as
    geometry-absent).
  - `scripts/07` was not re-run: the split does not change the resistance
    surfaces. The recorded Week-9 `tbl_11` gap tables keep the pre-split
    polygons and stay the Week-9 record.
- **Corrected:** the polygon/census ratio median. Docs said "near 0.58"; the
  data give 0.51 for the 55 reserves before the split (mean 0.546) and 0.515
  for the 56 after it. Corrected in `data-dictionary.md`, `data-sources.md` and
  the Limitations; historical entries below keep the old text.
- **Found, not changed:** `scripts/03` line 101 passes literal text to
  `readr::read_csv()`, which `readr` 2.2.0 deprecates (lifecycle warning). A
  later `readr` can stop the script. Fix: wrap the text in `I()`; no output
  changes.

### 2026-09-27 — Documentation fix pass (before Week 10)

A consistency check after Week 9 found stale or inconsistent statements. No
analytical rule, data layer or script changed. Historical change-log entries
are left as written; this entry records the corrections.

- **§5.3 Connectivity.** It named `leastcostpath` as the path tool, but
  Decision 17(b) keeps the tool open. It now says the tool is fixed in
  Decision 17. It also gave the resistance basis as land cover and roads and
  omitted the gHM multiplier; it now names the multiplier and the variants
  (Decisions 14–16). The `README.md` Stack row changed the same way for the
  tool.
- **`scripts/00a` package list (process choice F1-A).** `00a` still lists
  `leastcostpath`. It is not changed now: task 10.3 sets the list to the
  Decision-17 tool, so the code change occurs in the week that makes the
  choice.
- **Settlement pending item** relabelled "[Week 8–9 → Week 13]" (as in the
  handoff). The KDE that needs it is built in Week 13.
- **`data-dictionary.md`.** The `dist_road_m` band, the `cov_distroad` note
  and the `tbl_10` section carried Week-8 figures (3,010,738 cells; 98.15 %;
  max 278.9 km; mean 2,019 m). Updated from the `d13f` `tbl_10`: 3,067,467
  cells; `pct_of_india` 100 after rounding; `dist_road_m` max 279,692.7 m,
  mean 2,044.3 m. Also corrected: `WORLDCOVER_RESISTANCE` was called "a
  starting set, not a Decision" (it is Decision 14); the `tbl_10` header said
  2 columns were added on 2026-09-26 (6 were), and its note said they "appear
  after `scripts/06` is re-run" (they exist); the `source_stat` note gave the
  Week-8 trim as the only cause of a gap; the last line listed `resist` as not
  yet documented.
- **`naming-conventions.md` §6.** `tbl_11` holds 7 tables and was missing from
  the "As built" list. Added; the names were checked against a listing of
  `outputs/tables/` (2026-09-27). The handoff gotcha on table numbers now
  names `tbl_11` too.
- **`data-sources.md`, OSM.** The tertiary-road question was still listed as
  pending; Decision 15 closed it. The settlement flag now points to Week 13.
- **`project-plan.md`, Week 10.** The entry state said resistance is `NA`
  "only on the 98 cells", and a pitfall said "the grid ends 5 km outside
  India". The surfaces are `NA` on every cell outside the complete-case
  footprint: the 98 India cells and every cell outside India, the 5 km collar
  included. No path can leave India. Both corrected; the handoff Week-10 note
  and its `resist_*` gotcha (which also repeated two sentences) now say the
  same.
- **`README.md`.** The Growth row in the track table said "2006–2022"; the
  series is 2014/2018/2022 with 3 frames (Decision 6). Corrected.
- **Location of `tbl_04_secondary_sources_2006_2010.md`.** Docs cited it in
  `docs/`; the file is only in `outputs/tables/` (confirmed 2026-09-27).
  Corrected in `data-sources.md` (2 places), `references.md` and
  `naming-conventions.md` §6. Two historical records keep the old path, as
  written: the 2026-09-12 change-log entry below and the Week-4 outcome in
  `project-plan.md`. The correct path is
  `outputs/tables/tbl_04_secondary_sources_2006_2010.md`.
- **`proposal.md` §8.** New deviation entry: the resistance surface adds human
  pressure to land cover and roads (Decisions 14–16); the land-cover + roads
  form is the `noghm` variant. §5 (connectivity) points to it, as the growth
  item already points to the Decision-6 entry.

### 2026-09-26 — Week 9 (in progress): task 9.2 rule fixed; corridor layer

- **Decision 11** recorded before the check was run: the gHM gap-fill relevance
  rule (units, membership, land-only count, 5 % / 25-cell threshold) and the
  fill method if triggered. Sources added to `docs/references.md`.
- **Plan gap closed (task 9.2a).** No task extracted the 59 NTCA corridor
  polygons that Week 3 set aside. `scripts/02` now writes them to
  `data/processed/boundary_corridors_7755.gpkg`. A re-run guard in `scripts/02`
  STEP 6 compares the rebuilt reserve layer with the one on disk before writing
  and stops if any attribute or polygon area differs.
- **`scripts/07_connectivity.R` started:** header for all of Stage 2 (task 9.1)
  and STEP 9.2 (the check). The resistance STEPs are not written yet.
- **Pre-fill check run: TRIGGERED** (27 of 169 units; see Decision 11
  outcome). `scripts/02` re-run: the guard reported the reserve layer
  identical; 59 corridors written, all with a `Corridor` label.
- **Fill implemented** in `scripts/06` STEP 8.4b (`GHM_GAP_FILL`), with guards
  (real gHM values unchanged; filled values inside 0–1). `tbl_10` gains
  `n_filled`. `scripts/07` output names now carry `_prefill` / `_postfill`, and
  a post-fill trigger stops the week for a new decision.
- **Corridor labels:** two labels held an escaped XML entity
  (`Dibru Saikhowa-D &apos;e`, `D&apos; Ering-mehao`; the KML escapes them
  twice). `scripts/02` now decodes the standard XML entities in the corridor
  fields only. The PA names that drive the reserve build are not changed.
- **Post-fill check run: STILL TRIGGERED** (1 corridor, `dhudwa_nepal2`; 6
  no-class cells). The gHM fill closed every eligible land gap (54,958 filled;
  91 water cells left). Complete-case cells 3,065,696 (99.94 %).
- **Decision 12** made after that result: gHM closed; land cover rebuilt in
  `scripts/06` from the unmasked tile cache and masked on the template; a
  `postfill_d12` re-check follows. `scripts/07` reads the aligned land cover
  that `06` now writes, and reports edge vs interior no-class cells.
- **Correction to the 2026-09-26 fix-pass entry below:** its "edge halo" item
  says landcover has +13 cells just outside India. That is a net figure: the
  landcover band had 1,791 cells outside India and no class in 1,778 India
  cells. The terrain "+20" is also a net figure.
- **Elevation on water cells:** the stack minimum is now −344.8 m (probably
  sea-floor depth in the AWS terrain tiles). Added to the Week-14 pending item.
- **`postfill_d12` check run: STILL TRIGGERED** (corridor `dhudwa_nepal2`, 5
  of 42 land cells). Land cover fixed (3,067,558 of 3,067,565 India cells have
  a class; 7 interior cells do not). The loss stayed at 1,869: terrain is `NA`
  at the 1,771 edge cells.
- **Decision 13** made after that result: terrain rebuilt in `scripts/06` from
  the raw DEM (the `scripts/01` path without its mask), masked on the template,
  with an interior guard; the 7 interior no-class cells accepted. `tbl_10` gains
  `terrain_source` and `build_tag`; `scripts/07` labels outputs
  `postfill_<build_tag>` and prints the interior no-class cells.
- **`postfill_d13` check run: CLEAR — Decision 10 closed.** 0 units with any
  dropped land cell. Complete-case cells 3,067,467; 98 dropped (91 water + 7
  no-class cells at WorldCover tile corners). gHM filled 56,729. Guards PASS
  (terrain core difference 0).
- **Task 9.2 is complete.** Next: task 9.3 (Decision 14, land-cover resistance
  values) and task 9.4 (Decision 15, barrier road classes), both before any
  resistance STEP is written.
- **Decision 14 recorded (task 9.3).** Literature review (movement, genetics,
  Sundarban telemetry, national method) and a data check of WorldCover class
  shares inside reserves vs India. Set B class values; gHM multiplier k = 4,
  cap 100; Sundarban water region (reserve + 10 km ring) at 10, water 50
  elsewhere; variant k = 0 for a Week-10 comparison. The data check removed the
  first basis for class 90 (no reserve cells); the value 3 stays on a corrected
  basis. `R/00_config.R` updated; `references.md` gains the sources. Raised a
  pending item: SDM-based resistance + circuit-theory check after Stage 3.
- **Defect found and fixed: the stack file was written as `INT1U`.** The
  task-9.4 road check read the stack from disk and found gHM = 0 everywhere
  (`tbl_10`: mean 0.377). `datatype()` confirmed `INT1U` for all six bands:
  a GeoTIFF holds one data type, and `terra::writeRaster()` chose unsigned
  8-bit. On disk: gHM and distance-to-road 0; elevation and TRI cut to 0–254;
  slope without decimals; land cover intact. **Scope:** every `scripts/06`
  build written so far. `tbl_10` and all Decision 10–13 figures were computed
  in memory and are correct; STEP 9.2 read only the land-cover band and its
  `NA` pattern from disk and matched `tbl_10`, so its results stand. **Fix:**
  `write_processed_rast()` now takes an explicit `datatype` (default `FLT4S`;
  compression predictor 3 for float, 2 for integer) and reads every written
  raster back, stopping if any band's mean or `NA` count differs from memory.
  `scripts/06` writes the stack as `FLT4S` (land cover as `INT2U` in its own
  file); `BUILD_TAG` → `d13f`, so the `scripts/07` re-check is labelled
  `postfill_d13f`. **Lesson:** QA must run on the file that later scripts read,
  not only on the object in memory.
- **Stack rebuilt with the fix (`build_tag` d13f):** every write read back and
  verified; on disk `FLT4S`, gHM max 0.993 / mean 0.377, elevation min −434.2,
  distance-to-road mean 2,044. `tbl_10` values unchanged. `scripts/07` re-check
  `postfill_d13f`: **CLEAR** (98 dropped; 0 units affected) — Decision 10's
  closure holds on the correctly written file. A colour table inherited from
  the WorldCover tiles caused write warnings (values unaffected); `scripts/06`
  now removes it before writing.
- **Decision 15 recorded (task 9.4).** Barrier classes motorway–secondary
  (tertiary left to gHM); one value 30; maximum rule; `touches = TRUE`;
  railways and crossing structures as limitations; variants `road15` and
  `road50`. Data check: barrier roads touch 17.5 % of India's cells (34.8 %
  with tertiary); gHM on those cells 0.525 vs 0.377 for India.
- **Resistance STEPs written (tasks 9.5–9.8)** in `scripts/07_connectivity.R`:
  the four surfaces (baseline + `RESIST_VARIANTS`) built from config, asserts
  (all classes mapped; no `NA` in the footprint; no value outside it; 1 ≤ value
  ≤ 100), `FLT4S` writes with read-back, and `tbl_11_resistance_qa.csv`. The
  STEPs refuse to run if STEP 9.2 is triggered on the stack. **Implementation
  note:** Decision 14 does not state a cell-membership rule for the Sundarban
  water region; the code uses the Decision-11 rule (every cell the region
  touches), because the ring is the Decision-11 buffer.
- **First resistance build (2026-09-26): all asserts PASS**, four surfaces
  written and read-back verified. 11 classes mapped; Sundarban override 546
  water cells; barrier-road cells 535,592 (17.5 %); k = 4 capped 80,424 cells.
  QA (baseline / noghm / road15 / road50): mean 23.10 / 12.97 / 22.22 / 26.09;
  at or above the road value 41.4 % / 20.3 % / 65.1 % / 20.3 %; road cells
  raised 255,500 / 510,408 / 164,338 / 510,408 (`noghm` and `road50` raise the
  same cells: every road cell whose class value is 10 or less). Baseline class
  means: tree 5.91 (road cells in forest pull it up), shrub 9.58, grass 9.16,
  crop 30.31, built-up 100, bare 14.74, snow 100, **water 87.37**, wetland
  5.76, mangrove 2.48, moss 51.39.
- **Decision 16** made from that QA: water exempt from the gHM multiplier.
  The Decision-11 note that the water fill sets no resistance value is
  corrected in place. STEPs 9.5–9.8 re-run pending.
- **Rebuild with Decision 16: all asserts PASS** (see the Decision-16
  outcome). Four surfaces and `tbl_11_resistance_qa.csv` written; the
  first-build QA kept as `tbl_11_resistance_qa_pred16.csv`.
- **Week 9 complete (tasks 9.1–9.9).** Numbered Decisions added this week:
  11 (gap-fill rule), 12 (post-fill: gHM closed; land cover from the tile
  cache), 13 (terrain from the raw DEM; 7 tile-corner cells accepted), 14
  (resistance values, gHM multiplier, Sundarban water, `noghm`), 15 (road
  barrier, `road15`/`road50`), 16 (water exempt from gHM). Defect found and
  fixed: the stack file was `INT1U` on disk (now `FLT4S`, verified on
  read-back). Raised for Week 10: least-cost-path set-up and the variant
  comparison metric.

### 2026-09-26 — Documentation fix pass (before Week 9)

A consistency check of the docs and scripts found stale or false statements. No
analytical rule changed. Historical change-log entries below are left as
written; this entry records the corrections to them.

- **§5.2 Growth** described five rounds (2006–2022). Corrected to the Decision-6
  series (2014/2018/2022, 3 frames).
- **Decision 10 / `tbl_10`.** Decision 10 said `tbl_10` records the per-band
  before-mask counts. The Week-8 `tbl_10` held after-mask counts only; the
  before-mask counts existed only in the console output, and the Decision
  carried an unfilled figure (`~3,067,58x`). Fix: `scripts/06` STEP 8.6 now
  writes `n_valid_before` and `n_dropped_by_mask`, with two new hard stops
  (after-mask counts equal across bands; no negative drop), and prints the
  India-grid denominator and the binding layer. **`scripts/06` was re-run on
  2026-09-26.** The stack did not change: 3,010,738 complete-case cells, and
  every Week-8 spot-check value is identical (gHM 0.377/0.377; elev
  577.333/570.773; slope 2.540/2.504; tri 23.419/23.101; dist_road
  2018.946/2044.985; landcover modal 40, n_class 11).
- **Coverage figures made exact.** From the re-run `tbl_10`: India grid =
  3,067,565 cells; valid before the mask — landcover 3,067,578, gHM 3,012,007,
  elev/slope/tri 3,067,585, dist_road_m 3,067,565. The India-footprint loss is
  **56,827 cells (1.85%)**, not "~56,840 (~1.8%)". The old figure was the
  landcover-band drop, which counts 13 cells outside the India polygon.
- **Edge halo (data note, not a bug).** landcover (+13) and elev/slope/tri (+20)
  have valid cells just outside the India polygon after the resample onto the
  snapped template. dist_road_m is masked to India exactly, so the common mask
  removes them. Recorded in `scripts/06` STEP 8.6 and `data-dictionary.md`.
- **Distance-to-road maximum.** The Week-8 entry gives "max ~278.9 km" for the
  task-8.4 covariate. That is the stack band (after the common mask). The interim
  layer `cov_distroad_1km_7755.tif` (not common-masked) has max 279,693 m
  (~279.7 km) and mean 2,045 m.
- **`scripts/06` comments** corrected: the METHOD NOTES said WorldCover goes
  through `read_rast(..., categorical = TRUE)` (the script uses
  `terra::resample(method = "near")` on purpose); STEP 8.5 said the common mask
  trims only cells "where bilinear vs nearest disagree by a cell" (the cause is
  the gHM windowed-COG footprint, per Decision 10).
- **Table-number rule** made explicit (`naming-conventions.md` §6): a table
  number groups related tables, and the slug is the unique key. This matches the
  existing repeats (`tbl_00` ×2, `tbl_02` ×2, `tbl_04` ×3); no table is renamed.
- **Script plan.** Stage 2 (Weeks 9–12) is one script, `scripts/07_connectivity.R`
  (replaces the planned `07_build_resistance.R`). The header-only stubs
  `scripts/08_habitat_suitability.R` and `scripts/09_build_site.R` are deleted;
  later stages take the next free number when they start.
- **`scripts/00c_verify_wdpa_boundaries.R`** was missing from `scripts/` (deleted
  by accident). It was recovered and is back in place; Decision 4 cites it
  correctly.
- **Change log heading** restored for the Week-5 task-5.1 entry (the paragraph
  had no heading).
- Other docs: `data-sources.md` (2018 Table 3.4 page range; missing
  administrative-boundaries heading), `data-dictionary.md` (`tbl_10` writer, new
  columns, exact coverage), `project-plan.md` (script numbers; task 8.3 text),
  `README.md` (status figures).

### 2026-09-20 — Week 8: covariate stack assembled (Stage 2 input; Decision 10)

`scripts/06_build_covariate_stack.R` built the aligned covariate stack — the
first Stage-2 (Connectivity) deliverable. Assembly and alignment only; no
resistance values and no barrier road-class choice (both Week 9).

**Template (task 8.2).** One 1 km EPSG:7755 template, built from the national
boundary buffered by a 5 km collar (`COLLAR_M`), with the extent **snapped out to
whole multiples of `GRID_CELL_M`** so the grid is reproducible from the boundary
alone (independent of whatever bbox origin `scripts/01` used). 3093 × 2864 =
8,858,352 cells. Every covariate resamples onto this one template; extent / res /
CRS asserted once.

**Alignment (task 8.3).** The three Week-2 covariate layers (which live in
`data/interim/`, not `data/processed/`) are resampled onto the template —
WorldCover **nearest** (categorical), gHM and terrain **bilinear** (continuous).
`read_rast()` is deliberately **not** used here: it reprojects to an auto grid,
but the inputs are already EPSG:7755, so a straight `resample` onto the template
is one interpolation each (avoids double-interpolating, and stepping the class
layer twice). `compareGeom` re-asserted against the template after each.

**Distance-to-road (task 8.4).** `cov_distroad_1km_7755.tif` derived by
**rasterize-then-distance** (rasterise the 885,669 major-road lines onto the
template with `touches = TRUE`, then `terra::distance`) — far cheaper than
cell-to-line over 886k lines × 8.86M cells, identical at 1 km. **Inline road-class
choice (covariate only, not a Decision):** all five major classes + `_link` ramps
(the layer is already major-only from `scripts/01`); tertiary is **kept** on
purpose — whether tertiary is a movement *barrier* is the separate Week-9 road
Decision. Result: min 0 m, max ~278.9 km, mean ~2.0 km inside India.

**Stack + NA policy (task 8.5 + Decision 10).** Six bands assembled in the fixed
order `landcover, ghm, elev, slope, tri, dist_road_m` and written to
`data/processed/cov_stack_1km_7755.tif`. Cross-band **common NA mask** (Decision
10): any band `NA` → all bands `NA`, giving a complete-case predictor. gHM is the
binding NA layer; the mask drops ~56,840 cells (~1.8%). A gHM coastal/edge
gap-fill is **deferred to Week 9** pending a per-reserve relevance check.

**QA (task 8.6).** `tbl_10_covariate_stack_qa.csv`: all six bands **3,010,738
cells, 98.15% of India, `range_ok` TRUE**. Stacked-vs-source spot-check confirms
alignment did not corrupt values — gHM 0.377/0.377, landcover modal 40 (cropland)
n_class 11 both, elev 577.3/570.8, slope 2.54/2.50, tri 23.4/23.1, dist_road
2018.9/2044.9 (the small gaps are the ~1.8% common-mask trim, source means being
over the larger pre-mask footprint).

**Data notes (not bugs).** gHM's smaller footprint is a windowed-COG-read edge
effect, documented in Decision 10. The `write_processed_rast` console message
lacks a trailing newline, so it visually abuts the next line — cosmetic, in the
shared `R/00_functions_io.R`; left untouched.

### 2026-09-20 — Week 7 complete: regional roll-up + growth figures (Stage 1 done)

`scripts/05_growth_analysis.R` turned the Week-6 per-reserve metrics into the
Stage-1 deliverables. It reads `stats_reserve_census_7755.gpkg` only and writes
nothing back to it. No new numbered Decision was needed; the one analytical choice
(the regional roll-up rule) is recorded here and inline in the script, kept
un-numbered because it is uncontested — promote it to a Decision only if that
changes.

**Regional roll-up rule (inline analytical choice, task 7.2).** Rolled the
per-reserve layer up to two units — landscape complex and state — into one long
`tbl_02_regional_rollup.csv` (`unit_level` column; 23 rows = 5 landscape + 18
state). Rule:
- **Absolute fields** (`pop_2014/2018/2022`, `change_abs`) are summed over
  **non-`NA` reserves only**, each with its own **coverage count**
  (`n_pop_<year>`, `n_change_abs`), because coverage differs by field. A region
  with no non-`NA` contributor for a field gets `NA`, not 0.
- **Ratio fields** (`change_pct`, `aagr`) are **recomputed on the summed pops**,
  never averaged from per-reserve percentages (which would over-weight small
  reserves — a 0→1 reserve is not equal weight to a 200→260 reserve). Numerator
  and denominator use the **same contributor set**: reserves with a valid
  two-round span that are not `growth_zero_flag`.
- **Regional AAGR** needs one span (reserve spans mix 8 yr from a 2014 baseline
  and 4 yr from 2018), so it is annualised over a **`pop_baseline`-weighted mean
  span** (`span_region`). `change_pct` is the primary regional ratio; `aagr` is
  secondary and carries the mixed-span caveat.
- Added **`n_measured`** per region (`census_status == "measured"`): reserves that
  have census data at all, distinct from per-round coverage.

**Reconciliation (task 7.6, verified).** The landscape total, the state total,
and the per-reserve `na.rm` sum agree for every pop round and for `change_abs`:
pop_2014 = 1586, pop_2018 = 1958, pop_2022 = 2257, change_abs = +651;
n_measured = 53. Landscape picture: Central India +282 (+59.7%), Shivalik-Gangetic
+239 (+58.9%), Western Ghats +108 (+19.8%), North-East Hills +22 (+13.2%),
Sundarbans `NA`.

**Figures — how the `NA`/zero/absent cases are shown (Decisions 7/9 in the
visuals).**
- **fig_01** (ranking): reserves ranked by `change_pct` (default), faceted by
  landscape, filled by growth sign. Reserves with a `NA` ratio are excluded from
  the bars **and** counted per facet ("N not ranked") — shown separately, not
  dropped silently. The `growth_zero_flag` reserve (Mukundara) has a `NA` ratio,
  so it is not on the bars and cannot read as a decline (its `change_abs` is +1).
- **fig_02** (choropleth, 3 frames 2014/2018/2022 — Decision 6): per-round tiger
  count, fixed bins so a colour means the same count in every frame. `NA` pop →
  grey **"No estimate"** (never 0); a real within-reserve 0 → near-white
  **"0 (real)"** on the ramp (Decision 9); the 3 geometry-absent reserves
  (Amrabad, Pilibhit, Dholpur-Karauli) are named off-map and never drawn.
  `transition_manual` holds each round as a discrete frame so the polygons are
  fixed (an earlier `transition_states` build tweened the geometry — wrong for a
  fixed-geometry map).

**Tooling.** Added `gifski` to `renv` (the `fig_02` GIF renderer; `gganimate` was
already present). No change to any data layer.

### 2026-09-13 — Week 5 complete: census joined, area overwritten, density built

`scripts/03_prepare_census.R` finished (tasks 5.2–5.9). As built:
- **Pivot (5.2):** long → wide, 53 reserves, row presence 45/50/53 by round.
  Sundarbans 2022 kept `NA`-within (blank within-figure); Mukundara 2014 = 0
  kept as a real zero.
- **Join (5.3):** left join onto `boundary_reserves_all_7755.gpkg` — all 58
  reserves survive (53 measured + 5 flagged); the 3 geometry-absent reserves
  keep their census rows.
- **Area overwrite (5.4, Decision 8):** `area_km2` ← notified core+buffer total
  from `tbl_05_area_source_map.csv`, `area_provisional` → `FALSE`, `area_source`
  → `ntca_notification`, for all 58. **Value change was zero** — the Week-3
  placeholder already equalled the notified totals to the cent, so the overwrite
  was provenance-only. `poly_census_ratio` recomputed against the notified area.
- **Density (5.5):** `density_2022 = pop_2022 / area_km2 × 100` — 52 values;
  `NA` for the 5 flagged + Sundarbans; `0` for real within-reserve zeros. Note:
  per **total notified area**, not core-only, so it will not match a core-based
  NTCA density figure.
- **baseline_year (5.6):** earliest non-`NA` round — 45 at 2014, 5 at 2018,
  3 at 2022; `NA` for the 5 flagged.
- **Layer written (5.7):** `stats_reserve_census_7755.gpkg`, 58 reserves, 20
  attribute columns + geometry. Re-read confirmed. QA tables tbl_06–tbl_09.
- **Crosswalk review rows (5.8):** all 6 (Kamlang, Pench-MP, Pench-MH, Bor,
  Similipal, Nagarhole) verified on the correct `unit_id` + state.
- **Config reconciled (5.9):** added `CENSUS_SERIES_YEARS` (2014/2018/2022) and
  `CENSUS_BASELINE_YEAR` (2014) to `R/00_config.R`; `CENSUS_YEARS` now aliases
  the series. `BASELINE_YEAR`/`CURRENT_YEAR` kept at 2006/2022 and re-commented:
  they are the **GBIF occurrence-download bounds** (`scripts/01` YR_MIN/YR_MAX),
  not the census baseline — narrowing them would silently change the GBIF pull.
- **`change_abs/change_pct/aagr` are NOT yet computed** — Week 6.

### 2026-09-13 — Week 5 task 5.1: reserve area source (Decision 8)

Located the reserve core+buffer area for `area_km2` (task 5.1) and wrote
**Decision 8** (A1-revised). Key findings:
- **Neither census report tabulates area** (2018 Table 3.4 / 2022 Table I.3.3 are
  population-only; verified by reading, incl. a 2022 page raster).
- **ISFR 2021 Ch.4 does not carry the notified area either** — its per-reserve
  column (Table 4.5) is the **WII digitized-boundary** GIS area (52 reserves,
  total 74,710.53 km2), a different quantity from the legal notified total. It is
  therefore used as a **cross-check only**, not the area source (corrects the
  earlier A1 assumption that ISFR would supply the notified area).
- **Area source is the NTCA/state notification** (consolidated), all 58 reserves;
  notified-total sum 84,507 vs NTCA stated 84,487 (0.02%).
- Outputs: `outputs/tables/tbl_05_area_source_map.csv` (per-reserve area + source +
  ISFR cross-check + confidence), `outputs/tables/tbl_05b_isfr_area_crosscheck.csv`
  (52-reserve ISFR-vs-notified comparison; median |diff| 5.2%, 15 reserves >15%).

### 2026-09-12 — 2006/2010 secondary table + reference sweep

Built a **secondary** 2006/2010 reserve table and checked whether any reference
can supply comparable reserve-level counts (per user request; usable if needed).

- **`data/raw/ntca/census_reserve_long_2006_2010.csv`** — 24 reserve-anchored
  figures (11 for 2006, 13 for 2010) from the NTCA reports' prose, each tagged
  `spatial_unit` (reserve_and_surrounds / block_or_complex / landscape /
  reserve_prose) and `attribution_confidence` (5 high, 11 medium, 8 low). Kept
  as **context only** — NOT spliced into the within-reserve SECR series
  (Decision 6). The 5 high-confidence rows are 2010 Kanha 60, Bandhavgarh 59,
  Satpura 43, Pench-MP 54, Ranthambhore 31.
- **Singh & Sen (2015) supplies no values.** Its reserve bars (Figs 9–16) are
  normalised indices captioned "Source: NTCA"; only its landscape/national
  totals are numeric, and those are already in the reports. Confirms Decision 7.
- **No other reference gives a comparable reserve-level count set.** The 2011
  Jhala method paper is source-population scale; Gopal et al. (2010, Oryx) gives
  Panna 2006 *occupancy* (not a count); Harihar et al. (2017) documents that
  2006/2010 are methodologically non-comparable to 2014+ — reinforcing
  Decision 6. Full write-up:
  `docs/tbl_04_secondary_sources_2006_2010.md`. Three references added to
  `docs/references.md`.

### 2026-09-12 — Week 4 prose sweep for table-missing reserves

Second-pass check: do reserves absent from a round's master table have a figure
in that report's prose? (Same pattern as 2006/2010.)

- **2014:** Orang (then a National Park) has a tiger chapter — 15 unique
  captured, density 10.55(2.82)/100 km²; recorded as a **supplementary** row,
  not within-reserve abundance. Mukundara "does not have tigers" in 2014 —
  recorded as a real within-reserve **0** (0→1→1 trajectory). Kawal/Rajaji
  surveyed but no tiger abundance figure. Others post-date 2014.
- **2018:** no new reserve-level figures (missing reserves are post-2018 or
  NP/WLS mentions only).
- **2022:** Ratapani (then a WLS) has 56 individuals / density 2.30(0.31) for
  the Bhopal-Ratapani complex — recorded as a **supplementary** row, not the
  reserve. Corrected Ranipur 2022 note (camera-capture count, not scat).
- **Handling:** supplementary prose figures use
  `census_status = measured_prose_supplementary` and a non-within `spatial_unit`
  so they are preserved but excluded from the within-reserve growth series
  (Decision 6). Net series change: +1 row (Mukundara 2014 = 0).

### 2026-09-12 — Week 4 census extraction + spot-check (tasks 4.4–4.6)

- **Full census time series extracted**, not the planned half. All three SECR
  tables keyed into `data/raw/ntca/census_reserve_long.csv` (long format,
  Decision 6 series 2014/2018/2022): 44 rows (2014, Table 2.2), 50 (2018,
  Table 3.4, within column), 53 (2022, Table I.3.3, within column) = 147
  measured rows across 53 reserves, plus 5 never-estimated flag rows (Decision
  7). All 58 reserves accounted for. 2022 values transcribed from a page raster
  (its PDF text layer is corrupt).
- **Two Pench reserves** disambiguated by state (unit_id 23 MP, 33 MH).
- **Spot-check passed** (`outputs/tables/tbl_04_spotcheck_log.md`): 2022 within
  values match the PIB government release 17/17 exactly; the 2014 column sums to
  the report's own Table 2.2 total (1586) exactly. The 2018 within sum (1958) is
  +35 vs the report's de-double-counted 1923 — expected, since a per-reserve sum
  keeps shared-tiger reserves' own figures; logged, not corrected.
- **Carried flags:** 2018/2022 SEs are printed to implausible precision
  (transcribed verbatim); Sundarban 2022 within is blank (biosphere-level only);
  17 scat-DNA minimums have no SE. All flagged in the table `notes` column.
- **Not yet joined to boundaries** — that is Week 5 (the pivot to wide
  `stats_reserve_census_7755.gpkg`).

### 2026-09-12 — Week 4 missing-year Decision (task 4.2)

- **Decision 7 written:** missing (reserve, round) figures are stored `NA` — no
  carry-forward, interpolation, or gap-fill. Grounded in the observed gap
  structure: the three-round series is left-censored (reserves enter when first
  estimated) with **no true internal gaps**, so interpolation has nothing to
  bridge and carry-forward would fabricate stability. Closes the [Week 4]
  pending item.
- **Schema note:** `stats_reserve_census_7755.gpkg` gains a `census_status`
  flag so never-estimated reserves (post-2022 notifications) read as "mapped,
  not measured" rather than silently missing.

### 2026-09-12 — Week 4 census source location (task 4.1)

Located the reserve-level population figures in all five NTCA rounds before
extraction. Findings drove **Decision 6** and corrected a Limitations line.

- **Per-reserve SECR tables exist only for 2014, 2018, 2022.** 2014 Table 2.2
  (pp. 22–23), 2018 Table 3.4 (pp. 42–43), 2022 Table I.3.3 (pp. 28–29). 2018
  and 2022 split "within reserve" vs "utilising"; the **within** column is the
  comparable figure. 2014 has a single `Tiger Population` column.
- **2006 and 2010 have no per-reserve table.** Their finest tabulated unit is
  state × landscape complex (Table ES.1). Reserve-anchored numbers appear only
  in landscape-chapter prose, cover a subset (~18 in 2006, ~26 in 2010), are
  double-sampling estimates over the reserve **and surrounding occupied forest**,
  and are not like-for-like with the SECR series. (Corrects the earlier
  assumption that "NTCA figures are SECR estimates" for all rounds.)
- **2022 table text layer is corrupt.** `pdftotext` returns column-scrambled
  output for Table I.3.3; values are transcribed from a 150-DPI page raster.
- **New output:** `outputs/tables/tbl_04_census_source_map.csv` — per-round
  locators (page, table, figure type, spatial unit, method) plus a per-reserve
  availability matrix across all five rounds. No population values are extracted
  yet; that is the next task.

### 2026-09-11 — Week 3 reserve boundary build (`scripts/02`)

As-built findings while building `boundary_reserves_all_7755.gpkg`. These
refine, but do not change, Decision 4.

- **The KML holds protected areas, not tiger reserves.** The NTCA DSS KML
  contains 705 national-park / sanctuary polygons (plus 59 corridor polygons and
  156 unnamed duplicates), not 58 tiger-reserve entities. A tiger reserve is
  therefore built from its **constituent PA(s)** (for example Corbett = Corbett
  NP + Sonanadi WLS; Kali = Anshi NP + Dandeli WLS), not by a single name match.
  The earlier "55/58 name match, 3 unmatched + 2 false matches" framing is
  superseded by a **reserve→constituent-PA crosswalk**
  (`data/raw/ntca/reserve_pa_crosswalk.csv`, reviewed by hand). 10 reserves are
  multi-part and are dissolved to one polygon per `unit_id`.
- **Match key is name + state, not name.** PA names are not unique across the
  KML (two "Pench" — MP and MH; two "Rajiv Gandhi" — Karnataka and AP). The
  match uses standardised name **and** state together.
- **Alternate spellings resolved 5 apparent gaps.** Five reserves that a plain
  name match missed are present under other KML names: Pakke→`Pakhui`,
  Nagarhole→`Rajiv Gandhi`, Sahyadri→`Chandoli`+`Koyna`, Mukundara→`Darrah`,
  Anamalai→`Indira Gandhi`. The true gaps are **3**: Amrabad, Pilibhit,
  Dholpur-Karauli (each a 2014+ reserve, absent from the July-2022 KML). This
  matches the Decision-4 expectation of 3 unmatched reserves. The 3 are written
  as geometry-absent rows (`geometry_present = FALSE`) so the census still
  joins.
- **KML read method — xml2, not the GDAL KML driver.** On the build machine the
  GDAL KML driver (a) discards the `SchemaData`/`SimpleData` fields (`DESIG`,
  `state_name`, `Corridor`) that the whole match depends on, and (b) splits the
  file into two layers (`PA_TR_Corridors` = 764, `corridor` = 156). `scripts/02`
  therefore parses the KML with `xml2` and rebuilds geometry directly from ring
  coordinates (outer + inner holes, multi-part where present). New package
  dependency: `xml2`.
- **Corridors dropped in Week 3.** The 59 corridor polygons are set aside; the
  connectivity track (Stage 2) re-extracts them. Note for Stage 2: the corridors
  are **polygons, not centrelines, and are named** via the `Corridor` field
  (some names are blank). This differs from the earlier "unnamed centrelines"
  description.
- **156 unnamed duplicates preserved, not used.** They are spatial duplicates of
  named PAs. Written to `data/interim/boundary_kml_unattributed_7755.gpkg` for
  inspection; excluded from the reserve build.
- **`area_km2` is a flagged placeholder in Week 3.** The NTCA census area table
  does not exist until Weeks 4–5, so `area_km2` holds a published total-area
  figure (`area_source = wikipedia_ntca_2022_PLACEHOLDER`) with
  `area_provisional = TRUE`. Decision 4 is unchanged: the census overwrites this
  field in Week 5, at which point `area_provisional` becomes `FALSE`.
- **QA columns added.** The reserve layer carries `poly_km2` (KML polygon area)
  and `poly_census_ratio` (poly ÷ census) so the Decision-4 area gap is visible
  per reserve. As built, the ratio median is near 0.58 (polygons under-state the
  legal total, as expected). One outlier is recorded in Limitations below.
