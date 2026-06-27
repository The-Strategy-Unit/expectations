# README
# Run the analysis pipeline

# cat(keyring::key_get("login"))


# PARAMETERS --------------------------------------------------------------

# CHOOSE WHICH PROCEURES / PODs TO LOAD:
run_elec_tavi <- FALSE 
run_emer_tavi <- FALSE
run_emer_thrb <- FALSE

# CHOOSE WHETHER TO START FROM SCRATCH:
rerun_tavi_sql <- TRUE
rerun_thromb_sql <- TRUE
rerun_ref_data_sql <- TRUE
download_ref_datasets <- FALSE


# -------------------------------------------------------------------------

# REMEMBER POP-UP! 
# Password required:
# cat(keyring::key_get("login"))
source(here::here("R", "01_setup.R"))


source(here("R", "011_reference_data.R"))

# FOR BOTH TAVIs:
source(here("R", "22_TAVI_load.R"))
source(here("R", "23_TAVI_lsoa_standard.R"))
source(here("R", "24_TAVI_EL_exclusions.R"))
source(here("R", "25_TAVI_EL_tidy.R"))
source(here("R", "26_TAVI_centre_lkps.R"))
source(here("R", "27_TAVI_distance_lkp.R"))


# THEN ELECTIVE:

# EMERGENCY:
source(here("R", "34_TAVI_EM_exclusions.R"))
source(here("R", "35_TAVI_EM_tidy.R"))

