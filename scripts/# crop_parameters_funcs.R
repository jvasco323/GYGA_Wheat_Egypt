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
#' @param dtemp tibble or data.frame containing both Julian days (column "juld") and temperature sum (column "TSUM").
#'
#' @importFrom tibble is_tibble
#' @importFrom purrr map2 reduce

dd_to_juld <- function(TSUM, dtemp){
  
  dd_to_juld_atom <- function(TSUM, dtemp) {
    
    dtemp[which_nearest(TSUM, dtemp[,"TSUM"]), "juld"]
  }
  
  if(is_tibble(TSUM) || is.data.frame(TSUM)){
    TSUM <- deframe(TSUM)
  }
  
  if(length(TSUM) != length(unique(dtemp$Year))){
    stop("The number of elements in TSUM must be equal to the number of years in dtemp")
  }
  
  map2(.x = TSUM,
       .y = split(dtemp, dtemp$Year),
       ~ dd_to_juld_atom(TSUM = .x , dtemp = .y)) %>%
    reduce(rbind)
  
}

#' Extract TSUM corresponding to julian days, given a conversion table.
#'
#' @param juld tibble, data.frame or numeric vector containing the julian days to convert in TSUM.
#' @param dtemp tibble or data.frame containing both Julian days (column "juld") and temperature sum (column "TSUM").
#'
#' @importFrom tibble is_tibble
#' @importFrom purrr map2 reduce


juld_to_dd <- function(juld, dtemp){
  
  juld_to_dd_atom <- function(juld, dtemp) {
    
    dtemp[which_nearest(juld, dtemp[,"juld"]), "TSUM"]
  }
  
  if(is_tibble(juld) || is.data.frame(juld)){
    juld <- deframe(juld)
  }
  
  if(length(juld) != length(unique(dtemp$Year))){
    stop("The number of elements in juld must be equal to the number of years in dtemp")
  }
  
  map2(.x = juld,
       .y = split(dtemp, dtemp$Year),
       ~ juld_to_dd_atom(juld = .x , dtemp = .y)) %>%
    reduce(rbind)
  
}