# Project Plan

**Project:** India's Tiger Network
**Author:** Kiran Balasubramanian
**Start:** September 2026
**Pace:** **2–4 hours per week**, alongside full-time work. Weeks are
self-contained and may slip. The plan below is sized to that cadence.

---

## How to read this plan

- Each **week is one small unit** of 2–4 hours. It has a clear entry state, a
  clear exit state, and a single deliverable where possible.
- Weeks are grouped into **stages**, one per analysis track, in priority order.
- The pace is honest: at 2–4 h/week this is a **multi-month project**, roughly
  **5–6 months** of calendar time if weeks rarely slip. That is expected and
  fine.
- A week that needs a design decision **ends by asking the decision**, not by
  guessing. Code follows the decision the next week.

---

## Week 0 — Scaffolding (done)

The repository, R environment, and documentation set already exist (this
scaffold). Week 0 is not new build work — it is **verify and commit** what was
scaffolded, so Week 1 starts from a clean, version-controlled base.

| # | Task | Done when | Est. |
|---|---|---|---|
| 0.1 | Unzip the scaffold into a local folder named `tiger-network` | Folder opens with the tree in the README | 5 min |
| 0.2 | Open `tiger-network.Rproj` in RStudio | Project loads; working directory is the repo root | 5 min |
| 0.3 | Read the three core docs: `proposal.md`, `project-plan.md`, `methodology.md` | You agree with Decisions 1–3 and the scope, or note changes | 20–30 min |
| 0.4 | Confirm the three pending forks are acceptable as *pending* (boundary source, missing-year handling, resistance values) | You are happy to decide these in Weeks 2/4/9, not now | 5 min |
| 0.5 | `git init`; create the GitHub repo `tiger-network` under `K-bsub`; set `main` as default | Empty remote exists and is linked | 10 min |
| 0.6 | First commit of the scaffold (docs + code + config, **no data**) | `git status` shows nothing under `data/raw`, `data/processed`, `data/restricted` staged | 10 min |
| 0.7 | Confirm `.gitignore` excludes data and heavy outputs | `git status --short` lists no `.tif`/`.gpkg`/`.rds` from `data/` or `outputs/rasters` | 5 min |
| 0.8 | Push `main` to GitHub | Remote shows the scaffold; `.gitkeep` files hold the empty folders | 5 min |

**Not in Week 0:** running `renv::init()` (that is Week 1, after `00a` verifies
the toolchain), any data download, and any analysis. Week 0 ends with a
committed, pushed scaffold and no data in version control.

**Exit state:** `tiger-network` repo is live on GitHub with the full scaffold on
`main`, data-free, ready for Week 1.

---

## Stage 0 — Setup and audit (Weeks 1–2)

| Week | Focus | Exit state (deliverable) | Est. |
|---|---|---|---|
| **1** | Environment + data audit | `00a` runs clean; `00b` audit table written; you know exactly what data is present vs missing | 2–3 h |
| **2** | Re-acquire gaps + boundary decision | Missing scripted data re-downloaded; **Decision:** WII TR boundaries vs KBA fallback | 3–4 h |

**Week 1 note:** the audit is the whole point of this stage. It tells us how much
of "all reserves" is already on disk and how much must be rebuilt.

**Week 2 note:** the boundary decision is the biggest feasibility fork. If the
authoritative WII/NTCA all-reserve boundary layer is not publicly downloadable,
we fall back to KBA (with the Corbett-style area caveat) and record why.

---

## Stage 1 — Growth (Weeks 3–7) · priority 1

This is the largest data-effort stage. Phase 1 extracted reserve-level census
for **7 reserves**. Extending to **all reserves** across five census rounds is
the main new work, and it is manual PDF/Excel extraction.

| Week | Focus | Exit state (deliverable) | Est. |
|---|---|---|---|
| **3** | Boundary layer built | `02` output: reserves layer with unit_id, state, landscape_complex, area_km2 | 3–4 h |
| **4** | Census extraction — part 1 | ~half of reserves entered into the census time series; **Decision:** missing-year handling | 3–4 h |
| **5** | Census extraction — part 2 | All available reserves entered; census joined to boundaries | 3–4 h |
| **6** | Growth metrics | `03` output: `tbl_01_reserve_growth.csv` (change, %, AAGR, density) | 2–3 h |
| **7** | Growth visuals + roll-up | `04` outputs: ranking figure, regional roll-up table, animated choropleth | 3–4 h |

**At the end of Stage 1 the priority-1 track is complete and publishable on its
own.** If the project stops here, it is still a finished, worthwhile piece.

---

## Stage 2 — Connectivity (Weeks 8–12) · priority 2

| Week | Focus | Exit state (deliverable) | Est. |
|---|---|---|---|
| **8** | Covariate stack | `06` output: land cover, terrain, gHM, dist-to-road aligned to a 1 km grid | 3–4 h |
| **9** | Resistance surface | **Decision:** resistance values (numbered); `07` resistance raster | 2–3 h |
| **10** | Least-cost paths | LCPs between neighbouring reserve pairs | 3–4 h |
| **11** | Reserve network graph | `igraph` metrics: betweenness (linchpins), components (isolated reserves) | 3–4 h |
| **12** | Pinch points + visuals | Road-crossing pinch points; `fig_04` network figure; `tbl_03` metrics | 3–4 h |

---

## Stage 3 — Habitat suitability (Weeks 13–16) · priority 3

| Week | Focus | Exit state (deliverable) | Est. |
|---|---|---|---|
| **13** | Occurrence + effort | `05` outputs: cleaned occurrences, target-group background, KDE | 3–4 h |
| **14** | SDM fit | `08`: `maxnet` fitted with bias correction; model saved | 3–4 h |
| **15** | Predict + validate | National suitability surface; validation against reserves; publish-floor gate | 3–4 h |
| **16** | SDM visuals | `fig_05` suitability map with effort caveat | 2–3 h |

---

## Stage 4 — Story site and close (Weeks 17–20)

| Week | Focus | Exit state (deliverable) | Est. |
|---|---|---|---|
| **17** | Site skeleton | Quarto site structure; one page per track; navigation | 3–4 h |
| **18** | Leaflet maps | Interactive maps wired in (reuse Bay Area Leaflet recipe) | 3–4 h |
| **19** | Narrative + QC | Author-written narrative; figure alt text; accessibility pass | 3–4 h |
| **20** | Publish + docs close | Site deployed to GitHub Pages; final report; decision log closed | 3–4 h |

---

## Milestone summary

| Milestone | Target week | Meaning |
|---|---|---|
| Scaffold committed to GitHub | 0 | Version-controlled, data-free base to build on |
| Data audited and gaps closed | 2 | Know exactly what must be rebuilt |
| **Growth track complete** | 7 | Priority-1 deliverable done and publishable |
| Connectivity track complete | 12 | Priority-2 deliverable done |
| Suitability track complete | 16 | Priority-3 deliverable done |
| **Site published** | 20 | Full project live |

---

## Risk management (pace-specific)

| Risk | Likelihood | Effect | Response |
|---|---|---|---|
| All-reserve census extraction is slower than 2 weeks | High | Stage 1 slips | Extraction is the natural stop-and-resume task; split across more weeks freely |
| WII TR boundaries not public | Medium | Weaker boundary layer | KBA fallback, documented (Decision) |
| Weeks slip due to job load | High | Calendar stretches | Expected. Each week is self-contained; no penalty for a gap |
| SDM adds little beyond growth + connectivity | Medium | Wasted effort | Priority 3 by design — drop it if Stage 1–2 already tell the story |
| Scope creep to "every possible analysis" | Medium | Never finishes | Three tracks only. New ideas go to a Phase-2 future-work list |

---

## Progress tracking

Status is tracked per week in this table. Update the exit state to ✅ when the
deliverable exists.

| Week | Deliverable | Status |
|---|---|---|
| 0 | Scaffold committed + pushed to GitHub (data-free) | ⚪ Not started |
| 1 | Data audit table | ⚪ Not started |
| 2 | Boundary decision + gap downloads | ⚪ Not started |
| 3 | Reserve boundary layer | ⚪ Not started |
| 4–5 | Census time series (all reserves) | ⚪ Not started |
| 6 | Growth metrics table | ⚪ Not started |
| 7 | Growth visuals + roll-up | ⚪ Not started |
| 8–12 | Connectivity track | ⚪ Not started |
| 13–16 | Suitability track | ⚪ Not started |
| 17–20 | Site + close | ⚪ Not started |
