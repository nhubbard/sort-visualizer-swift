#include <stdio.h>
#include <stdlib.h>

#define BASE 4

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

void siftDown(int arr[], int node, int stop) {
  int left = node * BASE + 1;
  if (left >= stop) {
    return;
  }
  int maxIndex = left;
  for (int i = left + 1; i < left + BASE && i < stop; i++) {
    if (arr[maxIndex] < arr[i]) {
      maxIndex = i;
    }
  }
  if (arr[node] < arr[maxIndex]) {
    swap(&arr[node], &arr[maxIndex]);
    siftDown(arr, maxIndex, stop);
  }
}

void sort(int arr[], int n) {
  for (int i = n - 1; i >= 0; i--) {
    siftDown(arr, i, n);
  }
  for (int end = n - 1; end > 0; end--) {
    swap(&arr[0], &arr[end]);
    siftDown(arr, 0, end);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
