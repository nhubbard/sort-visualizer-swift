#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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

int medianOf3(int arr[], int left, int mid, int right) {
  if (!(arr[left] >= arr[right])) {
    swap(&arr[left], &arr[right]);
  }
  if (!(arr[left] >= arr[mid])) {
    swap(&arr[left], &arr[mid]);
  }
  if (!(arr[mid] >= arr[right])) {
    swap(&arr[mid], &arr[right]);
  }
  return mid;
}

int partition(int arr[], int lo, int hi, int pivotValue) {
  int i = lo, j = hi;
  while (1) {
    while (arr[i] < pivotValue) i++;
    j--;
    while (pivotValue < arr[j]) j--;
    if (!(i < j)) return i;
    swap(&arr[i], &arr[j]);
    i++;
  }
}

void siftDown(int arr[], int lo, int root, int rangeSize) {
  while (1) {
    int largest = root;
    int left = 2 * root + 1;
    int right = 2 * root + 2;
    if (left < rangeSize && arr[lo + largest] < arr[lo + left]) largest = left;
    if (right < rangeSize && arr[lo + largest] < arr[lo + right]) largest = right;
    if (largest == root) break;
    swap(&arr[lo + root], &arr[lo + largest]);
    root = largest;
  }
}

void heapSortRange(int arr[], int lo, int hi) {
  int size = hi - lo;
  for (int i = size / 2 - 1; i >= 0; i--) siftDown(arr, lo, i, size);
  for (int end = size - 1; end > 0; end--) {
    swap(&arr[lo], &arr[lo + end]);
    siftDown(arr, lo, 0, end);
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

int floorLog2(int a) {
  return (int)floor(log((double)a) / log(2.0));
}

void introsortLoop(int arr[], int lo, int hi, int depthLimit) {
  while (hi - lo > 16) {
    if (depthLimit == 0) {
      heapSortRange(arr, lo, hi);
      return;
    }
    depthLimit--;
    int mid = lo + (hi - lo) / 2;
    int pivotIndex = medianOf3(arr, lo, mid, hi - 1);
    int pivotValue = arr[pivotIndex];
    int p = partition(arr, lo, hi, pivotValue);
    introsortLoop(arr, p, hi, depthLimit);
    hi = p;
  }
}

void sort(int arr[], int n) {
  introsortLoop(arr, 0, n, 2 * floorLog2(n));
  insertionSort(arr, 0, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
