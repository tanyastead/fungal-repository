# ui.R
ui <- fluidPage(
  titlePanel("Fungal Transcriptomic Database"),
  navset_tab(id = "navMenu",
    nav_panel(title = "Search",
              #TODO: move the search section to the middle of the page!
              br(), br(),
              # fluidRow(
              #     column(4, textInput("query", NULL, placeholder = "Enter search text...")),
              #     column(4, selectInput("term", NULL, choices = c("Gene ID","Gene Function", "Keyword"))),
              #     column(4, actionButton("search", "Search"))
              #     )
              fluidRow(column(8, offset = 2,
                              
                        
                                  
                                  # Horizontal alignment using flexbox
                                  div(style = "display: flex; justify-content: space-between; align-items: center;",
                                      
                                      # Text Input
                                      div(style = "flex: 1; padding-right: 10px;margin-top: 15px;",
                                          textInput("query", NULL, placeholder = "Enter search text...", width = "100%")
                                      ),
                                      
                                      # Select Input
                                      div(style = "flex: 1; padding: 0 10px;margin-top: 15px;",
                                          selectInput("term", NULL,
                                                      choices = c("Gene ID", "Gene Function", "Keyword"),
                                                      width = "100%")
                                      ),
                                      
                                      # Search Button aligned using margin-top
                                      div(style = "flex: 1; padding-left: 10px;",
                                          div(style = "display: flex; align-items: center; height: 100%;",
                                              actionButton("search", "Search", 
                                                           
                                                           style = "width: 100%; margin-top: 0; line-height: 1.8;height: 38px;")
                                          )
                                      )
                                  )
                              
              ))
              ),
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
                downloadButton(outputId = "exportResults", label = "Export Table")
                
              ),
              mainPanel(
                DTOutput("tableData"),
                textOutput("speciesMessage"),
                textOutput("keywordMessage"),
                textOutput("fromYearMessage"),
                textOutput("toYearMessage"),
                verbatimTextOutput("troubleshootingCondition")
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
                # actionButton("exportExperiments", "Export Table", icon = icon("download"))
              ),
              mainPanel(
                navset_card_underline(
                  nav_panel("Data Table", 
                            # actionButton("exportExpTable", "Export Table", icon = icon("download"))
                            tags$div(
                              style = "text-align: right;",
                              downloadButton(
                                outputId = "exportExpTable", 
                                label = "Export Table", 
                                # class = "btn-primary"
                                # icon = icon("download"),
                                # style = "font-size: 14px; padding: 6px 12px;"  # Adjust size here
                              )
                            ),
                            br(),
                            DTOutput("experimentTable")),
                  nav_panel("Volcano Plot",
                            # actionButton("exportVolcano", "Export Plot", icon = icon("download")),
                            tags$div(
                              style = "text-align: right;",
                              downloadButton(
                                outputId = "exportVolcano", 
                                label = "Export Plot", 
                                # icon = icon("download"),
                                # style = "font-size: 14px; padding: 6px 12px;"  # Adjust size here
                              )
                            ),
                            br(),
                            plotlyOutput("volcanoPlot")
                            ),
                  nav_panel("Expression Heatmap",
                            tags$div(
                              style = "text-align: right;",
                              downloadButton(
                                outputId = "exportHeatmap", 
                                label = "Export Plot", 
                                # icon = icon("download"),
                                # style = "font-size: 14px; padding: 6px 12px;"  # Adjust size here
                              )
                            ),
                            br(),
                            plotOutput("heatmap"))
                ),
                # DTOutput("experimentTable"),
                textOutput("testMessage")
                )
              ),
    # nav_panel(title = "Plots",
    #           fluidRow(
    #             column(
    #               width = 12,
    #               div(
    #                 style = "background-color: #f0f0f0; padding: 10px; margin-bottom: 10px;",
    #                 h4("Experiment Summary"),
    #                 textOutput("plotsAuthorYear"),
    #                 uiOutput("plotsDescription"),
    #                 textOutput("plotsContrast")
    #               )
    #             )
    #           ),
    #           # plotlyOutput("volcanoPlot")
    #           ),
    )
)