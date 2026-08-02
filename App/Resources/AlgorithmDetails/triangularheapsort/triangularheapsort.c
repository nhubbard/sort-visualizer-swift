#include <math.h>
#include <stdio.h>

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

int triangularRoot(int val) {
  return ((int)sqrt((double)(8 * val + 1)) - 1) / 2;
}

void siftDown(int arr[], int root, int size) {
  while (1) {
    int row = triangularRoot(root);
    int left = root + row + 1;
    if (left >= size)
      break;
    int right = left + 1;
    int largest = root;
    if (arr[largest] < arr[left])
      largest = left;
    if (right < size && arr[largest] < arr[right])
      largest = right;
    if (largest == root)
      break;
    swap(&arr[root], &arr[largest]);
    root = largest;
  }
}

void heapify(int arr[], int length) {
  for (int i = length - 1; i >= 0; i--) {
    siftDown(arr, i, length);
  }
}

void sort(int arr[], int size) {
  if (size <= 1)
    return;
  heapify(arr, size);
  for (int i = 1; i < size - 1; i++) {
    swap(&arr[0], &arr[size - i]);
    siftDown(arr, 0, size - i);
  }
  if (arr[0] > arr[1]) {
    swap(&arr[0], &arr[1]);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
