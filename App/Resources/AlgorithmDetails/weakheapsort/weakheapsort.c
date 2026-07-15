#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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

void mergeW(int arr[], int flags[], int i, int j) {
  if (arr[i] < arr[j]) {
    flags[j] = !flags[j];
    int t = arr[i];
    arr[i] = arr[j];
    arr[j] = t;
  }
}

void sort(int arr[], int n) {
  int flags[n];
  for (int i = 0; i < n; i++) {
    flags[i] = 0;
  }

  for (int i = n - 1; i > 0; i--) {
    int j = i;
    while ((j & 1) == flags[j >> 1]) {
      j >>= 1;
    }
    int gparent = j >> 1;
    mergeW(arr, flags, gparent, i);
  }

  for (int i = n - 1; i > 1; i--) {
    int t = arr[0];
    arr[0] = arr[i];
    arr[i] = t;
    int x = 1;
    while (1) {
      int y = 2 * x + flags[x];
      if (y >= i) {
        break;
      }
      x = y;
    }
    while (x > 0) {
      mergeW(arr, flags, 0, x);
      x >>= 1;
    }
  }
  int t = arr[0];
  arr[0] = arr[1];
  arr[1] = t;
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
