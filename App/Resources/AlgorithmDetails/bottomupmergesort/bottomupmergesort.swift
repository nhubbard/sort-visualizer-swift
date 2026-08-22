import Foundation

func merge(_ array: inout [Int], _ low: Int, _ mid: Int, _ high: Int) {
    let left = Array(array[low ..< mid])
    let right = Array(array[mid ..< high])
    var i = 0
    var j = 0
    var k = low
    while i < left.count, j < right.count {
        if left[i] <= right[j] {
            array[k] = left[i]
            i += 1
        } else {
            array[k] = right[j]
            j += 1
        }
        k += 1
    }
    while i < left.count {
        array[k] = left[i]
        i += 1
        k += 1
    }
    while j < right.count {
        array[k] = right[j]
        j += 1
        k += 1
    }
}

func sort(_ array: inout [Int]) {
    let n = array.count
    var width = 1
    while width < n {
        var low = 0
        while low < n {
            let mid = min(low + width, n)
            let high = min(low + 2 * width, n)
            if mid < high {
                merge(&array, low, mid, high)
            }
            low += 2 * width
        }
        width *= 2
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
