let insertionThreshold = 24

/// Once a range's "between the pivots" middle partition holds more than this fraction of the
/// range, it's worth pausing to scan out any elements that exactly equal one of the two pivots
/// before recursing into what's left.
let equalElementsMinFraction = 4

/// Sorts arr[low...high] in place (both bounds inclusive).
func insertionSort(_ arr: inout [Int], _ low: Int, _ high: Int) {
    var i = low + 1
    while i <= high {
        let key = arr[i]
        var j = i - 1
        while j >= low, arr[j] > key {
            arr[j + 1] = arr[j]
            j -= 1
        }
        arr[j + 1] = key
        i += 1
    }
}

/// arr[low...high] holds only values in the closed range [pivot1, pivot2]. In a single scan,
/// moves every element equal to pivot1 to the front and every element equal to pivot2 to the
/// back -- a Dutch-national-flag-style three-way partition, generalized to two specific
/// target values instead of "less than/greater than a pivot". Returns the inclusive bounds of
/// what's left strictly between the two pivots.
func movePivotDuplicatesOut(
    _ arr: inout [Int], _ low: Int, _ high: Int, _ pivot1: Int, _ pivot2: Int
) -> (Int, Int) {
    var writeLow = low
    var read = low
    var writeHigh = high
    while read <= writeHigh {
        if arr[read] == pivot1 {
            arr.swapAt(read, writeLow)
            writeLow += 1
            read += 1
        } else if arr[read] == pivot2 {
            arr.swapAt(read, writeHigh)
            writeHigh -= 1
        } else {
            read += 1
        }
    }
    return (writeLow, writeHigh)
}

/// Sorts arr[low...high] in place (both bounds inclusive).
func optimizedDualPivotQuickSort(_ arr: inout [Int], _ low: Int, _ high: Int) {
    let size = high - low + 1
    if size <= insertionThreshold {
        if size > 1 {
            insertionSort(&arr, low, high)
        }
        return
    }

    // Sample two candidates roughly a third of the way in from each end and seed the two
    // pivots from them, smaller one first.
    let third = size / 3
    let pivot1Index = low + third
    let pivot2Index = high - third
    if arr[pivot1Index] > arr[pivot2Index] {
        arr.swapAt(pivot1Index, pivot2Index)
    }
    arr.swapAt(low, pivot1Index)
    arr.swapAt(high, pivot2Index)
    let pivot1 = arr[low]
    let pivot2 = arr[high]

    // Single left-to-right scan splitting the interior into three regions: less than pivot1,
    // between the two pivots, and greater than pivot2.
    var less = low + 1
    var great = high - 1
    var k = less
    while k <= great {
        if arr[k] < pivot1 {
            arr.swapAt(k, less)
            less += 1
        } else if arr[k] > pivot2 {
            while k < great, arr[great] > pivot2 {
                great -= 1
            }
            arr.swapAt(k, great)
            great -= 1
            if arr[k] < pivot1 {
                arr.swapAt(k, less)
                less += 1
            }
        }
        k += 1
    }

    // Drop the two pivots into place at the boundaries of their regions.
    less -= 1
    great += 1
    arr.swapAt(low, less)
    arr.swapAt(high, great)

    // arr[low...less-1] < pivot1, arr[less] == pivot1, arr[less+1...great-1] is the middle
    // region, arr[great] == pivot2, arr[great+1...high] > pivot2.
    optimizedDualPivotQuickSort(&arr, low, less - 1)
    optimizedDualPivotQuickSort(&arr, great + 1, high)

    var middleLow = less + 1
    var middleHigh = great - 1

    if pivot1 != pivot2, middleHigh >= middleLow {
        let middleSize = middleHigh - middleLow + 1
        // Equal-elements optimization: a middle region this large is usually full of values
        // tied to one pivot or the other, which would otherwise get pointlessly
        // re-partitioned by the recursive call below. Shrink it first by scanning out the
        // exact duplicates. They're already correctly positioned relative to the low and
        // high regions -- every pivot1 duplicate is >= everything already sorted into the
        // low region, and every pivot2 duplicate is <= everything already sorted into the
        // high region -- so neither of those two regions needs to be touched again.
        if middleSize > size / equalElementsMinFraction {
            (middleLow, middleHigh) = movePivotDuplicatesOut(&arr, middleLow, middleHigh, pivot1, pivot2)
        }
    }

    if pivot1 != pivot2, middleHigh >= middleLow {
        optimizedDualPivotQuickSort(&arr, middleLow, middleHigh)
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    if n < 2 {
        return
    }
    optimizedDualPivotQuickSort(&arr, 0, n - 1)
}

var array: [Int] = [
    55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79,
    21, 88, 5, 51, 66, 29, 44, 12, 78, 33, 91, 6, 58, 12,
]
sort(&array)
print(array)
