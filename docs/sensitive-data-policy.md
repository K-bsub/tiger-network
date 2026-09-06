# Sensitive Data Policy

**Status:** Active — applies from Week 1 onward
**Applies to:** all branches and all published outputs

---

## 1. Why this document exists

Precise location data for tigers carries a poaching and disturbance risk, as it
does for any large cat. The risk here is **lower than for pumas** in the Bay Area
project, for two reasons: the analysis is at reserve scale (not sub-reserve), and
tiger reserves are already public, mapped places. But GBIF still holds some
precise occurrence points, and this repository is public and permanent. A
lightweight guard is therefore kept, adapted from the Bay Area policy.

This project is public. Anything committed or rendered to the site is
permanently public. Treat every commit as irreversible.

---

## 2. Data sensitivity tiers

| Tier | Definition | Examples | Handling |
|---|---|---|---|
| **T0 — Open** | Public, no location risk | Reserve boundaries, roads, land cover, DEM, census tables | Normal use |
| **T1 — Open, coarse** | Public but already obscured at source | iNaturalist tiger records (obscured), GBIF records with high `coordinateUncertaintyInMeters` | Normal use; document the obscuring |
| **T2 — Sensitive** | Precise unobscured locations of a sensitive species | Any precise tiger detection at sub-reserve precision | Not published at native precision |

There is no T3 (partner data) in this project — it uses public open data only.
If partner or telemetry data is taken up in a future phase, add a T3 tier and a
written agreement, following the Bay Area policy §4.

---

## 3. Hard rules

- [ ] **Published continuous surfaces are generalised to ≥1 km.** This covers SDM
      suitability, KDE, and resistance rasters. Enforced in code by
      `assert_publishable_rast()`.
- [ ] **Published occurrence products are aggregated**, never raw points — to
      reserve level or grid cell. Enforced by `assert_no_raw_points()`.
- [ ] **No precise coordinates in any figure, table, caption, popup, or commit
      message.**
- [ ] **Watch small-n.** A reserve or cell with very few underlying records can
      reverse-narrow a location. `warn_small_n()` flags these; suppress or
      coarsen before publishing.
- [ ] **Check before every commit** that nothing under `data/restricted/` is
      staged: `git status --short`.

Bobcat-style finer publication is allowed for tigers at reserve scale, because
reserve boundaries are public. The publish floor still applies to any
sub-reserve continuous surface.

---

## 4. Accidental disclosure

If precise sensitive data is committed:

1. Do not simply delete it in a new commit — the history retains it.
2. Rewrite history (`git filter-repo`) or, if the repository is small and young,
   delete and recreate it.
3. Force-push, then confirm the data is gone from all branches and any fork.
4. Log the incident and the remediation in `docs/methodology.md`.
