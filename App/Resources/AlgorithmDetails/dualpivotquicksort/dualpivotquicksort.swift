import Foundation

func insertionSort(_ array: inout [Int], _ start: Int, _ end: Int) {
    guard start + 1 < end else { return }
    for i in (start + 1)..<end {
        var j = i
        while j > start && array[j] < array[j - 1] {
            array.swapAt(j - 1, j)
            j -= 1
        }
    }
}

func dualPivotQuickSort(_ array: inout [Int], _ left: Int, _ right: Int, _ initialDivisor: Int) {
    let length = right - left
    if length < 4 {
        insertionSort(&array, left, right + 1)
        return
    }
    var divisor = initialDivisor
    let third = length / divisor
    var med1 = left + third
    var med2 = right - third
    if med1 <= left { med1 = left + 1 }
    if med2 >= right { med2 = right - 1 }
    if array[med1] < array[med2] {
        array.swapAt(med1, left)
        array.swapAt(med2, right)
    } else {
        array.swapAt(med1, right)
        array.swapAt(med2, left)
    }
    let pivot1 = array[left], pivot2 = array[right]
    var less = left + 1, great = right - 1
    var k = less
    while k <= great {
        if array[k] < pivot1 {
            array.swapAt(k, less)
            less += 1
        } else if array[k] > pivot2 {
            while k < great && array[great] > pivot2 { great -= 1 }
            array.swapAt(k, great)
            great -= 1
            if array[k] < pivot1 {
                array.swapAt(k, less)
                less += 1
            }
        }
        k += 1
    }
    if great - less < 13 { divisor += 1 }
    array.swapAt(less - 1, left)
    array.swapAt(great + 1, right)
    dualPivotQuickSort(&array, left, less - 2, divisor)
    if pivot1 < pivot2 { dualPivotQuickSort(&array, less, great, divisor) }
    dualPivotQuickSort(&array, great + 2, right, divisor)
}

func sort(_ array: inout [Int]) {
    dualPivotQuickSort(&array, 0, array.count - 1, 3)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
