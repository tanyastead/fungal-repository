# ui.R
ui <- fluidPage(
  titlePanel("Fungal Transcriptomic Database"),
  br(),
  fluidRow(
    column(4, textInput("query", NULL, placeholder = "Enter search text...")),
    column(4, selectInput("term", NULL, choices = c("Gene/Gene Property", "Keyword"))),
    column(4, actionButton("search", "Search"))
    ),
  br(),
  br(),
  textOutput("message")

  
  
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
