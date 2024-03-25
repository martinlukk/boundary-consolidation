

## Program:   15-fitmodels-ethnat.R
## Task:      (1) fit linear mixed-effects models (random intercepts and slopes)
##            to ISSP/SWIID data to estimate effect of income inequality on
##            ethno-nationalism,
##            (2) generate coefficient table and plots,
##            (3) generate plots of interaction effects
##
## Input:     01-issp_swiid.Rds
##
## Output:    fig4.jpg
##            fig5.jpg
##            fig6.jpg
##
## Project:   boundary-consolidation
## Author:    Martin Lukk / 2024-01-15 (last updated)


# 0. Program Setup --------------------------------------------------------
library(tidyverse)
library(here)
library(haven)
library(parallel)
library(lme4)
library(lmerTest)
library(mice)
library(broom.mixed)
library(modelsummary)
library(ggplot2)
library(ggtext)
library(ggeffects)


# 1. Load Data ------------------------------------------------------------

# NOTE: This analysis involves fitting models to 100 imputed data sets, which
# can be computationally intensive.

# Researchers wishing to replicate the analysis on a personal computer may
# want to edit the code below to specify the analysis of fewer imputed
# data sets. This will produce similar, though not identical, model estimates
# to those in the published article.

n_imputations <- 100
 
issp_swiid <-
  read_rds(here("data", "output", "01-issp_swiid.Rds"))[1:n_imputations] %>% 
  map(. %>% mutate(across(c("edlvl", "incquin", "ethmajI", "femaleI"), ~ factor(.x))))


# 2. Specify Models -------------------------------------------------------
model1a <-
  diff_s ~ # Outcome
  gini_disp_4yr_s + # Predictor
  age_s + femaleI + edlvl + incquin + ethmajI + # Individual-level controls
  (1 | country) + (1  | country_year)  # Random-effects

model2a <- update(
  model1a,
  # Add country-level controls
  . ~ . + gdppc_s + governS_s + migstock_s + kof_trade_s)

model6a <- update(
  model2a,
  # Add cross-level interaction terms and random slopes
  . ~ . -
    (1 | country_year) +
    (1 + ethmajI + incquin | country_year) +
    gini_disp_4yr_s:ethmajI +
    gini_disp_4yr_s:incquin +
    incquin:ethmajI +
    gini_disp_4yr_s:incquin:ethmajI)


# 3. Fit Each Model to N Data Frames and Pool Results -------------------

# Define function for fitting models in parallel
fit_model <- function(data, model) {
  mclapply(data, function(df)
    lmer(formula = model, data = df),
    mc.cores = detectCores())
}

# Fit models
fit_m1a <- fit_model(issp_swiid, model1a)
fit_m2a <- fit_model(issp_swiid, model2a)
fit_m6a <- fit_model(issp_swiid, model6a)

# Pool results across imputations
results_a <- list(fit_m1a, fit_m2a, fit_m6a) %>% map(pool)


# 4. Plot Coefficients for Model without Interactions ---------------------

# Specify labels
plot_vars1 <- c(
  "gini_disp_4yr_s" = "Income inequality (4-yr avg.)",
  "gdppc_s" = "GDP per capita",
  "governS_s" = "Democratic governance",
  "migstock_s" = "Immigrant population",
  "kof_trade_s" = "Trade globalization",
  "age_s" = "Age",
  "femaleI1" = "Female",
  "ethmajI1"  = "Majority ethnic group",
  "edlvl2" = "Secondary education",
  "edlvl3" = "Some post-secondary ed.",
  "edlvl4" = "University degree or above",
  "incquin2" = "Income Q2",
  "incquin3" = "Income Q3",
  "incquin4" = "Income Q4",
  "incquin5" = "Income Q5"
)

# Add categories and spacing
add_rows_1 <-
  tibble(
    term = c(
      " ",
      "  ",
      "**Individual covariates**",
      "   ",
      "**Contextual covariates**",
      "    "
    ),
    estimate = NA,
    model = "Model 1"
  )
attr(add_rows_1, "position") <- c(5, 9, 13, 14, 19, 20)

p_coef_main <-
  modelplot(
    results_a[2],
    coef_map = rev(plot_vars1),
    add_rows = add_rows_1,
    size = .5, color = "steelblue"
  ) +
  geom_vline(xintercept = 0,
             colour = "black",
             linetype = "dashed") +
  hrbrthemes::theme_ipsum_rc() +
  labs(x = "Coefficient Estimate and 95% Confidence Interval",
       caption = 'Note: Estimates are from a linear mixed-effects model fit to 1995-2013 ISSP National Identity cross-sections. \nN (individuals) = 69,247, N (country-years) = 75, N (countries) = 38. All continuous covariates are standardized. \nThe reference category for education is "less than secondary" and Quintile 1 for income. Exact values are \nfound in Table D1 (Model 2).') +
  theme(axis.text.y = ggtext::element_markdown(),
        plot.caption = element_text(size = 11, hjust = 0))

ggsave(here("figures", "fig4.jpg"), plot = p_coef_main,
       device = "jpg",
       width = 9, height = 5.25, dpi = 300)


# 5. Plot Three-Way Interaction (Inequality x Income x Ethnicity) ----------

# Define function for predicting marginal effects 
predict_margins1 <- function(df) {
  ggpredict(df,
            terms = c("gini_disp_4yr_s [1.5:5.5 by = 0.5]", "ethmajI", "incquin"),
            condition = c(edlvl = 2))
}

predictions1 <- map(fit_m6a, predict_margins1) %>% pool_predictions()

p_predict_m6a <-
  tibble(predictions1) %>%
  mutate(x = x * 10,
  group = fct_recode(group,
                     "Yes" = "1",
                     "No"  = "0"),
  facet = fct_recode(facet,
                     "Income Quintile\n1" = "1",
                     "\n2" = "2",
                     "\n3" = "3",
                     "\n4" = "4",
                     "\n5" = "5")) %>%
  ggplot(aes(x = x, y = predicted,
             fill = group, color = group)) +
  geom_line(aes(linetype = group), size = 0.75) + 
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), size = 0, alpha = 0.1) +
  scale_fill_brewer(palette = "Set1") +
  scale_color_brewer(palette = "Set1") +
  labs(fill = "Majority ethnic group",
       color = "Majority ethnic group",
       linetype = "Majority ethnic group",
       x = "Income Inequality (Gini 4-yr average)",
       y = "Ethno-nationalism",
       caption = 'Note: Estimates are from a linear mixed-effects model fit to 1995-2013 ISSP National Identity cross-sections that includes all \nindividual and contextual covariates indicated in Figure 4. Exact values are found in Table D2 (Model 6). Values are predicted \nfor a male respondent with secondary education and other covariates at their means.') +
  facet_grid(~ facet) +
  hrbrthemes::theme_ipsum() +
  theme(legend.position = "bottom",
        plot.caption = element_text(size = 12, hjust = 0))

ggsave(here("figures", "fig5.jpg"), plot = p_predict_m6a,
       device = "jpg",
       width = 9, height = 5.25, dpi = 300)


predict_margins2 <- function(df) {
  ggpredict(df,
            terms = c("incquin", "ethmajI", "gini_disp_4yr_s [meansd]"),
            condition = c(edlvl = 2))
}

predictions2 <- map(fit_m6a, predict_margins2) %>% pool_predictions()

p_predict_int <- 
  tibble(predictions2) %>%
  mutate(group = fct_recode(group,
                            "Yes" = "1",
                            "No"  = "0"), 
         facet = fct_recode(facet,
                            "Inequality \n-1 SD" = "2.44",
                            "\nMean" = "3.03",
                            "\n+1 SD" = "3.62")
         ) %>%
  ggplot(aes(x = x, y = predicted,
             fill = group, color = group)) +
  geom_pointrange(aes(ymin = conf.low, ymax = conf.high, shape = group),
                  size = 0.75, position = position_dodge(width = .1)) +
  scale_fill_brewer(palette = "Set1") +
  scale_color_brewer(palette = "Set1") +
  labs(fill = "Majority \nethnic group",
       color = "Majority \nethnic group",
       shape = "Majority \nethnic group",
       x = "Income Quintile",
       y = "Ethno-nationalism",
       caption = "Note: Estimates are from a linear mixed-effects model fit to 1995-2013 ISSP National Identity cross-sections that includes all individual and contextual \ncovariates indicated in Figure 4. Values are predicted for a male respondent with secondary education and other covariates at means.") +
  facet_wrap(~ facet) +
  hrbrthemes::theme_ipsum() +
  theme(plot.caption = element_text(hjust = 0))

ggsave(here("figures", "fig6.jpg"), plot = p_predict_int,
       device = "jpg",
       width = 9, height = 5.25, dpi = 300)
