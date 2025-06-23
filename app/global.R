# global.R
library(shiny)
library(DBI)
library(RSQLite)
library(DT)

# Connect to database
con <- dbConnect(SQLite(), "/Users/tanyastead/Documents/MSc_Bioinformatics/11_Individual_Project/fungal-repository/database/repository.sqlite")

# Show list of tables
tables <- dbListTables(con)

# Show list of all species
queriedSpecies <- dbGetQuery(con, "SELECT DISTINCT species FROM Genes")

# Show list of all keywords
keywords <- dbGetQuery(con, "SELECT DISTINCT keyword FROM ExpKeywords")
