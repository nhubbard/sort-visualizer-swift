#include <algorithm>
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

bool compSwap(int arr[], int a, int b) {
  if (arr[a] > arr[b]) {
    std::swap(arr[a], arr[b]);
    return true;
  }
  return false;
}

bool stoogeSort(int arr[], int a, int m, int b, bool merge) {
  if (a >= m)
    return false;
  if (b - a == 2)
    return compSwap(arr, a, m);

  bool lChange = false;
  bool rChange = false;

  int a2 = (a + a + b) / 3;
  int b2 = (a + b + b + 2) / 3;

  if (m < b2) {
    lChange = stoogeSort(arr, a, m, b2, merge);
    if (merge) {
      rChange = stoogeSort(arr, std::max(a + b2 - m, a2), b2, b, true);
      if (rChange) {
        stoogeSort(arr, a + b2 - m, a2, 2 * a2 - a, true);
      }
    } else {
      rChange = stoogeSort(arr, a2, b2, b, false);
      if (rChange) {
        stoogeSort(arr, a, a2, 2 * a2 - a, true);
      }
    }
  } else {
    rChange = stoogeSort(arr, a2, m, b, merge);
    if (rChange) {
      stoogeSort(arr, a, a2, a2 + b - m, true);
    }
  }

  return lChange || rChange;
}

void sort(int arr[], int n) { stoogeSort(arr, 0, 1, n, false); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
