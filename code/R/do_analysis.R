source("code/R/theme_trr.R")

library(dplyr)
library(ggplot2)
library(readr)
library(tidyr)
library(lubridate)


main <- function() {
  df <- readRDS("data/generated/filtered_data.rds")
  results <- describe_data(df)
  country_data <- compute_country_level_audit_data(df)
  market_share_data <- calculate_market_shares(country_data)
  summary_stats <- aggregate_country_metrics(market_share_data)
  final_results <- compute_eu_averages(summary_stats)
  results$replicated_figure <- plot_market_share_by_audit_network(final_results)
  save(results, file = "output/results.rda")
}

describe_data <- function(df) {
  number_of_pies <- length(unique(na.omit(df$entity_map_key)))
  number_of_pie_statutory_audits <- sum(!is.na(df$entity_map_key))
  
  return(list(
    number_of_pies = number_of_pies,
    number_of_pie_statutory_audits = number_of_pie_statutory_audits
  ))
}


compute_country_level_audit_data <- function(df) {
  df <- df %>%
    mutate(
      auditor_network = if_else(is.na(auditor_network), "", auditor_network)
    ) %>%
    group_by(trans_report_auditor_country, auditor_fkey, auditor_network) %>%
    summarize(
      obs = sum(!is.na(entity_map_key)),
      .groups = "drop"
    )
  
  return(df)
}

calculate_market_shares <- function(df) {
  big4_networks <- c(
    "|PricewaterhouseCoopers International|",
    "|Ernst & Young Global|",
    "|Deloitte & Touche International|",
    "|KPMG International|"
  )
  kap10_networks <- c(
    big4_networks,
    "|Baker Tilly International|MHA|",
    "|Baker Tilly International|",
    "|BDO International|",
    "|Grant Thornton International|",
    "|Mazars Worldwide|Praxity Global Alliance|",
    "|Mazars Worldwide|",
    "|Nexia International|",
    "|RSM Global (International)|"
  )
  
  df <- df %>%
    group_by(trans_report_auditor_country) %>%
    mutate(
      obs_all = sum(obs)
    ) %>%
    ungroup() %>%
    mutate(
      mshare = obs / obs_all,
      big4 = as.integer(auditor_network %in% big4_networks),
      kap10 = as.integer(big4),
      kap10 = if_else(auditor_network %in% kap10_networks, 1, kap10)
    ) %>%
    group_by(trans_report_auditor_country) %>%
    mutate(
      cr4 = rank(-mshare, ties.method = "first"),
      cr4 = as.integer(cr4 <= 4)
    ) %>%
    ungroup()
  
  return(df)
}

aggregate_country_metrics <- function(df) {
  big4 <- df %>%
    filter(big4 == 1) %>%
    group_by(trans_report_auditor_country) %>%
    summarize(mshare_big4 = sum(mshare), .groups = "drop")
  
  cr4 <- df %>%
    filter(cr4 == 1) %>%
    group_by(trans_report_auditor_country) %>%
    summarize(mshare_cr4 = sum(mshare), .groups = "drop")
  
  kap10 <- df %>%
    filter(kap10 == 1) %>%
    group_by(trans_report_auditor_country) %>%
    summarize(mshare_kap10 = sum(mshare), .groups = "drop")
  
  merged <- big4 %>%
    left_join(cr4, by = "trans_report_auditor_country") %>%
    left_join(kap10, by = "trans_report_auditor_country")
  
  return(merged)
}

compute_eu_averages <- function(df) {
  eu_averages <- tibble(
    trans_report_auditor_country = "EU AVERAGE",
    mshare_big4 = mean(df$mshare_big4, na.rm = TRUE),
    mshare_cr4 = mean(df$mshare_cr4, na.rm = TRUE),
    mshare_kap10 = mean(df$mshare_kap10, na.rm = TRUE)
  )
  
  final_df <- bind_rows(df, eu_averages) %>%
    distinct() %>%
    arrange(desc(mshare_big4))
  
  return(final_df)
}

plot_market_share_by_audit_network <- function(df) {
  df <- df %>%
    arrange(desc(mshare_big4)) %>%
    mutate(trans_report_auditor_country = factor(
      trans_report_auditor_country, levels = unique(trans_report_auditor_country)
    ))
  
  df_long <- df %>%
    pivot_longer(
      cols = c(mshare_big4, mshare_cr4, mshare_kap10),
      names_to = "metric",
      values_to = "value"
    )
  
  df_long <- df_long %>%
    mutate(
      bar_color = case_when(
        trans_report_auditor_country == "EU AVERAGE" & metric == "mshare_big4" ~ "#7f4365",
        trans_report_auditor_country == "EU AVERAGE" & metric == "mshare_cr4" ~ "#835881",
        trans_report_auditor_country == "EU AVERAGE" & metric == "mshare_kap10" ~ "#c5798c",
        metric == "mshare_big4" ~ "#576E94",
        metric == "mshare_cr4" ~ "#7FA4D7",
        metric == "mshare_kap10" ~ "#B0B8D1"
      )
    )
  
  p <- ggplot(df_long, aes(
    x = trans_report_auditor_country,
    y = value * 100,
    fill = bar_color
  )) +
    geom_bar(
      stat = "identity",
      position = position_dodge(width = 0.8),
      size = 0.2
    ) +
    scale_y_continuous(
      breaks = seq(0, 100, by = 10),
      labels = function(x) paste0(x, "%"),
      expand = c(0, 0)
    ) +
    scale_fill_identity(
      name = "Type",
      breaks = c("#576E94", "#7FA4D7", "#B0B8D1"),
      labels = c("Big 4", "CR4", "Top 10 (KAP10)"),
      guide = "legend"
    ) +
    labs(
      x = NULL,
      y = NULL
    ) +
    theme_trr("bar", text_size = 8) +
    theme(
      axis.line = element_blank(),
      axis.text.x = element_text(angle = 90, hjust = 1),
      legend.position = "bottom",
      panel.grid.minor = element_blank(),
      panel.grid.major.y = element_line(color = "grey", linetype = "dashed", size = 0.1)
    )
  
  return(p)
}

main()
