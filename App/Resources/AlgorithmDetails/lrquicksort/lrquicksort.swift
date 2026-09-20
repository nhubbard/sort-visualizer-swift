import Foundation

func sort(_ array: inout [Int]) {
    quickSort(&array, 0, array.count - 1)
}

func quickSort(_ array: inout [Int], _ p: Int, _ r: Int) {
    var left = p
    var right = r
    while left < right {
        let pivot = array[left + (right - left + 1) / 2]
        var i = left
        var j = right
        while i <= j {
            while array[i] < pivot { i += 1 }
            while array[j] > pivot { j -= 1 }
            if i <= j {
                array.swapAt(i, j)
                i += 1
                j -= 1
            }
        }
        if j - left < right - i {
            if left < j { quickSort(&array, left, j) }
            left = i
        } else {
            if i < right { quickSort(&array, i, right) }
            right = j
        }
    }
}


var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
