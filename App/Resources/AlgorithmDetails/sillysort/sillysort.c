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

void sillySort(int arr[], int i, int j);

void sort(int arr[], int n) {
  sillySort(arr, 0, n - 1);
}

void sillySort(int arr[], int i, int j) {
  if (i < j) {
    int m = i + (j - i) / 2;
    sillySort(arr, i, m);
    sillySort(arr, m + 1, j);
    if (arr[i] >= arr[m + 1]) {
      swap(&arr[i], &arr[m + 1]);
    }
    sillySort(arr, i + 1, j);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
