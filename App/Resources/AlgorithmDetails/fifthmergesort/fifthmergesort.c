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
      if (s->a[middle] > value) high = middle;
      else low = middle + 1;
    }
    for (int j = i; j > low; --j) s->a[j] = s->a[j - 1];
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
    else value = source(s, right++, offset, from_buffer);
    if (from_buffer) s->a[destination++] = value;
    else s->buffer[destination++] = value;
  }
  while (left < middle) {
    int value = source(s, left++, offset, from_buffer);
    if (from_buffer) s->a[destination++] = value;
    else s->buffer[destination++] = value;
  }
  while (right < end) {
    int value = source(s, right++, offset, from_buffer);
    if (from_buffer) s->a[destination++] = value;
    else s->buffer[destination++] = value;
  }
}

static void ping_pong(Fifth *s, int first, int end) {
  int i = first;
  while (i + 8 < end) {
    binary_insertion(s, i, i + 8);
    i += 8;
  }
  if (end - i > 1) binary_insertion(s, i, end);

  int length = end - first, from_buffer = 0;
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
        if (from_buffer) s->a[j] = s->buffer[j - first];
        else s->buffer[j - first] = s->a[j];
      }
    }
    from_buffer = !from_buffer;
  }
  if (from_buffer) {
    for (int j = 0; j < length; ++j) s->a[first + j] = s->buffer[j];
  }
}

static void merge_forward(Fifth *s, int destination, int first, int middle, int end) {
  int left = first, right = middle;
  while (left < middle && right < end) {
    if (s->a[left] <= s->a[right]) s->a[destination++] = s->a[left++];
    else s->a[destination++] = s->a[right++];
  }
  while (left < middle) s->a[destination++] = s->a[left++];
  while (right < end) s->a[destination++] = s->a[right++];
}

typedef struct { int left, right; } Remaining;
static Remaining merge_backward(Fifth *s, int destination, int middle, int end) {
  int left = middle - 1, right = end - 1;
  while (destination > right && right >= middle && left >= 0) {
    if (s->a[left] > s->a[right]) s->a[destination--] = s->a[left--];
    else s->a[destination--] = s->a[right--];
  }
  if (left < 0) {
    while (right >= middle) s->a[destination--] = s->a[right--];
  } else if (right == left) {
    while (right >= 0) s->a[destination--] = s->a[right--];
  } else if (right < middle) {
    while (left >= 0) s->a[destination--] = s->a[left--];
  }
  Remaining result = {left + 1, right + 1};
  return result;
}

static void merge_main_prefix(Fifth *s, int destination, int left_end,
                              int middle, int end) {
  int left = 0, right = middle;
  while (left < left_end && right < end) {
    if (s->a[left] <= s->a[right]) s->a[destination++] = s->a[left++];
    else s->a[destination++] = s->a[right++];
  }
  while (left < left_end) s->a[destination++] = s->a[left++];
}

static void merge_external(Fifth *s, int destination, int middle, int end) {
  int left = 0, right = middle;
  while (left < s->buffer_length && right < end) {
    if (s->buffer[left] <= s->a[right])
      s->a[destination++] = s->buffer[left++];
    else s->a[destination++] = s->a[right++];
  }
  while (left < s->buffer_length) s->a[destination++] = s->buffer[left++];
}

void sort(int a[], int n) {
  if (n <= 1) return;
  int fifth = n / 5, buffer_length = n - 4 * fifth;
  int *buffer = malloc((size_t)buffer_length * sizeof *buffer);
  if (!buffer) return;
  Fifth s = {a, buffer, buffer_length};
  ping_pong(&s, 0, buffer_length);
  int first = buffer_length;
  for (int i = 0; i < 4; ++i) {
    ping_pong(&s, first, first + fifth);
    first += fifth;
  }
  for (int i = 0; i < buffer_length; ++i) buffer[i] = a[i];

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

int main(void) {
  int a[] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};
  int n = (int)(sizeof a / sizeof a[0]);
  sort(a, n);
  printf("[");
  for (int i = 0; i < n; ++i) printf("%s%d", i ? ", " : "", a[i]);
  puts("]");
  return 0;
}
