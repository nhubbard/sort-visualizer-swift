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

function binary_insertion(s, first, end) {
  for (let i = first + 1; i < end; ++i) {
    let value = s.a[i],
      low = first,
      high = i;
    while (low < high) {
      let middle = low + Math.trunc((high - low) / 2);
      if (s.a[middle] > value) high = middle;
      else low = middle + 1;
    }
    for (let j = i; j > low; --j) s.a[j] = s.a[j - 1];
    s.a[low] = value;
  }
}

function source(s, index, offset, from_buffer) {
  return from_buffer ? s.buffer[index - offset] : s.a[index];
}

function merge(s, offset, first, middle, end, from_buffer) {
  let left = first,
    right = middle;
  let destination = from_buffer ? first : first - offset;
  while (left < middle && right < end) {
    let value;
    if (
      source(s, left, offset, from_buffer) <=
      source(s, right, offset, from_buffer)
    )
      value = source(s, left++, offset, from_buffer);
    else value = source(s, right++, offset, from_buffer);
    if (from_buffer) s.a[destination++] = value;
    else s.buffer[destination++] = value;
  }
  while (left < middle) {
    let value = source(s, left++, offset, from_buffer);
    if (from_buffer) s.a[destination++] = value;
    else s.buffer[destination++] = value;
  }
  while (right < end) {
    let value = source(s, right++, offset, from_buffer);
    if (from_buffer) s.a[destination++] = value;
    else s.buffer[destination++] = value;
  }
}

function ping_pong(s, first, end) {
  let i = first;
  while (i + 8 < end) {
    binary_insertion(s, i, i + 8);
    i += 8;
  }
  if (end - i > 1) binary_insertion(s, i, end);

  let length = end - first,
    from_buffer = 0;
  for (let gap = 8; gap < length; gap *= 2) {
    let full = gap * 2;
    i = first;
    while (i + full < end) {
      merge(s, first, i, i + gap, i + full, from_buffer);
      i += full;
    }
    if (i + gap < end) merge(s, first, i, i + gap, end, from_buffer);
    else {
      for (let j = i; j < end; ++j) {
        if (from_buffer) s.a[j] = s.buffer[j - first];
        else s.buffer[j - first] = s.a[j];
      }
    }
    from_buffer = !from_buffer;
  }
  if (from_buffer) {
    for (let j = 0; j < length; ++j) s.a[first + j] = s.buffer[j];
  }
}

function merge_forward(s, destination, first, middle, end) {
  let left = first,
    right = middle;
  while (left < middle && right < end) {
    if (s.a[left] <= s.a[right]) s.a[destination++] = s.a[left++];
    else s.a[destination++] = s.a[right++];
  }
  while (left < middle) s.a[destination++] = s.a[left++];
  while (right < end) s.a[destination++] = s.a[right++];
}

function merge_backward(s, destination, middle, end) {
  let left = middle - 1,
    right = end - 1;
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
  let result = { left: left + 1, right: right + 1 };
  return result;
}

function merge_main_prefix(s, destination, left_end, middle, end) {
  let left = 0,
    right = middle;
  while (left < left_end && right < end) {
    if (s.a[left] <= s.a[right]) s.a[destination++] = s.a[left++];
    else s.a[destination++] = s.a[right++];
  }
  while (left < left_end) s.a[destination++] = s.a[left++];
}

function merge_external(s, destination, middle, end) {
  let left = 0,
    right = middle;
  while (left < s.buffer_length && right < end) {
    if (s.buffer[left] <= s.a[right]) s.a[destination++] = s.buffer[left++];
    else s.a[destination++] = s.a[right++];
  }
  while (left < s.buffer_length) s.a[destination++] = s.buffer[left++];
}

function fifthSort(a, n) {
  if (n <= 1) return;
  let fifth = Math.trunc(n / 5),
    buffer_length = n - 4 * fifth;
  let buffer = new Array(buffer_length).fill(0);
  let s = { a, buffer, buffer_length };
  ping_pong(s, 0, buffer_length);
  let first = buffer_length;
  for (let i = 0; i < 4; ++i) {
    ping_pong(s, first, first + fifth);
    first += fifth;
  }
  for (let i = 0; i < buffer_length; ++i) buffer[i] = a[i];

  let two_fifths = 2 * fifth;
  first = buffer_length;
  for (let i = 0; i < 2; ++i) {
    merge_forward(
      s,
      first - buffer_length,
      first,
      first + fifth,
      first + two_fifths,
    );
    first += two_fifths;
  }
  let remainder = merge_backward(s, n - 1, two_fifths, 2 * two_fifths);
  if (remainder.right > 0)
    merge_main_prefix(s, buffer_length, remainder.left, two_fifths, n);
  merge_external(s, 0, buffer_length, n);
}

class KeyGroup {
  constructor(start, end) {
    this.start = start;
    this.end = end;
  }
}
function relation(left, right, operator) {
  if (operator === "<") {
    return left < right;
  }
  if (operator === "<=") {
    return left <= right;
  }
  if (operator === ">") {
    return left > right;
  }
  if (operator === ">=") {
    return left >= right;
  }
  return left === right;
}
class ChaliceSortExample {
  constructor(input) {
    this.values = input;
    this.temp = [];
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
  compare(first, second, predicate) {
    return relation(this.values[first], this.values[second], predicate);
  }
  compareValues(first, second, predicate) {
    return relation(first, second, predicate);
  }
  save(index, value) {
    this.temp[index] = value;
  }
  load(index) {
    return this.temp[index];
  }
  shiftForwardExternal(destination, source, end) {
    let input, output;
    output = destination;
    for (input = source; input < end; input++) {
      this.write(output, this.read(input));
      output += 1;
    }
  }
  shiftBackwardExternal(start, sourceEnd, destinationEnd) {
    let input, output;
    input = sourceEnd;
    output = destinationEnd;
    while (input > start) {
      input -= 1;
      output -= 1;
      this.write(output, this.read(input));
    }
  }
  rightBinarySearch(start, end, value) {
    let lower, middle, upper;
    lower = start;
    upper = end;
    while (lower < upper) {
      middle = lower + Math.floor((upper - lower) / 2);
      if (this.read(middle) <= value) {
        lower = middle + 1;
      } else {
        upper = middle;
      }
    }
    return lower;
  }
  multiSwap(first, second, length) {
    let offset;
    if (!(length > 0)) {
      return;
    }
    for (offset = 0; offset < length; offset++) {
      this.swap(first + offset, second + offset);
    }
  }
  binaryInsertion(start, end) {
    let high, index, low, middle, value;
    if (!(end - start > 1)) {
      return;
    }
    for (index = start + 1; index < end; index++) {
      value = this.read(index);
      low = start;
      high = index;
      while (low < high) {
        middle = low + Math.floor((high - low) / 2);
        if (this.read(middle) > value) {
          high = middle;
        } else {
          low = middle + 1;
        }
      }
      this.insertTo(index, low);
    }
  }
  ceilCbrt(value) {
    let high, low, middle;
    low = 0;
    high = 11;
    while (low < high) {
      middle = Math.floor((low + high) / 2);
      if (1 << (3 * middle) >= value) {
        high = middle;
      } else {
        low = middle + 1;
      }
    }
    return 1 << low;
  }
  calcKeys(blockLength, count) {
    let high, low, middle;
    low = 1;
    high = Math.floor(count / 4);
    while (low < high) {
      middle = Math.floor((low + high) / 2);
      if (Math.floor((count - 4 * middle - 1) / blockLength) - 2 < middle) {
        high = middle;
      } else {
        low = middle + 1;
      }
    }
    return low;
  }
  leftBinSearch(startIn, endIn, value) {
    let end, middle, start;
    start = startIn;
    end = endIn;
    while (start < end) {
      middle = start + Math.floor((end - start) / 2);
      if (this.values[middle] >= value) {
        end = middle;
      } else {
        start = middle + 1;
      }
    }
    return start;
  }
  rotate(start, middle, end) {
    let leftLength, offset, position, rightLength;
    if (!(start < middle && middle < end)) {
      return;
    }
    position = start;
    leftLength = middle - start;
    rightLength = end - middle;
    while (leftLength !== 0 && rightLength !== 0) {
      if (leftLength <= rightLength) {
        for (offset = 0; offset < leftLength; offset++) {
          this.swap(position + offset, position + leftLength + offset);
        }
        position += leftLength;
        rightLength -= leftLength;
      } else {
        for (offset = 0; offset < rightLength; offset++) {
          this.swap(
            position + leftLength - rightLength + offset,
            position + leftLength + offset,
          );
        }
        leftLength -= rightLength;
      }
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
  shiftForward(destination, source, end) {
    let offset;
    if (!(source < end)) {
      return;
    }
    for (offset = 0; offset < end - source; offset++) {
      this.swap(destination + offset, source + offset);
    }
  }
  shiftBackward(start, sourceEnd, destinationEnd) {
    let destination, source;
    source = sourceEnd;
    destination = destinationEnd;
    while (source > start) {
      source -= 1;
      destination -= 1;
      this.swap(destination, source);
    }
  }
  mergeForwardExternal(startIn, middle, end) {
    let left, leftLength, offset, right, start;
    leftLength = middle - startIn;
    if (!(leftLength > 0)) {
      return;
    }
    for (offset = 0; offset < leftLength; offset++) {
      this.save(offset, this.read(startIn + offset));
    }
    start = startIn;
    left = 0;
    right = middle;
    while (left < leftLength && right < end) {
      if (this.compareValues(this.load(left), this.read(right), "<=")) {
        this.write(start, this.load(left));
        left += 1;
      } else {
        this.write(start, this.read(right));
        right += 1;
      }
      start += 1;
    }
    while (left < leftLength) {
      this.write(start, this.load(left));
      left += 1;
      start += 1;
    }
  }
  mergeBackwardExternal(start, middle, endIn) {
    let end, left, offset, right, rightLength;
    rightLength = endIn - middle;
    if (!(rightLength > 0)) {
      return;
    }
    for (offset = 0; offset < rightLength; offset++) {
      this.save(offset, this.read(middle + offset));
    }
    end = endIn;
    right = rightLength - 1;
    left = middle - 1;
    while (right >= 0 && left >= start) {
      end -= 1;
      if (this.compareValues(this.load(right), this.read(left), ">=")) {
        this.write(end, this.load(right));
        right -= 1;
      } else {
        this.write(end, this.read(left));
        left -= 1;
      }
    }
    while (right >= 0) {
      end -= 1;
      this.write(end, this.load(right));
      right -= 1;
    }
  }
  mergeWithBufferForward(startIn, middle, end, destinationIn, external) {
    let chooseLeft, destination, right, source, start;
    start = startIn;
    right = middle;
    destination = destinationIn;
    while (start < middle && right < end) {
      chooseLeft = this.compare(start, right, "<=");
      source = chooseLeft ? start : right;
      if (external) {
        this.write(destination, this.read(source));
      } else {
        this.swap(destination, source);
      }
      if (chooseLeft) {
        start += 1;
      } else {
        right += 1;
      }
      destination += 1;
    }
    if (start > destination) {
      if (external) {
        this.shiftForwardExternal(destination, start, middle);
      } else {
        this.shiftForward(destination, start, middle);
      }
    }
    if (external) {
      this.shiftForwardExternal(destination, right, end);
    } else {
      this.shiftForward(destination, right, end);
    }
  }
  mergeWithBufferBackward(start, middle, endIn, destinationEndIn, external) {
    let destinationEnd, left, right;
    left = middle - 1;
    right = endIn - 1;
    destinationEnd = destinationEndIn;
    while (right >= middle && left >= start) {
      destinationEnd -= 1;
      if (this.compare(right, left, ">=")) {
        if (external) {
          this.write(destinationEnd, this.read(right));
        } else {
          this.swap(destinationEnd, right);
        }
        right -= 1;
      } else {
        if (external) {
          this.write(destinationEnd, this.read(left));
        } else {
          this.swap(destinationEnd, left);
        }
        left -= 1;
      }
    }
    if (destinationEnd > right) {
      if (external) {
        this.shiftBackwardExternal(middle, right + 1, destinationEnd);
      } else {
        this.shiftBackward(middle, right + 1, destinationEnd);
      }
    }
    if (external) {
      this.shiftBackwardExternal(start, left + 1, destinationEnd);
    } else {
      this.shiftBackward(start, left + 1, destinationEnd);
    }
  }
  inPlaceMerge(startIn, middleIn, end) {
    let insertion, middle, moved, start;
    start = startIn;
    middle = middleIn;
    while (start < middle && middle < end) {
      start = this.rightBinarySearch(start, middle, this.read(middle));
      if (start === middle) {
        return;
      }
      insertion = this.leftBinSearch(middle, end, this.read(start));
      this.rotate(start, middle, insertion);
      moved = insertion - middle;
      middle = insertion;
      start += moved + 1;
    }
  }
  laziestSortExternal(start, end) {
    let cursor, next;
    cursor = start;
    while (cursor < end) {
      next = Math.min(end, cursor + this.temp.length);
      this.binaryInsertion(cursor, next);
      if (cursor > start) {
        this.mergeBackwardExternal(start, cursor, next);
      }
      cursor = next;
    }
  }
  findKeysSmall(start, end, otherStart, otherEnd, full, needed) {
    let displaced, first, index, last, location, otherLocation;
    first = start;
    last = null;
    if (full) {
      last = 0;
      while (first < end) {
        location = this.leftBinSearch(otherStart, otherEnd, this.read(first));
        if (location === otherEnd || !this.compare(first, location, "==")) {
          last = first + 1;
          break;
        }
        first += 1;
      }
      if (last !== 0) {
        index = last;
        while (index < end && last - first < needed) {
          otherLocation = this.leftBinSearch(
            otherStart,
            otherEnd,
            this.read(index),
          );
          if (
            otherLocation === otherEnd ||
            !this.compare(index, otherLocation, "==")
          ) {
            location = this.leftBinSearch(first, last, this.read(index));
            if (location === last || !this.compare(index, location, "==")) {
              this.rotate(first, last, index);
              displaced = index - last;
              first += displaced;
              location += displaced;
              last = index + 1;
              this.insertTo(index, location);
            }
          }
          index += 1;
        }
      } else {
        last = first;
      }
    } else {
      last = first + 1;
      index = last;
      while (index < end && last - first < needed) {
        location = this.leftBinSearch(first, last, this.read(index));
        if (location === last || !this.compare(index, location, "==")) {
          this.rotate(first, last, index);
          displaced = index - last;
          first += displaced;
          location += displaced;
          last = index + 1;
          this.insertTo(index, location);
        }
        index += 1;
      }
    }
    return new KeyGroup(first, last);
  }
  findKeys(start, end, desired, stride) {
    let first, found, group, last, remaining, secondStart;
    group = this.findKeysSmall(
      start,
      end,
      0,
      0,
      false,
      Math.min(desired, stride),
    );
    first = group.start;
    last = group.end;
    if (stride < desired && last - first === stride) {
      remaining = desired - stride;
      while (true) {
        group = this.findKeysSmall(
          last,
          end,
          first,
          last,
          true,
          Math.min(stride, remaining),
        );
        found = group.end - group.start;
        if (found === 0) {
          break;
        }
        if (found < stride || remaining === stride) {
          this.rotate(last, group.start, group.end);
          secondStart = last;
          last += found;
          this.mergeBackwardExternal(first, secondStart, last);
          break;
        }
        this.rotate(first, last, group.start);
        first += group.start - last;
        last = group.end;
        this.mergeBackwardExternal(first, group.start, last);
        remaining -= stride;
      }
    }
    this.rotate(start, first, last);
    return last - first;
  }
  findBitsSmall(start, end, referenceIn, backward, needed) {
    let first, index, last, reference;
    first = start;
    reference = referenceIn;
    while (
      first < end &&
      !this.compare(first, reference, backward ? "<" : ">")
    ) {
      first += 1;
    }
    reference += 1;
    last = null;
    if (first < end) {
      last = first + 1;
      index = last;
      while (index < end && last - first < needed) {
        if (this.compare(index, reference, backward ? "<" : ">")) {
          this.rotate(first, last, index);
          first += index - last;
          last = index + 1;
          reference += 1;
        }
        index += 1;
      }
    } else {
      last = first;
    }
    return new KeyGroup(first, last);
  }
  findBits(start, end, needed, stride) {
    let count,
      first,
      firstCount,
      found,
      group,
      last,
      phase,
      reference,
      referenceStart;
    this.laziestSortExternal(start, start + needed);
    referenceStart = start;
    reference = start + needed;
    count = 0;
    firstCount = 0;
    for (phase = 0; phase < 2; phase++) {
      if (count >= needed) {
        continue;
      }
      first = reference;
      last = first;
      while (true) {
        group = this.findBitsSmall(
          last,
          end,
          referenceStart + count,
          phase === 1,
          Math.min(stride, needed - count),
        );
        found = group.end - group.start;
        if (found === 0) {
          break;
        }
        count += found;
        if (found < stride || count === needed) {
          this.rotate(last, group.start, group.end);
          last += found;
          break;
        }
        this.rotate(first, last, group.start);
        first += group.start - last;
        last = group.end;
      }
      this.rotate(reference, first, last);
      reference += last - first;
      if (phase === 0) {
        firstCount = count;
      }
    }
    if (count < needed) {
      return -1;
    }
    this.multiSwap(
      start + firstCount,
      start + needed + firstCount,
      needed - firstCount,
    );
    return firstCount;
  }
  bitReversal(start, end) {
    let current, decrement, half, index, jump, length, offset, threeQuarters;
    length = end - start;
    offset = 0;
    half = Math.floor(length / 2);
    threeQuarters = half + Math.floor(half / 2);
    if (length < 3) {
      return;
    }
    for (index = 1; index < length - 1; index++) {
      jump = half;
      current = index;
      decrement = threeQuarters;
      while ((current & 1) === 0) {
        jump -= decrement;
        current >>= 1;
        decrement >>= 1;
      }
      offset += jump;
      if (offset > index) {
        this.swap(start + index, start + offset);
      }
    }
  }
  unshuffle(start, end) {
    let consumed, position, remaining, width;
    remaining = Math.floor((end - start) / 2);
    consumed = 0;
    width = 2;
    while (remaining > 0) {
      if ((remaining & 1) === 1) {
        position = start + consumed;
        this.bitReversal(position, position + width);
        this.bitReversal(position, position + Math.floor(width / 2));
        this.bitReversal(position + Math.floor(width / 2), position + width);
        this.rotate(
          start + Math.floor(consumed / 2),
          position,
          position + Math.floor(width / 2),
        );
        consumed += width;
      }
      remaining >>= 1;
      width *= 2;
    }
  }
  redistributeBuffer(startIn, middleIn, end) {
    let insertion, middle, moved, size, start;
    start = startIn;
    middle = middleIn;
    size = this.temp.length;
    while (middle - start > size && middle < end) {
      insertion = this.leftBinSearch(middle, end, this.read(start + size));
      this.rotate(start + size, middle, insertion);
      moved = insertion - middle;
      middle = insertion;
      this.mergeForwardExternal(start, start + size, middle);
      start += moved + size;
    }
    if (middle < end) {
      this.mergeForwardExternal(start, middle, end);
    }
  }
  copyMain(source, destination, length) {
    let offset;
    if (!(length > 0 && source !== destination)) {
      return;
    }
    if (destination > source) {
      for (offset = length - 1; offset > 0 - 1; offset += -1) {
        this.write(destination + offset, this.read(source + offset));
      }
    } else {
      for (offset = 0; offset < length; offset++) {
        this.write(destination + offset, this.read(source + offset));
      }
    }
  }
  dualMergeBackward(startIn, middleIn, endIn, destinationEndIn, external) {
    let chooseLeft, destinationEnd, end, left, middle, right, source, start;
    start = startIn;
    middle = middleIn;
    end = endIn - 1;
    destinationEnd = destinationEndIn;
    left = middle - 1;
    while (destinationEnd > end + 1 && end >= middle) {
      destinationEnd -= 1;
      if (this.compare(end, left, ">=")) {
        if (external) {
          this.write(destinationEnd, this.read(end));
        } else {
          this.swap(destinationEnd, end);
        }
        end -= 1;
      } else {
        if (external) {
          this.write(destinationEnd, this.read(left));
        } else {
          this.swap(destinationEnd, left);
        }
        left -= 1;
      }
    }
    if (end < middle) {
      if (external) {
        this.shiftBackwardExternal(start, left + 1, destinationEnd);
      } else {
        this.shiftBackward(start, left + 1, destinationEnd);
      }
    } else {
      left += 1;
      end += 1;
      destinationEnd = middle - (left - start);
      right = middle;
      while (start < left && right < end) {
        chooseLeft = this.compare(start, right, "<=");
        source = chooseLeft ? start : right;
        if (external) {
          this.write(destinationEnd, this.read(source));
        } else {
          this.swap(destinationEnd, source);
        }
        if (chooseLeft) {
          start += 1;
        } else {
          right += 1;
        }
        destinationEnd += 1;
      }
      while (start < left) {
        if (external) {
          this.write(destinationEnd, this.read(start));
        } else {
          this.swap(destinationEnd, start);
        }
        start += 1;
        destinationEnd += 1;
      }
    }
  }
  smartMerge(destinationIn, startIn, middle, reversed) {
    let chooseLeft, destination, right, start;
    destination = destinationIn;
    start = startIn;
    right = middle;
    while (start < middle) {
      chooseLeft = reversed
        ? this.compare(start, right, "<")
        : this.compare(start, right, "<=");
      if (chooseLeft) {
        this.write(destination, this.read(start));
        start += 1;
      } else {
        this.write(destination, this.read(right));
        right += 1;
      }
      destination += 1;
    }
    return right;
  }
  smartTailMerge(destinationIn, startIn, middle, end) {
    let blockLength, bufferIndex, destination, offset, right, start;
    destination = destinationIn;
    start = startIn;
    right = middle;
    blockLength = this.temp.length;
    while (start < middle && right < end) {
      if (this.compare(start, right, "<=")) {
        this.write(destination, this.read(start));
        start += 1;
      } else {
        this.write(destination, this.read(right));
        right += 1;
      }
      destination += 1;
    }
    if (start < middle) {
      if (start > destination) {
        this.shiftForwardExternal(destination, start, middle);
      }
      for (offset = 0; offset < blockLength; offset++) {
        this.write(end - blockLength + offset, this.load(offset));
      }
    } else {
      bufferIndex = 0;
      while (bufferIndex < blockLength && right < end) {
        if (
          this.compareValues(this.load(bufferIndex), this.read(right), "<=")
        ) {
          this.write(destination, this.load(bufferIndex));
          bufferIndex += 1;
        } else {
          this.write(destination, this.read(right));
          right += 1;
        }
        destination += 1;
      }
      while (bufferIndex < blockLength) {
        this.write(destination, this.load(bufferIndex));
        bufferIndex += 1;
        destination += 1;
      }
    }
  }
  blockCycle(start, tagStart, sortedTags, tagCount, blockLength) {
    let index, next, position;
    if (!(tagCount > 1)) {
      return;
    }
    for (index = 0; index < tagCount - 1; index++) {
      if (
        this.compare(tagStart + index, sortedTags + index, ">") ||
        (index > 0 &&
          this.compare(tagStart + index, sortedTags + index - 1, "<"))
      ) {
        this.copyMain(
          start + index * blockLength,
          start - blockLength,
          blockLength,
        );
        position = index;
        next =
          this.leftBinSearch(
            sortedTags,
            sortedTags + tagCount,
            this.read(tagStart + index),
          ) - sortedTags;
        while (true) {
          this.copyMain(
            start + next * blockLength,
            start + position * blockLength,
            blockLength,
          );
          this.swap(tagStart + index, tagStart + next);
          position = next;
          next =
            this.leftBinSearch(
              sortedTags,
              sortedTags + tagCount,
              this.read(tagStart + index),
            ) - sortedTags;
          if (!(next !== index)) {
            break;
          }
        }
        this.copyMain(
          start - blockLength,
          start + position * blockLength,
          blockLength,
        );
      }
    }
  }
  blockCycleEasy(start, tagStart, sortedTags, tagCount, blockLength) {
    let index, next;
    if (!(tagCount > 1)) {
      return;
    }
    for (index = 0; index < tagCount - 1; index++) {
      if (
        this.compare(tagStart + index, sortedTags + index, ">") ||
        (index > 0 &&
          this.compare(tagStart + index, sortedTags + index - 1, "<"))
      ) {
        next =
          this.leftBinSearch(
            sortedTags,
            sortedTags + tagCount,
            this.read(tagStart + index),
          ) - sortedTags;
        while (true) {
          this.multiSwap(
            start + index * blockLength,
            start + next * blockLength,
            blockLength,
          );
          this.swap(tagStart + index, tagStart + next);
          next =
            this.leftBinSearch(
              sortedTags,
              sortedTags + tagCount,
              this.read(tagStart + index),
            ) - sortedTags;
          if (!(next !== index)) {
            break;
          }
        }
      }
    }
  }
  inPlaceMergeBackward(start, middleIn, endIn, reversed) {
    let end, finalEnd, insertion, middle, moved;
    middle = middleIn;
    end = endIn;
    finalEnd = reversed
      ? this.rightBinarySearch(middle, end, this.read(middle - 1))
      : this.leftBinSearch(middle, end, this.read(middle - 1));
    end = finalEnd;
    while (end > middle && middle > start) {
      insertion = reversed
        ? this.leftBinSearch(start, middle, this.read(end - 1))
        : this.rightBinarySearch(start, middle, this.read(end - 1));
      this.rotate(insertion, middle, end);
      moved = middle - insertion;
      middle = insertion;
      end -= moved + 1;
      if (middle === start) {
        break;
      }
      end = reversed
        ? this.rightBinarySearch(middle, end, this.read(middle - 1))
        : this.leftBinSearch(middle, end, this.read(middle - 1));
    }
    return finalEnd;
  }
  blockMerge(
    start,
    middle,
    end,
    leftTagCount,
    tagCount,
    tagStartIn,
    sortedTagsIn,
    firstBitsIn,
    secondBitsIn,
    blockLength,
  ) {
    let bitsEnd,
      firstBits,
      fragment,
      leftBlock,
      leftTag,
      nextBlock,
      offset,
      outputTag,
      reversed,
      rightBlock,
      rightTag,
      secondBits,
      sortedTags,
      tagStart;
    if (end - middle <= blockLength) {
      this.mergeBackwardExternal(start, middle, end);
      return;
    }
    this.insertTo(tagStartIn + leftTagCount - 1, tagStartIn);
    leftBlock = start + blockLength - 1;
    rightBlock = middle + blockLength - 1;
    leftTag = tagStartIn;
    rightTag = tagStartIn + leftTagCount;
    outputTag = sortedTagsIn;
    firstBits = firstBitsIn;
    secondBits = secondBitsIn;
    while (
      leftTag < tagStartIn + leftTagCount &&
      rightTag < tagStartIn + tagCount
    ) {
      if (this.compare(leftBlock, rightBlock, "<=")) {
        this.swap(outputTag, leftTag);
        outputTag += 1;
        leftTag += 1;
        leftBlock += blockLength;
      } else {
        this.swap(outputTag, rightTag);
        outputTag += 1;
        rightTag += 1;
        this.swap(firstBits, secondBits);
        rightBlock += blockLength;
      }
      firstBits += 1;
      secondBits += 1;
    }
    while (leftTag < tagStartIn + leftTagCount) {
      this.swap(outputTag, leftTag);
      outputTag += 1;
      leftTag += 1;
      firstBits += 1;
      secondBits += 1;
    }
    while (rightTag < tagStartIn + tagCount) {
      this.swap(outputTag, rightTag);
      outputTag += 1;
      rightTag += 1;
      this.swap(firstBits, secondBits);
      firstBits += 1;
      secondBits += 1;
    }
    tagStart = sortedTagsIn;
    sortedTags = tagStartIn;
    this.heapSort(sortedTags, sortedTags + tagCount);
    for (offset = 0; offset < blockLength; offset++) {
      this.save(offset, this.read(middle - blockLength + offset));
    }
    this.copyMain(start, middle - blockLength, blockLength);
    this.blockCycle(
      start + blockLength,
      tagStart,
      sortedTags,
      tagCount,
      blockLength,
    );
    this.multiSwap(tagStart, sortedTags, tagCount);
    firstBits -= tagCount;
    secondBits -= tagCount;
    fragment = start + blockLength;
    nextBlock = fragment;
    bitsEnd = secondBits + tagCount;
    reversed = this.compare(firstBits, secondBits, ">");
    while (true) {
      while (true) {
        if (reversed) {
          this.swap(firstBits, secondBits);
        }
        firstBits += 1;
        secondBits += 1;
        nextBlock += blockLength;
        if (!(
          secondBits < bitsEnd &&
          this.compare(firstBits, secondBits, reversed ? ">" : "<")
        )) {
          break;
        }
      }
      if (secondBits === bitsEnd) {
        this.smartTailMerge(
          fragment - blockLength,
          fragment,
          reversed ? fragment : nextBlock,
          end,
        );
        return;
      }
      fragment = this.smartMerge(
        fragment - blockLength,
        fragment,
        nextBlock,
        reversed,
      );
      reversed = !reversed;
    }
  }
  blockMergeEasy(
    start,
    middle,
    end,
    leftTail,
    rightTail,
    leftTagCount,
    tagCount,
    tagStartIn,
    sortedTagsIn,
    firstBitsIn,
    secondBitsIn,
    blockLength,
  ) {
    let _,
      bitsEnd,
      dataEnd,
      dataStart,
      firstBits,
      fragment,
      leftBlock,
      leftTag,
      nextBlock,
      outputTag,
      reversed,
      rightBlock,
      rightTag,
      secondBits,
      sortedTags,
      tagStart;
    if (end - middle <= blockLength) {
      _ = this.inPlaceMergeBackward(start, middle, end, false);
      return;
    }
    dataStart = start + leftTail;
    dataEnd = end - rightTail;
    leftBlock = dataStart + blockLength - 1;
    rightBlock = middle + blockLength - 1;
    leftTag = sortedTagsIn;
    rightTag = sortedTagsIn + leftTagCount;
    outputTag = tagStartIn;
    firstBits = firstBitsIn;
    secondBits = secondBitsIn;
    while (
      leftTag < sortedTagsIn + leftTagCount &&
      rightTag < sortedTagsIn + tagCount
    ) {
      if (this.compare(leftBlock, rightBlock, "<=")) {
        this.swap(leftTag, outputTag);
        leftTag += 1;
        outputTag += 1;
        leftBlock += blockLength;
      } else {
        this.swap(rightTag, outputTag);
        rightTag += 1;
        outputTag += 1;
        this.swap(firstBits, secondBits);
        rightBlock += blockLength;
      }
      firstBits += 1;
      secondBits += 1;
    }
    while (leftTag < sortedTagsIn + leftTagCount) {
      this.swap(leftTag, outputTag);
      leftTag += 1;
      outputTag += 1;
      firstBits += 1;
      secondBits += 1;
    }
    while (rightTag < sortedTagsIn + tagCount) {
      this.swap(rightTag, outputTag);
      rightTag += 1;
      outputTag += 1;
      this.swap(firstBits, secondBits);
      firstBits += 1;
      secondBits += 1;
    }
    tagStart = sortedTagsIn;
    sortedTags = tagStartIn;
    this.heapSort(sortedTags, sortedTags + tagCount);
    this.blockCycleEasy(dataStart, tagStart, sortedTags, tagCount, blockLength);
    this.multiSwap(tagStart, sortedTags, tagCount);
    firstBits -= tagCount;
    secondBits -= tagCount;
    fragment = dataStart;
    nextBlock = fragment;
    bitsEnd = secondBits + tagCount;
    reversed = this.compare(firstBits, secondBits, ">");
    while (true) {
      while (true) {
        if (reversed) {
          this.swap(firstBits, secondBits);
        }
        firstBits += 1;
        secondBits += 1;
        nextBlock += blockLength;
        if (!(
          secondBits < bitsEnd &&
          this.compare(firstBits, secondBits, reversed ? ">" : "<")
        )) {
          break;
        }
      }
      if (secondBits === bitsEnd) {
        if (!reversed) {
          _ = this.inPlaceMergeBackward(dataStart, dataEnd, end, false);
        }
        this.inPlaceMerge(start, dataStart, end);
        return;
      }
      fragment = this.inPlaceMergeBackward(
        fragment,
        nextBlock,
        nextBlock + blockLength,
        reversed,
      );
      reversed = !reversed;
    }
  }
  sift(start, rootIn, limit) {
    let child, root;
    root = rootIn;
    while (root * 2 + 1 < limit) {
      child = root * 2 + 1;
      if (
        child + 1 < limit &&
        this.compare(start + child, start + child + 1, "<")
      ) {
        child += 1;
      }
      if (!this.compare(start + root, start + child, "<")) {
        return;
      }
      this.swap(start + root, start + child);
      root = child;
    }
  }
  heapSort(start, end) {
    let count, limit, root;
    count = end - start;
    if (!(count > 1)) {
      return;
    }
    for (root = Math.floor((count - 2) / 2); root > 0 - 1; root += -1) {
      this.sift(start, root, count);
    }
    for (limit = count - 1; limit > 1 - 1; limit += -1) {
      this.swap(start, start + limit);
      this.sift(start, 0, limit);
    }
  }
  sort() {
    let _,
      bitEnd,
      bitSeparation,
      blockLength,
      count,
      cubeRoot,
      dataLength,
      dataStart,
      end,
      index,
      keyEnd,
      keyLength,
      keys,
      leftTail,
      limit,
      middle,
      minimumLevel,
      offset,
      runLength,
      start,
      tagCount,
      vacant;
    count = this.values.length;
    start = 0;
    end = count;
    cubeRoot = 2 * this.ceilCbrt(Math.floor(count / 4));
    blockLength = 2 * cubeRoot;
    keyLength = this.calcKeys(blockLength, count);
    this.temp = Array(blockLength).fill(0);
    keys = this.findKeys(start, end, 2 * keyLength, cubeRoot);
    if (keys < 8) {
      runLength = 1;
      while (runLength < count) {
        middle = start + runLength;
        while (middle < end) {
          _ = this.inPlaceMergeBackward(
            middle - runLength,
            middle,
            Math.min(middle + runLength, end),
            false,
          );
          middle += 2 * runLength;
        }
        runLength *= 2;
      }
      return;
    }
    if (keys < 2 * keyLength) {
      keys -= keys % 4;
      keyLength = Math.floor(keys / 2);
    }
    keyEnd = start + keys;
    bitEnd = keyEnd + keys;
    bitSeparation = this.findBits(keyEnd, end, keyLength, cubeRoot);
    if (bitSeparation === -1) {
      this.laziestSortExternal(start, bitEnd);
      this.inPlaceMerge(start, bitEnd, end);
      return;
    }
    dataStart = bitEnd + blockLength;
    dataLength = end - dataStart;
    this.binaryInsertion(bitEnd, dataStart);
    for (offset = 0; offset < blockLength; offset++) {
      this.save(offset, this.read(bitEnd + offset));
    }
    runLength = 1;
    while (runLength < cubeRoot) {
      vacant = Math.max(2, runLength);
      index = dataStart;
      while (index + 2 * runLength < end) {
        this.mergeWithBufferForward(
          index,
          index + runLength,
          index + 2 * runLength,
          index - vacant,
          true,
        );
        index += 2 * runLength;
      }
      if (index + runLength < end) {
        this.mergeWithBufferForward(
          index,
          index + runLength,
          end,
          index - vacant,
          true,
        );
      } else {
        this.shiftForwardExternal(index - vacant, index, end);
      }
      dataStart -= vacant;
      end -= vacant;
      runLength *= 2;
    }
    index = end - (dataLength % (2 * runLength));
    if (index + runLength < end) {
      this.mergeWithBufferBackward(
        index,
        index + runLength,
        end,
        end + runLength,
        true,
      );
    } else {
      this.shiftBackwardExternal(index, end, end + runLength);
    }
    index -= 2 * runLength;
    while (index >= dataStart) {
      this.mergeWithBufferBackward(
        index,
        index + runLength,
        index + 2 * runLength,
        index + 3 * runLength,
        true,
      );
      index -= 2 * runLength;
    }
    dataStart += runLength;
    end += runLength;
    runLength *= 2;
    index = dataStart;
    while (index + 2 * runLength < end) {
      this.mergeWithBufferForward(
        index,
        index + runLength,
        index + 2 * runLength,
        index - runLength,
        true,
      );
      index += 2 * runLength;
    }
    if (index + runLength < end) {
      this.mergeWithBufferForward(
        index,
        index + runLength,
        end,
        index - runLength,
        true,
      );
    } else {
      this.shiftForwardExternal(index - runLength, index, end);
    }
    dataStart -= runLength;
    end -= runLength;
    runLength *= 2;
    index = end - (dataLength % (2 * runLength));
    if (index + runLength < end) {
      this.dualMergeBackward(
        index,
        index + runLength,
        end,
        end + Math.floor(runLength / 2),
        true,
      );
    } else {
      this.shiftBackwardExternal(index, end, end + Math.floor(runLength / 2));
    }
    index -= 2 * runLength;
    while (index >= dataStart) {
      this.dualMergeBackward(
        index,
        index + runLength,
        index + 2 * runLength,
        index + 2 * runLength + Math.floor(runLength / 2),
        true,
      );
      index -= 2 * runLength;
    }
    dataStart += Math.floor(runLength / 2);
    end += Math.floor(runLength / 2);
    runLength *= 2;
    if (keys >= runLength) {
      this.rotate(start, keyEnd, dataStart);
      bitEnd = keyEnd + blockLength;
      if (keyLength >= runLength) {
        minimumLevel = 2 * runLength;
        while (runLength < keyLength) {
          vacant = Math.max(minimumLevel, runLength);
          index = dataStart;
          while (index + 2 * runLength < end) {
            this.mergeWithBufferForward(
              index,
              index + runLength,
              index + 2 * runLength,
              index - vacant,
              false,
            );
            index += 2 * runLength;
          }
          if (index + runLength < end) {
            this.mergeWithBufferForward(
              index,
              index + runLength,
              end,
              index - vacant,
              false,
            );
          } else {
            this.shiftForward(index - vacant, index, end);
          }
          dataStart -= vacant;
          end -= vacant;
          runLength *= 2;
        }
        index = end - (dataLength % (2 * runLength));
        if (index + runLength < end) {
          this.mergeWithBufferBackward(
            index,
            index + runLength,
            end,
            end + runLength,
            false,
          );
        } else {
          this.shiftBackward(index, end, end + runLength);
        }
        index -= 2 * runLength;
        while (index >= dataStart) {
          this.mergeWithBufferBackward(
            index,
            index + runLength,
            index + 2 * runLength,
            index + 3 * runLength,
            false,
          );
          index -= 2 * runLength;
        }
        dataStart += runLength;
        end += runLength;
        runLength *= 2;
      }
      if (keys >= runLength) {
        index = dataStart;
        while (index + 2 * runLength < end) {
          this.mergeWithBufferForward(
            index,
            index + runLength,
            index + 2 * runLength,
            index - runLength,
            false,
          );
          index += 2 * runLength;
        }
        if (index + runLength < end) {
          this.mergeWithBufferForward(
            index,
            index + runLength,
            end,
            index - runLength,
            false,
          );
        } else {
          this.shiftForward(index - runLength, index, end);
        }
        dataStart -= runLength;
        end -= runLength;
        runLength *= 2;
        index = end - (dataLength % (2 * runLength));
        if (index + runLength < end) {
          this.dualMergeBackward(
            index,
            index + runLength,
            end,
            end + Math.floor(runLength / 2),
            false,
          );
        } else {
          this.shiftBackward(index, end, end + Math.floor(runLength / 2));
        }
        index -= 2 * runLength;
        while (index >= dataStart) {
          this.dualMergeBackward(
            index,
            index + runLength,
            index + 2 * runLength,
            index + 2 * runLength + Math.floor(runLength / 2),
            false,
          );
          index -= 2 * runLength;
        }
        dataStart += Math.floor(runLength / 2);
        end += Math.floor(runLength / 2);
        runLength *= 2;
      }
      this.rotate(start, bitEnd, dataStart);
      bitEnd = keyEnd + keys;
      this.heapSort(start, keyEnd);
    }
    for (offset = 0; offset < blockLength; offset++) {
      this.write(bitEnd + offset, this.load(offset));
    }
    this.unshuffle(start, keyEnd);
    limit = blockLength * (keyLength + 2);
    tagCount = Math.floor(runLength / blockLength) - 1;
    while (
      runLength < dataLength &&
      Math.min(2 * runLength, dataLength) <= limit
    ) {
      index = dataStart;
      while (index + 2 * runLength <= end) {
        this.blockMerge(
          index,
          index + runLength,
          index + 2 * runLength,
          tagCount,
          2 * tagCount,
          start,
          start + keyLength,
          keyEnd,
          keyEnd + keyLength,
          blockLength,
        );
        index += 2 * runLength;
      }
      if (index + runLength < end) {
        this.blockMerge(
          index,
          index + runLength,
          end,
          tagCount,
          Math.floor((end - index - 1) / blockLength) - 1,
          start,
          start + keyLength,
          keyEnd,
          keyEnd + keyLength,
          blockLength,
        );
      }
      runLength *= 2;
      tagCount = 2 * tagCount + 1;
    }
    while (runLength < dataLength) {
      blockLength = Math.floor((2 * runLength) / keyLength);
      leftTail = runLength % blockLength;
      index = dataStart;
      while (index + 2 * runLength <= end) {
        this.blockMergeEasy(
          index,
          index + runLength,
          index + 2 * runLength,
          leftTail,
          leftTail,
          Math.floor(keyLength / 2),
          keyLength,
          start,
          start + keyLength,
          keyEnd,
          keyEnd + keyLength,
          blockLength,
        );
        index += 2 * runLength;
      }
      if (index + runLength < end) {
        this.blockMergeEasy(
          index,
          index + runLength,
          end,
          leftTail,
          (end - index - runLength) % blockLength,
          Math.floor(keyLength / 2),
          Math.floor(keyLength / 2) +
            Math.floor((end - index - runLength) / blockLength),
          start,
          start + keyLength,
          keyEnd,
          keyEnd + keyLength,
          blockLength,
        );
      }
      runLength *= 2;
    }
    this.multiSwap(
      keyEnd + bitSeparation,
      keyEnd + keyLength + bitSeparation,
      keyLength - bitSeparation,
    );
    this.laziestSortExternal(start, dataStart);
    this.redistributeBuffer(start, dataStart, end);
  }
}
function sort(values) {
  if (values.length >= 32 && values.length < 128)
    fifthSort(values, values.length);
  else {
    const sorter = new ChaliceSortExample(values);
    if (values.length < 32) sorter.binaryInsertion(0, values.length);
    else sorter.sort();
  }
}
const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array);
console.log("[" + array.join(", ") + "]");
