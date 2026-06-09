
df_thromb_join_vars <- df_thromb_with_centres |> 
  left_join(lkp_imd25, join_by(lsoa21_bfit == lsoa_code_2021)) |>
  left_join(lkp_rural, join_by(lsoa21_bfit == lsoa_code)) |>
  left_join(lkp_regione, join_by(lsoa21_bfit == lsoa21cd)) 
  
