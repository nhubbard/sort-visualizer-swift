#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

void compSwap(int arr[], int a, int b, int end) {
  if (b < end && arr[a] > arr[b]) {
    swap(&arr[a], &arr[b]);
  }
}

void circle(int arr[], int pos, int ln, int gap, int end) {
  if (ln < 2) {
    return;
  }
  int i = 0;
  while (2 * i < (ln - 1) * gap) {
    compSwap(arr, pos + i, pos + (ln - 1) * gap - i, end);
    i += gap;
  }
  circle(arr, pos, ln / 2, gap, end);
  if (pos + ln * gap / 2 < end) {
    circle(arr, pos + ln * gap / 2, ln / 2, gap, end);
  }
}

void weaveCircle(int arr[], int pos, int ln, int gap, int end) {
  if (ln < 2) {
    return;
  }
  weaveCircle(arr, pos, ln / 2, 2 * gap, end);
  weaveCircle(arr, pos + gap, ln / 2, 2 * gap, end);
  circle(arr, pos, ln, gap, end);
}

void sort(int arr[], int n) {
  int end = n;
  int padded = 1;
  while (padded < end) {
    padded *= 2;
  }
  weaveCircle(arr, 0, padded, 1, end);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}