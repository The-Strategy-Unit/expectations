
# 1. IMD 2025 -----------------------------------------------------------------
# CHOOSING IMD 2025 AS CLEANER; CONTRIBUTING INDICATORS INCLUDE 
# NEW FACTORS LIKE BROADBAND; AND ALSO BASED ON DATA FROM EARLY 2020s

query_imd <- "
SELECT LSOA_CODE_2021, IMD_DECILE
FROM UKHF_Demography.Index_Of_Multiple_Deprivation_By_LSOA1
WHERE EFFECTIVE_SNAPSHOT_DATE = '2025-12-31'
"

lkp_imd25 <- dbGetQuery(con_one, query_imd) |>
  as_tibble() |>
  clean_names() 

gc()
gc()


# 3. RURAL -------------------------------------------------------------------

query_rural <- "
SELECT lsoa_code, rural_urban_classification
FROM UKHF_Rural_Urban_Class.LSOAs_2021_Map1
WHERE Effective_Snapshot_Date = '2025-03-05'
"

lkp_rural <- dbGetQuery(con_one, query_rural) |>
  as_tibble() |>
  clean_names() 

gc()
gc()


# 4. REGION --------------------------------------------------------------

# TABLE MANUALLY DOWNLOADED FROM:
# https://geoportal.statistics.gov.uk/datasets/ons::lsoa-2021-to-bua-to-lad-to-region-december-2022-best-fit-lookup-in-ew-v2/about

### FOR REFERENCE, 2011 VERSION IS HERE:
### https://geoportal.statistics.gov.uk/datasets/c1e13af610c84ec59f086502e8ebe4f7_0/about


lkp_regione <-  read_csv(
  here("data", list.files(here("data"), pattern = "Region"))
) |> 
  clean_names() |> 
  select(lsoa21cd, rgn22nm)

