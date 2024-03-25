

## Program:   14-descriptives-bivariate.R
## Task:      Compute country and country-year level summary data,
##            generate scatter plots of relationship between inequality and
##            ethno-nationalism.
##
## Input:     01-issp_swiid.Rds
## Output:    fig3.jpg
##
## Project:   boundary-consolidation
## Author:    Martin Lukk / 2024-01-15 (last updated)


# 0. Program Setup --------------------------------------------------------
library(tidyverse)
library(here)
library(haven)
library(countrycode)
library(slider)
library(ggrepel)


# 1. Load Data ------------------------------------------------------------
issp <-
  read_rds(here("data", "output", "01-issp_swiid.Rds")) %>%
  map(zap_labels)

issp <- issp[[1]]

load(here("data", "input", "swiid9_1.rda")); rm(swiid) # Non multiple imputation version for plotting


# 2. Prepare Data ---------------------------------------------------------
issp_mean <-
  issp %>%
  select(country_year, country, year, wave, diff_s) %>%
  filter(!is.na(diff_s)) %>%
  group_by(country_year) %>%
  summarize(diff_mean = mean(diff_s),
            diff_se   = sd(diff_s)/sqrt(length(diff_s)),
            country   = mean(country),
            year      = mean(year),
            wave      = mean(wave))

swiid <- swiid_summary %>%
  # Convert country names to codes
  mutate(country = countrycode(
    country,
    origin = "country.name",
    destination = "iso3n",
    warn = F
  )) %>%
  select(country, year, starts_with("gini_disp")) %>%
  # Drop countries without ISO3N codes
  filter(!is.na(country)) %>%
  # Compute moving averages
  arrange(country, year) %>%
  group_by(country) %>%
  filter(n() >= 5) %>%
  mutate(gini_disp_4yr =
           slide_index_mean(gini_disp, i = year, before = 3),
         gini_disp_4yr_se =
           slide_index_mean(gini_disp_se, i = year, before = 3)) %>%
  ungroup()


# 3. Merge Data -----------------------------------------------------------
issp_swiid_cyr <-
  swiid %>%
  left_join(issp_mean, by = c("country", "year")) %>%
  # Drop SWIID country-years without corresponding survey data
  filter(!is.na(country_year)) %>%
  relocate(country_year) %>%
  relocate(wave, .after = year) %>%
  mutate(country = as.factor(country),
         country_lab = as.factor(str_remove(country_year, "_[0-9]+")),
         country_lab = fct_recode(country_lab,
                                  "Czechia" = "CzechRep",
                                  "New Zealand" = "NewZealand",
                                  "S. Korea" = "SKorea"),
         wave = as.factor(wave),
         wave = fct_recode(wave,
                           "1995" = "1",
                           "2003" = "2",
                           "2013" = "3"))

issp_swiid_c <- issp_swiid_cyr %>%
  group_by(country) %>%
  summarize(gini4yr_country = mean(gini_disp_4yr),
         diff_country    = mean(diff_mean),
         nwaves          = n()) %>%
  ungroup() %>%
  left_join(issp_swiid_cyr %>% select(country_lab, country) %>% group_by(country) %>% slice_head(),
            by = "country")

rm(issp, issp_mean, swiid, swiid_summary)


# 4. Plot -----------------------------------------------------------------
p_cntryavg <- ggplot() +
  geom_point(data = issp_swiid_cyr,
             aes(x = gini_disp_4yr, y = diff_mean),
             color = "black", alpha = .2) +
  geom_smooth(data = issp_swiid_cyr,
              aes(x = gini_disp_4yr, y = diff_mean),
              linetype = "solid", color = "black", size = 0.25, alpha = 0.1, method = lm) +
  geom_point(data = issp_swiid_c,
             aes(x = gini4yr_country, y = diff_country),
             color = "steelblue", size = 3) +
  geom_text_repel(data = issp_swiid_c,
                  aes(x = gini4yr_country, y = diff_country, label = country_lab),
                  size = 2.25) +
  scale_fill_brewer(palette = "Set1") +
  scale_color_brewer(palette = "Set1") +
  labs(
    x = "Income Inequality (Gini 4-year average)",
    y = "Ethno-nationalism",
    fill = "Wave",
    color = "Wave",
    # title = "Income Inequality and Ethno-nationalism"
    # subtitle = "Data points are country-years.",
    caption = "Note: Data are from 1995-2013 ISSP National Identity cross-sections. Labeled and highlighted points indicate estimated mean levels \nof inequality and ethno-nationalism for a given country, averaged across available survey waves. Grey points represent individual \nsurveys for a single country and year."
  ) + 
  hrbrthemes::theme_ipsum() +
  theme(legend.position = "off",
        plot.caption = element_text(size = 12, hjust = 0))

ggsave(here("figures", "fig3.jpg"), plot = p_cntryavg,
       device = "jpg",
       width = 9.2, height = 5.25, dpi = 300)
