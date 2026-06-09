
# ONLY ENGLAND-RESIDENT PATIENTS WITH LSOA (98%):
# (WE CAN'T GET IMD FOR OTHERS)
# BEFORE 26/27
# AGE REALISTIC

# TODO EMERGENCY ADMISSIONS ONLY !!

df_thromb_exlcusions <- df_thromb_standardise_lsoa |>
  # ONLY ENGLAND-RESIDENT PATIENTS WITH LSOA (98%):
  filter(str_detect(lsoa21_bfit, "^E")) |> 
  filter(!is.na(lsoa21_bfit)) |> 
  filter(fyear != "2026/27") |> 
  filter(age <= 112)



