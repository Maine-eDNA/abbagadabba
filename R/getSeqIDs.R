#' Download unique identifiers by taxon for sequences on NCBI
#'
#' @param spp vector of species names (should already be scrubbed)
#'
#' @return a \code{data.frame} with columns \code{uid} and \code{gid} that
#' record (respectively) the species ID and the sequence ID from NCBI
#'
#'  @examples
#'  \dontrun{
#'  foo <- getNCBISeqID(c('Drosophila murphyi', 'Drosophila sproati'))
#' }
#'
#' @export

getNCBISeqID <- function(spp) {
    seqIDs <- rentrez::entrez_search(db = 'nuccore',
                                     term = paste(sprintf('%s[ORGN]', spp),
                                                  collapse = ' OR '),
                                     retmax = 5e+04)

    # note: can search for loci with something like this: 16S[All Fields] AND "foo"[Organism]
    return(seqIDs$ids)

}
