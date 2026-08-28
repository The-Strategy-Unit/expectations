# ==============================================================================
# HFRS STEP 2 -- SCORE THE LOOKBACK DIAGNOSES AND CATEGORISE
# ==============================================================================
# Inputs:
#   1. lookback_spells  -- output of [UDAL]frailty_score_lookback.sql via
#                          011_reference_data.R
#                          (one row per index spell x prior spell)
#   2. index_spells     -- full index cohort at spell level
#                          (one row per index spell; from the principal query)
#   3. frailty_risk_scores.csv -- the 109-row ICD-10 -> points reference
#                          (reconstruct from Gilbert et al. 2018 appendix;
#                           see frailty_risk_scores.r )
#
# Output: index_spells with hfrs_score, hfrs_band, any_prior_admission,
#         ready to join onto your modelling dataset by der_spell_id.
#
# Method decisions implemented here (see Claude chat notes):
#   - Accrual over ALL prior admissions (any admission method)
#   - Index-spell diagnoses EXCLUDED (handled upstream in SQL)
#   - Each 3-char ICD-10 code counts ONCE per index spell (distinct)
#   - Bands: low < 5, intermediate 5-15, high > 15 (Gilbert cutpoints)
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. Load
# ------------------------------------------------------------------------------
lkp_frailty_score
df_frailty_lookback
df_tavi_elective_join_vars

# lookback <- read_csv("data/lookback_spells.csv",
#                      col_types = cols(.default = col_character(),
#                                       index_admission_date  = col_date(),
#                                       prior_admission_date  = col_date(),
#                                       prior_discharge_date  = col_date()))

index_spells <- read_csv("data/index_spells.csv")   
# TODO: your cohort extract must contain: index_spell_id (== der_spell_id), nhs_no

lkp_frail <- read_csv("reference/frailty_risk_scores.csv",
                     col_types = cols(icd10 = col_character(),
                                      score = col_double()))


# ------------------------------------------------------------------------------
# 1. Split the concatenated diagnosis string into one row per code
# ------------------------------------------------------------------------------
# TODO: confirm the delimiter in Der_Diagnosis_All on YOUR extract.
# Commonly "," but some feeds use ";" or "||". The regex below splits on
# comma/semicolon/pipe and tolerates surrounding whitespace.
diag_delim_regex <- "[,;|]+"

df_diag_long <- df_frailty_lookback |> 
  select(index_spell_id, prior_diagnosis_all) |>
  separate_rows(prior_diagnosis_all, sep = diag_delim_regex) |>
  mutate(
    code = prior_diagnosis_all |>
      str_to_upper() |>
      # strip dots, dashes, spaces. X-fillers stay
      str_remove_all("[^A-Z0-9]")        
  ) 

wep <- df_diag_long |> 
  # must start letter+2 digits
  filter(str_detect(code, "^[A-Z][0-9]{2}")) |>   
  mutate(icd3 = str_sub(code, 1, 3)) 

# <-- Decision 3: each code once per index spell
df_diag_long <- wep |> distinct(index_spell_id, icd3)        

# ------------------------------------------------------------------------------
# 2. Map to points and sum per index spell
# ------------------------------------------------------------------------------
df_frailty_by_spell <- df_diag_long |>
  inner_join(lkp_frailty_score |> select(icd10, score), by = c("icd3" = "icd10")) |>
  group_by(index_spell_id) |>
  summarise(
    score_frailty   = sum(score),
    # distinct frailty codes contributing:
    n_hfrs_codes = n(),                 
    .groups = "drop"
  )

# Patients WITH prior admissions (for the utilisation marker), regardless of
# whether any of their codes were frailty codes:
df_had_lookback <- df_frailty_lookback |> distinct(index_spell_id) |>
  mutate(any_prior_admission = 1L)

