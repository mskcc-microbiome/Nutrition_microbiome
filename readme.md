This is the code repository for the nutrition microbiome paper.
The code for generating the figures is included. 



## Reproducing the R Environment

This project uses `renv` to manage package dependencies, ensuring reproducibility of the analysis.  `renv` creates a project-specific library of R packages, isolated from your global R installation.  
This prevents conflicts with other projects and ensures that the correct package versions are used.

To recreate the R environment:

1.  **Install `renv`:** If you do not have the `renv` package installed, install it from CRAN:
    ```r
    if (!requireNamespace("renv", quietly = TRUE)) {
      install.packages("renv")
    }
    ```
    This command first checks if `renv` is already installed, and only installs it if necessary.  This is good practice for reproducibility.

2.  **Clone the Repository:** Clone this GitHub repository to your local machine using Git:
    ```bash
    git clone git@github.com:mskcc-microbiome/Nutrition_microbiome.git
    ```

3.  **Open the Project in RStudio (Recommended):** Open the RStudio project file (`.Rproj`) located in the cloned repository.  This will automatically set the working directory correctly.  If you're not using RStudio, navigate to the project directory in your R console using `setwd()`.

4.  **Restore the Environment:** Inside R (either in RStudio or your R console), run the following command:
    ```r
    renv::restore()
    ```
    This command will read the `renv.lock` file and install the *exact* versions of all packages listed there into a project-specific library.  This may take some time, especially the first time you run it.  `renv` may need to download and compile packages.

5.  **Activate the Environment (if not using RStudio):**
    If you are *not* using RStudio, you will need to *activate* the `renv` environment after restoring it.  This is done automatically by RStudio when you open the `.Rproj` file.  To activate manually, run:
    ```r
    renv::activate()
    ```
    You'll only need to do this once per R session, *if* you aren't using RStudio.

