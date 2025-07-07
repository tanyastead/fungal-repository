# server.R
server <- function(input, output, session) {
  # Cleanly close the DB connection on ending the session
  session$onSessionEnded(function() {
    dbDisconnect(con)
  })
  
  ## Setup the initial state
  # hide all unnecessary tabs
  hideTab("navMenu", target = "Results")
  hideTab("navMenu", target = "Experiments")
  
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
  
  # refSpec <- reactiveVal()
  
  ## SEARCH TAB
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
    updateRadioButtons(session, "lFCRegulation", selected = "Up- or Downregulated")
    
    ### COMBINING GENEID AND GENE FUNCTION SEARCH
    if (input$term == "Gene (Name or Function)"){
      req(input$query)
      # Query the DB
      tableQuery <- dbGetQuery(con, paste0("
            SELECT Genes.species, ExpKeywords.keyword, GeneFunctions.go_term, GeneFunctions_FTS.gene_id, GeneFunctions_FTS.gene_function,
            GeneContrasts.contrast, Experiments.author,Experiments.year,Experiments.description
            FROM GeneFunctions_FTS
            JOIN Genes ON GeneFunctions_FTS.gene_id = Genes.gene_id
            JOIN GeneFunctions on GeneFunctions_FTS.gene_id = GeneFunctions.gene_id
            JOIN GeneContrasts ON GeneFunctions_FTS.gene_id = GeneContrasts.gene_id
            JOIN Experiments ON GeneContrasts.experiment_id = Experiments.experiment_id
            JOIN ExpKeywords ON Experiments.experiment_id = ExpKeywords.experiment_id
            WHERE GeneFunctions_FTS MATCH '",input$query,"';
            "))
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
        # mutate gene function as hyperlinks set to open go term page
        mutate(gene_function = paste0('<a href="https://amigo.geneontology.org/amigo/term/',
                                      go_term, '" target="_blank">', gene_function, '</a>')) %>%
        # groups table where ALL listed values are identical
        group_by(species, gene_id, go_term,gene_function, author, year, description) %>%
        # collapse contrasts/hyperlinks into a single string separated by a <br> so they appear on newlines in a single cell
        summarise(contrasts = paste(unique(hyperlink), collapse = "<br>"),
                  keywords = paste(unique(keyword), collapse = "; "),
                  .groups = 'drop') %>%
        # sort the order of the columns
        select(species, keywords, go_term, gene_id, gene_function, contrasts, author, year, description)
      
      # Save the processedTable outside the observeEvent
      queryData(processedTable)
      
      # Save specific column names outside the observeEvent
      colnames(c("Species","Keywords","GO Term","Gene", "Functional Annotation", "Contrasts", "Author", "Year", "Description"))
      
      # save number of columns to hide
      hidden_columns(c(0:2))
      
      # Switch view to the Results tab
      showTab("navMenu", target = "Results")
      updateTabsetPanel(session, "navMenu", selected = "Results")
      
    } else if (input$term == "Keyword") {
      req(input$query)
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
      
    }
    
    # Filter based on keyword
    if (!is.null(input$refineCondition)){
      keyword_pattern <- str_c(input$refineCondition, collapse = "|")
      data <- data %>%
        filter(str_detect(keywords, regex(keyword_pattern, ignore_case = TRUE)))
      # output$speciesMessage <- renderText(paste0("species has been redifned to: ", (input$refineCondition)))
      
    }
    # output$troubleshootingCondition <- renderPrint(data$keywords)
    return(data)
  })
  
  
  ## Render the query table in the results tab
  output$tableData <- DT::renderDataTable({
    req(filteredData())
    
    DT::datatable(filteredData(),
                  rownames = FALSE,
                  colnames = colnames(),
                  options = list(
                    columnDefs = list(
                      list(visible = FALSE, targets = hidden_columns())
                      )
                    ), # Hide the unecessary columns
                  escape = FALSE)
  })
  
  ## Clear button resets side panel values
  observeEvent(input$clearResults, {
    updateSelectizeInput(session, "refineSpecies", selected = character(0))
    updateSelectizeInput(session, "refineCondition", selected = character(0))
    updateTextInput(session, "fromYear", value = "")
    updateTextInput(session, "toYear", value = "")
  })
  
  ## Export button downloads table
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
    
    # Identify possible genes and relevant values based on selected contrast
    geneValues <- dbGetQuery(con, paste0(
      "SELECT 
        GeneFunctions.go_term,
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
      mutate(gene_function = paste0('<a href="https://amigo.geneontology.org/amigo/term/',
                                    go_term, '" target="_blank">', gene_function, '</a>'))
      
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
  
  ## Refine the Experiments table
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
      data <- data %>%
        filter(reduce(input$refineFunctionExp, 
                      ~ .x | str_detect(gene_function, fixed(.y, ignore_case = TRUE)),
                      .init = FALSE))
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
  
  ## See what is being outputted 
  # output$testSearchExpOutput <- renderText({
  #   paste0("placeholder, typeof:",typeof(input$testSearchExp), " stored: ", input$testSearchExp)
  # })

  # ## Render the experiment table in the experiments tab
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
              escape = FALSE)
  })
  
  ## Download button downloads table
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
  
  ## Clear button resets side panel values
  observeEvent(input$clearExperiments, {
    updateSelectizeInput(session, "refineGene", selected = character(0))
    updateSelectizeInput(session, "refineFunctionExp", choices = NULL, selected = NULL, server = TRUE)
    updateNumericInput(session, "pvalue", value = NA)
    updateNumericInput(session, "padj", value = NA)
    updateNumericInput(session, "lFC", value = NA)
    updateRadioButtons(session, "lFCRegulation", selected = "Up- or Downregulated")
  })
  
  ## Generate interactive volcano plot
  output$volcanoPlot <- renderPlotly({
    entire_df <- experimentData()
    # entire_df <- filteredExpData()
    # remove empty pval 
    entire_df <- filter(entire_df, !is.na(pval))
      
    # Set significant values for log2FC and padj
    if (!is.null(input$lFC) && !is.na(input$lFC)){
      fold <- input$lFC
    } else {
      fold <- 1
    }
    if (!is.null(input$padj) && !is.na(input$padj)){
      pval <- input$padj
    } else {
      pval <- 0.05
    }
    
    # create ggplot volcano plot
    p <- interactive_volcano(data = entire_df, lFC = fold, pv = pval, cont = selectedContrast())
    
    # save plot so it can be downloaded
    volcano(p)
    
    # display interactive plot
    ggplotly(p, tooltip = "text") %>% layout(
      margin = list(t = 80)  # Increase top margin (default is usually ~50)
    )
  })
  
  ## Download button downloads volcano plot
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
  
 

  output$heatmap <- renderPlot({
    ##TODO: Set log2FC scale to static???

    # Execute DB search
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
      filtered_genes <- filtered_genes %>%
        filter(reduce(input$refineFunctionExp,
                      ~ .x | str_detect(gene_function, fixed(.y, ignore_case = TRUE)),
                      .init = FALSE))
    }
    if (!is.null(input$pvalue) && !is.na(input$pvalue)){
      filtered_genes <- filter(filtered_genes, pval < input$pvalue)
    }
    if (!is.null(input$padj) && !is.na(input$padj)){
      filtered_genes <- filter(filtered_genes, padj < input$padj)
    }
    if (!is.null(input$lFC) && !is.na(input$lFC)){
      if (input$lFCRegulation == "Up- or Downregulated"){
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

    # generate heatmap only if <20 genes are selected
    if (nrow(plot_data) < (20 * length(unique(all_DEGs$contrast)))){
      # Wipe the message
      output$heatmapText <- NULL
      # Plot the heatmap
      plot <- DEG_heatmap(plot_data)
      heatmap(plot)
      plot
      
    } else {
      # Print output mnessage
      output$heatmapText <- renderUI({
        HTML('<span style="font-weight: bold;">
          Too many genes selected!<br>
          <i>Select fewer than 20 genes to generate expression heatmap</i>
        </span>')
      })
      # Colour the empty plot space to match the background
      par(bg = "#f5f7fa")
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "", main = "")
    }
    
    

  })

  # print when point is clicked
  output$testVolcanoClick <- renderPrint({
    click <- event_data("plotly_click")
    if (!is.null(click)){
      print(click$key)
    }
  })
  # observeEvent({
  #   # TODO: Get click event working properly
  #   click <- event_data("plotly_click")
  #   print("point has been clicked")
  #   print(click)
  # })
  
  ## Download button downloads heatmap
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
  

}
