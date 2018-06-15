# Navigation Syntax
* __pwd__ - *"print working directory" presents pathway of current active directory*
* __ls__ - *lists the files and folders in working directory*
  - __ls -l__ *lists in single column*
* __cd__ - *"change directory" navigates to new folder*
  - __cd ..__ - *steps up one level in directory path*
* __mkdir__ - *make new folder in working directory*
* __rename__ - *rename file or folder*
* __mv__ - *move file or folder*
* __scp__ - *secure copy*
* __rm__ - *delete file or folder*
* __less filename.ext__ - *opens file in command line*
  - __-s__ - *turns on line wrap*
  - __q__ - *exits*
* __top__ - *lists all commands running on HPC and memory usage statistics in real time*
* __Ctrl+C__ - *kill command*

# JCU HPC Syntax
* *To log in:*

      ssh jcNUMBER@zodiac.hpc.jcu.edu.au
      ssh jcNUMBER@genomcs2.hpc.jcu.edu.au
*     *Your home address is:*

__/home5/34/jcNUMBER/__

* *Copy file from local directory to HPC*

      scp filename jcNUMBER@zodiac.hpc.jcu.edu.au:~/
*     *Copy file from HPC to local directory*

      scp jcNUMBER@zodiac.hpc.jcu.edu.au:~/filename .

* Use __-nohup__ "no hangup" as parameter to prevent HPC connection time-out while command is being executed.


# QIIME 2
* To launch Qiime 2 from JCU HPC:
      source activate qiime2-2018.2

*     Qiime2 Tutorials: https://docs.qiime2.org/2018.2/
* Walkthrough for demultiplexed sequences: https://github.com/BikLab/BITMaB2-Tutorials/blob/master/QIIME2-metabarcoding-tutorial-already-demultiplexed-fastqs.md
* commands are the same for .fastq (decompressed) and fastq.gz (compressed) files


# CREATE MANIFEST
* Compiles demultiplexed reads into a single .qza for quality control
* Create comma-separated text file (.csv) with the following columns:
    1. sample identifier
    2. absolute filepath
    3. read direction
* The first line must be a header line
* For single-end reads, 1 line per sample; for paired-end, 2 lines per sample
* *Format as single-end reads if there is no read overlap*

      sample-id,absolute-filepath,direction
      sample-1,$PWD/some/filepath/sample1_R1.fastq.gz,forward
      sample-2,$PWD/some/filepath/sample2_R1.fastq.gz,forward
      sample-1,$PWD/some/filepath/sample1_R2.fastq.gz,reverse
      sample-2,$PWD/some/filepath/sample2_R2.fastq.gz,reverse

*The manifest file is a comma-separated (i.e., .csv) text file. The first field on each line is the sample identifier that should be used by QIIME, the second field is the absolute filepath, and the third field is the read direction. Lines beginning with # and blank lines are ignored. The first line in the file that does not begin with a # and is not blank must be the header line: __sample-id,absolute-filepath,direction__. With the exception of the header line, the order of lines in this file is not important.
For single-end reads, there must be exactly one line per sample id corresponding to either the forward or reverse reads. For paired-end reads there must be exactly two lines per sample id, corresponding to the forward and the reverse reads. The direction field on each line can only contain the text forward or reverse.*

# IMPORT DATA
* Import as Phred33 (Illumina 1.8 = Phred offset of 33)

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
* DADA2 can only denoise samples from a single sequencing run, to include multiple runs, denoise each separately and merge with technique in fecal microbiome tutorial

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

*DADA2 is a pipeline for detecting and correcting (where possible) Illumina amplicon sequence data. As implemented in the q2-dada2 plugin, this quality control process will additionally filter any phiX reads (commonly present in marker gene Illumina sequence data) that are identified in the sequencing data, and will filter chimeric sequences.
The dada2 denoise-single method requires two parameters that are used in quality filtering: __--p-trim-left m__, which trims off the first m bases of each sequence, and __--p-trunc-len n__ which truncates each sequence at position n. This allows the user to remove low quality regions of the sequences. To determine what values to pass for these two parameters, you should review the Interactive Quality Plot tab in the manifestout.qzv file that was generated by qiime demux summarize above.*

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
* Build metadata.tsv file (https://docs.qiime2.org/2018.2/tutorials/metadata/)
* Feature-table summarize provides info on abundance and distribution of sequences per sample/feature
* Feature-table tabulate-seqs maps featureIDs to sequences and provides NCBI links for BLAST

      qiime feature-table summarize \
        --i-table dada2-table.qza \
        --o-visualization dada2-table.qzv \
        --m-sample-metadata-file metadata.tsv

      qiime feature-table tabulate-seqs \
        --i-data dada2.qza \
        --o-visualization featureID.qzv

*The feature-table summarize command will give you information on how many sequences are associated with each sample and with each feature, histograms of those distributions, and some related summary statistics. The feature-table tabulate-seqs command will provide a mapping of feature IDs to sequences, and provide links to easily BLAST each sequence against the NCBI nt database.*

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

*QIIME 2’s diversity analyses are available through the q2-diversity plugin, which supports computing alpha and beta diversity metrics, applying related statistical tests, and generating interactive visualizations. We’ll first apply the core-metrics-phylogenetic method, which rarefies a FeatureTable[Frequency] to a user-specified depth, computes several alpha and beta diversity metrics, and generates principle coordinates analysis (PCoA) plots using Emperor for each of the beta diversity metrics.*

*An important parameter that needs to be provided to this script is __--p-sampling-depth__, which is the even sampling (i.e. rarefaction) depth. Because most diversity metrics are sensitive to different sampling depths across different samples, this script will randomly subsample the counts from each sample to the value provided for this parameter. For example, if you provide --p-sampling-depth 500, this step will subsample the counts in each sample without replacement so that each sample in the resulting table has a total count of 500. If the total count for any sample(s) are smaller than this value, those samples will be dropped from the diversity analysis. Choosing this value is tricky. We recommend making your choice by reviewing the information presented in the dada2-table.qzv file that was created above and choosing a value that is as high as possible (so you retain more sequences per sample) while excluding as few samples as possible.*

#### ALPHA - associations between categorical metadata columns and alpha diversity
* __Shannon's Diversity Index__ - quantitative measure of community richness
* __Observed OTUs__ - qualitative measure of community richness
* __Faith's Phylogenetic Diversity Index__ - qualitative measure of community richness incorporating phylogenetic relationships
* __Evenness (Pielou's Evenness)__ - measure of community evenness

      qiime diversity alpha-group-significance \
        --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
        --m-metadata-file metadata.tsv \
        --o-visualization core-metrics-results/faith-pd-group-significance.qzv

      qiime diversity alpha-group-significance \
        --i-alpha-diversity core-metrics-results/evenness_vector.qza \
        --m-metadata-file metadata.tsv \
        --o-visualization core-metrics-results/evenness-group-significance.qzv

*Next we’ll analyze sample composition in the context of categorical metadata using PERMANOVA (first described in Anderson (2001)) using the beta-group-significance command. The following commands will test whether distances between samples within a group, such as samples from the same body site (e.g., gut), are more similar to each other then they are to samples from the other groups (e.g., tongue, left palm, and right palm). If you call this command with the __--p-pairwise__ parameter, as we’ll do here, it will also perform pairwise tests that will allow you to determine which specific pairs of groups (e.g., tongue and gut) differ from one another, if any. This command can be slow to run, especially when passing --p-pairwise, since it is based on permutation tests. So, unlike the previous commands, we’ll run this on specific columns of metadata that we’re interested in exploring, rather than all metadata columns that it’s applicable to. Here we’ll apply this to our unweighted UniFrac distances, using two sample metadata columns, as follows.*

####  BETA - PERMANOVA
* __Jaccard Distance__ - qualitative measure of dissimilarity
* __Bray-Curtis Distance__ - quantitative measure of community dissimilarity
* __Unweighted UniFrac Distance__ - a qualitative measure of community dissimilarity incorporating phylogenetic relationships
* __Weighted UniFrac Distance__ - quantitative measure of community dissimilarity incorporating phylogenetic relationships
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

*Ordination is a popular approach for exploring microbial community composition in the context of sample metadata. We can use the Emperor tool to explore principal coordinates (PCoA) plots in the context of sample metadata. While our core-metrics-phylogenetic command did already generate some Emperor plots, we want to pass an optional parameter, __--p-custom-axes__, which is very useful for exploring time series data. The PCoA results that were used in core-metrics-phylogeny are also available, making it easy to generate new visualizations with Emperor. We will generate Emperor plots for unweighted UniFrac and Bray-Curtis so that the resulting plot will contain axes for principal coordinate 1, principal coordinate 2, and days since the experiment start. We will use that last axis to explore how these samples changed over time.*

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

*Explore alpha diversity as a function of sampling depth using the qiime diversity alpha-rarefactionvisualizer. This visualizer computes one or more alpha diversity metrics at multiple sampling depths, in steps between 1 (optionally controlled with --p-min-depth) and the value provided as --p-max-depth. At each sampling depth step, 10 rarefied tables will be generated, and the diversity metrics will be computed for all samples in the tables. The number of iterations (rarefied tables computed at each sampling depth) can be controlled with --p-iterations. Average diversity values will be plotted for each sample at each even sampling depth, and samples can be grouped based on metadata in the resulting visualization if sample metadata is provided with the --m-metadata-file parameter.
The value that you provide for --p-max-depth should be determined by reviewing the “Frequency per sample” information presented in the dada2-table.qzv file that was created above. In general, choosing a value that is somewhere around the median frequency seems to work well, but you may want to increase that value if the lines in the resulting rarefaction plot don’t appear to be leveling out, or decrease that value if you seem to be losing many of your samples due to low total frequencies closer to the minimum sampling depth than the maximum sampling depth.*


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
