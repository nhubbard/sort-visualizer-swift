import AlgorithmKit
import Foundation
import SortEngineKit

public struct LSDRadixSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "lsdradixsort")
    public let metadata = AlgorithmMetadata(
        displayName: "LSD Radix Sort",
        category: .distribution,
        sizeRange: 16...512,
        stable: true,
        timeComplexity: ComplexityBounds(best: "O(d \\times (n+b))", average: "O(d \\times (n+b))", worst: "O(d \\times (n+b))"),
        spaceComplexity: "O(n + b)",
        iconName: "number"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        let radix = 4

        func getDigit(_ value: Int, _ place: Int) -> Int {
            (value / Int(pow(Double(radix), Double(place)))) % radix
        }

        var maxValue = 0
        for i in 0..<n {
            maxValue = max(maxValue, engine.values[i])
        }
        var highestPlace = 1
        while Int(pow(Double(radix), Double(highestPlace))) <= maxValue {
            highestPlace += 1
        }

        let outputHandle = engine.createAuxArray(length: n)

        for place in 0..<highestPlace {
            var counts = [Int](repeating: 0, count: radix)
            var values = [Int]()
            for i in 0..<n {
                values.append(engine.values[i])
            }
            for i in 0..<n {
                counts[getDigit(values[i], place)] += 1
            }
            for d in 1..<radix {
                counts[d] += counts[d - 1]
            }
            var output = [Int](repeating: 0, count: n)
            for i in stride(from: n - 1, through: 0, by: -1) {
                let digit = getDigit(values[i], place)
                counts[digit] -= 1
                output[counts[digit]] = values[i]
                engine.writeAux(outputHandle, at: counts[digit], value: values[i])
            }
            for i in 0..<n {
                engine.setValue(i, output[i])
            }
        }

        engine.deleteAuxArray(outputHandle)
    }
}
