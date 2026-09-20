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

void sort(int arr[], int end) {
  int i = 0;
  while (i < end - 1) {
    if (arr[i] > arr[i + 1]) {
      for (int f = i; f < end - 1; f++) {
        int t = arr[f];
        arr[f] = arr[f + 1];
        arr[f + 1] = t;
      }
      if (i > 0)
        i--;
      continue;
    }
    i++;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
