

## Program:   17-fitmodels-voting.R
## Task:      (2) Predict nationalism factor scores and generate ethno-nationalism
##            outcome variables for ISSP respondents,
##            (3-4) fit mixed-effects logistic regression models of vote choice
##            on nationalism,
##            (5) compute and plot AMEs
##
## Input:     02-issp-parties.Rds
## Output:    fig7.jpg
##
## Project:   boundary-consolidation
## Author:    Martin Lukk / 2024-01-15 (last updated)


# 0. Program Setup --------------------------------------------------------
library(tidyverse)
library(haven)
library(here)
library(lavaan)
library(lmerTest)
library(broom.mixed)
library(modelsummary)
library(ggeffects)
library(margins)


# 1. Load Data ------------------------------------------------------------
issp <- read_rds(here("data", "output", "02-issp-parties.Rds")) %>%
  filter(across(starts_with("imp"), ~ !is.na(.))) %>%
  mutate(across(starts_with("imp"), ~ as.numeric(.x)),
         across(c("farrightI_V1", "farrightI_V2", "edlvl", "incquin", "ethmajI", "femaleI", "urbrural", "unemployedI", "unionI", "wrksupI"), ~ factor(.x)),
         across(c("age", "sss10"),  ~ as.vector(scale(.x, center = TRUE, scale = TRUE)), .names = "{.col}_s")) %>%
  zap_labels()


# 2. Fit CFA Models and Predict Factor Scores -----------------------------
model_cfa <- ' ethnic =~ impbornP + impliveP + impcitP + impreligP +
                      impfeelP + implangP
            civic  =~ impfeelP + implangP + imprespP +
                      impcitP  + impliveP + impreligP
            impbornP ~~ impcitP '

fscores <-
  cfa(model_cfa, data = issp, sampling.weights = "weight") %>%
  lavPredict(., method = "regression")

issp_outcomes <-
  cbind(issp, fscores) %>%
  mutate(diff = ethnic - civic,
         diff_s = as.vector(scale(diff, center = TRUE, scale = TRUE)))


# 3. Specify Models -------------------------------------------------------
model1 <-
  farrightI_V1 ~
  diff_s + sss10_s +
  age_s + femaleI + edlvl + incquin + ethmajI + urbrural +
  unemployedI + wrksupI + unionI +
  (1 | country) +
  (1 | country_year)

model2 <- update(model1, farrightI_V2 ~ . )


# 4. Fit Mixed-Effects Logistic Regression Model of Vote Choice -----------
fit_m1 <- glmer(formula = model1,
                data = issp_outcomes,
                family = binomial(link = "logit"),
                control = glmerControl(optimizer = "bobyqa"))

fit_m2 <- glmer(formula = model2,
                data = issp_outcomes,
                family = binomial(link = "logit"),
                control = glmerControl(optimizer = "bobyqa"))


# 5. Generate Plot of AMEs ------------------------------------------------
ame_m1 <- margins(fit_m1)
ame_m2 <- margins(fit_m2)

plot_vars <- c(
  "(Intercept)" = "(Intercept)",
  "diff_s" = "Ethno-nationalism",
  "sss10_s" = "Subjective social status",
  "age_s" = "Age",
  "femaleI1" = "Female",
  "ethmajI1"  = "Majority ethnic group",
  "edlvl2" = "Secondary education",
  "edlvl3" = "Some post-secondary ed.",
  "edlvl4" = "University degree or above",
  "incquin2" = "Income Q2",
  "incquin3" = "Income Q3",
  "incquin4" = "Income Q4",
  "incquin5" = "Income Q5",
  "unemployedI1" = "Unemployed",
  "wrksupI1" = "Supervisor at work",
  "unionI1" = "Trade union member",
  "urbrural2" = "Town/small city",
  "urbrural3" = "Rural area"
)

add_rows <-
  tibble(
    term = c(
      " ", "  ", "   ", "    ", "     ", "      "),
    estimate = NA,
    model = "No"
  )
attr(add_rows, "position") <- c(4, 12, 21, 28, 35, 38)

p_coef_vote <-
  modelplot(list("No" = ame_m1, "Yes" = ame_m2),
            add_rows = add_rows,
            coef_map = rev(plot_vars[-1]),
            draw = FALSE
  ) %>%
  mutate(across(c(estimate, std.error, conf.low, conf.high), ~ .x * 100)) %>%
  ggplot(aes(y = term, x = estimate,
             xmin = conf.low, xmax = conf.high,
             color = model, shape = model)) +
  geom_pointrange(position = position_dodge(width = .7)) +
  scale_color_brewer(palette = "Set1") +
  geom_vline(xintercept = 0, colour = "black", linetype = "dashed") +
  labs(
    x = "Average Marginal Effect and 95% Confidence Interval",
    y = "",
    color = "Abstain \nexcluded",
    shape = "Abstain \nexcluded",
    caption = 'Note: Estimates are from logistic mixed-effects models fit to 1995-2013 ISSP National Identity \ncross-sections and include random intercepts for countries and country-years. N (individuals-\nabstain incl.) = 22,616, N (individuals-abstain excl.) = 18,919, N (country-years) = 34, N \n(countries) = 20. All continuous covariates are standardized. The reference category for \neducation is "less than secondary", Quintile 1 for income, and "urban" for place of residence. \nExact values are found in Table D3 (Models 1-2).'
  ) +
  hrbrthemes::theme_ipsum() +
  theme(plot.caption = element_text(size = 12, hjust = 0))

ggsave(here("figures", "fig7.jpg"), plot = p_coef_vote,
       device = "jpg",
       width = 9, height = 5.25, dpi = 300)
