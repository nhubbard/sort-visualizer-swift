func sort(_ arr: inout [Int]) {
    func sortRange(_ start: Int, _ end: Int) {
        let length = end - start
        guard length > 1 else { return }

        let bounds = (0 ... 5).map { start + length * $0 / 5 }
        for part in 0 ..< 5 {
            sortRange(bounds[part], bounds[part + 1])
        }

        var positions = Array(bounds.prefix(5))
        var merged: [Int] = []
        merged.reserveCapacity(length)
        while merged.count < length {
            var best: Int?
            for part in 0 ..< 5 where positions[part] < bounds[part + 1] {
                if best == nil || arr[positions[part]] < arr[positions[best!]] {
                    best = part
                }
            }
            merged.append(arr[positions[best!]])
            positions[best!] += 1
        }
        arr.replaceSubrange(start ..< end, with: merged)
    }

    sortRange(0, arr.count)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
