# README
# WE WANT IMD AS PROXY FOR EXPECTATION 
# IMD ASSIGNMENT DEPENDS ON LSOA
# OPTIONS HER: EITHER:
# - USE 2011 LSOA (CODED FOR ALL YEARS) AND IMD (2019); OR
# - USE 2021 LSOA (WITH BESTFIT LKP) AND IMD (2025)
#
# SEE:
#    df_thromb |> 
#      count(fyear, lsoa11 = !is.na(lsoa11code), lsoa21 = !is.na(lsoa21code)) |> 
#      group_by(fyear) |> 
#      mutate(p = n/sum(n)) |> 
#      ungroup() |> 
#      filter(lsoa11 == T & lsoa21 == F) |> 
#      print(n=60)
#      mutate(lsoa11 = ifelse(lsoa11 == TRUE, "lsoa11", "" )) |> 
#      mutate(lsoa21 = ifelse(lsoa21 == TRUE, "lsoa21", "" )) |> 
#      tidyr::unite("base", c(lsoa11, lsoa21), sep = "") |> 
#      ggplot()+
#      geom_line(aes(fyear, p, col = base, group = base))
#
#
# ALSO LSOA CODING DIPS A FEW % - INEXPLICABLY - IN 2025/26:
#    df_thromb |> 
#      filter(fyear == "2024/25" | fyear == "2025/26" | fyear == "2026/27" ) |> 
#      count(month, lsoa = !is.na(lsoa11code)) |> 
#      group_by(month) |> 
#      mutate(p = n/sum(n)) |> 
#      ungroup() |> 
#      filter(lsoa == T) |> 
#      print(n =30)
#
# CHOOSING IMD 2025 AS CONTRIBUTING INDICATORS INCLUDE 
# NEW FACTORS LIKE BROADBAND; AND ALSO BASED ON DATA FROM EARLY 2020s 
#
# ***


df_thromb_standard_lsoa <- df_thromb |>
  left_join(lkp_lsoa_bestfit, join_by(lsoa11code == lsoa11cd)) |> 
  rename(lsoa21_bfit = lsoa21cd) |> 
  select(everything(), -contains("lsoa"), lsoa21_bfit) 


