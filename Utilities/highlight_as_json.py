import json
import sys
from pygments import highlight
from pygments.lexers import get_lexer_for_filename
from pygments.formatter import Formatter


class JsonFormatter(Formatter):
    def __init__(self):
        self.tokens = []

    def format(self, tokensource, outfile):
        for ttype, value in tokensource:
            self.tokens.append({"type": str(ttype), "value": value})

    def result(self):
        return self.tokens


filename = sys.argv[1]
with open(filename) as fp:
    code = fp.read()

lexer = get_lexer_for_filename(filename)
formatter = JsonFormatter()
highlight(code, lexer, formatter)
result = formatter.result()
with open(filename + ".json", "w") as fp:
    json.dump({"result": formatter.result()}, fp)