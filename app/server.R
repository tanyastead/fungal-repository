# server.R
server <- function(input, output, session) {
  
  query <- eventReactive(input$search, {
    req(input$query)  # Ensure input is not empty
    input$query
  })
  
  observeEvent(input$search, {
    if (input$term == "Gene (Name or Function)") {
      output$message <- renderText({
        paste0("gene has been searched: ", query())
      })
    } else if (input$term == "Keyword") {
      output$message <- renderText({
        paste0("keyword has been searched: ", query())
      })
    }
  })
  refSpec <- reactive({
    req(input$refineSpecies)
    input$refineSpecies
  })
  refKey <- reactive({
    req(input$refineCondition)
    input$refineCondition
  })
  output$speciesMessage <- renderText(paste0("species has been refined to: ", refSpec()))
  output$keywordMessage <- renderText( refKey())

  # # Reactive expression to fetch selected table
  # selectedTable <- reactive({
  #   req(input$table)
  #   dbReadTable(con, input$table)
  # })
  # 
  # # Render the table
  # output$tableData <- renderTable({
  #   selectedTable()
  # })
  # 
  # # Render the graph
  # output$tablePlot <- renderPlot({
  #   data <- selectedTable()
  #   ggplot(data = data, aes(data[[2]], data[[3]]) ) + geom_point()
  # }, res = 96)
  # 
  # # Reactive function to fetch the query
  # selectedQuery <- reactive({
  #   req(input$id)
  #   dbGetQuery(con, paste0("SELECT * FROM AbioticConditions WHERE abiotic_id = ",input$id))
  # })
  # # Render the output
  # output$queryData <- renderTable({
  #   selectedQuery()
  # })
  
}
