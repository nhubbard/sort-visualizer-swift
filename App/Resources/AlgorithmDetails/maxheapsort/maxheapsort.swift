func siftDown(_ array: inout [Int], _ rootIn: Int, _ size: Int) {
    var root = rootIn
    while true {
        var largest = root
        let left = 2 * root + 1
        let right = left + 1
        if left < size, array[largest] < array[left] { largest = left }
        if right < size, array[largest] < array[right] { largest = right }
        if largest == root { break }
        array.swapAt(root, largest)
        root = largest
    }
}

func sort(_ array: inout [Int]) {
    let length = array.count
    var i = length / 2 - 1
    var k = length - 1
    while i >= 0 {
        siftDown(&array, i, length)
        i -= 1
    }
    while k > 0 {
        array.swapAt(0, k)
        siftDown(&array, 0, k)
        k -= 1
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
