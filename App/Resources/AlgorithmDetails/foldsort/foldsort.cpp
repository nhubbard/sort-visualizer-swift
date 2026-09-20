#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23,
                 90, 69, 51, 81, 68, 83, 32, 56};

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

int end;

void compSwap(int arr[], int a, int b);
void halver(int arr[], int low, int high);

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

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
