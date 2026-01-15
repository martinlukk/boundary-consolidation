# Replication Materials: "Politics of Boundary Consolidation: Income Inequality, Ethno-Nationalism, and Radical-Right Voting" (Lukk 2024)

This repository contains code and instructions to reproduce the main analyses reported in the article "Politics of Boundary Consolidation: Income Inequality, Ethno-Nationalism, and Radical-Right Voting" by Martin Lukk, published in _Socius:_

> **Abstract:** Scholars have linked income inequality to the recent success of radical-right parties and movements. Yet research finds that inequality reduces participation among groups likely to support the radical right and promotes support for redistribution, an issue championed by the radical left. This raises questions about why, if at all, inequality matters for radical-right politics. I reconcile previous arguments by developing a theory that connects these phenomena through the process of boundary consolidation. I argue that inequality generates status threats that prompt exclusionary shifts in national group boundaries. This promotes ethno-nationalism, a restrictive conception of national membership, and, ultimately, support for the radical right, whose mobilization relies on ethno-nationalist appeals. Analyses of time-series cross-sectional data from 38 countries support this theory, finding that inequality is associated with greater ethno-nationalism, with distinct associations by income and ethnicity, and that ethno-nationalism strongly predicts radical-right voting. I thus demonstrate how long-term structural changes are linked to contemporary radical politics and how arguments setting economic and cultural causes of the radical right in opposition are inadequate.

The published version (open access) is available here: https://journals.sagepub.com/doi/full/10.1177/23780231241251714.

## Citation

Lukk, Martin. 2024. “Politics of Boundary Consolidation: Income Inequality, Ethnonationalism, and Radical-Right Voting.” _Socius_ 10. https://doi.org/10.1177/23780231241251714

## Instructions

To replicate the analyses reported in the study, follow the numbered steps below.

1.  Clone the repository using Git or download and unzip the folder containing the replication files (i.e., `boundary-consolidation/` or `boundary-consolidation-main/`) to your local disk.

### Data Acquisition

2.  This study uses publicly available data from numerous sources. Download the data sets listed below from the indicated sources and save the relevant data files (indicated in parentheses) to the `data/input/` directory within the replication folder downloaded in Step #1.

    -   [Correlates of War Intergovernmental Organizations, Version 3](https://correlatesofwar.org/wp-content/uploads/state_year_formatv3.zip) (`state_year_formatv3.csv`)
    -   [International Social Survey Programme: National Identity I ("ISSP 1995")](https://doi.org/10.4232/1.2880) (`ZA2880.dta`)
    -   [International Social Survey Programme: National Identity II ("ISSP 2003")](https://doi.org/10.4232/1.11449) (`ZA3910_v2-1-0.dta`)
    -   [International Social Survey Programme: National Identity III ("ISSP 2013")](https://doi.org/10.4232/1.12312) (`ZA5950_v2-0-0.dta`)
    -   [International Social Survey Programme: National Identity III (Netherlands Sample) ("ISSP 2013 NL")](https://doi.org/10.4232/1.12921) (`ZA5517_v1-0-0.dta`)
    -   [KOF Globalisation Index 2019](https://ethz.ch/content/dam/ethz/special-interest/dual/kof-dam/documents/Medienmitteilungen/Globalisierungsindex/KOFGI_2019.zip) (`KOFGI_2019_data.dta`)
    -   [Penn World Table version 9.1](https://www.rug.nl/ggdc/docs/pwt91.dta) (`pwt91.dta`)
    -   [Standardized World Income Inequality Database, Version 9.1](https://dataverse.harvard.edu/api/access/datafile/4724739) (`swiid9_1.rda`)
    -   [U.N. International Migrant Stock, 2019](https://www.un.org/en/development/desa/population/migration/data/estimates2/data/UN_MigrantStockTotal_2019.xlsx) (`UN_MigrantStockTotal_2019.xlsx`)
    -   [Worldwide Governance Indicators ("WGI Data (STATA)")](https://datacatalog.worldbank.org/search/dataset/0038026/Worldwide%20Governance%20Indicators?version=1) (`wgidataset-fixed.dta`)

### Data Cleaning

3.  The `01-clean/` subdirectory contains a set of Stata do-files that perform tasks required to prepare the data for analysis. These can be run all at once by running `00-clean-run_all.do`, found within the subdirectory, which calls the specific do-files listed below. **Make sure to specify the file path for the project folder downloaded in Step #1** in the first line of this do-file (i.e., `../boundary-consolidation/` or `../boundary-consolidation-main/`).

-   Clean ISSP data sets:
    -   `01-clean-issp95.do`
    -   `02-clean-issp03.do`
    -   `03-clean-issp13.do`
    -   `04-clean-issp13NL.do`
-   Generate derived variables and save harmonized data file:
    -   `05-derive-issp95.do`
    -   `06-derive-issp03.do`
    -   `07-derive_append-issp13.do`
    -   `08-append-issp.do`
-   Clean and merge country-level control variables with ISSP data:
    -   `09-merge-controls.do`
-   Subset data and select variables for analyses:
    -   `10-subset1-issp_ctrls_ethnat.do`
    -   `11-subset2-issp_ctrls_voting.do`

### Analyses

4.  The `02-analyze/` subdirectory contains a set of `R` scripts that perform additional tasks required to analyze the data and perform the analyses themselves, as described below. First, open `boundary-consolidation.Rproj` in RStudio to access the project associated with these replication materials. Then, run the analysis scripts within RStudio in the order specified to generate `Figures 2-7` and reproduce the main analyses reported in the article. Figures generated by these scripts can be found in the `figures/` subdirectory.

-   Perform factor analysis and derive ethno-nationalism outcome variables:
    -   `11-derive-fscores.R`
-   Merge ISSP attitude data with SWIID income inequality estimates:
    -   `12-merge-issp_swiid.R`
-   Compute descriptive statistics and summary data, generate `Figure 2` and `Figure 3`:
    -   `13-descriptive_stats.R`
    -   `14-descriptive-bivariate.R`
-   Fit linear mixed-effects models, generate `Figure 4`, `Figure 5`, and `Figure 6`:
    -   `15-fitmodels-ethnat.R`
    -   Note: **this analysis involves fitting models to 100 imputed data sets, which can be computationally intensive.** Researchers wishing to replicate the analysis on a personal computer may wish to edit the script to specify fewer imputed data sets, which will produce similar, though not identical, model estimates.
-   Generate far right party choice variable, fit mixed-effects logistic regression models and compute marginal effects, generate `Figure 7`:
    -   `16-derive-parties.R`
    -   `17-fitmodels-voting.R`

## Author Information

Please contact me at [martin.lukk\@mail.utoronto.ca](mailto:martin.lukk@mail.utoronto.ca) if you have questions or find any discrepancies, or submit an [issue](https://github.com/martinlukk/boundary-consolidation/issues) on GitHub.
