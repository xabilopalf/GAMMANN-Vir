# 01_anomaly_analysis.R
   
# 1. Load the necessary libraries

required = c("readxl","tidyverse", "ggplot2", "dplyr")

for (i in required) {
  if (!require(i, character.only = T)) {
    install.packages(i, character.only = T)
  }
  library(i, character.only = T)
}

setwd()

# 2. Read the data from an Excel file
data <- read_excel("data.xlsx", sheet = "R_version_table")

# 3. Filter the data to remove the year 2023 (or any data you might not use)
data <- data %>% filter(Year != 2023)

# 4. Remove rows with NA values in the DATE variable
df_anom1 <- data %>% filter(!is.na(DATE)) 

# 5. Function anomaly.table()
# Calculate the interannual mean for each variable and month
# Calculate the monthly anomaly

anomaly.table <- function(df, no.log = c()) {
  df %>% select(Year, Month, starts_with("Temperature"):last_col()) %>%
    
    # Adequate the data to long format
    pivot_longer(cols = -c(Year, Month), names_to = "Variable", values_to = "Value") %>%
    filter(!is.na(Value)) %>%
    
    # Calculate the monthly mean for each variable
    group_by(Variable, Month) %>%
    mutate(Mean_Monthly = mean(Value, na.rm = TRUE)) %>%
    
    # Calculate the monthly anomaly with conditional logic
    mutate(Anomaly_Monthly = ifelse(
      Variable %in% no.log, 
      Value - Mean_Monthly, 
      log10(Value / Mean_Monthly)  # Apply log10 if valid
    )) %>%
    ungroup() %>%
    
    # 5.5. Sort the results by Year, Month, and Variable
    select(Year, Month, Variable, Anomaly_Monthly) %>%
    
    # 5.6. Reshape the data to wide format: each variable is a column
    pivot_wider(names_from = Variable, values_from = Anomaly_Monthly)
}

# 6. Apply the function to your dataset with variables that don't use log10
df_anom2 <- anomaly.table(df_anom1, no.log = c("Temperature", "Salinity", "Secchi_Disk"))

df_anom2 <- as.data.frame(lapply(df_anom2, function(x) format(x, scientific = FALSE)))
df_anom2 <- as.data.frame(lapply(df_anom2, function(x) as.numeric(as.character(x))))

# 8. Calculate the interannual mean of the anomalies for each variable
mean_year_anomaly <- df_anom2 %>% 
  group_by(Year) %>% 
  summarise_all(mean, na.rm = TRUE) %>% as.data.frame()

# 9. Create graphs to visualize the anomalies for each variable

#  Plot particular variables of interest
anom_plot <- ggplot(mean_year_anomaly, aes(x = Year, y = mean_year_anomaly[, 5])) + 
  geom_bar(stat = "identity", fill = ifelse(mean_year_anomaly[, 5] > 0, "#25326c", "lightblue"), 
           alpha = 0.85, color = "#25326c") +
  geom_smooth(method = "lm", se = FALSE, col = "#ffc701") +
  labs(x = "Year", y = paste(colnames(mean_year_anomaly)[5], "Anomaly")) +
  theme_minimal() +
  ggtitle(paste("Anomalies", colnames(mean_year_anomaly)[5])) + 
  theme(text = element_text(size = 20, face = "bold")) +
  geom_text(aes(label = paste("y = ", round(coef(lm(mean_year_anomaly[, 4] ~ Year))[2], 2), 
                              "x +", round(coef(lm(mean_year_anomaly[, 5] ~ Year))[1], 2)), 
                x = 2005, y = 2.7)) +
  geom_text(aes(label = paste("R2 = ", round(summary(lm(mean_year_anomaly[, 4] ~ Year))$r.squared, 2)), 
                x = 2005, y = 2.5)) ; anom_plot


#  Iterate for all variables
for (i in 4:ncol(mean_year_anomaly)) {
  # Linear model 
  formula <- as.formula(paste(colnames(mean_year_anomaly)[i], "~ Year"))
  model <- lm(formula, data = mean_year_anomaly)
  slope <- round(coef(model)[2], 2)
  intercept <- round(coef(model)[1], 2)
  r_squared <- round(summary(model)$r.squared, 2)
  
  # Plot it!
  anom_plot <- ggplot(mean_year_anomaly, aes(x = Year, y = mean_year_anomaly[, i])) +
    geom_bar(stat = "identity", fill = ifelse(mean_year_anomaly[, i] > 0, "#25326c", "lightblue"), 
             alpha = 0.85, color = "#25326c") +
    geom_smooth(method = "lm", se = FALSE, col = "#ffc701") +
    labs(x = "Year", y = paste(colnames(mean_year_anomaly)[i], "Anomaly")) +
    theme_minimal() +
    ggtitle(paste("Anomalies", colnames(mean_year_anomaly)[i])) + 
    theme(text = element_text(size = 20, face = "bold")) + 
    geom_text(aes(label = paste("y = ", slope, "x +", intercept), 
                  x = 2005, y = (0.8 * max(mean_year_anomaly[, i])))) +
    geom_text(aes(label = paste("R2 = ", r_squared), 
                  x = 2005, y = (0.7 * max(mean_year_anomaly[, i]))))
  
  # Save it as a SVG file
  ggsave(paste("anomalies_", colnames(mean_year_anomaly)[i], ".svg"), plot = anom_plot, width = 11, height = 6)
}
