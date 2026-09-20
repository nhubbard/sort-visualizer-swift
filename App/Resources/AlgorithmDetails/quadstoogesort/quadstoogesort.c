#include <stdio.h>
#include <stdlib.h>

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

void quadStooge(int arr[], int pos, int length);

void sort(int arr[], int n) {
  quadStooge(arr, 0, n);
}

void quadStooge(int arr[], int pos, int length) {
  if (length >= 2 && arr[pos] > arr[pos + length - 1]) {
    swap(&arr[pos], &arr[pos + length - 1]);
  }
  if (length <= 2) {
    return;
  }

  int len1 = length / 2;
  int len2 = (length + 1) / 2;
  int len3 = (len1 + 1) / 2 + (len2 + 1) / 2;

  quadStooge(arr, pos, len1);
  quadStooge(arr, pos + len1, len2);
  quadStooge(arr, pos + len1 / 2, len3);
  quadStooge(arr, pos + len1, len2);
  quadStooge(arr, pos, len1);
  if (length > 3) {
    quadStooge(arr, pos + len1 / 2, len3);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
