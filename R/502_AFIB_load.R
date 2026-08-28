
# READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
sql_script_main_afib <- here("sql", "[UDAL]main_dccv_afib_ablation.sql")

query_afib <- readChar(sql_script_main_afib, file.info(sql_script_main_afib)$size) |>
  str_replace_all(string = _, "\n|\r|ï»¿", " ")

df_afib_raw <- dbGetQuery(con_one, query_afib) |>
  as_tibble() |>
  clean_names()

gc()
gc()

# df_afib_raw |> colnames()
# 
# # NUMBER IN COHORT BY YEAR:
# df_afib_raw |> count(fyear)


# ABLATION WITHIN 24 MTH RISES FROM 5% TO 14.5%
# df_afib_raw |> 
#   count(fyear, ablation_24m) |> 
#   group_by(fyear) |> 
#   mutate(p = n/sum(n)) |> 
#   ungroup() |> 
#   filter(ablation_24m == 1)

# df_afib_raw |> group_by(fyear) |>  summarise(mn = mean(n_diagnoses))

# df_afib_raw |> 
#   count(fyear, na = (is.na(lsoa11code) | lsoa11code == "")) |>
#   group_by(fyear) |>
#   mutate(p = n/sum(n)) |>
#   ungroup() |>
#   filter(na == F) |> 
#   print(n=40)


# df_afib_raw |> saveRDS(here("data_raw", "df_afib_raw.rds"))
df_afib_raw <-  readRDS(here("data_raw", "df_afib_raw.rds"))


df_afib_raw |> count(is.na(days_to_ablation))
df_afib_raw |> count(em_abl)

df_afib_raw |> 
  count(days_to_ablation) |>
  mutate(months = round_half_up(days_to_ablation/30)) |> 
  count(months, wt = n) |> 
  filter(!is.na(months)) |> 
  # print(n=51)
  ggplot(aes(months, n)) +
  geom_line()+
  geom_point(size = 0.9)+
  geom_vline(xintercept = 24, lty = "dashed")

df_afib_raw |> 
  count(days_to_ablation <365*2)

# % ESCALATION EVENTS ARE EMERGENCY BY YEAR. 

# df_afib_raw |> 
#   count(fyear, ablation_24m, em_abl) |>
#   filter(ablation_24m == 1) |> 
#   group_by(fyear) |>
#   mutate(p = n/sum(n)) |>
#   ungroup() |>
#   filter(em_abl == 1)

# TODO: PROCEDURES IN EMERGENCY ABLATION
# df_afib_raw |> 
#   filter(ablation_24m == 1) |> 
#   filter(em_abl == 1) |> 
#   count(der_procedure_all - FOR THE ABLATION SPELL, sort = T)
  

