### ------------------------------------------------------------------------ ###
###                 Extract national statistics from raw files               ###
### ------------------------------------------------------------------------ ###

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(stringdist)
  library(sf)
})

### Functions -------------------------------------------------------------- ###

#' Reads raw ya file for Egypt for a given year
#' @param path [character] raw file path.
#' @return A list of tables, each element of the list correspond to one sheet
#' of the raw file.
read_raw_file <- function(path){ 
  map(excel_sheets(path),
      function(sheet) {
        read_xlsx(path, sheet, 
                  col_types = "text", .name_repair = "minimal")
      })
}

#' Given a list of tibbles turns all NA into "NA"
#' this later ease the comparison between 2 sheets.
uniformize_NA <- function(ld) {
  map(ld, function(df) modify(df, str_replace_na))
}

is_of_length_2 <- function(x) length(x) == 2

#' Given a list of list containing all the data for Egypt,
#' compares sheets from the same year.
compare_sheets_by_year <- function(lld) {
  lld <- map(lld, uniformize_NA)
  map_if(lld, is_of_length_2, 
         function(ld) reduce(ld, waldo::compare),
         .else = function(ld) return("Single sheet, nothing to compare"))
}

pivot_raw_data <- function(raw_data) {
  pattern <- "^(.+) (Old Land|New Land|Tota) (.+)$"
  pivot_longer(data = raw_data, 
               cols = -Governorates,
               names_to = c("variety", "land_type", "variable"),
               names_pattern = pattern)
}

#' Convert "NA" to NA 
stringNA_to_NA <- function(x) {
  x[x == "NA"] <- NA
  return(x)
}



### Main ------------------------------------------------------------------- ###

path_raw_files <- list.files("data/actual-yields/raw/",
                             pattern = "\\.xlsx$",
                             full.names = TRUE)
crop_year <- str_extract(path_raw_files, "(?<=\\(\\d{4}-)\\d{4}(?=\\))")

lld <- map(path_raw_files, read_raw_file) %>% set_names(crop_year)


## Every file except from 2012-2013 contains two sheets that seem highly similar
diff_sheets <- compare_sheets_by_year(lld)
## Only minor differences:
# 2011: One additional column 'Gov total' that seems to be the 
# sum over all varieties and land type 
# 2018: First sheet contains zeros instead of NAs

# Keep only first sheets for all years except 2018
l_raw_data <- map(lld[grep("[^2018]", names(lld))], 1)
# For 2018 keep second sheet to have to convert 0 back to NA
l_raw_data[["2018"]] <- lld[["2018"]][[2]]
l_raw_data <- l_raw_data[order(names(l_raw_data))]

# head(lld[[1]][[1]])[1:5 , 1:5]
# Data sets are organized the same way across years:
# A first column 'Governorates' and a myriad of column following this pattern:
# Variety Name Land type Variable (Unit).


# Pivot data -> extract variables {"variety", "land_type", "variable"}
# from header
long_data <- map_dfr(l_raw_data, pivot_raw_data, .id = "year")

# Convert "NA" to NA and turn value to numeric
long_data <- long_data %>% 
  mutate(value = as.numeric(stringNA_to_NA(value)))

# High percentage of missing value
long_data %>% 
  summarize(per_NA = sum(is.na(value))/length(value))

# Make variable name uniform (correct typos) and syntactic
patterns <- c("yon" = "ton", "Ton" = "ton")
long_data$variable <- long_data$variable %>% 
  str_replace_all(patterns) %>% 
  str_remove_all("\\(|\\)|\\.|/") %>% 
  str_replace("^Area ton$", "Area ha") %>% 
  str_replace(" ", "_")


# Get rid of data expressed in local unit
# Aside of them not being relevant, keeping them will prevent pivoting
# the table
long_data_international_units <- long_data %>% 
  filter(str_detect(variable, "Fed|ArdFed|Ardab", negate = TRUE)) 

data_iu <- long_data_international_units %>% 
  pivot_wider(names_from = "variable",
              values_from = "value")

## Save
write_csv(data_iu, "data/actual-yields/extracted/EGY_actual_yields.csv")


