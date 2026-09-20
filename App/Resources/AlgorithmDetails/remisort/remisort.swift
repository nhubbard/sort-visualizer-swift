import Foundation

func sort(_ a: inout [Int]) {
    let n = a.count
    guard n > 1 else { return }
    var low = 0, high = min(n, 1291)
    while low < high {
        let mid = (low + high) / 2
        if mid * mid * mid >= n {
            high = mid
        } else {
            low = mid + 1
        }
    }
    let block = low, runLength = block * block, runCount = (n - 1) / runLength + 1
    var keys = Array(0 ..< (runCount < 2 ? n : runLength))
    func greater(_ x: Int, _ y: Int, _ base: Int) -> Bool {
        a[base + x] > a[base + y] || (a[base + x] == a[base + y] && x > y)
    }
    func tableSift(_ root: Int, _ length: Int, _ base: Int, _ initial: Int) {
        var j = root, item = initial
        while 2 * j + 1 < length {
            j = 2 * j + 1
            if j + 1 < length, greater(keys[j + 1], keys[j], base) {
                j += 1
            }
        }
        while j > root, greater(item, keys[j], base) {
            j = (j - 1) / 2
        }
        while j > root {
            let previous = keys[j]
            keys[j] = item
            item = previous
            j = (j - 1) / 2
        }
        keys[root] = item
    }
    func tableSort(_ start: Int, _ end: Int) {
        let length = end - start
        guard length > 1 else { return }
        for i in stride(from: (length - 1) / 2, through: 0, by: -1) {
            tableSift(i, length, start, keys[i])
        }
        for i in stride(from: length - 1, to: 0, by: -1) {
            let item = keys[i]
            keys[i] = keys[0]
            tableSift(0, i, start, item)
        }
        for i in 0 ..< length where keys[i] != i {
            let held = a[start + i]
            var j = i, next = keys[i]
            repeat {
                a[start + j] = a[start + next]
                keys[j] = j
                j = next
                next = keys[next]
            } while next != i
            a[start + j] = held
            keys[j] = j
        }
    }
    if runCount < 2 {
        tableSort(0, n); return
    }
    var buffer = [Int](repeating: 0, count: runLength)
    var heap = Array(0 ..< runCount)
    var position = [Int](repeating: 0, count: runCount)
    var destination = [Int](repeating: 0, count: runCount)
    for run in 0 ..< runCount {
        let start = run * runLength
        tableSort(start, min(start + runLength, n))
        position[run] = start
        destination[run] = start
    }
    func less(_ x: Int, _ y: Int) -> Bool {
        a[position[x]] < a[position[y]] || (a[position[x]] == a[position[y]] && x < y)
    }
    func sift(_ item: Int, _ start: Int, _ size: Int) {
        var root = start
        while 2 * root + 2 < size {
            let left = 2 * root + 1
            let child = less(heap[left], heap[left + 1]) ? left : left + 1
            if !less(heap[child], item) {
                break
            }
            heap[root] = heap[child]
            root = child
        }
        let left = 2 * root + 1
        if left < size, less(heap[left], item) {
            heap[root] = heap[left]
            root = left
        }
        heap[root] = item
    }
    for i in stride(from: (runCount - 1) / 2, through: 0, by: -1) {
        sift(heap[i], i, runCount)
    }
    var size = runCount
    func advance(_ run: Int) {
        position[run] += 1
        if position[run] == min((run + 1) * runLength, n) {
            size -= 1
            sift(heap[size], 0, size)
        } else {
            sift(heap[0], 0, size)
        }
    }
    for i in buffer.indices {
        let run = heap[0]
        buffer[i] = a[position[run]]
        advance(run)
    }
    var t = 0, count = 0, cursor = 0
    while position[cursor] - destination[cursor] < block {
        cursor += 1
    }
    repeat {
        let run = heap[0]
        a[destination[cursor]] = a[position[run]]
        destination[cursor] += 1
        advance(run)
        count += 1
        if count == block {
            keys[t] = cursor > 0 ? destination[cursor] / block - block - 1 : -1
            t += 1
            cursor = 0
            count = 0
            while position[cursor] - destination[cursor] < block {
                cursor += 1
            }
        }
    } while size > 0
    var end = n
    while count > 0 {
        count -= 1
        destination[cursor] -= 1
        end -= 1
        a[end] = a[destination[cursor]]
    }
    position[runCount - 1] = end
    keys[keys.count - 1] = -1
    t = 0
    while keys[t] != -1 {
        t += 1
    }
    var source = 0
    for run in 1 ..< runCount {
        if source >= destination[0] {
            break
        }
        while destination[run] < position[run] {
            keys[t] = destination[run] / block - block
            t += 1
            while keys[t] != -1 {
                t += 1
            }
            for x in 0 ..< block {
                a[destination[run] + x] = a[source + x]
            }
            destination[run] += block
            source += block
        }
    }
    for x in buffer.indices {
        a[x] = buffer[x]
    }
    let blocks = (end - runLength) / block
    for i in 0 ..< blocks where keys[i] != i {
        for x in 0 ..< block {
            buffer[x] = a[runLength + i * block + x]
        }
        var j = i, next = keys[i]
        repeat {
            for x in 0 ..< block {
                a[runLength + j * block + x] = a[runLength + next * block + x]
            }
            keys[j] = j
            j = next
            next = keys[next]
        } while next != i
        for x in 0 ..< block {
            a[runLength + j * block + x] = buffer[x]
        }
        keys[j] = j
    }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
