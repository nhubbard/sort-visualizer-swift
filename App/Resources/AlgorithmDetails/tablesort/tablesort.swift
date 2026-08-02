func stableComp(_ arr: [Int], _ table: [Int], _ a: Int, _ b: Int) -> Bool {
    let ta = table[a]
    let tb = table[b]
    if arr[ta] > arr[tb] { return true }
    if arr[ta] == arr[tb] { return table[a] > table[b] }
    return false
}

func medianOfThree(_ arr: [Int], _ table: inout [Int], _ a: Int, _ b: Int) {
    let m = a + (b - 1 - a) / 2
    if stableComp(arr, table, a, m) { table.swapAt(a, m) }
    if stableComp(arr, table, m, b - 1) {
        table.swapAt(m, b - 1)
        if stableComp(arr, table, a, m) { return }
    }
    table.swapAt(a, m)
}

func partition(_ arr: [Int], _ table: inout [Int], _ a: Int, _ b: Int, _ p: Int) -> Int {
    var i = a - 1
    var j = b
    while true {
        repeat {
            i += 1
        } while i < j && !stableComp(arr, table, i, p)
        repeat {
            j -= 1
        } while j >= i && stableComp(arr, table, j, p)
        if i < j {
            table.swapAt(i, j)
        } else {
            return j
        }
    }
}

func quickSort(_ arr: [Int], _ table: inout [Int], _ a: Int, _ b: Int) {
    if b - a < 3 {
        if b - a == 2 && stableComp(arr, table, a, a + 1) {
            table.swapAt(a, a + 1)
        }
        return
    }
    medianOfThree(arr, &table, a, b)
    let p = partition(arr, &table, a + 1, b, a)
    table.swapAt(a, p)
    quickSort(arr, &table, a, p)
    quickSort(arr, &table, p + 1, b)
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    var table = Array(0..<n)
    quickSort(arr, &table, 0, n)
    for i in 0..<n {
        if table[i] != i {
            let t = arr[i]
            var j = i
            var next = table[i]
            repeat {
                arr[j] = arr[next]
                table[j] = j
                j = next
                next = table[next]
            } while next != i
            arr[j] = t
            table[j] = j
        }
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
