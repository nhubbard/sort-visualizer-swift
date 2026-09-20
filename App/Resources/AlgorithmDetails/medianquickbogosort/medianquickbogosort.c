#include <stdio.h>
#include <stdlib.h>

int array[7] = {0, 39, 21, 62, 91, 14, 23};

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

int isSplit(int arr[], int start, int mid, int end);
void shuffleRange(int arr[], int start, int end);
void sortRange(int arr[], int start, int end);

void sort(int arr[], int n) {
  sortRange(arr, 0, n);
}

int isSplit(int arr[], int start, int mid, int end) {
  int lowMax = arr[start];
  for (int i = start + 1; i < mid; i++) {
    if (arr[i] > lowMax) {
      lowMax = arr[i];
    }
  }
  for (int i = mid; i < end; i++) {
    if (lowMax > arr[i]) {
      return 0;
    }
  }
  return 1;
}

void shuffleRange(int arr[], int start, int end) {
  for (int i = end - 1; i > start; i--) {
    int j = start + rand() % (i - start + 1);
    int t = arr[i];
    arr[i] = arr[j];
    arr[j] = t;
  }
}

void sortRange(int arr[], int start, int end) {
  if (start >= end - 1) {
    return;
  }
  int mid = (start + end) / 2;

  while (!isSplit(arr, start, mid, end)) {
    shuffleRange(arr, start, end);
  }

  sortRange(arr, start, mid);
  sortRange(arr, mid, end);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
