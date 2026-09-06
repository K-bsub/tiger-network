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

---

### Decisions pending (raised, not yet made)

These forks are open. Each is decided in the week noted in the project plan,
before the relevant code is written.

- **[Week 2] Reserve boundary source.** Authoritative WII/NTCA all-reserve TR
  boundaries vs KBA fallback. KBA mismatched legal TR area in Phase 1 (Corbett
  density inflated).
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
- **Boundary version mismatch.** Different sources digitise reserve boundaries
  differently; the chosen source is documented and used consistently.
- **Resistance parameters are judgement calls.** Documented and justified, not
  ground-truthed against telemetry (which is not public).
