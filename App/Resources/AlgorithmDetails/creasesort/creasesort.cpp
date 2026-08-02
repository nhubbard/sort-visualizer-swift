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

void compSwap(int arr[], int a, int b) {
  if (arr[a] > arr[b]) {
    std::swap(arr[a], arr[b]);
  }
}

void sort(int arr[], int n) {
  int maxVal = 1;
  while (maxVal * 2 < n) {
    maxVal *= 2;
  }

  int next = maxVal;
  while (next > 0) {
    int i = 0;
    while (i + 1 < n) {
      compSwap(arr, i, i + 1);
      i += 2;
    }

    int j = maxVal;
    while (j >= next && j > 1) {
      i = 1;
      while (i + j - 1 < n) {
        compSwap(arr, i, i + j - 1);
        i += 2;
      }
      j /= 2;
    }

    next /= 2;
  }
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}