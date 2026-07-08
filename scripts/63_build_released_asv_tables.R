# Build the released ASV data tables from the 171 raw exports.
#
# Two shareable products, both written to ../data (the dev repo) and to the
# Reproduce_nutrition released_data/ folder (the public repro repo):
#
#   1. 63_asv_blast_annotation.csv -- one row per ASV: its taxonomic lineage plus the
#      BLAST hit that assigned it. Joins the two per-ASV 171 annotation exports
#      (171_asv_annotation_blast_data.csv, 171_asv_annotation_blast_detailed_data.csv)
#      on asv_key. Carries no counts; it is a dedicated ASV-to-annotation lookup.
#
#   2. 63_asv_count_relab_res.csv -- the per-ASV counts (asv_key, sampleid, count,
#      count_relative). The CLR is left to be computed downstream in the
#      figure-reproduction script.
#
# The 16S Enterococcus ASV relab table is no longer built here: it is exactly the
# Enterococcus rows of product 1 joined to product 2 (relab = count_relative), so the
# one script that needs it (reproduce/43_extdata_enterococcus_asv.R) derives it inline.
#
# Inputs live in ../data (run from the scripts/ folder).

library(tidyverse)

# Public repro repo released_data/. Written to in addition to ../data so the two
# copies stay in sync. Skipped with a note if the repo is not checked out here.
RELEASED <- "/Users/daia1/Work/projects/Reproduce_nutrition/released_data"

write_both <- function(df, filename) {
  write_csv(df, file.path("../data", filename))
  if (dir.exists(RELEASED)) {
    write_csv(df, file.path(RELEASED, filename))
  } else {
    message("released_data/ not found at ", RELEASED, "; wrote only ../data/", filename)
  }
}

# ---------------------------------------------------------------------------
# 1. ASV BLAST annotation lookup (one row per ASV).
# ---------------------------------------------------------------------------
# Taxonomy (kingdom..species) from the vdb blast-based annotation, joined to the
# detailed record of the BLAST hit that made the call. `ordr` is renamed to `order`.
#
# Each ASV sequence is the query, aligned against a 16S reference database with BLAST;
# the detailed columns describe the reported hit. Which are standard BLAST tabular
# (outfmt 6) fields vs. derived by the annotation pipeline:
#   accession     NCBI accession of the matched reference (subject) sequence, e.g.
#                 NR_113903.1                                    [BLAST: sseqid/saccver]
#   name          composite label of the hit: the reference species -- or a ';'-joined
#                 list of species that share this top hit -- followed by the query
#                 length and percent identity          [derived from BLAST subject titles]
#   unique_name   a single representative species distilled from `name`      [derived]
#   query_length  length (bp) of the ASV query sequence                      [BLAST: qlen]
#   align_length  length of the query-subject alignment, gaps included     [BLAST: length]
#   pident        percent of identical bases over the alignment            [BLAST: pident]
#   nident        number of identical bases in the alignment               [BLAST: nident]
#   score         raw alignment score                                       [BLAST: score]
#   length_ratio  align_length / query_length: fraction of the query covered by the
#                 alignment (~1 = full-length match)          [derived coverage metric]
# So accession, query_length, align_length, pident, nident and score are typical BLAST
# output; name, unique_name and length_ratio are post-processed by the pipeline.
annotation <- read_csv("../data/171_asv_annotation_blast_data.csv", show_col_types = FALSE) |>
  select(asv_key, kingdom, phylum, class, order = ordr, family, genus, species)

detailed <- read_csv("../data/171_asv_annotation_blast_detailed_data.csv", show_col_types = FALSE) |>
  select(asv_key, accession, name, unique_name, query_length, align_length,
         pident, nident, score, length_ratio)

asv_annotation <- annotation |>
  left_join(detailed, by = "asv_key")

# The detailed BLAST table covers only the ASVs with a retained hit, so those columns
# are NA for the rest; every ASV has a taxonomy annotation.
message("asv blast annotation: ", nrow(asv_annotation), " ASVs; ",
        sum(is.na(asv_annotation$accession)), " without a BLAST hit detail")

write_both(asv_annotation, "63_asv_blast_annotation.csv")

# ---------------------------------------------------------------------------
# 2. Per-ASV counts and relative abundance.
# ---------------------------------------------------------------------------
# The observed (non-zero) per-sample counts. CLR is not computed here; the
# figure-reproduction script does its own centred-log-ratio (0.5 pseudocount over
# the full ASV x sample matrix, as in script 171's genus-level CLR).
asv_count_relab <- read_csv("../data/171_asv_counts_data.csv", show_col_types = FALSE) |>
  select(asv_key, sampleid, count, count_relative)

message("asv count/relab: ", nrow(asv_count_relab), " rows over ",
        n_distinct(asv_count_relab$asv_key), " ASVs x ", n_distinct(asv_count_relab$sampleid), " samples")

write_both(asv_count_relab, "63_asv_count_relab_res.csv")
