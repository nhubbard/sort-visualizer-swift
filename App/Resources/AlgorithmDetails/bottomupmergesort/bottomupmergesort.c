#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

int min(int a, int b) { return a < b ? a : b; }

void merge(int arr[], int low, int mid, int high) {
  int leftSize = mid - low;
  int rightSize = high - mid;
  int *left = malloc(leftSize * sizeof(int));
  int *right = malloc(rightSize * sizeof(int));
  for (int x = 0; x < leftSize; x++)
    left[x] = arr[low + x];
  for (int x = 0; x < rightSize; x++)
    right[x] = arr[mid + x];

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
  for (int width = 1; width < n; width *= 2) {
    for (int low = 0; low < n; low += 2 * width) {
      int mid = min(low + width, n);
      int high = min(low + 2 * width, n);
      if (mid < high) {
        merge(arr, low, mid, high);
      }
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
