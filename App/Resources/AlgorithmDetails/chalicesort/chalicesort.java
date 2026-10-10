// MIT License
// Copyright (c) 2021 aphitorite
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

import java.util.Arrays;

class KeyGroup {
  int start, end;

  KeyGroup(int start, int end) {
    this.start = start;
    this.end = end;
  }
}

class FifthMergeFallback {
  static class Fifth {
    int[] a, buffer;
    int buffer_length;

    Fifth(int[] a, int[] buffer, int length) {
      this.a = a;
      this.buffer = buffer;
      buffer_length = length;
    }
  }

  static class Remaining {
    int left, right;

    Remaining(int left, int right) {
      this.left = left;
      this.right = right;
    }
  }

  static void binary_insertion(Fifth s, int first, int end) {
    for (int i = first + 1; i < end; ++i) {
      int value = s.a[i], low = first, high = i;
      while (low < high) {
        int middle = low + (high - low) / 2;
        if (s.a[middle] > value) high = middle;
        else low = middle + 1;
      }
      for (int j = i; j > low; --j) s.a[j] = s.a[j - 1];
      s.a[low] = value;
    }
  }

  static int source(Fifth s, int index, int offset, boolean from_buffer) {
    return from_buffer ? s.buffer[index - offset] : s.a[index];
  }

  static void merge(Fifth s, int offset, int first, int middle, int end, boolean from_buffer) {
    int left = first, right = middle;
    int destination = from_buffer ? first : first - offset;
    while (left < middle && right < end) {
      int value;
      if (source(s, left, offset, from_buffer) <= source(s, right, offset, from_buffer))
        value = source(s, left++, offset, from_buffer);
      else value = source(s, right++, offset, from_buffer);
      if (from_buffer) s.a[destination++] = value;
      else s.buffer[destination++] = value;
    }
    while (left < middle) {
      int value = source(s, left++, offset, from_buffer);
      if (from_buffer) s.a[destination++] = value;
      else s.buffer[destination++] = value;
    }
    while (right < end) {
      int value = source(s, right++, offset, from_buffer);
      if (from_buffer) s.a[destination++] = value;
      else s.buffer[destination++] = value;
    }
  }

  static void ping_pong(Fifth s, int first, int end) {
    int i = first;
    while (i + 8 < end) {
      binary_insertion(s, i, i + 8);
      i += 8;
    }
    if (end - i > 1) binary_insertion(s, i, end);

    int length = end - first;
    boolean from_buffer = false;
    for (int gap = 8; gap < length; gap *= 2) {
      int full = gap * 2;
      i = first;
      while (i + full < end) {
        merge(s, first, i, i + gap, i + full, from_buffer);
        i += full;
      }
      if (i + gap < end) merge(s, first, i, i + gap, end, from_buffer);
      else {
        for (int j = i; j < end; ++j) {
          if (from_buffer) s.a[j] = s.buffer[j - first];
          else s.buffer[j - first] = s.a[j];
        }
      }
      from_buffer = !from_buffer;
    }
    if (from_buffer) {
      for (int j = 0; j < length; ++j) s.a[first + j] = s.buffer[j];
    }
  }

  static void merge_forward(Fifth s, int destination, int first, int middle, int end) {
    int left = first, right = middle;
    while (left < middle && right < end) {
      if (s.a[left] <= s.a[right]) s.a[destination++] = s.a[left++];
      else s.a[destination++] = s.a[right++];
    }
    while (left < middle) s.a[destination++] = s.a[left++];
    while (right < end) s.a[destination++] = s.a[right++];
  }

  static Remaining merge_backward(Fifth s, int destination, int middle, int end) {
    int left = middle - 1, right = end - 1;
    while (destination > right && right >= middle && left >= 0) {
      if (s.a[left] > s.a[right]) s.a[destination--] = s.a[left--];
      else s.a[destination--] = s.a[right--];
    }
    if (left < 0) {
      while (right >= middle) s.a[destination--] = s.a[right--];
    } else if (right == left) {
      while (right >= 0) s.a[destination--] = s.a[right--];
    } else if (right < middle) {
      while (left >= 0) s.a[destination--] = s.a[left--];
    }
    Remaining result = new Remaining(left + 1, right + 1);
    return result;
  }

  static void merge_main_prefix(Fifth s, int destination, int left_end, int middle, int end) {
    int left = 0, right = middle;
    while (left < left_end && right < end) {
      if (s.a[left] <= s.a[right]) s.a[destination++] = s.a[left++];
      else s.a[destination++] = s.a[right++];
    }
    while (left < left_end) s.a[destination++] = s.a[left++];
  }

  static void merge_external(Fifth s, int destination, int middle, int end) {
    int left = 0, right = middle;
    while (left < s.buffer_length && right < end) {
      if (s.buffer[left] <= s.a[right]) s.a[destination++] = s.buffer[left++];
      else s.a[destination++] = s.a[right++];
    }
    while (left < s.buffer_length) s.a[destination++] = s.buffer[left++];
  }

  static void sort(int[] a, int n) {
    if (n <= 1) return;
    int fifth = n / 5, buffer_length = n - 4 * fifth;
    int[] buffer = new int[buffer_length];
    Fifth s = new Fifth(a, buffer, buffer_length);
    ping_pong(s, 0, buffer_length);
    int first = buffer_length;
    for (int i = 0; i < 4; ++i) {
      ping_pong(s, first, first + fifth);
      first += fifth;
    }
    for (int i = 0; i < buffer_length; ++i) buffer[i] = a[i];

    int two_fifths = 2 * fifth;
    first = buffer_length;
    for (int i = 0; i < 2; ++i) {
      merge_forward(s, first - buffer_length, first, first + fifth, first + two_fifths);
      first += two_fifths;
    }
    Remaining remainder = merge_backward(s, n - 1, two_fifths, 2 * two_fifths);
    if (remainder.right > 0) merge_main_prefix(s, buffer_length, remainder.left, two_fifths, n);
    merge_external(s, 0, buffer_length, n);
  }

  public static void mainUnused(String[] args) {
    int[] a = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(a, a.length);
    System.out.println(Arrays.toString(a));
  }
}

class ChaliceSortExample {
  private final int[] values;
  private int[] temp;

  private static boolean relation(int left, int right, String op) {
    switch (op) {
      case "<":
        return left < right;
      case "<=":
        return left <= right;
      case ">":
        return left > right;
      case ">=":
        return left >= right;
      default:
        return left == right;
    }
  }

  ChaliceSortExample(int[] input) {
    values = input;
    temp = new int[0];
  }

  int read(int index) {
    return values[index];
  }

  void write(int index, int value) {
    values[index] = value;
  }

  void swap(int first, int second) {
    int held = values[first];
    values[first] = values[second];
    values[second] = held;
  }

  boolean compare(int first, int second, String predicate) {
    return relation(values[first], values[second], predicate);
  }

  boolean compareValues(int first, int second, String predicate) {
    return relation(first, second, predicate);
  }

  void save(int index, int value) {
    temp[index] = value;
  }

  int load(int index) {
    return temp[index];
  }

  void shiftForwardExternal(int destination, int source, int end) {
    int input;
    int output;
    output = destination;
    for (input = source; input < end; input++) {
      write(output, read(input));
      output += 1;
    }
  }

  void shiftBackwardExternal(int start, int sourceEnd, int destinationEnd) {
    int input;
    int output;
    input = sourceEnd;
    output = destinationEnd;
    while ((input > start)) {
      input -= 1;
      output -= 1;
      write(output, read(input));
    }
  }

  int rightBinarySearch(int start, int end, int value) {
    int lower;
    int middle;
    int upper;
    lower = start;
    upper = end;
    while ((lower < upper)) {
      middle = (lower + ((upper - lower) / 2));
      if ((read(middle) <= value)) {
        lower = (middle + 1);
      } else {
        upper = middle;
      }
    }
    return lower;
  }

  void multiSwap(int first, int second, int length) {
    int offset;
    if (!((length > 0))) {
      return;
    }
    for (offset = 0; offset < length; offset++) {
      swap((first + offset), (second + offset));
    }
  }

  void binaryInsertion(int start, int end) {
    int high;
    int index;
    int low;
    int middle;
    int value;
    if (!(((end - start) > 1))) {
      return;
    }
    for (index = (start + 1); index < end; index++) {
      value = read(index);
      low = start;
      high = index;
      while ((low < high)) {
        middle = (low + ((high - low) / 2));
        if ((read(middle) > value)) {
          high = middle;
        } else {
          low = (middle + 1);
        }
      }
      insertTo(index, low);
    }
  }

  int ceilCbrt(int value) {
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

  int calcKeys(int blockLength, int count) {
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

  int leftBinSearch(int startIn, int endIn, int value) {
    int end;
    int middle;
    int start;
    start = startIn;
    end = endIn;
    while ((start < end)) {
      middle = (start + ((end - start) / 2));
      if ((values[middle] >= value)) {
        end = middle;
      } else {
        start = (middle + 1);
      }
    }
    return start;
  }

  void rotate(int start, int middle, int end) {
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
          swap((position + offset), ((position + leftLength) + offset));
        }
        position += leftLength;
        rightLength -= leftLength;
      } else {
        for (offset = 0; offset < rightLength; offset++) {
          swap(
              (((position + leftLength) - rightLength) + offset),
              ((position + leftLength) + offset));
        }
        leftLength -= rightLength;
      }
    }
  }

  void insertTo(int source, int destination) {
    int cursor;
    int value;
    value = read(source);
    cursor = source;
    while ((cursor > destination)) {
      write(cursor, read((cursor - 1)));
      cursor -= 1;
    }
    write(destination, value);
  }

  void shiftForward(int destination, int source, int end) {
    int offset;
    if (!((source < end))) {
      return;
    }
    for (offset = 0; offset < (end - source); offset++) {
      swap((destination + offset), (source + offset));
    }
  }

  void shiftBackward(int start, int sourceEnd, int destinationEnd) {
    int destination;
    int source;
    source = sourceEnd;
    destination = destinationEnd;
    while ((source > start)) {
      source -= 1;
      destination -= 1;
      swap(destination, source);
    }
  }

  void mergeForwardExternal(int startIn, int middle, int end) {
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
      save(offset, read((startIn + offset)));
    }
    start = startIn;
    left = 0;
    right = middle;
    while (((left < leftLength) && (right < end))) {
      if (compareValues(load(left), read(right), "<=")) {
        write(start, load(left));
        left += 1;
      } else {
        write(start, read(right));
        right += 1;
      }
      start += 1;
    }
    while ((left < leftLength)) {
      write(start, load(left));
      left += 1;
      start += 1;
    }
  }

  void mergeBackwardExternal(int start, int middle, int endIn) {
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
      save(offset, read((middle + offset)));
    }
    end = endIn;
    right = (rightLength - 1);
    left = (middle - 1);
    while (((right >= 0) && (left >= start))) {
      end -= 1;
      if (compareValues(load(right), read(left), ">=")) {
        write(end, load(right));
        right -= 1;
      } else {
        write(end, read(left));
        left -= 1;
      }
    }
    while ((right >= 0)) {
      end -= 1;
      write(end, load(right));
      right -= 1;
    }
  }

  void mergeWithBufferForward(
      int startIn, int middle, int end, int destinationIn, boolean external) {
    boolean chooseLeft;
    int destination;
    int right;
    int source;
    int start;
    start = startIn;
    right = middle;
    destination = destinationIn;
    while (((start < middle) && (right < end))) {
      chooseLeft = compare(start, right, "<=");
      source = (chooseLeft ? start : right);
      if (external) {
        write(destination, read(source));
      } else {
        swap(destination, source);
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
        shiftForwardExternal(destination, start, middle);
      } else {
        shiftForward(destination, start, middle);
      }
    }
    if (external) {
      shiftForwardExternal(destination, right, end);
    } else {
      shiftForward(destination, right, end);
    }
  }

  void mergeWithBufferBackward(
      int start, int middle, int endIn, int destinationEndIn, boolean external) {
    int destinationEnd;
    int left;
    int right;
    left = (middle - 1);
    right = (endIn - 1);
    destinationEnd = destinationEndIn;
    while (((right >= middle) && (left >= start))) {
      destinationEnd -= 1;
      if (compare(right, left, ">=")) {
        if (external) {
          write(destinationEnd, read(right));
        } else {
          swap(destinationEnd, right);
        }
        right -= 1;
      } else {
        if (external) {
          write(destinationEnd, read(left));
        } else {
          swap(destinationEnd, left);
        }
        left -= 1;
      }
    }
    if ((destinationEnd > right)) {
      if (external) {
        shiftBackwardExternal(middle, (right + 1), destinationEnd);
      } else {
        shiftBackward(middle, (right + 1), destinationEnd);
      }
    }
    if (external) {
      shiftBackwardExternal(start, (left + 1), destinationEnd);
    } else {
      shiftBackward(start, (left + 1), destinationEnd);
    }
  }

  void inPlaceMerge(int startIn, int middleIn, int end) {
    int insertion;
    int middle;
    int moved;
    int start;
    start = startIn;
    middle = middleIn;
    while (((start < middle) && (middle < end))) {
      start = rightBinarySearch(start, middle, read(middle));
      if ((start == middle)) {
        return;
      }
      insertion = leftBinSearch(middle, end, read(start));
      rotate(start, middle, insertion);
      moved = (insertion - middle);
      middle = insertion;
      start += (moved + 1);
    }
  }

  void laziestSortExternal(int start, int end) {
    int cursor;
    int next;
    cursor = start;
    while ((cursor < end)) {
      next = Math.min(end, (cursor + temp.length));
      binaryInsertion(cursor, next);
      if ((cursor > start)) {
        mergeBackwardExternal(start, cursor, next);
      }
      cursor = next;
    }
  }

  KeyGroup findKeysSmall(
      int start, int end, int otherStart, int otherEnd, boolean full, int needed) {
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
        location = leftBinSearch(otherStart, otherEnd, read(first));
        if (((location == otherEnd) || !(compare(first, location, "==")))) {
          last = (first + 1);
          break;
        }
        first += 1;
      }
      if ((last != 0)) {
        index = last;
        while (((index < end) && ((last - first) < needed))) {
          otherLocation = leftBinSearch(otherStart, otherEnd, read(index));
          if (((otherLocation == otherEnd) || !(compare(index, otherLocation, "==")))) {
            location = leftBinSearch(first, last, read(index));
            if (((location == last) || !(compare(index, location, "==")))) {
              rotate(first, last, index);
              displaced = (index - last);
              first += displaced;
              location += displaced;
              last = (index + 1);
              insertTo(index, location);
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
        location = leftBinSearch(first, last, read(index));
        if (((location == last) || !(compare(index, location, "==")))) {
          rotate(first, last, index);
          displaced = (index - last);
          first += displaced;
          location += displaced;
          last = (index + 1);
          insertTo(index, location);
        }
        index += 1;
      }
    }
    return new KeyGroup(first, last);
  }

  int findKeys(int start, int end, int desired, int stride) {
    int first;
    int found;
    KeyGroup group;
    int last;
    int remaining;
    int secondStart;
    group = findKeysSmall(start, end, 0, 0, false, Math.min(desired, stride));
    first = group.start;
    last = group.end;
    if (((stride < desired) && ((last - first) == stride))) {
      remaining = (desired - stride);
      while (true) {
        group = findKeysSmall(last, end, first, last, true, Math.min(stride, remaining));
        found = (group.end - group.start);
        if ((found == 0)) {
          break;
        }
        if (((found < stride) || (remaining == stride))) {
          rotate(last, group.start, group.end);
          secondStart = last;
          last += found;
          mergeBackwardExternal(first, secondStart, last);
          break;
        }
        rotate(first, last, group.start);
        first += (group.start - last);
        last = group.end;
        mergeBackwardExternal(first, group.start, last);
        remaining -= stride;
      }
    }
    rotate(start, first, last);
    return (last - first);
  }

  KeyGroup findBitsSmall(int start, int end, int referenceIn, boolean backward, int needed) {
    int first;
    int index;
    int last;
    int reference;
    first = start;
    reference = referenceIn;
    while (((first < end) && !(compare(first, reference, (backward ? "<" : ">"))))) {
      first += 1;
    }
    reference += 1;
    last = 0;
    if ((first < end)) {
      last = (first + 1);
      index = last;
      while (((index < end) && ((last - first) < needed))) {
        if (compare(index, reference, (backward ? "<" : ">"))) {
          rotate(first, last, index);
          first += (index - last);
          last = (index + 1);
          reference += 1;
        }
        index += 1;
      }
    } else {
      last = first;
    }
    return new KeyGroup(first, last);
  }

  int findBits(int start, int end, int needed, int stride) {
    int count;
    int first;
    int firstCount;
    int found;
    KeyGroup group;
    int last;
    int phase;
    int reference;
    int referenceStart;
    laziestSortExternal(start, (start + needed));
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
        group =
            findBitsSmall(
                last,
                end,
                (referenceStart + count),
                (phase == 1),
                Math.min(stride, (needed - count)));
        found = (group.end - group.start);
        if ((found == 0)) {
          break;
        }
        count += found;
        if (((found < stride) || (count == needed))) {
          rotate(last, group.start, group.end);
          last += found;
          break;
        }
        rotate(first, last, group.start);
        first += (group.start - last);
        last = group.end;
      }
      rotate(reference, first, last);
      reference += (last - first);
      if ((phase == 0)) {
        firstCount = count;
      }
    }
    if ((count < needed)) {
      return -(1);
    }
    multiSwap((start + firstCount), ((start + needed) + firstCount), (needed - firstCount));
    return firstCount;
  }

  void bitReversal(int start, int end) {
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
        swap((start + index), (start + offset));
      }
    }
  }

  void unshuffle(int start, int end) {
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
        bitReversal(position, (position + width));
        bitReversal(position, (position + (width / 2)));
        bitReversal((position + (width / 2)), (position + width));
        rotate((start + (consumed / 2)), position, (position + (width / 2)));
        consumed += width;
      }
      remaining >>= 1;
      width *= 2;
    }
  }

  void redistributeBuffer(int startIn, int middleIn, int end) {
    int insertion;
    int middle;
    int moved;
    int size;
    int start;
    start = startIn;
    middle = middleIn;
    size = temp.length;
    while ((((middle - start) > size) && (middle < end))) {
      insertion = leftBinSearch(middle, end, read((start + size)));
      rotate((start + size), middle, insertion);
      moved = (insertion - middle);
      middle = insertion;
      mergeForwardExternal(start, (start + size), middle);
      start += (moved + size);
    }
    if ((middle < end)) {
      mergeForwardExternal(start, middle, end);
    }
  }

  void copyMain(int source, int destination, int length) {
    int offset;
    if (!(((length > 0) && (source != destination)))) {
      return;
    }
    if ((destination > source)) {
      for (offset = (length - 1); offset > (0 - 1); offset += -(1)) {
        write((destination + offset), read((source + offset)));
      }
    } else {
      for (offset = 0; offset < length; offset++) {
        write((destination + offset), read((source + offset)));
      }
    }
  }

  void dualMergeBackward(
      int startIn, int middleIn, int endIn, int destinationEndIn, boolean external) {
    boolean chooseLeft;
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
      if (compare(end, left, ">=")) {
        if (external) {
          write(destinationEnd, read(end));
        } else {
          swap(destinationEnd, end);
        }
        end -= 1;
      } else {
        if (external) {
          write(destinationEnd, read(left));
        } else {
          swap(destinationEnd, left);
        }
        left -= 1;
      }
    }
    if ((end < middle)) {
      if (external) {
        shiftBackwardExternal(start, (left + 1), destinationEnd);
      } else {
        shiftBackward(start, (left + 1), destinationEnd);
      }
    } else {
      left += 1;
      end += 1;
      destinationEnd = (middle - (left - start));
      right = middle;
      while (((start < left) && (right < end))) {
        chooseLeft = compare(start, right, "<=");
        source = (chooseLeft ? start : right);
        if (external) {
          write(destinationEnd, read(source));
        } else {
          swap(destinationEnd, source);
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
          write(destinationEnd, read(start));
        } else {
          swap(destinationEnd, start);
        }
        start += 1;
        destinationEnd += 1;
      }
    }
  }

  int smartMerge(int destinationIn, int startIn, int middle, boolean reversed) {
    boolean chooseLeft;
    int destination;
    int right;
    int start;
    destination = destinationIn;
    start = startIn;
    right = middle;
    while ((start < middle)) {
      chooseLeft = (reversed ? compare(start, right, "<") : compare(start, right, "<="));
      if (chooseLeft) {
        write(destination, read(start));
        start += 1;
      } else {
        write(destination, read(right));
        right += 1;
      }
      destination += 1;
    }
    return right;
  }

  void smartTailMerge(int destinationIn, int startIn, int middle, int end) {
    int blockLength;
    int bufferIndex;
    int destination;
    int offset;
    int right;
    int start;
    destination = destinationIn;
    start = startIn;
    right = middle;
    blockLength = temp.length;
    while (((start < middle) && (right < end))) {
      if (compare(start, right, "<=")) {
        write(destination, read(start));
        start += 1;
      } else {
        write(destination, read(right));
        right += 1;
      }
      destination += 1;
    }
    if ((start < middle)) {
      if ((start > destination)) {
        shiftForwardExternal(destination, start, middle);
      }
      for (offset = 0; offset < blockLength; offset++) {
        write(((end - blockLength) + offset), load(offset));
      }
    } else {
      bufferIndex = 0;
      while (((bufferIndex < blockLength) && (right < end))) {
        if (compareValues(load(bufferIndex), read(right), "<=")) {
          write(destination, load(bufferIndex));
          bufferIndex += 1;
        } else {
          write(destination, read(right));
          right += 1;
        }
        destination += 1;
      }
      while ((bufferIndex < blockLength)) {
        write(destination, load(bufferIndex));
        bufferIndex += 1;
        destination += 1;
      }
    }
  }

  void blockCycle(int start, int tagStart, int sortedTags, int tagCount, int blockLength) {
    int index;
    int next;
    int position;
    if (!((tagCount > 1))) {
      return;
    }
    for (index = 0; index < (tagCount - 1); index++) {
      if ((compare((tagStart + index), (sortedTags + index), ">")
          || ((index > 0) && compare((tagStart + index), ((sortedTags + index) - 1), "<")))) {
        copyMain((start + (index * blockLength)), (start - blockLength), blockLength);
        position = index;
        next =
            (leftBinSearch(sortedTags, (sortedTags + tagCount), read((tagStart + index)))
                - sortedTags);
        while (true) {
          copyMain((start + (next * blockLength)), (start + (position * blockLength)), blockLength);
          swap((tagStart + index), (tagStart + next));
          position = next;
          next =
              (leftBinSearch(sortedTags, (sortedTags + tagCount), read((tagStart + index)))
                  - sortedTags);
          if (!((next != index))) {
            break;
          }
        }
        copyMain((start - blockLength), (start + (position * blockLength)), blockLength);
      }
    }
  }

  void blockCycleEasy(int start, int tagStart, int sortedTags, int tagCount, int blockLength) {
    int index;
    int next;
    if (!((tagCount > 1))) {
      return;
    }
    for (index = 0; index < (tagCount - 1); index++) {
      if ((compare((tagStart + index), (sortedTags + index), ">")
          || ((index > 0) && compare((tagStart + index), ((sortedTags + index) - 1), "<")))) {
        next =
            (leftBinSearch(sortedTags, (sortedTags + tagCount), read((tagStart + index)))
                - sortedTags);
        while (true) {
          multiSwap((start + (index * blockLength)), (start + (next * blockLength)), blockLength);
          swap((tagStart + index), (tagStart + next));
          next =
              (leftBinSearch(sortedTags, (sortedTags + tagCount), read((tagStart + index)))
                  - sortedTags);
          if (!((next != index))) {
            break;
          }
        }
      }
    }
  }

  int inPlaceMergeBackward(int start, int middleIn, int endIn, boolean reversed) {
    int end;
    int finalEnd;
    int insertion;
    int middle;
    int moved;
    middle = middleIn;
    end = endIn;
    finalEnd =
        (reversed
            ? rightBinarySearch(middle, end, read((middle - 1)))
            : leftBinSearch(middle, end, read((middle - 1))));
    end = finalEnd;
    while (((end > middle) && (middle > start))) {
      insertion =
          (reversed
              ? leftBinSearch(start, middle, read((end - 1)))
              : rightBinarySearch(start, middle, read((end - 1))));
      rotate(insertion, middle, end);
      moved = (middle - insertion);
      middle = insertion;
      end -= (moved + 1);
      if ((middle == start)) {
        break;
      }
      end =
          (reversed
              ? rightBinarySearch(middle, end, read((middle - 1)))
              : leftBinSearch(middle, end, read((middle - 1))));
    }
    return finalEnd;
  }

  void blockMerge(
      int start,
      int middle,
      int end,
      int leftTagCount,
      int tagCount,
      int tagStartIn,
      int sortedTagsIn,
      int firstBitsIn,
      int secondBitsIn,
      int blockLength) {
    int bitsEnd;
    int firstBits;
    int fragment;
    int leftBlock;
    int leftTag;
    int nextBlock;
    int offset;
    int outputTag;
    boolean reversed;
    int rightBlock;
    int rightTag;
    int secondBits;
    int sortedTags;
    int tagStart;
    if (((end - middle) <= blockLength)) {
      mergeBackwardExternal(start, middle, end);
      return;
    }
    insertTo(((tagStartIn + leftTagCount) - 1), tagStartIn);
    leftBlock = ((start + blockLength) - 1);
    rightBlock = ((middle + blockLength) - 1);
    leftTag = tagStartIn;
    rightTag = (tagStartIn + leftTagCount);
    outputTag = sortedTagsIn;
    firstBits = firstBitsIn;
    secondBits = secondBitsIn;
    while (((leftTag < (tagStartIn + leftTagCount)) && (rightTag < (tagStartIn + tagCount)))) {
      if (compare(leftBlock, rightBlock, "<=")) {
        swap(outputTag, leftTag);
        outputTag += 1;
        leftTag += 1;
        leftBlock += blockLength;
      } else {
        swap(outputTag, rightTag);
        outputTag += 1;
        rightTag += 1;
        swap(firstBits, secondBits);
        rightBlock += blockLength;
      }
      firstBits += 1;
      secondBits += 1;
    }
    while ((leftTag < (tagStartIn + leftTagCount))) {
      swap(outputTag, leftTag);
      outputTag += 1;
      leftTag += 1;
      firstBits += 1;
      secondBits += 1;
    }
    while ((rightTag < (tagStartIn + tagCount))) {
      swap(outputTag, rightTag);
      outputTag += 1;
      rightTag += 1;
      swap(firstBits, secondBits);
      firstBits += 1;
      secondBits += 1;
    }
    tagStart = sortedTagsIn;
    sortedTags = tagStartIn;
    heapSort(sortedTags, (sortedTags + tagCount));
    for (offset = 0; offset < blockLength; offset++) {
      save(offset, read(((middle - blockLength) + offset)));
    }
    copyMain(start, (middle - blockLength), blockLength);
    blockCycle((start + blockLength), tagStart, sortedTags, tagCount, blockLength);
    multiSwap(tagStart, sortedTags, tagCount);
    firstBits -= tagCount;
    secondBits -= tagCount;
    fragment = (start + blockLength);
    nextBlock = fragment;
    bitsEnd = (secondBits + tagCount);
    reversed = compare(firstBits, secondBits, ">");
    while (true) {
      while (true) {
        if (reversed) {
          swap(firstBits, secondBits);
        }
        firstBits += 1;
        secondBits += 1;
        nextBlock += blockLength;
        if (!(((secondBits < bitsEnd) && compare(firstBits, secondBits, (reversed ? ">" : "<"))))) {
          break;
        }
      }
      if ((secondBits == bitsEnd)) {
        smartTailMerge((fragment - blockLength), fragment, (reversed ? fragment : nextBlock), end);
        return;
      }
      fragment = smartMerge((fragment - blockLength), fragment, nextBlock, reversed);
      reversed = !(reversed);
    }
  }

  void blockMergeEasy(
      int start,
      int middle,
      int end,
      int leftTail,
      int rightTail,
      int leftTagCount,
      int tagCount,
      int tagStartIn,
      int sortedTagsIn,
      int firstBitsIn,
      int secondBitsIn,
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
    boolean reversed;
    int rightBlock;
    int rightTag;
    int secondBits;
    int sortedTags;
    int tagStart;
    if (((end - middle) <= blockLength)) {
      ignored = inPlaceMergeBackward(start, middle, end, false);
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
    while (((leftTag < (sortedTagsIn + leftTagCount)) && (rightTag < (sortedTagsIn + tagCount)))) {
      if (compare(leftBlock, rightBlock, "<=")) {
        swap(leftTag, outputTag);
        leftTag += 1;
        outputTag += 1;
        leftBlock += blockLength;
      } else {
        swap(rightTag, outputTag);
        rightTag += 1;
        outputTag += 1;
        swap(firstBits, secondBits);
        rightBlock += blockLength;
      }
      firstBits += 1;
      secondBits += 1;
    }
    while ((leftTag < (sortedTagsIn + leftTagCount))) {
      swap(leftTag, outputTag);
      leftTag += 1;
      outputTag += 1;
      firstBits += 1;
      secondBits += 1;
    }
    while ((rightTag < (sortedTagsIn + tagCount))) {
      swap(rightTag, outputTag);
      rightTag += 1;
      outputTag += 1;
      swap(firstBits, secondBits);
      firstBits += 1;
      secondBits += 1;
    }
    tagStart = sortedTagsIn;
    sortedTags = tagStartIn;
    heapSort(sortedTags, (sortedTags + tagCount));
    blockCycleEasy(dataStart, tagStart, sortedTags, tagCount, blockLength);
    multiSwap(tagStart, sortedTags, tagCount);
    firstBits -= tagCount;
    secondBits -= tagCount;
    fragment = dataStart;
    nextBlock = fragment;
    bitsEnd = (secondBits + tagCount);
    reversed = compare(firstBits, secondBits, ">");
    while (true) {
      while (true) {
        if (reversed) {
          swap(firstBits, secondBits);
        }
        firstBits += 1;
        secondBits += 1;
        nextBlock += blockLength;
        if (!(((secondBits < bitsEnd) && compare(firstBits, secondBits, (reversed ? ">" : "<"))))) {
          break;
        }
      }
      if ((secondBits == bitsEnd)) {
        if (!(reversed)) {
          ignored = inPlaceMergeBackward(dataStart, dataEnd, end, false);
        }
        inPlaceMerge(start, dataStart, end);
        return;
      }
      fragment = inPlaceMergeBackward(fragment, nextBlock, (nextBlock + blockLength), reversed);
      reversed = !(reversed);
    }
  }

  void sift(int start, int rootIn, int limit) {
    int child;
    int root;
    root = rootIn;
    while ((((root * 2) + 1) < limit)) {
      child = ((root * 2) + 1);
      if ((((child + 1) < limit) && compare((start + child), ((start + child) + 1), "<"))) {
        child += 1;
      }
      if (!(compare((start + root), (start + child), "<"))) {
        return;
      }
      swap((start + root), (start + child));
      root = child;
    }
  }

  void heapSort(int start, int end) {
    int count;
    int limit;
    int root;
    count = (end - start);
    if (!((count > 1))) {
      return;
    }
    for (root = ((count - 2) / 2); root > (0 - 1); root += -(1)) {
      sift(start, root, count);
    }
    for (limit = (count - 1); limit > (1 - 1); limit += -(1)) {
      swap(start, (start + limit));
      sift(start, 0, limit);
    }
  }

  void sort() {
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
    count = values.length;
    start = 0;
    end = count;
    cubeRoot = (2 * ceilCbrt((count / 4)));
    blockLength = (2 * cubeRoot);
    keyLength = calcKeys(blockLength, count);
    temp = new int[blockLength];
    keys = findKeys(start, end, (2 * keyLength), cubeRoot);
    if ((keys < 8)) {
      runLength = 1;
      while ((runLength < count)) {
        middle = (start + runLength);
        while ((middle < end)) {
          ignored =
              inPlaceMergeBackward(
                  (middle - runLength), middle, Math.min((middle + runLength), end), false);
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
    bitSeparation = findBits(keyEnd, end, keyLength, cubeRoot);
    if ((bitSeparation == -(1))) {
      laziestSortExternal(start, bitEnd);
      inPlaceMerge(start, bitEnd, end);
      return;
    }
    dataStart = (bitEnd + blockLength);
    dataLength = (end - dataStart);
    binaryInsertion(bitEnd, dataStart);
    for (offset = 0; offset < blockLength; offset++) {
      save(offset, read((bitEnd + offset)));
    }
    runLength = 1;
    while ((runLength < cubeRoot)) {
      vacant = Math.max(2, runLength);
      index = dataStart;
      while (((index + (2 * runLength)) < end)) {
        mergeWithBufferForward(
            index, (index + runLength), (index + (2 * runLength)), (index - vacant), true);
        index += (2 * runLength);
      }
      if (((index + runLength) < end)) {
        mergeWithBufferForward(index, (index + runLength), end, (index - vacant), true);
      } else {
        shiftForwardExternal((index - vacant), index, end);
      }
      dataStart -= vacant;
      end -= vacant;
      runLength *= 2;
    }
    index = (end - (dataLength % (2 * runLength)));
    if (((index + runLength) < end)) {
      mergeWithBufferBackward(index, (index + runLength), end, (end + runLength), true);
    } else {
      shiftBackwardExternal(index, end, (end + runLength));
    }
    index -= (2 * runLength);
    while ((index >= dataStart)) {
      mergeWithBufferBackward(
          index, (index + runLength), (index + (2 * runLength)), (index + (3 * runLength)), true);
      index -= (2 * runLength);
    }
    dataStart += runLength;
    end += runLength;
    runLength *= 2;
    index = dataStart;
    while (((index + (2 * runLength)) < end)) {
      mergeWithBufferForward(
          index, (index + runLength), (index + (2 * runLength)), (index - runLength), true);
      index += (2 * runLength);
    }
    if (((index + runLength) < end)) {
      mergeWithBufferForward(index, (index + runLength), end, (index - runLength), true);
    } else {
      shiftForwardExternal((index - runLength), index, end);
    }
    dataStart -= runLength;
    end -= runLength;
    runLength *= 2;
    index = (end - (dataLength % (2 * runLength)));
    if (((index + runLength) < end)) {
      dualMergeBackward(index, (index + runLength), end, (end + (runLength / 2)), true);
    } else {
      shiftBackwardExternal(index, end, (end + (runLength / 2)));
    }
    index -= (2 * runLength);
    while ((index >= dataStart)) {
      dualMergeBackward(
          index,
          (index + runLength),
          (index + (2 * runLength)),
          ((index + (2 * runLength)) + (runLength / 2)),
          true);
      index -= (2 * runLength);
    }
    dataStart += (runLength / 2);
    end += (runLength / 2);
    runLength *= 2;
    if ((keys >= runLength)) {
      rotate(start, keyEnd, dataStart);
      bitEnd = (keyEnd + blockLength);
      if ((keyLength >= runLength)) {
        minimumLevel = (2 * runLength);
        while ((runLength < keyLength)) {
          vacant = Math.max(minimumLevel, runLength);
          index = dataStart;
          while (((index + (2 * runLength)) < end)) {
            mergeWithBufferForward(
                index, (index + runLength), (index + (2 * runLength)), (index - vacant), false);
            index += (2 * runLength);
          }
          if (((index + runLength) < end)) {
            mergeWithBufferForward(index, (index + runLength), end, (index - vacant), false);
          } else {
            shiftForward((index - vacant), index, end);
          }
          dataStart -= vacant;
          end -= vacant;
          runLength *= 2;
        }
        index = (end - (dataLength % (2 * runLength)));
        if (((index + runLength) < end)) {
          mergeWithBufferBackward(index, (index + runLength), end, (end + runLength), false);
        } else {
          shiftBackward(index, end, (end + runLength));
        }
        index -= (2 * runLength);
        while ((index >= dataStart)) {
          mergeWithBufferBackward(
              index,
              (index + runLength),
              (index + (2 * runLength)),
              (index + (3 * runLength)),
              false);
          index -= (2 * runLength);
        }
        dataStart += runLength;
        end += runLength;
        runLength *= 2;
      }
      if ((keys >= runLength)) {
        index = dataStart;
        while (((index + (2 * runLength)) < end)) {
          mergeWithBufferForward(
              index, (index + runLength), (index + (2 * runLength)), (index - runLength), false);
          index += (2 * runLength);
        }
        if (((index + runLength) < end)) {
          mergeWithBufferForward(index, (index + runLength), end, (index - runLength), false);
        } else {
          shiftForward((index - runLength), index, end);
        }
        dataStart -= runLength;
        end -= runLength;
        runLength *= 2;
        index = (end - (dataLength % (2 * runLength)));
        if (((index + runLength) < end)) {
          dualMergeBackward(index, (index + runLength), end, (end + (runLength / 2)), false);
        } else {
          shiftBackward(index, end, (end + (runLength / 2)));
        }
        index -= (2 * runLength);
        while ((index >= dataStart)) {
          dualMergeBackward(
              index,
              (index + runLength),
              (index + (2 * runLength)),
              ((index + (2 * runLength)) + (runLength / 2)),
              false);
          index -= (2 * runLength);
        }
        dataStart += (runLength / 2);
        end += (runLength / 2);
        runLength *= 2;
      }
      rotate(start, bitEnd, dataStart);
      bitEnd = (keyEnd + keys);
      heapSort(start, keyEnd);
    }
    for (offset = 0; offset < blockLength; offset++) {
      write((bitEnd + offset), load(offset));
    }
    unshuffle(start, keyEnd);
    limit = (blockLength * (keyLength + 2));
    tagCount = ((runLength / blockLength) - 1);
    while (((runLength < dataLength) && (Math.min((2 * runLength), dataLength) <= limit))) {
      index = dataStart;
      while (((index + (2 * runLength)) <= end)) {
        blockMerge(
            index,
            (index + runLength),
            (index + (2 * runLength)),
            tagCount,
            (2 * tagCount),
            start,
            (start + keyLength),
            keyEnd,
            (keyEnd + keyLength),
            blockLength);
        index += (2 * runLength);
      }
      if (((index + runLength) < end)) {
        blockMerge(
            index,
            (index + runLength),
            end,
            tagCount,
            ((((end - index) - 1) / blockLength) - 1),
            start,
            (start + keyLength),
            keyEnd,
            (keyEnd + keyLength),
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
        blockMergeEasy(
            index,
            (index + runLength),
            (index + (2 * runLength)),
            leftTail,
            leftTail,
            (keyLength / 2),
            keyLength,
            start,
            (start + keyLength),
            keyEnd,
            (keyEnd + keyLength),
            blockLength);
        index += (2 * runLength);
      }
      if (((index + runLength) < end)) {
        blockMergeEasy(
            index,
            (index + runLength),
            end,
            leftTail,
            (((end - index) - runLength) % blockLength),
            (keyLength / 2),
            ((keyLength / 2) + (((end - index) - runLength) / blockLength)),
            start,
            (start + keyLength),
            keyEnd,
            (keyEnd + keyLength),
            blockLength);
      }
      runLength *= 2;
    }
    multiSwap(
        (keyEnd + bitSeparation),
        ((keyEnd + keyLength) + bitSeparation),
        (keyLength - bitSeparation));
    laziestSortExternal(start, dataStart);
    redistributeBuffer(start, dataStart, end);
  }
}

public class chalicesort {
  public static void sort(int[] values) {
    if (values.length >= 32 && values.length < 128) FifthMergeFallback.sort(values, values.length);
    else {
      ChaliceSortExample s = new ChaliceSortExample(values);
      if (values.length < 32) s.binaryInsertion(0, values.length);
      else s.sort();
    }
  }

  public static void main(String[] args) {
    int[] a = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
    sort(a);
    System.out.println(Arrays.toString(a));
  }
}
