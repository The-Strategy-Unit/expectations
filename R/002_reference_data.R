
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

query_imd_rank <- "
SELECT LSOA_CODE_2021, IMD_RANK, IMD_DECILE
FROM UKHF_Demography.Index_Of_Multiple_Deprivation_By_LSOA1
WHERE EFFECTIVE_SNAPSHOT_DATE = '2025-12-31'
"

lkp_imd25_rank <- dbGetQuery(con_one, query_imd_rank) |>
  as_tibble() |>
  clean_names() 

gc()
gc()

lkp_imd25_rank <- lkp_imd25_rank |> 
  mutate(imd_quartile = ntile(imd_rank, 4)) 
  # count(imd_decile, imd_quartile)
  # count(imd_quartile)

# 2. RURAL -------------------------------------------------------------------

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


# 3. REGION --------------------------------------------------------------

# TABLE MANUALLY DOWNLOADED FROM:
# https://geoportal.statistics.gov.uk/datasets/ons::lsoa-2021-to-bua-to-lad-to-region-december-2022-best-fit-lookup-in-ew-v2/about

### FOR REFERENCE, 2011 VERSION IS HERE:
### https://geoportal.statistics.gov.uk/datasets/c1e13af610c84ec59f086502e8ebe4f7_0/about


lkp_regione <-  read_csv(
  here("data", list.files(here("data"), pattern = "Region"))
) |> 
  clean_names() |> 
  select(lsoa21cd, rgn22nm)


# 4. LSOA11 --> LSOA21 BEST FIT LOOKUP ------------------------------------

# THIS BEST FIT LOOKUP ENABLES CONVERSION FROM 2011 TO 2021
# CAN'T BE DOING BACK CONVERSION SINCE MISSING 1K 2021 LSOAs 
# "1,044 LSOAs are missing from the 2021 LSOAs"
# https://geoportal.statistics.gov.uk/datasets/ons::lsoa-2011-to-lsoa-2021-to-local-authority-district-2022-best-fit-lookup-for-ew-v2/about

lkp_lsoa_bestfit <- read_csv(
  here("data", list.files(here("data"), pattern = "LSOA11"))
) |>
  clean_names() |>
  select(lsoa11cd, lsoa21cd)



# 5. LSOA (2021) to SICBL to ICB LOOKUP (APR 2025) -------------------------------------

# TABLE MANUALLY DOWNLOADED FROM:
# https://geoportal.statistics.gov.uk/datasets/d3822450044541edbcb4369d6e83948a_0/explore


lkp_icb <- read_csv(
  here("data", list.files(here("data"), pattern = "SICBL"))
) |>
  clean_names() |>
  # colnames()
  select(lsoa21cd, sicbl25nm, icb25nm)


# 6. LSOA 2021 POPULATION WEIGHTED CENTROIDS --------------------------------

# https://www.data.gov.uk/dataset/e3e903a6-1864-4083-8837-017b6bdf8cc5/lower-layer-super-output-areas-december-2021-ew-population-weighted-centroids2
# curl::curl_download(
#   url = "https://open-geography-portalx-ons.hub.arcgis.com/api/download/v1/items/32729e42d05e4e23bc7e43a36aa4ae8b/excel?layers=0",
#   destfile = here("data", "lsoa_centroids.xlsx")
# )

lkp_lsoa_centroids <- read_excel(here("data", "lsoa_centroids.xlsx")) |> 
  clean_names() |> 
  select(lsoa21cd, long = x, lat = y)

# 7. NHS ESTATES RETURNS (ERIC) ----------------------------

# FOR SITE POSTCODES, WE'RE USING ERIC (ONLY GIVES POSTCODE FOR 24/25):
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

# 8. LOOKUP COORDS (LONG, LAT) FOR POSTCODES -------------------------

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


# 10. HOSPITAL FRAILTY RISK SCORE ------------------------------------------

# Source: Gilbert T, Neuburger J, Kraindler J, et al. Development and validation
# of a Hospital Frailty Risk Score focusing on older people in acute care settings
# using electronic hospital records: an observational study. Lancet 2018.
# Supplementary appendix, Table A2 (109 ICD-10 codes and points).
#
# This section reconstructs Table A2 in the supplementary appendix of the paper above.
# ------------------------------------------------------------------------------

lkp_frailty_score <- tribble(
  ~icd_code, ~icd_description, ~n_devt_cohort, ~pct_devt_cohort, ~n_frail_group, ~pct_frail_group, ~points,
  "F00", "Dementia in Alzheimer's disease", 664, 3.0, 564, 11.5, 7.1,
  "G81", "Hemiplegia", 332, 1.5, 240, 4.9, 4.4,
  "G30", "Alzheimer's disease", 1107, 5.0, 751, 15.3, 4.0,
  "I69", "Sequelae of cerebrovascular disease (secondary codes)", 509, 2.3, 343, 7.0, 3.7,
  "R29", "Other symptoms and signs involving the nervous and musculoskeletal systems (R29.6 Tendency to fall)", 4140, 18.7, 2429, 49.5, 3.6,
  "N39", "Other disorders of urinary system (includes urinary tract infection and urinary incontinence)", 3852, 17.4, 2233, 45.5, 3.2,
  "F05", "Delirium, not induced by alcohol and other psychoactive substances", 1328, 6.0, 923, 18.8, 3.2,
  "W19", "Unspecified fall", 2568, 11.6, 1462, 29.8, 3.2,
  "S00", "Superficial injury of head", 886, 4.0, 569, 11.6, 3.2,
  "R31", "Unspecified haematuria", 708, 3.2, 309, 6.3, 3.0,
  "B96", "Other bacterial agents as the cause of diseases classified to other chapters (secondary code)", 1395, 6.3, 918, 18.7, 2.9,
  "R41", "Other symptoms and signs involving cognitive functions and awareness", 2037, 9.2, 1222, 24.9, 2.7,
  "R26", "Abnormalities of gait and mobility", 1882, 8.5, 1114, 22.7, 2.6,
  "I67", "Other cerebrovascular diseases", 1838, 8.3, 1050, 21.4, 2.6,
  "R56", "Convulsions, not elsewhere classified", 332, 1.5, 206, 4.2, 2.6,
  "R40", "Somnolence, stupor and coma", 266, 1.2, 177, 3.6, 2.5,
  "T83", "Complications of genitourinary prosthetic devices, implants and grafts", 244, 1.1, 147, 3.0, 2.4,
  "S06", "Intracranial injury", 221, 1.0, 128, 2.6, 2.4,
  "S42", "Fracture of shoulder and upper arm", 266, 1.2, 142, 2.9, 2.3,
  "E87", "Other disorders of fluid, electrolyte and acid-base balance", 2546, 11.5, 1251, 25.5, 2.3,
  "M25", "Other joint disorders, not elsewhere classified", 1262, 5.7, 648, 13.2, 2.3,
  "E86", "Volume depletion", 1550, 7.0, 893, 18.2, 2.3,
  "R54", "Senility", 332, 1.5, 211, 4.3, 2.2,
  "Z50", "Care involving use of rehabilitation procedures", 354, 1.6, 196, 4.0, 2.1,
  "F03", "Unspecified dementia", 2701, 12.2, 1433, 29.2, 2.1,
  "W18", "Other fall on same level", 642, 2.9, 363, 7.4, 2.1,
  "Z75", "Problems related to medical facilities and other health care", 642, 2.9, 437, 8.9, 2.0,
  "F01", "Vascular dementia", 863, 3.9, 491, 10.0, 2.0,
  "S80", "Superficial injury of lower leg", 244, 1.1, 152, 3.1, 2.0,
  "L03", "Cellulitis", 863, 3.9, 422, 8.6, 2.0,
  "H54", "Blindness and low vision", 642, 2.9, 314, 6.4, 1.9,
  "E53", "Deficiency of other B group vitamins", 244, 1.1, 123, 2.5, 1.9,
  "Z60", "Problems related to social environment", 487, 2.2, 240, 4.9, 1.8,
  "G20", "Parkinson's disease", 487, 2.2, 240, 4.9, 1.8,
  "R55", "Syncope and collapse", 1439, 6.5, 633, 12.9, 1.8,
  "S22", "Fracture of rib(s), sternum and thoracic spine", 221, 1.0, 113, 2.3, 1.8,
  "K59", "Other functional intestinal disorders", 2590, 11.7, 1305, 26.6, 1.8,
  "N17", "Acute renal failure", 3454, 15.6, 1713, 34.9, 1.8,
  "L89", "Decubitus ulcer", 775, 3.5, 461, 9.4, 1.7,
  "Z22", "Carrier of infectious disease", 221, 1.0, 132, 2.7, 1.7,
  "B95", "Streptococcus and staphylococcus as the cause of diseases classified to other chapters", 332, 1.5, 182, 3.7, 1.7,
  "L97", "Ulcer of lower limb, not elsewhere classified", 797, 3.6, 407, 8.3, 1.6,
  "R44", "Other symptoms and signs involving general sensations and perceptions", 221, 1.0, 128, 2.6, 1.6,
  "K26", "Duodenal ulcer", 244, 1.1, 98, 2.0, 1.6,
  "I95", "Hypotension", 1727, 7.8, 844, 17.2, 1.6,
  "N19", "Unspecified renal failure", 221, 1.0, 93, 1.9, 1.6,
  "A41", "Other septicaemia", 952, 4.3, 515, 10.5, 1.6,
  "Z87", "Personal history of other diseases and conditions", 2790, 12.6, 1197, 24.4, 1.5,
  "J96", "Respiratory failure, not elsewhere classified", 886, 4.0, 353, 7.2, 1.5,
  "X59", "Exposure to unspecified factor", 354, 1.6, 196, 4.0, 1.5,
  "M19", "Other arthrosis", 2635, 11.9, 1040, 21.2, 1.5,
  "G40", "Epilepsy", 443, 2.0, 211, 4.3, 1.5,
  "M81", "Osteoporosis without pathological fracture", 1660, 7.5, 682, 13.9, 1.4,
  "S72", "Fracture of femur", 1107, 5.0, 530, 10.8, 1.4,
  "S32", "Fracture of lumbar spine and pelvis", 266, 1.2, 128, 2.6, 1.4,
  "E16", "Other disorders of pancreatic internal secretion", 421, 1.9, 211, 4.3, 1.4,
  "R94", "Abnormal results of function studies", 531, 2.4, 236, 4.8, 1.4,
  "N18", "Chronic renal failure", 3564, 16.1, 1354, 27.6, 1.4,
  "R33", "Retention of urine", 1705, 7.7, 824, 16.8, 1.3,
  "R69", "Unknown and unspecified causes of morbidity", 177, 0.8, 103, 2.1, 1.3,
  "N28", "Other disorders of kidney and ureter, not elsewhere classified", 399, 1.8, 172, 3.5, 1.3,
  "R32", "Unspecified urinary incontinence", 841, 3.8, 461, 9.4, 1.2,
  "G31", "Other degenerative diseases of nervous system, not elsewhere classified", 686, 3.1, 417, 8.5, 1.2,
  "Y95", "Nosocomial condition", 753, 3.4, 447, 9.1, 1.2,
  "S09", "Other and unspecified injuries of head", 288, 1.3, 157, 3.2, 1.2,
  "R45", "Symptoms and signs involving emotional state", 443, 2.0, 260, 5.3, 1.2,
  "G45", "Transient cerebral ischaemic attacks and related syndromes", 244, 1.1, 88, 1.8, 1.2,
  "Z74", "Problems related to care-provider dependency", 332, 1.5, 201, 4.1, 1.1,
  "M79", "Other soft tissue disorders, not elsewhere classified", 930, 4.2, 402, 8.2, 1.1,
  "W06", "Fall involving bed", 310, 1.4, 186, 3.8, 1.1,
  "S01", "Open wound of head", 753, 3.4, 407, 8.3, 1.1,
  "A04", "Other bacterial intestinal infections", 221, 1.0, 108, 2.2, 1.1,
  "A09", "Diarrhoea and gastroenteritis of presumed infectious origin", 1417, 6.4, 618, 12.6, 1.1,
  "J18", "Pneumonia, organism unspecified", 3830, 17.3, 1644, 33.5, 1.1,
  "J69", "Pneumonitis due to solids and liquids", 487, 2.2, 250, 5.1, 1.0,
  "R47", "Speech disturbances, not elsewhere classified", 421, 1.9, 236, 4.8, 1.0,
  "E55", "Vitamin D deficiency", 310, 1.4, 157, 3.2, 1.0,
  "Z93", "Artificial opening status", 443, 2.0, 162, 3.3, 1.0,
  "R02", "Gangrene, not elsewhere classified", 155, 0.7, 83, 1.7, 1.0,
  "R63", "Symptoms and signs concerning food and fluid intake", 1328, 6.0, 564, 11.5, 0.9,
  "H91", "Other hearing loss", 1151, 5.2, 466, 9.5, 0.9,
  "W10", "Fall on and from stairs and steps", 266, 1.2, 103, 2.1, 0.9,
  "W01", "Fall on same level from slipping, tripping and stumbling", 686, 3.1, 270, 5.5, 0.9,
  "E05", "Thyrotoxicosis [hyperthyroidism]", 199, 0.9, 74, 1.5, 0.9,
  "M41", "Scoliosis", 288, 1.3, 123, 2.5, 0.9,
  "R13", "Dysphagia", 731, 3.3, 324, 6.6, 0.8,
  "Z99", "Dependence on enabling machines and devices", 399, 1.8, 167, 3.4, 0.8,
  "U80", "Agent resistant to penicillin and related antibiotics", 288, 1.3, 177, 3.6, 0.8,
  "M80", "Osteoporosis with pathological fracture", 177, 0.8, 83, 1.7, 0.8,
  "K92", "Other diseases of digestive system", 1018, 4.6, 388, 7.9, 0.8,
  "I63", "Cerebral Infarction", 863, 3.9, 324, 6.6, 0.8,
  "N20", "Calculus of kidney and ureter", 133, 0.6, 54, 1.1, 0.7,
  "F10", "Mental and behavioural disorders due to use of alcohol", 221, 1.0, 93, 1.9, 0.7,
  "Y84", "Other medical procedures as the cause of abnormal reaction of the patient", 332, 1.5, 147, 3.0, 0.7,
  "R00", "Abnormalities of heart beat", 1284, 5.8, 481, 9.8, 0.7,
  "J22", "Unspecified acute lower respiratory infection", 2059, 9.3, 878, 17.9, 0.7,
  "Z73", "Problems related to life-management difficulty", 421, 1.9, 250, 5.1, 0.6,
  "R79", "Other abnormal findings of blood chemistry", 819, 3.7, 324, 6.6, 0.6,
  "Z91", "Personal history of risk-factors, not elsewhere classified", 443, 2.0, 182, 3.7, 0.5,
  "S51", "Open wound of forearm", 177, 0.8, 103, 2.1, 0.5,
  "F32", "Depressive episode", 1395, 6.3, 613, 12.5, 0.5,
  "M48", "Spinal stenosis (secondary code only)", 487, 2.2, 177, 3.6, 0.5,
  "E83", "Disorders of mineral metabolism", 288, 1.3, 132, 2.7, 0.4,
  "M15", "Polyarthrosis", 288, 1.3, 113, 2.3, 0.4,
  "D64", "Other anaemias", 2125, 9.6, 829, 16.9, 0.4,
  "L08", "Other local infections of skin and subcutaneous tissue", 155, 0.7, 83, 1.7, 0.4,
  "R11", "Nausea and vomiting", 1196, 5.4, 451, 9.2, 0.3,
  "K52", "Other noninfective gastroenteritis and colitis", 244, 1.1, 93, 1.9, 0.3,
  "R50", "Fever of unknown origin", 354, 1.6, 147, 3.0, 0.1
) |> 
  rename(score = points, icd10 = icd_code)

# SANITY CHECKS #
stopifnot(
  # Gilbert et al. define 109 codes
  nrow(lkp_frailty_score) == 109,                 
  all(nchar(lkp_frailty_score$icd10) == 3),
  !any(duplicated(lkp_frailty_score$icd10))
)

# Spot-check two values against the published table / NHP volume copy:
stopifnot(
  lkp_frailty_score$score[lkp_frailty_score$icd10 == "F00"] == 7.1,
  lkp_frailty_score$score[lkp_frailty_score$icd10 == "W19"] == 3.2
)

# 11. HOSPITAL FRAILTY LOOKBACK FOR TAVI -------------------------------------------

# # READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
# sql_script_frailty <- here("sql", "[UDAL]frailty_score_lookback.sql")
# 
# query_frailty <- readChar(sql_script_frailty, file.info(sql_script_frailty)$size) |>
#   str_replace_all(string = _, "\n|\r|ï»¿", " ")
# 
# df_frailty_lookback <- dbGetQuery(con_one, query_frailty) |>
#   as_tibble() |>
#   clean_names()
# 
# gc()
# gc()

# df_frailty_lookback |> saveRDS(here("data","df_frailty_lookback.rds")) 

# df_frailty_lookback <- readRDS(here("data","df_frailty_lookback.rds")) |> 
#   mutate(across(contains("date"), ~ as_date(.)))


# 12. HOSPITAL FRAILTY + COMORBIDITY LOOKBACK FOR AFIB -------------------------------------------

## READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
# sql_script_lookback_afib <- here("sql", "[UDAL]AFIB_frailty_lookback.sql")
# 
# query_lookback_afib <- readChar(sql_script_lookback_afib, file.info(sql_script_lookback_afib)$size) |>
#   str_replace_all(string = _, "\n|\r|ï»¿", " ")
# 
# df_lookback_afib <- dbGetQuery(con_one, query_lookback_afib) |>
#   as_tibble() |>
#   clean_names()
# 
# gc()
# gc()
# gc()
# 
# df_lookback_afib |>
#   mutate(across(contains("date"), ~ as_date(.))) |>
#   saveRDS(here("data","df_lookback_afib.rds"))

df_lookback_afib <- readRDS(here("data","df_lookback_afib.rds")) 



