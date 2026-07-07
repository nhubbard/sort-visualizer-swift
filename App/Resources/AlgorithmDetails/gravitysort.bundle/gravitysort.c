#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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
  if (n == 0) return;

  int minValue = arr[0];
  int maxValue = arr[0];
  for (int i = 1; i < n; i++) {
    if (arr[i] < minValue) minValue = arr[i];
    if (arr[i] > maxValue) maxValue = arr[i];
  }
  int ySize = maxValue - minValue + 1;

  int *x = malloc(n * sizeof(int));
  int *y = calloc(ySize, sizeof(int));

  for (int i = 0; i < n; i++) {
    x[i] = arr[i] - minValue;
    y[x[i]]++;
  }

  for (int i = ySize - 1; i > 0; i--) {
    y[i - 1] += y[i];
  }

  for (int j = ySize - 1; j >= 0; j--) {
    for (int i = 0; i < n; i++) {
      int inc = (i >= n - y[j] ? 1 : 0) - (x[i] >= j ? 1 : 0);
      arr[i] += inc;
    }
  }

  free(x);
  free(y);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
