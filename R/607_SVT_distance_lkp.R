
# TODO NOTE THAT SVT CURRENTLY USES AFIB CENTRE LOOKUP
# AND FIRST FEW CHUNKS HERE ARE SAME AS 507


# ADD THESE POSTCODES MANUALLY: 
eric_plus_for_afib <- eric |> 
  ## LEGACY CODE FOR MANCHESTER ROYAL INF:
  add_row(
    site_code = "R0A02",
    site_name = "MANCHESTER ROYAL INFIRMARY",
    post_code = "M13 9WL"
  ) |>
  # ADDITIONAL CODE FOR PAPWORTH (ADDTIONAL TO EVERARD):
  add_row(
    site_code = "RGM22",
    site_name = "PAPWORTH HOSPITAL",
    post_code = "CB2 0AY"
  ) |> 
  #  MERIDIAN @ COVENTRY UNI HOSP:
  add_row(
    site_code = "RKB18",
    site_name = "MERIDIAN COVENTRY",
    post_code = "CV2 2LQ"
  ) 


# -------------------------------------------------------------------------

# THESE ARE THE 45 UNIQUE POSTCODES:
tmp_ep_centre_postcodes <- lkp_ep_centres_for_distance |> 
  distinct(site_code) |> 
  left_join(eric_plus_for_afib, join_by(site_code)) |> 
  arrange(site_name) |> 
  print(n=45)


df_ep_centre_postcodes <- tmp_ep_centre_postcodes |> 
  left_join(lkp_postcode_coords, join_by(post_code)) |> 
  st_as_sf(coords = c("long", "lat"), crs = 4326) |> 
  st_transform(27700) |> 
  print(n=45)

# -------------------------------------------------------------------------
# DIFFERENT FROM AFIB FROM HERE ON
# -------------------------------------------------------------------------

df_ep_relevant_centroids_svt <- df_svt_exclusions |> 
  distinct(lsoa21code) |>
  left_join(lkp_lsoa_centroids, join_by(lsoa21code == lsoa21cd)) |> 
  st_as_sf(coords = c("long", "lat"), crs = 4326) |> 
  st_transform(27700)

gc()
gc()


df_ep_distance_combos_svt <- df_ep_relevant_centroids_svt |> 
  cross_join(df_ep_centre_postcodes |> select(-post_code)) |> 
  tibble()

df_ep_distance_combos_svt <- 
  st_distance(df_ep_relevant_centroids_svt, df_ep_centre_postcodes) |> 
  as_tibble() |> 
  # ADD THE LSOA COLUMN BACK IN:
  mutate(lsoa21code = df_ep_relevant_centroids_svt$lsoa21code, .before = 1)

colnames(df_ep_distance_combos_svt)[2:46] <- df_ep_centre_postcodes$site_code

df_ep_distance_combos_long_svt <- df_ep_distance_combos_svt |> 
  pivot_longer(cols = 2:46, names_to = "site_code", values_to = "distance")

gc()
gc()


df_ep_distance_by_year_svt <- df_ep_distance_combos_long_svt |> 
  # left_join(lkp_thrombo_centres, join_by(site_code),
  #           relationship = "many-to-many")
  full_join(
    lkp_ep_centres_for_distance |> 
      select(fyear, site_code),
    join_by(site_code),
    relationship = "many-to-many"
  )

gc()
gc()

# -------------------------------------------------------------------------
# THIS TAKES A MINUTE OR SO: DISTANCE IN METERS.
lkp_min_distance_ep_svt <- df_ep_distance_by_year_svt |> 
  group_by(fyear, lsoa21code) |> 
  filter(distance == min(distance)) |> 
  ungroup() |> 
  select(lsoa21code, fyear, distance) |> 
  mutate(distance = as.numeric(distance)) |> 
  rename(min_ep_dist = distance) |> 
  distinct()

gc()
gc()
gc()


