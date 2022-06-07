#include <stdio.h>
#include <stdlib.h>

int items[10] = {35, 95, 74, 71, 72, 30, 96, 53, 9, 0};

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

void bubbleSort(int arr[], int n) {
  for (int c = 0; c < n - 1; c++) {
    for (int d = 0; d < n - c - 1; d++) {
      if (arr[d] > arr[d + 1]) {
        swap(&arr[d], &arr[d + 1]);
      }
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(items) / sizeof(items[0]);
  bubbleSort(items, size);
  printList(items, size);
  return 0;
}
