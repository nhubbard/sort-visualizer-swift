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

#include <algorithm>
#include <iostream>
#include <tuple>
#include <vector>

class AdaptiveGrailExample {
public:
  int* values;
  int minRun;
  AdaptiveGrailExample(int* input) {
    values = input;
    minRun = 16;
  }
  int read(int index) {
    return values[index];
  }
  void write(int index, int value) {
    values[index] = value;
  }
  void swap(int first, int second) {
    std::tie(values[first], values[second]) = std::make_tuple(values[second], values[first]);
  }
  int compare(int first, int second) {
    if ((values[first] < values[second])) {
      return -(1);
    }
    if ((values[first] > values[second])) {
      return 1;
    }
    return 0;
  }
  int compareValue(int index, int value) {
    if ((values[index] < value)) {
      return -(1);
    }
    if ((values[index] > value)) {
      return 1;
    }
    return 0;
  }
  void reverse(int start, int end) {
    int left, right;
    left = start;
    right = (end - 1);
    while ((left < right)) {
      std::tie(values[left], values[right]) = std::make_tuple(values[right], values[left]);
      left += 1;
      right -= 1;
    }
  }
  void multiSwap(int first, int second, int count) {
    int offset;
    if (!((count > 0))) {
      return;
    }
    for (offset = 0; offset < count; offset++) {
      swap((first + offset), (second + offset));
    }
  }
  void multiTriSwap(int first, int second, int third, int count) {
    int offset, value;
    if (!((count > 0))) {
      return;
    }
    for (offset = 0; offset < count; offset++) {
      value = read((first + offset));
      write((first + offset), read((second + offset)));
      write((second + offset), read((third + offset)));
      write((third + offset), value);
    }
  }
  void insertTo(int source, int destination) {
    int cursor, value;
    value = read(source);
    cursor = source;
    while ((cursor > destination)) {
      write(cursor, read((cursor - 1)));
      cursor -= 1;
    }
    write(destination, value);
  }
  void insertToBackward(int source, int destination) {
    int cursor, value;
    value = read(source);
    cursor = source;
    while ((cursor < destination)) {
      write(cursor, read((cursor + 1)));
      cursor += 1;
    }
    write(cursor, value);
  }
  void shift(int destination, int source, int end) {
    int offset;
    if (!((source < end))) {
      return;
    }
    for (offset = 0; offset < (end - source); offset++) {
      swap((destination + offset), (source + offset));
    }
  }
  void rotate(int startIn, int middleIn, int endIn) {
    int end, left, middle, right, start;
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
  int leftBinarySearch(int start, int end, int value) {
    int lower, middle, upper;
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
  int rightBinarySearch(int start, int end, int value) {
    int lower, middle, upper;
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
  int buildUniqueRun(int start, int limit) {
    int count, index, order;
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
  int buildUniqueRunBackward(int end, int limit) {
    int count, index, order;
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
  int findKeys(int start, int end, int initial, int needed) {
    int candidate, count, distance, index, keyEnd, keyStart, location;
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
  int findKeysBackward(int start, int end, int initial, int needed) {
    int candidate, count, distance, index, keyEnd, keyStart, location;
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
  void buildRuns(int start, int end) {
    int index, runStart;
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
  void binaryInsertion(int start, int end) {
    int index;
    if (!(((end - start) > 1))) {
      return;
    }
    for (index = (start + 1); index < end; index++) {
      insertTo(index, rightBinarySearch(start, index, read(index)));
    }
  }
  void mergeWithBufferRest(int start, int middle, int end, int buffer, int length) {
    int left, output, right;
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
  void mergeWithBuffer(int start, int middle, int end, int buffer) {
    int length;
    length = (middle - start);
    multiSwap(buffer, start, length);
    mergeWithBufferRest(start, middle, end, buffer, length);
  }
  void mergeWithBufferBackward(int start, int middle, int end, int buffer) {
    int left, length, output, right;
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
  void inPlaceMerge(int start, int middle, int end) {
    int left, next, right;
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
  void inPlaceMergeBackward(int start, int middle, int end) {
    int left, next, right;
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
  void mergeWithoutBuffer(int start, int middle, int end) {
    if (((middle - start) > (end - middle))) {
      inPlaceMergeBackward(start, middle, end);
    } else {
      inPlaceMerge(start, middle, end);
    }
  }
  bool checkSorted(int middle) {
    return (compare((middle - 1), middle) > 0);
  }
  bool checkReverseBounds(int start, int middle, int end) {
    if ((compare(start, (end - 1)) > 0)) {
      rotate(start, middle, end);
      return false;
    }
    return true;
  }
  bool checkBounds(int start, int middle, int end) {
    return (checkSorted(middle) && checkReverseBounds(start, middle, end));
  }
  int subarray(int tag, int middleKey) {
    return ((compare(tag, middleKey) < 0) ? 0 : 1);
  }
  int blockSelectSort(int position, int tags, int offset, int distance, int leftCount, int blockCount, int blockLength) {
    int candidate, index, limit, middleKey, minimum, order;
    middleKey = leftCount;
    index = 0;
    limit = (leftCount + 1);
    while ((index < (limit - 1))) {
      minimum = index;
      candidate = std::max((leftCount - offset), (index + 1));
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
  void sortKeys(int end, int buffer, int middleKey) {
    int index, left, right;
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
  void sortKeysWithoutBuffer(int end, int middleKey) {
    int index, left;
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
  int mergeBlocks(int start, int middle, int end, int destination, int reverseEqual) {
    int left, order, output, right;
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
  void blockMerge(int start, int middle, int end, int tags, int buffer, int blockLength) {
    int blockCount, fragment, group, key, lastFull, left, leftBlocks, leftCount, middleKey, rightBlocks;
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
  void blockMergeWithoutBuffer(int start, int middle, int end, int tags, int blockLength) {
    int blockCount, end2, firstFull, fragment, group, key, lastFull, left, leftBlocks, leftCount, middle2, middleKey, next, nextPosition, rightBlocks;
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
  void smartMerge(int start, int middle, int end, int buffer) {
    int trimmed;
    if (checkBounds(start, middle, end)) {
      trimmed = rightBinarySearch(start, (middle - 1), read(middle));
      mergeWithBuffer(trimmed, middle, end, buffer);
    }
  }
  void smartMergeBackward(int start, int middle, int end, int buffer) {
    int trimmed;
    if (checkBounds(start, middle, end)) {
      trimmed = leftBinarySearch((middle + 1), end, read((middle - 1)));
      mergeWithBufferBackward(start, middle, trimmed, buffer);
    }
  }
  void smartBlockMerge(int start, int middle, int end, int tags, int buffer, int blockLength) {
    int trimmedEnd, trimmedStart;
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
  void smartBlockMergeWithoutBuffer(int start, int middle, int end, int tags, int blockLength) {
    int trimmedStart;
    if (checkBounds(start, middle, end)) {
      trimmedStart = rightBinarySearch(start, (middle - 1), read(middle));
      if (((middle - trimmedStart) <= blockLength)) {
        inPlaceMerge(trimmedStart, middle, end);
      } else {
        blockMergeWithoutBuffer(trimmedStart, middle, end, tags, blockLength);
      }
    }
  }
  void smartInPlaceMerge(int start, int middle, int end) {
    if (checkSorted(middle)) {
      inPlaceMergeBackward(start, middle, end);
    }
  }
  void redistributeBuffer(int startIn, int middleIn, int end) {
    int distance, leftMiddle, middle, right, start;
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
  void redistributeBufferBackward(int start, int middleIn, int endIn) {
    int distance, end, middle, right, rightMiddle;
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
  void inPlaceMergeSort(int start, int end) {
    int index, run;
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
  void adaptiveSortWithoutBuffer(int startIn, int endIn, int keys, int ideal, int backwardBuffer) {
    int blockLength, buffer, dataEnd, dataStart, end, index, length, runLength, start, tagLength, tags;
    start = startIn;
    end = endIn;
    length = (end - start);
    blockLength = std::min(keys, minRun);
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
  void sort(int startIn, int endIn) {
    int backwardBuffer, blockLength, buffer, dataEnd, dataStart, end, ideal, index, keys, leftRun, length, middle, rightRun, runLength, start, tagLength, tags;
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
    backwardBuffer = 0;
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
    keys = (backwardBuffer ? findKeysBackward(start, end, rightRun, ideal) : findKeys(start, end, leftRun, ideal));
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
};

void adaptive_grail_sort(int* values, int length) {
  AdaptiveGrailExample(values).sort(0, length);
}

int main() {
  std::vector<int> values = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
  adaptive_grail_sort(values.data(), static_cast<int>(values.size()));
  std::cout << "[";
  for (size_t i = 0; i < values.size(); ++i) {
    if (i) std::cout << ", ";
    std::cout << values[i];
  }
  std::cout << "]\n";
}
