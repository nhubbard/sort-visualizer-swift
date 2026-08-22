import Foundation
import Testing

@testable import AlgorithmKit

@Suite
struct PolynomialRootSolverTests {
  @Test
  func solvesLinear() {
    // 2x - 4 = 0 -> x = 2
    let roots = PolynomialRootSolver.realRoots(coefficients: [-4, 2])
    #expect(roots.count == 1)
    #expect(abs(roots[0] - 2) < 1e-9)
  }

  @Test
  func solvesQuadraticWithTwoRealRoots() {
    // x^2 - 5x + 6 = 0 -> x = 2, 3
    let roots = PolynomialRootSolver.realRoots(coefficients: [6, -5, 1]).sorted()
    #expect(roots.count == 2)
    #expect(abs(roots[0] - 2) < 1e-9)
    #expect(abs(roots[1] - 3) < 1e-9)
  }

  @Test
  func quadraticWithNoRealRootsReturnsEmpty() {
    // x^2 + 1 = 0 -> no real roots
    let roots = PolynomialRootSolver.realRoots(coefficients: [1, 0, 1])
    #expect(roots.isEmpty)
  }

  @Test
  func solvesCubicWithThreeRealRoots() {
    // (x-1)(x-2)(x-3) = x^3 - 6x^2 + 11x - 6 -> x = 1, 2, 3
    let roots = PolynomialRootSolver.realRoots(coefficients: [-6, 11, -6, 1]).sorted()
    #expect(roots.count == 3)
    #expect(abs(roots[0] - 1) < 1e-6)
    #expect(abs(roots[1] - 2) < 1e-6)
    #expect(abs(roots[2] - 3) < 1e-6)
  }

  @Test
  func solvesCubicWithOneRealRoot() {
    // x^3 - 1 = 0 has one real root (x = 1) and two complex ones.
    let roots = PolynomialRootSolver.realRoots(coefficients: [-1, 0, 0, 1])
    #expect(roots.count == 1)
    #expect(abs(roots[0] - 1) < 1e-9)
  }

  @Test
  func newtonSolvesNLogNEqualsK() {
    // n*log(n) = 20 -- verify the returned root actually satisfies the equation, not a known
    // closed-form value (there isn't one).
    let k = 20.0
    let n = PolynomialRootSolver.newton(
      seed: 10, function: { $0 * log($0) - k }, derivative: { log($0) + 1 })
    #expect(abs(n * log(n) - k) < 1e-6)
  }
}
