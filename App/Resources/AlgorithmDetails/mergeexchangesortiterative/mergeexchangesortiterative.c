#include <math.h>
#include <stdio.h>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

void swap(int *a, int *b) {
  int t = *a;
  *a = *b;
  *b = t;
}

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

void mergeExchangeSort(int arr[], int n) {
  if (n <= 1)
    return;
  int t = (int)(log(n - 1) / log(2)) + 1;
  int p0 = 1 << (t - 1);
  for (int p = p0; p > 0; p >>= 1) {
    int q = p0;
    int r = 0;
    int d = p;
    while (1) {
      for (int i = 0; i < n - d; i++) {
        if ((i & p) == r && arr[i] > arr[i + d]) {
          swap(&arr[i], &arr[i + d]);
        }
      }
      if (q == p)
        break;
      d = q - p;
      q >>= 1;
      r = p;
    }
  }
}

void sort(int arr[], int n) { mergeExchangeSort(arr, n); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
