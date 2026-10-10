#include <stdio.h>
#include <stdlib.h>

/* MIT License
 * Copyright (c) 2021 The Holy Grail Sort Project, implemented by aphitorite
 * Copyright (c) 2020-2021 aphitorite
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software
 * and associated documentation files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in all copies or
 * substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
 * BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

typedef struct {
  int *a, *prefix, *tags;
  int n, tag_count;
} SynchronousSqrt;

static void exchange(SynchronousSqrt *s, int i, int j) {
  int value = s->a[i];
  s->a[i] = s->a[j];
  s->a[j] = value;
}

static void binary_insertion(SynchronousSqrt *s, int first, int end) {
  for (int i = first + 1; i < end; ++i) {
    int value = s->a[i], low = first, high = i;
    while (low < high) {
      int middle = low + (high - low) / 2;
      if (s->a[middle] <= value) low = middle + 1;
      else high = middle;
    }
    for (int j = i; j > low; --j) s->a[j] = s->a[j - 1];
    if (low != i) s->a[low] = value;
  }
}

static void shift_forward(SynchronousSqrt *s, int destination, int source, int end) {
  while (source < end) s->a[destination++] = s->a[source++];
}

static void shift_backward(SynchronousSqrt *s, int first, int source_end, int destination_end) {
  while (source_end > first) s->a[--destination_end] = s->a[--source_end];
}

static void multi_swap(SynchronousSqrt *s, int first, int second, int length) {
  for (int i = 0; i < length; ++i) exchange(s, first + i, second + i);
}

static void merge_forward(SynchronousSqrt *s, int first, int middle, int end, int output) {
  int left = first, right = middle;
  while (left < middle && right < end) {
    if (s->a[left] <= s->a[right]) s->a[output++] = s->a[left++];
    else s->a[output++] = s->a[right++];
  }
  if (left > output) shift_forward(s, output, left, middle);
  shift_forward(s, output, right, end);
}

static void merge_backward(SynchronousSqrt *s, int first, int middle, int end, int output) {
  int left = middle - 1, right = end - 1;
  while (right >= middle && left >= first) {
    --output;
    if (s->a[right] >= s->a[left]) s->a[output] = s->a[right--];
    else s->a[output] = s->a[left--];
  }
  if (output > right) shift_backward(s, middle, right + 1, output);
  shift_backward(s, first, left + 1, output);
}

static int smart_merge_backward(SynchronousSqrt *s, int first, int middle,
                                int end, int output, int reversed) {
  int left = middle - 1, right = end - 1;
  while (left >= first && right >= middle) {
    int take_left = reversed ? s->a[left] >= s->a[right] : s->a[left] > s->a[right];
    --output;
    if (take_left) s->a[output] = s->a[left--];
    else s->a[output] = s->a[right--];
  }
  return left + 1;
}

static void block_selection(SynchronousSqrt *s, int first, int end, int block,
                            int tag_start, int tag_count) {
  int available = tag_count + 1;
  if (available > s->tag_count - tag_start) available = s->tag_count - tag_start;
  for (int i = 0; i < available; ++i)
    s->tags[tag_start + i] = i + (i <= tag_count / 2 ? 0 : s->tag_count);
  int vacant = first;
  int current = first;
  while (current < end - block) {
    int minimum = vacant == current ? current + block : current;
    for (int candidate = minimum + block; candidate < end; candidate += block) {
      if (candidate != vacant &&
          (s->a[candidate] < s->a[minimum] ||
           (s->a[candidate] == s->a[minimum] &&
            s->tags[tag_start + (candidate - first) / block] <
            s->tags[tag_start + (minimum - first) / block])))
        minimum = candidate;
    }
    if (minimum > current) {
      if (vacant == current) {
        for (int i = 0; i < block; ++i) s->a[current + i] = s->a[minimum + i];
        s->tags[tag_start + (current - first) / block] =
          s->tags[tag_start + (minimum - first) / block];
        vacant = minimum;
      } else {
        multi_swap(s, current, minimum, block);
        int current_tag = tag_start + (current - first) / block;
        int minimum_tag = tag_start + (minimum - first) / block;
        int value = s->tags[current_tag];
        s->tags[current_tag] = s->tags[minimum_tag];
        s->tags[minimum_tag] = value;
      }
    }
    current += block;
  }
}

static void merge_blocks_backward(SynchronousSqrt *s, int first, int end,
                                  int first_tag, int past_last_tag, int block) {
  int tag = past_last_tag - 1;
  int frontier = end, block_start = frontier - block;
  int reversed = s->tags[tag] < s->tag_count;
  for (;;) {
    do { --tag; block_start -= block; }
    while (tag >= first_tag && ((s->tags[tag] < s->tag_count) == reversed));
    if (tag < first_tag) {
      shift_backward(s, first, frontier, frontier + block);
      break;
    }
    frontier = smart_merge_backward(s, block_start, block_start + block,
                                    frontier, frontier + block, reversed);
    reversed = !reversed;
  }
}

void sort(int a[], int n) {
  if (n <= 1) return;
  SynchronousSqrt s = {a, NULL, NULL, n, 0};
  if (n <= 16) { binary_insertion(&s, 0, n); return; }
  int block = 1;
  while (block * block < n) block *= 2;
  int remainder = n % block;
  int first = block + remainder, end = n;
  int work_length = end - first, run = 1;
  s.tag_count = (n - 1) / block + 1;
  s.prefix = malloc((size_t)first * sizeof *s.prefix);
  s.tags = malloc((size_t)s.tag_count * sizeof *s.tags);
  if (!s.prefix || !s.tags) { free(s.prefix); free(s.tags); return; }
  binary_insertion(&s, 0, first);
  for (int i = 0; i < first; ++i) s.prefix[i] = a[i];

  while (run < block) {
    int distance = run < 2 ? 2 : run;
    int index = first;
    while (index + 2 * run < end) {
      merge_forward(&s, index, index + run, index + 2 * run, index - distance);
      index += 2 * run;
    }
    if (index + run < end) merge_forward(&s, index, index + run, end, index - distance);
    else shift_forward(&s, index - distance, index, end);
    first -= distance;
    end -= distance;
    run *= 2;
  }

  int fragment = work_length % (2 * run);
  int index = end - fragment;
  if (index + run < end) merge_backward(&s, index, index + run, end, end + run);
  else shift_backward(&s, index, end, end + run);
  index -= 2 * run;
  while (index >= first) {
    merge_backward(&s, index, index + run, index + 2 * run, index + 3 * run);
    index -= 2 * run;
  }
  first += run; end += run; run *= 2;

  int tag_count = 4;
  while (run < work_length) {
    index = first;
    int tag_index = 0;
    while (index + 2 * run < end) {
      block_selection(&s, index - block, index + 2 * run, block, tag_index, tag_count);
      index += 2 * run;
      tag_index += tag_count;
    }
    int has_fragment = index + run < end;
    fragment = (end - index) / block;
    if (has_fragment)
      block_selection(&s, index - block, end, block, tag_index, tag_count);
    first -= block; end -= block; index -= block;
    if (has_fragment)
      merge_blocks_backward(&s, index, end, tag_index, tag_index + fragment, block);
    index -= 2 * run;
    tag_index -= tag_count;
    while (index >= first) {
      merge_blocks_backward(&s, index, index + 2 * run, tag_index,
                            tag_index + tag_count, block);
      index -= 2 * run;
      tag_index -= tag_count;
    }
    first += block; end += block; run *= 2; tag_count *= 2;
  }

  int left = 0, right = first, output = 0;
  while (left < first && right < end) {
    if (s.prefix[left] <= a[right]) a[output++] = s.prefix[left++];
    else a[output++] = a[right++];
  }
  while (left < first) a[output++] = s.prefix[left++];
  free(s.tags);
  free(s.prefix);
}

int main(void) {
  int a[] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
  int n = (int)(sizeof a / sizeof a[0]);
  sort(a, n);
  printf("[");
  for (int i = 0; i < n; ++i) printf("%s%d", i ? ", " : "", a[i]);
  puts("]");
  return 0;
}
