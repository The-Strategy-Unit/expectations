# README
# ADD CHARLSON SCORE TO WORKING STUDY DATAFRAME (TAKES A MINUTE OR SO):
# ? USE LEVEL OR SCORE IN THE MODEL ?

# CHARLSON COMORBIDITY INDEX STRINGS
# https://bmjopen.bmj.com/content/bmjopen/10/10/e041302/DC2/embed/inline-supplementary-material-2.pdf?download=true
df_cci_codes <- tibble(
  mi = "I21|I22|I252",
  chf = "I099|I110|I130|I132|I255|I420|I425|I426|I427|I428|I429|I43|I50|P290",
  pvd = "I70|I71|I731|I738|I739|I771|I790|I792|K551|K558|K559|Z958|Z959",
  cbvd = "G45|G46|I6|H340",
  dementia = "F00|F01|F02|F03|G30|F051|G311",
  copd = "I278|I279|J40|J41|J42|J43|J44|J45|J46|J47|J60|J61|J62|J63|J64|J65|J66|J67|J684|J701|J703",
  rheu = "M05|M06|M315|M32|M33|M34|M351|M353|M360",
  pepulc = "K25|K26|K27|K28",
  plegia = "G041|G114|G801|G802|G81|G82|G830|G831|G832|G833|G834|G839",
  diab_nc = "E100|E101|E106|E108|E109|E110|E111|E116|E118|E119|E120|E121|E126|E128|E129|E130|E131|E136|E138|E139|E140|E141|E146|E148|E149",
  diab_wc = "E102|E103|E104|E105|E107|E112|E115|E117|E122|E123|E124|E125|E127|E132|E133|E134|E135|E137|E142|E143|E144|E145|E147",
  mild_ld = "B18|K700|K701|K702|K703|K709|K713|K714|K715|K717|K73|K74|K760|K762|K763|K764|K768|K769|Z944",
  modsev_ld = "I850|I859|I864|I982|K704|K711|K721|K729|K765|K766|K767",
  renal = "I120|I131|N032|N033|N034|N035|N036|N037|N052|N053|N054|N055|N056|N057|N18|N19|N250|Z490|Z491|Z492|Z940|Z992",
  malig = "C0|C1|C20|C21|C22|C23|C24|C25|C26|C30|C31|C32|C33|C34|C37|C38|C39|C40|C41|C43|C45|C46|C47|C48|C49|C50|C51|C52|C53|C54|C55|C56|C57|c58|C6|C70|C71|C72|C73|C74|C75|C76|C81|C82|C83|C84|C85|C88|C90|C91|C92|C93|C94|C95|C96|C97",
  mst = "C77|C78|C79|C80",
  hiv = "B20|B21|B22|B24"
)

df_thromb_with_comorb <- df_thromb_join_vars |>
  mutate(cci_age = case_when(
    age >= 80 ~ 4,
    age >= 70 ~ 3,
    age >= 60 ~ 2,
    age >= 50 ~ 1,
    TRUE ~ 0
  )) |>
  mutate(cci_mi = if_else(str_detect(der_diagnosis_all, df_cci_codes$mi), 1, 0)) |>
  mutate(cci_chf = if_else(str_detect(der_diagnosis_all, df_cci_codes$chf), 1, 0)) |>
  mutate(cci_pvd = if_else(str_detect(der_diagnosis_all, df_cci_codes$pvd), 1, 0)) |>
  mutate(cci_cbvd = if_else(str_detect(der_diagnosis_all, df_cci_codes$cbvd), 1, 0)) |>
  mutate(cci_dementia = if_else(str_detect(der_diagnosis_all, df_cci_codes$dementia), 1, 0)) |>
  mutate(cci_copd = if_else(str_detect(der_diagnosis_all, df_cci_codes$copd), 1, 0)) |>
  mutate(cci_rheu = if_else(str_detect(der_diagnosis_all, df_cci_codes$rheu), 1, 0)) |>
  mutate(cci_pepulc = if_else(str_detect(der_diagnosis_all, df_cci_codes$pepulc), 1, 0)) |>
  mutate(cci_plegia = if_else(str_detect(der_diagnosis_all, df_cci_codes$plegia), 2, 0)) |>
  mutate(cci_diab = case_when(
    str_detect(der_diagnosis_all, df_cci_codes$diab_wc) ~ 2,
    str_detect(der_diagnosis_all, df_cci_codes$diab_nc) ~ 1,
    TRUE ~ 0
  )) |>
  mutate(cci_liver = case_when(
    str_detect(der_diagnosis_all, df_cci_codes$modsev_ld) ~ 3,
    str_detect(der_diagnosis_all, df_cci_codes$mild_ld) ~ 1,
    TRUE ~ 0
  )) |>
  mutate(cci_renal = if_else(str_detect(der_diagnosis_all, df_cci_codes$renal), 2, 0)) |>
  mutate(cci_malig = if_else(str_detect(der_diagnosis_all, df_cci_codes$malig), 2, 0)) |>
  mutate(cci_mst = if_else(str_detect(der_diagnosis_all, df_cci_codes$mst), 6, 0)) |>
  mutate(cci_hiv = if_else(str_detect(der_diagnosis_all, df_cci_codes$hiv), 6, 0)) |>
  tidytable::mutate_rowwise(
    cci = sum(tidytable::c_across(starts_with("cci_")))
  ) |>
  ungroup() |>
  select(-starts_with("cci_")) |> 
  mutate(cci_level = case_when(
    cci == 0 ~ "No comorbidities",
    cci <= 2 ~ "Mild comorbidities",
    cci <= 4 ~ "Moderate comorbidities",
    cci >= 5 ~ "Severe comorbidities"
  )) |>
  mutate(cci_level = factor(
    cci_level,
    levels = c(
      "No comorbidities",
      "Mild comorbidities",
      "Moderate comorbidities",
      "Severe comorbidities"
    )
  ))

gc()
gc()
gc()

# UNIVAR THOSE UNDERGOING THROMB LOWER COMORBS:
# TODO MAY NEED A MORE THOROUGH MULTIVAR ANALYSIS
# df_thromb_with_comorb |> 
#   count(cci, thromb_spell) |>
#   # count(cci_level, thromb_spell) |>
#   group_by(thromb_spell) |>
#   mutate(p = n / sum(n)) |>
#   ungroup() |>
#   mutate(thromb_spell = as_factor(thromb_spell)) |> 
#   ggplot(aes(cci, p)) +
#   # ggplot(aes(cci_level, p)) +
#   geom_line(aes(col = thromb_spell)) +
#   geom_point(aes(col = thromb_spell)) +
#   # facet_wrap(vars(thromb_spell), ncol = 1)+
#   NULL
