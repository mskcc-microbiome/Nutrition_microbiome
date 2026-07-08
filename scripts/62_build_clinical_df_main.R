# Build the merged clinical-outcome analysis table (df_main).
#
# Cleaning step for the Fig 3 / E6 clinical-outcome family. Joins three pieces into
# one downstream table:
#   1. per-patient sugar-density summary, recomputed from the diet table
#      (152_combined_DTB.csv) over the day -7..12 window -- this is the
#      R09_df_main_for_nutrition_clinical_outcome.RDS
#   2. the cleaned clinical-outcome table (R02_cleaned_clinical_outcome.rds:
#      survival times/events, transplant covariates, diet-pattern cluster)
#   3. hospital length of stay (003_combined_PTB_pid_updated.csv) and neutrophil
#      engraftment day (085_engraftment_day_annot.csv)
#
# Inputs live in ../data (run from the scripts/ folder). Output:
# ../data/df_main_clinical_outcome.rds -- the single table the downstream Fig 3 /
# E6 / supplementary-table analysis reads.

library(tidyverse)

# Cleaned clinical table, with the R09 recodes: cluster relabel, intensity order,
# the graft-source x gvhd-prophylaxis factor, and the diet x abx-exposure label.
clinical <- read_rds("../data/R02_cleaned_clinical_outcome.rds") |>
  mutate(modal_diet = fct_recode(modal_diet,
                                 "Cluster 1" = "Low intake",
                                 "Cluster 2" = "High intake")) |>
  mutate(intensity = factor(intensity, levels = c("nonablative", "reduced", "ablative"))) |>
  mutate(source_and_gvhdppx = str_glue("{source}+{gvhd_ppx}"),
         source_and_gvhdppx = factor(source_and_gvhdppx,
                                     levels = c("TCD+TCD", "Cord+CNI-based",
                                                "Unmodified+CNI-based", "Unmodified+PTCy-based")),
         day_exposed_cat = factor(day_exposed_cat,
                                  levels = c("Short exposure (< 8 days)", "Long exposure (>= 8 days)"))) |>
  mutate(day_exposed_cat = str_replace(day_exposed_cat, " \\(.+\\)", "")) |>
  mutate(abx_diet_cat = str_glue("{modal_diet}, {day_exposed_cat}"))

# Per-patient sugar-density summary from the diet table. Daily totals first, then
# the day -7..12 peri-transplant window, then per-patient means. daily_sugar_density
# is grams of sugar per 1000 kcal (0 on days with no calories).
dtb <- read_csv("../data/152_combined_DTB.csv", show_col_types = FALSE)

daily_intake <- dtb |>
  group_by(pid, fdrt) |>
  summarise(total_caloric_intake = sum(Calories_kcal, na.rm = TRUE),
            sugar_intake_grams   = sum(Sugars_g, na.rm = TRUE), .groups = "drop")

sugar_summary <- daily_intake |>
  filter(fdrt >= -7 & fdrt <= 12) |>
  mutate(daily_sugar_density = if_else(total_caloric_intake > 0,
                                       sugar_intake_grams / (total_caloric_intake / 1000), 0)) |>
  group_by(pid) |>
  summarise(avg_sugar_daily_intake_gram    = mean(sugar_intake_grams, na.rm = TRUE),
            avg_sugar_density_per_1000kcal  = mean(daily_sugar_density, na.rm = TRUE),
            avg_total_caloric_intake        = mean(total_caloric_intake, na.rm = TRUE), .groups = "drop")

# R09_df_main RDS: the sugar summary carrying the clinical columns the sugar models
# use, plus the above/below-median sugar-density split (median over the cohort).
r09_df_main <- sugar_summary |>
  inner_join(clinical |> select(pid, OStime_30, OSevent, intensity, source_and_gvhdppx,
                                day_exposed, source, gvhd_ppx, age, sex, Disease = disease.simple),
             by = "pid") |>
  mutate(SugarCal_cat_high = if_else(
           avg_sugar_density_per_1000kcal > median(avg_sugar_density_per_1000kcal, na.rm = TRUE),
           "Above-median", "Below-median"),
         SugarCal_cat_high = factor(SugarCal_cat_high, levels = c("Above-median", "Below-median")))

write_rds(r09_df_main, "../data/R09_df_main_for_nutrition_clinical_outcome.RDS")

# Hospital length of stay (003_combined_PTB) and neutrophil engraftment day (085).
los <- read_csv("../data/003_combined_PTB_pid_updated.csv", show_col_types = FALSE) |>
  select(pid, leng_of_stay)
engraft <- read_csv("../data/085_engraftment_day_annot.csv", show_col_types = FALSE) |>
  select(pid, engraftment_day)

# Merged df_main: the full clinical table plus the three sugar summary columns, the
# sugar-density split, length of stay, and engraftment day.
df_main <- clinical |>
  inner_join(r09_df_main |> select(pid, avg_sugar_daily_intake_gram,
                                   avg_sugar_density_per_1000kcal, avg_total_caloric_intake),
             by = "pid") |>
  left_join(los, by = "pid") |>
  left_join(engraft, by = "pid") |>
  mutate(SugarCal_cat_high = if_else(
           avg_sugar_density_per_1000kcal > median(avg_sugar_density_per_1000kcal, na.rm = TRUE),
           "Above-median", "Below-median"),
         SugarCal_cat_high = factor(SugarCal_cat_high, levels = c("Above-median", "Below-median")))

write_rds(df_main, "../data/df_main_clinical_outcome.rds")

# Also drop a CSV copy for easy column inspection (difftime cols -> numeric).
df_main |>
  mutate(across(where(~ inherits(.x, "difftime")), as.numeric)) |>
  write_csv("../data/df_main_clinical_outcome.csv")

# Reproduction checks against the published group sizes.
message("df_main rows: ", nrow(df_main), " (expect 173)")
message("SugarCal split: ",
        paste(names(table(df_main$SugarCal_cat_high)), table(df_main$SugarCal_cat_high),
              sep = "=", collapse = ", "), " (expect Above-median=86, Below-median=87)")
message("Diet-pattern cluster: ",
        paste(levels(df_main$modal_diet), table(df_main$modal_diet),
              sep = "=", collapse = ", "), " (expect Cluster 1=114, Cluster 2=59)")
message("Wrote ../data/df_main_clinical_outcome.rds")
