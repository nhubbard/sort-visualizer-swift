func sort(_ array: inout [Int]) {
    array.withUnsafeMutableBufferPointer { items in
        let count = items.count
        guard count > 1 else { return }

        func swap(_ a: Int, _ b: Int) {
            items.swapAt(a % count, b % count)
        }
        func shiftForward(_ start: Int, _ midpoint: Int, _ end: Int) {
            var a = start
            var middle = midpoint
            while middle < end {
                swap(a, middle)
                a += 1
                middle += 1
            }
        }
        func shiftBackward(_ start: Int, _ midpoint: Int, _ finish: Int) {
            var middle = midpoint
            var end = finish
            while middle > start {
                end -= 1
                middle -= 1
                swap(end, middle)
            }
        }
        func insertion(_ start: Int, _ end: Int) {
            guard start + 1 < end else { return }
            for first in (start + 1) ..< end {
                var i = first
                while i > start, items[(i - 1) % count] > items[i % count] {
                    swap(i, i - 1)
                    i -= 1
                }
            }
        }
        func multiSwap(_ a: Int, _ b: Int, _ length: Int) {
            guard length > 0 else { return }
            for i in 0 ..< length {
                swap(a + i, b + i)
            }
        }
        func rotate(_ begin: Int, _ midpoint: Int, _ finish: Int) {
            var start = begin
            var middle = midpoint
            var end = finish
            var left = middle - start
            var right = end - middle
            while left > 0, right > 0 {
                if right < left {
                    multiSwap(middle - right, middle, right)
                    end -= right
                    middle -= right
                    left -= right
                } else {
                    multiSwap(start, middle, left)
                    start += left
                    middle += left
                    right -= left
                }
            }
        }
        func inPlaceMerge(_ start: Int, _ midpoint: Int, _ end: Int) {
            var i = start
            var middle = midpoint
            while i < middle, middle < end {
                if items[i % count] > items[middle % count] {
                    var k = middle + 1
                    while k < end, items[i % count] > items[k % count] {
                        k += 1
                    }
                    rotate(i, middle, k)
                    i += k - middle
                    middle = k
                } else {
                    i += 1
                }
            }
        }
        @discardableResult
        func merge(_ position: Int, _ start: Int, _ middle: Int, _ end: Int, _ full: Bool) -> Int {
            var p = position
            var i = start
            var j = middle
            while i < middle, j < end {
                if items[i % count] <= items[j % count] {
                    swap(p, i)
                    i += 1
                } else {
                    swap(p, j)
                    j += 1
                }
                p += 1
            }
            if i < middle {
                if i > p {
                    shiftForward(p, i, middle)
                }
            } else if full {
                shiftForward(p, j, end)
            }
            return i < middle ? i : j
        }
        func blockLess(_ a: Int, _ b: Int, _ length: Int) -> Bool {
            if items[a % count] != items[b % count] {
                return items[a % count] < items[b % count]
            }
            return items[(a + length - 1) % count] < items[(b + length - 1) % count]
        }
        func blockMerge(_ start: Int, _ middle: Int, _ end: Int, _ length: Int) {
            let b1 = end - (end - middle - 1) % length - 1
            if b1 <= middle {
                merge(start - length, start, middle, end, true)
                return
            }
            var b2 = b1
            var i = middle - length
            while i > start, blockLess(b1, i, length) {
                i -= length
                b2 -= length
            }
            var j = start
            while j < b1 - length {
                var minimum = j
                i = j + length
                while i < b1 {
                    if blockLess(i, minimum, length) {
                        minimum = i
                    }
                    i += length
                }
                if minimum != j {
                    multiSwap(j, minimum, length)
                }
                j += length
            }
            var frontier = start
            i = start + length
            while i < b2 {
                frontier = merge(frontier - length, frontier, i, i + length, false)
                if frontier < i {
                    shiftBackward(frontier, i, i + length)
                    frontier += length
                }
                i += length
            }
            merge(frontier - length, frontier, b1, end, true)
        }

        if count <= 16 {
            insertion(0, count)
            return
        }
        var block = 1
        while block * block < count {
            block *= 2
        }
        var i = block
        var run = 1
        let rolling = count - block
        var end = count
        while run <= block {
            while i + 2 * run < end {
                merge(i - run, i, i + run, i + 2 * run, true)
                i += 2 * run
            }
            if i + run < end {
                merge(i - run, i, i + run, end, true)
            } else {
                shiftForward(i - run, i, end)
            }
            i = end + block - run
            end = i + rolling
            run *= 2
        }
        while run < rolling {
            while i + 2 * run < end {
                blockMerge(i, i + run, i + 2 * run, block)
                i += 2 * run
            }
            if i + run < end {
                blockMerge(i, i + run, end, block)
            } else {
                shiftForward(i - block, i, end)
            }
            i = end
            end += rolling
            run *= 2
        }
        insertion(i - block, i)
        inPlaceMerge(i - block, i, end)
        rotate(0, (i - block) % count, count)
    }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(&array)
print(array)
