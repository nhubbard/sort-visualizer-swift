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
