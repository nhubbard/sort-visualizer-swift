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

void siftDown(int arr[], int root, int size) {
  while (1) {
    int smallest = root;
    int left = 2 * root + 1;
    int right = 2 * root + 2;
    if (left < size && arr[left] < arr[smallest]) {
      smallest = left;
    }
    if (right < size && arr[right] < arr[smallest]) {
      smallest = right;
    }
    if (smallest == root) {
      break;
    }
    swap(&arr[root], &arr[smallest]);
    root = smallest;
  }
}

void heapify(int arr[], int n) {
  for (int i = n / 2 - 1; i >= 0; i--) {
    siftDown(arr, i, n);
  }
}

void reverse(int arr[], int n) {
  int low = 0, high = n - 1;
  while (low < high) {
    swap(&arr[low], &arr[high]);
    low++;
    high--;
  }
}

void sort(int arr[], int n) {
  heapify(arr, n);
  for (int end = n - 1; end > 0; end--) {
    swap(&arr[0], &arr[end]);
    siftDown(arr, 0, end);
  }
  reverse(arr, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
