
# GAMANN-Vir

<p align="center">
  <img src="https://github.com/xabilopalf/GAMANN-Vir/blob/main/Logo_GAMANN-Vir_page-0001.jpg" width="450" height="450"  alt=" "/>
</p>


The present document is part of a larger project that aims to analyze the temporal patterns of microorganisms, including viruses, in a 20-year time series. The project is divided into three main parts: 

  - 1) [Anomaly analyses](https://github.com/xabilopalf/GAMANN-Vir/blob/main/README.md#1-anomaly-analysis)
  - 2) [Generalized Additive Models (GAMs) ](https://github.com/xabilopalf/GAMANN-Vir/blob/main/README.md#2-gams-generalized-additive-models)
  - 3) [Artificial Neural Networks (ANNs)](https://github.com/xabilopalf/GAMANN-Vir/blob/main/README.md#3-machine-learning-artificial-neural-networks-anns)

This document focuses on the third part, which aims to predict the viral abundance time series through the use of ANNs. The document is structured as follows: 

  ## 1) Anomaly Analysis

Anomaly analysis involves detecting data points or observations that deviate significantly from expected patterns or normal behavior in a dataset. It is commonly used in time-series data, such as environmental or sensor readings, to identify unusual fluctuations or outliers that might indicate significant events or errors.

- **What the [`01_Anomaly_analysis.R`](https://github.com/xabilopalf/GAMANN-Vir/blob/main/01_Anomaly_analysis.R) script does:** 

   - **Monthly Calculation of Interannual Mean:** For each month of the year (January, February, etc.), the mean of all available observations across the years in the time series is calculated. For example, the mean of all January temperatures over the years.
   - **Monthly Anomaly Calculation:** For each monthly observation, the anomaly is calculated as the base 10 logarithm of the ratio between the value of that month and the corresponding interannual mean for the same month.

       $$p'(t) = \log_{10} \left( \frac{P(t)}{\bar{P}} \right)$$

  Where:
  - $$\( p'(t) \)$$ is the anomaly for the given time $$\( t \)$$ ,
  - $$\( P(t) \)$$ is the observed value at time $$\( t \)$$ ,
  - $$\( \bar{P} \)$$ is the interannual mean for the month corresponding to time $$\( t \)$$ .


- **Visualization:**
    Generates bar plots with linear regression to visualize the anomalies over time.


This process helps to identify and visualize any significant deviations in the data, aiding in the detection of potential errors or notable events.

**References:**
-   [Anomalies by NOAA](https://www.ncei.noaa.gov/access/monitoring/dyk/anomalies-vs-temperature)
-   [The ICES Phytoplankton & Microbial Plankton Status Report](https://wgpme.net/plankton-status-report) *(Explanation of how anomalies are calculated)*
  
  ## 2) GAMMs: Generalized Additive Models

- **Why Use GAMs?**
  - The **relationship** between independent and dependent variables **doesn't have to be linear**.
  - We don’t need to know the exact mathematical form of the relationship beforehand.
  - These models are **great for visualization**, allowing us to see the **partial effects of each independent variable**.

   We can:
    - Include categorical variables and interactions.
    - Use **different types of distributions** (not just Gaussian) for the response variable.
    - Account for correlations between observations (like repeated measures or nested designs) using mixed models. In our case, especially useful for **data autocorrelation in time-series**. 
       

- **What the [`02_GAMM_analysis.R`](https://github.com/xabilopalf/GAMANN-Vir/blob/main/02_GAMM_analysis.R) script does:**
  
  - **Temporal partial effect GAMMs** : First, a GAMM is fitted to model viral abundance, accounting for seasonality and long-term trends. Then, additional GAMs are automatically generated for other key variables using the fit_gams() function, and all models are visualized with gam_plots().
  - **Conditional GAMMs** : Next, an inflection point is introduced to assess potential shifts in the temporal relationship of viral abundance.
  - **Mixed partial effect GAMMs** : Finally, partial GAMs are fitted to explore the influence of nutrients, hosts, and environmental variables on viral abundance. Each model is visualized through plots and validated using statistical diagnostics to assess model fit and potential improvements.


**References:**
-   [Dr. Victoria Quiroga's GAMs Lecture](https://limno-con-r.github.io/libro/gam.html)
-   [R course](https://noamross.github.io/gams-in-r-course/)
-   [Oficial R documentation](https://cran.r-project.org/web/packages/gam/gam.pdf)
  
  ## 3) Machine Learning: Artificial Neural Networks (ANNs)

- **Why Use GAMs?**

- **What the [`03_ANN_time_series.R`](https://github.com/xabilopalf/GAMANN-Vir/blob/main/03_ANN_time_series.R) script does:**

This script automates the process of tuning, evaluating, and optimizing neural networks to model viral abundance using various combinations of environmental and biological predictors.

This script uses artificial neural networks (ANN) to model viral abundance with environmental and biological variables. The key processes are:

  - **Hyperparameter optimization** : Model parameters are tuned using grid search, accelerated by parallelization to improve efficiency. Finding the right tuning parameters for a machine learning model can be challenging. One issue we might face is **overfitting**, where the model becomes too tailored to the training data, leading to poor performance. On the other hand, we could also run into **underfitting**, where the model doesn't learn enough from the training data, which also results in high error rates when applied to new data.

  - **Testing predictor combinations** : Models are trained with different combinations of variables to identify the best predictors for viral abundance. The script creates every possible combination of predictors and trains a model for each one. Then, it tests each model using cross-validation to make sure the results are reliable.

  - **Performance evaluation and importance analysis** : The model's performance is evaluated using metrics like R² and RMSE to assess its accuracy, and the relative importance of each predictor is calculated, identifying the most influential factors. Once the model is trained, its performance is evaluated .

Results and performance metrics are stored for further analysis.
  
  ## 4) References.
