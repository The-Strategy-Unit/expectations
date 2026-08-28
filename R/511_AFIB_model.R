

# 1. ORIGINAL (DECILE) MODEL -------------------------------------------------------

mod_afib_01 <- mgcv::gam(
  formula = ablation_24m ~
    yr * imd_decile +
    covid_effect +
    sex + s(age_std, by = sex) +
    # ti(age_std, yr) + ti(cci_std, yr) 
    distance_std + rural_urban_classification + rgn22nm + 
    n_prior_dccv + lb_af_prior + ep_centre +
    s(cci_std) + s(hfrs_std) + any_prior_admission +
    # cm_hf_any * post_castle +
    cm_hypertension + cm_ihd + cm_stroke_tia + cm_diabetes +
    cm_copd + cm_ckd + cm_valve_disease + cm_obesity +
    cm_hf_specified + cm_hf_unspecified +
    # (RANDOM INTERCEPT):
    s(sicbl25nm, bs = "re"),
  family = "binomial",
  method = "REML",
  data = df_afib_cleaned_2 
)
# STARTED 9:28
Sys.time()

# mod_afib_01 |> saveRDS(here("data_raw", "mod_afib_01.rds"))
mod_afib_01  <- readRDS(here("data_raw", "mod_afib_01.rds"))
gc()
gc()
gc()

mod_afib_01 |> 
  broom::tidy(parametric = T) |> 
  mutate(odds = exp(estimate)) |> 
  mutate(lci = exp(estimate - 1.96 * std.error)) |> 
  mutate(uci = exp(estimate + 1.96 * std.error)) |> 
  select(term, estimate, odds, lci, uci) |> 
  view("coeffs_afib_01")




# 2. ORIGINAL (DECILE) MODEL + UPDATED VARIABLES --------------------------

mod_afib_01a <- mgcv::gam(
  formula = ablation_24m ~
    yr * imd_decile +
    covid_effect +
    sex + s(age_std, by = sex) +
    distance_std + rural_urban_classification + rgn22nm + 
    n_prior_dccv + lb_af_prior + ep_centre +
    s(cci_std) + s(hfrs_std) + any_prior_admission +
    post_castle_hf +
    cm_hypertension + cm_ihd + cm_stroke_tia + cm_diabetes +
    cm_copd + cm_ckd + cm_valve_disease + cm_obesity +
    # (RANDOM INTERCEPT):
    s(sicbl25nm, bs = "re"),
  family = "binomial",
  method = "REML",
  data = df_afib_cleaned 
)

# mod_afib_01a |> saveRDS(here("data_raw", "mod_afib_01a.rds"))
mod_afib_01a  <- readRDS(here("data_raw", "mod_afib_01a.rds"))
gc()
gc()
gc()

mod_afib_01a |> 
  broom::tidy(parametric = T) |> 
  mutate(odds = exp(estimate)) |> 
  mutate(lci = exp(estimate - 1.96 * std.error)) |> 
  mutate(uci = exp(estimate + 1.96 * std.error)) |> 
  select(term, estimate, odds, lci, uci) |> 
  view("coeffs_afib_01a")


# 3. FIRST AMENDMENT -----------------------------------------------------

# 1.CONCEPTUALLY 
# HF_ANY * POST CASTLE - NOT FOR EVERYBODY. POST-CASTLE ONLY TAKES VALUE WHEN HF == 1  
# COVID 20/21 ONLY
# TAKE OUT INT WITH SEX
# REMOVE RURAL URB.

# OPTIONS FOR IMD:
# IMD BINARY  - 7.5 8910 (QUARTILE) HIGHEST QUARTILE VS.  OTHERS
# LINEAR -
# LEVELS 

# WHAT WOULD HAVE HAPPENED IF ALL HAD EXPECTATIONS LEVELS SIMILAR TO THOSE WITH HIGH EXPECTATIONS

mod_afib_02 <- mgcv::gam(
  formula = ablation_24m ~
    yr * imd_top_quartile +
    covid_effect +
    sex + s(age_std) +  # , by = sex
    # ti(age_std, yr) + ti(cci_std, yr) 
    distance_std + rgn22nm + #  + rural_urban_classification 
    n_prior_dccv + lb_af_prior + ep_centre +
    s(cci_std) + s(hfrs_std) + any_prior_admission +
    post_castle_hf +
    cm_hypertension + cm_ihd + cm_stroke_tia + cm_diabetes +
    cm_copd + cm_ckd + cm_valve_disease + cm_obesity +
    # (RANDOM INTERCEPT):
    s(sicbl25nm, bs = "re"),
  family = "binomial",
  method = "REML",
  data = df_afib_cleaned 
)
# 3:33
# 3:49
Sys.time()
gc()
gc()
gc()
# mod_afib_02 |> saveRDS(here("data_raw", "mod_afib_02.rds"))
mod_afib_02 <- readRDS(here("data_raw", "mod_afib_02.rds"))
gc()
gc()
gc()


mod_afib_02 |> 
  broom::tidy(parametric = T) |> 
  mutate(odds = exp(estimate)) |> 
  mutate(lci = exp(estimate - 1.96 * std.error)) |> 
  mutate(uci = exp(estimate + 1.96 * std.error)) |> 
  select(term, estimate, odds, lci, uci) |> 
  view("coeffs_afib_02")



mgcv::plot.gam(mod_afib_02, pages = 1)


# 4. -------------------------------------------------------------------------
# ADJUST FIRST AMENDMENT TO CHECK THAT THE SMOOTH GROWTH IMPOSED BY 
# LINEAR RELATIONSHIP IS NOT OBSCURING GROWTH THAT IS CONCENTRATED IN SOME YEARS 


mod_afib_02a <- mgcv::gam(
  formula = ablation_24m ~
    s(yr, by = imd_top_quartile) + imd_top_quartile +
    covid_effect +
    sex + s(age_std) +  # , by = sex
    # ti(age_std, yr) + ti(cci_std, yr) 
    distance_std + rgn22nm + #  + rural_urban_classification 
    n_prior_dccv + lb_af_prior + ep_centre +
    s(cci_std) + s(hfrs_std) + any_prior_admission +
    post_castle_hf +
    cm_hypertension + cm_ihd + cm_stroke_tia + cm_diabetes +
    cm_copd + cm_ckd + cm_valve_disease + cm_obesity +
    # (RANDOM INTERCEPT):
    s(sicbl25nm, bs = "re"),
  family = "binomial",
  method = "REML",
  data = df_afib_cleaned 
)

gc()
gc()
gc()
gc()

mod_afib_02a |> 
  broom::tidy(parametric = T) |> 
  mutate(odds = exp(estimate)) |> 
  mutate(lci = exp(estimate - 1.96 * std.error)) |> 
  mutate(uci = exp(estimate + 1.96 * std.error)) |> 
  select(term, estimate, odds, lci, uci) |> 
  view("coeffs_afib_02a")

# BIC comparisons ---------------------------------------------------------

BIC(mod_afib_01)
BIC(mod_afib_01a)
BIC(mod_afib_02) # MODEL 2 IS BETTER EXPLANATORY
BIC(mod_afib_02a)

AIC(mod_afib_01)
AIC(mod_afib_01a)
AIC(mod_afib_02) # MODEL 2 IS WORSE AS PREDICTIVE MODEL
AIC(mod_afib_02a)


# MISCELLANEOUS -----------------------------------------------------------

# DAYS TO ABLATION CHANGES ACROSS YEARS. 
df_afib_join_tables_scored |> 
  # colnames()
  group_by(yr) |> 
  summarise(md = median(days_to_ablation, na.rm = T), mn = mean(days_to_ablation, na.rm = T)) |> 
  pivot_longer(cols = c(md, mn), names_to = "av", values_to = "days_to_ablation") |> 
  ggplot(aes(yr, days_to_ablation, colour = av))+
  geom_hline(yintercept = 730, lty = "dashed")+
  geom_line()+
  geom_blank(aes(y=0))+
  theme_minimal()

# DAYS TO ABLATION DOESN'T CHANGE MUCH BY IMD, ACROSS YEARS
df_afib_join_tables_scored |> 
  group_by(yr, imd_decile) |> 
  summarise(md = median(days_to_ablation, na.rm = T), mn = mean(days_to_ablation, na.rm = T)) |> 
  ungroup() |> 
  ggplot(aes(yr, md, colour = as.factor(imd_decile)))+
  geom_hline(yintercept = 730, lty = "dashed")+
  geom_line()+
  geom_blank(aes(y=0))+
  theme_minimal()



# WHY DOES REGION HAVE SUCH A STRONG EFFECT? NUMBER PER REGION?
# SITE, SUB_ICB , REGION ??