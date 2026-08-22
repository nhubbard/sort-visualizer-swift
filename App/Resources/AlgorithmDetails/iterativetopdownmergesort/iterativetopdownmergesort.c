#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

void merge(int arr[], int low, int mid, int high) {
  int leftSize = mid - low;
  int rightSize = high - mid;
  int *left = malloc(leftSize * sizeof(int));
  int *right = malloc(rightSize * sizeof(int));
  for (int x = 0; x < leftSize; x++) {
    left[x] = arr[low + x];
  }
  for (int x = 0; x < rightSize; x++) {
    right[x] = arr[mid + x];
  }

  int i = 0, j = 0, k = low;
  while (i < leftSize && j < rightSize) {
    if (left[i] <= right[j]) {
      arr[k++] = left[i++];
    } else {
      arr[k++] = right[j++];
    }
  }
  while (i < leftSize) {
    arr[k++] = left[i++];
  }
  while (j < rightSize) {
    arr[k++] = right[j++];
  }

  free(left);
  free(right);
}

void sort(int arr[], int n) {
  int subarrayCount = 1;
  while (subarrayCount < n) {
    subarrayCount *= 2;
  }

  while (subarrayCount > 1) {
    for (int i = 0; i < subarrayCount; i += 2) {
      int low = n * i / subarrayCount;
      int mid = n * (i + 1) / subarrayCount;
      int high = n * (i + 2) / subarrayCount;
      merge(arr, low, mid, high);
    }
    subarrayCount /= 2;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}