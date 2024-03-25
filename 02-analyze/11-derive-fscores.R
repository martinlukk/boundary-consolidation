

## Program:   11-derive-fscores.R
## Task:      Prepare ISSP variables for modeling,
##            conduct factor analysis and derive ethno-nationalism outcome
##            variables.
##
## Input:     x-16-issp_ctrls_subset1.dta
## Output:    x-18-issp-derived.Rds
##
## Project:   boundary-consolidation
## Author:    Martin Lukk / 2024-01-15 (last updated)


# 0. Program Setup --------------------------------------------------------

# NOTE: This project uses {renv} to manage the packages required to run its
# scripts. The `renv::restore()` command, called below, will prompt you to
# install the correct versions of the required packages before proceeding
# with the analysis script.

renv::restore()
library(tidyverse)
library(here)
library(haven)
library(lavaan)


# 1. Load Data ------------------------------------------------------------
issp <- read_dta(here("data", "output", "_temp", "x-16-issp_ctrls_subset1.dta")) %>%
  filter(across(starts_with("imp"), ~ !is.na(.x)))


# 2. Clean Data -----------------------------------------------------------
vars_continuous <- c("age", "governS", "migstock", "kof_trade", "gdppc")
vars_ordinal <- c("edlvl", "incquin")

issp <-
  issp %>%
  mutate(
    country_fct  = as_factor(countryV3),
    year_fct     = as_factor(year),
    country_year = fct_cross(country_fct, year_fct, sep = "_")
  ) %>%
  relocate(country_fct, year_fct, country_year, .after = year) %>%
  rename_with(~ str_remove(. , "V[:digit:]$")) %>%
  mutate(
    gdppc_src = gdppc,
    gdppc = log(gdppc),
    across(all_of(vars_continuous),
           # Standardize continuous vars with mean = 0, SD = 1
           ~ as.vector(scale(.x, center = TRUE, scale = TRUE)),
           .names = "{.col}_s"),
    across(all_of(vars_ordinal),
           ~ factor(.x)
    ),
    across(starts_with("imp"), ~ as.numeric(.x))
  ) %>%
  select(-c(starts_with("prty_")))


# 3. Confirmatory Factor Analysis -----------------------------------------
model3 <- ' ethnic =~ impbornP + impliveP + impreligP + impcitP +
                      impfeelP + implangP
            civic  =~ imprespP + implangP + impfeelP +
                      impcitP  + impreligP + impliveP
            impbornP ~~ impcitP '

fit_m3 <- cfa(model3, data = issp, sampling.weights = "weight")


# 4. Predict Factor Scores and Merge --------------------------------------
fscores_m3 <-
  fit_m3 %>%
  lavPredict(., method = "regression")

issp_outcomes <- cbind(issp, fscores_m3)


# 5. Generate Difference Score --------------------------------------------
issp_outcomes <-
  issp_outcomes %>%
  mutate(
    diff = ethnic - civic,
    diff_s = as.vector(scale(diff, center = TRUE, scale = TRUE)))


# 6. Save New Data Set ----------------------------------------------------
write_rds(issp_outcomes, here("data", "output", "_temp", "x-18-issp-derived.Rds"))
