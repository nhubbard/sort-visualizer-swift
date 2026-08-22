#include <stdio.h>
#include <stdlib.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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
  int min = arr[0];
  int max = arr[0];
  for (int i = 1; i < n; i++) {
    if (arr[i] < min) {
      min = arr[i];
    }
    if (arr[i] > max) {
      max = arr[i];
    }
  }

  int size = max - min + 1;
  int *holes = calloc(size, sizeof(int));
  for (int i = 0; i < n; i++) {
    holes[arr[i] - min]++;
  }

  int j = 0;
  for (int count = 0; count < size; count++) {
    while (holes[count] > 0) {
      holes[count]--;
      arr[j] = count + min;
      j++;
    }
  }

  free(holes);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
