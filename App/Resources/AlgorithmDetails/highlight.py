# Launches Pygments to highlight source code files in the format we expect.
from pygments import highlight
from pygments.lexers import get_lexer_for_filename
from pygments.formatter import Formatter

algorithms = sorted(
    [
        "quicksort",
        "mergesort",
        "heapsort",
        "bubblesort",
        "selectionsort",
        "insertionsort",
        "gnomesort",
        "shakersort",
        "oddevensort",
        "pancakesort",
        "bitonicsort",
        "radixsort",
        "shellsort",
        "combsort",
        "bogosort",
        "stoogesort",
        "binarymergesort",
        "burntpancakesort",
        "introsort",
        "oddevenmergesortiterative",
        "strandsort",
        "ternaryllquicksort",
        "ternarylrquicksort",
        "cocktailshakersort",
        "oddevensort",
        "recursiveshellsort",
        "binaryinsertionsort",
        "minheapsort",
        "cyclesort",
        "countingsort",
        "msdradixsort",
        "bottomupmergesort",
        "inplacemergesort",
        "bosenelsonsortiterative",
        "mergeexchangesortiterative",
        "bozosort",
        "cocktailmergesort",
        "optimizedbubblesort",
        "optimizedcocktailshakersort",
        "optimizedgnomesort",
        "swaplessbubblesort",
        "slowsort",
        "dualpivotquicksort",
        "doubleinsertionsort",
        "simplifiedlibrarysort",
        "doubleselectionsort",
        "stableselectionsort",
        "pigeonholesort",
        "flashsort",
        "gravitysort",
        "rotatemergesort",
        "bitonicsortrecursive",
        "oddevenmergesortrecursive",
        "hybridcombsort",
        "unoptimizedbubblesort",
        "binarygnomesort",
        "llquicksort",
        "circlesortiterative",
        "circlesortrecursive",
        "binarydoubleinsertionsort",
        "bingosort",
        "stablecyclesort",
        "staticsort",
        "weavedmergesort",
        "weavemergesort",
        "exchangebogosort",
        "lessbogosort",
        "cocktailbogosort",
        "slopesort",
        "snufflesort",
        "basenmaxheapsort",
        "diamondsortrecursive",
        "introcirclesortiterative",
        "badsort",
        "classictreesort",
        "triangularheapsort",
        "blockswapmergesort",
        "pairwisesortiterative",
        "circloidsort",
        "unoptimizedcocktailshakersort",
        "lrquicksort",
        "classicthreesmoothcombsort",
        "threesmoothcombsortiterative",
        "threesmoothcombsortrecursive",
    ]
)
extensions = ["c", "cpp", "cs", "go", "java", "js", "kt", "py", "rb", "swift"]


class AttributedTextFormatter(Formatter):
    def __init__(self):
        self.output = ""

    def format(self, tokensource, _):
        for ttype, value in tokensource:
            value = (
                value.replace("[", "\\[")
                .replace("]", "\\]")
                .replace("^", "\\^")
                .replace("_", "\\_")
                .replace("-", "\\-")
                .replace("*", "\\*")
            )
            if value == "\n":
                self.output += "\n"
            else:
                self.output += f"^[{value}](code: '{str(ttype)}')"

    def result(self):
        return self.output


if __name__ == "__main__":
    for algo in algorithms:
        for ext in extensions:
            filename = f"./{algo}.bundle/{algo}.{ext}"
            output_filename = f"{filename}.md"
            try:
                with open(filename) as fp:
                    code = fp.read().rstrip("\n")
                lexer = get_lexer_for_filename(filename)
                formatter = AttributedTextFormatter()
                highlight(code, lexer, formatter)
                result = formatter.result()
                with open(output_filename, "w") as fp:
                    fp.write(result)
            except FileNotFoundError:
                print(f"Warning: skipping {filename} highlighting (file not found)")