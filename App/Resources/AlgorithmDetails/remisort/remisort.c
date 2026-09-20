#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  int *a, n, block, runLength, runs;
  int *keys, *buffer, *heap, *position, *destination;
  int size;
} Remi;

static int minimum(int x, int y) { return x < y ? x : y; }
static int greater(Remi *s, int x, int y, int start) {
  int left = s->a[start + x], right = s->a[start + y];
  return left > right || (left == right && x > y);
}
static void tableSift(Remi *s, int root, int length, int start, int item) {
  int j = root;
  while (2 * j + 1 < length) {
    j = 2 * j + 1;
    if (j + 1 < length && greater(s, s->keys[j + 1], s->keys[j], start))
      j++;
  }
  while (j > root && greater(s, item, s->keys[j], start))
    j = (j - 1) / 2;
  while (j > root) {
    int old = s->keys[j];
    s->keys[j] = item;
    item = old;
    j = (j - 1) / 2;
  }
  s->keys[root] = item;
}
static void tableSort(Remi *s, int start, int end) {
  int length = end - start;
  if (length < 2)
    return;
  for (int i = (length - 1) / 2; i >= 0; i--)
    tableSift(s, i, length, start, s->keys[i]);
  for (int i = length - 1; i > 0; i--) {
    int item = s->keys[i];
    s->keys[i] = s->keys[0];
    tableSift(s, 0, i, start, item);
  }
  for (int i = 0; i < length; i++) {
    if (s->keys[i] == i)
      continue;
    int held = s->a[start + i], j = i, next = s->keys[i];
    do {
      s->a[start + j] = s->a[start + next];
      s->keys[j] = j;
      j = next;
      next = s->keys[next];
    } while (next != i);
    s->a[start + j] = held;
    s->keys[j] = j;
  }
}
static int less(Remi *s, int x, int y) {
  int left = s->a[s->position[x]], right = s->a[s->position[y]];
  return left < right || (left == right && x < y);
}
static void sift(Remi *s, int item, int root, int length) {
  while (2 * root + 2 < length) {
    int left = 2 * root + 1;
    int child = less(s, s->heap[left], s->heap[left + 1]) ? left : left + 1;
    if (!less(s, s->heap[child], item))
      break;
    s->heap[root] = s->heap[child];
    root = child;
  }
  int last = 2 * root + 1;
  if (last < length && less(s, s->heap[last], item)) {
    s->heap[root] = s->heap[last];
    root = last;
  }
  s->heap[root] = item;
}
static void advance(Remi *s, int run) {
  s->position[run]++;
  if (s->position[run] == minimum((run + 1) * s->runLength, s->n)) {
    s->size--;
    sift(s, s->heap[s->size], 0, s->size);
  } else
    sift(s, s->heap[0], 0, s->size);
}
void sort(int *a, int n) {
  if (n < 2)
    return;
  int low = 0, high = minimum(n, 1291);
  while (low < high) {
    int middle = (low + high) / 2;
    if (middle * middle * middle >= n)
      high = middle;
    else
      low = middle + 1;
  }
  Remi s = {0};
  s.a = a;
  s.n = n;
  s.block = low;
  s.runLength = low * low;
  s.runs = (n - 1) / s.runLength + 1;
  int keyLength = s.runs < 2 ? n : s.runLength;
  s.keys = malloc((size_t)keyLength * sizeof(int));
  for (int i = 0; i < keyLength; i++)
    s.keys[i] = i;
  if (s.runs < 2) {
    tableSort(&s, 0, n);
    free(s.keys);
    return;
  }
  s.buffer = malloc((size_t)s.runLength * sizeof(int));
  s.heap = malloc((size_t)s.runs * sizeof(int));
  s.position = malloc((size_t)s.runs * sizeof(int));
  s.destination = malloc((size_t)s.runs * sizeof(int));
  for (int run = 0; run < s.runs; run++) {
    int start = run * s.runLength;
    tableSort(&s, start, minimum(start + s.runLength, n));
    s.heap[run] = run;
    s.position[run] = s.destination[run] = start;
  }
  s.size = s.runs;
  for (int i = (s.runs - 1) / 2; i >= 0; i--)
    sift(&s, s.heap[i], i, s.size);
  for (int i = 0; i < s.runLength; i++) {
    int run = s.heap[0];
    s.buffer[i] = a[s.position[run]];
    advance(&s, run);
  }
  int t = 0, count = 0, cursor = 0;
  while (s.position[cursor] - s.destination[cursor] < s.block)
    cursor++;
  do {
    int run = s.heap[0];
    a[s.destination[cursor]++] = a[s.position[run]];
    advance(&s, run);
    count++;
    if (count == s.block) {
      s.keys[t++] =
          cursor > 0 ? s.destination[cursor] / s.block - s.block - 1 : -1;
      cursor = 0;
      count = 0;
      while (s.position[cursor] - s.destination[cursor] < s.block)
        cursor++;
    }
  } while (s.size > 0);
  int end = n;
  while (count > 0) {
    count--;
    s.destination[cursor]--;
    a[--end] = a[s.destination[cursor]];
  }
  s.position[s.runs - 1] = end;
  s.keys[keyLength - 1] = -1;
  t = 0;
  while (s.keys[t] != -1)
    t++;
  int source = 0;
  for (int run = 1; run < s.runs && source < s.destination[0]; run++) {
    while (s.destination[run] < s.position[run]) {
      s.keys[t++] = s.destination[run] / s.block - s.block;
      while (s.keys[t] != -1)
        t++;
      for (int x = 0; x < s.block; x++)
        a[s.destination[run] + x] = a[source + x];
      s.destination[run] += s.block;
      source += s.block;
    }
  }
  memcpy(a, s.buffer, (size_t)s.runLength * sizeof(int));
  int blocks = (end - s.runLength) / s.block;
  for (int i = 0; i < blocks; i++) {
    if (s.keys[i] == i)
      continue;
    memcpy(s.buffer, a + s.runLength + i * s.block,
           (size_t)s.block * sizeof(int));
    int j = i, next = s.keys[i];
    do {
      memmove(a + s.runLength + j * s.block, a + s.runLength + next * s.block,
              (size_t)s.block * sizeof(int));
      s.keys[j] = j;
      j = next;
      next = s.keys[next];
    } while (next != i);
    memcpy(a + s.runLength + j * s.block, s.buffer,
           (size_t)s.block * sizeof(int));
    s.keys[j] = j;
  }
  free(s.keys);
  free(s.buffer);
  free(s.heap);
  free(s.position);
  free(s.destination);
}
int main(void) {
  int array[] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
  int n = (int)(sizeof(array) / sizeof(array[0]));
  sort(array, n);
  printf("[");
  for (int i = 0; i < n; i++)
    printf("%s%d", i ? ", " : "", array[i]);
  printf("]\n");
  return 0;
}
