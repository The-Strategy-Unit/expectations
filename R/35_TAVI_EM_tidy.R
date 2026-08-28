# README
# Our desired unit of analysis is a continuous inpatient spell.
# We only want one record per super-spell but
# Superspells are rare for tavi emergencies:
# we remove only ~ 60 epis of 20k in this script.


# FLAG ALL EPIS THAT WERE PART OF A TAVI SPELL
df_tavi_emergency_spells_flagged <- df_tavi_emergency_exclusions |> 
  # GROUP BY SPELL ID IS NECESSARY. THE NHS NUMBER IS JUST IN CASE:
  group_by(nhs_no, der_spell_id) |> 
  mutate(tavi_spell = if_else(sum(tavi) > 0, 1, 0)) |> 
  ungroup()

# df_tavi_emergency_spells_flagged |>
#   count(tavi, tavi_spell)

gc()
gc()

# FOR ALL SPELLS, TAKE ONLY 1st EPI PER SPELL.
df_tavi_emergency_earliest_episodes <- df_tavi_emergency_spells_flagged |> 
  mutate(across(c(contains("date"), -contains("treatment_at_")), ~ as_date(.))) |> 
  group_by(nhs_no, der_spell_id) |>
  mutate(discharge_date = if_else(
    is.na(discharge_date), max(episode_end_date),
    discharge_date
  )) |> 
  filter(der_episode_number == min(der_episode_number)) |> 
  ungroup()


# BECAUSE WE'VE SPECIFIED IN QUERY TO ONLY TAKE EPI WITH THE PROCEDURE:
# 56% ARE FIRST EPIS, 79% 1 OR 2, 90% 1, 2, 3
# df_tavi_emergency_earliest_episodes |>
#   count(der_episode_number, sort = T) |>
#   mutate(p = n/sum(n))
gc()
gc()

# IMPUTE MISSING NHS NOs ------------------------------------------------------------------

# TODO CREATE A PSEUDO NHS NUMBER FOR THOSE WHO HAVEN'T ONE.
  # A BASIC ATTEMPT TO PICK UP POSSIBLE (IN-MONTH) TRANSFERS
  # FROM THOSE WITHOUT NHS NUMBER. 
  # (DOESN'T ASSIGN A CONSISTENT CODE FOR THE WHOLE STUDY PERIOD):
tmp_tavi_nhs_no <- df_tavi_emergency_earliest_episodes |> 
  mutate(nhs_no = as.character(nhs_no)) |> 
  group_by(fyear, month, age, sex, lsoa21_bfit) |> 
  mutate(nhs_no = case_when(
    is.na(nhs_no) ~ str_c("ASSIGNED_", cur_group_id()),
    T ~ nhs_no
  )) |> 
  ungroup()


# SUPER SPELL SECTION -------------------------------- 
## a. label super spells -----------------------------

tmp_tavi_superspells <- tmp_tavi_nhs_no |> 
  arrange(nhs_no, admission_date, discharge_date) |> 
  group_by(nhs_no) |> 
  # mutate(prior_spell_end_date = ) |> 
  mutate(flag_new_super = if_else(
    admission_date != lag(discharge_date, 1) | 
      is.na(lag(discharge_date, 1)),
    1, 0
  )) |> 
  mutate(super_spell_id = cumsum(flag_new_super)) |> 
  ungroup() 



## b. label TAVI super spells -----------------------------

tmp_tavi_superspells_2 <- tmp_tavi_superspells |> 
  group_by(nhs_no, super_spell_id) |> 
  mutate(tavi_superspell = if_else(sum(tavi_spell) > 0, 1, 0)) |> 
  ungroup()

# FIRST SPELL ----------------------------------------------------
# TAKE ONLY THE FIRST SPELL IN ANY SUPER-SPELLS (TAVI OR NOT)
# REMOVING 4 SPELLS THAT HAPPEN ON SAME DAY AS OTHER SPELL. 
# NO SPELLS HAPPEN 1,2,3.. DAYS AFTER, WHICH IS REASSURING. 

tmp_tavi_earliest_spell <- tmp_tavi_superspells_2 |> 
  group_by(nhs_no, super_spell_id) |> 
  filter(row_number() == min(row_number())) |> 
  ungroup()



# tmp_earliest_spell |> count(thromb_superspell)
# tmp_earliest_spell |> count(fyear, thromb_superspell) |> 
#   filter(thromb_superspell == 1)


# tmp_earliest_spell |>
#   count(admission_method, sort = T)
