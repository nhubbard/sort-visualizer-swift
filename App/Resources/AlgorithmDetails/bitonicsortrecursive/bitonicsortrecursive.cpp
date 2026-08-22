#include <cstdio>
#include <utility>

int greatestPowerOfTwoLessThan(int n) {
  int k = 1;
  while (k < n) {
    k <<= 1;
  }
  return k >> 1;
}

void compare(int arr[], int i, int j, bool dir) {
  bool isGreater = arr[i] > arr[j];
  if (dir == isGreater) {
    std::swap(arr[i], arr[j]);
  }
}

void bitonicMerge(int arr[], int lo, int n, bool dir) {
  if (n > 1) {
    int m = greatestPowerOfTwoLessThan(n);
    for (int i = lo; i < lo + n - m; i++) {
      compare(arr, i, i + m, dir);
    }
    bitonicMerge(arr, lo, m, dir);
    bitonicMerge(arr, lo + m, n - m, dir);
  }
}

void bitonicSort(int arr[], int lo, int n, bool dir) {
  if (n > 1) {
    int m = n / 2;
    bitonicSort(arr, lo, m, !dir);
    bitonicSort(arr, lo + m, n - m, dir);
    bitonicMerge(arr, lo, n, dir);
  }
}

void sort(int arr[], int n) { bitonicSort(arr, 0, n, true); }

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

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
