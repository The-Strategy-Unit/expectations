df_tavi_elective_join_vars <- readRDS(here("data_raw", "df_tavi_elective_join_vars.rds"))


# FROM "011_reference_data.R":
lkp_icb <- read_csv(
  here("data", list.files(here("data"), pattern = "SICBL"))
) |>
  clean_names() |>
  # colnames()
  select(lsoa21cd, sicbl25nm, icb25nm)

gc()
gc()
gc()


tmp_elective <- df_tavi_elective_join_vars |> # count(fyear) # count(lsoa21_bfit)
  filter(fyear != "2025/26") |> 
  left_join(lkp_icb, join_by(lsoa21_bfit == lsoa21cd)) |> 
  # colnames() |> 
  # mutate(site_name = str_c(site_name, "(", der_provider_site_code, ")")) |> 
  select(
    fyear, is_wkend, sex, age, site_name,
    tavi, imd_decile, rural_urban_classification,
    rgn22nm, cci, min_tavi_dist, sicbl25nm,
    any_prior_admission, score_frailty
  ) |>
  mutate(fyear = as.integer(str_sub(fyear, 6, 7)) - 10) |> 
  # mutate(is_wkend = as.factor(is_wkend)) |> 
  mutate(tavi = as.factor(tavi)) |> 
  # mutate(imd_decile = as.ordered(imd_decile)) |> 
  mutate(min_tavi_dist = round(min_tavi_dist/ 1e3, 1)) |>  
  mutate(covid_effect = as_factor(
    case_when(
      fyear == 10 ~ "19/20",
      fyear == 11 ~ "20/21",
      # fyear == 12 ~ "21/22",
      # fyear == 13 ~ "22/23",
      T ~ "none"
    )
  ))|>
  mutate(covid_effect = fct_relevel(covid_effect, "none")) |> 
  mutate(across(
    c(sex, rural_urban_classification, rgn22nm, sicbl25nm, imd_decile,
      any_prior_admission),
    ~ as.factor(.)
  ))


tmp_elective_plus <- tmp_elective |> 
  mutate(sex = as.character(sex)) |> 
  filter(sex %in% c("1", "2")) |> 
  mutate(sex = as.factor(sex)) |> 
  mutate(age_std = as.numeric(scale(age))) |> 
  mutate(cci_std = as.numeric(scale(cci))) |> 
  mutate(frailty_std = as.numeric(scale(score_frailty))) |>  
  mutate(distance_std = as.numeric(scale(min_tavi_dist))) |> 
  mutate(rural_urban_classification = as.character(rural_urban_classification)) |> 
  mutate(rural_urban_classification = case_when(
    str_detect(rural_urban_classification, "Urban") ~ "urban",
    str_detect(rural_urban_classification, "Larger") ~ "larger_rural",
    T ~ "smaller_rural"
  )) |> 
  mutate(rural_urban_classification = fct_relevel(
    rural_urban_classification, "urban"
    ))
  
tmp_elective_plus |>  
  count(rural_urban_classification, sort = T) |> 
  mutate(p = n/sum(n))

    
tmp_elective_plus |> glimpse()


# TODO LIST ---------------------------------------------------------------

# DONE: centre / scale variables age etc. cci frailty
# DONE: remove interaction cii year , frailty year
# DONE: smooths to linear cci (ULTIMATELY LINEAR TO SMOOTH BETTER)
# DONE: age by sex interaction.
# urban rural 
# DONE: do you even need frailty (or cci)
# check BIC



# 1. GREEDY MODEL ------------------------------------------------

mod_tavi_el_08 <- mgcv::gam(
  formula = tavi ~
    fyear*imd_decile +
    covid_effect +
    sex + s(age_std, by = sex) + ti(age_std, fyear) + s(cci_std) + ti(cci_std, fyear) + frailty_std*fyear + any_prior_admission +
    distance_std + rural_urban_classification + rgn22nm + # EMERG ONLY: is_wkend +
    # (RANDOM INTERCEPT): 
    s(sicbl25nm, bs = "re"),
  family = "binomial",
  method = "REML",
  data = tmp_elective_plus
)

mod_tavi_el_08 |> saveRDS(here("data_raw", "mod_tavi_el_08.rds"))
gc()
gc()
gc()

BIC(mod_tavi_el_08) # 54108.58

# 2. REMOVE INTERACTIONS WITH YEAR (EVOLUTION OF RISK/CODING) --------------

mod_tavi_el_09 <- mgcv::gam(
  formula = tavi ~
    fyear*imd_decile +
    covid_effect +
    sex + s(age_std, by = sex) + ti(age_std, fyear) + s(cci_std) + frailty_std + any_prior_admission +
    distance_std + rural_urban_classification + rgn22nm + # EMERG ONLY: is_wkend +
    # (RANDOM INTERCEPT): 
    s(sicbl25nm, bs = "re"),
  family = "binomial",
  method = "REML",
  data = tmp_elective_plus
)

mod_tavi_el_09 |> saveRDS(here("data_raw", "mod_tavi_el_09.rds"))
gc()
gc()
gc()

BIC(mod_tavi_el_09) # 08: 54108.58 09:  54099.95 (BETTER)

# 3. SMOOTH CCI TO LINEAR --------------

mod_tavi_el_10 <- mgcv::gam(
  formula = tavi ~
    fyear*imd_decile +
    covid_effect +
    sex + s(age_std, by = sex) + ti(age_std, fyear) + cci_std + frailty_std + any_prior_admission +
    distance_std + rural_urban_classification + rgn22nm + # EMERG ONLY: is_wkend +
    # (RANDOM INTERCEPT): 
    s(sicbl25nm, bs = "re"),
  family = "binomial",
  method = "REML",
  data = tmp_elective_plus
)

mod_tavi_el_10 |> saveRDS(here("data_raw", "mod_tavi_el_10.rds"))
gc()
gc()
gc()

BIC(mod_tavi_el_10) # 10: 54135.07  09:  54099.95 (WORSE - KEEP SMOOTH CCI)

# 4. LINEAR FRAILTY TO SMOOTH --------------

mod_tavi_el_11 <- mgcv::gam(
  formula = tavi ~
    fyear*imd_decile +
    covid_effect +
    sex + s(age_std, by = sex) + ti(age_std, fyear) + s(cci_std) + s(frailty_std) + any_prior_admission +
    distance_std + rural_urban_classification + rgn22nm + # EMERG ONLY: is_wkend +
    # (RANDOM INTERCEPT): 
    s(sicbl25nm, bs = "re"),
  family = "binomial",
  method = "REML",
  data = tmp_elective_plus
)
mod_tavi_el_11 |> saveRDS(here("data_raw", "mod_tavi_el_11.rds"))
gc()
gc()
gc()

BIC(mod_tavi_el_11) # 11: 53964.67  09:  54099.95 (BETTER - KEEP SMOOTH FRAILTY)

# 4. RM AGE SEX INTERACTION --------------

mod_tavi_el_12 <- mgcv::gam(
  formula = tavi ~
    fyear*imd_decile +
    covid_effect +
    sex + s(age_std) + ti(age_std, fyear) + s(cci_std) + s(frailty_std) + any_prior_admission + # 
    distance_std + rural_urban_classification + rgn22nm + # EMERG ONLY: is_wkend +
    # (RANDOM INTERCEPT): 
    s(sicbl25nm, bs = "re"),
  family = "binomial",
  method = "REML",
  data = tmp_elective_plus
)

# mod_tavi_el_12 |> saveRDS(here("data_raw", "mod_tavi_el_12.rds"))
mod_tavi_el_12 <-  readRDS(here("data_raw", "mod_tavi_el_12.rds"))
gc()
gc()
gc()

BIC(mod_tavi_el_12) #  53884.9 LOWEST SO FAR

# TODO COVID JUST 19/20 20/21

mod_tavi_el_12 |> 
  broom::tidy(parametric = T) |> 
  mutate(odds = exp(estimate)) |> 
  mutate(lci = exp(estimate - 1.96 * std.error)) |> 
  mutate(uci = exp(estimate + 1.96 * std.error)) |> 
  select(term, estimate, odds, lci, uci) |> 
  view("coeffs12")
