import Foundation

func sort(_ array: inout [Int]) {
    var i = array.count - 1
    while i > 0 {
        var consecSorted = 1
        for j in 0 ..< i {
            if array[j] > array[j + 1] {
                array.swapAt(j, j + 1)
                consecSorted = 1
            } else {
                consecSorted += 1
            }
        }
        i -= consecSorted
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
