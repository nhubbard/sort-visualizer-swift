#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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
  if (n == 0)
    return;

  int maxValue = arr[0];
  for (int i = 1; i < n; i++) {
    if (arr[i] > maxValue)
      maxValue = arr[i];
  }

  int *transpose = calloc(maxValue, sizeof(int));

  for (int i = 0; i < n; i++) {
    int value = arr[i];
    for (int j = 0; j < value; j++) {
      transpose[j]++;
    }
  }

  for (int i = 0; i < n; i++) {
    int total = 0;
    for (int j = 0; j < maxValue; j++) {
      if (transpose[j] > 0)
        total++;
    }
    arr[n - i - 1] = total;
    for (int j = 0; j < maxValue; j++) {
      transpose[j]--;
    }
  }

  free(transpose);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}