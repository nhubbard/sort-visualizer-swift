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

int is3Smooth(int n) {
  while (n % 6 == 0) {
    n /= 6;
  }
  while (n % 3 == 0) {
    n /= 3;
  }
  while (n % 2 == 0) {
    n /= 2;
  }
  return n == 1;
}

void sort(int arr[], int n) {
  for (int g = n - 1; g > 0; g--) {
    if (is3Smooth(g)) {
      for (int i = g; i < n; i++) {
        if (arr[i - g] > arr[i]) {
          swap(&arr[i - g], &arr[i]);
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
