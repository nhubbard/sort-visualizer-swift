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
  for (int i = 0; i < size; i++) {
    if (i == 0) {
      printf("[%d, ", items[i]);
    } else if (i != size - 1) {
      printf("%d, ", items[i]);
    } else {
      printf("%d]", items[i]);
    }
  }
}

int mostSignificantBit(int value) {
  if (value == 0) return -1;
  int bit = 0;
  while ((value >> (bit + 1)) != 0) bit++;
  return bit;
}

int partition(int arr[], int p, int r, int bit) {
  int i = p - 1;
  int j = r + 1;
  while (1) {
    do {
      i++;
    } while (i <= r && ((arr[i] >> bit) & 1) == 0);
    do {
      j--;
    } while (j >= p && ((arr[j] >> bit) & 1) == 1);
    if (i < j) {
      swap(&arr[i], &arr[j]);
    } else {
      return j;
    }
  }
}

void binaryQuickSortRecursive(int arr[], int p, int r, int bit) {
  if (p < r && bit >= 0) {
    int q = partition(arr, p, r, bit);
    binaryQuickSortRecursive(arr, p, q, bit - 1);
    binaryQuickSortRecursive(arr, q + 1, r, bit - 1);
  }
}

void sort(int arr[], int n) {
  int maxValue = arr[0];
  for (int i = 1; i < n; i++) {
    if (arr[i] > maxValue) maxValue = arr[i];
  }
  int bit = mostSignificantBit(maxValue);
  binaryQuickSortRecursive(arr, 0, n - 1, bit);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
