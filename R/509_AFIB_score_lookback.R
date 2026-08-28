# =====================================================================
# LOOKBACK SCORING - HFRS + COMORBIDITIES - DCCV ESCALATION COHORT
# ---------------------------------------------------------------------
# Inputs:
#   df_lookback_afib: output of sql code from 002_reference.R
#                  (der_spell_id, nhs_no, index_admission_date,
#                   prior_discharge_date, prior_diagnosis_all)
#   cohort       : final cohort from dccv_ablation_cohort.sql
#                  (one row per index spell; must include der_spell_id,
#                   fyear, and the index-spell comorbidity flags if you
#                   want the comparison in section 6)
#  lkp_frailty_score   : sourced from  002_reference.R
#
# Outputs: one row per index spell with
#   hfrs_score, hfrs_band, any_prior_admission, n_prior_spells,
#   lb_* comorbidity flags (lookback-based),
#   cm_* combined flags (lookback OR index-spell, if index flags supplied).

# ---------------------------------------------------------------------
# 1. Long table of DISTINCT codes per index spell
#    4-char kept once here; 3-char derived from it. Delimiter-agnostic.
# ---------------------------------------------------------------------
df_codes_long <- df_lookback_afib |>
  # head(10) |> 
  select(der_spell_id, prior_diagnosis_all) |>
  separate_rows(prior_diagnosis_all, sep = "[,;|[:space:]]+") |>
  mutate(icd4 = prior_diagnosis_all |> str_trim() |> str_to_upper() |> str_sub(1, 4)) |>
  filter(str_length(icd4) >= 3) |>
  mutate(icd3 = str_sub(icd4, 1, 3)) |>
  distinct(der_spell_id, icd4, .keep_all = TRUE) |>
  select(der_spell_id, icd3, icd4)

df_codes3 <- df_codes_long |> distinct(der_spell_id, icd3)   # HFRS + 3-char flags

# ---------------------------------------------------------------------
# 2. Spot-check assertions (transcription-error tripwire)
# ---------------------------------------------------------------------
stopifnot(
  nrow(lkp_frailty_score) == 109,
  !any(duplicated(lkp_frailty_score$icd10)),
  near(lkp_frailty_score$score[lkp_frailty_score$icd10 == "F00"], 7.1),
  near(lkp_frailty_score$score[lkp_frailty_score$icd10 == "W19"], 3.2)
)

# ---------------------------------------------------------------------
# 3. HFRS: each distinct 3-char code scores once per index spell
# ---------------------------------------------------------------------
df_hfrs <- df_codes3 |>
  inner_join(lkp_frailty_score, join_by(icd3 == icd10)) |>
  summarise(score = sum(score), .by = der_spell_id)

# ---------------------------------------------------------------------
# 4. Comorbidity flags - definitions in one place, flags via purrr
# ---------------------------------------------------------------------
list_comorb_def <- list(
  lb_hypertension  = str_c("I1", 0:5),
  lb_ihd           = str_c("I2", 0:5),
  lb_stroke_tia    = c("I63", "I64", "G45"),
  lb_diabetes      = str_c("E1", 0:4),
  lb_copd          = "J44",
  lb_ckd           = "N18",
  lb_valve_disease = c("I34", "I35"),
  lb_obesity       = "E66",
  lb_hf_any        = "I50",
  lb_af_prior      = "I48"    # pathway-duration marker
)

df_flags3 <- list_comorb_def |>
  imap(\(stems, nm) df_codes3 |>
         filter(icd3 %in% stems) |>
         distinct(der_spell_id) |>
         mutate("{nm}" := 1L)) |>
  reduce(full_join, by = "der_spell_id")

# HF specified vs unspecified (4-char):
df_flags4 <- df_codes_long |>
  filter(icd3 == "I50") |>
  summarise(
    lb_hf_unspecified = as.integer(any(icd4 == "I509")),
    lb_hf_specified   = as.integer(any(icd4 %in% c("I500", "I501"))),
    .by = der_spell_id
  )

# ---------------------------------------------------------------------
# 5. Assemble: zero-fill, band, disambiguate zero scores
# ---------------------------------------------------------------------
df_n_prior <- df_lookback_afib |>
  summarise(n_prior_spells = n(), .by = der_spell_id)

df_afib_scored <- df_afib_join_tables |> #  184,127
  select(der_spell_id) |>
  left_join(df_hfrs,    by = "der_spell_id") |>
  left_join(df_flags3,  by = "der_spell_id") |>
  left_join(df_flags4,  by = "der_spell_id") |>
  left_join(df_n_prior, by = "der_spell_id") |>
  mutate(
    n_prior_spells      = replace_na(n_prior_spells, 0L),
    any_prior_admission = as.integer(n_prior_spells > 0),
    hfrs_score          = replace_na(score, 0),
    across(starts_with("lb_"), \(x) replace_na(x, 0L)),
    hfrs_band = cut(hfrs_score, breaks = c(-Inf, 5, 15, Inf),
                    labels = c("low", "intermediate", "high"), right = FALSE)
  ) |> 
  select(-score)
# Caveat carried over: hfrs_score == 0 conflates "robust" with "never
# admitted"; any_prior_admission is the disambiguator and belongs in the
# model alongside the band.

# ---------------------------------------------------------------------
# 6. Diagnostics
# ---------------------------------------------------------------------
df_diagnostics <- df_afib_scored |> 
  left_join(df_afib_join_tables |> select(der_spell_id, fyear),
            by = "der_spell_id")

# (a) History-depth check - a ramp in early years = lookback truncation:
df_diagnostics |>
  summarise(mean_hfrs = mean(hfrs_score),
            pct_any_prior = mean(any_prior_admission),
            .by = fyear) |>
  arrange(fyear) 

# (b) Index-spell vs lookback ascertainment. A GROWING index/lookback
#     ratio across fyear is the coding-depth artefact showing itself:
idx_flags <- intersect(c("hypertension", "ihd", "stroke_tia", "diabetes",
                         "copd", "ckd", "valve_disease", "obesity"),
                       names(df_afib_join_tables))

if (length(idx_flags)) {
  df_diagnostics |>
    left_join(df_afib_join_tables |> select(der_spell_id, all_of(idx_flags)),
              by = "der_spell_id") |>
    summarise(
      across(all_of(idx_flags), mean, .names = "idx_{.col}"),
      across(str_c("lb_", idx_flags), mean, .names = "{.col}"),
      .by = fyear
    ) |>
    arrange(fyear) |>
    # print(n = Inf, width = Inf)
    tibble() |> 
    select(1, 2, 10, 3, 11, 4, 12, 5, 13, 6, 14, 7, 15, 8, 16, 9, 17 ) |> 
    view("lookback_vs_original")
}


# ---------------------------------------------------------------------
# 7. Combined flags for modelling (lookback OR index-spell)
# ---------------------------------------------------------------------
if (length(idx_flags)) {
  df_afib_scored_2 <- df_afib_scored |>
    left_join(df_afib_join_tables |> select(der_spell_id, all_of(idx_flags)),
              by = "der_spell_id") |>
    mutate(map2_dfc(
      .x = pick(all_of(str_c("lb_", idx_flags))),
      .y = pick(all_of(idx_flags)),
      .f = \(lb, ix) as.integer(lb == 1L | ix == 1L)
    ) |> set_names(str_c("cm_", idx_flags))) |>
    select(-all_of(idx_flags))   # drop raw index flags; cohort still has them
}


# 8. JOIN TO MAIN DF -------------------------------------------

df_afib_join_tables_scored <- df_afib_join_tables |> #  184,127 
  left_join(df_afib_scored_2, join_by(der_spell_id))

