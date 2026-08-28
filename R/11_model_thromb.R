df_model_prep <- df_thromb_with_dist |> 
  mutate(sex = if_else(sex %in% c("1", "2"), sex, "not_specified")) 

df_thromb_with_dist |> 
  mutate(site_name = if_else(is.na(site_name), der_provider_site_code, site_name)) |> 
  count(der_provider_site_code, site_name, sort = T) |> 
  filter(n < 1100) |> 
  left_join(lkp_thrombo_centres, join_by(der_provider_site_code == site_code)) |> 
  filter(thrombo_centre == 1) |> 
  count(site_name)

# DO WE EVEN WANT SITE?
# THERE ARE 720 PROVIDERS - WE WANT TO REDUCE TO 100- ISH?
# IF WE INCLUDE WALTON CENTRE WE HAVE 160 SITES + 1 "OTHER" CATEGORY.
# WHICH MIGHT BE OKAY.

# MAYBE ASSIGN RXH00 TO RXH01 ?, AND ALL 00s to 01s?? 
df_thromb_with_dist |> 
  filter(str_detect(der_provider_site_code, "^RXH")) |> 
  count(der_provider_site_code, sort = T)
