import Testing
@testable import AlgorithmKit

@Suite
struct BigOShapeTests {
    @Test(arguments: [
        ("O(1)", BigOShape.constant),
        ("O(n)", .linear),
        ("O(log n)", .logarithmic),
        ("O(log^2 n)", .logarithmicSquared),
        ("O(n log n)", .linearithmic),
        ("O(n \\log n)", .linearithmic),
        ("O(n )", .linearithmic),
        ("O(n\\log{n})", .linearithmic),
        ("O(n log^2 n)", .linearithmicSquared),
        ("O(n^2)", .polynomial(2)),
        ("O(n^1.25)", .polynomial(1.25)),
        ("O(n^{2.71})", .polynomial(2.71)),
        ("O(n^(log n))", .superLinearithmic),
        ("O(2^n)", .exponential),
        ("O(n \\times n!)", .factorial),
    ])
    func parsesPureNShapes(complexity: String, expected: BigOShape) {
        #expect(BigOShape.parse(complexity) == expected)
    }

    @Test(arguments: [
        "O(n*k)", "O(n+k)", "O(d*n)", "O(d*(n+b))", "O(d \\times n)", "O(d \\times (n+b))",
        "O(n \\times m)", "O(n+m^2)", "O(n \\times k)",
    ])
    func returnsNilForShapesWithAnotherFreeVariable(complexity: String) {
        #expect(BigOShape.parse(complexity) == nil)
    }

    @Test
    func referenceFamilyCoversTheClassicLadder() {
        let labels = BigOShape.referenceFamily.map(\.label)
        #expect(labels == ["O(1)", "O(log n)", "O(n)", "O(n log n)", "O(n^2)", "O(n^3)"])
    }

    @Test
    func valueGrowsMonotonicallyForEveryReferenceShape() {
        for (_, shape) in BigOShape.referenceFamily {
            #expect(shape.value(n: 100) >= shape.value(n: 10))
        }
    }
}
