#Plotting 16S Community Data

```{r}
library(tidyverse)
```

Retrieve chached "Tidy.rds" and "Un.Tidier.rds" data frames produced from "Normalization_and_TidyingUp.Rmd"
```{r}
Tidy <- read_rds("cache/Tidy.rds")
Un.Tidy <- read_rds("cache/Un.Tidy.rds")
```

---

#### To break down the samples and labels as referenced in this walkthrough:

My Tidy file is set up as such:

|index|Colony|Layer|Reads|TSS|Level|Classification|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|example|A|Inner|33254|0.2405736|Genus|Endozoicomonas|

Where:
index = Sample name
Colony = Individual colony the sample was collected from
Layer = Inner, core tissue ("IN"/"Inner"), Outer surface tissue ("OUT"/"Outer") or Mucous ("MUC"/"Mucous")
Reads = Total number of sequence reads in sample
TSS = "Total Sum Standardization" normalized proportion of each OTU in sample
Level = Taxanomic level to which the OTU was classified
Classification = Taxanomic assignment

Sample CWINA2 breaks down into CW-IN-A-2 where:
"CW" = My initials
"IN" = Inner tissue layer
"A" = Colony A
"2" = Biological replicate 2 out of 3 total collected from each colony (note that there is no correlation between triplicates, only colony, so "INA2" and "OUTA2" have no closer relation than "INA1" and "OUTA3")

---

### Removing Outliers:

My dadaset containes 3 known outliers which will be removed now.

CWINR1
```{r}
Tidy %>%
  filter(Level=="Class") %>%
  filter(Classification=="Campylobacteria") %>%
  filter(Layer=="Inner") %>%
  group_by(index, Layer) %>%
  summarise(TSS = sum(TSS)) %>%
  filter(TSS!=0)
```
CWOUTO2
```{r}
Tidy %>%
  filter(Level=="Class") %>%
  filter(Classification=="Bacteroidia") %>%
  filter(Layer=="Outer") %>%
  group_by(index, Layer) %>%
  summarise(TSS = sum(TSS)) %>%
  filter(TSS!=0) %>%
  arrange(desc(TSS))
```
CWOURS3
```{r}
Tidy %>%
  filter(Level=="Class") %>%
  filter(Classification=="Spirochaetia") %>%
  filter(Layer=="Outer") %>%
  group_by(index, Layer) %>%
  summarise(TSS = sum(TSS)) %>%
  filter(TSS!=0) %>%
  arrange(desc(TSS))
```


|Outliers to be removed:|
|Sample|Outlying Component|% of Sample Microbiome|
|:---:|:---:|:---:|
|CWINR1|Campylobacteria|45%|
|CWOUTO2|Bacteroidia|95%|
|CWOUTS3|Spirochaetia|80%|


```{r}
Tidier <- Tidy %>%
  filter(index!="CWINR1") %>%
  filter(index!="CWOUTO2") %>%
  filter(index!="CWOUTS3")
  
Un.Tidier <- Un.Tidy %>%
  filter(index!="CWINR1") %>%
  filter(index!="CWOUTO2") %>%
  filter(index!="CWOUTS3")
```

---

## Plotting with Tidy

#### Boxplot of the Genus Endozoicomonas across Layers

Tidy is arranged so that each sample is represented by one observation per taxanomic level (7) per OTU. You can therefore plot all taxanomic assignments of a specific level or all OTUs within a specific taxanomic assignment, but you cannot, for example, look at all Families within a Class. For that we will use Un.Tidy, which maintains relationships between levels.

Therefore, to look at the genus Endozoicomonas:

```{r}
Tidier %>%
  filter(Classification=='Endozoicomonas') %>%
  group_by(index, Layer) %>%
  summarise(TSS = sum(TSS)) %>%
  ggplot(aes(x=Layer, y=TSS)) + geom_boxplot() + scale_x_discrete(limits=c('Inner', 'Outer', 'Mucous'))
```

#### Jitter Plot of Classes across Layers
```{r}
Tidier %>% 
  filter(Level=="Phylum") %>%
  ggplot(aes(x=Layer, y=TSS)) + geom_jitter(aes(color=Classification)) + scale_x_discrete(limits=c('Inner', 'Outer', 'Mucous'))
```

Way too busy, filter to look at dominant Phyla (over 5% of community composition)
```{r}
Tidier %>% 
  filter(Level=="Phylum") %>%
  filter(TSS>.05) %>%
  na.omit %>%
  ggplot(aes(x=Layer, y=TSS)) + geom_jitter(aes(color=Classification)) + scale_x_discrete(limits=c('Inner', 'Outer', 'Mucous'))
```

The majority of dominant OTUs are within the Phylum Proteobacteria (will end up being Endozoicomonas)

## Plotting with Un.Tidy



#### Families of Gammaproteobacteria (over 1%)
```{r}
Un.Tidier %>% 
  filter(Class=="Gammaproteobacteria") %>%
  filter(TSS>.01) %>%
  ggplot(aes(x=Layer, y=TSS)) + geom_jitter(aes(color=Family)) + scale_x_discrete(limits=c('Inner', 'Outer', 'Mucous'))
```

#### Dominant Families of Gammaproteobacteria by Sample and Layer

```{r}
Un.Tidier %>% 
  filter(Class=="Gammaproteobacteria") %>%
  filter(TSS>.01) %>%
  ggplot(aes(x=Layer, y=index)) + geom_jitter(aes(size=TSS, color=Family)) + scale_x_discrete(limits=c('Inner', 'Outer', 'Mucous'))
```

