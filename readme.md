# Sugar-rich foods exacerbate antibiotic-induced microbiome disruption

This is the original development repository for the manuscript "Sugar-rich foods
exacerbate antibiotic-induced microbiome disruption". It holds the working scripts
that produced the published analyses: statistical modeling (including Bayesian
inference) of the link between dietary sugar intake, antibiotic exposure, and
microbiome disruption, in both patients undergoing hematopoietic cell
transplantation and in a mouse model.

Preprint: https://www.biorxiv.org/content/10.1101/2024.10.14.617881v1

## If you want to reproduce the figures, start here instead

A clean, runnable reproduction of the public (non-PHI) figures lives in a separate
repository:

**https://github.com/Anqi-Dai/Nutrition_microbiome_reproducibility**
(archived: https://doi.org/10.5281/zenodo.21290618)

That repository is the one to use if your goal is to rebuild the figures. It reads
only from a small set of de-identified released tables, rebuilds each panel with a
numbered R script, and documents its own environment setup, along with the GraPhlAn
food-tree render and the taxUMAP embedding pipeline. Those setup instructions used
to live in this README and are no longer maintained here.

This repository is kept as the record of how the analyses were originally developed.
The scripts here read from the full internal data, including patient-level tables
that cannot be shared, so most of them will not run outside our environment. Data
access, licensing, and citation details are covered in the reproducibility
repository linked above.

## R environment

This project uses `renv`. To restore the package library recorded in `renv.lock`:

```r
install.packages("renv")   # if not already installed
renv::restore()
```

Open the `.Rproj` file in RStudio and `renv` activates automatically; otherwise call
`renv::activate()` once per session.