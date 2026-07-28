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

int compSwap(int arr[], int a, int b) {
  if (arr[a] > arr[b]) {
    swap(&arr[a], &arr[b]);
    return 1;
  }
  return 0;
}

int max(int a, int b) {
  return a > b ? a : b;
}

int stoogeSort(int arr[], int a, int m, int b, int merge) {
  if (a >= m) return 0;
  if (b - a == 2) return compSwap(arr, a, m);

  int lChange = 0;
  int rChange = 0;

  int a2 = (a + a + b) / 3;
  int b2 = (a + b + b + 2) / 3;

  if (m < b2) {
    lChange = stoogeSort(arr, a, m, b2, merge);
    if (merge) {
      rChange = stoogeSort(arr, max(a + b2 - m, a2), b2, b, 1);
      if (rChange) {
        stoogeSort(arr, a + b2 - m, a2, 2 * a2 - a, 1);
      }
    } else {
      rChange = stoogeSort(arr, a2, b2, b, 0);
      if (rChange) {
        stoogeSort(arr, a, a2, 2 * a2 - a, 1);
      }
    }
  } else {
    rChange = stoogeSort(arr, a2, m, b, merge);
    if (rChange) {
      stoogeSort(arr, a, a2, a2 + b - m, 1);
    }
  }

  return lChange || rChange;
}

void sort(int arr[], int n) {
  stoogeSort(arr, 0, 1, n, 0);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
