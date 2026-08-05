import Foundation

/// Reverses `arr[0...hi]` in place. This "flip" is the only move the algorithm ever performs;
/// there is no per-element shift anywhere.
func flip(_ arr: inout [Int], _ hi: Int) {
    var lo = 0
    var hi = hi
    while lo < hi {
        arr.swapAt(lo, hi)
        lo += 1
        hi -= 1
    }
}

/// Monobound binary search: locates the index within the ascending run `arr[start..<end]` at
/// which `arr[valueIndex]` belongs, using one comparison per halving instead of the usual two.
func searchAscending(_ arr: [Int], _ start: Int, _ end: Int, _ valueIndex: Int) -> Int {
    var end = end
    var top = end - start
    while top > 1 {
        let mid = top / 2
        if arr[valueIndex] <= arr[end - mid] {
            end -= mid
        }
        top -= mid
    }
    if arr[valueIndex] <= arr[end - 1] {
        return end - 1
    }
    return end
}

/// Mirror image of `searchAscending` for a descending run `arr[start..<end]`.
func searchDescending(_ arr: [Int], _ start: Int, _ end: Int, _ valueIndex: Int) -> Int {
    var start = start
    var top = end - start
    while top > 1 {
        let mid = top / 2
        if arr[start + mid] > arr[valueIndex] {
            start += mid
        }
        top -= mid
    }
    if arr[start] > arr[valueIndex] {
        return start + 1
    }
    return start
}

/// Hand-sorts `arr[0..<n]` for `n <= 3` via a small decision tree, reporting whether the result
/// runs ascending (`true`) or descending (`false`).
func sortFirstThree(_ arr: inout [Int], _ n: Int) -> Bool {
    if n < 2 {
        return false
    }
    if arr[0] > arr[1] {
        flip(&arr, 1)
    }
    if n > 2 {
        if arr[1] > arr[2] {
            if arr[0] > arr[2] {
                flip(&arr, 1)
            } else {
                flip(&arr, 2)
                flip(&arr, 1)
            }
            return false
        }
        return true
    }
    return true
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    guard n >= 2 else { return }

    var ascending = sortFirstThree(&arr, n)

    var i = 3
    while i < n {
        if ascending {
            if arr[i - 1] <= arr[i] {
                // Already fits; the ascending prefix already ends at or below the new element.
            } else if arr[0] > arr[i] {
                // The new element is smaller than everything in the prefix -- one flip turns
                // the whole thing, including the new element, into a descending run.
                flip(&arr, i - 1)
                ascending = false
            } else {
                let idx = searchAscending(arr, 0, i, i)
                flip(&arr, i)
                let tail = i - idx
                flip(&arr, tail)
                flip(&arr, tail - 1)
                ascending = false
            }
        } else {
            if arr[i - 1] > arr[i] {
                // Already fits; the descending prefix already ends at or above the new element.
            } else if arr[0] <= arr[i] {
                flip(&arr, i - 1)
                ascending = true
            } else {
                let idx = searchDescending(arr, 0, i, i)
                flip(&arr, i)
                let tail = i - idx
                flip(&arr, tail)
                flip(&arr, tail - 1)
                ascending = true
            }
        }
        i += 1
    }

    if !ascending {
        flip(&arr, n - 1)
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
