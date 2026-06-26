# README
# Run SQL queries and bring ECDS data and lookups into R environment. 

# source(here::here("R", "01_setup.R"))

# TODO: NOTE: ACROSS 2025/26 LSOA ONLY ~80% COMPLETE. 

# 1. MAIN QUERY ---------------------------------------------------------

# READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
sql_script_tavi <- here("sql", "[UDAL]query_main_tavi.sql")

query_tavi <- readChar(sql_script_tavi, file.info(sql_script_tavi)$size) |>
  str_replace_all(string = _, "\n|\r|ï»¿", " ")

# avr = aortic valve replacement
df_tavi_raw <- dbGetQuery(con_one, query_tavi) |>
  as_tibble() |>
  clean_names() 

gc()
gc()


# 2. IMD 2025 -----------------------------------------------------------------
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
# rural ON core.der_postcode_lsoa_2021_code = rural.lsoa_code

# UKHD_Rural_Urban_Class.LSOAs_2011_SCD

lkp_rural <- dbGetQuery(con_one, query_rural) |>
  as_tibble() |>
  clean_names() 

gc()
gc()


# 4. REGION --------------------------------------------------------------

# TABLE DOWNLOADED FROM:
# https://geoportal.statistics.gov.uk/datasets/ons::lsoa-2021-to-bua-to-lad-to-region-december-2022-best-fit-lookup-in-ew-v2/about
# 2011
# https://geoportal.statistics.gov.uk/datasets/c1e13af610c84ec59f086502e8ebe4f7_0/about


lkp_regione <-  read_csv(
  here("data", list.files(here("data"), pattern = "Region"))
) |> 
  clean_names() |> 
  select(lsoa21cd, rgn22nm)

