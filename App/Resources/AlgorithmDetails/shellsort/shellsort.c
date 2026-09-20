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

void sort(int arr[], int n) {
  const int gaps[] = {8861, 3938, 1750, 701, 301, 132, 57, 23, 10, 4, 1};
  for (int g = 0; g < 11; g++) {
    int gap = gaps[g];
    if (gap >= n) continue;
    for (int i = gap; i < n; i++) {
      int j = i;
      while (j >= gap && arr[j] < arr[j - gap]) {
        swap(&arr[j], &arr[j - gap]);
        j -= gap;
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
