#include <stdio.h>

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

/* [start, stop) is the half-open range being sorted. merge selects whether
 * the two halves are recursively pre-sorted before the fixed diamond
 * comparison pattern below merges them together. */
void sort(int arr[], int start, int stop, int merge, int n) {
  if (stop - start == 2) {
    if (stop <= n && arr[start] > arr[stop - 1]) {
      swap(&arr[start], &arr[stop - 1]);
    }
  } else if (stop - start >= 3) {
    double div = (stop - start) / 4.0;
    int mid = (stop - start) / 2 + start;
    int quarter = (int)div + start;
    int threeQuarters = (int)(div * 3) + start;

    if (merge) {
      sort(arr, start, mid, 1, n);
      sort(arr, mid, stop, 1, n);
    }
    sort(arr, quarter, threeQuarters, 0, n);
    sort(arr, start, mid, 0, n);
    sort(arr, mid, stop, 0, n);
    sort(arr, quarter, threeQuarters, 0, n);
  }
}

void sortArray(int arr[], int n) {
  if (n < 2) return;
  int paddedLength = 1;
  while (paddedLength < n) paddedLength *= 2;
  sort(arr, 0, paddedLength, 1, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sortArray(array, size);
  printList(array, size);
  return 0;
}
