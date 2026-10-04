# =============================================================================
# 05_growth_analysis.R  [GROWTH - priority 1]
# Growth visuals and regional roll-up. Reads the per-reserve growth metrics
# built in Week 6 and makes the ranking figure, the animated choropleth, and
# the landscape-complex / state roll-up table.
#
# Input:
#   data/processed/stats_reserve_census_7755.gpkg   (Week 6 - growth metrics + geometry)
#   data/processed/boundary_states_7755.gpkg        (optional base layer)
#
# Outputs:
#   outputs/figures/fig_01_growth_ranking.png       reserve growth ranking
#   outputs/figures/fig_02_growth_animation.gif     3-frame choropleth (2014/2018/2022, Decision 6)
#   outputs/tables/tbl_02_regional_rollup.csv       roll-up to landscape complex and state
#
# Note: the census series is 2014/2018/2022 only (Decision 6), so the animation
# has 3 frames, not 5. Missing (reserve, round) cells stay NA (Decision 7).
#
# BUILT IN STAGES (project plan, Week 7):
#   [7.1] header/scope fixed; stale stub removed.                    [done]
#   [7.2] regional roll-up engine (STEP 2-3).                        [done]
#   [7.3] tbl_02 column contract + n_measured; write tbl_02 (STEP 4). [done]
#   [7.4] fig_01 growth ranking figure (STEP 5).                     [done]
#   [7.5] fig_02 animated choropleth, 3 frames (STEP 6).             [done]
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(sf)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  # gganimate + a renderer (gifski) are loaded in STEP 6 behind a guard, so the
  # rest of the script still runs if the animation toolchain is not installed.
})

source(here("R", "00_config.R"))        # CENSUS_SERIES_YEARS, LANDSCAPE_COMPLEXES, DIR_*
source(here("R", "00_functions_io.R"))  # read_vec, write_table

rule <- function(txt) cat("\n", strrep("=", 78), "\n", txt, "\n",
                          strrep("=", 78), "\n", sep = "")

# ---- Series / span constants ------------------------------------------------
SERIES_YEARS <- CENSUS_SERIES_YEARS      # 2014, 2018, 2022 (Decision 6)
END_YEAR     <- max(SERIES_YEARS)        # 2022
pop_cols     <- paste0("pop_", SERIES_YEARS)

# ---- Figure config ----------------------------------------------------------
RANK_METRIC <- "change_pct"

# Project palette (from site symbology_scheme; WCAG AA, deuteranopia-safe).
PAL_GROW    <- "#225522"   # growth (site "High growth")
PAL_DECLINE <- "#e34a33"   # decline (site Gi* hot orange-red)
PAL_FLAT    <- "#c8af64"   # no change (site gold accent)
INK         <- "#1e1e1e"
PAPER       <- "#f7f4ee"   # panel wash A (page paper)
PAPER_ALT   <- "#efe9db"   # panel wash B (one shade down; region striping)
GRID        <- "#d4cfc4"

# fig_02 population-level classes (applied identically every frame, so a colour
# means the same tiger count in all 3 years). The green ramp is the site
# sequential green. Two NON-green classes keep the three failure modes separate:
#   NO_ESTIMATE (grey)  = pop is NA that round (Decision 7 missing). NEVER green,
#                         never the lowest class - it is "we did not measure",
#                         not "few tigers".
#   ZERO (near-white)   = a REAL within-reserve 0 (Decision 9). A measured value,
#                         so it is a class on the ramp, distinct from grey.
POP_BREAKS <- c(0, 1, 21, 51, 101, 201, Inf)   # [0], 1-20, 21-50, 51-100, 101-200, >200
POP_LABELS <- c("0 (real)", "1-20", "21-50", "51-100", "101-200", ">200")
POP_RAMP   <- c("0 (real)" = "#ede8dd",   # near-white (real zero)
                "1-20"      = "#e5efd8",
                "21-50"     = "#b4c378",
                "51-100"    = "#78aa50",
                "101-200"   = "#3d7a2f",
                ">200"      = "#225522")
NO_ESTIMATE_COL <- "#b9b3a7"   # grey - NA that round (and drawn for nothing else)
STATE_FILL      <- "#e9e4d8"   # base-map states behind reserves
STATE_LINE      <- "#d4cfc4"

# Effort/detection caveat - REQUIRED on every published growth map (proposal
# success criterion). Reused across fig_01 and fig_02; wrapped at draw time.
EFFORT_CAVEAT <- paste(
  "Census figures are within-reserve SECR estimates (NTCA/WII). Apparent change",
  "partly reflects survey effort and method, not distribution alone: coverage",
  "and detection differ by round and reserve. Read rankings as indicative, not",
  "exact. Series 2014/2018/2022 (Decision 6); each reserve over its own baseline."
)

# ---- Paths ------------------------------------------------------------------
stats_path  <- file.path(DIR_PROCESSED, "stats_reserve_census_7755.gpkg")
states_path <- file.path(DIR_PROCESSED, "boundary_states_7755.gpkg")
stopifnot(file.exists(stats_path))

rollup_tbl_nn   <- 2L
rollup_tbl_slug <- "regional_rollup"

# ==============================================================================
# STEP 1 - Read the Week-6 stats layer and guard its schema
# ==============================================================================
rule("STEP 1 - read stats_reserve_census_7755.gpkg (Week-6 deliverable)")

stats_sf <- read_vec(stats_path)
cat("reserves read:", nrow(stats_sf), "\n")

if (nrow(stats_sf) != 58L) {
  stop("stats layer has ", nrow(stats_sf), " reserves; expected 58. ",
       "Check scripts/03 + scripts/04 output.", call. = FALSE)
}
if (any(duplicated(stats_sf$unit_id))) {
  stop("Duplicate unit_id in the stats layer.", call. = FALSE)
}
req_cols <- c("unit_id", "unit_name", "state", "landscape_complex",
              "baseline_year", "census_status", "geometry_present", pop_cols,
              "change_abs", "change_pct", "aagr", "growth_zero_flag")
missing_req <- setdiff(req_cols, names(stats_sf))
if (length(missing_req) > 0) {
  stop("stats layer missing required column(s): ",
       paste(missing_req, collapse = ", "),
       ". Run scripts/04 (Week 6) before the roll-up.", call. = FALSE)
}

# Keep an sf copy (for fig_02 geometry) AND a plain table (for roll-up / fig_01).
st <- st_drop_geometry(stats_sf)

for (nm in c(pop_cols, "change_abs", "change_pct", "aagr", "baseline_year")) {
  st[[nm]] <- as.numeric(st[[nm]])
}

ok_status <- c("measured", "not_estimated_post2022_notification")
bad_status <- setdiff(unique(na.omit(st$census_status)), ok_status)
if (length(bad_status) > 0) {
  stop("census_status value(s) outside the controlled set: ",
       paste(bad_status, collapse = ", "), call. = FALSE)
}

bad_lc <- setdiff(unique(na.omit(st$landscape_complex)), LANDSCAPE_COMPLEXES)
if (length(bad_lc) > 0) {
  stop("landscape_complex value(s) outside LANDSCAPE_COMPLEXES: ",
       paste(bad_lc, collapse = ", "), call. = FALSE)
}

pop_baseline <- vapply(seq_len(nrow(st)), function(i) {
  by <- st$baseline_year[i]
  if (is.na(by)) return(NA_real_)
  col <- paste0("pop_", by)
  if (!col %in% names(st)) return(NA_real_)
  as.numeric(st[[col]][i])
}, numeric(1))
st$pop_baseline <- pop_baseline
st$ratio_contributes <- !is.na(st$change_abs) & !st$growth_zero_flag

# ==============================================================================
# STEP 2 - THE ROLL-UP RULE (recorded inline; applies to both units)
# ==============================================================================
# ----------------------------------------------------------------------------
# NA-HANDLING AND RATIO RULE FOR THE REGIONAL ROLL-UP
# ----------------------------------------------------------------------------
# (1) ABSOLUTE SUMS (pop_2014/2018/2022, change_abs): sum over NON-NA reserves
#     only (na.rm = TRUE); report a SEPARATE contributing count PER FIELD, since
#     coverage differs by field. Zero non-NA contributors => NA, not 0.
# (2) RATIO METRICS (change_pct, aagr) - DO NOT AVERAGE PER-RESERVE %: sum the
#     absolute pops first, then recompute the ratio ON THE SUMS (population-
#     weighted). Numerator and denominator use the SAME contributor set
#     (ratio_contributes: valid 2-round span, non-flagged).
# (3) AAGR AT REGION LEVEL: spans differ (8 yr vs 4 yr), so annualise over the
#     pop_baseline-weighted mean span; change_pct is primary, aagr secondary.
# (4) COUNTS: n_reserves >= n_measured >= n_pop_2022 >= n_ratio.
# IMPLEMENTATION NOTE (name collision): summarise() evaluates in order, so an
#   output column must NOT reuse an input name a later expression still reads.
#   Sums are emitted under sum_* names and renamed only in STEP 4.
# ----------------------------------------------------------------------------
rule("STEP 2 - roll-up rule fixed: sum non-NA (count per field); ratio on the sums")

# ==============================================================================
# STEP 3 - Roll-up engine (one function, applied to each grouping unit)
# ==============================================================================
rule("STEP 3 - build the roll-up (population-weighted ratio on summed pops)")

rollup_by <- function(df, group_col, level_label) {
  df |>
    filter(!is.na(.data[[group_col]])) |>
    group_by(region = .data[[group_col]]) |>
    summarise(
      unit_level   = level_label,
      n_reserves   = n(),
      n_measured   = sum(census_status == "measured"),
      sum_2014     = if (all(is.na(pop_2014)))   NA_real_ else sum(pop_2014,   na.rm = TRUE),
      n_pop_2014   = sum(!is.na(pop_2014)),
      sum_2018     = if (all(is.na(pop_2018)))   NA_real_ else sum(pop_2018,   na.rm = TRUE),
      n_pop_2018   = sum(!is.na(pop_2018)),
      sum_2022     = if (all(is.na(pop_2022)))   NA_real_ else sum(pop_2022,   na.rm = TRUE),
      n_pop_2022   = sum(!is.na(pop_2022)),
      sum_chg      = if (all(is.na(change_abs))) NA_real_ else sum(change_abs, na.rm = TRUE),
      n_change_abs = sum(!is.na(change_abs)),
      n_ratio        = sum(ratio_contributes),
      pop_base_sum   = sum(pop_baseline[ratio_contributes]),
      pop_2022_rsum  = sum(pop_2022[ratio_contributes]),
      span_wsum      = sum(pop_baseline[ratio_contributes] *
                           (END_YEAR - baseline_year[ratio_contributes])),
      .groups = "drop"
    ) |>
    mutate(
      change_pct = if_else(
        n_ratio > 0 & pop_base_sum > 0,
        (pop_2022_rsum - pop_base_sum) / pop_base_sum * 100, NA_real_),
      span_region = if_else(n_ratio > 0 & pop_base_sum > 0,
                            span_wsum / pop_base_sum, NA_real_),
      aagr = if_else(
        n_ratio > 0 & pop_base_sum > 0 & span_region > 0,
        ((pop_2022_rsum / pop_base_sum)^(1 / span_region) - 1) * 100, NA_real_),
      change_pct  = round(change_pct, 1),
      aagr        = round(aagr, 1),
      span_region = round(span_region, 2)
    ) |>
    select(-pop_base_sum, -pop_2022_rsum, -span_wsum)
}

rollup_lc    <- rollup_by(st, "landscape_complex", "landscape_complex")
rollup_state <- rollup_by(st, "state",             "state")

for (nm in c("change_pct", "aagr")) {
  for (tb in list(rollup_lc, rollup_state)) {
    v <- tb[[nm]]
    if (any(is.infinite(v) | is.nan(v), na.rm = TRUE)) {
      stop("Regional ", nm, " has Inf/NaN; check the ratio guard.", call. = FALSE)
    }
  }
}
cat("no Inf/NaN in regional change_pct/aagr: OK\n")

lc_chg    <- sum(rollup_lc$sum_chg,    na.rm = TRUE)
state_chg <- sum(rollup_state$sum_chg, na.rm = TRUE)
reserve_chg <- sum(st$change_abs,      na.rm = TRUE)
cat(sprintf("change_abs total - landscape %+d | state %+d | per-reserve %+d\n",
            as.integer(lc_chg), as.integer(state_chg), as.integer(reserve_chg)))
if (round(lc_chg) != round(reserve_chg)) {
  warning("Landscape change_abs total (", lc_chg, ") != per-reserve total (",
          reserve_chg, "). A reserve may have an NA landscape_complex.")
}
if (round(state_chg) != round(reserve_chg)) {
  warning("State change_abs total (", state_chg, ") != per-reserve total (",
          reserve_chg, "). A reserve may have an NA state.")
}

lc_meas    <- sum(rollup_lc$n_measured)
state_meas <- sum(rollup_state$n_measured)
layer_meas <- sum(st$census_status == "measured")
cat(sprintf("n_measured total - landscape %d | state %d | layer 'measured' %d\n",
            lc_meas, state_meas, layer_meas))
if (lc_meas != layer_meas || state_meas != layer_meas) {
  warning("n_measured totals disagree with the layer 'measured' count (",
          layer_meas, "). A reserve may have an NA region key.")
}

# ==============================================================================
# STEP 4 - Assemble and write tbl_02
# ==============================================================================
rule("STEP 4 - write outputs/tables/tbl_02_regional_rollup.csv")

col_order <- c(
  "unit_level", "region", "n_reserves", "n_measured",
  "pop_2014", "n_pop_2014", "pop_2018", "n_pop_2018", "pop_2022", "n_pop_2022",
  "change_abs", "n_change_abs",
  "change_pct", "aagr", "span_region", "n_ratio"
)

tbl_02 <- bind_rows(rollup_lc, rollup_state) |>
  rename(pop_2014 = sum_2014, pop_2018 = sum_2018,
         pop_2022 = sum_2022, change_abs = sum_chg) |>
  arrange(unit_level, desc(change_abs)) |>
  select(all_of(col_order))

cat(sprintf("landscape rows: %d | state rows: %d | total: %d\n",
            nrow(rollup_lc), nrow(rollup_state), nrow(tbl_02)))
cat("\nlandscape complexes (population-weighted change_pct):\n")
tbl_02 |>
  filter(unit_level == "landscape_complex") |>
  arrange(desc(change_abs)) |>
  mutate(l = sprintf("   %-24s reserves %2d (measured %2d) | 2022 pop %s (n=%d) | chg %s | pct %s | aagr %s (span %s, n=%d)",
                     region, n_reserves, n_measured,
                     ifelse(is.na(pop_2022), "NA", as.character(as.integer(pop_2022))), n_pop_2022,
                     ifelse(is.na(change_abs), "NA", sprintf("%+d", as.integer(change_abs))),
                     ifelse(is.na(change_pct), "NA", sprintf("%+.1f%%", change_pct)),
                     ifelse(is.na(aagr), "NA", sprintf("%+.1f%%/yr", aagr)),
                     ifelse(is.na(span_region), "NA", as.character(span_region)), n_ratio)) |>
  pull(l) |> cat(sep = "\n")
cat("\n")

write_table(tbl_02, rollup_tbl_nn, rollup_tbl_slug)

rule("05 STAGE 7.3 done: regional roll-up (with n_measured) written to tbl_02_regional_rollup.csv.")

# ==============================================================================
# STEP 5 (7.4) - fig_01 reserve growth ranking
# ==============================================================================
rule("STEP 5 (7.4) - fig_01 reserve growth ranking (faceted by landscape)")

metric_label <- c(change_pct = "Change in tiger population (%)",
                  change_abs = "Absolute change in tigers",
                  aagr       = "Average annual growth (%/yr)")[[RANK_METRIC]]
metric_title <- c(change_pct = "% change",
                  change_abs = "absolute change",
                  aagr       = "annual growth")[[RANK_METRIC]]

plot_df <- st |>
  transmute(unit_name, landscape_complex,
            metric = .data[[RANK_METRIC]], change_abs, baseline_year,
            span_years = END_YEAR - baseline_year, is_na = is.na(.data[[RANK_METRIC]]))

ranked_df <- plot_df |> filter(!is_na)
na_df     <- plot_df |> filter(is_na)

ranked_df <- ranked_df |>
  mutate(growth_sign = case_when(metric > 0 ~ "Growing", metric < 0 ~ "Declining",
                                 TRUE ~ "No change"),
         growth_sign = factor(growth_sign, levels = c("Growing", "No change", "Declining")))

lc_present <- LANDSCAPE_COMPLEXES[LANDSCAPE_COMPLEXES %in% ranked_df$landscape_complex]

lc_pretty <- c(
  central_india_eastern = "Central India & Eastern Ghats",
  shivalik_gangetic     = "Shivalik-Gangetic (Terai Arc)",
  western_ghats         = "Western Ghats",
  northeast_hills       = "North-East Hills & Brahmaputra",
  sundarbans            = "Sundarbans")
na_per_facet <- na_df |> count(landscape_complex, name = "n_na")
facet_lab <- tibble(landscape_complex = lc_present) |>
  left_join(na_per_facet, by = "landscape_complex") |>
  mutate(n_na = tidyr::replace_na(n_na, 0L),
         label = ifelse(n_na > 0,
                        sprintf("%s  (%d not ranked)", lc_pretty[landscape_complex], n_na),
                        lc_pretty[landscape_complex]))
facet_map <- setNames(facet_lab$label, facet_lab$landscape_complex)

ranked_df <- ranked_df |>
  mutate(facet = factor(facet_map[landscape_complex], levels = facet_map[lc_present]),
         row_key = paste(landscape_complex, unit_name, sep = "___"),
         row_key = reorder(row_key, metric))

x_min <- min(0, min(ranked_df$metric, na.rm = TRUE))
x_max <- max(0, max(ranked_df$metric, na.rm = TRUE))
x_pad <- (x_max - x_min) * 0.04
stripe_df <- tibble(
  facet = factor(facet_map[lc_present], levels = facet_map[lc_present]),
  fill_band = ifelse(seq_along(lc_present) %% 2 == 1, PAPER_ALT, PAPER))

cat(sprintf("ranked reserves: %d | not-ranked (NA %s): %d\n",
            nrow(ranked_df), RANK_METRIC, nrow(na_df)))
cat("not-ranked per landscape: ",
    paste(sprintf("%s=%d", facet_lab$landscape_complex, facet_lab$n_na),
          collapse = " | "), "\n", sep = "")
dropped_lc <- setdiff(LANDSCAPE_COMPLEXES, lc_present)
if (length(dropped_lc) > 0) {
  cat("facets with 0 ranked reserves (omitted from the plot, reported here): ",
      paste(dropped_lc, collapse = ", "), "\n", sep = "")
}

theme_tiger <- theme_minimal(base_size = 11) +
  theme(
    plot.background   = element_rect(fill = PAPER, colour = NA),
    panel.background  = element_rect(fill = NA, colour = NA),
    panel.spacing     = unit(6, "pt"),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.grid.major.x = element_line(colour = GRID, linewidth = 0.3),
    strip.text        = element_text(face = "bold", hjust = 0, colour = INK, size = 10,
                                     margin = margin(t = 4, b = 3)),
    axis.text.y       = element_text(colour = INK, size = 7),
    axis.text.x       = element_text(colour = INK),
    axis.title        = element_text(colour = INK),
    plot.title        = element_text(face = "bold", colour = INK, size = 15),
    plot.subtitle     = element_text(colour = INK, size = 10),
    plot.caption      = element_text(colour = INK, size = 7.5, hjust = 0, lineheight = 1.15),
    plot.caption.position = "plot",
    plot.title.position   = "plot",
    legend.position   = "top",
    legend.title      = element_blank(),
    legend.text       = element_text(colour = INK))

sign_pal <- c(Growing = PAL_GROW, `No change` = PAL_FLAT, Declining = PAL_DECLINE)
y_labeller <- function(x) sub("^.*___", "", x)
caption_txt <- paste(strwrap(paste0("Caveat: ", EFFORT_CAVEAT), width = 120),
                     collapse = "\n")

p1 <- ggplot(ranked_df, aes(x = metric, y = row_key)) +
  geom_rect(data = stripe_df, inherit.aes = FALSE,
            aes(xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf, fill = I(fill_band))) +
  geom_col(aes(fill = growth_sign), width = 0.72) +
  geom_vline(xintercept = 0, colour = INK, linewidth = 0.4) +
  facet_wrap(vars(facet), ncol = 1, scales = "free_y", strip.position = "top") +
  scale_fill_manual(values = sign_pal, drop = FALSE, name = NULL) +
  scale_y_discrete(labels = y_labeller) +
  scale_x_continuous(limits = c(x_min - x_pad, x_max + x_pad)) +
  labs(title = "India's tiger reserves ranked by population change",
       subtitle = sprintf("Within-reserve %s over each reserve's own baseline to 2022 (SECR estimates, NTCA/WII)", metric_title),
       x = metric_label, y = NULL, caption = caption_txt) +
  theme_tiger

n_bars   <- nrow(ranked_df)
n_facets <- length(lc_present)
fig_h_in <- max(6, 1.4 + n_bars * 0.19 + n_facets * 0.25)
fig_w_in <- 9

if (!dir.exists(DIR_FIGURES)) dir.create(DIR_FIGURES, recursive = TRUE)
fig1_path <- file.path(DIR_FIGURES, "fig_01_growth_ranking.png")
ggsave(fig1_path, plot = p1, width = fig_w_in, height = fig_h_in,
       dpi = 200, bg = PAPER, limitsize = FALSE)
cat("Wrote ", fig1_path, sprintf(" (%.1f x %.1f in, %d bars, %d facets)\n",
                                  fig_w_in, fig_h_in, n_bars, n_facets), sep = "")

rule("05 STAGE 7.4 done: fig_01_growth_ranking.png written (effort caveat in caption).")

# ==============================================================================
# STEP 6 (7.5) - fig_02 animated choropleth (3 frames: 2014/2018/2022)
# ==============================================================================
rule("STEP 6 (7.5) - fig_02 animated choropleth: per-round population level")

# WHAT THIS SHOWS:
#   One map per census round (3 frames). Each reserve polygon is filled by that
#   round's within-reserve tiger COUNT (pop_<year>), binned with FIXED breaks so
#   a colour means the same count in every frame. Watching a reserve darken over
#   the 3 frames reads its growth; that is the "growth category across rounds".
#
# THE THREE FAILURE MODES, KEPT VISUALLY DISTINCT (task 7.5 core requirement):
#   1. GEOMETRY-ABSENT (Pilibhit, Dholpur-Karauli; Amrabad too before the
#      Decision-17 split, 2026-10-02): geometry_present is
#      FALSE and the geometry is empty. They CANNOT be a polygon, so they are
#      dropped from the drawn layer and named in a fixed on-figure note. They are
#      NEVER shown as 0 or as a coloured shape.
#   2. NA POP THAT ROUND (Decision 7 missing, e.g. Sundarbans 2022, a late-entry
#      reserve before its baseline): drawn in a distinct GREY "No estimate"
#      class. NEVER the lowest green.
#   3. REAL ZERO (Decision 9): a measured 0 is a valid low value -> its own
#      near-white "0 (real)" class on the ramp, distinct from the grey.
#   The bin function below encodes exactly this: NA -> "No estimate"; a real 0
#   falls in the [0,1) bin "0 (real)"; everything else on the green ramp.

# --- 6a. Guard the animation toolchain --------------------------------------
have_anim  <- requireNamespace("gganimate", quietly = TRUE)
have_gif   <- requireNamespace("gifski",    quietly = TRUE)
fig2_gif   <- file.path(DIR_FIGURES, "fig_02_growth_animation.gif")

# --- 6b. Reserves with geometry, long over the 3 rounds ---------------------
# geometry_present flag AND a non-empty geometry (belt and braces: a FALSE flag
# should already mean empty, but st_is_empty() catches any that slipped through).
absent_sf <- stats_sf |> filter(!geometry_present | st_is_empty(stats_sf))
map_sf    <- stats_sf |> filter(geometry_present & !st_is_empty(stats_sf))

absent_names <- sort(absent_sf$unit_name)
cat(sprintf("reserves with geometry: %d | geometry-absent (not mapped): %d\n",
            nrow(map_sf), nrow(absent_sf)))
cat("geometry-absent (named on the figure, never drawn as 0): ",
    paste(absent_names, collapse = ", "), "\n", sep = "")

# Long form: one row per (reserve, year). st keeps geometry (pivot on a plain
# frame, then rejoin geometry by unit_id to avoid pivoting the sfc column).
map_long <- map_sf |>
  st_drop_geometry() |>
  select(unit_id, unit_name, all_of(pop_cols)) |>
  pivot_longer(all_of(pop_cols), names_to = "year", values_to = "pop",
               names_transform = list(year = \(x) as.integer(sub("pop_", "", x))))

# Bin: NA -> "No estimate"; real 0 -> "0 (real)"; else the green ramp bin.
bin_pop <- function(x) {
  lab <- cut(x, breaks = POP_BREAKS, labels = POP_LABELS,
             right = FALSE, include.lowest = TRUE)   # [0,1)="0 (real)", etc.
  lab <- as.character(lab)
  lab[is.na(x)] <- "No estimate"                     # NA overrides (never a bin)
  factor(lab, levels = c(POP_LABELS, "No estimate"))
}
map_long$pop_class <- bin_pop(map_long$pop)

# Sanity: a real 0 must land in "0 (real)", NOT "No estimate".
zero_rows <- which(!is.na(map_long$pop) & map_long$pop == 0)
if (length(zero_rows) > 0 &&
    any(map_long$pop_class[zero_rows] != "0 (real)")) {
  stop("A real within-reserve 0 was not binned as '0 (real)'. Check POP_BREAKS.",
       call. = FALSE)
}
# Report the per-frame class spread so the NA/zero split is auditable.
cat("\nper-frame class counts (reserves with geometry):\n")
map_long |>
  count(year, pop_class) |>
  tidyr::pivot_wider(names_from = year, values_from = n, values_fill = 0) |>
  as.data.frame() |> print(row.names = FALSE)
cat("\n")

# Rejoin geometry (by unit_id) so each (reserve, year) row is an sf feature.
geom_only <- map_sf |> select(unit_id)
map_frames_sf <- geom_only |>
  right_join(map_long, by = "unit_id") |>
  st_as_sf()

# --- 6c. Optional states base layer -----------------------------------------
states_sf <- NULL
if (file.exists(states_path)) {
  states_sf <- tryCatch(read_vec(states_path), error = function(e) NULL)
}
if (is.null(states_sf)) {
  cat("note: boundary_states_7755.gpkg not found - drawing reserves without a state base.\n")
}

# --- 6d. Fill scale: ramp + grey, both always in the legend -----------------
fill_values <- c(POP_RAMP, "No estimate" = NO_ESTIMATE_COL)
fill_breaks <- c(POP_LABELS, "No estimate")

absent_note <- if (nrow(absent_sf) > 0) {
  paste0("Not mapped (no boundary polygon): ", paste(absent_names, collapse = ", "),
         ". Shown here for completeness, not as zero.")
} else {
  "All reserves have mapped geometry."
}

cap2 <- paste(strwrap(paste0("Caveat: ", EFFORT_CAVEAT, "  ", absent_note),
                      width = 110), collapse = "\n")

theme_map <- theme_void(base_size = 11) +
  theme(
    plot.background  = element_rect(fill = PAPER, colour = NA),
    panel.background = element_rect(fill = PAPER, colour = NA),
    plot.title       = element_text(face = "bold", colour = INK, size = 15),
    plot.subtitle    = element_text(colour = INK, size = 11),
    plot.caption     = element_text(colour = INK, size = 7.5, hjust = 0, lineheight = 1.15),
    plot.caption.position = "plot",
    plot.title.position   = "plot",
    legend.title     = element_text(colour = INK, size = 9),
    legend.text      = element_text(colour = INK, size = 8),
    legend.position  = "right")

build_base <- function() {
  g <- ggplot()
  if (!is.null(states_sf)) {
    g <- g + geom_sf(data = states_sf, fill = STATE_FILL, colour = STATE_LINE,
                     linewidth = 0.2)
  }
  g
}

# --- 6e. Animate, or fall back to 3 static frames ---------------------------
if (have_anim && have_gif) {
  suppressPackageStartupMessages(library(gganimate))
  # transition_manual: shows each census round as a DISCRETE frame. It does NOT
  # tween between states, so geom_sf geometry is never interpolated and the
  # polygons stay perfectly fixed - only the fill changes round to round. (An
  # earlier transition_states + ease_aes build morphed the vertices between
  # frames, making reserves appear to move; that is wrong for a fixed-geometry
  # choropleth.) 3 rounds -> 3 held frames.
  anim <- build_base() +
    geom_sf(data = map_frames_sf, aes(fill = pop_class), colour = INK, linewidth = 0.12) +
    scale_fill_manual(values = fill_values, breaks = fill_breaks, drop = FALSE,
                      name = "Tigers within\nreserve", na.value = NO_ESTIMATE_COL) +
    labs(title = "Tiger population by reserve, 2014-2022",
         subtitle = "Census round: {current_frame}   (within-reserve SECR estimate, NTCA/WII)",
         caption = cap2) +
    theme_map +
    gganimate::transition_manual(year)

  cat("rendering 3-frame animation (gifski)...\n")
  # One image per census round, each held ~1.7 s (fps below). No tween frames.
  gganimate::anim_save(
    fig2_gif,
    animation = gganimate::animate(
      anim, nframes = length(SERIES_YEARS), fps = 0.6,
      width = 1400, height = 1500, res = 150,
      renderer = gganimate::gifski_renderer(loop = TRUE), bg = PAPER))
  cat("Wrote ", fig2_gif, "\n", sep = "")
  rule("05 STAGE 7.5 done: fig_02_growth_animation.gif written (fixed polygons; NA/absent visibly distinct).")

} else {
  # Fallback: no gganimate/gifski. Write one static PNG per round so the
  # deliverable is not lost, and tell the user exactly what to install.
  warning("gganimate/gifski not available (gganimate=", have_anim,
          ", gifski=", have_gif, "). Writing 3 static frames instead of the GIF.")
  for (yr in SERIES_YEARS) {
    fr <- map_frames_sf |> filter(year == yr)
    g <- build_base() +
      geom_sf(data = fr, aes(fill = pop_class), colour = INK, linewidth = 0.12) +
      scale_fill_manual(values = fill_values, breaks = fill_breaks, drop = FALSE,
                        name = "Tigers within\nreserve", na.value = NO_ESTIMATE_COL) +
      labs(title = "Tiger population by reserve",
           subtitle = sprintf("Census round: %d   (within-reserve SECR estimate, NTCA/WII)", yr),
           caption = cap2) +
      theme_map
    fr_path <- file.path(DIR_FIGURES, sprintf("fig_02_frame_%d.png", yr))
    ggsave(fr_path, plot = g, width = 9, height = 9.6, dpi = 200, bg = PAPER)
    cat("Wrote ", fr_path, "\n", sep = "")
  }
  cat("To produce the GIF, install.packages(c('gganimate','gifski')) and re-run.\n")
  rule("05 STAGE 7.5 (fallback): 3 static frames written; install gganimate+gifski for the GIF.")
}

# ==============================================================================
# STEP 7 (7.6) - VERIFICATION BLOCK (hard-stops on any failure)
# ==============================================================================
# This block does not compute anything new. It asserts the four properties task
# 7.6 requires, against the objects built above, and stop()s on the first
# failure so a broken run cannot pass silently. Each check prints OK on success.
rule("STEP 7 (7.6) - verification: reconcile roll-up, frames=3, NA-not-0, flag-not-decline")

verify_fail <- character(0)
check <- function(cond, msg) {
  if (isTRUE(cond)) { cat("  OK  ", msg, "\n", sep = "")
  } else { cat("  FAIL", msg, "\n", sep = ""); verify_fail <<- c(verify_fail, msg) }
}

# --- 7.6a. Roll-up sums reconcile to the per-reserve table -------------------
# For each pop round and change_abs: the landscape roll-up total AND the state
# roll-up total must each equal the per-reserve na.rm sum. (Both groupings drop
# only NA-region rows; every reserve has a state and a landscape, so all three
# must agree.) tbl_02 is long with a unit_level column - split it to sum.
tbl_lc    <- tbl_02 |> filter(unit_level == "landscape_complex")
tbl_state <- tbl_02 |> filter(unit_level == "state")

for (col in c("pop_2014", "pop_2018", "pop_2022", "change_abs")) {
  per_reserve <- sum(st[[col]], na.rm = TRUE)
  lc_sum      <- sum(tbl_lc[[col]],    na.rm = TRUE)
  state_sum   <- sum(tbl_state[[col]], na.rm = TRUE)
  check(round(lc_sum) == round(per_reserve) && round(state_sum) == round(per_reserve),
        sprintf("%s reconciles: landscape %s | state %s | per-reserve %s",
                col, format(round(lc_sum)), format(round(state_sum)),
                format(round(per_reserve))))
}

# n_measured reconciles to the layer 'measured' count, via both groupings.
check(sum(tbl_lc$n_measured) == sum(st$census_status == "measured") &&
      sum(tbl_state$n_measured) == sum(st$census_status == "measured"),
      sprintf("n_measured reconciles to layer 'measured' (%d)",
              sum(st$census_status == "measured")))

# --- 7.6b. Frame count is exactly 3, and the years are the Decision-6 series --
frame_years <- sort(unique(map_frames_sf$year))
check(length(frame_years) == 3L,
      sprintf("frame count = 3 (got %d: %s)", length(frame_years),
              paste(frame_years, collapse = "/")))
check(identical(as.integer(frame_years), as.integer(SERIES_YEARS)),
      sprintf("frame years are the Decision-6 series 2014/2018/2022 (got %s)",
              paste(frame_years, collapse = "/")))

# --- 7.6c. No reserve rendered as 0 where it is actually NA ------------------
# Every NA-pop (reserve, round) MUST carry pop_class 'No estimate' (grey), never
# a numeric bin. And every '0 (real)' row MUST be a real measured 0, never NA.
na_rows        <- map_frames_sf$pop_class[is.na(map_frames_sf$pop)]
na_all_grey    <- length(na_rows) == 0L || all(na_rows == "No estimate")
check(na_all_grey,
      sprintf("all NA-pop cells are 'No estimate' (never a number): %d NA cells",
              sum(is.na(map_frames_sf$pop))))

zero_class_rows <- map_frames_sf$pop[map_frames_sf$pop_class == "0 (real)"]
zero_all_real   <- length(zero_class_rows) == 0L ||
                   all(!is.na(zero_class_rows) & zero_class_rows == 0)
check(zero_all_real,
      sprintf("all '0 (real)' cells are a measured 0 (never NA): %d such cells",
              sum(map_frames_sf$pop_class == "0 (real)")))

# The inverse direction too: no 'No estimate' cell has a non-NA pop.
grey_pop <- map_frames_sf$pop[map_frames_sf$pop_class == "No estimate"]
check(length(grey_pop) == 0L || all(is.na(grey_pop)),
      "no 'No estimate' cell carries a real number")

# --- 7.6d. The growth_zero_flag reserve is not shown as a decline ------------
# Decision 9: a zero-baseline reserve (Mukundara) has change_pct/aagr = NA, so it
# must be EXCLUDED from the fig_01 ranked bars (it is in na_df), and therefore
# never gets a 'Declining' fill. change_abs there is +1 (a rise), so mislabelling
# it a decline would be doubly wrong.
flagged <- st$unit_name[st$growth_zero_flag]
if (length(flagged) == 0L) {
  cat("  note  no growth_zero_flag reserve in this build - check skipped\n")
} else {
  in_ranked   <- flagged %in% as.character(ranked_df$unit_name)
  in_na       <- flagged %in% as.character(na_df$unit_name)
  check(!any(in_ranked),
        sprintf("flagged reserve(s) absent from ranked bars: %s",
                paste(flagged, collapse = ", ")))
  check(all(in_na),
        sprintf("flagged reserve(s) shown separately as not-ranked: %s",
                paste(flagged, collapse = ", ")))
  # And explicitly: change_abs is not negative for the flagged reserve.
  fl_chg <- st$change_abs[st$growth_zero_flag]
  check(all(is.na(fl_chg) | fl_chg >= 0),
        sprintf("flagged reserve(s) change_abs is not a decline (%s)",
                paste(ifelse(is.na(fl_chg), "NA", sprintf("%+d", as.integer(fl_chg))),
                      collapse = ", ")))
}

# --- 7.6e. Verdict ----------------------------------------------------------
if (length(verify_fail) > 0) {
  stop("7.6 verification FAILED (", length(verify_fail), " check(s)):\n  - ",
       paste(verify_fail, collapse = "\n  - "), call. = FALSE)
}
rule("05 STAGE 7.6 done: all verification checks passed.")
