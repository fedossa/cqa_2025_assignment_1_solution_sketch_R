library(dplyr)
library(readr)
library(lubridate)

main <- function() {
  df <- readRDS("data/pulled/wrds_aa.rds")
  filtered_data <- filter_to_eu_countries_and_2021(df)
  saveRDS(filtered_data, "data/generated/filtered_data.rds")
}

filter_to_eu_countries_and_2021 <- function(df) {
  eu_countries <- c(
    "AUSTRIA", "BELGIUM", "BULGARIA", "CROATIA", "CYPRUS", "CZECH REPUBLIC", 
    "DENMARK", "ESTONIA", "FINLAND", "FRANCE", "GERMANY", "GREECE", "HUNGARY",
    "IRELAND", "ITALY", "LATVIA", "LITHUANIA", "LUXEMBOURG", "MALTA", "NETHERLANDS",
    "NORWAY", "POLAND", "PORTUGAL", "ROMANIA", "SLOVAKIA", "SLOVENIA", "SPAIN", 
    "SWEDEN"
  )
  
  df <- df %>%
    mutate(report_period_end_date = ymd(report_period_end_date)) %>%
    filter(
      year(report_period_end_date) == 2021,
      trans_report_auditor_country %in% eu_countries
    ) %>%
    select(
      auditor_fkey, trans_report_auditor_country, auditor_network, entity_map_key
    )
  
  return(df)
}

main()
