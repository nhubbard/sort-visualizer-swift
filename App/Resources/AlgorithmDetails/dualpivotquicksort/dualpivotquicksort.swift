import Foundation

func partition(_ array: inout [Int],
               _ low: Int,
               _ high: Int) -> (Int, Int)
{
    if array[low] > array[high] {
        array.swapAt(low, high)
    }
    var j = low + 1
    var g = high - 1
    var k = low + 1
    let p = array[low]
    let q = array[high]
    while k <= g {
        if array[k] < p {
            array.swapAt(k, j)
            j += 1
        } else if array[k] >= q {
            while array[g] > q, k < g {
                g -= 1
            }
            array.swapAt(k, g)
            g -= 1
            if array[k] < p {
                array.swapAt(k, j)
                j += 1
            }
        }
        k += 1
    }
    j -= 1
    g += 1
    array.swapAt(low, j)
    array.swapAt(high, g)
    return (j, g)
}

func dualPivotQuickSort(_ array: inout [Int], _ low: Int, _ high: Int) {
    if low < high {
        let (j, g) = partition(&array, low, high)
        dualPivotQuickSort(&array, low, j - 1)
        dualPivotQuickSort(&array, j + 1, g - 1)
        dualPivotQuickSort(&array, g + 1, high)
    }
}

func sort(_ array: inout [Int]) {
    dualPivotQuickSort(&array, 0, array.count - 1)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
