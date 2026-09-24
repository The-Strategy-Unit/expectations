# README
# STRAIGHT LINE DISTANCE FROM THE POPN WEIGHTED CENTROIDS OF EACH LSOA 21 BESTFIT
# TO COORDS OF TAVI CENTRE WHICH IS NEAREST

# MANUALLY ADD POSTCODES (FROM ODS) THAT ERIC DOESN'T HAVE.
eric_plus_for_tavi <- eric |> 
  # LEGACY CODE - LONDON CHEST HOSPITAL (1):
  add_row(
    site_code = "R1H83",
    site_name = "LONDON CHEST HOSPITAL",
    post_code = "E2 9JX"
  ) |> 
  # # LEGACY CODE FOR MANCHESTER ROYAL INF:
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
  ) 

# CHECK ALL HAVE POSTCODES:
# lkp_tavi_centres_for_distance |>
#   distinct(site_code) |>
#   anti_join(eric_plus_for_tavi, join_by(site_code)) |>
#   left_join(
#     lkp_tavi_centres_prelim |>
#       distinct(site_code, site_name),
#     join_by(site_code)
#   )

# lkp_tavi_centres_for_distance |> 
#   left_join(lkp_tavi_centres_prelim |> 
#               distinct(site_code, site_name),
#             join_by(site_code)) |> 
#   # print(n=450)
#   mutate(n = 1) |> 
#   pivot_wider(names_from = fyear, values_from = n) |> 
#   view("wide")

# ALL TAVI CENTRES IN LKP WITHOUT A POSTCODE MATCH.
# lkp_tavi_centres_for_distance |> 
#   distinct(site_code) |>
#   anti_join(eric_plus_for_tavi, join_by(site_code)) |>
#   left_join(lkp_tavi_centres_prelim |> 
#               distinct(site_code, site_name),
#             join_by(site_code)) 
#   left_join(eric_plus_for_tavi, join_by(site_code)) |> 
#   arrange(site_name) |> 
#   print(n=45)
  

# # lkp_tavi_centres_for_distance |> 
# #   left_join(eric_plus_for_tavi, join_by(site_code)) 
#   
#   # count(site_code, sort = T) |>
#   # tail(20)
#   left_join(lkp_tavi_centres_prelim |> 
#               distinct(site_code, site_name),
#             join_by(site_code)) |> 
#   # print(n=450)
#   mutate(n = 1) |> 
#   pivot_wider(names_from = fyear, values_from = n) |> 
#   view("wide")
  

# -------------------------------------------------------------------------

# THESE ARE THE 30 UNIQUE POSTCODES:
tmp_tavi_centre_postcodes <- lkp_tavi_centres_for_distance |> 
   distinct(site_code) |> 
   left_join(eric_plus_for_tavi, join_by(site_code)) |> 
   arrange(site_name) |> 
   print(n=45)
  

# curl::curl_download(
#   url = "https://download.getthedata.com/downloads/open_postcode_geo.csv.zip",
#   destfile = here("data", "open_postcode_geo.csv.zip")
# )

# unzip(
#   zipfile = here("data", "open_postcode_geo.csv.zip"), 
#   exdir = here("data")
#   )

# lkp_postcode_coords <-  read_csv(
#   col_names = F,
#   here("data","open_postcode_geo.csv"),
#   col_select = c(1, 8, 9), # COLS 4, 5 = BNG (BRITISH NATIONAL GRID)
# )

# colnames(lkp_postcode_coords) <- c("post_code", "lat", "long") # "easting", "northing",

df_tavi_centre_postcodes <- tmp_tavi_centre_postcodes |> 
  left_join(lkp_postcode_coords, join_by(post_code)) |> 
  st_as_sf(coords = c("long", "lat"), crs = 4326) |> 
  st_transform(27700) |> 
  print(n=40)

# THIS WILL DO ALL LOSAs - TO USE FOR BOTH EL AND EM TAVIs
df_tavi_relevant_centroids <- lkp_lsoa_bestfit |> 
  distinct(lsoa21_bfit = lsoa21cd) |>
  filter(str_detect(lsoa21_bfit, "^E")) |> 
  left_join(lkp_lsoa_centroids, join_by(lsoa21_bfit == lsoa21cd)) |> 
  st_as_sf(coords = c("long", "lat"), crs = 4326) |> 
  st_transform(27700)

gc()
gc()

df_tavi_distance_combos <- df_tavi_relevant_centroids |> 
  cross_join(df_tavi_centre_postcodes |> select(-post_code)) |> 
  tibble()

df_tavi_distance_combos <- 
  st_distance(df_tavi_relevant_centroids, df_tavi_centre_postcodes) |> 
  as_tibble() |> 
  mutate(lsoa21_bfit = df_tavi_relevant_centroids$lsoa21_bfit, .before = 1)

colnames(df_tavi_distance_combos)[2:31] <- df_tavi_centre_postcodes$site_code

df_tavi_distance_combos_long <- df_tavi_distance_combos |> 
  pivot_longer(cols = 2:31, names_to = "site_code", values_to = "distance")

gc()
gc()


df_tavi_distance_by_year <- df_tavi_distance_combos_long |> 
  # left_join(lkp_thrombo_centres, join_by(site_code),
  #           relationship = "many-to-many")
  full_join(lkp_tavi_centres_for_distance, join_by(site_code), relationship = "many-to-many")

gc()
gc()

# THIS IS ALSO WHERE ONE COULD MAKE:
# "N CENTRES WITHIN 40/25 KM (15/25 MILES)"

# THIS TAKES A MINUTE OR SO:
lkp_min_distance_tavi <- df_tavi_distance_by_year |> 
  group_by(fyear, lsoa21_bfit) |> 
  filter(distance == min(distance)) |> 
  ungroup() |> 
  select(lsoa21_bfit, fyear, distance) |> 
  mutate(distance = as.numeric(distance)) |> 
  rename(min_tavi_dist = distance)

gc()
gc()
gc()

