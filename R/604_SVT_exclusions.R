# README
# Select elective episodes for england-resident patients with
# an lsoa assigned (99.4%) . We can't get IMD for others

# df_svt_raw |> 
#   # count(fyear)
#   # ONLY ENGLAND-RESIDENT PATIENTS WITH LSOA:
#   count(str_detect(lsoa21code, "^E")) |> 
#   mutate(p = n/sum(n))


df_svt_exclusions <- df_svt_raw |>
  # ONLY ENGLAND-RESIDENT PATIENTS WITH LSOA:
  filter(str_detect(lsoa21code, "^E")) |> 
  mutate(yr = as.integer(str_sub(fyear, 6, 7)) - 10) |> 
  filter(yr < 15) |> 
  filter(died_in_index_spell == 0) |>
  filter(sex %in% c("1", "2")) 


# df_svt_exclusions |> 
#   count(der_procedure_all, sort = T) |> 
#   mutate(p = n/sum(n)) |> 
#   filter(str_detect(der_procedure_all, "K621"))

