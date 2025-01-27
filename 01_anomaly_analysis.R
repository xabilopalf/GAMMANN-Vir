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

# 3. Filter the data to remove the year 2023
data <- data %>% filter(Year != 2023)

# 4. Remove rows with NA values in the DATE variable
df_anom1 <- data %>% filter(!is.na(DATE)) 

# 5. Function anomaly.table()
#  5.1. Filter only numeric columns starting from "Temperature"
#  5.2. Calculate the interannual mean for each variable and month
#  5.3. Calculate the monthly anomaly

anomaly.table <- function(df, no.log = c()) {
  df %>%
    # 5.1. Filter columns starting with "Temperature" up to the last column
    select(Year, Month, starts_with("Temperature"):last_col()) %>%
    
    # 5.2. Convert the dataframe to long format, with one row for each variable and month
    pivot_longer(cols = -c(Year, Month), names_to = "Variable", values_to = "Value") %>%
    filter(!is.na(Value)) %>%
    
    # 5.3. Calculate the monthly mean for each variable
    group_by(Variable, Month) %>%
    mutate(Mean_Monthly = mean(Value, na.rm = TRUE)) %>%
    
    # 5.4. Calculate the monthly anomaly with conditional logic
    mutate(Anomaly_Monthly = ifelse(
      Variable %in% no.log,                # If the variable is in no.log
      Value - Mean_Monthly,                # No log10 for these variables
      ifelse(
        (Value - Mean_Monthly) > 0,        # Validate that it is not negative or zero
        log10(Value - Mean_Monthly),      # Apply log10 if valid
        NA                                # Assign NA if not valid
      )
    )) %>%
    ungroup() %>%
    
    # 5.5. Sort the results by Year, Month, and Variable
    select(Year, Month, Variable, Anomaly_Monthly) %>%
    
    # 5.6. Reshape the data to wide format: each variable is a column
    pivot_wider(names_from = Variable, values_from = Anomaly_Monthly)
}

# 6. Apply the function to your dataset with variables that don't use log10
df_anom2 <- anomaly.table(df_anom1, no.log = c("Temperature", "Salinity", "Secchi_Disk"))

# 7. Convert all columns to general numeric format (no scientific notation)
df_anom2 <- as.data.frame(lapply(df_anom2, function(x) format(x, scientific = FALSE)))
df_anom2 <- as.data.frame(lapply(df_anom2, function(x) as.numeric(as.character(x))))

# 8. Calculate the interannual mean of the anomalies for each variable
mean_year_anomaly <- df_anom2 %>% 
  group_by(Year) %>% 
  summarise_all(mean, na.rm = TRUE) %>% as.data.frame()

# 9. Create graphs to visualize the anomalies for each variable

#  9.1. Plot the anomaly for a particular variable
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

#  9.2. Iterate over columns 4 to the end of the table to plot each variable
for (i in 4:ncol(mean_year_anomaly)) {
  # 9.2.1. Create the linear model for the current variable
  formula <- as.formula(paste(colnames(mean_year_anomaly)[i], "~ Year"))
  model <- lm(formula, data = mean_year_anomaly)
  slope <- round(coef(model)[2], 2)
  intercept <- round(coef(model)[1], 2)
  r_squared <- round(summary(model)$r.squared, 2)
  
  # 9.2.2. Create the plot for the variable
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
  
  # 9.2.3. Save the plot as an SVG file
  ggsave(paste("anomalies_", colnames(mean_year_anomaly)[i], ".svg"), plot = anom_plot, width = 11, height = 6)
}
