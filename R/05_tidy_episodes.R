# README
# OUR DESIRED UNIT OF ANALYSIS IS A CONTINUOUS INPATIENT SPELL FOLLOWING STROKE.
# WE ONLY WANT ONE RECORD PER STROKE SUPER-SPELL (E.G. INCL. TRANSFERS)

#
# FURTHER DETAILS:
#
# ABBREVIATIONS: 
# THROMB = THROMBECTOMY 
# NTHROMB = NON-THROMBECTOMY

# GIVEN WE DESIRE ONE RECORD PER STROKE, EITHER WE:
# 1. TAKE THE FIRST EPI FOR NTHROMBs, AND EPI WITH THE THROMB 
#    (AND EXCL. SPELLS WITH TWO THROMBS) FOR THROMB PATIENTS; OR
# 2. TAKE THE FIRST EPI FOR ALL (HAVING FLAGGED ALL EPIS IN THROMB SPELL)

# FAVOUR 2., FOR CONSISTENCY AND CLEANNESS, 
# ESPECIALLY SINCE 94% THROMBECTOMIES HERE OCCUR IN FIRST EPI


# TRANSFERS (TO AND FROM A THROMB CENTRE) MUST BE GUESSED AT.
# ACCORDING TO SSNAP ~60% OF PATIENTS ARE TRANSFERRED IN ORDER TO 
# RECIEVE A THROMB. THIS IS NOT REFLECTED IN DATA WE HAVE.
# E.G. WITH ADMIMETH, OR THROUGH LINKING. 


# START HERE --------------------------------------------------------------

gc()
gc()
gc()

# FLAG ALL EPIS THAT WERE PART OF A THROMB SPELL
# + FILL IN THE VERY FEW EPIS WITHOUT A NUMBER (ALWAYS ISOLATED EPISODES SO == 1)
df_spells <- df_thromb_exlcusions |>
  mutate(der_episode_number = if_else(is.na(der_episode_number), 1, der_episode_number)) |> 
  group_by(nhs_no, der_spell_id) |> 
  mutate(thromb_spell = if_else(sum(thromb) > 0, 1, 0)) |> 
  ungroup()

gc()
gc()

# FOR ALL SPELLS, TAKE ONLY 1st EPI PER SPELL.
df_new <- df_spells |>
  mutate(across(contains("date"), ~ as_date(.))) |> 
  group_by(nhs_no, der_spell_id) |>
  mutate(discharge_date = if_else(
    is.na(discharge_date), max(episode_end_date),
    discharge_date
  )) |> 
  filter(der_episode_number == min(der_episode_number)) |> 
  ungroup()

gc()
gc()

df_new |> count(is.na(discharge_date))


# **start old code ----------------------------------------------------------------
# THE LAST EPI FOR NTHROMBS, FIRST EPI FOR THROMBS
# TODO: THIS DF ONLY FOR THE PURPOSES OF IDENTIFYING TRANSFERS:

# df_transfers <- df_spells |> 
#   group_by(nhs_no, der_spell_id) |>
#   mutate(epi_chosen = case_when(
#     thromb_spell == 1 & der_episode_number == min(der_episode_number) ~ 1, 
#     thromb_spell == 0 & der_episode_number == max(der_episode_number) ~ 1,
#     T ~ NA_real_
#   )) |> 
#   ungroup() |> 
#   filter(epi_chosen == 1)
# 
# gc()
# gc()


# WE WILL SEE WHEN SPELLS OCCUR ON SAME DAY, DIFFERENT PROVIDERS


# SPLIT INTO THROMB AND NTHROMB:
# df_thrombos <- df_transfers |> 
# df_thrombos <- df_new |> 
#   filter(thromb_spell == 1) |> 
#   mutate(spell_start = as_date(episode_start_date)) |> 
#   select(nhs_no, site_name, spell_start)

# WE WANT NTHROMBS STARTING OR ENDING ON THE SAME DATE AS THROMB
# TODO: BECAUSE WE ONLY WANT ONE RECORD PER STROKE INCIDENT: 
# EVEN AT SAME PROVIDER - EXCLUDE RECORD
# TODO: THINK ABOUT WHETHER, IF THROMB, THIS EXCLUDES ALL PRIOR AND 
# SUBSEQUENT SPELLS (EPIs)???? FOR A CERTAIN PERIOD

# df_nonthrombos <- df_transfers |>
#   filter(thromb_spell == 0) |> 
#   mutate(spell_end = as_date(episode_end_date)) |>
#   select(nhs_no, site_name, spell_end)
#   # mutate(spell_start = as_date(episode_start_date)) |> 
#   # select(nhs_no, site_name, spell_start)

# **end old code ----------------------------------------------------------------


# ** INVESTIGATION START -------------------------------------------------------------
# # THROMB PATIENTS WITH MULTIPLE THROMBS 
# # (99% HAVE ONLY 1 (ASSUMING NAs ARE DIFFERENT PPL))
# df_thrombos |> count(nhs_no, sort = T) |> count(n) |> mutate(p = nn/sum(nn))
# # LOOK AT 2s and 3s
# 100007658266   
# 100034728599     
# 100001022775
# 100001093299     
# df_transfers |> 
#   relocate(thromb_spell, .before = fyear) |> 
#   filter(nhs_no == "100007658266") |> 
#   view()
# # TODO ADM METHOD 81 MAY WELL BE TRANSFERS *AFTER* THROMB
# # AMISSION DATES - WE'RE AFTER ADMISSIONS FOR STROKE. SO USE ADM / DISDATE
# # FOR STEP UP (TRANSFERS) AND STEP DOWN (TRANSFERS)
# # THERE IS COMPLICATED HISTORY
# df_transfers |> 
#   relocate(thromb_spell, .before = fyear) |> 
#   filter(nhs_no == "100034728599") |> 
#   view()
# # TODO TAKE ADMISSION AND DISDATE ON THE SAME DAY AS OTHER SPELLS
# df_transfers |> 
#   relocate(thromb_spell, .before = fyear) |> 
#   filter(nhs_no == "100001093299") |> 
#   view()
# ** INVESTIGATION END --------------------------------------------------------

# AN ISSUE WITH THROMBECTOMY IN BACK-TO-BACK SPELLS (OFTEN RECORDING ERROR?):
df_thrombos |>
  arrange(nhs_no, admission_date, discharge_date) |> 
  group_by(nhs_no) |> 
  mutate(prior_spell_end_date = lag(discharge_date, 1)) |> 
  # FLAG LAGS AND LEAD,
  # FILTER ON THE FLAG.
  # BRING THRO SITE CODE
  # SEMI JOIN SO WE EXCLUDE "THROMBS" NOT PERFORMED AT THROMB CENTRE.
  lead
    ungroup() |>
  filter(prior_spell_end_date == admission_date)


# df_new |> 
#   filter(thromb_spell == 1) |> 
#   filter(nhs_no == "100006985203") |> 
#   view()
# 
# df_new |> 
#   filter(thromb_spell == 1) |> 
#   filter(nhs_no == "100001080228") |> 
#   view()
# 
# df_new |> 
#   filter(thromb_spell == 1) |> 
#   filter(nhs_no == "100029761718") |> 
#   view()
# 
# df_new |> 
#   filter(thromb_spell == 1) |> 
#   filter(nhs_no == "100025414039") |> 
#   view()
# df_new |>
#   filter(thromb_spell == 1) |>
#   filter(nhs_no == "100031251974") |>
#   view()

# SUPERSPELLS: TAKE ONE RECORD PER SUPER-SPELL (WHETHER THE SUPER-SPELL HAS THROMB OR NOT)------

# SPLIT INTO THROMB AND NTHROMB:
df_thrombos <- df_new |> 
  filter(thromb_spell == 1) |> 
  select(nhs_no, der_spell_id, admission_date, discharge_date)

df_nonthrombos <- df_new |>
  filter(thromb_spell == 0) |> 
  select(nhs_no, der_spell_id, admission_date, discharge_date)

## 1. NON-THROMBECTOMY SPELLS THAT APPEAR TO BE SUPPORTING SPELLS IN A THROMB SUPER SPELL ----
# WILL REMOVE ~8Ok SPELLS
lkp_superspells <- df_nonthrombos |>
  arrange(nhs_no, admission_date, discharge_date) |> 
  group_by(nhs_no) |> 
  mutate(prior_spell_end_date = lag(discharge_date, 1)) |> 
  ungroup() |> 
  mutate(flag_super = if_else(admission_date == prior_spell_end_date, 1, 0)) |> 
  # mutate(flag_super = if_else(is.na(flag_super), 0, flag_super)) |> 
  select(-prior_spell_end_date)
  
# lkp_superspells |> count(flag_super)

## 2. NON-THROMBECTOMY SPELLS WHERE THE PATIENT WAS LIKELY TRANSFERRED FOR THROMBECTOMY -----
lkp_transfers_pre_thromb <- df_nonthrombos |> 
  # TRANSFERS TO SPECIALIST CENTRE: (REMOVES 2K)
  semi_join(df_thrombos, join_by(nhs_no, discharge_date == admission_date)) |> 
  mutate(flag_pre_thromb = 1)

## 3. NON-THROMBECTOMY SPELLS WHERE THE PATIENT WAS LIKELY TRANSFERRED AFTER THROMBECTOMY  ----
lkp_transfers_post_thromb <- df_nonthrombos |> 
  # TRANSFERS FROM SPECIALIST CENTRE: (REMOVES 9K)
  semi_join(df_thrombos, join_by(nhs_no, admission_date == discharge_date)) |> 
  mutate(flag_post_thromb = 1)

df_flag_support_spells <- df_new |> 
  left_join(lkp_superspells, join_by(nhs_no, der_spell_id, admission_date, discharge_date)) |> 
  left_join(lkp_transfers_pre_thromb, join_by(nhs_no, der_spell_id, admission_date, discharge_date)) |> 
  left_join(lkp_transfers_post_thromb, join_by(nhs_no, der_spell_id, admission_date, discharge_date))  |> 
  # vctrs::vec_size() # 991327
  identity()

df_spells_tidied <- df_flag_support_spells |>
  mutate(across(contains("flag"), ~ if_else(is.na(.), 0, .))) |> 
  # count(flag_super, flag_pre_thromb, flag_post_thromb)
  filter((if_all(contains("flag"), ~ . == 0))) 

df_spells_tidied <-df_spells_tidied |> 
  select(-c(starts_with("episode"), thromb, starts_with("flag")))

df_spells_tidied |> colnames()
gc()
gc()
gc()
gc()

# df_spells_tidied |> 
#   count(fyear, thromb_spell) |> 
#   group_by(fyear) |> 
#   mutate(p = n/sum(n)) |> 
#   print(n=40)

# -------------------------------------------------------------------------




# -------------------------------------------------------------------------



# CHECK THAT DIFFERENT PROVIDERS - WANT TO INCLUDE SAME PROVIDER
tmp_transfer_count <- df_thrombos |> 
  left_join(df_nonthrombos, join_by(nhs_no, spell_start == spell_end), keep = T)
  # left_join(df_nonthrombos, join_by(nhs_no, spell_start), keep = T)

tmp_transfer_count |> 
  count(!is.na(nhs_no.y)) |> 
  mutate(p = n/sum(n))

tmp_transfer_count |> 
  filter(site_name.x == site_name.y)

# ABOUT 2,000 WITH OTHER SPELL END ON SAME DAY AS THROMBO
# ABOUT 2,500 WITH OTHER SPELL START ON SAME DAY AS THROMBO

# START OR END - WE WANT BOTH, BECAUSE WE ONLY WANT ONE STROKE INCIDENT
# RECORDED 

# TODO: FOR MONDAY, WE WANT TO FLAG THE RECORDS TO REMOVE IN THE 
# MAIN DATASET - USING SOME KING OF KEY AND FOR LOOKUP. 
# AND THEN LOOK AT ADMIMETH TRANSFERS TO SEE IF THESE WERE THE SAME GROUP.
# EXCLUDE BEFORE (OR AFTER) ON THE SAME DAY

# GET ALL ROWS FROM NONTHROMBOS WITHOUT A MATCH IN THROMBOS:
tmp_transfers_removed <- df_nonthrombos |> 
  anti_join(df_thrombos, join_by(nhs_no, spell_end == spell_start))


# TODO - IN ADDTION TO THE ABOVE, WE'RE ALSO INTERESTED IN
# THE 1100 ADMIMETH 2Bs
# POTENTIALLY THE 950 2Ds - BUT CAN'T DO MUCH
# AND REMOVE THE NON "EM" 


# TODO: ALL MECHANICAL THROMBECTOMIES SHOULD BE EMERGENCY!
df_temp |> 
  filter(thromb == 1) |> 
  count(der_management_type, admission_method, sort = T) |> 
  mutate(p = n/sum(n))

