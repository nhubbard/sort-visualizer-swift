import Foundation

func doubleInsertionSort(_ array: inout [Int], _ start: Int, _ end: Int) {
    var left = start + (end - start) / 2 - 1
    var right = left + 1
    if array[left] > array[right] {
        array.swapAt(left, right)
    }
    left -= 1
    right += 1

    while left >= start, right < end {
        if array[left] > array[right] {
            let leftItem = array[right]
            let rightItem = array[left]

            var pos = left + 1
            while pos <= right, array[pos] <= leftItem {
                array[pos - 1] = array[pos]
                pos += 1
            }
            array[pos - 1] = leftItem

            pos = right - 1
            while pos >= left, array[pos] >= rightItem {
                array[pos + 1] = array[pos]
                pos -= 1
            }
            array[pos + 1] = rightItem
        } else {
            let leftItem = array[left]
            let rightItem = array[right]

            var pos = left + 1
            while array[pos] < leftItem {
                array[pos - 1] = array[pos]
                pos += 1
            }
            array[pos - 1] = leftItem

            pos = right - 1
            while array[pos] > rightItem {
                array[pos + 1] = array[pos]
                pos -= 1
            }
            array[pos + 1] = rightItem
        }

        left -= 1
        right += 1
    }

    if right < end {
        var pos = right - 1
        let current = array[right]
        while pos >= start, array[pos] > current {
            array[pos + 1] = array[pos]
            pos -= 1
        }
        array[pos + 1] = current
    }
}

func sort(_ array: inout [Int]) {
    if array.count > 1 {
        doubleInsertionSort(&array, 0, array.count)
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
