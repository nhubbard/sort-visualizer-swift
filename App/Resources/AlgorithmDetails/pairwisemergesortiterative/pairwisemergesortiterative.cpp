#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

int end;

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

void compSwap(int arr[], int a, int b) {
  if (b < end && arr[a] > arr[b]) {
    std::swap(arr[a], arr[b]);
  }
}

void sort(int arr[], int length) {
  end = length;

  int n = 1;
  while (n < length) {
    n <<= 1;
  }

  int k = n >> 1;
  while (k > 0) {
    int j = 0;
    while (j < length) {
      for (int i = 0; i < k; i++) {
        compSwap(arr, j + i, j + k + i);
      }
      j += k << 1;
    }
    k >>= 1;
  }

  k = 2;
  while (k < n) {
    int m = k >> 1;
    while (m > 0) {
      int j = 0;
      while (j < length) {
        int p = m;
        while (p < ((k - m) << 1)) {
          for (int i = 0; i < m; i++) {
            compSwap(arr, j + p + i, j + p + m + i);
          }
          p += m << 1;
        }
        j += k << 1;
      }
      m >>= 1;
    }
    k <<= 1;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
