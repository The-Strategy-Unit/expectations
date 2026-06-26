# README
# STRAIGHT LINE DISTANCE FROM THE POPN WEIGHTED CENTROIDS OF EACH LSOA 21 BESTFIT
# TO COORDS OF TAVI CENTRE WHICH IS NEAREST

# https://www.data.gov.uk/dataset/e3e903a6-1864-4083-8837-017b6bdf8cc5/lower-layer-super-output-areas-december-2021-ew-population-weighted-centroids2
# curl::curl_download(
#   url = "https://open-geography-portalx-ons.hub.arcgis.com/api/download/v1/items/32729e42d05e4e23bc7e43a36aa4ae8b/excel?layers=0",
#   destfile = here("data", "lsoa_centroids.xlsx")
# )

lkp_lsoa_centroids <- read_excel(here("data", "lsoa_centroids.xlsx")) |> 
  clean_names() |> 
  select(lsoa21cd, long = x, lat = y)


# FOR SITE POSTCODES, WE'RE USING ERIC:
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

# MANUALLY ADD POSTCODES (FROM ODS) THAT ERIC DOESN'T HAVE.
eric_plus <- eric |> 
  # # LEGACY CODE FOR SUSSEX:
  # add_row(
  #   site_code = "RXH01",
  #   site_name = "ROYAL SUSSEX COUNTY HOSPITAL",
  #   post_code = "BN2 5BE"
  # ) |> 
  # # LEGACY CODE FOR HAREFIELD:
  # add_row(
  #   site_code = "RT301",
  #   site_name = "HAREFIELD HOSPITAL",
  #   post_code = "UB9 6JH"
  # ) |> 
  # # LEGACY CODE FOR ROYAL BROMPTON:
  # add_row(
  #   site_code = "RT302",
  #   site_name = "ROYAL BROMPTON HOSPITAL",
  #   post_code = "SW3 6NP"
  # ) |> 
  # # LEGACY CODE FOR WYTHENSHAWE:
  # add_row(
  #   site_code = "RM202",
  #   site_name = "WYTHENSHAWE HOSPITAL",
  #   post_code = "M23 9LT"
  # ) |> 
  # LEGACY CODE - LONDON CHEST HOSPITAL (1):
  add_row(
    site_code = "R1H83",
    site_name = "LONDON CHEST HOSPITAL",
    post_code = "E2 9JX"
  ) |> 
  # # # LEGACY CODE FOR HAMMERSMITH:
  # # add_row(
  # #   site_code = "RQN02",
  # #   site_name = "HAMMERSMITH HOSPITAL",
  # #   post_code = "W12 0HS"
  # # ) |> 
  # # # LEGACY CODE FOR MANCHESTER ROYAL INF:
  # # add_row(
  # #   site_code = "RW3MR",
  # #   site_name = "MANCHESTER ROYAL INFIRMARY",
  # #   post_code = "M13 9WL"
  # # ) |> 
  # # LEGACY CODE (2) FOR MANCHESTER ROYAL INF (2):
  add_row(
    site_code = "R0A02",
    site_name = "MANCHESTER ROYAL INFIRMARY",
    post_code = "M13 9WL"
  ) |>
  # # LEGACY CODE FOR ESSEX CARDIOTHORACIC (SAME PLACE AS BASILDON):
  # add_row(
  #   site_code = "D9Y3Y",
  #   site_name = "ESSEX CARDIOTHORACIC CENTRE",
  #   post_code = "SS16 5NL"
  # ) |> 
  # # LEGACY CODE FOR ESSEX CARDIOTHORACIC (SAME PLACE AS BASILDON):
  # add_row(
  #   site_code = "RDDH8", 
  #   site_name = "BASILDON HOSPITAL",
  #   post_code = "SS16 5NL"
  # ) |> 
  # ADDITIONAL CODE FOR PAPWORTH (ADDTIONAL TO EVERARD):
  add_row(
    site_code = "RGM22",
    site_name = "PAPWORTH HOSPITAL",
    post_code = "CB2 0AY"
  ) |> 
  identity()
  # # ADDITIONAL CODE FOR GUYS' AND ST THOMAS' AT LONDON BRIDGE:
  # add_row(
  #   site_code = "RJ1AB",
  #   site_name = "GUYS' AND ST THOMAS' LONDON BRIDGE",
  #   post_code = "SE1 2PR"
  # ) |> 
  # # LEGACY CODE FOR GUYS' AND ST THOMAS':
  # add_row(
  #   site_code = "RJ100",
  #   site_name = "ST THOMAS' HOSPITAL",
  #   post_code = "SE1 7EH"
  # ) |> 
  # # GENERIC CODE FOR BLACKPOOL VICTORIA HOSPITAL:
  # add_row(
  #   site_code = "RXL00",
  #   site_name = "BLACKPOOL VICTORIA HOSPITAL",
  #   post_code = "FY3 8NR"
  # ) |> 
  # # GENERIC CODE FOR ST GEORGE'S TOOTING:
  # add_row(
  #   site_code = "RJ700",
  #   site_name = "ST GEORGE'S HOSPITAL",
  #   post_code = "SW17 0QT"
  # ) |> 
  # # GENERIC CODE FOR ROYAL SUSSEX:
  # add_row(
  #   site_code = "RXH00",
  #   site_name = "ROYAL SUSSEX COUNTY HOSPITAL",
  #   post_code = "BN2 5BE"
  # ) 
  # # ADD CODE FOR NUFFIELD OXFORD -> POINTS TO JOHN RADCLIFFE:
  # add_row(
  #   site_code = "NT244",
  #   site_name = "ROYAL SUSSEX COUNTY HOSPITAL",
  #   post_code = "OX3 9DU"
  # ) |> 
  

# CHECK ALL HAVE POSTCODES:
lkp_tavi_centres_for_distance |>
  distinct(site_code) |>
  anti_join(eric_plus, join_by(site_code)) |>
  left_join(
    lkp_tavi_centres_prelim |>
      distinct(site_code, site_name),
    join_by(site_code)
  )

# lkp_tavi_centres_for_distance |> 
#   left_join(lkp_tavi_centres_prelim |> 
#               distinct(site_code, site_name),
#             join_by(site_code)) |> 
#   # print(n=450)
#   mutate(n = 1) |> 
#   pivot_wider(names_from = fyear, values_from = n) |> 
#   view("wide")

# ALL TAVI CENTRES IN LKP WITHOUT A POSTCODE MATCH.
lkp_tavi_centres_for_distance |> 
  distinct(site_code) |>
  anti_join(eric_plus, join_by(site_code)) |>
  left_join(lkp_tavi_centres_prelim |> 
              distinct(site_code, site_name),
            join_by(site_code)) 
  left_join(eric_plus, join_by(site_code)) |> 
  arrange(site_name) |> 
  print(n=45)
  
# TODO rxh00 duplicated

lkp_tavi_centres_for_distance |> 
  left_join(eric_plus, join_by(site_code)) 
  
  # count(site_code, sort = T) |>
  # tail(20)
  left_join(lkp_tavi_centres_prelim |> 
              distinct(site_code, site_name),
            join_by(site_code)) |> 
  # print(n=450)
  mutate(n = 1) |> 
  pivot_wider(names_from = fyear, values_from = n) |> 
  view("wide")
  

# -------------------------------------------------------------------------

  

# THESE ARE THE 30 UNIQUE POSTCODES:
tmp_tavi_centre_postcodes <- lkp_tavi_centres_for_distance |> 
   distinct(site_code) |> 
   left_join(eric_plus, join_by(site_code)) |> 
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

lkp_postcode_coords <-  read_csv(
  col_names = F,
  here("data","open_postcode_geo.csv"),
  col_select = c(1, 8, 9), # COLS 4, 5 = BNG (BRITISH NATIONAL GRID)
)

colnames(lkp_postcode_coords) <- c("post_code", "lat", "long") # "easting", "northing",

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

# TODO THIS IS ALSO WHERE ONE COULD MAKE:
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

