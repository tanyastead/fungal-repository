# server.R
server <- function(input, output, session) {
  ## Setup the initial state
  # hide all unnecessary tabs
  hideTab("navMenu", target = "Results")
  hideTab("navMenu", target = "Experiments")
  hideTab("navMenu", target = "Plots")
  
  queryData <- reactiveVal() # Define a reactive contained to hold the table data
  colnames <- reactiveVal() # define an empty variable to hold column names
  
  ## Search bar queries DB and returns table of results
  observeEvent(input$search, {
    if (input$term == "Gene (Name or Function)") {
      req(input$query)
      tableQuery <- dbGetQuery(con, paste0("SELECT Genes.species, Genes.gene_id, GeneFunctions.function, 
          GeneContrasts.contrast, Experiments.author,Experiments.year,Experiments.description 
          FROM Genes 
          JOIN GeneContrasts ON Genes.gene_id = GeneContrasts.gene_id 
          LEFT JOIN GeneFunctions ON Genes.gene_id = GeneFunctions.gene_id 
          JOIN ExpContrasts ON GeneContrasts.contrast = ExpContrasts.contrast 
          JOIN Experiments ON ExpContrasts.experiment_id = Experiments.experiment_id
          WHERE Genes.gene_id = '", input$query, "';"))
      tableQuery$contrast <- paste0(
        '<a href="#" onclick="Shiny.setInputValue(\'goToTab\', \'', tableQuery$contrast, '\')">',
        tableQuery$contrast,
        '</a>'
      )
      queryData(tableQuery)
      colnames(c("Gene", "Functional Annotation", "Contrasts", "Author", "Year", "Description"))
      
      showTab("navMenu", target = "Results")
      updateTabsetPanel(session, "navMenu", selected = "Results")
    } else if (input$term == "Keyword") {
      req(input$query)
      # tableQuery <- dbGetQuery(con, paste0("SELECT Genes.species, ExpContrasts.contrast, Experiments.author, Experiments.year, 
      #     Experiments.description
      #     FROM ExpKeywords
      #     JOIN Experiments ON ExpKeywords.experiment_id = Experiments.experiment_id
      #     JOIN ExpContrasts ON ExpKeywords.experiment_id = ExpContrasts.experiment_id
      #     JOIN GeneContrasts ON ExpContrasts.contrast = GeneContrasts.contrast
      #     JOIN Genes ON GeneContrasts.gene_id = Genes.gene_id
      #     WHERE ExpKeywords.keyword = '", input$query, "';"))
      
      tableQuery <- dbGetQuery(con, paste0("SELECT ExpContrasts.contrast, Experiments.author, Experiments.year, 
          Experiments.description
          FROM ExpKeywords
          JOIN Experiments ON ExpKeywords.experiment_id = Experiments.experiment_id
          JOIN ExpContrasts ON ExpKeywords.experiment_id = ExpContrasts.experiment_id
          WHERE ExpKeywords.keyword = '", input$query, "';"))
      
      
      tableQuery$contrast <- paste0(
        '<a href="#" onclick="Shiny.setInputValue(\'goToTab\', \'', tableQuery$contrast, '\')">',
        tableQuery$contrast,
        '</a>'
      )
      queryData(tableQuery)
      colnames(c("Contrasts", "Author", "Year", "Description"))

      showTab("navMenu", target = "Results")
      updateTabsetPanel(session, "navMenu", selected = "Results")
    }
  })
  
  ## Refine the query table
  refSpec <- reactive({
    req(input$refineSpecies)
    input$refineSpecies
  })
  refKey <- reactive({
    req(input$refineCondition)
    input$refineCondition
  })
  
  #TODO: wrap these in an if statement, so can say year <= ToYear AND >= FromYear, if these are NOT NULL
  # refFromYear <- reactive({
  #   req(input$fromYear)
  #   filteredData <- reactive({
  #     req(queryData())
  #     return(dplyr::filter(queryData(), Year == input$fromYear))
  #   })
  #   output$tableData <- DT::renderDataTable({
  #     DT::datatable(filteredTable())
  #   })
  # })
  
  # Filter the data based on year
  filteredData <- reactive({
    req(queryData())
    
    if ((is.null(input$fromYear) || input$fromYear == "") && (is.null(input$toYear) || input$toYear == "")) {
      return(queryData())  # No filtering if input is empty
    } else if ((!is.null(input$fromYear) || input$fromYear != "") && (is.null(input$toYear) || input$toYear == "")) {
      return(dplyr::filter(queryData(), year >= input$fromYear))  # column name must match the actual one
    } else if ((is.null(input$fromYear) || input$fromYear == "") && (!is.null(input$toYear) || input$toYear != "")) {
      return(dplyr::filter(queryData(), year <= input$toYear))
    } else if ((!is.null(input$fromYear) || input$fromYear != "") && (!is.null(input$toYear) || input$toYear != "")){
      return(dplyr::filter(queryData(), year >= input$fromYear & year <= input$toYear))
    }
  })
  
  
  refToYear <- reactive({
    req(input$toYear)
  })
  output$speciesMessage <- renderText(paste0("species has been refined to: ", refSpec()))
  output$keywordMessage <- renderText( refKey())
  
  ## Render the query table in the results tab
  output$tableData <- DT::renderDataTable({
    req(filteredData())
    
    DT::datatable(filteredData(),
                  colnames = colnames(),
                  # options = list(columnDefs = list(list(visible = FALSE, targets = c(1,2)))),
                  escape = FALSE)
  })
  
  observeEvent(input$goToTab, {
    # input$goToTab contains the contrast value that was clicked
    # You can map this to a tab name, e.g.:
    contrast_clicked <- input$goToTab
    
    
    updateTabsetPanel(session, "navMenu", selected = "Experiments")
    showTab("navMenu", target = "Experiments")
    showTab("navMenu", target = "Plots")
    
    output$message <- renderText(paste0("contrast selected: ", contrast_clicked))
  })
  

  
}
