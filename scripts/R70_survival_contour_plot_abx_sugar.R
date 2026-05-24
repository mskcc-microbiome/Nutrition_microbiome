library(tidyverse)
library(survival)
library(gtsummary)
library(splines)
library(patchwork)
library(RColorBrewer)
library(cowplot)
library(ggnewscale)
library(ggpattern)  
library(sf)
library(stars)

df_use <- readRDS("data\\R09_df_main_for_nutrition_clinical_outcome.RDS")


fit <- coxph(Surv(OStime_30, OSevent) ~ ns(avg_sugar_density_per_1000kcal,
                                           knots = quantile(df_use$avg_sugar_density_per_1000kcal,
                                                            probs = c(0.1, 0.9))) * day_exposed + source_and_gvhdppx + intensity,
             data = df_use |> filter(OStime_30 > 0))

exposure_seq <- seq(0, 20, length.out = 100)
sugar_seq <- seq(23, 150, length.out = 100)

grid_df <- expand.grid(
  day_exposed = exposure_seq,
  avg_sugar_density_per_1000kcal = sugar_seq,
  source_and_gvhdppx = "TCD+TCD",
  intensity = "nonablative"
)

pred <- predict(fit, newdata = grid_df, type = "lp", se.fit = TRUE)
grid_df$lp <- pred$fit
grid_df$se <- pred$se.fit

# Convert to HR scale for confidence intervals and significance testing
grid_df$hr <- exp(grid_df$lp)
grid_df$hr_lower <- exp(grid_df$lp - 1.96 * grid_df$se)
grid_df$hr_upper <- exp(grid_df$lp + 1.96 * grid_df$se)

# Update significance testing to use HR scale (HR = 1 is null)
grid_df$significant <- with(grid_df,
                            ifelse(hr_lower > 1, "Significantly > 1",
                                   ifelse(hr_upper < 1, "Significantly < 1", "Not significant"))
)

x_min <- min(exposure_seq)
x_max <- max(exposure_seq)
y_min <- min(sugar_seq)
y_max <- max(sugar_seq)

#make custom palette (such that HR = 1 is the center at white)
hr_range <- range(grid_df$hr)
max_hr <- max(hr_range)
min_hr <- min(hr_range)

# Create breaks that are symmetric in log space around HR = 1
# and ensure HR = 1 is in the center of the middle bin
n_bins <- 13
half_bins <- n_bins / 2

# Define the width of the central white bin (in log space)
central_bin_log_width <- 0.5  # Adjust this to make white bin wider/narrower

# Create symmetric log breaks
log_min <- log(min_hr)
log_max <- log(max_hr)
max_log_extent <- max(abs(log_min), abs(log_max))

# Create breaks for one side
log_breaks_positive <- seq(central_bin_log_width/2, max_log_extent, length.out = half_bins + 1)
log_breaks_negative <- -rev(log_breaks_positive)

# Combine all breaks
all_log_breaks <- c(log_breaks_negative, log_breaks_positive)
symmetric_breaks <- exp(all_log_breaks)

# Color palette
n_colors_per_side <- half_bins
blues <- colorRampPalette(c("#DEEBF7", "#9ECAE1","#3182BD","#08519C"))(n_colors_per_side-1)
reds <- colorRampPalette(c("#FEE0D2","#FC9272","#DE2D26", "#A50F15"))(n_colors_per_side)
custom_palette <- c(rev(blues), "white", reds)

#make the polygons of significance:

sig_harmful <- grid_df %>% filter(significant == "Significantly > 1")  # HR > 1
# Note there are 2 harmful regions, to make plotting easier we split this into 2 groups
sig_harmful_high_s <- sig_harmful %>% filter(avg_sugar_density_per_1000kcal > 50)
sig_harmful_low_s <- sig_harmful %>% filter(avg_sugar_density_per_1000kcal < 50)

sig_harm_blob_high_s <- st_as_stars(sig_harmful_high_s,
                                    coords = c("day_exposed", "avg_sugar_density_per_1000kcal"))
sig_harm_polygon_high_s <- st_as_sf(sig_harm_blob_high_s, as_points = FALSE, merge = TRUE) %>%
  st_cast("POLYGON")

sig_harm_blob_low_s <- st_as_stars(sig_harmful_low_s,
                                   coords = c("day_exposed", "avg_sugar_density_per_1000kcal"))
sig_harm_polygon_low_s <- st_as_sf(sig_harm_blob_low_s, as_points = FALSE, merge = TRUE) %>%
  st_cast("POLYGON")

sig_protective <- grid_df %>% filter(significant == "Significantly < 1")  # HR < 1
sig_p_blob <- st_as_stars(sig_protective,
                          coords = c("day_exposed", "avg_sugar_density_per_1000kcal"))
sig_p_polygon <- st_as_sf(sig_p_blob, as_points = FALSE, merge = TRUE)


#make main plt: (adds polygon hatched regions:)
p_main_with_legend <- ggplot(grid_df,
                             aes(x = day_exposed,
                                 y = avg_sugar_density_per_1000kcal)) +
  geom_contour_filled(aes(z = hr), breaks = symmetric_breaks) +  # Use symmetric breaks
  scale_fill_manual(
    name   = "Contours of\nHazard ratio",  
    values = custom_palette
  )+
    geom_sf_pattern(data = sig_harm_polygon_high_s,
                    inherit.aes = FALSE,
                    fill = NA,
                    color = NA,
                    pattern = "stripe",
                    pattern_colour = NA,
                    pattern_fill = "grey60",
                    pattern_density = 0.3,
                    pattern_spacing = 0.02,
                    pattern_angle = 45,
                    pattern_alpha = 1)+
    geom_sf_pattern(data = sig_harm_polygon_low_s,
                    inherit.aes = FALSE,
                    fill = NA,
                    color = NA,
                    pattern = "stripe",
                    pattern_colour = NA,
                    pattern_fill = "grey60",
                    pattern_density = 0.3,
                    pattern_spacing = 0.02,
                    pattern_angle = 45,
                    pattern_alpha = 1) +
    geom_sf_pattern(data = sig_p_polygon,
                    inherit.aes = FALSE,
                    fill = NA,
                    color = NA,
                    pattern = "stripe",
                    pattern_colour = NA,
                    pattern_fill = "grey60",
                    pattern_density = 0.3,
                    pattern_spacing = 0.02,
                    pattern_angle = -45,
                    pattern_alpha = 1) +
  geom_contour(aes(z = hr),
               breaks = 1,        
               color = "grey80",
               size = .75,
               alpha = 0.5,
               linetype = 2) +
  geom_segment(y = median(df_use$avg_sugar_density_per_1000kcal),
               x = 0,
               xend = 20, color="grey") +
  labs(x = "Days of broad-spectrum antibiotics exposure",
       y = "Average grams of sugar intake\nper 1000Kcal between day -7 and day 12") +
  scale_x_continuous(limits = c(x_min, x_max), expand = c(0, 0)) +
  scale_y_continuous(limits = c(y_min, y_max), expand = c(0, 0)) +
  guides(fill = guide_legend(reverse = TRUE)) +  # This reverses ONLY the legend order
  theme_classic(base_size = 7) +
  theme(
    legend.position = "right",
    aspect.ratio = 1,
    axis.text = element_text(),
    axis.ticks = element_line()
  ) +
  coord_sf(expand = FALSE, xlim = c(x_min, x_max),
           ylim = c(y_min, y_max))

#print(p_main_with_legend)


# countour legend
contour_legend <- cowplot::get_legend(p_main_with_legend)

# Main plot without legend
p_main <- p_main_with_legend +
  theme(legend.position = "none",
        plot.margin = margin(2, 2, 2, 2))

# x axis histogram -> top
p_top <- ggplot(df_use, aes(x = day_exposed)) +
  geom_histogram(binwidth = 1,
                 boundary = 0,
                 fill = "grey70", color = NA, alpha = 0.5) +
  scale_x_continuous(limits = c(x_min, x_max), expand = c(0, 0)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(x = NULL, y = NULL) +
  theme_classic(base_size = 7) +
  theme(
    axis.text.y = element_text(),     
    axis.text.x = element_blank(),     
    axis.ticks.y = element_line(),     
    axis.ticks.x = element_blank(),    
    axis.line.y = element_line(),      
    axis.line.x = element_blank(),     
    plot.margin = margin(2, 0, 2, 0)
  )

# x axis histogram -> right
p_right <- ggplot(df_use, aes(x = avg_sugar_density_per_1000kcal)) +
  geom_histogram(bins = 40, fill = "grey70", color = NA, alpha = 0.5) +
  scale_x_continuous(limits = c(y_min, y_max), expand = c(0, 0)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.25))) +
  coord_flip() +
  labs(x = NULL, y = NULL) +
  theme_classic(base_size = 7) +
  theme(
    axis.text.x = element_text(),     
    axis.text.y = element_blank(),     
    axis.ticks.x = element_line(),     
    axis.ticks.y = element_blank(),    
    axis.line.x = element_line(),      
    axis.line.y = element_blank(),     
    plot.margin = margin(2, 0, 2, 0)
  )

#custom legend for hatching
hatch_legend_df <- data.frame(
  x = c(0, 0),
  y = c(2, 1),
  label = c("Significantly\nhigh mortality risk\n(p<0.05)",
            "Significantly\nlow mortality risk (p<0.05)"),
  pattern_angle = c(45, -45),
  pattern_colour = c("black", "black")
)

p_hatch_legend <- ggplot() +
  # Harmful hatching swatch
  geom_tile_pattern(
    aes(x = 0, y = 2),
    width = 0.2, height = 0.4,
    fill = NA, color = NA,
    pattern = "stripe",
    pattern_color= NA,
    pattern_fill = "black",
    pattern_density = 0.3,
    pattern_spacing = 0.02,
    pattern_angle = 45,
    pattern_alpha = 1
  ) +
  annotate("text", x = 0.2, y = 2,
           label = "Significantly\nharmful (p<0.05)",
           hjust = 0, size = 2) +
  # Protective hatching swatch
  geom_tile_pattern(
    aes(x = 0, y = 1),
    width = 0.2, height = 0.4,
    fill = NA, color = NA,
    pattern = "stripe",
    pattern_color= NA,
    pattern_fill = "black",
    pattern_density = 0.3,
    pattern_spacing = 0.02,
    pattern_angle = -45,
    pattern_alpha = 1
  ) +
  annotate("text", x = 0.2, y = 1,
           label = "Significantly\nprotective (p<0.05)",
           hjust = 0, size = 2) +
  xlim(-0.2, 1.5) + ylim(0.5, 2.5) +
  theme_void() +
  theme(plot.margin = margin(0, 0, 0, 0))

#combine legends
p_legends <- (wrap_elements(contour_legend) / p_hatch_legend) +
  plot_layout(heights = c(2, 1))

combined <- (p_top + plot_spacer() + plot_spacer() +
               p_main + p_right + p_legends) +
  plot_layout(
    ncol    = 3,
    nrow    = 2,
    widths  = c(5, 0.8, 1.5),
    heights = c(0.8, 5)
  ) + 
  theme(aspect.ratio = 1)

print(combined)
#ggsave("results/2d_countour_plot_abx_sugar.svg", combined)

