#' Download taxonomy (with error correcting) from NCBI
#'
#' @param spp character vector of species names
#'
#' @return a \code{data.frame} with columns \code{old_name}, \code{ncbi_name},
#' \code{uid} that record (respectively) the user-supplied name, the name
#' matched in NCBI, the species ID from NCBI
#'
#'  @examples
#'  \dontrun{
#'  foo <- getNCBITaxonomy(c('Idiomyia sproati', 'Drosophil murphy', 'no body'))
#' }
#'
#' @export

getNCBITaxonomy <- function(spp) {
    # check for spelling errors
    sppNames <- as.data.frame(taxize::gnr_resolve(spp, data_source_ids = 4))

    # clean up inconsistent output from `taxize::gnr_resolve`
    gnrNames <- c('user_supplied_name', 'submitted_name', 'matched_name',
                  'data_source_title', 'score')
    if(nrow(sppNames) == 0) {
        # make empty data.frame
        sppNames <- as.data.frame(as.list(1:5))
        names(sppNames) <- gnrNames
        sppNames <- sppNames[-1, , drop = FALSE]
    }

    notFound <- spp[!(spp %in% sppNames$user_supplied_name)]
    if(length(notFound) > 0) {
        # make data.frame of NA with appropriate nrow
        bad <- as.data.frame(matrix(NA, nrow = length(notFound), ncol = 5))
        names(bad) <- gnrNames
        bad$user_supplied_name <- notFound
        bad$score <- 0

        sppNames <- rbind(sppNames, bad)
    }


    # remove poor matches
    sppNames$matched_name[sppNames$score < 0.6] <- NA


    # make final list of names to find UIDs for
    sppNames$final_name <- sppNames$matched_name
    sppNames$final_name[is.na(sppNames$final_name)] <-
        sppNames$user_supplied_name[is.na(sppNames$final_name)]

    # make sure there are no duplicates
    sppNames <- sppNames[!duplicated(sppNames[, c('user_supplied_name',
                                                  'final_name')]), ]


    # get NCBI ids
    uids <- taxize::get_uid_(sppNames$final_name, messages = FALSE,
                             key = '8b50eaea30d551e7840ffd3844b6080d6308')

    # clean up inconsistent output from `taxize::get_uid_`
    cleanUIDs <- lapply(uids, function(id) {
        if(is.null(id)) {
            return(data.frame(ncbi_name = NA,
                              uid = NA))
        } else {
            return(data.frame(ncbi_name = id$scientificname,
                              uid = id$uid))
        }
    })

    cleanUIDs <- do.call(rbind, cleanUIDs)

    # put all relevant info together
    out <- data.frame(old_name = sppNames$user_supplied_name, cleanUIDs)
    rownames(out) <- NULL


    # taxonomic hierarchy

    goodUIDs <- !is.na(out$uid)
    tax <- replicate(nrow(out), data.frame(name = NA, rank = NA),
                     simplify = FALSE)

    if(any(goodUIDs)) {
        i <- taxize::as.uid(out$uid[goodUIDs], check = FALSE)
        tax[goodUIDs] <- taxize::classification(i, return_id = FALSE)
    }

    taxaHier <- cleanTaxaHier(tax)

    # add taxonomic hierarchy to out and return
    out <- cbind(taxaHier, out)

    return(out)

}


# helper function to make a clean data.frame of taxonomy for multiple entries

cleanTaxaHier <- function(tax) {
    # the different taxonomic levels we want
    desiredLevels <- c('kingdom', 'phylum', 'class', 'order', 'suborder',
                       'infraorder', 'superfamily', 'family', 'subfamily',
                       'tribe', 'genus')

    # loop over taxonomy entries and clean-up
    out <- lapply(tax, function(x) {

        tlist <- x$name
        names(tlist) <- x$rank

        return(tlist[desiredLevels])
    })

    # clean final data.frame and return
    out <- as.data.frame(do.call(rbind, out))
    names(out) <- desiredLevels
    rownames(out) <- NULL

    return(out)
}
