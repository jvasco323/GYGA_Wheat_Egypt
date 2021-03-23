### ------------------------------------------------------------------------ ###
###                 Send data to Chandra for confirmation                    ###
### ------------------------------------------------------------------------ ###

suppressPackageStartupMessages(
  library(tidyverse)
)

### Problem: there seems to be 3 land type category:
### Old Land, New Land and Tota (Total ?).
### For the name it seems that Tota is sum of Old Land and New Land
### However, while computing the summing manually  
### Area and Production over Old and New land  we notice some discrepancies with Tota
### Same thing appears when averaging Yield over Old and New land

data_iu <- read.csv("data/actual-yields/extracted/EGY_actual_yields.csv")

# Produce list of tibbles: each tibble correspond to a variable
# and holds 3 distincts columns for each land_type (Old Land, New Land, Tota)
l_var <- data_iu %>% 
  pivot_longer(cols = matches("^A|P|Y", ignore.case = FALSE),
               names_to = "variable",
               values_to = "value") %>% 
  split(.$variable) %>% 
  map(~ pivot_wider(data = .x,
                    names_from = "land_type",
                    values_from =  "value"))

# Sum between Old Land and New Land
l_var[c("Area_ha", "Prod_ton")] <- 
  l_var[c("Area_ha", "Prod_ton")] %>% 
  map(~ mutate(.x, 
               total = `New Land` + `Old Land`,
               delta = Tota - total))

# Mean between Land and New Land
l_var[["Yield_tonha"]] <-
  l_var[["Yield_tonha"]] %>% 
  rowwise() %>% 
  mutate(mean = mean(c(`New Land`, `Old Land`), na.rm = TRUE),
         delta = Tota - mean)

# Save all data points with obvious discrepancies between Tota and total
# delta > 1 ; to be sent to Chandra
l_var %>% 
  map(~ filter(.x, delta > 1)) %>% 
  bind_rows() %>% 
  as.data.frame() %>% 
  write_csv("data/actual-yields/extracted/land_type_discrepancies.csv")

