func forward(_ arr: inout [Int], _ leftStart: Int, _ rightStart: Int) {
    var left = leftStart
    var right = rightStart
    while left < right {
        var index = right
        while left < index {
            if arr[left] > arr[index] {
                arr.swapAt(left, index)
            }
            left += 1
            index -= 1
        }
        left = 0
        right -= 1
    }
}

func backward(_ arr: inout [Int], _ leftStart: Int, _ rightStart: Int) {
    var left = leftStart
    var right = rightStart
    let length = right
    while left < right {
        var index = left
        while index < right {
            if arr[index] > arr[right] {
                arr.swapAt(index, right)
            }
            index += 1
            right -= 1
        }
        left += 1
        right = length
    }
}

func exchange(_ arr: inout [Int], _ length: Int) {
    var left = 0
    var right = length - 1
    while left < right {
        if arr[left] > arr[right] {
            arr.swapAt(left, right)
        }
        left += 1
        right -= 1
    }

    forward(&arr, 0, length - 2)
    backward(&arr, 1, length - 1)
}

func sort(_ array: inout [Int]) {
    exchange(&array, array.count)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
