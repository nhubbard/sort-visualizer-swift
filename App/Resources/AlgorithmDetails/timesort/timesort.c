#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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
static void mergeSort(int *scratch, int *buffer, int lo, int hi);

void sort(int *a, int n) {
  if (n < 2)
    return;
  int *scratch = malloc((size_t)n * sizeof(int)),
      *buffer = malloc((size_t)n * sizeof(int));
  memcpy(scratch, a, (size_t)n * sizeof(int));
  memcpy(buffer, scratch, (size_t)n * sizeof(int));
  mergeSort(scratch, buffer, 0, n);
  memcpy(a, scratch, (size_t)n * sizeof(int));
  free(scratch);
  free(buffer);
  for (int i = 1; i < n; i++)
    for (int j = i; j > 0 && a[j - 1] > a[j]; j--) {
      int held = a[j - 1];
      a[j - 1] = a[j];
      a[j] = held;
    }
}

static void mergeSort(int *scratch, int *buffer, int lo, int hi) {
  if (hi - lo < 2)
    return;
  int mid = lo + (hi - lo) / 2;
  mergeSort(scratch, buffer, lo, mid);
  mergeSort(scratch, buffer, mid, hi);
  int left = lo, right = mid, dest = lo;
  while (left < mid && right < hi) {
    if (scratch[left] <= scratch[right])
      buffer[dest++] = scratch[left++];
    else
      buffer[dest++] = scratch[right++];
  }
  while (left < mid)
    buffer[dest++] = scratch[left++];
  while (right < hi)
    buffer[dest++] = scratch[right++];
  memcpy(scratch + lo, buffer + lo, (size_t)(hi - lo) * sizeof(int));
}

int main(void) {
  int n = (int)(sizeof(array) / sizeof(array[0]));
  sort(array, n);
  printList(array, n);
}
