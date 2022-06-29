#include <stdio.h>
#include <stdlib.h>

int array[8] = {0, 39, 21, 62, 91, 77, 14, 23};

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

int isSorted(int arr[], int n) {
  while (--n >= 1) {
    if (arr[n] < arr[n - 1]) {
      return 0;
    }
  }
  return 1;
}

void sort(int arr[], int n) {
  while (!isSorted(arr, n)) {
    for (int i = 0; i < n; i++) {
      int r = rand() % n;
      swap(&arr[i], &arr[r]);
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
