let recency = 8
let earlyOutTestAt = 4
let earlyOutDisorderFraction = 0.6

func sort(_ array: inout [Int]) {
    let length = array.count
    guard length > 1 else { return }

    var dropped: [Int] = []
    var droppedInARow = 0
    var read = 0
    var write = 0
    var iteration = 0

    while read < length {
        iteration += 1
        if iteration == length / earlyOutTestAt,
           Double(dropped.count) > Double(read) * earlyOutDisorderFraction {
            for value in dropped {
                array[write] = value
                write += 1
            }
            // Simplified fallback: the Python reference uses branched PDQ sorting here.
            array.sort()
            return
        }

        if write == 0 || array[read] >= array[write - 1] {
            array[write] = array[read]
            write += 1
            read += 1
            droppedInARow = 0
        } else if droppedInARow == 0, write >= 2, array[read] >= array[write - 2] {
            dropped.append(array[write - 1])
            array[write - 1] = array[read]
            read += 1
        } else if droppedInARow < recency {
            dropped.append(array[read])
            read += 1
            droppedInARow += 1
        } else {
            dropped.removeLast(droppedInARow)
            read -= droppedInARow
            var backtracked = 1
            write -= 1
            var largest = read
            for index in (read + 1) ... (read + droppedInARow) {
                if array[index] > largest {
                    largest = array[index]
                }
            }

            while write >= 1 && largest < array[write - 1] {
                write -= 1
                backtracked += 1
            }

            dropped.append(contentsOf: array[write ..< write + backtracked])
            droppedInARow = 0
        }
    }

    for (offset, value) in dropped.enumerated() {
        array[write + offset] = value
    }
    // Simplified tail sort: the Python reference uses branched PDQ sorting here.
    array[write ..< length].sort()
    let buffer = Array(array[write ..< length])
    var left = write - 1
    var right = buffer.count - 1
    var output = length - 1

    while right >= 0 {
        if left < 0 || buffer[right] > array[left] {
            array[output] = buffer[right]
            right -= 1
        } else {
            array[output] = array[left]
            left -= 1
        }
        output -= 1
    }
}

var array: [Int] = [
    0, 1, 2, 3, 4, 9, 6, 7, 8, 5,
    10, 11, 12, 13, 14, 15, 21, 17, 18, 19,
    20, 16, 22, 23, 24, 28, 26, 27, 25, 29,
]
sort(&array)
print(array)
