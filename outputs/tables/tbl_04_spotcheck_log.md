# Census extraction — spot-check log (task 4.5)

**Date:** 2026-09-12
**Checked file:** `census_reserve_long.csv` (147 measured rows, 53 reserves, rounds 2014/2018/2022)
**Second sources:** NTCA/PIB 2022 government release (pib.gov.in PRID 1943922); multiple 2022 reserve-list compilations; each report's own totals.

## Result: PASS — 0 unresolved discrepancies

### 1. 2022 within-reserve values vs PIB government release — 17/17 exact
Corbett 260, Bandipur 150, Nagarhole 141, Bandhavgarh 135, Dudhwa 135,
Mudumalai 114, Kanha 105, Kaziranga 104, Tadoba 97, Sathyamangalam 85,
Pench-MP 77, Ranthambore 57 — all match.
Five reported-zero reserves (Dampa, Kamlang, Kawal, Satkosia, Sahyadri) — all match 0.

### 2. 2014 column vs report's own Table 2.2 Total — exact
Sum of all 44 reserve midpoints = **1586** = printed Table 2.2 "Total" (1586). Full-column validation.

### 3. 2018 within-reserve sum vs report text — expected +35 difference (NOT an error)
Sum of 50 within-reserve figures = **1958** vs the report's stated "population within Tiger Reserves is 1,923".
The report's 1,923 is after removing double-counts between abutting reserves (it names Bandipur/Mudumalai/
Sathyamangalam and Pench-MP/Pench-MH as shared-tiger cases). A per-reserve sum legitimately keeps each
reserve's own figure, so a small positive difference is expected. Logged, not corrected.

### 4. State-total direction check (2022) — all consistent
Within-reserve sums are below published state totals (which include tigers outside reserves), as they must be:
MP 438 ≤ 785, Karnataka 373 ≤ 563, Uttarakhand 314 ≤ 560, Maharashtra 222 ≤ 444.

## Flags carried forward (not discrepancies)
- **Implausibly precise SE in 2018/2022** (e.g. Corbett 260±0.4, Navegaon 6±0.003). Transcribed verbatim from
  the source; the reports print these. Treat SE as indicative only in any weighting.
- **Sundarban 2022 within-reserve is blank** in Table I.3.3 (only the biosphere-level 101±10 "utilising" is given).
  Stored as NA-within with a note; 2018 within (88) and 2014 (68) are available if a 2022 within value is needed.
- **17 scat-DNA minimums** across rounds have no SE (genetic minimum counts). Flagged in `notes`.

---

## Second pass — prose search of 2014/2022 for table-missing reserves (2026-09-12)

Checked whether reserves absent from each round's master table have a figure in
that report's prose/chapters (the same pattern that applies to 2006/2010).

**2014 (14 reserves missing from Table 2.2):**
- **Orang** — has its own tiger chapter (was a National Park in 2014): 15 unique
  captured, density 10.55 (SE 2.82)/100 km² over 47 km². Added as a
  **supplementary** row (NP survey figure, not within-reserve abundance;
  excluded from the growth series). Orang was folded into the Kaziranga
  landscape source (~163 tigers).
- **Mukundara** — chapter states it "does not have tigers" in 2014 (CMR table is
  leopard-only). Added as a real **within-reserve 0** (now has a 0→1→1
  trajectory).
- **Kawal** — surveyed, but the CMR table is leopard-only; no tiger estimate.
- **Rajaji** — 2014 prose only: "two tigresses since 2006" (Western Rajaji near
  local extinction); no table figure. First table figure is 2018.
- Amrabad (0 mentions), Guru Ghasidas (NP, part of Sanjay-Bandhavgarh block),
  and the post-2014 notifications — no own figure.

**2018 (8 missing):** all post-2018 notifications or NP/WLS mentions only. The
"141 (126–156)" near Guru Ghasidas is the Sanjay-Bandhavgarh block, not the NP.
**No new reserve-level figures.**

**2022 (5 missing):**
- **Ratapani** — chapter gives 56 individuals, density 2.30 (SE 0.31)/100 km²,
  but as **Ratapani WLS / Bhopal-Ratapani complex** (a sanctuary in 2022; TR
  notified Dec 2024). Added as a **supplementary** row (complex figure, larger
  than the later reserve; excluded from the series).
- Guru Ghasidas, Durgavati, Madhav, Dholpur — no own figure (post-2022 or NP).

**Correction made:** Ranipur 2022 was mis-noted as scat-DNA; it is a
camera-capture count (4 unique captured, Table V.1.18, density not estimated).
Note and `figure_type` fixed.

**Net effect on the series:** +1 within-reserve row (Mukundara 2014 = 0);
2 supplementary rows recorded but segregated (`census_status =
measured_prose_supplementary`, non-within `spatial_unit`) so they never enter
growth metrics.
