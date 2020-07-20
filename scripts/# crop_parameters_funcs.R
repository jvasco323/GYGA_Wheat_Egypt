#' Give index of the nearest value to x in the target vector
#'
#' @param x double of length one.
#' @param target one-dimensional, vector, matrix, data.frame or tibble.
#'
#' @details data.frame and tibbles are systematically deframed.
#'
#' @importFrom tibble deframe is_tibble

which_nearest <- function(x, target){
  
  if(is_tibble(x) || is.data.frame(x)){
    x <- deframe(x)
  }
  
  if(is_tibble(target) || is.data.frame(target)){
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
  
  if(is_tibble(target) || is.data.frame(target)){
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
  
  if(is_tibble(TSUM) || is.data.frame(TSUM)){
    TSUM <- deframe(TSUM)
  }
  
  if(length(TSUM) != length(unique(dtemp$crop_year))){
    stop("The number of elements in TSUM must be equal to the number of years in dtemp")
  }
  
  map2(.x = TSUM,
       .y = split(dtemp, dtemp$crop_year),
       ~ dd_to_csd_atom(TSUM = .x , dtemp = .y)) %>%
    reduce(rbind)
  
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
  
  if(is_tibble(csd) || is.data.frame(csd)){
    csd <- deframe(csd)
  }
  
  if(length(csd) != length(unique(dtemp$crop_year))){
    stop("The number of elements in csd must be equal to the number of years in dtemp")
  }
  
  map2_dbl(.x = csd,
           .y = split(dtemp, dtemp$crop_year),
           ~ csd_to_dd_atom(csd = .x , dtemp = .y))
  
}


compute_dd <- function(dtemp_year) {
  
  dtemp_year$TSUM <- vector("numeric", nrow(dtemp_year))
  for (i in 1:length(dtemp_year$csd)) {
    
    ### Before emergence
    if(dtemp_year$TSUM[i] < TSUMEM) {
      
      avg_temp <- (dtemp_year$TMAX[i] + dtemp_year$TMIN[i]) / 2
      
      # Correct for max efficient temperature for emergence
      if(avg_temp >= TEFFMX) {
        avg_temp <- TEFFMX
      }
      
      ## Degree days
      dtemp_year$dd[i] <- avg_temp - TBASEM
      
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
      if(avg_temp >= Tmax) {
        avg_temp <- Tmax
      }
      
      ## Degree days
      dtemp_year$dd[i] <- avg_temp - TBASE
      ## Temperature sum
      dtemp_year$TSUM[i] <- dtemp_year$TSUM[i-1] + dtemp_year$dd[i]
    }
  }
  return(dtemp_year)
}
