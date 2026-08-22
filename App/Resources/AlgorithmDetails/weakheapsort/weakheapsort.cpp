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

void merge(int arr[], bool flags[], int i, int j) {
  if (arr[i] < arr[j]) {
    flags[j] = !flags[j];
    std::swap(arr[i], arr[j]);
  }
}

void sort(int arr[], int n) {
  bool flags[n];
  for (int i = 0; i < n; i++) {
    flags[i] = false;
  }

  for (int i = n - 1; i > 0; i--) {
    int j = i;
    while ((j & 1) == (flags[j >> 1] ? 1 : 0)) {
      j >>= 1;
    }
    int gparent = j >> 1;
    merge(arr, flags, gparent, i);
  }

  for (int i = n - 1; i > 1; i--) {
    std::swap(arr[0], arr[i]);
    int x = 1;
    while (true) {
      int y = 2 * x + (flags[x] ? 1 : 0);
      if (y >= i) {
        break;
      }
      x = y;
    }
    while (x > 0) {
      merge(arr, flags, 0, x);
      x >>= 1;
    }
  }
  std::swap(arr[0], arr[1]);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
