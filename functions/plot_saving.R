library(openxlsx)

save_plot_data_to_excel <- function(plot_object, 
                                    file_path = "plot_data.xlsx", 
                                    sheet_name = "Sheet1") {
  
  plot_data <- ggplot_build(plot_object)$data
  
  #so we don't overwrite the other tabs:
  if (file.exists(file_path)) {
    wb <- loadWorkbook(file_path)
  } else {
    wb <- createWorkbook()
  }
  
  addWorksheet(wb, sheet_name)
  writeData(wb, sheet_name, plot_data[[1]])
  saveWorkbook(wb, file_path, overwrite = TRUE)

}