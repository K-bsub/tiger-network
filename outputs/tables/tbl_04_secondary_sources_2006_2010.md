# 2006/2010 reserve-level counts — secondary-source assessment (task addendum)

**Date:** 2026-09-12
**Question:** Can the Singh & Sen (2015) paper, or any other reference, supply
reserve-level 2006/2010 tiger counts to fill the gaps?

## Verdict: No clean, comparable reserve-level count set exists for 2006/2010.

The 2006/2010 NTCA rounds published population at **landscape/source-population**
scale only. Reserve-anchored figures live in report **prose** (extracted to
`census_reserve_long_2006_2010.csv`), and no secondary source improves on that.

## Sources checked

### Singh & Sen (2015) — the referenced gap-fill — DOES NOT supply values
- Reserve-level data appears only in **normalised bar charts** (Figs 9–16),
  indexed to a 0–120 (or 0–80) axis, not tiger counts. Corbett's 2014 bar (~100)
  vs its real count (215) proves the bars are indices, not numbers.
- Its only hard numbers are **landscape totals** (Fig 4: Shivalik 297/353/485,
  Central 601/601/688, W.Ghats 402/534/776, NE 100/148/201, Sundarban 0/70/76)
  and **national totals** (1411/1706/2226) — all already in the NTCA reports.
- Every figure is captioned "Source: NTCA". It re-presents NTCA data; it is not
  an independent measurement. **Useful only for directional trend statements**
  (e.g. Valmiki fell 2010, rose 2014), not for values. Confirms Decision 7's
  choice to exclude it as a numeric gap-fill.

### Peer-reviewed literature — landscape/occupancy scale, not per-reserve
- **Jhala, Qureshi & Gopal (2011, J. Appl. Ecol.)** "Can the abundance of tigers
  be assessed from their signs?" — the methods paper behind the 2010 double
  sampling. Reports **source populations at ~13,000 km² scale**, not per reserve.
- **Statewise CIL estimates (from Jhala et al. 2010)** — state-level, not reserve.
- **Gopal et al. (2010, Oryx)** "Evaluating the status of… Panna TR" — a genuine
  reserve-specific 2006 study, but reports **occupancy (29% ± SE 1)** and prey,
  in a reserve already in decline toward local extinction (~2009); not a single
  comparable abundance count.
- **Karanth et al. (2004, Anim. Conserv.)** — Panna tiger **density**, pre-2006.

### Methodological caveat found (reinforces Decision 6)
- Gopalaswamy et al. (2015) and Harihar et al. (2017, Conservation Letters)
  criticise the 2006/2010 double-sampling as unreliable and **not directly
  comparable** to the 2014+ SECR estimates (sampling/analytical changes:
  ~doubled sites, +538% trap locations 2010→2014). Independent support for
  keeping 2006/2010 out of the within-reserve SECR growth series.

## Practical outcome
- `census_reserve_long_2006_2010.csv` holds the 24 prose-derived reserve-anchored
  figures (5 high / 11 medium / 8 low attribution confidence), each tagged by
  spatial_unit. This is the best available 2006/2010 reserve-level data.
- No secondary source adds a value beyond these. Reserve-specific papers
  (Panna, etc.) can refine **individual** reserves for the 7-reserve Phase-1
  panel if needed, but do not yield an all-reserve comparable column.
