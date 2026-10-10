# The WikiSorting source is released to the public domain under the Unlicense.

class WikiRange
  attr_accessor :start, :end
  def initialize(start=0, finish=0)
    @start = start
    @end = finish
  end
  def length()
    return (@end - @start)
  end
  def set(start, finish)
    @start, @end = start, finish
  end
  def copy()
    return WikiRange.new(@start, @end)
  end
end
class WikiPull
  attr_accessor :from_, :to, :count, :range
  def initialize(from_=0, to=0, count=0, range=nil)
    @from_ = from_
    @to = to
    @count = count
    @range = ((range == nil) ? WikiRange.new() : range)
  end
end
class WikiIterator
  attr_accessor :size, :denominator, :numeratorStep, :decimalStep, :numerator, :decimal
  def initialize(size)
    @size = size
    @denominator = ((1 << (size.bit_length() - 1)) / 4)
    @numeratorStep = (size % @denominator)
    @decimalStep = (size / @denominator)
    @numerator = 0
    @decimal = 0
  end
  def begin()
    @numerator = 0
    @decimal = 0
  end
  def nextRange()
    start = @decimal
    @decimal += @decimalStep
    @numerator += @numeratorStep
    if (@numerator >= @denominator)
      @numerator -= @denominator
      @decimal += 1
    end
    return WikiRange.new(start, @decimal)
  end
  def finished()
    return (@decimal >= @size)
  end
  def nextLevel()
    @decimalStep += @decimalStep
    @numeratorStep += @numeratorStep
    if (@numeratorStep >= @denominator)
      @numeratorStep -= @denominator
      @decimalStep += 1
    end
    return (@decimalStep < @size)
  end
  def length()
    return @decimalStep
  end
end
class WikiSortExample
  attr_accessor :values
  def initialize(input)
    @values = input
  end
  def read(index)
    return @values[index]
  end
  def less(left, right)
    return (@values[left] < @values[right])
  end
  def lessValues(left, right)
    return (left < right)
  end
  def greaterValues(left, right)
    return (left > right)
  end
  def swap(left, right)
    @values[left], @values[right] = @values[right], @values[left]
  end
  def binaryFirst(value, range)
    start = range.start
    finish = range.end
    while (start < finish)
      middle = (start + ((finish - start) / 2))
      if (@values[middle] < value)
        start = (middle + 1)
      else
        finish = middle
      end
    end
    return start
  end
  def binaryLast(value, range)
    start = range.start
    finish = range.end
    while (start < finish)
      middle = (start + ((finish - start) / 2))
      if (@values[middle] <= value)
        start = (middle + 1)
      else
        finish = middle
      end
    end
    return start
  end
  def findFirstForward(value, range, unique)
    if !((range.length > 0))
      return range.start
    end
    skip = [(range.length / [unique, 1].max), 1].max
    index = (range.start + skip)
    while (@values[(index - 1)] < value)
      if (index >= (range.end - skip))
        return binaryFirst(value, WikiRange.new(index, range.end))
      end
      index += skip
    end
    return binaryFirst(value, WikiRange.new((index - skip), index))
  end
  def findLastForward(value, range, unique)
    if !((range.length > 0))
      return range.start
    end
    skip = [(range.length / [unique, 1].max), 1].max
    index = (range.start + skip)
    while (@values[(index - 1)] <= value)
      if (index >= (range.end - skip))
        return binaryLast(value, WikiRange.new(index, range.end))
      end
      index += skip
    end
    return binaryLast(value, WikiRange.new((index - skip), index))
  end
  def findFirstBackward(value, range, unique)
    if !((range.length > 0))
      return range.start
    end
    skip = [(range.length / [unique, 1].max), 1].max
    index = (range.end - skip)
    while ((index > range.start) && (@values[(index - 1)] >= value))
      if (index < (range.start + skip))
        return binaryFirst(value, WikiRange.new(range.start, index))
      end
      index -= skip
    end
    return binaryFirst(value, WikiRange.new(index, (index + skip)))
  end
  def findLastBackward(value, range, unique)
    if !((range.length > 0))
      return range.start
    end
    skip = [(range.length / [unique, 1].max), 1].max
    index = (range.end - skip)
    while ((index > range.start) && (@values[(index - 1)] > value))
      if (index < (range.start + skip))
        return binaryLast(value, WikiRange.new(range.start, index))
      end
      index -= skip
    end
    return binaryLast(value, WikiRange.new(index, (index + skip)))
  end
  def insertionSort(range)
    if !((range.length > 1))
      return
    end
    ((range.start + 1)...range.end).each do |index|
      value = read(index)
      destination = binaryLast(value, WikiRange.new(range.start, index))
      cursor = index
      while (cursor > destination)
        @values[cursor] = read((cursor - 1))
        cursor -= 1
      end
      @values[destination] = value
    end
  end
  def blockSwap(first, second, length)
    if !((length > 0))
      return
    end
    (0...length).each do |offset|
      swap((first + offset), (second + offset))
    end
  end
  def rotate(amount, range)
    if !((range.length > 0))
      return
    end
    split = ((amount >= 0) ? (range.start + amount) : (range.end + amount))
    if !(((range.start < split) && (split < range.end)))
      return
    end
    position = range.start
    leftLength = (split - range.start)
    rightLength = (range.end - split)
    while ((leftLength != 0) && (rightLength != 0))
      if (leftLength <= rightLength)
        blockSwap(position, (position + leftLength), leftLength)
        position += leftLength
        rightLength -= leftLength
      else
        blockSwap(((position + leftLength) - rightLength), (position + leftLength), rightLength)
        leftLength -= rightLength
      end
    end
  end
  def mergeInternal(left, right, buffer)
    aCount = 0
    bCount = 0
    insert = 0
    if ((right.length > 0) && (left.length > 0))
      while true
        if !(less((right.start + bCount), (buffer.start + aCount)))
          swap((left.start + insert), (buffer.start + aCount))
          aCount += 1
          insert += 1
          if (aCount >= left.length)
            break
          end
        else
          swap((left.start + insert), (right.start + bCount))
          bCount += 1
          insert += 1
          if (bCount >= right.length)
            break
          end
        end
      end
    end
    blockSwap((buffer.start + aCount), (left.start + insert), (left.length - aCount))
  end
  def mergeInPlace(originalLeft, originalRight)
    if !(((originalLeft.length > 0) && (originalRight.length > 0)))
      return
    end
    left = originalLeft
    right = originalRight
    while true
      middle = binaryFirst(read(left.start), right)
      amount = (middle - left.end)
      rotate(-(amount), WikiRange.new(left.start, middle))
      if (right.end == middle)
        break
      end
      right.start = middle
      left.set((left.start + amount), right.start)
      left.start = binaryLast(read(left.start), left)
      if (left.length == 0)
        break
      end
    end
  end
  def netSwap(range, order, x, y)
    first = (range.start + x)
    second = (range.start + y)
    a = read(first)
    b = read(second)
    isGreater = greaterValues(a, b)
    isEqual = (!(isGreater) && !(lessValues(a, b)))
    if (isGreater || (isEqual && (order[x] > order[y])))
      swap(first, second)
      order[x], order[y] = order[y], order[x]
    end
  end
  def sortSmallRuns(iterator)
    while !(iterator.finished)
      order = (0...8).to_a
      range = iterator.nextRange()
      pairs = []
      if (range.length == 8)
        pairs = [[0, 1], [2, 3], [4, 5], [6, 7], [0, 2], [1, 3], [4, 6], [5, 7], [1, 2], [5, 6], [0, 4], [3, 7], [1, 5], [2, 6], [1, 4], [3, 6], [2, 4], [3, 5], [3, 4]]
      else
        if (range.length == 7)
          pairs = [[1, 2], [3, 4], [5, 6], [0, 2], [3, 5], [4, 6], [0, 1], [4, 5], [2, 6], [0, 4], [1, 5], [0, 3], [2, 5], [1, 3], [2, 4], [2, 3]]
        else
          if (range.length == 6)
            pairs = [[1, 2], [4, 5], [0, 2], [3, 5], [0, 1], [3, 4], [2, 5], [0, 3], [1, 4], [2, 4], [1, 3], [2, 3]]
          else
            if (range.length == 5)
              pairs = [[0, 1], [3, 4], [2, 4], [2, 3], [1, 4], [0, 3], [0, 2], [1, 3], [1, 2]]
            else
              if (range.length == 4)
                pairs = [[0, 1], [2, 3], [0, 2], [1, 3], [1, 2]]
              else
                pairs = []
              end
            end
          end
        end
      end
      pairs.each do |x, y|
        netSwap(range, order, x, y)
      end
    end
  end
  def sort()
    size = @values.length
    if (size < 4)
      insertionSort(WikiRange.new(0, size))
      return
    end
    iterator = WikiIterator.new(size)
    sortSmallRuns(iterator)
    if (size < 8)
      return
    end
    while true
      nominalBlock = [1, Math.sqrt(iterator.length).to_i].max
      blockSize = nominalBlock
      targetBufferSize = ((iterator.length / blockSize) + 1)
      buffer1 = WikiRange.new()
      buffer2 = WikiRange.new()
      pulls = [WikiPull.new(), WikiPull.new()]
      pullIndex = 0
      find = (targetBufferSize * 2)
      findSeparately = false
      if (find > iterator.length)
        find = targetBufferSize
        findSeparately = true
      end
      iterator.begin()
      while !(iterator.finished)
        left = iterator.nextRange()
        right = iterator.nextRange()
        last = left.start
        count = 1
        index = last
        while (count < find)
          index = findLastForward(read(last), WikiRange.new((last + 1), left.end), (find - count))
          if (index == left.end)
            break
          end
          last = index
          count += 1
        end
        index = last
        if (count >= targetBufferSize)
          pulls[pullIndex] = WikiPull.new(index, left.start, count, WikiRange.new(left.start, right.end))
          pullIndex = 1
          if (count == (targetBufferSize * 2))
            buffer1 = WikiRange.new(left.start, (left.start + targetBufferSize))
            buffer2 = WikiRange.new((left.start + targetBufferSize), (left.start + count))
            break
          else
            if (find == (targetBufferSize * 2))
              buffer1 = WikiRange.new(left.start, (left.start + count))
              find = targetBufferSize
            else
              if findSeparately
                buffer1 = WikiRange.new(left.start, (left.start + count))
                findSeparately = false
              else
                buffer2 = WikiRange.new(left.start, (left.start + count))
                break
              end
            end
          end
        else
          if ((pullIndex == 0) && (count > buffer1.length))
            buffer1 = WikiRange.new(left.start, (left.start + count))
            pulls[pullIndex] = WikiPull.new(index, left.start, count, WikiRange.new(left.start, right.end))
          end
        end
        last = (right.end - 1)
        count = 1
        while (count < find)
          index = findFirstBackward(read(last), WikiRange.new(right.start, last), (find - count))
          if (index == right.start)
            break
          end
          last = (index - 1)
          count += 1
        end
        index = last
        if (count >= targetBufferSize)
          pulls[pullIndex] = WikiPull.new(index, right.end, count, WikiRange.new(left.start, right.end))
          pullIndex = 1
          if (count == (targetBufferSize * 2))
            buffer1 = WikiRange.new((right.end - count), (right.end - targetBufferSize))
            buffer2 = WikiRange.new((right.end - targetBufferSize), right.end)
            break
          else
            if (find == (targetBufferSize * 2))
              buffer1 = WikiRange.new((right.end - count), right.end)
              find = targetBufferSize
            else
              if findSeparately
                buffer1 = WikiRange.new((right.end - count), right.end)
                findSeparately = false
              else
                if (pulls[0].range.start == left.start)
                  pulls[0].range.end -= pulls[1].count
                end
                buffer2 = WikiRange.new((right.end - count), right.end)
                break
              end
            end
          end
        else
          if ((pullIndex == 0) && (count > buffer1.length))
            buffer1 = WikiRange.new((right.end - count), right.end)
            pulls[pullIndex] = WikiPull.new(index, right.end, count, WikiRange.new(left.start, right.end))
          end
        end
      end
      (0...2).each do |pull|
        length = pulls[pull].count
        if (pulls[pull].to < pulls[pull].from_)
          index = pulls[pull].from_
          if (length > 1)
            (1...length).each do |count|
              index = findFirstBackward(read((index - 1)), WikiRange.new(pulls[pull].to, (pulls[pull].from_ - (count - 1))), (length - count))
              range = WikiRange.new((index + 1), (pulls[pull].from_ + 1))
              rotate((range.length - count), range)
              pulls[pull].from_ = (index + count)
            end
          end
        else
          if (pulls[pull].to > pulls[pull].from_)
            index = (pulls[pull].from_ + 1)
            if (length > 1)
              (1...length).each do |count|
                index = findLastForward(read(index), WikiRange.new(index, pulls[pull].to), (length - count))
                range = WikiRange.new(pulls[pull].from_, (index - 1))
                rotate(count, range)
                pulls[pull].from_ = ((index - 1) - count)
              end
            end
          end
        end
      end
      bufferSize = buffer1.length
      blockSize = ((iterator.length / bufferSize) + 1)
      iterator.begin()
      while !(iterator.finished)
        left = iterator.nextRange()
        right = iterator.nextRange()
        start = left.start
        pulls.each do |pull|
          if (start != pull.range.start)
            next
          end
          if (pull.from_ > pull.to)
            left.start += pull.count
          else
            if (pull.from_ < pull.to)
              right.end -= pull.count
            end
          end
        end
        if ((left.length == 0) || (right.length == 0))
          next
        end
        if less((right.end - 1), left.start)
          rotate(left.length, WikiRange.new(left.start, right.end))
        else
          if less(left.end, (left.end - 1))
            blockA = left.copy()
            firstA = WikiRange.new(left.start, (left.start + (blockA.length % blockSize)))
            indexA = buffer1.start
            index = firstA.end
            while (index < blockA.end)
              swap(indexA, index)
              indexA += 1
              index += blockSize
            end
            lastA = firstA.copy()
            lastB = WikiRange.new()
            blockB = WikiRange.new(right.start, (right.start + [blockSize, right.length].min))
            blockA.start += firstA.length
            indexA = buffer1.start
            if (buffer2.length > 0)
              blockSwap(lastA.start, buffer2.start, lastA.length)
            end
            if (blockA.length > 0)
              while true
                if (((lastB.length > 0) && !(less((lastB.end - 1), indexA))) || (blockB.length == 0))
                  split = binaryFirst(read(indexA), lastB)
                  remaining = (lastB.end - split)
                  minimum = blockA.start
                  findA = (minimum + blockSize)
                  while (findA < blockA.end)
                    if less(findA, minimum)
                      minimum = findA
                    end
                    findA += blockSize
                  end
                  blockSwap(blockA.start, minimum, blockSize)
                  swap(blockA.start, indexA)
                  indexA += 1
                  if (buffer2.length > 0)
                    mergeInternal(lastA, WikiRange.new(lastA.end, split), buffer2)
                  else
                    mergeInPlace(lastA, WikiRange.new(lastA.end, split))
                  end
                  if (buffer2.length > 0)
                    blockSwap(blockA.start, buffer2.start, blockSize)
                    blockSwap(split, ((blockA.start + blockSize) - remaining), remaining)
                  else
                    rotate((blockA.start - split), WikiRange.new(split, (blockA.start + blockSize)))
                  end
                  lastA = WikiRange.new((blockA.start - remaining), ((blockA.start - remaining) + blockSize))
                  lastB = WikiRange.new(lastA.end, (lastA.end + remaining))
                  blockA.start += blockSize
                  if (blockA.length == 0)
                    break
                  end
                else
                  if (blockB.length < blockSize)
                    rotate(-(blockB.length), WikiRange.new(blockA.start, blockB.end))
                    lastB = WikiRange.new(blockA.start, (blockA.start + blockB.length))
                    blockA.start += blockB.length
                    blockA.end += blockB.length
                    blockB.end = blockB.start
                  else
                    blockSwap(blockA.start, blockB.start, blockSize)
                    lastB = WikiRange.new(blockA.start, (blockA.start + blockSize))
                    blockA.start += blockSize
                    blockA.end += blockSize
                    blockB.start += blockSize
                    blockB.end = [(blockB.end + blockSize), right.end].min
                  end
                end
              end
            end
            if (buffer2.length > 0)
              mergeInternal(lastA, WikiRange.new(lastA.end, right.end), buffer2)
            else
              mergeInPlace(lastA, WikiRange.new(lastA.end, right.end))
            end
          end
        end
      end
      insertionSort(buffer2)
      pulls.each do |pull|
        unique = (pull.count * 2)
        if (pull.from_ > pull.to)
          buffer = WikiRange.new(pull.range.start, (pull.range.start + pull.count))
          while (buffer.length > 0)
            index = findFirstForward(read(buffer.start), WikiRange.new(buffer.end, pull.range.end), unique)
            amount = (index - buffer.end)
            rotate(buffer.length, WikiRange.new(buffer.start, index))
            buffer.start += (amount + 1)
            buffer.end += amount
            unique -= 2
          end
        else
          if (pull.from_ < pull.to)
            buffer = WikiRange.new((pull.range.end - pull.count), pull.range.end)
            while (buffer.length > 0)
              index = findLastBackward(read((buffer.end - 1)), WikiRange.new(pull.range.start, buffer.start), unique)
              amount = (buffer.start - index)
              rotate(amount, WikiRange.new(index, buffer.end))
              buffer.start -= amount
              buffer.end -= (amount + 1)
              unique -= 2
            end
          end
        end
      end
      if !(iterator.nextLevel())
        break
      end
    end
  end
end
def sort(values)
  WikiSortExample.new(values).sort()
end
array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
puts array.inspect
