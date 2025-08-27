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
library(rlist)
library(shinydashboard)
library(shinyFeedback)
library(reticulate)
library(jsonlite)
library(bsicons)
library(tippy)

# Set working directory
setwd("/Users/tanyastead/Documents/MSc_Bioinformatics/11_Individual_Project/fungal-repository/")

# Source functions
source("app/plots.R")

# Connect to database
con <- dbConnect(SQLite(), "database/repository.sqlite")

# Show list of tables
tables <- dbListTables(con)

# Show list of all species
queriedSpecies <- dbGetQuery(con, "SELECT DISTINCT species FROM Genes")

# Show list of all keywords
keywords <- dbGetQuery(con, "SELECT DISTINCT keyword FROM ExpKeywords")

# Show list of all authors
authors <- dbGetQuery(con, "SELECT DISTINCT author FROM Experiments")


# Define theme
my_theme <- bs_theme(
  version = 5,
  bg = "#f8f9fa",       
  fg = "#000",          
  primary = "#0066cc"   
)