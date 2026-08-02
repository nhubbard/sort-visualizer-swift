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

int isSorted(int arr[], int n) {
  for (int i = 1; i < n; i++) {
    if (arr[i] < arr[i - 1]) {
      return 0;
    }
  }
  return 1;
}

int permutationSort(int arr[], int n, int depth) {
  if (depth >= n - 1) {
    return isSorted(arr, n);
  }
  for (int i = n - 1; i > depth; i--) {
    if (permutationSort(arr, n, depth + 1)) {
      return 1;
    }
    if ((n - depth) % 2 == 0) {
      int t = arr[depth];
      arr[depth] = arr[i];
      arr[i] = t;
    } else {
      int t = arr[depth];
      arr[depth] = arr[n - 1];
      arr[n - 1] = t;
    }
  }
  return permutationSort(arr, n, depth + 1);
}

void sort(int arr[], int n) { permutationSort(arr, n, 0); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
