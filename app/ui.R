# ui.R
ui <- fluidPage(
  titlePanel("Fungal Transcriptomic Database"),
  navset_tab(id = "navMenu",
    nav_panel(title = "Search",
              #TODO: move the search section to the middle of the page!
              br(), 
              fluidRow(
                  column(4, textInput("query", NULL, placeholder = "Enter search text...")),
                  column(4, selectInput("term", NULL, choices = c("Gene (Name or Function)", "Keyword"))),
                  column(4, actionButton("search", "Search"))
                  )),
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
                actionButton("clearResults", "Clear"),
                actionButton("exportResults", "Export Table", icon = icon("download"))
                
              ),
              mainPanel(
                DTOutput("tableData"),
                textOutput("speciesMessage"),
                textOutput("keywordMessage"),
                textOutput("fromYearMessage"),
                textOutput("toYearMessage")
              )
            ),
    nav_panel(title = "Experiments",
              fluidRow(
                column(
                  width = 12,
                  div(
                    style = "background-color: #f0f0f0; padding: 10px; margin-bottom: 10px;",
                    h4("Experiment Summary"),
                    textOutput("experimentAuthorYear"),
                    uiOutput("experimentDescription"),
                    textOutput("experimentContrast")
                  )
                )
              ),
              sidebarPanel(
                strong("Refine output:"),
                selectizeInput("refineGene",
                               NULL,
                               choices = NULL,
                               multiple = TRUE,
                               options = list(placeholder = "Enter gene...")),
                # refine output - gene function??
                numericInput("pvalue",
                             "p-value <",
                             value = NULL,
                             min = 0,
                             max = 1,
                             step = 0.01),
                numericInput("padj",
                             "p-adjusted <",
                             value = NULL,
                             min = 0,
                             max = 1,
                             step = 0.01),
                numericInput("lFC",
                             HTML("Log<sub>2</sub>-fold change"),
                             value = NULL,
                             step = 0.1,
                             min = 0),
                radioButtons("lFCRegulation",
                             NULL,
                             choices = c("Up- or Downregulated", "Upregulated only", "Downregulated only")),
                br(),
                actionButton("clearExperiments", "Clear"),
                actionButton("exportExperiments", "Export Table", icon = icon("download"))
              ),
              mainPanel(
                DTOutput("experimentTable"),
                textOutput("testMessage")
                )
              ),
    nav_panel(title = "Plots",
              ),
    )
)