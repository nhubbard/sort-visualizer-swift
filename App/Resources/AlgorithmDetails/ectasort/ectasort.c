// MIT License
// Copyright (c) 2020-2021 aphitorite
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
#include <string.h>

typedef struct {
  int *a, *buffer, *tags;
  int block, bufferLength;
} Ecta;

static int minRun(int size) {
  while (size >= 32) size = (size + 1) / 2;
  return size;
}
static void insertion(Ecta *e, int start, int end) {
  for (int index = start + 1; index < end; index++) {
    int value = e->a[index], low = start, high = index;
    while (low < high) {
      int middle = low + (high - low) / 2;
      if (e->a[middle] > value) high = middle;
      else low = middle + 1;
    }
    for (int cursor = index; cursor > low; cursor--) e->a[cursor] = e->a[cursor - 1];
    e->a[low] = value;
  }
}
static void copyMain(Ecta *e, int source, int destination, int count) {
  if (count > 0) memmove(e->a + destination, e->a + source, (size_t)count * sizeof(int));
}
static void mergeTo(Ecta *e, int start, int middle, int end, int destination) {
  int left = start, right = middle, output = destination;
  while (left < middle && right < end)
    e->a[output++] = e->a[left] <= e->a[right] ? e->a[left++] : e->a[right++];
  while (left < middle) e->a[output++] = e->a[left++];
  while (right < end) e->a[output++] = e->a[right++];
}
static void pingPong(Ecta *e, int start, int m1, int m2, int m3, int end, int workspace) {
  int second = workspace + m2 - start;
  mergeTo(e, start, m1, m2, workspace);
  mergeTo(e, m2, m3, end, second);
  mergeTo(e, workspace, second, workspace + end - start, start);
}
static void mergeBackward(Ecta *e, int start, int middle, int end, int workspace) {
  int count = end - middle;
  copyMain(e, middle, workspace, count);
  int left = middle - 1, right = workspace + count - 1, output = end;
  while (left >= start && right >= workspace)
    e->a[--output] = e->a[left] > e->a[right] ? e->a[left--] : e->a[right--];
  while (right >= workspace) e->a[--output] = e->a[right--];
}
static void mergeFromBuffer(Ecta *e, int start, int middle, int end, int count) {
  int index = 0, right = middle, output = start;
  while (index < count && right < end)
    e->a[output++] = e->a[right] >= e->buffer[index] ? e->buffer[index++] : e->a[right++];
  while (index < count) e->a[output++] = e->buffer[index++];
}
static void dualMergeBackward(Ecta *e, int start, int first, int middle, int end, int count) {
  int index = count - 1, split = count - (end - middle);
  int left = middle - 1, output = end;
  while (index >= split && left >= first)
    e->a[--output] = e->a[left] < e->buffer[index] ? e->buffer[index--] : e->a[left--];
  if (left < first) while (index >= 0) e->a[--output] = e->buffer[index--];
  else mergeFromBuffer(e, start, first, output, split);
}
static int mergeSort(Ecta *e, int start, int end, int workspace, int initialRun, int capacity) {
  int run = initialRun, index = start;
  while (index + run <= end) { insertion(e, index, index + run); index += run; }
  insertion(e, index, end);
  while (4 * run <= capacity) {
    index = start;
    while (index + 4 * run <= end) {
      pingPong(e, index, index + run, index + 2 * run, index + 3 * run, index + 4 * run, workspace);
      index += 4 * run;
    }
    if (index + 3 * run < end)
      pingPong(e, index, index + run, index + 2 * run, index + 3 * run, end, workspace);
    else if (index + 2 * run < end)
      pingPong(e, index, index + run, index + 2 * run, end, end, workspace);
    else if (index + run < end) mergeBackward(e, index, index + run, end, workspace);
    run *= 4;
  }
  while (run <= capacity) {
    index = start;
    while (index + 2 * run <= end) {
      mergeBackward(e, index, index + run, index + 2 * run, workspace);
      index += 2 * run;
    }
    if (index + run < end) mergeBackward(e, index, index + run, end, workspace);
    run *= 2;
  }
  return run;
}
static void blockCycle(Ecta *e, int start, int count, int workspace, int excludeLast, int forward) {
  int stride = forward ? e->block : -e->block;
  for (int index = 0; index < count; index++) {
    int next = e->tags[index];
    if (index == next) continue;
    copyMain(e, start + index * stride, workspace, e->block);
    int current = index;
    while (1) {
      if (!(excludeLast && current == count - 1))
        copyMain(e, start + next * stride, start + current * stride, e->block);
      e->tags[current] = current;
      current = next;
      next = e->tags[next];
      if (next == index) break;
    }
    copyMain(e, workspace, start + current * stride, e->block);
    e->tags[current] = current;
  }
}
static void ectaForward(Ecta *e, int start, int middle, int end) {
  int block = e->block;
  int left = start, right = middle, tag = 0, tagCount = 0, saved = 2 * block;
  int savedPosition = start - 2 * block, otherPosition = middle;
  do {
    int choice = saved < block;
    for (int offset = 0; offset < block; offset++) {
      int destination = (choice ? otherPosition : savedPosition) + offset;
      if (left < middle && right < end) {
        if (e->a[left] <= e->a[right]) { e->a[destination] = e->a[left++]; saved++; }
        else { e->a[destination] = e->a[right++]; }
      } else if (left < middle) { e->a[destination] = e->a[left++]; saved++; }
      else { e->a[destination] = e->a[right++]; }
    }
    if (choice == 0) { savedPosition += block; saved -= block; }
    else { otherPosition += block; }
    e->tags[tagCount++] = choice == 0 ? tag++ : -1;
  } while (left < middle || right < end);
  if (saved > 0) e->tags[tagCount] = tag++;
  for (int index = 2; index < tagCount; index++)
    if (e->tags[index] == -1) e->tags[index] = tag++;
  blockCycle(e, start - 2 * block, tag, end - block, saved > 0, 1);
}
static void ectaBackward(Ecta *e, int start, int middle, int end) {
  int block = e->block;
  int right = end - 1, left = middle - 1, tag = 0, tagCount = 0, saved = 2 * block;
  int savedPosition = end + 2 * block, otherPosition = middle;
  do {
    int choice = saved < block;
    for (int offset = 1; offset <= block; offset++) {
      int destination = (choice ? otherPosition : savedPosition) - offset;
      if (right >= middle && left >= start) {
        if (e->a[right] >= e->a[left]) { e->a[destination] = e->a[right--]; saved++; }
        else { e->a[destination] = e->a[left--]; }
      } else if (right >= middle) { e->a[destination] = e->a[right--]; saved++; }
      else { e->a[destination] = e->a[left--]; }
    }
    if (choice == 0) { savedPosition -= block; saved -= block; }
    else { otherPosition -= block; }
    e->tags[tagCount++] = choice == 0 ? tag++ : -1;
  } while (right >= middle || left >= start);
  if (saved > 0) e->tags[tagCount] = tag++;
  for (int index = 2; index < tagCount; index++)
    if (e->tags[index] == -1) e->tags[index] = tag++;
  blockCycle(e, end + block, tag, start, saved > 0, 0);
}
void sort(int a[], int n) {
  if (n < 2) return;
  Ecta e = { a, NULL, NULL, 0, 0 };
  if (n <= 32) { insertion(&e, 0, n); return; }
  if (n < 256) e.bufferLength = n / 2;
  else {
    e.block = minRun(n);
    while (e.block * e.block < n / 2) e.block *= 2;
    e.bufferLength = 2 * e.block + n % e.block;
  }
  e.buffer = malloc((size_t)e.bufferLength * sizeof(int));
  int tagCount = e.block ? (n - e.bufferLength) / e.block + 1 : 0;
  e.tags = tagCount ? malloc((size_t)tagCount * sizeof(int)) : NULL;
  if (!e.buffer || (tagCount && !e.tags)) abort();
  if (n < 256) {
    memcpy(e.buffer, a + e.bufferLength, (size_t)e.bufferLength * sizeof(int));
    mergeSort(&e, 0, e.bufferLength, e.bufferLength, minRun(n), e.bufferLength);
    memcpy(a + e.bufferLength, e.buffer, (size_t)e.bufferLength * sizeof(int));
    memcpy(e.buffer, a, (size_t)e.bufferLength * sizeof(int));
    mergeSort(&e, e.bufferLength, n, 0, minRun(n), e.bufferLength);
    mergeFromBuffer(&e, 0, e.bufferLength, n, e.bufferLength);
    free(e.buffer);
    return;
  }
  int start = e.bufferLength, end = n, dataLength = end - start;
  memcpy(e.buffer, a + start, (size_t)e.bufferLength * sizeof(int));
  mergeSort(&e, 0, start, start, minRun(e.bufferLength), e.bufferLength);
  memcpy(a + start, e.buffer, (size_t)e.bufferLength * sizeof(int));
  memcpy(e.buffer, a, (size_t)e.bufferLength * sizeof(int));
  int run = mergeSort(&e, start, end, 0, minRun(n), e.bufferLength);
  int backward = 0;
  while (run < dataLength) {
    int index = start;
    while (index + 2 * run <= end) {
      ectaForward(&e, index, index + run, index + 2 * run);
      index += 2 * run;
    }
    if (index + run < end) ectaForward(&e, index, index + run, end);
    else copyMain(&e, index, index - 2 * e.block, end - index);
    run *= 2; start -= 2 * e.block; end -= 2 * e.block;
    if (run >= dataLength) { backward = 1; break; }
    index = start;
    while (index + 2 * run <= end) index += 2 * run;
    if (index + run < end) ectaBackward(&e, index, index + run, end);
    else copyMain(&e, index, index + 2 * e.block, end - index);
    index -= 2 * run;
    while (index >= start) {
      ectaBackward(&e, index, index + run, index + 2 * run);
      index -= 2 * run;
    }
    run *= 2; start += 2 * e.block; end += 2 * e.block;
  }
  if (backward) dualMergeBackward(&e, 0, start, end, n, e.bufferLength);
  else mergeFromBuffer(&e, 0, start, end, e.bufferLength);
  free(e.tags);
  free(e.buffer);
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
