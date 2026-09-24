
df_tavi_emergency_join_vars <- tmp_tavi_earliest_spell |> 
  left_join(lkp_imd25, join_by(lsoa21_bfit == lsoa_code_2021)) |>
  left_join(lkp_rural, join_by(lsoa21_bfit == lsoa_code)) |>
  left_join(lkp_regione, join_by(lsoa21_bfit == lsoa21cd)) |>
  left_join(
    lkp_tavi_centres,
    join_by(
      der_provider_site_code == site_code,
      fyear
    )
  ) |>
  mutate(tavi_centre = if_else(
    is.na(tavi_centre), 0, tavi_centre
  )) |> 
  add_charlson_score() |> 
  left_join(lkp_min_distance_tavi, join_by(lsoa21_bfit, fyear))


gc()
gc()
gc()

# # WE'D EXPECT MOST ALL SURGICAL AVR TO BE AT TAVI CENTRE
# # TAVIs AT NOT TAVI ARE ANOMALIES 
# df_tavi_emergency_join_vars |>
#   count(fyear, tavi_superspell, tavi_centre) |>
#   group_by(fyear, tavi_superspell) |>
#   mutate(p = n/sum(n)) |>
#   ungroup() |> 
#   # filter(tavi_superspell == 1 & tavi_centre == 0) |> 
#   print(n=50)
