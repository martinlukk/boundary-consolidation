

## Program:   13-descriptive_stats.R
## Task:      Generate faceted bar plot of support for membership criteria
##
## Input:     01-issp_swiid.Rds
## Output:    fig2.jpg
##
## Project:   boundary-consolidation
## Author:    Martin Lukk / 2024-01-15 (last updated)


# 0. Program Setup --------------------------------------------------------
library(tidyverse)
library(haven)
library(here)
library(survey)
library(srvyr)
library(hrbrthemes)


# 1. Load Data ------------------------------------------------------------
issp_swiid <- read_rds(here("data", "output", "01-issp_swiid.Rds")) %>% .[[1]]


# 2. Summarize Data -------------------------------------------------------
fig2_df <-
  issp_swiid %>%
  relocate(c(impbornP, impliveP, impreligP, impcitP, impfeelP, implangP), .before = imprespP) %>%
  as_survey_design() %>%
  group_by(country_fct) %>%
  # Compute unweighted avg response and errors for each "close to" variable
  summarise(across(starts_with("imp"), ~ survey_mean(.x, na.rm = T))) %>%
  rename_with(~ str_c(., "_mean"), .cols = !contains("_")) %>%
  pivot_longer(cols = !country_fct,
               names_to = c("impvar", "stat"),
               names_sep = "_") %>%
  pivot_wider(names_from = stat,
              values_from = value) %>%
  mutate(impvar = str_remove(impvar, "imp"),
         impvar = str_remove(impvar, "P"),
         impvar = as.factor(impvar)) %>%
  group_by(country_fct) %>%
  mutate(overall_mean = mean(mean)) %>%
  ungroup() %>%
  mutate(
    impvar = fct_recode(
      impvar,
      "Respect" = "resp",
      "Language" = "lang",
      "Feeling" = "feel",
      "Citizenship" = "cit",
      "Religion" = "relig",
      "Residence" = "live",
      "Birth" = "born"
    ),
    impvar = fct_relevel(impvar,
                         "Respect", "Language", "Feeling",
                         "Citizenship", "Religion", "Residence", "Birth"),
    country_fct = fct_recode(
      country_fct,
      "S. Korea"    = "SKorea",
      "Czechia"     = "CzechRep",
      "N. Zealand" = "NewZealand"
    )
  )


# 3. Plot Figure ----------------------------------------------------------
fig2 <-
  fig2_df %>%
  ggplot(aes(x = impvar, y = mean)) +
  geom_bar(aes(fill = impvar, color = impvar),
           stat = "identity",
           alpha = .8) +
  facet_wrap(~ fct_reorder(country_fct,+(overall_mean))) +
  scale_x_discrete(breaks = NULL) +
  coord_cartesian(ylim = c(1, 4)) +
  labs(x = "",
       y = "",
       fill = "Importance of:",
       color = "Importance of:",
       caption = "Note: Data from International Social Survey Program National Identity module waves 1-3. Bar heights indicate unweighted mean levels \nof importance reported for seven criteria for legitimate national membership per country, averaged across available waves. Countries are \nordered by their overall mean across all criteria. Criteria are presented in order of those most closely associated with civic nationalism (i.e., \nrespect) to most closely associated with ethnic nationalism (i.e., birth), based on strength of estimated factor loadings (see Appendix B).") +
  hrbrthemes::theme_ipsum() +
  scale_fill_brewer(palette = "Set2") +
  scale_color_brewer(palette = "Set2") +
  theme(legend.position = "bottom",
        plot.caption = element_text(size = 12, hjust = 0)) +
  guides(fill = guide_legend(nrow = 1, byrow = TRUE),
         color = guide_legend(nrow = 1, byrow = TRUE))

ggsave(here("figures", "fig2.jpg"), plot = fig2,
       device = "jpg",
       width = 9.25, height = 9.25, dpi = 300)
