# server.R
server <- function(input, output, session) {
  ## Setup the initial state
  # hide all unnecessary tabs
  hideTab("navMenu", target = "Results")
  hideTab("navMenu", target = "Experiments")
  hideTab("navMenu", target = "Plots")
  
  queryData <- reactiveVal() # Define a reactive contained to hold the table data
  colnames <- reactiveVal() # define an empty variable to hold column names
  selectedContrast <- reactiveVal() # Define an empty variable to hold the selected contrast
  selectedAuthor <- reactiveVal()
  selectedYear <- reactiveVal()
  exp_id <- reactiveVal()
  selectedDescription <- reactiveVal()
  experimentData <- reactiveVal()
  
  ## SEARCH TAB
  ## Search bar queries DB and returns table of results
  observeEvent(input$search, {
    if (input$term == "Gene (Name or Function)") {
      req(input$query)
      # Query the DB
      tableQuery <- dbGetQuery(con, paste0("SELECT Genes.species, Genes.gene_id, GeneFunctions.gene_function, 
          GeneContrasts.contrast, Experiments.author,Experiments.year,Experiments.description 
          FROM Genes 
          JOIN GeneContrasts ON Genes.gene_id = GeneContrasts.gene_id 
          LEFT JOIN GeneFunctions ON Genes.gene_id = GeneFunctions.gene_id 
          JOIN Experiments ON GeneContrasts.experiment_id = Experiments.experiment_id
          WHERE Genes.gene_id = '", input$query, "';"))
      
      # Set the contrast column as clickable links, and combine contrasts into a single cell
      processedTable <- tableQuery %>%
        # mutate contrasts as hyperlinks set to open new tabs. 
        mutate(hyperlink = paste0('<a href="#" onclick="Shiny.setInputValue(\'goToTab\', {',
                                  'contrast: \'', contrast, '\', ',
                                  'author: \'', author, '\', ',
                                  'year: ', year, ', ',
                                  'description: \'', description, '\', ',
                                  'priority: \'event\'',
                                  '})">',
                                  contrast,
                                  '</a>')) %>% # priority event forces the hyperlink to work every time it is clicked
        # groups table where ALL listed values are identical
        group_by(species, gene_id, gene_function, author, year, description) %>% 
        # collapse contrasts/hyperlinks into a single string separated by a <br> so they appear on newlines in a single cell
        summarise(contrasts = paste(hyperlink, collapse = "<br>"), .groups = 'drop') %>%
        # sort the order of the columns
        select(species, gene_id, gene_function, contrasts, author, year, description)
      
      # Save the processedTable outside the observeEvent
      queryData(processedTable)
      
      # Save specific column names outside the observeEvent
      colnames(c("Species","Gene", "Functional Annotation", "Contrasts", "Author", "Year", "Description"))
      
      # Switch view to the Results tab
      showTab("navMenu", target = "Results")
      updateTabsetPanel(session, "navMenu", selected = "Results")
      
    } else if (input$term == "Keyword") {
      req(input$query)
      # Query the DB
      tableQuery <- dbGetQuery(con, paste0("SELECT Experiments.species, ExpContrasts.contrast, Experiments.author, 
          Experiments.year, Experiments.description
          FROM ExpKeywords
          JOIN Experiments ON ExpKeywords.experiment_id = Experiments.experiment_id
          JOIN ExpContrasts ON ExpKeywords.experiment_id = ExpContrasts.experiment_id
          WHERE ExpKeywords.keyword = '", input$query, "';"))
      
      # Set the contrast column as clickable links, and combine contrasts into a single cell
      processedTable <- tableQuery %>%
        # mutate contrasts as hyperlinks set to open new tabs
        mutate(hyperlink = paste0( '<a href="#" onclick="Shiny.setInputValue(\'goToTab\', {',
                                   'contrast: \'', contrast, '\', ',
                                   'author: \'', author, '\', ',
                                   'year: ', year, ', ',
                                   'description: \'', description, '\', ',
                                   'nonce: Math.random()',
                                   '}, {priority: \'event\'})">',
                                   contrast,
                                   '</a>')) %>% 
        # groups table where ALL listed values are identical
        group_by(species, author, year, description) %>% 
        # collapse contrasts/hyperlinks into a single string separated by a <br> so they appear on newlines in a single cell
        summarise(contrasts = paste(hyperlink, collapse = "<br>"), .groups = 'drop') %>%
        # sort the order of the columns
        select(species, contrasts, author, year, description)
      
      # Save the processedTable outside the observeEvent
      queryData(processedTable)
      
      # save specific column names
      colnames(c("Species","Contrasts", "Author", "Year", "Description"))

      # open the Results tab
      showTab("navMenu", target = "Results")
      updateTabsetPanel(session, "navMenu", selected = "Results")
    }
  })
  
  
  ## RESULTS TAB
  ## Refine the query table
  filteredData <- reactive({
    req(queryData())
    
    data <- queryData()
    
    # Filter based on year
    if (!is.null(input$fromYear) && input$fromYear != "") {
      data <- dplyr::filter(data, year >= input$fromYear)
    }
    
    if (!is.null(input$toYear) && input$toYear != "") {
      data <- dplyr::filter(data, year <= input$toYear)
    }
    
    # Filter based on species
    if (!is.null(input$refineSpecies)){
      data <- dplyr::filter(data, species %in% input$refineSpecies)
      output$speciesMessage <- renderPrint(paste0("species has been redifned to: ", typeof(input$refineSpecies)))
    }
    
    return(data)
  })
  
  
  
  ## Render the query table in the results tab
  output$tableData <- DT::renderDataTable({
    req(filteredData())
    
    DT::datatable(filteredData(),
                  rownames = FALSE,
                  colnames = colnames(),
                  options = list(columnDefs = list(list(visible = FALSE, targets = c(0)))), # Hide the 1st column (species)
                  escape = FALSE)
  })
  
  ## EXPERIMENTS TAB
  ## Navigate to the experiments tab when a contrast is clicked
  observeEvent(input$goToTab, {
    # save the name of the selected contrast, author and year
    selectedContrast(input$goToTab$contrast)
    selectedAuthor(input$goToTab$author)
    selectedYear(input$goToTab$year)
    exp_id(paste0(selectedAuthor(), "_", selectedYear()))
    selectedDescription(input$goToTab$description)
    
    # Navigate to the experiments tab
    updateTabsetPanel(session, "navMenu", selected = "Experiments")
    showTab("navMenu", target = "Experiments")
    showTab("navMenu", target = "Plots")
    
    # Identify possible genes and relevant values based on selected contrast
    geneValues <- dbGetQuery(con, paste0(
      "SELECT GeneContrasts.gene_id, GeneFunctions.gene_function, DEG.log2FC, DEG.lfcSE, DEG.pval, DEG.padj
      FROM GeneContrasts
      LEFT JOIN GeneFunctions ON GeneContrasts.gene_id = GeneFunctions.gene_id
      JOIN DEG ON GeneContrasts.gene_contrast = DEG.gene_contrast
      WHERE contrast = '", selectedContrast(), "' and experiment_id = '",exp_id(),"';"
    ))
    
    experimentData(geneValues)
    
    # Output the table
    # output$experimentTable <- renderDataTable({
    #   datatable(geneValues)
    # })
    
    # Update experiment description
    output$experimentAuthorYear <- renderText(paste0(selectedAuthor(), ", ", selectedYear()))
    output$experimentDescription <- renderUI({
      HTML(paste0("<em>", selectedDescription(), "</em>"))
      })
    output$experimentContrast <- renderText(paste0("Selected contrast: ", selectedContrast()))
    
    # Refine side panel
    updateSelectizeInput(session,
                         "refineGene",
                         choices = geneValues$gene_id,
                         server = TRUE)
  })
  
  ## Refine the Experiments table
  filteredExpData <- reactive({
    req(experimentData())
    data <- experimentData()
    output$testMessage <- renderText(paste0("currently stored padj: ", input$padj))
    # Filter based on gene_id
    if (!is.null(input$refineGene)){
      data <- filter(data, gene_id %in% input$refineGene)
    }
    
    # Filter based on pval
    if (!is.null(input$pvalue) && !is.na(input$pvalue)){
      data <- filter(data, pval < input$pvalue)
    }
    
    # Filter based on padj
    if (!is.null(input$padj) && !is.na(input$padj)){
      data <- filter(data, padj < input$padj)
    }
    
    # Filter based on logFC
    ### if radio button == a, then do a
    if (!is.null(input$lFC) && !is.na(input$lFC)){
      if (input$lFCRegulation == "Up- or Downregulated"){
        data <- filter(data, log2FC >= input$lFC | log2FC <= -input$lFC)
      }
      if (input$lFCRegulation == "Upregulated only"){
        data <- filter(data, log2FC >= input$lFC)
      }
      if (input$lFCRegulation == "Downregulated only"){
        data <- filter(data, log2FC <= -input$lFC)
      }
    }
    
    return(data)
  })

  # ## Render the experiment table in the experiments tab
  output$experimentTable <- renderDataTable({
    req(filteredExpData())

    datatable(filteredExpData(),
              rownames = FALSE,
              colnames = c("Gene", "Functional Annotation", HTML("Log<sub>2</sub>-Fold Change"), 
                           "Log-Fold Change Standard Error",  HTML("P&#8209;Value"), HTML("P&#8209;Adjusted")),
              escape = FALSE)
  })
  
  ## Update the Experiments tab
  # Identify possible genes based on selected contrast
  # queriedGenes <- reactive({
  #   req(selectedContrast())
  #   
  #   dbGetQuery(con, paste0(
  #     "SELECT DISTINCT gene_id FROM GeneContrasts WHERE contrast = '",
  #     selectedContrast(), "' and experiment_id = '",exp_id(),"';"
  #   ))
  # })
  # Update variables in Experiments tab
  # observeEvent(selectedContrast(), {
  #   req(selectedContrast())
  #   
  #   # Update experiment description
  #   output$experimentAuthorYear <- renderText(paste0(selectedAuthor(), ", ", selectedYear()))
  #   output$experimentDescription <- renderUI({
  #     HTML(paste0("<em>", selectedDescription(), "</em>"))
  #   })
  #   output$experimentContrast <- renderText(paste0("Selected contrast: ", selectedContrast()))
  #   
  #   
  #   # update side panel
  #   genes <- queriedGenes()
  #   # updateSelectizeInput(session,
  #   #                      "refineGene",
  #   #                      choices = genes$gene_id,
  #   #                      server = TRUE)
  # })
  
}
