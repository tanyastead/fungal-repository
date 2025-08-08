# server.R
server <- function(input, output, session) {

  # Cleanly close the DB connection on ending the session
  session$onSessionEnded(function() {
    dbDisconnect(con)
  })
  
  # ---- INITIAL SETUP ----
  ## ---- Hide Tabs ----
  hideTab("navMenu", target = "Results")
  hideTab("navMenu", target = "Experiments")
  hideTab("navMenu", target = "Gene Info")
  
  ## ---- Define reactiveVal() ----
  queryData <- reactiveVal() # Define a reactive contained to hold the table data
  colnames <- reactiveVal() # define an empty variable to hold column names
  hidden_columns <- reactiveVal() # which columns to hide
  selectedContrast <- reactiveVal() # Define an empty variable to hold the selected contrast
  selectedAuthor <- reactiveVal()
  selectedYear <- reactiveVal()
  exp_id <- reactiveVal()
  selectedDescription <- reactiveVal()
  experimentData <- reactiveVal()
  heatmap <- reactiveVal()
  volcano <- reactiveVal()
  geneInfo <- reactiveVal()
  resultsConditionButtonIconToggle <- reactiveVal(FALSE)
  expFunctionButtonIconToggle <- reactiveVal(FALSE)
  heatmapPlotData <- reactiveVal()
  

  
  # ---- SEARCH TAB ----
  ## Search bar queries DB and returns table of results
  observeEvent(input$search, {
    ## Clear any previously inputted values in side panels
    # For Results side panel
    updateSelectizeInput(session, "refineSpecies", selected = character(0))
    updateSelectizeInput(session, "refineCondition", selected = character(0))
    updateTextInput(session, "fromYear", value = "")
    updateTextInput(session, "toYear", value = "")
    
    # For Experiments side panel
    updateSelectizeInput(session, "refineGene", selected = character(0))
    updateSelectizeInput(session, "refineFunctionExp", choices = NULL, selected = NULL, server = TRUE)
    updateNumericInput(session, "pvalue", value = NA)
    updateNumericInput(session, "padj", value = NA)
    updateNumericInput(session, "lFC", value = NA)
    updateRadioButtons(session, "lFCRegulation", selected = "Differentially expressed")
    
    ## ---- Gene (Name or Function) selected ----
    if (input$term == "Gene (Name or Function)"){
      req(input$query)
      # Query the DB
      ### original working 
      # tableQuery <- dbGetQuery(con, paste0("
      #       SELECT Genes.species, ExpKeywords.keyword, GeneFunctions.go_term, GeneFunctions_FTS.gene_id, GeneFunctions_FTS.gene_function,
      #       GeneContrasts.contrast, Experiments.author,Experiments.year,Experiments.description
      #       FROM GeneFunctions_FTS
      #       JOIN Genes ON GeneFunctions_FTS.gene_id = Genes.gene_id
      #       JOIN GeneFunctions on GeneFunctions_FTS.gene_id = GeneFunctions.gene_id
      #       JOIN GeneContrasts ON GeneFunctions_FTS.gene_id = GeneContrasts.gene_id
      #       JOIN Experiments ON GeneContrasts.experiment_id = Experiments.experiment_id
      #       JOIN ExpKeywords ON Experiments.experiment_id = ExpKeywords.experiment_id
      #       WHERE GeneFunctions_FTS MATCH '",input$query,"';
      #       "))
      ### original working 
      funcQuery <- dbGetQuery(con, paste0("
          SELECT 
            Genes.species, 
            ExpKeywords.keyword, 
            GeneFunctions_FTS.go_func,
            GeneFunctions_FTS.gene_id, 
            GeneFunctions_FTS.gene_function,
            GeneContrasts.contrast, 
            Experiments.author,
            Experiments.year,
            Experiments.description
          FROM GeneFunctions_FTS
          JOIN Genes ON GeneFunctions_FTS.gene_id = Genes.gene_id
          JOIN GeneContrasts ON GeneFunctions_FTS.gene_id = GeneContrasts.gene_id
          JOIN Experiments ON GeneContrasts.experiment_id = Experiments.experiment_id
          JOIN ExpKeywords ON Experiments.experiment_id = ExpKeywords.experiment_id
          WHERE 
            GeneFunctions_FTS MATCH '", input$query, "';
        "))

      idQuery <- dbGetQuery(con, paste0("
          SELECT
            Genes.species,
            ExpKeywords.keyword,
            GeneFunctions_FTS.go_func,
            Genes.gene_id,
            GeneFunctions_FTS.gene_function,
            GeneContrasts.contrast,
            Experiments.author,
            Experiments.year,
            Experiments.description
          FROM Genes
          LEFT JOIN GeneFunctions_FTS ON Genes.gene_id = GeneFunctions_FTS.gene_id
          JOIN GeneContrasts ON Genes.gene_id = GeneContrasts.gene_id
          JOIN Experiments ON GeneContrasts.experiment_id = Experiments.experiment_id
          JOIN ExpKeywords ON Experiments.experiment_id = ExpKeywords.experiment_id
          WHERE
            Genes.gene_id = '", input$query, "';
        "))
      
      # idQuery can return genes that do not have a stored function - change NA to string in order to combine queries
      idQuery$go_func <- as.character(idQuery$go_func)
      idQuery$gene_function <- as.character(idQuery$gene_function)
      
      # Combine the queries only if funcQuery returns something
      if (nrow(funcQuery) > 0){
        combined_query <- distinct(bind_rows(funcQuery, idQuery))
      } else{
        combined_query <- idQuery
      }
      
      # Set the contrast column as clickable links, and combine contrasts into a single cell
      processedTable <- combined_query %>%
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
        # mutate gene function as hyperlinks set to open go term page
        mutate(gene_function = if_else(
                                  is.na(gene_function),
                                  '<i>Not available</i>',
                                  if_else(
                                    !is.na(go_func),
                                    paste0('<a href="https://amigo.geneontology.org/amigo/term/', go_func, '" target="_blank">', gene_function, '</a>'),
                                    gene_function
                                  )
                                  # paste0('<a href="https://amigo.geneontology.org/amigo/term/',
                                  #     go_func, '" target="_blank">', gene_function, '</a>')
                                      )) %>%
        
        # groups table where ALL listed values are identical
        group_by(species, gene_id, go_func, gene_function, author, year, description) %>%
        # collapse contrasts/hyperlinks into a single string separated by a <br> so they appear on newlines in a single cell
        summarise(contrasts = paste(unique(hyperlink), collapse = "<br>"),
                  keywords = paste(unique(keyword), collapse = "; "),
                  .groups = 'drop') %>%
        # sort the order of the columns
        select(species, keywords, go_func, gene_id, gene_function, contrasts, author, year, description)
      
      # Save the processedTable outside the observeEvent
      queryData(processedTable)
      
      # Save specific column names outside the observeEvent
      colnames(c("Species","Keywords","GO Term","Gene", "Functional Annotation", "Contrasts", "Author", "Year", "Description"))
      
      # save number of columns to hide
      hidden_columns(c(0:2))
      
      # Switch view to the Results tab
      showTab("navMenu", target = "Results")
      updateTabsetPanel(session, "navMenu", selected = "Results")
      
    ## ---- Condition selected ----  
    } else if (input$term == "Condition") {
      req(input$query)
      ## TODO: CHECK IF THIS QUERY NEEDS FIXING!!
      tableQuery <- dbGetQuery(con, paste0(
        "SELECT
            Experiments.species,
            AllKeywords.keyword,
            ExpContrasts.contrast,
            Experiments.author,
            Experiments.year,
            Experiments.description
        FROM Experiments
        JOIN ExpContrasts ON Experiments.experiment_id = ExpContrasts.experiment_id
        JOIN ExpKeywords AS AllKeywords ON Experiments.experiment_id = AllKeywords.experiment_id
        WHERE Experiments.experiment_id IN (
                SELECT experiment_id
                FROM ExpKeywords
                WHERE keyword = '",input$query,"'
                COLLATE NOCASE
                );"
      ))
      
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
        summarise(contrasts = paste(unique(hyperlink), collapse = "<br>"),
                  keywords = paste(unique(keyword), collapse = "; "),
                  .groups = 'drop') %>%
        # sort the order of the columns
        select(species, keywords, contrasts, author, year, description)
      
      # Save the processedTable outside the observeEvent
      queryData(processedTable)
      
      # save specific column names
      colnames(c("Species","Keywords", "Contrasts", "Author", "Year", "Description"))
      
      # save number of columns to hide
      hidden_columns(c(0,1))
      
      # open the Results tab
      showTab("navMenu", target = "Results")
      updateTabsetPanel(session, "navMenu", selected = "Results")
    }
    
  })
  
  # ---- RESULTS TAB ----
  ## ---- Update  results sidepanel refine species and condition ----
  observeEvent(input$search, {
    req(queryData())
    data <- queryData()
    
    # Update refineSpecies
    speciesList <- list()
    for (sp in unique(data$species)){
      count <- sum(data$species == sp)
      speciesList <- list.append(speciesList, paste0(sp, " (", count, ")"))
    }
    updateSelectizeInput(session,
                         "refineSpecies",
                         choices = speciesList,
                         server = TRUE)
    
    # Update refineCondition
    all_keywords <- unlist(str_split(data$keywords, "; "))
    keywords <- unique(all_keywords)
    keywordsList <- list()
    for (key in keywords){
      count <- sum(all_keywords == key)
      keywordsList <- list.append(keywordsList, paste0(key, " (", count, ")"))
    }
    updateSelectizeInput(session,
                         "refineCondition",
                         choices = keywordsList,
                         server = TRUE)
  })
  
  ## ---- Refine/filter query table ----
  filteredData <- reactive({
    req(queryData())
    
    data <- queryData()
    
    ### use regex to remove the count from the input, and then use the input to filter the table
    # Filter based on year
    if (!is.null(input$fromYear) && input$fromYear != "") {
      data <- dplyr::filter(data, year >= input$fromYear)
    }
    
    if (!is.null(input$toYear) && input$toYear != "") {
      data <- dplyr::filter(data, year <= input$toYear)
    }
    
    # Filter based on species
    if (!is.null(input$refineSpecies)){
      spec <- str_replace(input$refineSpecies, "\\s\\([[:digit:]]+\\)$", "")
      data <- dplyr::filter(data, species %in% spec)
    }
    
    # Filter based on keyword
    if (!is.null(input$refineCondition)){
      terms <- str_replace(input$refineCondition, "\\s\\([[:digit:]]+\\)$", "")
      if (input$resultsConditionLogic == "OR") {
        keyword_pattern <- str_c(terms, collapse = "|")
        data <- data %>%
          filter(str_detect(keywords, regex(keyword_pattern, ignore_case = TRUE)))
        
      } else if (input$resultsConditionLogic == "AND") {
        data <- data %>%
          filter(
            map_lgl(keywords, function(k) {
              all(str_detect(k, regex(terms, ignore_case = TRUE)))
            })
          )
      }
    }

    return(data)
  })
  
  ## ---- Render query table ----
  output$tableData <- DT::renderDataTable({
    req(filteredData())
    
    DT::datatable(filteredData(),
                  rownames = FALSE,
                  colnames = colnames(),
                  selection = "none",
                  options = list(
                    columnDefs = list(
                      list(visible = FALSE, targets = hidden_columns())
                      )
                    ), # Hide the unecessary columns
                  escape = FALSE)
  })
  

  
  ## ---- Define Condition toggle logic ----
  observeEvent(input$resultsConditionToggle, {
    shinyjs::toggle(id = "resultsConditionLogicBox") 
    state <- !resultsConditionButtonIconToggle()
    resultsConditionButtonIconToggle(state)
    
    if (state == FALSE){
      icon <- icon("chevron-down")
    } else {
      icon <- icon("chevron-up")
    }
    
    updateActionButton(session = session,
                       "resultsConditionToggle",
                       icon = icon)
  })
  
  
  ## ---- Clear button to reset side panel values ----
  observeEvent(input$clearResults, {
    updateSelectizeInput(session, "refineSpecies", selected = character(0))
    updateSelectizeInput(session, "refineCondition", selected = character(0))
    updateTextInput(session, "fromYear", value = "")
    updateTextInput(session, "toYear", value = "")
  })
  
  ## ---- Export button downloads table ----
  output$exportResults <- downloadHandler(
    filename = function() {
      paste0(input$query, "_", 
             format(Sys.time(), "%Y-%m-%d_%H-%M-%S"),
             ".csv")
    },
    content = function(file) {
      write.csv(filteredData(), file, row.names = FALSE)
    }
  )
  
  # ---- EXPERIMENTS TAB ----
  ## ---- Navigate to the experiments tab when a contrast is clicked ----
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
    
    # Identify possible genes and relevant values based on selected contrast
    geneValues <- dbGetQuery(con, paste0(
      "SELECT 
        GeneFunctions.go_func,
        GeneContrasts.gene_id, 
        GeneFunctions.gene_function, 
        DEG.log2FC, 
        DEG.lfcSE, 
        DEG.pval, 
        DEG.padj
      FROM GeneContrasts
      LEFT JOIN GeneFunctions ON GeneContrasts.gene_id = GeneFunctions.gene_id
      JOIN DEG ON GeneContrasts.gene_contrast = DEG.gene_contrast
      WHERE contrast = '", selectedContrast(), "' and experiment_id = '",exp_id(),"';"
    ))
    
    # Hide the go_terms column and set gene_function as hyperlinks
    processedExpTable <- geneValues %>%
      # mutate gene function as hyperlinks set to open go term page
      ## TODO: If gene_function is NA, write Not Available instead of having hyperlink...
      mutate(gene_function = if_else(
        is.na(gene_function),
        '<i>Not available</i>',
        if_else(
          !is.na(go_func),
          paste0('<a href="https://amigo.geneontology.org/amigo/term/', go_func, '" target="_blank">', gene_function, '</a>'),
          gene_function
        )
        ))
      

    # Save the table
    experimentData(processedExpTable)
    
    # Update experiment description in Experiments and Plots tabs
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
    #TODO: Does anything else in the side panel need to be refined/cleared at this step??
  })
  
  ## ---- Define Function toggle logic ----
  observeEvent(input$expFunctionToggle, {
    shinyjs::toggle(id = "expFunctionLogicBox") 
    state <- !expFunctionButtonIconToggle()
    expFunctionButtonIconToggle(state)
    
    if (state == FALSE){
      icon <- icon("chevron-down")
    } else {
      icon <- icon("chevron-up")
    }
    
    updateActionButton(session = session,
                       "expFunctionToggle",
                       icon = icon)
  })
  
  ## ---- Refine the Experiments table ----
  filteredExpData <- reactive({
    req(experimentData())
    data <- experimentData()
    
    # remove NA values
    # data <- df[!is.na(df$pval), ]
    # data <- filter(data, !is.na(pval))
    # data$pval <- as.numeric(data$pval)

    # Filter based on gene_id
    if (!is.null(input$refineGene)){
      data <- filter(data, gene_id %in% input$refineGene)
    }
    # Filter based on function
    if (!is.null(input$refineFunctionExp) && length(input$refineFunctionExp) > 0) {
      
      if (input$expFunctionLogic == "AND"){
        data <- data %>%
          filter(reduce(input$refineFunctionExp, 
                        ~ .x & str_detect(gene_function, fixed(.y, ignore_case = TRUE)),
                        .init = TRUE))
      } else if (input$expFunctionLogic == "OR"){
        data <- data %>%
          filter(reduce(input$refineFunctionExp, 
                        ~ .x | str_detect(gene_function, fixed(.y, ignore_case = TRUE)),
                        .init = FALSE))
      }
      
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
    if (!is.null(input$lFC) && !is.na(input$lFC)){
      if (input$lFCRegulation == "Differentially expressed"){
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
  
  ## See what is being outputted 
  # output$testSearchExpOutput <- renderText({
  #   paste0("placeholder, typeof:",typeof(input$testSearchExp), " stored: ", input$testSearchExp)
  # })

  ## ---- Render the experiment table in the experiments tab ----
  output$experimentTable <- renderDataTable({
    req(filteredExpData())

    datatable(filteredExpData(),
              rownames = FALSE,
              colnames = c("GO Term","Gene", "Functional Annotation", HTML("Log<sub>2</sub>-Fold Change"),
                           "Log-Fold Change Standard Error",  HTML("P&#8209;Value"), HTML("P&#8209;Adjusted")),
              options = list(
                columnDefs = list(
                  list(visible = FALSE, targets = 0)
                )
              ),
              selection = "none",
              escape = FALSE) %>%
      formatRound(columns=c('log2FC', 'lfcSE'), digits=3) %>%
      formatSignif(columns = c("pval", "padj"), digits = 4)
  })
  
  ## ---- Download button downloads table ----
  output$exportExpTable <- downloadHandler(
    filename = function() {
      paste0(selectedContrast(), "_", 
             selectedAuthor(), "_", 
             selectedYear(), "_", 
             format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), 
             ".csv")
    },
    content = function(file) {
      write.csv(filteredExpData(), file, row.names = FALSE)
    }
  )
  
  ## ---- Clear button resets side panel values ----
  observeEvent(input$clearExperiments, {
    updateSelectizeInput(session, "refineGene", selected = character(0))
    updateSelectizeInput(session, "refineFunctionExp", choices = NULL, selected = NULL, server = TRUE)
    updateNumericInput(session, "pvalue", value = NA)
    updateNumericInput(session, "padj", value = NA)
    updateNumericInput(session, "lFC", value = NA)
    updateRadioButtons(session, "lFCRegulation", selected = "Differentially expressed")
  })
  
  ## ---- reactive vals for volcano plot ----
  removedCols <- reactiveVal(0)

  
  ## ---- Generate interactive volcano plot ----
  output$volcanoPlot <- renderPlotly({
    entire_df <- experimentData()
    # entire_df <- filteredExpData()
    # remove empty pval and padj
    entire_df <- filter(entire_df, !is.na(padj))
    entire_df <- filter(entire_df, !is.na(pval))
    
    # Remove rows where pval is 0
    emptyPval <- sum(entire_df$pval == 0)
    removedCols(emptyPval)
    entire_df <- filter(entire_df, pval != 0)
    print("checking")
    print(sum(entire_df$pval == 0))
    print(sum(is.na(entire_df$pval)))
    
    output$volcanoWarning <- renderUI({
      req(removedCols())
      HTML(paste0('<span style="font-weight: bold;">
                Note: ',removedCols(),' genes removed from plot due to empty p-values!
               </span>'))
    })
    
    # Check if rows do not contain a padj but do contain a pval, to determine which metric should be used to build the volcano plot
    if (any(entire_df$padj == 0 & entire_df$pval != 0)) {
      pMetric <- "pval"
    } else {
      pMetric <- "padj"
    }

      
    # Set significant values for log2FC and padj/pval
    if (!is.null(input$lFC) && !is.na(input$lFC)){
      fold <- input$lFC
    } else {
      fold <- 1
    }

    if (!is.null(input[[pMetric]]) && !is.na(input[[pMetric]])){
      pval <- input[[pMetric]]
    } else {
      pval <- 0.05
    }
    
    

    ## TODO: pass pMetric to the function to set plot title and horizotnal text
    # create ggplot volcano plot
    p <- interactive_volcano(data = entire_df, lFC = fold, pv = pval, cont = selectedContrast(), pmetric = pMetric)
    
    # save plot so it can be downloaded
    volcano(p)
    
    # display interactive plot
    p <- ggplotly(p, tooltip = "text", source = "volc") %>% layout(
      margin = list(t = 80)) #%>% 
      # event_register("plotly_click")
    
    ## not sure if having p here does anything - plotly click warning still displayed, and without it heatmap anyways renders...
    p
  })
  
  ## ---- Open the Gene Info tab when a point is clicked on the volcano plot ----
  observeEvent(event_data("plotly_click", source = "volc"), {
    click <- event_data("plotly_click", source = "volc")
    if (!is.null(click)) {

      print(click$key, 
                   # event_data("plotly_click", source="volc")
                   )
      print(str(click))
      print(click$customdata)
      # conduct query
      geneQuery <- dbGetQuery(con, paste0(
        "SELECT
          Genes.gene_id,
          GeneGo.go_term,
          GeneFunctions.gene_function
        FROM Genes
        LEFT JOIN GeneGo ON Genes.gene_id = GeneGo.gene_id
        LEFT JOIN GeneFunctions on Genes.gene_id = GeneFunctions.gene_id
        WHERE Genes.gene_id = '",click$key,"';"
      ))
      processedGeneInfo <- geneQuery %>%
        # mutate go_term to hyperlinks
        ## TODO: Combine GO terms into single cell
        mutate(
          go_term = if_else(
            is.na(go_term),
            '<i>Not available</i>',
            paste0('<a href="https://amigo.geneontology.org/amigo/term/',
                   go_term, '" target="_blank">', go_term, '</a>')
            ),
          gene_function = if_else(
            is.na(gene_function),
            '<i>Not available</i>',
            gene_function
          )
        )%>%
        # Group and summarise the table to have all GO terms in a single cell
        group_by(gene_id, gene_function) %>%
        summarise(go_term = paste(unique(go_term), collapse = "<br>"), .groups = 'drop')%>%
        # Reorder the columns to the correct order
        select(gene_id, go_term, gene_function)
      
      

      
      
      geneInfo(processedGeneInfo)
      # open tab
      showTab("navMenu", target = "Gene Info")
      updateTabsetPanel(session, "navMenu", selected = "Gene Info")
    }
  })
  
  ## ---- Render the Gene Info data table ----
  output$tableGeneInfo <- renderDataTable({
    req(geneInfo())
    
    datatable(geneInfo(),
              rownames = FALSE,
              colnames = c("Gene", "GO Term", "Functional Annotation"),
              selection = "none",
              options = list(dom = "t"),
              escape = FALSE)
    
  })
  
  ## ---- Gene Info Back Button ----
  observeEvent(input$backButton, {
    updateTabsetPanel(session, "navMenu", selected = "Experiments")
  })
  
  ## ---- Download button downloads volcano plot ----
  output$exportVolcano <- downloadHandler(
    filename = function() {
      paste0(selectedContrast(), "_", 
             selectedAuthor(), "_", 
             selectedYear(), "_", 
             format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), 
             ".png")
    },
    content = function(file) {
      ggsave(
        filename = file,
        plot = volcano(), 
        device = "png",
        width = 8,
        height = 6,
        dpi = 300
      )
    }
  )
  
 
  ## ---- Generate heatmap ----
  output$heatmap <- renderPlotly({
    ##TODO: Set log2FC scale to static???
    ## TODO: Change GeneFunctions!!!
    # Execute DB search
    ## TODO: Check if this needs to be fixed to align with new schema
    all_DEGs <- dbGetQuery(con, paste0(
      "SELECT
        GeneContrasts.gene_id,
        GeneContrasts.contrast,
        GeneFunctions.gene_function,
        DEG.log2FC,
        DEG.lfcSE,
        DEG.pval,
        DEG.padj
      FROM GeneContrasts
      LEFT JOIN GeneFunctions ON GeneContrasts.gene_id = GeneFunctions.gene_id
      JOIN DEG ON GeneContrasts.gene_contrast = DEG.gene_contrast
      WHERE experiment_id = '", exp_id(), "';"
    ))


    # First, filter by contrast-specific criteria
    filtered_genes <- all_DEGs %>%
      filter(contrast == selectedContrast())

    # Apply the filters on pval, padj, log2FC, etc.
    if (!is.null(input$refineGene)){
      filtered_genes <- filter(filtered_genes, gene_id %in% input$refineGene)
    }
    # Filter based on function
    if (!is.null(input$refineFunctionExp) && length(input$refineFunctionExp) > 0) {
      
      if (input$expFunctionLogic == "AND"){
        filtered_genes <- filtered_genes %>%
          filter(reduce(input$refineFunctionExp, 
                        ~ .x & str_detect(gene_function, fixed(.y, ignore_case = TRUE)),
                        .init = TRUE))
      } else if (input$expFunctionLogic == "OR"){
        filtered_genes <- filtered_genes %>%
          filter(reduce(input$refineFunctionExp, 
                        ~ .x | str_detect(gene_function, fixed(.y, ignore_case = TRUE)),
                        .init = FALSE))
      }
      
    }
    # Filter based on p-value
    if (!is.null(input$pvalue) && !is.na(input$pvalue)){
      filtered_genes <- filter(filtered_genes, pval < input$pvalue)
    }
    # Filter based on p-adjusted value
    if (!is.null(input$padj) && !is.na(input$padj)){
      filtered_genes <- filter(filtered_genes, padj < input$padj)
    }
    # Filter based on log fold change
    if (!is.null(input$lFC) && !is.na(input$lFC)){
      if (input$lFCRegulation == "Differentially expressed"){
        filtered_genes <- filter(filtered_genes, log2FC >= input$lFC | log2FC <= -input$lFC)
      }
      if (input$lFCRegulation == "Upregulated only"){
        filtered_genes <- filter(filtered_genes, log2FC >= input$lFC)
      }
      if (input$lFCRegulation == "Downregulated only"){
        filtered_genes <- filter(filtered_genes, log2FC <= -input$lFC)
      }
    }

    # Now extract the gene IDs that passed contrast-specific filtering
    selected_genes <- unique(filtered_genes$gene_id)

    # Subset the full all_DEGs to include *all* contrasts for those genes
    plot_data <- all_DEGs %>% filter(gene_id %in% selected_genes)


    # reorder the contrasts so that the selected contrast is the first
    target_contrast <- selectedContrast()

    # Get all contrast levels, and reorder to put target first
    contrast_levels <- unique(all_DEGs$contrast)
    ordered_levels <- c(target_contrast, setdiff(contrast_levels, target_contrast))

    # Reorder the contrast factor
    all_DEGs$contrast <- factor(all_DEGs$contrast, levels = ordered_levels)

    plot_data$contrast <- factor(plot_data$contrast, levels = ordered_levels)
    
    heatmapPlotData(plot_data)

    # generate heatmap only if <30 genes are selected
    if (nrow(plot_data) < (30 * length(unique(all_DEGs$contrast)))){
      # Wipe the message
      output$heatmapText <- NULL
      # Plot the heatmap
      # plot <- DEG_heatmap(plot_data)
      # # heatmap(plot)
      # ggplotly(plot, tooltip = "text", source = "heat")
      plot <- plotly_DEG_heatmap(plot_data)
      plot
      
      # save the heatmap so it can be downloaded
      # heatmap(plot) # TODO: this is necessary to download the plot, but doesn't allow the heatmap to be 
      
    } else {
      # Print output mnessage
      output$heatmapText <- renderUI({
        HTML('<span style="font-weight: bold;">
          Too many genes selected!<br>
          <i>Select fewer than 30 genes to generate expression heatmap</i>
        </span>')
      })
      # Colour the empty plot space to match the background
      par(bg = "#f5f7fa")
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "", main = "")
    }
    
    

  })

  
  ## ---- Open the Gene Info tab when a point is clicked on the heatmap ----
  observeEvent(event_data("plotly_click", source = "heat"), {
    click <- event_data("plotly_click", source = "heat")
    if (!is.null(click)) {
      # print("click:")
      # print(click)
      # # print(click$key, 
      # #       # event_data("plotly_click", source="volc")
      # # )
      # print("str click:")
      # print(str(click))
      # selected_gene <- filter(heatmapPlotData(),
      #                                contrast == click$x,
      #                                gene_id == click$y)
      # print("selected gene:")
      # print(selected_gene)
      print("customdata:")
      print(click$customdata)
      
      # conduct query
      geneQuery <- dbGetQuery(con, paste0(
        "SELECT
          Genes.gene_id,
          GeneGo.go_term,
          GeneFunctions.gene_function
        FROM Genes
        LEFT JOIN GeneGo ON Genes.gene_id = GeneGo.gene_id
        LEFT JOIN GeneFunctions on Genes.gene_id = GeneFunctions.gene_id
        WHERE Genes.gene_id = '",click$customdata,"';"
      ))
      processedGeneInfo <- geneQuery %>%
        # mutate go_term to hyperlinks
        ## TODO: Combine GO terms into single cell
        mutate(
          go_term = if_else(
            is.na(go_term),
            '<i>Not available</i>',
            paste0('<a href="https://amigo.geneontology.org/amigo/term/',
                   go_term, '" target="_blank">', go_term, '</a>')
          ),
          gene_function = if_else(
            is.na(gene_function),
            '<i>Not available</i>',
            gene_function
          )
        )%>%
        # Group and summarise the table to have all GO terms in a single cell
        group_by(gene_id, gene_function) %>%
        summarise(go_term = paste(unique(go_term), collapse = "<br>"), .groups = 'drop')%>%
        # Reorder the columns to the correct order
        select(gene_id, go_term, gene_function)
      
      
      
      
      
      geneInfo(processedGeneInfo)
      # open tab
      showTab("navMenu", target = "Gene Info")
      updateTabsetPanel(session, "navMenu", selected = "Gene Info")
    }
  })

  ## ---- Download button downloads heatmap ----
  output$exportHeatmap <- downloadHandler(
    filename = function() {
      paste0(selectedContrast(), "_", 
             selectedAuthor(), "_", 
             selectedYear(), "_", 
             format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), 
             ".png")
    },
    content = function(file) {
      ggsave(
        filename = file,
        plot = heatmap(), 
        device = "png",
        width = 8,
        height = 6,
        dpi = 300
      )
    }
  )
  
  # ## ---- Download button downloads volcano plot ----
  # output$exportVolcano <- downloadHandler(
  #   filename = function() {
  #     paste0(selectedContrast(), "_", 
  #            selectedAuthor(), "_", 
  #            selectedYear(), "_", 
  #            format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), 
  #            ".png")
  #   },
  #   content = function(file) {
  #     ggsave(
  #       filename = file,
  #       plot = volcano(), 
  #       device = "png",
  #       width = 8,
  #       height = 6,
  #       dpi = 300
  #     )
  #   }
  # )
  
  
  ## ---- TEST: Run python script from r shiny ----
  # observeEvent(input$uploadData, {
  #   reticulate::py_run_file("/Users/tanyastead/Documents/MSc_Bioinformatics/11_Individual_Project/fungal-repository/database/DEG_Data/test_python.py")
  # })
  
  ## ---- Run populate_genes.py to populate database with DE data ----
  observeEvent(input$uploadDEData, {
    hasError <- FALSE
    
    # Add error messages if input fields are empty
    if (input$expAuthor == "") {
      showFeedbackDanger("expAuthor", "Author is required")
      hasError <- TRUE
    } else {
      hideFeedback("expAuthor")
    }
    if (input$expYear == "") {
      showFeedbackDanger("expYear", "Year is required")
      hasError <- TRUE
    } else {
      hideFeedback("expYear")
    }
    if (input$expTitle == "") {
      showFeedbackDanger("expTitle", "Title or description is required")
      hasError <- TRUE
    } else {
      hideFeedback("expTitle")
    }
    if (input$expSpecies == "") {
      showFeedbackDanger("expSpecies", "Fungal species is required")
      hasError <- TRUE
    } else {
      hideFeedback("expSpecies")
    }
    if (is.null(input$expKeywords) || length(input$expKeywords) == 0) {
      showFeedbackDanger("expKeywords", "At least 1 keyword is required")
      hasError <- TRUE
    } else {
      hideFeedback("expKeywords")
    }
    if (is.null(input$chooseDEData)) {
      showFeedbackDanger("chooseDEData", "Dataset is required")
      hasError <- TRUE
    } else {
      hideFeedback("chooseDEData")
    }
    
    # If any input failed validation, stop here
    if (hasError) return()
    
    
    # Build list of keywords
    keys <- c()
    for (key in input$expKeywords){
      keys <- c(keys, "-k", key)
    }
    print(keys)
    
    # Build list of arguments
    script_args <- c("database/populate_genes.py",
              "-g", input$chooseDEData$datapath,
              "-s", input$expSpecies,
              "-a", input$expAuthor,
              "-y", input$expYear,
              "-t", input$expTitle,
              "-d", "../database/repository.sqlite"
              )
    script_args <- c(script_args, keys)
    # print(args)
    
    # Convert arguments to python style sys.argv string
    arg_string <- paste0("import sys; sys.argv = ", toJSON(script_args, auto_unbox = TRUE))
    # print(arg_string)
    
    # # check that wd is correct
    # print(getwd())
    # py_run_string("import os; print('Python cwd:', os.getcwd())")
    
    # Run code to set sys.argv in python
    py_run_string(arg_string)
    
    withProgress(
      message = "Adding dataset to repository",
      value = 0.5,
      {
        # Run python script
        py_run_file("../database/populate_genes.py")
      }
    )
    
    # Clear the inputs
    # updateTextInput(session, "expAuthor", value = "")
    updateSelectizeInput(session, "expAuthor", choices = c("",authors$author), selected = "", server = TRUE)
    updateTextInput(session, "expYear", value = "")
    # updateTextInput(session, "expSpecies", value = "")
    updateSelectizeInput(session, "expSpecies", choices = c("",queriedSpecies$species), selected = "", server = TRUE)
    updateSelectizeInput(session, "expKeywords", choices = NULL, selected = NULL, server = TRUE)
    updateTextAreaInput(session, "expTitle", value = "")
    reset("chooseDEData")

  })
  
  ## ---- Run populate_annot.py to populate database with FA data ----
  observeEvent(input$uploadFAData, {
    hasError <- FALSE
    
    # Add error messages if input fields are empty
    if (is.null(input$chooseFAData)) {
      showFeedbackDanger("chooseFAData", "Dataset is required")
      hasError <- TRUE
    } else {
      hideFeedback("chooseFAData")
    }
    
    # If any input failed validation, stop here
    if (hasError) return()
    
    # Construct arguments
    if (input$goRadioFAData == "1"){
      script_args <- c("../database/populate_annot.py",
                "-a", input$chooseFAData$datapath,
                "-d", "../database/repository.sqlite",
                "-g")
    } else if (input$goRadioFAData == "2"){
      script_args <- c("../database/populate_annot.py",
                "-a", input$chooseFAData$datapath,
                "-d", "../database/repository.sqlite")
    }
    
    print("printing args--------------")
    print(script_args)
    # Convert arguments to python style sys.argv string
    arg_string <- paste0("import sys; sys.argv = ", toJSON(script_args, auto_unbox = TRUE))

    # Run code to set sys.argv in python
    py_run_string(arg_string)
    
    # Run python script
    withProgress(
      message = "Adding functional annotation to repository",
      value = 0.5,
      {
        # Run python script
        py_run_file("../database/populate_annot.py")
      }
    )
    
    # Clear the inputs
    reset("chooseFAData")
    
    
  })
  
}
