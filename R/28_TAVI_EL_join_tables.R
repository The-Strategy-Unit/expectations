
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

# df_tavi_elective_join_vars |> vctrs::vec_size()
# 70050

df_tavi_elective_join_vars <- df_tavi_elective_join_vars |> 
  left_join(df_had_lookback, join_by(der_spell_id == index_spell_id)) |> 
  left_join(df_frailty_by_spell,  join_by(der_spell_id == index_spell_id)) |>
  mutate(any_prior_admission = as.factor(coalesce(any_prior_admission, 0L))) |> 
  mutate(score_frailty = coalesce(score_frailty, 0)) |> 
  mutate(n_hfrs_codes = coalesce(n_hfrs_codes, 0L)) |> 
  mutate(hfrs_band = case_when(
    score_frailty >  15 ~ "high",
    score_frailty >=  5 ~ "intermediate",
    TRUE             ~ "low"
  )) |> 
  mutate(hfrs_band = factor(hfrs_band, levels = c("low", "intermediate", "high")))
  
# ------------------------------------------------------------------------------
# Frailty Diagnostics 
# ------------------------------------------------------------------------------
  
# df_tmp |> 
#   ggplot(aes(score_frailty))+
#   # geom_histogram(binwidth = 1)+
#   geom_density()+
#   facet_wrap(vars(imd_decile))
#   
# df_tmp |> 
#   slice_sample(n = 10000) |> 
#   ggplot(aes(score_frailty, cci))+
#   # geom_smooth(method = "lm")+
#   geom_point(alpha = .01)
#   # facet_wrap(vars(imd_decile))
  
# message("Band distribution:")
# print(df_tmp |> count(hfrs_band) |> mutate(pct = 100 * n / sum(n)))
# 
# message("Share with no prior admission (score is 0-by-construction for these):")
# print(mean(df_tmp$any_prior_admission == 0))





