library(ggplot2)
library(openxlsx)

get_all_plot_vars <- function(ggplot_obj) {
  all_mappings <- sapply(ggplot_obj$mapping, rlang::as_label)
  layer_mappings <- unlist(lapply(ggplot_obj$layers, function(l) {
    sapply(l$mapping, rlang::as_label)
  }))
  
  unique(c(all_mappings, layer_mappings))
}


get_raw_vars <- function(ggplot_obj) {
  all_vars <- get_all_plot_vars(ggplot_obj)
  # Extract variable names from expressions
  unique(all.vars(parse(text = all_vars)))
}

save_ggplot_data_to_excel <- function(ggplot_obj, df, filename, tab_name, col_names = NULL, overwrite_tab = TRUE) {
  
  if (!grepl("\\.xlsx$", filename, ignore.case = TRUE)) {
    filename <- paste0(filename, ".xlsx")
  }
  
  all_mappings <- sapply(ggplot_obj$mapping, rlang::as_label)
  layer_mappings <- unlist(lapply(ggplot_obj$layers, function(l) {
    sapply(l$mapping, rlang::as_label)
  }))
  all_vars <- get_raw_vars(ggplot_obj)

  plot_data <- df[, intersect(all_vars, names(df)), drop = FALSE]
  
  # Rename columns if mapping provided
  if (!is.null(col_names)) {
    current_names <- names(plot_data)
    for (i in seq_along(current_names)) {
      if (current_names[i] %in% names(col_names)) {
        current_names[i] <- col_names[[current_names[i]]]
      }
    }
    names(plot_data) <- current_names
  }

  if (file.exists(filename)) {
    wb <- loadWorkbook(filename)
  } else {
    wb <- createWorkbook()
  }
  
  tab_name <- substr(tab_name, 1, 31)
  if (tab_name %in% names(wb)) {
    if (overwrite_tab) {
      removeWorksheet(wb, tab_name)
    } else {
      warning(paste0("Tab '", tab_name, "' already exists. Skipping. Use overwrite_tab = TRUE to overwrite."))
      return(invisible(NULL))
    }
  }
  
  addWorksheet(wb, tab_name)
  writeData(wb, tab_name, plot_data)
  
  saveWorkbook(wb, filename, overwrite = TRUE)
  cat("Saved", ncol(plot_data), "columns (", paste(names(plot_data), collapse = ", "), ") to tab '", tab_name, "' in", filename, "\n")
}

save_full_dataframe_to_excel <- function(plot_data, filename, tab_name, col_names = NULL, overwrite_tab = TRUE) {
  
  if (!grepl("\\.xlsx$", filename, ignore.case = TRUE)) {
    filename <- paste0(filename, ".xlsx")
  }
  
  # Rename columns if mapping provided
  if (!is.null(col_names)) {
    current_names <- names(plot_data)
    for (i in seq_along(current_names)) {
      if (current_names[i] %in% names(col_names)) {
        current_names[i] <- col_names[[current_names[i]]]
      }
    }
    names(plot_data) <- current_names
  }
  
  if (file.exists(filename)) {
    wb <- loadWorkbook(filename)
  } else {
    wb <- createWorkbook()
  }
  
  tab_name <- substr(tab_name, 1, 31)
  if (tab_name %in% names(wb)) {
    if (overwrite_tab) {
      removeWorksheet(wb, tab_name)
    } else {
      warning(paste0("Tab '", tab_name, "' already exists. Skipping. Use overwrite_tab = TRUE to overwrite."))
      return(invisible(NULL))
    }
  }
  
  addWorksheet(wb, tab_name)
  writeData(wb, tab_name, plot_data)
  
  saveWorkbook(wb, filename, overwrite = TRUE)
  cat("Saved", ncol(plot_data), "columns (", paste(names(plot_data), collapse = ", "), ") to tab '", tab_name, "' in", filename, "\n")
}
