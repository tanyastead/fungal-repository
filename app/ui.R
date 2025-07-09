# ui.R
ui <- fluidPage(
  useShinyjs(), 
  # theme = my_theme,
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),
  titlePanel("Fungal Transcriptomic Database"),
  navset_tab(id = "navMenu",
 # ---- Search Tab ----
    nav_panel(title = "Search",
              br(), br(),
              fluidRow(column(8, offset = 2,
                                  # Horizontal alignment using flexbox
                                  div(style = "display: flex; justify-content: space-between; align-items: center;",
                                      # Text Input
                                      div(style = "flex: 2; padding-right: 10px;margin-top: 15px;",
                                          textInput("query", NULL, placeholder = "Enter search text...", width = "100%")
                                      ),
                                      # Select Input
                                      div(style = "flex: 2; padding: 0 10px;margin-top: 15px;",
                                          selectInput("term", NULL,
                                                      choices = c("Gene (Name or Function)", "Condition"),
                                                      width = "100%")
                                      ),
                                      # Search Button aligned using margin-top
                                      div(style = "flex: 1; padding-left: 10px;",
                                          div(style = "display: flex; align-items: center; height: 100%;",
                                              actionButton("search", "Search", 
                                                           style = "width: 100%; margin-top: 0; line-height: 1.8;height: 38px;")
                                          )
                                      )
                                  ),
                              tags$hr(style = "margin-top: 20px; margin-bottom: 10px;"),
                              
                              # Add text underneath the line
                              div(style = "text-align: center; color: #555; font-style: italic;",
                                  "Search by gene ID, gene function or experimental condition (e.g. temperature)"
                              )
                              
              ))
              ),
 # ---- Results Tab ----
    nav_panel(title = "Results", 
              sidebarPanel(
                strong("Refine output:"),
                selectizeInput("refineSpecies",
                               NULL,
                               choices = NULL,
                               multiple = TRUE,
                               options = list(placeholder = "Enter species...")),

                
                
                # selectizeInput("refineCondition",
                #                NULL,
                #                choices = NULL,
                #                multiple = TRUE,
                #                options = list(placeholder = "Enter condition...")),
                # actionButton("toggle_logic", label = "", icon = icon("chevron-down")),
                div(style = "display: flex; align-items: center; gap: 10px;",
                    div(style = "flex-grow: 1;",
                        selectizeInput("refineCondition",
                                       NULL,
                                       choices = NULL,
                                       multiple = TRUE,
                                       options = list(placeholder = "Enter condition..."))
                    ),
                    actionButton("resultsConditionToggle", label = NULL, icon = icon("chevron-down"),
                                 style = "margin-top: -15px;")
                ),
                hidden(
                  div(id = "resultsConditionLogicBox",
                      tags$label("Search logic:", style = "font-weight: normal;"),
                      radioButtons("resultsConditionLogic",
                                   label = NULL,
                                   choices = c("AND", "OR"),
                                   inline = TRUE)
                  )
                ),
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
                # textOutput("speciesMessage"),
                # textOutput("keywordMessage"),
                # textOutput("fromYearMessage"),
                # textOutput("toYearMessage"),
                # verbatimTextOutput("troubleshootingCondition")
              )
            ),
# ---- Experiments Tab ----
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
## ---- Experiments Sidebar ----
              sidebarPanel(
                strong("Refine output:"),
                selectizeInput("refineGene",
                               NULL,
                               choices = NULL,
                               multiple = TRUE,
                               options = list(placeholder = "Enter gene name...")),
                # refine output - gene function??
                # selectizeInput("refineFunctionExp", 
                #                NULL, choices = NULL, multiple = TRUE, 
                #                options = list(create = TRUE, placeholder = "Enter functional annotation...")),
                
                
                
                div(style = "display: flex; align-items: center; gap: 10px;",
                    div(style = "flex-grow: 1;",
                        selectizeInput("refineFunctionExp", 
                                       NULL, choices = NULL, multiple = TRUE, 
                                       options = list(create = TRUE, placeholder = "Enter functional annotation..."))
                    ),
                    actionButton("expFunctionToggle", label = NULL, icon = icon("chevron-down"),
                                 style = "margin-top: -15px;")
                ),
                hidden(
                  div(id = "expFunctionLogicBox",
                      tags$label("Search logic:", style = "font-weight: normal;"),
                      radioButtons("expFunctionLogic",
                                   label = NULL,
                                   choices = c("AND", "OR"),
                                   inline = TRUE)
                  )
                ),
                
                
                
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
                  
## ---- Experiments Data Table Sub-Tab ----
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
                            br(),

## ---- Experiments Volcano Plot Sub-Tab ----                            
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
                            plotlyOutput("volcanoPlot"),
                            verbatimTextOutput("testVolcanoClick")
                            ),

## ---- Experiments Expression Heatmap Sub-Tab ----
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
                            tags$div(
                              uiOutput("heatmapText"),
                              style = "font-size: 16px; color: #2c3e50; font-weight: 500; margin-bottom: 10px;text-align: center;"
                            ),
                            # textOutput("heatmapText"),
                            plotOutput("heatmap")),
                  )
                # DTOutput("experimentTable"),
                # textOutput("testMessage"),
                # verbatimTextOutput("testSearchExpOutput")
                )
              ),
# ---- Gene Info Tab ----
    nav_panel(title = "Gene Info",
              br(),br(),
              DTOutput("tableGeneInfo")
              )
    )
)