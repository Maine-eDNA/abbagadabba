# figuring out how to use web history object ----

library(abbagadabba)

# species to find
sp <- 'hermissenda crassicornis'

# genbank IDs
x <- getNCBISeqID(sp)

# below script is for inclusion into `getMetadata`

ii <- seq(1, x$count, by = 50)

xml_metadata <- c()

for(i in ii) {
    recs <- entrez_fetch(db="nuccore", web_history=x$web_history,
                         rettype = "gbc", retmode = "xml", parsed=TRUE,
                         retmax = 50, retstart = i)
    recs <- XML::xmlToList(recs)

    xml_metadata <- c(xml_metadata, recs)
}



