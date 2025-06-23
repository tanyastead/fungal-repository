# ui.R
ui <- fluidPage(
  titlePanel("Fungal Transcriptomic Database"),
  br(),
  fluidRow(
    column(
      width = 12,  # Full width
      wellPanel(
        fluidRow(
          column(4, textInput("query", NULL, placeholder = "Enter search text...")),
          column(4, selectInput("term", NULL, choices = c("Gene (Name or Function)", "Keyword"))),
          column(4, actionButton("search", "Search"))
        )
      )
    )
  ),
  # fluidRow(
  #   column(4, textInput("query", NULL, placeholder = "Enter search text...")),
  #   column(4, selectInput("term", NULL, choices = c("Gene (Name or Function)", "Keyword"))),
  #   column(4, actionButton("search", "Search"))
  #   ),
  # br(),
  sidebarPanel(
    strong("Refine output:"),
    selectizeInput("refineSpecies", 
                   NULL, 
                   choices = queriedSpecies$species, 
                   multiple = TRUE, 
                   options = list(placeholder = "Enter species...")),
    selectizeInput("refineCondition", 
                   NULL, 
                   choices = keywords, 
                   multiple = TRUE, 
                   options = list(placeholder = "Enter condition...")),
    br(),
    tags$h6("From:"),
    textInput("fromYear", NULL, placeholder = "Year..."),
    tags$h6("To:"),
    textInput("toYear", NULL, placeholder = "Year..."),
    br(),
    actionButton("export", "Export Table", icon = icon("download"))
    
  ),
  mainPanel(
    textOutput("message"),
    textOutput("speciesMessage"),
    textOutput("keywordMessage")
  ),
  br(),
  

  
  
  # sidebarLayout(
  #   sidebarPanel(
  #     selectInput("table", "Select Table", choices = tables),
  #     textInput("id", "", placeholder = "enter abiotic id")
  #   ),
  #   mainPanel(
  #     tableOutput("tableData"),
  #     plotOutput("tablePlot"),
  #     tableOutput("queryData")
  #   )
  # )
)
