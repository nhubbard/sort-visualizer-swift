import Foundation

func sort(_ values: inout [Int]) {
    let n = values.count
    guard n > 1 else { return }
    let gap = 14, ratio = 4
    var positions = [Int](repeating: 0, count: gap + 2)
    var heap = [Int](repeating: 0, count: gap + 2)
    var state: UInt64 = 0x9E37_79B9_7F4A_7C15
    for value in values {
        state = (state ^ UInt64(bitPattern: Int64(value))) &* 0xBF58_476D_1CE4_E5B9 &+ 0x94D0_49BB_1331_11EB
    }
    func choice(_ count: Int) -> Int {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return Int((state &* 0x2545_F491_4F6C_DD1D) % UInt64(count))
    }
    func median(_ a: Int, _ m: Int, _ b: Int) -> Int {
        if values[m] > values[a] {
            if values[m] < values[b] {
                return m
            }
            return values[a] > values[b] ? a : b
        }
        if values[m] > values[b] {
            return m
        }
        return values[a] < values[b] ? a : b
    }
    func ninther(_ a: Int, _ b: Int) -> Int {
        let step = (b - a) / 9
        return median(
            median(a, a + step, a + 2 * step),
            median(a + 3 * step, a + 4 * step, a + 5 * step),
            median(a + 6 * step, a + 7 * step, a + 8 * step)
        )
    }
    func pivotIndex(_ a: Int, _ b: Int) -> Int {
        let step = (b - a) / 3
        return median(ninther(a, a + step), ninther(a + step, a + 2 * step), ninther(a + 2 * step, b))
    }
    func binarySearch(_ start: Int, _ end: Int, _ value: Int, backward: Bool) -> Int {
        var low = start, high = end
        while low < high {
            let middle = low + (high - low) / 2
            let found = backward ? values[middle] < value : values[middle] > value
            if found {
                high = middle
            } else {
                low = middle + 1
            }
        }
        return low
    }
    func insert(_ value: Int, from start: Int, to end: Int) {
        var index = start
        while index > end {
            index -= 1
            values[index + 1] = values[index]
        }
        values[end] = value
    }
    func insertion(_ start: Int, _ end: Int) {
        guard end > start + 1 else { return }
        for i in (start + 1) ..< end {
            let value = values[i]
            insert(value, from: i, to: binarySearch(start, i, value, backward: false))
        }
    }
    func blockSearch(_ start: Int, _ end: Int, _ value: Int, right: Bool) -> Int {
        var low = start, high = end
        while low < high {
            let middle = low + ((high - low) / (gap + 1) / 2) * (gap + 1)
            let found = right ? values[middle] > value : values[middle] >= value
            if found {
                high = middle
            } else {
                low = middle + gap + 1
            }
        }
        return low
    }
    func retrieve(_ end: Int, _ start: Int, _ pEnd: Int, _ boundary: Int, backward: Bool) {
        var destination = end - 1
        var block = pEnd - (gap + 1)
        while block > start + gap {
            var item = binarySearch(block - gap, block, boundary, backward: backward) - 1
            block -= gap + 1
            while item >= block {
                values.swapAt(destination, item)
                destination -= 1; item -= 1
            }
        }
        var item = binarySearch(start, start + gap, boundary, backward: backward) - 1
        while item >= start {
            values.swapAt(destination, item)
            destination -= 1; item -= 1
        }
    }
    func librarySort(_ start: Int, _ end: Int, _ scratch: Int, _ boundary: Int, backward: Bool) {
        let length = end - start
        if length < 32 {
            insertion(start, end); return
        }
        var count = length
        while count >= 32 {
            count = (count - 1) / ratio + 1
        }
        var i = start + count, trigger = start + ratio * count
        var pEnd = scratch + (count + 1) * (gap + 1) + gap
        insertion(start, i)
        for k in 0 ..< count {
            values.swapAt(start + k, scratch + k * (gap + 1) + gap)
        }
        while i < end {
            if i == trigger {
                retrieve(i, scratch, pEnd, boundary, backward: backward)
                count = i - start
                pEnd = scratch + (count + 1) * (gap + 1) + gap
                trigger = start + (trigger - start) * ratio
                for k in 0 ..< count {
                    values.swapAt(start + k, scratch + k * (gap + 1) + gap)
                }
            }
            let value = values[i]
            var block = blockSearch(scratch + gap, pEnd - (gap + 1), value, right: false)
            if values[block] == value {
                let afterEqual = blockSearch(block + gap + 1, pEnd - (gap + 1), value, right: true)
                block += choice((afterEqual - block) / (gap + 1)) * (gap + 1)
            }
            let loc = binarySearch(block - gap, block, boundary, backward: backward)
            if loc == block {
                repeat {
                    block += gap + 1
                } while block < pEnd && binarySearch(block - gap, block, boundary, backward: backward) == block
                if block == pEnd {
                    retrieve(i, scratch, pEnd, boundary, backward: backward)
                    count = i - start
                    pEnd = scratch + (count + 1) * (gap + 1) + gap
                    trigger = start + (trigger - start) * ratio
                    for k in 0 ..< count {
                        values.swapAt(start + k, scratch + k * (gap + 1) + gap)
                    }
                } else {
                    let first = binarySearch(block - gap, block, boundary, backward: backward)
                    let distance = block - max(first, block - gap / 2)
                    var source = block - distance, target = block
                    while source > loc - distance {
                        source -= 1; target -= 1
                        values.swapAt(target, source)
                    }
                }
            } else {
                let displaced = values[loc]
                values[i] = displaced
                i += 1
                insert(value, from: loc, to: binarySearch(block - gap, loc, value, backward: false))
            }
        }
        retrieve(end, scratch, pEnd, boundary, backward: backward)
    }
    func less(_ x: Int, _ y: Int) -> Bool {
        let left = values[positions[x]], right = values[positions[y]]
        return left < right || (left == right && x < y)
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
    func merge(_ runLength: Int, _ end: Int, _ destination: Int, _ count: Int) {
        if count < 2 {
            if count == 1 {
                var target = destination
                while positions[0] < end {
                    values.swapAt(target, positions[0])
                    target += 1; positions[0] += 1
                }
            }
            return
        }
        let start = positions[0]
        for i in 0 ..< count {
            heap[i] = i
        }
        for i in stride(from: (count - 1) / 2, through: 0, by: -1) {
            sift(heap[i], i, count)
        }
        var size = count, target = destination
        while size > 0 {
            let run = heap[0]
            values.swapAt(target, positions[run])
            target += 1; positions[run] += 1
            if positions[run] == min(start + (run + 1) * runLength, end) {
                size -= 1
                sift(heap[size], 0, size)
            } else {
                sift(heap[0], 0, size)
            }
        }
    }
    var start = 0, end = n
    while end - start >= 32 {
        let pivot = values[pivotIndex(start, end)]
        var first = start, i = start - 1, j = end, last = end
        while true {
            i += 1
            while i < j {
                if values[i] == pivot {
                    values.swapAt(first, i); first += 1
                } else if values[i] < pivot {
                    break
                }
                i += 1
            }
            j -= 1
            while j > i {
                if values[j] == pivot {
                    last -= 1; values.swapAt(last, j)
                } else if values[j] > pivot {
                    break
                }
                j -= 1
            }
            if i < j {
                values.swapAt(i, j)
            } else {
                if first == end {
                    return
                }
                if j < i {
                    j += 1
                }
                while first > start {
                    i -= 1; first -= 1; values.swapAt(i, first)
                }
                while last < end {
                    values.swapAt(j, last); j += 1; last += 1
                }
                break
            }
        }
        var left = i - start, right = end - j, count = 0
        if left <= right {
            var move = end - left
            left = max((right + 1) / (gap + 1), 16)
            var k = start
            while k < i {
                librarySort(k, min(k + left, i), j, pivot, backward: true)
                positions[count] = k; count += 1; k += left
            }
            merge(left, i, move, count)
            if j - i < move - j {
                while i < j {
                    move -= 1; values.swapAt(i, move); i += 1
                }
                end = move
            } else {
                while move > j {
                    move -= 1; values.swapAt(i, move); i += 1
                }
                end = i
            }
        } else {
            var move = start + right
            right = max((left + 1) / (gap + 1), 16)
            var k = j
            while k < end {
                librarySort(k, min(k + right, end), start, pivot, backward: false)
                positions[count] = k; count += 1; k += right
            }
            merge(right, end, start, count)
            if i - move < j - i {
                while move < i {
                    j -= 1; values.swapAt(move, j); move += 1
                }
                start = j
            } else {
                while j > i {
                    j -= 1; values.swapAt(move, j); move += 1
                }
                start = move
            }
        }
    }
    insertion(start, end)
}

var array = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
