# Project Proposal

**Title:** India's Tiger Network — Growth, Connectivity and Habitat Suitability
Across India's Tiger Reserves

**Author:** Kiran Balasubramanian
**Date:** September 6, 2026
**Project type:** Reproducible R analysis with a published story site

---

## 1. Introduction and statement of problem

Two earlier projects each told half of a story. The tiger Phase 1 project
measured **population growth** in seven reserves from 2006 to 2022 with ArcGIS.
Its planned Phase 2 was to measure **connectivity** between those same seven
reserves, but it did not run. A separate Bay Area project built a full
**connectivity and occupancy** analysis in R for two wild cats.

This project joins those halves. It measures tiger growth, connectivity, and
habitat suitability across **all of India's tiger reserves**, not seven. It uses
**R**, not ArcGIS. It reuses the R toolchain, the documentation discipline, and
the sensitive-data policy from the Bay Area project.

The analysis unit is the **reserve**. Results roll up to **landscape complex**
and **state** for the narrative.

## 2. Research questions

The questions follow the agreed priority order.

1. **[Growth — priority 1]** How did tiger populations change across all reserves
   between 2006 and 2022? Which reserves, landscape complexes, and states carried
   the recovery?
2. **[Connectivity — priority 2]** Where are the likely movement corridors
   between reserves? Which reserves are connectivity linchpins, and which are
   isolated? Where do corridors cross major roads?
3. **[Habitat suitability — priority 3]** Where is habitat suitable for tigers
   across India, and does modelled suitability agree with where reserves are?
4. **[Effort — cross-cutting]** How much of the apparent spatial pattern shows
   true distribution, and how much shows observer effort? This thread runs
   through all three tracks, as it did in both earlier projects.

### Why habitat suitability, not occupancy

Occupancy models need a detection history —
repeat visits to fixed sites with detection or non-detection. Opportunistic GBIF
tiger records cannot give one. Phase 1 kept only about 116 clean baseline points
and found strong observer bias. This project therefore models **habitat
suitability (SDM)**, which the data can support, and does not claim occupancy.
This decision is fixed before any modelling (see `docs/methodology.md`).

## 3. Study area

All of India. The set of analysis units is all tiger reserves that have
reserve-level census data. The reserve boundary source is decided in Week 2
(authoritative WII/NTCA layer if available; KBA fallback if not).

## 4. Data

Summarised in `docs/data-sources.md`. The project uses public open data only.
Most datasets exist from the earlier projects; `scripts/00b_audit_data.R` checks
what is still on disk before any re-download.

## 5. Methods

Summarised in `docs/methodology.md` §5.

- **Growth:** per-reserve census metrics (absolute change, % growth, AAGR,
  density); regional roll-up; animated choropleth across five census years.
- **Connectivity:** land-cover + road resistance surface; least-cost paths
  between reserve pairs; reserve network as a graph (`igraph`) for linchpin and
  isolation metrics; road pinch points.
- **Habitat suitability:** `maxnet` SDM with a target-group background for
  sampling-bias correction; national prediction; validation against reserves.
- **Effort:** target-group background and KDE/Gi* to separate detection effort
  from distribution.

## 6. Deliverables

1. Published Quarto story site (GitHub Pages)
2. Reproducible R pipeline with pinned dependencies (`renv`)
3. Full documentation set matching sister-project conventions
4. Processed, analysis-ready spatial layers with a data dictionary

## 7. Success criteria

- [ ] Analysis fully reproducible from a clean clone
- [ ] All three tracks completed at a level the data supports
- [ ] Growth covers all reserves with reserve-level data, not seven
- [ ] Every published map states its effort/detection-bias caveat
- [ ] No precise sensitive location data published
- [ ] All sources cited with licences honoured

## 8. Deviations from proposal

*Maintained during execution, as in the earlier projects. Each entry records
where the as-built work diverged from a stated choice here. Elaborations left
open are documented as numbered Decisions in `docs/methodology.md`, not here.*

*(none yet — project is at scaffolding stage)*
