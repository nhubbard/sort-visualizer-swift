func sort(_ arr: inout [Int]) {
    let n = arr.count
    guard n > 0 else {
        return
    }

    let minValue = arr.min()!
    let maxValue = arr.max()!
    let auxLength = maxValue - minValue
    var aux = [Int](repeating: 0, count: auxLength)

    func transferTo(_ index: Int) {
        var pointer = 0
        while arr[index] > minValue {
            arr[index] -= 1
            aux[pointer] += 1
            pointer += 1
        }
    }

    func transferFrom(_ index: Int) {
        var pointer = 0
        while pointer < auxLength, aux[pointer] != 0 {
            arr[index] += 1
            aux[pointer] -= 1
            pointer += 1
        }
    }

    for i in 0 ..< n {
        transferTo(i)
    }
    for i in stride(from: n - 1, through: 0, by: -1) {
        transferFrom(i)
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
