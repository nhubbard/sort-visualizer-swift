#include <algorithm>
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

void multiSwap(int arr[], int a, int b, int len);
int binarySearchMid(int arr[], int start, int mid, int end);
void multiSwapMerge(int arr[], int start, int mid, int end);
void multiSwapMergeSort(int arr[], int a, int b);

void sort(int arr[], int n) {
  multiSwapMergeSort(arr, 0, n);
}

void multiSwap(int arr[], int a, int b, int len) {
  for (int i = 0; i < len; i++) {
    std::swap(arr[a + i], arr[b + i]);
  }
}

int binarySearchMid(int arr[], int start, int mid, int end) {
  int a = 0;
  int b = std::min(mid - start, end - mid);
  int m = a + (b - a) / 2;
  while (b > a) {
    if (arr[mid - m - 1] > arr[mid + m]) {
      a = m + 1;
    } else {
      b = m;
    }
    m = a + (b - a) / 2;
  }
  return m;
}

void multiSwapMerge(int arr[], int start, int mid, int end) {
  int m = binarySearchMid(arr, start, mid, end);
  while (m > 0) {
    multiSwap(arr, mid - m, mid, m);
    multiSwapMerge(arr, mid, mid + m, end);
    end = mid;
    mid -= m;
    m = binarySearchMid(arr, start, mid, end);
  }
}

void multiSwapMergeSort(int arr[], int a, int b) {
  int len = b - a;
  int i;
  int j = 1;
  while (j < len) {
    for (i = a; i + 2 * j <= b; i += 2 * j) {
      multiSwapMerge(arr, i, i + j, i + 2 * j);
    }
    if (i + j < b) {
      multiSwapMerge(arr, i, i + j, b);
    }
    j *= 2;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
