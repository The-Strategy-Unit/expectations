# =====================================================================
# Marginal effects by year from a binomial GAM, with bootstrap CIs
#
# Model:  treatment_special ~ group + year + group*year
#         mgcv::gam(family = binomial, method = "REML")
#
# Two estimands, both computed by g-computation:
#   disparity : mean p(all Group A) - mean p(all Group B)      <- A vs B effect
#   policy    : mean p(all Group A) - mean p(observed groups)  <- population impact
#
# Uncertainty: (1) posterior simulation from the model    [fast, default]
#              (2) nonparametric case-resampling bootstrap [slow, optional]
# =====================================================================

library(tidyverse)
library(mgcv)
library("MASS", include.only = "mvrnorm")   # after dplyr: avoids masking select()

set.seed(2719)
R_SIMS <- 2000   # posterior draws
# R_BOOT <- 1000   # bootstrap resamples (only if you run section 5)


mod_afib_021 <-  read_rds(here("data_raw", "mod_afib_021.rds"))

# ---------------------------------------------------------------------
# 1. Data and model
# ---------------------------------------------------------------------
# Drop incomplete cases up front so the model frame and the prediction
# frame have identical rows — otherwise the yearly averaging misaligns.

dat <- df_afib_cleaned
# 
# dat |> vctrs::vec_size()
# dat |> drop_na(
#   yr, ablation_24m,
#   imd_top_quartile,
#     covid_effect,
#     sex, age_std,
#     distance_std , rgn22nm , #  , rural_urban_classification 
#     n_prior_dccv , lb_af_prior , ep_centre ,
#     cci_std , hfrs_std, any_prior_admission ,
#     post_castle_hf,
#     cm_hypertension , cm_ihd , cm_stroke_tia , cm_diabetes ,
#     cm_copd , cm_ckd , cm_valve_disease , cm_obesity ,
#     # (RANDOM INTERCEPT):
#     sicbl25nm
#   
#   ) |> vctrs::vec_size()
  
GRP_LEVELS <- levels(dat$imd_top_quartile)
stopifnot(length(GRP_LEVELS) == 2)

mod <- mod_afib_021


# ---------------------------------------------------------------------
# 2. Core machinery
# ---------------------------------------------------------------------
# `lpmatrix` gives X such that X %*% beta is the linear predictor. Building
# it once per counterfactual world means each of the 2000 draws is just a
# matrix multiply — seconds, not minutes.

lp_matrix <- function(model, data, set_group = NULL) {
  if (!is.null(set_group)) {
    data <- mutate(data, imd_top_quartile = factor(set_group, levels = GRP_LEVELS))
  }
  predict(model, newdata = data, type = "lpmatrix")
}

# Yearly contrasts for a single coefficient vector.
yearly_contrasts <- function(beta, Xp_A, Xp_B, Xp_obs, year) {
  tibble(
    year  = year,
    p_A   = plogis(as.vector(Xp_A   %*% beta)),
    p_B   = plogis(as.vector(Xp_B   %*% beta)),
    p_obs = plogis(as.vector(Xp_obs %*% beta))
  ) |>
    summarise(across(c(p_A, p_B, p_obs), mean), n = n(), .by = year) |>
    mutate(
      disparity = p_B - p_A,
      policy    = p_B - p_obs
    ) |>
    arrange(year) |> 
    identity()
}



Xp_A   <- lp_matrix(mod, dat, GRP_LEVELS[1])   # everyone -> Group A # ev1 -> lower 3 quart
Xp_B   <- lp_matrix(mod, dat, GRP_LEVELS[2])   # everyone -> Group B # ev1 -> upper quart
Xp_obs <- lp_matrix(mod, dat)                  # observed membership

point_est <- yearly_contrasts(coef(mod), Xp_A, Xp_B, Xp_obs, dat$yr)

# Sanity check: mean(p_obs) should reproduce the observed treatment rate
# almost exactly. If it doesn't, the counterfactual frames are misaligned.
dat |> #colnames()
  summarise(observed = mean(ablation_24m), .by = yr) |>
  left_join(dplyr::select(point_est, year, p_obs), join_by(yr == year)) |>
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

beta_draws <- mvrnorm(R_SIMS, mu = coef(mod), Sigma = V)

sim_draws <- seq_len(R_SIMS) |>
  map(\(i) yearly_contrasts(beta_draws[i, ], Xp_A, Xp_B, Xp_obs, dat$yr) |>
        mutate(.draw = i)) |>
  list_rbind()

summarise_draws <- function(draws, method) {
  draws |>
    pivot_longer(c(disparity, policy, p_A, p_B, p_obs),
                 names_to = "estimand", values_to = "value") |>
    summarise(
      lower = quantile(value, 0.025, names = FALSE),
      upper = quantile(value, 0.975, names = FALSE),
      .by   = c(year, estimand)
    ) |>
    mutate(method = method)
}

results_sim <- point_est |>
  pivot_longer(c(disparity, policy, p_A, p_B, p_obs),
               names_to = "estimand", values_to = "estimate") |>
  left_join(summarise_draws(sim_draws, "simulation"), by = c("year", "estimand"))


# ---------------------------------------------------------------------
# 4. Reading the numbers back out
# ---------------------------------------------------------------------
# Risk differences are in probability points. Multiplying by that year's
# attendances turns them into patients, which is usually the more
# persuasive framing.

tmp_000 <- results_sim |> #count(estimand)
  filter(estimand %in% c("p_obs" , "p_B", "policy")) |> # "disparity"
  mutate(
    across(c(estimate, lower, upper), \(x) x * 100, .names = "{.col}_pp"),
    patients = estimate * n,
    patients_lower = lower*n,
    patients_upper = upper*n,
  ) |>
  dplyr::select(year, estimand, estimate_pp, lower_pp, upper_pp, n, contains("patients")) |>
  arrange(estimand, year) |>
  print(n = )



# ---------------------------------------------------------------------
# 5. Case-resampling bootstrap  (optional — refits the GAM R_BOOT times)
# ---------------------------------------------------------------------
# Slower, but it also carries sampling variability in the *composition* of
# each year (the mix of A and B), which is genuinely part of the `policy`
# estimand. Stratify so no resample loses a group-within-year cell.

run_case_bootstrap <- FALSE   # flip to TRUE to run

if (run_case_bootstrap) {
  library("rsample")
  
  dat_strata <- mutate(dat, .strata = paste(group, year, sep = "_"))
  
  boot_one <- function(split) {
    d <- rsample::analysis(split)
    m <- tryCatch(
      gam(treatment_special ~ group + year + group * year,
          family = binomial, method = "REML", data = d),
      error = function(e) NULL
    )
    if (is.null(m)) return(NULL)
    yearly_contrasts(
      coef(m),
      lp_matrix(m, d, GRP_LEVELS[1]),
      lp_matrix(m, d, GRP_LEVELS[2]),
      lp_matrix(m, d),
      d$year
    )
  }
  
  boot_draws <- bootstraps(dat_strata, times = R_BOOT, strata = .strata) |>
    pull(splits) |>
    map(boot_one, .progress = TRUE) |>
    compact() |>
    list_rbind(names_to = ".draw")
  
  results_boot <- point_est |>
    pivot_longer(c(disparity, policy, p_A, p_B, p_obs),
                 names_to = "estimand", values_to = "estimate") |>
    left_join(summarise_draws(boot_draws, "bootstrap"), by = c("year", "estimand"))
}


# ---------------------------------------------------------------------
# 6. Plots
# ---------------------------------------------------------------------
results <- results_sim   # or results_boot

SERIES_1 <- "#2a78d6"   # blue
SERIES_2 <- "#eb6834"   # orange
INK_2    <- "#52514e"
GRID     <- "#e4e3df"

theme_me <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(colour = GRID, linewidth = 0.3),
    axis.title       = element_text(colour = INK_2),
    plot.title       = element_text(face = "bold"),
    plot.subtitle    = element_text(colour = INK_2),
    strip.text       = element_text(face = "bold", hjust = 0),
    legend.position  = "top",
    legend.title     = element_blank()
  )

# --- Panel 1: predicted probability under each counterfactual world ----
p_levels <- results |>
  filter(estimand %in% c("p_A", "p_B")) |>
  mutate(grp = if_else(estimand == "p_A", GRP_LEVELS[1], GRP_LEVELS[2]))

plot_levels <- ggplot(p_levels, aes(year, estimate, colour = grp, fill = grp)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.15, colour = NA) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  scale_colour_manual(values = setNames(c(SERIES_1, SERIES_2), GRP_LEVELS)) +
  scale_fill_manual(values   = setNames(c(SERIES_1, SERIES_2), GRP_LEVELS)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(
    title    = "Predicted probability of special treatment",
    subtitle = "Model-predicted rate if the whole clinic population were in each group",
    x = NULL, y = "Predicted probability"
  ) +
  theme_me

# --- Panel 2: the two contrasts, faceted -------------------------------
p_contrasts <- results |>
  filter(estimand %in% c("policy")) |>
  mutate(estimand = factor(
    estimand,
    levels = c("policy"),
    labels = c(
      paste0("All ", GRP_LEVELS[2], " − observed mix  (population impact)")
    )
  ))

plot_contrasts <- ggplot(p_contrasts, aes(year, estimate)) +
  geom_hline(yintercept = 0, colour = INK_2, linewidth = 0.4) +
  geom_ribbon(aes(ymin = lower, ymax = upper), fill = SERIES_1, alpha = 0.15) +
  geom_line(colour = SERIES_1, linewidth = 0.8) +
  geom_point(colour = SERIES_1, size = 2) +
  facet_wrap(~estimand, ncol = 1, scales = "free_y") +
  scale_y_continuous(labels = scales::label_percent(accuracy = 0.1, suffix = " pp")) +
  labs(
    title    = "Marginal effect of group membership, by year",
    subtitle = "Risk difference in probability points, with 95% intervals",
    x = NULL, y = "Difference in P(special treatment)"
  ) +
  theme_me

plot_levels
plot_contrasts

# ggsave("marginal_effects_levels.png",    plot_levels,    width = 8, height = 5, dpi = 300)
# ggsave("marginal_effects_contrasts.png", plot_contrasts, width = 8, height = 7, dpi = 300)