### GYGA Wheat Egypt actual yields ETL pipeline

# Extract raw actual yield data from files received from country agronomists
source("scripts/actual-yields/extract_ya.R")

# Create new country polygon with subregions names matching the ones in actual yields
source("scripts/actual-yields/match_names.R")

# Clean actual yield data
source("scripts/actual-yields/clean_ya.R")

# Aggregate actual yield data at buffer zone levelS
source("scripts/actual-yields/aggregate_ya.R")

# Render recap document for Chandra
rmarkdown::render("scripts/actual-yields/GYGA_wheat_EGY_ya_recap.Rmd")