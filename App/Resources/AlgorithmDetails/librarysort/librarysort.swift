func sort(_ arr: inout [Int]) {
    let n = arr.count
    guard n > 1 else { return }

    let empty = Int.min
    var capacity = 0
    var slots: [Int] = []
    // Physical `slots` index of each placed element, ascending by both position and value.
    var positions: [Int] = []

    func rebalance() {
        let count = positions.count
        let newCapacity = max(2, count * 2)
        var newSlots = [Int](repeating: empty, count: newCapacity)
        var newPositions = [Int]()
        for (i, pos) in positions.enumerated() {
            let newPos = i * 2
            newSlots[newPos] = slots[pos]
            newPositions.append(newPos)
        }
        slots = newSlots
        positions = newPositions
        capacity = newCapacity
    }

    func insert(_ value: Int) {
        if positions.count == capacity {
            rebalance()
        }

        // Upper-bound binary search: first slot whose value is strictly greater than `value`.
        var lo = 0
        var hi = positions.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if slots[positions[mid]] > value {
                hi = mid
            } else {
                lo = mid + 1
            }
        }
        let k = lo
        let targetPos = k == 0 ? 0 : positions[k - 1] + 1

        guard targetPos == capacity || slots[targetPos] != empty else {
            slots[targetPos] = value
            positions.insert(targetPos, at: k)
            return
        }

        // Either targetPos is already occupied, or targetPos == capacity (new maximum, no room
        // left of the structure's end). Search BOTH directions for the nearest gap and shift
        // whichever side is closer.
        var leftGap = targetPos - 1
        while leftGap >= 0, slots[leftGap] != empty {
            leftGap -= 1
        }
        var rightGap = targetPos
        while rightGap < capacity, slots[rightGap] != empty {
            rightGap += 1
        }
        let leftDistance = leftGap >= 0 ? targetPos - leftGap : Int.max
        let rightDistance = rightGap < capacity ? rightGap - targetPos : Int.max

        if rightDistance <= leftDistance {
            var i = rightGap
            while i > targetPos {
                slots[i] = slots[i - 1]
                i -= 1
            }
            for idx in k ..< (k + (rightGap - targetPos)) {
                positions[idx] += 1
            }
            slots[targetPos] = value
            positions.insert(targetPos, at: k)
        } else {
            let shiftCount = (targetPos - 1) - leftGap
            var i = leftGap
            while i < targetPos - 1 {
                slots[i] = slots[i + 1]
                i += 1
            }
            for idx in (k - shiftCount) ..< k {
                positions[idx] -= 1
            }
            slots[targetPos - 1] = value
            positions.insert(targetPos - 1, at: k)
        }
    }

    for v in arr {
        insert(v)
    }

    var result = [Int](repeating: 0, count: n)
    for (i, pos) in positions.enumerated() {
        result[i] = slots[pos]
    }
    arr = result
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
