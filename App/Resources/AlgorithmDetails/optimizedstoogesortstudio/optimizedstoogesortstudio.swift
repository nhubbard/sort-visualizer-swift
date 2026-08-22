@discardableResult
func compSwap(_ arr: inout [Int], _ a: Int, _ b: Int) -> Bool {
    if arr[a] > arr[b] {
        arr.swapAt(a, b)
        return true
    }
    return false
}

@discardableResult
func stoogeSort(_ arr: inout [Int], _ a: Int, _ m: Int, _ b: Int, _ merge: Bool) -> Bool {
    guard a < m else { return false }
    if b - a == 2 {
        return compSwap(&arr, a, m)
    }

    var lChange = false
    var rChange = false

    let a2 = (a + a + b) / 3
    let b2 = (a + b + b + 2) / 3

    if m < b2 {
        lChange = stoogeSort(&arr, a, m, b2, merge)
        if merge {
            rChange = stoogeSort(&arr, Swift.max(a + b2 - m, a2), b2, b, true)
            if rChange {
                stoogeSort(&arr, a + b2 - m, a2, 2 * a2 - a, true)
            }
        } else {
            rChange = stoogeSort(&arr, a2, b2, b, false)
            if rChange {
                stoogeSort(&arr, a, a2, 2 * a2 - a, true)
            }
        }
    } else {
        rChange = stoogeSort(&arr, a2, m, b, merge)
        if rChange {
            stoogeSort(&arr, a, a2, a2 + b - m, true)
        }
    }

    return lChange || rChange
}

func sort(_ array: inout [Int]) {
    stoogeSort(&array, 0, 1, array.count, false)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
