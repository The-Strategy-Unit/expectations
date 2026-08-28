# README 
# Create lookup of "Thrombectomy Centres" for each year in the study.
# We define thrombectomy centres as sites performing at least 10 
# thrombectomies in the year. The 2024/25 list here tallies with the
# list of thrombectomy centres given in the 24/25 SSNAP audit.

lkp_thrombo_centres_prelim <- df_thromb_exclusions |> 
  filter(thromb == 1) |>
  # filter(fyear == "2024/25") |>
  count(fyear, der_provider_site_code, site_name,  trust_name, sort = T) |> 
  rename(site_code = 2) |> 
  mutate(across(3:4, ~ str_to_title(.))) |> 
  mutate(across(3:4, ~str_remove_all(. , " Nhs Trust| Nhs Foundation Trust"))) |> 
  filter(n>=10) |>
  arrange(fyear, site_name) 

# # NUMBER OF "CENTRES" PER YEAR (DEPENDENT ON filter(n>= ) ABOVE):
# lkp_thrombo_centres_prelim |>
#   count(fyear)
# 
## LEAST FREQUENTLY OBSERVED:
# tmp_low_freq <- lkp_thrombo_centres_prelim |>
#   count(fyear, site_code, site_name) |>
#   count(site_code, site_name, sort = T) |>
#   # tail(19) |> 
#   filter(n < 5) |> 
#   filter(site_name != "Royal Sussex County Hospital" | is.na(site_name)) |> 
#   pull(site_code)
# 
# lkp_thrombo_centres_prelim |> 
#   filter(site_code %in% tmp_low_freq) |> 
#   arrange(-n) |> 
  # print(n=60)
# 
# # SO PROB REMOVE THESE:
# lkp_thrombo_centres_prelim |> 
#   filter(str_detect(site_name, "Chorley|Southend"))
# 
# # THESE LOOK FINE TO KEEP
# lkp_thrombo_centres_prelim |> 
#   filter(str_detect(site_name, "Cov|Notting|University College"))
# 
# # THESE LOOK LIKE MISSPECIFICATIONS:
# lkp_thrombo_centres_prelim |>
#   filter(is.na(site_name))

lkp_thrombo_centres <- lkp_thrombo_centres_prelim |> 
  # REMOVE THE 00 SUFFIXES AS THESE APPEAR TO BE MISCODINGS OF SPECIFIC SITE CODES:
  filter(!is.na(site_name)) |> 
  filter(!str_detect(site_name, "Chorley|Southend")) |> 
  select(fyear, site_code) |> 
  mutate(started_at_thromb_centre = 1L) 

# lkp_thrombo_centres |> saveRDS(here("data", "lkp_thrombo_centres.rds"))
# lkp_thrombo_centres <- readRDS(here("data", "lkp_thrombo_centres.rds"))


# DISTANCE FROM LSOA TO NEAREST THROMB CENTRE ----------------------------------





# APPLY TO MAIN DF ---------------------

df_thromb_with_centres <- tmp_earliest_spell |>
  left_join(
    lkp_thrombo_centres,
    join_by(
      der_provider_site_code == site_code,
      fyear
    )
  ) |> 
  mutate(started_at_thromb_centre = if_else(
    is.na(started_at_thromb_centre), 0, started_at_thromb_centre
    ))


# % THROMBECTOMIES DONE IN "THROMBECTOMY CENTRES" OVER TIME:
# df_thromb_with_centres |>
#   filter(thromb_superspell == 1) |>
#   mutate(fyearint = as.integer(str_sub(fyear, 6, 7))) |>
#   count(fyearint, started_at_thromb_centre) |>
#   group_by(fyearint) |>
#   mutate(p = n/sum(n)) |>
#   ungroup() |>
#   filter(started_at_thromb_centre == 1) |>
#   ggplot(aes(fyearint, p))+
#   geom_line()+
#   geom_point()



