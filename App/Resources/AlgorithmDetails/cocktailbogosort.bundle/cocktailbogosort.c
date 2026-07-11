#include <stdio.h>
#include <stdlib.h>

int array[8] = {0, 39, 21, 62, 91, 77, 14, 23};

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

int isMinimum(int arr[], int start, int end) {
  for (int k = start + 1; k < end; k++) {
    if (arr[start] > arr[k]) {
      return 0;
    }
  }
  return 1;
}

int isMaximum(int arr[], int start, int end) {
  for (int k = start; k < end - 1; k++) {
    if (arr[k] > arr[end - 1]) {
      return 0;
    }
  }
  return 1;
}

void shuffleRange(int arr[], int start, int end) {
  for (int i = start; i < end - 1; i++) {
    int j = i + rand() % (end - i);
    swap(&arr[i], &arr[j]);
  }
}

void sort(int arr[], int n) {
  int lo = 0;
  int hi = n;
  while (lo < hi - 1) {
    if (isMinimum(arr, lo, hi)) {
      lo++;
    } else if (isMaximum(arr, lo, hi)) {
      hi--;
    } else {
      shuffleRange(arr, lo, hi);
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
