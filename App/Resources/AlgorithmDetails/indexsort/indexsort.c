#include <stdio.h>
#include <stdlib.h>

int array[16] = {7, 3, 14, 0, 9, 5, 12, 1, 15, 4, 10, 2, 13, 6, 11, 8};

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

int findMin(int arr[], int n) {
  int min = arr[0];
  for (int i = 1; i < n; i++) {
    if (arr[i] < min) {
      min = arr[i];
    }
  }
  return min;
}

void sort(int arr[], int n) {
  int minValue = findMin(arr, n);

  for (int i = 0; i < n; i++) {
    int cmpCount = 0;
    while (arr[i] - minValue != i && cmpCount < n) {
      swap(&arr[i], &arr[arr[i] - minValue]);
      cmpCount++;
    }
    if (cmpCount >= n - 1) {
      break;
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
