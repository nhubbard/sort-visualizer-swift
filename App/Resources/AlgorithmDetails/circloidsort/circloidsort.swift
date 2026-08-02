import Foundation

func circle(_ array: inout [Int], _ left: Int, _ right: Int) -> Bool {
    var a = left
    var b = right
    var swapped = false
    while a < b {
        if array[a] > array[b] {
            array.swapAt(a, b)
            swapped = true
        }
        a += 1
        b -= 1
        if a == b {
            b += 1
        }
    }
    return swapped
}

func circlePass(_ array: inout [Int], _ left: Int, _ right: Int) -> Bool {
    if left >= right {
        return false
    }
    let mid = (left + right) / 2
    let l = circlePass(&array, left, mid)
    let r = circlePass(&array, mid + 1, right)
    return circle(&array, left, right) || l || r
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    if n <= 1 {
        return
    }
    while circlePass(&arr, 0, n - 1) {}
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
