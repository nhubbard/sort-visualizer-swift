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

void siftDown(int arr[], int root, int size);

void sort(int arr[], int n) {
  for (int i = n / 2 - 1; i >= 0; i--) {
    siftDown(arr, i, n);
  }
  for (int i = n - 1; i > 0; i--) {
    swap(&arr[0], &arr[i]);
    siftDown(arr, 0, i);
  }
}

void siftDown(int arr[], int root, int size) {
  while (1) {
    int largest = root;
    int left = 2 * root + 1;
    int right = left + 1;
    if (left < size && arr[largest] < arr[left]) largest = left;
    if (right < size && arr[largest] < arr[right]) largest = right;
    if (largest == root) break;
    swap(&arr[root], &arr[largest]);
    root = largest;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
