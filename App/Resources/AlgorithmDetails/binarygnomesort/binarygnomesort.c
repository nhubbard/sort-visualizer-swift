#include <stdio.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

void printList(int items[], int size) {
  printf("[");
  if (size > 0) {
    printf("%d", items[0]);
    for (int i = 1; i < size; i++) {
      printf(", %d", items[i]);
    }
  }
  printf("]");
}

int binarySearch(int arr[], int item, int start, int end);

void sort(int arr[], int n) {
  for (int i = 1; i < n; i++) {
    int item = arr[i];
    int pos = binarySearch(arr, item, 0, i);
    int j = i;
    while (j > pos) {
      int temp = arr[j];
      arr[j] = arr[j - 1];
      arr[j - 1] = temp;
      j--;
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

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
