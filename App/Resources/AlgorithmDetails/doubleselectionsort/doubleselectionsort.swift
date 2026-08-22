import Foundation

func doubleSelectionSort(_ array: inout [Int]) {
    let n = array.count
    if n <= 1 {
        return
    }

    var left = 0
    var right = n - 1
    var smallest = 0
    var biggest = 0

    while left <= right {
        for i in left ... right {
            if array[i] > array[biggest] {
                biggest = i
            }
            if array[i] < array[smallest] {
                smallest = i
            }
        }

        if biggest == left {
            biggest = smallest
        }

        array.swapAt(left, smallest)
        array.swapAt(right, biggest)

        left += 1
        right -= 1
        smallest = left
        biggest = right
    }
}

func sort(_ array: inout [Int]) {
    doubleSelectionSort(&array)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
