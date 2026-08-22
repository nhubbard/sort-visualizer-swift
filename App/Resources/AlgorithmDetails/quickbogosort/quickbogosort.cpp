#include <cstdio>
#include <cstdlib>
#include <utility>

int array[7] = {0, 39, 21, 62, 91, 14, 23};

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

bool isPartitioned(int arr[], int start, int pivot, int end) {
  for (int i = start; i < pivot; i++) {
    if (arr[i] > arr[pivot]) {
      return false;
    }
  }
  for (int i = pivot + 1; i < end; i++) {
    if (arr[pivot] > arr[i]) {
      return false;
    }
  }
  return true;
}

void sortRange(int arr[], int start, int end) {
  if (start >= end - 1) {
    return;
  }

  int pivot = start;

  while (!isPartitioned(arr, start, pivot, end)) {
    for (int i = start; i < end; i++) {
      int j = i + rand() % (end - i);
      if (pivot == i) {
        pivot = j;
      } else if (pivot == j) {
        pivot = i;
      }
      std::swap(arr[i], arr[j]);
    }
  }

  sortRange(arr, start, pivot);
  sortRange(arr, pivot + 1, end);
}

void sort(int arr[], int n) { sortRange(arr, 0, n); }

int main(int argc, char *argv[]) {
  int size = sizeof(array) / sizeof(array[0]);
  sort(array, size);
  printList(array, size);
  return 0;
}
