
# 1. ELECTROPHYSIOLOGY CENTRE LIST, BY YEAR------------------------------------

# READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
sql_ep_centre_list <- here("sql", "[UDAL]afib_ep_centres.sql")

query_ep_centres <- readChar(sql_ep_centre_list, file.info(sql_ep_centre_list)$size) |>
  str_replace_all(string = _, "\n|\r|ï»¿", " ")

df_ep_centres_raw <- dbGetQuery(con_one, query_ep_centres) |>
  as_tibble() |>
  clean_names()

gc()
gc()

# df_ep_centres_raw |>
#   mutate(yr = as.integer(str_sub(fyear, 6, 7)) - 10) |> 
#   filter(between(yr, 1, 14)) |> 
#   arrange(fyear, desc(n_abl)) |> 
#   view("centres")


df_ep_centre_prelim <- df_ep_centres_raw |>
  mutate(yr = as.integer(str_sub(fyear, 6, 7)) - 10) |> 
  filter(between(yr, 1, 14)) |> 
  # filter(str_detect(der_provider_site_code, "^N")) |> 
  # arrange(-n_abl)
  filter(n_abl >= 10) 

# df_ep_centre_prelim |> 
#   filter(str_detect(der_provider_site_code, "RJ[0-9]")) |> 
#   arrange(fyear)

lkp_ep_centre <- df_ep_centre_prelim |> 
  select(fyear, der_provider_site_code, site_name, trust_name) |> 
  mutate(ep_centre = 1L) 



# DISTANCE FROM LSOA TO NEAREST EP CENTRE LOOKUP ----------------------------

# THIS LIST WILL NOT BE THE SAME AS ALL CENTRES LISTED IN THE INITIAL LOOKUP 
# - WHICH WAS FOR A DIFFERENT PURPOSE. 
# E.G. HERE, WE DON'T WANT DISTANCE TO PRIVATE CENTRES,
# AND CENTRES SHOULDN'T APPEAR MORE THAN ONCE

# lkp_ep_centre |> 
#   filter(str_detect(der_provider_site_code, "RYJ")) |>
#   # count(der_provider_site_code)
#   # filter(!str_detect(der_provider_site_code, "^N")) |> 
#   filter(is.na(site_name)) |> 
#   distinct(der_provider_site_code)
#   print(n= 40)
  
lkp_ep_centres_for_distance <- lkp_ep_centre |> 
  filter(!str_detect(der_provider_site_code, "^N")) |>
  # SPIRE LEEDS (PRIVATE)
  filter(der_provider_site_code != "RR809") |> 
  # BRISTOL (PRIVATE)
  filter(der_provider_site_code != "RA7PH") |> 
  # LONDON BRIDGE (PRIVATE)
  filter(der_provider_site_code != "RJ1AB") |> 
  # EXETER (PRIVATE)
  filter(der_provider_site_code != "RH884") |> 
  # (PRIVATE)
  filter(der_provider_site_code != "R1H86") |> 
  mutate(site_code = case_when(
    # NA SITE NAMES (INDICATES OLD SITE CODE)
    der_provider_site_code %in% c("RJ700") ~ "RJ701", # ST. GEORGE'S
    der_provider_site_code %in% c("RT302") ~ "RJ182", # BROMPTON
    der_provider_site_code %in% c("RXL00") ~ "RXL01", # BLACKPOOL
    der_provider_site_code %in% c("RT301") ~ "RJ181", # HAREFIELD
    der_provider_site_code %in% c("RJ500") ~ "RYJ01", # CORRECT ST. MARY'S
    der_provider_site_code %in% c("RWE00", "RWESR") ~ "RWEAE", # LEICS
    der_provider_site_code %in% c("RQN00", "RYJ00") ~ "RYJ03", # HAMMERSMITH
    der_provider_site_code %in% c("RXH01", "RXH00") ~ "E0A3H", # SUSSEX
    ## AFTER LOOKING AT ERIC: (MORE EDITS / OLD SITES )
    der_provider_site_code %in% c("RRK02") ~ "RRK15", # QE B'HAM
    der_provider_site_code %in% c("RM202") ~ "R0A07", # WYTHENSHAWE
    der_provider_site_code %in% c("RKB33") ~ "RWP50", # WORCS
    der_provider_site_code %in% c("RDZ20") ~ "R0D02", # BOURNEMOUTH
    der_provider_site_code %in% c("RHM14") ~ "RN506", # N. HANTS
    der_provider_site_code %in% c("RW3MR") ~ "R0A02", # MANCS
    der_provider_site_code %in% c("RXH42") ~ "RYR18", # WORTHING
    der_provider_site_code %in% c("RJ100") ~ "RJ122", # GUYS AND ST. T --> ST. T
    der_provider_site_code %in% c("RDDH8", "D9Y3Y") ~ "RAJ12", # ESSEX CC @ BASILDON
    T ~ der_provider_site_code
  )) 
  