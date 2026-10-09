import Foundation

/// Independent snapshot of the built-in IDs expected in the visible algorithm catalog.
/// Update deliberately when the shipped algorithm corpus changes.
enum CatalogExpectedIDs {
  static let algorithms: Set<String> = [
    "aatreesort", "adaptivegrailsort", "americanflagsort", "andreysort", "asynchronoussort",
    "avltreesort", "badsort", "basenmaxheapsort", "binarydoubleinsertionsort", "binarygnomesort",
    "binaryinsertionsort", "binarymergesort", "binaryquicksortiterative", "binaryquicksortrecursive", "bingosort",
    "binomialheapsort", "binomialsmoothsort", "bitonicsortiterative", "bitonicsortrecursive", "blockinsertionsort",
    "blockswapmergesort", "bogobogosort", "bogosort", "bosenelsonsortiterative", "bosenelsonsortrecursive",
    "bottomupheapsort", "bottomupmergesort", "bozosort", "bubblebogosort", "bubblesort",
    "bufferedstoogesort", "bufferpartitionmergesort", "burntpancakesort", "chalicesort", "circlesortiterative",
    "circlesortrecursive", "circloidsort", "circulargrailsort", "classicgravitysort", "classicthreesmoothcombsort",
    "classictournamentsort", "classictreesort", "cocktailbogosort", "cocktailmergesort", "cocktailshakersort",
    "combsort", "completegraphsort", "countingsort", "creasesort", "cyclesort",
    "deterministicbogosort", "diamondsortiterative", "diamondsortrecursive", "doubleinsertionsort", "doubleselectionsort",
    "dropmergesort", "dualpivotquicksort", "ectasort", "exchangebogosort", "fifthmergesort",
    "flansort", "flashsort", "flippedminheapsort", "fluxsort", "foldsort",
    "forcedstablequicksort", "funsort", "gnomesort", "grailsort", "gravitysort",
    "guesssort", "hanoisort", "hybridcombsort", "improvedblockselectionsort", "improvedinplacemergesort",
    "indexsort", "inplacelsdradixsort", "inplacemergesort", "insertionsort", "introcirclesortiterative",
    "introcirclesortrecursive", "introsort", "iterativetopdownmergesort", "kotasort", "lazierestsort",
    "laziestsort", "lazyheapsort", "lazystablesort", "lessbogosort", "librarysort",
    "llquicksort", "lrquicksort", "lsdradixsort", "matrixsort", "maxheapsort",
    "medianmergesort", "medianquickbogosort", "mergebogosort", "mergeexchangesortiterative", "mergeinsertionsort",
    "mergesort", "minheapsort", "minmaxheapsort", "msdradixsort", "newshufflemergesort",
    "oddevenmergesortiterative", "oddevenmergesortrecursive", "oddevensort", "optimizedbottomupmergesort", "optimizedbubblesort",
    "optimizedcocktailshakersort", "optimizeddualpivotquicksort", "optimizedgnomesort", "optimizedguesssort", "optimizedlazystablesort",
    "optimizedrotatemergesort", "optimizedstoogesort", "optimizedstoogesortstudio", "optimizedweavemergesort", "outofplaceheapsort",
    "pairwisemergesortiterative", "pairwisemergesortrecursive", "pairwisesortiterative", "pairwisesortrecursive", "pancakeinsertionsort",
    "pancakesort", "patiencesort", "pdmergesort", "pdqbranchedsort", "pdqbranchlesssort",
    "pigeonholesort", "poplarheapsort", "quadsort", "quadstoogesort", "quickbogosort",
    "quicksort", "randomguesssort", "recursiveshellsort", "redblacktreesort", "remisort",
    "rotatelsdradixsort", "rotatemergesort", "rotatemsdradixsort", "selectionbogosort", "selectionsort",
    "shattersort", "shellsort", "shovesort", "sillysort", "simpleshattersort",
    "simplifiedlibrarysort", "simplisticgravitysort", "slopesort", "slowsort", "smartbogobogosort",
    "smartguesssort", "smoothsort", "snufflesort", "splaysort", "sqrtsort",
    "stablecyclesort", "stablepermutationsort", "stablequicksort", "stableselectionsort", "stacklessamericanflagsort",
    "stacklessbinaryquicksort", "stacklessdualpivotquicksort", "stacklesshybridquicksort", "stacklessrotatemergesort", "staticsort",
    "stoogesort", "strandsort", "swaplessbubblesort", "synchronoussqrtsort", "tablesort",
    "ternaryheapsort", "ternaryllquicksort", "ternarylrquicksort", "threesmoothcombsortiterative", "threesmoothcombsortrecursive",
    "timesort", "timsort", "tournamentsort", "treesort", "triangularheapsort",
    "twinsort", "unoptimizedbubblesort", "unoptimizedcocktailshakersort", "unstablegrailsort", "weakheapsort",
    "weavedmergesort", "weavemergesort", "weavesortiterative", "weavesortrecursive", "wikisort",
    "yujisbufferedmergesort2",
  ]
  static let categories: [String] = [
    "concurrent", "distribution", "exchange", "hybrid", "impractical",
    "insertion", "merge", "miscellaneous", "quick", "selection"
  ]
}
