import Foundation

func sort(_ array: inout [Int]) {
    let length = array.count
    var a = 1
    while a < length {
        var b = a
        var c = 0
        while b < length {
            if array[b - a] > array[b] {
                array.swapAt(b - a, b)
            }
            c = (c + 1) % a
            b += 1
            if c == 0 {
                b += a
            }
        }
        a *= 2
    }

    a /= 4
    var e = 1
    while a > 0 {
        var d = e
        while d > 0 {
            var b = (d + 1) * a
            var c = 0
            while b < length {
                if array[b - (d * a)] > array[b] {
                    array.swapAt(b - (d * a), b)
                }
                c = (c + 1) % a
                b += 1
                if c == 0 {
                    b += a
                }
            }
            d /= 2
        }
        a /= 2
        e = (e * 2) + 1
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
