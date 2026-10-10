// MIT License
// Copyright (c) 2021 aphitorite
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

/// Five-way stable merge with a one-fifth external buffer.
final class FifthMerge {
    var a: [Int]
    private let n: Int
    private let chunk: Int
    private let bufferLength: Int
    private var buffer: [Int]

    init(_ values: [Int]) {
        a = values
        n = values.count
        chunk = n / 5
        bufferLength = n - 4 * chunk
        buffer = Array(repeating: 0, count: bufferLength)
    }

    private func binaryInsertion(_ first: Int, _ end: Int) {
        guard end - first > 1 else { return }
        for i in (first + 1) ..< end {
            let value = a[i]
            var low = first
            var high = i
            while low < high {
                let middle = low + (high - low) / 2
                if a[middle] > value {
                    high = middle
                } else {
                    low = middle + 1
                }
            }
            var j = i
            while j > low {
                a[j] = a[j - 1]
                j -= 1
            }
            a[low] = value
        }
    }

    private func source(_ index: Int, _ offset: Int, _ fromBuffer: Bool) -> Int {
        fromBuffer ? buffer[index - offset] : a[index]
    }

    private func merge(_ offset: Int, _ first: Int, _ middle: Int, _ end: Int,
                       _ fromBuffer: Bool)
    {
        var left = first
        var right = middle
        var destination = fromBuffer ? first : first - offset
        func write(_ value: Int) {
            if fromBuffer {
                a[destination] = value
            } else {
                buffer[destination] = value
            }
            destination += 1
        }
        while left < middle, right < end {
            if source(left, offset, fromBuffer) <= source(right, offset, fromBuffer) {
                write(source(left, offset, fromBuffer))
                left += 1
            } else {
                write(source(right, offset, fromBuffer))
                right += 1
            }
        }
        while left < middle {
            write(source(left, offset, fromBuffer)); left += 1
        }
        while right < end {
            write(source(right, offset, fromBuffer)); right += 1
        }
    }

    private func pingPong(_ first: Int, _ end: Int) {
        var i = first
        while i + 8 < end {
            binaryInsertion(i, i + 8)
            i += 8
        }
        if end - i > 1 {
            binaryInsertion(i, end)
        }
        let length = end - first
        var fromBuffer = false
        var gap = 8
        while gap < length {
            let full = gap * 2
            i = first
            while i + full < end {
                merge(first, i, i + gap, i + full, fromBuffer)
                i += full
            }
            if i + gap < end {
                merge(first, i, i + gap, end, fromBuffer)
            } else {
                for j in i ..< end {
                    if fromBuffer {
                        a[j] = buffer[j - first]
                    } else {
                        buffer[j - first] = a[j]
                    }
                }
            }
            fromBuffer.toggle()
            gap *= 2
        }
        if fromBuffer {
            for j in 0 ..< length {
                a[first + j] = buffer[j]
            }
        }
    }

    private func mergeForward(_ destinationStart: Int, _ first: Int, _ middle: Int, _ end: Int) {
        var destination = destinationStart
        var left = first
        var right = middle
        while left < middle, right < end {
            if a[left] <= a[right] {
                a[destination] = a[left]; left += 1
            } else {
                a[destination] = a[right]; right += 1
            }
            destination += 1
        }
        while left < middle {
            a[destination] = a[left]; destination += 1; left += 1
        }
        while right < end {
            a[destination] = a[right]; destination += 1; right += 1
        }
    }

    private func mergeBackward(_ destinationStart: Int, _ middle: Int, _ end: Int) -> (Int, Int) {
        var destination = destinationStart
        var left = middle - 1
        var right = end - 1
        while destination > right, right >= middle, left >= 0 {
            if a[left] > a[right] {
                a[destination] = a[left]; left -= 1
            } else {
                a[destination] = a[right]; right -= 1
            }
            destination -= 1
        }
        if left < 0 {
            while right >= middle {
                a[destination] = a[right]; destination -= 1; right -= 1
            }
        } else if right == left {
            while right >= 0 {
                a[destination] = a[right]; destination -= 1; right -= 1
            }
        } else if right < middle {
            while left >= 0 {
                a[destination] = a[left]; destination -= 1; left -= 1
            }
        }
        return (left + 1, right + 1)
    }

    private func mergeMainPrefix(_ destinationStart: Int, _ leftEnd: Int,
                                 _ middle: Int, _ end: Int)
    {
        var destination = destinationStart
        var left = 0
        var right = middle
        while left < leftEnd, right < end {
            if a[left] <= a[right] {
                a[destination] = a[left]; left += 1
            } else {
                a[destination] = a[right]; right += 1
            }
            destination += 1
        }
        while left < leftEnd {
            a[destination] = a[left]; destination += 1; left += 1
        }
    }

    private func mergeExternal(_ destinationStart: Int, _ middle: Int, _ end: Int) {
        var destination = destinationStart
        var left = 0
        var right = middle
        while left < bufferLength, right < end {
            if buffer[left] <= a[right] {
                a[destination] = buffer[left]; left += 1
            } else {
                a[destination] = a[right]; right += 1
            }
            destination += 1
        }
        while left < bufferLength {
            a[destination] = buffer[left]
            destination += 1
            left += 1
        }
    }

    func sort() {
        guard n > 1 else { return }
        pingPong(0, bufferLength)
        var first = bufferLength
        for _ in 0 ..< 4 {
            pingPong(first, first + chunk)
            first += chunk
        }
        for i in 0 ..< bufferLength {
            buffer[i] = a[i]
        }
        let twoFifths = 2 * chunk
        first = bufferLength
        for _ in 0 ..< 2 {
            mergeForward(first - bufferLength, first, first + chunk, first + twoFifths)
            first += twoFifths
        }
        let (left, right) = mergeBackward(n - 1, twoFifths, 2 * twoFifths)
        if right > 0 {
            mergeMainPrefix(bufferLength, left, twoFifths, n)
        }
        mergeExternal(0, bufferLength, n)
    }
}

final class ChaliceSortExample {
    var values: [Int]
    init(_ input: [Int]) {
        values = input
    }

    private var temp: [Int] = []

    private func read(_ index: Int) -> Int {
        values[index]
    }

    private func write(_ index: Int, _ value: Int) {
        values[index] = value
    }

    private func swap(_ first: Int, _ second: Int) {
        values.swapAt(first, second)
    }

    private func compare(_ first: Int, _ second: Int, by predicate: (Int, Int) -> Bool) -> Bool {
        predicate(values[first], values[second])
    }

    private func compareValues(_ first: Int, _ second: Int, by predicate: (Int, Int) -> Bool) -> Bool {
        predicate(first, second)
    }

    private func save(_ index: Int, _ value: Int) {
        temp[index] = value
    }

    private func load(_ index: Int) -> Int {
        return temp[index]
    }

    private func shiftForwardExternal(_ destination: Int, _ source: Int, _ end: Int) {
        var output = destination
        for input in source ..< end {
            write(output, read(input)); output += 1
        }
    }

    private func shiftBackwardExternal(_ start: Int, _ sourceEnd: Int, _ destinationEnd: Int) {
        var input = sourceEnd
        var output = destinationEnd
        while input > start {
            input -= 1; output -= 1; write(output, read(input))
        }
    }

    private func rightBinarySearch(_ start: Int, _ end: Int, _ value: Int) -> Int {
        var lower = start
        var upper = end
        while lower < upper {
            let middle = lower + (upper - lower) / 2
            if read(middle) <= value {
                lower = middle + 1
            } else {
                upper = middle
            }
        }
        return lower
    }

    private func multiSwap(_ first: Int, _ second: Int, _ length: Int) {
        guard length > 0 else { return }
        for offset in 0 ..< length {
            swap(first + offset, second + offset)
        }
    }

    func binaryInsertion(_ start: Int, _ end: Int) {
        guard end - start > 1 else { return }
        for index in (start + 1) ..< end {
            let value = read(index)
            var low = start
            var high = index
            while low < high {
                let middle = low + (high - low) / 2
                if read(middle) > value {
                    high = middle
                } else {
                    low = middle + 1
                }
            }
            insertTo(index, low)
        }
    }

    private func ceilCbrt(_ value: Int) -> Int {
        var low = 0
        var high = 11
        while low < high {
            let middle = (low + high) / 2
            if (1 << (3 * middle)) >= value {
                high = middle
            } else {
                low = middle + 1
            }
        }
        return 1 << low
    }

    private func calcKeys(_ blockLength: Int, _ count: Int) -> Int {
        var low = 1
        var high = count / 4
        while low < high {
            let middle = (low + high) / 2
            if (count - 4 * middle - 1) / blockLength - 2 < middle {
                high = middle
            } else {
                low = middle + 1
            }
        }
        return low
    }

    private func leftBinSearch(_ startIn: Int, _ endIn: Int, _ value: Int) -> Int {
        var start = startIn
        var end = endIn
        while start < end {
            let middle = start + (end - start) / 2
            if values[middle] >= value {
                end = middle
            } else {
                start = middle + 1
            }
        }
        return start
    }

    private func rotate(_ start: Int, _ middle: Int, _ end: Int) {
        guard start < middle, middle < end else { return }
        var position = start
        var leftLength = middle - start
        var rightLength = end - middle
        while leftLength != 0, rightLength != 0 {
            if leftLength <= rightLength {
                for offset in 0 ..< leftLength {
                    swap(position + offset, position + leftLength + offset)
                }
                position += leftLength
                rightLength -= leftLength
            } else {
                for offset in 0 ..< rightLength {
                    swap(position + leftLength - rightLength + offset, position + leftLength + offset)
                }
                leftLength -= rightLength
            }
        }
    }

    private func insertTo(_ source: Int, _ destination: Int) {
        let value = read(source)
        var cursor = source
        while cursor > destination {
            write(cursor, read(cursor - 1))
            cursor -= 1
        }
        write(destination, value)
    }

    private func shiftForward(_ destination: Int, _ source: Int, _ end: Int) {
        guard source < end else { return }
        for offset in 0 ..< (end - source) {
            swap(destination + offset, source + offset)
        }
    }

    private func shiftBackward(_ start: Int, _ sourceEnd: Int, _ destinationEnd: Int) {
        var source = sourceEnd
        var destination = destinationEnd
        while source > start {
            source -= 1
            destination -= 1
            swap(destination, source)
        }
    }

    private func mergeForwardExternal(_ startIn: Int, _ middle: Int, _ end: Int) {
        let leftLength = middle - startIn
        guard leftLength > 0 else { return }
        for offset in 0 ..< leftLength {
            save(offset, read(startIn + offset))
        }
        var start = startIn
        var left = 0
        var right = middle
        while left < leftLength, right < end {
            if compareValues(load(left), read(right), by: (<=)) {
                write(start, load(left))
                left += 1
            } else {
                write(start, read(right))
                right += 1
            }
            start += 1
        }
        while left < leftLength {
            write(start, load(left))
            left += 1
            start += 1
        }
    }

    private func mergeBackwardExternal(_ start: Int, _ middle: Int, _ endIn: Int) {
        let rightLength = endIn - middle
        guard rightLength > 0 else { return }
        for offset in 0 ..< rightLength {
            save(offset, read(middle + offset))
        }
        var end = endIn
        var right = rightLength - 1
        var left = middle - 1
        while right >= 0, left >= start {
            end -= 1
            if compareValues(load(right), read(left), by: (>=)) {
                write(end, load(right))
                right -= 1
            } else {
                write(end, read(left))
                left -= 1
            }
        }
        while right >= 0 {
            end -= 1
            write(end, load(right))
            right -= 1
        }
    }

    private func mergeWithBufferForward(_ startIn: Int, _ middle: Int, _ end: Int, _ destinationIn: Int, external: Bool) {
        var start = startIn
        var right = middle
        var destination = destinationIn
        while start < middle, right < end {
            let chooseLeft = compare(start, right, by: (<=))
            let source = chooseLeft ? start : right
            if external {
                write(destination, read(source))
            } else {
                swap(destination, source)
            }
            if chooseLeft {
                start += 1
            } else {
                right += 1
            }
            destination += 1
        }
        if start > destination {
            if external {
                shiftForwardExternal(destination, start, middle)
            } else {
                shiftForward(destination, start, middle)
            }
        }
        if external {
            shiftForwardExternal(destination, right, end)
        } else {
            shiftForward(destination, right, end)
        }
    }

    private func mergeWithBufferBackward(_ start: Int, _ middle: Int, _ endIn: Int, _ destinationEndIn: Int, external: Bool) {
        var left = middle - 1
        var right = endIn - 1
        var destinationEnd = destinationEndIn
        while right >= middle, left >= start {
            destinationEnd -= 1
            if compare(right, left, by: (>=)) {
                if external {
                    write(destinationEnd, read(right))
                } else {
                    swap(destinationEnd, right)
                }
                right -= 1
            } else {
                if external {
                    write(destinationEnd, read(left))
                } else {
                    swap(destinationEnd, left)
                }
                left -= 1
            }
        }
        if destinationEnd > right {
            if external {
                shiftBackwardExternal(middle, right + 1, destinationEnd)
            } else {
                shiftBackward(middle, right + 1, destinationEnd)
            }
        }
        if external {
            shiftBackwardExternal(start, left + 1, destinationEnd)
        } else {
            shiftBackward(start, left + 1, destinationEnd)
        }
    }

    private func inPlaceMerge(_ startIn: Int, _ middleIn: Int, _ end: Int) {
        var start = startIn
        var middle = middleIn
        while start < middle, middle < end {
            start = rightBinarySearch(start, middle, read(middle))
            if start == middle {
                return
            }
            let insertion = leftBinSearch(middle, end, read(start))
            rotate(start, middle, insertion)
            let moved = insertion - middle
            middle = insertion
            start += moved + 1
        }
    }

    private func laziestSortExternal(_ start: Int, _ end: Int) {
        var cursor = start
        while cursor < end {
            let next = min(end, cursor + temp.count)
            binaryInsertion(cursor, next)
            if cursor > start {
                mergeBackwardExternal(start, cursor, next)
            }
            cursor = next
        }
    }

    private func findKeysSmall(
        _ start: Int, _ end: Int, _ otherStart: Int, _ otherEnd: Int, _ full: Bool, _ needed: Int
    ) -> (start: Int, end: Int) {
        var first = start
        var last: Int
        if full {
            last = 0
            while first < end {
                let location = leftBinSearch(otherStart, otherEnd, read(first))
                if location == otherEnd || !compare(first, location, by: (==)) {
                    last = first + 1
                    break
                }
                first += 1
            }
            if last != 0 {
                var index = last
                while index < end, last - first < needed {
                    let otherLocation = leftBinSearch(otherStart, otherEnd, read(index))
                    if otherLocation == otherEnd || !compare(index, otherLocation, by: (==)) {
                        var location = leftBinSearch(first, last, read(index))
                        if location == last || !compare(index, location, by: (==)) {
                            rotate(first, last, index)
                            let displaced = index - last
                            first += displaced
                            location += displaced
                            last = index + 1
                            insertTo(index, location)
                        }
                    }
                    index += 1
                }
            } else {
                last = first
            }
        } else {
            last = first + 1
            var index = last
            while index < end, last - first < needed {
                var location = leftBinSearch(first, last, read(index))
                if location == last || !compare(index, location, by: (==)) {
                    rotate(first, last, index)
                    let displaced = index - last
                    first += displaced
                    location += displaced
                    last = index + 1
                    insertTo(index, location)
                }
                index += 1
            }
        }
        return (first, last)
    }

    private func findKeys(_ start: Int, _ end: Int, _ desired: Int, _ stride: Int) -> Int {
        var group = findKeysSmall(start, end, 0, 0, false, min(desired, stride))
        var first = group.start
        var last = group.end
        if stride < desired && last - first == stride {
            var remaining = desired - stride
            while true {
                group = findKeysSmall(last, end, first, last, true, min(stride, remaining))
                let found = group.end - group.start
                if found == 0 {
                    break
                }
                if found < stride || remaining == stride {
                    rotate(last, group.start, group.end)
                    let secondStart = last
                    last += found
                    mergeBackwardExternal(first, secondStart, last)
                    break
                }
                rotate(first, last, group.start)
                first += group.start - last
                last = group.end
                mergeBackwardExternal(first, group.start, last)
                remaining -= stride
            }
        }
        rotate(start, first, last)
        return last - first
    }

    private func findBitsSmall(
        _ start: Int, _ end: Int, _ referenceIn: Int, _ backward: Bool, _ needed: Int
    ) -> (start: Int, end: Int) {
        var first = start
        var reference = referenceIn
        while first < end, !compare(first, reference, by: backward ? (<) : (>)) {
            first += 1
        }
        reference += 1
        var last: Int
        if first < end {
            last = first + 1
            var index = last
            while index < end, last - first < needed {
                if compare(index, reference, by: backward ? (<) : (>)) {
                    rotate(first, last, index)
                    first += index - last
                    last = index + 1
                    reference += 1
                }
                index += 1
            }
        } else {
            last = first
        }
        return (first, last)
    }

    private func findBits(_ start: Int, _ end: Int, _ needed: Int, _ stride: Int) -> Int {
        laziestSortExternal(start, start + needed)
        let referenceStart = start
        var reference = start + needed
        var count = 0
        var firstCount = 0
        for phase in 0 ..< 2 where count < needed {
            var first = reference
            var last = first
            while true {
                let group = findBitsSmall(last, end, referenceStart + count, phase == 1, min(stride, needed - count))
                let found = group.end - group.start
                if found == 0 {
                    break
                }
                count += found
                if found < stride || count == needed {
                    rotate(last, group.start, group.end)
                    last += found
                    break
                }
                rotate(first, last, group.start)
                first += group.start - last
                last = group.end
            }
            rotate(reference, first, last)
            reference += last - first
            if phase == 0 {
                firstCount = count
            }
        }
        if count < needed {
            return -1
        }
        multiSwap(start + firstCount, start + needed + firstCount, needed - firstCount)
        return firstCount
    }

    private func bitReversal(_ start: Int, _ end: Int) {
        let length = end - start
        var offset = 0
        let half = length / 2
        let threeQuarters = half + half / 2
        if length < 3 {
            return
        }
        for index in 1 ..< (length - 1) {
            var jump = half
            var current = index
            var decrement = threeQuarters
            while current & 1 == 0 {
                jump -= decrement
                current >>= 1
                decrement >>= 1
            }
            offset += jump
            if offset > index {
                swap(start + index, start + offset)
            }
        }
    }

    private func unshuffle(_ start: Int, _ end: Int) {
        var remaining = (end - start) / 2
        var consumed = 0
        var width = 2
        while remaining > 0 {
            if remaining & 1 == 1 {
                let position = start + consumed
                bitReversal(position, position + width)
                bitReversal(position, position + width / 2)
                bitReversal(position + width / 2, position + width)
                rotate(start + consumed / 2, position, position + width / 2)
                consumed += width
            }
            remaining >>= 1
            width *= 2
        }
    }

    private func redistributeBuffer(_ startIn: Int, _ middleIn: Int, _ end: Int) {
        var start = startIn
        var middle = middleIn
        let size = temp.count
        while middle - start > size, middle < end {
            let insertion = leftBinSearch(middle, end, read(start + size))
            rotate(start + size, middle, insertion)
            let moved = insertion - middle
            middle = insertion
            mergeForwardExternal(start, start + size, middle)
            start += moved + size
        }
        if middle < end {
            mergeForwardExternal(start, middle, end)
        }
    }

    private func copyMain(_ source: Int, _ destination: Int, _ length: Int) {
        guard length > 0, source != destination else { return }
        if destination > source {
            for offset in stride(from: length - 1, through: 0, by: -1) {
                write(destination + offset, read(source + offset))
            }
        } else {
            for offset in 0 ..< length {
                write(destination + offset, read(source + offset))
            }
        }
    }

    private func dualMergeBackward(_ startIn: Int, _ middleIn: Int, _ endIn: Int, _ destinationEndIn: Int, external: Bool) {
        var start = startIn
        let middle = middleIn
        var end = endIn - 1
        var destinationEnd = destinationEndIn
        var left = middle - 1
        while destinationEnd > end + 1, end >= middle {
            destinationEnd -= 1
            if compare(end, left, by: (>=)) {
                if external {
                    write(destinationEnd, read(end))
                } else {
                    swap(destinationEnd, end)
                }
                end -= 1
            } else {
                if external {
                    write(destinationEnd, read(left))
                } else {
                    swap(destinationEnd, left)
                }
                left -= 1
            }
        }
        if end < middle {
            if external {
                shiftBackwardExternal(start, left + 1, destinationEnd)
            } else {
                shiftBackward(start, left + 1, destinationEnd)
            }
        } else {
            left += 1
            end += 1
            destinationEnd = middle - (left - start)
            var right = middle
            while start < left, right < end {
                let chooseLeft = compare(start, right, by: (<=))
                let source = chooseLeft ? start : right
                if external {
                    write(destinationEnd, read(source))
                } else {
                    swap(destinationEnd, source)
                }
                if chooseLeft {
                    start += 1
                } else {
                    right += 1
                }
                destinationEnd += 1
            }
            while start < left {
                if external {
                    write(destinationEnd, read(start))
                } else {
                    swap(destinationEnd, start)
                }
                start += 1
                destinationEnd += 1
            }
        }
    }

    private func smartMerge(_ destinationIn: Int, _ startIn: Int, _ middle: Int, _ reversed: Bool) -> Int {
        var destination = destinationIn
        var start = startIn
        var right = middle
        while start < middle {
            let chooseLeft = reversed ? compare(start, right, by: (<)) : compare(start, right, by: (<=))
            if chooseLeft {
                write(destination, read(start))
                start += 1
            } else {
                write(destination, read(right))
                right += 1
            }
            destination += 1
        }
        return right
    }

    private func smartTailMerge(_ destinationIn: Int, _ startIn: Int, _ middle: Int, _ end: Int) {
        var destination = destinationIn
        var start = startIn
        var right = middle
        let blockLength = temp.count
        while start < middle, right < end {
            if compare(start, right, by: (<=)) {
                write(destination, read(start))
                start += 1
            } else {
                write(destination, read(right))
                right += 1
            }
            destination += 1
        }
        if start < middle {
            if start > destination {
                shiftForwardExternal(destination, start, middle)
            }
            for offset in 0 ..< blockLength {
                write(end - blockLength + offset, load(offset))
            }
        } else {
            var bufferIndex = 0
            while bufferIndex < blockLength, right < end {
                if compareValues(load(bufferIndex), read(right), by: (<=)) {
                    write(destination, load(bufferIndex))
                    bufferIndex += 1
                } else {
                    write(destination, read(right))
                    right += 1
                }
                destination += 1
            }
            while bufferIndex < blockLength {
                write(destination, load(bufferIndex))
                bufferIndex += 1
                destination += 1
            }
        }
    }

    private func blockCycle(_ start: Int, _ tagStart: Int, _ sortedTags: Int, _ tagCount: Int, _ blockLength: Int) {
        guard tagCount > 1 else { return }
        for index in 0 ..< (tagCount - 1) {
            if compare(tagStart + index, sortedTags + index, by: (>)) ||
                (index > 0 && compare(tagStart + index, sortedTags + index - 1, by: (<)))
            {
                copyMain(start + index * blockLength, start - blockLength, blockLength)
                var position = index
                var next = leftBinSearch(sortedTags, sortedTags + tagCount, read(tagStart + index)) - sortedTags
                repeat {
                    copyMain(start + next * blockLength, start + position * blockLength, blockLength)
                    swap(tagStart + index, tagStart + next)
                    position = next
                    next = leftBinSearch(sortedTags, sortedTags + tagCount, read(tagStart + index)) - sortedTags
                } while next != index
                copyMain(start - blockLength, start + position * blockLength, blockLength)
            }
        }
    }

    private func blockCycleEasy(_ start: Int, _ tagStart: Int, _ sortedTags: Int, _ tagCount: Int, _ blockLength: Int) {
        guard tagCount > 1 else { return }
        for index in 0 ..< (tagCount - 1) {
            if compare(tagStart + index, sortedTags + index, by: (>)) ||
                (index > 0 && compare(tagStart + index, sortedTags + index - 1, by: (<)))
            {
                var next = leftBinSearch(sortedTags, sortedTags + tagCount, read(tagStart + index)) - sortedTags
                repeat {
                    multiSwap(start + index * blockLength, start + next * blockLength, blockLength)
                    swap(tagStart + index, tagStart + next)
                    next = leftBinSearch(sortedTags, sortedTags + tagCount, read(tagStart + index)) - sortedTags
                } while next != index
            }
        }
    }

    private func inPlaceMergeBackward(_ start: Int, _ middleIn: Int, _ endIn: Int, _ reversed: Bool) -> Int {
        var middle = middleIn
        var end = endIn
        let finalEnd = reversed
            ? rightBinarySearch(middle, end, read(middle - 1))
            : leftBinSearch(middle, end, read(middle - 1))
        end = finalEnd
        while end > middle && middle > start {
            let insertion = reversed
                ? leftBinSearch(start, middle, read(end - 1))
                : rightBinarySearch(start, middle, read(end - 1))
            rotate(insertion, middle, end)
            let moved = middle - insertion
            middle = insertion
            end -= moved + 1
            if middle == start {
                break
            }
            end = reversed
                ? rightBinarySearch(middle, end, read(middle - 1))
                : leftBinSearch(middle, end, read(middle - 1))
        }
        return finalEnd
    }

    private func blockMerge(
        _ start: Int, _ middle: Int, _ end: Int, _ leftTagCount: Int, _ tagCount: Int,
        _ tagStartIn: Int, _ sortedTagsIn: Int, _ firstBitsIn: Int, _ secondBitsIn: Int, _ blockLength: Int
    ) {
        if end - middle <= blockLength {
            mergeBackwardExternal(start, middle, end)
            return
        }
        insertTo(tagStartIn + leftTagCount - 1, tagStartIn)
        var leftBlock = start + blockLength - 1
        var rightBlock = middle + blockLength - 1
        var leftTag = tagStartIn
        var rightTag = tagStartIn + leftTagCount
        var outputTag = sortedTagsIn
        var firstBits = firstBitsIn
        var secondBits = secondBitsIn
        while leftTag < tagStartIn + leftTagCount, rightTag < tagStartIn + tagCount {
            if compare(leftBlock, rightBlock, by: (<=)) {
                swap(outputTag, leftTag)
                outputTag += 1
                leftTag += 1
                leftBlock += blockLength
            } else {
                swap(outputTag, rightTag)
                outputTag += 1
                rightTag += 1
                swap(firstBits, secondBits)
                rightBlock += blockLength
            }
            firstBits += 1
            secondBits += 1
        }
        while leftTag < tagStartIn + leftTagCount {
            swap(outputTag, leftTag)
            outputTag += 1
            leftTag += 1
            firstBits += 1
            secondBits += 1
        }
        while rightTag < tagStartIn + tagCount {
            swap(outputTag, rightTag)
            outputTag += 1
            rightTag += 1
            swap(firstBits, secondBits)
            firstBits += 1
            secondBits += 1
        }
        let tagStart = sortedTagsIn
        let sortedTags = tagStartIn
        heapSort(sortedTags, sortedTags + tagCount)
        for offset in 0 ..< blockLength {
            save(offset, read(middle - blockLength + offset))
        }
        copyMain(start, middle - blockLength, blockLength)
        blockCycle(start + blockLength, tagStart, sortedTags, tagCount, blockLength)
        multiSwap(tagStart, sortedTags, tagCount)
        firstBits -= tagCount
        secondBits -= tagCount
        var fragment = start + blockLength
        var nextBlock = fragment
        let bitsEnd = secondBits + tagCount
        var reversed = compare(firstBits, secondBits, by: (>))
        while true {
            repeat {
                if reversed {
                    swap(firstBits, secondBits)
                }
                firstBits += 1
                secondBits += 1
                nextBlock += blockLength
            } while secondBits < bitsEnd && compare(firstBits, secondBits, by: reversed ? (>) : (<))
            if secondBits == bitsEnd {
                smartTailMerge(fragment - blockLength, fragment, reversed ? fragment : nextBlock, end)
                return
            }
            fragment = smartMerge(fragment - blockLength, fragment, nextBlock, reversed)
            reversed.toggle()
        }
    }

    private func blockMergeEasy(
        _ start: Int, _ middle: Int, _ end: Int, _ leftTail: Int, _ rightTail: Int,
        _ leftTagCount: Int, _ tagCount: Int, _ tagStartIn: Int, _ sortedTagsIn: Int,
        _ firstBitsIn: Int, _ secondBitsIn: Int, _ blockLength: Int
    ) {
        if end - middle <= blockLength {
            _ = inPlaceMergeBackward(start, middle, end, false)
            return
        }
        let dataStart = start + leftTail
        let dataEnd = end - rightTail
        var leftBlock = dataStart + blockLength - 1
        var rightBlock = middle + blockLength - 1
        var leftTag = sortedTagsIn
        var rightTag = sortedTagsIn + leftTagCount
        var outputTag = tagStartIn
        var firstBits = firstBitsIn
        var secondBits = secondBitsIn
        while leftTag < sortedTagsIn + leftTagCount, rightTag < sortedTagsIn + tagCount {
            if compare(leftBlock, rightBlock, by: (<=)) {
                swap(leftTag, outputTag)
                leftTag += 1
                outputTag += 1
                leftBlock += blockLength
            } else {
                swap(rightTag, outputTag)
                rightTag += 1
                outputTag += 1
                swap(firstBits, secondBits)
                rightBlock += blockLength
            }
            firstBits += 1
            secondBits += 1
        }
        while leftTag < sortedTagsIn + leftTagCount {
            swap(leftTag, outputTag)
            leftTag += 1
            outputTag += 1
            firstBits += 1
            secondBits += 1
        }
        while rightTag < sortedTagsIn + tagCount {
            swap(rightTag, outputTag)
            rightTag += 1
            outputTag += 1
            swap(firstBits, secondBits)
            firstBits += 1
            secondBits += 1
        }
        let tagStart = sortedTagsIn
        let sortedTags = tagStartIn
        heapSort(sortedTags, sortedTags + tagCount)
        blockCycleEasy(dataStart, tagStart, sortedTags, tagCount, blockLength)
        multiSwap(tagStart, sortedTags, tagCount)
        firstBits -= tagCount
        secondBits -= tagCount
        var fragment = dataStart
        var nextBlock = fragment
        let bitsEnd = secondBits + tagCount
        var reversed = compare(firstBits, secondBits, by: (>))
        while true {
            repeat {
                if reversed {
                    swap(firstBits, secondBits)
                }
                firstBits += 1
                secondBits += 1
                nextBlock += blockLength
            } while secondBits < bitsEnd && compare(firstBits, secondBits, by: reversed ? (>) : (<))
            if secondBits == bitsEnd {
                if !reversed {
                    _ = inPlaceMergeBackward(dataStart, dataEnd, end, false)
                }
                inPlaceMerge(start, dataStart, end)
                return
            }
            fragment = inPlaceMergeBackward(fragment, nextBlock, nextBlock + blockLength, reversed)
            reversed.toggle()
        }
    }

    private func heapSort(_ start: Int, _ end: Int) {
        let count = end - start
        guard count > 1 else { return }
        func sift(_ rootIn: Int, _ limit: Int) {
            var root = rootIn
            while root * 2 + 1 < limit {
                var child = root * 2 + 1
                if child + 1 < limit, compare(start + child, start + child + 1, by: (<)) {
                    child += 1
                }
                if !compare(start + root, start + child, by: (<)) {
                    return
                }
                swap(start + root, start + child)
                root = child
            }
        }
        for root in stride(from: (count - 2) / 2, through: 0, by: -1) {
            sift(root, count)
        }
        for limit in stride(from: count - 1, through: 1, by: -1) {
            swap(start, start + limit)
            sift(0, limit)
        }
    }

    func sort() {
        let count = values.count
        let start = 0
        var end = count
        let cubeRoot = 2 * ceilCbrt(count / 4)
        var blockLength = 2 * cubeRoot
        var keyLength = calcKeys(blockLength, count)
        temp = Array(repeating: 0, count: blockLength)

        var keys = findKeys(start, end, 2 * keyLength, cubeRoot)
        if keys < 8 {
            var runLength = 1
            while runLength < count {
                var middle = start + runLength
                while middle < end {
                    _ = inPlaceMergeBackward(middle - runLength, middle, min(middle + runLength, end), false)
                    middle += 2 * runLength
                }
                runLength *= 2
            }
            return
        }
        if keys < 2 * keyLength {
            keys -= keys % 4
            keyLength = keys / 2
        }
        let keyEnd = start + keys
        var bitEnd = keyEnd + keys
        let bitSeparation = findBits(keyEnd, end, keyLength, cubeRoot)
        if bitSeparation == -1 {
            laziestSortExternal(start, bitEnd)
            inPlaceMerge(start, bitEnd, end)
            return
        }

        // Build initial runs using first the external buffer, then the internal key buffer.
        var dataStart = bitEnd + blockLength
        let dataLength = end - dataStart
        binaryInsertion(bitEnd, dataStart)
        for offset in 0 ..< blockLength {
            save(offset, read(bitEnd + offset))
        }
        var runLength = 1
        while runLength < cubeRoot {
            let vacant = max(2, runLength)
            var index = dataStart
            while index + 2 * runLength < end {
                mergeWithBufferForward(index, index + runLength, index + 2 * runLength, index - vacant, external: true)
                index += 2 * runLength
            }
            if index + runLength < end {
                mergeWithBufferForward(index, index + runLength, end, index - vacant, external: true)
            } else {
                shiftForwardExternal(index - vacant, index, end)
            }
            dataStart -= vacant
            end -= vacant
            runLength *= 2
        }

        var index = end - dataLength % (2 * runLength)
        if index + runLength < end {
            mergeWithBufferBackward(index, index + runLength, end, end + runLength, external: true)
        } else {
            shiftBackwardExternal(index, end, end + runLength)
        }
        index -= 2 * runLength
        while index >= dataStart {
            mergeWithBufferBackward(index, index + runLength, index + 2 * runLength, index + 3 * runLength, external: true)
            index -= 2 * runLength
        }
        dataStart += runLength
        end += runLength
        runLength *= 2

        index = dataStart
        while index + 2 * runLength < end {
            mergeWithBufferForward(index, index + runLength, index + 2 * runLength, index - runLength, external: true)
            index += 2 * runLength
        }
        if index + runLength < end {
            mergeWithBufferForward(index, index + runLength, end, index - runLength, external: true)
        } else {
            shiftForwardExternal(index - runLength, index, end)
        }
        dataStart -= runLength
        end -= runLength
        runLength *= 2

        index = end - dataLength % (2 * runLength)
        if index + runLength < end {
            dualMergeBackward(index, index + runLength, end, end + runLength / 2, external: true)
        } else {
            shiftBackwardExternal(index, end, end + runLength / 2)
        }
        index -= 2 * runLength
        while index >= dataStart {
            dualMergeBackward(index, index + runLength, index + 2 * runLength, index + 2 * runLength + runLength / 2, external: true)
            index -= 2 * runLength
        }
        dataStart += runLength / 2
        end += runLength / 2
        runLength *= 2

        if keys >= runLength {
            rotate(start, keyEnd, dataStart)
            bitEnd = keyEnd + blockLength
            if keyLength >= runLength {
                let minimumLevel = 2 * runLength
                while runLength < keyLength {
                    let vacant = max(minimumLevel, runLength)
                    index = dataStart
                    while index + 2 * runLength < end {
                        mergeWithBufferForward(index, index + runLength, index + 2 * runLength, index - vacant, external: false)
                        index += 2 * runLength
                    }
                    if index + runLength < end {
                        mergeWithBufferForward(index, index + runLength, end, index - vacant, external: false)
                    } else {
                        shiftForward(index - vacant, index, end)
                    }
                    dataStart -= vacant
                    end -= vacant
                    runLength *= 2
                }
                index = end - dataLength % (2 * runLength)
                if index + runLength < end {
                    mergeWithBufferBackward(index, index + runLength, end, end + runLength, external: false)
                } else {
                    shiftBackward(index, end, end + runLength)
                }
                index -= 2 * runLength
                while index >= dataStart {
                    mergeWithBufferBackward(index, index + runLength, index + 2 * runLength, index + 3 * runLength, external: false)
                    index -= 2 * runLength
                }
                dataStart += runLength
                end += runLength
                runLength *= 2
            }
            if keys >= runLength {
                index = dataStart
                while index + 2 * runLength < end {
                    mergeWithBufferForward(index, index + runLength, index + 2 * runLength, index - runLength, external: false)
                    index += 2 * runLength
                }
                if index + runLength < end {
                    mergeWithBufferForward(index, index + runLength, end, index - runLength, external: false)
                } else {
                    shiftForward(index - runLength, index, end)
                }
                dataStart -= runLength
                end -= runLength
                runLength *= 2

                index = end - dataLength % (2 * runLength)
                if index + runLength < end {
                    dualMergeBackward(index, index + runLength, end, end + runLength / 2, external: false)
                } else {
                    shiftBackward(index, end, end + runLength / 2)
                }
                index -= 2 * runLength
                while index >= dataStart {
                    dualMergeBackward(index, index + runLength, index + 2 * runLength, index + 2 * runLength + runLength / 2, external: false)
                    index -= 2 * runLength
                }
                dataStart += runLength / 2
                end += runLength / 2
                runLength *= 2
            }
            rotate(start, bitEnd, dataStart)
            bitEnd = keyEnd + keys
            heapSort(start, keyEnd)
        }
        for offset in 0 ..< blockLength {
            write(bitEnd + offset, load(offset))
        }

        unshuffle(start, keyEnd)
        let limit = blockLength * (keyLength + 2)
        var tagCount = runLength / blockLength - 1
        while runLength < dataLength, min(2 * runLength, dataLength) <= limit {
            index = dataStart
            while index + 2 * runLength <= end {
                blockMerge(index, index + runLength, index + 2 * runLength, tagCount, 2 * tagCount,
                           start, start + keyLength, keyEnd, keyEnd + keyLength, blockLength)
                index += 2 * runLength
            }
            if index + runLength < end {
                blockMerge(index, index + runLength, end, tagCount, (end - index - 1) / blockLength - 1,
                           start, start + keyLength, keyEnd, keyEnd + keyLength, blockLength)
            }
            runLength *= 2
            tagCount = 2 * tagCount + 1
        }

        while runLength < dataLength {
            blockLength = 2 * runLength / keyLength
            let leftTail = runLength % blockLength
            index = dataStart
            while index + 2 * runLength <= end {
                blockMergeEasy(index, index + runLength, index + 2 * runLength, leftTail, leftTail,
                               keyLength / 2, keyLength, start, start + keyLength,
                               keyEnd, keyEnd + keyLength, blockLength)
                index += 2 * runLength
            }
            if index + runLength < end {
                blockMergeEasy(index, index + runLength, end, leftTail, (end - index - runLength) % blockLength,
                               keyLength / 2, keyLength / 2 + (end - index - runLength) / blockLength,
                               start, start + keyLength, keyEnd, keyEnd + keyLength, blockLength)
            }
            runLength *= 2
        }

        multiSwap(keyEnd + bitSeparation, keyEnd + keyLength + bitSeparation, keyLength - bitSeparation)
        laziestSortExternal(start, dataStart)
        redistributeBuffer(start, dataStart, end)
    }
}

var array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
if array.count < 128, array.count >= 32 {
    let fallback = FifthMerge(array)
    fallback.sort()
    array = fallback.a
} else {
    let sorter = ChaliceSortExample(array)
    if array.count < 32 {
        sorter.binaryInsertion(0, array.count)
    } else {
        sorter.sort()
    }
    array = sorter.values
}

print(array)
