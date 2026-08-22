import Foundation

func multiSwap(_ array: inout [Int], _ a: Int, _ b: Int, _ len: Int) {
    for i in 0 ..< len {
        array.swapAt(a + i, b + i)
    }
}

func rotate(_ array: inout [Int], _ a: Int, _ m: Int, _ b: Int) {
    var a = a
    var m = m
    var b = b
    var l = m - a
    var r = b - m
    while l > 0, r > 0 {
        if r < l {
            multiSwap(&array, m - r, m, r)
            b -= r
            m -= r
            l -= r
        } else {
            multiSwap(&array, a, m, l)
            a += l
            m += l
            r -= l
        }
    }
}

/// Selects the `c` smallest combined elements of the two already-sorted runs
/// `[a, m)` and `[m, b)` into the front half via a single rotation. Uses a
/// merge-path (co-rank) binary search over whichever run is shorter: it
/// looks for the split count `r` such that taking `r` elements from the tail
/// of one run and `c - r` from the head of the other yields exactly the `c`
/// smallest values in order, rather than searching for a value directly.
func partitionMerge(_ array: inout [Int], _ a: Int, _ m: Int, _ b: Int, _ c: Int) {
    let lenA = m - a
    let lenB = b - m
    guard lenA >= 1, lenB >= 1 else { return }

    if lenB < lenA {
        let cc = (lenA + lenB) - c
        var r1 = max(0, cc - lenA)
        var r2 = min(cc, lenB)
        while r1 < r2 {
            let ml = r1 + (r2 - r1) / 2
            if array[m - (cc - ml)] > array[b - ml - 1] {
                r2 = ml
            } else {
                r1 = ml + 1
            }
        }
        rotate(&array, m - (cc - r1), m, b - r1)
    } else {
        var r1 = max(0, c - lenB)
        var r2 = min(c, lenA)
        while r1 < r2 {
            let ml = r1 + (r2 - r1) / 2
            if array[a + ml] > array[m + (c - ml) - 1] {
                r2 = ml
            } else {
                r1 = ml + 1
            }
        }
        rotate(&array, a + r1, m, m + (c - r1))
    }
}

/// Finds the first place inside `[a, b)` where ascending order breaks, then
/// partition-merges the sorted piece before it with the sorted piece after
/// it. A no-op if `[a, b)` is already one ascending run.
func rotateMerge(_ array: inout [Int], _ a: Int, _ b: Int, _ c: Int) {
    var i = a + 1
    while i < b, array[i - 1] <= array[i] {
        i += 1
    }
    if i < b {
        partitionMerge(&array, a, i, b, c)
    }
}

func rotatePartitionMergeSort(_ array: inout [Int], _ n: Int) {
    guard n >= 2 else { return }

    var i = 1
    while i < n {
        if array[i - 1] > array[i] {
            array.swapAt(i - 1, i)
        }
        i += 2
    }

    var j = 2
    while j < n {
        var b1 = 0
        var blockStart = 0
        while blockStart + j < n {
            b1 = min(blockStart + 2 * j, n)
            partitionMerge(&array, blockStart, blockStart + j, b1, j)
            blockStart += 2 * j
        }

        var k = j / 2
        while k > 1 {
            var seamStart = 0
            while seamStart + k < b1 {
                let seamEnd = min(seamStart + 2 * k, n)
                rotateMerge(&array, seamStart, seamEnd, k)
                seamStart += 2 * k
            }
            k /= 2
        }

        var m = 1
        while m < b1 {
            if array[m - 1] > array[m] {
                array.swapAt(m - 1, m)
            }
            m += 2
        }

        j *= 2
    }
}

func sort(_ arr: inout [Int]) {
    rotatePartitionMergeSort(&arr, arr.count)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
