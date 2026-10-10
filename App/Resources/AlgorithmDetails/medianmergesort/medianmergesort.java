import java.util.Arrays;

class medianmergesort {
/* ArrayV's median-merge hybrid. The larger partition is an in-array swap
   buffer while the smaller partition is merge-sorted. No heap buffer is used. */
static void exchange(int[] a, int i, int j) {
  int value = a[i];
  a[i] = a[j];
  a[j] = value;
}

static void insertion(int[] a, int first, int end) {
  for (int i = first + 1; i < end; ++i)
    for (int j = i; j > first && a[j - 1] > a[j]; --j)
      exchange(a, j - 1, j);
}

static void binary_insertion(int[] a, int first, int end) {
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

static void median_three(int[] a, int first, int end) {
  int middle = first + (end - 1 - first) / 2;
  if (a[first] > a[middle]) exchange(a, first, middle);
  if (a[middle] > a[end - 1]) {
    exchange(a, middle, end - 1);
    if (a[first] > a[middle]) return;
  }
  exchange(a, first, middle);
}

static void median_medians(int[] a, int first, int end) {
  boolean alternate = true;
  while (end - first > 1) {
    int write = first, i = first;
    while (i + 10 <= end) {
      insertion(a, i, i + 5);
      exchange(a, write++, i + 2);
      i += 5;
    }
    if (i < end) {
      insertion(a, i, end);
      exchange(a, write++, i + (end - (alternate ? 1 : 0) - i) / 2);
      if ((end - i) % 2 == 0) alternate = !alternate;
    }
    end = write;
  }
}

static int partition(int[] a, int first, int end, int pivot) {
  int i = first - 1, j = end;
  for (;;) {
    do { ++i; } while (i < j && a[i] < a[pivot]);
    do { --j; } while (j >= i && a[j] > a[pivot]);
    if (i >= j) return j;
    exchange(a, i, j);
  }
}

/* The destination contains displaced values, restored on the return pass. */
static void merge(int[] a, int first, int middle, int end, int destination) {
  int i = first, j = middle;
  while (i < middle && j < end) {
    if (a[i] <= a[j]) exchange(a, destination++, i++);
    else exchange(a, destination++, j++);
  }
  while (i < middle) exchange(a, destination++, i++);
  while (j < end) exchange(a, destination++, j++);
}

static void merge_sort(int[] a, int first, int end, int buffer) {
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

static void sort(int[] a, int n) {
  int first = 0, end = n;
  boolean bad_split = false, used_medians = false;
  while (end - first > 16) {
    if (bad_split) {
      median_medians(a, first, end);
      used_medians = true;
    } else median_three(a, first, end);
    int pivot = partition(a, first + 1, end, first);
    exchange(a, first, pivot);
    int left = pivot - first, right = end - pivot - 1;
    bad_split = !used_medians &&
      (left == 0 || right == 0 ||
       (left > 0 && right > 0 && (left / right >= 16 || right / left >= 16)));
    if (left <= right) {
      merge_sort(a, first, pivot, pivot + 1);
      first = pivot + 1;
    } else {
      merge_sort(a, pivot + 1, end, 2 * pivot + 1 - end);
      end = pivot;
    }
  }
  binary_insertion(a, first, end);
}

  public static void main(String[] args) {
    int[] a = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81,
               68, 83, 32, 56, 10, 2, 95, 46, 21, 74, 6, 38};
    sort(a, a.length);
    System.out.println(Arrays.toString(a));
  }
}
