#' Download sequences and metadata from GenBank by unique identifier
#'
#' @param id character vector of unique ID(s) for records in database
#'
#' @return a list with two elements: \code{data} contains the metadata for each
#' sequence; and \code{dna} contains a character vector (same length as number
#' of rows of \code{data}) where each element is a FASTA-formatted DNA sequence
#' matched to the metadata by accession.version number
#'
#'  @examples
#'  \dontrun{
#'  foo <- getGenBankSeqs(c('1331395866', '1679378317'))
#' }
#'
#' @export

getGenBankSeqs <- function(id) {
    # get the raw record
    raw <- rentrez::entrez_fetch(db = 'nuccore', id = id,
                                 rettype = 'gbc', retmode = 'xml')

    # convert XML to list
    rawList <- XML::xmlToList(raw)

    # loop over list and extract needed info
    out <- lapply(rawList, function(l) {
        # get easy to retrieve data
        dat <- data.frame(
            accession = extractSafely(l$`INSDSeq_accession-version`),
            species = extractSafely(l$INSDSeq_organism),
            date = extractSafely(l$`INSDSeq_create-date`),
            pubmed = extractSafely(l$INSDSeq_references$INSDReference$
                                       INSDReference_pubmed)
        )

        # look for other publication info
        rawUnlist <- unlist(rawList)
        pubDOI <- grep('doi', rawUnlist, ignore.case = TRUE) + 1
        pubDOI <- unique(rawUnlist[pubDOI])
        dat$pubDOI <- paste(pubDOI, collapse = '; ')

        # extract feature table
        featTab <- l$`INSDSeq_feature-table`

        # add data from feature table
        dat <- cbind(dat, parseFeatTab(featTab))

        # add sequence to data.frame (will be sepparated after loop)
        dat$dna <- l$INSDSeq_sequence

        return(dat)
    })


    out <- do.call(rbind, out)
    rownames(out) <- NULL

    dna <- formatFASTA(out$accession, out$dna)
    out <- out[, names(out) != 'dna']

    return(list(data = out, dna = dna))
}


# helper function to parse the 'feature table'
parseFeatTab <- function(featTab) {
    # make nested list into a flat, named vector
    featTab <- unlist(featTab)

    # gather info into data.frame
    info <- data.frame(
        # info about genomic region
        region = extractFeatByName('gene', featTab),
        product = extractFeatByName('product', featTab),
        organelle = extractFeatByName('organelle', featTab),
        region_note = extractFeatByName('note', featTab),

        # info about geographic location
        latlon = extractFeatByName('lat_lon', featTab),
        locality = extractFeatByName('country', featTab),

        # info about specimen
        coll_date = extractFeatByName('collection_date', featTab),
        coll_by = extractFeatByName('collected_by', featTab),
        specimen_id = extractFeatByName('specimen_voucher', featTab)
    )

    return(info)
}

# helper function to ensure that returned value is always at least 1 long
# and is NA if it should be
extractSafely <- function(x) {
    if(length(x) < 1 | all(x == '')) x <- NA

    return(x)
}

# helper function to extract features by their names
extractFeatByName <- function(name, featTab) {
    index <- which(grepl('INSDQualifier_name', names(featTab)) &
                       featTab == name) + 1

    if(length(index) == 0) {
        out <- NA
    } else {
        out <- as.character(featTab[index])
        out <- unique(out)

        if(out == '') out <- NA
    }

    return(out)
}

# helper function to format sequences into FASTA format
formatFASTA <- function(dbID, dnaSeq) {
    paste0('>', dbID, '\n', dnaSeq)
}

