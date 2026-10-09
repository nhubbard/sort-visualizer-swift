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
#include <stdio.h>
#include <stdlib.h>

typedef struct { int *a, *buffer, *tags; } Sqrt;
static int readValue(Sqrt *s, int storage, int index) { return storage ? s->buffer[index] : s->a[index]; }
static void writeValue(Sqrt *s, int storage, int index, int value) { (storage ? s->buffer : s->a)[index] = value; }
static int compare(Sqrt *s, int firstStorage, int first, int secondStorage, int second) {
  int a = readValue(s, firstStorage, first), b = readValue(s, secondStorage, second);
  return (a > b) - (a < b);
}
static void copyValues(Sqrt *s, int sourceStorage, int source, int targetStorage, int target, int count) {
  if (sourceStorage == targetStorage && source < target && target < source + count) {
    for (int i = count - 1; i >= 0; i--)
      writeValue(s, targetStorage, target + i, readValue(s, sourceStorage, source + i));
  } else {
    for (int i = 0; i < count; i++)
      writeValue(s, targetStorage, target + i, readValue(s, sourceStorage, source + i));
  }
}
static void swapValues(Sqrt *s, int storage, int a, int b) {
  if (a == b) return;
  int first = readValue(s, storage, a);
  writeValue(s, storage, a, readValue(s, storage, b));
  writeValue(s, storage, b, first);
}
static void insertion(Sqrt *s, int storage, int position, int length) {
  for (int index = position + 1; index < position + length; index++) {
    int value = readValue(s, storage, index), cursor = index;
    while (cursor > position && readValue(s, storage, cursor - 1) > value) {
      writeValue(s, storage, cursor, readValue(s, storage, cursor - 1));
      cursor--;
    }
    writeValue(s, storage, cursor, value);
  }
}
static void mergeRight(Sqrt *s, int storage, int position, int leftLength, int rightLength, int distance) {
  int destination = position + leftLength + rightLength + distance - 1;
  int right = position + leftLength + rightLength - 1, left = position + leftLength - 1;
  while (left >= position) {
    if (right < position + leftLength || compare(s, storage, left, storage, right) > 0)
      writeValue(s, storage, destination, readValue(s, storage, left--));
    else writeValue(s, storage, destination, readValue(s, storage, right--));
    destination--;
  }
  if (right != destination) while (right >= position + leftLength)
    writeValue(s, storage, destination--, readValue(s, storage, right--));
}
static void mergeLeft(Sqrt *s, int storage, int position, int leftLength, int rightLength, int distance) {
  int left = position, right = position + leftLength, destination = position + distance;
  int leftEnd = right, rightEnd = right + rightLength;
  while (right < rightEnd) {
    if (left == leftEnd || compare(s, storage, left, storage, right) > 0)
      writeValue(s, storage, destination, readValue(s, storage, right++));
    else writeValue(s, storage, destination, readValue(s, storage, left++));
    destination++;
  }
  if (destination != left) while (left < leftEnd)
    writeValue(s, storage, destination++, readValue(s, storage, left++));
}
static void mergeDown(Sqrt *s, int storage, int position, int prefix, int prefixPosition, int leftLength, int prefixLength) {
  int left = 0, right = 0, destination = position - prefixLength;
  while (right < prefixLength) {
    if (left == leftLength || compare(s, storage, position + left, prefix, prefixPosition + right) >= 0)
      writeValue(s, storage, destination, readValue(s, prefix, prefixPosition + right++));
    else writeValue(s, storage, destination, readValue(s, storage, position + left++));
    destination++;
  }
  if (destination != position + left) while (left < leftLength)
    writeValue(s, storage, destination++, readValue(s, storage, position + left++));
}
static void smartMerge(Sqrt *s, int storage, int position, int *priorLength, int *priorFragment, int blockLength) {
  int left = position, right = position + *priorLength, destination = position - blockLength;
  int leftEnd = right, rightEnd = right + blockLength, opposite = 1 - *priorFragment;
  while (left < leftEnd && right < rightEnd) {
    int order = compare(s, storage, left, storage, right);
    if (order < 0 || (order == 0 && opposite == 1))
      writeValue(s, storage, destination, readValue(s, storage, left++));
    else writeValue(s, storage, destination, readValue(s, storage, right++));
    destination++;
  }
  if (left < leftEnd) {
    int remaining = leftEnd - left;
    while (left < leftEnd) {
      leftEnd--; rightEnd--;
      writeValue(s, storage, rightEnd, readValue(s, storage, leftEnd));
    }
    *priorLength = remaining;
  } else {
    *priorLength = rightEnd - right;
    *priorFragment = opposite;
  }
}
static void mergeBuffers(Sqrt *s, int storage, int position, int middleTag, int blockCount,
                         int blockLength, int trailingABlocks, int tailLength) {
  if (blockCount == 0) {
    mergeLeft(s, storage, position, trailingABlocks * blockLength, tailLength, -blockLength);
    return;
  }
  int priorLength = blockLength, priorFragment = s->tags[0] < middleTag ? 0 : 1;
  int process = blockLength;
  for (int tagIndex = 1; tagIndex < blockCount; tagIndex++) {
    int rest = process - priorLength;
    int nextFragment = s->tags[tagIndex] < middleTag ? 0 : 1;
    if (nextFragment == priorFragment) {
      copyValues(s, storage, position + rest, storage, position + rest - blockLength, priorLength);
      rest = process;
      priorLength = blockLength;
    } else smartMerge(s, storage, position + rest, &priorLength, &priorFragment, blockLength);
    process += blockLength;
  }
  int rest = process - priorLength;
  if (tailLength != 0) {
    if (priorFragment != 0) {
      copyValues(s, storage, position + rest, storage, position + rest - blockLength, priorLength);
      rest = process;
      priorLength = blockLength * trailingABlocks;
    } else priorLength += blockLength * trailingABlocks;
    mergeLeft(s, storage, position + rest, priorLength, tailLength, -blockLength);
  } else copyValues(s, storage, position + rest, storage, position + rest - blockLength, priorLength);
}
static void buildBlocks(Sqrt *s, int storage, int position, int length, int blockLength) {
  int pair = 1;
  while (pair < length) {
    int lower = compare(s, storage, position + pair - 1, storage, position + pair) > 0 ? 1 : 0;
    writeValue(s, storage, position + pair - 3, readValue(s, storage, position + pair - 1 + lower));
    writeValue(s, storage, position + pair - 2, readValue(s, storage, position + pair - lower));
    pair += 2;
  }
  if (length % 2) writeValue(s, storage, position + length - 3, readValue(s, storage, position + length - 1));
  position -= 2;
  int part = 2;
  while (part < blockLength) {
    int left = 0, right = length - 2 * part;
    while (left <= right) { mergeLeft(s, storage, position + left, part, part, -part); left += 2 * part; }
    int rest = length - left;
    if (rest > part) mergeLeft(s, storage, position + left, part, rest - part, -part);
    else while (left < length) {
      writeValue(s, storage, position + left - part, readValue(s, storage, position + left));
      left++;
    }
    position -= part;
    part *= 2;
  }
  int remainder = length % (2 * blockLength), leftover = length - remainder;
  if (remainder <= blockLength)
    copyValues(s, storage, position + leftover, storage, position + leftover + blockLength, remainder);
  else mergeRight(s, storage, position + leftover, blockLength, remainder - blockLength, blockLength);
  while (leftover > 0) {
    leftover -= 2 * blockLength;
    mergeRight(s, storage, position + leftover, blockLength, blockLength, blockLength);
  }
}
static void combineBlocks(Sqrt *s, int storage, int position, int length, int runLength, int blockLength) {
  int combineCount = length / (2 * runLength), remainder = length % (2 * runLength);
  if (remainder <= runLength) { length -= remainder; remainder = 0; }
  for (int group = 0; group <= combineCount; group++) {
    if (group == combineCount && remainder == 0) break;
    int groupPosition = position + group * 2 * runLength;
    int count = (group == combineCount ? remainder : 2 * runLength) / blockLength;
    int tagEnd = count + (group == combineCount ? 1 : 0);
    for (int tag = 0; tag <= tagEnd; tag++) s->tags[tag] = tag;
    int middle = runLength / blockLength;
    for (int tagIndex = 1; tagIndex < count; tagIndex++) {
      int selected = tagIndex - 1;
      for (int candidate = tagIndex; candidate < count; candidate++) {
        int order = compare(s, storage, groupPosition + selected * blockLength,
                            storage, groupPosition + candidate * blockLength);
        if (order > 0 || (order == 0 && s->tags[selected] > s->tags[candidate])) selected = candidate;
      }
      if (selected != tagIndex - 1) {
        for (int offset = 0; offset < blockLength; offset++)
          swapValues(s, storage, groupPosition + (tagIndex - 1) * blockLength + offset,
                     groupPosition + selected * blockLength + offset);
        int firstTag = s->tags[tagIndex - 1];
        s->tags[tagIndex - 1] = s->tags[selected];
        s->tags[selected] = firstTag;
      }
    }
    int trailingA = 0, tail = group == combineCount ? remainder % blockLength : 0;
    if (tail) while (trailingA < count && compare(s, storage, groupPosition + count * blockLength,
              storage, groupPosition + (count - trailingA - 1) * blockLength) < 0) trailingA++;
    mergeBuffers(s, storage, groupPosition, middle, count - trailingA, blockLength, trailingA, tail);
  }
  if (length > 0) for (int index = length - 1; index >= 0; index--)
    writeValue(s, storage, position + index, readValue(s, storage, position + index - blockLength));
}
static void commonSort(Sqrt *s, int storage, int position, int length, int prefix, int prefixPosition) {
  if (length <= 16) { insertion(s, storage, position, length); return; }
  int blockLength = 1;
  while (blockLength * blockLength < length) blockLength *= 2;
  copyValues(s, storage, position, prefix, prefixPosition, blockLength);
  commonSort(s, prefix, prefixPosition, blockLength, storage, position);
  buildBlocks(s, storage, position + blockLength, length - blockLength, blockLength);
  int runLength = blockLength;
  while (1) {
    runLength *= 2;
    if (length <= runLength) break;
    combineBlocks(s, storage, position + blockLength, length - blockLength, runLength, blockLength);
  }
  mergeDown(s, storage, position + blockLength, prefix, prefixPosition, length - blockLength, blockLength);
}
void sort(int a[], int n) {
  if (n < 2) return;
  int bufferLength = 1;
  while (bufferLength * bufferLength < n) bufferLength *= 2;
  Sqrt s = { a, NULL, NULL };
  s.buffer = malloc((size_t)bufferLength * sizeof(int));
  s.tags = malloc((size_t)((n - 1) / bufferLength + 2) * sizeof(int));
  if (!s.buffer || !s.tags) abort();
  commonSort(&s, 0, 0, n, 1, 0);
  free(s.buffer);
  free(s.tags);
}
int main(void) {
  int array[] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
  int n = sizeof(array) / sizeof(array[0]);
  sort(array, n);
  printf("[");
  for (int i = 0; i < n; i++) printf(i ? ", %d" : "%d", array[i]);
  puts("]");
  return 0;
}
