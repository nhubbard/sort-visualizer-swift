// MIT License
// Copyright (c) 2013 Andrey Astrelin
// Copyright (c) 2020 The Holy Grail Sort Project
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

class AdaptiveGrailExample(private val values: IntArray) {
  private var minRun = 16
  fun read(index: Int): Int {
    return values[index];
  }
  fun write(index: Int, value: Int) {
    values[index] = value;
  }
  fun swap(first: Int, second: Int) {
    var _sim0_0 = values[second]
    var _sim0_1 = values[first]
    values[first] = _sim0_0;
    values[second] = _sim0_1;
  }
  fun compare(first: Int, second: Int): Int {
    if ((values[first] < values[second])) {
      return -(1);
    }
    if ((values[first] > values[second])) {
      return 1;
    }
    return 0;
  }
  fun compareValue(index: Int, value: Int): Int {
    if ((values[index] < value)) {
      return -(1);
    }
    if ((values[index] > value)) {
      return 1;
    }
    return 0;
  }
  fun reverse(start: Int, end: Int) {
    var left = 0
    var right = 0
    left = start;
    right = (end - 1);
    while ((left < right)) {
      var _sim1_0 = values[right]
      var _sim1_1 = values[left]
      values[left] = _sim1_0;
      values[right] = _sim1_1;
      left += 1;
      right -= 1;
    }
  }
  fun multiSwap(first: Int, second: Int, count: Int) {
    var offset = 0
    if (!((count > 0))) {
      return;
    }
    for (offset in 0 until count) {
      swap((first + offset), (second + offset));
    }
  }
  fun multiTriSwap(first: Int, second: Int, third: Int, count: Int) {
    var offset = 0
    var value = 0
    if (!((count > 0))) {
      return;
    }
    for (offset in 0 until count) {
      value = read((first + offset));
      write((first + offset), read((second + offset)));
      write((second + offset), read((third + offset)));
      write((third + offset), value);
    }
  }
  fun insertTo(source: Int, destination: Int) {
    var cursor = 0
    var value = 0
    value = read(source);
    cursor = source;
    while ((cursor > destination)) {
      write(cursor, read((cursor - 1)));
      cursor -= 1;
    }
    write(destination, value);
  }
  fun insertToBackward(source: Int, destination: Int) {
    var cursor = 0
    var value = 0
    value = read(source);
    cursor = source;
    while ((cursor < destination)) {
      write(cursor, read((cursor + 1)));
      cursor += 1;
    }
    write(cursor, value);
  }
  fun shift(destination: Int, source: Int, end: Int) {
    var offset = 0
    if (!((source < end))) {
      return;
    }
    for (offset in 0 until (end - source)) {
      swap((destination + offset), (source + offset));
    }
  }
  fun rotate(startIn: Int, middleIn: Int, endIn: Int) {
    var end = 0
    var left = 0
    var middle = 0
    var right = 0
    var start = 0
    start = startIn;
    middle = middleIn;
    end = endIn;
    left = (middle - start);
    right = (end - middle);
    while (((left > 1) && (right > 1))) {
      if ((right < left)) {
        multiSwap((middle - right), middle, right);
        end -= right;
        middle -= right;
        left -= right;
      } else {
        multiSwap(start, middle, left);
        start += left;
        middle += left;
        right -= left;
      }
    }
    if ((right == 1)) {
      insertTo(middle, start);
    } else {
      if ((left == 1)) {
        insertToBackward(start, (end - 1));
      }
    }
  }
  fun leftBinarySearch(start: Int, end: Int, value: Int): Int {
    var lower = 0
    var middle = 0
    var upper = 0
    lower = start;
    upper = end;
    while ((lower < upper)) {
      middle = (lower + ((upper - lower) / 2));
      if ((values[middle] >= value)) {
        upper = middle;
      } else {
        lower = (middle + 1);
      }
    }
    return lower;
  }
  fun rightBinarySearch(start: Int, end: Int, value: Int): Int {
    var lower = 0
    var middle = 0
    var upper = 0
    lower = start;
    upper = end;
    while ((lower < upper)) {
      middle = (lower + ((upper - lower) / 2));
      if ((values[middle] > value)) {
        upper = middle;
      } else {
        lower = (middle + 1);
      }
    }
    return lower;
  }
  fun buildUniqueRun(start: Int, limit: Int): Int {
    var count = 0
    var index = 0
    var order = 0
    count = 1;
    index = (start + 1);
    order = compare((index - 1), index);
    if ((order < 0)) {
      index += 1;
      count += 1;
      while (((count < limit) && (compare((index - 1), index) < 0))) {
        index += 1;
        count += 1;
      }
    } else {
      if ((order > 0)) {
        index += 1;
        count += 1;
        while (((count < limit) && (compare((index - 1), index) > 0))) {
          index += 1;
          count += 1;
        }
        reverse(start, index);
      }
    }
    return count;
  }
  fun buildUniqueRunBackward(end: Int, limit: Int): Int {
    var count = 0
    var index = 0
    var order = 0
    count = 1;
    index = (end - 1);
    order = compare((index - 1), index);
    if ((order < 0)) {
      index -= 1;
      count += 1;
      while (((count < limit) && (compare((index - 1), index) < 0))) {
        index -= 1;
        count += 1;
      }
    } else {
      if ((order > 0)) {
        index -= 1;
        count += 1;
        while (((count < limit) && (compare((index - 1), index) > 0))) {
          index -= 1;
          count += 1;
        }
        reverse(index, end);
      }
    }
    return count;
  }
  fun findKeys(start: Int, end: Int, initial: Int, needed: Int): Int {
    var candidate = 0
    var count = 0
    var distance = 0
    var index = 0
    var keyEnd = 0
    var keyStart = 0
    var location = 0
    count = initial;
    keyStart = start;
    keyEnd = (start + count);
    index = keyEnd;
    while (((index < end) && (count < needed))) {
      candidate = read(index);
      location = leftBinarySearch(keyStart, keyEnd, candidate);
      if (((location == keyEnd) || (compareValue(location, candidate) != 0))) {
        rotate(keyStart, keyEnd, index);
        distance = (index - keyEnd);
        location += distance;
        keyStart += distance;
        keyEnd += distance;
        insertTo(keyEnd, location);
        count += 1;
        keyEnd += 1;
      }
      index += 1;
    }
    rotate(start, keyStart, keyEnd);
    return count;
  }
  fun findKeysBackward(start: Int, end: Int, initial: Int, needed: Int): Int {
    var candidate = 0
    var count = 0
    var distance = 0
    var index = 0
    var keyEnd = 0
    var keyStart = 0
    var location = 0
    count = initial;
    keyStart = (end - count);
    keyEnd = end;
    index = (keyStart - 1);
    while (((index >= start) && (count < needed))) {
      candidate = read(index);
      location = leftBinarySearch(keyStart, keyEnd, candidate);
      if (((location == keyEnd) || (compareValue(location, candidate) != 0))) {
        rotate((index + 1), keyStart, keyEnd);
        distance = (keyStart - (index + 1));
        location -= distance;
        keyEnd -= distance;
        keyStart -= (distance + 1);
        count += 1;
        insertToBackward(index, (location - 1));
      }
      index -= 1;
    }
    rotate(keyStart, keyEnd, end);
    return count;
  }
  fun buildRuns(start: Int, end: Int) {
    var index = 0
    var runStart = 0
    index = (start + 1);
    runStart = start;
    while ((index < end)) {
      if ((compare((index - 1), index) > 0)) {
        index += 1;
        while (((index < end) && (compare((index - 1), index) > 0))) {
          index += 1;
        }
        reverse(runStart, index);
      } else {
        index += 1;
        while (((index < end) && (compare((index - 1), index) <= 0))) {
          index += 1;
        }
      }
      if ((index < end)) {
        runStart = ((index - (((index - runStart) - 1) % minRun)) - 1);
      }
      while ((((index - runStart) < minRun) && (index < end))) {
        insertTo(index, rightBinarySearch(runStart, index, read(index)));
        index += 1;
      }
      runStart = index;
      index += 1;
    }
  }
  fun binaryInsertion(start: Int, end: Int) {
    var index = 0
    if (!(((end - start) > 1))) {
      return;
    }
    for (index in (start + 1) until end) {
      insertTo(index, rightBinarySearch(start, index, read(index)));
    }
  }
  fun mergeWithBufferRest(start: Int, middle: Int, end: Int, buffer: Int, length: Int) {
    var left = 0
    var output = 0
    var right = 0
    left = 0;
    right = middle;
    output = start;
    while (((left < length) && (right < end))) {
      if ((compare((buffer + left), right) <= 0)) {
        swap(output, (buffer + left));
        left += 1;
      } else {
        swap(output, right);
        right += 1;
      }
      output += 1;
    }
    while ((left < length)) {
      swap(output, (buffer + left));
      output += 1;
      left += 1;
    }
  }
  fun mergeWithBuffer(start: Int, middle: Int, end: Int, buffer: Int) {
    var length = 0
    length = (middle - start);
    multiSwap(buffer, start, length);
    mergeWithBufferRest(start, middle, end, buffer, length);
  }
  fun mergeWithBufferBackward(start: Int, middle: Int, end: Int, buffer: Int) {
    var left = 0
    var length = 0
    var output = 0
    var right = 0
    length = (end - middle);
    multiSwap(middle, buffer, length);
    left = (length - 1);
    right = (middle - 1);
    output = (end - 1);
    while (((left >= 0) && (right >= start))) {
      if ((compare((buffer + left), right) >= 0)) {
        swap(output, (buffer + left));
        left -= 1;
      } else {
        swap(output, right);
        right -= 1;
      }
      output -= 1;
    }
    while ((left >= 0)) {
      swap(output, (buffer + left));
      output -= 1;
      left -= 1;
    }
  }
  fun inPlaceMerge(start: Int, middle: Int, end: Int) {
    var left = 0
    var next = 0
    var right = 0
    left = start;
    right = middle;
    while (((left < right) && (right < end))) {
      if ((compare(left, right) > 0)) {
        next = leftBinarySearch((right + 1), end, read(left));
        rotate(left, right, next);
        left += (next - right);
        right = next;
      } else {
        left += 1;
      }
    }
  }
  fun inPlaceMergeBackward(start: Int, middle: Int, end: Int) {
    var left = 0
    var next = 0
    var right = 0
    left = (middle - 1);
    right = (end - 1);
    while (((right > left) && (left >= start))) {
      if ((compare(left, right) > 0)) {
        next = rightBinarySearch(start, left, read(right));
        rotate(next, (left + 1), (right + 1));
        right -= ((left + 1) - next);
        left = (next - 1);
      } else {
        right -= 1;
      }
    }
  }
  fun mergeWithoutBuffer(start: Int, middle: Int, end: Int) {
    if (((middle - start) > (end - middle))) {
      inPlaceMergeBackward(start, middle, end);
    } else {
      inPlaceMerge(start, middle, end);
    }
  }
  fun checkSorted(middle: Int): Boolean {
    return (compare((middle - 1), middle) > 0);
  }
  fun checkReverseBounds(start: Int, middle: Int, end: Int): Boolean {
    if ((compare(start, (end - 1)) > 0)) {
      rotate(start, middle, end);
      return false;
    }
    return true;
  }
  fun checkBounds(start: Int, middle: Int, end: Int): Boolean {
    return (checkSorted(middle) && checkReverseBounds(start, middle, end));
  }
  fun subarray(tag: Int, middleKey: Int): Int {
    return if (compare(tag, middleKey) < 0) 0 else 1;
  }
  fun blockSelectSort(position: Int, tags: Int, offset: Int, distance: Int, leftCount: Int, blockCount: Int, blockLength: Int): Int {
    var candidate = 0
    var index = 0
    var limit = 0
    var middleKey = 0
    var minimum = 0
    var order = 0
    middleKey = leftCount;
    index = 0;
    limit = (leftCount + 1);
    while ((index < (limit - 1))) {
      minimum = index;
      candidate = maxOf((leftCount - offset), (index + 1));
      while ((candidate < limit)) {
        order = compare(((position + distance) + (candidate * blockLength)), ((position + distance) + (minimum * blockLength)));
        if (((order < 0) || ((order == 0) && (compare((tags + candidate), (tags + minimum)) < 0)))) {
          minimum = candidate;
        }
        candidate += 1;
      }
      if ((minimum != index)) {
        multiSwap((position + (index * blockLength)), (position + (minimum * blockLength)), blockLength);
        swap((tags + index), (tags + minimum));
        if (((limit < blockCount) && (minimum == (limit - 1)))) {
          limit += 1;
        }
      }
      if ((minimum == middleKey)) {
        middleKey = index;
      }
      index += 1;
    }
    return (tags + middleKey);
  }
  fun sortKeys(end: Int, buffer: Int, middleKey: Int) {
    var index = 0
    var left = 0
    var right = 0
    swap(buffer, middleKey);
    left = middleKey;
    index = (left + 1);
    right = (buffer + 1);
    while ((index < end)) {
      if ((compare(index, buffer) < 0)) {
        swap(left, index);
        left += 1;
      } else {
        swap(right, index);
        right += 1;
      }
      index += 1;
    }
    multiSwap(left, buffer, (end - left));
  }
  fun sortKeysWithoutBuffer(end: Int, middleKey: Int) {
    var index = 0
    var left = 0
    left = middleKey;
    index = (left + 1);
    while ((index < end)) {
      if ((compare(index, left) < 0)) {
        insertTo(index, left);
        left += 1;
      }
      index += 1;
    }
  }
  fun mergeBlocks(start: Int, middle: Int, end: Int, destination: Int, reverseEqual: Boolean): Int {
    var left = 0
    var order = 0
    var output = 0
    var right = 0
    left = start;
    right = middle;
    output = destination;
    while (((left < middle) && (right < end))) {
      order = compare(left, right);
      if (((order < 0) || ((order == 0) && !(reverseEqual)))) {
        swap(output, left);
        left += 1;
      } else {
        swap(output, right);
        right += 1;
      }
      output += 1;
    }
    if ((left > output)) {
      while ((left < middle)) {
        swap(output, left);
        output += 1;
        left += 1;
      }
    }
    return right;
  }
  fun blockMerge(start: Int, middle: Int, end: Int, tags: Int, buffer: Int, blockLength: Int) {
    var blockCount = 0
    var fragment = 0
    var group = 0
    var key = 0
    var lastFull = 0
    var left = 0
    var leftBlocks = 0
    var leftCount = 0
    var middleKey = 0
    var rightBlocks = 0
    lastFull = ((end - (((end - middle) - 1) % blockLength)) - 1);
    left = (start + blockLength);
    group = start;
    key = (tags - 1);
    leftCount = ((middle - left) / blockLength);
    blockCount = ((lastFull - left) / blockLength);
    leftBlocks = -(1);
    rightBlocks = (leftCount - 1);
    multiTriSwap(buffer, (middle - blockLength), start, blockLength);
    insertToBackward(tags, ((tags + leftCount) - 1));
    middleKey = blockSelectSort(left, tags, 1, (blockLength - 1), leftCount, blockCount, blockLength);
    fragment = 0;
    while (((leftBlocks < leftCount) && (rightBlocks < blockCount))) {
      if ((fragment == 0)) {
        while (true) {
          group += blockLength;
          leftBlocks += 1;
          key += 1;
          if (!(((leftBlocks < leftCount) && (subarray(key, middleKey) == 0)))) {
            break;
          }
        }
        if ((leftBlocks == leftCount)) {
          left = mergeBlocks(left, group, end, (left - blockLength), false);
          mergeWithBufferRest((left - blockLength), left, end, buffer, blockLength);
        } else {
          left = mergeBlocks(left, group, ((group + blockLength) - 1), (left - blockLength), false);
        }
        fragment = 1;
      } else {
        while (true) {
          group += blockLength;
          rightBlocks += 1;
          key += 1;
          if (!(((rightBlocks < blockCount) && (subarray(key, middleKey) == 1)))) {
            break;
          }
        }
        if ((rightBlocks == blockCount)) {
          shift((left - blockLength), left, end);
          multiSwap(buffer, (end - blockLength), blockLength);
        } else {
          left = mergeBlocks(left, group, ((group + blockLength) - 1), (left - blockLength), true);
        }
        fragment = 0;
      }
    }
    sortKeys((tags + blockCount), buffer, middleKey);
  }
  fun blockMergeWithoutBuffer(start: Int, middle: Int, end: Int, tags: Int, blockLength: Int) {
    var blockCount = 0
    var end2 = 0
    var firstFull = 0
    var fragment = 0
    var group = 0
    var key = 0
    var lastFull = 0
    var left = 0
    var leftBlocks = 0
    var leftCount = 0
    var middle2 = 0
    var middleKey = 0
    var next = 0
    var nextPosition = 0
    var rightBlocks = 0
    firstFull = (start + ((middle - start) % blockLength));
    lastFull = (end - ((end - middle) % blockLength));
    left = start;
    group = firstFull;
    key = tags;
    leftCount = (((middle - group) / blockLength) + 1);
    blockCount = (((lastFull - group) / blockLength) + 1);
    leftBlocks = 0;
    rightBlocks = leftCount;
    middleKey = blockSelectSort(group, tags, 0, 0, (leftCount - 1), (blockCount - 1), blockLength);
    fragment = 0;
    while (((leftBlocks < leftCount) && (rightBlocks < blockCount))) {
      next = subarray(key, middleKey);
      key += 1;
      if ((next == fragment)) {
        if ((fragment == 0)) {
          leftBlocks += 1;
        } else {
          rightBlocks += 1;
        }
        left = group;
      } else {
        middle2 = group;
        end2 = (group + blockLength);
        if ((fragment == 0)) {
          while (((left < middle2) && (middle2 < end2))) {
            if ((compare(left, middle2) > 0)) {
              nextPosition = leftBinarySearch((middle2 + 1), end2, read(left));
              rotate(left, middle2, nextPosition);
              left += (nextPosition - middle2);
              middle2 = nextPosition;
            } else {
              left += 1;
            }
          }
        } else {
          while (((left < middle2) && (middle2 < end2))) {
            if ((compare(left, middle2) >= 0)) {
              nextPosition = rightBinarySearch((middle2 + 1), end2, read(left));
              rotate(left, middle2, nextPosition);
              left += (nextPosition - middle2);
              middle2 = nextPosition;
            } else {
              left += 1;
            }
          }
        }
        if ((left < middle2)) {
          if ((next == 0)) {
            leftBlocks += 1;
          } else {
            rightBlocks += 1;
          }
        } else {
          if ((fragment == 0)) {
            leftBlocks += 1;
          } else {
            rightBlocks += 1;
          }
          fragment = next;
        }
      }
      group += blockLength;
    }
    if ((leftBlocks < leftCount)) {
      inPlaceMergeBackward(start, lastFull, end);
    }
    sortKeysWithoutBuffer(((tags + blockCount) - 1), middleKey);
  }
  fun smartMerge(start: Int, middle: Int, end: Int, buffer: Int) {
    var trimmed = 0
    if (checkBounds(start, middle, end)) {
      trimmed = rightBinarySearch(start, (middle - 1), read(middle));
      mergeWithBuffer(trimmed, middle, end, buffer);
    }
  }
  fun smartMergeBackward(start: Int, middle: Int, end: Int, buffer: Int) {
    var trimmed = 0
    if (checkBounds(start, middle, end)) {
      trimmed = leftBinarySearch((middle + 1), end, read((middle - 1)));
      mergeWithBufferBackward(start, middle, trimmed, buffer);
    }
  }
  fun smartBlockMerge(start: Int, middle: Int, end: Int, tags: Int, buffer: Int, blockLength: Int) {
    var trimmedEnd = 0
    var trimmedStart = 0
    if (checkBounds(start, middle, end)) {
      trimmedStart = rightBinarySearch(start, (middle - 1), read(middle));
      trimmedEnd = leftBinarySearch((middle + 1), end, read((middle - 1)));
      if (checkReverseBounds(trimmedStart, middle, trimmedEnd)) {
        if ((((middle - trimmedStart) <= blockLength) || ((trimmedEnd - middle) <= blockLength))) {
          if (((trimmedEnd - middle) < (middle - trimmedStart))) {
            mergeWithBufferBackward(trimmedStart, middle, trimmedEnd, buffer);
          } else {
            mergeWithBuffer(trimmedStart, middle, trimmedEnd, buffer);
          }
        } else {
          trimmedStart -= ((trimmedStart - start) % blockLength);
          blockMerge(trimmedStart, middle, trimmedEnd, tags, buffer, blockLength);
        }
      }
    }
  }
  fun smartBlockMergeWithoutBuffer(start: Int, middle: Int, end: Int, tags: Int, blockLength: Int) {
    var trimmedStart = 0
    if (checkBounds(start, middle, end)) {
      trimmedStart = rightBinarySearch(start, (middle - 1), read(middle));
      if (((middle - trimmedStart) <= blockLength)) {
        inPlaceMerge(trimmedStart, middle, end);
      } else {
        blockMergeWithoutBuffer(trimmedStart, middle, end, tags, blockLength);
      }
    }
  }
  fun smartInPlaceMerge(start: Int, middle: Int, end: Int) {
    if (checkSorted(middle)) {
      inPlaceMergeBackward(start, middle, end);
    }
  }
  fun redistributeBuffer(startIn: Int, middleIn: Int, end: Int) {
    var distance = 0
    var leftMiddle = 0
    var middle = 0
    var right = 0
    var start = 0
    start = startIn;
    middle = middleIn;
    right = leftBinarySearch(middle, end, read(start));
    rotate(start, middle, right);
    distance = (right - middle);
    start += distance;
    middle += distance;
    leftMiddle = (start + ((middle - start) / 2));
    right = leftBinarySearch(middle, end, read(leftMiddle));
    rotate(leftMiddle, middle, right);
    distance = (right - middle);
    leftMiddle += distance;
    middle += distance;
    mergeWithoutBuffer(start, (leftMiddle - distance), leftMiddle);
    mergeWithoutBuffer(leftMiddle, middle, end);
  }
  fun redistributeBufferBackward(start: Int, middleIn: Int, endIn: Int) {
    var distance = 0
    var end = 0
    var middle = 0
    var right = 0
    var rightMiddle = 0
    middle = middleIn;
    end = endIn;
    right = rightBinarySearch(start, middle, read((end - 1)));
    rotate(right, middle, end);
    distance = (middle - right);
    end -= distance;
    middle -= distance;
    rightMiddle = (middle + ((end - middle) / 2));
    right = rightBinarySearch(start, middle, read((rightMiddle - 1)));
    rotate(right, middle, rightMiddle);
    distance = (middle - right);
    rightMiddle -= distance;
    middle -= distance;
    mergeWithoutBuffer(rightMiddle, (rightMiddle + distance), end);
    mergeWithoutBuffer(start, middle, rightMiddle);
  }
  fun inPlaceMergeSort(start: Int, end: Int) {
    var index = 0
    var run = 0
    buildRuns(start, end);
    run = minRun;
    while ((run < (end - start))) {
      index = start;
      while (((index + (2 * run)) <= end)) {
        smartInPlaceMerge(index, (index + run), (index + (2 * run)));
        index += (2 * run);
      }
      if (((index + run) < end)) {
        smartInPlaceMerge(index, (index + run), end);
      }
      run *= 2;
    }
  }
  fun adaptiveSortWithoutBuffer(startIn: Int, endIn: Int, keys: Int, ideal: Int, backwardBuffer: Boolean) {
    var blockLength = 0
    var buffer = 0
    var dataEnd = 0
    var dataStart = 0
    var end = 0
    var index = 0
    var length = 0
    var runLength = 0
    var start = 0
    var tagLength = 0
    var tags = 0
    start = startIn;
    end = endIn;
    length = (end - start);
    blockLength = minOf(keys, minRun);
    while (((2 * blockLength) <= keys)) {
      blockLength *= 2;
    }
    tagLength = (keys - blockLength);
    runLength = minRun;
    tags = 0;
    buffer = 0;
    dataStart = 0;
    dataEnd = 0;
    if (backwardBuffer) {
      buffer = (end - blockLength);
      dataStart = start;
      dataEnd = (buffer - tagLength);
      tags = dataEnd;
    } else {
      buffer = (start + tagLength);
      dataStart = (buffer + blockLength);
      dataEnd = end;
      tags = start;
    }
    buildRuns(dataStart, dataEnd);
    while (((runLength <= blockLength) && (runLength < length))) {
      index = dataStart;
      while (((index + (2 * runLength)) <= dataEnd)) {
        smartMerge(index, (index + runLength), (index + (2 * runLength)), buffer);
        index += (2 * runLength);
      }
      if (((index + runLength) < dataEnd)) {
        smartMergeBackward(index, (index + runLength), dataEnd, buffer);
      }
      runLength *= 2;
    }
    if ((((blockLength / 2) >= minRun) && ((blockLength / 2) >= ((keys + 1) / 2)))) {
      binaryInsertion(buffer, (buffer + blockLength));
      blockLength = (blockLength / 2);
      tagLength = (keys - blockLength);
      buffer += blockLength;
    }
    while (((tagLength >= (((2 * runLength) / blockLength) - 1)) && (runLength < length))) {
      index = dataStart;
      while (((index + (2 * runLength)) <= dataEnd)) {
        smartBlockMerge(index, (index + runLength), (index + (2 * runLength)), tags, buffer, blockLength);
        index += (2 * runLength);
      }
      if (((index + runLength) < dataEnd)) {
        if (((dataEnd - (index + runLength)) > blockLength)) {
          smartBlockMerge(index, (index + runLength), dataEnd, tags, buffer, blockLength);
        } else {
          smartMergeBackward(index, (index + runLength), dataEnd, buffer);
        }
      }
      runLength *= 2;
    }
    binaryInsertion(buffer, (buffer + blockLength));
    tagLength = (keys - (keys % 2));
    while ((runLength < length)) {
      blockLength = ((2 * runLength) / tagLength);
      index = dataStart;
      while (((index + (2 * runLength)) <= dataEnd)) {
        smartBlockMergeWithoutBuffer(index, (index + runLength), (index + (2 * runLength)), tags, blockLength);
        index += (2 * runLength);
      }
      if (((index + runLength) < dataEnd)) {
        if (((dataEnd - (index + runLength)) > blockLength)) {
          smartBlockMergeWithoutBuffer(index, (index + runLength), dataEnd, tags, blockLength);
        } else {
          smartInPlaceMerge(index, (index + runLength), dataEnd);
        }
      }
      runLength *= 2;
    }
    if (backwardBuffer) {
      start = rightBinarySearch(start, dataEnd, read(dataEnd));
      if ((keys >= (ideal / 2))) {
        redistributeBufferBackward(start, dataEnd, end);
      } else {
        mergeWithoutBuffer(start, dataEnd, end);
      }
    } else {
      end = leftBinarySearch(dataStart, end, read((dataStart - 1)));
      if ((keys >= (ideal / 2))) {
        redistributeBuffer(start, dataStart, end);
      } else {
        mergeWithoutBuffer(start, dataStart, end);
      }
    }
  }
  fun sort(startIn: Int, endIn: Int) {
    var backwardBuffer = false
    var blockLength = 0
    var buffer = 0
    var dataEnd = 0
    var dataStart = 0
    var end = 0
    var ideal = 0
    var index = 0
    var keys = 0
    var leftRun = 0
    var length = 0
    var middle = 0
    var rightRun = 0
    var runLength = 0
    var start = 0
    var tagLength = 0
    var tags = 0
    start = startIn;
    end = endIn;
    length = (end - start);
    if ((length < 31)) {
      binaryInsertion(start, end);
      return;
    }
    if ((length < 63)) {
      minRun = ((length + 1) / 2);
      buildRuns(start, end);
      middle = (start + minRun);
      if (checkBounds(start, middle, end)) {
        redistributeBufferBackward(start, middle, end);
      }
      return;
    }
    minRun = length;
    while ((minRun >= 32)) {
      minRun = ((minRun + 1) / 2);
    }
    blockLength = minRun;
    while (((blockLength * blockLength) < length)) {
      blockLength *= 2;
    }
    tagLength = ((length / blockLength) - 2);
    ideal = (tagLength + blockLength);
    rightRun = buildUniqueRunBackward(end, ideal);
    leftRun = 0;
    backwardBuffer = false;
    if ((rightRun == ideal)) {
      backwardBuffer = true;
    } else {
      leftRun = buildUniqueRun(start, ideal);
      if ((leftRun == ideal)) {
        backwardBuffer = false;
      } else {
        backwardBuffer = (((rightRun < 16) && (leftRun < 16)) || (rightRun >= leftRun));
      }
    }
    keys = if (backwardBuffer) findKeysBackward(start, end, rightRun, ideal) else findKeys(start, end, leftRun, ideal);
    if ((keys < ideal)) {
      if ((keys == 1)) {
        return;
      }
      if ((keys <= 4)) {
        inPlaceMergeSort(start, end);
      } else {
        adaptiveSortWithoutBuffer(start, end, keys, ideal, backwardBuffer);
      }
      return;
    }
    buffer = 0;
    dataStart = 0;
    dataEnd = 0;
    tags = 0;
    if (backwardBuffer) {
      buffer = (end - blockLength);
      dataStart = start;
      dataEnd = (buffer - tagLength);
      tags = dataEnd;
    } else {
      buffer = (start + tagLength);
      dataStart = (buffer + blockLength);
      dataEnd = end;
      tags = start;
    }
    buildRuns(dataStart, dataEnd);
    runLength = minRun;
    while (((runLength <= blockLength) && (runLength < length))) {
      index = dataStart;
      while (((index + (2 * runLength)) <= dataEnd)) {
        smartMerge(index, (index + runLength), (index + (2 * runLength)), buffer);
        index += (2 * runLength);
      }
      if (((index + runLength) < dataEnd)) {
        smartMergeBackward(index, (index + runLength), dataEnd, buffer);
      }
      runLength *= 2;
    }
    while ((runLength < length)) {
      index = dataStart;
      while (((index + (2 * runLength)) <= dataEnd)) {
        smartBlockMerge(index, (index + runLength), (index + (2 * runLength)), tags, buffer, blockLength);
        index += (2 * runLength);
      }
      if (((index + runLength) < dataEnd)) {
        if (((dataEnd - (index + runLength)) > blockLength)) {
          smartBlockMerge(index, (index + runLength), dataEnd, tags, buffer, blockLength);
        } else {
          smartMergeBackward(index, (index + runLength), dataEnd, buffer);
        }
      }
      runLength *= 2;
    }
    binaryInsertion(buffer, (buffer + blockLength));
    if (backwardBuffer) {
      start = rightBinarySearch(start, dataEnd, read(dataEnd));
      redistributeBufferBackward(start, dataEnd, end);
    } else {
      end = leftBinarySearch(dataStart, end, read((dataStart - 1)));
      redistributeBuffer(start, dataStart, end);
    }
  }
}

fun adaptiveGrailSort(values: IntArray) { AdaptiveGrailExample(values).sort(0, values.size) }

fun main() {
  val values = intArrayOf(0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56)
  adaptiveGrailSort(values)
  println(values.joinToString(prefix = "[", postfix = "]"))
}
