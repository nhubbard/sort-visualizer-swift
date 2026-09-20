#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

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

void sort(int arr[], int n) {
  for (int k = 2; k < 2 * n; k *= 2) {
    int m = ((n + k - 1) / k) % 2 != 0;
    for (int j = k / 2; j > 0; j /= 2) {
      for (int i = 0; i < n; i++) {
        int l = i ^ j;
        if (l > i && l < n) {
          int ascending = ((i & k) == 0) == m;
          if ((ascending && arr[i] > arr[l]) ||
              (!ascending && arr[i] < arr[l])) {
            swap(&arr[i], &arr[l]);
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
