// MIT License
// Copyright (c) 2013 Andrey Astrelin
// Copyright (c) 2020 The Holy Grail Sort Project
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <stdio.h>
#include <stdlib.h>

typedef struct {
  int *values, n, minRun;
} AdaptiveGrailExample;
static int min_int(int a, int b) { return a < b ? a : b; }
static int max_int(int a, int b) { return a > b ? a : b; }
int read(AdaptiveGrailExample *self, int index);
void write(AdaptiveGrailExample *self, int index, int value);
void swap(AdaptiveGrailExample *self, int first, int second);
int compare(AdaptiveGrailExample *self, int first, int second);
int compareValue(AdaptiveGrailExample *self, int index, int value);
void reverse(AdaptiveGrailExample *self, int start, int end);
void multiSwap(AdaptiveGrailExample *self, int first, int second, int count);
void multiTriSwap(AdaptiveGrailExample *self, int first, int second, int third,
                  int count);
void insertTo(AdaptiveGrailExample *self, int source, int destination);
void insertToBackward(AdaptiveGrailExample *self, int source, int destination);
void shift(AdaptiveGrailExample *self, int destination, int source, int end);
void rotate(AdaptiveGrailExample *self, int startIn, int middleIn, int endIn);
int leftBinarySearch(AdaptiveGrailExample *self, int start, int end, int value);
int rightBinarySearch(AdaptiveGrailExample *self, int start, int end,
                      int value);
int buildUniqueRun(AdaptiveGrailExample *self, int start, int limit);
int buildUniqueRunBackward(AdaptiveGrailExample *self, int end, int limit);
int findKeys(AdaptiveGrailExample *self, int start, int end, int initial,
             int needed);
int findKeysBackward(AdaptiveGrailExample *self, int start, int end,
                     int initial, int needed);
void buildRuns(AdaptiveGrailExample *self, int start, int end);
void binaryInsertion(AdaptiveGrailExample *self, int start, int end);
void mergeWithBufferRest(AdaptiveGrailExample *self, int start, int middle,
                         int end, int buffer, int length);
void mergeWithBuffer(AdaptiveGrailExample *self, int start, int middle, int end,
                     int buffer);
void mergeWithBufferBackward(AdaptiveGrailExample *self, int start, int middle,
                             int end, int buffer);
void inPlaceMerge(AdaptiveGrailExample *self, int start, int middle, int end);
void inPlaceMergeBackward(AdaptiveGrailExample *self, int start, int middle,
                          int end);
void mergeWithoutBuffer(AdaptiveGrailExample *self, int start, int middle,
                        int end);
int checkSorted(AdaptiveGrailExample *self, int middle);
int checkReverseBounds(AdaptiveGrailExample *self, int start, int middle,
                       int end);
int checkBounds(AdaptiveGrailExample *self, int start, int middle, int end);
int subarray(AdaptiveGrailExample *self, int tag, int middleKey);
int blockSelectSort(AdaptiveGrailExample *self, int position, int tags,
                    int offset, int distance, int leftCount, int blockCount,
                    int blockLength);
void sortKeys(AdaptiveGrailExample *self, int end, int buffer, int middleKey);
void sortKeysWithoutBuffer(AdaptiveGrailExample *self, int end, int middleKey);
int mergeBlocks(AdaptiveGrailExample *self, int start, int middle, int end,
                int destination, int reverseEqual);
void blockMerge(AdaptiveGrailExample *self, int start, int middle, int end,
                int tags, int buffer, int blockLength);
void blockMergeWithoutBuffer(AdaptiveGrailExample *self, int start, int middle,
                             int end, int tags, int blockLength);
void smartMerge(AdaptiveGrailExample *self, int start, int middle, int end,
                int buffer);
void smartMergeBackward(AdaptiveGrailExample *self, int start, int middle,
                        int end, int buffer);
void smartBlockMerge(AdaptiveGrailExample *self, int start, int middle, int end,
                     int tags, int buffer, int blockLength);
void smartBlockMergeWithoutBuffer(AdaptiveGrailExample *self, int start,
                                  int middle, int end, int tags,
                                  int blockLength);
void smartInPlaceMerge(AdaptiveGrailExample *self, int start, int middle,
                       int end);
void redistributeBuffer(AdaptiveGrailExample *self, int startIn, int middleIn,
                        int end);
void redistributeBufferBackward(AdaptiveGrailExample *self, int start,
                                int middleIn, int endIn);
void inPlaceMergeSort(AdaptiveGrailExample *self, int start, int end);
void adaptiveSortWithoutBuffer(AdaptiveGrailExample *self, int startIn,
                               int endIn, int keys, int ideal,
                               int backwardBuffer);
void sort(AdaptiveGrailExample *self, int startIn, int endIn);

int read(AdaptiveGrailExample *self, int index) { return self->values[index]; }
void write(AdaptiveGrailExample *self, int index, int value) {
  self->values[index] = value;
}
void swap(AdaptiveGrailExample *self, int first, int second) {
  int _sim0_0 = self->values[second];
  int _sim0_1 = self->values[first];
  self->values[first] = _sim0_0;
  self->values[second] = _sim0_1;
}
int compare(AdaptiveGrailExample *self, int first, int second) {
  if ((self->values[first] < self->values[second])) {
    return -(1);
  }
  if ((self->values[first] > self->values[second])) {
    return 1;
  }
  return 0;
}
int compareValue(AdaptiveGrailExample *self, int index, int value) {
  if ((self->values[index] < value)) {
    return -(1);
  }
  if ((self->values[index] > value)) {
    return 1;
  }
  return 0;
}
void reverse(AdaptiveGrailExample *self, int start, int end) {
  int left, right;
  left = start;
  right = (end - 1);
  while ((left < right)) {
    int _sim1_0 = self->values[right];
    int _sim1_1 = self->values[left];
    self->values[left] = _sim1_0;
    self->values[right] = _sim1_1;
    left += 1;
    right -= 1;
  }
}
void multiSwap(AdaptiveGrailExample *self, int first, int second, int count) {
  int offset;
  if (!((count > 0))) {
    return;
  }
  for (offset = 0; offset < count; offset++) {
    swap(self, (first + offset), (second + offset));
  }
}
void multiTriSwap(AdaptiveGrailExample *self, int first, int second, int third,
                  int count) {
  int offset, value;
  if (!((count > 0))) {
    return;
  }
  for (offset = 0; offset < count; offset++) {
    value = read(self, (first + offset));
    write(self, (first + offset), read(self, (second + offset)));
    write(self, (second + offset), read(self, (third + offset)));
    write(self, (third + offset), value);
  }
}
void insertTo(AdaptiveGrailExample *self, int source, int destination) {
  int cursor, value;
  value = read(self, source);
  cursor = source;
  while ((cursor > destination)) {
    write(self, cursor, read(self, (cursor - 1)));
    cursor -= 1;
  }
  write(self, destination, value);
}
void insertToBackward(AdaptiveGrailExample *self, int source, int destination) {
  int cursor, value;
  value = read(self, source);
  cursor = source;
  while ((cursor < destination)) {
    write(self, cursor, read(self, (cursor + 1)));
    cursor += 1;
  }
  write(self, cursor, value);
}
void shift(AdaptiveGrailExample *self, int destination, int source, int end) {
  int offset;
  if (!((source < end))) {
    return;
  }
  for (offset = 0; offset < (end - source); offset++) {
    swap(self, (destination + offset), (source + offset));
  }
}
void rotate(AdaptiveGrailExample *self, int startIn, int middleIn, int endIn) {
  int end, left, middle, right, start;
  start = startIn;
  middle = middleIn;
  end = endIn;
  left = (middle - start);
  right = (end - middle);
  while (((left > 1) && (right > 1))) {
    if ((right < left)) {
      multiSwap(self, (middle - right), middle, right);
      end -= right;
      middle -= right;
      left -= right;
    } else {
      multiSwap(self, start, middle, left);
      start += left;
      middle += left;
      right -= left;
    }
  }
  if ((right == 1)) {
    insertTo(self, middle, start);
  } else {
    if ((left == 1)) {
      insertToBackward(self, start, (end - 1));
    }
  }
}
int leftBinarySearch(AdaptiveGrailExample *self, int start, int end,
                     int value) {
  int lower, middle, upper;
  lower = start;
  upper = end;
  while ((lower < upper)) {
    middle = (lower + ((upper - lower) / 2));
    if ((self->values[middle] >= value)) {
      upper = middle;
    } else {
      lower = (middle + 1);
    }
  }
  return lower;
}
int rightBinarySearch(AdaptiveGrailExample *self, int start, int end,
                      int value) {
  int lower, middle, upper;
  lower = start;
  upper = end;
  while ((lower < upper)) {
    middle = (lower + ((upper - lower) / 2));
    if ((self->values[middle] > value)) {
      upper = middle;
    } else {
      lower = (middle + 1);
    }
  }
  return lower;
}
int buildUniqueRun(AdaptiveGrailExample *self, int start, int limit) {
  int count, index, order;
  count = 1;
  index = (start + 1);
  order = compare(self, (index - 1), index);
  if ((order < 0)) {
    index += 1;
    count += 1;
    while (((count < limit) && (compare(self, (index - 1), index) < 0))) {
      index += 1;
      count += 1;
    }
  } else {
    if ((order > 0)) {
      index += 1;
      count += 1;
      while (((count < limit) && (compare(self, (index - 1), index) > 0))) {
        index += 1;
        count += 1;
      }
      reverse(self, start, index);
    }
  }
  return count;
}
int buildUniqueRunBackward(AdaptiveGrailExample *self, int end, int limit) {
  int count, index, order;
  count = 1;
  index = (end - 1);
  order = compare(self, (index - 1), index);
  if ((order < 0)) {
    index -= 1;
    count += 1;
    while (((count < limit) && (compare(self, (index - 1), index) < 0))) {
      index -= 1;
      count += 1;
    }
  } else {
    if ((order > 0)) {
      index -= 1;
      count += 1;
      while (((count < limit) && (compare(self, (index - 1), index) > 0))) {
        index -= 1;
        count += 1;
      }
      reverse(self, index, end);
    }
  }
  return count;
}
int findKeys(AdaptiveGrailExample *self, int start, int end, int initial,
             int needed) {
  int candidate, count, distance, index, keyEnd, keyStart, location;
  count = initial;
  keyStart = start;
  keyEnd = (start + count);
  index = keyEnd;
  while (((index < end) && (count < needed))) {
    candidate = read(self, index);
    location = leftBinarySearch(self, keyStart, keyEnd, candidate);
    if (((location == keyEnd) ||
         (compareValue(self, location, candidate) != 0))) {
      rotate(self, keyStart, keyEnd, index);
      distance = (index - keyEnd);
      location += distance;
      keyStart += distance;
      keyEnd += distance;
      insertTo(self, keyEnd, location);
      count += 1;
      keyEnd += 1;
    }
    index += 1;
  }
  rotate(self, start, keyStart, keyEnd);
  return count;
}
int findKeysBackward(AdaptiveGrailExample *self, int start, int end,
                     int initial, int needed) {
  int candidate, count, distance, index, keyEnd, keyStart, location;
  count = initial;
  keyStart = (end - count);
  keyEnd = end;
  index = (keyStart - 1);
  while (((index >= start) && (count < needed))) {
    candidate = read(self, index);
    location = leftBinarySearch(self, keyStart, keyEnd, candidate);
    if (((location == keyEnd) ||
         (compareValue(self, location, candidate) != 0))) {
      rotate(self, (index + 1), keyStart, keyEnd);
      distance = (keyStart - (index + 1));
      location -= distance;
      keyEnd -= distance;
      keyStart -= (distance + 1);
      count += 1;
      insertToBackward(self, index, (location - 1));
    }
    index -= 1;
  }
  rotate(self, keyStart, keyEnd, end);
  return count;
}
void buildRuns(AdaptiveGrailExample *self, int start, int end) {
  int index, runStart;
  index = (start + 1);
  runStart = start;
  while ((index < end)) {
    if ((compare(self, (index - 1), index) > 0)) {
      index += 1;
      while (((index < end) && (compare(self, (index - 1), index) > 0))) {
        index += 1;
      }
      reverse(self, runStart, index);
    } else {
      index += 1;
      while (((index < end) && (compare(self, (index - 1), index) <= 0))) {
        index += 1;
      }
    }
    if ((index < end)) {
      runStart = ((index - (((index - runStart) - 1) % self->minRun)) - 1);
    }
    while ((((index - runStart) < self->minRun) && (index < end))) {
      insertTo(self, index,
               rightBinarySearch(self, runStart, index, read(self, index)));
      index += 1;
    }
    runStart = index;
    index += 1;
  }
}
void binaryInsertion(AdaptiveGrailExample *self, int start, int end) {
  int index;
  if (!(((end - start) > 1))) {
    return;
  }
  for (index = (start + 1); index < end; index++) {
    insertTo(self, index,
             rightBinarySearch(self, start, index, read(self, index)));
  }
}
void mergeWithBufferRest(AdaptiveGrailExample *self, int start, int middle,
                         int end, int buffer, int length) {
  int left, output, right;
  left = 0;
  right = middle;
  output = start;
  while (((left < length) && (right < end))) {
    if ((compare(self, (buffer + left), right) <= 0)) {
      swap(self, output, (buffer + left));
      left += 1;
    } else {
      swap(self, output, right);
      right += 1;
    }
    output += 1;
  }
  while ((left < length)) {
    swap(self, output, (buffer + left));
    output += 1;
    left += 1;
  }
}
void mergeWithBuffer(AdaptiveGrailExample *self, int start, int middle, int end,
                     int buffer) {
  int length;
  length = (middle - start);
  multiSwap(self, buffer, start, length);
  mergeWithBufferRest(self, start, middle, end, buffer, length);
}
void mergeWithBufferBackward(AdaptiveGrailExample *self, int start, int middle,
                             int end, int buffer) {
  int left, length, output, right;
  length = (end - middle);
  multiSwap(self, middle, buffer, length);
  left = (length - 1);
  right = (middle - 1);
  output = (end - 1);
  while (((left >= 0) && (right >= start))) {
    if ((compare(self, (buffer + left), right) >= 0)) {
      swap(self, output, (buffer + left));
      left -= 1;
    } else {
      swap(self, output, right);
      right -= 1;
    }
    output -= 1;
  }
  while ((left >= 0)) {
    swap(self, output, (buffer + left));
    output -= 1;
    left -= 1;
  }
}
void inPlaceMerge(AdaptiveGrailExample *self, int start, int middle, int end) {
  int left, next, right;
  left = start;
  right = middle;
  while (((left < right) && (right < end))) {
    if ((compare(self, left, right) > 0)) {
      next = leftBinarySearch(self, (right + 1), end, read(self, left));
      rotate(self, left, right, next);
      left += (next - right);
      right = next;
    } else {
      left += 1;
    }
  }
}
void inPlaceMergeBackward(AdaptiveGrailExample *self, int start, int middle,
                          int end) {
  int left, next, right;
  left = (middle - 1);
  right = (end - 1);
  while (((right > left) && (left >= start))) {
    if ((compare(self, left, right) > 0)) {
      next = rightBinarySearch(self, start, left, read(self, right));
      rotate(self, next, (left + 1), (right + 1));
      right -= ((left + 1) - next);
      left = (next - 1);
    } else {
      right -= 1;
    }
  }
}
void mergeWithoutBuffer(AdaptiveGrailExample *self, int start, int middle,
                        int end) {
  if (((middle - start) > (end - middle))) {
    inPlaceMergeBackward(self, start, middle, end);
  } else {
    inPlaceMerge(self, start, middle, end);
  }
}
int checkSorted(AdaptiveGrailExample *self, int middle) {
  return (compare(self, (middle - 1), middle) > 0);
}
int checkReverseBounds(AdaptiveGrailExample *self, int start, int middle,
                       int end) {
  if ((compare(self, start, (end - 1)) > 0)) {
    rotate(self, start, middle, end);
    return 0;
  }
  return 1;
}
int checkBounds(AdaptiveGrailExample *self, int start, int middle, int end) {
  return (checkSorted(self, middle) &&
          checkReverseBounds(self, start, middle, end));
}
int subarray(AdaptiveGrailExample *self, int tag, int middleKey) {
  return ((compare(self, tag, middleKey) < 0) ? 0 : 1);
}
int blockSelectSort(AdaptiveGrailExample *self, int position, int tags,
                    int offset, int distance, int leftCount, int blockCount,
                    int blockLength) {
  int candidate, index, limit, middleKey, minimum, order;
  middleKey = leftCount;
  index = 0;
  limit = (leftCount + 1);
  while ((index < (limit - 1))) {
    minimum = index;
    candidate = max_int((leftCount - offset), (index + 1));
    while ((candidate < limit)) {
      order = compare(self, ((position + distance) + (candidate * blockLength)),
                      ((position + distance) + (minimum * blockLength)));
      if (((order < 0) || ((order == 0) && (compare(self, (tags + candidate),
                                                    (tags + minimum)) < 0)))) {
        minimum = candidate;
      }
      candidate += 1;
    }
    if ((minimum != index)) {
      multiSwap(self, (position + (index * blockLength)),
                (position + (minimum * blockLength)), blockLength);
      swap(self, (tags + index), (tags + minimum));
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
void sortKeys(AdaptiveGrailExample *self, int end, int buffer, int middleKey) {
  int index, left, right;
  swap(self, buffer, middleKey);
  left = middleKey;
  index = (left + 1);
  right = (buffer + 1);
  while ((index < end)) {
    if ((compare(self, index, buffer) < 0)) {
      swap(self, left, index);
      left += 1;
    } else {
      swap(self, right, index);
      right += 1;
    }
    index += 1;
  }
  multiSwap(self, left, buffer, (end - left));
}
void sortKeysWithoutBuffer(AdaptiveGrailExample *self, int end, int middleKey) {
  int index, left;
  left = middleKey;
  index = (left + 1);
  while ((index < end)) {
    if ((compare(self, index, left) < 0)) {
      insertTo(self, index, left);
      left += 1;
    }
    index += 1;
  }
}
int mergeBlocks(AdaptiveGrailExample *self, int start, int middle, int end,
                int destination, int reverseEqual) {
  int left, order, output, right;
  left = start;
  right = middle;
  output = destination;
  while (((left < middle) && (right < end))) {
    order = compare(self, left, right);
    if (((order < 0) || ((order == 0) && !(reverseEqual)))) {
      swap(self, output, left);
      left += 1;
    } else {
      swap(self, output, right);
      right += 1;
    }
    output += 1;
  }
  if ((left > output)) {
    while ((left < middle)) {
      swap(self, output, left);
      output += 1;
      left += 1;
    }
  }
  return right;
}
void blockMerge(AdaptiveGrailExample *self, int start, int middle, int end,
                int tags, int buffer, int blockLength) {
  int blockCount, fragment, group, key, lastFull, left, leftBlocks, leftCount,
      middleKey, rightBlocks;
  lastFull = ((end - (((end - middle) - 1) % blockLength)) - 1);
  left = (start + blockLength);
  group = start;
  key = (tags - 1);
  leftCount = ((middle - left) / blockLength);
  blockCount = ((lastFull - left) / blockLength);
  leftBlocks = -(1);
  rightBlocks = (leftCount - 1);
  multiTriSwap(self, buffer, (middle - blockLength), start, blockLength);
  insertToBackward(self, tags, ((tags + leftCount) - 1));
  middleKey = blockSelectSort(self, left, tags, 1, (blockLength - 1), leftCount,
                              blockCount, blockLength);
  fragment = 0;
  while (((leftBlocks < leftCount) && (rightBlocks < blockCount))) {
    if ((fragment == 0)) {
      while (1) {
        group += blockLength;
        leftBlocks += 1;
        key += 1;
        if (!(((leftBlocks < leftCount) &&
               (subarray(self, key, middleKey) == 0)))) {
          break;
        }
      }
      if ((leftBlocks == leftCount)) {
        left = mergeBlocks(self, left, group, end, (left - blockLength), 0);
        mergeWithBufferRest(self, (left - blockLength), left, end, buffer,
                            blockLength);
      } else {
        left = mergeBlocks(self, left, group, ((group + blockLength) - 1),
                           (left - blockLength), 0);
      }
      fragment = 1;
    } else {
      while (1) {
        group += blockLength;
        rightBlocks += 1;
        key += 1;
        if (!(((rightBlocks < blockCount) &&
               (subarray(self, key, middleKey) == 1)))) {
          break;
        }
      }
      if ((rightBlocks == blockCount)) {
        shift(self, (left - blockLength), left, end);
        multiSwap(self, buffer, (end - blockLength), blockLength);
      } else {
        left = mergeBlocks(self, left, group, ((group + blockLength) - 1),
                           (left - blockLength), 1);
      }
      fragment = 0;
    }
  }
  sortKeys(self, (tags + blockCount), buffer, middleKey);
}
void blockMergeWithoutBuffer(AdaptiveGrailExample *self, int start, int middle,
                             int end, int tags, int blockLength) {
  int blockCount, end2, firstFull, fragment, group, key, lastFull, left,
      leftBlocks, leftCount, middle2, middleKey, next, nextPosition,
      rightBlocks;
  firstFull = (start + ((middle - start) % blockLength));
  lastFull = (end - ((end - middle) % blockLength));
  left = start;
  group = firstFull;
  key = tags;
  leftCount = (((middle - group) / blockLength) + 1);
  blockCount = (((lastFull - group) / blockLength) + 1);
  leftBlocks = 0;
  rightBlocks = leftCount;
  middleKey = blockSelectSort(self, group, tags, 0, 0, (leftCount - 1),
                              (blockCount - 1), blockLength);
  fragment = 0;
  while (((leftBlocks < leftCount) && (rightBlocks < blockCount))) {
    next = subarray(self, key, middleKey);
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
          if ((compare(self, left, middle2) > 0)) {
            nextPosition =
                leftBinarySearch(self, (middle2 + 1), end2, read(self, left));
            rotate(self, left, middle2, nextPosition);
            left += (nextPosition - middle2);
            middle2 = nextPosition;
          } else {
            left += 1;
          }
        }
      } else {
        while (((left < middle2) && (middle2 < end2))) {
          if ((compare(self, left, middle2) >= 0)) {
            nextPosition =
                rightBinarySearch(self, (middle2 + 1), end2, read(self, left));
            rotate(self, left, middle2, nextPosition);
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
    inPlaceMergeBackward(self, start, lastFull, end);
  }
  sortKeysWithoutBuffer(self, ((tags + blockCount) - 1), middleKey);
}
void smartMerge(AdaptiveGrailExample *self, int start, int middle, int end,
                int buffer) {
  int trimmed;
  if (checkBounds(self, start, middle, end)) {
    trimmed = rightBinarySearch(self, start, (middle - 1), read(self, middle));
    mergeWithBuffer(self, trimmed, middle, end, buffer);
  }
}
void smartMergeBackward(AdaptiveGrailExample *self, int start, int middle,
                        int end, int buffer) {
  int trimmed;
  if (checkBounds(self, start, middle, end)) {
    trimmed =
        leftBinarySearch(self, (middle + 1), end, read(self, (middle - 1)));
    mergeWithBufferBackward(self, start, middle, trimmed, buffer);
  }
}
void smartBlockMerge(AdaptiveGrailExample *self, int start, int middle, int end,
                     int tags, int buffer, int blockLength) {
  int trimmedEnd, trimmedStart;
  if (checkBounds(self, start, middle, end)) {
    trimmedStart =
        rightBinarySearch(self, start, (middle - 1), read(self, middle));
    trimmedEnd =
        leftBinarySearch(self, (middle + 1), end, read(self, (middle - 1)));
    if (checkReverseBounds(self, trimmedStart, middle, trimmedEnd)) {
      if ((((middle - trimmedStart) <= blockLength) ||
           ((trimmedEnd - middle) <= blockLength))) {
        if (((trimmedEnd - middle) < (middle - trimmedStart))) {
          mergeWithBufferBackward(self, trimmedStart, middle, trimmedEnd,
                                  buffer);
        } else {
          mergeWithBuffer(self, trimmedStart, middle, trimmedEnd, buffer);
        }
      } else {
        trimmedStart -= ((trimmedStart - start) % blockLength);
        blockMerge(self, trimmedStart, middle, trimmedEnd, tags, buffer,
                   blockLength);
      }
    }
  }
}
void smartBlockMergeWithoutBuffer(AdaptiveGrailExample *self, int start,
                                  int middle, int end, int tags,
                                  int blockLength) {
  int trimmedStart;
  if (checkBounds(self, start, middle, end)) {
    trimmedStart =
        rightBinarySearch(self, start, (middle - 1), read(self, middle));
    if (((middle - trimmedStart) <= blockLength)) {
      inPlaceMerge(self, trimmedStart, middle, end);
    } else {
      blockMergeWithoutBuffer(self, trimmedStart, middle, end, tags,
                              blockLength);
    }
  }
}
void smartInPlaceMerge(AdaptiveGrailExample *self, int start, int middle,
                       int end) {
  if (checkSorted(self, middle)) {
    inPlaceMergeBackward(self, start, middle, end);
  }
}
void redistributeBuffer(AdaptiveGrailExample *self, int startIn, int middleIn,
                        int end) {
  int distance, leftMiddle, middle, right, start;
  start = startIn;
  middle = middleIn;
  right = leftBinarySearch(self, middle, end, read(self, start));
  rotate(self, start, middle, right);
  distance = (right - middle);
  start += distance;
  middle += distance;
  leftMiddle = (start + ((middle - start) / 2));
  right = leftBinarySearch(self, middle, end, read(self, leftMiddle));
  rotate(self, leftMiddle, middle, right);
  distance = (right - middle);
  leftMiddle += distance;
  middle += distance;
  mergeWithoutBuffer(self, start, (leftMiddle - distance), leftMiddle);
  mergeWithoutBuffer(self, leftMiddle, middle, end);
}
void redistributeBufferBackward(AdaptiveGrailExample *self, int start,
                                int middleIn, int endIn) {
  int distance, end, middle, right, rightMiddle;
  middle = middleIn;
  end = endIn;
  right = rightBinarySearch(self, start, middle, read(self, (end - 1)));
  rotate(self, right, middle, end);
  distance = (middle - right);
  end -= distance;
  middle -= distance;
  rightMiddle = (middle + ((end - middle) / 2));
  right = rightBinarySearch(self, start, middle, read(self, (rightMiddle - 1)));
  rotate(self, right, middle, rightMiddle);
  distance = (middle - right);
  rightMiddle -= distance;
  middle -= distance;
  mergeWithoutBuffer(self, rightMiddle, (rightMiddle + distance), end);
  mergeWithoutBuffer(self, start, middle, rightMiddle);
}
void inPlaceMergeSort(AdaptiveGrailExample *self, int start, int end) {
  int index, run;
  buildRuns(self, start, end);
  run = self->minRun;
  while ((run < (end - start))) {
    index = start;
    while (((index + (2 * run)) <= end)) {
      smartInPlaceMerge(self, index, (index + run), (index + (2 * run)));
      index += (2 * run);
    }
    if (((index + run) < end)) {
      smartInPlaceMerge(self, index, (index + run), end);
    }
    run *= 2;
  }
}
void adaptiveSortWithoutBuffer(AdaptiveGrailExample *self, int startIn,
                               int endIn, int keys, int ideal,
                               int backwardBuffer) {
  int blockLength, buffer, dataEnd, dataStart, end, index, length, runLength,
      start, tagLength, tags;
  start = startIn;
  end = endIn;
  length = (end - start);
  blockLength = min_int(keys, self->minRun);
  while (((2 * blockLength) <= keys)) {
    blockLength *= 2;
  }
  tagLength = (keys - blockLength);
  runLength = self->minRun;
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
  buildRuns(self, dataStart, dataEnd);
  while (((runLength <= blockLength) && (runLength < length))) {
    index = dataStart;
    while (((index + (2 * runLength)) <= dataEnd)) {
      smartMerge(self, index, (index + runLength), (index + (2 * runLength)),
                 buffer);
      index += (2 * runLength);
    }
    if (((index + runLength) < dataEnd)) {
      smartMergeBackward(self, index, (index + runLength), dataEnd, buffer);
    }
    runLength *= 2;
  }
  if ((((blockLength / 2) >= self->minRun) &&
       ((blockLength / 2) >= ((keys + 1) / 2)))) {
    binaryInsertion(self, buffer, (buffer + blockLength));
    blockLength = (blockLength / 2);
    tagLength = (keys - blockLength);
    buffer += blockLength;
  }
  while (((tagLength >= (((2 * runLength) / blockLength) - 1)) &&
          (runLength < length))) {
    index = dataStart;
    while (((index + (2 * runLength)) <= dataEnd)) {
      smartBlockMerge(self, index, (index + runLength),
                      (index + (2 * runLength)), tags, buffer, blockLength);
      index += (2 * runLength);
    }
    if (((index + runLength) < dataEnd)) {
      if (((dataEnd - (index + runLength)) > blockLength)) {
        smartBlockMerge(self, index, (index + runLength), dataEnd, tags, buffer,
                        blockLength);
      } else {
        smartMergeBackward(self, index, (index + runLength), dataEnd, buffer);
      }
    }
    runLength *= 2;
  }
  binaryInsertion(self, buffer, (buffer + blockLength));
  tagLength = (keys - (keys % 2));
  while ((runLength < length)) {
    blockLength = ((2 * runLength + tagLength - 1) / tagLength);
    index = dataStart;
    while (((index + (2 * runLength)) <= dataEnd)) {
      smartBlockMergeWithoutBuffer(self, index, (index + runLength),
                                   (index + (2 * runLength)), tags,
                                   blockLength);
      index += (2 * runLength);
    }
    if (((index + runLength) < dataEnd)) {
      if (((dataEnd - (index + runLength)) > blockLength)) {
        smartBlockMergeWithoutBuffer(self, index, (index + runLength), dataEnd,
                                     tags, blockLength);
      } else {
        smartInPlaceMerge(self, index, (index + runLength), dataEnd);
      }
    }
    runLength *= 2;
  }
  if (backwardBuffer) {
    start = rightBinarySearch(self, start, dataEnd, read(self, dataEnd));
    if ((keys >= (ideal / 2))) {
      redistributeBufferBackward(self, start, dataEnd, end);
    } else {
      mergeWithoutBuffer(self, start, dataEnd, end);
    }
  } else {
    end = leftBinarySearch(self, dataStart, end, read(self, (dataStart - 1)));
    if ((keys >= (ideal / 2))) {
      redistributeBuffer(self, start, dataStart, end);
    } else {
      mergeWithoutBuffer(self, start, dataStart, end);
    }
  }
}
void sort(AdaptiveGrailExample *self, int startIn, int endIn) {
  int backwardBuffer, blockLength, buffer, dataEnd, dataStart, end, ideal,
      index, keys, leftRun, length, middle, rightRun, runLength, start,
      tagLength, tags;
  start = startIn;
  end = endIn;
  length = (end - start);
  if ((length < 31)) {
    binaryInsertion(self, start, end);
    return;
  }
  if ((length < 63)) {
    self->minRun = ((length + 1) / 2);
    buildRuns(self, start, end);
    middle = (start + self->minRun);
    if (checkBounds(self, start, middle, end)) {
      redistributeBufferBackward(self, start, middle, end);
    }
    return;
  }
  self->minRun = length;
  while ((self->minRun >= 32)) {
    self->minRun = ((self->minRun + 1) / 2);
  }
  blockLength = self->minRun;
  while (((blockLength * blockLength) < length)) {
    blockLength *= 2;
  }
  tagLength = ((length / blockLength) - 2);
  ideal = (tagLength + blockLength);
  rightRun = buildUniqueRunBackward(self, end, ideal);
  leftRun = 0;
  backwardBuffer = 0;
  if ((rightRun == ideal)) {
    backwardBuffer = 1;
  } else {
    leftRun = buildUniqueRun(self, start, ideal);
    if ((leftRun == ideal)) {
      backwardBuffer = 0;
    } else {
      backwardBuffer =
          (((rightRun < 16) && (leftRun < 16)) || (rightRun >= leftRun));
    }
  }
  keys = (backwardBuffer ? findKeysBackward(self, start, end, rightRun, ideal)
                         : findKeys(self, start, end, leftRun, ideal));
  if ((keys < ideal)) {
    if ((keys == 1)) {
      return;
    }
    if ((keys <= 4)) {
      inPlaceMergeSort(self, start, end);
    } else {
      adaptiveSortWithoutBuffer(self, start, end, keys, ideal, backwardBuffer);
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
  buildRuns(self, dataStart, dataEnd);
  runLength = self->minRun;
  while (((runLength <= blockLength) && (runLength < length))) {
    index = dataStart;
    while (((index + (2 * runLength)) <= dataEnd)) {
      smartMerge(self, index, (index + runLength), (index + (2 * runLength)),
                 buffer);
      index += (2 * runLength);
    }
    if (((index + runLength) < dataEnd)) {
      smartMergeBackward(self, index, (index + runLength), dataEnd, buffer);
    }
    runLength *= 2;
  }
  while ((runLength < length)) {
    index = dataStart;
    while (((index + (2 * runLength)) <= dataEnd)) {
      smartBlockMerge(self, index, (index + runLength),
                      (index + (2 * runLength)), tags, buffer, blockLength);
      index += (2 * runLength);
    }
    if (((index + runLength) < dataEnd)) {
      if (((dataEnd - (index + runLength)) > blockLength)) {
        smartBlockMerge(self, index, (index + runLength), dataEnd, tags, buffer,
                        blockLength);
      } else {
        smartMergeBackward(self, index, (index + runLength), dataEnd, buffer);
      }
    }
    runLength *= 2;
  }
  binaryInsertion(self, buffer, (buffer + blockLength));
  if (backwardBuffer) {
    start = rightBinarySearch(self, start, dataEnd, read(self, dataEnd));
    redistributeBufferBackward(self, start, dataEnd, end);
  } else {
    end = leftBinarySearch(self, dataStart, end, read(self, (dataStart - 1)));
    redistributeBuffer(self, start, dataStart, end);
  }
}

void adaptive_grail_sort(int *values, int length) {
  AdaptiveGrailExample state = {.values = values, .n = length, .minRun = 16};
  sort(&state, 0, length);
}

int main(void) {
  int values[] = {0,  39, 21, 62, 91, 77, 14, 23,
                  90, 69, 51, 81, 68, 83, 32, 56};
  int length = (int)(sizeof(values) / sizeof(values[0]));
  adaptive_grail_sort(values, length);
  putchar('[');
  for (int i = 0; i < length; i++)
    printf(i ? ", %d" : "%d", values[i]);
  puts("]");
}
