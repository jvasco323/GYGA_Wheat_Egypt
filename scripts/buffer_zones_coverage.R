
library(dplyr)
library(sf)

buffer_zones_file <- file.path("data/weather-stations/dws/wheat/ready/", 
                               "designated_buffer_zones_wheat_egypt_only_v2.gpkg")
buffer_zones <- st_read(buffer_zones_file, quiet = TRUE)

buffer_zones %>% 
  st_drop_geometry() %>% 
  summarise(buffer_zone_coverage_percentage = (sum(bz_nha)/ unique(nha) * 100))
