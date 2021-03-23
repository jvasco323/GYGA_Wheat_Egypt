### ------------------------------------------------------------------------ ###
###           Match gadm polygons and actual yields governorate names        ###
### ------------------------------------------------------------------------ ###

library(sf)
library(tidyverse)

### Functions -------------------------------------------------------------- ###

to_Latin_ASCII <- function(string) {
  stringi::stri_trans_general(string, id = "Latin-ASCII")
}

#' Identify level of gadm polygon
#' @param gadm_country [sf object] gadm polygon geometries for a given country.
#' @return [integer] 0, 1 or 2 
determine_level_gadm <- function(gadm_country) {
  NAME_X <- grep("^NAME_\\d$", names(gadm_country), value = TRUE)
  level_gadm <- max(as.integer(stringr::str_extract(NAME_X, "\\d")))
  return(level_gadm)
}

#' Get all english spellings of a given gadm polygon regions
#' @param gadm_country A sf object holding geometries for a given gadm country.
get_all_english_spellings <- function(gadm_country) {
  level_gadm <- determine_level_gadm(gadm_country)
  subregion_name_cols <- paste0(c("NAME_", "VARNAME_"), level_gadm)
  target_cols <- gadm_country[, subregion_name_cols, drop = TRUE]
  target_cols <- lapply(target_cols, to_Latin_ASCII)
  combined_vector <- Reduce(function(x, y) paste(x, y, sep = "|"), target_cols)
  combined_list <- strsplit(combined_vector, "\\|")
  return(combined_list)
}

#' Perform fuzzy string 
fuzzy_string_match <- function(national_stats, gadm) {
  df_dist <- expand.grid(national_stats = national_stats, gadm = gadm)
  df_dist$dist <- stringdist::stringdist(df_dist$national_stats, df_dist$gadm, 
                                         method = "jw")
  l_df_dist <- split(df_dist, df_dist$gadm)
  df_dist_match <- purrr::map_dfr(l_df_dist, ~ .x[which.min(.x$dist), ])
  return(df_dist_match)
}

find_best_match <- function(dist_table_df) {
  dist_table_by_ns <- dplyr::group_by(dist_table_df, national_stats)
  best_matches <- dplyr::filter(dist_table_by_ns, dist == min(dist)) 
  best_matches <- dplyr::ungroup(best_matches)
  best_matches[c("national_stats", "gadm")] <- 
    lapply(best_matches[c("national_stats", "gadm")], as.character)
  return(best_matches)
}

match_subregion_names <- function(gadm_sf, gadm_id_subregion,
                                  gadm_entries_list, subregion_names) {
  
  gadm <- sf::st_drop_geometry(gadm_sf)
  gadm$dist_table <-
    purrr::map(gadm[[gadm_entries_list]], 
               function(gadm_entries) {
                 purrr::map_dfr(subregion_names, 
                                fuzzy_string_match, 
                                gadm_entries)  
               })
  dist_table_df <- 
    purrr::map2_dfr(gadm$dist_table, gadm[[gadm_id_subregion]], 
                    function(dist_table, id_subregion) {
                      dist_table[["id_subregion"]] <- id_subregion
                      return(dist_table)
                    })
  best_matches <- find_best_match(dist_table_df)
  return(best_matches)
}

### Main ------------------------------------------------------------------- ###

EGY <- readRDS("data/shape-country/gadm36_EGY_1_sf.rds")
ya <- read.csv("data/actual-yields/EGY_actual_yields.csv")
  
  
EGY$all_NAMEs <- get_all_english_spellings(EGY)

egy_governorates <- unique(ya$Governorates)
best_matches <- match_subregion_names(gadm_sf = EGY, 
                                      gadm_id_subregion = "GID_1", 
                                      gadm_entries_list = "all_NAMEs",
                                      subregion_names = egy_governorates)

best_matches[best_matches$dist > 0, ]

## Modify gadm names
# Noubaria is part of Beheira (Al Buhayrah) governorate 
# Qalyoubia pick one: -> Qaliyubia 
# Assuit ok -> Assiut   
# Matrouh ok -> Matruh  

ya$Governorates <- str_replace_all(ya$Governorates,
                                   c("Qalyoubia" = "Qaliyubia",
                                     "Assuit" = "Assiut",
                                     "Matruh" = "Matrouh",
                                     "Kafr-Elsheikh" = "Kafr-El-Sheikh",
                                     "New valley" = "New Valley",
                                     "Noubaria" = "Al Buhayrah"))

egy_governorates <- unique(ya$Governorates)
best_matches <- match_subregion_names(gadm_sf = EGY, 
                                      gadm_id_subregion = "GID_1", 
                                      gadm_entries_list = "all_NAMEs",
                                      subregion_names = egy_governorates)

zero_mismatch <- nrow(best_matches[best_matches$dist > 0, ]) == 0
stopifnot(zero_mismatch)

## Add ya governorate names to polygon
best_matches <- best_matches %>% 
  rename(subregion = "national_stats") %>% 
  select(subregion, id_subregion)
EGY_mod <- inner_join(EGY, 
                      best_matches, 
                      by = c("GID_1" = "id_subregion"))
saveRDS(EGY_mod,
        "data/actual-yields/reshaped/gadm36_EGY_1_sf_mod.rds")
