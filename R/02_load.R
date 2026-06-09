# README
# Run SQL queries and bring ECDS data and lookups into R environment. 

# source(here::here("R", "01_setup.R"))

# TODO: NOTE: IN 2025/26 LSOA ONLY 95.7% COMPLETE. NOT ONLY IN LATTER MONTHS.

# 1. MAIN QUERIES ---------------------------------------------------------

## a. thrombectomy -------------------------------------------------------

# READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
sql_script_thromb <- here("sql", "[UDAL]query_main_thromb.sql")

query_thromb <- readChar(sql_script_thromb, file.info(sql_script_thromb)$size) |>
  str_replace_all(string = _, "\n|\r|ï»¿", " ")

df_thromb <- dbGetQuery(con_one, query_thromb) |>
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


# 5. DISTANCE ----------------------------------------------------------------

# query_distance <- "SELECT * FROM UKHD_Ordnance_Survey.LSOAs_December_2021_Population_Weighted_Centroids"
# 
# df_distance <- dbGetQuery(con_one, query_distance) |>
#   as_tibble() |>
#   clean_names() 
# 
# gc()
# gc()


# df_distance
# 
# curl::curl_download(
#   url = "https://files.digital.nhs.uk/AA/2375EE/ERIC%20-%202024_25%20-%20Site%20data.csv",
#   destfile = here("data", "eric_2425.csv")
# )
# 
# a <- read_csv(here("data", "eric_2425.csv"), col_names = F)
# colnames(df) <- as.character(unlist(df[1, ]))
# 
# # 2. Remove the first row from the data
# df <- df[-1, , drop = FALSE]
# 
# # 3. Reset row names
# rownames(df) <- NULL



# # DRIVETIME  ------------------------------------------------------------------
# 
# query_drivetimes <- "SELECT * FROM Internal_Reference.SiteToLSOA_DriveTime"
# 
# df_drivetimes <- dbGetQuery(con_one, query_drivetimes) |>
#   as_tibble() |>
#   clean_names() 
# 
# gc()
# gc()

# 3. TEST THROMBOS -------------------------------------------------------------
# 
# # READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
# sql_script_test <- here("sql", "test.sql")
# 
# query_audit_test <- readChar(sql_script_test, file.info(sql_script_test)$size) |>
#   str_replace_all(string = _, "\n|\r|ï»¿", " ")
# 
# df_audit_thromb_test <- dbGetQuery(con_one, query_audit_test) |>
#   as_tibble() |>
#   clean_names()
# 
# gc()
# gc()
# 
# df_audit_thromb_test |> 
#   count(
#     fyear, 
#     stroke = stroke_ischaemic == 1 | stroke_other == 1,
#     thrombo_modern, 
#     thrombo_legacy, 
#     wt = n
#     ) |> 
#   filter(thrombo_modern == 1 | thrombo_legacy == 1) |> 
#   pivot_longer(cols = c(thrombo_modern, thrombo_legacy), names_to = "coding", values_to = "b") |>
#   mutate(coding = str_remove(coding, "thrombo_")) |> 
#   mutate(stroke = as.integer(stroke)) |> 
#   mutate(n = b*n) |> 
#   count(fyear, stroke, coding, wt = n) |> 
#   filter(fyear != "2026/27") |> 
#   # count(fyear, wt = n) |> 
#   # mutate(year = row_number()) |> 
#   ggplot(aes(fyear, n, col = coding, group = coding)) +
#   geom_line()+
#   geom_point()+
#   facet_wrap(vars(stroke), scales = "free")

# df_audit_thromb |>
#   filter(thrombo_base == 1) |>
#   # head(10) |>
#   # slice(2) |>
#   # select(der_procedure_all) |>
#   # pull()
#   # transmute(a = str_extract_all(der_procedure_all, "L35"))
#   transmute(a = str_extract_all(der_procedure_all, "L35.{1}")) |>
#   identity() |>
#   unnest(a) |>
#   count(a, sort = T)



# 4. FURTHER TESTING PROVIDER RECONCILIATION  ------------------------------------------------------

# READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
# sql_script_test <- here("sql", "test3.sql")
# 
# query_audit_test <- readChar(sql_script_test, file.info(sql_script_test)$size) |>
#   str_replace_all(string = _, "\n|\r|ï»¿", " ")
# 
# df_audit_thromb_test3 <- dbGetQuery(con_one, query_audit_test) |>
#   as_tibble() |>
#   clean_names()
# 
# gc()
# gc()
# 
# df_audit_thromb_test3 |>
#   filter(thrombo_modern == 1 | thrombo_legacy == 1) |> 
#   # filter( stroke_ischaemic == 1 | stroke_other == 1) |> 
#   count(trust_name) 
