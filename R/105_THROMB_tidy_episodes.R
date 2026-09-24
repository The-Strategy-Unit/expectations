# README
# Our desired unit of analysis is a continuous inpatient spell (super spell) 
# following a stroke. We only want one record per stroke super-spell 
# (transfers complicate)

# will pick out the earliest episode record in a super spell 
# favour this for reasons of consistency and cleanness 
# (but especially since 94% thrombectomies here occur in first epi)


# FURTHER DETAILS:
#
# ABBREVIATIONS: 
# THROMB = THROMBECTOMY 
# NTHROMB = NON-THROMBECTOMY

# TRANSFERS (TO AND FROM A THROMB CENTRE) MUST BE GUESSED AT.
# ACCORDING TO SSNAP ~60% OF PATIENTS ARE TRANSFERRED IN ORDER TO 
# RECIEVE A THROMB. 

# IN DATA WE HAVE APPROX 10% ARE ADMITTED TO A THROMB CENTRE AFTER
# BEING ADMITTED ELSEWHERE. WILL ASSUME THE REMAINING 50% ARE TRANSFERRED
# FROM ANOTHER ED.
# E.G. WITH ADMIMETH, OR THROUGH LINKING. 



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
  
# IMPUTE MISSING NHS NOs ------------------------------------------------------------------

# CREATE A PSEUDO NHS NUMBER FOR THOSE WHO HAVEN'T ONE.
# A BASIC ATTEMPT TO PICK UP POSSIBLE (IN-MONTH) TRANSFERS
# FROM THOSE WITHOUT NHS NUMBER. 
# (DOESN'T ASSIGN A CONSISTENT CODE FOR THE WHOLE STUDY PERIOD):
tmp_nhs_no <- df_earliest_episodes |> 
  mutate(nhs_no = as.character(nhs_no)) |> 
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

## b. label thromb super spells -----------------------------

tmp_thromb_superspells <- tmp_superspells |> 
  group_by(nhs_no, super_spell_id) |> 
  mutate(thromb_superspell = if_else(sum(thromb_spell) > 0, 1, 0)) |> 
  ungroup()

# FIRST SPELL ----------------------------------------------------
# TAKE ONLY THE FIRST SPELL IN ANY SUPER-SPELLS (THROMB OR NTHROMB)
    
tmp_thromb_earliest_spell <- tmp_thromb_superspells |> 
  group_by(nhs_no, super_spell_id) |> 
  filter(row_number() == min(row_number())) |> 
  ungroup()

# 85% of cases, the thromb is in the earliest/first spell in the superspell
# which could be plausible if most transfers are straight from other provider ED
# and haven't been admitted there. 
# tmp_earliest_spell |>
#   count(thromb, thromb_superspell) |> 
#   filter(thromb_superspell == 1) |> 
#   mutate(p = n/sum(n))

# CHECK HOW MANY ADMITTED A DAY AFTER BEING DISCHARGED.
# 6K
tmp_thromb_earliest_spell |>
  select(nhs_no, admission_date, discharge_date) |>
  group_by(nhs_no) |>
  filter(admission_date == lag(discharge_date)+ days(3)) |>
  ungroup()
# THERE ARE STILL 2K AFTER 2 DAYS AND 1K AFTER 3 DAYS.

tmp_thromb_earliest_spell |>
  filter(nhs_no == "100000019422") |> 
  select(nhs_no, admission_date, discharge_date) 
  