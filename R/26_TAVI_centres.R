# README
# Create lookup of "TAVI Centres" for each year in the study.
# We define tavi centres as sites performing at least 4
# TAVIs in the year. The 2024/25 list tallies with the list of 
# tavi centres given in the 24/25 NICOR TAVI audit.

# Re-positioned in workflow since analysis aided by region lookup.

# TAVI CENTRE VAR = CONTACT WITH A TAVI TEAM (AT THAT LOCATION)
# TAVI CENTRE * REGION -- > TO ACCOUNT FOR POSSIBLE HUB AND SPOKE EXCEPTIONS

# IF WE'RE NOT USING A TAVI CENTRE INDICATOR VAR IN THE MODEL
# AND ONLY NEED THESE FOR THE DISTANCE TO VARS 
# THEN WE ONLY NEED THE MAJOR SITE CODES AND DON'T NEED TO 
# WORRY ABOUT SORTING OUT TOO MANY OF THE INCONSISTENCIES.

# BUT WE MAY HAVE TO DEAL WITH A FAIR NUMBER OF LEGACY CODES. 
# E.G. RT301, RT302: HAREFIELD, AND ROYAL BROMPTON.

lkp_tavi_centres_prelim <- tmp_tavi_elective_first_epi |> 
  # filter(fyear == "2018/19") |> 
  filter(tavi == 1) |> 
  count(fyear, der_provider_site_code, site_name, sort = T) |> 
  # count(fyear, rgn22nm, der_provider_site_code, site_name, sort = T) |> 
  # group_by(fyear, der_provider_site_code) |> 
  # filter(n == max(n)) |> 
  # ungroup() |> 
  # arrange(fyear, rgn22nm, -n) |> 
  arrange(fyear, -n) |> 
  # group_by(der_provider_site_code) |> 
  # mutate(n_tot = sum(n)) |> 
  # filter(str_detect(der_provider_site_code, "^RBQ"))
  # filter(n > 2 & n <6) |>
  # print(n=40)
  # SEEMS AN APPROPRIATE CUTOFF ( < 3 EITHER TENUOUS TO CALL SPECIALIST OR ERROR)
  filter(n >= 4) |> # | (fyear %in% c("2010/11", "2011/12") & n >= 10)
  # REMOVE GENERIC SITE CODES:
  # filter(!str_detect(der_provider_site_code, "00$")) |> 
  # # ESSEX IS AT BASILDON HOSP, SO JUST TAKE BASILDON FOR EASE OF POSTCODE:
  # filter(der_provider_site_code != "D9Y3Y") |> 
  # # NOT (OUTSOURCED TO) PRIVATE PROVIDERS:
  # filter(!str_detect(der_provider_site_code, "^N")) |> 
  # # ALSO NOT WELLINGTON (APPEARS TO BE NHS OUTSOURCED TO PRIVATE)
  # filter(der_provider_site_code != "E8R5L") |> 
  # # THIS WILL BE ACCOUNTED FOR BY KING'S, WHICH IS ALREADY PRESENT IN FYEAR:
  # filter(der_provider_site_code != "Z4I0G ") |> 
  # # THESE WILL BE ACCOUNTED FOR BY CENTRES WHICH ARE ALREADY PRESENT IN FYEAR:
  # filter(!der_provider_site_code %in% c("Z4I0G", "R1H86", "RRV30", "RWA30")) |> 
  # # filter(fyear %in% c("2010/11", "2011/12"))
  # filter(der_provider_site_code == "R0A02")
  distinct(fyear, der_provider_site_code, site_name) |>
  # count(fyear)
  # select(-rgn22nm) |> 
  rename(site_code = 2) |> 
  mutate(across(3, ~ str_to_title(.))) |> 
  mutate(across(3, ~str_remove_all(. , " Nhs Trust| Nhs Foundation Trust")))  


# lkp_tavi_centres_prelim |>  count(fyear)
# lkp_tavi_centres_prelim |>  filter(fyear == "2024/25") |> print(n=40)

# 
# tmp_low_freq <- lkp_tavi_centres_prelim |>
#   count(site_code, site_name, sort = T) |> 
#   print(n=80)
#   filter(n < 7) |> 
#   pull(site_code)

# 
## TAVIS PERFORMED IN TOTAL
# df_tavi_elective_join_vars |> 
#   # filter(der_provider_site_code == "RWA30")
#   # filter(fyear == "2018/19") |> 
#   filter(tavi == 1) |> 
#   # GROUPING BY REGION WAS USED IN INITIAL MANUAL IDENTIFICATION PROCESS
#   # WILL KEEP HERE, SINCE DON'T WANT TO CHANGE A PROCESS THAT APPEARS TO WORK:
#   count(fyear, der_provider_site_code, site_name, sort = T) |> 
#   filter(n >= 3) |> # | (fyear %in% c("2010/11", "2011/12") & n >= 10)
#   # filter(der_provider_site_code %in% tmp_low_freq) |> 
#   count(der_provider_site_code, site_name, wt = n, sort = T) |> 
#   print(n=80)
#   

# lkp_tavi_centres_prelim |> 
#   # count(fyear)
#   filter(fyear == "2024/25") |> 
#   print(n=40)
  
# # MANCHESTER IS NO LONGER A TAVI CENTRE
# lkp_tavi_centres_prelim |>
#   filter(fyear == "2019/20") |>
#   print(n=70)
  
# TODO LOOK AT OTHERS..?
# RKB00 --> RKB01
# RAJ12 IS ALSO D9Y3Y
# RRK

lkp_tavi_centres <- lkp_tavi_centres_prelim |> 
  select(fyear, site_code) |> 
  mutate(tavi_centre = 1L) 



# DISTANCE FROM LSOA TO NEAREST TAVI CENTRE ----------------------------------
# WE MAKE SOME CHANGES.

# WE DON'T WANT TO INCLUDE ALL CENTRES LISTED IN THE INITIAL LOOKUP 
# - WHICH WAS FOR A DIFFERENT PURPOSE. 
# E.G. HERE, WE DON'T WANT TO REFERENCE PRIVATE CENTRES, OR CENTRES MORE THAN ONCE.


lkp_tavi_centres_for_distance <- lkp_tavi_centres |> 
  ## ESSEX IS AT BASILDON HOSP, SO JUST TAKE BASILDON TO GET ERIC POSTCODE:
  mutate(site_code = if_else(site_code %in% c("RDDH8", "D9Y3Y"), "RAJ12", site_code)) |> 
  ## FOR SITES THAT HAVE MORE THAN ONE CODE, OVERWRITE OLD / GENERIC CODES:
  ## HAMMERSMITH
  mutate(site_code = if_else(site_code %in% c("RQN02"), "RYJ03", site_code)) |> 
  ## HAREFIELD
  mutate(site_code = if_else(site_code %in% c("RT301"), "RJ181", site_code)) |> 
  ## BROMPTON
  mutate(site_code = if_else(site_code %in% c("RT302"), "RJ182", site_code)) |> 
  ## MANCHESTER
  mutate(site_code = if_else(site_code %in% c("RW3MR"), "R0A02", site_code)) |> 
  ## PAPWORTH
  mutate(site_code = if_else(site_code %in% c("RGM21"), "RGM22", site_code)) |> 
  ## LONDON CHEST
  mutate(site_code = if_else(site_code %in% c("RNJ83"), "R1H83", site_code)) |> 
  ## SUSSEX
  mutate(site_code = if_else(site_code %in% c("RXH01", "RXH00"), "E0A3H", site_code)) |> 
  ## ST GEORGE'S
  mutate(site_code = if_else(site_code %in% c("RJ700"), "RJ701", site_code)) |> 
  ## ST THOMAS'
  mutate(site_code = if_else(site_code %in% c("RJ100"), "RJ122", site_code)) |> 
  ## WYTHENSHAWE
  mutate(site_code = if_else(site_code %in% c("RM202"), "R0A07", site_code)) |> 
  # WE DON'T WANT LOCATIONS OF PRIVATE PROVIDERS:
  filter(!str_detect(site_code, "^N")) |> 
  # WELLINGTON (NHS OUTSOURCED TO PRIVATE)
  filter(site_code != "E8R5L") |> 
  # THIS WILL BE ACCOUNTED FOR BY KING'S, WHICH IS ALREADY PRESENT IN FYEAR:
  filter(site_code != "Z4I0G") |> 
  # THESE WILL BE ACCOUNTED FOR BY CENTRES WHICH ARE ALREADY PRESENT IN FYEAR:
  filter(!site_code %in% 
           c("Z4I0G", "R1H86", "RRV30", "RWA30", "RKB00", "RHM00", "RJ1AB",
             "RXL00", "RYJ01")) |> 
  distinct(fyear, site_code)


  
  

## % TAVIs DONE IN "TAVI CENTRES" OVER TIME (SHOULD BE CONSTANTLY HIGH)
## THE EXCEPTIONS ARE PROBABLY LARGELY THE "OFF SITE" WORK OF TAVI CENTRES
  
  
 
# df_tavi_elective_with_centres |>
#   filter(tavi == 1) |>
#   mutate(fyearint = as.integer(str_sub(fyear, 6, 7))) |>
#   count(fyearint, tavi_centre) |>
#   group_by(fyearint) |>
#   mutate(p = n/sum(n)) |>
#   ungroup() |>
#   filter(tavi_centre == 1) |>
#   ggplot(aes(fyearint, p))+
#   geom_line()+
#   geom_point()
# 
# 
# # % TREATMENT = TAVI BY YEAR AND SPEC CENTRE
# df_tavi_elective_with_centres |> 
#   count(fyear, tavi, tavi_centre) |> 
#   pivot_wider(names_from = tavi, values_from = n) |> 
#   rename(treat_alt = `0`, treat_tavi = `1`) |> 
#   mutate(p_tavi = treat_tavi/(treat_tavi + treat_alt)) |> 
#   mutate(fyearint = as.integer(str_sub(fyear, 6, 7))) |>
#   mutate(tavi_centre = as.factor(tavi_centre)) |> 
#   # print(n=40)
#   # ggplot(aes(fyearint, p_tavi, col = tavi_centre))+
#   ggplot(aes(fyearint, treat_tavi, col = tavi_centre))+
#   geom_line()+
#   theme_minimal()
  
  

  
#   •	North East & Yorkshire:
  
#     Freeman Hospital (Newcastle)
#   	Hull Royal Infirmary (Hull University Teaching Hospitals) --> @ CASTLE HILL
#   	James Cook University Hospital (Middlesbrough)
#     Leeds General Infirmary (Leeds Teaching Hospitals)
#   	Northern General Hospital (Sheffield)
  
#   •	North West:
#     Blackpool Victoria Hospital (Blackpool Teaching Hospitals)
#     Liverpool Heart and Chest Hospital (Liverpool)
#    	Wythenshawe Hospital (Manchester University NHS FT)
#   •	NOT CURRENT: Manchester Royal Infirmary (Manchester University NHS FT) 

#   •	Midlands:
#     Glenfield Hospital (Leicester)
#     New Cross Hospital (Wolverhampton)
#     Nottingham City Hospital (Nottingham University Hospitals)
#   	Queen Elizabeth Hospital (Birmingham) 
#   	Royal Stoke University Hospital (University Hospitals of North Midlands)
#   	University Hospitals Coventry and Warwickshire (Coventry)

#   •	East of England:
#   	Royal Papworth Hospital (Cambridge)
#   	Essex Cardiothoracic Centre (Basildon/Mid and South Essex) /

#   •	London:
#     Barts Heart Centre (St Bartholomew's Hospital) /
#   •	Guy’s Hospital (Guy's and St Thomas' NHS FT) -----| ONLY ST THOMAS'
#   	St Thomas’ Hospital (Guy's and St Thomas' NHS FT) 
#     Hammersmith Hospital (Imperial College Healthcare NHS Trust) /
#   	King’s College Hospital (King's College Hospital NHS FT) /
#   	Royal Brompton Hospital /
#     St George’s University Hospitals (London) /
#   •	South East:
#     Harefield Hospital /
#     John Radcliffe Hospital (Oxford)
#     Royal Sussex County Hospital (Brighton and Sussex University Hospitals) /
#   	Southampton General Hospital (University Hospital Southampton) /  

#   •	South West:
#   	Bristol Heart Institute / Bristol Royal Infirmary /
#   	Derriford Hospital / (Plymouth) 

  
# PRIVATE:
# TODO BRISTOL SPIRE
# TODO NOTTINGHAM SPIRE
# TODO NUFFIELD HEALTH AT ST BARTS
  
#   Wales
#   •	University Hospital of Wales (Cardiff)
#   •	Morriston Hospital (Swansea) [1]
#   Northern Ireland
#   •	Royal Victoria Hospital (Belfast) [1]
#   
