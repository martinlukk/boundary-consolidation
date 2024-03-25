

## Program:   12-merge-issp_swiid.R
## Task:      (1-2) Load SWIID and ISSP data and harmonize variable names,
##            (3) generate variable containing Gini 4-year average,
##            (4) merge cleaned and subsetted ISSP data (including
##            country-level controls) with derived SWIID data,
##            (5) save new .Rds file containing an object with 100 data frames,
##            each containing the same ISSP data but different sets of SWIID
##            imputations.
##
## Input:     x-18-issp-derived.Rds
## Output:    01-issp_swiid.Rds
##
## Project:   boundary-consolidation
## Author:    Martin Lukk / 2021-01-07 (last updated)


# 0. Program Setup --------------------------------------------------------
library(tidyverse)
library(here)
library(haven)
library(countrycode)
library(slider)


# 1. Load Data ------------------------------------------------------------
load(here("data", "input", "swiid9_1.rda")); rm(swiid_summary)
issp <- read_rds(here("data", "output", "_temp", "x-18-issp-derived.Rds"))


# 2. Prepare for Merging --------------------------------------------------
swiid <- swiid %>%
    map(
    . %>%
      # Convert SWIID country codes into ISSP (ISO3N) codes
      mutate(
        country = countrycode(country,
                              origin = "country.name",
                              destination = "iso3n",
                              warn = F)
      ) %>%
      select(-c(gini_mkt, abs_red, rel_red)) %>%
      # Drop countries without ISO3N codes
      filter(!is.na(country))
  )


# 3. Derive Gini 4-year averages ------------------------------------------
swiid <- swiid %>%
  map(
    . %>%
      arrange(country, year) %>%
      group_by(country) %>%
      filter(n() >= 5) %>%
      # Generate mean based on given year and previous 3
      mutate(gini_disp_4yr =
               slide_index_mean(gini_disp, i = year, before = 3)) %>%
      ungroup() %>%
      # Rescale
      mutate(gini_disp_4yr_s = gini_disp_4yr / 10)
  )


# 4. Merge Data Sets ------------------------------------------------------
issp_swiid <- swiid %>%
  map(. %>%
        left_join(issp, by = c("country", "year")) %>%
        filter(!is.na(id))
  ) %>%
  map( ~ as.data.frame(.x, stringsAsFactors = F)) %>%
  map(zap_labels)


# 5. Save New Data Set ----------------------------------------------------
write_rds(issp_swiid, here("data", "output", "01-issp_swiid.Rds"))
