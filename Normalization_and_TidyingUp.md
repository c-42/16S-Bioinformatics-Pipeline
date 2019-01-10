# Normalization and Tidying up of Qiime2 Output Data

This is to convert the .csv output file from Qiime2 taxa-barplots.qzv into Tidy format.

* Written for "level-7 Species.csv" output file from view.Qiime2 but can be amended for other levels.

Before Normalization we need to remove OTUs which will not be counted as part of the bacterial community, including Archaea and Chloroplast reads as well as artefacts which here I consider anything with 5 or less reads but the cutoff is somewhat arbitrary. We will also remove samples which do not meet our sampling depth threshold of 8800 reads, as chosen in Qiime2 pipeline.

```{r}
library(tidyverse)
library(stringr)
library(magrittr)
```

The output .csv table from Qiime2 is set up as such:


|index|OTU_1|OTU_2|OTU_3|metadataA|metadataB|
|:---:|:---:|:---:|:---:|:---:|:---:|
|sample_1|#|#|#|A|B|
|sample_2|#|#|#|A|B|


## Filtering Raw Data

First we move 'index' to the end so that the next few steps are more practical.

```{r}
Filter.1 <- level.7.Species %>% select(-1,1)
```

Then remove samples which are below the threshold of 8800 reads (make sure column range reflects OTUs in your dataframe):

```{r}
SampleReads <- rowSums(Filter.1[,1:1448])
Samples_less8800 <- which(SampleReads<8800)
Filter.2 <- Filter.1[-Samples_less8800,]
```

And OTUs which are below the minimum total read count of 5:

```{r}
OTUreads <- colSums(Filter.2[1:1448])
OTUs_less6 <- which(OTUreads<6)
Filter.3 <- Filter.2[,-OTUs_less6]
```

Last we will remove unwanted OTUs from the community, in this case Archaea and Chloroplasts which are not components of the bacterial community.

```{r}
Filtered <- Filter.3 %>%
  .[, -grep("Archaea", colnames(.))] %>%
  .[, -grep("Chloroplast", colnames(.))]
```

## Normailization

Normalization of high-throughput sequencing on microbiome data is best done by total sum standardization (TSS) (McKnight et al. 2018. "Methods for normalizing microbiome data: An ecological perspective." *Methods in Ecology and Evolution*.

```{r}
Normalized <- Filtered %>%
  add_column("sums" = rowSums(.[,1:1104])) %>%
  gather(1:1104, key = "Taxonomy", value = "Reads") %>%
  transmute(index, Colony, Layer, Taxonomy, TSS=Reads/sums)
```

## Untidy, Tidy and Plots

We will produce two workind datasheets, 1 which is technically not tidy but necessary to maintain relationships between taxanomic levels, and one which is tidy. Transformations remove all the excess punctiation from Qiime2 headers.

```{r}
Un.Tidy <- Normalized %>%
  separate(Taxonomy, c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species"), sep = ".D_") %>%
  transform(Kingdom=str_replace(Kingdom, "D_0__", "")) %>%
  transform(Phylum=str_replace(Phylum, "1__", "")) %>%
  transform(Class=str_replace(Class, "2__", "")) %>%
  transform(Order=str_replace(Order, "3__", "")) %>%
  transform(Family=str_replace(Family, "4__", "")) %>%
  transform(Genus=str_replace(Genus, "5__", "")) %>%
  transform(Species=str_replace(Species, "6__", "")) %>%
  transform(Kingdom=str_replace_all(Kingdom, ".__", "")) %>%
  transform(Phylum=str_replace_all(Phylum, ".__", "")) %>%
  transform(Class=str_replace_all(Class, ".__", "")) %>%
  transform(Order=str_replace_all(Order, ".__", "")) %>%
  transform(Family=str_replace_all(Family, ".__", "")) %>%
  transform(Genus=str_replace_all(Genus, ".__", "")) %>%
  transform(Species=str_replace_all(Species, ".__", ""))

write_rds(Un.Tidy, "cache/Un.Tidy.rds", compress = "none")
```

```{r}
Tidy <- Un.Tidy %>%
  gather(Kingdom:Species, key = "Level", value = "Classification")

write_rds(Un.Tidy, "cache/Tidy.rds", compress = "none")
```
### *fin*




---
title: "Normalization_and_TidyingUp"
output: pdf
---
