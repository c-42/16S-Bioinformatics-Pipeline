---
---
Notes:
* Pipeline for Qiime2, see [Qiime2 tutorials](https://docs.qiime2.org/2018.11/ "Qiime2 Documents") for more options and better descriptions
* Filenames are arbitrary, the names here are chosen to represent each step of the process (ie denoising with DADA2 yields "dada2.qza" output file)
* Feature-classifier must be updated with recent database and according to specific primers used.
---
---


## I. CREATE MANIFEST

The manifest compiles demultiplexed reads during import into a single .qza for quality control. All forward and reverse reads are compiled and sorted by sample.

Create comma-separated text file (.csv) with the following columns:
  >1. sample identifier
  >2. absolute filepath
  >3. read direction

* The first line must be the header line
* For single-end reads, 1 line per sample; for paired-end, 2 lines per sample
* Remove file extension from file name (ie "manifest" not "manifest.csv")

|line|comma-separated columns
|::|
|1|sample-id,absolute-filepath,direction
|2|sample-1,$PWD/some/filepath/sample1_R1.fastq.gz,forward
|3|sample-2,$PWD/some/filepath/sample2_R1.fastq.gz,forward
|4|sample-1,$PWD/some/filepath/sample1_R2.fastq.gz,reverse
|5|sample-2,$PWD/some/filepath/sample2_R2.fastq.gz,reverse

---
## II. IMPORT DATA
* Import as Phred33

Single-end reads:
```py
    qiime tools import \
      --type 'SampleData[SequencesWithQuality]' \
      --input-path manifestfilename \
      --output-path manifestout.qza \
      --source-format SingleEndFastqManifestPhred33
```
Paired-end reads:
```py
    qiime tools import \
      --type 'SampleData[PairedEndSequencesWithQuality]' \
      --input-path manifestfilename \
      --output-path manifestout.qza \
      --source-format PairedEndFastqManifestPhred33
```
---
## III. DENOISING with DADA2

  DADA2 is a pipeline for detecting and correcting Illumina amplicon sequence data, where possible. Will filter PhiX reads and chimeras. An alternative denoising method is ["Deblur"](https://docs.qiime2.org/2018.11/tutorials/moving-pictures/ "Moving Pictures Tutorial With DADA2 and Deblur Walkthroughs"). It is the longest step in the pipeline, for 16S metabarcoding 20 samples ~6 hours, 65 samples ~22 hours.

Parameters:
  * --p-trim-left m trims the first 'm' bases (cut off bases before 'm')
  * --p-trunc-len n truncates each sequence at position 'n' (cut off bases after 'n')

First, convert manifestout.qza to .qzv for visualization:
```py
    qiime demux summarize \
      --i-data manifestout.qza
      --o-visualization manifestout.qzv
```
* Use [Qiime Viewer](https://view.qiime2.org "Qiime2 .qzv Viewer") to view .qzv files and select values for 'm' and 'n' according to drop-off in quality.

Single-end reads:
```py
    qiime dada2 denoise-single \
      --i-demultiplexed-seqs manifestout.qza \
      --p-trim-left m \
      --p-trunc-len n \
      --o-representative-sequences dada2.qza \
      --o-table dada2-table.qza \
      --o-denoising-stats denoise-stats.qza
```
Paired-end reads:
```py
    qiime dada2 denoise-paired \
      --i-demultiplexed-seqs manifestout.qza \
      --p-trim-left-f m \
      --p-trim-left-r x \
      --p-trunc-len-f n \
      --p-trunc-len-r y \
      --o-table dada2-table.qza \
      --o-representative-sequences dada2.qza \
      --o-denoising-stats denoise-stats.qza
```
* "Feature Table" (dada2-table.qza) contains counts (frequency) of each unique sequence in each sample.
* "Feature Data" (dada2.qza) maps feature identifiers in dada2-table to the sequences they represent.

Make [metadata.tsv](https://docs.qiime2.org/2018.11/tutorials/metadata/ "Instructions to Create Qiime2 Metadata File") and verify with [Keemei](https://keemei.qiime2.org/ "Keemei") by uploading metadata file to [Google Sheets](https://docs.google.com/spreadsheets/ "Google Sheets").

* First column must be sample ID
* First row must be column headers
* All columns must have headers

---


##### Summarize Feature Table:
```py
      qiime feature-table summarize \
        --i-table dada2-table.qza \
        --o-visualization feature-table.qzv \
        --m-sample-metadata-file sample-metadata.tsv
```
---
>##### Merge Denoised Datasets (if working with sequences from multiple sequencing runs)
>
>DADA2 can only denoise samples from a single sequencing run. To include multiple runs, denoise each separately and merge with technique in fecal microbiome tutorial.
>
>First merge FeatureTable, then FeatureData
```py
    qiime feature-table merge \
      --i-tables dada2-table-1.qza \
      --i-tables dada2-table-2.qza \
      --o-merged-table dada2-table-merged.qza
```
>
>```py
    qiime feature-table merge-seqs \
      --i-data dada2-1.qza \
      --i-data dada2-2.qza \
      --o-merged-data dada2-merged.qza
```
>
---
## IV. ASSIGN TAXONOMY
If you do not have a classifier.qza trained to your specific primers and the taxanomic database you want to reference, see "Train a Feature Classifier" at the bottom of this walkthrough.

```py
    qiime feature-classifier classify-sklearn \
      --i-classifier classifier.qza \
      --i-reads dada2.qza \
      --o-classification taxonomy.qza
```
```py
    qiime metadata tabulate \
      --m-input-file taxonomy.qza \
      --o-visualization taxonomy.qzv
```
---
## V. Analyze Taxanomic Data
##### TAXONOMY BARPLOT
```py
    qiime taxa barplot \
      --i-table dada2-table.qza \
      --i-taxonomy taxonomy.qza \
      --m-metadata-file metadata.tsv \
      --o-visualization taxa-bar-plots.qzv
```
##### FEATURE-TABLE FEATURE
Feature-table "summarize" provides info on abundance and distribution of sequences per sample/feature
```py
    qiime feature-table summarize \
      --i-table dada2-table.qza \
      --o-visualization dada2-table.qzv \
      --m-sample-metadata-file metadata.tsv
```
Feature-table "tabulate-seqs" maps feature-IDs to sequences and provides NCBI links for [BLAST](https://blast.ncbi.nlm.nih.gov/Blast.cgi?PROGRAM=blastn&PAGE_TYPE=BlastSearch&LINK_LOC=blasthome "NCBI Nucleotide BLAST")

```py
    qiime feature-table tabulate-seqs \
      --i-data dada2.qza \
      --o-visualization featureID.qzv
```
##### PHYLOGENETIC TREE
Align sequences:
```py
    qiime alignment mafft \
      --i-sequences dada2.qza \
      --o-alignment aligned.qza
```
"Mask" (filter) alignment to remove noise:
```py
    qiime alignment mask \
      --i-alignment aligned.qza \
      --o-masked-alignment masked.qza
```
Create Unrooted phylogenetic tree:
```py
    qiime phylogeny fasttree \
      --i-alignment masked.qza \
      --o-tree unrooted-tree.qza
```
Root tree according to midpoint of longest tip-to-tip distance in unrooted tree:
```py
    qiime phylogeny midpoint-root \
      --i-tree unrooted-tree.qza \
      --o-rooted-tree rooted-tree.qza
```
---
## ALPHA AND BETA DIVERSITY INDICES

* "Emperor" output files create maneuverable PCoA plots in [Qiime2 Viewer](https://view.qiime2.org/ "Qiime2 Viewer, same for emperor and .qzv files").

##### FIRST: Create Alpha/Beta Diversity files for basis of analysis:
* Output files in new directory 'core-metrics-results'.

Sample-depth parameter:
* Each sample is subsampled to predetermined count and samples with fewer reads are dropped.
* Choose sample depth based on dada2-table.qzv "interactive sample detail".

```py
    qiime diversity core-metrics-phylogenetic \
       --i-phylogeny rooted-tree.qza \
       --i-table dada2-table.qza \
       --p-sampling-depth SampleDepthValue \
       --m-metadata-file metadata.tsv \
       --output-dir core-metrics-results
```

#### ALPHA
"Associations between categorical metadata columns and alpha diversity."

* Shannon's diversity index - quantitative measure of community richness
* Observed OTUs - qualitative measure of community richness
* Faith's phylogenetic diversity (PD) - qualitative measure of community richness incorporating phylogenetic relationships
* Evenness (Pielou's evenness) - measure of community evenness

Visualize Faith's PD with metadata:
```py
    qiime diversity alpha-group-significance \
      --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
      --m-metadata-file metadata.tsv \
      --o-visualization core-metrics-results/faith-pd-group-significance.qzv
```
Visualize evenness with metadata:
```py
    qiime diversity alpha-group-significance \
      --i-alpha-diversity core-metrics-results/evenness_vector.qza \
      --m-metadata-file metadata.tsv \
      --o-visualization core-metrics-results/evenness-group-significance.qzv
```
#### BETA - PERMANOVA
* Jaccard distance - qualitative measure of dissimilarity
* Bray-Curtis distance - quantitative measure of community dissimilarity
* Unweighted UniFrac distance - a qualitative measure of community dissimilarity incorporating phylogenetic relationships
* Weighted UniFrac distance - quantitative measure of community dissimilarity incorporating phylogenetic relationships


Choose metadata category header to analyze.
* --p-pairwise is an optional parameter to add pairwise analysis

```py
    qiime diversity beta-group-significance \
      --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
      --m-metadata-file metadata.tsv \
      --m-metadata-column Category \
      --o-visualization core-metrics-results/unweighted-unifrac-body-site-significance.qzv \
      --p-pairwise
```
#### Continuous Sample Metadata (ie Time)
Alpha

To correlate continuous sample metadata with alpha diversity use the qiime diversity alpha-correlation command.

Beta

To correlate continuous sample metadata with sample composition use the qiime metadatadistance-matrix in combination with qiime diversity mantel and qiime diversity bioenv commands.

#### Ordination (PCoA plots)
* --p-custom-axes parameter defines MDS axes and can accomodate time as a variable, e.g. "DaysSinceExperimentStart" (used here, but optional)

Unweighted UniFrac PCoA:
```py
    qiime emperor plot \
      --i-pcoa core-metrics-results/unweighted_unifrac_pcoa_results.qza \
      --m-metadata-file metadata.tsv \
      --p-custom-axes DaysSinceExperimentStart \
      --o-visualization core-metrics-results/unweighted-unifrac-emperor-DaysSinceExperimentStart.qzv
```
Bray-Curtis Dissimilarty PCoA:
```py
    qiime emperor plot \
      --i-pcoa core-metrics-results/bray_curtis_pcoa_results.qza \
      --m-metadata-file metadata.tsv \
      --p-custom-axes DaysSinceExperimentStart \
      --o-visualization core-metrics-results/bray-curtis-emperor-DaysSinceExperimentStart.qzv
```
#### RAREFACTION (ALPHA)
* optional parameters --p-min-depth and --p-max-depth

```py
    qiime diversity alpha-rarefaction \
      --i-table dada2-table.qza \
      --i-phylogeny rooted-tree.qza \
      --p-max-depth MedianFrequency \
      --m-metadata-file metadata.tsv \
      --o-visualization alpha-rarefaction.qzv
```

Top plot shows alpha rarefaction ie whether increased sampling depth would observe higher species richness.

Bottom plot shows number of samples remaining in each group (eg colony) if sample-depth were set to x.

---
## TRAIN A FEATURE CLASSIFIER FOR TAXANOMIC ANALYSIS

* More instructions for feature classifier training [here](https://docs.qiime2.org/2018.11/tutorials/feature-classifier/ "Feature classifier training from Qiime2 docs")

Import references
  (I used [Silva](https://www.arb-silva.de/documentation/release-132/ "Silva version 132")) 99% for 16S but there are many other databases to choose):

```py
    qiime tools import \
      --type 'FeatureData[Sequence]' \
      --input-path silva_132_99_16S.fa \
      --output-path OTUs.qza
```
Break OTUs down into taxanomic levels:
```py
    qiime tools import \
      --type 'FeatureData[Taxonomy]' \
      --source-format HeaderlessTSVTaxonomyFormat \
      --input-path taxonomy_7_levels.txt \
      --output-path ref-taxonomy.qza
```
Extract Reference Reads

* This command is for primer set 341F-785R (16S rRNA V3 and V4 - bacteria/archaea)

##### *You must use your specific primer sequences!*

* Takes about 15 minutes to run

```py
    qiime feature-classifier extract-reads \
      --i-sequences OTUs.qza \
      --p-f-primer CCTACGGGNGGCWGCAG \
      --p-r-primer GACTACHVGGGTATCTAATCC \
      --p-trunc-len 444 \
      --o-reads ref-seqs.qza
```
Train the Classifier (takes several hours to run)

```py
    qiime feature-classifier fit-classifier-naive-bayes \
      --i-reference-reads ref-seqs.qza \
      --i-reference-taxonomy ref-taxonomy.qza \
      --o-classifier classifier.qza
```
---
---
## Qiime --help

    QIIME 2 command-line interface (q2cli)
     --------------------------------------

     To get help with QIIME 2, visit https://qiime2.org.

     To enable tab completion in Bash, run the following command or add it to
     your .bashrc/.bash_profile:

         source tab-qiime

     To enable tab completion in ZSH, run the following commands or add them to
     your .zshrc:

         autoload bashcompinit && bashcompinit && source tab-qiime

    Options:
     --version  Show the version and exit.
     --help     Show this message and exit.

    Commands:
     info                Display information about current deployment.
     tools               Tools for working with QIIME 2 files.
     dev                 Utilities for developers and advanced users.
     alignment           Plugin for generating and manipulating alignments.
     composition         Plugin for compositional data analysis.
     cutadapt            Plugin for removing adapter sequences, primers, and
                         other unwanted sequence from sequence data.
     dada2               Plugin for sequence quality control with DADA2.
     deblur              Plugin for sequence quality control with Deblur.
     demux               Plugin for demultiplexing & viewing sequence quality.
     diversity           Plugin for exploring community diversity.
     emperor             Plugin for ordination plotting with Emperor.
     feature-classifier  Plugin for taxonomic classification.
     feature-table       Plugin for working with sample by feature tables.
     gneiss              Plugin for building compositional models.
     longitudinal        Plugin for paired sample and time series analyses.
     metadata            Plugin for working with Metadata.
     phylogeny           Plugin for generating and manipulating phylogenies.
     quality-control     Plugin for quality control of feature and sequence data.
     quality-filter      Plugin for PHRED-based filtering and trimming.
     sample-classifier   Plugin for machine learning prediction of sample
                         metadata.
     taxa                Plugin for working with feature taxonomy annotations.
     vsearch             Plugin for clustering and dereplicating with vsearch.

  ---
  ---
