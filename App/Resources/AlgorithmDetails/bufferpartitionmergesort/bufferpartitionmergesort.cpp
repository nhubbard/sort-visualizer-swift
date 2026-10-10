#include <math.h>
#include <stdio.h>

/* ArrayV's buffer-partition merge: select a prefix, sort it through an
   in-array swap buffer, then merge it into the growing sorted suffix. */
static void exchange(int a[], int i, int j) {
  int value = a[i];
  a[i] = a[j];
  a[j] = value;
}

static void insertion(int a[], int first, int end) {
  for (int i = first + 1; i < end; ++i)
    for (int j = i; j > first && a[j - 1] > a[j]; --j)
      exchange(a, j - 1, j);
}

static void binary_insertion(int a[], int first, int end) {
  for (int i = first + 1; i < end; ++i) {
    int value = a[i], low = first, high = i;
    while (low < high) {
      int middle = low + (high - low) / 2;
      if (value < a[middle]) high = middle;
      else low = middle + 1;
    }
    for (int j = i; j > low; --j) a[j] = a[j - 1];
    a[low] = value;
  }
}

static void median_three(int a[], int first, int end) {
  int middle = first + (end - 1 - first) / 2;
  if (a[first] > a[middle]) exchange(a, first, middle);
  if (a[middle] > a[end - 1]) {
    exchange(a, middle, end - 1);
    if (a[first] > a[middle]) return;
  }
  exchange(a, first, middle);
}

static void median_medians(int a[], int first, int end) {
  int alternate = 1;
  while (end - first > 1) {
    int write = first, i = first;
    while (i + 10 <= end) {
      insertion(a, i, i + 5);
      exchange(a, write++, i + 2);
      i += 5;
    }
    if (i < end) {
      insertion(a, i, end);
      exchange(a, write++, i + (end - alternate - i) / 2);
      if ((end - i) % 2 == 0) alternate = !alternate;
    }
    end = write;
  }
}

static void shift_backward(int a[], int first, int middle, int end) {
  while (middle > first) exchange(a, --end, --middle);
}

static void multi_swap(int a[], int first, int second, int length) {
  for (int i = 0; i < length; ++i) exchange(a, first + i, second + i);
}

static void rotate(int a[], int first, int middle, int end) {
  int left = middle - first, right = end - middle;
  while (left > 0 && right > 0) {
    if (right < left) {
      multi_swap(a, middle - right, middle, right);
      end -= right; middle -= right; left -= right;
    } else {
      multi_swap(a, first, middle, left);
      first += left; middle += left; right -= left;
    }
  }
}

static void in_place_merge(int a[], int first, int middle, int end) {
  int left = first, right = middle;
  while (left < right && right < end) {
    if (a[left] > a[right]) {
      int upper = right + 1;
      while (upper < end && a[left] > a[upper]) ++upper;
      rotate(a, left, right, upper);
      left += upper - right;
      right = upper;
    } else ++left;
  }
}

static int partition(int a[], int first, int end) {
  int left = first, right = end;
  for (;;) {
    do { ++left; } while (left < right && a[left] > a[first]);
    do { --right; } while (right >= left && a[right] < a[first]);
    if (left >= right) return right;
    exchange(a, left, right);
  }
}

static int quick_select(int a[], int lower, int upper, int target) {
  int bad_split = 0, used_medians = 0;
  int target_upper = (target + upper + 1) / 2;
  for (;;) {
    if (bad_split) { median_medians(a, lower, upper); used_medians = 1; }
    else median_three(a, lower, upper);
    int pivot = partition(a, lower, upper);
    exchange(a, lower, pivot);
    int left = pivot - lower, right = upper - pivot - 1;
    if (left < 1) left = 1;
    if (right < 1) right = 1;
    bad_split = !used_medians && (left / right >= 16 || right / left >= 16);
    if (pivot >= target && pivot < target_upper) return pivot;
    if (pivot < target) lower = pivot + 1;
    else upper = pivot;
  }
}

/* The destination contains displaced values, restored on the return pass. */
static void merge(int a[], int first, int middle, int end, int destination) {
  int i = first, j = middle;
  while (i < middle && j < end) {
    if (a[i] <= a[j]) exchange(a, destination++, i++);
    else exchange(a, destination++, j++);
  }
  while (i < middle) exchange(a, destination++, i++);
  while (j < end) exchange(a, destination++, j++);
}

static void merge_sort(int a[], int first, int end, int buffer) {
  int length = end - first;
  if (length <= 1) return;
  int width = length;
  while (width >= 32) width = (width + 3) / 4;
  int i = first;
  while (i + width <= end) {
    binary_insertion(a, i, i + width);
    i += width;
  }
  binary_insertion(a, i, end);
  while (width < length) {
    int destination = buffer;
    i = first;
    while (i + 2 * width <= end) {
      merge(a, i, i + width, i + 2 * width, destination);
      i += 2 * width;
      destination += 2 * width;
    }
    if (i + width < end) merge(a, i, i + width, end, destination);
    else while (i < end) exchange(a, i++, destination++);
    width *= 2;

    destination = first;
    i = buffer;
    while (i + 2 * width <= buffer + length) {
      merge(a, i, i + width, i + 2 * width, destination);
      i += 2 * width;
      destination += 2 * width;
    }
    if (i + width < buffer + length)
      merge(a, i, i + width, buffer + length, destination);
    else while (i < buffer + length) exchange(a, i++, destination++);
    width *= 2;
  }
}

static int merge_forward(int a[], int destination, int first, int middle, int end) {
  int left = first, right = middle;
  while (left < middle && right < end) {
    if (a[left] <= a[right]) exchange(a, destination++, left++);
    else exchange(a, destination++, right++);
  }
  return left < middle ? left : right;
}

void sort(int a[], int n) {
  if (n <= 1) return;
  int first = 0, middle = (n + 1) / 2;
  int minimum = (int)sqrt((double)n);
  merge_sort(a, middle, n, first);
  while (middle - first > minimum) {
    int selected = (first + middle + 1) / 2;
    selected = quick_select(a, first, middle, selected);
    merge_sort(a, selected, middle, first);
    int buffer_length = selected - first;
    int merge_end = selected + buffer_length < n ? selected + buffer_length : n;
    selected = merge_forward(a, first, selected, middle, merge_end);
    while (selected < middle) {
      shift_backward(a, selected, middle, merge_end);
      selected = merge_end - (middle - selected);
      first = selected - buffer_length;
      middle = merge_end;
      if (middle == n) break;
      merge_end = merge_end + buffer_length < n ? merge_end + buffer_length : n;
      selected = merge_forward(a, first, selected, middle, merge_end);
    }
    middle = selected;
    first = selected - buffer_length;
  }
  binary_insertion(a, first, middle);
  in_place_merge(a, first, middle, n);
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
