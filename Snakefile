'''
This Snakefile carries out diet project work with qiime2 **LOCALLTY**

To run, conda activate qiime2-2021. for example snakemake -j8 food
'''
from glob import glob

rule all:
    input:
        'data/finalized/unweighted_unifrac_distance_matrix.qza'
        
sample_dir = '/Users/daia1/pipeline/scripts/food_tree/data/cleaned_diet_data'



#####################################################################################
# This section contains the template of doing beta diversity distance calculations 
# and the pcoa for diet data in different time period, need to do it here cuz 
# I need to use the tree.
#####################################################################################
rule covert_tree_to_qza:
    input:
        'data/cleaned_tree/output_food_tree_datatree.newick'
    output:
        'data/cleaned_tree/output_food_tree_datatree.qza'
    shell:
        '''
        qiime tools import \
            --input-path {input[0]} --output-path  {output[0]} --type 'Phylogeny[Rooted]'
        '''

rule convert_food_to_biom:
    input:
        'data/finalized/paired/pNday/{time}_diet_foodID_dehydrated_weight_per_pt.tsv'
    output:
        'data/finalized/paired/pNday/{time}_diet_foodID_dehydrated_weight_per_pt.biom'
    shell:
        'biom convert -i  {input[0]} -o {output[0]} --to-hdf5 --table-type="Table"'

rule convert_biom_to_qza:
    input:
        'data/finalized/paired/pNday/{time}_diet_foodID_dehydrated_weight_per_pt.biom'
    output:
        'data/finalized/paired/pNday/{time}_diet_foodID_dehydrated_weight_per_pt.qza'
    shell:
        'qiime tools import --input-path {input[0]} --output-path  {output[0]} --type "FeatureTable[Frequency]"'


rule cal_unweighted_unifrac_for_food:
    input:
        cts='data/finalized/paired/pNday/{time}_diet_foodID_dehydrated_weight_per_pt.qza',
        tree='data/cleaned_tree/output_food_tree_datatree.qza'
    output:
        'data/finalized/paired/pNday/{time}_diet_foodID_dehydrated_weight_per_pt_unweighted_unifrac_distance_matrix.qza'
    shell:
        '''
        qiime diversity beta-phylogenetic \
            --i-table {input.cts} \
            --i-phylogeny {input.tree} \
            --p-metric unweighted_unifrac \
            --o-distance-matrix {output[0]}
        '''

rule pcoa_unweighted_unifrac_food:
    input:
        'data/finalized/paired/pNday/{time}_diet_foodID_dehydrated_weight_per_pt_unweighted_unifrac_distance_matrix.qza'
    output:
        'data/finalized/paired/pNday/{time}_diet_foodID_dehydrated_weight_per_pt_unweighted_unifrac_pcoa.qza'
    shell:
        '''qiime diversity pcoa \
            --i-distance-matrix {input[0]} \
            --o-pcoa {output[0]}'''

rule export_food_pcoa:
    input:
        'data/finalized/paired/pNday/{time}_diet_foodID_dehydrated_weight_per_pt_unweighted_unifrac_pcoa.qza'
    output:
        directory('data/finalized/paired/pNday/{time}_diet_foodID_dehydrated_weight_per_pt_unweighted_unifrac_pcoa')
    shell:
        'qiime tools export --input-path {input[0]} --output-path {output[0]}'

#####################################################################################
# microbe data
# have to use qiime too cuz using R vegan the matrix dimension just don't seem right
#####################################################################################


rule convert_stool_relab_table_to_biom:
    input:
        'data/finalized/paired/pNday/{time}_stool_relab_species.tsv'
    output:
        'data/finalized/paired/pNday/{time}_stool_relab_species.biom'
    shell:
        'biom convert -i  {input[0]} -o {output[0]} --to-hdf5 --table-type="Table"'

rule convert_stool_table_to_qza:
    input:
        'data/finalized/paired/pNday/{time}_stool_relab_species.biom'
    output:
        'data/finalized/paired/pNday/{time}_stool_relab_species.qza'
    shell:
        'qiime tools import --input-path {input[0]} --output-path  {output[0]} --type "FeatureTable[Frequency]"' 

# for species relab data calculate the braycurtis distance

rule calculate_stool_microbe_braycurtis_distance:
    input:
        'data/finalized/paired/pNday/{time}_stool_relab_species.qza'
    output:
        'data/finalized/paired/pNday/{time}_stool_relab_species_braycurtis_distance_matrix.qza'
    shell:
        '''
        qiime diversity beta \
            --i-table {input[0]} \
            --p-metric  braycurtis \
            --o-distance-matrix {output[0]}
        '''

rule stool_microbe_braycurtis_PCoA:
    input:
        'data/finalized/paired/pNday/{time}_stool_relab_species_braycurtis_distance_matrix.qza'
    output:
        'data/finalized/paired/pNday/{time}_stool_relab_species_braycurtis_pcoa.qza'
    shell:
        'qiime diversity pcoa \
            --i-distance-matrix {input[0]} \
            --o-pcoa {output[0]}'

rule export_stool_microbe_pcoa:
    input:
        'data/finalized/paired/pNday/{time}_stool_relab_species_braycurtis_pcoa.qza'
    output:
        directory('data/finalized/paired/pNday/{time}_stool_relab_species_braycurtis_pcoa')
    shell:
        'qiime tools export --input-path {input[0]} --output-path {output[0]}'



#####################################################################################
# the macronutrients procrustes (need to compute the bray curtis since I don't have a tree to compute the unifrac)
#####################################################################################
'''
rule convert_food_to_biom:
    input:
        'data/finalized/paired/pNday/{time}_diet_macro_dehydrated_weight_per_pt.tsv'
    output:
        'data/finalized/paired/pNday/{time}_diet_macro_dehydrated_weight_per_pt.biom'
    shell:
        'biom convert -i  {input[0]} -o {output[0]} --to-hdf5 --table-type="Table"'

rule convert_biom_to_qza:
    input:
        'data/finalized/paired/pNday/{time}_diet_macro_dehydrated_weight_per_pt.biom'
    output:
        'data/finalized/paired/pNday/{time}_diet_macro_dehydrated_weight_per_pt.qza'
    shell:
        'qiime tools import --input-path {input[0]} --output-path  {output[0]} --type "FeatureTable[Frequency]"'


rule cal_bc_for_food:
    input:
        cts='data/finalized/paired/pNday/{time}_diet_macro_dehydrated_weight_per_pt.qza'
    output:
        'data/finalized/paired/pNday/{time}_diet_macro_dehydrated_weight_per_pt_bc_distance_matrix.qza'
    shell:
        'qiime diversity beta \
            --i-table {input[0]} \
            --p-metric braycurtis \
            --o-distance-matrix {output[0]}'

rule pcoa_bc_food:
    input:
        'data/finalized/paired/pNday/{time}_diet_macro_dehydrated_weight_per_pt_bc_distance_matrix.qza'
    output:
        'data/finalized/paired/pNday/{time}_diet_macro_dehydrated_weight_per_pt_bc_pcoa.qza'
    shell:
        'qiime diversity pcoa \
            --i-distance-matrix {input[0]} \
            --o-pcoa {output[0]}'

rule export_food_pcoa:
    input:
        'data/finalized/paired/pNday/{time}_diet_macro_dehydrated_weight_per_pt_bc_pcoa.qza'
    output:
        directory('data/finalized/paired/pNday/{time}_diet_macro_dehydrated_weight_per_pt_bc_pcoa')
    shell:
        'qiime tools export --input-path {input[0]} --output-path {output[0]}'

'''
# the loop variable for this part

with open('data/finalized/paired/pNday/p5day_names_loop.csv') as f:
    content = f.readlines()

times5_mrn = [x.strip() for x in content]

with open('data/finalized/paired/pNday/p4day_names_loop.csv') as f:
    content = f.readlines()

times4_mrn = [x.strip() for x in content]


with open('data/finalized/paired/pNday/p3day_names_loop.csv') as f:
    content = f.readlines()

times3_mrn = [x.strip() for x in content]


with open('data/finalized/paired/pNday/p2day_names_loop.csv') as f:
    content = f.readlines()

times2_mrn = [x.strip() for x in content]


loop_vars = times2_mrn +  times3_mrn + times4_mrn + times5_mrn

stool_loop_vars = ['allstool_weighted']

food_loop_vars = ['allstool_weighted']

food_loop_vars = ["allstool_p{}d".format(i) for i in range(1,6)]

stool_loop_vars = ["allstool_p{}d_scts".format(i) for i in range(1,6)]


rule stool:
    input:
        expand('data/finalized/paired/pNday/{time}_stool_relab_species_braycurtis_pcoa', time = stool_loop_vars)


rule food:
    input:
        expand('data/finalized/paired/pNday/{time}_diet_foodID_dehydrated_weight_per_pt_unweighted_unifrac_pcoa',  time = food_loop_vars)
        #expand('data/finalized/paired/pNday/{time}_diet_macro_dehydrated_weight_per_pt_bc_pcoa',  time = food_loop_vars)


