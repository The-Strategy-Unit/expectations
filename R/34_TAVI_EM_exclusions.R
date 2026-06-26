
df_tavi_emergency_exclusions <- df_tavi_standardise_lsoa |>
  # ONLY ENGLAND-RESIDENT PATIENTS WITH LSOA (97% PROB DUE TO LOW 25/26 LSOA RECORDING):
  filter(str_detect(lsoa21_bfit, "^E")) |> 
  filter(str_detect(admission_method, "^2|81")) 

