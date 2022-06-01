#include <stdio.h>
#include <stdlib.h>

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

int partition(int array[], int low, int high) {
  int pivot = array[high];
  int i = (low - 1);
  for (int j = low; j < high; j++) {
    if (array[j] <= pivot) {
      i++;
      swap(&array[i], &array[j]);
    }
  }
  swap(&array[i + 1], &array[high]);
  return (i + 1);
}

void quickSort(int array[], int low, int high) {
  if (low < high) {
    int pi = partition(array, low, high);
    quickSort(array, low, pi - 1);
    quickSort(array, pi + 1, high);
  }
}

int main(int argc, char *argv[]) {
  int items[8] = {1, 5, 2, 3, 7, 4, 8, 9};
  quickSort(items, 0, sizeof(items) / sizeof(items[0]));
  for (int i = 0; i < sizeof(items) / sizeof(items[0]); i++) {
    printf("%d", items[i]);
  }
  return 0;
}
