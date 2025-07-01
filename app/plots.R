# File to store functions used to create plots in main app

# Interactive Volcano plot function
interactive_volcano <- function(data, lFC, pv){
  # 1. subset the df to obtain just the gene name, log2FC and pval
  subset_df <- data[c("gene_id", "log2FC", "pval")]
  
  # 2. Add a column to say if genes are up, down, or not differentially expressed
  subset_df$diffexpressed <- "Not significant"
  subset_df$diffexpressed[subset_df$log2FC > lFC & subset_df$pval < pv] <- "Upregulated"
  subset_df$diffexpressed[subset_df$log2FC < -lFC & subset_df$pval < pv] <- "Downregulated"
  
  # 3. Add a column calculating -log10(pval)
  subset_df$neg_log10_pval <- -log10(subset_df$pval)
  
  # 4. Create a cap at the 95th percentile for neg_log10_pval values
  subset_df$neg_log10_pval[is.infinite(subset_df$neg_log10_pval)] <- NA  # temporarily remove for percentile calc
  y_cap <- quantile(subset_df$neg_log10_pval, 0.95, na.rm = TRUE)  # calculate 95th percentile value
  subset_df$neg_log10_pval[is.na(subset_df$neg_log10_pval)] <- y_cap #replace na values with y_cap
  
  # 5. Determine the y-axis limit
  # if(max(-log10(subset_df$pval)) == Inf){
  #   y_axis_lim <- y_cap
  # } else {
  #   y_axis_lim <- max(-log10(subset_df$pval))
  # }
  y_axis_lim <- max(subset_df$neg_log10_pval, na.rm = TRUE)
  
  # Create the plot
  plot <- ggplot(data = subset_df, 
                 aes(x = log2FC, 
                     y = neg_log10_pval, 
                     col = diffexpressed, 
                     text = paste0("Gene: ", gene_id,"<br>",
                                   "Expression: ", diffexpressed,"<br>",
                                   "Log2 fold change: ", log2FC,"<br>",
                                   "-log10 p-value: ", neg_log10_pval) )) +
    geom_vline(xintercept = c(-lFC, lFC), col = "gray", linetype = 'dashed') + # Set intercept lines
    geom_hline(yintercept = -log10(pv), col = "gray", linetype = 'dashed') +
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
         x = "log2 Fold Change", y = "-log10 p-value") 
    # scale_x_continuous(breaks = seq(floor(min(subset_df$log2FC)), ceiling(max(subset_df$log2FC)), 2)) # to customise the breaks in the x axis
  
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

