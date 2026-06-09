







# PUT ON GITHUB !!!







df_thromb_with_dist |> 
  count(fyear)

df_thromb_with_dist |> 
  count(is.na(sex))

# AGE GETTING V. SLIGHTLY YOUNGER OVER TIME
df_thromb_with_dist |> 
  group_by(fyear) |> 
  reframe(age = quantile(age)) |> 
  mutate(stat = rep(1:5, 12)) |> 
  pivot_wider(names_from = stat, values_from = age)

# ETHNICITY CODING 
df_thromb_with_dist |> 
  count(fyear, na = is.na(ethnic_group)) |> 
  group_by(fyear) |> 
  mutate(p = n/sum(n)) |> 
  ungroup() |> 
  filter(na == T) |> 
  arrange(fyear)


# admission method --------------------------------------------------------

df_thromb_with_dist |> 
  filter(thromb == 1) |> 
  count(der_management_type, admission_method, sort = T) |> 
  mutate(p = n/sum(n)) |> 
  filter(der_management_type == "EM") |> 
  summarise(sum(p))
  filter(!der_management_type == "EM") |> 
  print(n=40)

# 97% HAVE THROMB IN FIRST EPI AFTER TRANSFER
# 99% HAVE THROMB IN FIRST TWO EPIS AFTER TRANSFER
df_thromb_with_dist |> 
  filter(thromb == 0) |> 
  filter(admission_method == "81") |> 
  count(der_episode_number, sort = T) |> 
  mutate(p = n/sum(n))


# EMERGENCY ADMISSION, 85% IN FIRST 
df_thromb_with_dist |> 
  filter(der_management_type == "EM") |> 
  count(der_episode_number, sort = T) |> 
  mutate(p = n/sum(n))

# TODO WANT TO CHECK THAT WE ONLY PICK UP A SINGLE EPISODE FOR EACH SPELL
# TODO I.E. WE DON'T PICK UP LATER EPISODES FROM A PATIENT WHO HAS HAD A THROMBO IN THE FIRST

# TODO WE NEED SPELL ID AND PATIENT ID


# FOR PATIENTS WITH CEREBRAL INF
# SAME THROMBO PATIENT, SPELL ONLY PICK OUT THROMBO EPI
# SAME NO THROMBO PATIENT, SPELL ONLY, PICK OUT FIRST EPi? - COS THIS IS THE ONE 
# WHICH IS MOST LIKELY TO DECIDE WHETHER THROMB OR NOT

# UNI/MULTIVAR ANALYSIS OF THROMB WITH:
# imd_decile 
# rural
# region
# cci 
# distance_nr_ctr 

# imd_decile --------------------------------------------------------------
# rural --------------------------------------------------------------
# region --------------------------------------------------------------
# cci ---------------------------------------------------------------------
# distance_nr_ctr ---------------------------------------------------------

