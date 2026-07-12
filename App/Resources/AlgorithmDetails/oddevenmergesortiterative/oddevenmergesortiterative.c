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

void sort(int arr[], int n) {
  for (int p = 1; p < n; p += p) {
    for (int k = p; k > 0; k /= 2) {
      for (int j = k % p; j + k < n; j += k + k) {
        for (int i = 0; i < k; i++) {
          if ((i + j) / (p + p) == (i + j + k) / (p + p)) {
            if (i + j + k < n) {
              if (arr[i + j] > arr[i + j + k]) {
                swap(&arr[i + j], &arr[i + j + k]);
              }
            }
          }
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