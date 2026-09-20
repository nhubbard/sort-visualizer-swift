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

func optimizedDualPivotQuickSort(_ array: inout [Int], _ left: Int, _ right: Int, _ initialDivisor: Int) {
    let length = right - left
    if length < 27 {
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
    let dist = great - less
    if dist < 13 { divisor += 1 }
    array.swapAt(less - 1, left)
    array.swapAt(great + 1, right)
    optimizedDualPivotQuickSort(&array, left, less - 2, divisor)
    optimizedDualPivotQuickSort(&array, great + 2, right, divisor)
    if dist > length - 13, pivot1 != pivot2 {
        var k = less
        while k <= great {
            if array[k] == pivot1 {
                array.swapAt(k, less)
                less += 1
            } else if array[k] == pivot2 {
                array.swapAt(k, great)
                great -= 1
                if array[k] == pivot1 {
                    array.swapAt(k, less)
                    less += 1
                }
            }
            k += 1
        }
    }
    if pivot1 < pivot2 { optimizedDualPivotQuickSort(&array, less, great, divisor) }
}

func sort(_ array: inout [Int]) {
    optimizedDualPivotQuickSort(&array, 0, array.count - 1, 3)
}

var array: [Int] = [
    55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79,
    21, 88, 5, 51, 66, 29, 44, 12, 78, 33, 91, 6, 58, 12,
]
sort(&array)
print(array)
