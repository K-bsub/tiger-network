# =============================================================================
# 00c_verify_wdpa_boundaries.R
# Week 2, task 2.1 — verification check for the boundary-source Decision.
# One-off diagnostic. Runs after 00b, before 01. Not a pipeline stage.
#
# PURPOSE
# You cannot run this from the assistant sandbox (protectedplanet.net is not on
# the network allow-list). Run it LOCALLY, against the real WDPA India extract,
# to turn the boundary Decision from "on paper" into "checked".
#
# WHAT IT ANSWERS
#   1. COVERAGE: how many of the 58 official tiger reserves can be located in
#      WDPA, matched BY NAME across the Tiger Reserve / National Park / Wildlife
#      Sanctuary designations? (Many TRs sit in WDPA under their core National
#      Park or Sanctuary polygon, NOT under "Tiger Reserve" — a designation-only
#      filter under-counts. A name match across all three designations is the
#      honest test.)
#   2. AREA BASIS: for the reserves that match, does the WDPA geometry area
#      agree with the official NTCA legal TR area? Large positive = buffer-
#      inflated or wrong polygon (the Phase 1 KBA/Corbett failure); large
#      negative = core-only polygon (the likely NP-only case).
#
# HOW TO GET THE DATA (manual, one time — see docs/data-sources.md)
#   https://www.protectedplanet.net/country/IND  ->  "Download" (top right)
#   -> choose File Geodatabase (.gdb) -> accept terms -> unzip.
#   The country extract ships as a .gdb with polygon + point layers, OR as
#   shapefiles split into _0/_1/_2 (the 2 GB shapefile limit). Prefer the .gdb.
#   Place it at:  data/raw/wdpa/WDPA_WDOECM_<Mon><Year>_Public_IND.gdb
#
# This is a READ-ONLY diagnostic. It writes two CSVs to outputs/tables/ and
# prints a verdict. It stages nothing for the pipeline.
# =============================================================================

suppressPackageStartupMessages({
  library(here)
  library(sf)
  library(dplyr)
  library(stringr)
  library(readr)
  library(tidyr)
})

# ---- Config ----------------------------------------------------------------
# EDIT this to point at your unzipped WDPA India extract (.gdb folder preferred).
WDPA_PATH  <- here("data", "raw", "wdpa", "WDPA_WDOECM_Sep2026_Public_IND.gdb")

# Layer inside the .gdb that holds polygons. Leave NA to auto-pick; the script
# prints all layers so you can set it explicitly if the guess is wrong.
WDPA_LAYER <- NA_character_

# Designations to search. A TR can appear in WDPA under any of these.
TARGET_DESIGS <- c("tiger reserve", "national park", "wildlife sanctuary")

CURRENT_TR_COUNT <- 58L   # India, 2025 (Madhav is the 58th)

# ---- Reference: all 58 official tiger reserves -----------------------------
# Name + official legal TOTAL area (core + buffer, km2) + state.
# Source: NTCA / AITE 2022, via the Tiger reserves of India summary table.
# alt is a pipe-separated list of spelling / naming variants WDPA is known to
# use (or the constituent NP / sanctuary name a TR sits under in WDPA).
tr_ref <- tibble::tribble(
  ~name,                        ~state,             ~ntca_total_km2, ~alt,
  "Bandipur",                   "Karnataka",         1456.30,  "",
  "Corbett",                    "Uttarakhand",       1288.31,  "jim corbett|ramganga",
  "Kanha",                      "Madhya Pradesh",    2051.79,  "",
  "Manas",                      "Assam",             2837.10,  "",
  "Melghat",                    "Maharashtra",       2768.52,  "",
  "Palamau",                    "Jharkhand",         1129.93,  "palamu",
  "Ranthambore",                "Rajasthan",         1411.29,  "ranthambhore",
  "Similipal",                  "Odisha",            2750.00,  "simlipal",
  "Sunderbans",                 "West Bengal",       2584.89,  "sundarban|sundarbans",
  "Periyar",                    "Kerala",             925.00,  "",
  "Sariska",                    "Rajasthan",         1213.34,  "",
  "Buxa",                       "West Bengal",        757.90,  "",
  "Indravati",                  "Chhattisgarh",      2799.07,  "",
  "Namdapha",                   "Arunachal Pradesh", 2052.82,  "",
  "Nagarjunsagar-Srisailam",    "Andhra Pradesh",    3296.31,  "nagarjunsagar|srisailam|nagarjunasagar",
  "Dudhwa",                     "Uttar Pradesh",     2201.77,  "",
  "Kalakad-Mundanthurai",       "Tamil Nadu",        1601.54,  "kalakkad|mundanthurai",
  "Valmiki",                    "Bihar",              899.38,  "",
  "Pench (M.P.)",               "Madhya Pradesh",    1179.63,  "pench madhya|pench mp",
  "Tadoba-Andhari",             "Maharashtra",       1727.59,  "tadoba|andhari",
  "Bandhavgarh",                "Madhya Pradesh",    1536.93,  "",
  "Panna",                      "Madhya Pradesh",    1598.10,  "",
  "Dampa",                      "Mizoram",            988.00,  "",
  "Bhadra",                     "Karnataka",         1064.29,  "",
  "Pench (MH)",                 "Maharashtra",        741.22,  "pench maharashtra",
  "Pakke",                      "Arunachal Pradesh", 1198.45,  "pakhui",
  "Nameri",                     "Assam",              464.00,  "",
  "Satpura",                    "Madhya Pradesh",    2133.31,  "",
  "Anamalai",                   "Tamil Nadu",        1479.87,  "indira gandhi|annamalai",
  "Udanti-Sitanadi",            "Chhattisgarh",      1842.54,  "udanti|sitanadi",
  "Satkosia",                   "Odisha",             963.87,  "",
  "Kaziranga",                  "Assam",             1173.58,  "",
  "Achanakmar",                 "Chhattisgarh",       914.02,  "",
  "Kali",                       "Karnataka",         1097.51,  "anshi|dandeli|anshi dandeli",
  "Sanjay Dhubri",              "Madhya Pradesh",    1674.50,  "sanjay|dubri|sanjay dubri",
  "Mudumalai",                  "Tamil Nadu",         688.59,  "",
  "Nagarhole",                  "Karnataka",         1205.76,  "nagarahole|rajiv gandhi",
  "Parambikulam",               "Kerala",             643.66,  "",
  "Sahyadri",                   "Maharashtra",       1165.57,  "chandoli|koyna",
  "Biligiri Ranganatha Temple", "Karnataka",          574.82,  "brt|biligiri|biligiriranganatha",
  "Kawal",                      "Telangana",         2015.44,  "",
  "Sathyamangalam",             "Tamil Nadu",        1408.40,  "sathya|satyamangalam",
  "Mukandra Hills",             "Rajasthan",          759.99,  "mukundra|mukandra",
  "Nawegaon-Nagzira",           "Maharashtra",       1894.94,  "nawegaon|nagzira|navegaon",
  "Amrabad",                    "Telangana",         2611.39,  "amrabad",
  "Pilibhit",                   "Uttar Pradesh",      730.25,  "",
  "Bor",                        "Maharashtra",        816.27,  "",
  "Rajaji",                     "Uttarakhand",       1075.17,  "",
  "Orang",                      "Assam",              492.46,  "",
  "Kamlang",                    "Arunachal Pradesh",  783.00,  "",
  "Srivilliputhur-Megamalai",   "Tamil Nadu",        1016.57,  "srivilliputhur|megamalai|meghamalai",
  "Ramgarh Vishdhari",          "Rajasthan",         1501.90,  "ramgarh",
  "Ranipur",                    "Uttar Pradesh",      529.36,  "",
  "Veerangana Durgavati",       "Madhya Pradesh",    2339.12,  "durgavati|nauradehi|rani durgavati",
  "Dholpur-Karauli",            "Rajasthan",          599.64,  "dholpur|karauli",
  "Guru Ghasidas-Tamor Pingla", "Chhattisgarh",      2829.38,  "guru ghasidas|tamor pingla",
  "Ratapani",                   "Madhya Pradesh",    1271.47,  "",
  "Madhav",                     "Madhya Pradesh",    1751.00,  ""
)

stopifnot(nrow(tr_ref) == CURRENT_TR_COUNT)

# ---- Load WDPA -------------------------------------------------------------
if (!file.exists(WDPA_PATH) && !dir.exists(WDPA_PATH)) {
  stop("WDPA extract not found at:\n  ", WDPA_PATH,
       "\nDownload it from https://www.protectedplanet.net/country/IND first.",
       call. = FALSE)
}

if (grepl("\\.gdb$", WDPA_PATH)) {
  cat("Layers in the geodatabase:\n")
  print(sf::st_layers(WDPA_PATH))
  if (is.na(WDPA_LAYER)) {
    lyrs  <- sf::st_layers(WDPA_PATH)$name
    guess <- lyrs[str_detect(lyrs, regex("poly|_0$", ignore_case = TRUE))]
    WDPA_LAYER <- if (length(guess) >= 1) guess[1] else lyrs[1]
    message("Auto-picked layer: ", WDPA_LAYER,
            " (set WDPA_LAYER manually if this is wrong).")
  }
  wdpa <- sf::st_read(WDPA_PATH, layer = WDPA_LAYER, quiet = TRUE)
} else {
  wdpa <- sf::st_read(WDPA_PATH, quiet = TRUE)
}

stopifnot(all(c("DESIG_ENG", "NAME") %in% names(wdpa)))

# ---- Prepare WDPA candidate polygons ---------------------------------------
# Keep only the three target designations, compute geometry area in EPSG:7755.
norm <- function(x) str_squish(str_to_lower(x))

wdpa_cand <- wdpa |>
  mutate(desig = norm(DESIG_ENG)) |>
  filter(desig %in% TARGET_DESIGS) |>
  st_transform(7755) |>
  mutate(
    wdpa_name     = str_squish(NAME),
    wdpa_key      = str_replace_all(norm(NAME), "[^a-z ]", ""),
    rep_area_km2  = if ("REP_AREA" %in% names(wdpa)) REP_AREA else NA_real_,
    geom_area_km2 = round(as.numeric(st_area(geometry)) / 1e6, 1)
  ) |>
  st_drop_geometry() |>
  select(wdpa_name, wdpa_key, desig, rep_area_km2, geom_area_km2)

cat("\n==================== WDPA CANDIDATE POOL ====================\n")
cat("WDPA polygons in the 3 target designations:\n")
wdpa_cand |> count(desig) |> as.data.frame() |> print(row.names = FALSE)

# ---- Name match: each of the 58 TRs -> best WDPA candidate -----------------
# For each reference reserve, build a set of match tokens (main name words +
# alt spellings), find WDPA candidates whose key contains any token, and pick
# the candidate whose area is closest to the official total (helps when a name
# matches several parcels).
tokenise <- function(name, alt) {
  base <- str_replace_all(norm(name), "[^a-z ]", " ")
  base <- str_split(base, "\\s+")[[1]]
  base <- base[nchar(base) >= 4]                 # drop tiny stopword-ish tokens
  alts <- if (nchar(alt) > 0) str_split(norm(alt), "\\|")[[1]] else character(0)
  unique(c(base, str_squish(alts)))
}

match_one <- function(name, alt, ntca_total_km2) {
  toks <- tokenise(name, alt)
  if (length(toks) == 0)
    return(tibble(matched = FALSE, wdpa_name = NA_character_, desig = NA_character_,
                  geom_area_km2 = NA_real_, rep_area_km2 = NA_real_))
  pat  <- str_c("\\b", toks, collapse = "|")
  hits <- wdpa_cand |> filter(str_detect(wdpa_key, pat))
  if (nrow(hits) == 0)
    return(tibble(matched = FALSE, wdpa_name = NA_character_, desig = NA_character_,
                  geom_area_km2 = NA_real_, rep_area_km2 = NA_real_))
  hits |>
    mutate(area_gap = abs(geom_area_km2 - ntca_total_km2)) |>
    arrange(area_gap) |>
    slice(1) |>
    transmute(matched = TRUE, wdpa_name, desig, geom_area_km2, rep_area_km2)
}

matched <- tr_ref |>
  rowwise() |>
  mutate(m = list(match_one(name, alt, ntca_total_km2))) |>
  ungroup() |>
  unnest(m) |>
  mutate(
    matched     = tidyr::replace_na(matched, FALSE),
    pct_vs_ntca = round(100 * (geom_area_km2 - ntca_total_km2) / ntca_total_km2, 1)
  ) |>
  select(name, state, ntca_total_km2, matched, wdpa_name, desig,
         geom_area_km2, rep_area_km2, pct_vs_ntca)

# ---- Coverage summary ------------------------------------------------------
n_matched <- sum(matched$matched)
cat("\n==================== COVERAGE ====================\n")
cat("Official tiger reserves        :", CURRENT_TR_COUNT, "\n")
cat("Located in WDPA (name match)   :", n_matched, "\n")
cat("Not found                      :", CURRENT_TR_COUNT - n_matched, "\n")

if (n_matched < CURRENT_TR_COUNT) {
  cat("\nReserves NOT found in WDPA (check names / recent notifications):\n")
  matched |> filter(!matched) |>
    mutate(l = sprintf("   - %-28s %s", name, state)) |> pull(l) |> cat(sep = "\n")
  cat("\n")
}

# ---- Area-basis summary (matched reserves only) ----------------------------
area_ok  <- matched |> filter(matched, !is.na(pct_vs_ntca))
within10 <- sum(abs(area_ok$pct_vs_ntca) <= 10)
cat("\n==================== AREA BASIS (matched only) ====================\n")
cat("Matched with an area figure    :", nrow(area_ok), "\n")
cat("Within +/-10% of legal area    :", within10, "\n")
cat("Median |deviation|             :",
    round(median(abs(area_ok$pct_vs_ntca), na.rm = TRUE), 1), "%\n")
cat("\nWorst positive (over-sized / buffer-inflated):\n")
area_ok |> arrange(desc(pct_vs_ntca)) |> slice(1:5) |>
  mutate(l = sprintf("   +%5.1f%%  %-26s (%s)", pct_vs_ntca, name, desig)) |>
  pull(l) |> cat(sep = "\n")
cat("\nWorst negative (under-sized / core-only):\n")
area_ok |> arrange(pct_vs_ntca) |> slice(1:5) |>
  mutate(l = sprintf("   %6.1f%%  %-26s (%s)", pct_vs_ntca, name, desig)) |>
  pull(l) |> cat(sep = "\n")

# ---- Write tables ----------------------------------------------------------
out_dir <- here("outputs", "tables")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
write_csv(matched,   file.path(out_dir, "tbl_00_wdpa_tr_match.csv"))
write_csv(wdpa_cand, file.path(out_dir, "tbl_00_wdpa_candidates.csv"))
cat("\nWrote", file.path(out_dir, "tbl_00_wdpa_tr_match.csv"), "\n")
cat("Wrote", file.path(out_dir, "tbl_00_wdpa_candidates.csv"), "\n")

# ---- Verdict ---------------------------------------------------------------
cat("\n==================== VERDICT ====================\n")
cov_pct <- round(100 * n_matched / CURRENT_TR_COUNT)
cat("Coverage: ", n_matched, "/", CURRENT_TR_COUNT, " (", cov_pct, "%).\n", sep = "")
if (cov_pct >= 90 && within10 >= 0.7 * nrow(area_ok)) {
  cat("PASS: WDPA locates most TRs and areas broadly match legal extents.\n",
      "WDPA is a defensible primary boundary source.\n", sep = "")
} else if (cov_pct >= 90) {
  cat("MIXED: coverage is good but many areas deviate from legal TR extent\n",
      "(core-only or buffer-inflated). Usable, but the area basis must be\n",
      "documented per-reserve — same class of caveat as the Phase 1 KBA issue.\n",
      sep = "")
} else {
  cat("WEAK: WDPA does not cleanly locate the full reserve set by name.\n",
      "Inspect the not-found list and tbl_00_wdpa_candidates.csv before\n",
      "rejecting — some misses may be name-variant, not true absences.\n", sep = "")
}
cat("Decide the boundary source in task 2.2 on the basis of these numbers.\n")
cat("NOTE: matching is heuristic. Skim tbl_00_wdpa_tr_match.csv for wrong\n",
    "matches (a TR grabbing an unrelated NP of similar name) before trusting.\n",
    sep = "")
