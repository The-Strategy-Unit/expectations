# TODO 

# IF SOMEONE IS UNDERGOING A PLASTIC REPAIR OF AN AORTIC VALVE
# AS ALL OUR COHORT DO. THEN THEY HAVE TO BE AT A CARDIO THORACIC 
# SPECIALIST CENTRE, MOST OF WHICH WILL PROVIDE TAVIS - SOME DON'T.

# TREATED POPN ASSUMES ALL GET TO TREATMENT
# THERE MAY BE EXPECTATIONS / ATTITUDES THAT MEAN SOME DON'T 
# GET TO THAT STAGE.
# BUT MOST WILL GO TO GP - DUE TO NEED (AORTIC VALVE STENOSIS) SERIOUS - AND GET ON A 
# PATHWAY..

# EXPECTATIONS IS ALMOST SOLELY ABOUT HOW THESE PATIENTS
# INFLUENCE THE MDT TEAM - TO GO WITH TAVI OR NOT.
# AND THEN WE'D EXTRAPOLATE ABOUT HOW THIS WOULD WORK AT 
# EARLIER STAGES OF THE PATHWAY, AND DIFFERENT PROCS..

# WE WILL NEED TO CONTROL FIERCELY FOR COMORBIDITIES AND 
# MAYBE SEPARATE OUT THE HEART COMORBIDITIES. AS THERE ARE 
# IMPORTANT CLINICAL REASONS WHY PATIENT MAY BE AUTO 
# DISQUALIFIED FOR TAVI.
#

df_tavi_emergency_join_vars |> 
  filter(fyear == "2015/16") |>
  # filter(tavi_superspell == 0) |>
  count(tavi_superspell, fyear, imd_decile, sort = T) |> 
  tail(6)


# SUMMARY OF MODEL VARS
df_tavi_emergency_join_vars |> count(tavi_superspell)
df_tavi_emergency_join_vars |> count(tavi_spell)
df_tavi_emergency_join_vars |> count(fyear)

df_tavi_emergency_join_vars |> 
  count(fyear, tavi_superspell) |> 
  pivot_wider(names_from = tavi_superspell, values_from = n) |> 
  rowwise() |> 
  mutate(total = sum(c_across(`0`:`1`))) |>
  ungroup()

df_tavi_emergency_join_vars |> count(imd_decile)

df_tavi_emergency_join_vars |> ggplot(aes(age)) + geom_histogram()
df_tavi_emergency_join_vars |> count(sex)
df_tavi_emergency_join_vars |> ggplot(aes(cci)) + geom_histogram(binwidth = 1)


df_tavi_emergency_join_vars |> count(tavi_centre)
df_tavi_emergency_join_vars |> count(der_provider_site_code, sort = T)

df_tavi_emergency_join_vars |> 
  count(site_name, tavi_centre, sort = T) |> 
  tail(19)




df_tavi_emergency_join_vars |> count(der_provider_site_code, sort = T) |> ggplot(aes(n)) + geom_histogram()
# 51 SITES GREATER THAN 4 ADMISSIONS IN AT LEAST ONE YEAR. (182 IS MAX)
df_tavi_emergency_join_vars |> 
  count(fyear, site_name, tavi_centre, sort = T) |>
  filter(n > 4 | tavi_centre == 1) |>
  # distinct(site_name) |> 
  tail(19)

df_tavi_emergency_join_vars |> 
  count(fyear, site_name, tavi_centre, sort = T) |>
  filter(n < 4) |>
  filter(tavi_centre ==0)
# GROUP OTHER.
# THEY SHOULD ALL BE 
df_tavi_emergency_join_vars |> count(der_provider_site_code, sort = T) |>  filter(n > 4) |> tail()

df_tavi_emergency_join_vars |> count(is.na(min_tavi_dist)| min_tavi_dist< 0)
df_tavi_emergency_join_vars |> ggplot(aes(min_tavi_dist/1000)) + geom_density()+facet_wrap(vars(fyear))
df_tavi_emergency_join_vars |> count(rgn22nm)
df_tavi_emergency_join_vars |> count(rural_urban_classification)

df_tavi_emergency_join_vars |> count(is_wkend)

# SENSITIVITY:
# cut out earlier years where nos low.
df_tavi_emergency_join_vars |> count(fyear, tavi_superspell) |> filter(tavi_superspell == 1)
# ethnic_group
df_tavi_emergency_join_vars |> count(is.na(ethnic_group))
# admission_time
df_tavi_emergency_join_vars |> count(is.na(admission_time)) |> mutate(p = n/sum(n))

# df_tavi_emergency_join_vars |> saveRDS(here("data_raw", "df_tavi_emergency_join_vars.rds"))
df_tavi_emergency_join_vars <- readRDS(here("data_raw", "df_tavi_emergency_join_vars.rds"))


tmp_01 <- df_tavi_emergency_join_vars |> 
  # colnames() |> 
  mutate(site_name = str_c(site_name, "(", der_provider_site_code, ")")) |> 
  select(
    fyear, is_wkend, sex, age, site_name,
    tavi = tavi_superspell, imd_decile, rural_urban_classification, 
    rgn22nm, cci, min_tavi_dist
    ) |> 
  mutate(fyear = as.integer(str_sub(fyear, 6, 7)) - 10) |> 
  mutate(is_wkend = as.factor(is_wkend)) |> 
  mutate(tavi = as.factor(tavi)) |> 
  mutate(imd_decile = as.ordered(imd_decile)) |> 
  mutate(min_tavi_dist = round(min_tavi_dist/ 1e3, 1)) |>  
  # glimpse()
  identity()

gc()
gc()
gc()
  
# TODO GROUP LOWER FREQUENCY SITES

mgcv::gam(
  formula = tavi ~
    # VAR OF INTEREST:
    fyear*imd_decile +
    # NEED:
    s(age, by = sex) + sex + s(cci) +
    # SUPPLY / ACCESS:
    min_tavi_dist + rural_urban_classification + rgn22nm + is_wkend +
    # PROVIDER (RANDOM INTERCEPT):
    s(site_name, bs = "re"),
  family = "binomial",
  method = "REML",
  data = tmp_01
)
