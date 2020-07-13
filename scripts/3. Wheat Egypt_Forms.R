# =========================================================================================== #
# Load libraries ---------------------------------------------------------------------------- #
# =========================================================================================== #

library(tidyverse)
library(sf)
library(readxl)
library(openxlsx)

tictoc::tic()

# =========================================================================================== #
# Load data --------------------------------------------------------------------------------- #
# =========================================================================================== #

# Load template
form_template <- read_xlsx("./data/crop-management/raw-forms/template/crop_management_template.xlsx")

# Load designated weather stations
ws <- sf::st_read("./data/weather-stations/dws/wheat/ready/designated_weather_stations_wheat_egypt_only.gpkg")

# Define crop and countries (iso3 and names)
crop = "wheat"
iso3 = as.character(unique(ws$iso3))
country = countrycode::countrycode(sourcevar = iso3, origin = "iso3c", destination = "country.name")

for (i in 1:length(iso3)){
  form <- form_template
  
  # Get weather station by country
  weather_stations <- ws$station_name[ws$iso3 == iso3[i]]
  weather_stations <- as.character(weather_stations)
  
  # Create new columns for each weather station
  for(w in weather_stations){
    form[[w]] <- rep(" ", nrow(form))}
  
  # Fill in cropping_system
  form[ 1, 3:ncol(form)] <- form$Example[1]
  form_name <- sprintf("GYGA_cropm_form_%s_%s.xlsx", crop, iso3[i])
  form_path <- file.path("./data/crop-management/raw-forms/", form_name)
  write.xlsx(as.data.frame(form), file = form_path, row.names = FALSE)}

# =========================================================================================== #
# Crop management manuals ------------------------------------------------------------------- #
# =========================================================================================== #

# Read in the template
rmd_temp <- readLines("./data/crop-management/raw-forms/template/crop_management_template.Rmd")

# Substitute the place-holders in the template by the custom values.
l_rmd <- purrr::map2(.x = country, .y = iso3, .f = ~ stringr::str_replace_all(string = rmd_temp, pattern = c("CROP" = crop, "COUNTRY" = .x, "iso3" = .y)))

# Save file with ap
names_rmd <- paste0("GYGA_cropm_manual_", crop, "_" , iso3, ".Rmd")
files_rmd <- file.path("./data/crop-management/raw-forms/", names_rmd)
purrr::walk2(.x = l_rmd, .y = files_rmd, .f = ~ write(x = .x, file = .y))

# =========================================================================================== #
# THE END ----------------------------------------------------------------------------------- #
# =========================================================================================== #

tictoc::toc()
