#include <math.h>
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

void sort(int arr[], int n) {
  if (n <= 1) {
    return;
  }
  int pow2 = (int)(log(n - 1) / log(2));
  for (int k = pow2; k >= 0; k--) {
    int pow3 = (int)((log(n) - k * log(2)) / log(3));
    for (int j = pow3; j >= 0; j--) {
      int gap = (int)(pow(2, k) * pow(3, j));
      int i;
      for (i = 0; i + gap < n; i++) {
        if (arr[i] > arr[i + gap]) {
          swap(&arr[i], &arr[i + gap]);
        }
      }
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
