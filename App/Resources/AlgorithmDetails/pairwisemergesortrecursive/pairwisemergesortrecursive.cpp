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

void pairwiseMerge(int arr[], int a, int b) {
  int m = (a + b) / 2;
  int m1 = (a + m) / 2;
  int g = m - m1;

  for (int i = 0; i < m - m1; i++) {
    int j = m1;
    int k = g;
    while (k > 0) {
      compSwap(arr, j + i, j + i + k);
      k >>= 1;
      j -= (k - (i & k));
    }
  }
  if (b - a > 4) {
    pairwiseMerge(arr, m, b);
  }
}

void pairwiseMergeSort(int arr[], int a, int b) {
  int m = (a + b) / 2;
  int i = a;
  int j = m;
  while (i < m) {
    compSwap(arr, i, j);
    i++;
    j++;
  }
  if (b - a > 2) {
    pairwiseMergeSort(arr, a, m);
    pairwiseMergeSort(arr, m, b);
    pairwiseMerge(arr, a, b);
  }
}

void sort(int arr[], int length) {
  end = length;

  int n = 1;
  while (n < length) {
    n <<= 1;
  }

  pairwiseMergeSort(arr, 0, n);
}

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
