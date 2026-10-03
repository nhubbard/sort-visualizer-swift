// MIT License
// Copyright (c) 2014 Andrey Astrelin
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
function readValue(s, storage, index) { return storage ? s.buffer[index] : s.a[index]; }
function writeValue(s, storage, index, value) { (storage ? s.buffer : s.a)[index] = value; }
function compare(s, firstStorage, first, secondStorage, second) {
  let a = readValue(s, firstStorage, first), b = readValue(s, secondStorage, second);
  return (a > b) - (a < b);
}
function copyValues(s, sourceStorage, source, targetStorage, target, count) {
  if (sourceStorage == targetStorage && source < target && target < source + count) {
    for (let i = count - 1; i >= 0; i--)
      writeValue(s, targetStorage, target + i, readValue(s, sourceStorage, source + i));
  } else {
    for (let i = 0; i < count; i++)
      writeValue(s, targetStorage, target + i, readValue(s, sourceStorage, source + i));
  }
}
function swapValues(s, storage, a, b) {
  if (a == b) return;
  let first = readValue(s, storage, a);
  writeValue(s, storage, a, readValue(s, storage, b));
  writeValue(s, storage, b, first);
}
function insertion(s, storage, position, length) {
  for (let index = position + 1; index < position + length; index++) {
    let value = readValue(s, storage, index), cursor = index;
    while (cursor > position && readValue(s, storage, cursor - 1) > value) {
      writeValue(s, storage, cursor, readValue(s, storage, cursor - 1));
      cursor--;
    }
    writeValue(s, storage, cursor, value);
  }
}
function mergeRight(s, storage, position, leftLength, rightLength, distance) {
  let destination = position + leftLength + rightLength + distance - 1;
  let right = position + leftLength + rightLength - 1, left = position + leftLength - 1;
  while (left >= position) {
    if (right < position + leftLength || compare(s, storage, left, storage, right) > 0)
      writeValue(s, storage, destination, readValue(s, storage, left--));
    else writeValue(s, storage, destination, readValue(s, storage, right--));
    destination--;
  }
  if (right != destination) while (right >= position + leftLength)
    writeValue(s, storage, destination--, readValue(s, storage, right--));
}
function mergeLeft(s, storage, position, leftLength, rightLength, distance) {
  let left = position, right = position + leftLength, destination = position + distance;
  let leftEnd = right, rightEnd = right + rightLength;
  while (right < rightEnd) {
    if (left == leftEnd || compare(s, storage, left, storage, right) > 0)
      writeValue(s, storage, destination, readValue(s, storage, right++));
    else writeValue(s, storage, destination, readValue(s, storage, left++));
    destination++;
  }
  if (destination != left) while (left < leftEnd)
    writeValue(s, storage, destination++, readValue(s, storage, left++));
}
function mergeDown(s, storage, position, prefix, prefixPosition, leftLength, prefixLength) {
  let left = 0, right = 0, destination = position - prefixLength;
  while (right < prefixLength) {
    if (left == leftLength || compare(s, storage, position + left, prefix, prefixPosition + right) >= 0)
      writeValue(s, storage, destination, readValue(s, prefix, prefixPosition + right++));
    else writeValue(s, storage, destination, readValue(s, storage, position + left++));
    destination++;
  }
  if (destination != position + left) while (left < leftLength)
    writeValue(s, storage, destination++, readValue(s, storage, position + left++));
}
function smartMerge(s, storage, position, prior, blockLength) {
  let left = position, right = position + prior[0], destination = position - blockLength;
  let leftEnd = right, rightEnd = right + blockLength, opposite = 1 - prior[1];
  while (left < leftEnd && right < rightEnd) {
    let order = compare(s, storage, left, storage, right);
    if (order < 0 || (order == 0 && opposite == 1))
      writeValue(s, storage, destination, readValue(s, storage, left++));
    else writeValue(s, storage, destination, readValue(s, storage, right++));
    destination++;
  }
  if (left < leftEnd) {
    let remaining = leftEnd - left;
    while (left < leftEnd) {
      leftEnd--; rightEnd--;
      writeValue(s, storage, rightEnd, readValue(s, storage, leftEnd));
    }
    prior[0] = remaining;
  } else {
    prior[0] = rightEnd - right;
    prior[1] = opposite;
  }
}
function mergeBuffers(s, storage, position, middleTag, blockCount,
                         blockLength, trailingABlocks, tailLength) {
  if (blockCount == 0) {
    mergeLeft(s, storage, position, trailingABlocks * blockLength, tailLength, -blockLength);
    return;
  }
  let priorLength = blockLength, priorFragment = s.tags[0] < middleTag ? 0 : 1;
  let process = blockLength;
  for (let tagIndex = 1; tagIndex < blockCount; tagIndex++) {
    let rest = process - priorLength;
    let nextFragment = s.tags[tagIndex] < middleTag ? 0 : 1;
    if (nextFragment == priorFragment) {
      copyValues(s, storage, position + rest, storage, position + rest - blockLength, priorLength);
      rest = process;
      priorLength = blockLength;
    } else { let prior = [priorLength, priorFragment]; smartMerge(s, storage, position + rest, prior, blockLength); priorLength = prior[0]; priorFragment = prior[1]; }
    process += blockLength;
  }
  let rest = process - priorLength;
  if (tailLength != 0) {
    if (priorFragment != 0) {
      copyValues(s, storage, position + rest, storage, position + rest - blockLength, priorLength);
      rest = process;
      priorLength = blockLength * trailingABlocks;
    } else priorLength += blockLength * trailingABlocks;
    mergeLeft(s, storage, position + rest, priorLength, tailLength, -blockLength);
  } else copyValues(s, storage, position + rest, storage, position + rest - blockLength, priorLength);
}
function buildBlocks(s, storage, position, length, blockLength) {
  let pair = 1;
  while (pair < length) {
    let lower = compare(s, storage, position + pair - 1, storage, position + pair) > 0 ? 1 : 0;
    writeValue(s, storage, position + pair - 3, readValue(s, storage, position + pair - 1 + lower));
    writeValue(s, storage, position + pair - 2, readValue(s, storage, position + pair - lower));
    pair += 2;
  }
  if (length % 2) writeValue(s, storage, position + length - 3, readValue(s, storage, position + length - 1));
  position -= 2;
  let part = 2;
  while (part < blockLength) {
    let left = 0, right = length - 2 * part;
    while (left <= right) { mergeLeft(s, storage, position + left, part, part, -part); left += 2 * part; }
    let rest = length - left;
    if (rest > part) mergeLeft(s, storage, position + left, part, rest - part, -part);
    else while (left < length) {
      writeValue(s, storage, position + left - part, readValue(s, storage, position + left));
      left++;
    }
    position -= part;
    part *= 2;
  }
  let remainder = length % (2 * blockLength), leftover = length - remainder;
  if (remainder <= blockLength)
    copyValues(s, storage, position + leftover, storage, position + leftover + blockLength, remainder);
  else mergeRight(s, storage, position + leftover, blockLength, remainder - blockLength, blockLength);
  while (leftover > 0) {
    leftover -= 2 * blockLength;
    mergeRight(s, storage, position + leftover, blockLength, blockLength, blockLength);
  }
}
function combineBlocks(s, storage, position, length, runLength, blockLength) {
  let combineCount = Math.floor(length / (2 * runLength)), remainder = length % (2 * runLength);
  if (remainder <= runLength) { length -= remainder; remainder = 0; }
  for (let group = 0; group <= combineCount; group++) {
    if (group == combineCount && remainder == 0) break;
    let groupPosition = position + group * 2 * runLength;
    let count = Math.floor((group == combineCount ? remainder : 2 * runLength) / blockLength);
    let tagEnd = count + (group == combineCount ? 1 : 0);
    for (let tag = 0; tag <= tagEnd; tag++) s.tags[tag] = tag;
    let middle = Math.floor(runLength / blockLength);
    for (let tagIndex = 1; tagIndex < count; tagIndex++) {
      let selected = tagIndex - 1;
      for (let candidate = tagIndex; candidate < count; candidate++) {
        let order = compare(s, storage, groupPosition + selected * blockLength,
                            storage, groupPosition + candidate * blockLength);
        if (order > 0 || (order == 0 && s.tags[selected] > s.tags[candidate])) selected = candidate;
      }
      if (selected != tagIndex - 1) {
        for (let offset = 0; offset < blockLength; offset++)
          swapValues(s, storage, groupPosition + (tagIndex - 1) * blockLength + offset,
                     groupPosition + selected * blockLength + offset);
        let firstTag = s.tags[tagIndex - 1];
        s.tags[tagIndex - 1] = s.tags[selected];
        s.tags[selected] = firstTag;
      }
    }
    let trailingA = 0, tail = group == combineCount ? remainder % blockLength : 0;
    if (tail) while (trailingA < count && compare(s, storage, groupPosition + count * blockLength,
              storage, groupPosition + (count - trailingA - 1) * blockLength) < 0) trailingA++;
    mergeBuffers(s, storage, groupPosition, middle, count - trailingA, blockLength, trailingA, tail);
  }
  if (length > 0) for (let index = length - 1; index >= 0; index--)
    writeValue(s, storage, position + index, readValue(s, storage, position + index - blockLength));
}
function commonSort(s, storage, position, length, prefix, prefixPosition) {
  if (length <= 16) { insertion(s, storage, position, length); return; }
  let blockLength = 1;
  while (blockLength * blockLength < length) blockLength *= 2;
  copyValues(s, storage, position, prefix, prefixPosition, blockLength);
  commonSort(s, prefix, prefixPosition, blockLength, storage, position);
  buildBlocks(s, storage, position + blockLength, length - blockLength, blockLength);
  let runLength = blockLength;
  while (1) {
    runLength *= 2;
    if (length <= runLength) break;
    combineBlocks(s, storage, position + blockLength, length - blockLength, runLength, blockLength);
  }
  mergeDown(s, storage, position + blockLength, prefix, prefixPosition, length - blockLength, blockLength);
}
function sort(a, n) {
  if (n < 2) return;
  let bufferLength = 1;
  while (bufferLength * bufferLength < n) bufferLength *= 2;
  let s = {a: a, buffer: null, tags: null};
  s.buffer = new Array(bufferLength).fill(0);
  s.tags = new Array(Math.floor(Math.floor((n - 1) / bufferLength)) + 2).fill(0);
  commonSort(s, 0, 0, n, 1, 0);
}

const array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56];
sort(array, array.length);
console.log("[" + array.join(", ") + "]");
