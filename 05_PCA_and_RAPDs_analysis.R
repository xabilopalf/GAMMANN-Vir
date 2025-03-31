# 05_PCA_and_RAPDs_analysis.R


# 1. Load the necessary libraries and data
required = c("factoextra","tibble", "vegan", "ggplot2", "RColorBrewer", "viridis", "corrplot", "ggcorrplot", "cowplot")

for (i in required) {
  if (!require(i, character.only = T)) {
    install.packages(i, character.only = T)
  }
  library(i, character.only = T)
}

setwd()


data_ann<- read_excel("DADES_DV_tot.xlsx",  
                      sheet = "R_augmented_table",col_types = c("numeric", 
                                                                "text", "text", "text", "date", "text", 
                                                                "numeric", "numeric", "numeric", "numeric", 
                                                                "numeric", "numeric", "numeric", "numeric", 
                                                                "numeric", "numeric", "numeric", "numeric", 
                                                                "numeric", "numeric", "numeric", "numeric", 
                                                                "numeric", "numeric", "numeric", "numeric", 
                                                                "numeric", "numeric", "numeric", "numeric", 
                                                                "numeric"))
Aquí tienes el código con los comentarios en inglés:  
  

# 2. Data preparation
data_ann <- data_ann[which(data_ann$Year != 2023),]
data_ann <- data_ann[, c("Year", "Season", "Month", "TIME", "Temperature", "NO3", "PO4", "NO2", "SiO4", "CHL", 
                         "Bacteria_DAPI", "Prochlorococcus", "Synechococcus", "Abun_HNF", "Abun_PNF", "AbunVir", "Salinity", "Secchi_Disk")]
data_ann$Year <- as.numeric(data_ann$Year)

# Filter complete cases and set TIME as row names
pca_data <- data_ann[complete.cases(data_ann), ]
pca_data <- column_to_rownames(pca_data, var = "TIME")

# Create a separate environmental dataset
envs <- pca_data[, c("Year", "Season", "Month")]
envs$Year <- as.factor(envs$Year)


# 3. NMDS analysis
set.seed(123)
rapds.dist <- vegdist(pca_data, method = "bray", na.rm = TRUE)
nmds_result <- metaMDS(rapds.dist, trace = 1, trymax = 200)
nmds_coordinates <- as.data.frame(scores(nmds_result, display = "sites"))
nmds_coordinates$Year <- envs$Year
nmds_coordinates$Season <- envs$Season
nmds_coordinates$Month <- envs$Month

# NMDS visualization
nmds_plot <- ggplot(nmds_coordinates, aes(x = NMDS1, y = NMDS2, color = Year)) +
  geom_point(size = 3, aes(shape = Season)) + 
  geom_text(aes(label = Year), hjust = -0.15, vjust = -0.15) +
  labs(subtitle = paste("Stress =", format(round(nmds_result$stress, 3), nsmall = 3)),
       color = "Year", shape = "Season") +
  theme_minimal() +
  stat_ellipse(aes(group = Year, color = Year), level = 0.95, linetype = "dashed", size = 0.5) ; nmds_plot



# 4. RAPDs analysis

# setear working directory
setwd("~/Downloads/2024_Xabi/")

data_rapds <- read_excel("231218_MatriuRAPDs.xlsx", 
                    sheet = "YEAR_MONTHS_R1", col_types = c("skip", 
                                                            "numeric", "text", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric",  "numeric", "numeric", "numeric","numeric", "numeric", "numeric", "numeric", "numeric", "numeric",  "numeric", "numeric", "numeric","numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric",  "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric"))

# Prepare Data
rapds <- data_rapds[, 6:44]
data_rapds$Season[data_rapds$Season == "SU*"] <- "SU"



# In one take it will generate Jaccard distance disimilarity matrix and NMDS for each year individually and save it so we can access it later for plotting the NMDS
# First the list in which we will store the results
years <- 11:21
rapds.dist <- list()  # Lista para almacenar las matrices de distancia
trflp.mds <- list()   # Lista para almacenar los resultados de NMDS
Location <- list()    # Lista para almacenar las ubicaciones (Season) de cada año

# Loop through each year
for (year in years) {
  year_data <- data_rapds[data_rapds$Year == year, 6:44]
  rapds.dist[[as.character(year)]] <- vegdist(year_data, "jaccard") # generate Jaccard distance disimilarity matrix
  trflp.mds[[as.character(year)]] <- metaMDS(rapds.dist[[as.character(year)]], trace=1, trymax=200)
  
  Location[[as.character(year)]] <- as.factor(data_rapds$Season[data_rapds$Year == year]) # Location needed as factor for the NMDS
}


# Plot it!!

plots <- list() 

for (year in years) {
  # Obtain the coordinates (because of ggplot2 we need to extract thos values from the trflp.mds and Location )
  nmds_coordinates <- as.data.frame(scores(trflp.mds[[as.character(year)]], display = "sites"))
  nmds_coordinates$Location <- Location[[as.character(year)]]

  hull_data <- nmds_coordinates %>%
    group_by(Location) %>%
    slice(chull(NMDS1, NMDS2)) # Calculate the convex hull polygon by Location
  
  plot <- ggplot(nmds_coordinates, aes(x = NMDS1, y = NMDS2, color = Location)) +
    geom_point(size = 3, aes(shape = Location)) + 
    geom_polygon(data = hull_data, aes(x = NMDS1, y = NMDS2, fill = Location, color = NULL), alpha = 0.2) +
    scale_color_manual(values = c("W" = "cornflowerblue", "SP" = "chartreuse2", "SU" = "coral", "AU" = "gold1")) +
    scale_fill_manual(values = c("W" = "cornflowerblue", "SP" = "chartreuse2", "SU" = "coral", "AU" = "gold1")) +
    scale_shape_manual(values = c("W" = 19, "SP" = 19, "SU" = 19, "AU" = 19)) +
    labs(title = paste("NMDS ordination of RAPD data: Year 20",year),
         subtitle = paste("Stress =", format(round(trflp.mds[[as.character(year)]]$stress, 3), nsmall = 3)), 
         color = "Season", 
         shape = "Season",
         fill = "Season") +
    theme_minimal() +
    guides(color = "none")
  
  # Store
  plots[[as.character(year)]] <- plot
}


# EXAMPLE OF USE: It is done already, so just ask for the stored NMDS
plots[['13']]
plots[['14']]
plots[['15']]

# Save them all!

for (year in years) {
  file_name <- paste0("NMDS_Year_20", year, ".svg")
  ggsave(file_name, plot = plots[[as.character(year)]], width = 8, height = 6)
}

