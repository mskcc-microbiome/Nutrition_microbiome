library(vegan)
library(tidyverse)
library(ggplot2)
library(rstudioapi) 

# get the path of this script, if the following code breaks for you, can hardcode pathdir to the directory where you have saved this file.
if (rstudioapi::isAvailable()) {
  # we assume the most common use case is running this document in R studio:
  proj_home <- dirname(dirname(rstudioapi::getActiveDocumentContext()$path))
  }else if(sys.nframe() > 0){
  if(is.null(sys.frame(1)$ofile)){
    proj_home <- dirname(dirname(sys.frame(1)$ofile))
  }
  }else{
    # Fall back on current wd if not in Rstudio
    proj_homer = getwd()
  }


source(paste0(proj_home, "/functions/identify_covariates.R"))

#-------------------------------------------------------------------------------------
# Load and Prep data:

otu_table <- read.csv(paste0(proj_home, "/data/R25_asv_counts.csv")) %>%
  select(-count_relative) %>%
  pivot_wider(values_from = "count", names_from = "sampleid") %>%
  column_to_rownames("asv_key") 
otu_table[is.na(otu_table)] <- 0
dist_mat <- as.matrix(vegdist(t(otu_table), method = "bray"))


metadata <- read.csv(paste0(proj_home, "/data/153_combined_META.csv"))

# make sure sample order is the same:
reorder_indices <- match(rownames(dist_mat), metadata$sampleid)
metadata <- metadata[reorder_indices,] %>%
  remove_rownames() %>%
  column_to_rownames("sampleid")

threshold = 0.05
plotting_data_frame <- find_covariates_using_covariates_matrix_and_dist_mat(dist_mat, metadata, threshold = threshold, perms = 10000)

plotting_data_frame %>%
   filter(significant) %>%
   mutate(  # Modify me to define your categories of interest! :) 
     variable_category = case_when(
       grepl("fg", variable_name) ~ "Dietary Data",
       variable_name %in% c("simpson reciprocal") ~ "Stool Diversity\n(lol should\nremove this,\nleaving for\ndemo purposes)",
       .default = "Other"
     )
   ) %>%
   ggplot(aes(y = forcats::fct_reorder(variable_name, effect_size), x = effect_size, fill = variable_category)) +
   geom_col() + 
   theme_classic() +
   labs(title = "",
        x = "Effect Size",
        y = paste0("FDR Signficant Covariate, p < ", threshold),
        fill = "Covariate\nCategory")+
   theme(
     axis.text = element_text(size = 24), # Adjust axis labels
     axis.title = element_text(size = 24), # Adjust axis titles
     plot.title = element_text(size = 24),  # Adjust plot title
     strip.text.x = element_text(size = 20),
     legend.text = element_text(size = 15),
     legend.title  = element_text(size = 20),
     strip.text.y = element_text(size = 20)
   ) 

                  