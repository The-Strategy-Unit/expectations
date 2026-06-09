# README
# LSOA 21 BESTFITS WEIGHTED CENTROIDS DISTANCE TO COORDS OF THROMBECTOMY 
# CENTRE WHICH IS NEAREST (BY STRAIGHT LINE DISTANCE)

# https://www.data.gov.uk/dataset/e3e903a6-1864-4083-8837-017b6bdf8cc5/lower-layer-super-output-areas-december-2021-ew-population-weighted-centroids2
# curl::curl_download(
#   url = "https://open-geography-portalx-ons.hub.arcgis.com/api/download/v1/items/32729e42d05e4e23bc7e43a36aa4ae8b/excel?layers=0",
#   destfile = here("data", "lsoa_centroids.xlsx")
# )

lkp_lsoa_centroids <- read_excel(here("data", "lsoa_centroids.xlsx")) |> 
  clean_names() |> 
  select(lsoa21cd, long = x, lat = y)


# curl::curl_download(
#   url = "https://files.digital.nhs.uk/AA/2375EE/ERIC%20-%202024_25%20-%20Site%20data.csv",
#   destfile = here("data", "eric_2425.csv")
# )

eric <- read_csv(
  here("data", "eric_2425.csv"),
  col_names = T, 
  col_select =  c(`Site Code`, `Site Name`, `Post Code`)
) |> 
   clean_names()

eric_plus <- eric |> 
  # LEGACY CODE FOR SUSSEX:
  add_row(
    site_code = "RXH01",
    site_name = "ROYAL SUSSEX COUNTY HOSPITAL",
    post_code = "BN2 5BE"
    )
  
 
# THESE ARE THE 28 (27 UNIQUE) POSTCODES:
tmp_centre_postcodes <- lkp_thrombo_centres |> 
  distinct(site_code) |> 
  left_join(eric_plus, join_by(site_code)) |> 
  print(n=40)

 
# curl::curl_download(
#   url = "https://download.getthedata.com/downloads/open_postcode_geo.csv.zip",
#   destfile = here("data", "open_postcode_geo.csv.zip")
# )

# unzip(
#   zipfile = here("data", "open_postcode_geo.csv.zip"), 
#   exdir = here("data")
#   )

lkp_postcode_coords <-  read_csv(
  col_names = F,
  here("data","open_postcode_geo.csv"),
  col_select = c(1, 8, 9), # 4, 5 = BNG
    )

colnames(lkp_postcode_coords) <- c("post_code", "lat", "long") # "easting", "northing",

df_centre_postcodes <- tmp_centre_postcodes |> 
  left_join(lkp_postcode_coords, join_by(post_code)) |> 
  st_as_sf(coords = c("long", "lat"), crs = 4326) |> 
  st_transform(27700) 

df_relevant_centroids <- df_thromb_with_comorb |> 
  distinct(lsoa21_bfit) |> 
  left_join(lkp_lsoa_centroids, join_by(lsoa21_bfit == lsoa21cd)) |> 
  st_as_sf(coords = c("long", "lat"), crs = 4326) |> 
  st_transform(27700)


df_distance_combos <- df_relevant_centroids |> 
  cross_join(df_centre_postcodes |> select(-post_code)) |> 
  tibble()
  
df_distance_combos <- 
  st_distance(df_relevant_centroids, df_centre_postcodes) |> 
  as_tibble() |> 
  mutate(lsoa21_bfit = df_relevant_centroids$lsoa21_bfit, .before = 1)

colnames(df_distance_combos)[2:29] <- df_centre_postcodes$site_code

df_distance_combos_long <- df_distance_combos |> 
  pivot_longer(cols = 2:29, names_to = "site_code", values_to = "distance")

# df_distance_combos2 |> 
#   slice(c(543210: 543219))

lkp_thrombo_centres |> count(fyear)


df_distance_by_year <- df_distance_combos_long |> 
  # left_join(lkp_thrombo_centres, join_by(site_code),
  #           relationship = "many-to-many")
  full_join(lkp_thrombo_centres, join_by(site_code), relationship = "many-to-many")

gc()
gc()

# TAKES A MINUTE OR SO:
df_min_distance <- df_distance_by_year |> 
  group_by(fyear, lsoa21_bfit) |> 
  filter(distance == min(distance)) |> 
  ungroup()

lkp_distance_nearest_thromb <- df_min_distance |> 
  select(lsoa21_bfit, fyear, distance) |> 
  mutate(distance = as.numeric(distance)) |> 
  rename(dist_nrst_thromb_ctr = distance)


# -------------------------------------------------------------------------

df_thromb_with_dist <- df_thromb_with_comorb |> 
  left_join(lkp_distance_nearest_thromb, join_by(lsoa21_bfit, fyear))



