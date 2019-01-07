## Tidying Qiime2

This is to convert the .csv output file from Qiime2 taxa-barplots.qzv into Tidy format.

* Written for "level-7 Species.csv" output file from view.Qiime2 but can be amended for other levels.

*Note: While Qiime2 output file presents read counts, I normalized these (TSS) in excel after removing all OTUs with total read count of 5 or less before importing to R. The .csv import file is otherwise formatted the same way as is presented by Qiime2 pipeline.*

```{r}
library(tidyverse)
```

#### 1. Turn taxanomic classification headers into a column

Make sure to replace the first and last column headers in the script with those in your file.

```{r}
lvl7.1 <- lvl7.norm %>%
  gather(D_0__Bacteria.D_1__Acidobacteria.D_2__AT.s3.28.D_3__uncultured.bacterium.D_4__uncultured.bacterium.D_5__uncultured.bacterium.D_6__uncultured.bacterium:D_0__Bacteria.__.__.__.__.__.__, key = "Taxonomy", value = "TSS")
```

#### 2. Put taxanomic levels into separate columns

```{r}
lvl7.2 <- lvl7.1 %>%
  separate(Taxonomy, c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species"), sep = ".D_")
```

#### 3. Remove prefixes from names

```{r}
library(magrittr)
library(stringr)
```

```{r}
lvl7.3 <- lvl7.2 %>%
  transform(Kingdom=str_replace(Kingdom, "D_0__", "")) %>%
  transform(Phylum=str_replace(Phylum, "1__", "")) %>%
  transform(Class=str_replace(Class, "2__", "")) %>%
  transform(Order=str_replace(Order, "3__", "")) %>%
  transform(Family=str_replace(Family, "4__", "")) %>%
  transform(Genus=str_replace(Genus, "5__", "")) %>%
  transform(Species=str_replace(Species, "6__", ""))
```

#### 4. Gather taxanomic levels into single column

```{r}
lvl7.4 <- lvl7.3 %>%
  gather(Kingdom:Species, key = "Level", value = "Classification")
```

#### 5. Remove excess ".__" on taxanomic classifications for streamlining

```{r}
Tidy <- lvl7.4 %>%
  transform(Classification=str_replace_all(Classification, ".__", ""))
```


### *fin*
