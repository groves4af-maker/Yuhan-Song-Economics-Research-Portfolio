# Empirical Evaluation of the London ULEZ Expansion on Air Pollution

## Overview

This project evaluates the short-run effect of the August 2023 London ULEZ expansion on air pollution, focusing on NO₂ concentrations using UK AURN/DEFRA air quality monitoring data.

The project applies a Difference-in-Differences framework to compare changes in air pollution between affected and less-affected monitoring stations before and after the ULEZ expansion.

## Research Question

Did the August 2023 London ULEZ expansion lead to an immediate reduction in NO₂ concentrations?

## Methods

- Used Python to clean and structure UK AURN/DEFRA air quality monitoring data.
- Constructed a station-day panel with over 84,000 NO₂ observations.
- Applied Difference-in-Differences models in Stata.
- Included monitoring-station and date fixed effects.
- Used clustered standard errors to account for serial correlation within monitoring stations.
- Conducted event-study analysis to assess dynamic treatment effects.
- Conducted placebo/permutation tests to examine robustness of the identification strategy.

## Software

- Python
- Stata

## Repository Structure

```text
code/      Code for data cleaning, panel construction, DiD estimation, and robustness checks
data/      Data notes and processed data, where available
output/    Figures and tables generated from the analysis
report/    Project summary and written documentation