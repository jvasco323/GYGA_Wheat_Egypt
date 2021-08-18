### ------------------------------------------------------------------------ ###
###                           Clean extracted data                           ###
### ------------------------------------------------------------------------ ###

suppressPackageStartupMessages(
  library(tidyverse)
)


# Load actual yields in international units (iu)
data_iu <- as_tibble(read.csv(file.path("data/actual-yields/extracted", 
                                        "EGY_actual_yields.csv")))

# Chandra confirmed that the 'Tota' land type category was the sum of
# Old land + New land + Delta. There is no mention of delta in the raw data set
# but this might explain the big discrepency explain in the year 2018 especially.
# bottom line -> keeping only Tota (discarding values for Old and New Land)
data_iu <- data_iu %>% filter(land_type == "Tota") 

# Aggregate variables for year and governorates (over variety)
d <- data_iu %>%   
  group_by(year, Governorates) %>% 
  summarise(across(c(Area_ha, Prod_ton), sum, na.rm = TRUE),
            Yield_tonha = mean(Yield_tonha, na.rm = TRUE),
            .groups = "drop")

names(d) <- tolower(names(d))
d <- d %>% rename(yield_tha = yield_tonha,
                  production_t = prod_ton,
                  subregion = governorates)

duplicate_by_year <- d %>%
  group_by(year) %>%
  select(year, subregion) %>%
  summarise(nb_dup = sum(duplicated(subregion))) 
no_duplicate_subregion <- all(duplicate_by_year$nb_dup == 0)
stopifnot(no_duplicate_subregion)


# summary(d$yield_tha)
# summary(d$area_ha)
# summary(d$prod_ton)
# hist(d$yield_tha, breaks = 100)
# hist(log(d$area_ha), breaks = 100)

d <- d %>% 
  filter(yield_tha > 2)

## Add crop name
d$crop <- "Irrigated wheat"

d <- d %>% 
  select(crop, year, subregion, everything()) %>% 
  arrange(crop, year, subregion)

write_csv(d, "data/actual-yields/cleaned/EGY_ya_cleaned.csv")




