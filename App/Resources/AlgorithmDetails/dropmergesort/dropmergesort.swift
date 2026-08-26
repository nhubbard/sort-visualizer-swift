let recency = 8
let earlyOutTestAt = 4
let earlyOutDisorderFraction = 0.6

/// A plain general-purpose sort for arr[lo..<hi], used both as the early-out fallback and to
/// sort the leftover "dropped" elements before the final merge. Any decent O(n log n) sort
/// works here — the algorithm doesn't depend on which one.
func quicksort(_ arr: inout [Int], _ lo: Int, _ hi: Int) {
    guard hi - lo > 1 else { return }
    let pivot = arr[lo + (hi - lo) / 2]
    var less: [Int] = []
    var equal: [Int] = []
    var greater: [Int] = []
    for i in lo ..< hi {
        if arr[i] < pivot {
            less.append(arr[i])
        } else if arr[i] > pivot {
            greater.append(arr[i])
        } else {
            equal.append(arr[i])
        }
    }
    quicksort(&less, 0, less.count)
    quicksort(&greater, 0, greater.count)
    arr.replaceSubrange(lo ..< hi, with: less + equal + greater)
}

func sort(_ arr: inout [Int]) {
    let length = arr.count
    if length < 2 {
        return
    }

    var dropped: [Int] = []
    var numDroppedInARow = 0
    var read = 0
    var write = 0
    var iteration = 0
    let earlyOutStop = length / earlyOutTestAt

    while read < length {
        iteration += 1
        if iteration == earlyOutStop && Double(dropped.count) > Double(read) * earlyOutDisorderFraction {
            // Too disordered for the adaptive approach to be worth it: flush what's been
            // dropped so far back into the array and fall back to a plain full sort.
            for value in dropped {
                arr[write] = value
                write += 1
            }
            dropped.removeAll()
            quicksort(&arr, 0, length)
            return
        }

        if write == 0 || arr[read] >= arr[write - 1] {
            // In order — keep it.
            arr[write] = arr[read]
            write += 1
            read += 1
            numDroppedInARow = 0
        } else if numDroppedInARow == 0, write >= 2, arr[read] >= arr[write - 2] {
            // Quick undo: the element two back would have accepted this one just fine, so
            // drop the one right before it instead of the new element.
            dropped.append(arr[write - 1])
            arr[write - 1] = arr[read]
            read += 1
        } else if numDroppedInARow < recency {
            dropped.append(arr[read])
            read += 1
            numDroppedInARow += 1
        } else {
            // Accepting something `numDroppedInARow` elements back made every subsequent
            // element drop — that accept was a mistake. Undo it, and any other recently
            // accepted elements bigger than the dropped run's maximum.
            dropped.removeLast(numDroppedInARow)
            read -= numDroppedInARow

            var numBacktracked = 1
            write -= 1

            var maxOfDropped = arr[read]
            for i in (read + 1) ... (read + numDroppedInARow) where arr[i] > maxOfDropped {
                maxOfDropped = arr[i]
            }

            while write >= 1, maxOfDropped < arr[write - 1] {
                write -= 1
                numBacktracked += 1
            }

            for i in write ..< (write + numBacktracked) {
                dropped.append(arr[i])
            }

            numDroppedInARow = 0
        }
    }

    for (offset, value) in dropped.enumerated() {
        arr[write + offset] = value
    }

    quicksort(&arr, write, length)

    // Copy the now-sorted dropped tail before the final backward merge starts overwriting
    // arr[write...] in place.
    let buffer = Array(arr[write ..< (write + dropped.count)])

    var i = buffer.count - 1
    var j = write - 1
    var k = length - 1

    while i >= 0 {
        if j < 0 || buffer[i] > arr[j] {
            arr[k] = buffer[i]
            k -= 1
            i -= 1
        } else {
            arr[k] = arr[j]
            k -= 1
            j -= 1
        }
    }
}

var array: [Int] = [
    0, 1, 2, 3, 4, 9, 6, 7, 8, 5, 10, 11, 12, 13, 14, 15,
    21, 17, 18, 19, 20, 16, 22, 23, 24, 28, 26, 27, 25, 29,
]
sort(&array)
print(array)
