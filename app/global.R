# global.R

# Load libraries
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
library(purrr)
library(xml2)
library(shinyjs)

# Source functions
source("/Users/tanyastead/Documents/MSc_Bioinformatics/11_Individual_Project/fungal-repository/app/plots.R")

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

# Define theme
# Define your custom theme
my_theme <- bs_theme(
  version = 5,
  bg = "#f8f9fa",       # Background of the whole page
  fg = "#000",          # Text color
  primary = "#0066cc"   # This sets the navbar/tab highlight color
)