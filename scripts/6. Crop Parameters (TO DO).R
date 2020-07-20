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
# Rename year crop_year, year corresponds here to the cropping season
# i.e. year were harvest took place
names(sowing_date)[grep("year", names(sowing_date))] <- "crop_year"
sowing_date$year <- as.numeric(str_extract(sowing_date$sowing, "\\d{4}$"))

# Read crop data
TSUMEM <- 120
TBASEM <- 0
TEFFMX <- 30

TBASE <- 0
Tmax <- 30
# DTSMTB:
#     - [ 0.0,  0.0,
#         30.0, 30.0,
#         45.0, 30.0]
#     - daily increase in temperature sum as function of daily average temperature


# ================================================================================================== #
# Weather station 1 -------------------------------------------------------------------------------- #
# ================================================================================================== #

# Nile Delta
weather_nile_delta <- read_excel("./data/wofost-inputs/weather_nasa_NileDelta.xlsx", 
                                 sheet = "Sheet1")
day <- as.Date(weather_nile_delta$DAY)
days <- data.frame(DAY = weather_nile_delta$DAY, 
                   Year = as.numeric(format(day, format = "%Y")), 
                   Month = as.numeric(format(day, format = "%m")), 
                   Day = as.numeric(format(day, format = "%d")))
weather_nile_delta <- merge(weather_nile_delta, days, by = 'DAY')

# Duration provided by agronomists
intD1 <- c(80, 105)
intD2 <- c(45, 70)
D1 <- ceiling(mean(intD1))
D2 <- ceiling(mean(intD2))

# Select only time and temperature variables in weather data
dtemp <- weather_nile_delta %>% 
  filter(Year %in% sowing_date$year) %>% # DO NOT FORGET TO UNCOMMENT
  select(Year, Month, Day, TMIN, TMAX)

# Count number of missing days per year
years <- unique(dtemp$Year)
nb_data <- dtemp %>%
  split(.$Year) %>%
  map_dbl(nrow)
nb_real <- ifelse(lubridate::leap_year(years), 366, 365)
missing_dtemp <- tibble(years, nb_data, nb_real) %>%
  mutate(nb_missing = nb_real - nb_data) %>%
  as.data.frame()

# Add a column with date in Julian days
dtemp <- dtemp %>% 
  mutate(juld = paste(Year, Month, Day, sep = "-") %>% 
           as_date() %>% 
           yday())

dtemp[] <- lapply(dtemp, as.numeric)
tail(dtemp)


#  The sowing date correspond to the first Cropping Season Day (csd)
sowing_date$csd <- 1

# Include cropping season information in weather data.frame: crop_year and csd

# foo <- inner_join(dtemp, 
#                   select(sowing_date, year, crop_year),
#                   by = c("Year" = "year"))
# 
# tail(foo)

# This must be done one a per year basis

# temp names
a <- split(dtemp, dtemp$Year)
b <- split(sowing_date, sowing_date$year)

l_dtemp <- map2(
  a,
  b,
  ~ full_join(.x, 
              select(.y, doy, csd, crop_year), by =  c("juld" = "doy"))
  )
dtemp <- reduce(l_dtemp, rbind)

# So far all csd are NA but the sowing data
# Convert those NA to zeros
dtemp$csd[is.na(dtemp$csd)] <- 0


tail(dtemp)
# Increment missing csd and crop_year 

ref_year <- min(dtemp$crop_year, na.rm = TRUE) - 1
dtemp$crop_year[1] <- ref_year
for (i in 2:nrow(dtemp)) {
  
  if(dtemp$csd[i-1] != 0 & dtemp$csd[i] != 1) {
    dtemp$csd[i] <- dtemp$csd[i-1] + 1
  }
  
  if(grepl("^\\d{4}$", dtemp$crop_year[i])) {
    ref_year <- dtemp$crop_year[i]
  } 
  dtemp$crop_year[i] <- ref_year
}


dtemp[310:330, ]
sowing_date

# Degree days calculation
# Exclude problematic years for the moment
dtemp <- dtemp[!(dtemp$crop_year %in% c(2008, 2018, 2019)), ]
sowing_date <- sowing_date[!(sowing_date$crop_year %in% c(2018, 2019)), ]

dtemp %>%
  filter(crop_year %in% sowing_date$crop_year) %>%
  split(.$crop_year)%>%
  map(dim)



dtemp <- dtemp %>%
  split(.$crop_year) %>%
  map(compute_dd) %>%
  reduce(rbind)
  

# Process weather data and tsums
TSUM_sowing <- csd_to_dd(sowing_date$csd, dtemp)
TSUM_sowing

date_emergence <- dd_to_csd(rep(TSUMEM, length(unique(dtemp$crop_year))), dtemp)

date_anthesis <- date_emergence + D1 
TSUM_anthesis <- csd_to_dd(date_anthesis, dtemp)

date_maturity <- date_anthesis + D2
TSUM_maturity <- csd_to_dd(date_maturity, dtemp)

# Calculate TSUM1 and TSUM2
TSUM <- tibble(TSUM1 = TSUM_anthesis - TSUMEM, 
               TSUM2 = TSUM_maturity - TSUM_anthesis)
tidy_TSUM <- tidyr::pivot_longer(data = TSUM, 
                                 cols = c("TSUM1", "TSUM2"),
                                 names_to = "Parameter", values_to = "TSUM")
mean_TSUMs <- map(TSUM, ~ round(mean(.x), digits = 0))

# Plot temperature sums
hist_TSUM <- ggplot(tidy_TSUM)+
    aes(x = TSUM, fill = Parameter)+
    geom_histogram(binwidth = 10, colour = "black")+
    xlab(expr(tidy_TSUM ~ degree*C.day^{-1})) +
    theme_bw()
TSUM_mean <- tidy_TSUM %>% 
  group_by(Parameter) %>% 
  summarise(value = round(mean(TSUM), digits = 0), .groups = "drop")
hist_TSUM + geom_vline(xintercept = TSUM_mean$value, linetype = "dashed", size = 1)

# Save plot to pdf

# (....)

# ================================================================================================== #
# Weather station 2 -------------------------------------------------------------------------------- #
# ================================================================================================== #

# Upper Egypt
weather_upper_egypt <- read_excel("./data/wofost-inputs/weather_nasa_UpperEgypt.xlsx", sheet = "Sheet1")
day <- as.Date(weather_upper_egypt$DAY)
days <- data.frame(DAY = weather_upper_egypt$DAY, 
                   Year = as.numeric(format(day, format = "%Y")), 
                   Month = as.numeric(format(day, format = "%m")), 
                   Day = as.numeric(format(day, format = "%d")))
weather_upper_egypt <- merge(weather_upper_egypt, days, by='DAY')

# Duration provided by agronomists
intD1 <- c(75, 100)
intD2 <- c(40, 65)
D1 <- ceiling(mean(intD1))
D2 <- ceiling(mean(intD2))





# ================================================================================================== #
# THE END ------------------------------------------------------------------------------------------ #
# ================================================================================================== #
