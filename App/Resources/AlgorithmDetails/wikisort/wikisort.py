# The WikiSorting source is released to the public domain under the Unlicense.

import math
import builtins

class WikiRange:
    def __init__(self, start=0, end=0):
        self.start = start
        self.end = end
    @property
    def length(self):
        return self.end - self.start
    def set(self, start, end):
        self.start, self.end = start, end
    def copy(self):
        return WikiRange(self.start, self.end)

class WikiPull:
    def __init__(self, from_=0, to=0, count=0, range=None):
        self.from_ = from_
        self.to = to
        self.count = count
        self.range = WikiRange() if range is None else range

class WikiIterator:
    def __init__(self, size):
        self.size = size
        self.denominator = (1 << (size.bit_length() - 1)) // 4
        self.numeratorStep = size % self.denominator
        self.decimalStep = size // self.denominator
        self.numerator = 0
        self.decimal = 0
    def begin(self):
        self.numerator = 0
        self.decimal = 0
    def nextRange(self):
        start = self.decimal
        self.decimal += self.decimalStep
        self.numerator += self.numeratorStep
        if self.numerator >= self.denominator:
            self.numerator -= self.denominator
            self.decimal += 1
        return WikiRange(start, self.decimal)
    @property
    def finished(self):
        return self.decimal >= self.size
    def nextLevel(self):
        self.decimalStep += self.decimalStep
        self.numeratorStep += self.numeratorStep
        if self.numeratorStep >= self.denominator:
            self.numeratorStep -= self.denominator
            self.decimalStep += 1
        return self.decimalStep < self.size
    @property
    def length(self):
        return self.decimalStep

class WikiSortExample:
    def __init__(self, input):
        self.values = input
    def read(self, index):
        return self.values[index]
    def less(self, left, right):
        return self.values[left] < self.values[right]
    def lessValues(self, left, right):
        return left < right
    def greaterValues(self, left, right):
        return left > right
    def swap(self, left, right):
        self.values[left], self.values[right] = self.values[right], self.values[left]
    def binaryFirst(self, value, range):
        start = range.start
        end = range.end
        while start < end:
            middle = start + (end - start) // 2
            if self.values[middle] < value:
                start = middle + 1
            else:
                end = middle
        return start
    def binaryLast(self, value, range):
        start = range.start
        end = range.end
        while start < end:
            middle = start + (end - start) // 2
            if self.values[middle] <= value:
                start = middle + 1
            else:
                end = middle
        return start
    def findFirstForward(self, value, range, unique):
        if not (range.length > 0):
            return range.start
        skip = max(range.length // max(unique, 1), 1)
        index = range.start + skip
        while self.values[index - 1] < value:
            if index >= range.end - skip:
                return self.binaryFirst(value, WikiRange(index, range.end))
            index += skip
        return self.binaryFirst(value, WikiRange(index - skip, index))
    def findLastForward(self, value, range, unique):
        if not (range.length > 0):
            return range.start
        skip = max(range.length // max(unique, 1), 1)
        index = range.start + skip
        while self.values[index - 1] <= value:
            if index >= range.end - skip:
                return self.binaryLast(value, WikiRange(index, range.end))
            index += skip
        return self.binaryLast(value, WikiRange(index - skip, index))
    def findFirstBackward(self, value, range, unique):
        if not (range.length > 0):
            return range.start
        skip = max(range.length // max(unique, 1), 1)
        index = range.end - skip
        while index > range.start  and  self.values[index - 1] >= value:
            if index < range.start + skip:
                return self.binaryFirst(value, WikiRange(range.start, index))
            index -= skip
        return self.binaryFirst(value, WikiRange(index, index + skip))
    def findLastBackward(self, value, range, unique):
        if not (range.length > 0):
            return range.start
        skip = max(range.length // max(unique, 1), 1)
        index = range.end - skip
        while index > range.start  and  self.values[index - 1] > value:
            if index < range.start + skip:
                return self.binaryLast(value, WikiRange(range.start, index))
            index -= skip
        return self.binaryLast(value, WikiRange(index, index + skip))
    def insertionSort(self, range):
        if not (range.length > 1):
            return
        for index in builtins.range((range.start + 1), range.end):
            value = self.read(index)
            destination = self.binaryLast(value, WikiRange(range.start, index))
            cursor = index
            while cursor > destination:
                self.values[cursor] = self.read(cursor - 1)
                cursor -= 1
            self.values[destination] = value
    def blockSwap(self, first, second, length):
        if not (length > 0):
            return
        for offset in builtins.range(0, length):
            self.swap(first + offset, second + offset)
    def rotate(self, amount, range):
        if not (range.length > 0):
            return
        split = (range.start + amount if amount >= 0 else range.end + amount)
        if not (range.start < split  and  split < range.end):
            return
        position = range.start
        leftLength = split - range.start
        rightLength = range.end - split
        while leftLength != 0  and  rightLength != 0:
            if leftLength <= rightLength:
                self.blockSwap(position, position + leftLength, leftLength)
                position += leftLength
                rightLength -= leftLength
            else:
                self.blockSwap(position + leftLength - rightLength, position + leftLength, rightLength)
                leftLength -= rightLength
    def mergeInternal(self, left, right, buffer):
        aCount = 0
        bCount = 0
        insert = 0
        if right.length > 0  and  left.length > 0:
            while True:
                if not self.less(right.start + bCount, buffer.start + aCount):
                    self.swap(left.start + insert, buffer.start + aCount)
                    aCount += 1
                    insert += 1
                    if aCount >= left.length:
                        break
                else:
                    self.swap(left.start + insert, right.start + bCount)
                    bCount += 1
                    insert += 1
                    if bCount >= right.length:
                        break
        self.blockSwap(buffer.start + aCount, left.start + insert, left.length - aCount)
    def mergeInPlace(self, originalLeft, originalRight):
        if not (originalLeft.length > 0  and  originalRight.length > 0):
            return
        left = originalLeft
        right = originalRight
        while True:
            middle = self.binaryFirst(self.read(left.start), right)
            amount = middle - left.end
            self.rotate(-amount, WikiRange(left.start, middle))
            if right.end == middle:
                break
            right.start = middle
            left.set(left.start + amount, right.start)
            left.start = self.binaryLast(self.read(left.start), left)
            if left.length == 0:
                break
    def netSwap(self, range, order, x, y):
        first = range.start + x
        second = range.start + y
        a = self.read(first)
        b = self.read(second)
        isGreater = self.greaterValues(a, b)
        isEqual = not isGreater  and  not self.lessValues(a, b)
        if isGreater  or  (isEqual  and  order[x] > order[y]):
            self.swap(first, second)
            order[x], order[y] = order[y], order[x]
    def sortSmallRuns(self, iterator):
        while not iterator.finished:
            order = list(builtins.range(8))
            range = iterator.nextRange()
            pairs = []
            if range.length == 8:
                pairs = [(0,1),(2,3),(4,5),(6,7),(0,2),(1,3),(4,6),(5,7),(1,2),(5,6),(0,4),(3,7),(1,5),(2,6),(1,4),(3,6),(2,4),(3,5),(3,4)]
            elif range.length == 7:
                pairs = [(1,2),(3,4),(5,6),(0,2),(3,5),(4,6),(0,1),(4,5),(2,6),(0,4),(1,5),(0,3),(2,5),(1,3),(2,4),(2,3)]
            elif range.length == 6:
                pairs = [(1,2),(4,5),(0,2),(3,5),(0,1),(3,4),(2,5),(0,3),(1,4),(2,4),(1,3),(2,3)]
            elif range.length == 5:
                pairs = [(0,1),(3,4),(2,4),(2,3),(1,4),(0,3),(0,2),(1,3),(1,2)]
            elif range.length == 4:
                pairs = [(0,1),(2,3),(0,2),(1,3),(1,2)]
            else:
                pairs = []
            for (x, y) in pairs:
                self.netSwap(range, order, x, y)
    def sort(self):
        size = len(self.values)
        if size < 4:
            self.insertionSort(WikiRange(0, size))
            return
        iterator = WikiIterator(size)
        self.sortSmallRuns(iterator)
        if size < 8:
            return
        while True:
            nominalBlock = max(1, int(math.sqrt(iterator.length)))
            blockSize = nominalBlock
            targetBufferSize = iterator.length // blockSize + 1
            buffer1 = WikiRange()
            buffer2 = WikiRange()
            pulls = [WikiPull(), WikiPull()]
            pullIndex = 0
            find = targetBufferSize * 2
            findSeparately = False
            if find > iterator.length:
                find = targetBufferSize
                findSeparately = True
            iterator.begin()
            while not iterator.finished:
                left = iterator.nextRange()
                right = iterator.nextRange()
                last = left.start
                count = 1
                index = last
                while count < find:
                    index = self.findLastForward(self.read(last), WikiRange(last + 1, left.end), find - count)
                    if index == left.end:
                        break
                    last = index
                    count += 1
                index = last
                if count >= targetBufferSize:
                    pulls[pullIndex] = WikiPull(from_= index, to= left.start, count= count, range= WikiRange(left.start, right.end))
                    pullIndex = 1
                    if count == targetBufferSize * 2:
                        buffer1 = WikiRange(left.start, left.start + targetBufferSize)
                        buffer2 = WikiRange(left.start + targetBufferSize, left.start + count)
                        break
                    elif find == targetBufferSize * 2:
                        buffer1 = WikiRange(left.start, left.start + count)
                        find = targetBufferSize
                    elif findSeparately:
                        buffer1 = WikiRange(left.start, left.start + count)
                        findSeparately = False
                    else:
                        buffer2 = WikiRange(left.start, left.start + count)
                        break
                elif pullIndex == 0  and  count > buffer1.length:
                    buffer1 = WikiRange(left.start, left.start + count)
                    pulls[pullIndex] = WikiPull(from_= index, to= left.start, count= count, range= WikiRange(left.start, right.end))
                last = right.end - 1
                count = 1
                while count < find:
                    index = self.findFirstBackward(self.read(last), WikiRange(right.start, last), find - count)
                    if index == right.start:
                        break
                    last = index - 1
                    count += 1
                index = last
                if count >= targetBufferSize:
                    pulls[pullIndex] = WikiPull(from_= index, to= right.end, count= count, range= WikiRange(left.start, right.end))
                    pullIndex = 1
                    if count == targetBufferSize * 2:
                        buffer1 = WikiRange(right.end - count, right.end - targetBufferSize)
                        buffer2 = WikiRange(right.end - targetBufferSize, right.end)
                        break
                    elif find == targetBufferSize * 2:
                        buffer1 = WikiRange(right.end - count, right.end)
                        find = targetBufferSize
                    elif findSeparately:
                        buffer1 = WikiRange(right.end - count, right.end)
                        findSeparately = False
                    else:
                        if pulls[0].range.start == left.start:
                            pulls[0].range.end -= pulls[1].count
                        buffer2 = WikiRange(right.end - count, right.end)
                        break
                elif pullIndex == 0  and  count > buffer1.length:
                    buffer1 = WikiRange(right.end - count, right.end)
                    pulls[pullIndex] = WikiPull(from_= index, to= right.end, count= count, range= WikiRange(left.start, right.end))
            for pull in builtins.range(0, 2):
                length = pulls[pull].count
                if pulls[pull].to < pulls[pull].from_:
                    index = pulls[pull].from_
                    if length > 1:
                        for count in builtins.range(1, length):
                            index = self.findFirstBackward(self.read(index - 1), WikiRange(pulls[pull].to, pulls[pull].from_ - (count - 1)), length - count)
                            range = WikiRange(index + 1, pulls[pull].from_ + 1)
                            self.rotate(range.length - count, range)
                            pulls[pull].from_ = index + count
                elif pulls[pull].to > pulls[pull].from_:
                    index = pulls[pull].from_ + 1
                    if length > 1:
                        for count in builtins.range(1, length):
                            index = self.findLastForward(self.read(index), WikiRange(index, pulls[pull].to), length - count)
                            range = WikiRange(pulls[pull].from_, index - 1)
                            self.rotate(count, range)
                            pulls[pull].from_ = index - 1 - count
            bufferSize = buffer1.length
            blockSize = iterator.length // bufferSize + 1
            iterator.begin()
            while not iterator.finished:
                left = iterator.nextRange()
                right = iterator.nextRange()
                start = left.start
                for pull in pulls:
                    if start != pull.range.start:
                        continue
                    if pull.from_ > pull.to:
                        left.start += pull.count
                    elif pull.from_ < pull.to:
                        right.end -= pull.count
                if left.length == 0  or  right.length == 0:
                    continue
                if self.less(right.end - 1, left.start):
                    self.rotate(left.length, WikiRange(left.start, right.end))
                elif self.less(left.end, left.end - 1):
                    blockA = left.copy()
                    firstA = WikiRange(left.start, left.start + blockA.length % blockSize)
                    indexA = buffer1.start
                    index = firstA.end
                    while index < blockA.end:
                        self.swap(indexA, index)
                        indexA += 1
                        index += blockSize
                    lastA = firstA.copy()
                    lastB = WikiRange()
                    blockB = WikiRange(right.start, right.start + min(blockSize, right.length))
                    blockA.start += firstA.length
                    indexA = buffer1.start
                    if buffer2.length > 0:
                        self.blockSwap(lastA.start, buffer2.start, lastA.length)
                    if blockA.length > 0:
                        while True:
                            if (lastB.length > 0  and  not self.less(lastB.end - 1, indexA))  or  blockB.length == 0:
                                split = self.binaryFirst(self.read(indexA), lastB)
                                remaining = lastB.end - split
                                minimum = blockA.start
                                findA = minimum + blockSize
                                while findA < blockA.end:
                                    if self.less(findA, minimum):
                                        minimum = findA
                                    findA += blockSize
                                self.blockSwap(blockA.start, minimum, blockSize)
                                self.swap(blockA.start, indexA)
                                indexA += 1
                                if buffer2.length > 0:
                                    self.mergeInternal(lastA, WikiRange(lastA.end, split), buffer2)
                                else:
                                    self.mergeInPlace(lastA, WikiRange(lastA.end, split))
                                if buffer2.length > 0:
                                    self.blockSwap(blockA.start, buffer2.start, blockSize)
                                    self.blockSwap(split, blockA.start + blockSize - remaining, remaining)
                                else:
                                    self.rotate(blockA.start - split, WikiRange(split, blockA.start + blockSize))
                                lastA = WikiRange(blockA.start - remaining, blockA.start - remaining + blockSize)
                                lastB = WikiRange(lastA.end, lastA.end + remaining)
                                blockA.start += blockSize
                                if blockA.length == 0:
                                    break
                            elif blockB.length < blockSize:
                                self.rotate(-blockB.length, WikiRange(blockA.start, blockB.end))
                                lastB = WikiRange(blockA.start, blockA.start + blockB.length)
                                blockA.start += blockB.length
                                blockA.end += blockB.length
                                blockB.end = blockB.start
                            else:
                                self.blockSwap(blockA.start, blockB.start, blockSize)
                                lastB = WikiRange(blockA.start, blockA.start + blockSize)
                                blockA.start += blockSize
                                blockA.end += blockSize
                                blockB.start += blockSize
                                blockB.end = min(blockB.end + blockSize, right.end)
                    if buffer2.length > 0:
                        self.mergeInternal(lastA, WikiRange(lastA.end, right.end), buffer2)
                    else:
                        self.mergeInPlace(lastA, WikiRange(lastA.end, right.end))
            self.insertionSort(buffer2)
            for pull in pulls:
                unique = pull.count * 2
                if pull.from_ > pull.to:
                    buffer = WikiRange(pull.range.start, pull.range.start + pull.count)
                    while buffer.length > 0:
                        index = self.findFirstForward(self.read(buffer.start), WikiRange(buffer.end, pull.range.end), unique)
                        amount = index - buffer.end
                        self.rotate(buffer.length, WikiRange(buffer.start, index))
                        buffer.start += amount + 1
                        buffer.end += amount
                        unique -= 2
                elif pull.from_ < pull.to:
                    buffer = WikiRange(pull.range.end - pull.count, pull.range.end)
                    while buffer.length > 0:
                        index = self.findLastBackward(self.read(buffer.end - 1), WikiRange(pull.range.start, buffer.start), unique)
                        amount = buffer.start - index
                        self.rotate(amount, WikiRange(index, buffer.end))
                        buffer.start -= amount
                        buffer.end -= amount + 1
                        unique -= 2
            if not iterator.nextLevel():
                break

def sort(values):
    WikiSortExample(values).sort()

if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
