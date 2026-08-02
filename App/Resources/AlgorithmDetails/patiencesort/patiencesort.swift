private struct MinHeap {
    private var storage: [(top: Int, pileIndex: Int)] = []

    var isEmpty: Bool {
        storage.isEmpty
    }

    mutating func push(_ entry: (top: Int, pileIndex: Int)) {
        storage.append(entry)
        var i = storage.count - 1
        while i > 0 {
            let parent = (i - 1) / 2
            if storage[parent].top <= storage[i].top {
                break
            }
            storage.swapAt(parent, i)
            i = parent
        }
    }

    mutating func popMin() -> (top: Int, pileIndex: Int) {
        let result = storage[0]
        storage[0] = storage[storage.count - 1]
        storage.removeLast()
        var i = 0
        while true {
            let left = 2 * i + 1
            let right = 2 * i + 2
            var smallest = i
            if left < storage.count, storage[left].top < storage[smallest].top {
                smallest = left
            }
            if right < storage.count, storage[right].top < storage[smallest].top {
                smallest = right
            }
            if smallest == i {
                break
            }
            storage.swapAt(i, smallest)
            i = smallest
        }
        return result
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count

    var piles: [[Int]] = []
    var tops: [Int] = []

    for x in arr {
        // binary search: leftmost pile whose top is >= x
        var lo = 0
        var hi = piles.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if tops[mid] >= x {
                hi = mid
            } else {
                lo = mid + 1
            }
        }
        if lo == piles.count {
            piles.append([x])
            tops.append(x)
        } else {
            piles[lo].append(x)
            tops[lo] = x
        }
    }

    var heap = MinHeap()
    for i in 0 ..< piles.count {
        heap.push((top: tops[i], pileIndex: i))
    }

    var result: [Int] = []
    while !heap.isEmpty {
        let entry = heap.popMin()
        let value = piles[entry.pileIndex].removeLast()
        result.append(value)
        if let newTop = piles[entry.pileIndex].last {
            heap.push((top: newTop, pileIndex: entry.pileIndex))
        }
    }

    for i in 0 ..< n {
        arr[i] = result[i]
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
