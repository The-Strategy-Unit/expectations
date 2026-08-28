# README
# Load packages and establish DB connection. 
# Note: you will be prompted for a password via pop-up.

clipr::write_clip(capture.output(cat(keyring::key_get("login"))))

# library("gt")
# library("gtExtras")
library("sf")
library("DBI")
# library("pak")
library("here")
library("odbc")
# library("mgcv")
library("broom")
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

source(here("R", "004_charlson_function.R"))

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

