
# 1. COMPARISON WITH AUDITS ---------------------------------------------------------------

# 1. TAVI -------------------------------------------------------------

# READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
sql_script_audit_tavi <- here("sql", "[UDAL]query_audit_tavi.sql")

query_audit_tavi <- readChar(sql_script_audit_tavi, file.info(sql_script_audit_tavi)$size) |>
  str_replace_all(string = _, "\n|\r|ï»¿", " ")

df_audit_tavi <- dbGetQuery(con_one, query_audit_tavi) |>
  as_tibble() |>
  clean_names() 

gc()
gc()

# 2a. THROMBECTOMY episode -------------------------------------------------------------

# READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
sql_script_audit_thromb <- here("sql", "[UDAL]query_audit_thromb.sql")

query_audit_thromb <- readChar(sql_script_audit_thromb, file.info(sql_script_audit_thromb)$size) |>
  str_replace_all(string = _, "\n|\r|ï»¿", " ")

df_audit_thromb <- dbGetQuery(con_one, query_audit_thromb) |>
  as_tibble() |>
  clean_names() 

gc()
gc()
# 2b. THROMBECTOMY spell -------------------------------------------------------------

# READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
sql_script_audit_thromb <- here("sql", "[UDAL]query_audit_thromb_spell.sql")

query_audit_thromb <- readChar(sql_script_audit_thromb, file.info(sql_script_audit_thromb)$size) |>
  str_replace_all(string = _, "\n|\r|ï»¿", " ")

df_audit_thromb <- dbGetQuery(con_one, query_audit_thromb) |>
  as_tibble() |>
  clean_names() 

gc()
gc()

