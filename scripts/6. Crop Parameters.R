# ================================================================================================== #
# Get temperature sums for wheat in Egypt
# Global Yield Gap Atlas
# ================================================================================================== #

library(dplyr)
library(ggplot2)
library(readxl)

source("./scripts/crop_parameters_funcs.R")

# ================================================================================================== #
# Load data ---------------------------------------------------------------------------------------- #
# ================================================================================================== #

### Crop management data
# !! later those should be read directly from file
l_int_D1 <- list(nile_delta = c(80, 105),
                 upper_egpyt = c(75, 100))
l_int_D2 <- list(nile_delta = c(45, 70),
                 upper_egpyt = c(40, 65))

### WOFOST parameters
# Tmax is derived from DTSMTB
# !! later those should be read directly from PCSE yaml files
WOFOST_params_wheat <- list(
  TSUMEM = 120,
  TBASEM = 0,
  TEFFMX = 30,
  TBASE = 0,
  Tmax = 30
)

### Sowing dates
sowing_date <- read.csv("./data/crop-management/sowing_date.csv")
# Rename year crop_year, year corresponds here to the cropping season
# i.e. year were harvest took place
names(sowing_date)[grep("year", names(sowing_date))] <- "crop_year"
sowing_date$year <- as.numeric(stringr::str_extract(sowing_date$sowing, "\\d{4}$"))

### Weather data

wofost_input_path <- "./data/wofost-inputs/"
weather_files <- c("weather_nasa_UpperEgypt.xlsx", "weather_agera5_NileDelta.xlsx")

weather_paths <- file.path(wofost_input_path, weather_files)

l_weather_data_raw <- map(weather_paths, ~ read_excel(.x, sheet = "Sheet1"))
l_weather_data <- map(l_weather_data_raw, process_weather_data)

# ================================================================================================== #
# Weather station 1 -------------------------------------------------------------------------------- #
# ================================================================================================== #

## Make a list of arguments varying by weather stations
vargs_TSUM <- list(weather_data = l_weather_data,
                   intD1 = l_int_D1,
                   intD2 = l_int_D2)

## Call the main function in the proper way: telling it which
## arguments vary and which are constant across weather stations
list_TSUM <- purrr::pmap(
  vargs_TSUM, 
  ~ compute_TSUM(weather_data = ..1, 
                 sowing_date = sowing_date, 
                 WOFOST_params = WOFOST_params_wheat,
                 intD1 = ..2,
                 intD2 = ..3)
)
names(list_TSUM) <- c("nile_delta", "upper_egpyt")

TSUM <- dplyr::bind_rows(list_TSUM, .id = "station_name")

tidy_TSUM <- tidyr::pivot_longer(data = TSUM, 
                                 cols = c("TSUM1", "TSUM2"),
                                 names_to = "Parameter", values_to = "TSUM")

## Plot temperature sums

hist_TSUM <- ggplot(tidy_TSUM)+
  aes(x = TSUM, fill = Parameter)+
  geom_histogram(binwidth = 10, colour = "black")+
  xlab(expr(TSUM ~ degree*C.day^{-1}))+
  facet_wrap(. ~ station_name)
TSUM_mean <- tidy_TSUM %>% 
  group_by(Parameter) %>% 
  summarise(value = round(mean(TSUM), digits = 0), .groups = "drop")
hist_TSUM + geom_vline(xintercept = TSUM_mean$value, linetype = "dashed", size = 1)

# Save plot to pdf

# (....)


# ================================================================================================== #
# THE END ------------------------------------------------------------------------------------------ #
# ================================================================================================== #
