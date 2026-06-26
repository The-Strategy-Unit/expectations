# README
# OUR DESIRED UNIT OF ANALYSIS IS A CONTINUOUS INPATIENT SPELL FOLLOWING STROKE.
# WE ONLY WANT ONE RECORD PER STROKE SUPER-SPELL (TRANSFERS COMPLICATE)

# WILL PICK OUT THE EARLIEST EPISODE RECORD IN A SUPER SPELL (CONTINUOUS 
# PERIOD OF INPATIENT CARE)

#
# FURTHER DETAILS:
#
# ABBREVIATIONS: 
# THROMB = THROMBECTOMY 
# NTHROMB = NON-THROMBECTOMY

# GIVEN WE DESIRE ONE RECORD PER STROKE, EITHER WE:
# 1. TAKE THE FIRST EPI FOR NTHROMBs, AND EPI WITH THE THROMB FOR THROMB PATIENTS
#   OR
# 2. TAKE THE FIRST EPI FOR ALL (HAVING FLAGGED ALL EPIS IN A THROMB SPELL)

# FAVOUR 2, FOR STUDY DESIGN, CONSISTENCY, CLEANNESS. 
# (ESPECIALLY SINCE 94% THROMBECTOMIES HERE OCCUR IN FIRST EPI)


# TRANSFERS (TO AND FROM A THROMB CENTRE) MUST BE GUESSED AT.
# ACCORDING TO SSNAP ~60% OF PATIENTS ARE TRANSFERRED IN ORDER TO 
# RECIEVE A THROMB. THIS IS NOT REFLECTED IN DATA WE HAVE.
# E.G. WITH ADMIMETH, OR THROUGH LINKING. 


# START HERE --------------------------------------------------------------


# FLAG ALL EPIS THAT WERE PART OF A THROMB SPELL
# + FILL IN THE VERY FEW EPIS WITHOUT A NUMBER (ALWAYS ISOLATED EPISODES SO == 1)
df_thromb_spells_flagged <- df_thromb_exclusions |>
  mutate(der_episode_number = if_else(is.na(der_episode_number), 1, der_episode_number)) |> 
  group_by(nhs_no, der_spell_id) |> 
  mutate(thromb_spell = if_else(sum(thromb) > 0, 1, 0)) |> 
  ungroup()

gc()
gc()


# FOR ALL SPELLS, TAKE ONLY 1st EPI PER SPELL.
# THIS TAKES A MINUTE.
df_earliest_episodes <- df_thromb_spells_flagged |> 
  mutate(across(c(contains("date"), -contains("treatment_at_")), ~ as_date(.))) |> 
  group_by(nhs_no, der_spell_id) |>
  mutate(discharge_date = if_else(
    is.na(discharge_date), max(episode_end_date),
    discharge_date
  )) |> 
  filter(der_episode_number == min(der_episode_number)) |> 
  ungroup()

# 90% ARE FIRST EPIS, 96% 1 OR 2, 98% 1, 2, 3
# df_first_epis |>  
#   count(der_episode_number, sort = T) |> 
#   mutate(p = n/sum(n))
# gc()
# gc()

# RECORDING OF TIMES STEADILY IMPROVES:
# BUT CONFIRMS THAT TIMES WILL HAVE TO BE SENSITIVITY 
# USING LAST 4 YEARS
# df_first_epis |>
#   # count(is.na(episode_start_time) |episode_start_time == "") |>
#   # count(fyear, null_time = is.na(episode_start_time) |episode_start_time == "") |> 
#   count(fyear, null_time = is.na(admission_time) |admission_time == "") |> 
#   group_by(fyear) |> 
#   mutate(p = n/sum(n)) |> 
#   ungroup() |> 
#   filter(null_time == F)
  

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

# # AN ISSUE WITH THROMBECTOMY IN BACK-TO-BACK SPELLS (OFTEN RECORDING ERROR?):
# df_thrombos |>
#   arrange(nhs_no, admission_date, discharge_date) |> 
#   group_by(nhs_no) |> 
#   mutate(prior_spell_end_date = lag(discharge_date, 1)) |> 
#   # FLAG LAGS AND LEAD,
#   # FILTER ON THE FLAG.
#   # BRING THRO SITE CODE
#   # SEMI JOIN SO WE EXCLUDE "THROMBS" NOT PERFORMED AT THROMB CENTRE.
#   lead
#     ungroup() |>
#   filter(prior_spell_end_date == admission_date)


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


# NEW NHS NO ------------------------------------------------------------------

# TODO CREATE A PSEUDO NHS NUMBER FOR THOSE WHO HAVEN'T ONE.
# HOW CONSERVATIVE TO BE IN TERMS OF ASSIGNING SPELLS TO THOSE NHS NOs
tmp_nhs_no <- df_earliest_episodes |> 
  mutate(nhs_no = as.character(nhs_no)) |> 
  # A BASIC ATTEMPT TO PICK UP POSSIBLE (IN-MONTH) TRANSFERS
  # FROM THOSE WITHOUT NHS NUMBER. 
  # (DOESN'T ASSIGN A CONSISTENT CODE FOR THE WHOLE STUDY PERIOD):
  group_by(fyear, month, age, sex, lsoa21_bfit) |> 
  mutate(nhs_no = case_when(
    is.na(nhs_no) ~ str_c("ASSIGNED_", cur_group_id()),
    T ~ nhs_no
  )) |> 
  ungroup()


# SUPER SPELL SECTION --------------------------------------- 
## a. label super spells -----------------------------

tmp_superspells <- tmp_nhs_no |> 
  arrange(nhs_no, admission_date, discharge_date) |> 
  group_by(nhs_no) |> 
  # mutate(prior_spell_end_date = ) |> 
  mutate(flag_new_super = if_else(
    admission_date != lag(discharge_date, 1) | 
      is.na(lag(discharge_date, 1)),
    1, 0
    )) |> 
  mutate(super_spell_id = cumsum(flag_new_super)) |> 
  # mutate(flag_super = if_else(is.na(flag_super), 0, flag_super)) |> 
  ungroup() 

# # NA in flag_super means first or only spell for that person
# # 0 in flag super means first or only spell in superspell 
# 
# tmp_superspells |>
#   # filter(nhs_no == "100034739531") |> 
#   head(15) |> 
#   select(nhs_no, der_spell_id, admission_date, discharge_date, thromb_spell, flag_new_super, super_spell_id)
#   
# uk <- tmp_superspells |>
#   group_by(nhs_no) |> 
#   mutate(flag_2 = if_else(lead(flag_super, 1) == 1 , 1, 0)) |> 
#   ungroup()
# 
# 
# uk |>
#   head(15) |> 
#   select(nhs_no, der_spell_id, admission_date, discharge_date, thromb_spell, flag_super, flag_2) |> 
#   mutate(flag_2 = cumsum(flag_super, na.rm = T))
#   
# uk |>
#   filter(nhs_no == "100034739531") |> 
#   mutate(flag_super = if_else(flag_super == 2, 1, flag_super)) |>  
#   mutate(flag_2 = if_else(flag_super == 1 | flag_2 == 1, 1, 0)) |>  
#   # filter(flag_super == 2) |> 
#   # count(nhs_no, sort = T)
#   select(nhs_no, der_spell_id, admission_date, discharge_date, thromb_spell, flag_super, flag_2)
# 
# 
# 
# 
# df_thromb_spells_flagged |> 
#   filter(nhs_no == "100034739531") |> 
#   mutate(across(c(contains("date"), -contains("treatment_at_")), ~ as_date(.))) |> 
#   arrange(nhs_no, admission_date, discharge_date) |> 
#   select(nhs_no, der_spell_id, admission_date,  discharge_date, admission_time, discharge_time, thromb_spell)

## a. label thromb super spells -----------------------------

tmp_thromb_superspells <- tmp_superspells |> 
  group_by(nhs_no, super_spell_id) |> 
  mutate(thromb_superspell = if_else(sum(thromb_spell) > 0, 1, 0)) |> 
  ungroup()

tmp_thromb_superspells |> 
  # filter(thromb_superspell == 1) |>
  # count(nhs_no, sort = T)
  filter(nhs_no == "100034728599") |>
  # select(nhs_no)
  select(nhs_no, super_spell_id, admission_date, discharge_date, thromb, thromb_spell, thromb_superspell)


# FIRST SPELL ----------------------------------------------------
# TAKE ONLY THE FIRST SPELL IN ANY SUPER-SPELLS (THROMB OR NTHROMB SUPERSPELLS)
    
tmp_earliest_spell <- tmp_thromb_superspells |> 
  group_by(nhs_no, super_spell_id) |> 
  filter(row_number() == min(row_number())) |> 
  ungroup()

tmp_earliest_spell |> 
  filter(nhs_no == "100034728599") |>
  # select(nhs_no)
  select(nhs_no, super_spell_id, admission_date, discharge_date, thromb, thromb_spell, thromb_superspell)


tmp_earliest_spell |> count(thromb_superspell)
tmp_earliest_spell |> count(fyear, thromb_superspell) |> 
  filter(thromb_superspell == 1)


tmp_earliest_spell |>
  count(admission_method, sort = T)

# 85% of cases, the thromb is in the earliest/first spell in the superspell
# which could be plausible if most transfers are straight from other provider ED
# and haven't been admitted there. 
# tmp_earliest_spell |>
#   count(thromb, thromb_superspell) |> 
#   filter(thromb_superspell == 1) |> 
#   mutate(p = n/sum(n))

# END ---------------------------------------------------------------------





# SPLIT INTO THROMB AND NTHROMB DFs:
df_thrombos <- tmp_nhs_no |> 
  filter(thromb_spell == 1) |> 
  select(nhs_no, der_spell_id, admission_date, discharge_date)

df_nonthrombos <- tmp_nhs_no |>
  filter(thromb_spell == 0) |> 
  select(nhs_no, der_spell_id, admission_date, discharge_date)

# df_nonthrombos |> filter(is.na(nhs_no)) # 2788
# df_thrombos |> filter(is.na(nhs_no)) # 97


###### 1. NTHROMB SPELLS THAT APPEAR TO BE SECONDARY SPELLS IN NTHROMB SUPER SPELL ----
# WILL REMOVE ~7Ok SPELLS
lkp_nthromb_superspells <- df_nonthrombos |>
  arrange(nhs_no, admission_date, discharge_date) |> 
  group_by(nhs_no) |> 
  mutate(prior_spell_end_date = lag(discharge_date, 1)) |> 
  ungroup() |> 
  mutate(flag_super = if_else(admission_date == prior_spell_end_date, 1, 0)) |> 
  # mutate(flag_super = if_else(is.na(flag_super), 0, flag_super)) |> 
  select(-prior_spell_end_date)
  
# lkp_nthromb_superspells |> count(flag_super)

## 2. THROMBECTOMY SPELLS WHERE THE PATIENT WAS LIKELY TRANSFERRED FOR THROMBECTOMY ----
## AFTER BEING ADMITTED ELSEWHERE 
lkp_thromb_after_transfer <- df_thrombos |> 
  # TRANSFERRED TO SPECIALIST CENTRE: (REMOVES 2K)
  semi_join(df_nonthrombos, join_by(nhs_no, admission_date == discharge_date)) |> 
  mutate(flag_thromb_post_trsfr = 1)

# TODO IF WE ARE REMOVING THOSE ABOVE, WE'D HAVE TO FLAG 
# THE REMAINING SPELL AS A THROMB SPELL:
df_idea <- df_nonthrombos |> 
  # TRANSFERS TO SPECIALIST CENTRE: (REMOVES 2K)
  semi_join(df_thrombos, join_by(nhs_no, discharge_date == admission_date)) |> 
  mutate(flag_make_thromb_spell = 1)


## a. TODO (come back to this)  ----------------------------------------------

# 1941 vs 1945 (removed from thromb spells vs. )
# in x, not in y
# anti_join(
#   df_idea, 
#   lkp_thromb_after_transfer,
#   join_by(nhs_no, admission_date == discharge_date)
#   join_by(nhs_no,  discharge_date == admission_date )
# )

# testing_ok <- df_first_epis |> 
#   left_join(df_idea, join_by(nhs_no, der_spell_id, admission_date, discharge_date)) |> 
#   left_join(lkp_thromb_after_transfer, join_by(nhs_no, der_spell_id, admission_date, discharge_date)) 
# 
# 
# testing_ok <- testing_ok |>  
#   filter((if_any(contains("flag"), ~ . == 1)))
#   
# 1927 + 41

# testing_ok |> 
#   count(nhs_no) |> 
#   count(n, sort = T)
# 
# arrange(nhs_no) |> 
#   head() |> 
#   view()
#   # rowwise() |> 
#   # mutate(l = sum(c_across(contains("flag"))))
#   group_by(nhs_no)


# -------------------------------------------------------------------------

# lkp_thromb_after_transfer |>  count(flag_thromb_post_trsfr)
# df_idea |>  count(flag_make_thromb_spell)

## THIS SUGGESTS THAT >10% OF PATIENTS ARE ADMITTED ELSEWHERE THEN TRANSFERRED
# lkp_thromb_after_transfer |> count(year(admission_date))
## SO INFERRING FROM THE '60% TRANSFER' SSNAP STAT, 50% WOULD BE TRANSFERED PRIOR TO ADM

## 3. NON-THROMBECTOMY SPELLS WHERE THE PATIENT WAS LIKELY TRANSFERRED AFTER THROMBECTOMY  ----
lkp_transfers_post_thromb <- df_nonthrombos |> 
  # TRANSFERS FROM SPECIALIST CENTRE: (REMOVES 8K)
  semi_join(df_thrombos, join_by(nhs_no, admission_date == discharge_date)) |> 
  mutate(flag_post_thromb = 1)

lkp_transfers_post_thromb |>  count(flag_post_thromb)


## unite -----------------------------------------------------------------


# tmp_woah <- df_spells_tidied |> 
tmp_woah <- tmp_nhs_no |> 
  left_join(df_idea, join_by(nhs_no, der_spell_id, admission_date, discharge_date))

# 200 of the related spells have already been removed. what does this mean?

tmp_woah |> 
  count(flag_make_thromb_spell)

# df_flag_supporting_spells <- tmp_nhs_no |> 
df_flag_supporting_spells <- tmp_woah |> 
  left_join(lkp_nthromb_superspells, join_by(nhs_no, der_spell_id, admission_date, discharge_date)) |> 
  left_join(lkp_thromb_after_transfer, join_by(nhs_no, der_spell_id, admission_date, discharge_date)) |> 
  left_join(lkp_transfers_post_thromb, join_by(nhs_no, der_spell_id, admission_date, discharge_date)) 

# 80k spells removed in total
df_flag_supporting_spells |>
  mutate(across(contains("flag"), ~ if_else(is.na(.), 0, .))) |> 
  count(a = flag_make_thromb_spell, flag_super, flag_thromb_post_trsfr, flag_post_thromb)

df_spells_tidied <- df_flag_supporting_spells |>
  mutate(across(contains("flag"), ~ if_else(is.na(.), 0, .))) |> 
  # count(flag_super, flag_thromb_post_trsfr, flag_post_thromb)
  filter((if_all(contains("flag"), ~ . == 0))) 



df_spells_tidied <- df_spells_tidied |> 
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

# 
# 
# # CHECK THAT DIFFERENT PROVIDERS - WANT TO INCLUDE SAME PROVIDER
# tmp_transfer_count <- df_thrombos |> 
#   left_join(df_nonthrombos, join_by(nhs_no, spell_start == spell_end), keep = T)
#   # left_join(df_nonthrombos, join_by(nhs_no, spell_start), keep = T)
# 
# tmp_transfer_count |> 
#   count(!is.na(nhs_no.y)) |> 
#   mutate(p = n/sum(n))
# 
# tmp_transfer_count |> 
#   filter(site_name.x == site_name.y)
# 
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

