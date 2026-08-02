import Foundation

func binarySearch(_ array: [Int], _ item: Int, _ start: Int, _ end: Int) -> Int {
    var lo = start
    var hi = end
    while lo < hi {
        let mid = lo + (hi - lo) / 2
        if item < array[mid] {
            hi = mid
        } else {
            lo = mid + 1
        }
    }
    return lo
}

func binaryInsertionSort(_ array: inout [Int], _ start: Int, _ end: Int) {
    guard end - start > 1 else { return }
    for i in (start + 1) ..< end {
        let item = array[i]
        let pos = binarySearch(array, item, start, i)
        var j = i
        while j > pos {
            array[j] = array[j - 1]
            j -= 1
        }
        array[pos] = item
    }
}

func rebalance(
    _ array: inout [Int],
    _ temp: inout [Int],
    _ counts: inout [Int],
    _ locations: [Int],
    _ spineSize: Int,
    _ batchEnd: Int
) {
    for i in 0 ..< spineSize {
        counts[i + 1] = counts[i + 1] + counts[i] + 1
    }

    var k = 0
    for i in spineSize ..< batchEnd {
        let gap = locations[k]
        let position = counts[gap]
        temp[position] = array[i]
        counts[gap] = position + 1
        k += 1
    }

    for i in 0 ..< spineSize {
        let position = counts[i]
        temp[position] = array[i]
        counts[i] = position + 1
    }

    for i in 0 ..< batchEnd {
        array[i] = temp[i]
    }

    binaryInsertionSort(&array, 0, counts[0] - 1)
    for i in 0 ..< (spineSize - 1) {
        binaryInsertionSort(&array, counts[i], counts[i + 1] - 1)
    }
    binaryInsertionSort(&array, counts[spineSize - 1], counts[spineSize])

    for i in 0 ..< (spineSize + 2) {
        counts[i] = 0
    }
}

func librarySort(_ array: inout [Int]) {
    let n = array.count
    guard n >= 2 else { return }

    let rebalanceFactor = 2
    var spineSize = 1
    binaryInsertionSort(&array, 0, spineSize)

    var maxLevel = spineSize
    while maxLevel * rebalanceFactor < n {
        maxLevel *= rebalanceFactor
    }

    var temp = [Int](repeating: 0, count: n)
    var counts = [Int](repeating: 0, count: maxLevel + 2)
    var locations = [Int](repeating: 0, count: n)

    var i = spineSize
    var k = 0
    while i < n {
        if rebalanceFactor * spineSize == i {
            rebalance(&array, &temp, &counts, locations, spineSize, i)
            spineSize = i
            k = 0
        }
        let gap = binarySearch(array, array[i], 0, spineSize)
        counts[gap + 1] += 1
        locations[k] = gap
        k += 1
        i += 1
    }
    rebalance(&array, &temp, &counts, locations, spineSize, n)
}

func sort(_ array: inout [Int]) {
    librarySort(&array)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
