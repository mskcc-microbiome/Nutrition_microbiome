library(vegan)
library(tidyverse)
library(stats)
library(ggplot2)


#Helper Function that removes highly correlated variables first:
remove_highly_correlated <- function(df, threshold = 0.95){
  

  numeric_df <- df %>%
    #mutate(across(where(is.factor), ~ as.numeric(levels(.x))[.x])) %>%
    select_if(is.numeric)
  
  if (length(colnames(numeric_df)) < 2){
    print("There were fewer than 2 numeric columns in the provided covariates.  Returning.")
    return(df)
  }
  
  abs_cor_matrix <- cor(numeric_df, use = "pairwise.complete.obs") %>%
    abs()
  
  #drop any rows or columsn that are all NA:
  abs_cor_matrix <- abs_cor_matrix[rowSums(is.na(abs_cor_matrix)) != ncol(abs_cor_matrix), ]
  abs_cor_matrix <- abs_cor_matrix[, colSums(is.na(abs_cor_matrix)) != nrow(abs_cor_matrix)]
  
  variables_to_remove <- c()

  for (i in 1:(ncol(abs_cor_matrix) - 1)) {
    for (j in (i + 1):ncol(abs_cor_matrix)) {
      var1 <- colnames(abs_cor_matrix)[i]
      var2 <- colnames(abs_cor_matrix)[j]
      
      if (!(var1 %in% variables_to_remove) && !(var2 %in% variables_to_remove)) {
        
        if (abs_cor_matrix[var1, var2] > threshold) {
          
          if (sample(c(TRUE, FALSE), 1)) {
            variables_to_remove <- c(variables_to_remove, var1)
          } else {
            variables_to_remove <- c(variables_to_remove, var2)
          }
        }
      }
    }
  }
  if (length(variables_to_remove) > 0){
    print(paste("Removing", variables_to_remove))
    return(select(df, -any_of(variables_to_remove)))
  }
  return(df)
}


#Find the covariates of interest using phyloseq.  Will use all covariates in the sample_data of the phyloseq:
# Essentially just a helper function to make the code work for a phyloseq object.
find_covariates_using_phyloseq <- function(phyloseq_obj, perms = 10000, distance_metric = "bray", na_drop = T, threshold = 0.05){
  distance_mat <- as.matrix(vegdist(t(phyloseq_obj@otu_table), method = distance_metric))

  # cast as a tibble then dataframe to preserve types of columns (but lost rownames)
 cov_df <- sample_data(phyloseq_obj) %>% 
    as.tibble() %>% 
    as.data.frame() %>%
   mutate(row_n_match_up = row_number())
  
 #sketchy things to add the row/sample name in:
  sample_names <- sample_data(phyloseq_obj) %>% 
    as.matrix() %>% 
    as.data.frame() %>%
    rownames_to_column("Sample") %>%
    mutate(row_n_match_up = row_number()) %>%
    select(c(Sample, row_n_match_up))
  
  cov_df <- inner_join(cov_df, sample_names) %>% 
    filter(Sample %in% colnames(distance_mat)) %>%
    column_to_rownames("Sample") %>%
    select(-row_n_match_up) 
  
  if (na_drop){
    #drop the rows with NA in cov_df
    cov_df <- na.omit(cov_df)
    # make sure distance mat matches the same columns
    distance_mat <- distance_mat [rownames(distance_mat ) %in% rownames(cov_df),
                                  colnames(distance_mat ) %in% rownames(cov_df)]
  }
  
  return(find_covariates_using_covariates_matrix_and_dist_mat(distance_mat, cov_df, perms = perms, threshold = threshold))
}

#Find the covariates of interest using only distance matrix and provided covariate dataframe. 
find_covariates_using_covariates_matrix_and_dist_mat <- function(distance_mat, cov_df, perms = 10000, subset_to_match = F, threshold = 0.05){
  
  if (subset_to_match){
    distance_mat <- distance_mat [rownames(distance_mat ) %in% rownames(cov_df),
                                  colnames(distance_mat ) %in% rownames(cov_df)]
    cov_df <- rownames_to_column("Sample") %>% 
      filter(Sample %in% colnames(distance_mat)) %>%
      column_to_rownames("Sample")
    
  }
  if (!(nrow(distance_mat) == nrow(cov_df))){
    stop("Distance mat and provided covariates don't have the same number of dimensions, fix cov mat, ensure row names are sample ids.  Can rerun with subset_to_match=T to force cov_df and distance_mat to have same samples")
  }
  minimal_cov_df <- remove_highly_correlated(cov_df)
  
  cov <- vegan::envfit(ord=as.data.frame(distance_mat), env=minimal_cov_df, permutation = perms)
  effect_size <- cov$vectors$r
  pval <- cov$vectors$pval
  
  #Note you would want to change the code to add any category specific colors here:
  return(data.frame(effect_size, pval) %>%
    rownames_to_column("variable_name") %>%
    mutate(variable_name = stringr::str_replace_all(variable_name, '_', ' ')) %>%
    mutate(adjusted_pval = p.adjust(pval, method = "BH"),
           significant = adjusted_pval < threshold))
}


#-------------------------------------------------------------------------------------------------------------------
# Examples of how to use:


# test_phyloseq <- readRDS("your_path_to_your_phyloseq")
# test_covariates_of_interest <- readRDS("your_path_to_your_covaraites_dataframe")
# threshold = 0.05
# # This will run on all the covariates in the sample_data frame of the phyloseq provided:
# plotting_data_frame <- find_covariates_using_phyloseq(test_phyloseq, perms = 10000)

# # As an alternative this will only run on the covariates provided in your matrix.:
# #plotting_data_frame <- find_covariates_using_covariates_matrix_and_dist_mat(
# #  as.matrix(vegdist(t(phyloseq_obj@otu_table), method = "bray")),
# #  test_covariates_of_interest, perms = 10000)



# plotting_data_frame %>%
#   filter(significant) %>%
#   mutate(  # Modify me to define your categories of interest! :) 
#     variable_category = case_when(
#       variable_name %in% c("BMI", "Cholesterol") ~ "Patient Health Stats",
#       variable_name %in% c("Bristol Score") ~ "Stool Specific Parameters",
#       .default = "Other"
#     )
#   ) %>%
#   ggplot(aes(y = forcats::fct_reorder(variable_name, effect_size), x = effect_size, fill = variable_category)) +
#   geom_col() + 
#   theme_classic() +
#   labs(title = "",
#        x = "Effect Size",
#        y = paste0("FDR Signficant Covariate, p < ", threshold),
#        fill = "Covariate\nCategory")+
#   theme(
#     axis.text = element_text(size = 24), # Adjust axis labels
#     axis.title = element_text(size = 24), # Adjust axis titles
#     plot.title = element_text(size = 24),  # Adjust plot title
#     strip.text.x = element_text(size = 20),
#     legend.text = element_text(size = 15),
#     legend.title  = element_text(size = 20),
#     strip.text.y = element_text(size = 20)
#   ) 

#-----------------------------------------------------------------------------------------------------------------

