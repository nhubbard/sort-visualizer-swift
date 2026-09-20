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
  int maxValue = 0;
  for (int i = 0; i < n; i++) {
    if (arr[i] > maxValue) maxValue = arr[i];
  }
  int *output = malloc((size_t)n * sizeof(int));
  int divisor = 1;
  do {
    int counts[4] = {0, 0, 0, 0};
    for (int i = 0; i < n; i++) counts[(arr[i] / divisor) % 4]++;
    for (int digit = 1; digit < 4; digit++) counts[digit] += counts[digit - 1];
    for (int i = n - 1; i >= 0; i--) {
      int digit = (arr[i] / divisor) % 4;
      output[--counts[digit]] = arr[i];
    }
    for (int i = 0; i < n; i++) arr[i] = output[i];
    if (divisor > maxValue / 4) break;
    divisor *= 4;
  } while (1);
  free(output);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
