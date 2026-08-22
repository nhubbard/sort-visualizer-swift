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

int circle(int arr[], int left, int right) {
  int a = left;
  int b = right;
  int swapped = 0;
  while (a < b) {
    if (arr[a] > arr[b]) {
      swap(&arr[a], &arr[b]);
      swapped = 1;
    }
    a++;
    b--;
    if (a == b) {
      b++;
    }
  }
  return swapped;
}

int circlePass(int arr[], int left, int right) {
  if (left >= right) {
    return 0;
  }
  int mid = (left + right) / 2;
  int l = circlePass(arr, left, mid);
  int r = circlePass(arr, mid + 1, right);
  int c = circle(arr, left, right);
  return c || l || r;
}

void sort(int arr[], int n) {
  if (n <= 1) {
    return;
  }
  while (circlePass(arr, 0, n - 1)) {
    /* repeat until a full sweep makes no swaps */
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
