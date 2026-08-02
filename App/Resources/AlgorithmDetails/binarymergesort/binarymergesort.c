#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

const int THRESHOLD = 32;

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

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

void insertionSort(int arr[], int start, int end) {
  for (int i = start + 1; i < end; i++) {
    int j = i;
    while (j > start && arr[j] < arr[j - 1]) {
      swap(&arr[j - 1], &arr[j]);
      j--;
    }
  }
}

void merge(int arr[], int start, int mid, int end) {
  int low = start;
  int high = mid;
  int merged[end - start];
  int k = 0;
  while (low < mid && high < end) {
    if (arr[high] < arr[low]) {
      merged[k++] = arr[high++];
    } else {
      merged[k++] = arr[low++];
    }
  }
  while (low < mid) {
    merged[k++] = arr[low++];
  }
  while (high < end) {
    merged[k++] = arr[high++];
  }
  for (int i = 0; i < k; i++) {
    arr[start + i] = merged[i];
  }
}

void mergeSort(int arr[], int start, int end) {
  if (end - start <= THRESHOLD) {
    insertionSort(arr, start, end);
    return;
  }
  int mid = start + (end - start) / 2;
  mergeSort(arr, start, mid);
  mergeSort(arr, mid, end);
  merge(arr, start, mid, end);
}

void sort(int arr[], int n) {
  if (n < 2)
    return;
  mergeSort(arr, 0, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
