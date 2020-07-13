# =========================================================================================== #
# Load libraries ---------------------------------------------------------------------------- #
# =========================================================================================== #

library(tidyverse)
library(sf)
library(mapview)
library(tmap)

# =========================================================================================== #
# Load data --------------------------------------------------------------------------------- #
# =========================================================================================== #

buff <- st_read("./data/weather-stations/dws/wheat/ready/designated_buffer_zones_wheat_egypt_only.gpkg")
ws <- st_read("./data/weather-stations/dws/wheat/ready/designated_weather_stations_wheat_egypt_only.gpkg")

path_country_polygons <- "./data/shape-country/"

country_polygons <- path_country_polygons %>%
  list.files() %>%
  str_subset("gadm36_[A-Z]{3}_0_sf\\.rds") %>%
  file.path(path_country_polygons, .) %>% 
  map(readRDS)

names(country_polygons) <- map_chr(country_polygons, ~ unique(.x$GID_0))
country_polygons[["ESP"]] <- NULL

# =========================================================================================== #
# Produce map ------------------------------------------------------------------------------- #
# =========================================================================================== #

l_buff <- split(buff, f = buff$iso3)
l_ws <- split(ws, ws$iso3)

map_country <- function(country, buff, ws){
  #buff$GYGA_CZ <- droplevels(buff$GYGA_CZ)
  tm_shape(country) + tm_polygons( col = "cornsilk", alpha = 0.5) +
    tm_shape(buff) + tm_polygons(col = "GYGA_CZ", alpha = 0.5) +
    tm_shape(ws) + tm_dots(size = 1, col = "red", alpha = 0.5) + 
    tm_text(text = "station_name", auto.placement = TRUE)}

lp <- purrr::pmap(.l = list(country_polygons, l_buff, l_ws), .f = map_country)

# =========================================================================================== #
# Save map ---------------------------------------------------------------------------------- #
# =========================================================================================== #

file_nms <-  file.path("./data/maps/country/wheat/", paste0("map_wheat_", names(country_polygons), ".png"))
walk2(lp, file_nms, ~ tmap_save(.x, filename = .y))

# =========================================================================================== #
# THE END ----------------------------------------------------------------------------------- #
# =========================================================================================== #