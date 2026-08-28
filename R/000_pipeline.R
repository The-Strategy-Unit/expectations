# README
# Run the analysis pipeline

# clipr::write_clip(capture.output(cat(keyring::key_get("login"))))

# TODO 
# # PARAMETERS --------------------------------------------------------------
# 
# # CHOOSE WHICH PROCEURES / PODs TO LOAD:
# run_elec_tavi <- FALSE 
# run_emer_tavi <- FALSE
# run_emer_thrb <- FALSE
# 
# # CHOOSE WHETHER TO START FROM SCRATCH:
# rerun_tavi_sql <- TRUE
# rerun_thromb_sql <- TRUE
# rerun_ref_data_sql <- TRUE
# download_ref_datasets <- FALSE
# 

# SETUP -----------------------------------------------------------------

# REMEMBER POP-UP! 
# Password required:
# cat(keyring::key_get("login"))
source(here::here("R", "001_setup.R"))

source(here("R", "002_reference_data.R"))

# AFIB CATHETER ABLATION -----------------------------------------

# # source(here("R", "502_AFIB_load.R"))
df_afib_raw <-  readRDS(here("data_raw", "df_afib_raw.rds"))
# 
source(here("R", "504_AFIB_exclusions.R"))
source(here("R", "506_AFIB_centre_lkps.R"))
source(here("R", "507_AFIB_distance_lkp.R"))
source(here("R", "508_AFIB_join_tables.R"))
source(here("R", "509_AFIB_score_lookback.R"))
# source(here("R", "510_AFIB_final_processing.R"))

# df_afib_join_tables_scored |> saveRDS(here("data_raw", "df_afib_join_tables_scored.rds"))
df_afib_join_tables_scored <- readRDS(here("data_raw", "df_afib_join_tables_scored.rds"))

# df_afib_cleaned |> saveRDS(here("data_raw", "df_afib_cleaned.rds"))
df_afib_cleaned <-  readRDS(here("data_raw", "df_afib_cleaned.rds"))




# TAVI ----------------------------------------------------------

# FOR BOTH TAVIs
source(here("R", "22_TAVI_load.R"))
source(here("R", "23_TAVI_lsoa_standard.R"))
source(here("R", "24_TAVI_EL_exclusions.R"))
source(here("R", "25_TAVI_EL_tidy.R"))
source(here("R", "26_TAVI_centre_lkps.R"))
source(here("R", "27_TAVI_distance_lkp.R"))

# THEN:

# FOR ELECTIVE:
source(here("R", "28_TAVI_EL_join_tables.R"))

# FOR EMERGENCY:
source(here("R", "34_TAVI_EM_exclusions.R"))
source(here("R", "35_TAVI_EM_tidy.R"))
source(here("R", "38_TAVI_EM_join_tables.R"))
# source(here("R", "39_TAVI_EM_model_df_prep.R"))


# -------------------------------------------------------------------------




# THROMBECTOMY ----------------------------------------------------------

# TODO EXTEND NARROW SUPERSPELL QUALIFICATION LOGIC
# TODO PROBABLY START AT 2011/12 (BUT CERTAINLY FOR EMERGENCY)
# TODO APPLY clubSandwich() - to address small cluster inference problem.
# 
# source(here("R", "02_THROMB_load.R"))
# source(here("R", "03_THROMB_lsoa_standard.R"))
# source(here("R", "04_THROMB_exclusions.R"))
# source(here("R", "05_THROMB_tidy_episodes.R"))
# source(here("R", "06_THROMB_centre_lkps.R"))