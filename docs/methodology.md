# Methodology

**Project:** India's Tiger Network
**Author:** Kiran Balasubramanian
**Status:** Scaffolding. No analysis has run.

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

Target-group background (all georeferenced vertebrate occurrences) as the effort
proxy. KDE and Getis-Ord Gi* reproduce and generalise the Phase 1 observer-bias
finding (the Ranthambore cold spot) at national scale.

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
- Corridor centrelines in the source KML are largely unnamed; names are assigned
  during the connectivity track (as in Phase 2).

**Verification artefacts:** `scripts/00c_verify_wdpa_boundaries.R` (WDPA check),
`outputs/tables/tbl_00_kba_tr_match.csv` (KBA match), and the NTCA-KML match run.

---

### Decisions pending (raised, not yet made)

These forks are open. Each is decided in the week noted in the project plan,
before the relevant code is written.

- **[Week 4] Missing-year census handling.** How to treat reserves that lack a
  figure in one or more rounds (the Kaziranga-2006 problem, at scale).
- **[Week 9] Land-cover resistance values.** The `WORLDCOVER_RESISTANCE` lookup
  in `R/00_config.R` holds literature-informed starting values; the final set is
  a numbered Decision before the resistance surface is built.

---

## Change log

*(Records as-built changes to data, code, or scope during execution.)*

*(none yet)*

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
  the core national park or sanctuary polygon, which under-states reserve area
  (median 55 % below the legal total). Geometry is therefore used for mapping
  and connectivity only. All area and density metrics use the official NTCA
  census total area, not the polygon geometry. Coverage is 55 of 58 reserves;
  the gaps and false matches are resolved by hand during the Week-3 build.
- **Resistance parameters are judgement calls.** Documented and justified, not
  ground-truthed against telemetry (which is not public).
