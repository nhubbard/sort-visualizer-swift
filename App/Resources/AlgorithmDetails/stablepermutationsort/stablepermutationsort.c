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

int isSorted(int arr[], int n);
int permute(int arr[], int idx[], int n, int length);

void sort(int arr[], int n) {
  int idx[n];
  for (int i = 0; i < n; i++) {
    idx[i] = i;
  }
  permute(arr, idx, n, n);
}

int isSorted(int arr[], int n) {
  for (int i = 1; i < n; i++) {
    if (arr[i] < arr[i - 1]) {
      return 0;
    }
  }
  return 1;
}

int permute(int arr[], int idx[], int n, int length) {
  if (length < 2) {
    return isSorted(arr, n);
  }
  for (int i = length - 2; i >= 0; i--) {
    if (permute(arr, idx, n, length - 1)) {
      return 1;
    }
    int t1 = arr[idx[i]];
    arr[idx[i]] = arr[idx[length - 1]];
    arr[idx[length - 1]] = t1;
    int t2 = idx[i];
    idx[i] = idx[length - 1];
    idx[length - 1] = t2;
  }
  if (permute(arr, idx, n, length - 1)) {
    return 1;
  }
  int t = idx[length - 1];
  for (int i = length - 1; i > 0; i--) {
    idx[i] = idx[i - 1];
  }
  idx[0] = t;
  int t2 = arr[idx[0]];
  for (int i = 1; i < length; i++) {
    arr[idx[i - 1]] = arr[idx[i]];
  }
  arr[idx[length - 1]] = t2;
  return 0;
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
