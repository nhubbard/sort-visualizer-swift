#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

void printList(int items[], int size) {
  printf("[");
  if (size > 0) {
    printf("%d", items[0]);
    for (int i = 1; i < size; i++) {
      printf(", %d", items[i]);
    }
  }
  printf("]");
}

int minRun(int n) {
  while (n >= 32)
    n = (n + 1) / 2;
  return n;
}

void insertion(int arr[], int start, int end) {
  for (int i = start + 1; i < end; i++) {
    int value = arr[i], low = start, high = i;
    while (low < high) {
      int middle = low + (high - low) / 2;
      if (arr[middle] > value)
        high = middle;
      else
        low = middle + 1;
    }
    for (int j = i; j > low; j--)
      arr[j] = arr[j - 1];
    arr[low] = value;
  }
}

void mergeBackward(int arr[], int start, int middle, int end, int workspace) {
  int count = end - middle;
  for (int offset = 0; offset < count; offset++)
    arr[workspace + offset] = arr[middle + offset];
  int left = middle - 1, right = workspace + count - 1, output = end - 1;
  while (left >= start && right >= workspace) {
    if (arr[left] > arr[right])
      arr[output--] = arr[left--];
    else
      arr[output--] = arr[right--];
  }
  while (right >= workspace)
    arr[output--] = arr[right--];
}

void sortSegment(int arr[], int start, int end, int workspace, int run) {
  for (int lower = start; lower < end; lower += run) {
    int upper = lower + run < end ? lower + run : end;
    insertion(arr, lower, upper);
  }
  for (int width = run; width < end - start; width *= 2) {
    for (int lower = start; lower < end; lower += 2 * width) {
      int middle = lower + width < end ? lower + width : end;
      int upper = lower + 2 * width < end ? lower + 2 * width : end;
      if (middle < upper)
        mergeBackward(arr, lower, middle, upper, workspace);
    }
  }
}

void sort(int arr[], int n) {
  if (n < 2)
    return;
  int run = minRun(n);
  if (n <= 32) {
    insertion(arr, 0, n);
    return;
  }
  int half = n / 2;
  int *buffer = malloc((size_t)half * sizeof(int));
  if (buffer == NULL)
    return;
  for (int i = 0; i < half; i++)
    buffer[i] = arr[half + i];
  sortSegment(arr, 0, half, half, run);
  for (int i = 0; i < half; i++)
    arr[half + i] = buffer[i];
  for (int i = 0; i < half; i++)
    buffer[i] = arr[i];
  sortSegment(arr, half, n, 0, run);
  int left = 0, right = half, output = 0;
  while (left < half && right < n) {
    if (buffer[left] <= arr[right])
      arr[output++] = buffer[left++];
    else
      arr[output++] = arr[right++];
  }
  while (left < half)
    arr[output++] = buffer[left++];
  free(buffer);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
