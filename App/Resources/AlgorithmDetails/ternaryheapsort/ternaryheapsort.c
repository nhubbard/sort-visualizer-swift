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

void maxHeapify(int arr[], int heapSize, int i);

void sort(int arr[], int n) {
  int heapSize = n - 1;

  for (int i = n - 1; i >= 0; i--) {
    maxHeapify(arr, heapSize, i);
  }

  for (int i = n - 1; i >= 0; i--) {
    int t = arr[0];
    arr[0] = arr[i];
    arr[i] = t;
    heapSize -= 1;
    maxHeapify(arr, heapSize, 0);
  }
}

void maxHeapify(int arr[], int heapSize, int i) {
  int left = 3 * i + 1;
  int mid = 3 * i + 2;
  int right = 3 * i + 3;
  int largest = i;
  if (left <= heapSize && arr[left] > arr[largest]) {
    largest = left;
  }
  if (right <= heapSize && arr[right] > arr[largest]) {
    largest = right;
  }
  if (mid <= heapSize && arr[mid] > arr[largest]) {
    largest = mid;
  }
  if (largest != i) {
    int t = arr[i];
    arr[i] = arr[largest];
    arr[largest] = t;
    maxHeapify(arr, heapSize, largest);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
