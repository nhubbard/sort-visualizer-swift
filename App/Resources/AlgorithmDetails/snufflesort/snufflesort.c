#include <stdio.h>
#include <stdlib.h>

int array[8] = {0, 39, 21, 62, 91, 77, 14, 23};

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

void snuffleSort(int arr[], int start, int stop);

void sort(int arr[], int n) {
  snuffleSort(arr, 0, n - 1);
}

void snuffleSort(int arr[], int start, int stop) {
  if (stop - start + 1 >= 2) {
    if (arr[start] > arr[stop])
      swap(&arr[start], &arr[stop]);
    if (stop - start + 1 >= 3) {
      int mid = (stop - start) / 2 + start;
      int iterations = (stop - start + 1) / 2;
      for (int i = 0; i < iterations; i++) {
        snuffleSort(arr, start, mid);
        snuffleSort(arr, mid, stop);
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
