Project Title: Sugar-rich foods exacerbate antibiotic-induced microbiome disruption.

Brief Description:
This repository contains the code and processed data used for the analyses presented in the manuscript "Sugar-rich foods exacerbate antibiotic-induced microbiome disruption".  
The code performs statistical analyses (including Bayesian inference) and generates the figures demonstrating the link between dietary sugar intake, antibiotic exposure, and microbiome disruption in both human patients undergoing hematopoietic cell transplantation and in a mouse model.


## data/ 

## Food Code Levels Table (`NodeLabelsMCT.txt`)

This file (`NodeLabelsMCT.txt`) contains information used to describe the different levels of the food classification system. The source of the file is listed below.  

**Source:**

*   **Publication:** Johnson, A. J. et al. Daily Sampling Reveals Personalized Diet-Microbiome Associations in Humans. Cell Host Microbe 25, 789-802.e5 (2019).
*   **Repository:** https://github.com/knights-lab/Food_Tree

**File Structure:**

| Column Name             | Description                                                                                        | Data Type   |
|--------------------------|----------------------------------------------------------------------------------------------------|-------------|
| `Level.code`            | A hierarchical code representing the level within the food code classification system.  Higher-level codes (e.g., "1", "11") represent broader categories, while lower-level codes (e.g., "1142") represent more specific food items.                                                | character   |
| `Main.food.description` | Text description of the food category corresponding to the `Level.code`                                         | character   |


## Food Group Color Key (`food_group_color_key_final.csv`)

This file (`food_group_color_key_final.csv`) provides a mapping between food group codes, names, and colors used for visualization in the manuscript.

| Column Name | Description                                                                                  | Data Type   |
|-------------|----------------------------------------------------------------------------------------------|-------------|
| `fgrp1`     | Numeric code representing the food group (corresponds to the first digit of the full food code). | integer     |
| `fdesc`     | Full descriptive name of the food group.                                                   | character   |
| `fg1_name`  | Short variable-friendly name for the food group.                                        | character   |
| `color`     | Hexadecimal color code used for representing this food group in figures (e.g., food trees).     | character   |
| `shortname` | Short, one-word name of the food group.                                                      | character   |


## Data availability for the patient-level clinical data 

The patient-level clinical data used in this study are not publicly available due to patient privacy concerns and institutional regulations.  These data can be made available to qualified researchers upon reasonable request and with the execution of a data use agreement with Memorial Sloan-Kettering Cancer Institute.  Requests for data access should be directed to Dr. Jonathan Peled at peledj@mskcc.org.


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


## Setting up the Conda Environment for Graphlan

These instructions assume you have Conda (either Miniconda or Anaconda) installed.

1.  **Create a new environment:**
    ```bash
    conda create -n graphlan_env python=2.7 biopython matplotlib
    ```
    This command creates a new Conda environment named `graphlan_env` with Python 2.7, Biopython, and Matplotlib. We'll install Graphlan in the next step. Note that specific version can be specified via `biopython>=1.6 matplotlib>=1.1`.

2.  **Activate the environment:**
    ```bash
    conda activate graphlan_env
    ```

3. **Install Graphlan:**

   Follow the installation instruction of Graphlan. For example, using pip.
   ```bash
    pip install graphlan
    ```
    