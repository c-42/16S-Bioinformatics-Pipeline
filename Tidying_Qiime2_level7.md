---
output:
  pdf_document: default
  html_document: default
---
## Tidying Qiime2

This is to convert the .csv output file from Qiime2 taxa-barplots.qzv into Tidy format.

* Written for "level-7 Species.csv" output file but can be amended for other levels.

```{r}
library(tidyr)
```

#### 1. Turn taxanomic classification headers into a column

Make sure to replace the first and last column headers in the script with those in your file.

```{r}
lvl7.1 <- level.7.Species %>%
  gather(D_0__Archaea.D_1__Crenarchaeota.D_2__Bathyarchaeia.D_3__marine.metagenome.D_4__marine.metagenome.D_5__marine.metagenome.D_6__marine.metagenome:Unassigned.__.__.__.__.__.__, key = "Taxonomy", value = "Reads")
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
lvl7.Tidy <- lvl7.3 %>%
  gather(Kingdom:Species, key = "Taxanomic Level", value = "Feature Classification")
```

### *fin*
