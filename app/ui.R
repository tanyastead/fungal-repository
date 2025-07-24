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
              br(),
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
                             choices = c("Differentially expressed", "Upregulated only", "Downregulated only")),
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
                            uiOutput("volcanoWarning"),
                            br(),
                            plotlyOutput("volcanoPlot")
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
                            plotlyOutput("heatmap")),
                  )
                # DTOutput("experimentTable"),
                # textOutput("testMessage"),
                # verbatimTextOutput("testSearchExpOutput")
                )
              ),
# ---- Gene Info Tab ----
    nav_panel(title = "Gene Info",
              br(),
              actionButton("backButton", "Back"),
              br(),
              DTOutput("tableGeneInfo")
              ),
# ---- Spacer ----
    nav_spacer(),
# ---- Upload data Tab ----
    nav_panel(title = "Upload",
              br(),
              #### DE Data upload ####
              tags$h4("Upload differential expression data:"),
              tags$h5("To upload differential expression data into the repository, please enter the first author associated with the experiment, 
                      the year the study was published, the title or a description of the study, and any keywords associated with the study. Select the 
                      file containing the differential expression data, either in csv or txt format. This file should contain gene ID in column 1, 
                      contrast A and contrast B in columns 2 and 3, and in columns 7-11 log2-fold change, log2-fold change standard error, 
                      Wald test statistic (optional), p-value, and p-adjusted value. An example of this format is displayed below."),
              br(),
              useShinyFeedback(),
              fluidRow(
                column(3,textInput("expAuthor", "Author:", placeholder = "Enter experiment author...")),
                column(3, textInput("expYear", "Year:", width = "250px", placeholder = "Enter experiment year...")),
                column(3, textInput("expSpecies", "Fungal species:", width = "250px", placeholder = "Enter fungal species...")),
                column(3,  selectizeInput("expKeywords",
                                          "Keywords:", choices = NULL, multiple = TRUE,
                                          options = list(create = TRUE, placeholder = "Enter experiment keywords...")))
              ),

              div(style = "display: flex; align-items: center; gap: 20px;",
                  div(textAreaInput("expTitle", "Title or Description:", width = "250px", placeholder = "Enter experiment title or description...")),
                  div(
                    style = " margin-top: 5px; ",
                      fileInput("chooseDEData", "Choose File:")),
                  div(style = "display: flex; align-items: center; height: 100%; margin-top: 5px; ",
                      actionButton("uploadDEData", "Upload",
                                   style = "width: 100%; margin-top: -15px; line-height: 1.8;height: 35px;"))
                  ),

              br(), br(),
              
              tags$h4("Upload functional annotation data:"),
              tags$h5("To upload functional annotation data, select a file containing functional annotation data. Column 1 should contain gene ID. If 
                      GO terms are present, these should be present in column 2. If not available, column 2 should be populated with gene functional annotation
                      data. An example of this format is displayed below."),
              br(),
              div(style = "display: flex; align-items: center; gap: 20px;",
                  div(style = "margin-top: 15px;",
                      fileInput("chooseFAData", "Choose File")),
                  div(style = "margin-top: 0px;",
                    radioButtons("goRadioFAData", "Select the type of annotation in column 2", 
                                   choices = list("GO terms" = 1, "Functional annotations" = 2),
                                   selected = 1)),
                  div(style = "display: flex; align-items: center; height: 100%;",
                      actionButton("uploadFAData", "Upload",
                                   style = "width: 100%; margin-top: 0; line-height: 1.8;height: 38px;"))
              )
              

              )
    )
)