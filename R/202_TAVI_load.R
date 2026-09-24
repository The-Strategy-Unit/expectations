# README
# Run SQL queries and bring ECDS data and lookups into R environment. 

# TODO: NOTE: ACROSS 2025/26 LSOA ONLY ~80% COMPLETE. 

# 1. MAIN QUERY ---------------------------------------------------------

# READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
sql_script_tavi <- here("sql", "[UDAL]query_main_tavi.sql")

query_tavi <- readChar(sql_script_tavi, file.info(sql_script_tavi)$size) |>
  str_replace_all(string = _, "\n|\r|ï»¿", " ")

df_tavi_raw <- dbGetQuery(con_one, query_tavi) |>
  as_tibble() |>
  clean_names() 

gc()
gc()

