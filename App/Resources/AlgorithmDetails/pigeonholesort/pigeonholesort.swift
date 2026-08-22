import Foundation

func sort(_ array: inout [Int]) {
    guard !array.isEmpty else {
        return
    }
    var minValue = array[0]
    var maxValue = array[0]
    for value in array {
        if value < minValue {
            minValue = value
        }
        if value > maxValue {
            maxValue = value
        }
    }

    let size = maxValue - minValue + 1
    var holes = [Int](repeating: 0, count: size)
    for value in array {
        holes[value - minValue] += 1
    }

    var j = 0
    for count in 0 ..< size {
        while holes[count] > 0 {
            holes[count] -= 1
            array[j] = count + minValue
            j += 1
        }
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
