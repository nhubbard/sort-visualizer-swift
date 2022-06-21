# Launches Pygments to highlight source code files in the format we expect.
import json
from pygments import highlight
from pygments.lexers import get_lexer_for_filename
from pygments.formatter import Formatter

algorithms = ["quicksort", "mergesort", "heapsort", "bubblesort", "selectionsort", "insertionsort", "gnomesort", "shakersort", "oddevensort", "pancakesort", "bitonicsort"]
extensions = ["c", "cpp", "cs", "go", "java", "js", "kt", "py", "rb", "swift"]

class JsonFormatter(Formatter):
  def __init__(self):
    self.tokens = []

  def format(self, tokensource, _):
    for ttype, value in tokensource:
      self.tokens.append({"type": str(ttype), "value": value})

  def result(self):
    return self.tokens

if __name__ == "__main__":
  for algo in algorithms:
    for ext in extensions:
      filename = "./{algo}.bundle/{algo}.{ext}".format(algo=algo, ext=ext)
      output_filename = "{filename}.json".format(filename=filename)
      try:
        with open(filename) as fp:
          code = fp.read()
        lexer = get_lexer_for_filename(filename)
        formatter = JsonFormatter()
        highlight(code, lexer, formatter)
        result = formatter.result()
        with open(output_filename, "w") as fp:
          json.dump({"result": formatter.result()}, fp)
      except FileNotFoundError:
        print("Warning: skipping {filename} highlighting (file not found)".format(filename=filename))
