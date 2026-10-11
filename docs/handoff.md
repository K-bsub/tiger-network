# Handoff — India's Tiger Network

**What this is:** the single rolling context document for this project. One chat
per week. At the **start** of a week's chat, paste or attach this file so the
assistant has full context. At the **end**, update the "Current state" and "Log"
sections and commit. This file is the memory between chats — keep it truthful.

**How to update:** edit "Current state" to match reality, add a dated entry to
the "Log", tick the week off in `project-plan.md`, then commit both together
(`docs: update handoff after Week N`).

---

## Fixed context (rarely changes)

- **Repo:** https://github.com/K-bsub/tiger-network  ·  local:
  `C:/Users/kiran/OneDrive/Documents/GitHub/tiger-network`
- **Site:** https://K-bsub.github.io/tiger-network/
- **Environment:** R 4.5.2, RStudio on Windows; `renv` for reproducibility.
  Quarto is **not** on the Windows PATH — render from R with
  `quarto::quarto_render("site", as_job = FALSE)`.
- **Analysis CRS:** EPSG:7755 (WGS 84 / India NSF LCC).
- **Scope (locked):** three tracks in priority order — (1) Growth, (2)
  Connectivity, (3) Habitat suitability (SDM, **not** occupancy) — plus the
  cross-cutting effort/observer-bias thread. Reserve-level, rolled up to
  landscape complex and state.
- **Fixed Decisions (see `docs/methodology.md`):** D1 suitability not occupancy;
  D2 reserve unit rolled up; D3 CRS 7755; D4 NTCA KML geometry, census area;
  D5 Mammalia target group; **D6 census series = within-reserve SECR 2014/2018/2022
  only (2006/2010 are context, not a baseline)**; **D7 missing (reserve, round)
  cells = `NA`, no imputation**; **D8 reserve area = NTCA-notified core+buffer
  total (ISFR-2021 Ch.4 is cross-check only, not the area source)**; **D9 real
  within-reserve zeros — `change_abs` always valid, ratio metrics `NA`+flag only
  when the baseline is 0, a real 2022 zero is −100 not `NA`**; **D10 covariate
  stack common NA mask (any band `NA` → all bands `NA`) — closed Week 9**; **D11
  gHM gap-fill relevance rule + fill method**; **D12 gHM closed; land cover from
  the unmasked tile cache** (post-result); **D13 terrain from the raw DEM; 7
  tile-corner no-class cells accepted** (post-result); **D14 resistance: set-B
  class values × (1 + 4 × gHM), cap 100, Sundarban water 10 (50 elsewhere),
  variant `noghm`**; **D15 road barrier motorway–secondary, value 30, maximum
  rule, `touches = TRUE`, variants `road15`/`road50`**; **D16 water exempt from
  the gHM multiplier** (post-result); **D17 least-cost-path set-up: pairs by
  Euclidean-allocation adjacency + gap ≤ 315 km; P3 through-reserve rule; 16
  neighbours, crossed-cells knight rule; own engine, validated; no crop; edge
  to edge, contiguous = shared footprint cell (amended); Amrabad split (D1a);
  Pilibhit, Dholpur-Karauli out (G1); `network_group` labels; NTCA overlap
  descriptive**; **D18 variant comparison: symmetric 5 km route overlap < 0.5
  or percentile-rank change ≥ 0.25 = material; "robust" if ≤ 20 % material and
  ρ ≥ 0.9; road value robust only if both road variants are**; **D19 reserve
  network: each in-network pair is a link, cost = weight, no cost threshold;
  contiguous reserves merge (56 reserves → 47 nodes), lowest-cost pair = the
  edge; betweenness normalised by the node's own set; `linchpin` = top 3 in
  the set and value > 0, `cut_node` next to it; `isolated` = degree 0,
  `pendant` = degree 1, cheapest-link cost graded; descriptive threshold
  scan; second baseline run without cross-group links; variants "robust" if
  the sets are the same, ρ ≥ 0.9 and linchpin retention ≥ 2/3** (the path
  costs were seen before D19; no rule uses a cost value); **D20 road pinch
  points: roads = the D15 barrier cells; paths = all in-network paths, the
  rule counts `edge` links only; crossing = one unbroken run of barrier-road
  cells in the cell list of a path (vertices + knight middle cells; reserve
  cells count and are flagged); crossings ≤ 5 km apart = one site;
  `pinch_point` = a site on a bridge edge (`on_bridge`) or a site that ≥ 2
  edges use (`shared`); tier 1 both / 2 bridge only / 3 shared only, no order
  in a tier, road class not in the rule; four `lit_flag` links flagged, not
  dropped; variants "robust" if site overlap at 5 km ≥ 2/3; published
  position = 10 km grid cell + state + district; not the pinch point of
  circuit-theory mapping** (the network results were seen before D20; no
  road crossing was).

## Ways of working (apply every chat)

- ASD-STE100 Simplified Technical English in all writing.
- No flattery; realistic assessment; surface discrepancies, never silently
  default.
- Decisions before code: raise open forks; Kiran makes the call.
- Deliver **full files**, not snippets. Present only changed files per turn.
- Work at the **file level** (Kiran applies edits and re-uploads corrected
  files; those are the source of truth).
- Pre-registration discipline: fix analytical rules as numbered Decisions
  before looking at results.
- Sensitive-data policy: no precise points published; continuous surfaces
  generalised to ≥1 km; gate publish exports through the assert functions.
  Since Week 12: a modelled path or road crossing is given as a 10 km grid
  cell in every committed table, figure and caption
  (`assert_publishable_table()`); 1 km cells stay in gitignored layers.
- The run on the project machine is the record. Kiran runs the script and
  sends the console text; the docs for a task are written only after that
  run confirms the result.
- The narrative is the author's. A chat does not write story text; a title
  or a caption from a chat is a draft and is marked as one.
- Before each deliverable, check the new text against the AI-word list.
- Take each figure from code or data, never from prose.

---

## Current state  ·  updated after **Week 12** (Stage 2 complete: road pinch points) · 2026-10-10; Week-13 plan added 2026-10-10

- **Week 12 complete, committed and pushed** (tasks 12.1–12.11, 2026-10-10).
  **Stage 2 (Connectivity) is complete.** **Decision 20** (road
  pinch points) was recorded before any road crossing was computed. The
  network results were seen before it; the Decision says so.
- **Pinch-point code:** `R/00_functions_pinch.R` (new, 33 functions),
  `assert_publishable_table()` in `R/00_functions_sensitive.R`, 21 `PINCH_*`
  settings, STEPs 12.1–12.7 at the end of `scripts/07`. Third run switch:
  `RUN_ROAD_CELLS <- FALSE` (STEP 12.1 reads
  `data/interim/cov_roadbarrier_class_1km_7755.tif`; `TRUE` builds it again
  from the OSM road layer, 35 s). STEP 12.7 loads `ggplot2`.
- **Roads (STEP 12.1):** 444,234 barrier features of 885,669; **535,592**
  barrier-road cells, the count of the Week-9 surfaces (motorway 9,240;
  trunk 155,723; primary 168,278; secondary 202,351). The road layer has no
  road name: fields `osm_id` and `highway` only.
- **Crossings (baseline, `tbl_14_road_crossings.csv`):** 76 in-network paths
  (73 `edge`, 3 `parallel`); **556 crossings on 74 paths**, 765 road cells;
  122 crossings on the 13 bridges; 49 on the four `lit_flag` links
  (Orang–Dampa, Anamalai–Srivilliputhur-Megamalai,
  Periyar–Kalakad-Mundanthurai, Sariska–Rajaji — all four are bridges).
  Sariska–Rajaji has 35 crossings, 7 of them in Delhi. Two paths have no
  crossing (Guru Ghasidas-Tamor Pingla – Sanjay Dubri; Pench – Pench (MH)).
- **Sites and pinch points (`tbl_14_pinch_points.csv`):** **365 sites; 200
  pinch points — tier 1: 3, tier 2: 98, tier 3: 99**; `on_bridge` 101,
  `shared` 102. Tier 1: two sites in Sonitpur, Assam (Manas–Orang,
  Nameri–Orang, Orang–Dampa) and one in Chikmagalur, Karnataka (Bhadra–Kali,
  Bhadra–Nagarhole).
- **Pinch-point variants (Decision 20 point 6):** gHM multiplier
  **sensitive** (`noghm` site overlap 0.520, limit 2/3); road value
  **robust** (`road15` 0.866, `road50` 0.820). 98 of the 200 baseline pinch
  points have a variant pinch point within 5 km on all three variants; 3 on
  none. Decision 20 named "robust" as the more likely result; that was
  wrong, and the Decision text is not changed.
- **Stage-2 labels together:** paths (D18) robust / robust; network (D19)
  robust / robust; pinch points (D20) **sensitive** / robust. A text that
  names a pinch point must give the third.
- **Pinch-point QA:** 74 of 74 (`tbl_14_pinch_qa.csv`). The figure has its
  own 10 checks in STEP 12.7.
- **Publishable outputs (positions at a 10 km cell only):**
  `tbl_03_reserve_network.csv` (56 rows, values per node; 42 nodes have a
  pinch point on an edge, 7 a tier-1 one), `tbl_03b_pinch_points.csv` (all
  200 pinch points, by tier), `tbl_03_notes.md` (what a pinch point is
  here), `fig_03_reserve_network.png` (11 × 10.6 in; all three tiers, tier 3
  small and pale; linchpins numbered 1–8). **The title, subtitle and caption
  of `fig_03` are draft text of the chat; the author keeps the draft for
  now.**
- **Assessment to carry into the write-up:** the pinch-point label
  separates little — 54.8 % of the sites; the 13 bridges give 101, and
  Sariska–Rajaji alone gives 21. It is a position in the network, not a
  measure of the effect of a road, and not the pinch point of
  circuit-theory mapping. Tier 1 is the only short list.
- **Literature check of the pinch points (descriptive; `references.md`,
  "Week-12 pinch points"):** by link and district, because the road layer
  has no names. Of 21 groups: 10 with a source for a road conflict in the
  same district or reserve, 5 with a source for the link or context only, 6
  with none. No source confirms a tier-1 pinch point. Two limits found: a
  road inside a node has no crossing (NH 766, Bandipur); a documented
  crossing place can be a crossing that is not a pinch point (NH-44, Pench,
  Nagpur district). The sources are news reports.
- **Stage-2 summary against proposal question 2:** `methodology.md`, change
  log, "2026-10-10 — Week 12 complete". Ten new Limitations at the end of
  that file. `proposal.md` §8 has no new entry.
- **Weeks 10–11 state (unchanged, kept for reference):**
- **Week 11 complete, committed and pushed** (tasks 11.1–11.8).
  **Decision 19** (reserve network) was recorded on 2026-10-03,
  before any network metric. The path costs were seen before it (Week 10);
  the Decision says so and no rule uses a cost value.
- **Network code:** `R/00_functions_network.R` (new) and STEPs 11.1–11.4 at
  the end of `scripts/07`. They read the path layers from
  `lcp_reserve_network_7755.gpkg`; `pairs` and `res_net` come from STEP 10.1.
  No new switch. The graph is not written; it is rebuilt on each run.
- **Network (baseline):** 85 in-network pairs → 9 `block`, 0 `within_block`,
  73 `edge`, 3 `parallel`. **47 nodes** from 56 reserves (7 blocks: Bandipur +
  Nagarhole + Mudumalai + Sathyamangalam; Nagarjunsagar-Srisailam + Amrabad;
  Namdapha + Kamlang; Pakke + Nameri; Manas + Buxa; Periyar +
  Srivilliputhur-Megamalai; Parambikulam + Anamalai). 3 sets: 33 nodes
  (`central` + `north`), 8 (`western_ghats`), 6 (`northeast`). 13 bridges.
- **Metrics (`tbl_13_network_metrics.csv`, 56 rows, values per node):**
  8 linchpin nodes — set 1: Madhav, Guru Ghasidas-Tamor Pingla, Sanjay Dubri;
  set 2: the Bandipur block, Bhadra, Parambikulam + Anamalai; set 3: Pakke +
  Nameri, Orang. 12 cut nodes. No isolated node. 6 pendant nodes (Valmiki,
  Sundarbans, Dampa, Sahyadri, Kalakad-Mundanthurai, BRT).
- **Flags on the linchpins:** Madhav is `cross_group_dependent` (rank 1 with
  the Sariska–Rajaji link, rank 5 without it; Kanha then becomes a linchpin).
  Sanjay Dubri is not stable (Pench (MH) takes its place on `noghm` and
  `road50`). 7 stable linchpins. Sariska has `betweenness_norm` 0.2258, all
  of it from the north–central pairs.
- **Network variants (Decision 19 point 10):** gHM multiplier **robust** (`noghm`
  ρ 0.941, 7 of 8 linchpins retained); road value **robust** (`road15` ρ
  0.979, 8 of 8; `road50` ρ 0.995, 7 of 8). The sets are the same on all.
- **Network QA:** 91 of 91 (`tbl_13_network_qa.csv`); the self-test on the
  hand-computed graph (17 cases) runs at the start of STEP 11.2.
- **Literature check (descriptive; `references.md`, "Week-11 network"):**
  agrees for Guru Ghasidas-Tamor Pingla, Kanha/Pench, the Bandipur block,
  Bhadra, Sundarbans, Dampa, Sahyadri. No source found for a high Madhav
  centrality, for Orang–Dampa, or for a northern link of
  Nagarjunsagar-Srisailam + Amrabad. Sources describe no Anamalai–Periyar
  connection along Kerala and a barrier at the Shencottah gap.
- **Two data items kept as limitations (author choice g1):** Guru
  Ghasidas-Tamor Pingla and Sanjay Dubri are 1.59 km apart in the KML (two
  nodes, both linchpins) although sources call them contiguous; BRT is
  10.1 km from Sathyamangalam (a separate pendant node) although sources name
  it in the Bandipur block. Decision 17 was not changed.
- **Engine** `R/00_functions_lcp.R`: our own 16-neighbour cell graph (`terra`
  + `igraph`), crossed-cells knight rule, edge-to-edge Dijkstra from all cells
  of the source reserve. No least-cost-path package in the pipeline;
  `gdistance` + `raster` are for validation only.
- **`scripts/07` switches:** `RUN_RESISTANCE <- FALSE` (the Week-9 STEPs are
  skipped; a guard checks the four surfaces against
  `tbl_11_resistance_qa.csv`); `RUN_LCP_SMOKE <- FALSE`; `RUN_ROAD_CELLS <-
  FALSE` (Week 12). The STEPs of Weeks 10 to 12 run each time the script is
  sourced. Through Week 11 the reported STEP times add up to about 3.5
  minutes; with the unreported parts, a full run was about 4–5 minutes
  (estimate). The Week-12 STEPs were not timed on the project machine (about
  15 s in the drafting workspace).
- **Reserve layer:** 56 with geometry — Amrabad from the state split of the
  Nagarjunsagar-Srisailam polygon (`scripts/02` STEP 4b; D1a). Pilibhit and
  Dholpur-Karauli have no geometry and are not in the network (G1).
- **Pairs** (`tbl_12_reserve_pairs.csv`): 106 (132 candidates; 26 above
  315 km); 3 connected sets (34, 13, 9 reserves); 9 contiguous; 2 cross-group
  (Sariska–Corbett, Sariska–Rajaji).
- **Baseline paths:** 97 paths + 9 contiguous, 0 with no path. Cost median
  577.3 resistance-km; length/gap median 1.34 (range 0.63–4.18; highest
  Bandhavgarh–Panna). 21 pairs are not in the network (P3). Validation 15 of
  15 (largest difference 1.5e-15); QA 424 of 424 on all four surfaces.
- **Path variants (Decision 18):** gHM multiplier **robust** (`noghm` 18 of 97
  material — 1 pair inside the limit; ρ 0.985); road value **robust**
  (`road15` 11, `road50` 9 material). No material rank change in any variant.
- **Week-10 literature check (paths):** the highest costs agree with the genetic and Terai
  literature; the Bandhavgarh–Panna and Brahmaputra (Nameri/Orang–Kaziranga)
  detours do not match documented corridors → limitation L1 (no Decision
  change).
- **NTCA overlap** (descriptive, no buffer): share inside corridors median
  0.064; 31 of 59 corridors crossed.
- **Week-13 entry point** (`project-plan.md` → "Week 13 — task breakdown",
  tasks 13.1–13.10, written 2026-10-10). First task 13.1, the
  **occurrence-cleaning Decision 21** (pending item in `methodology.md`),
  before any cleaned count is seen: the uncertainty limit, the year window,
  the record types to remove, obscured records, thinning, records with no
  covariate value, the same rule for the background, and a minimum number of
  clean presence cells. Then a new script `scripts/08_<verb_object>.R`
  (named in task 13.2): the clean tiger layer, the clean background, the
  attrition table and the taxa tally (`tbl_15_*`). Then **Decision 22**
  (effort surfaces; it closes the pending settlement item), the density
  surfaces, QA and docs. The estimates add up to 4.6–6.3 hours; a split
  point is after task 13.4. Inputs on disk (gitignored):
  `data/interim/occ_tiger_gbif_raw_7755.gpkg` (4,606 records; median
  coordinate uncertainty about 30 km; years 1840–2026),
  `data/interim/effort_background_tgs_7755.gpkg` (39,057 Mammalia records,
  2006–2022), `osm_settlements_7755.gpkg` (199,800, village-dominated;
  folder not verified), `data/processed/cov_stack_1km_7755.tif`.
- **Read before Week 13:** (1) the occurrence-cleaning rules (uncertainty
  limit, dates, duplicates, records in water or outside India) are
  analytical rules — fix them as a numbered Decision (the next number is
  21) before the cleaned counts are seen; the raw count and the median
  uncertainty are already seen, so say so; (2) two pending Decisions are
  due: the settlement layer for the KDE (Week 13) and the target-group scope
  (Weeks 13–14); (3) a precise tiger record is sensitive (policy tier T2):
  no cleaned point layer, table or figure with point positions goes into a
  committed folder — read `sensitive-data-policy.md` first; (4) expect a
  heavy drop at cleaning (Phase 1 kept about 116 clean baseline points);
  the effort thread is a first-class part of Stage 3 — the plan asks for a
  minimum clean count to be fixed before the count is seen; (5) Stage 3 does not
  read a Stage-2 output, but the terrain bands of the stack hold probable
  sea-floor depths (decide in Week 14); (6) `data-dictionary.md` has a
  placeholder entry for `occ_tiger_gbif_clean_7755.gpkg`; (7) the PROJ
  `proj.db` note still applies — fresh session; (8) the figure number for
  Stage 3: `fig_04` is free, and the Week-16 plan row names `fig_05`; (9)
  the config has `KDE_RADIUS_M` 20 km and the pending settlement item said
  15 km — Decision 22 fixes it; (10) Getis-Ord Gi* is named in
  `methodology.md` §5.5 and is in no week of Stage 3 — Decision 22 point (f);
  (11) a density surface of few tiger records can show a record position —
  the ≥ 1 km rule does not prevent it; (12) the console text for a chat
  holds counts, never a record coordinate, and a data upload to a chat is a
  choice to make in task 13.2.
- **Open items:** `scripts/03` line 101 — wrap
  the literal text in `I()` for `readr` ≥ 2.2 (no output change; not done).
  The NTCA overlap has no buffer (Decision 17). Transboundary links are
  absent (India-only surface). The `README.md` Stack row now names the
  engine (closed 2026-10-10). **From Week 12:** the title, subtitle and
  caption of `fig_03` and the wording of `tbl_03_notes.md` are from the chat
  — the author's edit is open; the thin link lines of `fig_03` are faint at
  line width 0.3 (kept by author choice); the sentence "Bobcat-style finer
  publication…" in `sensitive-data-policy.md` was not reviewed against the
  new rule for modelled paths and crossings; `fig_04` is free while the
  Week-16 plan row names `fig_05`. The AI-word list is an image-only PDF; in
  Week 12 the check used the list of the source web page (humanizeai.io, 50
  words and 21 phrases) as a search pattern — a text file in the repo would
  make the check exact.
- **References still to verify** (entries marked in `references.md`): Sarkar
  et al. 2016, Jhala et al. 2021, Habib et al. 2020, Hussain et al. 2022,
  WHCWG 2010, McRae & Kavanagh 2011, Jan et al. 1999, Savary et al. 2022,
  Sharma et al. 2009 and 2011, Johnsingh et al. 2004, the transboundary TAL
  report, Sarkar et al. 2021, the 2026 bioRxiv preprint. **New in Week 11:**
  Brandes 2001, Brooks 2003, Carroll et al. 2012, Freeman 1977 (volume and
  pages); Jhala et al. 2015 (report number); Johnsingh et al. 2009 (authors,
  proceedings); Singh et al. 2015 (authors, article number); the two
  Qureshi et al. 2014 chapters (read in fragments); which Pench unit Dutta et
  al. 2016 mean. **New in Week 12:** Carter et al. 2020, Cushman et al. 2013,
  McRae 2012, Pariwakam et al. 2018, WHCWG 2013 (all from abstracts or
  extracts); Saxena & Habib 2022 (read through a news report); the 21 news
  and grey sources of "Week-12 pinch points" — two gave a summary only, one
  is an exam-preparation page, and some have no day or no title recorded.
- **Pending, not scheduled:** SDM-based resistance (1 − suitability) and a
  circuit-theory check after Stage 3.

### Output files this week (Week 12)

- `outputs/tables/` (committed; positions at the 10 km grid only):
  `tbl_14_road_crossings.csv` (556 rows), `tbl_14_pinch_points.csv` (365
  rows, one per site), `tbl_14_pinch_link_summary.csv` (76 rows),
  `tbl_14_pinch_variant_comparison.csv` (3 rows), `tbl_14_pinch_qa.csv` (74
  rows), `tbl_03_reserve_network.csv` (56 rows), `tbl_03b_pinch_points.csv`
  (200 rows), `tbl_03_notes.md` (32 lines).
- `outputs/figures/fig_03_reserve_network.png` (2200 × 2120 pixels).
- `data/interim/cov_roadbarrier_class_1km_7755.tif` — class rank of the
  barrier-road cells. Gitignored.
- `data/processed/lcp_road_crossings_7755.gpkg` — layers `baseline` (765
  points), `noghm` (608), `road15` (856), `road50` (687). **1 km positions:
  gitignored, never published.**
- Code: `R/00_functions_pinch.R` (new), `R/00_functions_sensitive.R`
  (`assert_publishable_table()`), `R/00_config.R` (`PINCH_*`), `scripts/07`
  (header, switch, STEPs 12.1–12.7). No new package. No other data layer
  changed; the tables of Weeks 10 and 11 are written again with the same
  content.
- Docs: `methodology.md` (Decision 20, status, §5.3, ten change-log
  entries, ten Limitations, pending item), `references.md` (two new
  sections), `sensitive-data-policy.md` (§3 rule for modelled paths and
  crossings), `data-dictionary.md`, `naming-conventions.md` §6,
  `project-plan.md`, `README.md`, this handoff. `proposal.md` not changed.

### Output files from Week 11 (unchanged)

- `outputs/tables/`: `tbl_13_network_links.csv` (85 rows),
  `tbl_13_network_metrics.csv` (56 rows, 32 columns),
  `tbl_13_network_threshold_scan.csv` (73 rows),
  `tbl_13_network_variant_comparison.csv` (3 rows),
  `tbl_13_network_qa.csv` (91 rows).
- Code: `R/00_functions_network.R` (new), `R/00_config.R` (`NET_*` settings;
  one comment), `scripts/07` (header, STEPs 11.1–11.4). No data layer
  changed. No new package.
- Docs: `methodology.md` (Decision 19, change log, Limitations, pending
  item, §5.3), `references.md` (two new sections), `data-dictionary.md`,
  `naming-conventions.md` §6, `project-plan.md`, `README.md`, this handoff.

### Output files from Week 10 (unchanged)

- `data/processed/lcp_reserve_network_7755.gpkg` — layers `baseline`,
  `noghm`, `road15`, `road50` (106 lines each). Gitignored.
- `data/processed/boundary_reserves_all_7755.gpkg` and
  `stats_reserve_census_7755.gpkg` — rebuilt with the Amrabad split (only units
  1 and 51 changed). Gitignored.
- `data/interim/lcp_pair_zones_1km_7755.tif` — allocation zones (QA only).
  Gitignored.
- `outputs/tables/`: `tbl_12_reserve_pairs.csv`, `tbl_12_lcp_validation.csv`,
  `tbl_12_lcp_qa.csv`, `tbl_12_lcp_variant_comparison.csv`,
  `tbl_12_lcp_variant_summary.csv`, `tbl_12_lcp_ntca_overlap.csv`,
  `tbl_12_lcp_ntca_corridors.csv`; Stage-1 tables rewritten by the split
  re-run (`tbl_02_reserve_build_report`, `tbl_07`, `tbl_08` changed on units 1
  and 51 only; the rest identical). `outputs/figures/fig_02_growth_animation.gif`
  re-rendered (Amrabad drawn).
- Code: `R/00_config.R` (Decision 17/18 settings, `BOUNDARY_STATE_SPLITS`),
  `R/00_functions_lcp.R` (new), `scripts/00a` (package list), `scripts/02`
  (STEP 4b, guard G-a), `scripts/03` and `05` (comments only), `scripts/07`
  (switches, STEPs 10.0–10.5). `renv.lock` updated.

### Data on disk (from Week 2, via `scripts/01` — unchanged)

All on the 1 km EPSG:7755 grid where raster.
- **GBIF tiger occ** — 4,606 pts (DOI 10.15468/dl.npxmxx). Median coord
  uncertainty ~30 km — heavy cleaning drop expected in Week 13.
- **GBIF Mammalia background** — 39,057 pts, 2006–2022 (DOI 10.15468/dl.2d523e).
- **WorldCover 2021** — 1 km modal class (all 11 classes present).
- **gHM 2022** — 1 km, mean 0.377.
- **OSM** — roads 885,669 (major, tertiary-dominated); settlements 199,800
  (**village-dominated ~195k** — likely needs trimming for the KDE).
- **Terrain** — elevation/slope/TRI, 1 km (elevatr AWS z7). Full-India coverage.
- **Admin boundaries** — Natural Earth states (36) + DataMeet Census-2011
  districts (641). Districts are pre-redistricting vintage.
- **Manual PDFs:** ISFR 2021 Ch.4 (parsed for the Week-5 area cross-check),
  Singh & Sen 2015, and the five NTCA census reports (2006–2022, parsed Week 4).

### Boundary Decision (Decision 4 — settled Week 2, as-built Week 3)

- **Chosen:** NTCA DSS `PA_TR_Corridor_Final` KML as the single geometry source.
  Reserve **area/density come from the NTCA notified total, not the KML polygon**
  (the polygon under-states the legal total; poly/census ratio median 0.515
  as built 2026-10-02 — earlier "~0.58" was not supported by the data).
- **As-built refinements (Week 3):** the "2 false matches" (Bor, Kamlang) were
  name-lookup artefacts — both have correct in-state polygons and are matched.
  Real gaps were 3 reserves without a KML polygon. Since 2026-10-02, Amrabad
  gets its geometry from the state split (Decision 17, D1a); Pilibhit and
  Dholpur-Karauli stay geometry-absent. Corridors are **named polygons**, not
  unnamed centrelines.
- **Raw:** `data/raw/ntca/PA_TR_Corridor_Final/`.

### Open pending Decisions (decide in the week noted)

Full text in `methodology.md` → "Decisions pending".
- **[Week 18] Published path layer** (raised 2026-10-10 with Decision 20) —
  the path lines are allowed in a static figure at national scale only. An
  interactive or downloadable path layer lets a reader zoom to a crossing
  that the tables give at 10 km. Decide before a path layer goes on the
  site: no layer, simplified lines, or a zoom limit.
- **[Week 13] Occurrence-cleaning rule** (raised 2026-10-10) — becomes
  Decision 21, before any cleaned count: uncertainty limit, year window,
  record types, obscured records, thinning, the same rule for the
  background, a minimum clean count.
- **[Week 8–9 → Week 13]** Settlement layer for the KDE — village-dominated
  (~195k); trim to city/town (4,597) or change radius? Closed by Decision 22
  (task 13.5), with the surfaces, the radius (config 20 km; the item said
  15 km) and the place of Gi*.
- **[Week 13–14]** Target-group scope — all Mammalia vs large-bodied guild.
- **[Week 14]** Terrain variables in the SDM — collinearity (slope vs TRI) and
  elevation on water/coastal cells (−434.2 m; probably sea-floor depth).
- **[After Stage 3]** SDM-based resistance + circuit-theory check.

_Resolved: [Week 4] missing-year handling → Decision 7; [Week 5] area source →
Decision 8; [Week 6] zero-baseline handling → Decision 9; [Week 8] covariate-stack
NA policy → Decision 10; [Week 9] gHM gap-fill relevance → Decisions 11–13
(Decision 10 closed); [Week 9] resistance values → Decision 14; [Week 9] barrier
road classes → Decision 15; [Week 9] water and gHM → Decision 16; [Week 10]
least-cost-path set-up → Decision 17; [Week 10] variant comparison metric →
Decision 18; [Week 11] functional-link rule → Decision 19; [Week 12]
pinch-point rule → Decision 20._

### Known gotchas (do not relearn)

- **NTCA KML — the GDAL driver mangles it; parse with `xml2`.** The KML
  `PA_TR_Corridor_Final.kml` (a) has its attribute fields (`DESIG`, `state_name`,
  `Corridor`) inside `SchemaData/SimpleData`, which the GDAL/LIBKML driver
  **drops** (an `st_read` shows only `Name`/`Description`/`geometry`), and (b) is
  split by the driver into **two layers** (`PA_TR_Corridors` = 764, `corridor` =
  156), so a plain `st_read` sees 764 features and no fields. `scripts/02`
  therefore parses the KML with **`xml2`** and rebuilds geometry from ring
  coordinates. Do not switch it back to `st_read`. Also: `st_as_sfc()` on a KML
  geometry snippet **returns empty geometries** for this file's
  MultiGeometry/altitudeMode structure — that path was tried and abandoned. New
  dependency: `xml2` (run `renv::snapshot()` if not already locked).
- **KML layer named `corridor` is NOT the corridors.** The GDAL `corridor` layer
  (156 features) holds the **unnamed duplicate** placemarks. The real corridors
  (59) sit inside the `PA_TR_Corridors` layer, tagged by the `Corridor` field.
- **`unit_name` is not a unique key.** Two `Pench` (MP + MH) and two
  `Rajiv Gandhi` (Karnataka + AP) exist in the KML. Any KML→reserve match must
  use **name + state**, never name alone. `scripts/02` does; keep it that way.
- **`area_km2` is the notified total from Week 5 on — in the stats layer.**
  `scripts/03` overwrote it from `tbl_05_area_source_map.csv` (Decision 8) in
  `stats_reserve_census_7755.gpkg` (`area_provisional = FALSE` there). The
  boundary layer keeps the Week-3 placeholder (`area_provisional = TRUE`). The overwrite changed zero values — the Week-3 placeholder already
  matched. Never derive area/density from `poly_km2` (the KML polygon).
- **`BASELINE_YEAR` in `R/00_config.R` is the GBIF download bound, NOT the census
  baseline.** It doubles as `scripts/01`'s YR_MIN (2006). Decision 6's census
  baseline is `CENSUS_BASELINE_YEAR` (2014). Do NOT set `BASELINE_YEAR` to 2014 —
  it would silently narrow the GBIF occurrence pull. The two were separated in
  task 5.9; keep them separate.
- **`census_reserve_long.csv` has a quoted `#` comment block before the header.**
  `read_csv(comment = "#")` does NOT strip quoted `#` lines — drop them by hand
  first (`raw[!str_detect(raw, '^\\s*"?#')]`), as `scripts/03` does. Same trap in
  pandas.
- **`density_2022` is per TOTAL notified area, not core-only.** It will not match
  an NTCA density figure that used core area (Corbett especially). Deliberate,
  per Decision 8 — consistent across all reserves.
- **First GitHub Pages publish:** the Action deploys to `gh-pages` but cannot
  create it. Bootstrap the branch once from the **Terminal tab** (not R
  console): `quarto publish gh-pages site`. Do **not** use
  `quarto::quarto_publish_site(server="gh-pages")` — that R wrapper targets
  Posit Connect and misreads `gh-pages` as a hostname.
- **`rlang` lock:** if a package update says "cannot remove prior installation"
  or "namespace already loaded, >= X required", restart R and run
  `install.packages()` as the **first** action, before anything auto-loads it.
- **`gh-pages` branch shows source as "deleted":** correct. That branch holds
  only rendered HTML; source stays on `main`.
- **`00b` reads `data/data_manifest.csv`** as the expected inventory (not
  `data-sources.md`).
- **The audit checks file *presence*, not *coverage*.** A `PRESENT` result means
  "a matching file exists in the folder", nothing more. When real data is staged
  in Week 2+, do not read a `PRESENT` on `ntca_census` as "the census is done" —
  the all-reserve census is manual extraction (Weeks 4–5) and the audit cannot
  see whether a file holds 7 reserves or all of them.
- **`00b` glob is recursive and case-insensitive.** A stray matching file in a
  nested subfolder still counts as `PRESENT`. Keep `data/raw/<subfolder>/` clean
  so a leftover file does not create a false `PRESENT`.
- **2022 census table (Table I.3.3) — the PDF text layer is CORRUPT.**
  `pdftotext` on pages 28-29 returns column-scrambled garbage (reserve names and
  numbers do not line up). The 2022 values were transcribed from a **150-DPI page
  raster** (`pdftoppm`), read visually. Do not trust a text-extraction of that
  table; re-raster if you need to re-check a value. 2014 (Table 2.2) and 2018
  (Table 3.4) text layers are clean.
- **"Within" vs "utilising" — take WITHIN.** 2018 Table 3.4 and 2022 Table I.3.3
  each give two population columns per reserve: "tigers utilising the reserve"
  (larger, double-counts tigers shared between abutting reserves) and "tigers
  within the reserve". The series uses **within**. The 2018 report says so
  explicitly. Getting this wrong inflates every 2018/2022 figure.
- **2006/2010 have NO per-reserve table.** Do not go looking for one — it does
  not exist. Those rounds report at state × landscape-complex scale (Table ES.1);
  reserve numbers are only in landscape-chapter prose, partial, and a different
  spatial unit. This is why Decision 6 starts the series at 2014.
- **Singh & Sen (2015) is not a numeric source.** Its per-reserve bars (Figs
  9-16) are **normalised indices** (0-120 axis, captioned "Source: NTCA"), not
  counts — Corbett's ~100 bar vs its real 215 proves it. Useful for trend
  direction only. Do not read values off it.
- **Two Pench = two `unit_id` (23 MP, 33 MH).** Both print as "Pench" in every
  census table; disambiguate by the state column. The extraction did; the Week-5
  join must key on `unit_id`, never `unit_name`.
- **`-` or `0` in a census table is a real within-reserve zero**, not missing —
  enter `0` (Dampa, Kamlang, Kawal, Satkosia, Sahyadri, Palamau-2018,
  Buxa-2018). Missing = the row is simply absent (reserve not estimated that
  round).
- **PROJ / PostGIS `proj.db` clash (this machine).** PostgreSQL 16 / PostGIS 3.6
  puts an old `proj.db` on PATH
  (`C:\Program Files\PostgreSQL\16\share\contrib\postgis-3.6\proj\proj.db`,
  LAYOUT.VERSION.MINOR = 2 — an ancient PROJ). GDAL/terra load that instead of
  their own, so **every reprojection to EPSG:7755 fails** with `empty srs` /
  `[project] cannot get output boundaries for the target crs`. This is NOT a code
  bug — the CRS engine is reading a corrupt database. Fix: pin `PROJ_LIB` to
  terra's bundled `proj.db` in the project `.Rprofile`, set **before** terra
  loads (after `renv/activate.R`). Verify in a fresh session with
  `crs(rast(crs="EPSG:7755"))` — it must print the "India NSF LCC" WKT. The env
  var must be set in a clean session; setting it after terra is already loaded
  does not take (PROJ caches the path at first use).
- **`gganimate` `transition_states` tweens `geom_sf` geometry.** On a fixed-
  geometry choropleth the reserves appeared to morph/drift between frames because
  gganimate interpolated the polygon vertices. Use **`transition_manual(year)`**
  for any fixed-geometry animated map — it holds each state as a discrete frame,
  no vertex tween. `ease_aes` makes the wrong version worse; drop it. Label var
  becomes `{current_frame}` (not `{closest_state}`).
- **`gifski` is a separate install from `gganimate`.** `gganimate` was in `renv`;
  `gifski` (the default GIF renderer) was not, so `fig_02` fell back to 3 static
  PNGs. Fix: `renv::install("gifski")` (CRAN Windows binary — no Rust toolchain),
  then `renv::snapshot(packages = c("gganimate","gifski"))`. A bare
  `renv::snapshot()` may miss `gifski` because `scripts/05` calls it via
  `requireNamespace`, not `library` — name it explicitly in the snapshot.
- **`dplyr::summarise` name collision.** Expressions evaluate IN ORDER within one
  `summarise()`. An output column must NOT reuse an input column name that a later
  expression still reads: `pop_2022 = sum(pop_2022, ...)` then
  `n_pop_2022 = sum(!is.na(pop_2022))` counts the 1-length summary (=> n=1), not
  the group. `scripts/05` emits sums under `sum_*` names and renames only at the
  end. Watch for this in every roll-up.
- **`forcats` is not in `renv`.** `scripts/05` uses base `reorder()` for
  within-facet bar ordering, not `fct_reorder`. Do not add `forcats` just for one
  reorder. (`row_key` is unique per reserve, so base `reorder()` orders correctly
  inside a free-`y` facet.)
- **Roll-up: never average per-reserve percentages.** Sum the absolute pops per
  region, then compute the regional % on those sums (population-weighted).
  Averaging % over-weights small reserves. For a regional AAGR (spans differ,
  8 yr vs 4 yr), annualise over a `pop_baseline`-weighted mean span; report
  `change_pct` as primary.
- **`facet_wrap` has no `space="free_y"`.** Bar thickness therefore varies between
  facets in fig_01 (a 20-bar facet has thinner bars than a 7-bar facet). Cosmetic;
  `facet_grid(rows, space="free_y")` would equalise but loses the clean top strips.
  Left as-is for Week 7 (see the fig_01 cosmetic backlog for the story-map pass).
- **`terra::ext()` returns an S4 `SpatExtent` — not subsettable with `["xmin"]`.**
  `ext(r)["xmin"]` throws "object of type 'S4' is not subsettable". Coerce first:
  `as.vector(terra::ext(r))` gives a named numeric (`xmin,xmax,ymin,ymax`), then
  subset that. `scripts/06` STEP 8.2 does this for the extent-snap assertion.
- **`is.na()` on a SpatRaster is the BASE generic — call it unqualified.** There is
  no `terra::is.na` export (`'is.na' is not an exported object from 'namespace:terra'`);
  terra supplies the S4 method for the base generic, so `sum(is.na(stack))` and
  `!is.na(r)` work but `terra::is.na(...)` errors. Same pattern for other base
  generics terra dispatches (`mean`, `sum`, `min`, `max`) — do not prefix them
  with `terra::`. `scripts/06` STEP 8.5 uses `sum(is.na(cov_stack))` for the
  common NA mask.
- **A layer masked on one grid and resampled onto another has a one-cell edge
  shift** (corrected 2026-09-26; an earlier note called it a "+13 halo").
  `scripts/01` masked each covariate to India on its own grid; `scripts/06`
  resamples onto the snapped template. The edge moves by about one cell, so a
  band can hold cells OUTSIDE India and miss cells INSIDE it at the same time.
  Before Decision 12, landcover had 1,791 cells outside and no class in 1,778
  India cells — "+13" was only the net. **Rule:** mask to India on the FINAL
  template (as `06` now does for landcover, terrain and dist_road_m), never on
  an intermediate grid. gHM still carries the shift (no local source copy; the
  Decision-11 fill covers its edge cells). Quote the India-footprint loss from
  the `dist_road_m` row of `tbl_10`.
- **Keep `data/raw/worldcover/tiles_1km/` and
  `data/raw/terrain/dem_india_aws_z7_4326.tif`.** Since Decisions 12 and 13,
  `scripts/06` builds land cover from the 88 unmasked tiles and terrain from the
  raw DEM. They are required inputs, not caches to delete.
- **An imputed value must not feed a rule meant for observed values.** The
  Decision-11 fill imputed gHM over water to keep cells in the stack; the
  Decision-14 multiplier then used it as if observed (water mean 87.4 instead of
  50). Decision 16 exempts water. When a later rule reads a filled band, check
  whether it should see the filled cells.
- **QA the file on disk, not only the object in memory.** Until 2026-09-26 the
  6-band stack was written as `INT1U` (one GeoTIFF = one data type; terra chose
  unsigned 8-bit), so gHM and distance-to-road were 0 on disk while `tbl_10`,
  computed in memory, looked correct. `write_processed_rast()` now takes an
  explicit `datatype` (default `FLT4S`) and reads every raster back. Do not
  bypass it with a bare `writeRaster()`.
- **An inference is not a check.** In Week 9 a forecast ("`n_filled` will rise
  after the land-cover fix") failed because terrain had the same edge defect.
  When a fix targets one band, check the other bands for the same cause before
  the re-run.
- **Terrain tiles carry sea-floor depths (probably).** Stack elevation reaches
  −434.2 m in the `d13` build (water and edge cells now have terrain); India's
  lowest land is about −2 m. Decide the treatment in Week 14 (SDM terrain), before terrain enters any
  model.
- **`resist_*` has `NA` inside India under Decision 10.** The 98
  common-mask cells of the final (`d13f`) stack stay `NA` (91 water + 7 tile-
  corner cells), and every cell outside India (the 5 km collar too) is `NA`.
  An assert of "no `NA` inside India" (old task 9.7 wording) cannot pass;
  assert "no `NA` inside the complete-case footprint". `NA` cells block
  least-cost paths in Week 10, so no path can leave India.
- **Table numbers are not unique keys.** `tbl_00`, `tbl_02`, `tbl_04`,
  `tbl_11` and `tbl_12` each hold more than one table (naming §6). Refer to a
  table by its full filename.
- **Least-cost-path packages take one origin point.** `leastcostpath::create_lcp`
  uses only the first origin row; `gdistance::shortestPath` only the first
  origin cell. Edge-to-edge paths need a search from all source cells, which
  is why the engine is our own (`R/00_functions_lcp.R`).
- **16-neighbour knight steps jump one-cell barriers** under the usual
  end-cell cost. The engine's crossed-cells rule prevents it. Do not swap in a
  package's 16-neighbour cost for production paths.
- **`terra::nearest()` is a brute-force search** (about 5 hours for the
  footprint). Use `sf::st_nearest_feature()` in chunks (`lcp_alloc_zones()`).
- **`sf` 1.0-15: `st_cast()` of a whole boundary set to POINT gave the wrong
  feature ids.** Build points per feature from its own coordinates
  (`st_coordinates()`), and check that each feature's points lie on its own
  edge. The first test gave 36 pairs instead of 106.
- **`terra::costDist()` default `maxiter` (50) may not converge** on a long
  window. Use a higher value (the validation uses 1000) and capture the
  warning.
- **`write_processed_vec()` deletes the whole GeoPackage.** For a file with
  one layer per surface, use `lcp_write_layer()` (replaces one layer, reads it
  back).
- **Contiguous means a shared footprint cell, not gap 0** (Decision 17 point
  6, amended). With `touches = TRUE`, Namdapha–Kamlang (0.3 km) shares a cell;
  Nagarjunsagar-Srisailam–Amrabad touch along the split line.
- **`scripts/02` re-run guard (G-a).** On the first split run only units 1 and
  51 may change; afterwards the layer must be identical. Any other change
  stops `02` with nothing overwritten.
- **On Windows, R reports only its own heap.** `lcp_mem_report()` gives the
  process peak on Linux only; read Task Manager on Windows.
- **`igraph` weights must be above zero, and a weight is a distance.**
  `betweenness()` stops on a zero weight (`igraph` 1.6.0: "Weight vector must
  be positive"). The contiguous pairs (cost 0) are therefore merged into
  blocks (Decision 19), not given a small weight.
- **`igraph` `normalized = TRUE` divides by the pairs of the whole graph.**
  With three sets of different size it is wrong for this project.
  `net_node_metrics()` divides by the pairs of the node's own set.
- **The metrics table is per reserve, the values are per node.** 56 rows, 47
  nodes; block members share the node values. Count linchpins, cut nodes and
  ranks by `node_id`, never by rows.
- **`igraph::all_shortest_paths()` names its result differently by version**
  (`res` in 1.x, `vpaths` in 2.x). `net_betweenness_identity()` reads both.
- **A geometry rule can make a link that the literature does not know.** The
  network has no cost threshold (Decision 19), so each pair inside 315 km
  that passes P3 is a link — Orang–Dampa (305 km) is one. Check a named link
  against the literature section before it goes into the story.
- **Contiguous by the KML is not contiguous by notification.** The KML
  polygons are national-park and sanctuary outlines. Guru Ghasidas-Tamor
  Pingla and Sanjay Dubri are 1.59 km apart there (author choice g1: kept as
  a limitation).
- **"Pinch point" in this project is a network label** (Decision 20). It is
  not the pinch point of circuit-theory mapping, not "each road crossing"
  (those are `tbl_14_road_crossings.csv`), and not a measure of traffic. A
  documented crossing place can be a crossing that is not a pinch point; a
  road inside a node has no crossing at all.
- **The cell list of a path is more than its vertices.** A knight step
  crosses two middle cells that are not path vertices. Use
  `pinch_path_cell_list()`; the check is that the cost from the cell list
  equals `cost_rkm` of the path (relative 1e-9) on each surface.
- **No position finer than 10 km in a committed table or figure.**
  `outputs/tables/` and `outputs/figures/` are committed.
  `assert_publishable_table()` stops for a column named `cell`, `x`, `y`,
  `mean_x`, `lon`, `lat`, `geom` and others, for an `sf` object, and for a
  position off the 10 km grid. `lcp_road_crossings_7755.gpkg` holds 1 km
  positions and stays under `data/`.
- **The district layer is in `data/raw/administrative/`**
  (`boundary_districts_datameet2011_7755.gpkg`); the state layer is in
  `data/processed/`. The first STEP 12.2 looked in the wrong folders.
- **State and district come from two layers and can disagree at a border**
  (Natural Earth states; DataMeet 2011 districts): for example a Haryana
  state with a Delhi district. The districts are those of 2011 (Kumram
  Bheem Asifabad is Adilabad there).
- **A point exactly on a grid line has no cell until a rule gives one.**
  `pinch_grid_cell_xy()` puts it in the cell to the east or south. The site
  self-test holds this case.
- **`tapply()` gives a one-dimension array, not a vector.** `identical()`
  against a plain vector is then `FALSE` although the values are the same
  (the first QA run gave 73 of 74). Use `as.vector()`.
- **The road layer has no road name.** A pinch point cannot be matched to a
  named highway from the project data; a literature match is by link and
  district only.
- **A forecast in a Decision can be wrong.** Decision 20 named a robust
  variant label as likely; the result was "sensitive". Record the result
  and leave the Decision text as it is.
- **`ggplot2`: one legend for marks of two kinds needs one class factor.**
  `fig_03` puts nodes and pinch points in one table with one `cls` factor,
  so that shape, fill, colour, size and stroke make one legend. A `geom_sf`
  line layer with `show.legend = "line"` puts a line through each key of
  each legend; use `key_glyph = "path"` and leave `show.legend` alone.
  `ggrepel` is not in `renv`: the linchpins have numbers and a list.
- **Non-ASCII text in a script or an output.** The copyright sign in the
  `fig_03` caption is written as an escape (`\u00a9`); `tbl_03_notes.md` is
  ASCII only, and STEP 12.6 stops if it is not.
- **A chat cannot rebuild each surface.** In Week 12 the drafting workspace
  had the baseline surface and the path layers, not the `noghm` and
  `road15` surfaces; their cost check ran on stand-ins there and on the
  real files on the project machine. The project-machine run is the record.
- **A news page read through a web fetch can give the summary only.** Mark
  such an entry "summary only" in `references.md`.

---

## Weekly log (newest first)

### Week 12 — Road pinch points, publishable tables, network figure (Stage 2 close) · 2026-10-10
- Entry state: Week 11 complete; the network of Decision 19; no road
  crossing computed; the pinch-point rule pending.
- Did: Decision 20 (research, the forks, recorded before any crossing);
  `PINCH_*` settings; new `R/00_functions_pinch.R`; STEP 12.1 (barrier-road
  cells with class, guard against the Week-9 count), STEP 12.2 (crossings),
  STEP 12.3 (sites, rule, tiers), STEP 12.4 (variants, Decision-20
  comparison), STEP 12.5 (QA, 74 of 74), STEP 12.6 (publishable tables,
  publish check, note file), STEP 12.7 (`fig_03`). Each STEP ran on the
  project machine; each printed figure is the same as in the drafting
  workspace, which ran the delivered files on the real data. Literature
  check of the pinch points by link and district. Docs close with a Stage-2
  summary against proposal question 2 and ten new Limitations.
- Decisions made: **20** (numbered). Process and author choices: A2 (interim
  road raster + run switch), B1 (new function file), C1 (five `tbl_14`
  tables), L2 (`lit_flag` links by `unit_id` with a names guard); site id
  and site position rules; the variant output (comparison table + near
  flags, no "stable" label); `tbl_03b` = all 200 pinch points by tier; slugs
  `reserve_network` and `pinch_points`; `fig_03` number and slug; the figure
  shows all three tiers with tier 3 small and pale; seven build choices of
  the figure kept; link line width 0.3 kept; draft figure text kept for now;
  a note file next to the tables; task 12.9 done; the split point after
  task 12.6 not used.
- Outputs: see "Output files this week (Week 12)".
- Gotchas found: see the new entries under "Known gotchas" (the meaning of
  "pinch point", cell lists, the 10 km rule, the district folder, two admin
  layers, grid-line points, `tapply()` arrays, no road names, a wrong
  forecast, the `ggplot2` legend, non-ASCII text, surfaces that a chat
  cannot rebuild, summary-only pages).
- Errors of the chat, corrected in the week: the district layer path in the
  first STEP 12.2 (the run stopped before any output); wrong hand values in
  the crossing self-test and in the site self-test (found before delivery);
  an ambiguous separator in one comparison column; the `tapply()` array
  (QA 73 of 74 in the first workspace run).
- Result against the forecast: Decision 20 said that a robust variant label
  was likely. The gHM multiplier is "sensitive" for the pinch points.
- Carried forward / next week: **Week 13** — Stage 3 starts (occurrence
  cleaning and effort; new `scripts/08`). The task breakdown was written
  after the push (2026-10-10, `project-plan.md`); start with task 13.1, the
  occurrence-cleaning Decision 21, before any cleaned count. Open: the author's edit of the `fig_03` text and
  of `tbl_03_notes.md`; the Week-18 path-layer Decision; the references to
  verify; the `scripts/03` `I()` fix.

### Week 11 — Reserve network graph (Stage 2) · 2026-10-03 to 2026-10-04
- Entry state: Week 10 complete; paths on four surfaces; the functional-link
  rule pending. Two stale statements found when the files were read
  (`methodology.md` §5.3 tool; a config comment) — corrected first.
- Did: Decision 19 (research, six forks a–f, recorded before any metric);
  `NET_*` settings; new `R/00_functions_network.R`; STEP 11.1 (nodes, links,
  graph), STEP 11.2 (self-test, metrics, second run, threshold scan), STEP
  11.3 (variants, Decision-19 comparison), STEP 11.4 (network QA, 91 of 91).
  Each STEP ran on the project machine; each table is identical to a
  separate sandbox build and to an independent Python check. Literature check
  of the linchpin and weakly connected nodes. Docs.
- Decisions made: **19** (numbered; forks a1 + a4, b1, c1 + k3, d2, e2, f2;
  judgement values 3, 0.9, 2/3). Process choices: q1 (QA table
  `tbl_13_network_qa.csv`); g1 (Decision 17 contiguity kept; two data items
  recorded as limitations); table details confirmed before tasks 11.3–11.5.
- Outputs: see "Output files this week (Week 11)".
- Gotchas found: see the new entries under "Known gotchas" (zero weights,
  `normalized = TRUE`, rows against nodes, `all_shortest_paths` by version,
  links without literature support, KML contiguity).
- Corrections of the record: `methodology.md` §5.3 named "`leastcostpath` or
  `gdistance`" as the tool; the `ROAD_BARRIER_TOUCHES` comment gave the
  8-neighbour reason only. As built against the Decision-19 "Consequences"
  text: the self-test is in STEP 11.2, a fifth table exists, the graph is
  rebuilt from the paths layer.
- Carried forward / next week: **Week 12** — the task breakdown was written
  after the push (2026-10-04, `project-plan.md`); start with task 12.1, the
  pinch-point Decision 20, before any road crossing is computed. `fig_03` is
  not in use; confirm the figure number. Open: the `scripts/03` `I()` fix.

### Week 10 — Least-cost paths (Stage 2) · 2026-10-01 to 2026-10-03
- Entry state: Week 9 complete; four resistance surfaces; Decisions 17–18
  pending.
- Did: Decision 17 (path set-up; amended 2026-10-02: contiguous = shared
  cell) and Decision 18 (variant metric), both before the paths; own path
  engine `R/00_functions_lcp.R` (sandbox checks (a)–(c) passed); `00a` package
  list from `renv::dependencies()`; `scripts/07` switches (RS1), surface guard,
  STEP 10.0 smoke test (Kanha–Pench, 0.3 s); Amrabad split in `scripts/02`
  (STEP 4b, guard G-a) with a Stage-1 re-run 02 → 05 (before/after check
  PASS); STEP 10.1 pairs (106); STEP 10.2 baseline paths; STEP 10.2b
  validation (15 of 15; V-add pair Bandhavgarh–Panna); STEP 10.3 QA; STEP
  10.4 variants + Decision 18 (both choices robust); literature check of the
  extremes (L1 limitation); STEP 10.5 NTCA overlap (descriptive).
- Decisions made: **17**, **18** (numbered); process choices F1-A (tool named
  in Decision 17), RS1 (run switches + `_split` label), G-a (02 guard), V-add,
  QA in one table, NTCA overlap in two tables, L1.
- Outputs: see "Output files from Week 10 (unchanged)".
- Gotchas found: see the new entries under "Known gotchas" (one-origin
  packages, knight jumps, `terra::nearest`, the `sf` id fault, `costDist`
  convergence, `write_processed_vec`, contiguous by cell, G-a, Windows memory).
- Corrections of the record: Decision 17/18 dates (2026-10-01, not
  2026-09-27); the gap-0 count after the split (8, not 7); the poly/census
  median (0.515, not ~0.58); the Week-3 Amrabad limitation.
- Carried forward / next week: **Week 11** — the task breakdown was written
  after the push (2026-10-03, `project-plan.md`); start with task 11.1, the
  functional-link Decision 19, before any network metric. Open: the
  `scripts/03` `I()` fix.

### Doc fix pass (before Week 10) · 2026-09-27
- Entry state: Week 9 complete; a consistency check found stale or
  inconsistent statements in the docs.
- Did: corrected `methodology.md` (§5.3 tool and resistance basis; settlement
  label; change-log entry), `data-dictionary.md` (`dist_road_m`, `cov_distroad`
  and `tbl_10` figures from the `d13f` `tbl_10`; `WORLDCOVER_RESISTANCE` is
  Decision 14; `tbl_10` column note; `source_stat`; last line),
  `naming-conventions.md` (§6 `tbl_11` row, checked against a listing of
  `outputs/tables/`), `data-sources.md` (OSM: tertiary closed by Decision 15;
  settlement flag → Week 13), `project-plan.md` (Week-10 entry state and
  pitfall: resistance is `NA` outside India, the collar included; task 10.3
  sets the `00a` list), `README.md` (Stack row; Growth row 2014/2018/2022),
  this handoff (`resist_*` gotcha merged; Week-10 note; table-number gotcha).
  Corrected the path of `tbl_04_secondary_sources_2006_2010.md` (it is only in
  `outputs/tables/`, not `docs/`) in `data-sources.md`, `references.md` and
  naming §6. Added a `proposal.md` §8 deviation entry: the resistance surface
  adds human pressure (Decisions 14–16), with a §5 pointer.
  No script, data layer or rule changed; no re-run.
- Decisions made (not numbered — process/doc choices): **F1-A** — docs say the
  path tool is fixed in Decision 17; `scripts/00a` keeps `leastcostpath` until
  task 10.3 sets it to the chosen tool; **F2** — record the pass in the
  methodology change log and here.
- Outputs: the nine docs above.
- Gotchas found: none new. The resistance `NA` footprint (every cell outside
  India) is now stated where Week 10 reads it.
- Carried forward / next week: **Week 10** — Decisions 17 and 18 first. At the
  Week-10 header edit of `scripts/07`, remove the repeated `OUTPUTS` line in
  the STEP-9.2 header block.

### Week 9 — Resistance surfaces (Stage 2) · 2026-09-26
- Entry state: Week 8 stack (3,010,738 complete-case cells; gHM gap-fill
  deferred by Decision 10); the doc fix pass done.
- Did: task 9.2a (corridor layer from `scripts/02`, with a re-run guard); 9.1
  + 9.2 (`scripts/07` header and the Decision-10 relevance check); the gHM
  fill in `scripts/06` STEP 8.4b; land cover and terrain rebuilt at source in
  `scripts/06`; found and fixed the `INT1U` stack write (`write_processed_rast`
  now has an explicit datatype and a read-back check); 9.3 + 9.4 (resistance
  and road Decisions, each with a literature review and a data check); 9.5–9.8
  (four resistance surfaces + QA); 9.9 (docs).
- Decisions made: **11** (gap-fill rule; pre-registered), **12** and **13**
  (post-result: land cover and terrain from unmasked sources), **14**
  (resistance values, gHM multiplier, Sundarban water, `noghm`), **15** (road
  barrier, `road15`/`road50`), **16** (post-result: water exempt from gHM).
  Process choices recorded in the change log: fill in `scripts/06` (G1); stop
  and decide again if a re-check still triggers (H3); outputs labelled by fill
  state / `build_tag` (I1); XML entities decoded in corridor labels (J1).
- Outputs: see "Output files this week (Week 9)".
- Gotchas found: mask on the final template, not an intermediate grid; QA the
  file on disk, not only memory; when a fix targets one band, check the others
  for the same cause; imputed covariate values must not leak into a rule meant
  for observed values (Decision 16).
- Carried forward / next week: **Week 10** — least-cost paths; Decisions 17
  (set-up) and 18 (variant comparison metric) first (see Current state and
  `project-plan.md` → Week 10).

### Doc fix pass (before Week 9) · 2026-09-26
- Entry state: Week 8 complete; docs carried stale or false statements found by a
  consistency check.
- Did: corrected `methodology.md` (§5.2 series; Decision 10 figures + the false
  `tbl_10` claim; missing Week-5 heading; §5.3 script note), `data-sources.md`
  (2018 page range; admin-boundaries heading), `data-dictionary.md` (`tbl_10`
  writer + new columns; exact coverage; halo note; distroad max),
  `project-plan.md` (script plan; task 8.3/9.1/9.2/9.7 text; Stage 3 numbers),
  `naming-conventions.md` (§6 table-number rule), `README.md`, this handoff.
  Added `n_valid_before` + `n_dropped_by_mask` + two hard stops to `scripts/06`
  STEP 8.6 and fixed its stale comments; **re-ran `scripts/06`** — stack
  identical, `tbl_10` rewritten with the new columns. Recovered
  `scripts/00c_verify_wdpa_boundaries.R` (deleted by accident).
- Decisions made (not numbered — process/doc choices): **A1** table numbers group
  related tables, slug is the key; **B2** make `tbl_10` hold the before-mask
  counts; **C** Stage 2 is one script `scripts/07_connectivity.R`, stubs
  `08_habitat_suitability.R` + `09_build_site.R` deleted.
- Outputs: updated `scripts/06_build_covariate_stack.R`,
  `tbl_10_covariate_stack_qa.csv` (2 new columns), the docs above.
- Gotchas found (now in "Known gotchas"): edge halo outside the India polygon;
  `NA` inside India in any Decision-10 derived surface; table numbers are not
  unique keys. The Week-8 figures "~56,840 (~1.8%)" and distroad "max ~278.9 km"
  in the Week-8 log below are superseded (56,827 / 1.85%; interim max 279.7 km).
- Carried forward / next week: **Week 9** — start `scripts/07_connectivity.R`;
  Decision-10 relevance check, land-cover resistance values, barrier road
  classes.

### Week 8 — Covariate stack (Stage 2 input assembly) · 2026-09-20
- Entry state: Stage 1 (growth) done. Week-2 covariate layers on disk in
  `data/interim/` (WorldCover 1 km modal, gHM 1 km, terrain 3-band 1 km) + OSM
  roads in `data/raw/osm/`; boundaries in `data/processed/`. `06` slot was the
  header-only stub `06_covariates.R` (`# ... (fill in Week 6)`).
- Did (tasks 8.1-8.6, all in `scripts/06_build_covariate_stack.R`):
  - **8.1** header/scope + path block + fail-early guards. Renamed the deliverable
    to `06_build_covariate_stack.R` (naming §3); corrected the input path (Week-2
    covariate rasters are in `data/interim/`, not `data/processed/`).
  - **8.2** one 1 km EPSG:7755 template from the national boundary, 5 km collar,
    extent snapped to whole `GRID_CELL_M` (3093 × 2864 = 8,858,352 cells);
    extent/res/CRS asserted.
  - **8.3** aligned the 3 covariates onto the template — WorldCover near, gHM +
    terrain bilinear; `compareGeom` PASS all three. Did NOT use `read_rast()`
    (already-7755 inputs → straight `resample`, one interpolation each).
  - **8.4** `cov_distroad_1km_7755.tif` by rasterise→`terra::distance`
    (`touches=TRUE`) over 885,669 roads; min 0 / max ~278.9 km / mean ~2.0 km.
    Inline road-class set = all 5 major classes (tertiary kept — barrier class is
    Week 9).
  - **8.5 + Decision 10** stacked 6 bands (`landcover, ghm, elev, slope, tri,
    dist_road_m`) → `cov_stack_1km_7755.tif`; common NA mask (any band NA → all
    NA). 3,010,738 complete-case cells; gHM binding, ~56,840 (~1.8%) dropped.
  - **8.6** `tbl_10_covariate_stack_qa.csv` — all 6 bands 3,010,738 cells / 98.15%
    / range_ok TRUE; stacked-vs-source spot-check matches (gHM 0.377/0.377, elev
    577/571, slope 2.54/2.50, tri 23.4/23.1, dist_road 2019/2045, landcover modal
    40 n_class 11 both).
- Decisions made: **Decision 10** (covariate-stack common NA mask; gHM gap-fill
  deferred to Week 9).
- Outputs: `scripts/06_build_covariate_stack.R`, `cov_stack_1km_7755.tif`,
  `cov_distroad_1km_7755.tif`, `tbl_10_covariate_stack_qa.csv`; updated
  `methodology.md`, `data-dictionary.md`, `project-plan.md`, `README.md`, this
  handoff. No new `renv` dependency.
- Gotchas found (now in "Known gotchas"): `terra::ext()` returns an S4
  SpatExtent — not subsettable with `["xmin"]`; coerce with `as.vector()` first.
  `is.na()` on a SpatRaster is the base generic (terra S4 method) — call it
  unqualified, `terra::is.na` is not an exported symbol.
- Carried forward / next week: **Week 9** — Stage 2 resistance surface. Decide
  land-cover resistance values + barrier road classes (numbered), and run the
  Decision-10 gHM gap-fill relevance check. **At commit: `git rm
  scripts/06_covariates.R`** (the old stub) so the `06` slot is not duplicated.

### Week 7 — Growth visuals + regional roll-up · 2026-09-20
- Entry state: `stats_reserve_census_7755.gpkg` carried all growth columns;
  `tbl_01_reserve_growth.csv` written (Week 6); `scripts/05_growth_analysis.R` was
  the renumbered header-only stub.
- Did (tasks 7.1-7.6, all in `scripts/05_growth_analysis.R`):
  - **7.1** rewrote the header/scope — fixed the frame count (the stub said "five
    census years"; Decision 6 fixes it to 3) and replaced the stale
    `# ... (fill in Week 4)` with `TODO(Week 7)` staging.
  - **7.2** `rollup_by()` for landscape complex and state; roll-up rule recorded
    inline (STEP 2): sum non-NA with a per-field coverage count; ratio recomputed
    on the summed pops, single contributor set; regional AAGR over a
    pop_baseline-weighted mean span.
  - **7.3** wrote `tbl_02_regional_rollup.csv` (23 rows); added `n_measured`.
  - **7.4** `fig_01` ranking, faceted by landscape, NAs shown separately, effort
    caveat wrapped in caption.
  - **7.5** `fig_02` 3-frame choropleth (`transition_manual`, fixed geometry);
    NA → grey "No estimate", real 0 → "0 (real)", 3 geometry-absent named off-map.
  - **7.6** STEP 7 hard-stopping verification block — all 13 checks OK.
- Decisions made: none (the roll-up NA rule is an inline choice, uncontested).
- Outputs: `scripts/05_growth_analysis.R` (filled), `tbl_02_regional_rollup.csv`,
  `fig_01_growth_ranking.png`, `fig_02_growth_animation.gif`; updated
  `data-dictionary.md`, `project-plan.md`, `README.md`, this handoff; `renv.lock`
  gains `gifski`.
- Gotchas found (now in "Known gotchas"): `transition_states` tweens `geom_sf`
  geometry → use `transition_manual`; `gifski` is a separate install from
  `gganimate`; `summarise` name-collision (summed col shadows the input a later
  expr reads); `forcats` not in `renv` → base `reorder()`; never average
  per-reserve % in a roll-up; `facet_wrap` has no `space="free_y"`.
- Data notes (not bugs): Sundarbans has a `pop_2022` `NA`, so it is grey in fig_02
  2022, absent from the fig_01 bars, and NA in the tbl_02 ratio — correct. Amrabad
  ranks in fig_01 (tabular) but is one of the 3 geometry-absent reserves, so it is
  named off-map in fig_02 (cannot be a polygon).
- Carried forward / next week: **Week 8** — Stage 2 (Connectivity) starts. Build
  `scripts/06_build_covariate_stack.R` → `cov_stack_1km_7755.tif` (WorldCover,
  gHM, terrain, distance-to-road on one 1 km EPSG:7755 template). Assembly only;
  the resistance-value + barrier-road-class Decisions are Week 9. Watch the
  categorical-vs-continuous resample rule and the PROJ `proj.db` clash.

### Week 6 — Growth metrics derived · 2026-09-19
- Entry state: `stats_reserve_census_7755.gpkg` built (Week 5) with
  `pop_2014/2018/2022`, notified `area_km2`, `density_2022`, `baseline_year`,
  `census_status`; growth columns not yet computed; Decision 9 pending.
- Did (tasks 6.1-6.8):
  - **6.1** - metrics go in a NEW `scripts/04_growth_metrics.R` (derive);
    renumbered the visuals stub `04_growth_analysis.R` -> `05_growth_analysis.R`.
  - **6.5 / Decision 9** - real within-reserve zeros: `change_abs` always valid;
    zero baseline -> `change_pct`/`aagr` `NA` + `growth_zero_flag`; real 2022 zero
    -> valid -100; never `Inf`/`NaN`.
  - **6.2** `change_abs` (non-`NA` 49); **6.3** `change_pct` + `growth_zero_flag`
    (non-`NA` 48; flag TRUE 1); **6.4** `aagr` over each reserve's own span
    (non-`NA` 48). **6.6** wrote `tbl_01_reserve_growth.csv` (58 reserves,
    sorted by `change_pct` desc). **6.7** whole-set verify (no `Inf`/`NaN`; NA
    pattern per Decisions 7/9; national split 32 growing / 17 declining).
    **6.8** appended the four columns to the stats layer + re-read round-trip.
- Decisions made: **Decision 9** (real within-reserve zeros in growth metrics).
- Outputs: `scripts/04_growth_metrics.R`, `scripts/05_growth_analysis.R` (renamed),
  `tbl_01_reserve_growth.csv`, updated `stats_reserve_census_7755.gpkg`;
  updated `methodology.md`, `data-dictionary.md`, `project-plan.md`, `README.md`,
  this handoff.
- Gotchas found: (1) the 6.2 done-when wording ("2022-only or NA pop_2022") is
  incomplete - a 2022-only reserve computes `change_abs = 0` unless you guard on
  SPAN, not just endpoints; guard on `baseline_year < 2022`. (2) Only **3**
  single-round reserves, not 4 - Navegaon-Nagzira has a 2014/2018 figure; trust
  the data-driven NA set, not the old planning list. (3) `growth_zero_flag` marks
  ONLY the zero-baseline case (ratio-undefined `NA`); a real 2022-zero decline is
  a valid -100, unflagged - do not blur the two.
- Carried forward / next week: **Week 7** - fill in `scripts/05_growth_analysis.R`
  (reads the stats layer): `fig_01` ranking, `fig_02` animated choropleth
  (3 frames, Decision 6), `tbl_02_regional_rollup.csv`. `NA`/geometry-absent
  reserves must render as a distinct "no estimate" class, never 0. Roll-up: sum
  absolute pops per region then recompute %, do NOT average per-reserve %.


### Week 5 — Census join, area overwrite, density, stats layer · 2026-09-13
- Entry state: `census_reserve_long.csv` extracted (Week 4); boundary layer with
  provisional `area_km2`; no stats layer.
- Did (tasks 5.1–5.9):
  - **5.1 + Decision 8** — located the reserve area source. Neither census report
    tabulates area; ISFR-2021 Ch.4 carries a WII digitized-boundary GIS area, not
    the notified total. Chose the NTCA-notified core+buffer total (consolidated
    notifications), ISFR as cross-check only. Built `tbl_05_area_source_map.csv`
    (58) + `tbl_05b_isfr_area_crosscheck.csv` (52). Notified total 84,507 vs NTCA
    stated 84,487.
  - **5.2** — `scripts/03` reads long, validates, pivots wide (53 reserves;
    45/50/53). **5.3** — left-join onto boundaries (58; 53 measured + 5 flagged;
    3 geometry-absent keep census). **5.4** — area overwrite (zero value change).
    **5.5** — density_2022 (52 values). **5.6** — baseline_year (45/5/3). **5.7** —
    wrote `stats_reserve_census_7755.gpkg` (58 reserves, 20 cols + geometry).
  - **5.8** — verified the 6 crosswalk `review` rows (all correct). **5.9** —
    reconciled config to Decision 6 (added `CENSUS_SERIES_YEARS`/
    `CENSUS_BASELINE_YEAR`; kept `BASELINE_YEAR` as the GBIF bound).
- Decisions made: **Decision 8** (reserve area source).
- Outputs: `scripts/03_prepare_census.R`, `stats_reserve_census_7755.gpkg`,
  `tbl_05`, `tbl_05b`, `tbl_06`–`tbl_09`; updated `methodology.md`,
  `data-dictionary.md`, `project-plan.md`, `README.md`, `R/00_config.R`, this handoff.
- Gotchas found (now in "Known gotchas"): `BASELINE_YEAR` double-duty (census vs
  GBIF bound); quoted-`#` comment block in the census CSV breaks `comment="#"`;
  ISFR area is a WII polygon area not the notified total; density is per-total-area
  not core-only; `table(useNA="ifany")` NA bin breaks name-indexed printing (fixed
  by index iteration). Process note: one mis-placed str_replace scrambled step
  order mid-build; caught in the coherence check and rebuilt — re-read the file
  before large edits.
- Carried forward / next week: **Week 6** — growth metrics (change/%/AAGR) →
  `tbl_01_reserve_growth.csv` + append to the stats layer. **Decision 9**
  (zero-baseline handling) first. Delete the stale `tbl_05_census_wide_check.csv`.

### Week 4 — Census time series extracted (full) · 2026-09-12
- Entry state: boundary layer built with **provisional** `area_km2`; the five NTCA
  reports on disk, not parsed; missing-year Decision pending.
- Did:
  - **4.1** — located the per-reserve figures in all five reports. Found the
    tabular figures exist **only for 2014/2018/2022** (Table 2.2 / 3.4 / I.3.3);
    2006/2010 have no per-reserve table. Wrote `tbl_04_census_source_map.csv`.
  - **Decision 6** — census figure type + baseline: within-reserve SECR,
    2014/2018/2022 only; 2006/2010 are context, not a baseline. Corrected the
    methodology limitation that wrongly called all rounds SECR.
  - **4.2 → Decision 7** — missing (reserve, round) = `NA`; no imputation.
    Grounded in the observed gap structure (left-censoring, no internal gaps).
  - **4.3** — long table shape fixed; `census_reserve_long.csv` template;
    data-dictionary updated (long + wide schema; dropped `pop_2006/2010`).
  - **4.4** — extracted the **full** series (planned as half):
    `census_reserve_long.csv`, 148 within-reserve rows / 53 reserves + 5 flags.
    2022 transcribed from a page raster.
  - **4.5** — spot-check passed: 2022 vs PIB release **17/17**; 2014 sum = report
    total (1586) exactly; 2018 sum +35 vs report's de-double-counted 1923
    (expected). Wrote `tbl_04_spotcheck_log.md`.
  - **Prose sweep** (extra) — table-missing reserves checked in prose. Added
    Orang 2014 + Ratapani 2022 as **supplementary** (segregated), Mukundara 2014
    = real within-reserve 0. No 2018 additions.
  - **2006/2010 secondary table** (user request) —
    `census_reserve_long_2006_2010.csv` (24 prose figures, confidence-graded,
    context only). Confirmed Singh & Sen supplies no values; no other reference
    gives a comparable reserve-level count set
    (`tbl_04_secondary_sources_2006_2010.md`). Added 3 references.
- Decisions made: **Decision 6** (census figure type + baseline), **Decision 7**
  (missing-year handling = `NA`).
- Outputs: `census_reserve_long.csv`, `census_reserve_long_2006_2010.csv`,
  `tbl_04_census_source_map.csv`, `tbl_04_spotcheck_log.md`,
  `tbl_04_secondary_sources_2006_2010.md`; updated `methodology.md`,
  `data-dictionary.md`, `references.md`, `project-plan.md` (Week 4 ✅ + Week 5
  tasks), this handoff.
- Gotchas found (all now in "Known gotchas"): 2022 Table I.3.3 PDF text layer is
  corrupt → read from a page raster; take the **within** column not "utilising";
  2006/2010 have no per-reserve table; Singh & Sen bars are normalised indices,
  not counts; two Pench = two `unit_id`; `-`/`0` is a real zero.
- Carried forward / next week: **Week 5** — pivot long → wide, join census to the
  boundary layer, **overwrite `area_km2`** from the census area (find that table
  first — task 5.1), compute `density_2022`, write
  `stats_reserve_census_7755.gpkg`. Also reconcile `R/00_config.R` `BASELINE_YEAR`
  drift (still 2006, pre-Decision-6). Glance at the 6 crosswalk `review` rows.

### Week 3 — Reserve boundary layer built · 2026-09-11
- Entry state: all covariates + admin boundaries + NTCA DSS KML on disk; boundary
  layer not built; the five NTCA census reports not yet downloaded.
- Did:
  - **Task 3.1** — downloaded the five NTCA All India Tiger Estimation reports
    (2006, 2010, 2014, 2018, 2022) into `data/raw/ntca/` (PDF; no Excel).
  - **Tasks 3.2–3.6** — wrote and ran `scripts/02_prepare_boundaries.R`. Built
    `boundary_reserves_all_7755.gpkg` (58 reserves: 55 geometry + 3 absent) and
    `boundary_states_7755.gpkg` (36). Built the hand-reviewed
    `reserve_pa_crosswalk.csv` (58 reserves → constituent KML PA names + a
    provisional area placeholder). Added QA columns (`poly_km2`,
    `poly_census_ratio`) and a build report (`tbl_02_reserve_build_report.csv`).
    Preserved the 156 unnamed KML duplicates to
    `data/interim/boundary_kml_unattributed_7755.gpkg`.
  - Updated docs: `data-dictionary.md` (new reserve schema), `methodology.md`
    (Week-3 change log + Nagarjunsagar limitation), `data-sources.md`,
    `proposal.md` (§8), `README.md`, `project-plan.md` (Week 3 ✅ + Week 4 tasks).
- Decisions made: none numbered (Decision 4 unchanged; the Week-3 change log
  records the as-built refinements to it).
- Outputs: `scripts/02`, `boundary_reserves_all_7755.gpkg`,
  `boundary_states_7755.gpkg`, `boundary_kml_unattributed_7755.gpkg`,
  `reserve_pa_crosswalk.csv`, `tbl_02_reserve_build_report.csv`, updated docs.
- Gotchas found (all now in "Known gotchas"): GDAL KML driver drops the
  SchemaData fields and splits the file into two layers → parse with `xml2`;
  `st_as_sfc()` on KML snippets returns empty geometry; the KML `corridor` layer
  is actually the 156 duplicates; `unit_name` is not unique (two Pench, two Rajiv
  Gandhi) → match on name + state. New dependency: `xml2`.
- Data QA: polygon/census ratio median ~0.58 (expected — polygons under-state the
  legal total). One outlier — Nagarjunsagar-Srisailam ratio 1.54 (coarse source
  geometry; not an Amrabad overlap; area is census-sourced so no metric affected)
  — documented in `methodology.md` Limitations.
- Carried forward / next week: **Week 4** — extract the all-reserve census time
  series from the five NTCA reports (manual). Make the **missing-year Decision**
  first (numbered). 6 crosswalk `review` rows to glance at when joining the
  census. `area_km2` overwrite from census happens in Week 5.

### Week 2 (part) — Admin boundaries + Week-2 close · 2026-09-07
- Entry state: covariates + boundary KML acquired; admin + manual downloads
  pending.
- Did: added `scripts/01` Block 8 — Natural Earth states (36) + DataMeet
  Census-2011 districts (641), scripted, reprojected to 7755. Fetched the manual
  PDFs by hand (ISFR 2021 Ch.4, Singh & Sen 2015). **Did NOT download the NTCA
  census reports** — deferred to Week 3 (task 3.1). Re-ran `00b`: **12/14
  PRESENT** (the 2 MISSING are the rejected KBA/WDPA sources — by design). Fixed
  admin/terrain/settlement manifest globs. `renv::snapshot()` (adds osmextract,
  elevatr, rnaturalearthhires). Confirmed no data staged for commit.
- Decisions made: none new (Decisions 4 + 5 already logged; 4 new pending
  Decisions added to methodology this week).
- Outputs: admin boundary layers; updated `data-sources.md`, `references.md`,
  `methodology.md`, `data_manifest.csv`, `project-plan.md` (Week 2 ✅), this
  handoff.
- Gotchas found: `ne_states()` needs `rnaturalearthhires` (not on CRAN — install
  from `https://ropensci.r-universe.dev`). Streamed/windowed pulls and
  osmextract/elevatr outputs needed manifest glob fixes to audit PRESENT (the
  default globs assume download-to-disk files).
- Carried forward / next week: **Week 3** — download the five NTCA census
  reports (task 3.1); build the reserve boundary layer from the KML
  (`scripts/02`); resolve the 3 unmatched + 2 false-matched reserves.

### Week 2 (part) — Scripted data downloads · 2026-09-07
- Entry state: boundary Decision made; `data/raw/` otherwise empty.
- Did: wrote and ran `scripts/01` blocks 1–7 — India boundary (Natural Earth),
  GBIF tiger occ + Mammalia background, WorldCover (1 km modal), gHM 2022 (1 km),
  OSM roads + settlements (Geofabrik via osmextract), terrain (elevatr AWS z7,
  elevation/slope/TRI). All covariates on the 1 km EPSG:7755 grid. Verified
  terrain covers full India. Fixed several manifest glob/subpath mismatches so
  `00b` audits the streamed/windowed pulls correctly (6 PRESENT).
- Decisions made: none numbered this entry (Decision 5 — Mammalia target group —
  was logged with the GBIF work). Several forks surfaced for end-of-week
  pending Decisions: road classes, settlement filtering, terrain variable
  selection.
- Outputs: interim covariate layers (`cov_landcover_..._1km_7755.tif`,
  `cov_ghm2022_1km_7755.tif`, `cov_terrain_1km_7755.tif`), raw GBIF/OSM/terrain,
  updated docs + manifest.
- Gotchas found: **PROJ/PostGIS `proj.db` clash** (see Known gotchas — cost most
  of this session; fixed via `.Rprofile` PROJ_LIB pin). WorldCover 10 m national
  reproject fails / is far too slow — reproject each tile to a 1 km template
  instead. osmextract needs `max_file_size` raised for the 1.5 GB India pbf, and
  an interrupted convert leaves a locked `.gpkg` (delete it + restart R).
- Carried forward / next week: manual downloads (2.6); then re-audit, commit,
  and write the end-of-week pending Decisions.

### Week 2 (part) — Boundary-source Decision · 2026-09-07
- Entry state: `00a` clean; `renv` locked; `data/raw/` empty; `00b` all 13
  MISSING; boundary source not chosen.
- Did: ran task 2.1 (boundary feasibility). Verified three candidate sources
  against the 58 official reserves. **WII** authoritative layer not publicly
  downloadable. **WDPA** holds zero Indian national PAs (India country profile:
  "national designations only = 0"; the extract is Ramsar/WHS only, 63 polygons)
  — rejected. **KBA** 51/58, core-PA area only, no corridors. **NTCA DSS KML**
  55/58 + corridors, core-PA area only. Chose the KML (Option C): geometry from
  KML, area/density from the NTCA census. Recovered KML provenance from the
  Phase-2 project docs (no re-download needed).
- Decisions made: **Decision 4 — Reserve boundary source and area basis**
  (methodology.md).
- Outputs: `scripts/00c_verify_wdpa_boundaries.R`,
  `outputs/tables/tbl_00_kba_tr_match.csv`. Updated `methodology.md`,
  `data-sources.md`, `data/data_manifest.csv`, `README.md`, this handoff.
- Gotchas found: WDPA India national layer does not exist publicly — do not
  re-attempt. KBA and the NTCA KML both store the **core PA polygon, not the
  legal TR extent** — never derive reserve area from either geometry.
- Carried forward / next week: finish Week-2 downloads (tasks 2.4–2.9); in
  Week 3 fix the 3 unmatched + 2 false-matched reserves when building the
  boundary layer.

### Week 1 — Setup + data audit · 2026-09-06
- Entry state: scaffold on `main`; `gh-pages` live (placeholder site); no data
  re-acquired; `renv` not initialised; no analysis.
- Did: ran `00a` (toolchain clean — GDAL 3.12.1 / GEOS 3.14.1 / PROJ 9.7.1;
  EPSG:7755 resolves). Reviewed prior-project disk contents; decided the
  surviving Phase 1 files (7-reserve census, ISFR 2017, 7-reserve corridors) are
  not usable for an all-reserve analysis, so left `data/raw/` empty. Ran `00b`
  audit (all 13 MISSING — the honest baseline). Ran `renv::init()` + `snapshot()`
  (124 packages; R 4.5.2 pinned).
- Decisions made: (none numbered; note the working call to reject Phase 1 data
  as insufficient — logged here, not a methodology Decision)
- Outputs: `outputs/tables/tbl_00_data_audit.csv`, `renv.lock`
- Gotchas found: audit checks presence not coverage; `00b` glob is recursive +
  case-insensitive (see "Known gotchas").
- Carried forward / next week: Week 2 closes the data gap the audit found and
  makes the **boundary-source Decision** (WII TR vs KBA fallback).

### Week 0 — Scaffolding · 2026-09-06
- Built the full repo scaffold in R (config, IO + sensitive functions, 11
  numbered script stubs, 8 docs, Quarto site, GitHub Action).
- Fixed Decisions 1–3.
- Committed and pushed `main`; bootstrapped `gh-pages`; site live with
  placeholder pages.
- **Carried forward:** three pending Decisions (Weeks 2/4/9); data audit is the
  Week 1 job.

---

## Template — copy this block for each new week

```
### Week N — <topic> · <date>
- Entry state: <what existed at the start>
- Did: <what was completed>
- Decisions made: <numbered Decisions added to methodology.md, if any>
- Outputs: <files produced>
- Gotchas found: <anything worth not relearning>
- Carried forward / next week: <what Week N+1 starts from>
```
