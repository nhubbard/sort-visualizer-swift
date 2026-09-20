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

int minFrom(int arr[], int i, int n);

void sort(int arr[], int n) {
  for (int i = 0; i < n; i++) {
    while (arr[i] != minFrom(arr, i, n)) {
      int j = i + rand() % (n - i);
      int t = arr[i];
      arr[i] = arr[j];
      arr[j] = t;
    }
  }
}

int minFrom(int arr[], int i, int n) {
  int m = arr[i];
  for (int k = i + 1; k < n; k++) {
    if (arr[k] < m) {
      m = arr[k];
    }
  }
  return m;
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
