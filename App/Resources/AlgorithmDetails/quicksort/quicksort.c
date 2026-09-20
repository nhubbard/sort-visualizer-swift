#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

void printList(int arr[], int n) {
  for (int i = 0; i < n; i++) {
    if (i == 0) {
      printf("[%d, ", arr[i]);
    } else if (i != n - 1) {
      printf("%d, ", arr[i]);
    } else {
      printf("%d]", arr[i]);
    }
  }
}

int partition(int arr[], int left, int right) {
  int i = left, j = right;
  while (i < j) {
    while (i < j && arr[i] <= arr[left]) i++;
    while (arr[j] > arr[left]) j--;
    if (i < j) swap(&arr[i], &arr[j]);
  }
  swap(&arr[left], &arr[j]);
  return j;
}

void sort(int arr[], int low, int high) {
  if (low < high) {
    int pivot = partition(arr, low, high);
    sort(arr, low, pivot - 1);
    sort(arr, pivot + 1, high);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, 0, size - 1);
  printList(array, size);
  return 0;
}
