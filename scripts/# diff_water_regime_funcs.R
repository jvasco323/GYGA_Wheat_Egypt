

#' Differenitate between water regime
#'
#' Given a set of sf polygon geometries extrcat the surface of irrigated 
#' and rainfed land for the crop of interest using SPAM rasters.
#' 
#' @param pol A sf object with POLYGON or MULTIPOLYGON geometries. This can correspond to 
#' buffer zones, climate zones or countries geometries.
#' @param spam_rasters A list of size two containing first a SPAM raster with irrigated harvested area and 
#' then a SPAM raster with rainfed areas. The list names must be `c("irrigated", "rainfed")`.
#' @param var_ha
#'

differentiate_water_regimes <- function(pols, spam_rasters, var_ha){
  
  water_regimes <- spam_rasters %>%
    map(~ raster::crop(x = .x, y = pols)) %>%
    map( ~ raster::mask(x = .x, mask = pols))
  
  for (i in seq_along(water_regimes)) {
    pols <- rgygaGIS::extract_area(polygons = pols,
                                   raster_mask =  water_regimes[[i]],
                                   area_name = names(water_regimes)[i])
  }
  
  var_ha <- as.symbol(var_ha)
  pols <- mutate(pols, 
                 per_irrigated = (irrigated / !!var_ha) * 100,
                 per_rainfed = (rainfed / !!var_ha) * 100)
  return(pols)
}