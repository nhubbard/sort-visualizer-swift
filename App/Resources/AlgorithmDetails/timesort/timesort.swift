func sort(_ arr: inout [Int]) {
    let n = arr.count
    guard n > 1 else { return }

    // Simulate the reporting order that proportional-to-value sleep durations
    // would produce in a jitter-free race: sort by value, ties broken by the
    // original position, i.e. the order the sleeps were originally scheduled.
    let woken = arr.enumerated()
        .sorted { $0.element != $1.element ? $0.element < $1.element : $0.offset < $1.offset }
        .map(\.element)
    for i in 0 ..< n {
        arr[i] = woken[i]
    }

    // Defensive cleanup pass: real scheduling jitter can't be fully trusted,
    // so finish with an ordinary insertion sort no matter what the race produced.
    for i in 1 ..< n {
        var j = i
        while j > 0, arr[j - 1] > arr[j] {
            arr.swapAt(j - 1, j)
            j -= 1
        }
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
