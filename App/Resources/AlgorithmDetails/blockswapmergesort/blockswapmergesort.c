#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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

void multiSwap(int arr[], int a, int b, int len) {
  for (int i = 0; i < len; i++) {
    int t = arr[a + i];
    arr[a + i] = arr[b + i];
    arr[b + i] = t;
  }
}

int binarySearchMid(int arr[], int start, int mid, int end) {
  int a = 0;
  int b = (mid - start < end - mid) ? (mid - start) : (end - mid);
  int m = a + (b - a) / 2;
  while (b > a) {
    if (arr[mid - m - 1] > arr[mid + m]) {
      a = m + 1;
    } else {
      b = m;
    }
    m = a + (b - a) / 2;
  }
  return m;
}

void multiSwapMerge(int arr[], int start, int mid, int end) {
  int m = binarySearchMid(arr, start, mid, end);
  while (m > 0) {
    multiSwap(arr, mid - m, mid, m);
    multiSwapMerge(arr, mid, mid + m, end);
    end = mid;
    mid -= m;
    m = binarySearchMid(arr, start, mid, end);
  }
}

void multiSwapMergeSort(int arr[], int a, int b) {
  int len = b - a;
  int i;
  int j = 1;
  while (j < len) {
    for (i = a; i + 2 * j <= b; i += 2 * j) {
      multiSwapMerge(arr, i, i + j, i + 2 * j);
    }
    if (i + j < b) {
      multiSwapMerge(arr, i, i + j, b);
    }
    j *= 2;
  }
}

void sort(int arr[], int n) {
  multiSwapMergeSort(arr, 0, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
