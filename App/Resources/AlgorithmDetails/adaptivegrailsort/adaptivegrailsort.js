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

class AdaptiveGrailExample {
  constructor(input) {
    this.values = input;
    this.minRun = 16;
  }
  read(index) {
    return this.values[index];
  }
  write(index, value) {
    this.values[index] = value;
  }
  swap(first, second) {
    [this.values[first], this.values[second]] = [
      this.values[second],
      this.values[first],
    ];
  }
  compare(first, second) {
    if (this.values[first] < this.values[second]) {
      return -1;
    }
    if (this.values[first] > this.values[second]) {
      return 1;
    }
    return 0;
  }
  compareValue(index, value) {
    if (this.values[index] < value) {
      return -1;
    }
    if (this.values[index] > value) {
      return 1;
    }
    return 0;
  }
  reverse(start, end) {
    let left, right;
    left = start;
    right = end - 1;
    while (left < right) {
      [this.values[left], this.values[right]] = [
        this.values[right],
        this.values[left],
      ];
      left += 1;
      right -= 1;
    }
  }
  multiSwap(first, second, count) {
    let offset;
    if (!(count > 0)) {
      return;
    }
    for (offset = 0; offset < count; offset++) {
      this.swap(first + offset, second + offset);
    }
  }
  multiTriSwap(first, second, third, count) {
    let offset, value;
    if (!(count > 0)) {
      return;
    }
    for (offset = 0; offset < count; offset++) {
      value = this.read(first + offset);
      this.write(first + offset, this.read(second + offset));
      this.write(second + offset, this.read(third + offset));
      this.write(third + offset, value);
    }
  }
  insertTo(source, destination) {
    let cursor, value;
    value = this.read(source);
    cursor = source;
    while (cursor > destination) {
      this.write(cursor, this.read(cursor - 1));
      cursor -= 1;
    }
    this.write(destination, value);
  }
  insertToBackward(source, destination) {
    let cursor, value;
    value = this.read(source);
    cursor = source;
    while (cursor < destination) {
      this.write(cursor, this.read(cursor + 1));
      cursor += 1;
    }
    this.write(cursor, value);
  }
  shift(destination, source, end) {
    let offset;
    if (!(source < end)) {
      return;
    }
    for (offset = 0; offset < end - source; offset++) {
      this.swap(destination + offset, source + offset);
    }
  }
  rotate(startIn, middleIn, endIn) {
    let end, left, middle, right, start;
    start = startIn;
    middle = middleIn;
    end = endIn;
    left = middle - start;
    right = end - middle;
    while (left > 1 && right > 1) {
      if (right < left) {
        this.multiSwap(middle - right, middle, right);
        end -= right;
        middle -= right;
        left -= right;
      } else {
        this.multiSwap(start, middle, left);
        start += left;
        middle += left;
        right -= left;
      }
    }
    if (right === 1) {
      this.insertTo(middle, start);
    } else {
      if (left === 1) {
        this.insertToBackward(start, end - 1);
      }
    }
  }
  leftBinarySearch(start, end, value) {
    let lower, middle, upper;
    lower = start;
    upper = end;
    while (lower < upper) {
      middle = lower + Math.floor((upper - lower) / 2);
      if (this.values[middle] >= value) {
        upper = middle;
      } else {
        lower = middle + 1;
      }
    }
    return lower;
  }
  rightBinarySearch(start, end, value) {
    let lower, middle, upper;
    lower = start;
    upper = end;
    while (lower < upper) {
      middle = lower + Math.floor((upper - lower) / 2);
      if (this.values[middle] > value) {
        upper = middle;
      } else {
        lower = middle + 1;
      }
    }
    return lower;
  }
  buildUniqueRun(start, limit) {
    let count, index, order;
    count = 1;
    index = start + 1;
    order = this.compare(index - 1, index);
    if (order < 0) {
      index += 1;
      count += 1;
      while (count < limit && this.compare(index - 1, index) < 0) {
        index += 1;
        count += 1;
      }
    } else {
      if (order > 0) {
        index += 1;
        count += 1;
        while (count < limit && this.compare(index - 1, index) > 0) {
          index += 1;
          count += 1;
        }
        this.reverse(start, index);
      }
    }
    return count;
  }
  buildUniqueRunBackward(end, limit) {
    let count, index, order;
    count = 1;
    index = end - 1;
    order = this.compare(index - 1, index);
    if (order < 0) {
      index -= 1;
      count += 1;
      while (count < limit && this.compare(index - 1, index) < 0) {
        index -= 1;
        count += 1;
      }
    } else {
      if (order > 0) {
        index -= 1;
        count += 1;
        while (count < limit && this.compare(index - 1, index) > 0) {
          index -= 1;
          count += 1;
        }
        this.reverse(index, end);
      }
    }
    return count;
  }
  findKeys(start, end, initial, needed) {
    let candidate, count, distance, index, keyEnd, keyStart, location;
    count = initial;
    keyStart = start;
    keyEnd = start + count;
    index = keyEnd;
    while (index < end && count < needed) {
      candidate = this.read(index);
      location = this.leftBinarySearch(keyStart, keyEnd, candidate);
      if (location === keyEnd || this.compareValue(location, candidate) !== 0) {
        this.rotate(keyStart, keyEnd, index);
        distance = index - keyEnd;
        location += distance;
        keyStart += distance;
        keyEnd += distance;
        this.insertTo(keyEnd, location);
        count += 1;
        keyEnd += 1;
      }
      index += 1;
    }
    this.rotate(start, keyStart, keyEnd);
    return count;
  }
  findKeysBackward(start, end, initial, needed) {
    let candidate, count, distance, index, keyEnd, keyStart, location;
    count = initial;
    keyStart = end - count;
    keyEnd = end;
    index = keyStart - 1;
    while (index >= start && count < needed) {
      candidate = this.read(index);
      location = this.leftBinarySearch(keyStart, keyEnd, candidate);
      if (location === keyEnd || this.compareValue(location, candidate) !== 0) {
        this.rotate(index + 1, keyStart, keyEnd);
        distance = keyStart - (index + 1);
        location -= distance;
        keyEnd -= distance;
        keyStart -= distance + 1;
        count += 1;
        this.insertToBackward(index, location - 1);
      }
      index -= 1;
    }
    this.rotate(keyStart, keyEnd, end);
    return count;
  }
  buildRuns(start, end) {
    let index, runStart;
    index = start + 1;
    runStart = start;
    while (index < end) {
      if (this.compare(index - 1, index) > 0) {
        index += 1;
        while (index < end && this.compare(index - 1, index) > 0) {
          index += 1;
        }
        this.reverse(runStart, index);
      } else {
        index += 1;
        while (index < end && this.compare(index - 1, index) <= 0) {
          index += 1;
        }
      }
      if (index < end) {
        runStart = index - ((index - runStart - 1) % this.minRun) - 1;
      }
      while (index - runStart < this.minRun && index < end) {
        this.insertTo(
          index,
          this.rightBinarySearch(runStart, index, this.read(index)),
        );
        index += 1;
      }
      runStart = index;
      index += 1;
    }
  }
  binaryInsertion(start, end) {
    let index;
    if (!(end - start > 1)) {
      return;
    }
    for (index = start + 1; index < end; index++) {
      this.insertTo(
        index,
        this.rightBinarySearch(start, index, this.read(index)),
      );
    }
  }
  mergeWithBufferRest(start, middle, end, buffer, length) {
    let left, output, right;
    left = 0;
    right = middle;
    output = start;
    while (left < length && right < end) {
      if (this.compare(buffer + left, right) <= 0) {
        this.swap(output, buffer + left);
        left += 1;
      } else {
        this.swap(output, right);
        right += 1;
      }
      output += 1;
    }
    while (left < length) {
      this.swap(output, buffer + left);
      output += 1;
      left += 1;
    }
  }
  mergeWithBuffer(start, middle, end, buffer) {
    let length;
    length = middle - start;
    this.multiSwap(buffer, start, length);
    this.mergeWithBufferRest(start, middle, end, buffer, length);
  }
  mergeWithBufferBackward(start, middle, end, buffer) {
    let left, length, output, right;
    length = end - middle;
    this.multiSwap(middle, buffer, length);
    left = length - 1;
    right = middle - 1;
    output = end - 1;
    while (left >= 0 && right >= start) {
      if (this.compare(buffer + left, right) >= 0) {
        this.swap(output, buffer + left);
        left -= 1;
      } else {
        this.swap(output, right);
        right -= 1;
      }
      output -= 1;
    }
    while (left >= 0) {
      this.swap(output, buffer + left);
      output -= 1;
      left -= 1;
    }
  }
  inPlaceMerge(start, middle, end) {
    let left, next, right;
    left = start;
    right = middle;
    while (left < right && right < end) {
      if (this.compare(left, right) > 0) {
        next = this.leftBinarySearch(right + 1, end, this.read(left));
        this.rotate(left, right, next);
        left += next - right;
        right = next;
      } else {
        left += 1;
      }
    }
  }
  inPlaceMergeBackward(start, middle, end) {
    let left, next, right;
    left = middle - 1;
    right = end - 1;
    while (right > left && left >= start) {
      if (this.compare(left, right) > 0) {
        next = this.rightBinarySearch(start, left, this.read(right));
        this.rotate(next, left + 1, right + 1);
        right -= left + 1 - next;
        left = next - 1;
      } else {
        right -= 1;
      }
    }
  }
  mergeWithoutBuffer(start, middle, end) {
    if (middle - start > end - middle) {
      this.inPlaceMergeBackward(start, middle, end);
    } else {
      this.inPlaceMerge(start, middle, end);
    }
  }
  checkSorted(middle) {
    return this.compare(middle - 1, middle) > 0;
  }
  checkReverseBounds(start, middle, end) {
    if (this.compare(start, end - 1) > 0) {
      this.rotate(start, middle, end);
      return false;
    }
    return true;
  }
  checkBounds(start, middle, end) {
    return (
      this.checkSorted(middle) && this.checkReverseBounds(start, middle, end)
    );
  }
  subarray(tag, middleKey) {
    return this.compare(tag, middleKey) < 0 ? "left" : "right";
  }
  blockSelectSort(
    position,
    tags,
    offset,
    distance,
    leftCount,
    blockCount,
    blockLength,
  ) {
    let candidate, index, limit, middleKey, minimum, order;
    middleKey = leftCount;
    index = 0;
    limit = leftCount + 1;
    while (index < limit - 1) {
      minimum = index;
      candidate = Math.max(leftCount - offset, index + 1);
      while (candidate < limit) {
        order = this.compare(
          position + distance + candidate * blockLength,
          position + distance + minimum * blockLength,
        );
        if (
          order < 0 ||
          (order === 0 && this.compare(tags + candidate, tags + minimum) < 0)
        ) {
          minimum = candidate;
        }
        candidate += 1;
      }
      if (minimum !== index) {
        this.multiSwap(
          position + index * blockLength,
          position + minimum * blockLength,
          blockLength,
        );
        this.swap(tags + index, tags + minimum);
        if (limit < blockCount && minimum === limit - 1) {
          limit += 1;
        }
      }
      if (minimum === middleKey) {
        middleKey = index;
      }
      index += 1;
    }
    return tags + middleKey;
  }
  sortKeys(end, buffer, middleKey) {
    let index, left, right;
    this.swap(buffer, middleKey);
    left = middleKey;
    index = left + 1;
    right = buffer + 1;
    while (index < end) {
      if (this.compare(index, buffer) < 0) {
        this.swap(left, index);
        left += 1;
      } else {
        this.swap(right, index);
        right += 1;
      }
      index += 1;
    }
    this.multiSwap(left, buffer, end - left);
  }
  sortKeysWithoutBuffer(end, middleKey) {
    let index, left;
    left = middleKey;
    index = left + 1;
    while (index < end) {
      if (this.compare(index, left) < 0) {
        this.insertTo(index, left);
        left += 1;
      }
      index += 1;
    }
  }
  mergeBlocks(start, middle, end, destination, reverseEqual) {
    let left, order, output, right;
    left = start;
    right = middle;
    output = destination;
    while (left < middle && right < end) {
      order = this.compare(left, right);
      if (order < 0 || (order === 0 && !reverseEqual)) {
        this.swap(output, left);
        left += 1;
      } else {
        this.swap(output, right);
        right += 1;
      }
      output += 1;
    }
    if (left > output) {
      while (left < middle) {
        this.swap(output, left);
        output += 1;
        left += 1;
      }
    }
    return right;
  }
  blockMerge(start, middle, end, tags, buffer, blockLength) {
    let blockCount,
      fragment,
      group,
      key,
      lastFull,
      left,
      leftBlocks,
      leftCount,
      middleKey,
      rightBlocks;
    lastFull = end - ((end - middle - 1) % blockLength) - 1;
    left = start + blockLength;
    group = start;
    key = tags - 1;
    leftCount = Math.floor((middle - left) / blockLength);
    blockCount = Math.floor((lastFull - left) / blockLength);
    leftBlocks = -1;
    rightBlocks = leftCount - 1;
    this.multiTriSwap(buffer, middle - blockLength, start, blockLength);
    this.insertToBackward(tags, tags + leftCount - 1);
    middleKey = this.blockSelectSort(
      left,
      tags,
      1,
      blockLength - 1,
      leftCount,
      blockCount,
      blockLength,
    );
    fragment = "left";
    while (leftBlocks < leftCount && rightBlocks < blockCount) {
      if (fragment === "left") {
        while (true) {
          group += blockLength;
          leftBlocks += 1;
          key += 1;
          if (!(
            leftBlocks < leftCount && this.subarray(key, middleKey) === "left"
          )) {
            break;
          }
        }
        if (leftBlocks === leftCount) {
          left = this.mergeBlocks(left, group, end, left - blockLength, false);
          this.mergeWithBufferRest(
            left - blockLength,
            left,
            end,
            buffer,
            blockLength,
          );
        } else {
          left = this.mergeBlocks(
            left,
            group,
            group + blockLength - 1,
            left - blockLength,
            false,
          );
        }
        fragment = "right";
      } else {
        while (true) {
          group += blockLength;
          rightBlocks += 1;
          key += 1;
          if (!(
            rightBlocks < blockCount &&
            this.subarray(key, middleKey) === "right"
          )) {
            break;
          }
        }
        if (rightBlocks === blockCount) {
          this.shift(left - blockLength, left, end);
          this.multiSwap(buffer, end - blockLength, blockLength);
        } else {
          left = this.mergeBlocks(
            left,
            group,
            group + blockLength - 1,
            left - blockLength,
            true,
          );
        }
        fragment = "left";
      }
    }
    this.sortKeys(tags + blockCount, buffer, middleKey);
  }
  blockMergeWithoutBuffer(start, middle, end, tags, blockLength) {
    let blockCount,
      end2,
      firstFull,
      fragment,
      group,
      key,
      lastFull,
      left,
      leftBlocks,
      leftCount,
      middle2,
      middleKey,
      next,
      nextPosition,
      rightBlocks;
    firstFull = start + ((middle - start) % blockLength);
    lastFull = end - ((end - middle) % blockLength);
    left = start;
    group = firstFull;
    key = tags;
    leftCount = Math.floor((middle - group) / blockLength) + 1;
    blockCount = Math.floor((lastFull - group) / blockLength) + 1;
    leftBlocks = 0;
    rightBlocks = leftCount;
    middleKey = this.blockSelectSort(
      group,
      tags,
      0,
      0,
      leftCount - 1,
      blockCount - 1,
      blockLength,
    );
    fragment = "left";
    while (leftBlocks < leftCount && rightBlocks < blockCount) {
      next = this.subarray(key, middleKey);
      key += 1;
      if (next === fragment) {
        if (fragment === "left") {
          leftBlocks += 1;
        } else {
          rightBlocks += 1;
        }
        left = group;
      } else {
        middle2 = group;
        end2 = group + blockLength;
        if (fragment === "left") {
          while (left < middle2 && middle2 < end2) {
            if (this.compare(left, middle2) > 0) {
              nextPosition = this.leftBinarySearch(
                middle2 + 1,
                end2,
                this.read(left),
              );
              this.rotate(left, middle2, nextPosition);
              left += nextPosition - middle2;
              middle2 = nextPosition;
            } else {
              left += 1;
            }
          }
        } else {
          while (left < middle2 && middle2 < end2) {
            if (this.compare(left, middle2) >= 0) {
              nextPosition = this.rightBinarySearch(
                middle2 + 1,
                end2,
                this.read(left),
              );
              this.rotate(left, middle2, nextPosition);
              left += nextPosition - middle2;
              middle2 = nextPosition;
            } else {
              left += 1;
            }
          }
        }
        if (left < middle2) {
          if (next === "left") {
            leftBlocks += 1;
          } else {
            rightBlocks += 1;
          }
        } else {
          if (fragment === "left") {
            leftBlocks += 1;
          } else {
            rightBlocks += 1;
          }
          fragment = next;
        }
      }
      group += blockLength;
    }
    if (leftBlocks < leftCount) {
      this.inPlaceMergeBackward(start, lastFull, end);
    }
    this.sortKeysWithoutBuffer(tags + blockCount - 1, middleKey);
  }
  smartMerge(start, middle, end, buffer) {
    let trimmed;
    if (this.checkBounds(start, middle, end)) {
      trimmed = this.rightBinarySearch(start, middle - 1, this.read(middle));
      this.mergeWithBuffer(trimmed, middle, end, buffer);
    }
  }
  smartMergeBackward(start, middle, end, buffer) {
    let trimmed;
    if (this.checkBounds(start, middle, end)) {
      trimmed = this.leftBinarySearch(middle + 1, end, this.read(middle - 1));
      this.mergeWithBufferBackward(start, middle, trimmed, buffer);
    }
  }
  smartBlockMerge(start, middle, end, tags, buffer, blockLength) {
    let trimmedEnd, trimmedStart;
    if (this.checkBounds(start, middle, end)) {
      trimmedStart = this.rightBinarySearch(
        start,
        middle - 1,
        this.read(middle),
      );
      trimmedEnd = this.leftBinarySearch(
        middle + 1,
        end,
        this.read(middle - 1),
      );
      if (this.checkReverseBounds(trimmedStart, middle, trimmedEnd)) {
        if (
          middle - trimmedStart <= blockLength ||
          trimmedEnd - middle <= blockLength
        ) {
          if (trimmedEnd - middle < middle - trimmedStart) {
            this.mergeWithBufferBackward(
              trimmedStart,
              middle,
              trimmedEnd,
              buffer,
            );
          } else {
            this.mergeWithBuffer(trimmedStart, middle, trimmedEnd, buffer);
          }
        } else {
          trimmedStart -= (trimmedStart - start) % blockLength;
          this.blockMerge(
            trimmedStart,
            middle,
            trimmedEnd,
            tags,
            buffer,
            blockLength,
          );
        }
      }
    }
  }
  smartBlockMergeWithoutBuffer(start, middle, end, tags, blockLength) {
    let trimmedStart;
    if (this.checkBounds(start, middle, end)) {
      trimmedStart = this.rightBinarySearch(
        start,
        middle - 1,
        this.read(middle),
      );
      if (middle - trimmedStart <= blockLength) {
        this.inPlaceMerge(trimmedStart, middle, end);
      } else {
        this.blockMergeWithoutBuffer(
          trimmedStart,
          middle,
          end,
          tags,
          blockLength,
        );
      }
    }
  }
  smartInPlaceMerge(start, middle, end) {
    if (this.checkSorted(middle)) {
      this.inPlaceMergeBackward(start, middle, end);
    }
  }
  redistributeBuffer(startIn, middleIn, end) {
    let distance, leftMiddle, middle, right, start;
    start = startIn;
    middle = middleIn;
    right = this.leftBinarySearch(middle, end, this.read(start));
    this.rotate(start, middle, right);
    distance = right - middle;
    start += distance;
    middle += distance;
    leftMiddle = start + Math.floor((middle - start) / 2);
    right = this.leftBinarySearch(middle, end, this.read(leftMiddle));
    this.rotate(leftMiddle, middle, right);
    distance = right - middle;
    leftMiddle += distance;
    middle += distance;
    this.mergeWithoutBuffer(start, leftMiddle - distance, leftMiddle);
    this.mergeWithoutBuffer(leftMiddle, middle, end);
  }
  redistributeBufferBackward(start, middleIn, endIn) {
    let distance, end, middle, right, rightMiddle;
    middle = middleIn;
    end = endIn;
    right = this.rightBinarySearch(start, middle, this.read(end - 1));
    this.rotate(right, middle, end);
    distance = middle - right;
    end -= distance;
    middle -= distance;
    rightMiddle = middle + Math.floor((end - middle) / 2);
    right = this.rightBinarySearch(start, middle, this.read(rightMiddle - 1));
    this.rotate(right, middle, rightMiddle);
    distance = middle - right;
    rightMiddle -= distance;
    middle -= distance;
    this.mergeWithoutBuffer(rightMiddle, rightMiddle + distance, end);
    this.mergeWithoutBuffer(start, middle, rightMiddle);
  }
  inPlaceMergeSort(start, end) {
    let index, run;
    this.buildRuns(start, end);
    run = this.minRun;
    while (run < end - start) {
      index = start;
      while (index + 2 * run <= end) {
        this.smartInPlaceMerge(index, index + run, index + 2 * run);
        index += 2 * run;
      }
      if (index + run < end) {
        this.smartInPlaceMerge(index, index + run, end);
      }
      run *= 2;
    }
  }
  adaptiveSortWithoutBuffer(startIn, endIn, keys, ideal, backwardBuffer) {
    let blockLength,
      buffer,
      dataEnd,
      dataStart,
      end,
      index,
      length,
      runLength,
      start,
      tagLength,
      tags;
    start = startIn;
    end = endIn;
    length = end - start;
    blockLength = Math.min(keys, this.minRun);
    while (2 * blockLength <= keys) {
      blockLength *= 2;
    }
    tagLength = keys - blockLength;
    runLength = this.minRun;
    tags = null;
    buffer = null;
    dataStart = null;
    dataEnd = null;
    if (backwardBuffer) {
      buffer = end - blockLength;
      dataStart = start;
      dataEnd = buffer - tagLength;
      tags = dataEnd;
    } else {
      buffer = start + tagLength;
      dataStart = buffer + blockLength;
      dataEnd = end;
      tags = start;
    }
    this.buildRuns(dataStart, dataEnd);
    while (runLength <= blockLength && runLength < length) {
      index = dataStart;
      while (index + 2 * runLength <= dataEnd) {
        this.smartMerge(
          index,
          index + runLength,
          index + 2 * runLength,
          buffer,
        );
        index += 2 * runLength;
      }
      if (index + runLength < dataEnd) {
        this.smartMergeBackward(index, index + runLength, dataEnd, buffer);
      }
      runLength *= 2;
    }
    if (
      Math.floor(blockLength / 2) >= this.minRun &&
      Math.floor(blockLength / 2) >= Math.floor((keys + 1) / 2)
    ) {
      this.binaryInsertion(buffer, buffer + blockLength);
      blockLength = Math.floor(blockLength / 2);
      tagLength = keys - blockLength;
      buffer += blockLength;
    }
    while (
      tagLength >= Math.floor((2 * runLength) / blockLength) - 1 &&
      runLength < length
    ) {
      index = dataStart;
      while (index + 2 * runLength <= dataEnd) {
        this.smartBlockMerge(
          index,
          index + runLength,
          index + 2 * runLength,
          tags,
          buffer,
          blockLength,
        );
        index += 2 * runLength;
      }
      if (index + runLength < dataEnd) {
        if (dataEnd - (index + runLength) > blockLength) {
          this.smartBlockMerge(
            index,
            index + runLength,
            dataEnd,
            tags,
            buffer,
            blockLength,
          );
        } else {
          this.smartMergeBackward(index, index + runLength, dataEnd, buffer);
        }
      }
      runLength *= 2;
    }
    this.binaryInsertion(buffer, buffer + blockLength);
    tagLength = keys - (keys % 2);
    while (runLength < length) {
      blockLength = Math.floor((2 * runLength + tagLength - 1) / tagLength);
      index = dataStart;
      while (index + 2 * runLength <= dataEnd) {
        this.smartBlockMergeWithoutBuffer(
          index,
          index + runLength,
          index + 2 * runLength,
          tags,
          blockLength,
        );
        index += 2 * runLength;
      }
      if (index + runLength < dataEnd) {
        if (dataEnd - (index + runLength) > blockLength) {
          this.smartBlockMergeWithoutBuffer(
            index,
            index + runLength,
            dataEnd,
            tags,
            blockLength,
          );
        } else {
          this.smartInPlaceMerge(index, index + runLength, dataEnd);
        }
      }
      runLength *= 2;
    }
    if (backwardBuffer) {
      start = this.rightBinarySearch(start, dataEnd, this.read(dataEnd));
      if (keys >= Math.floor(ideal / 2)) {
        this.redistributeBufferBackward(start, dataEnd, end);
      } else {
        this.mergeWithoutBuffer(start, dataEnd, end);
      }
    } else {
      end = this.leftBinarySearch(dataStart, end, this.read(dataStart - 1));
      if (keys >= Math.floor(ideal / 2)) {
        this.redistributeBuffer(start, dataStart, end);
      } else {
        this.mergeWithoutBuffer(start, dataStart, end);
      }
    }
  }
  sort(startIn, endIn) {
    let backwardBuffer,
      blockLength,
      buffer,
      dataEnd,
      dataStart,
      end,
      ideal,
      index,
      keys,
      leftRun,
      length,
      middle,
      rightRun,
      runLength,
      start,
      tagLength,
      tags;
    start = startIn;
    end = endIn;
    length = end - start;
    if (length < 31) {
      this.binaryInsertion(start, end);
      return;
    }
    if (length < 63) {
      this.minRun = Math.floor((length + 1) / 2);
      this.buildRuns(start, end);
      middle = start + this.minRun;
      if (this.checkBounds(start, middle, end)) {
        this.redistributeBufferBackward(start, middle, end);
      }
      return;
    }
    this.minRun = length;
    while (this.minRun >= 32) {
      this.minRun = Math.floor((this.minRun + 1) / 2);
    }
    blockLength = this.minRun;
    while (blockLength * blockLength < length) {
      blockLength *= 2;
    }
    tagLength = Math.floor(length / blockLength) - 2;
    ideal = tagLength + blockLength;
    rightRun = this.buildUniqueRunBackward(end, ideal);
    leftRun = 0;
    backwardBuffer = null;
    if (rightRun === ideal) {
      backwardBuffer = true;
    } else {
      leftRun = this.buildUniqueRun(start, ideal);
      if (leftRun === ideal) {
        backwardBuffer = false;
      } else {
        backwardBuffer = (rightRun < 16 && leftRun < 16) || rightRun >= leftRun;
      }
    }
    keys = backwardBuffer
      ? this.findKeysBackward(start, end, rightRun, ideal)
      : this.findKeys(start, end, leftRun, ideal);
    if (keys < ideal) {
      if (keys === 1) {
        return;
      }
      if (keys <= 4) {
        this.inPlaceMergeSort(start, end);
      } else {
        this.adaptiveSortWithoutBuffer(start, end, keys, ideal, backwardBuffer);
      }
      return;
    }
    buffer = null;
    dataStart = null;
    dataEnd = null;
    tags = null;
    if (backwardBuffer) {
      buffer = end - blockLength;
      dataStart = start;
      dataEnd = buffer - tagLength;
      tags = dataEnd;
    } else {
      buffer = start + tagLength;
      dataStart = buffer + blockLength;
      dataEnd = end;
      tags = start;
    }
    this.buildRuns(dataStart, dataEnd);
    runLength = this.minRun;
    while (runLength <= blockLength && runLength < length) {
      index = dataStart;
      while (index + 2 * runLength <= dataEnd) {
        this.smartMerge(
          index,
          index + runLength,
          index + 2 * runLength,
          buffer,
        );
        index += 2 * runLength;
      }
      if (index + runLength < dataEnd) {
        this.smartMergeBackward(index, index + runLength, dataEnd, buffer);
      }
      runLength *= 2;
    }
    while (runLength < length) {
      index = dataStart;
      while (index + 2 * runLength <= dataEnd) {
        this.smartBlockMerge(
          index,
          index + runLength,
          index + 2 * runLength,
          tags,
          buffer,
          blockLength,
        );
        index += 2 * runLength;
      }
      if (index + runLength < dataEnd) {
        if (dataEnd - (index + runLength) > blockLength) {
          this.smartBlockMerge(
            index,
            index + runLength,
            dataEnd,
            tags,
            buffer,
            blockLength,
          );
        } else {
          this.smartMergeBackward(index, index + runLength, dataEnd, buffer);
        }
      }
      runLength *= 2;
    }
    this.binaryInsertion(buffer, buffer + blockLength);
    if (backwardBuffer) {
      start = this.rightBinarySearch(start, dataEnd, this.read(dataEnd));
      this.redistributeBufferBackward(start, dataEnd, end);
    } else {
      end = this.leftBinarySearch(dataStart, end, this.read(dataStart - 1));
      this.redistributeBuffer(start, dataStart, end);
    }
  }
}
function sort(values) {
  let sorter;
  sorter = new AdaptiveGrailExample(values);
  sorter.sort(0, values.length);
}
const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
