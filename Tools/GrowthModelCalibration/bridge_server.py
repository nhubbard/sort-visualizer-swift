"""Local-only calibration helper for the operation-growth benchmark.

Swift has no symbolic math library, so the one genuinely symbolic step in the whole calibration
pipeline — Taylor-expanding a fitted growth-model expression (e.g. `a*n**k*log(n)`, which has no
elementary inverse) around a reference array size, so it reduces to an ordinary low-degree
polynomial Swift *can* invert with plain arithmetic — is delegated here.

This process is a dev-tool only. It is never started by, imported by, or shipped with the app; it
binds to loopback only and is invoked exclusively by the Mac Catalyst calibration test target
while a developer is re-deriving growth models after changing an algorithm's implementation.

Run with `uv run bridge_server.py`.
"""

from __future__ import annotations

import json
import re
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Any

import sympy

_PORT = 8765

# Deliberately conservative: only characters that can appear in a numeric arithmetic expression
# over `n` (plus `log`/`exp`/`sqrt`/`E`/`pi`) are allowed through to `sympify`. This is a local,
# trusted-caller tool, not a public service, but there's no reason to hand `sympify` anything
# looser than the shapes this pipeline actually produces.
_ALLOWED_EXPR_PATTERN = re.compile(r"^[0-9a-zA-Z_.\s+\-*/^(),]*$")

_N = sympy.symbols("n", positive=True, real=True)
_ALLOWED_SYMPIFY_LOCALS = {
    "n": _N,
    "log": sympy.log,
    "exp": sympy.exp,
    "sqrt": sympy.sqrt,
    "E": sympy.E,
    "pi": sympy.pi,
}


def _safe_sympify(expr_str: str) -> sympy.Expr:
    if not _ALLOWED_EXPR_PATTERN.match(expr_str):
        raise ValueError(f"expression contains disallowed characters: {expr_str!r}")
    # `**` is the only exponentiation operator accepted below `sympify` — reject the bare `^`
    # some callers might otherwise send, since sympy treats `^` as bitwise XOR, not power, and
    # would silently produce the wrong expression rather than an error.
    if "^" in expr_str:
        raise ValueError("use '**' for exponentiation, not '^'")
    return sympy.sympify(expr_str, locals=_ALLOWED_SYMPIFY_LOCALS)


def taylor_coefficients(expr_str: str, n0: float, order: int) -> dict[str, Any]:
    """Coefficients of the degree-`order` Taylor polynomial of `expr_str` around `n = n0`.

    Returns `coefficients[i]` = coefficient of `(n - n0)^i`, i.e. `f^(i)(n0) / i!` — computed by
    direct repeated symbolic differentiation and evaluation at `n0`, rather than by parsing
    `sympy.series`'s output, since that's exact at the expansion point and needs no `O(...)`
    term-stripping.
    """
    if order < 1:
        raise ValueError("order must be >= 1")

    f = _safe_sympify(expr_str)
    coefficients: list[float] = []
    derivative = f
    factorial = 1
    for i in range(order + 1):
        if i > 0:
            derivative = sympy.diff(derivative, _N)
            factorial *= i
        value = derivative.subs(_N, n0)
        coefficients.append(float(sympy.N(value) / factorial))

    return {
        "kind": "taylor-polynomial",
        "n0": n0,
        "coefficients": coefficients,
    }


class _Handler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path == "/health":
            self._respond(200, {"status": "ok"})
        else:
            self._respond(404, {"kind": "error", "message": "unknown path"})

    def do_POST(self) -> None:
        if self.path != "/taylor-invert":
            self._respond(404, {"kind": "error", "message": "unknown path"})
            return

        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        try:
            payload = json.loads(body)
            expr_str = payload["expr"]
            n0 = float(payload["n0"])
            order = int(payload.get("order", 2))
            result = taylor_coefficients(expr_str, n0, order)
            self._respond(200, result)
        except Exception as exc:  # local dev tool: report any failure back to the caller
            self._respond(400, {"kind": "error", "message": str(exc)})

    def _respond(self, status: int, payload: dict[str, Any]) -> None:
        data = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, format: str, *args: Any) -> None:  # silence default stderr access log
        pass


def main() -> None:
    server = HTTPServer(("127.0.0.1", _PORT), _Handler)
    print(f"growth-model-calibration bridge listening on http://127.0.0.1:{_PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
