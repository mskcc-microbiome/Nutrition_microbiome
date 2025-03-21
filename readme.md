Project Title: Sugar-rich foods exacerbate antibiotic-induced microbiome disruption.

Brief Description:
This repository contains the code and processed data used for the analyses presented in the manuscript "Sugar-rich foods exacerbate antibiotic-induced microbiome disruption".  
The code performs statistical analyses (including Bayesian inference) and generates the figures demonstrating the link between dietary sugar intake, antibiotic exposure, and microbiome disruption in both human patients undergoing hematopoietic cell transplantation and in a mouse model.


## data/ 

### Patient Characteristics Data (`patient_characteristics.csv`)

This file (`patient_characteristics.csv`) provides deidentified demographic and clinical characteristics for the 173 patients included in the study cohort.  These characteristics are used in various analyses throughout the manuscript.

| Column Name          | Description                                                                                                                                                                                            | Data Type | Possible Values/Examples                                                                     |
|----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------|----------------------------------------------------------------------------------------------|
| `pid`                | Deidentified patient identifier.  Each patient has a unique `pid`.                                                                                                                              | character | "P1", "P2", "P3", ...                                                                       |
| `age`                | Patient age in years at the time of transplant.                                                                             | numeric   | Numeric values.                                                        |
| `sex`                | Patient sex.                                                                                                                                                                                | character | "M" (Male), "F" (Female)                                            |
| `disease.simple`     | Simplified disease type. The following abbreviations are used: *Define each abbreviation here.  For example:*<br>  *   AML: Acute Myeloid Leukemia<br>  *   ALL: Acute Lymphoblastic Leukemia<br>  *   NHL: Non-Hodgkin Lymphoma<br>  *   MDS/MPN: Myelodysplastic Syndromes/Myeloproliferative Neoplasms<br>  *   CML: Chronic Myelogenous Leukemia<br>  *   CLL: Chronic Lymphocytic Leukemia<br> *   Hodgkins: Hodgkin's Lymphoma<br> *   Myeloma: Multiple Myeloma     | character | "AML", "ALL", "NHL", "MDS/MPN", "CML", "CLL", "Hodgkins", "Myeloma"                             |                                                                  |
| `source`             | Graft source type.  The following abbreviations are used: *Define each abbreviation.  For example:* <br> *  unmodified: Unmodified graft<br> *   TCD: T-cell depleted     | character |  "unmodified","TCD"...                                                                         |
| `intensity`          | Conditioning regimen intensity. The following abbreviations are used:*Define each abbreviation*. For example:<br> * ablative:Ablative conditioning regimen <br> * nonablative:Non-ablative conditioning regimen <br> * reduced: reduced-intensity conditioning.         | character |  "ablative", "nonablative", "reduced"...                                                             |
| `gvhd_ppx`           | Graft-versus-host disease (GVHD) prophylaxis regimen.  The following abbreviations are used: *Define each abbreviation*. For example:<br>  * CNI-based: Calcineurin inhibitor-based prophylaxis<br> * PTCy-based: Post-transplant cyclophosphamide-based prophylaxis        | character |   "CNI-based", "PTCy-based"...                                                                   |
| `day_exposed`        | Number of days the patient was exposed to broad-spectrum antibiotics within the window of day -7 to day +12, relative to the day of transplant (day 0).  The following antibiotics were considered broad-spectrum: piperacillin/tazobactam, carbapenems (e.g., meropenem, imipenem), cefepime, linezolid, oral vancomycin, and metronidazole. | integer   | 0, 1, 2, 3, ...                                                                             |




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

