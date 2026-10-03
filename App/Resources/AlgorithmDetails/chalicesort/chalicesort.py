# MIT License
# Copyright (c) 2021 aphitorite
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software
# and associated documentation files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


class KeyGroup:
    def __init__(self, start, end):
        self.start = start
        self.end = end


def relation(left, right, operator):
    if operator == "<":
        return left < right
    if operator == "<=":
        return left <= right
    if operator == ">":
        return left > right
    if operator == ">=":
        return left >= right
    return left == right


def fifth_sort(a):
    n = len(a)
    if n <= 1:
        return
    fifth = n // 5
    buffer_length = n - 4 * fifth
    buffer = [0] * buffer_length

    def binary_insertion(first, end):
        for i in range(first + 1, end):
            value = a[i]
            low, high = first, i
            while low < high:
                middle = low + (high - low) // 2
                if a[middle] > value:
                    high = middle
                else:
                    low = middle + 1
            for j in range(i, low, -1):
                a[j] = a[j - 1]
            a[low] = value

    def source(index, offset, from_buffer):
        return buffer[index - offset] if from_buffer else a[index]

    def merge(offset, first, middle, end, from_buffer):
        left, right = first, middle
        destination = first if from_buffer else first - offset
        while left < middle and right < end:
            if source(left, offset, from_buffer) <= source(right, offset, from_buffer):
                value = source(left, offset, from_buffer)
                left += 1
            else:
                value = source(right, offset, from_buffer)
                right += 1
            if from_buffer:
                a[destination] = value
            else:
                buffer[destination] = value
            destination += 1
        while left < middle:
            value = source(left, offset, from_buffer)
            if from_buffer:
                a[destination] = value
            else:
                buffer[destination] = value
            left += 1
            destination += 1
        while right < end:
            value = source(right, offset, from_buffer)
            if from_buffer:
                a[destination] = value
            else:
                buffer[destination] = value
            right += 1
            destination += 1

    def ping_pong(first, end):
        i = first
        while i + 8 < end:
            binary_insertion(i, i + 8)
            i += 8
        if end - i > 1:
            binary_insertion(i, end)
        length = end - first
        from_buffer = False
        gap = 8
        while gap < length:
            full = gap * 2
            i = first
            while i + full < end:
                merge(first, i, i + gap, i + full, from_buffer)
                i += full
            if i + gap < end:
                merge(first, i, i + gap, end, from_buffer)
            elif from_buffer:
                for j in range(i, end):
                    a[j] = buffer[j - first]
            else:
                for j in range(i, end):
                    buffer[j - first] = a[j]
            from_buffer = not from_buffer
            gap *= 2
        if from_buffer:
            for j in range(length):
                a[first + j] = buffer[j]

    def merge_forward(destination, first, middle, end):
        left, right = first, middle
        while left < middle and right < end:
            if a[left] <= a[right]:
                a[destination] = a[left]
                left += 1
            else:
                a[destination] = a[right]
                right += 1
            destination += 1
        while left < middle:
            a[destination] = a[left]
            destination += 1
            left += 1
        while right < end:
            a[destination] = a[right]
            destination += 1
            right += 1

    def merge_backward(destination, middle, end):
        left, right = middle - 1, end - 1
        while destination > right and right >= middle and left >= 0:
            if a[left] > a[right]:
                a[destination] = a[left]
                left -= 1
            else:
                a[destination] = a[right]
                right -= 1
            destination -= 1
        if left < 0:
            while right >= middle:
                a[destination] = a[right]
                destination -= 1
                right -= 1
        elif right == left:
            while right >= 0:
                a[destination] = a[right]
                destination -= 1
                right -= 1
        elif right < middle:
            while left >= 0:
                a[destination] = a[left]
                destination -= 1
                left -= 1
        return left + 1, right + 1

    def merge_main_prefix(destination, left_end, middle, end):
        left, right = 0, middle
        while left < left_end and right < end:
            if a[left] <= a[right]:
                a[destination] = a[left]
                left += 1
            else:
                a[destination] = a[right]
                right += 1
            destination += 1
        while left < left_end:
            a[destination] = a[left]
            destination += 1
            left += 1

    def merge_external(destination, middle, end):
        left, right = 0, middle
        while left < buffer_length and right < end:
            if buffer[left] <= a[right]:
                a[destination] = buffer[left]
                left += 1
            else:
                a[destination] = a[right]
                right += 1
            destination += 1
        while left < buffer_length:
            a[destination] = buffer[left]
            destination += 1
            left += 1

    ping_pong(0, buffer_length)
    first = buffer_length
    for _ in range(4):
        ping_pong(first, first + fifth)
        first += fifth
    for i in range(buffer_length):
        buffer[i] = a[i]
    two_fifths = 2 * fifth
    first = buffer_length
    for _ in range(2):
        merge_forward(first - buffer_length, first, first + fifth, first + two_fifths)
        first += two_fifths
    left, right = merge_backward(n - 1, two_fifths, 2 * two_fifths)
    if right > 0:
        merge_main_prefix(buffer_length, left, two_fifths, n)
    merge_external(0, buffer_length, n)


class ChaliceSortExample:
    def __init__(self, input):
        self.values = input
        self.temp = []

    def read(self, index):
        return self.values[index]

    def write(self, index, value):
        self.values[index] = value

    def swap(self, first, second):
        self.values[first], self.values[second] = (
            self.values[second],
            self.values[first],
        )

    def compare(self, first, second, predicate):
        return relation(self.values[first], self.values[second], predicate)

    def compareValues(self, first, second, predicate):
        return relation(first, second, predicate)

    def save(self, index, value):
        self.temp[index] = value

    def load(self, index):
        return self.temp[index]

    def shiftForwardExternal(self, destination, source, end):
        output = destination
        for input in range(source, end):
            self.write(output, self.read(input))
            output += 1

    def shiftBackwardExternal(self, start, sourceEnd, destinationEnd):
        input = sourceEnd
        output = destinationEnd
        while input > start:
            input -= 1
            output -= 1
            self.write(output, self.read(input))

    def rightBinarySearch(self, start, end, value):
        lower = start
        upper = end
        while lower < upper:
            middle = lower + (upper - lower) // 2
            if self.read(middle) <= value:
                lower = middle + 1
            else:
                upper = middle
        return lower

    def multiSwap(self, first, second, length):
        if not (length > 0):
            return
        for offset in range(0, length):
            self.swap(first + offset, second + offset)

    def binaryInsertion(self, start, end):
        if not (end - start > 1):
            return
        for index in range((start + 1), end):
            value = self.read(index)
            low = start
            high = index
            while low < high:
                middle = low + (high - low) // 2
                if self.read(middle) > value:
                    high = middle
                else:
                    low = middle + 1
            self.insertTo(index, low)

    def ceilCbrt(self, value):
        low = 0
        high = 11
        while low < high:
            middle = (low + high) // 2
            if (1 << (3 * middle)) >= value:
                high = middle
            else:
                low = middle + 1
        return 1 << low

    def calcKeys(self, blockLength, count):
        low = 1
        high = count // 4
        while low < high:
            middle = (low + high) // 2
            if (count - 4 * middle - 1) // blockLength - 2 < middle:
                high = middle
            else:
                low = middle + 1
        return low

    def leftBinSearch(self, startIn, endIn, value):
        start = startIn
        end = endIn
        while start < end:
            middle = start + (end - start) // 2
            if self.values[middle] >= value:
                end = middle
            else:
                start = middle + 1
        return start

    def rotate(self, start, middle, end):
        if not (start < middle and middle < end):
            return
        position = start
        leftLength = middle - start
        rightLength = end - middle
        while leftLength != 0 and rightLength != 0:
            if leftLength <= rightLength:
                for offset in range(0, leftLength):
                    self.swap(position + offset, position + leftLength + offset)
                position += leftLength
                rightLength -= leftLength
            else:
                for offset in range(0, rightLength):
                    self.swap(
                        position + leftLength - rightLength + offset,
                        position + leftLength + offset,
                    )
                leftLength -= rightLength

    def insertTo(self, source, destination):
        value = self.read(source)
        cursor = source
        while cursor > destination:
            self.write(cursor, self.read(cursor - 1))
            cursor -= 1
        self.write(destination, value)

    def shiftForward(self, destination, source, end):
        if not (source < end):
            return
        for offset in range(0, (end - source)):
            self.swap(destination + offset, source + offset)

    def shiftBackward(self, start, sourceEnd, destinationEnd):
        source = sourceEnd
        destination = destinationEnd
        while source > start:
            source -= 1
            destination -= 1
            self.swap(destination, source)

    def mergeForwardExternal(self, startIn, middle, end):
        leftLength = middle - startIn
        if not (leftLength > 0):
            return
        for offset in range(0, leftLength):
            self.save(offset, self.read(startIn + offset))
        start = startIn
        left = 0
        right = middle
        while left < leftLength and right < end:
            if self.compareValues(self.load(left), self.read(right), "<="):
                self.write(start, self.load(left))
                left += 1
            else:
                self.write(start, self.read(right))
                right += 1
            start += 1
        while left < leftLength:
            self.write(start, self.load(left))
            left += 1
            start += 1

    def mergeBackwardExternal(self, start, middle, endIn):
        rightLength = endIn - middle
        if not (rightLength > 0):
            return
        for offset in range(0, rightLength):
            self.save(offset, self.read(middle + offset))
        end = endIn
        right = rightLength - 1
        left = middle - 1
        while right >= 0 and left >= start:
            end -= 1
            if self.compareValues(self.load(right), self.read(left), ">="):
                self.write(end, self.load(right))
                right -= 1
            else:
                self.write(end, self.read(left))
                left -= 1
        while right >= 0:
            end -= 1
            self.write(end, self.load(right))
            right -= 1

    def mergeWithBufferForward(self, startIn, middle, end, destinationIn, external):
        start = startIn
        right = middle
        destination = destinationIn
        while start < middle and right < end:
            chooseLeft = self.compare(start, right, "<=")
            source = start if chooseLeft else right
            if external:
                self.write(destination, self.read(source))
            else:
                self.swap(destination, source)
            if chooseLeft:
                start += 1
            else:
                right += 1
            destination += 1
        if start > destination:
            if external:
                self.shiftForwardExternal(destination, start, middle)
            else:
                self.shiftForward(destination, start, middle)
        if external:
            self.shiftForwardExternal(destination, right, end)
        else:
            self.shiftForward(destination, right, end)

    def mergeWithBufferBackward(self, start, middle, endIn, destinationEndIn, external):
        left = middle - 1
        right = endIn - 1
        destinationEnd = destinationEndIn
        while right >= middle and left >= start:
            destinationEnd -= 1
            if self.compare(right, left, ">="):
                if external:
                    self.write(destinationEnd, self.read(right))
                else:
                    self.swap(destinationEnd, right)
                right -= 1
            else:
                if external:
                    self.write(destinationEnd, self.read(left))
                else:
                    self.swap(destinationEnd, left)
                left -= 1
        if destinationEnd > right:
            if external:
                self.shiftBackwardExternal(middle, right + 1, destinationEnd)
            else:
                self.shiftBackward(middle, right + 1, destinationEnd)
        if external:
            self.shiftBackwardExternal(start, left + 1, destinationEnd)
        else:
            self.shiftBackward(start, left + 1, destinationEnd)

    def inPlaceMerge(self, startIn, middleIn, end):
        start = startIn
        middle = middleIn
        while start < middle and middle < end:
            start = self.rightBinarySearch(start, middle, self.read(middle))
            if start == middle:
                return
            insertion = self.leftBinSearch(middle, end, self.read(start))
            self.rotate(start, middle, insertion)
            moved = insertion - middle
            middle = insertion
            start += moved + 1

    def laziestSortExternal(self, start, end):
        cursor = start
        while cursor < end:
            next = min(end, cursor + len(self.temp))
            self.binaryInsertion(cursor, next)
            if cursor > start:
                self.mergeBackwardExternal(start, cursor, next)
            cursor = next

    def findKeysSmall(self, start, end, otherStart, otherEnd, full, needed):
        first = start
        last = None
        if full:
            last = 0
            while first < end:
                location = self.leftBinSearch(otherStart, otherEnd, self.read(first))
                if location == otherEnd or not self.compare(first, location, "=="):
                    last = first + 1
                    break
                first += 1
            if last != 0:
                index = last
                while index < end and last - first < needed:
                    otherLocation = self.leftBinSearch(
                        otherStart, otherEnd, self.read(index)
                    )
                    if otherLocation == otherEnd or not self.compare(
                        index, otherLocation, "=="
                    ):
                        location = self.leftBinSearch(first, last, self.read(index))
                        if location == last or not self.compare(index, location, "=="):
                            self.rotate(first, last, index)
                            displaced = index - last
                            first += displaced
                            location += displaced
                            last = index + 1
                            self.insertTo(index, location)
                    index += 1
            else:
                last = first
        else:
            last = first + 1
            index = last
            while index < end and last - first < needed:
                location = self.leftBinSearch(first, last, self.read(index))
                if location == last or not self.compare(index, location, "=="):
                    self.rotate(first, last, index)
                    displaced = index - last
                    first += displaced
                    location += displaced
                    last = index + 1
                    self.insertTo(index, location)
                index += 1
        return KeyGroup(first, last)

    def findKeys(self, start, end, desired, stride):
        group = self.findKeysSmall(start, end, 0, 0, False, min(desired, stride))
        first = group.start
        last = group.end
        if stride < desired and last - first == stride:
            remaining = desired - stride
            while True:
                group = self.findKeysSmall(
                    last, end, first, last, True, min(stride, remaining)
                )
                found = group.end - group.start
                if found == 0:
                    break
                if found < stride or remaining == stride:
                    self.rotate(last, group.start, group.end)
                    secondStart = last
                    last += found
                    self.mergeBackwardExternal(first, secondStart, last)
                    break
                self.rotate(first, last, group.start)
                first += group.start - last
                last = group.end
                self.mergeBackwardExternal(first, group.start, last)
                remaining -= stride
        self.rotate(start, first, last)
        return last - first

    def findBitsSmall(self, start, end, referenceIn, backward, needed):
        first = start
        reference = referenceIn
        while first < end and not self.compare(
            first, reference, ("<" if backward else ">")
        ):
            first += 1
        reference += 1
        last = None
        if first < end:
            last = first + 1
            index = last
            while index < end and last - first < needed:
                if self.compare(index, reference, ("<" if backward else ">")):
                    self.rotate(first, last, index)
                    first += index - last
                    last = index + 1
                    reference += 1
                index += 1
        else:
            last = first
        return KeyGroup(first, last)

    def findBits(self, start, end, needed, stride):
        self.laziestSortExternal(start, start + needed)
        referenceStart = start
        reference = start + needed
        count = 0
        firstCount = 0
        for phase in range(0, 2):
            if count >= needed:
                continue
            first = reference
            last = first
            while True:
                group = self.findBitsSmall(
                    last,
                    end,
                    referenceStart + count,
                    phase == 1,
                    min(stride, needed - count),
                )
                found = group.end - group.start
                if found == 0:
                    break
                count += found
                if found < stride or count == needed:
                    self.rotate(last, group.start, group.end)
                    last += found
                    break
                self.rotate(first, last, group.start)
                first += group.start - last
                last = group.end
            self.rotate(reference, first, last)
            reference += last - first
            if phase == 0:
                firstCount = count
        if count < needed:
            return -1
        self.multiSwap(
            start + firstCount, start + needed + firstCount, needed - firstCount
        )
        return firstCount

    def bitReversal(self, start, end):
        length = end - start
        offset = 0
        half = length // 2
        threeQuarters = half + half // 2
        if length < 3:
            return
        for index in range(1, (length - 1)):
            jump = half
            current = index
            decrement = threeQuarters
            while current & 1 == 0:
                jump -= decrement
                current >>= 1
                decrement >>= 1
            offset += jump
            if offset > index:
                self.swap(start + index, start + offset)

    def unshuffle(self, start, end):
        remaining = (end - start) // 2
        consumed = 0
        width = 2
        while remaining > 0:
            if remaining & 1 == 1:
                position = start + consumed
                self.bitReversal(position, position + width)
                self.bitReversal(position, position + width // 2)
                self.bitReversal(position + width // 2, position + width)
                self.rotate(start + consumed // 2, position, position + width // 2)
                consumed += width
            remaining >>= 1
            width *= 2

    def redistributeBuffer(self, startIn, middleIn, end):
        start = startIn
        middle = middleIn
        size = len(self.temp)
        while middle - start > size and middle < end:
            insertion = self.leftBinSearch(middle, end, self.read(start + size))
            self.rotate(start + size, middle, insertion)
            moved = insertion - middle
            middle = insertion
            self.mergeForwardExternal(start, start + size, middle)
            start += moved + size
        if middle < end:
            self.mergeForwardExternal(start, middle, end)

    def copyMain(self, source, destination, length):
        if not (length > 0 and source != destination):
            return
        if destination > source:
            for offset in range(length - 1, 0 - 1, -1):
                self.write(destination + offset, self.read(source + offset))
        else:
            for offset in range(0, length):
                self.write(destination + offset, self.read(source + offset))

    def dualMergeBackward(self, startIn, middleIn, endIn, destinationEndIn, external):
        start = startIn
        middle = middleIn
        end = endIn - 1
        destinationEnd = destinationEndIn
        left = middle - 1
        while destinationEnd > end + 1 and end >= middle:
            destinationEnd -= 1
            if self.compare(end, left, ">="):
                if external:
                    self.write(destinationEnd, self.read(end))
                else:
                    self.swap(destinationEnd, end)
                end -= 1
            else:
                if external:
                    self.write(destinationEnd, self.read(left))
                else:
                    self.swap(destinationEnd, left)
                left -= 1
        if end < middle:
            if external:
                self.shiftBackwardExternal(start, left + 1, destinationEnd)
            else:
                self.shiftBackward(start, left + 1, destinationEnd)
        else:
            left += 1
            end += 1
            destinationEnd = middle - (left - start)
            right = middle
            while start < left and right < end:
                chooseLeft = self.compare(start, right, "<=")
                source = start if chooseLeft else right
                if external:
                    self.write(destinationEnd, self.read(source))
                else:
                    self.swap(destinationEnd, source)
                if chooseLeft:
                    start += 1
                else:
                    right += 1
                destinationEnd += 1
            while start < left:
                if external:
                    self.write(destinationEnd, self.read(start))
                else:
                    self.swap(destinationEnd, start)
                start += 1
                destinationEnd += 1

    def smartMerge(self, destinationIn, startIn, middle, reversed):
        destination = destinationIn
        start = startIn
        right = middle
        while start < middle:
            chooseLeft = (
                self.compare(start, right, "<")
                if reversed
                else self.compare(start, right, "<=")
            )
            if chooseLeft:
                self.write(destination, self.read(start))
                start += 1
            else:
                self.write(destination, self.read(right))
                right += 1
            destination += 1
        return right

    def smartTailMerge(self, destinationIn, startIn, middle, end):
        destination = destinationIn
        start = startIn
        right = middle
        blockLength = len(self.temp)
        while start < middle and right < end:
            if self.compare(start, right, "<="):
                self.write(destination, self.read(start))
                start += 1
            else:
                self.write(destination, self.read(right))
                right += 1
            destination += 1
        if start < middle:
            if start > destination:
                self.shiftForwardExternal(destination, start, middle)
            for offset in range(0, blockLength):
                self.write(end - blockLength + offset, self.load(offset))
        else:
            bufferIndex = 0
            while bufferIndex < blockLength and right < end:
                if self.compareValues(self.load(bufferIndex), self.read(right), "<="):
                    self.write(destination, self.load(bufferIndex))
                    bufferIndex += 1
                else:
                    self.write(destination, self.read(right))
                    right += 1
                destination += 1
            while bufferIndex < blockLength:
                self.write(destination, self.load(bufferIndex))
                bufferIndex += 1
                destination += 1

    def blockCycle(self, start, tagStart, sortedTags, tagCount, blockLength):
        if not (tagCount > 1):
            return
        for index in range(0, (tagCount - 1)):
            if self.compare(tagStart + index, sortedTags + index, ">") or (
                index > 0
                and self.compare(tagStart + index, sortedTags + index - 1, "<")
            ):
                self.copyMain(
                    start + index * blockLength, start - blockLength, blockLength
                )
                position = index
                next = (
                    self.leftBinSearch(
                        sortedTags, sortedTags + tagCount, self.read(tagStart + index)
                    )
                    - sortedTags
                )
                while True:
                    self.copyMain(
                        start + next * blockLength,
                        start + position * blockLength,
                        blockLength,
                    )
                    self.swap(tagStart + index, tagStart + next)
                    position = next
                    next = (
                        self.leftBinSearch(
                            sortedTags,
                            sortedTags + tagCount,
                            self.read(tagStart + index),
                        )
                        - sortedTags
                    )
                    if not (next != index):
                        break
                self.copyMain(
                    start - blockLength, start + position * blockLength, blockLength
                )

    def blockCycleEasy(self, start, tagStart, sortedTags, tagCount, blockLength):
        if not (tagCount > 1):
            return
        for index in range(0, (tagCount - 1)):
            if self.compare(tagStart + index, sortedTags + index, ">") or (
                index > 0
                and self.compare(tagStart + index, sortedTags + index - 1, "<")
            ):
                next = (
                    self.leftBinSearch(
                        sortedTags, sortedTags + tagCount, self.read(tagStart + index)
                    )
                    - sortedTags
                )
                while True:
                    self.multiSwap(
                        start + index * blockLength,
                        start + next * blockLength,
                        blockLength,
                    )
                    self.swap(tagStart + index, tagStart + next)
                    next = (
                        self.leftBinSearch(
                            sortedTags,
                            sortedTags + tagCount,
                            self.read(tagStart + index),
                        )
                        - sortedTags
                    )
                    if not (next != index):
                        break

    def inPlaceMergeBackward(self, start, middleIn, endIn, reversed):
        middle = middleIn
        end = endIn
        finalEnd = (
            self.rightBinarySearch(middle, end, self.read(middle - 1))
            if reversed
            else self.leftBinSearch(middle, end, self.read(middle - 1))
        )
        end = finalEnd
        while end > middle and middle > start:
            insertion = (
                self.leftBinSearch(start, middle, self.read(end - 1))
                if reversed
                else self.rightBinarySearch(start, middle, self.read(end - 1))
            )
            self.rotate(insertion, middle, end)
            moved = middle - insertion
            middle = insertion
            end -= moved + 1
            if middle == start:
                break
            end = (
                self.rightBinarySearch(middle, end, self.read(middle - 1))
                if reversed
                else self.leftBinSearch(middle, end, self.read(middle - 1))
            )
        return finalEnd

    def blockMerge(
        self,
        start,
        middle,
        end,
        leftTagCount,
        tagCount,
        tagStartIn,
        sortedTagsIn,
        firstBitsIn,
        secondBitsIn,
        blockLength,
    ):
        if end - middle <= blockLength:
            self.mergeBackwardExternal(start, middle, end)
            return
        self.insertTo(tagStartIn + leftTagCount - 1, tagStartIn)
        leftBlock = start + blockLength - 1
        rightBlock = middle + blockLength - 1
        leftTag = tagStartIn
        rightTag = tagStartIn + leftTagCount
        outputTag = sortedTagsIn
        firstBits = firstBitsIn
        secondBits = secondBitsIn
        while leftTag < tagStartIn + leftTagCount and rightTag < tagStartIn + tagCount:
            if self.compare(leftBlock, rightBlock, "<="):
                self.swap(outputTag, leftTag)
                outputTag += 1
                leftTag += 1
                leftBlock += blockLength
            else:
                self.swap(outputTag, rightTag)
                outputTag += 1
                rightTag += 1
                self.swap(firstBits, secondBits)
                rightBlock += blockLength
            firstBits += 1
            secondBits += 1
        while leftTag < tagStartIn + leftTagCount:
            self.swap(outputTag, leftTag)
            outputTag += 1
            leftTag += 1
            firstBits += 1
            secondBits += 1
        while rightTag < tagStartIn + tagCount:
            self.swap(outputTag, rightTag)
            outputTag += 1
            rightTag += 1
            self.swap(firstBits, secondBits)
            firstBits += 1
            secondBits += 1
        tagStart = sortedTagsIn
        sortedTags = tagStartIn
        self.heapSort(sortedTags, sortedTags + tagCount)
        for offset in range(0, blockLength):
            self.save(offset, self.read(middle - blockLength + offset))
        self.copyMain(start, middle - blockLength, blockLength)
        self.blockCycle(
            start + blockLength, tagStart, sortedTags, tagCount, blockLength
        )
        self.multiSwap(tagStart, sortedTags, tagCount)
        firstBits -= tagCount
        secondBits -= tagCount
        fragment = start + blockLength
        nextBlock = fragment
        bitsEnd = secondBits + tagCount
        reversed = self.compare(firstBits, secondBits, ">")
        while True:
            while True:
                if reversed:
                    self.swap(firstBits, secondBits)
                firstBits += 1
                secondBits += 1
                nextBlock += blockLength
                if not (
                    secondBits < bitsEnd
                    and self.compare(firstBits, secondBits, (">" if reversed else "<"))
                ):
                    break
            if secondBits == bitsEnd:
                self.smartTailMerge(
                    fragment - blockLength,
                    fragment,
                    (fragment if reversed else nextBlock),
                    end,
                )
                return
            fragment = self.smartMerge(
                fragment - blockLength, fragment, nextBlock, reversed
            )
            reversed = not reversed

    def blockMergeEasy(
        self,
        start,
        middle,
        end,
        leftTail,
        rightTail,
        leftTagCount,
        tagCount,
        tagStartIn,
        sortedTagsIn,
        firstBitsIn,
        secondBitsIn,
        blockLength,
    ):
        if end - middle <= blockLength:
            _ = self.inPlaceMergeBackward(start, middle, end, False)
            return
        dataStart = start + leftTail
        dataEnd = end - rightTail
        leftBlock = dataStart + blockLength - 1
        rightBlock = middle + blockLength - 1
        leftTag = sortedTagsIn
        rightTag = sortedTagsIn + leftTagCount
        outputTag = tagStartIn
        firstBits = firstBitsIn
        secondBits = secondBitsIn
        while (
            leftTag < sortedTagsIn + leftTagCount and rightTag < sortedTagsIn + tagCount
        ):
            if self.compare(leftBlock, rightBlock, "<="):
                self.swap(leftTag, outputTag)
                leftTag += 1
                outputTag += 1
                leftBlock += blockLength
            else:
                self.swap(rightTag, outputTag)
                rightTag += 1
                outputTag += 1
                self.swap(firstBits, secondBits)
                rightBlock += blockLength
            firstBits += 1
            secondBits += 1
        while leftTag < sortedTagsIn + leftTagCount:
            self.swap(leftTag, outputTag)
            leftTag += 1
            outputTag += 1
            firstBits += 1
            secondBits += 1
        while rightTag < sortedTagsIn + tagCount:
            self.swap(rightTag, outputTag)
            rightTag += 1
            outputTag += 1
            self.swap(firstBits, secondBits)
            firstBits += 1
            secondBits += 1
        tagStart = sortedTagsIn
        sortedTags = tagStartIn
        self.heapSort(sortedTags, sortedTags + tagCount)
        self.blockCycleEasy(dataStart, tagStart, sortedTags, tagCount, blockLength)
        self.multiSwap(tagStart, sortedTags, tagCount)
        firstBits -= tagCount
        secondBits -= tagCount
        fragment = dataStart
        nextBlock = fragment
        bitsEnd = secondBits + tagCount
        reversed = self.compare(firstBits, secondBits, ">")
        while True:
            while True:
                if reversed:
                    self.swap(firstBits, secondBits)
                firstBits += 1
                secondBits += 1
                nextBlock += blockLength
                if not (
                    secondBits < bitsEnd
                    and self.compare(firstBits, secondBits, (">" if reversed else "<"))
                ):
                    break
            if secondBits == bitsEnd:
                if not reversed:
                    _ = self.inPlaceMergeBackward(dataStart, dataEnd, end, False)
                self.inPlaceMerge(start, dataStart, end)
                return
            fragment = self.inPlaceMergeBackward(
                fragment, nextBlock, nextBlock + blockLength, reversed
            )
            reversed = not reversed

    def sift(self, start, rootIn, limit):
        root = rootIn
        while root * 2 + 1 < limit:
            child = root * 2 + 1
            if child + 1 < limit and self.compare(
                start + child, start + child + 1, "<"
            ):
                child += 1
            if not self.compare(start + root, start + child, "<"):
                return
            self.swap(start + root, start + child)
            root = child

    def heapSort(self, start, end):
        count = end - start
        if not (count > 1):
            return
        for root in range((count - 2) // 2, 0 - 1, -1):
            self.sift(start, root, count)
        for limit in range(count - 1, 1 - 1, -1):
            self.swap(start, start + limit)
            self.sift(start, 0, limit)

    def sort(
        self,
    ):
        count = len(self.values)
        start = 0
        end = count
        cubeRoot = 2 * self.ceilCbrt(count // 4)
        blockLength = 2 * cubeRoot
        keyLength = self.calcKeys(blockLength, count)
        self.temp = [0] * blockLength
        keys = self.findKeys(start, end, 2 * keyLength, cubeRoot)
        if keys < 8:
            runLength = 1
            while runLength < count:
                middle = start + runLength
                while middle < end:
                    _ = self.inPlaceMergeBackward(
                        middle - runLength, middle, min(middle + runLength, end), False
                    )
                    middle += 2 * runLength
                runLength *= 2
            return
        if keys < 2 * keyLength:
            keys -= keys % 4
            keyLength = keys // 2
        keyEnd = start + keys
        bitEnd = keyEnd + keys
        bitSeparation = self.findBits(keyEnd, end, keyLength, cubeRoot)
        if bitSeparation == -1:
            self.laziestSortExternal(start, bitEnd)
            self.inPlaceMerge(start, bitEnd, end)
            return
        dataStart = bitEnd + blockLength
        dataLength = end - dataStart
        self.binaryInsertion(bitEnd, dataStart)
        for offset in range(0, blockLength):
            self.save(offset, self.read(bitEnd + offset))
        runLength = 1
        while runLength < cubeRoot:
            vacant = max(2, runLength)
            index = dataStart
            while index + 2 * runLength < end:
                self.mergeWithBufferForward(
                    index,
                    index + runLength,
                    index + 2 * runLength,
                    index - vacant,
                    True,
                )
                index += 2 * runLength
            if index + runLength < end:
                self.mergeWithBufferForward(
                    index, index + runLength, end, index - vacant, True
                )
            else:
                self.shiftForwardExternal(index - vacant, index, end)
            dataStart -= vacant
            end -= vacant
            runLength *= 2
        index = end - dataLength % (2 * runLength)
        if index + runLength < end:
            self.mergeWithBufferBackward(
                index, index + runLength, end, end + runLength, True
            )
        else:
            self.shiftBackwardExternal(index, end, end + runLength)
        index -= 2 * runLength
        while index >= dataStart:
            self.mergeWithBufferBackward(
                index,
                index + runLength,
                index + 2 * runLength,
                index + 3 * runLength,
                True,
            )
            index -= 2 * runLength
        dataStart += runLength
        end += runLength
        runLength *= 2
        index = dataStart
        while index + 2 * runLength < end:
            self.mergeWithBufferForward(
                index, index + runLength, index + 2 * runLength, index - runLength, True
            )
            index += 2 * runLength
        if index + runLength < end:
            self.mergeWithBufferForward(
                index, index + runLength, end, index - runLength, True
            )
        else:
            self.shiftForwardExternal(index - runLength, index, end)
        dataStart -= runLength
        end -= runLength
        runLength *= 2
        index = end - dataLength % (2 * runLength)
        if index + runLength < end:
            self.dualMergeBackward(
                index, index + runLength, end, end + runLength // 2, True
            )
        else:
            self.shiftBackwardExternal(index, end, end + runLength // 2)
        index -= 2 * runLength
        while index >= dataStart:
            self.dualMergeBackward(
                index,
                index + runLength,
                index + 2 * runLength,
                index + 2 * runLength + runLength // 2,
                True,
            )
            index -= 2 * runLength
        dataStart += runLength // 2
        end += runLength // 2
        runLength *= 2
        if keys >= runLength:
            self.rotate(start, keyEnd, dataStart)
            bitEnd = keyEnd + blockLength
            if keyLength >= runLength:
                minimumLevel = 2 * runLength
                while runLength < keyLength:
                    vacant = max(minimumLevel, runLength)
                    index = dataStart
                    while index + 2 * runLength < end:
                        self.mergeWithBufferForward(
                            index,
                            index + runLength,
                            index + 2 * runLength,
                            index - vacant,
                            False,
                        )
                        index += 2 * runLength
                    if index + runLength < end:
                        self.mergeWithBufferForward(
                            index, index + runLength, end, index - vacant, False
                        )
                    else:
                        self.shiftForward(index - vacant, index, end)
                    dataStart -= vacant
                    end -= vacant
                    runLength *= 2
                index = end - dataLength % (2 * runLength)
                if index + runLength < end:
                    self.mergeWithBufferBackward(
                        index, index + runLength, end, end + runLength, False
                    )
                else:
                    self.shiftBackward(index, end, end + runLength)
                index -= 2 * runLength
                while index >= dataStart:
                    self.mergeWithBufferBackward(
                        index,
                        index + runLength,
                        index + 2 * runLength,
                        index + 3 * runLength,
                        False,
                    )
                    index -= 2 * runLength
                dataStart += runLength
                end += runLength
                runLength *= 2
            if keys >= runLength:
                index = dataStart
                while index + 2 * runLength < end:
                    self.mergeWithBufferForward(
                        index,
                        index + runLength,
                        index + 2 * runLength,
                        index - runLength,
                        False,
                    )
                    index += 2 * runLength
                if index + runLength < end:
                    self.mergeWithBufferForward(
                        index, index + runLength, end, index - runLength, False
                    )
                else:
                    self.shiftForward(index - runLength, index, end)
                dataStart -= runLength
                end -= runLength
                runLength *= 2
                index = end - dataLength % (2 * runLength)
                if index + runLength < end:
                    self.dualMergeBackward(
                        index, index + runLength, end, end + runLength // 2, False
                    )
                else:
                    self.shiftBackward(index, end, end + runLength // 2)
                index -= 2 * runLength
                while index >= dataStart:
                    self.dualMergeBackward(
                        index,
                        index + runLength,
                        index + 2 * runLength,
                        index + 2 * runLength + runLength // 2,
                        False,
                    )
                    index -= 2 * runLength
                dataStart += runLength // 2
                end += runLength // 2
                runLength *= 2
            self.rotate(start, bitEnd, dataStart)
            bitEnd = keyEnd + keys
            self.heapSort(start, keyEnd)
        for offset in range(0, blockLength):
            self.write(bitEnd + offset, self.load(offset))
        self.unshuffle(start, keyEnd)
        limit = blockLength * (keyLength + 2)
        tagCount = runLength // blockLength - 1
        while runLength < dataLength and min(2 * runLength, dataLength) <= limit:
            index = dataStart
            while index + 2 * runLength <= end:
                self.blockMerge(
                    index,
                    index + runLength,
                    index + 2 * runLength,
                    tagCount,
                    2 * tagCount,
                    start,
                    start + keyLength,
                    keyEnd,
                    keyEnd + keyLength,
                    blockLength,
                )
                index += 2 * runLength
            if index + runLength < end:
                self.blockMerge(
                    index,
                    index + runLength,
                    end,
                    tagCount,
                    (end - index - 1) // blockLength - 1,
                    start,
                    start + keyLength,
                    keyEnd,
                    keyEnd + keyLength,
                    blockLength,
                )
            runLength *= 2
            tagCount = 2 * tagCount + 1
        while runLength < dataLength:
            blockLength = 2 * runLength // keyLength
            leftTail = runLength % blockLength
            index = dataStart
            while index + 2 * runLength <= end:
                self.blockMergeEasy(
                    index,
                    index + runLength,
                    index + 2 * runLength,
                    leftTail,
                    leftTail,
                    keyLength // 2,
                    keyLength,
                    start,
                    start + keyLength,
                    keyEnd,
                    keyEnd + keyLength,
                    blockLength,
                )
                index += 2 * runLength
            if index + runLength < end:
                self.blockMergeEasy(
                    index,
                    index + runLength,
                    end,
                    leftTail,
                    (end - index - runLength) % blockLength,
                    keyLength // 2,
                    keyLength // 2 + (end - index - runLength) // blockLength,
                    start,
                    start + keyLength,
                    keyEnd,
                    keyEnd + keyLength,
                    blockLength,
                )
            runLength *= 2
        self.multiSwap(
            keyEnd + bitSeparation,
            keyEnd + keyLength + bitSeparation,
            keyLength - bitSeparation,
        )
        self.laziestSortExternal(start, dataStart)
        self.redistributeBuffer(start, dataStart, end)


def sort(values):
    if 32 <= len(values) < 128:
        fifth_sort(values)
    else:
        sorter = ChaliceSortExample(values)
        if len(values) < 32:
            sorter.binaryInsertion(0, len(values))
        else:
            sorter.sort()


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
