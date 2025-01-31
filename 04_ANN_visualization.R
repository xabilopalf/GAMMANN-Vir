# 04_ANN_visualization.R


# 1. Load the necessary libraries
required = c("readr","tidyverse", "ggplot2", "dplyr", "fmsb")

for (i in required) {
  if (!require(i, character.only = T)) {
    install.packages(i, character.only = T)
  }
  library(i, character.only = T)
}

setwd()


# Load data
ann_output <- read_delim("~/Downloads/log_Blanes_ANN_Fit_Metrics.tsv", 
                         delim = "\t", escape_double = FALSE, 
                         trim_ws = TRUE)

# 2. Data preparation
ann_output$RMSE <- as.numeric(gsub(",", ".", ann_output$RMSE))
ann_output$Rsquared <- as.numeric(gsub(",", ".", ann_output$Rsquared))
ann_output$size <- as.numeric(ann_output$size)
ann_output$predictors_num <- as.numeric(sapply(strsplit(ann_output$predictors, ","), length)) # Contar número de predictores



# 3. Figure 1: RMSE vs R squared for ANN models with different predictors

Figure_1<- ggplot(ann_output, aes(x = (RMSE), y = Rsquared, color = as.factor(grepl("Year", predictors)))) +
  geom_point(alpha = 0.7, size=2.5) +
  scale_color_manual(values = c("#21908C", "#FF5733"), labels = c("W/o Year", "W/ Year"), name = " ") +
  labs(x = "RMSE", y = "R squared",  title = "RMSE vs R squared for ANN models with different predictors") +
  theme_minimal() + 
  theme(legend.position = # que sea en la parte superior derecha
          c(0.8, 0.9),  legend.text = element_text(size = 13)) 

ggsave("RMSE_vs_Rsquared.svg", plot = Figure_1, width = 8, height = 8, units = "in")


# 4. Prepare data for Radar Chart for best 5% of the models containing Year

# Select the models containing the variable Year
year_data<- ann_output %>%
  filter(grepl("Year", predictors))

# from those, select the best 5% of the models
year_5perc <- year_data %>% slice_max(order_by = Rsquared, prop = 0.05)  %>%
  arrange(Rank_R2) %>%
  select(predictors, Rank_R2, RMSE, Rsquared, Olden) %>% as.data.frame()

# check that we have taken 5% of the data
year_5perc %>%
  nrow() / nrow(year_data) * 100



# 5. Figure 2: RADAR CHART, predictor Frequency of Best 5% of the models containing Year

# Calculate frequency of each predictor
predictor_frequency <- year_5perc %>%
  separate_rows(predictors, sep = ",") %>%  # Dividir combinaciones en filas únicas
  count(predictors, name = "frequency") %>%  # Contar ocurrencias
  mutate(normalized_frequency = frequency / max(frequency))  # Normalizar las frecuencias

# Prepare data for plot: Predictors and their Frequency
radar_data <- predictor_frequency %>%
  select(predictors, normalized_frequency) %>%
  pivot_wider(names_from = predictors, values_from = normalized_frequency) %>%
  replace(is.na(.), 0)  # If NA, replace with 0

# Limits
radar_data <- bind_rows(
  tibble(!!!set_names(rep(1, ncol(radar_data)), names(radar_data))),  # Max
  tibble(!!!set_names(rep(0, ncol(radar_data)), names(radar_data))),  # Min
  radar_data)

# Figure_2 "Radar Chart of Predictors for best %5 ANNs containing Year
Figure_2 <- radarchart(as.data.frame(radar_data),
  axistype = 4 ,pcol = c( "#FF5733"), pfcol = c(adjustcolor("#FF5733", alpha.f = 0.4)), plwd = 2, 
  title = paste("Radar Chart of Predictors for best %5 ANNs containing Year"))

ggsave("Radar_Year_best_5perc.svg", plot = Figure_2, width = 8, height = 8, units = "in")




# 6. NO YEAR: Prepare data for Radar Chart for best 5% of the models **WITHOUT**  Year

# Select the models containing the variable Year
no_year_data<- ann_output %>%
  filter(!grepl("Year", predictors)) 

# from those, select the best 5% of the models
no_year_5perc <- no_year_data %>% slice_max(order_by = Rsquared, prop = 0.05)  %>%
  arrange(Rank_R2) %>%
  select(predictors, Rank_R2, RMSE, Rsquared, Olden) %>% as.data.frame()

# check that we have taken 5% of the data
no_year_5perc %>%
  nrow() / nrow(no_year_data) * 100





# 7. Figure 3: RADAR CHART, predictor Frequency of Best 5% of the models **WITHOUT** Year

# Calculate frequency of each predictor
predictor_frequency_no_year <- no_year_5perc %>%
  separate_rows(predictors, sep = ",") %>%  # Dividir combinaciones en filas únicas
  count(predictors, name = "frequency") %>%  # Contar ocurrencias
  mutate(normalized_frequency = frequency / max(frequency))  # Normalizar las frecuencias

# Prepare data for plot: Predictors and their Frequency
radar_data_no_year <- predictor_frequency_no_year %>%
  select(predictors, normalized_frequency) %>%
  pivot_wider(names_from = predictors, values_from = normalized_frequency) %>%
  replace(is.na(.), 0)  # If NA, replace with 0

# Limits
radar_data_no_year <- bind_rows(
  tibble(!!!set_names(rep(1, ncol(radar_data_no_year)), names(radar_data_no_year))),  # Max
  tibble(!!!set_names(rep(0, ncol(radar_data_no_year)), names(radar_data_no_year))),  # Min
  radar_data_no_year)

# Figure_3 "Radar Chart of Predictors for best %5 ANNs containing Year
Figure_3 <- radarchart( as.data.frame(radar_data_no_year),
  axistype = 4,  pcol = c( "#21908C"), pfcol = c(adjustcolor("#21908C", alpha.f = 0.4)),  plwd = 2, 
  title = paste("Radar Chart of Predictors for best %5 ANNs NOTcontaining Year")) 

ggsave("Radar_NOYear_best_5perc.svg", plot = Figure_3, width = 8, height = 8, units = "in")





# 8. Oldens boxplots, YEAR: Prepare data for oldens predictor importance for best 5% of the models containing Year


# Select variables with Olden for the best 5% of the models containing Year
ann_olden <- year_5perc %>%
  select(RMSE, Rsquared, Rank_R2, predictors, Olden) 

# Extract Olden from Predictors
df_sep <- ann_olden %>%
  separate_rows(Olden, sep = "; ") %>%
  separate(Olden, into = c("Predictor", "Value"), sep = ",") %>%
  mutate(Value = as.numeric(Value) )%>%
  pivot_wider(names_from = Predictor, values_from = Value) # this separates columns for each predictor

df_Olden_boxplots<- ann_olden %>% select(-Olden) %>% bind_cols(df_sep) 


# Reshape data to long format
df_long <- df_Olden_boxplots %>%
  pivot_longer(
    cols = c(NO3, Bacteria_DAPI, Abun_HNF, Year, PO4, SiO4, NO2, Abun_PNF, Temperature, Synechococcus, Secchi_Disk, CHL, Prochlorococcus),
    names_to = "Variable",
    values_to = "Importance") %>% filter(!is.na(Importance)) 

# Counts of every predictor variable (for the upper part of the plot)
variable_counts <- df_long %>%
  group_by(Variable) %>%
  summarise(Count = n(), .groups = "drop")

# After doing counts, order the variables by the number of appearances
df_long <- df_long %>%
  mutate(Variable = factor(Variable, levels = variable_counts$Variable[order(-variable_counts$Count)]))


# 9. Figure 4: Olden's Importance of each predictor in all Best 5% of the models containing Year

Figure_4<- ggplot(df_long, aes(x = Variable, y = Importance)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.7) +  # Boxplot con transparencia y sin outliers
  geom_jitter(color = "#FF5733", width = 0.2, alpha = 0.5) +  # Puntos en azul
  geom_text(data = variable_counts, 
            aes(x = Variable, y = max(df_long$Importance, na.rm = TRUE) + 0.1, label = Count), 
            vjust = -0.5, color = "black") +  # Etiquetas en negro
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
  labs( x = "Variable", y = "Relative Importance")

ggsave("Olden_Boxplot_Year_best_5perc.svg", plot = Figure_4, width = 8, height = 6, units = "in")



# 10. Oldens boxplots, NO YEAR: Prepare data for oldens predictor importance for best 5% of the models **WITHOUT** Year

# Select variables with Olden for the best 5% of the models **WITHOUT** Year
ann_olden <- no_year_5perc %>%
  select(RMSE, Rsquared, Rank_R2, predictors, Olden) 

# Extract Olden from Predictors
df_sep <- ann_olden %>%
  separate_rows(Olden, sep = "; ") %>%
  separate(Olden, into = c("Predictor", "Value"), sep = ",") %>%
  mutate(Value = as.numeric(Value) )%>%
  pivot_wider(names_from = Predictor, values_from = Value) # this separates columns for each predictor

df_Olden_boxplots<- ann_olden %>% select(-Olden) %>% bind_cols(df_sep) 


# Reshape data to long format
df_long <- df_Olden_boxplots %>%
  pivot_longer(
    cols = c(NO3, Bacteria_DAPI, Abun_HNF, PO4, SiO4, NO2, Abun_PNF, Temperature, Synechococcus, Secchi_Disk, CHL, Prochlorococcus),
    names_to = "Variable",
    values_to = "Importance") %>% filter(!is.na(Importance)) 

# Counts of every predictor variable (for the upper part of the plot)
variable_counts <- df_long %>%
  group_by(Variable) %>%
  summarise(Count = n(), .groups = "drop")

# After doing counts, order the variables by the number of appearances
df_long <- df_long %>%
  mutate(Variable = factor(Variable, levels = variable_counts$Variable[order(-variable_counts$Count)]))



# 11. Figure 5: Olden's Importance of each predictor in all Best 5% of the models **WITHOUT** Year

Figure_5<- ggplot(df_long, aes(x = Variable, y = Importance)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.7) +  # Boxplot con transparencia y sin outliers
  geom_jitter(color = "#21908C", width = 0.2, alpha = 0.5) +  # Puntos en azul
  geom_text(data = variable_counts, 
            aes(x = Variable, y = max(df_long$Importance, na.rm = TRUE) + 0.1, label = Count), 
            vjust = -0.5, color = "black") +  # Etiquetas en negro
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
  labs( x = "Variable", y = "Relative Importance")

ggsave("Olden_Boxplot_NOYear_best_5perc.svg", plot = Figure_5, width = 8, height = 6, units = "in")










