# =========================================================================================== #
# Load libraries ---------------------------------------------------------------------------- #
# =========================================================================================== #

library(tidyverse)
library(sf)
library(raster)
library(mapview)
library(rgygaGIS)
library(here)
library(purrr)
mapviewOptions(vector.palette = colorRampPalette(c("darkred", "yellow", "darkgreen")))

tictoc::tic()

# =========================================================================================== #
# Load data --------------------------------------------------------------------------------- #
# =========================================================================================== #

# Download country polygons 
country_iso3 <- c("EGY") #RUS

# Load country polygons 
path_country_polygons <- "./data/shape-country/"
country_polygons <- 
  path_country_polygons %>%
  list.files() %>%
  str_subset("gadm36_[A-Z]{3}_0_sf\\.rds") %>%
  file.path(path_country_polygons, .) %>% 
  map(readRDS) %>%
  reduce(rbind)

# Load climate zones shape file
climate_zones <- sf::st_read("./data/climate-zones/GYGAClimateZones.shp")
climate_zones <- sf::st_make_valid(climate_zones)
new_bb <-  sf::st_bbox(climate_zones)
new_bb[1] <- -180
attr(new_bb, "class") <- "bbox"
attr(sf::st_geometry(climate_zones), "bbox") <- new_bb 

# Load SPAM crop mask raster
wheat <- raster::raster("./data/crop-mask/global harv area/spam2010V1r1_global_H_WHEA_A.tif")

# =========================================================================================== #
# Climate zone selection -------------------------------------------------------------------- #
# =========================================================================================== #

# Designated climate zones
dcz <- rgygaGIS::select_climate_zones(country_polygons = country_polygons, crop_spam = wheat, parallel = FALSE)
p_dcz <- mapview(dcz, zcol = "pnha")

# Subset crop mask to match country polygons bounding box
crop_mask <- raster::crop(x = wheat , y = country_polygons)

# Subset crop mask to exactly match country borders
crop_mask <- raster::mask(x = crop_mask, mask = country_polygons)
(p_mask <- mapview::mapview(crop_mask, legend = FALSE, zcol = "GYGA_CZ"))

# Extract crop harvested area at national scale
country_polygons <- 
  country_polygons %>%
  split(.$GID_0) %>%
  map(function(country){
    country$nha <- as.numeric(raster::extract(crop_mask, country, fun = sum, na.rm = TRUE))
    return(country)
  }) %>%
  reduce(rbind)

# Create polygon layer with climate zones by country --> this takes a while
climate_zones_cty <- 
  climate_zones %>%
  st_crop(country_polygons) %>% 
  st_intersection(country_polygons) 

# Plot climate zones
climate_zones_cty$GYGA_CZ <- as.factor(climate_zones_cty$GYGA_CZ)
mapview(climate_zones_cty, zcol = "GYGA_CZ", legend = FALSE)

# Extract crop harvested area at climate zone scale
climate_zones_cty <- 
  climate_zones_cty %>%
  split(rownames(.)) %>%
  map(function(climate_zone){
    climate_zone$cz_nha <- as.numeric(raster::extract(crop_mask, climate_zone, fun = sum, na.rm = TRUE))
    return(climate_zone)
  }) %>%
  reduce(rbind) 

# Keep climate zones with more than 5% of national harvested area
percent = 0.05
climate_zones_cty$pnha <- climate_zones_cty$cz_nha / sum(climate_zones_cty$cz_nha) 
designated_climate_zones <- climate_zones_cty[climate_zones_cty$pnha > percent, ]

# Plot climate zones with more than 5% of national harvested area
mapview::mapview(designated_climate_zones, zcol = "pnha")
(p_dcz <- mapview::mapview(designated_climate_zones, legend = FALSE, zcol = "GYGA_CZ"))

# Export climate zones
sf::st_write(obj = designated_climate_zones, delete_dsn = TRUE, dsn = "./data/weather-stations/dws/wheat/ready/designated_climate_zones_wheat_egypt_only.gpkg")

# =========================================================================================== #
# Weather station selection ----------------------------------------------------------------- #
# =========================================================================================== #

# Get weather station metadata
ws <- rgygaGIS::gyga_station

# Convert country names to country iso3; warning about Kosovo, safe to ignore
ws$iso3 <- countrycode::countrycode(sourcevar = ws$country_name, origin = "country.name", destination = "iso3c")

# Keep weather stations within countries of interest
ws <- 
  ws %>% 
  filter(iso3 %in% designated_climate_zones$GID_0)

# Turn weather stations data.frame into sf data.frame
ws <- 
  ws %>% 
  st_as_sf(coords = c("longitude", "latitude")) %>%
  st_set_crs(4326)
(p_ws <- mapview(ws, zcol = "station_name", legend = FALSE, col.region = "darkred"))
p_dcz + p_ws

# Keep weather stations in designated climate zones / left = FALSE translates to an inner join
designated_climate_zones$climatezone_id <- as.numeric(paste0(8180, designated_climate_zones$GYGA_CZ)) 
designated_weather_stations <- inner_join(ws, st_drop_geometry(designated_climate_zones), by='climatezone_id')
(p_dws <- mapview(designated_weather_stations, zcol = "station_name", legend = FALSE, col.region = "darkred"))

# Export weather stations
sf::st_write(obj = designated_weather_stations, delete_dsn = TRUE, dsn = "./data/weather-stations/dws/wheat/ready/designated_weather_stations_wheat_egypt_only.gpkg")

# =========================================================================================== #
# Buffer zone selection --------------------------------------------------------------------- #
# =========================================================================================== #

# Draw buffer zone around weather stations
# Buffer zone not drawn properly: local re-projection needed!!! --> Antoine updates package.
designated_buffer_zones <- 
  designated_weather_stations  %>%
  st_transform(3488) %>%
  st_buffer(dist = 100000) %>%
  st_transform(4326)
p_dws_buff <- mapview(designated_buffer_zones, zcol = "station_name", legend = FALSE, col.region = "darkred", alpha.regions = 0.1)
p_dcz + p_dws + p_dws_buff

# Extract crop harvested area at buffer zone scale
designated_buffer_zones <- 
  designated_buffer_zones %>%
  split(rownames(.)) %>%
  map(function(climate_zone){
    climate_zone$bz_nha <- as.numeric(raster::extract(crop_mask, designated_buffer_zones, fun = sum, na.rm = TRUE))
    return(climate_zone)
  }) %>%
  reduce(rbind) 

# Compute % of national harvested area within buffer zones
dws_bz_check <- rgygaGIS::extract_area(polygons = designated_buffer_zones, raster_mask = crop_mask, area_name = "bz_nha")
dws_bz_check <- dplyr::mutate(dws_bz_check, pnha_bz = .data$bz_nha / .data$nha) 

# 50% national harvested area within the buffer zones?
# - yes, then no need for more weather stations;
# - no, then additional weather stations needed from Hendrik
dws_bz_check$pnha_bz
p_mask + p_dcz + p_dws + p_dws_buff

# Export buffer zones
sf::st_write(obj = designated_buffer_zones, delete_dsn = TRUE, dsn = "./data/weather-stations/dws/wheat/ready/designated_buffer_zones_wheat_egypt_only.gpkg")

# =========================================================================================== #
# Check water regimes ----------------------------------------------------------------------- #
# =========================================================================================== #

source("./scripts/# diff_water_regime_funcs.R")

# Load SPAM crop mask raster
spam_path <- "./data/crop-mask/global harv area/"
spam_files <- c("spam2010V1r1_global_H_WHEA_I.tif", "spam2010V1r1_global_H_WHEA_R.tif")
spam_rasters <- map(here(spam_path, spam_files), raster::raster)
names(spam_rasters) <- c("irrigated", "rainfed")

# Calculate % irrigated area per country, climate zone and buffer zone
future::plan(future::multiprocess)
l_pols <- furrr::future_map2(.x = list(country = country_polygons, dcz = designated_climate_zones, dbz = designated_buffer_zones),
                             .y = list("nha", "cz_nha", "bz_nha"),
                             ~ differentiate_water_regimes(pols = .x, spam_rasters, var_ha = .y), 
                             .progress = TRUE)

# Export water regime (.csv)
path_water_regime <- "./data/crop-mask/water_regime"
l_pols[["country"]] %>%
  dplyr::select(NAME_0, GID_0, irrigated, rainfed, per_irrigated, per_rainfed) %>%
  st_drop_geometry() %>%
  arrange(GID_0) %>%
  readr::write_csv(path = here(path_water_regime, "SPAM_wheat_water_regime_COUNTRY.csv"))
l_pols[["dcz"]] %>%
  dplyr::select(NAME_0, GID_0, GYGA_CZ, ID, irrigated, rainfed, per_irrigated, per_rainfed) %>%
  st_drop_geometry() %>%
  arrange(GID_0, GYGA_CZ) %>%
  readr::write_csv(path = here(path_water_regime, "SPAM_wheat_water_regime_CZ.csv"))
l_pols[["dbz"]] %>%
  dplyr::select(NAME_0, GID_0, GYGA_CZ, station_id, station_name, irrigated, rainfed, per_irrigated, per_rainfed) %>%
  st_drop_geometry() %>%
  arrange(GID_0, ) %>%
  readr::write_csv(path = here(path_water_regime, "SPAM_wheat_water_regime_RWS.csv"))

# =========================================================================================== #
# THE END ----------------------------------------------------------------------------------- #
# =========================================================================================== #

tictoc::toc()
