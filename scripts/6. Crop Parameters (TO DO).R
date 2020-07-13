# ================================================================================================== #
# Get temperature sums for wheat in Egypt
# Global Yield Gap Atlas
# ================================================================================================== #

library(tidyverse)
library(readxl)
library(zoo)
library(lubridate)

source("./scripts/# crop_parameters_funcs.R")

tictoc::tic()

# ================================================================================================== #
# Load data ---------------------------------------------------------------------------------------- #
# ================================================================================================== #

# Sowing dates
sowing_date <- read.csv("./data/crop-management/sowing_date.csv")

# Read crop data
TSUMEM <- 120
TBASE <- 0
# DTSMTB:
#     - [ 0.0,  0.0,
#         30.0, 30.0,
#         45.0, 30.0]
#     - daily increase in temperature sum as function of daily average temperature


# ================================================================================================== #
# Weather station 1 -------------------------------------------------------------------------------- #
# ================================================================================================== #

# Nile Delta
weather_nile_delta <- read_excel("./data/wofost-inputs/weather_nasa_NileDelta.xlsx", sheet = "Sheet1")
day <- as.Date(weather_nile_delta$DAY)
days <- data.frame(DAY = weather_nile_delta$DAY, Year = as.numeric(format(day, format = "%Y")), Month = as.numeric(format(day, format = "%m")), Day = as.numeric(format(day, format = "%d")))
weather_nile_delta <- merge(weather_nile_delta, days, by='DAY')

# Duration provided by agronomists
intD1 <- c(80, 105)
intD2 <- c(45, 70)
D1 <- ceiling(mean(intD1))
D2 <- ceiling(mean(intD2))

# Select only time and temperature variables in weather data
dtemp <- weather_nile_delta %>% filter(Year %in% sowing_date$year) %>% select(Year, Month, Day, TMIN, TMAX)

# Add a column with date in Julian days
dtemp <- dtemp %>% mutate(juld = paste(Year, Month, Day, sep = "-") %>% as_date() %>% yday())

# Degree days calculation
dtemp[] <- lapply(dtemp, as.numeric)
dtemp$dd <- ((dtemp$TMAX + dtemp$TMIN) / 2) - TBASE

# Compute yearly temperature sums
dtemp <- dtemp %>% group_by(Year) %>% mutate(TSUM = cumsum(dd)) %>% ungroup()

# Process weather data and tsums
TSUM_sowing <- juld_to_dd(sowing_date$doy, dtemp)
TSUM_emergence <- TSUM_sowing + TSUMEM
date_emergence <- dd_to_juld(TSUM_emergence, dtemp)
date_anthesis <- date_emergence + D1 
TSUM_anthesis <- juld_to_dd(date_anthesis, dtemp)
date_maturity <- date_anthesis + D2
TSUM_maturity <- juld_to_dd(date_maturity, dtemp)
TSUM_anthesis - TSUM_sowing %>% deframe() %>% mean()

# Calculate TSUM1 and TSUM2
TSUM1 <- TSUM_anthesis - TSUM_emergence
TSUM2 <- TSUM_maturity - TSUM_anthesis
TSUM <- tibble(TSUM1 = deframe(TSUM_anthesis - TSUM_emergence), TSUM2 = deframe(TSUM_maturity - TSUM_anthesis))
tidy_TSUM <- TSUM %>% tidyr::gather(key = "Parameter", value = "TSUM")
mean_TSUMs <- map(TSUM, ~ round(mean(.x), digits = 0))

# Plot temperature sums
hist_TSUM <- ggplot(tidy_TSUM)+
    aes(x = TSUM, fill = Parameter)+
    geom_histogram(binwidth = 10, colour = "black")+
    xlab(expr(tidy_TSUM ~ degree*C.day^{-1})) +
    theme_bw()
TSUM_mean <- tidy_TSUM %>% group_by(Parameter) %>% summarise(value = round(mean(TSUM), digits = 0))
hist_TSUM + geom_vline(xintercept = TSUM_mean$value, linetype = "dashed", size = 1)

# Save plot to pdf

# (....)

# ================================================================================================== #
# Weather station 2 -------------------------------------------------------------------------------- #
# ================================================================================================== #

# Upper Egypt
weather_upper_egypt <- read_excel("./data/wofost-inputs/weather_nasa_UpperEgypt.xlsx", sheet = "Sheet1")
day <- as.Date(weather_upper_egypt$DAY)
days <- data.frame(DAY = weather_upper_egypt$DAY, Year = as.numeric(format(day, format = "%Y")), Month = as.numeric(format(day, format = "%m")), Day = as.numeric(format(day, format = "%d")))
weather_upper_egypt <- merge(weather_upper_egypt, days, by='DAY')

# Duration provided by agronomists
intD1 <- c(75, 100)
intD2 <- c(40, 65)
D1 <- ceiling(mean(intD1))
D2 <- ceiling(mean(intD2))





# ================================================================================================== #
# THE END ------------------------------------------------------------------------------------------ #
# ================================================================================================== #
