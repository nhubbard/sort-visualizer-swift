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

int stablePartition(int arr[], int start, int end) {
  int pivotValue = arr[start];
  int leftList[16];
  int rightList[16];
  int leftCount = 0;
  int rightCount = 0;

  for (int i = start + 1; i <= end; i++) {
    if (arr[i] < pivotValue) {
      leftList[leftCount++] = arr[i];
    } else {
      rightList[rightCount++] = arr[i];
    }
  }

  int writeIndex = start;
  for (int i = 0; i < leftCount; i++) {
    arr[writeIndex++] = leftList[i];
  }
  int pivotIndex = writeIndex;
  arr[writeIndex++] = pivotValue;
  for (int i = 0; i < rightCount; i++) {
    arr[writeIndex++] = rightList[i];
  }
  return pivotIndex;
}

void stableQuickSort(int arr[], int start, int end) {
  if (start < end) {
    int p = stablePartition(arr, start, end);
    stableQuickSort(arr, start, p - 1);
    stableQuickSort(arr, p + 1, end);
  }
}

void sort(int arr[], int n) { stableQuickSort(arr, 0, n - 1); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
