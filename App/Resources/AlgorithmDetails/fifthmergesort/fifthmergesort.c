#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

void sortRange(int arr[], int start, int end) {
  int length = end - start;
  if (length < 2) {
    return;
  }
  int bounds[6];
  for (int part = 0; part <= 5; part++) {
    bounds[part] = start + length * part / 5;
  }
  for (int part = 0; part < 5; part++) {
    sortRange(arr, bounds[part], bounds[part + 1]);
  }
  int positions[5];
  for (int part = 0; part < 5; part++) {
    positions[part] = bounds[part];
  }
  int *merged = malloc((size_t)length * sizeof(int));
  for (int offset = 0; offset < length; offset++) {
    int best = -1;
    for (int part = 0; part < 5; part++) {
      if (positions[part] < bounds[part + 1] &&
          (best < 0 || arr[positions[part]] < arr[positions[best]])) {
        best = part;
      }
    }
    merged[offset] = arr[positions[best]++];
  }
  for (int offset = 0; offset < length; offset++) {
    arr[start + offset] = merged[offset];
  }
  free(merged);
}

void sort(int arr[], int n) { sortRange(arr, 0, n); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
