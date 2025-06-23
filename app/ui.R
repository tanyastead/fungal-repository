# ui.R
ui <- fluidPage(
  titlePanel("Fungal Transcriptomic Database"),
  navset_tab(
    nav_panel(title = "Search", 
              p("First tab content.",
              fluidRow(
                  column(4, textInput("query", NULL, placeholder = "Enter search text...")),
                  column(4, selectInput("term", NULL, choices = c("Gene (Name or Function)", "Keyword"))),
                  column(4, actionButton("search", "Search"))
                  ))),
    nav_panel(title = "Results", 
              p("Second tab content."),
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
                DTOutput("tableData"),
                textOutput("message"),
                textOutput("speciesMessage"),
                textOutput("keywordMessage"),
                textOutput("fromYearMessage"),
                textOutput("toYearMessage")
              )
            ),
    )
)