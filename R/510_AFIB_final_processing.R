df_afib_cleaned <- df_afib_join_tables_scored |>
  left_join(lkp_imd25_rank |> select(-imd_decile), join_by(lsoa21code == lsoa_code_2021)) |> 
  mutate(rural_urban_classification = case_when(
    str_detect(rural_urban_classification, "Urban") ~ "urban",
    str_detect(rural_urban_classification, "Larger") ~ "larger_rural",
    T ~ "smaller_rural"
  )) |>
  mutate(rural_urban_classification = fct_relevel(
    rural_urban_classification, "urban"
  )) |>
  mutate(min_ep_dist = round(min_ep_dist / 1e3, 1)) |>
  mutate(covid_effect = as_factor(
    case_when(
      # fyear == "2019/20" ~ "19/20",
      fyear == "2020/21" ~ "20/21",
      # fyear == "2021/22" ~ "21/22",
      # fyear == 13 ~ "22/23",
      T ~ "none"
    )
  )) |>
  mutate(covid_effect = fct_relevel(covid_effect, "none")) |>
  # HEART FAILURE LOOKBACKS:
  mutate(cm_hf_any = as.integer(hf_any == 1 | lb_hf_any == 1)) |> 
  mutate(cm_hf_specified = as.integer(hf_specified == 1 | lb_hf_specified == 1)) |> 
  mutate(cm_hf_unspecified = as.integer(hf_unspecified == 1 | lb_hf_unspecified == 1)) |>   
  # CENTRE AND SCALE:
  mutate(age_std = as.numeric(scale(age))) |>
  mutate(cci_std = as.numeric(scale(cci))) |>
  mutate(hfrs_std = as.numeric(scale(hfrs_score))) |>
  mutate(distance_std = as.numeric(scale(min_ep_dist))) |>
  mutate(across(
    c(
      sex, rural_urban_classification, rgn22nm, sicbl25nm, icb25nm, imd_decile,
      any_prior_admission, starts_with("cm_"), ep_centre, lb_af_prior,
      repeat_dccv
    ),
    ~ as.factor(.)
  )) |>
  # distinct(yr, fyear)
  # colnames()
  mutate(n_prior_dccv = as.factor(if_else(n_prior_dccv > 1, "2+", as.character(n_prior_dccv)))) |> 
  mutate(post_castle = as.factor(if_else(yr >= 9, 1, 0))) |> 
  mutate(post_castle_hf = as.factor(if_else(post_castle == 1 & cm_hf_any == 1, 1, 0))) |> 
  mutate(imd_top_quartile = as.factor(if_else(imd_quartile == 4, 1, 0))) |> 
  select(
    yr, fyear,
    ablation_24m, 
    sex, age, age_std, site_name, sicbl25nm, icb25nm,
    # number of spells (el or em) involving DCCV before first elective in which
    # DCCV was primary procedure:
    n_prior_dccv, 
    repeat_dccv, 
    imd_decile, imd_top_quartile, rural_urban_classification, rgn22nm, 
    # how long has a patient carried an afib diagnosis:
    lb_af_prior,
    post_castle,
    post_castle_hf,
    ep_centre, cci_std, any_prior_admission, 
    hfrs_std, covid_effect, distance_std,
    starts_with("cm_")
    
    ) 

# df_afib_cleaned |> glimpse()

# df_afib_join_tables_scored |> 
#   mutate(cm_hf_any = as.integer(hf_any == 1 | lb_hf_any == 1)) |> 
#   count(hf_any, cm_hf_any)
