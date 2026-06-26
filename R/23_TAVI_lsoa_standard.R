# README
# WE WANT IMD AS PROXY FOR EXPECTATION 
# IMD ASSIGNMENT DEPENDS ON LSOA
# OPTIONS HER: EITHER:
# - USE 2011 LSOA (CODED FOR ALL YEARS) AND IMD (2019); OR
# - USE 2021 LSOA (WITH BESTFIT LKP) AND IMD (2025)
#
# SEE:
   # df_stenosis_avr |>
   #   count(fyear, lsoa11 = !is.na(lsoa11code), lsoa21 = !is.na(lsoa21code)) |>
   #   group_by(fyear) |>
   #   mutate(p = n/sum(n)) |>
   #   ungroup() |>
   #   # filter(lsoa11 == T & lsoa21 == F) |>
   #   # print(n=60)
   #   mutate(lsoa11 = ifelse(lsoa11 == TRUE, "lsoa11", "" )) |>
   #   mutate(lsoa21 = ifelse(lsoa21 == TRUE, "lsoa21", "" )) |>
   #   tidyr::unite("base", c(lsoa11, lsoa21), sep = "") |>
   #   ggplot()+
   #   geom_line(aes(fyear, p, col = base, group = base))

#
# ALSO LSOA CODING DIPS 10-20% - INEXPLICABLY - IN 2025/26:
   # df_stenosis_avr |>
   #   filter(fyear == "2024/25" | fyear == "2025/26" | fyear == "2026/27" ) |>
   #   # count(month, lsoa = !is.na(lsoa11code)) |>
   #   count(month, lsoa = !is.na(lsoa21code)) |>
   #   group_by(month) |>
   #   mutate(p = n/sum(n)) |>
   #   ungroup() |>
   #   filter(lsoa == T) |>
   #   print(n =30)
#
# CHOOSING IMD 2025 AS CONTRIBUTING INDICATORS INCLUDE 
# NEW FACTORS LIKE BROADBAND SPEED; AND ALSO BASED ON DATA FROM EARLY 2020s 
#
# ***

# THIS BEST FIT LOOKUP ENABLES CONVERSION FROM 2011 TO 2021
# CAN'T BE DOING BACK CONVERSION SINCE MISSING 1K 2021 LSOAs 
# "1,044 LSOAs are missing from the 2021 LSOAs"
# https://geoportal.statistics.gov.uk/datasets/ons::lsoa-2011-to-lsoa-2021-to-local-authority-district-2022-best-fit-lookup-for-ew-v2/about

lkp_lsoa_bestfit <- read_csv(
  here("data", list.files(here("data"), pattern = "LSOA11"))
) |>
  clean_names() |>
  select(lsoa11cd, lsoa21cd)

df_tavi_standardise_lsoa <- df_tavi_raw |> 
  left_join(lkp_lsoa_bestfit, join_by(lsoa11code == lsoa11cd)) |> 
  rename(lsoa21_bfit = lsoa21cd) |> 
  select(everything(), -contains("lsoa"), lsoa21_bfit) 

# df_tavi_standardise_lsoa |> 
#   count(fyear, has_lsoa = !is.na(lsoa21_bfit)) |> 
#   group_by(fyear) |>
#   mutate(p = n/sum(n)) |>
#   ungroup() |>
#   filter(has_lsoa == 1)
  
# df_tavi_standardise_lsoa |>
#   filter(fyear == "2025/26") |>
#   # count(str_detect(lsoa21_bfit, "^E")) |>
#   filter(age <= 112) |> 
#   filter(admission_method %in% c("11", "12", "13")) |> 
#   count((!is.na(lsoa21_bfit) & str_detect(lsoa21_bfit, "^E"))) |>
#   mutate(p = n/sum(n))
  
## SOME LONDON HOSPITALS MISSING ALMOST 100% OF LSOAS
# df_tavi_standardise_lsoa |>
##   filter(str_detect(admission_method, "^2|81")) |> 
#   filter(admission_method %in% c("11", "12", "13"))
#   filter(fyear == "2025/26") |>
#   # filter(!str_detect(der_provider_site_code, "^RJ1|^RJZ")) |>
#   # ONLY ENGLAND-RESIDENT PATIENTS WITH LSOA (97% PROB DUE TO LOW 25/26 LSOA RECORDING):
#   # filter(str_detect(lsoa21_bfit, "^E")) |>
#   count(der_provider_site_code, site_name, null = is.na(lsoa21_bfit)) |>
#   group_by(der_provider_site_code) |>
#   # count(fyear, null = is.na(lsoa21_bfit)) |>
#   # group_by(fyear) |>
#   mutate(p = n/sum(n)) |>
#   ungroup() |>
#   filter(null == F) |>
#   arrange(-n) |>
#   # arrange(fyear) |>
#   print(n = 60)
