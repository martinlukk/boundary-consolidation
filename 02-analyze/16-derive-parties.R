

## Program:   16-derive-parties.R
## Task:      Recodes country-specific party choice ISSP survey variables into
##            variable indicating if a far-right party is chosen, using the
##            classification scheme found in the Comparative Political Data Set.
##
## Input:     x-17-issp_ctrls_subset2.dta
## Output:    02-issp-parties.Rds
##
## Project:   boundary-consolidation
## Author:    Martin Lukk / 2021-01-07 (last updated)


# 0. Program Setup --------------------------------------------------------
library(tidyverse)
library(haven)
library(here)


# 1. Load Data ------------------------------------------------------------
issp <- read_dta(here("data", "output", "_temp", "x-17-issp_ctrls_subset2.dta"))


# 2. Clean General Variables ----------------------------------------------
issp <-
  issp %>%
  mutate(
    country_fct  = as_factor(countryV3),
    year_fct     = as_factor(year),
    country_year = fct_cross(country_fct, year_fct, sep = "_")
  ) %>%
  relocate(country_fct, year_fct, country_year, .after = year) %>%
  # Rename without variable versions
  rename_with(~ str_remove(. , "V[:digit:]$"))


# 3. Recode Radical Right Party Variable #1 (All Parties and Abstain) ------
issp_prty <-
  issp %>%
  mutate(
    farrightI_V1 = case_when(
      prty_95_A  == 3 ~ 1, # "FPOE (Right Liberal)"
      prty_95_A  != 3 ~ 0,

      prty_03_AT == 3 ~ 1, # "FPOE (Liberal)"
      prty_03_AT != 3 ~ 0,

      prty_13_BE == 7 ~ 1, # "Flemish Interest - Vlaams Belang"
      prty_13_BE %in% c(99) ~ NA_real_,
      prty_13_BE != 7 ~ 0,

      prty_95_BG != NA ~ NA_real_, # No far right party survey categories
      country_year == "Bulgaria_2003" ~ NA_real_, # Not asked

      prty_95_CDN != NA ~ NA_real_, # No far right parties in country
      prty_03_CA  != NA ~ NA_real_,

      prty_13_HR == 3 ~ 1, # "Croatian Party of Rights (Right, Conservative) - HSP"
      prty_13_HR %in% c(97, 99) ~ NA_real_,
      prty_13_HR != 3 ~ 0,

      prty_95_CZ == 16 ~ 1, # "SPR-RSC Republican Party",
      prty_95_CZ != 16 ~ 0,

      prty_03_CZ != NA ~ NA_real_, # No far right survey categories

      prty_13_CZ %in% c(8, 10, 15) ~ 1, # "Party of Free Citizens, Sovereignty, Dawn of Direct Democracy Party - Usvit"
      prty_13_CZ %in% c(97, 98, 99) ~ NA_real_,
      !(prty_13_CZ %in% c(8, 10, 15, NA)) ~ 0,

      prty_03_DK == 6 ~ 1, # "Danish Peoples Prty"
      prty_03_DK != 6 ~ 0,

      prty_13_DK == 6 ~ 1, # "Danish Peoples Party - DF, Dansk folkeparti"
      prty_13_DK %in% c(98) ~ NA_real_,
      prty_13_DK != 6 ~ 0,

      country_year == "Estonia_2013" ~ NA_real_, # No far right survey categories

      prty_03_FI == 8 ~ 1, # "True Finns"
      prty_03_FI != 8 ~ 0,

      prty_13_FI == 8 ~ 1, # "True Finns - PS"
      prty_13_FI %in% c(97, 99) ~ NA_real_,
      prty_13_FI != 8 ~ 0,

      prty_03_FR == 7 ~ 1, # "National Front"
      prty_03_FR != 7 ~ 0,

      prty_13_FR == 9 ~ 1, # "National Front - FN - Marine Le Pen"
      prty_13_FR %in% c(99) ~ NA_real_,
      prty_13_FR != 9 ~ 0,

      country_year == "Georgia_2013" ~ NA_real_, # No data on party family membership for this country

      prty_95_D == 7 ~ 1, # "Republikaner"
      prty_95_D !=7 ~ 0,

      prty_03_DE == 7 ~ 1, # "Republikaner"
      prty_03_DE == 96 ~ NA_real_, # [Would not vote;not eligible] (All are non-citizens in this category)
      prty_03_DE !=7 ~ 0,

      prty_13_DE %in% c(6, 8) ~ 1, # "National Democratic Party - NPD, AFD (Alternative for Germany)"
      prty_13_DE %in% c(97, 99) ~ NA_real_,
      !(prty_13_DE %in% c(6, 8, NA)) ~ 0,

      prty_95_H == 13 ~ 1, # "MIEP-Hungarian Justice a Life P"
      prty_95_H != 13 ~ 0,

      prty_03_HU != NA ~ NA_real_, # No far right survey categories

      prty_13_HU == 5 ~ 1, # "Movement for a Better Hungary - Jobbik"
      prty_13_HU %in% c(97, 99) ~ NA_real_,
      prty_13_HU != 5 ~ 0,

      prty_13_IS == 14 ~ 1, # "Households Party"
      prty_13_IS %in% c(97, 99) ~ NA_real_,
      prty_13_IS != 14 ~ 0,

      country_year == "India_2015" ~ NA_real_, # No data on party family membership for this country

      country_fct == "Ireland" ~ NA_real_, # No far right parties identified in country

      country_fct == "Israel" ~ NA_real_, # No data on party family membership for this country

      country_year == "Japan_1995" ~ NA_real_, # No far right survey categories

      country_year == "Japan_2003" ~ NA_real_, # No far right survey categories

      prty_13_JP == 3 ~ 1, # "Japan Restoration Party"
      prty_13_JP == 99 ~ NA_real_,
      prty_13_JP != 3 ~ 0,

      country_fct == "SKorea" ~ NA_real_, # No data on party family membership for this country

      prty_03_LV == 1 ~ 1, # "Alliance 'Tçvzemei un Brîvîbai'/LNNK"
      prty_03_LV != 1 ~ 0,

      prty_13_LV == 8 ~ 1, # "8 National Alliance 'All For Latvia!' - 'For Fatherland and Freedom/LNNK' - NA'"
      prty_13_LV %in% c(97, 99) ~ NA_real_,
      prty_13_LV != 8 ~ 0,

      country_year == "Lithuania_2013" ~ NA_real_, # No far right survey categories

      country_year == "Mexico_2015" ~ NA_real_, # No data on party family membership for this country

      prty_03_NL %in% c(9, 13) ~ 1, # "Centrum Democrats-CD, Fortuyns Party-LPF"
      prty_03_NL == 96 & (age < 18 | citizenI == 0) ~ NA_real_, # Exclude those ineligible to vote
      !(prty_03_NL %in% c(9, 13, NA)) ~ 0,

      prty_13_NL == 3 ~ 1, # "Wilders-PVV"
      prty_13_NL %in% c(99) ~ NA_real_,
      prty_13_NL != 3 ~ 0,

      prty_95_NZ == 4 ~ 1, # "New Zealand First"
      prty_95_NZ != 4 ~ 0,

      prty_03_NZ == 6 ~ 1, # "New Zealand First"
      prty_03_NZ != 6 ~ 0,

      prty_03_NO == 3 ~ 1, # "Progress Party"
      prty_03_NO != 3 ~ 0,

      prty_13_NO == 2 ~ 1, # "Progress Party - FRP"
      prty_13_NO %in% c(98, 99) ~ NA_real_,
      prty_13_NO != 2 ~ 0,

      country_year == "Philippines_2003" ~ NA_real_, # No data on party family membership for this country
      country_year == "Philippines_2014" ~ NA_real_,

      prty_95_PL %in% c(4, 17) ~ 1, # "Indep PL Confeder, Party 'X'"
      !(prty_95_PL %in% c(4, 17, NA)) ~ 0,

      country_fct == "Portugal" ~ NA_real_,  # No far right parties in country

      country_fct == "Russia" ~ NA_real_,  # No data on party family membership for this country

      prty_95_SK %in% c(9, 3) ~ 1, # "SNS Slovak Democratic Party, HZDS Movement f Democratic SK"
      !(prty_95_SK %in% c(9, 3, NA)) ~ 0,

      prty_03_SK %in% c(3, 8) ~ 1, # "I. Gasparovic (HZD), V. Meciar (HZDS-LS)"
      !(prty_03_SK %in% c(3, 8, NA)) ~ 0,

      prty_13_SK %in% c(3, 4, 9) ~ 1, # "Movement for Democratic Slovakia, Peoples Party - HZDS; Peoples Party - Our Slovakia; Slovak National Party - SNS"
      prty_13_SK == 99 ~ NA_real_,
      !(prty_13_SK %in% c(3, 4, 9, NA)) ~ 0,

      prty_95_SLO == 3 ~ 1, # "Slovenian National party"
      prty_95_SLO != 3 ~ 0,

      prty_03_SI == 4 ~ 1, # "Slovenian Nation SNS"
      prty_03_SI != 4 ~ 0,

      prty_13_SI == 4 ~ 1, # "Slovenian National Party - SNS"
      prty_13_SI %in% c(97, 99) ~ NA_real_,
      prty_13_SI != 4 ~ 0,

      country_year == "Spain_2003" ~ NA_real_, # No far right parties country in these years
      country_year == "Spain_2014" ~ NA_real_,

      prty_95_S == 6 ~ 1, # "NyD - New Democracy"
      prty_95_S != 6 ~ 0,

      country_year == "Sweden_2003" ~ NA_real_, # No far right survey categories

      prty_13_SE == 7 ~ 1, # "Sweden Democrats - SD"
      prty_13_SE == 99 ~ NA_real_,
      prty_13_SE != 7 ~ 0,

      prty_03_CH %in% c(5, 9) ~ 1, # "Swiss Peoples Party, Swiss Democrats"
      !(prty_03_CH %in% c(5, 9, NA)) ~ 0,

      country_year == "Turkey_2014" ~ NA_real_, # No data on party family membership for this country

      country_year == "UK_1995" ~ NA_real_, # No far right survey categories
      country_year == "UK_2013" ~ NA_real_,

      country_fct == "USA" ~ NA_real_, # No far right parties in time period
      country_year == "Uruguay_2004" ~ NA_real_ # No data on party family membership for this country
    )
  )

# 4. Recode Radical Right Party Variable #2 (Abstain excl.) ----------------
issp_prty <-
  issp_prty %>%
  mutate(farrightI_V2 = farrightI_V1,
         farrightI_V2 = case_when(

           prty_03_AT == 96 ~ NA_real_, # "Would not vote"

           prty_13_BE %in% c(0, 96) ~ NA_real_,

           prty_13_HR == 0 ~ NA_real_,

           prty_95_CZ == 96 ~  NA_real_, # "Would not vote;no party preference"
           prty_13_CZ == 0 ~ NA_real_,

           prty_03_DK == 96 ~ NA_real_,
           prty_13_DK %in% c(0, 96) ~ NA_real_,

           prty_03_FI == 96 ~ NA_real_,
           prty_13_FI == 0 ~ NA_real_,

           prty_03_FR == 96 ~ NA_real_, # "No preference"
           prty_13_FR %in% c(0, 96) ~ NA_real_,

           prty_95_D == 96 ~ NA_real_,
           prty_13_DE %in% c(0, 96) ~ NA_real_,

           prty_95_H == 96 ~ NA_real_,
           prty_13_HU %in% c(0, 96) ~ NA_real_,

           prty_13_IS %in% c(0, 96) ~ NA_real_,

           prty_13_JP == 0 ~ NA_real_,

           prty_03_LV == 96 ~ NA_real_,

           prty_13_LV == 0 ~ NA_real_,

           prty_03_NL == 96 ~ NA_real_,
           prty_13_NL == 0 ~ NA_real_,

           prty_03_NO == 96 ~ NA_real_,
           prty_13_NO == 0 ~ NA_real_,

           prty_95_SK == 96 ~ NA_real_,
           prty_03_SK == 96 ~ NA_real_,
           prty_13_SK == 0 ~ NA_real_,

           prty_95_SLO == 96 ~ NA_real_,
           prty_03_SI == 96 ~ NA_real_,
           prty_13_SI %in% c(0, 96) ~ NA_real_,

           prty_95_S == 96 ~ NA_real_,
           prty_13_SE == 0 ~ NA_real_,

           prty_03_CH == 96 ~ NA_real_,

           TRUE ~ farrightI_V2
           )
         )

issp_prty %>%
  select(-(starts_with("prty_"))) %>%
  filter(!is.na(farrightI_V1)) %>%
  write_rds(here("data", "output", "02-issp-parties.Rds"))
