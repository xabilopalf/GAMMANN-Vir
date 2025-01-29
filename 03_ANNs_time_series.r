library(readxl)
library(NeuralNetTools)
library(nnet)
library(caret)

data_ann<- read_excel("DADES_DV_tot.xlsx", sheet = "R_augmented_table",col_types = c("numeric", "numeric", "text", "text", "date", "text", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric",  "numeric"))

#data_ann <- data_ann %>% filter(Year != 2023) # we don't want data for 2023
data_ann <- data_ann[which(data_ann$Year != 2023),] # we don't want data for 2023

#Generate three datasets
data_ann_full <-data_ann
data_ann_pre12<-data_ann[which(data_ann$Year <= 2012),]
data_ann_post12<-data_ann[which(data_ann$Year > 2012),]

data_ann_log<-data_ann
data_ann_log$AbunVir<-log10(data_ann_log$AbunVir) 
data_ann_log$Bacteria_DAPI<-log10(data_ann_log$Bacteria_DAPI) 

dset_list<-list(data_ann_log)#,data_ann_full)#,data_ann_pre12,data_ann_post12)

names(dset_list)<-c("log")#,"full")#,"pre12","post12")

#custom function to z transform a dataframe and save the column means and standard deviations to use for transforming future data
z_transform<-function(in_df,col_means=c(),col_sds=c()) {
  if (length(col_means) == 0) {
    print("Calculating column means and standard deviations")
    col_means<-colMeans(in_df,na.rm=TRUE)
    names(col_means)<-colnames(in_df)
    col_sds<-apply(in_df,2,sd,na.rm=TRUE)
    names(col_sds)<-colnames(in_df)
  } else {
    print("Using provided column means and standard deviations")
  }
  out_df<-in_df
  #subtract the mean from each column and divide by the standard deviation
  for (var_name in colnames(in_df)) {
    out_df[[var_name]]<-(out_df[[var_name]]-col_means[[var_name]])/col_sds[[var_name]]
  }
  return(list(out_df,col_means,col_sds))
}


###Parallel processing
library(doParallel)
cl <- makePSOCKcluster(24)
registerDoParallel(cl)
for (dset_num in  1:length(dset_list)) {
  dset_name<-names(dset_list)[dset_num]
  print(paste("Running dataset ",dset_name))
  data_ann_num<-dset_list[[dset_num]]
  
  data_ann_num<-data_ann_num[,c("Month","Year","Temperature","Secchi_Disk","NO3","PO4","NO2","SiO4","CHL","AbunVir","Bacteria_DAPI","Prochlorococcus","Synechococcus","Abun_HNF","Abun_PNF")]
  
  #df_zscale <- as.data.frame(scale(data_ann_num, center = T)) # z-scale the data
  zdf_n_stats<-z_transform(data_ann_num)
  df_zscale<-as.data.frame(zdf_n_stats[[1]])
  odf_col_means<-zdf_n_stats[[2]]
  odf_col_sds<-zdf_n_stats[[3]]
  
  summary(df_zscale)
  
  possible_predictors<-c("Temperature","Secchi_Disk","NO3","PO4","NO2","SiO4","CHL","Bacteria_DAPI","Prochlorococcus","Synechococcus","Abun_HNF","Abun_PNF","Year")
  
  all_pred_var_comb <- list()
  
  for (pred_var_num in 4:5) {
    # Obtener todas las combinaciones posibles de longitud i con AbunVir incluida
    pred_var_combs <- combn(possible_predictors, pred_var_num , simplify = FALSE, collapse = ",")
    all_pred_var_comb <- c(all_pred_var_comb, pred_var_combs)
  }
  
  #hpt_Grid <- expand.grid(predictors =(all_pred_var_comb), maxit=c(5,10,25,50,100,200,500,1000), abstol=c(1E-1,1E-2,1E-3,1E-4,1E-5,1E-6),reltol=c(1E-1,1E-2,1E-3,1E-4,1E-5,1E-6,1E-7,1E-8,1E-9,1E-10))
  
  hpt_Grid <- expand.grid(predictors = all_pred_var_comb, maxit=c(10,50,100), abstol=c(1E-4),reltol=c(1E-8))
  
  hpt_Grid$hpt_comb_num<-1:nrow(hpt_Grid)
  
  #ann_Grid <- expand.grid(size = c(1:5), decay = c(0, 0.1, 1))
  ann_Grid <- expand.grid(size = c(2:3),decay = c(0))
  
  ###HPT tuning with Caret
  fitControl <- trainControl(method = "LGOCV", number = 5, p = 0.8)
  
  full_fit_results<-rbind()
  for (hpt_comb_num in 1:nrow(hpt_Grid)) {
    #for (hpt_comb_num in 1:100) {
    if (hpt_comb_num %% 1000 == 0) {
      print(paste("Running hpt combination ",hpt_comb_num))
    }
    predictors<-hpt_Grid$predictors[[hpt_comb_num]]
    
    subdata<-df_zscale[,c("AbunVir",predictors)]
    subdata<-subdata[complete.cases(subdata),]
    
    formula <- as.formula(paste("AbunVir ~", paste(predictors, collapse = "+")))
    
    set.seed(666)
    ann_fit <- train(formula , data = subdata, method = "nnet", trControl = fitControl, preProcess=NULL, verbose = FALSE, tuneGrid = ann_Grid, linout = TRUE, trace = FALSE, maxit=hpt_Grid[hpt_comb_num,"maxit"], abstol=hpt_Grid[hpt_comb_num,"abstol"], reltol=hpt_Grid[hpt_comb_num,"reltol"])
    fit_results<-ann_fit$results
    fit_results$hpt_comb_num<-hpt_comb_num
    
    
    # Calculate Olden importance
    best_net <- ann_fit$finalModel
    importance_olden <- olden(best_net, bar_plot = FALSE)
    importance_olden$Relative_Importance <- importance_olden$importance / sum(abs(importance_olden$importance))
    
    # Format Olden importance as a string
    importance_str <- paste0(row.names(importance_olden), 
                             ",", 
                             round(importance_olden$Relative_Importance, 2), 
                             collapse = "; ")
    
    # Add Olden importance to fit_results
    fit_results$Olden <- importance_str
    
    full_fit_results<-rbind(full_fit_results,fit_results)
  }
  
  #only seen to be able to make the functions below do what I want using this weird syntax
  full_fit_results$Rank_R2<-rank(full_fit_results$Rsquared*-1)
  full_fit_results$Rank_RMSE<-rank(full_fit_results$RMSE)
  
  hpt_Grid$predictors<-unlist(lapply(hpt_Grid$predictors, function(x) paste(unique(x), collapse = ',')))
  
  full_fit_results<-merge(full_fit_results,hpt_Grid,by="hpt_comb_num",all.x=TRUE)
  
  outfile_name<-paste(dset_name,"_Blanes_ANN_Fit_Metrics.tsv",sep="")
  
  write.table(full_fit_results, file = outfile_name, row.names = FALSE, col.names = TRUE, sep = "\t")
  
}
stopCluster(cl)


###Fit final network with best predictors and HP
#df_zscale <- as.data.frame(scale(subset(data_ann_log,select=c(AbunVir,PO4, Bacteria_DAPI,Abun_HNF,Year)), center = T)) # z-scale the data
data_ann_num<-subset(data_ann_num,select=c(AbunVir, PO4 ,Bacteria_DAPI,Abun_HNF, Year))
data_ann_num<-data_ann_num[complete.cases(data_ann_num),]
zdf_n_stats<-z_transform(data_ann_num)
df_zscale<-as.data.frame(zdf_n_stats[[1]])
odf_col_means<-zdf_n_stats[[2]]
odf_col_sds<-zdf_n_stats[[3]]

summary(df_zscale)

set.seed(666)

best_net<-nnet(AbunVir ~ PO4 + Bacteria_DAPI + Abun_HNF + Year, data = df_zscale, size = 2, decay = 0, linout = TRUE, maxit = 50, abstol = 0.0001, reltol = 0.00000001)

postResample(best_net$fitted.values, df_zscale$AbunVir)

#Add the predicted values to the z-scaled data df
df_zscale$ZPredicted_AbunVir<-best_net$fitted.values[,1]

#Add the reverse transformed predicted values to the original data df
data_ann_num$Predicted_AbunVir<-(df_zscale$ZPredicted_AbunVir*odf_col_sds["AbunVir"])+odf_col_means["AbunVir"]

library(NeuralNetTools)

#Calculate the importance of the predictors using the Olden method
importance_olden<-olden(best_net,bar_plot=FALSE)

#Look at the outpt and identify the most important predictor
importance_olden$Relative_Importance<-importance_olden$importance/sum(abs(importance_olden$importance))
