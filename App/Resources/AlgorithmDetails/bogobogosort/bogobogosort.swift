/// A literal Bogo Bogo Sort re-derives the "is it sorted?" answer through a recursive sort of its
/// own, so its real cost grows worse than n! squared -- even a handful of elements can take an
/// unreasonable amount of time. To keep this example runnable, the true recursive algorithm below
/// is only ever applied to a small leading slice of the array (chaosLimit elements); the rest is
/// finished with an ordinary insertion sort, and the two already-sorted pieces are merged back
/// together at the end. The random reshuffle is also replaced with a deterministic, never-repeating
/// permutation walk, so neither piece can wander into an unbounded random search.
let chaosLimit = 5

/// Advances `arr` to its next lexicographic permutation in place. Returns false (after resetting
/// `arr` to its first, fully ascending permutation) once every arrangement has been visited -- a
/// deterministic stand-in for "shuffle the array at random".
@discardableResult
func nextPermutation(_ arr: inout [Int]) -> Bool {
    let n = arr.count
    var i = n - 2
    while i >= 0, arr[i] >= arr[i + 1] {
        i -= 1
    }
    if i < 0 {
        arr.reverse()
        return false
    }
    var j = n - 1
    while arr[j] <= arr[i] {
        j -= 1
    }
    arr.swapAt(i, j)
    arr[(i + 1)...] = ArraySlice(arr[(i + 1)...].reversed())
    return true
}

/// The heart of the joke: rather than scanning `arr` once, decide whether it is sorted by copying
/// it, recursively Bogo-Bogo-sorting the copy's first n - 1 elements with this exact same process
/// one level down, reshuffling the whole copy until its last two elements land in order, and
/// comparing the result against the original. A match means the copy is now the true sorted
/// arrangement of the same values, which is only possible if `arr` was already sorted.
func bogoBogoIsSorted(_ arr: [Int]) -> Bool {
    let n = arr.count
    guard n > 1 else { return true }
    var copy = arr
    var prefix = Array(copy[0 ..< (n - 1)])
    bogoBogoSort(&prefix)
    copy[0 ..< (n - 1)] = ArraySlice(prefix)
    var candidate = 0
    while copy[n - 2] > copy[n - 1] {
        copy.swapAt(candidate, n - 1)
        candidate += 1
        prefix = Array(copy[0 ..< (n - 1)])
        bogoBogoSort(&prefix)
        copy[0 ..< (n - 1)] = ArraySlice(prefix)
    }
    return copy == arr
}

func bogoBogoSort(_ arr: inout [Int]) {
    while !bogoBogoIsSorted(arr) {
        nextPermutation(&arr)
    }
}

func insertionSort(_ arr: inout [Int]) {
    for i in 1 ..< arr.count {
        let key = arr[i]
        var j = i - 1
        while j >= 0, arr[j] > key {
            arr[j + 1] = arr[j]
            j -= 1
        }
        arr[j + 1] = key
    }
}

func mergeSorted(_ a: [Int], _ b: [Int]) -> [Int] {
    var merged: [Int] = []
    merged.reserveCapacity(a.count + b.count)
    var i = 0
    var j = 0
    while i < a.count, j < b.count {
        if a[i] <= b[j] {
            merged.append(a[i])
            i += 1
        } else {
            merged.append(b[j])
            j += 1
        }
    }
    merged.append(contentsOf: a[i...])
    merged.append(contentsOf: b[j...])
    return merged
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    let limit = min(chaosLimit, n)
    var chaos = Array(arr[0 ..< limit])
    var rest = Array(arr[limit...])
    bogoBogoSort(&chaos) // the real, recursive-check algorithm -- kept tiny on purpose
    insertionSort(&rest) // an ordinary fast sort for everything past the demonstration slice
    arr = mergeSorted(chaos, rest)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
