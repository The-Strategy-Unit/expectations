
# READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
sql_script_check_svt <- here("sql", "[UDAL]check_falsification2.sql")

query_svt_check <- readChar(sql_script_check_svt, file.info(sql_script_check_svt)$size) |>
  str_replace_all(string = _, "\n|\r|ï»¿", " ")

df_svt_check_raw <- dbGetQuery(con_one, query_svt_check) |>
  as_tibble() |>
  clean_names()

gc()
gc()

df_svt_check_raw |> select(seq)
df_svt_check_raw |> group_by(fyear) |> summarise(mn = max(seq))
df_svt_check_raw |>
  count(fyear, seq_1 = seq == 1) |>
  group_by(fyear) |> 
  mutate(p = n/sum(n)) |>
  ungroup() |> 
  filter(seq_1 == T)

df_svt_check_raw |> count(fyear) |> mutate(p = n/n[1])



# READ AND RUN QUERY FROM SCRIPT IN THE SQL FOLDER:
sql_script_main_svt <- here("sql", "[UDAL]main_falsification.sql")

query_svt <- readChar(sql_script_main_svt, file.info(sql_script_main_svt)$size) |>
  str_replace_all(string = _, "\n|\r|ï»¿", " ")

df_svt_raw <- dbGetQuery(con_one, query_svt) |>
  as_tibble() |>
  clean_names()

gc()
gc()

# df_svt_raw |> colnames()
 
## NUMBER IN COHORT BY YEAR:
df_svt_raw |> count(fyear) |> mutate(p = n/n[1])


# ABLATION WITHIN 24 MTH RISES FROM 5% TO 14.5%
# df_svt_raw |> 
#   count(fyear, ablation_24m) |> 
#   group_by(fyear) |> 
#   mutate(p = n/sum(n)) |> 
#   ungroup() |> 
#   filter(ablation_24m == 1)

# df_svt_raw |> group_by(fyear) |>  summarise(mn = mean(n_diagnoses))

# df_svt_raw |> 
#   count(fyear, na = (is.na(lsoa11code) | lsoa11code == "")) |>
#   group_by(fyear) |>
#   mutate(p = n/sum(n)) |>
#   ungroup() |>
#   filter(na == F) |> 
#   print(n=40)


# df_svt_raw |> saveRDS(here("data_raw", "df_svt_raw.rds"))
df_svt_raw <-  readRDS(here("data_raw", "df_svt_raw.rds"))


df_svt_raw |> count(is.na(days_to_ablation))
df_svt_raw |> count(em_abl)

df_svt_raw |> 
  count(days_to_ablation) |>
  mutate(months = round_half_up(days_to_ablation/30)) |> 
  count(months, wt = n) |> 
  filter(!is.na(months)) |> 
  # print(n=51)
  ggplot(aes(months, n)) +
  geom_line()+
  geom_point(size = 0.9)+
  geom_vline(xintercept = 24, lty = "dashed")

df_svt_raw |> 
  count(days_to_ablation <365*2)

# % ESCALATION EVENTS ARE EMERGENCY BY YEAR. 

# df_svt_raw |> 
#   count(fyear, ablation_24m, em_abl) |>
#   filter(ablation_24m == 1) |> 
#   group_by(fyear) |>
#   mutate(p = n/sum(n)) |>
#   ungroup() |>
#   filter(em_abl == 1)

# TODO: PROCEDURES IN EMERGENCY ABLATION
# df_svt_raw |> 
#   filter(ablation_24m == 1) |> 
#   filter(em_abl == 1) |> 
#   count(der_procedure_all - FOR THE ABLATION SPELL, sort = T)


