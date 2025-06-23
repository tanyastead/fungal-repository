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
      tableQuery <- dbGetQuery(con, paste0("SELECT Genes.gene_id, GeneFunctions.function, GeneContrasts.contrast, 
          Experiments.author,Experiments.year,Experiments.description 
          FROM Genes 
          JOIN GeneContrasts ON Genes.gene_id = GeneContrasts.gene_id 
          LEFT JOIN GeneFunctions ON Genes.gene_id = GeneFunctions.gene_id 
          JOIN ExpContrasts ON GeneContrasts.contrast = ExpContrasts.contrast 
          JOIN Experiments ON ExpContrasts.experiment_id = Experiments.experiment_id 
          WHERE Genes.gene_id = '", query(), "';"))
      output$tableData <- DT::renderDataTable({
        DT::datatable(tableQuery, 
                      colnames = c("Gene", "Functional Annotation", "Contrasts", "Author", "Year", "Description"))
        })
    } else if (input$term == "Keyword") {
      output$message <- renderText({
        paste0("keyword has been searched: ", query())
      })
      tableQuery <- dbGetQuery(con, paste0("SELECT ExpContrasts.contrast, Experiments.author, Experiments.year, 
          Experiments.description
          FROM ExpKeywords
          JOIN Experiments ON ExpKeywords.experiment_id = Experiments.experiment_id
          JOIN ExpContrasts ON ExpKeywords.experiment_id = ExpContrasts.experiment_id
          WHERE ExpKeywords.keyword = '", query(), "';"))
      output$tableData <- DT::renderDataTable({
        DT::datatable(tableQuery,
                      colnames = c("Contrasts", "Author", "Year", "Description"))
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
