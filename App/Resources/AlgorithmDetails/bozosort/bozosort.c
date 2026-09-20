#include <stdio.h>
#include <stdlib.h>

int array[6] = {0, 39, 21, 62, 91, 77};

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

int isSorted(int arr[], int n);

void sort(int arr[], int n) {
  while (!isSorted(arr, n)) {
    int i = rand() % n;
    int j = rand() % n;
    swap(&arr[i], &arr[j]);
  }
}

int isSorted(int arr[], int n) {
  for (int i = 1; i < n; i++) {
    if (arr[i - 1] > arr[i]) {
      return 0;
    }
  }
  return 1;
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
