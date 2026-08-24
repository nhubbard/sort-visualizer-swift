#include <stdio.h>
#include <stdlib.h>

#define INSERTION_THRESHOLD 16

int array[24] = {55, 12, 84, 3,  47, 91, 26, 68, 8,  73, 40, 97,
                 15, 62, 34, 79, 21, 88, 5,  51, 66, 29, 44, 12};

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

void insertionSort(int arr[], int lo, int hi) {
  for (int i = lo + 1; i < hi; i++) {
    int key = arr[i];
    int j = i - 1;
    while (j >= lo && arr[j] > key) {
      arr[j + 1] = arr[j];
      j--;
    }
    arr[j + 1] = key;
  }
}

/* Returns whichever of a, b, c indexes the middle value of the three. */
int medianOfThree(int arr[], int a, int b, int c) {
  if (arr[a] > arr[b]) {
    int t = a;
    a = b;
    b = t;
  }
  if (arr[b] > arr[c]) {
    b = c;
    if (arr[a] > arr[b]) {
      b = a;
    }
  }
  return b;
}

void fluxSortRange(int arr[], int lo, int hi, int swap[]) {
  int n = hi - lo;
  if (n <= INSERTION_THRESHOLD) {
    insertionSort(arr, lo, hi);
    return;
  }

  int mid = lo + n / 2;
  int pivot = arr[medianOfThree(arr, lo, mid, hi - 1)];

  /* Partition into arr (elements <= pivot) and swap (elements > pivot). Ties go
   * to the low side, which is what keeps the sort stable. */
  int lowWrite = lo;
  int highWrite = 0;
  for (int read = lo; read < hi; read++) {
    int value = arr[read];
    if (value > pivot) {
      swap[highWrite] = value;
      highWrite++;
    } else {
      arr[lowWrite] = value;
      lowWrite++;
    }
  }

  for (int i = 0; i < highWrite; i++) {
    arr[lowWrite + i] = swap[i];
  }

  if (lowWrite == hi) {
    /* Every element in range was <= pivot -- a run of duplicates around the
     * pivot value can cause this. There's no split to recurse into, so finish
     * directly. */
    insertionSort(arr, lo, hi);
    return;
  }

  fluxSortRange(arr, lo, lowWrite, swap);
  fluxSortRange(arr, lowWrite, hi, swap);
}

void sort(int arr[], int n) {
  if (n < 2)
    return;
  int *swap = malloc(n * sizeof(int));
  fluxSortRange(arr, 0, n, swap);
  free(swap);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
