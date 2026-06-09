# README
# Load packages and establish DB connection. 
# Note: you will be prompted for a password via pop-up.

  # .3C]-^'X@g9P,qM
# Internal_Reference	.SiteToLSOA_DriveTime
# UKHF_Rural_Urban_Class.	LSOAs_2021_Map1
# UKHF_Demography.Index_Of_Multiple_Deprivation_By_LSOA1
# Internal_Reference	.Region
# age_at_cds..., sex,
# ethnic_group 
# charlson - requires age and der diag all

# --LEFT JOIN (
#   --SELECT providersitecode, providersitename, lsoaname, distancemiles, offpeakdrivetime 
#   --FROM Internal_Reference.SiteToLSOA_DriveTime
#   --) travel
# --ON

# library("gt")
# library("gtExtras")
library("sf")
library("DBI")
# library("pak")
library("here")
library("odbc")
# library("mgcv")
# library("broom")
library("dplyr")
library("purrr")
# library("furrr")
library("readr")
library("tidyr")
library("tibble")
library("readxl")
library("forcats")
library("ggplot2")
# library("ggrepel")
library("janitor")
library("keyring")
library("stringr")
# library("tsibble")
library("lubridate")
# library("patchwork")
# library("yardstick")

options(scipen=999) 


server <- keyring::key_get("server")
db <- keyring::key_get("db")


con_one <- DBI::dbConnect(
  odbc::odbc(),
  Driver = "ODBC Driver 18 for SQL Server",
  Server = server,
  Database = db,
  Authentication = "ActiveDirectoryInteractive"
)

# REMEMBER POP-UP!

