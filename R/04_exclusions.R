# README
# SELECT ONLY ENGLAND-RESIDENT PATIENTS WITH AN LSOA (98%) 
# (LSOA REQUIRED FOR IMD (OUR EXPECTATIONS PROXY)

df_thromb_exclusions <- df_thromb_standardise_lsoa |>
  filter(str_detect(lsoa21_bfit, "^E")) |> 
  filter(!is.na(lsoa21_bfit)) 

gc()
gc()
gc()


