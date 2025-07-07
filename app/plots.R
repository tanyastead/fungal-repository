# File to store functions used to create plots in main app

# Interactive Volcano plot function
interactive_volcano <- function(data, lFC, pv, cont){
  # 1. subset the df to obtain just the gene name, log2FC and padj
  subset_df <- data[c("gene_id", "log2FC", "padj", "gene_function")]
  
  # 1.5 convert the gene_function from hyperlinks into plain text
  subset_df$gene_function_plain <- sapply(subset_df$gene_function, function(html) {
    xml_text(read_html(html))
  })
  
  # 2. Add a column to say if genes are up, down, or not differentially expressed
  subset_df$diffexpressed <- "Not significant"
  subset_df$diffexpressed[subset_df$log2FC > lFC & subset_df$padj < pv] <- "Upregulated"
  subset_df$diffexpressed[subset_df$log2FC < -lFC & subset_df$padj < pv] <- "Downregulated"
  
  # 3. Add a column calculating -log10(padj)
  subset_df$neg_log10_padj <- -log10(subset_df$padj)
  
  # 4. Create a cap at the 95th percentile for neg_log10_padj values
  subset_df$neg_log10_padj[is.infinite(subset_df$neg_log10_padj)] <- NA  # temporarily remove for percentile calc
  y_cap <- quantile(subset_df$neg_log10_padj, 0.95, na.rm = TRUE)  # calculate 95th percentile value
  subset_df$neg_log10_padj[is.na(subset_df$neg_log10_padj)] <- y_cap #replace na values with y_cap
  
  # 5. Determine the y-axis limit
  # if(max(-log10(subset_df$pval)) == Inf){
  #   y_axis_lim <- y_cap
  # } else {
  #   y_axis_lim <- max(-log10(subset_df$pval))
  # }
  y_axis_lim <- max(subset_df$neg_log10_padj, na.rm = TRUE)
  
  # Create the plot
  plot <- ggplot(data = subset_df, 
                 aes(x = log2FC, 
                     y = neg_log10_padj, 
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
             label = paste0("p-adjusted:\n", pv),
             hjust = 1.1,
             vjust = -0.5,
             size = 2,
             color = "black")+
    geom_point(size = 1) +
    scale_color_manual(
      values = c("Downregulated" = "#00AFBB", "Not significant" = "grey", "Upregulated" = "#F8766D"),
      labels = c("Downregulated" = "Downregulated", "Not significant" = "Not significant", "Upregulated" = "Upregulated")
    ) + # to set the labels 
    coord_cartesian(
      ylim = c(0, y_axis_lim),
      # ylim = c(0, min(100, max(-log10(subset_df$pval), na.rm = TRUE))),
      xlim = c(floor(min(subset_df$log2FC)), ceiling(max(subset_df$log2FC)))
    ) + # since some genes can have minuslog10padj of inf, we set these limits
    labs(color = 'Expression', #legend_title, 
         x = "log2 Fold Change", y = "-log10 p-value") +
    ggtitle(paste0("Volcano plot of contrast ", cont, "\n",
                   "log fold change = ", lFC, " and p-adjusted = ", pv)) +
    theme(axis.text.x = element_text(size = 8),  plot.title = element_text(size = 10)) +
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
  
  # print(subset_df)
  # print(max(-log10(subset_df$pval)))
  # print(min(-log10(subset_df$pval)))
  
  return(plot)
}

# Gene Expression Heatmap function
DEG_heatmap <- function(data){
  plot <- ggplot(data, aes(x = contrast, y = gene_id, fill = log2FC)) +
    geom_tile() +
    scale_fill_gradient2(low = "#00AFBB", mid = "grey80", high = "#F8766D", midpoint = 0) +
    theme_light() +
    labs(x = "Contrast", y = "Gene ID", fill = "log2FC") +
    theme(
      panel.grid.major.x = element_blank(),   # ❌ Remove vertical major gridlines
      # panel.grid.minor.x = element_blank(),   # ❌ Remove vertical minor gridlines
      panel.grid.major.y = element_line(color = "grey80"),  # ✅ Keep horizontal gridlines
      axis.text.x = element_text(angle = 45, hjust = 1),
      axis.text.y = element_text(size = 10)
    )
  return(plot)
}

