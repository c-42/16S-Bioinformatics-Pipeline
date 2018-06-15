# CREATE MANIFEST
* Compiles demultiplexed reads into a single .qza for quality control
* Create comma-separated text file (.csv) with the following columns:
    1. sample identifier
    2. absolute filepath
    3. read direction
* The first line must be a header line
* For single-end reads, 1 line per sample; for paired-end, 2 lines per sample
      sample-id,absolute-filepath,direction
      sample-1,$PWD/some/filepath/sample1_R1.fastq.gz,forward
      sample-2,$PWD/some/filepath/sample2_R1.fastq.gz,forward
      sample-1,$PWD/some/filepath/sample1_R2.fastq.gz,reverse
      sample-2,$PWD/some/filepath/sample2_R2.fastq.gz,reverse

# IMPORT DATA
* Import as Phred33

      qiime tools import \
        --type 'SampleData[SequencesWithQuality]' \
        --input-path manifestfilename \
        --output-path manifestout.qza \
        --source-format SingleEndFastqManifestPhred33

    or

      qiime tools import \
        --type 'SampleData[PairedEndsSequencesWithQuality]' \
        --input-path manifestfilename \
        --output-path manifestout.qza \
        --source-format PairedEndFastqManifestPhred33

# DENOISING - DADA2
* DADA2 is a pipeline for detecting and correcting Illumina amplicon sequence data, where possible. Will filter PhiX reads and chimeras.
* Parameters: --p-trim-left m trims the first 'm' bases; --p-trunc-len n truncates each sequence at position 'n'
* First, convert manifestout.qza to .qzv for visualization
* Dada2 can only denoise samples from a single sequencing run, to include multiple runs (ie me + wiebke), dada2 each separately and merge with technique in fecal microbiome tutorial

      qiime demux summarize \
        --i-data manifestout.qza
        --o-visualization manifestout.qzv

* Use https://view.qiime2.org to view .qzv files
* Select values for 'm' and 'n' according to .qzv

      qiime dada2 denoise-single \
        --i-demultiplexed-seqs manifestout.qza \
        --p-trim-left m \
        --p-trunc-len n \
        --o-representative-sequences dada2.qza \
        --o-table dada2-table.qza

    or

      qiime dada2 denoise-paired \
        --i-demultiplexed-seqs manifestout.qza \
        --o-table dada2-table.qzv \
        --o-representative-sequences dada2.qza \
        --p-trim-left-f m \
        --p-trim-left-r x \
        --p-trunc-len-f n \
        --p-trunc-len-r y

# MERGE DENOISED DATASETS
* First merge FeatureTable, then FeatureData

      qiime feature-table merge \
        --i-tables table-1.qza \
        --i-tables table-2.qza \
        --o-merged-table table.qza
      qiime feature-table merge-seqs \
        --i-data rep-seqs-1.qza \
        --i-data rep-seqs-2.qza \
        --o-merged-data rep-seqs.qza

* Summarize
      qiime feature-table summarize \
        --i-table table.qza \
        --o-visualization table.qzv \
        --m-sample-metadata-file sample-metadata.tsv

# ASSIGN TAXONOMY
* Sequence identification according to trained feature classifier
      qiime feature-classifier classify-sklearn \
        --i-classifier classifier.qza \
        --i-reads dada2.qza \
        --o-classification taxonomy.qza

      qiime metadata tabulate \
        --m-input-file taxonomy.qza \
        --o-visualization taxonomy.qzv

# TAXONOMY BARPLOT
* Histograms level 1-7
      qiime taxa barplot \
        --i-table dada2-table.qza \
        --i-taxonomy taxonomy.qza \
        --m-metadata-file metadata.tsv \
        --o-visualization taxa-bar-plots.qzv

# FEATURE TABLE FEATURE ID
* build metadata.tsv file (https://docs.qiime2.org/2018.2/tutorials/metadata/)
* feature-table summarize provides info on abundance and distribution of sequences per sample/feature
* feature-table tabulate-seqs maps featureIDs to sequences and provides NCBI links for BLAST

      qiime feature-table summarize \
        --i-table dada2-table.qza \
        --o-visualization dada2-table.qzv \
        --m-sample-metadata-file metadata.tsv

      qiime feature-table tabulate-seqs \
        --i-data dada2.qza \
        --o-visualization featureID.qzv

# PHYLOGENETIC TREE
* Multiple sequence alignment:

      qiime alignment mafft \
        --i-sequences dada2.qza \
        --o-alignment aligned.qza

* Mask/filter alignment to remove noise:

      qiime alignment mask \
        --i-alignment aligned.qza \
        --o-masked-alignment masked.qza

* FastTree to produce unrooted phylogenetic tree:

      qiime phylogeny fasttree \
        --i-alignment masked.qza \
        --o-tree unrooted-tree.qza

* Root tree according to midpoint of longest tip-to-tip distance in unrooted tree:

      qiime phylogeny midpoint-root \
        --i-tree unrooted-tree.qza \
        --o-rooted-tree rooted-tree.qza

# ALPHA AND BETA DIVERSITY INDICES
* Output files in new directory 'core-metrics-results'
* 'Emperor' output files create maneuverable MDS plots in qiime2.view

      qiime diversity core-metrics-phylogenetic \
        --i-phylogeny rooted-tree.qza \
        --i-table dada2-table.qza \
        --p-sampling-depth SampleDepthValue \
        --m-metadata-file metadata.tsv \
        --output-dir core-metrics-results

#### ALPHA - associations between categorical metadata columns and alpha diversity
* Shannon's diversity index - quantitative measure of community richness
* Observed OTUs - qualitative measure of community richness
* Faith's phylogenetic diversity - qualitative measure of community richness incorporating phylogenetic relationships
* Evenness (Pielou's evenness) - measure of community evenness

      qiime diversity alpha-group-significance \
        --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
        --m-metadata-file metadata.tsv \
        --o-visualization core-metrics-results/faith-pd-group-significance.qzv

      qiime diversity alpha-group-significance \
        --i-alpha-diversity core-metrics-results/evenness_vector.qza \
        --m-metadata-file metadata.tsv \
        --o-visualization core-metrics-results/evenness-group-significance.qzv

####  BETA - PERMANOVA
* Jaccard distance - qualitative measure of dissimilarity
* Bray-Curtis distance - quantitative measure of community dissimilarity
* Unweighted UniFrac distance - a qualitative measure of community dissimilarity incorporating phylogenetic relationships
* Weighted UniFrac distance - quantitative measure of community dissimilarity incorporating phylogenetic relationships
* Sample-depth parameter:
    - Each sample is subsampled to predetermined count and samples with fewer reads are dropped
    - Choose based on dada2-table.qzv "interactive sample detail"
* Choose metadata category header to analyze
* --p-pairwise is an optional parameter to add pairwise analysis

      qiime diversity beta-group-significance \
        --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
        --m-metadata-file metadata.tsv \
        --m-metadata-column Category \
        --o-visualization core-metrics-results/unweighted-unifrac-body-site-significance.qzv \
        --p-pairwise

# Continuous Sample Metadata (ie "time")
* Not yet derived from tutorials: https://docs.qiime2.org/2018.4/
###### Alpha
*In this data set, no continuous sample metadata columns (e.g., DaysSinceExperimentStart) are correlated with alpha diversity, so we won’t test for those associations here. If you’re interested in performing those tests (for this data set, or for others), you can use the qiime diversity alpha-correlation command*
######  Beta
*Again, none of the continuous sample metadata that we have for this data set are correlated with sample composition, so we won’t test for those associations here. If you’re interested in performing those tests, you can use the qiime metadatadistance-matrix in combination with qiime diversity mantel and qiime diversity bioenv commands*

# Ordination (PCoA plots)
* --p-custom-axes parameter defines MDS axes and can accomodate time as a variable

      qiime emperor plot \
        --i-pcoa core-metrics-results/unweighted_unifrac_pcoa_results.qza \
        --m-metadata-file metadata.tsv \
        --p-custom-axes DaysSinceExperimentStart \
        --o-visualization core-metrics-results/unweighted-unifrac-emperor-DaysSinceExperimentStart.qzv

      qiime emperor plot \
        --i-pcoa core-metrics-results/bray_curtis_pcoa_results.qza \
        --m-metadata-file metadata.tsv \
        --p-custom-axes DaysSinceExperimentStart \
        --o-visualization core-metrics-results/bray-curtis-emperor-DaysSinceExperimentStart.qzv

# RAREFACTION (ALPHA)
* Optional parameters --p-min-depth and --p-max-depth

      qiime diversity alpha-rarefaction \
        --i-table dada2-table.qza \
        --i-phylogeny rooted-tree.qza \
        --p-max-depth MedianFrequency \
        --m-metadata-file metadata.tsv \
        --o-visualization alpha-rarefaction.qzv

* Top plot shows alpha rarefaction ie whether increased sampling depth would observe higher species richness
* Bottom plot shows number of samples remaining in each group (eg colony) if sample-depth were set to x

# TRAIN A FEATURE CLASSIFIER FOR TAXANOMIC ANALYSIS
* Train a classifier: https://docs.qiime2.org/2018.2/tutorials/feature-classifier/
* Data files: https://docs.qiime2.org/2018.2/data-resources/

###### 1. Import references
* For SILVA_132_QIIME_release: https://www.arb-silva.de/fileadmin/silva_databases/qiime/Silva_128_notes.txt

      qiime tools import \
        --type 'FeatureData[Sequence]' \
        --input-path silva_132_99_16S.fa \
        --output-path OTUs.qza

      qiime tools import \
        --type 'FeatureData[Taxonomy]' \
        --source-format HeaderlessTSVTaxonomyFormat \
        --input-path taxonomy_7_levels.txt \
        --output-path ref-taxonomy.qza

###### 2. Extract Reference Reads
* This command is for primer set 341F-785R (16S rRNA V3 and V4 - bacteria/archaea)
* Takes about 15 minutes to run

      qiime feature-classifier extract-reads \
        --i-sequences OTUs.qza \
        --p-f-primer CCTACGGGNGGCWGCAG \
        --p-r-primer GACTACHVGGGTATCTAATCC \
        --p-trunc-len 444 \
        --o-reads ref-seqs.qza

###### 3. Train the Classifier
* Takes several hours to run

      qiime feature-classifier fit-classifier-naive-bayes \
        --i-reference-reads ref-seqs.qza \
        --i-reference-taxonomy ref-taxonomy.qza \
        --o-classifier classifier.qza
