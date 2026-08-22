#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

int end;

void printList(int arr[], int n) {
  for (int i = 0; i < n; i++) {
    if (i == 0) {
      printf("[%d, ", arr[i]);
    } else if (i != n - 1) {
      printf("%d, ", arr[i]);
    } else {
      printf("%d]", arr[i]);
    }
  }
}

void compSwap(int arr[], int a, int b) {
  if (b >= end)
    return;
  if (arr[a] > arr[b]) {
    int temp = arr[a];
    arr[a] = arr[b];
    arr[b] = temp;
  }
}

void rangeComp(int arr[], int a, int b, int offset) {
  int half = (b - a) / 2;
  int m = a + half;
  int base = a + offset;
  for (int i = 0; i < half - offset; i++) {
    if ((i & ~offset) == i) {
      compSwap(arr, base + i, m + i);
    }
  }
}

void sort(int arr[], int n) {
  end = n;
  if (n <= 1)
    return;
  int paddedLength = 1;
  while (paddedLength < n)
    paddedLength <<= 1;

  for (int k = 2; k <= paddedLength; k *= 2) {
    for (int j = 0; j < k / 2; j++) {
      for (int i = 0; i + j < n; i += k) {
        rangeComp(arr, i, i + k, j);
      }
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
