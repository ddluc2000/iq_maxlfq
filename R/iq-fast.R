#########################################################################
#
# Author: Thang V. Pham, t.pham@amsterdamumc.nl
#
# All rights reserved.
#
# Citation:
#
# Pham TV, Henneman AA, Jimenez CR. iq: an R package to estimate relative protein abundances from ion quantification in DIA-MS-based proteomics, Bioinformatics 2020 Apr 15;36(8):2611-2613.
#
# Software version: 1.9.6
#
#########################################################################

fast_read <- function(filename,
                      sample_id = "R.Condition",
                      primary_id = "PG.ProteinGroups",
                      secondary_id = c("EG.ModifiedSequence", "FG.Charge", "F.FrgIon", "F.Charge"),
                      intensity_col = "F.PeakArea",
                      annotation_col = c("PG.Genes", "PG.ProteinNames"),
                      filter_string_equal = c("F.ExcludedFromQuantification" = "False"),
                      filter_double_less = c("PG.Qvalue" = "0.01", "EG.Qvalue" = "0.01"),
                      intensity_col_sep = NULL,
                      intensity_col_id = NULL,
                      na_string = "0") {

    cmd <- paste0("--sample ", sample_id,
                  " --primary ", primary_id,
                  " --secondary ", paste(secondary_id, collapse = " "),
                  " --quant ", intensity_col)

    if (!is.null(annotation_col)) {
        cmd <- paste0(cmd, " --annotation ", paste(annotation_col, collapse = " "))
    }

    if (!is.null(filter_string_equal)) {
        for (f in names(filter_string_equal)) {
            cmd <- paste0(cmd, " --filter-string-equal ", f, " ", filter_string_equal[f])
        }
    }

    if (!is.null(filter_double_less)) {
        for (f in names(filter_double_less)) {
            cmd <- paste0(cmd, " --filter-double-less ", f, " ", filter_double_less[f])
        }
    }

    if (!is.null(intensity_col_sep)) {
        cmd <- paste0(cmd, " --intensity_col_sep ", intensity_col_sep)
        cmd <- paste0(cmd, " --na_string ", na_string)
    }

    if (!is.null(intensity_col_id)) {
        cmd <- paste0(cmd, " --intensity_col_id ", intensity_col_id)
    }

    return(.Call("iq_filter", as.character(paste0(cmd, " ", filename))))
}

fast_MaxLFQ <- function(norm_data, row_names = NULL, col_names = NULL) {

    # check for NA values
    if (any(is.na(norm_data$protein_list))) {
        stop("NA value in $protein_list.\n")
    }

    if (any(is.na(norm_data$sample_list))) {
        stop("NA value in $sample_list.\n")
    }

    if (any(is.na(norm_data$id))) {
        stop("NA value in $id.\n")
    }

    if (any(is.na(norm_data$quant))) {
        stop("NA value in $quant.\n")
    }

    if (is.null(row_names)) {
        proteins <- unique(as.character(norm_data$protein_list))
        p_list <- as.integer(factor(as.character(norm_data$protein_list), levels = proteins))
    } else {
        proteins <- as.character(row_names)
        p_list <- as.integer(norm_data$protein_list)
    }

    if (is.null(col_names)) {
        s <- unique(as.character(norm_data$sample_list))
        s_list <- as.integer(factor(as.character(norm_data$sample_list), levels = s))
    } else {
        s <- as.character(col_names)
        s_list <- as.integer(norm_data$sample_list)
    }

    ret <- .Call("iq_MaxLFQ",
                 list(protein_index = p_list,
                      ion_index = as.integer(factor(norm_data$id)),
                      sample_index = s_list,
                      quant = as.double(norm_data$quant)))

    rownames(ret$estimate) <- proteins[as.integer(rownames(ret$estimate))]

    colnames(ret$estimate) <- s[as.integer(colnames(ret$estimate))]

    return(ret)

}

fast_preprocess <- function(quant_table,
                            median_normalization = TRUE,
                            log2_intensity_cutoff = 0,
                            pdf_out = "qc-plots-fast.pdf",
                            pdf_width = 12,
                            pdf_height = 8) {

    if (!is.null(pdf_out)) {
        pdf(pdf_out, pdf_width, pdf_height)
    }

    d <- quant_table

    d$quant <- log2(d$quant)

    samples <- unique(d$sample_list)

    # intensity cut off
    if (!is.null(log2_intensity_cutoff)) {
        message("Removing low intensities...\n")
        if (!is.null(pdf_out)) {
            a <- hist(d$quant, 100, col = "steelblue", border = "steelblue", freq = FALSE,
                      main = "Histogram of log2 intensities",
                      xlab = "log2 intensity")
            arrows(log2_intensity_cutoff, 0, log2_intensity_cutoff, max(a$density) / 2.0 , col = "red", code = 1, lwd = 2)
        }
        selected <- d$quant > log2_intensity_cutoff
        d$quant <- d$quant[selected]
        d$protein_list <- d$protein_list[selected]
        d$sample_list <- d$sample_list[selected]
        d$id <- d$id[selected]
    }


    dl <- list()
    m <- rep(NA, length(samples))
    for (i in 1:length(samples)) {
      dl[i] <- list(d$quant[d$sample_list == samples[i]])
      m[i] <- median(dl[[i]], na.rm = TRUE)
    }

    if (!is.null(pdf_out)) {
        message("Barplotting raw data ...\n")

        boxplot(dl,
            names = as.character(samples),
            col = "steelblue",
            whisklty = 1,
            staplelty = 0,
            outpch = ".",
            las = 2)
    }

    if (median_normalization) {

        message("Median normalization ...\n")

        f <- mean(m) - m

        for (i in 1:length(samples)) {
            idx <- d$sample_list == samples[i]
            d$quant[idx] <- d$quant[idx] + f[i]
        }

        if (!is.null(pdf_out)) {
            message("Barplotting after normalization ...\n")

            dl <- list()
            m <- rep(NA, length(samples))
            for (i in 1:length(samples)) {
                dl[i] <- list(d$quant[d$sample_list == samples[i]])
                m[i] <- median(dl[[i]], na.rm = TRUE)
            }

            boxplot(dl,
                    names = as.character(samples),
                    col = "steelblue",
                    whisklty = 1,
                    staplelty = 0,
                    outpch = ".",
                    las = 2)
        }
    }

    if (!is.null(pdf_out)) {
        dev.off()
    }

    return(d)
}

process_long_format <- function(input_filename,
                                output_filename,
                                sample_id = "File.Name",
                                primary_id = "Protein.Group",
                                secondary_id = "Precursor.Id",
                                intensity_col = "Fragment.Quant.Corrected",
                                annotation_col = NULL,
                                filter_string_equal = NULL,
                                filter_double_less = c("Q.Value" = "0.01", "PG.Q.Value" = "0.01"),
                                intensity_col_sep = ";",
                                intensity_col_id = NULL,
                                na_string = "0",
                                normalization = "median",
                                log2_intensity_cutoff = 0,
                                pdf_out = "qc-plots.pdf",
                                pdf_width = 12,
                                pdf_height = 8) {


    if (normalization == "median") {
        median_normalization <- TRUE
    } else if (normalization == "none") {
        median_normalization <- FALSE
    } else {
        stop("Unknown normalization method.")
    }

    iq_dat <- fast_read(input_filename,
                        primary_id = primary_id,
                        sample_id  = sample_id,
                        secondary_id = secondary_id,
                        intensity_col = intensity_col,
                        intensity_col_sep = intensity_col_sep,
                        annotation_col = annotation_col,
                        filter_string_equal = filter_string_equal,
                        filter_double_less = filter_double_less)

    if (!is.null(iq_dat)) {
        iq_norm_data <- fast_preprocess(iq_dat$quant_table,
                                        median_normalization = median_normalization,
                                        log2_intensity_cutoff = log2_intensity_cutoff,
                                        pdf_out = pdf_out,
                                        pdf_width = pdf_width,
                                        pdf_height = pdf_height)

        res <- fast_MaxLFQ(iq_norm_data,
                           row_names = iq_dat$protein[, 1],
                           col_names = iq_dat$sample)

        message("Writing to: ", output_filename)

        if (is.null(annotation_col)) {

            tab <- cbind(rownames(res$estimate), res$estimate)
            colnames(tab)[1] <- primary_id

        } else {

            extra_annotation <- extract_annotation(rownames(res$estimate),
                                                   iq_dat$protein,
                                                   primary_id = primary_id,
                                                   annotation_columns = annotation_col)

            tab <- cbind(rownames(res$estimate),
                         extra_annotation[, annotation_col],
                         res$estimate)
            colnames(tab)[1:(length(annotation_col)+1)] <- c(primary_id, annotation_col)
        }

        write.table(tab, output_filename, sep = "\t", row.names = FALSE, quote = FALSE)
    }

    invisible(NULL)
}
