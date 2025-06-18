# server.R
server <- function(input, output, session) {
  
  query <- eventReactive(input$search, {
    req(input$query)  # Ensure input is not empty
    input$query
  })
  
  observeEvent(input$search, {
    if (input$term == "Gene/Gene Property") {
      output$message <- renderText({
        paste0("gene has been searched: ", query())
      })
    } else if (input$term == "Keyword") {
      output$message <- renderText({
        paste0("keyword has been searched: ", query())
      })
    }
  })

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
