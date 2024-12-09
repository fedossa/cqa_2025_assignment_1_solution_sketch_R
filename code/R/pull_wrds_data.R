library(RPostgres)
library(DBI)
library(dplyr)


if (!exists("cfg")) source("code/R/read_config.R")

main <- function() {
    db <- connect_to_wrds()
    wrds_aa <- fetch_audit_data_from_wrds(db)
    saveRDS(wrds_aa, "data/pulled/wrds_aa.rds")
    disconnect_from_wrds(db)
}

connect_to_wrds <- function() {
  db <- dbConnect(
    Postgres(),
    host = 'wrds-pgdata.wharton.upenn.edu',
    port = 9737,
    user = cfg$wrds_user,
    password = cfg$wrds_pwd,
    sslmode = 'require',
    dbname = 'wrds'
  )
  
  message("Logged on to WRDS ...")
  
  return(db)
}

disconnect_from_wrds <- function(db) {
  dbDisconnect(db)
  message("Disconnected from WRDS")
}

fetch_audit_data_from_wrds <- function(db) {
  message("Pulling audit analytics data ... ", appendLF = FALSE)
  query <- "
    SELECT *
    FROM audit_europe.feed76_transparency_reports
    LEFT JOIN audit_europe.feed70_europe_company_block USING (entity_map_fkey)
    WHERE report_period_end_date BETWEEN '2019-12-31' AND '2023-10-31'
  "
  wrds_aa <- dbGetQuery(db, query)
  unique_columns <- !duplicated(names(wrds_aa))
  wrds_aa <- wrds_aa[, unique_columns]
  message("done!")

  return(wrds_aa)
}

main()
