
set.seed(2641)
R_SIMS <- 2000   # posterior draws


dat <- tmp_elective_plus

GRP_LEVELS <- levels(dat$imd_decile)
stopifnot(length(GRP_LEVELS) == 10)

mod <- mod_tavi_el_13


# ---------------------------------------------------------------------
# 2. Core machinery
# ---------------------------------------------------------------------
# `lpmatrix` gives X such that X %*% beta is the linear predictor. Building
# it once per counterfactual world means each of the 2000 draws is just a
# matrix multiply — seconds, not minutes.

lp_matrix <- function(model, data, set_group = NULL) {
  if (!is.null(set_group)) {
    data <- mutate(data, imd_decile = factor(set_group, levels = GRP_LEVELS))
  }
  predict(model, newdata = data, type = "lpmatrix")
}

# Yearly contrasts for a single coefficient vector.
yearly_contrasts <- function(beta, Xp_A, Xp_obs, year) {
  tibble(
    year  = year,
    p_A   = plogis(as.vector(Xp_A   %*% beta)),
    p_obs = plogis(as.vector(Xp_obs %*% beta))
  ) |>
    summarise(across(c(p_A, p_obs), mean), n = n(), .by = year) |>
    mutate(
      policy    = p_A - p_obs
    ) |>
    arrange(year) |> 
    identity()
}


Xp_A   <- lp_matrix(mod, dat, GRP_LEVELS[10])   # everyone -> IMD 10 (LEAST DEPRIVED)
# Xp_B   <- lp_matrix(mod, dat, GRP_LEVELS[2])   # everyone -> Group B # ev1 -> upper quart
Xp_obs <- lp_matrix(mod, dat)                  # observed membership

point_est <- yearly_contrasts(coef(mod), Xp_A, Xp_obs, dat$fyear)

# Sanity check: mean(p_obs) should reproduce the observed treatment rate
# almost exactly. If it doesn't, the counterfactual frames are misaligned.
dat |> # colnames()
  mutate(tavi = as.integer(as.character(tavi))) |>
  summarise(observed = mean(tavi), .by = fyear) |>
  left_join(dplyr::select(point_est, year, p_obs), join_by(fyear == year)) |>
  mutate(diff = observed - p_obs) |>
  print(n = )


# ---------------------------------------------------------------------
# 3. Posterior simulation CIs  (recommended default)
# ---------------------------------------------------------------------
# Draw coefficient vectors from MVN(coef, vcov) and push each one all the
# way through the g-computation. This propagates coefficient uncertainty
# while holding the covariate distribution fixed.

V <- tryCatch(
  vcov(mod, unconditional = TRUE),   # smoothing-parameter-corrected, if available
  error = function(e) vcov(mod)
)

beta_draws <- MASS::mvrnorm(R_SIMS, mu = coef(mod), Sigma = V)

sim_draws <- seq_len(R_SIMS) |>
  map(\(i) yearly_contrasts(beta_draws[i, ], Xp_A, Xp_obs, dat$fyear) |>
        mutate(.draw = i)) |>
  list_rbind()

summarise_draws <- function(draws, method) {
  draws |>
    pivot_longer(c(policy, p_A, p_obs),
                 names_to = "estimand", values_to = "value") |>
    summarise(
      lower = quantile(value, 0.025, names = FALSE),
      upper = quantile(value, 0.975, names = FALSE),
      .by   = c(year, estimand)
    ) |>
    mutate(method = method)
}

results_sim <- point_est |>
  pivot_longer(c(policy, p_A, p_obs),
               names_to = "estimand", values_to = "estimate") |>
  left_join(summarise_draws(sim_draws, "simulation"), by = c("year", "estimand"))


# ---------------------------------------------------------------------
# 4. Reading the numbers back out
# ---------------------------------------------------------------------
# Risk differences are in probability points. Multiplying by that year's
# attendances turns them into patients, which is usually the more
# persuasive framing.

tmp_001a <- results_sim |> 
  mutate(
    # across(c(estimate, lower, upper), \(x) x * 100, .names = "{.col}_pp"),
    patients = estimate * n,
    patients_lower = lower*n,
    patients_upper = upper*n,
  ) |>
  # dplyr::select(year, estimand, contains("_pp"), n, contains("patients")) |>
  arrange(estimand, year) |>
  print(n = )



tmp_001a |> 
  # count(estimand)
  select(-n) |> 
  # select(yr, contains("imd"), margin_rate, fit_rate, if_top_rate) |> 
  # select(yr, imd_top_quartile, margin_rate, fit_rate, if_top_rate) |> 
  pivot_longer(cols = c(estimate, lower, upper, contains("patients")), names_to = "metric", values_to = "value") |> 
  filter(!str_detect(metric, "patients")) %>%
  ggplot()+
  geom_line(
    data = . %>% filter(metric == "estimate_pp"),
    aes(year, value, colour = estimand)
  )+
  # geom_ribbon(
  #   data = . %>% 
  #     filter(estimand == "p_obs") %>%
  #     pivot_wider(names_from = metric, values_from = value),
  #   aes(year, ymin = lower_pp, ymax = upper_pp),
  #   alpha = 0.15, 
  #   colour = NA
  # ) +
  # geom_ribbon(
  #   data = . %>% 
  #     filter(estimand == "p_B") %>%
  #     pivot_wider(names_from = metric, values_from = value),
  #   aes(year, ymin = lower_pp, ymax = upper_pp),
  #   alpha = 0.15, 
  #   colour = NA
  # ) +
  geom_ribbon(
    data = . %>%
      filter(estimand == "policy") %>%
      pivot_wider(names_from = metric, values_from = value),
    aes(year, ymin = lower, ymax = upper),
    alpha = 0.15,
    colour = NA
  ) +
  theme_minimal()+
  geom_blank(aes(y=0))+
  ylab("Rate of ablations\n")+
  facet_wrap(vars(imd_decile))+
  NULL

tmp_001a |> 
  # count(estimand)
  select(-n) |> 
  # select(yr, contains("imd"), margin_rate, fit_rate, if_top_rate) |> 
  # select(yr, imd_top_quartile, margin_rate, fit_rate, if_top_rate) |> 
  pivot_longer(cols = c(contains("_pp"), contains("patients")), names_to = "metric", values_to = "value") |> 
  filter(!str_detect(metric, "_pp")) %>%
  ggplot()+
  geom_line(
    data = . %>% filter(metric == "patients"),
    aes(year, value, colour = estimand)
  )+
  # geom_ribbon(
  #   data = . %>% 
  #     filter(estimand == "p_obs") %>%
  #     pivot_wider(names_from = metric, values_from = value),
  #   aes(year, ymin = lower_pp, ymax = upper_pp),
  #   alpha = 0.15, 
  #   colour = NA
  # ) +
  # geom_ribbon(
  #   data = . %>% 
  #     filter(estimand == "p_B") %>%
  #     pivot_wider(names_from = metric, values_from = value),
  #   aes(year, ymin = lower_pp, ymax = upper_pp),
  #   alpha = 0.15, 
  #   colour = NA
  # ) +
  geom_ribbon(
    data = . %>%
      filter(estimand == "policy") %>%
      pivot_wider(names_from = metric, values_from = value),
    aes(year, ymin = patients_lower  , ymax = patients_upper),
    alpha = 0.15,
    colour = NA
  ) +
  theme_minimal()+
  geom_blank(aes(y=0))+
  ylab("Number of ablations\n")+
  # facet_wrap(vars(imd_top_quartile))+
  NULL


