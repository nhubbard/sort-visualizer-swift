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

int partition(int arr[], int left, int right);

void sort(int arr[], int low, int high) {
  if (low < high) {
    int pivot = partition(arr, low, high);
    sort(arr, low, pivot - 1);
    sort(arr, pivot + 1, high);
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

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, 0, size - 1);
  printList(array, size);
  return 0;
}
