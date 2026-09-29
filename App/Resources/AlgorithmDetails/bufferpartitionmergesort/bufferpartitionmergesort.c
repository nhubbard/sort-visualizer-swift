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

void sort(int arr[], int n) {
  const int run = 8;
  for (int start = 0; start < n; start += run) {
    int end = start + run < n ? start + run : n;
    for (int i = start + 1; i < end; i++) {
      int value = arr[i];
      int j = i;
      while (j > start && arr[j - 1] > value) {
        arr[j] = arr[j - 1];
        j--;
      }
      arr[j] = value;
    }
  }

  int *scratch = malloc((size_t)n * sizeof(int));
  for (int i = 0; i < n; i++)
    scratch[i] = arr[i];
  for (int width = run; width < n; width *= 2) {
    for (int start = 0; start < n; start += 2 * width) {
      int middle = start + width < n ? start + width : n;
      int end = start + 2 * width < n ? start + 2 * width : n;
      int left = start;
      int right = middle;
      for (int out = start; out < end; out++) {
        if (left < middle && (right >= end || arr[left] < arr[right]))
          scratch[out] = arr[left++];
        else
          scratch[out] = arr[right++];
      }
    }
    for (int i = 0; i < n; i++)
      arr[i] = scratch[i];
  }
  free(scratch);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
