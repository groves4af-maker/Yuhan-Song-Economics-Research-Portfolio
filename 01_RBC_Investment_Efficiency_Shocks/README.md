# Investment Efficiency Shocks in a Real Business Cycle Framework

## Overview

This project builds a calibrated RBC/DSGE-style model with TFP and investment-efficiency shocks to study investment volatility and macroeconomic shock transmission.

The project combines empirical time-series analysis using U.S. macroeconomic data with model-based simulations in Matlab/Dynare.

## Research Question

How do investment-efficiency shocks affect macroeconomic aggregates such as output, consumption, investment, capital, and the real return to capital?

## Methods

- Processed U.S. quarterly macroeconomic data from FRED, 1970–2024.
- Visualised quarterly growth rates of output, consumption, and investment.
- Estimated a Structural VAR with Cholesky identification to obtain empirical impulse responses.
- Built a calibrated RBC/DSGE-style model with TFP and investment-efficiency shocks.
- Simulated impulse response functions using Matlab/Dynare.
- Compared simulated business-cycle moments with U.S. macroeconomic data.
- Discussed calibration versus estimation and the limitations of moment-matching for structural reliability.

## Software

- R
- Matlab
- Dynare

## Repository Structure

```text
code/      Code for data processing, SVAR estimation, and Dynare simulations
data/      Data notes and processed data, where available
output/    Figures and tables generated from the analysis
report/    Project summary and written documentation