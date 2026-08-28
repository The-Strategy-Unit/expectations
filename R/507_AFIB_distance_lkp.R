
# # CHECK WHICH SITES DON'T HAVE POSTCODES:
# lkp_ep_centres_for_distance |>
#   distinct(site_code) |>
#   # distinct(site_code, site_name) |>
#   # arrange(site_code)
#   anti_join(eric, join_by(site_code))
#   # anti_join(eric_plus_for_afib, join_by(site_code))

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

# -------------------------------------------------------------------------

df_ep_centre_postcodes <- tmp_ep_centre_postcodes |> 
  left_join(lkp_postcode_coords, join_by(post_code)) |> 
  st_as_sf(coords = c("long", "lat"), crs = 4326) |> 
  st_transform(27700) |> 
  print(n=45)


# THIS WILL DO ALL LOSAs - TO USE FOR BOTH EL AND EM TAVIs
df_ep_relevant_centroids <- df_afib_exclusions |> 
  distinct(lsoa21code) |>
  left_join(lkp_lsoa_centroids, join_by(lsoa21code == lsoa21cd)) |> 
  st_as_sf(coords = c("long", "lat"), crs = 4326) |> 
  st_transform(27700)

gc()
gc()


df_ep_distance_combos <- df_ep_relevant_centroids |> 
  cross_join(df_ep_centre_postcodes |> select(-post_code)) |> 
  tibble()

df_ep_distance_combos <- 
  st_distance(df_ep_relevant_centroids, df_ep_centre_postcodes) |> 
  as_tibble() |> 
  # ADD THE LSOA COLUMN BACK IN:
  mutate(lsoa21code = df_ep_relevant_centroids$lsoa21code, .before = 1)

colnames(df_ep_distance_combos)[2:46] <- df_ep_centre_postcodes$site_code

df_ep_distance_combos_long <- df_ep_distance_combos |> 
  pivot_longer(cols = 2:46, names_to = "site_code", values_to = "distance")

gc()
gc()


df_ep_distance_by_year <- df_ep_distance_combos_long |> 
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
lkp_min_distance_ep <- df_ep_distance_by_year |> 
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


