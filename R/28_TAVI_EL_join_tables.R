
df_tavi_elective_join_vars <- tmp_tavi_elective_first_epi |> 
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
  ))|> 
  add_charlson_score() |> 
  left_join(lkp_min_distance_tavi, join_by(lsoa21_bfit, fyear))



gc()
gc()
gc()