# Project Summary

## Title

Empirical Evaluation of the London ULEZ Expansion on Air Pollution

## Research Question

Did the August 2023 London ULEZ expansion lead to an immediate reduction in NO₂ concentrations?

## Data

This project uses UK AURN/DEFRA air quality monitoring data. The analysis constructs a station-day panel with over 84,000 NO₂ observations.

## Methodology

First, I use Python to clean and structure raw air quality monitoring data.

Second, I construct a station-day panel and define treatment status based on exposure to the August 2023 London ULEZ expansion.

Third, I estimate Difference-in-Differences models in Stata with monitoring-station and date fixed effects. I cluster standard errors at the monitoring-station level to account for serial correlation within stations.

Finally, I conduct event-study and placebo/permutation tests to assess dynamic treatment effects, parallel trends, and robustness of the identification strategy.

## Main Findings

The results show no statistically significant immediate decline in NO₂ concentrations after the ULEZ expansion.

This suggests that detecting short-run effects of real-world environmental policies can be empirically challenging, especially when pollution outcomes are affected by weather, traffic patterns, station location, and other confounding factors.

## Software

- Python
- Stata