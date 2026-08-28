

# 1. AMEs for mod 02 ---------------------------------------------------------


# mod_afib_02 <- readRDS(here("data_raw", "mod_afib_02.rds"))
mod_afib_02 <- readRDS(here("data_raw", "mod_afib_02.rds"))

df_all_top <- df_afib_cleaned |> mutate(imd_top_quartile = as_factor("1"))

df_compare_predictions <- df_afib_cleaned |> 
  mutate(pred = predict(mod_afib_02, newdata = df_afib_cleaned, type ="response")) |> 
  mutate(pred_all_top = predict(mod_afib_02, newdata = df_all_top, type ="response"))

# ON AVERAGE: 10% MORE ABLATIONS EACH YEAR IF
# ALL HAD EXPECTATIONS EQUAL TO THAT OF LEAST DEPRIVED QUARTILE?
df_compare_predictions |> summarise((mean(pred_all_top) - mean(pred))/mean(pred))

# TODO CONFINTERVALS
# TODO CONFINTERVALS
# TODO CONFINTERVALS
# TODO CONFINTERVALS
# TODO CONFINTERVALS

# difference for those that were
# top ceategory - predicted and cf. 
# two panels - top quartile, predicted,  LQ predicted and countefactual. 
# two lines difference .

# Rate traject pred, cf . Number trajectories, pred cf, by group. 
# Differences by cf, 


tmp_002 <- df_compare_predictions |> 
  mutate(diff = pred_all_top - pred) |> 
  # group_by(yr, imd_top_quartile) |> #
  group_by(yr) |>
  summarise(
    # n_att = n(),
    # n_abl = sum(ablation_24m),
    n_abl_fit = mean(pred)*n(),
    n_abl_top = mean(pred_all_top)*n(),
    n_margin = mean(diff)*n(),
    # obs_rate = sum(ablation_24m)/n(),
    fit_rate = mean(pred),
    if_top_rate = mean(pred_all_top),
    margin_rate = mean(diff)
    ) |> 
  ungroup() |> 
  # mutate(p_increase = margin_rate / fit_rate)
  identity()

tmp_002 |> select(margin_rate)

# RATES:
tmp_002 |> 
  select(yr, contains("imd"), margin_rate, fit_rate, if_top_rate) |> 
  # select(yr, imd_top_quartile, margin_rate, fit_rate, if_top_rate) |> 
  pivot_longer(cols = c(contains("rate"), contains("imd")), names_to = "metric", values_to = "rate") |> 
  ggplot(aes(yr, rate, colour = metric))+
  geom_line()+
  theme_minimal()+
  geom_blank(aes(y=0))+
  ylab("Rate of ablations\n")+
  # facet_wrap(vars(imd_top_quartile))+
  NULL
  # ylab("AME of top quartile IMD membership on whether patient has ablation\n")
  
# NUMBERS:
tmp_002 |> 
  select(yr, contains("imd"), n_margin, n_abl_fit, n_abl_top) |> 
  # select(yr, imd_top_quartile, n_margin, n_abl_fit, n_abl_top) |> 
  pivot_longer(cols = c(contains("n_"), contains("imd")), names_to = "metric", values_to = "n") |> 
  ggplot(aes(yr, n, colour = metric))+
  geom_line()+
  theme_minimal()+
  geom_blank(aes(y=0))+
  ylab("Number of ablations\n")+
  facet_wrap(vars(str_detect(metric, "margin")), ncol = 1, scales = "free_y")+
  NULL
# THEORY - ABL - EXPECTATIONS IN A CLINICALLY CLEAN WORLD. 

# WITH CONFINT -------------------------------------------------------------------------

tmp_000 |> 
  # count(estimand)
  select(-n) |> 
  # select(yr, contains("imd"), margin_rate, fit_rate, if_top_rate) |> 
  # select(yr, imd_top_quartile, margin_rate, fit_rate, if_top_rate) |> 
  pivot_longer(cols = c(contains("_pp"), contains("patients")), names_to = "metric", values_to = "value") |> 
  filter(!str_detect(metric, "patients")) %>%
  ggplot()+
  geom_line(
    data = . %>% filter(metric == "estimate_pp"),
    aes(year, value, colour = estimand)
    )+
  geom_ribbon(
    data = . %>% 
      filter(estimand == "p_obs") %>%
      pivot_wider(names_from = metric, values_from = value),
    aes(year, ymin = lower_pp, ymax = upper_pp),
    alpha = 0.15, 
    colour = NA
    ) +
  geom_ribbon(
    data = . %>% 
      filter(estimand == "p_B") %>%
      pivot_wider(names_from = metric, values_from = value),
    aes(year, ymin = lower_pp, ymax = upper_pp),
    alpha = 0.15, 
    colour = NA
    ) +
  geom_ribbon(
    data = . %>%
      filter(estimand == "policy") %>%
      pivot_wider(names_from = metric, values_from = value),
    aes(year, ymin = lower_pp, ymax = upper_pp),
    alpha = 0.15,
    colour = NA
    ) +
  theme_minimal()
  geom_blank(aes(y=0))+
  ylab("Rate of ablations\n")+
  # facet_wrap(vars(imd_top_quartile))+
  NULL

# -------------------------------------------------------------------------

#   # select(year_quarter, pred, pred_cf)
#   # mutate(across(starts_with("pred"), ~ if_else(. >= .5, 1, 0))) |> 
#   group_by(yr) |> 
#   summarise(
#     att = n(), 
#     actual_abl24 = sum(as.integer(as.character(ablation_24m))),
#     pred_abl24 = sum(pred),
#     pred_abl24_cf = sum(pred_cf),
#     diff = sum(pred_cf) - sum(pred) 
#   ) |> 
#   print(n=50)
#   # saveRDS(here("data", "260126_dfq_compare_numbers_adm.rds"))
# 
# library("marginaleffects")
# 
# 
# # BUT THIS IS FOR A TO B COMPARISON RATHER THAN CF POLICY SCENARIO#
# # WILL WE NEED TO BOOTSTRAP MANUALLY?
# tmp_predictions <- marginaleffects::avg_predictions(mod_afib_02, variables = "imd_top_quartile", by = "yr")
# Sys.time() # 2:44 - 3:03 TAKES AROUND 20 MINS
# marginaleffects::avg_comparisons(mod_afib_02, variables = "imd_top_quartile", by = "yr")
# 
# 
# df_afib_cleaned |> 
#   count(yr, ablation_24m) |> 
#   filter(ablation_24m == 1)

# -------------------------------------------------------------------------

# mod_afib_01 <- readRDS(here("data_raw", "mod_afib_01.rds"))
# mod_afib_01a <- readRDS(here("data_raw", "mod_afib_01a.rds"))

df_all_top_dec <- df_afib_cleaned |> mutate(imd_decile = as_factor("10"))

df_compare_predictions_mod_01a <- df_afib_cleaned |> 
  mutate(pred = predict(mod_afib_01a, newdata = df_afib_cleaned, type ="response")) |> 
  mutate(pred_all_top_dec = predict(mod_afib_01a, newdata = df_all_top_dec, type ="response"))


tmp_001a <- df_compare_predictions_mod_01a |> 
  mutate(diff = pred_all_top_dec - pred) |> 
  # group_by(yr, imd_top_quartile) |> #
  group_by(yr, imd_decile) |> #
  # group_by(yr) |>
  summarise(
    n_att = n(),
    n_abl = sum(ablation_24m),
    n_abl_fit = mean(pred)*n(),
    n_abl_top = mean(pred_all_top_dec)*n(),
    n_margin = mean(diff)*n(),
    obs_rate = sum(ablation_24m)/n(),
    fit_rate = mean(pred), 
    if_top_rate = mean(pred_all_top_dec), 
    margin_rate = mean(diff)
  ) |> 
  ungroup() |> 
  # mutate(p_increase = margin_rate / fit_rate)
  identity()

tmp_001a |> 
  select(yr, imd_decile, contains("rate")) |> 
  # select(yr, imd_top_quartile, n_margin, n_abl_fit, n_abl_top) |> 
  pivot_longer(cols = 3:6, names_to = "metric", values_to = "n") |> 
  filter(metric == "margin_rate") |> 
  ggplot(aes(yr, n, colour = metric))+
  geom_line()+
  theme_minimal()+
  theme(legend.position = "bottom")+
  geom_blank(aes(y=0))+
  ylab("PP increase in rate of ablations\n")+
  facet_wrap(vars(imd_decile), nrow = 1)+ # , ncol = 1, scales = "free_y"
  NULL


