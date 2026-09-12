# Methodology

**Project:** India's Tiger Network
**Author:** Kiran Balasubramanian
**Status:** Week 2 — data acquisition underway (GBIF pulls complete). No
analysis has run.

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

Per-reserve census metrics across five NTCA rounds (2006–2022): absolute change,
percent growth, average annual growth rate (AAGR), and density (tigers/100 km²).
Roll-up to landscape complex and state. Animated choropleth of growth category
across census years.

### 5.3 Connectivity (priority 2)

Resistance surface from land cover (ESA WorldCover) and roads as barriers.
Least-cost paths between neighbouring reserve pairs (`leastcostpath`). Reserve
network as a graph (`igraph`): betweenness identifies linchpin reserves,
components identify isolated reserves. Road crossings give pinch points.

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

---

### Decisions pending (raised, not yet made)

These forks are open. Each is decided in the week noted in the project plan,
before the relevant code is written.

- **[Week 4] Missing-year census handling.** How to treat reserves that lack a
  figure in one or more rounds (the Kaziranga-2006 problem, at scale).
- **[Week 9] Land-cover resistance values.** The `WORLDCOVER_RESISTANCE` lookup
  in `R/00_config.R` holds literature-informed starting values; the final set is
  a numbered Decision before the resistance surface is built.
- **[Week 8–9] Settlement layer for the KDE.** The OSM settlement pull is
  village-dominated (~195k of 199,800 points: city 495, town 4,102, village
  195,203). A 15 km KDE over all points will near-saturate nationally. Decide
  whether to use all city/town/village, trim to city/town (4,597), or change the
  KDE radius, when the density surface is built.
- **[Week 9] Road classes for the barrier surface.** The OSM road pull keeps
  motorway–tertiary (885,669 features, tertiary-dominated: 432,689). Decide
  whether tertiary stays in the barrier/resistance surface or the layer is
  restricted to motorway–secondary, when the resistance surface is built.
- **[Week 13–14] Target-group scope.** Decision 5 pulled all Mammalia. Decide at
  model fit whether to narrow to a large-bodied guild (carnivores + ungulates,
  the camera-trap/sighting group that shares the tiger's detection method),
  based on observed record volumes.
- **[Week 14] Terrain variables in the SDM.** Elevation, slope, and TRI are all
  acquired. Decide which enter the model after a collinearity check (slope and
  TRI are correlated; both may not be needed).

---

## Change log

*(Records as-built changes to data, code, or scope during execution.)*

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
- **Population estimates, not counts.** NTCA figures are SECR estimates; point
  midpoints are used for comparability.
- **Boundary basis (see Decision 4).** No open source holds legal
  tiger-reserve (core + buffer) extents. The chosen source (NTCA DSS KML) stores
  core national-park / sanctuary polygons, which in general under-state reserve
  area (as-built polygon/census ratio median near 0.58). Geometry is therefore
  used for mapping and connectivity only. All area and density metrics use the
  official NTCA census total area, not the polygon geometry. Coverage is 55 of
  58 reserves; each reserve is built from its constituent PA(s) via a hand-
  reviewed crosswalk and dissolved to one polygon (10 reserves are multi-part).
  The 3 reserves with no KML polygon (Amrabad, Pilibhit, Dholpur-Karauli) are
  kept as geometry-absent rows.
- **One reserve polygon over-extends its census area.**
  Nagarjunsagar-Srisailam (`unit_id` 1) has a KML polygon of ~5,074 km² against
  a census total of 3,296 km² (`poly_census_ratio` 1.54). The geometry is valid
  (single ring, no self-intersection). The cause is coarse source geometry: the
  KML stores a single-ring envelope of a fragmented hill sanctuary, and the
  sanctuary itself (~3,568 km²) is larger than the notified tiger-reserve total.
  It is **not** an overlap with the adjacent Amrabad gap reserve (Amrabad's
  centre falls outside the polygon). No metric is affected — area and density
  are census-sourced — so the polygon is kept as-is for mapping. Flag for the
  connectivity track: this reserve's mapped footprint is over-large.
- **Resistance parameters are judgement calls.** Documented and justified, not
  ground-truthed against telemetry (which is not public).
