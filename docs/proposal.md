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
  density); regional roll-up; animated choropleth across the census years with a
  per-reserve table (2014/2018/2022 — see §8 and Decision 6; 2006/2010 have no
  per-reserve table).
- **Connectivity:** land-cover + road resistance surface (as built: land cover
  × human pressure, plus roads — see §8 and Decisions 14–16); least-cost paths
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

- **Boundary source (§3 fork resolved).** §3 posed the boundary source as a
  Week-2 fork: authoritative WII/NTCA layer if available, KBA fallback if not.
  Neither was chosen. The WII all-reserve layer is not publicly downloadable and
  WDPA holds no Indian national PAs, so **Decision 4** selected the NTCA DSS
  KML — used for geometry only, with area and density from the NTCA census. The
  KML holds protected-area polygons, not reserve entities, so the reserve layer
  is built from a hand-reviewed reserve→constituent-PA crosswalk rather than a
  direct name match. See `docs/methodology.md` (Decision 4 + Week-3 change log).
- **Census series is 2014/2018/2022, not five rounds (§2 Q1, §5 growth).** Q1
  asks about change "between 2006 and 2022". Week-4 extraction found that
  **per-reserve figures are tabulated only from 2014** — the 2006 and 2010
  rounds report at state × landscape-complex scale, with only partial,
  prose-level, different-unit reserve figures (**Decision 6**). The all-reserve
  growth series therefore runs **2014 → 2018 → 2022**, and the animated
  choropleth has **3 frames, not 5**. The country-level 2006→2022 trajectory
  (1,411 → 3,682) is retained as framing narrative only. 2006/2010 reserve prose
  figures are kept as secondary context (`census_reserve_long_2006_2010.csv`) for
  the 7-reserve Phase-1 comparison, not the all-reserve series. Missing
  (reserve, round) cells are `NA` with no imputation (**Decision 7**). See
  `docs/methodology.md` (Decisions 6 + 7).
- **Resistance surface adds human pressure (§5 connectivity).** §5 states a
  "land-cover + road resistance surface". The Week-9 literature review found
  that the shared signal in the tiger movement and genetics studies is human
  settlement and pressure, not cropland as such. Land cover and roads alone
  cannot separate a busy village belt from remote farmland. The as-built
  surface is therefore land cover × human pressure, plus roads:
  - **Decision 14:** the land-cover class value is multiplied by
    (1 + 4 × gHM) and capped at 100. Water in the Sundarban region takes a
    lower value (10, against 50 elsewhere).
  - **Decision 16:** water is exempt from the gHM multiplier (gHM has no data
    over water).
  - **Decision 15:** major roads (motorway–secondary) are a barrier at value
    30, by the maximum rule.

  The land-cover + roads form stays in the analysis as the `noghm`
  sensitivity variant (k = 0, with the Decision-14 class values). Week 10
  compares it with the baseline. Two further variants (`road15`, `road50`)
  test the road value. See `docs/methodology.md` (Decisions 14–16).
- **Habitat suitability at a coarser grain, not at 1 km (§2 Q3, §5 habitat
  suitability).** §5 names a `maxnet` SDM with a national prediction; the
  plan was a model at 1 km. After the cleaning rule (**Decision 21**), the
  tiger records with a position good to 1 km are 45 records in 17 cells,
  below the minimum of 25 cells, so there is **no 1 km model**. **Decision
  23** (2026-10-25) chose a model at a coarser grain:
  - the grain is the cell of the iNaturalist obscuring grid, 0.2° × 0.2°
    (396–488 km² in India);
  - the presences are the obscured iNaturalist tiger records (104 cells
    before the model-cell rule);
  - the background is the clean iNaturalist mammal records on the same
    grid.

  A model is fitted only if the Week-14 count (task 14.4) gives 25 or more
  presence cells and a background of 10 times the presence cells or more.
  If not, Stage 3 gives the effort result (Q4), and Q3 gets no model
  answer. A national prediction, if there is one, is at 0.2°, not at 1 km.
  For the effort thread (§5), Gi* is built for the effort and — for a
  comparison with Phase 1 — for the tiger records; the tiger Gi* is not
  published. See `docs/methodology.md` (Decisions 21 and 23). *(2026-10-25,
  the count of task 14.4: 104 presence cells and 1,486 background cells on
  6,969 model cells of 0.2°, so a model is fitted — the outcome is
  `planned_model`. Decision 24 fixes its settings.)* *(2026-11-01, Week 15:
  the national prediction is at 0.2° over the 6,969 model cells — relative
  suitability (cloglog with clamping) in five classes of equal count, not
  a probability of presence (Decision 25). The validation against reserves
  (§5) is the reserve check of Decision 24 point 9: r1, against the 2022
  census density, "agrees"; r2 is not published (Decision 25 point 9).
  The published form is static figures and tables; a layer that a reader
  can zoom waits for the Week-18 rule. Not a new deviation.)*
  *(2026-11-07, Week 16: the figures are built — `fig_04` (the classes),
  `fig_05` (the value) and `fig_06` (the effort Gi\* of iNaturalist).
  Decision 26 (x1) makes no comparison with Phase 1: the four Gi\* compare
  each tiger set with the effort of its observer group, and the tiger Gi\*
  are not published. The model cells are 404–489 km² (the text above says
  396–488 km², the chat's arithmetic for India). The Week-18 rule is now
  in Week 19. Not a new deviation.)*
- **SDM-based resistance and a circuit-theory check (§5 connectivity and
  habitat suitability; added 2026-11-07).** §5 names a land-cover + road
  resistance surface and least-cost paths for connectivity, and a national
  prediction for suitability. It does not name a resistance surface from
  the suitability. The item was raised with Decision 14 (2026-09-26) and
  stayed pending. At the Week-16 close the author chose to work on it in
  Week 17 (choice R4 of task 16.6): a resistance surface from the
  suitability at 0.2° and a circuit-theory check against the Stage-2
  paths. **Decision 27** fixes the settings before any surface. The story
  site (deliverable 1) moves one week later (Weeks 18–21).
