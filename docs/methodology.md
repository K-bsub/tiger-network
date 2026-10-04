# Methodology

**Project:** India's Tiger Network
**Author:** Kiran Balasubramanian
**Status:** Week 10 complete — **Stage 2 (Connectivity) least-cost paths
built.** 106 reserve pairs and their edge-to-edge least-cost paths on four
surfaces (`lcp_reserve_network_7755.gpkg`; Decisions 17–18); validation, QA,
the Decision-18 variant comparison (gHM multiplier and road value both robust)
and a descriptive NTCA-corridor overlap (`tbl_12_*`). Next: Week 11 — the
functional-link Decision, then the network graph. Prior: Week 9 —
resistance surfaces (Decisions 11–16).

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
sensitivity variants. Least-cost paths between neighbouring reserve pairs; the
pair rule, the path method and the tool (`leastcostpath` or `gdistance`) are
fixed in Decision 17 (Week 10). Reserve
network as a graph (`igraph`): betweenness identifies linchpin reserves,
components identify isolated reserves. Road crossings give pinch points.
All Stage-2 steps (Weeks 9–12: resistance, least-cost paths, network graph,
pinch points) are built in **one script, `scripts/07_connectivity.R`**, with one
STEP block per task.

### 5.4 Habitat suitability (priority 3)

`maxnet` SDM on cleaned occurrences and the covariate stack, with a
target-group background for sampling-bias correction. National prediction,
validated against reserve locations. **This is suitability, not occupancy**
(Decision 1).

### 5.5 Effort thread (cross-cutting)

Target-group background (all Mammalia occurrences, tiger excluded — Decision 5)
as the effort proxy. KDE and Getis-Ord Gi* reproduce and generalise the Phase 1
observer-bias finding (the Ranthambore cold spot) at national scale.

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

### Decisions pending (raised, not yet made)

These forks are open. Each is decided in the week noted in the project plan,
before the relevant code is written.

- **[Week 8–9 → Week 13] Settlement layer for the KDE.** The OSM settlement pull is
  village-dominated (~195k of 199,800 points: city 495, town 4,102, village
  195,203). A 15 km KDE over all points will near-saturate nationally. Decide
  whether to use all city/town/village, trim to city/town (4,597), or change the
  KDE radius, when the density surface is built.
- **[Week 11] Functional-link rule (raised 2026-10-01, Decision 17 point 8;
  decide before the network metrics are computed).** How the Week-11 graph
  treats a pair as a functional link (for example a cost-distance threshold,
  or cost as an edge weight with no threshold), and therefore whether the four
  network groups are separate and which reserves are isolated. Also decide
  whether the network metrics are repeated on the variant surfaces (raised
  2026-10-01 with Decision 18).
- **[After Stage 3] SDM-based resistance + circuit-theory check.** Raised
  2026-09-26 (Decision 14, F1). After the SDM exists, build a resistance
  surface from 1 − suitability and run circuit theory between reserves, to
  reproduce the national method (Jhala et al. 2021; Qureshi et al. 2014) as
  closely as the data allow and compare it with the Stage-2 least-cost paths.
  Decide then: the transform (linear 1 − suitability as in the national method,
  or a negative exponential as Keeley et al. 2016 recommend for long-distance
  movers), and the tool (at ~3 million cells, probably Circuitscape or
  Omniscape outside R). Not yet in the week plan.
- **[Week 13–14] Target-group scope.** Decision 5 pulled all Mammalia. Decide at
  model fit whether to narrow to a large-bodied guild (carnivores + ungulates,
  the camera-trap/sighting group that shares the tiger's detection method),
  based on observed record volumes.
- **[Week 14] Terrain variables in the SDM.** Elevation, slope, and TRI are all
  acquired. Decide which enter the model after a collinearity check (slope and
  TRI are correlated; both may not be needed). **Also decide how to treat
  elevation on water and coastal cells:** the stack elevation now reaches
  −434.2 m (Week 8: −111.6 m; after the Decision-11 fill: −344.8 m; after
  Decision 13: −434.2 m — read the current value in `tbl_10`), and India's
  lowest land is about −2 m. The AWS terrain tiles probably carry sea-floor depths for water.
  The Week-2 note "coastal/salt-flat lows" for the raw −413 m minimum is
  probably the same artefact (not verified).

---

## Change log

*(Records as-built changes to data, code, or scope during execution.)*

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
