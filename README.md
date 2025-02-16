
# GAMMANN-Vir

<p align="center">
  <img src="https://github.com/xabilopalf/GAMANN-Vir/blob/main/Logo_GAMMANN-Vir.jpg" width="450" height="450"  alt=" "/>
</p>


The present document is part of a larger project that aims to analyze the temporal patterns of microorganisms, including viruses, in a 20-year time series. The project is divided into three main parts: 

   1) [Anomaly analysis](https://github.com/xabilopalf/GAMMANN-Vir/blob/main/README.md#1-anomaly-analysis)
   2) [Generalized Additive Models (GAMMs) ](https://github.com/xabilopalf/GAMMANN-Vir/blob/main/README.md#2-gamms-generalized-additive-models)
   3) [Artificial Neural Networks (ANNs)](https://github.com/xabilopalf/GAMMANN-Vir/blob/main/README.md#3-machine-learning-artificial-neural-networks-anns)
   4) [PCA and RAPDs Analysis](https://github.com/xabilopalf/GAMMANN-Vir/blob/main/README.md#4-pca-and-rapds-analysis)

  ## 1) Anomaly Analysis

Anomaly analysis involves detecting data points or observations that deviate significantly from expected patterns or normal behavior in a dataset. It is commonly used in time-series data, such as environmental or sensor readings, to identify unusual fluctuations or outliers that might indicate significant events or errors. This method represents each variable as a series of anomalies on a logarithmic scale, compared to the long-term average of the data. Anomalies for a given month \( p'<sub>(t)</sub> \) were determined by subtracting the value of each month from its interannual average  (Eq. 1), then averaging these differences to obtain the final annual anomaly ( \( p'<sub>annual</sub> \) ; Eq. 2). 

- **What the [`01_Anomaly_analysis.R`](https://github.com/xabilopalf/GAMMANN-Vir/blob/main/01_Anomaly_analysis.R) script does:** 

   - **Monthly Calculation of Interannual Mean:** For each month of the year (January, February, etc.), the mean of all available observations across the years in the time series is calculated. For example, the mean of all January temperatures over the years.
   - **Monthly Anomaly Calculation:** For each monthly observation, the anomaly is calculated as the base 10 logarithm of the ratio between the value of that month and the corresponding interannual mean for the same month.

       $$p'(t) = \log_{10} \left( \frac{P(t)}{\bar{P}} \right)$$ {1}
     
       $$p'_{annual} = \frac{1}{12} \sum_{t=1}^{12} p'(t) \tag$$ {2}     

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

- **Why Use GAMMs?**
  - The **relationship** between independent and dependent variables **doesn't have to be linear**.
  - We don’t need to know the exact mathematical form of the relationship beforehand.
  - These models are **great for visualization**, allowing us to see the **partial effects of each independent variable**.

   We can:
    - Include categorical variables and interactions.
    - Use **different types of distributions** (not just Gaussian) for the response variable.
    - Account for correlations between observations (like repeated measures or nested designs) using mixed models. In our case, especially useful for **data autocorrelation in time-series**. 
       

- **What the [`02_GAMM_analysis.R`](https://github.com/xabilopalf/GAMMANN-Vir/blob/main/02_GAMM_analysis.R) script does:**
  
  - **Temporal partial effect GAMMs** : First, a GAMMM is fitted to model viral abundance, accounting for seasonality and long-term trends. Then, additional GAMMs are automatically generated for other key variables using the fit_gams() function, and all models are visualized with gam_plots().
  - **Conditional GAMMs** : Next, an inflection point is introduced to assess potential shifts in the temporal relationship of viral abundance.
  - **Mixed partial effect GAMMs** : Finally, partial GAMMs are fitted to explore the influence of nutrients, hosts, and environmental variables on viral abundance. Each model is visualized through plots and validated using statistical diagnostics to assess model fit and potential improvements.


**References:**
-   [Dr. Victoria Quiroga's GAMMs Lecture](https://limno-con-r.github.io/libro/gam.html)
-   [R course](https://noamross.github.io/gams-in-r-course/)
-   [Oficial R documentation](https://cran.r-project.org/web/packages/gam/gam.pdf)
  
  ## 3) Machine Learning: Artificial Neural Networks (ANNs)

- **Why Use ANNs?**

Machine learning is a powerful tool for uncovering patterns in microbial communities, but its complexity often comes at the cost of interpretability. Many models prioritize accuracy over transparency, making their predictions difficult to understand. These scripts aim to extract meaningful biological insights, emphasizing the need for interpretable models. Though the use of artificial Neural Networks (ANNs), we model complex, non-linear relationships between environmental factors and viral community dynamics.

- **What the [`03_ANN_time_series.R`](https://github.com/xabilopalf/GAMMANN-Vir/blob/main/03_ANNs_time_series.R) script does:**

This script automates the process of tuning, evaluating, and optimizing neural networks to model viral abundance using various combinations of environmental and biological predictors.

This script uses artificial neural networks (ANN) to model viral abundance with environmental and biological variables. The key processes are:

  - **Hyperparameter optimization** : Model parameters are tuned using grid search, accelerated by parallelization to improve efficiency. Finding the right tuning parameters for a machine learning model can be challenging. One issue we might face is **overfitting**, where the model becomes too tailored to the training data, leading to poor performance. On the other hand, we could also run into **underfitting**, where the model doesn't learn enough from the training data, which also results in high error rates when applied to new data.

  - **Testing predictor combinations** : Models are trained with different combinations of variables to identify the best predictors for viral abundance. The script creates every possible combination of predictors and trains a model for each one. Then, it tests each model using cross-validation to make sure the results are reliable.

  - **Performance evaluation and importance analysis** : The model's performance is evaluated using metrics like R² and RMSE to assess its accuracy, and the relative importance of each predictor is calculated, identifying the most influential factors. Once the model is trained, its performance is evaluated .

Results and performance metrics are stored in **`log_Blanes_ANN_Fit_Metrics.tsv`** for further analysis.


- **What the [`04_ANN_visualization.R`](https://github.com/xabilopalf/GAMMANN-Vir/blob/main/04_ANN_visualization.R) script does:**

The script generates the following visualizations to analyze the performance of the neural network models stored in **`log_Blanes_ANN_Fit_Metrics.tsv`**:

  - **Scatter plot (RMSE vs R²):** Compares the root mean square error (RMSE) and the coefficient of determination (R²) across models. Differentiates between models that include or exclude the "Year" variable.
  - **Radar charts (Best 5% models with and without "Year"):** Show the frequency of each predictor in the top 5% of models, separately for those that include and exclude "Year".
  - **Boxplots (Predictor importance with and without "Year"):** Display the relative importance of each predictor in the best 5% of models, based on Olden's method, for models both with and without "Year".

**References:**
-   [Basics of Neural Networks: How many neurons I need?](https://www.yourdatateacher.com/2021/05/10/how-many-neurons-for-a-neural-network/) 
-   [Artificial Neural Network using R Studio](https://medium.com/@sukmaanindita/artificial-neural-network-using-r-studio-3eb538fa39fb)
-   [Visualizing neural networks in R](https://beckmw.wordpress.com/2013/11/14/visualizing-neural-networks-in-r-update/)
-   [How to tune hyperparameters with R](https://www.projectpro.io/recipes/tune-hyper-parameters-grid-search-r)
-   [Tuning hyperparameters in a neural network](https://f0nzie.github.io/machine_learning_compilation/tuning-hyperparameters-in-a-neural-network.html)
  
  ## 4) PCA and RAPDs analysis

 For this part, we also carried out a general PCA and correlogram to get an overall view of the variables.
 
 In addition, we performed Randomly Amplified Polymorphic DNA Polymerase Chain Reaction (RAPD-PCR) analysis. Jaccard dissimilarities between the samples were calculated based on the presence or absence of bands. This helped us visualize the differences in viral communities across different seasons. Everyhing can be found in the **[`05_PCA_and_RAPDs_analysis.R`](https://github.com/xabilopalf/GAMANN-Vir/blob/main/05_PCA_and_RAPDs_analysis.R )**
