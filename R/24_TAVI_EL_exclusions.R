# README
# SELECT ELECTIVE EPISODES 
# AND ONLY ENGLAND-RESIDENT PATIENTS WITH AN LSOA ASSIGNED (98%):
# (WE CAN'T GET IMD FOR OTHERS)

df_tavi_elective_exclusions <- df_tavi_standardise_lsoa |>
  # ONLY ENGLAND-RESIDENT PATIENTS WITH LSOA (97% PROB DUE TO LOW 25/26 LSOA RECORDING):
  filter(str_detect(lsoa21_bfit, "^E")) |> 
  filter(admission_method %in% c("11", "12", "13"))

# TODO: MAYBE ALSO EXCLUDE 2025/26 BASED ON LOW LSOA COMPLETION?

# df_tavi_exclusions |> 
#   count(der_management_type, admission_method, sort = T) |> 
#   mutate(p = n/sum(n))
#   print(n=40)


# df_tavi_standardise_lsoa |>
#   # ONLY ENGLAND-RESIDENT PATIENTS WITH LSOA (97% PROB DUE TO LOW 25/26 LSOA RECORDING):
#   filter(str_detect(lsoa21_bfit, "^E")) |> 
#   filter(!is.na(lsoa21_bfit)) |>
#   filter(tavi == 1) |> 
#   count(fyear, el = admission_method %in% c("11", "12", "13")) |> 
#   group_by(fyear) |> 
#   mutate(p = n/sum(n)) |> 
#   ungroup() |> 
#   filter(el == TRUE)