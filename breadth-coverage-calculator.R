#!/usr/bin/env Rscript 

args <- commandArgs(trailingOnly = TRUE) 

if (length(args) == 0) stop("Usage: Rscript coverage_check.R <file.txt>") 

data <- read.table(args[1], header = TRUE, skip = 1, comment.char = "") 

if (colnames(data)[1] %in% c("X.chr", "X..chr.")) colnames(data)[1] <- "chr" 

colnames(data) <- gsub("^X([0-9])", "\\1", colnames(data)) 

data <- data[grepl("^chr[0-9XY]+$", data$chr), ] 

samples <- setdiff(colnames(data), c("chr", "start", "end")) 

breadth_values <- numeric(length(samples))
names(breadth_values) <- samples
depth_mean_values <- numeric(length(samples))
frac_1x_values <- numeric(length(samples))

results_df <- data.frame(Sample = character(), Depth_mean = numeric(), Breadth = numeric(), Bases_1x = numeric(), stringsAsFactors = FALSE)

for (i in seq_along(samples)) {
    sample <- samples[i]
    depth_mean <- mean(data[[sample]]) 
    breadth_chr <- tapply(data[[sample]], data$chr, function(x) mean(x >= 1) * 100) 
    breadth <- median(breadth_chr) 
    frac_1x_chr <- tapply(data[[sample]], data$chr, function(x) mean(x >= 1) * 100) 
    frac_1x <- median(frac_1x_chr) 
    breadth_values[i] <- breadth
    depth_mean_values[i] <- depth_mean
    frac_1x_values[i] <- frac_1x
    results_df[i, ] <- c(sample, depth_mean, breadth, frac_1x)
} 

output_prefix <- gsub("\\.txt$", "", basename(args[1]))
output_prefix <- gsub("\\.tab$", "", output_prefix)

colnames(results_df) <- c("Sample", "Depth_mean", "Breadth", "Bases_>=1x")
write.table(results_df, file = paste0(output_prefix, "_stats.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)

pdf(paste0(output_prefix, "_breadth_coverage.pdf"), width = 12, height = 7)

par(mar = c(12, 5, 4, 2))
barplot_obj <- barplot(breadth_values, 
        main = "",
        ylab = "Breadth Coverage (bases >= 1x) (%)",
        xlab = "",
        las = 1,
        col = "grey70",
        names.arg = "",
        ylim = c(0, 110),
        border = "black",
        axes = TRUE)

text(x = barplot_obj, 
     y = -5, 
     labels = names(breadth_values), 
     srt = 45, 
     adj = 1, 
     xpd = TRUE, 
     cex = 0.7)

text(x = barplot_obj, 
     y = breadth_values + 3, 
     labels = sprintf("%.1f%%", breadth_values), 
     cex = 0.8, 
     pos = 3)

box()

dev.off()
