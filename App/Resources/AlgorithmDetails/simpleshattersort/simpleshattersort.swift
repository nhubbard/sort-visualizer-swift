func insertionSort(_ arr: inout [Int], _ start: Int, _ end: Int) {
    var i = start + 1
    while i < end {
        let key = arr[i]
        var j = i - 1
        while j >= start, arr[j] > key {
            arr[j + 1] = arr[j]
            j -= 1
        }
        arr[j + 1] = key
        i += 1
    }
}

func shatterPartition(_ arr: inout [Int], _ start: Int, _ length: Int, _ num: Int) -> [Int] {
    var minV = arr[start]
    var maxV = arr[start]
    for i in 1 ..< length {
        minV = min(minV, arr[start + i])
        maxV = max(maxV, arr[start + i])
    }
    let valueRange = maxV - minV + 1
    let shatters = (length + num - 1) / num

    var buckets = [[Int]](repeating: [], count: shatters)
    for i in 0 ..< length {
        let v = arr[start + i]
        var idx = (v - minV) * shatters / valueRange
        if idx > shatters - 1 {
            idx = shatters - 1
        }
        buckets[idx].append(v)
    }

    var offsets = [Int](repeating: 0, count: shatters + 1)
    for i in 0 ..< shatters {
        offsets[i + 1] = offsets[i] + buckets[i].count
    }

    var pos = start
    for bucket in buckets {
        for v in bucket {
            arr[pos] = v
            pos += 1
        }
    }
    return offsets
}

func floorLog2(_ n: Int) -> Int {
    var log = 0
    var m = n
    while m > 1 {
        m >>= 1
        log += 1
    }
    return log
}

func simpleShatterSort(_ arr: inout [Int], _ length: Int, _ num: Int, _ rate: Int) {
    var i = num
    while i > 1 {
        _ = shatterPartition(&arr, 0, length, i)
        i /= rate
    }
    let offsets = shatterPartition(&arr, 0, length, 1)
    for k in 0 ..< (offsets.count - 1) {
        if offsets[k + 1] - offsets[k] > 1 {
            insertionSort(&arr, offsets[k], offsets[k + 1])
        }
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    let rate = max(2, floorLog2(n) / 2)
    simpleShatterSort(&arr, n, 4, rate)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
