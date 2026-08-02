#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

int end;

void compSwap(int arr[], int a, int b) {
  if (b < end && arr[a] > arr[b]) {
    std::swap(arr[a], arr[b]);
  }
}

void halver(int arr[], int low, int high) {
  while (low < high) {
    compSwap(arr, low, high);
    low++;
    high--;
  }
}

void sort(int arr[], int n) {
  end = n;
  int ceilLog = 1;
  while ((1 << ceilLog) < n) {
    ceilLog++;
  }
  int size2 = 1 << ceilLog;

  int k = size2 >> 1;
  while (k > 0) {
    int i = size2;
    while (i >= k) {
      int j = 0;
      while (j < end) {
        halver(arr, j, j + i - 1);
        j += i;
      }
      i >>= 1;
    }
    k >>= 1;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}