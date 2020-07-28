#' Give index of the nearest value to x in the target vector
#'
#' @param x double of length one.
#' @param target one-dimensional, vector, matrix, data.frame or tibble.
#'
#' @details data.frame and tibbles are systematically deframed.
#'
#' @importFrom tibble deframe is_tibble

which_nearest <- function(x, target){
  
  if(tibble::is_tibble(x) || is.data.frame(x)){
    x <- deframe(x)
  }
  
  if(tibble::is_tibble(target) || is.data.frame(target)){
    target <- deframe(target)
  }
  
  itest <- which(target == x)
  
  if(length(itest) != 0){
    return(itest)
  }
  
  bl <- max(which(target < x))
  bu <- min(which(target > x))
  
  test <- which.min(c(abs(target[bl] - x), abs(target[bu] - x)))
  
  if(test == 1){
    
    return(bl)
    
  } else if(test == 2) {
    
    return(bu)
    
  } else {
    stop("Something went wrong when finding minimum distance between x and the closest target values")
  }
  
}

#' Return nearest value to x in the target vector
#'
#' @param x double of length one.
#' @param target one-dimensional, vector, matrix, data.frame or tibble
#'
#' @importFrom tibble is_tibble

extract_nearest <- function(x, target){
  
  if(tibble::is_tibble(target) || is.data.frame(target)){
    target[which_nearest(x, target), ]
  } else {
    target[which_nearest(x, target)]
  }
  
}

#' Extract julian days corresponding to TSUM, given a conversion table.
#'
#' @param TSUM tibble, data.frame or numeric vector containing the TSUM to convert in julian days.
#' @param dtemp tibble or data.frame containing both Julian days (column "csd") and temperature sum (column "TSUM").
#'
#' @importFrom tibble is_tibble
#' @importFrom purrr map2 reduce

dd_to_csd <- function(TSUM, dtemp){
  
  dd_to_csd_atom <- function(TSUM, dtemp) {
    
    dtemp[which_nearest(TSUM, dtemp[,"TSUM"]), "csd"]
  }
  
  if(tibble::is_tibble(TSUM) || is.data.frame(TSUM)){
    TSUM <- deframe(TSUM)
  }
  
  if(length(TSUM) != length(unique(dtemp$crop_year))){
    stop("The number of elements in TSUM must be equal to the number of years in dtemp")
  }
  
  purrr::map2_dbl(.x = TSUM,
                  .y = split(dtemp, dtemp$crop_year),
                  ~ dd_to_csd_atom(TSUM = .x , dtemp = .y))
  
}

#' Extract TSUM corresponding to julian days, given a conversion table.
#'
#' @param csd tibble, data.frame or numeric vector containing the julian days to convert in TSUM.
#' @param dtemp tibble or data.frame containing both Julian days (column "csd") and temperature sum (column "TSUM").
#'
#' @importFrom tibble is_tibble
#' @importFrom purrr map2 reduce


csd_to_dd <- function(csd, dtemp){
  
  csd_to_dd_atom <- function(csd, dtemp) {
    
    dtemp[which_nearest(csd, dtemp[,"csd"]), "TSUM"]
  }
  
  if(tibble::is_tibble(csd) || is.data.frame(csd)){
    csd <- deframe(csd)
  }
  
  if(length(csd) != length(unique(dtemp$crop_year))){
    stop("The number of elements in csd must be equal to the number of years in dtemp")
  }
  
  purrr::map2_dbl(.x = csd,
                  .y = split(dtemp, dtemp$crop_year),
                  ~ csd_to_dd_atom(csd = .x , dtemp = .y))
  
}


compute_dd <- function(dtemp_year, WOFOST_params) {
  
  dtemp_year$TSUM <- vector("numeric", nrow(dtemp_year))
  for (i in 1:length(dtemp_year$csd)) {
    
    ### Before emergence
    if(dtemp_year$TSUM[i] < WOFOST_params$TSUMEM) {
      
      avg_temp <- (dtemp_year$TMAX[i] + dtemp_year$TMIN[i]) / 2
      
      # Correct for max efficient temperature for emergence
      if(avg_temp >= WOFOST_params$TEFFMX) {
        avg_temp <- WOFOST_params$TEFFMX
      }
      
      ## Degree days
      dtemp_year$dd[i] <- avg_temp - WOFOST_params$TBASEM
      
      ## Temperature sum
      # Handle initial condition
      if(length(dtemp_year$TSUM[i-1]) == 0) { # First day
        dtemp_year$TSUM[i] <- dtemp_year$dd[i]
      } else { # Rest of the days
        dtemp_year$TSUM[i] <- dtemp_year$TSUM[i-1] + dtemp_year$dd[i]
      }
      
      ### After emergence
    } else {
      
      avg_temp <- (dtemp_year$TMAX[i] + dtemp_year$TMIN[i]) / 2
      
      # Correct for max efficient temperature for development
      # Tmax is derived from DTSMTB (last value)
      if(avg_temp >= WOFOST_params$Tmax) {
        avg_temp <- WOFOST_params$Tmax
      }
      
      ## Degree days
      dtemp_year$dd[i] <- avg_temp - WOFOST_params$TBASE
      ## Temperature sum
      dtemp_year$TSUM[i] <- dtemp_year$TSUM[i-1] + dtemp_year$dd[i]
    }
  }
  return(dtemp_year)
}

process_weather_data <- function(weather_data_raw){
  
  day <- as.Date(weather_data_raw$DAY)
  days <- data.frame(DAY = weather_data_raw$DAY, 
                     Year = as.numeric(format(day, format = "%Y")), 
                     Month = as.numeric(format(day, format = "%m")), 
                     Day = as.numeric(format(day, format = "%d")))
  weather_data <- merge(weather_data_raw, days, by = 'DAY')
  
  return(weather_data)
}

#' Compute TSUM1 and TSUM2 for WOFOST
#' 
#' This function does the calculation for multiple years but only one weather 
#' station at a time. 
#' 
#' @param weather_data A data.frame with the following columns: Year, Month, Day,
#' TMIN, TMAX.
#' @param sowing_date A data.frame with the following columns: crop_year, year, doy, csd.
#' @param WOFOST_params A named list of the following WOFOST parameters: TSUMEM, 
#' TBASEM, TEFFMX, TBASE, Tmax. Tmax is derived from DTSMTB and corresponds to the 
#' daily average temperature above which there is no crop growth.
#' @param intD1 A numeric vector of size 2 giving the lower and upper bound of the 
#' number of days between emergence and anthesis as provided by the country agronomist.
#' @param intd2 A numeric vector of size 2 giving the lower and upper bound of the 
#' number of days between anthesis and maturity as provided by the country agronomist.
#' 
#' @return A data.frame with 3 columns: TSUM1, TSUM2 and crop_year
#'
#' @importFrom lubridate as_date yday
#' @importFrom dplyr full_join

compute_TSUM <- function(weather_data, sowing_date, WOFOST_params, intD1, intD2) {
  
  # Make sure years are ordered properly 
  stopifnot(all(sowing_date$year == sort(sowing_date$year)))
  stopifnot(all(weather_data$Year == sort(weather_data$Year)))
  
  ## Take mean of duration provided by agronomists
  # Number of days between emergence and anthesis
  D1 <- ceiling(mean(intD1))
  # Number of days between anthesis and harvest
  D2 <- ceiling(mean(intD2))
  
  # Select only time and temperature variables in weather data
  dtemp <- weather_data[weather_data$Year %in% sowing_date$year,
                        c("Year", "Month", "Day", "TMIN", "TMAX")]
  
  # Add a column with date in Julian days
  dtemp$juld <- paste(dtemp$Year, dtemp$Month, dtemp$Day, sep = "-")
  dtemp$juld <- lubridate::yday(lubridate::as_date(dtemp$juld))
  
  # Make sure all weather variables are numeric
  dtemp[] <- lapply(dtemp, as.numeric)
  
  #  The sowing date correspond to the first Cropping Season Day (csd)
  sowing_date$csd <- 1
  
  # Include cropping season information in weather data.frame: crop_year and csd
  # This must be done one a per year basis
  include_cs_info <- function(.x, .y){
    dplyr::full_join(.x, 
                     .y[ , c("doy", "csd", "crop_year")], 
                     by =  c("juld" = "doy"))
  }
  l_dtemp <-  mapply(include_cs_info, 
                     split(dtemp, dtemp$Year),
                     split(sowing_date, sowing_date$year),
                     SIMPLIFY = FALSE)
  dtemp <- Reduce(rbind, l_dtemp)
  
  
  # So far all csd are NA but the sowing data
  # Convert those NA to zeros
  dtemp$csd[is.na(dtemp$csd)] <- 0
  
  # Increment missing csd and crop_year 
  ref_year <- min(dtemp$crop_year, na.rm = TRUE) - 1
  dtemp$crop_year[1] <- ref_year
  for (i in 2:nrow(dtemp)) {
    # Cropping season day
    if(dtemp$csd[i-1] != 0 & dtemp$csd[i] != 1) {
      dtemp$csd[i] <- dtemp$csd[i-1] + 1
    }
    # Cropping year
    if(grepl("^\\d{4}$", dtemp$crop_year[i])) {
      ref_year <- dtemp$crop_year[i]
    } 
    dtemp$crop_year[i] <- ref_year
  }
  
  # Keep only crop years of interest, i.e discard crop year fragment
  # at the very beginning of the period of interest
  valid_years <- intersect(sowing_date$crop_year, dtemp$Year)
  sowing_date <- sowing_date[sowing_date$crop_year %in% valid_years, ]
  dtemp <- dtemp[dtemp$crop_year %in% valid_years, ]
  
  # Degree days calculation
  l_dtemp <- lapply(split(dtemp, dtemp$crop_year), compute_dd, WOFOST_params)
  dtemp <- Reduce(rbind, l_dtemp)
  
  # Process weather data and TSUMs
  TSUM_sowing <- csd_to_dd(sowing_date$csd, dtemp)
  
  TSUM_emergence <- rep(WOFOST_params$TSUMEM, length(unique(dtemp$crop_year)))
  date_emergence <- dd_to_csd(TSUM_emergence, dtemp)
  
  date_anthesis <- date_emergence + D1 
  TSUM_anthesis <- csd_to_dd(date_anthesis, dtemp)
  
  date_maturity <- date_anthesis + D2
  TSUM_maturity <- csd_to_dd(date_maturity, dtemp)
  
  # Calculate TSUM1 and TSUM2
  TSUM <- data.frame(TSUM1 = TSUM_anthesis - WOFOST_params$TSUMEM, 
                     TSUM2 = TSUM_maturity - TSUM_anthesis, 
                     crop_year = valid_years)
  return(TSUM)
}
