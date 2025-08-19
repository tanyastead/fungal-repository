library(rtracklayer)
library(magrittr)
library(dplyr)

gff <- import("/Users/tanyastead/Documents/MSc_Bioinformatics/11_Individual_Project/fungal-repository/database/DEG_Data/Ding_2024/ncbi_dataset_Fvert/ncbi_dataset/data/GCF_000149555.1/genomic.gff", format = "gff")

# Filter for mRNA features
mrnas <- gff[gff$type == "mRNA"]
genes <- gff[gff$type == "gene"]

# Check available fields
head(mcols(mrnas))
head(mcols(genes))

# Get gene ID (from 'Parent') and functional annotation (from 'product')
df <- data.frame(
  transcript_id = mrnas$ID,
  gene_id = mrnas$locus_tag,
  product = mrnas$product,
  stringsAsFactors = FALSE
)


# Remove rows without annotation
df <- df[!is.na(df$product), ]

# If multiple mRNAs per gene, choose one (e.g., first)
df_unique <- df %>%
  group_by(gene_id) %>%
  slice(1) %>%  # You can also use slice_max(n = 1, order_by = nchar(product)) to pick the longest annotation
  ungroup()



write.csv(df_unique[, 2:3],
          "/Users/tanyastead/Documents/MSc_Bioinformatics/11_Individual_Project/fungal-repository/database/DEG_Data/Ding_2024/functional_annot.csv",
          row.names = F)
