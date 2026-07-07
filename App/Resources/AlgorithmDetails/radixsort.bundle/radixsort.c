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

int getMax(int arr[], int n) {
  int max = arr[0];
  for (int i = 1; i < n; i++) {
    if (arr[i] > max) {
      max = arr[i];
    }
  }
  return max;
}

void sort(int arr[], int n) {
  int bucket[10][10];
  int bucketCount[10];
  int i, j, k, r, nop = 0, divisor = 1, lar, pass;
  lar = getMax(arr, n);
  while (lar > 0) {
    nop++;
    lar /= 10;
  }
  for (pass = 0; pass < nop; pass++) {
    for (i = 0; i < 10; i++) {
      bucketCount[i] = 0;
    }
    for (i = 0; i < n; i++) {
      r = (arr[i] / divisor) % 10;
      bucket[r][bucketCount[r]] = arr[i];
      bucketCount[r] += 1;
    }
    i = 0;
    for (k = 0; k < 10; k++) {
      for (j = 0; j < bucketCount[k]; j++) {
        arr[i] = bucket[k][j];
        i++;
      }
    }
    divisor *= 10;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}