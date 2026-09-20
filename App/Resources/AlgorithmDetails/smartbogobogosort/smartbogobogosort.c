#include <stdio.h>
#include <stdlib.h>

int array[7] = {0, 39, 21, 62, 91, 14, 23};

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

void shuffleRange(int arr[], int end);
void sortLen(int arr[], int length);

void sort(int arr[], int n) {
  sortLen(arr, n);
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

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
