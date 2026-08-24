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

int circleSortRoutine(int arr[], int lo, int hi, int end) {
  if (lo == hi) {
    return 0;
  }
  int low = lo;
  int high = hi;
  int mid = (hi - lo) / 2;
  int swapCount = 0;
  while (lo < hi) {
    if (hi < end && arr[lo] > arr[hi]) {
      swap(&arr[lo], &arr[hi]);
      swapCount++;
    }
    lo++;
    hi--;
  }
  swapCount += circleSortRoutine(arr, low, low + mid, end);
  if (low + mid + 1 < end) {
    swapCount += circleSortRoutine(arr, low + mid + 1, high, end);
  }
  return swapCount;
}

void binaryInsertionSort(int arr[], int end) {
  for (int i = 1; i < end; i++) {
    int value = arr[i];
    int lo = 0;
    int hi = i;
    while (lo < hi) {
      int mid = lo + (hi - lo) / 2;
      if (value < arr[mid]) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    int j = i;
    while (j > lo) {
      arr[j] = arr[j - 1];
      j--;
    }
    arr[lo] = value;
  }
}

void sort(int arr[], int size) {
  if (size <= 1)
    return;
  int n = 1;
  int threshold = 0;
  while (n < size) {
    n <<= 1;
    threshold++;
  }
  threshold /= 2;

  int iterations = 0;
  while (1) {
    iterations++;
    if (iterations >= threshold) {
      binaryInsertionSort(arr, size);
      return;
    }
    if (circleSortRoutine(arr, 0, n - 1, size) == 0) {
      return;
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
