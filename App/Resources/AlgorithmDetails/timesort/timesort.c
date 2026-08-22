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
  if (n <= 1) {
    return;
  }

  /* Simulate the reporting order that proportional-to-value sleep durations
   * would produce in a jitter-free race: stable-sort the original positions
   * by value, so ties wake in the order they were originally scheduled. */
  int indices[n];
  for (int i = 0; i < n; i++) {
    indices[i] = i;
  }
  for (int i = 1; i < n; i++) {
    int j = i;
    while (j > 0 && arr[indices[j - 1]] > arr[indices[j]]) {
      swap(&indices[j - 1], &indices[j]);
      j--;
    }
  }

  int woke[n];
  for (int i = 0; i < n; i++) {
    woke[i] = arr[indices[i]];
  }
  for (int i = 0; i < n; i++) {
    arr[i] = woke[i];
  }

  /* Defensive cleanup pass: real scheduling jitter can't be fully trusted, so
   * finish with an ordinary insertion sort no matter what the race produced. */
  for (int i = 1; i < n; i++) {
    int j = i;
    while (j > 0 && arr[j - 1] > arr[j]) {
      swap(&arr[j - 1], &arr[j]);
      j--;
    }
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}