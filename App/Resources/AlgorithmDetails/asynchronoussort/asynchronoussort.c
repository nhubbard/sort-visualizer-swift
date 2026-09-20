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

void sort(int arr[], int n) {
  if (n == 0) return;
  int ext[n];
  for (int i = 0; i < n; i++) {
    ext[i] = arr[i];
  }

  int minValue = ext[0];
  int maxValue = ext[0];
  for (int i = 1; i < n; i++) {
    if (ext[i] < minValue) {
      minValue = ext[i];
    }
    if (ext[i] > maxValue) {
      maxValue = ext[i];
    }
  }
  maxValue = maxValue + 1;

  int cur = minValue;
  int i = 0;
  while (i < n) {
    for (int j = 0; j < n; j++) {
      if (ext[j] <= cur) {
        arr[i] = ext[j];
        ext[j] = maxValue;
        i += 1;
      }
    }
    cur += 1;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
