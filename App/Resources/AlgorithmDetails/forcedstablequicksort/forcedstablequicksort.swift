func stableComp(_ arr: [Int], _ key: [Int], _ a: Int, _ b: Int) -> Bool {
    if arr[a] > arr[b] { return true }
    if arr[a] == arr[b] { return key[a] > key[b] }
    return false
}

func stableSwap(_ arr: inout [Int], _ key: inout [Int], _ a: Int, _ b: Int) {
    arr.swapAt(a, b)
    key.swapAt(a, b)
}

func medianOfThree(_ arr: inout [Int], _ key: inout [Int], _ a: Int, _ b: Int) {
    let m = a + (b - 1 - a) / 2
    if stableComp(arr, key, a, m) { stableSwap(&arr, &key, a, m) }
    if stableComp(arr, key, m, b - 1) {
        stableSwap(&arr, &key, m, b - 1)
        if stableComp(arr, key, a, m) { return }
    }
    stableSwap(&arr, &key, a, m)
}

func partition(_ arr: inout [Int], _ key: inout [Int], _ a: Int, _ b: Int, _ p: Int) -> Int {
    var i = a - 1
    var j = b
    while true {
        repeat {
            i += 1
        } while i < j && !stableComp(arr, key, i, p)
        repeat {
            j -= 1
        } while j >= i && stableComp(arr, key, j, p)
        if i < j {
            stableSwap(&arr, &key, i, j)
        } else {
            return j
        }
    }
}

func quickSort(_ arr: inout [Int], _ key: inout [Int], _ a: Int, _ b: Int) {
    if b - a < 3 {
        if b - a == 2 && stableComp(arr, key, a, a + 1) {
            stableSwap(&arr, &key, a, a + 1)
        }
        return
    }
    medianOfThree(&arr, &key, a, b)
    let p = partition(&arr, &key, a + 1, b, a)
    stableSwap(&arr, &key, a, p)
    quickSort(&arr, &key, a, p)
    quickSort(&arr, &key, p + 1, b)
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    var key = Array(0..<n)
    quickSort(&arr, &key, 0, n)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
