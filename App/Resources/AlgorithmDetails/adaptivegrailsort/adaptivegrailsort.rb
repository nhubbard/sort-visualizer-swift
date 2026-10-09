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


class AdaptiveGrailExample
  def initialize(input)
    @values = input
    @minRun = 16
  end
  def read(index)
    return @values[index]
  end
  def write(index, value)
    @values[index] = value
  end
  def swap(first, second)
    @values[first], @values[second] = @values[second], @values[first]
  end
  def compare(first, second)
    if (@values[first] < @values[second])
      return -(1)
    end
    if (@values[first] > @values[second])
      return 1
    end
    return 0
  end
  def compareValue(index, value)
    if (@values[index] < value)
      return -(1)
    end
    if (@values[index] > value)
      return 1
    end
    return 0
  end
  def reverse(start, finish)
    left = start
    right = (finish - 1)
    while (left < right)
      @values[left], @values[right] = @values[right], @values[left]
      left += 1
      right -= 1
    end
  end
  def multiSwap(first, second, count)
    if !((count > 0))
      return
    end
    (0...count).each do |offset|
      swap((first + offset), (second + offset))
    end
  end
  def multiTriSwap(first, second, third, count)
    if !((count > 0))
      return
    end
    (0...count).each do |offset|
      value = read((first + offset))
      write((first + offset), read((second + offset)))
      write((second + offset), read((third + offset)))
      write((third + offset), value)
    end
  end
  def insertTo(source, destination)
    value = read(source)
    cursor = source
    while (cursor > destination)
      write(cursor, read((cursor - 1)))
      cursor -= 1
    end
    write(destination, value)
  end
  def insertToBackward(source, destination)
    value = read(source)
    cursor = source
    while (cursor < destination)
      write(cursor, read((cursor + 1)))
      cursor += 1
    end
    write(cursor, value)
  end
  def shift(destination, source, finish)
    if !((source < finish))
      return
    end
    (0...(finish - source)).each do |offset|
      swap((destination + offset), (source + offset))
    end
  end
  def rotate(startIn, middleIn, endIn)
    start = startIn
    middle = middleIn
    finish = endIn
    left = (middle - start)
    right = (finish - middle)
    while ((left > 1) && (right > 1))
      if (right < left)
        multiSwap((middle - right), middle, right)
        finish -= right
        middle -= right
        left -= right
      else
        multiSwap(start, middle, left)
        start += left
        middle += left
        right -= left
      end
    end
    if (right == 1)
      insertTo(middle, start)
    else
      if (left == 1)
        insertToBackward(start, (finish - 1))
      end
    end
  end
  def leftBinarySearch(start, finish, value)
    lower = start
    upper = finish
    while (lower < upper)
      middle = (lower + ((upper - lower) / 2))
      if (@values[middle] >= value)
        upper = middle
      else
        lower = (middle + 1)
      end
    end
    return lower
  end
  def rightBinarySearch(start, finish, value)
    lower = start
    upper = finish
    while (lower < upper)
      middle = (lower + ((upper - lower) / 2))
      if (@values[middle] > value)
        upper = middle
      else
        lower = (middle + 1)
      end
    end
    return lower
  end
  def buildUniqueRun(start, limit)
    count = 1
    index = (start + 1)
    order = compare((index - 1), index)
    if (order < 0)
      index += 1
      count += 1
      while ((count < limit) && (compare((index - 1), index) < 0))
        index += 1
        count += 1
      end
    else
      if (order > 0)
        index += 1
        count += 1
        while ((count < limit) && (compare((index - 1), index) > 0))
          index += 1
          count += 1
        end
        reverse(start, index)
      end
    end
    return count
  end
  def buildUniqueRunBackward(finish, limit)
    count = 1
    index = (finish - 1)
    order = compare((index - 1), index)
    if (order < 0)
      index -= 1
      count += 1
      while ((count < limit) && (compare((index - 1), index) < 0))
        index -= 1
        count += 1
      end
    else
      if (order > 0)
        index -= 1
        count += 1
        while ((count < limit) && (compare((index - 1), index) > 0))
          index -= 1
          count += 1
        end
        reverse(index, finish)
      end
    end
    return count
  end
  def findKeys(start, finish, initial, needed)
    count = initial
    keyStart = start
    keyEnd = (start + count)
    index = keyEnd
    while ((index < finish) && (count < needed))
      candidate = read(index)
      location = leftBinarySearch(keyStart, keyEnd, candidate)
      if ((location == keyEnd) || (compareValue(location, candidate) != 0))
        rotate(keyStart, keyEnd, index)
        distance = (index - keyEnd)
        location += distance
        keyStart += distance
        keyEnd += distance
        insertTo(keyEnd, location)
        count += 1
        keyEnd += 1
      end
      index += 1
    end
    rotate(start, keyStart, keyEnd)
    return count
  end
  def findKeysBackward(start, finish, initial, needed)
    count = initial
    keyStart = (finish - count)
    keyEnd = finish
    index = (keyStart - 1)
    while ((index >= start) && (count < needed))
      candidate = read(index)
      location = leftBinarySearch(keyStart, keyEnd, candidate)
      if ((location == keyEnd) || (compareValue(location, candidate) != 0))
        rotate((index + 1), keyStart, keyEnd)
        distance = (keyStart - (index + 1))
        location -= distance
        keyEnd -= distance
        keyStart -= (distance + 1)
        count += 1
        insertToBackward(index, (location - 1))
      end
      index -= 1
    end
    rotate(keyStart, keyEnd, finish)
    return count
  end
  def buildRuns(start, finish)
    index = (start + 1)
    runStart = start
    while (index < finish)
      if (compare((index - 1), index) > 0)
        index += 1
        while ((index < finish) && (compare((index - 1), index) > 0))
          index += 1
        end
        reverse(runStart, index)
      else
        index += 1
        while ((index < finish) && (compare((index - 1), index) <= 0))
          index += 1
        end
      end
      if (index < finish)
        runStart = ((index - (((index - runStart) - 1) % @minRun)) - 1)
      end
      while (((index - runStart) < @minRun) && (index < finish))
        insertTo(index, rightBinarySearch(runStart, index, read(index)))
        index += 1
      end
      runStart = index
      index += 1
    end
  end
  def binaryInsertion(start, finish)
    if !(((finish - start) > 1))
      return
    end
    ((start + 1)...finish).each do |index|
      insertTo(index, rightBinarySearch(start, index, read(index)))
    end
  end
  def mergeWithBufferRest(start, middle, finish, buffer, length)
    left = 0
    right = middle
    output = start
    while ((left < length) && (right < finish))
      if (compare((buffer + left), right) <= 0)
        swap(output, (buffer + left))
        left += 1
      else
        swap(output, right)
        right += 1
      end
      output += 1
    end
    while (left < length)
      swap(output, (buffer + left))
      output += 1
      left += 1
    end
  end
  def mergeWithBuffer(start, middle, finish, buffer)
    length = (middle - start)
    multiSwap(buffer, start, length)
    mergeWithBufferRest(start, middle, finish, buffer, length)
  end
  def mergeWithBufferBackward(start, middle, finish, buffer)
    length = (finish - middle)
    multiSwap(middle, buffer, length)
    left = (length - 1)
    right = (middle - 1)
    output = (finish - 1)
    while ((left >= 0) && (right >= start))
      if (compare((buffer + left), right) >= 0)
        swap(output, (buffer + left))
        left -= 1
      else
        swap(output, right)
        right -= 1
      end
      output -= 1
    end
    while (left >= 0)
      swap(output, (buffer + left))
      output -= 1
      left -= 1
    end
  end
  def inPlaceMerge(start, middle, finish)
    left = start
    right = middle
    while ((left < right) && (right < finish))
      if (compare(left, right) > 0)
        next_value = leftBinarySearch((right + 1), finish, read(left))
        rotate(left, right, next_value)
        left += (next_value - right)
        right = next_value
      else
        left += 1
      end
    end
  end
  def inPlaceMergeBackward(start, middle, finish)
    left = (middle - 1)
    right = (finish - 1)
    while ((right > left) && (left >= start))
      if (compare(left, right) > 0)
        next_value = rightBinarySearch(start, left, read(right))
        rotate(next_value, (left + 1), (right + 1))
        right -= ((left + 1) - next_value)
        left = (next_value - 1)
      else
        right -= 1
      end
    end
  end
  def mergeWithoutBuffer(start, middle, finish)
    if ((middle - start) > (finish - middle))
      inPlaceMergeBackward(start, middle, finish)
    else
      inPlaceMerge(start, middle, finish)
    end
  end
  def checkSorted(middle)
    return (compare((middle - 1), middle) > 0)
  end
  def checkReverseBounds(start, middle, finish)
    if (compare(start, (finish - 1)) > 0)
      rotate(start, middle, finish)
      return false
    end
    return true
  end
  def checkBounds(start, middle, finish)
    return (checkSorted(middle) && checkReverseBounds(start, middle, finish))
  end
  def subarray(tag, middleKey)
    return ((compare(tag, middleKey) < 0) ? 'left' : 'right')
  end
  def blockSelectSort(position, tags, offset, distance, leftCount, blockCount, blockLength)
    middleKey = leftCount
    index = 0
    limit = (leftCount + 1)
    while (index < (limit - 1))
      minimum = index
      candidate = [(leftCount - offset), (index + 1)].max
      while (candidate < limit)
        order = compare(((position + distance) + (candidate * blockLength)), ((position + distance) + (minimum * blockLength)))
        if ((order < 0) || ((order == 0) && (compare((tags + candidate), (tags + minimum)) < 0)))
          minimum = candidate
        end
        candidate += 1
      end
      if (minimum != index)
        multiSwap((position + (index * blockLength)), (position + (minimum * blockLength)), blockLength)
        swap((tags + index), (tags + minimum))
        if ((limit < blockCount) && (minimum == (limit - 1)))
          limit += 1
        end
      end
      if (minimum == middleKey)
        middleKey = index
      end
      index += 1
    end
    return (tags + middleKey)
  end
  def sortKeys(finish, buffer, middleKey)
    swap(buffer, middleKey)
    left = middleKey
    index = (left + 1)
    right = (buffer + 1)
    while (index < finish)
      if (compare(index, buffer) < 0)
        swap(left, index)
        left += 1
      else
        swap(right, index)
        right += 1
      end
      index += 1
    end
    multiSwap(left, buffer, (finish - left))
  end
  def sortKeysWithoutBuffer(finish, middleKey)
    left = middleKey
    index = (left + 1)
    while (index < finish)
      if (compare(index, left) < 0)
        insertTo(index, left)
        left += 1
      end
      index += 1
    end
  end
  def mergeBlocks(start, middle, finish, destination, reverseEqual)
    left = start
    right = middle
    output = destination
    while ((left < middle) && (right < finish))
      order = compare(left, right)
      if ((order < 0) || ((order == 0) && !(reverseEqual)))
        swap(output, left)
        left += 1
      else
        swap(output, right)
        right += 1
      end
      output += 1
    end
    if (left > output)
      while (left < middle)
        swap(output, left)
        output += 1
        left += 1
      end
    end
    return right
  end
  def blockMerge(start, middle, finish, tags, buffer, blockLength)
    lastFull = ((finish - (((finish - middle) - 1) % blockLength)) - 1)
    left = (start + blockLength)
    group = start
    key = (tags - 1)
    leftCount = ((middle - left) / blockLength)
    blockCount = ((lastFull - left) / blockLength)
    leftBlocks = -(1)
    rightBlocks = (leftCount - 1)
    multiTriSwap(buffer, (middle - blockLength), start, blockLength)
    insertToBackward(tags, ((tags + leftCount) - 1))
    middleKey = blockSelectSort(left, tags, 1, (blockLength - 1), leftCount, blockCount, blockLength)
    fragment = 'left'
    while ((leftBlocks < leftCount) && (rightBlocks < blockCount))
      if (fragment == 'left')
        while true
          group += blockLength
          leftBlocks += 1
          key += 1
          if !(((leftBlocks < leftCount) && (subarray(key, middleKey) == 'left')))
            break
          end
        end
        if (leftBlocks == leftCount)
          left = mergeBlocks(left, group, finish, (left - blockLength), false)
          mergeWithBufferRest((left - blockLength), left, finish, buffer, blockLength)
        else
          left = mergeBlocks(left, group, ((group + blockLength) - 1), (left - blockLength), false)
        end
        fragment = 'right'
      else
        while true
          group += blockLength
          rightBlocks += 1
          key += 1
          if !(((rightBlocks < blockCount) && (subarray(key, middleKey) == 'right')))
            break
          end
        end
        if (rightBlocks == blockCount)
          shift((left - blockLength), left, finish)
          multiSwap(buffer, (finish - blockLength), blockLength)
        else
          left = mergeBlocks(left, group, ((group + blockLength) - 1), (left - blockLength), true)
        end
        fragment = 'left'
      end
    end
    sortKeys((tags + blockCount), buffer, middleKey)
  end
  def blockMergeWithoutBuffer(start, middle, finish, tags, blockLength)
    firstFull = (start + ((middle - start) % blockLength))
    lastFull = (finish - ((finish - middle) % blockLength))
    left = start
    group = firstFull
    key = tags
    leftCount = (((middle - group) / blockLength) + 1)
    blockCount = (((lastFull - group) / blockLength) + 1)
    leftBlocks = 0
    rightBlocks = leftCount
    middleKey = blockSelectSort(group, tags, 0, 0, (leftCount - 1), (blockCount - 1), blockLength)
    fragment = 'left'
    while ((leftBlocks < leftCount) && (rightBlocks < blockCount))
      next_value = subarray(key, middleKey)
      key += 1
      if (next_value == fragment)
        if (fragment == 'left')
          leftBlocks += 1
        else
          rightBlocks += 1
        end
        left = group
      else
        middle2 = group
        end2 = (group + blockLength)
        if (fragment == 'left')
          while ((left < middle2) && (middle2 < end2))
            if (compare(left, middle2) > 0)
              nextPosition = leftBinarySearch((middle2 + 1), end2, read(left))
              rotate(left, middle2, nextPosition)
              left += (nextPosition - middle2)
              middle2 = nextPosition
            else
              left += 1
            end
          end
        else
          while ((left < middle2) && (middle2 < end2))
            if (compare(left, middle2) >= 0)
              nextPosition = rightBinarySearch((middle2 + 1), end2, read(left))
              rotate(left, middle2, nextPosition)
              left += (nextPosition - middle2)
              middle2 = nextPosition
            else
              left += 1
            end
          end
        end
        if (left < middle2)
          if (next_value == 'left')
            leftBlocks += 1
          else
            rightBlocks += 1
          end
        else
          if (fragment == 'left')
            leftBlocks += 1
          else
            rightBlocks += 1
          end
          fragment = next_value
        end
      end
      group += blockLength
    end
    if (leftBlocks < leftCount)
      inPlaceMergeBackward(start, lastFull, finish)
    end
    sortKeysWithoutBuffer(((tags + blockCount) - 1), middleKey)
  end
  def smartMerge(start, middle, finish, buffer)
    if checkBounds(start, middle, finish)
      trimmed = rightBinarySearch(start, (middle - 1), read(middle))
      mergeWithBuffer(trimmed, middle, finish, buffer)
    end
  end
  def smartMergeBackward(start, middle, finish, buffer)
    if checkBounds(start, middle, finish)
      trimmed = leftBinarySearch((middle + 1), finish, read((middle - 1)))
      mergeWithBufferBackward(start, middle, trimmed, buffer)
    end
  end
  def smartBlockMerge(start, middle, finish, tags, buffer, blockLength)
    if checkBounds(start, middle, finish)
      trimmedStart = rightBinarySearch(start, (middle - 1), read(middle))
      trimmedEnd = leftBinarySearch((middle + 1), finish, read((middle - 1)))
      if checkReverseBounds(trimmedStart, middle, trimmedEnd)
        if (((middle - trimmedStart) <= blockLength) || ((trimmedEnd - middle) <= blockLength))
          if ((trimmedEnd - middle) < (middle - trimmedStart))
            mergeWithBufferBackward(trimmedStart, middle, trimmedEnd, buffer)
          else
            mergeWithBuffer(trimmedStart, middle, trimmedEnd, buffer)
          end
        else
          trimmedStart -= ((trimmedStart - start) % blockLength)
          blockMerge(trimmedStart, middle, trimmedEnd, tags, buffer, blockLength)
        end
      end
    end
  end
  def smartBlockMergeWithoutBuffer(start, middle, finish, tags, blockLength)
    if checkBounds(start, middle, finish)
      trimmedStart = rightBinarySearch(start, (middle - 1), read(middle))
      if ((middle - trimmedStart) <= blockLength)
        inPlaceMerge(trimmedStart, middle, finish)
      else
        blockMergeWithoutBuffer(trimmedStart, middle, finish, tags, blockLength)
      end
    end
  end
  def smartInPlaceMerge(start, middle, finish)
    if checkSorted(middle)
      inPlaceMergeBackward(start, middle, finish)
    end
  end
  def redistributeBuffer(startIn, middleIn, finish)
    start = startIn
    middle = middleIn
    right = leftBinarySearch(middle, finish, read(start))
    rotate(start, middle, right)
    distance = (right - middle)
    start += distance
    middle += distance
    leftMiddle = (start + ((middle - start) / 2))
    right = leftBinarySearch(middle, finish, read(leftMiddle))
    rotate(leftMiddle, middle, right)
    distance = (right - middle)
    leftMiddle += distance
    middle += distance
    mergeWithoutBuffer(start, (leftMiddle - distance), leftMiddle)
    mergeWithoutBuffer(leftMiddle, middle, finish)
  end
  def redistributeBufferBackward(start, middleIn, endIn)
    middle = middleIn
    finish = endIn
    right = rightBinarySearch(start, middle, read((finish - 1)))
    rotate(right, middle, finish)
    distance = (middle - right)
    finish -= distance
    middle -= distance
    rightMiddle = (middle + ((finish - middle) / 2))
    right = rightBinarySearch(start, middle, read((rightMiddle - 1)))
    rotate(right, middle, rightMiddle)
    distance = (middle - right)
    rightMiddle -= distance
    middle -= distance
    mergeWithoutBuffer(rightMiddle, (rightMiddle + distance), finish)
    mergeWithoutBuffer(start, middle, rightMiddle)
  end
  def inPlaceMergeSort(start, finish)
    buildRuns(start, finish)
    run = @minRun
    while (run < (finish - start))
      index = start
      while ((index + (2 * run)) <= finish)
        smartInPlaceMerge(index, (index + run), (index + (2 * run)))
        index += (2 * run)
      end
      if ((index + run) < finish)
        smartInPlaceMerge(index, (index + run), finish)
      end
      run *= 2
    end
  end
  def adaptiveSortWithoutBuffer(startIn, endIn, keys, ideal, backwardBuffer)
    start = startIn
    finish = endIn
    length = (finish - start)
    blockLength = [keys, @minRun].min
    while ((2 * blockLength) <= keys)
      blockLength *= 2
    end
    tagLength = (keys - blockLength)
    runLength = @minRun
    tags = nil
    buffer = nil
    dataStart = nil
    dataEnd = nil
    if backwardBuffer
      buffer = (finish - blockLength)
      dataStart = start
      dataEnd = (buffer - tagLength)
      tags = dataEnd
    else
      buffer = (start + tagLength)
      dataStart = (buffer + blockLength)
      dataEnd = finish
      tags = start
    end
    buildRuns(dataStart, dataEnd)
    while ((runLength <= blockLength) && (runLength < length))
      index = dataStart
      while ((index + (2 * runLength)) <= dataEnd)
        smartMerge(index, (index + runLength), (index + (2 * runLength)), buffer)
        index += (2 * runLength)
      end
      if ((index + runLength) < dataEnd)
        smartMergeBackward(index, (index + runLength), dataEnd, buffer)
      end
      runLength *= 2
    end
    if (((blockLength / 2) >= @minRun) && ((blockLength / 2) >= ((keys + 1) / 2)))
      binaryInsertion(buffer, (buffer + blockLength))
      blockLength /= 2
      tagLength = (keys - blockLength)
      buffer += blockLength
    end
    while ((tagLength >= (((2 * runLength) / blockLength) - 1)) && (runLength < length))
      index = dataStart
      while ((index + (2 * runLength)) <= dataEnd)
        smartBlockMerge(index, (index + runLength), (index + (2 * runLength)), tags, buffer, blockLength)
        index += (2 * runLength)
      end
      if ((index + runLength) < dataEnd)
        if ((dataEnd - (index + runLength)) > blockLength)
          smartBlockMerge(index, (index + runLength), dataEnd, tags, buffer, blockLength)
        else
          smartMergeBackward(index, (index + runLength), dataEnd, buffer)
        end
      end
      runLength *= 2
    end
    binaryInsertion(buffer, (buffer + blockLength))
    tagLength = (keys - (keys % 2))
    while (runLength < length)
      blockLength = ((2 * runLength) / tagLength)
      index = dataStart
      while ((index + (2 * runLength)) <= dataEnd)
        smartBlockMergeWithoutBuffer(index, (index + runLength), (index + (2 * runLength)), tags, blockLength)
        index += (2 * runLength)
      end
      if ((index + runLength) < dataEnd)
        if ((dataEnd - (index + runLength)) > blockLength)
          smartBlockMergeWithoutBuffer(index, (index + runLength), dataEnd, tags, blockLength)
        else
          smartInPlaceMerge(index, (index + runLength), dataEnd)
        end
      end
      runLength *= 2
    end
    if backwardBuffer
      start = rightBinarySearch(start, dataEnd, read(dataEnd))
      if (keys >= (ideal / 2))
        redistributeBufferBackward(start, dataEnd, finish)
      else
        mergeWithoutBuffer(start, dataEnd, finish)
      end
    else
      finish = leftBinarySearch(dataStart, finish, read((dataStart - 1)))
      if (keys >= (ideal / 2))
        redistributeBuffer(start, dataStart, finish)
      else
        mergeWithoutBuffer(start, dataStart, finish)
      end
    end
  end
  def sort(startIn, endIn)
    start = startIn
    finish = endIn
    length = (finish - start)
    if (length < 31)
      binaryInsertion(start, finish)
      return
    end
    if (length < 63)
      @minRun = ((length + 1) / 2)
      buildRuns(start, finish)
      middle = (start + @minRun)
      if checkBounds(start, middle, finish)
        redistributeBufferBackward(start, middle, finish)
      end
      return
    end
    @minRun = length
    while (@minRun >= 32)
      @minRun = ((@minRun + 1) / 2)
    end
    blockLength = @minRun
    while ((blockLength * blockLength) < length)
      blockLength *= 2
    end
    tagLength = ((length / blockLength) - 2)
    ideal = (tagLength + blockLength)
    rightRun = buildUniqueRunBackward(finish, ideal)
    leftRun = 0
    backwardBuffer = nil
    if (rightRun == ideal)
      backwardBuffer = true
    else
      leftRun = buildUniqueRun(start, ideal)
      if (leftRun == ideal)
        backwardBuffer = false
      else
        backwardBuffer = (((rightRun < 16) && (leftRun < 16)) || (rightRun >= leftRun))
      end
    end
    keys = (backwardBuffer ? findKeysBackward(start, finish, rightRun, ideal) : findKeys(start, finish, leftRun, ideal))
    if (keys < ideal)
      if (keys == 1)
        return
      end
      if (keys <= 4)
        inPlaceMergeSort(start, finish)
      else
        adaptiveSortWithoutBuffer(start, finish, keys, ideal, backwardBuffer)
      end
      return
    end
    buffer = nil
    dataStart = nil
    dataEnd = nil
    tags = nil
    if backwardBuffer
      buffer = (finish - blockLength)
      dataStart = start
      dataEnd = (buffer - tagLength)
      tags = dataEnd
    else
      buffer = (start + tagLength)
      dataStart = (buffer + blockLength)
      dataEnd = finish
      tags = start
    end
    buildRuns(dataStart, dataEnd)
    runLength = @minRun
    while ((runLength <= blockLength) && (runLength < length))
      index = dataStart
      while ((index + (2 * runLength)) <= dataEnd)
        smartMerge(index, (index + runLength), (index + (2 * runLength)), buffer)
        index += (2 * runLength)
      end
      if ((index + runLength) < dataEnd)
        smartMergeBackward(index, (index + runLength), dataEnd, buffer)
      end
      runLength *= 2
    end
    while (runLength < length)
      index = dataStart
      while ((index + (2 * runLength)) <= dataEnd)
        smartBlockMerge(index, (index + runLength), (index + (2 * runLength)), tags, buffer, blockLength)
        index += (2 * runLength)
      end
      if ((index + runLength) < dataEnd)
        if ((dataEnd - (index + runLength)) > blockLength)
          smartBlockMerge(index, (index + runLength), dataEnd, tags, buffer, blockLength)
        else
          smartMergeBackward(index, (index + runLength), dataEnd, buffer)
        end
      end
      runLength *= 2
    end
    binaryInsertion(buffer, (buffer + blockLength))
    if backwardBuffer
      start = rightBinarySearch(start, dataEnd, read(dataEnd))
      redistributeBufferBackward(start, dataEnd, finish)
    else
      finish = leftBinarySearch(dataStart, finish, read((dataStart - 1)))
      redistributeBuffer(start, dataStart, finish)
    end
  end
end
def sort(values)
  sorter = AdaptiveGrailExample.new(values)
  sorter.sort(0, values.length)
end
array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
puts array.inspect
