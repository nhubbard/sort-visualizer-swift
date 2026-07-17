import Foundation

func sort(_ arr: inout [Int]) {
    let n = arr.count
    if n <= 1 {
        return
    }
    let pow2 = Int(log(Double(n - 1)) / log(2.0))
    for k in stride(from: pow2, through: 0, by: -1) {
        let pow3 = Int((log(Double(n)) - Double(k) * log(2.0)) / log(3.0))
        for j in stride(from: pow3, through: 0, by: -1) {
            let gap = Int(pow(2.0, Double(k)) * pow(3.0, Double(j)))
            var i = 0
            while i + gap < n {
                if arr[i] > arr[i + gap] {
                    arr.swapAt(i, i + gap)
                }
                i += 1
            }
        }
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
