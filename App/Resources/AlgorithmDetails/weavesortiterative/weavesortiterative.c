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

void sort(int arr[], int n) {
  int end = n;
  int padded = 1;
  while (padded < end) {
    padded *= 2;
  }

  int i = 1;
  while (i < padded) {
    int j = 1;
    while (j <= i) {
      int k = 0;
      while (k < padded) {
        int d = padded / i / 2;
        int m = 0;
        int l = padded / j - d;
        while (l >= padded / j / 2) {
          int p = 0;
          while (p < d) {
            int a = k + m;
            int b = k + l + p;
            if (b < end && arr[a] > arr[b]) {
              swap(&arr[a], &arr[b]);
            }
            p++;
            m++;
          }
          l -= d;
        }
        k += padded / j;
      }
      j *= 2;
    }
    i *= 2;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}