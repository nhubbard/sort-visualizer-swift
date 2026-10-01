func minRunLength(_ value: Int) -> Int {
    var n = value
    var remainder = 0
    while n >= 32 {
        remainder |= n & 1
        n >>= 1
    }
    return n + remainder
}

func countRun(_ values: inout [Int], _ start: Int) -> Int {
    var end = start + 1
    if end == values.count {
        return 1
    }
    let descending = values[end] < values[start]
    end += 1
    if descending {
        while end < values.count && values[end] < values[end - 1] {
            end += 1
        }
        values[start ..< end].reverse()
    } else {
        while end < values.count && values[end] >= values[end - 1] {
            end += 1
        }
    }
    return end - start
}

func binaryInsertion(_ values: inout [Int], _ start: Int, _ end: Int, _ sortedEnd: Int) {
    for index in sortedEnd ..< end {
        let pivot = values[index]
        var low = start
        var high = index
        while low < high {
            let middle = low + (high - low) / 2
            if values[middle] <= pivot {
                low = middle + 1
            } else {
                high = middle
            }
        }
        if low < index {
            for shift in stride(from: index, through: low + 1, by: -1) {
                values[shift] = values[shift - 1]
            }
        }
        values[low] = pivot
    }
}

func merge(_ values: inout [Int], _ runs: inout [(Int, Int)], _ index: Int) {
    let (start, leftLength) = runs[index]
    let (rightStart, rightLength) = runs[index + 1]
    let left = Array(values[start ..< rightStart])
    let right = Array(values[rightStart ..< (rightStart + rightLength)])
    var i = 0
    var j = 0
    var destination = start
    while i < left.count, j < right.count {
        if left[i] <= right[j] {
            values[destination] = left[i]
            i += 1
        } else {
            values[destination] = right[j]
            j += 1
        }
        destination += 1
    }
    while i < left.count {
        values[destination] = left[i]
        i += 1
        destination += 1
    }
    while j < right.count {
        values[destination] = right[j]
        j += 1
        destination += 1
    }
    runs.replaceSubrange(index ... (index + 1), with: [(start, leftLength + rightLength)])
}

func sort(_ values: inout [Int]) {
    let n = values.count
    guard n > 1 else { return }
    let minimum = minRunLength(n)
    var runs: [(Int, Int)] = []
    var cursor = 0
    while cursor < n {
        var length = countRun(&values, cursor)
        let forced = min(minimum, n - cursor)
        if length < forced {
            binaryInsertion(&values, cursor, cursor + forced, cursor + length)
            length = forced
        }
        runs.append((cursor, length))
        while runs.count > 1 {
            var index = runs.count - 2
            if (index >= 1 && runs[index - 1].1 <= runs[index].1 + runs[index + 1].1) ||
                (index >= 2 && runs[index - 2].1 <= runs[index].1 + runs[index - 1].1)
            {
                if runs[index - 1].1 < runs[index + 1].1 {
                    index -= 1
                }
            } else if runs[index].1 > runs[index + 1].1 {
                break
            }
            merge(&values, &runs, index)
        }
        cursor += length
    }
    while runs.count > 1 {
        var index = runs.count - 2
        if index > 0, runs[index - 1].1 < runs[index + 1].1 {
            index -= 1
        }
        merge(&values, &runs, index)
    }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
