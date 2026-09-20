#include <stdio.h>

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

int greatestPowerOfTwoLessThan(int n);
void compare(int arr[], int i, int j, int dir);
void bitonicMerge(int arr[], int lo, int n, int dir);
void bitonicSort(int arr[], int lo, int n, int dir);

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
  bitonicSort(arr, 0, n, 1);
}

int greatestPowerOfTwoLessThan(int n) {
  int k = 1;
  while (k < n) {
    k <<= 1;
  }
  return k >> 1;
}

void compare(int arr[], int i, int j, int dir) {
  int isGreater = arr[i] > arr[j];
  if (dir == isGreater) {
    int t = arr[i];
    arr[i] = arr[j];
    arr[j] = t;
  }
}

void bitonicMerge(int arr[], int lo, int n, int dir) {
  if (n > 1) {
    int m = greatestPowerOfTwoLessThan(n);
    for (int i = lo; i < lo + n - m; i++) {
      compare(arr, i, i + m, dir);
    }
    bitonicMerge(arr, lo, m, dir);
    bitonicMerge(arr, lo + m, n - m, dir);
  }
}

void bitonicSort(int arr[], int lo, int n, int dir) {
  if (n > 1) {
    int m = n / 2;
    bitonicSort(arr, lo, m, !dir);
    bitonicSort(arr, lo + m, n - m, dir);
    bitonicMerge(arr, lo, n, dir);
  }
}



int main(int argc, char *argv[]) {
  int array[16] = {0,  39, 21, 62, 91, 77, 14, 23,
                   90, 69, 51, 81, 68, 83, 32, 56};
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
