

# ABLATIONS ESCALATIONS (%) BY IMD, BY YEAR
# df_afib_exclusions |> 
#   left_join(lkp_imd25, join_by(lsoa21code == lsoa_code_2021)) |> 
#   count(yr, ablation_24m, imd_decile) |> 
#   group_by(yr, imd_decile) |> 
#   mutate(p = n/sum(n)) |> 
#   ungroup() |> 
#   filter(ablation_24m == 1) |> 
#   # pivot_wider(names_from = ablation_24m, values_from = n) |> 
#   # filter(fyear == "2023/24")
#   # print(n=30)
#   ggplot(aes(yr, p, col = as.factor(imd_decile)))+
#   geom_smooth(se = F, method = "lm")+
#   geom_blank(aes(y=0))


df_afib_join_tables <- df_afib_exclusions |> 
  left_join(lkp_imd25, join_by(lsoa21code == lsoa_code_2021)) |>
  left_join(lkp_rural, join_by(lsoa21code == lsoa_code)) |>
  left_join(lkp_icb, join_by(lsoa21code == lsoa21cd)) |> 
  left_join(lkp_regione, join_by(lsoa21code == lsoa21cd)) |>
  left_join(
    lkp_ep_centre |> select(fyear, der_provider_site_code, ep_centre),
    join_by(
      fyear,
      der_provider_site_code
    )
  ) |>
  mutate(ep_centre = if_else(is.na(ep_centre), 0, ep_centre)) |> 
  add_charlson_score() |>
  left_join(lkp_min_distance_ep, join_by(lsoa21code, fyear))

gc()
gc()
gc()


# # CHECK DIAGNOSIS CODING:
# df_afib_join_tables |> 
#   # filter(fyear == "2010/11") |> 
#   filter(fyear == "2023/24") |> 
#   count(der_diagnosis_all, sort = T) |> 
#   mutate(p = n/sum(n))
# 
# # CHECK COMORBIDITIES AS CODED BY CHARLSON
# df_afib_join_tables |> 
#   reframe(quantile(age))
# 
# df_afib_join_tables |> 
#   group_by(fyear) |> 
#   reframe(quantile(cci)) |> 
#   view("cci_quantiles")
# 
# df_afib_join_tables |> 
#   ggplot()+
#   geom_histogram(aes(cci), binwidth = 1)
# 
# 
# df_afib_join_tables |> 
#   mutate(cci_age = case_when(
#     age >= 80 ~ 4,
#     age >= 70 ~ 3,
#     age >= 60 ~ 2,
#     age >= 50 ~ 1,
#     TRUE ~ 0
#   )) |>
#   mutate(cci = cci - cci_age) |> 
#   # ggplot()+
#   # geom_histogram(aes(cci), binwidth = 1) 
#   count(cci) |> 
#   mutate(p = n/sum(n))
# 
# df_afib_join_tables |> colnames()
# df_afib_join_tables |> count(hypertension)
# df_afib_join_tables |> count(diabetes)
# df_afib_join_tables |> count(valve_disease)
# df_afib_join_tables |> count(obesity)

# lkp_min_distance_ep |> 
#   distinct()
#   # count(lsoa21code, fyear)
#   count(lsoa21code, fyear) |> 
#   filter(n>1) |> 
#   count(lsoa21code)

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





