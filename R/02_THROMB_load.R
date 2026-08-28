# README
# Bring APCE data on stroke patients into R environment. 

# source(here::here("R", "01_setup.R"))

# NOTE: ACROSS 2025/26 LSOA ONLY 95.7% COMPLETE.

# 1. MAIN QUERIES ---------------------------------------------------------

## a. thrombectomy epi -------------------------------------------------------

# READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
sql_script_thromb <- here("sql", "[UDAL]query_main_thromb.sql")

query_thromb <- readChar(sql_script_thromb, file.info(sql_script_thromb)$size) |>
  str_replace_all(string = _, "\n|\r|ï»¿", " ")

df_thromb <- dbGetQuery(con_one, query_thromb) |>
  as_tibble() |>
  clean_names()

gc()
gc()

## b. thrombectomy spell -------------------------------------------------------

# # READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
# sql_script_thromb <- here("sql", "[UDAL]query_main_thromb_spell.sql")
# 
# query_thromb <- readChar(sql_script_thromb, file.info(sql_script_thromb)$size) |>
#   str_replace_all(string = _, "\n|\r|ï»¿", " ")
# 
# df_thromb <- dbGetQuery(con_one, query_thromb) |>
#   as_tibble() |>
#   clean_names()
# 
# gc()
# gc()
