# Methodology

**Project:** India's Tiger Network
**Author:** Kiran Balasubramanian
**Status:** **Week 15 complete (2026-11-01; tasks 15.1–15.2 on 2026-10-31,
tasks 15.3–15.6 on 2026-11-01; the commit, task 15.7, by the author);
Week 14 complete (2026-10-25).** Stage 3 (habitat
suitability) has a fitted model. **Decision 23:** a `maxnet` model on the
obscured iNaturalist tiger records at the 0.2° grain of the iNaturalist
obscuring grid, with a background of the clean iNaturalist Mammalia
records; the count gave `planned_model` (104 presence cells, 1,486
background cells, 6,969 model cells). **Decision 24:** the model settings,
fixed before any covariate summary. As run (`scripts/09_model_suitability.R`):
6 of the 9 candidate covariates kept (the terrain as `elev_mean` only);
`lq` with multiplier 1 by AICc; over 5 folds of 2° spatial blocks, a mean
test Boyce index of 0.668, a mean test AUC of 0.749 and a mean OR10 of
0.165; both sensitivity runs "robust"; QA 133 of 133. **Week 15, task 15.1
(2026-10-31): Decision 25** — the prediction and its published form, fixed
before any prediction file: the model file of 2026-10-25, cloglog with
clamping; cells outside the training range flagged and hatched; five
equal-count classes by rank; no layer before Week 18; two static figures
(`fig_04` classes, `fig_05` value); a reserve table; the cells of the
reserve check; point 9 (added in task 15.2) prevents a link of a reserve
name to a presence state. **Task 15.2 (2026-10-31):** the process choices.
**Task 15.3 (2026-11-01):** the prediction of the 6,969 model cells (under
`data/processed/`, gitignored); the gate of Decision 24 point 8 is open
(mean test Boyce 0.668); classes of 1,394 and 1,393 cells; 32 cells outside
the training range. **Task 15.4 (2026-11-01):** the reserve check — r1
"agrees" (ρ = 0.379, n = 51, p = 0.00614); r2 not published (Decision 25
point 9); z1 0; `tbl_17_reserve_suitability.csv` (58 rows). **Task 15.5
(2026-11-01):** the QA of Decision 25, 84 of 84. **Task 15.6:** the docs
of Week 15 and the Week-16 plan. No map yet. Week 15 is committed (`7ae300a`). **Week 16, task 16.1 (2026-11-07):
Decision 26** — the Gi* settings, fixed before any Gi*: four Gi* (the
iNaturalist effort with the obscured tiger set; the effort of all datasets
with the tiger 5 km set), 0/1 values on the model cells, a 50 km band, an
exact p and a false discovery rate; `fig_06` for the iNaturalist effort
Gi*; the tiger Gi* never published. **Task 16.2 (2026-11-07):** the process choices, and Amendment 1 of
Decision 26 (the distance between cells on the sphere). **Task 16.3
(2026-11-07):** STEP 16.1, the four Gi*: at 50 km, `effort_inat` 654 hot
cells and `effort_all` 559, no cold cell; `tiger_obscured` 200 hot cells
(85 also hot in `effort_inat`); `tiger_5km` 52 (20). **Next:** task 16.4
(the figures `fig_04`, `fig_05` and `fig_06`).
Earlier stages: **Stage 1 (Growth) complete in Week 7; Stage 2
(Connectivity) complete in Week 12** — least-cost paths (Decisions 17–18),
the reserve network (Decision 19) and road pinch points (Decision 20; they
are sensitive to the gHM multiplier). **Week 13:** occurrence cleaning
(Decision 21; no 1 km model) and effort surfaces (Decision 22; the tiger
surface is never published).
*(2026-10-25: the change-log entries of Weeks 3–13 are now in
`docs/methodology-changelog-archive.md`, word for word; the results of
the closed stages stay in the change log here.)*

This document is the processing log and the decision record. Every significant
choice becomes a **numbered Decision** with a date and a justification, recorded
**before** results are examined. This pre-registration discipline is carried
from the earlier projects.

---

## 5. Methods overview

### 5.1 Coordinate reference system

All analysis uses **EPSG:7755 (WGS 84 / India NSF LCC)**, a national frame
suited to a country-wide extent. Raw data is ingested in EPSG:4326 and
reprojected on load. This differs from tiger Phase 1, which used UTM 43N
(EPSG:32643) — correct for Central India but distorting at national scale.

### 5.2 Growth (priority 1)

Per-reserve census metrics on the within-reserve SECR series **2014 / 2018 /
2022** (Decision 6): absolute change, percent growth, average annual growth rate
(AAGR), and density (tigers/100 km²). Each reserve uses its own baseline → 2022
span; missing (reserve, round) cells are `NA` (Decision 7); real zeros follow
Decision 9. The 2006 and 2010 rounds have no per-reserve table and are context
only. Roll-up to landscape complex and state. Animated choropleth across the
three census rounds (3 frames).

### 5.3 Connectivity (priority 2)

Resistance surfaces from land cover (ESA WorldCover), a human-pressure (gHM)
multiplier and major roads as barriers (Decisions 14–16), with three
sensitivity variants. Least-cost paths between neighbouring reserve pairs,
edge to edge, on our own 16-neighbour cell graph (`terra` + `igraph`,
`R/00_functions_lcp.R`). Decision 17 fixes the pair rule, the path method and
the engine; Decision 18 fixes the variant comparison. No least-cost-path
package is in the pipeline; `gdistance` is for validation only. Reserve
network as a graph (`igraph`; rules in Decision 19 — no cost threshold,
contiguous reserves merged into one node): betweenness identifies linchpin
reserves, components identify isolated reserves. Road crossings of the paths
give pinch points (rules in Decision 20: a crossing is a run of barrier-road
cells on a path; crossings at most 5 km apart are one site; a pinch point is
a site on a bridge edge or a site that two or more edges use — not the
pinch point of circuit-theory mapping). The outputs for publication are
`tbl_03_reserve_network.csv`, `tbl_03b_pinch_points.csv` (with the note file
`tbl_03_notes.md`) and `fig_03_reserve_network.png`; a crossing or a pinch
point is given as a 10 km grid cell with its state and district.
All Stage-2 steps (Weeks 9–12: resistance, least-cost paths, network graph,
pinch points) are built in **one script, `scripts/07_connectivity.R`**, with one
STEP block per task.

### 5.4 Habitat suitability (priority 3)

*(Written again 2026-11-01 at the Week-15 close; the dated notes of
Decision 25 are in this text now. Earlier texts: 2026-10-25 (Week 14) and
the first text, which named a `maxnet` SDM at 1 km on the cleaned
occurrences.)*

`maxnet` SDM at a coarser grain (Decision 23). There is no 1 km model: the
tiger records with a position good to 1 km are 45 records in 17 cells,
below the minimum of 25 (Decision 21 point 8).

- **Grain:** the cells of the iNaturalist obscuring grid, 0.2° × 0.2°
  (396–488 km² in India). A cell is a model cell if complete-case 1 km
  cells cover 50 % or more of it: 6,969 model cells.
- **Presences:** the obscured iNaturalist tiger records (Decision 21 point
  4): 104 presence cells.
- **Background:** the clean iNaturalist Mammalia records on the same grid,
  a target-group background from the same platform (Decision 5): 1,486
  cells. The main model has no bias covariate (Decision 24).
- **Settings (Decision 24):** summaries of the 1 km covariate stack over
  each cell; a collinearity check; AICc selection of the feature classes
  and the regularisation; evaluation by 2° spatial blocks in 5 folds; a
  gate on the Boyce index; a reserve check against the 2022 census density;
  two sensitivity runs. As run: six covariates (the mean of gHM, elevation
  and distance to road; the shares of forest, open natural and built
  land), `lq` with multiplier 1, a mean test Boyce index of 0.668.
- **Prediction (Decision 25; Week 15):** the model file of 2026-10-25,
  cloglog with clamping, over the 6,969 model cells
  (`data/processed/sdm_prediction_cell02.csv`, gitignored). The gate is
  open. Five classes of equal count by rank (1,394 cells, and 1,393 in
  class 1); the value is relative, not a probability of presence. 32 cells
  are outside the training range of one or more covariates: they keep
  their value and are hatched in the figures. The statistics:
  `tbl_16_sdm_prediction.csv`.
- **Reserve check (Decision 24 point 9; Decision 25 points 7–9):** a
  reserve value is the mean over the complete-case 1 km cells whose centre
  is in the core polygon; a 1 km cell outside the model cells has no value.
  56 of 58 reserves have a value (`tbl_17_reserve_suitability.csv`, the
  published table). r1: Spearman ρ = 0.379 with the 2022 census density
  (n = 51, p = 0.006) → "agrees". r2 is not published (Decision 25 point
  9). QA of Week 15: 84 of 84.
- **Published form:** two static figures at national scale in Week 16
  (`fig_04` the classes, `fig_05` the value, with the nine caption items of
  Decision 25 point 5); the tables of statistics; the reserve table. No
  layer that a reader can zoom or download before the Week-18 rule
  (pending item "Published layers").

**This is suitability, not occupancy** (Decision 1). At a grain of about
20 km it is not habitat at the scale of a reserve.

### 5.5 Effort thread (cross-cutting)

*(Written again 2026-10-25 at the Week-14 close.)*

Target-group background (all Mammalia, tiger excluded — Decision 5) as the
effort proxy.

- **Density surfaces (Decision 22, Week 13):** effort (the clean Mammalia
  background), tiger records and city/town settlements, with a quartic
  kernel of 20 km radius. The tiger surface is not published.
- **In the model (Decisions 23 and 24):** the target-group background of
  the model is the main bias correction; the city/town surface is a bias
  covariate in one sensitivity run only.
- **Getis-Ord Gi\* (Decision 23 point 8):** one Gi* of the effort and one
  of the tiger records in the Phase-1 form, for a comparison with the
  Phase-1 Ranthambore cold spot. The tiger Gi* is never published. A
  numbered Decision fixes the settings before any Gi* is computed (Week 16
  in the plan draft of 2026-10-25).
  *(2026-11-07, Decision 26: four Gi\* on the 0.2° model cells, each tiger
  set against the effort Gi\* of its observer group; no comparison with
  Phase 1. The tiger Gi\* cannot show a cold spot (Decision 26 point 6).)*
- No ratio of the tiger and the effort surfaces.

---

## Decision log

### Decision 1 — "Occupancy" reframed as habitat suitability (SDM)
**Date:** 2026-09-06
**Choice:** Model habitat suitability with `maxnet`, not occupancy.
**Reason:** Occupancy needs a detection history (repeat visits to fixed sites).
Opportunistic GBIF tiger records cannot supply one; Phase 1 kept only ~116 clean
baseline points and showed strong observer bias. SDM is defensible with these
data; occupancy is not. Framing is fixed before any modelling so the claim is
not overstated later.

### Decision 2 — Analysis unit is the reserve, rolled up to region/state
**Date:** 2026-09-06
**Choice:** Reserve-level analysis; landscape complex and state as roll-up units.
**Reason:** Connectivity is inherently reserve-to-reserve, and growth data is
reserve-level. Country-level growth is already known (1,411 → 3,682); it is a
framing number, not the analysis. Regional roll-up carries the narrative.

### Decision 3 — Analysis CRS EPSG:7755 (national), not UTM 43N
**Date:** 2026-09-06
**Choice:** EPSG:7755 (India NSF LCC) for all analysis.
**Reason:** The study extent is national. A single UTM zone distorts across the
country. A national conformal/equal-area frame is appropriate for country-wide
distance and area work.

### Decision 4 — Reserve boundary source and area basis
**Date:** 2026-09-07
**Choice:** Use the NTCA Decision Support System `PA_TR_Corridor_Final` KML as
the single geometry source for reserve boundaries and corridors. Do not use it
for reserve area. Compute all area and density metrics from the official NTCA
census total area (core + buffer), not from the KML polygon geometry.

**Reason (what the Week-2 check found):**
Task 2.1 tested each candidate source against the 58 official tiger reserves.
The result removed two of the three options and showed a shared limit in the
rest.

1. **Authoritative WII/NTCA all-reserve boundary layer — not available.** The
   WII PAN portal needs a login or a purchase. Bhuvan shows protected-area
   vectors but does not let you download them. No open all-reserve TR vector was
   found.
2. **WDPA (Protected Planet) — no national data for India.** The India country
   profile states, for both the WDPA and the WD-OECM: "Number of national
   designations only = 0". The public WDPA India extract holds only
   international designations (Ramsar sites, World Heritage Sites, one Biosphere
   Reserve) — 63 polygons, no national parks, no sanctuaries, no tiger reserves.
   India has not shared its national protected-area geometry with the WDPA. WDPA
   cannot supply reserve boundaries.
3. **KBA and the NTCA KML — both hold the core protected area, not the legal
   tiger-reserve extent.** A name match against the 58 reserves found:
   - KBA: 51 of 58 reserves, median area deviation 47 % from the legal total.
   - NTCA KML: 55 of 58 reserves, plus the corridor geometry, median deviation
     55 % from the legal total.
   The deviations are almost all negative (for example Kaziranga -65 %, Manas
   -82 %, Buxa -95 %). Both sources store the core national park or sanctuary
   polygon, not the notified core-plus-buffer tiger-reserve extent. This is the
   opposite of the Phase-1 KBA problem (which was area *inflation* from a
   buffer-inclusive polygon); at national scale the sources under-state area
   because they carry the core protected area only.

**Why the NTCA KML, and why area comes from the census (Option C):**
- The KML is the authoritative NTCA source, has the best coverage (55 of 58),
  and is the only source that also carries tiger corridors — which the
  connectivity track (priority 2) needs. One source, one licence.
- No open source holds legal tiger-reserve extents, so the boundary geometry is
  used for mapping and connectivity only. Reserve area and density come from the
  official NTCA census figures (the 58-reserve core/buffer/total table). Density
  is census population divided by official total area — never divided by the KML
  polygon area. This removes the area error from every reported metric.
- This follows the sibling Phase-2 project, which already treated this KML as
  authoritative for approximate extents only and paired it with the NTCA/ISFR
  tabular data.

**Carried limitations (added to the Limitations section):**
- The KML is a July-2022 infrastructure-clearance dataset, not peer-reviewed
  research spatial data. It is authoritative for approximate extents only.
- KML geometry is the core protected area, not the legal tiger-reserve extent.
  All published reserve polygons must state this basis. Area and density never
  use the polygon geometry.
- Coverage is 55 of 58. Three reserves are not found by name (Amrabad,
  Pilibhit, Dholpur-Karauli) and two matches are false (Bor matched Great
  Himalayan NP; Kamlang matched Namdapha-Kamlang). These are resolved by hand
  during the Week-3 boundary build, not now.
  *(As built — see the Week-3 change log: the "false matches" were name-lookup
  artefacts. Bor and Kamlang both have correct in-state polygons and are matched.
  The true gaps are the three reserves above.)*
- Corridor centrelines in the source KML are largely unnamed; names are assigned
  during the connectivity track (as in Phase 2).
  *(As built: the corridors are named polygons — the `Corridor` field carries a
  name, some blank — not unnamed centrelines. See the Week-3 change log.)*

**Verification artefacts:** `scripts/00c_verify_wdpa_boundaries.R` (WDPA check),
`outputs/tables/tbl_00_kba_tr_match.csv` (KBA match), and the NTCA-KML match run.

### Decision 5 — Target-group background is Mammalia only, not all vertebrates
**Date:** 2026-09-07
**Choice:** Build the SDM target-group background from all Mammalia occurrences
(tiger excluded), 2006–2022, national extent. Do not use the all-vertebrate
background that the sibling Bay Area project used.
**Reason:** The target-group method assumes the background taxa share the focal
species' sampling bias (Phillips et al. 2009; Barber et al. 2022). In India that
holds for mammals but not for all vertebrates:
- Birds (Aves) are recorded by a very large, separate birdwatcher/eBird
  community whose spatial bias (wetlands, coasts, IBAs) differs from the
  mammal-observer bias that shapes tiger records. Including birds would model
  birder effort, not tiger-relevant effort, and would swamp the mammal signal.
- Fish and amphibians are recorded by aquatic surveys — a different footprint
  again.
Mammalia is the widely used target group for mammal/carnivore SDMs and matches
how tigers are recorded (sightings, camera traps, sign). The Bay Area project
used all vertebrates because it built an *occupancy* non-detection history (any
vertebrate record = "someone surveyed here"); this project uses a target-group
*SDM*, where the shared-bias criterion governs and mammals are correct.
**Open sub-choice (Week 13/14):** all Mammalia vs a narrower large-bodied guild
(carnivores + ungulates, the camera-trap/sighting group). Pulled all Mammalia
now; the narrowing is decided from observed volumes at model fit, not here.

### Decision 6 — Census figure type and growth-series baseline
**Date:** 2026-09-12
**Choice:** For the growth track, use the **within-reserve SECR** per-reserve
estimate from each round that publishes one — **2014, 2018, 2022**. Baseline the
all-reserve growth series at **2014**. Do **not** build an all-reserve
2006→2022 series from the census reports. Treat **2006 and 2010** as
**7-reserve Phase-1 context only**, extracted from landscape-chapter prose and
labelled as a different spatial unit, never mixed into the all-reserve series.

**Reason (what task 4.1 found when locating the per-reserve tables):**
The five rounds do not report reserve-level population the same way.

1. **2014 / 2018 / 2022 — per-reserve SECR tables.** Each has a single table of
   within-reserve estimates:
   - 2014 — Table 2.2 (pp. 22–23), 44 reserves, `Tiger Population` midpoint with
     `Lower SE Limit` / `Upper SE Limit`.
   - 2018 — Table 3.4 (pp. 42–43), 50 reserves, `Number` + `SE`, split into
     "tigers **within** the reserve" and "tigers **utilising** the reserve".
   - 2022 — Table I.3.3 (pp. 28–29), ~56 reserves, `value ± SE`, same
     within/utilising split. (Its PDF text layer is corrupt; values must be
     transcribed from a page raster.)
   The comparable figure is the **within-reserve** column (2014 has only the one
   column; 2018 and 2022 split, and the "utilising" column double-counts tigers
   shared between abutting reserves — the 2018 report states the within figure is
   the one to use).
2. **2006 / 2010 — no per-reserve table.** The finest tabulated unit is
   **state × landscape complex** (Table ES.1 in each). Reserve-anchored numbers
   exist only in **landscape-chapter prose** (e.g. 2006: Panna "89 (± 1 se range
   73–105)", Pench "33 (27–39)"; 2010: Kanha "60 (45–75)", Ranthambhore "30–32").
   These are: **partial** (~18 reserves in 2006, ~26 in 2010, not all 58);
   **double-sampling**, not SECR; and estimated over the **reserve + surrounding
   occupied forest** (the "source population"; occupancy area typically exceeds
   the reserve), not the within-reserve boundary. Naming blends reserve and
   landscape ("Panna landscape", "Kanha-Pench"), so mapping to `unit_id` is a
   hand judgement, not a string join.

**Why baseline at 2014, not 2006:**
- Splicing a 2006/2010 reserve-and-surrounds prose figure to a 2014+
  within-reserve SECR figure mixes two spatial units and two methods in one
  series. It would **understate** early density (larger denominator area) and
  **understate** growth, an artefact that looks like a real trend.
- Coverage is incomplete before 2014, so an all-reserve 2006/2010 column would be
  mostly missing anyway and would force imputation on the least comparable rounds.
- The country-level 2006→2022 trajectory (1,411 → 3,682) is already the framing
  number (Decision 2); the all-reserve *reserve-level* series is what 2014 onward
  supports cleanly.
- Phase 1 already reconstructed 2006/2010 for its **7 featured reserves** from
  exactly these chapters. Those stay available for the 7-reserve narrative, with
  an explicit note that they are reserve-and-surrounds, double-sampling figures.

**Consequences for the pipeline:**
- The growth metrics (absolute change, % growth, AAGR) are computed on the
  2014/2018/2022 series. `baseline_year` in `stats_reserve_census_7755.gpkg` is
  2014 for reserves present in the 2014 table, later where a reserve first
  appears (e.g. Amrabad, Mukundara, Rajaji-2018; several reserves 2022-only).
- Reserves notified after 2022 (Guru Ghasidas-Tamor Pingla, Veerangana
  Durgavati, Ratapani, Madhav, Dholpur-Karauli) have **no census figure in any
  round** and carry `NA` population with a flag; they map but do not enter growth
  stats.
- This resolves the **baseline** part of the [Week 4] missing-year question
  (series starts 2014; 2006/2010 are not an all-reserve baseline). The remaining
  part — reserves absent from a round within the series — is fixed in Decision 7.
- Locators for every round are recorded in
  `outputs/tables/tbl_04_census_source_map.csv` (task 4.1).

### Decision 7 — Missing-year census handling (leave `NA`, no imputation)
**Date:** 2026-09-12
**Choice:** Where a reserve has no census figure in a round, **store `NA`**. Do
**not** carry forward, interpolate, or gap-fill population values. Growth metrics
are computed only over the rounds a reserve actually has, and each reserve's
`baseline_year` is its **first round with a figure**. The Singh & Sen (2015)
gap-fill is **not** used in the all-reserve series.

**Reason (what the gap structure actually is):**
Across the three SECR rounds that form the series (Decision 6), the per-reserve
availability is not a scatter of random holes — it is almost entirely
**left-censoring** (a reserve enters the series when it is first notified /
first estimated) with **no true internal gaps**:

- **42 reserves** are present in all three rounds (2014, 2018, 2022).
- **~5 reserves** first appear in **2018** (Kamlang, Orang, Mukundara, Amrabad,
  Rajaji) — no 2014 figure because they were not yet estimated as reserves.
- **~5 reserves** first appear in **2022** (Navegaon-Nagzira, Ramgarh Vishdhari,
  Srivilliputhur-Meghamalai, Ranipur, Sundarban within-figure) — 2022 baseline.
- **5 reserves** (Guru Ghasidas-Tamor Pingla, Veerangana Durgavati, Ratapani,
  Madhav, Dholpur-Karauli) have **no figure in any round** (post-2022
  notifications) — they map but carry `NA` population and are excluded from
  growth stats.
- **No reserve** is present-then-absent-then-present within 2014–2022. The one
  apparent "2014+2018 but not 2022" case (Satpura) is a name-match artefact; its
  2022 figure exists. So there is no genuine interior hole to interpolate across.

**Why `NA`, not the alternatives — evaluated:**
- **Carry-forward** (repeat the previous round's value): fabricates stability.
  For a late-entry reserve there is no previous value to carry; for a real reserve
  it would invent an unchanged population and bias AAGR toward zero. Rejected.
- **Interpolate** (linear between bracketing rounds): needs an interior gap to
  interpolate across, and the data has none. It would only ever apply to
  left-censored reserves, where there is nothing on the left to interpolate from.
  Inapplicable by construction. Rejected.
- **Singh & Sen (2015) gap-fill:** it fills the **2006–2010** Bandipur/Nagarahole
  gap. Decision 6 already excludes 2006/2010 from the all-reserve series, so this
  fill has no target in the series. Kept only as optional context for the
  7-reserve Phase-1 panel, clearly labelled as a secondary source. Not entered as
  primary census data.
- **Leave `NA` (chosen):** honest about coverage, keeps every stored value a real
  published SECR figure, and matches the pre-registration discipline (no invented
  data before results are seen). Growth over a shorter observed span is still
  valid; a reserve with only a 2022 figure simply has no growth metric yet.

**Implementation consequences:**
- `pop_<year>` is `NA` for any (reserve, round) with no published figure.
- `baseline_year` = earliest round with a non-`NA` figure (2014 for the 42-reserve
  core; 2018 or 2022 for late entries).
- `change_abs`, `change_pct`, `aagr` use each reserve's own baseline→2022 span;
  reserves with a single round get `NA` growth metrics, not a fabricated 0.
- `density_2022` needs only the 2022 figure and the census area, so it is
  available for every reserve with a 2022 row regardless of history.
- The five never-estimated reserves are flagged (a `census_status` note) so they
  are visibly "mapped, not measured" rather than silently missing.

This closes the **[Week 4] Missing-year census handling** pending item.

### Decision 8 — Reserve area source (core+buffer notified total; A1-revised)
**Date:** 2026-09-13
**Choice:** Set each reserve's `area_km2` (the Decision-4 census/notified area) to
the **NTCA-notified core + buffer total**, for all 58 reserves, `area_source =
ntca_notification`. Assemble it from the NTCA / state tiger-reserve notifications
(consolidated in the Wikipedia "Tiger reserves of India" table, which cites the
NTCA notifications and FSI ISFR 2021). Use **FSI ISFR 2021 Ch.4 as a cross-check
only**, never as the area value. Do not use the KML polygon area (Decision 4).

**Reason (what task 5.1 found across three source classes):**
1. **The census reports carry no area table.** Read directly: 2018 Table 3.4
   (pp.42-43, clean text) and 2022 Table I.3.3 (pp.28-29, page raster) each have
   four columns only — State, Tiger Reserve, Within +-SE, Utilising +-SE. No
   area column; no area annexure. Area is only in scattered per-reserve prose.
2. **ISFR 2021 Ch.4 does NOT carry the notified area.** On reading the chapter
   (image-only PDF; read from page rasters), its per-reserve area column
   (Table 4.5) is "**Area as per digitized Tiger Reserve Boundary**", source
   **WII Dehradun** — a GIS polygon area, not the legal notified core+buffer
   total. Its 52-reserve total is **74,710.53 km2** (report's own figure;
   independently re-summed to 74,710.41 from the transcribed column), far below
   the all-India notified total of ~84,487 km2. This is the same *class* of
   quantity Decision 4 rejected for the KML. ISFR also covers only 52 of 58.
   -> ISFR cannot be the area source; it is demoted to a cross-check.
3. **No single downloadable NTCA file lists all-58 core/buffer/total.** NTCA
   publishes the national aggregate (84,487 total; 46,701 core; 38,244.74 buffer)
   plus per-reserve notifications. The consolidated per-reserve notified figures
   are the Wikipedia table (citing those notifications). Assembled here for all 58.

**Cross-checks (raise confidence):**
- Sum of the 58 notified totals = **84,507 km2** vs NTCA stated **84,487**
  (0.02% apart). Sum core = 46,693 vs 46,701. Essentially exact.
- **ISFR cross-check (52 reserves, `tbl_05b_isfr_area_crosscheck.csv`):** median
  |difference| between ISFR digitized area and the notified total is **5.2%** —
  close for most reserves, validating the notified figures. **15 reserves diverge
  >15%** (WII polygon vs legal extent genuinely differ): most extreme Bor -84%,
  Orang -84%, Ramgarh Vishdhari -80%, Srivilliputhur-Megamalai -51%, and
  Palamau +75%. Density uses the notified total, so these do not affect any metric;
  they are flagged in `tbl_05` `notes`.
- Two-Pench collision handled: unit_id 23 = Pench (MP) total 1179.63; unit_id 33 =
  Pench (MH) total 741.22 (MP figure independently confirmed by its notification:
  core 411.33, buffer 768.30).

**Consequences for the pipeline:**
- `outputs/tables/tbl_05_area_source_map.csv` holds per-reserve core/buffer/total,
  `area_source = ntca_notification`, the ISFR cross-check columns, and a
  confidence grade (high where ISFR agrees within 15%; medium where ISFR diverges
  >15% or the reserve is post-2021 with no ISFR row).
- `area_total_km2` overwrites `boundary_reserves` `area_km2` in Week-5 `scripts/03`
  (task 5.4); `area_provisional` -> FALSE; `area_source` copied from this table.
- `density_2022 = pop_2022 / area_total_km2 * 100` (task 5.5) uses the notified total.
- `total` is used as given, not recomputed from core+buffer. Two rows have a source
  core+buffer != total quirk (Madhav -120; Sahyadri +11.88) — flagged, harmless.

**Open verification (does NOT block Week 5):**
- The notified figures were consolidated via Wikipedia (citing NTCA/FSI), not read
  from 58 individual notification PDFs. They pass both national-total and ISFR
  cross-checks. If a reserve-level value is ever disputed, confirm against that
  reserve's NTCA/state notification; record the locator in `tbl_05` `source_ref`.
- ISFR provenance is now correct: ISFR is a cross-check column, not the area source.

### Decision 9 — Real within-reserve zeros in growth metrics
**Date:** 2026-09-19
**Choice:** A published `0` is a **real within-reserve figure**, not missing data
(Decision 7), and is carried into the growth metrics as follows.
- `change_abs = pop_2022 - pop_baseline` is **always computed** where the reserve
  has a real two-round span and both endpoints are present — a zero at either
  endpoint does not make it `NA`.
- **Zero baseline** (`pop_baseline == 0`, e.g. Mukundara Hills, `unit_id` 42, a
  0→1→1 trajectory): `change_pct` and `aagr` are **`NA`**, because both divide by
  the baseline and a 0→N change is undefined as a ratio. These reserves are marked
  `growth_zero_flag = TRUE` so the `NA` is visibly **ratio-undefined**, not
  missing data.
- **Zero endpoint in 2022** (`pop_2022 == 0`, `pop_baseline > 0`, a real decline
  to local extirpation — e.g. Kamlang, Dampa, Kawal, Satkosia): `pop_2022` is a
  valid numerator, so `change_pct = -100` and `aagr = -100`%/yr are **computed and
  reported as-is**. These are not flagged (`growth_zero_flag = FALSE`) — the value
  is real, not a special-cased `NA`.
- No metric ever stores `Inf` or `NaN`.

**Reason:**
1. **A subtraction is defined at zero; a ratio is not.** `change_abs` needs no
   guard — 0→1 is +1, 12→0 is −12. Only the ratio metrics (`change_pct`, `aagr`)
   have a zero **denominator** problem, and that occurs only when the **baseline**
   is 0. Guarding on the baseline, not on "any zero", keeps every defined value.
2. **A zero baseline is genuinely undefined as growth, not −∞ or 0.** Mukundara's
   0→1 is real recovery, but "percent growth from 0" and "annual growth rate from
   0" have no finite value. Reporting `NA` (flagged) is the honest statement;
   inventing a number (or `Inf`) would misrepresent it. `change_abs = +1` already
   carries the real information for this reserve.
3. **A real decline to 0 is defined and informative.** `pop_2022 = 0` after a
   positive baseline is a −100% total change and a −100%/yr annualised rate — a
   true statement about a reserve that lost its within-reserve tigers over the
   observed span. `NA`-ing it would hide a conservation-relevant result; the
   effort/interpretation caveats belong in the narrative, not in a suppressed
   cell. (This is the wider scope task 6.5 asks for — both endpoints — beyond the
   baseline-only framing of the original pending item.)
4. **The flag separates two kinds of `NA`.** After this Decision the growth
   columns carry `NA` for three distinct reasons: single-round reserves (no span),
   `pop_2022` missing (Sundarbans), and zero baseline (ratio-undefined). Only the
   third is a *modelling* `NA`; `growth_zero_flag` marks it so a reader (and the
   Week-7 visuals) never confuses "we cannot compute a rate from 0" with "no data".

**Implementation consequences:**
- `change_abs`: computed wherever a two-round span exists (task 6.2); `NA` only
  for single-round reserves and reserves with a missing endpoint (Sundarbans, the
  5 flagged).
- `change_pct = change_abs / pop_baseline * 100`: `NA` where `pop_baseline == 0`;
  otherwise computed (including −100 for a real 2022 zero).
- `aagr = (pop_2022 / pop_baseline)^(1 / (2022 - baseline_year)) - 1`, as a
  percent: `NA` where `pop_baseline == 0`; otherwise computed (including −100 for
  a real 2022 zero). Single-round reserves have a zero-length span → `NA`, never a
  divide-by-zero.
- New column `growth_zero_flag` (logical) on `stats_reserve_census_7755.gpkg` and
  in `tbl_01_reserve_growth.csv`: `TRUE` iff the reserve has a real two-round span
  and `pop_baseline == 0`. In the current data this is Mukundara Hills only.

This closes the **[Week 6] Zero-baseline handling** pending item.

### Decision 10 — Covariate-stack cross-band NA policy (common mask; gHM gap-fill deferred)
**Date:** 2026-09-20
**Status:** **Closed 2026-09-26.** The common mask stands on the rebuilt stack
(Decision-11 gHM fill; land cover and terrain fixed at source, Decisions 12 and
13). Final: 3,067,467 complete-case cells of 3,067,565 India-grid cells; 98
dropped (91 water cells beyond the gHM fill + 7 no-class cells at WorldCover
tile corners). See the `postfill_d13` outcome under Decision 13. Confirmed
on the correctly written (`FLT4S`) stack by the `postfill_d13f` re-check.
**Choice:** In the assembled covariate stack `cov_stack_1km_7755.tif`
(`scripts/06_build_covariate_stack.R`, task 8.5), apply a **common NA mask**: a
cell is kept only where **all six bands** (`landcover`, `ghm`, `elev`, `slope`,
`tri`, `dist_road_m`) are non-`NA`; if any band is `NA` in a cell, the whole cell
is set `NA` across every band. Do **not** gap-fill any band now. A gHM
coastal/edge gap-fill is **deferred to Week 9**, to be done only if a per-reserve
relevance check shows the trimmed cells matter for the connectivity / SDM extent.

**Reason (what the Week-8 QA showed):**
- The Week-9 resistance surface and the Week-13+ `maxnet` SDM consume the stack
  as a multi-band predictor and need **complete cases** — no band should present
  a partial covariate vector for a cell. The common mask guarantees that.
- The bands do not share an identical valid footprint. Valid cells before the
  mask (`tbl_10`, `n_valid_before`): landcover 3,067,578; elev / slope / tri
  3,067,585; dist_road_m 3,067,565 (= the India grid exactly); **gHM
  3,012,007** — it is the **binding NA layer**. *(Correction, 2026-09-26: this
  Decision first cited `tbl_10` for these counts, but the Week-8 `tbl_10` held
  after-mask counts only, and it carried an unfilled figure. `scripts/06` now
  writes `n_valid_before` and `n_dropped_by_mask` to `tbl_10`; the figures here
  are from the 2026-09-26 re-run.)* gHM was built by a
  windowed 300 m COG read reprojected by bilinear (`scripts/01` Block 5); its
  valid extent is slightly smaller than WorldCover/terrain along the coast/border
  and at small interior water/fill gaps.
- The common mask therefore trims every band to gHM's footprint: **complete-case
  cells = 3,010,738 (98.15% of the 3,067,565-cell India grid); 56,827 India-grid
  cells (1.85%) lost** (the `dist_road_m` row of `tbl_10`, whose footprint is the
  India grid exactly). **55,049** are cells where only gHM is `NA`; the other
  **1,778** are India cells with no land-cover class (an edge offset found on
  2026-09-26 — see Decision 12). *(Corrected 2026-09-26. The Week-8 text gave
  "~56,840 (~1.8%)"; that was the landcover-band drop, which counted 1,791
  cells outside the India polygon and none of the 1,778 India cells without a
  class. An earlier correction called the landcover excess a "+13 halo"; +13
  is only the net of those two figures.)*

**Why defer the gap-fill rather than fill or close now:**
- Filling gHM's `NA` fringe (a focal/nearest-fill of the edge) is a covariate
  *treatment* choice, not a stacking mechanic. Making it inside the Week-8
  assembly step would bury an analytical decision in a mechanical one.
- Whether the 1.85% loss matters is an **empirical question not yet checked**:
  the concern is specific reserves on the coast/edge (Sundarbans mangrove edge,
  coastal Western Ghats reserves) losing cells inside their footprint. Deciding
  "no fill, ever" before that check would be the same premature closure the
  pre-registration discipline avoids; deciding "always fill" would add an
  unvalidated covariate edit.
- **Week-9 action:** before the resistance surface is built, intersect the
  dropped-cell set with the reserve/corridor footprints. If material coverage is
  lost inside a reserve, apply a bounded gHM edge gap-fill and re-stack (a new
  numbered Decision recording the fill method and radius); if not, the common
  mask stands as final and this Decision closes with "no fill needed".

**Consequences for the pipeline:**
- `cov_stack_1km_7755.tif` is the complete-case stack (six bands, common mask).
- `tbl_10_covariate_stack_qa.csv` records, per band, the valid cells before the
  mask (`n_valid_before`), the cells the mask removed (`n_dropped_by_mask`), and
  the complete-case count after the mask (`n_valid`), so the coverage cost is a
  saved figure, not a console figure. *(The first two columns were added on
  2026-09-26; see the change log.)*
- The interim single-purpose layers (`cov_distroad_1km_7755.tif` and the Week-2
  `cov_*_1km_7755.tif`) are **not** common-masked, so a Week-9 gap-fill can start
  from gHM's own footprint without re-deriving the others.

### Decision 11 — gHM gap-fill relevance rule (resolves Decision 10)
**Date:** 2026-09-26 (fixed **before** the check was run)
**Choice:** Decision 10 deferred a gHM gap-fill until a relevance check. The
rule for that check, and the fill used if it triggers, are fixed here. The
parameters live in `R/00_config.R` (`GAP_*`); `scripts/07_connectivity.R`
STEP 9.2 applies them.

1. **Footprint units** (each checked on its own):
   - the 55 reserve polygons with KML geometry;
   - the 59 NTCA corridor polygons (`boundary_corridors_7755.gpkg`, written by
     `scripts/02` in task 9.2a);
   - a **10 km ring outside each reserve polygon** (`GAP_BUFFER_M = 10000`), the
     approach zone that a least-cost path must cross to leave a reserve.
   The 3 geometry-absent reserves (Amrabad, Pilibhit, Dholpur-Karauli) cannot
   be checked; they are listed, not counted.
2. **Cell membership:** any 1 km cell the polygon touches
   (`terra::extract(touches = TRUE)`). Only India-grid cells count.
3. **Cells counted:** land cells — WorldCover class ≠ 80 (permanent water,
   `GAP_WATER_CLASS`). Dropped water cells are reported but not counted. An
   India cell with no WorldCover class counts as land.
4. **Materiality:** a unit is materially affected if **≥ 5 %** of its land
   cells are dropped (`GAP_MIN_PCT`) **or ≥ 25** land cells are dropped
   (`GAP_MIN_CELLS`; 25 km²).
5. **Outcome:** if **any** unit is materially affected, apply the fill (point 6),
   rebuild the stack, and re-run STEP 9.2 on the rebuilt stack. If **none** is,
   Decision 10 closes with "no fill needed" and the common mask is final.
6. **Fill method (used only if point 5 triggers):** fill a `NA` gHM cell with
   the mean of the valid gHM cells in its 3 × 3 neighbourhood (`GAP_FILL_WINDOW`),
   `NA` cells only (`terra::focal(..., na.policy = "only", na.rm = TRUE)`).
   Repeat up to 5 passes (`GAP_FILL_MAX_ITER`), so no filled cell is more than
   5 km from real gHM data. Fill only cells where the other five bands have
   values. Cells still `NA` after 5 passes stay `NA`.

**Reason and sources:**
- **Why a buffer, and why 10 km.** The reserve polygons are core-PA polygons
  that under-state the reserve (Decision 4), and a least-cost path starts at the
  polygon edge. So the zone just outside each polygon matters for connectivity
  as much as the polygon. Two independent bases give about 10 km:
  - *Policy.* India's default eco-sensitive zone around a protected area
    extends up to 10 km (Wildlife Conservation Strategy 2002; MoEF 2011 ESZ
    guidelines), and the guidelines include connectivity areas in that zone.
    Indian policy therefore already treats a zone of up to 10 km as the area
    that affects a protected area.
  - *Tiger ranging.* Mean resident female home ranges from Indian telemetry are
    56.4 km² in the Sundarban (Naha et al. 2016) and 73.6 km² in Panna
    (Sarkar et al. 2016). As circles, these have diameters of about 8.5 km and
    9.7 km. A 10 km ring is therefore about one female home-range width: the
    distance a resident animal's range reaches beyond the boundary.
  - *Rejected — narrower.* Yumnam et al. (2014) buffered least-cost corridors
    by 1.5 km, but that is a corridor **width**, not a reserve approach zone.
    It would test too few cells at the reserve edge.
  - No study was found that sets a buffer for this exact purpose (a
    covariate-coverage check). The value is a documented judgement from the
    two bases above.
- **Why 25 km² / 5 %.** 25 km² is less than half of the mean resident female
  ranges above (56.4 and 73.6 km²), so a loss below it is unlikely to remove a
  whole female territory's worth of habitat from a path or a suitability
  pattern. It is above the smallest female ranges reported in high-prey sites
  (about 10 km², reviewed in Naha et al. 2016), so it is not a lenient bound
  there. The 5 % share catches small units (for example narrow corridors),
  where fewer than 25 cells can still be a large fraction. **No published
  source gives the 5 % value; it is a judgement call** and is recorded as one.
- **Why land cells only.** A dropped water cell has no effect on the check's
  purpose: water will get a high resistance under the Week-9 land-cover values
  and adds nothing to an SDM. Counting it would make coastal units fail on sea
  and river channels. *Caveat carried to task 9.3:* Naha et al. (2016) studied
  tiger movement across water channels in the Sundarban, so treating water as
  a barrier there needs its own check when the resistance values are decided.
- **Why this fill.** The gaps are at gHM's coastal/border edge and small
  interior gaps (Decision 10). A neighbourhood mean of the valid cells is the
  standard way to fill small raster gaps, and it matches how gHM was already
  resampled (bilinear, `scripts/01` Block 5). The 5-pass bound keeps every
  filled value within about one female home-range radius (≈ 4.8 km for 73.6 km²)
  of real data, so the fill does not invent human-pressure values far inland or
  offshore. **No published study was found that prescribes a fill method for
  gHM edge gaps;** the method is a general raster technique
  (`terra::focal`, Hijmans), chosen before the result is known.

**Consequences:**
- STEP 9.2 writes `data/interim/cov_commonmask_dropped_1km_7755.tif` and
  `outputs/tables/tbl_11_ghm_gap_relevance.csv`, and prints the outcome.
- The outcome (triggered or not) is recorded in this document **before** the
  resistance STEPs (9.5+) are written.
- If triggered, where the fill code lives (in `scripts/06`, which builds the
  stack, or elsewhere) is decided then; the method itself does not change.

**Outcome — pre-fill check (2026-09-26): TRIGGERED.**
Source: `outputs/tables/tbl_11_ghm_gap_relevance_prefill.csv` (172 rows: 169
checked units + 3 geometry-absent reserves) and
`data/interim/cov_commonmask_dropped_prefill_1km_7755.tif`.
- The 56,827 dropped India-grid cells are 27,880 water (class 80) and 28,947
  land; the largest land class is cropland (class 40, 17,329 cells).
- **27 of 169 units are materially affected:** 16 of 55 buffer rings, 5 of 55
  reserves, 6 of 59 corridors. 17 fail on the 25-cell count only (share below
  5 %; mostly large buffer rings), 7 on the 5 % share only (small corridors and
  Orang), and 3 on both (Sundarbans reserve and ring, Kaziranga reserve).
- Largest losses: Nagarjunsagar-Srisailam ring 199 land cells (3.77 %; its
  polygon is over-extended, Decision 4 limitation); Sundarbans reserve 177
  (12.27 %); Satpura ring 69; Sundarbans ring 52 (10.06 %); Nagarjunsagar-
  Srisailam reserve 48.
- *Likely cause (hypothesis, not tested):* gHM is `NA` over water, and the
  bilinear resample in `scripts/01` sets a cell `NA` when a neighbour is `NA`,
  so land cells next to water are lost. Several failing units are inland next
  to reservoirs or large rivers (Nagarjunsagar/Srisailam, Satpura, Kali,
  Mukundara), which fits this.

**Implementation of the outcome (2026-09-26; process choices, not a new
Decision):**
- **Fill location:** `scripts/06` STEP 8.4b, between distance-to-road and
  stacking, switched by `GHM_GAP_FILL <- TRUE` in `R/00_config.R`. `scripts/06`
  stays the only writer of the stack. `tbl_10` gains `n_filled`.
- **Water cells:** the fill works by eligibility (other five bands present), so
  eligible water cells are filled too. Resistance for water comes from land
  cover (task 9.3), so this does not set any resistance value. *(Correction,
  2026-09-26: this became false when Decision 14 added a gHM multiplier for
  every class — in the first resistance build the imputed gHM raised water
  resistance (mean 87.4 against a class value of 50). Decision 16 exempts water
  from the multiplier, which makes the statement true again.)*
- **Pre-fill evidence kept:** `scripts/07` labels its STEP-9.2 outputs
  `_prefill` / `_postfill` from `tbl_10` `n_filled`, so the post-fill re-check
  never overwrites the pre-fill result.
- **If the post-fill re-check still triggers:** stop and decide again before
  STEP 9.3. No extra fill passes are added automatically. (Decision 11 did not
  say what to do in this case; this rule was fixed before the post-fill run.)

**Outcome — post-fill check (2026-09-26): STILL TRIGGERED — 1 unit.**
Source: `tbl_11_ghm_gap_relevance_postfill.csv`,
`cov_commonmask_dropped_postfill_1km_7755.tif`, `tbl_10` (`n_filled` 54,958).
- The fill filled **54,958** gHM cells (passes: 48,929 / 4,431 / 1,124 / 360 /
  114). **91** eligible cells stayed `NA`, all water (class 80). Complete-case
  cells rose from 3,010,738 to **3,065,696 (99.94 %)**; the India-footprint
  loss fell from 56,827 to **1,869** cells. Spot-check means of the unchanged
  bands are within 0.1 % of their sources.
- The 1,869 dropped cells are the **1,778 India cells with no land-cover class**
  plus the 91 water cells. **No dropped land cell is now caused by gHM.**
- The one failing unit is corridor `dhudwa_nepal2`: 6 of 43 land cells
  (13.95 %), all no-class cells. The fill cannot reach them by design (a cell
  with no land cover is not eligible).
- Per the rule fixed before this run, the week stopped for a new decision →
  **Decision 12.**

### Decision 12 — Post-fill trigger: gHM gap closed; land-cover edge offset fixed at source
**Date:** 2026-09-26
**Status:** made **after** the post-fill result (Decision 11 stop rule). It is a
post-result decision and is recorded as one.

**Facts that led to it:**
- After the Decision-11 fill, the remaining loss is not a gHM gap. It is 1,778
  India cells with no WorldCover class (plus 91 water cells > 5 km from gHM
  data).
- **Cause (mostly confirmed):** `scripts/01` masked WorldCover to India on its
  own grid; `scripts/06` resamples that masked layer onto the snapped template,
  which shifts the class edge by about one cell. As built, the landcover band
  had **1,791 cells outside** the India polygon and **no class in 1,778 India
  cells**. A distance check (2026-09-26) put the no-class cells a median 506 m
  from the India boundary, with 75 % within 587 m (min 204 m) — the one-cell
  shift. **But the maximum was 291 km** (mean 975 m): a small number of
  no-class cells are interior gaps that the edge shift does not explain. Their
  cause is not known.
- All 88 unmasked 1 km WorldCover tiles that `scripts/01` cached are on disk.

**Choice:**
1. **gHM:** Decision 10 closes for gHM. The Decision-11 fill resolved the gHM
   gap; the 91 water cells that stay `NA` are accepted (they are more than 5 km
   from gHM data, and water resistance comes from land cover).
2. **Land cover — fix at source.** `scripts/06` STEP 8.3 builds land cover from
   the 88 unmasked tiles (merged in the `scripts/01` order), resamples it
   (nearest) onto the template, and masks it to India **on the template** —
   the same India mask as `dist_road_m`. A guard stops the build if any India
   cell that had a class changes or loses it. `06` also writes the aligned
   land cover to `data/interim/cov_landcover_worldcover2021_aligned_1km_7755.tif`
   for `scripts/07`, and tags the build `lc_source = "tile_cache"` in `tbl_10`.
3. **Re-check:** re-run `scripts/06` and `scripts/07` STEP 9.2 (labelled
   `postfill_d12`). The Decision-11 rule applies unchanged. **Clear →** Decision
   10 closes. **Still triggered →** stop and decide again (the Decision-11 stop
   rule still applies). `scripts/07` now reports how many no-class cells are
   edge cells (within 1.5 cells of the boundary) and how many are interior.
4. The interior no-class cells are **not** addressed by this Decision.

**Rejected:**
- *Extend the gHM fill* — the stop rule forbids extra passes, and gHM is not
  the cause.
- *Majority-class fill of no-class cells* — it would invent land-cover classes
  at borders when the real classes are in the tile cache.
- *Leave the cells `NA`* — the defect has a known cause and a fix that uses
  real data.

**Consequences:**
- Edge-effect gHM cells at these 1,778 locations become eligible for the
  Decision-11 fill once they have a land-cover class, so the rebuilt stack may
  fill slightly more gHM cells than 54,958.
- Terrain and gHM still come from `scripts/01` layers masked on the
  `scripts/01` grid, so the same one-cell shift can exist for them (terrain is
  net +20 against the India count; the split is not measured). Any India cell
  that lacks terrain will show in the `postfill_d12` check as a dropped cell
  with a land-cover class.

**Outcome — `postfill_d12` check (2026-09-26): STILL TRIGGERED — 1 unit.**
Source: `tbl_11_ghm_gap_relevance_postfill_d12.csv`,
`cov_commonmask_dropped_postfill_d12_1km_7755.tif`, `tbl_10`.
- The land-cover fix worked. Guard PASS (no interior class changed or lost).
  India cells with a class rose from 3,065,787 to **3,067,558**; **7** still
  have none, all interior (31–291 km from the boundary).
- The loss did **not** change: 1,869 India cells dropped, 3,065,696
  complete-case cells, `n_filled` 54,958. The 1,771 edge cells that gained a
  class are still dropped: **terrain is `NA` there** (inferred: they have land
  cover and distance-to-road, yet the Decision-11 fill still did not treat them
  as eligible, and terrain is the only other eligibility condition). This is
  the terrain case named in the consequences above.
- Dropped cells now: 1,771 terrain-edge cells (463 of them water) + 91 water
  cells beyond the gHM fill + 7 interior no-class cells.
- Failing unit: corridor `dhudwa_nepal2` (Nepal border), 5 of 42 land cells
  (11.9 %) — terrain-edge cells. The stop rule applied → **Decision 13.**

### Decision 13 — Terrain edge shift fixed at source; interior no-class cells accepted
**Date:** 2026-09-26
**Status:** made **after** the `postfill_d12` result (stop rule). A post-result
decision, recorded as one.

**Choice:**
1. **Terrain — fix at source, the Decision-12 way.** `scripts/06` rebuilds
   elevation, slope and TRI from the cached raw DEM
   (`data/raw/terrain/dem_india_aws_z7_4326.tif`, clipped to India + 5 km) by
   repeating `scripts/01` Block 7 exactly **without its India mask**: slope and
   TRI on the native DEM; bilinear projection onto the `scripts/01` grid (India
   + 5,000 m, 1 km); then the Week-8 bilinear resample onto the template; then
   the India mask **on the template**.
2. **Guard (fixed before the run):** cells whose 5 × 5 neighbourhood lies wholly
   inside India ("core") must match the Week-8 terrain within 0.01 in each band
   (`TERR_GUARD_TOL`; the Week-8 layer is stored as 32-bit float) and must not
   lose a value; otherwise the build stops. Edge cells that gain or change a
   value are counted and reported, not stopped.
3. **Interior no-class cells (7) — accepted.** They are 31–291 km inside India,
   their cause is not known, and they are 7 of 3.07 million cells. `scripts/07`
   prints their cell centres; the list is recorded here after the re-check.
4. **gHM is not rebuilt at source.** It is now the only band masked on the
   `scripts/01` grid, but `scripts/01` read it remotely and kept no local copy;
   a source fix would need a new download. Once terrain is present at the edge
   cells, they become eligible for the Decision-11 fill.
5. **Re-check:** re-run `scripts/06` and `scripts/07` STEP 9.2. `tbl_10` now
   carries `build_tag = "d13"`, so the outputs are labelled `postfill_d13`. The
   Decision-11 rule applies unchanged. **Clear →** Decision 10 closes.
   **Still triggered →** stop and decide again.

**Rejected:**
- *Focal-mean fill of the terrain edge cells* — real values exist in the raw
  DEM.
- *Accept and close now* — every border and coastal edge cell would stay `NA`,
  and Week-10 least-cost paths cross borders at transboundary links (Dudhwa–
  Nepal, Valmiki, Manas–Bhutan, Sundarbans); `NA` cells block paths.

**Consequences:**
- The rebuilt stack should gain up to about 1,771 complete-case cells, and
  `n_filled` should rise (gHM edge cells become eligible).
- Edge-cell terrain values come from the unmasked source, so edge cells that
  already had a value may change slightly (reported by the guard as
  `changed_edge`).
- Decision numbers for Week 9: resistance values (task 9.3) → **Decision 14**;
  barrier road classes (task 9.4) → **Decision 15**.

**Outcome — `postfill_d13` check (2026-09-26): CLEAR. Decision 10 closes.**
Source: `tbl_11_ghm_gap_relevance_postfill_d13.csv` (0 units with any dropped
land cell), `cov_commonmask_dropped_postfill_d13_1km_7755.tif`, `tbl_10`
(`build_tag` d13).
- Decision-12 and Decision-13 guards PASS. Terrain core difference: **0** in
  every band; no core value lost. Terrain now covers all 3,067,565 India-grid
  cells (before: 3,065,794).
- Edge report: 1,771 edge cells gained terrain in each band. Edge cells whose
  value changed by more than 0.01: elevation 8,627, slope 5,298, TRI 8,096.
  These are expected (the Week-8 edge values were interpolated from a masked
  source); the size of the changes was not measured.
- gHM fill: **56,729** cells filled (was 54,958; the edge cells became
  eligible); 91 eligible cells stay `NA`, all water.
- **Complete-case cells: 3,067,467** (100.00 % of the India grid after
  rounding; exactly 3,067,565 − 98). Dropped: **98** = 91 water cells more
  than 5 km from gHM data + 7 India cells with no WorldCover class.
- Spot-check (stack vs source mean): gHM 0.377 / 0.377; elevation 571.309 /
  571.291; slope 2.506 / 2.506; TRI 23.117 / 23.116; distance-to-road 2,044.3 /
  2,045.0; land cover modal 40, 11 classes.
- **The 7 no-class cells (accepted, Decision 13):** cell centres in EPSG:7755 —
  (5294500, 4060500), (5294500, 4059500) ≈ 92.99°E 24.00°N;
  (4697500, 4020500), (4697500, 4019500), (4697500, 4018500), (4697500, 4017500)
  ≈ 86.99°E 24.00–24.03°N; (3500500, 4008500) ≈ 74.99°E 24.00°N. All 7 sit on
  **3° WorldCover tile corners** (24°N with 75°E, 87°E, 93°E). *Likely cause:*
  a seam where `scripts/01` reprojected each 3° tile on its own and snapped it
  onto the shared grid. Not tested further; no unit is affected.
- Elevation minimum in the stack is now **−434.2 m** (edge water cells now
  have terrain) — see the Week-14 pending item.

### Decision 14 — Land-cover resistance values, human-pressure multiplier, Sundarban water, and a sensitivity variant
**Date:** 2026-09-26 (fixed **before** any resistance surface is built)
**Choice:** The baseline resistance surface for Stage 2 is built from land cover
and human pressure; the road barrier (Decision 15) is added after this step.
All values live in `R/00_config.R`; `scripts/07_connectivity.R` STEP 9.5 reads
them.

1. **Class values** (`WORLDCOVER_RESISTANCE`, scale 1 = easiest … 100 = maximum):

   | WorldCover class | Starting value (Week 0) | **Decision 14** | Basis |
   |---|---|---|---|
   | 10 Tree cover | 1 | **1** | Preferred by dispersing tigers (Krishnamurthy et al. 2016; Dutta & Krishnamurthy 2024) |
   | 20 Shrubland | 3 | **3** | Open/degraded forest; negligible resistance in the genetics study (Thatte et al. 2018) |
   | 30 Grassland | 5 | **3** | At 1 km, mostly open dry forest and savanna inside reserves (data check below). *Judgement.* |
   | 40 Cropland | 7 | **10** | Avoided at fine scale but crossed, and crossed fast (Krishnamurthy et al. 2016; Dutta & Krishnamurthy 2024); low resistance in the genetics study (Thatte et al. 2018). Evidence mixed. *Judgement.* |
   | 50 Built-up | 50 | **100** | Dense settlement had the highest resistance in the genetics study (Thatte et al. 2018); dispersers avoided the human-dominated landscape (Dutta & Krishnamurthy 2024) |
   | 60 Bare / sparse | 10 | **10** | No tiger-specific evidence. *Judgement.* |
   | 70 Snow and ice | 100 | **100** | Unchanged; not tiger habitat |
   | 80 Permanent water | 100 | **50** (10 in the Sundarban region, point 3) | Wide water is rarely crossed but is not a barrier (Naha et al. 2016) |
   | 90 Herbaceous wetland | 15 | **3** | Open natural wet habitat, treated like grassland. It has **no** cells in any reserve polygon and covers 0.1 % of India at 1 km, so its effect is small. *Judgement.* |
   | 95 Mangroves | 10 | **1** | Preferred habitat of Sundarban tigers (Naha et al. 2016) |
   | 100 Moss and lichen | 8 | **50** | High alpine; not tiger habitat; 0.3 % of India and absent from reserves. *Judgement.* |

2. **Human-pressure multiplier (gHM):**
   `resistance = min(100, class value × (1 + 4 × gHM))` (`RESIST_GHM_K = 4`,
   `RESIST_MAX = 100`). The factor runs from ×1 (gHM 0) to ×5 (gHM 1).
   Examples: forest at gHM 0.1 → 1.4; cropland at gHM 0.2 → 18; cropland at gHM
   0.6 → 34; built-up → 100 at any gHM. **k = 4 is a judgement value.**
   *(Amended by Decision 16: water (class 80) is exempt from the multiplier.)*
3. **Sundarban water region:** inside the Sundarbans reserve polygon
   (`unit_id` 57) plus a 10 km ring (the Decision-11 `GAP_BUFFER_M`), a water
   cell (class 80) takes **10** instead of 50, before the gHM multiplier. No
   hand-drawn geometry is used.
4. **Sensitivity variant (fixed now):** the same surface with **k = 0** — set
   B without the gHM multiplier, same water region. Written beside the
   baseline and compared with it in Week 10. The comparison metric is fixed
   before the variant's paths are examined.
5. **Order of operations:** class value → Sundarban water override → gHM
   multiplier → cap at 100 → road barrier (Decision 15, task 9.6).

**Reason and sources:**
- **Why class values now, not 1 − suitability.** The national corridor work
  estimated habitat resistance as 1 − Ψ from occupancy and modelled corridors
  between reserves with circuit theory (Jhala et al. 2021; Qureshi et al.
  2014). This project's habitat model (Stage 3) does not exist yet, so Stage 2
  uses literature-informed class values. An SDM-based check follows Stage 3
  (pending item).
- **Movement evidence (central India).** Six GPS dispersal paths: tigers
  preferred forest on rugged ridges at broad scale and avoided the
  agriculture–village matrix at fine scale (Krishnamurthy et al. 2016). Five
  dispersers avoided the human-dominated landscape and moved faster through
  non-forest (Dutta & Krishnamurthy 2024). Genetics: dense settlements and
  high-traffic roads had the highest resistance; degraded forest and
  plantations almost none; the agriculture–village matrix was low (Thatte et
  al. 2018). The shared signal is **human settlement and pressure**, not
  cropland as such — hence the gHM multiplier (point 2) with a moderate
  cropland base value.
- **Why ratios matter.** A least-cost path compares costs. With forest 1 and
  cropland 10, 1 km of cropland costs as much as 10 km of forest; with the gHM
  multiplier, 1 km of busy farmland (gHM 0.6, value 34) costs as much as 34 km
  of forest. The cropland value and k are the most sensitive judgement values,
  which is why the variant (point 4) removes k.
- **Water.** Sundarban tigers crossed about five channels wider than 30 m each
  day (mean width 54 m) and rarely crossed channels wider than 400 m, but one
  male crossed an 800 m river and settled in Bangladesh (Naha et al. 2016). At
  1 km a cell is class 80 only where water is the most common cover, so class-80
  cells are wide water: rarely crossed, not a barrier. Outside the Sundarban no
  peer-reviewed tiger movement evidence on water was found, so water stays at
  50 there. The Brahmaputra valley was considered and **not** included: the
  evidence is grey literature only.
- **Scale.** 1–100 is the common convention. For long-distance movers Keeley et
  al. (2016) recommend transforms that leave much of the landscape at low
  resistance; the low values for the open natural classes follow that
  direction. The transform question returns with the SDM-based check.

**Data check (2026-09-26):** share of 1 km cells by WorldCover class inside the
55 reserve polygons vs all of India (aligned land cover, `scripts/06`):

| Class | Reserves | India |
|---|---|---|
| 10 Tree cover | 75.8 % | 26.1 % |
| 20 Shrubland | 5.6 % | 3.2 % |
| 30 Grassland | 6.8 % | 7.3 % |
| 40 Cropland | 5.8 % | 54.6 % |
| 50 Built-up | 0.0 % (7 cells) | 0.9 % |
| 60 Bare / sparse | 0.2 % | 4.8 % |
| 80 Water | 2.6 % | 1.7 % |
| 95 Mangroves | 3.2 % | 0.1 % |
| 70, 90, 100 | none | 0.7 %, 0.1 %, 0.3 % |

Reserves where a class is ≥ 10 % of cells: grassland in Madhav 35.8 %,
Mukundara Hills 34.2 %, Ratapani 34.1 %, Panna 30.2 %, Sariska 28.2 %,
Sathyamangalam 24.2 %, Ranthambore 23.5 %, Bandipur 20 % and 6 others;
cropland in Orang 31 %, Manas 27.8 %, Sanjay Dubri 23.6 %, Nameri 22.2 %,
Ramgarh Vishdhari 18.2 %, Kaziranga 17.2 % and 5 others; water in Orang 23.9 %,
Sundarbans 20.4 %, Sahyadri 14.2 %, Kaziranga 11.7 %, Bor 11.2 %; mangroves in
Sundarbans 79.2 %. **Limit:** reserve composition shows where tigers live and
where reserves were placed, not how tigers move. It supports the values; it
does not calibrate them. It also changed one basis: class 90 was first
justified by the Kaziranga/Dudhwa/Manas floodplains, but WorldCover does not map
those as class 90 at 1 km.

**Rejected:**
- *Keep the starting values* — mangroves (10) and herbaceous wetland (15) were
  too high for preferred or open habitat; built-up (50) too low; water (100)
  treats a crossable feature as a near-barrier.
- *Land cover + roads only* (the Week-0 plan) — it cannot separate a busy
  village belt from remote farmland, which is the main signal in the studies.
  Kept as the variant.
- *Water 100 everywhere* — isolates the Sundarban islands against the
  telemetry evidence.
- *A Brahmaputra water region* — grey-literature evidence only.

**Consequences:**
- `scripts/07` STEP 9.5 builds the land-cover × gHM surface and the variant;
  STEP 9.6 adds the road barrier (Decision 15); STEP 9.7 writes
  `resist_tiger_baseline_7755.tif` and `resist_tiger_noghm_7755.tif`.
- QA (`tbl_11_resistance_qa.csv`) must show every present class mapped, no
  `NA` inside the complete-case footprint, the value range, and the number of
  cells in the Sundarban water override.
- Week 10 adds a baseline-vs-variant path comparison.

### Decision 15 — Road barrier: classes, value, combine rule, and road-value variants
**Date:** 2026-09-26 (fixed **before** any resistance surface is built)
**Choice:** Roads are added to the Decision-14 surface as a barrier. Settings in
`R/00_config.R` (`ROAD_BARRIER_*`, `RESIST_VARIANTS`); `scripts/07_connectivity.R`
STEP 9.6 applies them.

1. **Barrier classes:** OSM `motorway`, `trunk`, `primary`, `secondary`, with
   each `_link` ramp taking its parent class. **Tertiary is not a barrier
   class**; its effect is left to gHM, which counts it as a minor road.
2. **One barrier value, 30,** for every barrier class
   (`ROAD_BARRIER_VALUE`). A road cell costs at least as much as 30 km of
   forest to cross. **A judgement value.**
3. **Combine rule: maximum.** On a road cell, resistance =
   max(Decision-14 surface, 30). The scale stays 1–100; a road through a town
   adds nothing (already 100).
4. **Rasterisation:** every 1 km cell a barrier road touches
   (`touches = TRUE`), so a diagonal road leaves no corner gaps for an
   8-neighbour path to slip through.
5. **Railways:** not a separate barrier; covered only through gHM (its
   transportation class includes railways). **Limitation.**
6. **Crossing structures** (for example the nine on NH-44 in Pench): not
   mapped; resistance is too high where they exist. **Limitation.**
7. **Variants (fixed now, compared in Week 10):** `road15` and `road50` — the
   baseline surface (k = 4) with a road value of 15 and 50, bracketing 30.
   `noghm` (Decision 14) keeps the road value 30. Each variant changes one
   choice only. The comparison metric is fixed before any variant's paths are
   examined.

**Reason and sources:**
- **Traffic, not the road as such.** In the genetics study, high-traffic roads
  (with dense settlement) had the highest resistance, and long-distance
  dispersers crossed low-traffic roads (Thatte et al. 2018). No tiger study
  found gives a resistance value per road class. With no national traffic data
  (no AADT for India), OSM class is the only traffic proxy. The India tagging
  guidance maps national highways to `trunk`, but Indian road classification is
  not uniform across authorities, so class ≈ road type is approximate and may
  vary by state (OpenStreetMap Wiki). A single value (point 2) does not claim a
  precision the class data do not have; the variants (point 7) test the value.
- **Why not tertiary.** Tertiary is the low-traffic class that dispersers
  cross, and it would double the barrier footprint (data check below).
- **Double counting with gHM.** gHM's transportation class includes roads and
  railways (Theobald et al. 2025). The data check shows gHM is only moderately
  higher on barrier-road cells (0.525 against 0.377 for India), so with k = 4
  the Decision-14 multiplier on a road cell is about ×3.1 against ×2.5 on
  average. gHM therefore carries only a small part of the road effect; the
  barrier value carries most of it. The maximum rule (point 3) keeps the two
  from stacking.
- **Mortality and structures (context).** An RTI record counts 26 tiger deaths
  on roads and railways between January 2010 and January 2021 (news report);
  camera traps at the NH-44 structures in Pench recorded tigers among 21 mammal
  species using them (Habib et al. 2020; Saxena & Habib 2022).

**Data check (2026-09-26; `FLT4S` stack, `build_tag` d13f):** OSM major roads
rasterised onto the 1 km grid with `touches = TRUE`:

| Classes | Length (km) | India cells touched | Reserve cells touched | Mean gHM on those cells |
|---|---|---|---|---|
| motorway | 15,366 | 0.3 % | 25 | 0.603 |
| trunk | 181,537 | 5.1 % | 797 | 0.552 |
| primary | 164,825 | 5.9 % | 1,183 | 0.546 |
| secondary | 210,340 | 7.7 % | 806 | 0.518 |
| tertiary | 658,303 | 22.5 % | 2,852 | 0.510 |
| motorway–primary | 361,728 | 10.9 % | 1,964 | 0.545 |
| **motorway–secondary (chosen)** | **572,068** | **17.5 %** | **2,711** | **0.525** |
| all five | 1,230,370 | 34.8 % | 5,260 | 0.504 |

India mean gHM: 0.377. **Consequence of the footprint:** 17.5 % of India's
cells will be at least 30 on the baseline surface, so the road value is one of
the most influential judgement values in Stage 2 — hence two variants.
*(Outcome note, first resistance build 2026-09-26: **41.4 %** of baseline cells
are at or above 30, not only the 17.5 % that are road cells, because the gHM
multiplier raises busy cropland to about 30 (cropland mean 30.3). Only 255,500
of the 535,592 road cells were raised by the maximum rule; in busy farmland the
road adds nothing. This follows from Decision 14 (its own example: cropland at
gHM 0.6 → 34). The `noghm` variant tests it (20.3 % at or above 30). Figures
after Decision 16 are in `tbl_11_resistance_qa.csv`.)*

**Rejected:**
- *All five classes* — doubles the barrier footprint to 34.8 % of India with
  the low-traffic class that dispersers cross.
- *Graded values by class* (100 / 50 / 30 / 15) — more detail than the OSM
  classes support; the evidence is qualitative.
- *Additive or multiplicative combine* — counts the road part of gHM twice;
  values leave the 1–100 scale.
- *Render-path rasterisation* — diagonal roads leak for an 8-neighbour path.
- *A railway barrier* and *hand-coded crossing structures* — no consistent
  national data; recorded as limitations.

**Consequences:**
- `scripts/07` STEP 9.6 rasterises the barrier roads and applies the maximum
  rule to the baseline and to every variant; STEP 9.7 writes
  `resist_tiger_baseline_7755.tif`, `resist_tiger_noghm_7755.tif`,
  `resist_tiger_road15_7755.tif` and `resist_tiger_road50_7755.tif`.
- Week 10 compares the baseline with three variants.

### Decision 16 — Water exempt from the gHM multiplier
**Date:** 2026-09-26
**Status:** made **after** the first resistance build, from its QA. A
post-result decision, recorded as one.

**Facts that led to it:**
- The gHM source has no data over water. The Decision-11 fill gave eligible
  water cells gHM values from their land neighbours, only to keep them in the
  stack; the record said this would not set any resistance value.
- Decision 14 then applied the gHM multiplier to every class. In the first
  build (`tbl_11_resistance_qa_pred16.csv`), water (class value 50) had a
  **mean final resistance of 87.4**: water near busy shores took a high
  imputed gHM and reached the cap. Sundarban water (10) was multiplied too.
- The multiplier is meant to measure human pressure on land a tiger walks
  across; on water it multiplied an imputed value.

**Choice:** the gHM multiplier is **not** applied to water (class 80;
`RESIST_GHM_EXEMPT_CLASSES`). Water resistance = its land-cover value: 50, or
10 inside the Sundarban water region. The cap and the road maximum rule still
apply (a barrier road over water takes max(value, road value)). Every surface
(baseline and variants) is rebuilt with this rule.

**Rejected:**
- *Keep the multiplier on water and correct the docs* — keeps a resistance
  value built on imputed data.
- *Exempt every cell whose gHM was filled* (water and about 1,771 edge land
  cells) — filling the land cells was the purpose of Decision 11.

**Consequences:**
- `scripts/07` STEP 9.5 applies the multiplier through `ifel(exempt, 1,
  1 + k × gHM)`; `tbl_11_resistance_qa.csv` gains `n_ghm_exempt`.
- The first-build QA table is kept as `tbl_11_resistance_qa_pred16.csv`
  (evidence for this Decision); the rebuilt surfaces overwrite the first-build
  rasters.

**Outcome (2026-09-26, rebuild): all asserts PASS.** 51,587 water cells exempt.
Water mean final resistance **49.58** (was 87.37; 546 Sundarban cells at 10, the
rest at 50). The `noghm` row is identical to the first build (k = 0 makes the
multiplier 1 everywhere), which confirms nothing else changed. Cells capped at
100 for k = 4: 51,184 (was 80,424). Road cells raised: baseline 255,502 and
`road15` 164,340 (+2 each: two Sundarban water cells on barrier roads were
above 30 before and are 10 now, so the maximum rule raises them); `noghm` and
`road50` unchanged at 510,408. Means: baseline 22.46, `noghm` 12.97, `road15`
21.58, `road50` 25.45. At or above the road value: 41.40 %, 20.31 %, 65.09 %,
20.31 %. Baseline class means (value → mean final): tree 1 → 5.91, shrub 3 →
9.58, grass 3 → 9.16, crop 10 → 30.31, built-up 100 → 100, bare 10 → 14.74,
snow 100 → 100, water 50 → 49.58, wetland 3 → 5.76, mangrove 1 → 2.48, moss
50 → 51.39. Barriers score high (built-up, snow, water, road cells) and tree
cover and mangroves score low — the task-9.8 sanity check holds.

### Decision 17 — Least-cost-path set-up: pairs, path method, start and end, geometry-absent reserves, network groups, NTCA comparison
**Date:** 2026-10-01 (fixed **before** any path is built; the first record
gave 2026-09-27 by mistake)
**Amended:** 2026-10-02, before any path is built — point 6 (definition of a
contiguous pair, option C1), point 4 check (b) (how it is run), and the
evidence count of gap-0 pairs (7 → 8).
**Choice:** Settings in `R/00_config.R` (`LCP_*`, `NETWORK_GROUPS`,
`BOUNDARY_STATE_SPLITS`). The Week-10 STEPs of `scripts/07_connectivity.R`
apply points 1–6 and 8–9; `scripts/02_prepare_boundaries.R` applies point 7.

1. **Reserve pairs — Euclidean-allocation adjacency with a gap cap (fork a).**
   - Every complete-case footprint cell (Decision 10) is allocated to the
     nearest reserve polygon by straight-line distance. Two reserves are a
     **candidate pair** if their allocation zones share at least one cell edge.
   - A candidate pair is **kept** if the straight-line gap between the two
     polygons is **≤ 315 km** (`LCP_PAIR_MAX_GAP_KM`).
   - The pair set comes from geometry only, so it is **the same for all four
     surfaces**. No pair is added or removed after a path is seen. Point 2
     changes network membership only.
2. **A path that crosses a third reserve (sub-fork P3).** If the A–B path
   crosses cells of reserve C (cells shared with A or B do not count), and A–C
   and C–B are both pairs, A–B is **not** in the Week-11 network
   (`in_network = FALSE`). Otherwise A–B stays in the network and C is recorded
   (`via_unit_ids`). The rule is applied per surface, after the paths are
   built. The path tables keep every pair; the Decision-18 comparison uses
   every pair.
3. **Graph and step cost (forks b1, b2).**
   - Nodes: complete-case footprint cells. `NA` cells are not nodes.
   - **16 neighbours:** 4 orthogonal (1 km), 4 diagonal (√2 km) and 8 knight
     moves (√5 km).
   - **Step cost = step length (km) × the length-weighted mean resistance of
     the cells that the straight line between the two cell centres crosses.**
     Orthogonal and diagonal steps: the two end cells, ½ each. Knight steps:
     the four cells crossed (start, two middle cells, end), ¼ each. A knight
     step is not allowed if any of the four cells is `NA`.
   - Cost-distance unit: **resistance-km**. Path length (km) is also recorded.
4. **Implementation (fork b3) — own graph, checked against existing tools.**
   The graph is built in R from the surface (`terra`) and searched with
   Dijkstra's algorithm in `igraph`, from all cells of the source reserve at
   once: one search per source reserve, to all of its paired targets. No
   least-cost-path package is a pipeline dependency. Validation
   (`tbl_12_lcp_validation.csv`) runs before the baseline paths are used:
   - (a) **Synthetic grid.** A small grid with hand-computed costs, at 8 and 16
      neighbours, with a one-cell barrier that a knight step must not jump.
      Exact agreement is required.
   - (b) **`terra::costDist`** (8 directions). Our engine at 8 neighbours against
      the `terra` accumulated cost from the source reserve's cells, read at the
      target reserve. *(Amended 2026-10-02:)* a test on a small grid showed
      that `terra` uses the mean of the two cells × the step length, the same
      as point 3. `terra` marks its targets by value, and a target cell's own
      value enters its first step, so both runs use a copy of the surface with
      the source cells set to 0. The source is free in the engine anyway.
   - (c) **`gdistance`** (16 directions; its documented cost uses the mean of the
      two end cells). Point to point between the start and end cells of our
      path, on a window that contains the path. Our engine runs in end-cell
      mode for knight steps (`LCP_KNIGHT_RULE = "end_cells"`, validation
      only). This checks the mechanics; check (a) checks the knight rule.
   - Pairs for (b) and (c), from the baseline pair set: the shortest non-zero
     gap, the gap nearest the median, and the longest gap (ties: lowest pair
     id).
   - Pass: relative cost difference ≤ 1e-6. A failure is a hard stop. Path
     overlap (share of cells in common) is reported, not a stop, because tied
     paths can differ.
5. **No crop (fork b4).** One national graph. Fallback only if the task-10.3
   smoke test shows that the graph does not fit in memory: a window per pair =
   the pair's bounding box + max(100 km, 50 % of the gap). A path that touches
   the window edge is re-run on a wider window.
6. **Start and end — edge to edge (fork c).**
   - Reserve cells = the footprint cells that the polygon touches
     (`touches = TRUE`). Cells outside India are `NA`, so 6 reserves use their
     India part only (share outside India in the geometry check: Sundarbans
     25 %, Buxa 18 %, Dudhwa 14 %, Valmiki 13 %, Namdapha 7 %, Manas 6 %).
   - Movement inside the source and target reserves costs nothing. Movement
     inside any other reserve costs that reserve's resistance.
   - *(Amended 2026-10-02, option C1:)* a pair is **contiguous** if the two
     reserves share at least one footprint cell. Every gap-0 pair is
     contiguous. A pair less than about 1.4 km apart (the cell diagonal) can
     be too, for example Namdapha–Kamlang (gap 0.3 km). A contiguous pair
     gets cost 0 and an empty path (`contiguous = TRUE`). QA accepts an empty
     path for a contiguous pair only. The pair table keeps `gap_km`.
7. **Geometry-absent reserves (fork d).**
   - **Amrabad (D1a).** `scripts/02` splits the Nagarjunsagar-Srisailam KML
     polygon at the Andhra Pradesh–Telangana boundary
     (`boundary_states_7755.gpkg`). The Andhra Pradesh part stays `unit_id` 1;
     the Telangana part becomes Amrabad (`unit_id` 51). Maps and network then
     use the same geometry. Evidence below.
   - **Pilibhit and Dholpur-Karauli (G1).** No geometry; not in the network.
     **Limitation.**
8. **Network groups (W2, H1).** A new field, `network_group`, set from a hand
   list (`NETWORK_GROUPS`) on geography: `northeast` (9 reserves),
   `western_ghats` (13), `north` (the Terai: Rajaji, Corbett, Dudhwa, Valmiki;
   Pilibhit is listed but has no geometry) and `central` (all other reserves,
   with the Rajasthan reserves, Ranipur and the Sundarbans). The groups are
   **labels only**: they remove no pair. A pair across two groups is kept and
   marked `cross_group = TRUE`. Whether the groups are separate in the network
   comes from the path costs in Week 11 (pending Decision below).
   `landscape_complex` does not change (see the note under Reason).
9. **NTCA corridor comparison (fork e) — descriptive.** For the baseline paths
   only: (i) for each path, the share of its length inside any NTCA corridor
   polygon; (ii) for each NTCA corridor, whether at least one baseline path
   crosses it. Not a validation: the corridors come from a different method
   (Qureshi et al. 2014).

**Reason and sources:**
- **Pairs.** This follows Linkage Mapper practice: candidate pairs come from
  adjacency in Euclidean or cost-weighted space, are limited by a maximum
  Euclidean distance, and cost is measured from each polygon edge (WHCWG 2010;
  McRae & Kavanagh 2011). Euclidean adjacency is used, not cost-weighted,
  because the pair set must not change with the surface: Decision 18 compares
  the same pairs. The cap is the longest straight-line dispersal recorded in
  India, 315 km by a GPS-collared sub-adult male from Tipeshwar (Hussain et al.
  2022). That distance is from a natal area to a settled area; the gaps here
  are edge to edge between core polygons, so the comparison is approximate.
  Valmiki (nearest gap 300.3 km) and Dampa (305.2 km) are just under the cap;
  with a 300 km cap both would be isolated by the rule.
- **Path through a third reserve.** Linkage Mapper can drop corridors that
  cross a core area. P3 drops one only where no connection is lost.
- **16 neighbours and the crossed-cells rule.** The largest length error is
  about 2.7 % with 16 neighbours against 8.2 % with 8 (1/cos 13.3° and
  1/cos 22.5°). The usual 16-neighbour cost uses only the two end cells, so a
  knight step can jump a barrier one cell wide: a road line (Decision 15,
  point 4) or an `NA` cell. The crossed-cells rule in point 3 stops this.
- **Own graph.** An edge-to-edge path needs a search from all source cells at
  once. `leastcostpath::create_lcp` uses only the first origin row, and
  `gdistance::shortestPath` only the first origin cell. The
  `leastcostpath::create_cs` documentation does not state how it reads the
  cell values or how it combines two cells. With our own graph the step cost
  is explicit in the code; `igraph` and `terra` are already in the stack.
  Existing tools check the result (point 4).
- **Edge to edge.** A centroid start adds cost inside the reserve and favours
  large reserves.
- **Amrabad.** The KML polygon's extent (78.34–79.47° E, 15.87–16.68° N) agrees
  with the published extent of the undivided reserve (78°30′–79°28′ E,
  15°53′–16°43′ N; Wikipedia, citing archived Project Tiger pages). 2,701.2 km²
  of its 5,073.9 km² lies in Telangana (`boundary_states_7755.gpkg`); Amrabad's
  census area is 2,611.4 km². The crosswalk notes that Amrabad sits within the
  Nagarjunasagar-Srisailam parcel historically. Polygon/census ratios after the
  split: Nagarjunsagar-Srisailam 0.72, Amrabad 1.03. The Telangana part has
  2 parts (2,698.9 and 2.3 km²). The Week-3 limitation says Amrabad's centre
  falls outside the polygon. A published Amrabad point (16.383° N, 78.833° E)
  does lie 2.2 km outside it, but that point is the Amrabad village, a
  settlement, not the reserve centre. The Week-3 cause for the 1.54 ratio
  ("coarse envelope of a fragmented hill sanctuary") is therefore replaced:
  the polygon holds both reserves. The limitation text changes with the
  `scripts/02` change.
- **Landscape complex (note).** `landscape_complex` places Ranthambore,
  Sariska, Mukundara Hills, Ramgarh Vishdhari and Dholpur-Karauli in
  `shivalik_gangetic`. The AITE reports place Rajasthan in the Central Indian
  and Eastern Ghats landscape, and add Ranipur to the Shivalik landscape for
  convenience (Jhala et al. 2023). The field stays as it is (author decision,
  2026-10-01). `network_group` is separate, so the network does not depend on
  it.

**Evidence (geometry check, 2026-10-01).** Made outside the pipeline with the
55 polygons and the Natural Earth 1:10 m India outline, with no resistance
values and no paths. The counts are approximate; the definitive pair set is
`tbl_12_reserve_pairs.csv`.

| Rule (55 reserves, before the split) | Pairs | Connected sets | Isolated | Longest gap (km) |
|---|---|---|---|---|
| Voronoi adjacency in India, no cap | 129 | 1 | 0 | 791 |
| **Voronoi adjacency + gap ≤ 315 km (chosen)** | **104** | **3** | **0** | **311** |
| Voronoi adjacency + gap ≤ 300 km | 101 | 5 | 2 | 300 |
| Voronoi adjacency + gap ≤ 200 km | 83 | 11 | 5 | 199 |
| Gap ≤ 200 km only | 118 | 11 | 5 | 199 |
| 3 nearest neighbours | 109 | 2 | 0 | 481 |

With the Amrabad split (56 reserves), the chosen rule gives about **106 pairs**
in **3 connected sets** (9, 13 and 34 reserves). **8 pairs** have gap 0:
Nagarjunsagar-Srisailam–Amrabad (the split line), Pakke–Nameri, Manas–Buxa,
Bandipur–Nagarhole, Bandipur–Mudumalai, Bandipur–Sathyamangalam, Periyar–
Srivilliputhur-Megamalai and Parambikulam–Anamalai. *(Corrected 2026-10-02:
the first record said 7 and left out the split pair.)* Namdapha–Kamlang
(0.3 km) can also be contiguous under point 6.
**2 pairs** cross network groups: Sariska–Corbett (292.7 km) and Sariska–
Rajaji (290.8 km). In 8 pairs the straight line between the nearest edges
crosses a third reserve (all in the Western Ghats and the Northeast).

**Rejected:**
- *Gap threshold only*, *k nearest neighbours*, *Voronoi adjacency with no
  cap* — redundant long pairs, forced links up to 481 km, or links of
  400–791 km.
- *Cost-weighted adjacency* — the pair set would change with the surface.
- *A 300 km cap* — isolates Valmiki and Dampa by the rule, not by cost.
- *Keep every path through a third reserve* (P1); *drop every such path* (P2).
- *8 neighbours* (K2) — up to 8.2 % length error. *16 neighbours with the
  end-cell cost* — jumps one-cell barriers.
- *`leastcostpath` or `gdistance` as the engine*, *point to point between the
  nearest edge points* — see Reason.
- *A crop by default* — a crop can cut off the true path.
- *A centroid start.*
- *Contiguous by polygon gap only* — with `touches = TRUE`, a pair 0.3 km
  apart can share a cell, so its path is empty although its gap is above 0.
  *Cell-centre membership* (`touches = FALSE`, option C2) — small polygons
  lose their edge cells. (Both rejected 2026-10-02.)
- *Amrabad split in `scripts/07` only* (D1b), *a joint node* (D2), *no change*
  (D3) — maps and network would disagree, or Nagarjunsagar-Srisailam would
  keep paths that start from Amrabad's area.
- *Geometry for Pilibhit and Dholpur-Karauli from OSM* (G2) — a new boundary
  source with a hand check; not now.
- *Pairs only inside a network group* (W1) — would assume, not measure, that
  the Terai is separate. *Groups from `landscape_complex`* (H2).
- *No NTCA comparison in Week 10* (E2).

**Consequences:**
- `scripts/02`: the state split (task 10.3b). `boundary_reserves_all_7755.gpkg`
  then has 56 reserves with geometry. Every Stage-1 output that uses the
  geometry is rebuilt, and the Stage-1 maps are re-rendered. The resistance
  surfaces do not use these polygons (the Sundarban water region uses
  `unit_id` 57 only), so they do not change.
- `scripts/07`: STEP 10.1 builds the pairs → `tbl_12_reserve_pairs.csv` (with
  `gap_km`, `contiguous` (shared footprint cell), `network_group` of each
  reserve, `cross_group`);
  STEP 10.2 builds the baseline paths → `lcp_reserve_network_7755.gpkg`;
  STEP 10.2b validates → `tbl_12_lcp_validation.csv`; STEP 10.3 QA; STEP 10.4
  builds the variant paths; STEP 10.5 writes the NTCA overlap →
  `tbl_12_lcp_ntca_overlap.csv`.
- `scripts/00a` (task 10.3): add `gdistance` (with `raster`) for validation;
  remove `leastcostpath`.
- Week 11 decides the functional-link rule (pending Decision below).

### Decision 18 — Variant comparison metric for the least-cost paths
**Date:** 2026-10-01 (fixed **before** any variant path is run; the first
record gave 2026-09-27 by mistake)
**Amended:** 2026-10-02 — point 1 uses the Decision-17 definition of a
contiguous pair (amended the same day).
**Choice:** Settings in `R/00_config.R` (`LCP_COMPARE_*`). `scripts/07` STEP
10.4 applies them. Each variant (`noghm`, `road15`, `road50`) is compared with
the baseline only, for the same pairs.

1. **Pairs compared:** every pair that is not contiguous (Decision 17 point 6).
   Contiguous pairs have no path and cost 0 on every surface; they are
   excluded and their count is reported.
2. **Route measure — symmetric buffer overlap.** For each pair:
   - share A = the length of the baseline path within *d* of the variant path
     ÷ the length of the baseline path;
   - share B = the length of the variant path within *d* of the baseline path
     ÷ the length of the variant path;
   - **route overlap = min(share A, share B).**
   - *d* = **5 km** (`LCP_COMPARE_ROUTE_D_KM`). Paths are the lines through the
     cell centres, in EPSG:7755.
3. **Material route change:** route overlap **< 0.5**
   (`LCP_COMPARE_ROUTE_MATERIAL`): most of the route is somewhere else.
4. **Cost measure — rank, not value.**
   - Per pair: the percentile rank of the cost-distance among the compared
     pairs, (rank − 1) / (n − 1), with tied costs given their average rank
     (0 = lowest cost, 1 = highest). Rank change = variant − baseline.
   - **Material rank change:** |rank change| **≥ 0.25**
     (`LCP_COMPARE_RANK_MATERIAL`), one quartile.
   - For the set: the **Spearman rank correlation** (ρ) between the baseline
     and variant cost-distances of the compared pairs.
5. **Material pair:** a material route change **or** a material rank change.
6. **Label for each variant (fixed now):** **robust** if the share of material
   pairs is **≤ 20 %** (`LCP_COMPARE_ROBUST_MAX_SHARE`) **and** ρ **≥ 0.9**
   (`LCP_COMPARE_ROBUST_MIN_RHO`); otherwise **sensitive**. `noghm` gives the
   label for the gHM multiplier (Decision 14). The road value (Decision 15) is
   called robust only if **both** `road15` and `road50` are robust.
   **The 20 % and 0.9 limits are judgement values.**
7. **Descriptive columns (no limits):** route overlap at 1, 2, 5 and 10 km;
   the path-length ratio (variant / baseline); whether the pair's
   `in_network` status changes (Decision 17 point 2); whether the third
   reserves that the path crosses change.

**Reason and sources:**
- **Route and cost separately.** In a sensitivity study across France, path
  overlap changed more with the cost scenario than cost distance did, and very
  different cost scenarios could still give highly correlated cost-distance
  matrices (Savary et al. 2022). A high ρ alone therefore does not show that
  the routes stay the same; point 5 counts a pair as material on either.
- **Per pair, not only one national figure.** How sensitive the route
  position is grows with habitat fragmentation and falls as the matrix becomes
  easier to cross (Rayfield et al. 2010), so the result varies by place.
- **Buffer overlap.** The buffer method is a standard measure of how close
  two lines are (Goodchild & Hunter 1997). The symmetric form (point 2) does
  not depend on where the paths end, which matters because edge-to-edge paths
  (Decision 17 point 6) can start and end at different edge cells.
- **5 km.** About one resident female home-range radius: 4.2 km from 56.4 km²
  (Naha et al. 2016) and 4.8 km from 73.6 km² (Sarkar et al. 2016). Within
  this distance, a tiger that uses one route meets the other.
- **Ranks, not values.** The variants change the cost scale by design (mean
  resistance 12.97 for `noghm` against 22.46 for the baseline). A raw cost
  ratio would mostly show that scale change.

**Rejected:**
- *Normalised Path Deviation Index* (Jan et al. 1999) — needs common path
  ends; `leastcostpath` moves the ends of one path to those of the other when
  they differ (Lewis 2025).
- *Hausdorff distance* — one local detour sets the value.
- *Share of path cells in common* — a one-cell shift at 1 km counts as a
  change.
- *d = 1.5 km* (the minimal corridor buffer of Yumnam et al. 2014; also
  rejected in Decision 11) and *d = 10 km* (the Decision-11 approach zone).
- *A material limit of 0.8* — stricter than "most of the route".
- *A raw cost ratio* — see Reason.
- *No label, interpretation in the write-up* — the reading would be chosen
  after the results.

**Consequences:**
- `scripts/07` STEP 10.4 writes `tbl_12_lcp_variant_comparison.csv` (one row
  per pair and variant) and `tbl_12_lcp_variant_summary.csv` (one row per
  variant: pairs compared, contiguous pairs excluded, shares of material route,
  rank and pair changes, ρ, label).
- The Week-10 write-up reports the labels as fixed here.
- Week 11 decides whether the network metrics are repeated on the variants
  (added to the Week-11 pending item).

### Decision 19 — Reserve network: links, nodes, edge weight, metrics, linchpin and isolated rules, variant comparison
**Date:** 2026-10-03 (fixed **before** any network metric is computed — see
"What was seen before this Decision")
**Choice:** Settings in `R/00_config.R` (`NET_*`). The Week-11 STEPs of
`scripts/07_connectivity.R` apply them. Fork codes as raised on 2026-10-03:
a1 + a4, b1, c1 + k3, d2, e2, f2.

1. **Links — all in-network pairs, no cost threshold (a1).** On each surface,
   every pair with `in_network == TRUE` (Decision 17 point 2) is a link. No
   pair is removed because of its cost. The cost-distance (`cost_rkm`,
   resistance-km) is the edge weight. In `igraph` a weight is a distance: a
   higher weight is a longer path.
2. **Nodes — contiguous reserves merge into one node (b1).** The contiguous
   pairs (Decision 17 point 6; cost 0) join their reserves into one **block**.
   A block is a connected set of reserves in the graph of the contiguous
   pairs. Each block is one node; each other reserve is its own node.
   - From `tbl_12_reserve_pairs.csv` (geometry only): **56 reserves → 47
     nodes.** Seven blocks have more than one reserve: Bandipur + Nagarhole +
     Mudumalai + Sathyamangalam; Nagarjunsagar-Srisailam + Amrabad; Namdapha +
     Kamlang; Pakke + Nameri; Manas + Buxa; Periyar + Srivilliputhur-Megamalai;
     Parambikulam + Anamalai.
   - The blocks come from geometry, so they are the same on all four
     surfaces.
   - `node_id` = the lowest `unit_id` in the node. `node_name` = the reserve
     names in `unit_id` order, joined with " + ".
3. **Edges — one per node pair, the lowest cost.** Between two nodes, the edge
   is the in-network pair with the lowest `cost_rkm` on that surface (a tie:
   the lowest `pair_id`). Each edge therefore traces to one `pair_id`. The
   graph is undirected and simple (no loop, no duplicate edge). Each
   in-network pair gets a `link_role`:
   - `block` — a contiguous pair (it makes a block; it is not an edge);
   - `within_block` — a pair that is not contiguous, with both reserves in one
     block (not an edge);
   - `edge` — the lowest-cost pair between two nodes;
   - `parallel` — another pair between the same two nodes (not an edge).
4. **Sets.** A set is a connected component of the graph. `set_size` counts
   nodes; the reserve count is given also.
5. **Metrics for each node (c1).** The reserves of one block share the values
   of their node.
   - `degree` — the number of edges.
   - `betweenness_raw` — weighted shortest-path betweenness (Freeman 1977;
     Brandes 2001): `igraph::betweenness()`, undirected, weights = `cost_rkm`,
     end points not counted, no cutoff. Equal-cost shortest paths share the
     count, as `igraph` does.
   - `betweenness_norm` — the raw value ÷ ((n − 1)(n − 2) / 2), where n is the
     number of nodes **in the node's own set**. This is the share of the node
     pairs of the set whose shortest path goes through the node (0 to 1).
     `NA` if n < 3 (`NET_NORM_MIN_SET_NODES`).
   - `betweenness_rank` — rank of `betweenness_norm` in the set (1 = highest;
     tied values take the lowest rank number).
   - `cut_node` — the node is an articulation point: without it, its set
     divides (`igraph::articulation_points()`).
   - `cheapest_link_rkm` — the lowest edge weight of the node (`NA` at degree
     0), and `cheapest_link_rank` over all nodes (1 = the highest value, the
     node that is hardest to reach from its nearest neighbour).
   For each edge: `is_bridge` — without the edge, its set divides
   (`igraph::bridges()`).
6. **Linchpin (k3).** Two columns, both fixed now:
   - `linchpin` = `betweenness_rank` ≤ **3** (`NET_LINCHPIN_TOP_N`) **and**
     `betweenness_norm` > 0. Nodes tied at rank 3 are all linchpins. A set
     with fewer than 3 nodes has no linchpin.
   - `cut_node` (point 5) is reported next to it. It is not a condition for
     the linchpin label.
   - **The number 3 is a judgement value.** In a small set, three nodes are a
     large share of the set (the smallest set has 6 nodes if all pairs are
     links); read the label with `set_size`.
7. **Isolated (d2).**
   - `isolated` = `degree` 0 (a set of one node).
   - `pendant` = `degree` 1 (one edge only).
   - `cheapest_link_rkm` and its rank (point 5) are the graded measure. No
     cost limit makes a reserve "isolated".
   - If no node has degree 0, the result is "no reserve is isolated by this
     rule", and the write-up names the pendant nodes and the highest
     `cheapest_link_rkm` values.
8. **Threshold scan (a4) — descriptive, baseline only.** The edges are put in
   cost order. For each edge: the number of sets and the size of the largest
   set (nodes) when only the edges up to that cost are in the graph, and
   `joins_sets` — the edge joins two sets at that step, which makes it an edge
   of the minimum spanning forest (`in_mst`). **No threshold is chosen and no
   link is removed.** The scan shows at what cost each part of the network
   joins.
9. **Network groups and the cross-group links (f2).** `network_group`
   (Decision 17 point 8) stays a label: cross-group pairs stay links in the
   main graph, and each set lists the groups in it. In addition, **one second
   run on the baseline only**: the same graph without the pairs that have
   `cross_group == TRUE`, with the same metrics (columns with the suffix
   `_nocross`). `cross_group_dependent` = the node is a linchpin in the main
   graph and is **not** a linchpin in the second run.
10. **Variant repeat and comparison (e2).** The graph and the metrics of
    points 1–7 are built on `noghm`, `road15` and `road50` by the same rules.
    Each variant is compared with the baseline only:
    - `sets_same` — the nodes divide into the same sets.
    - `rho` — the Spearman rank correlation of `betweenness_norm` between the
      baseline and the variant, over the nodes with a value on both surfaces
      (tied values take their average rank).
    - `linchpin_retention` — the number of baseline linchpins that are
      linchpins on the variant ÷ the number of baseline linchpins.
    - **Label (fixed now): robust** if `sets_same` is true **and** `rho`
      **≥ 0.9** (`NET_COMPARE_ROBUST_MIN_RHO`) **and** `linchpin_retention`
      **≥ 2/3** (`NET_COMPARE_ROBUST_MIN_RETENTION`); otherwise **sensitive**.
      `noghm` gives the label for the gHM multiplier (Decision 14). The road
      value (Decision 15) is robust only if **both** `road15` and `road50`
      are robust. **The 0.9 and 2/3 limits are judgement values.**
    - Descriptive columns (no limits): the number of edges; the number of
      edges that trace to a different `pair_id` or are absent; whether the
      `cut_node` set is the same; the linchpins lost and gained, by name.
    - `stable_linchpin` (per node) = a linchpin on all four surfaces.
11. **Validation and QA, before the metrics are used.** The betweenness call
    is first run on a small graph with hand-computed values (a 5-node path:
    0, 3, 4, 3, 0; with a second set, to test the per-set normalisation). The
    script stops if: a reserve is in no node or in two nodes; the node count
    is not 47 or the reserve count is not 56; an edge weight is `NA`, zero or
    negative; the graph has a loop or a duplicate edge; an edge does not
    trace to one `pair_id`; the set sizes do not add up to the node count.
    It reports (no stop) whether the sets of the in-network graph are the
    sets that all 106 pairs give (33, 8 and 6 nodes).

**What was seen before this Decision (pre-registration, stated plainly):**
- **The path costs were seen.** The Week-10 tables hold the cost of every
  pair on every surface, and the Week-10 record names the median (577.3), the
  maximum (5,814.2) and the three highest pairs. The chat that drafted this
  Decision read those summary figures only; it did not open
  `tbl_12_lcp_qa.csv` or the paths layer (field names only).
- For that reason **no rule here uses a cost value**: no cost threshold
  (point 1), no cost limit for "isolated" (point 7), and the scan chooses
  nothing (point 8).
- **Known from geometry before any metric:** the 47 nodes; the sets that all
  106 pairs give (33, 8, 6 nodes); and that `north` (4 reserves) joins
  `central` only through Sariska. On the baseline, Sariska–Rajaji is in the
  network and Sariska–Corbett is not (P3), so Sariska–Rajaji is the only
  north–central link and Sariska has `betweenness_norm` of **at least 0.22**
  (4 × 28 = 112 of 496 node pairs) from the layout of the pairs alone. Point 9
  exists because of this.
- No network metric was computed before this Decision.

**Reason and sources:**
- **No threshold.** In a genetic study of six central-Indian protected areas,
  connectivity was affected by human settlements, road density and
  host-population tiger density, but not by the distance between populations;
  assignment tests indicated dispersal on the order of 650 km (Joshi et al.
  2013). Outside evidence gives no cost value above which movement stops, and
  a value chosen now is chosen after the costs were seen.
- **Merge, not a small weight.** Cost 0 means the two reserves are one
  habitat block. A weight must be positive in `igraph::betweenness()`, and
  zero weights can give an unlimited number of equal-length paths. A small
  fixed weight is arbitrary, and it gives betweenness to the reserve in the
  middle of a block from the polygon layout only.
- **Shortest-path betweenness.** It goes with least-cost paths: it identifies
  a minimal network like the one that least-cost-path mapping gives, while
  current-flow betweenness identifies a diffuse network with alternative
  linkages (Carroll et al. 2012).
- **Normalise by the set.** `igraph`'s `normalized = TRUE` divides by the
  pairs of the whole graph, so nodes in a small set get low values for the
  set size alone. The set-level divisor is the maximum that a node can have
  in its set (the centre of a star).
- **Threshold scan and spanning tree.** As the link threshold goes up, more
  nodes connect and the components become fewer, until the graph is connected
  (Brooks 2003, as used in the `grainscape` package). The minimum spanning
  tree is a guide to the relative importance of patches for connectivity
  (Urban & Keitt 2001).
- **Second run without cross-group links.** The mtDNA studies show the
  northern populations as distinct (Sharma et al. 2009, 2011), and the one
  north–central link comes from the 315 km gap cap (Decision 17 point 1). The
  `cross_group` flag was fixed in Decision 17, before the paths.
- **Repeat on the variants.** `in_network` changed for 4, 1 and 4 pairs on
  `noghm`, `road15` and `road50` (Week-10 record), and one changed link can
  move many shortest paths. The path-level label of Decision 18 does not show
  that the node ranks stay the same.

**Rejected:**
- *a2 — a threshold of 315 km × a reference resistance.* The reference
  resistance is a free value; at 1 the threshold (315 resistance-km) is below
  the median cost.
- *a3 — a threshold from pairs with documented movement.* Documented movement
  gives a lower limit only; few pairs; post-result.
- *b2 — 56 nodes with a small fixed weight; b3 — betweenness without
  weights.* See Reason; b3 ignores the cost.
- *c2 — `igraph` `normalized = TRUE`; c3 — raw value and rank only.*
- *k1 or k2 alone.* Top-3 alone hides whether the set divides without the
  node; articulation points alone give no order.
- *d1 alone* — probably names no reserve and gives no grade. *d3 — a cost
  limit for "isolated"* — the same problem as a2.
- *e1 — no repeat on the variants.*
- *f1 — labels only, with a caveat; f3 — a cross-group link is functional
  only if its cost is not above the highest within-group link cost.* The
  outcome of f3 was known (5,637 against 4,186 resistance-km).
- *Current-flow centrality* (Carroll et al. 2012; used for central India by
  Dutta et al. 2016) — not built (scope). **Limitation.**

**Limitations:**
- Shortest-path betweenness uses one route for each node pair; a small cost
  change can move it. Point 10 measures this for the three variants only.
- All node pairs of a set count the same, at any distance. Two reserves at
  opposite ends of a set add to the betweenness of the nodes between them,
  although a tiger is not likely to make that journey.
- The through-reserve rule (P3) gives betweenness to a reserve that lies
  between two others.
- Pilibhit and Dholpur-Karauli are not nodes (G1). Links through Nepal,
  Bhutan and Bangladesh are absent, so a border reserve can look more weakly
  connected than it is.
- Block members share one value: the metrics do not show which reserve of a
  block carries a link (`tbl_13_network_links.csv` does).
- The numbers 3, 0.9 and 2/3 are judgement values.

**Consequences:**
- `scripts/07`: STEP 11.1 builds the nodes, the link table and the graph →
  `tbl_13_network_links.csv` (every baseline in-network pair, with
  `link_role`, the two `node_id`s, `is_bridge`, `in_mst`); STEP 11.2 computes
  the metrics, the second run of point 9 and the scan of point 8 →
  `tbl_13_network_metrics.csv` (one row per reserve, 56) and
  `tbl_13_network_threshold_scan.csv` (one row per baseline edge); STEP 11.3
  repeats on the variants → `tbl_13_network_variant_comparison.csv` (one row
  per variant); STEP 11.4 is the QA of point 11.
- `R/00_config.R`: new `NET_*` settings.
- The plan's "56 nodes" becomes "47 nodes from 56 reserves"
  (`docs/project-plan.md`, Week 11).
- The Week-11 write-up reports the labels as fixed here, and compares the
  linchpins with Dutta et al. (2016) as description only (task 11.6).

This closes the **[Week 11] Functional-link rule** pending item (both parts:
the link rule and the variant repeat).

### Decision 20 — Road pinch points: roads, paths, crossing, site, pinch-point rule, variant comparison, publication
**Date:** 2026-10-10 (fixed **before** any road crossing is computed — see
"What was seen before this Decision")
**Choice:** Settings in `R/00_config.R` (`PINCH_*`). The Week-12 STEPs of
`scripts/07_connectivity.R` apply them. Fork codes as raised on 2026-10-10:
a1 + n1, b1 + k1, c1 + r1 + m1, d1 + t1, e2, p1 + q1 + g1, `fig_03`, a new
policy rule.

1. **Roads — the barrier-road cells of Decision 15 (a1, n1).**
   - The roads are the four barrier classes of Decision 15 (`motorway`,
     `trunk`, `primary`, `secondary`), with each `_link` ramp in its parent
     class. They are rasterised onto the surface grid with `touches = TRUE`
     and masked to the footprint. This is the rule of STEP 9.6, so the cells
     are the cells that the path engine saw.
   - Guard: the number of barrier-road cells must be the `n_road_cells` value
     in `tbl_11_resistance_qa.csv`. A difference stops the script.
   - Each barrier-road cell records `road_class_top`: the highest class that
     touches the cell, in the order motorway, trunk, primary, secondary. The
     class is a description. It is not a traffic volume and it is not in any
     rule (point 5).
   - The barrier-road cells come from geometry, so they are the same on all
     four surfaces.
   - No road name or reference (n1): the road layer holds `osm_id` and
     `highway` only. A name for a published pinch point comes from a hand
     check (task 12.9).
2. **Paths — every in-network path gets its crossings; the rule uses the
   edges (b1, k1).**
   - On each surface, crossings are computed for every in-network pair that
     has a path: `link_role` `edge` and `parallel` (Decision 19 point 3). On
     the baseline this is 76 paths (73 `edge` + 3 `parallel`). Each crossing
     carries its `pair_id`, `link_role` and `is_bridge`.
   - The pinch-point rule (point 5) counts `edge` links only.
   - A pair that is not in the network (Decision 17 point 2; 21 on the
     baseline) gets no crossing. A contiguous pair has no path and no
     crossing.
   - `lit_flag` (k1): a link in `PINCH_LIT_FLAG_PAIRS` is marked in every
     table. The list is the four links that the Limitations name as without
     literature support, or with a described barrier: Orang–Dampa,
     Anamalai–Srivilliputhur-Megamalai, Periyar–Kalakad-Mundanthurai and
     Sariska–Rajaji. No link is dropped. The list was fixed on 2026-10-04
     (Week-11 Limitations), before this Decision.
3. **One crossing — a run of barrier-road cells on the path (c1, r1).**
   - **The cell list of a path:** the path cells in order (the line
     vertices), and, for each knight step, the two middle cells that the step
     crosses, put between its two end cells in the order in which the
     straight line meets them. This is the crossed-cells rule of the engine
     (Decision 17 point 3). Orthogonal and diagonal steps add no cell.
   - **A crossing** is one unbroken run of barrier-road cells in that list.
     A run ends at the first cell that is not a barrier-road cell.
   - Each crossing records: `n_cells` (the length of the run), its
     `road_class_top` (the highest class in the run) and its cells. A path
     that goes along a road gives one long run; `n_cells` shows it.
   - **Reserve cells (r1):** every barrier-road cell on the path counts,
     also a cell in the footprint of the source reserve, the target reserve
     or a third reserve. `in_reserve_unit_ids` lists the reserves whose
     footprint cells the run holds (empty if none). No cell is excluded.
4. **Site — crossings at most 5 km apart are one place (m1).**
   - Two crossings are joined if the shortest distance between a cell centre
     of one and a cell centre of the other is **≤ 5 km**
     (`PINCH_SITE_MERGE_KM`). The crossings can be on one link or on
     different links. A **site** is a connected set of joined crossings.
   - The sites of a surface are made from all crossings of that surface
     (`edge` and `parallel` links).
   - Each site records: the number of crossings, `n_links` (different
     `pair_id`s), `n_edges` (different `pair_id`s with `link_role` `edge`),
     `n_bridges` (of those, with `is_bridge` true), its distinct road cells,
     `road_class_top`, `span_km` (the longest distance between two of its
     cell centres), `in_reserve_unit_ids` and `lit_flag` (true if every edge
     of the site has the flag; `lit_flag_any` if one or more has it).
   - The site position is the mean of its distinct cell centres. It is
     published only at the precision of point 7.
5. **Pinch point and order (d1, t1).** Three columns on each site, all fixed
   now:
   - `on_bridge` = `n_bridges` ≥ 1: a bridge edge (Decision 19 point 5)
     uses the site. Without that edge, its set divides.
   - `shared` = `n_edges` ≥ **2** (`PINCH_SHARED_MIN_EDGES`): two or more
     edges use the site.
   - `pinch_point` = `on_bridge` **or** `shared`.
   - `pinch_tier`: 1 = both flags; 2 = `on_bridge` only; 3 = `shared` only;
     `NA` if the site is not a pinch point. Sites in one tier have no order
     between them. Tables sort by tier, then by `site_id`.
   - The road class, the cost and the number of crossings are columns. They
     are not in the rule and they give no order.
   - No upper limit on the number of pinch points. The count is a result.
   - **Term (t1):** the label stays "pinch point". Here it means a place
     where a barrier road meets a modelled least-cost path that the network
     depends on or that edges share. It is **not** the pinch point of
     circuit-theory mapping, which is a narrow part of a corridor with high
     current flow. A least-cost path has no width. Each table header, the
     figure caption and the write-up say this.
6. **Variant repeat and comparison (e2).** Points 1–5 are applied to
   `noghm`, `road15` and `road50`, each with its own paths and its own edges
   and bridges (the Decision-19 graph of that surface). Each variant is
   compared with the baseline only:
   - Two sites are **near** if the shortest distance between a cell centre
     of one and a cell centre of the other is ≤ 5 km (`PINCH_COMPARE_D_KM`).
   - `share_base` = baseline pinch points with a variant pinch point near
     them ÷ baseline pinch points. `share_variant` = variant pinch points
     with a baseline pinch point near them ÷ variant pinch points.
   - **`site_overlap` = min(`share_base`, `share_variant`).**
   - **Label (fixed now): robust** if `site_overlap` **≥ 2/3**
     (`PINCH_COMPARE_ROBUST_MIN_OVERLAP`); otherwise **sensitive**. A
     surface with no pinch point gives no overlap value and the label
     "sensitive". `noghm` gives the label for the gHM multiplier (Decision
     14). The road value (Decision 15) is robust only if **both** `road15`
     and `road50` are robust.
   - Descriptive columns (no limits): the numbers of crossings, sites and
     pinch points, and the pinch points by tier, on each surface; the same
     overlap at 10 km; the same overlap for all sites; the baseline
     tier-1 and tier-2 pinch points with no variant pinch point near them,
     by link.
7. **Publication (p1, q1, g1, `fig_03`, policy).**
   - **Position (p1):** a committed table, a figure, a caption and a popup
     give a crossing or a site as a **10 km grid cell** with its state and
     district. The 10 km grid is the analysis grid aggregated by 10
     (`PINCH_PUBLISH_GRID_M`), from the top-left corner of that grid. The
     state is from `boundary_states_7755.gpkg`; the district is from the
     DataMeet Census-2011 layer (641 districts, from before later district
     changes). The 1 km cells go only into a gitignored layer under
     `data/processed/`. This applies to `tbl_14_*` too: `outputs/tables/` is
     committed.
   - **Tables (q1):** `tbl_03_<slug>.csv`, one row per network reserve (56):
     the network results from `tbl_13_network_metrics.csv` (node, set,
     linchpin with `cross_group_dependent` and `stable_linchpin`, cut node,
     pendant, cheapest link) and the pinch-point counts on the edges of the
     node, by tier. `tbl_03b_<slug>.csv`, one row per baseline pinch point:
     tier, the two flags, `n_edges`, `n_bridges`, the links by name,
     `road_class_top`, `in_reserve_unit_ids`, `lit_flag`, state, district,
     10 km cell, and the variant result of the site.
   - **Figure (g1):** `fig_03_<slug>.png`, a map: the nodes by flag
     (linchpin with its two flags, cut node, pendant); the 73 baseline edge
     paths as modelled lines, with the bridges marked; the baseline pinch
     points at their 10 km cell, by tier. The caption says that the paths
     are modelled and not observed movement, that the surface is India-only,
     what a pinch point is here (point 5), and the limits of the linchpin
     labels.
   - **Figure number:** `fig_03` (author choice; the plan named `fig_04`
     while `fig_03` was not in use).
   - **Path lines:** the lines are drawn in the static figure only, at
     national scale. A published path layer that a reader can zoom or
     download (the Stage-4 Leaflet maps) needs its own rule first (pending
     item below).
   - **Policy:** `docs/sensitive-data-policy.md` §3 gets one rule for
     modelled paths and crossings. `assert_no_raw_points()` stops all point
     geometry, so a published site is a table row or a grid cell, never a
     point layer. The publish check for the 10 km rule is written with the
     publishable table (task 12.7).

**What was seen before this Decision (pre-registration, stated plainly):**
- **The network results were seen** (Week 11): the linchpin, cut and pendant
  nodes, the number of bridges and the bridge list on the console, the path
  costs, the length/gap ratios, the reserves that paths cross, and the NTCA
  overlap. The author knows which links are bridges.
- **Road figures seen:** the Decision-15 data check (barrier-road cells are
  17.5 % of India's cells; cells by class; 2,711 reserve cells touched) and
  the Week-9 QA (535,592 barrier-road cells in the footprint). The field
  names of the road layer (`osm_id`, `highway`).
- **The Decision-18 result was seen:** the routes are robust on all three
  variants. A robust label in point 6 is therefore the more likely result.
  The 2/3 limit is the Decision-19 value; it was not set from a crossing.
- **Not seen by anyone:** a road crossing. No crossing is computed, and the
  paths layer and the `tbl_12_*` and `tbl_13_*` tables hold no road field.
- **Not seen by the chat that drafted this Decision:** the path geometry and
  the `tbl_12_*` and `tbl_13_*` files (the documents only).
- **The author did not look at the paths on a map that shows roads** (stated
  2026-10-10).
- Result: `on_bridge` is post-result for **which links** it marks and
  pre-result for **where** the sites are. `shared`, the site positions, the
  counts and the variant label are pre-result. No rule uses a crossing
  count, a cost or a road class.

**Reason and sources:**
- **What the term means in the literature.** A pinch point is a bottleneck
  where movement is funnelled inside a linkage, and a small loss of area
  there can cut the linkage. The mapping method uses current flow from
  circuit theory inside least-cost corridors (WHCWG 2013; McRae 2012). For
  16 protected areas in central India, pinch points are parts of the
  linkages where movement is restricted by poor habitat, transport networks,
  human habitation, or a mix (Dutta et al. 2016). This project has paths,
  not corridors, and no circuit run, so point 5 defines the term for this
  project and states the difference. A circuit-theory check stays a pending
  item (after Stage 3).
- **Path × highway is an established step.** Factorial least-cost paths were
  intersected with highways and the crossings ranked by intensity, with
  movement data as a check (Cushman et al. 2013). In India, a count of the
  linear projects that pass through tiger corridors (399 proposed projects in
  the Central Indian and Eastern Ghats area) is the unit that planning uses
  (Pariwakam et al. 2018, from news reports). This project has no movement
  data, so the crossings are not validated.
- **Roads are almost everywhere.** 57 % of the area of the tiger
  conservation landscapes is in the road-effect zone (Carter et al. 2020),
  and 17.5 % of India's 1 km cells are barrier-road cells (Decision 15). "A
  link crosses a road" is therefore true for almost every link. The result
  is where, how many, and which crossings the network depends on — hence the
  two flags.
- **Cells, not line intersection.** The engine saw the roads as cells
  (`touches = TRUE`), and a path is a line through 1 km cell centres. A
  line-on-line intersection with an OSM road has an error of about 1 km, and
  a path beside a road can cross the line many times. A run of cells is the
  crossing in the terms of the surface.
- **`on_bridge`.** A bridge is the only connection between two parts of a
  set (Decision 19 point 5). A barrier road on that path is a place where
  the modelled network has no second route. This ties the pinch point to
  the meaning in the literature (a small loss cuts the connection) without a
  corridor width.
- **`shared`.** Two or more edges through one place is the path-based
  analogue of a high corridor intensity in Cushman et al. (2013).
- **No order by class.** Decision 15 gave one barrier value to the four
  classes, because the OSM class is only an approximate traffic proxy in
  India. An order by class would claim more than Decision 15 did.
- **5 km.** The Decision-18 route distance (about one resident female
  home-range radius). Two crossings inside that distance are one place for a
  tiger and for a mitigation structure.
- **Repeat on the variants.** `road15` and `road50` change the cost of each
  road cell. Decision 18 found the routes robust at 5 km, but it did not
  test the road crossings, and the bridges can differ by surface (the cut
  nodes differ on `noghm` and `road50`).
- **10 km.** A crossing is a modelled place on a public road, not a tiger
  location. The reason for the coarse position is false precision: the path
  position depends on judgement values (Decisions 14–16), and a 1 km "tiger
  crossing" on a public map can be read as an observed place. 10 km is the
  Decision-11 approach-zone width and two times the merge distance.

**Judgement values:** 5 km (site merge and variant distance), 2 edges
(`shared`), 2/3 (robust limit), 10 km (published position).

**Rejected:**
- *a2 — motorway and trunk only; a3 — all four classes for the crossings,
  motorway and trunk only for pinch points.* The engine did not separate the
  classes (Decision 15).
- *n2 — a new pull of `ref` and `name`.* A second road read with a
  different field set; names come from the hand check.
- *b2 — the 73 edges only; b3 — the 13 bridges only; b4 — all 97 paths.* b3
  cannot give `shared`; b4 counts paths that are not links.
- *k2 — no flag.*
- *c2 — line-on-line intersection.* See Reason.
- *r2 — no exit and entry cells; r3 — no reserve cell.* A road at a reserve
  edge is a real crossing for an animal that leaves the reserve; the flag
  keeps the information.
- *m2 — no merge; m3 — 10 km.* m2 makes one road section into many sites;
  10 km has no basis in the earlier Decisions as a "same place" distance.
- *d2 — `on_bridge` only; d3 — `shared` only; d4 — order by road class; d5 —
  order by edge betweenness.* d5 needs a new network metric after the
  network results were seen.
- *t2 — the term "priority crossing".*
- *e1 — baseline only; e3 — the two road variants only.*
- *p2 — state and district only; p3 — the 1 km cell.*
- *q2 — one table; g2 — a schematic graph with no map.*

**Limitations:**
- A crossing is a modelled place. No tiger movement data checks it.
- The path is one route of minimum cost. A tiger can cross the same road at
  a different place; a path a few cells away gives a different site.
- `on_bridge` comes from the geometry rules of Decisions 17 and 19 (no cost
  threshold). A bridge can be a link with no literature support; `lit_flag`
  marks the four known cases.
- Joined crossings can make a chain: a path beside a road gives a long
  site. `span_km` shows it; no upper limit is set.
- Roads inside a block of contiguous reserves get no crossing (a contiguous
  pair has no path). Roads inside one reserve are counted only on the exit,
  entry or through cells of a path.
- Crossing structures are not mapped (Decision 15 point 6): a pinch point
  can be at a place that has an underpass.
- Railways, canals and power lines are not in the road layer.
- The OSM class is not a traffic volume, and no road name is in the data.
- The district layer is from the 2011 Census.
- The numbers 5 km, 2, 2/3 and 10 km are judgement values.

**Consequences:**
- `scripts/07`: STEP 12.1 builds the barrier-road cells with their class
  (the guard of point 1); STEP 12.2 computes the baseline crossings →
  `tbl_14_road_crossings.csv`; STEP 12.3 builds the sites and applies point
  5 → `tbl_14_pinch_points.csv`; STEP 12.4 repeats on the variants →
  `tbl_14_pinch_variant_comparison.csv` (now required); STEP 12.5 is the QA
  → `tbl_14_pinch_qa.csv`; STEP 12.6 writes `tbl_03` and `tbl_03b`; STEP
  12.7 draws `fig_03`.
- QA (STEP 12.5) checks, with a stop on any failure: the functions on a
  hand-made case (a known path, a known road, a known count, one knight
  step over a road cell); each crossing cell is in the cell list of its
  path and is a barrier-road cell; each barrier-road cell in a cell list is
  in one crossing only; no crossing for a contiguous pair or a pair that is
  not in the network; each crossing is in one site only; two sites are more
  than 5 km apart; the counts per link and per site add up to the table
  totals; no committed table holds a 1 km position.
- `R/00_config.R`: new `PINCH_*` settings.
- `docs/sensitive-data-policy.md`: one new rule in §3.
- `docs/project-plan.md`: task 12.5 is required; `fig_04` becomes `fig_03`
  in the Week-12 text.
- The Week-12 write-up reports the labels as fixed here.

This closes the **[Week 12] Pinch-point rule** pending item.

### Decision 21 — Occurrence cleaning: record source, rule steps, uncertainty sets, obscured set, presence cells, background, minimum sample
**Date:** 2026-10-11 (fixed **before** any record is cleaned and before any
cleaned count is made — see "What was seen before this Decision")
**Choice:** Settings in `R/00_config.R` (`OCC_*`). The Stage-3 script
(`scripts/08_<verb_object>.R`, named in task 13.2) applies them. Fork codes
as raised on 2026-10-11: a3, n1, b1, c2, z2, o2, e1, g3, h2, k2. *(c2
replaces c1 by the amendment of 2026-10-11, made after the names stage of
STEP 13.1 and before any count — see "Amendment 1".)*

1. **Record source — the two GBIF files are read again.**
   - The rule needs `occurrenceStatus` and `issue` for the tiger records.
     The interim tiger layer (`occ_tiger_gbif_raw_7755.gpkg`) holds eight
     fields and not these two. The interim background layer
     (`effort_background_tgs_7755.gpkg`) holds `yr` only. Stage 3 therefore
     reads the two SIMPLE_CSV files of the Week-2 downloads again
     (`data/raw/gbif/`, `data/raw/gbif_background/`). There is no new
     download, and the two DOIs do not change.
   - **Entry state (step 0).** The `scripts/01` filter is repeated: a record
     with two coordinates, inside the India polygon
     (`boundary_india_national_7755.gpkg`). For the background also: year
     2006 to 2022, and not the tiger (`speciesKey`).
   - **Guard.** Tiger: the set of `gbifID` values of the entry state must be
     the set in the interim layer. Background: the number of records must be
     the number in the interim layer (that layer has no identifier). A
     difference stops the script.
   - **Fields that the rule uses:** `gbifID`, `datasetKey`,
     `occurrenceStatus`, `basisOfRecord`, `year`, `decimalLatitude`,
     `decimalLongitude`, `coordinateUncertaintyInMeters` and `issue`; for
     the background also `speciesKey`, `order` and `family` (task 13.4). The
     GBIF documentation lists each of them in the simple format. Task 13.2
     reads the header line of each file. If a field is not there, this
     Decision gets a dated amendment before any record is removed.
2. **Rule steps, in one fixed order (`OCC_STEP_ORDER`).** The two sets get
   the same steps, the same values and the same order (point 7). Each
   record is counted at the first step that removes it.

   | Step | Name | A record stays if | Fork |
   |---|---|---|---|
   | 1 | `status` | `occurrenceStatus` is `PRESENT` | c |
   | 2 | `basis` | `basisOfRecord` is `HUMAN_OBSERVATION`, `MACHINE_OBSERVATION`, `OBSERVATION`, `OCCURRENCE` or `MATERIAL_SAMPLE` | c2 (amended) |
   | 3 | `year` | `year` is 2006 to 2022 | b1 |
   | 4 | `coord_flags` | `issue` holds no flag of `OCC_ISSUE_REMOVE`; the two coordinates are not both zero and not equal | z2 |
   | 5 | `uncert_na` | `coordinateUncertaintyInMeters` has a value above zero | n1 |
   | 6 | `uncert` | the value is ≤ 5,000 m (point 3) | a3 |
   | 7 | `centroid` | the record is more than 1 km from the centroid of India, of each state and of each district | z2 |
   | 8 | `zoo` | the record is more than 1 km from each OpenStreetMap zoo | z2 |
   | 9 | `footprint` | the 1 km cell of the record is a complete-case cell of the covariate stack | fixed |

   - **Step 1.** `ABSENT` is removed. A record with no value is removed too:
     a missing value does not show a presence. The table counts the two
     cases in two columns.
   - **Step 2 (c2; amended 2026-10-11, was c1).** The kept types are
     `OCC_BASIS_KEEP`. All other record types are removed: preserved, fossil
     and living specimens, material citations, and a missing value. Before
     the amendment, material samples, `OBSERVATION` and `OCCURRENCE` were
     removed too. The two files hold no `OBSERVATION` and no `OCCURRENCE`
     record (names stage), so the amendment changes the result for material
     samples only.
   - **Step 3 (b1).** The limits are `BASELINE_YEAR` and `CURRENT_YEAR`,
     the bounds of the background download. A record with no year is
     removed. For the background this step must remove no record (the
     download and step 0 gave the window); the count is a check.
   - **Step 4.** `OCC_ISSUE_REMOVE` is the list of GBIF flags that say that
     a coordinate is wrong, or that GBIF changed it on an assumption:
     `ZERO_COORDINATE`, `COORDINATE_OUT_OF_RANGE`, `COORDINATE_INVALID`,
     `COUNTRY_COORDINATE_MISMATCH`, `PRESUMED_SWAPPED_COORDINATE`,
     `PRESUMED_NEGATED_LATITUDE`, `PRESUMED_NEGATED_LONGITUDE`,
     `COORDINATE_REPROJECTION_FAILED`, `COORDINATE_REPROJECTION_SUSPICIOUS`
     and `COORDINATE_UNCERTAINTY_METERS_INVALID`. The flags of
     `OCC_ISSUE_REPORT` are counted and remove no record:
     `GEODETIC_DATUM_ASSUMED_WGS84`, `GEODETIC_DATUM_INVALID`,
     `COORDINATE_ROUNDED`, `COORDINATE_REPROJECTED` and
     `COORDINATE_PRECISION_INVALID`. Task 13.2 lists the flag names that are
     in the two files (names and counts); a different spelling gets a dated
     note here before any record is removed.
   - **Step 4, the two coordinate tests.** A record at 0°, 0°, and a record
     with latitude equal to longitude, cannot be inside India (latitude is
     below 38° and longitude is above 68°). Step 0 has removed them. The two
     tests stay as checks and must count zero.
   - **Step 5 (n1).** A record with no uncertainty value, or with a value
     of zero or below, is removed. The number of decimal places of a
     coordinate is not used.
   - **Step 7.** The centroid is the geometric centroid of the polygon in
     EPSG:7755 (`sf::st_centroid()`), for three layers
     (`OCC_CENTROID_LEVELS`): India (1), the states
     (`boundary_states_7755.gpkg`, 36) and the DataMeet Census-2011
     districts (641). The distance is `OCC_CENTROID_DIST_M` = `GRID_CELL_M`.
   - **Step 8.** A zoo is an OpenStreetMap feature with `tourism` = `zoo`,
     a point or an area, in the cached Geofabrik India file of Week 2
     (`data/raw/osm/geofabrik_cache/`; no new download). The distance is
     from the record to the feature (zero inside an area), and the limit is
     `OCC_ZOO_DIST_M` = `GRID_CELL_M`. If the read gives no zoo feature, the
     script stops: a read that failed is not "no zoo".
   - **Step 9.** The cell is the cell of `cov_stack_1km_7755.tif` that
     holds the record. The record stays if that cell has a value in each
     band (the Decision-10 common mask). This step also removes a record
     that is inside the India polygon on a cell with its centre outside.
3. **Two uncertainty sets (a3).** Each record that passes all nine steps
   gets `uncert_set`:
   - `1km`: the value is ≤ 1,000 m (`OCC_UNCERT_MAIN_M` = `GRID_CELL_M`).
   - `5km`: the value is above 1,000 m and ≤ 5,000 m (`OCC_UNCERT_WIDE_M`,
     the Decision-18 distance).
   - **The 1 km set** is the records with `1km`. It is the main set.
   - **The 5 km set** is the records with `1km` or `5km`. It is for one
     sensitivity run (point 9). It does not replace the main set
     (point 8).
4. **Obscured set (o2).** No step removes a record because it is obscured;
   step 6 removes it because its uncertainty is above the limit. One
   labelled set is kept from the records that step 6 removes:
   - A record is in the obscured set if it passed steps 1 to 5, its
     `datasetKey` is the iNaturalist dataset (`OCC_INAT_DATASET_KEY`,
     "iNaturalist Research-grade Observations"), and its uncertainty is
     ≥ 25,000 m (`OCC_OBSCURED_MIN_UNCERT_M`).
   - Each record gets the 0.2° cell of its public coordinates
     (`OCC_OBSCURED_CELL_DEG`): the cell with its south-west corner at the
     coordinates rounded down to a multiple of 0.2°. iNaturalist puts the
     public point in the cell that holds the true position.
   - Steps 7 to 9 are not applied: the public point is a random point in
     the cell, so a distance of 1 km from it has no meaning.
   - **The obscured set is never a 1 km presence.** Its uses are an input
     to Decision 22 (effort) and to the Decision of point 8.
   - The script counts the iNaturalist records that step 6 removes with an
     uncertainty below 25,000 m. They are in no set.
   - The same rule is applied to the background, for the count only.
5. **Presence cells (e1).** The unit of the model is the 1 km cell, not the
   record.
   - A presence cell of a set is a complete-case cell with one or more
     records of that set. `n_cells_1km` and `n_cells_5km` are the two
     counts.
   - The number of records in a cell is kept as a count. It is not a
     weight.
   - There is no thinning by distance (`OCC_THIN_RULE` = `one_per_cell`).
   - The clean layer keeps each record that passed the nine steps, with its
     cell number, so that the count per cell and per year stays available.
6. **Tool (z2, not z3).** Base `sf`, `terra` and `dplyr` rules. The
   `CoordinateCleaner` package is not used. The zoo layer needs one more
   read of the cached OpenStreetMap file with `osmextract`. No new package.
7. **Background (g3).** The Mammalia background goes through steps 0 to 9,
   points 3 and 5, with the same values and the same order.
   - **1 km background:** the complete-case cells with one or more
     background records with `uncert_set` = `1km`, from all datasets.
   - **5 km background:** the same with `1km` or `5km`.
   - **Matched 1 km background:** the 1 km background, with only the
     records of a dataset that holds one or more records of the tiger 1 km
     set (`OCC_BG_MATCH_MIN_TIGER` = 1; the match is on `datasetKey`). Each
     background record gets `ds_match` (true or false).
   - No matched 5 km background is built.
   - The attrition table gives each step for the two sets, for all records
     and by dataset.
   - The pending item "target-group scope" (which mammals) does not change.
     Task 13.4 gives its evidence.
8. **Minimum number of presence cells (h2) and what changes (k2).** The
   test value is `n_cells_1km` of the tiger records. Fixed now:

   | `n_cells_1km` | Outcome for Week 14 |
   |---|---|
   | below 25 (`OCC_MIN_CELLS_MODEL`) | **No 1 km suitability model.** Week 14 starts with a numbered Decision between (i) no suitability model — Stage 3 gives the effort result — and (ii) a model at a coarser grain. The inputs that (ii) can use are the 5 km set and the obscured set. A 1 km model on the 5 km set is not an option |
   | 25 to 79 | **A reduced model.** The feature classes are linear and quadratic at most (`OCC_REDUCED_MAX_CLASSES` = `lq`). Each output of the model says that the sample is small. The other settings are a Week-14 Decision; it can be more strict, not less |
   | 80 or more (`OCC_MIN_CELLS_FULL`) | **The planned model** (`maxnet`; the settings are a Week-14 Decision) |

   - Task 13.3 compares the count with the two limits and states the
     outcome. The outcome does not change after that.
   - No minimum is fixed here for a background set. The Week-14 Decision
     fixes one, and it must say that the background counts were seen.
9. **The model sets for Week 14 (`OCC_MODEL_SETS`).** One main set and two
   sensitivity sets. Each sensitivity set changes one choice:

   | Set | Tiger cells | Background | Tests |
   |---|---|---|---|
   | `main` | 1 km set | 1 km background, all datasets | — |
   | `uncert5km` | 5 km set | 5 km background, all datasets | the uncertainty limit (a3) |
   | `matched` | 1 km set | matched 1 km background | the observer group (g3) |

   - The two sensitivity sets are run only if the main model is run
     (point 8).
   - The comparison rule and its labels are a Week-14 Decision, fixed
     before a model is fitted.
10. **Sensitivity and publication.**
    - The clean tiger layer holds precise positions (policy tier T2). The
      obscured set is tier T1. The layers stay under `data/` (gitignored).
    - A `tbl_15_*` table holds counts. It holds no coordinate, no cell
      number and no 0.2° cell.
    - The console text that goes to a chat holds counts and field names
      only.
    - A published form of a tiger-record surface is Decision 22, point (g).

**What was seen before this Decision (pre-registration, stated plainly):**
- **In the documents:** 4,606 tiger records inside India (93 % of the pull);
  a median coordinate uncertainty of about 30 km; years 1840 to 2026;
  39,057 background records inside India (75 % of the pull), 2006 to 2022;
  the Phase-1 result (about 116 clean baseline points for 7 reserves, with
  a different rule).
- **By the author, on the Week-2 console (`scripts/01`, Blocks 2 and 3):**
  the record-type mix of the tiger records, the number with no uncertainty
  value, the 90th percentile of the uncertainty, and the background records
  per year. The author stated on 2026-10-11 that these values are not
  remembered, and that the raw layers were not opened and the records were
  not looked at on a map after Week 2. Forks a, n and c are
  therefore post-seen in principle for the author.
- **By the chat that drafted this Decision:** the documents and the scripts
  only. No data file, no field value, and none of the three Week-2 values
  above.
- **Research that tells the direction of a result (2026-10-11):**
  iNaturalist obscures the tiger, and an obscured record has an uncertainty
  of about 28 to 31 km in India. Step 6 will therefore remove most or all
  iNaturalist tiger records. This agrees with the 30 km median. It is an
  inference; no record was checked.
- **The Phase-1 count is above the two limits of point 8.** The limits are
  from the literature and from the `maxnet` default (see Reason). They were
  not set from a count of this project.
- **The choices.** The chat gave one recommended option for each fork. The
  author took it for each fork but one: the chat recommended a1 (one limit
  of 1,000 m), and the author chose a3. a3 adds the 5 km set and takes no
  record out of the main set. *(This was the state when the Decision was
  recorded. For fork c, see "Amendment 1".)*
- **Not seen by anyone:** a cleaned count, the datasets of the tiger
  records, the GBIF flags in the two files, the number of obscured records,
  and a zoo layer.

**Amendment 1 — 2026-10-11, after the names stage of STEP 13.1, before any
count:**
- **What was run.** `scripts/08_prepare_occurrences.R` with `RAW_STAGE` =
  `names`, on the project machine. It read the two GBIF files and printed
  field names and distinct values. It printed no count of records, wrote no
  file and removed no record.
- **What the names showed.**
  - Each file has the 50 fields of the GBIF simple format. Each field of
    point 1 is there.
  - `occurrenceStatus` holds only `PRESENT` in the two files. Step 1 will
    remove no record.
  - No flag of `OCC_ISSUE_REMOVE` is in the two files. The flag part of
    step 4 will remove no record.
  - `basisOfRecord` holds five types in each file: `HUMAN_OBSERVATION`,
    `MACHINE_OBSERVATION`, `MATERIAL_CITATION`, `MATERIAL_SAMPLE` and
    `PRESERVED_SPECIMEN`.
  - The iNaturalist dataset key is in the two files. The tiger file has one
    `speciesKey`.
- **Flags with no rule that the stage marked for review — no amendment.**
  `COUNTRY_DERIVED_FROM_COORDINATES`, `CONTINENT_DERIVED_FROM_COORDINATES`
  and `COUNTRY_INVALID` (background only) are about the country and the
  continent text. They do not say that a coordinate is wrong, and step 0
  uses the India polygon.
- **Date flags — no amendment (y1).** `RECORDED_DATE_MISMATCH` and
  `RECORDED_DATE_INVALID` are in the two files, and step 3 uses `year`.
  Step 3 stays as it is: the `year` field of GBIF, for the two sets, which
  is the field of the 2006–2022 window of the background download. For a
  mismatch, GBIF keeps the part of the date on which the fields agree; the
  examples of its page keep the year. A conflict in the year is not in
  those examples (not verified). The rejected option was y2: also remove a
  record with one of the two flags.
- **Record types — c2 replaces c1 (the author's choice).** Step 2 now
  keeps `OBSERVATION`, `OCCURRENCE` and `MATERIAL_SAMPLE` too.
  - What was seen when the choice was made: the five type names above, and
    a flag for nucleotide sequences in the tiger file. The chat pointed to
    the two facts and proposed no change.
  - Not seen: a count. The number of material samples is not known.
  - Direction, stated plainly: c2 keeps more records than c1 and never
    fewer, so `n_cells_1km` with c2 is equal to or above its value with c1.
    The limits of point 8 do not change. The research of this Decision had
    shown that the clean set is probably small.
  - The rule is the same for the background.

**Amendment 2 — 2026-10-11, after the raw counts of STEP 13.1 (task 13.2),
before any clean count:**
- **What was seen.** The raw counts of `tbl_15_occ_raw_counts.csv` (the
  change log of 2026-10-11 gives them). By the chat: the GBIF registry
  entries of three tiger datasets, and the GBIF API counts of one of them.
- **The fact.** The dataset "Camera trap database of Tiger from Rajaji
  National Park" (305 records, all machine observations) says that its
  positions were degraded for security. None of its records has an
  uncertainty value, so step 5 removes all of them. A dataset can also
  degrade its positions and give a small uncertainty value. No rule step
  finds that.
- **Addition (v1; a QA check, not a rule step).** For each dataset that
  gives one or more records to the 1 km set or to the 5 km set, the script
  reads the GBIF description of the dataset and looks for words about
  degraded, generalised or obscured positions. A hit stops the script
  before the clean layers are written, and the author decides: keep the
  dataset, or a further amendment. The word list and the way to record a
  decision are process choices of task 13.3.
- **Direction.** The check removes no record. It can only stop the script.
  A later removal of a dataset is a post-result amendment, and the record
  must say so.
- **Rejected:** v2 — no check.

**Outcome of the dataset check (Amendment 2) — 2026-10-17:**
- **First run of STEP 13.2:** the check stopped on one dataset, so nothing
  of STEP 13.2 was written. The dataset is "Mammal occurrence in rainforest
  fragments of the Valparai Plateau and Anamalai Tiger Reserve, Western
  Ghats, India (2005-06)" (`3732112e-848c-4fcc-b62d-e5acb9d12099`). It gives
  5 records to the 1 km set and none to the 5 km set only.
- **The word:** "approximat", in this method sentence of the GBIF entry:
  "Geographic location was chosen as the approximate midpoint of line
  transects or, in the case of opportunistic surveys, approximately based
  on name of locality or place with a coordinate uncertainty in metres
  assigned to it."
- **The author's choice: k1 — keep the dataset** (in `OCC_DATASET_CLEARED`).
  Each record has a coordinate uncertainty, and step 6 uses that value; the
  word describes the method and does not say that a position was degraded.
- **What was seen when the choice was made:** the attrition, the three sets
  and the outcome of point 8 (the console of the first run prints them
  before the check).
- **The choice does not change the outcome of point 8.** With k2 (remove
  the dataset; rejected), `n_cells_1km` would be 12 to 17, which is below
  25 as is 17.
- **The other five datasets with a kept record** had no word of the list.

**Outcome of point 8 (task 13.3, `scripts/08` STEP 13.2, 2026-10-17):**
- `n_cells_1km` = **17** (45 records), which is below `OCC_MIN_CELLS_MODEL`
  (25). The outcome is **`no_1km_model`**: no suitability model at 1 km.
- By point 8, Week 14 starts with a numbered Decision between (i) no
  suitability model — Stage 3 gives the effort result — and (ii) a model at
  a coarser grain, with the 5 km set and the obscured set as the inputs
  that it can use. A 1 km model on the 5 km set is not an option.
- By point 9, the sensitivity sets `uncert5km` and `matched` are run only
  with a main model, so they are not run.
- The outcome does not change after this run (point 8). It is locked in
  `R/00_config.R` (`OCC_POINT8_OUTCOME`, process choice r1, 2026-10-17):
  `scripts/08` stops if a later run gives another outcome.

**Outcome of the dataset check on the background (task 13.4, `scripts/08`
STEP 13.3) — 2026-10-17:**
- **First run of STEP 13.3:** the check (process choice d1: the same check,
  word list and cleared list as for the tiger) stopped on five background
  datasets, so nothing of STEP 13.3 was written. In each, the word is not
  about a degraded position:

  | Dataset (key) | Background 1 km / above 1 km | The word, in context |
  |---|---|---|
  | Bird surveys and leopard study, Anamalai Hills (1999–2020) (`b045f965-…`) | 3,201 / 0 | "degraded forest fragments" (the habitat); "approximately 2,223 point-count surveys"; positions from a place name "with a coordinate uncertainty in metres assigned to it"; the position is "the start point of line transects" |
  | Hornbill-survey line transects, Western Ghats (2005–06) (`7528e073-…`) | 146 / 10 | "the approximate starting point or midpoint of each line transect based on GPS records"; the uncertainty is "based on transect length and positional error" |
  | Fruiting trees and their visitors, Anamalai Hills (`cf973c89-…`) | 111 / 0 | "approximately 3000 mm annual rainfall"; no sentence about the positions |
  | India Roadkill Monitoring Project (`f334ae5e-…`) | 97 / 0 | "ecologically sensitive landscapes"; also "Coordinate uncertainty values recorded as 0 m were adjusted to either 30 m or 100 m" |
  | Bird-survey transects, Dampa Tiger Reserve landscape (2014) (`f896ef0c-…`) | 26 / 0 | "the approximate midpoint of line transects … with a coordinate uncertainty in metres assigned to it" (the sentence of the k1 dataset) |

- **The author's choice: e1 — keep all five** (in `OCC_DATASET_CLEARED`,
  each with the date and its reason).
- **The roadkill note:** in GBIF an uncertainty of 0 often means "not
  known", and step 5 removes it. This publisher replaced 0 with 30 m or
  100 m, so such a record passes steps 5 and 6 with a value that the
  publisher assigned.
- **What was seen when the choice was made:** the background attrition, the
  four background sets and the taxa (the console of the first run prints
  them before the check).
- **Effect:** the five datasets give 3,581 of the 20,905 records of the
  1 km background (17 %). None of them is a matched dataset. The tiger
  outcome does not change.
- **Rejected:** e2 — clear some and remove the others (a post-result
  amendment).
- **Second run:** six hits (the k1 dataset is in the background too), all
  cleared; the outputs were written.

**Reason and sources:**
- **1,000 m.** The covariates are on a 1 km grid. With an uncertainty of
  1 km or less, the true position is in the cell of the record or in a
  cell next to it. In a simulation study, model performance fell with
  more position error and with a coarser grain, and a coarser grain did
  not make up for the error (Gábor et al. 2022). The limit is the grid
  size, not a value from the data.
- **5,000 m as a second set.** It is the Decision-18 distance (about one
  home-range radius of a resident female). A record can then be five cells
  from its covariates, so the set is for a sensitivity run only.
- **No value = removed.** A missing uncertainty does not show a precise
  position, and the decimal places of a coordinate show the format, not
  the accuracy.
- **2006 to 2022.** The background has no record outside this window, so a
  different window for the tiger gives the two sets a different time
  bias. The covariates are from 2021 and 2022; a record from 1840 is from a
  different land cover.
- **Record types.** A specimen has the position of a collection place or a
  museum, and often an old date. A material citation is a record from a
  publication. A material sample can be scat or hair with a true field
  position. By Amendment 1 it stays, and it goes through the same steps for
  uncertainty, centroid and zoo as each other record. `OBSERVATION` and
  `OCCURRENCE` give no method; they stay by c2 and are not in the files.
  *(Before Amendment 1: these three types were removed, because the type
  alone does not show the method.)*
- **Flags.** The Week-2 downloads used `hasGeospatialIssue = FALSE`, so
  some flags of the list are expected to count zero (not verified which).
  The flags for an assumed datum are not removed: they are on a large part
  of all GBIF records (as far as known), and the shift is probably small
  against 1 km (not measured for India).
- **Centroid and zoo.** Records are often given the centre of a country or
  a province, or the place of an institution, and automated tests for
  these are standard (Zizka et al. 2019). This Decision uses the same
  ideas with layers that are on disk. A zoo record is a true record of a
  tiger and a false record of habitat. A captive record on iNaturalist is
  not research grade, so the iNaturalist dataset on GBIF does not have it
  (as far as known; not verified).
- **Obscured records.** iNaturalist gives an obscured record a random
  point in a cell of a 0.2° grid and sets the public accuracy to the
  diagonal of the cell; one GBIF example has 29,458 m. The diagonal is
  about 28.4 km at 37° N and about 31.3 km at 7° N (computed for this
  Decision). 25,000 m is below the smallest value in India and above the
  5 km limit. The GBIF simple format has no field that says "obscured", so
  the set is found from the dataset and the uncertainty.
- **One presence per cell, no thinning.** Two records in one cell give the
  model the same covariates. The background, not a thinning distance,
  corrects the effort bias (Decision 5). A thinning distance on top of it
  would correct the bias two times and make a small set smaller.
- **Background by the same rule, with a matched set.** The target-group
  method needs a background with the bias of the presence records, from
  species "observed by similar methods" (Phillips et al. 2009). The same
  rule can give two different observer groups: most mammals are not
  obscured on iNaturalist and pass step 6, and the tiger does not. The
  matched set keeps only the datasets that also gave a clean tiger record.
  It is the nearer set to "similar methods", and it can be small, so it is
  the sensitivity set and not the main set.
- **25 and 80.** For simulated species in a real study area, the minimum
  number of records for an accurate model was 14 for a narrow-ranged and
  25 for a widespread species (van Proosdij et al. 2016); 25 is the higher
  value. `maxnet` chooses its default feature classes from the number of
  presences: linear below 10, plus quadratic below 15, plus hinge below
  80, plus product from 80 (`maxnet.formula()`, read 2026-10-11). 80 is
  therefore the count at which the default model is the full one.
- **Below the minimum, a Decision and not an automatic drop.** The risk
  table of the plan has "drop it" for a model that adds little. k2 keeps
  proposal question 3 open for one more Decision, with the caution of
  Gábor et al. (2022) about a coarser grain.

**Judgement values:** 5,000 m (second set), 25,000 m (obscured), 1 km
(centroid and zoo distance), 1 tiger record (dataset match), 25 and 80
(presence cells), `lq` (reduced model). The flag list of step 4 is a
judgement list.

**Rejected:**
- *a1 — one limit of 1,000 m; a2 — one limit of 5,000 m.* a3 holds a1 as
  its main set.
- *n2 — keep a record with four or more decimal places; n3 — keep.*
- *b2 — 2014 to 2022; b3 — all years.*
- *c1 — only `HUMAN_OBSERVATION` and `MACHINE_OBSERVATION`.* The first
  choice; replaced by c2 in Amendment 1.
- *y2 — remove a record with a date flag* (Amendment 1).
- *z1 — no zoo rule; z3 — `CoordinateCleaner`.* z3 is a published method,
  but it is a new dependency, and the coverage of its reference tables for
  India is not known.
- *A rule by land-cover class (for example, no record on built-up land).*
  Not raised as an option: it removes presences with a covariate of the
  model.
- *o1 — no obscured set.*
- *e2 — thinning at 5 km; e3 — no rule for duplicates.*
- *g1 — the same rule only; g2 — the matched datasets as the main
  background.*
- *h1 — one limit of 25.*
- *k1 — no model below the limit, with no further Decision.*

**Limitations:**
- The uncertainty value comes from the observer or the publisher. A small
  value can be wrong, and a record with no value can be precise. A dataset
  that gives no value loses all its records at step 5; the table by dataset
  shows it.
- An obscured record is found by inference. An iNaturalist record with a
  large uncertainty for a different reason gets a 0.2° cell that is not
  sure to hold the true position.
- The two sets can come from different observer groups (see Reason). The
  matched set tests this; it does not remove it.
- The centroid is the centre of a polygon of this project. A record at the
  centre point of a gazetteer can be more than 1 km from it.
- The OpenStreetMap zoo layer is not complete, and the coverage for India
  is not known. A captive animal at a place with no zoo tag stays.
- A material sample (step 2, c2) can be tissue from a captive or a dead
  animal, or it can have the position of a laboratory. The zoo rule finds
  only a zoo that is on the map. The record type does not say how the
  sample was found.
- The year of a record with a date flag is the year that GBIF gives
  (Amendment 1).
- The species identification is not checked.
- The datum of a record with an assumed datum is not checked.
- The window is 17 years; the covariates are from 2021 and 2022.
- A presence cell is not a count of tigers, and one cell per record set
  drops the number of visits.
- The limits 25 and 80 are for the number of cells, not for their spread.
  Clean records are probably grouped in a small number of reserves (not
  verified). The study behind 25 used simulated species with no sampling
  bias.
- The numbers in "Judgement values" are judgement values.

**Consequences:**
- `R/00_config.R`: new `OCC_*` settings. By Amendment 1, `OCC_BASIS_KEEP`
  has five values.
- `scripts/08` (task 13.2 onward): reads the two GBIF files, not the
  interim layers (the interim layers are the guard of point 1). Outputs:
  the clean tiger layer `occ_tiger_gbif_clean_7755.gpkg` (records, with
  `uncert_set` and the cell number), the obscured set, the clean
  background `effort_background_tgs_clean_7755.gpkg` (with `uncert_set`
  and `ds_match`), and the attrition table. The file name of the obscured
  set and the `tbl_15_*` slugs are process choices of task 13.2.
- QA (task 13.7), with a stop on any failure: the rule functions on a
  hand-made case first; the attrition adds up to the entry count for each
  set; no clean record fails a step; the two coordinate tests of step 4
  count zero; step 3 removes no background record; each obscured record
  has the iNaturalist key and an uncertainty of 25,000 m or more; no
  `tbl_15_*` table holds a position. By Amendment 2, also the check of the
  dataset descriptions (it stops the script before the clean layers are
  written).
- `docs/data-dictionary.md` (task 13.9): the placeholder entry of the clean
  layer has an `obscured` field. The clean layer has no such field; the
  obscured records are a separate set.
- `docs/project-plan.md`: task 13.1 done; a dated note on tasks 13.2 to
  13.4 and 13.7 (the new read of the two files, the zoo read, the obscured
  set, the three background sets).
- Week 14 starts with the outcome of point 8, then the Decisions that
  points 8 and 9 name.

This closes the **[Week 13] Occurrence-cleaning rule** pending item.

### Decision 22 — Effort surfaces: surfaces and uses, records, unit, settlement classes, kernel and radius, time windows, edge rule, Gi*, publication
**Date:** 2026-10-17 (fixed **before** any density surface is built and
before any count by time window is made — see "What was seen before this
Decision")
**Choice:** Settings in `R/00_config.R` (`KDE_*`).
`scripts/08_prepare_occurrences.R` STEP 13.4 (task 13.6) applies them. Fork
codes as raised on 2026-10-17: a2, p1, u2, b2, c2, d3, e2, f2, g1. *(Decision
21 uses some of the same codes. Write the Decision with the code, for
example "Decision 22 c2".)*

1. **Surfaces and their uses (a2).** Week 13 builds three surfaces for all
   years (2006–2022). Each surface uses the rules of points 2 to 7.

   | Surface | Input | Use |
   |---|---|---|
   | `effort` | the clean Mammalia background (point 2) | Shows where mammals are recorded (proposal question 4). A candidate bias input if Week 14 chooses a model at a coarser grain; Week 14 decides |
   | `tiger` | the clean tiger records (point 2) | Shows where tigers are recorded, for a comparison with the effort surface. Not a suitability surface. Not published (point 9) |
   | `settlement` | OpenStreetMap city and town points (point 4) | An access layer for the effort result. A candidate observer-bias covariate if Week 14 fits a model (Warton et al. 2013); Week 14 decides |

   - **No ratio surface** (tiger ÷ effort) in Week 13. A ratio is near to a
     simple bias-corrected model, so it is a part of the Week-14 model
     Decision.
   - **The obscured set is in no surface.** There is no matching background
     set: Decision 21 point 4 counts the obscured background and does not
     keep it. The position error of an obscured record is about 10 km on
     average (two random points in one 0.2° cell; computed for this
     Decision). The set stays an input to the Week-14 Decision.
   - **Target group:** all Mammalia (Decision 5). If Week 14 makes the
     target group smaller, the effort surface is built again with the same
     settings.
   - **No road surface.** The stack has `dist_road_m`.
2. **Records (p1).** The 5 km sets (`KDE_UNCERT_SETS`): the tiger records
   and the background records with `uncert_set` `1km` or `5km` (tiger: 300
   records in 44 cells; background: 23,901 records), from all datasets
   (`ds_match` is not used). The model sets of Decision 21 point 9 do not
   change.
3. **Unit (u2).** A complete-case 1 km cell with one or more records of the
   set counts 1 (`KDE_UNIT` = `cell`; the field `cell_1km`; Decision 21
   point 5). The number of records in a cell is not a weight. The same unit
   applies to the settlement points: a complete-case cell with one or more
   city or town points counts 1. A settlement point on a cell that is not a
   complete-case cell is not used; the script counts these points.
4. **Settlement classes (b2).** The points of
   `data/raw/osm/osm_settlements_7755.gpkg` with `place` = `city` or `town`
   (`KDE_SETTLEMENT_CLASSES`; 4,597 points: city 495, town 4,102). Villages
   (195,203 points) are not used.
5. **Kernel and radius (c2).**
   - **Kernel:** quartic (`KDE_KERNEL`), K(d) = (1 − (d / R)²)² for
     d < R and 0 from R. This is the kernel of the ArcGIS Kernel Density
     tool of Phase 1 (Silverman 1986, as the Esri documentation gives it).
   - **Radius:** R = `KDE_RADIUS_M` = 20,000 m. R is the support radius:
     the kernel is 0 from R. The standard deviation on each axis is
     R / √8 = 7,071 m (`KDE_SIGMA_M`). A tool that takes a standard
     deviation (the `sigma` of `spatstat`) gets 7,071 m, not 20,000 m.
     *(Checked for this Decision in `spatstat.explore` 3.2.5:
     `kernel = "quartic"` with `sigma` = 1 has a support radius of 2.83,
     which is √8.)*
   - **On the grid:** the weight of a cell is K at the distance between
     the two cell centres. The weights are scaled to a sum of 1 over the
     full disc.
   - **Value:** units per km² (a cell is 1 km²), after the edge rule
     (point 7). `NA` outside the complete-case cells. 32-bit float, on the
     grid of `cov_stack_1km_7755.tif`.
   - **One radius for all surfaces.** 20 km is the Phase-1 radius. Phase 1
     tested 10, 20 and 30 km and kept 20 km.
   - **QA radii (c2).** The three surfaces of point 1 are also built at
     10 km and 30 km (`KDE_RADII_QA_M`). They are for a QA comparison only
     and are not an input to any later step. For each surface and each QA
     radius the QA gives: (a) the Spearman rank correlation with the 20 km
     surface, on the cells where one or both surfaces are above 0; (b) the
     area above 0, in km²; (c) the maximum value. No rule uses these
     numbers. The radius stays 20 km whatever the result.
6. **Time windows (d3).**
   - The three surfaces of point 1 use all years, 2006–2022.
   - **Counts by window.** For each clean set (tiger 1 km set, tiger 5 km
     set, obscured set; background 1 km set, 5 km set and matched 1 km
     set): the number of records and the number of units (1 km cells; 0.2°
     cells for the obscured set) in each window of `KDE_WINDOWS`: 2006–2010
     (`BASELINE_WINDOW`), 2011–2017 (the years between) and 2018–2022
     (`CURRENT_WINDOW`). The window of a record is its `year`. One `tbl_15`
     table; its slug is a process choice of task 13.6. Counts only.
   - **Effort window surfaces.** The effort surface is also built for
     2006–2010 and for 2018–2022 (`KDE_WINDOW_SURFACES`), at 20 km only, from
     the units of the window: a cell counts if it has one or more
     background records of that window. A window surface is built only if
     the window has `KDE_WINDOW_MIN_UNITS` = 100 units or more. If it has
     fewer, the count is reported and no surface is built.
   - No tiger window surface. No settlement window surface: the settlement
     layer has no date.
   - Each window surface gives its unit count, its sum and its value range,
     as each other surface does. No other comparison of the two windows is
     fixed here.
   - The windows are the Phase-1 windows. They are not the census series
     (Decision 6; baseline 2014).
7. **Edge rule (e2).** A uniform edge correction (`KDE_EDGE`; Diggle 1985;
   the default of `spatstat` `density.ppp`).
   - The window is the complete-case cells of `cov_stack_1km_7755.tif`.
   - For each cell, M is the kernel mass of its disc that falls on window
     cells (the sum of the scaled weights of those cells). The value of the
     cell is its kernel sum divided by M. M depends on the window and the
     radius only, so one M per radius serves the three surfaces.
   - A cell with M below `KDE_EDGE_FLAG_MASS` = 0.5 keeps its value. The QA
     counts these cells for each radius.
8. **Getis-Ord Gi\* (f2).** Week 13 builds no Gi*. The Week-14 model
   Decision decides whether Gi* is built, where and how, as a part of the
   effort result. If it is built, its distance band is a new value: the
   Phase-1 documents give 50 km (final report) and 25 km (method notes and
   story-map outline).
9. **Publication (g1).**
   - **The tiger surface is never published and never committed**
     (`KDE_PUBLISH_TIGER` = `FALSE`). The same applies to its QA surfaces.
     They stay under `data/` (gitignored). With 44 units, a peak of the
     surface is at a record cell.
   - **The published tiger product is the count of clean records by
     reserve** (task 13.8). A count of 1 or 2 is not published; it is given
     as "fewer than 3" (`KDE_SMALL_N` = 3; `warn_small_n()`). Task 13.8 is
     optional: if it is not done, Week 13 publishes no tiger product.
   - **The effort and settlement surfaces** hold no tiger position (tier
     T0). They can be published at 1 km or coarser, through
     `assert_publishable_rast()`. Their published form is decided with the
     Stage-3 figures; each published map states the effort caveat
     (proposal §7).
   - The console text and each `tbl_15` table hold counts and statistics
     only: no coordinate, no cell number and no position of a maximum.

**What was seen before this Decision (pre-registration, stated plainly):**
- **In the documents (the author and the chat):** the cleaned counts of
  tasks 13.3 and 13.4 (tiger 1 km set 45 records in 17 cells; 5 km set 300
  records in 44 cells; obscured set 884 records in 104 cells of 0.2°;
  background 23,901 records; 1 km background 20,905 records in 4,554
  cells; matched 1 km background 6,082 records in 417 cells); the dataset
  shares (one dataset gives 273 of the 300 records of the tiger 5 km set;
  one background dataset gives 3,201 records of the 1 km background; two
  datasets give 4,829 of the 6,082 matched records); the background counts
  by order; the settlement classes; the Phase-1 KDE and Gi* settings and
  results.
- **By the author:** the Week-13 console of tasks 13.2 to 13.4. The author
  stated on 2026-10-17 that values from that console that are not in the
  documents are not remembered.
- **By the chat that drafted this Decision:** the documents, the scripts,
  the Phase-1 and Phase-2 documents of the Project, and the literature. No
  data file.
- **Not seen by anyone:** a density surface, a count by time window, a
  count by reserve, a position, and the number of cells of the 5 km
  background.
- **Post-seen in principle:** forks p and u. The chat knew the dataset
  shares when it recommended p1 and u2.
- **The choices.** The chat gave one recommended option for each fork. The
  author took it for each fork but two: c2 (the chat recommended c1, one
  radius with no QA radii) and d3 (the chat recommended d2, the counts by
  window with no window surface). c2 and d3 add surfaces to the
  recommended set; they remove nothing from it.

**Outcome of STEP 13.4 (task 13.6, `scripts/08`, run on the project machine
on 2026-10-18):**
- The hand-made case passed (16 of 16 checks). The guard passed: the clean
  layers on disk give the counts of `tbl_15_occ_sets.csv`, and point 8 is
  `no_1km_model`.
- Window: 3,067,467 complete-case cells (the `tbl_10` value).
- Units (point 3): effort 5,512 cells (the 23,901 records of the 5 km
  background); tiger 44 cells (300 records); settlement 4,588 cells (the
  4,597 city and town points; each point is on a complete-case cell).
- Effort window surfaces (point 6): 2006–2010 has 623 units and 2018–2022
  has 3,569 units. Both are above 100, so both surfaces are built.
- Counts by window (2006–2010 / 2011–2017 / 2018–2022):

  | Set | Records | Units |
  |---|---|---|
  | tiger 1 km set | 15 / 12 / 18 | 8 / 11 / 1 cells |
  | tiger 5 km set | 20 / 12 / 268 | 11 / 11 / 26 cells |
  | obscured set | 101 / 329 / 454 | 21 / 54 / 71 cells of 0.2° |
  | background 1 km set | 5,225 / 7,597 / 8,083 | 515 / 1,893 / 2,961 cells |
  | background 5 km set | 5,706 / 8,691 / 9,504 | 623 / 2,304 / 3,569 cells |
  | matched 1 km background | 1,670 / 3,685 / 727 | 62 / 330 / 142 cells |

- Window cells with an edge mass below 0.5: 8,843 at 20 km (2,815 at 10 km;
  15,702 at 30 km).
- The values of each surface (units, maximum, integral, area above 0) are
  in `tbl_15_kde_summary.csv`.
- No rule of this Decision changed after the run.

**QA radii (point 5; task 13.7, `scripts/08` STEP 13.5, 2026-10-18;
descriptive, no rule):** Spearman rank correlation with the 20 km surface,
on the cells where one or both surfaces are above 0
(`tbl_15_kde_radius_compare.csv`):

| Surface | 10 km | 30 km |
|---|---|---|
| effort | 0.788 (1,124,852 cells) | 0.911 (1,697,516 cells) |
| tiger | 0.791 (20,716 cells) | 0.906 (40,537 cells) |
| settlement | 0.800 (2,360,835 cells) | 0.899 (2,799,615 cells) |

The radius stays 20 km (point 5). The QA of the surfaces passed (the grid,
no value below 0, `NA` outside the window, the units, the integrals, the
edge masses, and a direct calculation at 45 sample cells of each 20 km
surface).

**Reason and sources:**
- **Two surfaces side by side (a2).** Proposal question 4 asks how much of
  the pattern is effort and how much is distribution. A description of
  that needs the effort surface and the tiger-record surface on the same
  rules. `maxnet` uses the target-group background points directly
  (Phillips et al. 2009), so the target-group method does not need a
  density surface. In two simulation studies, a filter of the records was
  the most consistent correction (Fourcade et al. 2014; Kramer-Schadt et
  al. 2013), and a correction can over-correct where the effort is low
  (Ranc et al. 2017; Barber et al. 2022). The bias use of the effort
  surface is therefore a candidate for Week 14 only.
- **The 5 km sets (p1).** The disc of a 20 km kernel is about 1,257 km². A
  position error of 5 km or less moves little of the mass of a unit. A
  surface from the 17 cells of the tiger 1 km set shows only those cells.
- **The cell as the unit (u2).** The cell is the unit of Decision 21. The
  repeated records of one study or one observer cannot make a peak alone.
- **City and town (b2).** OpenStreetMap holds 195,203 village points;
  Census 2011 counts 640,932 villages, including uninhabited villages
  (about 30 %). It holds 4,597 city and town points; Census 2011 counts
  7,933 towns, including census towns (about 58 %). A village surface
  would thus show the mapping effort of OpenStreetMap as well as the
  settlements. The comparison is rough: an OpenStreetMap village point and
  a Census village are not the same unit. The Phase-2 plan (§6.2) used
  cities and towns as its settlement layer. Human pressure (`ghm`) and
  road access (`dist_road_m`) are already in the stack.
- **The 15 km and the 20 km.** Both values are correct, for two different
  surfaces. 20 km is the search radius of the Phase-1 tiger-record KDE
  (Phase-1 final report §3.3). 15 km is the radius of the settlement
  density in the Phase-2 plan (§6.2; roads 10 km there). The pending item
  and the Week-13 plan called one of the two "wrong"; that was not
  correct.
- **Quartic, 20 km (c2).** The kernel and the radius of Phase 1 make the
  surfaces comparable with Phase 1. The QA radii show how much the radius
  changes each surface. A sigma from a data rule (c3) can be very small for
  clustered records, and the Phase-1 comparison is then lost.
- **Windows (d3).** The counts show the change in effort with no small
  surface. The two effort window surfaces show where the change is. Phase 1
  called a KDE from about 100 points "marginal"; 100 units is the minimum
  for a window surface.
- **Edge rule (e2).** The Sundarbans and the Terai reserves are on the
  coast or on the Nepal or Bangladesh border. The data has no record
  outside India. With no correction, their effort looks low for that
  reason only. The uniform correction divides by the kernel mass inside
  the window (Diggle 1985); it is the default of `spatstat`. ArcGIS, and so
  Phase 1, has no edge correction.
- **Gi* in Week 14 (f2).** The form of the Stage-3 result depends on the
  Week-14 Decision (no model, or a model at a coarser grain). Week 13 is
  already above its time estimate, and the Phase-1 band is not clear.
- **No tiger surface published (g1).** Sensitive-data policy §3: a
  published occurrence product is aggregated, and a unit with few records
  can narrow a position. A surface from 44 units shows record cells.

**Judgement values:** 20 km (radius, the Phase-1 value), 10 and 30 km (QA
radii, the Phase-1 test values), 100 units (window surface), 0.5 (edge
mass flag), 3 (small count; the default of `warn_small_n()`).

**Rejected:**
- *a1 — the effort surface only; a3 — a2 plus a ratio surface.* See "Two
  surfaces side by side".
- *p2 — the 1 km sets.* 17 tiger cells.
- *u1 — each record counts 1.* One dataset gives 273 of the 300 tiger
  records.
- *b1 — no settlement surface; b3 — all three classes.* b3: the village
  coverage.
- *c1 — 20 km with no QA radii* (the chat's recommendation); *c3 — a
  Gaussian kernel with a sigma from a data rule.*
- *d1 — all years only; d2 — counts by window with no window surface* (the
  chat's recommendation); *d4 — d3 plus tiger window surfaces.*
- *e1 — no edge correction.*
- *f1 — Gi\* in Week 13; f3 — no Gi\*.*
- *g2 — the tiger surface on the 10 km grid in 5 classes; g3 — the tiger
  surface at 1 km.*

**Limitations:**
- The effort surface shows where mammal records are, not where people
  looked: a survey with no record leaves no trace.
- A small number of sources give most background records (iNaturalist
  gives 21,083 of the 39,057 records of the entry state). The cell unit
  makes this smaller; it does not remove it.
- The tiger surface has 44 units, and one dataset gives 273 of the 300
  records. It describes records, not tigers.
- The OpenStreetMap city and town layer holds about 58 % of the Census
  towns, and its coverage by region is not known.
- The edge correction assumes that the rate outside the window is the rate
  inside it. Small islands and thin strips get large factors; the count of
  cells with M below 0.5 shows them.
- 20 km is the Phase-1 value. The QA radii show its effect; they do not
  test it.
- A position of the 5 km sets can be up to 5 km from the true position.
- A change between the two windows mixes a change of effort with the
  growth of the recording platforms.
- The window counts and the window surfaces are not corrected for the
  number of years in a window (5, 7 and 5 years).

**Consequences:**
- `R/00_config.R`: the `KDE_*` settings of this Decision, in a new block.
  `KDE_RADIUS_M` moves into the block; the comment "starting value; test
  10/20/30 km" is removed.
- `scripts/08` STEP 13.4 (task 13.6): the three surfaces at 20 km; the
  same three at 10 and 30 km for the QA; the effort window surfaces that
  reach the minimum; the counts by window. Process choices of task 13.6:
  the tool (a convolution on the template grid, or `spatstat`), the file
  names (`kde_<what>_1km_7755.tif`), where the QA surfaces are kept, the
  slug of the window table, and any new package.
- QA (task 13.7) adds: a hand-made case for the kernel and the edge rule
  (a known unit, a known mass) before the real run; each surface on the
  template grid (`compareGeom`); no value below 0; `NA` outside the
  complete-case cells; the unit count of each surface equals the cell
  count of its set; the count of cells with M below 0.5; the QA-radius
  numbers of point 5; no tiger surface under `outputs/`; no position in a
  table or in the console text.
- `docs/project-plan.md`: task 13.5 done; dated notes on tasks 13.6 to
  13.8.
- The Week-14 model Decision also decides: the bias use of the effort
  surface, the covariate use of the settlement surface, and Gi* (pending
  item).

This closes the **[Week 8–9 → Week 13] Settlement layer for the KDE**
pending item.

### Decision 23 — Model at a coarser grain: model, grain and input set, model cells, minimum, background, target group, background minimum, Facebook check, Gi*
**Date:** 2026-10-25 (fixed **before** any count of presence or background
cells at a coarser grain and before any model — see "What was seen before
this Decision")
**Choice:** Settings in `R/00_config.R` (`SDM_*`). The Week-14 script
(`scripts/09_<verb_object>.R`, named in task 14.2) applies them. Fork codes
as raised on 2026-10-18 and chosen on 2026-10-25: a2, b3, v1, c1, r2, s1,
m1, e1, f2. *(Decisions 21 and 22 use some of the same letters. Write the
Decision with the code, for example "Decision 23 r2".)*

1. **Model (a2).** Stage 3 fits a `maxnet` suitability model at a coarser
   grain. There is no 1 km model (Decision 21 point 8, `no_1km_model`).
   This is branch B of the Week-14 plan. A model is fitted only if the
   counts of task 14.4 reach the limits of points 4 and 6.
2. **Grain and input set (b3).**
   - **Presences:** the obscured set of Decision 21 point 4 — 884
     iNaturalist records in 104 cells of 0.2°, before point 3. The tiger
     1 km set and the 5 km set are not model inputs.
   - **Grain:** the cells of the iNaturalist obscuring grid: 0.2° of
     latitude by 0.2° of longitude, with edges at multiples of 0.2°, in
     EPSG:4326 (`SDM_GRAIN_DEG` = `OCC_OBSCURED_CELL_DEG`;
     `SDM_GRAIN_CRS`). The cell of a record is its coordinates rounded down
     to a multiple of 0.2° (the rule of Decision 21 point 4).
   - **Not an aggregate of the 1 km template.** A 0.2° cell is a polygon. A
     covariate value of a cell is a summary of the 1 km cells of
     `cov_stack_1km_7755.tif` with their centre inside the polygon. Decision
     24 fixes the summary of each band.
   - In India a 0.2° cell is 396–488 km²: 22.1 km north–south by 22.0 km
     east–west at 8° N, and 22.2 km by 17.8 km at 37° N (computed for this
     Decision on the WGS 84 ellipsoid). That is about 400 to 490 one-km
     cells.
   - **Unit:** a model cell (point 3) with one or more records of the set
     counts 1, as Decision 21 point 5. The number of records in a cell is
     not a weight.
   - The model sets of Decision 21 point 9 (`main`, `uncert5km`, `matched`)
     are not run. Decision 24 fixes the sensitivity runs at this grain.
3. **Model cells (v1).** A 0.2° cell is a model cell if the complete-case
   1 km cells with their centre inside its polygon cover 50 % or more of
   the polygon area (`SDM_CELL_MIN_COVER` = 0.5). The share is (the number
   of those cells × 1 km²) ÷ (the area of the polygon), both in EPSG:7755
   units.
   - Only a model cell can be a presence cell, a background cell or a
     prediction cell.
   - The script counts the presence records and the presence cells that
     this rule removes.
4. **Minimum number of presence cells (c1).** The test value is the number
   of presence cells after point 3. The limits are those of Decision 21
   point 8. No new value is set.

   | Presence cells | Outcome |
   |---|---|
   | below 25 (`SDM_MIN_CELLS`) | **No model** (`no_model_presence`). Stage 3 gives the effort result (branch A). There is no further Decision about a model, and no other grain is tried |
   | 25 to 79 | **A reduced model** (`reduced_model`). The feature classes are linear and quadratic at most (`SDM_REDUCED_MAX_CLASSES` = `lq`). Each output of the model says that the sample is small |
   | 80 or more (`SDM_MIN_CELLS_FULL`) | **The planned model** (`planned_model`). Decision 24 fixes the settings; it can be more strict than the `maxnet` default, not less |

   - Task 14.4 compares the count with the limits and states the outcome.
     The outcome is locked in `R/00_config.R` (as `OCC_POINT8_OUTCOME`) and
     does not change after that.
5. **Background (r2, s1).** The clean records of the iNaturalist dataset
   (`SDM_BG_DATASET_KEY` = `OCC_INAT_DATASET_KEY`), all Mammalia except the
   tiger. Two parts:
   - **(a) The obscured background:** the background records that pass
     steps 1 to 5 of Decision 21 and the obscured rule of its point 4
     (iNaturalist; uncertainty of 25,000 m or more), each in its 0.2° cell.
     Week 13 counted 7,029 records in 825 cells (before point 3;
     `tbl_15_occ_sets.csv`).
   - **(b) The iNaturalist records of the 5 km background:** the records of
     the clean background with `uncert_set` `1km` or `5km`
     (`SDM_BG_UNCERT_SETS`), each in the 0.2° cell of its own coordinates.
     These coordinates are not obscured. Not counted. *(2026-10-25, task
     14.2: 9,777 records — the 7,238 iNaturalist records of the 1 km
     background and 2,539 with an uncertainty above 1 km and up to 5 km.
     These are counts of records; task 14.4 counts the cells.)*
   - **Unit:** a model cell with one or more background records of part (a)
     or (b) counts 1.
   - **Scope (s1):** all Mammalia (Decision 5; `SDM_BG_SCOPE`). No taxon is
     removed. The target group does not change, so the Decision-22 effort
     surfaces are not built again (Decision 22 point 1).
   - The background holds no record of another dataset.
   - **A new output.** Part (a) is not on disk: Decision 21 point 4 counts
     the obscured background and does not keep it. Task 14.2 decides where
     it is made (`scripts/08` STEP 13.3 again with `RUN_CLEANING = TRUE`, or
     a new STEP of `scripts/09`). Part (b) needs `datasetKey`: the clean
     background layer has it (`scripts/08` STEP 13.3 writes it), and the
     guard of task 14.2 checks it on disk.
   - By default, `maxnet` adds each presence that is not in the background
     to the background (`addsamplestobackground = T`). Decision 24 says
     whether the default applies.
6. **Minimum size of the background (m1).** The number of background cells
   (point 5, after point 3, before a presence cell is added) must be 10
   times the presence cells of point 4 or more (`SDM_BG_MIN_RATIO` = 10).
   - Below it: **no model** (`no_model_background`), as in point 4: Stage 3
     gives the effort result, with no further Decision about a model and no
     other background.
   - Point 4 is tested first. The four outcomes are `SDM_OUTCOME_VALUES`.
     Task 14.4 states the outcome of points 4 and 6 together.
7. **The Facebook dataset (e1).** With b3, the dataset "Bengal Tiger
   (Panthera tigris) Sighting based on Photographs from Facebook in India"
   gives no record to the model: the obscured set is from iNaturalist only
   (Decision 21 point 4), and so is the background of point 5. e1 is
   therefore **a check, not a run**: the QA counts the records of this
   dataset (`SDM_CHECK_ABSENT_DATASETS`) in the presence set and in the
   background of the model, and each count must be 0. *(2026-10-25, task
   14.6: 0 records in the presence set and 0 in the background;
   `tbl_16_sdm_qa.csv`.)*
8. **Gi\* and the ratio (f2).**
   - **A Gi\* of the effort** is built (proposal question 4).
   - **A Gi\* of the tiger records in the Phase-1 form** is built for a
     comparison with Phase 1. The Phase-1 Gi* used the tiger records
     (1,411 points, 2006–2022), a fixed distance band of 50 km (the peak of
     its Incremental Spatial Autocorrelation was at 25 km) and a false
     discovery rate (Phase-1 final report §3.3). The Ranthambore cold spot
     came from that Gi*.
   - **The tiger Gi\* is never published and never committed**, as the
     tiger surface (Decision 22 point 9; `SDM_GISTAR_PUBLISH_TIGER` =
     `FALSE`). It stays under `data/` (gitignored).
   - **Settings later.** A numbered Decision in Week 15 or 16, before any
     Gi* is computed, fixes: the input set of the tiger Gi* (the 5 km set,
     the obscured set or both), the grid, the value of a cell, the
     neighbours and the distance band (a new value), the correction for
     many tests, and what the docs can state from the tiger Gi* (for
     example, whether the Phase-1 cold spot at Ranthambore is found again).
     Task 14.7 puts that Decision in the plan.
     *(2026-11-07, Decision 26 x1: the tiger Gi\* is compared with the
     effort Gi\* of this project only. There is no Phase-1 form and no
     comparison with Phase 1. Decision 26 fixes the settings. The text of
     this point does not change.)*
   - **No ratio** of the tiger and the effort surfaces (`SDM_RATIO` =
     `FALSE`). The model is the bias-corrected product. If task 14.4 gives
     a no-model outcome, the Gi* Decision also decides the ratio and the
     other parts of the effort result (the branch-A list of task 14.3).
9. **Sensitivity and publication.**
   - The obscured set and each layer made from it (the presence cells) are
     tier T1. They stay under `data/` (gitignored).
   - A `tbl_16_*` table holds counts and statistics only: no 0.2° cell, no
     corner coordinate and no other position.
   - The console text that goes to a chat holds counts and names only.
   - The published form of a suitability surface at 0.2° is decided with
     the prediction (Week 15). It must not mark the presence cells.
   - The QA check "no file with 'tiger' in its name under `outputs/`" (task
     13.7) and the file name of a model are a process choice of task 14.2
     or 14.3.

**What was seen before this Decision (pre-registration, stated plainly):**
- **In the documents (the author and the chat):** each count of the
  `tbl_15` tables (the entry state of the Week-14 plan). Among them: the
  obscured set, 884 records in 104 cells of 0.2°; the obscured background,
  7,029 records in 825 cells; the tiger 5 km set, 300 records in 44 cells of
  1 km, 273 of them from the Facebook dataset; the background by order and
  family; the counts by window; the counts per reserve; the Phase-1 Gi*
  settings.
- **By the author:** the Week-13 console. The author stated on 2026-10-25
  that the statement of 2026-10-17 is still true: values from that console
  that are not in the documents are not remembered. The author has not
  looked at a density surface or a point layer on a map.
- **By the chat that drafted this Decision:** the documents, the scripts,
  five committed `tbl_15` tables (`occ_sets`, `occ_window_counts`,
  `occ_by_reserve`, `background_taxa`, `kde_summary`),
  `data/data_manifest.csv`, the Phase-1 and Phase-2 documents of the
  claude.ai Project, the literature, and the iNaturalist source code. No
  data file and no map. *(It also read the Phase-1 spreadsheet
  `data_inventory_v2.xlsx` once, on 2026-10-18, before the author stated
  that the file is not a part of this project. No value of it is used.)*
- **Not computed by anyone:** a count of presence or background cells after
  point 3; the number of model cells; the number of cells of part (b) of
  the background; the taxa of the obscured background; a model, a Gi* or a
  ratio.
- **Post-seen in principle:** points 4 and 6. The upper limit of 104
  presence cells and the 825 cells of part (a) were known. The limits of
  point 4 were fixed on 2026-10-11, before any count. The chat wrote the
  value 10 of point 6 when it knew that 825 ÷ 104 = 7.9 for part (a) alone;
  part (b) is not counted.
- **The choices.** The chat gave one recommended option for each fork. The
  author took it for each fork but f: the chat recommended f1 (a Gi* of the
  effort only) and the author chose f2, which adds a tiger Gi* that is not
  published. For fork e, the chat said that with b3 there is nothing to
  choose; the author chose e1, which point 7 records as a check.

**Outcome of points 4 and 6 (task 14.4, `scripts/09` STEP 14.1, run on the
project machine on 2026-10-25):**
- The hand-made case passed (19 of 19 checks), and the guards passed (35
  of 35).
- **Grid (points 2 and 3):** 7,450 cells of 0.2° hold one or more
  complete-case 1 km centres. **6,969 are model cells** (cover share of
  50 % or more). They hold 3,025,000 of the 3,067,467 complete-case 1 km
  cells; the other 42,467 are in the 481 cells below the rule. A guard
  checks the count of each cell against the 1 km cell-id raster.
- **Presences (point 4):** 884 records in 104 cells. The 50 % rule removes
  no presence cell. **104 presence cells**, which is 80 or more
  (`SDM_MIN_CELLS_FULL`).
- **Background (point 6):** part (a), 7,029 records in 825 cells, 800 of
  them model cells; part (b), 9,777 records in 1,239 cells, 1,200 of them
  model cells. Together: **1,486 background cells**. The minimum is 10 ×
  104 = 1,040; the ratio is 14.3. The background cells are 21 % of the
  model cells. 86 of the 104 presence cells hold a background record; 18 do
  not.
- **Outcome: `planned_model`.** Decision 24 fixes the settings of the
  planned model; it can be more strict than the `maxnet` default, not less
  (point 4). With 104 presences, the default feature classes of
  `maxnet.formula()` are `lqph` (product features from 80; Decision 21,
  "Reason and sources").
- The outcome is locked in `R/00_config.R` (`SDM_GRAIN_OUTCOME` =
  `"planned_model"`, process choice l1). It does not change after this run.
- **Stated plainly:** part (a) alone (r1, rejected) has 800 background cells
  on model cells, which is below the minimum of 1,040. With r1, the outcome
  would have been `no_model_background`.
- Outputs: `data/processed/sdm_grid_cell02_7755.gpkg` and
  `sdm_cellid_1km_7755.tif` (gitignored; no presence or background flag);
  `outputs/tables/tbl_16_sdm_counts.csv` (21 rows; counts only). STEP 14.1
  took 0.1 minutes.
- No covariate summary and no model yet: Decision 24 comes first (process
  choice o2).

**Reason and sources:**
- **The obscured set at its own grain (a2, b3).**
  - At the 0.2° grain an obscured record has no position error. In the
    iNaturalist source code (`app/models/observation.rb`, branch `main`,
    commit `0e15a4a`, read 2026-10-18), the cell centre is the coordinate
    minus (the coordinate modulo 0.2) plus 0.1, and the public point is the
    centre plus a random offset of up to 0.1° on each axis. So the public
    point is in the same fixed cell as the true point. The help page of
    iNaturalist says that the rectangle includes the true location. This
    confirms the cell rule of Decision 21 point 4.
  - Gábor et al. (2022) found that a coarser grain does not make up for a
    position error. At the cell of the iNaturalist grid there is no error
    to make up for. A grain 10 times coarser did not severely affect the
    predictions of 50 species and 10 methods (Guisan et al. 2007).
  - The 5 km set is in effect one dataset: the Facebook dataset gives 273 of
    its 300 records, and 27 records stay without it. Its position error of
    up to 5 km stays at each grain (Gábor et al. 2022). Its records are
    grouped (300 records in 44 cells; records in 10 reserve polygons).
  - 104 cells, before point 3, is above the two limits of Decision 21
    point 8.
  - The years of the obscured set are more even: 454 of its 884 records
    (51 %) are from 2018–2022, against 268 of 300 (89 %) for the 5 km set.
- **Model cells (v1).** A cell that is mostly outside the complete-case
  window gets a covariate summary from a small part of its area. On a
  border cell, the true point of an obscured record can be outside India:
  step 0 tested the public point. The 50 % rule makes this smaller.
- **The limits of Decision 21 (c1).** No new value after the counts were
  seen. "No other grain" stops a search through grains until one passes.
- **One platform for the background (r2).**
  - A target-group background has the bias of the presences when its
    species are "observed by similar methods" (Phillips et al. 2009). Here
    the presences and the background are photographs uploaded to one
    platform.
  - iNaturalist obscures a taxon with an IUCN status of Near Threatened or
    worse (forum posts; see Decision 21), and an observer can obscure a
    record. Part (a) alone is therefore mostly threatened mammals, which
    probably share much of the range of the tiger (not verified). The
    target group must be "jointly abundant over the broadest environmental
    sub-area" (Botella et al. 2020); a correction can over-correct (Ranc et
    al. 2017; Barber et al. 2022).
  - Part (b) adds the common species of the same visits and the records
    outside the reserves.
  - A record of part (b) that is less than 5 km from a cell edge can be in
    the next cell. With the cell unit, the effect on the background is
    probably small (not measured).
- **All Mammalia (s1).** The iNaturalist filter removes the survey datasets
  of other methods (bat, trap and dolphin surveys are separate GBIF
  datasets). Most of the kept rodent records are squirrels: 5,377 of the
  6,361 rodent records of the 5 km background (84.5 %;
  `tbl_15_background_taxa.csv`), which are active by day and which
  visitors photograph. The pending item said that rodents are not observed
  by the methods that record tigers; for squirrels that is not correct. The
  taxa of the iNaturalist records are not counted. A smaller target group
  would need the effort surfaces built again (Decision 22 point 1).
- **10 times the presence cells (m1).** No published minimum was found for
  a target-group background. With 10 times the presence cells, the
  background — the sample of the conditions in the study area — is much
  larger than the presence set. The rule does not depend on the grain.
  `maxnet` 0.1.4 adds each presence to the background by default.
- **e1 as a check.** The check confirms that one dataset that dominates the
  tiger records is not in the model.
- **Two Gi\* (f2).** Proposal §5 names KDE and Gi* for the effort thread.
  The Phase-1 Gi* used the tiger records, so a tiger Gi* gives the
  comparison with that result. A Gi* from few units shows record areas, so
  it is not published (sensitive-data policy §3; Decision 22 point 9). A
  ratio is near to a simple bias-corrected model (Decision 22 point 1), and
  in branch B the model is that product.

**Judgement values:** 50 % (model cell), 10 (background ratio). From
Decision 21: 25 and 80 (presence cells), `lq` (reduced model), 25,000 m
(obscured). Fixed by the source, not judgement values: the cell size of
0.2° and the edges of the grid.

**Rejected:**
- *a1 — no model* (valid, and cheaper; see "Reason and sources").
- *b1 — the 5 km set on the 10 km grid; b2 — the 5 km set on a 5 km grid;
  b4 — two models (b3 and b1).* Not offered: one model with the two sets
  (two observer groups, and the Facebook dataset gives no background
  record).
- *v2 — a cell with one or more complete-case 1 km cells.*
- *c2 — new limits for a coarse grain; c3 — one limit of 25 and `lq` at
  each count.*
- *r1 — the obscured background only; r3 — the background of all
  datasets.*
- *s2 — all Mammalia except the taxa that other methods record (bats,
  whales and dolphins, shrews and moles, hedgehogs, small ground rodents:
  1,248 of the 23,901 records of the 5 km background); s3 — the
  large-bodied guild (Carnivora, Artiodactyla, Perissodactyla, Proboscidea:
  11,177 of 23,901).*
- *m2 — 10 % of the model cells of the grid; m3 — no minimum.*
- *e2 — no check.*
- *f1 — a Gi\* of the effort only* (the chat's recommendation); *f3 — no
  Gi\* and no ratio.*

**Limitations:**
- The grain is about 20 km. The result is a relative suitability at that
  grain. It is not habitat at the scale of a reserve and not an occupancy
  (Decision 1).
- The cells are not equal in area: a cell at 8° N is about 23 % larger than
  a cell at 37° N.
- The presences are iNaturalist photographs. Most are probably from the
  tourist zones of reserves (not verified). A comparison of suitability
  with the reserves is then partly circular; Decision 24 fixes a check that
  is not.
- Steps 7 to 9 of Decision 21 (centroid, zoo, footprint) are not applied to
  the obscured set (its point 4). A record at a zoo, or of a captive animal
  marked as wild, can give a presence cell. A research-grade iNaturalist
  record must be of a wild animal (as far as known; not checked record by
  record).
- The obscured set is found by inference (Decision 21): an iNaturalist
  record with a large uncertainty for another reason is in a cell that may
  not hold its true point.
- The obscuring code was read in its current version. The code of earlier
  years was not checked.
- On a border cell the true point can be outside India. Point 3 makes this
  smaller; it does not remove it.
- The background mixes two kinds of records: part (a), with a sure cell, and
  part (b), with a cell that is sure to about 5 km. The iNaturalist records
  with an uncertainty above 5 km and below 25 km are in no part.
  *(2026-10-25, task 14.2: the entry state has 1,535 such iNaturalist
  records, and 2,299 with no uncertainty value.)*
- The target-group method assumes that the effort for all mammals on
  iNaturalist is the effort for tigers. A visitor who looks for a tiger
  does not look for a squirrel in the same way.
- The covariates are from 2021 and 2022; the records are from 2006 to 2022.
- s1 keeps the taxa that other methods record. With the iNaturalist filter,
  the effect is probably small (not counted).
- The numbers in "Judgement values" are judgement values.

**Consequences:**
- `R/00_config.R`: a new block "Stage 3: model at a coarser grain (Decision
  23)" with the `SDM_*` settings. No other value changes.
- Task 14.2 (process choices): where the obscured background is made (a
  new output); a guard for `datasetKey` in the clean background layer; how
  the 0.2° cell polygons are made (in EPSG:4326, with densified edges,
  projected to EPSG:7755); the name of the outcome lock; the model file
  name against the QA check of task 13.7.
- Task 14.3 (Decision 24, branch B): the covariates and their summary to
  the 0.2° cells (with the pending item "Terrain variables"); the feature
  classes and the regularisation; whether a bias input is added to the
  background of point 5 (pending points 4 and 5); whether `maxnet` adds
  the presences to the background; the evaluation, with a check that is
  not circular; the sensitivity runs (pending point 2); the model file and
  what it holds.
- Task 14.4 (STEP 14.1): the 0.2° cells, the model cells (point 3), the
  presence cells and the background cells, and the outcome of points 4 and
  6, locked in the config. This is a stop point, as task 13.3.
- QA (task 14.6) adds: a hand-made case for the cell of a coordinate (a
  known coordinate gives a known cell, also on an edge) and for the cover
  share (a known polygon) before the real run; each presence record has the
  iNaturalist key and an uncertainty of 25,000 m or more; each background
  record has the iNaturalist key; the check of point 7 (0 records of the
  Facebook dataset); no 0.2° cell and no position in a `tbl_16` table; no
  file from the tiger records under `outputs/`, except a model file that
  Decision 24 allows.
- If task 14.4 gives a no-model outcome: Decision 24 (if recorded) gets a
  dated note "not used"; the effort result goes to the Gi* Decision of
  point 8.
- `proposal.md` §8: an entry. §5.4 is written again; §5.5 gets a dated note.
- `docs/project-plan.md`: task 14.1 done; the branch-A parts of tasks 14.3
  to 14.5 are not used (dated note); notes on tasks 14.2 to 14.6 and on the
  rows of Weeks 15 and 16.

This closes the **[Week 13–14 → Week 14] Target-group scope** pending item
(s1). The item **[Week 14] Model Decisions that Decision 21 names** gets a
dated note: points (1), (3) and (7) are closed; points (2), (4) and (5) go
to Decision 24; the settings of point (6) go to the Gi* Decision.

### Decision 24 — Model settings: covariates, water and elevation, collinearity, features and regularisation, bias input, background, evaluation, gate, reserve check, sensitivity runs, model file
**Date:** 2026-10-25 (fixed after the count of task 14.4 and **before** any
covariate summary at 0.2°, any correlation, any model and any prediction —
see "What was seen before this Decision")
**Choice:** Settings in `R/00_config.R` (`SDM_*`, a second block after the
Decision-23 block). `scripts/09` STEP 14.2 (task 14.5) and STEP 14.3 (task
14.6) apply them; the reserve check and the gate are applied in Week 15.
Fork codes as raised and chosen on 2026-10-25: c1, z1, k1, f3, b1 (with b2
as a sensitivity run), a1, v1, g2, r3, s3, m1. *(Earlier Decisions use some
of the same letters. Write the Decision with the code, for example
"Decision 24 f3".)*

1. **Covariates (c1).** Each covariate of a model cell (Decision 23 point
   3) is a summary over the complete-case 1 km cells of that cell
   (`sdm_cellid_1km_7755.tif`). Nine candidates (`SDM_COVARIATES`):

   | Covariate | Summary of the 1 km cells |
   |---|---|
   | `ghm_mean` | mean of `ghm` |
   | `elev_mean` | mean of `elev` (point 2) |
   | `slope_mean` | mean of `slope` (point 2) |
   | `tri_mean` | mean of `tri` (point 2) |
   | `droad_km_mean` | mean of `dist_road_m`, in km |
   | `lc_forest` | share of the cells of land-cover classes 10 and 95 (tree cover, mangroves) |
   | `lc_open` | share of classes 20, 30 and 90 (shrubland, grassland, herbaceous wetland) |
   | `lc_crop` | share of class 40 (cropland) |
   | `lc_built` | share of class 50 (built-up) |

   - A share is the number of cells of the group ÷ the number of
     complete-case cells of the model cell (`SDM_LC_GROUPS`).
   - Classes 60, 70, 80 and 100 (bare, snow and ice, water, moss and
     lichen) are the rest of a cell, not a covariate, so the four shares do
     not add up to 1.
   - *(The fork text of 2026-10-25 said "eight covariates": it counted
     slope and TRI as one, because point 3 is expected to keep one of
     them. There are nine candidates.)*
   - No other covariate is used. Point 3 can remove candidates; it adds
     none.
2. **Water and negative elevation (z1).**
   - The terrain means (`elev_mean`, `slope_mean`, `tri_mean`) do not use
     the 1 km cells of land-cover class 80 (permanent water;
     `SDM_WATER_CLASS`).
   - On the cells that they use, an elevation below 0 m becomes 0 m
     (`SDM_ELEV_MIN_M`).
   - A model cell with no complete-case cell other than water gets the
     means of its water cells, with an elevation below 0 m set to 0 m.
   - The QA counts the 1 km cells that each part of the rule changes, and
     the model cells of the last case.
3. **Collinearity (k1).** Pearson r between the candidates on all 6,969
   model cells (no presence or background information). The candidates
   are taken in a fixed order (`SDM_COV_PRIORITY`): `ghm_mean`,
   `lc_forest`, `elev_mean`, `slope_mean`, `tri_mean`, `lc_crop`,
   `lc_open`, `droad_km_mean`, `lc_built`. A candidate is kept if its |r|
   with each candidate already kept is 0.7 or less (`SDM_COR_MAX`);
   otherwise it is removed. The correlation table is written (statistics
   only).
4. **Feature classes and regularisation (f3).** Twelve models: feature
   classes `lq`, `lqh`, `lqph` (`SDM_FC_GRID`) × regularisation
   multiplier 1, 2, 3, 4 (`SDM_REGMULT_GRID`), each fitted on all presence
   and background cells with the covariates of point 3.
   - **AICc** (Warren & Seifert 2011; the ENMeval method): the raw output
     (`predict()` type `exponential`, with clamping) over the 6,969 model
     cells is scaled to a sum of 1; LL = the sum of the logs of the scaled
     values at the 104 presence cells; K = the number of non-zero
     coefficients (`betas`); n = 104; AICc = 2K − 2LL + 2K(K + 1) / (n −
     K − 1). A model with K ≥ n − 1 gets no AICc.
   - **Selection:** the models with an AICc within 2 of the lowest
     (`SDM_AICC_DELTA`); of these, the one with the fewest coefficients;
     if two have the same K, the one with the lower AICc.
   - If no model of the grid gets an AICc, the script stops and the author
     decides.
   - The AICc table is written (statistics only). The selected feature
     classes and multiplier are the settings of the main model and of each
     run of points 7 and 10.
5. **Bias input (b1; b2 is a sensitivity run).** The main model has no bias
   covariate: the background is the target-group background of Decision 23
   r2 (`SDM_BIAS_MAIN` = `"none"`). The effort surface of Decision 22 is
   not a model input. The city/town surface of Decision 22 is used only in
   the sensitivity run of point 10.
6. **Presence cells in the background (a1).** `maxnet` with
   `addsamplestobackground = TRUE` (`SDM_ADD_SAMPLES`): the 18 presence
   cells with no background record are added to the background. A presence
   record is also a record of the observer group, so a presence cell is a
   sampled cell.
7. **Evaluation (v1).** Spatial blocks (Roberts et al. 2017; Valavi et al.
   2019):
   - **Blocks:** 2° × 2° (`SDM_CV_BLOCK_DEG`; 10 × 10 cells of 0.2°, about
     220 km), with edges at multiples of 2° of longitude and latitude. The
     block of a model cell is (floor(`ix` / 10), floor(`iy` / 10)).
   - **Folds:** 5 (`SDM_CV_K`). The blocks that hold one or more presence
     or background cells are sorted by their number of presence cells
     (most first), then by their number of background cells (most first),
     then by block id. They are given to the folds in the order 1, 2, 3,
     4, 5, 5, 4, 3, 2, 1, 1, 2, … No random seed.
   - For each fold: the model of point 4 is fitted on the presence and
     background cells of the other four folds (point 6 applies) and
     predicts all 6,969 model cells.
   - **Output for the evaluation:** cloglog, with clamping
     (`SDM_EVAL_TYPE`; the `predict.maxnet()` default clamps).
   - **Metrics of each test fold:**
     - the continuous Boyce index (Hirzel et al. 2006): the
       predicted-to-expected ratio in a moving window of 1/10 of the
       prediction range (`SDM_BOYCE_WINDOW`), at 100 points
       (`SDM_BOYCE_RES`); "predicted" = the test presence cells,
       "expected" = all 6,969 model cells; the index is the Spearman
       correlation of the ratio and the window centre;
     - the test AUC: the test presence cells against the test background
       cells;
     - OR10: the share of the test presence cells below the 10th
       percentile of the predictions at the training presence cells
       (`SDM_OR_QUANTILE`);
     - AUCdiff: the training AUC of the fold model − its test AUC.
   - **Reported:** each metric for each fold, with the number of test
     presence cells; the mean and the SD over the folds; and the training
     AUC of the main model.
8. **The gate (g2).** If the mean test Boyce index over the folds is 0 or
   below (`SDM_BOYCE_GATE`), the result is not published as a suitability
   map. The docs then say that the model is no better than a random model,
   and Stage 3 gives the effort result. The gate is applied in Week 15,
   before any figure. Above 0, the metrics are published with the map.
9. **The reserve check (r3), run in Week 15.** The prediction of the main
   model (cloglog, with clamping). A **reserve value** is the mean of the
   predictions over the complete-case 1 km cells inside the reserve polygon
   (`boundary_reserves_all_7755.gpkg`; an edge counts), each 1 km cell with
   the value of its 0.2° cell. A cell in two overlapping polygons counts in
   each (as process choice o1 of task 13.8).
   - **r1 — census density:** the Spearman ρ between the reserve value and
     the 2022 census density (`density_2022`, Decision 8) over the
     reserves with a polygon and a value. Reported: ρ, n and the two-sided
     p-value. The reading: "agrees" if ρ > 0 and p < 0.05
     (`SDM_RESERVE_P`); otherwise "no agreement shown".
   - **r2 — reserves with no presence cell:** a reserve has a presence cell
     if one or more of its complete-case 1 km cells is in a presence cell.
     For the reserves with none, the share whose value is above the median
     prediction of the 6,969 model cells. Reported: counts and the share
     only. **No reserve name is linked to a presence or no-presence
     state** (Decision 22 point 9).
10. **Sensitivity runs (s3).** Two runs, each with the selected feature
    classes and multiplier of point 4:
    - **`bias_settlement` (b2):** the main data plus `settl_mean`, the mean
      of `kde_settlement_citytown_1km_7755.tif` over the complete-case 1 km
      cells of the cell, as a bias covariate (Warton et al. 2013). Point 3
      does not apply to it. At prediction, `settl_mean` is fixed at its
      median over the 6,969 model cells (`SDM_SENS_BIAS_FIX`).
    - **`window_2018_2022`:** the presence cells of the obscured records of
      2018–2022 (`SDM_SENS_WINDOW` = `CURRENT_WINDOW`) and the background
      cells of the background records (both parts) of 2018–2022, on the same
      model cells. The limits of Decision 23 points 4 and 6 apply to this
      run: below 25 presence cells, or below a background of 10 times its
      presence cells, the run is not made and the docs say so; from 25 to 79
      presence cells, the feature classes are `lq` at most.
    - **Comparison with the main model** (cloglog over the 6,969 model
      cells): the Spearman ρ, and the share of the main model's top 20 % of
      cells (`SDM_SENS_TOP_SHARE`) that are also in the top 20 % of the run.
      "Robust" if ρ ≥ 0.9 and the share ≥ 2/3 (`SDM_SENS_RHO_MIN`,
      `SDM_SENS_OVERLAP_MIN`; the values of Decisions 18 to 20); otherwise
      "sensitive".
    - The sensitivity sets of Decision 21 point 9 are not run (Decision 23
      point 2).
11. **Model file (m1).** `save_model(..., species = "tiger", model =
    "sdm_maxnet_cell02", dir = DIR_PROCESSED)` →
    `data/processed/tiger_sdm_maxnet_cell02_<date>.rds` (gitignored;
    `SDM_MODEL_DIR`). It holds the main model and a list of the settings
    (the covariates kept, the feature classes, the multiplier, the AICc
    table). The QA checks that no part of the saved object (at any depth)
    is a vector or a matrix with the length or the number of rows of the
    data rows (presence and background cells). The check "no file with
    'tiger' in its name under `outputs/`" stays as it is.

**What was seen before this Decision (pre-registration, stated plainly):**
- **In the documents (the author and the chat):** each count of
  `tbl_16_sdm_counts.csv` (104 presence cells; 1,486 background cells; 6,969
  model cells; 18 presence cells with no background record); the values of
  `tbl_10_covariate_stack_qa.csv` (for example the elevation range −434.168
  to 7,843.875 m and the slope maximum 42.334°); each count of the `tbl_15`
  tables, among them the obscured set of 2018–2022 (454 records in 71 cells
  of 0.2°, before the model-cell rule).
- **By the author:** the consoles of Weeks 13 and 14. The author stated on
  2026-10-25 that the two statements of Decision 23 still apply: no density
  surface or point layer was looked at on a map, and values from a console
  that are not in the documents are not remembered.
- **By the chat that drafted this Decision:** the documents, the scripts,
  the committed count tables, the `maxnet` source code and the literature.
  No data file and no map.
- **Not computed by anyone:** a covariate summary at 0.2°, a correlation of
  the covariates, a model, a prediction, a block or fold count.
- **Post-seen in principle:** fork f (the chat knew n = 104 when it wrote the
  grid and the rule K ≥ n − 1) and fork s (the 71 cells of the obscured set
  of 2018–2022 were known).
- **The choices.** The chat gave one recommended option for each fork. The
  author took it for each fork.

**Result of the run (task 14.5, `scripts/09` STEP 14.2, run on the
project machine on 2026-10-25; facts, not a reading):**
- The hand-made case of STEP 14.2 passed (23 of 23 checks). `maxnet` 0.1.4
  and `glmnet` 5.0 (in `renv.lock` after the run). STEP 14.2 took 0.2
  minutes.
- **Covariates (points 1 and 2):** one row for each of the 6,969 model
  cells (`data/processed/sdm_covariates_cell02.csv`). The water rule took
  46,183 water 1 km cells out of the terrain means; 551 1 km cells got the
  elevation floor of 0 m; 1 model cell has water cells only, and its
  terrain means use them.
- **Collinearity (point 3):** 7 of the 36 pairs have |r| > 0.7. **Kept (6):**
  `ghm_mean`, `lc_forest`, `elev_mean`, `lc_open`, `droad_km_mean`,
  `lc_built`. **Removed (3):** `slope_mean` (r = −0.710 with `ghm_mean`;
  0.847 with `elev_mean`), `tri_mean` (−0.715; 0.841), `lc_crop` (0.842
  with `ghm_mean`; −0.724 with `lc_forest`).
  - **Stated plainly:** the note of point 1 expected that point 3 keeps one
    of slope and TRI. It kept neither: each has |r| > 0.7 with `elev_mean`,
    which comes before them in the order. The terrain is in the model as
    `elev_mean` only.
- **AICc (point 4):** each of the 12 models got an AICc (K from 8 to 31; n
  = 104). **Selected: `lq`, multiplier 1** (K = 10, AICc 1,724.30). No
  other model is within 2: the next are `lq` with multiplier 2 (ΔAICc
  9.42) and `lqph` with multiplier 4 (9.55). The `maxnet` default (`lqph`,
  multiplier 1) has ΔAICc 48.63. The selected multiplier is the lowest
  value of the grid.
- **Main model (points 5 and 6):** the selected model of the grid, on the
  104 presence cells and the 1,486 background cells; training AUC 0.806.
- **Block cross-validation (point 7):** 98 blocks of 2° hold a presence or
  a background cell; 19 or 20 blocks per fold. Test presence cells: 26, 23,
  22, 17 and 16 (104 in total). Values rounded to 3 decimals (the full
  values are in `tbl_16_sdm_cv.csv`):

  | Metric | Fold 1 | Fold 2 | Fold 3 | Fold 4 | Fold 5 | Mean | SD |
  |---|---|---|---|---|---|---|---|
  | Boyce index | 0.796 | 0.779 | 0.362 | 0.702 | 0.703 | 0.668 | 0.177 |
  | Test AUC | 0.837 | 0.798 | 0.655 | 0.681 | 0.775 | 0.749 | 0.078 |
  | OR10 | 0.077 | 0.217 | 0.227 | 0.176 | 0.125 | 0.165 | 0.064 |
  | Training AUC | 0.786 | 0.804 | 0.832 | 0.813 | 0.811 | 0.809 | 0.017 |
  | AUCdiff | −0.052 | 0.006 | 0.177 | 0.132 | 0.036 | 0.060 | 0.093 |

- **The value for the gate (point 8):** the mean test Boyce index is
  0.668, above 0 (`SDM_BOYCE_GATE`). The gate is applied in Week 15, before
  any figure (point 8).
- **Sensitivity runs (point 10):**
  - `bias_settlement`: 104 presence cells, 1,486 background cells; `lq`,
    multiplier 1; ρ = 0.988, top-20 % share 0.931 → **robust**.
  - `window_2018_2022`: 71 presence cells (25–79, so `lq` at most) and
    1,229 background cells (minimum 10 × 71 = 710); `lq`, multiplier 1; ρ
    = 0.991, top-20 % share 0.896 → **robust**.
- **Model file (point 11):**
  `data/processed/tiger_sdm_maxnet_cell02_20261025.rds`. The object check
  passed before the save, and the file was read back.
- **Seen from this run on (for the Week-15 Decision on the prediction):**
  the console text of STEP 14.2 and the five tables, by the author and the
  chat. No prediction is written to a file and no map was made: the
  predictions of the AICc grid, the folds and the sensitivity runs are
  computed in memory only.
- Process choices, implementation points, tests and outputs: change log,
  2026-10-25, task 14.5.
- *(2026-11-01, Week 15: the gate (point 8) is open, and the reserve check
  (point 9) reads "agrees" (ρ = 0.379, n = 51, p = 0.00614); r2 is not
  published under Decision 25 point 9. The facts: Decision 25, "Result of
  STEP 15.1" and "Result of STEP 15.2".)*
- **QA (task 14.6, 2026-10-25):** STEP 14.3 computed the cell counts, the
  covariates of the 6,969 model cells (`terra::zonal()`), the correlations,
  AICc and K of the selected model (from the model file) and the training
  AUC (Wilcoxon) again by a second path. 133 of 133 checks pass (change
  log, task 14.6).

**Reason and sources:**
- **Shares, not the modal class (c1).** A cell of about 450 km² holds many
  classes; a modal class keeps one of them. Herbaceous wetland is in
  `lc_open` because the tall grasslands of the Terai are partly in that
  class; mangroves are in `lc_forest` for the Sundarbans.
- **Water (z1).** The elevation of the source tiles over the sea is a
  depth (`tbl_10` minimum −434.168 m; India's lowest land is about −2 m),
  and the slope and TRI of those cells come from the sea floor. The
  Sundarbans hold much water.
- **0.7 (k1).** In a simulation study, |r| > 0.7 was "an appropriate
  indicator" of when collinearity starts to distort the estimates and the
  prediction (Dormann et al. 2013). The order of the list keeps the human
  pressure index and forest first; slope is above TRI because it does not
  depend on the units of the DEM.
- **AICc and not the cross-validation (f3).** With the folds of point 7
  used to choose the model, the same folds would choose and test it. AICc
  uses all data and the likelihood over the study area (Warren & Seifert
  2011; the ENMeval method, which counts the non-zero coefficients as "an
  estimate of the true degrees of freedom"). The default regularisation of
  Maxent can overfit (Radosavljevic & Anderson 2014). The grid holds the
  default (`lqph`, multiplier 1), so the result is at least as strict as
  the default (Decision 23 point 4).
- **No bias covariate in the main model (b1).** The target-group background
  already has the bias of the observer group (Phillips et al. 2009). A bias
  covariate on top of it corrects the bias two times; the run of point 10
  shows how much the choice changes the result.
- **Blocks (v1).** Random cross-validation of data with structure can give
  a "serious underestimation of predictive error" (Roberts et al. 2017); the
  presence cells are grouped in reserves. The serpentine order gives each
  fold a similar number of presence cells with no random seed.
- **Boyce index (v1, g2).** The continuous Boyce index evaluates
  presence-only predictions; a value near 0 means that a model does not
  differ from a chance model (Hirzel et al. 2006). AUC with a background
  measures how presence cells differ from sampled cells, not from absences.
- **Census density (r3).** The census does not use GBIF records, so r1 is
  a check that does not use the presences. r2 uses the reserves where the
  model had no presence cell.
- **Two sensitivity runs (s3).** The bias choice (pending point 5) and the
  time: 51 % of the obscured records are from 2018–2022 and the covariates
  are from 2021–2022.
- **The model file under `data/` (m1).** Each file made from the tiger
  records stays under `data/` (Decision 22 point 9). The `maxnet` object
  holds the coefficients and summary statistics (`samplemeans`, the
  minimum and maximum of each covariate and feature), not the data rows
  (`maxnet.R`, read 2026-10-25).

**Judgement values:** 0.7 (|r|) and the order of the list; the grid of
feature classes and multipliers; 2 (ΔAICc); 2° blocks and 5 folds; 0.1 and
100 (Boyce window and points; the recommendation of Hirzel et al. 2006 for
the window); 10 % (OR10); 0 m (elevation floor); the median (the fixed bias
value); 0.05 (the reading of r1); 20 % (top cells). From earlier Decisions:
0.9 and 2/3 (Decisions 18 to 20).

**Rejected:**
- *c2 — forest and built shares only; c3 — the modal land-cover class.*
- *z2 — negatives set to 0 with no water rule; z3 — no elevation.*
- *k2 — |r| > 0.8; k3 — no collinearity check.*
- *f1 — the default only; f2 — `lqh` with multiplier 2; f4 — selection by
  the cross-validation.*
- *b2 for the main model; b3 — the effort surface as a covariate.*
- *a2 — no presence cell added to the background.*
- *v2 — four bins by latitude and longitude lines; v3 — random folds.*
- *g1 — no gate; g3 — a higher gate.*
- *r1 or r2 alone.*
- *s1 — no run; s2 — the bias run only.*
- *m2 — `outputs/models/` with an exception in the check.*

**Limitations:**
- A covariate is a summary over about 450 km². A tiger uses parts of a
  cell; the summary does not show which.
- The land cover is of 2021 and the human pressure of 2022.
- K counts the non-zero coefficients, which is an estimate of the degrees
  of freedom (ENMeval documentation).
- The block size is a judgement value. The range of spatial
  autocorrelation was not estimated.
- The continuous Boyce index depends on the output scale and the window.
- r1 is partly linked to the presences (a reserve with many tigers probably
  has many visitors), and the census density is per notified total area
  while the polygon is the core protected area (Decisions 4 and 8).
- r2 depends on a coarse rule: a 0.2° cell can touch more than one reserve.
- The sensitivity runs test two choices only.
- A bias covariate at a fixed value assumes that the bias acts the same way
  at each cell (Warton et al. 2013).
- The numbers in "Judgement values" are judgement values.

**Consequences:**
- `R/00_config.R`: a new block "Stage 3: model settings (Decision 24)" with
  the `SDM_*` settings of this Decision. No other value changes.
- `scripts/09` STEP 14.2 (task 14.5), with `RUN_GRID = FALSE`: the
  covariate summaries; the correlation check; the AICc grid; the main
  model; the cross-validation; the two sensitivity runs; the model file;
  `tbl_16` tables (statistics only). Process choices of task 14.5 first:
  the table slugs; whether the covariate table of the model cells is
  written (`data/processed/`, no presence flag); the Boyce function (own
  code or a package); run switches; `maxnet` in `renv.lock` (snapshot after
  the first run of the STEP).
- QA (task 14.6) adds: hand-made cases for the covariate summary (a known
  cell with known classes and values, a water cell, a cell with water only),
  for the collinearity rule, for AICc (a known small case), for the fold
  assignment, and for the Boyce index (a known ranking); the model-file
  check of point 11; no position or cell column in a `tbl_16` table; the
  check of Decision 23 point 7 (the Facebook dataset).
- Week 15: a numbered Decision on the prediction (the output type and
  clamping of the published map, its classes and form) before any map;
  then the gate of point 8 and the reserve check of point 9.
- The Gi* Decision of Decision 23 point 8 (Week 15 or 16) is not changed.

This closes the **[Week 14] Model Decisions that Decision 21 names** pending
item (point (2) by point 10; points (4) and (5) by points 5 and 10; the Gi*
settings of point (6) go to a new pending item) and the **[Week 14] Terrain
variables in the SDM** item (points 1 to 3).

### Decision 25 — Prediction and publication: model file and output, cells outside the training range, classes, published form, caption, figures, reserve table, cells of the reserve check
**Date:** 2026-10-31 (fixed **before** any prediction is written to a file
or seen — see "What was seen before this Decision")
**Choice:** Settings in `R/00_config.R` (a new block "Stage 3: prediction
and publication (Decision 25)" after the QA block of task 14.6). `scripts/09`
applies them in Week 15 (tasks 15.3–15.5); the two figures and the caption
drafts are made in Week 16. Fork codes as raised and chosen on 2026-10-31:
a1, b2, c1 (with n5), d1, e1, f3 (two figures, the legend label, the hatch
on both), t1, h1; point 9 (added in task 15.2 on 2026-10-31, before any
result): y1, z1. *(Earlier Decisions use some of the same letters. Write
the Decision with the code, for example "Decision 25 b2".)*

**Fixed by earlier Decisions (not forks; stated here so that the record is
complete):**
- The prediction cells are the 6,969 model cells only (Decision 23 point
  3). The 481 other cells of the grid get no value.
- The gate (Decision 24 point 8): the mean test Boyce index is 0.668, above
  0, so the gate allows a suitability map. Week 15 states this in a table
  and in the console.
- The reserve check (Decision 24 point 9): r1 and r2, on the cloglog values
  with clamping. Point 8 below is a reading of point 9. The text of
  Decision 24 does not change.

1. **Model file, output type and clamping (a1).**
   - The prediction uses the model file of the record,
     `data/processed/tiger_sdm_maxnet_cell02_20261025.rds`
     (`SDM_PRED_MODEL_FILE`). It does not use a model that a later run of
     `scripts/09` fits again.
   - The input is the six kept covariates of the 6,969 model cells
     (`sdm_covariates_cell02.csv`; Decision 24 points 1–3).
   - Output type: cloglog (`SDM_PRED_TYPE` = `SDM_EVAL_TYPE`), with
     clamping (`SDM_PRED_CLAMP` = `TRUE`, the `predict.maxnet()` default).
   - The classes (point 3), the value figure (point 6), the reserve values
     (points 7 and 8) and the counts of point 2 all use these values. No
     other output type is published.
2. **Cells outside the training range (b2).**
   - The training range of a covariate is its minimum and its maximum over
     the data rows of the main model (the 104 presence cells and the 1,486
     background cells), as the model object holds them (`varmin`,
     `varmax`). Clamping holds each covariate and each feature in its
     training range.
   - A model cell is **outside the training range** if one or more of its
     six covariates is below `varmin` or above `varmax`
     (`SDM_PRED_FLAG_RANGE` = `TRUE`). A value equal to a limit is inside.
     - These are the cells where clamping can change the value.
     - They are also the cells with a negative MESS when the reference set
       is the data rows (Elith et al. 2010).
     - The six covariates are 0 or more, so a quadratic feature is outside
       its range only when its covariate is outside its range.
   - **Reported** (statistics only): the number of model cells outside the
     range; for each covariate, the number below `varmin` and the number
     above `varmax`. No limit applies: the count is a result, not a rule.
   - In both figures (point 6), a cell outside the range keeps its class or
     its value and gets a hatch. The caption names the hatch and gives the
     count.
   - The reserve check uses the clamped values of all cells. This flag
     removes no cell.
   - By this definition, no presence cell and no background cell is outside
     the range. A hatched cell is thus a cell with no record of the model.
     The hatch does not mark a presence cell.
3. **Classes (c1, n5).**
   - Five classes (`SDM_PUB_N_CLASSES`) of equal count, by the rank of the
     cloglog value over the 6,969 model cells.
   - **Rank r:** 1 is the highest value; a tie goes to the lower cell id
     first (the order of `sdm_compare()`, Decision 24 point 10).
   - **Class:** K − floor(K × (r − 1) / n), with K = 5 and n = 6,969. Class
     5 holds the highest values. With n = 6,969, classes 5, 4, 3 and 2 hold
     1,394 cells each and class 1 holds 1,393 cells (arithmetic, not a
     result).
   - Class 5 is the same set of cells as the top 20 % of the sensitivity
     rule (ceiling(0.2 × n) = 1,394 cells, in the same order).
   - **Legend:** the classes by rank, from "highest 20 % of model cells" to
     "lowest 20 % of model cells". The legend gives no cloglog value.
   - 5 is a judgement value inside the range of 3 to 7 classes that the
     cartography texts give for a simple map. No source fixes the number
     for a suitability map.
4. **Published form, tier and check (d1).**
   - **Week 15 publishes no layer.** The prediction layer stays under
     `data/processed/` (gitignored). It holds, for each model cell, the
     cell id, the cloglog value, the class and the flag of point 2, and no
     presence or background field. Task 15.2 names the file.
   - The published forms are the two static figures of point 6 (national
     scale, Week 16), the reserve table of point 7 and tables of
     statistics.
   - A layer that a reader can zoom or download (the Stage-4 maps) waits
     for a rule in Week 18. The pending item "[Week 18] Published path
     layer" becomes "[Week 18] Published layers" and includes this surface.
   - **Tier T1** (sensitive-data policy §2: public data that the source
     obscured; "normal use; document the obscuring"). The caption says
     that the presences are obscured records (point 5, item 3).
   - **Check:** the figure code reads only the prediction layer of this
     point and the grid layer. Neither has a presence or a background field
     (Decision 23 point 9: the published form must not mark the presence
     cells). The check is written with the figures in Week 16.
5. **Caption content (e1).** The caption of each figure holds all of these
   items, as the caption of `fig_03` does. The caption text is drafted in
   Week 16 and marked as a draft (the narrative is the author's).
   1. Relative suitability from a `maxnet` model at the 0.2° grain (cells
      of about 20 km; 396–488 km² in India).
   2. Not occupancy (Decision 1), and not a probability of presence.
   3. The presences: the obscured iNaturalist tiger records, in 104 cells
      of 0.2° (obscured by the source; point 4). The background: the
      iNaturalist mammal records, in 1,486 cells. The effort caveat
      (proposal §7).
   4. How to read the figure: for `fig_04`, the classes by rank; for
      `fig_05`, the legend label of point 6. For both: the top-20 % overlap
      of each sensitivity run with the main model (0.931 and 0.896).
   5. The evaluation: a mean test Boyce index of 0.668 over 5 folds of 2°
      blocks, with the tie rule of implementation point 3 of Decision 24
      (not the `ecospat.boyce()` default), and a mean test AUC of 0.749.
   6. The hatch: outside the training range of one or more covariates
      (point 2), with the count. A blank cell: not a model cell (less than
      50 % complete-case cover).
   7. The reserve outlines are the core protected-area polygons (Decision
      4), not the notified total area.
   8. The reading of r1 of the reserve check, with ρ, n and p (Decision 24
      point 9).
   9. The data sources.
6. **Figures (f3: two figures).**
   - **`fig_04_<slug>.png`** (`SDM_PUB_FIG_CLASS` = 4): the five classes of
     point 3.
   - **`fig_05_<slug>.png`** (`SDM_PUB_FIG_VALUE` = 5): the cloglog value of
     each model cell on a continuous colour scale. The legend label is
     "model output (cloglog), relative; not a probability of presence"
     (`SDM_PUB_VALUE_LABEL`). The caption holds the same item (point 5,
     item 2).
   - **Both figures:** the 0.2° model cells, the hatch of point 2
     (`SDM_PUB_HATCH`), the reserve outlines and the state boundaries, at
     national scale. No presence mark, no background mark, no point. The
     sensitivity runs are numbers in the caption, not maps.
   - The slugs, the colours and the size are set in Week 16. A slug does
     not hold the word "tiger" (the QA check "no file with 'tiger' in its
     name under `outputs/`").
7. **Reserve table (t1).** One published table with one row for each
   reserve of `boundary_reserves_all_7755.gpkg` (58 rows, as
   `tbl_15_occ_by_reserve.csv`), keyed on `unit_id`
   (`SDM_PUB_RESERVE_TABLE` = `TRUE`). Content:
   - `unit_id`, `unit_name`, `state`;
   - the reserve value (point 8) and its rank among the reserves with a
     value (1 = the highest);
   - `density_2022` (Decision 8; `stats_reserve_census_7755.gpkg`);
   - the number of 1 km cells that the value uses, and the number of 1 km
     cells inside the polygon with no value (point 8).
   - A reserve with no polygon, or with no 1 km cell that has a value, has
     no value and no rank.
   - **No presence column.** r2 stays as counts and a share only (Decision
     24 point 9), with the rule of point 9.
   - The table number, the slug, the column names, the rounding and the
     tie rule of the rank are process choices of task 15.2.
8. **Cells of the reserve check (h1; a reading of Decision 24 point 9).**
   - **Inside:** a complete-case 1 km cell is inside a reserve polygon if
     its centre is inside the polygon or on its edge
     (`SDM_RESERVE_CELL_RULE` = `"centre"`). This is the literal reading of
     point 9 ("inside the reserve polygon …; an edge counts") and the rule
     for a record of task 13.8.
   - **A 1 km cell whose 0.2° cell is not a model cell** has no value
     (42,467 complete-case 1 km cells are in the 481 such cells; Decision
     23, the count of task 14.4). It is left out of the mean, and the
     number of such cells is reported for each reserve
     (`SDM_RESERVE_NONMODEL` = `"exclude_and_count"`).
   - A reserve with no 1 km cell that has a value gets no reserve value. It
     is not in r1 or r2.
   - A cell in two overlapping polygons counts in each (Decision 24 point
     9).
9. **The presence state of a reserve in the published outputs (y1, z1).**
   *(Added 2026-10-31 in task 15.2, before any result. The chat found the
   gap after points 1–8 were recorded.)* Decision 24 point 9 says that no
   reserve name is linked to a presence or no-presence state. Two
   combinations of points 2, 4, 7 and 8 can make that link.
   - **r2 and the reserve table (y1).**
     - The reserve table gives the value of each named reserve (point 7),
       and `tbl_16_sdm_prediction.csv` gives the median of the model cells.
       Over the reserves with a value, take the 2 × 2 count: value above
       the median or not (a value equal to the median is "not above") ×
       with or without a presence cell.
     - A count of 0 links each reserve of its row to one state. A count of
       1 or 2 almost does.
     - **Rule:** r2 (its counts and its share) is published only if each of
       the four counts is 3 or more (`SDM_PUB_R2_MIN_N` = `KDE_SMALL_N`, the
       value of Decision 22 point 9). Here 0 is also below the limit.
     - Otherwise `tbl_16_sdm_reserve_check.csv`, the console and the docs
       say "r2 not published (a count below 3)". They give no count of r2
       and no count of the 2 × 2 table.
   - **A state that follows from the figures or the table (z1).** STEP
     15.2 counts the reserves with a polygon of two kinds:
     - (a) one or more 1 km cells with a value, and each of them in a cell
       outside the training range (a hatched cell has no record, point 2);
     - (b) no 1 km cell with a value (no presence cell is outside the model
       cells: Decision 23, the count of task 14.4).
     - The count of each kind goes into the QA of STEP 15.3. If the total is
       above 0, the check fails and the script stops. The author then
       decides, before the figures and before the commit of the reserve
       table.
     - The QA table holds the counts only. The console gives the names of
       these reserves only when the check fails, marked "not for the docs".
     - This count uses the grid and the flag of point 2. It uses no
       suitability value.
   - The text of Decision 24 does not change.

**What was seen before this Decision (pre-registration, stated plainly):**
*(Point 9: added in task 15.2 on 2026-10-31. Nothing more was seen; no
prediction exists.)*
- **In the documents (the author and the chat):** each value of Decision 24
  "Result of the run" and of the `tbl_16` tables as the documents quote
  them: the counts (104 presence cells, 1,486 background cells, 6,969
  model cells; 42,467 complete-case 1 km cells in the 481 other cells); the
  kept covariates; the AICc table; the cross-validation metrics by fold
  (mean test Boyce 0.668, mean test AUC 0.749); the sensitivity ρ and
  top-20 % overlaps (0.988 and 0.931; 0.991 and 0.896); the QA, 133 of 133.
- **By the author:** the consoles of Week 14. The author stated on
  2026-10-31 (fork g of this Decision): (g1) no prediction, no covariate
  table and no grid was looked at in a map viewer; (g2) no value from the
  Week-14 consoles that is not in the documents is remembered.
- **By the chat that drafted this Decision:** the documents,
  `R/00_config.R`, the seven function files in `R/`,
  `scripts/09_model_suitability.R`, the `maxnet` documentation and the
  literature. The `tbl_16` files were not attached: the chat saw their
  values only as the documents quote them. No data file and no map.
- **Not computed or not seen by anyone:** a prediction written to a file,
  a class break, a count of cells outside the training range, a reserve
  value, the reserve check, a map. The predictions of STEP 14.2 (the AICc
  grid, the folds, the sensitivity runs) were made in memory only, and the
  console gave statistics only.
- **Post-seen in principle:**
  - Fork c: class 5 is the top 20 % of the sensitivity rule, and the
    overlaps of that set (0.931 and 0.896) were known when n5 was chosen.
  - Fork b: the chat knew that the background covers 21 % of the model
    cells (1,486 of 6,969), and said that some model cells are probably
    outside the training range (not checked).
  - The gate value (0.668) was known. Each fork assumes a map.
- **The choices.** The chat gave one recommended option for each fork.
  - The author took it for forks a, b, c (n5), d, e, t and h, and for two
    of the three points of f3 (the legend label; the hatch on both
    figures).
  - **Not the chat's recommendation:** f3 (the chat recommended f1, the
    class map only) and the form of f3 (the chat recommended one PNG with
    two panels; the author chose two figures).
  - The author asked for references on the number of classes before the
    choice n5.
  - Point 9 (task 15.2): the author took the chat's recommendation, y1 and
    z1, and the recording of the two forks as a point of this Decision.

**Result of STEP 15.1 (task 15.3, `scripts/09`, run on the project
machine; console text sent on 2026-11-01; facts, not a reading):**
- `RUN_FIT` = `FALSE` (w1 of task 15.2): STEP 14.2 was skipped, and STEP
  14.3 read the model file of the record: QA 133 of 133. The hand-made case
  of STEP 15.1 passed (18 of 18).
- **The gate (Decision 24 point 8):** the mean test Boyce index is 0.668,
  above 0. The gate allows a suitability map. `tbl_16_sdm_prediction.csv`
  and the console state it.
- **The prediction (point 1):** `tiger_sdm_maxnet_cell02_20261025.rds`; six
  covariates (`ghm_mean`, `lc_forest`, `elev_mean`, `lc_open`,
  `droad_km_mean`, `lc_built`); `lq`, multiplier 1; 6,969 model cells,
  cloglog with clamping. The values: minimum 2.139e−13, median 0.2898,
  maximum 0.9998.
- **The classes (point 3)** (values to 4 significant digits; the full
  values are in `tbl_16_sdm_prediction.csv`):

  | Class | Cells | Ranks | Lowest value | Highest value |
  |---|---|---|---|---|
  | 5 (highest 20 %) | 1,394 | 1–1,394 | 0.6037 | 0.9998 |
  | 4 | 1,394 | 1,395–2,788 | 0.362 | 0.6032 |
  | 3 | 1,394 | 2,789–4,182 | 0.2257 | 0.3618 |
  | 2 | 1,394 | 4,183–5,576 | 0.09924 | 0.2255 |
  | 1 (lowest 20 %) | 1,393 | 5,577–6,969 | 2.139e−13 | 0.09922 |

  No cell is in a tie across a class break.
- **Cells outside the training range (point 2):** 32 of 6,969. By
  covariate: `ghm_mean` below the minimum, 20; `elev_mean` below the
  minimum, 5, and above the maximum, 1; `lc_open` above the maximum, 7; no
  other covariate. The counts by covariate add up to 33, so one cell is
  outside on two covariates. No presence or background cell is outside
  the range (the guard of STEP 15.1 passed).
- **The layer (point 4; l1 of task 15.2):**
  `data/processed/sdm_prediction_cell02.csv`, 6,969 rows, written and read
  back.
- **Seen from this run on:** the console text of STEP 15.1 (statistics
  only), by the author and the chat. No map was made, and no reserve value
  exists yet.
- **For point 9 (z1), a fact and not a reading:** 32 cells are hatched, so
  a reserve of kind (a) is possible. STEP 15.2 (task 15.4) counts it.

**Result of STEP 15.2 (task 15.4, `scripts/09`, run on the project
machine; console text sent on 2026-11-01; facts, not a reading beyond the
rules of Decision 24 point 9):**
- The hand-made case of STEP 15.2 passed (17 of 17).
- **Reserves:** 58 rows; 56 with a polygon; 56 with a value (each reserve
  with a polygon has one or more 1 km cells with a value); 52 with a
  `density_2022`; 51 with a value and a density (Pilibhit has a density
  and no polygon).
- **The cells of point 8:** 42,713 1 km cells used, summed over the
  reserves (a cell in two polygons counts in each); 1,564 1 km cells in a
  0.2° cell that is not a model cell, in 6 reserves (Namdapha 454,
  Sundarbans 445, Manas 260, Valmiki 203, Dudhwa 193, Buxa 9).
- **r1 (Decision 24 point 9):** Spearman ρ = 0.379, n = 51, two-sided p =
  0.00614 (`exact = FALSE`). The reading of the rule: **"agrees"** (ρ > 0
  and p < 0.05).
- **r2 (Decision 24 point 9 with point 9 of this Decision):** **not
  published** (a count of the 2 × 2 table is below 3). The reason follows
  from the published tables, not from a presence state: 55 of the 56
  reserves with a value are above the median of the model cells (0.2898),
  so the row "not above" holds 1 reserve.
- **z1 (point 9):** kind (a) 0, kind (b) 0, total 0. No name was printed.
- **Tables:** `tbl_16_sdm_reserve_check.csv` (14 rows) and
  `tbl_17_reserve_suitability.csv` (58 rows; 2 with no value: Pilibhit
  and Dholpur-Karauli, no polygon).
- **Seen from this run on:** the console text of STEP 15.2, with the value
  and the rank of each reserve (the content of `tbl_17`), by the author and
  the chat. No map was made.

**Result of STEP 15.3, the QA (task 15.5, `scripts/09`, run on the project
machine; console text sent on 2026-11-01; facts):**
- **84 of 84 checks pass** (`tbl_16_sdm_pred_qa.csv`): test case 45 (the
  hand-made cases of STEPs 15.1–15.3: 18, 17 and 10), prediction 9,
  classes 5, reserves 6, r1 2, r2 1, z1 2, info 1, publish 13.
- **The second path agrees:** the values by hand from the model file; the
  flag; the ranks, the classes and the class sizes; class 5 = the top set
  of the sensitivity rule; the 1 km cells of each reserve by
  `terra::extract()` (no reserve differs from the centre rule of point 8);
  the reserve values and ranks; r1; the rule of point 9 for r2 (not
  published); z1 total 0.
- **The publish checks of the Week-15 tables pass** (c1 of task 15.2).
- **Information count** (the author's choice of task 15.5; not a check):
  1 reserve has valued 1 km cells outside the training range — Mukundara
  Hills, 19 of its 316 1 km cells (one 0.2° cell is hatched). The other 55
  reserves with a value use no cell outside the range; among them the
  Sundarbans, which has the highest reserve value.
- *(2026-11-01, task 15.6: the author chose m1 — `tbl_17` and the caption
  items of point 5 do not change. The docs record the fact; the figures
  show the hatch, and caption item 6 gives the count of hatched cells.
  Rejected: m2, a column of the cells outside the range in `tbl_17`; m3,
  one more caption item.)*

**Reason and sources:**
- **One model file and one output type (a1).**
  - The evaluation (Decision 24 point 7) and the reserve check (point 9)
    use cloglog with clamping. One type for each output keeps the outputs
    the same.
  - The Maxent output types are "monotonically related, but they are
    scaled differently" (Phillips 2017). A class by rank is thus the same
    with each type. A mean (the reserve value) and the colour scale of
    `fig_05` change with the type.
  - The record names the file that the prediction used. Each run of
    `scripts/09` fits the models again and writes one more dated file (w1
    of task 14.5).
- **Clamping and the flag (b2).**
  - With clamping, "predictors and features are restricted to the range
    seen during model training" (`maxnet` reference manual). With no
    clamping (b4), a quadratic term outside the data range can go far up or
    down.
  - A negative MESS marks a site where one or more variables are outside
    the range of the reference set (Elith et al. 2010). The hatch shows the
    reader where the model extrapolates. With b3, the map and the reserve
    check would use different cells.
- **Classes by rank, no value in the legend (c1).**
  - Presence–background data "must be augmented with an additional datum,
    e.g., species' prevalence, to reliably estimate absolute (rather than
    relative) probability of presence" (Phillips & Elith 2013). From
    presence-only data, one cannot learn the prevalence "without making
    unjustified simplifying assumptions" (Hastie & Fithian 2013).
  - Fixed breaks on the value (c2) or a threshold (c3) would give the value
    a meaning that it does not have.
- **Five quantile classes (n5).**
  - Quantile and minimum-boundary-error classes gave the best results for
    general map-reading tasks, and careful optimisation gave "no benefit
    over the simpler quantile method" (Brewer & Pickle 2002).
  - For a simple map, cartographers recommend 3 to 7 classes (Slocum et
    al., as Lei et al. 2023 cite them). The estimates of the number of grey
    shades that a reader can tell apart are near "seven, plus or minus two"
    (Gilmartin & Shelton 1990).
  - Five classes make class 5 the set of the sensitivity rule.
  - n4 (four classes from the P/E curve of the Boyce index; Hirzel et al.
    2006, and four classes in Hirzel et al. 2007) would set the breaks from
    the presences, after the curve is seen (post-result), with unequal
    counts. n7 would make the top class 14.3 % of the cells, not the set of
    the sensitivity rule.
- **No layer before Week 18 (d1).**
  - As for the paths (Decision 20 point 7; policy §3): a layer that a reader
    can zoom or download needs its own rule first.
  - `assert_publishable_rast()` compares the cell size with 1,000 map
    units. A 0.2° raster in EPSG:4326 has a cell size of 0.2, so the check
    refuses it. A 0.2° layer needs a new check. With d1 the check is not
    needed before Week 18.
- **All items in the caption (e1).** Each published map states its effort
  caveat (proposal §7). Above the gate, the metrics are published with the
  map (Decision 24 point 8). The Boyce value of this project is not the
  `ecospat.boyce()` default (Decision 24, implementation point 3). The
  caption of `fig_03` holds all its items.
- **A value figure next to the class figure (f3; author choice).**
  - The value figure shows the differences inside a class.
  - Cloglog "estimates probability of presence assuming that the sampling
    design is such that typical presence localities have an expected
    abundance of one individual per quadrat" (Phillips 2017). A Maxent
    user-group answer calls cloglog "an estimate of suitability" when these
    assumptions are not met. The legend label and the caption item tell
    the reader this.
  - The hatch is on both figures: in `fig_05`, a clamped value looks like
    any other value.
- **Reserve table (t1).** Proposal question 3 asks whether modelled
  suitability agrees with where the reserves are; the values by reserve
  answer it. A reserve value is a mean of the published values over a
  public polygon. It holds no record and no presence state.
- **Centre rule; no value outside the model cells (h1).** It needs no new
  value, and the counts show the effect. `touches = TRUE` (h2) adds edge
  cells that are mostly outside the polygon. A cell that is not a model
  cell has no prediction (Decision 23 point 3).
- **The small-count rule for r2 (y1).** A count of 1 or 2 by reserve is
  not published (Decision 22 point 9), and "a published total can give a
  suppressed count" (handoff). In the 2 × 2 count, a 0 is a disclosure too,
  because it links a full row. y1 keeps r2 where it is safe; y2 would drop
  it in each case.
- **A check, not a rule, for the states that the outputs show (z1).** The
  count needs only the grid and the flag, so a choice made after it does
  not depend on a suitability value. With z2 the rule of Decision 24 point
  9 would have an exception that nobody decided.

**Judgement values:** 5 (the number of classes; inside the range of 3 to 7
that the cartography texts give); the text of the legend label. From
earlier Decisions: 20 % (`SDM_SENS_TOP_SHARE`, Decision 24; class 5 is that
set).

**Rejected:**
- *a2 — the model of each run; a3 — raw (exponential) or logistic output.*
- *b1 — the count only; b3 — no class for a cell outside the range; b4 — no
  clamping.*
- *c2 — fixed breaks on the cloglog value; c3 — two classes from a
  threshold; c4 — a continuous scale as the only map (f3 adds a value
  figure next to the classes). n4 — four classes from the P/E curve; n7 —
  seven quantile classes.*
- *d2 — a committed layer of the 0.2° cells with the class; d3 — a
  committed layer with the cloglog value.*
- *e2 — a short caption and a note file.*
- *f1 — the class figure only (the chat's recommendation); f2 — the class
  figure and two small maps of the sensitivity runs; one PNG with two
  panels (the chat's recommendation for the form of f3).*
- *t2 — statistics only.*
- *h2 — `touches = TRUE`; h3 — no reserve value if more than a set share of
  its 1 km cells has no value.*
- *y2 — r2 not published; y3 — r2 published in each case, with the risk
  recorded.*
- *z2 — accept the states that the outputs show, and record the count.*
- *The two forks as a new Decision 26 (the Gi* Decision would become 27).*

**Limitations:**
- The classes are relative to the 6,969 model cells. A cell in class 5 is
  in the top 20 % of the model cells of India; this is not "suitable" in an
  absolute sense. The classes have equal counts by construction, so the
  map gives no share of suitable land.
- The flag uses the range of each covariate alone. It does not show a new
  combination of values inside the ranges. It counts a covariate outside
  its range also when the model gives that covariate no weight.
- A hatched cell has no record of the model (point 2). The hatch thus shows
  cells with no presence and no background record. It does not show a
  presence cell.
- A legend label and a caption item cannot stop a reader from reading
  `fig_05` as a probability map.
- A tie at a class break puts equal values in two classes (the cell-id
  rule).
- A 0.2° cell can cover parts of more than one reserve and land outside
  them. A small reserve can take its value from one or two 0.2° cells.
- A reserve at the coast or at the national border can lose 1 km cells
  under point 8. The count in the reserve table shows how many.
- **y1 can hide r2.** Most reserves are probably above the median of all
  model cells (not checked). Then a count below 3 is likely, and r2 is not
  published.
- **The z1 check can stop the script.** A coastal reserve can have no
  1 km cell with a value (kind (b); not checked). The author then decides
  with the count known.
- The presence cells come from records that the source obscured (tier T1).
  A reader can get the presence state of a reserve from iNaturalist. Point
  9 follows the rule of Decision 24 point 9; it does not make that state
  secret.
- The number of classes and the legend text are judgement values.

**Consequences:**
- `R/00_config.R`: a new block "Stage 3: prediction and publication
  (Decision 25)". No other value changes. *(2026-10-31, task 15.2: point 9
  adds `SDM_PUB_R2_MIN_N`; two process choices add `SDM_PUB_RANK_TIES` and
  `SDM_RESERVE_P_EXACT`.)*
- **Task 15.2 (process choices, before code):**
  - How `scripts/09` uses the named model file: a switch that skips the 19
    fits (w2 of task 14.5), or a direct read of the file. With either,
    STEP 14.3 check m1 ("the model file of this run") must change.
  - The STEP numbers, the table slugs and the name of the prediction layer
    (`data/processed/`, gitignored).
  - The number of the reserve table. STEP 14.3 scans each `tbl_16_*.csv`
    (except the QA table) and stops on a reserve column or name (check s1)
    and on a number column that is not in its list (check (a)). The
    reserve table thus needs another number (`tbl_17` is the next free) or
    a change of the scan.
  - The publish check of the reserve table (no presence column, no cell
    id) and of the summary tables.
  - A hand-made case first (as h1 of tasks 14.4–14.6).
- **Task 15.3 (STEP 15.1):** the prediction, the classes, the flag and its
  counts; the gate stated.
- **Task 15.4 (STEP 15.2):** the reserve check with the cells of point 8;
  the reserve table of point 7.
- **Task 15.5 (STEP 15.3), QA:** hand-made cases for the class rule (a tie;
  n not a multiple of 5), for the flag (a value at a limit is inside) and
  for the cells of point 8 (a centre on an edge; a 1 km cell in a cell that
  is not a model cell); the prediction again from the model file by a
  second path; the class sizes; class 5 against the top set of
  `sdm_compare()`; no presence or background field in the prediction
  layer; no presence column in the reserve table. The number of cells in a
  tie across a class break can be reported. Point 9: hand-made cases for
  the r2 rule (a count of 0, of 2 and of 3) and for the two kinds of z1;
  the z1 count must be 0.
- *(2026-10-31: the process choices of task 15.2 are in the change log.)*
- **Week 16:** `fig_04` and `fig_05`; the caption drafts with the items of
  point 5 (marked as drafts); the check of point 4 written with the
  figures.
- **Week 18:** the pending item "[Week 18] Published layers" decides a
  layer of the surface that a reader can zoom or download.
- `naming-conventions.md` §6: `fig_04` and `fig_05` are reserved.

This closes the **[Week 15] Prediction and publication of the suitability
surface** pending item, and widens the **[Week 18] Published path layer**
item to **[Week 18] Published layers**.

### Decision 26 — Gi\*: aim, input sets, cells and value, neighbours and band, QA bands, test and correction, publication, time window, code
**Date:** 2026-11-07 (fixed **before** any Gi\* is computed and before any
neighbour list is made — see "What was seen before this Decision")
**Choice:** Settings in `R/00_config.R` (a new block "Stage 3: Gi\*
(Decision 26)" after the Decision-25 block; prefix `GISTAR_`). `scripts/09`
applies them in Week 16: the Gi\* in task 16.3, the figure `fig_06` in task
16.4, the QA in task 16.5. Fork codes as raised and chosen on 2026-11-07:
x1, a3, b1 (with C1-2), c1, d1 (with k1 and q2), e1, m1, f1, s2 (with L1
and S-a), w1, g1; the author's statements h1 and h2. *(Earlier Decisions
use some of the same letters. Write the Decision with the code, for example
"Decision 26 e1".)*

1. **Aim (x1).**
   - The Gi\* show where cells with records cluster. Each tiger Gi\* is
     compared with the effort Gi\* of its observer group (point 2). This is
     a part of the answer to proposal question 4.
   - There is no comparison with Phase 1 and no Phase-1 form. The author
     stated on 2026-11-07 that this project is not Phase 1. Decision 23
     point 8 said "in the Phase-1 form … for a comparison with Phase 1";
     this point narrows it. The text of Decision 23 does not change; a
     dated note there points here.
   - The tiger Gi\* are never published and never committed (Decision 23
     point 8; `SDM_GISTAR_PUBLISH_TIGER` = `FALSE`). Point 7 says what the
     docs can state.
2. **Four Gi\* (a3, b1, C1-2).**

   | Gi\* | Input | Compared with |
   |---|---|---|
   | `effort_inat` | b1: the background cells of Decision 23 point 5 (iNaturalist Mammalia, tiger excluded; parts (a) and (b)): 1,486 model cells, from before `maxnet` adds a presence cell | `tiger_obscured` |
   | `tiger_obscured` | the obscured set (Decision 21 point 4): 884 records in 104 model cells | `effort_inat` |
   | `effort_all` | C1-2: the clean background of all datasets, the 5 km set of Decision 22 point 2 (23,901 records; the input of the Decision-22 effort surface) | `tiger_5km` |
   | `tiger_5km` | the tiger 5 km set (Decision 21 point 3; 300 records in 44 cells of 1 km) | `effort_all` |

   - **The cell of a record of `effort_all` and `tiger_5km`:** the 0.2°
     cell of its own coordinates, by the cell rule of Decision 21 point 4
     (the coordinates in EPSG:4326 rounded down to a multiple of 0.2°).
     This is the rule of part (b) of the background of Decision 23. A
     record in a 0.2° cell that is not a model cell is not used; the script
     counts these records and their cells. *(Reading 1 of 2026-11-07,
     confirmed by the author.)*
   - The number of 0.2° cells of `effort_all` and of `tiger_5km` is not
     counted yet. The tiger 5 km set has 44 cells of 1 km, so it has 44
     cells of 0.2° or fewer.
   - **No presence cell goes into an effort input.** `effort_inat` is the
     1,486 cells of Decision 23 point 6, from before `maxnet` adds the 18
     presence cells with no background record (Decision 24 a1).
     `effort_all` holds no tiger record (Decision 5).
   - `tiger_5km` comes from precise positions (tier T2). `tiger_obscured`
     comes from records that the source obscured (tier T1). Part (a) of
     `effort_inat` is records of other mammals that the source obscured.
3. **Cells and value (c1).**
   - The cells: the 6,969 model cells of Decision 23 point 3
     (`sdm_grid_cell02_7755.gpkg`, `model` = `TRUE`). The 481 other cells
     of the grid are in no Gi\*.
   - The value of a cell: 1 if the cell holds one or more records of the
     input, otherwise 0. The number of records is not a weight (the unit
     rule of Decision 21 point 5, Decision 22 point 3 and Decision 23 point
     2).
4. **Neighbours and band (d1, k1).**
   - The distance between two cells is the distance between their centres
     in EPSG:7755. The definition of the centre is a process choice of task
     16.2.
     *(Amended 2026-11-07, Amendment 1 (A1): the distance is on the sphere,
     between the centres in longitude and latitude. See "Amendment 1"
     below.)*
   - **Band:** cell j is a neighbour of cell i if the distance is 50 km or
     less (`GISTAR_BAND_KM`). The weights are binary. The cell itself is in
     its own window (w_ii = 1; the "star" of Gi\*). The window of cell i is
     the cell and its neighbours; n_i is the number of cells in it.
   - On the sphere, an inner cell has 20 neighbours at each latitude from
     8° N to 37° N (computed for this Decision; 25 km gives 4, 35 km gives
     8, 75 km gives 36–46 and 100 km gives 68–82). The script counts the
     neighbours of each cell, and the QA reports their distribution.
   - **Minimum (k1):** a cell with fewer than 8 neighbours
     (`GISTAR_MIN_NEIGHBOURS`; the cell itself is not counted) gets no
     class (`few_neighbours`) and is counted. Its value stays in the
     windows of the other cells.
5. **QA bands (q2).** Descriptive only; no rule uses them; the band stays
   50 km.
   - **queen:** the 8 cells around a cell (by the cell index `ix`, `iy`)
     that are model cells. With k1, a cell gets a class only if all 8 are
     model cells.
   - **75 km:** a fixed band of 75 km (36–46 neighbours for an inner cell).
   - Each of the four Gi\* is computed again at each QA band, with k1 and m1
     applied to each separately (reading 2 of 2026-11-07). Reported for each
     Gi\* and QA band: the number of `hot` and of `cold` cells, and the share
     of the `hot` cells (and of the `cold` cells) at 50 km that have the
     same class at the QA band.
6. **Statistic, p-value and correction (e1, m1).**
   - **Statistic (the standard form; Ord & Getis 1995):** with n the number
     of model cells, x̄ and S the mean and the standard deviation (divisor n)
     of the values, and K_i = Σ_j w_ij x_j the number of cells with the
     value 1 in the window of i:
     G\*_i = (K_i − x̄ n_i) / (S √((n n_i − n_i²) / (n − 1))).
     The denominator is the standard deviation of a window sum when the n
     values are put at random on the n cells (sampling without
     replacement). G\*_i is reported as a statistic; the class uses the
     p-value below.
   - **Exact p (e1):** when the n values are put at random on the n cells
     (random relabelling, the null hypothesis of the denominator above),
     K_i follows a hypergeometric distribution: n cells, M cells with the
     value 1, a sample of n_i cells. With binary weights, G\*_i is a linear
     function of K_i. So:
     - p_hot = P(K ≥ K_i) and p_cold = P(K ≤ K_i) (`stats::phyper`);
     - the two-sided p = min(1, 2 × min(p_hot, p_cold)).
     There is no random number and no Monte Carlo error.
   - **Correction (m1):** Benjamini–Hochberg (`stats::p.adjust(method =
     "BH")`) over the two-sided p of the cells with a class, for each Gi\*
     and each band separately; q = 0.05 (`GISTAR_FDR_Q`).
   - **Classes:** `hot` if the adjusted p is 0.05 or less and K_i is above
     its expectation (x̄ n_i); `cold` if the adjusted p is 0.05 or less and
     K_i is below it; `not_significant` otherwise; `few_neighbours` (point
     4). A cell that is not a model cell has no class.
   - **Arithmetic from the published counts (before any run; not a
     result):**
     - `tiger_obscured` at 50 km (M = 104, n_i = 21): a window with no
       record has P(K ≤ 0) = 0.729, so the two-sided p of a cell below the
       expectation is 1. No cell can be `cold`. A two-sided p of 0.05 for a
       cell below the expectation needs a window of 242 cells or more (a
       band of about 175–195 km), before the correction. `tiger_5km` has 44
       cells with the value 1 or fewer, so the same is true for it.
     - So the tiger Gi\* can show clusters of cells with records (`hot`)
       only. They cannot show where tiger records are fewer than expected.
     - `effort_inat` at 50 km (M = 1,486): the smallest two-sided p of a
       cell below the expectation is 0.0129 (a window of 21 cells with no
       record). Whether a cell is `cold` after the correction depends on
       the other p-values.
     - At this sparsity the normal approximation is far from the exact p.
       For `tiger_obscured`, a window of 21 cells with 2 cells with a record
       gives a normal one-sided p of 0.0012; the exact P(K ≥ 2) is 0.039.
7. **Publication (f1, s2 with L1 and S-a; readings 3 and 4).**
   - **`effort_inat` — a figure:** `fig_06_<slug>.png` (`GISTAR_PUB_FIG` =
     6), static, at national scale, with the frame of `fig_04` and
     `fig_05`: the model cells by class (`hot`, `cold`, `not_significant`,
     `few_neighbours`); the reserve outlines and the state boundaries; no
     presence mark, no background mark, no point. A blank cell is not a
     model cell. The slug, the colours (readable with a colour-vision
     deficiency) and the size are process choices of task 16.2. The slug
     does not hold "tiger".
     - **Tier T1:** part (a) of the input is records that the source
       obscured, and the figure is at the grain of that obscuring (0.2°).
       Sensitive-data policy §2: "normal use; document the obscuring".
       Caption item 2 states it.
     - **Caption items** (reading 4; drafted in Week 16 and marked as
       drafts; the narrative is the author's):
       1. The Getis–Ord Gi\* of the iNaturalist mammal records (tiger
          excluded) at the 0.2° grain (cells of 396–488 km²), 2006–2022. It
          shows clusters of cells with records; it does not show search
          effort or animals.
       2. The input: the 1,486 model cells with one or more records, of the
          6,969 model cells; the source obscured part of the records to
          their 0.2° cell. The presence cells of the model are not in the
          input; the figure uses no tiger record.
       3. The neighbours: a fixed band of 50 km (20 neighbours for an inner
          cell), the cell itself included; a cell with fewer than 8
          neighbours has no class (with the count).
       4. The test: the exact p under random relabelling; the false
          discovery rate (Benjamini–Hochberg) at q = 0.05; the classes with
          their counts. *(2026-11-07, k-a, chosen by the author after the
          run of task 16.3 (after the result was seen): item 4 also says
          that no cell is `cold` at 50 km, and gives the count of `cold`
          cells at the 75 km QA band, from `tbl_18_gistar.csv`. Caption
          text only; no rule changes. Rejected: k-b, no change.)*
       5. A blank cell: not a model cell.
       6. The two QA bands: the share of the `hot` cells that stay `hot`
          (queen; 75 km).
       7. The effort caveat (proposal §7).
       8. The reserve outlines are the core protected-area polygons
          (Decision 4), not the notified total area; the state lines are
          from Natural Earth.
       9. The data sources, with the GBIF download DOI.

       *(Item 2 says that the source obscured part of the records. This was
       added when this Decision was written, for the T1 rule of the policy;
       reading 4 did not hold it.)*
   - **`effort_all` — the statistics table only**, no figure. *(The chat's
     reading of C1-2, stated in its reply of 2026-11-07: C1-2 adds
     `effort_all` "for the 5 km comparison only", and f1 names one figure.
     The author can change it before task 16.4.)*
   - **One statistics table** (committed and publishable; the number and
     the slug are a process choice of task 16.2). Counts and statistics
     only (reading 3):
     - for each Gi\* and band: the cells by class; the neighbour counts
       (minimum, median, maximum, and the cells below 8); for the two
       effort Gi\*, the shares of the QA bands;
     - for the two tiger Gi\*, only the counts of the next item;
     - no cell id, no position and no reserve name.
   - **What the docs and the table can state from the tiger Gi\* (S-a):**
     - **`tiger_obscured` (s1):** the number of `hot` cells; how many of
       them are `hot` in `effort_inat`; that share. Also the number of
       `cold` cells (0, point 6) and of `few_neighbours` cells. No name of
       a reserve, a landscape complex or a state; no position.
     - **`tiger_5km` (s2):** the counts of s1, against `effort_all`; and the
       number of `hot` cells by landscape complex, by rule L1. No reserve
       name; no position. The record counts of this set by reserve are
       already published (`tbl_15_occ_by_reserve.csv`).
     - **L1:** a `hot` cell counts for a landscape complex if one or more
       of its complete-case 1 km cells is inside a reserve polygon of that
       complex (the centre rule of Decision 25 point 8). A `hot` cell with
       no such 1 km cell counts as "outside the reserve polygons". A cell
       with reserves of two complexes counts in each, so the rows can add
       up to more than the `hot` cells.
     - **S-a:** the obscured set gets no count by landscape complex. The
       Sundarbans complex holds one reserve, so a count there would link a
       reserve name to a presence state of the obscured set (Decision 24
       point 9; Decision 25 point 9).
   - **Layers:** the four Gi\* at 50 km are written under `data/processed/`
     (gitignored): one row per model cell with the cell id, the value,
     K_i, n_i, G\*_i, the p-values and the class. The layer names are a
     process choice of task 16.2 (prefix `hot_`, naming §2). The two tiger
     layers are never committed. No layer is published before the Week-18
     rule (pending item "Published layers").
   - **Check (as Decision 25 point 4):** the code of `fig_06` reads only
     the `effort_inat` layer, the grid layer, the reserve layer and the
     state layer: no tiger layer and no presence field. The check is
     written with the figure.
   - The console text holds counts and statistics only; for the tiger
     Gi\*, only the counts of this point.
8. **Time window (w1).** All years, 2006–2022 (the years of the clean
   sets). No Gi\* by time window.
9. **Code (g1).** Own code in base R and `sf`: the neighbours by the
   distance between cell centres; K_i and G\*_i; `stats::phyper`;
   `stats::p.adjust`. No new package; `renv.lock` does not change. `sfdep`
   stays in the `scripts/00a` list only, and no script loads it (task 16.6
   decides whether the list keeps it).

**What was seen before this Decision (pre-registration, stated plainly):**
- **In the documents (the author and the chat):** each value of the
  `tbl_15`, `tbl_16` and `tbl_17` tables as the documents quote them. Among
  them: the counts that point 6 uses (104 presence cells and 1,486
  background cells of 6,969 model cells; the tiger 5 km set, 300 records
  in 44 cells of 1 km; the background 5 km set, 23,901 records in 5,512
  cells of 1 km); the counts by time window; the record counts by reserve
  (`tbl_15_occ_by_reserve.csv`); the reserve values
  (`tbl_17_reserve_suitability.csv`).
- **By the author (stated on 2026-11-07):** h1 — no density surface,
  prediction, grid or point layer was looked at on a map; h2 — no value
  from a console that is not in the documents is remembered.
- **By the chat that drafted this Decision:** the documents;
  `R/00_config.R` and four function files in full, and the other code in
  part; the committed `tbl_15`, `tbl_16` and `tbl_17` tables; the
  literature. One search of the Phase-1 documents of the claude.ai Project
  (for the Phase-1 Gi\* settings, before x1); by x1, no value of it is
  used. No data file and no map.
- **Not computed by anyone:** a Gi\*, a neighbour list, the number of 0.2°
  cells of `tiger_5km` and of `effort_all`, a map.
- **Post-seen in principle:**
  - Forks c, e and x: the counts 104 and 1,486 of 6,969 were known. The
    arithmetic of point 6 was made from them and was in the fork text
    before the choice.
  - Fork a: the record counts by reserve of the tiger 5 km set were known.
- **The choices.** The chat gave one recommended option for each fork. The
  author took it for each fork but three: a3 (the chat recommended a2, the
  obscured set only), s2 (the chat recommended s1 for the tiger Gi\*) and
  C1-2 (the chat recommended C1-1, `effort_inat` for both comparisons).
  After the first choices and before this text, the chat raised two
  conflicts (C1: a3 against the reason of b1; the cell rule and the
  Sundarbans complex for s2) and four readings. The author chose C1-2, L1
  and S-a, and confirmed the readings.

**Amendment 1 — 2026-11-07, in task 16.2, before any Gi\* and before any
neighbour list (A1):**
- **The error.** Point 4 put the distance between cell centres in
  EPSG:7755. The count of 20 neighbours and the reason for d1 came from
  arithmetic on the sphere. The scale factor of EPSG:7755 is 1.018 at 8° N
  (the chat had estimated about 1.003). A check with PROJ (2026-11-07): at
  50 km in EPSG:7755, the rows of cells with a centre at 9.5° N or south
  have 12–18 neighbours, and at about 8.6° N one pair of cells is 30 m from
  the band. The fork text of task 16.2 (fork p) also said that no
  neighbour count changes at 50 km, with margins of 49.4 and 53.1 km; for
  EPSG:7755 that was wrong.
- **The rule now.** The distance between two cells is the great-circle
  distance (the haversine formula) on a sphere of radius 6,371.0088 km
  (`GISTAR_EARTH_RADIUS_KM`; the mean radius of WGS 84, (2a + b) / 3),
  between the cell centres in longitude and latitude (p1 of task 16.2:
  ((ix + 0.5) × 0.2°, (iy + 0.5) × 0.2°)). The band (50 km), the binary
  weights, the cell in its own window and k1 do not change. The 75 km QA
  band of point 5 uses the same distance.
- **Checked for this amendment (arithmetic on cell centres made from the
  grid rule; not a result):**
  - 50 km: an inner cell has 20 neighbours at each row of cells from
    6.1° N to 37.3° N. The largest distance inside the band is 49.675 km;
    the smallest outside is 53.212 km.
  - 75 km: 36–46 neighbours, by latitude. At some rows a pair of cells is
    20–30 m from the band. Both QA paths use the same distance formula, so
    no pair can change sides between them. No band from 60 to 90 km has a
    margin of 1 km at each row.
- **Options:** A1 (chosen; the chat's recommendation); A2 — EPSG:7755 and
  a band of 52 km; A3 — EPSG:7755 and 50 km, as recorded; A4 — the 5 × 5
  block of cells without its four corners (an index rule).
- **What was seen:** nothing more than the list above. No Gi\* and no
  neighbour list exists, and no data file was read.
- **Consequences:** `GISTAR_DIST` = `"sphere"` and `GISTAR_EARTH_RADIUS_KM`
  in `R/00_config.R`. Caption item 3 of point 7 ("20 neighbours for an
  inner cell") is now true for each row of India.

**Result of STEP 16.1 (task 16.3, `scripts/09`, run on the project
machine; console text sent on 2026-11-07; facts, not a reading):**
- The hand-made case of STEP 16.1 passed (26 of 26). The earlier STEPs ran
  as before (QA of STEP 15.3: 84 of 84). STEP 16.1 took 0.1 minutes.
- **Cells and neighbours (points 3 to 5; Amendment 1):** 6,969 model cells.
  Neighbours of a cell (the cell itself not counted):

  | Band | Min | Median | Max | Cells with fewer than 8 |
  |---|---|---|---|---|
  | 50 km | 0 | 20 | 20 | 40 |
  | queen | 0 | 8 | 8 | 814 |
  | 75 km | 0 | 36 | 42 | 12 |

- **Inputs (point 2):**
  - `effort_inat`: 16,806 records, 429 of them in a 0.2° cell that is not a
    model cell; 1,486 model cells (the background cells of STEP 14.1); 55
    cells with a record are not model cells.
  - `effort_all`: 23,901 records, 429 of them in a cell that is not a model
    cell; 1,375 model cells; 47 cells with a record are not model cells.
  - The tiger inputs: no count (point 7). `tiger_obscured` has the 104
    presence cells of STEP 14.1 (a guard).
  - The guards passed: each clean record has its GBIF coordinates once
    (r2); each iNaturalist record of `effort_all` has the cell of the
    iNaturalist layer; no record of an effort input is a tiger record; each
    record is of 2006–2022.
- **Classes at 50 km (points 6 and 7):**

  | Gi* | hot | cold | not_significant | few_neighbours |
  |---|---|---|---|---|
  | `effort_inat` | 654 | 0 | 6,275 | 40 |
  | `effort_all` | 559 | 0 | 6,370 | 40 |
  | `tiger_obscured` | 200 | 0 | — | 40 |
  | `tiger_5km` | 52 | 0 | — | 40 |

  (— : not given for a tiger Gi\*, point 7.)
- **The comparison (point 7, s1):** 85 of the 200 `hot` cells of
  `tiger_obscured` are `hot` in `effort_inat` (0.425). 20 of the 52 `hot`
  cells of `tiger_5km` are `hot` in `effort_all` (0.385).
- **Rule L1 (`tiger_5km`, s2):** the `hot` cells by landscape complex:
  `central_india_eastern` 12, `western_ghats` 8, `northeast_hills` 4,
  `shivalik_gangetic` 0, `sundarbans` 0; outside the reserve polygons 28.
  The rows add up to 52, so no `hot` cell counts in two complexes.
- **QA bands (point 5; descriptive, no rule):**

  | Gi* | hot (queen) | cold (queen) | hot (75 km) | cold (75 km) | share of the 50 km hot cells that stay hot: queen / 75 km |
  |---|---|---|---|---|---|
  | `effort_inat` | 278 | 0 | 977 | 1,408 | 0.390 / 0.962 |
  | `effort_all` | 208 | 0 | 817 | 949 | 0.354 / 0.953 |
  | `tiger_obscured` | 106 | 0 | 289 | 0 | 0.480 / 0.910 |
  | `tiger_5km` | 17 | 0 | 110 | 0 | 0.327 / 1 |

  The shares of the `cold` cells are `NA`: no cell is `cold` at 50 km.
- **Stated plainly (facts of the run; no rule changes):**
  - At 50 km, no cell of an effort Gi\* is `cold`. Point 6 gave the
    smallest two-sided p of a cell below the expectation at 50 km (0.0129)
    and said that the result depends on the other p-values. At the 75 km
    QA band, the two effort Gi\* have 1,408 and 949 `cold` cells. The band
    stays 50 km (point 5).
  - The two effort inputs have the same number of records outside the
    model cells (429). The QA of task 16.5 counts the inputs again by a
    second path.
  - No cell of a tiger Gi\* is `cold` at any band, as point 6 said.
- **Outputs:** `data/processed/hot_effort_inat_cell02.csv`,
  `hot_tiger_obscured_cell02.csv`, `hot_effort_all_cell02.csv` and
  `hot_tiger_5km_cell02.csv` (6,969 rows each; written, read back and
  checked; gitignored); `outputs/tables/tbl_18_gistar.csv` (92 rows).
- **Seen from this run on:** the console text of STEP 16.1 (the table), by
  the author and the chat. No map was made.

**Reason and sources:**
- **This project only (x1).** The author's direction of 2026-11-07.
  Proposal question 4 asks how much of the pattern of this project is
  effort.
- **One effort Gi\* for each observer group (a3, b1, C1-2).** A
  target-group background has the bias of the presences when its records
  come from the same observers (Phillips et al. 2009; Decision 23). The
  obscured set and `effort_inat` are both from iNaturalist. 273 of the 300
  records of the tiger 5 km set come from one dataset that is not
  iNaturalist (Decision 21), so its comparison uses the background of all
  datasets.
- **0/1 on the model cells (c1).** One unit rule for Stage 3. A count of
  records is skewed (one dataset gives 273 of the 300 records of the tiger
  5 km set). A 0/1 value gives the exact p of e1.
- **A fixed band of 50 km (d1).** Getis & Ord (1992) define the statistics
  by a distance band. On this grid, 50 km gives the same number of
  neighbours (20) at each latitude of India; 25 km gives 4.
- **At least 8 neighbours (k1).** "Features should have about eight
  neighbors each, especially if the values for the Input Field parameter
  value are skewed" (Esri, Hot Spot Analysis).
- **QA bands (q2).** A Gi\* result depends on the band. The QA bands show
  how much, with no rule (as Decision 22 c2).
- **The exact p (e1).**
  - The denominator of G\*_i is the standard deviation of a window sum
    under random relabelling. Under the same relabelling, K_i is
    hypergeometric, so its tail probability is the exact p. A permutation
    test of the same statistic gets nearer to it as the number of
    permutations increases.
  - At this sparsity the normal approximation is far off (point 6). For a
    variable that is not bell-shaped, a permutation p is preferred to the
    analytical one (Bivand, R-sig-Geo, 2024).
  - With permutations, the number of permutations sets the smallest p,
    and this limits what a correction for many tests can find (Anselin
    2023, §16.5). The exact p has no such limit.
  - Anselin & Li (2019) prefer a conditional permutation to an exact
    probability for the local join count. Their exact probability is the
    probability of one count, with the value of the cell fixed at 1. e1 is
    a tail probability under total relabelling, the null hypothesis of the
    denominator of G\*_i. The QA compares e1 with a permutation test at
    sample cells.
- **The false discovery rate (m1).** Benjamini & Hochberg (1995); for
  local statistics, Caldas de Castro & Singer (2006). Bivand (2024) calls it
  "a reasonable compromise". One level of q gives three classes in the
  figure.
- **A figure of the effort Gi\* (f1).** Proposal question 4 and §7.
- **Counts only for the obscured set (S-a); counts by landscape complex for
  the tiger 5 km set (s2, L1).** See point 7.
- **All years (w1).** The tiger sets have 21, 54 and 71 cells of 0.2°
  (obscured set) and 11, 11 and 26 cells of 1 km (5 km set) in the three
  windows (Decision 22).
- **Own code (g1).** e1 needs no package. Own code is also used for the
  paths (Decision 17) and the Boyce index (y1 of task 14.5).

**Judgement values:** 50 km (band); 8 (minimum neighbours; the Esri
guidance); 0.05 (q); queen and 75 km (QA bands). From earlier Decisions:
the 0.2° model cells (Decision 23); the sets (Decisions 21–23).

**Rejected:**
- *x2 — the Phase-1 form and comparison; x3 — no tiger Gi\*.*
- *a1 — the tiger 5 km set only; a2 — the obscured set only (the chat's
  recommendation).*
- *b2 as the only effort input; C1-1 — `effort_inat` for both comparisons
  (the chat's recommendation).*
- *c2 — the number of records as the value; c3 — all 7,450 cells.*
- *d2 — queen contiguity as the main rule; d3 — 100 km; d4 — a band from
  the data (a choice after a result). k2 — no minimum. q1 — no QA band.*
- *e2 — permutation p-values; e3 — the normal approximation.*
- *m2 — three levels (seven classes); m3 — no correction; m4 —
  Bonferroni.*
- *f2 — a table only; f3 — nothing published.*
- *s1 for both tiger Gi\* (the chat's recommendation); s3 — nothing; S-b —
  the Sundarbans count with "outside the reserve polygons"; S-c — s2 for
  both, with the link recorded.*
- *w2 — the effort Gi\* by time window. g2 — `sfdep`.*
- *Not offered: a Gi\* on the sampled cells only (near a ratio; Decision 23:
  no ratio).*

**Limitations:**
- A `hot` cell is a cluster of cells with records at about 20 km. It is not
  a cluster of tigers or of search effort.
- The tiger Gi\* cannot show a `cold` cell (point 6).
- The effort inputs are records, not search effort (Decision 22).
- A position of `effort_all` and `tiger_5km` can be up to 5 km from the
  true position; a record near a cell edge can be in the next cell.
- `tiger_5km` is in effect one dataset (273 of 300 records). Its Gi\* shows
  that dataset.
- The cells are not equal in area (396–488 km²), and the band is in km.
  Cells at the coast and the border have fewer neighbours, and the data
  has no record outside India.
- The exact p assumes random relabelling over the model cells. A
  large-scale trend (for example in effort) can make many cells
  significant for that reason only: "the p-values of the local statistic
  may be affected by the presence of global spatial autocorrelation"
  (Anselin 2023).
- The tests are dependent, because the windows overlap. Benjamini–Hochberg
  controls the false discovery rate under positive dependence (Benjamini &
  Yekutieli 2001; not read, see `references.md`); this is not checked here.
  With discrete p-values, the correction is conservative.
- 50 km and 8 are judgement values. The QA bands show the effect of the
  band; they do not test it.
- L1 uses the core polygons (Decision 4). A cell counts for a complex if
  one of its 1 km cells is in a reserve, and a cell can count for two
  complexes.

**Consequences:**
- `R/00_config.R`: a new block "Stage 3: Gi\* (Decision 26)" (`GISTAR_*`);
  a dated note in the Decision-23 block. No earlier value changes.
- **Task 16.2 (process choices, before code):** the STEP numbers of
  `scripts/09`; the cell centre (point 4); how a record of the 5 km sets
  gets its 0.2° cell (point 2: its coordinates in EPSG:4326, from the GBIF
  file or from the point converted from EPSG:7755); the layer names
  (`hot_`); the number and the slug of the statistics table; the slugs,
  the colours and the size of `fig_04`, `fig_05` and `fig_06`; where the
  caption drafts go; the checks of Decision 25 point 4 and of point 7 of
  this Decision; hand-made cases first.
- **Task 16.3 (STEP 16.1):** the four Gi\* at 50 km and at the two QA
  bands; the layers; the statistics table.
- **Task 16.4 (STEP 16.2):** `fig_04`, `fig_05` and `fig_06`, with the
  caption drafts.
- **Task 16.5 (STEP 16.3), QA:** hand-made cases (a small grid: the
  neighbours at a known band, K_i, G\*_i by hand, the exact p by a direct
  sum, a `cold` case, the Benjamini–Hochberg step, k1); the neighbour count
  of the inner cells (20); K_i, G\*_i and the classes again by a second
  path; the exact p against a permutation test at sample cells; the inputs
  again from the layers (the cell counts; no presence cell in an effort
  input); the publish checks (no tiger Gi\* file under `outputs/`, no file
  with "tiger" in its name, the scan of the table, only the tiger counts of
  point 7, the check of the `fig_06` code).
- **The time of Week 16:** two more Gi\* (`effort_all`, `tiger_5km`), the
  QA bands and `fig_06` add about 45–75 min to the estimate of 3.4–4.9 h
  (an estimate).
- `naming-conventions.md` §6: `fig_06` is reserved; `fig_07` is the next
  free number.
- `references.md`: a new section "Gi\* settings (Decision 26)".
- The pending item "[Week 18] Published layers" gets a dated note.
- Decision 23 point 8 and §5.5 get dated notes.
- *(2026-11-07: the process choices of task 16.2 are in the change log;
  Amendment 1 above changes point 4.)*

This closes the **[Week 15–16] Gi\* settings** pending item.

### Decisions pending (raised, not yet made)

These forks are open. Each is decided in the week noted in the project plan,
before the relevant code is written.

- **[Week 18] Published layers (raised 2026-10-10 with Decision 20 as
  "Published path layer"; widened 2026-10-31 by Decision 25 point 4; decide
  before a path layer or a suitability layer goes on the site).** Decision
  20 point 7 allows the path lines in a static figure at national scale
  only. An interactive or downloadable path layer (the Stage-4 Leaflet maps)
  lets a reader zoom to 1 km and find a crossing position that the tables
  give at 10 km. Decide: no path layer on the site, lines simplified to a
  fixed tolerance, or a zoom limit.
  *(2026-10-31, Decision 25 point 4: the item also covers the suitability
  surface at 0.2°, which Week 15 does not publish as a layer. Decide: no
  layer, the class only, or the class and the value; the publish check of
  a layer of 0.2° cells (`assert_publishable_rast()` refuses a raster of
  0.2° in EPSG:4326); how the hatch of Decision 25 point 2 and the caption
  items of point 5 appear in an interactive map.)*
  *(2026-11-07, Decision 26 point 7: the Gi\* layers are not published;
  `fig_06` is a static figure. A Gi\* layer on the site would wait for this
  rule too.)*
- **[After Stage 3] SDM-based resistance + circuit-theory check.** Raised
  2026-09-26 (Decision 14, F1). After the SDM exists, build a resistance
  surface from 1 − suitability and run circuit theory between reserves, to
  reproduce the national method (Jhala et al. 2021; Qureshi et al. 2014) as
  closely as the data allow and compare it with the Stage-2 least-cost paths.
  Decide then: the transform (linear 1 − suitability as in the national method,
  or a negative exponential as Keeley et al. 2016 recommend for long-distance
  movers), and the tool (at ~3 million cells, probably Circuitscape or
  Omniscape outside R). Not yet in the week plan.
  *(2026-10-25, Decision 23: if task 14.4 allows a model, its suitability
  surface is at the 0.2° grain (about 20 km), not at 1 km. A resistance
  surface from it would have that grain. Decide then whether this item
  still applies.)*

---

## Change log

*(Records as-built changes to data, code, or scope during execution.)*

### 2026-11-07 — Week 16, task 16.3 complete: STEP 16.1 (the four Gi\*)

- **Code.** `R/00_functions_gistar.R` (new; f1 of task 16.2): 13
  `gistar_*` functions — the haversine distance, the index window, the
  neighbours, K_i, G\*_i and the exact p, the Benjamini–Hochberg step and
  the classes, the cell of a record from its GBIF coordinates (r2), rule
  L1, the share of the QA bands, the checks of a layer, and the hand-made
  case (`gistar_self_test()`, 26 checks). `scripts/09`: STEP 16.1 after
  STEP 15.3 (s1); the header (the choices of task 16.2, the inputs and the
  outputs of STEP 16.1, a dated note on w2 of task 14.2); one more
  `source()` line; three paths.
- **Tests in the chat (not the record):** R 4.3.3 with `sf` 1.0.15 and
  `terra` 1.7.65 (the project machine has R 4.5.2, `sf` 1.1-1 and `terra`
  1.9-27). The hand-made case 26 of 26. Four changes made to the code on
  purpose (an off-by-one p, the cell out of its window, a wrong distance
  rule, the correction over all cells); each made the right checks fail.
  STEP 16.1 on a made-up project (a 1 km stack in EPSG:7755, 1,200 model
  cells, made-up records and GBIF zip files with coordinates on cell
  edges): all guards passed. Two negative tests (a record with no GBIF
  coordinates; an iNaturalist record with another cell) stopped the script
  at the right guard. No data file was used.
- **The run (project machine, 2026-11-07):** the result is in Decision 26,
  "Result of STEP 16.1". In short, at 50 km: `effort_inat` 654 `hot`,
  `effort_all` 559 `hot`, no `cold` cell; `tiger_obscured` 200 `hot` (85
  also `hot` in `effort_inat`); `tiger_5km` 52 `hot` (20 also `hot` in
  `effort_all`; by landscape complex 12, 8, 4, 0, 0 and 28 outside the
  reserve polygons).
- **Readings of the chat (stated in its reply of 2026-11-07; confirmed by
  the author on 2026-11-07):**
  1. Point 5 asks for the QA-band counts "for each Gi\*", and point 7
     allows only the s1 counts for a tiger Gi\*. The tiger rows at the QA
     bands hold `hot`, `cold`, `few_neighbours` and the same-class shares;
     no input count and no `not_significant` count.
  2. The tiger-against-effort comparison and the L1 counts are at 50 km
     only.
  3. The neighbour statistics are given once (`gistar` = `all`): they
     depend on the grid only.
- **An error of the chat:** the run instructions said that the Week-15
  tables "must not show as changed". QA check (c) of STEPs 14.3 and 15.3
  counts all files under `outputs/`, so the new `tbl_18_gistar.csv` changed
  its value text ("0 of 66 files" to "0 of 67 files") in
  `tbl_16_sdm_qa.csv` and `tbl_16_sdm_pred_qa.csv`. No other value
  changed. The two tables are committed with the new file.
- **Docs:** this file (Decision 26, "Result of STEP 16.1"; the status);
  `data-dictionary.md` (the four Gi\* layers; `tbl_18_gistar.csv`);
  `project-plan.md` (task 16.3 done); `naming-conventions.md` §6
  (`tbl_18` built); `handoff.md` (the state, the files, two gotchas, the
  open readings).
- **Next:** task 16.4 (STEP 16.2: `fig_04`, `fig_05` and `fig_06`). First
  the author answers the three readings and one caption question of
  `fig_06` (raised in the chat's reply after the run).

### 2026-11-07 — Week 16, task 16.2: process choices; Decision 26 Amendment 1 (no code, no run)

- **Docs and config only.** No script, data layer or table changed; no
  run; no Gi\*.
- **Process choices of task 16.2 (author, 2026-11-07; each as the chat
  recommended).** Write a choice with the task, for example "r2 of task
  16.2".
  - **s1 — STEPs.** In `scripts/09`, after STEP 15.3: STEP 16.1 the four
    Gi\* (task 16.3), STEP 16.2 `fig_04`, `fig_05` and `fig_06` (task 16.4),
    STEP 16.3 the QA (task 16.5). No new run switch: each run writes the
    Gi\* layers, `tbl_18_gistar.csv` and the three PNG files again (the same
    values).
  - **f1 — function files.** `R/00_functions_gistar.R` (`gistar_*`: the
    neighbours, K_i, G\*_i, the exact p, the classes, the L1 counts, the
    hand-made case; `gistar_qa_*`, the QA second path) and
    `R/00_functions_fig.R` (`fig_*`: the frame, the hatch, the key box, the
    read guard of k1, the hand-made case).
  - **p1 — the cell centre:** ((ix + 0.5) × 0.2°, (iy + 0.5) × 0.2°) in
    longitude and latitude. *(The fork text said "converted to EPSG:7755";
    with Amendment 1 of Decision 26 the centre is used in longitude and
    latitude.)*
  - **r2 — the 0.2° cell of a record of `effort_all` and `tiger_5km`:** the
    GBIF coordinates read again from the two download zip files by
    `gbifID`, then `occ_cell02()` — the input of background part (b)
    (`scripts/08` STEP 13.3). Process choice w2 of task 14.2 said that
    `scripts/09` reads no GBIF file; from task 16.3 it reads the two zip
    files (in STEP 16.1 only; the header of `scripts/09` changes with the
    code). The QA checks that an iNaturalist record of `effort_all` has the
    cell of `effort_background_inat_cell02_7755.gpkg`.
  - **n1 — the layers:** `data/processed/hot_effort_inat_cell02.csv`,
    `hot_tiger_obscured_cell02.csv`, `hot_effort_all_cell02.csv` and
    `hot_tiger_5km_cell02.csv` (gitignored): one row per model cell; `id`,
    `value`, `n_nb`, `n_win`, `k`, `gistar`, `p_hot`, `p_cold`, `p_two`,
    `p_adj`, `class`; no geometry (joined to the grid by `id`). The QA
    bands are not written as layers.
  - **t1 — the tables:** `outputs/tables/tbl_18_gistar.csv` (publishable;
    `gistar`, `band`, `group`, `item`, `value`, `reading`) and
    `tbl_18_gistar_qa.csv` (STEP 16.3; `group`, `check`, `value`, `pass`).
    A landscape-complex name is allowed only in the `tiger_5km` rows of
    `tbl_18_gistar.csv` (the reserve-name scan of the `tbl_16` tables would
    count "sundarbans" as the reserve name "Sundarbans"); STEP 16.3 scans
    for it. `tbl_19` is the next free number.
  - **g1 — the figure slugs:** `fig_04_suitability_classes.png`,
    `fig_05_suitability_value.png`, `fig_06_effort_gistar.png`.
  - **z1 — size and frame:** as `fig_03` (11 × 10.6 in, 200 dpi; the
    extent of the state layer; the theme of `fig_03`). The order: the
    state fill, the model cells, the state lines, the reserve outlines
    (core polygons, no fill; a white line under an ink line), the hatch,
    the key box. The legend on the right; the title, the subtitle and the
    caption in the image.
  - **c1 — colours:** `fig_04` viridis in 5 steps (class 1 dark, class 5
    light); `fig_05` viridis on a continuous scale, marks at 0, 0.25, 0.5,
    0.75 and 1; `fig_06` hot dark red, cold dark blue, `not_significant`
    light grey, `few_neighbours` mid grey; a blank cell (the land colour)
    is not a model cell. Task 16.4 sets the hex values of `fig_06` and
    checks them with a colour-vision simulation.
  - **h1 — the hatch:** diagonal lines cut to the 32 cell polygons with
    `sf` (own code), about 2–3 lines in each cell (tuned in task 16.4),
    each a white line under an ink line; a key box in the map with a
    hatched square and the text "outside the training range of one or more
    covariates" (its position in the config).
  - **k1 — the check of the figure inputs:** the figure code reads its
    files through `fig_read()`, which refuses a file that is not on the
    list of the figure and records each file that it reads. The lists:
    `fig_04` and `fig_05` — the prediction layer, the grid layer, the
    reserve layer, the state layer; `fig_06` — `hot_effort_inat_cell02.csv`,
    the grid layer, the reserve layer, the state layer. The figure code
    uses only objects that it makes (prefix `fig_`). STEP 16.3 checks the
    record, and that no data frame that is drawn has a field with a
    presence, background, record, tiger or occurrence word.
  - **d1 — the caption drafts:** as `fig_03`: made in STEP 16.2 from the
    values of the run, drawn in the PNG and printed in the console under
    "DRAFT"; an open item in the handoff until the author edits them.
  - **q1 — the permutation check:** for each Gi\* at 50 km, about 20 sample
    cells (the cell with the largest K_i and cells chosen by a fixed rule
    on the cell id); 9,999 total relabellings with a fixed seed; a pass if
    the exact p is inside the 99.9 % binomial interval of the Monte Carlo
    estimate.
- **Decision 26 Amendment 1 (A1), before any Gi\*.** The chat found an
  error of its own (below) and raised four options; the author chose A1:
  the distance between two cells is on the sphere (haversine, radius
  6,371.0088 km), between the centres in longitude and latitude. 50 km
  then gives 20 neighbours for an inner cell at each row of India.
  Decision 26, "Amendment 1", has the record.
- **Errors of the chat (found in task 16.2):**
  - Decision 26 point 4 put the distance in EPSG:7755, but the count of 20
    neighbours and the reason for d1 came from arithmetic on the sphere.
    The scale factor of EPSG:7755 is 1.018 at 8° N; the chat had estimated
    about 1.003.
  - The fork text of p said that no neighbour count changes at 50 km, with
    margins of 49.4 and 53.1 km. For EPSG:7755 that was wrong (12–18
    neighbours for the rows at 9.5° N or south; a pair of cells 30 m from
    the band at about 8.6° N).
  - The check that found it: PROJ (through `pyproj` in the chat's
    workspace) on cell centres made from the grid rule. No data file.
- **Not forks (fixed by practice):** a hand-made case first in each STEP;
  counts and statistics only in the console (for the tiger Gi\*, only the
  counts of Decision 26 point 7); L1 by the 1 km cells of each reserve by
  the centre rule (e1 of task 15.2); each number of a caption from a table
  or a layer of the run; no new package (`viridisLite` and `RColorBrewer`
  are in `renv.lock` as dependencies of `ggplot2`).
- **Config:** `GISTAR_DIST` and `GISTAR_EARTH_RADIUS_KM` (Amendment 1); a
  block "Process choices of task 16.2" after the Decision-26 block (the
  centre, the layer files, the table number and slugs, the figure slugs,
  the size and the resolution, the palette name, the hatch lines and the
  position of the key box (start values for task 16.4), the permutation
  settings). Two comments of the Decision-26 block changed for Amendment
  1. No other value changed.
- **Other docs:** this file (Decision 26: Amendment 1, a note on point 4
  and on "Consequences"; the status); `project-plan.md` (task 16.2 done;
  notes on tasks 16.3–16.5); `naming-conventions.md` §6 (`tbl_18`, the
  figure slugs and the layer names; `tbl_19` and `fig_07` next free);
  `handoff.md` (the state, the entry point, row 26, a gotcha).
- **Next:** the split point — the author can commit tasks 16.1–16.2
  (`analysis:` for `R/00_config.R`; `docs:` for the docs and
  `data/README.md`). Then task 16.3 (STEP 16.1, the Gi\*).

### 2026-11-07 — Week 16, task 16.1: Decision 26 recorded (no code, no Gi\*)

- **Docs and config only.** No script, data layer or table changed; no
  run; no Gi\*.
- **Entry state:** Week 15 is committed and pushed (`7ae300a`,
  2026-11-01). It is one commit with no scope prefix, not the planned
  `analysis:` and `docs:` commits of task 15.7. Nothing under `data/` is in
  it. The working tree was clean.
- **The author's directions (2026-11-07):**
  - This project is not Phase 1. The Phase-1 documents are not an input
    (Decision 26 x1). The chat had raised two discrepancies inside the
    Phase-1 documents; they are closed with no action.
  - From Week 16, the chat edits the docs and the scripts in the
    repository folder. The author runs the scripts, makes the Decisions
    and commits.
  - `renv.lock` and the references are changed when a task needs them.
- **Decision 26** (the Gi\* settings): x1, a3, b1 with C1-2, c1, d1 (k1,
  q2), e1, m1, f1, s2 with L1 and S-a, w1, g1; the author's statements h1
  and h2. a3, s2 and C1-2 are not the chat's recommendation. Before the
  text, the chat raised two conflicts (C1: a3 against the reason of b1; the
  cell rule and the Sundarbans complex for s2) and four readings; the
  author chose C1-2, L1 and S-a and confirmed the readings.
- **A reading of a short answer** (the gotcha of task 15.1): with C1-2,
  `effort_all` is published in the statistics table only, with no figure.
  The chat stated this reading in its reply; the author can change it
  before task 16.4.
- **A change after the readings:** caption item 2 of `fig_06` says that
  the source obscured part of the records (the T1 rule, sensitive-data
  policy §2).
- **Config:** a new block "Stage 3: Gi\* (Decision 26)" (`GISTAR_*`); a
  dated note in the Decision-23 block. No earlier value changed.
- **`data/README.md`** written again (the author's request): the folder
  layout as it is on disk; the background is Mammalia (Decision 5); the
  boundary source is the NTCA KML (Decision 4); ISFR is an area
  cross-check only (Decision 8).
- **Other docs:** this file (Decision 26; dated notes on Decision 23 point
  8, §5.5 and "Published layers"; the pending item closed; the status);
  `project-plan.md` (task 16.1 done; notes on tasks 16.2–16.5; the time
  estimate); `naming-conventions.md` §6 (`fig_06`); `references.md` (a
  new section); `handoff.md`; `README.md` (the line "Stack").
- **Next:** task 16.2 (the process choices). The commit is by the author:
  `analysis:` for `R/00_config.R`; `docs:` for the docs and
  `data/README.md`.

### 2026-11-01 — Week 15 complete: task 15.6 (docs close, the Week-16 plan)

- **Docs only.** No rule, value, script, data layer or table changed; no
  run.
- **The author's choice m1 (task 15.6):** the reserve table and the caption
  items do not state that the value of Mukundara Hills uses 19 of its 316
  1 km cells outside the training range. The docs record it (Decision 25,
  "Result of STEP 15.3"; "Limitations"); the figures show the hatch.
- **§5.4** written again (the prediction, the reserve check and the
  published form); **"Limitations"**: eight Week-15 items at the end of the
  section.
- **Week 15 against proposal question 3 (a record, not text for the
  site):** "Where is habitat suitable for tigers across India, and does
  modelled suitability agree with where reserves are?"
  - A relative suitability surface exists at the 0.2° grain over 6,969
    model cells; the gate of Decision 24 point 8 is open (mean test Boyce
    0.668). It is not occupancy and not a probability of presence.
  - Of the 56 reserves with a value, 55 are above the median of the model
    cells. The reserve values agree with the 2022 census density by the
    rule of Decision 24 point 9 (r1: ρ = 0.379, n = 51, p = 0.006). r2 has
    no published answer (Decision 25 point 9).
  - The effort caveat (proposal §7) applies to each of these statements.
    The figures come in Week 16.
- **`proposal.md` §8:** a dated note on the entry "Habitat suitability at a
  coarser grain" (the national prediction is at 0.2°; the validation
  against reserves is the reserve check). No new deviation.
- **`README.md`:** the status.
- **`project-plan.md`:** Week 15 complete (the commit, task 15.7, by the
  author); the Week-16 row and the **Week-16 task breakdown** (a draft; a
  plan, not a Decision): Decision 26 (the Gi* settings) first, then the
  process choices, the Gi*, the two suitability figures with the caption
  drafts, the QA, the docs (the Stage-3 close) and the commit.
- **`handoff.md`:** written for Week 16 (the state, the entry point, the
  gotchas of Week 15, the references to verify).
- **Next:** the commit of Week 15 (task 15.7, by the author; `analysis:`
  for `R/`, `scripts/` and `outputs/tables/`, `docs:` for the docs), then
  Week 16, task 16.1 — Decision 26.

### 2026-11-01 — Week 15, task 15.5 complete: STEP 15.3 (the QA of Decision 25)

- **Author's choice (task 15.5, 2026-11-01):** the QA also counts the
  valued 1 km cells of the reserves that are outside the training range
  (the open question of task 15.4: the reserve table shows no hatch). An
  information row (pass `TRUE`), not a check.
- **New code (task 15.5, chat, 2026-11-01):**
  - `scripts/09`: STEP 15.3 (its header lists the steps); the header lines
    "Ran 2026-11-01" for STEP 15.2. STEPs 14.1–15.2 did not change.
  - `R/00_functions_sdm.R`: seven QA functions — `sdm_qa_cloglog()` (the
    model output by hand: clamping of the covariates and of the features,
    link + `alpha`, cloglog; a feature that is not linear or quadratic
    stops), `sdm_qa_oor()`, `sdm_qa_rank_class()` (the class by
    ceiling(k (n − rank + 1) / n)), `sdm_qa_reserve_cells()`
    (`terra::extract()` on the polygons), `sdm_qa_reserve_values()`,
    `sdm_qa_spearman()` (the Pearson r of the ranks; the t approximation),
    `sdm_qa_r2_counts()` — and `sdm_self_test_153()`. They call no
    function of STEPs 15.1–15.2. No earlier line changed.
  - No config change; no new package.
- **The checks** (as built; the groups of the table): the hand-made cases
  of STEPs 15.1–15.3; the prediction (the fields of the layer; the model
  cells; the record file; the values by hand; the flag; no presence or
  background cell outside the range; the counts outside, min, median and
  max, and the gate of `tbl_16_sdm_prediction.csv`); the classes; the
  reserves (the fields and rows of `tbl_17`; the cells used and with no
  value; the values; the ranks; the density; the counts of
  `tbl_16_sdm_reserve_check.csv`); r1; r2 (the rule of point 9; the
  counts again only if published); z1 (the kinds again; the total must be
  0); the information count; the publish scans of the three Week-15
  tables and of the QA table.
- **Tests in the chat** (made-up projects; no project data): the pass case
  84 of 84. Seven errors put into the outputs between STEP 15.2 and STEP
  15.3 (a changed reserve value; a presence column in `tbl_17`; a changed
  value of the layer; a reserve name in the check table; a wrong count of
  cells outside the range; r2 counts with r2 not published; a cell id as a
  value) each fail the intended check. A set with a z1 reserve fails the
  z1 check only and prints the block "not for the docs"; a set with r2
  published passes the extra r2 check. Four wrong rules in the QA
  functions each make the hand-made case fail (no `alpha`; Pearson of the
  values; a value at a limit counted as outside; two r2 counts swapped —
  this case first had a symmetric example, and the chat changed it).
- **Run on the project machine** (console text sent 2026-11-01): 84 of 84;
  as in Decision 25, "Result of STEP 15.3". The terra path found no
  difference from the centre rule.
- **Output (new):** `outputs/tables/tbl_16_sdm_pred_qa.csv` (84 rows).
- **Not committed** (task 15.7).
- **Open (for task 15.6, the author):** whether the reserve table or a
  caption states the cells outside the range of Mukundara Hills (1
  reserve, 19 of 316 cells). *(2026-11-01, task 15.6: m1 — no change.)*
- **Next:** task 15.6 — the docs of Week 15 ("Limitations", §5.4,
  `proposal.md` §8 if needed, `README.md`) and the Week-16 breakdown.

### 2026-11-01 — Week 15, task 15.4 complete: STEP 15.2 (the reserve check and the reserve table)

- **New code (task 15.4, chat, 2026-11-01):**
  - `scripts/09`: STEP 15.2 (the steps 1–8 of its header); the paths of the
    census layer and of the prediction layer; the header line "Ran
    2026-11-01" for STEP 15.1. STEPs 14.1–15.1 did not change.
  - `R/00_functions_sdm.R`: `SDM_RESERVE_TBL_FIELDS` and nine functions —
    `sdm_reserve_cells()`, `sdm_reserve_values()`, `sdm_reserve_r1()`,
    `sdm_reserve_r2()`, `sdm_reserve_z1()`, `sdm_reserve_table()`,
    `sdm_reserve_table_checks()`, `sdm_reserve_check_summary()`,
    `sdm_self_test_152()`. No earlier line changed.
  - No config change; no new package.
- **Implementation points (no rule changed):** the 1 km cells of a polygon
  are the non-NA cells of the cell-id raster in the bounding box of the
  polygon whose centre `sf::st_intersects()` the polygon; a reserve with
  an empty geometry has no cell; `geometry_present` must agree with the
  geometry; `unit_id` is read as a number (stored as real) and compared as
  an integer. The console prints the reserve table without `state` and
  `landscape_complex` (they are in the file). Guards stop the run if the
  check table holds a reserve name or column, or an r2 count when r2 is
  not published.
- **Tests in the chat** (made-up projects; no project data):
  - the hand-made case 17 of 17. Four wrong rules put into the code (an
    edge that does not count; a value equal to the median counted as
    above; publish only above 3; a cell with no value counted as 0) each
    make it fail;
  - a made-up project of 45 reserves (an overlap, two with no polygon, one
    of each kind of z1): a second path by `terra::extract()` on the
    polygons gave the same reserve values (largest difference 4e−16) and
    the same counts of cells used; r1 again gave the same ρ and p; r2 not
    published (a 0 in the 2 × 2 count); the z1 block printed the two
    names;
  - a second made-up set with 4 reserves in each cell of the 2 × 2 count:
    r2 published (4 rows).
- **Run on the project machine** (console text sent 2026-11-01): as in
  Decision 25, "Result of STEP 15.2". STEP 15.1 gave the same values as in
  task 15.3.
- **Outputs (new):** `outputs/tables/tbl_16_sdm_reserve_check.csv` (14
  rows), `outputs/tables/tbl_17_reserve_suitability.csv` (58 rows).
- **Not committed** (task 15.7, at the end of the week).
- **Docs:** Decision 25 "Result of STEP 15.2"; a dated note in the result
  of Decision 24; `data-dictionary.md` (two entries); `naming-conventions.md`
  §6 (`tbl_17` as built); `project-plan.md` (task 15.4 done); `handoff.md`.
- **Next:** task 15.5 — STEP 15.3, the QA of Decision 25.

### 2026-11-01 — Week 15, task 15.3 complete: STEP 15.1 (the prediction, the classes, the flag, the gate)

- **New code (task 15.3, chat, 2026-10-31):**
  - `scripts/09`: the switch `RUN_FIT` (w1 of task 15.2; `FALSE`); guards:
    `RUN_FIT` is TRUE or FALSE, `RUN_COVARIATES` = `TRUE` needs `RUN_FIT` =
    `TRUE`, the model file of the record must exist, and a run with
    `RUN_FIT` = `TRUE` must not write over it (same date). The paths of the
    covariate table and of the model file are set before STEP 14.2. STEP
    14.2 runs only with `RUN_FIT` = `TRUE`. STEP 14.3: check m1 reads the
    model file of the record; with `RUN_FIT` = `TRUE`, one more check of
    the coefficients of the fit of the run; the publish scan reads its six
    tables only (c1). STEP 15.1 (new): the steps 1–8 of its header.
  - `R/00_functions_sdm.R`: `SDM_PRED_FIELDS` and eight functions —
    `sdm_pred_values()`, `sdm_out_of_range()`, `sdm_rank_class()`,
    `sdm_class_ties()`, `sdm_gate_open()`, `sdm_pred_layer_checks()`,
    `sdm_pred_summary()`, `sdm_self_test_151()`. No earlier line changed.
  - No config change (since task 15.2); no new package.
- **Tests in the chat** (a made-up project; no project data; R 4.3.3,
  `maxnet` 0.1.4 built from the GitHub tag v0.1.4, `glmnet` 4.1.8, `terra`
  1.7.65, `sf` 1.0.15):
  - the Week-14 script on the made-up project: QA 133 of 133;
  - the new script, `RUN_FIT` = `FALSE`: QA 133 of 133, and STEP 15.1
    complete; class 5 = the top set of the sensitivity rule;
  - `RUN_FIT` = `TRUE`: QA 134 of 134 (the coefficient check passes);
  - a closed gate (the fold values of the Boyce index made negative): the
    three gate rows, then a stop; no layer;
  - the guards for a missing model file of the record and for
    `RUN_COVARIATES` = `TRUE` with `RUN_FIT` = `FALSE` stop the run;
  - four wrong rules put into the functions (a tie to the higher id; an
    off-by-one class; a value at a limit counted as outside; a gate of ≥)
    each make the hand-made case fail.
- **`maxnet` source at the tag v0.1.4** (commit `c2b9270`, read in task
  15.3): `maxnet()` sets `varmin` and `varmax` over all data rows (the
  presence rows, the background rows and the presence rows added to the
  background); `predict.maxnet()` clamps the covariates, then the
  features; link = features × coefficients + `alpha`; cloglog = 1 −
  exp(−exp(`entropy` + link)). This agrees with the master branch read on
  2026-10-25 and with Decision 25 point 2.
- **Run on the project machine** (console text sent 2026-11-01): guards 35
  of 35; the STEP-14.1 counts as before (outcome `planned_model`); STEP
  14.2 skipped; QA 133 of 133; STEP 15.1 as expected (18 of 18; the gate;
  6,969 cells; classes of 1,394 and 1,393 cells; 36 table rows). The
  values: Decision 25, "Result of STEP 15.1".
- **Outputs:** `data/processed/sdm_prediction_cell02.csv` (gitignored);
  `outputs/tables/tbl_16_sdm_prediction.csv` (new). Written again:
  `tbl_16_sdm_qa.csv` (the texts of three checks changed: m1, the six
  tables, (d)) and `tbl_16_sdm_counts.csv` (the same values).
- **Not committed.** The author commits the work of Week 15 at the end of
  the week (task 15.7); the split commit of tasks 15.1–15.2 was not made.
- **Docs:** Decision 25 "Result of STEP 15.1"; `data-dictionary.md` (two
  entries, two dated notes); `references.md` (a note on the `maxnet`
  source at the tag); `project-plan.md` (task 15.3 done); `handoff.md`.
  The header of `scripts/09` gets the line "Ran 2026-11-01" with the code
  of task 15.4.
- **Next:** task 15.4 — STEP 15.2 (the reserve check, the reserve table,
  the r2 rule and the z1 counts of Decision 25 point 9).

### 2026-10-31 — Week 15, task 15.2: process choices; Decision 25 point 9 (no code, no run)

- **Docs and config only.** No script, data layer or table changed; no run;
  no prediction.
- **Decision 25 point 9 (y1, z1), added before any result.** In task 15.2
  the chat found two ways in which the outputs of Decision 25 can link a
  reserve name to a presence or no-presence state (Decision 24 point 9 does
  not allow it): r2 with the reserve table and the median, and a reserve
  whose 1 km cells are all hatched or have no value. The author chose y1
  (r2 only if each count of the 2 × 2 table is 3 or more) and z1 (a QA
  check that stops the script if a reserve of these kinds exists), and to
  record them as point 9 of Decision 25.
- **Process choices of task 15.2 (author, 2026-10-31; each as the chat
  recommended).** Write a choice with the task, for example "w1 of task
  15.2".
  - **w1 — the run switch `RUN_FIT`** in `scripts/09`, now `FALSE`.
    - `FALSE`: STEP 14.2 is skipped: no fit, no STEP-14.2 table and no
      model file are written. STEP 14.3 and the Week-15 STEPs read
      `SDM_PRED_MODEL_FILE`. STEP 14.3 check m1 becomes "the model file of
      the record is on disk" (other dated model files are counted only).
    - `TRUE`: STEP 14.2 runs as before, and STEP 14.3 also checks that the
      coefficients of the new fit are those of the record file (within
      `SDM_QA_REL_TOL`); otherwise the script stops.
    - The objects that STEP 14.3 takes from STEP 14.2 (the paths of the
      covariate table and of the model file) are set before STEP 14.2.
  - **l1 — the prediction layer** is `data/processed/sdm_prediction_cell02.csv`
    (gitignored): one row per model cell with `id`, `value` (cloglog),
    `rank`, `class` and `out_of_range`. No geometry; no presence or
    background field. Written, then read back and checked. The figures
    join it to `sdm_grid_cell02_7755.gpkg`.
  - **n1 — the reserve table** is
    `outputs/tables/tbl_17_reserve_suitability.csv` (publishable; a new
    number, as `tbl_03`). Check s1 of STEP 14.3 does not change: no
    `tbl_16` table holds a reserve name.
  - **c1 — the scans.** STEP 14.3 scans only its six tables (the list
    `need16`), not each `tbl_16` file. STEP 15.3 scans the Week-15 tables
    in the same run, after STEPs 15.1 and 15.2 write them, so no check
    enters one run late.
  - **t1 — the Week-15 tables** (with the author's yes to the class value
    ranges):
    - `tbl_16_sdm_prediction.csv` (STEP 15.1; columns `group`, `item`,
      `value`, `reading`): the gate; the minimum, median and maximum of the
      value; for each class its size and its lowest and highest value; the
      number of cells outside the training range, in total and for each
      covariate (below and above). The class value ranges are statistics
      in a table; the legend of `fig_04` still gives no value.
    - `tbl_16_sdm_reserve_check.csv` (STEP 15.2): r1 (ρ, n, p, the
      reading); r2 under point 9; the reserve counts (all, with a polygon,
      with a value, with a value and a density).
    - `tbl_16_sdm_pred_qa.csv` (STEP 15.3; `group`, `check`, `value`,
      `pass`).
  - **k1 — the columns of the reserve table:** `unit_id`, `unit_name`,
    `state`, `landscape_complex` (the roll-up of Decision 2, as in
    `tbl_15_occ_by_reserve.csv`), `cloglog_mean` (the reserve value),
    `cloglog_rank`, `density_2022`, `n_1km_cells_used`,
    `n_1km_cells_no_value`. Rows by `unit_id`; values at full precision
    (rounding only in figures and text); a tie in the rank gets the lowest
    rank number (`SDM_PUB_RANK_TIES` = `"min"`). *(The column names were
    set by the chat with k1; the author can change them before task
    15.4.)*
  - **e1 — the centre rule in code.** Main path: for each polygon, the
    centres of the complete-case 1 km cells in its bounding box, then
    `sf::st_intersects()` (an edge counts; the method of
    `occ_reserve_index()`, task 13.8). QA path: `terra::extract()` on the
    cell-id raster; the differences are counted, and the check passes at 0.
  - **p1 — the p-value of r1:** `stats::cor.test(method = "spearman", exact
    = FALSE)` in each case (`SDM_RESERVE_P_EXACT` = `FALSE`). With the R
    default, the method changes with the data (exact with no ties,
    approximate with ties), and `density_2022` can have ties.
  - **q1 — the QA (STEP 15.3)** has its own table. A hand-made case first.
    A second path that calls no function of STEPs 15.1–15.2: the
    prediction again by hand from the model file (the features, the
    clamping of the covariates and of the features, link = features ×
    coefficients + alpha, cloglog = 1 − exp(−exp(entropy + link))); the
    classes again by other code; the reserve values again by the QA path
    of e1; r1 again. Also: no presence or background cell is flagged (true
    by construction); the z1 count is 0; the publish checks of the
    Week-15 tables. The table is written first; then a FALSE stops the
    script.
- **Not forks (fixed by the plan, or implementation):** STEPs 15.1, 15.2
  and 15.3 come after STEP 14.3, in the same model-outcome block; STEP 14.3
  runs in each run. The gate reads the row `mean` of `tbl_16_sdm_cv.csv`;
  at 0 or below, the script stops before the layer is written. STEP 15.2
  finds the presence cells again from the obscured layer (STEP 14.2 can be
  skipped). The out-of-range comparisons are exact (the fit used the same
  CSV). r1 uses the reserves with a value and a `density_2022` that is not
  `NA`; a real zero counts. No new package; the console gives counts and
  statistics only.
- **Config:** `SDM_PUB_R2_MIN_N` (point 9), `SDM_PUB_RANK_TIES` (k1),
  `SDM_RESERVE_P_EXACT` (p1). No other value changed.
- **Other docs:** this file (Decision 25 point 9 and its links; the
  status); `project-plan.md` (task 15.2 done; dated notes on tasks
  15.3–15.5); `naming-conventions.md` §6 (the Week-15 slugs, `tbl_17`);
  `handoff.md`. `scripts/09` is not changed: its header gets the choices
  with the code of task 15.3.
- **Next:** the split point — the commit of tasks 15.1–15.2 (`analysis:`
  for `R/00_config.R`, `docs:` for the docs). Then task 15.3 (STEP 15.1).
  *(2026-11-01: the commit was not made; the author commits at the end of
  the week.)*

### 2026-10-31 — Week 15, task 15.1: Decision 25 recorded (no prediction)

- **Entry state:** Week 14 committed (`30a512d`, "Week 14 complete").
- **Docs and config only.** No script, data layer or table changed; no run.
  No prediction was written to a file or computed.
- **Decision 25** (the prediction and its published form): forks a1, b2,
  c1 with n5, d1, e1, f3 (two figures; the legend label; the hatch on
  both), t1, h1. f3 and its two-figure form are not the chat's
  recommendation (f1; one PNG with two panels). The author answered fork
  g: no prediction, covariate table or grid was looked at in a map viewer,
  and no console value outside the documents is remembered.
- **A gap in Decision 24 point 9,** found by the chat at the start of the
  task: point 9 did not say which 1 km cells are "inside" a polygon, or
  what value a 1 km cell gets when its 0.2° cell is not a model cell. Fork
  h raised it before any reserve value; h1 is recorded as a reading of
  point 9 (Decision 25 point 8). The text of Decision 24 does not change.
- **A conflict raised before the record:** f3 adds a figure of the cloglog
  value, and the reasons for c1 and e1 are against a reading of that value
  as a probability. The author chose the legend label and the caption item
  of Decision 25 point 6, and the hatch on both figures.
- **The number of classes:** at the author's request, the chat looked for
  a source for the number. None fixes it for a suitability map; the
  cartography texts give a range of 3 to 7 (Decision 25, "Reason and
  sources"). The author chose n5.
- **The author's answer "n5, 22."** was read as n5 and the label of point
  2 of the chat's question (not a value). The chat said so in its reply.
- **A correction of the fork text:** d1 said that the figure reads a table
  of cell id → class + flag. With f3, the figure also needs the cloglog
  value, so Decision 25 point 4 puts the value in the prediction layer
  (still no presence or background field).
- **Pending items:** "[Week 15] Prediction and publication of the
  suitability surface" closed; "[Week 18] Published path layer" is now
  "[Week 18] Published layers" (it includes the suitability surface).
- **Config:** a new block "Stage 3: prediction and publication (Decision
  25)" in `R/00_config.R` (`SDM_PRED_*`, `SDM_PUB_*`,
  `SDM_RESERVE_CELL_RULE`, `SDM_RESERVE_NONMODEL`). No other value
  changed.
- **Other docs:** the status and §5.4 (a dated note) of this file;
  `references.md` (a new section, "Prediction and publication (Decision
  25)"); `naming-conventions.md` §6 (`fig_04` and `fig_05` reserved);
  `project-plan.md` (task 15.1 done; dated notes on tasks 15.2–15.5, on
  the Week-16 row and on the pitfalls); `handoff.md`. "Limitations" is
  updated in task 15.6, after the run.
- **Next:** task 15.2 — the process choices (the use of the named model
  file and STEP 14.3 check m1; the number of the reserve table and the
  scan of STEP 14.3; the STEP numbers, the slugs and the layer name).

### 2026-10-25 — Week 14 complete: task 14.7 (docs close, the Week-15 plan, a cleanup of two docs)

- **Docs only.** No rule, value, script, data layer or table changed; no
  run.
- **Cleanup (author request, 2026-10-25: this file and the handoff were
  too long).**
  - **This file:** the 39 change-log entries of Weeks 3–13 (2026-09-11 to
    2026-10-18, about 135 KB) moved word for word to a new file,
    `docs/methodology-changelog-archive.md`. Here stay an index of them and
    the results of the closed stages, copied with no change (the last
    entry below the Week-14 entries). The status, §5.4 and §5.5 are written
    again with their dated notes in the text. The Decision log, the pending
    items and the Limitations are not shortened.
  - **`handoff.md`:** written again for the weeks that follow. Removed:
    the weekly log of Weeks 0–13, the "kept for reference" state of Weeks
    10–13, the output lists by week, and the gotchas of closed one-time
    work (git history keeps them; the change log here and its archive hold
    the record of each week). Kept: the fixed context,
    the ways of working, the Week-14 state, the files that later weeks
    read, the results of each stage, the open items, the references to
    verify, the pending Decisions and the gotchas that apply to later work.
- **"Limitations":** seven Week-14 items at the end of the section.
- **Week 14 against proposal question 3 (a record, not text for the
  site):** "Where is habitat suitable for tigers across India, and does
  modelled suitability agree with where reserves are?" — a model is fitted
  at the 0.2° grain (Decisions 23 and 24), and the value for the gate is
  above 0 (mean test Boyce index 0.668). No prediction surface exists yet;
  the second part of the question is the reserve check of Week 15
  (Decision 24 point 9).
- **`project-plan.md`:** Week 14 complete (task 14.8, the commit, by the
  author before the Week-15 chat); the rows of Weeks 15 and 16 written
  again; the **Week-15 task breakdown** (a draft; a plan, not a Decision):
  Decision 25 (the prediction and its published form) first, then the
  process choices, the prediction and the gate, the reserve check, the QA,
  the docs and the commit; the Gi* Decision moves to Week 16 in the draft.
- **Pending items:** dated notes on "[Week 15–16] Gi* settings" (Week 16
  in the draft) and "[Week 15] Prediction and publication" (Decision 25,
  task 15.1).
- **Other docs:** `proposal.md` §8 (a dated note), `README.md` (the status
  and the Stack row), `handoff.md` (written again).
- **Next:** the commit of Week 14 (task 14.8, by the author), then Week 15,
  task 15.1 — Decision 25, before any prediction surface is written or
  seen.

### 2026-10-25 — Week 14, task 14.6 complete: STEP 14.3 (QA of Decisions 23 and 24)

- **Process choices of task 14.6 (all as the chat recommended):**
  - c1 — a second path for the main numbers: the `sdm_qa_*` functions do
    not call the `sdm_*` functions of STEPs 14.1 and 14.2 (as c1 of task
    13.7);
  - m1 — the model file of this run (the path that `save_model()` gives);
    other dated model files are counted, and do not fail a check;
  - h1 — the hand-made cases of STEPs 14.1 to 14.3 are rows of the table,
    with a new hand-made case of the QA functions (`sdm_self_test_143()`,
    15 checks);
  - p1 — the publish checks: (a) no position or cell column, and each
    number column has a known name; (b) no value is a cell id of the grid;
    (c) no file with "tiger" in its name under `outputs/`; (d) the model
    file and the covariate table are under `data/processed/`, and
    `.gitignore` holds `data/processed/**`;
  - s1 — the small-count rule of Decision 22 point 9 is for counts by
    reserve. The QA checks that no `tbl_16` table holds a reserve column or
    a reserve name; a presence count of 1 or 2 by fold or by run is
    allowed, and the smallest presence count is in the value of the check.
  - Rejected: c2 (checks of the tables only), m2 (a failure on a second
    model file), m3 (a model file name with no date), h2 (no new hand-made
    case), p2 (checks (a) and (c) only), s2 (a failure on any presence
    count of 1 or 2).
- **Fixed by the Decisions and the plan (not forks):** the checks of
  Decision 23 "Consequences" (the iNaturalist key and the uncertainty of
  each presence record, the iNaturalist key of each background record, the
  check of point 7, no 0.2° cell or position in a `tbl_16` table, no tiger
  file under `outputs/`) and of Decision 24 "Consequences" (the hand-made
  cases, the check of point 11, no position column). As STEP 13.5 of
  `scripts/08`: the step reads files only, runs in each run after STEP
  14.2, writes `tbl_16_sdm_qa.csv` (group, check, value, pass) first, and
  then a `FALSE` stops the script.
- **The checks (133):**

  | Group | Checks | Content |
  |---|---|---|
  | test case | 57 | The hand-made cases of STEP 14.1 (19), STEP 14.2 (23) and STEP 14.3 (15) |
  | presence | 6 | The iNaturalist key; an uncertainty of 25,000 m or more; 0 records of the Facebook dataset (e1); each point in the 0.2° cell of its stored corner (after a projection to EPSG:4326); the records and the cells counted again |
  | background | 6 | The iNaturalist key; 0 Facebook records; the corner check; the two parts; the cells counted again; the counted cells give the locked outcome |
  | grid | 5 | The cell-id raster on the grid of the stack; the cell counts; the complete-case cells; the model flag; the covariate table against the grid |
  | covariates | 19 | Each column of the covariate table again by `terra::zonal()` on the cell-id raster (6,969 cells); the statistics and the z1 counts of `tbl_16_sdm_covariates.csv`; the kept set by the rule again; r of the 36 pairs by `cor()` |
  | model | 11 | The file of this run; the names of its parts; the check of point 11 with a second walker; the settings against the tables; `maxnet` 0.1.4; K and AICc of the selected model again from the file; the AICc table and the selection rule again; the training AUC again (Wilcoxon) |
  | cv | 7 | The rows; the test cells against the counted cells; training + test; the 2° blocks counted again; the mean and SD rows; AUCdiff; the ranges |
  | sensitivity | 4 | The rows; the bias run against the main model; the window run counted again, with the limits of Decision 23; the labels from ρ and the share |
  | publish | 18 | Checks (a) and (b) for each of the six tables of STEPs 14.1–14.2; (c); (d) two checks; s1; check (b) on the QA table before it is written |

- **Code:** `R/00_functions_sdm.R` — 12 new functions:
  `sdm_qa_corner_fail()`, `sdm_qa_key()`, `sdm_qa_zonal()`,
  `sdm_qa_diff()`, `sdm_qa_kept()`, `sdm_qa_aicc()`, `sdm_qa_select()`,
  `sdm_qa_auc()`, `sdm_qa_largest_part()`, `sdm_qa_id_hits()`,
  `sdm_qa_reserve_hits()`, `sdm_self_test_143()`. `R/00_config.R` — a block
  "Stage 3: QA of the model (task 14.6)" with two check tolerances,
  `SDM_QA_REL_TOL` (1e-9, relative) and `SDM_QA_DEG_TOL` (1e-7°); they are
  tolerances of checks, not values of the analysis (as
  `LCP_VALIDATE_TOL_REL`). `scripts/09` — STEP 14.3 and two input paths
  (`reserves_in`, `gitignore_in`). No new package.
- **Tests in the chat (made-up records only, rule d1):** the hand-made
  case passed (15 of 15). On the made-up project of task 14.5, 133 of 133
  checks passed. Eight faults were made on purpose, and the QA found each:
  a covariate value changed by 1e-6; a `cell_id` column with a real id; a
  reserve name in a table; a part of the model object with the length of
  the data rows; a Facebook record; a wrong stored corner; a `.gitignore`
  without `data/processed/**`; a tiger file under `outputs/`. With the
  faults removed, all checks passed again.
- **The run (project machine, 2026-10-25, `RUN_GRID` and `RUN_COVARIATES`
  `FALSE`):** STEP 14.2 gave the same console values as the run of task
  14.5 (`lq`, multiplier 1; mean test Boyce 0.668, test AUC 0.749, OR10
  0.165; both sensitivity runs "robust") and wrote the model file of
  2026-10-25 again (by w1). STEP 14.3: the hand-made cases 19, 23 and 15
  of 15; **QA 133 of 133 checks pass**; 0.2 minutes. The value of each
  check (a count, or the largest relative difference of the second path)
  is in `tbl_16_sdm_qa.csv`; this record does not repeat them.
- **Decision 23 point 7 (e1):** 0 records of the Facebook dataset in the
  presences and in the background.
- **`git status --short` after the run:** the list after task 14.5, plus
  `outputs/tables/tbl_16_sdm_qa.csv`; nothing under `data/`.
- **Estimates of the chat against the run:** 90–110 checks estimated, 133
  made (the hand-made rows alone are 57); 1–2 minutes estimated for STEP
  14.3, 0.2 minutes on the project machine. The delivery text said "10 new
  `sdm_qa_*` functions"; there are 11 (and `sdm_self_test_143()`).
- **Other docs:** the status; Decision 23 point 7 and Decision 24 "Result
  of the run" (dated notes); `project-plan.md`; `data-dictionary.md`
  (`tbl_16_sdm_qa.csv`); `naming-conventions.md` §6 (`sdm_qa`); the
  handoff.

### 2026-10-25 — Week 14, task 14.5 complete: STEP 14.2 (covariates, AICc, the main model, cross-validation, sensitivity runs)

- **Process choices of task 14.5 (all as the chat recommended):**
  - q1 — the covariate table of the model cells,
    `data/processed/sdm_covariates_cell02.csv` (gitignored; no presence or
    background flag), with the switch `RUN_COVARIATES`;
  - t1 — five `tbl_16` tables: `sdm_covariates`, `sdm_covariate_cor`,
    `sdm_aicc`, `sdm_cv`, `sdm_sensitivity` (`sdm_qa` stays reserved for
    task 14.6);
  - y1 — own code for the Boyce index and the AUC (no new package for
    them);
  - h1 — a hand-made case first (`sdm_self_test_142()`, 23 checks; a
    failure stops the script);
  - w1 — one switch, `RUN_COVARIATES`; the 19 fits run in each run.
  - Rejected: q2 (compute in each run, write nothing), t2 (one long
    table), y2 (`ecospat` and an AUC package), h2 (the hand-made cases in
    task 14.6 only), w2 (a second switch for the fits).
- **Implementation points of Decision 24** (the chat's eight points; the
  author: "Eight points look good"):
  1. The denominator of a share is all complete-case 1 km cells of the
     model cell, water included.
  2. Each fold model uses the selected feature classes and multiplier.
     `addsamplestobackground = TRUE` works on the training cells only. The
     test background is the background cells of the test blocks; the test
     presence cells are not added to it.
  3. The Boyce index: the window is 1/10 of the range of the predictions
     over the 6,969 model cells, at 100 points; P/E = the share of the test
     presence cells in the window ÷ the share of the model cells in the
     window; a window with no model cell is dropped, and no other value is
     removed; the index is the Spearman correlation of P/E and the window
     centre. (`ecospat` also removes repeated P/E values by default;
     Hirzel et al. 2006 does not.)
  4. OR10: the 10th percentile is the R default quantile (type 7).
  5. Training AUC: the 104 presence cells against the 1,486 background
     cells.
  6. Top 20 %: ceiling(0.2 × 6,969) = 1,394 cells, ordered by prediction
     from the highest; a tie goes to the lower cell id.
  7. The 2018–2022 run: its presence and background cells are counted on
     the model cells and the limits of Decision 23 are tested; with 25–79
     presence cells it uses `lq` with the selected multiplier; if it fails
     a limit, the table gives the counts and "not run".
  8. The settlement run: `settl_mean` is in the model formula as the other
     covariates are; the collinearity rule does not apply to it; at
     prediction it is set to its median over the model cells.
  - **In the code, not in the eight points:** "within 2" of point 4 is
    ΔAICc < 2; if two models have the same K and the same AICc, the first
    in the grid order is selected; the predictions are clamped (the
    `predict.maxnet()` default). In the run, no other model has a ΔAICc
    below 9.42, so the first two readings do not change the result.
- **The tie rule of the Boyce index (point 3), given to the author before
  the run.** On made-up values, the chat computed the index with the rule
  and with the successive repeated P/E values removed (the
  `ecospat.boyce()` default, `rm.duplicate = TRUE`):

  | Made-up case | Point 3 (repeats kept) | Successive repeats removed |
  |---|---|---|
  | Presences in the top 15 % of the range only | 0.654 | 0.981 |
  | Presences spread over the top 50 % | 0.861 | 0.406 |
  | Presence density rises with the value | 1.000 | 1.000 |

  So the rule changes the value in both directions, and a Boyce value of
  this project cannot be compared directly with a value from
  `ecospat.boyce()` at its default. The chat gave the option to change
  point 3 before the run (d2); the author ran with point 3 as accepted.
- **As built against the text of t1:** t1 said that the correlation table
  shows whether a candidate is kept. As built, `kept` is in
  `tbl_16_sdm_covariates.csv`, and `tbl_16_sdm_covariate_cor.csv` has
  `above_limit` for each pair. `tbl_16_sdm_cv.csv` also has the blocks,
  the test background cells, the training presence cells, the status and
  the training AUC of each fold, and a row `main`.
- **Code:** `R/00_functions_sdm.R` — 16 new functions (`sdm_covariates()`,
  `sdm_select_covariates()`, `sdm_aicc_value()`, `sdm_fit()`,
  `sdm_predict()`, `sdm_aicc_grid()`, `sdm_select_aicc()`, `sdm_auc()`,
  `sdm_boyce()`, `sdm_or10()`, `sdm_block_id()`, `sdm_fold_blocks()`,
  `sdm_cv()`, `sdm_compare()`, `sdm_object_ok()`, `sdm_self_test_142()`);
  `scripts/09` STEP 14.2 and the switch `RUN_COVARIATES`.
- **Tests in the chat (made-up records only, rule d1):** R 4.3.3, `maxnet`
  0.1.4 (installed from its source) and `glmnet` 4.1.8. The hand-made
  case passed (23 of 23). A made-up project of 1,037 model cells, 90
  presence cells and 1,000 background cells: a first run with `RUN_GRID`
  and `RUN_COVARIATES` `TRUE` and a second with both `FALSE` gave the same
  AICc table; two stop paths were tested (no covariate table with
  `RUN_COVARIATES = FALSE`; a covariate table with one model cell
  missing). Two faults were found and fixed before delivery: two expected
  values of the Boyce test cases were wrong for the tie rule of point 3
  (the test cases were changed, not the function), and a console heading
  had missing spaces.
- **The run (project machine, 2026-10-25, `RUN_GRID = FALSE`,
  `RUN_COVARIATES = TRUE`):** Decision 24, "Result of the run". STEP 14.2
  took 0.2 minutes (the text of w1 guessed 1–3 minutes).
- **`renv::snapshot()` after the run:** seven packages added to
  `renv.lock` — `maxnet` 0.1.4, `glmnet` 5.0, `foreach` 1.5.2,
  `iterators` 1.0.14, `RcppEigen` 0.3.4.0.2, `shape` 1.4.6.1, `survival`
  3.8-3. The chat's tests used `glmnet` 4.1.8; the project-machine run is
  the record.
- **Script after the run:** `RUN_COVARIATES <- FALSE` in `scripts/09`,
  with a dated note; a run note of STEP 14.2 in the header; the closing
  console line no longer asks for `renv::snapshot()`.
- **Outputs:** `data/processed/sdm_covariates_cell02.csv` (6,969 rows) and
  `data/processed/tiger_sdm_maxnet_cell02_20261025.rds` (both
  gitignored); `outputs/tables/tbl_16_sdm_covariates.csv` (10 rows),
  `tbl_16_sdm_covariate_cor.csv` (36), `tbl_16_sdm_aicc.csv` (12),
  `tbl_16_sdm_cv.csv` (8), `tbl_16_sdm_sensitivity.csv` (2) — statistics
  only.
- **`git status --short` after the run:** nothing under `data/`. Nothing of
  Week 14 is committed yet (the split point of the plan was not used), so
  the list holds the files of tasks 14.1 to 14.5. The chat's list of
  expected changes assumed that tasks 14.1–14.4 were committed; that was
  wrong.
- **Facts for task 14.7 (Limitations; not a reading):**
  - the terrain is in the model as `elev_mean` only;
  - the selected multiplier is the lowest value of the grid; no value
    below 1 was tested;
  - the mean OR10 is 0.165; by its definition, OR10 is about 0.10 when the
    test presence cells have the distribution of the training presence
    cells;
  - fold 3 has the lowest Boyce index (0.362) and test AUC (0.655), and
    the highest AUCdiff (0.177);
  - the Boyce values use the tie rule of point 3 (the table above).
- **Other docs:** §5.4 and the status (dated notes); Decision 24 ("Result
  of the run"); the pending item "[Week 15] Prediction and publication"
  (dated note); `project-plan.md`; `data-dictionary.md`;
  `naming-conventions.md` §6; `references.md` (the `ecospat.boyce` help
  page; the locked `maxnet` version); the handoff.

### 2026-10-25 — Week 14, task 14.3: Decision 24 recorded (no covariate summary, no model)

- **Decision 24** (the settings of the planned model) recorded after the
  count of task 14.4 (process choice o2) and before any covariate summary,
  correlation, model or prediction. The chat raised eleven forks with one
  recommended option each; the author chose c1, z1, k1, f3, b1 (b2 as a
  sensitivity run), a1, v1, g2, r3, s3, m1 — each as recommended.
- **Found during the research (facts for the Decision):**
  - The `maxnet` code (`maxnet.R`): with `addsamplestobackground = T`, a
    presence row that is not in the background is added to it; the
    background rows get a weight of 100; the object holds the
    coefficients and summary statistics (`samplemeans`, the minimum and
    maximum of each covariate and feature), not the data rows.
  - ENMeval computes AICc with the raw output scaled to a sum of 1 over the
    study area, K = the non-zero coefficients, and no value when K exceeds
    n.
  - The fork text said "eight covariates"; there are nine candidates
    (slope and TRI were counted as one). Decision 24 point 1 says so.
- **`R/00_config.R`:** a new block "Stage 3: model settings (Decision 24)"
  with the `SDM_*` settings of the Decision. No other value changes.
- **Pending items:** "[Week 14] Model Decisions that Decision 21 names"
  and "[Week 14] Terrain variables in the SDM" closed. New: "[Week 15–16]
  Gi* settings" (point (6) of the closed item) and "[Week 15] Prediction
  and publication of the suitability surface".
- **§5.4** and the status: dated notes.
- **Other docs:** `project-plan.md` (task 14.3 done; dated notes on tasks
  14.5–14.7 and the rows of Weeks 15–16); `references.md` (a new section
  "Model settings (Decision 24)"); `naming-conventions.md` §6 (the model
  file under `data/processed/`); the handoff.
- **Not done in this task:** no covariate summary, no correlation, no
  model, no code.

### 2026-10-25 — Week 14, task 14.4 complete: STEP 14.1 (the 0.2° cells and the count) — outcome `planned_model`

- **Process choices of task 14.4 (as the chat recommended):** k1 — the grid
  `sdm_grid_cell02_7755.gpkg` and the 1 km cell-id raster
  `sdm_cellid_1km_7755.tif` under `data/processed/` (gitignored), with no
  presence or background flag, and the switch `RUN_GRID`; h1 — a hand-made
  case first. By o2, task 14.4 ran before task 14.3 (Decision 24).
- **Code:** `R/00_functions_sdm.R` — `sdm_cell_id()`, `sdm_centre_cells()`,
  `sdm_cell_polygons()`, `sdm_build_grid()`, `sdm_cellid_rast()`,
  `sdm_outcome()`, `sdm_count_cells()`, `sdm_self_test()`;
  `scripts/09` STEP 14.1. The chat tested the code on made-up records only
  (rule d1); one fault was found there and fixed before delivery (a
  polygon ring did not close in floating point).
- **The run (project machine, 2026-10-25, `RUN_GRID = TRUE`):** the
  hand-made case 19 of 19; the guards 35 of 35; 7,450 cells with
  complete-case centres, 6,969 model cells; 104 presence cells (none
  removed by the 50 % rule); 1,486 background cells (part (a) 800, part (b)
  1,200 on model cells); **outcome `planned_model`** (Decision 23,
  "Outcome of points 4 and 6"). `tbl_16_sdm_counts.csv` written (21 rows).
- **Config and script after the run:** `SDM_GRAIN_OUTCOME <-
  "planned_model"`; `RUN_GRID <- FALSE` in `scripts/09`.
- **Facts for Decision 24 (seen):** the counts above; 18 of the 104
  presence cells hold no background record (`maxnet` adds a presence to
  the background by default); the default feature classes at 104
  presences are `lqph`.
- **Other docs:** §5.4 and the status (dated notes); the pending model item
  (dated note); `proposal.md` §8 (the outcome); `project-plan.md`;
  `data-dictionary.md` (the grid, the cell-id raster, `tbl_16_sdm_counts`);
  `naming-conventions.md` §6 (`tbl_16`); the handoff.

### 2026-10-25 — Week 14, task 14.2 complete: process choices, the iNaturalist background, `scripts/09` header and guards

- **Process choices (not numbered; all as the chat recommended):** s1 — one
  script for Weeks 14–16, `scripts/09_model_suitability.R`, one STEP block
  per task; f1 — the functions in a new file, `R/00_functions_sdm.R`; w2 —
  `scripts/08` STEP 13.3 writes the background of Decision 23 r2; g1 — the
  model cells from the complete-case 1 km centres, converted to longitude
  and latitude and given their 0.2° cell by the record rule, with the
  polygon area in EPSG:7755; t1 — `tbl_16_sdm_counts.csv` (task 14.4) and
  `tbl_16_sdm_qa.csv` (task 14.6); l1 — the outcome lock
  `SDM_GRAIN_OUTCOME` (`NA` until task 14.4); r1 — no run switch in task
  14.2. **The order (o2):** the count of task 14.4 comes before Decision 24
  (task 14.3); the covariate summaries and the fit come after it.
- **`scripts/08` (w2):** STEP 13.3 also writes
  `data/processed/effort_background_inat_cell02_7755.gpkg` (gitignored), with
  the 0.2° cell of the GBIF coordinates of each record; guard 2c checks the
  four `SDM_*` values that it uses. `RUN_CLEANING` was `TRUE` for one run,
  then `FALSE` again.
- **The run (project machine, 2026-10-25), `RUN_CLEANING = TRUE`,
  `RUN_SURFACES = FALSE`:**
  - STEPs 13.1–13.3, 13.5 and 13.6 ran. Each Week-13 count is the same
    again: the entry state (tiger 4,606; background 39,057), the attrition,
    the sets (tiger 45 / 17, 300 / 44, 884 / 104; background 20,905 /
    4,554, 23,901 / 5,512, 6,082 / 417, 7,029 / 825), the dataset check
    (6 hits, all cleared) and the counts per reserve.
  - **The new layer:** 16,806 records — part `obscured` 7,029 (the
    obscured background), part `uncert` 9,777. 9,777 is 7,238 + 2,539, the
    two counts of the iNaturalist row of the background dataset check.
  - QA: **172 of 172** checks pass (Week 13: 171). The new check is the
    publish check of `tbl_15_occ_by_reserve.csv`, added in task 13.8. It
    could run only in a run after the table was written, so this run is
    the first with it.
  - `git status --short`: of the tables, only `tbl_15_occ_qa.csv` changed —
    the new row, and the file count of the check "no file with 'tiger' in
    its name under outputs/" (55 → 56; `tbl_15_occ_by_reserve.csv` is the
    56th file). **Each other `tbl_15` table is the same as the committed
    version:** Week 13 gives the same result twice.
- **`scripts/09_model_suitability.R` (new):** the header (the process
  choices and the planned STEPs) and 35 guards: the `SDM_*` block, EPSG:7755,
  the inputs, the fields and CRS of the three layers, the counts of
  `tbl_15_occ_sets.csv`, the `uncert` part against the clean background, and
  the complete-case count of the stack against `tbl_10`. **35 of 35 pass**
  on the project machine; no result is printed.
- **`R/00_functions_sdm.R` (new):** `sdm_check_config()`,
  `sdm_cell_index()`, `sdm_n_cells()`, `sdm_read_fields()`,
  `sdm_run_guards()`. The chat tested them on made-up records only (rule
  d1).
- **`R/00_config.R`:** `SDM_GRAIN_OUTCOME <- NA_character_` (l1).
- **`maxnet`:** `renv::install("maxnet")` gave version 0.1.4.
  `renv::snapshot()` said that the lock file is up to date: renv records a
  package only when a script loads it, and the `scripts/00a` list is a text
  vector. `maxnet` goes into `renv.lock` with the fit STEP (task 14.5).
- **New facts (counts of records, from the console):** the iNaturalist
  entry state of the background has 21,083 records; 2,299 have no
  uncertainty value, and 1,535 have an uncertainty above 5 km and below
  25 km (in no part of the background; Decision 23, "Limitations").
- **Not done in this task:** no count of 0.2° cells; no model.

### 2026-10-25 — Week 14, task 14.1: Decision 23 recorded (no count, no model)

- **Decision 23** (model at a coarser grain) recorded before any count of
  presence or background cells at a coarser grain. The chat raised nine
  forks on 2026-10-18, with one recommended option each; the author chose
  a2, b3, v1, c1, r2, s1, m1, e1, f2 on 2026-10-25. f2 is not the chat's
  recommendation (f1). For e, the chat said that there is nothing to
  choose with b3; e1 is recorded as a check (Decision 23 point 7).
- **Found during the research (facts for the Decision):**
  - The iNaturalist source code puts the public point of an obscured
    record in the same fixed 0.2° cell as the true point. This confirms
    the cell rule of Decision 21 point 4, which was an inference.
  - The pending item "Target-group scope" said that rodents are not
    observed by the methods that record tigers. 5,377 of the 6,361 rodent
    records of the 5 km background are squirrels, which visitors
    photograph.
  - The Phase-1 Gi* used the tiger records (1,411 points, band 50 km;
    Phase-1 final report §3.3).
  - `maxnet` on CRAN is version 0.1.4; by default it adds each presence to
    the background (`addsamplestobackground = T`).
- **`R/00_config.R`:** a new block "Stage 3: model at a coarser grain
  (Decision 23)" with 18 `SDM_*` settings, after the `KDE_*` block; a dated
  comment on the Gi* line of the `KDE_*` block. No other value changes. The
  chat parsed and sourced the file in R 4.3.3 (with `here::here()` replaced
  by `file.path()` in a test copy); the first `source()` on the project
  machine is the check.
- **§5.4** written again; **§5.5** and the status get dated notes.
- **Pending items:** "[Week 13–14 → Week 14] Target-group scope" closed
  (s1). Dated notes on "[Week 14] Model Decisions that Decision 21 names"
  (points (1), (3), (7) closed; (2), (4), (5) to Decision 24; the Gi*
  settings to a numbered Decision in Week 15 or 16), on "Terrain variables
  in the SDM" (to Decision 24) and on "SDM-based resistance" (the grain is
  0.2°).
- **Other docs:** `proposal.md` §8 (an entry); `project-plan.md` (task 14.1
  done, "Changes from Decision 23", dated notes); `references.md` (a new
  section "Model at a coarser grain (Decision 23)"); the handoff.
- **Not done in this task:** no count at a coarser grain, no code in
  `scripts/09`, no model.

### Weeks 3–13 (2026-09-11 to 2026-10-18): archived entries and the results of the closed stages

The 39 change-log entries of Weeks 3–13 are in
`docs/methodology-changelog-archive.md`, word for word (moved on
2026-10-25, task 14.7). A reference to "the change log" of those weeks
points there. The results below are copied from those entries with no
change, because the write-up of Weeks 17–20 needs them.

**Stage 1 — Growth (from the entry "Week 7 complete", 2026-09-20):**

**Reconciliation (task 7.6, verified).** The landscape total, the state total,
and the per-reserve `na.rm` sum agree for every pop round and for `change_abs`:
pop_2014 = 1586, pop_2018 = 1958, pop_2022 = 2257, change_abs = +651;
n_measured = 53. Landscape picture: Central India +282 (+59.7%), Shivalik-Gangetic
+239 (+58.9%), Western Ghats +108 (+19.8%), North-East Hills +22 (+13.2%),
Sundarbans `NA`.

**Stage 2 — Connectivity (from the entry "Week 12 complete", 2026-10-10):**

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

**Week 13 against proposal questions 3 and 4 (from the entry "Week 13
complete", 2026-10-18):**

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

**Index of the archived entries (newest first):**

| Date | Entry |
|---|---|
| 2026-10-18 | Week 13 complete: task 13.9 (docs close) and the Week-14 plan (no code) |
| 2026-10-18 | Week 13, task 13.8 complete: STEP 13.6 (clean records per reserve) |
| 2026-10-18 | Week 13, task 13.7 complete: STEP 13.5 (QA of Decisions 21 and 22) |
| 2026-10-18 | Week 13, task 13.6 complete: STEP 13.4 (density surfaces) |
| 2026-10-17 | Week 13, task 13.5: Decision 22 recorded (no surface, no count) |
| 2026-10-17 | Doc fix pass (Week 13, before task 13.5) |
| 2026-10-17 | Week 13, task 13.4 complete: STEP 13.3 (background), dataset check, target-group scope; split point |
| 2026-10-17 | Week 13, task 13.3 complete: zoo read, STEP 13.2 (tiger records), dataset check, outcome of point 8 |
| 2026-10-11 | Week 13, task 13.2 complete: script, names stage, counts stage; Decision 21 Amendments 1 and 2 |
| 2026-10-11 | Week 13, task 13.1: Decision 21 recorded (no code, no count) |
| 2026-10-10 | Week 12 committed and pushed; Week-13 plan added (no code) |
| 2026-10-10 | Week 12 complete: task 12.10 (note file, Limitations, Stage-2 summary, docs close) |
| 2026-10-10 | Week 12 (in progress): task 12.9 (literature check of the pinch points) |
| 2026-10-10 | Week 12 (in progress): task 12.8 (STEP 12.7 figure `fig_03`) |
| 2026-10-10 | Week 12 (in progress): task 12.7 (STEP 12.6 publishable tables) |
| 2026-10-10 | Week 12 (in progress): task 12.6 (STEP 12.5 pinch-point QA) |
| 2026-10-10 | Week 12 (in progress): task 12.5 (STEP 12.4 variants and the Decision-20 comparison) |
| 2026-10-10 | Week 12 (in progress): task 12.4 (STEP 12.3 sites and pinch points, baseline) |
| 2026-10-10 | Week 12 (in progress): task 12.3 (STEP 12.2 road crossings of the baseline paths) |
| 2026-10-10 | Week 12 (in progress): task 12.2 (process choices; STEP 12.1 barrier-road cells) |
| 2026-10-10 | Week 12, task 12.1: Decision 20 recorded (no code, no crossing) |
| 2026-10-04 | Week 11 complete: tasks 11.2–11.7 (network graph, metrics, variants, QA, literature check, docs) |
| 2026-10-03 | Week 11, task 11.1: Decision 19 recorded (no code, no metric) |
| 2026-10-03 | Text fix before Week 11 (two stale statements) |
| 2026-10-03 | Week 10 complete: tasks 10.4–10.9 (pairs, baseline paths, validation, QA, variants, NTCA overlap, docs) |
| 2026-10-02 | Week 10 (in progress): tasks 10.1–10.3b |
| 2026-09-27 | Documentation fix pass (before Week 10) |
| 2026-09-26 | Week 9 (in progress): task 9.2 rule fixed; corridor layer |
| 2026-09-26 | Documentation fix pass (before Week 9) |
| 2026-09-20 | Week 8: covariate stack assembled (Stage 2 input; Decision 10) |
| 2026-09-20 | Week 7 complete: regional roll-up + growth figures (Stage 1 done) |
| 2026-09-13 | Week 5 complete: census joined, area overwritten, density built |
| 2026-09-13 | Week 5 task 5.1: reserve area source (Decision 8) |
| 2026-09-12 | 2006/2010 secondary table + reference sweep |
| 2026-09-12 | Week 4 prose sweep for table-missing reserves |
| 2026-09-12 | Week 4 census extraction + spot-check (tasks 4.4–4.6) |
| 2026-09-12 | Week 4 missing-year Decision (task 4.2) |
| 2026-09-12 | Week 4 census source location (task 4.1) |
| 2026-09-11 | Week 3 reserve boundary build (`scripts/02`) |

---

## Limitations

*(Carried forward and expanded as the analysis runs. Known at the outset:)*

- **Occurrence bias.** GBIF records concentrate near roads and park gates.
  Suitability and density outputs reflect effort as well as tiger presence. This
  is why the effort thread is a first-class part of the analysis, not a caveat.
- **Census cadence.** NTCA rounds are four years apart; within-period dynamics
  are not captured.
- **Population estimates, not counts — and not one figure type across rounds.**
  NTCA figures are estimates, not counts, and the estimate type changes over the
  series (see Decision 6). 2014, 2018 and 2022 give per-reserve **within-reserve
  SECR** estimates in a table; the point midpoint is used. 2006 and 2010 give no
  such table — reserve-anchored figures appear only in landscape-chapter prose,
  cover a subset of reserves, are **double-sampling** estimates over the reserve
  **plus surrounding occupied forest**, and are therefore not a like-for-like
  baseline for the SECR series. Handling is fixed in Decision 6.
- **Boundary basis (see Decision 4).** No open source holds legal
  tiger-reserve (core + buffer) extents. The chosen source (NTCA DSS KML) stores
  core national-park / sanctuary polygons, which in general under-state reserve
  area (as-built polygon/census ratio median 0.515, 56 reserves; *corrected
  2026-10-02 — earlier text said "near 0.58", but the data give 0.51 for the 55
  reserves before the split*). Geometry is therefore used for mapping and
  connectivity only. All area and density metrics use the official NTCA census
  total area, not the polygon geometry. 55 of 58 reserves match a KML polygon by
  name; each is built from its constituent PA(s) via a hand-reviewed crosswalk
  and dissolved to one polygon (10 reserves are multi-part). Amrabad gets its
  geometry from the state split (Decision 17, D1a), so 56 have geometry.
  Pilibhit and Dholpur-Karauli are kept as geometry-absent rows.
- **One KML polygon held two reserves (corrected 2026-10-02).** The KML
  polygon matched to Nagarjunsagar-Srisailam (`unit_id` 1; ~5,074 km² against a
  census total of 3,296 km², `poly_census_ratio` 1.54) is the undivided reserve:
  2,701 km² of it lies in Telangana, where Amrabad (`unit_id` 51) now is. The
  Week-3 text gave the cause as a coarse envelope of a fragmented sanctuary,
  and said the polygon did not overlap Amrabad because Amrabad's centre fell
  outside it. A published Amrabad point is the Amrabad village, which lies
  2.2 km outside the polygon; it is not the reserve centre (Decision 17). Since
  Decision 17 (D1a), `scripts/02` splits the polygon at the state boundary:
  Nagarjunsagar-Srisailam 2,372.7 km² (ratio 0.72), Amrabad 2,701.2 km² in 2
  polygons (ratio 1.03). Both parts keep the KML's coarse outline, and the
  state line (Natural Earth 1:10 m) is approximate. No census metric is
  affected: area and density are census-sourced.
- **Reserve area is the notified core+buffer total, not a GIS polygon
  (Decision 8).** No census report tabulates area, and ISFR-2021 Ch.4 carries a
  WII digitized-boundary area (a polygon area, 52 reserves) that diverges from the
  legal notified total by a median 5.2% and by >15% for 15 reserves (Bor -84%,
  Orang -84%, Palamau +75%, etc.). `area_km2` and `density_2022` use the notified
  total; ISFR is a cross-check only. Notified figures were consolidated from
  NTCA/state notifications (via the Wikipedia consolidation that cites them), not
  read from 58 individual notification PDFs — they pass national-total and ISFR
  cross-checks but carry that provenance caveat.
- **Resistance parameters are judgement calls.** Documented and justified, not
  ground-truthed against telemetry (which is not public).
- **Two reserves are not in the Stage-2 network (Decision 17, G1).** Pilibhit
  and Dholpur-Karauli have no geometry, so they have no paths and no network
  metrics. Pilibhit lies between Dudhwa and Corbett; Dholpur-Karauli is next to
  Ranthambore.
- **Least-cost routes can differ from documented corridors (author choice
  L1, 2026-10-03).** A least-cost path follows the resistance values, which
  are judgement calls (Decisions 14–16). Where the surface gives a high cost
  to river islands or to a narrow degraded link, the path can take a longer
  route than the corridor that tigers are documented to use. Two baseline
  cases: Nameri–Kaziranga and Kaziranga–Orang avoid the Brahmaputra islands,
  through which NTCA records connectivity (water value, Decision 14); and
  Bandhavgarh–Panna goes round the direct corridor that NTCA records (a
  ~30 km gap along the Ken and Midhassan). The validation shows these are true
  least-cost paths on the baseline surface. Sources: `references.md`,
  "Week-10 path extremes".
- **Paths stay inside India.** The resistance surfaces are `NA` on every cell
  outside India, so no least-cost path can cross Nepal, Bhutan, Bangladesh or
  Myanmar. Transboundary links (for example Valmiki–Chitwan, Manas–Royal Manas,
  the Sundarbans) are not represented, and a reserve on the border can appear
  more isolated than it is.
- **The network comes from geometry rules, with no cost threshold (Decisions
  17 and 19).** A pair is a link if it passes the adjacency and 315 km rules
  and P3; its cost is only the weight. Some links have no support in the
  literature, or the literature describes a barrier there: Orang–Dampa (a
  305 km gap, the only link of Dampa; no source found); Anamalai–
  Srivilliputhur-Megamalai (connection along Kerala is described as
  non-existent); Periyar–Kalakad-Mundanthurai (the Shencottah gap; the cost
  is low, 98.8 resistance-km); Sariska–Rajaji (the only north–central link;
  the populations are genetically distinct). By the rule no reserve is
  "isolated": each reserve has a pair inside 315 km. The graded columns
  (`pendant`, `cheapest_link_rkm`) and the threshold scan carry that
  information. Sources: `references.md`, "Week-11 network".
- **Linchpin labels are from shortest-path betweenness (Decision 19).** One
  route for each node pair; all node pairs of a set count the same at any
  distance; P3 gives betweenness to a reserve that lies between two others;
  the numbers 3, 0.9 and 2/3 are judgement values. Two labels depend on a
  choice: **Madhav** is rank 1 only with the cross-group link Sariska–Rajaji
  in the graph (`cross_group_dependent`; rank 5 without it), and no source
  was found that gives Madhav a high centrality; **Sanjay Dubri** is not a
  linchpin on `noghm` and `road50` (not stable). Current-flow centrality, the
  measure of Dutta et al. (2016), was not built.
- **Nodes follow the contiguity rule of Decision 17 (author choice g1,
  2026-10-04).** Contiguous means a shared footprint cell. Guru Ghasidas-Tamor
  Pingla and Sanjay Dubri are described as contiguous in the sources, but the
  KML polygons are 1.59 km apart, so they are two nodes — and both are
  baseline linchpins (ranks 2 and 3 of set 1). Biligiri Ranganatha Temple is
  named in the sources as part of the Bandipur block, but it is 10.1 km from
  Sathyamangalam, so it is a separate, pendant node. The KML polygons are
  national-park and sanctuary outlines (see "Boundary basis"), so a gap
  between two polygons does not show a gap between two notified reserves. The rule was fixed
  before the paths and was not changed after the results.
- **Block members share one value.** The metrics table has one row per
  reserve (56) but the values are per node (47). The 8 linchpin nodes are 13
  reserve rows. Count by `node_id`.
- **A pinch point is a position in the network, not a measure of the effect
  of a road (Decision 20).** A pinch point is a site where a barrier road
  meets a modelled path that is a bridge edge, or that two or more edges
  share. The rule uses the graph of Decision 19 and nothing more: no traffic
  volume, no road width, no record of animals on roads. It is not the pinch
  point of circuit-theory mapping (a narrow part of a corridor with high
  current flow); a least-cost path has no width. The tiers give no order
  inside a tier, and the road class is a description only.
- **The pinch-point label separates little.** 200 of the 365 baseline sites
  (54.8 %) are pinch points. Each crossing on a bridge edge is a pinch
  point, so the 13 bridge edges give 101 of them, and Sariska–Rajaji alone
  gives 21. Tier 1 is the only short list (3 sites). The count of pinch
  points on the edges of a node (`tbl_03`) follows the number and the length
  of its edges; it is not an order of nodes.
- **The pinch points are sensitive to the gHM multiplier (Decision 20 point
  6).** Without the multiplier (`noghm`) the site overlap is 0.520, below
  the limit of 2/3; the road variants give 0.866 and 0.820. 98 of the 200
  baseline pinch points have a variant pinch point within 5 km on all three
  variants; 3 have one on none (`n_variants_near`). The path routes
  (Decision 18) and the network (Decision 19) were robust on the same
  variants, and Decision 20 named a robust result as the more likely one;
  that forecast was wrong.
- **A road inside a node has no crossing.** A path goes from the edge of one
  node to the edge of another; no path is modelled inside a node or between
  the parts of one reserve. NH 766 through Bandipur has had a night traffic
  ban for years, and it is not in the tables: Bandipur, Nagarhole, Mudumalai
  and Sathyamangalam are one node. The same applies to the road between the
  two parts of Nawegaon-Nagzira.
- **A documented crossing place can be a crossing that is not a pinch
  point.** NH-44 at Pench (Maharashtra) has monitored crossing structures
  that tigers use (Saxena & Habib 2022). The paths in Nagpur district have
  road crossings on three links (`tbl_14_road_crossings.csv`); none is a
  pinch point, because one edge uses each and no edge there is a bridge.
  The full list of crossings is `tbl_14_road_crossings.csv`, not `tbl_03b`.
- **Pinch points on links without literature support.** 33 of the 200 pinch
  points are on sites whose edges all have `lit_flag` (Orang–Dampa,
  Anamalai–Srivilliputhur-Megamalai, Periyar–Kalakad-Mundanthurai,
  Sariska–Rajaji). The path Sariska–Rajaji has 35 crossings, 7 of them in
  Delhi, and the site with the longest span (22.6 km): a least-cost path
  through a city shows how weak this geometry-rule link is. Two of the three
  tier-1 pinch points are on a site that Orang–Dampa uses.
- **Roads are the OpenStreetMap class only.** The road layer holds two
  fields, the OSM id and the class. It has no road name, no traffic volume,
  and no tag for a bridge, a tunnel or a crossing structure: a road on a
  viaduct is a barrier cell like any other. A pinch point thus cannot be
  matched to a named road. Class tagging in OSM is not the same in all
  states (Decision 15), and a road that was built or planned after the
  extract is not in the layer.
- **Published position: a 10 km cell; state and district from two layers.**
  A crossing is one or more 1 km cells; the tables and the figure give the
  10 km cell (Decision 20 point 7). The state is from Natural Earth and the
  district from the DataMeet Census-2011 layer, so a few rows have a state
  and a district that do not agree at a border (for example a Haryana state
  with a Delhi district), and a district made after 2011 has its 2011 name.
- **The literature check of the pinch points is at the level of link and
  district, and its sources are news reports.** No source confirms a tier-1
  pinch point as a known tiger crossing place. 6 of the 21 groups have no
  source. Each group had one or two searches. Sources: `references.md`,
  "Week-12 pinch points".
- **`fig_03` at national scale.** Marks in the same 10 km cell or in
  adjacent cells overlap: the 200 pinch points are in 194 cells, and the 3
  tier-1 pinch points show as 2 marks. Tier 3 is small and pale by author
  choice. The thin lines of the links that are not bridges are faint. The
  title, the subtitle and the caption are draft text.

*(Week 13, added 2026-10-18 at the Week-13 close. Decisions 21 and 22 each
keep their own list of limitations; the items below are the ones that a
reader of the Stage-3 result needs.)*

- **Few clean tiger records, from few sources (Decision 21).** Of the 4,606
  GBIF tiger records inside India, 300 pass the rule (the 5 km set, 44
  cells of 1 km). 45 of them have an uncertainty of 1 km or less (the 1 km
  set, 17 cells), below the minimum of 25 cells for a 1 km model (Decision
  21 point 8: `no_1km_model`). One dataset, "Bengal Tiger (Panthera
  tigris) Sighting based on Photographs from Facebook in India", gives 273
  of the 300 records; its GBIF entry does not say how a position was given
  to a photograph. The 5 km set has records in 10 of the 56 reserve
  polygons, the 1 km set in 6. The clean records show where tigers were
  recorded and published on GBIF, not where tigers are, and a presence
  cell is not a count of tigers.
- **The uncertainty rule removes most records, and it trusts the
  publisher.** 2,912 tiger records have an uncertainty above 5 km and 313
  have no value. All 1,842 iNaturalist tiger records have an uncertainty of
  25 km or more (obscured positions). The value comes from the observer or
  the publisher: a small value can be wrong (one background publisher
  replaced 0 m with 30 m or 100 m), and a record with no value can be
  precise. The dataset check (Decision 21, Amendment 2) reads the GBIF
  description of a dataset, not its records.
- **The obscured set is not a 1 km presence.** 884 iNaturalist records in
  104 cells of 0.2°. A record goes into the set by inference (the dataset
  and the uncertainty value); GBIF has no field for an obscured position.
  Two random points in one 0.2° cell are about 10 km apart on average. No
  obscured background is kept (Decision 21 point 4), so the set has no
  background of the same rule.
- **The tiger records and the background do not have the same observers
  or the same years.** Most mammal records pass the uncertainty rule; the
  iNaturalist tiger records do not. 268 of the 300 records of the tiger
  5 km set are from 2018–2022. 5,355 of the 6,082 records of the matched
  1 km background are from 2006–2017, and 4,829 of the 6,082 come from two
  Valparai and Anamalai datasets. The matched set shows the observer
  difference; it does not remove it. The window is 17 years (2006–2022);
  the covariates are from 2021 and 2022.
- **The rule cannot find each wrong record.** The centroids are the
  polygon centroids of this project, not the points of a gazetteer. The
  OpenStreetMap zoo layer is not complete (coverage for India not known),
  so a captive animal at a place with no zoo tag stays. A material sample
  can be from a captive or a dead animal. The species identification and
  the datum are not checked. Decision 21, "Limitations", gives the full
  list.
- **The largest group of the tiger 1 km set is outside the reserve
  polygons.** The 18 records of the 1 km set from 2018–2022 are in one cell
  (`tbl_15_occ_window_counts.csv`). Each reserve row of
  `tbl_15_occ_by_reserve.csv` has fewer than 18 records of that set, so the
  cell is outside all reserve polygons. The cause is not known; none of
  these was checked: a buffer zone, a captive or rescue site with no zoo
  tag, one position given to many photographs. With the cell as the unit
  (Decision 22 point 3), the cell counts 1 in the surfaces.
- **The effort surface shows records, not search effort (Decision 22).**
  It shows where mammal records are, not where people looked: a survey
  with no record leaves no trace. iNaturalist gives 21,083 of the 39,057
  background records of the entry state; the cell unit makes the weight of
  one source smaller and does not remove it. The windows have 5, 7 and 5
  years, and the counts are not divided by the years. A change between the
  windows (background 5 km set: 623, 2,304 and 3,569 cells) mixes a change
  of effort with the growth of the recording platforms.
- **The tiger-record surface describes 44 cells.** One dataset gives 273
  of its 300 records, and 26 of its 44 cells have a record of 2018–2022.
  It is not a suitability surface, and it is not published.
- **The surfaces depend on the kernel choices.** 20 km is the Phase-1
  radius, not a value tested on these data. Against the 20 km surfaces,
  the Spearman rank correlation is 0.79–0.80 at 10 km and 0.90–0.91 at
  30 km (`tbl_15_kde_radius_compare.csv`), so the order of the cells
  changes with the radius. The edge correction assumes that the rate
  outside the window is the rate inside it; at 20 km, 8,843 window cells
  have less than half of the kernel mass inside the window.
- **The settlement surface uses OpenStreetMap cities and towns.** The
  layer holds about 58 % of the Census-2011 towns (a rough comparison), and
  its coverage by region is not known.
- **"In a reserve" means inside the KML polygon (task 13.8).** The
  polygons are national-park and sanctuary outlines (polygon/census ratio
  median 0.515), so a record in a buffer zone counts as outside. A position
  of the 5 km sets can be up to 5 km from the true position, so a record
  near a polygon edge can be on the wrong side of it. Pilibhit and
  Dholpur-Karauli have no polygon, and their counts are `NA`.
- **Reserve polygons overlap.** 6 pairs of polygons overlap, 20.7 km² in
  total (the largest: Bandipur–Sathyamangalam, 10.9 km²). By author choice
  o1 a record in two polygons counts in each, so the reserve rows add up
  to more than the records inside: 13 background records (all in the
  Parambikulam–Anamalai overlap) count two times. The reserve layer is not
  changed; the Stage-2 results use it.
- **Small tiger counts are suppressed.** In `tbl_15_occ_by_reserve.csv` a
  tiger count of 1 or 2 is `<3` (Decision 22 point 9). A reader cannot add
  the tiger columns. The number of tiger records inside all reserve
  polygons is not published, because it would give the sum of the
  suppressed counts.

*(Week 14, added 2026-10-25 at the Week-14 close. Decisions 23 and 24 each
keep their own list of limitations; the items below are the ones that a
reader of the Stage-3 result needs. The prediction and the reserve check
come in Week 15.)*

- **A model at about 20 km, on obscured records (Decision 23).** A
  presence cell is a 0.2° cell (about 450 km²) with one or more obscured
  iNaturalist tiger records: 104 cells. The true position of a record is
  in its cell, and not known in it. A tiger uses a part of a cell; a cell
  summary does not show which part. All presences and all background
  records are from one platform.
- **The terrain is in the model as elevation only.** The collinearity rule
  (Decision 24 point 3) removed slope and TRI (each |r| > 0.7 with
  elevation, which comes first in the fixed order) and the crop share. The
  six covariates are the mean of gHM, elevation and distance to road and
  the shares of forest, open natural and built land. The land cover is of
  2021 and gHM of 2022; the records are of 2006–2022.
- **A simple model, at the edge of the grid.** AICc selected `lq` with
  multiplier 1 (10 coefficients), and no other model was within 2. The
  multiplier is the lowest value of the grid; no value below 1 was tested.
- **What the evaluation says.** Over 5 folds of 2° blocks: a mean test
  Boyce index of 0.668 (SD 0.177; fold 3: 0.362) and a mean test AUC of
  0.749 (fold 3: 0.655). The mean OR10 is 0.165; by its definition, OR10 is
  about 0.10 when the test presence cells have the distribution of the
  training presence cells. The AUC compares presence cells with background
  cells, not with absences. The block size is a judgement value; the range
  of spatial autocorrelation was not estimated.
- **The Boyce values are not the `ecospat.boyce()` default.**
  Implementation point 3 of Decision 24 keeps repeated P/E values;
  `ecospat.boyce()` removes successive repeats by default. On made-up
  values the two rules give different values in both directions (change
  log, task 14.5). A published Boyce value says which rule it uses.
- **The background is records, not search effort.** It shows where mammal
  records are on iNaturalist; 18 of the 104 presence cells have no
  background record (`maxnet` adds them to the background).
- **Two sensitivity runs only.** Both are "robust": the settlement bias
  covariate (ρ 0.988) and the records of 2018–2022 only (71 presence cells;
  ρ 0.991). The grain, the cover rule and the covariate list were not
  tested.

*(Week 15, added 2026-11-01 at the Week-15 close. Decision 25 keeps its
own list of limitations; the items below are the ones that a reader of the
prediction and the reserve check needs.)*

- **Relative suitability, not a probability of presence (Decision 25).**
  Presence–background data need one more datum, such as the prevalence, for
  an absolute probability of presence. The five classes have equal counts
  by construction: class 5 is the top 20 % of the model cells of India,
  not "suitable land" in an absolute sense, and the map gives no share of
  suitable land.
- **One value for each 0.2° cell.** A 1 km cell takes the value of its 0.2°
  cell. A small reserve takes its value from one or two 0.2° cells (for
  example Veerangana Durgavati, 24 1 km cells; Orang, 71; Bor, 80), and
  reserves near each other share cells.
- **Cells outside the training range.** 32 of the 6,969 model cells (gHM
  below the minimum: 20; elevation below the minimum: 5, above the maximum:
  1; the open share above the maximum: 7). Their values are clamped; the
  figures hatch them. One reserve value uses such cells: Mukundara Hills,
  19 of its 316 1 km cells. By the author's choice m1 (task 15.6), the
  reserve table does not show this; the figures show the hatch. The flag
  uses each covariate alone and does not show a new combination of values.
- **Reserves at the coast and the border lose cells.** 1,564 complete-case
  1 km cells of 6 reserves are in 0.2° cells that are not model cells, and
  are left out of the reserve value: Dudhwa 28 % of its cells, Namdapha
  26 %, Valmiki 26 %, Sundarbans 25 %, Manas 9.5 %, Buxa 2.5 %.
- **r1 "agrees", with its limits (Decision 24 point 9).** ρ = 0.379 over 51
  reserves, p = 0.006. The census density is per notified total area,
  while the polygon is the core protected-area outline (Decisions 4 and 8).
  r1 is partly linked to the presences: a reserve with many tigers
  probably has many visitors and records. Five reserves with a value have
  no 2022 density and are not in r1 (among them the Sundarbans, which has
  the highest reserve value). The reading is the rule of Decision 24; it is
  not a test of the model at the scale of a reserve.
- **r2 is not published (Decision 25 point 9).** 55 of the 56 reserves with
  a value are above the median of the model cells, so a count of the
  2 × 2 table is below 3. The question of r2 (does the model rate the
  reserves with no presence cell as suitable?) has no published answer.
- **The reserve values are high as a group.** 55 of 56 are above the
  median of the model cells (0.2898); the lowest is Kamlang (0.180). The
  effort caveat (proposal §7) applies: tiger photographs are probably taken
  where visitors go, mostly in reserves, and the mammal background may not
  correct all of that effort (not tested).
- **Static figures only, so far.** No layer that a reader can zoom or
  download before the Week-18 rule (pending item "Published layers").
