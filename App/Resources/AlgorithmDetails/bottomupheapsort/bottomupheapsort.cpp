#include <cstdio>
#include <utility>

int array[16] = {0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56};

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

void siftDown(int arr[], int i, int b) {
  int j = i;
  while (2 * j + 1 < b) {
    if (2 * j + 2 < b) {
      j = (arr[2 * j + 2] > arr[2 * j + 1]) ? 2 * j + 2 : 2 * j + 1;
    } else {
      j = 2 * j + 1;
    }
  }
  while (arr[i] > arr[j]) {
    j = (j - 1) / 2;
  }
  while (j > i) {
    std::swap(arr[i], arr[j]);
    j = (j - 1) / 2;
  }
}

void sort(int arr[], int n) {
  for (int i = (n - 1) / 2; i >= 0; i--) {
    siftDown(arr, i, n);
  }

  for (int i = n - 1; i > 0; i--) {
    std::swap(arr[0], arr[i]);
    siftDown(arr, 0, i);
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
