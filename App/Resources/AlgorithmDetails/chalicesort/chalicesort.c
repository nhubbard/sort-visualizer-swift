// MIT License
// Copyright (c) 2021 aphitorite
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

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct {
  int start, end;
} KeyGroup;
typedef struct {
  int *values;
  int n;
  int *temp;
  int temp_length;
} Chalice;
static int chalice_min(int a, int b) { return a < b ? a : b; }
static int chalice_max(int a, int b) { return a > b ? a : b; }
static bool relation(int left, int right, const char *op) {
  if (!strcmp(op, "<"))
    return left < right;
  if (!strcmp(op, "<="))
    return left <= right;
  if (!strcmp(op, ">"))
    return left > right;
  if (!strcmp(op, ">="))
    return left >= right;
  return left == right;
}
#include <stdio.h>
#include <stdlib.h>

/* Five-way stable merge: one fifth occupies the only external buffer,
   leaving its former positions available to merge the other four chunks. */
typedef struct {
  int *a;
  int *buffer;
  int buffer_length;
} Fifth;

static void binary_insertion(Fifth *s, int first, int end) {
  for (int i = first + 1; i < end; ++i) {
    int value = s->a[i], low = first, high = i;
    while (low < high) {
      int middle = low + (high - low) / 2;
      if (s->a[middle] > value)
        high = middle;
      else
        low = middle + 1;
    }
    for (int j = i; j > low; --j)
      s->a[j] = s->a[j - 1];
    s->a[low] = value;
  }
}

static int source(Fifth *s, int index, int offset, int from_buffer) {
  return from_buffer ? s->buffer[index - offset] : s->a[index];
}

static void merge(Fifth *s, int offset, int first, int middle, int end,
                  int from_buffer) {
  int left = first, right = middle;
  int destination = from_buffer ? first : first - offset;
  while (left < middle && right < end) {
    int value;
    if (source(s, left, offset, from_buffer) <=
        source(s, right, offset, from_buffer))
      value = source(s, left++, offset, from_buffer);
    else
      value = source(s, right++, offset, from_buffer);
    if (from_buffer)
      s->a[destination++] = value;
    else
      s->buffer[destination++] = value;
  }
  while (left < middle) {
    int value = source(s, left++, offset, from_buffer);
    if (from_buffer)
      s->a[destination++] = value;
    else
      s->buffer[destination++] = value;
  }
  while (right < end) {
    int value = source(s, right++, offset, from_buffer);
    if (from_buffer)
      s->a[destination++] = value;
    else
      s->buffer[destination++] = value;
  }
}

static void ping_pong(Fifth *s, int first, int end) {
  int i = first;
  while (i + 8 < end) {
    binary_insertion(s, i, i + 8);
    i += 8;
  }
  if (end - i > 1)
    binary_insertion(s, i, end);

  int length = end - first, from_buffer = 0;
  for (int gap = 8; gap < length; gap *= 2) {
    int full = gap * 2;
    i = first;
    while (i + full < end) {
      merge(s, first, i, i + gap, i + full, from_buffer);
      i += full;
    }
    if (i + gap < end)
      merge(s, first, i, i + gap, end, from_buffer);
    else {
      for (int j = i; j < end; ++j) {
        if (from_buffer)
          s->a[j] = s->buffer[j - first];
        else
          s->buffer[j - first] = s->a[j];
      }
    }
    from_buffer = !from_buffer;
  }
  if (from_buffer) {
    for (int j = 0; j < length; ++j)
      s->a[first + j] = s->buffer[j];
  }
}

static void merge_forward(Fifth *s, int destination, int first, int middle,
                          int end) {
  int left = first, right = middle;
  while (left < middle && right < end) {
    if (s->a[left] <= s->a[right])
      s->a[destination++] = s->a[left++];
    else
      s->a[destination++] = s->a[right++];
  }
  while (left < middle)
    s->a[destination++] = s->a[left++];
  while (right < end)
    s->a[destination++] = s->a[right++];
}

typedef struct {
  int left, right;
} Remaining;
static Remaining merge_backward(Fifth *s, int destination, int middle,
                                int end) {
  int left = middle - 1, right = end - 1;
  while (destination > right && right >= middle && left >= 0) {
    if (s->a[left] > s->a[right])
      s->a[destination--] = s->a[left--];
    else
      s->a[destination--] = s->a[right--];
  }
  if (left < 0) {
    while (right >= middle)
      s->a[destination--] = s->a[right--];
  } else if (right == left) {
    while (right >= 0)
      s->a[destination--] = s->a[right--];
  } else if (right < middle) {
    while (left >= 0)
      s->a[destination--] = s->a[left--];
  }
  Remaining result = {left + 1, right + 1};
  return result;
}

static void merge_main_prefix(Fifth *s, int destination, int left_end,
                              int middle, int end) {
  int left = 0, right = middle;
  while (left < left_end && right < end) {
    if (s->a[left] <= s->a[right])
      s->a[destination++] = s->a[left++];
    else
      s->a[destination++] = s->a[right++];
  }
  while (left < left_end)
    s->a[destination++] = s->a[left++];
}

static void merge_external(Fifth *s, int destination, int middle, int end) {
  int left = 0, right = middle;
  while (left < s->buffer_length && right < end) {
    if (s->buffer[left] <= s->a[right])
      s->a[destination++] = s->buffer[left++];
    else
      s->a[destination++] = s->a[right++];
  }
  while (left < s->buffer_length)
    s->a[destination++] = s->buffer[left++];
}

void fifth_sort(int a[], int n) {
  if (n <= 1)
    return;
  int fifth = n / 5, buffer_length = n - 4 * fifth;
  int *buffer = malloc((size_t)buffer_length * sizeof *buffer);
  if (!buffer)
    return;
  Fifth s = {a, buffer, buffer_length};
  ping_pong(&s, 0, buffer_length);
  int first = buffer_length;
  for (int i = 0; i < 4; ++i) {
    ping_pong(&s, first, first + fifth);
    first += fifth;
  }
  for (int i = 0; i < buffer_length; ++i)
    buffer[i] = a[i];

  int two_fifths = 2 * fifth;
  first = buffer_length;
  for (int i = 0; i < 2; ++i) {
    merge_forward(&s, first - buffer_length, first, first + fifth,
                  first + two_fifths);
    first += two_fifths;
  }
  Remaining remainder = merge_backward(&s, n - 1, two_fifths, 2 * two_fifths);
  if (remainder.right > 0)
    merge_main_prefix(&s, buffer_length, remainder.left, two_fifths, n);
  merge_external(&s, 0, buffer_length, n);
  free(buffer);
}

int chalice_read(Chalice *s, int index);
void chalice_write(Chalice *s, int index, int value);
void chalice_swap(Chalice *s, int first, int second);
bool chalice_compare(Chalice *s, int first, int second, const char *predicate);
bool chalice_compareValues(Chalice *s, int first, int second,
                           const char *predicate);
void chalice_save(Chalice *s, int index, int value);
int chalice_load(Chalice *s, int index);
void chalice_shiftForwardExternal(Chalice *s, int destination, int source,
                                  int end);
void chalice_shiftBackwardExternal(Chalice *s, int start, int sourceEnd,
                                   int destinationEnd);
int chalice_rightBinarySearch(Chalice *s, int start, int end, int value);
void chalice_multiSwap(Chalice *s, int first, int second, int length);
void chalice_binaryInsertion(Chalice *s, int start, int end);
int chalice_ceilCbrt(Chalice *s, int value);
int chalice_calcKeys(Chalice *s, int blockLength, int count);
int chalice_leftBinSearch(Chalice *s, int startIn, int endIn, int value);
void chalice_rotate(Chalice *s, int start, int middle, int end);
void chalice_insertTo(Chalice *s, int source, int destination);
void chalice_shiftForward(Chalice *s, int destination, int source, int end);
void chalice_shiftBackward(Chalice *s, int start, int sourceEnd,
                           int destinationEnd);
void chalice_mergeForwardExternal(Chalice *s, int startIn, int middle, int end);
void chalice_mergeBackwardExternal(Chalice *s, int start, int middle,
                                   int endIn);
void chalice_mergeWithBufferForward(Chalice *s, int startIn, int middle,
                                    int end, int destinationIn, int external);
void chalice_mergeWithBufferBackward(Chalice *s, int start, int middle,
                                     int endIn, int destinationEndIn,
                                     int external);
void chalice_inPlaceMerge(Chalice *s, int startIn, int middleIn, int end);
void chalice_laziestSortExternal(Chalice *s, int start, int end);
KeyGroup chalice_findKeysSmall(Chalice *s, int start, int end, int otherStart,
                               int otherEnd, int full, int needed);
int chalice_findKeys(Chalice *s, int start, int end, int desired, int stride);
KeyGroup chalice_findBitsSmall(Chalice *s, int start, int end, int referenceIn,
                               int backward, int needed);
int chalice_findBits(Chalice *s, int start, int end, int needed, int stride);
void chalice_bitReversal(Chalice *s, int start, int end);
void chalice_unshuffle(Chalice *s, int start, int end);
void chalice_redistributeBuffer(Chalice *s, int startIn, int middleIn, int end);
void chalice_copyMain(Chalice *s, int source, int destination, int length);
void chalice_dualMergeBackward(Chalice *s, int startIn, int middleIn, int endIn,
                               int destinationEndIn, int external);
int chalice_smartMerge(Chalice *s, int destinationIn, int startIn, int middle,
                       int reversed);
void chalice_smartTailMerge(Chalice *s, int destinationIn, int startIn,
                            int middle, int end);
void chalice_blockCycle(Chalice *s, int start, int tagStart, int sortedTags,
                        int tagCount, int blockLength);
void chalice_blockCycleEasy(Chalice *s, int start, int tagStart, int sortedTags,
                            int tagCount, int blockLength);
int chalice_inPlaceMergeBackward(Chalice *s, int start, int middleIn, int endIn,
                                 int reversed);
void chalice_blockMerge(Chalice *s, int start, int middle, int end,
                        int leftTagCount, int tagCount, int tagStartIn,
                        int sortedTagsIn, int firstBitsIn, int secondBitsIn,
                        int blockLength);
void chalice_blockMergeEasy(Chalice *s, int start, int middle, int end,
                            int leftTail, int rightTail, int leftTagCount,
                            int tagCount, int tagStartIn, int sortedTagsIn,
                            int firstBitsIn, int secondBitsIn, int blockLength);
void chalice_sift(Chalice *s, int start, int rootIn, int limit);
void chalice_heapSort(Chalice *s, int start, int end);
void chalice_sort_body(Chalice *s);
int chalice_read(Chalice *s, int index) { return s->values[index]; }
void chalice_write(Chalice *s, int index, int value) {
  s->values[index] = value;
}
void chalice_swap(Chalice *s, int first, int second) {
  {
    int hold = s->values[first];
    s->values[first] = s->values[second];
    s->values[second] = hold;
  }
}
bool chalice_compare(Chalice *s, int first, int second, const char *predicate) {
  return relation(s->values[first], s->values[second], predicate);
}
bool chalice_compareValues(Chalice *s, int first, int second,
                           const char *predicate) {
  return relation(first, second, predicate);
}
void chalice_save(Chalice *s, int index, int value) { s->temp[index] = value; }
int chalice_load(Chalice *s, int index) { return s->temp[index]; }
void chalice_shiftForwardExternal(Chalice *s, int destination, int source,
                                  int end) {
  int input;
  int output;
  output = destination;
  for (input = source; input < end; input++) {
    chalice_write(s, output, chalice_read(s, input));
    output += 1;
  }
}
void chalice_shiftBackwardExternal(Chalice *s, int start, int sourceEnd,
                                   int destinationEnd) {
  int input;
  int output;
  input = sourceEnd;
  output = destinationEnd;
  while ((input > start)) {
    input -= 1;
    output -= 1;
    chalice_write(s, output, chalice_read(s, input));
  }
}
int chalice_rightBinarySearch(Chalice *s, int start, int end, int value) {
  int lower;
  int middle;
  int upper;
  lower = start;
  upper = end;
  while ((lower < upper)) {
    middle = (lower + ((upper - lower) / 2));
    if ((chalice_read(s, middle) <= value)) {
      lower = (middle + 1);
    } else {
      upper = middle;
    }
  }
  return lower;
}
void chalice_multiSwap(Chalice *s, int first, int second, int length) {
  int offset;
  if (!((length > 0))) {
    return;
  }
  for (offset = 0; offset < length; offset++) {
    chalice_swap(s, (first + offset), (second + offset));
  }
}
void chalice_binaryInsertion(Chalice *s, int start, int end) {
  int high;
  int index;
  int low;
  int middle;
  int value;
  if (!(((end - start) > 1))) {
    return;
  }
  for (index = (start + 1); index < end; index++) {
    value = chalice_read(s, index);
    low = start;
    high = index;
    while ((low < high)) {
      middle = (low + ((high - low) / 2));
      if ((chalice_read(s, middle) > value)) {
        high = middle;
      } else {
        low = (middle + 1);
      }
    }
    chalice_insertTo(s, index, low);
  }
}
int chalice_ceilCbrt(Chalice *s, int value) {
  int high;
  int low;
  int middle;
  low = 0;
  high = 11;
  while ((low < high)) {
    middle = ((low + high) / 2);
    if (((1 << (3 * middle)) >= value)) {
      high = middle;
    } else {
      low = (middle + 1);
    }
  }
  return (1 << low);
}
int chalice_calcKeys(Chalice *s, int blockLength, int count) {
  int high;
  int low;
  int middle;
  low = 1;
  high = (count / 4);
  while ((low < high)) {
    middle = ((low + high) / 2);
    if ((((((count - (4 * middle)) - 1) / blockLength) - 2) < middle)) {
      high = middle;
    } else {
      low = (middle + 1);
    }
  }
  return low;
}
int chalice_leftBinSearch(Chalice *s, int startIn, int endIn, int value) {
  int end;
  int middle;
  int start;
  start = startIn;
  end = endIn;
  while ((start < end)) {
    middle = (start + ((end - start) / 2));
    if ((s->values[middle] >= value)) {
      end = middle;
    } else {
      start = (middle + 1);
    }
  }
  return start;
}
void chalice_rotate(Chalice *s, int start, int middle, int end) {
  int leftLength;
  int offset;
  int position;
  int rightLength;
  if (!(((start < middle) && (middle < end)))) {
    return;
  }
  position = start;
  leftLength = (middle - start);
  rightLength = (end - middle);
  while (((leftLength != 0) && (rightLength != 0))) {
    if ((leftLength <= rightLength)) {
      for (offset = 0; offset < leftLength; offset++) {
        chalice_swap(s, (position + offset),
                     ((position + leftLength) + offset));
      }
      position += leftLength;
      rightLength -= leftLength;
    } else {
      for (offset = 0; offset < rightLength; offset++) {
        chalice_swap(s, (((position + leftLength) - rightLength) + offset),
                     ((position + leftLength) + offset));
      }
      leftLength -= rightLength;
    }
  }
}
void chalice_insertTo(Chalice *s, int source, int destination) {
  int cursor;
  int value;
  value = chalice_read(s, source);
  cursor = source;
  while ((cursor > destination)) {
    chalice_write(s, cursor, chalice_read(s, (cursor - 1)));
    cursor -= 1;
  }
  chalice_write(s, destination, value);
}
void chalice_shiftForward(Chalice *s, int destination, int source, int end) {
  int offset;
  if (!((source < end))) {
    return;
  }
  for (offset = 0; offset < (end - source); offset++) {
    chalice_swap(s, (destination + offset), (source + offset));
  }
}
void chalice_shiftBackward(Chalice *s, int start, int sourceEnd,
                           int destinationEnd) {
  int destination;
  int source;
  source = sourceEnd;
  destination = destinationEnd;
  while ((source > start)) {
    source -= 1;
    destination -= 1;
    chalice_swap(s, destination, source);
  }
}
void chalice_mergeForwardExternal(Chalice *s, int startIn, int middle,
                                  int end) {
  int left;
  int leftLength;
  int offset;
  int right;
  int start;
  leftLength = (middle - startIn);
  if (!((leftLength > 0))) {
    return;
  }
  for (offset = 0; offset < leftLength; offset++) {
    chalice_save(s, offset, chalice_read(s, (startIn + offset)));
  }
  start = startIn;
  left = 0;
  right = middle;
  while (((left < leftLength) && (right < end))) {
    if (chalice_compareValues(s, chalice_load(s, left), chalice_read(s, right),
                              "<=")) {
      chalice_write(s, start, chalice_load(s, left));
      left += 1;
    } else {
      chalice_write(s, start, chalice_read(s, right));
      right += 1;
    }
    start += 1;
  }
  while ((left < leftLength)) {
    chalice_write(s, start, chalice_load(s, left));
    left += 1;
    start += 1;
  }
}
void chalice_mergeBackwardExternal(Chalice *s, int start, int middle,
                                   int endIn) {
  int end;
  int left;
  int offset;
  int right;
  int rightLength;
  rightLength = (endIn - middle);
  if (!((rightLength > 0))) {
    return;
  }
  for (offset = 0; offset < rightLength; offset++) {
    chalice_save(s, offset, chalice_read(s, (middle + offset)));
  }
  end = endIn;
  right = (rightLength - 1);
  left = (middle - 1);
  while (((right >= 0) && (left >= start))) {
    end -= 1;
    if (chalice_compareValues(s, chalice_load(s, right), chalice_read(s, left),
                              ">=")) {
      chalice_write(s, end, chalice_load(s, right));
      right -= 1;
    } else {
      chalice_write(s, end, chalice_read(s, left));
      left -= 1;
    }
  }
  while ((right >= 0)) {
    end -= 1;
    chalice_write(s, end, chalice_load(s, right));
    right -= 1;
  }
}
void chalice_mergeWithBufferForward(Chalice *s, int startIn, int middle,
                                    int end, int destinationIn, int external) {
  int chooseLeft;
  int destination;
  int right;
  int source;
  int start;
  start = startIn;
  right = middle;
  destination = destinationIn;
  while (((start < middle) && (right < end))) {
    chooseLeft = chalice_compare(s, start, right, "<=");
    source = (chooseLeft ? start : right);
    if (external) {
      chalice_write(s, destination, chalice_read(s, source));
    } else {
      chalice_swap(s, destination, source);
    }
    if (chooseLeft) {
      start += 1;
    } else {
      right += 1;
    }
    destination += 1;
  }
  if ((start > destination)) {
    if (external) {
      chalice_shiftForwardExternal(s, destination, start, middle);
    } else {
      chalice_shiftForward(s, destination, start, middle);
    }
  }
  if (external) {
    chalice_shiftForwardExternal(s, destination, right, end);
  } else {
    chalice_shiftForward(s, destination, right, end);
  }
}
void chalice_mergeWithBufferBackward(Chalice *s, int start, int middle,
                                     int endIn, int destinationEndIn,
                                     int external) {
  int destinationEnd;
  int left;
  int right;
  left = (middle - 1);
  right = (endIn - 1);
  destinationEnd = destinationEndIn;
  while (((right >= middle) && (left >= start))) {
    destinationEnd -= 1;
    if (chalice_compare(s, right, left, ">=")) {
      if (external) {
        chalice_write(s, destinationEnd, chalice_read(s, right));
      } else {
        chalice_swap(s, destinationEnd, right);
      }
      right -= 1;
    } else {
      if (external) {
        chalice_write(s, destinationEnd, chalice_read(s, left));
      } else {
        chalice_swap(s, destinationEnd, left);
      }
      left -= 1;
    }
  }
  if ((destinationEnd > right)) {
    if (external) {
      chalice_shiftBackwardExternal(s, middle, (right + 1), destinationEnd);
    } else {
      chalice_shiftBackward(s, middle, (right + 1), destinationEnd);
    }
  }
  if (external) {
    chalice_shiftBackwardExternal(s, start, (left + 1), destinationEnd);
  } else {
    chalice_shiftBackward(s, start, (left + 1), destinationEnd);
  }
}
void chalice_inPlaceMerge(Chalice *s, int startIn, int middleIn, int end) {
  int insertion;
  int middle;
  int moved;
  int start;
  start = startIn;
  middle = middleIn;
  while (((start < middle) && (middle < end))) {
    start =
        chalice_rightBinarySearch(s, start, middle, chalice_read(s, middle));
    if ((start == middle)) {
      return;
    }
    insertion = chalice_leftBinSearch(s, middle, end, chalice_read(s, start));
    chalice_rotate(s, start, middle, insertion);
    moved = (insertion - middle);
    middle = insertion;
    start += (moved + 1);
  }
}
void chalice_laziestSortExternal(Chalice *s, int start, int end) {
  int cursor;
  int next;
  cursor = start;
  while ((cursor < end)) {
    next = chalice_min(end, (cursor + s->temp_length));
    chalice_binaryInsertion(s, cursor, next);
    if ((cursor > start)) {
      chalice_mergeBackwardExternal(s, start, cursor, next);
    }
    cursor = next;
  }
}
KeyGroup chalice_findKeysSmall(Chalice *s, int start, int end, int otherStart,
                               int otherEnd, int full, int needed) {
  int displaced;
  int first;
  int index;
  int last;
  int location;
  int otherLocation;
  first = start;
  last = 0;
  if (full) {
    last = 0;
    while ((first < end)) {
      location = chalice_leftBinSearch(s, otherStart, otherEnd,
                                       chalice_read(s, first));
      if (((location == otherEnd) ||
           !(chalice_compare(s, first, location, "==")))) {
        last = (first + 1);
        break;
      }
      first += 1;
    }
    if ((last != 0)) {
      index = last;
      while (((index < end) && ((last - first) < needed))) {
        otherLocation = chalice_leftBinSearch(s, otherStart, otherEnd,
                                              chalice_read(s, index));
        if (((otherLocation == otherEnd) ||
             !(chalice_compare(s, index, otherLocation, "==")))) {
          location =
              chalice_leftBinSearch(s, first, last, chalice_read(s, index));
          if (((location == last) ||
               !(chalice_compare(s, index, location, "==")))) {
            chalice_rotate(s, first, last, index);
            displaced = (index - last);
            first += displaced;
            location += displaced;
            last = (index + 1);
            chalice_insertTo(s, index, location);
          }
        }
        index += 1;
      }
    } else {
      last = first;
    }
  } else {
    last = (first + 1);
    index = last;
    while (((index < end) && ((last - first) < needed))) {
      location = chalice_leftBinSearch(s, first, last, chalice_read(s, index));
      if (((location == last) ||
           !(chalice_compare(s, index, location, "==")))) {
        chalice_rotate(s, first, last, index);
        displaced = (index - last);
        first += displaced;
        location += displaced;
        last = (index + 1);
        chalice_insertTo(s, index, location);
      }
      index += 1;
    }
  }
  return (KeyGroup){first, last};
}
int chalice_findKeys(Chalice *s, int start, int end, int desired, int stride) {
  int first;
  int found;
  KeyGroup group;
  int last;
  int remaining;
  int secondStart;
  group = chalice_findKeysSmall(s, start, end, 0, 0, false,
                                chalice_min(desired, stride));
  first = group.start;
  last = group.end;
  if (((stride < desired) && ((last - first) == stride))) {
    remaining = (desired - stride);
    while (true) {
      group = chalice_findKeysSmall(s, last, end, first, last, true,
                                    chalice_min(stride, remaining));
      found = (group.end - group.start);
      if ((found == 0)) {
        break;
      }
      if (((found < stride) || (remaining == stride))) {
        chalice_rotate(s, last, group.start, group.end);
        secondStart = last;
        last += found;
        chalice_mergeBackwardExternal(s, first, secondStart, last);
        break;
      }
      chalice_rotate(s, first, last, group.start);
      first += (group.start - last);
      last = group.end;
      chalice_mergeBackwardExternal(s, first, group.start, last);
      remaining -= stride;
    }
  }
  chalice_rotate(s, start, first, last);
  return (last - first);
}
KeyGroup chalice_findBitsSmall(Chalice *s, int start, int end, int referenceIn,
                               int backward, int needed) {
  int first;
  int index;
  int last;
  int reference;
  first = start;
  reference = referenceIn;
  while (((first < end) &&
          !(chalice_compare(s, first, reference, (backward ? "<" : ">"))))) {
    first += 1;
  }
  reference += 1;
  last = 0;
  if ((first < end)) {
    last = (first + 1);
    index = last;
    while (((index < end) && ((last - first) < needed))) {
      if (chalice_compare(s, index, reference, (backward ? "<" : ">"))) {
        chalice_rotate(s, first, last, index);
        first += (index - last);
        last = (index + 1);
        reference += 1;
      }
      index += 1;
    }
  } else {
    last = first;
  }
  return (KeyGroup){first, last};
}
int chalice_findBits(Chalice *s, int start, int end, int needed, int stride) {
  int count;
  int first;
  int firstCount;
  int found;
  KeyGroup group;
  int last;
  int phase;
  int reference;
  int referenceStart;
  chalice_laziestSortExternal(s, start, (start + needed));
  referenceStart = start;
  reference = (start + needed);
  count = 0;
  firstCount = 0;
  for (phase = 0; phase < 2; phase++) {
    if ((count >= needed)) {
      continue;
    }
    first = reference;
    last = first;
    while (true) {
      group = chalice_findBitsSmall(s, last, end, (referenceStart + count),
                                    (phase == 1),
                                    chalice_min(stride, (needed - count)));
      found = (group.end - group.start);
      if ((found == 0)) {
        break;
      }
      count += found;
      if (((found < stride) || (count == needed))) {
        chalice_rotate(s, last, group.start, group.end);
        last += found;
        break;
      }
      chalice_rotate(s, first, last, group.start);
      first += (group.start - last);
      last = group.end;
    }
    chalice_rotate(s, reference, first, last);
    reference += (last - first);
    if ((phase == 0)) {
      firstCount = count;
    }
  }
  if ((count < needed)) {
    return -(1);
  }
  chalice_multiSwap(s, (start + firstCount), ((start + needed) + firstCount),
                    (needed - firstCount));
  return firstCount;
}
void chalice_bitReversal(Chalice *s, int start, int end) {
  int current;
  int decrement;
  int half;
  int index;
  int jump;
  int length;
  int offset;
  int threeQuarters;
  length = (end - start);
  offset = 0;
  half = (length / 2);
  threeQuarters = (half + (half / 2));
  if ((length < 3)) {
    return;
  }
  for (index = 1; index < (length - 1); index++) {
    jump = half;
    current = index;
    decrement = threeQuarters;
    while (((current & 1) == 0)) {
      jump -= decrement;
      current >>= 1;
      decrement >>= 1;
    }
    offset += jump;
    if ((offset > index)) {
      chalice_swap(s, (start + index), (start + offset));
    }
  }
}
void chalice_unshuffle(Chalice *s, int start, int end) {
  int consumed;
  int position;
  int remaining;
  int width;
  remaining = ((end - start) / 2);
  consumed = 0;
  width = 2;
  while ((remaining > 0)) {
    if (((remaining & 1) == 1)) {
      position = (start + consumed);
      chalice_bitReversal(s, position, (position + width));
      chalice_bitReversal(s, position, (position + (width / 2)));
      chalice_bitReversal(s, (position + (width / 2)), (position + width));
      chalice_rotate(s, (start + (consumed / 2)), position,
                     (position + (width / 2)));
      consumed += width;
    }
    remaining >>= 1;
    width *= 2;
  }
}
void chalice_redistributeBuffer(Chalice *s, int startIn, int middleIn,
                                int end) {
  int insertion;
  int middle;
  int moved;
  int size;
  int start;
  start = startIn;
  middle = middleIn;
  size = s->temp_length;
  while ((((middle - start) > size) && (middle < end))) {
    insertion =
        chalice_leftBinSearch(s, middle, end, chalice_read(s, (start + size)));
    chalice_rotate(s, (start + size), middle, insertion);
    moved = (insertion - middle);
    middle = insertion;
    chalice_mergeForwardExternal(s, start, (start + size), middle);
    start += (moved + size);
  }
  if ((middle < end)) {
    chalice_mergeForwardExternal(s, start, middle, end);
  }
}
void chalice_copyMain(Chalice *s, int source, int destination, int length) {
  int offset;
  if (!(((length > 0) && (source != destination)))) {
    return;
  }
  if ((destination > source)) {
    for (offset = (length - 1); offset > (0 - 1); offset += -(1)) {
      chalice_write(s, (destination + offset),
                    chalice_read(s, (source + offset)));
    }
  } else {
    for (offset = 0; offset < length; offset++) {
      chalice_write(s, (destination + offset),
                    chalice_read(s, (source + offset)));
    }
  }
}
void chalice_dualMergeBackward(Chalice *s, int startIn, int middleIn, int endIn,
                               int destinationEndIn, int external) {
  int chooseLeft;
  int destinationEnd;
  int end;
  int left;
  int middle;
  int right;
  int source;
  int start;
  start = startIn;
  middle = middleIn;
  end = (endIn - 1);
  destinationEnd = destinationEndIn;
  left = (middle - 1);
  while (((destinationEnd > (end + 1)) && (end >= middle))) {
    destinationEnd -= 1;
    if (chalice_compare(s, end, left, ">=")) {
      if (external) {
        chalice_write(s, destinationEnd, chalice_read(s, end));
      } else {
        chalice_swap(s, destinationEnd, end);
      }
      end -= 1;
    } else {
      if (external) {
        chalice_write(s, destinationEnd, chalice_read(s, left));
      } else {
        chalice_swap(s, destinationEnd, left);
      }
      left -= 1;
    }
  }
  if ((end < middle)) {
    if (external) {
      chalice_shiftBackwardExternal(s, start, (left + 1), destinationEnd);
    } else {
      chalice_shiftBackward(s, start, (left + 1), destinationEnd);
    }
  } else {
    left += 1;
    end += 1;
    destinationEnd = (middle - (left - start));
    right = middle;
    while (((start < left) && (right < end))) {
      chooseLeft = chalice_compare(s, start, right, "<=");
      source = (chooseLeft ? start : right);
      if (external) {
        chalice_write(s, destinationEnd, chalice_read(s, source));
      } else {
        chalice_swap(s, destinationEnd, source);
      }
      if (chooseLeft) {
        start += 1;
      } else {
        right += 1;
      }
      destinationEnd += 1;
    }
    while ((start < left)) {
      if (external) {
        chalice_write(s, destinationEnd, chalice_read(s, start));
      } else {
        chalice_swap(s, destinationEnd, start);
      }
      start += 1;
      destinationEnd += 1;
    }
  }
}
int chalice_smartMerge(Chalice *s, int destinationIn, int startIn, int middle,
                       int reversed) {
  int chooseLeft;
  int destination;
  int right;
  int start;
  destination = destinationIn;
  start = startIn;
  right = middle;
  while ((start < middle)) {
    chooseLeft = (reversed ? chalice_compare(s, start, right, "<")
                           : chalice_compare(s, start, right, "<="));
    if (chooseLeft) {
      chalice_write(s, destination, chalice_read(s, start));
      start += 1;
    } else {
      chalice_write(s, destination, chalice_read(s, right));
      right += 1;
    }
    destination += 1;
  }
  return right;
}
void chalice_smartTailMerge(Chalice *s, int destinationIn, int startIn,
                            int middle, int end) {
  int blockLength;
  int bufferIndex;
  int destination;
  int offset;
  int right;
  int start;
  destination = destinationIn;
  start = startIn;
  right = middle;
  blockLength = s->temp_length;
  while (((start < middle) && (right < end))) {
    if (chalice_compare(s, start, right, "<=")) {
      chalice_write(s, destination, chalice_read(s, start));
      start += 1;
    } else {
      chalice_write(s, destination, chalice_read(s, right));
      right += 1;
    }
    destination += 1;
  }
  if ((start < middle)) {
    if ((start > destination)) {
      chalice_shiftForwardExternal(s, destination, start, middle);
    }
    for (offset = 0; offset < blockLength; offset++) {
      chalice_write(s, ((end - blockLength) + offset), chalice_load(s, offset));
    }
  } else {
    bufferIndex = 0;
    while (((bufferIndex < blockLength) && (right < end))) {
      if (chalice_compareValues(s, chalice_load(s, bufferIndex),
                                chalice_read(s, right), "<=")) {
        chalice_write(s, destination, chalice_load(s, bufferIndex));
        bufferIndex += 1;
      } else {
        chalice_write(s, destination, chalice_read(s, right));
        right += 1;
      }
      destination += 1;
    }
    while ((bufferIndex < blockLength)) {
      chalice_write(s, destination, chalice_load(s, bufferIndex));
      bufferIndex += 1;
      destination += 1;
    }
  }
}
void chalice_blockCycle(Chalice *s, int start, int tagStart, int sortedTags,
                        int tagCount, int blockLength) {
  int index;
  int next;
  int position;
  if (!((tagCount > 1))) {
    return;
  }
  for (index = 0; index < (tagCount - 1); index++) {
    if ((chalice_compare(s, (tagStart + index), (sortedTags + index), ">") ||
         ((index > 0) && chalice_compare(s, (tagStart + index),
                                         ((sortedTags + index) - 1), "<")))) {
      chalice_copyMain(s, (start + (index * blockLength)),
                       (start - blockLength), blockLength);
      position = index;
      next = (chalice_leftBinSearch(s, sortedTags, (sortedTags + tagCount),
                                    chalice_read(s, (tagStart + index))) -
              sortedTags);
      while (true) {
        chalice_copyMain(s, (start + (next * blockLength)),
                         (start + (position * blockLength)), blockLength);
        chalice_swap(s, (tagStart + index), (tagStart + next));
        position = next;
        next = (chalice_leftBinSearch(s, sortedTags, (sortedTags + tagCount),
                                      chalice_read(s, (tagStart + index))) -
                sortedTags);
        if (!((next != index))) {
          break;
        }
      }
      chalice_copyMain(s, (start - blockLength),
                       (start + (position * blockLength)), blockLength);
    }
  }
}
void chalice_blockCycleEasy(Chalice *s, int start, int tagStart, int sortedTags,
                            int tagCount, int blockLength) {
  int index;
  int next;
  if (!((tagCount > 1))) {
    return;
  }
  for (index = 0; index < (tagCount - 1); index++) {
    if ((chalice_compare(s, (tagStart + index), (sortedTags + index), ">") ||
         ((index > 0) && chalice_compare(s, (tagStart + index),
                                         ((sortedTags + index) - 1), "<")))) {
      next = (chalice_leftBinSearch(s, sortedTags, (sortedTags + tagCount),
                                    chalice_read(s, (tagStart + index))) -
              sortedTags);
      while (true) {
        chalice_multiSwap(s, (start + (index * blockLength)),
                          (start + (next * blockLength)), blockLength);
        chalice_swap(s, (tagStart + index), (tagStart + next));
        next = (chalice_leftBinSearch(s, sortedTags, (sortedTags + tagCount),
                                      chalice_read(s, (tagStart + index))) -
                sortedTags);
        if (!((next != index))) {
          break;
        }
      }
    }
  }
}
int chalice_inPlaceMergeBackward(Chalice *s, int start, int middleIn, int endIn,
                                 int reversed) {
  int end;
  int finalEnd;
  int insertion;
  int middle;
  int moved;
  middle = middleIn;
  end = endIn;
  finalEnd = (reversed ? chalice_rightBinarySearch(
                             s, middle, end, chalice_read(s, (middle - 1)))
                       : chalice_leftBinSearch(s, middle, end,
                                               chalice_read(s, (middle - 1))));
  end = finalEnd;
  while (((end > middle) && (middle > start))) {
    insertion = (reversed ? chalice_leftBinSearch(s, start, middle,
                                                  chalice_read(s, (end - 1)))
                          : chalice_rightBinarySearch(
                                s, start, middle, chalice_read(s, (end - 1))));
    chalice_rotate(s, insertion, middle, end);
    moved = (middle - insertion);
    middle = insertion;
    end -= (moved + 1);
    if ((middle == start)) {
      break;
    }
    end = (reversed ? chalice_rightBinarySearch(s, middle, end,
                                                chalice_read(s, (middle - 1)))
                    : chalice_leftBinSearch(s, middle, end,
                                            chalice_read(s, (middle - 1))));
  }
  return finalEnd;
}
void chalice_blockMerge(Chalice *s, int start, int middle, int end,
                        int leftTagCount, int tagCount, int tagStartIn,
                        int sortedTagsIn, int firstBitsIn, int secondBitsIn,
                        int blockLength) {
  int bitsEnd;
  int firstBits;
  int fragment;
  int leftBlock;
  int leftTag;
  int nextBlock;
  int offset;
  int outputTag;
  int reversed;
  int rightBlock;
  int rightTag;
  int secondBits;
  int sortedTags;
  int tagStart;
  if (((end - middle) <= blockLength)) {
    chalice_mergeBackwardExternal(s, start, middle, end);
    return;
  }
  chalice_insertTo(s, ((tagStartIn + leftTagCount) - 1), tagStartIn);
  leftBlock = ((start + blockLength) - 1);
  rightBlock = ((middle + blockLength) - 1);
  leftTag = tagStartIn;
  rightTag = (tagStartIn + leftTagCount);
  outputTag = sortedTagsIn;
  firstBits = firstBitsIn;
  secondBits = secondBitsIn;
  while (((leftTag < (tagStartIn + leftTagCount)) &&
          (rightTag < (tagStartIn + tagCount)))) {
    if (chalice_compare(s, leftBlock, rightBlock, "<=")) {
      chalice_swap(s, outputTag, leftTag);
      outputTag += 1;
      leftTag += 1;
      leftBlock += blockLength;
    } else {
      chalice_swap(s, outputTag, rightTag);
      outputTag += 1;
      rightTag += 1;
      chalice_swap(s, firstBits, secondBits);
      rightBlock += blockLength;
    }
    firstBits += 1;
    secondBits += 1;
  }
  while ((leftTag < (tagStartIn + leftTagCount))) {
    chalice_swap(s, outputTag, leftTag);
    outputTag += 1;
    leftTag += 1;
    firstBits += 1;
    secondBits += 1;
  }
  while ((rightTag < (tagStartIn + tagCount))) {
    chalice_swap(s, outputTag, rightTag);
    outputTag += 1;
    rightTag += 1;
    chalice_swap(s, firstBits, secondBits);
    firstBits += 1;
    secondBits += 1;
  }
  tagStart = sortedTagsIn;
  sortedTags = tagStartIn;
  chalice_heapSort(s, sortedTags, (sortedTags + tagCount));
  for (offset = 0; offset < blockLength; offset++) {
    chalice_save(s, offset, chalice_read(s, ((middle - blockLength) + offset)));
  }
  chalice_copyMain(s, start, (middle - blockLength), blockLength);
  chalice_blockCycle(s, (start + blockLength), tagStart, sortedTags, tagCount,
                     blockLength);
  chalice_multiSwap(s, tagStart, sortedTags, tagCount);
  firstBits -= tagCount;
  secondBits -= tagCount;
  fragment = (start + blockLength);
  nextBlock = fragment;
  bitsEnd = (secondBits + tagCount);
  reversed = chalice_compare(s, firstBits, secondBits, ">");
  while (true) {
    while (true) {
      if (reversed) {
        chalice_swap(s, firstBits, secondBits);
      }
      firstBits += 1;
      secondBits += 1;
      nextBlock += blockLength;
      if (!(((secondBits < bitsEnd) &&
             chalice_compare(s, firstBits, secondBits,
                             (reversed ? ">" : "<"))))) {
        break;
      }
    }
    if ((secondBits == bitsEnd)) {
      chalice_smartTailMerge(s, (fragment - blockLength), fragment,
                             (reversed ? fragment : nextBlock), end);
      return;
    }
    fragment = chalice_smartMerge(s, (fragment - blockLength), fragment,
                                  nextBlock, reversed);
    reversed = !(reversed);
  }
}
void chalice_blockMergeEasy(Chalice *s, int start, int middle, int end,
                            int leftTail, int rightTail, int leftTagCount,
                            int tagCount, int tagStartIn, int sortedTagsIn,
                            int firstBitsIn, int secondBitsIn,
                            int blockLength) {
  int ignored;
  int bitsEnd;
  int dataEnd;
  int dataStart;
  int firstBits;
  int fragment;
  int leftBlock;
  int leftTag;
  int nextBlock;
  int outputTag;
  int reversed;
  int rightBlock;
  int rightTag;
  int secondBits;
  int sortedTags;
  int tagStart;
  if (((end - middle) <= blockLength)) {
    ignored = chalice_inPlaceMergeBackward(s, start, middle, end, false);
    return;
  }
  dataStart = (start + leftTail);
  dataEnd = (end - rightTail);
  leftBlock = ((dataStart + blockLength) - 1);
  rightBlock = ((middle + blockLength) - 1);
  leftTag = sortedTagsIn;
  rightTag = (sortedTagsIn + leftTagCount);
  outputTag = tagStartIn;
  firstBits = firstBitsIn;
  secondBits = secondBitsIn;
  while (((leftTag < (sortedTagsIn + leftTagCount)) &&
          (rightTag < (sortedTagsIn + tagCount)))) {
    if (chalice_compare(s, leftBlock, rightBlock, "<=")) {
      chalice_swap(s, leftTag, outputTag);
      leftTag += 1;
      outputTag += 1;
      leftBlock += blockLength;
    } else {
      chalice_swap(s, rightTag, outputTag);
      rightTag += 1;
      outputTag += 1;
      chalice_swap(s, firstBits, secondBits);
      rightBlock += blockLength;
    }
    firstBits += 1;
    secondBits += 1;
  }
  while ((leftTag < (sortedTagsIn + leftTagCount))) {
    chalice_swap(s, leftTag, outputTag);
    leftTag += 1;
    outputTag += 1;
    firstBits += 1;
    secondBits += 1;
  }
  while ((rightTag < (sortedTagsIn + tagCount))) {
    chalice_swap(s, rightTag, outputTag);
    rightTag += 1;
    outputTag += 1;
    chalice_swap(s, firstBits, secondBits);
    firstBits += 1;
    secondBits += 1;
  }
  tagStart = sortedTagsIn;
  sortedTags = tagStartIn;
  chalice_heapSort(s, sortedTags, (sortedTags + tagCount));
  chalice_blockCycleEasy(s, dataStart, tagStart, sortedTags, tagCount,
                         blockLength);
  chalice_multiSwap(s, tagStart, sortedTags, tagCount);
  firstBits -= tagCount;
  secondBits -= tagCount;
  fragment = dataStart;
  nextBlock = fragment;
  bitsEnd = (secondBits + tagCount);
  reversed = chalice_compare(s, firstBits, secondBits, ">");
  while (true) {
    while (true) {
      if (reversed) {
        chalice_swap(s, firstBits, secondBits);
      }
      firstBits += 1;
      secondBits += 1;
      nextBlock += blockLength;
      if (!(((secondBits < bitsEnd) &&
             chalice_compare(s, firstBits, secondBits,
                             (reversed ? ">" : "<"))))) {
        break;
      }
    }
    if ((secondBits == bitsEnd)) {
      if (!(reversed)) {
        ignored =
            chalice_inPlaceMergeBackward(s, dataStart, dataEnd, end, false);
      }
      chalice_inPlaceMerge(s, start, dataStart, end);
      return;
    }
    fragment = chalice_inPlaceMergeBackward(
        s, fragment, nextBlock, (nextBlock + blockLength), reversed);
    reversed = !(reversed);
  }
}
void chalice_sift(Chalice *s, int start, int rootIn, int limit) {
  int child;
  int root;
  root = rootIn;
  while ((((root * 2) + 1) < limit)) {
    child = ((root * 2) + 1);
    if ((((child + 1) < limit) &&
         chalice_compare(s, (start + child), ((start + child) + 1), "<"))) {
      child += 1;
    }
    if (!(chalice_compare(s, (start + root), (start + child), "<"))) {
      return;
    }
    chalice_swap(s, (start + root), (start + child));
    root = child;
  }
}
void chalice_heapSort(Chalice *s, int start, int end) {
  int count;
  int limit;
  int root;
  count = (end - start);
  if (!((count > 1))) {
    return;
  }
  for (root = ((count - 2) / 2); root > (0 - 1); root += -(1)) {
    chalice_sift(s, start, root, count);
  }
  for (limit = (count - 1); limit > (1 - 1); limit += -(1)) {
    chalice_swap(s, start, (start + limit));
    chalice_sift(s, start, 0, limit);
  }
}
void chalice_sort_body(Chalice *s) {
  int ignored;
  int bitEnd;
  int bitSeparation;
  int blockLength;
  int count;
  int cubeRoot;
  int dataLength;
  int dataStart;
  int end;
  int index;
  int keyEnd;
  int keyLength;
  int keys;
  int leftTail;
  int limit;
  int middle;
  int minimumLevel;
  int offset;
  int runLength;
  int start;
  int tagCount;
  int vacant;
  count = s->n;
  start = 0;
  end = count;
  cubeRoot = (2 * chalice_ceilCbrt(s, (count / 4)));
  blockLength = (2 * cubeRoot);
  keyLength = chalice_calcKeys(s, blockLength, count);
  s->temp = (int *)calloc((size_t)blockLength, sizeof(int));
  s->temp_length = blockLength;
  keys = chalice_findKeys(s, start, end, (2 * keyLength), cubeRoot);
  if ((keys < 8)) {
    runLength = 1;
    while ((runLength < count)) {
      middle = (start + runLength);
      while ((middle < end)) {
        ignored = chalice_inPlaceMergeBackward(
            s, (middle - runLength), middle,
            chalice_min((middle + runLength), end), false);
        middle += (2 * runLength);
      }
      runLength *= 2;
    }
    return;
  }
  if ((keys < (2 * keyLength))) {
    keys -= (keys % 4);
    keyLength = (keys / 2);
  }
  keyEnd = (start + keys);
  bitEnd = (keyEnd + keys);
  bitSeparation = chalice_findBits(s, keyEnd, end, keyLength, cubeRoot);
  if ((bitSeparation == -(1))) {
    chalice_laziestSortExternal(s, start, bitEnd);
    chalice_inPlaceMerge(s, start, bitEnd, end);
    return;
  }
  dataStart = (bitEnd + blockLength);
  dataLength = (end - dataStart);
  chalice_binaryInsertion(s, bitEnd, dataStart);
  for (offset = 0; offset < blockLength; offset++) {
    chalice_save(s, offset, chalice_read(s, (bitEnd + offset)));
  }
  runLength = 1;
  while ((runLength < cubeRoot)) {
    vacant = chalice_max(2, runLength);
    index = dataStart;
    while (((index + (2 * runLength)) < end)) {
      chalice_mergeWithBufferForward(s, index, (index + runLength),
                                     (index + (2 * runLength)),
                                     (index - vacant), true);
      index += (2 * runLength);
    }
    if (((index + runLength) < end)) {
      chalice_mergeWithBufferForward(s, index, (index + runLength), end,
                                     (index - vacant), true);
    } else {
      chalice_shiftForwardExternal(s, (index - vacant), index, end);
    }
    dataStart -= vacant;
    end -= vacant;
    runLength *= 2;
  }
  index = (end - (dataLength % (2 * runLength)));
  if (((index + runLength) < end)) {
    chalice_mergeWithBufferBackward(s, index, (index + runLength), end,
                                    (end + runLength), true);
  } else {
    chalice_shiftBackwardExternal(s, index, end, (end + runLength));
  }
  index -= (2 * runLength);
  while ((index >= dataStart)) {
    chalice_mergeWithBufferBackward(s, index, (index + runLength),
                                    (index + (2 * runLength)),
                                    (index + (3 * runLength)), true);
    index -= (2 * runLength);
  }
  dataStart += runLength;
  end += runLength;
  runLength *= 2;
  index = dataStart;
  while (((index + (2 * runLength)) < end)) {
    chalice_mergeWithBufferForward(s, index, (index + runLength),
                                   (index + (2 * runLength)),
                                   (index - runLength), true);
    index += (2 * runLength);
  }
  if (((index + runLength) < end)) {
    chalice_mergeWithBufferForward(s, index, (index + runLength), end,
                                   (index - runLength), true);
  } else {
    chalice_shiftForwardExternal(s, (index - runLength), index, end);
  }
  dataStart -= runLength;
  end -= runLength;
  runLength *= 2;
  index = (end - (dataLength % (2 * runLength)));
  if (((index + runLength) < end)) {
    chalice_dualMergeBackward(s, index, (index + runLength), end,
                              (end + (runLength / 2)), true);
  } else {
    chalice_shiftBackwardExternal(s, index, end, (end + (runLength / 2)));
  }
  index -= (2 * runLength);
  while ((index >= dataStart)) {
    chalice_dualMergeBackward(
        s, index, (index + runLength), (index + (2 * runLength)),
        ((index + (2 * runLength)) + (runLength / 2)), true);
    index -= (2 * runLength);
  }
  dataStart += (runLength / 2);
  end += (runLength / 2);
  runLength *= 2;
  if ((keys >= runLength)) {
    chalice_rotate(s, start, keyEnd, dataStart);
    bitEnd = (keyEnd + blockLength);
    if ((keyLength >= runLength)) {
      minimumLevel = (2 * runLength);
      while ((runLength < keyLength)) {
        vacant = chalice_max(minimumLevel, runLength);
        index = dataStart;
        while (((index + (2 * runLength)) < end)) {
          chalice_mergeWithBufferForward(s, index, (index + runLength),
                                         (index + (2 * runLength)),
                                         (index - vacant), false);
          index += (2 * runLength);
        }
        if (((index + runLength) < end)) {
          chalice_mergeWithBufferForward(s, index, (index + runLength), end,
                                         (index - vacant), false);
        } else {
          chalice_shiftForward(s, (index - vacant), index, end);
        }
        dataStart -= vacant;
        end -= vacant;
        runLength *= 2;
      }
      index = (end - (dataLength % (2 * runLength)));
      if (((index + runLength) < end)) {
        chalice_mergeWithBufferBackward(s, index, (index + runLength), end,
                                        (end + runLength), false);
      } else {
        chalice_shiftBackward(s, index, end, (end + runLength));
      }
      index -= (2 * runLength);
      while ((index >= dataStart)) {
        chalice_mergeWithBufferBackward(s, index, (index + runLength),
                                        (index + (2 * runLength)),
                                        (index + (3 * runLength)), false);
        index -= (2 * runLength);
      }
      dataStart += runLength;
      end += runLength;
      runLength *= 2;
    }
    if ((keys >= runLength)) {
      index = dataStart;
      while (((index + (2 * runLength)) < end)) {
        chalice_mergeWithBufferForward(s, index, (index + runLength),
                                       (index + (2 * runLength)),
                                       (index - runLength), false);
        index += (2 * runLength);
      }
      if (((index + runLength) < end)) {
        chalice_mergeWithBufferForward(s, index, (index + runLength), end,
                                       (index - runLength), false);
      } else {
        chalice_shiftForward(s, (index - runLength), index, end);
      }
      dataStart -= runLength;
      end -= runLength;
      runLength *= 2;
      index = (end - (dataLength % (2 * runLength)));
      if (((index + runLength) < end)) {
        chalice_dualMergeBackward(s, index, (index + runLength), end,
                                  (end + (runLength / 2)), false);
      } else {
        chalice_shiftBackward(s, index, end, (end + (runLength / 2)));
      }
      index -= (2 * runLength);
      while ((index >= dataStart)) {
        chalice_dualMergeBackward(
            s, index, (index + runLength), (index + (2 * runLength)),
            ((index + (2 * runLength)) + (runLength / 2)), false);
        index -= (2 * runLength);
      }
      dataStart += (runLength / 2);
      end += (runLength / 2);
      runLength *= 2;
    }
    chalice_rotate(s, start, bitEnd, dataStart);
    bitEnd = (keyEnd + keys);
    chalice_heapSort(s, start, keyEnd);
  }
  for (offset = 0; offset < blockLength; offset++) {
    chalice_write(s, (bitEnd + offset), chalice_load(s, offset));
  }
  chalice_unshuffle(s, start, keyEnd);
  limit = (blockLength * (keyLength + 2));
  tagCount = ((runLength / blockLength) - 1);
  while (((runLength < dataLength) &&
          (chalice_min((2 * runLength), dataLength) <= limit))) {
    index = dataStart;
    while (((index + (2 * runLength)) <= end)) {
      chalice_blockMerge(s, index, (index + runLength),
                         (index + (2 * runLength)), tagCount, (2 * tagCount),
                         start, (start + keyLength), keyEnd,
                         (keyEnd + keyLength), blockLength);
      index += (2 * runLength);
    }
    if (((index + runLength) < end)) {
      chalice_blockMerge(s, index, (index + runLength), end, tagCount,
                         ((((end - index) - 1) / blockLength) - 1), start,
                         (start + keyLength), keyEnd, (keyEnd + keyLength),
                         blockLength);
    }
    runLength *= 2;
    tagCount = ((2 * tagCount) + 1);
  }
  while ((runLength < dataLength)) {
    blockLength = ((2 * runLength) / keyLength);
    leftTail = (runLength % blockLength);
    index = dataStart;
    while (((index + (2 * runLength)) <= end)) {
      chalice_blockMergeEasy(
          s, index, (index + runLength), (index + (2 * runLength)), leftTail,
          leftTail, (keyLength / 2), keyLength, start, (start + keyLength),
          keyEnd, (keyEnd + keyLength), blockLength);
      index += (2 * runLength);
    }
    if (((index + runLength) < end)) {
      chalice_blockMergeEasy(
          s, index, (index + runLength), end, leftTail,
          (((end - index) - runLength) % blockLength), (keyLength / 2),
          ((keyLength / 2) + (((end - index) - runLength) / blockLength)),
          start, (start + keyLength), keyEnd, (keyEnd + keyLength),
          blockLength);
    }
    runLength *= 2;
  }
  chalice_multiSwap(s, (keyEnd + bitSeparation),
                    ((keyEnd + keyLength) + bitSeparation),
                    (keyLength - bitSeparation));
  chalice_laziestSortExternal(s, start, dataStart);
  chalice_redistributeBuffer(s, start, dataStart, end);
}
void sort(int *a, int n) {
  if (n >= 32 && n < 128)
    fifth_sort(a, n);
  else {
    Chalice instance = {a, n, NULL, 0};
    if (n < 32)
      chalice_binaryInsertion(&instance, 0, n);
    else
      chalice_sort_body(&instance);
    free(instance.temp);
  }
}
int main(void) {
  int a[] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
  int n = sizeof(a) / sizeof(a[0]);
  sort(a, n);
  printf("[");
  for (int i = 0; i < n; ++i)
    printf("%s%d", i ? ", " : "", a[i]);
  puts("]");
}
