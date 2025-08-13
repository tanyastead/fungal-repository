# File to store functions used to create plots in main app

# Interactive Volcano plot function
interactive_volcano <- function(data, lFC, pv, cont, pmetric){
  # 1. subset the df to obtain just the gene name, log2FC and padj
  subset_df <- data[c("gene_id", "log2FC", "padj", "pval", "gene_function")]
  
  # 1.5 convert the gene_function from hyperlinks into plain text
  subset_df$gene_function_plain <- sapply(subset_df$gene_function, function(html) {
    if (str_detect(html, "<.*?>")) {
      xml_text(read_html(html))
    } else {
      html  # already plain text, return as-is
    }
  })
  
  # 1.8 save proper pmetric name
  if (pmetric == "pval"){
    metric <- "p-value"
  } else if (pmetric == "padj"){
    metric <- "p-adjusted"
  }
  
  # 2. Add a column to say if genes are up, down, or not differentially expressed
  subset_df$diffexpressed <- "Not significant"
  subset_df$diffexpressed[subset_df$log2FC > lFC & subset_df[[pmetric]] < pv] <- "Upregulated"
  subset_df$diffexpressed[subset_df$log2FC < -lFC & subset_df[[pmetric]] < pv] <- "Downregulated"
  
  # 3. Add a column calculating -log10(pmetric)
  subset_df$neg_log10_pmetric <- -log10(subset_df[[pmetric]])
  
  # 4. Create a cap at the 95th percentile for neg_log10_pmetric values
  subset_df$neg_log10_pmetric[is.infinite(subset_df$neg_log10_pmetric)] <- NA  # temporarily remove for percentile calc
  y_cap <- quantile(subset_df$neg_log10_pmetric, 0.995, na.rm = TRUE)  # calculate 95th percentile value
  subset_df$neg_log10_pmetric[is.na(subset_df$neg_log10_pmetric)] <- y_cap #replace na values with y_cap
  
  # 5. Calculate logFC 95th percentile for logFC
  lfc_95 <- quantile(abs(subset_df$log2FC), 0.995, na.rm = TRUE)
  
  print(paste0("ycap: ", y_cap, " lfc95: ", lfc_95))
  
  # 6. Calculate outliers
  subset_df$outliers <- ifelse(subset_df$neg_log10_pmetric >= y_cap & abs(subset_df$log2FC) >= lfc_95,
                               paste(subset_df$gene_id),
                               NA)
  # paste0("Gene: ", gene_id, "<br>",
  #        "Functional annotation: ", gene_function_plain)
  # 5. Determine the y-axis limit
  # if(max(-log10(subset_df$pval)) == Inf){
  #   y_axis_lim <- y_cap
  # } else {
  #   y_axis_lim <- max(-log10(subset_df$pval))
  # }
  y_axis_lim <- max(subset_df$neg_log10_pmetric, na.rm = TRUE)
  
  # Create the plot
  plot <- ggplot(data = subset_df, 
                 aes(x = log2FC, 
                     y = neg_log10_pmetric, 
                     col = diffexpressed, 
                     # text = paste0("Gene: ", gene_id,"<br>",
                     #               "Expression: ", diffexpressed,"<br>",
                     #               "Log2 fold change: ", log2FC,"<br>",
                     #               "-log10 p-value: ", neg_log10_pval) 
                     text = paste0("Gene: ", gene_id, "<br>",
                                   "Functional annotation: ", gene_function_plain),
                     key = gene_id
                     )) +
    geom_vline(xintercept = c(-lFC, lFC), col = "gray", linetype = 'dashed') + # Set intercept lines
    geom_hline(yintercept = -log10(pv), col = "gray", linetype = 'dashed') +
    annotate("text",
             x = max(subset_df$log2FC),
             y = -log10(pv),
             label = paste0(metric,":\n", pv),
             hjust = 1.1,
             vjust = -0.5,
             size = 2,
             color = "black")+
    geom_point(size = 1) +
    scale_color_manual(
      values = c("Downregulated" = "blue", "Not significant" = "grey", "Upregulated" = "red"),
      labels = c("Downregulated" = "Downregulated", "Not significant" = "Not significant", "Upregulated" = "Upregulated")
    ) + # to set the labels 
    coord_cartesian(
      ylim = c(0, y_axis_lim),
      # ylim = c(0, min(100, max(-log10(subset_df$pval), na.rm = TRUE))),
      xlim = c(floor(min(subset_df$log2FC)), ceiling(max(subset_df$log2FC)))
    ) + # since some genes can have minuslog10padj of inf, we set these limits
    labs(color = 'Expression', #legend_title, "Log<sub>2</sub>-fold change"
         x = "Log<sub>2</sub>-fold change", y = paste0("-log<sub>10</sub> ", metric)) +
    ggtitle(paste0("Volcano plot of contrast ", cont, "\n",
                   "Log<sub>2</sub>-fold change = ", lFC, " and ", metric, " = ", pv)) +
    theme(axis.text.x = element_text(size = 8),  plot.title = element_text(size = 10)) +
    ## working code, just not sure if this is how i want to identify and label outliers...
    # geom_text(aes(label = outliers), vjust = -1)+
    
    # scale_y_continuous(
    #   name = "-log10(p-adj)",
    #   sec.axis = sec_axis(
    #     trans = ~ 10^(-.),
    #     name = "p-adjusted",
    #     breaks = c(0.1, 0.01, 0.001, 0.0001),
    #     labels = scales::label_scientific()
    #   )
    # )+
    scale_x_continuous(breaks = seq(floor(min(subset_df$log2FC)), ceiling(max(subset_df$log2FC)), 2)) # to customise the breaks in the x axis
  
  
  return(plot)
}

# Gene Expression Heatmap function
DEG_heatmap <- function(data){
  data$customdata <- data$gene_id
  plot <- ggplot(data, aes(x = contrast, 
                           y = gene_id, 
                           fill = log2FC, 
                           text = paste0("Gene: ", gene_id, "<br>",
                                          "Functional annotation: ", gene_function, "<br>",
                                         "Log<sub>2</sub>-fold change: ", log2FC),
                           key = gene_id,
                           customdata = gene_id, 
                           group = gene_id
                           )) +
    geom_tile() +
    scale_fill_gradient2(low = "blue", mid = "grey", high = "red", midpoint = 0, limits = c(-3, 3), oob = scales::squish) +
    theme_light() +
    labs(x = "Contrast", y = "Gene ID", fill = "log2FC") +
    ggtitle("Gene expression")+
    theme(
      panel.grid.major.x = element_blank(),   # ❌ Remove vertical major gridlines
      # panel.grid.minor.x = element_blank(),   # ❌ Remove vertical minor gridlines
      panel.grid.major.y = element_line(color = "grey80"),  # ✅ Keep horizontal gridlines
      axis.text.x = element_text(angle = 45, hjust = 1, size = 7),
      axis.text.y = element_text(size = 7)
    )
  return(plot)
}


# Create plotly heatmap
plotly_DEG_heatmap <- function(data){
  # Set the min and max values for the colour scale
  # if (any(data$log2FC < -1)){
  #   zmin <- min(data$log2FC)
  # } else {
  #   zmin <- -2
  # }
  # 
  # if (any(data$log2FC > 1)){
  #   zmax <- max(data$log2FC)
  # } else {
  #   zmax <- 2
  # }
  
  # zmid <- 0
  # midpoint <- (zmid - zmin) / (zmax - zmin)
  
  plot <- plot_ly(
    data = data,
    x = ~contrast,
    y = ~gene_id,
    z = ~log2FC,
    type = "heatmap",
    # zmin = zmin,
    # zmax = zmax,
    zmin = -3,
    zmax = 3,
    colorscale = list(
      list(-3, "blue"),
      list(0, "grey"),
      list(3, "red")
    ),
    text = ~paste0(
      "Gene: ", gene_id, "<br>",
      "Function: ", gene_function, "<br>",
      "Log<sub>2</sub>-fold change: ", round(log2FC, 3)
    ),
    customdata = ~gene_id,
    hoverinfo = "text",
    source = "heat",
    colorbar = list(title = list(text = "Log<sub>2</sub>-fold change"))
  ) %>%
    layout(title = "Gene Expression", 
           xaxis = list(title = "Contrast"
                        , tickangle = -45
                        ), 
           yaxis = list(title = "Gene ID")
           # legend = list(title=list(text='<br> Log fold change <br>'))
           ) 
}
