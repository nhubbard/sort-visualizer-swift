let insertionThreshold = 16

func insertionSort(_ arr: inout [Int], _ lo: Int, _ hi: Int) {
    var i = lo + 1
    while i < hi {
        let key = arr[i]
        var j = i - 1
        while j >= lo, arr[j] > key {
            arr[j + 1] = arr[j]
            j -= 1
        }
        arr[j + 1] = key
        i += 1
    }
}

/// Returns whichever of a, b, c indexes the middle value of the three.
func medianOfThree(_ arr: [Int], _ a: Int, _ b: Int, _ c: Int) -> Int {
    var lowIndex = a
    var midIndex = b
    if arr[lowIndex] > arr[midIndex] {
        swap(&lowIndex, &midIndex)
    }
    if arr[midIndex] > arr[c] {
        midIndex = c
        if arr[lowIndex] > arr[midIndex] {
            midIndex = lowIndex
        }
    }
    return midIndex
}

func fluxSortRange(_ arr: inout [Int], _ lo: Int, _ hi: Int, _ swap: inout [Int]) {
    let n = hi - lo
    if n <= insertionThreshold {
        insertionSort(&arr, lo, hi)
        return
    }

    let mid = lo + n / 2
    let pivot = arr[medianOfThree(arr, lo, mid, hi - 1)]

    // Partition into arr (elements <= pivot) and swap (elements > pivot). Ties go to the
    // low side, which is what keeps the sort stable.
    var lowWrite = lo
    var highWrite = 0
    for read in lo ..< hi {
        let value = arr[read]
        if value > pivot {
            swap[highWrite] = value
            highWrite += 1
        } else {
            arr[lowWrite] = value
            lowWrite += 1
        }
    }

    for i in 0 ..< highWrite {
        arr[lowWrite + i] = swap[i]
    }

    if lowWrite == hi {
        // Every element in range was <= pivot -- a run of duplicates around the pivot
        // value can cause this. There's no split to recurse into, so finish directly.
        insertionSort(&arr, lo, hi)
        return
    }

    fluxSortRange(&arr, lo, lowWrite, &swap)
    fluxSortRange(&arr, lowWrite, hi, &swap)
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    if n < 2 {
        return
    }
    var swap = [Int](repeating: 0, count: n)
    fluxSortRange(&arr, 0, n, &swap)
}

var array: [Int] = [
    55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97,
    15, 62, 34, 79, 21, 88, 5, 51, 66, 29, 44, 12,
]
sort(&array)
print(array)
