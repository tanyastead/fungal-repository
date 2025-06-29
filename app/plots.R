# File to store functions used to create plots in main app

# Interactive Volcano plot function
interactive_volcano <- function(data, lFC, pv){
  # 1. subset the df to obtain just the gene name, log2FC and pval
  subset_df <- data[c("gene_id", "log2FC", "pval")]
  
  # 2. Add a column to say if genes are up, down, or not differentially expressed
  subset_df$diffexpressed <- "NO"
  subset_df$diffexpressed[subset_df$log2FC > lFC & subset_df$pval < pv] <- "UP"
  subset_df$diffexpressed[subset_df$log2FC < -lFC & subset_df$pval < pv] <- "DOWN"
  
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
  plot <- ggplot(data = subset_df, aes(x = log2FC, y = neg_log10_pval, col = diffexpressed, text = paste("Gene:", gene_id) )) +
    geom_vline(xintercept = c(-lFC, lFC), col = "gray", linetype = 'dashed') + # Set intercept lines
    geom_hline(yintercept = -log10(pv), col = "gray", linetype = 'dashed') +
    geom_point(size = 2) +
    scale_color_manual(
      values = c("DOWN" = "#00AFBB", "NO" = "grey", "UP" = "#F8766D"),
      labels = c("DOWN" = "Downregulated", "NO" = "Not significant", "UP" = "Upregulated")
    ) + # to set the labels 
    coord_cartesian(
      ylim = c(0, y_axis_lim),
      # ylim = c(0, min(100, max(-log10(subset_df$pval), na.rm = TRUE))),
      xlim = c(-10, 10)
    ) + # since some genes can have minuslog10padj of inf, we set these limits
    labs(color = 'Expression', #legend_title, 
         x = "log2 Fold Change", y = "-log10 p-value") + 
    scale_x_continuous(breaks = seq(-10, 10, 2)) # to customise the breaks in the x axis
  
  print(subset_df)
  print(max(-log10(subset_df$pval)))
  print(min(-log10(subset_df$pval)))
  
  return(plot)
}