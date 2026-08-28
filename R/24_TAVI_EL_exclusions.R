# README
# Select elective episodes for england-resident patients with
# an lsoa assigned (98%) . We can't get imd for others

df_tavi_elective_exclusions <- df_tavi_standardise_lsoa |>
  # ONLY ENGLAND-RESIDENT PATIENTS WITH LSOA (97% PROB DUE TO LOW 25/26 LSOA RECORDING):
  filter(str_detect(lsoa21_bfit, "^E")) |> 
  filter(admission_method %in% c("11", "12", "13")) |> 
  filter(fyear != "2025/26") |> 
  filter(sex %in% c("1", "2")) 
  # TODO UNCHECKED - THE FILTER OF SEX HERE COULD CAUSE PROBLEMS DOWNSTREAM
  
  

