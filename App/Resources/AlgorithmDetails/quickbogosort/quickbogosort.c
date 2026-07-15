#include <stdio.h>
#include <stdlib.h>

int array[7] = {0, 39, 21, 62, 91, 14, 23};

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

int isPartitioned(int arr[], int start, int end, int pivot) {
  for (int i = start; i < pivot; i++) {
    if (arr[i] > arr[pivot]) {
      return 0;
    }
  }
  for (int i = pivot + 1; i < end; i++) {
    if (arr[pivot] > arr[i]) {
      return 0;
    }
  }
  return 1;
}

void sortRange(int arr[], int start, int end) {
  if (start >= end - 1) {
    return;
  }

  int pivot = start;

  while (!isPartitioned(arr, start, end, pivot)) {
    for (int i = start; i < end; i++) {
      int j = i + rand() % (end - i);
      if (pivot == i) {
        pivot = j;
      } else if (pivot == j) {
        pivot = i;
      }
      int t = arr[i];
      arr[i] = arr[j];
      arr[j] = t;
    }
  }

  sortRange(arr, start, pivot);
  sortRange(arr, pivot + 1, end);
}

void sort(int arr[], int n) {
  sortRange(arr, 0, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
