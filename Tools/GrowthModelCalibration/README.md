# Growth Model Calibration Bridge

Dev-tool only — **never built into or shipped with the app**. Swift has no symbolic math
library, so the one genuinely symbolic step in the operation-growth calibration pipeline
(deriving a Taylor-polynomial approximation of a fitted growth curve like `a*n^k*log(n)`, which
has no elementary inverse, so it can be inverted at runtime with plain arithmetic instead of a
symbolic solver) is delegated to this small local HTTP server.

## Setup

```sh
cd Tools/GrowthModelCalibration
uv sync
```

## Running

```sh
uv run bridge_server.py
```

Listens on `http://127.0.0.1:8765` only (loopback, not exposed to the network). Two endpoints:

- `GET /health` — liveness check.
- `POST /taylor-invert` — body `{"expr": "<sympy-parseable expression in n>", "n0": <float>,
  "order": <int, default 2>}`. Returns `{"kind": "taylor-polynomial", "n0": ..., "coefficients":
  [c0, c1, ..., cOrder]}`, where `coefficients[i]` is the coefficient of `(n - n0)^i` in the
  Taylor expansion of `expr` around `n = n0` — i.e. `f⁽ⁱ⁾(n0) / i!`, computed by direct repeated
  differentiation, not by parsing `sympy.series`'s output. `expr` may use `n`, `log`, `exp`,
  `sqrt`, `E`, `pi`, and `**` for exponentiation (not `^`); anything else is rejected before
  being handed to `sympify`.

`GrowthModelCalibrationTests.swift` (`Modules/BuiltInAlgorithms/Tests/`) expects this server to
already be running before the calibration test target executes — start it manually in a separate
terminal first. It is only ever used for the `power_log` growth-model family (`a·nᵏ·log n`); every
other family the benchmark can fit has an exact closed-form inverse and never calls this bridge.

## Why a Taylor polynomial instead of solving directly

`a*n^k*log(n) = C` has no elementary closed-form solution for `n` (it's a case of the Lambert-*W*
family). Rather than needing a Lambert-*W* implementation on-device, the bridge Taylor-expands
the fitted curve to 2nd order around the array-size range the benchmark actually measured,
turning it into an ordinary quadratic in `(n - n0)` — solvable at runtime with the same
closed-form quadratic solver already used for the `polynomial+intercept` growth family (see
`PolynomialRootSolver` in `AlgorithmKit`). The shipped app never talks to Python or contains any
symbolic-math dependency; only the *coefficients* this bridge computes get baked into the
generated Swift data table.
