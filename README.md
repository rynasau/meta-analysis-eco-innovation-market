# meta-analysis-eco-innovation-market
# Meta-Analysis of Market Forces and Eco-Innovation

This repository contains a reproducible econometric workflow in **Stata** implementing a meta-analysis studying how market forces influence eco-innovation outcomes across empirical studies.
The project was developed as part of the course **Econometrics for Decision-Making** (January 2026).

This project conducts a structured meta-analysis to:

- Systematically screen empirical studies
- Harmonize reported econometric results
- Compute standardized effect sizes
- Estimate pooled effects using multilevel random-effects models
- Explore heterogeneity across regions and economic sectors
- Assess potential publication bias

# 1. Study Screening
- Theoretical screening based on relevance to market-force drivers of eco-innovation
- Variable-level filtering using manual tagging

# 2. Data Cleaning and Harmonization
- Regex extraction of coefficients and standard errors
- Standardization of decimal formats and missing statistics recovery
- Removal of implausible estimates

# 3. Effect Size Construction
- Calculation of t-statistics from:
  - Reported statistics
  - Standard errors
  - P-values
- Conversion to Partial Correlation Coefficients
- Fisher Z transformation
- Variance estimation

# 4. Econometric Estimation
- Multilevel random-effects meta-analysis
- Study-level clustering of effect sizes
- Subgroup analysis:
  - Geographic region
  - Industrial sector

# 5. Robustness and Diagnostics
- Heterogeneity estimation
- Prediction interval calculation
- Funnel plot and Egger’s test for publication bias

# Data Availability

The raw dataset used in this project cannot be publicly shared. The dataset, including the original collection of studies, was provided by the course instructor.
The repository therefore contains only the code required to replicate the analysis workflow. The structure and processing steps are fully documented to allow reproducibility if there's an access to the original data.



