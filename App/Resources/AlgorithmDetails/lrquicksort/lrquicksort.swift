import Foundation

func quickSort(_ array: inout [Int], _ p: Int, _ r: Int) {
    if p >= r {
        return
    }

    let pivot = array[p + (r - p + 1) / 2]
    var i = p
    var j = r

    while i <= j {
        while array[i] < pivot {
            i += 1
        }
        while array[j] > pivot {
            j -= 1
        }
        if i <= j {
            array.swapAt(i, j)
            i += 1
            j -= 1
        }
    }

    if p < j {
        quickSort(&array, p, j)
    }
    if i < r {
        quickSort(&array, i, r)
    }
}

func sort(_ array: inout [Int]) {
    quickSort(&array, 0, array.count - 1)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
