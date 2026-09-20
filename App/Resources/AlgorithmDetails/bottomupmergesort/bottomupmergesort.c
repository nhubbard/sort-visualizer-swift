#include <stdio.h>
#include <stdlib.h>

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

int min(int a, int b);
int merge(int arr[], int scratch[], int n, int index, int mergeSize);

void sort(int arr[], int n) {
  if (n < 2) return;
  int *scratch = malloc((size_t)n * sizeof(int));
  for (int j = 0; j < n; j++) scratch[j] = arr[j];
  int mergeSize = 2;
  while (mergeSize <= n) {
    int copyLength = n;
    for (int index = 0; index < n; index += mergeSize) {
      int stop = merge(arr, scratch, n, index, mergeSize);
      if (stop >= 0) copyLength = stop;
    }
    for (int j = 0; j < copyLength; j++) arr[j] = scratch[j];
    mergeSize *= 2;
  }
  if (mergeSize / 2 != n) {
    int stop = merge(arr, scratch, n, 0, mergeSize);
    int copyLength = stop < 0 ? n : stop;
    for (int j = 0; j < copyLength; j++) arr[j] = scratch[j];
  }
  free(scratch);
}

int min(int a, int b) {
  return a < b ? a : b;
}

int merge(int arr[], int scratch[], int n, int index, int mergeSize) {
  int mid = index + mergeSize / 2;
  int end = index + mergeSize < n ? index + mergeSize : n;
  if (mid >= end) return index;
  int left = index, right = mid, out = index;
  while (left < mid && right < end)
    scratch[out++] = arr[left] <= arr[right] ? arr[left++] : arr[right++];
  while (left < mid) scratch[out++] = arr[left++];
  while (right < end) scratch[out++] = arr[right++];
  return -1;
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
