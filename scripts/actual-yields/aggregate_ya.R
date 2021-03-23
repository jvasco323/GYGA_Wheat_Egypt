### ------------------------------------------------------------------------ ###
###                Aggregate actual yields at buffer zone level              ###
### ------------------------------------------------------------------------ ###

library(rgygaGIS)

# Load data ---------------------------------------------------------------- ###

ya <- read.csv("data/actual-yields/cleaned/EGY_ya_cleaned.csv")
egy_mod <- readRDS("data/actual-yields/extracted/gadm36_EGY_1_sf_mod.rds")
path_buffer_zones <- file.path("data/weather-stations/dws/wheat/ready/",
                               "designated_buffer_zones_wheat_egypt_only_v2.gpkg")
bz_sf <- sf::st_read(path_buffer_zones,
                     quiet = TRUE)


# Aggregate actual yields at buffer zone level ----------------------------- ###

ya_bufferzones <- rgygaGIS::aggregate_regional_stats(data_df = ya,
                                                     regions_sf = egy_mod,
                                                     buffer_zones_sf = bz_sf, 
                                                     region_variable_chr = "subregion")

# mapview(egy_mod) + mapview(bz_sf, col.region = "darkred", alpha.regions = 0.5)
