# 1. DECILE MODEL ------------------------------------------------

mod_svt_01 <- mgcv::gam(
  formula = ablation_24m ~
    yr * imd_decile +
    covid_effect +
    sex + s(age_std, by = sex) +
    distance_std + rural_urban_classification + rgn22nm + 
    # TODO recurrent_svt and n_prior use count SVT (prim_diag) admissions 
    # but there is some collinearity so picked n_prior
    # while lb_svt_prior counts diag in any position.
    n_prior_svt + ep_centre +
    s(cci_std) + 
    s(hfrs_std) + any_prior_admission +
    dx_af_any + dx_other_i47 +
    cm_hypertension + cm_ihd + cm_stroke_tia + cm_diabetes +
    cm_copd + cm_ckd + cm_valve_disease + cm_obesity +
    # (RANDOM INTERCEPT):
    s(sicbl25nm, bs = "re"),
  family = "binomial",
  method = "REML",
  data = df_svt_cleaned 
)
# 12:51 - 12:55
# 13:07 - 13:
Sys.time()
gc()
gc()



mod_svt_01 |> saveRDS(here("data_raw", "mod_svt_01.rds"))
# mod_svt_01  <- readRDS(here("data_raw", "mod_svt_01.rds"))

gc()
gc()
gc()

mod_svt_01 |> 
  broom::tidy(parametric = T) |> 
  mutate(odds = exp(estimate)) |> 
  mutate(lci = exp(estimate - 1.96 * std.error)) |> 
  mutate(uci = exp(estimate + 1.96 * std.error)) |> 
  select(term, estimate, odds, lci, uci) |> 
  view("coeffs_svt_01")

