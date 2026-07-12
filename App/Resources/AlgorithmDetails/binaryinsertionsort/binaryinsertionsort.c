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

int binarySearch(int arr[], int item, int start, int end) {
  int low = start;
  int high = end;
  while (low < high) {
    int mid = low + (high - low) / 2;
    if (item < arr[mid]) {
      high = mid;
    } else {
      low = mid + 1;
    }
  }
  return low;
}

void sort(int arr[], int n) {
  for (int i = 1; i < n; i++) {
    int item = arr[i];
    int pos = binarySearch(arr, item, 0, i);
    int j = i;
    while (j > pos) {
      arr[j] = arr[j - 1];
      j--;
    }
    arr[pos] = item;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
