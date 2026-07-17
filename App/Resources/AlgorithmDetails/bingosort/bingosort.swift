func sort(_ arr: inout [Int]) {
    let n = arr.count
    guard n > 1 else {
        return
    }

    // Find the true maximum value in the array.
    var maximum = n - 1
    var next = arr[maximum]
    var i = maximum - 1
    while i >= 0 {
        if arr[i] > next {
            next = arr[i]
        }
        i -= 1
    }
    // Skip past any elements already sitting at the tail with that value.
    while maximum > 0 && arr[maximum] == next {
        maximum -= 1
    }

    while maximum > 0 {
        // This round's target is the max found by the previous pass.
        let val = next
        next = arr[maximum]

        // Sweep once, moving every occurrence of `val` into the shrinking tail
        // while tracking the next-highest value among what's left behind.
        var j = maximum - 1
        while j >= 0 {
            if arr[j] == val {
                arr.swapAt(j, maximum)
                maximum -= 1
            } else if arr[j] > next {
                next = arr[j]
            }
            j -= 1
        }

        while maximum > 0 && arr[maximum] == next {
            maximum -= 1
        }
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
