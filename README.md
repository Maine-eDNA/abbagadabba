<!-- README.md is generated from README.Rmd. Please edit that file -->

# abbagadabba

R package *abbagadabba* (**a**mplicon-**b**ased **b**iodiversity
**a**ssessment, *g*ap *a*nalysis, *da*ta*b*ase *b*uilding *a*nd more)
provides functions to download DNA sequence data from NCBI based on
species names.

## Installation

*abbagadabba* is in active development and only exists on GitHub. It can
be installed using *devtools* (which is a stable package available on
CRAN).

``` r
library(devtools)
install_github("Maine-eDNA/abbagadabba")
```

## Example usage

Suppose we have a list of species for which we want to retrieve sequence
data. This list might include “bad names” (e.g. synonyms of
misspellings). We want to first correct as many of those bad names as we
can. Simultaneously, we’ll compile all information about the taxonomic
hierarchy of those species

``` r
library(abbagadabba)

cleanNames <- getNCBITaxonomy(c('Idiomyia sproati', 'Drosophil murphy', 'no body'))
cleanNames
```

    #   kingdom     phylum   class   order   suborder  infraorder superfamily
    # 1 Metazoa Arthropoda Insecta Diptera Brachycera Muscomorpha Ephydroidea
    # 2 Metazoa Arthropoda Insecta Diptera Brachycera Muscomorpha Ephydroidea
    # 3    <NA>       <NA>    <NA>    <NA>       <NA>        <NA>        <NA>
    #          family     subfamily        tribe      genus         old_name
    # 1 Drosophilidae Drosophilinae Drosophilini Drosophila Drosophil murphy
    # 2 Drosophilidae Drosophilinae Drosophilini Drosophila Idiomyia sproati
    # 3          <NA>          <NA>         <NA>       <NA>          no body
    #            ncbi_name   uid
    # 1 Drosophila murphyi 48335
    # 2 Drosophila sproati  7289
    # 3               <NA>  <NA>

We were able to fix `Drosophil murphy`, making it `Drosophila murphyi`,
and `Idiomyia sproati`, making it `Drosophila sproati`, but we couldn’t
match `no body`.

Now we need to get all sequence identifiers associated with those
species:

``` r
goodNames <- cleanNames$ncbi_name[!is.na(cleanNames$ncbi_name)]
seqIDs <-  getNCBISeqID(goodNames)
head(seqIDs)
```

    # [1] "2053656522" "2053655721" "1679378317" "1679378287" "1679378281"
    # [6] "1679378246"

Finally we can feed those IDs into the function to retrieve the
sequences themselves. For the purpose of this example, we’ll just look
at a few sequences

``` r
seqData <- getGenBankSeqs(seqIDs[1:2])
seqData
```

    # $data
    #           accession            species        date pubmed
    # 1 JAEIFY000000000.1 Drosophila sproati 16-JUN-2021     NA
    # 2 JAEIFX000000000.1 Drosophila murphyi 16-JUN-2021     NA
    #                      pubDOI region product organelle region_note
    # 1 10.1101/2020.12.14.422775     NA      NA        NA          NA
    # 2 10.1101/2020.12.14.422775     NA      NA        NA          NA
    #                     latlon                            locality coll_date
    # 1 19.574513 N 155.216191 W USA: Waiakea Forest Reserve, Hawaii  Jun-2019
    # 2 19.911621 N 155.313161 W                         USA: Hawaii  Apr-2018
    #     coll_by specimen_id
    # 1 Don Price          NA
    # 2 Don Price          NA
    # 
    # $dna
    # [1] ">JAEIFY000000000.1\n" ">JAEIFX000000000.1\n"
