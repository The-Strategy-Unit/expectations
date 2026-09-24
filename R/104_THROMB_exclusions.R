# README
# SELECT ONLY ENGLAND-RESIDENT PATIENTS WITH AN LSOA (98%) 
# (LSOA REQUIRED FOR IMD (OUR EXPECTATIONS PROXY)

df_thromb_exclusions <- df_thromb_standard_lsoa |>
  filter(str_detect(lsoa21_bfit, "^E")) 

gc()
gc()
gc()


