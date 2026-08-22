func sortRange(_ arr: inout [Int], _ start: Int, _ end: Int) {
    if start >= end - 1 {
        return
    }

    var pivot = start

    func isPartitioned() -> Bool {
        for i in start ..< pivot {
            if arr[i] > arr[pivot] {
                return false
            }
        }
        for i in (pivot + 1) ..< end {
            if arr[pivot] > arr[i] {
                return false
            }
        }
        return true
    }

    while !isPartitioned() {
        for i in start ..< end {
            let j = Int.random(in: i ... (end - 1))
            if pivot == i {
                pivot = j
            } else if pivot == j {
                pivot = i
            }
            arr.swapAt(i, j)
        }
    }

    sortRange(&arr, start, pivot)
    sortRange(&arr, pivot + 1, end)
}

func sort(_ arr: inout [Int]) {
    var a = arr
    sortRange(&a, 0, a.count)
    arr = a
}

var array: [Int] = [0, 39, 21, 62, 91, 14, 23]
sort(&array)
print(array)
