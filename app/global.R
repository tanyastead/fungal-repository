# global.R
library(shiny)
library(DBI)
library(RSQLite)

# Connect to database
con <- dbConnect(SQLite(), "/Users/tanyastead/Documents/MSc_Bioinformatics/11_Individual_Project/fungal-repository/database/repository.sqlite")

# Show list of tables
tables <- dbListTables(con)

