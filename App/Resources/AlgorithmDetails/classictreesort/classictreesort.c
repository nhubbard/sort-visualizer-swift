#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

static int idx;

void traverse(int arr[], int temp[], int lower[], int upper[], int r);

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
  int *lower = calloc(n, sizeof(int));
  int *upper = calloc(n, sizeof(int));

  for (int i = 1; i < n; i++) {
    int c = 0;
    while (1) {
      int *next = (arr[i] < arr[c]) ? lower : upper;
      if (next[c] == 0) {
        next[c] = i;
        break;
      } else {
        c = next[c];
      }
    }
  }

  int *temp = malloc(sizeof(int) * n);
  idx = 0;
  traverse(arr, temp, lower, upper, 0);
  memcpy(arr, temp, sizeof(int) * n);

  free(lower);
  free(upper);
  free(temp);
}

void traverse(int arr[], int temp[], int lower[], int upper[], int r) {
  if (lower[r] != 0) {
    traverse(arr, temp, lower, upper, lower[r]);
  }
  temp[idx++] = arr[r];
  if (upper[r] != 0) {
    traverse(arr, temp, lower, upper, upper[r]);
  }
}



int main(void) {
  int array[16] = {0,  39, 21, 62, 91, 77, 14, 23,
                   90, 69, 51, 81, 68, 83, 32, 56};
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
