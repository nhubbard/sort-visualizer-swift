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
