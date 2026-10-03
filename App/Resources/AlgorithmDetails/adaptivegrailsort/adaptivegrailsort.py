# MIT License
# Copyright (c) 2013 Andrey Astrelin
# Copyright (c) 2020 The Holy Grail Sort Project
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


class AdaptiveGrailExample:
    minRun = 16

    def __init__(self, input):
        self.values = input
        self.minRun = 16

    def read(self, index):
        return self.values[index]

    def write(self, index, value):
        self.values[index] = value

    def swap(self, first, second):
        self.values[first], self.values[second] = (
            self.values[second],
            self.values[first],
        )

    def compare(self, first, second):
        if self.values[first] < self.values[second]:
            return -1
        if self.values[first] > self.values[second]:
            return 1
        return 0

    def compareValue(self, index, value):
        if self.values[index] < value:
            return -1
        if self.values[index] > value:
            return 1
        return 0

    def reverse(self, start, end):
        left = start
        right = end - 1
        while left < right:
            self.values[left], self.values[right] = (
                self.values[right],
                self.values[left],
            )
            left += 1
            right -= 1

    def multiSwap(self, first, second, count):
        if not (count > 0):
            return
        for offset in range(0, count):
            self.swap(first + offset, second + offset)

    def multiTriSwap(self, first, second, third, count):
        if not (count > 0):
            return
        for offset in range(0, count):
            value = self.read(first + offset)
            self.write(first + offset, self.read(second + offset))
            self.write(second + offset, self.read(third + offset))
            self.write(third + offset, value)

    def insertTo(self, source, destination):
        value = self.read(source)
        cursor = source
        while cursor > destination:
            self.write(cursor, self.read(cursor - 1))
            cursor -= 1
        self.write(destination, value)

    def insertToBackward(self, source, destination):
        value = self.read(source)
        cursor = source
        while cursor < destination:
            self.write(cursor, self.read(cursor + 1))
            cursor += 1
        self.write(cursor, value)

    def shift(self, destination, source, end):
        if not (source < end):
            return
        for offset in range(0, (end - source)):
            self.swap(destination + offset, source + offset)

    def rotate(self, startIn, middleIn, endIn):
        start = startIn
        middle = middleIn
        end = endIn
        left = middle - start
        right = end - middle
        while left > 1 and right > 1:
            if right < left:
                self.multiSwap(middle - right, middle, right)
                end -= right
                middle -= right
                left -= right
            else:
                self.multiSwap(start, middle, left)
                start += left
                middle += left
                right -= left
        if right == 1:
            self.insertTo(middle, start)
        elif left == 1:
            self.insertToBackward(start, end - 1)

    def leftBinarySearch(self, start, end, value):
        lower = start
        upper = end
        while lower < upper:
            middle = lower + (upper - lower) // 2
            if self.values[middle] >= value:
                upper = middle
            else:
                lower = middle + 1
        return lower

    def rightBinarySearch(self, start, end, value):
        lower = start
        upper = end
        while lower < upper:
            middle = lower + (upper - lower) // 2
            if self.values[middle] > value:
                upper = middle
            else:
                lower = middle + 1
        return lower

    def buildUniqueRun(self, start, limit):
        count = 1
        index = start + 1
        order = self.compare(index - 1, index)
        if order < 0:
            index += 1
            count += 1
            while count < limit and self.compare(index - 1, index) < 0:
                index += 1
                count += 1
        elif order > 0:
            index += 1
            count += 1
            while count < limit and self.compare(index - 1, index) > 0:
                index += 1
                count += 1
            self.reverse(start, index)
        return count

    def buildUniqueRunBackward(self, end, limit):
        count = 1
        index = end - 1
        order = self.compare(index - 1, index)
        if order < 0:
            index -= 1
            count += 1
            while count < limit and self.compare(index - 1, index) < 0:
                index -= 1
                count += 1
        elif order > 0:
            index -= 1
            count += 1
            while count < limit and self.compare(index - 1, index) > 0:
                index -= 1
                count += 1
            self.reverse(index, end)
        return count

    def findKeys(self, start, end, initial, needed):
        count = initial
        keyStart = start
        keyEnd = start + count
        index = keyEnd
        while index < end and count < needed:
            candidate = self.read(index)
            location = self.leftBinarySearch(keyStart, keyEnd, candidate)
            if location == keyEnd or self.compareValue(location, candidate) != 0:
                self.rotate(keyStart, keyEnd, index)
                distance = index - keyEnd
                location += distance
                keyStart += distance
                keyEnd += distance
                self.insertTo(keyEnd, location)
                count += 1
                keyEnd += 1
            index += 1
        self.rotate(start, keyStart, keyEnd)
        return count

    def findKeysBackward(self, start, end, initial, needed):
        count = initial
        keyStart = end - count
        keyEnd = end
        index = keyStart - 1
        while index >= start and count < needed:
            candidate = self.read(index)
            location = self.leftBinarySearch(keyStart, keyEnd, candidate)
            if location == keyEnd or self.compareValue(location, candidate) != 0:
                self.rotate(index + 1, keyStart, keyEnd)
                distance = keyStart - (index + 1)
                location -= distance
                keyEnd -= distance
                keyStart -= distance + 1
                count += 1
                self.insertToBackward(index, location - 1)
            index -= 1
        self.rotate(keyStart, keyEnd, end)
        return count

    def buildRuns(self, start, end):
        index = start + 1
        runStart = start
        while index < end:
            if self.compare(index - 1, index) > 0:
                index += 1
                while index < end and self.compare(index - 1, index) > 0:
                    index += 1
                self.reverse(runStart, index)
            else:
                index += 1
                while index < end and self.compare(index - 1, index) <= 0:
                    index += 1
            if index < end:
                runStart = index - (index - runStart - 1) % self.minRun - 1
            while index - runStart < self.minRun and index < end:
                self.insertTo(
                    index, self.rightBinarySearch(runStart, index, self.read(index))
                )
                index += 1
            runStart = index
            index += 1

    def binaryInsertion(self, start, end):
        if not (end - start > 1):
            return
        for index in range((start + 1), end):
            self.insertTo(index, self.rightBinarySearch(start, index, self.read(index)))

    def mergeWithBufferRest(self, start, middle, end, buffer, length):
        left = 0
        right = middle
        output = start
        while left < length and right < end:
            if self.compare(buffer + left, right) <= 0:
                self.swap(output, buffer + left)
                left += 1
            else:
                self.swap(output, right)
                right += 1
            output += 1
        while left < length:
            self.swap(output, buffer + left)
            output += 1
            left += 1

    def mergeWithBuffer(self, start, middle, end, buffer):
        length = middle - start
        self.multiSwap(buffer, start, length)
        self.mergeWithBufferRest(start, middle, end, buffer, length)

    def mergeWithBufferBackward(self, start, middle, end, buffer):
        length = end - middle
        self.multiSwap(middle, buffer, length)
        left = length - 1
        right = middle - 1
        output = end - 1
        while left >= 0 and right >= start:
            if self.compare(buffer + left, right) >= 0:
                self.swap(output, buffer + left)
                left -= 1
            else:
                self.swap(output, right)
                right -= 1
            output -= 1
        while left >= 0:
            self.swap(output, buffer + left)
            output -= 1
            left -= 1

    def inPlaceMerge(self, start, middle, end):
        left = start
        right = middle
        while left < right and right < end:
            if self.compare(left, right) > 0:
                next = self.leftBinarySearch(right + 1, end, self.read(left))
                self.rotate(left, right, next)
                left += next - right
                right = next
            else:
                left += 1

    def inPlaceMergeBackward(self, start, middle, end):
        left = middle - 1
        right = end - 1
        while right > left and left >= start:
            if self.compare(left, right) > 0:
                next = self.rightBinarySearch(start, left, self.read(right))
                self.rotate(next, left + 1, right + 1)
                right -= (left + 1) - next
                left = next - 1
            else:
                right -= 1

    def mergeWithoutBuffer(self, start, middle, end):
        if middle - start > end - middle:
            self.inPlaceMergeBackward(start, middle, end)
        else:
            self.inPlaceMerge(start, middle, end)

    def checkSorted(self, middle):
        return self.compare(middle - 1, middle) > 0

    def checkReverseBounds(self, start, middle, end):
        if self.compare(start, end - 1) > 0:
            self.rotate(start, middle, end)
            return False
        return True

    def checkBounds(self, start, middle, end):
        return self.checkSorted(middle) and self.checkReverseBounds(start, middle, end)

    def subarray(self, tag, middleKey):
        return "left" if self.compare(tag, middleKey) < 0 else "right"

    def blockSelectSort(
        self, position, tags, offset, distance, leftCount, blockCount, blockLength
    ):
        middleKey = leftCount
        index = 0
        limit = leftCount + 1
        while index < limit - 1:
            minimum = index
            candidate = max(leftCount - offset, index + 1)
            while candidate < limit:
                order = self.compare(
                    position + distance + candidate * blockLength,
                    position + distance + minimum * blockLength,
                )
                if order < 0 or (
                    order == 0 and self.compare(tags + candidate, tags + minimum) < 0
                ):
                    minimum = candidate
                candidate += 1
            if minimum != index:
                self.multiSwap(
                    position + index * blockLength,
                    position + minimum * blockLength,
                    blockLength,
                )
                self.swap(tags + index, tags + minimum)
                if limit < blockCount and minimum == limit - 1:
                    limit += 1
            if minimum == middleKey:
                middleKey = index
            index += 1
        return tags + middleKey

    def sortKeys(self, end, buffer, middleKey):
        self.swap(buffer, middleKey)
        left = middleKey
        index = left + 1
        right = buffer + 1
        while index < end:
            if self.compare(index, buffer) < 0:
                self.swap(left, index)
                left += 1
            else:
                self.swap(right, index)
                right += 1
            index += 1
        self.multiSwap(left, buffer, end - left)

    def sortKeysWithoutBuffer(self, end, middleKey):
        left = middleKey
        index = left + 1
        while index < end:
            if self.compare(index, left) < 0:
                self.insertTo(index, left)
                left += 1
            index += 1

    def mergeBlocks(self, start, middle, end, destination, reverseEqual):
        left = start
        right = middle
        output = destination
        while left < middle and right < end:
            order = self.compare(left, right)
            if order < 0 or (order == 0 and not reverseEqual):
                self.swap(output, left)
                left += 1
            else:
                self.swap(output, right)
                right += 1
            output += 1
        if left > output:
            while left < middle:
                self.swap(output, left)
                output += 1
                left += 1
        return right

    def blockMerge(self, start, middle, end, tags, buffer, blockLength):
        lastFull = end - (end - middle - 1) % blockLength - 1
        left = start + blockLength
        group = start
        key = tags - 1
        leftCount = (middle - left) // blockLength
        blockCount = (lastFull - left) // blockLength
        leftBlocks = -1
        rightBlocks = leftCount - 1
        self.multiTriSwap(buffer, middle - blockLength, start, blockLength)
        self.insertToBackward(tags, tags + leftCount - 1)
        middleKey = self.blockSelectSort(
            left, tags, 1, blockLength - 1, leftCount, blockCount, blockLength
        )
        fragment = "left"
        while leftBlocks < leftCount and rightBlocks < blockCount:
            if fragment == "left":
                while True:
                    group += blockLength
                    leftBlocks += 1
                    key += 1
                    if not (
                        leftBlocks < leftCount
                        and self.subarray(key, middleKey) == "left"
                    ):
                        break
                if leftBlocks == leftCount:
                    left = self.mergeBlocks(left, group, end, left - blockLength, False)
                    self.mergeWithBufferRest(
                        left - blockLength, left, end, buffer, blockLength
                    )
                else:
                    left = self.mergeBlocks(
                        left, group, group + blockLength - 1, left - blockLength, False
                    )
                fragment = "right"
            else:
                while True:
                    group += blockLength
                    rightBlocks += 1
                    key += 1
                    if not (
                        rightBlocks < blockCount
                        and self.subarray(key, middleKey) == "right"
                    ):
                        break
                if rightBlocks == blockCount:
                    self.shift(left - blockLength, left, end)
                    self.multiSwap(buffer, end - blockLength, blockLength)
                else:
                    left = self.mergeBlocks(
                        left, group, group + blockLength - 1, left - blockLength, True
                    )
                fragment = "left"
        self.sortKeys(tags + blockCount, buffer, middleKey)

    def blockMergeWithoutBuffer(self, start, middle, end, tags, blockLength):
        firstFull = start + (middle - start) % blockLength
        lastFull = end - (end - middle) % blockLength
        left = start
        group = firstFull
        key = tags
        leftCount = (middle - group) // blockLength + 1
        blockCount = (lastFull - group) // blockLength + 1
        leftBlocks = 0
        rightBlocks = leftCount
        middleKey = self.blockSelectSort(
            group, tags, 0, 0, leftCount - 1, blockCount - 1, blockLength
        )
        fragment = "left"
        while leftBlocks < leftCount and rightBlocks < blockCount:
            next = self.subarray(key, middleKey)
            key += 1
            if next == fragment:
                if fragment == "left":
                    leftBlocks += 1
                else:
                    rightBlocks += 1
                left = group
            else:
                middle2 = group
                end2 = group + blockLength
                if fragment == "left":
                    while left < middle2 and middle2 < end2:
                        if self.compare(left, middle2) > 0:
                            nextPosition = self.leftBinarySearch(
                                middle2 + 1, end2, self.read(left)
                            )
                            self.rotate(left, middle2, nextPosition)
                            left += nextPosition - middle2
                            middle2 = nextPosition
                        else:
                            left += 1
                else:
                    while left < middle2 and middle2 < end2:
                        if self.compare(left, middle2) >= 0:
                            nextPosition = self.rightBinarySearch(
                                middle2 + 1, end2, self.read(left)
                            )
                            self.rotate(left, middle2, nextPosition)
                            left += nextPosition - middle2
                            middle2 = nextPosition
                        else:
                            left += 1
                if left < middle2:
                    if next == "left":
                        leftBlocks += 1
                    else:
                        rightBlocks += 1
                else:
                    if fragment == "left":
                        leftBlocks += 1
                    else:
                        rightBlocks += 1
                    fragment = next
            group += blockLength
        if leftBlocks < leftCount:
            self.inPlaceMergeBackward(start, lastFull, end)
        self.sortKeysWithoutBuffer(tags + blockCount - 1, middleKey)

    def smartMerge(self, start, middle, end, buffer):
        if self.checkBounds(start, middle, end):
            trimmed = self.rightBinarySearch(start, middle - 1, self.read(middle))
            self.mergeWithBuffer(trimmed, middle, end, buffer)

    def smartMergeBackward(self, start, middle, end, buffer):
        if self.checkBounds(start, middle, end):
            trimmed = self.leftBinarySearch(middle + 1, end, self.read(middle - 1))
            self.mergeWithBufferBackward(start, middle, trimmed, buffer)

    def smartBlockMerge(self, start, middle, end, tags, buffer, blockLength):
        if self.checkBounds(start, middle, end):
            trimmedStart = self.rightBinarySearch(start, middle - 1, self.read(middle))
            trimmedEnd = self.leftBinarySearch(middle + 1, end, self.read(middle - 1))
            if self.checkReverseBounds(trimmedStart, middle, trimmedEnd):
                if (
                    middle - trimmedStart <= blockLength
                    or trimmedEnd - middle <= blockLength
                ):
                    if trimmedEnd - middle < middle - trimmedStart:
                        self.mergeWithBufferBackward(
                            trimmedStart, middle, trimmedEnd, buffer
                        )
                    else:
                        self.mergeWithBuffer(trimmedStart, middle, trimmedEnd, buffer)
                else:
                    trimmedStart -= (trimmedStart - start) % blockLength
                    self.blockMerge(
                        trimmedStart, middle, trimmedEnd, tags, buffer, blockLength
                    )

    def smartBlockMergeWithoutBuffer(self, start, middle, end, tags, blockLength):
        if self.checkBounds(start, middle, end):
            trimmedStart = self.rightBinarySearch(start, middle - 1, self.read(middle))
            if middle - trimmedStart <= blockLength:
                self.inPlaceMerge(trimmedStart, middle, end)
            else:
                self.blockMergeWithoutBuffer(
                    trimmedStart, middle, end, tags, blockLength
                )

    def smartInPlaceMerge(self, start, middle, end):
        if self.checkSorted(middle):
            self.inPlaceMergeBackward(start, middle, end)

    def redistributeBuffer(self, startIn, middleIn, end):
        start = startIn
        middle = middleIn
        right = self.leftBinarySearch(middle, end, self.read(start))
        self.rotate(start, middle, right)
        distance = right - middle
        start += distance
        middle += distance
        leftMiddle = start + (middle - start) // 2
        right = self.leftBinarySearch(middle, end, self.read(leftMiddle))
        self.rotate(leftMiddle, middle, right)
        distance = right - middle
        leftMiddle += distance
        middle += distance
        self.mergeWithoutBuffer(start, leftMiddle - distance, leftMiddle)
        self.mergeWithoutBuffer(leftMiddle, middle, end)

    def redistributeBufferBackward(self, start, middleIn, endIn):
        middle = middleIn
        end = endIn
        right = self.rightBinarySearch(start, middle, self.read(end - 1))
        self.rotate(right, middle, end)
        distance = middle - right
        end -= distance
        middle -= distance
        rightMiddle = middle + (end - middle) // 2
        right = self.rightBinarySearch(start, middle, self.read(rightMiddle - 1))
        self.rotate(right, middle, rightMiddle)
        distance = middle - right
        rightMiddle -= distance
        middle -= distance
        self.mergeWithoutBuffer(rightMiddle, rightMiddle + distance, end)
        self.mergeWithoutBuffer(start, middle, rightMiddle)

    def inPlaceMergeSort(self, start, end):
        self.buildRuns(start, end)
        run = self.minRun
        while run < end - start:
            index = start
            while index + 2 * run <= end:
                self.smartInPlaceMerge(index, index + run, index + 2 * run)
                index += 2 * run
            if index + run < end:
                self.smartInPlaceMerge(index, index + run, end)
            run *= 2

    def adaptiveSortWithoutBuffer(self, startIn, endIn, keys, ideal, backwardBuffer):
        start = startIn
        end = endIn
        length = end - start
        blockLength = min(keys, self.minRun)
        while 2 * blockLength <= keys:
            blockLength *= 2
        tagLength = keys - blockLength
        runLength = self.minRun
        tags = None
        buffer = None
        dataStart = None
        dataEnd = None
        if backwardBuffer:
            buffer = end - blockLength
            dataStart = start
            dataEnd = buffer - tagLength
            tags = dataEnd
        else:
            buffer = start + tagLength
            dataStart = buffer + blockLength
            dataEnd = end
            tags = start
        self.buildRuns(dataStart, dataEnd)
        while runLength <= blockLength and runLength < length:
            index = dataStart
            while index + 2 * runLength <= dataEnd:
                self.smartMerge(index, index + runLength, index + 2 * runLength, buffer)
                index += 2 * runLength
            if index + runLength < dataEnd:
                self.smartMergeBackward(index, index + runLength, dataEnd, buffer)
            runLength *= 2
        if blockLength // 2 >= self.minRun and blockLength // 2 >= (keys + 1) // 2:
            self.binaryInsertion(buffer, buffer + blockLength)
            blockLength //= 2
            tagLength = keys - blockLength
            buffer += blockLength
        while tagLength >= 2 * runLength // blockLength - 1 and runLength < length:
            index = dataStart
            while index + 2 * runLength <= dataEnd:
                self.smartBlockMerge(
                    index,
                    index + runLength,
                    index + 2 * runLength,
                    tags,
                    buffer,
                    blockLength,
                )
                index += 2 * runLength
            if index + runLength < dataEnd:
                if dataEnd - (index + runLength) > blockLength:
                    self.smartBlockMerge(
                        index, index + runLength, dataEnd, tags, buffer, blockLength
                    )
                else:
                    self.smartMergeBackward(index, index + runLength, dataEnd, buffer)
            runLength *= 2
        self.binaryInsertion(buffer, buffer + blockLength)
        tagLength = keys - keys % 2
        while runLength < length:
            blockLength = (2 * runLength + tagLength - 1) // tagLength
            index = dataStart
            while index + 2 * runLength <= dataEnd:
                self.smartBlockMergeWithoutBuffer(
                    index, index + runLength, index + 2 * runLength, tags, blockLength
                )
                index += 2 * runLength
            if index + runLength < dataEnd:
                if dataEnd - (index + runLength) > blockLength:
                    self.smartBlockMergeWithoutBuffer(
                        index, index + runLength, dataEnd, tags, blockLength
                    )
                else:
                    self.smartInPlaceMerge(index, index + runLength, dataEnd)
            runLength *= 2
        if backwardBuffer:
            start = self.rightBinarySearch(start, dataEnd, self.read(dataEnd))
            if keys >= ideal // 2:
                self.redistributeBufferBackward(start, dataEnd, end)
            else:
                self.mergeWithoutBuffer(start, dataEnd, end)
        else:
            end = self.leftBinarySearch(dataStart, end, self.read(dataStart - 1))
            if keys >= ideal // 2:
                self.redistributeBuffer(start, dataStart, end)
            else:
                self.mergeWithoutBuffer(start, dataStart, end)

    def sort(self, startIn, endIn):
        start = startIn
        end = endIn
        length = end - start
        if length < 31:
            self.binaryInsertion(start, end)
            return
        if length < 63:
            self.minRun = (length + 1) // 2
            self.buildRuns(start, end)
            middle = start + self.minRun
            if self.checkBounds(start, middle, end):
                self.redistributeBufferBackward(start, middle, end)
            return
        self.minRun = length
        while self.minRun >= 32:
            self.minRun = (self.minRun + 1) // 2
        blockLength = self.minRun
        while blockLength * blockLength < length:
            blockLength *= 2
        tagLength = length // blockLength - 2
        ideal = tagLength + blockLength
        rightRun = self.buildUniqueRunBackward(end, ideal)
        leftRun = 0
        backwardBuffer = None
        if rightRun == ideal:
            backwardBuffer = True
        else:
            leftRun = self.buildUniqueRun(start, ideal)
            if leftRun == ideal:
                backwardBuffer = False
            else:
                backwardBuffer = (rightRun < 16 and leftRun < 16) or rightRun >= leftRun
        keys = (
            self.findKeysBackward(start, end, rightRun, ideal)
            if backwardBuffer
            else self.findKeys(start, end, leftRun, ideal)
        )
        if keys < ideal:
            if keys == 1:
                return
            if keys <= 4:
                self.inPlaceMergeSort(start, end)
            else:
                self.adaptiveSortWithoutBuffer(start, end, keys, ideal, backwardBuffer)
            return
        buffer = None
        dataStart = None
        dataEnd = None
        tags = None
        if backwardBuffer:
            buffer = end - blockLength
            dataStart = start
            dataEnd = buffer - tagLength
            tags = dataEnd
        else:
            buffer = start + tagLength
            dataStart = buffer + blockLength
            dataEnd = end
            tags = start
        self.buildRuns(dataStart, dataEnd)
        runLength = self.minRun
        while runLength <= blockLength and runLength < length:
            index = dataStart
            while index + 2 * runLength <= dataEnd:
                self.smartMerge(index, index + runLength, index + 2 * runLength, buffer)
                index += 2 * runLength
            if index + runLength < dataEnd:
                self.smartMergeBackward(index, index + runLength, dataEnd, buffer)
            runLength *= 2
        while runLength < length:
            index = dataStart
            while index + 2 * runLength <= dataEnd:
                self.smartBlockMerge(
                    index,
                    index + runLength,
                    index + 2 * runLength,
                    tags,
                    buffer,
                    blockLength,
                )
                index += 2 * runLength
            if index + runLength < dataEnd:
                if dataEnd - (index + runLength) > blockLength:
                    self.smartBlockMerge(
                        index, index + runLength, dataEnd, tags, buffer, blockLength
                    )
                else:
                    self.smartMergeBackward(index, index + runLength, dataEnd, buffer)
            runLength *= 2
        self.binaryInsertion(buffer, buffer + blockLength)
        if backwardBuffer:
            start = self.rightBinarySearch(start, dataEnd, self.read(dataEnd))
            self.redistributeBufferBackward(start, dataEnd, end)
        else:
            end = self.leftBinarySearch(dataStart, end, self.read(dataStart - 1))
            self.redistributeBuffer(start, dataStart, end)


def sort(values):
    sorter = AdaptiveGrailExample(values)
    sorter.sort(0, len(values))


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
