# global.R
library(shiny)
library(DBI)
library(RSQLite)
library(DT)
library(dplyr)
library(stringr)
library(ggplot2)
library(gridExtra)
library(plotly)
library(bslib)

# Connect to database
con <- dbConnect(SQLite(), "/Users/tanyastead/Documents/MSc_Bioinformatics/11_Individual_Project/fungal-repository/database/repository.sqlite")

# Show list of tables
tables <- dbListTables(con)

# Show list of all species
queriedSpecies <- dbGetQuery(con, "SELECT DISTINCT species FROM Genes")

# Show list of all keywords
keywords <- dbGetQuery(con, "SELECT DISTINCT keyword FROM ExpKeywords")

# Show list of all genes
# queriedGenes <- dbGetQuery(con, paste0("SELECT DISTINCT gene_id FROM GeneContrasts WHERE contrast = '", selectedContrast, "';"))
