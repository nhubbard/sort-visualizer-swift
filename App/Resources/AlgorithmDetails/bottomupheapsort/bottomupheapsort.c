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

void siftDown(int arr[], int i, int b);

void sort(int arr[], int n) {
  if (n < 2) return;
  for (int i = (n - 1) / 2; i >= 0; i--) {
    siftDown(arr, i, n);
  }

  for (int i = n - 1; i > 0; i--) {
    int t = arr[0];
    arr[0] = arr[i];
    arr[i] = t;
    siftDown(arr, 0, i);
  }
}

void siftDown(int arr[], int i, int b) {
  int j = i;
  while (2 * j + 1 < b) {
    if (2 * j + 2 < b) {
      j = (arr[2 * j + 2] > arr[2 * j + 1]) ? 2 * j + 2 : 2 * j + 1;
    } else {
      j = 2 * j + 1;
    }
  }
  while (arr[i] > arr[j]) {
    j = (j - 1) / 2;
  }
  while (j > i) {
    int t = arr[i];
    arr[i] = arr[j];
    arr[j] = t;
    j = (j - 1) / 2;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
