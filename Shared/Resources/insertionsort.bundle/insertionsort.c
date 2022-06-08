#include <stdio.h>
#include <stdlib.h>

int items[10] = {35, 95, 74, 71, 72, 30, 96, 53, 9, 0};

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

void insertionSort(int arr[], int n) {
  for (int i = 1; i < n; i++) {
    int key = arr[i];
    int j = i - 1;
    while (j >= 0 && arr[j] > key) {
      arr[j + 1] = arr[j];
      j = j - 1;
    }
    arr[j + 1] = key;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(items) / sizeof(items[0]);
  insertionSort(items, size);
  printList(items, size);
  return 0;
}