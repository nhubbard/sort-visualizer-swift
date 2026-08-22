#include <stdio.h>
#include <stdlib.h>

int array[7] = {0, 39, 21, 62, 91, 14, 23};

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

void shuffleRange(int arr[], int end) {
  for (int i = end - 1; i > 0; i--) {
    int j = rand() % (i + 1);
    int t = arr[i];
    arr[i] = arr[j];
    arr[j] = t;
  }
}

void sortLen(int arr[], int length) {
  if (length == 1) {
    return;
  }
  sortLen(arr, length - 1);
  while (arr[length - 2] > arr[length - 1]) {
    shuffleRange(arr, length);
    sortLen(arr, length - 1);
  }
}

void sort(int arr[], int n) { sortLen(arr, n); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
