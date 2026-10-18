# Methodology

**Project:** India's Tiger Network
**Author:** Kiran Balasubramanian
**Status:** **Week 13 complete (2026-10-11 to 2026-10-18) — Stage 3
(habitat suitability) has started.** **Decision 21** (occurrence cleaning)
was recorded on 2026-10-11 before any cleaned count, with Amendment 1
(record types: c2) and Amendment 2 (a dataset check: v1). **Decision 22**
(effort surfaces) was recorded on 2026-10-17 before any density surface.
`scripts/08_prepare_occurrences.R` STEPs 13.1–13.6 ran on the project
machine. Clean tiger records: 300 (1 km set: 45 records in 17 cells; 5 km
set: 300 records in 44 cells); obscured set: 884 records in 104 cells of
0.2°; clean background: 23,901 records. The outcome of Decision 21 point 8
is **no 1 km suitability model**. The 11 surfaces of Decision 22 are built
(effort, tiger records and city/town at 20 km; two effort window surfaces;
six QA surfaces); the tiger surface is never published. QA: 171 of 171
checks pass (`tbl_15_occ_qa.csv`). Clean records per reserve:
`tbl_15_occ_by_reserve.csv` (a tiger count of 1 or 2 is published as
`<3`). Thirteen Week-13 items are at the end of "Limitations". Week 13 is
committed (task 13.10, 2026-10-18). Next: **Week 14**, which starts with
**Decision 23**: a suitability model at a coarser grain, or no model (Stage 3 then
gives the effort result). Prior: **Week 12 — Stage 2 (Connectivity)
complete**: road pinch points by Decision 20 (200 pinch points; the gHM
multiplier is "sensitive" for them); publishable `tbl_03_reserve_network.csv`,
`tbl_03b_pinch_points.csv`, `tbl_03_notes.md` and
`fig_03_reserve_network.png` (positions at a 10 km grid cell; the figure
text is a draft); the Stage-2 summary against proposal question 2 is in the
change log (2026-10-10, "Week 12 complete"). Week 11 — reserve network
(Decision 19); Week 10 — least-cost paths (Decisions 17–18).

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

`maxnet` SDM on cleaned occurrences and the covariate stack, with a
target-group background for sampling-bias correction. National prediction,
validated against reserve locations. **This is suitability, not occupancy**
(Decision 1).
*(2026-10-17: the outcome of Decision 21 point 8 is `no_1km_model` — the
tiger 1 km set has 45 records in 17 cells. No `maxnet` model is fitted at
1 km. Week 14 starts with a Decision between no model and a model at a
coarser grain; this section is written again after that Decision.)*

### 5.5 Effort thread (cross-cutting)

Target-group background (all Mammalia occurrences, tiger excluded — Decision 5)
as the effort proxy. KDE and Getis-Ord Gi* reproduce and generalise the Phase 1
observer-bias finding (the Ranthambore cold spot) at national scale.
*(2026-10-17, Decision 22: Week 13 builds three density surfaces — effort,
tiger records and city/town settlements — with a quartic kernel of 20 km
radius. The tiger surface is not published. Gi* is not built in Week 13; the
Week-14 model Decision decides it.)*

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

### Decisions pending (raised, not yet made)

These forks are open. Each is decided in the week noted in the project plan,
before the relevant code is written.

- **[Week 18] Published path layer (raised 2026-10-10 with Decision 20;
  decide before a path layer goes on the site).** Decision 20 point 7 allows
  the path lines in a static figure at national scale only. An interactive
  or downloadable path layer (the Stage-4 Leaflet maps) lets a reader zoom to
  1 km and find a crossing position that the tables give at 10 km. Decide:
  no path layer on the site, lines simplified to a fixed tolerance, or a
  zoom limit.
- **[Week 14] Model Decisions that Decision 21 names (raised 2026-10-11;
  decide before a model is fitted).** (1) By the outcome of Decision 21
  point 8: below 25 presence cells, no suitability model or a model at a
  coarser grain (inputs: the 5 km set and the obscured set); from 25 to 79,
  the settings of the reduced model (linear and quadratic at most); from
  80, the settings of the planned model. (2) The comparison rule and the
  labels for the two sensitivity sets (`uncert5km`, `matched`). (3) A
  minimum size for a background set. The cleaned counts of Week 13 will be
  seen by then; each of these Decisions must say so.
  *(2026-10-17, after task 13.3: the outcome is `no_1km_model` (17 cells).
  Item (1) is the Decision between no model and a model at a coarser grain.
  Item (2) does not apply (point 9). Item (3) applies only if a model is
  chosen. Facts for the Decision, all seen:
  - the 5 km set: 300 records in 44 cells of 1 km; the obscured set: 884
    records in 104 cells of 0.2°;
  - one dataset, "Bengal Tiger (Panthera tigris) Sighting based on
    Photographs from Facebook in India" (`ff8a7785-…`), gives 20 of the 45
    records of the 1 km set and 273 of the 300 records of the 5 km set
    (91 %; 253 of them with an uncertainty above 1 km); its GBIF entry does
    not say how a position was given to a photograph *(corrected
    2026-10-17: this line said 253 of 300 (84 %); the dataset-check column
    `n_5km` counts the records above 1 km only)*;
  - the records are grouped: 45 records in 17 cells, 300 records in 44
    cells;
  - each obscured record is from iNaturalist (Decision 21 point 4).
  After task 13.4, about the background, all seen: the 1 km background has
  20,905 records in 4,554 cells; the matched 1 km background has 6,082
  records in 417 cells, and 4,829 of them (79 %) come from the two Valparai
  and Anamalai datasets, so it is mostly one area; the zoo step removed 517
  background records and no tiger record.)*
  *(2026-10-17, Decision 22: the model Decision also decides (4) whether
  the effort surface is a bias input of a model at a coarser grain; (5)
  whether the settlement surface is an observer-bias covariate; (6) Getis-Ord
  Gi*: built or not, where, and its distance band (the Phase-1 documents
  give 50 km and 25 km); (7) any ratio of the tiger and the effort surfaces.)*
  *(2026-10-18, after task 13.6, seen — the counts by window: 268 of the 300
  records of the tiger 5 km set are from 2018–2022 (26 of its 44 cells have
  a record of that window); 18 of the 45 records of the tiger 1 km set are
  from 2018–2022, all in one cell; 5,355 of the 6,082 records of the
  matched 1 km background are from 2006–2017. The time of the matched
  background and of the tiger records is thus not the same. Full counts in
  `tbl_15_occ_window_counts.csv`.)*
  *(2026-10-18, Week-13 close, seen — the counts per reserve (task 13.8,
  `tbl_15_occ_by_reserve.csv`): reserves with one or more records — tiger
  1 km set 6, tiger 5 km set 10, background 5 km set 45. The 18 records of
  the tiger 1 km set from 2018–2022 are in one cell, and each reserve row
  has fewer than 18 records of that set, so the cell is outside all
  reserve polygons; the cause is not known. The Week-14 plan
  (`project-plan.md`, "Week 14 — task breakdown") makes item (1)
  **Decision 23** (task 14.1), before any count at a coarser grain. Points
  (3) to (7) and the target-group item go into Decision 23 or into the
  Decision 24 of the branch that it picks.)*
- **[After Stage 3] SDM-based resistance + circuit-theory check.** Raised
  2026-09-26 (Decision 14, F1). After the SDM exists, build a resistance
  surface from 1 − suitability and run circuit theory between reserves, to
  reproduce the national method (Jhala et al. 2021; Qureshi et al. 2014) as
  closely as the data allow and compare it with the Stage-2 least-cost paths.
  Decide then: the transform (linear 1 − suitability as in the national method,
  or a negative exponential as Keeley et al. 2016 recommend for long-distance
  movers), and the tool (at ~3 million cells, probably Circuitscape or
  Omniscape outside R). Not yet in the week plan.
- **[Week 13–14 → Week 14] Target-group scope.** Decision 5 pulled all Mammalia. Decide at
  model fit whether to narrow to a large-bodied guild (carnivores + ungulates,
  the camera-trap/sighting group that shares the tiger's detection method),
  based on observed record volumes. *(2026-10-11: Decision 21 adds a
  matched background, by dataset. It tests the observer group; this item is
  about the taxa. The two are separate.)* *(2026-10-17, task 13.4, author
  choice g1: **carried to the Week-14 model Decision**. Reason: there is no
  1 km model (Decision 21 point 8), and the scope matters only if a
  coarse-grain model is chosen. Evidence: `tbl_15_background_taxa.csv` (46
  order and family rows). The 23,901 kept background records by order:
  Artiodactyla 6,853; Rodentia 6,361; Primates 5,014; Carnivora 3,409;
  Chiroptera 746; Proboscidea 682; Lagomorpha 362; Perissodactyla 233;
  Cetacea 140; Soricomorpha 43; Scandentia 31; Erinaceomorpha 12; no order
  15. Rodents, bats and whales are not observed by the methods that record
  tigers. The rejected option was g2: decide the scope now, after the
  background counts were seen.)*
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
