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

clinical_cov <- readRDS(paste0(proj_home, "/data/R02_cleaned_clinical_outcome.rds")) %>%
  select(c(source,intensity, age, sex, disease.simple, modal_diet, pid))

metadata <- read.csv(paste0(proj_home, "/data/153_combined_META.csv")) %>% 
  select(c(sampleid, empirical, timebin, fg_egg, fg_fruit, fg_grain, fg_legume, fg_meat, fg_milk, fg_oils, fg_sweets, fg_veggie, TPN, EN, pid)) %>%
  left_join(clinical_cov, by = "pid") %>%
  select(-pid)
    

# make sure sample order is the same:
reorder_indices <- match(rownames(dist_mat), metadata$sampleid)
metadata <- metadata[reorder_indices,] %>%
  remove_rownames() %>%
  column_to_rownames("sampleid")

threshold = 0.05
factor_fit <- vegan::envfit(as.data.frame(dist_mat), metadata, perms=1000)
plotting_data_frame <- find_covariates_using_covariates_matrix_and_dist_mat(dist_mat, metadata, threshold = threshold, perms = 100)

plotting_data_frame %>%
   filter(significant) %>% 
  mutate(variable_name = case_when(
    variable_name == "timebin" ~ "Week Relative to Transplant",
    variable_name == "disease.simple" ~ "Disease (Broad Category)",
    variable_name == "empirical" ~ "ABX exposure (last 2 days)",
    variable_name == "modal diet" ~ "Dietary Pattern",
    variable_name == "source" ~ "Graft Source",
    variable_name == "intensity" ~ "Conditioning Intensity",
    variable_name == "EN" ~ "Enteral Nutrition",
    variable_name == "TPN" ~ "Total Parenteral Nutrition",
    variable_name == "sex" ~ "Sex",
    variable_name == "age" ~ "Age",
    .default = variable_name
  )
  ) %>%
   mutate(  # Modify me to define your categories of interest! :) 
     variable_category = case_when(
       grepl("fg", variable_name) ~ "Sample Level Dietary Data",
       variable_name %in% c("Enteral Nutrition", "Total Parenteral Nutrition") ~ "Sample Level Dietary Data",
       variable_name == "Dietary Pattern" ~ "Patient Level Dietary Data",
       variable_name %in% c("ABX exposure (last 2 days)", "Week Relative to Transplant") ~ "Sample Level Data",
       variable_name %in% c("Graft Source", "Conditioning Intensity", "Disease (Broad Category)", "Sex", "Age") ~ "Patient Clinical Cov",
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
     axis.text = element_text(size = 18), # Adjust axis labels
     axis.title = element_text(size = 24), # Adjust axis titles
     plot.title = element_text(size = 24),  # Adjust plot title
     strip.text.x = element_text(size = 20),
     legend.text = element_text(size = 15),
     legend.title  = element_text(size = 20),
     strip.text.y = element_text(size = 17)
   ) 

                  