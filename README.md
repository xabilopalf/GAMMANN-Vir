# Virus Time Series: Modelling time series with GAMs and ANNs
The present document is part of a larger project that aims to analyze the temporal patterns of microorganisms, including viruses, in a 20-year time series. The project is divided into three main parts: (1) Anomaly analyses, (2) Generalized Additive Models (GAMs), and (3) Artificial Neural Networks (ANNs). This document focuses on the third part, which aims to predict the viral abundance time series through the use of ANNs. The document is structured as follows: 

  ## 1) Anomaly Analysis

Anomaly analysis involves detecting data points or observations that deviate significantly from expected patterns or normal behavior in a dataset. It is commonly used in time-series data, such as environmental or sensor readings, to identify unusual fluctuations or outliers that might indicate significant events or errors.

- **What the script does:** `01_anomaly_analysis.R`

   - **Monthly Calculation of Interannual Mean:** For each month of the year (January, February, etc.), the mean of all available observations across the years in the time series is calculated. For example, the mean of all January temperatures over the years.
   - **Monthly Anomaly Calculation:** For each monthly observation, the anomaly is calculated as the base 10 logarithm of the ratio between the value of that month and the corresponding interannual mean for the same month.

        $$ p'(t) = \log_{10} \left( \frac{P(t)}{\bar{P}} \right) $$

  Where:
  - \( p'(t) \) is the anomaly for the given time \( t \),
  - \( P(t) \) is the observed value at time \( t \),
  - \( \bar{P} \) is the interannual mean for the month corresponding to time \( t \).


- **Visualization:**
    Generates bar plots with linear regression to visualize the anomalies over time.


This process helps to identify and visualize any significant deviations in the data, aiding in the detection of potential errors or notable events.

  
  ## 2) GAMs: Generalized Additive Models
  
  ## 3) Machine Learning: Artificial Neural Networks (ANNs)
  
  ## 4) References.
