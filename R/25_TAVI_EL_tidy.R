# README
# This is a potential step. 
# Consecutive tavi spells are rare and will have little effect.
# Perhaps they are even genuine. 


# THE MAJORITY OF THOSE WITH ELECTIVE SPELLS OF TWO EPISODES ARE TAVI PATIENTS.

# TODO WEDNESDAY: WHEN WE EXCLUDE THE ADDITIONAL EPISODES, WE'LL HAVE TO
# CARRY OVER THE TAVI - IF NOT ALWAYS CARRIED.
tmp_tavi_elective_first_epi <- df_tavi_elective_exclusions |> 
  group_by(nhs_no, der_spell_id) |> 
  mutate(tavi_2 = if_else(sum(row_number()) > 1, 1, 0)) |> 
  # filter(sum(row_number()) > 1) |>
  # filter(sum(row_number()) == 1) |>
  ungroup() |> 
  mutate(tavi = if_else(tavi_2 == 1, 1, tavi)) |>
  select(-tavi_2) |> 
  arrange(nhs_no, admission_date, discharge_date) |> 
  group_by(nhs_no, der_spell_id) |> 
  filter(row_number() == 1) |> 
  ungroup()
    
  
#   ungroup() |> 
#   # filter(tavi == 1) |>
#   select(nhs_no, der_spell_id, admission_date, discharge_date, tavi) |> 
#   pull(der_spell_id)
# 
# df_tavi_elective_exclusions |> 
#   filter(der_spell_id %in% tmp_arc) |> 
#   count(tavi)
# 
# df_tavi_elective_exclusions |> 
#   filter(der_spell_id == "1729077593381998555") |> 
#   select(nhs_no, der_spell_id, admission_date, discharge_date, tavi)


# 10 CASES WHERE AORTIC VALVE REPLACEMENT IN TWO CONSECUTIVE SPELLS
# 5 CASES (50%) CONSECTIVE TAVIS
# tmp_tavi_elective_first_epi |> 
#   arrange(nhs_no, admission_date, discharge_date) |> 
#   group_by(nhs_no) |> 
#   mutate(prior_spell_end_date = lag(discharge_date, 1)) |> 
#   ungroup() |> 
#   filter(prior_spell_end_date == admission_date)
# 
# # WILL LEAVE IN THE DATASET
