#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

static int minInt(int a, int b) { return a < b ? a : b; }

static void compSwap(int arr[], int a, int b) {
  if (arr[a] > arr[b]) {
    swap(&arr[a], &arr[b]);
  }
}

void sort(int arr[], int n) {
  int p = 1;
  while (p < n) {
    p *= 2;
  }

  int m = 4;
  while (m <= p) {
    for (int k = 0; k < m / 2; k++) {
      int cnt = (k <= m / 4) ? k : m / 2 - k;
      int j = 0;
      while (j < n) {
        if (j + cnt + 1 < n) {
          int i = j + cnt;
          while (i + 1 < minInt(n, j + m - cnt)) {
            compSwap(arr, i, i + 1);
            i += 2;
          }
        }
        j += m;
      }
    }
    m *= 2;
  }
  m /= 2;
  for (int k = 0; k <= m / 2; k++) {
    int i = k;
    while (i + 1 < minInt(n, m - k)) {
      compSwap(arr, i, i + 1);
      i += 2;
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}