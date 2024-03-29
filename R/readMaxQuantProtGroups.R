

#' Reading MaxQuant Output
#'
#' Reads in "proteinGroups.txt" output (or its compressed version) as MSnSet.
#'
#' As feature data, only first
#' 12 columns and iBAQ columns are used. Features are based on the genes.
#' In case of multiple proteins matching the same gene, only the one with
#' the highest iBAQ value is returned.
#' @note The "proteinGroups.txt" file can be compressed (gzip) to save space.
#' @param path character path to the folder containing "proteinGroups.txt file".
#'          It should be in "{raw files folder}/combined/txt"
#' @param quantType character Defines pattern what type of column to
#'                  use for quantificaiton.
#'                  E.g. "LFQ intensity" or "Ratio H/L normalized".
#' @param verbose numeric controls the text output
#'
#' @note It looks like the convention for column naming in MaxQuant is
#'       type of quantification followed by sample name separated by space.
#'       E.g. "LFQ intensity Sample1" or "Ratio H/L normalized Control33".
#'       In \code{quantType} you need to specify the full first component
#'       in the name that defines the type of quantification.
#'
#' @note iBAQ option must be enabled in MaxQuant analysis because it is used
#'       to resolve ambiguity between two proteins matching one gene.
#'
#' @return \code{MSnSet} object
#'
#' @importFrom MSnbase MSnSet
#' @importFrom dplyr %>% group_by slice_max ungroup
#' @importFrom utils read.delim
#'
#' @export readMaxQuantProtGroups
#'
#' @examples
#'
#' # label-free data
#' m <- readMaxQuantProtGroups(system.file("extdata/MaxQuant",
#'                                          package="MSnSet.utils"),
#'                             quantType="LFQ intensity")
#' exprs(m) <- log2(exprs(m))
#' exprs(m) <- sweep(exprs(m), 1, rowMeans(exprs(m), na.rm=TRUE), '-')
#' image_msnset(m)
#'
#' # O18/O16 data
#' m <- readMaxQuantProtGroups(system.file("extdata/MaxQuant_O18",
#'                                          package="MSnSet.utils"),
#'                             quantType="Ratio H/L normalized")
#' exprs(m) <- log2(exprs(m))
#' exprs(m) <- sweep(exprs(m), 1, rowMeans(exprs(m), na.rm=TRUE), '-')
#' image_msnset(m)


readMaxQuantProtGroups <- function(path, quantType, verbose=1){
    # no options in the current version
    # use genes for IDs

    #.. get dataset names
    # dataset names are in the summary.txt

    smmr <- readMaxQuantSummary(path)



    # fpath <- file.path(path, "proteinGroups.txt")
    # I assume the file can be compressed for the sake of space
    # thus there is a bit relaxed search for file
    fpath <-
        list.files(path = path,
                   pattern = "proteinGroups.txt",
                   full.names = TRUE)
    stopifnot(length(fpath) == 1)

    x <- read.delim(fpath, check.names = FALSE, stringsAsFactors = FALSE)
    if(verbose > 0){
        print("MaxQuant columns")
        print(colnames(x))
    }

    # feature IDs in first 12 columns
    id.cols <- c("Protein IDs",
                 "Majority protein IDs",
                 "Peptide counts (all)",
                 "Peptide counts (razor+unique)",
                 "Peptide counts (unique)",
                 "Protein names",
                 "Gene names",
                 "Fasta headers",
                 "Number of proteins",
                 "Peptides",
                 "Razor + unique peptides",
                 "Unique peptides")
    quant.cols <- paste(quantType, rownames(smmr), sep=' ')
    # safety check
    stopifnot(all(quant.cols %in% colnames(x)))
    # quant.cols <- grep(paste("^",quantType,".+",sep=''), colnames(x), value = TRUE)
    # now make sure all selected columns available
    cols_missing <- setdiff(id.cols, colnames(x))
    if(length(cols_missing) > 0){
        # set off warning
        warn_msg <- paste(cols_missing, collapse = ', ')
        warn_msg <- sprintf('Missing columns: %s.', warn_msg)
        warning(warn_msg)
        id.cols <- intersect(colnames(x), id.cols)
    }
    ibaq.col <- NULL
    if("iBAQ" %in% colnames(x)){
        ibaq.col <- "iBAQ"  # to resolve gene ambiguity in situations when
        # we need to select one gene per protein id.
        # Since they'll be resolved by iBAQ intensity.
        # That ".+" is pretty much a hack to ensure that
        # I do not read in columns that have nothing to do
        # with samples.
        x <- x[,c(id.cols, ibaq.col, quant.cols)]
    }else{
        msg <- paste("iBAQ setting was not enabled in MaxQuant!","\n",
                     "It's not optimal, but OK.","\n",
                     "I'll skip the step of selecting"," ",
                     "top representative protein per gene.",
                     sep="")
        warning(msg)
        x <- x[,c(id.cols, quant.cols)]
    }


    # trim the quant.cols name and retain only sample names
    pref <- paste(quantType,"\\s+",sep="")
    colnames(x) <- sub(pref, '', colnames(x))
    quant.cols <- sub(pref, '', quant.cols)



    #
    #.. SELECTING LEVEL: GENE OR PROTEIN
    # Let's get rid of ("CON" not anymore) "REV" and empty gene names,
    # then check for redundancy.
    # not.con <- !grepl('CON__', x$`Majority protein IDs`)
    not.rev <- !grepl('REV__', x$`Majority protein IDs`)
    x <- x[not.rev,]
    if(('Gene names' %in% id.cols) & (!is.null(ibaq.col))){
        not.empty <- x$`Gene names` != ''
        x <- x[not.empty,]
        gns <- sapply(strsplit(x$`Gene names`, split = ';'), '[', 1)
        x$feature.name <- gns
        # retain genes with higher iBAQ
        # x <- plyr::ddply(.data = x, .variables = ~ feature.name,
        #                  .fun = function(d){d[which.max(d$iBAQ),]})
        x <- x %>%
            group_by(feature.name) %>%
            slice_max(order_by = iBAQ, n = 1, with_ties = TRUE) %>%
            ungroup() %>%
            as.data.frame()

    }else{
        # stick with Majority protein IDs (universal)
        mpids <- sapply(strsplit(x$`Majority protein IDs`, split = ';'), '[', 1)
        x$feature.name <- mpids
    }



    #.. Denote potential contaminants
    contaminants <- grepl('CON__', x$`Majority protein IDs`)
    x$`Majority protein IDs` <- sub('CON__','',x$`Majority protein IDs`)
    x$isContaminant <- contaminants
    id.cols <- c(id.cols, 'isContaminant')

    # to MSnSet
    x.exprs <- as.matrix(x[,quant.cols])
    x.exprs[x.exprs == 0] <- NA
    rownames(x.exprs) <- x$feature.name
    x.pdata <- data.frame(sample.name = colnames(x.exprs),
                          dataset.name = smmr[colnames(x.exprs),],
                          stringsAsFactors = FALSE)
    rownames(x.pdata) <- colnames(x.exprs)
    if(!is.null(ibaq.col))
        x.fdata <- x[,c(id.cols, ibaq.col)]
    else
        x.fdata <- x[,id.cols]
    rownames(x.fdata) <- x$feature.name
    ans <- MSnSet(exprs = x.exprs,
                  fData = x.fdata,
                  pData = x.pdata)
    if (validObject(ans))
        return(ans)
}


utils::globalVariables(c("feature.name", "iBAQ"))
