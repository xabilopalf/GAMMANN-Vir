# 02_GAM_analysis.R


# 1. Load the necessary libraries

required = c("readxl","tidyverse", "ggplot2", "dplyr", "gratia")

for (i in required) {
  if (!require(i, character.only = T)) {
    install.packages(i, character.only = T)
  }
  library(i, character.only = T)
}

setwd()


# 2. Load data
data_gam <- read_excel("~/Desktop/FPI_Doctorado/04_Active_Projects/ANN-ts/ANNs_ts/DADES_DV_tot.xlsx",  
           sheet = "R_augmented_table",col_types = c("numeric", 
                                                     "text", "text", "text", "date", "text", 
                                                     "numeric", "numeric", "numeric", "numeric", 
                                                     "numeric", "numeric", "numeric", "numeric", 
                                                     "numeric", "numeric", "numeric", "numeric", 
                                                     "numeric", "numeric", "numeric", "numeric", 
                                                     "numeric", "numeric", "numeric", "numeric", 
                                                     "numeric", "numeric", "numeric", "numeric", 
                                                     "numeric"))
# 3. Filter the data to remove the year 2023
data_gam <- data_gam %>% filter(Year != 2023)

# 4. Remove rows with NA values in the DATE variable
df_gam <- data_gam %>% filter(!is.na(DATE)) 

# 5. Check missingness
aggr_plot <- aggr(df, col=c('navyblue','red'), numbers=TRUE, sortVars=TRUE, labels=names(df), cex.axis=.5, gap=3, ylab=c("Histogram of missing data","Pattern"))
vis_miss(df, show_perc = F) + coord_flip()
missmap(df)


# 6. Data preparation: create Days variable to have Autocorrelation in the GAM model
attach(df_gam)
df_gam$DATE <- as.Date(df_gam$DATE, "%Y/%m/%d") # formato de fecha en inglés
df_gam$Month <- as.numeric(format(df_gam$DATE,'%m')) # generar variable Mes
df_gam$Day1 <- rep(df_gam$DATE[1], nrow(df_gam)) # fecha inicial de la serie
df_gam$Days <- (interval(df_gam$Day1, df_gam$DATE) %/% days(1))+1 # generar variable Days
df_gam$Day1 <- NULL
df_gam$TIME <- NULL




# 7. Modelling the Viral Abundance GAM

# Fit the GAM model
gam_AbunVir<-gamm(AbunVir ~ s(Month, bs="cc") + s(Days, bs="cr", k=20) + ti(Month,Days, bs=c("cc","cr")), family=quasipoisson , correlation = corCAR1(form = ~ Days), data = df_gam)

# Check the model
plot(gam_AbunVir$gam, scale=0, scheme=1, pages=1)
draw(gam_AbunVir$gam)
summary(gam_AbunVir$gam)
par(mfrow=c(2,2))
gam.check(gam_AbunVir$gam, type="pearson")




# 8. Model the rest of the variables

### DISCLAIMER: They should be modeled individually to understand the Daygnostics of the models and see if they need to be adjusted or change some parameter such as the k smoothness value, change the type of family (Gaussian, Quasipoisson, ...) or know if to add the interaction between variables.

# Fit the models 
fit_gams <- function(data, variables) {
  library(mgcv)
  
  for (var in variables) {
    formula <- as.formula(paste(var, "~ s(Month, bs='cc') + s(Days, bs='cr')"))
        model <- gamm( formula, family = quasipoisson,  correlation = corCAR1(form = ~ Days), data = data)
    
    object_name <- paste0("gam_", var)
    assign(object_name, model, envir = .GlobalEnv)
  }
}

## Example
variables <- c("AbunVir", "Temperature", "Salinity") # Add the variables of interest
fit_gams(df_gam, variables)


# Plot the models!
gam_plots <- function(variables, save = FALSE, path = getwd()) {
  plot_list <- list()
  
  for (i in seq_along(variables)) {
    var_name <- variables[i]
    gam_name <- paste0("gam_", var_name)
    
    # Check if the GAM object exists in the GlobalEnv
    if (exists(gam_name, envir = .GlobalEnv)) {
      model <- get(gam_name, envir = .GlobalEnv)
      
      # Plot using the draw() function from the 'gratia' package
      p <- draw(model)
      
      plot_name <- paste0("plot_", gam_name)
      assign(plot_name, p, envir = .GlobalEnv)
      
      # If save is TRUE, save the plot as an SVG file
      if (save) {
        file_path <- file.path(path, paste0("GAMM_", var_name, ".svg"))
        ggsave(file_path, plot = p, width = 8, height = 6, units = "in", device = "svg")
        message("Saved: ", file_path)
      }
      plot_list[[plot_name]] <- p
    } else {
      message("Model not found: ", gam_name)
    }
  }
  
  # Return the list of plots
  return(plot_list)
}

## Example
variables <- c("AbunVir", "Temperature", "Salinity")
gam_plots(variables, save = F)




# 9. GAM for Viral Abundance vs. Inflection Point


# We will use the inflection point to divide the time series into two periods: pre-2012 and post-2012. We will then fit a GAM model to the viral abundance data, including the inflection point as a predictor variable. 
# It is a way of conditioning the Month factor by the so-called inflection point

attach(df_gam) 

df_gam$inflection <- ifelse(df_gam$Days <= 4000, "pre", "post")
df_gam$inflection <- as.factor(df_gam$inflection)


# we create both models. With and without the inflection point
gam_AbunVir<-gamm(AbunVir ~ s(Month, bs="cc") + s(Days, bs="cr"), family=quasipoisson , correlation = corCAR1(form = ~ Days), data = df_gam)

condicional_Abunvir_gam<-gamm(AbunVir ~ inflection + s(Month, by=inflection, bs="cc") + s(Days, bs="cr"), family=quasipoisson , correlation = corCAR1(form = ~ Days), data = df_gam)


# Model AIC with and without inflection point

AIC(gam_AbunVir$lme, condicional_Abunvir_gam$lme) 

# Plot it! And check residuals!! 

draw(condicional_Abunvir_gam)
summary(condicional_Abunvir_gam$gam)
par(mfrow=c(2,2))
gam.check(condicional_Abunvir_gam$gam, type="pearson")

par(mfrow=c(1,1))
plot_smooth(condicional_Abunvir_gam$gam, view = "Month",
            plot_all = "inflection",
            hide.label=TRUE,rm.ranef = F, transform=exp, 
            rug=F, ylab="Viral Abundance")



# 10. Partial GAMs

# Partial GAM for Viral Abundance vs Nutrients

mod_nutr<-gamm(AbunVir ~  s(PO4, bs = "cr") + s(NO2, bs = "cr") + s(NO3, bs = "cr"), family=quasipoisson , data = df_gam)

# plot it!
draw(mod_nutr$gam)
# and Diagnostics
summary(mod_nutr$gam)
par(mfrow=c(2,2))
gam.check(mod_nutr$gam, type="pearson")


# Partial GAM for Viral Abundance vs host

mod_host<-gamm(AbunVir~  s(Bacteria_DAPI, bs="cr") + s(Abun_HNF, bs = "cr")  + s(Abun_PNF, bs = "cr") + s(Prochlorococcus, bs = "cr") + s(Synechococcus, bs = "cr") , family=quasipoisson , data = df_gam)

# plot it!
draw(mod_host$gam)
# and Diagnostics
summary(mod_host$gam)
par(mfrow=c(2,2))
gam.check(mod_host$gam, type="pearson")


# Partial GAM for Viral Abundance vs env.variables

mod_var_fq<-gamm(AbunVir~   s(Temperature, bs="cr") + s(Secchi_Disk, bs="cr", k=20)+   s(CHL, bs="cr") +  s(Salinity, bs="cr") , family=quasipoisson , data = df_gam)

# plot it!
plot(mod_var_fq$gam, scale=0, scheme=1, pages=1)
# and Diagnostics
summary(mod_var_fq$gam)
par(mfrow=c(2,2))
gam.check(mod_var_fq$gam, type="pearson")



