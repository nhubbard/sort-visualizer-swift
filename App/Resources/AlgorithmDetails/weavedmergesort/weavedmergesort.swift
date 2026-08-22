import Foundation

func merge(_ arr: inout [Int], _ tmp: inout [Int], _ length: Int, _ residue: Int, _ modulus: Int) {
    if residue + modulus >= length {
        return
    }
    var low = residue
    var high = residue + modulus
    let dmodulus = modulus << 1

    merge(&arr, &tmp, length, low, dmodulus)
    merge(&arr, &tmp, length, high, dmodulus)

    var nxt = residue
    while low < length, high < length {
        if arr[low] > arr[high] || (arr[low] == arr[high] && low > high) {
            tmp[nxt] = arr[high]
            high += dmodulus
        } else {
            tmp[nxt] = arr[low]
            low += dmodulus
        }
        nxt += modulus
    }
    if low >= length {
        while high < length {
            tmp[nxt] = arr[high]
            nxt += modulus
            high += dmodulus
        }
    } else {
        while low < length {
            tmp[nxt] = arr[low]
            nxt += modulus
            low += dmodulus
        }
    }
    var i = residue
    while i < length {
        arr[i] = tmp[i]
        i += modulus
    }
}

func sort(_ arr: inout [Int]) {
    var tmp = [Int](repeating: 0, count: arr.count)
    merge(&arr, &tmp, arr.count, 0, 1)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
