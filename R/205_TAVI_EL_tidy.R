# README
# Select only a single episode for each spell
# (The majority of elective spells of two episodes here are tavi patients.)
  
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
